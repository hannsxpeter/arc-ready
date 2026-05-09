# SEO & Web Standards

This file covers everything a SaaS product needs to be discoverable by search engines, readable by AI models, and compliant with web standards. Not "SEO tips" — the actual files, tags, and configurations you ship.

Dashboard UIs are mostly behind auth and should not be indexed. Marketing pages, docs, blog, and changelog are your SEO surface. This file covers that surface.

---

## Meta tags

Every public page needs these. No exceptions.

### Title tag

50-60 characters. Primary keyword near the front. Unique per page.

```html
<title>Invoicing Software for Freelancers | Billflow</title>
```

Rules:
- Never duplicate titles across pages. Duplicates cause content cannibalization.
- Pipe or dash separator between page title and brand: `Page Title | Brand` or `Page Title - Brand`.
- Numbers and brackets improve CTR: "7 Ways to..." or "[2026 Guide]".
- Do not stuff keywords. Write for humans scanning a search results page.

### Meta description

150-160 characters. Not a ranking signal, but controls the snippet users see. Write it like ad copy — address intent, highlight value.

```html
<meta name="description" content="Send professional invoices in 30 seconds. Track payments, automate reminders, get paid faster. Free for your first 5 clients." />
```

Rules:
- Unique per page. Shared descriptions across pages are worse than no description.
- Google rewrites ~70% of descriptions anyway. Still write them — the 30% matters.
- Include a call-to-action or value proposition, not a summary.

### Canonical URL

Tells search engines which URL is the "real" version when duplicates exist (www vs non-www, query params, trailing slashes).

```html
<link rel="canonical" href="https://billflow.com/features/invoicing" />
```

Rules:
- Every indexable page gets a canonical pointing to itself.
- Always use absolute URLs, never relative.
- Canonical must match the URL in your sitemap.
- If you have `?ref=twitter` or `?utm_source=newsletter` query params, the canonical strips them.

### Viewport and charset

```html
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
```

Always present. Not negotiable.

---

## Open Graph tags

Control how your pages look when shared on social platforms. Without these, platforms scrape whatever they find — usually garbage.

```html
<meta property="og:type" content="website" />
<meta property="og:title" content="Invoicing Software for Freelancers" />
<meta property="og:description" content="Send professional invoices in 30 seconds. Track payments, automate reminders, get paid faster." />
<meta property="og:url" content="https://billflow.com/" />
<meta property="og:image" content="https://billflow.com/og/home.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:site_name" content="Billflow" />
```

Image specs:
- **Size:** 1200x630px (1.91:1 ratio). This works across Facebook, LinkedIn, Twitter, Slack, Discord.
- **Format:** PNG or JPG. Keep under 5MB.
- **Content:** Don't use a photo with tiny text. Use large type on a solid/gradient background with your logo. It will be displayed at thumbnail size.

Use `og:type` = `website` for the homepage, `article` for blog posts (add `article:published_time`, `article:author`), `product` for product/pricing pages.

---

## Twitter/X Card tags

Twitter falls back to Open Graph tags for everything except `twitter:card`. The minimum you need:

```html
<meta name="twitter:card" content="summary_large_image" />
```

That's it. If you have OG tags set, Twitter uses `og:title`, `og:description`, and `og:image` as fallbacks. Only add explicit Twitter tags if you want different copy on Twitter than everywhere else:

```html
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:site" content="@billflow" />
<meta name="twitter:creator" content="@founderhandle" />
```

Card types:
- `summary_large_image` — large image preview. Use this for everything.
- `summary` — small square image. Only if your image is a logo/icon, not a scene.

---

## Structured data (JSON-LD)

Google's preferred format. Lives in a `<script>` tag, separate from HTML. Doesn't affect visible content.

### Organization (homepage)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Billflow",
  "url": "https://billflow.com",
  "logo": "https://billflow.com/logo.png",
  "sameAs": [
    "https://twitter.com/billflow",
    "https://github.com/billflow",
    "https://linkedin.com/company/billflow"
  ]
}
</script>
```

### WebSite with search (homepage)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Billflow",
  "url": "https://billflow.com",
  "potentialAction": {
    "@type": "SearchAction",
    "target": "https://billflow.com/docs?q={search_term_string}",
    "query-input": "required name=search_term_string"
  }
}
</script>
```

