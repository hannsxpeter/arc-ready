# Incident response

Loaded at Step 9 (runbook discipline) and Step 11 (severity ladder, incident commander, comms). Tier 3 and Tier 4.

**Canonical scope:** the runbook template, the runbook execution cadence, severity ladder, incident commander role, war-room protocol, status-page discipline, customer communication. **See also:** `post-mortem.md` for the learning loop; `alert-patterns.md` for the alert-to-page-to-runbook pipeline; `dashboards.md` for what the on-call opens when the page fires.

The one-line framing: a runbook is executable documentation the on-call uses at 3am with one browser tab. A **paper runbook** is a runbook written once, attached to an alert, and never executed; its commands reference log fields that have been renamed. observe-ready refuses both.

---

## Part 1. The runbook template

Every PAGE alert links to a runbook. Every runbook follows the same shape, so the on-call can read any runbook in any service without context-switching.

```markdown
# Runbook: <alert name>

## Alert context
- **SLO:** <which SLO this alert defends>
- **Journey:** <which user journey>
- **Service:** <which service>
- **Severity:** PAGE | TICKET
- **Expected frequency:** <e.g., < 1/month>
- **Owner:** @team
- **Last executed:** 2026-03-18 (tabletop)
- **Last reviewed:** 2026-04-15

## What the alert means
<One paragraph on what is happening when this alert fires. Written in plain English.
Not "the burn rate exceeded 14.4x;" rather "login is failing faster than the SLO allows,
which means real users are seeing signup or login errors at this minute.">

## Diagnose
### Step 1. Confirm user impact
```bash
# Is login actually failing?
curl -i https://api.example.com/healthz
curl -i -X POST https://api.example.com/login -d '{"email":"test@example.com","password":"..."}'
```
Expected: 200 OK on healthz; 200 or 401 on login.

### Step 2. Check recent deploys
Open https://grafana.example.com/d/login-primary and look at the deploy annotations.
If a deploy in the last hour corresponds to the burn start, it is the candidate cause.

### Step 3. Check upstream dependencies
```bash
# Auth provider status
curl -s https://status.authprovider.com/api/status
# DB primary latency
# (Query the Grafana login drilldown panel "DB primary latency p99")
```

### Step 4. Check error tracker for a concentrated signature
Open https://sentry.example.com/issues/?project=api&release=<current-release>
If one signature accounts for >50% of errors, the fix is that error.

## Act
Decision tree (pick one):

### A. Recent deploy correlates with burn
Rollback via deploy-ready:
```bash
flyctl releases rollback <previous-release-id>
```
Confirm burn rate drops in 5-10 minutes. If not, go to C.

### B. Upstream dependency degraded
Post in #incidents: "login-slo-burn; upstream auth provider degraded; tracking upstream status."
Open status page; update customer comms.
Do not rollback; the app is not the source.

### C. No clear cause
Escalate to IC on-call: @sre-oncall (see on-call schedule at https://pagerduty.example.com).
Open war room: #incident-<INC-NNN> Slack channel.
Bring one engineer from @api-team and one from @platform.

## Communicate
- **< 15 minutes:** first status-page update.
- **Every 30 minutes thereafter:** status-page update with progress.
- **Resolution:** status-page update + customer email if > 1 hour.

## Escalation
- IC on-call: PagerDuty, @sre-oncall. Phone: +1-555-...
- Engineering director: @alex, Phone: +1-555-...
- CEO (SEV-1 only after 2 hours): @sam, Phone: +1-555-...

## Post-incident
- Incident log: `.observe-ready/incidents/INC-NNN.md`
- Post-mortem due: within 5 business days.
- Action items tracked in <team backlog>.

## Known false positives
- During the nightly backup at 03:00 UTC, DB latency p99 spikes for ~90 seconds; burn rate fast tier
  can fire briefly. If the burn clears within 5 minutes and no error spike, mark as known noise.
```

### 1.1 What makes this template work

- **Executable commands.** Not "look at the dashboard;" a URL to the dashboard. Not "check the deploy;" the command and expected output. An on-call under stress copies and pastes; the runbook has to be paste-ready.
- **Decision tree, not prose.** A, B, or C; pick one. No "it depends on the context of the situation."
- **Named escalation with phone numbers.** The 3am version of "ping someone in Slack" does not work if Slack is the incident.
- **Known false positives section.** Every runbook accumulates a handful; documenting them prevents the on-call from opening a war room for a known nightly blip.

### 1.2 What breaks a runbook

- **Generic commands.** "Check the logs." Which command? What flags?
- **Links to directories.** "See the dashboards." Which dashboard? Direct link.
- **Prose decision process.** "Consider whether the issue is a deploy, a dependency, or something else." Three branches with explicit conditions instead.
- **Stale shell commands.** The grep command that references `request_id` after the log schema renamed it to `trace_id`. Paper runbook. Step 9's `last_executed` discipline is the defense.

