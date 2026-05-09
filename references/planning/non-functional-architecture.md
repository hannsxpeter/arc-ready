# Non-Functional Architecture

The Step 6 protocol. Latency, throughput, availability, scale horizons, consistency, compliance posture, observability shape, operational posture, and the math check that refuses "scalable" as a claim. Where the PRD's numeric targets become shape decisions with numbers.

**Scope owned by this file:** the translation from PRD NFRs to architectural commitments. Not the instrumentation (observe-ready), not the deployment (deploy-ready), not the tool picks (stack-ready). The spec, with numbers.

## Section 1. The translation job

The PRD states NFRs as targets. A well-written PRD (per prd-ready) gives targets like "p95 under 300ms on the order-placement flow at 1,000 concurrent users" and "99.9% monthly availability on the customer-facing API." A badly written PRD gives "scalable," "performant," "reliable," "fast" with no numbers, and architecture-ready's first job is to refuse those and get numbers.

**"Scalable" is not a translation.** It is a wish. It tells the engineer nothing about how many users, what kind of operations, what latency, what consistency. Every "scalable" claim gets replaced with "supports 10,000 concurrent users executing 50 requests per second each, with p95 under 300ms on read paths and p95 under 800ms on the checkout write path." That is a translation; that is an architectural constraint; that drives decisions.

The ThoughtWorks Tech Radar has held a consistent position since 2018: NFRs stated as adjectives are not NFRs. The SRE discipline (Google's "Site Reliability Engineering" book, O'Reilly 2016; chapter 4 on service level objectives) codified the same rule: an SLO is a numeric threshold over a measurable signal over a window. "High availability" is not an SLO; "99.9% availability measured monthly over the /api/orders endpoint's 2xx-response rate" is. architecture-ready inherits this discipline: every NFR dimension gets a number or gets flagged as an open question with an owner and a due date. No adjective survives Step 6.

**The refusal rule.** If the PRD says "the system must be scalable" and Step 6 writes "the architecture is scalable," both are horoscope-shaped and neither decides anything. The translation is: read the PRD, extract the concrete number (or go back and ask the PM for it), and write the architectural commitment that the number drives. If the PM cannot produce a number, the number goes on the open-questions log with an owner. Not having a number is a decision to flag, not a decision to hide.

**The second-order translation.** The PRD number is a user-visible target (p95 latency, monthly availability). The architectural commitment is component-level (per-component latency budget, per-component availability, per-component capacity). The chain math (Sections 2, 3, 4) is how the user-visible target decomposes into component-level constraints. If the chain does not close (the user-visible p95 is 300ms but the sum of component budgets is 450ms), the architecture is paper-tiger (RESEARCH-2026-04.md section 2.2) and must change: either the shape adjusts (remove a hop, cache, parallelize, precompute) or the target adjusts (negotiate with the PM for 500ms). Do not ship an infeasible chain.

## Section 2. The latency chain

The user-visible latency target is the sum of per-hop latencies on the request path, plus variance slack. Name the hops, budget each, check the math.

### The request path

A typical user request on a B2B SaaS flow:

1. **Network edge.** DNS resolution, TCP handshake, TLS handshake, CDN / edge router hop. Typical: 30-80ms for a cold client, 5-15ms warm.
2. **TLS handshake.** Already included in network edge for the first request; for keep-alive connections, effectively zero. First-request TLS: 50-100ms. Warm connection reuse cuts it to zero.
3. **Auth check.** Middleware validates the session token, JWT, or API key. Typical: 1-5ms with a local cache; 20-50ms if the check roundtrips to an identity service.
4. **Middleware.** Rate limiting, CSRF, request logging, tracing context propagation. Typical: 2-10ms.
5. **DB queries.** Application queries its data stores. Typical: 5-50ms per query, depending on index quality and data shape. Multiple queries in a handler add linearly unless parallelized.
6. **Business logic.** The code that does the actual work (compute prices, apply business rules, format responses). Typical: 5-30ms; occasionally much more for complex computations.
7. **External calls.** Calls to partner APIs or internal services. Typical: 50-300ms per call, depending on partner and network. Variance is high.
8. **Response serialization.** JSON (or protobuf) encoding, gzip compression. Typical: 1-10ms for small payloads; scales with payload size.
9. **Return network.** Response bytes traverse the edge back to the client. Similar to inbound, typically 10-30ms for keep-alive connections.

