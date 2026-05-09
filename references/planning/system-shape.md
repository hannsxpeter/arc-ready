# System shape: the load-bearing check and the seven shapes catalog

This reference is the expansion of SKILL.md Step 1 (the load-bearing check) and Step 2 (system shape selection). The skill picks exactly one shape, argues it, names its flip points, and writes ADR-001 documenting it. Shape is the most load-bearing decision in the document; every component, every data placement, every trust boundary, every NFR math-check inherits from it.

**Scope owned by this file:** when architecture is and is not load-bearing, the seven canonical shapes with named criteria, the default-modular-monolith rule and its evidence, the three microservices forcing functions, cell-based architecture as the 2024-2026 resilience answer, decision tables for picking between similar shapes, flip points per shape, and the evolutionary path between shapes. Component-level design lives in [component-breakdown.md](component-breakdown.md); data-shape decisions live in [data-architecture.md](data-architecture.md); ADR format lives in [adr-discipline.md](adr-discipline.md).

## Section 1. The load-bearing check

Not every project needs architecture-ready. The skill has a canonical refusal: if architecture is not load-bearing, stop, write a one-page minimal ARCH.md covering system shape ("one service, one database, sync"), data shape (entities, relationships), and trust boundary (who can mutate what), and ship. Do not produce a ten-page architecture document for a single-service CRUD app. That is itself a failure mode, and it is the shape of most AI-generated ARCH.md output.

### 1.1 Architecture is load-bearing if any one of these is true

The six criteria from SKILL.md Step 1, worked:

**(1) More than one persistence layer is in play.** A Postgres is not architecture. Postgres plus S3 plus Redis plus Kafka is architecture. The interface between two persistence layers, the consistency model across them, the failure mode when one is unreachable, and the durability expectation of each are architectural decisions that cannot be deferred.

Worked example: a SaaS app with Postgres for OLTP plus S3 for user file uploads plus Redis for session cache. Three persistence layers. The load-bearing architectural questions: what happens to a write when S3 is down (block, fail open, queue, retry), how are sessions reconstituted on Redis flush, is the upload idempotent on retry. None of these are answered by "we use Postgres."

**(2) More than one deployable service is in play.** Even two is enough. The interface between them is architectural, whether it is a REST call, a queue, or a shared database. Shared database between two deployables is itself a distributed-monolith antipattern that must be either explicitly accepted with rationale or refactored away; see Section 3 and component-breakdown.md Section 7.

Worked example: a web app plus a background worker plus a scheduled cron job. Three deployables sharing one Postgres. The architectural questions: what does the worker read from the same DB that the web app writes, are transactions coordinated, can the worker be offline for 15 minutes without user-visible impact, is the scheduled job idempotent on retry after a missed run. "We use Rails with Sidekiq" does not answer these; the architectural decision is the sync-async split and the idempotency posture.

**(3) A third-party integration is load-bearing in a failure mode.** Stripe, Twilio, a partner API, an internal service the team does not own. The failure mode, retry policy, idempotency discipline, and trust boundary are all architectural. A payment flow that fails silently on a Stripe webhook retry is not a bug; it is a missing architectural decision (idempotency keys, outbox pattern, reconciliation job).

Worked example: a marketplace that charges cards via Stripe, sends SMS via Twilio, and pulls inventory from a partner's REST API hourly. Three external integrations, three different failure postures. Card charge must be exactly-once-visible (Stripe's idempotency-key discipline), SMS can be best-effort (Twilio retries plus dedup window), partner inventory can be stale-tolerant (last-known-good cache with TTL). These are architectural decisions, not implementation details.

**(4) A non-functional target in the PRD constrains the shape.** A p95 latency budget tighter than 200ms for a multi-step operation. A compliance requirement forbidding PII in one component. A data-residency requirement constraining where data is stored. A consistency requirement forbidding eventual consistency in an accounting path. Each of these collapses the space of acceptable shapes.

Worked example: the PRD mandates p99 under 100ms for a search endpoint that spans catalog, inventory, pricing, and personalization. Synchronous fan-out to four services at 50ms each cannot hit the target. The shape must change (precompute the join, cache the personalized view, project inventory asynchronously into the search index) or the target must change. The architectural decision names which.

**(5) The team is larger than two engineers and will grow.** Team Topologies (Skelton and Pais, 2019; RESEARCH-2026-04.md section 3.8) and Conway's Law: communication structure becomes software structure. Architectural boundaries set team boundaries, and team boundaries set architectural boundaries. If the team plans to grow beyond the single-cognitive-load threshold (roughly 5-9 people for one stream-aligned team, per Team Topologies), architecture is load-bearing now because the boundaries you draw today are the team boundaries you live with tomorrow.

Worked example: three founders today, planning to hire ten engineers in twelve months. The architecture written for three founders is the architecture the ten-person team will inherit. If it is a single undifferentiated monolith with no module boundaries, onboarding new engineers will collide on every merge and feature delivery will decelerate around month three post-hire. The modular-monolith shape (Section 2.2, Section 3) is specifically the tool for this case.

**(6) The product will live longer than 12 months and will be maintained by people other than the original authors.** Architecture is for the future team. The document is how the next engineer understands why the system is the shape it is, which decisions are load-bearing, which are reversible, and what would flip each. An architecture document read only by its author has failed its primary purpose.

### 1.2 Architecture is NOT load-bearing if all of these are true

The escape valve. All six must be true; any one being false flips the check back to load-bearing.

- **One engineer, one service, one database.** Solo or pair project. Rails, Django, Phoenix, Laravel, FastAPI monolith. No queue, no event log, no cache that is not incidental.
- **No partner integration with non-trivial failure mode.** Payment-free, webhook-free, third-party-API-free, or integrations so trivial their failure has no business consequence.
- **No compliance constraint.** No HIPAA, PCI, SOC 2, GDPR residency, FedRAMP. The PRD's compliance section is empty or states "none apply."
- **Appetite under 8 weeks.** Short project. Shopify's "majestic monolith" at DHH's twelve-year scale does not apply to an eight-week project; the shape overhead is not earned.
- **No intent to scale the team.** The team of one or two does not plan to hire. The architectural boundaries-set-team-boundaries argument does not apply.
- **No intent to maintain past the initial launch.** One-off script, hackathon project, proof-of-concept, throwaway prototype. The "future team" is no team.

