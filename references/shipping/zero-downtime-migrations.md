# Zero-downtime migrations

The phrase "zero-downtime migration" is almost always a lie when used to describe a single deploy. The correct unit of planning is not the migration. It is the **deploy calendar**. A migration that moves data safely across a live system is always at least three deploys, and usually four, spaced by enough time that every running version of the app has rolled before the next phase ships. If your plan says "apply the migration, deploy the code, done," the plan is wrong and the outage is scheduled.

This file is the technical core of deploy-ready. Step 6 loads it. Every data-forward change passes through its guardrails before it is allowed to ship. The invariant behind all of them is the one from SKILL.md: **what rolls back is code, not data.** Code is a byte sequence in a registry; you can swap it out. Schema changes advance the state of the world and cannot be unshipped. Every pattern below exists because some team, somewhere, learned that the hard way, usually at 3am.

## The deploy calendar, not the single migration

Expand/contract is not a technique. It is a scheduling discipline. It forces you to write migrations as a sequence of small, individually-reversible, individually-deployable steps, interleaved with the code deploys that shift between old and new shapes.

The canonical reference is Martin Fowler's [Parallel Change](https://martinfowler.com/bliki/ParallelChange.html), first documented by Joshua Kerievsky in 2006 and presented at LSSC 2010. The four phases, in the order the calendar runs them:

| Phase | Ships | Content | Guardrail |
|---|---|---|---|
| **Expand** | Deploy N | Additive DDL only. New column nullable. New table unreferenced. New index `CONCURRENTLY`. | Old readers and writers must continue to work unchanged. |
| **Migrate / backfill** | Deploy N, or a batched job after | Dual-write. Backfill old rows into the new shape, batched, outside the DDL transaction. | Never in the same transaction as the schema change. |
| **Cutover** | Deploy N+1 | Code shifts reads and writes to the new shape. Old structure still present. | Rolling update completes before the next phase. Every pod is on the new code. |
| **Contract** | Deploy N+k, k >= 1 full rollout cycle | Destructive DDL removes the old structure. | Ships as its own deploy, never the same ship as expand. |

The calendar is load-bearing. Expand and contract are not the same deploy, because between them you need every running pod to have rolled onto the code that tolerates both shapes, and then onto the code that uses only the new shape. Collapsing the calendar is the single most common failure mode in AI-generated migration plans. The LLM sees "migration" and produces a single SQL file. The correct output is three SQL files and a calendar.

