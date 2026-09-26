---
name: arc-ready
description: "Plan, build, ship, and audit software from idea to launch with durable artifacts on disk and script-checked gates: PRD, architecture, roadmap, stack, repo, implementation, deploy, observability, launch, and security hardening. Use for greenfield kickoff (walk me from idea to launch), filling one missing stage in an existing project, read-only audits of existing plans or code, multi-repo layouts, or requests to write a PRD, design architecture, sequence a roadmap, choose a stack, scaffold a repo, build a web app, API, CLI or SDK, mobile or desktop app, data or ML system, or infrastructure project, set up CI/CD, deploys, rollback, SLOs, alerts, or runbooks, prepare a launch, or run an OWASP or compliance review. Keeps a progress ledger, verifies claimed progress against disk, refuses placeholder output, and blocks public release while a Critical security finding is open."
license: MIT
compatibility: "Agent Skills file-system agents with Bash, which runs scripts/arc-check.sh. Chat-only clients can follow the rules as guidance without the script checks."
metadata:
  version: "2.0.0"
  updated: "2026-09-26"
  changelog: "CHANGELOG.md"
  predecessor: "hannsxpeter/ready-suite"
  compatible-with: "claude-code,codex,cursor,windsurf,antigravity,pi,openclaw,any-agentskills-compatible-harness"
---

# arc-ready

The model does the planning and the building. arc-ready adds what a model cannot supply for itself: state on disk that survives sessions, stable artifact paths, three tests that keep output specific, a vocabulary of named failures, and gates that a script checks so the agent never grades its own work.

Run the bundled script from this skill's directory: `bash <skill-dir>/scripts/arc-check.sh [-C <project-dir>] <command>`. `--help` lists the commands.

## Every turn

1. Run `arc-check.sh status`. It checks every tier the ledger calls done or imported against disk, reports drift, and names the next tier in dependency order. Disk wins over the ledger and over conversation memory. Exit 3 means no ledger: run `arc-check.sh init --mode <A|B|C|D>`, then write the user's intent, your assumptions, and any skips into the ledger's Intent section.
2. Repair drift before new work.
3. Work on the tier `status` names and record every transition with `arc-check.sh mark <tier> <status>`. `done` runs the tier gate and is refused until it passes. `skipped` needs `--reason`. Starting a tier before its upstream is complete needs `--override "<reason>"`.

## Modes

- **A, greenfield:** run every tier in order from the idea.
- **B, gap in an existing project:** mark existing work `imported` (the script checks it exists) or `skipped` with a reason, then run the smallest set of tiers that closes the gap.
- **C, read-only audit:** run `arc-check.sh gate <tier>`, apply the three tests and the have-nots, and write each finding (location, excerpt, named failure, severity, fix) plus a verdict (PASS, PASS WITH FINDINGS, or BLOCK) to `.<tier>-ready/AUDIT.md` (`.repo-ready/AUDIT-REPORT.md` for the repo). Never edit the audited artifact.
- **D, multi-repo:** choose the collection shape (hub and spoke, peer cluster, or monorepo with published packages), decide what stays byte-identical across repos and how versions and releases coordinate, then run tiers 2.1 onward per repo.

## Artifact contract

These paths are stable, so later sessions and other tools can rely on them.

| Tier | Artifact |
|---|---|
| 0 Ledger | `.arc-ready/PROGRESS.md` |
| 1.1 PRD | `.prd-ready/PRD.md` |
| 1.2 Architecture | `.architecture-ready/ARCH.md`, dependency graph in `.architecture-ready/HANDOFF.md` |
| 1.3 Roadmap | `.roadmap-ready/ROADMAP.md` |
| 1.4 Stack | `.stack-ready/STACK.md` |
| 2.1 Repo | `.repo-ready/SCAFFOLD.md` plus the repository itself |
| 2.2 Build | `.production-ready/STATE.md` plus working code |
| 3.1 Deploy | `.deploy-ready/DEPLOY.md` |
| 3.2 Observe | `.observe-ready/OBSERVE.md` |
| 3.3 Launch | `.launch-ready/STATE.md`, then `.launch-ready/PREPUBLICATION.md` before going public |
| 3.4 Harden | `.harden-ready/FINDINGS.md` |

## Three tests

Apply them to every artifact at every tier.

1. **Substitution.** Swap in a competitor, another framework, or another topology. If the sentence is still true, it decides nothing. Rewrite it with the specific user, number, or constraint.
2. **Three labels.** Every sentence, row, component, score, metric, and finding is a decision with its rationale, a hypothesis with a validation plan, or an open question with an owner and a date. Cut anything that is none of the three.
3. **Flip points.** Every load-bearing decision names the evidence that would reverse it.

