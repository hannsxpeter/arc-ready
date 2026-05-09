# First-Deploy Checklist

Loaded at Step 9 in Mode A (first deploy to a new environment). This file covers the cold-start gate, per-platform first-deploy gotchas, the dry-run rollback procedure, and a printable one-page checklist.

**Canonical scope:** what has to be true about a new environment *before* an artifact ships into it for the first time. **See also:** `preflight-and-gating.md` for the subsequent-deploy checklist (Mode B); `rollback-playbook.md` for the recovery path when the first deploy goes sideways.

---

## Part 1. First-deploy blindness

**First-deploy blindness** is the class of failures that only happen on the first promotion to a new environment: the missing env var, the unset framework prefix, the `.env` that was not read at build, the IAM role that does not exist yet, the DNS record whose TTL has not propagated, the cert that is still provisioning, the database whose connection string is wrong in a way that only manifests from the new VPC.

These failures are distinct from "works on my machine" and distinct from subsequent-deploy failures. Steady-state tooling does not help: the pipeline that will run flawlessly on deploy number two has no opinion about deploy number one, because deploy number one is the deploy that discovers what the environment actually needs.

The first deploy to any new environment has failure modes the second deploy does not. Treat it as a distinct phase. Budget time for it. Do not assume "it is just like the other environment" because that assumption is exactly what first-deploy blindness is.

---

## Part 2. The cold-start gate list

Each item below is a hard block. If the item is not green, the first deploy does not go. A named, justified exception is acceptable; silence is not.

### 2.1 Target environment exists and is reachable

- The platform account, project, cluster, or namespace exists.
- Basic connectivity: `ping` (or the platform equivalent), DNS resolution of the platform's API endpoint, VPC peering or network policy permits the traffic path.
- The deploy identity can authenticate to the target (`aws sts get-caller-identity`, `kubectl auth can-i`, `flyctl auth whoami`, `vercel whoami`).

### 2.2 DNS created and propagated

- Authoritative record exists in the DNS provider.
- Recursive resolvers (Cloudflare 1.1.1.1, Google 8.8.8.8, Quad9 9.9.9.9) return the expected answer.
- TTL is appropriate for cutover: a 24h TTL on an old record is a cutover risk; drop it to 60s before the change, restore afterwards.
- For a primary domain, `dig +trace yourdomain.com` shows a clean delegation chain.

### 2.3 TLS certificate provisioned, not expiring soon, trust chain valid

- Certificate exists for every hostname the app serves (including `www.` if redirect is set up).
- Not expiring in the next 30 days (or ideally 60 for non-automated renewal).
- Trust chain is valid (intermediate cert is attached; `openssl s_client -connect host:443 -showcerts` shows a clean chain).
- SAN list includes every hostname the app answers on.

### 2.4 Database provisioned, schema at or ahead of the expand phase

- The database instance exists, is reachable from the new environment's runtime network, and has credentials that work.
- Schema is applied up through the expand phase required by the incoming code. The code will NOT run a migration as part of the first deploy if that migration has destructive steps; migrations ship as their own plan (`zero-downtime-migrations.md`).
- Connection pool limits are set sensibly; the new runtime is not going to exhaust them.

### 2.5 Env vars set in the platform, not just in the code

