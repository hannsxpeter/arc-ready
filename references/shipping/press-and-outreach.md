# Press and outreach (Step 9)

In 2026, press is smaller and more niche than in the 2015-2020 era. TechCrunch has shrunk; specialty newsletters and micro-influencers carry disproportionate weight for indie products. This reference covers press-kit contents, the niche target-list approach, the one-paragraph pitch-email format, and influencer and podcast outreach.

Press is optional. Mode E (quiet B2B direct) launches may skip Step 9 entirely; consumer and tool-space launches get at least a target list and one round of pitches.

## 1. The press kit

A single public page at `/press` or a hosted folder. No "request access" gate; journalists on deadline do not fill forms.

Contents:

- **Product name.** The exact spelling and capitalization.
- **Tagline.** One line. Passes the substitution test.
- **One-paragraph description.** 50 to 80 words. Ready to paste into an article.
- **Longer description.** 150 to 250 words. Names the audience, the problem, the mechanism, and the founder. Ready to paste into a feature.
- **Founder name and bio.** Short (50 words) and long (150 words) versions. Specific. "Prior ops lead at [named company]" beats "experienced software engineer."
- **Founder headshot.** Two sizes: 1280x1280 square for profile photos; 600x600 for avatar uses. High resolution, neutral background, recent.
- **Product screenshots.** At least three: hero screenshot (1280x720 or 1920x1080), a mid-detail screenshot of the product in use, a close-up of the distinctive UI element. Labeled with captions.
- **Logo.** SVG and PNG. Light-background and dark-background variants. The light version on dark backgrounds is often an embarrassment; include a dark-on-dark version.
- **Launch date.** Specific. "Publicly launched on April 23, 2026."
- **Landing page URL.** The canonical link.
- **Product Hunt URL, Hacker News URL, and other public launch links** once live. Updated day of.
- **Founder contact email.** Direct. Not `press@`.
- **Press policy.** One line. "Happy to answer questions; embargo respected if requested in advance."

Do not include:

- NDAs.
- Request-access gates.
- Enterprise sales pitches.
- Promotional videos that autoplay.

## 2. Target list

Not TechCrunch by default. In 2026, niche newsletters and specialty publications drive better-qualified traffic than generalist tech press.

### Categories

- **AI-focused newsletters.** TLDR AI, Ben's Bites, The Neuron, Import AI, The Rundown, Mindstream.
- **Developer-focused newsletters.** TLDR, The Pragmatic Engineer, Bytes (JavaScript), This Week in React, Golang Weekly, Python Weekly, Node Weekly.
- **Platform-specific newsletters.** Ruby Weekly, Rust Weekly, Elixir Radar, iOS Dev Weekly, Android Weekly.
- **Category newsletters.** Remote Rocketship (remote tools), Changelog (engineering podcasts and news), Product Hunt Daily Digest, Growthhackers Digest.
- **Industry newsletters.** Morning Brew, The Information (subscription), Stratechery (subscription), The Pragmatic Engineer (subscription). Less direct pitch; more about mention.
- **Niche trade publications.** Industry-specific to the product's domain.
- **Podcast interviewers.** Indie Hackers podcast, Software Engineering Daily, Changelog Podcast, Ship It, Build Your SaaS, My First Million.
- **Aggregators.** Hacker Newsletter (curates HN; one source).

### Research format per target

Each target entry:

- Name of the publication / newsletter.
- Curator or editor name.
- Category covered.
- Submission URL or email.
- Expected response turnaround (often days to weeks; some never respond).
- Example of prior coverage for a similar product.
- Notes on what they cover and what they do not.

Maintain the list in `.launch-ready/outreach-targets.md`. Update annually.

### The 2026 press-landscape reality

- **TechCrunch.** Much smaller reporting team; coverage is sparser. A successful TechCrunch pitch is possible but rare without an existing relationship or a newsworthy funding announcement.
- **The Verge / Ars Technica.** Tech-media consolidation; coverage is editorial-calendar driven more than pitch-response driven.
- **Product Hunt.** Still alive, covered in the launch-channels reference as a channel not as press.
- **Hacker Noon, Dev.to, freeCodeCamp.** Self-publish, not press. Covered in launch-channels.
- **Medium publications.** Some topical publications still accept submissions (The Startup, Better Programming, Level Up Coding, Towards Data Science).

### HARO / HARO-replacement

Help a Reporter Out (HARO) shut down in December 2024 and returned under new ownership in April 2025 via Cision's relaunch. Its reliability is lower than its pre-2024 reputation. Qwoted has become the more reliable alternative for journalist-source matching. Connectively also competes in the space.

Sign up on the journalist-response side; monitor for queries that match the product's domain. Respond with a one-paragraph pitch plus a direct quote. Multi-day response times are common.

## 3. The pitch email

One paragraph. One link. One sentence of founder context.

### Subject line

