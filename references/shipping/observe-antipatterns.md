# Observe-ready antipatterns

Named failure modes observe-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand at every SLO definition, every alert wiring, every runbook authorship, and every Mode C audit of an existing observability surface. Complements `references/slo-design.md`, `references/alert-patterns.md`, `references/incident-response.md`, and `references/post-mortem.md`.

## Core principle (recap)

> Every dashboard charts a metric tied to an SLO. Every alert pages someone with a defined response. Every runbook has been executed, not just authored.

The patterns below are violations of this principle.

## Pattern catalog

### Paper SLOs (Critical)

**Shape.** A list of "SLOs" with target numbers (99.9% uptime, 200ms p95 latency, 5% error rate). No error-budget policy. No defined consequence for budget exhaustion. Teams ship features even when budgets are deeply negative.

**Grep test.** Every SLO carries: target, measurement window, error-budget calculation, and an explicit policy ("when error budget is exhausted, feature work pauses until budget returns to >= 50%"). SLOs missing the policy fail.

**Guard.** `references/slo-design.md` mandates the error-budget policy as a structural part of every SLO. The "the error budget actually stops the train" discipline.

### Blind dashboards (Critical)

**Shape.** A pretty dashboard with twelve charts. None of the charts is bound to an SLO. Charts exist because someone added them; nobody knows which line crossing which threshold means "wake someone up."

**Grep test.** Every panel on every dashboard either: (a) is tied to a named SLO, or (b) is a leading indicator that flows into an alert, or (c) is explicitly labeled "informational, not gating." Panels with none of those fail.

**Guard.** `references/dashboards.md` requires panel-to-signal mapping. Mode C audits flag orphan panels.

### Paper runbooks (Critical)

**Shape.** A markdown file named "runbook.md" with twelve incident-response procedures. Nobody has run any of them. The team's first incident reveals step 3 references a tool nobody installed and step 6 references a person who left.

**Grep test.** Every runbook entry has been executed at least once (in a synthetic incident, GameDay, or real outage) within the last 90 days. Last-run timestamps documented per runbook.

**Guard.** `references/incident-response.md` mandates a quarterly runbook-rehearsal cadence. The dogfood discipline: run one synthetic outage per quarter.

### Alert fatigue (High)

**Shape.** Every signal pages someone. The on-call engineer gets 47 pages a day; ignores most of them; misses the real one. Alert quality dropping below 70% true-positive rate.

**Grep test.** Page-severity alert count <= 5 unique types. Each page has a defined response within 15 minutes. Pages firing more than once per week without a runbook update fail.

**Guard.** `references/alert-patterns.md` carries severity tiers (page / high / medium / low / digest). Step 4 of the workflow forces a four-tier triage.

### Vanity metrics (Medium)

**Shape.** Dashboards tracking "engagement with the dashboard" - count of dashboard views, average time on dashboard, "% of team checked the dashboard this week." None of it correlates to user-facing reliability.

**Grep test.** Every dashboard panel correlates to a user-impact signal: latency, error rate, throughput, user-facing flow completion, business KPI. Panels measuring engagement with the observability surface itself fail.

**Guard.** `references/metrics-taxonomy.md` defines the user-impact-signal taxonomy.

### Error budget without policy (Critical)

**Shape.** An error budget is calculated. Burn-rate is monitored. When the budget is exhausted, nothing happens. Feature work continues unchanged.

**Grep test.** The team's product roadmap document (`.roadmap-ready/ROADMAP.md` or equivalent) names "feature freeze" or "reliability work" as the response to budget exhaustion. Roadmaps that don't name the consequence fail.

**Guard.** `references/slo-design.md` mandates the error-budget policy as a roadmap-affecting decision, not a dashboard widget.

### Distributed tracing without sampling strategy (High)

**Shape.** OpenTelemetry traces enabled at 100% sample rate. Trace storage costs spike. Three months in, the team disables tracing entirely because the bill became unmanageable.

**Grep test.** Tracing config declares: head sampling rate (low for normal traffic), tail-based-sampling for error traces, retention period. Configs with 100% head sampling and no tail strategy fail.

**Guard.** `references/tracing.md` mandates the sampling strategy section.

### Structured logging without redaction (Critical)

