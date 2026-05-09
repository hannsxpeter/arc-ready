# Worked example: Pulse PRD

This is a worked example. The product, the company, the metrics, and the people are fictional. The PRD is what `prd-ready` produces when run end-to-end on a small B2B SaaS dashboard project; it is shown here as a complete artifact so the skill's discipline becomes visible.

The example feeds the worked architecture (`EXAMPLE-ARCH.md`), the worked roadmap (`EXAMPLE-ROADMAP.md`), and the worked stack decision (`EXAMPLE-STACK.md`). Together the four files demonstrate the suite's compose-by-artifact principle: each downstream artifact reads from this PRD and refines, never duplicates.

The product: **Pulse**, a Customer Success ops platform for B2B SaaS account managers. ~5 person seed-stage startup; first paying-pilot customer commits in 14 weeks; first PRD freeze targeted at the end of week 2.

What follows is the PRD itself, formatted to the prd-anatomy section order.

---

# Pulse: Customer Success ops platform

| | |
|---|---|
| Tier | Tier 2 (paying-pilot) |
| Status | Frozen v1.0 (2026-05-09) |
| Owner | Mira Chen (PM) |
| Authors | Mira Chen, Devon Park (eng lead) |
| Reviewers | Sam Okafor (CEO), Lin Tran (founding AE), Anaya Sharma (design) |

## Changelog

- **v1.0 (2026-05-09)**: frozen for paying-pilot delivery. Last edits: success-criteria leading metric narrowed from "weekly active AM" to "weekly active AM with at least one logged customer touchpoint" (counter-pattern: AMs who open the app to read, never write); R-08 (Salesforce sync) reranked from Must to Should after the pilot customer confirmed they'll start on HubSpot.
- **v0.9 (2026-05-07)**: ratified scope freeze with reviewers; deferred multi-currency revenue rollups to v1.1.
- **v0.8 (2026-05-04)**: added Open Question 4 (data residency) after pilot customer mentioned EU subsidiary. Resolved 2026-05-06: pilot is US-data-only; EU residency is v1.x scope.
- **v0.6 (2026-04-29)**: removed feature-laundry-list section from earlier draft; recut as MoSCoW-ranked R-NN entries.

## Open questions

(All resolved before v1.0 freeze; preserved here as the audit trail.)

1. ~~Salesforce or HubSpot first?~~ Resolved 2026-05-09: HubSpot only at v1.0 (pilot uses HubSpot). Salesforce moves to v1.1 (Should -> Could).
2. ~~Slack as a notification destination at launch?~~ Resolved 2026-05-04: yes, in scope (R-12).
3. ~~In-app NPS survey or third-party (Delighted / Refiner)?~~ Resolved 2026-05-04: in-app, narrow scope (one question, three reactions); third-party deferred.
4. ~~EU data residency?~~ Resolved 2026-05-06: out of scope for v1.0; pilot customer is US-data-only.
5. ~~SCIM provisioning?~~ Resolved 2026-04-30: out of scope for v1.0; manual user invites.

## Mode and context

This is a Tier 2 PRD. There is one paying-pilot customer (DartLogic, 38-person B2B SaaS in San Francisco) committed to a 14-week pilot starting 2026-05-12 with a paid 12-month contract on pilot success. The PRD is frozen for the pilot delivery; v1.1 scope items move to the parking lot below.

The product hypothesis is testable in the pilot: AMs who actively manage their accounts via Pulse will run accounts with measurably better retention than AMs who manage via spreadsheets. The pilot's success bar: by week 14, DartLogic's pilot AMs (3 of them) report higher confidence in their account state and at least 50% of their managed accounts have had a logged touchpoint within the prior 30 days.

## Problem

DartLogic's account managers manage 30-50 accounts each in spreadsheets, Slack DMs, and Gmail threads. They have no shared view of which customer a given AM talked to last, who is at risk, or what the next touchpoint should be. The result: at-risk customers slip through the cracks because no AM realizes they are in the at-risk segment until the renewal conversation goes badly. Of DartLogic's 12 churned accounts in the prior 12 months, post-mortems found that 8 had warning signals (declining usage, support ticket clusters, leadership changes) that the AM team did not surface to leadership before the renewal call.