### SoftwareApplication (product page)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Billflow",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD",
    "description": "Free tier — up to 5 clients"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "ratingCount": "342"
  }
}
</script>
```

### BreadcrumbList (every page with breadcrumbs)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://billflow.com" },
    { "@type": "ListItem", "position": 2, "name": "Docs", "item": "https://billflow.com/docs" },
    { "@type": "ListItem", "position": 3, "name": "API Reference", "item": "https://billflow.com/docs/api" }
  ]
}
</script>
```

### FAQPage (pricing page, feature pages)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Is there a free plan?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Billflow is free for up to 5 clients with unlimited invoices."
      }
    }
  ]
}
</script>
```

### Article / BlogPosting (blog posts)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "How to Automate Invoice Reminders",
  "datePublished": "2026-03-15",
  "dateModified": "2026-03-20",
  "author": { "@type": "Person", "name": "Alex Chen" },
  "publisher": {
    "@type": "Organization",
    "name": "Billflow",
    "logo": { "@type": "ImageObject", "url": "https://billflow.com/logo.png" }
  },
  "image": "https://billflow.com/blog/invoice-reminders/og.png"
}
</script>
```

Rules:
- Schema values must match visible page content. Do not put data in JSON-LD that isn't on the page.
- Validate with Google's Rich Results Test: https://search.google.com/test/rich-results
- For SaaS: prioritize Organization, SoftwareApplication, FAQPage, Article, and BreadcrumbList schemas.

---

## Sitemap.xml

Tells search engines what pages exist and when they changed.

### Format

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://billflow.com/</loc>
    <lastmod>2026-04-01</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://billflow.com/features</loc>
    <lastmod>2026-03-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://billflow.com/blog/automate-reminders</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>yearly</changefreq>
    <priority>0.6</priority>
  </url>
</urlset>
```

### Sitemap index (for large sites)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap>
    <loc>https://billflow.com/sitemaps/pages.xml</loc>
    <lastmod>2026-04-01</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://billflow.com/sitemaps/blog.xml</loc>
    <lastmod>2026-03-20</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://billflow.com/sitemaps/docs.xml</loc>
    <lastmod>2026-03-28</lastmod>
  </sitemap>
</sitemapindex>
```

Rules:
- Max 50,000 URLs or 50MB per sitemap file. Use a sitemap index to split.
- Split by content type (blog, docs, marketing pages), not randomly.
- `<lastmod>` must be accurate — the date of the last *significant* content change, not the deploy date. Google uses this to prioritize crawling.
- `<changefreq>` is a hint, not a directive. Google mostly ignores it. Include it anyway.
- `<priority>` is relative within your site. Homepage = 1.0, main sections = 0.8, individual pages = 0.6, archive = 0.4.
- Only include pages you actually want indexed. No admin URLs, no auth pages, no search result pages, no duplicates.
- Auto-generate from your CMS or build process. Never maintain by hand.
- Reference your sitemap in `robots.txt`: `Sitemap: https://billflow.com/sitemap.xml`
- Submit in Google Search Console after deploying.

---

## Core Web Vitals

Google uses these as ranking signals. Pass all three at the 75th percentile of real user visits.

| Metric | What it measures | Good | Needs improvement | Poor |
|---|---|---|---|---|
| **LCP** (Largest Contentful Paint) | Time for the largest visible element to render | < 2.5s | 2.5–4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | Latency from user input to visual response | < 200ms | 200–500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | Visual stability — how much the page shifts during load | < 0.1 | 0.1–0.25 | > 0.25 |

Impact: Core Web Vitals account for roughly 10-15% of ranking signals. They function as a tiebreaker — when content quality is comparable, better vitals win. As of the March 2026 core update, Google strengthened the weight of performance signals.

Only 48% of mobile pages pass all three metrics. LCP is the hardest — only 62% of mobile pages achieve "good."

### What to do

**LCP:**
- Preload the LCP image: `<link rel="preload" as="image" href="/hero.webp" />`
- Use `fetchpriority="high"` on the hero image.
- Eliminate render-blocking CSS and JS above the fold.
- Inline critical CSS, defer the rest.

**INP:**
- Keep main thread work under 50ms per task.
- Use `requestIdleCallback` or `scheduler.yield()` for heavy JS.
- Debounce input handlers.
- Avoid layout thrashing (read-then-write DOM patterns).

