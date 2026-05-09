# SLO design

Loaded at Step 4 of the workflow. Tier 2 gate. The load-bearing step. The paper-SLO refusal lives here.

**Canonical scope:** picking the SLI, picking the target, picking the window, computing the error budget, writing the error-budget policy, composing SLOs across a dependency chain, and handling low-traffic services. **See also:** `alert-patterns.md` for the multi-burn-rate math that derives from the SLO; `dashboards.md` for how the SLO renders on the primary dashboard; `metrics-taxonomy.md` for the input SLI metrics.

The one-line framing: an SLO is a promise to a user wrapped around a measurable signal with a consequence if the promise breaks. Drop any of those four pieces (promise, user, signal, consequence) and the SLO is cosmetic. We call that a **paper SLO**, and observe-ready refuses to accept it as a deliverable.

---

## Part 1. The vocabulary

| Term | Plain-English meaning | Example |
|---|---|---|
| **SLI** (Service Level Indicator) | A measurable signal about reliability. | "Fraction of login requests returning 2xx in under 300 ms." |
| **SLO** (Service Level Objective) | A target for the SLI over a window. | "99.9% over rolling 30 days." |
| **Error budget** | `1 - SLO`, converted to "bad events you can absorb." | "10,000 bad events per 30 days at 10M requests." |
| **Burn rate** | How fast the error budget is being consumed, relative to the target rate that would consume it exactly evenly over the window. | "14.4x burn rate means we will consume 100% of the budget in `window / 14.4`." |
| **Error budget policy** | The rule the org follows when the budget burns. | "Burn > 50% at halfway: freeze feature launches, direct effort at reliability." |
| **SLA** (Service Level Agreement) | The external, contractual version of an SLO. Usually looser than the internal SLO. | "We commit to 99.5% availability" (in the contract). |

