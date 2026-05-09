# Worked example: Pulse stack decision

This is a worked example. The product is fictional. The stack decision is what `stack-ready` produces when run end-to-end against the worked PRD (`EXAMPLE-PRD.md`), the worked architecture (`EXAMPLE-ARCH.md`), and the worked roadmap (`EXAMPLE-ROADMAP.md`).

The product context: **Pulse**, a Customer Success ops platform. Multi-tenant. 14-week paying-pilot appetite. 5-person team. $400/mo cost ceiling at pilot scale. Domain: B2B SaaS multi-page CRUD with HubSpot integration, scheduled jobs, and email/Slack notifications.

What follows is the stack decision itself, formatted to the stack-anatomy section order.

---

# Pulse: STACK.md

| | |
|---|---|
| Tier | Tier 2 (matches PRD tier) |
| Status | v1.0 (2026-05-12), 3 days after PRD freeze |
| Owner | Devon Park (eng lead) |
| Reviewers | Mira Chen (PM), Generalist (the second engineer) |
| Consumed PRD | `EXAMPLE-PRD.md` v1.0 |
| Consumed ARCH | `EXAMPLE-ARCH.md` v1.0 |
| Consumed ROADMAP | `EXAMPLE-ROADMAP.md` v1.0 |

## 1. Constraint map (from upstream artifacts)

The stack decision is bounded by the upstream artifacts. The following constraints are non-negotiable; any candidate that fails one of them is eliminated before scoring.

| Constraint | Source | Hard / soft |
|---|---|---|
| Multi-tenant single-schema with strong tenant-id discipline | ARCH §5, ADR-001 | Hard |
| Magic-link auth at v1.0; OIDC migration path at v1.x | ARCH §8 ADR-002 | Hard (migration path) |
| Single deployable + worker entry point | ARCH §8 ADR-003 | Hard |
| HubSpot integration via REST polling at v1.0 | ARCH §5 sync semantics | Hard |
| Email + Slack outbound notifications | ARCH §3, PRD R-05/R-09 | Hard |
| Structured JSON logs out of the box | ARCH §7 NFR | Hard |
| 14-week build appetite with 5-person team | PRD §Appetite | Hard |
| $400/mo cost ceiling at pilot scale | PRD §NFR Cost ceiling | Hard |
| Pen-test passes (no Critical findings) at week 12 | PRD §NFR Security | Hard |
| Account list <= 800ms p95 at 100 accounts, 5 concurrent users | PRD §NFR Performance | Soft (perf-tunable) |

## 2. Stack categories to decide

Per the architecture's container diagram (ARCH §3), nine categories need a decision:

1. **Web framework** (the API server + worker process; same codebase per ADR-003)
2. **Database**
3. **Auth library** (magic-link + OIDC migration path)
4. **Frontend framework / SPA**
5. **CSS / design system**
6. **Job runner / scheduler** (HubSpot poll, weekly digest, monthly cohort)
7. **Email transactional provider**
8. **Hosting / deploy platform**
9. **Observability** (logs + alerting)

Each category gets a ranked shortlist of 3-5 candidates, scored against the constraint map.

## 3. Per-category decisions

### 3.1 Web framework

| Candidate | Multi-tenant fit | Mono-deploy + worker | Team familiarity (5p) | Magic-link auth | Score (5pt scale) | Verdict |
|---|---|---|---|---|---|---|
| **Next.js 15 (App Router) + Server Actions** | Strong (route-level middleware, edge-aware) | Yes (Next + a separate Node worker process from same repo) | High (Devon, Generalist both built Next apps) | Strong (Auth.js / NextAuth) | **4.4** | Recommended |
| Remix | Strong | Yes (similar shape) | Med (only Devon has Remix) | Med (Auth.js works but Remix-idiomatic patterns less mature) | 3.6 | Reject (team familiarity gap; 14 weeks too short for one engineer ramping) |
| Fastify (raw, plus a separate React SPA) | Strong | Yes (cleanest separation) | High | Strong (passport, custom) | 4.0 | Reject (forces a second build pipeline for the SPA; raises cognitive load for a 5-person team) |
| RedwoodJS | Strong (built-in tenant patterns) | No (Rails-y full-stack model conflicts with the simple-deployable goal) | Low (no team experience) | Med (built-in but opinionated) | 2.8 | Reject |
| Rails 8 | Strong (decades of multi-tenant patterns) | Yes (Sidekiq for worker; Rails+Sidekiq is the canonical pattern) | Low (no team Rails experience; Devon TS, Generalist TS+Python) | Strong (Devise for magic-link) | 3.2 | Reject (familiarity gap dominates; ramping Rails costs ~3 of the 14 weeks) |

