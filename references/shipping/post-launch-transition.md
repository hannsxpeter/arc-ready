# Post-launch transition (Step 12)

The launch ends. Operations begins. The transition is an explicit handoff, not a fade.

This reference covers the transition criteria, the retrospective template, the hand-off to `production-ready`'s in-app telemetry, and the anti-patterns that keep teams in launch-mode when the window has closed.

## 1. Transition criteria

Declare the launch complete when all of these are true:

- **D+7 runbook complete.** Every scheduled item through D+7 has a checkmark.
- **Incoming traffic has dropped to within 3x of pre-launch baseline.** Launch-day traffic settles within 3 to 7 days; a launch that is still generating 10x traffic at D+14 is an unusually successful launch (rare) or the founder is posting new launch content daily (unhealthy).
- **The waitlist has been converted or segmented.** The hot 10% (highest engagement, highest signup-to-activation rate) get 1:1 outreach from the founder in the D+7 to D+14 window. The rest enter ongoing nurture.
- **The launch retrospective has been written.** Both the internal version and the external version.

If any of these are not true by D+14, the transition waits. But do not let it slip to D+30; the clearer the boundary, the cleaner the ongoing operations mode.

## 2. What transition looks like in practice

### Stop posting launch content

Week-two launch-content posts that re-hash the launch read as desperate. The founder's personal X / LinkedIn / newsletter shifts to:

