# roadmap-antipatterns.md

Named-failure-mode catalog for roadmap-ready. Each antipattern has a name, source (coiner or emergence), shape (how to recognize it), concrete example, and fix. The catalog is grep-testable: every item has a marker the skill checks for at tier gates.

Full citations live in [`RESEARCH-2026-04.md`](RESEARCH-2026-04.md); this file is the operational reference.

## 1. The three-label test procedure

Before cataloguing antipatterns, the procedure the skill runs against every roadmap item at every tier gate.

For each item, ask:

1. **Is this a grounded commitment?** A date, a scope, a named reason, and a sign-off.
2. **Is this an outcome-framed direction?** A target outcome and an appetite or a confidence band.
3. **Is this a named open question?** An unknown with an owner and a review date.

If the item is none of the three, it is theater. Rewrite or cut.

Procedure:

1. Quote every item verbatim from the Now, Next, and Later columns plus milestones.
2. For each, apply the three-label test.
3. List items that fail, with their failure label.
4. Rewrite failing items into one of the three forms, or cut.

The three-label test is the root discipline. Every antipattern below is a specific violation of it.

## 2. Feature factory

**Source:** John Cutler, "12 Signs You're Working in a Feature Factory," August 2016. https://cutle.fish/blog/12-signs-youre-working-in-a-feature-factory/

**Shape.** Roadmap rows are feature names only. No outcome column, no measurement plan, no hypothesis. Success = ship. The twelve Cutler signs: no measurement of feature impact; rapid shuffling of teams; infrequent acknowledged failures; no PM retrospectives; obsessing about prioritization with no matching validation; roadmaps showing a list of features rather than areas of focus or outcomes; immediate movement to the next project after "done"; etc.

**Example.**

```
Q1: SSO, Dark mode, AI integration, mobile app
Q2: Workspace management, billing v2, analytics dashboard, audit logs
Q3: ...
```

**Fix.** Require an outcome or high-integrity commitment label per item. A row that cannot answer "what outcome does this move?" is feature factory; either frame the outcome or cut.

**Grep marker.** Rows with no "outcome or commitment" column; or the column present but values are blank or "deliver feature X."

## 3. Build trap

**Source:** Melissa Perri, "Escaping the Build Trap," O'Reilly, 2018. https://melissaperri.com/book

**Shape.** The institutional symptom. Output metrics (features shipped, velocity) are present and celebrated; outcome metrics (retention, activation, revenue) are absent or ignored. Teams are rewarded for shipping, not for moving the needle.

**Example.** Quarterly review slides show "shipped 14 features this quarter" with no mention of which moved which KPI.

**Fix.** Require at least one outcome metric per theme, with a measurement source and a check-in cadence. Track outcome alongside output in retrospectives.

**Grep marker.** A roadmap with "features shipped" as the only success indicator, or with no theme having a KPI attached.

## 4. Roadmap theater

**Source:** Industry term; adopted, not coined by us. See https://theaipoweredprojectmanager.substack.com/p/your-project-roadmap-is-a-lie-you and https://www.appcues.com/blog/a-gantt-chart-is-not-a-product-roadmap

**Shape.** Gantt-chart aesthetics with dates pulled from thin air. "The visual confidence of the chart can exceed the actual confidence of the underlying knowledge." Dates to the day, four-quarter grids, bar chart art.

**Example.**

```
| Q1 | Q2 | Q3 | Q4 |
|----|----|----|----|
| Jan 15: Feature A | Apr 3: Feature E | Jul 22: Feature I | Oct 8: Feature M |
| Feb 4: Feature B | ... | ... | ... |
...
```

**Fix.** Strip fictional precision. Demote to Next (confidence band) or Later (thematic) as appropriate. Require high-integrity commitment labels for any fixed-date commit.

**Grep marker.** Day-level dates across all horizons without confidence bands or commitment labels.

## 5. Fictional precision

**Source:** Emerging, 2024-2026. Common AI-generated failure mode.

**Shape.** A single-point date (YYYY-MM-DD) asserted with no capacity input, no confidence band, no commitment reason. Typically LLM-generated, but humans do it too when tools encourage it.

**Example.** "Ship onboarding redesign: 2026-07-14."

**Fix.** Either: add a confidence band ("2026-07-14, 70%"), or add a commitment label ("high-integrity: regulatory audit window"), or move to a range ("late July 2026"), or demote to Next/Later.

