# Risks, assumptions, and open questions (Step 8)

Three separate lists. Every PRD merges them, and the merge is the failure. This reference covers why they are different, the shape of each, the canonical failures, and how the Open Questions log feeds directly into sign-off readiness.

## 1. Three kinds of uncertainty

The PRD distinguishes three kinds of "things we don't fully know," each handled differently.

| Kind | Definition | Handling |
|---|---|---|
| **Risk** | Something we know could go wrong, and we accept the exposure | Named, owned, mitigated, monitored |
| **Assumption** | Something we are proceeding as if true but have not proven | Named, evidenced (or flagged as hypothesis), validated |
| **Open question** | Something we do not yet know and must answer | Named, owned, due-dated, blocking-flagged |

A risk says "we chose to move forward knowing X could happen." An assumption says "we believe X, and here's how we'll test it." An open question says "we don't know X, and someone owes an answer by a date."

PRDs that merge the three into a single "Risks and Assumptions" table collapse the distinctions and end up with a pile of items that cannot be acted on.

## 2. Risks: the four-column discipline

Every risk has four properties.

### 1. Specific failure mode

Not "adoption risk." Not "technical risk." A specific thing that could fail.

**Pass:** "If the top 3 beta teams do not convert to paid within 60 days of v1 launch, the revenue model is unvalidated."

**Fail:** "Adoption risk."

### 2. Owner

The person accountable for watching the risk. Not "the team." Not "leadership." A named individual.

**Pass:** "Owner: Priya K., VP Product."

**Fail:** "Owner: product team."

### 3. Mitigation

Concrete action we are taking (or will take) to reduce the risk. Not "strong GTM." Not "we will focus on quality."

**Pass:** "Mitigation: Priya will run weekly 1:1s with each beta team's executive sponsor for the first 8 weeks post-launch; week-6 health check explicitly asks about conversion intent. A dedicated onboarding specialist (Anna) is assigned to each beta team. If two of three teams are at-risk at week 4, we escalate to an all-hands meeting for re-scoping."

**Fail:** "Mitigation: focus on customer success."

### 4. Trigger

What we will see if the risk materializes. The observable signal.

**Pass:** "Trigger: any beta team skips 2 consecutive weekly check-ins, or any beta team's usage metric (active seats per week) drops by >40% week-over-week for 2 consecutive weeks."

**Fail:** "Trigger: low adoption."

### Full example

```markdown
### Risk: Beta conversion fails

**Failure mode:** If the top 3 beta teams do not convert to paid within 60 days of v1 launch, the revenue model is unvalidated and the Q3 growth plan needs to be re-scoped.

**Owner:** Priya K., VP Product.

**Mitigation:** Weekly 1:1s with each beta team's executive sponsor for the first 8 weeks. Dedicated onboarding specialist (Anna) assigned per team. Week-6 health check explicitly asks about conversion intent. Escalation trigger: if 2 of 3 teams are at-risk at week 4, all-hands re-scoping meeting.

**Trigger:** Any beta team skips 2 consecutive weekly check-ins, or any beta team's active-seats-per-week drops >40% week-over-week for 2 consecutive weeks.
```

### Common risk categories to consider

- **Adoption / activation.** Will users actually use it?
- **Retention.** Will users stick?
- **Technical / feasibility.** Can we build it in the appetite?
- **Regulatory / compliance.** Will a regulator object?
- **Competitive.** Will a competitor ship first or better?
- **Dependency.** Will a third-party integration fail us?
- **Team / capacity.** Will key people leave or be reassigned?
- **Security / data.** Will a breach or incident undermine trust?
- **Vendor lock-in.** Will we be trapped in a tool we can't replace?

Not every PRD needs risks in every category; a Tier 1 Brief might have 2-3, a Tier 3 Full PRD 6-10.

## 3. Assumptions: the claim-evidence-validation discipline

Every assumption has three properties.

### 1. The claim

The belief we are proceeding as if true.

**Pass:** "We assume that 70% of target users (design-agency PMs at 10-50-person agencies) will reach their first generated status doc within 10 minutes of signup."

**Fail:** "We assume users will love the product."

### 2. The evidence (or explicit lack of evidence)

Why we believe the claim, or explicit acknowledgment that we don't yet have evidence.

**Pass:** "Evidence: 3 qualitative interviews (Jenna M., Priya K., Tom S., Jan-Feb 2026) where users self-estimated that generating their first status doc would take 'less than 10 minutes if the tool did what was promised.' Dogfood test with 5 internal users showed actual first-doc median of 7 minutes (small sample, dogfood context)."

