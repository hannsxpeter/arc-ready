# Domain Stacks

Per-dimension picks for 12 domain profiles. This is the core data the skill draws candidates from in Step 3.

**Scope owned by this file:** per-domain top picks across all 12 scoring dimensions, with one-line rationale and domain-specific flip points. Pre-combined bundles (Safe Default / Fast-to-Ship / Enterprise) live in `stack-bundles.md`. Anti-pairings live in `pairing-rules.md`. Scoring math lives in `scoring-framework.md`.

## How to read this file

Each domain has:

1. **Archetype**: one-line characterization of the product type.
2. **Hard constraints**: things the stack must do for this domain regardless of other preferences.
3. **Top picks table**: for each of 12 dimensions, the top pick, a runner-up, a budget alternative, and a common mistake to avoid. All picks are compatibility-checked against the pairing rules.
4. **Domain-specific notes**: the flip points, scale ceilings, and constraints that are easy to miss.

Scores in the tables are shown as guidelines (1-10) under the default weight vector. User overrides in Step 5 will shift them.

---

## 1. SaaS / Multi-tenant

**Archetype:** Platform serving organizations as the primary tenant, with per-tenant users, roles, subscriptions, and feature flags. Examples: Linear, Vercel Dashboard, Intercom, Notion.

**Hard constraints:**
- Tenant isolation must be enforced at the data layer, not only in application code.
- Subscription and seat-based billing must be modeled from day one (retrofitting is painful).
- Permissions are per-tenant, per-role, sometimes per-user overrides; RBAC is not optional.
- Usage analytics per tenant (product adoption, limit enforcement) is near-universal.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js 15 (9) | React Router v7 (8, ex-Remix v2) | SvelteKit (7) | Raw Express/Fastify for fullstack |
| Language | TypeScript (9) | Ruby (Rails path) (8) | Python (Django path) (7) | Go for frontend-heavy SaaS |
| Database | Postgres (10) | MySQL (7) | SQLite (dev only) (6) | MongoDB without explicit reason |
| ORM | Drizzle (9) | Prisma (8) | Kysely (7) | Raw SQL in TS without a thin wrapper |
| Auth | WorkOS (9 enterprise) / Better Auth (9 standard) | Clerk (8) | Auth.js (5, now in security-patch mode; for new projects use Better Auth) | Rolling your own |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind + custom (7) | Enterprise UI kits with lock-in |
| Client state | TanStack Query (9) | Server Components + Actions (9) | SWR (7) | Redux for a new SaaS |
| Hosting | Vercel (8) / Railway (8) | Fly.io (7) | Render (7) | DIY Kubernetes for a 3-person team |
| Observability | Sentry (9) + Axiom (8) | Datadog (8) | Grafana Cloud free (6) | console.log only |
| Payments | Stripe (10) | Paddle (8, if MoR needed) | Polar (8, low-fee MoR) / Lemon Squeezy (6, acquired by Stripe, absorbing into SMP) | Building a custom subscription engine |
| Email | Resend (9) | Postmark (9) | SendGrid (6) | AWS SES without a deliverability plan |
| Background jobs | Inngest (9) | Trigger.dev (8) | BullMQ (7) | Cron jobs in the web process |

**Domain-specific notes:**

- **Tenant isolation.** The biggest architectural decision in SaaS. Shared-schema with `org_id` everywhere is cheapest and works until ~1,000 tenants with privacy-sensitive data. Schema-per-tenant adds operational complexity but simplifies per-tenant backups, exports, and deletion. DB-per-tenant is rare outside highly regulated B2B. Decide at Tier 1; retrofitting is very expensive.
- **Postgres + Drizzle** is the default for new TypeScript SaaS in 2026. Prisma is the runner-up, not a mistake; choose Drizzle if your team wants SQL fluency, Prisma if you want the most DX out of the box.
- **Better Auth** has become the Auth.js successor for self-hosted SaaS identity in the TypeScript world. Clerk is the right call when you need polished UI and don't want to build auth screens. WorkOS is the right call when the customer list includes enterprises that will ask for SAML and SCIM in month six.
- **Convex** is a legitimate pick for SaaS if reporting is not a core feature; it scores 9/10 for greenfield MVPs but has a scale ceiling when cross-tenant aggregations become central (reporting, analytics, admin dashboards).
- **Flip point for the Safe Default bundle**: when the customer pipeline includes 5+ companies that will ask for SAML, SCIM, and audit log export in the first year. At that point, Better Auth moves to a 6/10 and WorkOS moves to 10/10.

---

## 2. E-commerce / Retail

**Archetype:** Store admin and storefront handling products, variants, inventory, orders, fulfillment, returns, and promotions. Examples: Shopify, WooCommerce, BigCommerce.