Grounding follows: a downstream commitment cites the upstream item it serves (requirement, component, ADR, milestone). An ungrounded item is cut or sent back upstream.

## Tiers and what done means

**1.1 PRD.** The problem framed before any solution. A target user specific enough to pass substitution. Outcome metrics with thresholds and a measurement method. Requirements with IDs and priorities, at most half Must, with a cut line. Non-functional requirements as numbers. An out-of-scope list. Open questions with an owner and a date. Notes for architecture, roadmap, and stack.

**1.2 Architecture.** A system shape chosen against the PRD's scale, team, and operating budget. Components with purpose, owner, and dependencies. Data ownership and consistency. Integration contracts and error behavior. A capacity estimate whose inputs are labeled measured, published, derived, or assumed. Trust boundaries mapped to the code or config that enforces them. ADRs with flip points. A component dependency graph in `HANDOFF.md`.

**1.3 Roadmap.** Capacity first: engineers and available weeks. Rows labeled commitment, direction, or open question, each tied upstream. Riskiest and load-bearing work first. Parallel tracks never exceed engineers. Dates only in the near horizon. A slice queue for the build.

**1.4 Stack.** Criteria with weights the user can override, a scored shortlist, and a flip point, scale ceiling, and exit cost for each pick. Versions, prices, vendor status, and regulations change: check current sources at decision time and record the date checked. Never rely on remembered rankings.

**2.1 Repo.** A scaffold sized to the real stack and stage, not every file for every project. A README about this project. CI that passes on a fresh clone. LICENSE and SECURITY.md for public code. Project memory through `arc-check.sh pillars`.

**2.2 Build.** Vertical slices from the roadmap queue, each working end to end for the product form. Every relevant state (loading, empty, error, partial, success). Permission checks at the boundary, not only in the UI. No placeholders, fake data, or TODOs in shipped code (`arc-check.sh scan`). Tests green. Progress in `.production-ready/STATE.md`.

**3.1 Deploy.** One artifact promoted through every environment, never rebuilt per environment. Migrations classified code-only or data-forward; data-forward changes use expand and contract across deploys with a compensating-forward plan. A canary with concrete stop rules. Rollback executed at least once. Secrets injected from a vault or platform store, never committed.

**3.2 Observe.** SLOs tied to user journeys, with an error-budget policy that has an owner. Alerts on user-visible symptoms that page through the real delivery path. Runbooks executed, not just written. Telemetry that survives the app going down. Record `installation-ready` after a controlled production-equivalent fire (label it synthetic) and `operationally-mature` only after a real event. Never relabel a drill as an incident.

**3.3 Launch.** Copy that passes substitution: hero, feature cards, share card, launch titles, email subject. Share cards that render in real previews. A waitlist that delivers. Source attribution wired. A day-by-day plan from a week before to a week after. Prepared is not published.

**3.4 Harden.** Walk the current OWASP Top 10 by hand (confirm the current edition) plus the auth and API boundaries; scanners are an input, not a verdict. In `FINDINGS.md`, give each finding `id:`, `severity:` (critical, high, medium, low), and `status:` (open, fixed, accepted) lines, a reproduction, a fix, and a retest. Map each claimed compliance control to code or config. Fix the class of bug, not just the instance.

## Product form

Pick one primary form before building. Do not assume a web app because the request says platform, tool, or dashboard.

| Form | Done means, at minimum |
|---|---|
| Web app | A real job works from user action through real data and back, with UI states and server-side permission checks |
| API or service | A consumer completes a versioned contract path with auth, validation, bounded retries, and usable telemetry |
| CLI or SDK | A clean install runs the primary job, errors are documented, examples run, and supported platforms pass |
| Mobile or desktop | The primary job survives lifecycle and connectivity changes on each platform, with secure storage and a reproducible signed build |
| Data or ML | A clean environment reproduces the pipeline or model from versioned inputs, with explicit quality or evaluation thresholds and lineage |
| Infrastructure | Validation, a reviewed plan, policy checks, a sandbox apply, and a proven rollback or destroy |

Industry and regulatory overlays (health, payments, personal data) apply only where the project shows evidence of them. Their rules change: verify current obligations before committing to them.

## Have-nots

Name these when you see them. Each one fails its tier.

