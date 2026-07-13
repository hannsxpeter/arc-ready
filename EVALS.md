# Evaluations

arc-ready has two evaluation layers: deterministic repository checks and live-harness behavioral cases.

## Reproduce the deterministic evidence

```bash
bash scripts/eval.sh --verbose
```

The command covers Modes A-D, dependency-ordered routing, disk drift, canonical artifacts, product forms, domain composition, stack-profile mappings, added domain completeness, progressive-disclosure budgets, the late-Critical publication gate, direct references, current OWASP routing, and live-case inventory.

Repository lint and dogfood smoke remain separate evidence surfaces:

```bash
bash scripts/lint.sh --all --verbose
bash scripts/dogfood-smoke.sh --verbose
```

Release validation also runs the pinned official Agent Skills validator through `scripts/release-check.sh`.

## Live-harness evidence

Deterministic checks cannot prove that a model will route, ask, write, or refuse correctly in every client. The cases under `evals/cases/` provide prompts, setup, expected invariants, and a 10-point scoring rubric for those behaviors. Run each case in every harness for which the release claims live behavioral evidence and record the result with `evals/RESULTS-TEMPLATE.md`. Compatibility metadata describes structural support; it does not imply that every listed client received a live run.

Checked-in evidence:

- `evals/results/2026-07-13-codex.md`: ten independent Codex file-system cases, 100/100 total, all gate invariants passed, plus a focused rerun after strict-review remediation.

## Release standard

A release candidate requires:

- 14/14 deterministic evaluations.
- All dogfood smoke tests passing.
- Repository lint passing.
- Official `skills-ref validate` passing against the absolute repository path.
- No live case below 8/10.
- No zero score on a gate invariant.
- Any harness-specific limitation recorded, dated, and scoped.

Live behavior remains harness-dependent. This repository provides reproducible cases and rubrics, but it does not claim a live run occurred unless a completed results record is checked in or attached to the release evidence.