**Pass (no evidence):** "Evidence: none yet. This is a hypothesis based on the PM's domain experience and the problem-severity framing. Validation required before Tier 3."

**Fail:** "Evidence: industry best practices."

### 3. The validation plan

How we will prove or disprove the claim, and when.

**Pass:** "Validation: measure the time-to-first-status metric in Amplitude (`status.generated` event emitted per-user first fire) and check the 50th percentile across new signups at day 14 post-launch. If p50 > 15 minutes, the assumption is invalidated and we will re-examine the onboarding flow."

**Fail:** "Validation: watch the metrics."

### The assumption-soup test

An assumption that does not pass the three-column test is assumption soup. The AI-slop canonical form is:

> "We assume that users will love this feature."

What fails:
- The claim is vague (what does "love" mean operationally).
- There is no evidence.
- There is no validation plan.

The rewrite:

> "We assume that 70% of target users will generate at least one status doc in their first session. Evidence: none yet; hypothesis based on PM interviews where users said they would 'try it right away.' Validation: measure `first_session_status_generated` event fire rate at day 14 post-launch; if below 50%, assumption is invalidated and we will study the onboarding funnel."

Every Tier 2+ PRD's assumptions pass the three-column test. "Users will love it"-style assumptions block the tier.

### Common assumptions to surface

- User behavior: adoption rates, feature discovery rates, retention curves.
- Market: total addressable market, willingness-to-pay, conversion rates.
- Technical: performance at scale, integration reliability, auth-provider uptime.
- Partner / vendor: API stability, SLA adherence, pricing stability.
- Team: velocity, knowledge availability, hiring timeline.
- Regulatory: stability of current regulations, jurisdiction applicability.

## 4. Open questions: the owner-date-blocking discipline

Every open question has four properties.

### 1. The question

The specific thing we don't know.

**Pass:** "How do we handle the case where a user's Asana API token expires mid-generation? Do we prompt them to re-auth immediately (interrupting their flow) or queue the job and notify them on re-auth?"

**Fail:** "Handling token expiration."

### 2. Owner

A named individual accountable for the answer.

### 3. Due date

When the answer is needed. Tied to tier gates when possible.

**Pass:** "Due: May 12, 2026 (blocks Tier 3)."

**Fail:** "Due: soon."

### 4. Blocking flag

Does this block Tier 2 sign-off? Tier 3? Ship? Or is it a post-launch question?

**Blocking levels:**
- **Blocks Tier 2 sign-off.** Must be answered before Spec is signed.
- **Blocks Tier 3 sign-off.** Must be answered before Full PRD is signed.
- **Blocks ship.** Must be answered before launch.
- **Non-blocking.** Answer is useful but does not gate anything.

### Full example

```markdown
### OQ-01: How to handle Asana token expiration mid-generation

**Question:** When a user's Asana API token expires while a status-doc generation job is running (mid-flight), do we: (a) interrupt and re-prompt for re-auth, losing the partial work; (b) queue the job and notify on re-auth; (c) soft-fail the Asana portion and generate from the other sources, with a flagged "Asana data unavailable" note?

**Owner:** Raj P., eng lead.

**Due:** May 12, 2026. Blocks Tier 3 sign-off.

**Current leaning:** (c), because the user-visible flow is least disrupted. Pending a brief eng spike on reliability of partial-source generation.
```

### The Open Questions log visibility rule

The OQ log is visible at the top of the PRD (not buried in an appendix). It is the first thing a reader sees; the first thing engineering checks when deciding "is this buildable yet"; the first thing sign-off reviewers compare against the tier gate.

An Open Questions list buried at the bottom is a list no one reads. Move it to the top; cap it if it gets too long (more than 10 open questions for a Tier 2 PRD means the PRD is too early for Tier 2).

### The OQ life cycle

1. **Added.** Question identified; owner and due date set.
2. **In progress.** Owner is working on the answer.
3. **Answered.** The question is closed; the answer is folded into the appropriate section of the PRD (problem, requirements, NFR, etc.). The OQ entry is updated with the resolution and date.
4. **Deferred.** The question is explicitly punted to a later phase with a new due date and rationale.

Do not delete OQ entries after they are answered; keep them as the PRD's intellectual history. Future readers can trace how decisions were made.

## 5. The three-way boundary

Where does a concern live: risk, assumption, or open question?

- **If we know it could go wrong and we are accepting the exposure:** risk.
- **If we believe it but haven't proven it, and we will test it:** assumption.
- **If we don't know and must find out:** open question.

