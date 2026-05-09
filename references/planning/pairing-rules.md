# Pairing Rules

The Step 4 gate. Some combinations do not work together; this file catalogs them and why.

**Scope owned by this file:** hard anti-pairings, soft anti-pairings, and legitimate-exception cases. Per-domain picks live in `domain-stacks.md`; bundle-level coherence lives in `stack-bundles.md`.

## Rule types

- **Hard anti-pairing**: reject the bundle. No legitimate case for this combination at Tier 1-3 scale.
- **Soft anti-pairing**: strongly flag, allow only with explicit rationale. There are rare legitimate cases.
- **Overlap**: two tools doing the same job; pick one, not both.
- **Substitution chain**: one tool meaningfully replaces another, so keeping both is wasteful.

## Hard anti-pairings

Reject these outright in Step 4. Do not score bundles that contain them.

### Data layer conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **Convex + Prisma** | Convex is a full data layer (schema, queries, mutations, reactivity, auth). Adding Prisma means running two ORMs with no shared schema, no shared migrations, and no shared reactivity. You are paying for two data layers and getting neither's benefits. |
| **Convex + Drizzle** | Same reason as above. |
| **Supabase + Firebase** | Two BaaS for the same scope. If you think you need both, you are either mid-migration (not a bundle) or confused about what each does. |
| **Two ORMs in the same service** (Prisma + Drizzle, Prisma + Kysely, Drizzle + TypeORM) | One source of schema truth per service. Mixing creates parallel migration tracks and divergent types. |
| **Two databases for the same entity** (Postgres and MongoDB both storing users) | Dual-write with no source-of-truth plan. This is a compounding data-integrity bug, not an architecture. |

### Identity conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **Clerk + Better Auth** | Two user stores. Impossible to keep in sync. RBAC becomes incoherent. |
| **Clerk + WorkOS** | Two user stores. |
| **Better Auth + WorkOS** | Same. Pick WorkOS if enterprise SSO is required; pick Better Auth if it isn't. |
| **Auth.js + Better Auth (new project)** | Auth.js folded into Better Auth in September 2025; Auth.js is now in security-patch mode and maintainers direct new projects to Better Auth. Running both in parallel in a new project is a temporary migration state, not an architecture. |
| **Auth.js + Clerk** | Same. |
| **Supabase Auth + Clerk** | Same. |
| **Firebase Auth + Supabase Auth** | Same. |
| **Any auth provider + rolled-your-own auth** | If you rolled your own, you don't need the provider. If you use the provider, don't roll your own. Mixing is how password resets route to the wrong user. |

### UI layer conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **shadcn/ui + MUI in the same app** | Two design systems. One will bleed into the other. One will eventually win and the migration is painful. |
| **shadcn/ui + Mantine** | Same. |
| **shadcn/ui + Chakra UI** | Same. |
| **MUI + Ant Design** | Same. |
| **Tailwind CSS + MUI's styled system in the same component tree** | Fighting tooling. You will double-ship CSS. |

### Client state conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **TanStack Query + SWR in the same app** | Two cache layers, double-fetching, invalidation incoherence. |
| **TanStack Query + Apollo Client in the same app** | Same. |
| **RTK Query + TanStack Query** | Same. |
| **Convex hooks + TanStack Query over the same Convex data** | Redundant; Convex hooks are the right layer for Convex data. |

