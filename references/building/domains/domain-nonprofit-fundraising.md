# 18. Non-profit / Fundraising

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
