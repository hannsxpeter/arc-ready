# PROGRESS.md schema, resume protocol, and audit ledger

This file defines the only artifact kickoff-ready produces: `.kickoff-ready/PROGRESS.md`. The ledger is the source of truth for "where in the kickoff arc this project sits," nothing more. The siblings own their own artifacts; PROGRESS.md is a denormalized read-cache for the auditor and the resume protocol.

Read this file at workflow Steps 1, 2, and 6.

## The single load-bearing principle

PROGRESS.md is **a view, not a database**. The source of truth is the union of `.{skill}-ready/` directories on disk. Every kickoff-ready turn begins by re-deriving state from disk; if PROGRESS.md disagrees with disk, **disk wins** and PROGRESS.md is corrected.

This discipline comes from Just / Make (`references/RESEARCH-2026-04.md` Section 3.4): "the file system is the truth." A target is "done" if its output file exists and is non-empty. Without this discipline, kickoff-ready cannot defend against the phantom-resume class of failures cited in Anthropic claude-code issues #42338, #42260, #42309, NousResearch hermes-agent#17344, and paperclipai#635 (research Section 2.3).

## Schema

PROGRESS.md is plain markdown with three top-level sections.

### Section 1: Frontmatter (required)

A YAML block at the top of the file. Stable identifiers, not narrative.

```yaml
---
project: <one-line name; the user's own words preferred>
intent: <one-paragraph project description, quoted verbatim from the user's request>
kickoff_started: <ISO8601 timestamp of first kickoff-ready turn>
last_turn: <ISO8601 timestamp of most recent kickoff-ready turn>
harness: <claude-code | codex | antigravity | cursor | windsurf | chat-frontend>
mode: <new | resume | import>
appetite: <optional time budget; e.g., "2 weeks", "exploring", "1-day prototype">
skill_version: 1.0.0
---
```

The `last_turn` field updates every turn. Used by the resume protocol to detect "did we crash mid-turn" cases.

### Section 2: Kickoff intent (Step 2 output, stable thereafter)

A short prose block that captures Step 2's output. Three sub-sections:

```markdown
## Kickoff intent

### Project description
<one-paragraph; the user's request paraphrased and confirmed back to them>

### Greenfield check
<confirmed greenfield | imports declared below>

### Skip declarations
<list of siblings the user explicitly opts out of, with reason>
- harden-ready: skip (one-day prototype; no real user surface)
- launch-ready: defer (internal-only tool; no public launch)

### Imports
<list of upstream artifacts the user already had before kickoff-ready started>
- prd-ready: imported from existing /docs/prd.md (copied to .prd-ready/PRD.md on 2026-05-06)
```

This section is set in Step 2 and revised only on explicit user re-confirmation. It is **not** rewritten on every turn.

### Section 3: Step ledger (load-bearing)

A markdown table, one row per sibling. Every sibling kickoff-ready knows about (the ten plus any future additions) appears as a row, even if the row's status is `pending` or `skipped`. **Silence is not a status.**

Schema:

| Column | Required | Type | Notes |
|---|---|---|---|
| `step` | yes | integer | Index in the topological sort. 1 through N. |
| `sibling` | yes | string | Sibling name (e.g., `prd-ready`). |
| `status` | yes | enum | One of `pending`, `in-flight`, `done`, `skipped`, `imported`, `failed`, `re-invoked`. Never blank. |
| `artifact_path` | yes | string | Full path of the sibling's primary deliverable. Empty string allowed only when status is `pending` or `skipped`. |
| `invocation_ts` | conditional | ISO8601 | Timestamp the sibling was invoked. Required for `in-flight`, `done`, `failed`, `re-invoked`. |
| `verification_ts` | conditional | ISO8601 | Timestamp the artifact-exists check passed. Required for `done` and `imported`. |
| `disk_state_hash` | conditional | string | File mtime in epoch seconds (sufficient as a hash). Required for `done` and `imported`. |
| `notes` | optional | string | Reason for skip, retry budget for failed, source path for imported, etc. |

Example:

```markdown
## Step ledger

| Step | Sibling | Status | Artifact path | Invocation TS | Verification TS | Disk hash | Notes |
|---|---|---|---|---|---|---|---|
| 1 | prd-ready | done | .prd-ready/PRD.md | 2026-05-06T14:02:11Z | 2026-05-06T14:18:33Z | 1746540513 | |
| 2 | architecture-ready | done | .architecture-ready/ARCH.md | 2026-05-06T14:21:00Z | 2026-05-06T14:39:14Z | 1746541654 | |
| 3 | roadmap-ready | done | .roadmap-ready/ROADMAP.md | 2026-05-06T14:42:00Z | 2026-05-06T14:55:08Z | 1746542508 | |
| 4 | stack-ready | done | .stack-ready/DECISION.md | 2026-05-06T14:57:30Z | 2026-05-06T15:08:42Z | 1746543122 | |
| 5 | repo-ready | done | .repo-ready/STATE.md | 2026-05-06T15:11:00Z | 2026-05-06T15:34:22Z | 1746544462 | |
| 6 | production-ready | in-flight | .production-ready/STATE.md | 2026-05-06T15:36:00Z | | | running tier 1 |
| 7 | deploy-ready | pending | | | | | |
| 8 | observe-ready | pending | | | | | |
| 9 | launch-ready | pending | | | | | |
| 10 | harden-ready | pending | | | | | parallel with launch-ready by default |
```

### Section 4 (optional): Risk acceptances

If `harden-ready` emits a Critical finding and the user explicitly accepts the risk to proceed with launch-ready, record it here:

```markdown
## Risk acceptances

- F-03 (harden-ready Critical, JWT alg-none): accepted by Jamie Chen (founder) on 2026-05-12; mitigation deployed 2026-05-13; revisit at next quarterly hardening. Justification: the affected code path is internal-only behind VPN; no external attack surface during the time-limited window.
```

Each acceptance is dated, named, justified, and time-bounded. This is the harden-ready risk-register pattern; kickoff-ready inherits it for the launch-gate exception.

## Status vocabulary

The seven statuses cover every state a step can be in. Adding more is unnecessary; mapping anything else into these seven is required.

- **pending.** Not yet started. The default for every step at kickoff begin (after Step 2). No timestamps required.
- **in-flight.** The sibling has been invoked but has not yet returned a verified artifact. `invocation_ts` set; `verification_ts` not yet set.
- **done.** The sibling completed and the artifact-exists check passed. Both `invocation_ts` and `verification_ts` set; `disk_state_hash` set.
- **skipped.** The user explicitly opted out. `notes` MUST contain the reason. No timestamps required (the skip is a decision, not an action).
- **imported.** An artifact at the expected path was already present before kickoff-ready ran (Step 0 detection) or the user explicitly imported it during the chain. `verification_ts` and `disk_state_hash` set; `invocation_ts` blank or set to the import action's timestamp; `notes` contains the source path or "pre-existing."
- **failed.** The sibling was invoked, returned, but the artifact-exists check did not pass (file missing, file empty, file is the unmodified template). `invocation_ts` set; `verification_ts` blank; `notes` contains the failure mode and retry budget. The next kickoff-ready turn re-invokes the sibling unless the budget is exhausted, in which case the user is asked to intervene.
- **re-invoked.** The user explicitly chose to re-run a previously-done sibling because the input changed. The prior `done` row is preserved (with status moved to `re-invoked`) and a new row is added below it for the re-invocation. `notes` on the prior row contains the reason ("PRD changed; re-running architecture-ready").

## Resume protocol

Run **every turn**, not just on explicit `/resume`. This is non-optional and is the only defense against phantom resume.

