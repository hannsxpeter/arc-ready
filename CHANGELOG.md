# Changelog

All notable changes to arc-ready are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows semantic versioning per `MAINTAINING.md`.

## [1.0.2] - 2026-05-30

Patch release. Resolves the two items v1.0.1 deferred and adds a third lint guard. No discipline change, no new failure-mode patterns, no artifact-path contract change.

### Added

- `references/building/login-pages.md` and `references/building/registration-pages.md`: the 78K `login-and-auth-pages.md` split at its existing H1 boundary into its two constituent documents (login / sign-in surfaces; registration / sign-up surfaces) so an agent loads only the relevant half. Cite sites updated in `SKILL.md` (sub-step 23 and the load-on-demand table) and `references/building/auth-and-rbac.md`; the two intra-document back-references now name the sibling file. `domain-considerations.md` (125K) is intentionally left whole (it is a grep-friendly per-domain lookup catalog).
- `scripts/lint.sh` gains a `reference-citations` check: every `references/<basename>.md` inline-code or prose citation inside `references/` must name a real reference. Reference basenames are globally unique, which makes this tier-agnostic form the dominant in-repo convention (~200 citations); the check guards it against a rename or typo.

### Changed

- `AGENTS.md` cross-references section now documents the actual two-form citation convention (file-relative `[..](..)` links guarded by `relative-links-resolve`; tier-agnostic `references/<basename>.md` citations guarded by `reference-citations`) instead of a `../tier/bar.md` convention the corpus used exactly once.
- Reference-budget guidance (`AGENTS.md`, `SKILL.md`) updated for the new catalog size (167 files) and to name `domain-considerations.md` as the remaining split candidate.

### Notes

- The em-dashes in the inherited `building/` references (53 files) are intentionally left per the faithful-copy rule; the lint continues to exempt reference files from `unicode-clean`.
- `references/building/security-setup.md`'s apparent duplicate `## Reporting a vulnerability` heading was confirmed a false positive (the second is inside a fenced code example), so no change was made.

### Why a patch, not a minor

Structural and tooling consistency only. The file split is a faithful bisection at an existing document boundary (no prose rewritten beyond two back-reference pointers); the lint addition guards an existing convention. No new content, no contract change.

## [1.0.1] - 2026-05-30

Patch release. Contract-consistency and mechanical-correctness fixes across the orchestrator, the dogfood smoke test, the reference cross-links, and a repo-wide documentation-drift audit. No discipline change, no new failure-mode patterns, no artifact-path contract change.

### Fixed

- **Critical-finding gate grep** (`SKILL.md`): the documented gate read the line *before* each `severity: critical` for its status (`grep -B 1`), so an open Critical never blocked launch. Corrected to scan forward (`grep -A 1`) and pinned the canonical FINDINGS.md finding shape (a `severity:` line followed by a `status:` line). The dogfood smoke test (Test 9) already used correct logic; the documented snippet now matches it.
- **Resume-protocol drift check** (`SKILL.md`): the snippet used `${tier^^}` (Bash 4+), which fails on the Bash 3.2 the project targets (macOS default). Replaced with a `tr`-based uppercase.
- **Drift detection missed the architecture tier** (`SKILL.md`, `scripts/dogfood-smoke.sh`): the loop variable `architecture` never matched the ledger label `(ARCH)`, so architecture-tier drift went undetected. Added the `architecture` to `ARCH` label mapping in the resume snippet and both smoke-test drift checks.
- **Dogfood smoke Test 1 was a vacuous pass** (`scripts/dogfood-smoke.sh`): the happy-path drift check used a malformed, case-mismatched regex that matched nothing, so the test could not fail regardless of disk state. Rewritten to mirror Test 2's correct uppercased check.
- **Stale template version** (`SKILL.md`): the PROGRESS.md schema example hardcoded `## Skill version: 0.1.1`. Bumped to the current version, now guarded by the new `skill-version-body` lint check.
- **Broken reference cross-links** (`references/`): rewrote 14 `RESEARCH-2026-04.md` markdown links in `references/planning/` to `../shared/RESEARCH-2026-04.md` (the file lives in `references/shared/`), including one anchored link. Fixed two self-directory `ORCHESTRATORS.md` links in `references/shared/RESEARCH-2026-04.md`. Cross-reference corrections only; reference prose is unchanged.

### Changed

