# Positioning and copy (Steps 1 and 3)

Positioning is upstream of every surface in the launch. No hero, OG card, email subject, or launch post can outperform weak positioning. This reference covers the substitution test, the four-sentence positioning document, the banned-word audit, and the tone-of-voice frame.

## 1. The substitution test

The skill's load-bearing discipline. Applied sentence by sentence to every user-facing line the launch ships.

### Procedure

1. Isolate the sentence. Hero headline, hero sub-headline, every feature card headline, every feature card description, pricing tier labels, CTA button text, OG card title, OG card description, meta title, meta description, waitlist form headline, waitlist confirmation subject, welcome email subject, launch-day email subject, PH tagline, Show HN title, LinkedIn launch post first line.
2. Substitute. Replace the product's name (or the implicit "we") with the name of a direct competitor. If no direct competitor is named, pick the two most obvious ones in the category.
3. Read. If the resulting sentence is plausible and reads as the competitor's marketing would read, the original fails the substitution test. Rewrite.

### Examples

Fail:

> "Empower your team with AI-powered productivity."
> Substitution: "Empower your team with Notion." "Empower your team with Asana." Both read plausibly. The original is hero-fatigue copy.

> "The modern way to manage your workflow."
> Substitution: "The modern way to manage your Linear." "The modern way to manage your Monday." Plausible. Fails.

Pass:

> "Run the eight-step on-call handoff checklist as one command."
> Substitution: "Run [Competitor]'s eight-step on-call handoff checklist as one command." Only plausible if the competitor in fact ships an eight-step on-call handoff command. Most will not; the sentence is specific.

> "Reduces the median new-hire onboarding from three days to eleven minutes."
> Substitution: "[Competitor] reduces the median new-hire onboarding from three days to eleven minutes." Either they do or they do not; the number makes the claim auditable. Passes.

### What the test catches

- Category-level claims that describe the product type, not the product.
- Feature headlines that use category labels (Fast / Secure / Scalable) rather than specific capabilities.
- Marketing-speak that any SaaS in the decade could have written.
- Hero copy that names a benefit without naming the mechanism.

### What the test misses

- Poor prose quality (clunky sentences that pass the substitution test by being specifically bad).
- Tonal mismatch with the audience (a technical audience reading an aspirational hero).
- Factual errors (a specific claim that is false).

Those are caught by the tone-of-voice frame (Section 3) and by basic proofreading, not by the substitution test.

## 2. The four-sentence positioning document

Adapted from April Dunford's *Obviously Awesome* (2019) competitive-alternative framing, Julian Shapiro's growth landing-page guide (julian.com/guide/growth), and Harry Dry's Marketing Examples specificity principle.

Four sentences. Written, reviewed, and frozen before any landing-page copy is drafted.

### Sentence 1: Who is this for

One sentence. Must name a role or a context specific enough that a competitor cannot plausibly use the same sentence. Three-sentence rubric:

- Name the role, not the company size. "Three-person engineering team" beats "small team."
- Name the situation, not the industry. "First engineering hire quits on a Friday" beats "tech startups."
- Name the constraint, not the aspiration. "Runway is eleven months" beats "wants to move fast."

Stack the three: "For three-person engineering teams whose first hire quits on a Friday and whose runway is eleven months."

### Sentence 2: What it replaces

One sentence. The existing workaround the audience is using today. April Dunford's framing: the competitive alternative is usually not another product; it is a spreadsheet, a Slack channel, a cron job, a habit. Examples:

- "A Notion page and a Slack channel."
- "Five rows in a Google Sheet and a monthly team meeting."
- "A cron job and a prayer."
- "The founder's personal email forwarding rules."

The sentence should be concrete enough that the reader thinks "yes, that is literally what we do." Replacement-framed positioning outperforms feature-framed positioning in every test Julian Shapiro, Harry Dry, and Marketing Examples have published; the reader's brain anchors on the thing they already know and compares.

### Sentence 3: What it does differently

One sentence. The thing the replacement cannot do. Must be concrete.

- "Runs the eight-step checklist as one command."
- "Updates every Slack thread automatically when the rotation changes."
- "Catches the schema drift before the migration breaks prod."

Vagueness tells:

