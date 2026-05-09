# Waitlist and email (Step 7)

A waitlist that captures emails with no nurture sequence is a paper waitlist. The skill refuses it.

This reference covers the tool landscape, the double-opt-in discipline, the pre-launch sequence, the launch-day drop, the post-launch sequence, and domain-authentication deliverability requirements.

## 1. Tool landscape (2026)

The waitlist / launch-email tool market is dense. The right tool for a launch depends on: list size expected, whether the founder writes prose or code, whether broadcasts plus sequences plus transactional are all needed, and budget.

| Tool | Best for | Free tier | API-first? | Double opt-in | Automation / sequences |
|---|---|---|---|---|---|
| **Kit** (formerly ConvertKit) | Creator-first; newsletter plus product launches | Up to 10,000 subscribers | Yes, strong API | Yes (optional) | Visual sequence builder |
| **Loops** | Product-led SaaS; broadcasts plus transactional | 1,000 subs, 2,000 emails/mo | Yes, strong API | Yes | Loops / sequence builder |
| **Resend Broadcasts** | Developer-first; broadcasts plus transactional; React Email | 3,000 emails/mo | Yes | Partial; confirmation email via template | Limited sequences (2026) |
| **Plunk** | Open-source, self-host option | Generous | Yes | Yes | Basic sequences |
| **Beehiiv** | Newsletter-heavy launches; monetization-focused | 2,500 subs | Limited API | Yes | Growth-tier automations |
| **EmailOctopus** | Budget list sending; simple broadcasts | 2,500 subs, 10k emails/mo | Yes | Yes | Basic sequences |
| **Buttondown** | Minimalist newsletter plus API | 100 subs free; cheap paid | Yes, strong API | Yes | Basic sequences |
| **MailerLite** | SMB-friendly; landing pages plus email | 1,000 subs | Yes | Yes | Sequence builder |
| **Mailchimp** | Legacy; full-featured | 500 subs, 1,000 emails/mo | Yes | Yes | Journey builder |
| **Substack** | Content-first products; newsletter-native | Unlimited; revenue share | No | Yes | Minimal sequences |

Anti-recommendation:

- **Gmail / Outlook direct sending for launch-day drops.** 500-recipient daily caps, no deliverability management, trivially flagged as spam. Only acceptable for a list under 50 addresses.
- **A self-rolled SMTP from a DigitalOcean droplet.** Deliverability to Gmail and Outlook will fail within minutes.
- **Zapier chaining three tools to send one email.** The indirection breaks at the worst moment.

### Selecting

- **Under 1,000 subs, product-led SaaS:** Loops or Kit.
- **Under 1,000 subs, developer tool:** Resend Broadcasts or Buttondown.
- **Under 1,000 subs, content-heavy:** Beehiiv or Substack.
- **Over 1,000 subs with revenue already:** Kit or Beehiiv.
- **Self-host requirement:** Plunk.

Record the choice in `stack-ready/DECISION.md` if stack-ready is in use; otherwise in `.launch-ready/STATE.md`.

## 2. Double opt-in

A double opt-in waitlist means the subscriber confirms by clicking a link in a first email before they are added to the active list.

### Why it matters

Deliverability (not legal): lists without double opt-in accumulate typos (`goohle.com`), spam traps, and fake addresses that tank the sender's domain reputation. The measurable effect: Beehiiv reports 35.7% average open rate for double-opted-in lists versus 27.4% for single-opted-in, and a measurable reduction in spam-folder placement. The long-term cost of a single-opted-in list is deliverability collapse two to six months in.

Legal (nuance): the common claim that double opt-in is "legally required in the EU" is not quite right. GDPR requires consent, not specifically double opt-in; most EU jurisdictions accept single opt-in with clear consent language. Germany and Austria are the notable exceptions where case law has set double opt-in as effectively required. CAN-SPAM (US) and CASL (Canada) do not require double opt-in. Double opt-in is a deliverability practice, not a universal legal requirement.

launch-ready enforces double opt-in regardless of legal jurisdiction because the deliverability gain matters on launch day.

### The two emails

**Confirmation email (triggers on form submit):**

- Subject line specific, not "Confirm your email." Example: "One click to join the Runbook waitlist."
- Body one paragraph. Names the founder. Sets expectation for the next touch. Single CTA button (confirm).
- No marketing content before confirmation. Legally ambiguous and tonally wrong.
- Sent instantly (under 30 seconds from form submit). Delays cause abandonment.

