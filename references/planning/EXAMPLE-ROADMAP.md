# Worked example: Pulse roadmap

This is a worked example. The product is fictional. The roadmap is what `roadmap-ready` produces when run end-to-end against the worked PRD (`EXAMPLE-PRD.md`) and the worked architecture (`EXAMPLE-ARCH.md`). It feeds production-ready (the per-slice work queue), deploy-ready (the cutover cadence), observe-ready (the KPI handoff), and launch-ready (the launch milestone gates).

The product context: **Pulse**, a Customer Success ops platform. 14-week paying-pilot appetite; 5-person team; first paying pilot is DartLogic, contract signs on pilot success at week 14.

What follows is the roadmap itself, formatted to the roadmap-anatomy section order.

---

# Pulse: ROADMAP.md

| | |
|---|---|
| Tier | Tier 2 (matches PRD tier) |
| Status | v1.0 (2026-05-11), 2 days after PRD freeze |
| Owner | Mira Chen (PM) |
| Reviewers | Devon Park (eng lead), Lin Tran (founding AE), Anaya Sharma (design) |
| Consumed PRD | `EXAMPLE-PRD.md` v1.0 |
| Consumed ARCH | `EXAMPLE-ARCH.md` v1.0 |
| Cadence | 14-week pilot (weekly review; bi-weekly demo to DartLogic; week-14 paying-pilot gate) |

## Capacity input (the variable that makes a roadmap real)

| Resource | Available | Effective | Notes |
|---|---|---|---|
| Eng (Devon, Mira-on-eng-50%, Generalist) | 14 weeks | 14 * 4 effective days/week = 56 days per Devon + 56 days generalist + 14*0.5*4 = 28 days Mira = **140 eng-days** | Mira at 50% on eng during weeks 5-14; PM-only weeks 1-4. Generalist starts week 1. Devon at 100% throughout. |
| Design (Anaya) | 14 weeks | 14 * 3 effective days/week = **42 design-days** | Anaya at 75% on Pulse; 25% on the brand site (out of scope). |
| AE (Lin) | 14 weeks | 14 * 1 effective day/week = **14 AE-days** | AE work is pilot-customer feedback loops, demo prep, and the week-14 paying-pilot ceremony. |
| **Total build capacity** | | **140 eng-days + 42 design-days + 14 AE-days** | |

Anything that does not fit in 140 eng-days does not ship at v1.0. The cut policy in the PRD (Coulds before Shoulds before Musts) governs.

## Now / Next / Later

| Horizon | Window | Theme | Confidence |
|---|---|---|---|
| **Now** | Weeks 1-6 | Foundation + first three Must requirements (R-01, R-02, R-07 -> R-03) | High; constraints known |
| **Next** | Weeks 7-12 | Remaining Musts (R-04, R-05, R-06) + Should items (R-09, R-10, R-11) as capacity permits | Medium; HubSpot sync risk (Risk-01) is the largest unknown |
| **Later** | Weeks 13-14 | Pilot polish, pen-test (NFR Security), launch-prep, paying-pilot gate | Medium; depends on Now and Next finishing on calendar |
| **Beyond** | v1.1+ | Salesforce sync (R-08), multi-currency, SSO/SCIM, EU residency, mobile, public API | Out of pilot scope; named in PRD §Deferred |

## Milestones

Three milestones in the 14-week pilot. Each has a completion gate that is binary (met / not met), no partial credit.

### M1 (week 6): Foundation + first slice end-to-end

**Completion gate:** Lin signs into a hosted instance with magic-link, sees a list of 100 mock-DartLogic accounts, opens one, logs a touchpoint, sees it on the timeline. The whole flow takes <= 4 seconds median end-to-end. The only role wired is AM; Manager and Admin are out of scope at M1.

**Why this gate:** the PRD's L-2 metric (time-to-log <= 90s) and L-1 metric (weekly active AM with at least one logged touchpoint) cannot start being measured without R-02 + R-03 wired. M1 unblocks the leading-metric data collection.

**Out at M1:** at-risk flag (M2), HubSpot sync (M2), notifications (M2), Manager + Admin roles (M2), Slack (M2 if capacity).

### M2 (week 12): All Musts + critical Shoulds + pen-test