**Hard constraints:**
- Product data is a tree (product > variant > SKU > inventory per location), not a row.
- Price is a set of prices, not a single number (list, sale, member, tax-inclusive).
- Inventory is a ledger, not a counter (avoid race conditions at checkout).
- Payments with PCI compliance; card data never touches your server (tokenized).
- Tax calculation is a service call, not a lookup table.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js 15 (9) | Remix (8) | SvelteKit (7) | Raw Rails without Hotwire for a modern storefront |
| Language | TypeScript (9) | Ruby (Rails path, 8) | PHP (Laravel, 7) | Go for storefront UI |
| Database | Postgres (9) | MySQL (8) | SQLite (dev only) (5) | MongoDB for transactional inventory |
| ORM | Prisma (8) | Drizzle (8) | Raw SQL with Kysely (7) | Schemaless ODMs for orders |
| Auth | Clerk (8) | Better Auth (8) | Supabase Auth (7) | Rolling your own for a store |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind UI (7) | Rigid component kits that fight brand |
| Client state | TanStack Query (9) | SWR (8) | Server Components (9) | Redux for product catalog |
| Hosting | Vercel (8) | Shopify Hydrogen on Oxygen (8, if Shopify-backed) | Railway (7) | Self-host for a 2-person team |
| Observability | Sentry (9) + PostHog (9) | Datadog (8) | Grafana Cloud (6) | Ad-hoc logs |
| Payments | Stripe (9) + Stripe Tax (9) | Adyen (8, enterprise) | Stripe without Stripe Tax (6) | Manual tax tables |
| Email | Postmark (9) | Resend (9) | SendGrid (6) | SES for transactional cart email without DKIM |
| Background jobs | Inngest (9) | Trigger.dev (8) | BullMQ (7) | Sync fulfillment updates in the request path |

**Domain-specific notes:**

- **Commerce platforms vs. custom build.** Shopify, WooCommerce, or BigCommerce handle much of what this matrix recommends out of the box. A custom build makes sense for unusual catalog shapes (B2B with RFQs, marketplace with aggregated inventory, deeply branded D2C with custom checkout). For standard D2C with <5k SKUs, the build-vs-buy question usually favors buy.
- **MedusaJS** (TypeScript headless commerce) is a legitimate 8/10 pick when the team wants code ownership but not to reinvent commerce primitives. Treat it as a "framework" choice that replaces several dimensions at once.
- **Inventory integrity.** Use Postgres transactions and explicit locking on checkout; an ORM that obscures transaction boundaries (or docs that hand-wave it) hurts here.
- **Tax is a service.** Avalara, TaxJar, Stripe Tax. Do not build this yourself beyond simple single-jurisdiction setups.
- **Flip point for the Safe Default bundle**: when SKU count passes ~10k with rich variant logic (size x color x material), an off-the-shelf platform (Shopify Plus, commercetools) often beats a custom build.

---

## 3. CMS / Content / Blog

**Archetype:** Editorial tools for publishing structured content, with roles (author/editor/admin), previews, versioning, and translations. Examples: Contentful, Sanity, Strapi, Ghost, Payload.

**Hard constraints:**
- Content model is structured (rich text + typed fields), not a blob.
- Preview of unpublished content is table stakes; "publish to see it" loses writers.
- Revisions and draft/published separation are expected.
- Translations (i18n) add a dimension to every piece of content; plan early.
- Frontend is often decoupled (headless), but monolithic works fine for small teams.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js 15 (9) | Astro (9 content-heavy) | Nuxt (8) | Raw Express for a content site |
| Language | TypeScript (9) | JavaScript (7) | Go (5 for CMS) | Exotic stacks for editorial UX |
| Database | Postgres (9) | SQLite (8, read-heavy) | MongoDB (7 if Payload) | NoSQL for relational editorial metadata |
| ORM | Drizzle (8) | Prisma (8) | Payload's own data layer (8 if Payload) | Rolling custom ORM for CMS |
| Auth | Better Auth (8) | Clerk (8) | Auth.js (5, now in security-patch mode; for new projects use Better Auth) | Rolling auth into the CMS itself |
| UI library | shadcn/ui + Radix (9 admin) | Mantine (8) | Tailwind + custom (7) | Admin frameworks that fight your brand |
| Client state | Server Components (9) | TanStack Query (9) | SWR (7) | Client-only data fetching for SEO-critical |
| Hosting | Vercel (9 with ISR) | Netlify (8) | Cloudflare Pages (8) | Static-only hosting for a CMS with write needs |
| Observability | Sentry (9) | Axiom (8) | Grafana Cloud (6) | No observability for editorial workflow bugs |
| Payments | Stripe (9 if paid tier) | (N/A for ads-supported) | Polar (8, low-fee MoR) / Lemon Squeezy (6, acquired by Stripe, absorbing into SMP) | Rolling your own subscription management |
| Email | Resend (9) | Postmark (9) | Buttondown/ConvertKit (8 if newsletter-first) | SES without a newsletter partner |
| Background jobs | Inngest (8) | BullMQ (7) | Cron (6) | Synchronous cache invalidation on publish |

**Domain-specific notes:**

