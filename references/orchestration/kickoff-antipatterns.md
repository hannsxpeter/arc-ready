# Anti-pattern catalog: named failure modes with grep tests and guards

This file is the operational reference for kickoff-ready's have-nots. Every named failure mode from `references/RESEARCH-2026-04.md` Section 2 has an entry here with:

1. The definition.
2. The grep test (how an auditor or a reviewer detects the pattern).
3. The kickoff-ready guard (the specific defense the skill runs).
4. The citation back to the research report.
5. The severity.

Loaded on demand during verification. Cited from the SKILL.md "have-nots" section.

## How the catalog is structured

| Field | Meaning |
|---|---|
| **Definition** | The failure mode in one sentence. |
| **Grep test** | A specific pattern an auditor checks for. Concrete: file path, regex, count, comparison. |
| **Guard** | What kickoff-ready does to prevent the failure. Operational, not aspirational. |
| **Severity** | Critical / High / Medium. Critical means the skill's contract is violated and the kickoff is invalid; High means the kickoff is degraded; Medium means a smaller correctness issue. |
| **Citation** | Where the failure mode is documented. Research report section, sibling SKILL.md, or external source. |

## Anti-pattern 1: Scope leak

**Severity:** Critical.

**Definition.** The orchestrator drifts into producing the specialist's content rather than invoking the specialist. kickoff-ready writes a PRD inline instead of calling prd-ready; sketches an architecture instead of calling architecture-ready; produces a launch checklist instead of calling launch-ready.

**Grep test.** Audit kickoff-ready's conversation transcript or output. Search for any of:
- `# Product Requirements`, `## Problem statement`, `## Functional requirements`, `## Success metrics`
- `# System Architecture`, `## Trust Boundaries`, `## Data Flow`, `ADR-`
- `## Now`, `## Next`, `## Later` (in roadmap form)
- `## Stack recommendation`, framework comparison tables
- Marketing copy patterns (`"Build the future of"`, `"The first AI-native"`)
- Severity-classified security findings, OWASP category headers
- Code blocks tagged with language identifiers in non-quote contexts

If any appear in kickoff-ready's output (not in PROGRESS.md as a path reference), scope leak fired.

**Guard.** Step 7 of the workflow. On every out-of-scope request, kickoff-ready refuses, names the failure mode, routes to the correct sibling, and resumes. The scope-fence catalog (`references/scope-fence.md`) lists eleven canonical refusals.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.4 (Praetorian on deterministic orchestration; AgentOrchestra on supervisor co-authorship). production-ready/ORCHESTRATORS.md invariant 1 ("the harness is the router; no ready-suite skill calls another").

## Anti-pattern 2: Rubber-stamp orchestration

**Severity:** Critical.

**Definition.** PROGRESS.md is advanced to `done` for a step without verifying the specialist actually produced its declared artifact on disk. The orchestrator trusts the sibling's "I'm done" claim or the conversation's success-shaped tone instead of checking disk.

