# ADR discipline

Architectural Decision Records are short, dated, and retired honestly when superseded. They are the mechanism by which a future maintainer can reconstruct why the architecture is shaped the way it is, without reverse-engineering the rationale from the code. Without ADRs, architectural decisions evaporate within 12 months of being made; the next team rediscovers the rationale badly, usually after a production incident that the original decision was meant to prevent.

This reference specifies the ADR format this skill requires, the lifecycle it enforces, and the antipatterns it refuses. The baseline format is Michael Nygard's (2011); the skill extends it with five additional fields that catch failure modes common in AI-generated ADRs.

## Section 1. Origin

Michael Nygard, "Documenting Architecture Decisions," published on cognitect.com on November 15, 2011 (https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions), is the canonical reference for lightweight architecture documentation. Nygard's observation was that large-format architecture documents ("Software Architecture Documents," SAD) were written at project start, never read, and never updated. The ADR format is the opposite: each record is one decision, one to two pages, written at decision time, and kept alongside the code.

The Nygard canonical format has five sections: Title, Status, Context, Decision, Consequences. Every subsequent ADR tool (adr-tools, log4brains, MADR) descends from this format. The format is intentionally minimal; the discipline is in keeping the records honest, dated, and retired.

Why ADRs matter: architectural decisions accumulate silently. Without a record, six months later, someone asks "why did we pick Postgres over Mongo," and the answers come from memory, from git blame, from someone's Slack thread, or from a rationalization generated on the spot. The rationalization looks plausible and may not match the original reason. The next decision, built on the rationalization, compounds the error. ADRs freeze the rationale at the moment of decision, so the audit trail survives team turnover.

What ADRs are not: they are not design documents. A design document describes how something is built; an ADR records why one option was chosen over alternatives. A PR description describes what changed; an ADR records what decision is now in force across all future changes.

## Section 2. The Nygard format (this skill's required template)

The skill requires every ADR to carry the following ten fields. The first five are Nygard's canonical format. The last five are extensions this skill adds to catch failure modes common in AI-generated ADRs (missing rationale, invented alternatives, no flip-point analysis, no blast-radius analysis, no date).

```markdown
# ADR-NNNN: [Decision title, short, imperative verb]

## Status
[Proposed | Accepted | Superseded by ADR-MMMM | Rejected | Deprecated]

## Date
YYYY-MM-DD

## Context
[The forces at play. The PRD constraints that are in scope. The state of the
system at decision time. Two to four paragraphs maximum. Facts only; opinions
and alternatives go below.]

## Decision
[What we chose. One paragraph. Imperative voice: "We will use a modular
monolith with three bounded contexts." Not "we might use" or "we are
considering."]

## Rationale
[Why we chose it over the alternatives. Cite the PRD number, the NFR, the
team-size constraint, or the architectural constraint that drove the choice.
Specific enough that it would not apply to a near-equivalent alternative.]

## Alternatives rejected
- [Alternative X]: rejected because [reason tied to the Context].
- [Alternative Y]: rejected because [reason tied to the Context].
- [Alternative Z]: rejected because [reason tied to the Context].

## Consequences
[What becomes easier. What becomes harder. What is now constrained. Both
directions matter: a decision with only benefits is a non-decision.]

## Flip point
[The concrete signal that would force us to reverse this decision. A scale
number, a team-size threshold, a cost curve, a compliance event, a performance
regression. If the flip-point answer is "nothing in particular," the decision
is not load-bearing and should not be an ADR.]

## Blast radius if wrong
[If we are wrong about this, what has to change. Weeks of rewrite? Months of
migration? Which components, which data, which teams? Honest estimate.]
```

### 2.1 What each extension field catches

- **Date.** Nygard's original template does not require a date in a named field (though it is conventional). The skill requires it because ADRs stored in git have commit dates, but commit dates drift when files are reorganized; the in-file date is authoritative.
- **Rationale (separate from Context).** AI-generated ADRs routinely conflate context and rationale: the Context section says "the team is large" and the Rationale says "because the team is large." Separating forces the author to state the reasoning, not just restate the situation.
- **Alternatives rejected.** The single most common failure in AI-generated ADRs is to name the decision without naming what was rejected. "We chose microservices" is an assertion; "we chose microservices over a modular monolith because the team is already 60 engineers across 8 bounded contexts with genuinely independent deploy cadences, and the modular-monolith's coordination tax at that size exceeds the microservices operational tax" is an ADR.
- **Flip point.** The single most common failure in human-written ADRs is the decision-with-no-exit-condition. If nothing would flip the choice, the decision is either not real or not load-bearing. Naming the flip point forces honesty about what the decision depends on.
- **Blast radius if wrong.** Forces an honest estimate of the cost of being wrong. An ADR whose blast radius is "we'd rewrite a page of code" is different from one whose blast radius is "we'd migrate 10 terabytes of production data across a 6-month coexistence window." The blast radius calibrates how much effort to spend on the decision up front.