Canonical references: [Google SRE Book ch. 4](https://sre.google/sre-book/service-level-objectives/); [Google SRE Workbook on SLOs](https://sre.google/workbook/implementing-slos/); [Alex Hidalgo, *Implementing Service Level Objectives*](https://www.oreilly.com/library/view/implementing-service-level/9781492076803/); [Nobl9 error budget policy](https://www.nobl9.com/resources/intro-to-error-budget-policies).

---

## Part 2. Picking the SLI

One SLI per user journey. Not three. Not zero.

### 2.1 Good SLIs

A good SLI has four properties:

1. **User-visible.** The user would agree that "if this signal is bad, my experience is bad." Request latency at the API gateway is user-visible. CPU % at the app server is not.
2. **Measurable.** You can compute the signal continuously from real telemetry, not estimate it quarterly.
3. **Stable in shape.** The calculation does not change between instrumentation versions or after a refactor. If it changes, the history becomes incomparable.
4. **Binary at the event level.** Each observation is either "good" or "bad." Fraction good / total gives the SLI.

### 2.2 SLI categories

- **Availability:** fraction of requests returning non-error. "2xx or 3xx status code."
- **Latency:** fraction of requests returning in under a threshold. "Completed in under 300 ms."
- **Quality / correctness:** fraction of requests returning correct content. Harder to measure; often sampled via synthetic checks or business-logic validators.
- **Freshness:** for data pipelines, fraction of windows where data landed within target delay.
- **Durability:** for storage, fraction of objects still retrievable after N days.
- **Throughput:** less common as an SLI; typically a capacity target rather than a reliability target.

### 2.3 Two SLIs per journey? Usually no

A single journey can have multiple reliability dimensions (availability and latency), but bind them into one SLI whenever possible:

```
good_request := http_status in [200..399] AND latency_ms < 300
SLI := count(good_request) / count(total_request)
```

Binding avoids the split-brain "availability is at 99.9% but latency SLO breached." If you truly need two SLIs, treat them as two SLOs on the same journey. Do not stack three or more; the composition gets impossible to reason about.

### 2.4 Anti-patterns in SLI selection

- **CPU or memory as the SLI.** Cause metrics, not user experience.
- **"Sum of all errors in the system" as the SLI.** Untraceable to a user journey; too broad to act on.
- **"Average latency" as the SLI threshold.** Averages hide the tail. Use the threshold-based fraction (`latency_ms < 300`) instead, because it is what the p99 user experiences.
- **Internal-only signals.** Message queue depth as the SLI: not user-visible. It can be a saturation diagnostic that predicts the SLO; it should not be the SLO itself.

---

## Part 3. Picking the SLO target

Start loose. Tighten with data.

### 3.1 The 9s quick reference

| SLO | Monthly downtime budget | Weekly downtime budget |
|---|---|---|
| 90.0% | 72 hours | 16.8 hours |
| 99.0% | 7 hours 18 min | 1 hour 40 min |
| 99.5% | 3 hours 39 min | 50 min |
| 99.9% | 43 min 30 s | 10 min 5 s |
| 99.95% | 21 min 45 s | 5 min |
| 99.99% | 4 min 21 s | 1 min |

Every additional 9 is ten times the cost. Pick the lowest target you can honestly commit to; do not aim for 99.99% because it sounds better in a marketing deck.

### 3.2 The dependency ceiling

If your service calls service B with a 99.9% SLO, and service C with a 99.95% SLO, and each call is required for the journey to succeed:

- Worst case if independent: product = 99.9% * 99.95% = 99.85%.
- Correlated failures: the real number is often worse than the product because dependencies fail together.

A 99.99% SLO on a service that depends on 99.9% upstream is a lie. The upstream cannot honor the downstream's promise. Use the dependency-graph math from `metrics-taxonomy.md` Step 1 as the ceiling.

### 3.3 The too-tight trap

An SLO tighter than the system can meet produces a permanently-burned budget and a policy that is always triggered. Teams stop trusting the policy, the SLO becomes decoration, and you have a paper SLO with extra steps.

Alex Hidalgo's rule of thumb: a realistic SLO is one the team believes they can meet over the long run with reasonable effort. If the team's honest answer is "maybe 50/50," the SLO is too tight. Loosen it, track the actual number for a month, then tighten if the data supports it.

### 3.4 Journey-appropriate targets

| Journey type | Typical starting SLO |
|---|---|
| Core user-facing critical (login, checkout) | 99.9% to 99.95% |
| Standard user-facing (list, read, update) | 99.5% to 99.9% |
| Non-critical user-facing (exports, reports) | 99% to 99.5% |
| Internal tools | 99% |
| Batch jobs (schedule adherence) | 99% |
| Data pipelines (freshness) | 95% to 99% depending on business impact |

Adjust based on the dependency ceiling and the team's confidence. Document the reasoning.

---

## Part 4. Picking the window

### 4.1 Rolling 28 or 30 days

The default. Stable enough to smooth short-term noise, short enough that the budget pressure is felt.

### 4.2 Rolling 7 days

Works for high-traffic services where 30 days is too long to wait on feedback. Noisier; more frequent budget resets mean the team can recover faster but also feel whiplash.

### 4.3 Calendar vs. rolling

Rolling windows preserve continuous budget pressure; calendar windows (monthly, quarterly) reset abruptly at the boundary. Calendar windows are easier to explain to product; rolling is stricter about drift.

Default: rolling. Switch to calendar only if stakeholder comprehension is a real problem.

### 4.4 Synthetic traffic for low-volume services

If actual traffic is so low that the SLO is unmeasurable (errors that happen less frequently than the reporting cadence), run a synthetic probe at the cadence you need. The probe hits the real service through the real path; the SLI computes over probe + real traffic. Checkly, Datadog Synthetics, Grafana Cloud Synthetics, Pingdom all do this.

---

## Part 5. Computing the error budget

For SLO `X` over window `W` with total events `N`:

`error budget = (1 - X) * N`

Examples:

- 99.9% over 30 days at 10,000,000 requests: budget = 10,000 bad requests per 30 days.
- 99.5% over 30 days at 100,000 requests: budget = 500 bad requests per 30 days.
- 99% over 7 days at 50,000 requests: budget = 500 bad requests per 7 days.

Budget as time-downtime equivalent: see the 9s quick reference in part 3.1.

### 5.1 Burn rate

Burn rate is the factor by which the *current rate* of bad events exceeds the *target rate* that would exhaust the budget evenly over the window.

- 1x burn = exact target rate; budget lasts the full window.
- 2x burn = budget exhausts in `window / 2`.
- 14.4x burn = budget exhausts in `window / 14.4`. For a 30-day window, that is ~50 hours.

Multi-burn-rate alerting uses these factors to decide "how quickly is this bad" and "should we page or ticket."

---

## Part 6. The error-budget policy

This is the policy document that turns the SLO into organizational behavior. Without it, the SLO is a paper SLO.

### 6.1 Required policy fields

| Field | Meaning |
|---|---|
| **Trigger** | The measurable condition that activates the policy. "Budget burn > 50% at 50% through the window." |
| **Action** | What engineering and product do. "Freeze non-reliability feature work; direct effort at budget recovery." |
| **Stakeholder** | Who owns the decision and communicates it. "Engineering manager for the service." |
| **Exit criterion** | When the action ends. "Budget back under 40% burn; trailing 7-day rate within SLO." |
| **Escalation** | What happens if the action fails. "If budget not recovered after 7 days of freeze, engage incident commander and consider re-evaluating the SLO target." |

### 6.2 Template policy (fill in)

```markdown
# Error Budget Policy: <journey name>

## SLO
99.9% over rolling 30 days.

## Trigger
At 50% through the window, if the budget-remaining is less than 50%,
the policy is active.

## Action
- Feature launches for the affected service pause.
- Engineering capacity on the service redirects to reliability work:
  reducing the top three sources of budget burn, tightening runbooks,
  adding missing alerts, reducing dependency-chain fragility.
- Product manager re-ranks the backlog with reliability items above
  feature items.

## Stakeholder
Engineering manager, <name>. Product manager, <name>.

## Exit criterion
Budget remaining above 60% at the next weekly check, sustained for
two consecutive weeks.

## Escalation
If the budget does not recover after two weeks of freeze, the service
lead and the engineering director jointly review:
- Is the SLO target realistic given current dependencies?
- Are there structural problems (vendor, architecture) that a feature
  freeze cannot fix?
- Should the target be loosened while the structural problem is addressed?

## Last reviewed
2026-04-22. Next review: 2026-07-22.
```

### 6.3 Why the policy matters

The SRE workbook is explicit: the budget is the shared currency between product and engineering. It converts "please add more reliability work" into "you have burned 70% of your budget at 40% of the window, the policy triggers, we pause features." The alternative is a debate every quarter. With a policy, the debate happened once (when the policy was agreed), and the rest is execution.

Teams without an error-budget policy tend to either over-allocate reliability work (everyone is scared) or under-allocate it (everyone ships features, reliability suffers). The policy is the coordination mechanism.

---

## Part 7. SLO composition across dependencies

If a user journey calls three services A, B, C, and the journey success requires all three to succeed:

- Independent failures (idealized): `SLO_journey = SLO_A * SLO_B * SLO_C`.
- Realistic: correlated failures reduce the number; the upstream ceiling is strict.

Example: journey calls A (99.9%), B (99.95%), C (99.99%). Journey SLO product = 99.84%. Claiming 99.9% for the journey is aspirational; the upstream cannot sustain it.

Two approaches:

1. **Loosen the journey SLO.** Set the journey SLO to the product (or slightly above if the team can compensate via retry, fallback, caching).
2. **Tighten the upstream SLOs.** If the journey SLO must be 99.9%, the upstreams need to be higher. This is a budget negotiation with those upstream teams (and their vendors, if the dependency is external).

Note each journey SLO in `.observe-ready/SLOs.md` with its dependency-chain derivation. AI-generated configs routinely set a 99.95% SLO on a journey that has a 99.5% external dependency; the math exposes the fiction.

---

## Part 8. Low-traffic services

The SRE workbook's low-traffic caveat ([SRE workbook](https://sre.google/workbook/alerting-on-slos/)): burn-rate alerts need enough traffic for the rate calculation to be stable. A service with 100 requests/day cannot compute meaningful 5-minute burn rates.

Approaches:

### 8.1 Extended windows

Use a 60-day window instead of 30; compute burn over longer evaluation periods. Slower to detect, but more stable.

### 8.2 Synthetic traffic

Add probe traffic at the cadence needed for the SLI calculation. A synthetic probe every minute gives 1,440 events per day, enough for burn-rate math.

### 8.3 Aggregate across services

If five low-traffic services share the same shape (a family of admin endpoints, a family of webhooks), compute SLO across the aggregate. Individual services surface as diagnostics when the aggregate burns.

### 8.4 Switch from ratio to duration

For very-low-traffic services, consider an availability SLO based on *uptime* (measured by a heartbeat) rather than request success ratio. Example: "the service was reachable for 99.9% of minutes in the window." This moves away from request-based SLI but often matches the user experience ("can I hit it when I need to") more honestly for a low-traffic tool.

---

## Part 9. SLO deliverable template

Every SLO lands in `.observe-ready/SLOs.md` in this format:

```markdown
## SLO: login-availability

- **Journey:** User login.
- **SLI query:**
  ```
  sum(rate(http_requests_total{route="/login", status_class="2xx"}[5m]))
    / sum(rate(http_requests_total{route="/login"}[5m]))
  ```
- **Target:** 99.9% success.
- **Latency joint:** 99.9% of successful requests complete in under 300ms.
- **Window:** rolling 30 days.
- **Error budget:** 43 min 30 s of downtime per 30 days.
- **Dependency ceiling:** Auth provider SLA 99.95%; DB SLO 99.95%. Product 99.85%.
  Target slightly above product; reliance on retry/cache to close gap is acceptable.
- **Error-budget policy:** see `.observe-ready/policies/login.md`.
- **Owner:** @api-team
- **Multi-burn-rate alerts:** fast (14.4x), medium (6x), slow (3x), drift (1x). See `.observe-ready/alerts.md#login-slo-*`.
- **Runbook:** `.observe-ready/runbooks/login-slo-burn.md`.
- **Last reviewed:** 2026-04-15.
- **Next review:** 2026-07-15.
```

Every field is load-bearing. If any is empty, the SLO is a paper SLO until it is filled.

---

## Part 10. Quarterly SLO review

SLOs drift. Targets that made sense at launch may be too tight or too loose after 6-12 months of operation. Quarterly:

- Compare actual SLI to SLO across the quarter.
- If actual is consistently above SLO (e.g., actual 99.99% against a 99.9% target), consider whether tightening would produce useful pressure or simply move the ceiling.
- If actual is consistently at SLO, the target is calibrated.
- If actual is consistently below SLO, either the target is wrong, a dependency regressed, or reliability work is insufficient. The error-budget policy should already have fired.

Review goes in `.observe-ready/SLO-reviews/YYYY-QN.md`. Target changes are documented with reasoning so the next maintainer can trace the history.

---

## Part 11. Checklist for Step 4 completion

- [ ] Every user journey has exactly one SLI (not zero, not three).
- [ ] Every SLI is user-visible, measurable, stable in shape, and binary at the event level.
- [ ] Every SLO target is feasible given the dependency ceiling.
- [ ] Every SLO has a declared window.
- [ ] Every SLO has a computed error budget in both event-count and time-equivalent terms.
- [ ] Every SLO has an error-budget policy with trigger, action, stakeholder, exit criterion, and escalation.
- [ ] Every SLO has an owner and a last-reviewed date.
- [ ] Low-traffic services have a named SLO-measurement strategy (extended window, synthetic, aggregation, or uptime).
- [ ] All SLOs landed in `.observe-ready/SLOs.md` with all fields filled.
- [ ] The paper-SLO watchlist in STATE.md is empty (or has explicit "policy: TBD with planned date").

When every box is checked, Step 4 is complete. Move to Step 5 (alert design from SLOs).
