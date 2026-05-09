# Secrets Injection

Loaded at Step 8 of the workflow and for Tier 2 completion. This file covers the path from whatever vault is present to the running process, and nothing else.

**Scope fence:** deploy-ready owns *injection at deploy time*. Vault choice (HashiCorp, AWS Secrets Manager, GCP Secret Manager, 1Password, Doppler), rotation policy, and access auditing live in security territory. The injection path, from vault to runtime, is where AI-generated deploys bleed, and it is what this file opinions on.

The one-line framing: a secret that lands in an image layer, a git commit, a workflow YAML literal, or a fork-pull-request context with secret access is leaked. The vault is a distraction if the path from the vault to the running process is broken. Every check below is about that path.

---

## Part 1. The sizing: why this is a deploy-ready problem

GitGuardian's 2026 State of Secrets report attributes roughly 2x baseline secret-leak rate to AI-assisted commits, with over 29M secrets leaked on GitHub in 2025 ([GitGuardian / dev.to, 2026](https://dev.to/mistaike_ai/29-million-secrets-leaked-on-github-last-year-ai-coding-tools-made-it-worse-2a42)). Truffle Security and Intrinsec's surveys of Docker Hub found over 10,000 images leaking credentials through `COPY .` and `COPY .env` patterns ([Truffle Security](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images), [Intrinsec](https://www.intrinsec.com/en/docker-leak/), [BleepingComputer](https://www.bleepingcomputer.com/news/security/over-10-000-docker-hub-images-found-leaking-credentials-auth-keys/), [GitGuardian on Docker Hub](https://blog.gitguardian.com/hunting-for-secrets-in-docker-hub/)).

These are not exotic failures. They are the default output of a coding assistant asked "write me a Dockerfile" or "set up GitHub Actions to deploy this." The deploy-ready audit is the last chance to catch them before the artifact is public.

---

## Part 2. The Docker layer leak

Docker images are append-only. Every `COPY`, `ADD`, `RUN` creates a new layer, and every previous layer persists forever in the image. A later `RUN rm secret.txt` does not remove the secret from the image; it removes it from the final layer only, leaving it intact in the layer it was copied in.

**The common AI-generated patterns that leak:**

```dockerfile
# BAD: copies everything including .env, .git, node_modules with cached npm config
COPY . /app

# BAD: copies .env explicitly, bakes secrets into a layer forever
COPY .env /app/.env

# BAD: "I'll clean up after" does not work
COPY .env /app/.env
RUN npm run build && rm /app/.env

# BAD: ARG at build time becomes visible in image history
ARG AWS_SECRET_ACCESS_KEY
RUN aws s3 cp s3://bucket/foo .
```

**The fix patterns:**

```dockerfile
# GOOD: explicit dockerignore, copy only what's needed
# .dockerignore includes: .env, .env.*, .git, node_modules, *.pem, *.key
COPY package.json package-lock.json /app/
RUN npm ci
COPY src /app/src
COPY tsconfig.json /app/

# GOOD: build-time secret mount (BuildKit); secret is not in any layer
# syntax=docker/dockerfile:1.4
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci

# GOOD: runtime secret via env var injected at start, never baked
CMD ["node", "server.js"]
# Secret arrives from orchestrator at runtime, not from the image.
```

**Audit command:**

```bash
# list every layer and its command; grep for suspicious content
docker history --no-trunc --format '{{.CreatedBy}}' your-image:tag | grep -iE '(secret|token|key|password|\.env|AKIA|ghp_|sk_live_)'

# dive into the filesystem, find files that should not be there
dive your-image:tag

# or use a scanner directly
trivy image --scanners secret your-image:tag
```

---

## Part 3. The audit list, expanded

The Step 8 audit from SKILL.md, with the how-to for each item.

### 3.1 No secrets in image layers

Tooling:
- **`docker history --no-trunc`** prints every layer's creation command. Secrets passed via `ARG` or `COPY` are visible here.
- **`dive`** walks the filesystem per layer; catches a secret that was copied in and "removed" in a later layer.
- **`trivy fs`** and **`trivy image`** scan the actual filesystem of the image for known secret patterns.
- **`grype`** and **`syft`** give SBOM-level visibility; paired with a secret scanner they close the loop.

What good looks like: the scanner returns zero hits, and the Dockerfile has no `COPY .`, no `COPY .env`, and no `ARG`-then-`RUN`-with-credential pattern.

### 3.2 No secrets in git history

The AI commit pattern: a `.env` gets accidentally tracked, the engineer reverts in the next commit, the secret is still in history.

Tooling:
- **`gitleaks`** (`gitleaks detect --source . --log-opts="--all"`) scans the full history, not just the working tree.
- **`trufflehog`** (`trufflehog git file://. --only-verified`) scans with live credential verification; cuts false positives.
- **Pre-commit hooks**: gitleaks-pre-commit, detect-secrets. These go in `repo-ready` territory but the audit happens at deploy time.

What good looks like: scan of the deploy diff AND the full history returns zero verified hits. If a secret is found, rotation first, history rewrite second, not the reverse.

### 3.3 No secrets in workflow literals

Separate section because this is the most common AI-generated CI failure.

**The bad pattern (AI will write this):**

```yaml
- name: Deploy
  run: |
    AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX \
    AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
      aws s3 sync ./build s3://my-bucket
```

**The fix (GitHub Actions):**

```yaml
- name: Deploy
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: aws s3 sync ./build s3://my-bucket
```

And better (OIDC, no long-lived key):

```yaml
permissions:
  id-token: write
  contents: read
steps:
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/gh-actions-deploy
    aws-region: us-east-1
- run: aws s3 sync ./build s3://my-bucket
```

**GitHub Actions environment scoping:** secrets can be scoped to environments (`staging`, `prod`), and the environment can require approval before the job runs. Production deploy credentials go in an environment-scoped secret with a protection rule, not a repository-level secret ([GitHub Changelog, 2025-11-07](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)).

**GitLab CI variable scoping:** `Protected` variables only expose to jobs on protected branches/tags; `Masked` variables redact from logs; `Environment scope` restricts variables to matching deployment environments. All three matter for prod credentials.

### 3.4 No untrusted-fork secret exposure

`pull_request_target` is the footgun. It runs workflows with the base repository's secrets available, which is correct for actions that need to comment on a PR. It becomes a vulnerability when the workflow also checks out the forked PR's code and runs it.

**The bad pattern:**

```yaml
on: pull_request_target
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # untrusted fork code
      - run: npm test  # runs with secrets available
```

An attacker opens a PR, modifies `npm test` (or any script invoked by it) to exfiltrate `${{ secrets.* }}` or dump the `GITHUB_TOKEN`, and the workflow runs their code with the base repo's full secret surface.

The timescale/pgai incident from 2025 is the exemplar: misuse of `pull_request_target` leaked every workflow secret including `GITHUB_TOKEN` and a HuggingFace token ([GHSA-89qq-hgvp-x37m](https://github.com/timescale/pgai/security/advisories/GHSA-89qq-hgvp-x37m), [Orca, "pull_request_nightmare"](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/)).

**The fix:** never check out untrusted fork code in a `pull_request_target` context that has secret access. Split into two workflows: one uses `pull_request` (no secrets, runs the fork code) and one uses `pull_request_target` (has secrets, runs only trusted code and posts results).

GitHub's 2025-11-07 changelog added environment protection for `pull_request_target` and branch-protection-like guarantees on fork-triggered runs; the default posture still requires the repo to opt in ([GitHub Changelog, 2025-11-07](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)). The audit: every `pull_request_target` in the repo's workflows is either explicitly justified or converted.

### 3.5 Runtime identity is least-privileged (and separate from deploy identity)

The deploy identity that ships the artifact is not the same identity the app uses at runtime.

- **Deploy identity:** push image to registry, update Kubernetes deployment, flip Vercel alias, update DNS, run migrations. Scoped narrowly to those actions, ideally via OIDC short-lived tokens.
- **Runtime identity:** read from the app's DB, write to its S3 bucket, call its downstream APIs. Has no deploy permissions.

The AI-generated anti-pattern: a single IAM role with `AdministratorAccess` or `PowerUserAccess` that is used for both. A compromise of the running app then owns the deploy pipeline; a compromise of the deploy pipeline owns the prod data. Replit's 2025 incident (full prod DB wipe by an AI agent) is partly this shape: the agent had credentials with authority it did not need ([Fortune](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/), [AI Incident Database #1152](https://incidentdatabase.ai/cite/1152/)).

The audit: for every environment, the deploy role's policy and the runtime role's policy are separate, each is scoped to its verbs, and neither has `*:*`.

### 3.6 Env vars and file mounts as the two safe injection patterns

At runtime, secrets arrive through one of two mechanisms:

- **Environment variables**, set by the orchestrator, read by the process at startup. Simple, universally supported. Risk: env vars leak to child processes, crash dumps, and some logging paths.
- **Mounted files**, written by the orchestrator to a tmpfs or secret-store volume, read by the process from a known path. Safer for large or binary secrets, and for rotation without a restart (some secret drivers refresh the mount in-place).

Everything else (config files in the image, `.env` files in the repo, hardcoded constants, secrets passed as CLI args) is unsafe.

---

## Part 4. Per-topology injection patterns

| Topology | Safe injection | Notes |
|---|---|---|
| **Container (Kubernetes, ECS, Nomad)** | Env var from `Secret` object; file mount from `Secret` as a volume. External Secrets Operator / CSI Secret Store syncs from the vault. | The `Secret` object is base64, not encrypted; apply encryption-at-rest on etcd and RBAC on `secrets` resources. |
| **Container (Fly.io, Railway, Render)** | `flyctl secrets set KEY=value` / platform UI; injected as env var at runtime. | Platform handles rotation by restarting the machine; `fly config env` is non-secret, `fly secrets` is encrypted. |
| **Serverless (AWS Lambda)** | `aws:secretsmanager:...` reference in the function config; Lambda extensions (AWS Parameters and Secrets Extension) for cached reads. | Do not put secrets in environment variables that are visible in the console; use Secrets Manager references. |
| **Serverless (GCP Cloud Functions / Cloud Run)** | Secret Manager mounted as env var or volume via `--set-secrets` / `--update-secrets`. | Cloud Run mounts are live-refreshed on rotation if configured. |
| **Static (built artifacts, SPAs, Next.js static export)** | Only public values at build time (API base URL, public analytics keys). Runtime secrets via proxy/edge function; never in the bundle. | See Part 5 on `NEXT_PUBLIC_`. |
| **Platform-native (Vercel, Netlify)** | Env var UI, per-environment scoping (Preview / Staging / Production). Secrets encrypted at rest by the platform. | The client-vs-server split is the load-bearing distinction; see Part 5. |

---

## Part 5. Build-time vs runtime: the `NEXT_PUBLIC_` trap

Next.js, Vite, Nuxt, and SvelteKit all have a framework-prefixed "public" env var convention. The prefix tells the bundler "inline this value into the client-side bundle." If a secret is set under that prefix, the secret ships to every user's browser.

- **Next.js:** `NEXT_PUBLIC_*` is inlined into the client bundle. Regular env vars are server-only ([Next.js env docs](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)).
- **Vite:** `VITE_*` is inlined.
- **Nuxt:** `NUXT_PUBLIC_*` is inlined.
- **SvelteKit:** anything in `$env/static/public` or `$env/dynamic/public`.

The AI failure mode: a config file sets `NEXT_PUBLIC_API_KEY` because "it needs to be available on the client." The deploy ships, the key is now in every user's downloaded bundle, and the key is harvested within hours by scrapers ([Vercel docs](https://vercel.com/docs/deployments/environments), [Vercel discussion #5015](https://github.com/vercel/vercel/discussions/5015)).

The audit command for the deployed artifact:

```bash
# download the prod bundle; grep for secret patterns
curl -s https://yourapp.com/_next/static/chunks/*.js | grep -iE '(sk_live_|aws_secret|ghp_|bearer )'

# for static exports
grep -rE '(sk_live_|aws_secret|ghp_|bearer )' ./out/
```

What good looks like: only intentionally-public values (public analytics keys, public API URLs) appear in the client bundle. Everything else is server-side (API routes, edge functions, RSC) and never touches the client.

---

## Part 6. Secret rotation at deploy time

Rotation itself is security territory. What deploy-ready opinions on: when a secret rotates, how does the running app pick up the new value?

Three patterns:

1. **Restart-required.** Secret is read once at startup. Rotation triggers a rolling restart of the fleet. Simple; works everywhere. Cost: rotation is a deploy.
2. **Live-reload from mounted file.** Orchestrator updates the secret volume; the app re-reads on a timer or inotify event. No restart. Works with Kubernetes Secret volumes, CSI Secret Store, Cloud Run secret volumes.
3. **Live-reload from a client SDK.** App uses the secret-store SDK directly (AWS Parameters and Secrets Extension, GCP Secret Manager client) with a local cache and a refresh interval.

The deploy-ready audit question: if the secret rotates, does the deploy pipeline also update the orchestrator's secret reference, or does the app pick up the rotated secret directly from the vault? Pattern (1) requires pipeline integration; patterns (2) and (3) decouple rotation from deploy.

---

## Part 7. Audit the artifact, not just the source

The source tree is clean, and the artifact still leaks. Three paths cause this:
- Build-time secrets that get inlined (Part 5).
- Transitively included files (`COPY .` includes `.env`, `COPY node_modules` includes cached npm credentials).
- Build-caches that include secrets in intermediate stages and are not stripped in the final image.

**The artifact-level audit commands:**

```bash
# scan the built Docker image
trivy image --scanners secret your-image:tag
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/gitleaks/gitleaks:latest docker your-image:tag

# scan the static build output
gitleaks detect --source ./dist
trufflehog filesystem ./dist

# for serverless packages
unzip -l function.zip | head
trivy fs ./unzipped-function/

# check environment variables actually set on the deployed service
kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[*].env}' | jq
flyctl ssh console --app my-app -C 'env' | grep -iE '(secret|token|key|password)'
```

These run against the shipped artifact, not the source, and they are the final gate before the audit passes.

---

## Further reading

- [GitGuardian "Hunting for secrets in Docker Hub"](https://blog.gitguardian.com/hunting-for-secrets-in-docker-hub/) for the Docker layer leak problem.
- [Truffle Security on Docker image secrets](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images).
- [GitHub Actions hardening guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions).
- [Wiz, "GitHub Actions security guide"](https://www.wiz.io/blog/github-actions-security-guide).
- [Orca Security, "pull_request_nightmare"](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/).
- [OWASP CI/CD Security Top 10](https://owasp.org/www-project-top-10-ci-cd-security-risks/).
- [Next.js environment variables documentation](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables).
- [timescale/pgai GHSA-89qq-hgvp-x37m](https://github.com/timescale/pgai/security/advisories/GHSA-89qq-hgvp-x37m) as the pull_request_target case study.
