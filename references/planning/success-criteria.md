# Success criteria (Step 4)

Success metrics are where PRDs most often pretend to decide things. "Increased engagement and retention" is the default AI-slop success metric; it is not a decision. This reference covers the four-property rule, the leading-vs-lagging distinction, common traps, and how success metrics handshake with observe-ready and production-ready.

## 1. The four-property rule

Every success metric in a PRD has four properties. Missing any one, it is not a metric; it is a wish.

### 1. Measurable

A number, not an adjective. The number can be a percentage, a threshold, a count, a duration, a ratio, or a rank. It cannot be "high," "fast," "widely adopted," "effective."

**Pass:** "80% of new teams complete onboarding in the first session."
**Fail:** "High onboarding completion rate."

### 2. Time-bound

A deadline or a measurement window. "At 90 days post-launch" or "month-over-month for 3 consecutive months" or "within the first session." Open-ended metrics ("eventually," "over time") are not metrics.

**Pass:** "Median time-to-first-value is under 10 minutes, measured at 30 days post-launch."
**Fail:** "Users achieve first value quickly."

### 3. Outcome-framed

A user or business outcome, not a feature-shipped indicator. Outcomes are behaviors, states, or business effects. Feature-shipped is a checkbox, not an outcome.

**Pass:** "Weekly active teams reach 400 by day 90."
**Fail:** "The weekly report feature is launched."

Feature-shipped checkboxes can live in the Functional Requirements section (Step 5) as completion criteria; they do not belong in Success Criteria.

### 4. Source-attributed

Named instrumentation. Where the number comes from.

**Pass:** "Measured in Amplitude via the `first_value_moment` event (emitted when a user completes the 5-step onboarding flow)."
**Fail:** "Tracked via analytics."

Source attribution is where production-ready and observe-ready pick up: a metric with a named event becomes an acceptance criterion (production-ready emits the event) and a dashboard panel (observe-ready graphs it).

## 2. Leading vs. lagging indicators

Every Tier 2+ PRD separates the two.

### Leading indicators

Show movement early, before the outcome lands. They are the steering wheel.

Examples:

- Activation rate at day 7 (does the user come back after signup).
- Percent of new teams completing onboarding in the first session.
- Median time from signup to first action.
- Feature adoption rate in the first week.
- Referral invitations sent per activated user.
- Support ticket rate per 1,000 users (inverse: fewer is better).

Leading indicators move first. If they don't move, the lagging indicators will not move.

### Lagging indicators

Confirm the outcome. They are the scoreboard.

Examples:

- Weekly active teams at 90 days.
- Paid conversion at day 30.
- Net revenue retention at month 6.
- Churn rate at month 3.
- Organic-referral contribution to new signups at month 6.

Lagging indicators ratify; they do not steer. A PRD that cites only lagging indicators has no way to course-correct during build or early adoption.

### The rule

Every Tier 2+ PRD has at least one leading indicator and at least one lagging indicator. Tier 1 Briefs may have only lagging (the product is not shipped yet; leading indicators require instrumentation).

## 3. The "how many metrics" question

A PRD with 15 success metrics has no success metric. Nobody can track 15 simultaneously; the team will pick 2 implicitly and the other 13 will rot.

**Recommended counts:**

- **Tier 1:** 1 leading, 1 lagging (2 total).
- **Tier 2:** 2 leading, 2 lagging (4 total).
- **Tier 3:** up to 3 leading, 3 lagging plus 2 counter-metrics (8 max).

Counter-metrics are metrics we commit to watching *not* degrade (e.g., "while pushing activation, we commit to keeping day-30 churn below 12%"). They catch gaming.

If the PRD has more than the recommended count, collapse. The top-line metrics are the ones leadership will quote; the others are instrumentation that belongs in the team's ops dashboard, not the PRD's Success section.

## 4. Outcome vs. output (the north-star discipline)

Outputs are things you ship (features, releases, pages, docs). Outcomes are things that happen (behavior changes, revenue changes, retention changes). PRDs that optimize for outputs produce features nobody uses.

**Outputs:**

- "Ship the onboarding redesign by June 1."
- "Launch the billing page v2."
- "Publish 12 blog posts for SEO."

**Outcomes:**

- "80% of new teams complete onboarding in their first session (up from 50%)."
- "Median MRR per team in their second month reaches $X."
- "Organic traffic to /docs/ reaches 5K/month within 6 months of publish."

Outputs go in the functional requirements (Step 5) and roadmap-ready's schedule. Outcomes go in the Success section. A PRD that confuses the two is either prioritizing feature factory work over user value, or has not separated the ship date from the success criterion.

## 5. The "improvement baseline" rule

Every success metric names a baseline. "80% onboarding completion" is hollow without "up from 50%." The baseline is the current state; the metric is the target; the delta is what the PRD is claiming will happen.

If no baseline exists (pre-launch product, new feature without prior instrumentation):

- State "baseline unknown; will instrument in week 1 of build and measure 2 weeks of data before setting target."
- Flag as an open question at Step 8.
- Cap the tier at 2 until the baseline exists.

## 6. The HEART framework (Google) as a lens

Google's HEART framework (Happiness, Engagement, Adoption, Retention, Task success) is a useful lens for checking that the PRD's metrics cover the space. Not every PRD needs metrics in every dimension; the framework is a checklist.

| Dimension | Example metric |
|---|---|
| Happiness | NPS, CSAT, qualitative survey, 5-star rating |
| Engagement | Daily active users, session count, actions per session |
| Adoption | Percent of eligible users who have used the feature at least once |
| Retention | Day-7, day-30, day-90 retention; cohort curves |
| Task success | Completion rate for the core user task; error rate; time to complete |

