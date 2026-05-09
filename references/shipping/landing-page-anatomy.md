# Landing page anatomy (Steps 2 and 4)

Five canonical sections in order. Visual identity tokens. The aesthetic test. Anti-patterns that signal AI-slop.

## 1. The five canonical sections

A launch landing page has five sections. They are in this order; reordering breaks the visitor's reading path.

### Hero

Above the fold on a 1366x768 viewport. Contains, and only contains:

- **Headline.** One sentence. Passed the substitution test. Product-specific.
- **Sub-headline.** One sentence. Adds the differentiator or names the audience. Optional but recommended.
- **Primary CTA.** One action. Button, not a link. Clear verb. Named outcome. "Join the waitlist," "Start free," "See a demo."
- **Social-proof micro-row** (optional). One of: user count ("used by 840 engineers at 120 companies"), three to eight real customer logos (only if actual customers), one pull quote with a real attributed name and company, or a "built by [founder]" line.

What the hero does NOT contain:

- Scrolling carousel of anything.
- Auto-playing video. (A click-to-play product demo is acceptable below the fold.)
- Three-CTA choose-your-adventure ("sign up," "demo," "pricing," "docs").
- Hero illustration clusters: three abstract figures, pastel icon blobs, gradient circles, a laptop with a generic dashboard on it.
- Paragraph-length copy (three or more sentences). The hero is a door, not a document.

### Social proof

Single row, single purpose. Options (pick one or two; do not stack all three):

- **Customer logos.** Three to eight, real, actually using the product. Grayscale or monochrome to avoid visual chaos. Link each to a case study or a quote.
- **User / team count with a date.** "Used by 840 engineers at 120 companies" with the date ("as of April 2026"). Numbers without dates imply stale claims.
- **Named pull quote.** One. Real person, real company, real title. Not "John Smith, CEO." Not an AI-generated testimonial. If no real testimonial exists, drop the section entirely.

If none of the three are available for a pre-launch product, this section becomes a single line: "Built by [named founder] after [specific frustration]." This is the founder's credibility and the origin story in one sentence. It is honest; it builds trust.

Do not fabricate logos. Do not use generic "as seen in" badges for publications that have not actually covered the product. The TechCrunch logo on a landing page that has never been mentioned in TechCrunch is fraud-adjacent; it will be caught, and when it is, the entire launch's credibility collapses.

### Feature grid

Three to six tiles. Not seven. Not eight. Not twelve.

Each tile:

- **Icon.** From the installed icon library (Lucide, Heroicons, Phosphor, Tabler, Radix). 24 to 48 pixels. One per tile. Consistent weight.
- **Headline.** Substitution-test-passing. A capability specific to this product, not a category label. "Runs the eight-step migration as one command" beats "Migrations." "Auto-updates the on-call rotation in every pinned Slack thread" beats "Integrations."
- **Description.** One sentence. Names the mechanism. "Reads the PagerDuty schedule every 60 seconds and rewrites the pinned message in the declared Slack channels."

What the feature grid does NOT contain:

- More than six tiles.
- Category labels as headlines. "Fast," "Secure," "Scalable," "Collaborative," "Modern" all fail.
- "Learn more" links that go nowhere.
- Icons drawn from the same gradient-blob set that every Tailwind starter ships with.
- Emojis as icons. (The global emoji rule applies; launch-ready enforces.)

If more than six features matter, the landing page is trying to do the job of the product documentation. Move the long list to `/features` or the docs; keep the landing page grid at six or fewer.

### Pricing (if applicable)

Visible above the scroll, not buried five sections down. Real numbers.

- **Max three tiers.** Free, Pro, Enterprise. Or Starter, Team, Business. Three; not five.
- **Each tier names the one audience it serves.** "For solo founders." "For teams of 2 to 20." "For companies with a security review." If a tier cannot name its audience in one line, it does not yet exist.
- **Real numbers.** "$19 / month" beats "Contact us" on a self-serve product. "Contact us" is allowed for the enterprise tier where the pricing genuinely depends on contract shape.
- **No anchor-price psychological tricks.** A "most popular" badge on the middle tier is fine; a crossed-out $199 next to the real $19 is a tell that the brand is not confident.