**Shape.** Logs include user PII (emails, names, IP addresses) and secrets (API keys, tokens, passwords) shipped to a third-party log aggregator (Axiom, Datadog, Honeycomb). The aggregator becomes a PII data store; GDPR / SOC 2 / HIPAA blast radius.

**Grep test.** The structured-logging helper has a redaction list (`refresh_token`, `access_token`, `password`, `email`, `ssn`, etc.). The lint catches log-emission code that includes these field names without going through the redacter.

**Guard.** `references/logging-patterns.md` carries the redaction discipline. Cited: harden-ready FINDINGS.md F-01 (the Pulse worked example).

### On-call rotation of one (High)

**Shape.** A "rotation" with one person on it. They're on-call 24/7. They burn out, leave, and the team is uncovered.

**Grep test.** On-call rotation has at least 2 people (primary + secondary). Vacations and sick days are covered by named back-up. Rotation that lists "Devon: every week" fails.

**Guard.** `references/incident-response.md` mandates a 2-person minimum at v1.0 and a 4-person rotation as the team grows.

### Synthetic monitoring as the only observability (Medium)

**Shape.** External uptime checks (Pingdom, UptimeRobot) ping the homepage every minute. The team sees green. Real users hit a multi-step flow that breaks; the synthetic doesn't catch it.

**Grep test.** Real-user observability exists alongside synthetic: client-side error tracking (Sentry), real-user latency (RUM), or business KPI tracking. Synthetic-only stacks fail.

**Guard.** `references/dashboards.md` mandates real-user signals on Tier 2+ services.

### Post-mortem as blame ritual (Medium)

**Shape.** Post-mortems that name a person ("Devon broke prod"), close with a remediation that depends on the named person not making mistakes, and produce no class-of-incident learning.

**Grep test.** Post-mortems answer: what class of incident does this belong to; what mechanism would prevent the class; what's tracked as the follow-up. Person-blame post-mortems fail.

**Guard.** `references/post-mortem.md` is blameless-by-construction. The class-not-instance discipline applies.

### Alert that pages without a response (Critical)

**Shape.** A pager alert fires. The on-call engineer wakes up. There's no documented response. They poke at the dashboard, can't tell what's wrong, eventually go back to sleep. The next morning they discover something was actually broken.

**Grep test.** Every page-severity alert links to a runbook entry that names: how to confirm the alert is real, what to do first, when to escalate. Alerts without runbook links fail.

**Guard.** Step 4 (alert routing) mandates a runbook link per page.

### SLO with no measurement (Critical)

**Shape.** "Our SLO is 99.9% uptime." No measurement is in place. Nothing is computing the actual figure. The number is aspirational.

**Grep test.** Every named SLO has a query that computes it (Axiom APL, Datadog query, Honeycomb panel, etc.) and a dashboard showing the rolling-window measurement. SLOs without measurement fail.

**Guard.** Step 1 of the workflow defines the measurement query alongside the target.

### Logging at INFO too verbosely (Low)

**Shape.** Every request logs 4-5 lines: enter handler, parse params, call DB, return result. Log volume blows past the aggregator's free tier; cost surprises follow.

**Grep test.** Per-request log line count median <= 2 (one entry, one exit). Higher-volume routes documented and budgeted.

**Guard.** `references/logging-patterns.md` carries log-level discipline.

### Dashboards reviewed never (Medium)

**Shape.** A dashboard was authored 6 months ago. It's still up. Three of its panels reference metrics that no longer exist; they've shown "no data" for 90 days.

**Grep test.** Every dashboard has a "last reviewed" date. Dashboards not reviewed within 90 days are flagged.

**Guard.** Weekly pilot review (or monthly review post-pilot) walks every dashboard.

## Severity ladder

- **Critical**: blocks the observability tier. Must be fixed before declaring the observability surface ready.
- **High**: blocks the tier gate. Must be fixed before next milestone.
- **Medium**: flagged in the audit; fix recommended this cycle.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": canonical have-nots list.
- `references/slo-design.md`: SLO targets + error-budget policy.
- `references/alert-patterns.md`: severity tiers and routing.
- `references/incident-response.md`: rotation + runbook rehearsal.
- `references/post-mortem.md`: blameless, class-not-instance.
- `references/dashboards.md`: panel-to-signal discipline.
- `references/metrics-taxonomy.md`: user-impact signal types.
- `references/logging-patterns.md`: structured + redaction.
- `references/tracing.md`: sampling strategy.
