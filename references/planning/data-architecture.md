# Data Architecture

The Step 4 protocol. Entities, storage shapes, tenancy, lifecycle, consistency, and the discipline that keeps "just use Postgres" from eating the design decision before it gets made.

**Scope owned by this file:** the data-shape decisions that precede and constrain stack-ready's database pick. The entities are from the PRD; the storage shape is from here; the specific database is from stack-ready. Confusing those three layers is how architecture-ready's most important section becomes its most handwaved section.

## Section 1. Why data architecture precedes stack selection

Data outlives code. A rewritten service is a quarter of work; a re-shaped schema for a ten-million-row table is an engineering program, a migration rollback plan, a comms plan, and an incident in waiting. Once entities are live in production with foreign keys, indexes, triggers, reports, and external integrations reading off them, the shape of the schema is load-bearing for every component that touches it. "We'll migrate it later" is the most expensive sentence in software after "we'll add tests later."

The industry's canonical treatment is Martin Kleppmann's "Designing Data-Intensive Applications" (O'Reilly, 1st ed 2017, ISBN 978-1-449-37332-0), chapters 5-9 in particular: replication, partitioning, transactions, consistency, stream processing. The 2nd edition, with Chris Riccomini, had early release in March 2025 and general availability in January 2026 (RESEARCH-2026-04.md section 3.10); the 2nd edition adds modern material on stream processing, change data capture, and the practical consequences of 2017-2025 data-infrastructure evolution. If you are writing data architecture in 2026 and have not read Kleppmann cover to cover, you are guessing. Pat Helland's corpus complements Kleppmann on the distributed-data shape: "Life beyond Distributed Transactions" (CIDR 2007; ACM Queue 2016) and "Immutability Changes Everything" (ACM Queue 2015; CACM 2016) are the two papers every architect picking an event-driven or append-only shape needs in hand (RESEARCH-2026-04.md section 3.11).

The division of labor between architecture-ready and stack-ready is simple and strict. **architecture-ready decides shape.** "This workload is transactional relational OLTP with moderate read-write volume and strong consistency on order totals." "This workload is append-only event log with 7-year replay requirement for regulatory audit." "This workload is key-value with 10ms p99 read latency, no relational queries." **stack-ready decides brand.** Postgres vs. MySQL vs. CockroachDB vs. Spanner for the relational OLTP. Kafka vs. Kinesis vs. Redpanda vs. Pulsar for the event log. Redis vs. DynamoDB vs. Cloudflare KV for the key-value. Confusing the two is **stackitecture** (RESEARCH-2026-04.md section 2.4): the stack choice is made first, dressed up as an architecture section, and the shape question is never asked. The most common stackitecture failure is "we're using Postgres, so everything goes in Postgres," which lands tables that want to be time-series, graph, search-indexed, or blob storage into a relational OLTP engine that handles them poorly.

The test for whether this section is doing its job: at the end of Step 4, a downstream stack-ready session reads the storage-shape list and can run its pre-flight without the user answering any further data-shape question. If stack-ready has to ask "is this workload relational or event-log-shaped?" because architecture-ready's data section just said "Postgres," the data architecture is stackitecture, not architecture.

## Section 2. The nine storage shapes

Name the shape, not the database. The rule that precedes every entry in this section: when you write "Postgres" in Step 4, stop and replace it with the shape ("relational OLTP"). If that feels wrong, the reason is usually that you were picking the database before the shape, which is the whole failure mode this section exists to prevent.

### 2.1 Relational / OLTP (row-oriented, transactional, strong-consistency)

**What it is.** Rows in tables with declared columns, foreign-key relationships, ACID transactions across rows in the same database. The shape that powers the majority of business software on the planet since 1979. Normal forms, joins, transactional integrity, SQL as the query language.

**When it wins.** Entities with relationships. Transactions that must span multiple rows atomically (order plus line items; account balance plus ledger entry; user plus permission grant). Strong-consistency needs (accounting, inventory, identity, anywhere a stale read is a correctness bug, not a UX bug). Workloads where the total row count per table stays in the millions to low billions, not the tens of billions.

**When it loses.** Time-series at high ingest rates (millions of rows per minute degrade OLTP engines). Schemaless or highly variable-schema data where every document has different fields. Workloads where the query pattern is overwhelmingly graph traversal (multi-hop "friends of friends of friends"). Workloads where the query pattern is full-text search with relevance ranking. Workloads with blob data larger than the page size (images, video, documents); the row-oriented engine is a bad fit for BLOB storage even when it supports it.

**Canonical example shape.** E-commerce orders and line items; SaaS accounts, users, subscriptions, and invoices; CRM contacts, deals, and activities; ticketing workflows; HR employees, positions, and pay events. Pat Helland's "inside data": the authoritative, current, referentially-complete state (Helland, "Data on the Outside Versus Data on the Inside," CIDR 2005).

### 2.2 Document (JSON-shaped, schema-flexible, read-heavy)

**What it is.** Self-contained JSON or BSON documents keyed by an ID, with flexible sub-structure. Secondary indexes on document fields. Queries by ID or by indexed field. No cross-document joins in the transactional sense; some engines add aggregation pipelines.

**When it wins.** Content-oriented data with variable shape (product catalogs with dozens of category-specific attributes; CMS content where each page type has different fields; user-generated form responses with per-form schemas). Read-heavy workloads where the read is "fetch the whole document for this page." Workloads where schema evolution is frequent and small, and the alternative would be many nullable columns or an EAV anti-pattern. Early-stage products whose schema is genuinely unknown and will change weekly.

**When it loses.** Workloads with cross-entity transactional integrity (charging a card and crediting an account atomically). Workloads where the read pattern is "join A to B to C with a filter on D"; document stores handle that poorly, and the application-level join is slow, error-prone, and usually a signal the shape is wrong. Workloads where the schema is actually stable, and the document store is being used because "schemaless is flexible"; Helland's "Immutability Changes Everything" on the discipline required for flexible schemas: the invariant moves from the database to the application, and that is a real cost, not a free benefit.

**Canonical example shape.** Product catalog with heavy variant diversity; headless CMS content; user-profile sub-documents with optional sections; webhook event payloads for inbound integrations where the shape is partner-dictated.

### 2.3 Key-value (fast lookup, simple structure)

**What it is.** A single key maps to a single value (string, hash, set, list). O(1) lookups. No secondary indexes in the pure form; no cross-key transactions in the strict form, though some engines offer per-key CAS or multi-key transactions with caveats.

**When it wins.** Session state. Rate-limiting counters. Feature-flag lookups. Short-lived cache entries. Short-TTL derived data that must be fast but can be recomputed if lost. Idempotency keys (dedup window tables). Anywhere the access pattern is "given this key, get this value in under a millisecond."

**When it loses.** As a general-purpose datastore. The absence of relationships, of secondary indexes, of transactional joins means application code has to carry all of that; the app becomes a database-in-the-app. Workloads that need queries like "all users who joined this month" are not key-value workloads; forcing them is a Golden Hammer (Brown et al., "AntiPatterns," Wiley, 1998).

**Canonical example shape.** Redis-shaped cache; DynamoDB-shaped single-item lookups; Cloudflare KV; session store behind a stateful auth system. Pat Helland's observation that "inside data" can be cached as "outside data" aligns with this shape: the cache is a projection, not the source of truth.

### 2.4 Time-series (append-only, time-indexed, aggregation-heavy)

**What it is.** Rows keyed by a timestamp and one or more series identifiers (device ID, metric name, tenant ID). Append-only in the typical case. Queries are overwhelmingly "time-window aggregation": p95 latency over the last hour, request count per minute for the last day, temperature readings for this device between these two dates. Retention policies are load-bearing: raw data for a week, 1-minute rollups for a month, 1-hour rollups for a year, aggregates forever.

**When it wins.** Operational metrics. Audit logs at high volume. IoT sensor data. Financial tick data. Analytics events where the dominant access pattern is "aggregate this window." The access pattern is write-heavy and read-analytical, which OLTP row-stores handle poorly and dedicated time-series engines handle with orders-of-magnitude better storage and query efficiency.

**When it loses.** Workloads with random-access reads on historical data ("give me the exact reading from this device on this date two years ago"); time-series engines can serve that but the shape is wasted. Workloads with cross-series transactional updates; time-series is append-only in the typical case and the shape resists mutable history.

**Canonical example shape.** TimescaleDB-shaped (Postgres plus time-series extension); InfluxDB-shaped (purpose-built); Prometheus (operational metrics only); ClickHouse (columnar, overlaps with OLAP). The shape decision is distinct from the engine; stack-ready picks among the engines.

### 2.5 Event log (immutable, append-only, ordered)

**What it is.** An ordered, partitioned log of events. Each event is immutable, append-only, durably persisted. Consumers read from offsets; the log is the source of truth for the sequence of events. Retention is typically days to weeks to months; compacted logs retain the latest value per key indefinitely. Pat Helland's "Immutability Changes Everything" is the foundational paper: once events are immutable, they can be replayed, re-projected, cached aggressively, and distributed without coordination.

**When it wins.** Systems where the audit trail is the product: regulatory replay, financial-ledger reconstruction, partner-event sourcing. Systems with multiple independent consumers that each project a different read model off the same event stream (CQRS shape, when justified). Systems that need to rebuild a corrupt or lost read model by replaying the log. Systems where services integrate asynchronously and the log is the contract.

**When it loses.** Systems where the primary access pattern is "fetch current state"; event logs without a materialized read model force consumers to fold events to compute state, which is slow. Simple CRUD systems where the audit log is a nice-to-have, not a load-bearing feature; a history table or append-only audit table in the relational store covers 80% of the audit value with 10% of the operational cost. The "whole system on event sourcing" antipattern (RESEARCH-2026-04.md section 4.5; InfoQ 2016) is the most commonly over-prescribed version of this shape.

**Canonical example shape.** Kafka-shaped log (durable, partitioned, multi-consumer); Kinesis-shaped stream; EventStoreDB's event-sourcing shape where the log IS the authoritative state.

### 2.6 Search (inverted index, relevance-ranked)

**What it is.** Text documents indexed token by token, with relevance scoring (TF-IDF, BM25, or learned-rank variants). Queries return ranked results, not exact-match sets. Secondary structures support faceting, filtering, and aggregation. The query language is "text match plus filters," not relational joins.

**When it wins.** Full-text search with relevance. Faceted search (e-commerce filters, job-board filters). Log search (find the request ID across a billion log lines). Autocomplete and type-ahead. Any workload where "find the most relevant N results" is the question, and where exact-equality SQL `LIKE` queries would either be slow or return the wrong thing.

**When it loses.** As a primary transactional store. Search indexes are near-real-time at best; they are derived views. Using the search index as the source of truth is a category error. Workloads with structured queries ("find all orders where status = 'shipped' and total > $100") where a relational index is both faster and exact.

**Canonical example shape.** Elasticsearch-shaped; OpenSearch; Meilisearch; Typesense; Postgres `tsvector` for small-scale integrated text search. The shape is "inverted index with relevance"; the engine is a downstream pick.

### 2.7 Graph (traversal, relationship-first)

**What it is.** Nodes and edges as first-class citizens. Queries traverse relationships: "friends of friends of friends," "shortest path from A to B," "all accounts linked by shared IP or device ID within three hops." The query language is traversal (Cypher, Gremlin, SPARQL), not joins. Storage is optimized for following edges, not for scanning tables.

**When it wins.** Social graphs (who follows whom, who is connected to whom). Organization charts (reporting hierarchy with arbitrary depth). Fraud-ring detection (which accounts share signals through N hops). Recommendation engines ("users who bought X also bought Y, which is connected via Z"). Access-control graphs (ReBAC, Zanzibar-shaped permissions). Any workload where the fundamental operation is "follow this edge N times."

**When it loses.** Workloads where graphs are incidental (most business applications have some many-to-many relationships; that does not make them graph workloads). Workloads where the relationship depth is bounded at 1-2 hops; relational joins handle those well, and a dedicated graph engine is overkill. Early-stage products where the shape is unclear; starting with a graph engine when a relational store would work is resume-driven architecture (RESEARCH-2026-04.md section 1.5).

**Canonical example shape.** Neo4j-shaped property graph; NebulaGraph; JanusGraph; Postgres with recursive CTEs for small scale. For the permission-graph subcategory: Google Zanzibar-inspired systems (SpiceDB, Ory Keto, AuthZed).

### 2.8 Object store (blob, large, read-heavy)

**What it is.** Key-to-blob storage optimized for large objects (KB to TB). Writes are typically whole-object puts; reads are whole-object gets or ranged reads. No relational queries; no secondary indexes in the pure form. Durability and cost per byte are the dominant design points, not latency.

**When it wins.** Images, videos, audio, documents, backups, logs-as-files, data-lake source files, ML model artifacts, large analytics exports. Any workload where the object is the unit and the question is "retrieve by key." Multi-region replication, lifecycle policies (move to cold storage after N days), and access control at the bucket level.

**When it loses.** As a transactional store. Object stores do not support partial updates efficiently; they do not support relational queries; they do not support strong consistency across objects (some provide per-object strong read-after-write, but not cross-object). Using S3 as a database is a category error the same way using Redis as a document store is.

**Canonical example shape.** S3-shaped (AWS S3, Cloudflare R2, GCS, Azure Blob, MinIO, Backblaze B2). The shape is "object store"; the vendor is a stack-ready decision.

### 2.9 Columnar / OLAP (column-oriented, analytical, aggregation-heavy)

**What it is.** Data stored in columnar format (all values of column A contiguously, then all values of column B, and so on), optimized for scans over huge volumes and aggregation across millions to billions of rows. Queries are analytical: GROUP BY, aggregation, window functions, rollups. Insert patterns are batch or micro-batch; row-level updates are expensive or unsupported.

**When it wins.** Data warehouses. Business-intelligence dashboards. Analytics workloads that scan terabytes per query. Reporting against denormalized fact tables with dozens of dimension joins. Workloads where "sum this metric across these slices" is the fundamental question and the answer requires scanning a large volume.

**When it loses.** Transactional workloads. Row-level OLTP operations. Workloads with sub-second single-row reads and writes; OLAP engines optimize the wrong thing. The common mistake is running ad-hoc analytics on the OLTP store (slow, contends with production traffic) or running OLTP transactions on the OLAP store (slow, loses correctness guarantees). The HTAP ("hybrid transactional-analytical processing") category exists precisely because separating OLTP and OLAP is the normal state of affairs.

**Canonical example shape.** Snowflake-shaped cloud warehouse; BigQuery; Redshift; Databricks; ClickHouse; DuckDB (embedded); the "lakehouse" shape (Parquet on object storage plus a query engine). The shape is columnar analytical; the specific engine is a downstream pick.

### The shape-to-engine mapping is one-to-many

Every shape has multiple engines that implement it; stack-ready's job is to pick among them. What architecture-ready commits to is the shape. "Relational OLTP" does not commit to Postgres; it commits to "row-oriented, transactional, strong-consistency, relationship-first." Stack-ready then chooses Postgres, MySQL, CockroachDB, or Spanner based on scale ceiling, operational tolerance, team familiarity, and the other 11 dimensions in its scoring framework. If Step 4 writes "Postgres" instead of "relational OLTP," it has foreclosed stack-ready's scoring pass.

## Section 3. Entities and relationships (ERD at the architectural level)

The PRD's entities are the starting point. architecture-ready does not invent entities; it takes the PRD's entity list and refines it into a shape a downstream team can build against.

### Top 5-15 entities

Name the top entities, no more than 15 at this tier. Deeper entity detail (sub-entities, attributes per entity at the column level, validation constraints) belongs in production-ready's schema work. What architecture-ready names is the entity set that carries the domain's load: the nouns a conversation with the product team returns to repeatedly.

For a SaaS order-management system: Organization, User, Product, SKU, Order, LineItem, Payment, Shipment, Refund, AuditEvent. That is 10. Adding Discount, PromoCode, Wishlist, Cart, Review would push to 15; those are genuinely distinct entities with their own lifecycle and relationships, not attributes hung off another entity. Adding User.FirstName, User.LastName, User.Phone is attribute-level and does not belong here.

If the entity list exceeds 15, the domain is probably compound (ordering plus shipping plus customer-support plus marketing plus analytics all in one list). Split by bounded context and name the entities per context.

### Cardinality

For each relationship between entities, name the cardinality: one-to-one, one-to-many, many-to-many. One-to-many is the dominant case (one Organization has many Users; one Order has many LineItems). Many-to-many requires a join entity and the join is itself a domain concept (OrderProduct is the wrong name; LineItem or OrderItem is the right name, and it has its own attributes like quantity and price-at-time).

### Inheritance vs. composition

If the domain has multiple types that share attributes (PhysicalProduct and DigitalProduct; CreditCardPayment and WirePayment; IndividualUser and OrgUser), choose: inheritance (single-table with a discriminator column, or class-table inheritance), composition (a base entity plus a typed sub-entity with a foreign key), or polymorphism (separate tables with a shared interface at the application layer).

The rule: **polymorphism is almost always wrong at the data layer** for persistent entities. "Attachable" or "Commentable" abstract types with polymorphic foreign keys (Comment.commentable_type, Comment.commentable_id) produce databases the query planner cannot optimize, joins the ORM cannot express naturally, and referential integrity the database cannot enforce. The correct shape in almost every case is a separate foreign-key column per attached entity (Comment.order_id, Comment.product_id, Comment.ticket_id, nullable), or separate comment tables per attaching entity (OrderComment, ProductComment, TicketComment). This is ugly; polymorphism is uglier once the system has run for two years.

### Soft delete is a decision

"Should we soft-delete?" is an architectural decision, not a default. Options:

- **Hard delete.** Row is gone. Foreign-key relationships must be resolved (cascade, set null, restrict). Simplest shape. Correct default unless a regulatory or product requirement says otherwise.
- **Soft delete with `deleted_at` column.** Row stays; application-layer queries filter `deleted_at IS NULL`. Requires discipline to never miss the filter; easy to leak deleted rows in joins, reports, or new queries. Partial indexes can enforce "unique among non-deleted."
- **Soft delete with shadow table.** Row is moved to a `deleted_orders` table on delete. Active table stays clean; deleted data is queryable separately. More migration ceremony but fewer query-level bugs.
- **Tombstone with retention policy.** Row stays, with `deleted_at`, for a fixed window (30 days, 7 years), then hard-deleted. Bridges soft-delete convenience with eventual data minimization (GDPR right-to-erasure).

The decision is an ADR. The rationale must cite a PRD constraint (undo requirement, regulatory retention, audit trail, reporting need). "Soft delete as a default" is not a decision; it is a habit, and it is one of the most common causes of surprise data leaks.

### Foreign keys as constraints vs. guidance

Foreign keys in the database enforce referential integrity. The alternative is to declare the relationship in application code and let the database not care; this is sometimes called "soft foreign keys" or "application-enforced referential integrity."

**Rule: declare foreign keys at the database level for all relationships inside a single bounded context.** The database is the last line of defense against orphan rows; application-level constraints fail every time someone writes a script that bypasses the ORM.

**Exception: cross-context relationships do not get foreign keys.** If Order has a `customer_id` that references the Customer entity owned by a different service (or a different schema in a modular monolith), a database-level foreign key couples the schemas across the service boundary and defeats the purpose of the boundary. Use an application-level identity instead and accept that eventual consistency applies (a deleted Customer may have dangling references in Orders, handled explicitly: block the deletion, archive the customer, or repair the references with a backfill).

## Section 4. Tenancy models

Multi-tenancy is a trust boundary. Every shared-tenant system is one query away from cross-tenant data leakage; the architecture commits to the isolation model, and trust-boundaries.md consumes that commitment.

### 4.1 Single-tenant

One tenant per deployment. One database, one app, one customer. The shape for on-premise enterprise software, regulated-industry deployments where multi-tenancy is contractually forbidden, and the early phase of a SaaS business where customers are configured manually.

**Wins:** maximum isolation; no cross-tenant bug possible because there is no cross-tenant shared state; compliance is simpler (each customer's deployment is in their own blast radius). **Loses:** operational cost scales linearly with customer count; every customer is a separate deploy, a separate patch, a separate backup; the cost curve is brutal above a few dozen tenants.

### 4.2 Multi-tenant shared-schema with tenant-column filter

One database, one schema, one set of tables. Every tenant-scoped table carries a `tenant_id` (or `organization_id`, `account_id`) column. Every query filters by it. Row-level security at the database level, application middleware, or both, enforces the filter.

**Wins:** lowest operational cost per tenant; single deploy, single backup, single migration. The default for most B2B SaaS. **Loses:** every query is one WHERE clause away from leaking across tenants. A single missed filter (in an ORM query, a raw SQL report, an analytics dashboard, a Zapier integration) is a cross-tenant breach. The boundary is in code, not in the schema; code rots faster than schemas.

The defense-in-depth pattern: enable database-level row-level security (Postgres RLS, SQL Server RLS, Oracle VPD) so the database enforces the filter even if the application forgets. Plus an integration test in CI (a tenant-isolation fitness function, Step 10) that attempts cross-tenant reads from a test user and asserts the query returns zero rows or errors.

### 4.3 Multi-tenant per-tenant schema

One database, one tenant per schema. Tables are identical across schemas; the schema name is the tenant identifier. Queries reference `tenant_<uuid>.orders` instead of `orders`.

**Wins:** stronger isolation than shared-schema (a schema-level permission miss is less likely than a WHERE-clause miss); easier per-tenant backup, restore, and export; simpler tenant deletion (drop the schema). **Loses:** database-level limits on schema count (Postgres handles thousands of schemas well, tens of thousands with degradation); migrations must run against every schema (slow, error-prone); cross-tenant queries (product-level analytics, admin dashboards) require UNION ALL across schemas or a separate warehouse.

### 4.4 Multi-tenant per-tenant database

One database per tenant. Same engine, same schema, separate physical storage. Tenants are physically isolated at the database level.

**Wins:** strong isolation; per-tenant compliance posture (a tenant requiring data residency in a specific jurisdiction can have their database in that jurisdiction); per-tenant backup, restore, encryption key, and retention policy. **Loses:** highest operational cost of the shared-tenant variants; migrations must run against every database; cross-tenant queries are difficult; database-proliferation management is a full-time job above a few hundred tenants.

### 4.5 The tenancy decision as a trust-boundary commitment

The tenancy model is the tenant-isolation trust boundary. See trust-boundaries.md Section 4. A cross-tenant data leak is a catastrophic incident: regulatory reporting obligations, customer notification, loss of trust, often an exit of the founding deal. The tenancy model is the spec; the implementation is how defense-in-depth gets layered:

- Shared-schema with tenant-column filter: row-level security plus middleware plus integration tests. Three layers.
- Per-tenant schema: schema-level permissions plus middleware plus integration tests. Three layers.
- Per-tenant database: connection-routing at authentication time plus per-tenant credentials plus integration tests. Three layers.

Single-layer isolation is an accepted risk that must be explicitly stated in an ADR. "We filter by tenant_id in middleware and accept that a direct-SQL-access path would bypass isolation" is a real decision; call it out or add the defense-in-depth layer.

### Cost vs. isolation trade-off

The trade-off is monotone: more isolation costs more to operate. The decision is a function of the PRD's compliance posture, the customer mix (a few large enterprise customers push toward per-tenant database; many small customers push toward shared-schema), and the team's operational maturity. Changing tenancy later is a migration of existential magnitude; pick once, defend the pick in the ADR, and do not drift.

## Section 5. Data lifecycle

Each entity has a lifecycle. The architecture commits to it; stack-ready picks the retention features in the engine.

### 5.1 Immutable

The entity is written once and never changed. Updates create new rows; "the current value" is derived from the latest row by key. Audit logs, event-log events, blockchain-style ledgers, financial postings are immutable by design.

**When to pick.** Regulatory requirements mandate no-modification-after-write (SOX for financial records, HIPAA for certain medical records, blockchain ledgers). Pat Helland's "Immutability Changes Everything" is the theoretical backbone: immutable data can be cached, replicated, and distributed without coordination, which is a major architectural simplification when the domain supports it.

### 5.2 Append-only

The entity accepts inserts but not updates or deletes. The storage shape is naturally append-friendly (event log, time-series). The difference from immutable is that append-only allows new rows that supersede old rows; the old rows stay.

**When to pick.** Event logs, telemetry, audit trails, any workload where "what happened, in order" is the primary question. Retention policies are load-bearing (how far back must the log be queryable; how old can rows be before rollup or deletion).

### 5.3 Mutable with version history

The entity supports updates; each update stores the prior version in a history table or a version column. "Current" is the latest version; "historical" is queryable. Git is the archetype.

**When to pick.** Content that changes but needs an edit history (CMS pages, wiki articles, legal contracts, configuration that must be auditable). Reversible changes are a product requirement.

### 5.4 Mutable with soft-delete

The entity supports updates and deletes, but delete means `deleted_at IS NOT NULL`, not a physical DELETE. See Section 3's soft-delete decision discussion.

### 5.5 Mutable with hard-delete

The entity supports updates and deletes, and delete means physical DELETE. The row is gone.

**When to pick.** The default unless a constraint says otherwise. Hard-delete is simpler, cheaper, and avoids the class of bugs where soft-deleted rows leak through unfiltered queries.

### 5.6 Retention policies

Every entity group that stays in the system forever is carrying cost forever. The retention policy is architectural because it constrains the storage shape (time-series engines are built for retention policies; relational OLTP engines need per-table partitioning and manual archival).

**Regulatory drivers:**

- **HIPAA.** Medical records: typically 6 years from creation or last effective date (42 CFR 482.24(b)(1)); state laws override upward (some states require longer). Audit logs: minimum 6 years.
- **GDPR.** Data minimization: personal data must not be kept longer than necessary for the purpose. Right-to-erasure: subjects can request deletion; the architecture must support it. See also Section 10.
- **SOC 2.** No mandated retention window; controls must document and enforce whatever window is stated. Typically 1-7 years for audit logs.
- **PCI DSS.** Cardholder data: must not be stored beyond business justification; CVV never stored post-authorization; audit logs minimum 1 year with 3 months immediately available (PCI DSS 4.0 requirement 10.5.1).
- **SOX.** Financial records: 7 years minimum (17 CFR 240.17a-4).

**Contractual drivers.** Customer contracts often override regulatory minima (enterprise customers demand 7 years even when regulation says 3).

**Data-residency drivers.** GDPR and some national regulations constrain where data can physically reside (EU data in EU; China's PIPL; Russia's data-localization law). The architecture commits: which entity groups are residency-constrained, and what deployment shape enforces the constraint (per-region database, per-region deployment, data-residency aware routing).

Retention policy decisions are ADRs. Every regulated entity group gets one.

## Section 6. Consistency and invariants

The architectural-level consistency question: strong or eventual, per entity group.

### Strong consistency

Reads see the latest write. The guarantee the relational OLTP shape provides within a single database. Cross-database or cross-region distributed-strong-consistency costs throughput and latency, and Brewer's CAP theorem says a network partition forces a choice between consistency and availability.

**Pick when.** Accounting, inventory, identity, authorization: any read that is a correctness bug if stale. "Account balance" and "available inventory" and "is this user allowed to do X" must see the latest write.

### Eventual consistency

Reads may lag writes by some window. The guarantee most distributed systems settle for when strong consistency is too expensive.

**Pick when.** Analytics, recommendations, derived views, caches, search indexes, CDC-fed read models. Users tolerate a 1-second or 1-minute delay between "I just updated my profile" and "the profile shows the update in the search result." The architecture makes the window explicit.

### Cross-entity invariants

For every invariant that spans multiple entities, name: (a) the invariant, (b) the enforcement point, (c) the consistency guarantee.

Example invariants:

- "An order's total equals the sum of its line items' prices at commit time." Enforcement: transactional within the Orders schema, in the same local transaction that creates the order. Consistency: strong.
- "A user cannot have both an active subscription and a cancelled one for the same product." Enforcement: unique partial index on the subscription table. Consistency: strong.
- "An inventory decrement cannot produce a negative count." Enforcement: application-level with row-level lock plus CHECK constraint; stack-ready picks whether the engine supports SELECT FOR UPDATE or optimistic concurrency with version columns. Consistency: strong.
- "The user's notification-preference-changed event eventually produces an updated cache entry." Enforcement: async event consumer. Consistency: eventual, bounded at 60 seconds.

Invariants that span services (Orders service, Inventory service) cannot be enforced transactionally without distributed transactions, which are a red flag (see 6.3).

### 6.3 The outbox pattern for dual-write avoidance

The dual-write problem: an application writes to the database and emits an event (to a queue, an event log, or a webhook). If the write succeeds and the event emit fails, the system is inconsistent; if the emit succeeds and the write fails, the system is inconsistent.

The outbox pattern solves it: the application writes to the database AND inserts an event row into an `outbox` table in the same local transaction. A separate process (a CDC reader, a polling worker) reads the outbox and emits events to the external system at-least-once, deleting or marking as sent after acknowledgement. The database is the single source of truth for "did this happen"; the event emit is a downstream concern with retry and idempotency.

**When the integration architecture involves any service-to-service event emit tied to a local mutation, the outbox pattern is the default.** Not outbox is an explicit decision with a rationale (the emit is tolerant of loss, or the dual-write risk is accepted with a reconciliation job).

### 6.4 Distributed transactions as a red flag

Distributed transactions (XA, 2PC) span multiple databases or services with ACID guarantees across the span. They work in theory. In practice: the coordinator is a SPOF; the failure modes are baroque; performance is poor; most modern stacks (cloud databases, managed services, message brokers) do not support them.

Pat Helland's "Life Beyond Distributed Transactions" (CIDR 2007, ACM Queue 2016; RESEARCH-2026-04.md section 3.11) is the canonical argument for why distributed transactions are a dead end for scalable systems. The alternatives: compensating transactions (saga pattern, see integration-architecture.md Section 5), outbox pattern, eventual consistency with reconciliation.

**Rule: if the architecture proposes distributed transactions, it is wrong.** Either the services should be merged (the transaction boundary should contain all the writes), or the consistency requirement should be relaxed to eventual with an explicit reconciliation mechanism.

## Section 7. Data ownership rule

**One writer per entity. Many readers acceptable.**

Every entity in the architecture has exactly one component that can write it. Other components may read (via API, via a projection, via read-replica, via event consumption) but not write. The writer is the source of truth; its invariants are the invariants; its schema is the contract.

Violations of this rule are the **distributed monolith** antipattern (RESEARCH-2026-04.md section 2.6; Sam Newman, "Monolith to Microservices," 2019). Two services writing to the same table couples them forever: their schemas cannot evolve independently, their deploys cannot be decoupled, their transactions interleave in ways neither owns, their invariants depend on each other's code paths. The team gets all the operational cost of two services and none of the independence.

Detection: for every entity, state the writer. If the answer is "A and B, depending on the flow," either merge A and B (the boundary was drawn wrong), or split the entity (the entity is two entities wearing a trench coat), or designate one as the writer and have the other call its API.

The component-breakdown-Step 3 dependency graph depends on this rule; the fitness function in evolutionary-architecture.md Section 3 enforces it. A data-ownership conformance check is a Tier 2 requirement.

## Section 8. The "just use Postgres" antipattern

Postgres is a legitimately excellent relational OLTP database. It is also the most common stackitecture answer when the shape question was never asked.

### Why Postgres is a good default

Postgres is free, mature since 1996, ACID, SQL-compliant, has excellent tooling, runs on every cloud with managed offerings (RDS, Cloud SQL, Neon, Supabase, Crunchy, Timescale). For relational OLTP workloads in the SaaS domain, it is a 9/10 choice in stack-ready's scoring framework (see stack-ready's domain-stacks.md). Starting with Postgres for an undifferentiated SaaS back-end is not wrong.

### When "just use Postgres" becomes stackitecture

The failure mode is picking Postgres without asking the shape question. Symptoms:

- **Time-series in Postgres.** Events at 1M rows per day degrade over a year; at 100M rows per day degrade in a week. The table partitioning, retention, and rollup work required is real, and a dedicated time-series engine (TimescaleDB, which is Postgres-compatible, or a purpose-built engine) would handle it with orders-of-magnitude less work.
- **Append-only event log in Postgres.** Postgres can be an event log at low volumes. At high volumes, the lack of partition-per-topic, consumer offsets, and log compaction makes the application carry all of that, badly.
- **Graph traversal in Postgres.** Recursive CTEs work for 2-3 hops at small scale. For fraud-ring detection across 6 hops on a graph of millions of edges, a graph engine wins by two orders of magnitude.
- **Full-text search in Postgres.** `tsvector` is fine for a few-million-document corpus. For relevance-ranked search across tens of millions of documents with faceting, a dedicated search engine is the right shape.
- **Blobs in Postgres.** Storing images in `bytea` columns blows up backup size, replication lag, and memory pressure. Object storage is the correct shape; the database stores the object key.
- **OLAP in Postgres.** Dashboards running GROUP BY over hundreds of millions of rows contend with production traffic and are 100x slower than a columnar warehouse. The answer is to stream OLTP data to an OLAP engine (or use TimescaleDB hypertables for the intermediate case), not to scale up the OLTP cluster.

### The shape-first test

Before writing "Postgres" in Step 4, answer three questions per entity group:

1. What is the access pattern: relational query, time-window aggregation, full-text search, graph traversal, blob retrieval, analytical scan, key lookup?
2. What is the write pattern: transactional row updates, high-volume appends, whole-object writes, batch loads?
3. What is the retention pattern: forever, rolling window, regulatory fixed window, purge on demand?

If all three point to relational OLTP, Postgres is a safe default. If any points elsewhere, the entity group's storage shape is not relational OLTP, and the architecture commits to that shape. Stack-ready then picks the engine.

## Section 9. Schema evolution and migrations at the architectural level

Schemas change. The architecture commits to the discipline that governs how.

### Forward-compatibility

New code must run against the old schema until migrations deploy; old code must run against the new schema until the rollout completes. Breaking-schema changes (drop a column, rename a table, change a column type incompatibly) require expand-contract (see below). Additive changes (add a column, add a table, add an index) are safe if the application tolerates the absence of the new field.

### Expand-contract

The industry-standard pattern for safe schema change. Three deploys:

1. **Expand.** Add the new schema element (new column, new table, new enum value) alongside the old. Application writes to both old and new; reads can use either. Reversible.
2. **Migrate.** Backfill old data into the new shape. Application starts reading from new. Old is still written for safety.
3. **Contract.** Stop writing to old. After a cooling-off period with the new working, drop the old schema element.

Deploy-ready owns the pipeline that ships expand-contract; architecture-ready commits to the discipline. If the ADR for a schema change is "alter the table in production," deploy-ready will refuse or will cause an incident.

### The cost of schema churn

Schema changes are more expensive than code changes at scale because:

- Every environment (dev, staging, production) must migrate.
- Every tenant's database (in per-tenant schemas or databases) must migrate.
- Every read replica must catch up.
- Every materialized view, trigger, and projection depending on the old shape must update.
- Every external consumer (analytics warehouse, partner integration, ETL job) must tolerate the change.
- The migration itself takes time proportional to the table size (a 100M-row ALTER can take hours, with locking considerations).

The architectural consequence: **design the schema well at entity-creation time, because changing it is a program, not a chore.** Anticipate the common evolutions (new tenant model, new status values, new relationships) and leave room.

### Reference deploy-ready briefly

deploy-ready's expand-contract discipline and code-vs-data rollback asymmetry are the operational concern. architecture-ready commits to the ADR: "schema changes follow expand-contract; migrations are forward-only; rollback of data migrations is a new migration, not a reverse." Deploy-ready enforces it. See deploy-ready's SKILL.md for the pipeline specifics; architecture-ready is the decision, deploy-ready is the execution.

## Section 10. PII and compliance shape

Which entities carry PII. Which components can see PII. The architectural commitments that constrain the stack-ready and production-ready layers.

### PII classification per entity

For each entity, classify:

- **No PII.** Product catalog entries, configuration, feature flags, public content.
- **Low-risk PII.** Username, display name, organization name.
- **Standard PII.** Email, phone, mailing address, IP address.
- **Sensitive PII.** Government ID, SSN, tax ID, date of birth (when linked to other identifiers).
- **Special-category PII (GDPR Article 9).** Health, biometric, genetic, racial/ethnic, religious, political, sexual-orientation, union-membership. Higher-bar consent and minimization requirements.
- **Cardholder data (PCI).** PAN, CVV, magnetic stripe, track data. PCI-scoped.
- **Protected health information (HIPAA).** Any health information linked to an individual. HIPAA-scoped.

The classification drives the next question.

### Which components can see PII

Name, per PII class, which components can read and write. PCI-scoped data should live in the smallest possible component footprint (tokenization is the standard industry answer: the component handling PAN is narrow; everything else handles a token). PHI is similarly scoped: the BAA-covered components handle PHI; analytics and product-telemetry do not.

The architecture commits: "the Payment component is the only component with unredacted PAN access; the Identity component handles hashed passwords and tokenized credentials; the Analytics component receives only tokenized and de-identified data." Component-level PII scoping is a trust-boundary commitment; trust-boundaries.md Section 3 elaborates.

### Encryption at rest vs. in transit

**At rest.** Every persistence layer holding PII encrypts at rest. The spec: "All databases, object stores, and backups holding Standard or higher PII use encryption at rest with keys managed by the cloud provider's KMS or an equivalent HSM-backed service." Stack-ready picks the KMS; architecture-ready states the spec.

**In transit.** Every inter-component communication crossing a network boundary encrypts in transit. TLS 1.2+ for external; mTLS or TLS for internal service-to-service; database connections use TLS. The spec: "All network communication of data classified Low-risk PII or higher uses TLS or equivalent transport encryption." No cleartext inside the datacenter.

**At application layer.** Some data (SSN, card number, health identifiers) benefits from application-layer encryption in addition to at-rest: the data is encrypted before it ever reaches the database, with keys managed outside the database. The database stores ciphertext; compromise of the database does not compromise the data. This is field-level encryption and is a shape decision, not a stack decision.

**What architecture-ready does NOT decide here.** The specific algorithm (AES-256-GCM vs. ChaCha20-Poly1305), the key rotation schedule (90 days vs. annually), the KMS product (AWS KMS vs. GCP KMS vs. HashiCorp Vault). Those are stack-ready's choices under the compliance filter. architecture-ready commits to the spec: "field-level encryption required for X, at-rest required for Y, in-transit required for Z." Stack-ready implements.

### The PII shape as an input to production-ready

The PII classification and component-access map feed into production-ready's Step 2 threat model and into trust-boundaries.md's four-boundary analysis. The cross-boundary flows that carry PII are the high-value targets; the threat model traces those flows and identifies the defenses.

End of data-architecture.md.
