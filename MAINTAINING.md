# Maintaining arc-ready

Procedural guide for the arc-ready maintainer. arc-ready has one repository, one skill version, one changelog, one tag stream, and one release stream. The coordinated multi-repository rituals from hannsxpeter/ready-suite do not apply.

For contributor guidance, see `CONTRIBUTING.md`. For evaluation policy, see `EVALS.md`.

## Release contract

| Surface | Contract |
|---|---|
| `SKILL.md` | Official Agent Skills activation surface. Version lives at `metadata.version`; update date lives at `metadata.updated`. |
| `CHANGELOG.md` | Top version must match `metadata.version`. |
| Canonical artifacts | Stable `.<tier>-ready/<ARTIFACT>.md` paths. Breaking changes require a major release. |
| Pillars memory | Project-root `AGENTS.md` plus `agents/context.md` and `agents/repo.md` when adoption is not blocked. Arc artifacts remain authoritative. |
| Public activation | `.launch-ready/PREPUBLICATION.md` must be newer than the checked hardening revision and have a pass verdict. |
| References | Focused, load-on-demand files. Inherited source prose remains faithful; cross-reference corrections are allowed. |
| Evaluations | Deterministic suite, operational smoke, official validator, and scored live-harness cases. |

## Versioning

- Patch releases (`vX.Y.Z`) fix bugs, typos, cross-references, or lint behavior without adding workflow capability.
- Minor releases (`vX.Y.0`) add non-breaking routing, references, sub-steps, ecosystem guidance, or evaluation coverage.
- Major releases (`vX.0.0`) break canonical artifact paths or the workflow shape. Coordinate downstream consumers and update `MIGRATION.md` before publication.

The 1.1.0 product-form, domain-composition, evaluation, and pre-publication additions are minor because the canonical artifact contract and Modes A-D remain stable.

## Prepare a release candidate

1. Choose the version and update `metadata.version` and `metadata.updated` in `SKILL.md`.
2. Add the matching top CHANGELOG entry with patch, minor, or major rationale.
3. Update public version surfaces, plugin metadata, migration notes, and issue or PR templates when affected.
4. Add or update deterministic evaluations and live-harness cases for behavior changes.
5. Install the pinned official validator in an isolated environment:

```bash
python3 -m venv .venv-skills-ref
.venv-skills-ref/bin/pip install -r requirements/skills-ref.txt
```

6. Run the release evidence command with an absolute validator path:

```bash
SKILLS_REF_BIN="$PWD/.venv-skills-ref/bin/skills-ref" bash scripts/release-check.sh
```

7. Run every live-harness case claimed for the release. Record scores with `evals/RESULTS-TEMPLATE.md`. No case may score below 8/10, and no gate invariant may score zero.
8. Inspect `git diff --check`, the full diff, new reference routes, and the inherited Unicode baseline. A baseline update is allowed only for a reviewed mechanical move of existing source text.

Do not publish a release candidate with a skipped official validator, failing deterministic check, unresolved dogfood failure, or unsupported live-harness claim.

## Publish after evidence passes

Publication is a maintainer action, separate from release preparation:

```bash
VERSION=1.1.0
git add -A
git commit -m "v$VERSION: prepare release"
git push origin HEAD
git tag "v$VERSION"
git push origin "v$VERSION"
gh release create "v$VERSION" --title "v$VERSION" --notes-from-tag
```

Never bypass hooks. If CI fails after a tag is published, fix forward with a new patch version. Do not move a published tag.

## Validation commands

```bash
bash -n scripts/*.sh
bash scripts/lint.sh --all --verbose
bash scripts/dogfood-smoke.sh --verbose
bash scripts/eval.sh --verbose
SKILLS_REF_BIN="$PWD/.venv-skills-ref/bin/skills-ref" bash scripts/lint.sh official-validator --verbose
bash scripts/lint.sh tag-release-parity --verbose
```

`scripts/release-check.sh` runs all of these evidence surfaces. Tag-release parity is read-only and requires an authenticated GitHub CLI.

## Lint checks

| Check | What it proves |
|---|---|
| `unicode-clean` | Load-bearing authored files contain no forbidden dash, arrow, or box characters. |
| `unicode-baseline` | Existing inherited punctuation and emoji counts did not increase in any tracked file. |
| `frontmatter-version` | `metadata.version` matches the top CHANGELOG entry. |
| `skill-version-body` | Every embedded progress-schema version matches `metadata.version`. |
| `compatible-with` | Compatibility metadata names the supported standards-level clients. |
| `standards-shape` | Top-level Agent Skills fields and scalar limits match the current specification. |
| `skill-size-budget` | `SKILL.md` remains below 500 lines and 5000 words. |
| `references-exist` | Every direct `SKILL.md` reference exists. |
| `reference-basenames` | Reference basenames remain globally unique. |
| `relative-links-resolve` | Markdown links among references resolve from the source file. |
| `reference-citations` | Tier-agnostic `references/<basename>.md` citations name real files. |
| `tier-folders-populated` | Every reference tier remains populated. |
| `shell-syntax` | Every repository Bash script parses under Bash. |
| `eval-suite` | Deterministic behavioral invariants pass. |
| `official-validator` | The current official `skills-ref` validator accepts the repository when installed. |
| `tag-release-parity` | Every existing tag has a matching GitHub Release. Release-only check. |

## Inherited Unicode policy

Load-bearing authored surfaces must remain clean. Some references inherited punctuation and emoji from the source suite. `config/unicode-baseline.txt` records per-file counts so CI rejects increases without rewriting faithful copies.

After a reviewed mechanical split or move, regenerate and inspect the baseline:

```bash
bash scripts/update-unicode-baseline.sh
git diff -- config/unicode-baseline.txt
```

Never use baseline regeneration to approve newly authored symbols.

## Tag-release parity

Every tag must have a matching GitHub Release. Scheduled and manually dispatched CI runs the read-only parity check. If a tag lacks a release, investigate the tag and evidence before creating the missing release.

## Predecessor and downstream coordination

The eleven-skill hannsxpeter/ready-suite remains available. When a defect affects both products, repair arc-ready first and port the smallest relevant change to the predecessor. If canonical artifact paths, Pillars behavior, or orchestration semantics change, coordinate the dogfood example and downstream orchestrators before a major release.
