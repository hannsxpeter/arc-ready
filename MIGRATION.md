# Migration: from aihxp/ready-suite to arc-ready

If you currently use the eleven-skill aihxp/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready) and want to switch to arc-ready, this guide covers the install change, trigger surface, where each former skill's content now lives, and the artifact contract.

The TL;DR: same content, same discipline, same artifacts, one install. The eleven-skill suite remains available; arc-ready is the recommended starting point for new projects.

## Install change

Before:

```bash
# Eleven separate skills, each in its own repo.
git clone https://github.com/aihxp/kickoff-ready ~/.claude/skills/kickoff-ready
git clone https://github.com/aihxp/prd-ready ~/.claude/skills/prd-ready
git clone https://github.com/aihxp/architecture-ready ~/.claude/skills/architecture-ready
git clone https://github.com/aihxp/roadmap-ready ~/.claude/skills/roadmap-ready
git clone https://github.com/aihxp/stack-ready ~/.claude/skills/stack-ready
git clone https://github.com/aihxp/repo-ready ~/.claude/skills/repo-ready
git clone https://github.com/aihxp/production-ready ~/.claude/skills/production-ready
git clone https://github.com/aihxp/deploy-ready ~/.claude/skills/deploy-ready
git clone https://github.com/aihxp/observe-ready ~/.claude/skills/observe-ready
git clone https://github.com/aihxp/launch-ready ~/.claude/skills/launch-ready
git clone https://github.com/aihxp/harden-ready ~/.claude/skills/harden-ready
```

After:

```bash
# One skill.
git clone https://github.com/aihxp/arc-ready ~/.claude/skills/arc-ready
```

For other harnesses (Codex, Cursor, Windsurf, Antigravity, Pi, OpenClaw), install per the harness's Agent Skills standard install path.

## Trigger surface

The eleven-skill suite had per-skill triggers ("write a PRD" routed to prd-ready; "deploy this" routed to deploy-ready). arc-ready inherits the union of every named trigger and routes internally to the right tier sub-step.

| Trigger phrase | Former skill | Now in arc-ready |
|---|---|---|
| kickoff, walk me through idea to launch, orchestrate the whole arc | kickoff-ready | Tier 0 + full Mode A dispatch |
| write a PRD, product spec, requirements doc | prd-ready | Tier 1.1 |
| design the architecture, system diagram, ADR | architecture-ready | Tier 1.2 |
| build a roadmap, milestone plan, Now-Next-Later | roadmap-ready | Tier 1.3 |
| what stack should I use, pick a database | stack-ready | Tier 1.4 |
| set up a repo, add CI, GitHub Actions | repo-ready | Tier 2.1 |
| dashboard, admin panel, internal tool | production-ready | Tier 2.2 |
| deploy this, CI/CD pipeline, expand-contract | deploy-ready | Tier 3.1 |
| add monitoring, define an SLO, write a runbook | observe-ready | Tier 3.2 |
| launch my product, build a landing page, Product Hunt | launch-ready | Tier 3.3 |
| adversarial review, pen-test prep, OWASP walkthrough | harden-ready | Tier 3.4 |

The full trigger list is in `SKILL.md` frontmatter and `README.md`.

## Where former skill content lives now

Each former skill's content is preserved in arc-ready under the corresponding tier folder.

### kickoff-ready

| Former path | New path |
|---|---|
| `kickoff-ready/SKILL.md` | Consolidated into `SKILL.md` Tier 0 (Steps 0.1 - 0.6) |
| `kickoff-ready/references/kickoff-antipatterns.md` | `references/orchestration/kickoff-antipatterns.md` |
| `kickoff-ready/references/sequencing-rules.md` | `references/orchestration/sequencing-rules.md` |
| `kickoff-ready/references/handoff-protocols.md` | `references/orchestration/handoff-protocols.md` |
| `kickoff-ready/references/progress-tracking.md` | `references/orchestration/progress-tracking.md` |
| `kickoff-ready/references/scope-fence.md` | `references/orchestration/scope-fence.md` |
| `kickoff-ready/references/agents-md-template.md` | `references/orchestration/agents-md-template.md` |
| `kickoff-ready/references/RESEARCH-2026-04.md` | `references/shared/RESEARCH-2026-04.md` (consolidated) |

### prd-ready, architecture-ready, roadmap-ready, stack-ready

| Former path pattern | New path pattern |
|---|---|
| `<planning-skill>/SKILL.md` | Consolidated into `SKILL.md` Tier 1.1 / 1.2 / 1.3 / 1.4 |
| `<planning-skill>/references/*.md` | `references/planning/*.md` (filenames preserved) |
| `<planning-skill>/references/RESEARCH-2026-04.md` | `references/shared/RESEARCH-2026-04.md` (consolidated) |
| `<planning-skill>/references/EXAMPLE-*.md` | `references/planning/EXAMPLE-*.md` |

### repo-ready, production-ready

| Former path pattern | New path pattern |
|---|---|
| `<building-skill>/SKILL.md` | Consolidated into `SKILL.md` Tier 2.1 / 2.2 |
| `<building-skill>/references/*.md` | `references/building/*.md` (filenames preserved) |
| `production-ready/ORCHESTRATORS.md` | `references/shared/ORCHESTRATORS.md` |

### deploy-ready, observe-ready, launch-ready, harden-ready

| Former path pattern | New path pattern |
|---|---|
| `<shipping-skill>/SKILL.md` | Consolidated into `SKILL.md` Tier 3.1 / 3.2 / 3.3 / 3.4 |
| `<shipping-skill>/references/*.md` | `references/shipping/*.md` (filenames preserved) |
| `<shipping-skill>/references/RESEARCH-2026-04.md` | `references/shared/RESEARCH-2026-04.md` (consolidated) |

