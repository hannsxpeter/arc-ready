# 27. Insurance / InsurTech

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