Tim Wellhausen's [Expand and Contract paper](https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html) and [Prisma's Data Guide entry](https://www.prisma.io/dataguide/types/relational/expand-and-contract-pattern) are both practical references that say the same thing in different words. Read either.

### What happens when you skip the calendar

If expand ships in the same deploy as the code that reads the new column, and the rolling update is not instantaneous, old pods are reading a column that does not exist. Errors. If cutover ships in the same deploy as contract, the rollback target (the code that tolerates both shapes) never existed in prod. You have no valid rollback. If contract ships before every pod is on the new code, old pods are reading a column that has just been dropped. Errors, again.

The calendar exists to keep every intermediate state a valid rollback target. Skip a rung and the rollback path collapses.

## Branch-by-abstraction: the code-level equivalent

Schema decomposition has a code-level sibling. [Branch-by-abstraction](https://paulhammant.com/blog/branch_by_abstraction), introduced by Paul Hammant and elaborated on [Fowler's bliki](https://martinfowler.com/bliki/BranchByAbstraction.html) and [continuousdelivery.com](https://continuousdelivery.com/2011/05/make-large-scale-changes-incrementally-with-branch-by-abstraction/), is how you swap a large internal dependency (a persistence layer, a messaging system, a payment provider) without a long-lived feature branch and without a single-shot cutover.

The pattern:

1. Introduce an abstraction layer between the callers and the thing being replaced.
2. Move the existing implementation behind the abstraction (no behavior change).
3. Add the new implementation behind the same abstraction, guarded by a flag.
4. Migrate callers one at a time. Run both in parallel if needed.
5. Remove the old implementation and the flag.

The relevance to deploy-ready: the app layer between your code and the database is itself a branch-by-abstraction target. If your data-access layer tolerates both the old and the new schema, you can ship the expand phase, leave it for a rollout cycle, ship the code that uses the abstraction, and only then cut reads and writes. The abstraction is what lets each phase be a valid rollback target.

## Shadow writes and dual writes

Stripe's [Online migrations at scale](https://stripe.com/blog/online-migrations) is the canonical industry writeup of the four-phase dual-write pattern. The phases are essentially expand/contract applied to whole tables rather than single columns:

1. Dual-write to both the old and the new table on every mutation.
2. Change reads to the new table.
3. Stop writing to the old table.
4. Drop the old table.

Stripe ran Hadoop jobs for the backfill and used Scientist-style comparison experiments between the two stores to detect drift before each phase boundary. See also the [HN discussion](https://news.ycombinator.com/item?id=13554254) and [Simon Willison's notes](https://simonwillison.net/2023/Nov/5/online-migrations-at-scale/).

The failure mode dual-writes introduce is silent divergence. If the old write succeeds and the new write fails (or vice versa), and nothing in the app surfaces the failure, the two stores drift. Christoph Bussler's frank writeup, [Online Database Migration by Dual-Write](https://medium.com/google-cloud/online-database-migration-by-dual-write-this-is-not-for-everyone-cb4307118f4b), is the right counterweight: dual-write is not for everyone, and the failure modes include silent data divergence with no way to recover ground truth. If you cannot replay or reconcile, you cannot dual-write safely.

The guardrails around dual-write:

- **Write both or write neither.** Wrap both writes in a single transaction where possible, or use an outbox pattern with a reconciling worker.
- **Compare continuously.** A Scientist-style harness that reads both on every read path and alerts on divergence is the only way to catch drift early.
- **Have a ground-truth store.** One of the two stores is authoritative at any moment. If both drift, you need one you can replay.
- **Backfill before cutover.** Do not shift reads to the new table until every row is present and checksum-verified.

## Online schema-change tooling

For large tables on MySQL or Percona-flavored engines, the safe path is an online schema-change tool that mirrors the change into a shadow table and atomically swaps. Two dominant tools:

| Tool | Mechanism | Supports FKs? | Impact | Notes |
|---|---|---|---|---|
| [gh-ost](https://github.com/github/gh-ost) | Triggerless. Reads the binary log to mirror changes into a ghost table. | No | Lower on live load; pausable; throttlable | Not compatible with Galera / PXC. [Bytebase on limitations](https://www.bytebase.com/blog/gh-ost-limitations/). |
| [pt-online-schema-change](https://docs.percona.com/percona-toolkit/pt-online-schema-change.html) | Trigger-based. Copies rows to a shadow table; triggers keep it in sync. | Yes | Higher on live load; ~2x faster on idle load per [Percona benchmark](https://www.percona.com/blog/gh-ost-benchmark-against-pt-online-schema-change-performance/) | Standard for FK-heavy schemas. [Severalnines comparison](https://severalnines.com/blog/online-schema-change-mysql-mariadb-comparing-github-s-gh-ost-vs-pt-online-schema-change/); [PlanetScale comparison](https://planetscale.com/docs/vitess/schema-changes/online-schema-change-tools-comparison). |

Rule of thumb: gh-ost when the workload is heavy and you can afford triggerless overhead; pt-online-schema-change when FKs are in play; either is a full order of magnitude safer on a populated table than a raw `ALTER TABLE`.

Postgres does not have an exact equivalent in the core distribution; most operations that would rewrite a table can be decomposed into add-nullable, backfill, swap, drop. Extensions like `pg_repack` and tools like Reshape and pgroll occupy an adjacent space and are worth evaluating on Postgres deployments with large tables.

## Programmatic guardrails

Manual discipline degrades. The guardrails below are the ones that run in CI or at migration time and refuse to ship unsafe DDL:

- **Rails: [strong_migrations](https://www.rubydoc.info/gems/strong_migrations/)** is the gold standard. It intercepts ActiveRecord migration methods and raises with a suggested safe alternative when you try to do something unsafe. Peer gems: [PlanetScale Rails](https://planetscale.com/blog/zero-downtime-rails-migrations-planetscale-rails-gem) and [LendingHome's zero_downtime_migrations](https://github.com/LendingHome/zero_downtime_migrations).
- **Django:** [django-pg-zero-downtime-migrations](https://github.com/tbicr/django-pg-zero-downtime-migrations) and [yandex/zero-downtime-migrations](https://github.com/yandex/zero-downtime-migrations). Both wrap the PostgreSQL backend and refuse operations that take long `ACCESS EXCLUSIVE` locks. Vintasoftware's [Django zero-downtime guide](https://www.vintasoftware.com/blog/django-zero-downtime-guide) is the practical walkthrough.
- **Prisma:** the [docs on customizing migrations](https://www.prisma.io/docs/orm/prisma-migrate/workflows/customizing-migrations) describe decomposing field changes into expand/contract steps and using `CREATE INDEX CONCURRENTLY`. Prisma does not ship a strong_migrations equivalent in core; the guardrails are documentation, not enforcement. Add a CI lint (regex the generated SQL for dangerous patterns) if you want real enforcement.
- **Framework-agnostic:** if you are not on Rails or Django, write the CI lint yourself. Grep the generated SQL in the PR for the deadly patterns listed below and fail the check. The lint costs a day to write once and saves an outage in year one.

## The guardrail catalog

Each of the patterns below is one the AI will cheerfully emit, labelled as a zero-downtime migration. Each breaks in a specific way. For each, the example of the unsafe DDL, the mechanism of the break, and the safe alternative.

### 1. `ALTER COLUMN` type change on a populated table

**Unsafe:**

```sql
ALTER TABLE orders
  ALTER COLUMN amount TYPE numeric(12, 2);
```

**Why it breaks:** Postgres rewrites the entire table under an `ACCESS EXCLUSIVE` lock. For a billion-row table this is hours of full outage. MySQL with `ALGORITHM=COPY` is the same story. The table is locked against reads and writes for the duration.

**Safe:**

```sql
-- Deploy N (expand)
ALTER TABLE orders ADD COLUMN amount_v2 numeric(12, 2);

-- Deploy N, batched job (migrate)
UPDATE orders SET amount_v2 = amount::numeric(12, 2)
  WHERE id BETWEEN $1 AND $2;  -- batched, 10k rows at a time

-- Deploy N+1 (cutover)
-- Code reads amount_v2 first, falls back to amount

-- Deploy N+k (contract)
ALTER TABLE orders DROP COLUMN amount;
ALTER TABLE orders RENAME COLUMN amount_v2 TO amount;
```

Even the rename in the contract is a hazard; do it only after every reader has shipped the code that uses the renamed column.

### 2. Adding a `NOT NULL` column in one step

**Unsafe:**

```sql
ALTER TABLE users ADD COLUMN email_verified boolean NOT NULL DEFAULT false;
```

**Why it breaks:** on Postgres < 11, adding a column with a `NOT NULL` default forces a full table rewrite under `ACCESS EXCLUSIVE`. On Postgres 11+ the default is stored as metadata and the rewrite is avoided, but adding `NOT NULL` with a backfill on an already-populated column still needs the multi-step pattern.

**Safe (Postgres, with backfill):**

```sql
-- Deploy N (expand)
ALTER TABLE users ADD COLUMN email_verified boolean;

-- Deploy N+1: application writes both old and new rows with a value

-- Batched backfill
UPDATE users SET email_verified = false
  WHERE email_verified IS NULL AND id BETWEEN $1 AND $2;

-- After backfill is complete and verified
ALTER TABLE users
  ADD CONSTRAINT users_email_verified_not_null
  CHECK (email_verified IS NOT NULL) NOT VALID;

ALTER TABLE users
  VALIDATE CONSTRAINT users_email_verified_not_null;

-- Only after validation
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;
ALTER TABLE users DROP CONSTRAINT users_email_verified_not_null;
```

The `CHECK ... NOT VALID` plus `VALIDATE CONSTRAINT` pattern takes a `SHARE UPDATE EXCLUSIVE` lock (writes keep working) instead of the `ACCESS EXCLUSIVE` that `SET NOT NULL` would otherwise take. See [strong_migrations docs](https://www.rubydoc.info/gems/strong_migrations/) for the Rails-idiomatic version.

### 3. `CREATE INDEX` without `CONCURRENTLY`

**Unsafe:**

```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**Why it breaks:** a plain `CREATE INDEX` takes a `SHARE` lock that blocks writes to the table for the entire duration of the index build. On a 500M-row table that is anywhere from minutes to hours.

**Safe:**

```sql
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
```

`CONCURRENTLY` is slower (two passes instead of one) but does not block writes. Two caveats: it cannot run inside a transaction (Rails and Django handle this automatically with the right helper), and if the build fails halfway it leaves an invalid index that must be dropped and retried. Check `pg_indexes.indisvalid` after the build.

### 4. Renaming a column still being read

**Unsafe:**

```sql
ALTER TABLE users RENAME COLUMN full_name TO name;
```

shipped in the same deploy as code that reads `name`.

**Why it breaks:** between the `ALTER` completing and the rolling update finishing, old pods are reading `full_name` (which no longer exists) and new pods are reading `name` (which just appeared). You get errors from the old pods for the duration of the rollout.

**Safe (expand/contract applied to a rename):**

```sql
-- Deploy N (expand)
ALTER TABLE users ADD COLUMN name text;
UPDATE users SET name = full_name WHERE name IS NULL;  -- batched

-- Deploy N+1 (cutover)
-- Application writes to both name and full_name
-- Application reads from name, falls back to full_name

-- Deploy N+2 (cleanup-read)
-- Application reads from name only; still writes both

-- Deploy N+3 (contract)
ALTER TABLE users DROP COLUMN full_name;
```

See Bswen's [three critical pitfalls](https://docs.bswen.com/blog/2026-04-15-avoid-irreversible-database-migration-mistakes/) and [Harness's database rollback guide](https://www.harness.io/harness-devops-academy/database-rollback-strategies-in-devops). The rename that used to be one line is now four deploys. That is the correct cost.

### 5. Backfill inside the schema-change transaction

**Unsafe:**

```sql
BEGIN;
ALTER TABLE orders ADD COLUMN region text;
UPDATE orders SET region = 'us-east' WHERE created_at < '2024-01-01';
UPDATE orders SET region = 'us-west' WHERE created_at >= '2024-01-01';
COMMIT;
```

**Why it breaks:** the `ALTER` acquires `ACCESS EXCLUSIVE` and the transaction holds it for the full duration of the backfill. On a large table, that is the full table locked against all reads and writes for many minutes to hours. See [strong_migrations on backfill](https://www.rubydoc.info/gems/strong_migrations/).

**Safe:**

```sql
-- Schema change in its own short transaction
BEGIN;
ALTER TABLE orders ADD COLUMN region text;
COMMIT;

-- Backfill in batches, outside any transaction the DDL is in
-- (run from the app or a migration runner, not in the schema migration)
UPDATE orders SET region = 'us-east'
  WHERE region IS NULL AND id BETWEEN $1 AND $2 AND created_at < '2024-01-01';
```

### 6. Missing `lock_timeout` and `statement_timeout`

**Unsafe:** any migration run without either.

**Why it breaks:** a migration that tries to acquire a lock it cannot get will queue. Every subsequent write on the table queues behind it. Even on a small table, a long-running `SELECT` holding a weak lock can block the `ALTER` for minutes; meanwhile, new writes queue behind the waiting `ALTER` and your write path is frozen.

**Safe:** set timeouts at the session level before any DDL.

```sql
SET lock_timeout = '5s';
SET statement_timeout = '2min';

ALTER TABLE users ADD COLUMN preferences jsonb;
```

If the migration cannot acquire the lock in 5 seconds, it fails and you try again during a quieter window. The alternative (no timeout) queues every writer behind the blocked `ALTER` and takes the app down. See [GoCardless on lock_timeout](https://gocardless.com/blog/zero-downtime-postgres-migrations-a-little-help/).

### 7. Dropping a column still referenced

**Unsafe:**

```sql
ALTER TABLE users DROP COLUMN legacy_role;
```

while any running pod still reads `legacy_role`.

**Why it breaks:** reads of the dropped column raise `UndefinedColumn`. If ORMs cache schema (most do), the error can persist across connections until the pool cycles.

**Safe:** contract only after one full rollout cycle has confirmed every pod is on the code that does not reference the column. The `.deploy-ready/migrations/calendar.md` entry is load-bearing here: it is the record that says "as of v1.12.0, no pod reads `legacy_role`."

```sql
-- Deploy N+k, confirmed every pod is on v1.12.0 or later
ALTER TABLE users DROP COLUMN legacy_role;
```

Before dropping, take a restore point (`pg_dump` of the column, a snapshot, a backup point that can be restored to a side table). Dropped is dropped.

### 8. Foreign key additions without `NOT VALID` + `VALIDATE`

**Unsafe:**

```sql
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id);
```

**Why it breaks:** Postgres validates the constraint against every existing row under an `ACCESS EXCLUSIVE` lock. On a large table this is minutes of full table lock.

**Safe:**

```sql
-- Add as NOT VALID (only enforces on new rows; no scan)
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id)
  NOT VALID;

-- Later, validate in a lighter-lock operation
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```

`VALIDATE CONSTRAINT` takes `SHARE UPDATE EXCLUSIVE`, which does not block writes. The same pattern applies to check constraints.

### 9. `TRUNCATE` without a restore point

**Unsafe:**

```sql
TRUNCATE TABLE audit_log;
```

**Why it breaks:** `TRUNCATE` is instant and unrecoverable. There is no "rollback" in any meaningful sense. The rows are gone.

**Safe:** never call `TRUNCATE` against prod without (a) a restore point recorded, (b) an explicit approval, and (c) a sanity check that nothing else references the table in ways that will cascade. Prefer a timestamp-based delete in batches if you can:

```sql
DELETE FROM audit_log WHERE created_at < now() - interval '90 days'
  AND id IN (SELECT id FROM audit_log
             WHERE created_at < now() - interval '90 days'
             LIMIT 10000);
```

If you must `TRUNCATE`, dump first:

```sql
COPY audit_log TO '/backup/audit_log_pre_truncate_2026_04_22.csv';
TRUNCATE TABLE audit_log;
```

See the rollback-playbook for the destructive-command gate.

### 10. Enum value changes (Postgres cannot drop enum values)

**Unsafe:**

```sql
-- Postgres does not allow this
ALTER TYPE order_status DROP VALUE 'legacy_pending';
```

**Why it breaks:** Postgres has no `DROP VALUE` on an enum. The only way to "remove" an enum value is to create a new type, migrate every column that uses the old type, and drop the old type. That is a multi-deploy operation on any populated table.

**Safe:**

```sql
-- Deploy N (expand)
CREATE TYPE order_status_v2 AS ENUM ('pending', 'paid', 'cancelled');
ALTER TABLE orders ADD COLUMN status_v2 order_status_v2;

-- Backfill
UPDATE orders SET status_v2 =
  CASE status
    WHEN 'legacy_pending' THEN 'pending'::order_status_v2
    WHEN 'pending' THEN 'pending'::order_status_v2
    WHEN 'paid' THEN 'paid'::order_status_v2
    WHEN 'cancelled' THEN 'cancelled'::order_status_v2
  END
  WHERE status_v2 IS NULL;

-- Deploy N+1 (cutover): code writes and reads status_v2

-- Deploy N+k (contract)
ALTER TABLE orders DROP COLUMN status;
ALTER TABLE orders RENAME COLUMN status_v2 TO status;
DROP TYPE order_status;
ALTER TYPE order_status_v2 RENAME TO order_status;
```

Adding enum values (`ALTER TYPE ... ADD VALUE`) is cheap and safe on Postgres 12+. Removing is the whole dance above. If you know you will want to remove values, prefer a `text` column with a `CHECK` constraint from the start.

## Data-forward discipline and the rollback asymmetry

Every pattern above exists because of a single invariant: **what rolls back is code, not data.** Code is a byte sequence in an immutable registry; you can swap it out in seconds. A schema migration that dropped a column, or a backfill that rewrote a million rows, is a forward state transition with no undo.

Jasmin Fluri's [Database Rollbacks in CI/CD](https://medium.com/@jasminfluri/database-rollbacks-in-ci-cd-strategies-and-pitfalls-f0ffd4d4741a) and [Liquibase's post on fix-forward vs rollback](https://www.liquibase.com/blog/database-rollbacks-the-devops-approach-to-rolling-back-and-fixing-forward) both arrive at the same conclusion: treat schema migrations as immutable forward-only changes. If a release fails, you write a new compensating migration; you do not reverse the previous one. PlanetScale's [revert a migration without losing data](https://planetscale.com/blog/revert-a-migration-without-losing-data) is the sharpest version of this: the answer to "revert the migration" is branching plus expand/contract discipline, because the revert itself must preserve the data path.

Practical consequence: every entry in `.deploy-ready/PLAN.md` that touches data has two fields:

- **Restore point.** A named, verified restore target (nightly snapshot + WAL to point-in-time; `pg_dump` of the affected table; side table containing the pre-mutation rows). Without this, rollback is fiction.
- **Compensating-forward plan.** What a new migration would look like that corrects the post-deploy state if the change is wrong. Written before the deploy, not after the incident.

The plan never has a "rollback: redeploy previous image" bullet next to a schema migration. If you catch yourself writing one, delete it and write the compensating-forward instead.

## A sample deploy calendar: renaming a column over 3 deploys across 2 weeks

This is the worked example. Scenario: rename `users.full_name` to `users.name`. Production table has 40M rows and a steady write rate.

**Week 1, Monday (Deploy N, expand):**

```sql
SET lock_timeout = '5s';
ALTER TABLE users ADD COLUMN name text;
CREATE INDEX CONCURRENTLY idx_users_name ON users(name);
```

Code shipped: unchanged. `full_name` is still the authoritative field.

**Week 1, Tuesday (backfill job):** batched `UPDATE` in 10k-row chunks, off-peak. Verify row count matches after completion. Update `.deploy-ready/migrations/calendar.md` with "backfill complete, checksum verified."

**Week 1, Thursday (Deploy N+1, cutover part 1):** code shipped writes to both `full_name` and `name` on every mutation. Reads prefer `name`, fall back to `full_name` if null. Roll out with a canary; confirm every pod is on the new code.

**Week 2, Monday (Deploy N+2, cutover part 2):** code shipped reads and writes only `name`. `full_name` is unreferenced in the app. Confirm again every pod is on the new code.

**Week 2, Thursday (Deploy N+3, contract):** with a recorded restore point taken the day prior:

```sql
SET lock_timeout = '5s';
ALTER TABLE users DROP COLUMN full_name;
```

Ship alone. No other changes in this deploy. Done.

Three deploys across two calendar weeks for what looks like a one-line change. That is the correct cost of the rename-without-downtime. Any plan that collapses the calendar is cheating and will page someone.

## The expand-only migration trap

The opposite of the collapsed calendar is the calendar that was started and never finished. The expand phase ships, the cutover ships, and then something else becomes urgent and the contract phase is quietly dropped from the backlog. Six months later there are three dual-schema liabilities sitting in the database: columns that nobody reads but every migration must preserve, tables that shadow each other, indexes that no longer correspond to a live query pattern.

This is the **expand-only migration trap**, and it compounds. Each unfinished expand makes the next migration harder to reason about (there are now three shapes for every table, not two). The ORM has to know about columns no code uses. The backup footprint grows. The cost of the next expand goes up because you have to decide whether to extend the old dual-schema or add a third shape.

The cure is a scheduling commitment, not a technical one. Every expand entry in `.deploy-ready/migrations/calendar.md` has a required contract ship date, with an owner, and the STATE.md "in-progress expand/contract cycles" block blocks the next migration's planning review until the previous contract is either shipped or explicitly deferred with a dated justification.

If you see a codebase with five columns named `*_v2`, `*_new`, or `legacy_*`, you are looking at an expand-only migration trap that never got paid off. Pay it off before you add a sixth.

## Relevant incidents

A few of the patterns above are not theoretical. They are named failures.

- **GitLab.com, 2017-01-31** ([postmortem](https://about.gitlab.com/blog/postmortem-of-database-outage-of-january-31/)): 300GB of production data lost; 6 hours of user edits gone. The compounding deploy-level failures included `pg_dump` backups not running (a deploy-time config regression), alert emails for backup failure silently rejected by DMARC, and replication to the secondary already broken. Five recovery mechanisms, silently disabled at deploy time. The lesson for migrations: the restore point you cite in the deploy plan must be verified recently, not just assumed.
- **Stripe online migrations** ([blog](https://stripe.com/blog/online-migrations)): the four-phase dual-write pattern is what made large-scale migrations safe at Stripe. The writeup is the closest thing the industry has to a reference implementation.
- **Knight Capital, 2012** ([Kosli writeup](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/)): not a schema migration, but a partial deploy where old code on one server interacted with a reused feature flag. The rollback worsened things because the team re-deployed the new-with-reused-flag to all servers, spreading the defect. Cross-referenced in rollback-playbook under flag-lineage discipline. The shape of the failure (old code alive during cutover) is exactly what the expand/contract calendar exists to prevent.

## Further reading

- Martin Fowler, [Parallel Change](https://martinfowler.com/bliki/ParallelChange.html). The canonical expand/contract reference.
- Stripe, [Online migrations at scale](https://stripe.com/blog/online-migrations). Dual-write patterns at production scale.
- [strong_migrations](https://www.rubydoc.info/gems/strong_migrations/) docs. The best single-page list of dangerous migration patterns and their safe alternatives.
- GoCardless, [Zero-downtime Postgres migrations, a little help](https://gocardless.com/blog/zero-downtime-postgres-migrations-a-little-help/). The lock_timeout pattern and why it matters.
- Christoph Bussler, [Online Database Migration by Dual-Write](https://medium.com/google-cloud/online-database-migration-by-dual-write-this-is-not-for-everyone-cb4307118f4b). The honest counterweight on when dual-write fails silently.
