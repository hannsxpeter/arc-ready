# sequencing-principles.md

Step 1 (pre-flight) and Step 4 (sequencing) material. This file states the decision framework for ordering work within a roadmap. The framework layers topological order (from architecture), risk-driven prioritization (from Ries / Lean Startup), appetite or estimate (from Shape Up or classical PM), and capacity matching (from team size + Amdahl).

## 1. The eight pre-flight questions

Answered in writing before any sequencing pass. See SKILL.md Step 1 for the list. Every answer is either a concrete value, an explicit assumption, or a flagged open question with an owner and a due date. Fabricated answers are the primary failure; a null capacity value silences dated commitments rather than producing invented dates.

**Capacity worked example.** A team of 4 full-time engineers with a 2-engineer on-call rotation (1-week shifts) has effective capacity: 4 * (4 weeks - 1 week on-call per engineer per 4-week window) = 12 engineer-weeks per 4-week cycle, minus an Amdahl allowance of ~20% for reviews/coordination = ~9.6 engineer-weeks of productive capacity. A Shape Up 6-week cycle on the same team: 4 * 6 - 4 = 20 engineer-weeks gross, * 0.8 = 16 engineer-weeks net. This is the number the capacity check uses.

**Cadence-selection interaction.** Pre-flight answer 2 (cadence) shapes the horizon question (3): Shape Up implies 6-week horizons; quarterly implies 3-month; SAFe PI implies 10-12 weeks. If the cadence answer is "we don't have one yet," run cadence-selection ([`cadence-models.md`](cadence-models.md)) before attempting Step 4.

## 2. The four sequencing layers

Every sequencing pass is a layered decision. Conflicts between layers are resolved top-to-bottom.

### Layer 1: topological order

If architecture component A depends on architecture component B, then any roadmap item targeting A is sequenced after any item targeting B. Non-negotiable.

The topological sort is fed by `.architecture-ready/HANDOFF.md`. If the HANDOFF is missing a component-dependency graph, the skill flags this as a Step 3 blocker and does not proceed past Tier 1 Sketch.

Cycle detection: if the sort returns a cycle (A -> B -> A), the roadmap cannot be sequenced; the cycle must be broken by architecture-ready (that is an architecture problem, not a sequencing problem). Route back to architecture-ready with the specific cycle quoted.

### Layer 2: risk-driven ordering

Among items that can be sequenced in either order (their topological constraints are already satisfied), items that resolve higher-risk unknowns go earlier. This is Eric Ries's "build-measure-learn" applied to sequencing: the cheapest time to discover "this won't work" is before downstream work has been built on top of it.

The canonical high-risk patterns:
- **Novel third-party integration** (new payment provider, new identity provider, new AI vendor). If it doesn't work, a lot of plan depends on it.
- **Performance or scale hypotheses** that haven't been benched ("this will hold 10x traffic"). Prove with a spike, not with polish.
- **Regulatory or compliance hypotheses** ("this design is HIPAA-compliant as specified"). Get the legal review early.
- **User-behavior hypotheses** core to the PRD ("users will complete onboarding in under 10 minutes"). Prototype the flow before building the rest.

The canonical low-risk patterns that tempt early work:
- **Landing page / marketing site.** Visible but not blocking. Ships late.
- **Admin dashboards / internal tooling.** Nice to have; not load-bearing. Ships late.
- **Polishing known-working features.** Zero risk; zero learning. Defer.

Risk-first is the correction to the common mistake of "start with easy wins." Easy wins feel productive but teach nothing and leave the hard unknowns for when the architecture is already locked in.

### Layer 3: appetite fitting (Shape Up) or estimate fitting (classical)

**Shape Up mode.** Every item has an appetite: small batch (2 weeks) or big batch (6 weeks). Items that don't fit are shaped smaller or deferred; they are not carried forward at full scope. Appetite is declared before estimate; if the work proves larger than the appetite allows, scope is cut at the cycle boundary.

Appetite source: Ryan Singer, "Shape Up" (Basecamp, 2019), chapter 3. The exact phrasing: "Instead of asking 'how long will this take?' ask 'how much time is this worth?'"

**Classical mode.** Every item has an estimate (days, weeks, or story points) with a confidence band. Single-point estimates ("this takes 3 weeks") are banned; every estimate is a range or a confidence band ("70% by end of week 3, 95% by end of week 5").

