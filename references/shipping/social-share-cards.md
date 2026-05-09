# Social share cards (Step 6)

An Open Graph card that renders wrong on launch day is a launch asset that was never tested. The skill refuses to accept an OG card that has not been previewed on five channels. This reference covers the preview rule, the image spec, the cache TTL traps, and the generation-tool landscape.

## 1. The five-channel preview rule

Before any link to the landing page ships, the OG card is previewed on each of:

1. **X / Twitter.** `twitter:card` at `summary_large_image`; 1200x630 renders. Twitter truncates titles and descriptions; preview by posting to a test account and reading what the card looks like on a timeline.
2. **LinkedIn.** 1200x627. LinkedIn Post Inspector (www.linkedin.com/post-inspector) is the pre-launch clearance. LinkedIn caches the preview for at least 7 days; a wrong preview on launch day is a wrong preview for the entire launch window.
3. **Slack.** Slack unfurls via the Slack bot. Preview by pasting the URL into a test workspace channel. Slack's preview uses `og:title`, `og:description`, `og:image`; it truncates titles aggressively.
4. **iMessage.** macOS Messages and iOS Messages. Preview by sending the URL to yourself. iMessage uses a narrow preview card; images are scaled down significantly.
5. **Discord.** Discord embeds via the Discord bot. Preview by pasting the URL into a test server channel. Discord uses a full-width embed by default; the image renders large.

Record the five previews as screenshots in `.launch-ready/assets/og-previews/`. Date the screenshots. The screenshots are the audit trail; launch-ready refuses to accept "I previewed it and it looked fine" without evidence.

### Why five and not more

Facebook Sharing Debugger (developers.facebook.com/tools/debug) is useful if Facebook is a target channel, but Facebook has diminished as a launch channel for most indie products; the debugger is optional.

WhatsApp uses the Facebook Sharing logic; previewing on iMessage and Facebook covers WhatsApp behavior for most practical purposes.

Reddit uses a server-side fetcher; the preview matches Slack's logic closely enough that a clean Slack preview usually implies a clean Reddit preview.

Email clients (Gmail, Outlook) do not render OG previews; that is what the inline image in the launch email is for.

## 2. The cache TTL traps

Social platforms cache OG metadata aggressively to avoid re-fetching on every paste. Cache TTLs as of 2026:

- **LinkedIn:** at least 7 days. Post Inspector can force a re-fetch on one URL, but if a link has been posted before the re-fetch, the old card propagates.
- **Facebook / Meta:** at least 7 days. Facebook Sharing Debugger forces a re-scrape.
- **Twitter / X:** approximately 7 days. No public debugger after the Card Validator was deprecated.
- **Slack:** approximately 1 hour (empirical). Slack re-fetches more aggressively than LinkedIn; less critical.
- **Discord:** minutes to hours (empirical). Re-fetches on most pastes.
- **iMessage:** fetches once per URL per device; does not re-fetch. A wrong preview persists.

The launch implication: the OG card shipped on launch day is the OG card for the launch week. Post-launch fixes do not propagate to users who have already seen the card. The pre-launch Post Inspector clearance is the only prevention.

## 3. The OG image spec

Native resolution, exactly. No off-by-one.

- **1200 x 630 pixels.** 1.91:1 aspect ratio. This is what X, LinkedIn, Facebook, Slack, Discord, iMessage all expect.
- **File size under 300KB.** Ideally 50 to 150KB. Large OG images fail to render on slow unfurl timeouts (LinkedIn and Slack both have timeouts around 5 to 10 seconds).
- **PNG or JPEG.** PNG for pages with sharp text and solid colors; JPEG with quality 85 to 90 for photographic content. SVG is NOT supported by most unfurlers.
- **Legible at 600x315.** When the card renders at half size (happens on LinkedIn compact preview, Slack mobile, iMessage), text must still be readable. Minimum font size at 1200x630: 32pt for body, 48pt for headline.
- **Safe zone of 40px on every edge.** Channels crop differently; do not put critical content in the outer band.
- **Brand color present.** The one brand color from the visual identity tokens. Not five gradient stops.
- **Product name legible.** Include the word, not just the logo. Some channels render the image only, not the title text.
- **One-line value proposition.** Six to ten words. Same substitution-test rules as the hero.

## 4. OG image content patterns

Pick one pattern; do not combine.

### Pattern A: Logo and tagline

- Brand-color background or white.
- Logo centered or top-left.
- Product name in large type.
- One-line tagline below.
- Founder handle or URL in small type at bottom.

Best for: B2B products where brand recognition matters more than visual flair.

### Pattern B: Screenshot plus framing

- Real product screenshot, cropped and framed.
- Overlay brand color gradient at 20% opacity in one corner.
- Product name and tagline in a text block off to one side.

Best for: products where the interface is distinctive and the screenshot is self-explanatory.

### Pattern C: Bold statement

- Solid brand color or black background.
- One sentence in very large type (80pt+).
- No logo. Product name small at the bottom.

