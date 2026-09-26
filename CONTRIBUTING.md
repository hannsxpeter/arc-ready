# Contributing to arc-ready

arc-ready 2.x is small on purpose. `SKILL.md` is the entire default context an agent loads, so every sentence in it costs tokens on every run. Contributions are welcome when they make the skill more reliable without making it larger, or when evidence shows that added context changes outcomes.

Pillars is the agent-memory layer arc-ready emits for file-system projects. Changes to `arc-check.sh pillars` or to the emitted `AGENTS.md` must keep that contract: the arc artifacts stay authoritative, an existing non-Pillars `AGENTS.md` is never overwritten, and a blocked adoption is recorded in the ledger.

## Before you contribute

Read `README.md`, `SKILL.md`, `AGENTS.md` (conventions and forbidden actions), and `EVALS.md`.

## What makes a good contribution

- A bug fix in `scripts/arc-check.sh`, with a test in `scripts/test.sh` that fails before the fix.
- Moving a rule out of prose and into the script, where it is enforced instead of requested.
- A new gate check that catches a documented have-not mechanically without rejecting legitimate artifacts. Add a passing and a failing fixture.
- A `SKILL.md` or guided-pack change backed by an ablation run, for example a rule that closes a failure you observed in current models.
- A correction where the documentation disagrees with actual behavior.

## What is out of scope

- Reference material a current model already knows: framework tutorials, general best practices, vendor comparisons. The 1.x library at the `v1.2.1` tag remains available for anyone who wants it.
- Frozen data that goes stale, such as version numbers, prices, rankings, or survey statistics. `SKILL.md` tells agents to check current sources instead.
- Changes to the `.<tier>-ready/` artifact paths or the ledger format outside a major release.
- Em dashes, en dashes, arrows, box-drawing characters, or emoji (the lint enforces this).

## How to contribute

1. Fork the repository and create a descriptive branch, such as `fix/prepublish-expired-acceptance` or `gate/observe-runbook-date`.
2. Make the change. Keep scripts Bash 3.2 compatible.
3. Run `bash scripts/test.sh --verbose` and `bash scripts/lint.sh --all --verbose`.
4. For `SKILL.md` or guided-pack changes, run the ablation harness, or the relevant subset (`TASKS=resume MODELS=claude-haiku-4-5 bash evals/ablation/run.sh`), and attach the summary.
5. Add a top `CHANGELOG.md` entry, and bump `metadata.version` in `SKILL.md` and `ARC_CHECK_VERSION` in `scripts/arc-check.sh` together.
6. Commit as `<scope>: <imperative summary>`, for example `arc-check: reject expired risk acceptances`.
7. Open a pull request and cover the checklist in the template.

## Code style

- Bash 3.2 compatible scripts with no dependencies beyond POSIX tools, plus `perl` for the lint and `jq` and the `claude` CLI for the ablation harness.
- Markdown: `-` for unordered lists, `1.` for ordered, pipe tables, `#` headings, and fenced code with a language tag.
- ASCII hyphen for ranges and compounds, `->` instead of Unicode arrows, and no emoji.

## Reporting bugs

Use GitHub Issues with the bug template. Include the version (`bash scripts/arc-check.sh version`), the harness and model, the mode, and the output of `arc-check.sh status` or the failing gate. For security issues, see `SECURITY.md`.

## Taxonomy questions

The have-nots in `SKILL.md` are arc-ready's named failure modes. If a behavior feels like a failure but matches none of them, file a taxonomy question. A new name needs evidence that current models produce the behavior and that it is distinct from the existing names.

## License

By contributing, you agree that your contributions will be licensed under the project's MIT license (see `LICENSE`).