The problem is **shared visibility into account state, not the data itself.** HubSpot has the data; nobody on the AM team agrees on what "at risk" means, where to log it, or how to know it before the renewal date. The cost is recurring: at DartLogic's $4M ARR, the 8 preventable churns represent ~$280k of leaked retention that better visibility could have saved.

This is not a problem about "lack of CRM" (DartLogic has HubSpot). It is not a problem about "AMs don't talk to customers" (they do, frequently). It is a problem about **the unwritten rule that an account is OK until proven otherwise**, and the absence of a tool that makes the proof visible.

## Target user

### Primary: Account Manager at a 30-150 person B2B SaaS

Concrete persona: **Lin (DartLogic AM)**. Manages 38 accounts, ranging from $5k MRR to $80k MRR. Spends 60-70% of her week in customer calls and async messages; the rest in HubSpot, Slack, Gmail, and a personal Google Sheet. Carries a quarterly NRR target plus a quarterly satisfaction (NPS) target. Has been at DartLogic 18 months. Previously at a 600-person SaaS where the CS team had a homegrown internal tool she misses badly.

What Lin needs from Pulse:
- A view of her 38 accounts that updates without her having to refresh it.
- A way to log a touchpoint in under 30 seconds without leaving the call she just finished.
- A way to flag an account as at-risk before the renewal date with reasons her manager can read.
- A way to see what touchpoints she has missed across her book, sorted by recency-since-last-contact.
- A way to receive an alert (email or Slack) when an account meets a defined risk pattern (no-touch-30d, support-ticket-cluster, NPS drop).

What Lin does NOT need:
- A full-stack CRM. She has HubSpot.
- Email composition tools. She uses Gmail.
- A second source of truth for the customer record. HubSpot is the master.

### Secondary: AM team manager

Concrete persona: **Devon (DartLogic Head of CS)**. Manages 4 AMs. Carries the team-level NRR target. What Devon needs:
- A view across all AMs' books, with at-risk accounts surfaced.
- The ability to reassign accounts between AMs without IT involvement.
- A weekly digest of what changed (new at-risk accounts, AMs missing touchpoints, NPS responses).
- A monthly cohort view: which accounts churned, which were saved, what the leading signal was.

### Tertiary: Founder / executive

Concrete persona: **Sam (DartLogic CEO)**. Reviews account health monthly in a board prep meeting. Needs a one-screen view of net retention, count of at-risk accounts, and recent saves vs. churns. Does not need to log into Pulse to see it; an emailed PDF or a Slack-posted screenshot is acceptable.

### Substitution test

Pulse's target user is not "small business owners" or "CS teams who need productivity tools." Substitute either of those phrases into this section and the PRD becomes generic; the actionable specificity goes away. Lin, Devon, and Sam are not interchangeable with other DartLogic personas; the design exists to serve their specific workflows.

## Success criteria

### Leading (steers)

- **L-1: Weekly active AM with at least one logged touchpoint.** Target by week 6: 3 of 3 DartLogic pilot AMs are weekly active with at least one logged touchpoint per week. Counter-pattern: AMs who open Pulse to read but never write are not weekly active.
- **L-2: Time from "AM finishes call" to "touchpoint logged" measured via in-app time-stamp.** Target by week 8: median <= 90 seconds, p95 <= 4 minutes. (Slow logging is the leading indicator of "Pulse is friction not relief.")
- **L-3: At-risk-flag-to-renewal-call lead time.** Target by week 10: every account that is later marked at-risk has its first at-risk flag at least 30 days before its renewal date. (Flagging during the renewal call is too late.)

### Lagging (ratifies)

- **G-1: DartLogic 12-month NRR.** Pre-Pulse 12-month NRR: 89%. Pilot success bar: 12-month NRR measured at week 52 >= 95%. (Pilot ends at week 14; this metric is post-pilot.)
- **G-2: Pilot extension to 12-month paid contract.** Target by week 14: contract signed.
- **G-3: NPS response rate from accounts logged in Pulse.** Target by week 14: >= 30%. Industry baseline at this segment: 12-15%.

### Counter-metric (watches for gaming)

