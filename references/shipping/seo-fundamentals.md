# Launch-day SEO fundamentals (Step 5)

launch-ready owns launch-day-correct SEO, not ongoing SEO practice. The difference: launch-day SEO is the set of one-time technical gates that must be green when the product ships. Ongoing SEO (keyword strategy, content cadence, link building, topic clusters) is a different discipline and out of scope.

This reference covers the 12 launch-day gates, Open Graph and Twitter Card discipline, schema.org structured data, and the performance checks that a PH / HN traffic spike will amplify.

## 1. The twelve gates

Each is a hard block. A launch with any of these in the red ships a preventable bug.

### Gate 1: Exactly one `<h1>` per page

Multiple H1s fragment the semantic structure; search engines and screen readers lose the primary topic. Tooling: view-source, browser DevTools, Lighthouse.

The H1 contains the product name or the positioning's main verb. "Runbook, the on-call handoff tool for three-person teams" is a strong H1. "Welcome to Runbook" is a weak H1. "Home" is a catastrophic H1.

### Gate 2: `<title>` under 60 characters

Google truncates titles at approximately 580 pixels (varies by font). 60 characters is the safe length for nearly all character mixes. Longer titles are truncated in the search result; the cutoff is usually at a worse position than intended.

The title is launch copy, not a navigation label. It contains the product name plus the differentiator. "Runbook: on-call handoffs that update themselves" (49 chars) passes. "Home | Runbook" (15 chars) passes for length but fails the launch-copy discipline.

### Gate 3: Meta description under 160 characters

Google shows approximately 155 to 160 characters of meta description on desktop; mobile is shorter. The description is distinct from the hero copy; it reads as a search-result preview, not a page headline.

Active voice, second person, names the primary benefit. "Hand off your on-call rotation without writing the Slack pin yourself. Reads your existing PagerDuty schedule every 60 seconds." (127 chars) passes.

### Gate 4: Canonical URL on every page

`<link rel="canonical" href="https://runbook.dev/">` on every page. Prevents duplicate-content penalties when the page is accessible at both `www.` and non-`www.`, at both `http://` and `https://`, or with and without trailing slash.

Pick a canonical host and stick to it. Redirect all other variants to the canonical via server-level 301.

### Gate 5: robots.txt correct

At `/robots.txt`. Allows major search-engine crawlers (Googlebot, Bingbot, DuckDuckBot) for the production host. Disallows any staging subdomains (`staging.`, `preview.`, `dev.`) that might otherwise leak into search results during the launch spike.

Minimal example:

```
User-agent: *
Allow: /

Sitemap: https://runbook.dev/sitemap.xml
```

For staging subdomains, a separate robots.txt with `Disallow: /` plus `<meta name="robots" content="noindex">` on every page.

### Gate 6: sitemap.xml exists

At `/sitemap.xml`. Referenced from robots.txt. Contains:

- The landing page.
- The waitlist confirmation page (if public).
- The privacy policy page.
- The terms of service page.
- The blog index page if any.
- The press / about page if any.

Does NOT contain: staging URLs, admin pages, authenticated pages, duplicate URLs with query parameters.

For a simple launch, a static sitemap.xml with five to ten URLs is sufficient. Dynamic sitemaps matter at content scale; for launch-day, static is fine.

### Gate 7: Open Graph tags complete

On every shareable page. The minimum set:

```html
<meta property="og:type" content="website">
<meta property="og:url" content="https://runbook.dev/">
<meta property="og:title" content="Runbook: on-call handoffs that update themselves">
<meta property="og:description" content="Hand off your on-call rotation without writing the Slack pin yourself.">
<meta property="og:image" content="https://runbook.dev/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:site_name" content="Runbook">
<meta property="og:locale" content="en_US">
```

See `social-share-cards.md` for OG image production and the five-channel preview rule.

### Gate 8: Twitter Card tags complete

```html
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:site" content="@runbookdev">
<meta name="twitter:creator" content="@founderhandle">
<meta name="twitter:title" content="Runbook: on-call handoffs that update themselves">
<meta name="twitter:description" content="Hand off your on-call rotation without writing the Slack pin yourself.">
<meta name="twitter:image" content="https://runbook.dev/og.png">
```

`summary_large_image` is the format that shows the 1200x630 card. `summary` is the smaller square thumbnail and is not what a launch wants.

Twitter deprecated its Card Validator public tool over 2023; preview by posting a link to a test account (X's algorithm is card-aware on first post) or use third-party previewers (OpenGraph.xyz, opengraph.io).

### Gate 9: schema.org JSON-LD present

At minimum for a SaaS landing page:

**Organization:**

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Runbook",
  "url": "https://runbook.dev",
  "logo": "https://runbook.dev/logo.png",
  "sameAs": [
    "https://twitter.com/runbookdev",
    "https://github.com/runbook",
    "https://www.linkedin.com/company/runbook"
  ]
}
```

**SoftwareApplication (if the product is a software product):**

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Runbook",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
```

