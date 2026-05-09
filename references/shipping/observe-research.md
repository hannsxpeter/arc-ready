# Observe-ready mode detection and research protocol

Loaded at Step 0 of every observe-ready session. This file is the entry point.

Five modes drive the rest of the session. Pick one; every step after this adjusts to the mode.

## Mode A: Greenfield

**Trigger:** the app has shipped (or is about to), and there is no SLO, no structured logging discipline, no real dashboard. The dashboards that exist are the vendor's default for "add monitoring," and the alerts that exist are thresholds on CPU and memory.

**What to produce at Step 0:**

- List the services the app is running (from `.deploy-ready/TOPOLOGY.md` if present).
- List the user journeys the app serves (from `.production-ready/STATE.md` if present, or name them from the running surface).
- Confirm the observability tool family in use or being chosen. If `.stack-ready/DECISION.md` names one, read it.
- Declare the starting tier: Tier 0 (no observability) or Tier 1 partial (some logging exists).

**Next step:** proceed to Step 1 (service inventory) and Step 2 (logging baseline). Do not jump to SLOs until the signal plumbing exists to measure against.

## Mode B: Instrumented-but-unbound

**Trigger:** logging, metrics, and maybe traces exist. Dashboards exist, often a lot of them. No SLOs. No error-budget policy. The pager goes off. Nobody is sure which alerts to trust.

**What to produce at Step 0:**

- Inventory the existing observability artifacts: dashboards (count, ownership, last-reviewed date per artifact if derivable), alerts (count, firing frequency in the last 30 days, dismissal rate), SLOs (likely none).
- Mark the dashboards and alerts without ownership or a review date as prune candidates up front. They will either gain metadata during this pass or get pruned.
- Identify the top three user journeys that matter most. Those are where the first SLOs go; the rest can wait for the next pass.

**Next step:** Step 1 inventory, Step 3 metric taxonomy cleanup, Step 4 SLO binding on the top three journeys. Step 5 alert rewrite follows once SLOs exist.

This mode is the most common. Most teams with a pager have Mode B observability.

## Mode C: Mature-with-sprawl

**Trigger:** SLOs exist. Dashboards exist in numbers that nobody can remember. Alerts exist in numbers that page more than they actionably inform. The ask is "make this surface usable again." Dashboard-sprawl (400 Grafana panels at ASAPP, 2700 at Flexport pre-cutdown) is the shape.

**What to produce at Step 0:**

- Audit table: every dashboard with owner, last-viewed-during-incident, linked-to-SLO status.
- Audit table: every alert with firing count, actionable count, dismissal count over the last quarter.
- Audit table: every SLO with error-budget-policy status (paper SLO flag if no policy).

**Next step:** Mode C makes Step 11 prune cadence, Step 6 dashboard discipline, and Step 5 alert pruning the primary work. The incentive structure flips: fewer, better artifacts beat more, equal-quality artifacts.

## Mode D: Incident-reactive

**Trigger:** an incident just happened and exposed a specific observability gap. The missing alert, the runbook that was stale, the dashboard that was hosted on the dead cluster, the trace that was sampled out. The ask is narrower than Mode B; focus is on the gap the post-mortem exposed.

**What to produce at Step 0:**

