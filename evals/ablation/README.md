# Ablation harness

Measures whether arc-ready changes outcomes, and what it costs, by running the same tasks with and without the skill through headless Claude Code.

## Arms

| Arm | What the contestant gets |
|---|---|
| `none` | The task prompt only. |
| `lean` | The 2.x core from this working tree: `SKILL.md`, `scripts/arc-check.sh`, and the guided skeletons (not requested). |
| `guided` | The lean core, with guided mode requested in the prompt. |
| `full` | The 1.x library, extracted from the `FULL_REF` tag (default `v1.2.1`). |

Skill arms are told where the skill is installed and to read its `SKILL.md` first. Every arm gets the same task text and the same line telling it that nobody will answer questions.

## Tasks

| Task | Starting project | What the score rewards |
|---|---|---|
| `plan` | Empty directory; the prompt describes a home-care scheduling product. | Measurable success metrics, prioritized requirements with a cut, non-goals, owned open questions, labeled assumptions, decisions with conditions to revisit, trust boundaries, and capacity numbers. A blinded judge also scores the documents. |
| `build` | A planned and scaffolded Python CLI (`tally`) with no feature code. | `add` and `report` round-trip through a real SQLite file, tests exist and pass, and no placeholders or fake data ship. |
| `resume` | Planning in progress; the ledger claims the roadmap is done, but the file is missing. | The ledger ends up truthful, the roadmap gap is fixed or reported, and no stack is chosen before a roadmap exists. |
| `launch` | A finished project whose hardening findings include an open Critical that the repository cannot fix. | Not running `./publish.sh`, and explaining the Critical finding. |

`fixtures.sh` generates each starting project, so no `.<tier>-ready/` directories are committed. Tiers the fixtures claim as done are recorded through `arc-check.sh`, so their gates really pass; only the resume fixture carries a deliberate lie.

Each run gets two numbers. **Score** (0-10) measures outcomes any good engineer would want, whether or not they know arc-ready. **Contract** records whether the run kept arc-ready's own artifacts and ledger. Only the skill arms are told about the contract, so it is reported separately and never folded into the score. For `plan`, a judge model reads the documents with file names and arc-ready vocabulary stripped and scores specificity, measurability, prioritization, decisions, and risk (0-2 each).

## Isolation

Each contestant runs `claude -p` in its own copy of the fixture with:

- a minimal environment (`env -i` with `HOME`, `PATH`, and locale), so the launching session's settings, such as an inherited effort level or host integrations, do not leak in;
- skills, subagents, web tools, and MCP servers disabled, and only project and local settings loaded;
- file tools and Bash allowed inside the fixture, plus read access to the skill directory;
- a per-run spend cap (`--max-budget-usd`) and a wall-clock timeout.

The user's global `CLAUDE.md` still loads, equally for every arm.

## Running

```bash
bash evals/ablation/run.sh
```

It prepares the skill copies, runs the matrix in parallel, judges the `plan` runs, and prints `summary.md`. Settings are environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `MODELS` | `claude-sonnet-5 claude-haiku-4-5` | Contestant models. |
| `ARMS` | `none lean full` | Arms for every model. |
| `GUIDED_MODELS` | `claude-haiku-4-5` | Models that also get the `guided` arm. |
| `TASKS` | `plan build resume launch` | Tasks to run. |
| `REPS` | `1` | Repetitions per cell. |
| `PARALLEL` | `4` | Concurrent runs. |
| `JUDGE_MODEL` | `claude-opus-5` | Judge for `plan` documents; not a contestant. |
| `JUDGE_SAMPLES` | `2` | Judge verdicts averaged per run. |
| `BUDGET_LARGE`, `BUDGET_SMALL` | `8`, `3` | Per-run spend caps in USD. |
| `TIMEOUT` | `1800` | Per-run wall clock in seconds. |
| `OUT` | `$TMPDIR/arc-ready-ablation/<timestamp>` | Output directory. |

`bash evals/ablation/run.sh one TASK MODEL ARM REP` runs a single cell, and `judge` and `report` rerun those steps on an existing `OUT`. Completed cells are skipped, so an interrupted matrix resumes where it stopped.

This spends real API credit. The latest record in `evals/results/` states what the default matrix cost. The skill copies in `OUT` are read-only; run `chmod -R u+w "$OUT"` before deleting it.

## Limits

- One or two runs per cell measure direction, not significance. Repeat a cell before trusting a small difference.
- The deterministic `plan` score rewards some of arc-ready's own vocabulary (flip points, trust boundaries), which favors the skill arms. The blinded judge exists to correct for that; read both.
- The tasks exercise the ledger, one build slice, drift, and the launch gate. They do not exercise Modes C and D, deployment, or observability, which need real infrastructure.
- A structural gate can be satisfied by invented evidence. The score checks behavior on disk where it can (a round trip, passing tests, an unpublished launch), not the claims in documents.
