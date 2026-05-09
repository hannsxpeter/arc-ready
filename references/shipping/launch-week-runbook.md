# Launch-week runbook (Step 11)

The runbook is a calendar, not a checklist. Each item has a day, an hour, an owner, and a pass criterion. Without a calendar, the launch becomes a single exhausted sprint on launch day during which half of Step 1 through Step 10 is re-discovered under pressure.

This reference covers D-7 through D+7 with timezone-aware scheduling, the launch-day hour-by-hour, and the pre-written response templates.

## 1. D-7: one week out

Pass criteria: every Tier 1, Tier 2, and Tier 3 item from SKILL.md is in draft or better. Remaining items are Tier 4.

### Day-7 actions

- **Positioning document finalized.** The four sentences from Step 1. Locked unless a major realization arrives before D-3.
- **Landing page shipped to staging.** Real content, real OG card, substitution test clean.
- **Banned-word audit green on the full landing page** (not just hero).
- **OG card previewed on five channels.** Screenshots saved in `.launch-ready/assets/og-previews/`.
- **LinkedIn Post Inspector cleared on the production URL.** Pre-fetches the correct OG card before launch day.
- **Waitlist live with double opt-in.** Send a test email to yourself; confirm the flow end-to-end.
- **Welcome email drafted.** Pre-launch sequence drafted (at least two emails between welcome and launch day).
- **SPF / DKIM / DMARC verified.** mail-tester.com score >= 9.0.
- **Analytics tool installed.** Five conversion-waterfall events instrumented. Test events fire in staging.
- **UTM registry created.** Every planned link documented.
- **Product Hunt post drafted.** Title, tagline, description, media, topics chosen.
- **Hunter confirmed >48 hours out** (so the D-7 commitment is a safe bet).
- **Show HN draft prepared.** Title, first-comment body drafted.
- **X thread drafted.** All seven tweets in a doc; demo GIF or video recorded.
- **LinkedIn post drafted.**
- **Reddit target subs identified.** Founder comment history verified on each.
- **Soft-asks sent to amplification list.** "Launching April 23, would love a PH upvote / HN discussion comment / RT. I will send the link day-of."
- **Press pitches sent** for long-lead-time venues (podcasts, monthly newsletters, embargo-supported press).

## 2. D-3: three days out

Pass criteria: final copy reviews, dry runs of every shareable path.

### Day-3 actions

- **Hero copy final.** Substitution test re-run against the current competitor set.
- **Feature grid final.**
- **Banned-word audit re-run** on the final copy.
- **Dry run every OG preview.** Post the landing URL to a test Slack, a test X post, a test LinkedIn (to a private test account, then delete), iMessage, Discord. Confirm the current OG renders.
- **Pre-written response library drafted.** A short file of reply templates for common PH / HN / Reddit comments:
  - "What does it cost?"
  - "How is this different from [competitor]?"
  - "Is this open source?"
  - "What stack is this built on?"
  - "Can I self-host?"
  - "Is there an API?"
  - "How do you handle [specific concern]?"
  Each response is 2 to 4 sentences; saved in `.launch-ready/assets/response-templates.md`.
- **Launch-day email drop scheduled in the ESP.** Confirm the send time (usually 11:00 AM PT on launch day).
- **Status page ready.** Out-of-band hosting verified. Linked from landing-page footer.
- **Load test the landing page.** 10x expected peak traffic; confirm no regressions.

## 3. D-1: the day before

Pass criteria: calm; nothing left to discover.

### Day-minus-1 actions

- **Final status-page dry run.** Trigger a test incident (privately); confirm the page updates.
- **Team channel set up.** Slack / Discord / Telegram channel for launch-day coordination if the team has multiple people.
- **Timezone-aware schedule posted** to the team channel. Every scheduled event with its timezone.
- **Analytics end-to-end tested.** Walk through the five-event waterfall with a test conversion; confirm each event logs.
- **Waitlist pre-launch email #2 sent** (if scheduled for T-minus-1).
- **OG cards re-verified on X, LinkedIn, Slack.** One more time.
- **Founder goes to bed early.** A 12:01 AM PT launch needs the founder awake for the first 4 hours; a 7 AM PT launch needs 4 hours of sleep the night before.

