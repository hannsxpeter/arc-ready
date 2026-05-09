# Progressive Delivery

Loaded at Step 7 of the workflow and for Tier 4 completion. This file covers the five rollout strategies, the paper-canary rule, the blast-radius rule, feature-flag-as-deploy-strategy, readiness probe discipline, and connection draining.

**Canonical scope:** how traffic moves from the old version to the new version and how the deploy plan is structured to detect a bad change before it reaches 100% of users. **See also:** `rollback-playbook.md` for what to do when the canary trips; `zero-downtime-migrations.md` for the schema side of the same problem.

The one-line framing: a rollout strategy is not a tool, it is a contract. The contract is "if the new version is bad, we notice in time and revert before the blast radius grows." Every strategy below is a different way of writing that contract. A plan that does not name which strategy it is using is a plan that has no contract, which means it ships everything to everyone at once and hopes.

---

## Part 1. The five rollout strategies

### 1.1 All-at-once

Ship to 100% of the target in one step. The deploy system takes down the old and stands up the new, or swaps the pointer in a single action.

**When to use:**
- Isolated internal tools with small user counts and no SLO.
- Staging and preview environments where the point is integration testing, not user protection.
- Config-only hotfixes where the alternative (a broken prod) is worse than the risk of the fix.
- Batch jobs and scheduled workers where "traffic" is a cron trigger, not a continuous stream.