- **Stack artifact filename reconciled to `.stack-ready/STACK.md` repo-wide.** The Tier 1 prose, the Tier 1.4 gate, the output instruction, the README artifact map, and the resume example said `DECISION.md`, contradicting the grep tests, the worked example, the dogfood, and the v0.1.1 decision record. Swept `DECISION.md` to `STACK.md` across `SKILL.md`, `README.md`, the orchestration sequencing rules and PROGRESS schema, `pillars-integration.md`, the stack-tier deep-dives, six shipping references, and `MIGRATION.md` (24 occurrences across 14 reference files plus the root docs). `STACK.md` is the canonical write name; `DECISION.md` is still accepted on import for externally-authored artifacts; `STATE.md` remains the ongoing-work file. The historical provenance mentions in `references/shared/RESEARCH-2026-04.md` are left intact (they describe the source skill). This aligns drifted documentation to the already-canonical name; it does not move the contract.
- **Artifact-map alignment** across `README.md`, `MIGRATION.md`, and `SKILL.md`: the repo artifact now reads `.repo-ready/SCAFFOLD.md` (scaffold mode) with `.repo-ready/AUDIT-REPORT.md` noted for Mode B audits; the deploy and observe primaries now read `.deploy-ready/DEPLOY.md` and `.observe-ready/OBSERVE.md` (previously simplified to `STATE.md` in README and MIGRATION), matching SKILL.md's produces table.
- **Reference-budget guidance** (`AGENTS.md`, `SKILL.md`, `CONTRIBUTING.md`): the "~80 references at 5-15K" claim was inaccurate (the catalog is ~165 files, several well over 25K). Reworded to reflect reality and to name `domain-considerations.md` and `login-and-auth-pages.md` as split candidates.
- **Documentation drift fixes**: corrected the `CODE_OF_CONDUCT.md` enforcement links from the stale `aihxp/repo-ready` slug to `aihxp/arc-ready`; added the two new lint checks to the `MAINTAINING.md` lint-checks table; refreshed the `0.1.5` version placeholder in the bug-report issue template to `1.0.1`; clarified in `MIGRATION.md` that `trigger-disambiguation.md` is retained as a reference rather than removed.

### Added