**Welcome email (triggers on confirmation click):**

- Subject line names the product and a specific benefit. "Welcome to the Runbook waitlist. Here is when you'll hear from me next."
- Body one paragraph plus a small list. Names the founder, the rough launch date, one concrete thing the subscriber will get at launch (early access, a discount, a private build, a founder onboarding call, a named benefit).
- Not a newsletter signup. Not "thanks for your interest." The welcome email is the first touch of the real sequence.
- Sent within 5 minutes of confirmation click.

## 3. The pre-launch sequence

Between confirmation and launch day, two to four emails. Each has a specific purpose; a drip of "we are almost there" emails with no content fails.

Sequence pattern (adjust cadence to launch timeline):

### Email 1: Welcome (immediate after confirmation)

Covered above.

### Email 2: Behind-the-scenes (T-minus 2 weeks)

Specific design decision, specific technical constraint, specific thing the founder wrestled with. Builds trust. Sets up the "I am a real person building a real thing" frame.

Example: "Why we killed the Slack bot."

Body: a paragraph or two on a decision the team made. One image or screenshot. Close with a question back to the list ("would you use X if it shipped at Y price?"). Keep the list warm; solicit opinions.

### Email 3: The launch date (T-minus 1 week)

Announce the exact date and time. "Tuesday, May 14, 12:01 AM Pacific." Name the channels ("we will be on Product Hunt, Show HN, and Twitter"). Ask explicitly for one thing ("if you are on Product Hunt, please upvote" or "the launch-day email will ship at 11am Pacific with a special offer just for this list").

Set expectation for the launch-day drop so it does not arrive as a surprise.

### Email 4 (optional): The teaser (T-minus 48 hours)

A screenshot or a short demo clip. "Here is the thing you are waiting for." One sentence of anticipation.

Skip if the sequence is already three emails; four emails in two weeks risks burnout.

## 4. The launch-day drop

The email that goes out at the launch hour. Timed to be the first notification the list gets about the launch going live.

Contents:

- **Subject line.** Specific. "Runbook is live. Here is your early-access link." Not "We launched!" Not "Product Hunt today!"
- **Greeting.** "Hi [name]," if the list is personalized; "Hi," if not. Do not fake personalization with a merge tag that renders empty.
- **First paragraph.** "Runbook is live. [One sentence of the positioning]." The hero sentence from the landing page.
- **The CTA.** One primary link. Goes to the waitlist's exclusive URL (if there is one) or to the landing page with a UTM parameter that attributes the signup to the email drop.
- **The ask.** One specific amplification ask. "If you use Product Hunt, here is our link" with a direct PH URL. Not "please share." Specific asks convert 5-10x better than generic ones.
- **A postscript.** Short. Names the founder. Invites a direct reply. "Reply to this email with any feedback; I read every one."

Timing:

- If the launch is at 12:01 AM PT (Product Hunt canonical), the email does NOT go out at 12:01 AM. Send at 11:00 AM PT. The PH momentum is built in the early hours by the amplification list; the email list is a second wave that extends the launch into the full day.
- If the launch is Show HN dominant (7:00 AM PT), the email can go out at 7:30 to 8:00 AM PT, after the HN post has been validated as live and not flagged.

UTM on every link:

- `utm_source=email_launch`
- `utm_medium=email`
- `utm_campaign=launch_YYYY_MM`
- `utm_content=launch_day_drop`

## 5. The post-launch sequence (D+1 through D+7)

Three emails minimum. Converts launch-day curiosity into sustained attention.

### D+1: Thank-you and what's next

Subject: "Thank you. Here is what happened." Specific numbers if impressive ("we hit #3 on Product Hunt" or "350 of you signed up in the first 12 hours"); a general "thank you" if not.

Body: acknowledges the launch moment, names one specific surprise ("the biggest learning: everyone wants integration with Linear"), previews the next week. Do not ask for anything in this email; it is a thank-you.

### D+3: First learning

Subject: "What we learned on launch day." Pick one specific insight. One user quote. One concrete next step.

Body: two to three short paragraphs. Names a specific user and their specific feedback (with permission). Shares the team's response. This is the "we are listening" signal that converts lukewarm signups into engaged users.

### D+7: What shipped this week

Subject: "One week in. Here is what shipped." Specific shipped items, even small ones. Closes the launch week narrative.

Body: a short bulleted list of shipped changes, fixes, and decisions. Names the founder. One sentence of what is next.

## 6. Form conversion discipline

