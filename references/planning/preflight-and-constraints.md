# Preflight and Constraints

The Step 1 and Step 2 protocol. Six questions that separate "what the user says they want" from "what the stack must actually satisfy."

**Scope owned by this file:** the 6 pre-flight questions, default-assumption rules when the user doesn't answer, and the conversion of answers into hard constraints vs. weighted preferences. Scoring weights and candidate matching live in `scoring-framework.md` and `domain-stacks.md`.

## The 6 pre-flight questions

Every session answers these in writing, either from user input or stated assumption.

### 1. Domain

> What real-world job does this stack serve?

Map to one of the 12 domain profiles in `domain-stacks.md`:

1. SaaS / Multi-tenant
2. E-commerce / Retail
3. CMS / Content / Blog
4. Fintech / Financial
5. Healthcare / Medical
6. Education / LMS
7. CRM / Sales / Marketing
8. Customer Support / Helpdesk
9. Marketplace / Two-sided
10. AI / ML / LLM products
11. Analytics / BI / Dashboards
12. Internal Tools / Back-office

If the project spans multiple domains (e.g., a SaaS that includes a marketplace layer, or a fintech with heavy AI features), pick the dominant one for the Safe Default bundle and note the secondary domain for cross-reference. Bundles are optimized per domain; split-domain projects usually want the primary bundle with a surgical override for the secondary (e.g., "SaaS bundle, but Stripe Connect for the marketplace layer").

**If the user says nothing:** infer from context. A phrase like "dashboard for my SaaS" -> SaaS. "Inventory tool for my store" -> E-commerce. "Internal ops tool for our team" -> Internal Tools. State the inference.

### 2. Team

> How many engineers? What's their language depth? Who is on call when it breaks?

What matters:

- **Team size.** Solo, 2-5, 6-15, 16+. Each cohort has a different complexity ceiling.
- **Existing language depth.** "We're a Python shop with no JS" is a hard constraint on some bundles. "Team has deep TypeScript and light Python" shapes defaults.
- **On-call story.** Is there a dedicated SRE, a rotating on-call, or is the primary engineer the on-call? This shapes the self-host-vs.-managed axis more than any other input.
- **Hiring plan.** Are you hiring in 3 months? For what skill set? Picking a stack in a tiny niche language (Crystal, Zig, early-career Gleam) is fine for a solo founder and bad for a team planning to hire.

**If the user says nothing:** assume team of 2-5, moderate TypeScript depth, rotating-or-no on-call. State the assumption.

### 3. Budget posture

> Free-tier scrappy, cash-efficient growth, or enterprise-indifferent-to-cost?

These are postures, not dollar amounts. A startup spending $1k/month on dev tools is "cash-efficient" if they're pre-revenue; an enterprise spending $1k/month is "scrappy." The number alone means nothing.

**Three postures:**

| Posture | Characterization | Implications |
|---|---|---|
| **Free-tier scrappy** | Zero paid services month 1, anything paid is justified line-by-line | Supabase/Firebase free tier, Vercel Hobby, Cloudflare free, Sentry free, self-hosted alternatives preferred where free |
| **Cash-efficient growth** | Pay for the things that return more than they cost; comfortable with $50-$500/month/tool at reasonable scale | Vercel Pro, Clerk paid, Resend paid, Sentry Team, Datadog or self-hosted Grafana depending on team size |
| **Enterprise-indifferent** | Cost is real but subordinate to capability, compliance, and time-to-ship; annual contracts are normal | WorkOS, Datadog, AWS with reserved capacity, enterprise tiers across the board, procurement-ready vendors |

**If the user says nothing:** default to "cash-efficient growth." State the default.

**Traps to name up front:**
- The **free-tier cliff**: "free until you need auth" is not free. Identify at what point each tool flips from free to paid for this specific use case.
- **Seat pricing**: a tool at $12/user/month gets real at 20 users. Price it at the 12-month team size, not today's team size.
- **Egress pricing**: a CDN or object store that looks free has an egress bill that shows up around 10TB/month. Name it for file-heavy apps.
- **Per-MAU pricing**: auth providers and analytics tools often flip from free to painful at 5k-10k MAU. Price at the 12-month user projection.

### 4. Time-to-ship

> Days, weeks, months, or no hard deadline?

What matters is the shape of the deadline:

| Window | Implication |
|---|---|
| **Days (demo, hackathon, fundraise)** | Maximum BaaS leverage. Fast-to-Ship bundle. Accept a worse scale ceiling for velocity. |
| **Weeks (MVP, pilot, paid POC)** | Safe Default bundle. Don't over-optimize for scale the team won't see. |
| **Months (funded startup, internal project)** | Safe Default bundle at minimum, Enterprise bundle if compliance is in scope. |
| **No hard deadline (personal, learning, side project)** | Fit the user's learning goals and ergonomic preferences. Scoring weights shift toward DX and ecosystem depth. |

**If the user says nothing:** assume weeks. State the assumption. Long-window projects should explicitly say "no deadline" since the default pushes toward shippability.

### 5. Scale ceiling (12 months, honest)

> What's the realistic traffic and data volume in 12 months?

The single most-lied-about pre-flight answer. Engineers routinely claim "Google-scale" and build for 10k users. Push for honest numbers.

Useful anchors:

| Cohort | Typical 12-month numbers | Stack implication |
|---|---|---|
| **Pre-launch / beta** | <100 DAU, <10GB data | Anything works. BaaS is fine. SQLite is fine. |
| **Early-stage B2B SaaS** | 500-5,000 DAU, 10-100GB data, <100 req/s p95 | Postgres + managed host + simple stack is fine. |
| **Growth-stage B2B** | 5k-50k DAU, 100GB-1TB, 100-1,000 req/s | Postgres + read replica, CDN, queue discipline, basic observability. |
| **Growth-stage B2C** | 50k-1M DAU, 1-10TB, 1k-10k req/s | Postgres + read replicas + cache layer, queue-centric architecture, real observability. |
| **Hyperscale** | 10M+ DAU, 100TB+, 10k+ req/s | Custom. This skill does not try to solve hyperscale; it ensures you don't solve pre-launch as if it were hyperscale. |

**If the user says nothing:** assume early-stage. State the assumption and flag that the recommendation should be re-run if the numbers are off by 10x.

**Pushback triggers.** If the user claims hyperscale numbers for a month-one project with no customers, ask once: "What's the actual 12-month number?" and score against that. Do not score against aspirational numbers.

### 6. Regulatory and data-residency constraints

> HIPAA? PCI-DSS? SOC 2? GDPR? EU data residency? FedRAMP? State privacy laws (CCPA, VCDPA, CPA)? Industry-specific (FINRA, FERPA, COPPA)?

Silence is not an answer. Ask explicitly if the domain is in healthcare, finance, education, government, or anything with children's data, and the user hasn't named constraints.

Each constraint is a hard filter in Step 2. Convert them to candidate rejections:

| Constraint | Rules out |
|---|---|
| **HIPAA (PHI)** | Managed services that don't sign a BAA; default tiers of Vercel, Supabase (check current BAA availability and tier), Convex (check current BAA status), Firebase without GCP HIPAA offering |
| **PCI-DSS (card data)** | Hosting card data on your own infrastructure at any non-trivial volume; Stripe's SAQ-A tokenized flow is the default, not a constraint |
| **SOC 2 Type II** | Vendors with no SOC 2 report; note that SOC 2 is a vendor claim, not a technical constraint, so it affects procurement more than code |
| **GDPR** | Vendors with no DPA, no data processing agreement, or no mechanism for data deletion requests |
| **EU data residency** | US-only regions for DB, hosting, logs; a Vercel deployment routing to US-only Lambda is a violation even if the app is EU-targeted |
| **UK data residency** (post-Brexit) | Similar to EU but with UK-specific nuances; Iceland/Switzerland are often acceptable EU adjacencies |
| **FedRAMP (US federal)** | Most commercial SaaS; requires a FedRAMP Moderate or High authorized hosting path (AWS GovCloud, Azure Gov, GCP Gov) |
| **CJIS (US criminal justice)** | Non-CJIS-compliant hosting; very narrow vendor list |
| **FERPA (US education)** | Managed services without FERPA-aligned agreements; affects some BaaS choices |
| **COPPA (US under-13)** | Any analytics or marketing tool that doesn't have a COPPA-compliant mode |
| **CCPA / state privacy laws** | Less restrictive than GDPR technically, more a procurement concern |
| **Industry compliance (FINRA, HITRUST, ISO 27001)** | Check vendor certifications; usually narrower vendor pools |

