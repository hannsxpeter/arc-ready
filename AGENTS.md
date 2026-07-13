# Global writing rules

## Never use em dashes or en dashes

Do not use the em dash character (U+2014) or en dash character (U+2013) in any output. This applies everywhere: chat responses, code comments, commit messages, docs, markdown files, PR descriptions, generated text, and any file you write or edit. Do not introduce them into files that don't already have them. When editing existing files that contain them, do not add new ones.

Use these alternatives instead:
- Comma, colon, or semicolon for a pause or aside
- Parentheses for a parenthetical
- Two separate sentences when the break is strong
- Hyphen (`-`) for compound words and number ranges (e.g., write `pages 10-15` and never use the en dash character)

This rule is absolute. It applies regardless of project, language, or file type.

## Never use emojis

Do not use emojis in any output. This applies everywhere: chat responses, code, comments, commit messages, docs, markdown files, PR descriptions, generated text, and any file you write or edit. Covers all emoji characters (faces, symbols, objects, flags, hands, hearts, checkmarks/crosses used decoratively, etc.) across all Unicode emoji blocks. Do not introduce them into files that don't already use emojis; when editing existing files that contain them, do not add new ones.

Exceptions (narrow):
- If the user explicitly asks for emojis in the current request, you may use them for that request only.
- If the file being edited already uses emojis as a structural convention and the user wants consistency, match the existing pattern rather than introducing new ones.

Default stance: no emojis. Use words, punctuation, or plain ASCII markers (`-`, `*`, `[x]`, `[ ]`) instead.

**When a visual marker is genuinely needed (UI components, status indicators, buttons, nav items, toasts, etc.), use proper icons, not emojis.** Prefer a real icon library already present in the project (Lucide, Heroicons, Material Icons, Phosphor, Font Awesome, Radix Icons, Tabler, etc.) or an inline SVG. If no icon library is installed and one is warranted, suggest adding one rather than falling back to emojis. This applies to frontend code especially, but also anywhere a graphic symbol is appropriate.

--- project-doc ---

# arc-ready (project agent brief)

This file is the cross-tool agent brief for the arc-ready repository itself. It is consumed by any harness that respects the Linux Foundation Agentic AI Foundation `AGENTS.md` standard (Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others).

This is **not** the Pillars-compatible AGENTS.md template arc-ready emits to consumer projects; that template lives at `references/orchestration/agents-md-template.md` and is parameterized by project state. This file describes how to work on arc-ready itself.

## What this repo is

arc-ready is a single AI skill that takes a software project from idea through launch, then emits Pillars agent memory for future coding work. It is the consolidated successor to the eleven-skill hannsxpeter/ready-suite. See `README.md` for the full picture and `SKILL.md` for the workflow body.

## Project conventions

### Stack

This is a documentation-first repository. Its executable surfaces are Bash 3.2-compatible lint, smoke, evaluation, baseline, and release scripts plus the GitHub Actions workflow at `.github/workflows/lint.yml`.

### Commands

- `bash scripts/lint.sh` runs the meta-linter. Equivalent: `bash scripts/lint.sh --all`.
- `bash scripts/lint.sh --verbose` for verbose output.
- `bash scripts/dogfood-smoke.sh --verbose` runs the operational smoke suite, including Pillars floor and source-backed pillar checks.
- `bash scripts/eval.sh --verbose` runs the 14 deterministic behavioral evaluations.
- `SKILLS_REF_BIN=<path> bash scripts/release-check.sh` runs release-grade validation with the pinned official validator.
- `bash scripts/lint.sh --help` for individual checks.
- CI runs `lint.sh` on every push and PR.

### Forbidden actions