**Grep marker.** YYYY-MM-DD dates with no adjacent confidence indicator and no commitment label.

## 6. Fictional parallelism

**Source:** Adjacent to Critical Chain Project Management (Goldratt) and multi-tasking-myth literature. Not coined under this exact name but widely-observed pattern.

**Shape.** The roadmap shows N parallel tracks; team has fewer than N engineers. Tracks appear parallel on the diagram; in practice they serialize, and the cycle runs late.

**Example.** 4-track Q2 roadmap on a team of 2 engineers. Each track "owned by the team" without per-track owner.

**Fix.** Count concurrent tracks per period. If the count exceeds team size, re-sequence or cut. See [`dependency-graph.md`](dependency-graph.md) section 4.

**Grep marker.** Number of rows in Now with overlapping date ranges exceeds team-capacity pre-flight answer.

## 7. Invisible parallelism

**Source:** Amdahl's law applied to coordination overhead. See https://en.wikipedia.org/wiki/Amdahl's_law and https://shahbhat.medium.com/applying-laws-of-scalability-to-technology-and-people-5884b4b4b04

**Shape.** The roadmap respects team size on paper, but concurrent tracks share a bottleneck (central auth service, a single domain expert, a shared SRE team, a legal review). The bottleneck serializes what looked parallel.

**Example.** Three tracks all depend on "auth API changes," with no auth API slice scheduled. The three tracks stall waiting for auth.

**Fix.** For each period, list items and their dependencies. If three or more items share a dependency, schedule the dependency first or cut concurrent tracks. See [`dependency-graph.md`](dependency-graph.md) section 7.

**Grep marker.** Multiple rows in a period naming the same dependency that is not scheduled earlier.

## 8. Quarter-stuffing

**Source:** Hofstadter's law (1979) + Kahneman-Tversky planning fallacy (1979) applied to quarterly buckets.

**Shape.** Q1, Q2, Q3, Q4 filled to identical density with identical precision. Far-future quarters appear as confident as near-future.

**Example.** Q1 has 4 items each with day-level dates; Q4 has 4 items each with day-level dates. The Q4 items are treated as committed despite being 9 months out.

**Fix.** Apply Now-Next-Later precision gradient. Later is thematic; Next is directional; Now is specific. Equal precision across horizons is the failure.

**Grep marker.** Row count and precision equal across Now, Next, Later columns.

## 9. Speculative roadmap

**Source:** Descriptive; Roman Pichler's "10 Product Roadmapping Mistakes to Avoid" covers adjacent territory. https://www.romanpichler.com/blog/product-roadmapping-mistakes-to-avoid/

**Shape.** The roadmap contains items that are not in the PRD, not in the architecture, and not named external constraints. They appeared out of nowhere: suggested by a stakeholder, invented by an LLM, assumed because "every product has one."

**Example.** "AI chatbot" in Q3 when the PRD does not mention AI and the product is not AI-adjacent.

**Fix.** For every item, check the upstream anchor. If neither PRD section nor architecture component nor external constraint is referenced, route to prd-ready (for inclusion in PRD) or cut.

**Grep marker.** Rows with no PRD ref, no architecture ref, no external-constraint tag.

## 10. Shelf roadmap

