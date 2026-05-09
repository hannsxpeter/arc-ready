# Post-mortems

Loaded at Step 11 of the workflow. Tier 4 gate. The incident-to-learning loop.

**Canonical scope:** blameless post-mortem format, causal analysis beyond Five Whys, action-item tracking, alert pruning after incidents, the observability-gap feedback loop. **See also:** `incident-response.md` for the severity ladder and IC role; `alert-patterns.md` for alert pruning; `slo-design.md` for the error-budget policy that interacts with post-mortem outcomes.

The one-line framing: every incident is input to the observability surface. If an incident does not produce at least one observability-gap action item (an alert that should have fired, a dashboard that should have existed, a runbook that was missing), the post-mortem was shallow.

---

## Part 1. Blameless format

Blame is cheap; learning is expensive. The format favors learning.

### 1.1 Principle

Blamelessness is not "no accountability." It is "the system produced the conditions under which the human decision was the decision they made." The post-mortem asks what conditions led to the decision, not who made the wrong one. Systemic fixes prevent the recurrence; personal blame does not.

Reference: [Etsy's debriefing culture](https://codeascraft.com/2012/05/22/blameless-postmortems/); [Google SRE Book chapter 15](https://sre.google/sre-book/postmortem-culture/).

### 1.2 Language

- Names attached to expertise: "@alex diagnosed the upstream dependency failure within 10 minutes."
- Not names attached to fault: "The developer who deployed this broke production."
- "We did X" or "the system did X" in place of "<name> did X."

### 1.3 Facts before narrative

- Timeline: what happened, in order, with timestamps. Recorded during the incident by the scribe.
- Observations: what the responders saw. What the metrics showed. What the logs revealed.
- Actions: what the responders did and why.
- Only after facts are captured: the narrative of cause and effect.

---

## Part 2. The post-mortem template

```markdown
# Post-mortem: INC-<NNN> - <short title>

## Summary
- **Date:** 2026-04-15
- **Duration:** 14:02 UTC to 15:48 UTC (1h 46m)
- **Severity:** SEV-1
- **Impact:** Login failed for ~12% of traffic over the affected window.
  Approximately 4,200 users received login errors. No data loss.
  No known security impact.
- **Root cause summary:** Database connection pool saturated after
  a deploy that introduced an N+1 query in the login path.
- **Status:** Resolved.

## Timeline
| Time (UTC) | Event |
|---|---|
| 13:56 | Deploy v1.12.3 shipped to prod. |
| 14:02 | login-slo-fast PAGE fires. @api-oncall takes page. |
| 14:05 | War room opens. @sre-oncall IC. |
| 14:10 | DB connection pool saturation observed on Grafana. |
| 14:15 | Rollback initiated (flyctl releases rollback). |
| 14:19 | Rollback complete; login error rate dropping. |
| 14:30 | Burn rate back within budget. |
| 15:00 | Confirmed resolved; status page updated. |
| 15:48 | Customer comms email sent. Incident closed. |

## Impact
Approximately 4,200 users received login errors between 13:58 and 14:25.
Error rate peaked at 42%. SLO budget for login consumed: 31% of the 30-day
budget in a single incident.

## What went well
- PAGE fired within 4 minutes of deploy.
- Rollback completed in under 5 minutes.
- War-room coordination was effective; IC handoff happened cleanly when
  @sre-oncall had to step away briefly.
- Status-page updates were on cadence.

## What went wrong
- The connection-pool saturation was not directly observable on the login
  primary dashboard. The on-call had to navigate to the database drilldown
  to see it. This added ~3 minutes to triage.
- The N+1 query that caused the saturation was not caught by pre-deploy load
  testing. Load testing covers steady-state traffic but not the amplification
  that N+1 creates under concurrent requests.
- The runbook's "check recent deploys" step was step 2, but the operator
  jumped to step 3 first because the deploy annotation was not visible on
  the primary dashboard.

## Why did it happen (causal analysis, not Five Whys specifically)
- A feature was added to return user preferences on login response.
- The preference fetch was implemented as a per-user query in a loop
  rather than a batch query.
- Code review did not catch the N+1.
- Pre-deploy load testing passed because the test fixture used one user.
- The canary phase in deploy-ready passed because the canary population
  was small and the pool pressure was not yet visible.
- At full traffic post-rollout, the pool saturated.

Multiple contributing factors, not a single root cause. The N+1 was the
immediate trigger; the lack of N+1-aware load testing, the gap in code
review signal, the canary population size, and the dashboard drilldown
required are all contributing and all fixable.

## Action items
| # | Action | Owner | Due | Impact |
|---|---|---|---|---|
| 1 | Add connection-pool saturation to login primary dashboard (above fold). | @api-team | 2026-04-22 | Observability gap. |
| 2 | Add deploy annotations on the login burn-rate chart. | @api-team | 2026-04-22 | Observability gap. |
| 3 | Update the login-slo-burn runbook to point to the connection-pool chart. | @api-team | 2026-04-25 | Runbook correctness. |
| 4 | Implement N+1 detection in code review (linter or CI check). | @platform | 2026-05-15 | Root cause mitigation. |
| 5 | Extend load-testing fixture to include multi-user scenarios. | @platform | 2026-05-22 | Root cause mitigation. |
| 6 | Review canary population sizing for pool-pressure visibility. | @deploy-team | 2026-05-22 | Deploy mechanics. |

Every action item is tracked in the team backlog with the due date.
Follow-up retro in two weeks confirms closure.

## Paper-runbook and paper-SLO checks
- Paper runbook check: login-slo-burn runbook last executed 2026-03-15.
  Executed during this incident (2026-04-15). Confirmed correct; one
  dashboard-link update needed (action item 3).
- Paper SLO check: login SLO has an active error-budget policy;
  the 31% budget burn triggers the policy at the next weekly check.
  Product has been notified.

## Observability gaps identified
- Gap 1: connection-pool saturation not above the fold on login primary.
  Action item 1.
- Gap 2: deploy annotations missing. Action item 2.
- Gap 3: no pre-deploy N+1 detection. Action item 4 (out of observe-ready
  scope; tracked as deploy-pipeline improvement).

## Alerts firing during the incident
| Alert | Useful? | Action |
|---|---|---|
| login-slo-fast | Yes; fired at +4min from deploy. | Keep. |
| login-slo-medium | Yes; fired shortly after. | Keep. |
| db-connection-pool-saturation | No; was a TICKET. Did not page. | Upgrade to PAGE with runbook. |
| db-cpu-high | No; fired but was a cause metric without predictive value. | Consider demote to LOG-ONLY. |

## Lessons
- Dashboards need deploy annotations by default.
- N+1 detection is a deploy-pipeline concern that intersects with observability
  (the saturation metric exists; making it prominent is the observability fix).
- Canary population sizing is a deploy-ready concern; observability alone
  could not have prevented the incident but could have detected it ~2 min
  sooner.

## Follow-up
- Post-mortem review in team retro: 2026-04-22.
- Action-item closure check: 2026-05-29.
- Public-facing customer writeup: published at status.example.com/incidents/INC-NNN
  on 2026-04-18.
```

---

## Part 3. Causal analysis beyond Five Whys

Five Whys is useful. It is also simplistic: real incidents often have multiple contributing factors, not a single deep cause.

### 3.1 Why Five Whys falls short

A single-chain "why" analysis suggests there is one root cause. Most outages are combinations: the code bug plus the missing alert plus the untested rollback plus the slow human response. Fixing only the code bug leaves the other three in place.

### 3.2 Alternatives

- **Causal analysis / contributing factors tree.** List every condition that had to be true for the incident to happen. Each condition is a potential intervention point.
- **Swiss cheese model.** Incidents happen when holes in multiple layers of defense align. The post-mortem identifies which holes were present; action items close holes in multiple layers.
- **Learning from incidents (John Allspaw and the LFI community).** Focuses on the messy human decisions under uncertainty, not just the technical chain. [Howie's blog](https://www.adaptivecapacitylabs.com/blog/) is a canonical resource.

### 3.3 Practical structure

The "Why did it happen" section of the template enumerates contributing factors, not a single root cause. Action items address multiple factors.

---

## Part 4. Action-item tracking

Action items without owner, due date, and closure check are wishes. Tracked action items are the incident-to-learning loop.

### 4.1 The fields

| Field | Must be present |
|---|---|
| Description | What will be done. |
| Owner | Named person or team. |
| Due date | Specific calendar date. |
| Impact | Which observability gap or root-cause mitigation. |
| Status | Open / in progress / closed. |
| Verification | How we know the action was effective. |

### 4.2 The closure cadence

Every sprint retro (or equivalent cadence), the team reviews open action items:

- What is closed? Verification confirmed?
- What is in progress? On track for the due date?
- What is at risk? Re-scope or re-prioritize.
- What is blocked? Escalate.

Action items silently aged past due without closure are a process failure. Track them in the team backlog; escalate to engineering management if a SEV-1 action item is 30+ days past due.

### 4.3 The follow-up retro

Two weeks after the incident: a dedicated 15-minute retro reviews the action items from this specific post-mortem. This is the closure check. Any item not closed gets a re-scope or an explicit deferral.

---

## Part 5. Observability-gap action items

Every incident must produce at least one observability-gap action item. If the post-mortem does not surface one, the team should ask harder.

### 5.1 Types of observability gap

- **Missing alert.** An SLI was breaching but no alert fired; the incident was detected by a human noticing or a customer complaint.
- **Late alert.** The alert fired, but too late to catch the incident early enough.
- **Noisy alert.** Many alerts fired; the actionable one was lost in noise.
- **Missing dashboard chart.** The on-call needed a signal that was not above the fold; triage took longer.
- **Missing runbook step.** The runbook had a gap; the on-call had to improvise.
- **Paper runbook.** The runbook's commands were stale.
- **Unreachable runbook.** The runbook was hosted on infrastructure affected by the incident.
- **Missing trace.** Sampling dropped the incident trace; the postmortem had no per-request detail.
- **Missing log field.** A log field that would have answered a question was not present.
- **Dependency chain invisibility.** The chain from cause to effect was not observable; the on-call had to guess.

Each gap is a specific fix the observability surface can make. Track it.

### 5.2 The observability-gap action-item loop

The action items feed back into the observe-ready workflow:

- Missing alert -> Step 5 alert-pattern work.
- Missing dashboard chart -> Step 6 dashboard-design work.
- Missing runbook step -> Step 9 runbook discipline.
- Missing trace -> Step 7 tracing / sampling work.
- Missing log field -> Step 2 logging work.

The post-mortem is the trigger; the follow-on session closes the loop.

---

## Part 6. Alert pruning after the incident

The post-mortem's "Alerts firing during the incident" table is where alert pruning happens. The GitHub 2018 pattern ("alerts fired in volume, signal-to-noise dropped under load") is prevented by pruning after each incident.

### 6.1 Per-alert review

For every alert that fired during the incident:

- Was it useful? (Did the responders read it, and did it inform their actions?)
- Was it timely? (Did it fire early enough to matter?)
- Was it correct? (Did it reflect real conditions or a false positive?)

Actions:

- Keep (useful, timely, correct).
- Tune (useful but needs threshold adjustment).
- Upgrade (should have been PAGE, was TICKET).
- Demote (PAGE that was noise; make TICKET or LOG-ONLY).
- Delete (fired but not useful, not tuneable).

### 6.2 Feeds alert-patterns pruning cadence

The incident-time alert review feeds the quarterly pruning cadence in `alert-patterns.md` section 7. The two reinforce each other: quarterly catches dead alerts; per-incident catches noisy ones.

---

## Part 7. Public post-mortem discipline

For SEV-1 incidents that affected external customers, a public post-mortem is standard industry practice.

### 7.1 Timing

- Initial status-page summary: within 72 hours.
- Full public post-mortem: within 14 days.
- Long-delay post-mortems (security, legal review): publish a summary; defer the full analysis with a named reason.

### 7.2 Content

A public post-mortem is an edited subset of the internal. Include:

- Summary of the incident.
- Impact (customer-visible).
- Timeline.
- What went wrong.
- What we are doing.

Exclude:

- Internal service names that would help attackers.
- Details that would expose the vendor, customer, or upstream beyond what is necessary.
- Blame language about specific engineers.

### 7.3 Examples

- [Slack January 2021](https://slack.engineering/slacks-outage-on-january-4th-2021/).
- [Roblox 2021](https://about.roblox.com/newsroom/2022/01/roblox-return-to-service-10-28-10-31-2021).
- [Cloudflare June 2022](https://blog.cloudflare.com/cloudflare-outage-on-june-21-2022/).
- [GitHub October 2018](https://github.blog/2018-10-30-oct21-post-incident-analysis/).
- [AWS DynamoDB 2025](https://www.infoq.com/news/2025/11/aws-dynamodb-outage-postmortem/).

All are published, detailed, and cited in `RESEARCH-2026-04.md`.

---

## Part 8. The "no incidents this quarter" note

Not every quarter has SEV-1s. If the quarter was quiet, the post-mortem discipline still applies: the team writes a brief retrospective:

- What near-misses happened (TICKET-severity issues that could have been worse)?
- What observability gaps were surfaced in normal operations?
- Is the on-call load healthy?
- Are alerts still tuned correctly after a quarter of no-fires?

The note is short; its purpose is to prevent "no incidents" from becoming "no observability work."

---

## Part 9. The retrospective cadence

- Per incident: post-mortem within 5 business days (SEV-1), 10 business days (SEV-2).
- Per sprint: review open action items from recent post-mortems.
- Per quarter: meta-retrospective on the incident pattern, alert pruning log, runbook execution log, paper-SLO watchlist.
- Per year: annual reliability review. Trend of SLO attainment. Cost of observability. Changes to the observability surface.

---

## Part 10. Checklist for Step 11 completion

- [ ] Every SEV-1 and SEV-2 incident in the last quarter has a post-mortem using the fixed template.
- [ ] Every post-mortem has named action items with owners, due dates, and closure verification.
- [ ] Every post-mortem surfaces at least one observability-gap action item.
- [ ] Alert review is part of every post-mortem.
- [ ] A follow-up retro two weeks post-incident confirms action-item closure.
- [ ] Public post-mortems for SEV-1 customer-affecting incidents are published on cadence.
- [ ] If no incidents this quarter, a "quiet quarter" retrospective is written.
- [ ] Quarterly meta-retrospective reviews the pattern of incidents, alerts, and runbooks.

When every box is checked, Step 11 is complete. The Tier 4 goal is met.
