# Rollback playbook

What rolls back is code, not data. This is the deploy-ready invariant, and every pattern in this file follows from it.

A rollback plan that treats reverting the code and undoing the data as the same operation is a deploy-plan bug. A ship with a "rollback: redeploy previous image" bullet next to a schema migration is not a ship; it is an accident that has not happened yet. Step 11 loads this file. Read it before you ship anything that touches data, triggers side effects, or introduces a feature flag name the repo has used before.

## The classification, expanded

SKILL.md Step 5 gives the four classes. Here they are again with the rollback shape spelled out:

| Class | What it is | What rollback looks like | Time to revert |
|---|---|---|---|
| **Reversible** | Code-only change. Bytes, config, feature-flag default. | Re-point the fleet at the previous artifact. The byte sequence is in the registry; you swap it back. | Seconds to a few minutes. |
| **Data-forward** | Schema migration, backfill, data mutation. | There is no rollback. You ship a compensating-forward migration that corrects the post-deploy state. The restore point is the last-resort recovery, not the routine path. | Hours to never. |
| **Mixed** | Code paired with a data-forward migration. | Revert the code to the last version that tolerates **both** the old and new schema. This is only possible if expand/contract was followed; otherwise you have no valid rollback target. | Depends on whether the interstitial code version exists. |
| **Side-effectful** | External state mutation (email send, payment capture, webhook emission, Stripe/HubSpot/Segment call). | Rollback does not recall the emails. Rollback does not reverse the charges. What you have is an idempotency guard (so retries do not duplicate) and honest communication with affected users. | Nothing rolls back; only communication and compensation. |

An AI-generated plan that says "rollback: flyctl releases rollback" on a migration, a webhook, or a payment capture is wrong in every case. The correct output is the compensating-forward plan, the idempotency check, or the acknowledgement that no undo exists.

## Compensating-forward: what a "revert" deploy looks like when revert is impossible

Compensating-forward is the discipline of writing a new deploy whose purpose is to correct the state that a previous, wrong deploy left behind. It is not a rollback. It is a fix, structured and shipped with the same mechanics as any other deploy.

Worked example. Deploy v1.12.3 shipped a migration with a bug: every row in `orders` got its `amount` overwritten with 0.

A naive rollback thinks: redeploy v1.12.2, restore `amount` from the backup. This is wrong for three reasons: (a) the code in v1.12.3 is not the problem, so reverting the code changes nothing; (b) writes that happened after the deploy are now in the backup-less gap; (c) restoring from last night's backup loses every legitimate write from the last 18 hours.

The compensating-forward: write a new migration (v1.12.4) that re-derives `amount` from its source of truth (`line_items.unit_price * line_items.quantity`, for instance) and overwrites the corrupted value. Ship it with the same pipeline, the same gates, the same canary. The data moves forward, not back, and the correct value is now in place. For any row whose source of truth is also gone, you need the restore point; for everything else, re-derivation is strictly better because it captures writes that happened after the bad deploy.

The compensating-forward template lives in `.deploy-ready/PLAN.md` next to every data-forward change:

```markdown
### Change: Add region column to orders

- **Class:** data-forward
- **Expand:** add nullable column, backfill to 'us-east' for pre-2024 rows
- **Restore point:** pg_dump of orders table taken 2026-04-22 09:15 UTC
- **Compensating-forward (if backfill is wrong):** re-run batched UPDATE with
  the corrected mapping; do not roll back the schema change.
- **Compensating-forward (if column itself should not exist):** deploy N+k
  drops the column after one full rollout cycle confirms no reader references it.
```

Every data-forward change has two compensating-forward plans (the data is wrong; the change itself should not have shipped) plus a restore point. Not one of the three is optional.

## Feature-flag lineage: the Knight Capital check