### The no-change rule

No code changes to the app or landing page after 6 PM PT on D-1, unless a launch-blocking bug is found. Last-minute changes introduce risk at the worst time. The staging environment is already proven; touch it at your peril.

## 4. D-0: launch day

Timezone-aware hour-by-hour. All times in Pacific Time (PT) with Eastern (ET) in parentheses. Adjust base schedule to the founder's actual base.

### 12:01 AM PT (3:01 AM ET): Product Hunt goes live

- **0:00:00.** Publish the PH post.
- **0:00:30.** Post the maker comment. Pin it.
- **0:01:00 to 0:05:00.** First upvote wave (amplification list); founder upvotes from the founder account.
- **0:05:00 to 0:30:00.** First comment responses. Founder replies to every comment in the first 30 minutes.
- **0:30:00 to 1:00:00.** Monitor referrer dashboard; tweet a "we are live on PH" thread teaser from the founder account (do NOT post the full launch thread yet; save for 8:30 AM).

### 1:00 AM PT to 6:00 AM PT (4-9 AM ET): quiet hours

- PH traffic accumulates; no new channels activated.
- Founder sleeps from approximately 1 AM to 5 AM PT.
- Wake at 5 AM PT; check PH ranking, read overnight comments, respond to the ones that matter most.

### 7:00 AM PT (10:00 AM ET): Show HN

- **7:00:00.** Submit Show HN post.
- **7:01:00.** Post the first comment (founder context, technical detail, specific ask).
- **7:01:00 to 7:30:00.** Monitor. If HN auto-flags (drops in rank very quickly without votes), check the title for banned patterns; do not re-submit the same URL.
- **7:30:00 to 9:00:00.** Respond to every HN comment within 30 minutes. Tone: technical, thoughtful, humble.

### 8:30 AM PT (11:30 AM ET): X / Twitter thread

- **8:30:00.** Post the full seven-tweet thread from the founder's personal account.
- **8:31:00.** Retweet from the product account. Amplifiers RT now.
- **8:30:00 to 11:00:00.** Respond to every substantive reply in the thread.

### 9:00 AM PT (12:00 PM ET): LinkedIn

- **9:00:00.** Post the founder-voice LinkedIn post. Link in first comment.
- **9:00:00 to 11:00:00.** Respond to every comment.

### 10:00 AM PT to 1:00 PM PT: Reddit, staggered

- **10:00 AM PT.** /r/SideProject post.
- **11:00 AM PT.** /r/SaaS post.
- **12:00 PM PT.** Niche subreddit post (only one per hour per account to avoid spam pattern detection).
- Respond to every comment in each sub.

### 11:00 AM PT (2:00 PM ET): waitlist launch-day drop

- Email sends to the pre-confirmed waitlist list.
- Monitor open rate and click rate in the ESP.
- UTM: `utm_source=email_launch&utm_medium=email&utm_campaign=launch_YYYY_MM&utm_content=launch_day_drop`.

### Every 30 minutes through 6 PM PT: the launch-day loop