- **C-1: Touchpoint-volume-without-content.** Definition: a touchpoint logged in <= 15 seconds with body text under 20 characters. Target: <= 5% of total touchpoints. Above 5% means AMs are gaming the leading metric by logging "yes" or "called" to hit the count.
- **C-2: At-risk-flags-without-resolution.** Definition: an at-risk flag that is not resolved (cleared or escalated) within 14 days of its set date. Target: <= 10%. Above 10% means flags are decoration, not signal.

## Appetite

The pilot is 14 weeks. The team is 5 people: 1 PM, 2 eng (1 full-stack lead + 1 generalist), 1 designer, 1 founding AE. Eng capacity for build is ~14 weeks * 2 eng * 4 effective days/week = 112 eng-days. The designer carries first-pass UI for every feature; the AE carries pilot-customer feedback loops.

Appetite is fixed at 14 weeks. Scope is the variable; if a Should-ranked requirement runs over, it moves to v1.1.

### Rabbit holes (named, bounded)

- **Multi-tenancy data model.** Pulse is multi-tenant from day 1 (DartLogic now; future customers later). The temptation is to build a full tenant-isolation layer with row-level security, schema-per-tenant, and an admin tool to switch contexts. Bound: tenant-id column on every customer-facing row, application-layer enforcement, no admin tool. RLS is v1.x.
- **CRM sync correctness.** HubSpot sync failure modes are well-known and numerous. The temptation is to build a generic ETL layer. Bound: HubSpot only at v1.0, polled every 15 minutes, last-write-wins on collisions, manual conflict-resolution UI deferred to v1.1.
- **Notification delivery semantics.** "Email, Slack, in-app" sounds simple. The temptation is to build a notification framework with retry, dedupe, user-preference UI, and rate-limiting. Bound: in-app + email at v1.0, single retry on email failure, per-user on/off toggle (no per-channel granularity), Slack at v1.0 but only via incoming webhook.
- **Reporting / cohorts.** Devon and Sam want monthly cohort views. The temptation is to build a generalized cohort-analytics engine. Bound: one fixed cohort report (churn / save by month) generated by a scheduled job, exported as CSV. Anything more complex routes to "export to spreadsheet."

### No-gos (will not appear in v1.0)

- **No general CRM features.** Pulse does not own contacts, deals, pipelines, or revenue forecasts. HubSpot does. (If we drift here, we are competing with HubSpot, which is not the strategy.)
- **No email composition.** Pulse links out to Gmail / HubSpot for sending; it does not compose.
- **No mobile app.** Web-responsive only. Native mobile is v2.0+.
- **No public API.** Internal-only at v1.0; partner integrations route through HubSpot.
- **No SSO / SCIM.** Magic-link email auth at v1.0; SAML/OIDC at v1.x.
- **No multi-currency revenue rollups.** USD only at v1.0.

## Functional requirements

MoSCoW-ranked. Cuts (Should -> Could, Could -> deferred) are explicit.

### Must

- **R-01 (Must): Multi-tenant account record.** Each tenant has its own set of accounts, AMs, and touchpoints. Cross-tenant access prohibited at the application layer. Acceptance: a tenant-bound user querying any record returns only their tenant's data; a malformed query attempting cross-tenant access returns 403.
- **R-02 (Must): Account list view (per AM).** Lin signs in, sees her 38 accounts as rows: company name, MRR, last touchpoint date, at-risk flag. Sorted by recency-since-last-touchpoint by default. Acceptance: Lin's account list loads in <= 800ms p95 with 100 accounts in a tenant.
- **R-03 (Must): Touchpoint log.** Lin opens an account, clicks "Log touchpoint," picks a type (call / email / meeting / message), writes a body, hits save. The touchpoint appears on the account's timeline immediately. Acceptance: from "click Log touchpoint" to "saved + timeline updated" <= 4 seconds median in normal network conditions.
- **R-04 (Must): At-risk flag with reason and resolution.** Lin can flag an account at-risk with a free-text reason and an optional follow-up date. The flag persists until cleared or escalated. Acceptance: flagged accounts appear in Devon's team view; the flag carries the AM name and the timestamp.
- **R-05 (Must): Email notification on at-risk pattern match.** When an account in Lin's book matches a defined pattern (no-touch-30d, support-ticket-cluster-via-HubSpot, NPS-drop), Pulse emails Lin within 1 hour. Acceptance: the email arrives, links back to the matching account, names the pattern.
- **R-06 (Must): HubSpot one-way sync (HubSpot -> Pulse).** Account records originate in HubSpot; Pulse polls every 15 minutes and updates its mirror. Conflict policy: HubSpot is the source of truth for anything HubSpot owns (contact info, deal stage, lifecycle stage); Pulse owns touchpoints and at-risk flags exclusively. Acceptance: a HubSpot record updated at T appears in Pulse by T+15min p95.
- **R-07 (Must): RBAC: AM, Manager, Admin.** Three roles. AM sees their own book + writes their own touchpoints + flags. Manager sees the team's books + reassigns accounts. Admin manages users and tenant settings. Acceptance: every API endpoint enforces the role check server-side; the matrix is documented and tested.