Edge cases:

- "We assume the market will grow 20%": this is an assumption (claim + should have evidence + should have validation plan).
- "The market might shrink": this is a risk (if it does, here's the mitigation).
- "Will the market grow or shrink?": this is an open question only if answering it changes a PRD decision. If it doesn't, drop from the PRD.

## 6. Common anti-patterns

### "Adoption risk"

Too generic. Rewrite as a specific failure mode. "If the top 3 beta teams do not convert to paid within 60 days, the revenue model is unvalidated."

### "We assume product-market fit"

Not an assumption; not testable. Rewrite as measurable: "We assume that at least 40% of trial users will activate (complete onboarding + generate at least 1 status doc) within their first week. Evidence: 3 interviews suggest strong intent. Validation: measure activation rate at day 28; if below 25%, the PMF assumption is invalidated."

### "TBD" in the OQ log

Not an open question; a placeholder for an open question. Name the question or delete the entry.

### Stale OQs

An OQ with a due date of 2 months ago and no update is a PRD-health signal. Either the question was silently answered and the log wasn't updated (broadcast failure), or the question was silently dropped (scope change without log). Investigate.

### Mitigations that are "strong X"

"Strong GTM," "strong customer success," "strong quality focus." These are not mitigations; they are aspirational adjectives. Replace with concrete actions.

### Triggers that are "low X"

"Low adoption," "low engagement," "low quality." Quantify. "Active-seats-per-week below 40 for 2 consecutive weeks."

## 7. The risk / assumption / OQ section at each tier

- **Tier 1 (Brief).** Minimal: 1-3 top risks, 2-4 key assumptions, 3-8 open questions. Focus on the largest-magnitude uncertainties.
- **Tier 2 (Spec).** Expanded: 3-6 risks with full owner/mitigation/trigger, 4-8 assumptions with full evidence/validation, 5-15 open questions.
- **Tier 3 (Full PRD).** Complete: 5-10 risks, 6-10 assumptions (many validated or close to), 3-10 open questions (most resolved; unresolved ones have explicit deferral rationale).
- **Tier 4 (Launch-Ready).** All open questions resolved or deferred with rationale; risks have active monitoring plans; assumptions are being validated via measurement.

## 8. The assumption-validation tracker

For Tier 3+ PRDs, maintain a separate tracker of assumption validation:

```markdown
### Assumption validation tracker

| ID | Assumption | Validation status | Last check |
|---|---|---|---|
| A-01 | 70% of users reach first status in <10 min | In progress | 2026-05-01 |
| A-02 | Beta teams convert to paid within 60 days | Not yet testable | - |
| A-03 | Asana API reliability sufficient for real-time generation | Validated (99.7% over 30 days, dogfood measurement) | 2026-04-15 |
```

This tracker is the living receipts of the PRD's hypothesis-to-fact progression. Observe-ready can take it over post-launch for ongoing measurement.

## 9. The relationship to scope

Risks, assumptions, and open questions are scoped to the current PRD's claims. A risk that applies to the entire product ("the market might vanish") is not this PRD's risk; it belongs at a higher strategic level.

Keep the section scoped: risks, assumptions, and OQs relevant to the decisions this PRD is making. Cross-link to broader strategic artifacts for company-level risks.

## 10. Sign-off and these sections

Each tier's sign-off (Step 10) specifically checks this section.

- **PM sign-off:** the risks cover the adoption/revenue/market exposure.
- **Engineering sign-off:** the risks cover the technical feasibility and integration exposure; open questions affecting estimability are flagged.
- **Design sign-off:** the risks cover the user-experience edge cases; open questions affecting flow design are flagged.
- **QA sign-off:** the risks cover the test-coverage gaps; open questions affecting acceptance criteria are flagged.
- **Legal / compliance sign-off:** the risks cover the regulatory exposure; open questions affecting compliance posture are flagged.

If a signer cannot attest because an open question in their territory is unresolved, the tier does not pass until the OQ is resolved or explicitly deferred with the signer's agreement.

## 11. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 1.4 (assumption-soup failure mode).
- Ben Horowitz, *Good Product Manager, Bad Product Manager* (1998) on naming risks and owners.
- Ed Catmull, *Creativity, Inc.* (2014) on the Braintrust's role in surfacing project risks.
- Atul Gawande, *The Checklist Manifesto* (2009) for the discipline of structured risk lists vs. narrative.
- Adam Grant, *Originals* (2016) on premortems: imagining failure before it happens.