**CLS:**
- Set explicit `width` and `height` on all images and videos.
- Use `aspect-ratio` CSS for responsive containers.
- Reserve space for dynamic content (ads, embeds, lazy-loaded images).
- Never inject content above the current viewport after initial render.

---

## Heading hierarchy

```html
<h1>Invoicing Software for Freelancers</h1>         <!-- one per page -->
  <h2>Features</h2>
    <h3>Automatic Reminders</h3>
    <h3>Multi-Currency Support</h3>
  <h2>Pricing</h2>
    <h3>Free Tier</h3>
    <h3>Pro Plan</h3>
  <h2>FAQ</h2>
```

Rules:
- Exactly one `<h1>` per page. It should match or closely match the `<title>` tag.
- Do not skip levels. No `<h1>` to `<h3>` without an `<h2>`.
- Headings are for document structure, not visual sizing. Use CSS for sizing. An `<h3>` that's larger than an `<h2>` is a styling choice — the HTML hierarchy must still be correct.

---

## Image optimization

### Formats

Use **WebP** as the default. WebP is 25-35% smaller than JPEG at equivalent quality, supported by all modern browsers.

Use **AVIF** for even better compression (40-50% smaller than JPEG) where build tooling supports it. AVIF is more CPU-intensive to decode, so use it for large hero images, not small icons.

Use **SVG** for icons, logos, and illustrations — anything that's geometric or flat.

Use **PNG** only for images requiring transparency where SVG isn't suitable.

### The `<picture>` element with format fallback

```html
<picture>
  <source srcset="/hero.avif" type="image/avif" />
  <source srcset="/hero.webp" type="image/webp" />
  <img
    src="/hero.jpg"
    alt="Dashboard showing invoice analytics"
    width="1200"
    height="630"
    loading="lazy"
    decoding="async"
  />
</picture>
```

### Responsive images with srcset

```html
<img
  src="/hero-800.webp"
  srcset="/hero-400.webp 400w, /hero-800.webp 800w, /hero-1200.webp 1200w"
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
  alt="Invoice creation form with autofill"
  width="1200"
  height="800"
  loading="lazy"
  decoding="async"
/>
```

### Rules

- **Every image gets `alt` text.** Descriptive, concise, no "image of" prefix. Decorative images get `alt=""`.
- **Every image gets `width` and `height` attributes** (or CSS `aspect-ratio`). This prevents CLS.
- **Lazy load everything below the fold:** `loading="lazy"`. Above-the-fold hero images: do NOT lazy load — they are your LCP element.
- **Add `decoding="async"`** to all images. Lets the browser decode off the main thread.
- **Preload the LCP image** in the `<head>`: `<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />`
- **Use a CDN with auto-format.** Cloudflare, Vercel, Imgix, and Cloudinary can serve AVIF/WebP automatically based on the `Accept` header.

---

## URL structure

- **Human-readable slugs:** `/blog/automate-invoice-reminders` not `/blog/post?id=47382`.
- **Flat hierarchy:** `/docs/api-reference` not `/docs/section/subsection/api/reference/v2`.
- **Lowercase, hyphens:** `/pricing` not `/Pricing` or `/pricing_page`.
- **No query params for content pages.** Use path segments. Query params are for filters, sorts, search.
- **No trailing slashes** (or always trailing slashes — pick one and enforce it with redirects).
- **No file extensions in URLs:** `/about` not `/about.html`.
- **Consistent scheme:** Always HTTPS, always redirect HTTP to HTTPS.

---

## Internal linking

- Every page should be reachable within 3 clicks from the homepage.
- Blog posts link to related blog posts, feature pages, and docs.
- Docs link to related docs and feature pages.
- Feature pages link to pricing, docs, and blog posts.
- Use descriptive anchor text: "learn about automatic reminders" not "click here."
- Navigation (header, sidebar, footer) provides the structural link backbone.
- Breadcrumbs provide hierarchical context and generate BreadcrumbList schema.

---

## robots.txt

### Format

```txt
# Search engine crawlers
User-agent: *
Allow: /
Disallow: /app/
Disallow: /admin/
Disallow: /api/
Disallow: /auth/
Disallow: /search?
Disallow: /internal/
Disallow: /staging/
Disallow: /preview/

# Reference sitemap
Sitemap: https://billflow.com/sitemap.xml
```