Add `FAQPage` schema if the landing page has an FAQ section; Google sometimes shows FAQ rich results.

Validate with Google's Rich Results Test (search.google.com/test/rich-results). Any error or warning is a launch-day block.

### Gate 10: HTTPS only

No mixed content. All assets (CSS, JS, images, fonts) load over HTTPS. `Strict-Transport-Security` header with `max-age=31536000; includeSubDomains` (and ideally `preload` on the HSTS preload list).

A launch page served over HTTP in 2026 will be flagged "Not Secure" by Chrome and downranked by Google.

### Gate 11: Core Web Vitals pass

Measured via PageSpeed Insights (pagespeed.web.dev) and/or Chrome UX Report. Thresholds as of April 2026:

- **LCP (Largest Contentful Paint) under 2.5 seconds.** Typically the hero image or the hero headline render.
- **CLS (Cumulative Layout Shift) under 0.1.** Prevents the page from jumping as webfonts load, images arrive, and async widgets insert.
- **INP (Interaction to Next Paint) under 200ms.** Replaced FID in March 2024. Measures the worst interaction latency during the visit.

Common causes of failures on launch landing pages:

- **LCP high.** Hero image not preloaded; webfont loading blocks render; uncached third-party scripts.
- **CLS high.** Images without `width` and `height` attributes; webfonts without `size-adjust` or `font-display: swap`; async-injected widgets (chat, analytics) without reserved space.
- **INP high.** Heavy JavaScript frameworks on the landing page; third-party scripts (analytics, consent banners) blocking the main thread.

Launch-day traffic spikes amplify slow-page penalties: first-visit conversion drops when LCP exceeds 2.5s, and the traffic from PH / HN is first-visit.

### Gate 12: No stray `noindex`

AI-generated landing pages often inherit `<meta name="robots" content="noindex,nofollow">` from the template the page was scaffolded from (shadcn starter, Tailwind starter, Next.js template). The template includes the meta tag to prevent the template-repo itself from ranking. When the page ships to production, the meta tag stays and the launch page is invisible to search.

The grep:

```
grep -r "noindex" src/ public/ app/ pages/ dist/ build/ 2>/dev/null
```

Zero hits on the shipped HTML. One hit is a launch-blocking bug.

Also grep `X-Robots-Tag` in HTTP response headers; some hosts set a global noindex header that overrides the meta tag.

## 2. What launch-ready does NOT own on SEO

- **Keyword research.** "What keywords should we target" is ongoing-marketing territory.
- **Topic clusters and pillar pages.** A content strategy beyond the landing page is out of scope.
- **Link building.** Outreach for backlinks is ongoing marketing.
- **Google Search Console setup beyond the one-time verification.** Launch-day verification is in scope; weekly GSC monitoring is not.
- **International SEO.** `hreflang` tags, region-specific domains, per-language content are out of scope for v1.0.0.
- **Featured-snippet optimization.** A 2026-specific practice that requires ongoing content investment.

## 3. The launch-day SEO checklist (print version)

Copy into `.launch-ready/launches/YYYY-MM-slug.md`:

- [ ] Exactly one `<h1>` on the landing page.
- [ ] `<title>` under 60 characters; contains product name and differentiator.
- [ ] Meta description under 160 characters; distinct from hero copy.
- [ ] `<link rel="canonical">` on every page; points to the canonical host.
- [ ] `/robots.txt` exists and allows major crawlers; staging subdomains blocked.
- [ ] `/sitemap.xml` exists and references the five core pages; referenced from robots.txt.
- [ ] All seven Open Graph meta tags present on every shareable page.
- [ ] All six Twitter Card meta tags present on every shareable page.
- [ ] schema.org Organization JSON-LD present.
- [ ] schema.org SoftwareApplication (or relevant type) JSON-LD present.
- [ ] FAQPage JSON-LD if FAQ section exists.
- [ ] Google Rich Results Test: zero errors, zero warnings.
- [ ] HTTPS everywhere; no mixed content; HSTS header set.
- [ ] PageSpeed Insights: LCP under 2.5s, CLS under 0.1, INP under 200ms on both desktop and mobile.
- [ ] Grep for `noindex` in shipped HTML: zero hits.
- [ ] Grep for `X-Robots-Tag` in response headers: no `noindex`.
- [ ] Google Search Console verification added (one-time).

## 4. Research pass references

For Google's 2026 ranking-signal guidance, see Google Search Central (developers.google.com/search). For schema.org type definitions, see schema.org/SoftwareApplication and schema.org/Organization. Further citations in `RESEARCH-2026-04.md` sections 5 and 7.
