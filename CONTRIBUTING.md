# Contributing to arc-ready

arc-ready is the consolidated successor to the eleven-skill aihxp/ready-suite. The discipline of arc-ready is the discipline of the suite, preserved verbatim. Contributions that add new failure-mode patterns the source suite did not enforce will be rejected; contributions that clarify, fix, or extend the existing pattern catalog within its established shape are welcome.

Pillars is the standard agent-memory layer arc-ready emits for file-system projects. Changes that touch `AGENTS.md` emission, repo scaffolding, or ongoing-agent context must preserve that contract: canonical arc artifacts remain authoritative, and Pillars carries task-routed operating memory.

## Before you contribute

Read in this order:

1. `README.md` (5 minutes; what arc-ready is and why).
2. `SKILL.md` (15 minutes; the workflow body).
3. `MIGRATION.md` (5 minutes; the relationship to aihxp/ready-suite).
4. `MAINTAINING.md` (5 minutes; release rituals).
5. `AGENTS.md` (5 minutes; project conventions and forbidden actions).

## What is in scope

- Bug fixes (typos, broken cross-references, formatting errors).
- Lint improvements (new mechanical checks that catch documented failure modes).
- Reference updates that reflect changes in the underlying technology landscape (e.g., a deprecated tool, a new compliance framework version).
- Worked-example refinements (`EXAMPLE-PRD.md`, `EXAMPLE-ARCH.md`, etc.).
- Cross-tier consistency fixes (a have-not in tier X that would also fire in tier Y, but is not currently named in tier Y's catalog).

## What is out of scope

- New named failure-mode patterns the source suite did not enforce. arc-ready is faithful consolidation, not v2.
- Workflow restructures that change the artifact contract (the canonical `.<tier>-ready/<ARTIFACT>.md` paths). Downstream consumers depend on these paths.
- A non-Pillars variant of the emitted project memory layer. Pillars is the default standard; exceptions are recorded blockers, not a separate distribution.
- Deletion or merging of references that have load-on-demand value. Eighty references at ~5-15K each are correct.
- Em-dashes, en-dashes, arrows, or box-drawing characters in load-bearing files (lint enforces).
- Emojis anywhere (lint enforces).

## How to contribute

1. Fork the repository on GitHub.
2. Create a branch with a descriptive name: `fix/typo-in-prd-anatomy`, `lint/add-frontmatter-check`, `docs/update-stack-bundles-2026-Q3`.
3. Make the change.
4. Run the lint locally: `bash scripts/lint.sh`. Fix any failures.
5. Update `CHANGELOG.md` with a top entry. Use the format from existing entries.
6. Bump the `version:` field in `SKILL.md` frontmatter to match the new CHANGELOG entry.
7. Commit with a message following the pattern `<scope>: <imperative summary>`. Examples: `lint: add unicode check for AGENTS.md`, `references/planning: fix cross-reference to risks-and-assumptions`.
8. Push the branch to your fork.
9. Open a pull request. The PR template (see `.github/pull_request_template.md` if present) lists the checks; cover them in the description.

## Documentation changes

Documentation is load-bearing in this repo. Before merging a docs-only change, check whether it touches one of the public contracts:

- Artifact paths in `.<tier>-ready/`.
- Pillars adoption rules for `AGENTS.md` and `agents/*.md`.
- Tier gates, have-nots, or grep tests.
- Release rituals or versioning policy.

If it touches any of those, update `CHANGELOG.md`, run `bash scripts/lint.sh --all`, and run `bash scripts/dogfood-smoke.sh --verbose`. If it changes Pillars wording, make sure the docs still say one thing: arc artifacts are authoritative, Pillars is the project-memory layer, and blockers are recorded instead of creating a non-Pillars variant.

## Versioning

arc-ready follows semantic versioning:

- **Patch** (v0.x.y): bug fixes, typo corrections, cross-reference fixes, lint improvements.
- **Minor** (v0.x.0): new content within the established pattern catalog (refinements, additions of references for new ecosystem developments).
- **Major** (vX.0.0): breaking changes to the artifact contract or the workflow shape. Coordinate with downstream consumers and the dogfood example.

See `MAINTAINING.md` for the release rituals.

## Code style

- Markdown only (plus the Bash lint script).
- ASCII hyphen `-` for ranges and compounds; never em-dash or en-dash.
- ASCII arrow `->` instead of unicode arrows.
- No emojis. Use icons in any UI surface (this repo has none, so this rule applies to documentation snippets only).
- Lists use `-` for unordered, `1.` for ordered.
- Tables use Markdown pipe syntax.
- Headings use `#` to `######`. No setext (underlined) headings.
- Code blocks use triple backticks with a language tag (`bash`, `markdown`, etc.).

## Reporting bugs

Use GitHub Issues. Include:

- arc-ready version (`grep '^version:' SKILL.md`).
- The harness you are running (Claude Code, Codex, Cursor, etc.).
- The mode (A/B/C/D) you were in.
- Reproduction steps.
- Expected vs. actual behavior.

For security issues, see `SECURITY.md`.

## Reporting taxonomy

The named failure modes in the have-nots catalog are the load-bearing taxonomy. If you encounter a behavior that feels like a failure but does not map to a named mode, file an issue with the label `taxonomy-question`. The maintainer will either point you at the existing mode or, in rare cases, refine the catalog. Net-new pattern names require strong evidence that the behavior is distinct from every existing pattern.

## License

By contributing, you agree that your contributions will be licensed under the project's MIT license (see `LICENSE`).