Classical estimation practice has well-documented failure modes (Hofstadter's law, Kahneman-Tversky planning fallacy). The confidence-band requirement is the guard: even if the estimate is wrong, the band's width captures the uncertainty honestly. See Critical Chain Project Management ([`dependency-graph.md`](dependency-graph.md) section 2) for the statistical argument.

The choice between Shape Up and classical is made at cadence selection, not per item. Don't mix appetites and estimates in the same roadmap; it confuses the precision reading.

### Layer 4: capacity matching

The count of concurrent tracks in any one period does not exceed the capacity pre-flight answer. This is the fictional-parallelism guard.

Worked example: a team of 3 engineers in a 6-week cycle has effective capacity ~14 engineer-weeks net of Amdahl. A single big-batch bet (6 weeks * 2-3 engineers) occupies ~15 engineer-weeks; that's the whole cycle. A cycle with "three parallel tracks" for this team is fiction; the cycle can hold at most one big batch + one small batch (6 weeks * 1 engineer = 6 engineer-weeks if the tracks are genuinely independent).

The Amdahl check (see [`dependency-graph.md`](dependency-graph.md) section 5) applies specifically to parallelism claims. Doubling team size does not double throughput; the serial fraction (reviews, coordination, shared-service dependencies) caps the achievable speedup.

Capacity overflow is a negotiation, not an assumption. When capacity is exceeded, the skill either cuts scope (default), slows the cadence (extend the horizon), or pushes the overflow to the next cycle. It does not silently "hope for the best."

## 3. The grounding corollary

Every grounded commitment and every outcome-framed direction on the roadmap references at least one upstream artifact:

- A PRD section from `.prd-ready/PRD.md`: "R-03 (Should): Health endpoint."
- An architecture component from `.architecture-ready/ARCH.md`: "Component: echo-service; ADR-002."
- A named external constraint: "SOC 2 audit window ends 2026-07-01" or "Partner launch with X locked in for 2026-06-15."

Items without an upstream anchor are speculative. They were invented somewhere and "somewhere" is not an upstream artifact. Disposition:

- If the item is a real proposal the team wants, route to prd-ready to add it to the PRD. Once it appears in the PRD, it can re-enter the roadmap.
- If the item is a legitimate architectural decision not yet captured, route to architecture-ready.
- If the item is an external constraint the team can name explicitly, tag it and keep it.
- Otherwise, cut it. Speculative items are the AI-slop failure pattern; they look reasonable and aren't.

## 4. Risk-first vs. outcome-first ordering

These are compatible, not competing. Risk-first is "within a horizon, the riskier item goes earlier." Outcome-first is "within a horizon, the item with the highest-priority outcome goes earlier."

Both are sub-criteria for the sequencing within a horizon, under the topological-and-capacity layers. If the team has declared outcome-based prioritization (Cagan, Perri), outcomes rank first, and risk breaks ties. If the team has declared feature-based prioritization with discovery gaps, risk ranks first, and outcome breaks ties.

Most teams end up hybrid: highest-outcome and highest-risk tend to correlate (high-risk items are often high-value; that's why they're high-risk). The explicit layering matters when they diverge: a high-outcome low-risk item should not jump ahead of a low-outcome high-risk item, because the risk is what's waiting to surprise the team.

## 5. Anti-pattern: "easy wins first"

A recurring temptation. It produces roadmaps that feel productive in the first cycle and stall in the third, because the easy wins are done and the hard things are now on the critical path with no team history of having learned them.

The corrective framing: every cycle should include one risk-taking item. Even a single small-batch spike ("can we call the payment provider's API in this way") is enough to keep learning-rate high. A cycle with zero risk is a cycle with zero learning, and a stream of zero-learning cycles is a feature factory.

Exception: the rescue mode (Mode E). Rescue cycles often need a confidence-rebuilding easy win to break the stall pattern. That is a conscious tactical choice with a named reason; document it explicitly, then return to normal ordering.

## 6. Sequencing outputs

Every Step 4 sequencing pass produces:

1. **Ordered Now column.** Slices in the order they will be worked, with dependency column and appetite or estimate per slice.
2. **Capacity math.** A one-line summary: "Cycle holds X engineer-weeks gross, Y net of Amdahl; planned Z engineer-weeks, margin W."
3. **Risk register for the cycle.** Top 1-3 risks and the spikes or experiments that resolve them.
4. **Deferred items with reasons.** Items considered but not scheduled, with a reason each: "not fitted to appetite," "dependency not yet resolved," "below cut line," "rolled to Next column."

This output feeds Step 5 (milestone anatomy) and Step 8 (downstream handoff block). If any of the four outputs is missing, Step 4 is incomplete.

## 7. When sequencing proves impossible

Sometimes the work simply does not fit the cycle at the declared team size at any sequencing. The skill's response:

- **Cut scope.** The Shape Up default. Re-shape items to smaller appetites; defer the rest to the next cycle.
- **Extend the horizon.** If the cycle is a Shape Up 6-week and the work truly does not fit at any shape, the more honest response is "this is actually two cycles," not "this is a 9-week cycle." The latter breaks the circuit-breaker discipline.
- **Add capacity.** Only if the team is actually growing. Not a sequencing move; it's an org move.
- **Refuse the roadmap.** If the ask is "fit all of this in Q2 with the current team," and the capacity math refuses, the roadmap is refused. Escalate to the person asking.

The skill's job is to surface the infeasibility before engineering discovers it by burning a cycle. "No" is a legitimate roadmap output.