- Read `.deploy-ready/incidents/NNN-slug.md` (and the team's post-mortem if separate) for the incident summary and the named observability gap.
- Identify the step(s) in the workflow that the gap belongs to. If the gap is "we had no alert for queue depth going over threshold," that is Step 5 work scoped to the one alert. If the gap is "the runbook 404ed," that is Step 9 scoped to that runbook.

**Next step:** execute the narrow fix. Then, as a follow-on, walk the broader step to see if the same gap class exists elsewhere. An incident-reactive fix that closes one gap and leaves ten open is a partial close.

## Mode E: Cost-driven

**Trigger:** the bill arrived. Datadog custom-metric cost, New Relic CCU overage, Splunk-or-Elastic log ingest, Honeycomb event volume. The ask is "cut 40% without losing signal."

**What to produce at Step 0:**

- Inventory by cost line: metrics ingested, logs ingested, traces ingested, dashboards / seats billed.
- Identify the top five cost contributors. Typical culprits, per the research: high-cardinality metric tags, verbose `DEBUG` logs shipped at `INFO`, head-sampled traces ingesting the 99% boring tail, duplicated instrumentation (an OTel agent plus a vendor agent both shipping).
- Map each cost contributor to the signal it produces. "Is this line item answering a question anyone asks during an incident?" The Chronosphere framing: ~70% of observability spend goes to logs never queried.

**Next step:** Mode E makes Step 2 logging sampling, Step 3 cardinality discipline, Step 7 trace sampling, and the retention alignment in each step the primary work. Mode E is compatible with the other modes; a Mode B team often discovers they are also in Mode E once the first bill after scaling comes in.

## The destructive-retention-change alert

Retention changes are lossy in one direction. Dropping log retention from 90 days to 14 days loses the ability to answer questions about the last quarter's incidents; re-enabling it does not bring the data back. If the agent is about to propose a retention cut, call it out explicitly and confirm with the user that the lost data window is acceptable. The guardrail mirrors deploy-ready's destructive-command gate: some operations have no undo.

## The paper-SLO detection procedure

If the request resembles "define an SLO for X":

1. Ask (or infer): what is the SLI query?
2. Ask (or infer): what is the target number and window?
3. Ask (or infer): what error-budget policy governs the number? Who is the stakeholder? What is the consequence of burn?
4. If any of 1-3 is missing at the end of the session, the SLO is a paper SLO. The skill refuses to write it to `.observe-ready/SLOs.md` without the policy fields filled in. It can write a draft entry with explicit `POLICY: TBD` markers so that the gap is visible in STATE.md, but it does not treat an SLO-without-policy as shipped.

## The observability-surface reachability question

Before declaring any tier complete, ask: **if the service being observed is down, is the observability for it reachable?**

The answers vary by artifact:

- Dashboards: if hosted on Grafana in the same cluster, no. If hosted on Grafana Cloud or a separate cluster, yes.
- Runbooks: if on Notion/Confluence with SSO via the same IdP the app uses, no. If mirrored to a read-only static site or printed card, yes.
- Alert routing: if PagerDuty posts only to Slack and Slack is degraded, partially. If PagerDuty pages via SMS or voice directly, yes.
- Status page: if hosted on the same cloud region as the app, no (or at least, the status page may go down with the region). If hosted on a distinct provider (Statuspage.io, Instatus, etc.), yes.

Mark each artifact's reachability as `reachable` or `dependent` in `.observe-ready/INDEPENDENCE.md`. Dependent artifacts get a remediation or an explicit exception. See Step 10 for the full six-row test.

## What "done" looks like per mode

| Mode | Minimum "done" | Typical tier end-state |
|---|---|---|
| A Greenfield | Tier 1 + one SLO per top user journey | Tier 2 in one session is realistic |
| B Instrumented-but-unbound | Tier 2 across top-3 journeys | Tier 3 over 2-3 sessions |
| C Mature-with-sprawl | Tier 3 with pruned catalog (typically 50-70% reduction) | Tier 4 after a full cycle |
| D Incident-reactive | Narrow fix closed; broader class audited for similar gaps | Returns to baseline tier the team was at |
| E Cost-driven | 30-50% volume reduction with unchanged signal coverage | Typically Tier 3 re-verified after the cuts |

Mode E often surfaces Mode C symptoms. A team whose bill is detonating usually has dashboard sprawl and alert fatigue as contributing factors.

## What to read next

- `logging-patterns.md` before Step 2.
- `metrics-taxonomy.md` before Step 1 and Step 3.
- `slo-design.md` before Step 4.
- `alert-patterns.md` before Step 5.
- `dashboards.md` before Step 6.
- `tracing.md` before Step 7.
- `error-tracking.md` before Step 8.
- `incident-response.md` before Step 9 and Step 11.
- `post-mortem.md` before Step 11.
- `vendor-landscape.md` on demand, especially when a vendor-specific detail (cardinality pricing, retention tier, propagation quirk) appears in the scope.
- `RESEARCH-2026-04.md` for citations and the named-term derivations.