### Background job conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **Sidekiq + BullMQ** (same service) | Two job queues, two retry stories, two dashboards, two failure modes. Pick one. |
| **Inngest + Trigger.dev** | Both are durable workflow platforms. Either solves the problem; both together doubles the ops surface. |
| **Celery + RQ + SQS** (multiple queues in one Python service) | One queue per service unless you have a specific reason (and the reason usually isn't good enough). |

### Hosting conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **Vercel + AWS Lambda (same app request path)** | Vercel already runs on AWS Lambda. Stacking your own Lambdas behind Vercel adds a hop for no benefit. |
| **Netlify + Vercel (same app)** | Two deploy platforms for the same app. Unambiguous confusion. |
| **Cloudflare Workers + Vercel Edge Functions** (same app, same scope) | Two edge runtimes. Pick one. |

### Framework conflicts

| Anti-pairing | Why it breaks |
|---|---|
| **Next.js + Remix / React Router v7 in the same monorepo sharing routes** | Not a monorepo pattern, an in-progress migration. (Note: Remix v2 merged into React Router v7 in November 2024; if an older bundle references "Remix v2+", the current name is React Router v7. Remix v3 forks Preact and drops React; treat it as a separate product.) |
| **Rails + Phoenix for the same app domain** | Language barrier at the framework level. If you have both, something is migrating. |
| **Django + FastAPI for the same app** | Same. |

### Sync engine conflicts (new)

| Anti-pairing | Why it breaks |
|---|---|
| **Two sync engines on the same shared state** (Convex + Liveblocks for a single collaborative doc, Convex + Replicache over the same entity, Supabase Realtime + Convex) | Each sync engine is a source of truth for reactivity; overlapping them on the same data creates ordering ambiguity. One can sit below the other (e.g., Liveblocks for cursor presence on top of a Convex-stored document) but only when the scopes are clearly disjoint. |
| **"Backend-in-a-box" doubles** (Supabase + Convex, PocketBase + Supabase) | Each replaces DB + auth + storage + realtime. Running two is usually mid-migration or an unresolved platform choice. |

## Soft anti-pairings

Flag these. Allow only with explicit rationale. There are rare legitimate cases.

### Observability overlap

| Soft anti-pairing | When it's legitimate |
|---|---|
| **Sentry + Datadog + Honeycomb** all at once | Rare; usually means "errors to Sentry, metrics to Datadog, traces to Honeycomb." If you can't explain the split in one sentence, the three-tool setup is overkill. |
| **Sentry + New Relic + Datadog** | Almost never legitimate; these overlap heavily. |

### Email overlap

| Soft anti-pairing | When it's legitimate |
|---|---|
| **Resend + Postmark + SendGrid** | Never legitimate simultaneously. |
| **Postmark (transactional) + Customer.io (marketing)** | Legitimate and common; different pipelines. |
| **Resend + Loops** | Both are transactional-ish; pick one unless one is doing marketing automation. |

### Payments overlap

| Soft anti-pairing | When it's legitimate |
|---|---|
| **Stripe + Paddle + Lemon Squeezy** | Never all three. |
| **Stripe + Paddle** | Legitimate if you use Stripe for self-serve and Paddle as Merchant of Record for certain jurisdictions; state the reason. |
| **Stripe + Adyen** | Legitimate for global enterprise with payment redundancy; otherwise overkill. |

### Analytics / telemetry overlap

| Soft anti-pairing | When it's legitimate |
|---|---|
| **PostHog + Mixpanel + Amplitude** | Never all three. |
| **PostHog + Segment** | Legitimate if Segment is the fan-out hub and PostHog is one destination; otherwise redundant. |
| **Google Analytics + PostHog** | Legitimate; GA for SEO/marketing reporting, PostHog for product analytics. State the split. |

## Overlap detection

These overlap less as anti-pairings and more as "you almost certainly didn't mean both." Audit for them.

| Overlap | What's happening |
|---|---|
| **Prisma + Supabase client** | Supabase's auto-generated REST and RLS overlap Prisma's type generation. Pick one. |
| **tRPC + GraphQL** (same service) | Two RPC styles. Pick the one that fits the team. |
| **REST + GraphQL + tRPC** (same service) | Three transports. Unless there's a public API reason, this is over-engineered. |
| **Multiple CSS frameworks** (Tailwind + Bootstrap + styled-components) | Pick one. |
| **Multiple testing libraries** (Vitest + Jest in the same package) | Pick one. |
| **Multiple bundlers** (webpack + Vite in the same app) | Mid-migration, not architecture. |

## Substitution chains

Where one tool replaces another such that keeping both is wasteful.

### Convex replaces

- Postgres (as the primary data store, at Convex's scale)
- An ORM (Prisma, Drizzle, etc.)
- A job queue, for short-lived tasks (Convex scheduled functions)
- Often a WebSocket / real-time sync layer (Convex has reactivity built in)

If you're using Convex, you don't also need these unless you're migrating.

### Supabase replaces (partially)

- Postgres hosting (Supabase is Postgres)
- An auth provider, with Supabase Auth (though you can swap it)
- File storage, with Supabase Storage
- Real-time updates, with Supabase Realtime

If you're using Supabase, audit whether additional tools (another Postgres host, another auth provider, another realtime SDK) are actually needed.

### Firebase replaces (partially)

- A database (Firestore)
- Auth (Firebase Auth)
- File storage (Firebase Storage)
- Hosting (Firebase Hosting)
- Background jobs (Cloud Functions)

Same audit pattern as Supabase.

### Phoenix LiveView replaces

- A separate client-side framework (React, Vue, Svelte)
- A separate WebSocket layer
- Often a separate client state manager

If you pick LiveView, stacking a client-side framework on top fights the platform.

### Server Components + Server Actions (Next.js 15+)

- Reduce the need for a separate API layer and client-side cache manager for many CRUD patterns
- Do not fully replace TanStack Query if you have heavy client-side interactivity
- Partially replace tRPC for simple CRUD paths

## Cross-layer overlaps to check

Some dimensions bleed into each other. Verify the bundle has one answer per job.

| Job | Which dimensions own it | Common mistake |
|---|---|---|
| User identity | Auth | Implementing it also in the DB layer without a clear owner |
| Permissions (RBAC) | Auth + API + DB (row-level) | Having only client-side checks |
| Real-time updates | Client state + framework + DB (if Convex/Supabase) | Three different realtime subsystems |
| File uploads | Storage provider + auth + background jobs | Processing uploads in-request without a background pipeline |
| Email sending | Email provider + background jobs (for retries) | Sending in the request path with no retry |
| Error reporting | Observability (Sentry-like) | Duplicating error capture in custom code |
| Structured logs | Observability (Axiom, Datadog, etc.) | Having two logging destinations with divergent format |

## Legitimate exception cases

When the anti-pairing rules bend. Note these explicitly when they apply.

### Migration in progress

A codebase mid-migration legitimately has both (old + new) tools. This is not an architecture; it is a temporary state. The `DECISION.md` must declare the cutover plan and date.

### Specialist secondary tool

Example: Postgres as the primary DB, with ClickHouse for OLAP aggregations. Two DBs, different jobs, legitimate split. Rule of thumb: if you can't explain why each tool is uniquely required in one sentence, it's not a legitimate split.

### Polyglot service architecture

If the team has genuinely independent services (one in Python, one in Elixir, one in Node), each service may have its own stack. Anti-pairings apply within a service, not across independent services. But a 3-person team with 3 different services in 3 different languages is usually the wrong architecture.

### Regulatory or procurement requirements

"We must use vendor X because enterprise customer contract requires it." State the requirement; if it forces an otherwise-anti-pairing combination, document the reason and the cost.

## How to resolve a flagged pairing

When the pairing check fires:

1. **Identify the conflicting pair.** Name both tools and the job they overlap on.
2. **Determine which tool wins.** Usually the more specialized or more entrenched one.
3. **Drop the other from the bundle.** The scoring pass re-runs without it.
4. **If the user insists on both**, capture the rationale in the output. If no rationale survives scrutiny, reject the bundle and state why.

## Pairings that are legitimate but commonly flagged wrong

These look like anti-pairings at a glance but are fine.

- **Postgres + pgvector** is Postgres with an extension. Not two databases.
- **Postgres + Redis for caching** is one database with a cache layer. Legitimate.
- **Stripe + Stripe Tax + Stripe Identity** are one vendor's different products. Not an anti-pairing.
- **Sentry (errors) + PostHog (product analytics)** are different jobs, not overlap.
- **shadcn/ui is not a component library**; it's a copy-and-paste pattern on top of Radix. shadcn/ui + Radix are already paired; the former sits on the latter.
- **TanStack Query + TanStack Table** are different tools with overlapping branding. Not an anti-pairing.

## Staleness in this file

Pairing rules change when platforms evolve. Examples of shifts in the last 24 months:

- **Supabase gained a strong Auth story**, making Supabase Auth + Supabase DB a coherent single-vendor bundle.
- **Convex expanded its query model**, raising its ceiling for moderate-complexity SaaS. **Convex open-sourced under FSL Apache 2.0 (Feb 2025)** and is now self-hostable on Postgres/MySQL/SQLite; lock-in concerns have softened.
- **WorkOS added AuthKit**, becoming the procurement-friendly choice for enterprise-first apps (1M MAU free tier).
- **Clerk introduced Organizations**, reducing the need for custom multi-tenant code.
- **Astro gained server-side capability** and **was acquired by Cloudflare (January 2026)**, making Astro + Workers a natural pairing.
- **Auth.js folded into Better Auth (September 2025).** Auth.js is in security-patch mode; Better Auth is the TypeScript-native default for self-hosted identity.
- **Remix v2 merged into React Router v7 (November 2024).** Remix v3 (announced May 2025) forks Preact and drops React; any reference to "Remix v2+" is stale.
- **Stripe acquired Lemon Squeezy (July 2024)** and launched Stripe Managed Payments (private beta April 2025). Lemon Squeezy is being absorbed; Polar (4% + $0.40) is the new indie-favored MoR.
- **Prisma 7 (late 2025) removed the Rust query engine.** Prisma's historical bundle-size and cold-start disadvantages vs Drizzle have narrowed materially; don't penalize Prisma for those anymore.
- **Neon acquired by Databricks (~$1B, May 2025)**; storage pricing dropped ~80%. PlanetScale launched Postgres on Neki (September 2025), ending the "MySQL-only" PlanetScale.
- **Redis license pivoted to SSPL/AGPL (2024).** Valkey (Linux Foundation) captured the "default cache" narrative; DragonflyDB and Upstash complete the fork landscape. "Redis" now means "Redis-compatible protocol," not the product.
- **Highlight.io acquired by LaunchDarkly and shuts down Feb 28, 2026.** Any bundle that references Highlight must migrate (LaunchDarkly Observability or Sentry Replay / OpenReplay).
- **Anthropic acquired Bun (December 2025).** Bun production viability materially improved; still requires staging validation for npm edge cases.
- **Vercel shipped Fluid Compute + Active CPU pricing (April 2025).** Up to 90% cost cut for idle-heavy workloads (LLM, streaming). Bill-shock still exists at egress and image optimization.
- **Cloudflare Developer Platform matured:** D1, Queues, Hyperdrive GA (April 2024); Workflows GA (2025); Durable Objects with SQLite on free tier; Cloudflare Containers launched mid-2025.

Re-read this file every 3-6 months or when a major vendor shift is announced. See `RESEARCH-2026-04.md` for the evidence base behind these shifts.
