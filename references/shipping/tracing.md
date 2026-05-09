# Distributed tracing

Loaded at Step 7 of the workflow. Tier 3 gate. OpenTelemetry as the instrumentation standard; tail (or error-biased) sampling for production; retention aligned to the SLO window.

**Canonical scope:** OTel adoption, W3C Trace Context propagation, context propagation traps (async queues, gRPC streams, serverless), sampling strategies (head, tail, adaptive), span hygiene, retention. **See also:** `logging-patterns.md` for the `trace_id` contract shared with logs; `metrics-taxonomy.md` for the span-to-metric pipeline; `vendor-landscape.md` for Tempo / Jaeger / Datadog APM / Honeycomb differences.

The one-line framing: a trace answers "where did time go on this request," which metrics and logs cannot. Traces are cheap when sampled correctly; expensive and useless when sampled wrong. Head-based 1% is a debugging tool for low-traffic apps; it is a production liability on anything with an SLO.

---

## Part 1. OpenTelemetry as the instrumentation layer

OpenTelemetry reached CNCF graduated status in late 2024 / early 2025 ([OpenTelemetry blog](https://opentelemetry.io/blog/2025/stability-proposal-announcement/); [CNCF project page](https://www.cncf.io/projects/opentelemetry/)). It is the vendor-neutral API, SDK, and Collector for telemetry data.

### 1.1 What is stable as of 2025-2026

- **Traces.** Stable across major languages (Go, Java, Python, Node.js, .NET, Ruby, PHP, Rust, C++).
- **Metrics.** Stable. Data model and API are fixed.
- **Profiles.** Data model stable in 2025 ([OpenTelemetry 2025 stability](https://opentelemetry.io/blog/2025/stability-proposal-announcement/)).

### 1.2 What is still in motion

- **Logs API.** Stabilization underway across SDKs.
- **Semantic conventions.** Many conventions (messaging, databases, RPC, AI/LLM) are still being stabilized. Instrumentation libraries relying on experimental conventions are pre-release.
- **Collector configuration DSL.** Rich, bespoke, and evolving; config written for collector v0.80 may need adjustment at v0.100.

### 1.3 Why OpenTelemetry specifically

Vendor neutrality. The same instrumentation code exports to Datadog, Honeycomb, Grafana Tempo, Jaeger, AWS X-Ray, or any OTLP-compatible backend via collector configuration. Switch vendors without re-instrumenting.

Backend lock-in is a real cost; the sibling skill stack-ready addresses vendor choice, but observe-ready's position on instrumentation is: OpenTelemetry, even if the backend is proprietary. An OTel SDK writing to a Datadog agent is fine; a Datadog-proprietary tracer is switching cost waiting to bite.

### 1.4 Auto-instrumentation vs. manual

Auto-instrumentation covers the standard transports (HTTP servers and clients, gRPC, major DB drivers, major queue clients). For most services, 80% of useful spans come from auto-instrumentation.

Manual instrumentation fills the gaps: custom business spans ("processed this order"), domain-specific attributes ("order value, tenant tier"), transaction boundaries that do not map to transport boundaries.

Start with auto-instrumentation; add manual spans where the auto-spans do not answer the operator's question.

---

## Part 2. W3C Trace Context propagation

Context propagation is how a trace stays connected across service boundaries. W3C Trace Context is the standard; every OTel SDK supports it natively.

### 2.1 The traceparent header

```
traceparent: 00-<trace_id>-<parent_span_id>-<trace_flags>
```

- `00` is the version byte.
- `trace_id` is 16 bytes (32 hex chars). Globally unique per trace.
- `parent_span_id` is 8 bytes (16 hex chars). The span that triggered this call.
- `trace_flags` is 1 byte. Currently only the sampled bit matters.

### 2.2 The tracestate header

```
tracestate: vendor1=key:value,vendor2=key:value
```

Vendor-specific context in a portable envelope. Datadog, Honeycomb, and others carry their own state in tracestate so cross-vendor traces (rare but real) can preserve vendor-specific detail.

### 2.3 Baggage

Baggage propagates business context alongside traces: `tenant_id`, `request_source`, `feature_flag_name`. Propagates automatically across OTel boundaries; useful for filtering spans by business attributes downstream. Do not put PII in baggage; it travels with the trace header, which can be logged in various places.

### 2.4 The edge is the generator

The first OTel-aware hop the request touches generates the trace_id and parent_span_id. From then on, every hop extracts, records as parent, and generates its own span_id while preserving the trace_id.

If the edge is a load balancer or CDN that does not emit OTel spans, the first app-layer hop generates. Ideally: the edge participates (Cloudflare Workers, Vercel, AWS API Gateway, Kong all have some OTel integration), and the trace starts at the user-visible surface.

---

## Part 3. Context propagation traps

These are where traces silently break.

### 3.1 Async queues

The producer puts `traceparent` into message metadata or headers; the consumer extracts on dequeue.

- **RabbitMQ**: message properties `headers` carries the traceparent. OTel auto-instrumentation for major RabbitMQ clients does this automatically.
- **Kafka**: Kafka message headers carry the traceparent. OTel Kafka instrumentation is stable.
- **SQS**: SQS message attributes carry the traceparent. OTel AWS SDK instrumentation covers it.
- **Redis streams / BullMQ / Sidekiq**: depends on the library. Older BullMQ and older Sidekiq do not auto-propagate; check the specific library version. Dapr's workflow guidance is explicit about propagation across queue boundaries ([OpenTelemetry on Dapr](https://opentelemetry.io/blog/2026/dapr-workflow-observability/)).

Audit: enqueue a message, dequeue it, and confirm the consumer's first span has the correct `trace_id`. If not, the library is not propagating; upgrade or add manual propagation.

### 3.2 Long-lived gRPC streams

HTTP and unary gRPC carry `traceparent` per request. A long-lived gRPC stream (server or bidirectional) opens once, and subsequent exchanges do not carry per-message headers by default. [Tracetest's guide](https://tracetest.io/blog/opentelemetry-trace-context-propagation-for-grpc-streams) documents the workaround: attach context to each message payload, or split the stream into logical requests with their own context boundaries.

For gRPC with streaming, design traces around message boundaries, not stream lifetimes. A stream-level span is wall-clock meaningful (it measures stream duration) but not useful for per-message SLI analysis.

### 3.3 Serverless cold starts and fan-out

- **Lambda invoked synchronously**: the caller's trace_id propagates via Lambda's OTel integration (either ADOT or manual).
- **Lambda invoked asynchronously via SNS/SQS**: use the queue's trace propagation as above.
- **Lambda-to-Lambda via `invoke`**: the caller must inject `traceparent` into the event payload; the callee extracts.
- **Step Functions**: each state machine execution is a trace; each state transition is a span. AWS's OTel integration for Step Functions is maturing.
- **Cloudflare Workers, Vercel Edge**: the platform-native OTel integration (or a standalone `fetch` wrapper) injects `traceparent` outbound and extracts inbound.

Cold starts create span outliers. Record cold-start status as a span attribute (`faas.cold_start = true`) so you can filter them from p99 latency charts if desired.

### 3.4 Background tasks and scheduled jobs

No inbound request, no upstream trace. Each scheduled run starts a new root trace. Downstream calls (DB, API, queue writes) become spans under that root.

### 3.5 The propagation audit

Step 7 should include a trace-correlation audit:

1. Generate one end-to-end request through every transport in the service graph.
2. Capture the trace_id at each hop's logs.
3. Confirm the trace_id is identical across every hop.
4. Confirm parent-child span relationships in the trace backend match the actual call graph.

Run this quarterly; run it after any major library upgrade.

---

## Part 4. Sampling

Sampling is where cost and utility meet.

### 4.1 Head-based sampling

Decide at span creation whether to keep or drop. Stateless, cheap, simple. Default in every OTel SDK out of the box.

The core problem: the decision happens before the error is known. Error traces that started in the dropped 99% are dropped even though they are the traces you need.

Head sampling is acceptable for:

- Low-traffic services where 100% sampling is cheap.
- Development and staging environments.
- Very high-volume services where tail sampling is operationally heavy and head sampling's data loss is an acceptable tradeoff.

Not acceptable for:

- Production services with SLOs. The observability cost of dropping error traces exceeds the storage cost of keeping them.

### 4.2 Tail-based sampling

Decide after the span (or the whole trace) is complete. Stateful: the collector must buffer spans for in-flight traces until the sampling window closes.

The math: "For a system with 5,000 new traces per second, a 30-second wait, 8 spans per trace, and 2 KB per span, that works out to roughly 2.4 GB just for the span buffer" ([dev.to on scaling collectors](https://dev.to/taman9333/traces-at-scale-head-or-tail-sampling-strategies-scaling-the-collector-nk); [OneUptime](https://oneuptime.com/blog/post/2026-02-06-head-based-vs-tail-based-sampling-opentelemetry/view)).

Tail-sampling rules you want:

- Keep traces with any error status.
- Keep traces with latency above p95.
- Keep a small fraction of healthy traces for baseline comparison (5-10%).
- Keep traces from specific business segments (enterprise tenants, compliance-relevant journeys).

### 4.3 The tail-sampling routing constraint

All spans of a single trace must route to the same tail-sampling collector instance. Options:

- Consistent-hash load-balancer on `trace_id`.
- Single collector instance (fine up to some throughput).
- Trace-aware load balancer (Grafana's trace-balancer, some mesh-native solutions).

AI-generated OTel Collector configs with a `loadbalancing` exporter in front of tail samplers are the canonical way to scale this.

### 4.4 Adaptive sampling

When the tail sampler is overloaded, fall back to a less expensive strategy (head or probabilistic) temporarily. Prevents data loss during spikes at the cost of sample-quality variance. Grafana Adaptive Metrics is a similar idea applied to metrics.

### 4.5 The skill's default

- Dev / staging: head sampling at 100%.
- Production with SLO: tail sampling. Keep errors, keep p95+ latency, keep 5-10% of healthy traces as baseline.
- Very high volume: tail with aggressive healthy-trace dropping, paired with exemplar sampling for each RED metric.

Head-only sampling in production with an SLO is rejected by Step 7.

---

## Part 5. Retention alignment

The SLO window is the floor for trace retention on SLO-relevant traces.

### 5.1 The alignment

- SLO 30-day rolling -> SLO-relevant traces kept 30 days minimum.
- Baseline traces (sampled healthy) kept shorter; they are for trend comparison, not incident replay.
- Exception: if the error-budget policy requires reviewing specific incidents 90 days later (compliance, legal), retention extends to match.

### 5.2 Tiered retention

Most trace backends support tiered retention: hot (queryable, fast), warm (queryable, slower, cheaper), cold (archival).

- Hot: 7 days. Active incident investigation.
- Warm: 30 days. Recent-history query. Covers the SLO window.
- Cold: 90 days or longer. Postmortem research, compliance.

Configure the tiers; accept the cost; verify during the quarterly pass.

### 5.3 The retention-vs-SLO mismatch

If SLO is 30 days and Tempo retention is 15 days, the postmortem cannot query the 20-day-ago trace. Step 7 flags the mismatch; Step 4 caps the SLO window at the retention floor or extends retention to match.

---

## Part 6. Span hygiene

A clean span is a low-cardinality name plus a handful of meaningful attributes.

### 6.1 Span names

- Span name is the route pattern, not the URL. `GET /users/:id` not `GET /users/12345`.
- Span name is the operation, not the specific instance. `db.query.select_user_by_id` not `SELECT * FROM users WHERE id = 12345`.
- Low-cardinality. If the span name has any per-request variable in it, something is wrong.

### 6.2 Span attributes

- Use semantic conventions where they exist. `http.method`, `http.route`, `http.status_code`, `db.system`, `db.operation` are defined; use them.
- Add business attributes relevant to SLIs: `tenant_id`, `user_segment`, `journey_name`.
- Do not put PII in attributes. Scrub at the collector.
- Do not put whole request or response bodies in attributes. Too large; too often PII.

### 6.3 Span events

Events are timestamped notes on a span. Use them for:

- Recording exceptions (OTel has a convention: `exception.type`, `exception.message`, `exception.stacktrace`).
- Significant state changes mid-span ("cache hit recorded at T+5ms, DB miss at T+20ms, upstream call at T+35ms").

Events are not a replacement for child spans. A database call is a child span, not an event on the parent.

### 6.4 Span duration sanity

A span lasting hours is almost certainly a bug: the span never ended, or the library's close-on-exception handling is missing. Periodically audit p99 durations; >60-second spans on a request service are suspect.

---

## Part 7. The trace-to-metric pipeline

Traces inform metrics via span metrics: the collector derives request rate, error rate, and duration histogram from spans. This is cheaper than instrumenting metrics separately and keeps the two in sync.

Grafana's trace-metrics generator, Datadog's APM Trace Metrics, and Honeycomb's metric-from-event derivations all do this. Configure it; it is the canonical path from "we have spans" to "we have SLIs."

### 7.1 The cardinality constraint returns

Span metrics inherit span attributes as labels. Same cardinality discipline as `metrics-taxonomy.md` section 3: low-cardinality labels on the metric (route pattern, method, status class); high-cardinality attributes stay on the trace itself.

---

## Part 8. Vendor differences

| Vendor | Trace backend | Sampling | Retention |
|---|---|---|---|
| Grafana Cloud Tempo | Columnar; object-storage-backed. | Head or tail via OTel collector upstream. | Default 30 days; configurable. |
| Datadog APM | Proprietary; query UI. | Head or tail via Datadog Agent. | Default 15 days on Pro, 30 days on Enterprise. |
| Honeycomb | Structured events, not trace-specific. | Determined by sampling SDK and refinery. | 60 days default on Pro. |
| Jaeger | Self-hosted; ElasticSearch or Cassandra backend. | Head only in-process; tail via OTel collector. | Self-managed; whatever you configure. |
| AWS X-Ray | AWS-native; integrated with Lambda and ECS. | Head via SDK; reservoir + fixed rate. | 30 days. |
| New Relic APM | Proprietary agent; OTel ingest available. | Head; New Relic determines retention tiers. | Varies by plan. |

Configuration deltas in `vendor-landscape.md`.

---

## Part 9. Checklist for Step 7 completion

- [ ] OpenTelemetry SDKs are installed on every service.
- [ ] Context propagation is verified across every transport in the dependency graph: HTTP, gRPC (including streams), async queues, serverless invocations, scheduled jobs.
- [ ] The correlation audit (generate a request, trace it through every hop) passes.
- [ ] Sampling strategy is appropriate: head-only is allowed only for dev/staging or explicit low-volume justification; production with SLO uses tail or error-biased sampling.
- [ ] Trace retention covers the SLO window (hot or warm tier).
- [ ] Span hygiene: low-cardinality names, semantic-conventions attributes, no PII.
- [ ] Span-to-metric pipeline is configured where the backend supports it.
- [ ] Trace backend is reachable during the observed-service outage (independence test).

When every box is checked, Step 7 is complete. Move to Step 8 (error tracking).
