# Alert patterns

Loaded at Step 5 of the workflow. Tier 2 gate. Every alert derives from an SLO; every page is actionable or it is pruned.

**Canonical scope:** symptom-based pages, cause-based diagnostics, multi-window multi-burn-rate alerting, the three-tier severity ladder, alert routing independence, the pruning cadence. **See also:** `slo-design.md` for the SLO-and-budget input; `incident-response.md` for what happens after the alert fires; `vendor-landscape.md` for configuration deltas across PagerDuty, incident.io, and vendor-native alert routers.

The one-line framing: an alert that pages a human must represent an ongoing or imminent problem with your service, it must be actionable, and it must carry the runbook that makes action possible. Rob Ewaschuk's "Philosophy on Alerting" (2013) is where this starts; the SRE Book chapter 6 codifies it; every serious practitioner since has reproduced the same principle. The data in section 6 below says it is ignored in practice at scale.

---

## Part 1. The three severity tiers

observe-ready uses three, not more. More tiers create ambiguity and demand routing logic that fails under stress.

| Tier | Urgency | Channel | Acknowledgement expectation |
|---|---|---|---|
| **PAGE** | Urgent, user-visible, budget-burning. Wake someone up. | PagerDuty (or equivalent) via SMS / voice / app push. | Within minutes. |
| **TICKET** | Latent. Needs attention this business day. | Team channel; ticket in the queue. | Within the business day. |
| **LOG-ONLY** | Trend or diagnostic. Review weekly or in the relevant dashboard. | Dashboard; weekly ops review. | No acknowledgement. |

An AI-generated config typically ships every alert at PAGE severity because the demo did. The first Step 5 pass demotes most of them to TICKET or LOG-ONLY.

### 1.1 How to tier a proposed alert

1. Does the condition represent a user-visible problem or an imminent one (budget burning fast)? If yes, PAGE. If not, not PAGE.
2. Is the condition something that needs a human today but not now? TICKET.
3. Is the condition an interesting trend? LOG-ONLY.
4. Is the condition something nobody will act on? Delete it.

### 1.2 Why not more tiers

PagerDuty and incident.io default UIs let you pick P1/P2/P3/P4/P5. Tempting, but unhelpful. The difference between P2 and P3 is a judgment call; the difference between PAGE and TICKET is a behavioral commitment (do I wake up or not). Commit to behavior; three tiers force clarity.

---

## Part 2. Symptom-based pages, cause-based diagnostics

Rob Ewaschuk's canonical position: "pages should be urgent, important, actionable, and real. They should represent either ongoing or imminent problems with your service" ([Ewaschuk, "My Philosophy on Alerting"](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit)). The SRE Book chapter 6 formalizes it as **symptom-based alerting**: alert on user-visible problems, not on causes.

### 2.1 Symptom signals (can page)

- User-visible error rate breaching SLO burn threshold.
- User-visible latency breaching SLO burn threshold.
- Request throughput deviation (drop below expected floor, spike above expected ceiling) if either breaks the journey.
- Data freshness breaching SLO.
- Availability (heartbeat absent) if the service must be reachable.

### 2.2 Cause signals (never page directly; they go to TICKET or LOG-ONLY)