```
1. Read .kickoff-ready/PROGRESS.md.
   If absent: kickoff-ready is in `new` mode (Step 0 of workflow).
   If present: kickoff-ready is in `resume` mode.

2. For every row in the step ledger with status `done` or `imported`:
   a. Check that `artifact_path` exists on disk.
   b. Check that the file is non-empty (size > 100 bytes is a reasonable
      threshold; an empty template scaffold is the failure to detect).
   c. Compute the current file mtime. If it differs from the recorded
      `disk_state_hash` by more than a tolerance, note the drift.

3. If any `done` or `imported` row fails (a) or (b):
   - Disk wins. Update the row's status to `failed` (or `pending` if the
     artifact was never produced).
   - Note the drift in PROGRESS.md with a timestamp.
   - The next step is to re-invoke that sibling, not to advance.

4. If all `done` and `imported` rows verify:
   - Identify the next `pending` or `in-flight` row.
   - That row is the current step.

5. Record the resume verification in PROGRESS.md frontmatter as
   `last_turn: <now>` and add a one-line entry under a `## Resume log`
   section if any drift was detected.
```

The resume protocol is mechanical. It does not require LLM judgment; it requires file reads. An LLM that "remembers" we are at step 5 without re-reading PROGRESS.md is failing the protocol. Every turn re-reads.

## Skip-when-artifact-exists logic (import detection)

In Step 0, before any other action, kickoff-ready checks for pre-existing sibling artifacts. The check is per-sibling and uses the canonical artifact paths from `references/sequencing-rules.md` per-sibling upstream contract.

```
For each sibling in the topological order:
  Check if the sibling's primary artifact exists on disk.
  (For repo-ready, the check is multi-file: README.md at repo root AND
   any of .github/workflows/*.yml, .gitlab-ci.yml, .editorconfig,
   .repo-ready/SECURITY.md. The other nine siblings are single-file.)
  If yes:
    Mark as candidate import.
    Ask the user (or note in PROGRESS.md if non-interactive):
      "I see .prd-ready/PRD.md already exists. Do you want to:
       (a) import it as the kickoff PRD (skip prd-ready invocation)
       (b) re-run prd-ready (overwrite after confirmation)
       (c) treat the existing file as out-of-scope
           and let kickoff-ready start fresh elsewhere"
  If no:
    Mark as `pending`.
```

The default on a fresh kickoff is to import existing artifacts (option a). The user can override per-sibling. The Yeoman conflict-resolution semantic is the model (research Section 3.5): never silently overwrite existing files; always confirm.

### Canonical primary artifact paths per sibling

| Sibling | Canonical artifact (single-file unless noted) |
|---|---|
| prd-ready | `.prd-ready/PRD.md` |
| architecture-ready | `.architecture-ready/ARCH.md` |
| roadmap-ready | `.roadmap-ready/ROADMAP.md` |
| stack-ready | `.stack-ready/DECISION.md` |
| repo-ready | **Multi-file:** README.md at repo root AND any of (`.github/workflows/*.yml`, `.gitlab-ci.yml`, `.editorconfig`, `.repo-ready/SECURITY.md`). repo-ready does not produce a single STATE.md. |
| production-ready | `.production-ready/STATE.md` |
| deploy-ready | `.deploy-ready/STATE.md` |
| observe-ready | `.observe-ready/STATE.md` |
| launch-ready | `.launch-ready/STATE.md` |
| harden-ready | `.harden-ready/STATE.md` (and `.harden-ready/FINDINGS.md` for the launch-gate check) |

When PROGRESS.md records `artifact_path` for a sibling, it stores the canonical path string from this table. For repo-ready, the field stores the multi-file expression (e.g., `README.md + .github/workflows/`); the verification walks each file.

## What PROGRESS.md is NOT

To prevent scope leak, PROGRESS.md must not contain:

- **PRD content.** No problem statements, no functional requirements, no success metrics. Those belong in `.prd-ready/PRD.md`.
- **Architecture content.** No diagrams, no trust boundaries, no integration shapes. Those belong in `.architecture-ready/ARCH.md`.
- **Roadmap content.** No Now/Next/Later, no milestone details. Those belong in `.roadmap-ready/ROADMAP.md`.
- **Any sibling's deliverable copy-pasted.** PROGRESS.md points to artifact paths; it does not embed their contents.
- **Sprint plans, ticket queues, per-feature work breakdowns.** Those belong to a phase orchestrator (GSD's `.planning/`, BMAD's workflow YAML, or whatever the user chooses).
- **Project-level decisions outside the kickoff arc.** "We decided to add a paid tier" belongs in roadmap-ready's `ROADMAP.md` or the project's own changelog, not in PROGRESS.md.

If a section in PROGRESS.md grows beyond schema-required content, scope leak is happening. Move the content to the correct sibling's artifact and replace it with a path reference.

## The audit-ledger view

After kickoff completes, PROGRESS.md becomes the auditor's view of the project's origin. The Step 6 `## Kickoff complete` block summarizes:

```markdown
## Kickoff complete

Kickoff arc completed on <ISO8601>. The project shipped with the following posture:

| Sibling | Status | Artifact | Verified |
|---|---|---|---|
| prd-ready | done | .prd-ready/PRD.md | 2026-05-06T14:18:33Z |
| architecture-ready | done | .architecture-ready/ARCH.md | 2026-05-06T14:39:14Z |
| roadmap-ready | done | .roadmap-ready/ROADMAP.md | 2026-05-06T14:55:08Z |
| stack-ready | done | .stack-ready/DECISION.md | 2026-05-06T15:08:42Z |
| repo-ready | done | .repo-ready/STATE.md | 2026-05-06T15:34:22Z |
| production-ready | done | .production-ready/STATE.md | 2026-05-08T19:11:55Z |
| deploy-ready | done | .deploy-ready/STATE.md | 2026-05-09T11:02:18Z |
| observe-ready | done | .observe-ready/STATE.md | 2026-05-09T16:48:01Z |
| launch-ready | done | .launch-ready/STATE.md | 2026-05-12T09:30:14Z |
| harden-ready | deferred | (not yet produced) | - |

### Deferred items handed off to ongoing operations
- harden-ready: deferred to next quarterly cycle. Reason: pre-launch alpha; security review scoped for post-public-launch.

### Recommended next-step orchestrator
This project's iteration loop after kickoff is suited to GSD or another phase orchestrator.
The kickoff arc is one-shot; phase work after this is not kickoff-ready's responsibility.
See production-ready/ORCHESTRATORS.md for the GSD integration pattern.
```

The audit-ledger view is durable. It survives kickoff-ready's removal from the harness. A new engineer joining the project six months later can read PROGRESS.md and reconstruct exactly which siblings were invoked, which were skipped, why, and where the artifacts live.

## Re-invocation discipline

When the user re-runs a previously-done sibling because the input changed:

1. Move the prior row's status to `re-invoked` and append `notes: superseded by row N+1; reason: <why>`.
2. Append a new row for the re-invocation with status `in-flight`.
3. Mark every downstream sibling's status as `re-invoked` if its upstream input changed in a way that affects it. (Example: re-running prd-ready likely affects architecture-ready, which affects roadmap-ready, etc. The kickoff-ready agent reasons about the dependency cascade and updates downstream rows accordingly.)
4. The user is informed of the cascade before kickoff-ready re-invokes downstream siblings; they may choose to manually edit downstream artifacts instead of full re-invocation.

The historical row is preserved for audit. PROGRESS.md grows, never shrinks (except for explicit user-initiated cleanup, which is recorded as a note).

## When PROGRESS.md is committed to source control

PROGRESS.md belongs in the repo. Commit it. The next kickoff-ready session reads it from the working tree, not from a separate state directory. This makes the kickoff arc auditable in `git log` and reviewable in PRs.

The only exception: a pure prototype that will be thrown away within the day might run kickoff-ready without committing. In that case, PROGRESS.md is still authoritative for the session but is lost when the directory is deleted. This is the user's call; kickoff-ready does not enforce.

## Summary

The kickoff arc has one persistent artifact: `.kickoff-ready/PROGRESS.md`. The schema is small, the rules are mechanical, and the source of truth is always the file system. Every other rule about kickoff-ready collapses to: read disk, update PROGRESS.md, invoke the next sibling, verify, repeat.
