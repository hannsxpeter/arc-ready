# handoff-to-execution.md

Step 8 material. This file specifies the downstream handoff block written to `.roadmap-ready/HANDOFF.md`. The artifact is the contract with the five downstream consumers: stack-ready, production-ready, deploy-ready, observe-ready, launch-ready.

## 1. HANDOFF.md structure

The file is the concatenation of five sub-sections, in this order. Every sub-section is populated or explicitly "not applicable" with a reason. An empty sub-section blocks Tier 3 sign-off.

```markdown
# Roadmap handoff

**From:** roadmap-ready 1.0.0, [ISO date]
**ROADMAP.md:** [path] ([tier])
**Upstream PRD:** [path] ([tier])
**Upstream ARCH:** [path] ([tier])
**Project:** [project name]

## To stack-ready

[sub-section per section 2]

## To production-ready

[sub-section per section 3]

## To deploy-ready

[sub-section per section 4]

## To observe-ready

[sub-section per section 5]

## To launch-ready

[sub-section per section 6]
```

## 2. To `stack-ready`

If stack-ready has not yet run, the roadmap's cadence and milestone shape feed stack-ready's constraint map.

```markdown
## Stack-ready inputs (from roadmap)

- Cadence: [Shape Up 6+2 / quarterly / PI / continuous / milestone / hybrid name]
- First milestone horizon: [4-6 weeks / 3 months / 10-12 weeks]
- First milestone scope shape: [monolith v1 / service split / mobile + backend / etc.]
- Time-to-first-ship target: [weeks / months]
- Any stack-level commitments baked into milestones: [e.g., "managed Postgres by M2", "migrate from MongoDB to Postgres in M4", "add Redis cache in M3"]
- Team size for stack-fit: [N engineers]
- Budget posture for stack-fit: [free-tier / cash-efficient / enterprise]

Ready to feed stack-ready's Step 1 pre-flight.
```

**What stack-ready does with this.** stack-ready reads cadence, horizon, and time-to-ship to set its "Time-to-ship" pre-flight answer. The stack-level commitments feed the "Scale ceiling" and "Regulatory constraints" constraints for candidate evaluation.

If stack-ready has already run, this sub-section simply notes "stack-ready has run; DECISION.md is at `[path]`." The roadmap consumes downstream of stack-ready in that case; no new inputs are required.

## 3. To `production-ready`

The slice queue. production-ready's Step 5 (slice ordering) drains this queue top-to-bottom, respecting the dependency column. The queue is the canonical sequence; a queue with cycles is rejected.

```markdown
## Production-ready slice queue

| # | Slice | Owner | Appetite / size | Outcome or commitment | PRD ref | Architecture ref | Depends on | Milestone | Status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | [slice name] | @user | big batch / small batch / S / M / L | [outcome or commitment label] | R-01, PRD s4 | echo-service / auth-service | - | M1 | queued |
| 2 | ... | ... | ... | ... | ... | ... | #1 | M1 | queued |
| 3 | ... | ... | ... | ... | ... | ... | #1 | M1 | queued |
```

**Queue rules.**

- Slice numbers are stable once assigned. Re-ordering is allowed; re-numbering is not (preserves cross-links).
- "Depends on" column lists slice numbers from this queue. External dependencies (e.g., "vendor Y's API change") are listed inline in the slice description.
- "Status" values: `queued`, `in-progress`, `blocked`, `done`, `cut`. Cut slices stay in the queue with a reason for historical traceability.
- Every slice has at least one of PRD ref or Architecture ref. A slice with neither is speculative (route to prd-ready or architecture-ready to anchor it).
- Every slice has an outcome or commitment label; feature-factory rows (bare names) are disqualified.

**What production-ready does with this.** production-ready v2.5.6 already lists roadmap-ready in its upstream frontmatter. Its Step 1 pre-flight reads the milestone plan; its Step 5 slice-ordering reads the queue directly and drains in order.

