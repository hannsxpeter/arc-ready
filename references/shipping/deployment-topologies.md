# Deployment Topologies

Loaded at Step 2. This file is the picker: given the change in hand and the stack it sits on, which topology is this, what hazards attach to it on the first ship, how does rollback actually look, and where does the real app sit on the 2-to-4-topology spectrum most production systems live on.

The core assumption: there is no "the topology." Almost every non-trivial app is a mixed deploy. The plan names each topology that a change touches and classifies each independently. Treating a Next.js app on Vercel as a single topology, when it is in fact a static bundle plus edge middleware plus serverless API routes plus a managed Postgres plus a cron worker, is where first-deploy blindness begins.

## The seven topologies

| Topology | What it is | Primary artifact |
|---|---|---|
| **Static** | Pre-built HTML/CSS/JS served from a CDN. No per-request code. | Build output directory (`dist/`, `.next/static`, `build/`). |
| **Container** | Long-running process in an OCI image, scheduled on a platform (Kubernetes, Fly.io, ECS, Cloud Run min-instances). | Docker image with content-addressed digest. |
| **Serverless function** | Per-request (or per-event) execution on a provider-managed runtime. Cold-started. | Zipfile, container image (Lambda container), or framework-native output (Vercel, Netlify). |
| **Long-running service** | Container or bare-process on a VM, PID 1, always resident. | VM image, container, deb/rpm, or compiled binary. |
| **Edge / worker** | Code distributed to many PoPs; runs close to the user. V8 isolates (Cloudflare Workers, Vercel Edge) or lightweight containers. | Worker bundle or edge-compatible build output. |
| **Scheduled job** | Time- or event-triggered execution. Cron, Scheduler, Queue consumer. | Same shape as container or serverless; the topology difference is the trigger path. |
| **Mixed** | Two or more of the above. Almost every production app. | Multiple of the above, with a manifest that names each. |

### Static

The pre-built bundle served from a CDN with no per-request compute. Stereotype: `next build && vercel deploy` producing a `_next/static` tree, or `vite build` pushed to S3 + CloudFront.

Ship-it failure modes specific to static:

