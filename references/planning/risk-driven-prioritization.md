# risk-driven-prioritization.md

Step 4 material (sequencing overlay). Prioritization frameworks, their strengths and failures, and the compatibility matrix. The skill allows multiple frameworks; it requires one to be declared explicitly for each roadmap.

## 1. The frameworks

### RICE (Intercom, ~2015)

Formula: **RICE = (Reach x Impact x Confidence) / Effort**

- **Reach:** number of people affected per unit time (per month, per quarter). Use consistent units across the roadmap.
- **Impact:** 0.25 (minimal), 0.5 (low), 1 (medium), 2 (high), 3 (massive). Intentionally coarse.
- **Confidence:** 0-100%, penalizes unsupported enthusiasm.
- **Effort:** total person-months across all roles.

**Strengths.** Forces confidence to be explicit. Comparable across teams when reach units are consistent. Discourages pet-project over-prioritization.

**Failures.** False precision when confidence and impact are guessed. Gameability (tune impact or confidence to get the desired answer). Reach is under-defined for internal-tooling or infra work. Ignores dependencies; a high-RICE item that blocks all other work scores the same as an independent high-RICE item.

**When to use.** Growth-stage SaaS; customer-facing feature prioritization; feedback-rich environments where reach is actually measurable.

### ICE (Sean Ellis, growth-hacking era)

Formula: **ICE = Impact x Confidence x Ease**, each 1-10.

**Strengths.** Fast; "dozens of ideas in a single session." Good for growth experiments where each item is small.

**Failures.** Missing reach. Subjective (same idea scored by two people often diverges widely). Not good for milestone-level sequencing.

**When to use.** Short-cycle experiment sequencing; growth teams; when speed of ranking matters more than precision.

### WSJF - Weighted Shortest Job First (SAFe)

Formula: **WSJF = Cost of Delay / Job Size**

Cost of Delay = User-Business Value + Time Criticality + Risk Reduction / Opportunity Enablement.

Values on a modified Fibonacci scale (1, 2, 3, 5, 8, 13, 20).

**Strengths.** Economic framing ("jobs with highest value per unit time win"). Fits SAFe PI planning. Explicit about time-criticality.

**Failures.** Four-component Fibonacci estimation produces bucket fights. Time-criticality and value are hard to separate cleanly. Imposes a ceremony cost.

**When to use.** SAFe shops; enterprise with multiple teams bidding for shared capacity; regulated environments where time-criticality is real.

### MoSCoW (Dai Clegg, 1994, DSDM)

**Must-have** (critical for the current timebox), **Should-have** (important but deferable), **Could-have** (desirable, low-cost), **Won't-have** (explicitly excluded this timebox).

DSDM rule of thumb: no more than 60% effort in Must-have; 20% Should; 20% Could as buffer.

**Strengths.** Strong at milestone-cut level. Forces the "Won't-have this timebox" discipline. Easy to explain.

**Failures.** Weakest at continuous-flow. If Won't-have is empty, the list is a wishlist. If everything is Must, the list is not prioritized.

**When to use.** Milestone-based cadence; cut-line discipline at milestone boundaries; quarterly or PI planning.

### Kano model (Noriaki Kano, 1980s)

Categorizes features by satisfaction curve:

- **Must-be (basic):** absence causes dissatisfaction; presence is taken for granted.
- **Performance (one-dimensional):** satisfaction rises linearly with investment.
- **Attractive (delighter):** unexpected; presence creates disproportionate satisfaction, absence not noticed.
- **Indifferent:** no satisfaction impact.
- **Reverse:** presence causes dissatisfaction for some users.

**Strengths.** Good for framing debates about "what kind of feature is this." Kano gravity (delighters become performance, performance becomes must-be) explains why feature X that was exciting in 2015 is table-stakes in 2026.

**Failures.** Categorizes, does not rank. Two delighters scored equally tell you nothing about which to build first.

**When to use.** Pair with another ranking framework. Use Kano to filter (drop Indifferent items entirely) and RICE / MoSCoW / appetite to rank within each category.

### Opportunity scoring (Anthony Ulwick, Outcome-Driven Innovation)

Formula: **Opportunity = Importance + max(0, Importance - Satisfaction)**, each on 1-10 scale from customer surveys.

Outcomes with high importance and low satisfaction are underserved; that is where innovation ROI is high.

**Strengths.** Directly ties prioritization to customer outcomes. Discovery-grounded.

**Failures.** Requires customer surveys that most teams do not have. Not a sequencing tool (tells you what to focus on, not when).

**When to use.** Upstream of the roadmap: opportunity scoring feeds the PRD. Once an opportunity is chosen and PRD'd, the roadmap sequences the solutions.

### Riskiest-first (Lean Startup, Eric Ries)

Build-Measure-Learn loop. "Leap-of-faith assumptions": the beliefs whose wrongness would hose the project. Test the riskiest first.

**Strengths.** Learning-rate focused. Prevents late-stage discovery of fatal errors. Pairs well with Shape Up (spikes are high-risk bets).

**Failures.** Requires the team to honestly articulate what is risky. The riskiest item is often the one the team does not want to face.

**When to use.** Pre-PMF; early-stage discovery; any time the team is building on unvalidated assumptions.

### Appetite-first (Shape Up, Ryan Singer)

Not a ranking framework per se. The inversion: instead of "how long will this take?" ask "how much time is this worth?" Then shape to fit.

