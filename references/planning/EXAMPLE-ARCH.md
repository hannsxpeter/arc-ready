# Worked example: Pulse architecture

This is a worked example. The product is fictional. The architecture is what `architecture-ready` produces when run end-to-end against the worked PRD at `EXAMPLE-PRD.md`. It feeds the worked roadmap (`EXAMPLE-ROADMAP.md`) and the worked stack decision (`EXAMPLE-STACK.md`).

The product context: **Pulse**, a Customer Success ops platform for B2B SaaS account managers. Multi-tenant from day 1. One pilot customer (DartLogic). 14-week paying-pilot appetite. Five-person team.

What follows is the architecture itself, formatted to the architecture-anatomy section order.

---

# Pulse: System architecture

| | |
|---|---|
| Tier | Tier 2 (matches PRD tier) |
| Status | Frozen v1.0 (2026-05-10), 1 day after PRD freeze |
| Owner | Devon Park (eng lead) |
| Reviewers | Mira Chen (PM, for PRD-to-arch fidelity), Anaya Sharma (design, for UI-to-data alignment) |
| Consumed PRD | `EXAMPLE-PRD.md` v1.0 (2026-05-09) |

## 1. Context

Pulse is a multi-tenant web application that mirrors customer-account data from a CRM (HubSpot at v1.0; Salesforce at v1.1) and adds a touchpoint log, an at-risk flag, and a notification engine on top. The PRD names seven Must requirements (R-01 to R-07) and four Should requirements; the architecture below answers what system shape supports those requirements at the appetite of 14 weeks and 5 people.

The architecture is not novel. Pulse is a standard B2B-SaaS multi-tenant CRUD app with a third-party sync, scheduled jobs, and email/Slack notifications. The decisions worth recording are the ones that constrain implementation: tenancy enforcement, sync semantics, trust boundaries, and the auth migration path from magic-link to SSO without rework.

## 2. C4 Context diagram (Level 1)

```
                        +----------------------+
                        |                      |
   AM (Lin) ---------> | Pulse web app        | <--- Manager (Devon)
                       |                      |
                       +-----+--------+-------+
                             |        |
                             |        |
              +--------------+        +-------------+
              |                                     |
              v                                     v
    +-------------------+                 +-------------------+
    |                   |                 |                   |
    |  HubSpot CRM      |                 |  Email + Slack    |
    |  (source of truth |                 |  (notification    |
    |   for accounts)   |                 |   destinations)   |
    +-------------------+                 +-------------------+
```

The system has three external integrations: HubSpot (read), email provider (write), Slack incoming webhooks (write). All three are network-edge trust boundaries (see §6).

## 3. C4 Container diagram (Level 2)

```
                       +-----------------------------------+
                       |                                   |
                       |  Pulse web app (browser SPA)      |
                       |                                   |
                       +---------------+-------------------+
                                       | HTTPS / JSON
                                       v
+-------------------------------+   +--+--------------------------+
|                               |   |                             |
|  HubSpot REST API             |<--+  Pulse API server           |
|                               |   |  (auth, RBAC, CRUD,         |
+-------------------------------+   |   notification dispatch)    |
                                    |                             |
+-------------------------------+   +--+----+--------------+------+
|                               |      |    |              |
|  Email + Slack APIs           |<-----+    v              v
|                               |       +---+----+   +-----+--------+
+-------------------------------+       |        |   |              |
                                        |  DB    |   |  Job runner  |
                                        | (Postgres) |  (15-min poll|
                                        +--------+   |   + weekly   |
                                                     |   digest +   |
                                                     |   cohort)    |
                                                     +--------------+
```

Five containers:

