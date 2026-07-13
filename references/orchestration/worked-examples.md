# Worked Examples and Calibration

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Worked example: the Pulse arc (from the dogfood)

The eleven-skill suite produced a worked example at [hannsxpeter/ready-suite-example](https://github.com/hannsxpeter/ready-suite-example), a fictional B2B SaaS product called Pulse (Customer Success ops platform). The same arc, run end-to-end on arc-ready, produces the same artifacts at the same canonical paths.

The arc, condensed:

- **Tier 0.** User intent: "I have an idea for a Customer Success ops platform. Walk me through to launch." Mode A. PROGRESS.md initialized. Skip declared for `launch-ready`: pilot is private, public launch deferred to v1.1.
- **Tier 1.1 (PRD).** `.prd-ready/PRD.md` written. Problem framed: CS teams operate from spreadsheets; renewal data lives in HubSpot but adoption signal lives in Mixpanel; reconciliation is manual. Target user: CS Manager at 50-200 person B2B SaaS, $5M-$50M ARR, three or more CS reps reporting up. Success: TTV < 14 days for first health-score dashboard, MTTAR < 8 hours for at-risk account flag. R-NN with MoSCoW. Six pilot customers commit to onboarding within 4 weeks of v1.0 cutover. Sign-off recorded.
- **Tier 1.2 (architecture).** `.architecture-ready/ARCH.md` written. Modular monolith (3 bounded contexts: ingestion, scoring, surface); single deployable + worker; HubSpot v1.0, Mixpanel v1.1; Auth.js v5 magic-link with OIDC migration path; tenant-id discipline (single-schema multi-tenancy with row-level security); ADR-001 through ADR-007. Trust boundaries mapped to Postgres RLS policies and Auth.js middleware. Component dependency graph in HANDOFF.md.
- **Tier 1.3 (roadmap).** `.roadmap-ready/ROADMAP.md` written. Team capacity: 4 engineers, 6-week Shape Up cycle, Amdahl serial fraction 0.3. Three Now slices, three Next slices, two Later directions. Each commitment grounded in PRD R-NN. Critical path identified: ingestion before scoring before surface. Cutover milestone gate at week 13.
- **Tier 1.4 (stack).** `.stack-ready/STACK.md` written. Frontend: Next.js 15 + Tailwind v4 + shadcn/ui re-skinned with DESIGN.md. Backend: Server Actions + tRPC. Data: Postgres on Neon, Drizzle ORM. Auth: Auth.js v5. Hosting: Vercel + Railway worker. Observability: Axiom. 12-dimension scoring with weights (DX 0.18, Cost 0.16, Performance 0.10, Operability 0.16, etc.). Flip points named per dimension.
- **Tier 2.1 (repo).** `.repo-ready/SCAFFOLD.md` written; repo root populated. README, CONTRIBUTING, SECURITY, LICENSE, CODEOWNERS, .github/workflows/{ci, lint, deploy-staging, deploy-prod}.yml, .editorconfig, Makefile. Pillars-compatible AGENTS.md emitted with `agents/context.md` and `agents/repo.md` floor files, then source-backed `agents/stack.md`, `agents/arch.md`, and `agents/quality.md` when artifacts exist. DESIGN.md scaffolded (Tier 2.2 sub-step 3b).
- **Tier 2.2 (production / app).** Slices shipped vertically: tenant-bootstrap -> ingestion-pipeline -> health-score-engine -> renewal-dashboard -> at-risk-flagging. Each end-to-end-wired, all states covered, real backend, no fake data. `.production-ready/STATE.md` records the queue.
- **Tier 3.1 (deploy).** `.deploy-ready/DEPLOY.md` written. Same-artifact promotion via Vercel build hash; expand-contract calendar for the schema migration that adds `health_score_history`; canary at 10% with concrete stop rule (p99 latency > 1.2s OR error rate > 1% over 5 min); rollback path proven via dry-run; secrets vault-injected via Vercel env.
- **Tier 3.2 (observe).** `.observe-ready/OBSERVE.md` written. SLOs: dashboard-load p95 < 800ms, ingestion-latency p99 < 60s, health-score-recompute end-to-end p95 < 30s. Error budget policy: code freeze if 30-day budget burns past 50%. Runbooks executed: dashboard-load-degraded, ingestion-stall. INDEPENDENCE.md recorded: telemetry on Axiom is decoupled from the app.
- **Tier 3.3 (launch).** Skipped (declared at kickoff; pilot is private; deferred to v1.1).
- **Tier 3.4 (harden).** `.harden-ready/FINDINGS.md` written. OWASP Top 10 walkthrough: 1 High (auth session-fixation in magic-link flow, fix landed; retest passed), 3 Medium, 8 Low. SOC 2 Common Criteria mapped to specific files. Auth-hardening verification in AUTH-VERIFICATION.md. Critical-finding gate to launch (had launch run): would have held until High resolved; resolved before harden was marked done.
- **Tier 0 (final ledger).** `.arc-ready/PROGRESS.md` updated with `## Arc complete` block. Per-tier summary table. Open items: launch-ready deferred to v1.1, post-pilot bug-bounty program not yet stood up. Recommended next-step orchestrator: GSD for ongoing phase work.

The dogfood verifies cleanly against arc-ready's tier dispatch: every artifact at the same canonical path the eleven-skill suite established, same content shape, same gate-to-gate handoff.

## Tier-by-tier "common failure modes that fire here"

When an agent runs a tier sub-step and hits resistance, the resistance is usually one of the named failure modes. This is the quick-reference: if X is happening, look for failure mode Y.

| Symptom while running | Likely failure mode | Catalog reference |
|---|---|---|
| The PRD's Problem section keeps wanting to name the product | Solution-first PRD | `references/planning/prd-antipatterns.md` Antipattern 4 |
| The PRD's Target User reads like any user | Invisible PRD | `references/planning/prd-antipatterns.md` Antipattern 2 |
| Architecture diagram done; ADRs are thin | Architecture theater | `references/planning/architecture-antipatterns.md` |
| Architecture says "we'll figure scale later" | Non-architecture | `references/planning/architecture-antipatterns.md` |
| Roadmap has dates but no team-capacity input | Fictional precision | `references/planning/roadmap-antipatterns.md` |
| Roadmap has 6 parallel tracks for 4 engineers | Fictional parallelism | `references/planning/roadmap-antipatterns.md` |
| Stack pick has rationale but no flip point | Flip-point-free recommendation | `references/planning/stack-antipatterns.md` |
| Repo has every recommended file regardless of stage | Maximum-files-everywhere | `references/building/repo-antipatterns.md` |
| App feature has UI but no backend wiring | Hollow button | `references/building/production-antipatterns.md` |
| App feature uses faker.js or hardcoded JSON | Fake data | `references/building/production-antipatterns.md` |
| Schema migration in single deploy | Single-deploy expand-contract | `references/shipping/deploy-antipatterns.md` |
| "Canary" deploy with no stop rule | Paper canary | `references/shipping/deploy-antipatterns.md` |
| Dashboard has 40 charts; nothing is the SLO | Blind dashboard | `references/shipping/observe-antipatterns.md` |
| Alert fires every minute and is muted | Alert-without-real-fires | `references/shipping/observe-antipatterns.md` |
| Hero copy works for any competitor | AI-slop landing / hero-fatigue | `references/shipping/launch-antipatterns.md` |
| OG card not rendering in previews | Unrendered OG card | `references/shipping/launch-antipatterns.md` |
| "Snyk passed; we are secure" | Scanner-only security | `references/shipping/harden-antipatterns.md` |
| Compliance checklist green; trust boundary in code missing | Compliance without security | `references/shipping/harden-antipatterns.md` |

When in doubt, run the named-pattern grep test from the relevant catalog. The catalog has the load-bearing definition, the citation, and the remediation procedure.

## What good looks like, per tier

When an agent is in the middle of a tier and uncertain whether the artifact is approaching gate-passing quality, this is the at-a-glance reference. The full calibration lives in the worked-example files (`references/planning/EXAMPLE-PRD.md`, etc.).

### Tier 1.1 (PRD): what a passing Problem section looks like

> "Customer Success Managers at 50-200 person B2B SaaS companies spend 6-10 hours per week reconciling renewal data from HubSpot with adoption signal from Mixpanel. The reconciliation is manual: a CSM exports a HubSpot view, joins it against a Mixpanel cohort export, sorts by usage delta, and flags accounts whose adoption has dropped more than 30% in the last 30 days. The flag does not surface in their workflow tools; they paste it into Slack or a renewal-prep doc. The error rate is high (we measure 12-18% miscategorization in pilot data) and the latency is fatal (a flagged account is on average 11 days into the at-risk state by the time the CSM sees the signal). The mean-time-to-at-risk-recognition (MTTAR) we target is under 8 hours."

Substitution test: replace "HubSpot" with "Salesforce" or "Mixpanel" with "Amplitude"; the sentence is still true, but the specific 6-10 hours, the 12-18% miscategorization, and the 11 days are observable claims that fail substitution against a different product. Specificity is the discipline.

### Tier 1.2 (architecture): what a passing ADR looks like

> "ADR-001: Single-schema multi-tenancy with tenant-id row-level security.
>
> Context. Pulse serves 50-200 person B2B SaaS companies in pilot phase, scale ceiling per the PRD is 6 pilot tenants in v1.0 and ~50 tenants by v1.1. Cross-tenant data leakage would be a P0 incident given the customer-data subject the platform handles.
>
> Decision. We use a single Postgres schema with a `tenant_id` column on every table that holds tenant-owned data, enforced by Postgres row-level security policies. Auth.js v5 attaches the authenticated session's tenant_id to every query via the connection's session-local variable. The default deny RLS policy on every new table is enforced by lint.
>
> Consequences. Faster queries than schema-per-tenant; no per-tenant migration overhead. Higher blast radius if RLS is misconfigured; pen-test must verify enforcement. Cross-tenant analytics queries require explicit superuser context.
>
> Flip points. (1) A tenant requires a dedicated schema for compliance reasons (we move them off; we do not change the platform default). (2) The tenant count exceeds 5,000 (RLS overhead becomes measurable; we evaluate schema-per-tenant). (3) A bug in RLS leaks one tenant's data to another (we move to schema-per-tenant immediately, not as an evaluation)."

Substitution test: replace "Postgres" with "MySQL"; the rationale survives because RLS-equivalent exists in both. Replace "B2B SaaS" with "consumer mobile"; the rationale collapses (consumer-mobile rarely has multi-tenancy in the tenant-isolation sense).

### Tier 1.3 (roadmap): what a passing commitment row looks like

> "**M1 - Pilot Cutover (week 13).** Commitment. Six named pilot customers (per .prd-ready/PRD.md §Target users) onboarded; ingestion live for HubSpot + Mixpanel; health-score dashboard at TTV<14d; at-risk flag with MTTAR<8h. Reasoning: the pilot contract obligates us to a 14-day TTV per customer; the ingestion plus scoring plus surface chain is the load-bearing critical path per .architecture-ready/HANDOFF.md §dependency-graph; the target date is fixed by the partner-agreed cutover. Sign-off: <CSM Lead, Product Lead, Eng Lead>, dated 2026-04-01."

Each commitment carries: an outcome, an upstream reference (PRD or ARCH), a critical-path justification, a fixed date with sign-off. No bare feature names, no invented dates.

### Tier 1.4 (stack): what a passing recommendation looks like

> "**Recommendation.** Bundle B2: Next.js 15 (App Router) + Server Actions + tRPC + Drizzle + Postgres on Neon + Auth.js v5 + Tailwind v4 + shadcn/ui + Vercel + Railway worker + Axiom.
>
> Score 8.6/10 weighted on (DX 0.18, Cost 0.16, Operability 0.16, Performance 0.10, Scale ceiling 0.10, Security 0.10, Maturity 0.08, Hireability 0.06, Multi-tenancy fit 0.06). Pulse is a 4-engineer team building a B2B SaaS pilot with 6 tenants in v1.0 and 50 by v1.1; this bundle optimizes for DX and operability at this scale.
>
> Flip points. (1) DAU > 50k or scale ceiling > 5k tenants: re-evaluate Vercel + Railway against AWS ECS + RDS (cost crossover). (2) Real-time collaboration becomes a load-bearing requirement: re-evaluate Drizzle + Postgres against Convex + auto-CRDT. (3) The team grows past 12 engineers: re-evaluate the modular-monolith deploy against split services per ARCH-001."

Every score has weights; every recommendation has flip points; the scale ceiling is named.

### Tier 2.1 (repo): what a passing scaffold looks like

> "Repo root has: README.md (project-specific, not template), LICENSE (MIT), CONTRIBUTING.md, SECURITY.md, Pillars-compatible AGENTS.md (with CLAUDE.md symlink), agents/context.md, agents/repo.md, source-backed agents/stack.md and agents/quality.md when artifacts exist, DESIGN.md (Tier 2.2 sub-step 3b scaffolded), CODEOWNERS, .editorconfig, .gitignore, Makefile, .nvmrc, .github/workflows/{ci, lint, deploy-staging, deploy-prod, security}.yml, .github/ISSUE_TEMPLATE, .github/pull_request_template.md, package.json with a complete scripts block, biome.json, vitest.config.ts. CI runs and passes on a fresh clone."

No file is the unmaintained template; every file references the project's specific stack and project profile (Next.js + TypeScript + B2B SaaS + pilot stage in this case).

### Tier 2.2 (production): what a passing slice looks like

> "**Slice: At-risk account flagging.** Schema: `account_health_history` table with `tenant_id`, `account_id`, `health_score`, `delta_30d`, `flagged_at`, `flag_reason`. Migration applied. API: `POST /api/health/flag` invoked by the scoring job; `GET /api/health/at-risk` for the dashboard. Permission check: `requireRole('cs_manager')` middleware. Service layer: `flagAtRiskAccount` writes to the table, emits a domain event. Query hooks: `useAtRiskAccounts` with stale-while-revalidate. Dashboard page: list with filters (tenant, severity, age), detail row with reason chips and "view in HubSpot" deep link, empty state ("No at-risk accounts in the last 30 days"), loading state (skeleton), error state (retry banner). Tests: unit (scorer logic), integration (API + DB), E2E (Playwright: dashboard renders, flag-and-view round-trip). Demo: a CSM logs in, sees three flagged accounts, clicks one, reads the reason, deep-links to HubSpot."

Every layer wired end-to-end; no fake data; all states; tests green; demonstrably useful.

### Tier 3.1 (deploy): what a passing canary looks like

> "**Canary deploy: 2026-04-15 health-score-engine v3.0 with `pg_score_history` schema migration.**
>
> Classification: data-forward. Compensating-forward plan: if rollback needed, deploy v3.0-rollback that backfills any new health-score rows from v2.x scoring (50ms per row, ~6 hours for full backfill across pilot tenants). Restore point: full DB snapshot taken at 2026-04-15T14:00Z. Calendar: this is deploy 2 of 3 in the expand/contract sequence (deploy 1: schema-add 2026-04-08; deploy 2: writes-now 2026-04-15; deploy 3: contract-old 2026-04-22).
>
> Canary: 10% of staging traffic at 2026-04-15T14:30Z, then 10% prod for 30 minutes, then 50% for 60 minutes, then 100%. Stop rule: abort to 0% if (p99 latency on /api/health/recompute > 1.2s for 5 min) OR (error rate > 1% for 5 min) OR (any 5xx on /api/health/at-risk). Manual abort gate at 30 min mark.
>
> Rollback: if abort fires before contract step, revert v3.0 image to v2.x; the new schema column remains (NULL-able, no read paths). If abort fires after contract step, this is a partial-rollback impossible scenario; trigger compensating-forward."

Every "canary" is concrete: percentage, duration, metric, threshold, abort condition. No paper canaries.

### Tier 3.2 (observe): what a passing SLO looks like

> "**SLO: Dashboard load p95 < 800ms over 30-day window.**
>
> SLI: time from `GET /dashboard` to LCP, measured at edge by Axiom Browser SDK. Target: 99% of requests under 800ms. Window: 30-day rolling. Error budget: 1% (~432 minutes/month over budget).
>
> Error budget policy. Owner: Eng Lead. If 30-day budget burns past 50%: trigger code-freeze on dashboard-impacting features; on-call investigates. If past 80%: incident-style review; the budget restoration is a roadmap-prioritized item. Last reviewed: 2026-04-01.
>
> Page rule: alert pages on-call if budget burn rate exceeds 14.4x (1% in 1h) for the dashboard journey. Ticket rule (non-paging): rate > 6x for 6h. Both rules live in Axiom alert config; runbook at `.observe-ready/runbook/dashboard-load-degraded.md` and was executed last on 2026-03-22 (SLO breach, MTTR 47 min)."

Every SLO is bound to a journey, has an owner, has a freeze trigger, has a runbook that has actually been run.

### Tier 3.3 (launch): what a passing hero looks like

> "**Hero (substitution-pass).** 'Pulse: the at-risk-account console for CS Managers running 50-200 person B2B SaaS books. Cuts MTTAR from 11 days to 8 hours; replaces the spreadsheet pivot with a 30-second triage view.'
>
> Substitution test: replace 'CS Managers running 50-200 person B2B SaaS books' with 'sales reps' or 'product managers'; the sentence becomes false. Replace 'MTTAR from 11 days to 8 hours' with 'productivity'; loses the load-bearing claim. Replace 'spreadsheet pivot' with 'manual workflow'; loses the substitution-failing detail. The hero passes."

Every claim is something a competitor could not also say without the sentence becoming false.

### Tier 3.4 (harden): what a passing finding looks like

> "**Finding: AUTH-2026-04-01-001. Magic-link session fixation.**
>
> Severity: High (auth bypass; session-fixation enables an attacker to capture the magic-link token in an OAuth state-poisoning chain).
>
> Affected asset: `src/auth/magic-link.ts:42` (token issuance) and `middleware/session.ts:18` (session reuse).
>
> Reproduction. (1) Attacker visits `/api/auth/signin/email` with a controlled `state` param. (2) Auth.js issues a session pre-binding the state. (3) Victim follows the magic-link, the state matches, the victim's session is bound to the attacker's pre-existing session. (4) Attacker reuses the session.
>
> Impact. Account takeover for any user who follows a magic-link the attacker triggered.
>
> Root cause. Auth.js v5 default `state` param policy does not regenerate session ID on token consumption.
>
> Proposed fix. (code excerpt: regenerate session-id after `verifyEmailToken` returns). Add unit test that asserts session-id changes between issuance and consumption.
>
> Regression prevention. Lint rule that flags any session-fixation-related Auth.js config drift. Add to security CI.
>
> Retest plan. Re-run reproduction after fix; expected: session-id mismatch error; verified.
>
> References. NIST SP 800-63B 5.1.6, OWASP Session Management Cheatsheet, Auth.js v5 release notes."

Every finding is actionable: title, severity with justification, reproduction, impact, root cause, fix with code, regression prevention, retest plan, references. No vague "auth needs review" entries.
