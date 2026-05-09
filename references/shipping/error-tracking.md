# Error tracking

Loaded at Step 8 of the workflow. Tier 1 requirement, Tier 3 polish.

**Canonical scope:** what an error tracker (Sentry, Rollbar, Bugsnag, Honeycomb errors pane) captures, how release tagging works, grouping discipline, the complementary-not-redundant relationship with metrics, and PII scrubbing. **See also:** `logging-patterns.md` for where error events originate; `metrics-taxonomy.md` for the distinct role of error-rate metrics; `tracing.md` for the trace_id contract shared with exceptions.

The one-line framing: an error tracker tells you *what* failed, a metric tells you *how often*. Both are required. Neither replaces the other. An error-rate metric at 0.5% is a number; the error tracker is where you find out it is all `NullPointerException` in a single route that shipped this morning.

---

## Part 1. What an error tracker does that metrics cannot

A metric is a numeric aggregation. `http_errors_total{service="api",status_class="5xx"}` is an integer per time bucket. It tells you 500 errors happened in the last hour; it does not tell you they were all the same `TypeError: cannot read property 'id' of undefined` in `/checkout`.

An error tracker captures each exception as a distinct event with:

- Full stack trace.
- Breadcrumbs (a buffered history of the last N operations leading up to the error).
- Environment context (service, release, host, user segment).
- Request context (sanitized).
- Frequency and distinct-users count.
- First-seen and last-seen timestamps.
- Regression detection (was this error fixed in a prior release and returned).

This is the diagnostic lens. The error tracker sits beside the metrics backend; both are required.

---

## Part 2. Release tagging is mandatory

Every exception event tags the release identifier that was running when the exception happened. This is how you answer "did this start with v1.12.3."

### 2.1 Release identifier

The identifier comes from `.deploy-ready/STATE.md`'s current release (or the equivalent in the deploy toolchain). Typical formats:

- Semantic version: `v1.12.3`.
- Git short SHA: `a3f2b1c`.
- Combined: `v1.12.3-a3f2b1c`.
- Vercel / Netlify deployment ID.

Use a single format across services. Divergent formats ("backend uses SHA, frontend uses semver") make cross-service release correlation hard.

### 2.2 Deploy integration

The error tracker learns about the deploy via:

- Sentry's `sentry-cli releases` command run in the deploy pipeline.
- Rollbar's deploy tracking via the SDK at app startup or via CI webhook.
- Bugsnag's `bugsnag-cli release` command.
- Honeycomb's deploy markers via API or the deploy integration.

The integration records a `deploy` event on the release timeline. New error instances appearing on the new release are flagged as `regression` if the error existed on a prior release and was marked resolved.

### 2.3 The no-release failure mode

Without release tagging:

- Every error looks like "always been here" (the tracker cannot distinguish a new occurrence from a regression).
- Post-deploy error-rate spikes are hard to attribute to the specific deploy.
- The "did v1.12.3 break login" question requires metric correlation instead of a direct tracker query.

Tier 1 requires release tagging. Do not defer.

---

## Part 3. Grouping discipline

Error trackers group similar exceptions to prevent one error from becoming 10,000 events. Grouping is heuristic; it can merge distinct errors or over-split the same error.

### 3.1 Sentry default grouping

Sentry groups by exception type + top-of-stack frame. Over-splits when:

- Stack frames include an auto-generated class name that changes per request.
- Frames include the file line number and a refactor moves it.
- An ORM wraps the exception and the wrapping varies.

Sentry's [fingerprint rules](https://docs.sentry.io/product/issues/grouping-and-fingerprints/) let you override grouping per signature.

### 3.2 Rollbar default grouping

