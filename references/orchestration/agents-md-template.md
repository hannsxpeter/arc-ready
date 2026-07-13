# `AGENTS.md` template emitted by arc-ready

Loaded at SKILL.md Step 0.6 and Step 2.1. The template arc-ready writes to project root when no `AGENTS.md` exists.

## What this file is for

`AGENTS.md` is the cross-tool agent brief read by Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others, per the open standard at [agents.md](https://agents.md/). On Claude Code the equivalent is `CLAUDE.md`; many teams symlink `CLAUDE.md` to `AGENTS.md` to avoid drift.

arc-ready emits a Pillars-compatible `AGENTS.md` by default for file-system projects. Pillars owns durable, task-routed agent memory in `agents/*.md`. arc-ready owns the canonical arc artifacts in `.<tier>-ready/`. The relationship is:

- `AGENTS.md` tells agents how to load Pillars and where arc-ready artifacts live.
- `agents/*.md` distill stable operating memory for future coding tasks.
- `.<tier>-ready/*.md` remain the source of truth for arc decisions.

## Emit conditions

1. If no `AGENTS.md` exists, write the Pillars-compatible template below.
2. If `AGENTS.md` exists and is already Pillars-compatible, preserve it and add only missing arc-ready artifact-map context if the file has an obvious place for it.
3. If `AGENTS.md` exists and conflicts with the Pillars loader, leave it untouched and record `pillars: adoption-blocked-existing-agents` in `.arc-ready/PROGRESS.md`.
4. On chat-only frontends with no file system, surface the template as guidance text for the user to paste.

## Template

Substitutions are double-braced. Resolve from PROGRESS.md and the artifact paths on disk.

````markdown
# {{project_name}}

This project follows the [Pillars](https://github.com/hannsxpeter/pillars) standard. Coding agents working in this repository read the pillar files in `./agents/*.md` to stay aligned with the project's facts, decisions, and conventions.

## At the start of any task

1. Load every file in `./agents/` recursively whose frontmatter has `always_load: true`.
2. Scan frontmatter in the remaining pillar files.
3. Identify primary pillars whose `triggers` or `covers` match the current task.
4. Load the primaries and every pillar listed in their `must_read_with`, depth 1 only.
5. Consult `see_also` only if the task explicitly touches that area.
6. Follow `Rules`, apply `Workflows`, heed `Watchouts`, and ask about `Gaps`.

## Handling missing pillars

| State | Action |
|---|---|
| `status: present` | Load and comply. |
| `status: stub` | Ask before making decisions in this area. |
| Name in `excluded:` | Treat as intentionally not applicable. |
| Trigger matches a known absent pillar | Infer from code, state the assumption, and recommend creating the pillar. |

If `context.md` or `repo.md` is missing, pause and ask the human to create stubs or declare an explicit project exception.

## Excluded pillars

```yaml
excluded: []
```

## arc-ready artifacts

This project was shaped via [arc-ready](https://github.com/hannsxpeter/arc-ready). For source-of-truth planning, build, ship, and hardening decisions, consult the artifacts below before changing the related area.

| Tier | Status | Artifact |
|---|---|---|
| 1.1 PRD | {{prd_status}} | `{{prd_artifact_path}}` |
| 1.2 Architecture | {{arch_status}} | `{{arch_artifact_path}}` |
| 1.3 Roadmap | {{roadmap_status}} | `{{roadmap_artifact_path}}` |
| 1.4 Stack | {{stack_status}} | `{{stack_artifact_path}}` |
| 2.1 Repo | {{repo_status}} | (repo-level scaffolding) |
| 2.2 Production | {{production_status}} | `{{production_artifact_path}}` |
| 3.1 Deploy | {{deploy_status}} | `{{deploy_artifact_path}}` |
| 3.2 Observe | {{observe_status}} | `{{observe_artifact_path}}` |
| 3.3 Launch | {{launch_status}} | `{{launch_artifact_path}}` |
| 3.4 Harden | {{harden_status}} | `{{harden_artifact_path}}` |

The arc audit ledger lives at `.arc-ready/PROGRESS.md`. It records tier invocation, skip declarations, Pillars adoption status, and verification timestamps.
````

## Required companion files

The AGENTS.md emit is incomplete unless `agents/context.md` and `agents/repo.md` exist. If the source artifacts are not mature enough to fill them, emit stubs:

```markdown
---
pillar: context
status: stub
always_load: true
covers: [project identity, domain language, product invariants, glossary]
triggers: []
must_read_with: []
see_also: [repo]
---

## Scope

(stub) Fill in project identity, domain language, product invariants, and glossary.

## Context

(stub)

## Decisions

(none)

## Rules

(none)

## Workflows

(none)

## Watchouts

(none)

## Touchpoints

- `see_also: [repo]`

## Gaps

- This pillar is a stub. Ask before inventing project identity, domain vocabulary, or product invariants.
```

```markdown
---
pillar: repo
status: stub
always_load: true
covers: [file layout, naming conventions, where things go, repository structure]
triggers: []
must_read_with: []
see_also: [context]
---

## Scope

(stub) Fill in file layout, naming conventions, and structural decisions.

## Context

(stub)

## Decisions

(none)

## Rules

(none)

## Workflows

(none)

## Watchouts

(none)

## Touchpoints

- `see_also: [context]`

## Gaps

- This pillar is a stub. Ask before inventing folder layout, naming patterns, or where tests, configs, and docs live.
```

## Substitution rules

- `{{project_name}}` - from PROGRESS.md `## Kickoff intent` block, one-line project description, stripped of quoting.
- `{{<tier>_status}}` - one of `done`, `skipped`, `deferred`, `imported`, `failed`. Mirror the PROGRESS.md status field.
- `{{<tier>_artifact_path}}` - from the per-tier artifact contract in [`references/orchestration/sequencing-rules.md`](sequencing-rules.md). For skipped or deferred tiers, write `(not produced)`.

## What arc-ready does not put in AGENTS.md

The AGENTS.md file is a loader and map, not a substitute for artifacts or Pillars.

- Do not paste PRD, architecture, roadmap, launch, or hardening content into AGENTS.md.
- Do not duplicate detailed stack rules if `agents/stack.md` exists.
- Do not duplicate detailed repo rules if `agents/repo.md` exists.
- Do not use AGENTS.md as a future-work TODO list. PROGRESS.md tracks deferred arc items; a phase orchestrator tracks ongoing work.

## Interaction with Tier 2.1

Tier 0 may emit the loader and mandatory stubs. Tier 2.1 enriches the memory layer:

1. It verifies `AGENTS.md` is Pillars-compatible.
2. It fills or creates `agents/context.md` and `agents/repo.md`.
3. It adds source-backed pillars such as `stack.md`, `arch.md`, `quality.md`, `deploy.md`, and `observe.md` when the source artifacts exist.
4. It records Pillars adoption status in `.arc-ready/PROGRESS.md`.

## Cross-references

- [Pillars standard](https://github.com/hannsxpeter/pillars) - task-routed agent memory standard
- [agents.md open standard](https://agents.md/) - the AGENTS.md ecosystem standard
- `references/building/pillars-integration.md` - required memory-layer mapping from arc-ready artifacts to Pillars
- `references/building/onboarding-dx.md` Section 9 - per-tool deltas and conventions
- [`references/orchestration/handoff-protocols.md`](handoff-protocols.md) Section "AGENTS.md" - chat-only harness behavior