**Decision:** Next.js 15 (App Router) + Server Actions for the API + the SPA, plus a separate Node worker process invoking the same Next codebase via a CLI entry point. ADR-S-001.

### 3.2 Database

| Candidate | Multi-tenant fit | Tenant-id discipline support | Cost at pilot scale | Migration tooling | Score | Verdict |
|---|---|---|---|---|---|---|
| **Postgres (managed: Neon serverless)** | Strong | Native (composite indexes, FK constraints, RLS migration path) | $19/mo at pilot | Drizzle / Prisma | **4.6** | Recommended |
| Postgres (managed: Supabase) | Strong | Native + Supabase RLS | $25/mo at pilot | Supabase migrations + Drizzle | 4.4 | Reject (Supabase Auth is bundled; we want Auth.js for magic-link + OIDC migration cleanliness) |
| Postgres (managed: AWS RDS) | Strong | Native | $50/mo at pilot (db.t4g.micro) | Drizzle / Prisma | 3.8 | Reject (most expensive; no developer-experience advantage at this scale) |
| MongoDB Atlas | Med (multi-tenant via partition keys; the tenant-id discipline is application-level same as Postgres) | Adequate | $25/mo at pilot | Manual migrations | 3.0 | Reject (loses Postgres-native joins for the account-list query in PRD R-02; adds index-bloat risk for the touchpoint timeline) |
| Convex | Strong (multi-tenant patterns built-in) | Native | $25/mo at pilot | Built-in schema migrations | 3.4 | Reject (Convex BaaS model couples DB + auth + functions; conflicts with ADR-002's auth-shape stability across the OIDC migration; we'd repaint the auth twice) |

**Decision:** Postgres on Neon serverless for v1.0. ADR-S-002.

### 3.3 Auth library

| Candidate | Magic-link support | OIDC migration path | Session-shape stability | Score | Verdict |
|---|---|---|---|---|---|
| **Auth.js (NextAuth v5)** | Strong (Email provider) | Strong (10+ OIDC providers built-in; same session shape) | High (callback hooks let us preserve the JWT/session payload) | **4.6** | Recommended |
| Clerk | Strong | Strong | Med (Clerk session shape is opinionated; migrating off Clerk in the future is harder) | 3.8 | Reject (Clerk is a vendor lock-in; cost rises faster than self-hosted Auth.js as the pilot scales) |
| WorkOS AuthKit | Strong | Strong | Med | 3.4 | Reject (WorkOS strength is enterprise SSO; overkill at v1.0; reconsider at v1.x when SCIM lands) |
| Lucia | Strong | Med (DIY OIDC) | High | 3.4 | Reject (sustained-maintenance signal: Lucia announced sunset in 2025; not a forward-safe pick) |

**Decision:** Auth.js v5 with the Email provider for v1.0; OIDC providers added at v1.x without changing the session shape. ADR-S-003.

### 3.4 Frontend framework / SPA

The architecture (ARCH §3) calls for a browser SPA. Web framework decision (§3.1) is Next.js, which provides the SPA via React Server Components + client components. No separate frontend pick needed.

**Decision:** React 19 (the Next.js default). No separate framework.

### 3.5 CSS / design system

