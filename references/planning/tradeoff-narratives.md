# Tradeoff Narratives

The Step 6 rubric. Every shortlisted bundle ships with three narrative items: the flip point, the scale ceiling, and the switching cost. This file is the library of flip-point patterns and switching-cost estimates.

**Scope owned by this file:** the "what flips this," "where is the ceiling," "what does exit cost" narratives per common candidate. Per-domain context lives in `domain-stacks.md`; pairing constraints live in `pairing-rules.md`.

## Why this discipline matters

A recommendation without a flip point is a horoscope. It sounds authoritative and can't be checked. In month three, when the team hits the failure mode that was predictable from day one, nobody can tell whether the recommendation was wrong or whether circumstances changed. This file makes the reasoning checkable.

## Reading a tradeoff narrative

For every bundle, write three paragraphs (each 1-3 sentences). Example:

**Bundle: SaaS Safe Default (Next.js + Postgres + Drizzle + Better Auth + shadcn + Vercel + Sentry + Stripe + Resend + Inngest)**

- **What flips this:** if the customer pipeline includes 5+ companies who will ask for SAML/SCIM in year one, Better Auth moves from 9 to 6 and WorkOS becomes the correct auth anchor. The rest of the bundle stays; only auth shifts.
- **Scale ceiling:** Postgres + Drizzle + Vercel comfortably handles a B2B SaaS up to ~50k DAU and ~500GB data under standard workloads. Past that, the bottleneck is usually query patterns (add read replica, introduce caching) or Vercel's pricing model (egress, middleware invocations).
- **Switching cost:** exiting Better Auth to WorkOS is a 1-2 week migration if done early, 4-8 weeks after significant user growth. Exiting Vercel to AWS is 2-4 weeks. Nothing in this bundle is trap-shaped.

## Flip-point library

Canonical flip points per candidate. Use as building blocks; adjust to the user's specific situation.

### Framework flip points

| Candidate | What flips it |
|---|---|
| **Next.js** | Long-running request patterns (WebSockets, SSE streaming beyond 30s, heavy file uploads) push you to Fly.io or Railway. Hard edge-runtime limits push you to a persistent-process host. |
| **Remix** | Ecosystem gaps (fewer mature SAML SDKs, fewer Clerk-equivalent auth providers with Remix-first support) push enterprise work back to Next.js. |
| **SvelteKit** | Any ecosystem blocker (mature payment SDK, specific enterprise integration) pushes to Next.js, where the ecosystem is deeper. |
| **Rails + Hotwire** | If the product requires deep client-side interactivity (real-time collaborative editing, rich canvas tools), Hotwire starts fighting you; add a JS framework or accept the friction. |
| **Phoenix LiveView** | If the team loses its Elixir depth (key engineer leaves, hiring pipeline thins), the ecosystem is too small to recover easily. |
| **Astro** | When the content site grows authenticated, transactional surfaces beyond a few features, a general-purpose framework fits better. |

### Database flip points

| Candidate | What flips it |
|---|---|
| **Postgres** | Rarely flipped; Postgres is the stable default. Sustained >10k writes/s needs sharding or a specialist DB. |
| **Convex** | Cross-tenant aggregations, complex reporting, SQL-style ad-hoc queries; Convex's query model hits a ceiling here. Postgres wins. |
| **Supabase** | Compliance constraints (check current BAA/SOC 2 posture), or scale where Supabase's hosted tier becomes expensive; move to self-hosted Postgres. |
| **Firebase Firestore** | Relational query needs, cost at scale; Firestore's model assumes document-shaped data. |
| **MongoDB** | When transactional integrity becomes central; MongoDB's eventual-consistency story is weaker than Postgres. |
| **ClickHouse** | For OLTP workloads; ClickHouse is OLAP-first. |
| **SQLite** | Write-heavy multi-node workloads; SQLite's single-writer model starts to pinch. |

### ORM flip points

