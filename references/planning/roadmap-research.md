# roadmap-research.md

Step 0 material. Load at the start of every session. This file holds the mode detection protocol, the shortlist of named failure modes, the upstream-signal checklist, and the resume protocol. Full citations live in [`RESEARCH-2026-04.md`](RESEARCH-2026-04.md).

## 1. Mode detection protocol

Pick exactly one mode. Declare it in writing. The rest of the workflow is shaped by the mode, so a wrong mode choice compounds downstream.

### Mode A - Greenfield

**Signals.** No prior ROADMAP.md. No `.roadmap-ready/` directory, or the directory exists only because another skill pre-created it. The team either just landed a PRD or has a fresh architecture artifact.

**Default path.** Step 1 (pre-flight), Step 2 (cadence), Step 3 (ingest upstream), Step 4 (sequence), Step 5 (milestones), Step 6 (Now-Next-Later), Step 7 (launch milestone if in scope), Step 8 (handoffs), Step 9 (review cadence), Step 10 (public derivative if mixed audience), Step 11 (staleness).

**Tier ceiling.** If PRD is at Tier 2 or higher and ARCH is at Tier 1 or higher: Tier 3 Committed available. Otherwise: degrade per Step 3 table.

### Mode B - AI-slop roadmap exists

**Signals.** A ROADMAP.md (or equivalent) already exists. Tell-signals: dates to the day in every column, parallel tracks equal to the count of items not the count of engineers, all four quarters filled to identical density, rows that name features absent from the PRD, no cadence declared, launch milestones with no readiness gates, confidence bands absent.

**Default path.** Run Step 1.5 audit first. Quote failing items. Name dominant failure mode. Cut speculative items. Re-shape fictional parallelism. Demote fictional precision to confidence-banded Next-column items. Then rejoin the Mode A path from Step 2.

**Tier ceiling.** Cannot exceed the tier the original claimed until every failing item is fixed or cut. A Mode B document that claimed Tier 3 Committed drops to Tier 1 Sketch until audit-remediation completes.

### Mode C - Iteration / refresh

**Signals.** Prior ROADMAP.md exists and is healthy. A cycle (Shape Up), month (quarterly cadence), or PI has passed. The Now column has shipped or slipped; actuals are in. The ask is "plan the next horizon."

**Default path.** Archive the completed Now column (see [`review-cadence.md`](review-cadence.md) section 6). Promote Next to Now. Re-shape the new Now for appetite and capacity. Re-generate Next from Later or from fresh PRD items. Update confidence bands. Refresh the handoff block. Increment the review-cadence log.

**Tier ceiling.** Same as prior revision's tier, pending sign-off by the signers from the prior tier.

### Mode D - Pivot

**Signals.** PRD has changed materially (new target user, new problem, new success metric) or the business direction has shifted. The existing roadmap is now answering a different question.

**Default path.** Fork. Create a new ROADMAP.md with a new file name (ROADMAP-v2.md, ROADMAP-2026-q3.md, etc.) or mark the old one "archived: pivot" and start fresh. Cross-link the old to the new. Do not overwrite the prior artifact; pivots are historical records for future context.

**Tier ceiling.** Starts at Tier 1 Sketch after a pivot. Re-earn each tier.

### Mode E - Rescue / stall

**Signals.** Roadmap was committed, build started, work stalled. Commitments are slipping. Team morale is down. Engineering is working from the sprint backlog, not the roadmap.

**Default path.** Diagnose the dominant stall cause before touching the roadmap. The four canonical causes:
- **Scope exceeded appetite.** An item sized as 2-week small-batch turned out to be 6-week big-batch. Shape Up's circuit-breaker applies: default is cut at cycle boundary, re-shape rather than extend.
- **Dependency missed in sequencing.** The architecture DAG was not fully respected. Return to Step 3-4 with the DAG; find the missed edge.
- **Capacity over-committed.** Engineer-weeks were over-assumed. Re-run Step 1; cut parallel tracks.
- **Discovery gap.** An item is stalled because the underlying problem was not well-understood. Route to prd-ready for discovery; remove the stalled item from Now and demote to Next with an open-question label.

**Tier ceiling.** Drops to Tier 2 Plan pending re-diagnosis. Re-earn Tier 3.

### Mode F - Freeze

**Signals.** A launch milestone is approaching (within the D-14 window by default). The team is in cut-line discipline.

**Default path.** No new items accepted into the frozen milestone. Every proposed addition is routed to the next-milestone backlog. Every open question either resolves before D-7 or explicitly blocks the launch. See [`launch-sequencing.md`](launch-sequencing.md) section 5.

**Tier ceiling.** Tier 3 Committed or Tier 4 Public-ready, held.

## 2. Named failure modes shortlist

Every roadmap eventually hits at least one of these patterns. The full catalog with citations is in [`roadmap-antipatterns.md`](roadmap-antipatterns.md). The shortlist below is what the skill checks for at every tier gate.

- **Feature factory** (Cutler, 2016). Features listed with no outcome or measurement plan.
- **Build trap** (Perri, 2018). The institutional symptom of feature factory: features-shipped as the proxy for value.
- **Roadmap theater.** Gantt-chart aesthetics with dates pulled from thin air. Industry term; adopted, not coined by us.
- **Fictional precision.** Day-level dates with no capacity input.
- **Fictional parallelism.** More concurrent tracks than engineers.
- **Quarter-stuffing.** All horizons at identical precision; no Now-Next-Later gradient.
- **Speculative roadmap.** Items not in the PRD, architecture, or any external constraint.
- **Shelf roadmap.** Written once, filed, never consulted. Last-reviewed date older than one cadence cycle.
- **Polish-indefinitely.** Cycles extended past appetite by default instead of re-shaped.
- **Invisible parallelism.** Parallel tracks drawn with shared-service or coordination bottlenecks unacknowledged.
- **Perpetual-now.** All items in Now; no forward view. Inverse: all items in Later, nothing in Now.
- **Linear (single-track) roadmap.** All items in one column even when architecture supports parallelism and team size is greater than 1.