The waitlist form on the landing page.

- **Two fields maximum.** Email required. Optional second field: "what are you building" (for B2B dev tools), "team size" (for team products), or nothing. Every additional field drops conversion measurably; a single email field converts highest.
- **GDPR consent checkbox if targeting EU/UK users.** Unchecked by default (explicit opt-in). The checkbox text says what the subscriber will get. "Email me about the Runbook launch and early access" beats "I agree to receive communications."
- **Submit button text.** Specific. "Reserve my early-access spot" beats "Submit." "Join the waitlist" beats "Subscribe."
- **Inline thank-you state after submit.** Not a full page redirect (kills conversion tracking). Names the confirmation email. Tells the subscriber to check their spam folder if they do not see it.
- **Error states work.** Invalid email format shows a clear error. Duplicate submission shows "you are already on the list." Network error shows "something went wrong; try again" with a retry.

## 7. Deliverability and domain authentication

Launch-day emails land in spam for a significant fraction of the list if the sending domain is not authenticated. The three DNS records:

### SPF (Sender Policy Framework)

TXT record on the root domain or the sending subdomain.

```
v=spf1 include:_spf.google.com include:spf.resend.com ~all
```

Adapted to whichever services send email for the domain. The `~all` at the end is soft-fail; `-all` is hard-fail (stricter; use once everything is known working).

### DKIM (DomainKeys Identified Mail)

Provider-specific. Each email-sending provider (Kit, Loops, Resend, etc.) gives a DKIM key to add as a DNS TXT record.

Validate via `dig TXT selector._domainkey.domain.com`.

### DMARC (Domain-based Message Authentication)

TXT record at `_dmarc.domain.com`.

Minimal launch configuration:

```
v=DMARC1; p=none; rua=mailto:dmarc@domain.com
```

`p=none` is report-only (safe for launch). After launch, tighten to `p=quarantine` and eventually `p=reject` once deliverability is known good.

### Validation

- **mail-tester.com.** Send a test email to the address mail-tester gives; it reports the spam score. Launch-day requirement: 9.0 or higher out of 10.
- **Google Postmaster Tools.** Shows deliverability data for Gmail specifically once the domain has sent enough volume.
- **MXToolbox SPF/DKIM/DMARC check.** Validates the DNS records.

## 8. Sending volume and warm-up

A brand-new sending domain sending 1,000 emails on launch day looks like a spam botnet. The pre-launch sequence (Section 3) doubles as warm-up: low-volume sends over two to four weeks establish sending reputation.

- **Week T-minus 4:** send to confirmed subscribers only; volume under 100 emails per day.
- **Week T-minus 2:** ramp to 500 per day if list supports it.
- **Week T-minus 1:** ramp to 2,000 per day if list supports it.
- **Launch day:** whatever the list actually is.

Providers (Kit, Loops, Beehiiv) manage warm-up internally if the domain is on their shared IP pool. Dedicated IPs require manual warm-up; only choose dedicated IPs if list exceeds 50,000 subs.

## 9. The paper-waitlist refusal

The skill refuses to accept a waitlist configuration that satisfies any of these:

- No double opt-in configured.
- No confirmation email drafted (the immediate post-submit email).
- No welcome email drafted (post-confirmation first touch).
- No pre-launch sequence drafted (at least one email between welcome and launch).
- No launch-day drop scheduled in the ESP.
- No post-launch sequence drafted (at least D+1 and D+7).
- SPF or DKIM or DMARC failing on the sending domain.

Any one of these makes the waitlist a paper waitlist. The form works; the funnel does not.

## 10. Legal boilerplate (one paragraph, not exhaustive)

- **CAN-SPAM (US).** Requires a physical mailing address, a working unsubscribe, a truthful subject line. Double opt-in is not required.
- **GDPR (EU/UK).** Requires consent; single opt-in acceptable in most jurisdictions if consent language is clear.
- **CASL (Canada).** Requires express consent, a working unsubscribe, sender identification. Stricter on consent than CAN-SPAM.

launch-ready does not replace a legal review. It flags the requirement to add: privacy policy link in the waitlist form, unsubscribe link in every email, physical address in the email footer.

## 11. Research pass references

For the double-opt-in deliverability data, Beehiiv's study; for open-rate baselines, Kit's and Mailchimp's benchmark reports; for the EU/US/CA legal nuance, the explicit regulation texts. Citations in `RESEARCH-2026-04.md` sections 8 and 9.