| Candidate | What flips it |
|---|---|
| **Drizzle** | Team lacks SQL fluency; Prisma's higher-level API reduces ceremony. |
| **Prisma** | Heavy SQL optimization needs; Prisma obscures the generated query. Drizzle or Kysely fit better. |
| **Kysely** | If you want type safety AND a rich query API; Drizzle covers more ground. |
| **SQLAlchemy** | Rarely flipped; Python default. |
| **ActiveRecord** | Outgrowing Rails; ActiveRecord binds to Rails. |
| **Raw SQL** | When the team grows past ~3 engineers; type safety becomes valuable. |

### Auth flip points

| Candidate | What flips it |
|---|---|
| **Better Auth** | Enterprise SAML / SCIM / audit log export required; WorkOS is the move. |
| **Clerk** | MAU pricing cliff hit (varies by current pricing; often around 10k-50k MAU); move to Better Auth or WorkOS. |
| **WorkOS** | Pricing concerns pre-enterprise; Better Auth until enterprise customers arrive. |
| **Auth.js** | Better Auth has shipped a feature you need and Auth.js is behind; routine migration. |
| **Supabase Auth** | Moving off Supabase for any reason; Supabase Auth is tied to the platform. |
| **Firebase Auth** | Same; tied to Firebase. |
| **Rolling your own** | Anytime; the flip always favors a provider. |

### UI library flip points

| Candidate | What flips it |
|---|---|
| **shadcn/ui** | Brand demands deep visual differentiation; build on Radix directly for more control. |
| **Mantine** | Brand flex conflicts with Mantine's style; more work to override than to build custom on Radix. |
| **MUI** | Escaping Material Design aesthetic; the override cost is high. |
| **Radix (headless)** | Team bandwidth can't build UI from scratch; add shadcn/ui or Mantine. |
| **Custom design system** | Early stage without design ownership; adopt shadcn/ui and iterate. |

### Client state flip points

| Candidate | What flips it |
|---|---|
| **TanStack Query** | If Server Components cover your needs, the client-side cache is dead weight. |
| **Server Components + Actions** | Heavy client interactivity, optimistic updates, real-time; add TanStack Query. |
| **Convex hooks** | Move off Convex. |
| **SWR** | Feature gap vs. TanStack Query; migrate. |
| **Apollo** | Moving off GraphQL; Apollo becomes dead weight. |

### Hosting flip points

| Candidate | What flips it |
|---|---|
| **Vercel** | Bill shock at scale (egress, middleware invocations); move to self-managed or Railway. Persistent connection workloads (WebSockets); move to Fly.io or Railway. |
| **Railway** | Need for deeper AWS integration, enterprise procurement, or compliance; move to AWS. |
| **Fly.io** | Ops simplicity wanted over geo-flexibility; move to Render or Railway. |
| **AWS** | Team can't absorb ops burden; move to Vercel/Railway. |
| **Cloudflare Workers** | Workload mismatch (long-running, non-edge-friendly); move to Vercel or Fly.io. |
| **Self-hosted** | Team loses ops capability; move to managed. |

### Observability flip points

| Candidate | What flips it |
|---|---|
| **Sentry** | Rarely flipped; error tracking is a stable default. |
| **Datadog** | Cost at scale; move to Grafana Cloud or self-host. |
| **Honeycomb** | Team doesn't invest in tracing; the tool goes underused. |
| **Axiom** | Feature gap (no APM, limited dashboarding); pair with Grafana or move to Datadog. |
| **Grafana Cloud** | Team grows and wants commercial support; Datadog or Grafana Cloud Pro. |

### Payment flip points

| Candidate | What flips it |
|---|---|
| **Stripe** | Need for Merchant of Record globally (VAT handling); add Paddle or use as MoR. |
| **Stripe Connect** | Marketplace scale past Stripe Connect's pricing comfort; Adyen. |
| **Paddle** | Need for Connect-style split payments; Paddle's equivalent is weaker. |
| **Adyen** | Pre-enterprise; Stripe's DX is better. |
| **Lemon Squeezy** | Growth past ~$1M ARR; Stripe's tooling depth becomes the deciding factor. |

