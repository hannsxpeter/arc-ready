# arc-ready

[![lint](https://github.com/hannsxpeter/arc-ready/actions/workflows/lint.yml/badge.svg)](https://github.com/hannsxpeter/arc-ready/actions/workflows/lint.yml)
[![release](https://img.shields.io/badge/release-v1.1.0-blue)](https://github.com/hannsxpeter/arc-ready/releases/tag/v1.1.0)
[![version](https://img.shields.io/badge/source-1.1.0-blue)](CHANGELOG.md)
[![agent skills](https://img.shields.io/badge/Agent%20Skills-compatible-2f6fed)](SKILL.md)
[![hannsxpeter/pillars](https://img.shields.io/badge/hannsxpeter%2Fpillars-standard-0f766e)](https://github.com/hannsxpeter/pillars)
[![smoke](https://img.shields.io/badge/smoke-12%2F12-brightgreen)](scripts/dogfood-smoke.sh)
[![eval](https://img.shields.io/badge/eval-14%2F14-brightgreen)](EVALS.md)
[![license](https://img.shields.io/github/license/hannsxpeter/arc-ready)](LICENSE)

A single AI skill that takes software from raw idea through PRD, architecture, roadmap, stack selection, repository scaffolding, implementation, deploy pipeline, observability, launch, and adversarial hardening. It routes web applications, APIs and services, CLIs and SDKs, mobile and desktop applications, data and ML systems, and infrastructure projects through form-specific gates. The full arc, mechanically enforced.

arc-ready is the evolution of [hannsxpeter/ready-suite](https://github.com/hannsxpeter/ready-suite): same discipline, same artifact contract, one install instead of eleven coordinated skills. It also standardizes on [hannsxpeter/pillars](https://github.com/hannsxpeter/pillars) for task-routed agent memory, so future coding agents can load durable project context without rereading every arc artifact.

## Quickstart

```bash
# Claude Code
git clone https://github.com/hannsxpeter/arc-ready ~/.claude/skills/arc-ready

# Then in any project, invoke a tier sub-step by saying any of the trigger phrases.
# Greenfield: "I have an idea for X. Walk me through to launch."
# Existing-codebase gap-fill: "Write a PRD for this app."
# Audit: "Audit the architecture in .architecture-ready/ARCH.md."
```

The skill produces artifacts at canonical `.<tier>-ready/<ARTIFACT>.md` paths in the project directory and emits Pillars-compatible agent memory for future work. See [Artifact map](#artifact-map) below for the full path table.

## Documentation map

- New users: read Quickstart, What arc-ready does, Installation, and Artifact map.
- Existing ready-suite users: read [MIGRATION.md](MIGRATION.md), especially the artifact contract and Pillars adoption notes.
- Maintainers: read [MAINTAINING.md](MAINTAINING.md) for release rituals, official standards validation, and evidence requirements.
- Evaluators: read [EVALS.md](EVALS.md) for deterministic checks, live-harness cases, and scoring rules.
- Contributors: read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) before editing load-bearing files.
- Agents changing emitted project memory: read `references/orchestration/agents-md-template.md` and `references/building/pillars-integration.md` together.

## Why arc-ready

The eleven-skill suite worked. It still works; it remains shipped, mechanically enforced, and dogfooded at [hannsxpeter/ready-suite-example](https://github.com/hannsxpeter/ready-suite-example). Adoption friction was the problem: eleven skills to install, twelve repos to track, byte-identical SUITE.md ritual, coordinated patches across repos. arc-ready preserves the discipline (every named failure mode, every grep test, every workflow guard) and removes the multi-repo overhead.

You install one skill. You read one SKILL.md. You patch one repo. The artifacts that arc-ready produces (`.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, etc.) are at the same canonical paths the eleven-skill suite established, so the dogfood example still verifies and downstream consumers (orchestrators like GSD, BMAD, Spec Kit, Superpowers) do not have to change.

## What arc-ready does

The arc is what every software project traverses, ordered or not, named or not:

```
idea -> PRD -> architecture -> roadmap -> stack -> repo -> app -> deploy -> observe -> launch / harden
```

arc-ready makes the arc explicit, gates each tier on a verified artifact from the prior tier, and refuses the dominant AI failure modes at every step:

- **Tier 0 (orchestration).** Mode detection, intent capture, progress ledger, Pillars-compatible AGENTS.md emission, scope-fence enforcement.
- **Tier 1 (planning).** PRD, architecture, roadmap, stack decision. Each gates the next.
- **Tier 2 (building).** Form-aware repo scaffolding (production-grade structure, docs, CI/CD, quality tooling, Pillars agent memory), then user-operable vertical slices with no scaffolds or placeholders.
- **Tier 3 (shipping).** Deploy pipeline (same-artifact promotion, expand-contract migrations, real canaries with stop rules), observability (SLOs bound to journeys, runbooks executed at least once, error-budget policies), launch (substitution-test-resistant landing pages, OG cards that render, source-attributed waitlists), adversarial hardening (OWASP walkthroughs, compliance-control-to-code-evidence mapping, actionable findings).

Modes:

- **Mode A**: full arc, greenfield. The default.
- **Mode B**: specific tier, existing codebase. Routes to the tier filling the gap.
- **Mode C**: retroactive audit. Scores existing artifacts against arc-ready discipline.
- **Mode D**: multi-repo suite layout. Designs collections of related repos.

## Product-form and domain routing

arc-ready selects one primary project form before it composes domain guidance. This keeps browser assumptions out of headless services, command-line tools, native clients, data pipelines, and infrastructure work.

| Project form | Representative completion evidence |
|---|---|
| Web application | Accessible user journey across UI, backend, persistence, permissions, and failure states |
| API or service | Versioned contract, authenticated round trip, idempotency, failure semantics, and operable telemetry |
| CLI or SDK | Installable artifact, stable interface, consumer example, exit or error contract, and compatibility test |
| Mobile or desktop | Native lifecycle, offline or degraded behavior, permissions, packaging, and upgrade path |
| Data or ML | Reproducible pipeline, data contract, lineage, quality checks, evaluation, and rollback or recovery |
| Infrastructure or IaC | Validated plan, policy checks, safe apply, drift detection, state protection, and rollback |

Domain guidance then composes four axes: project form, product archetype, industry overlay, and regulatory overlay. See the [product-form router](references/building/product-form-router.md), [domain registry](references/building/domain-registry.md), and focused [domain router](references/building/domain-considerations.md).

## Installation

This is an Agent Skills compatible skill. Install per your harness:

- **Claude Code**: `/skills install` from this repo, or symlink the repo into `~/.claude/skills/arc-ready/`.
- **Codex CLI**: per the Codex Skills install protocol.
- **Cursor / Windsurf**: copy `SKILL.md` into the rules directory and reference it.
- **Antigravity / Pi / OpenClaw**: per the harness's Agent Skills standard install path.
- **Any AGENTS.md-aware harness** (Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin): the project's `AGENTS.md` (emitted by Tier 0 Step 0.6 if absent) describes the Pillars loading protocol and names the artifact map; the harness consumes the artifacts directly.

## Triggers

arc-ready triggers on any of the following phrases (consolidated trigger surface from the eleven-skill suite):

**Orchestration / kickoff**: kickoff, new project from scratch, walk me through idea to launch, help me ship it end-to-end, orchestrate the whole arc, I have an idea what next.

**Planning**: write a PRD, product spec, requirements doc, one-pager, product brief, problem statement, design the architecture, system diagram, monolith or microservices, integration shape, service boundaries, data architecture, ADR, trust boundaries, C4 diagram, build a roadmap, milestone plan, quarterly plan, sequence the work, Now-Next-Later, Shape Up cycle, PI planning, what stack should I use, Next.js vs Remix, pick a database, Postgres or Mongo, which auth provider, hosting recommendation.

**Building**: set up a repo, initialize a project, add documentation, set up CI, configure linting, add a README, set up GitHub Actions, make my repo professional, add contributing guidelines, set up release automation, adopt Pillars, task-routed agent memory, build a web app, API or service, CLI or SDK, mobile or desktop app, data or ML system, infrastructure project, dashboard, admin panel, internal tool, or CRUD app.

**Shipping**: deploy this, CI/CD pipeline, promote to staging, zero-downtime migration, expand-contract, rollback, canary, blue/green, progressive rollout, first deploy, environment parity, GitHub Actions pipeline, GitOps, add monitoring, define an SLO, alerts when X, add Datadog / Honeycomb / Sentry / Grafana, write a runbook, on-call setup, post-mortem, structured logging, OpenTelemetry, distributed tracing, error budget policy, launch my product, build a landing page, Product Hunt, Show HN, waitlist, OG card, launch-day SEO, press kit, launch week plan, adversarial review, pen-test prep, OWASP walkthrough, SOC 2 / HIPAA / PCI-DSS / GDPR gap check, responsible disclosure, bug bounty, post-incident hardening, security review before launch.

## Repo layout

```
arc-ready/
  SKILL.md                       The orchestrator body.
  CHANGELOG.md                   Version history.
  README.md                      This file.
  LICENSE                        MIT.
  AGENTS.md                      Cross-tool agent brief for arc-ready itself.
  CLAUDE.md -> AGENTS.md         Symlink (Claude Code overlay).
  SECURITY.md                    Vulnerability reporting channel.
  CONTRIBUTING.md                Contribution guide.
  MAINTAINING.md                 Single-repo release rituals.
  MIGRATION.md                   Migration guide for ready-suite users.
  EVALS.md                       Evaluation model and release evidence.
  evals/cases/                   Live-harness prompts and rubrics.
  scripts/lint.sh                Single-repo meta-linter.
  scripts/eval.sh                Deterministic behavioral checks.
  scripts/release-check.sh       Release-grade validation entry point.
  requirements/skills-ref.txt    Pinned official validator dependency.
  config/unicode-baseline.txt    Reviewed inherited Unicode counts.
  .github/
    CODEOWNERS                   Code ownership.
    workflows/lint.yml           CI lint job.
  references/
    orchestration/               Tier 0 references.
    planning/                    Tier 1 references (PRD, ARCH, ROADMAP, STACK).
    building/                    Tier 2 references (REPO, PRODUCTION).
      domains/                   Focused product and industry profiles.
    shipping/                    Tier 3 references (DEPLOY, OBSERVE, LAUNCH, HARDEN).
    shared/                      Cross-tier references (RESEARCH, ORCHESTRATORS).
```

## Artifact map

arc-ready writes to canonical `.<tier>-ready/` directories. The contract is unchanged from the eleven-skill suite.

| Tier | Artifact | Path |
|---|---|---|
| 0 | Arc progress ledger | `.arc-ready/PROGRESS.md` |
| 1.1 | Product Requirements | `.prd-ready/PRD.md` (+ HANDOFF, AUDIT) |
| 1.2 | Architecture | `.architecture-ready/ARCH.md` (+ HANDOFF, adr/) |
| 1.3 | Roadmap | `.roadmap-ready/ROADMAP.md` (+ HANDOFF, retrospectives/) |
| 1.4 | Stack decision | `.stack-ready/STACK.md` |
| 2.1 | Repo scaffolding | repo root (`.github/`, `package.json`, README, etc.) + `.repo-ready/SCAFFOLD.md` (or `.repo-ready/AUDIT-REPORT.md` for Mode B audits) |
| 2.2 | Production state | `.production-ready/STATE.md` |
| 3.1 | Deploy state | `.deploy-ready/DEPLOY.md` (+ PLAN, TOPOLOGY, STATE) |
| 3.2 | Observe state | `.observe-ready/OBSERVE.md` (+ SLOs, INDEPENDENCE, STATE) |
| 3.3 | Launch state | `.launch-ready/STATE.md` (+ runbook, copy, and `.launch-ready/PREPUBLICATION.md` before public activation) |
| 3.4 | Hardening findings | `.harden-ready/FINDINGS.md` (+ remediation) |
| 0/2.1 | Cross-tool agent brief | Pillars-compatible `AGENTS.md` at project root |
| 2.1 | Pillars agent memory | `agents/context.md`, `agents/repo.md`, and source-backed `agents/*.md` |

Tier 2.1 adopts [hannsxpeter/pillars](https://github.com/hannsxpeter/pillars) for file-system projects by emitting a Pillars-compatible `AGENTS.md` plus task-routed `agents/*.md` files distilled from arc-ready artifacts. This is a downstream project-memory layer; it does not replace the canonical artifact paths above.

## Stability promise

The intended 1.0 contract is stable and intentionally small:

- Canonical `.<tier>-ready/` artifact paths remain the source of truth for arc decisions.
- File-system projects get a Pillars-compatible `AGENTS.md` plus `agents/context.md` and `agents/repo.md` as the floor memory layer.
- Source-backed `agents/*.md` files may be added when upstream arc artifacts contain enough evidence. Stub pillars must say they are stubs rather than inventing decisions.
- Existing non-Pillars `AGENTS.md` files are respected. arc-ready records `pillars: adoption-blocked-existing-agents` instead of silently overwriting them.
- There is no non-Pillars distribution. Pillars is the project-memory standard; exceptions are recorded blockers.
- Public activation requires a fresh pre-publication record tied to the current hardening revision. Launch preparation alone never authorizes publication.

## Status

The current v1.1.0 release adds explicit product forms, composable domain guidance, progressive disclosure, deterministic and live-harness evaluations, official Agent Skills validation, current OWASP Top 10:2025 routing, and a serialized public activation gate. The 1.0 artifact contract remains stable. Every named failure mode from the eleven source skills remains available under `references/<tier>/<skill>-antipatterns.md`.

The eleven-skill suite at [hannsxpeter/ready-suite](https://github.com/hannsxpeter/ready-suite) remains available and supported for users who prefer the multi-repo footprint.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Single-repo release rituals are in [MAINTAINING.md](MAINTAINING.md).

## Migration from ready-suite

If you currently use the eleven-skill hannsxpeter/ready-suite and want to switch to arc-ready, see [MIGRATION.md](MIGRATION.md). The artifacts produced are unchanged; only the install footprint is.
