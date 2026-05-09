# Preflight and gating

Loaded at Step 1 (pre-flight) and Step 9 (pre-deploy checklist). This file owns two jobs: the 10 pre-flight questions the agent must answer in writing before any ship, and the four gate types the pipeline must enforce before any promotion. Read Step 1 before writing any plan text; read Step 9 right before the final promote.

## Part 1, the 10 pre-flight questions

Answer all 10 in writing. Missing answers are not neutral; they are assumptions, and an unnamed assumption is how first-deploy blindness and paper canaries ship. If the request is vague, pick the default from the table at the end of this section, state it in one paragraph, and proceed.

### 1. What is shipping

Why it matters: a ship without a one-sentence description cannot be classified in Step 5. You cannot plan a rollback for "a bunch of changes"; you can plan one for "feature flag flip that defaults analytics tracker to v2 for 10% of users."

Good answer: "Ship PR #412, which renames `users.avatar_url` to `users.avatar_href`, ships the read path that tolerates either column name, and keeps the old column populated. This is the code-shift phase of an expand/contract cycle whose expand landed in v1.11.7."

Bad answer: "Deploy main." What is in main? A README update, a schema rewrite, and a payment-processor swap ship wildly differently. "Deploy main" is the class of request that ends in an unclassified data-forward change, see Step 5.

Missing answer: treat the diff as the source of truth. Read `git diff <last-deploy-version>..HEAD` and summarize. State the summary as the assumption.

### 2. Build provenance

Why it matters: the same-artifact invariant is Tier 1 requirement #3. An artifact rebuilt per environment is a prolific source of dev/prod drift. The bytes the agent validated in staging are not the bytes that ship to prod unless they are literally the same bytes.

Good answer: "Docker image `registry.example.com/api:sha-abcd1234` built once in the `build.yml` workflow on commit abcd1234. The same content-hashed image promotes through staging, canary, and prod."

Bad answer: "Each environment's workflow builds its own container from the Dockerfile." This is per-environment rebuilds. Not only do the content hashes diverge, but subtle differences (base image pin drift, transient dependency resolution) make the environments test different software.

Missing answer: inspect the pipeline. If there is a `build` step in the promote workflow, it is probably rebuilding. Flag it; call it out as Tier 1 blocker.

### 3. Target environments

Why it matters: a terminal-environment-only plan ("deploy to prod") skips the promotion ladder and hides parity gaps. Naming the full path makes parity auditable and surfaces the gates.

Good answer: "`preview -> staging -> canary (10% for 15 min) -> prod (rolling)`. All use the same artifact from Build. Approval gate between staging and canary; automated rollback on canary metric breach."

Bad answer: "prod." Where did the artifact come from? What caught the regression that didn't get caught? Unnamed ladders mean the canary is a paper canary and the gate is convention.

### 4. Topology

Why it matters: topology determines the failure surface. A rolling update on a long-running service has different first-deploy hazards than a serverless function deploy, which differs again from a static-bundle CDN push. `deployment-topologies.md` has per-topology hazards; you cannot read the right hazard list without naming the topology.

Good answer: "Long-running container service on Fly.io, three regions, rolling update with 30% per wave, readiness probe on `/healthz` with DB ping."

Bad answer: "web app." Which part? The static bundle has one failure shape; the API has another; the worker has a third.

### 5. Data-layer involvement

Why it matters: this question determines whether Step 6 is mandatory. Code-only changes get a rollback; data-forward changes get a compensating-forward plan. Getting this wrong produces the worst class of broken deploy plan, the "rollback: redeploy the previous image" bullet on a migration that cannot be undone.

Good answer: "Data-forward. Migration adds a nullable `users.locale` column (expand phase). No backfill in this ship; backfill is scheduled for N+1. Old code continues to work because the column is nullable and unread."

Bad answer: "A small migration, nothing to worry about." This is how populated-column `NOT NULL` defaults ship. See the guardrails in `zero-downtime-migrations.md`.

Missing answer: inspect the diff. Any files under `migrations/`, `prisma/migrations/`, `alembic/versions/`, `db/migrate/`, or any `.sql` file in the diff means data-forward until proven otherwise. Default to Mode E routing.

### 6. Stateful side effects

