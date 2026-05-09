# review-cadence.md

Step 9 material. This file covers review frequency, authority maps, re-plan triggers, freeze conditions, freshness indicators, the archive rule, and the lifecycle of a roadmap across cycles.

## 1. Review frequency by cadence

Review cadence is derived from the declared cadence but is a separate decision (who looks at the roadmap, how often, at what granularity):

| Cadence | Review cadence | Granularity |
|---|---|---|
| Shape Up 6+2 | Every betting table (8 weeks) | Full bets reviewed; Now column replaced |
| Quarterly themes | Monthly check-in; quarterly re-plan | Monthly: progress only; quarterly: full re-plan |
| SAFe PI | Every PI boundary (8-12 weeks) | Full PI planning event |
| Continuous delivery | Monthly | Rollout calendar review; Now column refreshed |
| Milestone-based | Per milestone | Full milestone review |
| Hybrid Q+SU | Quarterly re-plan + per-betting-table | Quarterly: themes; betting: bets |
| Hybrid M+CD | Per milestone + monthly | Milestone: full; monthly: rollout updates |

A review cadence is not a retrospective; it is the beat at which the roadmap is updated to reflect reality and re-sequence for the next horizon.

## 2. The iteration pattern (Mode C)

The healthy cycle. At each review-cadence beat:

1. **Read the Now column.** What shipped, what slipped, what got cut.
2. **Update status columns.** `queued` -> `in-progress` -> `done` or `cut`.
3. **Archive the completed.** Done items move to the Archive section with their target-vs-actual and a one-line retrospective.
4. **Promote Next to Now.** The incoming Next column becomes the new Now. Shape it to appetite; decompose into slices; assign owners.
5. **Re-generate Next.** Pull from Later, from the PRD's unshipped items, from the ideas backlog. Size for the cycle after.
6. **Refresh Later.** Update direction based on what was learned; cut items that are clearly not happening; add new hypotheses.
7. **Update confidence bands.** Items that got easier move up; items that got harder move down or get demoted.
8. **Update the handoff.** HANDOFF.md reflects the new state.
9. **Broadcast.** The team is notified of changes; silent edits are moving-target-roadmap failures.

This is the default Mode C flow. It is not exceptional; it is the default.

## 3. Authority map

Who can change what, with what ceremony:

| Section | Who can change | Ceremony |
|---|---|---|
| Now column: slice status | Anyone on the team | Standing authority; updated as work progresses |
| Now column: slice order | PM or team lead | Standing authority; decision logged |
| Now column: slice add/cut | PM or team lead | Decision logged; broadcast to team |
| Next column | PM or team lead | At review-cadence beat; broadcast to team |
| Later column | Product owner or PM | At review-cadence beat; broadcast |
| Milestones (target date, scope) | Product owner | With explicit sign-off |
| Launch milestone date | Exec sponsor / product owner | Escalation; broadcast wide |
| High-integrity commitment label | Exec sponsor or equivalent | Tier 3 sign-off required |
| Cadence choice | Team + product owner | At cadence re-evaluation trigger |
| Out-of-scope list | PM with team input | At review-cadence beat |
| Rabbit holes | Team + tech lead | At milestone creation / review |

The rule: changes lower in the hierarchy are reversible with low ceremony; changes higher up require more process. Silent changes at higher levels are the moving-target-roadmap failure mode.

## 4. What triggers an unplanned re-plan

Most changes happen at review-cadence beats. Unplanned re-plans are triggered by:

### Scope discovery during a cycle

A rabbit hole expanded; an item proved larger than appetite. Response:

- Cut scope to fit appetite (Shape Up default).
- OR re-bet at cycle boundary (Shape Up exception; explicit decision).
- OR cut the item entirely and replace with a smaller scope (cycle-level re-plan).

### Capacity loss

Engineer departure; extended leave; on-call incident requiring sustained attention. Response:

- Reduce Now column to fit new capacity.
- Items displaced go to Next with a capacity-related flag.
- If capacity loss is permanent, re-run Step 1 (pre-flight) at the next cycle boundary.

### External shift

Regulatory change; partner slip; competitor launch. Response:

- Re-evaluate affected milestones.
- If the shift affects launch timing, re-declare slip protocol.
- If the shift affects PRD scope, route to prd-ready.

### PRD change (pivot or material delta)

Upstream PRD has forked. Response:

- Mode D: fork the roadmap; cross-link to prior.
- If the change is scoped (new feature added; feature removed), update in place with changelog entry.

### Discovery gap

An item is stalled because the underlying problem is not well-understood. Response:

- Remove from Now; demote to Next with open-question label.
- Route to prd-ready for discovery.
- Replace the Now slot with a ready-to-build item.

### Stakeholder intervention

An exec or customer demands a re-sequence. Response:

- Escalate to product owner for decision.
- If accepted, reshape the current cycle; cut scope to accommodate.
- Document the intervention explicitly (for future calibration).

## 5. Freeze conditions

A milestone is frozen (Mode F) when:

- **Launch cut-line active.** D-14 to D-0 window of an imminent launch.
- **Contractual lock-in.** Customer contract fixes scope.
- **Regulatory window active.** Regulatory date within the commitment horizon.