### What to block

| Block | Why |
|---|---|
| `/app/`, `/dashboard/` | Authenticated app pages — no public value |
| `/admin/` | Admin panel — never index |
| `/api/` | API endpoints — not pages |
| `/auth/`, `/login`, `/signup`, `/reset-password` | Auth flows — no SEO value |
| `/search?` | Search result pages — duplicate/thin content |
| `/internal/`, `/staging/`, `/preview/` | Non-production content |
| `/_next/data/` (Next.js) | JSON data routes, not pages |

### What NOT to block

- **CSS and JS files.** Google needs to render your pages. Blocking CSS/JS breaks rendering and hurts rankings.
- **Images you want indexed.** Product screenshots, blog images, diagrams.
- **Your marketing pages.** Obviously.

### SaaS multi-tenant considerations

If you use tenant subdomains (`acme.billflow.com`), block them from indexing — tenant-specific content is private:

```txt
# On *.billflow.com (tenant subdomains)
User-agent: *
Disallow: /
```

Only `billflow.com` (root domain) and `docs.billflow.com` should be indexable.

### Crawl-delay

```txt
User-agent: Bingbot
Crawl-delay: 5
```

Supported by Bing, Yandex, and some others. **Not supported by Google** — Google ignores it entirely. Use Google Search Console's crawl rate settings instead.

### Common mistakes

- Blocking CSS/JS and wondering why Google can't render your pages.
- Using `Disallow: /` on production during a launch and forgetting to remove it.
- Not testing after changes. Use Google Search Console's robots.txt tester.
- Forgetting the `Sitemap:` directive.

---

## AI crawler management

AI crawlers are a separate concern from search engine crawlers. They fall into two categories:

### Training crawlers

Collect content at scale for model training. You may want to block these if your content is your competitive advantage.

| User-agent | Operator | Purpose |
|---|---|---|
| `GPTBot` | OpenAI | Training data for GPT models |
| `ChatGPT-User` | OpenAI | Real-time page fetch when user asks ChatGPT |
| `OAI-SearchBot` | OpenAI | Search indexing for ChatGPT search |
| `ClaudeBot` | Anthropic | Training data for Claude models |
| `Claude-User` | Anthropic | Real-time page fetch when user asks Claude |
| `Claude-SearchBot` | Anthropic | Search indexing for Claude search |
| `Google-Extended` | Google | Training data for Gemini (separate from Googlebot) |
| `Bytespider` | ByteDance | Training data for TikTok/Doubao AI |
| `CCBot` | Common Crawl | Open dataset used by many AI labs |
| `meta-externalagent` | Meta | Training data for Meta AI |
| `PerplexityBot` | Perplexity | Training and search |
| `Amazonbot` | Amazon | Training and Alexa/search |
| `Applebot-Extended` | Apple | Training data for Apple Intelligence |

### Recommended robots.txt for SaaS

Most SaaS companies should: allow search-related AI crawlers (they drive traffic), make a deliberate choice about training crawlers.

```txt
# AI search bots — allow (they send traffic)
User-agent: ChatGPT-User
Allow: /

User-agent: Claude-User
Allow: /

User-agent: Claude-SearchBot
Allow: /

User-agent: OAI-SearchBot
Allow: /

User-agent: PerplexityBot
Allow: /

# AI training bots — block if your content is proprietary
User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: Bytespider
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: meta-externalagent
Disallow: /
```

Important: Anthropic's three bots are independent — blocking `ClaudeBot` does not block `Claude-User` or `Claude-SearchBot`. Same pattern with OpenAI's `GPTBot` vs `ChatGPT-User` vs `OAI-SearchBot`.

### Aggressive crawlers

Some crawlers (Bytespider, 360Spider, ChatGLM-Spider) ignore `robots.txt`. For those, you need server-level blocking:

```nginx
# nginx — block by user-agent
if ($http_user_agent ~* "(Bytespider|360Spider|ChatGLM-Spider)") {
    return 403;
}
```

Or use Cloudflare WAF / rate limiting rules.

---

## llms.txt

A proposed standard (created by Jeremy Howard at Answer.AI, September 2024) for providing structured content to AI models at inference time. Unlike `robots.txt` (which controls crawling), `llms.txt` tells AI models where your most useful content lives.

