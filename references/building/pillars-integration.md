# Pillars memory layer for arc-ready

This reference defines the required bridge between arc-ready artifacts and the [Pillars](https://github.com/aihxp/pillars) standard for file-system projects.

Pillars is project memory for coding agents: a project-root `AGENTS.md` describes how to load task-routed files under `agents/*.md`. arc-ready is the artifact pipeline: PRD, architecture, roadmap, stack, repo, production, deploy, observe, launch, and harden. The memory layer distills stable decisions from arc-ready artifacts into Pillars so future implementation work loads the right facts without rereading every artifact on every task.

## When to use this layer

Use this layer in Tier 2.1 for every project where arc-ready can write files.

This includes greenfield Mode A projects, existing-codebase Mode B projects where Tier 2.1 is scaffolding or repairing repo conventions, and Mode D suite layouts. Mode C audit-only work should report whether Pillars is present and drift-free, but should not write files unless the user asks for remediation.

The only non-adoption cases are:

- The harness has no file system. Surface the recommended files as guidance text.
- An existing user-authored `AGENTS.md` conflicts with the Pillars loader and the user has not approved an edit. Respect the file and record `pillars: adoption-blocked-existing-agents`.
- The user explicitly instructs arc-ready not to write agent-memory files. Record the explicit opt-out in `.arc-ready/PROGRESS.md`.

## Non-goals

Pillars does not replace arc-ready artifacts. Do not rewrite `.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, `.roadmap-ready/ROADMAP.md`, or any other canonical artifact into the Pillars 8-section template.

Pillars is a downstream memory layer. The arc-ready artifact remains authoritative; the Pillar points back to it when a decision needs richer context.

## Emit rules

1. Respect existing files. If `AGENTS.md` exists and is not already Pillars-compatible, do not overwrite it. Record `pillars: adoption-blocked-existing-agents` in `.arc-ready/PROGRESS.md` and tell the user the project is not yet Pillars-conformant.
2. If `AGENTS.md` is absent, write the Pillars-compatible loader protocol, then include a short arc-ready artifact map or link to `.arc-ready/PROGRESS.md`.
3. Create `agents/` only if absent. If it exists, add only missing files and preserve user-authored content.
4. Mark generated files as `status: stub` unless arc-ready has enough artifact evidence to populate meaningful Context and Decisions sections.
5. Every non-obvious statement in a generated Pillar must cite its source artifact by path.

## Suggested mapping

| Pillar | Source | When to emit |
|---|---|---|
| `agents/context.md` | `.prd-ready/PRD.md` | Always when adopting Pillars. |
| `agents/repo.md` | Tier 2.1 repo scaffold and README | Always when adopting Pillars. |
| `agents/stack.md` | `.stack-ready/STACK.md` | When stack-ready ran or stack was detected. |
| `agents/arch.md` | `.architecture-ready/ARCH.md` and HANDOFF | When architecture-ready ran. |
| `agents/quality.md` | CI, lint, test, formatter config | When Tier 2.1 configures quality tooling. |
| `agents/deploy.md` | `.deploy-ready/STATE.md` or deploy workflow files | When deploy-ready ran or deploy workflows exist. |
| `agents/observe.md` | `.observe-ready/STATE.md` | When observe-ready ran. |
| `agents/security.md` | `.harden-ready/FINDINGS.md`, SECURITY.md, security setup | When harden-ready ran or security setup is material. |
| `agents/ui.md` | DESIGN.md, UI references, production surfaces | When the project has a visual UI. |
| `agents/data.md` | data architecture, schema, migrations | When data storage exists. |
| `agents/auth.md` | auth and RBAC implementation | When user identity or permissions exist. |

The first pass should prefer fewer, higher-signal files. `context.md` and `repo.md` are mandatory. `stack.md`, `arch.md`, and `quality.md` are next when their source artifacts or repo evidence exist.

## Pillar body guidance

Use the Pillars 8-section body:

1. Scope
2. Context
3. Decisions
4. Rules
5. Workflows
6. Watchouts
7. Touchpoints
8. Gaps

Populate Context from visible facts and artifact-backed commitments. Populate Decisions only when the arc-ready artifact records rationale. Populate Rules sparingly, only for constraints that an agent could not infer from code and docs. Use Gaps for undecided items instead of inventing rationale.

## AGENTS.md shape

`AGENTS.md` should lead with the Pillars loading protocol. Add a short arc-ready section after the protocol:

```markdown
## arc-ready artifacts

This project was shaped via arc-ready. For source-of-truth planning and launch decisions, consult:

| Tier | Artifact |
|---|---|
| PRD | `.prd-ready/PRD.md` |
| Architecture | `.architecture-ready/ARCH.md` |
| Roadmap | `.roadmap-ready/ROADMAP.md` |
| Stack | `.stack-ready/STACK.md` |
| Progress ledger | `.arc-ready/PROGRESS.md` |
```

If the project uses `CLAUDE.md`, symlink it to `AGENTS.md` or make it a thin tool-specific overlay that points at `AGENTS.md`.

## Verification

After emitting the memory layer:

```bash
test -f AGENTS.md || echo "[fail] AGENTS.md missing"
test -d agents || echo "[fail] agents directory missing"
test -f agents/context.md || echo "[fail] context pillar missing"
test -f agents/repo.md || echo "[fail] repo pillar missing"
grep -q "Pillars" AGENTS.md || echo "[fail] AGENTS.md does not describe Pillars loading"
grep -q ".arc-ready/PROGRESS.md" AGENTS.md || echo "[fail] AGENTS.md does not point to arc-ready ledger"
```

If generated Pillars claim to be `status: present`, spot-check that each non-obvious Context or Decision claim has an artifact source path. If not, downgrade to `status: stub` and move the claim to Gaps.
