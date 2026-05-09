# PRD antipatterns: the named failure modes (Mode C audits and tier-gate checks)

This reference is the catalog of PRD failure modes, each with its named term, its detection signature, its canonical examples, and its remediation. Load this for Mode C audits (Step 1.5) and at every tier gate for the have-nots check.

## 1. The three-label audit (the load-bearing test)

The core test, applied sentence by sentence. Every user-facing sentence of the PRD is either:

- **A decision.** "We have chosen X, and here is the rationale."
- **A flagged hypothesis.** "We believe X, and here is how we will test it."
- **A named open question.** "We do not yet know X, and [owner] will answer by [date]."

If a sentence is none of the three, it is PRD theater.

### Procedure

1. Copy each Problem-section sentence into a scratch pad. Same for Target User, Success Criteria, Out-of-Scope, and Risks sections.
2. For each sentence, write which of the three labels it is. If "none," mark for rewrite.
3. For every "decision" label, check: is there a rationale? (If no rationale, it is an implicit hypothesis; relabel.)
4. For every "hypothesis" label, check: is there a validation plan? (If no plan, it is theater dressed as confidence; rewrite with evidence or relabel as open question.)
5. For every "open question" label, check: is there an owner and a due date? (If no, it is a placeholder; rewrite.)

This audit is what a Tier 2+ PRD's sign-off signers run when reviewing. If more than 20% of sentences are "none," the PRD is not ready for sign-off.

## 2. The named antipatterns

Six primary antipatterns with named terms. Three secondary.

### Antipattern 1: Hollow PRD

**Symptom:** Every section is filled, but the sentences are decisions-that-aren't. The PRD passes visual review and decides nothing.

**Detection signature:**
- "TBD," "TODO," "coming soon," "we'll figure this out later" without an owner.
- Sentences that pass the three-label test's structural form but have no substance ("We have chosen to build a scalable solution" -- the rationale is missing).
- Sections that summarize their own intent without delivering content ("This section describes the user's needs").

**Canonical example:**

> "Problem: users need a better way to manage their status updates. Solution: we will build a tool that helps them."

**Remediation:** Rewrite every hollow sentence with the three-label structure. If the rewrite cannot be done (no decision has actually been made), mark the sentence as an open question and assign an owner.

**Term origin:** suite-consistent with production-ready's "hollow dashboard" / "hollow button" vocabulary. Reuses the shape of production-ready's hollow-check. A PRD can be hollow in the same way a button can be hollow: structure without function.

### Antipattern 2: Invisible PRD

**Symptom:** The PRD reads the same across any product in the category. Substitution test fails.

**Detection signature:**
- Target-user description uses category labels ("small business owners," "modern teams," "busy professionals").
- Problem statement uses category framings ("users need faster workflows").
- Success metrics use category norms ("increased engagement and retention").
- The PRD could plausibly describe a competitor's product without changing more than the product's name.

**Canonical example:**

> "For small business owners who value efficiency, our productivity tool streamlines the workflow, leading to increased engagement and retention."

Substitute any SaaS product for "our productivity tool." The sentence still reads. Fails.

**Remediation:** Apply the substitution test to each user-facing sentence. Rewrite with specificity: named roles, named contexts, named constraints, named competitors or workarounds.

