<!--
Thanks for contributing to arc-ready.

arc-ready is faithful consolidation of the eleven-skill aihxp/ready-suite. Net-new
failure-mode patterns and net-new discipline rules will be rejected; refinements
within the established pattern catalog are welcome. See CONTRIBUTING.md.

Please cover the items below in your description. Lint must pass before merge.
-->

## What this changes

<!-- One paragraph: what changed and why. -->

## Type of change

- [ ] Bug fix (lint, broken cross-reference, typo)
- [ ] Reference update (ecosystem change: deprecated tool, new compliance version, new vendor)
- [ ] Worked-example refinement (EXAMPLE-PRD.md, EXAMPLE-ARCH.md, etc.)
- [ ] Cross-tier consistency fix
- [ ] Lint or CI improvement
- [ ] Documentation (README, AGENTS.md, MAINTAINING.md, MIGRATION.md, CONTRIBUTING.md, SECURITY.md)
- [ ] Other (please describe)

## Discipline check

- [ ] No net-new failure-mode patterns introduced.
- [ ] No collapsed references that have load-on-demand value.
- [ ] No em-dashes, en-dashes, arrows, or box-drawing characters in load-bearing files.
- [ ] No emojis.

## Versioning

- [ ] SKILL.md `version:` bumped (X.Y.Z) - patch / minor / major rationale stated below.
- [ ] CHANGELOG.md top entry added with the same version and a "Why a patch / minor / major" paragraph.
- [ ] If minor or major: MIGRATION.md updated if the artifact contract or workflow shape changed.

**Version bump rationale**: <!-- patch / minor / major and why -->

## Lint

- [ ] `bash scripts/lint.sh --all` passes locally.

## Cross-references

- [ ] Any new references registered in SKILL.md references table.
- [ ] Cross-references between reference files use tier-relative paths (same-tier as `bar.md`, cross-tier as `../<other-tier>/bar.md`).
- [ ] Artifact paths (`.<tier>-ready/<ARTIFACT>.md`) preserved.

## Related issues

<!-- Closes #NNN, refs #NNN -->