- `scripts/lint.sh` gains two checks: `relative-links-resolve` (every markdown link to a real reference resolves from the linking file's directory) and `skill-version-body` (SKILL.md body version strings match the frontmatter). Both run in CI on push and pull request.

### Why a patch, not a minor

Bug-fix and consistency release. No new content, no new failure-mode patterns, no change to the discipline or the artifact-path contract. The stack-filename reconciliation aligns drifted documentation to the `STACK.md` name the dogfood and the v0.1.1 decision record already established.

## [1.0.0] - 2026-05-14

Stable contract release. Makes Pillars the standard agent-memory layer for file-system projects shaped by arc-ready, while keeping every canonical `.<tier>-ready/` artifact authoritative.

### Added

- `references/building/pillars-integration.md`: required memory-layer bridge from arc-ready artifacts to a Pillars-compatible `AGENTS.md` plus `agents/*.md` files. The mapping covers context, repo, stack, arch, quality, deploy, observe, security, UI, data, and auth pillars.
- `SKILL.md` Tier 2.1 sub-step 15: loads the Pillars memory layer for every file-system project.
- README stability-promise section that defines the intended 1.0 contract for canonical artifacts, Pillars floor memory, source-backed pillars, and adoption blockers.
- README documentation map for new users, ready-suite migrants, maintainers, contributors, and agents changing emitted project memory.
- MIGRATION Pillars adoption procedure for projects imported from the eleven-skill suite.
- CONTRIBUTING documentation-change checklist for public contract edits.
- MAINTAINING 1.0 stabilization checklist for a non-breaking major release.

### Changed

- `references/orchestration/agents-md-template.md` now emits a Pillars-compatible AGENTS.md by default, points at `.arc-ready/PROGRESS.md`, uses tier names, and documents how Pillars owns decomposed project memory.
- `SKILL.md` AGENTS.md emit-and-respect rules now require the Pillars memory layer for file-system projects unless adoption is explicitly blocked and recorded.
- `scripts/dogfood-smoke.sh` now verifies the Pillars loader, the mandatory `agents/context.md` and `agents/repo.md` floor pillars, and one source-backed stack pillar with artifact provenance and routing metadata.

### Why 1.0

This is a non-breaking stabilization release. The canonical artifact paths remain unchanged, but the project now declares the combined artifact contract and Pillars memory contract stable for downstream agents and orchestrators.

## [0.1.6] - 2026-05-09

Operational-validation pass. Closes the remaining gaps from the post-v0.1.5 evaluation: untested resume-protocol heuristic, no end-to-end smoke test, oversized description for Cursor's per-rule limit. Adds CI integration of the smoke test.

### Added

- `scripts/dogfood-smoke.sh`: seven-test operational smoke test covering drift-detection (happy path + synthetic drift), next-sub-step heuristic, artifact-path contract reachability for all eleven canonical paths, AGENTS.md emit-respect (existing-respected and absent cases), and the critical-finding gate logic. All seven tests pass against a synthetic mid-arc project. Run with `bash scripts/dogfood-smoke.sh [--verbose]`.
- CI workflow runs the smoke test on every push and PR. Smoke-test failure is a CI failure.
- `.cursorrules` (1,754 chars; under Cursor's per-rule 2KB recommendation): slim Cursor-adapter rule with the trigger surface and a pointer to the full SKILL.md. Lets Cursor users install arc-ready under tighter rule-size constraints. The full SKILL.md description (2,558 chars) is fine for Claude Code, Codex, and any harness with a 4KB practical ceiling on frontmatter.

### Changed

- `SKILL.md` resume-protocol shell snippet: rewritten to walk tiers in dependency order (1.1 -> 1.2 -> ... -> 3.4), treat `skipped` as a complete status, and resolve next-sub-step against the dependency-order traversal rather than file-order pattern matching. The smoke test verifies it returns `1.2` correctly when PRD is imported and ARCH is in-flight (the bug v0.1.5 acknowledged).

### Validated

- **Description size analysis**: 2,558 chars / ~639 tokens. Under the practical 4KB ceiling for Claude Code, Codex, Antigravity, Pi, OpenClaw. Over the 2KB recommendation for Cursor; addressed via `.cursorrules` adapter.
- **Trigger collision analysis (static)**: 63 unique trigger phrases extracted; no generic single-word triggers; all are domain-specific phrases. Low collision risk against general-purpose skills.
- **Operational smoke test**: 7/7 tests pass on a synthetic mid-arc project. Covers the load-bearing operational properties (drift detection, dependency-ordered next-sub-step, AGENTS.md emit-respect, critical-finding gate).

### Still untested (requires live harnesses)

- Functional agent execution: an actual agent loaded with arc-ready's SKILL.md running through Tier 0 -> Tier 3 on a real or fictional product. Out of scope for a build script; tested in a session.
- Trigger routing on live harnesses: empirical measurement of how Claude Code's, Codex's, Cursor's, Windsurf's skill routers score arc-ready against other installed skills.
- Token cost on real invocations: actual cache behavior across the eight compatible_with harnesses.

These are operational properties that require live measurement. The static and structural validations above are the maximum buildable validation.

### Why a patch, not a minor

Refines an inline heuristic; adds a smoke test + adapter file; no discipline change. arc-ready remains faithful consolidation.

## [0.1.5] - 2026-05-09

Repo-hygiene and discoverability pass. Closes the C-territory gaps surfaced by the post-build self-evaluation: missing OSS scaffolding files, no plugin marketplace entry, large/flat Tier 2.2 sub-step list, README without quickstart or status badges. No discipline change; no new patterns.

### Added

- `CODE_OF_CONDUCT.md`: Contributor Covenant (lifted from the suite's repo-ready dogfood).
- `.github/ISSUE_TEMPLATE/bug_report.yml`: structured bug-report form covering version, harness, mode, tier, reproduction, expected, actual.
- `.github/ISSUE_TEMPLATE/feature_request.yml`: feature-request form with scope-check (faithful-consolidation discipline reminder).
- `.github/ISSUE_TEMPLATE/taxonomy_question.yml`: dedicated form for "behavior that feels like a failure but does not map to a named pattern" - the load-bearing edge case for the pattern catalog.
- `.github/pull_request_template.md`: PR checklist covering type-of-change, discipline, versioning, lint, cross-references.
- `.github/dependabot.yml`: weekly GitHub Actions update PRs (markdown-only repo; ecosystem updates are limited to CI infra).
- `plugins/arc-ready/.claude-plugin/plugin.json`: Claude Code plugin marketplace entry. Symlinks to the repo's SKILL.md and references/ to avoid content duplication.
- `README.md` quickstart block with concrete first command, status badges (lint, release, license).

### Changed

- `SKILL.md` Tier 2.2 sub-step list: added a six-cluster navigation aid (Foundations / Quality / Polish / Scale and i18n / Engagement and ops / Integration and testing) before the 35 numbered sub-steps. Substantive content unchanged; navigation only.

### Operationally smoke-tested

Resume protocol shell snippet from SKILL.md was simulated against a synthetic `.arc-ready/PROGRESS.md` showing PRD imported, ARCH in-flight, others pending. The drift-detection logic correctly identified no drift; the next-sub-step heuristic returned an approximate first-pending row (refinement opportunity for v0.1.6: tighten the heuristic to skip Tier 0 in-flight when downstream tiers are in-flight).

### Why a patch, not a minor

Repo-hygiene additions and a navigation-aid edit. No content discipline change. Faithful consolidation preserved.

## [0.1.4] - 2026-05-09

### Added

- `references/orchestration/trigger-disambiguation.md`: ported from the eleven-skill suite hub's `references/TRIGGER-DISAMBIGUATION.md` (99-line phrase-to-tier-sub-step disambiguation table). v0.1.0 had claimed this content was "folded into SKILL.md mode-detection," but a content-fidelity audit (compare arc-ready vs source) revealed the disambiguation table itself was missing. Restored verbatim with the `<skill>-ready` -> `Tier X.Y (NAME)` vocabulary substitution applied to the canonical-skill column. Registered in SKILL.md references table.
- Disambiguation table covers the dominant overlap cases: "set up CI" (Tier 2.1) vs "CI/CD pipeline" (Tier 3.1), "ADR" (Tier 1.2 vs 1.4), "trust boundaries" (Tier 1.2 declare vs Tier 3.4 verify), "runbook" (Tier 3.2 vs 3.4), "audit" (Tier 2.1 vs 3.4), and ~20 more.

### Why a patch, not a minor

Closes a content-fidelity gap from v0.1.0. No new patterns; no discipline change; this is the missing reference, not a new contribution. The fidelity audit run after this release should now show zero missing source content (excluding intentional drops: SUITE.md, install.sh, plugins/, PLUGIN-RESEARCH.md - all hub-specific to the multi-repo era).

## [0.1.3] - 2026-05-09

### Fixed

Standalone-repo cleanup. arc-ready had no operational dependencies on the eleven sibling repos (no submodules, no required external files) but its inherited reference content still mentioned sibling-repo paths in prose, which made the repo *feel* coupled even though it wasn't. Sweeps applied:

- `production-ready/ORCHESTRATORS.md` (in inherited prose) rewritten to `references/shared/ORCHESTRATORS.md` across all reference files. The ORCHESTRATORS content is in arc-ready; the citations now point inside arc-ready.
- Bare `references/<file>.md` paths in `references/orchestration/*.md` (which assumed the source skills' flat references/ layout) rewritten to tier-prefixed paths (`references/orchestration/foo.md`, `references/shared/RESEARCH-2026-04.md`, etc.).
- Bare `references/<file>.md` paths in `references/building/questioning.md` rewritten to same-tier sibling references (no `references/` prefix needed since the file is itself in `references/building/`).
- Cursor-handoff prose in `references/orchestration/handoff-protocols.md` rewritten from "open prd-ready's SKILL.md" (eleven-skill suite assumption) to "open arc-ready's SKILL.md and navigate to Tier 1.1" (single-skill reality). The historical inter-skill handoff pattern is annotated as preserved-for-reference; arc-ready's actual dispatch is intra-skill tier-routing.

After this sweep: zero references in `references/` to sibling-repo paths. The only sibling-repo mentions in arc-ready now live in `MIGRATION.md` (the intentional migration matrix showing former-path -> new-path) and `README.md`/`CHANGELOG.md`/`SECURITY.md` (predecessor acknowledgment, not coupling).

### Why a patch, not a minor

Path-rewrite cleanup. No content discipline change; no new failure-mode patterns; arc-ready remains a faithful consolidation. The repo is now standalone in name and feel: no inherited prose pretends arc-ready depends on sibling repos.

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

[1.0.0]: https://github.com/aihxp/arc-ready/releases/tag/v1.0.0
[0.1.6]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.6
[0.1.5]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.5
[0.1.4]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.4
[0.1.3]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.3
[0.1.2]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.2
[0.1.1]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.1
[0.1.0]: https://github.com/aihxp/arc-ready/releases/tag/v0.1.0
