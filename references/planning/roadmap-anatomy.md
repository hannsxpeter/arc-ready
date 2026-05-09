# roadmap-anatomy.md

Step 5 (milestone anatomy), Step 6 (Now-Next-Later), and Step 10 (public derivative) material. This file contains the canonical ROADMAP.md template with annotations, milestone anatomy, horizon structure, and the redaction rules for public derivatives.

## 1. The ROADMAP.md template

The canonical Markdown structure. Every section is mandatory at Tier 2 or higher unless explicitly annotated as conditional.

```markdown
# [Project name] Roadmap

**Tier:** Sketch / Plan / Committed / Public-ready
**State:** Draft / Living / Soft-frozen / Archived
**Last updated:** [ISO date]
**Review cadence:** [frequency]
**Skill version:** roadmap-ready 1.0.0

## Changelog

- **[ISO date]** [what changed, in one line]

## Mode and context

**Mode:** A / B / C / D / E / F (from Step 0).
**Upstream:** PRD at Tier [N]; ARCH at Tier [N]; STACK [declared / pending].
**Audience:** internal only / mixed / public.

## Cadence

We chose **[cadence name]** because [team size + risk tolerance + customer expectations].

Alternatives considered:
- **[rejected cadence 1]**: [why not]
- **[rejected cadence 2]**: [why not]

Trigger for re-evaluation: [named condition].

## Pre-flight answers

- Team capacity: [N engineers; M engineer-weeks per cycle]
- Horizon: [length]
- Hard external dates: [list, or "none"]
- Risk tolerance: [level]
- Existing commitments: [list, or "none"]
- Upstream state: [PRD tier, ARCH tier]

## Now (current cycle: [YYYY-Qn or ISO range])

| Slice | Owner | Appetite or size | Outcome or commitment | PRD ref | Architecture ref | Depends on | Status | Last reviewed |
|---|---|---|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

Capacity: planned X engineer-weeks of Y available. Margin: Z engineer-weeks.
Risk register this cycle:
- [Risk 1]: [mitigation]
- [Risk 2]: [mitigation]

## Next (directional; [range])

| Theme | Target outcome | Confidence band | PRD ref | Status |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

## Later (thematic)

- **Theme 1:** [outcome direction]; [rough horizon]
- **Theme 2:** ...

## Milestones

### M1: [Name]

- **Target:** [date with confidence band, or range, or appetite]
- **Completion gate:** [yes/no condition]
- **In-scope:** [enumerated items, each with PRD and architecture ref]
- **Out-of-scope:** [enumerated with reasons]
- **Rabbit holes:** [each with smallest-version alternative]
- **Dependencies:** [upstream milestones from DAG]
- **Cutover cadence:** [when this ships to production]

### M2: [Name]
...

### Launch milestone (if applicable)

- **Mode:** hard / soft / beta / GA / Product Hunt / ...
- **Target date:** [YYYY-MM-DD, confidence band]
- **D-calendar:** D-30 [date] / D-14 [date] / D-7 [date] / D-1 [date] / D-0 [date] / D+7 [date]
- **Readiness gates:**
  - Observability live: [date, owner]
  - Rollback tested: [date, owner]
  - Runbooks reviewed: [date, owner]
  - Support briefed: [date, owner]
- **Pre-launch dependencies:** [milestones that must complete first]
- **External commitments:** [press, partners, platforms]
- **Slip protocol:** [hold / re-shape / exception with named reason]

## Review cadence

- **Frequency:** [per-betting-table / monthly / per-PI / etc.]
- **Authority map:** [who changes what at what level]
- **Re-plan triggers:** [named conditions]
- **Freeze conditions:** [when the roadmap is frozen]
- **Freshness check:** [staleness threshold]
- **Archive rule:** [completed milestones archived, not overwritten]

## Deferred and cut items

- [Item]: [reason cut; link to prd-ready if routed back]
- [Item]: [reason cut]

## Sign-off ledger (if Tier 3)

- PM: [name, date, attestation]
- Eng lead: [name, date, attestation]
- Design lead (if design work): [name, date, attestation]
- Exec sponsor (if launch): [name, date, attestation]
- Legal / compliance (if regulated): [name, date, attestation]

## Downstream handoff

See [`HANDOFF.md`](HANDOFF.md).
```

Every row in Now has an "outcome or commitment" column. This enforces the three-label test at the data level: the column contains either an outcome frame ("increase activation by 20%") or a commitment label ("high-integrity commitment: regulatory deadline 2026-07-01") or a named open question ("OQ-03: does the new onboarding reach p75 first-value under 10 minutes").

## 2. Milestone anatomy

A milestone is a named set of slices with a completion gate. The 8 required fields:

### 2.1 Name

Concrete and recognizable. "M2: Onboarding redesign" is a milestone. "Q2 Objectives" is a heading. "Growth initiatives" is a theme. A milestone name should survive the substitution test against other products: if the same name would fit any SaaS in the category, it's a heading, not a milestone.

