# Vendor landscape

Loaded on demand. The configuration deltas and hidden pricing traps across the major observability backends, plus the independence considerations that apply to each.

**Canonical scope:** Datadog, Grafana Cloud, Honeycomb, New Relic, Splunk Observability, Dynatrace, open-source OTel stacks (Prometheus, Tempo, Jaeger, Loki, Mimir), Sentry / Rollbar / Bugsnag, PagerDuty, incident.io, FireHydrant, Rootly, Blameless, Better Stack, Checkly, Cribl, Chronosphere. **See also:** `slo-design.md` for the SLO-vendor feature matrix; `tracing.md` for per-vendor sampling; `alert-patterns.md` for alert-router differences.

Vendor choice is not this skill's territory (stack-ready owns that). This file opinions on what a chosen vendor must actually do and where the usual configurations go wrong.

---

## Part 1. Datadog

### 1.1 Strengths

- Broadest product depth in one UI: metrics, logs, APM, RUM, synthetics, SLOs, notebooks, LLM observability, CI visibility.
- Terraform provider with first-class `datadog_monitor`, `datadog_dashboard`, `datadog_service_level_objective` resources ([Datadog Terraform docs](https://docs.datadoghq.com/getting_started/integrations/terraform/)).
- SLO and burn-rate monitors are first-class.

### 1.2 Cardinality trap

Custom metrics are priced per unique metric + tag combination. Each combination is a billable custom metric ([Datadog docs](https://docs.datadoghq.com/account_management/billing/custom_metrics/)).

- `customer_id` as a tag: bill detonator.
- `request_id` as a tag: bill detonator.
- `route` as a tag with dynamic path segments: 100x multiplier.

[Sawmills](https://www.sawmills.ai/blog/best-practices-for-high-cardinality-metrics-in-datadog) and [SigNoz](https://signoz.io/blog/datadog-pricing/) both catalog the pattern. Datadog's "Metrics Without Limits" feature lets you exclude tags at query or billing time; configure it, do not rely on defaults.

### 1.3 SLO-vs-error-budget-policy gap

Datadog SLOs are first-class. Error-budget policies (the "what happens when the budget burns" rule) are not codified in Datadog; the policy is out-of-band in a wiki or Notion. observe-ready's pattern: keep the policy in `.observe-ready/policies/` alongside the SLO entry.

### 1.4 Configuration notes

- Dashboards have a description field; put the `owner`, `last_reviewed`, `purpose`, `slo_bindings` metadata there.
- Use `@team` notation in monitor configs to route to the team's PagerDuty; avoids routing through Slack only.
- The `evaluation_delay` on `no data` alerts catches deadman-switch cases.
- `datadog_service_level_objective` Terraform resource generates the burn-rate monitor; configure the multi-window multi-burn-rate pattern there.

### 1.5 Retention

- Metrics: 15 months on Infrastructure; 15 months on APM metrics; variable on custom metrics. Confirm the tier.
- Logs: 15 days default hot; up to 15 months on Flex Logs (cold tier; slower query).
- Traces: 15 days default on Pro; 30 days on Enterprise.
- Verify every SLO-relevant signal has retention covering the SLO window.

### 1.6 Independence

Datadog is SaaS; default SaaS independence applies. Single-region dependencies: if the SaaS region Datadog uses (us1, us3, us5, eu1, ap1) degrades, the observability surface degrades with it. For critical workloads: pair with a secondary check (Better Stack uptime, Pingdom, or an internal heartbeat) to detect Datadog's own blind spots.

Datadog 2023 (multi-region connectivity issue) is the cautionary case: the observability platform could not observe itself for ~27 hours ([Datadog blog](https://www.datadoghq.com/blog/2023-03-08-multiregion-infrastructure-connectivity-issue/)).

---

## Part 2. Grafana Cloud and the LGTM stack

### 2.1 Strengths

- Open-source-anchored: Grafana (dashboards), Loki (logs), Tempo (traces), Mimir (metrics), Pyroscope (profiles). Portable.
- Generous free tier; sliding-scale pricing as you grow.
- Adaptive Metrics auto-aggregates unused time series ([Grafana Cloud](https://grafana.com/products/cloud/)).

### 2.2 Cardinality notes

- Mimir prices by active series per 1,000.
- Loki penalizes high-cardinality labels hard; use [label best practices](https://grafana.com/docs/loki/latest/fundamentals/labels/).
- Tempo is cost-friendly for tail sampling; the OTel Collector in front handles the sampling.

### 2.3 SLO support

Grafana's [Sloth](https://sloth.dev/) project compiles SLO specs into multi-burn-rate Prometheus rules. Grafana Cloud's SLO UI wraps this. Use Sloth (or the UI) to avoid hand-authoring the PromQL.

### 2.4 Retention mismatch risk

Tempo (traces) and Mimir (metrics) have independent retention. A trace that existed in Tempo on day 10 may be missing on day 16 if Tempo retention is 14 days; the metric with which it correlates is still in Mimir.

Align retention: pick the SLO window, confirm Tempo covers it, confirm Mimir covers it, confirm Loki covers it.

### 2.5 Independence

Grafana Cloud is SaaS. The same considerations as Datadog apply. Self-hosted Grafana inherits the independence question: host it on the app's cluster and it goes down with the app.

---

## Part 3. Honeycomb

### 3.1 Strengths

- Wide structured events as the primary abstraction. Traces, metrics, and logs are all views of the same event stream.
- High cardinality is free; pricing is by event count, not attribute count ([Honeycomb on high cardinality](https://docs.honeycomb.io/get-started/basics/observability/concepts/high-cardinality)).
- BubbleUp: compare a subset of events (errors) to a baseline and surface which attributes differ.
- SLO and burn-rate support first-class.

### 3.2 Notes

- Pricing is volume-of-events-linear. If you instrument deeply without sampling, the bill tracks event volume.
- Refinery (Honeycomb's sampling proxy) handles tail sampling.
- No built-in logs or traces store decoupled from the wide-event model. If your app is not already emitting wide events, adapter work is required.

### 3.3 Error-budget policy gap

Same as Datadog: SLOs first-class, error-budget policies are out-of-band. Keep the policy in `.observe-ready/policies/`.

### 3.4 Independence

SaaS with dedicated EU and US regions. Independent of most other SaaS outages.

---

## Part 4. New Relic

### 4.1 Strengths

- Full-fidelity APM with long ecosystem history.
- OpenTelemetry ingest is supported; the agent is mature.

### 4.2 Pricing trap

CCU (Compute Consumption Unit) model is opaque. SigNoz's breakdown ([SigNoz on CCU](https://signoz.io/blog/new-relic-ccu-pricing-unpredictable-costs/)) and Middleware's writeup ([Middleware](https://middleware.io/blog/new-relic-pricing/)) both catalog "bill shock" cases where enabling a feature (JVM-level telemetry, custom events) produced 10x bill spikes for a month.

AI-generated New Relic configs routinely enable instrumentation without understanding the billing implication. Audit before activating any deep integration.

### 4.3 SLO support

SLOs available; error-budget policies out-of-band as with others.

### 4.4 Independence

SaaS with regional endpoints; independent of most cloud providers.

---

## Part 5. Splunk Observability (formerly SignalFx and AppDynamics)

### 5.1 Strengths

- Enterprise-proven. SignalFx heritage on fast metrics streaming.
- Strong real-time capability for high-volume metrics.

### 5.2 Notes

- Proprietary agent creates migration friction.
- Splunk acquired SignalFx and AppDynamics separately; enterprises can find two Splunk-branded observability stacks that do not share ontology.
- Pricing is enterprise-grade opacity; work with an account rep.

---

## Part 6. Dynatrace

### 6.1 Strengths

- OneAgent: the most automated instrumentation on the market. Drop it on the host, it discovers everything.
- AI-driven anomaly detection (Davis) is mature.

### 6.2 Notes

- Proprietary agent; migration cost.
- "AI-driven" correlation produces correlated anomalies during correlated failures; human judgment still needed to determine causality.
- Pricing is enterprise-grade; SMB-unfriendly.

---

## Part 7. Open-source OpenTelemetry stack (Prometheus, Tempo, Loki, Jaeger, Grafana, AlertManager)

### 7.1 Strengths

- Free at the license level. CNCF-backed.
- OpenTelemetry graduated 2024-2025. Mature.
- Portable across backends (swap Tempo for Jaeger, swap Mimir for Thanos).

### 7.2 Operational cost

Running the stack is a real workload:

- **Long-term metrics storage.** Prometheus default is 15 days. Thanos, Cortex, Mimir add clustering and deduplication at the cost of operational complexity.
- **Alerting.** AlertManager handles routing; configuration is YAML; requires a team that reads it.
- **Dashboards.** Grafana self-hosted; a separate deployment from the app.
- **Traces.** Tempo or Jaeger; object storage or database backend.
- **Logs.** Loki is cheaper than ElasticSearch; still needs storage and indexing management.

### 7.3 OTel Collector configuration pitfalls

The OTel Collector config DSL is rich and bespoke. Common AI-generated mistakes:

- `memory_limiter` missing -> the collector OOMs under load.
- `batch` processor after `tail_sampling` -> breaks trace grouping.
- Tail-sampling collectors behind a round-robin load balancer -> spans of one trace scatter across replicas; tail sampling cannot assemble.
- Semantic-conventions processors using unstable convention versions.

Verify config against the collector version; re-verify on version bumps.

### 7.4 Independence

Self-hosted: independence is whatever you make it. Hosting Grafana on the same cluster as the app is the default failure mode; move to a dedicated cluster or managed service.

---

## Part 8. Sentry, Rollbar, Bugsnag

See `error-tracking.md` sections 3 and 8 for the functional comparison. Quick notes:

- **Sentry**: strongest performance monitoring sidecar (Performance / Tracing product). Default grouping over-splits on framework stack-trace noise; tune fingerprints.
- **Rollbar**: aggressive grouping; can merge distinct errors. Strong deploy integration.
- **Bugsnag**: strongest on mobile (Android ANR, iOS crash). BitSight / SmartBear owned.
- **Honeycomb**: errors as a query, not as a separate product. Good for teams already on Honeycomb.

Independence: all are SaaS; the network path to upload is the dependency.

---

## Part 9. PagerDuty, incident.io, FireHydrant, Rootly, Blameless

All are alert-routing and incident-coordination layers; signal quality is upstream.

### 9.1 PagerDuty

Incumbent. Largest integration ecosystem. Event Intelligence filters noise (markets 98% reduction; implies the baseline is 2% signal). Event Orchestrations for complex routing. On-call Schedules native.

### 9.2 incident.io

Slack-native; incident-management-first. Strong on post-mortem capture and timeline. Growing alert-routing features.

### 9.3 FireHydrant

Similar to incident.io; runbooks and comms are first-class.

### 9.4 Rootly

Similar space; ChatOps-native workflow.

### 9.5 Blameless

Post-mortem and learning-focused; the name reflects the cultural frame.

### 9.6 Independence

All are SaaS. PagerDuty is multi-region; the others vary. Check the vendor's own status page as part of the Step 10 independence test.

---

## Part 10. Better Stack, Checkly, Pingdom

Synthetic and uptime monitoring.

### 10.1 Better Stack

Status page + uptime monitoring + incident coordination. Generous free tier.

### 10.2 Checkly

Browser-based synthetic checks. API and browser monitoring. Their own 2024 postmortem on missing deadman-switch alerting for check absence is the industry-canonical "alert on silence" lesson ([Checkly](https://www.checklyhq.com/blog/post-mortem-outage-browser-check-results-alerting)).

### 10.3 Pingdom

SolarWinds-owned. Long-established. Legacy shape.

### 10.4 Black-box vs. in-app

Synthetic monitoring observes the public surface. A correct status page with broken internal jobs is invisible to synthetic-only setups. Pair with in-app observability.

---

## Part 11. Cribl and Chronosphere

Both address the observability cost crisis.

### 11.1 Cribl Stream

Vendor-agnostic telemetry pipeline. Filters, enriches, routes telemetry before it lands in expensive backends. Markets 30-50% volume reductions as routine ([Cribl](https://cribl.io/solutions/initiatives/cost-control/)). Useful when running multiple backends (a Splunk and a Datadog, or a Datadog and an OTel stack).

### 11.2 Chronosphere

Kubernetes-native observability platform with explicit cost control. Transformation rules, aggregation, and tenant-shaped multi-tenancy. Frames the cost problem directly: "enterprise log data growth exceeding 250% year over year, with ~70% of observability spend going toward storing logs never queried" ([Chronosphere 2025 trends](https://chronosphere.io/learn/2025-top-observability-trends/); [SiliconANGLE](https://siliconangle.com/2026/02/05/observability-cost-ai-scale-chronosphere-opensourcesummit/)).

### 11.3 Where they fit

Cribl as a pipeline tier between producers and backends; Chronosphere as a backend with cost control baked in. Either or both are appropriate if Mode E (cost-driven) is active.

---

## Part 12. ClickHouse-based stacks (SigNoz, Uptrace, self-built)

ClickHouse as a columnar store is cheap for large datasets. SigNoz and Uptrace package it; many orgs build their own.

### 12.1 Tradeoff

- Lower infrastructure cost at scale.
- Higher operational cost: the team runs the database, handles clustering, tunes queries.
- Query flexibility: SQL-over-observability-data is powerful; the learning curve is real.

### 12.2 When to consider

Mode E (cost-driven) teams with infrastructure expertise. Not recommended as a first observability stack; the operational burden is front-loaded.

---

## Part 13. Lightstep, Groundcover

- **Lightstep**: acquired by ServiceNow in 2021; now ServiceNow Cloud Observability. Integrated with ServiceNow enterprise workflow ([ServiceNow announcement](https://www.servicenow.com/blogs/2021/acquires-it-observability-leader-lightstep)).
- **Groundcover**: eBPF-first. Pitched as "observability without sending data to the vendor;" traffic stays in your cluster. Useful for data-sovereignty or high-sensitivity workloads.

---

## Part 14. Independence matrix

Revisiting Step 10's six-row test with vendor awareness.

| Artifact | SaaS vendor | Self-hosted | Notes |
|---|---|---|---|
| Dashboards | Grafana Cloud, Datadog, Honeycomb | Grafana self-hosted | Self-hosted on the same cluster is dependent. |
| Alert routing | PagerDuty, incident.io | AlertManager self-hosted | Self-hosted shares the fate of the cluster. |
| Runbooks | Confluence, Notion, static site | git repo, wiki | SSO dependency matters more than host. |
| Status page | Statuspage.io, Instatus, Better Stack | Self-hosted | Self-hosted on the same region is dependent. |
| Trace store | Grafana Tempo, Datadog, Honeycomb | Jaeger, self-hosted Tempo | Self-hosted is dependent; SaaS is independent. |
| On-call schedule | PagerDuty, incident.io | Shared calendar | Shared calendar on the app's IdP is dependent. |

The SaaS default is independence unless the SaaS vendor is itself regionally dependent on the same cloud region as the app (look at the Datadog 2023 pattern for a reminder that SaaS is not a magic independence wand).

---

## Part 15. Portability posture

OpenTelemetry is the portability anchor. SDK-level OTel instrumentation plus collector-level routing means the same app-side code can emit to:

- Datadog Agent (via OTLP).
- Grafana Cloud (via OTLP).
- Honeycomb (via OTLP).
- AWS X-Ray.
- Jaeger or Tempo self-hosted.
- Any combination, in parallel.

Vendor-proprietary agents lock you in. Avoid them for new work. OTel SDK + collector is the vendor-neutral path.

---

## Part 16. Vendor-decision-adjacent observe-ready rules

- **Cardinality rule survives vendor choice.** High-cardinality tags on per-series pricing is always wrong; switch to wide-event backend or exclude the dimension.
- **Retention rule survives vendor choice.** SLO window dictates retention floor; align regardless of backend.
- **Error-budget-policy rule survives vendor choice.** No vendor codifies the policy; keep it in `.observe-ready/policies/`.
- **Runbook discipline survives vendor choice.** PagerDuty and incident.io both hold runbook URLs in alert payloads; both require the URL to be specific and independent.

observe-ready opinions on the rules; the vendor implements them. If the vendor cannot implement a rule, name the gap.

---

## Part 17. Choosing for the first time

If no vendor is chosen (stack-ready has not run, or the team is ambivalent):

- **Small team, no budget**: OpenTelemetry + Grafana Cloud free tier. Swap to self-hosted later if cost pressure appears.
- **Small team, some budget**: Honeycomb (for wide-event clarity) or Grafana Cloud (for the full stack).
- **Mid-sized team, ops maturity**: Datadog or Grafana Cloud as the backend; OpenTelemetry as the instrumentation.
- **Enterprise, compliance**: Chronosphere or Grafana Enterprise self-hosted; consider dedicated SIEM for security overlap.
- **Cost crisis**: Cribl Stream as pipeline; Chronosphere as backend; drop legacy vendor weight.

The specific choice is stack-ready's territory; this is the orientation.

---

## Part 18. The vendor-audit question

Every quarter: is the vendor still the right choice?

- Cost trending as expected?
- Feature gaps that the team is working around?
- Consolidation (one vendor covering three previously separate purchases) or unbundling (dedicated best-of-breed) matching where the team is?
- Outages from the vendor that affected us?
- Has the vendor's pricing changed in a way that invalidates the original decision?

Write the audit in `.observe-ready/vendor-audit-YYYY-QN.md`. It informs the next `stack-ready` pass.