- Product updates (what shipped this week).
- Behind-the-scenes posts (a specific decision, a specific bug, a specific learning).
- Customer stories (with consent).
- Domain commentary (thoughtful takes on the product's category, not re-posts of the launch).

If the launch is genuinely trending (still seeing meaningful organic share at D+14), the founder can and should keep engaging with the launch-content flow. The rule is "stop *creating* new launch content," not "stop responding to people who share the launch organically."

### Close the launch-campaign analytics

The UTM campaign `launch_YYYY_MM` becomes historical:

- No new shared links use this campaign value.
- New shared links get new UTMs (`weekly_update_YYYY_WW` for weekly newsletters; `blog_post_slug` for specific articles; `partner_XYZ` for partnership launches).
- The D+7 waterfall report is saved to `.launch-ready/launches/YYYY-MM-slug.md` as a historical artifact.
- The referrer dashboard continues to run, but the launch-day live-refresh discipline ends.

### Hand off to production-ready's in-app telemetry

Launch-day signups are now users. Their behavior is tracked in the product, not in the launch funnel. The distinction:

- **launch-ready's telemetry question.** Where did this visitor come from; did they sign up; did they activate (first meaningful action)?
- **production-ready's telemetry question.** Did the activated user adopt feature X in week 1? Did they retain to week 4? Did they hit the pricing tier's conversion threshold?

The handoff is operational, not technical. If both analytics tools are the same (PostHog for both launch and product), no migration happens; the reporting question changes. If launch-ready uses Plausible and production-ready uses PostHog, the launch campaign closes in Plausible and product analytics continues in PostHog.

### Archive the launch notes

Move `.launch-ready/launches/YYYY-MM-slug.md` to read-only status. Future launches read this file to avoid re-learning what the current launch learned.

The archive is not deletion. The file persists. A Mode C (relaunch) or Mode D (rescue) session months later reads the archive to know what worked and what did not.

## 3. The retrospective template

The launch retrospective is written twice: internal (honest, detailed, private) and external (shareable, specific, careful with numbers to share).

### Internal retrospective

Saved to `.launch-ready/retrospectives/YYYY-MM-slug.md`. Template:

```markdown
# Launch retrospective: [Product] - [YYYY-MM]

## Outcome summary
- Launch date: YYYY-MM-DD
- Mode: A / B / C / D / E
- Product Hunt rank: #N of N products of the day
- Hacker News: front page / second page / flagged / not posted
- Total landing-page visits on launch day: N
- Signups on launch day: N
- Email confirmations on launch day: N
- First-activation on launch day: N
- Revenue on launch day: $X (if applicable)
- Waitlist joined on launch day: N

## Conversion waterfall
| Stage | Count | Drop-off |
|---|---|---|
| landing_view | N | - |
| cta_click | N | N% |
| signup_submit | N | N% |
| email_confirmed | N | N% |
| activation | N | N% |

## Source breakdown
| Source | Visits | Signups | Rate |
|---|---|---|---|
| producthunt | | | |
| hackernews | | | |
| twitter | | | |
| ... | | | |

## What went right
- [Specific thing. Specific evidence.]
- [Specific thing.]
- [Specific thing.]

## What went wrong
- [Specific thing. Specific evidence.]
- [Specific thing.]
- [Specific thing.]

## Which of the five failure causes dominated (if the launch underperformed)
- [ ] Positioning (visitors arrived, bounced; hero did not explain)
- [ ] Venue (wrong channel or wrong time)
- [ ] Amplification (no hunter, no list, no first-hour activity)
- [ ] Capture (form broken, confirmation went to spam, CTA buried)
- [ ] Timing (competing industry event)

Dominant cause: [name]. Evidence: [specific].

## Surprises
- [Thing we did not expect.]
- [Thing we did not expect.]

## What we would do differently
- [Specific change, with reason.]
- [Specific change, with reason.]

## Open questions for next launch
- [Question.]
- [Question.]

## Links
- Landing page: [URL]
- PH post: [URL]
- Show HN post: [URL]
- X thread: [URL]
- LinkedIn post: [URL]
- Retrospective (external): [URL once published]
```

### External retrospective

Published as a blog post, X thread, or IH milestone. Template:

```
# What we learned launching [Product]

[Specific outcome in one sentence.]

[One paragraph of context: what the product is, for whom, why we launched.]

## The numbers
[Specific numbers the founder is comfortable sharing.]

## What worked
[2-3 specific things, each with a short explanation.]

## What did not
[1-2 specific things, honestly. Founder-voice.]

## What I would tell someone launching next month
[2-3 actionable learnings.]

[Closing: what is next, CTA to the waitlist or the product.]
```

External retrospectives that specifically name numbers (even modest ones) out-perform generic "we had a great launch" posts. Harry Dry's rule: "specificity is credibility."

## 4. The post-launch 1:1 outreach

The hot 10% of the waitlist, identified in the D+1 waterfall analysis (highest signup-to-activation rate, highest engagement emails), get 1:1 outreach from the founder in the D+7 to D+14 window.

Format:

- Personal email from the founder. Not a templated ESP send.
- Three sentences. Name something specific about their signup (where they came from if traceable; what their reply to a prior email said).
- One question. "What would make this more useful for your team?" "What would stop you from paying for this today?"
- No pitch. No "can we get on a call." The goal is conversation and learning.

Response rates on these emails are high (40 to 70 percent) because the list has self-selected for engagement. The responses inform the next three months of product decisions and often the next launch (Mode C relaunch or a new-feature launch).

## 5. When the launch underperformed

If the launch hit the "no traction" shape (low traffic, low signups, quick return to baseline), the retrospective's dominant-cause analysis is the forward-path input.

- **Positioning dominant.** Do not relaunch on the same positioning. Return to Step 1 with fresh competitor substitution tests. Consider whether the product needs repositioning for a different audience.
- **Venue dominant.** The product was fine; the launch venues were wrong. Pick different venues. If B2B and PH/HN failed, try LinkedIn-heavy or direct-outreach launch. If consumer and HN failed, try Instagram/TikTok or niche Reddit.
- **Amplification dominant.** Pre-launch list-building is the next month's work. Twitter following, newsletter subscribers, or community presence in the product's niche. Then relaunch when there is actually an audience.
- **Capture dominant.** Fix the form, fix the confirmation, fix the CTA. Then soft-launch by re-sharing to the existing waitlist (who are still subscribed; they still want the product).
- **Timing dominant.** Waiting out the competing event and re-launching two to four weeks later is acceptable. The original launch posts are still findable; a "we relaunched because our original launch coincided with Google I/O" is honest and sometimes well-received.

## 6. The anti-patterns of not-transitioning

### The perpetual launch

Some founders keep posting "launch day" content for weeks. Every X post is a variant of the launch thread. Every newsletter is an "early users" recap. This pattern reads as desperate; the audience that saw the original launch is tired of it by D+14.

The transition discipline: when D+7 closes, the marketing voice shifts to product, ongoing learning, and domain commentary.

### The launch that never ends because nothing is working

If post-launch metrics are low, the instinct is to keep pumping launch content. The better move is the retrospective; diagnose the dominant cause; fix it; relaunch intentionally. Two launches two months apart beat one launch stretched over ten weeks of diminishing returns.

### The launch retrospective that never happens

A launch without a retrospective cannot improve. The second launch repeats the first one's mistakes. The skill's Tier 4 requirement 20 is the retrospective explicitly; missing it fails the tier.

## 7. When a second launch is appropriate

A relaunch (Mode C or Mode D) is appropriate when:

- The retrospective has been written.
- The dominant cause has been diagnosed.
- A specific change has been made (new positioning, new venues, new capture flow).
- Enough time has passed that the new launch is not perceived as the old launch re-posted (typically 6 to 12 weeks minimum).

A relaunch sooner than 6 weeks reads as "the same launch again," and the original launch's audience is not ready to re-engage.

## 8. Research pass references

For post-launch retrospective conventions, the Indie Hackers milestones format and Arvid Kahl's "Zero to Sold" framing around post-launch iteration. Citations in `RESEARCH-2026-04.md` section 15.
