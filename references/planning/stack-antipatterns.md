# Stack-ready antipatterns

Named failure modes stack-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand during Mode B / Mode C audits, and at every tier-gate check before declaring a stack decision done. The full catalog of why each pattern is load-bearing lives in the skill body (`SKILL.md` §"The 'have-nots'") and the research pass (`RESEARCH-2026-04.md`).

## Core principle (recap)

> Every score states the weighting assumptions the user can override, and names the failure mode that would flip the recommendation.

A pattern below is a violation of this principle. Each is grep-testable.

## Pattern catalog

### Vibe stack selection (Critical)

**Shape.** Stack picks chosen because they're popular on Twitter, trending on HN, or recently discussed on a podcast. No domain fit; no constraint check; no scoring rationale.

**Grep test.** For every category pick, the rationale must reference: the domain (from `references/domain-stacks.md`), at least one named constraint, and one cited source from `RESEARCH-2026-04.md` or vendor docs. A pick whose rationale paragraph contains only marketing copy ("the modern way to build", "developer-loved", "lightning-fast") fails the test.

**Guard.** Step 5 scoring is required even for "obvious" picks. The scoring framework forces an explicit weighting that surfaces vibe-driven assumptions.

### Resume-driven selection (Critical)

**Shape.** Technology in the stack because the engineer wants it on a resume. Kubernetes for a 10-user CRUD; Kafka for a single-tenant pilot; gRPC for a 2-endpoint API.

**Grep test.** For every framework / runtime / infra pick, the architecture (from `.architecture-ready/ARCH.md`) must demand it. A pick with no architecture-driving requirement and a complexity floor higher than the project's current scale fails.

**Guard.** Step 1 pre-flight (team size, scale ceiling, time-to-ship) bounds the complexity envelope. Step 5 scoring weights "team familiarity" and "complexity floor" explicitly.

### Premature scale (High)

**Shape.** Picks that solve problems the project doesn't yet have. Multi-region deploy at 0 users; sharding strategy at 1k DAU; horizontal autoscaling for a team-internal tool.

**Grep test.** For every scale-related pick (multi-region, sharded DB, distributed cache, message queue, service mesh), the PRD's 12-month traffic estimate must justify it. "Just in case" is not justification.

**Guard.** Step 1 question 5 (scale ceiling) anchors picks to the honest 12-month estimate. Step 6 tradeoff narrative names the scale-ceiling-flip-point, so the user knows when to revisit.

### Stack decoupled from architecture (High)

**Shape.** Stack decision made before architecture, or made independently of architecture. The stack picks Postgres but the architecture demands a graph DB; the stack picks REST but the architecture demands streaming.

**Grep test.** Every stack pick traces back to a constraint in `.architecture-ready/ARCH.md` or `.prd-ready/PRD.md` §NFR. A pick that satisfies no upstream constraint is decoupled.

**Guard.** Step 2 builds a constraint map from PRD + ARCH artifacts before any candidates are scored. Picks that don't satisfy a constraint are eliminated before scoring, not at the end.

### Cost-blind recommendation (High)

**Shape.** Bundle that fits the requirements but ignores the cost ceiling. Datadog at $200/mo on a $400/mo total cap; AWS RDS multi-AZ at $50/mo when Neon serverless at $19/mo would do; per-seat SaaS pricing without a per-seat count.

**Grep test.** Step 5 bundle summary table must list per-line monthly cost (free-tier estimates included) and total against the PRD cost ceiling. A summary missing the cost column or exceeding the ceiling without a named tradeoff fails.

**Guard.** Step 1 question 3 (budget posture) is a hard constraint. Step 5 scoring framework includes a cost dimension. Step 6 names the cost-flip-point.

### Unweighted recommendation (Medium)

**Shape.** A score with no stated weighting. Reads as "objective" but it isn't.

**Grep test.** Every dimension scored must declare its weight (high / medium / low or numeric) and a one-line rationale for the weight. A score table with bare numbers and no weight column fails.

**Guard.** `references/scoring-framework.md` provides the default weighting matrix; the skill explicitly invites override at Step 5.

### "It depends" as final answer (Medium)

**Shape.** Recommendation that names tradeoffs without making the call. "Postgres or Mongo, depends on your needs."

**Grep test.** Every category gets a single named pick (or two with a clear flip-point). A category that ends in "depends" without naming the variable and the assumption fails.

**Guard.** Step 5 scoring forces a winner under stated weights. Step 6 names the flip-point that would change the winner; the user can override the weights, the skill makes the call.

### Dead-library recommendation (Medium)

