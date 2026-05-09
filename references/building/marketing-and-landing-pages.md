# Marketing and Landing Page Patterns

This file covers the public-facing pages that sell the product — landing pages, pricing, social proof, CTAs, and the performance optimizations that make them convert. This is not dashboard UI. Marketing pages optimize for **clarity, persuasion, and speed** — every element exists to move a visitor toward signup.

The structure here follows the scroll order of a typical SaaS landing page: hero, social proof, features, pricing, FAQ, final CTA, footer.

---

## Hero section

The hero is the most important section on the page. You have **3-5 seconds** to communicate what the product does and why it matters. If the hero fails, nothing below it matters.

### Layout patterns

Pick one. Don't hybridize.

| Pattern | When to use | Layout |
|---|---|---|
| **Text-left, image-right** | Product has a clear UI to show (dashboards, tools) | 2-column grid, 55/45 or 60/40 split |
| **Centered text, image below** | Abstract product, strong headline | Single column, text stacked above screenshot |
| **Full-bleed background** | Visual-first products (design tools, media) | Text overlay on hero image/video |
| **Text-left, demo-right** | Interactive product, want to wow | 2-column, right side is embedded demo |

**The default choice for SaaS dashboards is text-left, image-right.** It's the most proven layout. The product screenshot proves the product exists and gives visitors a mental model.

```css
.hero {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: center;
  max-width: 1280px;
  margin: 0 auto;
  padding: 80px 24px 64px;
}
@media (max-width: 768px) {
  .hero {
    grid-template-columns: 1fr;
    gap: 40px;
    padding: 48px 16px 40px;
    text-align: center;
  }
}
```

### Headline

The headline is the single most impactful element on the page. Rules:

- **Under 8 words / 44 characters.** Forces clarity. "Manage customer data in one place" not "The revolutionary AI-powered customer data management platform for modern enterprises."
- **Benefit-first.** Lead with what the user gets, not what the product is. "Ship 2x faster" not "A CI/CD platform."
- **Specific numbers beat vague claims.** "Save 10 hours/week" beats "Save time." "99.9% uptime" beats "Reliable."
- **No jargon.** If your mom can't understand it, rewrite it.

**Typography:**
- Size: 48-64px (`text-5xl` to `text-6xl`). Mobile: 36-40px.
- Weight: 700-800 (bold to extrabold).
- Line height: 1.1-1.2 (tight).
- Letter spacing: `-0.02em` to `-0.03em` (tighter at large sizes).
- Color: highest contrast text color (pure black or near-black on light bg).

### Subheadline

One sentence expanding the headline. Explains the "how" after the headline's "what."

- Size: 18-20px. Weight: 400 (regular). Color: muted text (`text-muted-foreground`).
- Max width: 560px (prevents unreadable long lines).
- Line height: 1.5.
- Keep to 1-2 lines. If it needs 3 lines, cut words.

### CTA buttons

Two buttons maximum. One primary, one secondary.

| Button | Example copy | Style | Links to |
|---|---|---|---|
| **Primary** | "Start free trial", "Get started free", "Try for free" | Solid bg, large (h-12, px-8, text-base) | Signup page |
| **Secondary** | "See demo", "Watch video", "Book a call" | Ghost or outline, same size | Demo page or video modal |

**CTA copy rules:**
- **Verb + benefit.** "Start free trial" not "Submit" or "Learn more."
- **"Free" converts.** Always mention free trial/free tier if you have one.
- **One primary action.** If you can't decide between "Start trial" and "Book demo", pick one. A/B test it later.

```css
.hero-cta-group {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}
.hero-cta-primary {
  height: 48px;
  padding: 0 32px;
  font-size: 16px;
  font-weight: 600;
  border-radius: 8px;
}
```

### Hero image/video

- **Product screenshot:** Show the actual product, not an illustration. Use a browser frame or device mockup for context. Slight perspective tilt (3-5deg rotateY, 2deg rotateX) adds depth.
- **Video:** Autoplay muted, loop, no controls. Keep under 15 seconds. Use `<video>` tag, not a YouTube embed. Provide poster image for instant render.
- **Dimensions:** Hero image should be at minimum 600px wide. Use `fetchpriority="high"` and `loading="eager"` — this is above the fold, it must load immediately.

---

## Social proof section

Social proof sits immediately below the hero. It answers "who else uses this?" and "can I trust them?"

### Logo bar

