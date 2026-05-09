# Domain Considerations

This file covers the domain-specific landmines for 33 common dashboard verticals. The generic dashboard discipline — auth, RBAC, CRUD, vertical slices, states, validation — applies identically to all of them. What differs is the 20% of domain-specific knowledge that, if missed, causes a rewrite, a compliance violation, or a broken product.

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

Each domain section below has the full gotcha list, compliance requirements, expected UX, and seed data shape. Read the matching section before designing your schema.

---

## 1. SaaS / Multi-tenant

**Archetype:** Platform admin for a multi-tenant product — managing organizations, subscriptions, users, feature access, and usage.

**Core entities:** Tenant/Organization, Subscription/Plan, Seat/License, Feature Flag, Usage Metric, Invoice, API Key

**Gotchas:**
- **Tenant isolation is not just auth** — a missing `WHERE org_id = ?` leaks data across tenants. Every query, every cache key, every background job must be tenant-scoped. Shared DB vs. schema-per-tenant vs. DB-per-tenant is an architectural decision that's nearly impossible to change later.
- **Plan limits are runtime constraints, not billing metadata** — "5 seats," "10GB storage," "1000 API calls/day" must be enforced in real-time at the application layer, not just checked at invoice time.
- **Subscription lifecycle has ~12 states, not 3** — trialing, active, past_due, paused, cancelled-but-active-until-period-end, downgraded-pending, upgraded-prorated, churned, reactivated, comped. Modeling this as "active/inactive" breaks.
- **Feature flags are per-tenant, per-plan, AND per-user** — a feature might be enabled for the plan but toggled off for the org, or enabled as a beta for one specific tenant. Three-dimensional matrix.
- **Usage-based billing requires idempotent event ingestion** — double-counted API calls mean incorrect invoices, chargebacks, and broken trust.
- **Impersonation/support access must be audited** — support staff viewing a tenant's dashboard must leave an audit trail and must not be able to modify billing.
- **White-labeling affects every layer** — custom domains, logos, and email from-addresses require SSL cert provisioning, DNS validation, and email deliverability config.

**Compliance:** SOC 2 Type II (expected by enterprise buyers), GDPR data processing agreements per tenant, data residency requirements (EU tenants may require EU-hosted data).

**UX users expect:** Tenant switcher in nav, plan comparison/upgrade flow inline, usage dashboards with limits as gauges, "impersonating [tenant]" banner for support staff.

**Seed data shape:** 3 orgs (1 on free, 1 on pro, 1 on enterprise trial expiring in 3 days). 8-12 users across them with all roles represented. 1 org approaching its seat limit. Usage data spanning 90 days with realistic daily variation. 2 pending invoices, 1 past-due. Feature flags with at least 1 beta feature enabled for only 1 org.

---

## 2. E-commerce / Retail

**Archetype:** Store admin managing products, orders, inventory, and fulfillment.

**Core entities:** Product/Variant/SKU, Order, Cart, Inventory Location, Fulfillment, Return/Refund, Promotion/Discount

**Gotchas:**
- **A product is not a row — it's a tree.** Product > Variant (size/color) > SKU > Inventory per location. Flattening this causes data integrity nightmares when a size is out of stock at one warehouse but available at another.
- **Price is not a single number** — list price, sale price, member price, bulk/tiered pricing, currency-specific pricing, tax-inclusive vs. tax-exclusive. A "price" column is always wrong.
- **Inventory is a ledger, not a counter** — decrementing a quantity field causes race conditions. Inventory should be event-sourced: reserved, allocated, shipped, returned, adjusted, damaged. "Available" is a computed projection.
- **Order state machines are complex and partially reversible** — pending > paid > partially_shipped > shipped > partially_returned > refunded. Many transitions happen in parallel.
- **Tax calculation is locale-specific and changes constantly** — US sales tax varies by state/county/city, EU VAT varies by product category and buyer location. Use a tax service API (Avalara, TaxJar). Never hardcode rates.
- **Promotions interact combinatorially** — "20% off + free shipping + buy-2-get-1" — which stack? Promotion engines are their own domain.
- **Returns are not the inverse of orders** — partial refunds, restocking fees, store credit vs. original payment method, inventory going to a different location.

**Compliance:** PCI DSS if handling card data (use tokenized payment providers), consumer protection laws (EU cooling-off periods), ADA/WCAG for storefront.

**UX users expect:** Drag-to-reorder product images, bulk inventory update via spreadsheet, order timeline with every state transition, SKU matrix editor (size x color grid), real-time inventory badges.

**Seed data shape:** 25 products with 2-4 variants each (size/color), realistic pricing ($9.99-$299.99 in integer cents). 2 inventory locations. 50 orders spanning 90 days in mixed states (3 pending, 5 shipped, 2 partially_returned, 1 refunded, rest completed). 5 customers with multiple orders, 15 with one. 2 active promotions (one percentage, one free-shipping). 1 product out of stock at one location but available at the other.

---

## 3. CMS / Content / Blog

**Archetype:** Content team managing articles, pages, media, and publishing workflows.

**Core entities:** Content Item (Post/Page), Content Type/Schema, Media Asset, Taxonomy (Category/Tag), Revision/Version, Workflow Stage, Author

**Gotchas:**
- **Content is not a single "body" text field** — content types have structured fields (hero image, SEO metadata, excerpt, related posts, custom fields). Storing everything in one rich text blob blocks structured queries, API delivery, and multi-channel publishing.
- **Draft/publish lifecycle requires revision history** — every save creates a version. Published content and draft edits coexist simultaneously. Scheduled publishing requires a background job.
- **Slugs and URLs are a data integrity concern** — changing a slug must create redirects from the old URL. Duplicate slugs, slug collisions, and locale-specific slugs cause SEO damage if missed.
- **Media management is its own subsystem** — images need multiple generated sizes, alt text, focal point cropping, CDN delivery, and deduplication. Deleting a media asset referenced by 50 posts is a cascade problem.
- **Localization is not just translation** — different locales may have entirely different content. Fallback chains (show English if French is missing), RTL support, and locale-specific URLs are structural decisions.
- **Content workflows are org-specific** — "Draft > Review > Legal > Scheduled > Published" vs. "Draft > Published." The workflow should be configurable, not hardcoded.

**Compliance:** WCAG 2.1 AA for published content, GDPR (comment forms, cookies), copyright/licensing metadata for media, DMCA takedown process.

**UX users expect:** WYSIWYG with structured blocks (Notion-style), side-by-side preview, version diff view, drag-to-reorder blocks, inline media upload, SEO score indicator, editorial calendar view.

**Seed data shape:** 3 content types (Post, Page, Case Study). 20 posts across 4 categories and 10 tags — 12 published, 3 drafts, 2 scheduled (one for tomorrow, one for next week), 2 in review, 1 archived. 3 authors with different roles (editor, writer, admin). 30 media assets (images with alt text, 2 PDFs). 1 post with 5 revisions showing meaningful diffs. Realistic slugs, SEO metadata, and featured images.

---

## 4. Financial / Fintech / Accounting

**Archetype:** Finance team managing ledgers, transactions, invoices, and reconciliation.

**Core entities:** Account (asset/liability/equity/revenue/expense), Transaction/Journal Entry, Ledger, Invoice, Reconciliation, Chart of Accounts, Fiscal Period

**Gotchas:**
- **Double-entry bookkeeping is non-negotiable** — every transaction must have equal debits and credits. A single-entry "transactions" table requires a full rewrite when an accountant reviews it.
- **Money must never use floating point** — use integer cents or a decimal type with fixed precision. $0.01 rounding error across 100,000 transactions is $1,000 that fails an audit.
- **Financial records are append-only** — never edit or delete a transaction. Create a correcting/reversing entry. The original record must remain with a linked reversal.
- **Fiscal periods close and lock** — once a month/quarter/year is "closed," no transactions post to it without a formal reopening process. Not optional.
- **Multi-currency requires exchange rates at transaction time** — store both the original currency amount AND the converted amount at the rate used. Rates change daily; retroactive revaluation is a separate process.
- **Reconciliation is a first-class workflow** — matching bank statement lines to ledger entries is core, not an afterthought. Unreconciled items must be surfaced prominently.
- **Rounding rules vary by jurisdiction** — some countries round to nearest 0.05, some use banker's rounding, tax rounding has locale-specific rules.

**Compliance:** SOX (public companies), GAAP/IFRS accounting standards, PCI DSS for payment data, AML/KYC for fintech, data retention 7+ years.

**UX users expect:** T-account visualization, trial balance report, aged receivables/payables, bank reconciliation matching interface, chart of accounts tree, journal entry form with auto-balancing, fiscal period lock indicators.

**Seed data shape:** Chart of accounts with 20-30 accounts across all 5 types (asset/liability/equity/revenue/expense). 200 journal entries spanning 6 months — all balanced (debits = credits). 1 closed fiscal period (last quarter), 1 open. 15 invoices (10 paid, 3 outstanding, 2 overdue). 50 bank statement lines with 40 reconciled and 10 unreconciled. All amounts in integer cents. 1 multi-currency transaction with stored exchange rate. 1 reversing entry linked to its original.

---

## 5. Healthcare / Medical

**Archetype:** Clinical or admin staff managing patients, encounters, diagnoses, prescriptions, and claims.

**Core entities:** Patient, Provider, Encounter/Visit, Diagnosis (ICD code), Procedure (CPT code), Medication/Prescription, Insurance Claim, Care Plan

