# Changelog

All notable changes to arc-ready are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows semantic versioning per `MAINTAINING.md`.

## [0.1.0] - 2026-05-09

### Added

- Initial consolidation of the eleven-skill aihxp/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready) into a single arc-ready skill.
- `SKILL.md`: tier-structured orchestrator body. Mode A/B/C/D detection. Tier 0 (orchestration), Tier 1 (planning: PRD, ARCH, ROADMAP, STACK), Tier 2 (building: REPO, PRODUCTION), Tier 3 (shipping: DEPLOY, OBSERVE, LAUNCH, HARDEN). Consolidated have-nots catalog covering every named failure mode from the source eleven skills. Tier completion gates, references table, suite-membership block, consumes/produces tables, session-state and resume protocol.
- 164 reference files organized by tier under `references/{orchestration,planning,building,shipping,shared}/`. Faithful preservation of every named pattern, grep test, and worked example from the source skills. Cross-references rewritten from sibling-skill paths to tier-relative paths.
- `references/shared/RESEARCH-2026-04.md`: consolidated source-citations file from the eleven per-skill research dumps.
- `references/shared/ORCHESTRATORS.md`: integration patterns for GSD, BMAD, Spec Kit, Superpowers, and plain harnesses (lifted from the ready-suite hub).
- `scripts/lint.sh`: single-repo meta-linter checking unicode cleanliness, frontmatter-version-matches-CHANGELOG, banned-phrase audits on load-bearing files.
- `.github/workflows/lint.yml`: CI workflow running the lint on push, PR, and a daily schedule.
- `README.md`, `AGENTS.md`, `CLAUDE.md` (symlink to AGENTS.md), `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE` (MIT), `.gitignore`, `.github/CODEOWNERS`.
- `MAINTAINING.md`: single-repo release rituals (patch / minor / major / tag-release parity / unicode discipline).
- `MIGRATION.md`: one-page guide for aihxp/ready-suite users covering install change, trigger surface, where each former skill's content now lives.

### Inherited from aihxp/ready-suite

The discipline of arc-ready is the discipline the eleven-skill suite produced. Specifically:

- The artifact-as-contract principle: every tier produces a canonical `.<tier>-ready/<ARTIFACT>.md` at a stable path, and downstream consumers depend on that path.
- The three-label test: every PRD sentence, every roadmap row, every architectural element labels as decision, hypothesis, or open question.
- The substitution test: every user-facing claim must fail competitor-substitution.
- The artifact-on-disk corollary: a tier is done when the artifact exists on disk and passes the have-nots check, not when the agent says it is done.
- The scope-fence: every tier refuses content that belongs to another tier.
- The mode-detection discipline: A/B/C/D modes are recorded explicitly; misdetection is a load-bearing failure mode.

### Compatibility

- Compatible with: claude-code, codex, cursor, windsurf, antigravity, pi, openclaw, any-agentskills-compatible-harness.
- Artifact paths (`.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, etc.) are unchanged from the eleven-skill suite. The aihxp/ready-suite-example dogfood verifies cleanly against arc-ready's tier dispatch.

[0.1.0]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.0
