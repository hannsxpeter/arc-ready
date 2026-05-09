# Launch-ready antipatterns

Named failure modes launch-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand at every landing-page draft, every launch-week runbook review, and every Mode C audit of an in-flight launch. Complements `references/landing-page-anatomy.md`, `references/positioning-and-copy.md`, `references/launch-channels.md`, and `references/launch-week-runbook.md`.

## Core principle (recap)

> Put a deployed, healthy app in front of real users without shipping AI-slop. Every launch artifact is concrete (named user, named outcome, named source); every channel post is sourced; every signup is attributed.

The patterns below are violations of this principle.

## Pattern catalog

### AI-slop landing (Critical)

**Shape.** Hero copy that reads "Empower your team with AI-powered solutions." Three feature cards labeled "Streamlined," "Powerful," "Intuitive." Generic stock photo of diverse coworkers around a laptop. Could describe any product in any category.

**Grep test.** The substitution test: replace the product name with a competitor's. Does the page still read plausibly? If yes, the page is AI-slop. Specific named-user, named-job, named-outcome copy survives the substitution; abstract-empower-streamline copy doesn't.

**Guard.** `references/positioning-and-copy.md` mandates the substitution test. Step 2 of the workflow drafts hero copy against named target users from the PRD.

### Hero-fatigue copy (High)

**Shape.** Hero headline: "The Future of Work, Today." Sub-hero: "Transforming how teams collaborate." CTA: "Get Started." Every B2B SaaS page on the internet, indistinguishable from a thousand others.

**Grep test.** Banned-phrase grep against the hero block: `Future of`, `Transform your`, `Empower`, `Streamline`, `Game-changing`, `Revolutionary`, `Next-generation`, `Synergy`, `Disrupt`, `Unleash`. Hits in the hero fail.

**Guard.** `references/positioning-and-copy.md` carries the banned-phrase list. The lint runs against the launch artifact, not against the SKILL.md (which legitimately discusses these phrases).

### Spec-sheet positioning (High)

**Shape.** Landing page is a feature list. "Multi-tenant SSO. Audit logs. Webhook events. SOC 2 Type II. SAML. SCIM." Reads as a checklist; doesn't say what problem it solves for whom.

**Grep test.** The page's first 200 words name: a target user (specific role, not "teams"), a problem they have (specific friction, not "inefficiency"), an outcome the product delivers (named, measurable). Pages whose first 200 words are a feature list fail.

**Guard.** Step 2 of the workflow drafts copy starting from problem-and-user, not features. Features appear after the value paragraph, not before.

### Paper waitlist (Critical)

**Shape.** A "Join the waitlist" form. Submitting the form returns "Thanks!" Nothing happens. No email confirmation. No follow-up. No CRM record. Months later, the team launches and emails the waitlist; 80% bounce because the email-capture had no validation, no confirmation, no nurture.

**Grep test.** The waitlist form: (a) validates email, (b) sends a confirmation email, (c) records in a CRM or list-manager, (d) has a documented nurture cadence. Forms missing any fail.

**Guard.** `references/waitlist-and-email.md` is the canonical reference; mandates the four-element check.

### Unrendered OG card (High)

**Shape.** Sharing the launch URL on Twitter / LinkedIn / Slack produces a generic preview: no image, generic title, broken description. The opportunity for free social impressions vanishes.

**Grep test.** `og:image`, `og:title`, `og:description`, `twitter:card` meta tags present. The OG image is publicly accessible and renders correctly in `https://www.opengraph.xyz/url/<launch-url>` or equivalent. Missing or broken OG metadata fails.

**Guard.** `references/social-share-cards.md` is the canonical reference. The launch-week runbook D-3 step verifies OG rendering.

### Silent launch (Critical)

**Shape.** Launch day. Signups arrive. The signup form doesn't capture source attribution. The team can't tell which channel drove the signups. Post-launch analysis is "people came from somewhere; we got 200 signups."

**Grep test.** Every signup row records: source (UTM parameters from the URL the user arrived on), referrer (HTTP referer), and timestamp. Forms that capture only email fail.

**Guard.** `references/launch-telemetry.md` mandates source attribution. Every launch-channel link uses a unique UTM tag.

### Launch as the first deploy (Critical)

**Shape.** The team's first prod deploy is the launch day deploy. The team has never run the production app for more than a few hours. Launch-day reveals capacity issues, crash bugs, missing env vars.

**Grep test.** Production has been live for >= 14 days before launch day. At least one synthetic load test has run at expected launch-day concurrency. Pre-prod environment was exercised by real internal users for >= 7 days.

**Guard.** `references/launch-week-runbook.md` D-14 step verifies prod soak. The deploy-ready / launch-ready handshake mandates a minimum soak period.

### Channels picked from a list (Medium)