### Should

- **R-08 (Should): Salesforce one-way sync (Salesforce -> Pulse).** Same shape as R-06 but for Salesforce. (Was Must in v0.9; cut to Should after pilot customer confirmed HubSpot-only.) Out of scope for v1.0; first feature in v1.1.
- **R-09 (Should): Slack notification on at-risk pattern match.** Same as R-05 but Slack via incoming webhook. Acceptance: the AM's configured Slack DM channel receives the alert; the message links back to the account.
- **R-10 (Should): Reassignment audit log.** Every account-reassignment event is logged with old AM, new AM, manager, timestamp, reason (optional). Acceptance: Devon can pull a CSV of the last 90 days of reassignments.
- **R-11 (Should): Manager weekly digest email.** Every Monday 09:00 local, Devon receives an email: count of at-risk accounts (by AM), AMs missing touchpoints, NPS responses received the prior week. Acceptance: the email arrives, the numbers match the in-app dashboard.

### Could

- **R-12 (Could): In-app NPS survey.** Pulse can email a one-question NPS survey to a designated contact at the account, on a schedule. Replies stored on the account record. Cut policy if eng day-count bumps: defer R-12 first.
- **R-13 (Could): Cohort report (monthly churn / save).** A scheduled job that runs the last day of each month, computes per-cohort churn / save counts, and emails Devon a CSV.

### Deferred (parking lot for v1.1+)

- Salesforce sync (R-08 promoted from Should-deferred to v1.1).
- Multi-currency revenue rollups.
- EU data residency.
- SSO / SCIM.
- Public API.
- Mobile app.
- Generalized notification framework.
- Per-user notification-preference UI.

## Non-functional requirements

- **Performance.** Account list view <= 800ms p95 under 100-account tenants and 5 concurrent AMs. Touchpoint save end-to-end <= 4s median.
- **Availability.** 99.5% during pilot. Maintenance windows allowed weekends 00:00-04:00 PT, announced 48h in advance.
- **Security.** All traffic TLS. At-rest encryption at the database layer. Audit log for: login, role change, account reassignment, at-risk flag set/cleared. Pen-test before paying-pilot signs the 12-month contract (week 12).
- **Compliance.** Pilot is US-data-only; no GDPR / SOC 2 commitments at v1.0. SOC 2 Type II target for v2.0 (post-pilot).
- **Observability.** Structured JSON logs. SLO on R-02 (account list view) and R-05 (notification delivery): 99% of requests within their performance / latency target, monthly. Error budget: 1%.
- **Cost ceiling.** Hosting + third-party services <= $400/mo at pilot scale.

## Risks and assumptions

