# cadence-models.md

Step 2 material. Seven cadence models, a selection matrix, and the rationale template. The cadence decision is ADR-shaped: the skill records one cadence choice, two rejected alternatives, and a trigger for re-evaluation.

## 1. The seven cadences

### Shape Up 6+2

Ryan Singer, Basecamp, 2019. Six-week build cycles, two-week cool-down, betting table at the cycle boundary. Appetite before estimate: small batch (2 weeks) or big batch (6 weeks). The circuit breaker: if a project does not finish in six weeks, cancel by default, do not auto-extend.

**Good fit.** 5-40 engineers; product-led culture; autonomy; no fixed-scope external obligations; team has shipped production software before and has judgment about appetite.

**Bad fit.** Regulated rollouts with fixed dates; enterprise B2B with named customer GA; coordination with multiple external teams on a shared calendar; teams where every feature is a commitment.

**Horizon.** 6 weeks Now, 6 weeks Next (the shape for the next cycle), direction for Later.

**Review cadence.** Every 8 weeks (betting table at cool-down).

**Key reading.** `basecamp.com/shapeup`. Chapter 3 (set boundaries), Chapter 6 (write the pitch), Chapter 8 (the betting table), Chapter 14 (decide when to stop).

### Quarterly themes with monthly check-ins

Growth-stage SaaS default. Quarter defines themes (3-5 per quarter); month defines sub-outcomes; weekly sprints for execution. Often OKR-aligned.

**Good fit.** 30-300 people; OKRs in use; board cadence aligned to quarters; product-led but reporting to stakeholders on quarterly beats.

**Bad fit.** Teams smaller than ~8 engineers (ceremony overhead); consumer SaaS at scale with continuous deploy (quarterly is too slow).

**Horizon.** Current quarter Now (3 months); next quarter Next; rest-of-year Later.

**Review cadence.** Monthly check-in on theme progress; quarterly re-plan.