### 2.2 Target date or date range

Three acceptable forms:
- **Date with confidence band:** "2026-06-30, 70%."
- **Range:** "End of June 2026," "Q2 2026."
- **Appetite:** "6 weeks from start" (Shape Up); "one PI" (SAFe).

Not acceptable: single-point date with no uncertainty ("2026-06-30, delivered") unless it is a high-integrity commitment (see 2.6 below).

### 2.3 Completion gate

A yes-or-no condition. Some good examples:

- "New signups reach first-value in under 10 minutes at p75, measured via Amplitude."
- "SOC 2 Type II report delivered to customers."
- "Checkout conversion rate reaches 35%, measured weekly for 4 weeks."
- "Mobile app has shipped to App Store with 4+ star rating after 2 weeks of GA."

Not completion gates (these are themes or goals without gates):

- "Onboarding is improved."
- "Activation goes up."
- "Checkout works better."
- "Users are happy."

If the team cannot state a completion gate, the milestone is not ready to commit. Demote to Next or Later until the gate is known.

### 2.4 In-scope items

Enumerated. Each references a PRD section and an architecture component. "All items from Q2 plan" is not enumeration; it's a heading. The expected enumeration density is 3-10 items per milestone; fewer is under-scoped, more is likely over-scoped for a single cycle.

### 2.5 Out-of-scope items (this is the hardest section)

Enumerated with reasons. This is the no-gos list, not the backlog. The Out-of-Scope section is expected to be longer than the Won't-have MoSCoW tier, because it catches things nobody thought to rank.

Three sub-parts:

- **Explicit no-gos.** Things the team considered and cut. "Email digest: cut for M3 because notifications via in-app are sufficient for the activation KR; reconsidered at M5 if retention signal calls for it."
- **Deferrals.** In-plan but not-this-milestone. "Multi-tenant admin: deferred to M5; single-tenant admin ships in M3."
- **Non-ownership.** Things this team does not own. "Billing system migration: owned by platform team; this milestone assumes the new billing endpoint is stable."

The milestone is incomplete without all three sub-parts populated. The have-nots list flags missing out-of-scope as a disqualifier.

### 2.6 Rabbit holes

Shape Up term (Singer, chapter 5). A rabbit hole is an anticipated risk that could blow up the scope of the milestone. Each rabbit hole names:

- What could go wrong.
- Why it is tempting to over-build.
- The smallest version that avoids the rabbit hole.

Example: "Real-time collaboration: rabbit hole. Tempting to build full CRDT-based sync; v1 uses optimistic locking with last-writer-wins and a 'refresh to see latest' banner. Full real-time is a v3 rescoping question."

### 2.7 Dependencies

Upstream milestones or external commitments that must complete first. Drawn from the architecture DAG and the external-constraints list.

### 2.8 Cutover cadence

When this milestone ships to production. Three common patterns:

- **Per-milestone cutover.** Each milestone ships to production on its completion date. Feeds deploy-ready with a named cutover calendar.
- **Every N milestones.** E.g., "M1 and M2 batch-cut together on 2026-06-30; M3 is its own cutover."
- **Continuous with flag rollout.** Shipped dark behind flags on completion; flag rollout to 25 / 50 / 100% on a calendar after milestone completion. Feeds deploy-ready with flag-rollout dates.

### 2.9 High-integrity commitment label (Cagan)

Optional but required for any milestone with a fixed-date-and-fixed-scope claim. The label names the reason the commitment is high-integrity:

- "Regulatory: SOC 2 Type II audit window begins 2026-07-15."
- "Partner-committed: integration with X goes live on their 2026-06-20 launch."
- "Contract: customer Y's SLA-defined delivery date is 2026-06-01."

A fixed-date-and-fixed-scope item without a high-integrity commitment label is roadmap theater. Either label it or relabel it with a confidence band.

## 3. Horizon structure (Now-Next-Later)

The canonical three-horizon structure (Bastow, ProdPad, 2012). Other cadences have analogs: Shape Up has "current cycle / next shape / direction"; quarterly has "this quarter / next quarter / rest-of-year"; PI has "current PI / next PI / PI-after-next."

The precision gradient is the rule. Now > Next > Later in precision, not in activity.

### Now

Current cycle. Specific, owned, dated (or appetite-bounded). Every slice has:

- A name.
- An owner (engineer or small team).
- An appetite or size (small batch / big batch, or S / M / L / XL).
- An outcome, commitment label, or open-question label.
- A PRD reference.
- An architecture reference.
- A dependency list (upstream slices that must complete first).
- A status (not started / in progress / blocked / done).
- A last-reviewed date.

A slice in Now without all nine fields is incomplete. The status column is updated as work progresses; the last-reviewed date is updated at every review-cadence beat.

