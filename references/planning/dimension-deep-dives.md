# Dimension Deep Dives

Per-dimension analysis for close-call decisions. Loaded on demand in Step 5 when two candidates are within scoring range of each other and the user wants a deeper read.

**Scope owned by this file:** the tradeoffs inside each of the 12 dimensions: what separates the top candidates, the scoring axes that matter, the common misuses. Per-domain picks live in `domain-stacks.md`; scoring math lives in `scoring-framework.md`.

## 1. Framework

Fullstack meta-choice. Shapes everything below it.

### Top TypeScript candidates

- **Next.js 15.** App Router is now mature. Server Components + Server Actions collapse a large surface of API + client-state. Vercel is the default host. Ecosystem is the deepest. Score: 9 across most domains. Caveat: State of JS 2024 shows Next.js retention softening tied to App Router / RSC complexity; consider the "flip to Astro if content-heavy, flip to SvelteKit if team is reactivity-native" note.
- **React Router v7 (formerly Remix v2+).** Remix v2 merged into React Router v7 in November 2024; the canonical name is now RR v7. Nested routing, data loaders, strong web-platform alignment, excellent DX. Smaller ecosystem than Next.js. Score: 7-8 depending on domain.
- **Remix v3 (Preact-based).** Announced May 2025; drops React, forks Preact. Assess-ring only; treat as a separate product, not a Next.js alternative.
- **SvelteKit.** Smallest-bundle story, excellent DX, solid data loading. Moved to Adopt on ThoughtWorks Tech Radar Vol 31 (Oct 2024). Ecosystem is smaller for enterprise patterns (fewer packages for SAML, fewer Clerk-quality auth options). Score: 7-8 for teams that love Svelte; lower for teams that don't.
- **Nuxt.** Vue equivalent to Next.js. Strong in European markets. Score: 7-8.
- **Astro.** Content-first framework with partial hydration. Leads meta-framework satisfaction by ~39 points over Next.js in State of JS 2024. Acquired by Cloudflare (January 2026). Score: 9 for content-heavy (blogs, docs, marketing, CMS public surface), 6 for app-heavy (use Next.js instead).
- **TanStack Start.** On ThoughtWorks Trial ring (Vol 34). Score: 7 for TanStack-shop teams; not yet a Safe Default.

### Top non-TypeScript candidates

- **Rails 8 + Hotwire/Turbo.** Rails is back. Hotwire gives you SPA-like interactivity without a JS framework. DX is superb for CRUD-heavy work. Rails 8 ships Kamal 2 + Solid Queue / Solid Cache / Solid Cable as defaults. 37signals' cloud exit quantified at $10M+/5yr. Score: 9 in SaaS, Fintech, Education, CMS domains when the team has Ruby depth.
- **Django 6 + HTMX + Alpine.** Mature, batteries-included, excellent admin. HTMX adoption among Django devs grew from 5% to 24% (2021-2025); Alpine from 3% to 14%. Django 6.0 adds first-class template partials making the combination canonical. Score: 8-9 for Python teams.
- **Phoenix LiveView 1.1.** Real-time native. LiveView 1.0 shipped late 2024, 1.1 in 2025. Production case studies (Multiverse, Stord, Bleacher Report, Erlang Solutions). Elixir's concurrency is a match for helpdesk, presence, collaborative editing. Score: 9 in real-time domains when the team has Elixir depth.
- **Laravel 12 + Livewire or Inertia.** PHP's most polished stack. State of Laravel 2025: Livewire 62% / Inertia 48%. "TALL" (Tailwind + Alpine + Laravel + Livewire) is effectively "modern Laravel." Score: 8.
- **FastAPI.** Not fullstack; pair with a separate frontend. Adoption jumped from 29% to 38% YoY among Python devs (JetBrains PyCharm 2025). Top pick when the backend is Python and the frontend is decoupled. Score: 8-9 as API layer.

### Top TypeScript backend candidates (new in 1.1.0)

The Framework dimension above focuses on fullstack meta-frameworks. A parallel "TypeScript backend" lane matters for Cloudflare-Workers-first apps, API-only services, or TypeScript monorepos with a decoupled frontend.

