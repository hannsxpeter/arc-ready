# Domain Considerations

This router indexes the inherited domain-specific landmines for 33 common product profiles and the added v1.1 profiles. The generic dashboard discipline — auth, RBAC, CRUD, vertical slices, states, validation — applies identically to all of them. What differs is the 20% of domain-specific knowledge that, if missed, causes a rewrite, a compliance violation, or a broken product.

**How to use this file:** During pre-flight (question #1: "who uses this, for what job?"), identify which domain archetype matches. Read that section before designing the schema or writing the first migration. The gotchas listed here are things that generic CRUD misses — they're the landmines, not the full terrain.

If the dashboard spans multiple domains (e.g., a SaaS that includes billing, which is SaaS plus Financial), read both sections.

## Tier remap for regulated domains

The default tier ladder (Foundation, Functional, Polished, Hardened) assumes an internal tool where accessibility and audit are "ready for beta" concerns. In regulated domains, some Tier 3 items are Tier 1 legal obligations. When the pre-flight identifies one of the following domains, remap the tier requirements accordingly before starting Step 4.

| Domain | Requirement that moves to Tier 1 | Legal / compliance anchor |
|---|---|---|
| Healthcare / Medical | Accessibility (req #17) plus Audit log (req #16) | ADA Title III plus HIPAA §164.312(b) require PHI access logs from day one |
| US Government / Public Sector | Accessibility (req #17) | Section 508 is a federal procurement gate |
| EU Public Sector | Accessibility (req #17) | EN 301 549 and EAA 2025 obligations |
| Education / LMS | Accessibility (req #17) | DOJ and OCR lawsuits routinely target inaccessible LMS features |
| Financial / Fintech | Audit log (req #16) | SOX, PCI-DSS, MiCA record-keeping |
| Legal / Law Firm | Audit log (req #16) | Client confidentiality plus malpractice evidentiary trail |
| HR / Payroll | Audit log (req #16) | SOC 2 plus wage-and-hour disputes |
| Gaming with minors | Audit log (req #16) | COPPA and GDPR-K |
| Cybersecurity / SOC | Audit log (req #16) | Forensic integrity is the product |

**How this changes the build.** When Tier 1 is declared complete, the remapped items must be satisfied, not deferred. Accessibility at Tier 1 means: keyboard-reachable shell, visible focus styles, semantic HTML, and an axe pass on the landing plus first CRUD page. Audit log at Tier 1 means: the append-only table exists, every mutation writes to it, and an admin can view it, even if pretty filtering waits for Tier 3.

**Architecture note requirement.** State the remap explicitly: "Regulated domain: [name]. Tier 1 also includes [requirements]." Without the explicit statement, the remap doesn't bind and the agent will default back to the unrestricted tier ladder.

**Seed-data compliance.** In these regulated domains, do not seed with real-shaped sensitive data. Use synthetic fixtures that are realistic in structure (name formats, ID formats, temporal distributions) but carry no personally identifying content. For healthcare specifically, never seed with real MRNs, real claim numbers, or realistic DOBs paired with realistic names. Synthetic tooling: Faker (general), synthea (healthcare), generatedata.com (bulk).

## Top gotchas by frequency

These are the domain-specific mistakes that cause the most rewrites. Check before your first migration:

```
Domain                     #1 gotcha that generic CRUD misses
──────────────────────────────────────────────────────────────────────────
SaaS / Multi-tenant        Missing WHERE org_id = ? on every query (data leak)
E-commerce                 Price as a single float (should be integer cents + multi-price)
Financial / Accounting     Single-entry bookkeeping (must be double-entry, append-only)
Healthcare                 Missing HIPAA audit log of every PHI access
CMS / Content              Body as one text blob (must be structured fields + revisions)
Education / LMS            Grade as a percentage (must handle weighted categories + drops)
Legal                      Time as hours (must be 0.1-hour increments for billing)
Restaurant / POS           Menu item as a flat row (must handle modifiers/customizations)
Marketplace                No escrow/hold for payments (direct transfer = disputes)
IoT / Devices              Polling for status (must handle offline as first-class state)
HR / Payroll               Salary as annual number (must handle pay periods + tax brackets)
Real Estate                Lease as start+end dates (must handle renewals + deposit ledger)
Logistics                  Shipment as one status (must be state machine with parallel paths)
```

Each linked domain profile has the full gotcha list, compliance requirements, expected UX, and seed data shape. Read the matching section before designing your schema.

---

## Domain profile router

Select project form first in `references/building/product-form-router.md`, then compose product archetype, industry overlay, and regulatory overlay through `references/building/domain-registry.md`. Load only the linked profiles that apply.

| ID | Profile | Direct reference |
|---|---|---|
| 1 | SaaS / Multi-tenant | [profile](domains/domain-saas-multitenant.md) |
| 2 | E-commerce / Retail | [profile](domains/domain-ecommerce-retail.md) |
| 3 | CMS / Content / Blog | [profile](domains/domain-cms-content.md) |
| 4 | Financial / Fintech / Accounting | [profile](domains/domain-financial-fintech-accounting.md) |
| 5 | Healthcare / Medical | [profile](domains/domain-healthcare-medical.md) |
| 6 | Education / EdTech / LMS | [profile](domains/domain-education-lms.md) |
| 7 | Travel / Hospitality / Booking | [profile](domains/domain-travel-booking.md) |
| 8 | Sports / Fitness | [profile](domains/domain-sports-fitness.md) |
| 9 | Real Estate / Property Management | [profile](domains/domain-real-estate-property.md) |
| 10 | Logistics / Supply Chain / Fleet | [profile](domains/domain-logistics-fleet.md) |
| 11 | HR / People / Payroll | [profile](domains/domain-hr-payroll.md) |
| 12 | Project Management / Collaboration | [profile](domains/domain-project-management.md) |
| 13 | Customer Support / Helpdesk | [profile](domains/domain-customer-support.md) |
| 14 | Marketing / CRM / Sales | [profile](domains/domain-marketing-crm-sales.md) |
| 15 | IoT / Device Management | [profile](domains/domain-iot-device-management.md) |
| 16 | Restaurant / Food Service | [profile](domains/domain-restaurant-food-service.md) |
| 17 | Legal / Law Firm | [profile](domains/domain-legal-law-firm.md) |
| 18 | Non-profit / Fundraising | [profile](domains/domain-nonprofit-fundraising.md) |
| 19 | Media / Streaming | [profile](domains/domain-media-streaming.md) |
| 20 | Agriculture / Farm Management | [profile](domains/domain-agriculture-farm.md) |
| 21 | AI / ML / Chat | [profile](domains/domain-ai-ml-chat.md) |
| 22 | Entertainment / Events | [profile](domains/domain-entertainment-events.md) |
| 23 | Gaming / Esports | [profile](domains/domain-gaming-esports.md) |
| 24 | Cybersecurity / SOC | [profile](domains/domain-cybersecurity-soc.md) |
| 25 | Construction / Field Services | [profile](domains/domain-construction-field-services.md) |
| 26 | Marketplace / Platform | [profile](domains/domain-marketplace-platform.md) |
| 27 | Insurance / InsurTech | [profile](domains/domain-insurance-insurtech.md) |
| 28 | Telecommunications / ISP | [profile](domains/domain-telecommunications-isp.md) |
| 29 | Energy / Utilities | [profile](domains/domain-energy-utilities.md) |
| 30 | Government / Public Sector | [profile](domains/domain-government-public-sector.md) |
| 31 | Recruiting / ATS (Applicant Tracking) | [profile](domains/domain-recruiting-ats.md) |
| 32 | Co-working Space / Shared Office | [profile](domains/domain-coworking-space.md) |
| 33 | Workflow Automation / Integration Platform | [profile](domains/domain-workflow-automation.md) |
| 34 | Data / Analytics / BI | [profile](domains/domain-data-analytics-bi.md) |
| 35 | Manufacturing / MES / Industrial Operations | [profile](domains/domain-manufacturing-mes.md) |
| 36 | Developer Platform / API / SDK | [profile](domains/domain-developer-platform.md) |
| 37 | Research / Lab / LIMS | [profile](domains/domain-research-lab-lims.md) |

## How to interpret a vague request

Users rarely say "build me an admin panel with RBAC, audit logs, settings, user management, and a billing module." They say "I need a dashboard for my X." Pick the closest archetype below, then read the matching section earlier in this file during pre-flight.

- **"Dashboard for my SaaS"** → multi-tenant admin: users, organizations, billing, usage, settings, audit
- **"Internal tool for my team"** → CRUD on the team's domain entities, with simple shared auth, lighter RBAC
- **"Analytics dashboard"** → KPI cards + 4–6 charts + a filter bar + exports; auth optional but recommended
- **"Operational dashboard" / "control panel"** → real-time data, health indicators, action buttons (restart, deploy, ack), audit
- **"Customer portal"** → end-user-facing: their data only, billing/subscription, support, settings
- **"Reporting dashboard"** → tables-heavy, scheduled reports, exports to CSV/PDF, filters, drill-down
- **"CMS" / "blog admin"** → content types, draft/publish workflow, media management, SEO, versioning
- **"E-commerce admin" / "store manager"** → products/variants, orders, inventory, fulfillment, returns
- **"AI dashboard" / "LLM admin"** → models, prompts, conversations, token/cost tracking, evaluation pipelines
- **"Helpdesk" / "support dashboard"** → tickets, SLAs, queues, canned responses, customer context
- **"CRM" / "sales dashboard"** → contacts, deals, pipeline stages, campaigns, forecasting
- **"HR dashboard" / "people admin"** → employees, payroll, leave, benefits, performance reviews
- **"Medical" / "healthcare admin"** → patients, encounters, prescriptions, claims, HIPAA compliance
- **"Marketplace admin"** → two-sided (buyers + sellers), disputes, commissions, trust/safety
- **"Gaming admin" / "esports"** → players, matches, virtual economy, anti-cheat, seasons
- **"Restaurant" / "POS admin"** → menus with modifiers, orders, table management, kitchen display
- **"Property management"** → units, leases, tenants, maintenance, owner reporting
- **"Logistics" / "fleet management"** → shipments, vehicles, routes, drivers, real-time tracking
- **"Legal" / "law firm"** → matters, time billing (0.1-hour increments), trust accounting, conflicts
- **"Construction" / "field services"** → jobs, crews, permits, inspections, offline-first mobile
- **"Education" / "LMS"** → courses, enrollments, gradebook, assessments, student progress

If the dashboard spans multiple domains (e.g., SaaS that includes billing → SaaS + Financial), read both sections. Build the foundation slice the same way regardless, then specialize the feature slices to the archetype.

---

## Cross-cutting patterns

Several patterns emerged across all 33 domains. If your domain isn't listed above, check whether these apply — they almost certainly do:

1. **State machines, not status columns** — every domain has at least one entity with a lifecycle more complex than a simple enum. Orders, tickets, cases, bookings, grants, permits, matches — all have conditional transitions, parallel states, and reversal paths. Model them explicitly.

2. **Temporal complexity beyond timestamps** — business hours, fiscal periods, timezone-aware deadlines, seasonal schedules, effective dates, rights windows, SLA clocks that pause. Almost no domain uses simple datetime comparisons.

3. **Multi-dimensional pricing** — nearly no domain has a single price field. Pricing varies by time, geography, customer tier, channel, volume, and promotional period. A "price" column is almost always wrong.

4. **Compliance causes rewrites, not technical debt** — technical shortcuts are tolerable; compliance violations are not. The domains with the harshest consequences (healthcare, finance, legal, HR, gaming with minors) are where "we'll add that later" is most dangerous.

5. **Append-only audit trails** — financial, healthcare, legal, HR, cybersecurity, and gaming domains all require immutable records. Soft-delete is insufficient; you need reversing entries and full audit logs.

6. **Domain-specific code systems** — ICD-10 (medical), CPT (procedures), NAICS (industry), HS codes (customs), LEDES (legal billing), STIX (threat intel), EIDR (entertainment). If your domain has a standard taxonomy, use it — don't invent your own.

7. **Two audiences, one platform** — marketplaces, LMS (student/teacher), healthcare (patient/provider), support (agent/customer), and gaming (player/admin) all have at least two fundamentally different user types that need different views of the same data.

8. **Offline/mobile-first for field domains** — construction, agriculture, logistics, sports, and restaurant (KDS/POS) all have users who are not sitting at a desk with good WiFi. If the dashboard doesn't work on a phone with spotty connectivity, it doesn't work.
