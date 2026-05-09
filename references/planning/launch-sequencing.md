# launch-sequencing.md

Step 7 material. This file covers launch milestone identification, launch modes, readiness gates, the D-calendar, slip protocol, and the Mode F (freeze) discipline.

## 1. What counts as a launch

A launch is any external announcement that takes one-time amplification: a moment where external attention is concentrated and the product's first impression is made. Examples:

- **Hard launch / GA.** Product is officially for sale / open to all; distinct from beta.
- **Soft launch.** Limited release to 50-500 early users; 2-8 weeks; feedback-and-fix focus.
- **Beta.** Invite-only or public-opt-in; explicit "not GA"; feedback loop active.
- **Waitlist-to-GA.** Pre-launch waitlist, gradual invite waves, eventually open. Waitlist members convert ~10x better than cold traffic.
- **Product Hunt.** Orchestrated single-day spike; 6-week lead-up typical; 12:01 AM PT launch time.
- **Show HN / Launch HN.** Hacker News first-impression post.
- **TechCrunch-day or press-day.** Orchestrated press coverage on a named date.
- **Conference demo.** Public reveal at a conference keynote or booth.
- **Internal launch.** Cross-team rollout inside a company; less intense than public but still a coordinated event.

A project can have multiple launches (beta, then GA, then Product Hunt). Each gets its own launch-milestone block.

A project can have zero launches (internal tool, pre-product-market-fit experiment, rewrite of an already-launched product). The launch-milestone block is simply "not applicable" in that case.

## 2. The seven launch-milestone fields

Every launch milestone in the roadmap has all seven:

### 2.1 Launch mode

One of the named modes in section 1. Determines the D-calendar shape, the pre-launch dependencies, and the external-commitment pattern.

### 2.2 Target date

With a confidence band. Acceptable forms:

- "2026-07-15, 60% by this date, 90% by 2026-08-15."
- "Late July 2026, soft target."
- "End of Q3 2026."

Not acceptable: "2026-07-15" with no band and no high-integrity-commitment label. A single-point launch date with 100% implied is a commitment; label it or soften it.

### 2.3 Readiness gates

At minimum four, each a sub-milestone with its own target date:

- **Observability live.** Dashboards built; alerts wired; SLOs authored; on-call rotation assigned. Feeds observe-ready.
- **Rollback tested.** Rollback path exercised end-to-end (not just documented); rollback window confirmed. Feeds deploy-ready.
- **Runbooks reviewed.** Incident response runbooks exist; support team knows where they are; on-call can find them in under 90 seconds. Feeds launch-ready's runbook.
- **Support team briefed.** Customer support or community moderators trained on the product; top 5 failure modes documented with triage steps.

A launch without dated readiness gates is unsequenced. It is a launch plan on paper, not a launch plan in time.

### 2.4 Pre-launch dependencies

Items in earlier milestones that must ship before the launch milestone is coherent. Drawn from:

- **Architecture DAG.** Components the launch depends on must be stable.
- **PRD release-gating criteria.** Features the PRD requires at launch.
- **External commitments.** Partner integrations, platform approvals (App Store, Product Hunt hunter confirmation).

Each pre-launch dependency is a roadmap item with its own milestone and target date. The launch-milestone's confidence band is bounded by the riskiest pre-launch dependency.

### 2.5 D-calendar

Day-by-day markers before and after D-0 (launch day). Minimum markers: D-30, D-14, D-7, D-1, D-0, D+7.

Typical D-calendar content:

- **D-30.** Feature-complete target; content and assets in draft. Marketing and support teams aware.
- **D-14.** Dogfooding complete; critical-path issues triaged; rollback tested end-to-end.
- **D-7.** Code freeze (or flag-freeze); press outreach begins; support runbooks reviewed; on-call schedule locked. **launch-ready's runbook starts here.**
- **D-1.** Final go/no-go; dashboards watched; rollback rehearsed.
- **D-0 (launch day).** Announcement; monitoring; hot-fix capacity reserved.
- **D+7.** Post-launch retrospective and stabilization; support volume review.

