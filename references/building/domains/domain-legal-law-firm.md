# 17. Legal / Law Firm

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
