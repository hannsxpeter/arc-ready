# Environment parity

Loaded at Step 3. This file owns the promotion ladder, the parity gaps between its rungs, and the discipline that keeps the gaps from silently widening. Parity is the thing you lose by default. No one ever ships a deploy that accidentally made staging more like prod; they ship deploys that make staging a little less like prod, and the gap compounds.

## The four parity gaps

The Twelve-Factor App names three gaps between dev and prod ([12factor.net, factor X](https://12factor.net/dev-prod-parity)). Deploy-ready names a fourth. All four apply to every rung of the promotion ladder, not just the dev-to-prod boundary.

| Gap | What it is | Twelve-factor or deploy-ready |
|---|---|---|
| **Time** | The delay between a change landing in dev and reaching prod. Bigger delays mean bigger batches mean more coupled failures. | 12-factor |
| **Personnel** | Who writes the code vs. who runs the code. When the writer is not the operator, the writer does not feel the pager. | 12-factor |
| **Tooling** | Different OSes, runtimes, DB versions, or library versions between dev and prod. SQLite in dev, Postgres in prod is the classic. | 12-factor |
| **Fidelity** | How much the non-prod environment is pretending. Traffic shape, data volume, third-party endpoints, feature flag defaults, scale. This is deploy-ready's addition. | deploy-ready |

Twelve-factor's three gaps are mostly about process: shorten the time, erase the personnel split, match the tooling. Deploy-ready's fourth is about the environment's honesty: what is the environment deliberately lying about, and what is that lie costing you?

## What makes staging not prod

Staging can be a faithful reproduction of prod's code path and a wildly misleading reproduction of prod's failure surface. The fidelity gap lives in six specific places.

### Data volume

Prod has 50M rows; staging has 5,000. Every query that is fast in staging because the planner chose a hash join over 5,000 rows becomes a 40-second seq scan in prod with 50M. The query plan is not a property of the code; it is a property of the data volume against the code.

Good practice: seed staging at least at 1% of prod's row count per table, and pin the planner stats. Explicitly test the top 20 queries at prod-shaped cardinality.

Bad practice: "we have some sample data." The sample data shapes the planner; the planner shapes the outage.

### Traffic pattern

Prod gets 1,000 rps with a 2:1 read-to-write ratio. Staging gets an engineer clicking around at 0.1 rps. The concurrency primitives (connection pool saturation, lock contention, cache warmth, circuit-breaker behavior) only surface under real load. This is why a deploy can look fine in staging and immediately brown out in prod: the concurrency shapes are not present in staging.

Good practice: synthetic load that mirrors prod's request-mix against staging during the canary window. If you have traffic replay (shadow traffic, Diffy-style mirroring), use it.

Bad practice: "we smoke-tested." A smoke test is a request-level check; it says nothing about concurrency behavior.

### Concurrency and scale

Staging runs one instance; prod runs twelve behind a load balancer. The 12-instance shape has distributed-system behaviors (leader election if any, cache consistency, rolling-update half-states) that the 1-instance shape cannot reproduce.

Good practice: staging runs at least 2 instances, so that rolling-update behavior is testable and half-state code paths are exercised.

Bad practice: "staging is one box because it saves money." The deploy you're about to run is precisely the one that rolls new code across multiple boxes. If staging cannot reproduce that, staging cannot test the deploy.

### Third-party integrations

Staging points at Stripe test mode, SendGrid sandbox, Twilio test credentials, and a dev tier of your analytics vendor. Prod points at real money, real inboxes, real phones, and a paid analytics tier with different rate limits. The sandboxes behave differently from the real services in ways that are invisible from the code: different webhook delivery guarantees, different rate-limit headers, different idempotency handling.

Good practice: name every third-party integration per environment and what it points at. Document which behaviors are known to differ (rate limits, webhook signatures, latency). Run at least one end-to-end test per integration against a pre-prod-real tier, not only against the sandbox.

Bad practice: "we use test mode everywhere below prod." Test mode does not experience the rate limits of real mode.

### Feature flag defaults

Staging has every experimental flag turned on; prod has most turned off. The paths under test in staging are the optimistic paths, not the pessimistic paths. A regression in the flag-off path ships to prod because staging never exercised it.

Good practice: flag defaults match prod in the environment that precedes prod. Test both the on and off paths explicitly, in different environments or different runs, not by accident.

Bad practice: "staging runs with all flags on so we can test them." That is a separate environment purpose; it is not a pre-prod rehearsal.

### Secrets scope

Staging secrets are scoped to a non-prod vault; prod secrets are scoped to the prod vault. The code paths that read secrets are the same, but the secret values are different, and a misconfigured secret can fail-silent in staging and fail-loud in prod (or vice versa). An env var that resolves to a non-empty string in staging and to an empty string in prod is a bug that only shows up on ship day.

Good practice: treat secret-injection paths as part of parity. The injection mechanism must be identical; the values must be different.

Bad practice: "we read env vars; they're fine." Vercel and Netlify both document that env vars added after the deployment are `undefined` until redeploy ([Vercel environments docs](https://vercel.com/docs/deployments/environments); [Netlify build environment docs](https://docs.netlify.com/build/environment-variables/overview/)). That single gotcha is the leading cause of "it works in preview, 500s in prod."

## Per-rung parity table template

Every promotion ladder should be documented with a rung-by-rung parity table. The template below is the minimum schema. Add rows per rung your deployment has; add columns if the environment has specific dimensions (region, data-residency, contract with a customer on a specific tier).

| Rung | Traffic source | Data source | Scale | Feature-flag defaults | Observability reach |
|---|---|---|---|---|---|
| **dev** | Engineer only | Synthetic / seeded / branched | 1 instance | All experimental on | Local logs; no production telemetry |
| **preview (per-PR)** | Engineer + reviewer | Branched copy or synthetic | 1 instance | Match prod + opt-in experimental | Limited, preview-scoped telemetry |
| **staging** | Synthetic load + engineers | Sanitized prod subset or generated prod-shape | 2+ instances | Match prod | Full `observe-ready` telemetry, same pipeline as prod |
| **canary** | 1-10% of prod traffic, time-boxed | Real prod | Same shape as prod, scaled fraction | Match prod | Full; canary-specific metrics drive rollback trigger |
| **prod** | 100% real users | Real prod | Full scale | Authoritative | Full |

Fill this in for the specific project before Step 4. Any row that is blank is a gap that will ship as a surprise. Any column where staging differs from prod without being named is a deliberate lie that will become a real incident.

## Preview-environment anti-patterns

Preview environments on Vercel, Netlify, Cloudflare Pages, and Render are the most common source of first-deploy blindness. The pattern is always the same: the preview looks fine, a single knob is set differently than prod, and the knob only shows up at build time or at cold start.

### Env vars undefined until redeploy

An env var added in the dashboard after the deploy is built is `undefined` for that deploy. The platform will happily keep serving the old artifact with the old variable resolution. This is documented on both Vercel and Netlify. First-deploy blindness: the agent sets the env var in the dashboard, tests the URL, sees a 500, and chases the code for a bug that is not in the code.

Fix: redeploy after env var changes. Better: inject env vars as part of the deploy pipeline, so the artifact and the variable set are shipped together.

### `.env` not read at build time

Frameworks that read env vars at build time (Next.js `NEXT_PUBLIC_*`, Vite `VITE_*`, Gatsby `GATSBY_*`) bake the value into the bundle. A variable set for runtime is invisible to the bundle. The symptom: `process.env.NEXT_PUBLIC_API_URL` resolves to `undefined` in the browser even though the value is clearly set on the host.

Fix: treat build-time vs. runtime env vars as two different categories. Document which is which. Run the build with the correct variables injected; do not rely on runtime lookup for build-time values. See [Vercel discussion #5015](https://github.com/vercel/vercel/discussions/5015).

### Framework prefix requirements

Next.js ships only `NEXT_PUBLIC_`-prefixed variables to the browser; anything without that prefix is server-only. Vite uses `VITE_`; Create React App uses `REACT_APP_`; SvelteKit uses `PUBLIC_`. A variable named `API_URL` without the prefix is accessible on the server and absent in the browser. The AI-generated failure mode: "I set `API_URL` in the dashboard and the browser console still says `undefined`."

Fix: name every public-exposed env var with the framework prefix. Document the prefix in the deploy plan per environment.

### Build-time vs. runtime split

A single framework can have both. Next.js reads `NEXT_PUBLIC_*` at build time and baked them into the bundle; it reads other env vars at runtime on the server. The two paths have different reloading behavior: runtime vars are visible on the next request; build-time vars require a rebuild. A deploy that changes only a build-time var without rebuilding is a no-op.

Fix: name which vars are build-time and which are runtime. Any build-time var change triggers a rebuild; a runtime var change can reload. Write this into the pipeline.

### Per-PR env isolation

Preview deploys that share a single database between all PRs will see tests from PR A break PR B. Preview deploys that point at the shared staging database will see schema changes in one PR fail tests in another. The fix is per-PR ephemeral databases (Neon branching, PlanetScale branching, Supabase branching) but the AI-generated default is usually "point preview at staging DB" and hope.

Fix: per-PR branched database, or a documented reason why the PR's tests do not need database isolation.

## Parity drift audit

Every quarter, run the drift audit. Gaps widen silently; the audit makes them visible before an incident finds them.

Checklist:

- **Runtime versions.** Node, Python, Ruby, Go, JVM. Is the runtime in staging the same minor version as prod? Same patch? A minor-version bump in one environment that lags in another is a delayed regression.
- **DB engine versions.** Postgres 15.3 in staging, 15.6 in prod. The minor-version difference usually does not matter; the time when it matters is precisely when you have not audited it.
- **Library versions from the lockfile.** If the same-artifact invariant is holding, these match by construction. If they do not, something is rebuilding per environment.
- **OS / base image.** `node:20-bookworm-slim` in staging, `node:20-alpine` in prod. Different libc, different tz data, different curl flags; every one of these has been a midnight page for someone.
- **Region.** Staging in `us-east-1`, prod in `eu-west-1`. Latency, availability zones, regulatory regime all differ.
- **Replication topology.** Staging is single-node; prod is primary-replica. Read-after-write guarantees differ, replication lag is zero in staging and non-zero in prod.
- **Load balancer config.** Staging's LB has a 60-second idle timeout; prod's has 30. Long-running requests that succeed in staging time out in prod.
- **CDN config.** Cache-control headers, purge behavior, geographical pop distribution.
- **Feature flag defaults.** Already covered; re-verify.
- **Third-party integrations.** Still pointing at sandboxes? Any sandboxes that sunset since last audit?

Each row: green if it matches, yellow if it is a known difference, red if it is an unknown difference. Red rows are next-quarter's outages.

## Data-seed strategies

The non-prod data source is the single biggest fidelity decision. The three main options have sharply different risk profiles.

| Strategy | What it is | Use when | Avoid when |
|---|---|---|---|
| **Synthetic** | Generated data that resembles prod in shape but is not derived from prod | Pre-prod environments below canary; any regulated-data domain | You need query-plan realism; you need real corner cases |
| **Scrubbed prod copy** | Prod data with PII redacted or tokenized | Query-plan realism, concurrency testing, regression repro | Regulated domains where even scrubbed data is risky; always verify scrubbing is actually removing PII |
| **Shared prod** | Non-prod points at prod database directly | Almost never | Almost always. Any non-prod pointing at prod DB can corrupt prod via a migration, a destructive command, or a bug in the test harness. |

Shared prod for non-prod environments is almost always wrong. The Replit incident (AI agent destroying a prod database during a code freeze, see [Fortune](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/) and [The Register](https://www.theregister.com/2025/07/21/replit_saastr_vibe_coding_incident/)) illustrates the failure class: when dev credentials reach the prod database, the only barrier between a mistake and an outage is the agent's caution, which is not a barrier. Replit's explicit post-incident fix was to split dev and prod databases automatically.

The rule: if a non-prod environment can write to the prod database, that is a bug, not a convenience. Fix it before the next ship.

## The pre-prod parity gap, named

Deploy-ready surfaces the pre-prod parity gap as a named concept. The gap is the specific set of differences between the final pre-prod environment (usually staging) and prod, deliberately identified and quantified. It answers three questions:

1. What is different between staging and prod, by design?
2. What is the failure class each difference is blind to?
3. What compensating control catches that failure class before it reaches prod?

Example:

| Difference | Failure class it is blind to | Compensating control |
|---|---|---|
| Staging has 1% of prod's row count | Query plan regression on large tables | Canary with p99 latency threshold on the critical path |
| Staging has a single load-balanced instance | Rolling-update half-state bugs | Blue/green or canary at 10% for 15 minutes before full promote |
| Staging sends email to a catch-all inbox | Real email-template rendering on real clients | Pre-canary email sent to a test user on each mail client once per release |
| Staging uses Stripe test mode | Real webhook timing, real dispute flows | Canary window extended to 60 minutes for payment-code changes |

This table lives in `.deploy-ready/TOPOLOGY.md`. It is updated whenever the staging configuration changes. The agent references it in Step 3 and refuses to skip rows; silence on a row is a first-deploy-blindness risk.

## Feature-flag parity discipline

Feature flags are the one place where staging and prod are deliberately different, and the difference is load-bearing for testing. Discipline here has three rules.

1. **Name which flags diverge between staging and prod, and why.** Staging may have `enable_v2_checkout: true` while prod has `enable_v2_checkout: false` because staging is exercising v2 and prod has not yet shipped it. That divergence is intentional. A divergence like `enable_analytics_tracker: true` in staging and `false` in prod because "we forgot" is not intentional.

2. **Test both the on and off paths before shipping.** If prod will run with the flag off, a non-prod environment must also run with the flag off and the full test suite must pass. Do not ship a change that makes the flag-off path broken in favor of the flag-on path, then flip the flag and discover the flag-off rollback is broken.

3. **Flag lineage is part of the plan.** Reused flag names are the Knight Capital shape. If a flag was used before, the plan must explicitly check whether the old code gated by that flag has been deleted. See `rollback-playbook.md` for the flag-reuse check.

Document the flag divergence table in `.deploy-ready/TOPOLOGY.md` alongside the parity gap table. Any flag divergence without a reason is either a bug or a debt; neither is acceptable silence.

## Further reading

- 12-factor app, factor X: https://12factor.net/dev-prod-parity
- Vercel environments: https://vercel.com/docs/deployments/environments
- Netlify environment variables: https://docs.netlify.com/build/environment-variables/overview/
- Vercel env var build-vs-runtime discussion: https://github.com/vercel/vercel/discussions/5015
- Stripe, Online migrations at scale (data volume realism): https://stripe.com/blog/online-migrations
- `preflight-and-gating.md` for Step 1 and Step 9.
- `first-deploy-checklist.md` for Mode A cold-start gates on a new rung.
- `deployment-topologies.md` for per-topology parity considerations.