Best for: launches where the positioning is the story; works when the one sentence is the substitution-test-passing hero.

### Pattern D: Founder photo

- Brand-color background.
- Founder photo on one side (real, not stock).
- Pull quote from the founder on the other side.
- Product name and URL at bottom.

Best for: indie launches where the founder is the brand.

Avoid:

- Abstract gradient backgrounds with tiny text.
- Stock illustrations of abstract people pointing at laptops.
- Busy collages of icons, devices, and UI elements.
- Screenshots at full native resolution (looks like a crashed browser window on the card).

## 5. OG image generation tools

Pick one. Do not use three and hope.

### @vercel/og (open-source, JS-driven)

`@vercel/og` (formerly vercel/og-image) runs at the edge via Vercel Functions. JSX-based: you write the OG card as a React component, Vercel renders it to a PNG. Dynamic parameters via URL: `/og?title=Runbook&sub=On-call+handoffs`.

- Free.
- Dynamic per-page OG.
- Self-hosted possible via Satori (the underlying library).
- Best when the site is already on Vercel.

### Tailgraph (SaaS)

Templated OG card designer; free tier with watermark, paid tier without. Hosted rendering; stable URLs.

- Good for non-Next.js projects.
- Templates easier than JSX.
- Free tier constraints usually matter.

### Bannerbear (SaaS)

Templated designer plus API. Paid from the start; targeted at teams doing many OG cards per day.

- API-driven.
- Best when OG cards for blog posts, podcast episodes, etc. need automation.
- Overkill for a single launch OG card.

### Cloudinary (SaaS)

Image-transformation API. Overlay text, crop, reposition. Paid.

- Best when Cloudinary is already in the stack.
- Overkill for most launches.

### OG Image Studio, opengraph.studio, og.dev (various)

Self-serve single-card designers. Export the PNG; drop in as a static file.

- Simplest for a one-off launch card.
- No dynamic rendering; every page gets the same OG.

### Figma export (manual)

Design in Figma at 1200x630; export as PNG.

- Simplest for founders who already design in Figma.
- Manual; no templating.

### Choosing

- **One static OG card for the whole site:** Figma export or OG Image Studio.
- **Per-page OG with dynamic titles:** @vercel/og if on Vercel; Tailgraph if not.
- **Automated OG for many URLs:** Bannerbear or Cloudinary.

## 6. Twitter Card validator status

The public Twitter Card Validator at cards-dev.twitter.com/validator was deprecated in 2023 as part of Twitter's / X's API changes. As of April 2026, the public validator is not reliably available.

Preview alternatives:

- Post the URL to a test X account; read the timeline card.
- Use opengraph.xyz or opengraph.io (free third-party previewers that render the card using the Twitter card meta tags).
- Use metatags.io (shows all card metadata at once).

## 7. Canonical OG URL discipline

The OG URL should be the canonical URL. Do not ship OG tags with `og:url` pointing to a staging domain or to a variant (`www.` when the canonical is non-`www.`). A mismatch causes:

- Inconsistent social shares (different people share the same page with different canonical URLs).
- Cached OG metadata points to the wrong domain; the post-launch redirect chain breaks the cache.

## 8. Dynamic OG for the launch page and the waitlist

Most launch pages ship with one static OG card for the landing page. Two variants are sometimes worth it:

- **Landing page OG:** the primary card; static; generated via Figma export or OG Image Studio.
- **Waitlist confirmation OG:** if the waitlist confirmation page is shareable (some flows encourage users to share "I just joined the waitlist"), a variant OG that says "I joined the Runbook waitlist; you should too" works. @vercel/og handles the dynamic variant cleanly.

Do not ship variant OG cards for every marketing landing page before they matter; premature OG generation is noise.

## 9. The pre-launch preview runbook

Two days before launch:

- Render the final OG card at 1200x630 under 300KB.
- Deploy to a real preview URL (staging.runbook.dev).
- Post the preview URL to a test X account, a test LinkedIn post (delete after verification), a test Slack workspace, send to yourself via iMessage, paste into a test Discord server.
- Screenshot each preview; save to `.launch-ready/assets/og-previews/YYYY-MM-DD/`.
- Run LinkedIn Post Inspector on the real production URL (even if the production page is not yet public; Post Inspector fetches the URL directly).
- If any preview is wrong, fix the OG card or the meta tags and re-preview all five channels. Partial fixes are not acceptable.

The day of launch:

- Re-preview at least X, LinkedIn, and Slack one more time on the real production URL.
- If LinkedIn shows a cached old version (from a pre-launch test), click "Clear cache" in Post Inspector and re-fetch.

## 10. Research pass references

For LinkedIn's cache behavior, see the LinkedIn Post Inspector documentation. For OG metadata spec, see ogp.me. For @vercel/og usage, see vercel.com/docs/functions/og-image-generation. Citations in `RESEARCH-2026-04.md` sections 6 and 7.
