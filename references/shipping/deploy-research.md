# Deploy research, Step 0

Loaded at the start of every session. The job of this file is to put the agent in the correct mode before it reads anything else, and to prevent the class of AI-driven deploy incident that begins with "the agent thought it was shipping when it was actually investigating." Read end to end before Step 1.

## Why Step 0 exists

Deploy failures cluster into a small number of shapes. Which shape you are in determines what you read next, what you output, and what you refuse to do. An agent that walks Step 1 without declaring a mode will write a first-deploy plan for a subsequent deploy, skip the cold-start gates on a new environment because "the environment is just like the other one," or worst of all start executing destructive commands in prod while the user is still asking diagnostic questions.

The mode detection protocol below is a five-minute exercise that prevents every one of those failures. It is non-negotiable even on a "just ship this tiny change" request. Tiny changes are where partial-deploy incidents hide (Knight Capital's $460M loss was a tiny change shipped incorrectly to one of eight servers, see [Kosli on Knight](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/) and [Doug Seven](https://dougseven.com/2014/04/17/knightmare-a-devops-cautionary-tale/)).

## The five modes

| Mode | Trigger | Load order priority |
|---|---|---|
| **A. First deploy to an environment** | The target environment has never received a successful ship from this pipeline, or does not exist yet. | `first-deploy-checklist.md` before anything else. |
| **B. Subsequent deploy** | The pipeline has shipped to this environment before; same artifact type; same topology. | `preflight-and-gating.md` shortcut path. |
| **C. Incident or rollback** | Prod is currently broken, a ship just went wrong, or the user is asking "is X broken." | `rollback-playbook.md` immediately. Skip forward. |
| **D. Pipeline construction** | The user is building the CI/CD pipeline itself, not shipping a specific change. | `pipeline-patterns.md` and `environment-parity.md`. |
| **E. Migration-dominated** | The change set is primarily a schema or data migration. | `zero-downtime-migrations.md` front-and-center. |

A session can be in exactly one mode at a time. If the work moves from one mode to another (a subsequent deploy turns into an incident; a first deploy reveals a migration that needs its own plan), stop, restate the mode, and re-enter the workflow at the correct step.

## Signals for detecting the mode

Read each signal in order. The first mode whose signals match is the mode you are in.

### Mode C signals (incident / rollback): check first

Check these first because the cost of missing an incident is higher than the cost of pausing a ship.

- Observability dashboard is red, or the user is pointing at an alert.
- The user's language: "production is down," "this just broke," "rollback," "revert," "something is wrong with the canary," "users can't log in."
- A recent commit in `main` has not completed its rollout; the deploy is in-flight.
- `.deploy-ready/STATE.md` shows a ship in progress with no post-deploy check mark.
- Recent entries in `.deploy-ready/incidents/` dated within the last 24 hours.

If any of these are present, you are in Mode C. Do not ship. Read `rollback-playbook.md` and execute.

### Mode A signals (first deploy)

- No `.deploy-ready/STATE.md` exists, or it exists but lists no successful ship to the target environment.
- Target environment not in `.deploy-ready/TOPOLOGY.md`.
- The request contains phrases like "first deploy," "set up the pipeline," "spin up staging," "new environment," "new region."
- IAM role, DNS record, TLS cert, registry path, or env vars for the target have not been verified to exist.
- Git history of the deploy pipeline shows no successful run targeting this environment.

If any of these are present, Mode A is the safe choice. First deploys fail differently; `first-deploy-checklist.md` is a hard block. "It's probably set up like the other one" is how first-deploy blindness happens.

### Mode B signals (subsequent deploy)

- `.deploy-ready/STATE.md` records at least one successful ship to the target environment within the last 90 days.
- The change set is small (one or a few commits), classifiable, and fits inside the existing topology.
- No schema change in the diff, or the schema change is in its contract phase with the expand already shipped.
- The pipeline has run green on main within the last ship cycle.

Mode B is the common case. The shortcut in `preflight-and-gating.md` applies: the bulk of the environment map, secrets-injection audit, and topology note is quoted from the last successful deploy's plan, with only the delta analyzed.

### Mode D signals (pipeline construction)

- No pipeline file exists in the repo (`.github/workflows/`, `.gitlab-ci.yml`, Jenkins file, Buildkite pipeline).
- The existing pipeline builds, tests, and pushes to prod in a single job with no gate.
- The user is asking "how do I set up CI/CD," "wire up deploys," "add staging to the pipeline."
- `.stack-ready/DECISION.md` names a host and topology, but there is no deploy automation against it.

Mode D focuses on Steps 3 and 4. The other steps run as a dry walkthrough against a representative change so the pipeline gets validated end to end before the first real ship.

### Mode E signals (migration-dominated)

- The diff includes files under `db/migrations/`, `prisma/migrations/`, `alembic/versions/`, `migrations/`, or similar.
- The diff contains SQL DDL (`ALTER TABLE`, `CREATE INDEX`, `DROP COLUMN`, `ADD COLUMN`, `RENAME`).
- The user mentions "migration," "schema change," "backfill," "data migration."
- `.deploy-ready/migrations/calendar.md` has an open expand phase older than one full ship cycle (the expand-only migration trap, see section at the end of this file).

If Mode E is triggered, Step 6 (expand/contract calendar) moves to the front. The deploy calendar is the plan; the code change is a satellite.

## Research output block, per mode

Every mode produces a short, named block before the agent proceeds to Step 1. The block is the agent's contract with the session. It is written to the plan output so that a reviewer can see what was detected.

### Mode A output block

```
Mode: A (first deploy)
Target environment: <name>
Topology: <from stack-ready or inferred>
Cold-start items to verify:
  - DNS: <exists? propagated?>
  - TLS cert: <exists? expiry?>
  - IAM / runtime role: <exists? least-privilege?>
  - Registry / artifact store: <exists? push credentials valid?>
  - Env vars: <set in platform, not just in code?>
  - DB: <provisioned? migrations applied through expand?>
  - Log aggregation: <reaches this env?>
Risks unique to first deploy: <framework prefix gotchas, env vars undefined until redeploy, etc.>
```

### Mode B output block

```
Mode: B (subsequent deploy)
Target environment: <name>, last successful ship: <date, version>
Change-class (from Step 5): <reversible | data-forward | mixed | side-effectful>
Delta vs. last deploy:
  - Code: <summary>
  - Schema: <none | expand | migrate | cutover | contract>
  - Config / env vars: <none | listed>
Open expand/contract cycles from STATE.md: <list>
Rollback target: <prior version id>
Known-green of last deploy: <yes | no, with note>
```

### Mode C output block

```
Mode: C (incident / rollback)
Current prod state: <healthy portions vs. broken portions>
Trigger: <alert name | user report | self-observed>
Time of first observation: <timestamp>
In-flight deploy at time of incident: <yes/no, version>
Blast radius: <users affected, services affected>
Rollback path available: <yes/no>
If data-forward: compensating-forward plan location: <path>
```

Do not proceed to remediation until this block is filled. Mode C is the one place where an agent's speed is directly correlated with its ability to make things worse.

### Mode D output block

```
Mode: D (pipeline construction)
Existing pipeline: <none | partial, location>
Stack-ready decision: <host, topology, artifact type>
Target environments to wire: <preview, staging, canary, prod>
Representative change for dry walkthrough: <small recent commit>
Gate enforcement target: <GitHub environment rules | GitLab environment approvals | Argo sync waves>
```

### Mode E output block

```
Mode: E (migration-dominated)
Migration files in scope: <list>
Classified change per file: <expand | migrate | cutover | contract | destructive>
Current calendar entries in .deploy-ready/migrations/calendar.md: <list>
Proposed deploy calendar:
  - N (this ship): <phase>
  - N+1: <phase>
  - N+k: <contract phase, scheduled>
Restore point captured: <snapshot id | none>
Code ship (if paired): <deploy N or N+1?>
```

## The destructive-command alert

If the environment is prod and the session is ambiguous about whether it is shipping or investigating, default to investigating. Do not run destructive commands. The agent-running-destructive-commands failure class has two named incidents behind it:

- **Replit (SaaStr tenant, July 2025):** an AI agent ignored a designated code-and-action freeze, executed destructive database commands without human approval, destroyed 1,206 executive records and 1,196 company records, then fabricated a replacement database of 4,000 invented users, and misrepresented the deletion after the fact ([Fortune, 2025](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/); [The Register, 2025](https://www.theregister.com/2025/07/21/replit_saastr_vibe_coding_incident/); [AI Incident Database #1152](https://incidentdatabase.ai/cite/1152/)). Replit's post-incident fixes were: auto-split dev and prod databases, better rollback, a new planning-only mode.
- **DataTalks.Club (2025):** an AI agent operating against production credentials with no environment guard destroyed the production VPC, ECS cluster, load balancers, database, and bastion on the course platform ([dev.to, rsiv](https://dev.to/rsiv/ai-sped-up-development-not-shipping-5g1)). No confirmation gate on destructive IaC.

The operational rule for every Mode C session and any ambiguous prod session:

- If an action is destructive (`DROP`, `TRUNCATE`, `rm -rf`, `terraform destroy`, `kubectl delete`, `prisma migrate reset`, `flyctl destroy`, `gh-ost --alter=DROP`), do not execute it without an explicit confirmation step naming the target and the blast radius.
- If the environment detection is unclear, treat as prod. Prod assumptions are safe; dev assumptions against prod are not.
- If the user has declared a freeze, the freeze overrides the plan. Ask for release from the freeze; do not route around it.
- Credentials separation: if the deploy credential is the same as the app's runtime credential, that is a bug, not a convenience. Least-privilege runtime identity is a Tier 2 requirement for a reason.

## Detecting an expand-only migration trap in an existing repo

The expand-only migration trap is one of the two named hazards this skill surfaces. You shipped the expand phase, forgot or skipped the contract, and now carry a perpetual dual-schema liability that makes every subsequent migration harder. The trap compounds: the next engineer adds a new column next to the already-orphaned `_old` column, and a year later the table has four variants of the same field with no agent in the company confident enough to delete any of them.

Detection signals, walk them in order:

1. **Check the calendar.** Open `.deploy-ready/migrations/calendar.md`. Any entry with an expand phase dated older than two full ship cycles and no matching contract entry is an open trap. Flag it in the Mode E output block under "Open calendar entries."
2. **Scan column names for parallel-change debris.** Search the schema (or `schema.prisma`, `db/schema.rb`, models, or migrations) for suffix patterns: `_old`, `_new`, `_v1`, `_v2`, `_tmp`, `_backup`, `_deprecated`. Each is a candidate trap. The cheap cases are genuinely historical; the expensive cases are live parallel writes with no one in the team confident which is canonical.
3. **Scan migration history for orphan expands.** An expand migration (`ADD COLUMN ... NULL`, `CREATE TABLE ... shadow_*`) with no downstream migration that drops or renames the old structure is an orphan expand. If the migration is older than 90 days and the old structure is still present, assume the trap is live.
4. **Scan application code for dual-read-dual-write paths.** Code comments like "TODO: remove after migration," "dual-write for now," "backfill in progress," or code paths that read from one column and fall through to another are evidence of an in-flight expand that never closed.
5. **Check feature flags.** A feature flag named after a migration phase (`use_new_avatar_url`, `dual_write_users`, `read_from_v2`) that has been in prod for more than a ship cycle is an expand-only trap with a flag on top.

When a trap is detected, the Mode E output block must name it explicitly and the plan must either schedule the contract phase in a future deploy (preferred) or name the reason the contract is still blocked (acceptable only if the reason is concrete, e.g., "mobile client 4.3.x rollout at 78%"). "We'll get to it" is not a reason; it is how the trap persists.

## What to read next, by mode

| Mode | Next file | Then |
|---|---|---|
| A | `first-deploy-checklist.md` | `preflight-and-gating.md` Step 1 |
| B | `preflight-and-gating.md` | Step 2 topology note (Mode B shortcut) |
| C | `rollback-playbook.md` | Step 11 directly |
| D | `pipeline-patterns.md` | `environment-parity.md` |
| E | `zero-downtime-migrations.md` | `preflight-and-gating.md` Step 1 |

Load on demand; do not pre-read the full reference set. Each file is priced for a specific step.