1. **Browser SPA** (the AM's view). Renders account list, account detail, touchpoint log, at-risk flag UI, settings.
2. **API server.** Single deployable. Owns auth, RBAC, CRUD, notification dispatch, and the HubSpot sync read path.
3. **Postgres database.** Single logical database; tenant isolation at the application layer (see §5).
4. **Job runner.** Same codebase as the API server, run with a different entry point. Owns the HubSpot poll (every 15 min), the weekly Manager digest (Monday 09:00 local), and the monthly cohort export (last day of month).
5. **External integrations.** HubSpot (read), email provider, Slack incoming webhooks (write).

## 4. Component breakdown (Level 3, partial)

The API server's internal components:

- **Auth.** Magic-link email + session cookie. The session cookie carries the user's tenant-id and role, signed and rotation-aware. SSO migration path: replace the magic-link issuer with an OIDC handshake; the session shape stays unchanged. (See ADR-002.)
- **RBAC layer.** Single middleware applies the role check before every domain handler. The matrix is `{role} x {resource} x {action} -> allow|deny`, statically defined and tested.
- **Tenant scope.** Every query against domain tables includes a `tenant_id = :user.tenant_id` clause, applied at the data-access layer (not the route layer). A query that omits the clause fails at code review and at the application's tenant-scope test (see §5 and §10).
- **HubSpot mirror.** Read-only on Pulse's side. The mirror table is `hubspot_accounts` with the tenant-id column and a `hubspot_id` external key. The job runner owns the polling loop; the API server reads from the mirror.
- **Touchpoint store.** Pulse-owned. Append-only; soft-delete only via the audit log path.
- **At-risk flag store.** Pulse-owned. Each flag has a state (set / cleared / escalated), the AM who set it, the manager who escalated (if any), and a free-text reason.
- **Notification dispatcher.** Reads from the at-risk pattern matcher (a scheduled job inside the job runner) and posts to the user's configured destination (email always; Slack if webhook configured). Single-retry on transient failure; logs both success and failure for the SLO calculation.

## 5. Data architecture

### Tenant model

Pulse is multi-tenant from day 1. Three options were considered (see ADR-001):

1. **Schema-per-tenant.** Each tenant gets its own Postgres schema. Maximum isolation; high operational cost.
2. **Database-per-tenant.** Each tenant gets its own database. Maximum isolation; very high operational cost; not viable for 5-person team.
3. **Single-schema with tenant-id column.** All tenants in shared tables; isolation via application-layer enforcement of tenant-id on every query.

ADR-001 picks option 3 (single-schema with tenant-id), rationale below. Trade-off accepted: one bug in the tenant-scope enforcement could leak cross-tenant data; the architecture compensates with (a) every domain table has a `tenant_id NOT NULL` constraint, (b) every data-access function takes a `tenant_id` parameter and applies it before composing queries, (c) a per-PR test that replays the previous 50 API requests with a wrong tenant-id and asserts every one returns 403, and (d) the future migration path to row-level security (RLS) is preserved (the schema does not foreclose it).

### Core entities

```
tenant
  id (PK), name, created_at

user
  id (PK), tenant_id (FK -> tenant), email, role (am | manager | admin),
  created_at, deleted_at

hubspot_account (mirror, read-only on Pulse side)
  id (PK), tenant_id (FK), hubspot_id, company_name, mrr,
  lifecycle_stage, last_synced_at

am_account_assignment
  id (PK), tenant_id (FK), hubspot_account_id (FK), am_user_id (FK),
  assigned_at, unassigned_at

touchpoint
  id (PK), tenant_id (FK), hubspot_account_id (FK), am_user_id (FK),
  type (call | email | meeting | message), body, occurred_at, logged_at

at_risk_flag
  id (PK), tenant_id (FK), hubspot_account_id (FK), set_by_user_id (FK),
  reason, set_at, cleared_at, cleared_by_user_id (FK), escalated_at,
  escalated_to_user_id (FK)

audit_log
  id (PK), tenant_id (FK), actor_user_id (FK), action, resource_type,
  resource_id, payload (JSONB), occurred_at
```

Every domain table has `tenant_id NOT NULL` and a composite index `(tenant_id, primary lookup column)`. The audit log is the source of truth for security-sensitive events (login, role change, account reassignment, flag set/cleared).

### Sync semantics (HubSpot -> Pulse)

The HubSpot mirror is read-only on Pulse's side. Sync is one-way: HubSpot owns account data; Pulse never writes back. The sync is poll-based at v1.0 (every 15 minutes per tenant, staggered to avoid rate-limit clustering) and migration-ready to webhook-based at v1.1 (HubSpot supports webhooks; the migration is small).

Conflict policy: HubSpot wins for any field HubSpot owns (contact info, deal stage, lifecycle stage, MRR). Pulse owns touchpoints, at-risk flags, and reassignment audit; HubSpot never overwrites those.

Failure mode handling: a failed poll cycle logs the error and retries on the next cycle. After three consecutive failures for the same tenant, an alert fires to the on-call channel; the tenant's last-synced timestamp surfaces in the UI as a staleness indicator.

## 6. Trust boundaries

Five trust boundaries. Each is named, declared in the diagram (§3), and enforced in code (the location is named below).

1. **Network edge (browser <-> API server).** Enforced at the HTTPS terminator (TLS) and the session cookie (signed, HttpOnly, Secure, SameSite=Lax). Code: `auth/session.ts`.
2. **Tenant boundary (cross-tenant access prohibited).** Enforced at the data-access layer; every domain function takes a `tenant_id` parameter. Code: `db/tenant.ts` and per-PR tenant-scope test.
3. **Role boundary (AM / Manager / Admin).** Enforced as middleware before every domain handler. Code: `auth/rbac.ts`.
4. **HubSpot integration boundary.** Pulse holds a HubSpot OAuth refresh token per tenant. The token is encrypted at rest. Pulse calls HubSpot only for account-fetch on the polling cycle; no other endpoints. Code: `integrations/hubspot.ts`.
5. **Notification destination boundary.** Slack webhooks are user-controlled URLs. Pulse validates the URL is `https://hooks.slack.com/services/...` before saving; any other URL is rejected. Code: `notifications/slack.ts`.

The architecture-ready failure mode "paper trust boundaries (declared in docs, absent in code)" is refused by the §6 entries each carrying a code path; the harden-ready audit (PRD §NFR week 12 pen-test) verifies these in the implementation.

## 7. Non-functional requirements (mapped from PRD)

| PRD NFR | Architecture mechanism | Target |
|---|---|---|
| Performance: account list <= 800ms p95 | Composite index `(tenant_id, last_touchpoint_at DESC)` on `am_account_assignment` joined to `hubspot_account` | 800ms p95 with 100 accounts, 5 concurrent users |
| Performance: touchpoint save <= 4s median | Synchronous DB insert + websocket broadcast to the open account-detail page | 4s median; websocket optional, fall back to polling on disconnect |
| Availability: 99.5% pilot | Single-region deploy; managed Postgres; no custom HA at v1.0 | 99.5% measured at the API server's `/health` endpoint |
| Security: TLS, at-rest encryption, audit log | TLS at the load balancer; managed Postgres at-rest encryption; audit_log table written on each security-sensitive event | Audit log retained 90 days at v1.0 |
| Observability: structured logs, SLO on R-02 and R-05 | JSON-line logs with `tenant_id`, `user_id`, `request_id`, `route`, `latency_ms`; SLO dashboards from the log aggregator | 99% within target, monthly |
| Cost: <= $400/mo at pilot scale | Single deploy + managed Postgres + transactional email + log aggregator. See `EXAMPLE-STACK.md` for the per-line breakdown | $400/mo cap with 1 tenant, 5 users, 100 accounts |

## 8. Architectural Decision Records

### ADR-001: Single-schema with tenant-id column for multi-tenancy

**Date:** 2026-05-10. **Status:** accepted.

**Context.** Pulse is multi-tenant from day 1. The team is 5 people for a 14-week pilot. Three options exist for tenant isolation: schema-per-tenant, database-per-tenant, single-schema-with-tenant-id.

**Decision.** Single-schema with a `tenant_id NOT NULL` column on every domain table; isolation enforced at the application layer; future migration path to RLS preserved.

**Rationale.** Schema-per-tenant adds operational cost (migrations applied N times, monitoring per-schema, backups per-schema) that 5 engineers cannot carry alongside the 14-week feature build. Database-per-tenant is the same problem amplified. Single-schema with application-layer enforcement is the standard practice for B2B SaaS at this stage; it scales to ~100 tenants with no architectural change. The trade-off (one tenant-scope bug could leak cross-tenant data) is mitigated by the four mechanisms in §5.

**Consequences.** Every data-access function takes `tenant_id`. The tenant-scope test runs in CI per-PR. The migration path to RLS exists (Postgres supports RLS without schema changes); we will move there if the customer count exceeds ~50 or compliance requires harder isolation.

**Alternatives considered.** Schema-per-tenant rejected for ops cost. Database-per-tenant rejected for higher ops cost. Cosmos DB / DynamoDB partition-key approaches rejected for ecosystem mismatch (see `EXAMPLE-STACK.md` ADR-S-002).

### ADR-002: Magic-link auth at v1.0 with SSO migration path

**Date:** 2026-05-10. **Status:** accepted.

**Context.** PRD R-07 requires three roles (AM, Manager, Admin). PRD §No-gos defers SSO/SCIM to v1.x. The pilot customer accepts magic-link for the 14-week pilot.

**Decision.** Magic-link email auth at v1.0. Session cookie carries `tenant_id`, `user_id`, `role`. SSO migration path: replace the magic-link issuer with an OIDC handshake; the session shape stays unchanged.

**Rationale.** Magic-link is straightforward to build (one week of the eng budget vs. four for OIDC), the pilot customer accepts it, and the migration path is small (the SSO change touches the issuer, not the consumer). SSO at v1.0 would consume budget needed for R-06 (HubSpot sync) and R-04 (at-risk flag).

**Consequences.** v1.x SSO migration is a 4-week scope. We do not change the session shape between v1.0 and v1.x; existing sessions continue to work after the migration.

**Alternatives considered.** Password auth: rejected, modern B2B SaaS does not start with password auth. SSO at v1.0: rejected on budget grounds.

### ADR-003: Job runner colocated with API server

**Date:** 2026-05-10. **Status:** accepted.

**Context.** Three scheduled jobs at v1.0: HubSpot poll (every 15 min), Manager weekly digest (Mondays), monthly cohort export (last day of month). PRD R-06, R-11, R-13 require these.

**Decision.** Same codebase as the API server; deployed as a separate process with a different entry point. Single deployable.

**Rationale.** Separate codebase doubles the maintenance burden; separate deployable doubles the deployment surface. At pilot scale, the simplest pattern that works is one codebase, one deployment, two entry points (`api`, `worker`).

**Consequences.** Both processes share the same DB pool and the same configuration. Worker scaling is independent of API scaling, but at pilot scale neither needs to scale.

**Alternatives considered.** Separate worker repository: rejected for maintenance burden. Cron jobs in the OS / platform: rejected because the cohort export requires DB access and the polling cycle requires retry logic that fits poorly in shell-out cron.

## 9. Architecture failure modes refused

The grep tests this architecture passes (failure modes architecture-ready refuses):

- **Architecture theater.** Every diagram (§2, §3) carries decisions; every ADR (§8) has a load-bearing tradeoff. No "we decided to use a microservices architecture" without naming what microservices and why.
- **Paper-tiger architecture.** §7 maps each NFR to a concrete mechanism; the SLO calculation is named at §7. The pen-test in week 12 (PRD NFR) verifies the trust boundaries hold.
- **Cargo-cult cloud-native.** No Kubernetes, no Kafka, no service mesh. The architecture is a single deployable + a managed database, which fits the team size and the customer count. The migration path to multi-service is explicit (see ADR-003 alternatives).
- **Stackitecture.** §2 and §3 describe system shape (containers, components, integrations, trust boundaries). §10 (downstream handoff) leaves stack picks to stack-ready; the architecture does not name a framework or a database product. The names in §3 ("Postgres") are domain-of-discourse, not stack picks; "Postgres" stands for "any relational DB with strong tenant-id support" until stack-ready ratifies.
- **Resume-driven architecture.** No technology is in this architecture because it is interesting; every component (single deploy, single DB, polled sync, magic-link auth) is the simplest thing that satisfies the PRD requirement.
- **'Scalable' as a claim with no numbers.** §7 carries numbers (800ms p95 at 100 accounts, 5 concurrent users, $400/mo at 1 tenant + 5 users + 100 accounts). The phrase "scalable" does not appear in this document.

## 10. Downstream handoff

- **roadmap-ready** consumes this architecture to produce the dependency-ordered slice queue. The dependency graph: tenant model + auth (foundation) -> account list view (R-02 from PRD) -> touchpoint log (R-03) -> at-risk flag (R-04) -> HubSpot mirror (R-06) -> notification dispatch (R-05) -> RBAC (R-07). The Should and Could requirements come after Must. Worked example: `EXAMPLE-ROADMAP.md`.
- **stack-ready** consumes this architecture's component list (§3, §4) plus the NFR mechanism map (§7) to pick concrete technologies. The picks must satisfy: a relational DB with tenant-scope discipline (ADR-001), a session-cookie auth library with OIDC migration path (ADR-002), a single deployable that supports a worker entry point (ADR-003), structured-logging out of the box (NFR observability). Worked example: `EXAMPLE-STACK.md`.
- **production-ready** consumes the architecture's component breakdown (§4) and the data model (§5) to build slices. The first slice is the foundation: tenant + user + magic-link sign-in + the empty account list view. Then R-02 through R-07 in order from the PRD.
- **harden-ready** consumes the trust boundaries (§6). The pen-test in week 12 verifies each boundary in the implementation; findings against §6 are blocking for the paying-pilot signature.

## 11. Out-of-scope (explicit)

- **Multi-region deploy.** Single-region (US-East) at v1.0. EU residency is v1.x.
- **Service decomposition.** Pulse is a monolith at v1.0. Decomposition is justified at >= ~50 tenants or by an SLO violation that the monolith cannot fix.
- **Real-time tracing.** Logs at v1.0; OpenTelemetry distributed traces are v1.x.
- **Public API.** Internal-only at v1.0.
- **CSP / WAF tuning.** Default-strict CSP at v1.0; no WAF beyond the platform default. Tuning is week-12 pen-test driven, deferred to harden-ready.