- **Headless CMS vs. in-app CMS.** Sanity, Contentful, and Hygraph are strong headless options that score 8-9/10 for teams that want to skip the CMS build entirely. Payload (TypeScript, self-hostable) is a growing 8/10 option with more code ownership. Ghost is 9/10 for publications that are primarily blogs.
- **Static site generators.** Astro (9/10 for content-heavy sites, blogs, marketing) outscores Next.js for pure content. Next.js wins when the site has significant interactive or authenticated surface area alongside content.
- **Search.** Content sites without search feel broken past ~50 posts. Algolia is the default (9/10); MeiliSearch (self-host, 8/10) and Typesense (8/10) are worthy alternatives; Postgres full-text search is adequate (7/10) for smaller sites.
- **Flip point for the Safe Default bundle**: when editorial team grows past ~5 writers or content model exceeds ~10 types with cross-references, a dedicated headless CMS (Sanity, Payload) beats a custom CMS build.

---

## 4. Fintech / Financial

**Archetype:** Money-handling applications: banking, accounting, bookkeeping, invoicing, payments, lending. Examples: QuickBooks, Wave, Plaid-adjacent tools, neobanks.

**Hard constraints:**
- Money is integer cents (or the minor unit for the currency), never a float.
- Double-entry ledger, not single-entry; every change is a credit and a debit.
- Append-only audit trail for every state change touching money or balances.
- PCI-DSS if card data, which usually means Stripe/Adyen tokenized flow (SAQ-A scope).
- SOC 2 Type II expected by enterprise customers; affects vendor selection across the stack.
- Regulatory constraints vary by jurisdiction (MiCA in EU, state money transmission in US, FINRA for brokerage).

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Rails (9 with Hotwire) | Django (8) | Any framework without mature audit tooling |
| Language | TypeScript (9) | Ruby (9, Rails path) | Python (8, Django path) | Dynamic-typed niche languages |
| Database | Postgres (10, with `NUMERIC` for money) | MySQL (7) | SQLite (5 for prod fintech) | MongoDB for ledger data |
| ORM | Drizzle (8) with hand-written migrations | Prisma (8) | SQLAlchemy (Python, 8) | ORMs that obscure transactions |
| Auth | WorkOS (10, enterprise) | Clerk (8) | Better Auth (8, non-enterprise) | Rolling auth for fintech |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind + custom (7) | Heavy animation libraries in transaction flows |
| Client state | TanStack Query (9) | Server Components (9) | SWR (7) | Optimistic updates on monetary ops without rollback |
| Hosting | AWS (8, with HIPAA-style controls if sensitive) | Vercel (8, check SOC 2 tier) | Render (7) | Consumer-tier hosting for transactional money |
| Observability | Datadog (9) | Sentry (9) + Honeycomb (9) | Grafana Cloud (7) | Under-logging for money events |
| Payments | Stripe (10) or Adyen (9) for enterprise | Paddle (8, MoR) | Polar (8, indie MoR) / Lemon Squeezy (6, acquired by Stripe) | Handling card data on own servers |
| Email | Postmark (9, compliance-oriented) | Resend (9) | AWS SES (7 with DKIM/SPF) | Bulk email providers for transactional |
| Background jobs | Inngest (9) | Temporal (9, complex workflows) | Sidekiq (8, Rails) | Unreliable queues for financial events |

**Domain-specific notes:**

- **The ledger is not an afterthought.** Adopt a double-entry pattern from day one, even if early screens only show "account balance." Retrofitting ledger semantics is the single most expensive fintech refactor.
- **Idempotency is mandatory.** Every write that touches money must have an idempotency key. Stripe's SDK handles this on the payment side; your own writes need the same discipline for transfers, refunds, and adjustments.
- **Reconciliation.** Build a "reconciliation dashboard" early, even if it just shows "total debits = total credits." Discovering a ledger imbalance six months in is a crisis; discovering it on day one is a bugfix.
- **Temporal** is a top pick for complex workflows (loan origination, KYC pipelines, multi-step payouts) when the team has the sophistication to wield it. Inngest covers 80% of fintech workflow needs with less ceremony.
- **Flip point for the Safe Default bundle**: when the team needs regulatory capabilities the SaaS providers don't offer (custodial flows, FINRA-regulated brokerage, EU MiCA-scoped crypto), a partner bank or BaaS provider (Unit, Treasury Prime, Modern Treasury, Alpaca) becomes the anchor of the stack.

---

## 5. Healthcare / Medical

**Archetype:** EHR-adjacent tools, patient portals, provider workflows, telehealth, health analytics. Examples: anything that touches PHI.

