# Logging patterns

Loaded at Step 2 of the workflow. Tier 1 foundation. Covers structured event format, correlation IDs, level discipline, PII scrubbing at the OpenTelemetry Collector, sampling, and retention alignment.

**Canonical scope:** what a log line must carry, how it flows from the app to the backend, and what gets stripped along the way. **See also:** `tracing.md` for the trace_id contract; `error-tracking.md` for how errors are lifted off the log stream into a dedicated tracker; `vendor-landscape.md` for backend-specific retention and indexing quirks.

The one-line framing: a log line is a structured event, not a free-text breadcrumb. If your logs are strings with `printf` formatting you lose the ability to query them during the incident you wrote them for. If your logs are JSON with a `user.email` field you lose the ability to store them under GDPR.

---

## Part 1. The structured-log format

One format across every service in the app. Defined once, enforced by the logger.

### 1.1 Minimum required fields

Every log line carries, without exception:

| Field | Type | Purpose |
|---|---|---|
| `timestamp` | RFC 3339 UTC | When the event happened. Not when the log line was written. |
| `level` | enum | `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`. Nothing else. |
| `service` | string | The service that emitted the line. Matches the deploy topology entry. |
| `env` | enum | `dev`, `preview`, `staging`, `prod`. Matches `.deploy-ready/TOPOLOGY.md`. |
| `trace_id` | string | W3C Trace Context trace ID. Same ID the tracer uses. Empty only for events that genuinely have no trace context (a cron startup log, a boot line). |
| `span_id` | string | Current span ID if inside a span. Empty otherwise. |
| `event` | string | A low-cardinality event name. `user.signup.attempt`, `order.submitted`, `db.query.error`. Not a free-form message. |
| `message` | string | Human-readable detail for the event. Optional when `event` + structured fields carry everything. |

A log line missing `trace_id` on a request-handling path is a correlation bug. Fix the propagation (see `tracing.md`) before worrying about the log format.

### 1.2 Recommended additional fields

| Field | When to add |
|---|---|
| `user_id_hash` | For user-scoped events. Hashed, not raw. Enough to correlate sessions without storing PII. |
| `tenant_id` | For multi-tenant apps. A primary dimension for SLOs and debugging. |
| `release` | Deploy version from `.deploy-ready/STATE.md`. Enables "did this error start with v1.12.3." |
| `region` | Cloud region. For multi-region apps and for correlating with regional outages. |
| `duration_ms` | For events that bound a time interval (request handlers, DB calls, outbound API calls). |
| `http.status_code` | For request events. Not as a Datadog tag (high cardinality if used with dynamic paths); as a log field. |
| `error.class` | For error events. Exception class name. |
| `error.stack` | For error events. Full stack trace. |

### 1.3 Anti-patterns in the structured-log format

- **`msg` as a free-text carrier for everything.** "User signed up with email foo@example.com, redirecting to dashboard." Structured alternative: `event: user.signup.complete`, `user_id_hash: <hash>`, `next: /dashboard`. The first is unsearchable; the second answers "how many signups in the last hour" with a query.
- **`printf` format strings in the log.** The formatted string is what lands in the backend, which means you lose the ability to filter on the parameters.
- **Mixed JSON and unstructured output** to the same stream. Most log aggregators ingest either; both in one stream causes intermittent parse failures and silent data loss.
- **The logger emits multi-line stack traces as separate lines.** Each line becomes its own event; the stack is unindexable. Configure the logger to emit the full trace in a single `error.stack` field.
- **Reusing `level` to carry meaning other than severity.** "This log is at level `audit`." Use a separate field (`event_type: audit`) and keep `level` strictly about severity.

---

## Part 2. Level discipline

`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`. The operational meaning of each is fixed.

| Level | Meaning | Should it page? |
|---|---|---|
| `DEBUG` | Development-only verbosity; sampled or off in prod. | Never. |
| `INFO` | Normal operation. A user signed up. A job completed. | Never. |
| `WARN` | Something unusual, not yet user-visible. Retry succeeded; rate limit approaching. | Only if aggregated WARN rate crosses an SLO-relevant threshold. |
| `ERROR` | Something failed. User-visible, or will be. | Maybe, if aggregated ERROR rate crosses a burn-rate threshold. |
| `FATAL` | The process cannot continue. | Yes, though `FATAL` should also trigger a restart; the page catches the frequency, not the instance. |

The AI-generated anti-pattern: log every exception at `WARN`, every important event at `INFO`, and fall back to `printf` for `DEBUG`. This level inflation kills alert-design discipline because the levels carry no shared semantics.

