# Changelog

All notable changes to arc-ready are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows semantic versioning per `MAINTAINING.md`.

## [0.1.2] - 2026-05-09

### Fixed

- CI lint workflow no longer fails on `push` events. The `tag-release-parity` check is now run only on `schedule` and `workflow_dispatch`, because tag pushes trigger CI before the matching GitHub Release is created (chicken-and-egg). Push and pull-request runs run every other check; the daily schedule run catches missing releases. Local `bash scripts/lint.sh --all` continues to run the full check.
- Hardcoded local-clone paths (`/Users/hprincivil/Projects/<skill>-ready/SKILL.md`) in `references/planning/trust-boundaries.md` and `references/shared/RESEARCH-2026-04.md` rewritten to skill-relative references. These were inherited from source authoring and survived the v0.1.0 cross-reference sweep.
- Broken external link in `references/shared/RESEARCH-2026-04.md` from `aihxp/production-ready/blob/main/SUITE.md` (no longer the canonical hub) to `aihxp/ready-suite/blob/main/SUITE.md` with a "(predecessor)" annotation.

### Why a patch, not a minor

Bug-fix release. CI was structurally broken; published references contained user-specific local paths; one external cross-link was outdated. No discipline change, no new content.

## [0.1.1] - 2026-05-09

### Added

- SKILL.md expansion to spec target (~1,500-2,000 lines). Adds Mode B existing-codebase routing decision tree with concrete gap-to-tier mapping, Mode C retroactive audit procedure with severity vocabulary and per-tier audit-output canonical paths, Mode D multi-repo suite layout dispatch, per-tier inline grep test snippets (PRD, architecture, roadmap, stack, repo, production, deploy, observe, launch, harden), per-harness integration notes (Claude Code, Codex, Cursor, Windsurf, Antigravity, Pi, OpenClaw, generic chat frontend), worked-example narrative tracing the Pulse arc through every tier, "common failure modes that fire here" symptom-to-pattern lookup table, critical-finding gate logic and grep test, AGENTS.md emit-and-respect rules across Tier 0 and Tier 2.1, elaborated resume protocol with shell-snippet examples and disk-wins semantics.
- Artifact map alignment with the dogfood (`aihxp/ready-suite-example`): `.stack-ready/STACK.md` (alongside `DECISION.md` variant), `.repo-ready/SCAFFOLD.md` (alongside `AUDIT-REPORT.md` for Mode B), `.deploy-ready/DEPLOY.md`/`PLAN.md`/`TOPOLOGY.md`/`STATE.md` (multi-artifact reality), `.observe-ready/OBSERVE.md`/`SLOs.md`/`INDEPENDENCE.md`/`STATE.md` (multi-artifact reality). The Consumes-from-upstream and Produces-for-downstream tables now match the canonical names the source eleven-skill suite established and the dogfood uses.

### Why a patch, not a minor

Content deepening, not contract change. The artifact-map clarification reflects what the source skills already produced; arc-ready was previously documenting one canonical filename per tier when the source produces several. No new failure-mode patterns were introduced; the discipline is unchanged.

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

[0.1.2]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.2
[0.1.1]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.1
[0.1.0]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.0
