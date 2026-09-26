# arc-ready

![arc-ready](assets/hero.png)

**From "I have an idea" to "it's live" without the guesswork.**

One AI skill that walks a software project through every stage it has to go through anyway: what to build, how it fits together, in what order, with what tools, then building it, shipping it, watching it, launching it, and attacking it before someone else does.

[![lint](https://github.com/hannsxpeter/arc-ready/actions/workflows/lint.yml/badge.svg)](https://github.com/hannsxpeter/arc-ready/actions/workflows/lint.yml)
[![release](https://img.shields.io/badge/release-v2.0.0-blue)](https://github.com/hannsxpeter/arc-ready/releases/tag/v2.0.0)
[![agent skills](https://img.shields.io/badge/Agent%20Skills-compatible-2f6fed)](SKILL.md)
[![hannsxpeter/pillars](https://img.shields.io/badge/hannsxpeter%2Fpillars-standard-0f766e)](https://github.com/hannsxpeter/pillars)
[![license](https://img.shields.io/github/license/hannsxpeter/arc-ready)](LICENSE)

---

## The problem it solves

AI coding assistants are very good at producing something that looks finished. A screen appears. A button exists. A demo runs.

Then you look closer. The data behind the login screen is fake. The dashboard renders but nothing saves. The roadmap has no order. The monitoring fires alerts nobody can act on. The launch page makes claims the product cannot back up. And the assistant cheerfully reports that everything is done.

Current models know how to write a good PRD, design a sound architecture, and harden an app. What they lack is memory that outlives a session, a record of what was actually done instead of what they remember doing, and something other than their own judgment standing between "done" and "shipped". arc-ready supplies those parts and stays out of the way for the rest.

## What it adds

- **State on disk.** A progress ledger at `.arc-ready/PROGRESS.md` and one document per stage at a fixed path. A new session, a new assistant, or a new hire picks up from the files, not from anyone's memory.
- **Checks a script runs, not a promise.** `scripts/arc-check.sh` refuses to record a stage as done until its gate passes, catches a ledger that claims work the disk does not show, and flags placeholders and fake data in shipped code.
- **A release gate.** Immediately before anything goes public, `arc-check.sh prepublish` re-reads the security findings and blocks while a Critical one is open. Only the risk's owner can accept it, by running `arc-check.sh accept` at a terminal; the assistant cannot record an acceptance for you.
- **Three tests and a list of named failures.** Every plan and claim must survive swapping in a competitor's name, must be a decision, a hypothesis, or an owned open question, and must say what would reverse it. The named failures ("hollow PRD", "paper canary", "scanner-only security") give reviewers and assistants a shared vocabulary.
- **Project memory.** At the repository stage it writes a [Pillars](https://github.com/hannsxpeter/pillars) `AGENTS.md` and memory files, without ever overwriting one you already have.

All of it is plain Markdown in your project folder and one Bash script. There is no service and no account.

## How it works

Every software project travels the same road, whether anyone names it or not:

```
idea -> what to build -> how it fits together -> in what order
     -> with what tools -> a real repo -> the actual app
     -> shipping it -> watching it -> launching it -> hardening it
```

arc-ready turns each of those into a stage with a written outcome, and a stage cannot start until the ones before it are done, imported, or deliberately skipped with a reason.

| Stage | What it answers | What it leaves behind |
|---|---|---|
| Kickoff | Where are we, and what is next | A progress ledger |
| Product definition | What are we building, for whom, and how do we know it worked | A product requirements doc |
| Architecture | How do the pieces fit, and what would change our minds | A system design with its reasoning and a dependency graph |
| Roadmap | In what order, with the people we actually have | A sequenced plan with capacity and a slice queue |
| Stack | Which technologies, checked against current sources | A weighted, dated decision with exit costs |
| Repository | Is the project set up for this stack and stage | Structure, CI that passes on a fresh clone, project memory |
| The app | Does it work end to end | Working slices on real data, with tests |
| Deploy | Can we ship safely and undo it | One artifact promoted through environments, a rollback that was run |
| Observe | Will we know when it breaks | Journey-based targets, owned error budgets, executed runbooks |
| Launch | Is the public story true and ready | Copy, share cards, attribution, a launch-week plan |
| Harden | What would an attacker find | Findings with severity, reproduction, fix, and retest |

## Getting started

Install once:

```bash
git clone https://github.com/hannsxpeter/arc-ready ~/.claude/skills/arc-ready
```

That is the Claude Code location. Codex, Antigravity, Pi, OpenClaw, and other Agent Skills harnesses use their own skills directory with the same clone. For Cursor or Windsurf, clone it anywhere, then copy `.cursorrules` into your project (or into `.cursor/rules/`) and point it at the clone. The script needs Bash; chat-only assistants can still follow the rules without it.

Then talk to your assistant in your own words:

```text
I have an idea for a booking app for small salons. Walk me through to launch.
```

```text
Write a PRD for this app.
```

```text
Audit the architecture in .architecture-ready/ARCH.md.
```

**Using a smaller model?** Run `bash ~/.claude/skills/arc-ready/scripts/arc-check.sh init --guided` in your project, or ask for guided mode. The assistant then reads a short skeleton for each stage before writing it. Nothing extra loads otherwise.

**Want the full 1.x reference library?** It is frozen at `v1.2.1`: `git clone --branch v1.2.1 https://github.com/hannsxpeter/arc-ready ~/.claude/skills/arc-ready`. See [MIGRATION.md](MIGRATION.md).

## Four ways to use it

- **Full arc.** Start at an idea and finish at a hardened launch.
- **Fill a gap.** You have a codebase and one missing piece (requirements, monitoring, a launch plan). Existing work is recorded as imported, and the assistant goes straight to the gap.
- **Audit.** Score an existing document against the same standard, without changing it.
- **Multi-repo.** Lay out a set of related repositories that must stay consistent.

## It knows what kind of thing you are building

A command-line tool does not need a design system, and a data pipeline does not need share cards. arc-ready picks the product form first and applies the matching definition of done.

| If you are building | "Done" means, at minimum |
|---|---|
| A web application | A real job works from user action through real data and back, with UI states and server-side permission checks |
| An API or service | A consumer completes a versioned contract path with auth, validation, bounded retries, and usable telemetry |
| A CLI or SDK | A clean install runs the primary job, errors are documented, examples run, and supported platforms pass |
| A mobile or desktop app | The primary job survives lifecycle and connectivity changes, with secure storage and a reproducible signed build |
| A data or ML system | A clean environment reproduces the pipeline or model from versioned inputs, with quality thresholds and lineage |
| Infrastructure | A validated plan, policy checks, a sandbox apply, and a proven rollback |

## Where everything gets written

These paths are a stable contract. The stage documents sit where the eleven-skill ready-suite put them, and none moved in 2.0.

| Stage | Path |
|---|---|
| Progress ledger | `.arc-ready/PROGRESS.md` |
| Product requirements | `.prd-ready/PRD.md` |
| Architecture | `.architecture-ready/ARCH.md` and `HANDOFF.md` |
| Roadmap | `.roadmap-ready/ROADMAP.md` |
| Stack decision | `.stack-ready/STACK.md` |
| Repository | the repository itself, plus `.repo-ready/SCAFFOLD.md` |
| The app | working code, plus `.production-ready/STATE.md` |
| Deploy | `.deploy-ready/DEPLOY.md` |
| Observe | `.observe-ready/OBSERVE.md` |
| Launch | `.launch-ready/STATE.md`, then `.launch-ready/PREPUBLICATION.md` before going public |
| Harden | `.harden-ready/FINDINGS.md` |
| Project memory | `AGENTS.md` and `agents/*.md` |

## What the script checks

| Command | What it does |
|---|---|
| `arc-check.sh status` | Compares the ledger with disk, reports drift, and names the next stage. |
| `arc-check.sh mark <stage> <status>` | Records progress. `done` is refused until the stage's gate passes; a skip needs a reason; starting early needs a recorded override. |
| `arc-check.sh gate <stage>` | Runs the mechanical checks for one stage, for example measurable success metrics and a Must cut line in the PRD, or an executed rollback in the deploy plan. |
| `arc-check.sh scan` | Finds TODO comments, fake-data libraries, and stubbed calls in shipped source. |
| `arc-check.sh pillars` | Writes project memory when absent, and records a block instead of overwriting yours. |
| `arc-check.sh prepublish` | The public-release gate. |
| `arc-check.sh accept` | Records a risk acceptance. It runs only for a person at a terminal. |

The gates check structure. Whether a requirement is specific or an architecture decision is sound is still the assistant's judgment, guided by the three tests.

## What it refuses to do

- Mark a stage done when its document is missing, empty, or still a template.
- Start a stage before the ones it depends on, unless you record why.
- Ship placeholder data, stub screens, or "TODO: wire this up".
- Treat a Critical security finding as resolved without a fix, or accept a security risk on your behalf. Only a person at a terminal can record a risk acceptance.
- Publish from a pre-publication check that is older than the latest security findings.
- Write evidence it did not produce, such as a rollback it never ran.

## Evidence

Version 2.0.0 was measured before release. The same four tasks ran with no skill, with the lean 2.0 core, and with the full 1.2.1 library, on Claude Sonnet 5 and Claude Haiku 4.5: 56 runs, plus a 9-run rerun after one fix. Details are in [EVALS.md](EVALS.md).

- **Plans got better with the skill.** A separate model, blind to which setup wrote the documents, scored plans 7.25 (Sonnet) and 5.75 (Haiku) without the skill, and 10 and 10 with the lean core. The full 1.2.1 library scored 10 and 8.25.
- **The full library cost four times as much for the same result.** A Sonnet planning run cost $2.57 with it and $0.64 with the lean core.
- **The ledger caught what memory missed.** Asked to continue a project whose ledger claimed a roadmap that did not exist, every lean-core run noticed and fixed it; one no-skill run in four did.
- **Building a clear slice needed no help.** Every setup on both models built it end to end with passing tests.
- **The measurement found a hole, and the fix is in code.** Haiku, with either version of the skill, sometimes wrote its own risk acceptance to get past the release gate, then published. `arc-check.sh accept` now works only for a person at a terminal. After that change, every launch run held.

## Common questions

**Do I have to be a developer?**
No. You need to be able to describe what you want to exist. The planning stages are conversations, and the documents are written for people who are not engineers. The building stages assume an AI coding assistant is doing the typing.

**Why did 2.0 get so much smaller?**
Version 1.x shipped a 220-file reference library, and loading what it pointed to for the planning stages alone came to about 254,000 tokens. Current models already know most of that material. Version 2.0 keeps the parts they cannot supply for themselves and moves enforcement into a script. The numbers are in the evidence section above and in [EVALS.md](EVALS.md).

**I already started building. Is it too late?**
No. Point it at your project and ask for the missing piece. Existing documents are imported, not rewritten.

**Does it replace my developers?**
No. It replaces forgotten steps and arguments about what "done" means. Decisions that are yours stay yours.

**Where does my project data go?**
Into your project folder, as plain Markdown. arc-ready is a set of instructions and one script your assistant runs locally.

## Documentation map

- [SKILL.md](SKILL.md): everything the assistant is told.
- [EVALS.md](EVALS.md): how arc-ready is tested and measured, with the latest results.
- [MIGRATION.md](MIGRATION.md): moving from 1.x or from the eleven-skill ready-suite.
- [docs/drift-audit.md](docs/drift-audit.md): where the 1.2.1 documentation disagreed with reality, and what changed.
- [CONTRIBUTING.md](CONTRIBUTING.md), [MAINTAINING.md](MAINTAINING.md), [AGENTS.md](AGENTS.md): working on arc-ready itself.
- [SECURITY.md](SECURITY.md): reporting a vulnerability, and exactly what the script reads and writes.
- [CHANGELOG.md](CHANGELOG.md): version history.

## Where it came from

arc-ready began as [hannsxpeter/ready-suite](https://github.com/hannsxpeter/ready-suite), eleven separate skills in twelve repositories. Version 1 consolidated them into one skill with the same artifacts. Version 2 keeps the artifacts, the named failures, and the gates, and drops the textbook material current models no longer need.

## License

MIT. See [LICENSE](LICENSE).