**Hard constraints:**
- HIPAA. Every managed service touching PHI must have a signed BAA.
- PHI access audit log from day one (who viewed what record, when).
- Encryption at rest and in transit; this is standard, but document it.
- Data residency may apply (state-specific, or international if international patients).
- Accessibility at Tier 1, not polish (ADA Title III applies).
- Backup and recovery plan with documented RPO/RTO.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Rails (9 with Hotwire) | Django (8) | Unmaintained frameworks |
| Language | TypeScript (9) | Ruby (9, Rails path) | Python (8, Django path) | Stacks with thin compliance libraries |
| Database | Postgres (10, self-hosted or on BAA-covered host) | MySQL (7) | (SQLite not for prod PHI) | MongoDB without BAA from provider |
| ORM | Drizzle (8) with hand-written migrations | Prisma (8) | SQLAlchemy (8) | ORMs that bypass the audit layer |
| Auth | WorkOS (10, with BAA) | Clerk (check current BAA tier) (7) | Self-hosted Keycloak (7) | Providers without a BAA |
| UI library | shadcn/ui + Radix (9, accessible primitives) | Mantine (8) | Tailwind + custom (7 with care) | UI kits with weak ARIA support |
| Client state | TanStack Query (9) | Server Components (9) | SWR (7) | Client-only architectures that leak PHI to logs |
| Hosting | AWS (9, HIPAA-eligible services with BAA) | GCP (9, same) | Azure (9, same) | Consumer-tier hosting without BAA |
| Observability | Sentry (9, with BAA and PHI scrubbing) | Datadog (9, with BAA) | Grafana Cloud (6 if no BAA) | Any observability without PHI redaction |
| Payments | Stripe (9, if telehealth or cash-pay) | Braintree (8) | Square (8) | Processors without healthcare experience |
| Email | Postmark (8, with BAA-equivalent) | Paubox (9, HIPAA-specialized) | AWS SES (8, with BAA) | Resend and similar without healthcare BAA check |
| Background jobs | Inngest (8, with BAA) | Temporal (9 if self-hosted) | Sidekiq (8, Rails) | SaaS job providers without BAA |

**Domain-specific notes:**

- **BAA is non-negotiable** for any vendor touching PHI. Verify the current state of each vendor's BAA offering during the session; do not rely on memory.
- **Audit log.** Every read and every write of PHI goes into an immutable audit log. This is a federal requirement, not a nice-to-have. Design the data layer with this in mind.
- **De-identification.** If a use case can be served by de-identified data (analytics, ML training), de-identify it per HIPAA Safe Harbor rules. The constraint set collapses dramatically.
- **Telehealth additions.** WebRTC, scheduling, prescription integration (Surescripts), clinical terminology (SNOMED, ICD-10), insurance (X12 transactions).
- **Flip point for the Safe Default bundle**: when the product becomes a full EHR (complete medical records, clinical decision support, ordering), stack choices become dominated by interoperability standards (FHIR, HL7, CDS Hooks) rather than general web stack concerns.

---

## 6. Education / LMS

**Archetype:** Course delivery, assignments, grading, student progress, learning analytics. Examples: Canvas, Moodle, Teachable, Kajabi, custom cohort-based courses.

**Hard constraints:**
- Accessibility at Tier 1, not Tier 3. DOJ and OCR actively enforce.
- FERPA (US K-12 and higher ed) governs student records.
- COPPA if under-13 users; additional restrictions on analytics and marketing tools.
- Video delivery at scale is typically its own infra decision (Mux, Cloudflare Stream).

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Rails (9 with Hotwire) | Django (8) | Frameworks with weak accessibility ecosystems |
| Language | TypeScript (9) | Ruby (9, Rails path) | Python (8) | Niche languages for K-12 procurement |
| Database | Postgres (10) | MySQL (8) | SQLite (6 for internal) | MongoDB for gradebook data |
| ORM | Drizzle (8) | Prisma (8) | ActiveRecord (8, Rails) | ORMs without clear migration stories |
| Auth | Clerk (8) | Better Auth (8) | django-allauth (8) | Auth providers without SSO for institutional buyers |
| UI library | Radix primitives + custom (9, accessibility-first) | shadcn/ui (9) | Mantine (8) | Libraries with weak screen reader support |
| Client state | TanStack Query (9) | Server Components (9) | SWR (7) | Over-clientified architectures on flaky school networks |
| Hosting | Vercel (8) | AWS (8) | Render (7) | Edge-only hosting for long assignment uploads |
| Observability | Sentry (9) | Datadog (8) | Grafana Cloud (7) | Session replay without FERPA/COPPA consent |
| Payments | Stripe (9, if paid courses) | Paddle (8, MoR) | Polar (8, low-fee MoR) / Lemon Squeezy (6, acquired by Stripe, absorbing into SMP) | Rolling your own tuition billing |
| Email | Postmark (9) | Resend (9) | SendGrid (7) | Marketing-first email for student notifications |
| Background jobs | Inngest (8) | Sidekiq (8, Rails) | BullMQ (7) | Long video processing in the web process |
| Video | Mux (9) | Cloudflare Stream (9) | YouTube unlisted (6, no control) | Self-hosting video at scale |

**Domain-specific notes:**

- **Accessibility is the Tier 1 gate.** WCAG AA is the defensible floor; many institutional buyers require it in contracts. Radix primitives and shadcn/ui start with accessibility built in, which is why they score 9. Custom-built components score lower unless the team has accessibility discipline.
- **Institutional SSO.** Higher ed buyers require SAML, often SCIM, sometimes LTI (Learning Tools Interoperability). WorkOS handles SAML/SCIM well; LTI is a specialized integration.
- **Video.** Mux is the current default for teams that want video-as-a-service. Cloudflare Stream is cheaper and improving. Self-hosting HLS with ffmpeg pipelines is a scale trap for a small team.
- **Flip point for the Safe Default bundle**: when the product moves into K-12 procurement, a wholly different bundle of compliance and ecosystem considerations applies (student info system integration, state-specific privacy laws, platform-neutral courseware formats like QTI and LTI).

