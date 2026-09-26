# Maintaining arc-ready

Release guide for the maintainer: one repository, one version, one changelog, one tag stream. Contributor guidance is in `CONTRIBUTING.md`; evaluation policy is in `EVALS.md`.

## Release contract

| Surface | Contract |
|---|---|
| `SKILL.md` | The whole default context. Version at `metadata.version`, date at `metadata.updated`. At most 16,384 bytes, and it names no file outside the guided pack. |
| `scripts/arc-check.sh` | `ARC_CHECK_VERSION` equals `metadata.version`. Reads 1.x and 2.x ledgers. |
| `CHANGELOG.md` | The top entry equals `metadata.version`. |
| Artifact paths | Stable `.<tier>-ready/` paths and ledger format. Breaking either is a major release. |
| Guided pack | Opt-in only. Each skeleton is at most 4,096 bytes and, once filled in, passes its tier gate. |
| Evidence | `scripts/test.sh`, the lint, and the official validator for every release; an ablation record in `evals/results/` for content changes. |
| Full library | `v1.2.1` stays tagged and installable. It receives no changes. |

## Versioning

- **Patch:** fixes to scripts, lint, or documentation that change neither what agents are told nor what gates accept.
- **Minor:** new gate checks or `arc-check.sh` commands, or `SKILL.md` and guided-pack changes backed by evaluation.
- **Major:** changes to artifact paths, the ledger format, or the workflow shape. Update `MIGRATION.md` before publishing.

## Prepare a release

1. Update `metadata.version` and `metadata.updated` in `SKILL.md`, and `ARC_CHECK_VERSION` in `scripts/arc-check.sh`.
2. Add the matching top `CHANGELOG.md` entry with its patch, minor, or major rationale.
3. For content changes, run the ablation (`bash evals/ablation/run.sh`) and commit a dated record under `evals/results/`.
4. Install the pinned validator in an isolated environment:

```bash
python3 -m venv .venv-skills-ref
.venv-skills-ref/bin/pip install -r requirements/skills-ref.txt
```

5. Run the release evidence:

```bash
SKILLS_REF_BIN="$PWD/.venv-skills-ref/bin/skills-ref" bash scripts/release-check.sh
```

6. Inspect `git diff --check` and the full diff.

## Publish

`main` is protected: changes land through a pull request once the `meta-linter` check passes.

```bash
VERSION=2.0.0
git switch -c "release/v$VERSION"
git commit -am "release: prepare arc-ready v$VERSION"
git push -u origin "release/v$VERSION"
gh pr create --fill
```

After the pull request merges:

```bash
git switch main
git pull --ff-only
git tag -a "v$VERSION" -m "arc-ready v$VERSION"
git push origin "v$VERSION"
awk '/^## \[/{n++} n==1' CHANGELOG.md > /tmp/arc-ready-notes.md
gh release create "v$VERSION" --title "v$VERSION" --notes-file /tmp/arc-ready-notes.md
```

Never bypass hooks. If CI fails after a tag is published, fix forward with a new patch version; do not move a published tag.

## Lint checks

| Check | What it proves |
|---|---|
| `punctuation-clean` | No forbidden dash, arrow, or box characters in any authored file (the archival `docs/research/` is exempt). |
| `emoji-free` | No emoji in any tracked text file. |
| `version-parity` | `metadata.version`, the top CHANGELOG entry, and `arc-check.sh` agree. |
| `compatible-with` | Compatibility metadata names the supported standards-level clients. |
| `standards-shape` | Top-level Agent Skills fields and scalar limits match the specification. |
| `skill-budget` | `SKILL.md` and each guided skeleton stay inside their byte budgets. |
| `no-default-loads` | `SKILL.md` names no reference outside its guided-mode section, and `references/` holds only the guided pack. |
| `skill-paths-exist` | Every script and skeleton `SKILL.md` names exists, and every skeleton is listed. |
| `links-resolve` | Relative markdown links resolve. |
| `shell-syntax` | Every repository Bash script parses. |
| `test-suite` | `scripts/test.sh` passes. |
| `official-validator` | The pinned `skills-ref` validator accepts the repository, when installed. |
| `tag-release-parity` | Every tag has a matching GitHub Release. Release-only. |

## Ablation runs

- The default matrix is four tasks across the none, lean, and full arms on Claude Sonnet 5 and Claude Haiku 4.5, plus guided mode on Haiku, repeated twice. `evals/results/` records the cost of the latest run.
- The harness starts each contestant with a minimal environment, so settings inherited from the session that launches it (an effort level, host integrations) do not skew the runs.
- Run output lives outside the repository, under `$TMPDIR/arc-ready-ablation/` by default. Commit only the summary and the results table.
- The skill copies inside the run output are read-only. Run `chmod -R u+w` on the output before deleting it.

## Tag-release parity

Every tag must have a matching GitHub Release. Scheduled CI runs the read-only parity check. If a tag lacks a release, investigate before creating one.

## Predecessor

hannsxpeter/ready-suite remains available. arc-ready 1.2.1 is the frozen full-library edition.
