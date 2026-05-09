# Analytics & Telemetry

This file is about two adjacent topics that are easy to confuse:

1. **Analytics inside the dashboard** — the charts, KPIs, and reports the dashboard *shows* to its users about *their* business.
2. **Telemetry on the dashboard itself** — the events the dashboard *emits* about how it's *being used*, plus the audit log of user actions.

Both matter. Both should be designed deliberately, not bolted on at the end.

## Part 1 — Analytics in the dashboard

### What "analytics" means here

Most dashboards display some form of analytics — counts, sums, trends, comparisons, distributions of the user's data. Doing this well means combining the chart-selection rules from `data-visualization.md` with a few additional principles specific to analytics surfaces.

### The analytics page structure

A typical analytics page in a dashboard:

```
┌─────────────────────────────────────────────────────────────┐
│ Analytics                                       [Export ▾]  │
│ March 1 – March 31, 2026                                    │
├─────────────────────────────────────────────────────────────┤
│ [Date range ▾]  [Compare to ▾]  [Segment ▾]  [Reset]       │  ← filter bar
├─────────────────────────────────────────────────────────────┤
│  KPI 1     │  KPI 2     │  KPI 3     │  KPI 4              │
│  vs prev   │  vs prev   │  vs prev   │  vs prev            │
├─────────────────────────────────────────────────────────────┤
│  Main trend chart (the headline metric over time)           │
│                                                              │
├──────────────────────────────┬──────────────────────────────┤
│  Breakdown chart 1           │  Breakdown chart 2           │
│  (e.g., by source)           │  (e.g., by plan tier)        │
├──────────────────────────────┴──────────────────────────────┤
│  Detail table                                                │
│  (the underlying rows)                                       │
└─────────────────────────────────────────────────────────────┘
```

### Time range and comparison

Almost every analytics page needs a date range picker and a comparison.

- **Date range picker** with quick presets (Today, Yesterday, Last 7 days, Last 30 days, This month, Last month, This quarter, Last quarter, Year to date, Custom). Custom opens a calendar.
- **Comparison** lets the user compare the current range to a previous period (Previous period, Previous year). When comparison is on, every chart shows the comparison series too — typically as a faint dotted line below the main one.
- **Default range** — Last 30 days is a safe default. The user adjusts.
- **Persist the range in the URL** so reloading and sharing work.
- **Show the dates explicitly** somewhere — "March 1 – March 31, 2026" — so the user is never confused about what "last month" means.

### Drill-down

Charts should be drillable. Click a bar → see the records that contributed to it. Click a slice → filter the table below to that slice. The user explores by clicking, not by re-running queries.

The pattern:
- Hover a chart element → tooltip with details
- Click → either filter the rest of the page to that subset, or navigate to a detail page
- Make the click affordance obvious (cursor pointer, hover state)

### Segments and dimensions

Power-user analytics let the user pivot by different dimensions:

- "Show me revenue by plan tier"
- "...by acquisition channel"
- "...by country"

This is a dimension picker. Every metric × dimension combination becomes a chart. Don't precompute them all — let the user select and the chart updates.

For dashboards built on top of an OLAP store (Cube, Druid, ClickHouse, Snowflake, BigQuery), this is straightforward — query at request time. For dashboards on operational stores (Postgres, MySQL), you'll need indices or materialized views to keep the queries fast.

### Funnels and cohorts

Two patterns common in product analytics:

- **Funnel chart** — sequential steps with drop-off between each. "Visitors → Signups → Activated → Paid." Use a horizontal funnel viz with percentages.
- **Cohort retention** — a triangular table showing what % of users from each signup cohort are still active in week 1, 2, 3, etc. Color-coded cells.

These are advanced visualizations. Don't build them unless the user asked. They're hard to do right and easy to mislead with.

### Exports for analytics

Analytics pages need export. The export should reflect:
- The current date range
- The current segments / filters
- The current comparison
- All the underlying rows, not just the chart data

CSV is the default. Some dashboards offer "export this chart as PNG/SVG" — useful for slide decks. Both are easy with the right chart library.

## Part 2 — Telemetry on the dashboard itself

This is the part most dashboards skip until it's too late. Telemetry is how you know the dashboard is being used, where users get stuck, and what's slow. Build it from the start. Retrofitting it is painful.

### Two categories of telemetry

1. **Usage events** — what the user did (clicked a button, viewed a page, ran a report). For product analytics: who's using what, where they drop off, what the most-used features are.
2. **Performance metrics** — how fast the dashboard is for real users. For monitoring: is the app slow? Where? For whom?

These typically go to different tools and are easy to confuse. Send both, label them clearly.

### Usage event tracking

Pick a tracker:
- **Self-hosted / open source**: PostHog, Plausible, Umami, Matomo
- **SaaS**: PostHog Cloud, Mixpanel, Amplitude, Heap, Segment (which routes to all the others)
- **Inside the data warehouse**: send events directly to Snowflake / BigQuery / ClickHouse via Snowplow or Rudderstack