**Gotchas:**
- **HIPAA is not optional and it's not just encryption** — it requires access controls, audit logging of every PHI access (who viewed what patient record when), minimum necessary access, Business Associate Agreements with every vendor, breach notification procedures, and regular risk assessments. Violations cost $50K-$1.8M per incident.
- **Patient identity matching is an unsolved hard problem** — patients lack universal IDs. Name + DOB matching creates duplicates, and merging duplicates is a complex workflow (which record's allergies win?).
- **Clinical data uses standardized code systems** — ICD-10 for diagnoses (~70,000 codes), CPT for procedures, LOINC for labs, RxNorm for medications. Free-text fields are not acceptable for these.
- **Interoperability standards are mandated** — HL7 FHIR is required for certified EHR systems. You will need to both consume and produce FHIR resources.
- **Consent management is granular and revocable** — a patient may consent to treatment but not to sharing data with a specific insurer. This is not a simple boolean.
- **Drug interactions and allergy checking are safety-critical** — prescribing workflows must check drug-drug interactions and contraindications. Getting this wrong can kill someone.

**Compliance:** HIPAA, HITECH Act, 21st Century Cures Act (information blocking), GDPR (EU health data is "special category"), FDA for clinical software, state-specific consent laws.

**UX users expect:** Problem/medication/allergy list always visible, clinical note templates (SOAP format), encounter timeline, medication reconciliation workflow, e-prescribing integration, patient portal with role-restricted views.

**Seed data shape:** 50 patients (diverse demographics, 3 with no encounters, 1 with revoked consent for a specific provider). 15 providers across 3 departments. 200 encounters spanning 6 months with ICD-10 and CPT codes. 10 active prescriptions with 2 known drug interactions seeded. 5 insurance claims (3 approved, 1 denied, 1 pending). Audit log with 500+ PHI access entries. 1 patient with a merged duplicate record.

---

## 6. Education / EdTech / LMS

**Archetype:** Instructors and admins managing courses, enrollments, grades, and student progress.

**Core entities:** Course, Module/Lesson, Assignment/Assessment, Enrollment, Grade/Score, Student, Instructor, Certificate

**Gotchas:**
- **Grading is not just a percentage** — letter grades, pass/fail, weighted categories (homework 30%, exams 40%), curved grades, dropped lowest scores, incomplete grades, grade overrides. The gradebook is a computation engine.
- **Academic calendar structures everything** — semesters, terms, registration periods, add/drop deadlines, grade submission deadlines create temporal boundaries that affect what actions are available when.
- **Student data has specific protections** — FERPA restricts who can see student records. Parents of minors have rights; parents of adults (18+) do not unless the student grants access.
- **Content sequencing and prerequisites are a DAG** — "complete Module 3 before Module 4" and "pass Course 101 before enrolling in 201" create dependency graphs enforced at enrollment and content access time.
- **Assessment integrity is a feature** — proctoring, time limits, randomized question pools, plagiarism detection, and lockdown browser integration are expected.
- **Accessibility is legally mandated** — ADA/Section 508 compliance is required for educational institutions. All content must work with screen readers, video must have captions.

**Compliance:** FERPA (US student records), COPPA (under-13), GDPR (EU students), ADA/Section 508 accessibility, state-specific K-12 data privacy laws.

**UX users expect:** Gradebook grid (students x assignments), progress tracker (completion %), assignment submission workflow with rubric, discussion forum threading, attendance tracker, certificate builder, student/parent/teacher portal views.

**Seed data shape:** 5 courses (2 active, 1 completed, 1 upcoming, 1 archived). 30 students and 4 instructors. 60 enrollments across courses. 8 assignments per active course with weighted grading categories. Grades for 80% of student-assignment pairs (leave some unsubmitted). 1 student with an "incomplete" grade. Prerequisites between 2 courses. 3 modules per course with sequential unlock. 1 certificate template with 5 issued certificates.

---

## 7. Travel / Hospitality / Booking

**Archetype:** Property or tour operator managing listings, availability, reservations, and guest communication.

**Core entities:** Listing/Property/Room, Reservation/Booking, Availability, Rate/Pricing, Guest, Channel (OTA), Calendar Block

**Gotchas:**
- **Availability is a time-slot matrix, not a boolean** — a hotel room is available per-night, a tour per-time-slot. Overbooking is intentional in some domains (airlines) and catastrophic in others (vacation rentals).
- **Rate management is multi-dimensional** — rates vary by date, day of week, season, length of stay, occupancy, booking channel, lead time, member status, and promo code. A "price" field is meaningless; you need a rate engine.
- **Channel management creates double-booking risk** — listings on Booking.com, Airbnb, Expedia, and direct must sync availability in near-real-time. A booking on one channel must instantly block dates on all others.
- **Cancellation policies are complex business logic** — "Free until 48 hours before check-in, 50% for 24-48 hours, no refund within 24 hours" with timezone considerations (whose timezone?), force majeure, and partial cancellations.
- **Timezone handling is critical and pervasive** — a hotel in Tokyo booked by a user in New York: checkout is 11 AM JST but the confirmation email shows the guest's local time. Cancellation deadlines evaluate in the property's timezone.
- **Guest communication has timing requirements** — confirmation immediately, pre-arrival info 3 days before, check-in instructions day-of, review request post-checkout. Automated sequences tied to booking dates.

**Compliance:** PCI DSS for payment, local tourism/lodging taxes and reporting, ADA for US properties, anti-discrimination laws, data retention for tax.

**UX users expect:** Calendar grid for availability (green/yellow/red), drag-to-block dates, rate calendar (price heatmap), reservation timeline (Gantt-style), channel distribution status, guest communication timeline, dynamic pricing suggestions.

**Seed data shape:** 3 properties (hotel with 10 rooms, vacation rental with 1 unit, tour operator with 3 daily slots). 40 reservations spanning next 90 days in mixed states (confirmed, checked-in, checked-out, cancelled, no-show). Rates that vary by day-of-week and season. 2 channel sources (direct + Booking.com). 5 calendar blocks (owner stays, maintenance). 1 reservation with a pending cancellation inside the refund window. Guest communications at various stages.

---

## 8. Sports / Fitness

**Archetype:** Gym, studio, or club managing members, classes, schedules, and trainer assignments.

**Core entities:** Member/Athlete, Class/Session, Schedule, Membership Plan, Trainer/Coach, Booking/Check-in, Workout/Program, Body Metrics

**Gotchas:**
- **Class capacity and waitlists are real-time constraints** — a class with 20 spots must enforce capacity at booking time, manage a waitlist with auto-promotion on cancellation, and handle no-shows (which may incur penalties).
- **Recurring schedules with exceptions are hard** — "Spinning every Tuesday/Thursday at 6 PM, except holidays, with a substitute instructor on March 5th" is a recurring event with overrides. iCal RRULE + EXDATE is the minimum viable approach.
- **Membership freezes, pauses, and transfers are not edge cases** — members freeze for injury/travel, pause seasonally, transfer locations, or convert monthly to annual. Each has proration and billing implications.
- **Wearable/device integration generates high-volume time-series data** — heart rate every second, GPS tracks, rep counts. This needs time-series storage and aggregation, not relational rows.
- **Late cancellation and no-show policies drive revenue** — "Cancel 2+ hours before or lose a class credit" is business-critical logic. Grace periods, penalty credits, and strike systems are expected.
- **Family/group accounts share billing but have individual profiles** — a parent pays for the family membership but each member has their own bookings and progress.

**Compliance:** Health data privacy (jurisdiction-dependent), minor athlete protections (parental consent, safeguarding), PCI for recurring billing, liability waivers (digital signature).

**UX users expect:** Weekly schedule grid, class capacity indicators, member check-in kiosk mode, workout builder (sets x reps x weight), progress charts, leaderboards, trainer schedule calendar.

**Seed data shape:** 80 members (60 active, 10 frozen, 5 expired, 5 on trial). 4 membership plans (monthly, annual, family, drop-in). 6 class types with recurring weekly schedules. 200 bookings over 30 days — 3 classes at capacity with waitlists, 5 no-shows, 2 late cancellations. 4 trainers with schedules. 1 family account with 3 members. 10 members with body metric histories (weight/measurements over 6 months).

---

## 9. Real Estate / Property Management

**Archetype:** Property manager handling units, tenants, leases, maintenance, and owner reporting.

**Core entities:** Property, Unit, Tenant, Lease, Maintenance Request, Rent Payment, Listing, Inspection

**Gotchas:**
- **Lease terms are legal contracts with complex date logic** — start/end dates, renewal options (auto-renew vs. month-to-month), rent escalation clauses, security deposit rules (state-specific maximums and return timelines), early termination penalties.
- **Rent accounting has trust account requirements** — many jurisdictions require security deposits in separate escrow/trust accounts. Commingling operating funds with tenant deposits is illegal in most US states.
- **Maintenance requests have legal response timelines** — habitability issues (heat, water, structural) have legally mandated response times. Treating all requests equally causes legal violations.
- **Property financials need owner-level reporting** — each owner needs P&L statements, 1099 generation, reserve fund accounting, and CAM reconciliation. This is per-property-owner accounting.
- **Vacancy and turnover is a workflow** — move-out inspection > deposit itemization > unit make-ready > listing > showing > application > lease signing > move-in inspection. Each step has timelines and dependencies.
- **Fair housing compliance is non-negotiable** — screening criteria must be applied uniformly. The dashboard must not surface protected class information to decision-makers during application review.

**Compliance:** Fair Housing Act, state-specific landlord-tenant laws (vary wildly), security deposit laws, lead paint disclosure (pre-1978), habitability requirements, eviction process requirements, 1099-MISC for owner payments.

**UX users expect:** Portfolio overview with vacancy rates, unit-level P&L, lease expiration timeline, maintenance request kanban, tenant ledger, inspection checklist with photo capture, comparative market analysis.

**Seed data shape:** 3 properties with 20 total units (15 occupied, 3 vacant, 2 in turnover). 15 active leases with varied terms (1 expiring this month, 1 month-to-month, 1 with rent escalation). 30 maintenance requests (20 completed, 5 open, 3 urgent/habitability, 2 scheduled). 6 months of rent payments with 2 late payments and 1 partial. 2 property owners with separate financials. Security deposits in trust. 1 unit in make-ready workflow.

---

## 10. Logistics / Supply Chain / Fleet

**Archetype:** Operations team managing shipments, vehicles, drivers, routes, and warehousing.

**Core entities:** Shipment/Consignment, Vehicle/Asset, Route, Driver/Operator, Warehouse/Depot, Load/Cargo, Proof of Delivery, Geofence

**Gotchas:**
- **Location tracking is a high-frequency data stream** — vehicles report GPS every 5-30 seconds. This is time-series data needing specialized storage (TimescaleDB, InfluxDB). PostgreSQL rows will fail at scale.
- **Route optimization is NP-hard** — vehicle capacity, delivery time windows, driver hours-of-service, traffic, multi-stop optimization. Integrate with an optimization engine (Google OR-Tools, HERE, Routific). Don't build one.
- **Chain of custody and proof of delivery are legal documents** — photos, signatures, timestamps, GPS at delivery are evidence in disputes. This data must be immutable.
- **Hours of Service regulations are strict** — US DOT: max 11 hours driving after 10 hours off, 14-hour window, 30-minute break after 8 hours. EU tachograph rules differ. Violations mean heavy fines.
- **ETA calculations must account for real-world constraints** — loading/unloading time, traffic, driver breaks, customs for cross-border, weight stations. Naive distance/speed is always wrong.
- **Vehicle maintenance is predictive, not just calendar-based** — intervals based on mileage, engine hours, AND time. Deferred maintenance must trigger escalating alerts.

**Compliance:** DOT/FMCSA, EU driving/rest regulations, hazmat transport rules, customs/import-export docs, cold chain compliance (temperature logging for perishables), ELD mandate.

**UX users expect:** Real-time map with vehicle positions, route visualization, driver HOS status bars, shipment tracking timeline, warehouse slot grid, vehicle maintenance dashboard with red/yellow/green, geofence alerts.

**Seed data shape:** 15 vehicles (12 active, 2 in maintenance, 1 decommissioned). 8 drivers with varied HOS states (2 near daily limit, 1 on mandatory rest). 50 shipments (30 delivered with proof-of-delivery, 10 in transit with GPS breadcrumbs, 5 pending pickup, 3 delayed, 2 with exceptions). 2 warehouses with slot occupancy. 100,000 GPS data points across the fleet. 5 geofences. 3 vehicles with upcoming maintenance based on mileage.

---

## 11. HR / People / Payroll

**Archetype:** HR team managing employees, compensation, benefits, leave, and compliance.

**Core entities:** Employee, Position/Job, Department, Pay Period, Payroll Run, Leave/PTO Balance, Benefits Enrollment, Performance Review

**Gotchas:**
- **Payroll is the most regulation-heavy computation most developers will ever implement** — gross pay, pre-tax deductions (401k, HSA), federal withholding (W-4), state tax (50 different rules), local tax, FICA (Social Security caps change annually), Medicare (additional 0.9% above $200K), post-tax deductions, garnishments (with priority rules). Any error is a legal violation.
- **Multi-state employment is a tax nightmare** — remote employees: which state's taxes apply? Reciprocity agreements, nexus rules, home state vs. work state all matter.
- **PTO accrual is not a simple balance** — rates vary by tenure, accrual may be per-pay-period, some states require payout at termination, some cap accrual ("use it or lose it" is illegal in California).
- **Effective dating is pervasive** — salary changes mid-pay-period, title changes effective next month, benefits effective first-of-month after 30 days. Every attribute needs effective dates, not just current values.
- **Compensation data is the most sensitive data in the company** — even HR staff may have tiered access (can see ICs but not executives).
- **Termination is a multi-system workflow** — final paycheck (timing is state-regulated), COBRA, access revocation, equipment return, exit interview, 401k rollover. Missing any step has legal consequences.

**Compliance:** FLSA (overtime, exempt vs. non-exempt), FMLA (leave), ADA (accommodations), ACA (benefits), EEOC, W-2/W-4/I-9/1099 forms, COBRA, ERISA (retirement).

**UX users expect:** Org chart, payroll run preview with exceptions highlighted, PTO calendar (team view), benefits enrollment wizard, performance review workflow, compensation band visualization, headcount reporting.

**Seed data shape:** 40 employees across 4 departments and 3 levels (IC, manager, director). 2 pay periods of completed payroll with realistic deductions. 5 employees in different states (for multi-state tax). PTO balances with varied accrual rates by tenure. 1 employee on FMLA leave, 1 recently terminated (with final paycheck record). Benefits enrollment data for 2 plan types. 3 pending performance reviews. Salary history with effective dates showing 1 mid-period raise.

---

## 12. Project Management / Collaboration

**Archetype:** Teams managing tasks, sprints, timelines, and resource allocation.

**Core entities:** Project, Task/Issue, Sprint/Iteration, Board/View, Milestone, Time Entry, Comment/Activity, Workflow Status

**Gotchas:**
- **Task dependencies create scheduling constraints** — finish-to-start, start-to-start, with lag/lead times. Changing one task's dates must cascade through the dependency graph (critical path). Circular dependencies must be detected.
- **Custom workflows per team are expected** — one team uses Kanban (3 statuses), another uses a 7-status workflow with approval gates and transition rules ("only QA can move to Done").
- **Time tracking has billing implications** — entries may be billable/non-billable, associated with a client, subject to approval. Rounding rules and overtime add complexity.
- **Permissions are project-scoped, not global** — admin on Project A, member on Project B, viewer on Project C. Guest/external collaborator access with limited visibility is common.
- **Activity feeds must be real-time** — every field change generates an event. Users expect WebSocket-driven updates. The activity log is also the audit trail.
- **Reporting requires cross-project aggregation** — portfolio health, resource utilization, burn-down charts, velocity. These are expensive queries needing materialized views.

**Compliance:** SOC 2 for enterprise, GDPR (right to deletion conflicts with audit trails).

**UX users expect:** Kanban board with drag-and-drop, Gantt chart with dependency arrows, sprint backlog with story points, inline time tracking, @-mentions with notifications, customizable views (list/board/calendar/timeline).

**Seed data shape:** 3 projects (1 active sprint, 1 planning, 1 completed). 60 tasks across all statuses with 10 dependency relationships (no circular). 2 custom workflows (3-status Kanban, 5-status with approvals). 8 team members with varied project-level roles. 100 time entries (70 billable, 30 non-billable). 200 activity feed events. 1 overdue milestone. Story point estimates on 80% of tasks. 5 tasks with file attachments.

---

## 13. Customer Support / Helpdesk

**Archetype:** Support team managing tickets, SLAs, queues, and customer communication.

**Core entities:** Ticket/Case, Queue, Agent, SLA, Canned Response/Macro, Knowledge Base Article, Customer, Escalation

**Gotchas:**
- **SLA tracking is a contractual obligation** — "First response within 1 business hour" must account for business hours, timezone of the contract, holidays, and SLA pausing when waiting on customer response. A ticket opened Friday at 4:30 PM with a 4-hour SLA is due Monday, not Saturday.
- **Ticket routing is multi-factor** — skills-based (language, product expertise), round-robin with capacity limits, priority queue jumping, VIP routing, and follow-the-sun for global teams.
- **Merging duplicate tickets must preserve context** — keep all messages from both, notify both requesters, consolidate SLA timers (use the earlier/stricter one).
- **Collision detection prevents duplicate work** — two agents viewing the same ticket need real-time presence indicators ("Agent Smith is typing").
- **Escalation paths are time-triggered and condition-triggered** — "If no response in 30 minutes, escalate to Tier 2. If Enterprise plan, escalate immediately." Automated rules running continuously.
- **CSAT surveys have timing requirements** — too early or too late = low response. Survey fatigue must be managed (don't survey the same customer every time).

**Compliance:** GDPR (right to delete, but ticket history may be needed for disputes), PCI DSS (mask card numbers in messages), data retention policies.

**UX users expect:** Queue with SLA countdown timers (red when breaching), split-pane (list + detail), customer context sidebar, canned response insertion, internal notes vs. public replies, collision indicators, satisfaction trends.

**Seed data shape:** 100 tickets spanning 30 days — 15 open (3 breaching SLA, 2 escalated), 80 resolved, 5 pending customer response. 6 agents across 2 tiers. 3 SLA policies (enterprise 1hr, pro 4hr, free 24hr). 20 canned responses. 10 knowledge base articles. 500 messages (mix of public replies and internal notes). CSAT scores on 60% of resolved tickets. 2 merged tickets. 1 VIP customer with priority routing.

---

## 14. Marketing / CRM / Sales

**Archetype:** Sales and marketing teams managing leads, deals, campaigns, and pipelines.

**Core entities:** Contact/Lead, Account/Company, Opportunity/Deal, Pipeline (multiple), Pipeline Stage, Campaign, Activity/Touchpoint, Segment, Attribution, Sequence/Cadence, Lead Score, Quote/Proposal, Product Catalog, Territory/Assignment Rule, Lifecycle Stage, Quota

**Gotchas:**
- **Contact deduplication is an ongoing battle** — same person from a webform, a CSV import, and LinkedIn. Merge logic must handle conflicting data and cascade to all related activities and opportunities.
- **Pipeline stages are not linear** — deals move backward, skip stages, sit for months (needing stale deal alerts), and have stage-specific required fields.
- **Attribution modeling is an analytics problem masquerading as a data model** — first-touch, last-touch, linear, time-decay require capturing every touchpoint with timestamps. Changing the model must recompute all historical data.
- **Email deliverability is a feature** — bounce handling, unsubscribe management (CAN-SPAM one-click), suppression lists, sending reputation, SPF/DKIM/DMARC. Sending to a bad list blacklists your domain.
- **Forecast accuracy requires pipeline weighting** — stage-based probability vs. AI-predicted vs. rep-override are three different values. Forecasting by team, quarter, with commit/best-case/pipeline is expected.
- **Activity logging must be effortless or it won't happen** — auto-logging from email integration, calendar sync, and call recording is expected. Manual logging alone means empty CRMs.
- **Custom fields are the data model, not an afterthought** — every business needs fields no generic schema anticipates ("Competitor mentioned," "Contract renewal month"). Schema design is a trap: EAV tables destroy query performance, JSONB loses type safety, wide tables cap out. You need a field type registry (text, number, date, dropdown, multi-select, relationship, formula, rollup), per-object field limits, field-level permissions, and formula fields that compute across relationships. Without custom fields, the CRM is unusable for real businesses.
- **Email sequences/cadences are a distinct subsystem** — multi-step automated outreach: step 1 sends email, wait 3 days, check for reply/open, branch to step 2A (if replied) or 2B (if not), with A/B testing per step. Auto-unenroll on reply, business-hours-only sending, per-rep daily send limits for domain reputation, manual task steps interleaved with automated emails, and sequence state must update when a rep manually replies to a sequence contact.
- **Lead routing determines speed-to-lead (and revenue)** — responding within 5 minutes makes reps 9x more likely to qualify. Routing rules: round-robin, weighted (more to better performers), geographic/territory-based, firmographic (by industry/company size), availability-based (skip OOO reps), queue-based (reps claim from a pool). High-score leads may skip the queue. Unacted leads auto-reassign after 48 hours. Routing interacts with capacity limits (rep with 50 open deals shouldn't get more).
- **Contact enrichment is continuous, not a one-time import** — auto-fill company data (industry, size, revenue, tech stack) from Clearbit, Apollo, ZoomInfo, Clay. Design needs: field mapping (enrichment > CRM fields), conflict resolution (never overwrite manual edits), re-enrichment on schedule (every 30 days), enrichment source tracking, and cost/credit tracking per API call.
- **Lead scoring requires decay and lifecycle thresholds** — composite 0-100 score from: firmographic fit (job title +10, wrong industry -20), behavioral signals (pricing page +20, webinar +15, demo form +30), and decay (no activity for 30 days = -25%/month). Without decay, the MQL pool fills with stale leads. Scores drive automation: crossing MQL threshold (50) auto-routes to sales with SLA. Crossing SQL (75) auto-creates a deal. The score model must be tunable by marketing ops, not hardcoded.
- **Multiple pipelines are inevitable** — new business, renewals, upsell, partnerships, channel. Each has different stages, required fields, probability mappings, forecast rollup, and ownership rules. A "Renewal" pipeline has stages like "Usage review > Proposal > Negotiation > Renewed/Churned" — completely different from new business. Pipeline-specific reporting (win rate, cycle length per pipeline) is expected. Builders who hardcode one pipeline restructure when the business adds a second.
- **Contact lifecycle stages are independent of deal stages** — a contact's lifecycle (Subscriber > Lead > MQL > SQL > Opportunity > Customer > Evangelist) tracks their overall relationship. A deal's pipeline stage tracks one specific commercial opportunity. One contact can be a "Customer" while having a new upsell deal in "Proposal." Lifecycle only moves forward automatically. Deal stages can move backward. Conflating these means ambiguous status after deal close/loss.
- **Team hierarchy scoping is not standard RBAC** — a rep sees only their own contacts/deals. A manager sees direct reports'. A VP sees the region. This is org-hierarchy-scoped row-level security. It interacts with every query: every list view, report, export, and API response must be filtered by the requesting user's visibility scope. Building this as an afterthought means rewriting every data access layer.
- **Quote/proposal generation (CPQ) closes the deal-to-revenue gap** — line items (product, quantity, unit price, discount %), product catalog with pricing tiers, discount approval workflows (>15% needs manager, >30% needs VP), quote versioning (v1 > v2 > v3 with diff), PDF generation with branding, e-signature integration (DocuSign, PandaDoc), quote expiration with auto-follow-up. The deal amount should compute from line items, not be manually entered.
- **CRM-specific integrations are the most technically complex** — bidirectional calendar sync (meetings appear in both CRM and Google/Outlook, with conflict resolution), email sync (via Gmail/Outlook APIs or IMAP, matching sent/received emails to contacts by address), phone/dialer (click-to-call, recording with consent, voicemail drops, power dialer for sequences), website visitor tracking (reverse IP to identify companies, feeding lead scoring).

**Compliance:** CAN-SPAM / CASL / GDPR for email, TCPA for phone/SMS, Do Not Call registries, consent tracking for B2C, GDPR right to erasure across all contact data and activity history.

**UX users expect:** Pipeline board (Kanban by stage with deal values, per-pipeline), contact timeline (every interaction chronologically), email sequence builder with branching, lead scoring dashboard with MQL/SQL thresholds, territory/assignment rule configuration, quote builder with line items and approval status, multiple pipeline selector, contact lifecycle stage progression, team hierarchy visualization, RevOps metrics (win rate, avg deal size, cycle length, pipeline coverage ratio 3-5x target, quota attainment, stage conversion rates, activity-to-outcome ratios), enrichment status indicators on contact records.

**Seed data shape:** 200 contacts across 50 companies with lifecycle stages (30 subscribers, 40 leads, 30 MQLs, 25 SQLs, 50 customers, 25 churned). 25 open deals across 3 pipelines (new business, renewal, upsell) with 5 stages each. 5 sales reps in 2 teams with a manager hierarchy. 500 activity records (emails, calls, meetings) with auto-logged and manual mix. 3 campaigns with engagement metrics. 10 closed-won and 8 closed-lost in last quarter. Lead scores 0-100 with 5 contacts in MQL range (50-74), 3 in SQL range (75+), and 10 decayed below threshold. 2 active email sequences with 4 steps each, 30 contacts enrolled. 5 quotes (2 accepted, 1 pending approval, 1 expired, 1 draft) with line items from a 10-product catalog. 2 duplicate contacts ready for merge. 3 enrichment records showing Clearbit-populated company data. Territory rules for 2 regions. Quotas per rep for current quarter.

---

## 15. IoT / Device Management

**Archetype:** Operations team monitoring devices, telemetry, firmware, and alerts at scale.

**Core entities:** Device, Sensor, Telemetry Reading, Alert/Alarm, Firmware Version, Device Group/Fleet, Command, Configuration Profile

**Gotchas:**
- **Telemetry volume is orders of magnitude beyond CRUD** — 10,000 devices x 10 metrics x every 10 seconds = 600,000 data points/minute. PostgreSQL won't handle this. Use a time-series database (InfluxDB, TimescaleDB, QuestDB) with retention policies and downsampling.
- **Devices are offline by default** — commands queue and retry. Telemetry arrives out of order and in batches. "Offline" is normal, not an error, with its own alerting thresholds.
- **OTA firmware updates are high-risk deployments** — a bad update bricks thousands of devices. Staged rollouts (1% > 10% > 50% > 100%), rollback, and success reporting are critical.
- **Alert fatigue kills usefulness** — deduplication, suppression windows (maintenance mode), severity escalation, acknowledgment workflows, and alert correlation (100 devices in same location = one root cause).
- **Device provisioning is a security boundary** — unique credentials (certificates), device attestation, secure enrollment. Compromised credentials must be revocable per-device.
- **Edge vs. cloud processing determines architecture** — some computation must happen at the edge. The dashboard manages edge gateway config, local rule engines, and data forwarding.

**Compliance:** FDA (medical devices), FCC (RF devices), GDPR (if devices collect personal data), IEC 62443 (industrial IoT), data sovereignty for cross-border deployments.

**UX users expect:** Real-time device map, telemetry time-series charts with zoom/pan, alert list with severity and acknowledgment, live device metrics, fleet health scores, firmware rollout tracker, threshold configuration.

**Seed data shape:** 50 devices across 3 device groups (20 sensors, 20 actuators, 10 gateways). 35 online, 10 offline (last seen varied), 5 in error state. 7 days of telemetry data (temperature, humidity, battery) at 30-second intervals — downsampled to hourly for older data. 200 alerts (150 acknowledged, 30 open, 20 auto-resolved). 3 firmware versions with 1 staged rollout in progress (40% complete). 5 alert threshold configurations.

---

## 16. Restaurant / Food Service

**Archetype:** Restaurant operator managing menus, orders, tables, kitchen workflow, and multi-platform delivery.

**Core entities:** Menu Item, Modifier/Addon, Order (dine-in/takeout/delivery), Table, Reservation, Ingredient/Inventory, Shift, POS Terminal

**Gotchas:**
- **Menu structure is deeply nested** — Category > Subcategory > Item > Size > Modifiers (with modifier groups: "Choose protein" allows 1, "Choose toppings" allows up to 3). Modifiers have prices, some are free, some required, availability may differ by item.
- **Kitchen Display requires order routing** — a single order's items may go to different stations (grill, fryer, bar). Each station sees only its items, tracks prep time, and coordinates firing (apps before entrees).
- **Menu availability is time-sensitive** — breakfast menu until 11 AM, happy hour 4-6 PM, 86'd items (out of stock mid-service). The POS must prevent ordering unavailable items in real-time.
- **Ingredient-level inventory affects menu availability** — running out of chicken affects 12 menu items. The system must trace ingredient-to-item relationships.
- **Split checks and partial payments are the norm** — "Split 4 ways," "pay for my items only," "put $30 on this card and the rest on that." Tip distribution across splits adds complexity.
- **Delivery integration is multi-platform** — Uber Eats, DoorDash, Grubhub arrive through different APIs with different menu mappings, commissions, and delivery areas.

**Compliance:** Food safety (HACCP, FDA Food Code), allergen disclosure (EU requires 14 allergen categories), calorie labeling, tip reporting (IRS), liquor licensing.

**UX users expect:** Visual menu builder with modifier groups, table map with status colors, KDS ticket display with timers, 86 board, daily sales summary with prior period comparison, labor cost gauge, delivery aggregation view.

**Seed data shape:** 40 menu items across 6 categories with 3 modifier groups (proteins, toppings, sizes). 15 tables in a floor plan. 100 orders from today (60 dine-in, 25 takeout, 15 delivery from 2 platforms). 5 orders in active preparation with KDS timestamps. 2 items 86'd. 8 staff with shift schedules. 30 days of daily sales history. Allergen flags on 10 items. Tip data across 50 completed checks. 3 split-check examples.

---

## 17. Legal / Law Firm

**Archetype:** Law firm managing clients, cases, documents, time billing, and trust accounting.

**Core entities:** Client/Matter, Case, Document, Time Entry, Trust Account (IOLTA), Invoice, Court Deadline, Conflict Check

**Gotchas:**
- **Conflict of interest checking is mandatory** — before engagement, search all current and past clients, opposing parties, and related entities. A missed conflict means malpractice and bar discipline. Must be documented.
- **Trust accounting (IOLTA) has strict rules** — client funds cannot commingle with operating funds. Each client's trust balance is tracked individually. Over-disbursing is a disbarrable offense. The trust ledger must reconcile to the penny monthly.
- **Legal billing is idiosyncratic** — hourly in 6-minute increments (0.1 hour), flat fee, contingency, blended rates, LEDES format for corporate clients, pre-bills (drafts partners edit before sending). Time narratives must be detailed but not reveal privileged info.
- **Privilege classification governs document access** — documents are privileged, work product, or neither. During litigation, a privilege log must list all withheld documents. Inadvertent disclosure is a crisis.
- **Statute of limitations tracking is malpractice prevention** — calculate deadlines from triggering events, account for tolling and jurisdiction-specific rules. Provide escalating reminders. Missing a deadline is the #1 malpractice claim.
- **Document management needs version control with metadata** — drafts, redlines, executed copies, court-filed versions, opposing counsel versions must be distinguishable.

**Compliance:** Bar association rules (vary by state), ABA Model Rules, IOLTA trust rules, client confidentiality, e-discovery requirements, LEDES billing standards.

**UX users expect:** Conflict check search, trust ledger with per-client sub-ledgers, time entry with timer and 0.1-hour increments, pre-bill editing workflow, matter-centric document management, court deadline calendar with countdown.

**Seed data shape:** 20 clients with 35 matters (25 active, 5 closed, 5 archived). 500 time entries in 0.1-hour increments across 6 attorneys with varied hourly rates ($250-$750). 10 trust account deposits and 8 disbursements — balances reconcile to the penny. 50 documents across matters (drafts, executed, court-filed). 8 upcoming court deadlines (2 within 7 days). 3 pre-bills in draft. 1 conflict check result showing a flagged relationship. 200 audit log entries.

---

## 18. Non-profit / Fundraising

**Archetype:** Non-profit staff managing donors, donations, grants, programs, and fund restrictions.

**Core entities:** Donor, Donation/Gift, Campaign/Appeal, Grant, Program/Project, Beneficiary, Volunteer, Fund/Restriction

**Gotchas:**
- **Fund accounting is fundamentally different from corporate accounting** — track by restriction: unrestricted, temporarily restricted (donor-specified purpose), permanently restricted (endowment principal never spent). Spending a restricted gift on operations is a legal violation.
- **Donor stewardship has lifecycle expectations** — acknowledgment within 48 hours, year-end tax receipt (IRS requires written acknowledgment for gifts >$250), impact report showing gift use. Missing the window damages relationships and may violate IRS rules.
- **Grant management is compliance-heavy** — proposal > award > reporting. Grants have spending restrictions, reporting deadlines, matching requirements, and indirect cost caps. Expenses must be grant-allocable.
- **Recurring giving has unique churn dynamics** — credit card expiration is the #1 failure cause. Card updater services, retry logic (1st and 15th), and donor notification workflows are essential.
- **In-kind donations and volunteer hours need valuation** — donated goods must be valued at fair market value for tax receipts. Getting valuations wrong creates IRS problems.
- **Beneficiary data has extra sensitivity** — vulnerable populations (refugees, domestic violence survivors) require stronger privacy. Case worker access must be role-restricted, some data (shelter addresses) must never appear in reports.

**Compliance:** IRS 501(c)(3) rules, Form 990, grant compliance (OMB Uniform Guidance for federal grants), state charitable solicitation registration, GDPR for international donors, quid pro quo donation rules.

**UX users expect:** Donor giving history timeline, acknowledgment letter generator, fund balance dashboard (restricted vs. unrestricted), grant deadline tracker, campaign thermometer, recurring giving dashboard with failed payment alerts, volunteer hours logging.

**Seed data shape:** 150 donors (100 one-time, 30 recurring monthly, 15 major donors, 5 lapsed). 500 donations spanning 2 years across 3 funds (unrestricted, scholarship restricted, building capital). 3 active grants with spending against budget and upcoming reporting deadlines. 2 campaigns (1 active at 65% of goal, 1 completed). 5 recurring gifts with 2 failed payment (expired card). 20 volunteers with 200 hours logged. 10 in-kind donations with valuations. Year-end tax receipts for prior year.

---

## 19. Media / Streaming

**Archetype:** Content team managing a media catalog, licensing rights, distribution, and subscriber analytics.

**Core entities:** Title/Asset, Episode/Season/Series, License/Rights Window, Catalog Entry, Subscription Tier, Viewing Session, Content Rating, Distribution Channel

**Gotchas:**
- **Content rights are territorial and temporal** — a movie may be licensed for US streaming Jan-Dec 2026, UK from March, unavailable in Germany. Every availability check evaluates: territory + date range + platform + rights type (SVOD/TVOD/AVOD). Expired rights must auto-remove content.
- **Metadata standards are industry-specific** — EIDR for title IDs, per-territory content ratings (PG-13 US, 12A UK, FSK 12 Germany), available subtitles/dubs, audio formats (Stereo, 5.1, Atmos), HDR formats, aspect ratios.
- **Content ingestion is a pipeline, not an upload** — source master > quality check > transcode to multiple formats/bitrates > generate thumbnails > extract captions > DRM packaging > CDN. Each step can fail. A single title may produce 20+ output files.
- **Parental controls and ratings require player-level enforcement** — age-gated profiles, PIN for mature content, kids profiles must never serve tracked ads (COPPA).
- **Playback analytics drive the business** — start rate, completion rate, drop-off points, buffering events, concurrent stream limits, device fingerprinting for DRM. High-volume event data.
- **Content windowing is business-critical** — theatrical > premium VOD > standard VOD > pay TV > free. The dashboard must manage release windows and prevent premature availability.

**Compliance:** COPPA (kids content), regional rating board requirements, accessibility (audio description, closed captions mandated), GDPR for viewing history, royalty reporting to rights holders.

**UX users expect:** Catalog browser with territory/rights filters, rights availability calendar heatmap, ingestion pipeline status, viewing analytics with engagement curves, subscriber cohorts, content performance rankings, editorial curation tools.

**Seed data shape:** 200 titles (120 movies, 60 series with 3-10 episodes each, 20 documentaries). Rights windows for 3 territories (US, UK, Germany) — 150 titles available in US, 90 in UK, 60 in Germany, with 5 expiring within 30 days. Per-territory content ratings. 10 titles in ingestion pipeline (3 transcoding, 2 QA, 5 complete). 3 subscription tiers. 50,000 viewing session records with completion rates. 5 curated editorial rows.

---

## 20. Agriculture / Farm Management

**Archetype:** Farm operator managing fields, crops, livestock, inputs, yields, and compliance records.

**Core entities:** Field/Plot, Crop/Variety, Livestock/Herd, Input Application (seed/fertilizer/pesticide), Harvest/Yield, Weather Data, Equipment, Compliance Record

**Gotchas:**
- **Spatial data is fundamental** — fields are polygons, not names. Soil types vary within a field. Variable-rate application requires GIS integration. The dashboard needs map-based visualization with overlays.
- **Crop rotation is a multi-year dataset** — what was planted for the last 5 years affects what can be planted this year. The data model must track field-year-crop relationships across seasons.
- **Input application records are regulatory** — every pesticide application must record: product, EPA registration number, rate per acre, application method, wind speed, temperature, applicator certification, restricted entry interval. Missing any field means fines.
- **Weather integration is essential** — growing degree days, precipitation, frost dates, evapotranspiration drive decisions. On-farm weather station data must ingest automatically.
- **Livestock tracking is individual-animal granular** — ear tag/RFID, breed, birthdate, lineage, vaccinations, weight history, health events, movement history. For dairy: individual milk production records.
- **Harvest must reconcile with storage and sales** — bushels from Field 3 go to Bin A, sold to Elevator B at a specific grade and moisture. Moisture adjustment, drying costs, and basis pricing are standard calculations.

**Compliance:** EPA pesticide reporting, USDA organic certification (3-year transition), FSMA Produce Safety Rule, animal welfare regulations, water use permits, nutrient management plans, country-of-origin labeling, traceability (EU Farm to Fork).

**UX users expect:** Map-centric interface with field polygons, field activity timeline, input application form with regulatory fields, yield comparison (this year vs. 5-year average), livestock cards, weather dashboard with GDD accumulation, grain bin tracker.

**Seed data shape:** 8 fields as GeoJSON polygons with varied acreage (40-320 acres). 5 years of crop rotation history per field. 20 input application records with full regulatory fields (product, EPA number, rate, weather conditions, applicator cert). 3 years of harvest data with yields in bushels/acre. 50 livestock with individual records (ear tag, breed, vaccinations, weight history). 90 days of weather station data (temp, precip, wind). 4 grain bins with capacity and current fill levels. 2 equipment items with maintenance schedules.

---

## 21. AI / ML / Chat

**Archetype:** Team managing AI models, prompts, conversations, usage/cost tracking, and evaluation pipelines.

**Core entities:** Model/Deployment, Prompt/Template, Conversation/Thread, Message, Usage Record (tokens/cost), Evaluation/Benchmark, Knowledge Base/RAG Source, Fine-tune Job

**Gotchas:**
- **Token cost tracking requires per-request granularity** — input tokens, output tokens, cached tokens, and model-specific pricing all differ. Aggregate by user, by feature, by model, by time period. Costs can spike 100x overnight if a prompt change increases output length. Budget alerts and per-user/per-org rate limits are essential.
- **Streaming responses require a fundamentally different UX pattern** — the response builds token-by-token. The UI must handle: streaming display (token-by-token or chunk-by-chunk), cancellation mid-stream (AbortController), retry on failure mid-stream, and saving the final complete response. Standard request/response patterns don't work.
- **Prompt versioning is as critical as code versioning** — a prompt change can silently degrade output quality across the product. Track prompt versions, link them to evaluation scores, and support rollback. Treat prompts as deployment artifacts, not strings in a database.
- **Conversation history has context window limits** — you cannot send the entire conversation to the model forever. Implement truncation strategies (sliding window, summarization, hybrid) and make the strategy visible/configurable. Users will notice when the model "forgets."
- **Evaluation is not optional and is domain-specific** — "accuracy" means different things for summarization vs. code generation vs. classification. Build evaluation pipelines with domain-appropriate metrics, human review workflows, and A/B testing between prompt versions or models.
- **RAG (Retrieval-Augmented Generation) adds a whole subsystem** — document ingestion, chunking strategy, embedding generation, vector storage, retrieval quality measurement, source attribution in responses. Each has tuneable parameters that dramatically affect quality.
- **Content moderation is both input and output** — filter harmful inputs before they reach the model AND filter harmful outputs before they reach the user. Log moderation events. False positives frustrate users; false negatives create liability.
- **Model availability and latency vary unpredictably** — different models have different rate limits, different uptime, different latency profiles. Build fallback chains (try Model A, fall back to Model B), queue management, and latency monitoring per model.
- **Model deprecation is an operational lifecycle** — OpenAI deprecates models on ~6-month cycles. Fine-tuned models are stranded when their base is deprecated. Track model version per conversation and eval result. Build migration paths: deprecation alerts, evaluation re-runs against replacement models, forced migration deadlines.
- **Embedding model changes invalidate all existing vectors** — if you change from `text-embedding-ada-002` to `text-embedding-3-small`, every vector in your database is incompatible. You cannot mix vectors from different models in the same index. Track embedding model provenance per vector. Plan for dual-index migration strategy. This is an architecture decision that's nearly impossible to fix retroactively.
- **Structured output fails 1-20% of the time** — prompt-based JSON extraction is 80-95% reliable. Function calling raises it to 95-99%. Only constrained decoding (OpenAI `json_schema`, Anthropic tool-use-as-structured-output) reaches near-100%. Validate every response against the schema. Build graceful degradation for parse failures.
- **Multi-modal content changes everything** — images consume 1,000+ tokens per image (tiled pricing). Audio is time-based. The data model needs `content_blocks[]` not a `content` string. Context budget math must include media tokens. Storage requirements change dramatically.

**Compliance:** Data processing agreements with model providers, GDPR (conversation data is personal data if it contains PII), EU AI Act (risk classification, transparency requirements), CCPA, industry-specific rules if AI processes financial/medical/legal data, content moderation obligations.

**UX users expect:** Chat interface with streaming responses, conversation history with search, prompt playground/testing sandbox, usage/cost dashboard with per-model breakdown, model performance comparison charts, knowledge base/document management for RAG, evaluation results dashboard, system prompt editor with version history.

**Seed data shape:** 3 model deployments (GPT-4o, Claude Sonnet, a fine-tuned model). 5 system prompts with 3 versions each — linked to evaluation scores showing version-over-version improvement. 200 conversations (1,500 messages) spanning 30 days across 20 users. Token usage records with cost breakdown per model per day. 1 RAG knowledge base with 50 ingested documents and chunking metadata. 30 evaluation runs with domain-specific metrics. 5 flagged conversations (content moderation triggers). Rate limit events for 2 users.

---

## 22. Entertainment / Events

**Archetype:** Event organizer or venue managing shows, ticketing, artists, and attendee experience.

**Core entities:** Event, Venue/Location, Ticket/Tier, Performer/Artist, Attendee, Seating Map, Promotion/Discount, Settlement/Payout

**Gotchas:**
- **Seating maps are spatial data with business logic** — reserved seating requires a visual seat picker where each seat has a section, row, seat number, price tier, accessibility designation, and obstructed-view flag. Hold-release patterns (seats held for 10 minutes during checkout) prevent double-selling.
- **Ticket inventory has high-concurrency pressure** — 10,000 people trying to buy 500 tickets in 30 seconds. Standard database locks won't hold. Queue-based purchase flows, waiting rooms, and atomic inventory decrement (optimistic locking or database-level constraints) are required.
- **Dynamic/surge pricing is expected** — prices change based on demand, time-to-event, and remaining inventory. Early bird, last-minute, and demand-based tiers. The pricing engine must be fast and auditable.
- **Refund and transfer policies vary per event** — some events allow transfers (name change on ticket), some allow refunds until X days before, some are final sale. Policies must be per-event configurable.
- **Settlement/payout to artists and venues is a financial workflow** — ticket revenue minus fees, taxes, and venue costs, split among multiple parties. This is accounting with multiple payees per event.
- **Check-in and access control are real-time** — QR code/barcode scanning at doors, preventing duplicate entry (a scanned ticket can't enter twice), VIP vs. GA routing, and real-time attendance counts.
- **Multi-day and recurring events add calendar complexity** — festivals with multiple stages and overlapping acts, weekly show series, season passes valid for specific dates.
- **ADA accessibility is structural data, not just UI** — every seat needs an `accessibility_type` field (wheelchair, companion, limited mobility, hearing impaired). Accessible seats must be distributed throughout the venue (legal requirement), not clustered. Companion seats sell with accessible seats (1:1 ratio). If you build the seating map without accessibility types, you need a schema migration.
- **Ticket fraud and bot detection are day-one concerns** — 10,000 bots hitting your endpoint in 30 seconds. Purchase velocity detection, CAPTCHA during high-demand on-sales, verified fan queues, dynamic QR codes that change periodically, device fingerprinting.
- **Venue configurations are one-to-many** — a single venue hosts different events with different layouts: concert (standing floor, 2,500 cap) vs. gala (seated tables, 800 cap) vs. conference (theater-style, 1,200 cap). Each configuration has its own seating map.

**Compliance:** ADA accessibility for venues, local fire code capacity limits, sales tax on tickets (varies by jurisdiction), age restrictions for certain events, anti-scalping laws (jurisdiction-specific), payment card industry compliance.

**UX users expect:** Visual seating map editor, drag-and-drop event scheduling, ticket sales dashboard with real-time counters, check-in scanner interface (mobile-optimized), settlement/payout breakdown per event, marketing campaign tracking (promo code performance), attendee demographics.

**Seed data shape:** 10 events (3 upcoming, 5 past, 2 recurring weekly). 1 venue with a 500-seat map (sections, rows, accessibility seats, 2 obstructed-view). 800 tickets sold across events with 3 price tiers. 5 promo codes (2 active, 2 expired, 1 maxed out). 2 past events with completed settlements showing revenue splits. 300 check-in records for past events (including 5 duplicate scan attempts). 1 upcoming event with 60% sold and dynamic pricing active. 3 refunded tickets and 2 transfers.

---

## 23. Gaming / Esports

**Archetype:** Game studio or platform managing players, matches, virtual economies, seasons, and competitive integrity.

**Core entities:** Player/Account, Match/Game Session, Leaderboard/Ranking, Virtual Item/Currency, Season/Battle Pass, Tournament/Bracket, Ban/Sanction, Achievement

**Gotchas:**
- **Virtual economies require fintech-level rigor** — in-game currency (earned and purchased), item trading, marketplace transactions. Use integer math for all currency. Duplication exploits (creating currency/items from nothing) are the #1 game-breaking bug. Transaction logs must be append-only and auditable.
- **Matchmaking is a real-time system with fairness constraints** — skill-based rating (Elo, Glicko-2, TrueSkill), queue times vs. match quality trade-offs, party/group matching, regional latency requirements, and smurf detection (high-skill players on new accounts).
- **Leaderboards at scale need specialized data structures** — sorted sets (Redis ZSET) or materialized views, not `ORDER BY score DESC LIMIT 100` on every page load. Real-time vs. periodic refresh. Per-region, per-season, per-mode leaderboards multiply the problem.
- **Season/battle pass progression is a time-bound engagement system** — XP accumulation, tier rewards, premium vs. free track, catch-up mechanics for late joiners, end-of-season reward distribution. Resetting and archiving season data while preserving rewards is a migration event.
- **Anti-cheat and ban management is an ongoing war** — detection signals (impossible stats, speed hacks, aimbot patterns), ban types (temporary, permanent, shadow ban, hardware ban), appeal workflows, and ban evasion detection (same hardware/IP with new account).
- **Loot box / gacha compliance varies by country** — Belgium and Netherlands ban paid loot boxes, Japan regulates "kompu gacha," China requires published drop rates, Apple/Google require disclosure. The same game may need different monetization per region.
- **Player data for minors triggers COPPA/GDPR-K** — under-13 accounts need parental consent, restricted chat, restricted spending, no behavioral advertising. Age gating must be real, not a "click yes" checkbox.
- **Real-time multiplayer state is not a database concern** — match state lives in game servers, not in PostgreSQL. The dashboard reads from match result records, player stats aggregations, and event streams. Don't try to query live match state from the admin panel.
- **Cross-platform account linking is an identity architecture problem** — a player has one identity but accounts on Steam, PSN, Xbox, Nintendo, Epic. Platform policies restrict data sharing (Sony historically blocked cross-progression). Purchased items may be platform-locked. Linking must be reversible. Data model: `Player` has many `PlatformLink` records.
- **Live service content pipeline has external blocking dependencies** — seasonal content goes through platform certification (Sony, Microsoft, Nintendo each certify separately, 1-5 business days, may reject). The dashboard needs: release calendar with certification status per platform, rollback capability, feature flags for gradual rollout.
- **Player behavioral analytics drive LiveOps** — churn risk scoring, engagement segments (whale/dolphin/minnow), content exhaustion detection, social graph health. This isn't just analytics — it drives automated interventions (re-engagement offers when churn probability exceeds threshold).
- **Guild/clan management is a social governance system** — creation, invitations, roles (leader/officer/member), shared resources/bank, guild progression, inter-guild competition, moderation, dissolution and asset distribution.

**Compliance:** COPPA (minors), GDPR (player data, right to deletion of accounts), loot box regulations (Belgium, Netherlands, Japan, China), ESRB/PEGI rating compliance, gambling regulations (if real-money is involved), platform ToS (Steam, PlayStation, Xbox, App Store policies).

**UX users expect:** Player lookup with match history, ban/moderation queue with evidence viewer, leaderboard browser by season/region/mode, virtual economy dashboard (currency in circulation, inflation metrics), tournament bracket editor, season pass progression analytics, report/appeal workflow, real-time concurrent player counts.

**Seed data shape:** 500 player accounts (400 active, 50 inactive, 30 banned — 5 permanent, 25 temporary). 2,000 match records across 2 game modes with Elo/MMR ratings. 3 seasons (1 current, 2 archived) with battle pass progression data. Virtual economy: 10 item types, 5,000 transactions (purchases, trades, drops), currency balances per player. 1 active tournament bracket (16 players, quarterfinal stage). 20 player reports with evidence (screenshots, replay IDs). 3 ban appeals pending review. Leaderboards for current season by region (NA, EU, APAC).

---

## 24. Cybersecurity / SOC

**Archetype:** Security team monitoring threats, investigating incidents, managing vulnerabilities, and tracking compliance.

**Core entities:** Alert/Event, Incident, Vulnerability, Asset/Host, Threat Intelligence Feed, Investigation/Case, Policy/Rule, Compliance Control

**Gotchas:**
- **Alert volume is overwhelming by design** — a SOC receives thousands to millions of events per day. Without correlation (grouping related alerts into incidents), deduplication, and automated triage, the dashboard is unusable. Build for filtering and prioritization, not for showing everything.
- **MITRE ATT&CK framework is the shared language** — every alert and incident should map to ATT&CK tactics and techniques. Analysts expect to see TTPs (Tactics, Techniques, Procedures), not just raw log lines.
- **Mean Time to Detect (MTTD) and Mean Time to Respond (MTTR) are the KPIs** — the dashboard must track these per incident type, per analyst, over time. They drive staffing and process decisions.
- **Investigation workflows are non-linear** — an analyst pivots from an IP to a host to a user to a file hash to another host. The dashboard must support this "investigation graph" pattern — click an IOC (Indicator of Compromise), see everything related.
- **Threat intelligence feeds are external data integrations** — STIX/TAXII format feeds, commercial threat intel (Recorded Future, CrowdStrike), OSINT feeds. IOCs (IPs, domains, file hashes) must be enriched and correlated against internal telemetry.
- **Chain of custody matters for forensics** — evidence collected during an investigation (memory dumps, disk images, log exports) must be hashed, timestamped, and stored immutably. This is legal evidence.
- **Compliance posture tracking is continuous** — SOC 2, ISO 27001, NIST CSF, PCI DSS, HIPAA controls mapped to evidence. Each control has a status (met/partially met/not met) with supporting evidence and review dates.
- **SOAR playbook execution is how modern SOCs actually respond** — automated workflows: phishing alert > extract URLs > check threat intel > isolate endpoint > reset credentials > notify user. Dashboard needs: playbook builder, execution trace per incident, manual approval gates, playbook metrics. Without SOAR, the dashboard is read-only.
- **Vulnerability management is a full lifecycle, not just scan results** — discovery > enrichment (add EPSS score, check CISA KEV catalog) > prioritization (CVSS + exploitability + asset criticality + exposure) > assignment with SLA > remediation > verification rescan > exception management. CVSS alone is inadequate — a CVSS 10 on an air-gapped test server is lower priority than a CVSS 7.5 on an internet-facing production database.
- **Attack surface management is distinct from vulnerability scanning** — external asset discovery (including shadow IT), exposure validation, cloud security posture (CSPM), certificate monitoring, DNS/subdomain takeover risks. This is what an attacker sees from outside.
- **Threat hunting is proactive, not reactive** — analysts form hypotheses and search historical data for evidence. Dashboard needs: hunting query workspace, campaign tracker, and the ability to convert findings into automated detection rules.

**Compliance:** SOC 2, ISO 27001, NIST CSF, PCI DSS, HIPAA (if healthcare data), GDPR (incident notification within 72 hours), industry-specific regulations, breach notification laws (vary by state/country).

**UX users expect:** Alert queue with severity/priority, incident timeline with event correlation, threat map (geographic), MITRE ATT&CK matrix heatmap, vulnerability scanner results with CVSS scores, asset inventory with risk scores, compliance control matrix with evidence status, runbook/playbook execution tracker.

**Seed data shape:** 200 assets (servers, endpoints, network devices) across 3 network segments. 5,000 security events spanning 7 days. 15 incidents (10 resolved, 3 investigating, 2 new) mapped to MITRE ATT&CK TTPs. 100 vulnerabilities from scan results with CVSS scores (20 critical, 30 high, 50 medium). 3 threat intel feeds with 500 IOCs. 1 active investigation with a 5-hop pivot chain (IP > host > user > file hash > second host). 40 compliance controls with evidence status (30 met, 5 partially met, 5 not assessed). MTTD and MTTR metrics for last 90 days.

---

## 25. Construction / Field Services

**Archetype:** Construction firm or field service company managing jobs, crews, inspections, permits, and equipment.

**Core entities:** Project/Job Site, Work Order, Crew/Worker, Inspection, Permit, Equipment/Asset, Daily Log, Change Order, Drawing/Plan

**Gotchas:**
- **The dashboard must work offline and on mobile** — field workers are on job sites with poor connectivity. Forms for daily logs, inspections, and time tracking must work offline and sync when connectivity returns. This is a fundamental architecture decision, not a nice-to-have.
- **Change orders are how construction projects actually work** — the original scope changes constantly. Each change order has a cost impact, schedule impact, approval workflow, and audit trail. The budget is the original contract + sum of approved change orders. Tracking "budget vs. actual" without change orders is meaningless.
- **Permit tracking has jurisdictional dependencies** — different municipalities have different permit types, fee structures, inspection requirements, and processing times. A permit's status (applied > under review > approved > inspection scheduled > passed) is a state machine with external dependencies.
- **Safety compliance is non-negotiable and heavily regulated** — OSHA incident reporting (within 24 hours for hospitalizations, 8 hours for fatalities), daily safety logs, toolbox talks, PPE tracking, and near-miss reporting. The dashboard must make safety reporting fast and frictionless.
- **Drawing/plan management requires version control with superseding** — Revision A is superseded by Revision B. Workers must always see the latest revision. Building from an outdated drawing is a catastrophic (and common) mistake.
- **Progress tracking is visual and percentage-based** — "Foundation 100%, Framing 60%, Electrical 20%, Plumbing 0%." Progress photos linked to dates and locations. Earned value management (EVM) for financial progress vs. schedule progress.
- **Prevailing wage requirements apply to government contracts** — Davis-Bacon Act (federal), state prevailing wage laws. Workers on covered projects must be paid specific rates by trade classification. Tracking certified payroll (WH-347 form) is a reporting requirement.
- **Subcontractor payment applications (AIA G702/G703) are the industry-standard billing workflow** — used on 78% of commercial projects. The G702 is the cover sheet, G703 is the Schedule of Values (each line item with scheduled value, completed work, materials stored, retainage, balance). Lien waivers (4 types: conditional/unconditional for progress/final) must accompany each pay app. Missing this means the dashboard can't handle billing.
- **RFI and submittal tracking are mission-critical document workflows** — an RFI is a formal question when drawings are unclear. A submittal is a document sent for architect approval before installation. Both have: numbered tracking, routing workflows, response deadlines with escalation, status tracking. A project may have 200-500 RFIs and 300-1000 submittals.
- **BIM integration is increasingly table-stakes** — 3D models with metadata (materials, costs, schedule). Dashboard integration: click a wall to see its RFI, 4D scheduling (3D + time), clash detection results, model version management linked to drawing revisions.
- **Bonding and insurance certificate (COI) tracking prevents site shutdowns** — every subcontractor needs certificates of insurance (ACORD 25 form) with the GC as additional insured. Expired COI = sub can't work. Automated expiration tracking across 20+ subs is essential.
- **Weather delay tracking feeds the claims process** — daily weather recording, delay classification (full/partial day), contractual weather days (only delays beyond the anticipated count trigger extensions), schedule impact analysis linking weather to critical-path activities.

**Compliance:** OSHA (safety), Davis-Bacon (prevailing wage for government work), state contractor licensing, building codes (vary by jurisdiction), environmental regulations (stormwater, hazmat), lien laws and payment bond requirements.

**UX users expect:** Mobile-first daily log entry, photo capture with GPS tagging, punch list with completion tracking, Gantt chart with critical path, equipment utilization calendar, safety incident dashboard, budget tracker with change order waterfall, drawing viewer with revision indicator.

**Seed data shape:** 3 projects (1 active at 40% complete, 1 in pre-construction, 1 recently completed). 15 crew members across 4 trades. 30 daily logs with weather, crew counts, and work descriptions. 5 change orders on the active project ($5K-$50K impact each) — 3 approved, 1 pending, 1 rejected. 10 permits in varied states. 3 drawing sets with 2 revisions each (Rev A superseded by Rev B). 20 punch list items (12 complete, 8 open). 2 safety incidents (1 near-miss, 1 recordable). 8 equipment items with utilization logs. Budget with original contract + change order waterfall.

---

## 26. Marketplace / Platform

**Archetype:** Two-sided platform connecting buyers and sellers (or providers and consumers), managing trust, transactions, and disputes.

**Core entities:** Seller/Provider, Buyer/Consumer, Listing, Transaction/Order, Review/Rating, Dispute, Commission/Fee, Payout, Verification

**Gotchas:**
- **Two-sided means two dashboards (at least)** — sellers see their listings, orders, payouts, and performance. Buyers see their orders, reviews, and saved items. Platform admins see everything plus disputes, compliance, and marketplace health. Three distinct RBAC contexts, not one.
- **Trust and safety is a dedicated function** — user verification (ID, business license, background check), content moderation (listing photos, descriptions), fraud detection (fake reviews, shill bidding, payment fraud), and abuse reporting. This is not an afterthought; it's a full team's worth of tooling.
- **Escrow/payment splitting is complex** — buyer pays > platform holds > seller fulfills > platform releases to seller minus commission. Refund flows, dispute holds, partial fulfillment, split payments to multiple sellers in one order. You need a payment orchestration layer (Stripe Connect, PayPal for Marketplaces).
- **Commission structures are rarely simple** — they vary by category, by seller tier, by volume, by promotional period. "15% on electronics, 8% on books, 5% for Gold sellers, 0% for the first 90 days" is a real commission table.
- **Search and discovery are core product features** — not just a search bar. Relevance ranking, category navigation, filters (price, location, rating, availability), promoted/sponsored listings, and personalized recommendations. Search quality directly drives GMV.
- **Dispute resolution is a three-party workflow** — buyer claims item not received, seller provides tracking, platform arbitrates. Escalation tiers, evidence submission, resolution deadlines, and appeal processes. The dispute dashboard is as important as the order dashboard.
- **Review integrity affects the entire marketplace** — fake review detection, review gating (only verified purchasers), review response from sellers, rating aggregation with recency weighting, and review moderation for prohibited content.
- **Geographic and regulatory complexity** — a marketplace operating in multiple countries must handle: local payment methods, local tax collection and remittance (marketplace facilitator laws in 46+ US states — the marketplace, not the seller, collects and remits), local consumer protection, and local seller verification requirements.
- **Seller onboarding is a multi-step verification pipeline** — identity verification (KYC/KYB), bank account verification (micro-deposits or Plaid), tax form collection (W-9/W-8BEN), 1099-K threshold tracking, restricted category approval. The pipeline is a state machine: `registered > identity_verified > bank_verified > tax_form_verified > active`. Blocking at any step needs clear communication.
- **Category taxonomy is a schema-per-category problem** — each leaf category has different required attributes: "Laptops" needs RAM/storage/screen; "Dresses" needs size/color/material. Attribute types include enums, free text, numeric with units. Changing taxonomy after thousands of listings exist is a major migration.
- **Multi-channel inventory sync prevents overselling** — sellers list on your marketplace + Amazon + eBay. A sale on Amazon must decrement your quantity within seconds. Real-time sync, safety stock buffers, centralized order management across channels.
- **Shipping integration is the physical fulfillment layer** — rate calculation (carrier APIs), label generation, tracking integration, shipping SLA enforcement (ship within X days or face penalties), return logistics. Makes or breaks buyer trust.
- **Seller analytics is a dashboard-within-a-dashboard** — every seller needs: sales trends, top listings, conversion rates, traffic sources, return rate, satisfaction metrics, payout history, listing quality scores with improvement recommendations.

**Compliance:** Marketplace facilitator tax laws (US, state-by-state), consumer protection (EU Consumer Rights Directive, right of withdrawal), payment services regulations (PSD2 in EU), KYC/AML for seller onboarding, digital services act (EU, content moderation obligations), platform liability laws.

**UX users expect:** Seller dashboard with earnings/payouts/performance, buyer order tracking, admin moderation queue, dispute resolution workflow with evidence viewer, marketplace health dashboard (GMV, take rate, seller churn, buyer satisfaction), category management, search analytics (top queries, zero-result queries), promoted listing management.

**Seed data shape:** 30 sellers (20 active, 5 new/unverified, 3 suspended, 2 churned) across 3 tiers with different commission rates. 100 listings across 8 categories with varied pricing. 200 orders spanning 60 days (160 completed, 15 in transit, 10 pending, 5 disputed, 5 refunded, 5 cancelled). 500 reviews with ratings (4 flagged for moderation — 2 suspected fake). 3 active disputes at different stages. 10 payouts completed, 2 pending. Search analytics: top 20 queries with click-through rates, 5 zero-result queries. 5 promoted listings with spend and impression data. GMV and take-rate metrics for 6 months.

---

## 27. Insurance / InsurTech

**Archetype:** Insurance company or MGA managing policies, claims, underwriting, and agent commissions.

**Core entities:** Policy, Claim, Policyholder, Agent/Broker, Underwriting Submission, Premium, Coverage, Loss/Event

**Gotchas:**
- **Policy lifecycle is a complex state machine** — quote > bind > issue > endorse > renew > cancel > reinstate. Each state change has financial implications (premium adjustments, refunds, earned vs. unearned premium calculations). Mid-term endorsements (changes to coverage) trigger pro-rated premium recalculation.
- **Claims processing (FNOL to settlement) is the core workflow** — First Notice of Loss intake > assignment to adjuster > investigation > reserve setting (estimated payout) > negotiation > settlement > payment. Reserve accuracy affects the company's financial position. Subrogation (recovering from a third party) adds another dimension.
- **Underwriting is a risk assessment pipeline** — submission intake > data enrichment (third-party data: credit, claims history, property data) > risk scoring > pricing > terms/conditions > bind or decline. Automated vs. manual underwriting rules determine which submissions require human review.
- **Rating engines calculate premiums from dozens of variables** — age, location, coverage limits, deductibles, claims history, credit score, industry code, building construction type. Rate tables are jurisdiction-specific and change with regulatory filings. Never hardcode rates.
- **Insurance has its own data standards** — ACORD forms (standard data exchange formats), ISO/NAIC lines of business codes, policy administration system integration standards. Using non-standard formats creates integration barriers with carriers and reinsurers.
- **Regulatory filings are per-state** — each state Department of Insurance has different requirements for rate filings, form filings, annual statements, and market conduct examinations. A policy sold in 50 states has 50 regulatory contexts.

**Compliance:** State DOI regulations (vary per state), NAIC model laws, HIPAA (for health insurance), Gramm-Leach-Bliley Act (privacy), anti-rebating laws, surplus lines filing requirements, producer licensing.

**UX users expect:** Policy lifecycle timeline, claims dashboard with severity and reserve tracking, underwriting submission queue, agent commission statements, loss ratio visualizations, renewal pipeline, FNOL intake form with guided workflow.

**Seed data shape:** 100 policies across 3 lines (auto, home, commercial) in varied states (active, expired, cancelled, pending renewal). 30 claims spanning 6 months (15 open at various stages, 15 closed with settlements). 10 agents with commission schedules. 20 underwriting submissions (10 bound, 5 declined, 5 in review). Premium data with earned/unearned splits. 5 endorsements on active policies.

---

## 28. Telecommunications / ISP

**Archetype:** Telecom or ISP managing subscribers, service provisioning, network operations, and usage-based billing.

**Core entities:** Subscriber/Account, Service Plan, Circuit/Connection, Network Element, Trouble Ticket, Usage Record (CDR), Invoice, Coverage Area

**Gotchas:**
- **Service provisioning is a multi-system orchestration** — activating a new subscriber touches: billing system (create account), network (provision bandwidth, assign IP, configure RADIUS), hardware (ship modem/router, schedule install), and CRM (create contact, schedule onboarding). Each step can fail independently. Rollback on failure is a saga/compensation problem.
- **Usage-based billing with CDRs (Call Detail Records) is high-volume metering** — millions of CDR events per day. Each record: caller, callee, start time, duration, data transferred, cell tower, service type. Rating (converting CDR events to charges) applies complex rules: time-of-day rates, bundle allowances, roaming surcharges, family plan sharing, rollover data.
- **Network monitoring is a real-time operations concern** — SNMP traps, syslog events, performance metrics (latency, packet loss, utilization) from thousands of network elements. Outage detection, root cause analysis, SLA compliance tracking. The dashboard must show network health maps with drill-down to individual elements.
- **Trouble ticket SLAs are regulated** — the FCC and state PUCs mandate response and resolution times for service outages. Telecom SLAs are contractual AND regulatory, unlike typical helpdesk SLAs.
- **Number portability is a regulated workflow** — customers porting phone numbers in/out. The Local Number Portability process has specific timelines (simple port: 1 business day), and losing carriers cannot block ports. Tracking port status and compliance is dashboard functionality.

**Compliance:** FCC regulations, state PUC rules, CALEA (lawful intercept), CPNI (Customer Proprietary Network Information) privacy, E-911 requirements, universal service fund contributions, number portability regulations.

**UX users expect:** Subscriber account dashboard with service status, network health map with outage overlay, trouble ticket queue with SLA timers, usage analytics (data/voice/text), provisioning workflow tracker, coverage map, invoice management with CDR detail drill-down.

**Seed data shape:** 200 subscribers across 4 plan types (basic, standard, premium, business). 50,000 CDR events spanning 30 days. 10 network elements with health metrics. 30 trouble tickets (20 resolved, 10 open with SLA tracking). 3 service outages with affected subscriber counts. 5 active number port requests. Monthly invoices with usage breakdown.

---

## 29. Energy / Utilities

**Archetype:** Utility company or energy provider managing meters, consumption, grid operations, and regulatory compliance.

**Core entities:** Meter, Customer/Account, Rate Schedule, Usage Reading, Outage, Work Order, Regulatory Filing, Renewable Certificate

**Gotchas:**
- **Meter data management is the foundation** — smart meters report consumption at 15-minute intervals. A utility with 500,000 meters generates 48 million readings per day. This is time-series data requiring specialized storage. Data validation (detecting faulty meters, estimated reads, meter tampering) is a continuous process.
- **Rate schedules are regulated and complex** — time-of-use rates (different price per kWh by time of day and season), tiered rates (first 500 kWh at one price, next 500 at another), demand charges (peak kW usage), net metering (solar customers selling back to grid). Rate changes require regulatory approval and public notice periods.
- **Outage management is safety-critical** — outage detection (from meter last-gasp signals, customer reports, SCADA), crew dispatch, estimated restoration time, rolling status updates to affected customers. Mutual aid coordination during major events (storms). Regulatory reporting of outage duration and frequency (SAIDI, SAIFI metrics).
- **Demand forecasting drives grid operations** — predicting load 15 minutes, 1 hour, 1 day, and 1 year ahead. Weather-dependent. Affects wholesale energy procurement, generation dispatch, and grid stability. Machine learning models are standard.
- **Renewable energy certificates (RECs) are tradeable compliance instruments** — each MWh of renewable generation produces a REC. Tracking generation, certification, sale, and retirement of RECs is a compliance requirement for renewable portfolio standards.

**Compliance:** NERC (reliability standards), FERC (wholesale markets), state PUC rate regulation, Green Button (data access standard), EPA emissions reporting, renewable portfolio standards, PURPA (qualifying facilities), cybersecurity (NERC CIP for critical infrastructure).

**UX users expect:** Grid operations dashboard with real-time load, outage map with affected customers and ETR, customer consumption charts with rate tier visualization, demand response event management, meter health monitoring, regulatory filing tracker, renewable generation dashboard.

**Seed data shape:** 500 meters with 30 days of 15-minute interval readings. 3 rate schedules (residential, commercial, time-of-use). 10 outage events (5 resolved, 5 active with crew assignments). 200 customer accounts with billing history. 50 work orders across types (meter install, line repair, tree trimming). 30 days of demand/generation data for forecasting.

---

## 30. Government / Public Sector

**Archetype:** Government agency managing permits, citizen services, public records, procurement, and transparency.

**Core entities:** Permit/License, Application, Citizen/Applicant, Case, Public Record, Procurement/RFP, Budget Line Item, FOIA Request

**Gotchas:**
- **Permit and licensing workflows vary by jurisdiction and type** — building permits, business licenses, event permits, liquor licenses — each has different requirements, review workflows, fee schedules, and inspection processes. A single agency may administer 50+ permit types. The workflow engine must be configurable per permit type, not hardcoded.
- **Public records and FOIA compliance have strict timelines** — federal FOIA requires acknowledgment within 20 business days. State open records laws vary (some require response within 3-5 business days). The dashboard must track: request intake, review/redaction workflow, cost estimation, response deadline, appeal process. Overdue requests are legal violations.
- **Procurement is heavily regulated** — RFP lifecycle: draft > legal review > public posting > vendor questions (all answers must be shared equally) > proposal receipt > evaluation (scoring rubrics, conflict of interest declarations) > award > protest period > contract execution. Transparency requirements mean most records are public. Bid tabulations, scoring sheets, and award justifications must be accessible.
- **Budget transparency is legally required** — citizens have a right to see how public money is spent. Dashboards may need public-facing budget explorers (expenditures by department, fund, program). Data must align with government accounting standards (GASB for US, IPSAS international).
- **Accessibility is legally mandated, not optional** — Section 508 compliance is required for all federal systems and most state/local. This goes beyond WCAG: specific testing with assistive technology (JAWS, NVDA, VoiceOver), document accessibility (all published PDFs must be tagged), and VPAT (Voluntary Product Accessibility Template) documentation.

**Compliance:** Section 508 / ADA, FedRAMP (cloud security for federal), FOIA / state open records laws, GASB accounting standards, procurement regulations (FAR for federal, state-specific), records retention schedules, data sovereignty requirements.

**UX users expect:** Permit application portal with status tracker, public-facing searchable permit database, procurement portal with RFP listing and vendor registration, budget transparency dashboard, FOIA request tracker with deadline countdown, case management for inspections/enforcement, GIS integration for spatial permits (zoning, land use).

**Seed data shape:** 50 permit applications across 5 types (building, business, event, liquor, sign) in varied states. 20 procurement actions (10 active RFPs, 5 awarded, 5 closed). 15 FOIA requests (5 open with deadline tracking, 10 completed). Budget data across 8 departments with line-item detail. 30 inspection records. 5 public meeting agendas with attached documents.

---

## 31. Recruiting / ATS (Applicant Tracking)

**Archetype:** HR or recruiting team managing job postings, candidates, interview pipelines, and hiring compliance.

**Core entities:** Job Requisition, Candidate, Application, Interview, Offer, Hiring Pipeline Stage, Evaluation/Scorecard, Source/Channel

**Gotchas:**
- **The hiring pipeline is a funnel with configurable stages** — applied > phone screen > technical interview > onsite > offer > accepted/rejected. But stages vary by role (engineering has a coding test, sales has a role play). Each stage has: assigned interviewers, scorecards/rubrics, pass/fail criteria, and time-in-stage SLAs. The pipeline must be configurable per job requisition.
- **Interview scheduling is a constraint satisfaction problem** — coordinate availability across 3-6 interviewers, candidate timezone, room availability, and buffer time between interviews. Integration with Google Calendar / Outlook is essential. Self-scheduling links (candidate picks from available slots) reduce coordination overhead.
- **EEO compliance requires specific data collection and reporting** — US employers with 100+ employees must file EEO-1 reports (demographics by job category). Demographic data (race, gender, veteran status, disability) must be collected voluntarily and kept separate from hiring decisions — interviewers must NOT see this data. The dashboard must enforce this separation.
- **OFCCP compliance for government contractors** — federal contractors must maintain applicant flow logs, track hiring disposition by demographic group, and demonstrate non-discriminatory hiring practices. Internet Applicant Rule defines who counts as an "applicant" (must meet basic qualifications and express interest).
- **Candidate experience is measurable and matters** — time-to-response (acknowledge application within 24-48 hours), time-in-stage (candidates ghosted in "under review" for weeks), interview feedback turnaround, and offer response time. Track these as SLAs. A poor candidate experience damages employer brand.
- **Source attribution drives recruiting spend** — which channels (LinkedIn, Indeed, referrals, career page, agencies) produce the most hires, at what cost per hire? Track source at application time AND at hire time (the source of the application, not just the source of the candidate record). Agency placements have fee structures (typically 15-25% of first-year salary) that must be tracked.

**Compliance:** EEO-1 reporting, OFCCP (federal contractors), EEOC anti-discrimination, ban-the-box laws (jurisdiction-specific — some prohibit asking about criminal history), FCRA (Fair Credit Reporting Act for background checks), state-specific salary history ban laws, GDPR (EU candidates), data retention policies for applicant data.

**UX users expect:** Kanban pipeline view per job (candidates as cards moving through stages), interview scheduling with calendar integration, scorecard/rubric forms, offer letter generation, candidate profile with full activity timeline, sourcing analytics (cost per hire by channel), compliance reporting (EEO-1 data, time-to-fill, demographic disposition), hiring manager dashboard (their open reqs, pending interviews, candidates awaiting decision).

**Seed data shape:** 10 open job requisitions across 4 departments. 200 candidates with varied pipeline stages (100 applied, 40 phone screened, 20 interviewing, 10 offer stage, 5 hired, rest rejected/withdrawn). 50 completed scorecards across interviewers. 3 sourcing channels with cost data. 5 accepted offers and 2 declined. EEO demographic data (voluntary, separated from hiring data). 3 agency placements with fee tracking. Interview schedules across 2 weeks.

---

## 32. Co-working Space / Shared Office

**Archetype:** Co-working operator managing spaces, memberships, bookings, access control, and community.

**Core entities:** Location/Building, Space (desk/office/meeting room/event area), Member, Membership Plan, Booking/Reservation, Invoice, Access Event (door entry/exit), Visitor, Amenity

**Gotchas:**
- **Space inventory is a multi-dimensional availability problem** — a hot desk is available per-half-day, a private office is leased monthly, a meeting room is bookable by the hour, an event space is reserved by the day. Each space type has different booking rules, cancellation policies, and pricing models. A single "bookings" table must handle all of these with type-specific validation.
- **Membership plans combine access rights + credits + amenities** — a "Pro" membership might include: unlimited hot desk access, 10 meeting room hours/month (credits that roll over or expire), guest passes (5/month), mail handling, printing credits (100 pages), and access to all locations. Each component must be tracked independently. Credit consumption, rollover rules, and overage billing add complexity that a simple subscription model misses.
- **Occupancy and capacity management have legal and contractual limits** — fire code limits per floor/room, lease agreements with the building may cap total members, desk-to-member ratios for hot desking (typically 1:3 to 1:5 — more members than desks, betting on not everyone showing up simultaneously). The dashboard must track real-time occupancy vs. capacity and alert before limits are exceeded.
- **Access control integration is physical infrastructure** — door locks, turnstiles, and key card systems (Kisi, Salto, Brivo, HID) must integrate with the membership system. A member whose plan expires at midnight should lose door access at midnight. Visitor pre-registration generates temporary access codes. The access log (who entered which door when) is both a security feature and an occupancy data source.
- **Meeting room booking has the same complexity as calendar scheduling** — recurring bookings, buffer time between meetings (15 min for cleaning), no-show detection (room booked but nobody entered — release after 15 minutes), equipment requirements (projector, whiteboard, video conferencing), catering add-ons, and multi-room bookings for large events. Integrate with Google Calendar / Outlook so bookings appear on members' calendars.
- **Revenue is a mix of recurring + usage-based + one-off** — monthly membership fees (recurring), meeting room overage hours (usage-based), day passes (one-off), event space rentals (one-off with custom pricing), printing/scanning charges (per-use), mail handling fees (monthly add-on), and virtual office plans (address-only, no physical access). The billing system must handle all of these on a single invoice.
- **Community and networking features differentiate co-working from generic office rental** — member directory (opt-in profiles with skills/industry), event calendar (workshops, networking, lunch-and-learns), announcements/news feed, perks and partner discounts, member-to-member messaging or introductions. These are not core to the space management but are expected by members.
- **Multi-location management multiplies everything** — a co-working brand with 5 locations needs: per-location capacity, per-location access control, membership plans that work across locations (or are location-specific), and consolidated reporting across all locations. A member with an "all-access" plan should be able to book at any location. Financial reporting needs both per-location P&L and consolidated views.
- **The sales pipeline (lead-to-member funnel) is a first-class feature** — inquiry capture from website, tour scheduling (self-service booking), automated follow-up, proposal/agreement generation, pipeline stages (Lead > Tour Booked > Tour Completed > Proposal Sent > Signed). Every major platform (Nexudus, OfficeRnD, Optix) includes this. Conversion metrics (inquiry-to-tour rate, tour-to-member rate) drive growth.
- **Virtual office and mail handling is a significant revenue stream (up to 35%)** — virtual members pay for a business address without physical access. Mail arrives > staff logs it (sender, type) > member gets notification > member chooses action (scan, forward, hold, discard) > billing per scan/forward or flat monthly fee. This is an entire workflow with its own data model and billing rules.
- **Visitor management is a structured workflow, not just a guest list** — pre-registration (host creates entry) > visitor receives email with QR code > arrival at kiosk (scan, photo capture, optional ID verification) > digital document signing (NDA, safety waiver) > badge printing > host notification (push/Slack/SMS) > temporary access credentials > auto-checkout on expiry. Full audit trail of all visitors.
- **Network/WiFi management is operationally critical** — per-tenant VLAN isolation for enterprise members, bandwidth allocation by tier, captive portal tied to membership system, guest WiFi with time limits, print/scan management per member account.
- **Member engagement scoring predicts churn** — composite of door entries, desk bookings, event attendance, community app usage, meeting room bookings. Declining scores flag at-risk members before they cancel. NPS tracking, referral programs with credit tracking, and member milestone recognition (anniversary, usage milestones) drive retention.

**Compliance:** Fire code occupancy limits, ADA accessibility for physical spaces, local business licensing, zoning compliance (not all commercial zones permit co-working), data protection for access logs (personal data under GDPR), payment processing (PCI), lease/sublease regulations, health and safety (fire suppression, emergency exits, first aid, Emergency Action Plan), liability waivers with version tracking, insurance requirements (general liability, professional, cyber, workers' comp), 24/7 access liability (different legal exposure with no staff present).

**UX users expect:** Floor plan view with real-time desk/room availability (color coding), meeting room booking calendar with time-slot grid, member check-in dashboard (who's in the building now), membership management with plan comparison, CRM pipeline board (lead-to-member funnel), invoice/billing history, access log viewer, occupancy analytics (peak hours, utilization by space type), community member directory, event calendar with RSVP, visitor check-in kiosk mode, mail handling queue, network health status, financial KPIs (RevPAD ~$350/month benchmark, breakeven at 80-85% occupancy, member LTV, churn rate target <5% monthly).

**Seed data shape:** 2 locations with 3 floors each. 80 hot desks, 15 private offices (varied sizes: 1-person to 8-person), 6 meeting rooms (2 small/2 medium/2 large), 1 event space. 120 active members across 5 plan types (hot desk, dedicated desk, private office, virtual office, day pass). 15 leads in the CRM pipeline at various stages. 200 meeting room bookings spanning 30 days (mix of one-off and recurring, 5 no-shows). 30 days of access events (door entries/exits, 2,000+ events). 10 visitors with pre-registration records and signed NDAs. 20 mail items (8 scanned, 5 forwarded, 4 held, 3 discarded). 3 corporate accounts with 2-5 members each. Monthly invoices for 2 months with membership fees + meeting room overages + mail handling charges. Occupancy data showing weekday peak at 2 PM, low on Fridays. 5 upcoming community events with RSVP counts. Member engagement scores with 3 flagged as at-risk.

---

## 33. Workflow Automation / Integration Platform

**Archetype:** Automation platform (like n8n, Zapier, Make, Pipedream) where users build, manage, and monitor automated workflows connecting multiple services.

**Core entities:** Workflow/Flow, Node/Step (trigger + actions), Execution/Run, Connection/Credential, Trigger (webhook/schedule/event), Template, Workspace

**Gotchas:**
- **The visual workflow builder is the core product** — a canvas-based node editor where users drag nodes, connect them with edges, and configure each node's parameters. This is not a form — it's a graph editor. Libraries: `@xyflow/react` (formerly React Flow, the standard), `@antv/x6`, or Litegraph.js. The data model is a DAG (directed acyclic graph): each node has inputs, outputs, configuration, and connections to other nodes. Cycles must be detected and prevented.
- **Execution engine determines the architecture** — workflows run as a series of steps: trigger fires > node 1 executes > output feeds into node 2 > etc. Each step can succeed, fail, or timeout independently. The execution engine must handle: sequential execution, parallel branches (fan-out/fan-in), conditional paths (if/else routing), loops (iterate over a list of items), error handling per node (retry, continue on error, stop workflow), and sub-workflow calls. This is essentially a DAG execution engine, not CRUD.
- **Credential management for connected services is the security-critical layer** — users store API keys, OAuth tokens, and database passwords for dozens of services. Each credential is encrypted at rest (per-user or per-workspace encryption key), never sent to the browser in plaintext, and scoped to specific workflows. The credential store is the highest-value target for attackers. Credential testing ("verify this connection works") is a required feature.
- **Execution history and debugging require detailed logging** — every execution records: which nodes ran, in what order, what data each node received (input) and produced (output), how long each took, which failed and why. Users must be able to click into a past execution and see the data flowing through each node — this is the primary debugging tool. Store execution data with retention limits (executions generate a lot of data).
- **Trigger types are diverse and each has infrastructure requirements** — webhook triggers (your platform hosts a URL that receives events), schedule triggers (cron-based, requires a scheduler), polling triggers (check an API every N minutes for changes), event-stream triggers (listen to a message queue or WebSocket), and manual triggers (user clicks "Run"). Each needs different infrastructure. Webhook triggers must generate unique URLs per workflow and handle signature verification per provider.
- **Node/integration ecosystem is the moat** — users expect 100+ pre-built integrations (Slack, Gmail, Sheets, Salesforce, databases, HTTP, etc.). Each integration is a node type with: authentication method, available actions (send message, create record, query), input/output schema, and rate limit awareness. Building and maintaining integrations is the majority of ongoing work. Consider a community-contributed node model.
- **Error handling and retry are workflow-level concerns** — a node that calls an external API may fail due to rate limits, timeouts, or bad data. Users configure per-node: retry count, retry delay, continue-on-error (proceed to next node with error data), or stop workflow. At the workflow level: error notification (email/Slack the workflow owner when a run fails), dead-letter handling for permanently failed executions.
- **Data transformation between nodes is where users get stuck** — Node A outputs `{ "customer": { "email": "a@b.com" } }`, Node B expects `{ "to": "a@b.com" }`. Users need a data mapping UI: visual field mapper, expression editor (JavaScript or a simpler DSL), and a preview showing transformed data before running. This is the hardest UX problem in workflow builders.
- **Versioning and environment management** — production workflows should not be edited live. The pattern: edit in draft > test > publish. Published versions are immutable. Rollback to a previous version if the new one breaks. Note: n8n has no built-in environment separation (manage with separate instances or Git-based deployment). Zapier edits are live by default. Export workflows as JSON for Git-based version control.
- **Execution models differ fundamentally across platforms** — n8n uses an item-based model (every node receives/outputs an array of items), Zapier uses a record-at-a-time model (one record triggers one chain), Make uses an operation-based model (routers for branching, iterators for loops, aggregators for combining). The model you choose affects pricing, performance, and how users think about data flow. Binary data (files/images) requires explicit handling separate from JSON data.
- **Webhook reliability requires a queue-based ingestion layer** — accept the HTTP request immediately (return 200), push to a durable queue (Redis, SQS), process asynchronously. Never process synchronously. Deduplicate by event ID (providers guarantee at-least-once, meaning duplicates WILL arrive). When your endpoint recovers from downtime, retry storms hit — all backed-up retries arrive simultaneously. Buffer with a queue.
- **Rate limiting is a multi-dimensional problem** — per-service token buckets (each external API has its own limits), per-user execution quotas (tied to pricing tier), shared rate limits across users (50 users with Slack integrations share one platform-level quota), and 429 handling per node (automatic backoff, respect Retry-After header, not immediate failure).
- **Queue mode architecture for production scale** — separate webhook processors (accept requests, enqueue) from execution workers (pull from queue, execute workflows). Workers are stateless, horizontally scalable. Redis as message broker, PostgreSQL for persistence. Without queue mode, heavy workflows block the UI. Monitor: queue depth, worker health (CPU, memory, OOM risk), concurrent execution count.
- **Testing workflows requires specific UX patterns** — single-node re-execution (run just one node without re-triggering the whole workflow), data pinning (cache output of expensive nodes for test runs), separate test webhook URLs (hold the request and show it in the editor), manual trigger with sample data for any workflow type, execution preview showing input/output at every node.
- **AI-assisted workflow building is now a headline feature** — natural language to workflow (Zapier Copilot, n8n AI), suggested next nodes based on current node, AI-assisted field mapping between incompatible schemas, AI error diagnosis. Treat AI-generated workflows as scaffolding needing human review, not production-ready output.
- **The template/community marketplace is a growth engine** — n8n has 9,000+ community templates, Make has 7,900+. Templates include: workflow JSON, documentation, required credentials list, setup instructions. Community-built custom nodes extend the integration catalog (n8n nodes published to npm). Some platforms support paid templates with revenue sharing.
- **Common failure modes have a specific taxonomy** — silent failures (workflow completes but produces wrong output — most dangerous), cascading errors (error in step 2 propagated through 20 downstream steps), stale credentials (OAuth tokens expire months later), schema drift (external API changes field names), timeout cascades (slow API causes retry storm), and "set and forget" decay (60%+ of failures happen because workflows aren't monitored after deployment).
- **Pricing model determines what the dashboard must track** — Zapier: tasks (one action step on one record), Make: operations (one module per item), n8n cloud: executions (one workflow run regardless of steps), n8n self-hosted: unlimited. The dashboard must display consumption against plan limits, usage forecasting, cost projections, and overage alerts.

**Compliance:** Data processing agreements per workflow hop (GDPR Article 30 requires documenting each processing activity — each workflow IS a processing activity), credential storage encryption (SOC 2), execution log retention policies, rate limit compliance per service, webhook URL security, data minimization (workflows should pass only needed fields, not entire records), data residency for credentials and execution data, right-to-erasure tracing (which workflows touched a person's data and in which services), cross-border transfer documentation (SCCs for EU/non-EU service connections).

**UX users expect:** Visual canvas workflow builder (drag nodes, connect edges, configure per-node), execution history list with status (success/failure/running), execution detail view showing data at each node with timing, credential manager (add/test/delete/health-check connections), workflow templates gallery and marketplace, dashboard with KPIs (total executions, success rate, active workflows, top errors, queue depth), cron expression builder for schedule triggers, real-time execution monitoring (watch a run step by step), version history with JSON export for Git, data mapping UI with expression editor and live preview, AI-assisted workflow builder, usage/consumption meter against plan limits, operational monitoring (worker health, queue depth, credential expiry alerts).

**Seed data shape:** 10 workflows (5 active, 2 draft, 2 disabled, 1 with errors). Each has 3-8 nodes with varied types (webhook trigger, HTTP request, Slack message, conditional, loop, database query). 500 execution records spanning 30 days (400 success, 50 failed, 30 running/queued, 20 cancelled). Full input/output data per node for last 7 days, summarized for older. 8 stored credentials across 5 services (Slack, Gmail, Postgres, Stripe, HTTP) — 1 with expired OAuth token. 5 workflow templates. 1 workflow with schedule trigger (every hour, 720 executions). 1 webhook-triggered workflow with 20 incoming events and 2 duplicate deliveries (deduplicated). Queue metrics showing peak at 50 concurrent, normal at 5. Worker health data for 2 workers. Usage consumption at 65% of plan limit.

---

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
