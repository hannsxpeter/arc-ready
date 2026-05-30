# Maintaining arc-ready

Procedural guide for the arc-ready maintainer. Single-repo rituals, version-bump rules, release discipline. The eleven-skill aihxp/ready-suite required coordinated patches across twelve repos and a byte-identical SUITE.md ritual; arc-ready is one repo and the rituals collapse accordingly.

For the contributor-facing version of these conventions, see `CONTRIBUTING.md`.

## The repo

One repo, one SKILL.md, one CHANGELOG.md, one tag stream, one release stream. The eleven-skill suite's coordinated-patch rituals do not apply.

Pillars is now part of the emitted project contract for file-system projects. Release work that touches Tier 0 Pillars-compatible AGENTS.md emission, Tier 2.1 repo scaffolding, or onboarding docs must verify the Pillars loader plus `agents/context.md` and `agents/repo.md` floor files.

| File | Versioned | Notes |
|---|---|---|
| `SKILL.md` | Yes (frontmatter `version:` field) | The skill body. Lint checks `version:` matches CHANGELOG top entry. |
| `CHANGELOG.md` | Yes (top entry) | Keep a Changelog format. Top entry is checked by lint for unicode cleanliness and version-shape. |
| `README.md`, `AGENTS.md`, `CLAUDE.md` (symlink), `SECURITY.md`, `CONTRIBUTING.md`, `MAINTAINING.md`, `MIGRATION.md` | No (load-bearing surfaces; lint checks unicode cleanliness) | |
| `LICENSE` | No | MIT. |
| `scripts/lint.sh`, `scripts/dogfood-smoke.sh`, `.github/workflows/lint.yml`, `.github/CODEOWNERS`, `.gitignore` | No | Smoke test covers operational behavior including Pillars floor emission and source-backed pillar provenance. |
| `references/<tier>/*.md` | No | Inherited from source skills; faithful copies. Cross-reference updates allowed; content rewrites are not. |

## The four rituals

### Ritual 1: patch release (v0.x.y)

For bug fixes, typo corrections, broken cross-reference fixes, lint improvements that catch documented failure modes.

Steps:

```bash
cd ~/Projects/arc-ready
VERSION=1.0.1
# 1. Make the change.
# 2. Bump SKILL.md frontmatter version (e.g., 1.0.0 -> 1.0.1) and updated date.
# 3. Prepend a CHANGELOG entry. Pattern:
#       ## [$VERSION] - YYYY-MM-DD
#       <one-paragraph problem-and-fix>
#       ### Fixed
#       - bullet
#       ### Why a patch
#       <one-paragraph rationale>
# 4. Run lint:
bash scripts/lint.sh
# 5. Commit, push, tag, release:
git add -A  # or specific files
git commit -m "v$VERSION: <imperative summary>"
git push origin HEAD
git tag "v$VERSION"
git push origin "v$VERSION"
gh release create "v$VERSION" --title "v$VERSION" --notes-from-tag
```

The lint enforces the `version:` in SKILL.md matches the top CHANGELOG entry. If the CI lint fails after push, fix and ship a new patch (do not amend or force-push the tag).

### Ritual 2: minor release (v0.x.0)

For new content within the established pattern catalog (refinements, additions for new ecosystem developments, new references that supplement existing tiers).

Same steps as Ritual 1 with version bumped at the minor position (e.g., 1.0.5 -> 1.1.0). The CHANGELOG entry uses `### Added` and `### Changed` sections instead of `### Fixed`.

### Ritual 3: major release (vX.0.0)

For breaking changes to the artifact contract or the workflow shape.

A 1.0.0 release can also be used to declare the existing contract stable. In that case, it is not a breaking release, but it still needs the same evidence standard because downstream agents and orchestrators will treat the contract as durable.

Major releases require coordination:

1. Open a discussion thread (GitHub Discussions or Issues) at least 30 days before tag.
2. Update `MIGRATION.md` with the breaking-change matrix.
3. Verify the dogfood (`aihxp/ready-suite-example`) still works against the new arc-ready, or coordinate the dogfood update.
4. Notify downstream orchestrator authors (GSD, BMAD, Spec Kit, Superpowers, etc.) if the artifact paths or contracts change.
5. Tag and release per Ritual 1, with a long-form CHANGELOG entry covering the breaking changes and migration steps.

For a non-breaking 1.0.0 stabilization release, use this checklist instead of the breaking-change matrix:

1. Run `bash scripts/lint.sh --all --verbose`.
2. Run `bash scripts/dogfood-smoke.sh --verbose`; the smoke must verify resume, artifact paths, AGENTS.md respect, Pillars floor files, at least one source-backed pillar, and the critical-finding gate.
3. Run one live or synthetic user journey that covers greenfield Pillars adoption and existing-AGENTS.md blocker behavior.
4. Confirm `README.md` states the stability promise for canonical `.<tier>-ready/` artifacts and Pillars memory files.
5. Confirm `MIGRATION.md` explains that Pillars adoption is additive for projects imported from the eleven-skill suite.
6. Confirm the top CHANGELOG entry says why 1.0.0 is stable and names any remaining live-harness validation limits.

### Ritual 4: tag-release parity

Every git tag must have a matching GitHub Release. The lint includes a `tag-release-parity` check that walks `git tag` and verifies each tag has a release.

If a tag is missing a release, run:

```bash
gh release create <tag> --title "<tag>" --notes-from-tag
```

If a release is created without a tag (rare), the lint surfaces it; create the tag from the release commit.

## Lint checks

`bash scripts/lint.sh --all` runs:

| Check | What it does |
|---|---|
| `unicode-clean` | Em-dash, en-dash, arrow, box-drawing absent from load-bearing files (SKILL.md, README.md, AGENTS.md, CLAUDE.md, SECURITY.md, CONTRIBUTING.md, MAINTAINING.md, MIGRATION.md, top CHANGELOG entry). Inherited reference files are exempt. |
| `frontmatter-version` | SKILL.md `version:` field matches the top CHANGELOG entry version. |
| `skill-version-body` | Every `## Skill version:` line in the SKILL.md body matches the frontmatter `version:`. Catches stale template version strings. |
| `tag-release-parity` | Every git tag has a matching GitHub Release. Requires `gh` authenticated. Runs only in CI or when `gh` is available. |
| `compatible-with` | SKILL.md `compatible_with:` frontmatter contains the standards-level harness names (claude-code, codex, cursor, windsurf, pi, openclaw, any-agentskills-compatible-harness). antigravity is allowed but not required. |
| `references-exist` | Every reference path mentioned in SKILL.md (`references/<tier>/<file>.md`) exists in the file system. Detects broken links from SKILL.md to references. |
| `relative-links-resolve` | Every markdown link to a real reference file inside `references/` resolves from the linking file's directory. Catches cross-tier links written with the wrong relative path. |
| `tier-folders-populated` | `references/{orchestration,planning,building,shipping,shared}` each have at least one file. Detects accidental directory deletions. |

`bash scripts/lint.sh --help` lists individual checks.

## Em-dash discipline

The hub (predecessor: `aihxp/ready-suite/scripts/lint.sh`) enforced em-dash cleanliness on a defined set of "suite-authored" files. arc-ready does the same:

**Enforced**: `SKILL.md` (whole file), `README.md` (whole file), `AGENTS.md`, `CLAUDE.md` (symlink target), `SECURITY.md`, `CONTRIBUTING.md`, `MAINTAINING.md`, `MIGRATION.md`, top CHANGELOG entry only.

**Exempt**: `references/<tier>/*.md`. These are faithful copies of the source skills' references, which contain em-dashes from their original authoring. Removing them would alter the inherited content and violate the "faithful consolidation, not v2" principle.

If you edit a reference file, do not introduce new em-dashes. The existing ones are inherited; the new ones would be net-new authoring.

## Predecessor: aihxp/ready-suite

The eleven-skill suite remains available and supported. arc-ready does not deprecate it. If a critical bug affects both, fix it in arc-ready first (single-repo patch) and port to the relevant suite skill (per-skill patch).

The dogfood example (`aihxp/ready-suite-example`) is the integration test surface for both. If a change to arc-ready breaks the dogfood, the dogfood is the authority; revisit the change.

## Release announcements

Major and minor releases get a release announcement (GitHub Discussions, blog post, or Twitter/X thread). Patch releases do not, unless the patch closes a security issue (then coordinate with `SECURITY.md` disclosure).

## What this file is not

This file is **not** the equivalent of `aihxp/ready-suite/MAINTAINING.md`. The hub maintained twelve repos, a byte-identical SUITE.md ritual, the v2.5.12 precedent recovery story, and the multi-repo coordinated-patch matrix. None of that applies to arc-ready. arc-ready is one repo; the rituals are correspondingly small. If you need the multi-repo discipline (because you are scaffolding a different multi-repo collection), see `references/building/multi-repo-suite-layout.md`.