### A worked budget example

**PRD target:** p95 under 300ms for the order-placement request at the API layer (excluding end-user network).

**Budget math:**

- TLS handshake: 50ms (first request; amortized lower on keep-alive).
- Auth check (cached session): 5ms.
- Middleware: 5ms.
- DB queries (parallel read of user + inventory + pricing, plus write of order + line items): 30ms.
- Business logic (validate, compute total, apply discounts, check inventory invariants): 10ms.
- External call to payment gateway: 100ms (p95; p99 is higher).
- Response serialization: 10ms.
- Sub-total: 210ms.
- **Headroom: 90ms for variance, GC pauses, warm-up, and fan-out jitter.**

This budget fits 300ms p95 with headroom. It assumes warm TLS; a cold TLS adds 50ms. It assumes the payment gateway does not degrade; when it does, the budget breaks. The architecture must name "payment gateway p95 at 100ms" as an assumption and set a circuit breaker with a graceful-degradation path (integration-architecture.md Section 4) for when the assumption fails.

### Where the budget breaks

Budgets break in predictable ways:

- **The external call is the variance source.** A partner API's p99 is often 3-10x its p95. If the architecture p95 budget allots 100ms for a partner call but the partner's p99 is 500ms, the architecture's p99 is blown even if the p95 holds.
- **Fan-out multiplies latency.** Calling N partners in parallel and waiting for all of them gives the latency of the slowest, not the average. At high fan-out (10+), the tail dominates.
- **DB queries under load.** A query that is 5ms at idle may be 50ms under load because of contention, lock waits, or buffer cache eviction. Benchmark under realistic load.
- **GC pauses on managed runtimes.** JVM, Node, .NET, Go: occasional GC pauses of 10-100ms are normal. Budget for them in the headroom.
- **Cold starts.** Serverless cold starts add 100-500ms at p99 for low-traffic functions (RESEARCH-2026-04.md section 4.2). The budget for serverless components must include cold-start tax or provisioned concurrency.

### Name where the budget breaks in the ARCH.md

For every user-visible flow with a latency target, name the hop that is most likely to blow the budget under stress, and the mitigation. "The payment-gateway hop is the budget's dominant variance contributor; if Stripe p99 exceeds 300ms, the checkout latency SLO cannot be met. Mitigation: async order placement with status polling, cache recent pricing, and have a circuit-breaker fallback to retry-offline mode."

## Section 3. The throughput chain

### RPS and EPS calculations

The PRD says "scale to 10,000 concurrent users." That number is not a throughput; it is a concurrency. Translate:

- **Active users per second.** If 10,000 users each issue 5 requests per minute, the system handles (10000 * 5) / 60 = 833 RPS on the user-visible API. Bursts can be 2-5x this (users clicking rapidly).
- **Events per second.** Each user request may fan out to 3-10 internal events (analytics, audit, cache invalidation, downstream service calls). 833 RPS in means 2500-8000 EPS internally.
- **Background job throughput.** Scheduled jobs, webhooks, retries, cron tasks. Often spiky: 100x baseline during batch runs.

### Per-component capacity

