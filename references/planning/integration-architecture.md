# Integration Architecture

The Step 5 protocol. Sync vs async, transport shapes, idempotency, failure modes, and the named patterns teams reach for when they should not. The dimension that AI-generated architecture handwaves most.

**Scope owned by this file:** the decisions per integration (internal and external). Per integration, four answers: sync/async, transport, idempotency, failure mode. Named patterns (outbox, saga, CQRS, event sourcing, API gateway, service mesh, sidecar, strangler fig) get a subsection each, with the cargo-cult refusal rule.

## Section 1. The sync-vs-async decision

**The most load-bearing integration choice.** Every other integration decision stacks on top of this one. Get it wrong and the architecture is either an unresponsive mess (everything blocks on everything) or a consistency nightmare (everything is eventually-consistent and nothing is ever actually in sync).

### What sync means

The caller sends a request and blocks waiting for the callee's response. If the callee is slow, the caller is slow. If the callee is down, the caller fails immediately. Coupling is tight: the caller cannot proceed without the callee.

**Wins.** Failure is visible at the point of failure; debugging is local; the caller knows whether the operation succeeded. The semantics are the same as a local function call, which is a simpler mental model. End-to-end latency is the sum of the hops, which is predictable and easy to budget.

**Loses.** Every hop is a point of cascading failure; a slow callee makes a slow caller, which makes a slow caller's caller. Availability is multiplicative across sync chains (three services at 99.9% each give 99.7% end-to-end, minus correlated-failure slack; see non-functional-architecture.md Section 4). Tight coupling: upgrades, deploys, and scaling must be coordinated.

### What async means

The caller sends a message and moves on. The callee eventually processes it. Failure is invisible at the point of send; detection requires monitoring the queue or the consumer. Coupling is loose: the caller does not know when (or if) the callee processes the message.

**Wins.** Bursts are absorbed by the queue; slow consumers do not slow producers. Availability of the caller does not depend on availability of the consumer; the consumer can be down for minutes or hours and work queues up. Fan-out: one message to many consumers without the producer knowing who they are. Loose coupling allows independent deploys and scaling.

**Loses.** Failure is invisible until someone checks the queue depth, the dead-letter queue, or the consumer lag. Consistency is eventual; the caller cannot answer "did this complete" at the moment of send. Debugging is non-local; a failure traced to a stuck consumer may be hours removed from the triggering request. Operationally heavier: queues, consumers, monitoring, DLQ handling, retry policy, poison-message handling.

### Rules of thumb

**Pick sync when:**

- The caller genuinely needs the callee's response to continue (a checkout flow must know whether the payment succeeded before showing the confirmation page).
- The operation is latency-bounded and the caller has an SLO that depends on the callee meeting its own SLO.
- The operation is idempotent and short; retries on network errors are cheap.
- The system has a small enough service count that the multiplicative-availability math still works.

**Pick async when:**

- The operation can complete without a caller waiting (send email, update analytics, emit audit event, recompute a derived view).
- The operation fans out to many consumers (one "user signed up" event fires email, analytics, billing provisioning, CRM sync).
- The operation tolerates delay measured in seconds to minutes (cache invalidation, search index update, webhook delivery).
- The producer and consumer must scale independently; bursts on one side should not crush the other.

### The mixed-flow antipattern

Mixing sync and async inside the same user-visible operation without a clear handoff is the **distributed monolith** in integration clothing (RESEARCH-2026-04.md section 2.6; Sam Newman, "Monolith to Microservices," 2019). Symptoms:

