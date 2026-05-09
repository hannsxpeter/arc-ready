# Dashboards

Loaded at Step 6 of the workflow. Tier 3 gate. The above-the-fold rule and the blind-dashboard refusal.

**Canonical scope:** what a primary dashboard looks like, what belongs above the fold, the per-service-type catalog, the sprawl budget. **See also:** `slo-design.md` for the SLIs charted; `alert-patterns.md` for the alerts linked from the dashboard; `vendor-landscape.md` for Grafana vs. Datadog vs. Honeycomb rendering differences.

The one-line framing: the primary dashboard is the operator's answer key, not the engineer's art project. It answers one question in the first screen: is this service meeting its SLOs right now. If it cannot, it is a **blind dashboard**, and observe-ready refuses to accept it as a deliverable.

---

## Part 1. The above-the-fold rule

Seven or fewer charts on the first screen. Each chart answers a question. No decoration.

### 1.1 The 7-chart limit

Flexport reduced ~2,700 dashboards to ~60; ASAPP had 400+ Grafana dashboards before cleanup ([Tasman](https://www.tasman.ai/news/dashboard-sprawl-is-killing-your-business); [Tech Monitor on ASAPP](https://www.techmonitor.ai/leadership/digital-transformation/asapp-dashboard-sprawl-case-study)). The shape that survived was short, bound, and maintained. Seven charts is enough to show an SLO burn, a few SLIs, and two or three diagnostics. More than seven pushes work below the fold, which is where it should go anyway.

The limit is heuristic. Six is fine. Eight is OK if one of the charts is a compact row of small status cells. Twelve is too many.

### 1.2 The four canonical charts above the fold

A primary dashboard's first four charts, in order:

1. **Error budget remaining (big number or gauge).** The one number the operator needs first. "How much budget is left in the window."
2. **Burn rate (short and long window time series).** "How fast are we consuming the budget right now."
3. **SLI trend (time series per user journey).** "How does the SLI look across the window."
4. **Top diagnostic for the service (time series).** "What is the first cause to check when the SLO burns." For a request/response service, usually latency p99 broken out by route. For a worker, queue depth and age.

### 1.3 Three more charts max

Depending on the service:

- Dependency latency (upstream calls, DB, cache).
- Saturation of the bottleneck resource (connection pool, worker concurrency).
- Recent deploys / releases overlaid as annotations on the burn chart (deploy-ready / launch-ready integration).
- Error rate broken out by route or job_type.
- Synthetic-check results.

The test for "does this chart belong above the fold": is an operator likely to read it in the first 30 seconds during an incident? If no, below the fold.

### 1.4 What goes below the fold

- Every RED/USE chart that is not already above.
- Infrastructure metrics: per-host CPU, memory, disk, network.
- Non-SLO business metrics.
- Trends longer than the SLO window (monthly, quarterly).

Below-the-fold is not "deleted." It is "not on the 30-second path."

---

## Part 2. Chart semantics are strict

### 2.1 Latency: p99, not avg

Average latency hides the tail. The p99 is what the bottom 1% of your users experience. If your SLO is framed in terms of "99% of requests complete in under N ms," the chart is p99.

Some vendors default to `avg` in the UI; override. Grafana's histogram_quantile, Datadog's p99 aggregation, Honeycomb's P99 heatmap are the idioms.

### 2.2 Rate: events/sec, not raw counters

`rate()` (Prometheus), `per_second()` (Datadog), or equivalent. Charting raw counters produces saw-toothed lines that are impossible to read.

### 2.3 Error rate: ratio, not count

`errors / total`, not just `errors`. 500 errors on 10k requests is different from 500 errors on 10M.

### 2.4 Time ranges: align across panels

If the first chart is 1h and the second is 24h, the panels misrepresent concurrent events. Pick one time range per dashboard (usually matching the short window of the burn-rate alert) and give the dashboard a time-picker for the operator to change.

### 2.5 Annotations: deploys and incidents

Overlay deploy events (from `.deploy-ready/STATE.md`) as vertical bars on the time series. "Did this error rate start with deploy v1.12.3" becomes a visual question, not a correlation chase.

Overlay known incidents as vertical bands. Past incidents in the same window give context.

### 2.6 Color and symbology

- Red means bad. Always. Do not use red for "positive trend going up" even if culturally common in some sectors.
- Thresholds visible on the chart (the SLO line as a horizontal reference).
- Avoid stacked area charts for series that should be compared (they hide individual contributions).

---

## Part 3. Per-service-type catalogs

Every service of the same topology has the same shape of primary dashboard. An operator who knows one service can read any service of the same type in 30 seconds.

### 3.1 Request/response service

Above the fold:

1. Error budget remaining for availability SLO.
2. Burn rate (1h short, 1h long).
3. p99 latency per route (top routes; not all).
4. Request rate per route.
5. Error rate (5xx / total).
6. Dependency latency (DB, cache, upstream API) side by side.
7. Deploy annotations on the burn chart.

### 3.2 Worker service

Above the fold:

1. Queue depth across key queues.
2. Queue oldest-item age (the freshness proxy).
3. Processing rate (dequeue rate).
4. Processing failure rate.
5. Retry rate.
6. Dead-letter queue depth.
7. Worker concurrency utilization.

### 3.3 Batch / scheduled job service

Above the fold:

1. Last successful run timestamp (freshness at a glance).
2. Recent runs: success, failure, runtime.
3. Records processed per run (trend).
4. Per-stage latency breakdown.
5. Expected vs. actual schedule adherence.

### 3.4 Edge worker / serverless

Above the fold:

1. Per-region error rate.
2. Per-region p99 latency.
3. Per-region invocation rate.
4. Cold-start rate and latency.
5. CPU time per invocation (billing-proxy).
6. Subrequest count per invocation.

### 3.5 Data pipeline

Above the fold:

1. Freshness (time since last watermark).
2. Completeness (records out / records in).
3. Pipeline runtime per run.
4. Stage-level duration breakdown.
5. Validation failure rate.
6. Deduplication count (if relevant).
7. Lag for each consumer / downstream reader.

---

## Part 4. Drilldown dashboards

Primary shows "is the SLO healthy." Drilldown shows "why is it not."

Conventions:

- One drilldown per primary. Linked from each chart on the primary.
- Drilldown is free to have more charts; the purpose is debugging.
- Drilldown breaks out dimensions the primary aggregated away (per-endpoint, per-region, per-tenant).
- Drilldown includes the trace exemplars, the log exemplars, the error-tracker exemplars.

### 4.1 Exemplars

An exemplar is a link from a metric data point to a specific trace that contributed to the point. "This p99 spike corresponded to this specific slow trace." Prometheus (with exemplar support), Grafana (OTel / Tempo integration), Honeycomb (BubbleUp), and Datadog (APM trace metrics) all have some form of exemplar. Configure it; it is the fastest path from "something is wrong" to "here is the slow request."

---

## Part 5. Dashboard metadata

Every dashboard, primary or drilldown, carries:

| Field | Purpose |
|---|---|
| `owner` | Team or individual responsible for the dashboard. |
| `purpose` | One-line description of what question this dashboard answers. |
| `last_reviewed` | ISO date of the last review. A dashboard without a review date in 180 days is a prune candidate. |
| `slo_bindings` | Which SLO(s) this dashboard surfaces. If none, why does the dashboard exist? |
| `alerts_linked` | Which alert policies render into this dashboard. |
| `dependencies` | What infrastructure the dashboard depends on to render (the independence-test input). |

In Grafana, set these as dashboard tags or in the dashboard description JSON. In Datadog, use the description field and the tag system. In Honeycomb, boards carry names and descriptions that can hold this metadata.

### 5.1 Ownerless dashboards are deleted, not muted

Muting by moving to an "archive" folder leaves the dashboard reachable and usable by whoever created it. A year later it is out of date and actively misleading. Delete or re-own.

---

## Part 6. Sprawl budget

Three dashboards per service:

1. **Primary.** Above-the-fold answers "is the SLO met."
2. **Drilldown.** Debug-focused; linked from the primary.
3. **Dependencies.** Health of the service's upstream and downstream dependencies, often shared across services in the same blast radius.

If a service grows a fourth dashboard, one of the existing three is pruned or merged. The limit is opinionated; teams that want more can justify the exception. The default enforces discipline.

### 6.1 Shared dashboards (not per-service)

- **Incident-command dashboard.** Top-level view: current SLO health for every journey, open incidents, recent deploys, alert-firing heatmap. One per org.
- **Platform dashboard.** Shared infrastructure: Kubernetes cluster health, network, DNS, IdP. One per infrastructure layer.
- **Executive dashboard.** Monthly business view: SLO attainment summary, cost summary, top incidents. One per org.

Shared dashboards do not count against the per-service budget.

---

## Part 7. The pruning pass

Part of the quarterly observe-ready review (shared with alert pruning).

For each dashboard:

- Last viewed in the last 30 days? No -> candidate for deletion.
- Bound to an active SLO or named diagnostic? No -> candidate for deletion.
- Owner still in the org? No -> re-own or delete.
- Last reviewed in the last 180 days? No -> candidate for review.

Delete rather than archive. Archived dashboards accumulate.

---

## Part 8. Dashboards and independence

The dashboard surface has its own independence question (Step 10):

- **Hosted in the same cluster as the app.** Dependent. Host in a managed vendor (Grafana Cloud, Datadog SaaS) or a separate cluster.
- **Needs SSO via the app's IdP.** Dependent. Separate IdP path or local auth fallback.
- **Depends on the same database the app uses.** (Some self-hosted Grafana deployments share the app's Postgres for their own config store.) Separate Postgres.

A primary dashboard that is unreachable during the incident it describes is the most cutting example of a blind dashboard.

---

## Part 9. Working examples

### 9.1 api service (request/response)

```yaml
name: api-primary
owner: api-team
purpose: "Is the login and signup journey meeting its SLOs."
last_reviewed: 2026-04-15
slo_bindings: [login-availability, signup-availability]
alerts_linked: [login-slo-fast, login-slo-medium, signup-slo-fast]
dependencies: [grafana-cloud, prometheus, tempo]

panels:
  - title: "Login error budget remaining"
    type: stat
    target: 99.9% / 30d
  - title: "Login burn rate (1h, 5m)"
    type: time_series
  - title: "Signup error budget remaining"
    type: stat
    target: 99.5% / 30d
  - title: "p99 latency per route"
    type: time_series
    routes: [/login, /signup, /logout]
  - title: "Error rate per route"
    type: time_series
  - title: "Upstream latency (auth provider, DB, cache)"
    type: time_series
  - title: "Active incidents + recent deploys"
    type: annotations_over_time

below_fold:
  - RED breakdown per route
  - Connection pool saturation
  - Per-region latency and error
  - Deploy history
```

### 9.2 worker service

```yaml
name: worker-primary
owner: orders-team
purpose: "Are order-fulfillment jobs completing within freshness SLO."
last_reviewed: 2026-04-10
slo_bindings: [order-fulfillment-freshness]
alerts_linked: [order-fulfillment-freshness-fast, order-fulfillment-freshness-medium]
dependencies: [grafana-cloud, prometheus]

panels:
  - title: "Freshness error budget remaining"
    type: stat
  - title: "Queue depth (primary, retry, dead-letter)"
    type: time_series
  - title: "Oldest unprocessed job age"
    type: time_series
  - title: "Processing throughput (dequeue rate)"
    type: time_series
  - title: "Processing failure rate"
    type: time_series
  - title: "Worker concurrency utilization"
    type: time_series

below_fold:
  - Per-job-type duration
  - Retry count per job_type
  - Deploy annotations
```

---

## Part 10. Checklist for Step 6 completion

- [ ] Every service has a primary dashboard with seven or fewer above-the-fold charts.
- [ ] The first chart is the error budget for the primary SLO; the second is the burn rate.
- [ ] Every chart above the fold binds to a named SLO, SLI, or declared diagnostic.
- [ ] Chart semantics: p99 for latency, rates as events/sec, error rate as ratio.
- [ ] Deploy annotations overlay the burn-rate chart.
- [ ] Every dashboard carries owner, purpose, last_reviewed, slo_bindings, alerts_linked, dependencies metadata.
- [ ] Per-service-type shape matches the catalog (request, worker, batch, edge, pipeline).
- [ ] Sprawl budget observed: no more than three dashboards per service (primary, drilldown, dependencies).
- [ ] No dashboard exists without an owner.
- [ ] Dashboards are hosted on infrastructure independent of the observed service (independence-test row).

When every box is checked, Step 6 is complete. Move to Step 7 (tracing).