Display logos of recognizable customers. This is the single highest-impact social proof element.

- **Count:** 6-8 logos. Fewer than 5 looks thin; more than 10 is clutter.
- **Grayscale.** All logos in grayscale (CSS `filter: grayscale(100%) opacity(0.6)`). Color logos compete with your brand and look messy. Optionally color on hover.
- **Heading:** "Trusted by 1,000+ teams" or "Powering teams at" — always include a number if you can.
- **Size:** Logos 32-40px tall, auto width. Consistent visual weight — scale so the tallest and widest logos appear balanced.
- **Layout:** Horizontal row, centered, `gap: 40-64px`. On mobile, wrap to 2 rows or use horizontal scroll.

```css
.logo-bar {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 48px;
  flex-wrap: wrap;
  padding: 48px 24px;
}
.logo-bar img {
  height: 32px;
  width: auto;
  filter: grayscale(100%) opacity(0.6);
  transition: filter 0.2s;
}
.logo-bar img:hover {
  filter: grayscale(0%) opacity(1);
}
```

### Testimonial cards

Show real humans saying real things about your product.

**Card anatomy:**
- Customer photo (48-64px circle avatar).
- Quote text (16px, italic or regular, 2-4 lines max).
- Name (14px, bold), role + company (14px, muted).
- Optional: star rating, metric/result ("Increased conversion 40%").

**Layout:** 3-column grid on desktop, 1 column on mobile. Or a horizontal carousel with auto-advance every 5 seconds (with manual controls and pause-on-hover).

```css
.testimonial-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  max-width: 1120px;
  margin: 0 auto;
}
.testimonial-card {
  padding: 32px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: 12px;
}
@media (max-width: 768px) {
  .testimonial-grid {
    grid-template-columns: 1fr;
  }
}
```

### Review badges and metrics

- **Third-party badges:** G2, Capterra, TrustRadius logos with scores. Link to the review page. These are more credible than self-reported metrics.
- **Vanity metrics:** "10,000+ teams", "50M+ data points processed", "99.9% uptime." Display as large stat numbers (36-48px, bold) with labels below (14px, muted).

**Layout for metrics:** Horizontal row of 3-4 stats, evenly spaced. Use `justify-content: space-around` or a 3-4 column grid.

```css
.metrics-row {
  display: flex;
  justify-content: center;
  gap: 64px;
  padding: 48px 24px;
  text-align: center;
}
.metric-value {
  font-size: 40px;
  font-weight: 700;
  line-height: 1.1;
}
.metric-label {
  font-size: 14px;
  color: var(--text-muted);
  margin-top: 4px;
}
```

---

## Feature sections

Feature sections explain what the product does. Multiple layout patterns exist — vary them for visual rhythm.

### Feature grid

Best for listing 3-9 discrete features at equal weight.

- **Layout:** 3-column grid on desktop, 1 column on mobile. Each cell: icon (24-32px) + title (18px, semibold) + description (14-16px, muted, 2-3 lines).
- **Icons:** Use a consistent icon set (Lucide, Heroicons, Phosphor). All same size and stroke weight.
- **Spacing:** 32-48px gap between cells. Section padding 80-96px vertical.

```css
.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 40px;
  max-width: 1120px;
  margin: 0 auto;
  padding: 80px 24px;
}
@media (max-width: 768px) {
  .feature-grid {
    grid-template-columns: 1fr;
    gap: 32px;
  }
}
```

### Alternating feature rows

Best for 3-5 key features, each with a screenshot or illustration.

- **Layout:** 2-column grid, text on one side, image on the other. Alternate sides on each row.
- **Split:** 50/50 or 45/55 (slightly more room for the image).
- **Text side:** Overline label (12px, uppercase, primary color), heading (28-32px, bold), description (16px, 2-3 sentences), optional bullet list of sub-features.
- **Image side:** Product screenshot in a device frame or with a subtle drop shadow.

```css
.feature-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  padding: 64px 24px;
}
.feature-row:nth-child(even) {
  direction: rtl; /* swap sides */
}
.feature-row:nth-child(even) > * {
  direction: ltr; /* reset text direction */
}
@media (max-width: 768px) {
  .feature-row {
    grid-template-columns: 1fr;
    gap: 32px;
  }
  .feature-row:nth-child(even) {
    direction: ltr;
  }
}
```

### Tabbed feature showcase

For products with distinct modules or workflows that benefit from interactive exploration.