Frozen milestones reject new items. Every proposed addition is routed to the next-milestone backlog with a dated note. Every open question either resolves before D-7 or explicitly blocks the launch.

Un-freeze happens at D+7 (post-launch) or at contractual/regulatory completion.

## 6. Freshness indicators

Every Now and Next item carries a last-reviewed date. At each review-cadence beat, the date updates.

**Staleness rule.** An item with a last-reviewed date older than one cadence cycle is flagged stale. This is the shelf-roadmap guard.

**Common staleness patterns:**

- A Next item that has been in Next for 3+ cycles without motion. Either pull to Now or demote to Later. Flag.
- A Later item that has been thematic for 6+ cycles without decomposition. Either pull to Next or cut. Flag.
- A milestone with a target date that has passed. Either mark done (if shipped), mark slipped (with new target), or mark cut (with reason).

Stale items accrete; the shelf roadmap is the end state. The freshness indicator is the daily discipline.

## 7. Archive rule

Completed milestones are archived, not overwritten. The ROADMAP.md file grows by one section per cycle.

Archived milestones retain:

- Name and target date (at time of archiving).
- Completion gate (pass/fail at archive time).
- In-scope list at the time of archiving.
- Out-of-scope at time of archiving.
- Target vs. actual (what shipped on time, what slipped, what was cut).
- One-line retrospective with link to full retrospective if available.

The archive is read at each Mode C iteration to recalibrate capacity estimates. Historical actuals > claimed-capacity is the signal that the team systematically over-commits.

### Example archive entry

```markdown
### M1: Initial traced service (target 2026-04-15, completed 2026-04-15)

**Gate:** R-01, R-02, R-03 acceptance criteria pass; deployed to Fly.io. PASS.

**In-scope (shipped):** R-01 echo endpoint; R-02 OTel instrumentation; R-03 health endpoint.

**Out-of-scope (held):** auth; rate limiting; persistence.

**Retrospective:** Target appetite 6 weeks; actual 5 weeks; under-budget. One rabbit hole surfaced (OTel semantic conventions compliance); addressed by accepting drift. [Full retrospective: .roadmap-ready/retrospectives/2026-04-15-m1.md]
```

## 8. The changelog

Every ROADMAP.md has a changelog. Every change enters the changelog at the time of change:

```markdown
## Changelog

- **2026-04-23** Mode A initial draft.
- **2026-05-14** Mode C iteration: M1 archived, M2 promoted to Now, M3 pulled from Later to Next.
- **2026-05-14** Launch milestone date confirmed as 2026-06-30 (60% confidence); slip protocol: re-shape, no exceptions.
- **2026-05-21** Off-cycle: Capacity loss (engineer departure); Now column cut to 3 slices from 4; displaced slice (slice #7) moved to M3.
```

The changelog is flat chronological. No silent edits. A change that does not appear in the changelog did not happen.

## 9. Broadcast discipline

Every change requires a broadcast. The broadcast is a short message in the team's async channel (Slack, Linear, Discord, email) with a link to the changelog entry.

Engineering cannot discover changes by re-reading the ROADMAP.md. Broadcasts make the delta visible.

**Anti-pattern:** silent edits. The roadmap is updated, but the team is not told. Engineering reads the old version mentally; when a decision is referenced, confusion. This is the moving-target-roadmap failure mode.

**Minimum broadcast content:**

- What changed (one line).
- Why it changed (one line).
- Link to changelog entry.

## 10. The retrospective cadence

At each cycle boundary (or milestone completion), a retrospective is written. It is separate from the archive entry (which is a summary) and separate from the changelog (which is a delta log).

Retrospective content:

- What was planned vs. what shipped.
- What surprised the team (capacity, dependency, external shift).
- What was cut and why.
- What should change for the next cycle (process, scope sizing, dependency visibility).
- Named commitments for the next cycle.

Retrospective format is the team's choice; what matters is that it exists and is dated.

Retrospectives feed Mode C iteration at the next cycle boundary. A team that does not retrospect does not calibrate; its capacity estimates drift.

## 11. Mode E recovery

When the review-cadence process itself has stalled (retros are not happening; changelog is unmaintained; the roadmap is stale), Mode E applies. Procedure:

1. Acknowledge the stall. Do not silently pick up where the process should have been.
2. Run a catch-up retrospective. What happened since the last recorded cycle?
3. Reset the freshness indicators. Every item reviewed; stale items cut.
4. Re-declare the review cadence. Is it still the right cadence? If the stall is because the cadence is too heavy, switch.
5. Commit to the next beat publicly. If the beat is missed again, the cadence is wrong; switch or reduce.

A stalled roadmap is a recoverable problem. A stalled roadmap that pretends it is not stalled is the shelf-roadmap failure.

## 12. Summary

A roadmap is a living artifact. Review cadence is declared; freshness is tracked; archive grows with each cycle; every change hits the changelog and broadcast. Freeze conditions protect launches. Retrospectives calibrate capacity. The discipline is the doc, not the plan inside the doc.