- **Build-time env var capture.** The env var is read at `build` time, not at request time. Add an env var in the Vercel UI after the deploy and it is `undefined` until you trigger a rebuild ([Vercel env docs](https://vercel.com/docs/deployments/environments); [Vercel issue #5015](https://github.com/vercel/vercel/discussions/5015); [Netlify env docs](https://docs.netlify.com/build/environment-variables/overview/)). This is first-deploy blindness: a green deploy, a green preview, a prod that reads `undefined` from three places.
- **Framework prefix discipline.** `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `PUBLIC_`: the prefix is what makes the value cross the server/client boundary. Wrong prefix means the client gets `undefined`.
- **Cache invalidation.** Your HTML may be immutable-hashed, but `/` and `/sitemap.xml` are not. A stale `/` pointing at a retired bundle is the visible version of the new ship.

### Container

A long-running process in an OCI image, scheduled on Kubernetes, Fly.io, ECS, Cloud Run (with min-instances), or Nomad. This is the default for anything with state in memory, connection pools, or non-trivial cold-start cost.

Ship-it failure modes:

- **Registry-push credentials.** The build pushes to one registry; the target cluster pulls from a different path. Service account missing the `ecr:GetAuthorizationToken` or equivalent. ImagePullBackOff is the first-deploy signature of this.
- **Readiness probe lying.** The probe returns 200 on bind, not on "I can serve a real request." Traffic routes to a pod that has not yet loaded config or opened a DB connection. Kubernetes will mark pods Ready before they are Ready ([Resolve.ai on probes](https://resolve.ai/glossary/how-to-debug-kubernetes-probe-issues); [CubeAPM readiness probe failed](https://cubeapm.com/blog/kubernetes-readiness-probe-failed-error/)).
- **Secret baking.** `COPY . /app` in the Dockerfile drags `.env` into a layer. Later `RUN rm .env` does not remove it; layers are append-only ([Truffle Security](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images); [Intrinsec](https://www.intrinsec.com/en/docker-leak/); [BleepingComputer 10,000+ images](https://www.bleepingcomputer.com/news/security/over-10-000-docker-hub-images-found-leaking-credentials-auth-keys/)).

### Serverless function

Per-request or per-event execution on Lambda, Cloud Functions, Vercel serverless routes, Netlify Functions, or similar. The runtime is the provider's; you bring code.

Ship-it failure modes:

- **Cold-start IAM.** The function's runtime role is distinct from the deployer's role. The deploy succeeds because the deployer has `lambda:CreateFunction`; the first invocation fails because the runtime role is missing `sts:AssumeRole` for the thing the function calls (DynamoDB, S3, Secrets Manager). First-deploy blindness in its purest form.
- **Package size and cold-start weight.** Lambda has a 250MB unzipped layer limit; Vercel has route-level bundle budgets. A dependency bloats the bundle past the limit; the deploy succeeds locally and fails the push.
- **Timeouts that differ across environments.** Default Lambda timeout is 3 seconds; default API Gateway timeout is 30 seconds (max 29 for HTTP APIs). Your code runs 8 seconds locally and is killed in prod.

### Long-running service

A process resident on a VM, a dedicated container with no scale-to-zero, or a bare binary on a host. Historically the default; still correct for anything with persistent connection state (WebSocket hubs, long-lived queue consumers, stateful caches).

Ship-it failure modes:

- **Graceful shutdown missing.** SIGTERM is sent; the process exits without draining connections. In-flight requests 502.
- **Rolling update logic owned by systemd or a hand-rolled script.** The script runs `systemctl restart app` on every host in parallel. Brief total outage during the restart window.
- **PID 1 semantics in containers.** A shell script as PID 1 does not forward signals to the child. `docker stop` hangs for 10 seconds and then SIGKILLs. Use `tini` or set `ENTRYPOINT` correctly.

### Edge / worker

Code distributed across many PoPs and run close to the user: Cloudflare Workers, Vercel Edge Functions, Deno Deploy, Fastly Compute, AWS Lambda@Edge. V8 isolates or lightweight containers; no full Node runtime.

Ship-it failure modes:

- **Missing Node/Bun APIs.** `fs`, `net`, `child_process`, many `crypto` primitives, `Buffer` in some runtimes. A dependency that worked in serverless fails at bundle time or first invocation at the edge.
- **Propagation latency.** The deploy is "done" at the control plane; the new version is not everywhere. For tens of seconds to a minute, different users hit different versions. This interacts with code-vs-data rollback asymmetry: if the new version writes a new schema variant, the old version at the edge is still writing the old variant.
- **Distributed cache invalidation.** Purging a cache key is eventually consistent across PoPs; a stale cached response survives the deploy. Plan for the stale window or bump the cache-key version.

### Scheduled job

Cron on Kubernetes, EventBridge Scheduler -> Lambda, Cloud Scheduler -> Cloud Run, Vercel Cron, Fly Machines cron. Underneath, the artifact is usually container or serverless; the topology difference is the trigger.

Ship-it failure modes:

- **Overlap.** The job takes longer than the interval. Two copies run concurrently, race on the same row, or double-charge. Use a leader lock or `@Singleton`-style guard.
- **Silent failure.** A cron that fails emits an exit code nobody reads. Log aggregation was never wired; alerting is absent. Weeks pass before anyone notices the nightly backfill has not run.
- **Timezone drift.** The scheduler's zone is UTC; the business reads "midnight" as local. The report runs 8 hours off.

### Mixed

Most real apps. A typical SaaS is: static (marketing site and dashboard shell) + serverless (API routes or Lambda) + long-running (queue workers, auth service) + scheduled (nightly ETL) + managed data plane (Neon, RDS, Upstash).

The discipline: the deploy plan names each topology that a change touches, classifies the change-class for each, and carries an independent rollback path per topology. A change that updates one Postgres column and three code topologies has four rollback conversations, not one.

## First-deploy hazards per topology

First-deploy blindness has a shape. This is the catalog: the specific things that bite on the first push to a new environment and do not bite again.

| Topology | Cold-start gotcha | Why the second deploy does not hit it |
|---|---|---|
| Static | Env vars unread at build; framework prefix wrong; DNS not propagated. | Subsequent deploys reuse the existing env-var set and DNS. |
| Container | Registry pull creds; network policy; readiness probe path; namespace quota. | Cluster state retains the image-pull secret; next deploy pushes a new tag only. |
| Serverless | Runtime IAM role missing; dead-letter queue unconfigured; provisioned concurrency absent. | The runtime role exists from deploy 1; you are only changing code after. |
| Long-running | DNS, TLS cert, systemd unit path, firewall, SELinux. | Host state persists. |
| Edge / worker | Custom domain binding, KV namespace binding, secret binding, wrangler config drift. | Bindings persist; deploys only change the bundle. |
| Scheduled | Scheduler resource exists; IAM invoke permission; timezone. | Scheduler resource persists across deploys. |

Per Mode A (first deploy), every row above is a hard-block gate. Per Mode B, the relevant row is a quick-check ("the binding still exists; the deploy only changes the bundle"). The difference between Modes is which set of questions you ask.

## Rollback characteristics per topology

Rollback is not uniform. The code-vs-data asymmetry applies per topology, and the mechanism differs.

| Topology | Rollback mechanism | Time-to-revert (typical) | Sharp edges |
|---|---|---|---|
| Static | Point the CDN alias at the previous build. Atomic, provider-native. | Seconds. | The cached HTML at intermediate CDNs; the service-worker `sw.js` that still believes in the new version. |
| Container | Re-tag the previous image as `:prod` (or the platform equivalent: `flyctl releases rollback`, `kubectl rollout undo`, `gcloud run services update-traffic`). | 30s to a few minutes. | ImagePullBackOff if the old tag was garbage-collected; liveness probe thrash during the swap. |
| Serverless | Provider-specific. Lambda: update `$LATEST` alias to previous version ARN. Vercel: "instant rollback" in the UI points the deployment alias back. Netlify: "publish deploy" on an earlier build. | Seconds. | Old versions can be GC'd; pin retention. Environment variable changes since the rolled-back deploy persist. |
| Long-running | Rolling update back to the previous artifact. Blue/green swap if that is the topology. | Minutes. | The rollout is not atomic. During the roll-back, some hosts are old and some are older. If the data schema changed in between, welcome to mixed-schema land. |
| Edge / worker | Wrangler rollback or platform revert. Propagation is eventually consistent. | Seconds at control plane, tens of seconds globally. | The stale cache; the KV value that was written by the new version and is not valid for the old. |
| Scheduled | Not really a rollback. Disable the schedule, fix, re-enable. If the job partially ran, manual compensating-forward. | Varies. | The side effects the job already emitted (emails, charges, webhooks). Side-effectful class per Step 5. |

Every "rollback" bullet above assumes the change is code-only. If the change is data-forward, rollback is not the plan; `compensating-forward` is. This is the load-bearing discipline from SKILL.md Step 5 and applies to every topology in the table.

## Decision matrix: picking a topology

Given a set of constraints, the topology choices collapse. This is the quick table; when in doubt, pick what your stack-ready output already chose and do not re-decide.

| Constraint | Static | Container | Serverless | Long-running | Edge | Scheduled |
|---|---|---|---|---|---|---|
| Team size 1-3 | Good | OK | Good | OK | Good | Good |
| Team size 4-10 | Good | Good | Good | Good | OK | Good |
| Team size 10+ | OK | Good | OK | Good | OK | Good |
| Spiky traffic | Good (CDN) | OK (autoscale) | Good | Poor (overprovision) | Good | N/A |
| Steady traffic | Good | Good | OK (cold starts) | Good | OK | N/A |
| Stateful (in-memory) | Never | Good | Never | Good | Never | N/A |
| Stateful (persistent to store) | N/A | Good | Good | Good | Good | Good |
| SOC2 / HIPAA / PCI | Good (if CDN is compliant) | Good | Good (if provider compliant) | Good | Tricky (data locality) | Good |
| Latency-critical global | Good | OK (multi-region) | OK | OK (multi-region) | Best | N/A |
| < 100ms p50 startup | N/A | Good | Poor (cold start) | Good | Good | N/A |
| Long-running (>30s) | N/A | Good | Poor (timeouts) | Good | Poor | Good |
| Irregular / event-driven | N/A | OK | Good | OK | Good | Good |

Shorthand rules:

- **Stateful in-memory = long-running or container.** Serverless loses the state between invocations. Edge loses it harder.
- **Latency-global = edge or multi-region container.** Everything else pays a geography tax.
- **Long-running work (>30s, batch, ML inference) = container or scheduled job.** Serverless providers have limits; crossing them is the topology saying no.
- **Compliance-heavy = pick provider with the certs first.** Static and serverless are fine if the provider is compliant. Edge is tricky for data-locality rules.

## Mixed topology in practice: worked examples

Real apps. Each is 3 to 5 topologies, and the deploy plan has 3 to 5 rollback entries.

### Vercel + Neon

- Static: the Next.js client bundle on Vercel's CDN. Rollback: instant-rollback to previous deployment.
- Serverless: Next.js API routes and server actions. Rollback: same as static (Vercel treats them as one deployment). Note: the server actions' env-var reads are at request time, so env-var changes apply immediately, not at build time (different from NEXT_PUBLIC_*).
- Edge: Next.js middleware at the edge. Rollback: same as the Vercel deploy.
- Managed data plane: Neon Postgres. No rollback. Migration discipline (expand-only, contract deferred) is the entire story. Any data-forward change is a compensating-forward candidate.
- Scheduled: Vercel Cron. Rollback: disable the cron, fix, re-enable. Side effects are side effects.

The trap: treating the whole thing as one atomic Vercel deploy. It is not. The DB migration lives outside Vercel's rollback graph.

### Fly.io app (container + Postgres)

- Container: `flyctl deploy` on the app. Rollback: `flyctl releases rollback <id>`. Typical revert under 90 seconds on rolling strategy.
- Long-running workers: separate Fly app or separate process group. Rollback: same mechanism, separate artifact.
- Managed data plane: Fly Postgres or Neon. No rollback for data-forward changes.
- Scheduled: Fly machines with cron trigger, or an external scheduler. Rollback: stop the machine.

The trap: the DB lives in the same org but is a separate service with separate rollback semantics. The same-artifact invariant applies to the app image, not to the DB schema.

### Google Cloud Run + Cloud Scheduler

- Container: Cloud Run service. Rollback: `gcloud run services update-traffic --to-revisions=<prev>=100`. Atomic at the traffic-split layer.
- Scheduled: Cloud Scheduler -> Cloud Run job (via Pub/Sub or direct HTTPS). Rollback: revert the job image, re-deploy.
- Managed data plane: Cloud SQL or AlloyDB. As above.
- Static: Cloud Storage + Cloud CDN. Atomic alias swap.

The trap: Cloud Run's traffic-split rollback is per-revision. If the new revision ran a migration, the migration ran. Rollback of the code does not rollback the migration.

### AWS Lambda + DynamoDB + CloudFront

- Serverless: Lambda behind API Gateway or ALB. Rollback: shift `$LATEST` alias to previous version, or update Lambda function configuration to previous code.
- Static: CloudFront in front of an S3 bucket. Rollback: update the CloudFront origin path or re-upload previous build.
- Managed data plane: DynamoDB. Non-relational but still data-forward: an item written with a new attribute is forward. Reverting the Lambda does not remove the attribute.
- Scheduled: EventBridge Scheduler -> Lambda. Rollback: disable the rule.
- Edge: Lambda@Edge or CloudFront Functions. Rollback: re-associate previous version with the distribution; propagation takes minutes.

The trap: IAM. The rollback Lambda alias now points at a code version that expects different IAM permissions than what the runtime role grants (or vice versa, if IAM changed between versions). Role changes must be ship-1-deploy-out-of-band from code changes.

## Naming in the deploy plan

Per SKILL.md Step 2, the topology note is 6-15 lines. For a mixed app it names each topology separately. Example for a Next.js on Vercel + Neon app:

```
Topology: mixed (static + serverless + edge + managed-DB + scheduled)
- Static: Next.js client bundle; Vercel CDN; atomic alias swap on rollback.
- Serverless: Next.js route handlers + server actions; same deploy as static;
  env vars read at request time.
- Edge: middleware.ts at Vercel Edge; deployed as part of the same build.
- Managed DB: Neon Postgres (branch: main). Any schema or data change is
  data-forward class; no rollback; compensating-forward only.
- Scheduled: Vercel Cron /api/cron/reconcile at 0 */6 * * *; rollback is
  disable cron, fix, re-enable. Side effects acknowledged.
Artifact path: single Vercel deployment ID; same artifact promotes from
  preview -> production alias via `vercel promote`.
```

The trap the note prevents: a mental model of "I deployed it to Vercel" collapses five topologies into one rollback path. Writing them out forces the Step 5 classification pass to run against each.

## Common cross-topology footguns

- **Env var promotion drift.** Staging has `DATABASE_URL=...` pointing at staging Neon; prod has `DATABASE_URL=...` pointing at prod Neon. The build is same-artifact; the env is different. Good. The hazard: a new env var is added in staging, ship the artifact to prod, and the var is `undefined` in prod until someone notices. Every first prod ship after an env-var add is a first-deploy gate even on a mature pipeline.
- **Healthcheck path divergence.** `/health` exists on the container topology; the static topology returns 404. An aggregated healthcheck ("every topology returns 200") flips red for reasons that do not matter.
- **DNS propagation on topology change.** You moved a subdomain from Cloudflare Pages (static) to a Fly app (container). The cert issues fine; DNS takes 24 hours on the old TTL. Users hit the retired deploy for half a day.
- **Queue consumer lag on container rollout.** A 10-pod rolling update cycles pods one-by-one while the queue backs up. If the deploy runs at peak ingest, queue depth spikes and downstream SLOs breach on a green deploy.
- **Edge cache poisoning.** A bug in the new version writes an incorrect response into the CDN with a 1-hour TTL. Rollback the code; the CDN still returns the bad response until the TTL expires or you manually purge.

## Further reading

Source citations in `RESEARCH-2026-04.md`:

- Sections 1.3 and 3.4 on Dockerfile layer leaks and platform-native CD gotchas (Vercel/Netlify env-var traps, framework prefixes): [Truffle Security](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images); [Intrinsec](https://www.intrinsec.com/en/docker-leak/); [Vercel env docs](https://vercel.com/docs/deployments/environments); [Netlify env docs](https://docs.netlify.com/build/environment-variables/overview/).
- Section 1.2 on readiness probes that return 200 on socket bind: [Resolve.ai](https://resolve.ai/glossary/how-to-debug-kubernetes-probe-issues); [CubeAPM](https://cubeapm.com/blog/kubernetes-readiness-probe-failed-error/); [groundcover](https://www.groundcover.com/learn/kubernetes/deployment-not-updating).
- Section 3.2 on GitOps rollback semantics for Argo CD and Flux: [Devtron comparison](https://devtron.ai/blog/gitops-tool-selection-argo-cd-or-flux-cd/); [Spacelift Flux vs Argo CD](https://spacelift.io/blog/flux-vs-argo-cd).
- Section 1.1 on "passes validate, fails in prod" IaC and K8s patterns and the DataTalks.Club destruction incident: [Testkube](https://testkube.io/blog/system-level-testing-ai-generated-code); [Gruntwork](https://www.gruntwork.io/blog/thinking-of-using-ai-with-terraform); [dev.to rsiv](https://dev.to/rsiv/ai-sped-up-development-not-shipping-5g1).
- Section 7.2 on same-artifact promotion as the single largest drift-prevention lever.
