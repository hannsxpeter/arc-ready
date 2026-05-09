# arc-ready (project agent brief)

This file is the cross-tool agent brief for the arc-ready repository itself. It is consumed by any harness that respects the Linux Foundation Agentic AI Foundation `AGENTS.md` standard (Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others).

This is **not** the AGENTS.md template arc-ready emits to consumer projects; that template lives at `references/orchestration/agents-md-template.md` and is parameterized by project state. This file describes how to work on arc-ready itself.

## What this repo is

arc-ready is a single AI skill that takes a software project from idea through launch. It is the consolidated successor to the eleven-skill aihxp/ready-suite. See `README.md` for the full picture and `SKILL.md` for the workflow body.

## Project conventions

### Stack

This is a documentation-only repository. The only "code" is `scripts/lint.sh` (Bash 3.2 compatible) and the GitHub Actions workflow at `.github/workflows/lint.yml`.

### Commands

- `bash scripts/lint.sh` runs the meta-linter. Equivalent: `bash scripts/lint.sh --all`.
- `bash scripts/lint.sh --verbose` for verbose output.
- `bash scripts/lint.sh --help` for individual checks.
- CI runs `lint.sh` on every push and PR.

### Forbidden actions

- **Em-dashes, en-dashes, arrows, box-drawing characters in load-bearing files** (SKILL.md, README.md, top CHANGELOG entry, MAINTAINING.md, MIGRATION.md, AGENTS.md, CONTRIBUTING.md, SECURITY.md). The lint enforces this. Use ASCII hyphen and `->` arrow form. Reference files inherited from the source ready-suite skills may contain em-dashes from their original authoring; do not introduce new ones in those files when editing.
- **Emojis anywhere.** No emoji characters in any markdown, code, or commit message. Use words, plain ASCII markers (`-`, `*`, `[x]`, `[ ]`), or proper icons in any UI surface.
- **Adding new failure-mode patterns the source ready-suite did not enforce.** arc-ready is faithful consolidation, not v2. New patterns dilute the moat the eleven-skill version produced.
- **Collapsing references that have load-on-demand value.** Eighty references at ~5-15K each are correct; thirty references at ~25K each blow the agent attention budget.
- **Skipping the lint or bypassing CI.** No `--no-verify` on commits.
- **Editing `references/<tier>/*.md` to "improve" content lifted from source skills.** Faithful copies. Cross-reference updates are allowed; content rewrites are not.

### Contribution policy

- Patch releases (v0.1.x) for bug fixes, typo corrections, cross-reference fixes.
- Minor releases (v0.x.0) for new content (new patterns, new sub-steps).
- Major releases (vX.0.0) for breaking changes to the artifact contract or the workflow shape. Coordinate with downstream consumers (orchestrators, the dogfood example).

See `MAINTAINING.md` for the release rituals.

### Cross-references

- `references/<tier>/foo.md` files use **relative paths** to other references: same-tier as `bar.md`, cross-tier as `../<other-tier>/bar.md`.
- `SKILL.md` references use the full path from repo root: `references/<tier>/foo.md`.
- Artifact paths (`.prd-ready/PRD.md`, etc.) are stable; do not rewrite these into arc-ready paths. They are the contract with downstream consumers.

## Standards alignment

- **agentskills.io**: SKILL.md frontmatter format, references/ lazy-load pattern.
- **agents.md (Linux Foundation Agentic AI Foundation)**: this file at project root; emit `AGENTS.md` to consumer projects per Tier 0 Step 0.6.
- **Google Labs DESIGN.md**: detect and consume DESIGN.md in the building tier UI work per Tier 2.2 sub-step 3.

## File map

| File | Purpose |
|---|---|
| `SKILL.md` | The orchestrator body. The skill an agent loads. |
| `README.md` | Public-facing project description. |
| `AGENTS.md` | This file: how to work on arc-ready. |
| `CLAUDE.md` | Symlink to `AGENTS.md`; Claude Code overlay. |
| `CHANGELOG.md` | Version history. Top entry is checked by lint. |
| `LICENSE` | MIT license text. |
| `SECURITY.md` | Vulnerability reporting channel. |
| `CONTRIBUTING.md` | Contribution guide. |
| `MAINTAINING.md` | Single-repo release rituals (patch / minor / major). |
| `MIGRATION.md` | Guide for ready-suite users switching to arc-ready. |
| `scripts/lint.sh` | The meta-linter. |
| `.github/workflows/lint.yml` | CI workflow that runs the lint. |
| `.github/CODEOWNERS` | Code ownership. |
| `references/orchestration/` | Tier 0 references. |
| `references/planning/` | Tier 1 references (PRD, ARCH, ROADMAP, STACK). |
| `references/building/` | Tier 2 references (REPO, PRODUCTION). |
| `references/shipping/` | Tier 3 references (DEPLOY, OBSERVE, LAUNCH, HARDEN). |
| `references/shared/` | Cross-tier references (RESEARCH, ORCHESTRATORS). |

## What to read first

A new contributor or agent working on arc-ready should read in this order:

1. `README.md` (5 minutes; what arc-ready is and why it exists).
2. `SKILL.md` (15 minutes; the workflow body and tier dispatch).
3. `MIGRATION.md` (5 minutes; the relationship to aihxp/ready-suite).
4. `MAINTAINING.md` (5 minutes; release rituals).
5. `references/<relevant-tier>/<file>.md` (load on demand for the work at hand).

Total cold-start time: about 30 minutes for the orchestrator surface, plus per-tier deep dives as needed.