- "Faster" without a number.
- "Better" without a dimension.
- "More reliable" without a baseline.
- "Easier" without a comparison.

If the sentence cannot survive "faster than what, by how much," rewrite.

### Sentence 4: The differentiator test

For Sentence 3, write the competitor's rebuttal. The competitor is a real named competitor or the implied alternative (the spreadsheet, the manual process).

If the rebuttal is "we do that too," the sentence is not a differentiator. Rewrite Sentence 3 until the rebuttal becomes one of:

- "We do not do that."
- "We do the opposite."
- "We do that, but it costs five times as much" or "it takes five times longer" or "it requires an enterprise contract."

The final form of Sentence 4 records both the claim and the rebuttal. It is the proof that Sentence 3 is not lazy.

### Storage

The four sentences go in `.launch-ready/POSITIONING.md`. They are quoted (not re-written) every time the landing page, OG card, or launch post is drafted. If the positioning changes, update the document and flag every downstream artifact for re-review.

## 3. Tone of voice

Three adjectives. Three anti-adjectives. One short paragraph connecting them.

Examples:

> Tone: direct, technical, quietly funny. Anti-tone: corporate, breathless, aspirational. The voice sounds like a senior engineer explaining an internal tool to a new hire at lunch, not like a keynote speaker pitching at a conference.

> Tone: warm, plain, specific. Anti-tone: clever, ironic, hedged. The voice sounds like a parent writing a letter, not a brand.

The tone paragraph is the reference every subsequent copy draft is checked against. "Does this hero sound like a senior engineer at lunch, or does it sound like a keynote" is a shorter check than re-reading the full brand guide.

## 4. The banned-word audit

The AI-slop signature. This list is the fingerprint of Claude / Cursor / Lovable / v0 / Bolt / Framer AI output circa 2024 to 2026. The list is versioned; as model behavior changes, new tells emerge and old tells fade. The v1.0.0 list:

| Banned | Why it fails | Replace with |
|---|---|---|
| seamless | Describes the aspiration, not the mechanism. Used in every SaaS landing page since 2012. | The specific transition. "Without switching tabs," "in one step," name the integration. |
| powerful | Says nothing measurable. | The specific capability and its scale. "Queries Postgres and S3 in the same request." |
| revolutionary | Self-awarding superlative. | The specific new thing. "First tool to run migrations inside the backfill transaction." |
| effortless | Effort is measurable; use the number. | "Two fewer clicks than the incumbent workflow." "Eight fewer keystrokes." |
| intelligent | Meaningless adjective for "uses software." | The specific technique. "Uses the customer's prior responses to pre-fill the form." |
| cutting-edge | Dated by the time it is published. | The version or year. "Built on the OpenAI December 2025 completions API." |
| game-changing | Self-congratulatory. | The metric that changed. "Reduces median onboarding from three days to eleven minutes." |
| unlock | Metaphor that obscures the action. | The thing enabled. "Gives every engineer their own staging environment." |
| supercharge | Cliche. | The before and after. "One prompt replaces a forty-line YAML config." |
| elevate | Brand-speak. | The specific upgrade. "Turns the weekly ops review into a one-click dashboard." |
| streamline | Euphemism for "remove." | The removal. "Removes the approval step entirely." |
| empower | Hollow. | The action enabled. "Non-engineers ship changes without filing a ticket." |
| robust | Means "we hope it does not crash." | The threshold. "Survives the 50K QPS the prior system collapsed at." |
| solution (as the product) | Consultant-speak. | Name the product or the action. |
| best-in-class, leading, enterprise-grade, world-class | Unwinnable claims without proof. | Drop entirely, or replace with a number (market share, rank, customer count). |
| cutting-edge technology | Redundant adjective plus nonspecific noun. | Drop the phrase entirely. |
| drive value, drive results, drive outcomes | Business-speak for "useful." | Name the specific result. |
| AI-powered (for non-AI products) | 2024 tell. | Drop unless the product is an AI product AND the AI is the differentiator. |

### Running the audit