### Current status

As of 2025-2026, major AI providers (OpenAI, Google, Anthropic) have **not yet implemented native support** for llms.txt in their primary products. Adoption is growing among documentation platforms (Mintlify, GitBook, Fern, Read the Docs) but mainstream AI integration remains limited. Implement it anyway — it's low-cost, forward-looking, and documentation tools already use it.

### Format

The file is Markdown, served at `/llms.txt`. The structure is strict:

```markdown
# Billflow

> Invoicing and payment automation software for freelancers and small businesses. REST API, webhook integrations, multi-currency support.

## Docs

- [Getting Started](https://billflow.com/docs/getting-started): Quick setup guide — create account, send first invoice
- [API Reference](https://billflow.com/docs/api): REST API docs with authentication, endpoints, and webhooks
- [Integrations](https://billflow.com/docs/integrations): Connect with Stripe, QuickBooks, Slack, Zapier

## Blog

- [Automating Invoice Reminders](https://billflow.com/blog/automate-reminders): Step-by-step guide to payment automation
- [Multi-Currency Invoicing](https://billflow.com/blog/multi-currency): How to invoice international clients

## Optional

- [Changelog](https://billflow.com/changelog): Product updates and release notes
- [Status Page](https://status.billflow.com): Current system status
```

### Structure rules

1. **H1** — project/site name (required, exactly one)
2. **Blockquote** — short summary with key information (strongly recommended)
3. **H2 sections** — categories of links. Section titled "Optional" marks less critical resources.
4. **Link lists** — `[Title](URL): Description` format, one per line with a dash prefix

### llms-full.txt

A companion file containing your entire site content concatenated into one large Markdown file. Useful for smaller sites or documentation-heavy products where you want AI models to have full context without following links.

Serve at `/llms-full.txt`. Can be large (megabytes).

### Implementation alongside robots.txt

These files serve different purposes and work independently:

| File | Controls | Audience |
|---|---|---|
| `robots.txt` | What crawlers can/cannot access | Search engines, AI crawlers |
| `llms.txt` | What content is most useful for AI | AI models at inference time |

You can block an AI training crawler in `robots.txt` while still providing `llms.txt` as a directory. The `llms.txt` is read at query time, not crawl time.

---

## RSS / Atom / JSON Feed

### Which format

Provide **RSS 2.0** at minimum. It has the widest support across feed readers, podcast apps, and automation tools.

If you can easily generate multiple formats, provide **RSS 2.0 + JSON Feed**. JSON Feed (version 1.1) is cleaner for developers to parse and debug.

Atom is technically superior to RSS but has no practical advantage in 2025. Skip it unless you have a specific need.

### RSS 2.0

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Billflow Blog</title>
    <link>https://billflow.com/blog</link>
    <description>Product updates, invoicing tips, and freelance business advice.</description>
    <language>en-us</language>
    <lastBuildDate>Wed, 20 Mar 2026 09:00:00 GMT</lastBuildDate>
    <atom:link href="https://billflow.com/feed.xml" rel="self" type="application/rss+xml" />

    <item>
      <title>How to Automate Invoice Reminders</title>
      <link>https://billflow.com/blog/automate-reminders</link>
      <guid isPermaLink="true">https://billflow.com/blog/automate-reminders</guid>
      <pubDate>Fri, 15 Mar 2026 09:00:00 GMT</pubDate>
      <description>Step-by-step guide to setting up automatic payment reminders that actually get you paid.</description>
    </item>
  </channel>