- **Hono.** #2 backend in JS Rising Stars 2024 (+11.5k stars). Used internally by Cloudflare (D1, KV, Queues, Workers Logs). ~14 KB. Multi-runtime (Workers, Bun, Node, Deno, Lambda). Drizzle docs default for backend examples. Score: 9 for edge/Workers/multi-runtime; 8 general.
- **Fastify.** Node-native, 2-3x Express throughput for JSON APIs. Score: 8. The safe choice for Node-primary backends.
- **Elysia.** Bun-specific; performance advantage shrinks on Node. Score: 8 on Bun, 6 elsewhere.
- **NestJS.** Enterprise-TS, Angular-shaped. +6.8k stars in 2024. Score: 8 for teams already in the Nest pattern; 6 for greenfield.
- **Express.** Still #5 on Rising Stars backend. Declining vs Hono/Fastify/Elysia. Score: 6 for new projects (use Hono or Fastify); 8 for maintaining existing apps.
- **tRPC.** Not a backend framework; a typed RPC layer that plugs into Next.js, Hono, Fastify, Express, or a Nest controller. Score: 9 for TypeScript monorepos with internal-only APIs.

### Scoring axes

- **DX.** How pleasant is day-to-day development?
- **Data flow.** How clean is server-to-client data handling?
- **Auth integration.** How well do top auth providers integrate?
- **Ecosystem.** Packages, tutorials, Stack Overflow depth.
- **Deployment story.** How well does it fit target hosting?
- **Concurrency model.** Matters for real-time, streaming, WebSockets.

### Common misuses

- Picking **Next.js for a content-only blog**: Astro or even a static site generator is simpler.
- Picking **Remix when the team has zero Remix experience** and the reason is "we want to try something new": the ecosystem difference will cost months.
- Picking **a JS framework when the team is Python-only**: Django is almost always the better bet.
- Picking **SvelteKit when enterprise SAML is in the pipeline**: the auth ecosystem is thinner; pair with a provider that ships a SvelteKit SDK.

---

## 2. Language / runtime

The language ripples through every other choice.

### Top candidates

- **TypeScript.** Default for fullstack JS. Type safety, huge ecosystem, first-class support across all major BaaS. Score: 9 for general-purpose web work.
- **Ruby.** Rails is the killer app. Excellent for CRUD-heavy work. Score: 9 for Rails teams.
- **Python.** Django is mature; FastAPI is modern. Dominates data/ML adjacency. +7 percentage points YoY on Stack Overflow 2025, largest mover. Score: 8-9 depending on domain.
- **Elixir.** Concurrency is a superpower; Phoenix is polished. Third most-admired on Stack Overflow 2025 at 66%. Score: 9 in real-time, 7 elsewhere.
- **Go.** Go 1.22+ `net/http.ServeMux` supports method+path patterns; community advice has shifted to "start with stdlib, add Chi or httprouter only if needed." Excellent for services and CLIs; weak for frontend-heavy fullstack. Score: 8 for APIs, 5 for fullstack web.
- **Kotlin / Java (Spring Boot).** Enterprise-native, deep ecosystem. Score: 8 for enterprise, over-engineered for SMB.
- **Rust (Axum, Actix).** Superb performance, steep learning curve. Axum is now the default over Actix (Tokio team, DX edge). Most-admired language on Stack Overflow at 72% for 10 consecutive years. Score: 8 for infra/perf-critical, 5 for general web.
- **C# / .NET.** Underrated; excellent DX for Windows-adjacent orgs. Score: 8 in enterprise.

### JS runtime sub-axis (new in 1.1.0)

- **Node.js 24 LTS** (May 2025) is the default for new projects. **Node 22 LTS** (maintenance until April 2027) is the safe choice. npm v11 ~65% faster on large installs. Node 22+ ships native TypeScript support. Score: 9 for stability, 8 for cutting-edge.
- **Bun.** Anthropic acquired Bun (December 2025); Claude Code runs on it in production. Rising Stars 2025 #1 build tool (+10.8k). ~90% Node test-suite pass rate. Score: 8 for TS-native greenfield when team has staging-validation discipline; 6 for enterprise workloads where ecosystem edge cases bite.
- **Deno 2** (October 2024) added npm compatibility, package.json recognition, LTS channel from 2.1. Adoption still niche; most teams stay on Node for ecosystem inertia. Score: 8 for scripts/CLI and security-forward workloads; 6 for greenfield web apps where Node or Bun is more conventional.

### Scoring axes

- **Team fit.** Does the team already know it, or are you hiring?
- **Ecosystem.** How many libraries are current?
- **Hireability.** How easy to hire for this language in 12 months?
- **Performance ceiling.** Does the language limit vertical scale?
- **Deployment options.** How many mature hosts exist?

### Common misuses