Each of these is grep-testable against a well-formed ROADMAP.md. The have-nots list in SKILL.md is the enforced subset.

## 3. Upstream-signal checklist

Before declaring a mode and proceeding, check each upstream signal. The skill is fundamentally dependent on upstream artifacts; their state determines its precision ceiling.

| Signal | What to check | Implication |
|---|---|---|
| `.prd-ready/PRD.md` exists | file present | If absent, Tier 1 Sketch max |
| PRD tier | frontmatter version, or `## Tier` heading | Tier 2 Spec or higher unlocks Tier 3 Committed |
| `.prd-ready/HANDOFF.md` exists | file present | Pre-fills Step 3 inputs |
| "Roadmap-ready inputs" sub-section in HANDOFF | section present, non-empty | Directly pre-fills priorities, dependencies |
| `.architecture-ready/ARCH.md` exists | file present | If absent, Tier 2 Plan max |
| ARCH tier | frontmatter version or tier heading | Tier 1 Sketch unlocks Tier 3 Committed |
| ARCH dependency graph | component-breakdown table, integration list, or Mermaid C4 | Feeds Step 4 topological sort |
| `.architecture-ready/HANDOFF.md` "Roadmap-ready inputs" | section present, non-empty | Pre-fills load-bearing-first ordering |
| `.stack-ready/DECISION.md` or STACK.md | file present | Confirms stack is settled |
| `.production-ready/STATE.md` | file present (Mode C/E) | Shows what has already shipped; informs archive |
| Prior ROADMAP.md | file present (Mode B/C/D/E/F) | Shapes mode detection |

## 4. Resume protocol

If `.roadmap-ready/STATE.md` exists, read it first. It contains the skill version, current tier, mode, pre-flight answers, active milestones, and the last session note.

- If the STATE.md skill version matches the current session's skill version, resume from the last recorded tier.
- If the STATE.md skill version is older than the current session's skill version, re-run the Tier audit against the current skill's have-nots before proceeding. AI-slop tells may have evolved; downstream handoff contracts may have tightened.
- If STATE.md conflicts with the actual ROADMAP.md content, trust ROADMAP.md and update STATE.md in place with a dated note.
- If STATE.md is absent but ROADMAP.md exists, rebuild STATE.md from ROADMAP.md's current state. This is a lossy reconstruction; flag the open-questions and sign-off ledger sections as "unknown, verify with team."

## 5. When the user has one sentence

If the user's entire input is "build me a roadmap" or similar, the skill does not produce a six-column grid. The correct response is:

1. Declare Mode A (Greenfield) by default, or ask if a prior roadmap exists.
2. Ask for the smallest set of pre-flight inputs the defaults cannot cover: team size, cadence preference (or "whatever the team is already doing"), and audience (internal only vs. mixed).
3. Ingest any upstream artifacts present. If none are, flag that the roadmap is effectively a feature wishlist until a PRD lands; proceed to Tier 1 Sketch max.
4. Produce a Tier 1 Sketch. Name the gaps explicitly. Point at the Tier 2 requirements.

A six-column Gantt in response to a one-sentence prompt is the primary AI-slop failure mode. The skill refuses it.

## 6. When this skill is wrong

The skill is not infallible. Known edge cases where the default rules need conscious override:

- **Regulatory or contractual dates** where a fixed date is the point. The "high-integrity commitment" label exists for this. Use it explicitly; record the named reason; require Tier 3 sign-off.
- **Very small teams (solo or pairs)** where the cadence-selection matrix points at Shape Up but the team is smaller than a Shape Up bet. Shape Up 2-week small-batch becomes the only cadence; big-batch is not applicable.
- **Open-source projects** where there is no single team and no capacity input. The capacity rule relaxes to "flag any dated commitment as aspirational"; most of the roadmap becomes direction-only.
- **Very young pre-PMF products** where the PRD itself is hypothetical. The roadmap is appetite-based exploration; Later column is the main one; Now is the next experiment. This is Shape Up's "discovery mode"; rank items by riskiest assumption.
- **Post-launch maintenance mode** where the product is stable and the roadmap is mostly bug fixes and small improvements. The Now column becomes a rolling 2-week window; the Next and Later columns become light. The skill still applies but the weight shifts.

In each edge case, declare the override explicitly in the Mode block. Don't silently relax rules.

## 7. The stricter-generator stance

A note on positioning. The AI-tooling landscape is full of generators: ChatPRD, Productboard AI, Aha! AI, Atlassian Rovo for Jira, Linear's AI features, Notion AI. They all generate roadmaps. They all inherit the same failure modes: fictional precision, invented dates, no capacity check, no upstream grounding.

`roadmap-ready` is not a better generator. It is a stricter refuser. It refuses to commit dates without a capacity input. It refuses to sequence without a dependency graph. It refuses to include features absent from the PRD. It refuses to emit launch milestones with no readiness gates. The teeth of the skill are the have-nots.

This is the niche the existing tooling leaves open. Generators produce; the skill vets.