### Hub (aihxp/ready-suite)

| Former path | New equivalent |
|---|---|
| `ready-suite/SUITE.md` | Removed. arc-ready is one repo; the byte-identical SUITE.md ritual does not apply. |
| `ready-suite/ORCHESTRATORS.md` | `references/shared/ORCHESTRATORS.md` |
| `ready-suite/MAINTAINING.md` | `MAINTAINING.md` (rewritten for single-repo rituals; the v2.5.12 precedent recovery story and multi-repo coordinated-patch matrix are removed). |
| `ready-suite/scripts/lint.sh` | `scripts/lint.sh` (rewritten for single-repo checks; suite-md-sync removed; trigger-overlap removed). |
| `ready-suite/references/TRIGGER-DISAMBIGUATION.md` | Folded into `SKILL.md` mode-detection and tier-dispatch sections. |
| `ready-suite/install.sh`, `uninstall.sh` | Not needed. Standard Agent Skills install applies. |

## Artifact contract: unchanged

The most important property of the migration is that artifact paths are identical. Downstream consumers (orchestrators like GSD, BMAD, Spec Kit, Superpowers; the dogfood at `aihxp/ready-suite-example`) consume artifacts at:

- `.prd-ready/PRD.md`
- `.architecture-ready/ARCH.md`
- `.roadmap-ready/ROADMAP.md`
- `.stack-ready/DECISION.md`
- `.repo-ready/AUDIT-REPORT.md`
- `.production-ready/STATE.md`
- `.deploy-ready/STATE.md`
- `.observe-ready/STATE.md`
- `.launch-ready/STATE.md`
- `.harden-ready/FINDINGS.md`

These paths are stable across the eleven-skill suite and arc-ready. arc-ready also writes its own `.arc-ready/PROGRESS.md` for the cross-tier ledger.

arc-ready file-system projects also get Pillars-compatible agent memory:

- `AGENTS.md` with the Pillars loading protocol and an arc-ready artifact map.
- `agents/context.md` and `agents/repo.md` as mandatory floor pillars.
- Additional source-backed `agents/*.md` files when the relevant arc artifacts exist.

The arc artifacts remain authoritative. Pillars is the project-memory layer for future agent work.

### Pillars adoption during migration

For projects created under the eleven-skill suite, the migration path is additive:

1. Keep every existing `.<tier>-ready/` artifact in place.
2. Add `.arc-ready/PROGRESS.md` to record imported tier state.
3. If `AGENTS.md` is absent, emit the Pillars-compatible loader and the `agents/context.md` and `agents/repo.md` floor pillars.
4. If `AGENTS.md` already exists and is Pillars-compatible, preserve it and add missing arc-ready artifact-map context only where it fits cleanly.
5. If `AGENTS.md` exists and conflicts with Pillars, leave it untouched and record `pillars: adoption-blocked-existing-agents` in `.arc-ready/PROGRESS.md`.

Do not rewrite old arc artifacts into Pillars. Pillars points future agents toward the right decisions; the artifact files remain the decision record.

## Discipline: unchanged

Every named failure mode, every grep test, every workflow guard from the source eleven skills is preserved in arc-ready. The full per-tier catalogs (with citations, severity, remediation) are at:

- `references/orchestration/kickoff-antipatterns.md`
- `references/planning/prd-antipatterns.md`
- `references/planning/architecture-antipatterns.md`
- `references/planning/roadmap-antipatterns.md`
- `references/planning/stack-antipatterns.md`
- `references/building/repo-antipatterns.md`
- `references/building/production-antipatterns.md`
- `references/shipping/deploy-antipatterns.md`
- `references/shipping/observe-antipatterns.md`
- `references/shipping/launch-antipatterns.md`
- `references/shipping/harden-antipatterns.md`

The "have-nots" sections in `SKILL.md` consolidate the load-bearing patterns from each catalog, with each pattern keeping its name and grep target.

## Running both

The eleven-skill suite and arc-ready can coexist on the same machine. The trigger surface overlaps; the harness will route to whichever skill matches first. To prefer arc-ready on a project, ensure arc-ready is installed and the per-skill suite repos are not installed for that project.

There is no harm in keeping both around during a transition period. The artifact contracts are the same, so a project kicked off under the eleven-skill suite is fully consumable by arc-ready (Mode A or B with imports), and vice versa.

## When to switch

Switch when:

- You are starting a new project (the install footprint difference is most visible here).
- You are onboarding a new team member (one skill to install instead of eleven).
- You are integrating with an orchestrator (downstream consumer needs only one trigger to route).

Stay on the eleven-skill suite when:

- You have customized one or more individual skills' references and the per-skill repo is your version-control surface.
- You are running a CI lint that depends on the byte-identical SUITE.md ritual across suite repos.
- You prefer the per-skill changelog granularity (eleven CHANGELOG.md files, each tracking one skill's evolution).

Both are valid. arc-ready is the recommended path; the eleven-skill suite is the supported alternative.

## Open questions

- **Trigger collision**: if both arc-ready and the eleven-skill suite are installed, the harness may route ambiguously. Recommended posture: install one or the other, not both, on a given machine.
- **Dogfood maintenance**: `aihxp/ready-suite-example` continues to dogfood the eleven-skill suite. arc-ready's dogfood acceptance test is that the same artifacts (at the same paths) are reproducible from arc-ready. If they diverge, the dogfood is the authority.
- **Pillars adoption for imported projects**: a project started under the eleven-skill suite may not have `agents/*.md`. When arc-ready imports it, Tier 2.1 should add the Pillars memory layer unless an existing `AGENTS.md` blocks adoption.
