# Launch telemetry (Step 10)

launch-ready owns only launch-campaign telemetry. Product telemetry (feature adoption, retention, in-app funnels, A/B tests, session replay) is `production-ready`'s `references/analytics-and-telemetry.md`. The line is bright: launch-ready asks "where did the visitor come from and did they sign up"; product telemetry asks "did the signed-up user adopt and retain."

This reference covers the UTM taxonomy, the analytics tool choice, the five-event conversion waterfall, the referrer dashboard, traffic-spike readiness, and the status-page requirement.

## 1. UTM taxonomy

Every shared link on every launch channel carries UTM parameters. A launch without UTMs is a silent launch: the founder cannot attribute the fourteen signups to the five venues posted to.

### The five UTM parameters

- `utm_source`: the specific venue. Examples: `producthunt`, `hackernews`, `reddit_sideproject`, `reddit_saas`, `twitter`, `linkedin`, `dev_to`, `indiehackers`, `newsletter_tldr`, `podcast_indiehackers`, `email_launch`, `email_welcome`, `press_pragmaticengineer`.
- `utm_medium`: the channel type. Fixed vocabulary: `social`, `referral`, `email`, `press`, `organic`.
- `utm_campaign`: the named campaign. Format: `launch_YYYY_MM` (e.g., `launch_2026_04`) or `relaunch_2026_q2_pivot` for distinct campaigns.
- `utm_content`: the specific post or variant. Examples: `og_card_v1`, `thread_tweet_3`, `maker_comment`, `hero_cta`, `footer_cta`.
- `utm_term`: optional. Only if testing headline variants ("variant_a", "variant_b").

### Example URLs

Product Hunt post link:

```
https://runbook.dev/?utm_source=producthunt&utm_medium=social&utm_campaign=launch_2026_04&utm_content=ph_post
```

Show HN link (submitted URL):

```
https://runbook.dev/?utm_source=hackernews&utm_medium=social&utm_campaign=launch_2026_04&utm_content=show_hn
```

Launch-day email:

```
https://runbook.dev/?utm_source=email_launch&utm_medium=email&utm_campaign=launch_2026_04&utm_content=launch_day_drop
```

X thread tweet 6 (the CTA tweet):

```
https://runbook.dev/?utm_source=twitter&utm_medium=social&utm_campaign=launch_2026_04&utm_content=thread_tweet_6
```

### Discipline rules

- **Lowercase.** UTM values are case-sensitive in most analytics tools; lowercase-everywhere prevents `Twitter` and `twitter` splitting the report.
- **Underscores, not hyphens.** `email_launch` not `email-launch`. Consistency matters.
- **Stable vocabulary.** Use the same `utm_source` values across campaigns. `producthunt` stays `producthunt` forever, not `product_hunt` this time and `ph` next.
- **Registry.** Maintain `.launch-ready/utm-registry.md` with the full list of values used. New values added during a launch are recorded; this prevents collisions with future campaigns.

### Link-shortener compatibility

Short links (bit.ly, t.co, custom domains) that preserve UTMs redirect with the parameters intact. Shorteners that strip parameters kill attribution; test the shortener before launch day.

Some channels (X / Twitter) auto-wrap links in t.co redirects that preserve parameters; this is fine. Some Reddit / LinkedIn integrations may modify URLs; test posting a test URL through each channel's link-handling and confirm UTMs arrive at the analytics endpoint.

## 2. Analytics tool

Choose one. Do not run three analytics tools in parallel; attribution fragments.

| Tool | Best for | Free tier | Privacy | Launch-day view |
|---|---|---|---|---|
| **Plausible** | Lightweight, EU-based, privacy-first | Paid; ~$9/mo | Cookieless | Real-time referrers; UTM breakdown |
| **Fathom** | Lightweight, EU-friendly | Paid; ~$15/mo | Cookieless | Real-time; UTM breakdown |
| **Umami** | Self-hosted lightweight | Free (self-host) | Cookieless | Live visits, UTM breakdown |
| **PostHog** | Product analytics + launch | Generous free tier | Cookies optional | Funnel + real-time |
| **GA4** | Google Analytics 4 | Free | Cookies; consent-gated | Real-time; UTM breakdown; steeper learning curve |

