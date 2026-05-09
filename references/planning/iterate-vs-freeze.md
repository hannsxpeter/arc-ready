# Iterate vs. freeze: the PRD lifecycle (Step 11)

PRDs change. The question is not whether they change but under what discipline. This reference covers the four lifecycle states, the change-control protocol, when a change is in-scope vs. new-PRD, the broadcast discipline, and when Tier 1 is enough.

## 1. The four lifecycle states

Every PRD is in exactly one of four states at any time.

### State 1: Draft

Pre-Tier 1 sign-off. The PRD is being assembled; decisions are not yet committed.

**Rules:**
- Anyone on the PRD's roster can edit.
- Changes do not require changelog entries.
- Changes do not require broadcasts.
- The PRD is not yet authoritative; engineering does not build from it.

**Exit:** Tier 1 sign-off. Transitions to Living.

### State 2: Living

Tier 1 or Tier 2 signed; the PRD is the source of truth for the team. Work is happening off of it (design, engineering prep, possibly early build), and it will continue to change as more is learned.

**Rules:**
- Edits allowed by the PM and attested signers.
- Every edit writes to the changelog with date, author, section, one-line summary.
- Every edit is broadcast in the team's async channel.
- Re-sign is required for material scope, appetite, or target-user changes.

**Exit:** Tier 3 sign-off. Transitions to Soft-frozen.

### State 3: Soft-frozen

Tier 3 signed; build is in progress. The PRD is now a commitment the team is executing against. Changes should be rare and must be escalated.