## Section 3. Status lifecycle

ADR status is a state machine:

```
                 Proposed
                /         \
          Accepted      Rejected
           /     \           (terminal)
  Deprecated   Superseded by ADR-MMMM
                      (not deleted)
```

- **Proposed.** Under discussion; not yet in force. Can be edited freely. Use sparingly; most ADRs in this skill are Accepted at creation because they are written at decision time, not before.
- **Accepted.** In force. The decision is current. Edits to Accepted ADRs are allowed only for clarity, not to change the decision (changing the decision means Superseded).
- **Superseded by ADR-MMMM.** A new ADR has replaced this one. The old ADR stays in the repository; status changes; new ADR cites the old. The history is the point.
- **Rejected.** The proposal was considered and rejected. The ADR stays, with the rejection rationale, so the next person who considers the same idea finds the answer.
- **Deprecated.** The decision is no longer in force because the context that required it no longer exists (a component was removed, a feature was retired). Different from Superseded: nothing replaced this decision; the need is simply gone.

### 3.1 Supersession chains

A supersession chain records evolution. Example:

- ADR-0001 (2024-03-15, Accepted): Use a single monolith with Postgres.
- ADR-0001 (2025-08-10, Superseded by ADR-0017).
- ADR-0017 (2025-08-10, Accepted): Split into three services because team has grown to 25 engineers across three product lines with independent deploy cadences; cites ADR-0001 in Context.

Readers six months later can trace: the system started as a monolith for reasons X, grew to three services for reasons Y when conditions Z held. Deleting ADR-0001 when it was superseded would erase the reasoning; the reasoning is often the thing the next maintainer needs.

### 3.2 Rejected ADRs stay

A Rejected ADR is a memo to the future. "We considered event sourcing in 2024 for the order ledger; we rejected it because the compliance retention requirement turned out to be 90 days rather than 7 years, so a standard audit table sufficed. If the compliance requirement extends beyond 3 years, reopen this decision." The next engineer who hears "event sourcing for audit" as a suggestion finds the rejection and does not re-propose it from scratch.

## Section 4. When to write an ADR

Write an ADR when the decision:

1. **Is non-obvious.** A reasonable senior engineer could have chosen otherwise. If the decision is obvious ("use HTTPS," "back up the database"), an ADR is noise.
2. **Has consequences that outlive the current sprint.** If the decision will constrain code written 6 or 12 months from now, record it.
3. **Reverses a prior decision.** Even if the prior decision had no ADR, the reversal gets one (plus a retroactive ADR for the prior decision if it was load-bearing).
4. **Will surprise a future maintainer.** If a new engineer reading the code would ask "why is it this way," and the answer is non-trivial, write the ADR.
5. **Spans a trade-off.** Two or more real alternatives existed; one was chosen. The trade-off is the thing to record.

### 4.1 The three-line test

If the decision's rationale fits in three lines, do not write an ADR:

> "We chose the already-chosen ORM because the team knows it and the entity count is small enough that bespoke data-access would not pay off."

That is an inline comment in the codebase, not an ADR. If the rationale is longer, the decision has depth, and the ADR adds value.

### 4.2 What counts as load-bearing

The foundational ADRs required by this skill:

- **ADR-0001 System shape.** Monolith, modular monolith, services, serverless, event-driven, edge-native. Non-obvious by definition; failure mode is severe if wrong.
- **ADR-0002 Storage shape per entity group.** Relational, document, key-value, time-series, event log, search, graph, object. Precedes the database pick (which is stack-ready's job).
- **ADR-0003 Trust-boundary model.** Which boundaries exist, where enforced, tenant-isolation model.
- **ADR-NNNN per load-bearing integration.** Sync vs. async, transport, idempotency; written for any integration whose failure is an architectural concern.
- **ADR-NNNN per non-obvious pattern adoption.** Event sourcing, CQRS, saga, outbox, API gateway, service mesh. If adopted, justify.

## Section 5. When NOT to write an ADR

ADRs that dilute the corpus and should be refused:

1. **Trivial decisions.** "ADR-0042: Use tab-indented YAML." Coding style is not architecture. This dilutes the corpus; readers skim past the ADRs that matter.
2. **Retroactive rationalizations.** Writing an ADR months after the decision to make it look deliberate. Separate case (Section 10) covers legitimate retroactive ADRs; rationalizations are different and worse. The rationale section is reverse-engineered; the alternatives are the ones the author remembers, not the ones that were on the table.
3. **Decisions that will be reversed within the sprint.** If the team knows the decision is temporary (a placeholder, a stopgap), a comment in code or a ticket suffices. ADRs are for decisions meant to last.
4. **Design documents masquerading as ADRs.** A four-page ADR with a section on "Implementation plan" is a design document. Split: the ADR records the decision; the design document records how to execute it.
5. **Political cover.** ADRs written to justify a decision that has already been sold to leadership. The format is not a vehicle for retroactive CYA; it exists to record architectural reasoning for future maintainers.

## Section 6. Length discipline

Two pages maximum. Approximately 800 to 1200 words. If the rationale needs more, one of the following is true:

- The decision is actually multiple decisions (Section 7); split.
- Background material belongs in a separate reference document cited from the Context section.
- The ADR has become a design document; move the implementation detail elsewhere.

Long ADRs are design documents pretending to be decisions. The reader who opens an ADR expects to find a decision; the reader who opens a design document expects to find an implementation plan. Conflating the two produces documents that serve neither purpose.

The discipline: if you find yourself writing a third page, stop and ask whether the ADR has crossed the line into design. If yes, factor out. If no, trim: the ten fields above are load-bearing; everything else is discretionary.

## Section 7. One decision per ADR

Compound ADRs are unreadable. If the ADR covers three choices (a system shape, a database pick, a deployment topology), it is three ADRs. Readers cannot cite "we decided per ADR-0007" if ADR-0007 decided five things at once; the supersession chain becomes a tangle; the flip point for choice A may differ from choice B, and a single ADR cannot honor both.

The test: can every field (Context, Decision, Rationale, Alternatives rejected, Consequences, Flip point, Blast radius) be written once, coherently, about a single thing? If yes, one ADR. If you find yourself writing "the system shape decision has flip point X, and the database decision has flip point Y," those are two ADRs.

Composite decisions are common; ADR families handle them. ADR-0001 "System shape" can reference ADR-0002 "Storage shape" which references ADR-0003 "Trust boundary model." Each ADR is self-contained; the family together describes a coherent architecture.

## Section 8. Storage

`.architecture-ready/adr/NNNN-slug.md` in the project repository. Not in a wiki. Not in Confluence. Not in a shared Google Doc. With the code, versioned with the code, reviewed in pull requests when changed.

### 8.1 Naming convention

- `NNNN` is a zero-padded sequence (0001, 0002, ..., 0042). Zero-padding is conventional; four digits is enough for any real-world ADR corpus.
- `slug` is kebab-case, descriptive, under 60 characters. "system-shape" is fine. "modular-monolith-with-three-bounded-contexts" is fine. "architectural-decisions-regarding-the-new-system" is not.
- The filename should make the decision guessable from the file listing. `ls .architecture-ready/adr/` should read like a table of contents.

### 8.2 Why in-repo and not a wiki

Wiki-resident ADRs go stale within 6 months. The reasons are structural:

1. Wikis are not reviewed in PR. ADR changes pass without engineering review.
2. Wiki edit history is weaker than git. "Who changed this and why" becomes guesswork.
3. Wikis are not searchable from the code. A developer grepping for "why is it this way" finds code but not rationale.
4. Wiki ACLs drift; ADRs end up inaccessible to new team members.
5. The wiki lives on a different service; it goes down or migrates; ADRs are lost.

In-repo ADRs are reviewed, versioned, co-located with the code they constrain, and move with the project across migrations.

### 8.3 PR review for ADR changes

An ADR change (new ADR, supersession, status change) is reviewed in a PR like any other code change. Required reviewers: at least one person with architectural context (tech lead, staff engineer, architect). The PR description includes:

- What is the decision being recorded?
- What changed in the codebase that motivated this ADR (if anything)?
- Does this ADR supersede another? Cite it.

ADRs reviewed in PR get caught when they miss fields, when the rationale is hollow, when the flip point is "nothing," or when the alternatives were not really on the table. The review is the quality gate.

## Section 9. Tooling

Several tools automate parts of the ADR workflow. None of them check the discipline (the discipline is human review); they reduce friction on the mechanical parts.

### 9.1 adr-tools (Nat Pryce, npryce fork)

https://github.com/npryce/adr-tools

Bash CLI. Commands:

- `adr init` creates the `doc/adr/` directory and an initial ADR-0001.
- `adr new "Title"` creates the next ADR with the Nygard template.
- `adr link N supersedes M` marks ADR-M superseded by ADR-N and updates both files.
- `adr list` and `adr generate toc` produce an index.

Minimal, venerable, maintained enough. The template is Nygard-canonical; the skill's additional five fields (Date, Rationale, Alternatives rejected, Flip point, Blast radius) must be added to the template after init. Configure `adr-template.md` in the repo to match this skill's required fields.

### 9.2 Henderson fork (Joel Parker Henderson)

https://github.com/joelparkerhenderson/architecture-decision-record

Curated template catalog. Useful for onboarding teams to ADRs. Multiple template variants (Nygard, MADR, custom); pick one per project and stick with it.

### 9.3 log4brains (Thomas Vaillant)

https://github.com/thomvaill/log4brains

Generates a static site from a Markdown ADR repository. Features a live preview, a searchable knowledge base, and a "what's new" feed. The project dogfoods itself: the log4brains ADRs live at https://thomvaill.github.io/log4brains/adr/, readable as a reference for how to write these well.

log4brains' template machinery is easier to customize than adr-tools'; this skill's five additional fields slot in as required sections in the log4brains template. Recommended when the project wants a browsable ADR site (useful for large teams, open-source projects, and regulated domains where auditors want a readable audit trail).

### 9.4 MADR (Markdown Architectural Decision Records)

https://adr.github.io/madr/

A richer Markdown template maintained by the adr.github.io community. MADR adds fields like "Deciders," "Consulted," and "Informed" (a RACI overlay), and structures "Considered Options" prominently. MADR is compatible with log4brains and adr-tools.

Use MADR when the team wants a more structured decision record than Nygard's minimum, especially in larger organizations where decision authorship and stakeholder consultation matter. For small teams, MADR is overhead; stick with Nygard plus this skill's five extensions.

### 9.5 When to use what

- **Small team, early-stage project.** adr-tools plus the Nygard template with this skill's five extensions. Minimum friction.
- **Medium team, established project.** log4brains for the browsable site and richer tooling.
- **Large organization, multiple projects, regulated domain.** MADR for the structured decision record plus log4brains for the site. Accept the overhead for the audit trail.
- **Any team.** In-repo, version-controlled, PR-reviewed, with the skill's required fields. The tool is secondary; the discipline is primary.

## Section 10. The retroactive-ADR problem

ADRs written months after the decision rationalize; real ADRs record. Rationalization looks like recording and produces a plausible-sounding document that misleads future maintainers. The rationale section is reverse-engineered: the author lists the alternatives they now remember, not the alternatives that were actually on the table; the context reflects current conditions, not the conditions at decision time; the flip point is back-filled from current expectations.

This is not a minor defect. Retroactive ADRs undermine the corpus: future readers trust them, apply them as historical record, and compound the error.

### 10.1 When retroactive ADRs are acceptable

Archaeological purposes only. A team inherits a codebase with no ADR corpus and needs to document the existing architecture for onboarding, compliance, or pre-rearchitecture analysis. Label the ADR explicitly:

```markdown
# ADR-0001: System shape (retroactive)

## Status
Accepted (retroactive)

## Date
Written 2026-04-23 to document a decision made approximately 2022-09
(inferred from initial commit of core modules; original decision authors
no longer on team).

## Context
...
```

The label `(retroactive)` in the title and the dual date (written vs. decision-made) are mandatory. Readers know to treat the rationale as reconstructed, not recorded.

### 10.2 When retroactive ADRs are unacceptable

- Writing an ADR for a recent decision (weeks old) and dating it as if it were made at decision time. This is falsification, not rationalization.
- Writing an ADR after a production incident to make the decision that caused the incident look deliberate. The correct response is a post-incident ADR that supersedes the implicit prior decision.
- Writing an ADR to satisfy a compliance auditor after the fact, without the retroactive label. Auditors do not know the difference; future maintainers do, and the corpus's trustworthiness erodes.

The skill's guidance: write ADRs at decision time. When retroactive is necessary, label. Never pretend.

## Section 11. ADR antipatterns

The following patterns appear repeatedly in AI-generated ADRs and in hurried human-written ones. Each is a defect; the review must catch them.

### 11.1 "We chose X because it is industry-standard"

No trade-off. "Industry-standard" is a phrase that applies to almost anything, and the rationale does not survive substitution: replace X with any plausible alternative, and the sentence still reads. Rewrite with the specific constraint: "We chose X because Y, where Y is a concrete constraint from the PRD or from the team."

### 11.2 "We chose X because it scales"

No number. "Scales" is a verb with no object. Scales to what? 1000 requests per second? 1 million? Scales in which dimension (throughput, storage, latency, user count, tenant count)? Rewrite with the specific scale target from the PRD and the specific mechanism by which X addresses it.

### 11.3 "We chose X and will revisit later"

Non-decision. If the revisit is the actual plan, the ADR should say so: "We will use X for the first 6 months; at 6 months we will re-evaluate against criteria Y, Z." The flip point is then concrete. "Revisit later" without criteria is a way to avoid deciding.

### 11.4 "We chose X or Y or Z depending on the case"

No decision. An ADR that says "it depends" has not decided; it has described a decision matrix. Either the ADR is actually N separate ADRs (one per case), or it is a policy document (not an ADR). Rewrite as a single decision with scope ("for the order service, we chose X; see ADR-0012 for the catalog service"), or factor into multiple ADRs.

### 11.5 "We chose X based on best practices"

Appeal to authority. "Best practices" applies to anything and decides nothing. If there is a specific authority (a paper, a book, a team's published standard), cite it with the page or section. If the authority is "general industry knowledge," rewrite with the concrete constraint that informed the choice.

### 11.6 Hollow alternatives

"Alternatives considered: Y, Z" where Y and Z are either straw-men (obviously inferior to X) or invented (nobody actually considered them). This is the AI-generated ADR failure par excellence: the template requires alternatives, so the AI invents plausible-sounding options that were never on the table.

Fix: in the Alternatives rejected section, each alternative should have been a serious candidate. "Y was seriously considered by engineer A and engineer B for reasons Y1, Y2; it was rejected because Y3 (a concrete failure against the PRD)." If an alternative was not seriously considered, do not list it.

### 11.7 The "all consequences are positive" ADR

An ADR whose Consequences section says "Faster, cheaper, more reliable, easier to maintain" is a non-ADR. Every real decision has trade-offs. If the consequences are all positive, the author did not think through the downside, or the ADR is marketing rather than architecture. Rewrite with the specific things that become harder: operational complexity, team expertise required, cost, compliance burden, integration friction.

### 11.8 The "flip point: if the team changes mind" ADR

Flip points must be concrete. "If the team reconsiders" is not a flip point; it is a recursion. Real flip points: "if tenant count exceeds 5000," "if p99 latency regresses past 500ms for 30 consecutive days," "if a second regulated-data-type is added to scope," "if the compliance regime adds PCI to the existing HIPAA requirement." A flip point that is concrete enough to set up a fitness function or an alert is a real flip point.

### 11.9 Missing the blast-radius field

"Blast radius if wrong: TBD" or absent. The field exists because, at decision time, the author knows roughly how much it would cost to reverse; that estimate is the best available calibration for how much effort to spend on the decision now. Missing the field is missing the calibration.

### 11.10 Title that describes the technology, not the decision

"ADR-0007: PostgreSQL" is a title that names a tool; it is not a decision. "ADR-0007: Use PostgreSQL as the primary transactional store for order, inventory, and identity" is a decision title. The imperative verb ("Use," "Adopt," "Reject," "Split," "Consolidate") plus the specific scope make the title load-bearing; a bare noun does not.

Each of these antipatterns has a rewrite. The review's job is to catch them before the ADR is accepted; the skill's job is to refuse acceptance until the ADR passes. An ADR corpus full of antipattern ADRs is worse than no corpus: future maintainers trust it, act on the false rationale, and compound the error.