| ID | Risk / assumption | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| Risk-01 | HubSpot API rate limits hit during the 15-min poll under multi-tenant load | Med | High | Staggered poll start times per tenant; back-off; alert on rate-limit hits |
| Risk-02 | Pilot AMs adopt Pulse for two weeks then stop | Med | High | Weekly check-in with Lin; counter-metric C-1 watches for gaming; AE owns adoption |
| Risk-03 | At-risk pattern matching is too noisy (false positives) | High | Med | Conservative thresholds at v1.0; weekly review of fired alerts vs. resolutions; tune in v1.1 |
| Risk-04 | DartLogic does not extend to 12-month contract | Med | Critical | Weekly pilot reviews; defined success bar (G-1, G-2); fall-back: extend pilot 4 weeks before declaring failure |
| Assumption-01 | Lin will adopt the touchpoint log if the time-to-log <= 90s. Source: prior-AM-tool research at our prior employer. Validation: L-2 metric. | High | High | If time-to-log > 90s by week 4, re-design the log flow before adding more features |
| Assumption-02 | HubSpot's API rate limits permit 15-min polls per tenant. Source: HubSpot docs as of 2026-04-29. Validation: integration smoke tests by week 3. | High | Med | If polling proves rate-limited, switch to HubSpot webhooks (HubSpot supports them; we deferred webhooks for simplicity) |

## Sign-off

| Role | Name | Sign-off date |
|---|---|---|
| PM | Mira Chen | 2026-05-09 |
| Eng lead | Devon Park | 2026-05-09 |
| Design | Anaya Sharma | 2026-05-09 |
| CEO | Sam Okafor | 2026-05-09 |
| Pilot customer (DartLogic) | Jules Reilly (CS Director) | 2026-05-09 |

Sign-off attests to: the scope as frozen above, the success bar in §Success criteria, the no-gos in §Appetite, and the open-questions resolutions logged in §Open questions.

## Downstream handoff

The artifacts this PRD enables:

- **architecture-ready** consumes this PRD to produce `.architecture-ready/ARCH.md`. The architecture must answer: how is multi-tenancy enforced (R-01); what is the trust boundary at HubSpot sync (R-06); what is the data model for accounts, touchpoints, and at-risk flags (R-02 to R-04); what is the auth shape that supports magic-link plus a clean SSO migration path (NFR security). Worked example: `EXAMPLE-ARCH.md`.
- **roadmap-ready** consumes this PRD plus the architecture to produce `.roadmap-ready/ROADMAP.md`. The roadmap sequences the seven Must requirements over the 14-week appetite, places the four Shoulds and two Coulds with explicit cut policy, names the named-rabbit-hole bounds, and lands the pilot success bar at week 14. Worked example: `EXAMPLE-ROADMAP.md`.
- **stack-ready** consumes the PRD's NFR section, the team-size constraint (5 people), and the appetite (14 weeks). The stack picks must satisfy: multi-tenant data model, HubSpot integration, magic-link auth with future SSO migration, hosted job scheduler for the 15-min poll, structured logging out of the box. Worked example: `EXAMPLE-STACK.md`.
- **production-ready** consumes the architecture, roadmap, and stack to build the slices. The first slice is the foundation: tenant + AM + sign-in + the empty account list view. Then R-02 through R-07 in order.

## Why this is not a hollow PRD

The grep tests this PRD passes (failure modes prd-ready refuses):

- **Hollow PRD test.** Every R-NN entry has acceptance criteria. The success criteria are numerical with named counter-metrics. No "TBD," no "TODO," no "coming soon."
- **Invisible PRD test.** Substitute "small business owners" for "DartLogic AM team": the PRD breaks. The persona is named (Lin, Devon, Sam) and the metrics are anchored to a specific company at a specific stage.
- **Feature-laundry-list test.** Every requirement has a MoSCoW rank. The Coulds have an explicit cut policy. The deferred section is named v1.1+ items, not "out of scope" silently.
- **Solution-first PRD test.** §Problem describes "shared visibility into account state" as the problem; it does not name "build a Pulse-like tool" as the problem. The product solves a named problem; the problem does not name the product.
- **Assumption-soup test.** §Risks-and-assumptions has source citations and validation steps for every assumption.
- **Moving-target test.** §Changelog records edits with dates and rationale; v1.0 is frozen with sign-off; future scope edits append a new changelog entry, do not silently revise.

## Why this PRD will get built

It will get built because (a) it has a named pilot customer with a paid contract on success, (b) the appetite is bounded to 14 weeks of fixed eng capacity, (c) every Must has acceptance criteria the team can verify, and (d) the success bar is testable without ambiguity.

If any of those four were missing, this would be a wishlist, not a PRD. prd-ready refuses to produce wishlists.