**Shape.** Launch playbook copies a generic list: "Post on Product Hunt, Show HN, Reddit r/SaaS, Indie Hackers, Twitter, LinkedIn, dev.to." Six channels in one day. Three of them are wrong-fit for the product; one of the right-fit ones gets neglected.

**Grep test.** Channel selection cross-references the target user (from PRD) against the channel's audience. Each picked channel has: a named reason for fit, a launch-day post (in voice, not auto-generated), and a measurable goal.

**Guard.** `references/launch-channels.md` carries audience profiles per channel. Step 4 of the workflow forces fit-check.

### Press kit that's a screenshot folder (High)

**Shape.** "Press kit" linked from the launch page. Clicking it opens a Google Drive folder with three screenshots and an outdated logo. No founder bio. No product summary. No quote-able lines.

**Grep test.** Press kit contains: founder bio (50-100 words), product summary (50 words), 3+ quote-ready lines, logo (SVG and PNG, light and dark variants), 3+ product screenshots (high-res), launch date and contact email.

**Guard.** `references/press-and-outreach.md` carries the canonical press-kit anatomy.

### Launch-week runbook never rehearsed (High)

**Shape.** Detailed runbook for D-7 through D+7. Nobody has executed any of it. D-7 arrives and the team realizes step 4 ("notify Resend of the expected volume bump") has a 5-day approval cycle.

**Grep test.** Runbook has been tabletop-rehearsed at least once. Each step has a named owner. SLA-bound external steps (provider notifications, press embargo windows) have lead-time documented.

**Guard.** `references/launch-week-runbook.md` mandates D-30 tabletop. The launch-ready discipline carries this.

### Hero that is the wrong product (Critical)

**Shape.** The landing page's hero describes a product the team isn't actually shipping. Aspirational copy from the pitch deck made it onto the marketing site. Visitors sign up; the actual product disappoints; reviews go bad.

**Grep test.** Every claim in the hero block must trace to a feature in `.production-ready/STATE.md` or equivalent shipping evidence. Aspirational claims about features in the v1.x roadmap fail.

**Guard.** Step 2 of the workflow grounds copy in shipped features. Roadmap features appear in a separate "Coming soon" section if at all.

### SEO afterthought (Medium)

**Shape.** Launch happens. Two weeks later someone realizes the landing page has no `<title>` tag, no meta description, no `<h1>`, no schema.org markup, no sitemap. Organic traffic baseline is zero.

**Grep test.** Pre-launch SEO checklist: title tag (under 60 chars), meta description (under 160 chars), one `<h1>`, schema.org / JSON-LD for the product, sitemap.xml at root, robots.txt allowing the launch URL. Missing any fails.

**Guard.** `references/seo-fundamentals.md` is the canonical reference. D-3 step of the runbook verifies.

### Founder absent on launch day (High)

**Shape.** Launch day. Hacker News post climbs to #2. Comments accumulate; questions pile up; objections get airtime. The founder is on a plane / in a meeting / unavailable for 6 hours. Top comments are unanswered; the post drops.

**Grep test.** Launch-day runbook names the founder's availability for the 8-hour window after each channel post. Anyone who replies to comments has the founder's voice (not the marketing team's).

**Guard.** `references/launch-week-runbook.md` mandates founder-availability commitment for D-day.

### Launch numbers without baseline (Medium)

**Shape.** Post-launch retro: "We got 1,200 signups." Is that good? Bad? Compared to what? No baseline; no benchmark; the number floats unmoored.

**Grep test.** Launch-day metrics report names: target (set pre-launch), benchmark (industry / category baseline), actual, delta. Reports with only the actual number fail.

**Guard.** Step 5 of the workflow defines launch-day targets pre-launch. Post-launch metrics are gradient against the target, not absolute.

### Treating launch as the goal (Medium)

**Shape.** The team optimizes for the launch event. The day after, energy collapses. The waitlist doesn't get nurtured. Press follow-ups get dropped. Signups don't activate.

**Grep test.** D+7 plan exists alongside D-7 plan. Post-launch handoff to the ongoing-marketing function is named.

**Guard.** `references/post-launch-transition.md` covers the D+1 through D+30 cadence.

## Severity ladder

- **Critical**: blocks the launch. Must be fixed before launch day.
- **High**: blocks the tier gate. Must be fixed before next milestone.
- **Medium**: flagged in the runbook; fix recommended.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": canonical have-nots list.
- `references/landing-page-anatomy.md`: section structure.
- `references/positioning-and-copy.md`: substitution test, banned phrases.
- `references/launch-channels.md`: per-channel audience profiles.
- `references/launch-week-runbook.md`: D-7 to D+7 calendar.
- `references/waitlist-and-email.md`: capture + nurture discipline.
- `references/social-share-cards.md`: OG metadata.
- `references/seo-fundamentals.md`: pre-launch SEO checklist.
- `references/launch-telemetry.md`: source attribution.
- `references/post-launch-transition.md`: D+1 through D+30.