If a PRD has 0 task-success metrics, it is probably measuring the wrong thing: engagement without task success can be gaming (users click around trying to find the thing). If a PRD has 4 adoption metrics and 0 retention metrics, it is missing the "did they come back" question.

## 7. Common traps

### Trap 1: Vanity metrics

Total signups, total pageviews, total downloads, total impressions. Metrics that only go up. They don't tell you anything about whether the product is working.

**Fix:** replace "total" with "active" and define active. "Weekly active teams" with active defined as "at least 3 actions taken by at least 2 team members."

### Trap 2: Ratios without volume

"95% conversion rate" sounds great until you learn the denominator is 20. Include both the rate and the volume it is measured over.

**Fix:** "95% conversion rate (measured across at least 1,000 sessions per week)."

### Trap 3: Metrics that measure the product's effort, not the user's outcome

"Number of API calls served per day." Fine for capacity planning; not a success metric.

**Fix:** reframe as user outcome. "Number of unique users completing a core flow per day."

### Trap 4: Survey metrics without response-rate discipline

"NPS of 50." With a response rate of 3%, this is probably selection-biased.

**Fix:** "NPS of 50 with at least 25% response rate across active-in-last-30-days users."

### Trap 5: Mixing in-product and in-market metrics

"8 of 12 PMs use the feature" and "launched to 10,000 customers" in the same list. These operate at different levels (behavioral vs. market). Keep them separate; don't compare.

### Trap 6: "Delight" metrics

"Users feel delighted." Not a metric. Either define a survey question and threshold, or drop.

### Trap 7: Metrics that require a data science project to compute

If the PRD's metric requires a multi-week data engineering project to instrument, it will not be measured on day 1. Either simplify, or explicitly budget the instrumentation in the functional requirements.

## 8. The success-metric handoff (to production-ready and observe-ready)

Each success metric in a Tier 2+ PRD has a hand-off:

- **To production-ready:** the event, log line, or data source that computes the metric. Example: "Event `status.generated` emitted on the client when the user clicks 'Generate status.' Properties: `user_id`, `team_id`, `sources_used[]`, `duration_ms`, `output_chars`."
- **To observe-ready:** the dashboard panel or SLO that surfaces the metric. Example: "Dashboard: Product > Activation. Panel: `status.generated` by day, 30-day rolling. Alert: if 7-day rolling rate drops more than 20% week-over-week."

Without the handoff, the metric exists on paper only. The handoff-producing discipline is what turns success metrics from PRD theater into live measurement.

## 9. The counter-metric discipline

For every forward metric, consider naming one counter-metric: "while pushing X up, we commit to not degrading Y."

Example pairs:

| Forward | Counter |
|---|---|
| Onboarding completion | Churn at day 30 |
| Feature adoption | Support ticket rate |
| Session duration | Frustration score (survey) |
| Conversion rate | Customer quality (LTV of converted cohort) |

Counter-metrics catch gaming. "Engagement" can be gamed by adding infinite scroll; the counter-metric "sessions leading to a completed task" catches it.

## 10. Timeline discipline

Every metric has a measurement timeline. Common patterns:

- **Immediate:** measured during onboarding or first session. Leading.
- **Short-term:** 7 days, 14 days, 30 days. Leading or early lagging.
- **Medium-term:** 60 days, 90 days. Lagging.
- **Long-term:** 6 months, 12 months. Lagging, often business-level.

A PRD with metrics only at 12 months has no steering input. A PRD with metrics only at 7 days has no retention signal.

## 11. The "what does success at 90 days look like" story

For Tier 1 Briefs, write a 90-day success story. One paragraph, prose, concrete.

**Example:**

> "By May 30, 2026 (90 days after launch), 8 of 12 PMs at our agency generate their Friday status via the tool (measured by count of `status.generated` events in Amplitude). Median time from opening the tool to clicking Send is under 10 minutes (down from the 40-90-minute baseline). We have collected 20 qualitative user comments via in-app feedback; at least 14 are positive (referencing time savings or client perception). Day-30 retention in the PM cohort is >75% (at least 9 of the 12 are still generating status weekly). No client has reported a factual error in a PRD-generated status doc."

The story pins down:
- the date (specific deadline)
- the primary adoption metric with a measurement source
- the primary outcome metric with a measurement source and delta
- a qualitative check
- a retention check
- a counter-metric (factual accuracy)

Stories beat metric lists for Tier 1 because they force the PM to imagine the state rather than tick boxes. Expand into a metric list at Tier 2.

## 12. The "am I measuring an input or an outcome" check

Quick audit: for each metric, ask "does this measure user behavior or product shipping?"

- "Onboarding is live" -> product shipping (output). Does not belong.
- "80% of users complete onboarding" -> user behavior (outcome). Belongs.
- "We have 3 blog posts about the feature" -> product shipping. Does not belong.
- "10% of blog-referred users sign up" -> user behavior. Belongs.

If the success list is more than half shipping-checkboxes, it is not a success list; it is a scope checklist with a pretend label.

## 13. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 6.3 (stack-ready's scale-ceiling input) and 6.4 (production-ready's acceptance-criteria consumption).
- Gibson Biddle, *DHM: Delight in Hard-to-copy, Margin-enhancing ways* (2013-2016, Lenny's Newsletter interview).
- Google, *HEART framework* (Kerry Rodden, Hilary Hutchinson, Xin Fu, CHI 2010).
- Andrew Chen, *The Cold Start Problem* (2021), chapter on leading vs. lagging engagement metrics.
- Amplitude, *North Star Framework* (2019) for outcome-centric metric hierarchies.
