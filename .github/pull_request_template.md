<!--
Thanks for contributing to arc-ready. See CONTRIBUTING.md.

arc-ready 2.x keeps the default context small. Content earns its place by a
measured effect in the ablation harness, or by being something a model cannot
know (a format, a contract, a gate). Enforcement belongs in scripts/arc-check.sh
rather than in prose. Cover the items below. Lint must pass before merge.
-->

## What this changes

<!-- One paragraph: what changed and why. -->

## Type of change

- [ ] Bug fix (script, lint, typo)
- [ ] arc-check.sh behavior (ledger, gate, prepublish, pillars, scan)
- [ ] SKILL.md content
- [ ] Guided pack skeleton
- [ ] Evaluation (tests or ablation harness)
- [ ] Documentation
- [ ] Other (please describe)

## Evidence

- [ ] `bash scripts/test.sh` passes, and new script behavior has a test.
- [ ] `bash scripts/lint.sh --all` passes (budgets, no default loads, punctuation, links).
- [ ] Changes to SKILL.md or the guided pack include an ablation result (see EVALS.md), or say why none is needed.
- [ ] No em dashes, en dashes, arrows, or emoji.

## Versioning

- [ ] `metadata.version` in SKILL.md, `ARC_CHECK_VERSION` in scripts/arc-check.sh, and the top CHANGELOG entry agree.
- [ ] MIGRATION.md is updated if the artifact paths, the ledger format, or the workflow shape changed.

**Version bump rationale**: <!-- patch / minor / major and why -->

## Related issues

<!-- Closes #NNN, refs #NNN -->