**If the user says nothing:** ask explicitly for regulated domains (healthcare, finance, education, government, children's data). For other domains, default to "no named compliance constraints" and state it.

### 7. Reversibility posture

> Is this decision you can change in ~4 weeks if wrong, or is it foundational for 3+ years?

Borrowed from Dan McKinley's "innovation tokens" framing and evidence from migration postmortems: the same score on two dimensions can have 10x different real-world cost depending on reversibility. A DB pick is rarely reversible in under six months; a UI library swap is often 2-4 weeks; an observability vendor swap is a weekend.

**Three postures:**

| Posture | Characterization | Scoring implication |
|---|---|---|
| **Exploratory (reversible in weeks)** | "This is a validation build; we can rip and replace." | Weight DX and time-to-ship heavily; weight exit-cost lightly. A 2/10 on exit cost is acceptable if DX is a 10/10. |
| **Committed (reversible in 3-6 months with effort)** | "This is the serious build; we can migrate later but would prefer not to." | Default weighting. Exit cost matters; weight it at the published default. |
| **Foundational (3+ year horizon, multi-engineer-month rewrite to reverse)** | "This decision outlives the current team; a rewrite would be a multi-quarter project." | Weight exit cost, compliance, ecosystem depth, and bus factor heavily. Reduce DX and cost weights. Most database, auth, payment, and primary-framework picks are foundational. |

**If the user says nothing:** default to Committed. State it.

**Dimension-specific reversibility defaults** (use these to pre-fill the picture even if the user answers only in aggregate):

| Dimension | Typical reversibility |
|---|---|
| Database | Foundational (6-24 months to switch for a non-trivial app) |
| ORM | Committed (2-12 weeks depending on app size) |
| Auth provider | Committed (1-8 weeks, user-visible cutover) |
| Primary framework | Foundational (rewrite-level work) |
| UI library | Committed (2-12 weeks for leaf swap; longer for heavy custom) |
| Hosting platform | Committed (1-6 weeks for most setups) |
| Observability | Exploratory (weekend to weeks) |
| Email provider | Exploratory (1-2 weeks, mostly DNS) |
| Payments | Foundational for the primary processor; committed for MoR layering |
| Background jobs | Committed (2-8 weeks for non-trivial pipelines) |

The foundational picks get the scoring rigor; exploratory picks can skip the full pass (see `scoring-framework.md` § "When to skip the scoring pass entirely").

## From answers to the constraint map

The constraint map converts pre-flight answers into two buckets.

### Bucket 1: hard constraints (rule out candidates)

A candidate that violates a hard constraint is dropped in Step 3, before scoring. Do not "score around" a hard constraint; it is not a preference.

Examples:

| Hard constraint | Rule |
|---|---|
| HIPAA with PHI in the data layer | Drop managed DBs without BAA at the tier the team can afford |
| Team is Python-only, no JS headcount, no budget to hire | Drop Node-centric fullstack frameworks; Django/FastAPI bundles only |
| EU data residency | Drop Vercel Hobby, drop US-only-region managed DBs, require EU regions across the stack |
| Must be self-hostable | Drop Vercel-only, drop Clerk-only (Clerk has no self-host), drop Convex (fully managed) |
| Must work offline (field, maritime, remote sites) | Drop network-always BaaS; require local-first data layer |
| Team is 2 engineers, no dedicated ops | Drop self-host-on-Kubernetes patterns; managed services only |
| SLA commitment of 99.95% | Drop single-region hobby tiers; require multi-region or documented failover |
| Zero paid services month 1 | Drop paid-only tools; require free-tier alternatives |
| Budget cap of $X/month at 1,000 MAU | Price the stack at that MAU and drop anything over |

### Bucket 2: weighted preferences (score candidates)

A preference does not rule out a candidate; it weights the scoring. These are the user's dials. See `scoring-framework.md` for default weights and override mechanics.

Examples:

| Preference | Effect on scoring |
|---|---|
| "I care about developer experience" | DX weight +30%; ergonomic frameworks score higher |
| "I care about cost" | Cost weight +30%; self-host and free-tier options score higher |
| "I care about maturity" | Ecosystem/maturity weight +30%; younger libraries score lower even if technically better |
| "I want to learn X" | Add X to dimension scoring as a user preference; note that scoring is no longer neutral |
| "We have existing skill in Y" | Weight Y's dimension score +20%; reduces switching-cost drag |
| "Team loves / hates Z" | Score Z up or down by one grade; reflect the team's aesthetic without pretending it's neutral |

## Defaults (when the user doesn't answer)

If a question is unanswered, state the assumption and proceed. Never interrogate.

| Question | Default |
|---|---|
| Domain | Infer from project description; if unclear, ask once, pick closest if still unclear |
| Team | 2-5 engineers, moderate TypeScript depth, rotating or no on-call |
| Budget posture | Cash-efficient growth |
| Time-to-ship | Weeks |
| Scale ceiling | Early-stage (5k DAU, 100GB, <100 req/s at 12 months) |
| Regulatory constraints | None stated; ask explicitly if the domain is regulated |

State the defaults in the pre-flight output so the user can redirect before scoring begins.

## Constraint-to-stack implication cheatsheet

Common constraints and the stack implications they carry. Use as a fast-path when building the constraint map.

### Compliance

- **HIPAA.** Requires BAA with every managed service that touches PHI. At time of writing, this affects: choice of DB host, logging destination, email provider (if PHI in emails), support tooling (if PHI visible to support). Self-hosting is allowed but doesn't eliminate the audit. Verify current BAA coverage on vendor site before scoring.
- **PCI-DSS.** If using Stripe's tokenized flow (card data never touches your server), you fall under SAQ-A and PCI is mostly a procurement checkbox. If you handle card numbers on your server, scope explodes; do not recommend this path for a small team.
- **SOC 2 Type II.** The vendors you pick need SOC 2 reports; your own SOC 2 becomes an audit of your processes, not a technical constraint. Shortlist vendors with documented SOC 2.
- **GDPR.** DPAs across the stack, data deletion plumbing, data residency clauses. Affects choice of analytics, logging, email, and anything that touches user data.

### Data residency

- **EU residency.** DB in EU region, logs in EU region, CDN that respects EU-only routing, hosting in EU region. The whole stack must be EU-aware. A Vercel-standard deployment is US by default; you need Pro tier or higher to pin region, and even then verify.
- **UK residency post-Brexit.** Most EU-compliant vendors are UK-compliant, but verify. Some UK government contracts require UK-sovereign hosting.
- **India, Russia, China.** Local data residency laws; rarely addressed by US-centric BaaS. Typically requires regional deployment partners.

### Self-host requirements

- **Security posture.** "We can't have customer data on third-party servers" is a hard constraint. Rules out BaaS, managed DB for sensitive data, and most observability SaaS.
- **Portability.** "We need to be able to exit in 30 days" is less strict than self-host; it rules out services with no equivalent migration target (e.g., proprietary query languages, vendor-locked identity models).
- **Sovereign cloud.** Government contracts may require AWS GovCloud, Azure Gov, or specific regional clouds. Rules out most commercial SaaS.

### Team composition

- **Python-only team, no JS headcount.** Django or FastAPI bundles only; Next.js/Remix are out. If the team is willing to learn JS for the frontend, a Django API + Next.js frontend is viable but priced in hiring or learning time.
- **Ruby / Rails shop.** Rails + Hotwire/Turbo is the Safe Default; mixing in JS frameworks without reason adds complexity.
- **No TypeScript tolerance.** Ruby, Python, Elixir, Go, or Rails paths. JS-centric stacks are out.
- **Aggressive hiring plan.** Niche languages (Elixir, Gleam, Roc) score lower on hireability; TypeScript, Python, Ruby, and Go score higher.

### Ops maturity

- **Solo founder, no dedicated ops.** Managed everything. Self-host is a scale ceiling trap.
- **2-5 engineers, no SRE.** Managed services for DB, queue, logs. Self-host only for things that are genuinely low-burden (static assets, small side services).
- **Dedicated SRE or platform team.** Self-host becomes viable. Cost savings and control justify the ops burden.
- **10+ engineers, multi-team.** Platform decisions become product decisions; internal tooling investment is worth it.

## Common anti-patterns in the pre-flight phase

- **Interrogating the user.** Six questions max. If they don't answer, assume defaults and state them.
- **Accepting aspirational scale numbers.** If a pre-launch project claims 1M DAU in month 12, score against 50k DAU and note the discrepancy.
- **Ignoring compliance silence.** In regulated domains, ask explicitly. Silence is not safety; it is a future incident.
- **Letting preferences override constraints.** "I want to use X" doesn't override "HIPAA requires a BAA that X doesn't have."
- **Treating every preference as a hard constraint.** "I prefer Drizzle" is a weighted preference, not a filter. Drop candidates on actual constraints, weight them on preferences.
- **Forgetting to price the stack at the 12-month team and MAU.** Today's pricing is not tomorrow's pricing.