**Term origin:** Tom Leung ([Fireside PM](https://firesidepm.substack.com/p/i-tested-5-ai-tools-to-write-a-prdheres)), who tested five AI PRD tools and concluded the output was "invisible." Attributable; adopted as a primary term.

### Antipattern 3: Feature laundry list

**Symptom:** A flat list of features (or requirements) with no prioritization. Every item is Must-ranked, or nothing is ranked. No cut line.

**Detection signature:**
- 12+ requirements, all Must.
- 12+ requirements, none with MoSCoW.
- Requirements that span "I think someday we should..." to "v1 must have..." without stratification.
- No Won't (this release) tier populated.
- Out-of-Scope section short because nothing was cut to make room.

**Canonical example:**

> "Functional requirements: (1) CSV import, (2) user authentication, (3) export to PDF, (4) team collaboration, (5) real-time sync, (6) AI-powered insights, (7) custom branding, (8) audit logs, (9) API access, (10) mobile app, (11) single sign-on, (12) payment processing. All are Must."

**Remediation:** Force the MoSCoW distribution. At most 50% Must. Name a cut line below which Could/Won't items live. Cross-link to Out-of-Scope.

**Term origin:** ProductPlan glossary ("feature laundry list refers to adding too many features, which obscures a product's main value"). In the wild; adopted verbatim.

### Antipattern 4: Solution-first PRD

**Symptom:** The Problem section names the product's solution. The product is assumed; the problem is backfilled.

**Detection signature:**
- Problem section starts with "Our product..." or "The system..." or "The tool...".
- Problem section says "users need a solution that..." (the solution is pre-decided).
- Problem section describes the product's features instead of the user's friction.
- Target user is defined by the product ("users of our product") rather than by their role and context.

**Canonical example:**

> "Problem: our users don't have a central dashboard where they can view all their project status in one place, so they need a central dashboard where they can view all their project status in one place."

Tautology. The solution is assumed in the problem framing.

**Remediation:** Rewrite the Problem section in the form "users today do X manually, which takes Y time and costs Z." Do not name the solution until after the problem is framed; the solution emerges from the Requirements section (Step 5), not the Problem section.

**Term origin:** Intercom's "Start with the problem" (2017). Formalized as the anti-solution-first discipline.

### Antipattern 5: Assumption-soup PRD

**Symptom:** User-behavior claims stated as facts without evidence, validation plan, or explicit hypothesis framing.

**Detection signature:**
- "Users will love...," "customers want...," "the market demands...," "our users expect..."
- "Best practices suggest..."
- "Industry standards indicate..."
- Invented user quotes.
- Personas with invented demographics.

**Canonical example:**

> "Users will love the new dashboard because it's intuitive and saves time. Customers want to be able to see everything in one place."

No evidence. No validation plan. Decisions disguised as facts.

**Remediation:** For each claim, label as hypothesis and add evidence (or flag the evidence gap). Rewrite user-behavior claims in the form "we believe [X]; evidence: [research]; validation: [plan]." If no evidence exists and the claim is load-bearing, block the tier until research is gathered.

**Term origin:** Coined for prd-ready. The research pass found no pre-existing term; lane is open. Attested usage: PRDs at Series A startups.

### Antipattern 6: Moving-target PRD

**Symptom:** The PRD is edited frequently without changelog entries or broadcasts. Engineers stop trusting the document; they rely on Slack and meeting notes instead.

**Detection signature:**
- No changelog section, or an empty/stale changelog.
- Changelog exists but has no entries for the last 2+ weeks despite known edits.
- No broadcast record (Slack/Linear/Discord posts) for recent edits.
- Engineers report "I don't know if this section is current."
- Different team members reference different versions of the same section.

**Canonical example:**

The PRD says "the system will support up to 10,000 concurrent users" but the latest eng huddle decided to commit to 50,000. The PRD is not updated; the huddle notes are in a different Notion page; half the team has one number, half the other.

**Remediation:** Run the change-control protocol (Step 11). Every edit to a Living or Soft-frozen PRD gets a changelog entry. Every changelog entry is broadcast. Silent edits are rejected by process.

**Term origin:** Ben Horowitz's 1998 memo: "Bad product managers update the PRD and don't tell anyone." The failure has been named since 1998; formalized here.

### Secondary antipattern 1: Theater PRD

**Symptom:** The PRD exists for ritual, not decision. It is produced because "we need a PRD" and consumed by no one. Often lives in a folder no one opens after the approval meeting.

**Detection signature:**
- No one has viewed the PRD in the last 30 days (Google Doc view count, Confluence analytics).
- Engineering is building from Slack and standups, not from the PRD.
- The PRD's requirements are stale; the product shipping does not match.

**Remediation:** Either kill the PRD (it is not serving its function) or fix it (drive the team's decisions through the PRD, broadcast changes, update the requirements). Choose deliberately; a zombie PRD is worse than no PRD.

**Term origin:** "Theater" is widely used in "security theater" and "agile theater"; applied here. Open lane; use sparingly as a rhetorical flourish.

### Secondary antipattern 2: Quill-and-inkwell PRD

**Symptom:** A 40-page PRD that covers every conceivable edge case and decides nothing. The document is impressive as a writing sample; useless as a decision artifact.

**Detection signature:**
- Page count over 10 for non-regulated domains.
- Every section has sub-sections; sub-sections have sub-sub-sections.
- The document contains a table of contents.
- Sign-off takes weeks because no one has time to read it.

**Remediation:** Cut. The Tier 3 length guide is 3-8 pages. Anything longer is template-bloat; split into separate documents or trim.

**Term origin:** Coined for prd-ready. No attested usage; reserve as a rhetorical flourish.

### Secondary antipattern 3: Superficial-completion PRD

**Symptom:** All sections are present but with vacuous content. "Ensuring alignment with legal standards" as a compliance section. Tautologies throughout.

**Detection signature:**
- Sentences that restate the section header as body content.
- Circular definitions.
- Non-sequitur bullet points that do not connect to the surrounding context.

**Canonical example:**

> "Compliance: this product will comply with applicable regulations. Privacy: user privacy will be protected. Security: the system will be secure."

**Remediation:** Replace each hollow sentence with a specific claim. "Compliance: SOC 2 Type II controls apply to production; evidence in Vanta; no HIPAA/PCI at v1." Every sentence is a decision with rationale.

**Term origin:** Aakash Gupta, *Modern PRD Guide* ([aakashg.com](https://www.news.aakashg.com/p/product-requirements-documents-prds)): "superficial completion: all sections present but with vacuous content."

## 3. The Mode C audit procedure (Step 1.5)

When a prior AI-slop PRD exists and the ask is "fix this," run this procedure:

### Procedure

1. **Read the PRD top to bottom once.** Do not rewrite; read to identify the dominant failure mode.
2. **Classify the dominant failure.** Pick one of the six primary antipatterns above. Most AI-slop PRDs exhibit 2-4 failure modes simultaneously, but one usually dominates.
3. **Quote at least one failing sentence per section.** Copy the exact text. Name which antipattern it exhibits.
4. **List the remediation per section.** What needs to change.
5. **Decide rewrite scope.** Fresh Tier 1 Brief (recommended if >40% of sentences fail) or section-level rewrites (if <40% fail).
6. **Write the audit output as a document.** The audit lives at `.prd-ready/AUDIT.md` and is the input to the subsequent workflow.

### Example audit output

```markdown
# AUDIT of existing PRD (2026-04-23)

Source: PRD.md v1.2 (edited 2026-04-19 by ChatGPT; no human edits since).

## Dominant failure mode
**Invisible PRD** (primary). **Assumption-soup PRD** (secondary). **Hollow PRD** (tertiary, in NFR section).

## Failing quotes

### Problem section
> "Users want a faster way to manage their workflows."
-- **Invisible.** Substitution test: "Notion users want a faster way to manage their workflows." Plausible. Sentence decides nothing specific.

> "Our product will revolutionize how teams collaborate."
-- **Solution-first.** The Problem section names the product's solution.

### Target user section
> "Sarah, a 35-year-old marketing manager, values efficiency and growth."
-- **Invisible + fabricated persona.** No role specificity. Invented demographics.

### Success criteria section
> "Increased engagement and retention."
-- **Invisible + assumption-soup.** No number, no deadline, no source, no outcome frame.

### NFR section
> "The system will be secure and fast."
-- **Hollow.** No thresholds, no dimensions. Superficial completion.

## Recommendation
Fresh Tier 1 Brief. Do not rewrite atop the existing document; the antipattern signal is too deep.

## Remediation plan
- Step 0: declare Mode A (pivot from C to fresh draft).
- Step 1: seven pre-flight questions with actual user research (3 PM interviews in the last month are in /research/; use them).
- Step 2: Problem section with friction + who + workaround, passing the substitution test.
- Step 3: target user with role + context + constraint + workaround + cited quote.
- Step 4: success criteria with 1 leading + 1 lagging metric, each with number + deadline + outcome frame + source.
- ...
```

### The "salvage" question

Sometimes an AI-slop PRD has 1-2 sections that are genuinely good (the PM wrote them; the AI didn't). Keep those; rewrite the rest. Mark the salvaged sections in the audit so they are not re-edited unnecessarily.

## 4. Tier-gate audit (run at every tier closure)

Before declaring any tier complete, run a lightweight version of the Mode C audit against the current PRD:

### Checklist

- [ ] Three-label test: <10% of sentences are "none."
- [ ] Substitution test: Problem + Target User sentences pass against 2 competitors.
- [ ] MoSCoW distribution: at most 50% Must; no un-ranked requirements.
- [ ] Out-of-Scope length: meets tier minimum (3+ for Tier 1, 5+ for Tier 2, 10+ for Tier 3).
- [ ] NFR coverage: every dimension listed in [requirements.md](requirements.md) section 7 has a threshold or a flagged open question.
- [ ] Open questions log: every OQ has an owner and a due date.
- [ ] Risks: every risk has failure mode + owner + mitigation + trigger.
- [ ] Assumptions: every assumption has claim + evidence + validation plan.
- [ ] Handoff block: populated to the tier's required depth.
- [ ] Changelog: every edit since last tier signed, dated, attributed.
- [ ] Sign-off ledger: every required signer for this tier has attested.
- [ ] Banned phrases: "industry-leading," "enterprise-grade," "seamlessly," "AI-powered" (for non-AI), "best-in-class," etc., absent from user-facing sections.

Any unchecked box blocks the tier.

## 5. Banned-phrase audit

Grep-testable. A PRD written for internal use should not reach for launch-ready's external-copy adjectives. If it does, the adjective is usually masking a missing specific claim.

| Banned phrase | Why it fails | Replace with |
|---|---|---|
| industry-leading | Self-awarding superlative | The number or rank that proves it ("ranked #1 by G2 for [category]" or drop) |
| enterprise-grade (without definition) | Means "we hope it's good" | The specific control (SOC 2, HIPAA BAA, SSO support) |
| seamlessly | Describes aspiration, not mechanism | The specific transition ("without switching tabs," "in one click") |
| AI-powered (for non-AI products) | 2024-era tell | Drop unless AI is the actual differentiator |
| best-in-class | Unwinnable claim without proof | Drop or cite the ranking |
| world-class | Brand-speak | The specific capability |
| cutting-edge | Dated by the time it ships | The version or year |
| game-changing | Self-congratulatory | The metric that changed |
| revolutionary | Self-awarding superlative | The specific new thing |
| effortless | Effort is measurable | The number ("two fewer clicks than the incumbent") |
| powerful | Says nothing measurable | The specific capability and its scale |

These phrases are fine in some contexts (press releases, sales decks); prd-ready refuses them in the PRD's user-facing sections because they signal that the writer reached for an adjective instead of naming a specific claim.

## 6. The "can an engineer start building" test

The highest-leverage audit. Hand the PRD to an engineer on the team (or a reasonable proxy: read it yourself while pretending to be the engineer). Can they, after 20 minutes:

- Name what is being built?
- Name who it is for?
- Name what counts as done?
- Name what is NOT in scope?
- Start writing tickets without scheduling a clarification meeting?

If no, the PRD has failed its contract regardless of how many sections are filled. The first question they need to ask is the next thing to write down.

## 7. How these antipatterns cluster

Common PRD failure is rarely one antipattern; it is a cluster:

- **Invisible + assumption-soup + fabricated persona.** The AI-slop default. Tom Leung's test of ChatGPT output. Remediation: fresh draft after real user research.
- **Feature laundry list + missing non-goals.** The stakeholder-capture failure. Every stakeholder got their wish; no one decided the cut line. Remediation: force MoSCoW, expand Out-of-Scope.
- **Solution-first + hollow NFRs.** The implementation-eager PM. Solution is pre-picked; the user problem and system qualities are backfilled. Remediation: rewrite Problem section problem-first; fill NFRs with thresholds or flagged open questions.
- **Moving-target + theater.** The "PRD exists for ritual" failure. Nobody reads it; nobody updates it; the product shipping is disconnected. Remediation: rebuild trust by shipping one cycle with strict changelog + broadcast discipline, or kill the PRD.

When classifying the dominant failure, look for the cluster; the fix addresses the cluster, not the individual symptom.

## 8. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 1 (ten failure modes) and section 2 (named-term survey).
- Aakash Gupta, *Modern PRD Guide* (2024, news.aakashg.com).
- Tom Leung, *I tested 5 AI tools to write a PRD* (Fireside PM, 2024).
- Chris Warren, *Product Requirements Documents: A Perspective from an Engineering Leader* (Medium, 2023).
- Plane Blog, *How to write a PRD that engineers actually read* (2024).
- Figr Design, *How to write a PRD* (2024).