### Email flip points

| Candidate | What flips it |
|---|---|
| **Postmark** | Rarely flipped; deliverability is Postmark's moat. |
| **Resend** | Deliverability issue at volume; move to Postmark. |
| **SendGrid** | Deliverability concerns, DX dissatisfaction; move to Postmark or Resend. |
| **AWS SES** | Deliverability problems, DKIM/SPF/DMARC becoming a full-time job; move to Postmark or Resend. |
| **Loops** | Feature gap (marketing automation depth); move to Customer.io. |

### Background jobs flip points

| Candidate | What flips it |
|---|---|
| **Inngest** | Need for workflow engine with human-in-the-loop, multi-day sagas; move to Temporal. |
| **Trigger.dev** | Same as Inngest; the two are close competitors. |
| **Temporal** | Ops burden; the team wanted simpler workflows. Move to Inngest. |
| **BullMQ** | Need for durability beyond Redis; move to Inngest or SQS. |
| **Sidekiq** | Moving off Rails; Sidekiq stays in Rails. |

## Scale-ceiling library

Where each candidate starts fighting the team.

### Database ceilings

- **Postgres (single instance, managed host)**: ~5,000-10,000 writes/second sustained; ~10,000 queries/second; ~10TB data with care. Typical ceilings show up as query-latency degradation, not hard limits.
- **Convex**: cross-tenant aggregations, complex reporting queries; scale up to ~100k DAU per app before pricing or query-model friction. Varies by feature mix.
- **Supabase**: follows Postgres ceiling for DB; hosted tier pricing gets attention around 100-500GB or 10k+ DAU.
- **Firebase Firestore**: read pricing dominates at scale; ~1M DAU on a read-heavy app is where pricing becomes a boardroom conversation.
- **MongoDB**: sharding is the scaling story; ~10k writes/s on a primary before sharding.
- **ClickHouse**: tens of billions of rows with proper schemas; OLAP scale is vast.
- **SQLite (via LiteFS or Turso)**: fine for mostly-read workloads at modest write rates; high-concurrency writes need explicit handling.

### Framework ceilings

- **Next.js on Vercel**: rarely the bottleneck for most apps; pricing is the usual ceiling before raw performance.
- **Rails + Hotwire**: mature at any scale; the ceiling is often team-specific (Ruby throughput on a tight-loop workload).
- **Phoenix LiveView**: hundreds of thousands of concurrent WebSocket connections per server; a Phoenix app rarely hits a framework ceiling.
- **Django**: well-understood scale; WSGI workers and database are typical ceilings, not Django itself.

### Auth ceilings

- **Clerk**: check current MAU pricing; typical enterprise-flip around 50k+ MAU or SAML requirement.
- **Better Auth**: depends on self-hosted DB; ceiling is where your DB + infra stops serving auth traffic.
- **WorkOS**: enterprise-grade; pricing is seat-based in a range most enterprises accept.

### Hosting ceilings

- **Vercel**: pricing cliffs before infrastructure cliffs. Production apps with heavy traffic hit the Enterprise tier.
- **Railway**: a few thousand vCPU and terabytes of DB; commercial scale is real.
- **Fly.io**: persistent process workloads scale horizontally with good primitives.
- **AWS**: essentially no ceiling; the ceiling is your team's operational capacity.
- **Self-hosted VPS**: scales to the box; past that, you are building cloud infrastructure.

## Switching-cost library

Honest engineer-week estimates for exiting each candidate.

### Database switches (most painful)

- **Postgres to MySQL (or vice versa)**: rare; 2-8 weeks depending on feature dependence (JSONB, PostGIS, advanced Postgres features).
- **Convex to Postgres**: 4-16 weeks depending on app size. Data model translation is the dominant cost.
- **Supabase to self-hosted Postgres**: 1-4 weeks for DB; 2-6 additional weeks for Auth/Storage replacements.
- **Firebase Firestore to Postgres**: 8-24 weeks; data model translation + refactor of query patterns.
- **MongoDB to Postgres**: 6-16 weeks depending on schema evolution in the Mongo side.