**Cycle detection.** If the queue contains a cycle (slice #3 depends on #5 which depends on #3), the skill refuses to emit the queue. Re-sequence.

## 4. To `deploy-ready`

The cutover cadence. deploy-ready's Step 2 (topology note) and Step 4 (pipeline design) consume this.

```markdown
## Deploy-ready cutover cadence

- Cadence style: [per-milestone / every N milestones / continuous with feature flags / hybrid]
- Milestone 1 cutover: [date or condition, e.g., "2026-06-15" or "when M1 gate passes"]
- Milestone 2 cutover: [date or condition]
- Milestone N cutover: [...]
- Launch milestone cutover: [date, launch mode]

### Migration posture (if applicable)

- Expand/contract migrations active across milestones: [list, with phase per milestone]
- Example: "Expand: M2 adds new column; Backfill: M3 backfills; Read-switch: M4 reads new column; Contract: M5 drops old column"

### Rollback policy

- [same-artifact promotion / forward-only / versioned artifacts with N-2 rollback window]
- Rollback window: [hours / days / deploys]

### Flag-rollout calendar (if continuous cadence)

| Feature flag | Launched behind flag | 25% rollout | 50% rollout | 100% rollout | Flag removal |
|---|---|---|---|---|---|
| [name] | [date] | [date] | [date] | [date] | [date, or post-stabilization] |
```

**What deploy-ready does with this.** deploy-ready reads the cadence style to set its own pipeline promotion cadence. It reads the migration posture to enforce expand/contract discipline across multiple milestones. It reads rollback policy to set up rollback windows in CI/CD. It reads the flag-rollout calendar to set up progressive rollouts.

If deploy-ready has already run (a prior milestone's deploy setup exists), this sub-section updates it rather than re-authoring.

## 5. To `observe-ready`

The KPIs each milestone is expected to move, plus launch readiness for any launch milestone.

```markdown
## Observe-ready inputs

### Per-milestone KPIs

| Milestone | KPIs expected to move | Leading indicator | Lagging indicator | Measurement source |
|---|---|---|---|---|
| M1 | [e.g., activation rate] | [e.g., onboarding-complete-within-session] | [e.g., 7-day retention] | [Amplitude / PostHog / custom] |
| M2 | ... | ... | ... | ... |

### Launch readiness (if launch milestone in scope)

- Observability live by: [date, owner]
- SLOs finalized by: [date, owner]
- Alert routes confirmed by: [date, owner]
- On-call coverage window: [hours/days surrounding launch]
- Dashboard URL (once built): [placeholder]
- Status page URL: [placeholder]

### NFRs that shape SLOs (from PRD + ARCH)

- Performance: [p95 target]
- Availability: [monthly %]
- Scale: [req/s or equivalent]
- Security / compliance: [if applicable]
```

**What observe-ready does with this.** observe-ready reads the KPI list to author SLOs tied to milestone outcomes; it reads the launch readiness dates to set up dashboards and alerts before launch-day; it reads NFRs to derive SLO thresholds.

## 6. To `launch-ready`

The launch milestone summary. Full detail is in ROADMAP.md's launch-milestone block; this sub-section is the pointer.

```markdown
## Launch-ready inputs

- Launch milestone: [name]
- Launch mode: [hard / soft / beta / GA / waitlist-to-GA / Product Hunt / TechCrunch-day / other]
- Target date: [YYYY-MM-DD, confidence band]
- D-calendar:
  - D-30: [date, focus]
  - D-14: [date, focus]
  - D-7: [date, focus]
  - D-1: [date, focus]
  - D-0: [date, focus]
  - D+7: [date, focus]
- Pre-launch dependencies: [milestones that must complete first, with names]
- External commitments:
  - Press briefings: [if any]
  - Partner announcements: [if any]
  - Platform coordination: [Product Hunt hunter confirmed / HN submitter identified / etc.]
- Slip protocol: [hold / re-shape / named exception]
- Public-roadmap derivative location: [path, if Tier 4]
```

**What launch-ready does with this.** launch-ready's Step 0 (mode detection) and Step 11 (D-7 runbook) read this sub-section. The D-7 date anchors launch-ready's runbook start; if the D-7 date is missing, launch-ready cannot start. Launch mode shapes the D-calendar; external commitments feed launch-ready's hunter-and-submitter coordination.

## 7. When a downstream sibling is not installed

For each downstream, the sub-section is written regardless of whether the sibling is installed. A team that installs deploy-ready six months from now finds the cutover cadence already written; the sibling can start from context, not from scratch.

A team that will never install a sibling (e.g., no launch planned) marks the sub-section "not applicable: no launch in scope for this roadmap" with a dated note.

## 8. Cross-sibling consistency checks

Before declaring Tier 3, the skill checks for consistency across handoff sub-sections:

- **Stack vs. production:** if the slice queue references a component, the stack must support it (e.g., queue says "Postgres migration in M3"; stack says "MongoDB is our DB" without a migration plan -> inconsistent).
- **Production vs. deploy:** every milestone in the slice queue has a cutover date; every cutover date has milestone items shipping.
- **Deploy vs. observe:** launch readiness dates in deploy and observe handoffs match.
- **Observe vs. launch:** KPIs for the launch milestone match the observability-live content.
- **Launch vs. roadmap:** the launch-milestone block in ROADMAP.md is consistent with the Launch-ready sub-section.

Inconsistencies are flagged, not silently reconciled. The team decides which side is authoritative (usually the ROADMAP.md; the handoff reflects it).

## 9. HANDOFF.md maintenance

The handoff is updated at every tier boundary and at every Mode C refresh. When the roadmap changes:

- If a slice is added, appended to the queue; the queue's numbering extends.
- If a milestone is added, its cutover and KPIs are added to deploy-ready and observe-ready sub-sections.
- If the launch is pushed, the D-calendar in the launch-ready sub-section updates with a dated change note.
- If a milestone is cut, its entries are removed from deploy-ready and observe-ready and recorded in ROADMAP.md's "Deferred" section.

The changelog in HANDOFF.md's header captures the changes:

```markdown
## Changelog

- **[date]** M3 slice queue expanded with slices 12-15 (auth redesign); deploy cutover for M3 moved from 2026-06-15 to 2026-06-29.
- **[date]** Launch D-calendar shifted 1 week later following Mode E rescue: D-7 now 2026-07-08.
```

## 10. Minimal HANDOFF.md example (echo-service example)

For a trivial project, the HANDOFF.md is short but complete:

```markdown
# Roadmap handoff (dogfood: echo-service example)

**From:** roadmap-ready 1.0.0, 2026-04-23
**ROADMAP.md:** dogfood/ROADMAP.md (Tier 2 Plan)
**Upstream PRD:** prd-ready dogfood (Tier 2 Spec)
**Upstream ARCH:** architecture-ready dogfood (Tier 1 Sketch)
**Project:** echo-service example (traced echo service)

## To stack-ready
Stack-ready has run at v1.1.5; DECISION.md documented. No new inputs needed.

## To production-ready
Slice queue (single-component, solo team):

| # | Slice | Appetite | Outcome or commitment | PRD ref | ARCH ref | Depends on | Milestone | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Base HTTP + /healthz | S | Deploy target live for deploy-ready / observe-ready | R-03 | echo-service | - | M1 | done |
| 2 | /echo with JSON validation | S | PRD R-01 acceptance criteria pass | R-01 | echo-service | #1 | M1 | done |
| 3 | OTel instrumentation + Honeycomb export | M | PRD R-02 acceptance criteria pass | R-02 | echo-service, integration:honeycomb | #2 | M1 | done |

## To deploy-ready
- Cadence style: per-milestone
- M1 cutover: 2026-04-15 (shipped)
- Rollback policy: same-artifact promotion; 3-deploy rollback window via Fly rolling strategy

## To observe-ready
KPIs: p95 latency < 200ms; 99% monthly availability; span-emit conformance in CI.
Observability live by: M1 completion (shipped).

## To launch-ready
No public launch planned. Sub-section: "not applicable; this is a toy dogfood target, not a public product."
```

## 11. Summary

HANDOFF.md is the contract with the five downstream consumers. Every sub-section is populated or marked "not applicable" with a reason. Cross-sibling consistency is checked before Tier 3 sign-off. The handoff is maintained at every roadmap change; it is not written once and forgotten.