- Refresh the referrer dashboard. Note top source, conversion rate, any anomalies.
- Check PH ranking, HN ranking, X thread engagement.
- Respond to new comments on every channel.
- Check the status page dashboard (observe-ready's SLOs, if installed). Any red row triggers an immediate investigation.

### Every 2 hours: health check

- Status page check.
- App SLO check (observe-ready's dashboards).
- CDN / hosting dashboard.
- Database connection pool (if dynamic).

### End of day (7-10 PM PT): write the day-0 note

- Not a blog post. A private note in `.launch-ready/launches/YYYY-MM-slug.md`.
- What worked. What did not. What surprised. What hit at which time.
- Specific numbers: landing views, signups, PH rank, HN rank, referrer breakdown.
- One sentence on what to do tomorrow.
- Founder goes to bed; D+1 is a new day of work.

## 5. D+1: thank-you day

Pass criteria: every launch-day question answered; the waitlist thanked.

### Day-plus-1 actions

- **Thank-you email to the waitlist.** "Thank you. Here is what happened on launch day." Specific numbers.
- **Analyze the conversion waterfall.** Which source converted best? Which was highest volume? Which was highest quality (lowest drop-off at activation)?
- **Answer overnight comments.** Any PH / HN / Reddit comment from the overnight hours gets a reply.
- **Reply to press pitches that bit.** If any journalist reached out during launch day, respond within 24 hours with the press-kit link and availability.
- **Embed the PH badge** on the landing page if the product placed in the top 5 of the day.
- **Do not post new launch content on new channels today.** The launch is the launch; week-two content is week two.

## 6. D+3: first-learning day

### Day-plus-3 actions

- **"Here is what we learned" email** to the list. Pick one specific insight from the launch. One user quote. One concrete next step.
- **First post-launch tweet** with a specific number (signups, conversions, feedback themes).
- **Onboarding friction audit.** Walk the signup flow fresh (use a different device, different browser, different email). Where did users drop? Fix the highest-drop-off step.
- **Respond to any late PH / HN / Reddit comments.** Launch posts have a long tail; engagement continues for days.

## 7. D+7: retrospective day

### Day-plus-7 actions

- **Launch retrospective: internal version.** Written honestly, saved to `.launch-ready/retrospectives/YYYY-MM-slug.md`. Covers:
  - Numbers: landing views, signups, conversions, activation, retention so far, revenue if applicable.
  - What went right.
  - What went wrong.
  - Which of the five launch-failure causes (positioning, venue, amplification, capture, timing) dominated if the launch underperformed.
  - What to do differently next time.
- **Launch retrospective: external version.** Blog post, X thread, or IH milestone. Specific numbers. Honest takeaways. No spin.
- **"What shipped this week" email** to the list. Specific items.
- **Post-launch transition declared.** Step 12.

## 8. Timezone-aware scheduling note

The schedule above assumes the founder is in US Pacific. Adjust for other bases:

- **US Eastern founder.** Add 3 hours to every time. PH post goes live at 3:01 AM ET; founder is asleep for the first 4 hours unless willing to stay up.
- **European founder.** 12:01 AM PT is 9:01 AM CET. Founder is awake; maker comment and early responses are easier. Show HN at 4 PM CET; founder is still active.
- **Asian / Australian founder.** 12:01 AM PT is late evening CST (China); very late night AEST. Asian / Australian founders often schedule the PH post and schedule auto-comments to pin, then wake for the Show HN submission.

## 9. The calendar artifact

The runbook is not a document; it is a calendar. Create real calendar events with reminders for every scheduled action. Share the calendar with any teammates.

Format for each calendar event:

- Event title: "[LAUNCH] Submit Show HN - runbook.dev."
- Time: exact, with timezone.
- Description: the pass criterion, the URL to submit, the first-comment text in full (not a link to a doc; the text is right there).
- Reminder: 5 minutes before.

## 10. Pre-written response library

Saved in `.launch-ready/assets/response-templates.md`. Each template is 2 to 4 sentences; the founder edits to fit the specific comment.

Common PH / HN / Reddit questions:

### "What does it cost?"

```
[Product] is free during beta. We plan to introduce paid tiers at [general timeline]; the team tier will land around [$X/mo] and the enterprise tier is [concrete; often 'contact us']. If you join the waitlist, you get [specific perk].
```

### "How is this different from [competitor]?"

```
Good question. The main difference is [one-sentence specific differentiator]. [Competitor] does [their strength]; we chose [our approach] because [reason]. We are not trying to be a [competitor] alternative for [specific use case]; we are better at [specific use case].
```

### "Is this open source?"

```
[Yes / No / Partially]. [If yes: repo link.] [If no: explain why not; the honest answer beats the defensive one.] [If partially: what is open, what is not.]
```

### "What is the tech stack?"

```
[Honest answer.] Frontend: [framework]. Backend: [framework/language]. Database: [db]. Hosting: [provider]. Built in [timeframe].
```

### "Can I self-host?"

```
[Yes / No / Future plans.] [Explain the path.]
```

## 11. Research pass references

For launch-day timing conventions, Ben Lang and Pieter Levels' published playbooks. For the Aidlab HN postmortem and the Show HN title dynamics, the Indie Hackers writeup. For timezone-awareness, community-level conventions on PH and HN discussion threads. Citations in `RESEARCH-2026-04.md` sections 11 and 15.