Why it matters: side-effectful changes (email send, payment capture, webhook emission) have no rollback. If the code ships and sends 10,000 emails and you revert the artifact, the emails still went out. The plan has to acknowledge that; pretending otherwise is worse than naming it.

Good answer: "This ship enables a new welcome email on first login. Idempotency key is the user id plus a content hash, so a retry does not duplicate. Rollback does not recall emails that have been sent; users who received the email during the canary window will keep it."

Bad answer: silence. If a change triggers webhooks or sends money, you cannot discover that on Tuesday after shipping on Monday.

### 7. Blast radius

Why it matters: blast radius drives the rollout strategy in Step 7. A change with a 100-user blast radius can ship all-at-once to a small staging fleet; a change with a 10M-user blast radius that goes 0-to-100 uniform in one step is the CrowdStrike shape ([CrowdStrike RCA](https://www.crowdstrike.com/en-us/blog/channel-file-291-rca-available/)), the Cloudflare 2019 shape ([Cloudflare](https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/)), and the Facebook 2021 shape ([Cloudflare writeup](https://blog.cloudflare.com/october-2021-facebook-outage/)).

Good answer: "Worst case: 100% of the API fleet returns 500 on the new endpoint. Affects approximately 2M MAU. Mitigation: canary at 10% in a single region for 15 minutes with automated rollback on p99 error > 1%."

Bad answer: "Shouldn't be bad." Quantify. If you cannot, simulate the failure: "if every byte in this artifact is the opposite of what it should be, what happens?" That is the blast-radius floor.

### 8. Rollback path

Why it matters: an untested rollback is a paper rollback. Tier 3 requirement #12 is explicit: the revert command has been run against a non-prod copy within the last 90 days. GitLab 2017 had five recovery mechanisms silently broken at deploy time ([GitLab postmortem](https://about.gitlab.com/blog/postmortem-of-database-outage-of-january-31/)); none of them were rehearsed.

Good answer: "For the code change: `flyctl releases rollback v1.12.2`, rehearsed against staging 2026-03-18, time-to-revert approximately 90 seconds. For the schema change: forward-only; compensating-forward migration is in `migrations/20260423_compensate_avatar_rename.sql` with restore point from nightly snapshot plus WAL."

Bad answer: "We'll redeploy the previous image if something goes wrong." Does the previous image know about the new schema? If not, this is a partial-deploy footgun.

### 9. Feature flag lineage

Why it matters: reused flag names revive dormant code. This is the Knight Capital failure mode ([Kosli](https://www.kosli.com/blog/knight-capital-a-story-about-devops-automated-governance/); [Henrico Dolfing](https://www.henricodolfing.com/2019/06/project-failure-case-study-knight-capital.html)). A flag that once gated "Power Peg" code was re-purposed; the old code was never deleted; on partial deploy the 8th server woke the old code up and caused $460M in 45 minutes.

Good answer: "New flag: `enable_v2_avatar_path`. No prior flag with this name in the last 18 months of git history. Old avatar path is deleted as part of this ship, not gated behind a flag."

Bad answer: "Yes we have a flag." What flag. With what history. Does the code gated by the off-path still exist? If yes, document it; if no, document that too.

### 10. Approval posture

Why it matters: an approval gate enforced by convention ("ping someone in Slack") is not a gate. A gate is enforced by the pipeline: environment protection rules, required reviewers, signed approvals. Tier 2 requirement #7 is explicit on this.

Good answer: "GitHub environment protection rule on `prod` requires review from `@team-infra`. The promotion job cannot dispatch without an approved review. Approvers are rotating on-call; the on-call calendar is linked from the environment settings."

Bad answer: "Our team lead approves in Slack." Slack approval is auditable but not enforced. A pushed branch with the right permissions bypasses Slack entirely.

## Default-assumption table for vague requests

If the user says "deploy this to prod" and nothing else, pick these defaults, state them in one paragraph, and proceed. Do not interrogate.

| Question | Default |
|---|---|
| What is shipping | The diff from the last successful prod ship to HEAD; summarized. |
| Build provenance | Mode B: same artifact promoted from staging. If the pipeline rebuilds, flag it. |
| Target environments | The path recorded in `.deploy-ready/TOPOLOGY.md`. If none, `staging -> prod` as a minimum. |
| Topology | Quoted from `.deploy-ready/TOPOLOGY.md` or `.stack-ready/DECISION.md`. |
| Data-layer involvement | Inspected from the diff. Any migration file present means data-forward until proven otherwise. |
| Stateful side effects | None, unless the diff touches email, payment, webhook, or third-party API code. Flag any such path. |
| Blast radius | All prod users of the affected surface. Cannot be smaller by assumption. |
| Rollback path | The previous artifact hash, if the change is reversible. Compensating-forward required otherwise. |
| Feature flag lineage | No reuse. Flag any match against prior flag names in the last 18 months of git history. |
| Approval posture | Pipeline-enforced. If not configured, flag as Tier 2 blocker. |

State the defaults in one paragraph at the top of the plan. The user will redirect if a default is wrong.

## Part 2, the subsequent-deploy checklist (Mode B)

Mode B (subsequent deploy) is the common case. The full first-deploy checklist from `first-deploy-checklist.md` is unnecessary because the environment, DNS, cert, IAM, registry, and env vars are already verified. The Mode B checklist is narrower.

| Check | Pass when |
|---|---|
| Environment exists and was healthy before this ship | `.deploy-ready/STATE.md` records a green last-deploy state. |
| Change-class classified per Step 5 | Every change in the diff appears in the reversible/data-forward/mixed/side-effectful table. |
| Migrations are in the correct phase | If data-forward, the phase is named and matches the calendar entry. No destructive DDL without a restore point. |
| Canary criteria met, if a canary is planned | Named metric, threshold, window, automated rollback trigger. Otherwise no canary is claimed. |
| Last deploy known-green | The last ship's post-deploy checks passed; no in-flight incident rolled into this session. |
| Rollback path still current | The rollback command still points at a valid prior artifact (the prior artifact has not been deleted from the registry by retention policy). |
| Approval gate configured and not bypassed | The environment protection rule is still on; no workflow changes disabled it. |

Any failure here is a block. A Mode B ship with an unclassified change is the same bug as a Mode A ship without DNS: you shipped without knowing what you shipped.

## Part 3, the four gate types

The pipeline is not the tool. The pipeline is the set of gates the change must pass on its way to prod. Every pipeline has exactly four gate types. Any gate enforced by convention rather than by the pipeline is a Tier 2 blocker.

### Build gate

The artifact is hermetic, hashed, and reproducible. Any build that produces a different hash on the same input is not a build; it is a non-deterministic operation that happens to produce artifacts.

Enforced by the pipeline:

- The build step runs in a pinned image (not `node:latest`, not `python:3`, but `node:20.11.1-bookworm-slim@sha256:...`).
- Dependencies are resolved from a lockfile, not a manifest.
- Source tree is a checkout of a specific commit SHA, not a branch.
- Output is a single named artifact with a content hash recorded in the pipeline logs.

Enforced by convention (reject): "we rebuild in each environment's workflow," "the Dockerfile pulls `latest`," "the build is fine, we just don't hash it."

### Test gate

`repo-ready` territory is green. Deploy-ready does not add tests; it refuses to promote past this gate without a green outcome from the test layer.

Enforced by the pipeline:

- The `test` job is a required check on the pull request and on the main branch.
- The promote workflow has a `needs: test` dependency; promotion cannot start until test is green.
- Flaky tests are quarantined, not ignored.

Enforced by convention (reject): "CI is usually green, we merge when it's yellow," "we skip failing tests in the deploy workflow."

### Security gate

The artifact is scanned; no secrets are baked in. The scan runs on the artifact itself (the built image, the built bundle), not just on the source tree. The source might be clean and the image might still leak; Docker Hub surveys found over 10,000 images leaking credentials via `COPY .` patterns ([Intrinsec](https://www.intrinsec.com/en/docker-leak/); [BleepingComputer](https://www.bleepingcomputer.com/news/security/over-10-000-docker-hub-images-found-leaking-credentials-auth-keys/)). GitGuardian's 2026 data records roughly 2x baseline secret leak rate on AI-assisted commits ([dev.to / GitGuardian](https://dev.to/mistaike_ai/29-million-secrets-leaked-on-github-last-year-ai-coding-tools-made-it-worse-2a42)).

Enforced by the pipeline:

- Image scan (Trivy, Grype, Snyk Container) runs on the built image before push.
- Dependency audit (npm audit, pip-audit, bundler-audit, etc.) runs on the artifact's lockfile.
- Secret scan (TruffleHog, GitGuardian, gitleaks) runs on the built artifact's file layers, not only the source.
- `pull_request_target` workflows do not check out untrusted fork code with secret access (see the [timescale/pgai advisory](https://github.com/timescale/pgai/security/advisories/GHSA-89qq-hgvp-x37m) and [Orca's pull_request_nightmare](https://orca.security/resources/blog/pull-request-nightmare-github-actions-rce/)).

Enforced by convention (reject): "we scan in dev," "we trust the base image," "we don't run secret scans on binaries."

### Approval gate

A pipeline-enforced approval between pre-prod and prod. Not a convention; not a Slack ping; not "we usually remember."

Enforced by the pipeline (concrete patterns):

- **GitHub:** environment protection rules. Create an environment named `prod` under repo settings; set required reviewers and a wait timer if desired; the `deploy-prod` job targets `environment: prod`, and the job cannot start until a required reviewer approves. Combine with branch protection (main-only promotion) and the 2025-11-07 `pull_request_target` changes ([GitHub changelog](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/)).
- **GitLab:** environment approval rules. Configure the `prod` environment with a manual job and protected environments; set the required approval count and the approver group. The pipeline will not transition without the approval.
- **Argo CD:** sync waves and manual sync. Mark the prod Application for manual sync; use `argocd-rollouts` for progressive delivery with analysis runs as automated gates. Combine with RBAC on the `Sync` action so only approvers can trigger it. Note: auto-sync, if enabled on prod, disables the gate ([Devtron comparison](https://devtron.ai/blog/gitops-tool-selection-argo-cd-or-flux-cd/)).
- **Flux:** use manual reconciliation for prod or introduce a gating step via Flagger. Flux lacks first-class approval UX; the pattern is to put the approval upstream in the pull request to the environment's git branch.
- **Jenkins / Buildkite / CircleCI:** manual approval block with RBAC. The approval step is configured in the pipeline file and the RBAC scopes the approvers.

Enforced by convention (reject): "we ping the lead in Slack," "we deploy when the team is around," "we use a convention that only merging after review means ship to prod."

## Pre-deploy checklist summary table

The agent uses this table as the final walk before declaring a deploy ready. Every row must be green or have a named exception with a one-sentence justification.

| Check | Mode A | Mode B | Block if fail |
|---|---|---|---|
| 10 pre-flight questions answered | Yes | Yes | Yes |
| Topology note written | Yes | Quoted from last | Yes |
| Environment exists and reachable | Verify | Verify | Yes |
| DNS / TLS / IAM / registry | Verify | Assume, spot-check | Yes for A, warn for B |
| Env vars set in platform | Verify, cold | Diff only | Yes |
| Build gate: hermetic, hashed artifact | Verify | Verify | Yes |
| Test gate: repo-ready green | Verify | Verify | Yes |
| Security gate: scans clean | Verify | Verify | Yes |
| Approval gate: pipeline-enforced | Verify | Verify | Yes |
| Change-class classified | Yes | Yes | Yes |
| Migration phase named | If data-forward | If data-forward | Yes |
| Rollback path current and rehearsed | Yes | Yes | Yes for reversible; compensating-forward for data-forward |
| Canary criteria met (if canary) | Four fields present | Four fields present | Yes; else downgrade to all-at-once |
| Feature flag lineage checked | Yes | Yes | Yes |
| Observability reach confirmed | If canary | If canary | Yes if claiming canary |
| STATE.md ready for post-deploy update | Yes | Yes | No; but required before session end |

Walk this top to bottom. The first row that fails is the next thing to fix, not a note for later. "Later" is where paper canaries and expand-only traps live.

## Further reading

- 12-factor, factor X on dev/prod parity: https://12factor.net/dev-prod-parity
- `environment-parity.md` (Step 3) for the parity gaps and drift audit.
- `first-deploy-checklist.md` (Mode A) for the cold-start gates.
- `progressive-delivery.md` (Step 7) for the paper-canary rule and blast-radius limits.
- `rollback-playbook.md` (Step 11) for code-vs-data asymmetry and compensating-forward.
