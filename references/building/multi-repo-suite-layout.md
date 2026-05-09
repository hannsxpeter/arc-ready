# Multi-repo suite layout

Loaded when SKILL.md Step 0 routes to **Mode D (Multi-repo suite)**: the user is building or maintaining a coordinated collection of repos that ship together (a skill suite, a multi-package library, a meta-framework with separate plugin repos, an organization's reference implementations across N services that follow a shared pattern).

This file documents the canonical multi-repo-suite layout pattern: the discipline above per-repo hygiene that keeps an N-repo collection coherent. Single-repo work uses Modes A / B / C. Mode D is for the layer above.

The pattern is generalized from the [aihxp/ready-suite](https://github.com/aihxp/ready-suite) suite (12 repos: 11 specialist skills + 1 hub). The pattern applies to any multi-repo collection where: (a) the repos ship together as a logical unit, (b) at least one cross-repo invariant exists (a file that must be byte-identical, a version table that must agree, a release ritual that must propagate), and (c) the maintainer wants the discipline mechanically enforced rather than documented-and-hoped-for.

## When Mode D applies

Mode D is the right mode when at least three of these are true:

1. The project ships across multiple git repositories under one GitHub org or user.
2. At least one file lives in N repos and must be byte-identical (the canonical map / table-of-contents file; the suite's `SUITE.md` is one example).
3. There is a cross-repo version table or coordination ledger that has to agree.
4. Release rituals propagate (releasing one repo triggers a sync to N siblings).
5. There is a hub repo (discovery, install scripts, marketplace manifest, governance docs) that differs structurally from the per-unit specialist repos.
6. The collection has its own meta-discipline (lint that runs across N repos; CI that clones siblings; coordinated patches that touch multiple repos in the same logical change).

Mode D is the wrong mode when:

- The repos are independent and just happen to be under one org (not a suite, just an account).
- "Multi-repo" means a monorepo with subdirectories (use Modes A/B/C with monorepo patterns from `references/monorepo-patterns.md`).
- There is no cross-repo invariant (every repo's content is independent).

## The canonical multi-repo-suite layout

A Mode D collection has two repo classes: **hub** (one) and **specialists** (N). They share some structure and diverge on others.

### Top-level structure shared by every specialist repo

| File | Purpose | Required |
|---|---|---|
| `<UNIT>.md` | The unit's content (e.g., `SKILL.md` for a skill, `LICENSE.md` for a license repo, the unit's primary manifest). | Yes |
| `CHANGELOG.md` | Per-unit version history. Top entry's version matches the unit's frontmatter / manifest version. | Yes |
| `<COLLECTION-MAP>.md` | The byte-identical-across-N-repos map of the collection. (`SUITE.md` in ready-suite.) | Yes |
| `README.md` | Per-unit landing page: what is this, when to use, install, link to the collection map. | Yes |
| `LICENSE` | Open-source license text with real year and real author (no template variables). | Yes |
| `SECURITY.md` | Private vulnerability disclosure with severity-tied response SLAs. | Yes |
| `CONTRIBUTING.md` | Thin pointer to the hub's canonical contributor guide. No content duplication. | Yes |
| `.gitignore` | Minimal: OS / editor / install-backup / personal-local-config ignores. | Yes |
| `.github/CODEOWNERS` | Default catch-all rule + path-specific rules for high-blast-radius files. | Yes |
| `references/` (or per-unit-equivalent) | Unit-specific reference library. | Optional |

### Top-level structure unique to the hub

| File / directory | Purpose |
|---|---|
| `<COLLECTION-MAP>.md` | Source of truth for the byte-identical map. The N specialists mirror this exactly. |
| `README.md` | Discovery hub for the whole collection. |
| `MAINTAINING.md` | Maintainer-facing rituals: SUITE.md sync, version-bump rules, tag-release parity, the five rituals. |
| `CONTRIBUTING.md` | Canonical contributor guide. Per-unit `CONTRIBUTING.md` files point here. |
| `CHANGELOG.md` | Hub-level change history. Curated narrative; entries dated, not versioned (the hub typically does not version itself). |
| `LICENSE` | Open-source license. |
| `SECURITY.md` | Cross-collection disclosure policy. |
| `install.sh`, `uninstall.sh` | One-command consumer install / uninstall (if applicable). Bash 3.2 compatible if cross-platform. |
| `scripts/lint.sh` (or equivalent) | The meta-linter: mechanically enforces every cross-repo invariant. |
| `.github/workflows/lint.yml` | CI runs the meta-linter on push, on PR, and on a daily schedule. |
| `.github/CODEOWNERS` | Path-specific rules for high-blast-radius hub files (collection map, install scripts, lint, marketplace manifest). |
| `references/TRIGGER-DISAMBIGUATION.md` (or per-collection equivalent) | Disambiguation table for ambiguous user-phrasing across units, if applicable. |
| Marketplace manifest (e.g., `.claude-plugin/marketplace.json`) | Package-manager bundling for the collection (if applicable). |

### What does NOT belong in a unit repo

- Personal Claude Code overrides (`.claude/settings.local.json`). The `.local` suffix is the canonical "do not commit" marker.
- IDE-private files (`.vscode/`, `.idea/`).
- Development planning artifacts (`.planning/`, GSD scaffolds, etc.) unless explicitly intentional as a transparency trail.
- Secrets in any form (`.env`, `*.pem`, `*.key`, hardcoded API keys).
- Build artifacts (`dist/`, `node_modules/`, `target/`, `.next/`, `__pycache__/`).
- Backup directories from install scripts (`*.backup-<timestamp>/`).

## The cross-repo invariants (what the meta-linter enforces)

Every Mode D collection has invariants that must hold across all N repos. The meta-linter (`scripts/lint.sh` in the hub) enforces them. Default checks for any Mode D collection:

### 1. Byte-identical collection map

The collection map (`SUITE.md` in ready-suite, or whatever the project calls it) is byte-identical across the hub and every specialist. Changes land at the hub and copy verbatim to N siblings in the same coordinated patch.

**Lint check shape:**
```
for repo in $REPOS; do
  cmp -s "$repo/<COLLECTION-MAP>.md" "$HUB/<COLLECTION-MAP>.md" || fail "$repo differs"
done
```

### 2. Version-frontmatter matches CHANGELOG top entry

For every unit, the unit's frontmatter version (in `<UNIT>.md` or its manifest) matches the top `## v<X.Y.Z>` entry in its `CHANGELOG.md`. A unit shipped with mismatched version + CHANGELOG is incoherent.

### 3. Tag-release parity

Every git tag in every unit repo has a matching GitHub Release (or platform-equivalent) with non-empty notes. Tags without releases produce silent ship-no-notes.

### 4. Convention-conforming files

Every cross-collection convention (no em-dashes / no arrows / no banned-phrase-X / etc.) is mechanically enforced on the load-bearing files: the collection map, the hub README, hub install scripts, and the top CHANGELOG entry per unit. Pre-existing instances in older content can be allowlisted; no new instances may be introduced.

### 5. Compatibility frontmatter consistency

If units declare a `compatible_with` (or equivalent) field, every unit's set must include the same standards-level minimum values. Drift on this field signals coordination failure.

### 6. Cross-unit naming-collision detection (advisory)

If units have triggers / scope words / naming conventions that could collide across units (e.g., one unit's trigger phrase appears as a substring of another's), surface as advisory warnings. Each collision either (a) gets a row in a disambiguation file or (b) gets one of the units to rename.

## The five rituals

A Mode D collection has five maintenance rituals. Each ritual has a defined trigger, a defined sequence, and a defined output.

### Ritual 1: Single-unit patch

The smallest coordinated change. One unit repo, no other repos affected.

**Trigger:** a change confined to one unit's content (`<UNIT>.md`, `references/`, `README.md`) that does NOT touch the collection map or any cross-cutting field.

**Sequence:**
1. Make the change.
2. Bump frontmatter version + updated date in `<UNIT>.md`.
3. Prepend a CHANGELOG entry with: problem-and-fix paragraph, Added/Changed/Removed bullets, "Why a patch / minor" rationale.
4. Run the meta-linter from the hub.
5. Commit, push, tag, release.

### Ritual 2: Coordinated cross-collection patch

The standard ritual. Collection map changes; all N repos sync.

**Trigger:** a change that affects more than one unit (a new compatibility row in the collection map; a new field in unit frontmatter; a coordinated content sweep across N units).

**Sequence:**
1. Discuss first if the change affects scope or trigger surface. Open a hub issue.
2. Make changes in the hub first (collection map, governance docs, install scripts).
3. Sync the collection map to every specialist via `cp` (or equivalent).
4. Bump frontmatter version + updated date in EVERY affected unit.
5. Update the collection map's known-good versions table.
6. Update the hub README known-good versions table.
7. Prepend CHANGELOG entries in every affected unit.
8. Run the meta-linter; expect green.
9. Per unit: commit, push, tag, release. Use a helper script.
10. Hub commit + push (no tag, no release on hub).
11. Verify CI green on the hub workflow.
12. Tag-release parity audit.

**Critical ordering rule:** update the collection map's known-good versions table to ALL the new versions BEFORE any unit commits. If the table is updated after the first unit ships, the first unit captures stale-table content; the meta-linter catches the drift on the next push.

### Ritual 3: Hub-only patch

**Trigger:** a change confined to the hub that does NOT touch the collection map and does NOT modify any specialist.

**Sequence:** hub commit + push. No version bumps. No specialist sync.

### Ritual 3a: Hub + one-specialist patch

**Trigger:** a change that affects the hub plus a single specialist (a hub-mirrored file that lives in N=2 repos; a single-unit audit refresh that touches both hub and the unit).

**Sequence:** the affected specialist gets a patch bump + CHANGELOG; the collection map's known-good versions table updates; **byte-identical sync runs across all N repos** (every other specialist gets a sync-only patch bump). Hub commit + push.

The "skip the full sync because only one specialist changed" precedent does NOT hold. If the lint enforces byte-identical collection map, every version table change requires every unit to re-sync.

### Ritual 4: Lint regression recovery

**Trigger:** the daily-scheduled lint workflow fires red.

**Sequence:**
1. Read the failing check name in the workflow output.
2. Run that specific check locally with `--verbose`.
3. Fix the drift (most common: byte-identical map drift; frontmatter-version mismatch; missing release for an existing tag; new banned-character introduction).
4. Push the fix; re-run the workflow via `workflow_dispatch` to confirm green.

### Ritual 5: Adding a new unit to the collection

**Trigger:** the maintainer is shipping the (N+1)th specialist.

**Sequence:**
1. Create the new specialist repo. Mirror the canonical top-level structure.
2. Update the collection map's per-unit table to include the new unit.
3. Update the hub README's discovery surface.
4. If the meta-linter's `SKILLS` list (or equivalent) is hardcoded, update it.
5. If CI clones siblings, update the workflow's clone list.
6. Coordinated patch ritual (Ritual 2) plus the new unit's first release.
7. If applicable, update the package-manager marketplace manifest.

## Version-bump rules

Mode D uses semver flavored to the collection's work shapes:

- **Major (`X.0.0`)**: the unit's primary manifest restructures in a way that breaks downstream consumers.
- **Minor (`x.Y.0`)**: a new behavior the user can observe (new step / sub-step; new artifact emit; new have-not enforced; new tier in the workflow).
- **Patch (`x.y.Z`)**: documentation-only updates; collection-map sync; frontmatter compatibility additions; reference-file additions that do not change the unit's primary content.

Default to patch. Minor only when there is an observable behavior change. The CHANGELOG entry's "Why a patch, not a minor" line forces an explicit choice.

## Tag-release parity

Every git tag in every unit has a matching platform release (GitHub Release in the canonical case). The release body is lifted verbatim from the CHANGELOG entry between the matching `## v<X.Y.Z>` heading and the next `---` separator.

The release-body extraction shape:
```bash
body=$(awk -v v="## v$ver " '
  $0 ~ "^"v {f=1; next}
  f && /^---$/ {exit}
  f
' CHANGELOG.md)
gh release create "v$ver" --title "v$ver" --notes "$body" --repo "$ORG/$UNIT"
```

The lint check enforces parity. Backfill missing releases by re-running this command against the existing tag.

## Anti-patterns

- **Documenting the byte-identical invariant without enforcing it.** "We keep `<COLLECTION-MAP>.md` byte-identical" without a lint that runs daily produces drift within weeks. The mechanism is what works; the prose is what gets ignored.
- **One-off precedent that breaks the invariant.** "Single-unit patches don't trigger full sync" sounds reasonable; in practice it produces N-version drift on the affected rows of the collection map. The lint catches it; the fix is more commits per patch, accepted as the cost of the invariant.
- **Hub elaborate scaffold without a meta-linter.** The hub gathers cross-cutting docs (`MAINTAINING.md`, `ORCHESTRATORS.md`, governance docs) without machine-readable enforcement. Future drift goes uncaught.
- **Per-unit `CONTRIBUTING.md` that duplicates the hub's.** N copies of the same contributor guide drift independently within months. Each unit's `CONTRIBUTING.md` should be a thin pointer to the hub's canonical version.
- **Personal local config committed.** `.claude/settings.local.json` and similar `.local` files are personal-machine overrides, not project config. Committing them per repo creates noise; the `.gitignore` template prevents it.
- **Unsynced version table.** Hub README version table out of step with the collection map's known-good versions table. The two should match exactly. The maintainer's update ritual must touch both.
- **Tag without release.** Cuts a `git tag v1.2.3`, pushes it, never creates the matching GitHub Release. Consumers see a tag exists but find no release notes; trust erodes.

## Cross-references

- `references/repo-audit.md`: the per-unit 42-criteria scorecard. Mode D applies the scorecard per unit AND adds the cross-unit invariants in this file.
- `references/audit-mode.md`: scoring engine for Mode C; can be invoked per-unit during a Mode D audit.
- `references/release-distribution.md`: per-unit release patterns (semantic-release, release-please, manual). Mode D layers tag-release parity on top.
- `references/community-governance.md`: per-unit `CODE_OF_CONDUCT.md` / `SECURITY.md` / contributor templates. Mode D coordinates these so per-unit files point at the hub canonical.
- `references/git-workflows.md`: branching and merging conventions. Mode D adds the coordinated-patch ordering rules.

## Worked example

The aihxp/ready-suite suite implements this pattern across 12 repos. See:

- [aihxp/ready-suite/SUITE.md](https://github.com/aihxp/ready-suite/blob/main/SUITE.md) - the byte-identical collection map.
- [aihxp/ready-suite/scripts/lint.sh](https://github.com/aihxp/ready-suite/blob/main/scripts/lint.sh) - the meta-linter.
- [aihxp/ready-suite/MAINTAINING.md](https://github.com/aihxp/ready-suite/blob/main/MAINTAINING.md) - the maintainer rituals (Ritual 1 through Ritual 5).
- [aihxp/ready-suite/.github/workflows/lint.yml](https://github.com/aihxp/ready-suite/blob/main/.github/workflows/lint.yml) - the CI workflow that clones N siblings and runs the meta-linter.

The pattern is reproducible. A new collection can scaffold the hub and the first specialist by following Ritual 5 against this reference, then add specialists one at a time. The maintenance burden scales sublinearly with N once the meta-linter is in place: the hub's daily lint run catches drift across N repos with the same effort as catching drift in 2 repos.