- **Tabs:** Horizontal tab bar (3-5 tabs max) above a large content area. Each tab shows a different screenshot + description.
- **Active tab:** Bold text, underline or background fill. Inactive: muted text.
- **Content area:** Minimum 480px height to prevent layout shift when switching tabs.
- **Animation:** Crossfade between tab contents (200ms opacity transition).
- **Auto-rotate:** Advance tabs every 5-8 seconds. Pause on hover or interaction.

### Comparison table

For competitive positioning. "Us vs. Them" or "Feature comparison across tiers."

- **Layout:** Standard table. Sticky first column (feature name). Green checkmarks for included, red X or dash for excluded.
- **Highlight your column:** Your product column gets a primary-color header and a subtle background tint.
- Keep to **10-15 rows** max. More than that, link to a dedicated comparison page.

---

## Pricing section

Pricing is where visitors decide to convert or leave. Clarity is everything.

### Pricing cards

**The 3-tier standard:** Free/Starter, Pro, Enterprise. Three options is optimal — two feels limited, four causes decision paralysis.

- **Card layout:** 3-column grid, equal width. Center card (usually Pro) is the recommended plan.
- **Highlighted plan:** "Most Popular" badge on the recommended tier. Visually emphasize with: primary-color border (2px), slightly raised (`scale(1.02)` or `box-shadow`), or a distinct background color.
- **Card anatomy:**
  1. Plan name (20px, bold)
  2. Price (40-48px, bold) + billing period (14px, muted: "/month" or "/user/month")
  3. Short description (14px, muted, 1 line)
  4. CTA button (full-width within the card)
  5. Feature list (14px, checkmark + feature name, 8px gap between items)

```css
.pricing-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  max-width: 1040px;
  margin: 0 auto;
  padding: 64px 24px;
  align-items: start;
}
.pricing-card {
  padding: 32px;
  border: 1px solid var(--border-default);
  border-radius: 12px;
  background: var(--bg-surface);
}
.pricing-card--popular {
  border: 2px solid var(--color-primary);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
  position: relative;
}
@media (max-width: 768px) {
  .pricing-grid {
    grid-template-columns: 1fr;
    max-width: 400px;
  }
}
```

### Monthly/annual toggle

- Position: centered above the pricing cards.
- Use a **segmented control** (not a toggle switch — users need to see both options simultaneously).
- Annual shows the discounted price. Display the discount: "Save 20%" badge next to the Annual option, or show the monthly price crossed out with the annual price below.
- Default selection: **Annual.** Most SaaS companies default to annual because it converts higher LTV.

### Feature comparison matrix

Below the pricing cards, include a detailed feature comparison table.

- **Sticky header row** with plan names.
- **Group features by category** (e.g., "Collaboration", "Security", "Support").
- **Visual markers:** Checkmark (included), dash (not included), specific values ("5 users", "Unlimited").
- Keep mobile-friendly: on small screens, collapse to a single-column accordion where each plan expands to show its features.

### Enterprise CTA

Enterprise tier doesn't show a price — it shows "Contact Sales" or "Talk to us."

- The CTA opens a **demo booking form** (Calendly embed, HubSpot meetings, or a custom form).
- Include "Custom pricing", "Dedicated support", "SSO/SAML" in the feature list to signal enterprise readiness.

### FAQ below pricing

Address objections immediately after showing the price. Common questions:

1. "Can I change plans later?"
2. "Is there a free trial?"
3. "What happens when my trial ends?"
4. "Do you offer discounts for nonprofits/startups?"
5. "How does billing work?"

**Layout:** Accordion (disclosure/collapse). Full-width below the pricing grid. Max-width 720px, centered. 5-8 questions max.

```css
.faq-section {
  max-width: 720px;
  margin: 0 auto;
  padding: 64px 24px;
}
.faq-item {
  border-bottom: 1px solid var(--border-default);
  padding: 20px 0;
}
.faq-question {
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.faq-answer {
  font-size: 15px;
  line-height: 1.6;
  color: var(--text-muted);
  padding-top: 12px;
}
```

---

## CTA sections

CTAs are distributed throughout the page, not just in the hero.

### Mid-page CTA breaks

Insert a CTA section between major content blocks (e.g., between features and pricing). Pattern:

- **Centered text:** Heading (28-32px, bold) + subtext (16px, muted) + primary CTA button.
- **Background:** Subtle contrast from surrounding sections — slightly tinted bg or a bordered container.
- **Padding:** 64-80px vertical. Keep it visually distinct but not jarring.