- Grep the landing-page HTML source for each banned word (case-insensitive).
- Grep the rendered text (some frameworks stringify copy in JSON; grep those files too).
- Grep the OG card image's text content (or the input data to the OG generator).
- Grep the meta title, meta description, twitter:title, twitter:description, og:title, og:description.
- Grep the email sequence (confirmation, welcome, pre-launch, launch-day, post-launch).
- Grep the PH tagline, Show HN title draft, LinkedIn post draft, X thread draft.

A zero-hits-above-the-fold audit is the gate; above the fold means the hero, sub-hero, and any visible feature headlines on a 1366x768 viewport.

Below the fold, banned words can survive with a one-line justification. A FAQ that says "our customers often ask if our product is seamless; here is what that means for them" is allowed with review.

### Additional copy rules

- **Active voice, second person.** "You ship faster" beats "Your team will be enabled to ship faster." Exception: the founder-voice first-person line ("I built this after...").
- **Named subjects.** The founder's voice beats the company-we voice in the hero and the sub-hero. "I built this after my on-call rotation broke our launch" beats "Our team is passionate about solving on-call chaos."
- **Concrete over abstract.** Numbers, dates, names, before/after contrasts. If a sentence would survive unchanged in a pitch deck for a different product, rewrite.
- **Sentence length variety.** Hero is one short sentence. Sub-hero is one medium sentence. Feature descriptions are one short sentence each. Pricing tier descriptions are one short sentence each. Long paragraphs belong in the blog, not the landing page.
- **No weasel qualifiers in the hero.** "Often," "usually," "typically," "can," "may." The hero claims; the FAQ qualifies.

## 5. The "who else could write this sentence" test

A lighter variant of the substitution test, useful when drafting: as each sentence is written, ask "who else could have written this sentence." If the answer is "any SaaS founder," the sentence is not specific enough. If the answer is "the six founders who have built something in this exact niche," the sentence is specific enough.

The test is self-administered during drafting; the substitution test is the audit. Both serve the same discipline; one prevents, one catches.

## 6. The founder voice and the company voice

A running disagreement in modern SaaS marketing: founder-voice versus company-voice. The literature (Harry Dry, Arvid Kahl, Patrick Campbell) is nearly unanimous for launch-stage products: founder-voice wins.

Founder-voice traits:

- First-person singular ("I," "me") in the hero story and the about section.
- Specific origin ("I built this after the third Friday-night page").
- Named and pictured founder.
- Direct contact path (founder's email, not `hello@` aliases).
- Personal email from the founder as the first post-signup touch.

Company-voice traits:

- First-person plural ("we") everywhere.
- Abstract mission statements.
- Unnamed or stock-photo people.
- Generic aliases (support@, hello@, team@).
- Templated email from the company.

For early-stage launches, every founder-voice trait beats every company-voice trait. The exception is enterprise sales where the buyer expects a company behind the product; even then, the founder's personal pitch at the top of the relationship converts better.

launch-ready enforces founder-voice on the landing page hero and the launch-day email. Below that, company-voice is acceptable.

## 7. Substitution-test edge cases

### "But our product IS seamless"

If the product genuinely is seamless (by some specific definition), the word is still banned from the hero. Write the specific definition instead. "Runs without configuration after `brew install`." The reader gets the claim and the proof in one sentence; the word "seamless" provides neither.

### "But our competitors really ARE called X, Y, Z"

Name them. Direct naming is rare in SaaS marketing because legal and brand teams are risk-averse, but it is effective. Linear did this effectively against Jira in their early launches. If the legal team blocks the naming, the substitution test becomes a stricter discipline because the reader does not know what the product is differentiating against.

### "The product does many things; one sentence cannot capture it"

Pick the most important one. The hero is not a feature list; it is the door. The product can say more on the feature page, the docs, and the pricing page. Products that ship a hero with five claims stacked together read as indecisive; one strong claim outperforms.

### "Our audience knows the category; we do not need to explain"

The audience who knows the category is the launch-day audience, not the pre-launch audience. PH, HN, Reddit, and Twitter bring traffic from outside the category. A hero that assumes category knowledge loses them in three seconds.

## 8. Research pass references

For the full citations behind the substitution test, April Dunford's framework, the banned-word list derivation, and the founder-voice literature, see `RESEARCH-2026-04.md` sections 3, 4, and 5.