---

## 7. CRM / Sales / Marketing

**Archetype:** Customer lifecycle tools: contact management, pipeline tracking, email campaigns, events, segmentation. Examples: HubSpot, Salesforce, Pipedrive, Apollo-style tools, Customer.io.

**Hard constraints:**
- Deduplication is table stakes; a CRM that creates duplicate contacts is broken.
- Event ingestion at scale (every email open, page view, click) requires an ingest pipeline.
- Contact and company data shapes evolve; JSON fields and typed custom fields both have places.
- Email compliance (CAN-SPAM, CASL, GDPR) shapes the email product.
- Integrations (calendar, email, Slack, Zapier-alike) are often the product.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Remix (8) | Rails (8 with Hotwire) | Any framework without good WebSocket support |
| Language | TypeScript (9) | Ruby (8, Rails path) | Python (8, Django path) | Weakly-typed for data-heavy CRM |
| Database | Postgres (10, with JSONB for custom fields) | MySQL (7) | SQLite (5 for prod CRM) | NoSQL when pipeline analytics matter |
| ORM | Drizzle (8) | Prisma (8) | ActiveRecord (8, Rails) | ORMs that fight JSONB |
| Auth | Clerk (9, with org/team features) | Better Auth (8) | WorkOS (9, enterprise) | Solo-user auth for multi-rep teams |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind UI (7) | Kits that restrict table/grid customization |
| Client state | TanStack Query (9) | Convex hooks (9 if Convex) | SWR (8) | Heavy client caches without invalidation plan |
| Hosting | Vercel (8) | Railway (8) | Fly.io (7) | DIY for analytics ingest at scale |
| Observability | Sentry (9) + PostHog (10, product analytics) | Segment + Datadog (8) | Plausible + Grafana (7) | Building your own analytics |
| Payments | Stripe (9, if seat-based CRM) | Paddle (8) | Polar (8, low-fee MoR) / Lemon Squeezy (6, acquired by Stripe, absorbing into SMP) | Complex per-contact pricing without a billing engine |
| Email | Resend (9) or Postmark (9) for transactional; Customer.io (9) or Loops (9) for marketing | SendGrid (7) | AWS SES (7 with care) | One provider for both transactional and marketing at scale |
| Background jobs | Inngest (9) | Trigger.dev (9) | BullMQ (7) | In-process background work for event ingest |

**Domain-specific notes:**

- **Two email pipelines.** Transactional (login, receipts, notifications) and marketing (campaigns, broadcasts). They have different deliverability needs and should use different providers. Mixing them hurts deliverability on both.
- **Event ingestion.** A growing CRM has a firehose of events (opens, clicks, visits, replies). ClickHouse or PostHog's event infra scores higher than Postgres for that pipeline past ~10M events/month. At smaller scale, Postgres with a partitioned events table is fine.
- **Custom fields.** JSONB in Postgres handles most cases. Strict typed custom fields require more schema work but win on reporting. Hybrid (typed core fields + JSONB extension) is the pragmatic default.
- **Flip point for the Safe Default bundle**: when the product crosses into marketing automation with visual workflow builders, multi-channel orchestration, and in-app product tours, the stack starts to look more like a platform than an app; queues and observability dominate.

---

## 8. Customer Support / Helpdesk

**Archetype:** Ticketing, inbox, knowledge base, chat, internal routing, SLAs. Examples: Zendesk, Intercom, Front, Freshdesk.

**Hard constraints:**
- Real-time updates (new tickets, replies, presence) are central; polling is a user-visible failure.
- SLA timers require accurate time math across business hours, holidays, and customer tiers.
- Email threading is hard (Message-IDs, References, subject lines); use a proven approach.
- Integrations are often the product (Salesforce, Stripe, internal tools).

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Phoenix LiveView (9 real-time) | Rails (8) | Frameworks without WebSocket maturity |
| Language | TypeScript (9) | Elixir (9, LiveView path) | Ruby (8) | Languages without good concurrency for WebSocket fanout |
| Database | Postgres (10) | MySQL (7) | SQLite (5 for prod) | MongoDB for relational ticket data |
| ORM | Drizzle (8) | Prisma (8) | Ecto (9 Elixir) | ORMs weak on concurrent writes |
| Auth | Clerk (9) | Better Auth (8) | WorkOS (9, enterprise) | Rolling auth for a multi-agent tool |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind + custom (7) | Kits without data-dense list components |
| Client state | TanStack Query (9) + WebSockets | Convex (9, real-time native) | Server Components + actions (8) | Polling-based updates |
| Real-time transport | WebSockets via framework (9) | Pusher (8) | Server-Sent Events (8) | Long polling |
| Hosting | Vercel (7, needs WebSocket-aware deploy) | Fly.io (9 for WebSocket workloads) | Railway (8) | Serverless-only for persistent connections |
| Observability | Sentry (9) + Honeycomb (9) for latency debugging | Datadog (8) | Grafana Cloud (7) | No tracing for real-time bugs |
| Email | Postmark (9, support-inbound pipeline) | SendGrid Inbound (7) | AWS SES (7) | Resend for inbound (outbound only) |
| Background jobs | Inngest (9) | Oban (9 Elixir) | BullMQ (8) | In-process for SLA timers |

