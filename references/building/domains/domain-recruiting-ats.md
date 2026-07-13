# 31. Recruiting / ATS (Applicant Tracking)

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

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
