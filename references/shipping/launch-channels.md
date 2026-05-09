# Launch channels (Step 8)

Launch-channel work is the most venue-specific part of the skill. Each channel has its own etiquette, timing, and flagging dynamic. Ignoring any of them produces silent failure: the venue rejects or downranks without a visible error, and the founder learns from the traffic numbers.

This reference covers Product Hunt, Hacker News (Show HN), Reddit, X/Twitter, LinkedIn, Indie Hackers, and dev.to. Per channel: title discipline, timing, hunter/submitter requirements, amplification, and response plan.

## 1. Product Hunt

The canonical indie launch channel. Still alive in 2026, with significant algorithmic changes from the Ryan Hoover era.

### The 2025-2026 algorithm

The most important change: only approximately 10% of submissions are "Featured" (curated onto the homepage). Un-Featured submissions accumulate upvotes but are invisible to the mobile audience, which is the majority of PH traffic. The algorithm explicitly discounts or zeroes votes from:

- New accounts (created within weeks of voting).
- Accounts with coordinated voting patterns (voting for the same products in the same order in a short time window, detected via graph analysis).
- Voting clusters that appear to originate from the same company or Slack group.

The old playbook of rallying brand-new accounts in a group chat actively hurts in 2026.

### Timing

- **Day.** Tuesday, Wednesday, or Thursday. Monday and Friday are avoided by experienced launchers; weekend traffic is a fraction of weekday.
- **Hour.** 12:01 AM Pacific Time is canonical. PH's day cycle resets at midnight PT; launching at 12:01 gives a full 24 hours of ranking time.
- **Avoid.** Friday, Saturday, Sunday. Also avoid the day of major competing launches (another large company's launch on the same PH day will consume attention).

### Hunter

- **Confirmed >48 hours in advance.** A hunter who pulls out the day before is the worst possible scenario; confirmation with a scheduled reminder is standard practice.
- **Hunter account quality matters less than in 2022** due to algorithm changes, but a hunter with a record of successful launches still helps with the "who is this" signal in the first hour.
- **The founder can self-hunt.** Self-hunting is acceptable and common. The "hunter" role is less load-bearing than 2022 lore suggests; a first-time founder self-hunting does fine if the product is strong.

### The PH post

- **Name.** The product name. One word or two-word phrase. Unambiguous.
- **Tagline.** One line. Passes the substitution test (Step 1). Not a rehash of the hero; a PH-native tagline. Example: "On-call handoffs that update themselves in Slack."
- **Description.** Two to four paragraphs. First paragraph: what the product does, for whom, in replacement-framed language. Second paragraph: the differentiator. Third paragraph: what the founder hopes for from PH feedback. Fourth paragraph (optional): the founder's origin story.
- **Images / media.** Product screenshots (not abstract gradients), a short demo GIF or video, OG card. PH requires at least a gallery of images.
- **Topics.** Tag accurately. Maximum three relevant topics. Over-tagging is spam-signaling.

### Maker comment

Posted within the first 2 minutes of the launch going live. This is the founder's first impression; it is read by everyone who clicks into the PH post in the first hour.

Format:

- **First line.** "Hi PH! I am [name], founder of [product]."
- **Second paragraph.** What the product does in replacement-framed language. One technical detail that demonstrates the founder knows the domain.
- **Third paragraph.** What the founder is asking PH for. "Feedback on the pricing model" or "would love to hear from anyone who has tried X approach" or "interested in whether the category resonates." Specific asks convert better than generic "let us know what you think."
- **Closing.** "Happy to answer questions. I am here all day." Sign with real name, not brand handle.

Pin the maker comment so it stays at the top of the discussion.

### Amplification

The first hour is where PH's ranking signal forms. Amplification list requirements:

- **Minimum 10 real humans** who will visit and upvote in the first 2 hours.
- **Asks sent >48 hours in advance** so they are not scrambling on launch morning.
- **Varied account origins.** Not all from the founder's company or VC network; spread across genuine early users, industry contacts, friends who actually care.
- **Not bought.** PH actively detects paid engagement; it downranks or zeroes. The old "upvote group" on Telegram is a 2022 pattern that does not work in 2026.

### Comment strategy through the day

- Respond to every top-level comment within 30 minutes for the first 4 hours.
- Respond to every top-level comment within 60 minutes for the rest of the day.
- Upvote comments (PH-native engagement) rather than stacking replies.
- Ask follow-up questions in replies; PH rewards depth of discussion.

### Badge and post-launch

- If the launch places in the top 5 of the day, embed the PH badge on the landing page.
- Save the PH URL for the launch log; it remains findable for years and drives trickle traffic.

### Product Hunt have-nots

- Launches on Friday, Saturday, Sunday.
- Launches scheduled for non-midnight-PT times.
- Hunter not confirmed >48 hours in advance.
- Tagline using banned words (Step 3 audit applies).
- Maker comment posted >5 minutes after the launch goes live.
- Amplification list of "please upvote" asks without any specific engagement ask.
- Coordinated voting clusters from the same Slack/Discord.

## 2. Hacker News (Show HN)

The highest-quality traffic channel for developer-oriented products. Different etiquette from PH.

### Title discipline

Show HN title format, per news.ycombinator.com/showhn.html:

- **"Show HN: [Product] - [one-line description]".**
- No "Launch HN" (reserved for YC-backed; non-YC gets flagged).
- No all-caps.
- No "we built" (first-person-plural is discouraged; state the product and what it does).
- No emojis.
- No year in the title (the Aidlab postmortem specifically called this out as lowering quality).

Good titles:

- "Show HN: Runbook - On-call handoffs that update themselves."
- "Show HN: A Postgres extension for point-in-time schema snapshots."
- "Show HN: I built a CLI that explains why your build failed."

Bad titles:

- "Launch HN: Runbook for On-Call Teams (YC S25)" (non-YC use).
- "SHOW HN: REVOLUTIONARY AI PLATFORM FOR DEVOPS [rocket emoji]" (caps, banned words, emojis).
- "We built a new way to manage on-call" (we-voice, vague).

### Timing

- **Day.** Tuesday, Wednesday, Thursday preferred. Monday is viable. Friday drops off by afternoon; Saturday and Sunday are dead for Show HN.
- **Hour.** 7:00 AM Pacific to 10:00 AM Pacific (10 AM ET to 1 PM ET). HN's US-heavy early-morning audience is the first-wave readers.
- **Avoid.** 12:00 AM PT (submissions posted overnight accumulate downvotes during Europe-Asia hours when the submitter is asleep). Friday afternoon and weekends.

### Submitter

- **Real HN account.** >1 year old preferred. Some comment karma.
- **Throwaways get flagged** quickly; HN's moderation is strict on apparent self-promotion from fresh accounts.
- **Founder submits as themselves.** Co-founder submission is fine; marketing team submission is not the same as founder submission in HN culture.

### The post body

Show HN accepts a URL plus an optional first comment from the submitter. The first comment is the founder's chance to set context.

Format:

- **First line.** "Hi HN, I am [name]. [One sentence on what it does and for whom]."
- **Second paragraph.** The specific technical detail or decision that makes this interesting to HN. HN rewards technical depth; a post that could have been a marketing page rarely ranks.
- **Third paragraph.** The ask. "Curious about [specific technical question]" or "would love feedback on [specific design decision]." Specific asks drive high-quality comments.
- **Closing.** "Happy to answer questions." Sign with real name.

HN readers know when a post is a marketing veneer over a low-content product. The first comment must demonstrate the founder knows the technical terrain better than a marketer would.

### Amplification on HN

Different from PH. HN's algorithm punishes early vote clusters that look coordinated. The pattern:

- **Do not rally 20 upvotes in the first 10 minutes.** This looks like vote manipulation and can trigger a flag.
- **Do send 3-5 knowledgeable friends the link** to read and comment thoughtfully. HN rewards discussion depth; a thoughtful comment from a real user in the first hour helps the post.
- **Do not use the "second-chance pool" game.** If the post does not take off in the first hour, let it go; do not re-submit the same URL repeatedly.

### Response through the day

- Respond to every comment within 30 minutes for the first 2 hours.
- Respond thoughtfully; HN culture values substantive replies over quick acknowledgments.
- Do not argue with critical comments; acknowledge, ask clarifying questions, admit what is true in the criticism.
- Update the post or the product if a bug is surfaced and fixed in real time.

### Flagging dynamics

HN moderates aggressively. Posts get flagged and fall off the front page for:

- Title that sounds like marketing ("revolutionary," "game-changing," "world's best").
- Product that is a thin wrapper over another product's API without substantive differentiation.
- First comment that is a sales pitch.
- Account that shows no prior HN participation (new account, first post is a Show HN).
- Coordinated upvoting detected by HN's algorithm.

### Hacker News have-nots

- "Launch HN" in the title for a non-YC product.
- All-caps title.
- "We" as the subject in the title ("We built X").
- Emojis anywhere in the title or first comment.
- First comment under 100 words (reads as effort-less).
- Submitter account < 6 months old with no comment history.
- Weekend submission without a specific reason (low traffic, worse ranking).

## 3. Reddit

High-variance channel. Done right, Reddit drives targeted, knowledgeable traffic. Done wrong, the post is deleted within hours and the account is banned from the subreddit.

### The 9:1 rule

Most subreddits that allow any self-promotion require a 9:1 ratio of non-promotional participation to promotional. The founder's account must have 9 substantive comments, link shares, or posts in the sub (or related subs) for every 1 self-promotional post. Zero history equals immediate removal.

Build the 9:1 weeks before launch. Comment on other founders' posts. Share useful links. Answer questions.

### Target subreddits

Niche-specific. Examples:

- **/r/SideProject.** General indie / side-project launches. Moderate traffic.
- **/r/SaaS.** SaaS-specific. Self-promotion Thursdays often permitted.
- **/r/EntrepreneurRideAlong.** Founder-story format. "Here is what I built and why."
- **/r/webdev, /r/programming.** Developer tools; moderation is strict on marketing language.
- **/r/devops, /r/sre, /r/kubernetes.** Specific to devops tools.
- **Niche subs for the product's domain.** /r/analytics for analytics tools, /r/marketing for marketing tools, /r/startups for business-side products.

Read each sub's rules before posting. Rules vary widely; some ban self-promo entirely, some allow only on specific days, some require flair.

### Timing

- **Day.** Monday through Thursday. Reddit traffic peaks mid-week US daytime.
- **Hour.** 10:00 AM to 1:00 PM Eastern. Avoid early-morning (low US traffic) and late-night (mod-removal risk because mods are asleep and users flag).

### Post format

Varies by sub, but the pattern that works most places:

- **Title.** Question-shaped or show-and-tell-shaped per the sub's norm. Avoid pure promotion.
- **Body.** Tell a story. What problem did you hit. What did you build. What did you learn. What would you do differently. Reddit rewards introspection; pure pitch is flagged.
- **Link.** Place the product link in the body, not the title, unless the sub specifically allows link posts.
- **Disclosure.** If the sub requires a self-promotion tag or disclosure ("I am the founder"), include it early.

### Post-post behavior

- Respond to every comment in the first 2 hours.
- Upvote comments (do not just reply); Reddit rewards engagement.
- If the post is removed, do not re-post. Learn the rule; come back in weeks after more participation.

### Reddit have-nots

- Sub where founder has zero comment history.
- Post that is a bare product pitch with no story.
- Multiple subs cross-posted in the same hour (looks spammy; Reddit's algorithm detects).
- Title using banned words.
- Link in the title on a sub that requires text post.

## 4. Twitter / X

The amplification layer for all other launch channels. Less discovery; more multiplication.

### The launch thread

A launch-day thread is the canonical X format. Structure:

- **Tweet 1 (the hook).** One sentence that stops the scroll. Names the product and the specific thing it does. Includes the OG card image (attached image, not a link). No hashtags; hashtags depress reach on X as of 2026.
- **Tweet 2 (the problem).** Specific frustration the founder hit. "Last Friday my on-call rotation broke because..." Sets up the need for the product.
- **Tweet 3 (what it does).** Demo GIF or short video. 15 to 30 seconds maximum. Shows the product doing the thing.
- **Tweet 4 (the differentiator).** "Most tools do X. Runbook does Y because..."
- **Tweet 5 (proof).** User quote, beta usage numbers, or concrete "here is what you can do with it today."
- **Tweet 6 (the ask).** Link to the landing page. "If this resonates, you can [specific CTA]." The link is last so the thread is read, not just clicked.
- **Tweet 7 (the meta).** If launching on PH or HN, link those posts here with a "and if you are on PH, an upvote would help."

### Timing

- **Day.** Tuesday to Thursday. Friday afternoon through Sunday is noise.
- **Hour.** 8:00 AM to 10:00 AM Pacific (11:00 AM to 1:00 PM Eastern). Morning engagement is highest for the US audience.

### Account requirements

- Founder posts from their personal account, not the product account.
- The product account (if exists) retweets and participates in the replies.
- First-time-posting accounts get low reach regardless of content; a history of real engagement helps.

### Engagement through the day

- Reply to every substantive comment in the thread.
- Quote-tweet interesting replies to amplify them.
- Do not fight anyone in the replies; acknowledge, correct if needed, move on.

### Twitter / X have-nots

- Product account posting instead of founder personal account (unless the product is fully faceless).
- Thread without a demo GIF or video.
- Thread that buries the product link in tweet 1 (kills the read-through rate).
- Hashtags in the thread (suppresses reach).
- Weekend posting.

## 5. LinkedIn

Undervalued for B2B launches in 2026. Founder-voice posts out-perform company-page posts.

### Format

- **First line.** Hook. One sentence that stops the scroll. LinkedIn shows only the first 2 to 3 lines before the "see more" cut.
- **Body.** Founder-voice first-person. One specific incident or decision that led to the product. The "see more" reveals the full story.
- **Image.** One; either the OG card or a real photo of the founder / team / product.
- **No hashtags** in the first version. Hashtags can be added in edits; LinkedIn's 2026 algorithm appears to depress reach on heavily-hashtagged posts.
- **Link.** In the first comment, not the body. LinkedIn depresses reach on posts with external links in the body. A comment-link gets most of the benefit.

### Timing

- **Day.** Tuesday, Wednesday, Thursday. LinkedIn activity peaks mid-week.
- **Hour.** 7:00 AM to 9:00 AM Pacific (10:00 AM to 12:00 PM Eastern). Weekday morning is prime.

### Engagement

- Respond to every comment.
- Ask questions in replies; LinkedIn rewards thread depth.
- Tag 3 to 5 specific people who would care (not a shotgun blast; specific people who will genuinely engage).

### LinkedIn have-nots

- Press-release voice ("We are thrilled to announce...").
- Company-page post without founder voice.
- External link in the body (reach penalty).
- Weekend posting.
- Over 5 hashtags.

## 6. Indie Hackers

The milestone format is the native post. Revenue or user numbers required for authenticity.

### Milestone format

- **Title.** "Launched [Product] on Product Hunt today. Here are the numbers." Or similar.
- **Body.** Specific numbers: signups, PH placement, revenue if applicable. Specific learnings. What the founder would do differently.
- **Link.** To the product.
- **Engagement.** Answer every comment. IH is a small, high-quality community; every commenter is a potential user or collaborator.

### Timing

- Any day. IH is slower-paced than HN or X.

## 7. dev.to

Tutorial-shaped launch posts for developer tools.

### Format

- Not a pitch. A technical write-up that happens to mention the product.
- "How we built X" or "What we learned shipping Y" formats.
- Code samples, architecture diagrams, real lessons learned.
- Product link at the end, not the top.

### Timing

- Any weekday. dev.to traffic is steadier than X or HN.

## 8. Channel selection matrix

Not every product launches on every channel. Default stacks:

| Product type | Primary channels | Secondary |
|---|---|---|
| **Indie SaaS (B2B, self-serve)** | PH, Show HN, X thread, LinkedIn, IH milestone | /r/SideProject, /r/SaaS, dev.to |
| **Developer tool / infra** | Show HN, X thread, dev.to, PH | /r/devops, /r/programming, IH |
| **Consumer product** | X thread, TikTok/Instagram, Reddit niche subs | PH (secondary) |
| **B2B enterprise** | LinkedIn, niche industry forums, direct sales outreach | PH (optional), niche newsletters |
| **Open source tool** | Show HN, dev.to, GitHub Trending | PH, /r/programming |

## 9. The amplification calendar

Every channel needs a post-plan with all seven fields (venue, timing, title, body, hunter/submitter, amplification, response). Templates in `.launch-ready/templates/channel-post-plan.md`. See SKILL.md Step 8 for the full field list.

## 10. Research pass references

For PH 2025 algorithm analysis, Awesome Directories and Flowjam. For HN title patterns and submitter quality, Aidlab's postmortem. For Reddit 9:1 rule, subreddit-specific FAQs. For X thread structure, Pieter Levels' and Marc Lou's published playbooks. Citations in `RESEARCH-2026-04.md` sections 10 and 11.