**Domain-specific notes:**

- **Serverless + WebSockets is a trap.** Vercel and similar serverless-first platforms do not excel at long-lived connections. A hybrid (serverless app + managed Pusher/Ably/Liveblocks for real-time) works, or a persistent-process host (Fly.io, Railway, Render) for the WebSocket side.
- **Elixir + Phoenix LiveView** is a genuine 9/10 for helpdesk if the team has Elixir depth. Soft real-time is native; the concurrency model is a match.
- **Email inbound parsing.** Postmark, SendGrid Inbound Parse, or running your own IMAP ingest. Postmark's parse is the default for TypeScript teams.
- **Flip point for the Safe Default bundle**: when the product scales past ~100 agents and ~10k tickets/day, queue discipline and real-time fanout dominate the architecture; observability (Honeycomb or Datadog) moves from Tier 3 to Tier 2.

---

## 9. Marketplace / Two-sided

**Archetype:** Platforms connecting buyers and sellers, with listings, discovery, transactions, disputes, ratings. Examples: Airbnb, Etsy, DoorDash, Upwork, Turo.

**Hard constraints:**
- Split payments (buyer pays, platform takes fee, seller receives net). Usually Stripe Connect or Adyen marketplace.
- Trust and safety from day one (IDV, reviews, moderation) or platform fails to scale.
- Search and discovery is a first-class feature, not an afterthought.
- Dispute resolution and escrow are typically required for non-trivial marketplaces.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Remix (8) | Rails (8) | Frameworks weak on geo/search patterns |
| Language | TypeScript (9) | Ruby (8, Rails) | Python (8, Django) | Niche languages for marketplace scale |
| Database | Postgres (10) with PostGIS for geo | MySQL (7) | (SQLite not for prod) | MongoDB for transactional marketplace |
| ORM | Drizzle (8) | Prisma (8) | ActiveRecord (8) | ORMs weak on JSONB or geo |
| Auth | Clerk (9) + ID verification addon | WorkOS (9, enterprise) | Better Auth + standalone IDV (7) | Auth without IDV story |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Tailwind UI (7) | Kits that fight listing/grid layouts |
| Client state | TanStack Query (9) | Convex (8, if simple) | SWR (8) | Over-cached state on listing freshness |
| Hosting | Vercel (8) | Railway (8) | AWS (8, enterprise) | Edge-only for transactional workloads |
| Observability | Sentry (9) + PostHog (9) | Datadog (8) | Grafana Cloud (7) | No funnel analytics for marketplaces |
| Payments | Stripe Connect (10) | Adyen (9, enterprise) | Paddle (6, Connect-equivalent weaker) | Handling seller payouts yourself |
| Email | Postmark (9) | Resend (9) | SendGrid (7) | Treating buyer and seller comms identically |
| Background jobs | Inngest (9) | Temporal (9) | Trigger.dev (8) | Sync payout processing |
| Search | Algolia (9) | MeiliSearch (8) | Postgres FTS (7) | Grep-style search for large catalogs |

**Domain-specific notes:**

- **Stripe Connect is nearly unavoidable.** Adyen and similar enterprise processors are the alternative for teams outside Stripe's sweet spot, but for most marketplaces under $100M GMV, Connect is the path of least resistance.
- **Geo queries.** PostGIS (Postgres extension) handles "listings near me" elegantly up to significant scale. External geospatial services are usually premature.
- **Identity verification.** Persona, Stripe Identity, or Onfido. Buying IDV beats building it; the fraud surface is too big for a small team.
- **Flip point for the Safe Default bundle**: when GMV crosses a threshold where Stripe Connect fees become material (~$10M/year), enterprise processors (Adyen) start to look attractive; also when regulatory requirements (cross-border, money transmitter licenses) start to dominate.

---

## 10. AI / ML / LLM products

**Archetype:** Applications where LLMs, vector search, or traditional ML are product-facing features. Examples: AI assistants, copilots, chat UIs over domain data, RAG pipelines, eval tools.