**Completion gate:** every Must requirement (R-01 through R-07) is wired and verified per its acceptance criteria from the PRD. R-09 (Slack) and R-11 (Manager weekly digest) are wired if capacity permits. The week-12 pen-test (PRD §NFR Security) returns no Critical findings, or every Critical finding has been resolved or risk-accepted in writing by the CEO.

**Why this gate:** the paying-pilot signature at week 14 is contingent on the pilot working as DartLogic uses it for two weeks (M2 -> M3). Two weeks is the minimum window that exercises the weekly-digest cycle, the at-risk pattern matching, and the HubSpot poll under DartLogic's real account volume.

**Out at M2:** R-08 (Salesforce, deferred), R-12 (in-app NPS, Could; cut if eng day-count bumps), R-13 (cohort report, Could; cut if eng day-count bumps).

### M3 (week 14): Paying-pilot gate

**Completion gate:** DartLogic uses Pulse for two weeks (weeks 13-14). The pilot success bar from PRD §Success criteria is met:

- L-1: 3 of 3 DartLogic AMs are weekly active with at least one logged touchpoint per week, by week 14. **Binary gate.**
- L-2: Time-to-log median <= 90s by week 14. **Binary gate.**
- L-3: Every later-flagged at-risk account had its first flag >= 30 days before its renewal date. **Reviewable, not strictly binary at week 14 because some at-risk-to-renewal windows extend past pilot-end. Carryover metric.**
- G-2: 12-month paid contract signed by week 14. **Binary gate. The pilot.**

If G-2 is signed: pilot is a success; v1.1 planning starts immediately. If G-2 is not signed: 4-week pilot extension per PRD Risk-04, before declaring failure.

## Slice queue (topologically sorted)

The slice queue is the production-ready input. Each slice is a vertical: schema + API + UI + tests, end-to-end, demo-able. The architecture's dependency graph (`EXAMPLE-ARCH.md` §10) drives the order.

### Now (weeks 1-6)

| Week | Slice | PRD ref | Owner | Days | Demo |
|---|---|---|---|---|---|
| 1 | **Foundation: tenant + user + magic-link sign-in** | R-01, R-07 (auth half) | Devon | 5 eng + 2 design | Lin signs in with magic-link, lands on an empty account list page |
| 2 | **Mock-data ingest path** (no HubSpot yet; CSV import for the 100 DartLogic accounts) | (R-06 placeholder) | Generalist | 4 eng + 1 design | A CSV of 100 accounts loads into the DB; appears on the account list |
| 3 | **Account list view (per-AM)** | R-02 | Devon + Anaya | 4 eng + 3 design | Lin's 100-account list renders < 800ms; sortable by recency-since-last-touchpoint |
| 4 | **Account detail page (read-only)** | R-02, R-03 prep | Generalist + Anaya | 4 eng + 2 design | Lin clicks an account, sees timeline (empty), profile, MRR, lifecycle stage |
| 5 | **Touchpoint log (R-03)** | R-03 | Mira-on-eng + Devon | 5 eng + 2 design | Lin logs a touchpoint; appears on timeline; <= 4s end-to-end |
| 6 | **M1 gate, demo to DartLogic** | (gate) | All | 3 eng + 2 design + 2 AE | M1 demo; pilot CSV ingested; L-2 metric instrumentation live |

**Now total: 25 eng-days + 12 design-days + 2 AE-days.** Buffer at end of week 6 if any slice slips.

### Next (weeks 7-12)

| Week | Slice | PRD ref | Owner | Days | Demo |
|---|---|---|---|---|---|
| 7 | **At-risk flag (R-04)** | R-04 | Devon | 4 eng + 2 design | Lin flags an account at-risk with a reason; appears on Devon's (mock) Manager view |
| 7-8 | **HubSpot sync (R-06)** -- highest risk | R-06 | Devon + Generalist | 8 eng (split across 2 weeks) | DartLogic's real HubSpot tenant connected; 15-min poll active; conflict policy verified |
| 8 | **Manager view + RBAC (R-07 second half)** | R-07 | Mira-on-eng | 4 eng + 2 design | Devon (DartLogic Head of CS) sees the team's books; flagged accounts surface |
| 9 | **At-risk pattern matcher + email notification (R-05)** | R-05 | Devon + Generalist | 5 eng + 1 design | A staged "no-touch-30d" account fires; Lin receives email within 1 hour |
| 10 | **Slack notification path (R-09 Should)** | R-09 | Generalist | 3 eng | Slack incoming-webhook configured per AM; same alert delivers to Slack |
| 10-11 | **Manager weekly digest (R-11 Should)** + **Reassignment audit (R-10 Should)** | R-10, R-11 | Mira-on-eng + Generalist | 5 eng + 1 design | Monday email arrives with at-risk count, AMs missing touchpoints, NPS responses; CSV export of last-90-days reassignments |
| 11 | **Audit log + admin tools** | R-07 admin half + NFR audit | Devon | 3 eng + 1 design | Sam (CEO) can pull the audit log of role changes, flags, reassignments |
| 12 | **Pen-test week (NFR Security)** | NFR | Devon (defends), external pen-tester | 5 eng (response + fixes) | All Critical findings resolved or risk-accepted; pen-test report archived |