### ORM switches (moderate)

- **Prisma to Drizzle**: 2-8 weeks; migration file re-work + query rewriting.
- **Drizzle to Prisma**: 2-6 weeks.
- **ActiveRecord to anything**: not typically done; ActiveRecord moves with Rails.

### Auth switches (user-visible)

- **Better Auth to WorkOS**: 1-3 weeks for small apps; 3-8 weeks for apps with complex RBAC and established user base.
- **Clerk to Better Auth**: 2-6 weeks; user import is the friction.
- **Auth0 to Clerk**: 2-4 weeks.
- **Rolling your own to a provider**: 2-6 weeks plus the bugfix you just inherited.

### UI library switches (spread-out)

- **MUI to shadcn/ui**: 4-12 weeks; every component re-built.
- **shadcn/ui to custom design system**: 2-6 weeks; shadcn is easier to evolve than replace since you own the code.
- **Mantine to Radix-based**: 3-8 weeks.

### Hosting switches (variable)

- **Vercel to Railway**: 1-2 weeks for most Next.js apps; Edge/Middleware features can complicate.
- **Vercel to AWS**: 2-6 weeks; CI/CD rebuild, infrastructure-as-code.
- **Railway to AWS**: 2-4 weeks.
- **Heroku to anywhere**: 1-3 weeks.
- **Self-hosted to managed**: usually 1-2 weeks; migrations are simpler in this direction.

### Payment switches (painful; user-visible)

- **Stripe to Adyen**: 4-12 weeks; subscription migration, PCI consideration, user re-authorization.
- **Stripe to Paddle**: 2-6 weeks; MoR transition is the friction.
- **Custom payment to Stripe**: 2-6 weeks; mostly deleting code.

### Observability switches (low-cost)

- **Sentry to anywhere (or vice versa)**: 1-2 weeks.
- **Datadog to Grafana Cloud**: 2-4 weeks for dashboard and alert migration.
- **Adding observability to a bare app**: 1 week for basic coverage, 4+ weeks for full adoption.

### Email switches (straightforward)

- **Any to any**: 1-2 weeks. DNS changes (DKIM, SPF) are the friction.

### Background job switches

- **BullMQ to Inngest**: 2-6 weeks.
- **Inngest to Trigger.dev**: 2-4 weeks.
- **Sidekiq to anything**: rarely done.
- **Self-managed queue to managed**: 1-3 weeks for simple queues.

## How to write a tradeoff narrative

Three paragraphs. Each 1-3 sentences. Concrete, not abstract.

### Bad example

> **What flips this:** if the requirements change significantly. **Scale ceiling:** it depends on traffic. **Switching cost:** could be significant.

Everything here is a placeholder. Nothing is actionable.

### Good example

> **What flips this:** if the customer pipeline adds even one enterprise buyer asking for SAML or SCIM in the next 6 months, Better Auth is no longer the right anchor. WorkOS replaces it; the rest of the bundle holds. **Scale ceiling:** Drizzle + Postgres on Neon handles ~50k DAU with standard workloads. At that point, read replicas and query review become active work, not background tasks. Vercel pricing starts to matter around 500GB/month egress. **Switching cost:** Better Auth to WorkOS is 1-2 weeks if done before 1k users, 3-6 weeks after. Vercel to AWS is 2-4 weeks. Nothing in this bundle traps you.

Three paragraphs, nine sentences, concrete numbers, named failure modes.

## Patterns to avoid

- **"It depends"** as the flip-point. State the variable.
- **"Very large scale"** as the ceiling. State a number.
- **"Manageable migration"** as the switching cost. State engineer-weeks.
- **"No real tradeoffs"** is always false. Find them.