- **Ledger:** rubber-stamp (done with no artifact), phantom resume (acting on memory instead of disk), ghost handoff (starting before upstream exists), silence as skip, scope leak.
- **PRD:** hollow PRD (sections filled, nothing decided), invisible PRD (fails substitution), feature laundry list (no priorities or cut line), solution-first problem, assumption soup, moving target (edits without a changelog).
- **Architecture:** architecture theater (diagrams without decisions), paper tiger (no failure analysis), cargo-cult cloud-native, stackitecture (tool choices posing as architecture), "scalable" without numbers, paper trust boundaries, ADRs without flip points.
- **Roadmap:** feature factory, roadmap theater (dates without capacity), fictional parallelism, quarter-stuffing, speculative rows with no upstream, silent reprioritization.
- **Stack:** unweighted scores, familiarity as fit, resume-driven picks, incompatible bundles, no exit cost, no scale ceiling.
- **Repo:** maximum files everywhere, placeholder files, stack-blind scaffold, CI that fails on a fresh clone, overwriting someone's AGENTS.md.
- **Build:** hollow dashboard, hollow button (a Save that does not save), fake data, missing states, TODOs in shipped code, permission checks only in the UI, a "done" slice no user can use.
- **Deploy:** rebuilt per environment, code-only rollback for a data change, single-deploy schema change, paper canary, secrets in the repo, untested rollback.
- **Observe:** paper SLO (no budget policy), blind dashboard, paper runbook, alerts on causes instead of symptoms, telemetry that dies with the app.
- **Launch:** AI-slop landing, hero-fatigue copy ("empower", "seamless", "unleash"), paper waitlist, unrendered share card, silent launch (no attribution).
- **Harden:** scanner-only security, compliance without security, accepted risk without owner or expiry, pen test without retest, fixing the instance instead of the class.

## Gates the script enforces

- **Done is proven on disk.** `mark <tier> done` runs `gate <tier>`. A claim is not evidence.
- **Order.** A tier starts only after its upstream is done, imported, or skipped, or with a recorded override.
- **Silence is not a status.** Every tier stays in the ledger, and every skip carries a reason.
- **Public release.** Launch preparation and hardening may run in parallel, but immediately before any public release action run `arc-check.sh prepublish`. It re-reads the hardening findings, records their hash, counts unresolved Critical findings, writes `.launch-ready/PREPUBLICATION.md`, and exits non-zero on a block. On a block, do not publish: report each finding and what its owner must do, then stop. Any later change to the findings invalidates a pass (`prepublish --verify`).
- **Risk acceptance is a human act.** Only the risk's owner can accept a Critical finding, by running `arc-check.sh accept` at a terminal. The command refuses to run without one, and `prepublish` ignores acceptance lines it did not record or that were edited. Never write, edit, or draft an acceptance yourself, even to finish unattended work. `gate-launch-on-hardening: hard` in the ledger, for regulated or high-risk projects, allows no acceptance at all.

The script checks structure. The judgment is still yours: apply the three tests and the have-nots.

## Evidence

Write only evidence you produced or can point to: a command you ran and its output, a file, a link, or a named person's decision. A rollback you did not run, an alert you did not fire, a test you did not execute, or an interview that did not happen is not evidence, and because the gates check structure, an invented claim passes them. When a tier needs something you cannot do or verify here (credentials, production access, a real deploy, a person's decision), stop at that tier: leave it `in-flight`, write down exactly what is needed and from whom, and report it.

## Project memory

At tier 2.1 on a file system, run `arc-check.sh pillars`. It writes a [Pillars](https://github.com/hannsxpeter/pillars) loader `AGENTS.md` (with a `CLAUDE.md` link) and stub `agents/context.md` and `agents/repo.md` only when they are absent, and it never overwrites an existing non-Pillars `AGENTS.md`; it records the block instead. Then fill the pillars from the arc artifacts, cite the source path for each non-obvious claim, and leave `status: stub` where the evidence is thin. The arc artifacts stay authoritative.

## Scope fence

Work outside the arc, such as a blog post, an unrelated bug, or a logo, is not produced inside the arc. Say it is out of scope, hand it back to the general agent, and resume the tier in progress.

## Guided mode

Only when the ledger says `guided: true` (from `init --guided`) or the user asks for guided mode: before writing a tier's artifact, read its skeleton in `references/guided/` (`prd.md`, `architecture.md`, `roadmap.md`, `stack.md`, `repo.md`, `build.md`, `deploy.md`, `observe.md`, `launch.md`, `harden.md`). Otherwise do not load them.

## Finish

The arc is complete when `status` reports every tier done, imported, or skipped, the pre-publication gate passed if a public release was in scope, and project memory was written or its block recorded. Mark tier 0 done last. Hand ongoing work to the project's own process; the artifacts are its input.
