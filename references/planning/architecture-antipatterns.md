# Architecture Antipatterns

Catalog file. Loaded on demand during Mode C audits and at tier-gate checks. Referenced by SKILL.md's have-nots list, Step 1.5 theater audit, and Step 8 ADR discipline.

Antipatterns compile into four rough tiers: document-level (the ARCH.md itself decides nothing), shape-level (the system shape is wrong for the constraints), data-level (the storage / ownership / transaction decisions are wrong), and integration-level (the inter-component communication is wrong). Below each tier, trust-boundary antipatterns, diagram antipatterns, ADR antipatterns, and evolutionary antipatterns have their own sections. Section 10 applies the substitution test end-to-end to a worked example; Section 11 catalogs historical antipatterns still worth knowing.

## 1. How to read this file

Each antipattern entry has six fields:

1. **Canonical name,** with coiner / first source if known.
2. **Definition** in one paragraph.
3. **Symptoms** visible in the ARCH.md, the codebase, or the running system.
4. **Smell test,** a question that exposes the antipattern.
5. **Fix,** what to write or rewrite.
6. **Citation,** pointer to RESEARCH-2026-04.md section or external source.

The catalog is not exhaustive; it is the set the skill refuses at tier gates. When in doubt, apply the substitution test (Section 10): substitute a near-equivalent for the component, tool, or claim; if the rationale still reads plausibly, the rationale decided nothing.

## 2. Document-level antipatterns

Antipatterns of the architecture artifact itself. The document renders, fills sections, and decides nothing.

### Architecture theater

**Coined here** (adopted from widespread informal use; no canonical prior art in architecture literature, adjacent to "security theater" from Bruce Schneier 2003). See RESEARCH-2026-04.md section 2.1.

**Definition.** An architecture artifact (diagram, doc, ADR) that renders but decides nothing. Passes visual review; fails any "what would flip this" question. The canonical AI-slop failure mode: every section is filled, every box is labeled, every arrow exists, and not one element has a flip point, a blast radius, or an alternative rejected.

**Symptoms.** C4 container diagrams with eight boxes and no rationale per box. Sections titled "Non-Functional Requirements" whose content is "scalable, performant, reliable." ADRs with a Context and a Decision but no Alternatives Rejected. Paragraphs that read the same across any product category.

**Smell test.** Pick any element (box, arrow, ADR, paragraph). Ask: "what would make us reverse this?" If the answer is "nothing in particular" or "it depends on context," the element is decoration. If the answer is "we would reverse this if the PRD's tenancy model changes from single-tenant to multi-tenant, or if the scale ceiling moves above 100K org-users, or if a regulatory constraint forbids PII in this component," the element is a decision.

**Fix.** For every failing element, either add the flip-point field (Nygard ADR format, SKILL.md Step 8) or delete the element. Do not try to patch prose; rewrite from the pre-flight answers up.

**Citation.** RESEARCH-2026-04.md section 2.1; SKILL.md have-nots list.

### Paper-tiger architecture

**Coined here.** The phrase "paper tiger" is common English (Mao 1956); in software, no prior technical use exists. See RESEARCH-2026-04.md section 2.2.

**Definition.** Architecture that reads robust on paper (redundant regions, HA databases, circuit breakers, graceful degradation) but the first real load or first real failure collapses it because the decisions were never load-tested by design review. The latency chain, throughput chain, and availability chain have not been computed.

**Symptoms.** The ARCH.md says "multi-region active-active with p99 under 100ms." The arithmetic does not close: the multi-region replication lag is 50-80ms, the application makes three sequential DB calls, the p99 chain is 300-500ms in the best case. No one did the math. "Scalable to 1M users" with no specification of requests per user, per second, at peak. "99.99% availability" with four dependencies at 99.9% each, the chain is 99.6% at best.

**Smell test.** Compute the chain. Latency: sum the mean and the tail of every hop on the request path; does it meet the PRD p95 and p99? Availability: multiply the uptimes of every dependency on the critical path; does it meet the PRD uptime? Throughput: divide the PRD's req/s target by the per-component capacity; does it fit? If any chain fails, the architecture is paper tiger.

**Fix.** Do the math in Step 6. Publish the chain in the ARCH.md Non-Functional section. When the chain fails the PRD target, either change the shape (add caching, precompute, move to async) or change the target (negotiate with PRD; change the appetite). Silence on the math is not an answer.

**Citation.** RESEARCH-2026-04.md section 2.2; SKILL.md Step 6 and have-nots list.

### Horoscope architecture

**Coined here** (adopted from stack-ready vocabulary; prd-ready uses "horoscope PRD" for the same shape at the product tier). See RESEARCH-2026-04.md section 2.10.

**Definition.** An ARCH.md whose prose reads plausibly regardless of the project, surviving the substitution test across domains. "The system uses a scalable backend with a well-designed data layer and a modern frontend" is horoscope prose. Replace "orders" with "tickets" or "invoices" or "bookings"; if the architecture still reads plausibly, it has not decided anything specific.

**Symptoms.** Entity names are generic ("User," "Record," "Event," "Service"). NFR claims are directional ("fast," "reliable," "scalable") with no numbers. Components are named by layer ("API," "Service," "Data Access") rather than by bounded context ("Orders," "Billing," "Identity"). The word "appropriate" appears as a load-bearing qualifier ("appropriate caching," "appropriate partitioning").

**Smell test.** The substitution test at domain level: swap the project with a different domain. If the ARCH.md still reads plausibly for the new domain, it was horoscope. A real ARCH.md for an orders system names "order," "cart," "line item," "fulfillment," "inventory," "pricing"; these do not substitute into a medical-records system without obvious wrongness.

**Fix.** Rewrite with the PRD's actual entities, numbers, and constraints. Every paragraph must cite either a PRD number or a named entity; paragraphs that do neither are horoscope.

**Citation.** RESEARCH-2026-04.md section 2.10; SKILL.md have-nots list; parallel to prd-ready's "invisible PRD" refusal.

### Ghost architecture

**Coined here.** See RESEARCH-2026-04.md section 2.10.

**Definition.** The ARCH.md describes one system; the running system is a different one. Happens when ARCH.md is not maintained post-build, no fitness function catches the drift, and the team relies on the doc for onboarding. New engineers read the doc, build against the doc, and discover in code review that the system does not match.

**Symptoms.** A diagram shows three services; the repo has five deployables. An ADR says "we use Postgres for orders and an event log for audit"; the audit log is a Postgres table with a `created_at` column and no replay capability. A component diagram shows a Redis cache; Redis was removed eighteen months ago and nothing replaced it in the diagram.

**Smell test.** Pick three load-bearing claims from the ARCH.md. Open the repo and verify each. If any fails to match, the ARCH.md is ghost.

**Fix.** Mode B or Mode D. Run the codebase-reality scan (SKILL.md Step 0, Mode B); reconcile divergences as open questions with owners; supersede the ADRs that no longer match reality; wire a dependency-conformance fitness function to catch future drift. Tier 3 requires a post-build audit at 30 / 60 / 90 days precisely to refuse ghost architecture.