### Selecting

- **Launch only, product analytics via other tool:** Plausible, Fathom, or Umami.
- **Launch plus ongoing product telemetry:** PostHog.
- **GA4 as the enterprise default:** acceptable but the real-time view is less intuitive than Plausible's.

Record the choice in `stack-ready/DECISION.md` or `.launch-ready/STATE.md`.

## 3. The five-event conversion waterfall

Define five events from landing to activation. Each is instrumented in the chosen analytics tool. Tested end-to-end in staging before launch.

### Event 1: landing_view

Fires on page load of the landing page. Properties: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `referrer`, `user_agent_device`, `viewport_size`.

### Event 2: cta_click

Fires when the primary CTA is clicked. Properties: same UTM properties plus `cta_location` (hero, middle, footer).

### Event 3: signup_submit

Fires when the signup or waitlist form is submitted. Properties: same UTM properties.

### Event 4: email_confirmed

Fires on confirmation click from the double-opt-in email. Properties: same UTM properties (passed through the confirmation link).

### Event 5: activation

Fires on the first meaningful action. For a SaaS, this is typically the first login and first meaningful use (first API call, first config saved, first document created). For a waitlist-only launch, activation is the first engagement email open or click.

### The waterfall report

At the end of launch day, the report shows:

| Stage | Count | Drop-off from prior |
|---|---|---|
| landing_view | 4,200 | - |
| cta_click | 1,340 | 68% |
| signup_submit | 520 | 61% |
| email_confirmed | 410 | 21% |
| activation | 190 | 54% |

Attribution by `utm_source`:

| Source | landing_view | signup_submit | conversion rate |
|---|---|---|---|
| producthunt | 1,840 | 290 | 15.8% |
| hackernews | 1,210 | 150 | 12.4% |
| twitter | 620 | 35 | 5.6% |
| linkedin | 310 | 28 | 9.0% |
| email_launch | 220 | 17 | 7.7% |

The table answers "which channel drove which signups" and which converted best per visitor. It is the D+1 retrospective's central artifact.

## 4. The referrer dashboard

A live view during the launch. Refreshed every 30 to 60 minutes during the first 12 hours.

Required contents:

- **Top 10 referrers in the last hour.** Which channels are driving live traffic right now.
- **UTM source breakdown (cumulative since launch).** How the day is stacking.
- **Conversion rate by source.** Not just volume; quality.
- **Waitlist signups by source.** Specific attribution.
- **Live event feed.** The last 20 conversion events in chronological order.

Tool options:

- **Plausible's real-time view.** Shows last 30 minutes of visits with referrer.
- **PostHog's live events feed.** Shows event stream in real time.
- **A custom dashboard.** Metabase / Grafana over the raw event data if available.

Hosted somewhere the founder can refresh without being on a production dashboard. A bookmarked URL on a phone is fine.

## 5. Traffic-spike readiness

Launch-day traffic spikes are measured in multiples, not percentages. A landing page that handles 50 requests per minute on a normal day may see 5,000 per minute in the first hour of a PH / HN double-launch.

### Static landing pages

Static pages hosted on Vercel, Netlify, Cloudflare Pages, or a CDN-fronted S3 bucket survive PH / HN front-page traffic without tuning. This is the default recommendation.

### Server-rendered landing pages

If the landing page is server-rendered (Next.js SSR, Rails, Django), the spike hits the server. Mitigations:

- **CDN caching for the landing page.** Cache-Control: `public, max-age=300, s-maxage=3600`. The server sees a fraction of actual traffic.
- **Static export of the landing page.** Many frameworks support static-ish export of marketing pages even when the app itself is dynamic. Next.js `generateStaticParams` or similar.
- **Tested surge capacity.** Run a load test simulating 10x expected peak (tools: k6, Artillery, Gatling). Fix any bottleneck that fails.
- **Waitlist form submission.** This is the one dynamic path; it cannot be static. Ensure the form endpoint has connection-pool headroom or a queue in front.

### The app itself

If the app (behind the landing page, post-signup) also sees the traffic spike, that is `observe-ready`'s responsibility. launch-ready reads `.observe-ready/SLOs.md` and surfaces any at-risk SLO in the launch runbook. If observe-ready is not installed, launch-ready notes the absence and recommends a manual health check every 30 minutes on launch day.

### Database

Waitlist signups hitting Postgres. The failure shape (from published launch postmortems): the database hits the connection-pool cap around 500 req/min; new signups are accepted by the HTTP layer but never committed. This is the worst possible failure: visitors think they signed up; they did not.

Mitigations:

- **Connection pooling.** PgBouncer or similar in transaction-pooling mode in front of Postgres.
- **Async write.** The HTTP handler enqueues the signup to a job queue; the queue processes at its own rate. The form shows "you are on the list" on enqueue success.
- **Per-IP rate limit.** Prevents a single misbehaving actor from drinking the connection pool.

## 6. Status page

Linked from the landing page footer. Hosted out-of-band per observe-ready's Step 10 independence rule.

### Why

During a launch-day traffic spike, if the app goes down, customers expect an acknowledgment. A blank page or a Cloudflare error page is a worst-case experience. A working status page is a trust-preserving fallback.

### Tools

- **Instatus.** SaaS. Free tier for basic status page.
- **StatusGator.** Aggregates external services' statuses.
- **Atlassian Statuspage.** Enterprise; typically overkill for launch.
- **Self-hosted Upptime.** Free GitHub Actions-based.

### Out-of-band hosting

The status page runs on infrastructure distinct from the app. If the app runs on Fly.io, the status page runs on Vercel, or vice versa. If the app's DNS goes down, the status page must be reachable (different DNS provider or a cached zone).

observe-ready's INDEPENDENCE.md names the status-page row as one of the six dependency-test rows. launch-ready reads that file; if the status page is flagged as dependent, the launch runbook includes an action to move it out-of-band before launch day.

### Pre-launch status posts

Post a scheduled "We are launching today" message to the status page on D-0. Not an alert; an acknowledgment. Reassures visitors who see the status page via a 500.

## 7. Post-launch: closing the campaign

At the transition boundary (Step 12), the launch campaign closes. Operations:

- Stop generating new `utm_campaign=launch_YYYY_MM` links. New shared links get new UTMs.
- Keep the existing `launch_YYYY_MM` attribution historical. Do not delete.
- Export the launch-day report to `.launch-ready/launches/YYYY-MM-slug.md`.
- Hand off ongoing analytics to `production-ready`'s in-app telemetry.

## 8. What launch-ready does NOT track

- **Feature adoption.** "Did the user use the new dashboard feature three times in week one." production-ready territory.
- **Retention cohorts.** "Did users who signed up on launch day still log in at week 4." production-ready territory.
- **Pricing A/B tests.** "Does the $19 tier or the $29 tier convert better." production-ready territory.
- **Session replay of authenticated users.** production-ready territory.
- **Product-qualified-lead scoring.** production-ready territory.

These are real analytics concerns; they are not launch-campaign concerns. Keep the line bright.

## 9. Research pass references

For Plausible / Fathom / Umami / PostHog / GA4 comparisons, vendor documentation and Analytics Mania / Simo Ahava's running coverage. For traffic-spike case studies (SadServers, iDiallo, Gatling), direct postmortem links. Citations in `RESEARCH-2026-04.md` sections 13 and 14.