**Strengths.** Resists scope creep. Encourages cut decisions. Pairs with the circuit-breaker.

**Failures.** Requires a culture that trusts appetite over estimate. Doesn't rank items; it sizes them.

**When to use.** Shape Up teams. Combined with another framework (RICE, MoSCoW) to choose which items get what appetite.

## 2. Compatibility matrix

Which frameworks layer naturally, which stack, which conflict. Legend: **C** = compatible; **S** = stacked (both at different layers); **L** = loose overlap; **X** = conflicting.

| | RICE | ICE | WSJF | MoSCoW | Kano | Opp | Risk | Appetite |
|---|---|---|---|---|---|---|---|---|
| **RICE** | - | L | L | L | S | S | C | C |
| **ICE** | L | - | L | L | S | S | C | C |
| **WSJF** | L | L | - | L | S | S | C | C |
| **MoSCoW** | L | L | L | - | C | L | C | C |
| **Kano** | S | S | S | C | - | C | S | S |
| **Opp** | S | S | S | L | C | - | C | S |
| **Risk** | C | C | C | C | S | C | - | C |
| **Appetite** | C | C | C | C | S | S | C | - |

The only real conflict: RICE/ICE/WSJF (effort-in-denominator) vs. Appetite-first (effort is not the input; it's the budget). Teams resolve by layering: use RICE/ICE to rank candidates, then assign appetite to the top N, then execute Shape Up style.

## 3. The declaration rule

Every roadmap declares which framework(s) it uses:

```markdown
## Prioritization

Primary framework: **RICE**. Used to rank candidates for Now and Next.
Secondary: **Appetite** (Shape Up). Used to size the ranked candidates into 2-week small-batch or 6-week big-batch.
Kano filter: items scored Indifferent are cut before RICE ranking.
Riskiest-first tiebreaker: among similarly-RICE-scored items, the one resolving higher-risk assumptions goes first.
```

A roadmap without a declared framework ends up using whatever the tool's default sort is (usually creation date or alphabetical). The skill flags absence of declaration.

## 4. Anti-patterns

### "Every item is a Must."

If every MoSCoW row is Must, no prioritization has happened. The DSDM rule (no more than 60% Must) is a check; violate it, and the label is theater.

### "We use RICE."

Where is the formula? If RICE is declared but no item has a RICE score with the four inputs visible, the framework is claimed but not applied. Grep for the score column; flag absence.

### "Everything is medium confidence."

If every Confidence value is 80%, the team is not thinking about confidence. RICE requires real confidence variance; without it, RICE collapses to Reach x Impact / Effort.

### "Effort estimates from ChatGPT."

Effort estimates are a team-judgment exercise. Models produce plausible-looking numbers with no grounding. If effort values came from an LLM with no team review, discard and re-estimate.

### "Score-then-ignore."

Team runs RICE, the scores produce an ordering, then the team reorders based on "what the CEO wants." Either the framework is load-bearing or it is theater. Pick one.

### "Shiny-object prioritization."

Framework picked fresh every quarter. Whichever framework is in the newsletter this week. Teams that switch frameworks every cycle never build the calibration data to use any of them well. Pick one; stick with it for 4-6 cycles before re-evaluating.

## 5. When no framework fits

Some roadmaps genuinely don't need a ranking framework:

- **Strict sequential work** (one big thing at a time). Sequencing comes from the architecture DAG; ranking is not the bottleneck.
- **Entirely riskiest-first.** Pre-PMF teams where every slice is a learning spike. "What unknown matters most?" is the only question; no RICE needed.
- **Entirely appetite-first.** Shape Up mature teams where each cycle's bets are debated at the betting table; no formal score.

In these cases, declare "no ranking framework; sequencing is architectural (or risk-based or appetite-based)" and move on. An absent framework with no declaration is the failure; an absent framework with a declared reason is fine.

## 6. Scoring consistency

Cross-team roadmaps need comparable scores. If team A's RICE impact "2" means different things from team B's "2," the composite roadmap is not comparable. Two common approaches:

- **Anchor items.** A small library of known items with agreed scores that every team calibrates against.
- **Score-review ceremony.** Quarterly cross-team review of a sample of items; re-calibrate if divergence exceeds a threshold.

Intra-team consistency (one team over time) is easier: the same PM / team lead scoring items over cycles develops judgment. The first two cycles will have noisy scores; by cycle 3-4, the team's "2" means something consistent.

## 7. Framework cadence fit

Which frameworks fit which cadences:

| Cadence | Primary fit | Secondary fit |
|---|---|---|
| Shape Up 6+2 | Appetite | RICE for candidate ranking at betting table |
| Quarterly themes | MoSCoW | RICE for ranking within themes |
| SAFe PI | WSJF | MoSCoW for cut line |
| Continuous delivery | ICE | Kano filter |
| Milestone-based | MoSCoW | RICE for within-milestone ranking |
| Hybrid Q+SU | RICE + Appetite | MoSCoW at quarter boundary |
| Hybrid M+CD | MoSCoW + ICE | Kano at milestone |

The fit is not rigid. Teams deviate based on culture and context. The table is a starting point.

## 8. Summary

Pick one (or two layered) frameworks explicitly. Score items consistently. Re-score at cycle boundaries. Cut items the framework would cut. If the team consistently overrides the framework, either the framework is wrong for the team or the overrides are the actual decision rule (and the framework is theater). Either diagnose and correct.