For most internal dashboards, **self-hosted PostHog** is the right answer in 2026 — open source, privacy-friendly, and now includes product analytics, session replay, feature flags, A/B testing, and surveys in a single platform. Runs anywhere.

### What to track

A small, well-defined set of events beats hundreds of half-defined events. The minimum useful set:

1. **`page_viewed`** — every page navigation. Properties: `page_path`, `page_title`, `referrer`.
2. **`action_performed`** — every meaningful user action. Properties: `action_name` (e.g., `customer.create`), `target_type`, `target_id`.
3. **`error_shown`** — every time an error is displayed to the user. Properties: `error_type`, `error_code`, `page_path`.
4. **`feature_used`** — high-value features (the things you want to track adoption of). Properties: `feature_name`.

That's enough for the first 6 months. Resist the urge to track everything; you'll drown in data and never look at it.

### Event naming

Use a structured naming convention:

```
<noun>.<verb>          → customer.create, project.delete, billing.method.update
```

Stable, consistent, easy to grep, easy to filter on. Avoid:
- Free-text event names ("Created a customer")
- Verb-only names ("Click")
- Per-page custom names ("Customers Page Click")

### What to attach to every event

A **user identifier** (their `user_id`, not PII), an **org identifier**, a **session id**, the **page path**, the **timestamp**, and the **app version**. Attach these via the tracker's "super properties" or initialization config so you don't have to remember on every call.

**Don't attach PII** unless you've decided to. Email, name, IP address — these end up in tracker storage forever. Use IDs and look them up at query time.

### Feature adoption tracking

Beyond tracking that a feature was used, measure adoption:

- What percentage of users have tried Feature X? Segment by cohort, plan, role.
- Adoption funnel: signed up > saw feature > tried feature > uses regularly.
- Track adoption over time: is Feature X being adopted or abandoned?
- Activation metrics: what's the "aha moment" for each feature?

This is the core use case for product analytics tools (PostHog, Mixpanel, Amplitude). Web analytics (page views, sessions) doesn't answer these questions.

### Session replay

Session replay (PostHog, LogRocket, FullStory) records what users did as video-like playback. It's the qualitative complement to quantitative analytics: when a funnel shows 40% drop-off, watch replays to see *why*.

Implementation: add the SDK, it records DOM mutations. Key considerations:
- Mask sensitive fields (passwords, PII) — most tools do this by default.
- Storage costs grow with traffic — set sampling rates for high-traffic dashboards.
- Link analytics events to replay sessions so you can go from "user hit error" to "watch what happened."

### A/B testing infrastructure

Test which layout, onboarding flow, or default setting performs better:

- Feature flag wraps two variants.
- Analytics tracks the conversion event per variant.
- The tool calculates statistical significance.
- Tools: PostHog (built-in flags + experiments), Statsig, GrowthBook.

### Anomaly detection and alerts

Display metrics, but also alert when they change unexpectedly:

- Threshold alerts: "notify when error rate > 5%."
- Anomaly detection: "alert when revenue drops > 2 standard deviations from the 30-day mean."
- Notify via email, Slack, or in-app notification.
- Table-stakes for operational dashboards.

### Privacy, GDPR, and consent

If the dashboard is internal to your company, you probably don't need a cookie banner — internal employees aren't end users in the GDPR sense, and the tracker is a legitimate business tool. Document the data collection in the privacy policy.

