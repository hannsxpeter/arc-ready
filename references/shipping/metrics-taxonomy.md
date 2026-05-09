# Metrics taxonomy

Loaded at Step 1 (service inventory) and Step 3 (metric taxonomy). Tier 1 foundation plus SLO input.

**Canonical scope:** what to measure per service, how to categorize the measurement (SLI vs. method vs. diagnostic), and how to keep the cardinality bill from detonating. **See also:** `slo-design.md` for turning SLIs into SLOs; `dashboards.md` for how these metrics surface in the operator's first screen; `vendor-landscape.md` for backend-specific cardinality traps.

The one-line framing: a metric that is not bound to a question has no right to exist. RED for request services. USE for resources. Golden signals for user-facing journeys. Everything else is diagnostic and does not page.

---

## Part 1. The three methodologies

### 1.1 RED (Rate, Errors, Duration)

[Tom Wilkie's RED method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/), Weaveworks 2015. The canonical framing for request/response services.

- **Rate**: requests per second. Per endpoint or per service.
- **Errors**: failed requests per second (or error rate as a percent of Rate).
- **Duration**: distribution of request latencies (p50, p95, p99).

RED is derived from Google's four golden signals but drops "saturation" because at service level it is an infrastructure concern, not a request concern.

RED's strength: it is uniform across any request/response service. Every HTTP server, gRPC server, or RPC server fits. An operator can read the RED dashboard for any service without a tutorial.

### 1.2 USE (Utilization, Saturation, Errors)

[Brendan Gregg's USE method](https://www.brendangregg.com/usemethod.html), 2013. The canonical framing for resources.

- **Utilization**: fraction of time the resource is busy. CPU % busy, memory used/total.
- **Saturation**: degree to which the resource has work it cannot serve yet. Run queue length, swap usage, connection pool queue depth.
- **Errors**: errors the resource emits. Disk I/O errors, network retransmits, connection refused counts.

USE applies to CPU, memory, disk, network, connection pools, queue depth. It is a diagnostic framework; USE metrics do not page by default (they are causes, not symptoms), but they are the first place you look when a symptom-based alert fires.

### 1.3 Golden signals

Google's SRE book, chapter 6: latency, traffic, errors, saturation. Aimed at user-facing services.

- **Latency**: time to serve a successful request. Split success and failure (failure latency often lower because it is an early return).
- **Traffic**: demand on the service. Requests per second.
- **Errors**: explicit failures (4xx, 5xx, protocol errors) and implicit (successful response with wrong content).
- **Saturation**: how full the service is. The resource nearest a bottleneck.

Golden signals are the input to SLOs. An SLO picks one of these (usually latency or errors) and promises a target. The other signals become diagnostics for the SLO.

---

## Part 2. Per-service-type catalogs

Topology determines the metric set. Each catalog below is the minimum for the type; add more when a user journey requires it.

### 2.1 Request/response (HTTP, gRPC, RPC)

**SLI candidates:**
- `availability`: fraction of requests returning a success status.
- `latency_slo`: fraction of requests returning in under N ms.
- `error_rate`: fraction of requests returning 5xx.

**Method metrics:**
- `http_server_duration_seconds` (histogram, per route, per method, per status_class).
- `http_server_active_requests` (gauge).

**Diagnostics:**
- Connection pool utilization and saturation.
- Upstream latency per dependency.
- DB query latency and errors.

**Labels to use (low-cardinality):** `route_pattern`, `method`, `status_class` (2xx, 3xx, 4xx, 5xx), `env`, `region`.

**Labels to not use (high-cardinality):** `user_id`, `request_id`, `customer_email`, raw `path` (use `route_pattern` instead), `query_string`.

### 2.2 Worker (async queue consumer)

**SLI candidates:**
- `processing_success_rate`: fraction of jobs completing without error.
- `processing_latency_slo`: fraction of jobs completing in under N seconds.
- `freshness`: age of the oldest unprocessed job at any time.

**Method metrics:**
- `worker_job_duration_seconds` (histogram, per job_type).
- `worker_jobs_processed_total` (counter, per job_type, per status).
- `worker_queue_depth` (gauge, per queue).
- `worker_queue_oldest_age_seconds` (gauge, per queue).

**Diagnostics:**
- Retry rate per job_type.
- Dead-letter queue depth.
- Dequeue rate vs. enqueue rate (the lag signal).

**Deadman-switch metric:** `worker_last_processed_timestamp`. An alert on "timestamp has not moved in N seconds" catches a silently stalled worker. Checkly 2024 is the lesson.

### 2.3 Batch / scheduled job

**SLI candidates:**
- `success_rate`: fraction of runs completing without error.
- `runtime_slo`: fraction of runs completing in under N seconds.
- `schedule_adherence`: fraction of expected runs that actually ran.

**Method metrics:**
- `batch_job_duration_seconds` (histogram, per job_name).
- `batch_job_last_success_timestamp` (gauge).
- `batch_records_processed_total` (counter, per job_name).

**Deadman-switch metric:** `batch_job_last_success_timestamp` is the primary "did the job run" signal. Alert on absence past the expected schedule + grace window.

### 2.4 Edge worker (Cloudflare Workers, Vercel Edge Functions, AWS Lambda@Edge)

**SLI candidates:**
- `availability`: fraction of invocations returning non-error.
- `latency_slo`: fraction completing in under N ms.
- Distinct per-region if the edge runs in many regions.

**Method metrics:**
- Per-region request count and error count.
- CPU time per invocation (edge platforms often bill on CPU time).

**Diagnostics:**
- Cold-start rate and latency.
- Subrequest count per invocation.

### 2.5 Data pipeline (ETL, streaming)

**SLI candidates:**
- `freshness_slo`: fraction of windows where data landed within N minutes of source.
- `completeness_slo`: fraction of expected records actually processed.
- `correctness_slo` (harder): fraction of processed records passing a validation check.

**Method metrics:**
- `pipeline_lag_seconds` (gauge, per pipeline).
- `pipeline_records_in` / `pipeline_records_out` (counters).
- `pipeline_duplicate_rate` (if deduplication matters).
- `pipeline_last_watermark_timestamp` (gauge).

**Diagnostics:**
- Per-stage latency breakdown.
- Schema-validation failure count.

### 2.6 Database (primary or replica)

**SLI candidates (typically at the service that consumes the DB, not the DB itself):**
- Query latency at p99.
- Query error rate.
- Replication lag (for replicas).

**Method metrics (from the DB):**
- Connection pool utilization and saturation.
- Active queries, long-running queries (>1s) count.
- Replication lag in seconds.
- Transaction abort rate.
- Lock wait time.

**Diagnostics:**
- Table-level row counts (sampled).
- Index hit rate.
- Buffer cache hit rate (Postgres, MySQL specifics).

### 2.7 Cache (Redis, Memcached, in-process)

**Method metrics:**
- Hit rate per cache namespace.
- Eviction rate.
- Memory utilization.
- Connection pool saturation.

Cache is rarely an SLI directly; it usually appears as a diagnostic when latency SLO burns (cache miss surge is a common cause).

### 2.8 Message broker (Kafka, RabbitMQ, SQS)

**Method metrics:**
- Per-topic / per-queue producer rate.
- Per-topic / per-queue consumer lag.
- Broker-level CPU, memory, disk.
- Partition-to-consumer mapping.

Broker SLIs are often composition: "freshness" for the downstream consumer is the SLI; broker lag is the diagnostic.

---

## Part 3. Cardinality discipline

Cardinality is the number of distinct label combinations a metric has. High cardinality kills the bill on per-time-series priced backends (Datadog, Prometheus with long retention, New Relic metrics).

### 3.1 The dimensions that are always high-cardinality

- `user_id`, `account_id`, `customer_id`, `tenant_id` (on large systems)
- `request_id`, `trace_id`, `session_id`
- `order_id`, `transaction_id`, `invoice_id`
- Raw URL paths (every distinct `/users/<id>` is a new series).
- Full query strings or full request bodies.
- Timestamps as labels (never).

### 3.2 The dimensions that are OK to label on

- `env` (4 values: dev, preview, staging, prod)
- `region` (a handful)
- `service` (bounded; your service inventory)
- `endpoint` or `route_pattern` (bounded by the API surface)
- `method` (GET, POST, PUT, DELETE, PATCH, OPTIONS)
- `status_class` (2xx, 3xx, 4xx, 5xx, not the exact code unless needed)
- `tenant_tier` (bucketed, e.g., free, pro, enterprise)
- `job_type`, `job_name` (bounded)

### 3.3 The per-backend cardinality model

| Backend | Pricing / limit model | AI-config hazard |
|---|---|---|
| Datadog custom metrics | Per unique metric + tag combination. Each combination is a billable custom metric. [Datadog docs](https://docs.datadoghq.com/account_management/billing/custom_metrics/). | Tag on `customer_id` or `request_id`; the bill multiplies 100x. |
| New Relic metrics (CCU) | Per-series ingest plus query CCU. | Deep instrumentation enabled without awareness of per-custom-event cost. |
| Prometheus (self-hosted) | Memory-bounded by active series. Defaults hold about 10M active series on modest hardware. | A `path` label on every HTTP route detonates series count. |
| Grafana Cloud Mimir | Per 1,000 active series pricing. | Same as Prometheus but paid. Adaptive Metrics helps; configure it. |
| Honeycomb | Per-event pricing, not per-attribute. High-cardinality attributes are free. | Volume matters, not dimension count. The inverse of the Datadog trap. |
| Chronosphere | Transformation-rules driven, aggregation control. | Cardinality is a first-class control plane concern, not a hidden line item. |
| ClickHouse-based stacks (SigNoz, Uptrace, self-built) | Infrastructure cost; per-row effectively. | Cheap for high cardinality. |

### 3.4 High-cardinality data lives on wide events

`user_id`, `request_id`, `trace_id` belong on structured log events, spans, or wide-event backends (Honeycomb, ClickHouse). Not on time-series backends priced per-series.

observe-ready's rule: any metric configured with a high-cardinality label on a per-series-priced backend is rejected. The label goes on the trace or the log event; the metric stays low-cardinality.

### 3.5 The cardinality audit

Part of the Step 3 pass:

- List every custom metric name and the labels it carries.
- For each label, estimate the distinct value count at 30 days (growing).
- Product of label cardinalities = series count for that metric.
- Sum across metrics = total series budget.
- Compare to the backend limit or to the billing target.

AI-generated configs routinely ship metrics with 5-7 labels including one or two high-cardinality ones. The first-pass audit often finds the top 3 metrics account for 80% of the series.

---

## Part 4. The bound-to-promise test

Step 3's exit gate. For every metric the system exposes:

1. Is this metric an SLI for a named user journey? (Bound to an SLO.) -> Goes above the fold on the primary dashboard.
2. Is this metric a RED or USE set for a service? (Method metric.) -> Secondary dashboard; not above the fold.
3. Is this metric a named diagnostic explicitly needed during triage? (Examples: DB connection pool saturation when the DB SLO burns.) -> Below the fold or on a drilldown dashboard.
4. None of the above -> Remove it, or mark explicitly as "supporting; unbound; review in 90 days."

The fourth case is where dashboard sprawl originates. A metric someone instrumented once because it seemed useful, never reviewed, never consulted during an incident, and now on four dashboards. The skill's position: demote or delete.

---

## Part 5. Deadman switches

A "deadman switch" alert fires when a heartbeat metric stops updating. It is how you detect silent failure, where nothing is going wrong per se but nothing is going at all.

Services that need a deadman:
- Scheduled jobs: alert if `last_run_timestamp` is older than `expected_interval + grace`.
- Workers: alert if `worker_last_processed_timestamp` is older than N seconds when the queue is non-empty.
- Synthetic checks (Checkly, Pingdom): alert on the *absence* of a successful check result past the expected cadence. Checkly's own 2024 postmortem on this is the citation ([Checkly](https://www.checklyhq.com/blog/post-mortem-outage-browser-check-results-alerting)).
- Data pipelines: alert if the watermark does not advance.

The pattern in Prometheus:

```
absent_over_time(scheduled_job_last_run_timestamp[2h])
```

The pattern in Datadog: `no data` alert condition with an `evaluation_delay` tuned to the expected cadence.

Deadman switches are easy to forget to add because they do not surface anything when things are working. Part of the Tier 1 checklist.

---

## Part 6. Retention and rollup

Metrics retention is cheaper than logs or traces (time-series are compact), but still has alignment constraints.

- Raw resolution: 10s to 60s. Retain for at least the SLO window (rolling 30 days is typical).
- Rolled-up resolution: 1h or 1d. Retain for historical trend; 1-2 years is common.
- Datadog, Grafana Cloud, New Relic handle rollup automatically with configurable retention per tier.
- Prometheus default is 15 days; for SLO-relevant metrics, pair with Thanos, Cortex, or Mimir for long-term storage.

The SLO-alignment rule from `logging-patterns.md` applies: raw resolution must cover the SLO window.

---

## Part 7. Checklist for Step 3 completion

- [ ] Every user journey from Step 1 has a golden-signal set named (latency, traffic, errors, saturation).
- [ ] Every service has a RED or USE set appropriate to its topology.
- [ ] Per-service-type catalogs are applied: workers track queue depth + age; batch jobs track last-success timestamp; pipelines track lag.
- [ ] Deadman switches are in place for scheduled jobs, workers, synthetic checks, and data pipelines.
- [ ] Cardinality audit has been run. No metric carries a high-cardinality label on a per-series-priced backend without an explicit exclusion rule.
- [ ] Every metric passes the bound-to-promise test: SLI, method, named diagnostic, or removed.
- [ ] Retention per metric tier covers the SLO window.

When every box is checked, Step 3 is complete. Move to Step 4 (SLO design).
