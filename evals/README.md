# Evaluations

- [`ablation/`](ablation/README.md): the with-and-without-skill comparison harness.
- `results/`: dated records. Each one applies to the version it names.
  - [`2026-09-26-ablation.md`](results/2026-09-26-ablation.md): the 2.0.0 ablation in Claude Code, on Claude Sonnet 5 and Claude Haiku 4.5, with its raw table in `2026-09-26-ablation.tsv`.
  - [`2026-07-13-codex.md`](results/2026-07-13-codex.md): the 1.1.0 compliance run in Codex. Its case files are preserved at the `v1.2.1` tag under `evals/cases/`.

The behavioral tests for `scripts/arc-check.sh` live in `scripts/test.sh`. The evaluation policy is in [`EVALS.md`](../EVALS.md).
