# Deploy-ready antipatterns

Named failure modes deploy-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand at every cutover, every rollback rehearsal, and every Mode C audit of an existing deployment pipeline. Complements `references/pipeline-patterns.md`, `references/zero-downtime-migrations.md`, and `references/rollback-playbook.md`.

## Core principle (recap)

> Same artifact, promoted across environments. Never rebuilt between staging and prod. Code rolls back fast; data rolls back via expand-contract or backup.

The patterns below are violations of this principle.

## Pattern catalog

### Different-artifact promotion (Critical)

**Shape.** The CI pipeline builds the artifact for staging, ships it, then builds AGAIN for prod with potentially different deps / env / config. Two builds, "same code", different artifacts. Subtle bugs ship.

**Grep test.** The same Docker image SHA (or Vercel deployment ID, or equivalent) that ships to staging is the one promoted to prod. Pipelines that have a `build-prod` step distinct from `build-staging` fail.

**Guard.** `references/pipeline-patterns.md` mandates one-build-many-promote. Step 2 of the cutover playbook verifies the artifact SHA matches.

### Expand and contract in the same deploy (Critical)

**Shape.** A migration that drops a column AND ships the code that no longer reads from it in the same deploy. If anything goes wrong, rollback breaks because the new code is in the rolled-back image but the old column is gone.

**Grep test.** Every DB migration is classified as `expand` (additive: new column, new index) or `contract` (destructive: drop column, drop table). Deploys that ship a contract migration without first running the expand migration in a prior release fail.

**Guard.** `references/zero-downtime-migrations.md` mandates expand-contract as a multi-deploy calendar. Two deploys minimum: deploy 1 expands and the code reads both columns; deploy 2 contracts after the new column is fully populated.

### Code-vs-data rollback symmetry assumption (High)

**Shape.** Rollback procedure says "if anything goes wrong, redeploy the prior image." But the deploy ran a destructive migration. The prior image now talks to a schema that doesn't match.

**Grep test.** The rollback procedure documents code-vs-data asymmetry: code rollback (redeploy prior image) is fast and safe; data rollback requires a forward-fix migration or a PIT restore. Procedures that promise symmetric rollback fail.

**Guard.** `references/rollback-playbook.md` is explicit about the asymmetry. The cutover playbook lists the rollback steps; data rollback always requires a named human decision, not a click.

### Paper canary (Critical)

**Shape.** "Canary deploy" that gets 100% of traffic from minute 1. Or a canary that traffic-shifts from 0% to 100% in 30 seconds with no time for telemetry to surface a regression.

**Grep test.** Canary plan names: traffic percentage curve, observation window per percentage, named rollback trigger metrics, named rollback procedure. Plans missing any of these fail.

**Guard.** `references/progressive-delivery.md` carries the canonical canary curves. The deploy-ready discipline names "paper canary" as a refusal.

### First-deploy-as-discovery (High)

**Shape.** The first prod deploy is when the team figures out what env vars are needed, what secrets need to be set, what DNS records need to point where. An hour into the deploy ceremony, someone is editing the Vercel dashboard live.

**Grep test.** A pre-prod environment (`staging.app.com`, `dartlogic-stage.app.com`, etc.) ran the same artifact for at least one week before prod. Every env var, every secret, every config is exercised in pre-prod.

**Guard.** Step 6 of the cutover playbook verifies pre-prod parity. The cutover discipline mandates a pre-prod soak period.

### Drift between staging and prod (Critical)

**Shape.** Staging is on Postgres 14; prod is on Postgres 15. Staging uses the in-memory cache; prod uses Redis. Staging Auth.js secret is hardcoded; prod is from a vault. Tests pass on staging; prod breaks on something staging doesn't have.

**Grep test.** Environment parity check: list (DB version, cache, auth provider, all third-party SaaS, all env vars) for staging and prod. Unaccounted-for differences fail.

**Guard.** `references/environment-parity.md` is the canonical reference; lists the per-category checks.

### Manual secret injection via the dashboard (High)

**Shape.** Secrets get into prod by someone clicking "Add environment variable" in the platform dashboard. No git-tracked source of truth. When the team rotates the secret, the dashboard is the only record.

**Grep test.** Secret source-of-truth is named (Vault, Doppler, AWS Secrets Manager, Vercel env via `vercel env pull`, etc.) and the deploy pipeline injects from that source. Manual dashboard-only secrets fail.

**Guard.** `references/secrets-injection.md` is the canonical reference. The cutover playbook step 1 verifies secrets are sourced from the named system.

### Rollback never rehearsed (High)

