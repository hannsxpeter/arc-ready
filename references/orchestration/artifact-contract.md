# Artifact and State Contract

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Suite membership

arc-ready is a single skill, not a suite. It is the consolidated successor to the eleven-skill hannsxpeter/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready). The eleven-skill version remains available for users who prefer the multi-repo footprint; arc-ready is the recommended starting point for new projects.

The transition is documented in `MIGRATION.md`. Briefly: every named failure mode, every grep test, every workflow guard from the eleven skills exists in arc-ready under the corresponding tier folder. The artifact paths (`.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, etc.) are unchanged. The dogfood (`hannsxpeter/ready-suite-example`) verifies cleanly against arc-ready's tier dispatch.

## Consumes from upstream

arc-ready has no upstream skills. It triggers from raw user intent and reads from disk to detect the import mode.

When the agent starts, it inventories existing arc artifacts and adjusts the dispatch:

| If present | Effect | Recorded as |
|---|---|---|
| `.prd-ready/PRD.md` | Skip Tier 1.1; verify import; advance to 1.2 | `1.1: imported` in PROGRESS.md |
| `.architecture-ready/ARCH.md` | Skip 1.2; verify; advance | `1.2: imported` |
| `.roadmap-ready/ROADMAP.md` | Skip 1.3; verify; advance | `1.3: imported` |
| `.stack-ready/STACK.md` or `.stack-ready/DECISION.md` | Skip 1.4; verify; advance | `1.4: imported` |
| Repo scaffolding presence (README.md, .github/workflows/*.yml, .repo-ready/SCAFFOLD.md) | Skip 2.1; verify scaffolding; advance | `2.1: imported` |
| `.production-ready/STATE.md` | Skip 2.2; verify | `2.2: imported` |
| `.deploy-ready/DEPLOY.md` or `.deploy-ready/STATE.md` | Skip 3.1; verify | `3.1: imported` |
| `.observe-ready/OBSERVE.md` or `.observe-ready/STATE.md` | Skip 3.2; verify | `3.2: imported` |
| `.launch-ready/STATE.md` | Skip 3.3; verify | `3.3: imported` |
| `.harden-ready/FINDINGS.md` | Skip 3.4; verify | `3.4: imported` |

If an imported artifact is present but the user wants to re-run the tier (because the input changed), the user explicitly invokes the tier and PROGRESS.md is rolled back from that point forward. Re-invocation is a recorded event, not silent overwrite.

## Produces for downstream

arc-ready produces the arc artifacts at canonical `.<tier>-ready/` paths. Downstream orchestrators (GSD, BMAD, Spec Kit, plain harnesses) consume these artifacts directly.

| Artifact | Path | Tier |
|---|---|---|
| Kickoff/arc progress ledger | `.arc-ready/PROGRESS.md` | Tier 0 |
| Product Requirements | `.prd-ready/PRD.md` (+ HANDOFF.md, AUDIT.md) | Tier 1.1 |
| Architecture | `.architecture-ready/ARCH.md` (+ HANDOFF.md, adr/NNN-*.md) | Tier 1.2 |
| Roadmap | `.roadmap-ready/ROADMAP.md` (+ HANDOFF.md, retrospectives/) | Tier 1.3 |
| Stack decision | `.stack-ready/STACK.md` (`.stack-ready/STATE.md` for ongoing work) | Tier 1.4 |
| Repo scaffold report | `.repo-ready/SCAFFOLD.md` (or `AUDIT-REPORT.md` for Mode B audits), plus the scaffolded files at repo root | Tier 2.1 |
| Production state | `.production-ready/STATE.md` | Tier 2.2 |
| Deploy plan and state | `.deploy-ready/DEPLOY.md` (current ship), `.deploy-ready/PLAN.md` (next ship), `.deploy-ready/TOPOLOGY.md` (environments), `.deploy-ready/STATE.md` (resume state) | Tier 3.1 |
| Observe state and SLOs | `.observe-ready/OBSERVE.md` (overview), `.observe-ready/SLOs.md` (per-journey SLOs), `.observe-ready/INDEPENDENCE.md` (telemetry-decoupling test), `.observe-ready/STATE.md` (resume state) | Tier 3.2 |
| Launch state | `.launch-ready/STATE.md` (+ runbook/, copy/) | Tier 3.3 |
| Hardening findings | `.harden-ready/FINDINGS.md` (+ remediation/) | Tier 3.4 |
| Pillars memory loader | `AGENTS.md` at project root (+ symlink `CLAUDE.md` -> `AGENTS.md`) | Tier 0 / 2.1 |
| Pillars floor memory | `agents/context.md`, `agents/repo.md`, plus source-backed `agents/*.md` | Tier 2.1 |

The artifact paths are stable. Downstream consumers can hard-code these paths and trust them. arc-ready does not move or rename artifacts as it evolves; the eleven-skill suite established the contract, and arc-ready preserves it.

## Session state and resume

The arc spans sessions. The planning tier alone can span days. The building tier can span weeks. The full arc routinely spans a month or more. Without a state file, every resume rediscovers the chain from scratch.

Maintain `.arc-ready/PROGRESS.md` as the source of truth about the arc. Read it first on every turn. If it conflicts with disk (artifacts present that PROGRESS.md does not record, or PROGRESS.md says done for a tier whose artifact is missing), trust disk and update PROGRESS.md.

Each tier's intermediate state lives in the tier's `.<tier>-ready/STATE.md` file. PROGRESS.md is the arc-level summary; the per-tier STATE files are the deep state.

The schema is in `references/orchestration/progress-tracking.md`. The resume protocol is the load-bearing defense against phantom resume. Run it every turn. Never trust the cached conversation about what tier or sub-step we are on.

## Handoff: ongoing operations is not arc-ready's job

arc-ready is one-shot per project. The arc is idea -> launch and hardening; what comes after the arc (sprint-by-sprint feature work, ongoing security hardening, ongoing observability tuning, ongoing roadmap re-planning) is the project's ongoing motion.

Hand off to a phase orchestrator after the arc completes. Options include:

- **GSD** (`gsd-*` slash commands in Claude Code): phase-based orchestration with discuss / plan / execute / verify / ship loops.
- **BMAD**: agile-method orchestration with explicit story and milestone management.
- **Spec Kit**: spec-driven development with intent / specification / plan / tasks loops.
- **Superpowers**: skill composition with brainstorm / plan / implement / verify loops.
- **The user's own process.** No orchestrator required; the artifacts at `.<tier>-ready/` paths are stable enough that any process can consume them.

The arc-ready / orchestrator boundary: arc-ready owns the arc. The orchestrator owns the iteration loop after the arc. PROGRESS.md is the handoff contract. See `references/shared/ORCHESTRATORS.md` for the integration patterns.

## Per-tier session-state schemas

Each tier's `.<tier>-ready/STATE.md` is the durable record of where the tier is and what it has produced. The schemas vary by tier; the load-on-demand pattern lives in the per-tier references. This section is the at-a-glance summary so an agent can read or write the right shape without round-tripping through references.

### `.arc-ready/PROGRESS.md` (Tier 0)

```markdown
# arc-ready PROGRESS

## Skill version: 1.1.0
## Last update: <ISO-8601 timestamp>
## Mode: A | B | C | D
## Harness: claude-code | codex | cursor | windsurf | antigravity | pi | openclaw | generic
## Project: <project name from kickoff intent>

## Kickoff intent
<one-paragraph user-quoted description; greenfield-or-not check; skip declarations; time budget>

## Tier ledger
- 0: <status> | <artifact: .arc-ready/PROGRESS.md> | <verified: ISO-8601>
- 1.1 (PRD): <status> | <artifact: .prd-ready/PRD.md> | <verified: ...>
- 1.2 (ARCH): <status> | <artifact: .architecture-ready/ARCH.md> | <verified: ...>
- 1.3 (ROADMAP): <status> | <artifact: .roadmap-ready/ROADMAP.md> | <verified: ...>
- 1.4 (STACK): <status> | <artifact: .stack-ready/STACK.md> | <verified: ...>
- 2.1 (REPO): <status> | <artifact: .repo-ready/SCAFFOLD.md + repo root> | <verified: ...>
- 2.2 (PRODUCTION): <status> | <artifact: .production-ready/STATE.md> | <verified: ...>
- 3.1 (DEPLOY): <status> | <artifact: .deploy-ready/DEPLOY.md> | <verified: ...>
- 3.2 (OBSERVE): <status> | <artifact: .observe-ready/OBSERVE.md> | <verified: ...>
- 3.3 (LAUNCH): <status> | <artifact: .launch-ready/STATE.md> | <verified: ...>
- 3.4 (HARDEN): <status> | <artifact: .harden-ready/FINDINGS.md> | <verified: ...>

## Resume verifications
- <ISO-8601>: next_sub_step: <derived>; disk-state hash: <mtime hash>

## Risk acceptances (only if Critical findings exist)
- finding: <id> | severity: critical | accepted: <ISO-8601> | owner: <name> | expires: <ISO-8601> | justification: <one-line>

## Out-of-scope refusals
- <ISO-8601>: <user-request> | refused: <named failure mode> | routed-to: <harness | tier-sub-step>

## Arc complete (only when arc finishes)
- per-tier summary table
- open items handed off to ongoing work
- recommended next-step orchestrator
- agents_md_emitted: path | existing-respected | guidance-text
```

`status` vocabulary: `pending`, `in-flight`, `done`, `skipped`, `imported`, `failed`, `re-invoked`. Silence is not a status. Every tier appears in the ledger.

### `.prd-ready/STATE.md` (Tier 1.1, when ongoing)

```markdown
# PRD STATE
- skill version, current tier (Brief / Spec / Full PRD / Launch-Ready PRD), mode (A-F)
- pre-flight answers
- active sections (problem, target user, success, requirements, NFRs, scope, risks, open questions, handoff, sign-off)
- sign-off ledger
- open questions blocking next tier
- last session note
```

### `.architecture-ready/STATE.md` (Tier 1.2, when ongoing)

```markdown
# Architecture STATE
- skill version, current tier (Sketch / Plan / Design / Spec)
- mode (A-D)
- consumed PRD version
- ADRs written so far
- open architectural questions blocking next tier
- last session note
```

### `.roadmap-ready/STATE.md` (Tier 1.3, when ongoing)

```markdown
# Roadmap STATE
- skill version, current tier (Sketch / Plan / Roadmap / Roadmap+ )
- mode (A-D)
- team capacity input
- consumed PRD version, consumed ARCH version
- horizons (Now / Next / Later) with current commitments and directions
- review cadence and last review date
- last session note
```

### `.stack-ready/STATE.md` (Tier 1.4, when ongoing)

```markdown
# Stack STATE
- skill version, current tier (Survey / Score / Decide / Decision)
- mode (A-D)
- domain profile selected
- shortlist with current scores and weights
- pairing-rule check status
- migration paths drafted
- last session note
```

### `.production-ready/STATE.md` (Tier 2.2)

```markdown
# Production STATE
- skill version, current tier (Scaffold / End-to-end / Tested / Polished)
- consumed PRD, ARCH, ROADMAP, STACK versions
- slice queue: pending / in-flight / done
- active architectural decisions (per ADR-NN)
- ADRs written this tier
- open questions blocking next slice
- last session note
```

### `.deploy-ready/STATE.md` (Tier 3.1)

```markdown
# Deploy STATE
- skill version, current tier (Sketch / Plan / Pipeline / Calendar)
- environments in play (dev, staging, prod, etc.)
- active pipelines and their last green build hashes
- in-progress expand/contract cycles
- rollback paths by service
- incidents logged this tier
- open questions blocking next deploy
- last session note
```

### `.observe-ready/STATE.md` (Tier 3.2)

```markdown
# Observe STATE
- skill version, tier reached (Sketch / Plan / Live / Tuned)
- installation status (pending / installation-ready) with controlled-fire evidence
- operational maturity (not-yet-evidenced / operationally-mature) with real-event evidence
- services and journeys
- SLOs active (per `.observe-ready/SLOs.md`)
- paper-SLO watchlist (numbers without policies)
- dashboards (per `.observe-ready/DASHBOARDS.md`)
- runbooks (per `.observe-ready/runbook/`)
- independence test status (per `.observe-ready/INDEPENDENCE.md`)
- incidents this quarter
- alert pruning last pass
- open questions blocking next tier
- last session note
```

### `.launch-ready/STATE.md` (Tier 3.3)

```markdown
# Launch STATE
- skill version, tier reached (Positioning / Surfaces / Channels / Live)
- mode (A-D)
- positioning (Step 1)
- landing page (Steps 2-4)
- OG cards (Step 6)
- SEO (Step 5)
- waitlist (Step 7)
- channels (Step 8)
- launch week runbook (Step 9)
- telemetry (Step 10)
- press kit and outreach status
- open questions blocking Tier 3 or Tier 4
- last session note
```

### `.harden-ready/STATE.md` (Tier 3.4)

```markdown
# Harden STATE
- skill version, tier reached (Walkthrough / Compliance / Pen-test / Continuous)
- mode (A-D)
- OWASP Top 10 verdicts (Web / API / LLM as applicable)
- compliance frameworks in scope and mapping status
- auth verification (per `.harden-ready/AUTH-VERIFICATION.md`)
- API verification (per `.harden-ready/API-VERIFICATION.md`)
- class-not-instance fixes (per `.harden-ready/CLASS-FIXES.md`)
- pen-test scope and last execution
- responsible disclosure surface
- findings open / fixed / accepted
- last session note
```

The schemas are intentionally short. The deep state lives in companion files at the tier's canonical paths (`.observe-ready/SLOs.md`, `.harden-ready/AUTH-VERIFICATION.md`, etc.); STATE.md is the index plus the resume hint. Reading STATE.md should take an agent under one minute and orient them to where the tier is.