For each component on the critical path, state its capacity. Capacity is a function of the engine (stack-ready's pick), the hardware (stack-ready's pick), and the workload shape (architecture-ready's commitment).

Concrete rough numbers (see Section 5 for more detail):

- **Single Postgres writer.** 5-10k TPS on standard hardware for simple transactional workloads; lower for complex transactions, higher with connection pooling and careful schema.
- **Postgres read replicas.** Each replica can serve reads at roughly the same TPS as the writer; scale horizontally for reads.
- **Redis single instance.** 100k ops/sec on commodity hardware; clustered Redis scales horizontally.
- **Kafka single partition.** 1-10 MB/sec throughput per partition; scale via more partitions and more consumers.
- **Node.js / Python single process.** 1-5k RPS for simple JSON APIs; scales horizontally with replicas.
- **Go / Java single process.** 10-50k RPS for similar workloads.

Name the capacity per component in the ARCH.md.

### Bottleneck identification

The throughput chain is only as fast as its slowest link. Walk the critical flow and identify:

- Which component first saturates as load increases?
- At what RPS does it saturate?
- What happens when it saturates (queue up, drop requests, slow down)?

The bottleneck is usually the write-side relational store or an external API. The architecture commits to where the bottleneck is and what happens when it is hit.

### Scale strategy

For each component, state the scale strategy:

- **Horizontal.** Add more replicas; stateless or shared-nothing. The default for application servers.
- **Vertical.** Bigger instance. Usually the path for single-writer databases before sharding.
- **Read replicas.** Offload reads to replicas; writes still single-writer. The typical relational-OLTP scale path.
- **Sharding.** Partition data across multiple writers. The hardest-scaling path; changes the schema and query layer.
- **Caching.** Memoize hot reads at a layer between the application and the store (Redis, Memcached, application memory).
- **CDN.** Cache static and semi-static content at the edge.
- **Precomputation.** Compute expensive results ahead of time (materialized views, nightly batch, on-write derivation).

### Little's Law

L = lambda * W. **Concurrency equals arrival rate times average latency.** If the system handles 1000 RPS with average latency of 200ms, the average concurrency is 1000 * 0.2 = 200 concurrent in-flight requests. That is the capacity the server must support at any instant.

**Why this matters.** Capacity planning conflates the three quantities constantly. "We handle 1000 RPS" without specifying the latency does not tell you the concurrency. "We support 200 concurrent users" without specifying the requests-per-user does not tell you the RPS. Little's Law makes the conversions explicit.

**Applied to the budget.** If the PRD says 10,000 concurrent users and the typical request is 300ms, lambda = L / W = 10000 / 0.3 = 33,333 RPS if every user is always active. Users are not always active; adjust by active-fraction (maybe 5-20%): 1,700-6,700 RPS actual. The architecture sizes for this.

## Section 4. The availability chain

### The nines

Availability as a percentage maps to downtime as follows (the canonical table):

| Availability | Monthly downtime | Yearly downtime |
|---|---|---|
| 99% | 7.2 hours | 3.65 days |
| 99.5% | 3.6 hours | 1.83 days |
| 99.9% | 43 minutes | 8.76 hours |
| 99.95% | 22 minutes | 4.38 hours |
| 99.99% | 4.3 minutes | 52.6 minutes |
| 99.999% | 26 seconds | 5.26 minutes |

Each additional nine is roughly 10x less downtime and typically 3-10x more expensive to achieve.

### Multiplicative availability math

**Serial dependencies multiply.** If a user request touches three components in serial, each at 99.9% availability, end-to-end availability is:

0.999 * 0.999 * 0.999 = 0.997, or **99.7% end-to-end**.

That is not 99.9%. It is meaningfully worse: 43 minutes of monthly downtime becomes 130 minutes.

**Five components in serial at 99.9% each:** 0.999^5 = 0.995 = **99.5% end-to-end**, or 3.6 hours monthly.

The architectural consequence: if the PRD target is 99.9% end-to-end and the critical path has three components, each component needs at least 99.97% to leave any slack for correlated failures. If the PRD target is 99.99% end-to-end with three hops, each hop needs 99.997%, which is rarely achievable on a single replica.

### Correlated failures

The multiplicative math assumes independent failures. In practice, failures correlate:

- **Shared infrastructure.** Two "independent" components on the same availability zone both fail when the AZ goes down.
- **Shared dependency.** Two components that both depend on the same third component fail together when the third fails.
- **Deploy-time correlation.** A bad deploy takes down both components at once.
- **Traffic correlation.** A traffic spike that overloads component A also spikes demand on B.

The architecture must call out correlated-failure vectors. "Both the Orders and Inventory components run in US-East-1; an AZ outage takes both down; end-to-end availability during an AZ event is 0%." This is not 99.9%; this is a known-correlated-failure mode.

### Redundancy math

Redundancy is the answer to correlated failure at the component level. Two replicas behind a load balancer, each at 99% availability, give:

1 - (1 - 0.99) * (1 - 0.99) = 1 - 0.0001 = **99.99%** combined (if failures are independent).

But again, if both replicas share an AZ, the independent-failure assumption fails. Multi-AZ redundancy is the next layer; multi-region is the layer beyond.

### The availability-chain ADR

At the end of Section 4, the ARCH.md states:

- The per-component availability target.
- The end-to-end availability target (the PRD's NFR).
- The math that shows the targets are consistent (or that one of them must change).
- The correlated-failure vectors and their mitigations (multi-AZ, multi-region, cell-based architecture per RESEARCH-2026-04.md section 4.6).

If the math does not close, the architecture either adds redundancy (more cost) or the PRD target is adjusted (negotiate with PM). Do not ship an infeasible availability chain.

## Section 5. Scale horizons

Every component has a capacity ceiling. Name the concrete number so the team knows when rearchitecture becomes necessary.

The ceilings are rough, vendor-dependent, and workload-dependent. State them as order-of-magnitude guidance, not guarantees.

### Relational OLTP (single-writer, e.g., Postgres-shaped)

- **5-10k TPS** on standard cloud hardware (e.g., RDS db.m5.2xlarge-class) without partitioning.
- **20-50k TPS** with tuning, connection pooling (PgBouncer), and query optimization.
- **100k+ TPS** requires partitioning, sharding, or a distributed-SQL engine (CockroachDB, Spanner, Yugabyte).

Ceiling signals: WAL-write saturation, connection-pool exhaustion, lock contention on hot rows.

### Read replicas

- Each replica adds roughly the writer's capacity for read-only queries.
- Replica lag is a separate concern: typical 100ms-10s depending on load and network; strong-read consistency requires routing to the writer or accepting lag.

### Redis single-instance

- **100k ops/sec** on commodity hardware for simple GET/SET.
- **Several hundred k ops/sec** with pipelining.
- Clustered Redis scales horizontally; cross-shard operations are restricted.

### Kafka single partition

- **1-10 MB/sec throughput per partition**; Kafka scales via more partitions.
- Consumer groups scale horizontally to match partition count.
- A single topic can have hundreds of partitions; a cluster can handle thousands of topics.

### Serverless functions

- **Cold starts: 100-500ms at p99** for low-traffic functions (AWS Lambda, CloudFlare Workers; the Cloudflare Workers shape has near-zero cold start due to V8 isolates, RESEARCH-2026-04.md section 4.3).
- **Concurrency ceilings.** AWS Lambda default concurrency limit is 1000 concurrent executions per region; can be raised. Reaching the ceiling throttles requests.
- Cost curve: cheap at low volume; crosses over to container pricing at sustained high volume.

### CDN edge

- **Millions of RPS** per region for cached content.
- **Cold cache miss** roundtrips to origin; cache hit ratio drives the effective load on origin.

### WebSocket connections

- **10k-100k concurrent connections per instance** for most server implementations.
- Memory per connection is the typical bottleneck.

### Naming the ceiling in the ARCH.md

Per load-bearing component, state the ceiling: "Postgres writer ceiling at 8k TPS on the chosen instance class. At 12-month projected load of 2k TPS, we have 4x headroom. Trigger for rearchitecture planning: 4k sustained TPS." This gives the team a forward-looking signal; the architecture plans for the horizon, not just today.

## Section 6. Consistency and partitioning

The formal grounding for consistency and partitioning decisions.

### CAP theorem (Brewer)

In the presence of a network partition, a distributed system must choose between consistency and availability. Formally: Consistency, Availability, Partition-tolerance; choose two (but partition-tolerance is not optional in a real distributed system, so the real choice is CP or AP).

- **CP system.** When the network partitions, refuse to serve requests that could violate consistency. Examples: most relational databases with failover; HBase; MongoDB with strong consistency configs.
- **AP system.** When the network partitions, keep serving requests, tolerate inconsistency, reconcile later. Examples: DNS; Cassandra; Dynamo-style stores.

Eric Brewer, "Towards Robust Distributed Systems," PODC 2000 keynote; formalized by Gilbert and Lynch, "Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services," SIGACT News 2002.

### PACELC (Abadi)

CAP's extension: in the presence of a Partition, choose Availability or Consistency; Else (when no partition) choose Latency or Consistency. Daniel Abadi, 2010, "Problems with CAP, and Yahoo's little known NoSQL system," https://dbmsmusings.blogspot.com/2010/04/problems-with-cap-and-yahoos-little.html.

PACELC captures the full trade-off space:

- **PC/EC.** Consistency on partition AND in normal operation. Relational databases. Slow but consistent.
- **PA/EL.** Availability on partition AND low-latency in normal operation. Dynamo-style. Fast but eventually-consistent.
- **PC/EL.** Consistency on partition, latency in normal operation. Rare.
- **PA/EC.** Availability on partition, consistency in normal operation. Some tunable systems.

### Architectural impact

**Strong consistency limits throughput.** Write-path serialization (at the single writer, at the consensus quorum) caps TPS. Cross-region strong consistency adds the latency of cross-region round trips.

**Eventual consistency requires application-level reconciliation.** The application must handle temporary inconsistency (display stale data with a timestamp; re-read; conflict-resolution policy). CRDTs (conflict-free replicated data types) are the formalism for data structures that merge automatically; when the domain fits a CRDT (counters, sets, last-write-wins maps), eventual consistency is free; when it does not, reconciliation is application code.

### Where the ARCH.md commits

Per entity group, state:

- **Consistency model.** Strong, linearizable, sequential, causal, eventual.
- **Partition tolerance.** Single-region (no partition concern), multi-AZ (limited partition concern), multi-region (full partition concern).
- **Reconciliation strategy** (for eventually-consistent entity groups): last-write-wins, vector clocks, CRDT, application-defined.

## Section 7. Security, privacy, compliance as shape constraints

Compliance is a filter on the architecture, not a sticker on top.

### HIPAA scope

HIPAA applies when the system handles Protected Health Information (PHI). Components in scope: any that store, process, or transmit PHI. Requirements include access controls, audit logging, encryption in transit, encryption at rest (addressable, strongly recommended), breach notification, minimum-necessary access, Business Associate Agreements (BAAs) with vendors.

**Architectural impact.** PHI-handling components run on BAA-covered infrastructure. Audit logging is continuous. Analytics pipelines that receive PHI are themselves in scope; de-identification at the ingress to analytics keeps analytics out of scope. PHI encryption keys are managed with restricted access; key rotation is audited.

### PCI DSS scope

PCI DSS applies when the system handles cardholder data (PAN, track data, CVV). Scope boundaries are load-bearing: every component that touches PAN is in scope, which includes logs, backups, and ephemeral data.

**Architectural impact.** The common pattern is tokenization at the ingress: the Payment component interacts with PAN briefly; a payment processor (Stripe, Braintree) tokenizes; downstream components handle tokens, not PAN. The tokenized shape shrinks PCI scope dramatically. Components that MUST handle PAN are physically isolated, network-segmented, and under stricter audit.

### SOC 2

SOC 2 is an audit framework, not a regulation. Type 1 audits the controls at a point in time; Type 2 audits their operation over a period (typically 6-12 months).

**Architectural impact.** Control evidence: audit logs, access-review processes, change-management records, incident-response documentation. The architecture commits to what is logged, where, for how long, and how access is reviewed. The logging infrastructure is itself in scope and must be reliable.

### GDPR and data residency

GDPR applies to personal data of EU residents. Requirements include lawful basis for processing, right to access, right to erasure, right to portability, data-processing agreements, breach notification, data-protection officer for certain organizations.

**Data residency.** GDPR does not strictly require EU-only storage (adequacy decisions and Standard Contractual Clauses allow transfer), but many customers demand it contractually. China's PIPL and Russia's data-localization laws strictly require local storage for certain data.

**Architectural impact.** Either a single-region deployment in the residency zone (simplest, if customers are in one region), or multi-region with data routing by residency (complex, but scales to global customers). The right-to-erasure requirement shapes data lifecycle (data-architecture.md Section 5); erasure requests propagate across all components holding the subject's data.

### FedRAMP and SOC environments

FedRAMP applies to US federal agencies' cloud services. Compliance requires FedRAMP-certified infrastructure (AWS GovCloud, Azure Government, specific compliant zones in other clouds). Architectural impact: vendors must be compliant; per-region deployment may be required.

### Where this section commits

The ARCH.md states, per regulated data class:

- Which components are in scope.
- Which are deliberately kept out of scope (tokenization, de-identification at ingress).
- Where the in-scope components run (region, cloud zone, compliance tier).
- What the audit, encryption, and access-control commitments are at the shape level (not the tool level; stack-ready picks).

## Section 8. Observability shape

**What architecture-ready commits to.** The shape of observability: what signals must propagate across boundaries, what audit events must be captured, where they go.

**What observe-ready owns.** The implementation: dashboards, alert rules, SLO burn-rate policies, runbook scope, on-call rotation.

architecture-ready precedes observe-ready; the shape commitments are inputs.

### Trace IDs and correlation IDs

Every user request gets a trace ID at the edge. The trace ID propagates through every component that handles the request: HTTP headers, RPC metadata, event-log event envelopes, queue messages. Every log line emitted by every component carrying the trace ID allows reconstruction of the full request trajectory.

**Architectural commitment.** "Every component on the critical path accepts an inbound trace ID (or mints one if absent) and propagates it to every outbound call, log line, and event emission. The propagation follows the OpenTelemetry convention (W3C Trace Context headers). Failure to propagate is a defect, not a style choice."

### Span boundaries

Within a component, spans delimit units of work (a handler invocation, a DB query, an outbound call). Spans have timestamps, durations, tags, and parent-span references. The span graph is the call graph, trace-annotated.

**Architectural commitment.** Every load-bearing operation (handler entry, DB query, external call, event emission) is a span. observe-ready picks the tool (Honeycomb, Tempo, Jaeger, Datadog APM); architecture-ready commits to the span boundaries.

### Audit events

Audit events are distinct from operational logs. An audit event records: who did what, to what, when, from where. Audit events are consumed by security, compliance, and customer-facing features (audit log UI).

**Architectural commitment.** Every high-blast-radius mutation (trust-boundaries.md Section 4: cross-tenant DELETE, admin impersonation, billing change, API-key rotation, export-all) emits an audit event. Audit events go to a dedicated durable store (not application logs; audit logs have different retention, access, and tamper-resistance requirements). Audit events are immutable; the retention is compliance-driven (HIPAA: 6 years; SOC 2: audit-scope-defined, often 1-7 years; PCI DSS: 1 year with 3 months immediate).

### What crosses boundaries

Every service boundary is an observability boundary. At the boundary:

- Trace ID propagates.
- Latency is measured (boundary-level span).
- Error rates are attributed (this boundary's errors vs. that boundary's errors).
- Audit events (if the boundary is a trust boundary) are emitted.

### The shape as an observe-ready input

observe-ready reads these commitments and wires the tool. If the architecture does not commit to trace-ID propagation, observe-ready cannot produce coherent end-to-end traces. If the architecture does not commit to audit-event emission points, observe-ready cannot produce the audit-log feature the PRD asked for.

## Section 9. Operational posture

The PRD's operational NFRs constrain the architecture.

### On-call coverage

**24/7 vs. business hours.** 24/7 on-call for a small team means rotational burnout or outsourced on-call; business-hours-only means overnight outages go uncaught until morning, which constrains the SLA the product can promise.

**Architectural impact.** If on-call is business-hours only, the architecture cannot promise 99.9% 24/7 availability. Either the operational posture matches the NFR, or the NFR is relaxed.

### Runbook scope

Every alert must have a runbook. The architecture commits to: which operational concerns have runbooks, which are "escalate to engineering." A runbook-only scope (no escalation) means the runbook is complete; an escalation-included scope means the engineering team is the backstop.

### Deploy frequency

Continuous deployment means the architecture must tolerate deploys multiple times per day without user-visible impact. This shapes: zero-downtime deploys, expand-contract schema migrations (data-architecture.md Section 9), backward-compatible API changes (integration-architecture.md Section 8), feature flags for staged rollout.

Weekly or monthly deploys allow more coupling; big-bang deploys allow the most coupling but have the highest risk.

### Rollback window

The time between "we noticed" and "rollback complete." Typical targets:

- **Serverless / function deploys:** seconds (re-deploy the previous version).
- **Container-based services:** minutes (re-deploy the previous image).
- **Database schema changes:** hours to days (data migrations are not reversible without a new migration).

deploy-ready owns the pipeline; architecture-ready commits to the rollback unit (what can be rolled back independently).

### Backup / restore RTO and RPO

**RTO (Recovery Time Objective).** How long until the system is back after a disaster.

**RPO (Recovery Point Objective).** How much data loss is acceptable.

The PRD states both; the architecture must support both.

**The 15-minute RPO example.** If the PRD says 15-minute RPO, a daily backup job is not compatible. The architecture needs continuous replication (streaming replication for Postgres, WAL shipping with 15-minute latency at worst), or synchronous replication to a standby, or event-sourcing with continuous log persistence.

**Typical RPO/RTO combinations:**

- **RPO 1 hour, RTO 4 hours.** Hourly backup, manual restore. Common for internal tools.
- **RPO 15 minutes, RTO 1 hour.** Continuous replication, automated restore. Common for customer-facing SaaS.
- **RPO 0 (no data loss), RTO minutes.** Synchronous multi-region replication. Expensive; mandatory for financial or regulated systems.

The architecture commits; the stack-ready skill picks the engines that support the commitment; the deploy-ready skill wires the restore pipeline.

## Section 10. The math check

At the end of Step 6, run the chains and compute. This is a gate, not a formality.

### The three chains

1. **Latency chain.** Sum the per-hop latency budgets. Compare to the PRD's latency target. If sum > target, the chain fails: either remove a hop, parallelize, cache, or negotiate the target.
2. **Availability chain.** Multiply the per-component availabilities. Compare to the PRD's availability target. If product < target, the chain fails: add redundancy, eliminate a serial dependency, or negotiate the target.
3. **Throughput chain.** Identify the bottleneck component. Compare its capacity to the projected load at 12-month scale ceiling. If capacity < load, the chain fails: horizontal scaling, caching, or rearchitecture.

### What "fails the math" means

If any chain fails, the architecture does not meet the PRD and must change. The options:

- **Change the shape.** Remove a hop (co-locate components); add a cache; parallelize; precompute; partition.
- **Change the target.** Negotiate with the PM: "the PRD says p95 under 200ms; the payment gateway alone has p95 of 150ms; we can hit 250ms but not 200ms. Is 250ms acceptable, or do we need to remove the payment gateway from the critical path?"
- **Add a component.** Redundancy for availability; a cache for throughput; a CDN for latency.

### Do not ship an infeasible chain

The worst outcome is shipping an architecture whose math is known to not close. The team builds; the system goes live; the SLA is missed from day one; the team scrambles. Architecture-ready's job is to catch this on paper, before the code is written. If the math does not close, the architecture does not pass Tier 2.

### The math check as a Tier 2 gate

From the SKILL.md Tier 2 requirements: "NFR chains computed. Step 6: latency, availability, throughput chains each compute to the PRD's targets. Infeasible chains are called out, and either the shape or the target is adjusted." This is not optional. A Tier 2 ARCH.md with adjectives instead of numbers, or with a chain that does not compute, fails the tier.

### Example of a closing chain and a failing chain

**Closing chain (order placement):**

- Latency budget: TLS 50ms + auth 5ms + middleware 5ms + DB 30ms + business logic 10ms + payment gateway 100ms + serialization 10ms = 210ms.
- Target: p95 under 300ms. 
- Headroom: 90ms for variance, GC, warm-up. Closes.

**Failing chain (the same flow with a partner credit check):**

- Latency budget: 210ms (as above) + credit check 200ms = 410ms.
- Target: p95 under 300ms. 
- Gap: 110ms over.
- Mitigation options: (a) make the credit check async, return 202 Accepted, notify via webhook when complete; (b) parallelize the credit check with the payment authorization; (c) cache recent credit-check results for the same customer; (d) negotiate the target to 500ms.

Name the mitigation; do not write "we will optimize later." "Later" is how the infeasible chain ships.

End of non-functional-architecture.md.