- Every env var the app reads at startup is set in the platform's config surface.
- Framework prefixes applied: `NEXT_PUBLIC_*`, `VITE_*`, `NUXT_PUBLIC_*`, `REACT_APP_*`, depending on the framework.
- Non-secret env vars are in platform config; secret env vars are in the platform's secret store (see `secrets-injection.md`).
- Vercel/Netlify-class gotcha: env vars added AFTER the deployment are `undefined` until the next deploy. If you set an env var and expect the running deployment to see it, you are wrong until you redeploy ([Vercel docs](https://vercel.com/docs/deployments/environments), [Netlify docs](https://docs.netlify.com/build/environment-variables/overview/), [Vercel discussion #5015](https://github.com/vercel/vercel/discussions/5015)).

### 2.6 IAM / runtime role exists with least-privileged permissions

- The role the app runs as in the new environment exists.
- Its policy is the least-privileged set of verbs the app needs (separate from the deploy identity; see `secrets-injection.md` Part 3.5).
- Trust policy permits the platform's runtime principal (the Lambda execution role, the ECS task role, the Kubernetes service account, the Cloud Run service account).

### 2.7 Image in registry; pull credentials valid from target

- The artifact (image, bundle, package) is pushed to the registry the target environment pulls from.
- Pull credentials are valid: if the registry is private, the target has an image pull secret or equivalent (`imagePullSecrets`, ECR auth via task role, GCR via Workload Identity).
- The artifact is named with a content hash or immutable tag (not `:latest`).

### 2.8 Healthcheck endpoint is truthful

A probe that returns 200 on socket bind is lying. The probe must check:

1. Config loaded (env vars present, secrets read).
2. Database reachable and responsive.
3. Required dependencies (cache, queue, downstream services) reachable.
4. A real request-shape can be served.

See `progressive-delivery.md` Part 5 for the probe shape. First-deploy gotcha: the probe path and port in the manifest must match the app's routes. The most common AI-generated bug is a probe pointing at `/health` when the app serves `/healthz`, or at port 8080 when the app binds 3000.

### 2.9 Log aggregation reaches the env, OR explicit "shipping without logs" exception

- The log shipper is configured: CloudWatch Logs agent, Datadog agent, Loki Promtail, Vector, or the platform's native log integration.
- A test log line from the new environment is visible in the log backend.
- If logs are not reaching the env, this is a hard block unless the plan explicitly states "shipping without logs" with a time-bounded remediation.

### 2.10 Rollback path exists AND has been dry-run on a non-prod copy

A rollback that has never been run is not a rollback. See Part 4 below for the dry-run procedure.

### 2.11 Observability reaches the env, OR no canary claims allowed

- Metrics from the new environment reach the metrics backend (Prometheus, Datadog, CloudWatch, New Relic).
- Traces (if used) reach the tracing backend.
- If no observability reaches the env, no canary may be claimed. See `progressive-delivery.md` Part 2 for the paper-canary rule.

---

## Part 3. Per-platform first-deploy gotchas

### 3.1 Vercel

- **Env vars after deploy are undefined until redeploy.** Setting a var in the Vercel dashboard does not affect the running deployment ([Vercel docs](https://vercel.com/docs/deployments/environments)).
- **`.env` is not read at build.** Vercel builds happen on their infrastructure; your local `.env` is not uploaded. Only vars set in the Vercel dashboard are available at build time.
- **`NEXT_PUBLIC_` prefix is load-bearing.** Values without the prefix are server-only; values with it are inlined into the client bundle. A secret under `NEXT_PUBLIC_` is a client-bundle leak (see `secrets-injection.md` Part 5).
- **Preview and Production are separate environment scopes.** A var set for Production is not automatically set for Preview; the first preview deploy will fail on a missing var if only Production is configured.
- **Serverless function cold starts** can exceed the default 10s execution timeout on the Hobby plan; bump the timeout for serverless routes that cold-start heavy.

### 3.2 Netlify

- Same env-var-after-deploy gotcha as Vercel.
- **Build image version lock**: Netlify builds on a pinned image; Node version and system package availability depend on the selected build image. A local-vs-build Node mismatch is a common first-deploy failure ([Netlify docs](https://docs.netlify.com/configure-builds/manage-dependencies/)).
- **Function region**: Netlify Functions run in a specific region; latency to your DB matters. Set the region explicitly for production.
- **Build-time env prefix**: Netlify does not have a framework-wide `PUBLIC_` convention; each framework (Next, Vite, Astro) has its own. Apply the prefix the framework expects.

### 3.3 Fly.io

- **`fly secrets` vs `fly config env`**: `fly secrets set KEY=value` encrypts and restarts machines; `fly config env` is non-secret and requires a redeploy. Mixing these is a common first-deploy footgun.
- **Region = app location.** The Fly app runs in the region(s) you allocate machines in. If the DB lives in `ord` and the app is allocated in `fra`, every query crosses the Atlantic. Colocate.
- **`fly.toml` versus deployed config**: `fly.toml` in the repo is the declared config; what's actually running can drift. `fly config show` prints the deployed config; compare before the first deploy.
- **Volume mounts are per-machine**: a single volume is not shared across machines. Stateful services need an external DB, not a shared volume.

### 3.4 Cloud Run

- **IAM for service-to-service:** Cloud Run services default to no identity; set a service account with the verbs the service needs. For calling another Cloud Run service, grant `roles/run.invoker` on the target.
- **Cloud SQL connector:** if the app talks to Cloud SQL, use the Cloud SQL Auth Proxy or the direct VPC connector. A plain Postgres connection string with a public IP works but exposes the DB; private is the default for prod.
- **Cold-start latency** on first request after idle can be hundreds of ms to seconds. Set a minimum instance count if SLO requires warm starts.
- **Concurrency:** Cloud Run's default max concurrency per instance is 80; for CPU-bound work, lower it; for I/O-bound work, higher may be fine.

### 3.5 AWS Lambda

- **Function URL vs API Gateway:** Function URLs are simpler but have no custom auth, no WAF, no staging/production aliases. API Gateway has more features and more config surface.
- **VPC cold-start tax:** a Lambda in a VPC used to have a significant cold-start penalty; Hyperplane ENIs reduced this but it is still non-trivial. Non-VPC Lambdas cold-start faster.
- **IAM trust policy:** the Lambda execution role's trust policy must permit `lambda.amazonaws.com` as the service principal. A custom role from another service copied over will fail to assume.
- **Reserved concurrency** protects against cold starts under spike but caps total concurrency; set it deliberately, not as a default.
- **Environment variables in the console are visible to anyone with `GetFunction` permission.** Use Secrets Manager references for secrets, not raw env vars.

### 3.6 Kubernetes

- **Image pull secret:** private registries need `imagePullSecrets` on the pod spec or the service account. A first-deploy `ErrImagePull` loop is the canonical symptom.
- **Service account token:** if the app uses Workload Identity (GKE) / IRSA (EKS) / Pod Identity (AKS), the ServiceAccount annotation has to match the cloud IAM binding. A missing or wrong annotation leaves the pod with no cloud identity; the app's SDK calls fail with cryptic errors.
- **NetworkPolicy default-deny:** if the cluster has default-deny network policies, a new Deployment with no matching `Ingress`/`Egress` rule is isolated. DB connections and external API calls fail.
- **CoreDNS:** DNS inside the cluster resolves via CoreDNS; a misconfigured `search` domain or a broken CoreDNS deployment silently breaks every hostname resolution. `kubectl run -it --rm dig --image=toolbox -- dig your.db.host` from inside the cluster catches this.
- **Readiness probe path and port:** see Part 2.8; the most common AI manifest bug.

---

## Part 4. Dry-run rollback: what it means on the first deploy

A rollback that has never been run is a wiki page, not a capability. The first deploy is the one chance to prove rollback works before the stakes get real.

**The procedure:**

1. **Ship v0.0.1 as a known-good baseline.** This is a trivial release: the app boots, serves a static response, passes the healthcheck. Call it explicitly "baseline." Tag it in the registry. Do not remove it from the deploy history.
2. **Ship v0.0.2 as a second release.** Trivial change (a log line, a version string). Watch it promote cleanly.
3. **Execute rollback to v0.0.1.** Use the actual rollback command the plan says to use: `flyctl releases rollback`, `kubectl rollout undo`, `vercel alias` to the prior deployment, `aws deploy stop-deployment`.
4. **Confirm user-visible behavior.** Hit the app from outside the deploy system (curl, a real browser, a synthetic probe). Verify the response matches v0.0.1, not v0.0.2.
5. **Roll forward to v0.0.2 again** to leave the environment in the intended state.

**Budget 30 minutes for this.** Do not skip. A first deploy without a dry-run rollback is a first deploy whose rollback path is hypothetical. When the real change later fails, "we'll just roll back" is an assumption, and on the first non-trivial deploy the assumption is the thing that is untested.

**What this catches:**
- Rollback command is wrong for this platform or version.
- The old artifact is not retained long enough to be a rollback target (registry garbage-collected it, platform pruned it).
- Rollback flips the artifact but not the associated config (env vars, secrets, DNS), leaving a partial state.
- Migrations are not idempotent on re-run (the expand-phase schema is fine, but the app's startup runs migrations unconditionally).
- IAM: the deploy role cannot actually execute the rollback command.

---

## Part 5. One-page printable first-deploy checklist

```
FIRST-DEPLOY CHECKLIST                                 Env: ___________
                                                       Date: __________

[ ] 1. Target environment exists and is reachable
    - Platform auth works: ____________________________________
    - API endpoint reachable: _________________________________

[ ] 2. DNS created and propagated
    - Authoritative: __________________________________________
    - Recursive (1.1.1.1, 8.8.8.8): ___________________________
    - TTL for cutover (<=60s): ________________________________

[ ] 3. TLS cert provisioned
    - Hostnames covered: ______________________________________
    - Expires: ________________________________________________
    - Trust chain: openssl s_client -connect host:443

[ ] 4. Database provisioned
    - Reachable from runtime: _________________________________
    - Expand-phase schema applied: ____________________________
    - Connection pool limits: _________________________________

[ ] 5. Env vars in platform
    - Framework prefix applied (NEXT_PUBLIC_*, VITE_*, etc.): _
    - Secrets via secret store, not literals: _________________
    - Preview and Production both configured: _________________

[ ] 6. IAM / runtime role
    - Exists: _________________________________________________
    - Least-privileged verbs: _________________________________
    - Separate from deploy identity: __________________________

[ ] 7. Image in registry
    - Immutable tag or content hash: __________________________
    - Pull credentials valid: _________________________________

[ ] 8. Healthcheck truthful
    - Path matches app route: _________________________________
    - Port matches app binding: _______________________________
    - Checks DB / cache / deps, not just socket bind: _________

[ ] 9. Log aggregation reaches env
    - Test log line visible in backend: _______________________
    - Exception if not: _______________________________________

[ ] 10. Rollback path dry-run
    - Ship v0.0.1 baseline: ___________________________________
    - Ship v0.0.2: ____________________________________________
    - Rollback to v0.0.1: _____________________________________
    - Confirmed user-visible: _________________________________
    - Roll forward to v0.0.2: _________________________________

[ ] 11. Observability reaches env (or no canary claims allowed)
    - Metrics visible: ________________________________________
    - Traces visible (if used): _______________________________
    - Canary allowed: Y / N

Sign-off: _______________________ Date: _____________________
```

Print this. Walk it. Tick every box. The first deploy is the only one where walking a checklist costs less than skipping it.

---

## Further reading

- [Vercel environment variables](https://vercel.com/docs/deployments/environments) on the redeploy-required gotcha.
- [Netlify environment variables](https://docs.netlify.com/build/environment-variables/overview/).
- [Fly.io secrets](https://fly.io/docs/reference/secrets/) on `fly secrets` vs `fly config env`.
- [Cloud Run service identity](https://cloud.google.com/run/docs/securing/service-identity).
- [AWS Lambda execution context](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html) on cold starts and VPC.
- [Kubernetes probes documentation](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/).
- [The Twelve-Factor App, Factor X: dev/prod parity](https://12factor.net/dev-prod-parity) for the parity framing.