| Candidate | Speed-to-decent-UI | Design-token-friendly | Team familiarity | Component-library fit | Score | Verdict |
|---|---|---|---|---|---|---|
| **Tailwind v4 + shadcn/ui (token-overridden)** | High | Strong (Tailwind v4 `@theme`) | High | shadcn pulls Radix; we re-skin per the visual identity | **4.4** | Recommended |
| Mantine | High (component library is comprehensive) | Med (token system is Mantine-shaped; harder to migrate later) | Med | Strong | 3.8 | Reject (visual identity from PRD §V is custom; re-skinning Mantine is harder than re-skinning shadcn) |
| Plain Tailwind + Radix primitives (no shadcn) | Med (more time spent on per-component composition) | Strong | High | DIY composition | 3.6 | Reject (slower, no quality gain over shadcn) |
| Chakra UI | High | Med | Med | Strong | 3.6 | Reject (token system is Chakra-shaped; same re-skinning issue as Mantine) |

**Decision:** Tailwind v4 with `@theme`-defined tokens + shadcn/ui re-skinned per the visual identity to be derived in production-ready Step 3. ADR-S-004.

The design tokens follow the production-ready DESIGN.md flow: if a project-root DESIGN.md exists, production-ready Step 3 sub-step 3a consumes it; otherwise sub-step 3b derives the visual identity and (recommended) scaffolds a DESIGN.md from it. See `../building/design-md-integration.md`.

### 3.6 Job runner / scheduler

| Candidate | Single-deployable fit | Retry semantics | Cost at pilot scale | Score | Verdict |
|---|---|---|---|---|---|
| **node-cron + a worker entry point in the Next.js codebase** | Strong (one repo, one codebase, one `npm run worker`) | DIY retry (handle in app code) | $0 (runs on the same host) | **4.0** | Recommended |
| Inngest | Strong (durable functions, retry built-in) | Strong | $0 free tier covers pilot | 4.2 | Considered; deferred to v1.1 as the cohort + digest workflows mature. v1.0 uses node-cron for simplicity. |
| BullMQ + Redis | Med (adds Redis dependency) | Strong | $5/mo Redis | 3.6 | Reject (Redis adds an ops surface for one feature; over-engineered at v1.0) |
| Trigger.dev | Strong | Strong | $20/mo Cloud | 3.6 | Reject (cost; SaaS dependency for one feature) |

**Decision:** node-cron in the Next.js codebase for v1.0. ADR-S-005. Inngest is an explicit v1.1 candidate; the migration path is small (the three jobs become Inngest functions; the cron wrapper becomes the Inngest trigger).

### 3.7 Email transactional provider

| Candidate | Magic-link send (Auth.js) | Cost at pilot | Score | Verdict |
|---|---|---|---|---|
| **Resend** | Strong (Auth.js Email provider supports it natively) | $0 free (3k/mo) | **4.6** | Recommended |
| Postmark | Strong | $15/mo | 4.0 | Reject (cost; no DX advantage over Resend at this scale) |
| AWS SES | Strong | $0.10/1000 (~$2/mo at pilot) | 3.4 | Reject (deliverability tuning is heavier; reputation-warming for a brand-new sending domain is non-trivial; Resend handles it) |

**Decision:** Resend for v1.0. ADR-S-006. Migration path: Auth.js Email provider is provider-agnostic; switching to Postmark or SES is a config change.

### 3.8 Hosting / deploy platform