- "Service A calls Service B synchronously, which emits an event to Service C, which calls Service D synchronously, and the user's request is waiting on all of it." This is worse than pure sync (because of the async handoff's unpredictability) and worse than pure async (because the user is blocked).
- "The operation is async, but the caller polls a status endpoint every second until it sees success." This is sync with extra steps; the architecture has committed to polling overhead without getting the benefits of true async.
- "Critical consistency depends on an async consumer catching up before the next user action." This is a race condition architectualized into a feature.

The rule: commit to sync or async per flow. At flow boundaries, the handoff is explicit ("return 202 Accepted; the caller polls `/jobs/:id` or subscribes to webhooks"), not implicit.

## Section 2. Transport shapes

Pick the transport per integration. Each has a sweet spot and a failure signature.

### 2.1 REST over JSON

HTTP verbs, resource URLs, JSON payloads. The lingua franca of the 2010s-2020s internet.

**Pros.** Universal tooling; every language has a client; every proxy, load balancer, and CDN understands HTTP; debugging is `curl`. Widely readable OpenAPI specs. Stateless per-request; horizontally scalable at the server.

**Cons.** Verbose over the wire compared to binary formats. No built-in streaming semantics (workarounds: SSE, WebSockets, or chunked transfer). Versioning is disciplined by convention, not by schema enforcement; breaking changes slip through without contract tests.

**Versioning discipline.** Versioned path (`/v1/...`, `/v2/...`), additive changes within a version, explicit breaking-change deprecation cycle (announce, parallel-run, remove). The GitHub API and Stripe API are the exemplars.

### 2.2 gRPC

HTTP/2 with Protocol Buffers. Strongly-typed schemas, code-generated clients, bidirectional streaming.

**Pros.** Strong contracts via `.proto` files; breaking changes are detectable at build time; performance is better than REST for internal service-to-service. First-class streaming. Multi-language client generation is excellent.

**Cons.** Browsers cannot speak gRPC directly (gRPC-Web is a proxy translation layer). Debugging requires gRPC-aware tools; `curl` does not work. Operational tooling is less mature than REST's. The versioning discipline is the Protocol Buffer versioning rules (adding fields is safe; renumbering or retyping is breaking).

**Versioning discipline.** Follow Protobuf rules: never change a field's tag number or type; deprecate fields with `[deprecated = true]`; keep old fields around for the grace period.

### 2.3 GraphQL

Single endpoint, client-specified query, typed schema.

**Pros.** Clients fetch exactly what they need. One endpoint instead of many REST endpoints. Strong schema. Good for aggregating heterogeneous back-ends behind a single API.

**Cons.** Server-side complexity: N+1 queries without careful DataLoader use; authorization at field level is non-trivial; caching is harder than REST (every query is unique). Rate limiting is harder (query cost varies). Not a good fit for mutations with strict ACID requirements.

**Versioning discipline.** Schema evolution: additive changes are safe; fields deprecated with `@deprecated`; breaking changes require a schema version bump or a parallel-schema rollout.

### 2.4 WebSockets

Bidirectional persistent TCP connection over HTTP upgrade. Both client and server can push.

**Pros.** True bidirectional; low-latency after connection established. The transport of choice for chat, collaborative editing, live dashboards, multiplayer games.

**Cons.** Stateful connection: sticky routing is required or connections must tolerate re-connection. Load balancer support varies. Horizontal scaling requires a shared message bus (Redis pub/sub, Kafka, or similar) so back-ends can deliver messages to connections they do not own.

### 2.5 Server-Sent Events (SSE)

One-way server-to-client streaming over HTTP. A long-lived response whose body is a stream of events.

**Pros.** Simpler than WebSockets when the flow is server-push-only; works through most HTTP proxies; auto-reconnect built into the browser's `EventSource`. Ideal for LLM token streaming, live feeds, notifications.

**Cons.** One-way; client-to-server still needs a separate request. Less ubiquitous than WebSockets.

### 2.6 Event log (Kafka-shaped)

Durable, partitioned, append-only log; consumers read from offsets; retention is days to weeks (or indefinite with compaction).

**Pros.** Multi-consumer fan-out at scale; replay from any offset; durable storage; decoupling of producer and consumer in time. The right shape for audit, stream processing, and integration of multiple independent consumers off a shared event stream.

**Cons.** Operationally heavy in self-host form (ZooKeeper historically, KRaft now; partition management; broker tuning); somewhat mitigated by managed offerings (Confluent Cloud, Amazon MSK, Redpanda Cloud). Ordering is per-partition, not global. Consumer offset management is the consumer's responsibility.

**Versioning discipline.** A schema registry (Confluent Schema Registry, Apicurio) is the only scalable discipline. Avro, Protobuf, or JSON Schema with compatibility rules (backward, forward, full). Without a schema registry, event payload evolution collapses into ad-hoc JSON that breaks consumers quietly.

### 2.7 Message queue (SQS-shaped)

Point-to-point async: one producer, one consumer (or a pool of consumers competing for messages). No replay; delivered messages are gone.

**Pros.** Simpler operationally than Kafka; managed offerings are ubiquitous (SQS, Cloud Pub/Sub, Azure Service Bus, RabbitMQ). Right shape for task queues, webhooks, and work distribution.

**Cons.** No replay; no multi-consumer fan-out in the pure form (some engines overlay pub/sub on queues for fan-out). Ordering guarantees vary (SQS standard is at-least-once with best-effort ordering; FIFO is stricter with throughput trade-offs).

### 2.8 Webhook

Outbound HTTP POST from one system to another. The integration pattern for "when X happens in Stripe, notify my service."

**Pros.** Simple; every system can implement them; debuggable with an HTTP server.

**Cons.** Inbound surface area (receiver must be publicly reachable or use a webhook relay like ngrok / Svix in dev); retry discipline is the sender's problem and varies (Stripe retries with exponential backoff for up to 3 days; others retry once and give up); signature verification is mandatory (see Section 7); replay attacks require timestamp validation.

### 2.9 RPC-over-shared-DB (antipattern)

One service writes a row; another service polls the table. Or one service updates a status field; another service reacts by observing the change.

**Antipattern.** Both services are coupled to the shared schema, both services write, invariants span services, schema evolution requires coordinated deploys. This is the **distributed monolith** antipattern in its purest form (RESEARCH-2026-04.md section 2.6).

**When it is acceptable.** The shared DB is a dedicated integration surface (an outbox table, a job table) where one service is the writer and the other is a reader with a well-defined protocol. Temporal, Hatchet, and similar workflow engines formalize this as a supported pattern.

### 2.10 File transfer

SFTP, S3 bucket drop, shared drive. Batch-oriented. Common in enterprise integrations and partner data exchange.

**Pros.** Works everywhere; tolerates offline endpoints; natural batching.

**Cons.** Latency is minutes to hours; schema is the file format (CSV without schema is a perennial disaster); no built-in delivery confirmation. Error detection requires explicit ack files or monitoring.

## Section 3. Idempotency

The most commonly-handwaved integration property. Most AI-generated architecture documents either omit idempotency entirely or state "idempotent" as a claim without a mechanism.

### The reality of delivery guarantees

- **At-most-once.** Rare. Usually wrong because messages are lost on failure and the system cannot recover them. Only acceptable when the message content is self-recomputable (e.g., cache invalidation: if we miss it, the cache TTL will save us).
- **At-least-once.** The default. Messages may be delivered more than once due to retries across network failures, consumer crashes, or duplicate sends. The receiver must be idempotent.
- **Exactly-once.** A myth outside narrow windows. Kafka's "exactly-once semantics" (EOS) is an at-least-once producer plus transactional commit to a specific sink; it is not a general-purpose exactly-once delivery across heterogeneous systems. Distributed exactly-once across independent systems requires either a shared transactional context (rare) or idempotent receivers (the common solution). Pat Helland's "Life Beyond Distributed Transactions" (CIDR 2007) is the theoretical grounding.

### The formula

**At-least-once delivery plus idempotent receivers.** This is the industry-standard pattern, and the one architecture-ready commits to unless a specific constraint justifies otherwise.

### Idempotency key design

Every mutation that can be retried needs an idempotency key. The key is:

- **Client-generated** for API calls (the caller sends `Idempotency-Key: <uuid>` on every retry).
- **Event-generated** for event-log consumers (the event's ID plus consumer identity).
- **Deterministic** for scheduled jobs (`<job-name>-<logical-timestamp>`).

The receiver maintains a dedup cache: given the same idempotency key, return the same result without re-executing the mutation. The cache entry includes the outcome so retries return the original response.

### Retry window

How long does the receiver remember keys? The dedup window must cover:

- The sender's retry window (Stripe: up to 3 days; your own webhook consumer: configure explicitly).
- Plus a buffer for clock skew and queue lag.

Typical windows: 24 hours for API calls, 7 days for webhooks, unlimited for append-only event logs where the event ID is intrinsic.

### Dedup cache sizing

For a receiver handling N requests per day with a 24-hour window, the cache holds N entries. For 1M requests/day, that is 1M entries; a Redis instance handles it easily. For 100M requests/day, the cache itself is a database with its own sharding, persistence, and failure modes. At that scale the architecture is a decision, not an implementation detail.

### Idempotency as an architecture-ready commitment

Step 5 of the skill requires every mutation-over-network to name its idempotency posture. "At-least-once plus idempotency key on POST /orders with 24-hour dedup window, stored in Redis" is a decision. "Idempotent" is a claim; refuse it.

## Section 4. Failure modes and blast radius

Every integration has failure modes. The architecture names them and the responses.

### Circuit breakers

Pattern: when a downstream integration fails N times in a window, stop calling it for a cooldown period, then half-open to probe. Prevents cascading failure: a slow callee does not drag every caller down.

The shape is the decision; the tool is stack-ready. The shape: "when calls to partner API X fail more than 5 times in 30 seconds, open the breaker for 60 seconds; return a pre-computed fallback during open state." Tools that implement this shape: Hystrix (Netflix, deprecated but still referenced), Polly (.NET), Resilience4j (Java), Failsafe (Java), various JS implementations. Name the shape, not the tool; stack-ready picks.

### Retries with exponential backoff and jitter

When a call fails on a transient error (timeout, 5xx, connection reset), retry. But retry carefully:

- **Exponential backoff.** Wait 100ms, then 200ms, then 400ms, then 800ms. Prevents hammering a struggling callee.
- **Jitter.** Randomize the wait by +/- 25%. Prevents the thundering-herd problem where many clients retry in lockstep. AWS Builders Library "Timeouts, retries, and backoff with jitter" is the canonical reference.
- **Budget.** Cap total retry time; after N seconds or M attempts, give up and return failure to the caller. Infinite retries are an availability problem disguised as a reliability feature.
- **Idempotency.** Retries require an idempotency key on mutations (Section 3).

### Dead-letter queues (DLQ)

For async consumers, messages that fail processing after N retries go to a DLQ. The DLQ is not "set and forget"; it is an operational concern with monitoring, alerting, and a runbook for triage.

The architectural commitment: every async integration has a DLQ, a DLQ-depth alert, and a named owner who triages DLQ messages when the alert fires. "DLQ exists" is not a decision; "DLQ exists, alerts at depth 10, owned by the Orders team, triaged weekly" is.

### Graceful degradation

When an integration fails, the caller can either hard-fail or degrade gracefully. The choice is per-integration and per-user-flow:

- **Recommendations down.** Show the homepage without recommendations; degrade gracefully.
- **Payment gateway down.** Refuse the checkout; hard-fail with a clear error.
- **Analytics down.** Log locally and forward later; degrade without user awareness.
- **Auth down.** Nothing works; hard-fail.

The architectural spec: for every integration in the critical path, name the degradation strategy. "If partner X is unreachable, do Y" is a decision.

### Hard failure as a design choice

Sometimes the right answer is "fail fast, fail visibly, do not retry." For non-idempotent operations with real-world side effects (moving money, sending physical goods), retrying a failed call that may have succeeded is worse than failing and requiring human reconciliation. Name this explicitly when it applies.

## Section 5. Named integration patterns

Every pattern below has a legitimate use case and an overuse case. The cargo-cult check (RESEARCH-2026-04.md section 2.3): if the pattern appears in the architecture, the ADR must cite the specific PRD constraint that justifies it. "Because best practice" is not justification. "Because the PRD mandates X" is.

### 5.1 Outbox pattern

**What it is.** A writer inserts to the business table and to an `outbox` table in the same local transaction. A reader (CDC consumer or polling worker) forwards outbox rows to downstream systems (queue, event log, webhook) at-least-once, marking rows as sent on acknowledgement.

**When it wins.** Any time a mutation must reliably trigger an external effect: send email, emit event, call a downstream service. Solves the dual-write problem (see data-architecture.md Section 6.3).

**When it loses.** Never really. It is the default pattern for reliable event emission. The ADR cost is low.

**PRD constraint that justifies it.** Whenever a user-triggered action must reliably produce a downstream effect and the system cannot tolerate inconsistency between the local write and the external emit.

### 5.2 Saga pattern (orchestration vs. choreography)

**What it is.** A long-running distributed transaction coordinated by compensating actions. Step 1 runs; if Step 2 fails, the compensating action for Step 1 runs.

- **Orchestration.** A central coordinator (Temporal, AWS Step Functions, Camunda, custom workflow engine) drives the steps and handles compensation.
- **Choreography.** Each service reacts to events; no central coordinator. Tighter coupling in time, looser coupling in structure.

**When it wins.** Operations that span multiple services with eventual-consistency tolerance and explicit compensation semantics (travel booking: book flight, book hotel, charge card; if the hotel fails, refund the card and cancel the flight).

**When it loses.** When the operation could be a single local transaction because all the writes are in one bounded context. Sagas are for genuine cross-service transactions; using a saga inside a single service is overengineering.

**PRD constraint that justifies it.** A flow that spans bounded contexts, must complete eventually, and has a defined compensation path. If compensations are undefined ("what if the card charge succeeded but the hotel booking failed?" -> "we'll handle it manually"), the saga is paper-tiger.

### 5.3 CQRS

**What it is.** Separate read and write models. Writes go through a command model; reads come from a query model, possibly projected from events or replicated from the write store.

**When it wins.** Read and write patterns genuinely differ: writes are simple transactional updates, reads are complex aggregations over denormalized views. The canonical example: an order-entry system where writes are "create order, update order status" and reads are "dashboard of orders by region, status, month, total."

**When it loses.** Most systems. Read-write patterns are usually similar enough that a well-indexed relational store handles both. CQRS adds complexity: two models to maintain, eventual consistency between them, more things to fail. RESEARCH-2026-04.md section 4.5: CQRS is one of the two most over-prescribed advanced patterns.

**PRD constraint that justifies it.** Read patterns at a scale or complexity the write store cannot serve, and/or read patterns that require different data shapes (columnar, denormalized, search-indexed) than the write store provides. "CQRS because separate query model" is circular; the question is why the query model must be separate.

### 5.4 Event sourcing

**What it is.** The event log IS the source of truth. State is a projection computed from events. The current balance of an account is the sum of all credit and debit events.

**When it wins.** Audit and replay are load-bearing. Regulatory requirements mandate immutable event history. The business logic fundamentally thinks in events (financial ledger, workflow audit trail, blockchain-shaped domains).

**When it loses.** Most systems. Event sourcing is complex: every query requires projection, schema evolution of events is a discipline, debugging requires event replay, testing requires event fixtures. A history table with `created_at` and a changelog gets 80% of the audit value at 10% of the cost. RESEARCH-2026-04.md section 4.5: "Whole System Based on Event Sourcing is an Anti-Pattern" (InfoQ 2016; Chris Kiehl, "Event Sourcing is Hard"; Oliver Butzki on event sourcing as a microservice anti-pattern).

**PRD constraint that justifies it.** Regulatory replay requirement, reconstructable history as a product feature, or a domain that is fundamentally an event stream. If the justification is "audit," a history table is cheaper. If the justification is "time-travel debugging," there are better tools.

### 5.5 The CQRS and event-sourcing refusal

Both are over-prescribed. The architecture-ready refusal:

- **CQRS is justified when read patterns cannot be served by the write store.** Not when "separating reads and writes feels cleaner."
- **Event sourcing is justified when the event log is the business truth.** Not when "events are the future of architecture."
- **Applying event sourcing to a whole system is an antipattern.** Apply it to a bounded context where the events-as-truth semantics are load-bearing (the Payments or Ledger context), not to the entire application.

If the AI-generated architecture proposes event sourcing, demand the PRD line that requires it. If none exists, reject.

### 5.6 API gateway

**What it is.** A single entry point for external traffic. Handles authentication, rate limiting, routing, request transformation, and sometimes aggregation across back-end services.

**When it wins.** At microservices scale with cross-cutting concerns (auth, rate limiting, logging) that would otherwise be duplicated in every service. Managed gateways (Kong, Apigee, AWS API Gateway, Cloudflare API Shield) are mature.

**When it loses.** For a monolith or a service-oriented architecture with 3-5 services. The single-entry-point concern is handled by the load balancer plus middleware in the service itself. Adding an API gateway for a small system is cargo-cult.

**PRD constraint that justifies it.** Multiple services with shared cross-cutting concerns that cannot be handled at the load balancer level, and a team that has operated gateways before (or a managed-gateway budget).

### 5.7 Service mesh

**What it is.** Sidecar proxies (Envoy, Linkerd) alongside every service, enforcing network policy, mTLS, observability, circuit breaking, and retries uniformly across the fleet.

**When it wins.** At 20+ services with consistent networking needs and a team that includes platform engineers who can operate the mesh. Istio and Linkerd are production-grade.

**When it loses.** For fewer than 20 services, or for teams without platform-engineering capacity. The mesh has operational overhead (sidecar resource consumption, debugging sidecar failures, mesh version upgrades) that small teams cannot absorb. Istio itself merged its control-plane microservices back to a single binary in 2020 (RESEARCH-2026-04.md section 0 and 4.1) because the distributed control plane was more complex than justified.

**PRD constraint that justifies it.** Fleet size (20+ services), platform-engineering staffing, and the cost of NOT having uniform policy enforcement (compliance, security posture).

### 5.8 Sidecar

**What it is.** A process that runs alongside the main service in the same deployment unit, providing cross-cutting functionality (logging, config, sidecar proxy, secrets fetching).

**When it wins.** When cross-cutting functionality is language-agnostic and benefits from isolation from the application process (sidecar-based config fetching like Consul Template; logging agents like Fluent Bit; envoy proxy for mTLS).

**When it loses.** When the functionality is simpler as a library in the application language. Sidecars add deployment-unit complexity.

### 5.9 Strangler fig

**What it is.** A pattern for gradual replacement of a legacy system. New functionality is routed to the new system; old functionality stays on the legacy system. Over time, the new system "strangles" the legacy system until it is entirely replaced. Martin Fowler coined the term: https://martinfowler.com/bliki/StranglerFigApplication.html.

**When it wins.** Large-system migrations where a big-bang replacement is too risky. The strangler router (often an API gateway or reverse proxy) controls routing and is the mechanism for gradual cutover.

**When it loses.** Small systems where a rewrite is faster than the strangler. The strangler pattern adds routing complexity; use it when the legacy system is too large to replace at once.

**PRD constraint that justifies it.** A legacy system in scope, an evolution-mode architecture (Mode E in the skill's mode detection), and a calendar that does not allow a big-bang cutover.

## Section 6. The CQRS and event-sourcing refusal (expanded)

Because this is the pattern most often cargo-culted, it deserves its own section.

### Why event sourcing is over-prescribed

Event sourcing as a concept is intellectually appealing: immutability, replayability, audit-as-feature, temporal queries. But the cost is real:

- **Every query requires projection.** The system must project events to state; either at read time (slow) or in the background (eventual consistency). The projection is itself a component with its own failure modes.
- **Schema evolution is a discipline.** Events are immutable; old events must be readable forever. Adding a field, renaming a field, or changing semantics requires event versioning, upcasters, or a parallel event stream.
- **Testing is harder.** Fixtures are event sequences, not rows. Tests must project events to assert state.
- **Debugging is non-local.** A bug in current state may trace to a corrupt projection or a missing upcaster for an old event type.
- **Tooling is thinner.** Event stores are a smaller category than relational databases; tooling for migrations, backups, and queries is less mature.

Chris Kiehl, "Don't Let the Internet Dupe You, Event Sourcing is Hard" (https://chriskiehl.com/article/event-sourcing-is-hard) and Oliver Butzki's DEV.to post "Why Event Sourcing is a microservice communication anti-pattern" (RESEARCH-2026-04.md section 4.5) document the industry's reconsideration.

### When event sourcing actually justifies itself

- A regulatory or contractual requirement mandates immutable event history with replay (financial audit, healthcare records with certain compliance regimes).
- The business domain is fundamentally event-driven: a ledger, a reservation system with complex cancellation semantics, a workflow engine.
- The team has event-sourcing experience (hiring for event-sourcing skill is harder than hiring for CRUD).
- The event log as source of truth is used, not just stored; projections are queried, replay is exercised, the event stream is integrated with.

### When CQRS justifies itself

- Reads at a scale the write store cannot serve (10x-100x read vs. write volume, or read-side aggregations that are infeasible against the normalized write store).
- Read shape genuinely different from write shape (writes are transactional rows; reads are search-indexed, denormalized, or columnar-analytical).
- The team can operate two models and the eventual-consistency window between them is acceptable to the business.

### The InfoQ refusal

InfoQ, "A Whole System Based on Event Sourcing is an Anti-Pattern" (2016, https://www.infoq.com/news/2016/04/event-sourcing-anti-pattern/). The summary: event sourcing applied to a bounded context with domain-appropriate semantics is legitimate; event sourcing as the architecture of an entire system is almost always a mistake. The architecture-ready rule: event sourcing is a bounded-context decision, not a system-level decision. If the ARCH.md proposes "the system is event-sourced," rewrite it as "the Payments/Ledger/Audit context is event-sourced; the rest is CRUD."

## Section 7. Partner integrations and webhook design

Third-party integrations are a failure domain the architecture must commit to.

### Common partners

Stripe, Twilio, Segment, Auth0, SendGrid, HubSpot, Salesforce, and the long tail of partner-specific APIs. Each has its own retry semantics, signature verification, rate limits, and idempotency discipline.

### Idempotency-key handling on inbound webhooks

Every partner retries webhooks on failure. Without idempotent processing on the receiver side, a retried webhook creates duplicate records, double-charges, or phantom events. The receiver must:

1. Extract a unique ID from the webhook payload (Stripe's `event.id`, Twilio's `MessageSid`, a partner-provided idempotency key).
2. Check a dedup cache; if the ID has been seen, return 200 OK without re-processing.
3. If new, process and record the ID in the dedup cache.
4. Return 200 OK only after durable recording of the outcome.

### Retry semantics (inbound and outbound)

**Inbound.** The partner retries on non-2xx. Stripe retries exponentially up to 3 days. Your receiver must handle duplicates (above) and respond quickly (return 200 immediately, process async if the work is heavy, else the partner times out and retries).

**Outbound.** Your own webhook emissions to customers must retry on their failures. The pattern: exponential backoff, retry budget, DLQ on permanent failure, customer-facing "webhook delivery log" surface so they can debug.

### Signature verification as a trust boundary

Every inbound webhook must be signature-verified. Without verification, the endpoint is a publicly-addressable mutation of your state. The signature is a trust boundary (trust-boundaries.md Section 1): it transitions from "untrusted internet caller" to "authenticated partner." Failure to verify is a security incident waiting to be exploited.

Implementation spec (architecture-ready commits to the spec; production-ready implements):

- HMAC-SHA256 (or equivalent) over the raw request body plus a shared secret.
- Signature in a header (e.g., `Stripe-Signature`).
- The receiver computes the HMAC on the raw body (not the parsed JSON) and compares with constant-time equality.
- Rejection returns 400/401 without processing.

### Replay attack prevention

Signature alone is not enough if the signed payload can be replayed. The standard addition: a timestamp in the signed payload or header, and a maximum-age check (reject if older than N seconds, typically 5 minutes) plus the idempotency key check. An attacker who captures a valid webhook cannot replay it outside the window.

## Section 8. Internal-service integration contracts

Service-to-service integrations need contracts as rigorous as external ones, arguably more so because they are not rate-limited by partner quotas and internal consumers are less defensive.

### 8.1 OpenAPI for REST

Every REST service publishes an OpenAPI (formerly Swagger) spec. The spec is the contract; clients generate code from it; the spec is versioned with the service.

**Versioning policy.** Additive changes within a major version (new endpoints, new optional fields). Breaking changes require a new major version with a parallel-run period. Deprecated endpoints are marked and removed on a schedule, not silently.

### 8.2 gRPC proto for gRPC

The `.proto` file is the contract. Field tag numbers are immutable. Adding fields is safe; removing or renumbering breaks clients and must follow a deprecation cycle.

### 8.3 Schema registry for event log

For Kafka-shaped integrations, a schema registry (Confluent Schema Registry, Apicurio) is the only sustainable discipline. The registry enforces compatibility rules (backward, forward, or full) at produce time; incompatible schemas are rejected before they corrupt the log.

Compatibility rules:

- **Backward.** New consumers can read old messages. Adding optional fields with defaults is backward-compatible.
- **Forward.** Old consumers can read new messages. Removing fields is forward-compatible.
- **Full.** Both. The safest; the most restrictive.

Pick one per topic; document it; enforce it in the registry.

### 8.4 Backward and forward compatibility rules

For any contract, the team commits to which direction of compatibility is required. The decision is an ADR if non-obvious.

- **Read-old-write-new case.** The producer is ahead of the consumer. Requires backward-compatible schema changes (consumers tolerate unknown fields).
- **Read-new-write-old case.** The producer is behind the consumer. Requires forward-compatible schema changes (consumers tolerate missing fields).
- **Rolling deploy.** Both directions during the deploy window. Requires full compatibility for the duration.

### 8.5 Contract testing with Pact

Pact (https://pact.io) is the canonical consumer-driven contract-testing tool. Consumers write tests that describe what they expect from the provider; the provider runs the consumer's tests against itself in CI. A contract violation fails the provider's build.

**When it pays off.** Multiple independently-deployed consumers of a single service. Without contract tests, the provider has no signal when a change breaks a consumer; with them, the signal is at build time.

**When it does not.** Single-consumer services or monoliths where integration tests cover the pairs. The ceremony is not free.

The architecture-ready commitment is at the "should we use contract testing" level; stack-ready picks the tool; production-ready wires the CI.

## Section 9. The flow-complete test

At the end of Step 5, walk every critical flow end-to-end on paper. For each arrow in the flow:

### 9.1 Every arrow has a failure mode

What happens if this call fails? Timeout, 5xx, connection reset, DNS failure, TLS handshake failure. Each has a response (retry, fallback, hard fail).

### 9.2 Every arrow has a retry policy

Retry or no? If retry, with what backoff, what budget, what idempotency key? "Retry forever" is not a policy. "Retry with exponential backoff and 30-second jitter for up to 5 attempts, then DLQ" is a policy.

### 9.3 Every arrow has an idempotency decision

Is this mutation idempotent? If yes, how (idempotency key, at-most-once semantics, natural idempotency)? If no, retries are dangerous and must be guarded.

### 9.4 No arrow is an "undecided"

Every arrow in the container diagram (C4 Level 2) has all three answers. An arrow labeled "calls" or "uses" without sync/async, transport, idempotency, and failure mode is decoration, not a decision. See diagrams.md for the arrow-labeling discipline.

### 9.5 The flow-complete test as a Tier 2 gate

Tier 2 of the skill requires integration architecture complete. The flow-complete test is how Tier 2 is evaluated: pick the three most critical user-visible flows (from the PRD), walk them through the container diagram, verify every arrow has all four answers. If any arrow is undecided, the architecture is paper-tiger (RESEARCH-2026-04.md section 2.2) and will collapse on first real load.

End of integration-architecture.md.