**Hard constraints:**
- Streaming UX from day one; non-streaming LLM outputs feel broken.
- Eval pipeline before shipping; unevaluated prompts are unverified products.
- Cost observability; an LLM app without per-request cost tracking is a runaway bill.
- Prompt and model versioning; changing a prompt without versioning is an untracked deploy.
- Rate limits and abuse protection; every public LLM endpoint is a prompt-injection target.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) with Vercel AI SDK | Remix (8) | SvelteKit (8) | Frameworks without streaming primitives |
| Language | TypeScript (9) | Python (9 for ML-heavy backend) | Go (7) | Languages with thin LLM SDK support |
| Database | Postgres + pgvector (10) | Qdrant (8, dedicated vector DB) | Weaviate (7) | Standalone vector DB when Postgres can serve |
| ORM | Drizzle (9, pgvector-friendly) | Prisma (7, weaker vector support) | Raw SQL (8) | ORMs that hide the vector type |
| Auth | Clerk (9) | Better Auth (8) | WorkOS (9, enterprise) | Rolling auth while also building AI features |
| UI library | shadcn/ui + Radix (9) | assistant-ui (9, AI-specific) | Tailwind + custom (7) | Non-streaming-friendly components |
| Client state | Vercel AI SDK hooks (9) | TanStack Query (8) | SWR (7) | Custom WebSocket layers over existing LLM SDKs |
| Hosting | Vercel (9, Edge for streaming) | Cloudflare Workers AI (8) | Fly.io (8) | Long-cold-start serverless for chat |
| Observability | Helicone (9, LLM-specific) or LangSmith (9) + Sentry (9) | Datadog (8) | Axiom (8) | No LLM observability |
| Model providers | OpenAI (9) + Anthropic (10) + fallback (9) | Open models via Together AI or Bedrock (8) | Single-provider (risky) | Hard-coded single model with no fallback |
| Eval | Braintrust (9) | LangSmith (9) | Self-hosted rubric + Vitest (7) | No eval |
| Email | Resend (9) | Postmark (9) | SendGrid (7) | N/A if no email |
| Background jobs | Inngest (9, great for LLM chains) | Trigger.dev (9) | BullMQ (7) | Sync LLM chains in request path |

**Domain-specific notes:**

- **Multi-provider fallback.** OpenAI, Anthropic, Gemini, and open models each have outage windows. Build a fallback from day one. Vercel AI SDK and the various SDK wrappers make this tractable.
- **pgvector first.** Unless you have >100M vectors or very high QPS, Postgres with pgvector beats a separate vector DB on operational cost.
- **Evals are a Tier 1 concern.** Shipping a prompt without a rubric is shipping unverified code. Tools: Braintrust, LangSmith, or a custom Vitest rig. The choice is less important than having the loop.
- **Cost observability.** Helicone and Langfuse are the current leaders. Without it, a prompt change that doubles token usage can run for weeks before anyone notices.
- **Flip point for the Safe Default bundle**: when the product shifts from "LLM feature inside an app" to "LLM is the app" (AI-native from the ground up), the stack's center of gravity moves to eval, model router, and streaming infra; traditional dimensions (UI, auth) matter less.

---

## 11. Analytics / BI / Dashboards

**Archetype:** User-facing or team-facing analytics over domain data: reporting dashboards, BI tools, embedded analytics in other products. Examples: Looker, Metabase, Mode, embedded Explo/Cube.

**Hard constraints:**
- Query flexibility (ad-hoc SQL, semantic layer, saved reports).
- Data freshness SLA (live, 5-min delayed, hourly, daily).
- Cost per query; an analytics product with a runaway query is a bill-shock source.
- Embed story if B2B (iframe with SSO, React component, or JWT-signed URL).

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Remix (8) | Streamlit (7, internal only) | Raw SPA without SSR for embed |
| Language | TypeScript (9) | Python (9 data-backend) | SQL (as a concept) | Niche languages for data joins |
| Database | ClickHouse (10, OLAP) | Postgres (8, OLTP+simple OLAP) | DuckDB (9, embedded analytics) | OLTP-only DB for a BI product at scale |
| ORM | Drizzle (8) for OLTP; raw SQL (10) for OLAP | Prisma (6, OLAP weakness) | Raw SQL (9) | ORMs that pretend OLAP is OLTP |
| Auth | Clerk (8) | WorkOS (9, enterprise embed) | Better Auth (7) | Auth without JWT-signed embed support |
| UI library | shadcn/ui + Radix (9) | Tremor (9, dashboard-specific) | Mantine (8) | Heavy UI kits that fight dense data display |
| Charts | Recharts (8) / visx (9) / ECharts (9) | Nivo (8) | Chart.js (7) | Building charts from scratch |
| Client state | TanStack Query (9) | Server Components (9) | SWR (7) | Over-cached dashboards with stale data |
| Hosting | Vercel (8) + ClickHouse Cloud (9) | AWS (8) | Render + DuckDB (7) | Self-hosted Clickhouse for small team |
| Observability | Datadog (9, useful for query tracing) | Sentry (9) | Grafana Cloud (7) | No slow-query visibility |
| Query layer | Cube (9, semantic layer) | dbt + custom API (8) | Raw SQL (7) | No semantic layer at scale |
| Background jobs | Inngest (8) | Trigger.dev (8) | BullMQ (7) | Synchronous report generation |

**Domain-specific notes:**

- **OLTP vs. OLAP.** Dashboards querying operational data should typically hit a replica or a separately-scoped read path. Running heavy aggregations on the primary Postgres can starve writes.
- **ClickHouse for aggregations.** When analytical queries start to dominate (million-row scans, group-bys over time), ClickHouse scores a 10. For OLTP-adjacent analytics (small scale, simple queries), Postgres is fine.
- **Semantic layer.** Cube (and dbt as the ETL layer) let you define metrics once and reuse them across dashboards. Without it, every dashboard reinvents "what does active user mean" and the definitions diverge.
- **Embedded analytics.** If you're embedding dashboards in other products, budget for auth (JWT-signed URLs), theming, and iframe UX. Metabase and Looker have mature embed stories; a custom build is weeks of work.
- **Flip point for the Safe Default bundle**: when query volume hits sustained >100/s with non-trivial complexity, OLAP infrastructure (ClickHouse, Snowflake, BigQuery) becomes the anchor, and the app stack becomes a thin UI over that.