| Candidate | Single-deploy fit | Worker process support | Cost at pilot | Score | Verdict |
|---|---|---|---|---|---|
| **Vercel (web) + Railway (worker)** | Strong (Vercel for the SPA + API; Railway for the cron worker) | Strong | $20 Vercel + $10 Railway = **$30/mo** | **4.0** | Recommended |
| Vercel + Vercel Cron | Strong (same platform) | Med (Vercel Cron is hobbyist-grade for v1.0; jobs > 10s timeout cleanly; the 15-min HubSpot poll is OK; the cohort export may exceed) | $20/mo Vercel | 3.6 | Reject (timeout risk on cohort export; introducing a second platform for the worker is cleaner) |
| Fly.io (single platform, two processes) | Strong | Strong (`process` groups) | $15-30/mo | 4.2 | Considered; Vercel chosen for the SPA-developer-experience advantage. Fly.io is the v1.x fallback if Vercel becomes a friction point. |
| AWS (ECS + EventBridge) | Med (more moving parts) | Strong | $40-60/mo | 3.0 | Reject (over-engineered for pilot scale) |
| Render | Strong | Strong (background workers) | $14/mo + $7/mo worker = $21/mo | 4.0 | Considered; close score with Vercel+Railway. Vercel chosen for Next.js-DX. |

**Decision:** Vercel for the SPA + API; Railway for the worker process. ADR-S-007.

### 3.9 Observability

| Candidate | Structured logs | Cost at pilot | Score | Verdict |
|---|---|---|---|---|
| **Axiom** | Strong | $0 free tier (500GB/mo, more than pilot consumes) | **4.4** | Recommended |
| Datadog | Strong | $15-30/mo at pilot | 3.6 | Reject (overkill for pilot; reconsider at v1.x when SLO complexity grows) |
| Honeycomb | Strong (best-in-class for tracing) | $130/mo lowest paid tier | 3.0 | Reject (cost; tracing is v1.x scope per architecture §11) |
| Plain Vercel logs + a digest cron | Adequate | $0 | 2.8 | Reject (no SLO query support; the KPI handoff to observe-ready needs queryable logs) |

**Decision:** Axiom for v1.0. ADR-S-008. Migration path: standard JSON logs; switching to Datadog or Honeycomb is a log-shipper change.

## 4. Pairing compatibility checks

Stack picks must compose. The pairings checked:

| Pair | Compatibility | Notes |
|---|---|---|
| Next.js 15 + Postgres (Neon) | Strong | Neon serverless driver works in Edge runtime; Drizzle / Prisma both supported |
| Next.js + Auth.js v5 | Strong | Auth.js v5 is the canonical Next.js auth |
| Auth.js v5 + Resend | Strong | Resend is a first-party Auth.js Email provider |
| Tailwind v4 + shadcn/ui | Strong | shadcn supports Tailwind v4 as of late 2025 |
| Vercel + Neon | Strong | Vercel-Neon integration is a one-click connect |
| Vercel + Railway worker | Adequate | Two-platform setup; the worker connects to the same Neon DB; no contention |
| node-cron + Vercel Cron alternatives | N/A | We use Railway; Vercel Cron is not in the chosen bundle |
| Axiom + Vercel | Strong | Axiom Vercel integration is one-click |
| Axiom + Railway | Adequate | Stdout shipping; no first-party integration; standard JSON-line approach |

No incompatibilities. The two-platform deploy (Vercel + Railway) is the only "Adequate" pairing; if it becomes a friction point, the Fly.io fallback (single platform, two processes) is the migration target.

## 5. Bundle summary

| Layer | Pick | Cost/mo |
|---|---|---|
| Web framework | Next.js 15 (App Router) | $0 |
| Database | Postgres on Neon serverless | $19 |
| Auth | Auth.js v5 (Email provider) | $0 |
| CSS / components | Tailwind v4 + shadcn/ui | $0 |
| Job runner | node-cron in worker process | $0 |
| Email | Resend | $0 (free tier) |
| SPA hosting | Vercel | $20 |
| Worker hosting | Railway | $10 |
| Observability | Axiom | $0 (free tier) |
| Domain + DNS | (existing) | $1 |
| **Total** | | **$50/mo** |

**Cost headroom: $350/mo against the PRD's $400/mo cap.** The headroom absorbs traffic spikes, SaaS upgrades (Resend or Axiom paid tiers), or a second pilot customer joining late in v1.0.

## 6. ADRs (stack-level)

The architecture-level ADRs are in `EXAMPLE-ARCH.md` §8. The stack-level ADRs (S-prefix) capture the technology picks and the migration paths.