</rss>
```

### JSON Feed 1.1

```json
{
  "version": "https://jsonfeed.org/version/1.1",
  "title": "Billflow Blog",
  "home_page_url": "https://billflow.com/blog",
  "feed_url": "https://billflow.com/feed.json",
  "description": "Product updates, invoicing tips, and freelance business advice.",
  "language": "en-US",
  "items": [
    {
      "id": "https://billflow.com/blog/automate-reminders",
      "url": "https://billflow.com/blog/automate-reminders",
      "title": "How to Automate Invoice Reminders",
      "content_html": "<p>Step-by-step guide to setting up automatic payment reminders...</p>",
      "date_published": "2026-03-15T09:00:00-04:00",
      "authors": [{ "name": "Alex Chen" }],
      "tags": ["automation", "invoicing"]
    }
  ]
}
```

### Feed discovery

Add to every HTML page's `<head>`:

```html
<link rel="alternate" type="application/rss+xml" title="Billflow Blog" href="/feed.xml" />
<link rel="alternate" type="application/json" title="Billflow Blog (JSON)" href="/feed.json" />
```

This enables auto-discovery in feed readers and browsers.

### What to include in feeds

| Feed | Content | URL |
|---|---|---|
| Blog feed | Blog posts — full or summary HTML in `<description>` | `/feed.xml` |
| Changelog feed | Product updates, new features, fixes | `/changelog/feed.xml` |
| Docs updates | Major documentation changes (optional) | `/docs/feed.xml` |

### Pagination

For large archives, use RFC 5005 feed paging. Add navigation links in the channel:

```xml
<atom:link rel="next" href="https://billflow.com/feed.xml?page=2" />
<atom:link rel="previous" href="https://billflow.com/feed.xml?page=1" />
```

Keep the default feed to the most recent 20-50 items.

### Validation

- RSS/Atom: https://validator.w3.org/feed/
- JSON Feed: https://validator.jsonfeed.org/

### Auto-generation

Generate feeds from the same content source as your pages. In Next.js, generate during build. In a CMS, use a plugin. Never maintain feed XML by hand.

---

## Favicon — modern approach

You need five files, not thirty. This covers every browser and device.

### The files

| File | Size | Purpose |
|---|---|---|
| `favicon.ico` | 32x32 | Legacy browsers, bookmark bars |
| `favicon.svg` | scalable | Modern browsers — supports dark mode |
| `apple-touch-icon.png` | 180x180 | iOS home screen, Safari |
| `icon-192.png` | 192x192 | Android Chrome, PWA |
| `icon-512.png` | 512x512 | PWA splash screen, install dialog |

### HTML

```html
<link rel="icon" href="/favicon.ico" sizes="32x32" />
<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
<link rel="manifest" href="/manifest.webmanifest" />
```

### SVG favicon with dark mode

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <style>
    rect { fill: #4f46e5; }
    @media (prefers-color-scheme: dark) {
      rect { fill: #818cf8; }
    }
  </style>
  <rect width="32" height="32" rx="6" />
  <text x="50%" y="50%" text-anchor="middle" dy=".35em"
        font-family="system-ui" font-size="20" fill="white">B</text>
</svg>
```

### Web app manifest

```json
{
  "name": "Billflow",
  "short_name": "Billflow",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#4f46e5",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/favicon.svg", "sizes": "any", "type": "image/svg+xml" }
  ]
}
```

Rules:
- File extension: `.webmanifest` is preferred, `.json` works fine. Serve with `application/manifest+json` content type.
- `theme_color` affects the browser chrome (address bar on Android, title bar on desktop PWA). Match your brand color.
- `background_color` is the splash screen color while the app loads. Use white or your brand bg.
- For maskable icons (Android adaptive icons), add `"purpose": "maskable"` and ensure important content stays within the safe zone (center 80%).

---

## security.txt (RFC 9116)

A standardized file that tells security researchers how to report vulnerabilities to you. Required? No. Recommended by CISA and NCSC? Yes.

### Location

Serve at `/.well-known/security.txt`. Also acceptable at `/security.txt`, but the `.well-known` path takes precedence if both exist.

### Format

```txt
# Security contact for Billflow
Contact: mailto:security@billflow.com
Contact: https://billflow.com/security/report
Expires: 2027-04-01T00:00:00.000Z
Preferred-Languages: en
Canonical: https://billflow.com/.well-known/security.txt
Policy: https://billflow.com/security/policy
```

### Required fields

| Field | Description |
|---|---|
| `Contact` | How to report vulnerabilities — email (mailto:) or URL. At least one required. |
| `Expires` | When this file should be considered stale. Required. Use ISO 8601 datetime. Set it 1 year out and update annually. |

### Optional fields

| Field | Description |
|---|---|
| `Preferred-Languages` | Languages you accept reports in |
| `Canonical` | The definitive URL of this security.txt file |
| `Policy` | URL of your vulnerability disclosure policy |
| `Hiring` | URL of security-related job openings |
| `Encryption` | URL of your PGP key for encrypted reports |
| `Acknowledgments` | URL of your security hall of fame |

