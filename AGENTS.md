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

This is the agent brief for working on the arc-ready repository itself. Harnesses that read the `AGENTS.md` standard (Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others) load it directly, and `CLAUDE.md` is a symlink to it. It is not the Pillars loader arc-ready writes into consumer projects; `scripts/arc-check.sh pillars` generates that one.

## What this repo is

arc-ready is one Agent Skill that takes a software project from idea to launch with durable artifacts on disk and script-checked gates. Version 2 is deliberately small: `SKILL.md` is the whole default context (about 3,700 tokens), `scripts/arc-check.sh` holds the ledger, tier gates, and pre-publication gate that agents run, and `references/guided/` is an opt-in pack of skeletons for smaller models. The 1.x reference library is frozen at the `v1.2.1` tag. See `README.md` for the picture and `docs/drift-audit.md` for why 2.0 changed shape.

## Design rules

1. **Every always-loaded token earns its place.** Content stays in `SKILL.md` only if an ablation run shows it changes outcomes, or if it is something a model cannot know on its own: the artifact paths, the ledger and findings formats, the gate semantics, and the named have-nots.
2. **Enforce in code, not prose.** A rule that can be checked belongs in `scripts/arc-check.sh`, with a test in `scripts/test.sh`, rather than in a paragraph asking the model to police itself.
3. **Nothing loads by default.** `SKILL.md` names no file except the guided skeletons, and only in its guided-mode section. The lint enforces this and the byte budget.
4. **Measure before adding or cutting.** A change to `SKILL.md` or the guided pack comes with an ablation result from `evals/ablation/`, or a stated reason none is needed.
5. **Stable artifact paths.** The `.<tier>-ready/` paths and the ledger format are a contract. Changing them is a major release with a `MIGRATION.md` entry, and `arc-check.sh` keeps reading 1.x ledgers.

## Commands

- `bash scripts/test.sh --verbose` runs the behavioral tests for `arc-check.sh` against synthetic projects.
- `bash scripts/lint.sh --all --verbose` runs the repository lint, including the tests. `bash scripts/lint.sh --help` lists individual checks.
- `SKILLS_REF_BIN=<path> bash scripts/release-check.sh` runs release evidence with the pinned official validator.
- `bash evals/ablation/run.sh` runs the ablation matrix. It spends API credit; read `evals/ablation/README.md` first.
- CI runs the tests and the lint on every push and pull request.

## Forbidden actions

- Em dashes, en dashes, Unicode arrows, box-drawing characters, or emoji in any authored file. The lint enforces this everywhere except the archival `docs/research/`.
- Routing `SKILL.md` to new reference files, or growing it past the lint budget, without an ablation result that justifies it.
- Committing `.<tier>-ready/` directories as fixtures. Generate fixtures in scripts, as `scripts/test.sh` and `evals/ablation/fixtures.sh` do.
- Skipping the lint or bypassing CI. No `--no-verify` on commits.
- Bash that breaks on Bash 3.2, the macOS default: no associative arrays, `${var^^}`, or `mapfile`, and no `case` statements inside `$(...)`.

## Versioning

- **Patch:** fixes to scripts, lint, or documentation that change neither what agents are told nor what gates accept.
- **Minor:** new gate checks or `arc-check.sh` commands, or `SKILL.md` and guided-pack changes backed by evaluation.
- **Major:** changes to artifact paths, the ledger format, or the workflow shape.

`metadata.version` in `SKILL.md`, `ARC_CHECK_VERSION` in `scripts/arc-check.sh`, and the top `CHANGELOG.md` entry must agree; the lint checks it. `MAINTAINING.md` has the release steps.

## File map

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill, and the whole default context. |
| `scripts/arc-check.sh` | Runtime tool agents run: ledger, gates, pillars, prepublish, scan. |
| `references/guided/` | Opt-in skeletons for smaller models, one per tier. |
| `scripts/test.sh` | Behavioral tests for `arc-check.sh`. |
| `scripts/lint.sh` | Repository lint. |
| `scripts/release-check.sh` | Release evidence entry point. |
| `evals/ablation/` | The with-and-without-skill comparison harness. |
| `evals/results/` | Dated evaluation records. |
| `docs/drift-audit.md` | Where the 1.2.1 documentation disagreed with reality, and the fixes. |
| `docs/research/RESEARCH-2026-04.md` | Archival source citations behind the have-not names. Agents do not read it. |
| `README.md`, `EVALS.md`, `MIGRATION.md`, `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md` | Project documentation. |
| `.cursorrules` | Template for pointing Cursor at the skill. |
| `.github/` | CI workflow, templates, and code owners. |

## What to read first

1. `README.md`: what arc-ready is and the evidence behind 2.0.
2. `SKILL.md`: everything an agent is told.
3. `bash scripts/arc-check.sh --help`, then `scripts/test.sh`: what is enforced and how it is tested.
4. `EVALS.md`: how changes are measured.