### ADR-S-001: Next.js 15 (App Router) for the web framework

**Decision:** Next.js 15 with App Router for the API + SPA + worker (single codebase, three entry points: `web`, `api` is the same as `web`, `worker` via a CLI script).

**Rationale.** Maximum team familiarity (Devon and Generalist both have Next experience). App Router supports the route-level middleware needed for tenant + RBAC enforcement (ARCH §6 boundaries). Single codebase satisfies ADR-003.

**Alternatives considered.** Remix, Fastify+separate-SPA, RedwoodJS, Rails 8 (rejected, see §3.1).

**Migration path.** Migrating off Next.js to Remix or Fastify+SPA is a 4-6 week project at v1.x scale; not anticipated.

### ADR-S-002: Postgres on Neon for the database

**Decision:** Postgres on Neon serverless. Drizzle as the ORM/migration tool.

**Rationale.** Native multi-tenant discipline (composite indexes on tenant_id; future RLS migration path preserved per architecture ADR-001). Lowest cost ($19/mo) for the feature set at this scale. Vercel-Neon one-click integration aligns with the deployment platform.

**Alternatives considered.** Supabase (rejected: bundled Auth conflicts with our Auth.js choice). RDS (rejected: cost, no DX advantage). MongoDB (rejected: loses Postgres joins for the account-list query). Convex (rejected: BaaS lock-in conflicts with auth-shape stability).

**Migration path.** Drizzle migrations are vendor-portable; switching to Supabase or Fly Postgres is straightforward.

### ADR-S-003: Auth.js v5 with magic-link Email provider

**Decision:** Auth.js v5 (`@auth/core`) with the Email provider; OIDC providers added at v1.x without changing session shape.

**Rationale.** Aligns with architecture ADR-002. No vendor lock-in; OIDC providers are config additions. Free.

**Alternatives considered.** Clerk (rejected: lock-in, cost). WorkOS AuthKit (rejected: enterprise focus, cost). Lucia (rejected: maintenance signal).

**Migration path.** OIDC is a v1.x scope; expected ~1 week to add Google + Microsoft providers without changing the session shape.

### ADR-S-004: Tailwind v4 + shadcn/ui (re-skinned)

**Decision:** Tailwind v4 with `@theme`-defined tokens; shadcn/ui as the component baseline, re-skinned per the visual identity from production-ready Step 3.

**Rationale.** Highest velocity for a 5-person team to produce a UI that does not look default. shadcn pulls Radix primitives (accessible, composable) and gives us code we own (vs. a NPM library we cannot easily customize). Tailwind v4's `@theme` aligns with the optional DESIGN.md scaffolding flow.

**Alternatives considered.** Mantine, Chakra (rejected: token system shape). Plain Tailwind + Radix (rejected: slower, no quality gain).

**Migration path.** N/A; re-skinned shadcn is owned code.

### ADR-S-005: node-cron in the worker process for v1.0; Inngest at v1.1 if scope grows

**Decision:** node-cron for the three v1.0 scheduled jobs (HubSpot poll, weekly digest, monthly cohort). Inngest is the v1.1 migration target if the workflow set grows.

**Rationale.** node-cron is the simplest thing that works for three scheduled jobs at pilot scale. Inngest's value (durable functions, retry, observability) compounds at >5 workflows; we have 3.

**Alternatives considered.** Inngest (deferred to v1.1). BullMQ+Redis (rejected: cost, ops surface). Trigger.dev (rejected: cost, SaaS dependency).

**Migration path.** Three node-cron jobs become three Inngest functions; the cron wrapper becomes the Inngest trigger. Estimated 1 week at v1.1.

### ADR-S-006: Resend for transactional email

**Decision:** Resend.

**Rationale.** Auth.js native Email provider, free tier covers pilot, sending-domain reputation handled by Resend. Lowest setup cost.

**Alternatives considered.** Postmark (cost). AWS SES (deliverability ramp).