- Picking **Rust for a CRUD app** because it's fast: the team's velocity drop usually outweighs the runtime speedup.
- Picking **Go for frontend-heavy apps**: Go's template system is crude vs. TypeScript/Svelte/React.
- Picking **Elixir because the team lead is excited**: if the rest of the team doesn't know it, you are betting the product on learning.
- Picking **Python for high-concurrency real-time**: the GIL matters; async Python is viable but fighting the ecosystem.

---

## 3. Database

The longest-lived decision.

### Top candidates

- **Postgres.** The universal default. Stack Overflow 2024: ~75% admiration, 47.1% desired, 49% adoption; DB-Engines top climber in 4 of 6 recent months. JSONB, full-text search, pgvector, PostGIS cover adjacent needs. Score: 10 in most domains.
- **Managed Postgres tier.** Four contenders with different branching strategies: **Neon** (acquired by Databricks ~$1B May 2025; storage pricing dropped ~80%), **Supabase** (Postgres-native BaaS), **PlanetScale Postgres on Neki** (Sept 2025; ended PlanetScale's MySQL-only era), **Xata** (open-source Postgres with CoW branching). All 8-9 depending on workload. AWS RDS / Aurora for enterprise compliance; Railway / Fly Postgres for app-co-located simplicity.
- **MySQL.** Legacy-only for most new projects. PlanetScale pivoted to Postgres. Score: 7 for existing MySQL shops; 5 for greenfield.
- **SQLite.** Viable for mostly-read production via **Turso** and **Cloudflare D1**. **LiteFS Cloud sunset October 2024**; Fly deprioritized LiteFS. Score: 7-8 for edge/read-heavy; 5 for high-concurrency writes.
- **Convex.** Managed, reactive, typed. Open-sourced under FSL Apache 2.0 (February 2025); self-hostable on Postgres/MySQL/SQLite. Reported HIPAA BAA on any plan as of 2025. Score: 9 for fast-to-ship SaaS; scale ceiling at cross-tenant SQL aggregations and multi-region requirements. Convex's own infra migrated from Aurora MySQL to PlanetScale Postgres in 2025, which is itself a "Postgres wins at scale" credibility signal.
- **MongoDB.** Flat-to-declining trend per DB-Engines. Score: 5-6 for transactional work; 7 for genuinely document-natural data (CMS, schemaless event streams).
- **DynamoDB.** AWS-native, hyperscale. Score: 7 for AWS-deep teams; 5 for others.
- **ClickHouse.** OLAP-specialist. Score: 10 for analytics dimensions.
- **DuckDB / MotherDuck.** Embedded / customer-facing analytics, now leading ClickBench on its own benchmark. MotherDuck's 1-second billing minimum vs Snowflake's 60-second is a cited cost-cliff fix. Score: 9 for embedded analytics and ad-hoc; not a ClickHouse replacement at high concurrency.
- **Firestore.** Firebase default; managed, real-time. Score: 7 for tiny apps, 5 for production scale (query limits, per-read pricing spikes). Firebase-to-Supabase migrations commonly cite 80% cost reductions.

### Scoring axes

- **Data model fit.** Relational, document, KV, graph?
- **Scale ceiling.** Where does it stop?
- **Ops burden.** Managed service tiers, self-host maturity.
- **Ecosystem.** ORMs, drivers, tooling.
- **Cost at scale.** Real cost at your 12-month projection.
- **Compliance.** BAAs, data residency, SOC 2.

### Common misuses

- Picking **MongoDB for relational data** because it "scales": joins are not actually a bottleneck at the scale most apps see.
- Picking **DynamoDB for a 3-person team** not on AWS: the ceremony is not worth it.
- Picking **Postgres but treating it like a NoSQL store** (no constraints, no foreign keys): you are paying Postgres costs for NoSQL benefits.
- Picking **SQLite for a 50-engineer team with heavy writes**: viable at smaller scale; fights at larger scale.

---

## 4. ORM / query layer

Team ergonomics and migration discipline.

### Top candidates

- **Drizzle.** TypeScript-first, SQL-transparent, type-safe, ~7 KB min+gzip. Overtook Prisma in weekly npm downloads in late 2025. Score: 8-9. Caveat: `drizzle-kit` migration tooling has documented production-safety gaps (generates destructive DDL without guards, non-commutative two-branch migrations); allocate review discipline for schema changes.
- **Prisma 7 (late 2025).** Removed the Rust query engine; now ~1.6 MB pure TS + WASM compiler (85-90% smaller). Claims 3-3.4x faster queries on large result sets, up to 9x faster serverless cold starts. Excellent DX, strong migration tooling (safer than Drizzle Migrate). Score: 8. Historical Prisma penalties for bundle size and edge-runtime are now stale.
- **Kysely.** Type-safe SQL query builder, minimal. Score: 7-8 for teams who want SQL-visible code without ORM semantics.
- **TanStack DB.** Reactive client-side layer; sits on top of Drizzle or Kysely. Not an ORM replacement; a new dimension. Score: 8 when reactive client state over Postgres is the job.
- **SQLAlchemy 2.x.** Python mature default; SQLModel (SQLAlchemy + Pydantic) for FastAPI. Score: 8-9 for Python teams.
- **ActiveRecord.** Rails-native, most complete ORM overall for mature teams. Score: 9 in Rails.
- **Ecto.** Elixir's ORM; excellent. Score: 9 in Phoenix.
- **sqlc / ent / GORM / Bun / sqlx** (Go). sqlc wins for type-safe raw SQL; ent for code-first relations; GORM for rapid CRUD; Bun middle-ground; sqlx minimalist.
- **SQLx / Diesel / SeaORM** (Rust). SQLx dominates; Diesel is compile-time-checked; SeaORM traditional.
- **Raw SQL with a thin wrapper.** Always viable. Score: 7-8 when SQL fluency is strong; lower when it isn't.

### Scoring axes

- **Type safety.** Compile-time error catching.
- **Migration story.** How clean is schema evolution?
- **Escape hatches.** Can you drop to raw SQL for performance?
- **Maturity.** How production-proven?
- **Ecosystem.** Plugins, tutorials, Stack Overflow.

### Common misuses

- Picking **Prisma then fighting it on complex queries**: if you know 20% of your queries will be complex, Drizzle's SQL-visible model fits better.
- Picking **Drizzle when the team lacks SQL fluency**: Prisma or Drizzle Query API hides complexity; raw-style Drizzle requires reading generated SQL.
- Using **an ORM without understanding transactions**: regardless of ORM, transaction boundaries are where bugs live.

---

## 5. Auth / identity

Often the most churn-prone dimension.

### Top candidates

- **Better Auth.** TypeScript-native, self-hostable, excellent DX. Absorbed Auth.js in September 2025; Auth.js maintainers now direct new projects here. Score: 9 for standard SaaS.
- **Clerk.** Best-in-class polished UI, Organizations, SAML on Business plan ($99/mo). Pricing cliff: free 50k MAU on Blaze tier, then ~$2k/mo at 100k MAU. Score: 8-9 depending on MAU posture. Strongest for B2C scale-ups that want polished auth in 1-3 days.
- **WorkOS (AuthKit).** Enterprise-first (SAML, SCIM, audit log export). Free up to 1M MAU, then $2,500/M. Score: 10 when enterprise is in scope. Crossed ~1k paying customers and ~$30M ARR by late 2025.
- **Auth.js (formerly NextAuth).** Long-standing TS auth, folded into Better Auth in September 2025, now in security-patch mode. Score: 5 for new projects (down from 7), 7 for maintaining existing apps. Do not start new projects on Auth.js.
- **Supabase Auth.** Paired with Supabase DB, it's cohesive; cheapest at scale past 100k MAU ($0.00325 per extra MAU). Score: 8 in Supabase bundles.
- **Firebase Auth.** Paired with Firebase, fine. Score: 7.
- **Keycloak.** Open-source, self-hosted enterprise auth. Score: 7; heavy but complete.
- **Scalekit.** Emerging WorkOS competitor for B2B AI/agent apps. Score: 8 for that segment; too new for the default SaaS rec.
- **Stytch, Kinde, SuperTokens, FusionAuth, Ory.** Each has a narrower niche; score 7-8 in their specific fit (Stytch for passwordless + M2M, FusionAuth for self-host OSS, Ory for Kratos-style enterprise identity).
- **Devise (Rails).** Mature, trusted. Score: 9 in Rails bundles.
- **django-allauth.** Same for Django. Score: 9.
- **Rolling your own.** Almost never the right call. Score: 3-5; the failure modes are well-documented.

### Scoring axes

- **Feature set.** Social login, MFA, passwordless, Organizations, SAML, SCIM.
- **Pricing at scale.** Per-MAU pricing cliffs.
- **Compliance.** BAAs, SOC 2, data residency.
- **UI polish.** How much do you want to build yourself?
- **Customization.** Can you theme, extend, override?
- **Exit story.** Can you export users if you switch?

### Common misuses

- Picking **Clerk for a 100k-MAU app** without pricing for the 100k-MAU tier: the bill lands in month 6.
- Picking **Auth.js in 2026** when Better Auth is the active project: you are choosing the less-maintained option.
- Picking **self-hosted Keycloak for a 3-person team**: ops burden exceeds the saving.
- Picking **WorkOS without enterprise prospects**: paying for SAML/SCIM you don't need.

---

## 6. UI library

Design velocity vs. design ownership.

### Top candidates

- **shadcn/ui + Radix primitives.** The modern TypeScript default. Copy-paste patterns; you own the code. Accessibility is built into Radix. Score: 9.
- **Radix alone (headless).** Maximum customization; slightly more boilerplate. Score: 8-9.
- **Mantine.** Batteries-included, excellent dashboard components. Score: 8.
- **Chakra UI.** Declining but mature. Score: 7.
- **MUI (Material-UI).** Enterprise-heavy, opinionated. Score: 7 for Google-style UIs, 5 when you want to brand.
- **Ant Design.** Similar to MUI but more common in enterprise APAC. Score: 7.
- **Tailwind UI.** Paid templates on top of Tailwind. Score: 7.
- **HeroUI (formerly NextUI).** Modern, well-designed. Score: 7-8.
- **Custom design system on Radix.** Enterprise default when brand matters. Score: 8; higher upfront cost.

### Scoring axes

- **Customization.** Can you make it look like your brand?
- **Accessibility.** WCAG AA out of the box?
- **Component completeness.** Does it have everything you need?
- **Theming.** CSS variables, design tokens, dark mode.
- **Ecosystem.** Tutorials, extensions, copycats.

### Common misuses

- Picking **shadcn/ui + MUI** in one app: they fight.
- Picking **Tailwind UI then customizing it to unrecognizability**: you've written a design system without the infrastructure.
- Picking **MUI then trying to make it look non-Material**: you will pay the "override" tax everywhere.
- Picking **a low-code UI kit for a product that needs brand differentiation**: every SaaS ends up looking the same.

---

## 7. Client state / data fetching

How the frontend talks to the backend.

### Top candidates

- **TanStack Query.** The mature default for client-side data fetching, caching, mutation. Score: 9.
- **SWR.** Vercel-authored, simpler than TanStack Query. Score: 7.
- **Server Components + Server Actions (Next.js 15+).** Reduces the need for client-side caches on many paths. Score: 9 when the app fits the pattern.
- **Convex hooks.** Reactive, tied to Convex. Score: 9 in Convex bundles.
- **Hotwire (Rails).** HTML-over-the-wire; replaces much of the client state layer. Score: 9 in Rails bundles.
- **HTMX (Django).** Similar. Score: 8-9 in Django bundles.
- **Phoenix LiveView.** Same idea, more sophisticated. Score: 9 in Phoenix bundles.
- **Apollo Client (GraphQL).** Score: 7. Use only if GraphQL is the API style.
- **RTK Query.** Score: 7. Use only with Redux Toolkit.
- **Raw `fetch` with useEffect.** Score: 4. You will rebuild TanStack Query badly.

### Scoring axes

- **Cache model.** Is invalidation explicit or automatic?
- **Optimistic updates.** Built-in or DIY?
- **DX.** How much boilerplate?
- **Integration.** With your framework's data flow?
- **Real-time support.** Subscriptions, websockets.

### Common misuses

- Using **useEffect + fetch for production data fetching**: you will rebuild caching, retry, deduplication badly.
- Pairing **TanStack Query with server-rendered data** without thinking about cache hydration: double-fetches or stale-until-revalidated visible to users.
- Using **Apollo Client when the backend isn't GraphQL**: overhead with no benefit.

---

## 8. Hosting / deploy

The hidden cost center.

### Top candidates

- **Vercel.** Next.js's home. Excellent DX. Fluid Compute + Active CPU pricing (April 2025) cut costs up to 90% for idle-heavy workloads (LLM, streaming). Egress, image optimization, and middleware invocations remain the bill-shock vectors. Score: 8 general, 9 for AI-agent apps, 7 for content-heavy or high-egress workloads.
- **Netlify.** Jamstack-first, solid DX. Score: 7.
- **Railway.** Simple, generous, pure usage-based pricing. Score: 8. Best for spiky workloads where fixed-tier pricing overpays.
- **Fly.io.** Persistent processes, WebSockets, geo-distribution. Cheapest at scale (~$200/mo for workloads equivalent to $500-$2000/mo on Vercel per independent benchmarks). Score: 8-9 for those workloads.
- **Render.** Heroku-like simplicity, flat pricing ($7 Starter / $25 Standard). Score: 7. Where teams graduate when they want predictable monthly budgets.
- **Cloudflare Workers / Pages.** Edge-first; D1, Queues, Hyperdrive GA (April 2024); Workflows GA (2025); Durable Objects with SQLite on free tier; Containers launched mid-2025. Score: 8-9 for edge-suitable workloads and AI-inference apps; 6 for heavy OLTP-shaped Postgres apps where D1's model mismatches.
- **AWS (ECS Fargate, EKS, App Runner).** Full control, high ops burden. Score: 8 for enterprise, 4 for solo.
- **GCP.** Similar. Score: 7.
- **Azure.** Enterprise in Microsoft shops. Score: 7.
- **Kamal 2 + Hetzner / bare VPS.** Ships with Rails 8 by default. 37signals' cloud exit quantified at $10M+/5yr savings ($3.2M to $1.3M/yr). Score: 8 for Rails shops with ops capability; 6 for TS shops still maturing on containers.
- **Self-hosted VPS with Dokku / Coolify / Dokploy / CapRover.** Score: 7 for cost-conscious teams with ops bandwidth. Dokploy (Docker-first) increasingly chosen over Coolify for production stability.

### Scoring axes

- **Ops burden.** How many hours per week?
- **Cost at 12-month scale.** Egress, seats, invocations.
- **Deploy ergonomics.** Push to deploy, preview environments.
- **Compliance.** BAA, SOC 2, data residency.
- **Workload fit.** Serverless vs. persistent, edge vs. region.

### Common misuses

- Picking **Vercel without pricing for egress and seats**: the bill is a surprise.
- Picking **AWS for a 3-person team**: ops cost dominates.
- Picking **Cloudflare Workers for a workload that needs long-lived connections**: the runtime model fights.
- Picking **self-hosted Kubernetes** as a cost play for a small team: the ops cost erases the savings.

---

## 9. Observability

What you see when something breaks.

### Top candidates

- **Sentry.** Error tracking + session replay + performance. Score: 9. Default at low end (Team plan $26/mo).
- **Datadog.** Enterprise observability; everything in one place; expensive. Score: 8-9 at enterprise. Bill-shock at ~$5k+/mo is documented; Grafana Cloud migrations report ~40% savings (50+ migrations per Grafana Labs).
- **New Relic.** Mature, less modern DX. Score: 7.
- **Honeycomb.** Best-in-class tracing, wide events, excellent debugging UX. Score: 9 for teams that invest in tracing.
- **Axiom.** Log-first observability at reasonable cost (95%+ log compression, no sampling, from $25/mo). Score: 8. First-class in the log-first tier.
- **BetterStack / Logtail.** Log-first, strong DX. Score: 8.
- **Grafana Cloud.** Open-source stack managed; primary migration target from Datadog. Score: 8 (up from 7 in 1.0.0).
- **Self-hosted Grafana + Prometheus + Loki + Tempo.** Score: 7 for ops-capable teams.
- **SigNoz.** Open-source, ClickHouse + OTel native. Score: 7 for self-host + OTel-native teams.
- **PostHog.** Bundles analytics + session replay + feature flags + experiments + error tracking + surveys + LLM analytics. $0 tier with 100k errors/mo. Score: 9 for early-stage startups replacing Sentry + Mixpanel + LaunchDarkly trio.
- **OpenTelemetry** (as a protocol choice): always yes for new projects; the destination still matters.

### LLM observability (new in 1.1.0)

- **Braintrust.** $80M Series B (a16z, Feb 2025). Customers: Notion, Replit, Cloudflare, Vercel, Ramp, Dropbox, Airtable. Eval-in-CI focus. Score: 9 for enterprise + evals discipline.
- **Langfuse.** Open-source, self-hostable. Pro from $59/mo; self-host free. Score: 9 for data-control teams.
- **Helicone.** Gateway-first (routing/failover/caching across 100+ models). Score: 8.
- **LangSmith.** LangChain-native. Score: 8 for LangChain shops.
- **Phoenix (Arize).** OpenTelemetry-native, academic lean. Score: 7 for teams invested in OTel across everything.

### Session replay (separately)

- **Sentry Replay.** Bundled default. Score: 9.
- **Highlight.io.** Acquired by LaunchDarkly (April 2025); shuts down Feb 28, 2026. Score: 0 for new projects; migration required for existing users.
- **OpenReplay.** Leading OSS session replay. Score: 8.
- **LogRocket, FullStory.** Mature, paid. Score: 7-8.

### Scoring axes

- **Error detection quality.** Grouping, context, release tracking.
- **Tracing depth.** Are you going to adopt traces, or just logs?
- **Cost at volume.** Per-host, per-GB, per-event pricing curves.
- **DX.** Ease of integration, dashboard UX.
- **Compliance.** BAA, data residency.

### Common misuses

- Shipping with **console.log as "observability"**: you will find out about a production bug from a customer.
- Paying for **Datadog on a 3-person team**: $10k/year could fund a better stack choice elsewhere.
- Using **three tools with overlapping scope**: Sentry + Rollbar + Datadog + New Relic is a procurement mistake.

---

## 10. Payments

Stripe-or-else.

### Top candidates

- **Stripe.** Universal default. Score: 10 for most use cases.
- **Stripe Connect.** Marketplace payments. Score: 10.
- **Stripe Tax.** Automated tax. Score: 9.
- **Stripe Managed Payments (SMP).** First-party MoR, launched private beta April 2025. Covers VAT in 100+ countries. Does not yet cover South Korea, China, India, Turkey, Brazil. Score: 7 today (private beta, limited geo). When GA lands in your region, Paddle drops from 8 to 6-7 for NA/EU-only businesses.
- **Adyen.** Enterprise-scale, global. Score: 8-9 at enterprise.
- **Braintree (PayPal).** Viable, narrower. Score: 7.
- **Paddle.** Merchant of Record; handles VAT for digital goods. Score: 8 for digital SaaS needing MoR *and* for India/Brazil/Korea/Turkey/China (geos SMP doesn't cover). Moat is shrinking in NA/EU as SMP rolls out.
- **Polar.** Indie-favored low-fee MoR (4% + $0.40). Score: 8 for indie/creator MoR; cheaper than Paddle and Lemon Squeezy.
- **Lemon Squeezy.** Acquired by Stripe (July 2024); roadmap absorbing into Stripe Managed Payments. Score: 5-6 for new adoption; prefer SMP once GA in your geo.
- **DodoPayments.** Lower-fee Gumroad alternative for creator/indie. Score: 7.
- **Gumroad.** Full MoR as of January 2025; 10% + $0.50 fee. Score: 6 for very-small-scale creators; higher fees than Polar/Dodo.
- **Mollie.** EU-specific payment methods, local-feeling checkout. Score: 8 when customer base is EU-heavy.
- **Authorize.Net.** Legacy. Score: 5.
- **Rolling your own payment processing.** Score: 1. Do not.

### Scoring axes

- **Geographic coverage.** Where do your customers pay from?
- **Product model fit.** Subscription, one-time, usage-based, marketplace.
- **Merchant of Record.** Does the processor handle VAT/tax globally?
- **Fees.** Interchange, platform fees, connected accounts.
- **Integration depth.** SDK, webhook maturity.

### Common misuses

- Picking **Stripe with no webhook retry plan**: subscription state will diverge from reality.
- Picking **a non-MoR processor** while selling to EU B2C: you become the tax authority's problem.
- Building **custom subscription logic** on top of Stripe: Stripe Billing's primitives are more complete than people think.

---

## 11. Email / notifications

Deliverability is the hidden dimension.

### Top candidates

- **Postmark.** Transactional-only infrastructure (refuses marketing email); keeps IP reputation pristine. 98.5% inbox placement documented (95.3% -> 98.5% post-migration from SendGrid). No dedicated-IP upcharge. Score: 9.
- **Resend.** Developer-first, React Email integration, 3,000/mo free tier, captured TypeScript-first mindshare. Score: 9. Weak spot: limited multi-tenant story; not publicly benchmarked at Postmark's deliverability level.
- **SendGrid.** Free tier removed; new accounts get 60-day trial (100/day) then $19.95/mo minimum. Shared IPs = variable deliverability. Score: 6 (down from 7 in 1.0.0).
- **AWS SES.** Cheapest per send; requires careful DKIM/SPF/DMARC setup, reputation risk tail. False economy under 1M/month without deliverability discipline. Score: 7 for teams with deliverability expertise.
- **Loops.** Transactional and lifecycle. Score: 8.
- **Customer.io.** Lifecycle / marketing. Score: 9 for that job.
- **Paubox.** HIPAA-specialized. Score: 9 for healthcare.
- **Knock.** In-app + multi-channel notifications. Score: 9 for apps with complex notification preferences.
- **Novu.** Open-source Knock equivalent. Score: 8.

### Scoring axes

- **Deliverability.** Inbox rate; reputation management.
- **DX.** SDK, templates, API.
- **Cost at volume.** Per-email and per-seat pricing.
- **Compliance.** BAA, SOC 2.
- **Multi-channel.** Email + SMS + push + in-app.

### Common misuses

- Using **one provider for transactional and marketing**: marketing volume damages transactional deliverability.
- Picking **AWS SES without a deliverability plan**: bounces compound; you end up on blocklists.
- Using **Resend for healthcare** without checking BAA: may not be compliant.

---

## 12. Background jobs / queues

Where durability lives.

### Top candidates

- **Inngest.** Developer-first durable workflows; event-driven; zero-config Vercel integration. Score: 9.
- **Trigger.dev v3.** Open-source + self-host, TypeScript-native, retries and observability baked in. Score: 8-9. Co-equal with Inngest; pick on DX preference and self-host need.
- **Temporal.** Enterprise-grade workflow engine; multi-day sagas, human-in-the-loop, strict determinism. Steep learning curve; complexity tax real but pays off when failure is unacceptable. Netflix, Snap, Stripe. Score: 9 for complex workflows; 6 for simple async.
- **Hatchet / Restate / DBOS.** New "Postgres-backed / library-first" durable execution alternatives. "Your DB is your workflow store" vs Temporal's dedicated orchestrator. Score: 8 for small teams on Postgres that want durability without a separate service.
- **Solid Queue (Rails 8 default).** Postgres/SQLite-backed, ships with Rails 8. Replaces Sidekiq for teams that want to stay Rails-native without Redis. Score: 9 in Rails 8 bundles.
- **BullMQ.** Redis-based, TypeScript-native queue. Score: 7.
- **SQS.** AWS-native. Score: 7; 8 in AWS-deep teams.
- **Sidekiq.** Rails default for teams on Redis. Pro $179/mo (Batches, unique jobs), Enterprise $749/mo+ (rate limiting, encryption, periodic jobs at scale), unlimited license $79,500/yr. Score: 9 for Rails shops with Redis in stack; consider Solid Queue for new Rails 8 projects.
- **Celery.** Python default. Score: 8. Dramatiq, RQ, ARQ are simpler async-friendly alternatives.
- **Oban.** Elixir-native, Postgres-backed. Score: 9 for Phoenix. Increasingly cited as "Sidekiq without Redis" inspiration for cross-ecosystem patterns.
- **RabbitMQ.** Message broker, venerable. Score: 7.
- **Kafka / Redpanda.** Event streaming, different shape. Redpanda is the drop-in Kafka replacement (single binary, no JVM, no ZooKeeper) for ops-averse teams. Most small teams do not need Kafka; NATS, Pub/Sub, SQS, or Redis Streams are usually the right answer. Score: 7 for event-sourcing-native teams.

### Scoring axes

- **Durability.** Retries, dead-letter, idempotency.
- **Visibility.** Dashboard, tracing, alerts.
- **DX.** How easy to define a job?
- **Ops burden.** Hosted vs. self-host?
- **Fit to workload.** Short async vs. long-running vs. fan-out.

### Common misuses

- Running **jobs in the web process**: one slow job blocks web requests.
- Using **cron for everything**: no retry, no dashboard, silent failures.
- Picking **Temporal for simple async tasks**: ceremony dominates the benefit.
- Picking **BullMQ without Redis persistence**: jobs lost on restart.

## Cross-cutting dimensions

These dimensions interact heavily; keep an eye on interaction effects.

- **Auth + UI library**: Clerk provides complete UI; Better Auth needs you to build or use their headless.
- **Database + ORM**: Postgres + Drizzle is tight; MySQL + Drizzle works but has fewer patterns.
- **Hosting + framework**: Vercel + Next.js is near-symbiotic; Next.js on Render works but misses some DX.
- **Payments + domain**: Stripe Connect for marketplaces; Paddle for digital global SaaS; Adyen for enterprise.
- **Email + background jobs**: sending email reliably requires a retry-capable job system behind it.
- **Observability + scale**: error tracking (Sentry) fits all scales; tracing (Honeycomb) pays off at team scale and above.
