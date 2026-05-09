# Stack Bundles

Pre-combined "stacks that just work" for the 12 domains, three archetypes each. Compatibility-checked against `pairing-rules.md`. These are the starting shortlists the skill pulls in Step 3.

**Scope owned by this file:** the 36 bundles (12 domains x 3 archetypes) with their complete dimension fills and the one-line rationale for why each bundle hangs together. Per-candidate scoring lives in `domain-stacks.md` and `scoring-framework.md`.

## How to read a bundle

Each bundle has:
- A name.
- A fit profile (who this is for).
- A 12-dimension fill.
- A one-line coherence rationale (why these pieces go together).
- A flip indicator (when to prefer one of the other archetypes).

Where a dimension is "N/A," the bundle's platform replaces it (e.g., Convex replaces DB + ORM).

## The three archetypes

- **Safe Default.** The pick that is "probably right" for a domain when the user has not stated a strong opinion. Small-to-medium team, cash-efficient, ship in weeks, mature tooling preferred.
- **Fast-to-Ship.** Maximum BaaS leverage. Solo founder or tiny team, shipping in days or short weeks, willing to trade scale ceiling for velocity.
- **Enterprise.** 10+ engineers, compliance in scope, portability matters, ops maturity, enterprise customer asks (SAML, SCIM, audit, SLA) in the pipeline.

---

## Domain 1: SaaS / Multi-tenant

### SaaS - Safe Default

Team of 3-8, cash-efficient, SAML not yet in the pipeline, ship in weeks.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (managed: Neon, Supabase DB, or Railway Postgres) |
| ORM | Drizzle |
| Auth | Better Auth |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query + Server Components |
| Hosting | Vercel (or Railway for persistent needs) |
| Observability | Sentry + Axiom |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Inngest |

**Coherence:** All TypeScript, minimal new languages to learn, managed everything, maturely-paired. Better Auth gives you self-hostable identity without building it. Inngest handles durable workflows without forcing Temporal complexity.

**Flip to Fast-to-Ship** if: solo founder, shipping in days, willing to trade on-prem and reporting complexity for speed.

**Flip to Enterprise** if: customer pipeline includes 5+ companies asking for SAML/SCIM/audit log export in year one.

### SaaS - Fast-to-Ship

Solo or 2-person team, MVP in days-to-weeks, ship first, scale later.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Convex |
| ORM | N/A (Convex is the data layer) |
| Auth | Clerk |
| UI | shadcn/ui |
| Client state | Convex hooks |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Inngest (or Convex scheduled functions for simple cases) |

**Coherence:** Managed BaaS (Convex) collapses DB + ORM + reactivity into one layer. Clerk gives you complete auth UI in a day. Everything hosts on Vercel.