**Shape.** The team has a rollback procedure documented. They've never run it. The first time it fires is during a real incident; it doesn't work because one step refers to a tool nobody installed.

**Grep test.** A rollback rehearsal happened in the last 90 days. Specifically: the team triggered a synthetic regression in pre-prod and walked the rollback playbook end-to-end.

**Guard.** `references/rollback-playbook.md` mandates a rehearsal cadence. The cutover plan for a first-prod deploy rehearses rollback in pre-prod the week before.

### Hands-on prod shell (Critical)

**Shape.** The deploy "completes" but a person is logged into the prod box adjusting things. `kubectl exec`, `ssh`, or platform-shell into prod is the routine, not the exception.

**Grep test.** Every change to prod state goes through a tracked pipeline (PR + deploy + observability). Manual shell sessions on prod are exception events with a logged reason.

**Guard.** Step 7 of the cutover playbook prohibits ongoing shell access during normal operations. Emergency shell sessions log to an audit channel.

### Contract migration during the pilot window (Critical)

**Shape.** During a paying-pilot validation window, a destructive DB migration ships. The pilot's data is at risk. If the pilot signs the contract, post-mortem reveals the destructive migration was unnecessary.

**Grep test.** Pilot windows (declared in `.roadmap-ready/ROADMAP.md`) prohibit `DROP COLUMN`, `DROP TABLE`, schema-rename migrations. Migrations during the window are expand-only.

**Guard.** Cutover playbook prohibits contract-phase migrations during named-windows. Schema-change PRs labeled `contract` are blocked at review during pilot windows.

### One-deploy "expand and contract" (Critical)

**Shape.** Same as above but generalized. The temptation: "I'll just do both in one deploy, it's cleaner." Not cleaner; load-bearing assumptions about read-during-migration break.

**Grep test.** Every PR that contracts (drops a column / table) has a prior PR that expanded (added the new column / new path) and shipped, with the new code paths fully exercised in prod for at least 7 days.

**Guard.** Two-deploy minimum is structural. PRs that bundle expand + contract are split at review.

### CI/CD pipeline runs `echo` for tests (Critical)

**Shape.** The deploy workflow has a "test" stage that runs `echo "tests pass"` instead of the project's actual test suite.

**Grep test.** Same as repo-ready REPO-3.2: CI commands match the project's stack tooling. Echo placeholders fail.

**Guard.** Audit-mode catches this; deploy-ready cross-checks at cutover.

### GitOps pretending to be code-promotion (Medium)

**Shape.** A "GitOps" setup where state changes happen by editing a YAML file in a repo. Deploys roll back by reverting the commit. But the rollback only reverts the YAML; the actual application state (DB schema, in-flight messages, cache) is untouched.

**Grep test.** GitOps repo's reverts cover code state only. Data state requires a forward-fix migration. The team understands the asymmetry.

**Guard.** `references/rollback-playbook.md` re-states the asymmetry for GitOps shops.

### "Same artifact" claim with build-time secrets (High)

**Shape.** Same Docker image promotes from staging to prod. But the image was built with staging API keys baked in. Prod gets the staging artifact AND prod's API keys via env injection. Confusion.

**Grep test.** Build-time secrets are forbidden. Docker images contain no API keys, no environment URLs, no secrets. Configuration injects at runtime.

**Guard.** `references/secrets-injection.md` mandates runtime injection. The cutover playbook verifies the image is config-free.

### Cutover during a freeze window (Medium)

**Shape.** Sales calls the team Friday at 4pm: "Big customer demo Monday morning, can you ship feature X by Sunday?" The team deploys Sunday night. Monday morning the demo breaks.

**Grep test.** Production freezes are declared in advance (Friday 17:00 PT through Monday 09:00 PT, by default). Cutovers during freeze windows require an explicit override + a named risk owner.

**Guard.** `references/preflight-and-gating.md` carries the freeze-window policy.

## Severity ladder

- **Critical**: blocks the cutover. Must be fixed before the deploy proceeds.
- **High**: blocks the tier gate. Must be fixed before next tier or next deploy.
- **Medium**: flagged in the cutover playbook; fix recommended.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": canonical have-nots list.
- `references/pipeline-patterns.md`: same-artifact promotion canonical patterns.
- `references/zero-downtime-migrations.md`: expand-contract calendar.
- `references/rollback-playbook.md`: code-vs-data asymmetry.
- `references/progressive-delivery.md`: canary curves and traffic-shift discipline.
- `references/environment-parity.md`: staging/prod parity checklist.
- `references/secrets-injection.md`: runtime-only secrets.
- `references/preflight-and-gating.md`: freeze-window policy.