**When not to use:**
- Any user-facing prod change where the blast radius is larger than "the engineer watching this terminal."
- Anything that runs on every request (edge workers, middleware, auth layers). CrowdStrike 2024 shipped a content file to 100% of Windows hosts in one step and took out 8.5M machines ([CrowdStrike RCA](https://www.crowdstrike.com/en-us/blog/channel-file-291-rca-available/)).
- Anything pushed to endpoint devices, where "rollback" requires users to take action.

**What can go wrong:** the canonical all-at-once failure is a uniform regression: the change is bad for 100% of traffic, and by the time the first alert fires, the bad version is already serving 100% of users. There is no interstitial state where you learn and stop.

### 1.2 Rolling update

The default for long-running services under an orchestrator (Kubernetes, ECS, Nomad, Fly.io). New instances roll in, old instances roll out, readiness probes gate the rollover. Typical knobs: `maxSurge` (how many extra pods exist mid-rollout) and `maxUnavailable` (how many old pods can be down at once).

**When to use:**
- Stateless HTTP services with a load balancer in front.
- Services where the readiness probe is truthful (see section 5).
- Deploys where the new and old versions can coexist for the duration of the rollover (no breaking API changes mid-flight).

**When not to use:**
- Services where the new version cannot coexist with the old (the expand phase has not been run yet, a config file is incompatible). Do the expand first; see `zero-downtime-migrations.md`.
- Services without a real readiness probe; a lying probe turns a rolling update into a silent outage.

**What can go wrong (the canonical AI bug):** AI-generated Deployment manifests ship without readiness probes, or with probes whose path or port does not match the app ([Resolve.ai](https://resolve.ai/glossary/how-to-debug-kubernetes-probe-issues), [CubeAPM](https://cubeapm.com/blog/kubernetes-readiness-probe-failed-error/), [groundcover](https://www.groundcover.com/learn/kubernetes/deployment-not-updating)). Kubernetes then marks pods Ready before they are ready and routes traffic to a process that cannot serve it. The rollout either stalls indefinitely or, worse, completes with every new pod happily failing.

**Concrete example (Kubernetes rolling update):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: api
        image: registry.example.com/api@sha256:abc123
        readinessProbe:
          httpGet:
            path: /healthz/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
          failureThreshold: 2
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
        terminationGracePeriodSeconds: 30
```

`maxUnavailable: 0` means the rollover cannot shrink capacity; `maxSurge: 2` means it can temporarily exceed it by two. The `preStop` sleep and `terminationGracePeriodSeconds` are the connection-draining pattern covered in section 6.

### 1.3 Blue/green

Two parallel fleets (blue: current, green: new). Deploy to the idle fleet, validate, flip the load balancer pointer. Rollback is the reverse flip.

**When to use:**
- Services where the rollover must be instantaneous from the user's perspective (no rolling middle state).
- First-deploy confidence checks: you can stand up green, hit every healthcheck, and flip only when satisfied.
- Platforms with native support (Vercel's immutable deployments are effectively blue/green by URL; AWS CodeDeploy has a first-class `BLUE_GREEN` deployment type).

**When not to use:**
- Cost-sensitive environments where double capacity during cutover is prohibitive.
- Stateful services where the old fleet is holding state the new fleet has no path to (sticky sessions, in-memory caches); you end up with split-brain data.

**What can go wrong:** the green fleet passes a synthetic check but fails on real traffic because the synthetic check did not exercise the critical path. The flip happens, errors spike, the reverse flip is easy, but the wasted time is on real users.

**Concrete examples:**
- **Vercel instant rollback:** every deploy is a new immutable URL; promoting to prod swaps the alias. "Rollback" is re-aliasing to the previous deployment ID, which is seconds ([Vercel docs](https://vercel.com/docs/deployments/environments)).
- **AWS CodeDeploy blue/green on ECS:** you define `deploymentConfig: CodeDeployDefault.ECSAllAtOnce` with a `BLUE_GREEN` deployment type; the new task set comes up, the listener rule shifts, the old task set drains.

### 1.4 Canary

A small percentage of traffic routes to the new version. You watch a named metric over a named window; if the metric breaches a numeric threshold, an automated trigger reverts the routing.

**When to use:**
- Prod-scale services with real traffic, real metrics, and real observability.
- Changes where the risk is "unknown, probably okay, want to verify before 100%" rather than "known bad" or "known safe."
- Any stack where `observe-ready` (or equivalent) is wired up to emit the metric back into the rollout controller.

**When not to use:**
- You do not have an observability stack that can emit the success metric at the required latency. A canary that reads metrics on a 5-minute lag cannot catch a regression in a 10-minute window.
- The change is already breaking a hard invariant in staging. A canary is not a debugger; fix the break first.

**What can go wrong:** the canary is a paper canary. See section 2.

**Concrete example (Argo Rollouts with an analysis template):**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: api
spec:
  strategy:
    canary:
      steps:
      - setWeight: 5
      - pause: {duration: 5m}
      - analysis:
          templates:
          - templateName: success-rate
          args:
          - name: service-name
            value: api
      - setWeight: 25
      - pause: {duration: 10m}
      - analysis:
          templates:
          - templateName: success-rate
      - setWeight: 50
      - pause: {duration: 10m}
      - setWeight: 100
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m
    successCondition: result[0] >= 0.995
    failureLimit: 2
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status!~"5.."}[2m]))
          /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[2m]))
```

The `AnalysisTemplate` is the metric contract. Without it, the `Rollout` is just a traffic slider with pauses, which is a paper canary.

### 1.5 Ring deployment

Cohorts in order: internal employees, then beta customers, then one geographic region, then all. Each ring is a blast-radius limit.

**When to use:**
- Client-side code that ships to endpoint devices: mobile apps, desktop apps, IoT agents, browser extensions, game clients.
- SaaS products with a "dogfood" internal tier and a publicly-available tier.
- Changes where detection requires real user behavior, not just HTTP-level metrics.

**When not to use:**
- Services where every request looks the same and cohorting adds no signal. Regular canary is lighter.
- Emergency hotfixes where waiting for the next ring is worse than the risk.

**Concrete example patterns for client-side code:**
- **Mobile apps:** phased release on App Store Connect (1%, 2%, 5%, 10%, 20%, 50%, 100% over 7 days) and Google Play staged rollout (similar).
- **Desktop:** Electron's `autoUpdater` with `feed` URLs keyed per ring. Channels: `dev`, `beta`, `stable`.
- **IoT / edge agents:** the agent polls a config server that returns a version per device cohort. The server respects the ring schedule.

CrowdStrike's 2024 Channel File 291 incident is the anti-example: a kernel-level content file shipped to 100% of Windows hosts with no ring, no staged rollout, no cohort ([CrowdStrike RCA](https://www.crowdstrike.com/en-us/blog/channel-file-291-rca-available/)). A ring deployment with even one early cohort would have caught the BSOD before it hit 8.5M machines.

---

## Part 2. The paper-canary rule

**A canary without all four of the following is not a canary. It is a paper canary. Refuse to call it one.**

| Required | What it means | Bad | Good |
|---|---|---|---|
| **Named success metric** | A specific measurable signal. | "we'll watch Grafana for a bit" | `sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))` |
| **Numeric threshold** | A number, not an adjective. | "error rate should be low" | `error rate < 0.5%` |
| **Time or request window** | A bounded observation period. | "keep an eye on it" | `15 minutes OR 10,000 requests per region, whichever is shorter` |
| **Automated rollback trigger** | A programmatic action, not a human click. | "if it looks bad, page me" | `analysis template sets rollout to abort; traffic reverts to stable within 60s` |

If any of the four is missing, the plan does not get to call the step a canary. Pick all-at-once (if the blast radius permits) or stop and wire up the observability first.

**Why this is strict:** a canary that looks like a safety mechanism but is not one is worse than no canary. Teams ship with the false confidence that "we're canarying this," skip the harder conversations about blast radius and rollback, and discover in prod that the traffic slider with pauses they called a canary was never going to catch anything. LaunchDarkly, Argo Rollouts, and Flagger all document this explicitly: "Sophisticated monitoring and alerting are required to be effective" ([LaunchDarkly on canary](https://launchdarkly.com/blog/four-common-deployment-strategies/), [Argo Rollouts analysis docs](https://argo-rollouts.readthedocs.io/en/stable/features/analysis/), [Flagger docs](https://flagger.app/)).

### 2.1 Good paper-canary examples (in real config)

**Flagger canary resource with a metric template:**

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  service:
    port: 8080
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
    webhooks:
    - name: load-test
      url: http://flagger-loadtester.test/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://api-canary:8080/"
```

`thresholdRange.min: 99` (success rate percent), `max: 500` (latency ms), `interval: 1m` (window), and `threshold: 5` (number of failed checks before rollback) make this a real canary.

**LaunchDarkly progressive rollout (flag-driven):**

```json
{
  "kind": "progressive",
  "steps": [
    { "rolloutWeight": 5,  "duration": "PT5M" },
    { "rolloutWeight": 25, "duration": "PT10M" },
    { "rolloutWeight": 50, "duration": "PT15M" },
    { "rolloutWeight": 100 }
  ],
  "measuredRollout": {
    "metric": "api-error-rate",
    "threshold": 0.005,
    "action": "rollback"
  }
}
```

LaunchDarkly's measured rollouts tie the percentage progression to a metric; a regression auto-rolls-back the flag ([LaunchDarkly measured rollouts docs](https://launchdarkly.com/)).

### 2.2 Canary metric picking

| Metric | When to use | When not to |
|---|---|---|
| **p99 error rate (5xx, non-2xx)** | HTTP services, API backends, anything where "did it succeed" is the primary signal. Fast to compute, low variance, catches most regressions. | Services where "success" at the HTTP layer does not mean success for the user (a 200 that returns an empty page). |
| **p95 latency** | User-facing interactive services where slowness matters as much as failure. Catches deadlocks, accidental N+1 queries, cold-start regressions. | Services where latency varies by 10x legitimately (batch endpoints, long-running queries). |
| **Business metric on critical path** | Checkout conversion, signup completion, login success. The metric the business cares about. | Low-traffic paths where the signal takes too long to accumulate inside the canary window. |

The strongest canary combines two or three: error rate as the fast-fail, latency as the slower-fail, business metric as the "did anything actually work" backstop. Each has a separate threshold; any one breaching rolls back.

---

## Part 3. The blast-radius rule

**No untested change goes 0 to 100 in one step.**

CrowdStrike 2024 (8.5M hosts, one-step push), Cloudflare 2019 (27-minute global 502 outage from a WAF rule pushed globally in one step), and Facebook BGP 2021 (6-hour global outage from a backbone-capacity command run across the whole fleet with no staged validation) are the same shape ([CrowdStrike RCA](https://www.crowdstrike.com/en-us/blog/channel-file-291-rca-available/), [Cloudflare 2019 blog](https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/), [Cloudflare on Facebook 2021](https://blog.cloudflare.com/october-2021-facebook-outage/), [Engineering at Meta](https://engineering.fb.com/2021/10/04/networking-traffic/outage/)).

The deploy-ready invariant: the plan names, for every change, what the first non-trivial cohort is. If the plan does not name a cohort less than 100%, the plan fails this rule.

The exception: a change that is known-safe because it has already been run at scale in a shadow environment, with the exact same artifact, against the exact same shape of traffic. In practice this exception is rare. Most changes labelled "safe" are "untested against prod traffic."

---

## Part 4. Feature-flag-as-deploy-strategy

Ship the code dark (behind a flag, default off). Flip the flag separately. The flag-flip IS the deploy.

**Why this matters:** it decouples "the code is present" from "the code is active." A regression in the dark code path is caught in prod with zero users. The flag-flip is instant both ways; the revert is `flag.off()`, not a redeploy.

**The kill-switch pattern:** every risky feature ships with a global flag that defaults on *but can be flipped off from a single control plane without a redeploy*. When the feature misbehaves in prod, the on-call flips the kill switch; the code path is bypassed; the incident is contained while a proper fix is written.

**The Knight Capital footgun:** flag names are not free. A reused flag name from a prior deploy can wake up dormant code that was supposed to be dead. Knight Capital 2012 partial-deployed new code to 7 of 8 servers; the 8th still had old "Power Peg" code; a reused feature flag activated that dormant code and caused a $460M loss in 45 minutes ([Kosli](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/), [Doug Seven](https://dougseven.com/2014/04/17/knightmare-a-devops-cautionary-tale/)).

The discipline: when a feature is retired, the flag name is retired too, along with every branch that read the flag. Removal of the branch is a separate deploy after the flag is confirmed fully off. `rollback-playbook.md` covers the flag lineage audit.

---

## Part 5. Readiness probe discipline

A probe that returns 200 as soon as the HTTP server binds is lying.

**What the probe must actually check, in order:**
1. The HTTP server is bound and accepting connections.
2. Config has loaded (env vars are present, secrets are read).
3. The database connection pool is reachable and has at least one healthy connection.
4. Required cache / queue / service dependencies the app cannot function without are reachable.
5. An in-process smoke check runs: "can I execute the critical-path request shape the app was written to serve?"

A probe that does only (1) returns 200 before the app is ready. Kubernetes marks the pod Ready, traffic arrives, every request is a 500 because the DB pool is empty, and the rolling update completes with every new pod happily failing.

**Good probe shape (HTTP):**

```python
@app.get("/healthz/ready")
def ready():
    if not config.loaded:
        return Response(status=503)
    if not db.ping(timeout=0.5):
        return Response(status=503)
    if not cache.ping(timeout=0.3):
        return Response(status=503)
    return Response(status=200)

@app.get("/healthz/live")
def live():
    return Response(status=200)
```

The split between `/healthz/ready` and `/healthz/live` matters. Liveness answers "is the process alive," readiness answers "can I serve a real request." Using one endpoint for both is a common AI-generated manifest bug: a flaky dependency then triggers liveness restarts, restart loop, cascading failure.

---

## Part 6. Connection draining and graceful shutdown

During a rolling update, when a pod is about to go away, in-flight requests need to finish and new requests need to route elsewhere. The steps:

1. The orchestrator marks the pod as "not Ready" (unroutes it from the load balancer).
2. The orchestrator calls `preStop` (Kubernetes) or the equivalent hook.
3. The orchestrator sends SIGTERM.
4. The app stops accepting new requests, finishes in-flight ones, and exits 0.
5. The orchestrator's `terminationGracePeriodSeconds` is the hard cap.

**Why `preStop` matters:** there is a brief window after the pod is marked not-Ready but before the load balancer's endpoint list has converged. Without a `preStop` sleep, the SIGTERM races the last few requests. The canonical pattern: `preStop: sleep 15` to let the LB converge, then SIGTERM triggers the graceful shutdown.

**Application-side graceful shutdown (Node.js example):**

```javascript
const server = app.listen(port);
process.on('SIGTERM', () => {
  server.close(() => {
    db.pool.end();
    cache.quit();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 25_000);
});
```

The `setTimeout` fallback is the "abandon-in-flight-after-25s" backstop. Without it, a slow request holds the process open indefinitely and the orchestrator eventually SIGKILLs, which drops in-flight connections.

---

## Further reading

- [Argo Rollouts documentation](https://argo-rollouts.readthedocs.io/) on canary, blue/green, and analysis templates.
- [Flagger documentation](https://flagger.app/) on progressive delivery for Kubernetes.
- [LaunchDarkly, "Four common deployment strategies"](https://launchdarkly.com/blog/four-common-deployment-strategies/).
- [Martin Fowler, CanaryRelease](https://martinfowler.com/bliki/CanaryRelease.html) and [BlueGreenDeployment](https://martinfowler.com/bliki/BlueGreenDeployment.html).
- [CrowdStrike 2024 Channel File 291 RCA](https://www.crowdstrike.com/en-us/blog/channel-file-291-rca-available/) as the blast-radius cautionary tale.
- [Cloudflare, "Details of the July 2, 2019 outage"](https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/) for the same lesson in WAF form.
- [Knight Capital postmortem writeups](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/) on feature-flag reuse.
- [Kubernetes probes documentation](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/) on probe semantics.