### 2.1 The rate question

The level does not page. The *rate* of ERROR (or FATAL) lines over a window, compared to the SLO's error budget, is what pages. See `alert-patterns.md` for the math.

### 2.2 Prod and non-prod

`DEBUG` should be off (or heavily sampled) in prod, not just because of volume but because of cost. Datadog, New Relic, and Splunk all charge on ingested bytes or events; unfiltered `DEBUG` from a busy service is a line-item on the bill that produces no query-time value.

---

## Part 3. Correlation IDs and propagation

The `trace_id` field is the same identifier as the W3C Trace Context traceparent. One ID across the whole request, from the edge inbound to the deepest downstream call.

### 3.1 Generation

The edge (load balancer, API gateway, ingress) is the point of generation for external requests. Internal-to-internal calls inherit; they do not generate new IDs. See `tracing.md` section 2 for the exact propagation rules.

### 3.2 Propagation across transports

| Transport | Mechanism |
|---|---|
| HTTP inbound | `traceparent` header (W3C Trace Context). Logger reads it; if absent, generates a new ID. |
| HTTP outbound | The HTTP client injects the current `traceparent` automatically if the OTel HTTP instrumentation is active. |
| gRPC | `traceparent` metadata. Works for unary and streaming. For long-lived streams, see `tracing.md` section 3.2. |
| Async queues (RabbitMQ, SQS, Kafka, Redis) | The producer puts `traceparent` and optional `tracestate` into message metadata or headers; the consumer pulls it on dequeue. Default OTel instrumentations handle this for the big names. |
| Scheduled jobs (cron) | Generate a new `trace_id` per run. The run is its own root trace; there is no upstream context. |
| Serverless cold start | Lambda, Cloud Run: the platform may generate its own request ID. Map platform request ID to `trace_id` in middleware. |

### 3.3 The dropped-ID failure mode

If a log line in a downstream service has no `trace_id` (or a different one from upstream), the trace is broken at that hop. Common causes:

- The async library used to enqueue (e.g., an old Sidekiq or Bull) does not auto-instrument.
- A manual logging line inside a worker does not use the logger-with-context but the module-level logger.
- A third-party SDK swallows the context (some HTTP clients strip unknown headers).

Debug during the first observe-ready pass: pick one request, log the `trace_id` at each service boundary, and confirm it is the same ID everywhere. If not, fix before proceeding.

---

## Part 4. PII scrubbing at the OpenTelemetry Collector

Scrub at the collector, before data lands in the backend. Scrubbing in the application layer is easier to forget, easier to get wrong per-service, and harder to audit.

### 4.1 Declared PII fields

The default list to scrub (expand per compliance context):

- Personal identifiers: `user.email`, `user.phone`, `user.address`, `user.ssn`, `user.dob`, `user.name` (if full name), `passport`, `drivers_license`.
- Authentication material: `authorization`, `cookie`, `set-cookie`, `x-api-key`, `password`, `password_hash`, `token`, `access_token`, `refresh_token`, `id_token`.
- Payment material: `card_number`, `cvv`, `bank_account`, `routing_number`, `stripe_pm_id` (depending on context).
- Request bodies in logs unless specifically sanitized.
- Query parameters that can embed any of the above.

### 4.2 OTel Collector attribute processor

The pattern (abbreviated):

```yaml
processors:
  attributes/scrub:
    actions:
      - key: user.email
        action: delete
      - key: user.phone
        action: delete
      - key: authorization
        action: delete
      - key: cookie
        action: delete
      - key: password
        action: delete
      - key: http.request.header.authorization
        action: update
        value: "[REDACTED]"
      - key: user.name
        action: hash

  transform/scrub_body:
    log_statements:
      - context: log
        statements:
          - replace_pattern(body, "\"email\":\"[^\"]+\"", "\"email\":\"[REDACTED]\"")
          - replace_pattern(body, "[0-9]{13,19}", "[CARD?]")  # rough; tune
```

The exact syntax varies by collector version. Reference: OneUptime's ["Scrub PII from OTel pipelines"](https://oneuptime.com/blog/post/2026-02-06-scrub-pii-opentelemetry-logs-traces-metrics/view) and ["Keep PII out of observability"](https://oneuptime.com/blog/post/2025-11-13-keep-pii-out-of-observability-telemetry/view) are the practitioner guides.

### 4.3 Vendor-specific scrubbers