If all six are true, the skill writes a one-page minimal ARCH.md and stops. Typical cases:

- **Single-file CLI.** `gh`, `jq`, a personal productivity tool. One executable, one file, no architecture.
- **One-off script.** A data-migration script, a one-time report generator, a Friday-afternoon scraper. No architecture.
- **Static marketing site.** Next.js-static-export, Hugo, Eleventy, plain HTML. No architecture beyond "which static host." That is stack-ready's job, not architecture-ready's.
- **Toy personal project.** A weekend project to learn a new framework. No team, no users, no maintenance horizon.
- **No-team no-maintenance no-compliance no-partner.** A demo app for a conference talk, a reference implementation for a blog post.

Refusing to produce architecture here is itself a discipline. An AI-generated C4 diagram with three containers, two databases, a Kafka broker, and a service mesh, produced for a single-file CLI, is the canonical shape of the problem this skill exists to solve. The refusal is the feature.

### 1.3 Conversely: when architecture IS load-bearing even for a small team

Some teams assume "we are small, we can skip this" and are wrong. The six criteria in Section 1.1 override team size. Specifically:

**Regulated domains.** A solo founder building a HIPAA-in-scope product has a load-bearing architecture problem on day one. Trust boundaries, audit log shape, PHI segregation, BAA coverage across every managed service: all architectural decisions. Skipping ARCH.md does not skip the problem; it means the architecture gets made by default, accidentally, and the audit finds it later.

**Multi-tenant.** Multi-tenant is an architectural decision even at two tenants. Shared-schema with tenant-column filters, per-tenant schema, per-tenant database, per-tenant deployment: four different shapes with four different cost curves, four different isolation postures, and four different blast radii on a tenancy-boundary breach. The Atlassian April 2022 outage (RESEARCH-2026-04.md section 5.6) is the canonical cost of getting tenant-identifier polymorphism wrong: 775 customers lost production for up to 14 days because a deletion API accepted both site IDs and app IDs. Architecture, not bug.

**Financial systems.** Ledgers, payments, accounting. A monotonic invariant ("debits equal credits") has to be enforced somewhere; where is an architectural decision. A single-database ACID transaction can enforce it; a distributed system needs the outbox pattern or a saga with compensations. Skipping the decision means the invariant is enforced nowhere and the first reconciliation failure is a long night.

**Health and safety systems.** Telemetry from medical devices, dosage calculators, clinical decision support. The PRD NFRs for availability and latency are architectural constraints, and the data-residency and audit requirements are non-negotiable.

**Multi-region.** The PRD says "must serve EU and US customers with data residency in-region." That is an architectural decision. One-app-many-regions, per-region-app, per-region-data-one-app: three shapes, all viable, each with different operational cost. The shape chosen here constrains every downstream decision.

**Partner-facing products.** A product whose primary users are another company's product or employees. The integration contract is a public API, the versioning strategy is architectural, and the blast radius of a breaking change includes the partner's team and revenue. Architecture is the written contract.

The escape valve is narrow. Most real projects that claim to not need architecture do need it; the load-bearing check is the way to be honest about which.

## Section 2. The seven shapes catalog

The seven canonical shapes. SKILL.md Step 2 picks exactly one; this section is the evidence and the criteria behind each.

### 2.1 Single-service monolith

**What it is.** One deployable, one database, synchronous request-response everywhere. The Rails / Django / Phoenix / Laravel / FastAPI shape. The Basecamp / 37signals "majestic monolith" shape (DHH 2016, RESEARCH-2026-04.md section 4.1). One process reads requests, hits one database, returns responses; background work, if any, runs in a separate but co-deployed process pool (Sidekiq, Celery, Oban, RQ) against the same database.

**When it wins.** The default shape for teams of 1-10 engineers building a product that fits in a request-response cognitive model. Cheapest to operate, lowest coordination cost, simplest deployment, simplest debugging, simplest local development. Specific criteria from a PRD that favor this shape:
- Scale ceiling under ~5k requests per second at the 12-month horizon.
- Single bounded context or a few tightly related contexts.
- No independent scale curve per component.
- No regulatory or security boundary requiring physical separation.
- Team under 10 engineers, no growth plan past 20.
- Strong-consistency needs dominate the workload (orders, payments, user data).

**When it loses.** Past the single-cognitive-load team size (10-20 engineers depending on domain complexity), coordination costs dominate and the monolith becomes a bottleneck for independent team cadences. Hits a hard scale ceiling on write-heavy workloads without partitioning (~5-10k write TPS on a single Postgres writer on standard hardware, per Kleppmann, DDIA 1st ed ch. 5; RESEARCH-2026-04.md section 3.10). Cannot serve mixed-availability requirements cleanly (if one part of the app needs 99.99% and another 99.5%, the monolith is pinned to the higher bar).

**Named real-world examples.** Basecamp / HEY (DHH, Rails monolith deployed with Kamal; RESEARCH-2026-04.md section 4.1). Stack Overflow (9 web servers, 1 SQL Server plus hot standby, 2 Redis, 3 tag engine, 3 Elasticsearch; 450 peak req/sec/server at 12% CPU, Nick Craver 2016-2023 architecture posts). Small-to-medium B2B SaaS products from ProfitWell to Plausible Analytics.

**Flip points.** Moves to modular monolith when team grows past 10 engineers and bounded contexts become identifiable. Moves to service-oriented when one bounded context has a genuinely different scale curve (e.g., a reporting subsystem that needs a column store, or a real-time feature that needs a pub/sub shape).

### 2.2 Modular monolith

**What it is.** One deployable, one database, but with internal bounded contexts whose module boundaries are enforced by the compiler, the test suite, or a linting tool. The Shopify shape (2.8M lines of Ruby, 4000+ internal components, enforced by Packwerk; RESEARCH-2026-04.md section 4.1). The current GitHub shape (Rails monolith since 2008 with a small number of extracted services). The Stack Overflow shape (informally modular inside the monolith, well-defined team ownership).

