# 11. HR / People / Payroll

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