---

## Part 2. Runbook execution cadence

A runbook's `last_executed` date is load-bearing. 90 days is the soft floor; 180 days is the hard floor. Past 180 days without execution, the runbook is paper.

### 2.1 Tabletop exercises

The cheapest way to execute a runbook without an incident. The on-call walks through the runbook step by step against a staging copy of the service:

- Confirm each command still runs.
- Confirm each dashboard link still resolves.
- Confirm each named person is still in the role.
- Confirm the diagnostic output matches the runbook's expected output.

Anything that does not match is fixed in the runbook in-session.

Tabletop for every PAGE runbook: once per quarter. Budget for it; it is the defense against drift.

### 2.2 Incident execution

Every real incident executes the runbook. The runbook update happens in the post-mortem:

- What did the runbook get right?
- What did it get wrong?
- What step was missing?

Action items from the post-mortem update the runbook.

### 2.3 New-hire execution

When an engineer joins the on-call rotation, they walk each runbook for their service. This is both training and a runbook audit; new eyes catch stale references fast.

---

## Part 3. Runbook hosting and reachability

A runbook hosted on the service it documents is an **unreachable runbook**. Facebook 2021 and Roblox 2021 are the citations.

### 3.1 Independence options

| Where | Reachable during app outage? |
|---|---|
| Confluence, Notion, same SSO as app | No if SSO is the problem. |
| Confluence, Notion, different SSO | Yes. |
| GitHub wiki with github.com SSO | Yes unless GitHub is the problem. |
| Static site mirror (read-only copy of the runbooks) hosted on a different provider | Yes. |
| Printed cards in the DC or on-call's physical location | Yes. |

The skill's recommendation: runbooks live in git, mirrored to a static-site reader hosted on an independent provider. Updates push via CI; readers hit the static site.

### 3.2 The linked-from-the-alert URL

PagerDuty / incident.io alert payload includes the runbook URL directly. The on-call opens the alert, clicks the runbook link, lands on the runbook. No wiki search, no "let me find the Confluence page."

### 3.3 The runbook-index page

For every service, a single index page listing all runbooks with their `last_executed` dates. The quarterly review runs against this page.

---

## Part 4. Severity ladder

Three tiers. Same rationale as the alert-severity ladder.

| SEV | Definition | Response |
|---|---|---|
| **SEV-1** | User-visible, widespread, active. Significant fraction of users seeing a major outage or data loss. | IC opens war room within 15 min; status page within 15 min; customer comms within 30 min; every 30 min thereafter. |
| **SEV-2** | User-visible, bounded or degraded. Some users affected or feature-level degradation. | IC optional; status page within 30 min; customer comms if > 1 hour. |
| **SEV-3** | Internal-visible. No user impact yet. Paged because an SLO budget is burning and will reach user-visibility soon. | Ticketed; triage in business hours unless escalating. |

### 4.1 Declaration

The on-call who takes the page declares the SEV on first triage. IC (if engaged) can adjust.

### 4.2 SEV-1 triggers

- Core user-facing service unavailable or > 10% error rate.
- Data-loss event (ongoing).
- Security incident that breaches user data.
- Payment or billing failures at scale.

---

## Part 5. Incident commander role

Named per incident. Runs the war room; does not fix.

### 5.1 Responsibilities

- Declare the SEV and communicate it.
- Open the war room (Slack channel or Zoom) and invite responders.
- Keep the timeline: "at 14:02 we did X, at 14:07 we observed Y."
- Handle external communication (status page updates, customer comms) or delegate to a comms lead.
- Decide when to escalate.
- Decide when the incident is resolved and call it.

### 5.2 The IC does not fix

The IC coordinates. The subject-matter experts (SMEs) fix. This separation prevents the best debugger from also being the comms person while also watching Slack.

### 5.3 IC rotation

On call-based rotation, separate from the service-specific on-call. Often drawn from SRE, platform, or engineering management. The IC can be from any team but is trained specifically in the IC protocol.

### 5.4 IC handoff

Long incidents hand off the IC role every 4-6 hours. Fresh eyes, fresh energy, documented handoff (the timeline and the current state).

---

## Part 6. War-room protocol

The war room is a dedicated Slack channel or a Zoom call opened per incident.

### 6.1 Channel naming

`#incident-YYYY-MM-DD-<slug>` or `#incident-NNN`. Persistent post-incident; the timeline stays for the post-mortem.

### 6.2 Roles

- **IC.** Drives.
- **Comms.** Handles external updates.
- **SME (or several).** Fixes.
- **Scribe.** Records the timeline; posts observations and actions. On small teams, the IC doubles as scribe.

