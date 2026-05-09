# scope-vs-time.md

Step 5 (milestone anatomy) and Step 9 (review cadence) material. This file covers the appetite-xor-estimate rule, MoSCoW discipline at milestone level, when to cut scope vs. move the date, the rabbit-hole anatomy, and the polish-indefinitely failure mode.

## 1. Appetite xor estimate

Every roadmap item has either an appetite (fixed time, scope flexes) or an estimate (variable time, scope fixed). Not both. Not neither.

### Appetite (Shape Up)

An appetite is a budget: "We are willing to spend 6 weeks on this" (big batch) or "We are willing to spend 2 weeks on this" (small batch). If the work proves larger than the appetite, scope is cut; the date holds.

The Shape Up discipline: scope is flexed down, not time up. "Fixed time, variable scope" (https://basecamp.com/shapeup/1.2-chapter-03).

### Estimate (classical)

An estimate is a predicted duration: "This takes 3 weeks with confidence band 1-5 weeks." If the work proves larger, either scope cuts or time extends. The team decides at the cycle boundary.

Classical estimation is well-documented as systematically optimistic (Hofstadter's law; Kahneman-Tversky planning fallacy). The confidence-band requirement is the guard: every estimate includes uncertainty honestly.

### The xor rule

An item with an appetite does not also need an estimate. An item with an estimate does not also need an appetite. Combining both confuses the precision reading: "6 weeks, estimated at 4 weeks, confidence band 3-7 weeks" is asserting multiple uncertainties the team does not have discipline to track.

**Neither is not acceptable.** An item with no appetite and no estimate is unsized. An unsized item cannot be committed; it belongs in Next or Later (direction), not Now (commitment).

## 2. MoSCoW at milestone level

Must-have, Should-have, Could-have, Won't-have-this-milestone.

DSDM rule of thumb (Dai Clegg, 1994): no more than 60% of effort in Must; 20% Should; 20% Could as buffer.

### The cut line

The cut line is the boundary between committed (Must + Should) and flexible (Could + Won't). When a milestone is cut-lined, scope pressure cuts from the top of Could downward; Must and Should survive at all costs.

A milestone without a cut line is a milestone that grows until the cycle runs out. Declare the cut line in the milestone definition.

### Won't-have is mandatory

The Won't-have-this-milestone tier exists to prevent scope creep by making exclusions explicit. A proposed addition mid-cycle is first checked against Won't-have: if it's there, the change is escalated (we chose not to do this); if not, it's debated.

A milestone with an empty Won't-have tier is a milestone where nothing has been excluded, which means scope is unconstrained.

### Anti-pattern: everything is Must

If the milestone has 12 items and all 12 are Must, no prioritization has happened. The DSDM rule (no more than 60% Must) forces the team to articulate what is load-bearing vs. desirable. Violate the rule and the tiers are decorative.

## 3. When to cut scope vs. when to move the date

The tradeoff:

- **Cut scope** when the time is load-bearing (launch tied to external date, contract clause, regulatory window, appetite is fixed).
- **Move the date** when scope is load-bearing (fixed-scope commitment, high-integrity commitment with a named reason).

The default (Shape Up's stance): cut scope. Dates are cheap to hold; scope is cheap to cut; extending dates is how timelines die.

### Named exceptions

- **Regulatory dates.** "SOC 2 audit begins 2026-07-15" is fixed. Scope cuts, but if minimum-viable compliance exceeds available time, the team either adds capacity or accepts the audit delay (business decision, not a roadmap decision).
- **Partner launches.** "Integration goes live with X on 2026-06-20" is fixed if the partner is not negotiable. Scope cuts ruthlessly.
- **Contractual SLAs.** "Customer Y's delivery date is 2026-06-01 per contract" is fixed. Same logic.
- **Conference demos.** Sometimes fixed, sometimes negotiable. Clarify with the business.

In every case, the fixed date is a high-integrity commitment (see [`roadmap-anatomy.md`](roadmap-anatomy.md) section 2.9). Label it explicitly; require Tier 3 sign-off.

### The polish-indefinitely failure

The common pattern: team picks an ambitious milestone, discovers mid-cycle that "one more iteration" improves it, iterates beyond appetite, ships late. Shape Up's circuit-breaker addresses this exactly: at the appetite boundary, ship or cut; do not extend by default.

Signals the team is in polish-indefinitely mode:

- Current milestone is 1+ week past its target date; no explicit extension decision was recorded.
- Every standup discusses "just one more thing" on the current item.
- The team is not talking about the next milestone; all attention is on polishing the current.

Fix: ship what's there (even if imperfect); move remaining polish to the next milestone's backlog; hold the circuit-breaker.

## 4. Rabbit hole anatomy

Shape Up term (Singer, chapter 5). A rabbit hole is an anticipated risk that could blow up the scope of an item or milestone.

Every rabbit hole has three parts:

1. **What could go wrong.** Specific failure mode. "Full CRDT sync for real-time collaboration is a large, hard-to-bound scope."
2. **Why it is tempting to over-build.** The attractive nuisance. "CRDT feels complete; optimistic locking feels like a hack."
3. **Smallest version that avoids the rabbit hole.** The alternative to pursue. "Optimistic locking with last-writer-wins plus a 'refresh to see latest' banner. Full CRDT is a v3 rescoping question."

### Grep-testable rabbit-hole pattern

Every active milestone (Now column) has at least one named rabbit hole. If zero rabbit holes, either the work is genuinely trivial (flag as suspiciously simple) or the rabbit holes have not been thought about.

### Rabbit holes vs. risks

Adjacent but distinct:

- A **risk** is something that could happen outside the team's control (vendor pricing change, partner slip, regulatory shift).
- A **rabbit hole** is something the team itself could fall into by over-building.

Both are logged; they are separate sections. Risks have owners, mitigations, and triggers. Rabbit holes have smallest-version alternatives.

## 5. When to extend the appetite

The default is cut, not extend. But Shape Up names one legitimate extension: "betting more on the same bet" at the next betting table. If a bet was partially completed and the team chooses to bet on the remainder for the next cycle, that is an explicit decision at the cycle boundary, not a mid-cycle drift.

The discipline:

- **Mid-cycle extension:** forbidden by default. Fire the circuit-breaker at the cycle boundary.
- **Cycle-boundary re-bet:** allowed. The team explicitly bets the next cycle on completing the remainder. This is a conscious decision with a named reason ("the first cycle proved the core; finishing the edges is worth another 6 weeks").

A team that re-bets on the same bet repeatedly (3+ cycles on the same item) has a different problem: the appetite was wrong, or the scoping was wrong, or the work is intractable and should be cut.

## 6. Scope cut mechanics

When scope must be cut, the procedure:

1. **Identify the cut line.** Must / Should / Could / Won't from the milestone's MoSCoW.
2. **Cut from the top of Could downward.** First: everything in Could. Then: Should items in priority order.
3. **Protect Must.** If Must alone exceeds the appetite, the milestone was over-committed at planning time; re-scope by removing items from Must (with explicit decision) or extend (with high-integrity commitment label).
4. **Record what was cut and why.** Cut items go to "deferred" with a one-line reason.
5. **Broadcast.** The cut is announced to the team and any stakeholders who had visibility into the original scope. Silent cuts are moving-target-roadmap failures.

## 7. Scope growth mid-cycle

The inverse problem. A proposed addition appears mid-cycle: a stakeholder asks, a customer requests, a new idea emerges. The procedure:

1. **Check against Won't-have.** If the item is explicitly Won't-have, the proposal is rejected or escalated.
2. **Check against rabbit holes.** If the item is a rabbit hole already named, the proposal is rejected.
3. **Check capacity margin.** If the current cycle has no margin, the item goes to the next cycle's backlog.
4. **Check cut-line discipline.** If the item is a Must that displaces an existing Must, the team is not adding scope; it is re-scoping. Requires explicit decision.
5. **Default response:** route to the next cycle.

A team that accepts every mid-cycle addition is a team that has no cycle discipline. A team that never accepts additions is brittle. The discipline is explicit: procedure above, not "feels right."

## 8. Appetite-setting examples

**Example 1: onboarding redesign.**

- Target outcome: new signups reach first-value in under 10 minutes at p75.
- Appetite candidates: small batch (2 weeks), big batch (6 weeks), larger (not available in Shape Up; would need to be re-shaped).
- Team assessment: the redesign touches 4 pages and 3 backend endpoints. Small batch (2 weeks) is insufficient. Big batch (6 weeks) is plausible if scope is tight.
- Chosen appetite: big batch, with rabbit holes named (tempting: rewrite auth flow; smallest version: keep current auth, only change post-auth flow).

**Example 2: SSO integration.**

- Target outcome: enterprise customers can log in via their IdP.
- Appetite candidates: small batch (2 weeks), big batch (6 weeks).
- Team assessment: SSO via SAML is well-understood; OIDC is straightforward; the hard part is the admin UI for configuring per-tenant. Small batch is possible for a single IdP (Okta) without admin UI; big batch for multi-IdP with admin UI.
- Chosen: small batch for Okta MVP; admin UI deferred to Next cycle.

**Example 3: migration to Postgres 16.**

- Target outcome: database on supported major version.
- Appetite candidates: small batch.
- Team assessment: straightforward via pg_upgrade in maintenance window. 1 week of prep, 1 hour of downtime, 1 week of post-validation.
- Chosen: small batch. No rabbit holes expected; flagged anyway ("tempting to refactor schema as part of the upgrade; smallest version is pure upgrade, no schema changes").

## 9. Summary

Every item has appetite or estimate. No item has both; no item has neither. Rabbit holes are named; scope cuts are the default when the appetite binds; fixed dates are labeled as high-integrity commitments with named reasons. The polish-indefinitely pattern is surfaced by the circuit-breaker.