**Source:** Descriptive; ProductPlan's "Reasons Roadmaps Fail" (https://www.productplan.com/learn/reasons-product-roadmaps-fail/) and ProdPad's "Problem with the Perfect Roadmap" (https://www.prodpad.com/blog/problem-perfect-roadmap/).

**Shape.** The roadmap was written once, signed off, filed. It is no longer consulted. Engineering works from the sprint backlog; the roadmap has become decoration.

**Example.** Last-reviewed date on the roadmap is 4 months ago. The current Now column references slices that were completed 6 weeks ago and no longer exist.

**Fix.** Mode C iteration: re-run the review cycle. Archive completed items; promote Next to Now; refresh confidence bands. Declare a review cadence if absent.

**Grep marker.** Last-reviewed date older than one cadence cycle; Now column contains items that have obviously shipped.

## 11. Polish-indefinitely

**Source:** Shape Up's circuit-breaker exists specifically to counter this. https://basecamp.com/shapeup/3.5-chapter-14

**Shape.** Current milestone is 1+ weeks past its target date. No explicit extension decision was recorded. The team is iterating "just one more thing" on the current item instead of shipping and moving on.

**Example.** Shape Up big-batch cycle is in week 7 of a 6-week budget. No cut decision; no explicit re-bet. The team keeps polishing.

**Fix.** Fire the circuit-breaker: at appetite boundary, cut or re-bet explicitly. Move remaining polish to next cycle's backlog. Ship what's there.

**Grep marker.** Milestone target date passed; status is not `done` or `cut`; no extension decision logged.

## 12. Perpetual-now

**Source:** Adjacent to feature factory (everything is urgent) and shelf roadmap (no forward view).

**Shape.** All items are in Now; Next and Later are empty. There is no roadmap beyond the current cycle. Every meeting is about the current fires.

**Example.** ROADMAP.md has a Now column with 8 items; the Next and Later sections contain "TBD."

**Fix.** Populate Next and Later. If the team genuinely does not know what comes after Now, write the open questions (three-label test: "named open question"). Empty Next/Later is an incomplete roadmap.

**Inverse:** Everything in Later, nothing in Now. The roadmap is all hope and no execution. Promote at least one Later item to Now at the next review.

**Grep marker.** Now populated; Next + Later both empty or placeholder.

## 13. Linear (single-track) roadmap

**Source:** Descriptive; the single-lane fallacy.

**Shape.** All items in one column. No acknowledgement of parallelism even when team size supports it and architecture DAG allows it.

**Example.** Team of 5; 12 items; all sequenced one-after-another in a single queue. Two-thirds of the team is idle at any given time.

**Fix.** Re-run Step 4 sequencing with dependency graph. Identify items that can run in parallel; allocate to parallel tracks. Respect capacity and Amdahl.

**Grep marker.** Team size > 1 AND all items in a single chain with sequential dependencies AND no item is structurally blocking.

## 14. Date-driven without appetite (inverse of Shape Up)

**Source:** Inverse of Singer's "Fixed time, variable scope." https://basecamp.com/shapeup/1.2-chapter-03

**Shape.** Fixed dates are set with no scope-flex mechanism. Scope is "everything we want"; dates slip or scope crashes at the end.

**Example.** "Ship everything in the PRD by 2026-07-01." No MoSCoW, no appetite per item, no cut line.

**Fix.** Declare a scope-flex mechanism: appetite per item (Shape Up) or MoSCoW tiering (milestone-based) or cut-from-top (continuous). A fixed date with no cut mechanism is date-driven without appetite.

**Grep marker.** Fixed date on a milestone with no MoSCoW ranks on in-scope items and no appetite labels.

## 15. Scope-driven disguised as date-driven

**Source:** Same as 14.

**Shape.** A date is committed; scope is held "all in"; the team believes it's date-driven. In reality, scope is the fixed input; the date will slip because scope never flexes.

**Example.** "Ship v2 by end of Q3 with all 12 features" stated as a Q3 commit. When week 10 of 13 shows only 4 features on track, the team extends rather than cuts.

**Fix.** At commit time, explicitly label: are we date-fixed (scope flexes) or scope-fixed (date flexes)? Both with no flex is the failure mode. If genuinely both (high-integrity commitment), name the reason and require Tier 3 sign-off.

**Grep marker.** Fixed scope + fixed date + no high-integrity commitment label.

## 16. Polish-vs-launch confusion

**Source:** Related to polish-indefinitely.

**Shape.** The team treats launch as "when everything is perfect." Launch readiness gates are absent; every un-launched week is "we're polishing."

**Example.** Launch milestone targeted for Q2; it's Q4 and still un-launched. Nothing is broken; nothing is finished.

**Fix.** Define launch-readiness as an explicit gate (see [`launch-sequencing.md`](launch-sequencing.md) section 2.3). Observability live + rollback tested + runbooks reviewed. Once those gates pass, launch. Polish happens post-launch.

**Grep marker.** Launch milestone has no dated readiness gates; target date slipping monotonically.

## 17. Public file is the internal file

**Source:** Common commercial-leak pattern.

**Shape.** A single roadmap file is published to customers while containing internal owners, capacity math, rabbit-hole specifics, or contractual detail.

**Example.** Publishing a Notion doc that shows "Engineer @alice assigned to SSO" and "Rabbit hole: auth rewrite is tempting" to external customers.

**Fix.** Produce a separate ROADMAP-PUBLIC.md per Step 10 redaction rules. Never share the internal file externally.

**Grep marker.** Public-audience roadmap contains owner names, capacity numbers, or rabbit-hole descriptions.

## 18. Roadmap without a cadence

**Source:** Descriptive.

**Shape.** A document titled "Roadmap" with no cadence declaration. The tool's default cadence (usually Gantt) wins by default.

**Example.** A 200-item list in Linear or Jira with no release cadence, no milestone boundaries, no Shape Up cycles, no quarterly themes. Just a list.

**Fix.** Run Step 2 (cadence selection). Declare one cadence with rationale; state the re-evaluation trigger.

**Grep marker.** No cadence declaration in ROADMAP.md header or "Cadence" section missing.

## 19. Roadmap without a review cadence

**Source:** Descriptive; direct cause of shelf roadmap.

**Shape.** The roadmap is built but has no recurring review schedule. After one cycle, it drifts into staleness.

**Example.** ROADMAP.md exists; no mention of when it gets reviewed or who has authority to update it.

**Fix.** Run Step 9. Declare review frequency, authority map, re-plan triggers, freeze conditions.

**Grep marker.** No "Review cadence" section in ROADMAP.md.

## 20. Launch milestone without readiness gates

**Source:** Common; launch-sequencing failure.

**Shape.** Launch milestone exists; has a target date; has pre-launch feature list. But the readiness gates (observability, rollback, runbooks, support) are absent. The launch is scheduled for a crisis.

**Example.** "Launch 2026-07-01: M1, M2, M3 complete." No observability-live date; no rollback-tested date; no runbooks-reviewed date.

**Fix.** Add the four readiness gates from [`launch-sequencing.md`](launch-sequencing.md) section 2.3. Each with a target date and an owner.

**Grep marker.** Launch milestone has no "Readiness gates" section or the section lacks observability-live + rollback-tested + runbooks-reviewed + support-briefed.

## 21. Banned grid-generation output (AI-slop)

**Source:** Emerging, 2024-2026. The canonical AI roadmap failure.

**Shape.** An LLM or AI tool produces a four-quarter grid with even fill, invented dates, no upstream references, no cadence declaration. Looks confident; decides nothing.

**Example.** (See sections 4, 5, 8 combined.)

**Fix.** Reject wholesale. Re-run from Step 0. Demand pre-flight inputs; enforce the three-label test; require upstream anchors.

**Grep marker.** Four-quarter columns with identical density, invented dates, no cadence section, no pre-flight section. Composite pattern.

## 22. Summary disposition matrix

| Antipattern | Dominant marker | Fix at step |
|---|---|---|
| Feature factory | No outcome column | Step 1 (declare outcome per item) |
| Build trap | Only output KPIs | Step 5 (milestone completion gates = outcomes) |
| Roadmap theater | Day-level dates, no bands | Step 6 (precision gradient) |
| Fictional precision | Single-point dates, no basis | Step 1 (require capacity input) |
| Fictional parallelism | Concurrent tracks > team size | Step 4 (capacity check) |
| Invisible parallelism | Shared dependency unacknowledged | Step 4 (Amdahl check) |
| Quarter-stuffing | Equal density across horizons | Step 6 (horizon precision) |
| Speculative roadmap | No upstream anchors | Step 3 (grounding corollary) |
| Shelf roadmap | Stale last-reviewed | Step 9 (review cadence) |
| Polish-indefinitely | Passed target, no decision | [`scope-vs-time.md`](scope-vs-time.md) section 5 (circuit breaker) |
| Perpetual-now | Next + Later empty | Step 6 (populate all horizons) |
| Linear single-track | No parallelism despite capacity | Step 4 (re-sequence) |
| Date-driven no appetite | Fixed date, no cut mechanism | [`scope-vs-time.md`](scope-vs-time.md) section 1 |
| Scope-driven disguised | Fixed both, no label | Step 5 (high-integrity commitment label) |
| Polish-vs-launch | No readiness gates on launch | Step 7 (launch sequencing) |
| Public-internal leak | Internal content in public file | Step 10 (redaction rules) |
| No cadence | Cadence section missing | Step 2 (cadence selection) |
| No review cadence | Review section missing | Step 9 |
| Launch no gates | Readiness gates absent | Step 7 |
| AI-slop grid | Composite failure | Mode B audit (Step 1.5) |

## 23. Summary

Every roadmap antipattern is a specific violation of the three-label test or of the upstream-grounding rule. The skill checks for each at tier gates; the have-nots in SKILL.md are the enforced subset. A roadmap that passes every grep marker in this catalog is a roadmap that commits what it can ground and refuses what it cannot.