**Grep test.** For every PROGRESS.md row with `status: done`:
- Does the file at `artifact_path` exist on disk? `[ -f "$artifact_path" ]`
- Is its size non-trivial? `wc -c "$artifact_path"` returns more than 100 bytes (or the sibling's documented threshold).
- Is the file's mtime later than the row's `invocation_ts`? `stat -c %Y "$artifact_path"` is greater than the timestamp.

If any check fails, rubber-stamp orchestration fired.

**Guard.** SKILL.md Step 3, 4, 5 verification gate. Two-check rule: artifact exists AND artifact non-empty. The post-invocation checks in `references/sequencing-rules.md` Section "Post-invocation checks" run mechanically; the LLM does not get to decide.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.1 (Cogent's 2026 multi-agent orchestration playbook on "the orchestrator only checks whether an agent ran successfully rather than reading verification verdicts"; Cybermaniacs on rubber-stamp risk; the AWS / DEV piece on multi-agent validation).

## Anti-pattern 3: Phantom resume

**Severity:** Critical.

**Definition.** kickoff-ready claims to resume from PROGRESS.md but starts fresh because (a) the prompt cache was invalidated, (b) compression-summary loss caused the agent to relitigate step one, or (c) the agent inherited stale tool-result state and made decisions based on yesterday's truth.

**Grep test.** Audit kickoff-ready's session start. Every kickoff-ready turn (not just the first) must begin with:
- A literal `Read .kickoff-ready/PROGRESS.md` operation.
- An `ls .{skill}-ready/` operation per claimed-complete sibling.
- A re-derivation of the current step from disk before any further action.

If a turn skipped these and acted on cached conversation memory, phantom resume fired.

**Guard.** SKILL.md Step 1 resume protocol. `references/progress-tracking.md` "Resume protocol" section. The protocol is mechanical and runs every turn, not just on explicit resume.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.3 cites six failure modes from the Anthropic claude-code issue tracker:
- Cache invalidation on resume (anthropics/claude-code#42338)
- Context-compression confusion on resume (NousResearch/hermes-agent#17344)
- Stale-state inheritance on failed-run resume (paperclipai/paperclip#635)
- Stale tool results in resumed sessions
- Token overhead on long-session resume (anthropics/claude-code#42260)
- Undocumented resume behavior (anthropics/claude-code#42309)

## Anti-pattern 4: Ghost handoff

**Severity:** High.

**Definition.** kickoff-ready invokes a sibling without first verifying its upstream artifact exists. The architect agent runs before `.prd-ready/PRD.md` is on disk; it hallucinates a PRD-equivalent from the user's one-paragraph idea; the downstream chain proceeds on a fictional foundation.

**Grep test.** For every Skill-tool invocation kickoff-ready emits:
- The sibling's `upstream:` list (per `references/sequencing-rules.md` per-sibling upstream contract) is fully present on disk before the invocation timestamp.
- PROGRESS.md shows verified-done rows for every upstream sibling.

If invocation happened with a missing upstream, ghost handoff fired.

**Guard.** SKILL.md Step 3, 4, 5 pre-invocation upstream-artifact-exists check. `references/sequencing-rules.md` "Mid-arc checks" section.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.7 (Galileo on multi-agent coordination failure where handoffs do not include verifiable pointers; the LLM-agent hallucination survey on agents asked to infer state).

## Anti-pattern 5: Happy-path orchestration

**Severity:** High.

**Definition.** kickoff-ready handles the case where every sibling succeeds and writes its artifact, but has no policy for: sibling X failed; sibling X claimed success but artifact is missing; the user wants to skip sibling X; the user already has the PRD from before kickoff-ready started; the user wants to re-run sibling X because the input changed.

**Grep test.** Read PROGRESS.md schema. The status vocabulary must include:
- `pending` (not started)
- `in-flight` (invoked, not yet returned)
- `done` (completed and verified)
- `skipped` (user opted out, recorded reason)
- `imported` (artifact pre-existed, recorded source)
- `failed` (returned but verification failed, recorded retry budget)
- `re-invoked` (user re-ran a previously-done step, recorded why)

If only `pending` and `done` exist in the schema or in actual rows, happy-path orchestration fired.

**Guard.** `references/progress-tracking.md` status vocabulary defines all seven statuses. SKILL.md Step 2 captures skip declarations. SKILL.md Step 1 detects imports. The re-invocation rules in `references/sequencing-rules.md` handle change.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.6 (Wikipedia on "happy path"; the LangGraph supervisor-vs-swarm tradeoffs piece on edge-case coverage gaps and graph complexity blowup).

## Anti-pattern 6: State-vs-artifact drift (also: ouroboros progress)

**Severity:** High.

**Definition.** PROGRESS.md says step N is done; `.{skill-N}-ready/` either does not exist on disk, exists empty, or contains only the unmodified template scaffold. The state file is reading from itself instead of from disk.

**Grep test.** This is the visible symptom of rubber-stamp orchestration (anti-pattern 2). The test is the same: every `done` row's artifact verifies on disk.

**Guard.** Same as anti-pattern 2: the two-check rule and the resume protocol's disk-vs-PROGRESS reconciliation.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.2 (Galileo on shared-context corruption; Cleanlab on agents asked to infer state instead of querying it; arXiv 2509.18970 on LLM-agent hallucinations).

Note: this anti-pattern is recorded as a name kickoff-ready uses but does not claim. The flagship name is rubber-stamp orchestration (the cause); state-vs-artifact drift is the visible symptom; ouroboros progress is the metaphor.

## Anti-pattern 7: Goal drift via supervisor anchoring

**Severity:** Medium.

**Definition.** The supervisor (kickoff-ready) anchors to its own conversation memory rather than to the dependency graph and the per-sibling consumes list. Over many turns, the supervisor's idea of "where we are" drifts from disk truth.

**Grep test.** For every kickoff-ready turn, compare:
- The agent's claim of "current step" (from conversation).
- The PROGRESS.md "next step" (from re-deriving from disk per Step 1 protocol).

If they disagree and the agent acted on the conversation claim, goal drift fired.

**Guard.** Step 1 resume protocol enforces disk-as-truth. The supervisor's anchor is the dependency graph (data) and the artifact-on-disk check (mechanical), not the conversation.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.12 (LangGraph supervisor pattern goal-drift; Galileo on supervisors becoming silent co-authors).

## Anti-pattern 8: Skip-as-silence

**Severity:** Medium.

**Definition.** A sibling is omitted from kickoff-ready's chain without an explicit `skipped` row in PROGRESS.md. The auditor reading PROGRESS.md cannot tell whether the skip was an intentional decision or whether kickoff-ready forgot the sibling.

**Grep test.** Every sibling in the suite has exactly one row in PROGRESS.md (or a documented re-invoked history). Silence (no row at all) is the failure.

**Guard.** Step 2 declaration for known-at-start skips; mid-arc declaration with PROGRESS.md update for runtime skips; the Shape Up no-gos discipline applied to PROGRESS.md.

**Citation.** `references/RESEARCH-2026-04.md` Section 3.3 (Shape Up no-gos as the model: a pitch lists what is explicitly out, not silence).

## Anti-pattern 9: Critical-finding gate bypass

**Severity:** Critical.

**Definition.** harden-ready emits a Critical finding (open status) and kickoff-ready advances launch-ready to `done` without an explicit risk-acceptance entry in PROGRESS.md. The launch happens on top of an unresolved adversarial-review finding.

**Grep test.** For every PROGRESS.md showing launch-ready as `done`:
- Read `.harden-ready/FINDINGS.md`.
- Filter for Critical findings with status != Closed.
- For each open Critical: PROGRESS.md `## Risk acceptances` must contain a dated, named, justified entry pointing to that finding.
- If any Critical lacks a corresponding acceptance row, the gate was bypassed.

**Guard.** SKILL.md Step 5 critical-finding gate logic. `references/sequencing-rules.md` "Critical-finding gate logic" section. The gate algorithm runs on every kickoff-ready turn during shipping tier.

**Citation.** `references/RESEARCH-2026-04.md` Section 5.5 (recommended default; harden-ready's pairs_with declaration; the security-sensitive override patterns).

## Anti-pattern 10: God-skill drift

**Severity:** Medium.

**Definition.** kickoff-ready's SKILL.md, references, or README begin to grow content that overlaps with sibling deliverables. The skill body crosses the size and scope of a specialist; the orchestrator becomes a second specialist.

**Grep test.** Compare SKILL.md line count and content density against the siblings:
- `wc -l SKILL.md` for kickoff-ready and for the shortest sibling (deploy-ready at ~495 lines per the May 2026 versions).
- kickoff-ready should be smaller than every sibling. If it grows past the sibling median, scope leak is happening at the documentation layer.
- Section headers in kickoff-ready's references should be orchestration-flavored (sequencing, handoff, progress, scope, anti-patterns), not specialist-flavored (PRD, architecture, roadmap, etc.).

**Guard.** Every release of kickoff-ready passes the fence audit (`references/scope-fence.md` Section "Summary"). New features must be orchestration-tier metadata; new content must not duplicate sibling work.

**Citation.** `references/RESEARCH-2026-04.md` Section 2.5 (Praetorian on monolithic agents; "god skill" as the cautionary endpoint, not a refusal name).

## Anti-pattern 11: Composing with the wrong orchestrator

**Severity:** Medium.

**Definition.** kickoff-ready ends, but the user's project still needs ongoing phase / milestone work, and kickoff-ready's Step 6 hands off to a phase orchestrator that does not exist or that the user did not configure. The arc completes; the next phase has no owner.

**Grep test.** PROGRESS.md `## Kickoff complete` block names a "Recommended next-step orchestrator" but the user has no installed orchestrator matching the recommendation.

**Guard.** Step 6 surfaces the recommendation honestly. If the user has GSD installed, recommend GSD. If they have BMAD, recommend BMAD with the boundary-translation pattern from production-ready/ORCHESTRATORS.md. If they have neither, recommend running siblings directly when needed (the "no orchestrator" pattern from production-ready/ORCHESTRATORS.md).

**Citation.** production-ready/ORCHESTRATORS.md sections on GSD, BMAD, and "no orchestrator." `references/handoff-protocols.md` "Composition with phase orchestrators" section.

## Anti-pattern 12: Re-invocation without history preservation

**Severity:** Medium.

**Definition.** The user re-runs a previously-done sibling. PROGRESS.md is updated to show the new run, but the prior `done` row is overwritten or deleted. The audit history is lost.

**Grep test.** PROGRESS.md should grow monotonically. A sibling that was re-invoked should have at least two rows: the prior `done` row (with status moved to `re-invoked` and a `notes` field pointing to the new row) and the new in-flight or done row.

**Guard.** `references/progress-tracking.md` "Re-invocation discipline" section. PROGRESS.md grows; nothing is deleted (except by explicit user-initiated cleanup, which is itself recorded as a note).

**Citation.** `references/RESEARCH-2026-04.md` Section 5.7 (the re-invocation rules; the GitHub Actions re-run-failed-jobs discipline).

## How to use the catalog during verification

A reviewer auditing a kickoff-ready run does this:

1. Open `.kickoff-ready/PROGRESS.md`.
2. For each row with status `done` or `imported`: run anti-pattern 2 grep test (artifact exists, non-empty, mtime later than invocation).
3. For the chain as a whole: run anti-pattern 4 grep test (each invocation had its upstream verified before).
4. For the schema: run anti-pattern 5 grep test (all seven statuses are possible; not just done/pending).
5. For the conversation transcript: run anti-pattern 1 grep test (no specialist content in kickoff-ready's output).
6. If harden-ready ran: run anti-pattern 9 grep test (Critical-gate compliance).
7. For session continuity: run anti-pattern 3 grep test (every turn re-reads PROGRESS.md).

If all pass, the kickoff is valid. If any fail, the failure mode has fired and the kickoff is invalid; remediation depends on the severity.

## Severity escalation

- **Critical failure** (anti-patterns 1, 2, 3, 9): the kickoff is invalid. The skill's contract is broken. Remediation: re-run the affected steps; do not declare the kickoff complete until the failure is corrected.
- **High failure** (anti-patterns 4, 5): the kickoff is degraded. The chain proceeded on a fictional foundation or omitted policy. Remediation: roll back to the failure point; correct PROGRESS.md; re-invoke from there.
- **Medium failure** (anti-patterns 6, 7, 8, 10, 11, 12): the kickoff is correctness-imperfect but probably still useful. Remediation: note the failure in PROGRESS.md `## Notes` section; proceed; fix in the next pass.

## Summary

Twelve named failure modes. Each has a definition, a grep test, a guard, a citation, a severity. The catalog is the operational reference for SKILL.md's have-nots and for any review of a completed kickoff. If a future failure mode is discovered, it is added here with the same five fields; it is not surfaced inline in SKILL.md.
