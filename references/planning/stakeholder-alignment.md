# Stakeholder alignment and sign-off protocol (Step 10)

Sign-off is what makes a PRD binding. An unsigned PRD is a draft regardless of how polished it reads. This reference covers the sign-off roster by tier, the per-role attestation pattern, the pre-sign-off walkthrough, common disagreements and how to resolve them, and what "done" means at each tier.

## 1. The sign-off principle

A PRD is not done when the PM declares it done. It is done when the named stakeholders have attested in writing that the document reflects what they have agreed to.

Two failure modes this prevents:

- **The "I didn't know" failure.** Engineer at week 3 of build: "Wait, we are shipping this? Nobody asked me whether the scope was estimable." Sign-off forces the conversation before build, not during.
- **The "we have decided" ambiguity.** "The team decided to ship X" -- but who specifically decided? Sign-off creates an accountable record.

## 2. Sign-off roster by tier

| Tier | Required signers |
|---|---|
| **Tier 1 (Brief)** | Product manager + one engineering lead + one design lead |
| **Tier 2 (Spec)** | Tier 1 signers + QA lead or equivalent |
| **Tier 3 (Full PRD)** | Tier 2 signers + data/analytics + legal/compliance (if regulated) + customer support |
| **Tier 4 (Launch-Ready PRD)** | Tier 3 signers + marketing/product marketing + executive sponsor |

If a role does not exist at the org (no dedicated QA, no data person, no legal team), the PM names who plays the role for this PRD. "No QA" is fine; "no one attested to testability" is not.

## 3. Per-role attestation

Each signer attests to a specific thing, not a blanket "approved." This specificity protects the PRD from the "I signed it but I didn't read the XYZ section" failure.

### Product manager

Attests to:
- Problem framing is accurate to the user research we have.
- Target user is correctly scoped.
- Success metrics are measurable and align with the business outcome.
- Scope and no-gos reflect deliberate trade-offs.
- Appetite is a commitment, not a guess.

### Engineering lead

Attests to:
- Functional requirements are estimable (the team can give point estimates or week estimates without another round of Q&A).
- Non-functional requirements are achievable in the stated appetite, or the gaps are flagged.
- Acceptance criteria are testable.
- Rabbit holes are identified; smallest-version alternatives are acceptable.
- Dependencies are named accurately.
- The PRD does not contain implementation prescriptions that would constrain architecture-ready's work inappropriately.

### Design lead

Attests to:
- User flows implied by the requirements are coherent.
- The target user is recognizable as a real person design has studied.
- Non-goals do not strand the user (cutting X does not leave the user unable to do Y).
- Visual-identity direction (Tier 3+) is actionable.

### QA lead

Attests to:
- Acceptance criteria are testable (automated, manual, or user-acceptance).
- Edge states (error, empty, rate-limited) are named.
- Observability requirements support test-environment validation.
- The test plan implied by the PRD is achievable in the appetite.

### Data/analytics

Attests to:
- Success metrics are measurable with existing or committed-to instrumentation.
- Events and dashboards are named, not just described.
- The metric's data source is live (or the plan to make it live is in scope).

### Legal/compliance

Attests to:
- Compliance constraints are correctly scoped (HIPAA does or does not apply; GDPR obligations are named; data-residency is addressed).
- Data-handling requirements align with privacy policy and regulatory posture.
- Third-party processor agreements are identified (DPAs, BAAs, SCCs).

### Customer support

Attests to:
- Failure modes and edge states are documented enough to triage.
- Support runbook can be written from this PRD.
- Expected support volume is named; staffing plan exists or is flagged.

### Marketing / product marketing

Attests to:
- Launch criteria and rollout plan are coordinated.
- Messaging is consistent between PRD (internal) and launch surfaces (external).
- The launch-ready handoff is planned, not assumed.

### Executive sponsor

Attests to:
- Strategic alignment with company priorities.
- Investment authorization.
- The trade-offs made in scope and appetite are appropriate for the company's current phase.

## 4. The sign-off ledger

A table at the bottom of the PRD (or in the changelog section), updated as signers attest:

```markdown
## Sign-off ledger

| Role | Signer | Date | Attestation | Tier |
|---|---|---|---|---|
| PM | Priya K. | 2026-04-22 | Problem + target user + success + scope + appetite | 1 |
| Eng lead | Raj P. | 2026-04-22 | Requirements estimable, NFRs achievable, AC testable | 1 |
| Design lead | Mia L. | 2026-04-22 | Flows coherent; user recognizable; non-goals OK | 1 |
| QA lead | Kofi A. | 2026-04-25 | AC testable; edge states named | 2 |
| Data | - | pending | - | 2 |
| Legal | - | not applicable (no regulated data at v1) | - | 2 |
```

"Pending" is acceptable for work in progress; "not applicable" with a reason is acceptable for roles that do not apply; an empty row (role listed but no sign) is a blocker.

## 5. The pre-sign-off walkthrough

The sign-off is not a Slack thumbs-up. It follows a walkthrough, usually 30-60 minutes depending on tier.

### Walkthrough structure

1. **PM reads the PRD top to bottom**, pausing at each section to ask the signers whether they have questions.
2. **Each signer calls out their attestation area as they read.** Eng lead interrupts at the Requirements section; design lead interrupts at the Target User section; etc.
3. **Open questions are logged, not debated.** If an unresolved question surfaces, log it as an OQ with an owner and a due date; do not attempt to resolve in the walkthrough.
4. **Sign-off happens after the walkthrough**, via whatever mechanism the org uses (PR review, Google Doc comments, Confluence approvals, Linear issue status, literal signature).

### Asynchronous sign-off

For distributed teams, synchronous walkthroughs are often impractical. The async equivalent:

1. PM posts the PRD with a note: "Please review by [date]. Attest by commenting with your name + date + attestation."
2. Each signer reads and comments.
3. Questions surfaced in comments are either answered inline (small) or logged as OQs (larger).
4. When all attestations are in, the PM marks the tier as signed.

Async sign-off takes longer but produces a durable record.

## 6. Common disagreements and how to resolve

### "I don't think the requirement is estimable"

Engineering leads often flag this. Resolutions:

- **Refine the requirement.** Add acceptance criteria until the estimable threshold is reached.
- **Flag as an open question.** If the requirement cannot be estimated without research (a spike), log the spike as an OQ blocking sign-off.
- **Accept the open question as non-blocking.** If the requirement is Should or Could and estimability is uncertain, accept and plan for estimation later in the cycle.

### "This is out of scope, but marketing is already talking about it"

Marketing pre-announcements that exceed PRD scope create vapor-promise pressure. Resolutions:

- **PM owns the marketing alignment.** Walk marketing through the scope and agree on what is publicly promised.
- **If marketing insists on the feature, it is now in scope.** Bring it into the PRD, update MoSCoW, re-sign the tier.
- **If the feature cannot be added, marketing updates their messaging.** Document in the changelog.

### "We have no data person; I can't attest to measurability"

If the org has no data/analytics role, the PM or eng lead covers it, but the attestation is specific: "PM attests to measurability based on [named instrumentation or plan]." This records who is accountable even when the role is missing.

### "Legal isn't sure about the compliance posture"

Delays Tier 3 sign-off. Resolutions:

- **Defer to Tier 3 gate only.** Tier 2 can still sign without legal if the doc is not yet committing to compliance claims.
- **Commission a legal review.** If the compliance question is load-bearing (HIPAA, GDPR), sign-off is blocked until the review lands.
- **Reduce scope to side-step compliance.** Some teams cut the regulated feature to ship the non-regulated parts on schedule.

### "I want to add a feature during sign-off"

Feature-creep during sign-off is the moving-target-PRD failure in motion. Resolutions:

- **Check against Out-of-Scope.** If the feature is a named no-go, do not add; escalate if the requester insists.
- **Check against appetite.** If adding the feature exceeds appetite, the PM names what else is cut.
- **Log the request as a change proposal.** Tier can still sign on the current PRD; the change proposal runs separately.

## 7. What "done" means at each tier

