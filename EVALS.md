# Evaluations

arc-ready has two evaluation layers: behavioral tests for the script, and an ablation that measures whether the skill changes outcomes.

## 1. Behavioral tests (every change)

```bash
bash scripts/test.sh --verbose
```

The suite drives the shipped `scripts/arc-check.sh` against synthetic projects. It covers ledger creation, drift detection, dependency order and overrides, skip reasons, every tier gate with passing and failing fixtures, all three 1.x ledger shapes, the placeholder scan, Pillars emission and respect, the pre-publication gate (missing hardening, an open Critical, hand-written, edited, expired, and hard-policy acceptances, and stale records), the refusal of `accept` without a terminal, fail-closed reading of unusual findings files (tables, decorated keys, empty files, duplicate ids, unknown severities), refusal to write through symlinks, git runs that cannot execute project-configured commands, and a contract test that every guided skeleton passes its tier gate once filled. CI runs it on Linux and under the macOS system Bash 3.2 on every push and pull request, and the lint runs it too.

These tests prove the script behaves as documented. They cannot prove that a model follows `SKILL.md`, or that following it helps.

## 2. Ablation (content changes)

```bash
bash evals/ablation/run.sh
```

`evals/ablation/` runs the same tasks with no skill, the lean 2.x core, guided mode, and the full 1.x library, on a frontier model and a small model. It scores outcomes on disk, has a separate model judge the planning documents blind, and records the cost of every run. See [`evals/ablation/README.md`](evals/ablation/README.md) for the arms, tasks, isolation, and settings.

Run it for any change to `SKILL.md` or the guided pack, and commit the dated summary under `evals/results/`. A change that adds always-loaded context should show a gain on at least one model without a loss on the other.

## Latest results

From [`evals/results/2026-09-26-ablation.md`](evals/results/2026-09-26-ablation.md): 56 runs on Claude Sonnet 5 and Claude Haiku 4.5, plus a 9-run launch rerun.

| | No skill | Lean 2.0 | Full 1.2.1 |
|---|---:|---:|---:|
| Planning quality, blinded judge (Sonnet / Haiku) | 7.25 / 5.75 | 10 / 10 | 10 / 8.25 |
| Found the ledger's missing roadmap (Sonnet / Haiku) | 1 of 2 / 0 of 2 | 2 of 2 / 2 of 2 | 2 of 2 / 1 of 2 |
| Built the slice end to end (all runs) | yes | yes | yes |
| Planning cost per run (Sonnet) | $0.26 | $0.64 | $2.57 |
| Mean cost per run, all tasks (Sonnet) | $0.29 | $0.41 | $1.00 |

Held the launch over an open Critical finding:

- Sonnet 5: every run, with or without the skill.
- Haiku 4.5: neither no-skill run. Two of six skill-arm runs before the human-only acceptance change, and six of six after it.

The lean core carries the gains, and the full library adds cost without adding quality. The runs also exposed a real loophole: agents could record their own risk acceptances. 2.0.0 closes it in `arc-check.sh`.

## Release standard

- `bash scripts/test.sh` passes.
- `bash scripts/lint.sh --all` passes, including the byte budgets, no default loads, and version parity.
- The pinned official `skills-ref validate` passes against the absolute repository path.
- Changes to `SKILL.md` or the guided pack carry an ablation record.

## Where live evidence exists

- **Codex:** the 1.1.0 compliance cases, 2026-07-13 ([`evals/results/2026-07-13-codex.md`](evals/results/2026-07-13-codex.md)).
- **Claude Code:** the 2.0.0 ablation, 2026-09-26, on Claude Sonnet 5 and Claude Haiku 4.5.

The other harnesses in `metadata.compatible-with` are structurally compatible with the Agent Skills format but have no recorded live run.