**Migration path.** Auth.js Email provider is provider-agnostic; switching to Postmark or SES at v1.x (if volume requires) is a config change.

### ADR-S-007: Vercel (web) + Railway (worker)

**Decision:** Vercel for the Next.js SPA + API; Railway for the worker process.

**Rationale.** Vercel's Next.js DX is the strongest of the platforms. Railway's worker support handles the cron jobs cleanly. Combined cost ($30/mo) is well under the PRD ceiling. Two-platform deploy is the only friction; mitigated by Fly.io as the migration target.

**Alternatives considered.** Vercel + Vercel Cron (rejected: cohort-export timeout risk). Fly.io (single-platform alternative; close score). Render (close score; Vercel chosen for Next.js DX). AWS ECS (over-engineered).

**Migration path.** If Vercel + Railway becomes a friction point, migrate to Fly.io single-platform. Estimated 1 week at v1.x.

### ADR-S-008: Axiom for observability

**Decision:** Axiom for log aggregation and SLO queries.

**Rationale.** Free tier covers pilot. Strong query language for SLO calculation. Vercel one-click integration.

**Alternatives considered.** Datadog (cost). Honeycomb (cost; tracing is v1.x). Plain Vercel logs (no SLO query support).

**Migration path.** Standard JSON-line logs; switching to Datadog at v1.x (when SLO complexity grows) is a log-shipper change.

## 7. Stack-decision failure modes refused

The grep tests this stack decision passes:

- **Vibe stack selection.** Every category (§3) has a ranked shortlist with a scoring rationale. The picks are not "this is what's popular on Twitter."
- **Resume-driven selection.** No technology is in this stack because the engineer wants to put it on a resume. node-cron beats Inngest at v1.0 because Inngest's value compounds at scale we do not have. Resend beats AWS SES because deliverability ramp matters at v1.0.
- **Premature scale.** No Kubernetes, no Kafka, no service mesh. The single-deploy + worker pattern (architecture ADR-003) is honored at the stack level.
- **Stack decoupled from architecture.** Every pick traces back to a constraint (§1) sourced in PRD or ARCH. Picks that do not satisfy a constraint are rejected.
- **Cost-blind.** The bundle summary (§5) shows $50/mo against the $400 ceiling. Headroom is named.

## 8. Pre-flight checklist (for kickoff into production-ready)

Before production-ready Step 0 fires, the following must be in place:

- [ ] Vercel account + project created; Neon database connected
- [ ] Railway account + worker service created
- [ ] Resend account + sending domain verified
- [ ] Axiom account + Vercel integration enabled
- [ ] HubSpot developer account; OAuth app registered (for the v1.x sync code path; v1.0 polling uses an admin API token from DartLogic)
- [ ] GitHub repo with Vercel + Axiom integrations
- [ ] DNS records for the magic-link sending domain configured (Resend produces these)

The repo-ready skill produces the GitHub repo scaffolding; the pre-flight items above are the stack-side prerequisites the eng team handles in week 1.

## 9. Downstream handoff

- **production-ready** consumes this stack decision as the locked-in technology set for the slices in the roadmap. The first slice (foundation: tenant + user + magic-link sign-in) uses Next.js + Neon + Auth.js + Resend + Vercel, end-to-end.
- **repo-ready** consumes the stack decision to scaffold the repo. CI matrix runs Node 22 LTS (Next.js 15's required version); lint via Biome (per repo-ready's Tier 2 default); typecheck via tsc.
- **deploy-ready** consumes the platform picks (Vercel + Railway) to produce the cutover playbook. Same-artifact promotion: a single Docker image for the worker, a single Vercel deployment for the web, both promoted by tag.
- **observe-ready** consumes the Axiom pick to wire the SLO dashboards from the roadmap KPI handoff (`EXAMPLE-ROADMAP.md` §KPI handoff).
- **harden-ready** at the M2 pen-test reviews the auth (Auth.js + Resend), the tenancy enforcement (Drizzle + Postgres), and the trust boundaries (architecture §6 mapped to Next.js middleware).