- CPU > 80%.
- Memory > 75%.
- Disk > 90%.
- Queue depth > N (unless the journey's freshness SLO is burning; then the symptom already pages).
- Connection pool > X%.
- Error count > 0 (always false; any non-toy service has non-zero errors).
- Any threshold on a cause that does not predict SLO burn in a short horizon.

### 2.3 The exception: predictive cause alerts

Some cause metrics predict symptom failure with high confidence: "disk will fill in < 6 hours at current rate." These can PAGE if the lead time is short and the SLO impact is certain. The rule: the alert message and runbook must make the predictive nature explicit so the on-call does not confuse it with a symptom. Most cause metrics do not qualify; disk-fill is the classic one that does.

### 2.4 The Charity Majors position

"On-call alerting should be triggered by service level objectives (SLOs) rather than simply being triggered by infrastructure failure or monitoring threshold breaches, and engineers should only be woken up if the business is being impacted" ([InfoQ interview](https://www.infoq.com/articles/charity-majors-observability-failure/)). observe-ready adopts this position as operational default.

---

## Part 3. Multi-window multi-burn-rate alerting

The SRE Workbook's alerting-on-SLOs chapter is the canonical source ([Google SRE workbook](https://sre.google/workbook/alerting-on-slos/)). Every SLO-aware observability vendor (Datadog, Grafana, Nobl9, Honeycomb) has reproduced this pattern.

### 3.1 The four-tier matrix

Default tiers for a 30-day rolling-window SLO:

| Tier | Burn rate | Long window | Short window | Severity | Consumes (if sustained) |
|---|---|---|---|---|---|
| Fast-acute | 14.4x | 1 hour | 5 min | PAGE | 2% of budget per hour |
| Medium | 6x | 6 hours | 30 min | PAGE | 5% of budget per 6 hours |
| Slow | 3x | 24 hours | 2 hours | TICKET | 10% of budget per day |
| Drift | 1x | 72 hours | 6 hours | TICKET | 10% of budget per 3 days |

Both windows must breach simultaneously for the alert to fire. The short window preserves detection speed; the long window filters noise.

Reference implementations:

- [Grafana Cloud multi-burn-rate guide](https://grafana.com/blog/how-to-implement-multi-window-multi-burn-rate-alerts-with-grafana-cloud/).
- [Datadog "burn rate is a better error rate"](https://www.datadoghq.com/blog/burn-rate-is-better-error-rate/).
- [OneUptime's GCP multi-burn-rate guide](https://oneuptime.com/blog/post/2026-02-17-how-to-set-up-multi-window-multi-burn-rate-alerting-for-slos-on-google-cloud/view).
- Nobl9 and Chronosphere emit these alert shapes first-class.

### 3.2 Why single-window alerts fail

Single-window alerts are either:

- **Too short:** fire on every 2-minute blip. Noisy. The on-call mutes it.
- **Too long:** the budget is half-gone before the alert trips. Slow to detect.

The SRE Workbook math shows that multi-window preserves both detection speed and signal quality. An AI-generated "alert when error rate > 1%" is a single-threshold, single-window alert. Replace with the four-tier matrix derived from the SLO.

### 3.3 Example PromQL / Grafana implementation

For an SLO of 99.9% success:

```promql
# Fast tier (14.4x burn, 1h window, 5m short window)
(
  (1 - (sum(rate(http_requests_total{service="api", status_class!~"5.."}[1h])) / sum(rate(http_requests_total{service="api"}[1h])))) > (14.4 * (1 - 0.999))
  AND
  (1 - (sum(rate(http_requests_total{service="api", status_class!~"5.."}[5m])) / sum(rate(http_requests_total{service="api"}[5m])))) > (14.4 * (1 - 0.999))
)
```

The abbreviated form using `sloth` or `pyrra` (Prometheus-native SLO compilers) or Grafana's SLO UI generates this mechanically from the SLO spec. Use the tooling; hand-authored PromQL for four tiers is error-prone.

---

## Part 4. Every PAGE has a runbook URL

The runbook URL is part of the alert payload. Not a reference to a wiki directory; a deep link to a specific runbook for this alert.

### 4.1 PagerDuty payload contract

```yaml
alert:
  summary: "login SLO fast burn (14.4x)"
  severity: PAGE
  details:
    slo: login-availability
    current_burn: 18.2x
    runbook: https://runbooks.example.com/login-slo-burn
    dashboard: https://grafana.example.com/d/login-primary
    owner: api-team
    service: api
```

### 4.2 The runbook URL field is mandatory

No runbook URL = not a PAGE. Demote to TICKET until a runbook exists. If the alert is genuinely critical, writing the runbook is the first fix in this pass.

### 4.3 Runbook discipline

See `incident-response.md` for the runbook template. The short version: executable commands, last-executed date, out-of-band hosting.

---

## Part 5. Alert routing independence

"If PagerDuty posts only to Slack, and Slack depends on the service that is down, the pager is dependent."

### 5.1 The Facebook 2021 pattern

When Facebook's BGP routes withdrew, operators could not reach internal tools; many of those tools used the same IdP or the same network paths that had failed. The alert infrastructure that would normally route the notification was itself dark.

### 5.2 Default routing: SMS or voice, not Slack only

PagerDuty and incident.io both page via SMS and voice by default, not just Slack. Verify the default is active.

### 5.3 The dependency-test rows

| Dependency | Fix |
|---|---|
| Pager service SSO via the same IdP as the app | Separate IdP for the pager service, or exemption with a phone-number fallback. |
| Pager service hosted in the same cloud region as the app | Pager vendor hosted independently (PagerDuty is multi-region and cross-provider). |
| Slack channel integration as the only notification path | Add SMS / voice / mobile-app push as primary. |
| Phone numbers stored in a system that depends on the app | Phone numbers kept in the pager vendor's own contact method, not an internal directory. |
| On-call rotation calendar on the same infrastructure as the app | Pager vendor's native rotation, or an independent calendar (Google Calendar). |

### 5.4 The physical fallback

For severe cases (critical infrastructure, financial services, life-safety systems): a printed phone tree kept at the on-call's physical location. Low-tech; works when everything else fails.

---

## Part 6. Alert-fatigue data and the false-positive baseline

The industry data is unambiguous.

- Incident.io 2025 survey: "85% of teams report that the majority of their alerts are false positives" ([incident.io](https://incident.io/blog/alert-fatigue-solutions-for-dev-ops-teams-in-2025-what-works)).
- "67% of engineers admit to ignoring or dismissing alerts without investigating."
- "73% of organizations experienced outages linked to ignored alerts."
- PagerDuty's Event Intelligence markets a 98% noise-reduction number, implying the baseline is 2% signal ([PagerDuty](https://www.pagerduty.com/resources/digital-operations/learn/alert-fatigue/)).
- Runframe 2026 State of Incident Management: toil rose 30% in 2025, the first increase in five years ([Runframe](https://runframe.io/blog/state-of-incident-management-2025)).

The GitHub 2018 incident is the operational version of these numbers: alerts fired in high volume, triage time under load was a response-time tax ([GitHub](https://github.blog/2018-10-30-oct21-post-incident-analysis/)).

observe-ready's position on the numbers: the team's alert set should produce roughly low-single-digit pages per on-call shift, with >80% of pages resulting in direct operator action. Anything beyond that is noise budget that should have been pruned.

---

## Part 7. Alert pruning: the quarterly pass

Dead alerts accumulate. So do alerts that fire constantly and are muted in effect.

### 7.1 Pruning criteria

- **Never fired in 90 days.** Candidate for deletion. Verify the underlying SLO still exists; if yes, is the alert still the right shape? If yes, keep; if the condition cannot fire, delete.
- **Fired and was dismissed without action > 3 times.** Threshold too low, condition wrong, or the on-call does not consider it actionable. Tune or delete.
- **Fired and was acknowledged but nothing changed in the service > 5 times.** The alert is signaling a known steady-state condition; change the threshold or convert to TICKET.
- **No owner.** Orphan alerts get muted, not tuned. Delete or re-own.
- **No runbook.** Was a PAGE when no one thought about it; demote to TICKET until a runbook is written.

### 7.2 Cadence

Quarterly is the floor. Monthly is better for busy teams. The pruning log goes in `.observe-ready/alerts.md#pruning-log`.

### 7.3 The flappy-alert rule

If an alert fires and clears more than once per hour on average, it is flapping. Flapping alerts page the on-call repeatedly for the same condition; the on-call mutes them. Fix with:

- Longer hysteresis (condition must hold longer before firing).
- A short-window floor on the alert expression.
- Correlation / deduplication at the alert router.

---

## Part 8. Deadman-switch alerts

Alerts on the *absence* of a signal. Easy to forget; critical when they matter.

| Target | Example |
|---|---|
| Scheduled job ran on schedule | `absent_over_time(scheduled_job_last_run_timestamp[<interval + grace>])` |
| Worker is actively processing | `worker_last_processed_timestamp` not advanced in N seconds when queue is non-empty |
| Synthetic check produced a result | Checkly-style: alert on "no check result in N minutes" |
| Data pipeline advanced its watermark | Watermark has not changed in N seconds past expected cadence |
| The alert backend itself is receiving data | Meta-deadman: a heartbeat from the collector. If the collector is down, other deadman alerts cannot fire. |

Checkly 2024 is the cautionary tale: a synthetic-check platform had no deadman on its own check results, so a 5-hour silence looked fine ([Checkly](https://www.checklyhq.com/blog/post-mortem-outage-browser-check-results-alerting)).

---

## Part 9. Correlation and suppression

An incident that fires 80 alerts is worse than one that fires 3 because the on-call spends 20 minutes triaging the notifications before starting the actual work. GitHub 2018.

### 9.1 Patterns

- **Dependency suppression.** If service A is down, suppress alerts from B, C, D that depend on A. PagerDuty's Event Intelligence, incident.io's grouping, and most modern alert routers support this.
- **Deduplication by signature.** Alerts with the same `service` + `alert_name` in a short window are grouped into one notification.
- **Clustering by trace_id.** When an error spike is all one trace, collapse the alerts.

### 9.2 Gotcha

Over-aggressive correlation hides distinct problems. If two separate incidents happen concurrently, their alerts should not merge. Tune correlation rules carefully; a correlation audit is part of the quarterly pruning pass.

---

## Part 10. Example alert catalog

For a login journey with SLO 99.9%:

```markdown
## login-availability SLO alerts

### login-slo-fast (PAGE, 14.4x burn)
- Condition: both 1h and 5m burn rate > 14.4x.
- Severity: PAGE.
- Routing: @api-team PagerDuty, SMS primary, Slack secondary.
- Runbook: https://runbooks.example.com/login-slo-burn
- Dashboard: https://grafana.example.com/d/login-primary
- Last-reviewed: 2026-04-15
- Owner: @api-team

### login-slo-medium (PAGE, 6x burn)
- Condition: both 6h and 30m burn rate > 6x.
- Severity: PAGE.
- Routing: same as above.
- Runbook, dashboard, owner: same.

### login-slo-slow (TICKET, 3x burn)
- Condition: both 24h and 2h burn rate > 3x.
- Severity: TICKET.
- Routing: #api-tickets Slack channel, linear-board auto-ticket.
- Runbook: https://runbooks.example.com/login-slo-slow-burn
- Owner: @api-team

### login-slo-drift (TICKET, 1x burn)
- Condition: both 72h and 6h burn rate > 1x.
- Severity: TICKET.
- Routing: same as slow.
- Runbook: same.
- Owner: same.
```

Every PAGE has a runbook. Every alert has an owner. Every alert has a last-reviewed date. No single-window burn.

---

## Part 11. Checklist for Step 5 completion

- [ ] Every SLO has the four-tier burn-rate matrix configured (fast, medium, slow, drift).
- [ ] No single-window burn-rate alerts exist.
- [ ] No cause-based alert (CPU %, memory %, disk %) is wired as PAGE unless it is a qualifying predictive alert with named lead time.
- [ ] Every PAGE has a runbook URL in its payload.
- [ ] Every alert has an owner and a last-reviewed date.
- [ ] Alert routing path is independent of the service being paged (SMS / voice, not only Slack).
- [ ] Deadman-switch alerts exist for scheduled jobs, workers, synthetic checks, and data pipelines.
- [ ] Correlation and suppression are tuned enough to avoid 80-alert incidents but not so aggressive that distinct incidents merge.
- [ ] Alert pruning cadence is declared and on the calendar (quarterly floor).

When every box is checked, Step 5 is complete. Move to Step 6 (dashboard design).