- **Em-dashes, en-dashes, arrows, box-drawing characters in load-bearing files** (SKILL.md, README.md, top CHANGELOG entry, MAINTAINING.md, MIGRATION.md, AGENTS.md, CONTRIBUTING.md, SECURITY.md). The lint enforces this. Use ASCII hyphen and `->` arrow form. Reference files inherited from the source ready-suite skills may contain em-dashes from their original authoring; do not introduce new ones in those files when editing.
- **Emojis anywhere.** No emoji characters in any markdown, code, or commit message. Use words, plain ASCII markers (`-`, `*`, `[x]`, `[ ]`), or proper icons in any UI surface.
- **Adding new failure-mode patterns the source ready-suite did not enforce.** arc-ready is faithful consolidation, not v2. New patterns dilute the moat the eleven-skill version produced.
- **Collapsing references that have load-on-demand value.** The catalog is currently 220 focused files. The former large domain catalog has been split into a compact router plus 37 profiles under `references/building/domains/`. Preserve this progressive-disclosure shape.
- **Skipping the lint or bypassing CI.** No `--no-verify` on commits.
- **Editing `references/<tier>/*.md` to "improve" content lifted from source skills.** Faithful copies. Cross-reference updates are allowed; content rewrites are not.

### Contribution policy

- Patch releases (v0.x.y) for bug fixes, typo corrections, cross-reference fixes.
- Minor releases (v0.x.0) for new content (new patterns, new sub-steps).
- Major releases (vX.0.0) for breaking changes to the artifact contract or the workflow shape. Coordinate with downstream consumers (orchestrators, the dogfood example).

See `MAINTAINING.md` for the release rituals.

### Cross-references

- `references/<tier>/foo.md` files cite sibling references two ways, both lint-guarded. Clickable `[text](relative.md)` markdown links must resolve from the linking file's own directory (checked by `relative-links-resolve`). Inline-code and prose citations use the tier-agnostic form `references/<basename>.md`: reference basenames are globally unique, so the tier qualifier is omitted and a reference can move tiers without breaking citations, and the basename must name a real reference (checked by `reference-citations`). The `references/<basename>.md` form is the dominant in-repo convention (~200 citations); do not mass-rewrite it into per-file relative paths.
- `SKILL.md` references use the full path from repo root: `references/<tier>/foo.md`.
- Artifact paths (`.prd-ready/PRD.md`, etc.) are stable; do not rewrite these into arc-ready paths. They are the contract with downstream consumers.

## Standards alignment

- **agentskills.io**: SKILL.md frontmatter format, references/ lazy-load pattern.
- **agents.md (Linux Foundation Agentic AI Foundation)**: this file at project root; emit `AGENTS.md` to consumer projects per Tier 0 Step 0.6.
- **Pillars**: consumer projects get a Pillars-compatible `AGENTS.md` plus `agents/*.md` memory files in Tier 2.1. arc-ready itself is not currently organized as a Pillars consumer repo.
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
| `scripts/eval.sh` | Deterministic behavioral evaluations. |
| `scripts/dogfood-smoke.sh` | Operational synthetic-project smoke suite. |
| `scripts/release-check.sh` | Release-grade evidence entry point. |
| `EVALS.md`, `evals/cases/` | Evaluation policy, prompts, invariants, and rubrics. |
| `.github/workflows/lint.yml` | CI workflow that runs the lint. |
| `.github/CODEOWNERS` | Code ownership. |
| `references/orchestration/` | Tier 0 references. |
| `references/planning/` | Tier 1 references (PRD, ARCH, ROADMAP, STACK). |
| `references/building/` | Tier 2 references (REPO, PRODUCTION). |
| `references/building/product-form-router.md` | Form-specific concerns and build gates. |
| `references/building/domain-registry.md` | Four-axis composition and stack-profile mapping. |
| `references/building/domains/` | Focused product and industry profiles. |
| `references/building/pillars-integration.md` | Required Pillars memory-layer mapping for consumer projects. |
| `references/shipping/` | Tier 3 references (DEPLOY, OBSERVE, LAUNCH, HARDEN). |
| `references/shared/` | Cross-tier references (RESEARCH, ORCHESTRATORS). |

## What to read first

A new contributor or agent working on arc-ready should read in this order:

1. `README.md` (5 minutes; what arc-ready is and why it exists).
2. `SKILL.md` (15 minutes; the workflow body and tier dispatch).
3. `MIGRATION.md` (5 minutes; the relationship to hannsxpeter/ready-suite).
4. `MAINTAINING.md` (5 minutes; release rituals).
5. `references/<relevant-tier>/<file>.md` (load on demand for the work at hand).

Total cold-start time: about 30 minutes for the orchestrator surface, plus per-tier deep dives as needed.
