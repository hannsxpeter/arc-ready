# 30. Government / Public Sector

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
