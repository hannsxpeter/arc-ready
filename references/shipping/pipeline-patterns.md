# Pipeline Patterns

Loaded at Step 4. The pipeline is not the tool. The pipeline is the set of gates the change must pass, in a fixed order, where each gate has a well-defined pass criterion and a well-defined failure action. This file is opinionated about those gates, about the patterns that enforce them, and about the anti-patterns AI generators emit confidently.

The single load-bearing invariant: **same-artifact promotion**. The bytes that run in prod are the bytes that were tested in staging are the bytes that were scanned at build. If any gate rebuilds the artifact, the pipeline is broken and the drift is free to compound.

## The 8 required gates

From SKILL.md Step 4. Each gate has a good shape and a bad shape. The bad shape is what an AI generator produces when prompted "write me a CI/CD pipeline" without further constraint.

### Gate 1: Build

**What "good" looks like.** A single hermetic build. Pinned base image by SHA. Locked dependencies (lockfile checked, not re-resolved). Build output is one named artifact with a content-addressed hash (Docker image digest, npm tarball SHA, zip SHA256). The build runs in CI, not on a developer laptop, and emits the digest as a pipeline output.

**What "bad AI output" looks like.**

```yaml
# BAD: non-deterministic base, no lockfile, no hash emitted
- run: docker build -t myapp:latest .
- run: docker push myapp:latest
```

The base image is `FROM node:20` without a digest; `npm install` re-resolves the tree; the tag is `:latest` with no traceable content hash. "Same-artifact promotion" is literally impossible because there is no artifact name that identifies bytes.

**Good shape.**

```yaml
- run: docker build -t ghcr.io/org/app:${{ github.sha }} .
- run: docker push ghcr.io/org/app:${{ github.sha }}
- id: digest
  run: echo "digest=$(docker buildx imagetools inspect ghcr.io/org/app:${{ github.sha }} --format '{{json .Manifest}}' | jq -r '.digest')" >> $GITHUB_OUTPUT
```

The tag is the commit SHA; the digest is captured and carried through subsequent jobs as a pipeline output. Later gates reference `ghcr.io/org/app@sha256:<digest>`, not the tag.

### Gate 2: Test

**What "good" looks like.** Tests run against the built artifact (container or bundle), not against a freshly-checked-out source tree. Unit, integration, and any contract tests run here. Green or no promote. `repo-ready` owns the test content; this gate only verifies the green.

**Bad AI output.** Tests run against source, not the artifact; a flaky test is marked `continue-on-error: true`; tests are skipped on merge queue.

### Gate 3: Security

**What "good" looks like.** Image scan (Trivy, Grype, Snyk Container) against the built image. Dependency audit (`npm audit`, `pip-audit`, `cargo audit`). Secret scan against the artifact and the diff (gitleaks, trufflehog). SBOM emitted and archived.