**Next total: 37 eng-days + 7 design-days + 0 AE-days.** Tight; if HubSpot sync slips by 3 days, R-09 (Slack Should) is the first cut. If it slips 5 days, R-10 + R-11 (both Should) are cut and v1.1 picks them up.

### Later (weeks 13-14)

| Week | Slice | PRD ref | Owner | Days | Demo |
|---|---|---|---|---|---|
| 13 | **Pilot deployment to DartLogic production tenant** | (deploy gate) | Devon + Lin (AE) | 3 eng + 2 AE | DartLogic's 3 AMs onboarded; passwords / magic-link tested; Lin runs the on-call playbook |
| 13-14 | **Pilot week 1: at-risk pattern tuning, latency review, sync health** | (operations) | Devon + Generalist | 4 eng + 2 AE | L-2 metric reviewed Monday; thresholds adjusted; Risk-03 (noisy alerts) tracked |
| 14 | **M3 gate ceremony: paying-pilot signature** | M3 | All | 1 eng + 4 AE | DartLogic signs (or 4-week extension declared) |

**Later total: 8 eng-days + 0 design-days + 8 AE-days.**

### Capacity reconciliation

| Phase | Eng-days planned | Design-days planned | AE-days planned |
|---|---|---|---|
| Now (weeks 1-6) | 25 | 12 | 2 |
| Next (weeks 7-12) | 37 | 7 | 0 |
| Later (weeks 13-14) | 8 | 0 | 8 |
| **Plan total** | **70** | **19** | **10** |
| **Capacity available** | **140** | **42** | **14** |
| **Slack** | **70 days (50%)** | **23 days (55%)** | **4 days (29%)** |

Half the eng capacity is slack. This is intentional. The named risks (Risk-01 HubSpot rate limits, Risk-03 noisy alerts) and the named rabbit holes (multi-tenancy, sync correctness, notifications, reporting) consume slack first. Slack that survives gets spent on Should and Could items in priority order. Slack that survives all of those gets spent on the v1.1 Salesforce sync (R-08) early.

## Cutover cadence (for deploy-ready)

| Cutover | Week | Environment | Rollback policy |
|---|---|---|---|
| Internal staging | week 2 (continuous after) | staging.pulse.dev (single-region; same shape as prod) | last-known-good Docker image; one-click revert |
| Pilot pre-prod | week 6 (M1) | dartlogic-stage.pulse.dev (DartLogic-only; mock data) | last-known-good Docker image |
| Pilot production | week 13 | dartlogic.pulse.dev (DartLogic real data) | last-known-good Docker image; the DB migration policy is expand-contract per deploy-ready (no destructive migration in the pilot window) |

The deploy cadence is one cutover per week to staging during weeks 1-12; one cutover to pilot pre-prod at M1; one cutover to pilot production at week 13.

The deploy-ready discipline applies in full: same artifact promoted across environments; destructive DB migrations are forbidden between week 13 and week 14 (the pilot window). See `deploy-ready` skill for the cutover playbook.

## KPI handoff (for observe-ready)