The discipline that distinguishes a modular monolith from a regular monolith is the enforcement. Without enforcement, the modular monolith degrades into a regular monolith with wishful thinking. Tools:
- **Packwerk (Ruby, Shopify open source):** static dependency enforcement for Ruby codebases; RESEARCH-2026-04.md sections 4.1, 8.2.
- **ArchUnit (Java/Kotlin):** JUnit-test-shaped rules for package dependencies, layer direction, naming. RESEARCH-2026-04.md section 8.2.
- **NetArchTest (.NET):** analog for C#.
- **dependency-cruiser (JS/TS):** import-rule enforcement and cycle detection; GitLab production use.
- **Custom Python checks:** `archlint`, or bespoke AST-walking scripts; less mature tooling but viable.

**When it wins.** The sweet spot for teams of 3-30 engineers with clear bounded contexts but no operational maturity for distributed systems. The shape the industry has been re-learning since 2018 (ThoughtWorks Tech Radar held microservices at "Trial" not "Adopt" since 2018; RESEARCH-2026-04.md section 4.7). Specific criteria:
- Team size 3-30, with bounded contexts identifiable but not requiring independent deploys.
- Scale ceiling under what a single well-partitioned Postgres plus vertical scaling can serve (~10k-50k TPS depending on workload shape).
- Domain complexity sufficient to benefit from explicit module boundaries (ordering vs. billing vs. identity vs. inventory).
- No compliance constraint forcing physical separation (if HIPAA requires PHI-bearing components isolated at the process level, the modular monolith is not enough; see Section 2.3 or 2.4).

