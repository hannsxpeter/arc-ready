# Requirements: functional and non-functional (Steps 5 and 6)

Requirements are where the PRD either gives engineering what it needs to build or forces eight clarification meetings. This reference covers the granularity rule, the MoSCoW discipline, acceptance-criteria format, the non-functional dimension checklist, the common gaps, and how requirements feed downstream to stack-ready, architecture-ready, and production-ready.

## 1. What a functional requirement is

A functional requirement describes what the system must do from the user's point of view. Three properties:

1. **User-observable.** The user can see it happen or see the effect. Not "the system supports CSV import" (a capability) but "the user can upload a CSV of up to 10,000 rows and receive a preview in under 5 seconds" (a behavior).
2. **Testable.** QA (or production-ready's Tier 1 proof test) can construct a test that passes or fails. "The import completes" is testable; "the import is fast" is not without a threshold.
3. **Decided.** MoSCoW-ranked. Acceptance criteria named. Dependencies listed. Open questions flagged.

A line that is not all three is not a requirement; it is a wish, a feature idea, or a task.

## 2. The granularity rule

Requirements have a natural size. Too small: it is a task. Too big: it is an epic.

**Too small (a task):**

> "Add a 'Generate status' button to the header."

This is an implementation detail. It belongs in a ticket, not a PRD.

**Too big (an epic):**

> "Users can manage their status updates."

Too many implied behaviors; the PRD reader cannot know what is in scope. Split.

**Right-sized:**

> "Users can generate a new status doc from the currently-selected project by clicking 'Generate status,' which pulls the last 7 days of activity from connected tools and renders a draft for review within 15 seconds."

Specific enough to test. Broad enough to cover the user-facing behavior without dictating implementation.

### Split-or-merge heuristic

If a requirement requires more than 5 acceptance criteria to test, split it. If a requirement has fewer than 2 acceptance criteria, merge it with adjacent behavior or reclassify as a task.

## 3. MoSCoW discipline

MoSCoW is the default prioritization for PRDs: **Must, Should, Could, Won't (this release).**

### Must

Fails the release if missing. The product does not ship without this. Usually 30-50% of the requirement list.

### Should

Important but the release can go without it. Ships if time-box allows; does not block launch. Usually 20-30%.

### Could

Nice to have. Polish. Edge-case coverage. Shipped if the appetite's remaining budget can fit it. Usually 20-30%.

### Won't (this release)

Explicitly not shipping in this cycle. Cross-linked to the Out-of-Scope section (Step 7). Usually 10-20%.

### The distribution check

- A list where every item is Must is not prioritized.
- A list where most items are Should is indecisive.
- A list where most items are Could is not a PRD; it is brainstorming.
- A list with no Won'ts has not considered scope cuts.

Force a distribution: at most 50% Musts, at least 10% Should or Could, and at least one explicit Won't. If the distribution cannot be honored, the appetite is wrong; cut scope or extend appetite.

### Why MoSCoW specifically

RICE, ICE, Kano, weighted-shortest-job-first, and other frameworks exist. They are fine for roadmap sequencing (roadmap-ready's territory). For a PRD, MoSCoW's advantage is that it directly communicates "what ships" to engineering; rankings 1-10 or scores 0-100 hide the cut-line.

Teams that have a standing RICE or ICE practice can layer it on top of MoSCoW (Must + high RICE = build first; Could + low RICE = probably cut), but the PRD's primary rank is MoSCoW.

## 4. Acceptance criteria format

Every requirement has acceptance criteria. The Given-When-Then structure from Gherkin works well:

```
Given [precondition]
When [user action]
Then [observable result]
```

### Example

Requirement: "Users can generate a new status doc from the currently-selected project."

Acceptance criteria:

```
Given a user has authenticated and selected a project with at least 3 days of activity in the last 7 days
When they click 'Generate status' in the header
Then a draft status doc renders in the review panel within 15 seconds
And the draft includes sections for: project highlights, risks, next week
And each section cites at least one source (Figma comment, Asana task, Harvest entry)
And no section exceeds 500 words
```

```
Given a user clicks 'Generate status' on a project with no recent activity
When the server has no events to summarize
Then an empty-state renders with guidance ('No activity in the last 7 days; add a manual summary?') within 3 seconds
And the Generate button does not re-trigger until dismissed
```

```
Given a user clicks 'Generate status' and the LLM call fails
When the timeout is reached or the upstream returns a non-200
Then the UI renders an error state with a retry affordance within 10 seconds
And the error is logged with trace ID, user ID, and the failing upstream event
And the retry counter is capped at 3 per minute per user
```

Three acceptance criteria for one requirement: happy path, empty state, error state. The pattern scales; every nontrivial requirement has happy, empty, and error at minimum.

### Criteria that fail

- "The feature works." (Not testable.)
- "The feature is fast." (No threshold.)
- "The feature is usable." (Not testable by an automated test.)
- "The feature is secure." (Not testable without a specific threat and control.)

Replace with observable, threshold-bounded criteria.

## 5. Dependencies

Every requirement has a dependency list (possibly empty).

Dependency types:

- **Blocking dependency.** Requirement B cannot ship until A ships. "The billing page cannot ship until the pricing table exists."
- **Soft dependency.** Requirement B is easier or better with A. "The onboarding tour is easier if the feature detection system is in place first."
- **External dependency.** Requires a third-party integration or a non-team input. "Stripe Connect onboarding requires Stripe account setup (owner: finance team)."

Roadmap-ready consumes this list to produce the sequencing. Architecture-ready uses it to identify the components that must exist before others.

## 6. What requirements are NOT

- **Screens or wireframes.** "The dashboard has three tabs" is a UI decision; it lives in design, not the PRD. Name the user-observable behavior, not the layout.
- **Implementation details.** "Uses a Kafka queue" is architecture, not requirement. Name what the user sees; architecture-ready picks the queue.
- **Non-functional constraints.** Performance, security, scale, availability are non-functional. Cover in Step 6 (Section 7 below).
- **Marketing features.** "AI-powered insights" is marketing; "when the user asks 'what changed last week,' the system returns a ranked list of changes within 3 seconds" is a requirement.
- **Scope declarations.** "We will support multi-tenant admin" is scope; the requirement is "an admin user can view and edit all team members in their tenant (CRUD), but cannot see users in other tenants."

## 7. Non-functional requirements (NFRs)

The dimensions every Tier 3+ PRD addresses. Silence in any dimension is a decision (usually the wrong one).

### Performance

How fast the system responds under expected load.

**Thresholds:**

- p50/p95/p99 response time for primary user actions.
- Batch job duration (e.g., "nightly billing batch completes under 15 minutes for 10,000 tenants").
- Page load time (LCP, TTI) on a stated connection profile.

**Example:** "p95 response time under 300ms for primary user actions on a 4G connection; p99 under 800ms. Batch jobs: nightly billing completes under 15 minutes for up to 10,000 tenants."

### Scale

The system's capacity at launch, 6 months, 12 months.

**Thresholds:**

- Concurrent users.
- Events per day.
- Storage (GB, rows).
- Tenants.
- Queries per second.

**Example:** "Supports 10,000 concurrent users and 1M events/day at v1; 50,000 concurrent users and 10M events/day at 12 months (projection based on sales forecast)."

This is the same signal stack-ready consumes for the 12-month scale-ceiling pre-flight question.

### Availability

Uptime target. Usually stated as a percentage or as monthly-downtime minutes.

**Thresholds:**

- 99% = 7.2 hours/month of acceptable downtime.
- 99.9% = 43 minutes/month.
- 99.99% = 4.3 minutes/month.
- 99.999% = 26 seconds/month.

**Example:** "99.9% uptime monthly, measured across primary user-facing actions (not background jobs). Planned maintenance windows do not count against the SLO. Public status page at status.example.com."

Observe-ready consumes availability targets to write SLOs. A PRD that says "highly available" without a number forces observe-ready to invent one.

### Security

Named threats and controls.

**Common threats to address:**

- Unauthorized access (auth, session).
- Data exfiltration (encryption, access logs).
- Injection attacks (parameterized queries, CSP).
- CSRF / XSS.
- Dependency vulnerabilities.
- Secrets leakage.

**Example:** "All data in transit encrypted with TLS 1.3+. Data at rest encrypted with AES-256; customer-managed keys available for Enterprise tier. Auth: SSO via Okta/Google Workspace/Azure AD SAML. Session timeout: 30 days (30 days of inactivity triggers re-auth). No PII in application logs (Sentry PII scrubbing enabled)."

### Privacy

What user data the system collects, keeps, and shares. GDPR, CCPA, and vertical-specific privacy rules.

**Example:** "GDPR-compliant: subject access requests fulfilled within 30 days; right-to-delete honored with a 60-day retention buffer for backup recovery. No third-party analytics on authenticated pages. Cookie consent banner on marketing site only."

### Compliance

Regulatory constraints.

**Example:** "SOC 2 Type II controls apply to production (evidence logged in Vanta). HIPAA BAA required for Healthcare tier customers; PHI handling is gated behind tier. PCI-DSS SAQ-A level: Stripe-hosted payment pages only; no PAN ever enters our systems."

### Accessibility

WCAG conformance level, testing method.

**Example:** "WCAG 2.2 AA compliance verified by automated axe-core scans in CI on every PR and a manual screen-reader pass (NVDA on Windows, VoiceOver on macOS) on every tier 2+ feature."

### Internationalization

Language, locale, currency, timezone support.

**Example:** "English only at v1. Internationalization scaffold in place: strings externalized via react-i18next; no hardcoded strings in UI. Currency and date formatting respect the user's browser locale even in v1. Next-language decision deferred to v2."

### Observability

What the system exposes about itself for monitoring.

**Example:** "Every user-facing error is logged with user ID, trace ID, and a support-reproducible payload. Structured logs (JSON) shipped to Honeycomb. Per-tenant usage metrics exported to the admin dashboard. SLO dashboards cover: availability, latency (p95), error rate."

Observe-ready consumes these directly.

### Data retention

How long data is kept. Regulated by legal, privacy, and cost constraints.

**Example:** "Active user data: indefinite. Inactive accounts (no login for 24 months): data purged 30 days after the 24-month mark, with email notification at 23 months. Audit logs: 7 years for Finance tier customers; 1 year for others. Backups: 30-day rolling window."

### Browser / platform support

Named targets.

**Example:** "Chrome, Safari, Firefox, Edge latest-2 versions. iOS Safari 16+. Android Chrome. No IE support. Mobile-web functional for read operations; writes require desktop at v1."

### Operational / deployability

Deployment expectations. Informs deploy-ready.

**Example:** "Zero-downtime deployments required. Database migrations follow expand-contract discipline; no migrations that lock primary tables for more than 2 seconds. Rollback window: last 3 deployments retained for instant rollback."

## 8. The NFR silence trap

AI-generated PRDs skip NFRs because they are genuinely the hardest section. The cost: every downstream skill has to invent numbers that the PM was supposed to own.

**Forcing function:** at Tier 3, every NFR dimension listed above has a line. The line is either:

- A concrete threshold (the normal case).
- "Not applicable; [reason]" (the explicit opt-out).
- "Open question; [owner] by [date]" (the flagged gap).

Silence on an NFR dimension blocks Tier 3 sign-off. The research pass notes (section 1.5, engineers refuse to estimate) that the missing NFRs cause the dominant rescue-mode symptom ("the PRD is underspecified").

## 9. Requirements for features that span tiers of users

Multi-sided products (marketplaces, multi-tenant SaaS with separate admin roles, dev+product-manager products) have requirements that span user tiers. Two options:

- **Single list, user-tagged.** "[R4] [buyer] Users can filter listings by price range within 300ms." "[R5] [seller] Users can set minimum and maximum price per listing."
- **Per-user sub-lists.** One requirement set per target user.

The per-user structure is clearer; the single-list structure is shorter. Use per-user if the number of requirements is >8 or the two tiers have complex interactions.

## 10. The "can an engineer estimate this" check

The strongest audit. For each requirement, ask: could an engineer on the team read this, ask zero questions, and give a point estimate (or hours, or days)?

If no, the requirement is underspecified. Common gaps:

- Missing acceptance criteria for error or empty states.
- Unnamed dependencies.
- Ambiguous scope ("generate a good status doc" -- what is "good").
- Implementation bleed ("use OpenAI GPT-5" -- that's architecture, but the requirement needs to name the user-observable quality).
- Missing NFR ("fast" -- what threshold).

Fix the gap before declaring the requirement done.

## 11. Requirements traceability

For Tier 3 PRDs (especially regulated domains), maintain a traceability matrix:

| Requirement ID | Description | Source (problem section, user interview, regulation) | Tests | Owner |
|---|---|---|---|---|
| R-01 | Users can generate status doc... | Problem section; Jenna M. interview Jan 2026 | T-01, T-02, T-03 | eng-team-a |
| R-02 | All PII encrypted at rest... | SOC 2 Type II requirement CC6.1 | T-12, T-13 | platform-team |

Traceability is overkill for Tier 2; required for Tier 3 in regulated domains.

## 12. Requirements and architecture (the boundary)

The PRD names *what* the user can do. Architecture names *how* it works under the hood. The boundary is tested by this question: "if I rewrote the implementation from scratch but kept every user-observable behavior, would the requirement still be met?"

- "Users can upload a CSV and get a preview within 5 seconds." -> Yes, any implementation that meets the behavior is valid. Requirement.
- "Uses Kafka for event streaming." -> No, this prescribes implementation. Architecture.
- "Events are processed exactly once; no duplicates under any failure mode." -> Yes, this is a user-facing correctness property (the user doesn't see duplicates). Requirement.

When in doubt, describe the property the user or the business cares about, not the mechanism.

## 13. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 1.8 (over-specification failure mode) and section 6 (downstream-consumer needs).
- Mike Cohn, *User Stories Applied* (2004) for Given-When-Then adaptation.
- Karl Wiegers, Joy Beatty, *Software Requirements* (3rd ed., 2013) for traceability matrix patterns.
- Gojko Adzic, *Specification by Example* (2011) for acceptance criteria derived from examples.
- Nicole Forsgren, Jez Humble, Gene Kim, *Accelerate* (2018) on operational NFRs and deployment discipline.