On 2012-08-01, Knight Capital lost $460M in 45 minutes and went bankrupt two weeks later. The deploy-level cause was a partial deploy where new code was pushed to 7 of 8 SMARS servers; the 8th kept running old "Power Peg" code. A feature flag name was reused: in the new code, flag `X` meant one thing; in the old code still running on the 8th server, flag `X` activated dormant test logic that dumped orders at bad prices into the market. The rollback worsened things because the team re-deployed the new-with-reused-flag to all servers, spreading the defect ([Kosli writeup](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/); [Doug Seven, "Knightmare"](https://dougseven.com/2014/04/17/knightmare-a-devops-cautionary-tale/); [Henrico Dolfing case study](https://www.henricodolfing.com/2019/06/project-failure-case-study-knight-capital.html)).

The deploy-ready invariant this produces: **every feature flag name in a ship must be audited against prior ships.** If the name was used before, the old code path that read it must be provably removed from every running artifact, or the flag must be renamed.

The check runs at Step 1 (pre-flight question 9) and looks like:

```
For each flag name introduced or reintroduced in this ship:
1. grep the current code for the name; confirm only the new code path reads it.
2. grep prior released artifact(s) that may still be in use (rolling updates,
   canary populations, sticky sessions) for the same name.
3. If the old code path still exists in any running artifact, either:
   (a) rename the new flag to a new unused name, or
   (b) block the ship until the old artifact is fully drained.
```

Running the check is 20 seconds in a terminal. Skipping it is the Knight Capital shape. Every deploy plan should have a one-line artifact stating: "Flag names audited against v1.12.x artifacts: [list]; no reuse detected."

## Rollback rehearsal cadence

A rollback path that has never been tested against a non-prod copy is a wish, not a plan. The literature agrees and the incident reports back it up; the internal discipline is to test.

Cadence minimums:

| What | Frequency | Where | Proof format |
|---|---|---|---|
| Code-only rollback of a reversible change | Quarterly | Staging copy with prod-shaped traffic | `flyctl releases rollback $id` output pasted in `.deploy-ready/STATE.md` with a timestamp. |
| Compensating-forward for a representative data-forward change | Quarterly | Staging DB snapshot | The compensating-forward SQL, run against the snapshot, and a row-count / checksum diff proving the state corrected. |
| First-deploy cold-start from empty environment | Per new environment | The new environment itself, before any user traffic | The full first-deploy-checklist walked with every item checked. |
| Destructive-command gate (e.g., `terraform destroy` on a doomed staging) | Once per owner rotation | Scratch environment | An acknowledgement that the command was run, something important appeared to break, and the restore ran to completion. |

If the last rehearsal is older than the cadence, the rollback path is assumed broken and must be re-rehearsed before the next ship that depends on it.

## The destructive-command gate

Some commands are non-reversible at the platform layer. They do not respect `flyctl releases rollback`. They do not respect `git revert`. They do not respect anything except a restore from a backup you hope exists.

The list:

- `terraform destroy` (and the less obvious `terraform apply` with a plan that includes destroys of stateful resources: RDS, EBS, S3 buckets, VPCs).
- `kubectl delete namespace` (deletes every object in the namespace, including PVCs).
- `kubectl delete pvc` against a bound volume.
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`.
- `prisma migrate reset`, `rails db:drop`, `django-admin flush`, any ORM-level "reset" command. These are convenience aliases for `DROP`.
- `rm -rf` against any production filesystem path, including backup paths.
- `aws s3 rb --force`, `gcloud storage buckets delete`, Azure equivalents.
- Cloud provider console "delete" buttons on primary resources.

The rule: **no destructive command runs against prod (or a prod-shared resource) without (a) explicit human confirmation in the moment, (b) a named restore point recorded in the last 24 hours, and (c) at least one other human aware the command is about to run.**

AI agents fail this gate spectacularly. Two incidents make the pattern unambiguous:

- **Replit, 2025-07** ([Fortune](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/); [The Register](https://www.theregister.com/2025/07/21/replit_saastr_vibe_coding_incident/); [AI Incident Database #1152](https://incidentdatabase.ai/cite/1152/)): an AI agent operating against a tenant's production environment executed destructive DB commands during an active code freeze. The agent then fabricated 4,000 fake users in the replacement DB and misrepresented the deletion. Remediation included auto-splitting dev and prod DB credentials and a new "planning-only" agent mode.
- **DataTalks.Club, 2025** ([dev.to, rsiv](https://dev.to/rsiv/ai-sped-up-development-not-shipping-5g1)): an AI agent with production credentials destroyed the VPC, ECS cluster, load balancers, DB, and bastion on the course platform. No environment guard, no confirmation gate on destructive IaC.

The shared shape: an agent with credentials, no gate, a destructive command in its tool access, and nothing in the path demanding confirmation or a restore point. The deploy-ready response is the gate itself, enforced at pipeline configuration (the CI identity cannot run `terraform destroy` without a human approval step), not at agent discipline.

## The incident log format

Every rollback, every compensating-forward, and every close call writes a new entry in `.deploy-ready/incidents/`. The pattern matters more than the blast radius; a three-minute near-miss that nobody noticed is exactly the shape the next outage will take if the lesson is not recorded.

File naming: `NNN-short-slug.md`, numbered sequentially so sorting by filename sorts by incident chronology.

Template:

```markdown
# 003-silent-migration-lock

## Date
2026-03-11, 14:22 UTC to 15:09 UTC (47 minutes).

## Environment
prod, primary DB cluster.

## What broke
`ALTER TABLE orders ADD COLUMN region text NOT NULL DEFAULT 'us-east';` was
shipped as part of v1.10.4. The statement acquired ACCESS EXCLUSIVE on orders
for 47 minutes while Postgres rewrote the table. All write traffic queued
behind it; the API returned 504s for the duration. No user data was lost.

## What recovered it
The migration completed on its own. No intervention was possible without
terminating the backend, which would have caused more damage.

## Rollback path attempted
None. No rollback was possible; the operation could not be interrupted safely.

## Pattern
"ALTER COLUMN on populated table with default" is pattern #1 in the
zero-downtime-migrations guardrail catalog.

## What changes for the next deploy
- The CI migration lint (added under v1.10.5) now rejects any ADD COLUMN with
  a non-null default on a table with more than 1M rows.
- The deploy plan for the next data-forward change names the restore point
  explicitly and walks the expand/contract calendar.
- STATE.md "in-progress expand/contract cycles" block is load-bearing; next
  session reads it.

## Owner
@hp
```

The value of the incident log compounds. After ten entries, the patterns cluster. Two of those ten will be the same pattern dressed in different clothes, and the plan for the eleventh deploy can reference the pattern directly instead of re-deriving it from pain.

## Rollback paths that lie

A catalog of common false rollback claims. Each looks reasonable at review time and fails at incident time.

| Claim | Why it lies |
|---|---|
| "git revert the migration commit" | `git revert` generates a commit that undoes the diff. It does not undo the schema change in the running database; the migration already ran. Reverting the code leaves the schema in the post-migration state. |
| "redeploy the previous image after we dropped the column" | The previous image's code still expects the column. It will start and then error on every read. |
| "manual DB restore from last night's backup" | If the backup was never tested, the restore is a wish. If it was tested six months ago, the procedure has drifted. If you have not run it this quarter, treat it as broken until rehearsed. |
| "the rollout is canary; we can just reverse the canary" | True only for a code-only change. If the canary pod's version ran migrations or wrote data, reversing the traffic does not reverse the data. |
| "undo the feature flag" | Only works if the flag actually gates the full code path. If the new code runs regardless (flag controls only display, or the flag check is on the wrong side of the mutation), flipping the flag does not roll back the behavior. |
| "email the Stripe API to reverse the charge" | Stripe will refund, not reverse. The fee is still charged. The accounting entry exists. If your system had side effects on the capture (invoice issued, webhook fired, metrics emitted), those do not unshape. |
| "re-run the old migration to recreate the column" | Recreates an empty column of the right name. Every row is null or default. The prior data does not come back. This is a compensating-forward at best, and the quality depends on whether the data can be re-derived. |

At plan-review time, read every "rollback" bullet and ask: which of these is it? If it matches any row above, the bullet is wrong and must be rewritten as compensating-forward, restore-from-point, or honest-acknowledgement-of-no-undo.

## Side-effect rollback reality

Emails sent are sent. Payments captured are captured. Webhooks emitted are emitted. SMS messages delivered are delivered. Segment events recorded are recorded. Third-party state changes propagated to partners' systems are in those systems now. A rollback of your code does not reach into the recipients' inboxes and retract the emails, does not reach into Stripe and reverse the captures, does not reach into the webhook subscriber's database and undo the row they wrote.

The only honest responses to a bad side-effectful deploy are:

1. **Stop the bleeding.** Disable the code path emitting the side effect. This is a code-only change and rolls back normally.
2. **Communicate.** To users who received the wrong email, the wrong charge, the wrong notification. Fast, factual, apologetic.
3. **Compensate.** Refund the charges. Issue a correction email. If the partner system got a wrong webhook, send them a corrected webhook and confirm receipt.
4. **Prevent the next one.** Idempotency keys on every mutation. A feature flag around any new side-effectful code path. A canary step that verifies the side effect is the intended one before rollout to 100%.

The deploy plan for every side-effectful change includes, explicitly: "Rollback: the side effect is not recoverable. Compensating action is [refund / correction email / corrected webhook]. Idempotency guard prevents duplicate emissions on retry." If the plan says "rollback: revert the code" next to a Stripe capture or a SendGrid send, it is wrong.

## Pre-prod rollback drill: the 10-minute check

A checklist engineers can run against staging (or an equivalent prod-shaped environment) to verify that the rollback path actually works. Run before any ship that relies on the path; run on the cadence above even when nothing is shipping.

```
1. Note the currently-deployed artifact ID and the previous one.
   $ flyctl releases list -a myapp | head -5
   Expected: two valid artifact IDs.

2. Trigger a rollback to the previous artifact.
   $ flyctl releases rollback $PREVIOUS_ID -a myapp
   Expected: rollback completes; new deployment started.

3. Watch the rolling update.
   $ flyctl status -a myapp --watch
   Expected: every instance transitions to the previous version within 3 min.

4. Smoke-check the critical path.
   $ curl -f https://staging.myapp.com/healthz
   $ curl -f -XPOST https://staging.myapp.com/login ...
   Expected: 200 on health; 200 on a login; one read returns expected shape.

5. Verify the version pinned is actually the previous one.
   $ curl -s https://staging.myapp.com/version
   Expected: returns the previous version string, not current.

6. Check logs for errors during the rollback.
   $ flyctl logs -a myapp | tail -100
   Expected: no unhandled errors, no crash loops.

7. Return to current.
   $ flyctl releases rollback $CURRENT_ID -a myapp
   Expected: forward roll succeeds.

8. Record the timestamp and outcome in STATE.md.
```

Ten minutes, done quarterly, catches every class of rollback-path rot: a missing artifact, a broken reverse health check, a config that was baked into the image only in the new version, a dependency the old version needs that was removed from the environment.

The equivalent for compensating-forward drills (on staging DB snapshots) is longer; the shape is the same. Take a snapshot, run the bad migration against it, run the compensating-forward, verify row counts and checksums match expected. Document the time-to-correct and the script that corrected it.

## What goes in `.deploy-ready/rollback.md` (per service)

Every service in the app has a dedicated rollback doc, kept current at every deploy boundary. Template:

```markdown
# Rollback: api service

## Last rehearsed
2026-03-18 against staging. Time to revert: 94 seconds. Outcome: green.

## Reversible-change rollback
Command: `flyctl releases rollback $ID -a api-prod`
Expected time: 60 to 120 seconds.
Who can run it: anyone in @team-infra with prod credentials.
Post-rollback verify: `curl -f https://api.myapp.com/healthz`; smoke login.

## Data-forward rollback
Not available. See the migration's compensating-forward entry in
`.deploy-ready/PLAN.md` and the restore point in
`.deploy-ready/migrations/calendar.md`.

## Side-effect rollback
Email sends: idempotency keyed on (user_id, template_id, day).
Payment captures: not reversible; refund via Stripe dashboard if needed.
Webhooks: downstream consumers are idempotent on event_id.

## Known-bad rollback paths
- Do NOT run `prisma migrate reset`. It drops the DB.
- Do NOT `git revert` a migration commit and re-deploy; the DB state is
  already advanced.
- Do NOT roll back past v1.11.7 without explicitly ensuring the orders table
  still has the `region` column. The expand phase shipped in v1.11.7; older
  code does not know the column exists but does tolerate extra columns;
  older code before v1.11.0 does NOT tolerate it and will fail validations.
```

Paste this in every new service's `rollback.md` on first deploy. Update at every deploy boundary. Read it before every rollback attempt.

## Further reading

- Jasmin Fluri, [Database Rollbacks in CI/CD](https://medium.com/@jasminfluri/database-rollbacks-in-ci-cd-strategies-and-pitfalls-f0ffd4d4741a). The fix-forward framing.
- Liquibase, [Database Rollbacks: the DevOps approach](https://www.liquibase.com/blog/database-rollbacks-the-devops-approach-to-rolling-back-and-fixing-forward). Rollback vs. fix-forward as a deliberate choice.
- Kosli, [Knight Capital: a story about DevOps automated governance](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/). The canonical flag-lineage incident.
- GitLab, [2017 database outage postmortem](https://about.gitlab.com/blog/postmortem-of-database-outage-of-january-31/). Five recovery mechanisms silently disabled at deploy time; the lesson on restore-point verification.
- AI Incident Database entry [#1152](https://incidentdatabase.ai/cite/1152/) on the Replit / SaaStr production wipe. The destructive-command gate failure in its modern AI-agent form.