**When it loses.** Above 30-50 engineers, the single-deployable constraint creates a deployment-contention bottleneck even with module boundaries (everyone merges to the same main branch, every deploy includes everyone's changes). At that scale, selective service extraction (Section 2.3) or cell-based (Section 5) starts to earn its operational cost.

**Named real-world examples.** Shopify (2.8M Ruby lines, 4000+ packwerk-enforced components, 30TB/min BFCM peak; RESEARCH-2026-04.md section 4.1). GitHub (Rails monolith since 2008 with narrow service extractions). Modern Basecamp, HEY, and the Campfire revival. Many mid-size B2B SaaS products (Intercom's core app through much of its history).

**Flip points.** Deploys to service-oriented when a single bounded context develops a genuinely different scale curve or team ownership that demands independent deploys. Deploys to cell-based when the availability requirement demands blast-radius limits that a single shared deployable cannot provide.

### 2.3 Service-oriented (SOA, coarse-grained services)

**What it is.** A handful of deployables (3-7), each owning a bounded context with its own database. Synchronous request-response between services, often with some async events for audit and for fan-out. The Amazon-pre-2006-microservices-memo shape (before Bezos's two-pizza-team and "service interface mandate"). The modern retrenchment shape that Segment reported in 2018 (consolidated fine-grained microservices to a handful of coarse services; widely cited).

**When it wins.** Team size 15-50, two to five bounded contexts with genuinely different scale or availability curves. Specific criteria from PRD:
- Two or more bounded contexts with independent deploy cadences (the mobile team ships twice a day, the billing team ships twice a month, and they cannot be on the same deploy cycle).
- One or more bounded contexts with a different scale curve (an analytics pipeline that processes 10x the traffic of the core app).
- A regulatory boundary that forces physical separation of one subsystem (a PCI-in-scope payments surface separated from the rest).
- Enough operational maturity to run 3-7 services without drowning in coordination overhead.

**When it loses.** Below 15 engineers, the coordination tax on a 3-7-service architecture exceeds the monolith's scale-ceiling tax. Above 50 engineers, the coarse-grained services often need to split further, and the choice between service-oriented and microservices becomes a forcing-function question (Section 4).

**Named real-world examples.** Amazon through 2002-2006 (before the microservices era, before the famous Bezos memo). Segment post-2018 consolidation. Many mid-large B2B SaaS products; the pattern is under-blogged because it is the boring middle between "monolith" and "microservices" and boring patterns get fewer conference talks.

**Flip points.** Deploys to microservices when team size forces further decomposition (50+ engineers, Team-Topologies stream-aligned-team count rising past 5-6 teams). Deploys back to modular monolith when the services reveal themselves to be a distributed monolith (Section 2.4 anti-pattern; component-breakdown.md Section 7).

### 2.4 Microservices (fine-grained services)

**What it is.** Many deployables (20+), each with its own database, each owned by a small team, orchestrated by a service mesh or API gateway. Conway's-Law-driven: services correspond to teams. The Amazon-post-Bezos-memo shape. The Netflix-post-2009 shape. The Uber-at-peak-complexity shape (2016-2019 era).

**When it wins.** Team size above the Team-Topologies threshold (Skelton and Pais put the threshold around 50-100 engineers for the coordination math to favor microservices; RESEARCH-2026-04.md section 3.8; real-world examples below 20 engineers almost always regret it). Specific criteria, all three of which should be met, not just one:
- Team size 50+, with multiple stream-aligned teams each needing independent deploy cadence.
- Genuinely different scale curves per service, and the cost of running each service at its own scale exceeds the cost of coordination.
- Operational maturity to run 20+ services: observability, tracing, service discovery, CI/CD per service, incident response across services.

**When it loses.** Below 20 engineers, almost always. The coordination tax, the distributed-systems debug tax, the version-skew tax, the cross-service transaction tax, the observability tax: each is payable, none is small. "Microservices for scale" without one of the three forcing functions above (Section 4) is the cargo-cult failure mode (Korokithakis 2015; RESEARCH-2026-04.md sections 1.1, 1.2).

**Named real-world examples.** Netflix (the reference architecture of the 2010s, documented extensively; 500+ services at scale). Amazon (thousands of services internal, famously "everything is a service"; the 2002 Bezos memo). Uber (peaked at 2200+ services around 2018, later consolidated). The canonical walkback: Amazon Prime Video's audio-video monitoring service (March 2023, Marcin Kolny post; RESEARCH-2026-04.md section 4.1). **Accurate citation discipline:** this was one internal team within Amazon, working on one specific monitoring pipeline, consolidating a specific distributed-AWS-Step-Functions-plus-Lambda pipeline into a single service and reducing costs by 90%. It was not "Amazon abandoned microservices" (Amazon remains a service-oriented organization at the corporate level). The post is widely mis-cited; read the primary source before citing. Istio consolidated its control-plane microservices back to a single binary in 2020 (a genuine architectural retreat for that product).

**Flip points.** Retreats to service-oriented or modular monolith when team consolidates or when the coordination cost is no longer justified by the scale curve. This is what "monolith-to-microservices" inverted: the 2020-2026 trajectory includes many public walkbacks. Not every microservices implementation is wrong, but the default-to-microservices of 2014-2019 has not aged well.

### 2.5 Serverless / function-as-a-service

**What it is.** Functions over a managed runtime (AWS Lambda, Cloudflare Workers, Vercel Functions, Google Cloud Functions, Azure Functions), with an external datastore. No server provisioning; compute is billed per invocation. Strong for event-driven and sparsely-triggered workloads.

**When it wins.** Bursty, event-driven, stateless workloads. Specific criteria:
- Workload is event-triggered (webhook, S3 upload, queue message, scheduled cron) rather than sustained HTTP traffic.
- Per-invocation compute is short (Lambda's 15-minute limit; Workers' 10ms CPU time per request on free tier, higher on paid).
- Stateless or state-externalized (state in DynamoDB, Postgres, Redis, not in the function's memory).
- Low-to-moderate traffic where the pay-per-invocation cost is lower than a continuously-running container.
- Ops team wants zero server management and accepts vendor lock-in.

**When it loses.** Long-running workflows (15-minute Lambda limit; the Prime Video case above was partly about this). Sustained-load APIs above a certain request rate, where Lambda's per-invocation cost crosses over a container's cost (cost-crossover point is workload-dependent; Mikhail Shilkov's cold-start benchmarks track this). Workloads with large in-memory state (ML inference, real-time graph traversal, in-memory caches). Low-traffic APIs with p99 latency budgets (cold start adds 100-500ms at the low-traffic tail; AWS Lambda cold-start guidance 2024, RESEARCH-2026-04.md section 4.2). WebSockets and stateful protocols (better on containers or on platforms with explicit WebSocket support like Cloudflare Durable Objects).

**Named real-world examples.** A substantial fraction of all AWS workloads under Lambda's 10-billion-requests-a-day bar. Image resizing pipelines (S3 trigger to Lambda to resize). Webhook handlers for Stripe, Twilio, Slack. Scheduled jobs. Auth hooks (Clerk, Auth0 custom actions). CI/CD runners.

**Flip points.** Crosses over to containers when sustained load makes per-invocation pricing worse than per-hour pricing. Crosses over to edge (Section 2.7) when the workload is read-heavy global and cold-start latency matters. Retreats to a traditional monolith when the function graph becomes a distributed monolith (the Prime Video case: many small Lambdas coordinating was more expensive than one container doing the same work).

### 2.6 Event-driven

**What it is.** The system's primary integration shape is asynchronous events on a log (Kafka, Kinesis, Redpanda, RabbitMQ Streams, NATS JetStream) or a queue (SQS, Cloud Pub/Sub, RabbitMQ classic). Components publish events; other components consume them; the log or queue is the integration surface. Strong for audit, replay, and fan-out.

CQRS (separate read and write models) is optional in an event-driven architecture; event sourcing (the event log is the source of truth, state is a projection) is a further step beyond that. Both are separable decisions.

**When it wins.** Integration-heavy systems where multiple consumers need the same event, audit is load-bearing, replay is a product capability, or eventual consistency is acceptable. Specific criteria:
- Multiple consumers for each business event (order-placed fans out to fulfillment, billing, analytics, notifications).
- Regulatory or product need for complete audit with replay (financial systems, healthcare, legal).
- High-throughput write paths where the consumer can be decoupled from the producer's latency budget.
- Operational maturity to run Kafka or equivalent (Confluent Cloud and Amazon MSK have reduced the operational cost, but the discipline is still non-trivial).

**When it loses.** Simple CRUD systems (the event-driven overhead earns nothing). Systems where strong immediate consistency is required across the event (financial ledgers where "the write is not real until all consumers have acknowledged" have no clean event-driven shape; they are sync or they are wrong). Small teams without the operational muscle to run the event log.

The cargo-cult version, widely seen in 2018-2024 AI-generated architecture: "we use Kafka for event-driven architecture" where the PRD describes a 100-event-per-day system with two consumers. Kafka for that shape is cargo-cult (RESEARCH-2026-04.md section 1.2). RabbitMQ or even Postgres-as-a-queue via `LISTEN/NOTIFY` is the right shape.

**Named real-world examples.** LinkedIn (Kafka was created here, 2011, for this shape). Netflix's integration layer. Large retailers at BFCM scale. Modern banking systems (Monzo, Nubank). Stripe internally at the ledger level. Uber's core event platform.

**Flip points.** Retreats to sync request-response when the event-log complexity is not earned. Event sourcing specifically has a retreat pattern: "we adopted event sourcing and regret it" posts are common (Chris Kiehl, "Don't Let the Internet Dupe You, Event Sourcing is Hard"; Oliver Butzki, "Why Event Sourcing is a microservice communication antipattern"; RESEARCH-2026-04.md section 4.5). A history table in a relational DB gets 80% of the audit-log value at 10% of the cost, and is the right shape for most teams that think they need event sourcing.

### 2.7 Edge-native

**What it is.** Compute at the edge (Cloudflare Workers, Deno Deploy, Vercel Edge Functions, Netlify Edge Functions), data replicated to the edge or held in edge-friendly stores (Cloudflare D1, Turso, Cloudflare Durable Objects, Vercel KV). Strong for global-low-latency read-heavy workloads.

V8-isolate-based runtimes (Workers, Vercel Edge) have near-zero cold start and deploy globally in seconds. Node.js compatibility has improved in 2024-2026 (Workers supports Node.js APIs via compatibility layer; Deno 2 supports npm).

**When it wins.** Geographically sensitive low-latency static-plus-a-bit-of-logic workloads. Specific criteria:
- Global user base with latency-sensitive reads.
- Workload is read-heavy relative to writes.
- Compute per request is small (10ms CPU time on Workers free, 50ms on paid; similar on Vercel, higher on Deno Deploy).
- Data can be replicated to the edge (CDN-cached, or edge-replicated DBs like D1 and Turso).
- No strong-consistency write requirement across regions (Durable Objects are a partial answer but single-home).

**When it loses.** Write-heavy workloads. Strong-consistency-across-regions workloads. CPU-heavy workloads. Workloads that need substantial in-memory state. Workloads that require a specific runtime (Python-only ML inference, Java, Go). The edge pattern is genuine but narrow; it is not a universal upgrade from centralized cloud.

**Named real-world examples.** Cloudflare's own infrastructure. Discord's voice routing layer. Shopify's edge-cached storefront. Many modern marketing sites (Vercel Edge for Next.js static-plus-personalization). Linear's edge auth check.

**Flip points.** Retreats to traditional cloud when write consistency or CPU demands exceed edge capabilities. Combines with traditional cloud (edge for reads and auth, central cloud for writes) in hybrid architectures; the pure-edge shape is rarer than the edge-plus-origin shape.

## Section 3. The default-modular-monolith rule and why

The industry lesson of 2018-2026, compressed: **default to a modular monolith unless a specific constraint rules it out.** Every other shape must justify itself against this default.

### 3.1 The evidence

**ThoughtWorks Technology Radar has held microservices at "Trial" not "Adopt" since 2018.** Vol 19 (May 2018) first placed microservices out of the Adopt ring with explicit guidance: do not adopt for scale you do not have; the organizational maturity required is non-trivial (InfoQ, "Microservices to Not Reach Adopt Ring in ThoughtWorks Technology Radar," 2018; RESEARCH-2026-04.md section 4.7). The position has been maintained across subsequent radar volumes through 2026.

**Martin Fowler's "MonolithFirst" (2015)** makes the case: build the monolith first, extract services only when the bounded contexts are well-enough understood that the extraction lines are obvious. Attempting to design microservices from scratch without the domain knowledge the monolith would have given you produces the distributed-monolith antipattern (RESEARCH-2026-04.md section 1.1, citing Fowler https://martinfowler.com/bliki/MonolithFirst.html).

**Sam Newman's "Monolith to Microservices" (O'Reilly, 2019)** codifies the migration pattern. Chapter 1 explicitly argues that teams should not start with microservices; the book is about the incremental extraction, using the Strangler Fig pattern (Fowler), which requires a working monolith as the starting point. RESEARCH-2026-04.md section 1.1.

**Shopify has open-sourced Packwerk** (https://github.com/Shopify/packwerk) specifically to enforce module boundaries in a 2.8M-line Ruby monolith spanning 4000+ components. The Shopify engineering blog's "Deconstructing the Monolith" (2019) and "Under Deconstruction: The State of Shopify's Monolith" (2024) are the reference writeups. At BFCM 2025 the monolith handled 30TB per minute of traffic. This is the existence proof: modular monoliths operate at internet scale.

**The 2020-2026 consolidation trend.** Segment consolidated fine-grained microservices to a handful of coarse services in 2018. Istio merged its control-plane microservices back to a single binary in 2020. Amazon Prime Video's audio-video monitoring team consolidated a specific distributed pipeline to a single service in March 2023 with a 90% cost reduction (again: one team, one pipeline, not "Amazon abandoned microservices"; RESEARCH-2026-04.md section 4.1). The pattern is widespread enough that "monolith-to-microservices" posts are outnumbered by "microservices-to-monolith" posts in the current blogosphere.

### 3.2 Why this is the right default

**Coordination cost is real.** A distributed system pays in ops, observability, testing, and cognitive load. The pay is worth it when the forcing function is present (Section 4); it is not worth it otherwise.

**Boundaries are easier to draw in hindsight than in advance.** Starting with a modular monolith and extracting services when the bounded contexts are well-understood produces better boundaries than drawing them on day one based on a PRD's guess at what the contexts will be.

**Reversibility favors the modular monolith.** Extracting a service from a modular monolith with enforced module boundaries is a bounded project (weeks to months). Merging microservices back into a modular monolith is a much larger project (months to quarters). The asymmetry favors starting at the lower-cost shape.

**Team sizes below ~30 engineers do not earn the microservices overhead** in the Team-Topologies math (RESEARCH-2026-04.md section 3.8). Most teams never cross that threshold. The monolith is right for them for the life of the product.

### 3.3 The enforcement discipline

A modular monolith without enforcement degrades into a regular monolith within six months of the ADR being written. The fitness function (RESEARCH-2026-04.md section 8) is the mechanism. See SKILL.md Step 10 and the tools list in Section 2.2 of this file. Specifically:

- **If Ruby: Packwerk, in CI, failing the build on boundary violations.**
- **If Java/Kotlin: ArchUnit, as a JUnit test suite, in CI.**
- **If .NET: NetArchTest, as unit tests, in CI.**
- **If JS/TS: dependency-cruiser, configured in CI, failing the build on cycles and disallowed imports.**
- **If Python: archlint or bespoke AST checks; less mature, more effort.**

An architecture that declares "modular monolith" without naming the enforcement mechanism has not made a decision; it has made a wish. The ADR must name the tool and the CI integration.

## Section 4. The three microservices forcing functions

Microservices are a cost. The cost is worth paying when a forcing function is present. Three forcing functions are canonically accepted; absent one, microservices are cargo-cult.

### 4.1 Team size requires independent deploy cadences

**The rule.** Multiple stream-aligned teams (Team Topologies) each own a bounded context, and each needs to deploy independently of the others. The coordination cost of a shared deployable (everyone merges to main, every deploy includes everyone's changes, every deploy is a shared blast radius) exceeds the coordination cost of independent services.

**The threshold.** Team Topologies puts the Conway's-Law-driven crossover somewhere around 50-100 engineers, when teams can no longer fit into a single "single cognitive load" scope (RESEARCH-2026-04.md section 3.8). Real-world examples below 20 engineers almost always regret microservices; the coordination tax exceeds the deploy-cadence benefit.

**Example.** Shopify has 4000+ modules in its monolith, not 4000 services. The deploy cadence is coordinated at the platform level; independence comes from module boundaries, not deployable boundaries. Amazon famously went to microservices when Bezos mandated "every team exposes its data through a service interface" (2002), but Amazon at that time had already crossed the forcing-function threshold by team size.

### 4.2 Services have genuinely different scale or availability curves

**The rule.** One bounded context processes 10x the traffic of another, or one bounded context requires 99.99% availability while another can tolerate 99.5%, and the cost of scaling or protecting the whole monolith at the higher bar exceeds the cost of running them as separate services.

**Example.** An e-commerce platform where the storefront (read-heavy, latency-critical, 99.99% SLA) and the admin dashboard (write-heavy, internal, 99.5% SLA) genuinely have different curves. Separating them lets each be sized and protected independently.

**The anti-pattern.** Claiming different scale curves without the numbers. "The analytics service needs to scale independently" requires a number: at 12 months, how many events per second will analytics process, and how does that compare to the rest of the system. If the answer is "I don't know," the forcing function is not present; the default modular monolith remains.

### 4.3 Regulatory or security boundaries require physical separation

**The rule.** A compliance regime (PCI, HIPAA, FedRAMP) requires that a specific subsystem be physically isolated from the rest, in a separately deployed process, with distinct credentials, distinct network boundaries, and distinct audit trails. A shared binary cannot satisfy the requirement; a shared database in most cases cannot either.

**Example.** A SaaS that handles payment card data. PCI-DSS requires that card-data-handling components are in PCI scope, with stricter audit, access controls, and network segmentation. Separating the card-handling component as its own service, with its own database in a PCI-compliant region, with its own deploy pipeline, narrows PCI scope and reduces audit cost. This is a real forcing function.

**Not a forcing function:** "we want to be able to switch the database later." That is a stack-ready concern, not an architectural one, and the answer is an ORM abstraction, not a service boundary.

### 4.4 If none of the three are present

Do not adopt microservices. Every architectural decision past this point should justify itself against the default modular monolith. If the justification is "industry best practice," the ADR is cargo-cult and must be rewritten or the shape changed. If the justification is "we might grow someday," the ADR is speculative and must be rewritten against concrete 12-month growth numbers or the shape changed. If the justification is "Netflix uses microservices," the ADR is resume-driven (RESEARCH-2026-04.md sections 1.5, 2.5) and must be rewritten or the shape changed.

## Section 5. Cell-based architecture

Cell-based architecture is the 2024-2026 resilience answer. It is NOT microservices, and it is NOT a monolith. It is a partitioning pattern: take the whole system (monolith, modular monolith, or service-oriented) and replicate it as independent cells, each serving a partition of customers or traffic. Failures, deploys, and blast radius scope to one cell.

### 5.1 What it is

**A cell is a complete, independent replica of the system, serving a partition.** Cells are isolated from each other at the deployment, network, and data layers. A deploy bug, a noisy-neighbor customer, or a cascading failure in one cell does not affect the others. Cells can be monoliths, modular monoliths, or service-oriented; the cell shape is orthogonal to the internal architecture of the cell.

Partitioning key can be customer ID, tenant ID, region, business unit, or traffic shard. Routing from the edge (DNS, API gateway, edge router) determines which cell serves which request.

### 5.2 Canonical references

- **AWS Well-Architected, "Reducing the Scope of Impact with Cell-Based Architecture"** (https://docs.aws.amazon.com/wellarchitected/latest/reducing-scope-of-impact-with-cell-based-architecture/). The canonical writeup. RESEARCH-2026-04.md section 4.6.
- **AWS re:Invent 2024 ARC312** ("Using cell-based architectures for resilient design on AWS") and **ARC335** ("Learn to create a robust, easy-to-scale architecture with cells"). RESEARCH-2026-04.md section 4.6.
- **Slack's cellularization** (documented in Slack engineering blog posts 2022-2024). Moved from a single-region shared deployment to a cell-per-customer-cluster model after the multi-hour outages of 2022.
- **Roblox's post-October-2021 re-architecture** (Roblox postmortem, RESEARCH-2026-04.md section 5.7). The 73-hour outage was directly attributable to a shared service-discovery SPOF; the retrofit includes cell-based isolation for blast-radius reduction.

### 5.3 When it wins

- Availability requirement that cannot tolerate a global outage. A single shared system has a maximum availability roughly equal to its weakest shared component; cells trade that for partition-level availability.
- Multi-tenant system where the blast radius of a noisy neighbor, a security incident, or a deployment bug should be limited to one tenant cohort.
- Scale beyond what a single deployment can serve, where the workload partitions cleanly.

### 5.4 When it loses

- Small systems. The operational cost of running N cells instead of one is N-shaped; it is not worth it below a high customer count and a high-availability requirement.
- Workloads that cannot partition cleanly (e.g., a social network where any user can interact with any other user; cells need cross-cell routing that erodes the isolation benefit).

### 5.5 The 2024-2026 trend

InfoQ Architecture Trends 2024 and 2025 report list cell-based architecture in the "early majority" stage (RESEARCH-2026-04.md section 4.6). Teams moving from "monolith with regional replicas" to "monolith-per-cell with deployment isolation" are now common in the resilience-sensitive tier (banking, healthcare, large SaaS).

Note: cells are not regions. Cells are internal partitions within a region (typically). Regional replicas are a separate concern (disaster recovery, latency). A mature architecture can have cells within regions and regions above cells. This is the shape most high-availability AWS customers are adopting.

## Section 6. How to pick between similar shapes

Decision tables for the ambiguous cases. The PRD NFR grounding is what breaks the tie in each.

### 6.1 Modular monolith vs. service-oriented vs. microservices

| Dimension | Modular monolith | Service-oriented (3-7) | Microservices (20+) |
|---|---|---|---|
| Team size | 3-30 engineers | 15-50 engineers | 50+ engineers |
| Deploy cadence | One pipeline, coordinated | 3-7 pipelines, coordinated at platform | 20+ pipelines, independent |
| Ops complexity | Single deployable; standard Rails/Django/etc. ops | Per-service CI/CD; shared observability | Service mesh, distributed tracing, per-service SRE |
| Scale curve | Single curve | 3-7 curves, each sized independently | Many curves |
| Coordination cost | Low | Moderate | High |
| Debug complexity | Single process, single DB | Cross-service for integration bugs | Cross-service for every bug |
| Failure isolation | None (shared process) | Some (per-service process) | High (per-service process, sometimes per-service network) |
| Right default for | PRDs with unified scale curve, small-to-mid team | PRDs with 2-5 bounded contexts that actually have different scale or team ownership | PRDs with 5+ stream-aligned teams and genuinely independent scale curves |

**The tie-breaker.** If you are oscillating between modular monolith and service-oriented, pick modular monolith and extract later when the boundaries are proven. If you are oscillating between service-oriented and microservices, pick service-oriented and split later when the team size and scale demand it.

### 6.2 Event-driven vs. synchronous service-oriented

| Dimension | Event-driven | Sync service-oriented |
|---|---|---|
| Primary integration | Async events on a log or queue | Request-response |
| Consumer count per event | Many (fan-out) | Usually one |
| Audit/replay | Native (the log is the audit) | Requires separate audit shape |
| Consistency | Eventual | Immediate (within the sync chain) |
| Debug complexity | Time-decoupled; harder to reason about | Stack-trace-shaped; easier |
| Back-pressure | Built into the queue/log | Must be designed in |
| Right for | Fan-out, audit, replay, high-throughput decoupled writes | Simple CRUD, tight coupling, immediate consistency |

**The tie-breaker.** Ask whether a given event has zero or one consumers, or many. Zero or one: sync wins. Many: async wins. If the answer changes over the product's horizon, pick the shape that matches the 12-month state.

### 6.3 Serverless vs. containers

| Dimension | Serverless | Containers |
|---|---|---|
| Pricing | Per-invocation | Per-hour |
| Cold start | 100ms-5s (provider-dependent) | None after warm |
| Workload shape | Bursty, event-triggered, short | Sustained, long-running |
| State | Externalized | In-process or externalized |
| Ops | Near-zero | Standard container ops |
| Runtime flexibility | Constrained to provider runtimes | Any runtime |
| Scale to zero | Yes | Only with serverless-container hybrid (Knative, Fly Machines, AWS Fargate Spot) |
| Right for | Webhooks, scheduled jobs, image processing, auth hooks | Sustained APIs, stateful apps, ML inference, anything long-running |

**The tie-breaker.** Compute the monthly cost at 12-month traffic. If serverless is cheaper and the workload shape fits, use serverless. If containers are cheaper and the ops cost is affordable, use containers. If the workload is mixed (some webhooks, some sustained API), run a hybrid; do not pretend one shape fits both.

### 6.4 Edge-native vs. traditional cloud

| Dimension | Edge-native | Traditional cloud |
|---|---|---|
| Cold start | ~0 (V8 isolates) to low (Deno Deploy) | Standard (warm) or high (cold) |
| Geographic latency | Low globally | Low regionally, high globally |
| CPU per request | Constrained (10-50ms typical) | Unconstrained |
| Memory per request | Constrained (128MB typical) | Unconstrained |
| Runtime | JavaScript/TypeScript, WASM, some others | Anything |
| Data store | Edge-replicated (D1, Turso, Durable Objects) or origin-hit | Any |
| Right for | Auth checks, redirects, personalization, CDN logic, light API proxies | Main app logic, CPU-heavy work, database-bound work |

**The tie-breaker.** If users are globally distributed and latency sensitivity is high, start edge. If users are regional or CPU demands are high, stay on traditional cloud. The hybrid "edge for reads, origin for writes" is the common real-world shape.

## Section 7. The shape flip points

Every shape has a ceiling. Name the ceiling concretely so the team knows when to rearchitect. Vague answers ("when we need to scale") are not ceilings.

### 7.1 Single-service monolith

- **Write TPS ceiling on single-writer Postgres:** ~5-10k write TPS on standard cloud hardware (e.g., db.r6g.8xlarge) without partitioning. Read replicas help reads, not writes. Past this, partitioning, read/write splitting at the app layer, or Citus/Aurora-Limitless-style distributed Postgres become necessary. (Kleppmann DDIA ch. 5 on partitioning; RESEARCH-2026-04.md section 3.10.)
- **Team size coordination ceiling:** 10-20 engineers. Past this, merge conflicts, deploy-contention, and onboarding load dominate.
- **Cognitive complexity ceiling:** when a new engineer cannot hold the bounded contexts in their head on day one.

### 7.2 Modular monolith

- **Team size coordination ceiling:** 30-50 engineers, when even module-boundary enforcement cannot hide the single-pipeline deploy contention.
- **Scale ceiling:** same single-writer Postgres ceiling as the monolith. Modular monolith does not magically scale past the monolith's data ceiling.
- **Module-boundary enforcement decay:** if the fitness function is not in CI, the modular monolith degrades to a regular monolith in 6-12 months. The enforcement IS the ceiling-protector.

### 7.3 Service-oriented

- **Team size ceiling (upper):** 50-100 engineers, when the number of stream-aligned teams exceeds what 3-7 services can own cleanly.
- **Service count ceiling:** past 7-10 services, the coordination cost approaches microservices cost without the microservices benefits. Split further into microservices or consolidate back.
- **Distributed monolith ceiling:** if the 3-7 services share a database, call each other synchronously for every user request, and cannot deploy independently, the architecture has collapsed into a distributed monolith. The ceiling was hit earlier than expected.

### 7.4 Microservices

- **Service count and ops-maturity ceiling:** microservices below 20 engineers almost always regret it (coordination tax exceeds benefit). Above 20 but below the Team-Topologies threshold (50-100), results are mixed. Above that, the shape can be right if the other forcing functions are present.
- **Observability ceiling:** without distributed tracing, structured logging with correlation IDs, and per-service SLOs, debugging microservices at scale becomes untenable. The observability cost is a multi-quarter investment and is a prerequisite, not an afterthought.

### 7.5 Serverless

- **Cold-start wall at low-traffic p99:** 100-500ms added at the p99 for Lambda Node/Python (AWS Lambda cold-start docs 2024; Mikhail Shilkov benchmarks). Provisioned concurrency mitigates this at the cost of per-hour pricing. Cloudflare Workers V8 isolates have near-zero cold start and do not hit this wall.
- **15-minute function timeout.** Workloads longer than this must be split or moved off serverless.
- **Cost crossover point:** when sustained load makes per-invocation pricing worse than per-hour pricing. Workload-dependent; commonly in the mid-thousands-of-requests-per-second range for Lambda, lower for Vercel Functions.
- **Vendor-lock-in ceiling:** the Lambda-specific, Vercel-specific, or Workers-specific features the system depends on become an exit cost proportional to the depth of adoption.

### 7.6 Event-driven

- **Operational ceiling:** Kafka at scale is a full-time job for at least one SRE, even on Confluent Cloud or MSK. Below a certain team size, RabbitMQ or SQS-equivalent is the right shape; Kafka is the wrong shape.
- **Consumer complexity ceiling:** as the number of consumers per event grows, the contract management between producer and consumer becomes load-bearing. Schema registries (Confluent Schema Registry, AWS Glue Schema Registry), consumer-driven contracts, and versioning strategies are required.
- **Event-sourcing-as-architecture ceiling:** event sourcing for specific bounded contexts (ledgers, audit) often works; event sourcing as a whole-system architecture is itself an antipattern (RESEARCH-2026-04.md section 4.5). The ceiling is hit fast.

### 7.7 Edge-native

- **CPU and memory per request:** 10-50ms CPU and ~128MB memory is typical. Heavier workloads fall through to the origin.
- **Write consistency across regions:** edge data stores (D1, Turso) typically have a single writer region with replicas for reads. Global-strong-consistency writes are not an edge-native workload.
- **Runtime ceiling:** JavaScript/TypeScript plus a growing WASM ecosystem is the runtime surface. Python, Java, Go at the edge exist (some platforms) but are narrower.

## Section 8. Shape-change evolutionary path

Every arrow is reversible. Scrolling back is allowed. The path is:

```
single-service monolith -> modular monolith -> service-oriented (selective extraction) -> microservices or cell-based
```

And in reverse:

```
microservices -> service-oriented (consolidation) -> modular monolith -> monolith
```

Most real systems move forward one step at a time, sometimes pausing at each for years. Some systems never leave the modular monolith; that is a success state, not a failure.

### 8.1 The Strangler Fig pattern

The canonical forward migration is the **Strangler Fig pattern** (Martin Fowler, 2004, https://martinfowler.com/bliki/StranglerFigApplication.html; referenced in Sam Newman's "Monolith to Microservices," 2019, RESEARCH-2026-04.md section 1.1). The monolith continues to run; new functionality is built in services; existing functionality is gradually extracted; eventually the monolith is strangled by the growing external services. The pattern requires:

- A clear seam where the extraction can happen (usually a bounded context).
- A proxy or gateway that can route traffic to either the monolith or the new service during the transition.
- Fitness functions that detect when the boundary is crossed (dependency checks that fail the build if the monolith still references the extracted module).
- A rollback plan if the extraction misbehaves.

The anti-pattern version: starting to extract a service without a clear bounded context, without routing infrastructure, and without fitness functions. The extraction stalls, the service ends up sharing the database with the monolith, and the result is a distributed monolith worse than the starting state.

### 8.2 The reverse migration

Retreating from microservices to service-oriented, or from service-oriented to modular monolith, is often called "consolidation" and is less well-documented than the forward migration but increasingly common (Section 2.4, Section 3.1). The pattern is:

- Identify the services that should not have been split. Criteria: they deploy together, they share a database, they call each other synchronously on every user request, they have no independent scale curve.
- Merge them into a single deployable with internal module boundaries (modular monolith shape).
- Keep the external API contract stable during the merge.
- Remove the inter-service network hop and replace it with an in-process call.
- Measure the reduction in latency, cost, and complexity.

The Prime Video 2023 post is the canonical writeup (RESEARCH-2026-04.md section 4.1); Segment's 2018 post is the earlier reference.

### 8.3 The rule: reversibility is a feature

Every shape transition should be designed as reversible. The Strangler Fig pattern is reversible (the monolith continues running until the service proves itself). Consolidation is reversible (the services can be re-extracted if the consolidation creates a new bottleneck). Cells can be added or subtracted. Edge can be added above origin without removing origin.

An architecture that makes a shape transition irreversible (for example, by deleting the old service's code before the new one is proven, or by dropping the monolith's database before the service's database is trusted) has introduced a risk the PRD did not require. The ADR for a shape transition should name its reversibility plan; if there is no reversibility plan, the ADR is incomplete.

### 8.4 Relation to the evolutionary-architecture discipline

Evolutionary architecture (Ford, Parsons, Kua, Sadalage; RESEARCH-2026-04.md section 3.2) is the broader framework for this: the architecture is not a static artifact but a continuously-evolving structure whose intended properties are enforced by fitness functions. Shape transitions are planned, guarded by fitness functions, and reversible. The shape is never "final"; it is current, and it is expected to change as the product, team, and constraints change.

The canonical pillars from the 2023 second edition: **fitness functions**, **incremental change**, **appropriate coupling**. The shape catalog in this file is the "appropriate coupling" dimension; the flip points in Section 7 are the triggers for "incremental change"; the enforcement tools in Section 2.2 are the "fitness functions." See SKILL.md Step 10 and [evolutionary-architecture.md](evolutionary-architecture.md) for the full treatment.

---

The shape decision is load-bearing. Write ADR-001 with the shape named, the PRD NFRs it satisfies, the alternatives rejected with reasons, the flip point that would force a change, and the blast radius if wrong. Keep it to two pages. See [adr-discipline.md](adr-discipline.md). The component breakdown within the shape is the next decision; see [component-breakdown.md](component-breakdown.md).