---

## 12. Internal Tools / Back-office

**Archetype:** Admin panels, ops consoles, internal CRUD tools for a team of employees, not customers. Examples: Retool-adjacent admin panels, ops tooling, internal moderation consoles.

**Hard constraints:**
- Speed to ship is the dominant constraint; building this is overhead.
- Operates on production data; destructive actions need confirmations and audit.
- Used by a small, known set of users; auth is enterprise SSO, not consumer.
- Often the team's "second" app; budget for stack simplicity.

**Top picks:**

| Dimension | Top pick | Runner-up | Budget | Avoid |
|---|---|---|---|---|
| Framework | Next.js (9) | Retool/Internal tools (9 low-code) | Django Admin (9 out-of-box) | Building this with React from scratch if low-code fits |
| Language | TypeScript (9) | Python (8, Django) | (no code, if Retool) | Complex stacks for simple CRUD |
| Database | (reuse existing) | Postgres (if greenfield, 10) | MySQL (8) | Adding a second DB just for admin |
| ORM | (reuse existing) | Drizzle / Prisma / ActiveRecord (8) | Raw SQL (8) | Introducing a new ORM |
| Auth | Existing company SSO via WorkOS (10) | Clerk (9) | Better Auth (8) | Rolling consumer-style auth for employees |
| UI library | shadcn/ui + Radix (9) | Mantine (8) | Django admin theme (8) | Consumer-polished kits for internal use |
| Client state | TanStack Query (9) | Server Components (9) | SWR (7) | Over-engineered state for simple forms |
| Hosting | Vercel (9) | Internal Kubernetes (7 ops burden) | Render (8) | Consumer-scale hosting for 20 employees |
| Observability | Sentry (9) | Grafana Cloud (7) | console.log (6 if small) | No observability on an ops tool |
| Payments | N/A | N/A | N/A | Don't add payments to an internal tool |
| Email | Postmark (9) | Resend (9) | SMTP (7) | Marketing email providers for internal alerts |
| Background jobs | Inngest (8) | BullMQ (7) | Cron (7) | Over-engineered workflow for simple batch jobs |

**Domain-specific notes:**

- **Low-code is often the right answer.** Retool, Internal, Tooljet, Appsmith. If the tool is truly internal and the primary driver is speed, a low-code option can be the correct 9/10 pick, with "switching cost is high if the tool outgrows low-code" as the flip point.
- **Django Admin (for Django apps) and Rails Admin** are near-zero-config and hard to beat for straightforward CRUD internal tools on top of an existing stack.
- **Security posture.** Internal tools often have higher data access than customer-facing apps (superuser impersonation, cross-tenant views). Audit every access; treat the tool like production even when the user base is 10 employees.
- **Flip point for the Safe Default bundle**: when the internal tool grows into a customer-facing product (happens quietly, over months), the stack has to be reassessed against the new domain; do not let an internal tool drift into production without a re-pick.

---

## Cross-domain patterns

Observations that recur across all 12 domains.

### Postgres wins more often than not

Across these 12 domains, Postgres is the top pick in 10 and a runner-up in the other 2 (ClickHouse for analytics, Convex for fast-to-ship simple SaaS). Postgres is the safe default not because it's trendy but because it scales from prototype to hundreds of thousands of users without a rewrite, and because its ecosystem (pgvector, PostGIS, JSONB, full-text search) covers adjacent needs.

### Next.js is the frontend default but not the only path

In the TypeScript world, Next.js scores 9 across most of these domains. Remix, SvelteKit, and Nuxt are legitimate 7-8 alternatives; Astro wins for content-heavy. Outside TypeScript, Rails with Hotwire is a 9 in several domains, Django an 8. A skilled team on Phoenix LiveView can score a 9 in real-time domains.

### Auth picks have been shifting

Better Auth, Clerk, and WorkOS have displaced Auth.js and earlier BaaS auth options as the top picks for new TypeScript projects. The right one depends on compliance posture (WorkOS for enterprise), polished UI need (Clerk), or self-host + control (Better Auth).

### Serverless has a real ceiling for some domains

Customer support, marketplace transaction orchestration, and real-time domains benefit from persistent-process hosting (Fly.io, Railway, Render) or hybrid architectures. Blindly recommending Vercel for every domain misses where the workload doesn't fit.

### Cost blows up at the edges

Vercel bill shock, Clerk MAU pricing, Firebase read/write egress, and Datadog host pricing all show up in month 6-18. Price at the 12-month scale, not today.

### Ecosystem churn is higher in AI/ML and identity

Both spaces have seen 2-3 shifts in top picks in the last 18 months. The staleness check (Step 9) matters more here.