**Shape.** A library or framework recommended that has no recent maintenance signal. Archived repo; last commit >18 months; no active releases; depended-on by a shrinking number of projects.

**Grep test.** Every library pick checks: GitHub last-commit date, last release date, npm/PyPI weekly downloads trend. Picks with stale signals on all three fail.

**Guard.** Step 5 scoring includes "sustained-maintenance signal" as a dimension. Step 6 names the migration cost if the library disappears.

### Managed service into compliance domain without BAA (Critical)

**Shape.** HIPAA app recommended onto a managed service with no BAA; PCI-DSS app onto a provider that does not support SAQ-A; GDPR app onto a US-only-region service.

**Grep test.** Step 1 question 6 (regulatory and data-residency constraints) is matched against every managed-service pick. A pick into a compliance-constrained domain that lacks the named compliance documentation fails.

**Guard.** Step 2 constraint map elevates compliance to "hard constraint." Picks failing the hard constraint are eliminated before scoring.

### Self-host into resource-constrained team (High)

**Shape.** "Self-host Postgres on Kubernetes" recommended to a 2-engineer team with no infra ops experience.

**Grep test.** Every self-host pick names the ops cost (in eng-days/month). Self-host pick + small team + no ops experience + no named ops budget fails.

**Guard.** Step 1 question 2 (team) bounds the ops complexity. Step 6 names the scale-ceiling-flip-point at which self-hosting becomes a liability.

### Trend-driven recommendation (Medium)

**Shape.** Pick justified by trend ("because it's popular," "because it's new"). No domain fit.

**Grep test.** Every pick's rationale paragraph names a domain fit, a constraint match, and a sustained-maintenance signal. Rationale that names only "trend" or "popularity" fails.

**Guard.** Step 5 scoring weights "domain fit" and "team familiarity" higher than "popularity."

### Undisclosed commercial tie (Critical)

**Shape.** A vendor recommended by an evaluator with an undisclosed commercial relationship to the vendor.

**Grep test.** A disclosure block at the end of the recommendation. Recommendations without a disclosure block, or with relationships not surfaced, fail.

**Guard.** The skill mandates disclosure as a structural requirement of the output, not an option.

### Undated recommendation (Low)

**Shape.** A stack rec with no date stamp. Reader cannot know if the recommendation is from 2024 (Next.js 13 era) or 2026 (Next.js 15 era).

**Grep test.** Every output carries a date stamp at the top. Outputs without one fail.

**Guard.** Step 0 mode-detection block includes the date in the output header.

### Migration plan without rollback checkpoint (High)

**Shape.** Mode D migration plan with no rollback checkpoint at each phase.

**Grep test.** Every phase in the migration plan has: pre-condition, migration step, verification, rollback procedure. A phase missing the rollback procedure fails.

**Guard.** `references/migration-paths.md` is the canonical reference; phases that skip the rollback step are flagged in code review.

### Hidden cost-cliff (Medium)

**Shape.** Cost ceiling that ignores egress, seat pricing, the free-tier cliff. "Free until you need auth" is not free; "$5/seat/mo" times unstated seat count is not a quote.

**Grep test.** Cost summary lists egress, per-seat pricing (with assumed seat count), and free-tier cliff conditions explicitly. A summary missing any of these fails.

**Guard.** Step 5 cost dimension includes the cost-cliff check.

### Microservices into a team of 2 (High)

**Shape.** "Microservices" recommended to a small team with no scale forcing function. The complexity floor is higher than the complexity being avoided.

**Grep test.** Microservices pick + team < 5 + no scale forcing function + no compliance-driven service-isolation requirement fails.

**Guard.** Step 1 pre-flight bounds team size and scale; the architecture-ready / stack-ready handoff names the complexity floor.

### Unreleased framework version (Critical)

**Shape.** Recommendation pins to a framework version that does not exist (Next.js 20 when current is 15; Rails 9 when current is 8.1).

**Grep test.** Every framework pick verifies the version against the registry's current release. Pinning to unreleased versions fails.

**Guard.** Step 5 scoring requires registry verification. Upcoming versions are noted separately as "next major; revisit at GA."

## Severity ladder

- **Critical**: blocks the recommendation. Must be fixed before declaring done.
- **High**: blocks the tier gate. Must be fixed before next tier.
- **Medium**: flagged in the output; user decides whether to address now or accept.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": the canonical have-nots list (this file is its grep-test annotation).
- `references/scoring-framework.md`: the per-dimension weighting matrix.
- `references/pairing-rules.md`: the anti-pairing catalog.
- `references/tradeoff-narratives.md`: flip points, scale ceilings, switching costs.
- `references/RESEARCH-2026-04.md`: source citations for every named pattern above.