**Flip to Safe Default** if: reporting/analytics becomes central (Convex's query model will hit a ceiling on cross-tenant SQL). If you need long-running durable workflows, if compliance becomes a real constraint, or if the team grows past 4 engineers.

### SaaS - Enterprise

10+ engineers, SOC 2, SAML/SCIM customers, ops team exists.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres on AWS RDS (Multi-AZ) |
| ORM | Prisma (or Drizzle; Prisma's migration tooling is slightly better for team scale) |
| Auth | WorkOS (AuthKit) |
| UI | Custom design system built on Radix primitives |
| Client state | TanStack Query + Server Components |
| Hosting | AWS (ECS Fargate or EKS) |
| Observability | Datadog |
| Payments | Stripe |
| Email | Postmark (compliance-oriented) |
| Background jobs | Temporal (for complex workflows) or Inngest |

**Coherence:** WorkOS unlocks SAML/SCIM without building it. AWS gives compliance flexibility (VPC, private subnets, SOC 2-eligible services). Datadog pays off at team scale. Temporal handles workflows that span hours or days with retries and visibility.

**Flip to Safe Default** if: enterprise asks are aspirational but not real (no signed contracts), team size hasn't justified the AWS + Datadog bill yet.

---

## Domain 2: E-commerce / Retail

### E-commerce - Safe Default

D2C or B2B store, team of 2-6, typical catalog (hundreds to low thousands of SKUs).

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (managed) |
| ORM | Prisma (cleaner migrations for catalog evolution) |
| Auth | Clerk |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry + PostHog |
| Payments | Stripe + Stripe Tax |
| Email | Postmark |
| Background jobs | Inngest |

**Coherence:** Stripe + Stripe Tax handles the checkout + tax compliance axis. PostHog gives you funnel analytics out of the box. Postmark for transactional (order confirmations, shipping).

**Flip to Fast-to-Ship** if: the catalog is small (<50 SKUs), simple variants, no custom checkout needs. Shopify Basic + Hydrogen can beat a custom build.

**Flip to Enterprise** if: SKU count >5k, multi-region, B2B pricing tiers, international tax complexity.

### E-commerce - Fast-to-Ship

Shopify-backed storefront for a brand that wants faster velocity than stock Shopify themes.

| Dimension | Pick |
|---|---|
| Framework | Shopify Hydrogen |
| Language | TypeScript |
| Database | Shopify (catalog + orders) + optional Postgres for custom data |
| ORM | Minimal; mostly Shopify APIs |
| Auth | Shopify customer accounts |
| UI | Tailwind + custom, or Shopify's component library |
| Client state | Remix-style data loaders (Hydrogen is Remix-based) |
| Hosting | Shopify Oxygen |
| Observability | Sentry |
| Payments | Shopify Payments |
| Email | Klaviyo (marketing) + Postmark (transactional) |
| Background jobs | Shopify webhooks + Inngest for custom logic |

**Coherence:** Shopify handles catalog, inventory, checkout, tax, and fulfillment. Hydrogen gives you custom storefront velocity without throwing away the Shopify backbone.

**Flip to Safe Default** if: the brand outgrows Shopify's model (highly custom catalog, custom checkout, deeply B2B) and wants a from-scratch build.

### E-commerce - Enterprise

Large catalog, B2B or B2C at scale, compliance and performance are real.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 (or MedusaJS for commerce-native TypeScript) |
| Language | TypeScript |
| Database | Postgres (multi-AZ, read replicas) |
| ORM | Prisma (with hand-tuned queries for hot paths) |
| Auth | WorkOS (B2B) or Clerk (B2C scale) |
| UI | Custom design system on Radix primitives |
| Client state | TanStack Query |
| Hosting | AWS (CloudFront + ECS) |
| Observability | Datadog |
| Payments | Stripe Adaptive or Adyen |
| Email | Postmark + Klaviyo |
| Background jobs | Inngest or Temporal for multi-step fulfillment |
| Search | Algolia |

**Coherence:** Bespoke everything. Algolia for large catalog discovery. Adyen for global payment coverage.

**Flip to Safe Default** if: the enterprise framing is aspirational. Starting at this weight with a small team front-loads complexity.

---

## Domain 3: CMS / Content / Blog

### CMS - Safe Default

Team running a content site or blog, 2-5 writers + editors, structured content with preview.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 (ISR + preview mode) |
| Language | TypeScript |
| Database | Postgres |
| ORM | Drizzle |
| Auth | Better Auth |
| UI | shadcn/ui + Radix (admin) / custom (public-facing) |
| Client state | Server Components |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | N/A (or Stripe if paid content) |
| Email | Resend |
| Background jobs | Inngest (search indexing, scheduled publishes) |
| Search | Postgres FTS (small) or Algolia (larger) |

**Coherence:** Custom Next.js-based CMS with Postgres as the content store. Preview mode for unpublished content. ISR for performance.

**Flip to Fast-to-Ship** if: the team wants to skip the CMS build entirely.

**Flip to Enterprise** if: editorial team grows past ~5 writers, 20+ content types, multi-language with translation workflow.

### CMS - Fast-to-Ship

Skip the CMS build; use a headless CMS with a custom frontend.

| Dimension | Pick |
|---|---|
| Framework | Astro (content-heavy) or Next.js |
| Language | TypeScript |
| CMS | Sanity (or Payload for self-host, or Hygraph) |
| Database | (CMS-provided) |
| ORM | N/A (CMS client SDK) |
| Auth | CMS for editors; Clerk for paid readers |
| UI | shadcn/ui + Radix or Tailwind + custom |
| Client state | Server Components |
| Hosting | Vercel or Netlify |
| Observability | Sentry |
| Payments | Stripe (if paid tier) |
| Email | Buttondown or ConvertKit (newsletter) + Resend (transactional) |
| Background jobs | N/A at this scale (CMS handles publishing) |

**Coherence:** Sanity handles the content model, editor UX, and preview. Astro builds a fast public site over it. Near-zero backend code.

**Flip to Safe Default** if: the content model requires deep custom workflows that the headless CMS forces you to hack around.

### CMS - Enterprise

Large editorial operation, translations, complex approval workflows, many authors.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| CMS | Sanity with custom Studio or Payload (self-host) |
| Database | Postgres (for companion business data) |
| ORM | Drizzle |
| Auth | WorkOS for staff; Clerk for readers |
| UI | Custom design system |
| Client state | Server Components + TanStack Query |
| Hosting | Vercel Enterprise or AWS |
| Observability | Datadog |
| Email | Postmark + Customer.io (member comms) |
| Background jobs | Inngest |
| Search | Algolia |

**Coherence:** Staff SSO via WorkOS, paid reader accounts via Clerk. Sanity or Payload as the content backbone; Algolia for reader-facing search.

---

## Domain 4: Fintech / Financial

### Fintech - Safe Default

Financial product team of 3-8, compliance in scope but not enterprise procurement yet.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (with strict `NUMERIC` for money, append-only ledger tables) |
| ORM | Drizzle (SQL-transparent for audit) |
| Auth | Clerk + standalone audit logging |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query |
| Hosting | Vercel (verify current SOC 2 tier) or Railway |
| Observability | Sentry + Axiom (log-oriented) |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Inngest (idempotency-friendly) |

**Coherence:** Postgres `NUMERIC` for integer-cent money arithmetic. Drizzle exposes SQL so audits are legible. Idempotent background work via Inngest.

**Flip to Fast-to-Ship** rarely; fintech rarely benefits from the fast-to-ship compromise (compliance debt is expensive).

**Flip to Enterprise** if: the product goes through bank partnerships, broker-dealer registration, international payments, or enterprise procurement.

### Fintech - Fast-to-Ship

Cautious recommendation. Only for pre-revenue fintech experiments that are not yet custodial or regulated.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (Supabase or Neon) |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe Standard Accounts (not Connect) |
| Email | Resend |
| Background jobs | Inngest |

**Coherence:** Same shape as Safe Default but with cheaper managed services and no custom audit infra. Viable for bookkeeping-style apps, budgeting tools, financial dashboards where the team is not handling custody.

**Strong flip** to Safe Default or Enterprise the moment the product touches custody, lending, brokerage, or regulated deposits.

### Fintech - Enterprise

Regulated product (bank partnership, lender, broker-dealer), enterprise procurement likely.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 or Rails 8 |
| Language | TypeScript or Ruby |
| Database | Postgres on AWS RDS (Multi-AZ, PITR) |
| ORM | Prisma or ActiveRecord |
| Auth | WorkOS (SAML/SCIM for institutional clients) |
| UI | Custom design system on Radix |
| Client state | TanStack Query |
| Hosting | AWS (SOC 2 and PCI-eligible services) |
| Observability | Datadog |
| Payments | Stripe Connect or Adyen; core bank via partner (Unit, Treasury Prime) |
| Email | Postmark |
| Background jobs | Temporal |

**Coherence:** AWS gives you regulated-workload flexibility. Temporal handles multi-step workflows (KYC, onboarding, disbursement) with reliability guarantees. WorkOS is table stakes for institutional procurement.

---

## Domain 5: Healthcare / Medical

### Healthcare - Safe Default

Healthcare startup, HIPAA in scope, small team.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres on AWS RDS (BAA signed) |
| ORM | Drizzle |
| Auth | WorkOS (with BAA) or self-hosted Keycloak |
| UI | Radix primitives + custom (accessibility-first) |
| Client state | TanStack Query |
| Hosting | AWS (BAA-eligible services) |
| Observability | Sentry with PHI scrubbing + BAA |
| Payments | Stripe (for cash-pay telehealth) |
| Email | Paubox or Postmark with BAA |
| Background jobs | Inngest (with BAA) or self-hosted Temporal |

**Coherence:** Every layer has a BAA path. AWS is the compliance default. Custom UI atop Radix primitives for accessibility confidence.

**Flip to Fast-to-Ship** is strongly discouraged for HIPAA apps. If you must, ensure every BaaS provider has a BAA at the paid tier you're using.

**Flip to Enterprise** if: EHR integration, clinical workflows, or institutional hospital buyers are in scope.

### Healthcare - Fast-to-Ship

Only viable for healthcare apps that do not touch PHI directly (de-identified analytics, practitioner-only tools, wellness apps operating at the edge of HIPAA).

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Supabase (verify current HIPAA offering) or Postgres on Neon Pro (with BAA if available) |
| ORM | Drizzle |
| Auth | Clerk (verify BAA tier) |
| UI | shadcn/ui |
| Client state | TanStack Query |
| Hosting | Vercel Pro (verify BAA) |
| Observability | Sentry |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Inngest |

**Caution:** BAA coverage across these vendors has been in flux. Verify each one during the session. If any one lacks a BAA at your tier, the bundle does not work for PHI.

### Healthcare - Enterprise

EHR-adjacent, institutional buyers, FHIR integration.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres on AWS RDS + healthcare-specific extensions |
| ORM | Prisma |
| Auth | WorkOS (SAML for institutional SSO) |
| UI | Custom design system on Radix |
| Client state | TanStack Query |
| Hosting | AWS HIPAA-eligible services |
| Observability | Datadog with BAA |
| Payments | Stripe (if applicable) |
| Email | Paubox |
| Background jobs | Temporal (for clinical workflows with audit) |
| FHIR | Medplum or custom FHIR server |

**Coherence:** Everything is BAA-covered. Medplum provides a FHIR-native backend for clinical data interop.

---

## Domain 6: Education / LMS

### Education - Safe Default

Course creator tools, cohort-based courses, small-to-medium LMS.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres |
| ORM | Drizzle |
| Auth | Clerk |
| UI | Radix primitives + custom (accessibility-first) |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Inngest |
| Video | Mux |

**Coherence:** Accessibility-first UI is the gate. Mux handles video without self-hosting. Clerk covers auth for students and instructors.

**Flip to Fast-to-Ship** if: skipping the LMS build via Teachable/Podia/Kajabi fits the content.

**Flip to Enterprise** if: higher-ed procurement, LTI integration, or state-specific K-12 compliance.

### Education - Fast-to-Ship

Skip the custom LMS; use a platform.

| Dimension | Pick |
|---|---|
| Platform | Teachable, Podia, Kajabi, or Circle.so for community |
| Custom frontend | Astro (marketing pages) linking out to platform |
| Auth | Platform-handled |
| Payments | Platform-handled |

**Coherence:** Skip the stack question entirely. If the content fits a platform, the platform wins on velocity.

### Education - Enterprise

Institutional LMS, higher ed or K-12 procurement.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 or Rails 8 |
| Language | TypeScript or Ruby |
| Database | Postgres on AWS RDS |
| ORM | Prisma or ActiveRecord |
| Auth | WorkOS (SAML, SCIM, LTI) |
| UI | Custom design system with WCAG AA compliance |
| Client state | TanStack Query |
| Hosting | AWS |
| Observability | Datadog |
| Email | Postmark |
| Background jobs | Inngest or Sidekiq |
| Video | Mux or Cloudflare Stream |
| Interop | LTI 1.3, QTI if assessments are exchanged |

**Coherence:** SAML for institutional SSO, LTI for integration with institutional platforms (Canvas, Moodle, Blackboard), WCAG AA is contractual.

---

## Domain 7: CRM / Sales / Marketing

### CRM - Safe Default

B2B CRM for SMB or mid-market sales teams.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (with JSONB for custom fields) |
| ORM | Drizzle |
| Auth | Clerk (with Organizations) |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry + PostHog |
| Payments | Stripe (seat-based) |
| Email | Resend (transactional) + Customer.io (marketing/lifecycle) |
| Background jobs | Inngest |

**Coherence:** Dual email pipeline (transactional + marketing). PostHog for product analytics on a CRM is near-mandatory. JSONB on Postgres for custom fields that CRM users demand.

**Flip to Fast-to-Ship** if: the team can buy a white-label CRM or use HubSpot-as-platform rather than building.

**Flip to Enterprise** if: the pipeline includes sales orgs with 100+ reps, Salesforce bi-directional sync, enterprise data residency.

### CRM - Fast-to-Ship

Vertical SaaS with lightweight CRM; build the CRM as part of the app, not the whole product.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Inngest |

**Coherence:** Same basic bundle as SaaS Safe Default. The CRM features are a module, not the whole product.

### CRM - Enterprise

Platform-scale CRM with heavy customization, enterprise integrations.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres + ClickHouse (for event/activity data) |
| ORM | Prisma + raw SQL for analytics |
| Auth | WorkOS |
| UI | Custom design system |
| Client state | TanStack Query |
| Hosting | AWS |
| Observability | Datadog |
| Payments | Stripe (seat-based, enterprise tier) |
| Email | Postmark + Customer.io |
| Background jobs | Temporal |
| Search | Algolia or Elasticsearch |

**Coherence:** OLTP + OLAP split. Temporal for complex lead-routing workflows. Enterprise SSO.

---

## Domain 8: Customer Support / Helpdesk

### Helpdesk - Safe Default

Support team tooling, real-time, 5-30 agents.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 + WebSockets via Pusher or Ably |
| Language | TypeScript |
| Database | Postgres |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query + WebSocket subscriptions |
| Hosting | Railway or Fly.io (persistent WebSockets) |
| Observability | Sentry + Honeycomb |
| Payments | N/A (internal) or Stripe (if SaaS) |
| Email | Postmark (inbound + outbound) |
| Background jobs | Inngest |

**Coherence:** Persistent-process hosting (not Vercel default) for WebSocket fanout. Postmark for inbound email parsing into tickets. Honeycomb for latency debugging when real-time feels slow.

**Flip to Fast-to-Ship** if: the org can use Intercom, Front, or Help Scout directly and skip the build.

**Flip to Enterprise** if: 100+ agents, SLA contracts, enterprise CRM integrations.

### Helpdesk - Fast-to-Ship

Phoenix LiveView for teams with Elixir depth.

| Dimension | Pick |
|---|---|
| Framework | Phoenix LiveView |
| Language | Elixir |
| Database | Postgres |
| ORM | Ecto |
| Auth | Phoenix auth generators or pow |
| UI | Tailwind + custom |
| Client state | LiveView-native |
| Hosting | Fly.io |
| Observability | Sentry + AppSignal (Elixir-native) |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Oban |

**Coherence:** Elixir/Phoenix real-time is a match for helpdesk workloads. Soft real-time concurrency is native. Assumes team has Elixir depth or is willing to learn.

### Helpdesk - Enterprise

Large support org, SLA, enterprise integrations.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 + persistent WebSocket layer |
| Language | TypeScript |
| Database | Postgres + ClickHouse (analytics) |
| ORM | Prisma |
| Auth | WorkOS |
| UI | Custom design system |
| Client state | TanStack Query + WebSockets |
| Hosting | AWS (ECS + API Gateway WebSockets, or Fly.io) |
| Observability | Datadog + Honeycomb |
| Payments | Stripe |
| Email | Postmark + Customer.io |
| Background jobs | Temporal |

---

## Domain 9: Marketplace / Two-sided

### Marketplace - Safe Default

Two-sided marketplace, GMV under $10M/year, team of 3-8.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres + PostGIS (for geo) |
| ORM | Drizzle |
| Auth | Clerk + Stripe Identity or Persona for IDV |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry + PostHog |
| Payments | Stripe Connect |
| Email | Postmark |
| Background jobs | Inngest |
| Search | Algolia or MeiliSearch |

**Coherence:** Stripe Connect is the default split-payment engine. PostGIS on Postgres for "listings near me." Algolia for discovery. IDV is a must from day one.

**Flip to Fast-to-Ship** if: MVP with no payment routing yet; can run with Stripe Standard initially.

**Flip to Enterprise** if: GMV crosses $10M or geographic scope becomes global.

### Marketplace - Fast-to-Ship

MVP marketplace, no payment routing yet, proving demand.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (Supabase or Neon) |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe Standard (single account, platform holds) |
| Email | Resend |
| Background jobs | Inngest |
| Search | Postgres FTS |

**Coherence:** Skip Stripe Connect until paid sellers are real. Skip Algolia until catalog size demands it. Classic lean MVP.

### Marketplace - Enterprise

Scaled marketplace, international, regulatory complexity.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres + PostGIS + ClickHouse |
| ORM | Prisma |
| Auth | WorkOS + Persona (enterprise IDV) |
| UI | Custom design system |
| Client state | TanStack Query |
| Hosting | AWS |
| Observability | Datadog |
| Payments | Adyen (global coverage) or Stripe Connect at enterprise tier |
| Email | Postmark + Customer.io |
| Background jobs | Temporal |
| Search | Algolia or Elasticsearch |

---

## Domain 10: AI / ML / LLM products

### AI Product - Safe Default

LLM-powered product, small-to-medium team, multi-provider, eval-disciplined.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 + Vercel AI SDK |
| Language | TypeScript |
| Database | Postgres + pgvector |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui + Radix + assistant-ui for chat |
| Client state | Vercel AI SDK hooks + TanStack Query |
| Hosting | Vercel (Edge for streaming) |
| Observability | Sentry + Helicone (or Langfuse) |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Inngest (LLM chains) |
| Model providers | Anthropic + OpenAI (fallback) |
| Eval | Braintrust |

**Coherence:** Vercel AI SDK is the default TypeScript streaming UX layer. pgvector beats standalone vector DBs at most scales. Braintrust for eval + prompt versioning. Multi-provider from day one.

**Flip to Fast-to-Ship** if: single-provider experiment, proving a prompt works, no production eval needed yet.

**Flip to Enterprise** if: customer compliance requires data-isolation, on-prem models, or enterprise SSO.

### AI Product - Fast-to-Ship

Single-provider MVP, proving demand for an LLM feature.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 + Vercel AI SDK |
| Language | TypeScript |
| Database | Postgres (Supabase or Neon) |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui |
| Client state | Vercel AI SDK hooks |
| Hosting | Vercel |
| Observability | Sentry |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Inngest |
| Model providers | Anthropic (single) |
| Eval | Manual for now, add Braintrust when users arrive |

**Coherence:** Same base bundle, no eval rigor yet. Add rigor as soon as users exist.

### AI Product - Enterprise

AI product for enterprise customers, compliance and isolation real.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres + pgvector (self-hosted or dedicated) |
| ORM | Prisma |
| Auth | WorkOS |
| UI | Custom design system |
| Client state | Vercel AI SDK hooks + TanStack Query |
| Hosting | AWS (Bedrock for models with data residency) |
| Observability | Datadog + Langfuse (self-hosted) |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Temporal |
| Model providers | Anthropic via Bedrock, OpenAI via Azure (compliance-friendly routes) |
| Eval | Braintrust or self-hosted LangSmith |

**Coherence:** Bedrock and Azure for enterprise-friendly model access with data residency. WorkOS for enterprise SSO. Temporal for complex multi-agent workflows.

---

## Domain 11: Analytics / BI / Dashboards

### Analytics - Safe Default

Embedded analytics or standalone BI for a team of 3-8.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | Postgres (OLTP) + ClickHouse (OLAP) |
| ORM | Drizzle (OLTP), raw SQL (OLAP) |
| Auth | Clerk |
| UI | shadcn/ui + Radix + Tremor (dashboard-specific) |
| Charts | visx or ECharts |
| Client state | TanStack Query |
| Hosting | Vercel + ClickHouse Cloud |
| Observability | Sentry + Datadog (query visibility) |
| Payments | Stripe (if SaaS) |
| Email | Postmark |
| Background jobs | Inngest |
| Semantic layer | Cube |

**Coherence:** OLTP + OLAP split from day one. Cube for metric definitions to prevent definition drift.

**Flip to Fast-to-Ship** if: the analytics is small, Postgres alone handles it, no semantic layer needed yet.

**Flip to Enterprise** if: embedded analytics in other products, multi-tenant, white-label.

### Analytics - Fast-to-Ship

Internal dashboards or simple analytics MVP.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 (or Streamlit for internal-only) |
| Language | TypeScript (or Python for Streamlit) |
| Database | Postgres (read replica) |
| ORM | Drizzle |
| Auth | Clerk |
| UI | shadcn/ui + Tremor |
| Charts | Recharts |
| Client state | TanStack Query |
| Hosting | Vercel |
| Observability | Sentry |
| Background jobs | Inngest |

**Coherence:** Skip ClickHouse until you need it. Postgres with a read replica handles most early analytics workloads.

### Analytics - Enterprise

Embedded analytics platform, B2B, white-labeled, multi-tenant.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | ClickHouse (primary) + Postgres (metadata) |
| ORM | Raw SQL (ClickHouse) + Drizzle (Postgres) |
| Auth | WorkOS (for embedded SSO) |
| UI | Custom design system |
| Charts | visx or ECharts |
| Client state | TanStack Query |
| Hosting | AWS + ClickHouse Cloud |
| Observability | Datadog |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Inngest or Temporal |
| Semantic layer | Cube |

**Coherence:** ClickHouse-primary for query performance. Cube for reusable metrics. WorkOS for embedded SSO into customer apps.

---

## Domain 12: Internal Tools / Back-office

### Internal - Safe Default

Internal ops tool for a team of 10-50 employees.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 |
| Language | TypeScript |
| Database | (reuse existing production DB via read-or-write as appropriate) |
| ORM | (reuse existing ORM) |
| Auth | Existing company SSO via WorkOS |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query |
| Hosting | Vercel (internal deploy with auth gate) |
| Observability | Sentry |
| Payments | N/A |
| Email | Postmark (for internal alerts) |
| Background jobs | Inngest |

**Coherence:** Reuses the production stack so the team does not maintain two parallel codebases' worth of stack knowledge. SSO via WorkOS for the employee identity.

**Flip to Fast-to-Ship** often wins for internal tools; low-code is genuinely appropriate.

**Flip to Enterprise** rarely; internal tools don't need enterprise weight.

### Internal - Fast-to-Ship

Use a low-code platform.

| Dimension | Pick |
|---|---|
| Platform | Retool, Internal, Appsmith, Tooljet, or Budibase |
| Database | Connect to existing production DB (read-only views recommended) |
| Auth | Platform SSO integration with existing IdP |
| Observability | Platform-provided audit logs |

**Coherence:** Skip the build. Retool or equivalent delivers 80% of most internal tools in hours, not weeks.

**Flip to Safe Default** when: the tool becomes central (heavy usage, many workflows), low-code friction exceeds the value, or the tool needs to be customer-facing.

### Internal - Enterprise

Large-company internal tool with compliance, audit, complex permissions.

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 or Rails 8 |
| Language | TypeScript or Ruby |
| Database | Reuse production DB with dedicated read replica |
| ORM | Existing ORM |
| Auth | Company SSO via WorkOS or Okta |
| UI | Custom design system matching internal brand |
| Client state | TanStack Query |
| Hosting | Internal Kubernetes or AWS |
| Observability | Datadog |
| Email | Postmark |
| Background jobs | Existing production queue infrastructure |

**Coherence:** Reuses company infra. Auth matches the existing corporate IdP. Observability is centralized with the company's standard.

---

## Patterns across the 36 bundles

### Next.js + TypeScript is the TypeScript default

In 9 of 12 domains, Next.js + TypeScript is the Safe Default framework pick. The three exceptions are: Education Enterprise (Rails is 50/50 with Next.js); Helpdesk Fast-to-Ship (Phoenix LiveView when the team has Elixir depth); Fintech Enterprise (Rails is strong here too).

### Postgres dominates

Postgres is the DB pick in 10 of 12 Safe Default bundles. The exceptions: SaaS Fast-to-Ship (Convex), Analytics (ClickHouse + Postgres split).

### Stripe is near-universal

Stripe (or Stripe Connect) is the payment pick in 11 of the 12 domains where payments apply. Adyen is the Enterprise alternative for global coverage.

### WorkOS wins Enterprise

Every Enterprise bundle uses WorkOS for auth. The pattern is consistent: enterprise customers demand SAML + SCIM, and WorkOS is the leader.

### Fast-to-Ship has real domain variation

Convex for SaaS, Shopify Hydrogen for e-commerce, Sanity for CMS, Phoenix LiveView for helpdesk, Retool for internal. The unifying theme is "skip the build"; the specific platform depends on the domain.

### Enterprise bundles converge

Enterprise bundles look similar across domains: Next.js + TypeScript + Postgres (or ClickHouse) + WorkOS + AWS + Datadog + Temporal/Inngest + Stripe. The domain shapes the periphery (Algolia for marketplace, Medplum for healthcare, LTI for education, Cube for analytics).

## Named alternative bundles (new in 1.1.0)

Cross-domain bundles surfaced by the 2026-04 research. Each is a coherent, compatibility-checked stack that cuts across the 12 domains.

### Cloudflare-native

For greenfield Workers-first apps where edge latency and bundled primitives matter. Production-credible after D1/Queues/Hyperdrive GA (April 2024) and Workflows GA (2025).

| Dimension | Pick |
|---|---|
| Framework | Next.js 15 on Workers, Hono, or Astro (for content-heavy) |
| Language | TypeScript |
| Database | Cloudflare D1 (SQLite edge) or Hyperdrive + Neon Postgres |
| ORM | Drizzle |
| Auth | Better Auth (self-hosted on Workers) or Clerk |
| UI | shadcn/ui + Radix |
| Client state | TanStack Query or Server Components |
| Hosting | Cloudflare Pages / Workers |
| Observability | Axiom (Workers Logs native) + Sentry |
| Payments | Stripe |
| Email | Resend |
| Background jobs | Cloudflare Queues + Workflows (or Inngest for complex workflows) |
| File storage | Cloudflare R2 |

**Coherence:** Every layer runs on Cloudflare. R2 cuts egress vs S3. Durable Objects available for stateful requirements. Astro bundle particularly clean given the Cloudflare + Astro acquisition (Jan 2026).

**Flip** when: heavy Postgres transactional workload without Hyperdrive caching fit; need for multi-tenant SQLite-per-tenant that exceeds Durable Object Facets' scale; team without edge-runtime familiarity.

### Post-Cloud Rails

For Ruby teams with ops bandwidth, biased toward self-host economics. Quantified savings from 37signals ($10M+/5yr cloud exit) make this a credible default, not a meme.

| Dimension | Pick |
|---|---|
| Framework | Rails 8 + Hotwire/Turbo |
| Language | Ruby |
| Database | Postgres (or SQLite with Rails 8 defaults for smaller apps) |
| ORM | ActiveRecord |
| Auth | Devise (or Clerk for JS-heavy SPA layers if used) |
| UI | Tailwind + custom, or ViewComponent + Phlex |
| Client state | Hotwire (Turbo + Stimulus) |
| Hosting | Kamal 2 + Hetzner VPS |
| Observability | AppSignal (Rails-native) + Sentry |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Solid Queue (Rails 8 default, Postgres-backed) or Sidekiq |
| File storage | S3 or R2 (via Active Storage) |

**Coherence:** Kamal 2 ships with Rails 8. Solid Queue removes Redis dependency. One language, one runtime, one deploy story. Entire stack self-hostable on a €50/mo Hetzner box for moderate scale.

**Flip** when: team lacks Ruby depth; compliance procurement requires big-three cloud providers (AWS/GCP/Azure) by contract; workload requires edge latency (use Cloudflare-native or Vercel instead).

### Phoenix LiveView

For Elixir teams on real-time / soft-realtime domains (helpdesk, collab, presence, live dashboards). LiveView 1.0 shipped late 2024; 1.1 in 2025; production case studies real (Multiverse, Stord, Bleacher Report, Erlang Solutions).

| Dimension | Pick |
|---|---|
| Framework | Phoenix + LiveView 1.1 |
| Language | Elixir |
| Database | Postgres |
| ORM | Ecto |
| Auth | Phoenix auth generators (or pow) |
| UI | Tailwind + LiveView components |
| Client state | LiveView-native (HTML over the wire) |
| Hosting | Fly.io (BEAM-native clustering support) |
| Observability | AppSignal (Elixir-native) + Sentry |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Oban (Postgres-backed) |

**Coherence:** Soft real-time by default. One language, no separate JS framework needed for most surfaces. BEAM concurrency is a match for helpdesk, presence, chat, live dashboards.

**Flip** when: team has no Elixir depth (hiring risk); product requires deep native-mobile or offline-first story; very heavy client-side canvas / visualization that exceeds LiveView's server-driven ceiling.

### Django + HTMX + Alpine

For Python teams shipping content-heavy or admin-heavy apps without adding a JS framework. HTMX adoption among Django devs grew from 5% to 24% (2021-2025); Django 6.0 template partials make this canonical.

| Dimension | Pick |
|---|---|
| Framework | Django 6 + HTMX + Alpine.js |
| Language | Python |
| Database | Postgres |
| ORM | Django ORM (or SQLAlchemy for decoupled parts) |
| Auth | django-allauth |
| UI | Tailwind + custom |
| Client state | HTMX (server-rendered HTML over the wire) |
| Hosting | Fly.io, Render, or self-host with Dokku/Coolify |
| Observability | Sentry |
| Payments | Stripe |
| Email | Postmark |
| Background jobs | Celery or Dramatiq |

**Coherence:** Django admin out of the box for internal tooling. HTMX handles 80% of modern interactivity needs without shipping a JS framework. Strong for CMS, B2B admin, and internal tools.

**Flip** when: team has no Python depth; product requires heavy client-side interactivity where HTMX's server-round-trip model is user-visible; need for native mobile.

### TALL / Laravel + Livewire

For PHP teams shipping SaaS with Livewire (62%) or Inertia (48%) per State of Laravel 2025.

| Dimension | Pick |
|---|---|
| Framework | Laravel 12 + Livewire (or Inertia + Vue/React) |
| Language | PHP |
| Database | Postgres or MySQL |
| ORM | Eloquent |
| Auth | Laravel Breeze / Fortify / Jetstream |
| UI | Tailwind + Alpine.js + Livewire components |
| Client state | Livewire (server-driven) or Inertia |
| Hosting | Laravel Forge + VPS, or Fly.io, or Render |
| Observability | Sentry, Flare |
| Payments | Stripe (Laravel Cashier) |
| Email | Postmark |
| Background jobs | Laravel Queues (Redis/Horizon) |

**Coherence:** Laravel's tight ecosystem; Livewire + Alpine + Tailwind (the TALL stack) handles most SaaS UI without a JS framework. Laravel Forge + a VPS is the canonical cheap-and-happy deploy.

**Flip** when: team has no PHP depth; product needs native mobile as first-class; very heavy client-side state that exceeds Livewire's server-driven model.

## Using a bundle

The bundle is a starting shortlist, not a verdict. In Step 5, score each candidate against the pre-flight answers. In Step 6, name the flip point for the bundle the user is leaning toward. In Step 8, the chosen bundle plus its rationale becomes `.stack-ready/DECISION.md`.