### Final CTA section (before footer)

The last persuasion attempt before the visitor leaves.

- **Full-width container** with a distinct background (brand color at 5-10% opacity, or a gradient).
- **Content:** Heading ("Ready to get started?"), subheadline (one more value prop), primary CTA button, optional secondary.
- **This is your second-highest-converting CTA** after the hero. Make it prominent.

```css
.final-cta {
  text-align: center;
  padding: 80px 24px;
  background: var(--color-primary-50); /* very light brand tint */
  border-radius: 16px;
  max-width: 1200px;
  margin: 64px auto;
}
```

### Email capture forms

For gated content (ebooks, webinars) or newsletter signups.

- **Inline form:** Single input (email) + submit button in a horizontal row. No name, no company — reduce friction.
- **Width:** 400-480px max. Center on page.
- **Button text:** "Subscribe", "Get the guide", "Join free" — not "Submit."
- **Privacy note:** Tiny text below (12px, muted): "No spam. Unsubscribe anytime."

### Demo booking

Embed Calendly, HubSpot Meetings, or Cal.com inline or in a modal.

- **Inline embed:** 100% width, ~600px height. Loads in an iframe.
- **Modal trigger:** "Book a demo" button opens a centered modal with the booking widget.
- **Form alternative:** If you don't use a scheduler, collect name, email, company size, and a preferred time slot.

---

## Page structure (scroll order)

The standard high-converting SaaS landing page follows this order:

1. **Sticky header** — logo, nav links (Product, Pricing, Docs), CTA button ("Start free trial"). Height 64px. Transparent over hero, solid bg on scroll. Show after 100px of scroll.
2. **Hero section** — headline + subheadline + CTA + product image.
3. **Social proof** — logo bar + optional metric counters. Immediately below hero, above the fold on desktop.
4. **Feature overview** — 3-column feature grid (quick scan) or alternating rows (detailed).
5. **Mid-page CTA** — brief reinforcement CTA.
6. **Detailed features** — tabbed showcase, screenshots, comparison.
7. **Testimonials** — quote cards or video testimonials.
8. **Pricing** — cards + toggle + feature matrix.
9. **FAQ** — accordion, 5-8 questions.
10. **Final CTA** — "Ready to get started?" section.
11. **Footer** — links (product, company, legal, resources), social icons, copyright.

### Sticky header with CTA

```css
.site-header {
  position: sticky;
  top: 0;
  z-index: 40;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  background: transparent;
  transition: background-color 0.2s, box-shadow 0.2s;
}
.site-header--scrolled {
  background: var(--bg-surface);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}
```

Toggle `.site-header--scrolled` class with an Intersection Observer on a sentinel element at the top of the page, or a scroll listener with a 100px threshold.

---

## Performance

Landing page speed is a conversion factor. Every 100ms of load time costs ~1% in conversion rate. LCP under 2.5 seconds is the target.

### Image optimization

| Technique | What | When |
|---|---|---|
| **WebP/AVIF** | Modern formats, 25-50% smaller than JPEG/PNG | Always. Provide fallback with `<picture>` + `<source>` |
| **`fetchpriority="high"`** | Tells browser to prioritize this image | Hero image only (the LCP element) |
| **`loading="lazy"`** | Defers loading until near viewport | Every image below the fold |
| **`loading="eager"`** | Load immediately (default) | Hero image, logo bar (above fold) |
| **Responsive `srcset`** | Serve right size for viewport | Always. Provide 1x, 1.5x, 2x at minimum |
| **`<picture>` with art direction** | Different crops for mobile vs desktop | Hero image if layout changes significantly |

```html
<picture>
  <source srcset="hero.avif" type="image/avif">
  <source srcset="hero.webp" type="image/webp">
  <img
    src="hero.jpg"
    alt="Product dashboard screenshot"
    width="1200"
    height="800"
    fetchpriority="high"
    loading="eager"
    decoding="async"
  >
</picture>
```

**Always set explicit `width` and `height`** on `<img>` tags. This lets the browser reserve space before the image loads, preventing Cumulative Layout Shift.

### Critical CSS inlining

- Inline the CSS needed for above-the-fold content directly in a `<style>` tag in `<head>`. This eliminates the render-blocking round trip for the external stylesheet.
- Target: under **14KB** of critical CSS (fits in the first TCP round trip).
- Load the rest of the stylesheet asynchronously:

```html
<link rel="preload" href="/styles.css" as="style" onload="this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="/styles.css"></noscript>
```

### Font loading

- **`font-display: swap`** on all `@font-face` declarations. Shows fallback font immediately, swaps when custom font loads. Prevents invisible text (FOIT).
- **Preload critical fonts:** `<link rel="preload" href="/font.woff2" as="font" type="font/woff2" crossorigin>` — but only 1-2 weights (regular + bold). Don't preload every weight.
- **Subset fonts.** If you only use Latin characters, subset to Latin. Reduces file size 50-80%.
- **Use `woff2` exclusively.** Browser support is universal. Don't serve `woff`, `ttf`, or `eot`.
- **Match fallback metrics.** Use `size-adjust`, `ascent-override`, `descent-override` in `@font-face` to make the fallback font match the custom font's metrics, minimizing layout shift on swap.

```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6,
    U+02DA, U+02DC, U+0300-0301, U+0303-0304, U+0308-0309, U+0323,
    U+0329, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193,
    U+2212, U+2215, U+FEFF, U+FFFD; /* Latin subset */
}
```

### Third-party script loading

- **Defer all third-party scripts** (analytics, chat widgets, A/B testing). Use `defer` or `async` attributes, or load them after the `load` event.
- **Never put analytics in `<head>` without `async`.** It blocks rendering.
- Chat widgets (Intercom, Crisp, Drift): load after 5 seconds or on scroll event, whichever comes first.

---

## Conversion patterns

### Exit-intent popups

Trigger when the cursor moves toward the browser chrome (desktop) or after scroll-up on mobile.

- **Use sparingly.** One per session, max. Don't show on return visits within 7 days (use localStorage/cookies).
- **Offer value:** Discount code, free resource, or newsletter signup. Never show a popup that just says "Don't leave!"
- **Timing:** Desktop — trigger on mouse leaving viewport toward the top. Mobile — trigger on rapid scroll-up or after 30 seconds + 50% scroll depth.
- **Average conversion rate:** ~3.9% of displaying visitors. The top 10% of campaigns reach ~27%.
- **Design:** Centered modal, backdrop blur, single CTA, prominent close button. Max width 480px. Keep copy to headline + 1 sentence + CTA + close.

### Sticky bottom bar on mobile

A fixed bottom bar with a CTA button that stays visible while scrolling.

- **Height:** 56-64px. Background: solid, matches site bg. Top border or shadow for separation.
- **Content:** Short text label + primary CTA button. Or just the CTA button full-width.
- **Show after:** 300px of scroll (don't show on initial viewport — let the hero CTA do its job).
- **Conversion impact:** Sticky bottom CTAs improve mobile conversion by 12-27%.

```css
.sticky-bottom-cta {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 64px;
  background: var(--bg-surface);
  border-top: 1px solid var(--border-default);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
  z-index: 30;
  transform: translateY(100%);
  transition: transform 0.3s ease;
}
.sticky-bottom-cta--visible {
  transform: translateY(0);
}
```

### Chatbot / support widget

- **Position:** Bottom-right corner, 24px from edges. Floating button (48-56px circle).
- **Delay load:** Don't load the widget JavaScript on page load. Load after 5 seconds idle or on first scroll past 50% of the page. This saves 100-300KB of initial payload.
- **Behavior:** Click opens a chat panel (360px wide, 480px tall) anchored to the bottom-right. First message should be automated: "Hi! How can I help?" with 2-3 quick-reply buttons for common questions.
- **Don't auto-open** the chat window. Let the user choose to engage.

### Announcement banners

A top-of-page bar for promotions, product launches, or events.

- **Height:** 40-48px. Full-width, above the sticky header.
- **Content:** Short text (1 line) + optional CTA link. Dismissible with X button.
- **Colors:** Brand color bg for positive announcements, amber for warnings/maintenance.
- **Persistence:** Dismissal saved to localStorage. Don't show again for that announcement (key by announcement ID).

```css
.announcement-banner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  height: 44px;
  padding: 0 16px;
  font-size: 14px;
  font-weight: 500;
  background: var(--color-primary);
  color: white;
}
.announcement-banner__dismiss {
  position: absolute;
  right: 16px;
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  opacity: 0.7;
}
.announcement-banner__dismiss:hover {
  opacity: 1;
}
```