**Citation.** RESEARCH-2026-04.md section 2.10; SKILL.md Step 13, Step 14, and Tier 3 requirement 22.

### Invisible architecture

**Adopted term** (parallel to prd-ready's "invisible PRD"; not a canonical architecture-literature term but an internal ready-suite term).

**Definition.** Architecture that survives the substitution test. Reads the same across any system in the same domain. Specifically: replace "orders" with "tickets" or "invoices" or "bookings." If the architecture still reads plausibly, it is invisible and has not decided anything specific.

**Symptoms.** No named NFR numbers from the PRD. No named integrations from the PRD. No tenancy model stated for a multi-tenant product. No bounded contexts; instead, layers ("service layer," "data layer"). No cited precedent system.

**Smell test.** The substitution test at product level. If ARCH.md for a B2B SaaS CRM reads identically to ARCH.md for a B2C ride-sharing app, both are invisible.

**Fix.** Same as horoscope architecture. Rewrite with PRD specifics; add the prior-art section (Tier 2 requirement 17) naming three comparable public systems.

**Citation.** RESEARCH-2026-04.md section 2.10; SKILL.md have-nots list.

### Cover Your Assets

**Coined by Brown / Malveau / McCormick / Mowbray, "AntiPatterns," Wiley, 1998.** https://sourcemaking.com/antipatterns/software-architecture-antipatterns. See RESEARCH-2026-04.md section 1.3.

**Definition.** Architecture authors evade decisions by listing alternatives. To avoid making a mistake, they enumerate options without picking. When no decisions are made and no priorities are established, the document has limited value. The 20-year-old name for a large portion of the AI-generated-architecture failure mode.

**Symptoms.** "We can use Postgres or MySQL or MongoDB, depending on the workload." "The system could be a monolith or microservices." "Authentication could be session-based or JWT-based, to be determined."

**Smell test.** Count the "or" clauses in the ARCH.md. Count the "depending on" clauses. Count the "to be determined" sections. If the total is more than 3-4 items at Tier 1, or more than zero at Tier 2, the doc is Cover Your Assets.

**Fix.** Convert each "or" into an ADR with a decision, a rationale, and alternatives rejected. If genuinely undecided, flag as an open question with an owner and a due date; do not ship the undecided state as the decision.

**Citation.** RESEARCH-2026-04.md section 1.3 and section 2; Brown et al. 1998.

### Architecture by Implication

**Coined by DevIQ** (undated). https://deviq.com/antipatterns/architecture-by-implication/. See RESEARCH-2026-04.md sections 1.3, 2.10.

**Definition.** Architecture is assumed rather than documented. The team has intent; the document does not record it. New engineers inherit the intent by asking current engineers; when the current engineers leave, the intent is lost.

**Symptoms.** The team "has an architecture" but no ARCH.md. ADRs are in Slack messages, Google Docs, or pull-request comments. Onboarding is "ask Sarah." Decisions are visible in code but not in text.

**Smell test.** Ask the team to point at the architecture document. If there is no document, or if the document was last updated more than twelve months ago, architecture-by-implication is in effect.

**Fix.** Mode B. Run the retroactive ARCH.md process; extract intent from interviews and from code; record in ADRs with `(retroactive)` labels; begin the supersession discipline going forward.

**Citation.** DevIQ; RESEARCH-2026-04.md sections 1.3 and 2.10.

## 3. Shape-level antipatterns

Antipatterns of the system shape itself.

### Distributed monolith

**Coined by Sam Newman,** canonical definition quoted from Jonathan Tower (InfoQ 2016): "the services are separately deployable but have so many dependencies that they must be deployed together." See RESEARCH-2026-04.md section 2.6.

**Definition.** Multiple services share a database, share synchronous call chains, or share deployment coupling so tight that they deploy together. Gets the operational cost of distributed systems (network failures, eventual consistency, observability complexity) with none of the benefits (independent scaling, independent deploy, team autonomy).

**Symptoms.** Two services writing to the same Postgres table. Every user request fans out to three sync calls across services. Deploy order is documented: "deploy Orders before Payments, always." A schema migration requires coordinated deploys across four repos.

**Smell test.** Can each service ship independently? If the answer requires a coordination plan, the shape is a distributed monolith. Is there one writer per entity? If not, the shape is a distributed monolith.

**Fix.** Either consolidate the services into a modular monolith (the Segment / Prime Video / Istio path; RESEARCH-2026-04.md section 4.1) or refactor the data ownership so each service owns its tables and communicates via outbox events. The modular-monolith path is the cheaper fix for teams under 20 engineers.

**Citation.** RESEARCH-2026-04.md sections 1.1 and 2.6; Newman 2019; InfoQ 2016.

### Anemic services

**Adopted term** (parallel to Fowler's "Anemic Domain Model"; used widely in microservices critique; see Newman 2019).

**Definition.** A service that is a thin wrapper over a single database table. Usually named "UserService," "AuthService," "NotificationService." These are CRUD endpoints, not services. They introduce network hops, independent deploy burden, and observability complexity without encapsulating a bounded context.

**Symptoms.** The service's responsibility sentence is "CRUD for the users table." The service has no business logic beyond input validation; it is a REST proxy for a table. The service owns no process, only state.

**Smell test.** Ask: "what domain invariant does this service enforce?" If the answer is "the schema of the table," the service is anemic.

**Fix.** Consolidate into the bounded context that owns the entity. A user is rarely the whole bounded context; usually Identity (auth, users, sessions, API keys) is the bounded context and "UserService" is a fragment of it.

**Citation.** SKILL.md have-nots list; Newman 2019.

### God services

**Adopted term** (inverse of anemic services; widely used in microservices critique).

**Definition.** A service whose responsibility sentence covers half the domain. "Handles users, auth, billing, orders, and notifications." The inside of a monolith with a REST API painted on. Undermines the independent-deploy / independent-scale argument that motivated the decomposition.

**Symptoms.** One service has more lines of code than the other six combined. Features that should be independent ship through the same repo. A schema migration in one bounded context blocks deploys across another.

**Smell test.** The responsibility sentence contains "and." A single "and" is a red flag; three "and"s is a god service.

**Fix.** Split by bounded context. The Evans / Vernon DDD frame identifies the split points; the ADR for the split names the PRD constraint that justifies it.

**Citation.** SKILL.md have-nots list; Evans 2003; Vernon 2013.

### Big ball of mud

**Coined by Brian Foote and Joseph Yoder, PLoP 1997.** https://www.laputan.org/mud/mud.html. PDF mirror at https://hillside.net/plop/plop97/Proceedings/foote.pdf. See RESEARCH-2026-04.md section 2.8.

**Definition.** A haphazardly structured, sprawling, sloppy, duct-tape-and-baling-wire, spaghetti-code jungle. Expedient local changes have accumulated to the point that the architecture is unrecognizable. Unlike "accidental architecture," the ball of mud is actively resisted by nothing.

**Symptoms.** Circular imports everywhere. A change in one module requires changes in seven others. No clear ownership of entities. The onboarding doc says "good luck."

**Smell test.** Attempt to draw the C4 Container diagram. If no sensible diagram can be produced, the system is a ball of mud.

**Fix.** Pick one bounded context; extract it with a fitness function (dependency-cruiser / Packwerk) enforcing the boundary; repeat. The modular-monolith path is the practical cure; rewrite is almost always a false economy (Fowler "MonolithFirst," section 1.1).

**Citation.** Foote / Yoder 1997; RESEARCH-2026-04.md section 2.8.

### Non-architecture ("we'll figure it out later")

**Coined here** with tight definition; adjacent prior art in SourceMaking's "Architecture By Implication."

**Definition.** The explicit decision to defer architectural decisions indefinitely. Zero ADRs; zero constraints; zero failure-mode analysis. An architecture document that is a hopes list is not architecture.

**Symptoms.** "We'll start with a simple Rails app and refactor later." "Microservices if we need them." "We'll add caching when we hit scale." Zero decisions recorded; zero flip points; zero failure modes.

**Smell test.** Can the team name a decision they have made about the architecture? If the answer is "we just use the framework defaults," non-architecture is in effect.

**Fix.** The load-bearing check (SKILL.md Step 1). If architecture is not load-bearing, non-architecture is acceptable: write the one-page minimal ARCH.md and stop. If architecture is load-bearing, non-architecture is the failure; run the full skill.

**Citation.** RESEARCH-2026-04.md section 2.7.

### Cargo-cult cloud-native

**Adopted term** (Stavros Korokithakis 2015 "microservices cargo cult"; Portainer 2024 "The Kubernetes Cargo Cult"). See RESEARCH-2026-04.md section 1.2 and 2.3.

**Definition.** Adopting Kubernetes, Kafka, service mesh, event sourcing, CQRS, or the full CNCF stack because other companies do, with no PRD-grounded justification tied to a specific non-functional constraint. "Because it scales" without a number is cargo-cult.

**Symptoms.** A ten-engineer team running a 100-service Kubernetes cluster for a CRUD app with 5K MAU. A 100-event-per-day system with Kafka as the event bus. A 5K-MAU app with a service mesh, API gateway, and three sidecars per pod.

**Smell test.** For each named CNCF component, ask: "what PRD constraint does this serve?" If the answer is "scalability" without a number, or "best practice," cargo-cult is in effect.

**Fix.** Replace each component with the simplest alternative that meets the actual constraint. Usually: Kubernetes to a managed PaaS; Kafka to SQS or RabbitMQ or direct DB-polling; service mesh to a load balancer plus TLS; API gateway to a reverse proxy.

**Citation.** Korokithakis 2015; Portainer 2024; RESEARCH-2026-04.md sections 1.2 and 2.3.

### Resume-driven architecture

**Coined / studied by Fritzsch / Wyrich / Bogner / Wagner, ICSE 2021.** "Résumé-Driven Development: A Definition and Empirical Characterization." https://arxiv.org/abs/2101.12703. See RESEARCH-2026-04.md sections 1.5 and 2.5.

**Definition.** Architects pick shapes, tools, and patterns to improve their resume rather than to serve the PRD. The practical architecture-tier form: Kafka, Kubernetes, event sourcing, and CQRS on a 50-user internal tool because those are the four phrases that go on a resume.

**Symptoms.** The flip point for an architecture choice would require the PRD to change in ways the PRD does not mention. The ADR rationale is "industry best practice" rather than a PRD constraint. The architect has changed teams frequently and each project shipped with a novel stack.

**Smell test.** Ask: "if this decision were wrong, how would we find out?" If the answer is "we probably would not, because the team would have rotated by then," resume-driven architecture is likely.

**Fix.** Re-derive the shape from the PRD. Substitute every fancy tool with the simplest alternative; if the simple alternative loses on a PRD-specific criterion, keep the fancy tool; if it does not, cut.

**Citation.** Fritzsch et al. 2021; RESEARCH-2026-04.md sections 1.5 and 2.5.

### Accidental architecture

**Adopted term** (used in Brown et al. 1998, SourceMaking, and numerous blog posts; no single canonical coiner). See RESEARCH-2026-04.md section 2.9.

**Definition.** Architecture that emerged without decision. Different from non-architecture (which is an explicit deferral) and different from big ball of mud (which is actively sprawling). Accidental architecture has shape; no one designed it; and no one has written it down.

**Symptoms.** The team says "we have an architecture" but cannot name the decisions. Shape is visible; rationale is absent. Onboarding is oral tradition.

**Smell test.** Ask three engineers to describe the architecture in one paragraph. If the three paragraphs disagree on the system shape, the component boundaries, or the trust boundaries, accidental architecture is in effect.

**Fix.** Mode B. Retroactive ARCH.md from reality; interviews; ADRs labeled `(retroactive)`.

**Citation.** Brown et al. 1998; RESEARCH-2026-04.md section 2.9.

## 4. Data-architecture antipatterns

Antipatterns of the storage, ownership, and transactional decisions.

### Stackitecture

**Coined here.** See RESEARCH-2026-04.md section 2.4.

**Definition.** Architecture decisions driven by stack choice rather than problem shape. "Our architecture is Next.js + Postgres + Prisma" is stackitecture; the stack has overwritten the shape question. Opposite of architecture-ready's intended discipline: architecture shape first, stack second.

**Symptoms.** The ARCH.md's "system shape" section names frameworks and databases. The "data architecture" section names Postgres without first naming a storage shape (relational? document? time-series?). The "integration" section names specific tools (Kafka, Redis) without first naming the integration shape (sync? async? fan-out? queue?).

**Smell test.** Remove every brand name from the ARCH.md. Read what remains. If the architecture is no longer legible, stackitecture was the document.

**Fix.** Rewrite the ARCH.md without brand names; add the storage-shape / integration-shape / compute-shape vocabulary; let stack-ready pick the brand from the shapes.

**Citation.** RESEARCH-2026-04.md section 2.4.

### "Just wire it to Postgres" without shape analysis

**Adopted term** (parallel to cargo-cult; described in RESEARCH-2026-04.md section 1.7).

**Definition.** The AI-slop data-architecture failure. Any persistence question produces "use Postgres with Prisma" regardless of whether the workload is time-series, graph, append-only event log, write-heavy ledger, or OLAP. Postgres is a good default; it is not a design.

**Symptoms.** Every entity stored in Postgres tables; audit logs as Postgres rows that grow linearly; time-series metrics stored as rows keyed by timestamp; full-text search as `ILIKE` queries; graph traversal as recursive CTEs.

**Smell test.** For each entity group in the ARCH.md, ask: "what is its access pattern?" If the access pattern is graph traversal (N+1 hops), the shape is graph; if it is append-only with time-range queries, the shape is time-series or event log; if it is text search with relevance ranking, the shape is inverted index. Postgres can serve several of these with extensions, but the shape must be named first.

**Fix.** Step 4 of SKILL.md. Name the storage shape per entity group (relational / document / key-value / time-series / event log / search / graph / object store). The brand (Postgres, TimescaleDB, Elasticsearch) is stack-ready's decision.

**Citation.** RESEARCH-2026-04.md section 1.7; Kleppmann 2017.

### Shared database for writes across services

**Coined by Sam Newman 2019,** also documented by Helland 2007. See RESEARCH-2026-04.md sections 1.7, 2.6, 3.11.

**Definition.** Two or more services write to the same database table. The signature of a distributed monolith at the data tier. Prevents independent deploy (schema changes coordinate), prevents independent scale (one writer's load limits the other), and prevents data-ownership fitness functions (no single writer to enforce).

**Symptoms.** Two service repos have migrations against the same table. Two services have an ORM model for the same row. Two services have read-write credentials to the same schema.

**Smell test.** For each load-bearing table, list the services that write to it. If the list is longer than one, the antipattern is present.

**Fix.** Refactor to a single writer; the non-writer reads via API, via a read replica, or via events. Enforce with schema grants (data-ownership fitness function, evolutionary-architecture.md Section 5).

**Citation.** Newman 2019; RESEARCH-2026-04.md section 2.6.

### Distributed transactions across services

**Described by Helland 2007, "Life beyond Distributed Transactions."** See RESEARCH-2026-04.md section 3.11.

**Definition.** A transaction that spans service boundaries. In practice: two-phase commit (2PC) across services, or an XA-style coordinator, or a long-lived lock held across a network hop. Fragile, slow, and prone to coordinator-loss failure modes.

**Symptoms.** The ARCH.md mentions "distributed transaction" or "2PC." An integration path is described as "atomic across services." A saga is described without compensation logic.

**Smell test.** Can you name the failure mode when the coordinator dies mid-transaction? If the answer is "it rolls back," distributed transactions are in play. If the answer is "we log the inconsistency and reconcile later," the design is actually a saga; name it as such.

**Fix.** Replace with a saga (compensating actions) or the outbox pattern (write-to-DB and emit-event in the same local transaction). SKILL.md Step 5 names both.

**Citation.** Helland 2007; Newman 2019; RESEARCH-2026-04.md section 3.11.

### Event sourcing applied to the whole system

**Documented as antipattern: InfoQ 2016, Chris Kiehl 2024, Oliver Butzki (DEV.to).** See RESEARCH-2026-04.md section 4.5.

**Definition.** Building a whole system on event sourcing: the event log is the source of truth for every entity, every read is a projection. In a small number of domains (ledgers, regulatory audit trails, collaborative documents) this is correct. In most domains it is overkill, the learning curve is steep, and the operational cost (schema evolution, projection rebuilds, versioning) is high.

**Symptoms.** Every entity has a corresponding event stream. Reads require replaying events or maintaining projections. Schema evolution requires writing upcasters. New engineers take months to ship features.

**Smell test.** For the event-sourcing decision, name the PRD constraint that makes a history table insufficient. If the answer is not "seven-year regulatory retention with replay" or "concurrent collaborative editing" or "financial ledger with immutable audit," event sourcing is overkill.

**Fix.** Replace with a history table (most audit needs), or CQRS on a traditional DB (most read-heavy needs), or a specific event-sourced aggregate where the domain demands it. Keep 80% of the value at 10% of the cost.

**Citation.** RESEARCH-2026-04.md section 4.5; InfoQ 2016; Kiehl 2024.

### CQRS for its own sake

**Documented widely; Thoughtworks Technology Radar has warned since ~2017.**

**Definition.** Separating read and write models when read and write patterns do not genuinely differ. Adds complexity (two models, synchronization, eventual-consistency UX handling) for no benefit.

**Symptoms.** The read model is a near-copy of the write model with one extra field. Synchronization between the two is handled by a scheduled job. The UI is designed around "eventually consistent reads" that confuse users.

**Smell test.** Name the read access pattern and the write access pattern. If they do not genuinely differ (the read is not a different shape, different cardinality, or different latency budget), CQRS is overkill.

**Fix.** Collapse to a single model. If read load becomes a bottleneck later, add a read replica; if read patterns diverge later, introduce CQRS then.

**Citation.** RESEARCH-2026-04.md section 4.5.

### Golden hammer on storage

**Coined by Brown et al. 1998.** https://sourcemaking.com/antipatterns/software-architecture-antipatterns.

**Definition.** Applying the same storage shape to every workload. Usually the default is relational (Postgres everywhere), but the antipattern applies equally to "MongoDB for everything" or "DynamoDB for everything." Results in graph workloads in relational tables (recursive CTEs), time-series in rows (exploding row count), and search in `ILIKE` queries (no relevance ranking, no tokenization).

**Symptoms.** One database brand, one schema shape, every entity shoehorned. When a workload does not fit, the team invents a workaround inside the existing storage rather than adding a specialized store.

**Smell test.** For each entity group, does its access pattern genuinely match the storage shape? If the answer requires justification ("well, it's fine with indexes"), the hammer is applied incorrectly.

**Fix.** Name the storage shape per entity group in Step 4. The brand can still be one vendor (Postgres has extensions for several shapes), but the shape decision is explicit and the ADR names the trade-off.

**Citation.** Brown et al. 1998; RESEARCH-2026-04.md section 2.10.

## 5. Integration antipatterns

Antipatterns of how components talk.

### Dual-write without outbox

**Described by the outbox pattern literature (Debezium, Microservices.io).**

**Definition.** An operation writes to the database and also emits a message to a broker, in two separate non-transactional steps. If the broker is down after the DB write, the event is lost. If the DB fails after the broker write, the system is inconsistent. One of the two failure modes always exists.

**Symptoms.** Code shape: `db.save(order); broker.publish("OrderPlaced", order);`. No transactional guarantee across the two calls. No retry queue for failed publishes.

**Smell test.** Ask: "what happens if the broker is down when we save the order?" If the answer is "the event is lost," dual-write is in play.

**Fix.** Outbox pattern. Write the event to a local table in the same DB transaction as the save; a separate poller or CDC (Debezium) publishes to the broker. SKILL.md Step 5 names it.

**Citation.** RESEARCH-2026-04.md section 5 (general); Newman 2019.

### "Exactly-once delivery" claims

**Widely refuted; Kleppmann 2017 chapter 9 makes the formal argument.**

**Definition.** Any claim that a message-bus or integration achieves "exactly-once delivery" without idempotent receivers. The underlying networks and brokers are at-least-once in practice; exactly-once is an illusion maintained at the application layer via idempotency keys and dedup.

**Symptoms.** The ARCH.md says "we use Kafka exactly-once semantics." An integration is described without an idempotency key.

**Smell test.** Ask: "what is the idempotency key for this mutation?" If the answer is "we don't need one because delivery is exactly-once," the claim is wrong.

**Fix.** Declare at-least-once delivery; require idempotent receivers; name the idempotency key per mutation. Kafka's "exactly-once semantics" is within-broker only, not end-to-end.

**Citation.** Kleppmann 2017 chapter 9; Helland 2007.

### Synchronous call chains across every user request

**Documented as the "distributed monolith" flavor by Newman 2019 and by Thoughtworks "Layered microservices architecture."**

**Definition.** Every user request fans out to 3-10 synchronous calls across services. p99 latency is the sum of the worst-case paths; availability is the product of the component availabilities. The latency chain fails; the availability chain fails; no one in the team notices because the PRD NFR targets are never computed.

**Symptoms.** A trace of a single user request spans five services in sequence. Any one service degrading to 500ms p99 breaks the user experience. A single 5xx from any service surfaces as a user-visible error.

**Smell test.** Trace one user request through the system. Count the synchronous network hops. Multiply the per-hop p95 by the count; compare to the PRD target. If the chain exceeds the target, the shape is wrong.

**Fix.** Collapse into a monolith (Step 2 modular-monolith choice), or move some hops async with eventual consistency at the UI, or precompute / cache aggressively.

**Citation.** Newman 2019; Thoughtworks Radar; RESEARCH-2026-04.md section 2.6.

### RPC-over-shared-DB

**Historical antipattern; Kleppmann 2017 and Newman 2019 both caution.**

**Definition.** Service A communicates with Service B by writing to a shared DB table that Service B polls. A crude integration shape that couples A and B via the schema without a clear API contract. Common when teams try to avoid a broker.

**Symptoms.** A table named `jobs` or `queue` that multiple services read and write. No API contract; the table schema is the contract. Schema changes require coordinated deploys.

**Smell test.** Is the service boundary visible in a formal interface (REST, gRPC, event schema)? Or is it only visible in a shared DB schema? If only the latter, RPC-over-shared-DB is the shape.

**Fix.** Replace with a proper broker (SQS, Kafka, RabbitMQ) or a direct API. The shared table couples two services through a third system; either make it one service or make the contract explicit.

**Citation.** Newman 2019.

### Sync fan-out without fallback

**Described in Hohpe / Woolf 2003 and in the resilience-patterns literature (Nygard "Release It!" 2007).**

**Definition.** A synchronous request fans out to N downstream calls; if any fails, the whole request fails; no fallback is defined.

**Symptoms.** A search endpoint calls four enrichment services in parallel; if any times out, the whole search fails. No graceful degradation.

**Smell test.** Ask: "what does this endpoint return if enrichment service N times out?" If the answer is "the user sees an error," no fallback exists.

**Fix.** Add a timeout per downstream; return partial results on timeout; document the degraded mode.

**Citation.** Nygard "Release It!" 2nd ed 2018; Hohpe / Woolf 2003.

### No idempotency on mutations over unreliable networks

**Described everywhere; formally treated by Helland 2007.**

**Definition.** A mutation is sent over a network (webhook, partner API, payment flow); the caller retries on failure; the mutation does not check an idempotency key; the mutation runs twice; the system is inconsistent.

**Symptoms.** A webhook handler creates a record on every invocation; the handler has no idempotency key. A payment flow charges twice on a network retry.

**Smell test.** Every mutation over a network has an idempotency key. If any mutation does not, the antipattern is present.

**Fix.** Require an idempotency key on every mutation; store a dedup record; reject duplicate keys with a 200-OK-and-no-op or a 409-conflict.

**Citation.** Helland 2007; Stripe's idempotency-key docs as the canonical industry reference.

### Circuit breaker named but not configured

**Adjacent to "fitness function named but not wired" from evolutionary-architecture.md Section 10.**

**Definition.** The ARCH.md mentions "circuit breaker" as a resilience pattern; the implementation has a library imported but no thresholds, timeouts, or half-open state configured. The code runs; the circuit never trips; the pattern exists only on paper.

**Symptoms.** An import of Polly / Hystrix / resilience4j / go-resiliency with default configuration. No tests for the circuit-open state. No alert on circuit-open.

**Smell test.** Is there a test that forces the downstream to fail and asserts the circuit opens? If not, the circuit breaker is theater.

**Fix.** Configure thresholds (failure rate, latency, volume); add a test that trips the circuit; add an alert on circuit-open.

**Citation.** Nygard "Release It!" 2nd ed 2018.

### No dead-letter queue

**Standard enterprise-integration-pattern guidance; Hohpe / Woolf 2003.**

**Definition.** An async-integration handler fails; the message is retried a fixed number of times; on exhaustion, the message is dropped silently. The failure mode is invisible until someone notices data loss later.

**Symptoms.** A consumer has no DLQ configuration. Failed messages are logged but not stored. No alert on failure-rate.

**Smell test.** Ask: "what happens to a message that fails all retries?" If the answer is "logged and dropped," DLQ is missing.

**Fix.** Configure a DLQ; alert on DLQ depth; provide a reprocessing path.

**Citation.** Hohpe / Woolf 2003.

### Silent failure modes

**General antipattern; Nygard 2018.**

**Definition.** The system fails in a way that is not visible to the user, the operator, or the monitoring layer. Broken background jobs, dropped async messages, failed webhook deliveries that never retry.

**Symptoms.** "Why didn't the email get sent?" has no answer. An audit log is missing entries from a three-hour window last week. A background job has been failing silently for months.

**Smell test.** For each failure mode named in Step 5 (integration-architecture), is it observable? If not, it is silent.

**Fix.** Every failure mode emits a metric or an alert. DLQ depth, retry count, circuit-open state, background-job-success-rate are all observable.

**Citation.** Nygard 2018; SKILL.md Step 5 failure-posture requirement.

## 6. Trust-boundary antipatterns

Antipatterns of authority transitions in the system. The most catastrophic class; one breach is usually enough to take a company down (Code Spaces 2014, Atlassian 2022, Capital One 2019).

### Silent multi-tenant boundary

**Described throughout the trust-boundary literature; see Shostack 2014.**

**Definition.** A multi-tenant architecture with no named tenant-isolation boundary. The architecture implicitly assumes tenant-column filters in queries; no enforcement layer, no test, no policy-as-code. First bug in an ORM query joins one tenant's data into another tenant's response.

**Symptoms.** The ARCH.md Step 7 section is three words. Queries use `WHERE tenant_id = ?` filters at the application layer; no row-level security at the DB; no middleware that enforces tenant scoping.

**Smell test.** Is there an integration test that tenant A cannot read tenant B's data through any endpoint? If not, silent tenant boundary.

**Fix.** Name the boundary; add row-level security at the DB (Postgres RLS); add middleware that injects tenant scope; add the fitness function (evolutionary-architecture.md Section 7).

**Citation.** RESEARCH-2026-04.md sections 5.6 (Atlassian 2022), 2.10; Shostack 2014.

### Client-only authorization

**A classic; documented in every OWASP Top 10 since 2013.**

**Definition.** Authorization decisions are made in the frontend (hidden buttons, disabled fields); the backend does not re-enforce. A user with browser dev tools can send any request and bypass the UI-level check.

**Symptoms.** The backend trusts a `role` claim from the frontend. Frontend hides admin buttons; backend does not check admin scope on admin endpoints. "Security by obscurity."

**Smell test.** Call the admin endpoint with a non-admin token. Does the request succeed? If yes, client-only authorization is the pattern.

**Fix.** Enforce authorization on every mutation at the server. Frontend hiding is UX; backend enforcement is security.

**Citation.** OWASP Top 10 A01:2021 (Broken Access Control).

### Single layer for a load-bearing boundary

**Defense-in-depth principle; Shostack 2014.**

**Definition.** A trust boundary is enforced by exactly one mechanism; a bug or bypass in that mechanism breaches the boundary. For load-bearing boundaries (tenant isolation, admin scope, payment authorization), a single layer is insufficient.

**Symptoms.** Tenant isolation is enforced only by a middleware check. Admin authorization is enforced only by a role string in the JWT. Payment authorization is enforced only at the API layer.

**Smell test.** For each load-bearing boundary, name two independent enforcement layers. If there is only one, defense-in-depth is missing.

**Fix.** Add at least one reinforcing layer: row-level security at the DB plus middleware at the app; cryptographic scoping plus role check; policy-as-code plus code-level check.

**Citation.** Shostack 2014; RESEARCH-2026-04.md section 5.

### Audit log in the same service it audits

**Described in SRE literature and Nygard 2018.**

**Definition.** The audit log is written by the same service (and same DB) it is auditing. When the service is compromised or fails, the audit log is lost or corruptible. The audit log serves no forensic purpose if the attacker can modify it.

**Symptoms.** Audit log as a table in the same Postgres as the application data. Same service credentials; same failure domain.

**Smell test.** If the application database is corrupted, is the audit log preserved? If no, the audit log is not an audit log.

**Fix.** Write the audit log to a separate store with append-only semantics: a different database with write-only grants; a log aggregator; an event log with compaction disabled. Shostack 2014 and the SOC 2 audit-log requirement address this directly.

**Citation.** Shostack 2014; RESEARCH-2026-04.md section 5.5 (GitLab 2017 backup failure as the same class of mistake).

### PII crossing a boundary without re-authentication

**GDPR, HIPAA, and SOC 2 all address this.**

**Definition.** PII leaves a regulated component and enters an unregulated one without re-authentication, re-authorization, or re-encryption at the boundary. Expands compliance scope silently.

**Symptoms.** PHI flows from an HIPAA-scoped service to an analytics pipeline that has no BAA. PCI data flows to a logging service with no PCI scope. GDPR-restricted data flows to an offshore component.

**Smell test.** For each boundary between regulated and unregulated components, is the data transformed, redacted, or re-authorized? If not, the boundary is a compliance hole.

**Fix.** Redact / tokenize PII at the boundary; or make both components regulated; or reject the cross-boundary flow.

**Citation.** HIPAA / PCI / GDPR compliance literature; SKILL.md Step 6.

### Cross-tenant admin endpoints without explicit cell isolation

**Cell-based architecture literature; AWS re:Invent 2024 ARC312.**

**Definition.** A superuser / platform admin endpoint can perform mutations across tenants with no cell-level isolation. One bug, one compromise, one fat-fingered script, and the blast radius is the entire customer base (Atlassian 2022, Capital One 2019, Code Spaces 2014).

**Symptoms.** A single admin API call can affect any tenant. No per-cell rate limit; no per-cell authorization; no per-cell blast-radius cap.

**Smell test.** For any admin endpoint, what is the worst-case blast radius? If the answer is "all tenants," cross-tenant admin without cell isolation.

**Fix.** Cell-based architecture (RESEARCH-2026-04.md section 4.6). Partition tenants into cells; admin operations scope to one cell; multi-cell operations require explicit multi-cell authorization and have per-cell rate limits.

**Citation.** AWS re:Invent 2024 ARC312, ARC335; RESEARCH-2026-04.md sections 4.6, 5.6.

## 7. Diagram antipatterns

Antipatterns of how the architecture is drawn. Simon Brown's own catalog (RESEARCH-2026-04.md section 7.3) is the reference.

### Cloud-vendor icon dumps

**Described by Brown at GOTO 2024.**

**Definition.** A diagram composed of AWS / GCP / Azure icons connected by arrows. Diagrams the deployment, not the architecture. Belongs in deploy-ready, not architecture-ready.

**Symptoms.** Hexagons and slabs. Service names next to icons (e.g., "Lambda" under the Lambda icon). No bounded contexts; no component responsibilities.

**Smell test.** Substitute the cloud vendor. If the architecture reads identically under AWS icons, GCP hexagons, and Azure slabs, the diagram was decorating the deployment.

**Fix.** Redraw with C4. Containers named by bounded context; arrows labeled with protocol and purpose; vendor icons removed or relegated to a deployment appendix.

**Citation.** Brown GOTO 2024; RESEARCH-2026-04.md section 7.3.

### Diagrams without labeled arrows

**Described by Brown; the most common C4 mistake.**

**Definition.** An arrow between two boxes with no label. Or a label that is "uses," "calls," or "talks to." These are not labels; they are spaces.

**Symptoms.** Arrows with no text. Labels like "uses," "calls," "sends."

**Smell test.** For each arrow, does the label name the protocol, the purpose, and the sync-vs-async? If not, the arrow is decoration.

**Fix.** Label format: "POST /api/orders (REST/JSON, authenticated, sync)" or "Emits OrderPlaced events (async, Kafka, at-least-once)." Labels are sentences, not words.

**Citation.** Brown GOTO 2024; RESEARCH-2026-04.md section 7.3.

### Mixed abstraction levels

**Brown flags this as the most common C4 misuse.**

**Definition.** A Container diagram with Components inside one container. Or a Component diagram with Code-level classes mixed in. Or a Context diagram with containers exposed as if they were external systems.

**Symptoms.** One box in the diagram is nested inside another box in a way the level does not allow. The legend fails to explain.

**Smell test.** Does every box in the diagram sit at exactly one C4 level? If not, abstraction levels are mixed.

**Fix.** Split into multiple diagrams at consistent levels. The Context, Container, and Component diagrams are separate artifacts; do not combine.

**Citation.** Brown GOTO 2024; RESEARCH-2026-04.md section 7.3.

### Rainbow diagrams without legend

**Described in general-purpose diagramming literature.**

**Definition.** Color carries information (red for sync, green for async, blue for database, yellow for cache) but no legend explains. Readers guess; colors conflict with their other associations; the diagram communicates less than a black-and-white version.

**Symptoms.** Five or more colors; no legend.

**Smell test.** Covering the key. Can a reader deduce what each color means? If not, the color is decoration.

**Fix.** Add a legend, or remove the color. Color should carry information that the shape and label do not already carry.

**Citation.** Tufte 1983 "The Visual Display of Quantitative Information."

### Diagrams out of date 18+ months

**Described in every post-mortem; Brown 2024.**

**Definition.** The diagram was last updated during the architecture kickoff; the system has evolved; the diagram does not reflect reality. Any new engineer who onboards from the diagram is onboarded to a fiction.

**Symptoms.** The diagram shows services that no longer exist. The diagram omits services that were added. The diagram shows protocols that were migrated.

**Smell test.** The diagram's last-update timestamp. If more than 6 months, assume stale; more than 12 months, verified stale; more than 18 months, ghost architecture.

**Fix.** Regenerate from Structurizr DSL in CI; or wire a diagram-drift fitness function; or establish a quarterly diagram review.

**Citation.** Brown 2024; ghost architecture antipattern (Section 2 above).

### C4 misuses (Brown's own catalog)

**From Brown's GOTO 2024 talk and the Working Software writeup.** See RESEARCH-2026-04.md section 7.3.

- **Containers with components inside a Container diagram.** Abstraction mix; split levels.
- **Missing technology on containers.** A container without a named technology is under-specified; the C4 standard requires it.
- **Missing direction on arrows.** Unidirectional vs bidirectional matters for coupling analysis.
- **Container-as-Component confusion.** Brown notes "container" is a badly chosen word; people confuse with Docker. A C4 container is a deployable unit (web app, API, database, file system).
- **No Context diagram.** Jumping straight to Container skips the "what is this system, who uses it, what does it depend on" question.

**Fix.** Read Brown's catalog before drawing; use Structurizr DSL for enforcement; review diagrams with the same rigor as code.

**Citation.** RESEARCH-2026-04.md section 7.3.

## 8. ADR antipatterns

Antipatterns of the decision-record practice. See evolutionary-architecture.md Section 10 for the fitness-function side; this section catches the record-keeping side.

### Retroactively rationalized ADRs

**Documented by IcePanel 2023, DEV.to ADR-practice writeups.** See RESEARCH-2026-04.md section 7.2.

**Definition.** An ADR written after the decision was implemented, whose rationale is reverse-engineered to match the already-chosen option. The alternatives-rejected section is invented; the reader cannot tell what was actually on the table.

**Symptoms.** All ADRs are dated within a single two-week window (written to backfill compliance). The alternatives-rejected section is plausible but generic ("MongoDB: rejected because relational fit is better"). The author was not on the team when the decision was made.

**Smell test.** Ask the author: "what alternative was on the table that you seriously considered?" If the answer is "I don't know, I wasn't there," retroactive rationalization.

**Fix.** Label retroactive ADRs as such: `ADR-NNN-slug.md (retroactive)`; note the date the decision actually shipped; name the alternatives as best-known; flag unknowns.

**Citation.** RESEARCH-2026-04.md section 7.2.

### ADRs without flip points

**SKILL.md Step 8 requirement.**

**Definition.** An ADR that has Status, Date, Context, Decision, Rationale, Alternatives, Consequences, but no Flip Point field. The ADR records the decision but not the condition under which the decision would be reversed. Readers cannot tell when to revisit.

**Symptoms.** The ADR ends with Consequences. No "what would flip this" paragraph.

**Smell test.** Read the ADR. Can you state, in one sentence, the scale number, team-size threshold, compliance event, or cost curve that would reverse the decision? If not, no flip point.

**Fix.** Add the Flip Point field. "We would reverse this decision if the scale ceiling moves above 100K org-users, if the team grows beyond 20 engineers, or if a compliance event requires physical isolation."

**Citation.** SKILL.md Step 8; Nygard 2011 extended format.

### "We chose X because industry-standard"

**Described throughout the AI-slop cohort of blog posts; RESEARCH-2026-04.md section 1.8.**

**Definition.** An ADR whose rationale is "it is industry-standard," "it is best practice," or "it is what most companies do." Not a rationale; an appeal to authority. Fails the substitution test (any tool could be justified this way).

**Symptoms.** Rationale contains "industry-standard," "best practice," "widely adopted," "mature ecosystem," without a PRD-grounded constraint.

**Smell test.** Replace the chosen tool with a plausible alternative. If the rationale still reads plausibly ("MongoDB is industry-standard" works as well as "Postgres is industry-standard"), the rationale decided nothing.

**Fix.** Rewrite with a concrete trade-off. "We chose Postgres because the PRD's strong-consistency requirement on the orders path forbids eventual-consistency stores; MongoDB was rejected because its default isolation is too weak; MySQL was rejected because the team's on-call rotation has Postgres depth but not MySQL depth."

**Citation.** RESEARCH-2026-04.md sections 1.8, 7.2.

### "We chose X because it scales"

**Documented by Korokithakis 2015 "microservices cargo cult."**

**Definition.** Rationale is "it scales" with no number. The load-bearing claim is vacuous; every tool "scales" at some level. Fails the paper-tiger test.

**Symptoms.** Rationale contains "scales," "scalable," "handles scale," without a requests-per-second number, a data-volume number, or a user-count number.

**Smell test.** Ask: "at what load does the alternative stop working?" If the answer is a number, "it scales" becomes a real claim; if not, it is cargo-cult.

**Fix.** Name the scale target. "We chose Kafka because our event-volume target is 500K events/second sustained; SQS was rejected because its per-queue throughput ceiling is 3K msg/second in standard-delivery mode."

**Citation.** Korokithakis 2015; RESEARCH-2026-04.md section 1.2.

### "We chose X or Y depending on the case"

**A form of Cover Your Assets (Brown et al. 1998).**

**Definition.** The ADR names two options as both valid, depending on unspecified context. The decision is deferred; the document does not commit.

**Symptoms.** "We use X for cases A and Y for cases B, where A and B are defined by the team as needed."

**Smell test.** Is there a rule that determines which option applies? If not, the ADR is not a decision.

**Fix.** Pick one; or write two ADRs (one for case A, one for case B) with explicit criteria; or flag as an open question with owner and due date.

**Citation.** Brown et al. 1998.

### ADRs written for trivial decisions

**RESEARCH-2026-04.md section 7.2.**

**Definition.** ADRs for decisions too small to warrant recording. "ADR-042: Use tab-indented YAML." Dilutes the corpus; new engineers cannot distinguish load-bearing ADRs from noise.

**Symptoms.** ADRs about code style, tool configuration, folder structure, or personal preferences.

**Smell test.** Would reversing this decision require any coordination across the team? If not, it is not an architectural decision; it is a style preference.

**Fix.** Move to the style guide / coding standards doc. Keep ADRs for decisions with a flip point and a blast radius.

**Citation.** RESEARCH-2026-04.md section 7.2.

### ADR that supersedes never written

**RESEARCH-2026-04.md section 7.2.**

**Definition.** A decision is reversed; the old ADR is silently abandoned; no new ADR supersedes it. Readers 6 months later cannot tell which of two conflicting ADRs is current.

**Symptoms.** An ADR marked Accepted from 2024 contradicts the running system. No ADR references or supersedes the old one.

**Smell test.** For every Accepted ADR, does the running system match? If any does not, either the system has drifted (Ghost Architecture) or the ADR was superseded without a record.

**Fix.** Write the superseding ADR; mark the old one `Superseded by ADR-NNN`; link forward and backward. Use `adr link N supersedes M` if using Pryce's adr-tools.

**Citation.** RESEARCH-2026-04.md section 7.2; SKILL.md Step 8.

### ADRs in a wiki instead of the repo

**RESEARCH-2026-04.md section 7.2.**

**Definition.** ADRs live in Confluence, Notion, Google Docs, or any system separate from the code. Go stale within 6 months because no one reviews them in PRs. Cannot be versioned with the code; cannot be diffed; cannot be searched alongside git history.

**Symptoms.** The ARCH.md points at Confluence for ADRs. The team has "historical ADRs" in a Google Doc. The repo has no `adr/` directory.

**Smell test.** `ls .architecture-ready/adr/`. If empty or missing, ADRs are elsewhere and likely stale.

**Fix.** Migrate to `.architecture-ready/adr/NNN-slug.md`; review in PRs; version with code.

**Citation.** RESEARCH-2026-04.md section 7.2.

## 9. Evolutionary-architecture antipatterns

See evolutionary-architecture.md Section 10 for the full treatment. Summarized here:

- **Fitness functions named but not wired.** The Tier 3 disqualifier. Remediation: wire one, seed one violation, show the commit.
- **So many fitness functions no one can ship.** Rewrite to catch the class, not the instance. Audit override-annotation counts monthly.
- **Fitness functions catching business logic.** Move to regular tests. Fitness functions guard architectural invariants only.
- **No supersession discipline on ADRs.** Every ADR change is paired with a fitness-function diff.

## 10. The substitution test applied at the architecture level

The substitution test is the single most efficient audit tool at the architecture tier. Read the ARCH.md. For any component, data-shape decision, integration pattern, or NFR claim, substitute a near-equivalent. If the rationale still reads plausibly, the rationale decided nothing specific.

### Worked example: a bad ARCH section rewritten

**Before (horoscope / stackitecture).**

> **System shape.** We are building a modern scalable cloud-native microservices architecture using Kubernetes for orchestration, Kafka for event streaming, and Postgres for durable storage. The architecture supports horizontal scaling, high availability, and observability through industry-standard tooling. Services are loosely coupled and independently deployable, enabling rapid iteration and strong team autonomy.

Substitution test. Replace "Kubernetes" with "ECS Fargate," "Kafka" with "SQS," "Postgres" with "MySQL." The paragraph still reads plausibly. Replace "microservices" with "modular monolith." Still plausible. Replace the product entirely: this could be for an orders system, a ride-sharing app, a healthcare platform, or a fintech ledger. Still plausible. Every sentence passes substitution. The section decides nothing.

**After (specific, load-bearing).**

> **System shape.** Modular monolith on a single Postgres database. Three internal bounded contexts (Orders, Inventory, Identity) enforced by Packwerk at CI. The PRD's 12-month scale ceiling is 25K org-users and 50 requests per second sustained at peak; a single 4-vCPU Rails instance handles this with headroom. The team is four engineers; Team Topologies' single-cognitive-load threshold is roughly 5-7 engineers (Skelton / Pais 2019); microservices add at least 3x ops overhead that we cannot absorb. We reject microservices because no forcing function applies (team size, independent scaling curve, or regulatory boundary all point to modular monolith). We reject event-driven because the integration pattern is sync request-response for every primary user flow in the PRD. **Flip point.** We would reverse this decision if the team grows past 20 engineers, if the scale ceiling moves above 500 requests per second sustained, or if a regulatory boundary (e.g., HIPAA carve-out for a separate PHI-processing component) requires physical isolation. **Blast radius if wrong.** A rearchitecture to services would take 6-12 months and stop feature development; we estimate 3 engineer-years of effort. We mitigate by keeping Packwerk boundaries enforced from day one so the eventual extraction is mechanical.

Substitution test on the rewrite. Replace "Packwerk" with "ArchUnit": the paragraph breaks because Packwerk is specific to Ruby and the team is Ruby. Replace "4 engineers" with "30 engineers": the paragraph breaks because the flip point already names the threshold. Replace "Orders, Inventory, Identity" with generic names: the paragraph breaks because the PRD's bounded contexts are specific. Replace "modular monolith" with "microservices": the paragraph contradicts itself. Every load-bearing element resists substitution. The section decides something.

### The rule

If any paragraph in ARCH.md survives the substitution test, it is horoscope / stackitecture / theater. Rewrite until the prose breaks when substituted. This is tedious; it is also the fastest way to raise the signal-to-noise ratio of an AI-generated or AI-assisted ARCH.md.

## 11. Historical antipatterns still worth knowing

Shorter entries for antipatterns that are older, better-known, and less common in pure AI-slop but still show up in hybrid AI-plus-human-written architecture.

### Inner platform effect

**Described throughout programming folklore; catalogued by Wikipedia.**

**Definition.** Building a generic customizable system on top of a generic customizable system. "We will build a rules engine on top of the workflow engine." The new system ends up reimplementing features of the underlying platform, badly.

**Smell test.** Does the system expose a DSL for configuration? Does the DSL reimplement features that the host language already provides? If yes, inner platform.

**Fix.** Use the host platform directly. Accept less flexibility; ship sooner; add flexibility later with concrete data.

### Magic pushbutton

**Brown et al. 1998.**

**Definition.** A button in the UI that triggers a long, opaque cascade of operations across the system. "Sync," "Refresh," "Update Everything." No observability into what happens when the button is pressed.

**Fix.** Break into explicit steps; add observability per step; allow partial retries.

### Vendor lock-in as the architecture

**Brown et al. 1998; sometimes acceptable.**

**Definition.** The architecture is "use vendor X's full stack." Sometimes the right call (deep integration yields benefits); often a risk (vendor changes pricing, discontinues product, or acquires a competitor).

**Smell test.** Ask: "what is the migration path if vendor X doubles its price or is acquired?" If the answer is "rewrite the system," lock-in is load-bearing. Flag explicitly; trade the risk for the speed knowingly.

**Fix.** Name the lock-in as an ADR; document the migration cost; revisit annually.

### Microservices envy

**Informal; sibling to resume-driven architecture.**

**Definition.** The team wants to be like Netflix / Amazon / Uber because the engineering blog is cool. Adopts microservices to emulate the aesthetic, not to solve a constraint.

**Fix.** Name the PRD constraint that forces microservices; if no constraint, modular monolith.

### Microkernel overreach

**Adjacent to speculative generality.**

**Definition.** Designing a microkernel-style plug-in architecture for a product that will never have a third-party plug-in. "We will let users write extensions." Nobody does. The overhead is permanent; the benefit is hypothetical.

**Fix.** Ship without the plug-in architecture. Add it later, after three concrete extension requests are on the roadmap.

### Enterprise-service-bus hangover

**Described in Hohpe / Woolf 2003 and in the 2010s microservices-renaissance literature.**

**Definition.** Centralizing all inter-service communication through a single message bus that also does routing, transformation, and orchestration. The bus becomes a monolith of its own; changes to it block every service.

**Fix.** Pick a simpler broker (SQS, Kafka, RabbitMQ) that does delivery only; keep routing, transformation, and orchestration in the services.

### Shared-database integration

**Newman 2019; Kleppmann 2017.**

**Definition.** Different services integrate by reading and writing to the same database. Shared schema as a contract. Coupling is invisible from the code; schema changes block multiple teams.

**Fix.** Move to API- or event-based integration; each service owns its data; inter-service reads go through an interface.

End of architecture-antipatterns.md.