**Rules:**
- Changes require PM approval plus broadcast plus impact assessment.
- Clarifications and acceptance-criteria tightening are acceptable.
- Reversals (cutting a feature, changing a Must to Won't) require executive-sponsor approval and Tier 3 re-sign.
- The change-control protocol (section 3 below) is strictly enforced.

**Exit:** Launch. Transitions to Archived.

### State 4: Archived

Post-launch; the PRD is historical. Edits stop; a retrospective is added; the document is linked to the next PRD (if any).

**Rules:**
- No more edits except the post-launch retrospective section.
- PRD is kept in the project repo for historical reference.
- If the product pivots, the archived PRD is referenced from the new one; it is not edited or overwritten.

## 2. The state transition audit

At every transition, audit these:

### Draft -> Living

- All Tier 1 requirements satisfied.
- Tier 1 signers attested.
- Initial changelog entry created.
- Team informed that the document is now authoritative.

### Living -> Soft-frozen

- All Tier 3 requirements satisfied.
- All Tier 3 signers attested.
- Open questions resolved or explicitly deferred with next-review dates.
- Change-control protocol formally adopted (team knows the process).
- PRD's tier badge updated; state badge updated.

### Soft-frozen -> Archived

- Product has launched.
- Tier 4 requirements met (if Launch-Ready tier was pursued).
- Post-launch retrospective scheduled within 30 days.
- Links to the next PRD established (if work continues).

## 3. The change-control protocol

The protocol that governs every change in Living and Soft-frozen states.

### Step 1: Check Out-of-Scope

For any proposed scope change, first check the Out-of-Scope section:

- **Named no-go.** The change violates a prior deliberate decision. Escalate to PM; require explicit reversal.
- **Deferral.** The change is in a later release. Confirm whether the deferral condition has been met; if not, hold.
- **Non-ownership.** The change is not this PRD's territory. Reroute to the owning team.

### Step 2: Check appetite

If the change survives Step 1, check the appetite:

- Does the change fit within the remaining appetite without cutting other work?
- If yes, proceed.
- If no, name what gets cut. Present the trade-off to the requester.

### Step 3: Classify the change

One of three:

- **In-scope clarification.** Wording change, acceptance-criteria tweak, tightening a previously implicit detail. Stays in current PRD, changelog entry, broadcast.
- **Scope adjustment.** Adding a sub-requirement, narrowing an NFR, tightening a no-go. Stays in current PRD, PM sign-off, broadcast, eng-lead re-attestation if estimation is affected.
- **New PRD required.** New feature, new target user, new success metric, >50% appetite delta. Fork a new PRD, cross-link to prior.

### Step 4: Apply the change

- Edit the PRD.
- Add a changelog entry: date, author, affected sections, one-line summary.
- Broadcast in the team's async channel.
- Update any affected handoff artifacts (`.prd-ready/HANDOFF.md` if eng or data).
- Request re-sign from affected signers if scope-adjustment or larger.

### Step 5: Check for drift

Periodically (at each tier gate; at each weekly review), check whether changes have drifted the PRD from its original intent. Signs of drift:

- The current scope is materially different from the original Tier 1 Brief.
- The target user has shifted without explicit recognition.
- Success metrics have been relaxed without business-outcome discussion.
- Appetite has stretched more than 20%.

If drift is detected, raise it to the team. Options: accept the drift (update tier, re-sign, document), reject the drift (cut back to the original scope), or fork (the drift is a pivot; new PRD).

## 4. When a change is "new PRD" vs. "same PRD"

The threshold, informally:

| Change | Same PRD | New PRD |
|---|---|---|
| Acceptance-criteria tweak | x | |
| Wording clarification | x | |
| Adding a sub-requirement to an existing feature | x | |
| Tightening an NFR threshold | x | |
| Narrowing a no-go | x | |
| Adding a new feature | x (if fits appetite, small) | x (if large or changes MoSCoW distribution) |
| Removing a Must feature | | x (usually) |
| Shifting the target user | | x |
| Changing the success metric meaningfully | | x |
| >50% appetite delta | | x |
| Changing the problem framing | | x |

The spirit of the rule: a change that would have materially changed the original sign-off requires a new PRD. A change that the original signers would shrug at can stay.

## 5. When Tier 1 is enough

Not every project needs Tier 3. The decision is not "do we have time for Tier 3" but "does the scope, team, and stakeholder set justify Tier 3."

### Tier 1 (Brief) is sufficient when

- Single-PM / single-engineer project or very small team.
- 2-week or shorter appetite.
- No regulatory exposure.
- No external-customer commitment attached to the ship.
- No marketing pre-announcement.
- Reversible decision (can be undone cheaply if wrong).

Adam Fishman's *PRDs are the worst way to drive product progress* (Hot Take #1) and Marty Cagan's *Discovery over documentation* both argue that most PRDs should stop at the Brief level. The instinct to keep expanding the document often reflects organizational theater, not actual decision-making need.

### Tier 2 (Spec) is sufficient when

- Small team (2-5 engineers, 1 designer, 1 PM).
- 4-8 week appetite.
- No regulatory exposure.
- Internal or low-visibility external ship.
- Design and engineering handoff is the primary need; executive alignment is already secured.

### Tier 3 (Full PRD) is warranted when

- 5+ engineer team or cross-team dependencies.
- 8+ week appetite.
- Regulatory exposure (HIPAA, PCI, SOC 2, GDPR cross-border).
- External customer commitment (signed contract with feature deliverables).
- Major marketing campaign.
- Platform-shift or infrastructure-level project.

### Tier 4 (Launch-Ready) is warranted when

- Public launch with attention (Product Hunt, Show HN, press).
- Paid tier launch.
- New customer-segment launch.
- Post-launch instrumentation and support are load-bearing.

Forcing Tier 4 when Tier 2 would suffice is the "good for many, great for no one" template-bloat failure. Calibrate to the actual project need.

## 6. The broadcast discipline

Every change in Living or Soft-frozen state gets broadcast.

### What "broadcast" means

Posting in the team's async channel (Slack, Discord, Linear comment, email list) with:

- A link to the PRD.
- A summary of the change (one sentence).
- A link to the changelog entry.
- A call for questions by a date.

### Example broadcast

```
PRD Change [project-name]
- Changelog: 2026-04-23, Priya K.: added Slack integration to Out-of-Scope (cut for v1 based on Jan survey; reconsider v1.5).
- Link: /prd-ready/PRD.md#changelog-2026-04-23
- Questions? Reply by 2026-04-26. Default: silence = agreement.
```

### Why broadcast matters

Horowitz's 1998 memo names the failure: "bad product managers update the PRD and don't tell anyone." Engineers stop trusting PRDs that change silently; they revert to hallway conversations, and the PRD becomes theater.

The broadcast is low-effort (2-minute Slack post) and high-leverage (prevents the trust-collapse failure mode).

## 7. Re-sign thresholds

When does a change trigger re-sign vs. just a changelog entry?

| Change type | Changelog only | Re-sign from original signers | New Tier sign-off |
|---|---|---|---|
| Wording clarification | x | | |
| Acceptance-criteria tightening | x | | |
| Adding a sub-requirement | x | x (if eng re-estimation needed) | |
| Adding a new feature within appetite | | x (PM, eng, design) | |
| Removing a Must feature | | x (all affected) | |
| Shifting the target user | | | x (new Tier 1 first) |
| Material success-metric change | | x (PM, data) | |
| NFR threshold change | | x (eng, data, legal if compliance) | |
| Appetite delta >20% | | x (PM, eng, exec sponsor) | |

Default to re-sign when in doubt. Over-communication beats under-communication.

## 8. The dated changelog format

Consistent format across all entries:

```markdown
## Changelog

- **2026-04-23** @priya-k (PM): added Slack integration to Out-of-Scope; evidence: Jan 2026 survey (n=40, 78% on Teams). Reason: cut to make appetite; reconsider v1.5 if Teams ships and users request parity. Affects: Scope section.
- **2026-04-22** @raj-p (eng lead): tightened R-02 (Generate status doc) acceptance criteria to include explicit 15-second p95 latency threshold. Evidence: dogfood data shows 12s median is achievable; adding buffer for 4G. Affects: Functional Requirements.
- **2026-04-20** @mia-l (design lead): updated R-03 (Manual section override) acceptance criteria to include keyboard accessibility. Evidence: WCAG 2.2 AA requirement per NFR. Affects: Functional Requirements.
- **2026-04-19** (Tier 2 signed by @priya-k, @raj-p, @mia-l, @kofi-a)
- **2026-04-17** (Tier 1 signed by @priya-k, @raj-p, @mia-l)
- **2026-04-10** (initial draft from prd-ready skill v1.0.0)
```

Each entry: date, author, affected section, substance of the change, reason. No vague entries ("updated requirements"); always the substance.

## 9. Stale PRD detection

Post-launch PRDs can go stale if the product continues to evolve. Detection signals:

- Customer support references features the PRD doesn't describe.
- Engineering has built a feature not in the PRD (scope-crept in without logging).
- Analytics shows events the PRD didn't specify.
- Marketing describes capabilities the PRD doesn't list.

On detection: run a "refresh" pass (Mode D). Update the PRD with a dated changelog entry; broadcast; re-sign if material.

For PRDs long in archived state, staleness is expected; do not update archived PRDs. Start a new PRD if the project continues.

## 10. Version numbering

The PRD's version number is separate from the skill's version.

Format: major.minor (or major.minor.patch for large-team orgs).

- **Patch** (1.0.1): wording / typo / clarification. Not tracked for most PRDs.
- **Minor** (1.1): scope adjustment, new requirement, NFR change. Tracked.
- **Major** (2.0): new target user, new success metric, pivot-level change. Should probably be a new PRD instead.

## 11. The "should this PRD still exist" question

Periodically (at tier gates, at 30-day post-launch review) ask: is this PRD still earning its keep?

Kill the PRD if:

- No one is consuming it (engineering doesn't read; design doesn't reference).
- The product shipping is materially disconnected from the PRD (the document is not representing reality).
- The project has been shelved; the PRD should be archived, not kept living.

Keeping a living PRD for a dead or divergent project is the "theater PRD" failure. Archive or kill.

## 12. The "living document" principle (Horowitz)

From Ben Horowitz's 1998 memo: the PRD is a living, continually updated document. The good PM:

- Updates daily or weekly.
- Broadcasts updates.
- Explains the "why" of each update.
- Maintains the changelog.
- Re-signs when material changes land.

The bad PM:

- Doesn't have time to update.
- Updates silently.
- Doesn't explain changes.
- Keeps changelog as an afterthought.
- Assumes stakeholders understood the change.

The difference compounds over weeks. A well-maintained living PRD stays useful for the product's whole life; a neglected one calcifies into theater in 6 weeks.

## 13. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 7 (lifecycle patterns).
- Ben Horowitz / David Weiden, *Good Product Manager, Bad Product Manager* (1998).
- Ryan Singer, *Shape Up* (2019), on appetite and fixed-time-variable-scope as change-control discipline.
- Reforge, *Evolving Product Requirements Documents* (2021), three-stage evolution model.
- Adam Fishman, *Hot Take #1: PRDs are the worst way to drive product progress* (FishmanAF newsletter).