If the dashboard is customer-facing, you need consent. Use a tracker with consent mode (PostHog, Plausible — Plausible doesn't even use cookies) and respect the user's choice.

Self-hosted analytics and "no third-party cookies" trackers (Plausible, Umami) are increasingly the right answer for compliance — they avoid the consent banner entirely.

## Part 3 — Audit logs

Different from telemetry. Telemetry is for *you* (the developer) to understand usage. Audit logs are for *users* (admins, compliance officers, security teams) to understand who did what in the system.

Every dashboard handling real data needs an audit log. This is non-negotiable for any dashboard with multi-user access, RBAC, or anything regulated. See `auth-and-rbac.md` for the schema.

### What to log

**Always log:**
- Authentication events: login, logout, failed login, password change, MFA enrollment, MFA challenge
- User management: invite, role change, disable, delete
- Permission changes: role assigned, role created, permission grant
- Data mutations: create, update, delete on every entity
- Settings changes: org settings, security settings, billing changes
- Sensitive reads: who viewed what (when relevant — not every read, just the ones that matter for compliance)
- Exports: who exported what
- API key creation, rotation, revocation

**Don't log:**
- Passwords or secrets in any form (redact before storing)
- Full request/response bodies if they contain PII (log the diff, not the content)
- Routine reads (would balloon the table)

### The audit log UI

Audit logs need a viewer page in the dashboard. The pattern:

```
┌─────────────────────────────────────────────────────────────┐
│ Audit log                                      [⤓ Export]   │
│ All activity in your organization                           │
├─────────────────────────────────────────────────────────────┤
│ [Search]  [Actor ▾] [Action ▾] [Date ▾]  [Reset]           │
├─────────────────────────────────────────────────────────────┤
│ Time          Actor          Action             Target     │
│ 2 min ago     Alice          customer.create    Acme Corp  │
│ 5 min ago     Bob            project.delete     Phoenix    │
│ 12 min ago    System         user.disable       Carol      │
│ 1 hr ago      Alice          billing.update     Plan: Pro  │
│ ...                                                          │
├─────────────────────────────────────────────────────────────┤
│ Showing 1–25 of 12,847                  ‹ 1 2 3 ... ›      │
└─────────────────────────────────────────────────────────────┘
```

- Filter by actor, action type, target, date range
- Click an entry to see the full details (before/after JSON)
- Export to CSV
- Server-side pagination (audit logs grow forever)
- Restricted to admin role by default — non-admins can't see the audit log

### Append-only

The audit log is append-only. No edits, no deletes from the application. Even admins can't modify entries. For compliance, the table should be enforced at the database level — `REVOKE UPDATE, DELETE` on the audit table from the application user.

### Retention

Audit logs grow forever if you let them. Decide on a retention policy:
- 90 days for low-stakes apps
- 1 year for typical SaaS
- 7 years for regulated industries (finance, healthcare)

Move old entries to cold storage (S3 Glacier, BigQuery, Snowflake) instead of deleting if compliance requires.

## Part 4 — Performance metrics (RUM)

Real User Monitoring measures actual page load and interaction latency for actual users. Different from synthetic monitoring (which runs scripted tests).

### What to measure

The Core Web Vitals are the modern baseline:

- **LCP (Largest Contentful Paint)** — when the main content is visible. Target: < 2.5s.
- **INP (Interaction to Next Paint)** — how long the page takes to respond to user input. Target: < 200ms.
- **CLS (Cumulative Layout Shift)** — how much the page jumps around as it loads. Target: < 0.1.

For dashboards specifically, also measure:
- **Time to interactive** — when the user can actually click buttons
- **API response time per endpoint** — surfaces slow queries
- **Error rate per page** — surfaces broken features

### Tools

- **Self-hosted**: PostHog (has RUM), Sentry (has performance), GlitchTip
- **SaaS**: Sentry, Datadog RUM, New Relic Browser, LogRocket, FullStory
- **Browser-native**: `web-vitals` library + your existing analytics tracker

For most dashboards, **Sentry's combined error tracking + performance** is the right default. Add it on day one.

### Error tracking

Every unhandled exception in the dashboard goes to an error tracker — Sentry, Bugsnag, Rollbar, GlitchTip. Configure once, applies forever. Without this, errors happen silently in production and the team finds out from angry users.

The setup:
1. Install the SDK for your framework
2. Initialize with the DSN, the environment, and the release version
3. Identify the user (after login) so errors are tied to who hit them
4. Add `breadcrumbs` for important actions (mutations, navigations)
5. Set up alerting — email or Slack on new errors, or on error rate spikes

Don't ship a dashboard without error tracking. It's the cheapest insurance you'll ever buy.

## Part 5 — In-app help and changelogs

Two small but valuable surfaces that improve dashboards over time:

### Changelogs

A "What's new" link or popover that shows recent updates. The pattern from Linear, Vercel, Stripe. Encourages engagement, demonstrates the product is alive.

- Link from the user menu or a "?" icon in the header
- Each entry: date, title, short description, optional screenshot
- Auto-show a small dot when there's an unread entry

### Tooltips and guided tours

Use tooltips for *clarification*, not primary content. If you find yourself adding tooltips to explain how the dashboard works, the dashboard is unclear — fix the dashboard first.

For onboarding new users to a complex feature, a one-time guided tour (Driver.js, Shepherd.js, Intro.js) is acceptable. Keep it short — 4 steps max. Let the user dismiss at any time. Don't replay it on every login.

### Help center / docs link

A "Help" link in the user menu pointing to your docs site. If you don't have docs, write one page about the dashboard's main features. A user who's stuck and can't find help leaves.

## Don'ts

- **Don't ship without error tracking.** Errors happen silently and the team learns about them from users.
- **Don't ship without an audit log** for any multi-user dashboard.
- **Don't store PII in event tracker payloads.** Use IDs.
- **Don't track every click.** Track meaningful actions. Most clicks are noise.
- **Don't put 100 metrics on the analytics page** because you can. Pick the 5–10 that drive decisions.
- **Don't require authentication to view your changelog.** It's marketing content.
- **Don't show users the raw error tracker IDs** ("Error ID: a3f9-bc23"). Show a friendly message and log the ID server-side.
- **Don't auto-show a guided tour on every login.** Once.
- **Don't conflate audit logs with analytics events.** They serve different audiences and have different retention requirements.
- **Don't let the audit log table grow without bound.** Set a retention policy or archive to cold storage.
- **Don't trust client-reported timestamps** in the audit log. Always use server time.
- **Don't expose the full audit log to non-admins.** Scope it to the org and the user's permission level.