Rules:
- Must be served over HTTPS.
- Content-Type: `text/plain`.
- **Set a calendar reminder to update `Expires` before it lapses.** An expired security.txt is worse than none.

---

## humans.txt

A plain-text file at `/humans.txt` listing the people, tools, and technologies behind a site.

```txt
/* TEAM */
Lead Developer: Alex Chen
Contact: alex@billflow.com
Twitter: @alexchen

/* THANKS */
Vercel, Stripe, Anthropic

/* SITE */
Last update: 2026-04-01
Standards: HTML5, CSS3
Components: React, Next.js, Tailwind CSS
Software: VS Code, Figma
```

**Verdict:** Nice gesture, no SEO value, no technical impact. Include it if you want to. Skip it if you don't. It has no effect on anything.

---

## ads.txt

Only relevant if you sell ad inventory on your site. For most SaaS products: **skip it.**

If you do display ads (blog, docs with ads), `ads.txt` declares which ad networks are authorized to sell your inventory:

```txt
google.com, pub-1234567890, DIRECT, f08c47fec0942fa0
```

Format: `<domain>, <publisher-id>, <relationship>, <certification-authority-id>`

Serve at `/ads.txt`. The IAB Tech Lab manages the standard.

---

## browserconfig.xml

Configured Windows tile behavior for Internet Explorer and older Edge. In 2025: **skip it.** PWA manifest handles everything browserconfig.xml used to do. Edge is Chromium now.

If you must support it for legacy Windows users pinning your site:

```xml
<?xml version="1.0" encoding="utf-8"?>
<browserconfig>
  <msapplication>
    <tile>
      <square150x150logo src="/mstile-150x150.png" />
      <TileColor>#4f46e5</TileColor>
    </tile>
  </msapplication>
</browserconfig>
```

But again — skip it unless you have analytics proving IE/Legacy Edge users.

---

## .well-known directory

The `/.well-known/` path prefix is reserved by RFC 8615 for standardized metadata files. Things that go here:

| Path | Purpose | Standard |
|---|---|---|
| `/.well-known/security.txt` | Vulnerability disclosure | RFC 9116 |
| `/.well-known/change-password` | Redirect to password change page | W3C spec |
| `/.well-known/openid-configuration` | OpenID Connect discovery | OpenID spec |
| `/.well-known/apple-app-site-association` | iOS Universal Links | Apple |
| `/.well-known/assetlinks.json` | Android App Links | Google |
| `/.well-known/acme-challenge/` | SSL certificate validation | Let's Encrypt |

For SaaS, you'll most commonly need `security.txt` and possibly `change-password` (which is just a 302 redirect to your actual password change URL — password managers use it).

---

## SEO for SaaS — what to index vs. what to hide

### The rule

**Index:** Marketing site, blog, docs, changelog, pricing, legal pages.
**Do not index:** The app itself, admin panels, auth flows, API endpoints, search results, user-generated content.

```html
<!-- On app pages behind auth -->
<meta name="robots" content="noindex, nofollow" />
```

Plus the `robots.txt` rules from earlier. Belt and suspenders — use both.

### Marketing pages vs. app pages

Your marketing site (`billflow.com/`) and your app (`billflow.com/app/` or `app.billflow.com`) should be treated as completely separate SEO surfaces:

| Concern | Marketing site | App |
|---|---|---|
| Rendering | SSR or SSG | CSR is fine |
| Meta tags | Full SEO tags on every page | `noindex, nofollow` |
| Sitemap | Yes | No |
| Structured data | Yes | No |
| OG images | Yes | No (it's behind auth) |
| robots.txt | Allow | Disallow |

If your marketing site and app share a domain (common with Next.js), use path-based rules. If they're separate subdomains, configure each independently.

### SSR / SSG for SEO

Search engines can render JavaScript, but they do it slowly and unreliably. For marketing pages and blog content:

- **Static Site Generation (SSG)** — best for SEO. Pre-rendered at build time, instant TTFB, cacheable at the edge. Use for blog posts, docs, changelog, landing pages.
- **Server-Side Rendering (SSR)** — use when content changes frequently or is personalized per request (pricing with geo-detection, localized content). Still sends full HTML to crawlers.
- **Client-Side Rendering (CSR)** — acceptable for authenticated app pages only. Do not use for any page you want indexed.

### Documentation as SEO strategy

Documentation is the highest-ROI SEO investment for SaaS. Developers search for technical problems, find your docs, discover your product.

- Every docs page is a potential landing page. Treat them as first-class content.
- Structure docs with clear heading hierarchy (`h1` = page title, `h2` = sections, `h3` = subsections).
- Include code examples — Google indexes code blocks and they appear in search.
- Add `Article` or `TechArticle` schema to docs pages.
- Cross-link heavily: every concept mentioned should link to its reference page.
- Keep docs on your domain (`billflow.com/docs`), not a separate domain. The SEO authority flows to your main domain.

### Blog strategy

Blog content targets informational search intent — people looking for answers, not products. The funnel: search -> article -> awareness -> conversion.

- **Hub-and-spoke model:** Create pillar pages ("Complete Guide to Freelance Invoicing") that link to 10-30 supporting articles ("How to Handle Late Payments", "Invoice Template for Designers"). This builds topical authority.
- **Update old posts.** A 2024 post updated in 2026 with current data outranks a new 2026 post on the same topic. Update the `dateModified` in schema.
- **Target long-tail keywords.** "How to send an invoice to international clients" has less competition and higher conversion intent than "invoicing software."

### Changelog as SEO content

Product changelogs are underrated for SEO:

- Each entry is a unique page with unique content.
- They demonstrate active development (trust signal).
- They attract searches for specific feature names.
- Add `Article` schema with `datePublished`.
- Provide an RSS feed of the changelog.

### Pricing page SEO

- Use `SoftwareApplication` schema with `Offer` details.
- Include FAQ schema for common pricing questions.
- Use clear heading hierarchy: `h1` = "Pricing", `h2` = plan names, `h3` = feature categories.
- Include pricing in the meta description — it's a differentiator in search results.
- Don't hide pricing behind "Contact Sales" if you have public plans. Google can't index what isn't on the page.

---

## Complete HTML head template

This is everything a public SaaS marketing page needs in `<head>`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <!-- SEO -->
  <title>Invoicing Software for Freelancers | Billflow</title>
  <meta name="description" content="Send professional invoices in 30 seconds. Track payments, automate reminders, get paid faster. Free for your first 5 clients." />
  <link rel="canonical" href="https://billflow.com/" />

  <!-- Open Graph -->
  <meta property="og:type" content="website" />
  <meta property="og:title" content="Invoicing Software for Freelancers" />
  <meta property="og:description" content="Send professional invoices in 30 seconds. Track payments, automate reminders, get paid faster." />
  <meta property="og:url" content="https://billflow.com/" />
  <meta property="og:image" content="https://billflow.com/og/home.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:site_name" content="Billflow" />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />

  <!-- Feeds -->
  <link rel="alternate" type="application/rss+xml" title="Billflow Blog" href="/feed.xml" />
  <link rel="alternate" type="application/json" title="Billflow Blog (JSON)" href="/feed.json" />

  <!-- Favicon -->
  <link rel="icon" href="/favicon.ico" sizes="32x32" />
  <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  <link rel="manifest" href="/manifest.webmanifest" />
  <meta name="theme-color" content="#4f46e5" />

  <!-- Structured data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "Billflow",
    "url": "https://billflow.com",
    "logo": "https://billflow.com/logo.png"
  }
  </script>
</head>
```

---

## Root-level files checklist

Every SaaS product should ship these files at the domain root:

| File | Priority | Purpose |
|---|---|---|
| `robots.txt` | Required | Controls crawler access |
| `sitemap.xml` | Required | Page index for search engines |
| `favicon.ico` | Required | Browser tab icon |
| `favicon.svg` | Required | Modern browser icon with dark mode |
| `apple-touch-icon.png` | Required | iOS home screen icon |
| `manifest.webmanifest` | Required | PWA metadata, Android icons |
| `llms.txt` | Recommended | AI model content directory |
| `feed.xml` | Recommended | RSS feed for blog/changelog |
| `feed.json` | Optional | JSON Feed alternative |
| `/.well-known/security.txt` | Recommended | Vulnerability disclosure |
| `humans.txt` | Optional | Team credits |
| `ads.txt` | Skip | Only for ad-supported sites |
| `browserconfig.xml` | Skip | Legacy Windows — PWA manifest replaces it |