| KPI | Definition | SLO target | Alert when | Source |
|---|---|---|---|---|
| Account-list latency (R-02) | API p95 latency for `GET /api/accounts` | <= 800ms p95 monthly | p95 >= 1200ms for 5 consecutive minutes | API server logs |
| Touchpoint-save E2E (R-03) | Time from `POST /api/touchpoints` to client-side acknowledgment | <= 4s median monthly | median >= 6s for 5 consecutive minutes | Client beacon + API logs |
| HubSpot sync freshness (R-06) | `now - max(last_synced_at)` per tenant | <= 20 minutes p99 monthly | >= 45 minutes for any tenant | Worker logs |
| Notification delivery (R-05) | `notification_sent_at - notification_triggered_at` | <= 1 hour p99 monthly | >= 2 hours p99 over an hour window | Worker logs |
| Auth failure rate | failed magic-link redemptions / total | <= 2% monthly | >= 5% over an hour window | Auth service logs |

The first four are PRD-derived; the last is harden-ready-derived (auth abuse signal). The observe-ready skill ratifies these into a runbook and on-call setup before the M3 paying-pilot gate.

## Launch-milestone gate (for launch-ready)

The pilot is a private launch. Pulse does not have a public-facing landing page or a launch-day external announcement at v1.0. The launch-ready skill picks up at v1.1 (post-paying-pilot, when generalized launch is on the calendar).

The week-14 paying-pilot ceremony is the public-facing event: a joint case-study post on DartLogic's blog (DartLogic-authored, Pulse-CEO-cited) and a Pulse blog post announcing the first paying customer. Both are out of launch-ready's tier-2 launch playbook scope; they are pilot-marketing artifacts.

## Risk register (active)

| ID | Risk | Owner | Mitigation tracked at | Status (week) |
|---|---|---|---|---|
| Risk-01 | HubSpot rate limit hits during multi-tenant 15-min poll | Devon | Architecture §7; week-3 integration smoke tests | Open |
| Risk-02 | Pilot AMs adopt for two weeks then stop | Lin (AE) | Weekly check-ins; counter-metric C-1 | Open |
| Risk-03 | At-risk pattern matching too noisy | Mira (PM) | Conservative thresholds; weekly review | Open |
| Risk-04 | DartLogic does not extend to 12-month contract | Sam (CEO) | Weekly pilot reviews; defined success bar | Open |

Each risk has an owner, a mitigation tracked in a specific named place, and a weekly review checkpoint. Risks without those three elements are not risks; they are anxiety.

## Roadmap failure modes refused

The grep tests this roadmap passes:

- **Fictional precision.** The capacity input is named (140 eng-days, 42 design-days, 14 AE-days). The plan uses 70 + 19 + 10 = 99 days against capacity, with explicit slack. No Gantt-to-the-day claims are made.
- **Fictional parallelism.** The slice queue lists at most one primary-owner slice per week per engineer. Two engineers means two parallel slices when work permits; the dependency graph (architecture §10) prevents fictional parallelism at the data-model level.
- **Quarter-stuffing.** The 14-week appetite is split into Now (6 weeks, 25 eng-days), Next (6 weeks, 37 eng-days), Later (2 weeks, 8 eng-days). The latter two phases carry less work as the pilot ceremony approaches.
- **Speculative features.** Every slice maps to a PRD R-NN entry. Items not in the PRD do not appear on the roadmap.
- **Feature-factory output.** Every row in the slice queue carries an outcome (the demo column) and a commitment (the milestone gate). No bare feature names.
- **Shelf roadmap.** The cadence is named (weekly review, bi-weekly demo, week-14 gate). The slice queue is the production-ready input; the cutover cadence is the deploy-ready input; the KPI table is the observe-ready input. The roadmap is consulted weekly because the milestones depend on it.
- **Roadmap theater.** No Gantt aesthetics. The capacity reconciliation column shows actual day-count math. The risk register has owners and review cadence.

## Downstream handoff

- **production-ready** consumes the §Slice queue. Slice 1 (foundation) is the first vertical to ship; production-ready's Step 4 ("Build the foundation slice") maps directly. Each subsequent slice is a vertical-slice unit by production-ready's discipline.
- **deploy-ready** consumes §Cutover cadence. The week-1, week-6, week-13 cutovers are the deploy events; the rollback policy and expand-contract migration discipline are deploy-ready's contract.
- **observe-ready** consumes §KPI handoff. The five SLOs become the observe-ready dashboards and the alert routing.
- **launch-ready** consumes §Launch-milestone gate. At v1.0 launch-ready is mostly out of scope; v1.1 brings the first generalized launch.
- **harden-ready** consumes §Risk register and the M2 pen-test week. Findings against the architecture's trust boundaries (architecture §6) are blocking for the M3 paying-pilot signature.