Rollbar groups aggressively by message and stack. Sometimes merges distinct root causes that happen to land on the same frame. Rollbar has [grouping tuning](https://docs.rollbar.com/docs/grouping) via fingerprint and custom rules.

### 3.3 Bugsnag default grouping

Similar to Sentry; also supports grouping overrides.

### 3.4 The quarterly grouping review

Part of the pruning pass:

- Top 20 error signatures by volume.
- For each: is the grouping correct? (Is this really one error, or three?)
- For misgrouped: write a fingerprint rule.
- For resolved-but-recurring: confirm it is a regression, not a new error that happens to share a shape.

### 3.5 Ignore rules

Some errors are known and non-actionable: user-generated 4xx, deprecated-browser stack traces, known third-party SDK warnings. Configure ignore rules so they do not pollute the top-20 signature list.

Ignore rules are pruned too: a third-party rule that was added to silence noise from a vendor you no longer use is dead weight.

---

## Part 4. Environment, service, and context

Every error event carries:

| Field | Example |
|---|---|
| `environment` | `prod`, `staging`, `preview`. Matches `.deploy-ready/TOPOLOGY.md`. |
| `service` | `api`, `worker`, `web`, matching the service inventory. |
| `release` | Release identifier as above. |
| `trace_id` | W3C Trace Context trace ID for the request that errored. |
| `user_segment` | Business dimension: `tier:free`, `region:us-east`, etc. Not the raw user ID unless explicitly consented. |
| `breadcrumbs` | The last N operations before the error: navigation events, HTTP calls, UI interactions, log lines. |

`trace_id` is the critical cross-link. The error in the tracker links to the trace in Tempo / Honeycomb / Jaeger via this ID. The tracker, the trace backend, and the log backend all use the same ID.

---

## Part 5. PII handling

Scrub before capture. Same rule as `logging-patterns.md` section 4.

### 5.1 Built-in scrubbers

- **Sentry**: [Data Scrubbing](https://docs.sentry.io/platforms/javascript/data-management/sensitive-data/) defaults to common PII patterns. Verify the config matches the app's schema; add missing fields.
- **Rollbar**: [Person tracking](https://docs.rollbar.com/docs/person-tracking) and [scrub parameters](https://docs.rollbar.com/docs/options-1#scrubheaders).
- **Bugsnag**: [filtering out sensitive data](https://docs.bugsnag.com/platforms/javascript/filtering-out-sensitive-data/).

### 5.2 Request bodies

Trackers often capture the request body as part of the context. That is the largest single PII exposure surface: signup requests carry email/name, checkout requests carry card details.

Configure body sanitization:

- Replace known PII keys (`email`, `phone`, `card_number`, `cvv`) with `[REDACTED]`.
- Truncate request bodies over N KB.
- Drop request bodies entirely on routes that handle sensitive data (payment processing, account settings).

### 5.3 The audit

Sample 100 recent events per quarter. Confirm no email addresses, phone numbers, card numbers, or authorization tokens appear in the captured context.

---

## Part 6. Errors vs. metrics: why both are required

### 6.1 The metric answers "how often"

`rate(http_errors_5xx_total[5m])` drives the SLO and the alerts. It is the number the burn-rate calculation uses.

### 6.2 The tracker answers "what"

The tracker is where the on-call opens a tab mid-incident to see "what was the error." The aggregated error count from metrics is not a substitute.

### 6.3 The two are not redundant

An AI-generated config that logs every exception as a metric and does not run an error tracker loses the per-exception detail. A config that runs a tracker and does not aggregate into metrics cannot build the SLO's error budget.

### 6.4 The boundary

- Metric: rate, count, derived SLI.
- Tracker: the specific error, its signature, its volume, its first seen, its regression status.

Use the metric for the alert; link to the tracker from the runbook for the investigation.

---

## Part 7. Error-event enrichment

Errors gain value when they carry the context the on-call needs.

### 7.1 User segment

Attach the user segment (not the user ID): `tier:free`, `plan:pro`, `org:123-hash`. This lets you answer "did this error affect enterprise tenants more than free tenants" without storing PII.

### 7.2 Feature flags

If the error happened while a feature flag was enabled, tag it. The Knight Capital-style flag issue (`deploy-ready/rollback-playbook.md`) is a deploy-mechanics concern; the observability version is "which flag was active when the error spiked." Sentry has [feature-flag evaluation tracking](https://docs.sentry.io/product/issues/issue-details/feature-flags/) for this.

### 7.3 Breadcrumbs

Most SDKs buffer the last N operations before the error: navigation events, HTTP calls, UI actions, console logs, custom events. Verify breadcrumbs include:

- Key log lines (attach a breadcrumb on every structured log event above a threshold level).
- Outbound HTTP calls (auto-captured).
- UI interactions (for frontend trackers).
- Feature-flag evaluations.

### 7.4 Linked trace and log

Deep links from the error event to the trace (via `trace_id`) and to the log query (via `trace_id` filter) make triage fast. Configure once; benefit every incident.

---

## Part 8. Frontend error tracking

For apps with a frontend, error tracking is dual: backend (what the server saw) and frontend (what the user saw).

### 8.1 Frontend specifics

- **Source-map upload** is mandatory. A frontend stack trace without source maps is unreadable. Integrate source-map upload into the deploy pipeline.
- **Session replay** (Sentry, LogRocket, FullStory) captures the user's actions leading to the error. High signal for UX bugs; review PII settings carefully.
- **Browser console errors** capture via the SDK's global error handler.
- **Unhandled promise rejections** capture separately from exceptions.

### 8.2 Volume management

Frontend errors can be noisy: browser extensions, ad blockers, user-agent-specific bugs. Aggressive ignore rules for known-noise signatures are standard practice.

---

## Part 9. Resolution workflow

An error event is captured; someone has to close the loop.

### 9.1 States

- **New.** Just appeared.
- **Triaged.** Assigned to an engineer or a team.
- **In progress.** A fix is in flight.
- **Resolved.** The fix has shipped; the error tracker is watching for regressions.
- **Regression.** The error reappeared after being marked resolved; alert the team.
- **Ignored.** Known and accepted; no fix planned.

### 9.2 The regression loop

A resolved error that reappears in a new release is a regression. The tracker flags it; the on-call rotation sees it; the engineer who fixed it investigates. This is the tracker's most distinctive value over raw metrics: it remembers what was fixed.

### 9.3 Assignment to owner

Every error signature gets an owner. If the service has a team owner in the service inventory, that team owns the signature by default. Manual reassignment is fine; an unowned signature goes in the triage queue for the on-call.

---

## Part 10. The error-tracker independence check

The error tracker is usually a SaaS vendor (Sentry Cloud, Rollbar, Bugsnag, Honeycomb). By default, it runs on infrastructure independent of the observed service.

- **Self-hosted Sentry**: if hosted on the same cluster as the app, dependent. Move to a separate cluster or use Sentry Cloud.
- **SaaS trackers**: independent by default, subject to the tracker vendor's own regional outages.
- **Network path**: if the SDK's upload path depends on the app's DNS, a DNS outage loses errors during the outage. Most SDKs buffer and retry.

---

## Part 11. Checklist for Step 8 completion

- [ ] An error tracker is installed on every service (backend and frontend if applicable).
- [ ] Release tagging is wired via the deploy pipeline; every event carries the release identifier.
- [ ] Deploy integration records deploy markers on the tracker timeline.
- [ ] Grouping has been reviewed on the top 20 signatures in the last quarter.
- [ ] PII scrubber is configured; audit shows zero PII in captured events.
- [ ] Every event carries environment, service, release, trace_id, user_segment, breadcrumbs.
- [ ] Source maps upload on every frontend deploy (if frontend).
- [ ] Each error signature has an owner or is in the triage queue.
- [ ] Regression detection is active; the team responds when a resolved error returns.
- [ ] The tracker's network path is independent of the observed service.

When every box is checked, Step 8 is complete. Move to Step 9 (runbook discipline).