- **Datadog** has the [Sensitive Data Scanner](https://docs.datadoghq.com/security/sensitive_data_scanner/) with built-in PII patterns. Turn it on; do not rely only on the application.
- **Honeycomb** scrubs on ingest via the SDK or the refinery proxy.
- **Sentry** has [Data Scrubbing](https://docs.sentry.io/platforms/javascript/data-management/sensitive-data/) with default PII patterns; verify the config matches the app's schema.
- **Grafana Cloud / Loki** does not have a first-class PII scrubber; use Promtail's `pipeline_stages` or run telemetry through an OTel Collector before Loki.
- **Cribl Stream** is often dropped in as a dedicated PII-scrubbing tier because it is vendor-neutral.

### 4.4 Audit

Quarterly: sample 1000 random log lines from prod. Grep for `@`, `email`, a card-number pattern, an authorization-header shape. Zero hits on real PII is the pass gate. Hits mean the scrubber is miswired or a new field was added without scrubber coverage.

---

## Part 5. Sampling

Sampling applies to logs when volume exceeds usefulness. Rules of thumb:

- **Never sample ERROR or FATAL.** You lose the incident evidence.
- **Sample `INFO` on hot paths.** If the request logger emits `INFO` per request on a 10k req/s service, 10% sampling retains the shape while cutting 90% of volume.
- **Sample per trace_id, not per line.** If you sample per line, you lose coherent traces (some lines in the trace kept, others dropped).
- **Sample at the collector, not the application.** Then the sample rate is config, not code.
- **Declare the sample rate.** It is a field in the log line (`sample_rate: 0.1`), so the aggregator can reverse-scale the count for metrics derived from logs.

---

## Part 6. Retention

Retention alignment is a first-class observability decision, not a backend default.

### 6.1 The aligned windows

| Tier | Target window | Purpose |
|---|---|---|
| Hot | 7 to 30 days | Ad hoc query during incidents. |
| Warm | 30 to 90 days | Postmortem research; quarter-over-quarter trend. |
| Cold / archive | 1 to 7 years | Compliance; long-tail investigations. |

### 6.2 The SLO-alignment rule

Retention for any signal tied to an SLO must cover at least the SLO window. If the SLO is rolling 30 days and logs are kept 14 days, the SLO's computed error budget cannot be validated against source data. Same for traces and metrics.

### 6.3 The destructive-retention-change gate

Cutting retention is lossy and irreversible. Treat a retention reduction like deploy-ready treats a destructive-command: explicit confirmation, named window (what data will be lost), and a reason. Cost pressure is a valid reason; silent vendor-default tightening is not.

---

## Part 7. Log aggregation pipeline

One path: application logger -> local collector (OTel, Fluent Bit, Vector) -> ingestion backend.

### 7.1 Reasons to run a local collector

- Buffer during network blips; the app keeps running if the backend is unreachable.
- PII scrubbing at the edge.
- Sampling close to the source; cheaper than shipping then dropping.
- Multiple export paths: one to a hot-query backend (Loki, Elasticsearch), one to a cheap archive (S3).

### 7.2 OTel Collector gotchas

- `memory_limiter` must be configured or the collector OOMs under load spike.
- Processor order matters: scrubbers before exporters; sampling at the right stage.
- `batch` processors that run after tail samplers break trace grouping.
- Collector replicas behind a load balancer: tail-based trace sampling requires all spans of a trace route to the same replica. Use consistent hashing on `trace_id` or a dedicated trace-aware load balancer.

### 7.3 Application-layer instrumentation

Use the language's OpenTelemetry SDK and the logger integration for that SDK. The logger automatically attaches `trace_id`, `span_id`, and span attributes to emitted logs if the integration is active. Rolling your own is how you drop IDs.

---

## Part 8. Checklist for Step 2 completion

- [ ] One JSON structured format is declared and enforced across all services.
- [ ] Required fields (timestamp, level, service, env, trace_id, span_id, event) are present on every line.
- [ ] Level discipline: `ERROR` is for things the on-call may need to see; not inflated with every stack trace.
- [ ] Correlation IDs propagate across HTTP, gRPC, async queues, and scheduled jobs in the service graph.
- [ ] PII scrubber is configured at the OTel Collector (or equivalent). Sample audit returns zero hits.
- [ ] Sampling policy is declared for non-critical logs.
- [ ] Retention tier per backend is set and covers the SLO window.
- [ ] Local collector is in front of the ingestion backend; `memory_limiter` configured.

When every box is checked, Step 2 is complete. Move to Step 3.