For smaller launches (soft launch, beta), a compressed D-calendar (D-7, D-0, D+7) may suffice. For orchestrated launches (Product Hunt, press day), the full D-30 through D+7 is typical.

### 2.6 Slip protocol

The rule for "the launch has slipped." Default: Shape Up's circuit-breaker. Re-shape, do not extend.

**Named exceptions** that must hold the date despite scope pressure:

- **Regulatory.** "SOC 2 audit begins 2026-07-15; GA must precede."
- **Partner-committed.** "Integration announcement with X is contractually fixed to their keynote 2026-06-20."
- **Platform-coordinated.** "Product Hunt launch is scheduled; moving means losing the hunter."
- **Contractual SLA.** "Customer Y's delivery date is 2026-06-01 per contract."

Non-exceptions (the date moves if the scope binds):

- "We told investors Q2."
- "The marketing team is excited."
- "Competitive pressure."

Slip protocol is declared at milestone creation. When the slip happens, the declared protocol executes; there is no mid-slip negotiation.

### 2.7 External commitments

Hard dependencies on the launch date from outside the team:

- **Press briefings.** Journalists briefed under embargo. Usually D-14 to D-7.
- **Partner announcements.** Co-marketing partners coordinated.
- **Platform coordination.** Product Hunt hunter confirmed (D-14 by convention); HN submitter account chosen (must have prior HN activity; see launch-ready); Reddit community moderator notified if needed.
- **Internal coordination.** Exec team ready for questions; sales team ready for inbound.

Each external commitment is a separate line with its own date and owner.

## 3. Connection to launch-ready

`launch-ready` v1.0.2+ is the downstream skill that runs the launch. It consumes the launch-milestone block from ROADMAP.md and the "Launch-ready inputs" sub-section from HANDOFF.md.

launch-ready's Step 0 (mode detection) reads the launch mode. Its Step 11 (launch-week runbook) reads the D-calendar. Its D-7 runbook start date is the D-7 marker in the roadmap. If the D-7 marker is missing, launch-ready cannot start.

The contract: the roadmap produces the calendar; launch-ready runs the calendar. roadmap-ready does not write landing-page copy, OG cards, or launch-post drafts; launch-ready does. launch-ready does not decide the launch date or the readiness gates; roadmap-ready does.

## 4. Connection to observe-ready and deploy-ready

The three readiness gates (observability live, rollback tested, runbooks reviewed) are shared responsibility:

- **Observability live** is owned by observe-ready. roadmap-ready names the target date; observe-ready authors the SLOs and dashboards.
- **Rollback tested** is owned by deploy-ready. roadmap-ready names the target date; deploy-ready sets up the rollback path and tests it.
- **Runbooks reviewed** is owned by launch-ready (or the team's internal ops practice). roadmap-ready names the target date; the owners produce the runbooks.

If any of the three siblings is not installed, the team owns the gate directly. The gate exists whether the sibling is installed or not; the skill is not a substitute for the gate content.

## 5. Mode F: the freeze

When the launch milestone is within D-14, the team enters Mode F (freeze). The discipline:

- **No new items accepted** into the launch milestone. Every proposed addition is routed to the next-milestone backlog.
- **Every open question** either resolves before D-7 or explicitly blocks the launch. No "we'll figure it out on launch day."
- **Scope cuts only**, not scope additions. A cut is announced; an addition is refused.
- **Daily review at D-7 through D-0.** Dashboards watched; rollback rehearsed; support team on standby.

The freeze is the final cut-line discipline. Without it, the last two weeks become "just one more thing" until the launch ships with unvalidated additions.

## 6. Post-launch: D+7 transition

The D+7 marker is the post-launch retrospective and stabilization. Specifically:

- **Retrospective written.** What launched vs. what planned; what broke; what worked. Input to Mode C (iteration) at the next cycle.
- **Traffic within 3x baseline.** If launch-day traffic is still 10x baseline at D+7, the launch is not stable; extend support coverage.
- **Support volume review.** Top 5 post-launch issues triaged; any that are not resolvable in the current milestone are added to the next milestone.
- **Second-launch timing.** If a second launch is planned (beta -> GA, GA -> Product Hunt), the minimum window is 6-12 weeks. A second launch within D+7 is premature.

D+7 is owned by launch-ready; roadmap-ready names the target date.

## 7. Common launch-sequencing failures

### Feature-complete is not launch-ready

A milestone labeled "feature-complete" often has no observability, no tested rollback, no runbooks. Launching on feature-complete alone is a crisis ready to happen. The D-14 gate ("dogfooding complete; critical-path triaged; rollback tested") exists to surface this.

### Parallel launches on the same day

Product Hunt + Show HN + launch email + press day + blog post, all on D-0. This is tempting (maximum concentration) but collapses onto a single failure mode: if anything breaks, all five channels see the breakage.

The safer pattern: stagger. Show HN or PH at 12:01 AM PT; email drop at 7 AM PT; press embargo lifts at 9 AM PT. See launch-ready's D-calendar for the hour-by-hour.

### Launch milestone with no pre-launch dependencies

"Launch M5" with no architecture components named, no PRD release criteria, no external commitments. The launch exists in the roadmap but not in the sequence. Flag and re-build the dependency list.

### D-calendar with no D-7

The launch milestone has D-30 and D-0 but no D-7. launch-ready cannot start its runbook. Fix by adding D-7 with the code-freeze and press-outreach content.

### Slip protocol not declared

When the launch slips (and launches do slip), the team scrambles to decide hold-vs-move. The declaration at milestone creation prevents the scramble: the rule was pre-committed.

## 8. Launch-milestone template

Recommended content for each launch-milestone entry in ROADMAP.md:

```markdown
### Launch milestone: [name]

- **Mode:** [from section 1]
- **Target date:** [date with confidence band]
- **Slip protocol:** [hold / re-shape / named exception]
- **High-integrity commitment label (if hold):** [named reason]

#### Readiness gates

| Gate | Target date | Owner |
|---|---|---|
| Observability live | [date] | observe-ready (or direct owner) |
| Rollback tested | [date] | deploy-ready |
| Runbooks reviewed | [date] | launch-ready (or team) |
| Support briefed | [date] | support team |

#### D-calendar

| Marker | Date | Focus |
|---|---|---|
| D-30 | [date] | feature-complete target |
| D-14 | [date] | dogfooding + rollback tested |
| D-7 | [date] | code freeze + press outreach + runbook review (launch-ready runbook starts here) |
| D-1 | [date] | go/no-go + rollback rehearsed |
| D-0 | [date] | launch |
| D+7 | [date] | retrospective + stabilization |

#### Pre-launch dependencies

- M[N]: [milestone that must complete first]
- PRD R-[N]: [release-gating criterion]
- External: [commitment, e.g., "App Store review cleared"]

#### External commitments

- Press briefings: [target publications; embargo date]
- Partner announcements: [partners; co-marketing date]
- Platform coordination: [PH hunter / HN submitter / etc.]
```

## 9. When there is no launch

For internal tools, research projects, or maintenance roadmaps, the launch-milestone section is "not applicable" with a reason:

```markdown
### Launch milestone

Not applicable: this roadmap is for internal dogfood iteration. There is no public launch planned. Public-roadmap derivative is not produced.
```

This explicit "not applicable" is required; a silent omission is read as "launch TBD" which is different.

## 10. Summary

A launch milestone is a named event with a target date and readiness gates. The mode determines the calendar. The D-calendar anchors launch-ready's runbook. Slip protocol is declared in advance. Mode F enforces the pre-launch cut-line. A launch without readiness gates is unsequenced; a date without a slip protocol is a surprise waiting to happen.