### Next

Directly after the current cycle. Directional. Items are themes or outcomes, not fully decomposed slices. Confidence bands are appropriate here ("70%," "likely," "aspirational"); day-level dates are not.

A Next item has:

- A theme name.
- A target outcome.
- A confidence band (percentage, qualitative tier, or "aspirational").
- A PRD reference (if tied to a PRD section).
- A status (pending / in shaping / pulled to Now).

Next items are shaped into Now items at the cycle boundary. If a Next item is shaped and found to be larger than appetite, it is cut down or deferred to Later.

### Later

Longer-term direction. Thematic. Names outcomes and intent, not features. Items in Later are hypotheses; they do not have target dates.

A Later item has:

- A theme.
- An intent sentence ("we want to increase activation among small-team accounts").
- A status (exploring / probable / deferred).

Later items are revisited at each cycle boundary. If Later is empty, the roadmap has no forward view (perpetual-now failure mode); if Now is empty, the roadmap has no execution.

## 4. Precision gradient enforcement

The skill grep-tests for precision mismatches:

- **Now row with no owner:** demote to Next or assign owner.
- **Now row with no PRD reference:** route to prd-ready (item is speculative).
- **Now row with confidence band lower than 70%:** demote to Next (lower confidence is Next-level).
- **Next row with day-level date:** rewrite as confidence band or range.
- **Later row with date:** remove date; Later is thematic.
- **Later row decomposed into slices:** promote theme to Next and keep the slices in Next.

Equal precision across Now, Next, and Later is the quarter-stuffing failure. See [`roadmap-antipatterns.md`](roadmap-antipatterns.md) section 3.

## 5. Format choices

The canonical output is plain Markdown. The reasons:

- Every planning-tier and downstream-tier sibling skill reads Markdown.
- LLMs (including the skill itself in future sessions) read and write Markdown reliably; vendor formats (Jira XML, Linear JSON) are tool-specific and drift.
- Markdown is grep-testable for the have-nots.
- Markdown renders anywhere, including GitHub, which is the default surface for engineering-visible plans.

Tool-specific exports (Jira, Linear, Productboard, Aha!, Notion) are downstream transformations. The skill does not pick a tool; it emits the canonical Markdown. A team using Linear imports the Markdown into Linear's issue-and-project structure; a team using Notion embeds it as a database; a team using plain files commits it to the repo.

## 6. Public derivative (Step 10)

If the audience is mixed (internal plus external), produce `ROADMAP-PUBLIC.md` as a derivative. Never publish the internal file.

### Redaction rules

Strip from public:

- **Capacity math.** "Planned 14 engineer-weeks of 16 available" becomes nothing in the public view.
- **Team assignments and owners.** Internal "Owner: @alice" becomes "team" or omitted.
- **Confidence bands for internal use.** Internal "70%" becomes external "targeting" or "planned for."
- **Commercially-sensitive context.** Contract clauses, partner names under NDA, competitive positioning.
- **Rabbit-hole specifics.** "Rabbit hole: full CRDT is tempting; v1 uses optimistic locking" is internal discipline. Public sees only the outcome.
- **Won't-have phrasing.** Internal "Won't have: Slack integration" becomes external "Not planned."
- **Deferred items with internal reasons.** Public gets a cleaner deferred list; internal reasons stay internal.

### Additions for public

- **Customer-value framing.** "Why this matters to you" on each item.
- **Cross-links to changelog.** Shipped items link to the public changelog entry.
- **Feedback channel.** "Have a thought on this roadmap? [link]."
- **Update cadence.** "Updated quarterly."

### Anti-pattern

Publishing the internal file. This is a leak failure. Internal owners, capacity math, or rabbit-hole specifics ending up on the public customer-facing page is the cost of sloppy derivation.

### Alternative: no public roadmap

Per Basecamp's "Options, Not Roadmaps" (https://basecamp.com/articles/options-not-roadmaps), a legitimate choice is to publish nothing. The rationale: roadmaps communicate commitments, and not every team wants to make commitments to the public.

For B2B SaaS with enterprise customers expecting "when will SSO ship?", silence is commercially untenable. For a bootstrapped product with no sales cycle, silence is sustainable. The skill supports either; the audience answer in pre-flight decides.

## 7. Archive pattern

Completed milestones are archived, not overwritten. The ROADMAP.md file grows by one section per cycle:

```markdown
## Archive

### M1: Initial traced service (completed 2026-04-15)

Shipped R-01 (echo endpoint), R-02 (OTel instrumentation). R-03 deferred to M2.

Retrospective: [link]
```

Archived milestones retain their target dates, gates, and in-scope lists. Deferred items from the archive are cross-linked to the milestone they moved to.

The archive pattern is load-bearing for Mode C (iteration). Every cycle, the skill reads the archive to compute actuals vs. planned and to recalibrate capacity estimates for the next cycle.