### 6.3 Cadence

- IC calls a sync at incident start, then every 20-30 minutes, until resolution.
- Syncs are short (5 min): what do we know, what are we trying, who is doing what.
- Between syncs, SMEs work; Comms communicates.

### 6.4 Zoom vs. Slack

- Slack: better for async updates, durable timeline, easier to include people who join late.
- Zoom: better for coordination, screen sharing, faster resolution of misunderstanding.
- Modern practice: both. Slack as the system of record, Zoom as the work surface.

---

## Part 7. Status page discipline

The status page is the public version of the incident timeline. It exists to reduce support-ticket volume and set customer expectation.

### 7.1 Hosted independently

The status page runs on infrastructure independent of the app. Statuspage.io (Atlassian), Instatus, Better Stack's status page, internal-hosted on a distinct region / provider.

The Datadog 2023 pattern: the observability vendor's status page went down with the observability vendor. Hosting on a distinct provider is cheap insurance.

### 7.2 Update cadence

- **< 15 min** from detection for SEV-1.
- **< 30 min** from detection for SEV-2.
- **Every 30 min thereafter** until resolution.
- **Resolution update** within 15 min of actual resolution.

### 7.3 What to say

- **Detected.** "We are investigating reports of <problem> on <feature>. Users may experience <impact>."
- **Progress.** "We have identified the cause. Fix in progress."
- **Resolved.** "The issue is resolved as of <time>. <Summary of cause>. A full post-mortem will be published within <timeframe>."

Templates in advance. Do not write under pressure.

### 7.4 What not to say

- Internal language ("the Kafka consumer group rebalanced").
- Blame ("due to a vendor outage upstream").
- Premature resolution claims.
- Silence. A 90-minute gap with no update sends customers to Twitter.

---

## Part 8. Customer communication

Separate track from status page. Email, in-app banner, account-manager outreach.

### 8.1 Templates

- **SEV-1 ongoing email** to affected users: factual, empathetic, specific.
- **SEV-1 resolved email**: summary, impact, what we are doing to prevent.
- **SEV-2 resolved email** (only if > 1 hour): brief summary; some customers prefer not being notified at all for short issues.
- **Enterprise account outreach**: named account manager reaches out to top accounts during the incident.

### 8.2 The one-page-per-incident policy

For SEV-1 incidents: publish a one-page customer-facing summary within 72 hours. Public post-mortem within 14 days. Both live on the status page's incident history.

---

## Part 9. On-call ergonomics

Paging a human at 3am is expensive in a human sense. The on-call experience shapes the team's reliability culture.

### 9.1 Rotation

- Weekly rotation is standard.
- Follow-the-sun is better for distributed teams, but requires enough rotation members in each time zone.
- Secondary on-call for every primary: a backup who takes over if the primary does not respond in N minutes.

### 9.2 Compensation

- Overtime pay or comp time for after-hours pages.
- Post-incident on-call person gets the next business day off, or at least the morning, if the incident ran past midnight.

### 9.3 Feedback loop

- Post-shift retro: the on-call writes a short note on the week. Pages received, alerts useful vs. noisy, runbooks executed, runbook updates made.
- Quarterly on-call report: trends across the team. If one service pages 5x what another does, that is a signal to the team.

### 9.4 The on-call package

Every on-call member has, at shift start:

- Access to PagerDuty (or equivalent).
- Access to the runbook index.
- Access to production credentials or the ability to get them in an emergency.
- Contact info for SMEs per service.
- Contact info for IC on-call.
- A laptop in reachable condition.
- Up-to-date familiarity with the tier-3 runbooks (from last quarter's tabletops).

---

## Part 10. Checklist for Step 9 and Step 11 completion

Step 9 (runbook discipline):

- [ ] Every PAGE alert has a runbook URL in its payload.
- [ ] Every runbook follows the fixed template (alert context, diagnose, act, communicate, escalation, post-incident).
- [ ] Every runbook has a `last_executed` date in the last 90 days.
- [ ] Runbooks are hosted on infrastructure independent of the observed service.
- [ ] Tabletop exercise schedule is on the calendar (quarterly per runbook minimum).

Step 11 (incident response):

- [ ] Severity ladder (SEV-1, SEV-2, SEV-3) is declared with named response expectations.
- [ ] IC role is on a rotation; IC training is documented.
- [ ] Status page is hosted on independent infrastructure.
- [ ] Status page update cadence is declared (15 min for SEV-1, 30 min thereafter).
- [ ] Customer communication templates are written in advance.
- [ ] On-call rotation has a secondary for every primary.
- [ ] On-call compensation policy is declared.

When the Step 9 boxes are checked, Step 9 is done. Step 11 continues in `post-mortem.md`.