- Specific.
- Names the product.
- Names the reason this venue should care.

Examples:

- "Runbook: on-call handoffs for teams too small to hire an SRE (pitch for TLDR DevOps)"
- "Pitch: a Postgres extension for point-in-time schema snapshots"
- "For your developer-tools roundup: I built a CLI that explains build failures"

Bad:

- "Product Launch: Revolutionary AI Platform"
- "Would love to connect!"
- "Check out my startup"

### Body

Four sentences at most. Template:

```
Hi [Editor first name],

I am [founder name], and I just launched [product]. It is [one-sentence description using the positioning from Step 1]. I thought it might fit your [specific column / issue / beat] because [one sentence: why this venue specifically].

Happy to send more detail, a demo, or embargo if useful. Landing page: [link]. Press kit: [link]. My direct line: [email].

Best,
[Real name]
[Title at Product]
```

Five paragraphs is too long. Three sentences is too short. Four sentences with a specific "why this venue" is the sweet spot.

### Anti-patterns

- **CC-spray to five publications.** Each editor sees the CC list; reputation damage.
- **Attached press kit as PDF.** Attachments trigger spam filters; link instead.
- **"As a founder, I am passionate about..."** Self-description that adds nothing. Cut.
- **"Would love to connect and discuss how [product] could help your readers."** Sales-pitch voice; editors want a story pitch, not a sales call.
- **Mail-merged template with [EDITOR NAME] unfilled.** Seen often; instant delete.

## 4. Influencer outreach

Micro-influencers in the product's niche, not generic tech influencers.

### Identifying

- People whose Twitter / LinkedIn / YouTube audience matches the product's target user.
- Followers between 5,000 and 50,000 typically convert better than followers over 100,000 (less audience dilution).
- People who actually use adjacent tools and tweet / post about them honestly.
- Not people with "growth consultant" in bio who charge for shoutouts.

### The ask

Specific. Not "please retweet" or "would love your support."

Template:

```
Hi [name],

I have been reading your work on [specific piece]; the [specific point] resonated with how I was thinking about [adjacent problem].

I am launching [product] on [date]. Given your interest in [adjacent space], I wondered if you would take a 5-minute look at the demo (link: ...) and, if it resonates with you, mention it on launch day with your honest take. Happy to hear if this is not a fit; I will not take up more of your time.

[Real name]
[Direct contact]
```

Sent >7 days before launch. Not >30 days (forgotten) and not <48 hours (rushed).

### What does NOT work

- Paying influencers for promotional posts that are disclosed as paid. Launch-day traffic is not the goal; trust is.
- Offering affiliate commission to general-audience influencers.
- Bulk DM to a list of "tech influencers."

## 5. Podcast outreach

Longer lead time; more substantial audience.

### Timing

- Podcast pitches need a 4 to 12 week lead time to schedule and record.
- Not a launch-day lever. Pitches sent at launch are for follow-up interviews, not launch-day coverage.
- Note the timeline; flag as a D+14+ activity.

### Format

- Founder pitches themselves as a guest.
- Subject line: "Podcast guest pitch: [topic] - [founder name]."
- Body: one paragraph on why the founder is a good fit, one paragraph on the product's story, one paragraph on the topic the interview could cover.
- Link to a prior podcast appearance if any (recorded clips; not written blog posts).

### Target podcasts

Depending on product:

- **Indie / founder-focused:** Indie Hackers, My First Million, Build Your SaaS, Startups For The Rest Of Us, Ship It.
- **Engineering-focused:** Software Engineering Daily, Changelog, The Pragmatic Engineer, Developer Tea.
- **Industry-specific:** varies.

## 6. Press scheduling and embargo

For founders who want coordinated press coverage on launch day:

- Pitch with embargo >7 days in advance. "Embargoed until April 23 12:01 AM PT."
- Provide the press kit, the exclusive angle, and the interview availability in the first pitch.
- Respect the embargo; breaking it (on any side) poisons the relationship.

For most indie launches, embargo is overkill. A one-day-before-launch pitch to a newsletter that publishes weekly catches the next edition; same with podcasts that have weekly drops.

## 7. The "no press" path

If the launch strategy is broadcast-first (PH, HN, Reddit, X) and press is not a priority, Step 9 can be compressed to:

- Publish a press kit at `/press` for any journalist who finds the product.
- Do not send pitches.
- If a journalist reaches out post-launch, respond within 24 hours with the press-kit link and availability for a call.

Many successful indie launches do zero outbound press and let the channel-driven traffic surface press interest organically.

## 8. Research pass references

For TechCrunch-shrinkage analysis, Semafor and Axios coverage of tech-media consolidation 2024-2026. For HARO / Qwoted landscape, direct site comparisons. For micro-influencer vs. macro-influencer conversion data, inBeat and HypeAuditor studies. Citations in `RESEARCH-2026-04.md` section 12.
