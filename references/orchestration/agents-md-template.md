# `AGENTS.md` template emitted by kickoff-ready

Loaded at SKILL.md Step 6 sub-step 6a. The template kickoff-ready writes to project root when no `AGENTS.md` exists.

## What this file is for

`AGENTS.md` is the cross-tool agent brief read natively by Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others, per the open standard at [agents.md](https://agents.md/) (governed by the Linux Foundation's Agentic AI Foundation). On Claude Code the equivalent is `CLAUDE.md`; many teams symlink `CLAUDE.md` -> `AGENTS.md` to avoid drift.

kickoff-ready's emit is **artifact metadata only**: it names the ready-suite artifacts produced by the kickoff and points at them. It does not contain stack, build commands, conventions, or forbidden actions. Those belong to repo-ready's scaffolding (or to the user). Mixing the two re-introduces scope leak.

## Emit conditions (recap)

1. Only if no `AGENTS.md` exists at project root. If one exists, leave it untouched, record `agents_md_emitted: existing-respected` in PROGRESS.md.
2. Only on harnesses with a file system. On chat-only frontends, surface the template as a guidance string for the user to paste.
3. Once written, kickoff-ready never re-edits this file. Subsequent kickoff resumes do not append or rewrite.

## Template

Substitutions are double-braced. Resolve from PROGRESS.md.

```markdown
# {{project_name}}

This project was kicked off via the [ready-suite](https://github.com/aihxp/ready-suite). The kickoff arc produced the artifacts listed below; consult the relevant artifact before changes that touch its area.

## Ready-suite artifact map

| Sibling | Status | Artifact |
|---|---|---|
| prd-ready | {{prd_status}} | `{{prd_artifact_path}}` |
| architecture-ready | {{arch_status}} | `{{arch_artifact_path}}` |
| roadmap-ready | {{roadmap_status}} | `{{roadmap_artifact_path}}` |
| stack-ready | {{stack_status}} | `{{stack_artifact_path}}` |
| repo-ready | {{repo_status}} | (repo-level scaffolding) |
| production-ready | {{production_status}} | `{{production_artifact_path}}` |
| deploy-ready | {{deploy_status}} | `{{deploy_artifact_path}}` |
| observe-ready | {{observe_status}} | `{{observe_artifact_path}}` |
| launch-ready | {{launch_status}} | `{{launch_artifact_path}}` |
| harden-ready | {{harden_status}} | `{{harden_artifact_path}}` |

The kickoff audit ledger lives at `.kickoff-ready/PROGRESS.md`. It records every sibling invocation, skip declaration, and verification timestamp from the kickoff arc.

## Project conventions

This file is the cross-tool agent brief; project conventions (stack, build/test commands, forbidden actions, contribution policy) belong in a separate canonical document. If repo-ready ran during kickoff, those conventions are already captured at the location repo-ready chose (typically appended to this file or in `CONTRIBUTING.md`). If repo-ready was skipped or did not run, see `CONTRIBUTING.md`, `README.md`, or run repo-ready directly to scaffold the conventions section.

## How to extend this file

Append project conventions below this line, or replace this template's body wholesale once your team has settled on the canonical agent brief. kickoff-ready will not re-edit this file. Treat it like any other repo-controlled doc: it passes through code review, it is covered by `CODEOWNERS` if you have one, and changes appear in the commit history.
```

## Substitution rules

- `{{project_name}}` - from PROGRESS.md `## Kickoff intent` block, one-line project description, stripped of quoting.
- `{{<sibling>_status}}` - one of `done`, `skipped`, `deferred`, `imported`, `failed`. Mirror the PROGRESS.md status field.
- `{{<sibling>_artifact_path}}` - from the per-sibling artifact contract in [`references/sequencing-rules.md`](sequencing-rules.md). For skipped/deferred siblings, write `(not produced)`.

## What kickoff-ready never writes into AGENTS.md

The emit is artifact metadata. The following content is forbidden in the kickoff-ready emit even if helpful in principle, because writing it re-introduces scope leak:

- **Stack details** (language, framework, runtime versions). repo-ready's job.
- **Build / test / lint commands.** repo-ready's job.
- **Forbidden actions** (don't commit to main, don't edit lockfile, etc.). repo-ready's job, derived from CONTRIBUTING.md.
- **Specialist content** (PRD excerpts, architecture decisions, launch strategy notes). The artifact files themselves are authoritative; kickoff-ready never excerpts them inline.
- **Future-work TODOs.** PROGRESS.md tracks deferred items; AGENTS.md is not a second ledger.

## Interaction with repo-ready

If the kickoff arc invokes repo-ready, both skills converge on `AGENTS.md` at project root. The handshake:

1. kickoff-ready Step 6 sub-step 6a runs after all siblings (including repo-ready, if invoked) have completed. By then, repo-ready may already have written or extended `AGENTS.md` with project conventions.
2. If `AGENTS.md` exists when sub-step 6a runs, kickoff-ready records `existing-respected` and does not write. repo-ready's AGENTS.md is authoritative.
3. If repo-ready was skipped or did not produce `AGENTS.md`, kickoff-ready emits the artifact-map-only template. The user can run repo-ready later to extend it with conventions, or extend it manually.

This separation is by design: kickoff-ready owns artifact metadata, repo-ready owns project conventions. The same file holds both, but they are written by different skills at different times.

## Cross-references

- [agents.md open standard](https://agents.md/) - the format spec and the harnesses that read it
- repo-ready's `references/onboarding-dx.md` Section 9 - per-tool deltas, anti-patterns, the canonical template for the conventions side
- [`references/handoff-protocols.md`](handoff-protocols.md) Section "AGENTS.md" - how kickoff-ready surfaces the template on chat-only harnesses