Pricing display is a Step 2 discipline only. The underlying pricing is a business decision; launch-ready does not own what the numbers should be.

If the product does not charge at launch (free tier only, not-yet-priced), replace the pricing section with a one-line honest statement: "Free during beta. Pricing will arrive with v1.0." Then put the primary CTA below it again.

### CTA (closing)

Repeat the primary CTA at the bottom of the landing page. Same verb as the hero CTA. Different visual treatment (larger, centered, more whitespace). This is the visitor who scrolled through the whole page and is ready.

Optional: a secondary CTA next to the primary one. "Book a demo" next to "Start free." Two tops; three is a diffusion.

## 2. The above-the-fold discipline

1366x768 is the laptop fold. 390x844 is the iPhone fold. A launch landing page's hero must work on both.

Test procedure:

- Load the landing page at 1366x768 (set window, zoom 100%). Everything below the hero section is below the fold.
- Load the landing page at 390x844 (iOS Safari sim or real device). Everything below the hero section is below the fold.
- On both, the hero must contain: headline, sub-headline (optional), primary CTA. Nothing else.

Common above-the-fold failures:

- **Mobile header too tall.** A 120px sticky header on mobile leaves 724px for the hero, and the CTA pushes below.
- **Sub-hero too long.** A three-sentence sub-hero wraps to six lines on mobile and pushes the CTA below.
- **CTA button below a hero image.** On mobile the image consumes 60% of the viewport and the CTA lands off-screen.

## 3. Visual identity tokens

launch-ready does not redecide the visual identity; it consumes `production-ready`'s brand tokens if present. If absent, launch-ready produces a minimum viable identity:

- **One brand color.** Not three. Saturated enough to survive on the OG card thumbnail. CSS variable `--color-brand`. Contrast ratio against white background must pass WCAG AA for body text (4.5:1) if the brand color is used for any body text; headline-only use relaxes to AA-large (3:1).
- **Two supporting grays.** One for body text (approximately #374151 or similar), one for muted UI (approximately #9CA3AF). CSS variables `--color-text` and `--color-muted`.
- **One typeface for headlines, one for body.** Can be the same. Default pair: Inter for both. If differentiation matters, use a serif for headlines (Source Serif, Instrument Serif) and Inter for body. Webfont loading: use `font-display: swap` to avoid invisible text during load; use a system font fallback stack so the page is readable before the webfont arrives.
- **Icon library chosen.** Lucide, Heroicons, Phosphor, Tabler, Radix Icons. One, not a mix. No emojis. No gradient-blob icon sets from Tailwind starter templates.
- **One hero image or pattern, or none.** If the hero includes an illustration, it is either (a) a real screenshot of the product or (b) a custom illustration commissioned or produced by the team that survives the substitution test. Stock illustrations of abstract people pointing at laptops are banned.

## 4. The aesthetic test

Single-person, one-question test. Runs at Tier 1 and again at Tier 2.

- Take a screenshot of the landing page hero at 1366x768.
- Show it to a person who has never seen the product, for ten seconds.
- Remove the screenshot.
- Ask: "What does this product do?"

Scoring:

- If the answer is specific and correct ("something about on-call handoffs for engineering teams"), pass.
- If the answer is generic ("some kind of SaaS tool," "a project management thing"), fail. The hero is not doing its job; return to Step 1 and Step 3.
- If the answer is specific and wrong, fail. The hero is miscommunicating; return to Step 1.

Run the test on at least one naive viewer before Tier 1 is declared. Run again on a different viewer before Tier 2 is declared.

## 5. Anti-patterns (the shadcn-default set)

The aesthetic signature of AI-generated landing pages in 2025-2026. Each is individually fine; all of them together read as "template." The skill refuses a page that stacks three or more without specific justification.

- **Gradient hero background.** Radial gradient from upper-left, brand color bleeding into purple or blue.
- **Pastel icon blobs.** Rounded squares with pastel gradient fills containing a line-weight icon.
- **Three-column feature grid.** Not two, not four; always three.
- **Inter typography at three sizes.** 36/24/16 or 48/24/16. No typographic hierarchy beyond the three.
- **Testimonial carousel.** Auto-rotating quotes with a dot-nav.
- **"Trusted by" logo row without real customers.** Generic industry-logo placeholders.
- **Gradient CTA button.** Brand color to lighter-brand-color, 45-degree angle.
- **Emoji as section markers.** Rocket, lightbulb, chart. Banned globally; specifically banned here.
- **Pricing tier "most popular" shadow ring.** Standard Tailwind "most popular" highlight.
- **Faux screenshots of abstract dashboards.** A fake product screenshot that does not match the real product UI.
- **"Get started in 3 easy steps" section** with three circled numbers and icons.
- **Gradient footer.** Repeat of the hero gradient, 50% opacity.
- **"We are hiring" section** on a pre-launch page with no hiring pipeline.

One or two of these can appear for specific reasons (a gradient hero with a specific brand reason, a three-column feature grid because the product really has three independent features). Three or more stacked together is AI-slop. The skill flags and recommends removing the weakest justifications.

## 6. Hero copy patterns that work

From Julian Shapiro's landing-page guide, Harry Dry's Marketing Examples catalog, and Swipe Files' running commentary:

- **Audience-first.** "For [specific role] who [specific situation]." "For indie founders who launched on PH and got 15 upvotes."
- **Replacement-framed.** "Replace [current workaround] with [specific new thing]." "Replace the weekly on-call spreadsheet with a handoff doc that updates itself."
- **Outcome-framed.** "So you can [specific outcome]." "So you can sleep through Friday night without missing a page."
- **Anti-villain.** "The [category] that does not [common annoyance]." "The dashboard that does not require you to learn a query language."
- **Named differentiator.** "The only [category] that [specific capability]." "The only on-call tool that reads your existing PagerDuty schedule, not a separate one."

## 7. Sub-hero patterns that work

- **Mechanism reveal.** "Because [specific mechanism]." "Because we read the schedule via the PagerDuty API every 60 seconds."
- **Proof point.** "[Specific metric]." "Reduces handoff time from 45 minutes to three."
- **Founder line.** "I built this after [specific incident]." "I built this after our third Friday-night page in a row dropped a customer."
- **Not-yet disclaimer.** "Free during beta. Launching [month]."

## 8. Pricing display patterns

Even if pricing strategy is out of scope, the display discipline matters. Three tiers; each names the audience; real numbers.

Common pricing anti-patterns:

- **Five tiers including "custom."** Five is too many; the visitor bounces at the decision.
- **Unpriced enterprise tier as the only tier.** If a self-serve product's pricing page says "Contact us" for every tier, the visitor infers B2B enterprise SaaS with six-figure contracts. Most visitors are not that.
- **Yearly-only pricing with hidden monthly.** A "from $19/mo" tag on a yearly-only contract at $228 up front is misleading. The visitor sees $19 and expects monthly; the checkout reveals $228. Trust collapses.
- **"Popular" badge on the tier the founder wants to push.** The "most popular" badge is a real design pattern (Basecamp, Linear, many others use it effectively) but only if the tier is genuinely the most popular choice. Marketing-only "most popular" labels get caught.

## 9. Accessibility and performance

A launch landing page fails quickly if the page is slow or inaccessible.

- **Core Web Vitals in the green.** LCP under 2.5s, CLS under 0.1, INP under 200ms. See `seo-fundamentals.md` for the PageSpeed Insights discipline.
- **Keyboard navigation works.** Tab order reaches the CTA; focus ring is visible.
- **Alt text on all images.** Screen readers reach the social proof and feature icons.
- **Color contrast passes WCAG AA.** Body text 4.5:1 minimum.
- **No autoplay anything.** Videos click-to-play; carousels click-to-advance.

## 10. Research pass references

For hero-specificity research, Julian Shapiro's guide, Harry Dry's examples, and the shadcn-default aesthetic critique citations, see `RESEARCH-2026-04.md` sections 2, 3, and 6.
