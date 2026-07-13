# 25. Construction / Field Services

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