- **Tier 1 (Brief) signed:** the team has alignment on the problem, the user, the target outcome, and the appetite. Go/no-go is decided; the team can invest in Tier 2 work.
- **Tier 2 (Spec) signed:** engineering, design, and QA have read the requirements and attested they can work from them. Build planning can start.
- **Tier 3 (Full PRD) signed:** the PRD is build-ready. All stakeholders (eng, design, QA, data, legal, support) have attested. Build executes; change-control protocol is active.
- **Tier 4 (Launch-Ready) signed:** the PRD is ship-ready. Measurement is instrumented; support runbook exists; launch plan is coordinated with launch-ready. The release can ship when the team is ready.

Note: signed does not mean "cannot change." Living and Soft-frozen PRDs change often; the change-control protocol (Step 11) governs how.

## 8. Sign-off and the skill's hand-off

When Tier 2 signs, prd-ready invites the user to invoke downstream skills:

- **stack-ready** (live, v1.1.5) consumes the Stack-ready handoff block.
- **architecture-ready** (not yet released) consumes the Architecture-ready block when released.
- **roadmap-ready** (not yet released) consumes the Roadmap-ready block when released.
- **production-ready** (live, v2.5.6) consumes the Production-ready block when build starts.

If the harness exposes a skill-invocation tool (Claude Code's Skill tool), invoke the sibling directly. Otherwise, tell the user: "PRD is Tier 2-signed. Install [sibling] or run it now." Do not generate the sibling's output inline.

## 9. The "who isn't in the room" check

Before declaring a tier signed, list the people who are not on the roster. For each:

- Would they object to anything in the PRD?
- Does their absence create downstream friction?

Common omissions:

- **On-call engineer.** Has opinions about observability, rollback, and reliability that eng lead may not catch.
- **Security reviewer.** For anything touching auth, payments, or PII.
- **Customer success / account management.** Knows what customers are already promised vs. what we're shipping.
- **Junior designers or engineers.** Often the ones who will actually build and ship; their input on acceptance criteria is valuable.

The PRD's sign-off roster is a minimum, not a maximum. Add signers if the PRD touches their territory.

## 10. The "re-sign on change" rule

Changes to a PRD after a tier is signed may require re-sign. The change-control protocol (Step 11) governs which changes trigger re-sign:

- **In-scope clarifications.** No re-sign needed; changelog entry + broadcast.
- **Scope adjustments within appetite.** PM re-signs; eng lead re-sign if affecting estimates; broadcast.
- **New requirements or changed appetite.** Full tier re-sign. If the change is large enough to be a pivot (Step 0 Mode E), new PRD.
- **Changed NFRs** (loosening or tightening). Eng lead + data + legal re-sign, as applicable.
- **Changed compliance posture.** Legal re-sign mandatory.

## 11. Storage and retrieval

The sign-off ledger lives in the PRD itself (`.prd-ready/PRD.md`), not in a separate tool. The PRD is the single source of truth; having sign-off records in Linear, Slack, and email ledgers fragments the record.

For orgs that require separate approval records (some enterprises, regulated industries): keep the PRD's ledger as the primary and pointer-link to the org's approval system. Do not maintain two competing records.

## 12. The "signer is wrong" case

Occasionally a signer attests to something that turns out to be wrong (eng lead attests "estimable," team finds it isn't at week 3). Handling:

- **No blame game.** Attestations are good-faith, not infallible.
- **Rescue mode (Step 0 Mode F).** The PRD is underspecified; run the rescue workflow to fix.
- **Update the PRD, not the signature.** Do not retcon the sign-off ledger; add a new changelog entry explaining what changed and why. The historical attestation remains valid for what was known at the time.

## 13. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 7.4 (sign-off protocols, signers per role).
- Ben Horowitz, *Good Product Manager, Bad Product Manager* (1998) on broadcast discipline.
- Andy Grove, *High Output Management* (1983) on who-signs-off-on-what.
- Perforce, *How to Write a PRD* on sign-off rosters.
- Guru, *PRD Reference* on tracking approvals and versions.