**Key reading.** Lenny Rachitsky's "One Team, One Roadmap" (https://www.lennysnewsletter.com/p/one-team-one-roadmap-issue-27); ProductPlan's OKR roadmap guide (https://www.productplan.com/templates/okr-roadmap/).

### SAFe PI planning

Scaled Agile Framework Program Increment planning. 8-12 week PIs. PI planning event lasts 2 days with the whole Agile Release Train (50-125 people) aligning on PI objectives, dependencies, commitments. Scrum sprints within the PI.

**Good fit.** 100+ engineers; multiple Agile Release Trains; regulated or safety-critical domains; traditional enterprise with waterfall legacy transitioning to agile.

**Bad fit.** Startups; product-led companies; small teams. SAFe is controversial: critics call it ceremony-heavy and not truly agile; defenders argue it works for domains with significant coordination needs.

**Horizon.** Current PI Now (8-12 weeks); next PI Next; remainder of the year Later.

**Review cadence.** Per PI (8-12 weeks); inspect-and-adapt event at PI boundary.

**Key reading.** `framework.scaledagile.com/pi-planning`. Be aware of the SAFe debate before adopting.

### Continuous delivery with rollout calendar

No release cadence. Deploy is decoupled from release via feature flags. Work merges to trunk frequently; features ship dark; activation happens in cohorts; full rollout is a calendar decision.

**Good fit.** Consumer SaaS at scale; strong DevOps culture; feature-flag infrastructure (LaunchDarkly, Unleash, DevCycle, in-house) in place; engineering team comfortable with trunk-based development.

**Bad fit.** Enterprise with long contract windows tied to named releases; mobile apps (App Store gates); hardware-adjacent software; teams without feature-flag infra.

**Horizon.** Next 4-6 weeks of rollout windows Now; next 3 months of planned experiments Next; direction Later.

**Review cadence.** Monthly rollout review; experiment-level per-flag lifecycle.

**Key reading.** Martin Fowler, "Feature Toggles" (https://martinfowler.com/articles/feature-toggles.html); trunkbaseddevelopment.com.

### Milestone-based

Named releases: 1.0, 1.1, 2.0. Often tied to public events, partner commitments, regulatory dates, conference demos, App Store gates.

**Good fit.** Mobile (App Store release cycle); enterprise software with formal GA; hardware-adjacent software; regulated deployments; any product with contractual release commitments.

**Bad fit.** Consumer SaaS with continuous deploy; internal tools with no named-release discipline.

**Horizon.** Next milestone Now; following milestone Next; milestone after Later.

**Review cadence.** Per milestone (usually per quarter or per half).

**Key reading.** See launch-sequencing.md for the milestone-to-launch connection.

### Hybrid: quarterly themes plus Shape Up bets underneath

A common pattern at 40-150 engineer organizations. Quarter is the planning horizon for stakeholders; Shape Up bets are the execution cadence inside the quarter.

**Good fit.** Growth-stage SaaS (40-150 engineers); product-led but exec-reporting on quarterly beats; culture comfortable with Shape Up.

**Bad fit.** Very small teams; very large enterprises.

**Horizon.** Current quarter Now (with bets named); next quarter Next (themes only, bets TBD); Later for direction.

**Review cadence.** Monthly check-in; betting table at cycle boundary (every 8 weeks); quarterly re-plan.

### Hybrid: milestone release calendar plus continuous-delivery within

B2B SaaS with named customer GAs and internal continuous deploy. Customers see "GA 1.2 in Q3"; internally, features ship dark behind flags and are activated at milestone boundaries.

**Good fit.** B2B SaaS with enterprise customers; teams that have both contractual commitments and continuous-deploy discipline.

**Bad fit.** Pure-continuous teams (no external GA); pure-milestone teams (no feature-flag infra).

**Horizon.** Current GA milestone Now; next GA Next; future GAs Later.

**Review cadence.** Per milestone, with monthly rollout review underneath.

## 2. Selection matrix

Use these axes to pick a cadence. The skill records the answer on each axis before selecting.

| Axis | Shape Up | Quarterly | SAFe PI | Continuous | Milestone | Hybrid Q+SU | Hybrid M+CD |
|---|---|---|---|---|---|---|---|
| Team size | 5-40 | 30-300 | 100+ | 10-100 | 10-200 | 40-150 | 20-150 |
| Risk tolerance | High | Medium | Low | Very high | Low-medium | Medium | Medium-high |
| Customer GA | No | Indirect | Yes | No | Yes | Indirect | Yes |
| External deadlines | Rare | Quarterly | Per PI | Flag-driven | Per release | Quarterly + per-bet | Per GA |
| OKR alignment | Optional | Typical | Typical | Optional | Optional | Typical | Optional |
| Flag infra needed | No | No | No | Yes | No | No | Yes |
| Regulatory fit | Weak | Medium | Strong | Weak | Strong | Medium | Strong |

No single axis decides. The selection is a fit across axes.

## 3. Rationale template

Every cadence decision is recorded in the ROADMAP.md as an ADR-shaped paragraph:

```markdown
## Cadence

We chose **[cadence name]** because [team size + risk tolerance + customer expectations].

Alternatives considered:
- **[rejected cadence 1]**: [why not]
- **[rejected cadence 2]**: [why not]

Trigger for re-evaluation: [named condition that would prompt a cadence change, e.g., "team grows past 40 engineers," "first enterprise customer with named GA"].
```

A cadence without a rationale is a cadence that will drift. Every team inherits whatever cadence the tool defaults to (Jira defaults to sprints; Productboard defaults to Now-Next-Later; Linear defaults to cycles); without an explicit decision, the tool wins.

## 4. Cadence interactions with cadence-adjacent practices

### OKRs

OKRs are an overlay, not a cadence. They pair naturally with quarterly themes (KR per theme) and reasonably with SAFe PI (KR per PI). They do not pair well with Shape Up (6-week cycles vs. 3-month OKRs has a timing mismatch) or with continuous delivery (no single-point measurement).

If OKRs are in scope, align the roadmap's outcome framing with the KRs. Each KR becomes a theme or a theme's primary metric.

### Scrum sprints

Scrum is a tactical cadence, not a roadmap cadence. 2-week sprints are too short to be roadmap horizons. A team using Scrum has a sprint backlog; the roadmap sits above it and feeds the product-goal-level items that sprints pull from.

If a team publishes "the sprint backlog" as "the roadmap," the roadmap is in the feature-factory failure mode. The skill flags this at Mode B audit.

### #NoEstimates

Woody Zuill, Neil Killick, et al. The argument: estimation is often waste; consistent small-slice delivery provides forecasting signal without ceremony. The skill is compatible with NoEstimates when paired with Shape Up (appetite-first sidesteps estimation) or continuous delivery (rollout-by-flag sidesteps estimation).

The skill is not compatible with "no estimates AND no appetites AND no cadence AND no capacity input." Some form of ground truth is required. Named alternative: forecast ranges ("70% by Q2, 95% by Q3") based on historical throughput, not estimated effort.

### Discovery + delivery paired tracks

Torres-style continuous discovery runs alongside any delivery cadence. It is not a cadence for the roadmap; it is a practice that feeds the PRD and thereby feeds the roadmap.

## 5. Signal: the cadence is wrong

If any of these patterns emerge after a cycle or two, the cadence is likely mis-picked:

- **Every Shape Up cycle is extended by 1-2 weeks.** Appetite discipline is failing; either the team is sandbagging estimates (stated as appetite) or the scoping is not happening. Evaluate whether quarterly themes + Shape Up hybrid would fit better, or whether the team size has outgrown Shape Up.
- **Every quarter's Q4 items slip.** Quarterly themes are being treated as commitments end-to-end; no scope cut discipline. Either tighten cut-line discipline or switch to continuous delivery.
- **SAFe PI planning events take 3 days instead of 2 and no one commits.** The ART is too large, or the upstream (PRD + architecture) is not ready. Route to prd-ready and architecture-ready.
- **Continuous delivery team is shipping lots but moving no KPIs.** No outcome-based prioritization; feature factory in a different format. Add outcome discipline at the flag-rollout level.
- **Milestone-based releases miss GAs regularly.** The milestone appetite is wrong or scope discipline is absent. Apply Shape Up's circuit-breaker at the milestone level.

## 6. Public-roadmap cadence

Separate concern. The internal cadence is for the team; the public cadence is for customers. Usually the public cadence is lower-frequency: quarterly public-roadmap update even if internal cadence is Shape Up 6+2.

Internal: detail, weekly movement, full Now-Next-Later.
Public: themes, rough timing, no internal owners, customer-value framing.

The public derivative cadence is a Step 10 decision; the internal cadence is Step 2. They do not have to match.

## 7. Summary

Pick the cadence explicitly. Record the rationale. Name the alternatives. State the re-evaluation trigger. Re-pick at the trigger, not at drift.