**Bad AI output.** The scan runs against the source only, missing anything the Dockerfile pulled in at `apt-get` or `RUN curl` steps. Secret scan runs on `push`, not on the artifact, so anything baked into an image layer slips through ([Truffle Security on Docker layer leaks](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images); [Intrinsec Docker leak survey](https://www.intrinsec.com/en/docker-leak/); [GitGuardian 2026 report via dev.to](https://dev.to/mistaike_ai/29-million-secrets-leaked-on-github-last-year-ai-coding-tools-made-it-worse-2a42)).

### Gate 4: Promote to first non-prod env

**What "good" looks like.** Pull by digest, not by tag. Smoke-check the deployment, not just the HTTP status. The healthcheck is truthful (see SKILL.md Tier 1, requirement 5). The promotion step references the digest emitted by Gate 1.

**Bad AI output.** `docker pull myapp:latest && docker run`. Any push to `:latest` between build and promote races. The smoke check is `curl -f http://.../health`, and the healthcheck returns 200 on socket bind ([Resolve.ai](https://resolve.ai/glossary/how-to-debug-kubernetes-probe-issues); [CubeAPM](https://cubeapm.com/blog/kubernetes-readiness-probe-failed-error/)).

### Gate 5: Promote to staging

**What "good" looks like.** Same artifact digest as Gate 4. Environment variables supplied from the CI provider's environment-scoped secret store, not from YAML. The pre-deploy checklist (subsequent-deploy section of `preflight-and-gating.md`) runs here. If the ship includes a migration expand phase, the migration runs before the code shift, gated on success.

**Bad AI output.** The staging deploy rebuilds the image "to pick up staging env vars" (the drift hazard). The migration runs in the same transaction as the schema change. The staging DB is the prod DB.

### Gate 6: Approval

**What "good" looks like.** GitHub Actions environment protection rule with required reviewers. GitLab CI manual job with protected-environment access control. The approver identity is logged. The approval cannot be bypassed by a push to main. The approval is scoped to the specific deployment, not a blanket "deploy yes" toggle. GitHub added environment branch protections and stricter `pull_request_target` reference pinning on [2025-11-07](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/); use the updated protection rule format, not the legacy one.

**Bad AI output.** The approval is a `workflow_dispatch` toggle that any maintainer can flip. A Slack message "ping me when you want to ship" with no pipeline enforcement. A `gh workflow run deploy.yml` from a developer's laptop. The environment protection rule exists but `required_reviewers` is an empty list.

### Gate 7: Promote to prod

**What "good" looks like.** Same artifact digest as Gate 1. Promotion is a tag-move in the registry or an alias-swap, not a re-build. Rollout strategy per SKILL.md Step 7 (rolling, blue/green, canary with the four-field rule, or ring).

**Bad AI output.** `docker build . && docker push` on the prod deploy job. The tag `:prod` is rebuilt from source. Any change in a transitive dependency between build and prod deploy lands in prod unreviewed.

### Gate 8: Post-deploy verification

**What "good" looks like.** A smoke run against prod from CI after the rollout completes. Canary metric check (if canary is the strategy). Rollout state captured in `.deploy-ready/STATE.md`. If any check fails, pipeline triggers rollback or signals a human.

**Bad AI output.** The pipeline declares success when the `kubectl rollout status` returns before the readiness probe has actually verified traffic serves correctly. No post-deploy smoke. No link back to the observability layer (paper canary territory).

## The same-artifact invariant: how to enforce it

The invariant is simple and often violated.

**State the invariant.** The digest emitted at Gate 1 is the digest pulled at Gates 4, 5, and 7. No intermediate rebuild. No `docker build` appears in any job after Gate 1.

**Enforce via registry tags.** Build once, tag with commit SHA. Promote by adding additional tags (or moving aliases): `:preview`, `:staging`, `:prod`. Tag moves are O(1); they never re-resolve dependencies. In Kubernetes land, the Deployment manifest refers to the image by `@sha256:<digest>`, not by tag.

**Enforce via CI output passing.** The build job emits the digest as an output; downstream jobs reference it. GitHub Actions:

```yaml
jobs:
  build:
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - id: build
        run: |
          digest=$(docker buildx build --push --tag ghcr.io/org/app:${{ github.sha }} . | grep 'pushed digest' | awk '{print $NF}')
          echo "digest=$digest" >> $GITHUB_OUTPUT

  promote-staging:
    needs: build
    steps:
      - run: kubectl set image deployment/app app=ghcr.io/org/app@${{ needs.build.outputs.digest }}

  promote-prod:
    needs: [build, promote-staging]
    environment: prod   # gated by environment protection rule
    steps:
      - run: kubectl set image deployment/app app=ghcr.io/org/app@${{ needs.build.outputs.digest }}
```

Identical digest flows from build to prod. The only thing changing across environments is the target cluster and the secrets bound at runtime.

**Reject the "build per env" anti-pattern.** An AI-generated pipeline often has separate `build-staging` and `build-prod` jobs that each run `docker build`. This is the largest single source of dev/prod drift ([Gruntwork on AI + Terraform](https://www.gruntwork.io/blog/thinking-of-using-ai-with-terraform); [Testkube on K8s manifests](https://testkube.io/blog/system-level-testing-ai-generated-code)). The fix: one `build` job, multiple `promote-*` jobs.

## Pipeline patterns

### Trunk-based with environment branches (or not)

The pattern that wins for CD. All changes land on `main` (trunk). Short-lived feature branches merge via PR. Each push to `main` triggers a pipeline that promotes through the environment ladder up to a gated approval for prod.

Environment branches are optional and often a smell. A `staging` branch that diverges from `main` is a drift magnet; if the branch holds config specific to the env, that config belongs in env-scoped secrets, not in a branch.

When to use environment branches: you genuinely run different code in staging vs. prod (hotfix-only branch for a regulated release cadence). Then the branch is the artifact path, and the same-artifact invariant applies within each branch's promotion ladder.

### GitFlow (and why it is dying for CD)

GitFlow (develop, feature, release, hotfix, main) was designed for quarterly-release desktop-software-shaped workflows. For CD, it has too many long-lived branches and too many merge points. Each merge is a dev/prod drift opportunity. The "release branch" stage adds latency without preventing bugs that continuous deploys catch faster.

For new projects in 2026: trunk-based. For legacy projects already on GitFlow: fine, but the CD pipeline lives on the release branch, not on develop, and the same-artifact invariant still holds.

### GitOps (Argo CD, Flux)

The cluster reconciles to a git repo. Commits to the deployment-manifest repo change the cluster state.

What it catches: drift between declared state and actual state. Reviewable, auditable deployment history. A rollback is a git revert.

What it does not catch (from RESEARCH 3.2):

- Argo CD auto-sync and rollback are mutually exclusive; enabling one disables the other ([Devtron comparison](https://devtron.ai/blog/gitops-tool-selection-argo-cd-or-flux-cd/)). If auto-sync is on, rolling back to a previous manifest requires touching git, not the CD tool.
- Flux does not support cluster-drift reconciliation for Helm releases; no self-healing for Helm ([Spacelift Flux vs Argo CD](https://spacelift.io/blog/flux-vs-argo-cd); [Northflank comparison](https://northflank.com/blog/flux-vs-argo-cd)).
- Neither tool has an opinion about migration ordering relative to rollout. A Deployment and a Job can be applied in an order that makes the new pods crash on a missing column.
- Neither tool has an opinion about data-forward rollback. Reverting the manifest does not revert the data.

GitOps composes with deploy-ready: use GitOps for the reconciliation layer; use deploy-ready's rules for what goes in the git repo and in what order. The pipeline emits the manifest change; Argo or Flux applies it.

### Platform-native CD (Vercel, Netlify, Fly.io, Railway, Render, Cloud Run)

Push-to-deploy. The platform owns the pipeline.

What it catches: a green deploy, previews, basic rollback ("instant rollback" to a previous deployment ID).

What it does not catch (from RESEARCH 3.4):

- The preview environment is not prod-shaped. Env vars added after the deploy read as `undefined` until redeploy ([Vercel env docs](https://vercel.com/docs/deployments/environments); [Vercel discussion #5015](https://github.com/vercel/vercel/discussions/5015); [Netlify env docs](https://docs.netlify.com/build/environment-variables/overview/)). This is first-deploy blindness in the platform-native form.
- No opinion on migrations against a shared production DB. The platform ships the code; the DB is out of scope.
- "Rollback" is a deployment-alias change; the data went forward.

Use platform-native CD for the delivery mechanism. Use deploy-ready for the migration calendar, rollback classification, and canary criteria that the platform does not own.

### Manual gates vs. automated promotion

Automated promotion from non-prod to prod ("push to main, auto-canary, auto-promote") works for mature pipelines with robust observability and a track record of rollback rehearsals. Most pipelines are not there. The gate is a required reviewer on the `prod` environment, and the reviewer looks at the post-deploy state of staging before approving.

Move from manual to automated when:

1. The canary meets the four-field rule (named metric, threshold, window, automated rollback trigger).
2. Rollback has been rehearsed within the last 90 days.
3. The observability layer can detect regression within the canary window.
4. The team trusts the gates to fire correctly (verified by false-positive rate, not vibes).

Until all four are true, keep the human gate. A paper-canary-driven auto-promote is worse than a manual gate.

## CI-CD separation discipline

Continuous integration: build, test, security, lint. Continuous deployment: promote, smoke, rollout, verify. They are distinct pipelines that compose.

**Why one monolithic workflow is an anti-pattern.** From RESEARCH 1.4: AI generates a single workflow that builds-tests-deploys-to-prod-on-push-to-main ([Tech-Now guide](https://tech-now.io/en/it-support-issues/copilot-consulting/how-to-fix-copilot-not-integrating-with-ci-cd-pipelines)). Problems:

- No separation of concerns. A change to the test step requires re-running deploy.
- No reuse. The same build logic is pasted in three places.
- No gating. Any push to main ships to prod. The Knight-Capital-shaped incidents (see SKILL.md "have-nots") live in this pattern.
- The entire workflow is one blast radius. A bug in the test step breaks deploys.

**The separated shape.**

```
ci.yml:       on: [push, pull_request]
              jobs: lint, test, build (emits artifact digest)

cd.yml:       on: workflow_run (ci.yml completed on main)
              jobs: promote-preview, promote-staging, smoke, approve, promote-prod, verify
```

The CI workflow is owned by `repo-ready`. The CD workflow is owned by `deploy-ready`. They compose via the artifact digest. CI never deploys; CD never rebuilds.

## Supply-chain pitfalls specific to CI

This is the section most AI-generated pipelines get wrong. Each item is an actual RCE or secret-exfil path, not a theoretical concern.

### pull_request_target with untrusted fork checkout

The canonical failure. `pull_request_target` runs in the context of the base repo with access to repo secrets, but the trigger is a PR from a fork. If the workflow checks out the fork's code and runs it, the fork has RCE with secret access. The [timescale/pgai advisory](https://github.com/timescale/pgai/security/advisories/GHSA-89qq-hgvp-x37m) is the worked example: every workflow secret including `GITHUB_TOKEN` and a HuggingFace token exfiltrated via exactly this pattern.

**Bad.**

```yaml
on: pull_request_target
jobs:
  test:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}   # <- fork code
      - run: npm test   # <- fork code runs with repo secrets
```

**Fix.** Do not use `pull_request_target` to run untrusted fork code. Use `pull_request` (no secrets) for untrusted builds, and `pull_request_target` only for jobs that read metadata (label, comment) and do not execute checked-out code. If you must run tests against fork code, use a two-stage workflow: `pull_request` runs the fork code in a sandbox, emits artifacts; `workflow_run` picks up the artifacts in a secret-access context ([Wiz GitHub Actions guide](https://www.wiz.io/blog/github-actions-security-guide); [Orca pull_request_nightmare](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/)).

### Secrets in workflow literals

**Bad.**

```yaml
env:
  AWS_SECRET_ACCESS_KEY: "AKIA..."
  DATABASE_URL: "postgres://user:password@prod-db/app"
```

The secret is in the file, in git, in every fork of the repo forever. Secret scan will catch this after the commit; the damage is done.

**Fix.** Secrets come from the CI provider's secret store, scoped to the environment:

```yaml
jobs:
  deploy-prod:
    environment: prod
    env:
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

The `environment: prod` scope means the secrets are only loaded when the job targets `prod`, and GitHub's environment protection rules apply (reviewers, required branches, wait timers).

### GitHub Actions environment protection rules

GitHub changed the protection-rule model on [2025-11-07](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/): `pull_request_target` no longer triggers environment protection rules by default, and environment branch protections are now stricter. Net effect: an older AI-generated workflow that relied on "environment protection protects me from fork PRs" is no longer correct.

Verify, per environment:

1. `required_reviewers` is a non-empty list of actual humans (not the pipeline's own bot).
2. `deployment_branch_policy` restricts to named branches (usually `main`).
3. Environment secrets are scoped to the environment, not the repo.
4. Wait timer is set if the team wants a cooling-off window on prod deploys.

### Reference pinning: pin by SHA, not by tag

**Bad.**

```yaml
- uses: actions/checkout@v4
- uses: some-vendor/deploy-action@main
```

`actions/checkout@v4` floats: a new release under the `v4` major resolves to new code. `some-vendor/deploy-action@main` is even worse: any push to that repo's `main` runs in your pipeline. The tj-actions/changed-files supply-chain attack (March 2025) shipped malicious code to every workflow that referenced it by tag, not by SHA.

**Fix.** Pin by commit SHA:

```yaml
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
- uses: some-vendor/deploy-action@<sha>   # pinned, update via dependabot
```

Dependabot and Renovate both support "pin by SHA, update as PR" workflows. The review step on the PR is where you audit the new action version.

### Deploy credentials scoped to a PAT on someone's personal account

When the "deploy to ECR" credential is `ghcr_pat` belonging to a former employee, you have one incident waiting for an HR event. Use a machine identity: GitHub OIDC -> AWS IAM role (the current best practice for AWS), service account credentials bound to a dedicated bot user, or an equivalent provider-native mechanism.

## Anti-patterns table

| Anti-pattern | Bad AI output | Fix |
|---|---|---|
| Monolithic workflow | One `deploy.yml` that builds, tests, and deploys to prod on push to main. | Split CI and CD. CI on push; CD on `workflow_run` or `workflow_dispatch` with environment gates. |
| Per-env rebuild | `build-staging` job and `build-prod` job both run `docker build`. | One `build` job; promote by digest. |
| No approval gate | `deploy-prod` job runs unconditionally on main push. | `environment: prod` with `required_reviewers` set. |
| Secrets in YAML | `env: DB_URL: "postgres://..."` in the workflow file. | Move to env-scoped secrets. Run `gitleaks` to catch pre-commit. |
| No environment protection | Every environment is repo-scope secrets with no reviewer. | Configure environments in the repo settings; set reviewers, branch policy, wait timers. |
| Unpinned action | `uses: actions/checkout@main` or `@v4`. | Pin by SHA, let Dependabot/Renovate file updates. |
| Laptop promotion | Engineer runs `gh workflow run deploy.yml --ref main` to ship. | Remove manual-dispatch on deploy. Promotion triggered only by pipeline or reviewer on environment gate. |
| pull_request_target with fork code | `on: pull_request_target` + checkout of `pull_request.head.sha`. | See the section above. Use `pull_request` for untrusted builds; two-stage for anything else. |
| Plaintext prod DB in staging | `staging` env points at the prod DB "for convenience." | Branch the DB (Neon branches, PlanetScale branches), or seed staging separately. |
| Readiness = socket bind | Probe path `/` returns 200 as soon as the HTTP server binds. | Probe reads config, opens a DB connection, returns healthy only on real-request-ready. |
| Deploy identity = runtime identity | The same role pushes images and runs the app. | Two identities. Deploy role has registry push; runtime role has app permissions. Both least-privileged. |
| Skip tests on merge queue | `continue-on-error: true` on the test step. | Tests gate the build. No green tests, no artifact. |
| Canary by vibes | "Deploy and watch Grafana for a bit." | Name the metric, the threshold, the window, the rollback trigger. Refuse to call it a canary otherwise. |
| Rollback is "redeploy" | Data-forward migration with rollback: "redeploy previous image." | Compensating-forward; pre-migration restore point; expand/contract decomposition. |

## Concrete GitHub Actions YAML: good and bad

### Bad: the AI-default pipeline

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-test-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - run: npm ci
      - run: npm test
      - run: docker build -t myapp:latest .
      - run: docker push myapp:latest
      - run: ssh deploy@prod 'docker pull myapp:latest && docker restart app'
        env:
          SSH_KEY: "-----BEGIN RSA PRIVATE KEY-----\n..."
```

Every row of the anti-patterns table is in here. This is the Knight Capital shape: no gates, no rollback, no artifact identity, secrets in literals.

### Good: a minimal but disciplined pipeline

```yaml
name: CD

on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

permissions:
  id-token: write   # for OIDC to cloud
  contents: read

jobs:
  build:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: docker/setup-buildx-action@c47758b77c9736f4b2ef4073d4d51994fabfe349
      - uses: docker/login-action@e92390c5fb421da1463c202d546fed0ec5c39f20
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: build
        uses: docker/build-push-action@4f58ea79222b3b9dc2c8bbdd6debcef730109a75
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          provenance: true
          sbom: true
      - uses: aquasecurity/trivy-action@18f2510ee396bbf400402947b394f2dd8c87dbb0
        with:
          image-ref: ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
          exit-code: 1
          severity: HIGH,CRITICAL

  promote-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502
        with:
          role-to-assume: arn:aws:iam::123:role/deploy-staging
          aws-region: us-east-1
      - run: |
          kubectl set image deployment/app \
            app=ghcr.io/${{ github.repository }}@${{ needs.build.outputs.digest }} \
            -n staging
          kubectl rollout status deployment/app -n staging --timeout=5m
      - run: ./scripts/smoke.sh https://staging.example.com

  promote-prod:
    needs: [build, promote-staging]
    runs-on: ubuntu-latest
    environment: prod   # has required_reviewers, deployment_branch_policy: main only
    steps:
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502
        with:
          role-to-assume: arn:aws:iam::123:role/deploy-prod
          aws-region: us-east-1
      - run: |
          kubectl set image deployment/app \
            app=ghcr.io/${{ github.repository }}@${{ needs.build.outputs.digest }} \
            -n prod
          kubectl rollout status deployment/app -n prod --timeout=10m
      - run: ./scripts/smoke.sh https://example.com
      - run: ./scripts/canary-verify.sh   # named metric, threshold, window, rollback trigger
```

Features:

- CI and CD are separate workflows. CD triggers on CI completion.
- Build emits a digest; subsequent jobs reference the digest, not a tag.
- Image scan runs against the built image (not source).
- Environment gates: `staging` has no reviewers; `prod` has reviewers and branch policy.
- Cloud creds come from OIDC federation, not static PATs.
- All third-party actions pinned by SHA.
- `permissions` is minimal; `id-token: write` only where needed.
- Smoke and canary verification are real scripts, not a `curl -f /health`.

## Further reading

Source citations in `RESEARCH-2026-04.md`:

- Section 1.4 on CI/CD conflation and supply-chain footguns: [Wiz GitHub Actions guide](https://www.wiz.io/blog/github-actions-security-guide); [Orca pull_request_nightmare](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/); [timescale/pgai advisory](https://github.com/timescale/pgai/security/advisories/GHSA-89qq-hgvp-x37m); [Tech-Now troubleshooting](https://tech-now.io/en/it-support-issues/copilot-consulting/how-to-fix-copilot-not-integrating-with-ci-cd-pipelines).
- Section 3.1 on GitHub Actions protection rule changes: [GitHub Changelog 2025-11-07](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/); [Sysdig insecure Actions in open-source repos](https://www.sysdig.com/blog/insecure-github-actions-found-in-mitre-splunk-and-other-open-source-repositories).
- Section 3.2 on GitOps tooling gaps (Argo CD / Flux): [Devtron comparison](https://devtron.ai/blog/gitops-tool-selection-argo-cd-or-flux-cd/); [Spacelift Flux vs Argo CD](https://spacelift.io/blog/flux-vs-argo-cd); [Northflank Flux vs Argo CD](https://northflank.com/blog/flux-vs-argo-cd).
- Section 3.4 on platform-native CD env-var traps: [Vercel env docs](https://vercel.com/docs/deployments/environments); [Netlify env docs](https://docs.netlify.com/build/environment-variables/overview/); [Vercel discussion #5015](https://github.com/vercel/vercel/discussions/5015).
- Section 1.3 on Docker layer leaks and secret scanning against artifacts: [Truffle Security](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images); [Intrinsec Docker Hub leaks](https://www.intrinsec.com/en/docker-leak/); [BleepingComputer 10,000+ images](https://www.bleepingcomputer.com/news/security/over-10-000-docker-hub-images-found-leaking-credentials-auth-keys/).
