# Social Media Features

This file covers everything social-media-related a fullstack dashboard may need: social links and icons on marketing pages, sharing content from within a dashboard, social media management features (Hootsuite/Buffer-style), social login and profile display, social embeds and widgets, and platform-specific UX patterns. Each section gives concrete specs, component patterns, and implementation guidance.

Social features range from trivial (footer icons) to complex (multi-platform post composer). Build only what your product needs. Most dashboards need sections 1 and 2. Only social media management products need section 3.

---

## 1. Social media links and icons on marketing/landing pages

### Placement patterns

| Position | When to use | Notes |
|---|---|---|
| **Footer** | Default for every site | Standard location users expect. Place in a row, after copyright/legal links. |
| **Header** | Media companies, content-heavy sites | Only if social is core to the business. Competes with primary nav — use sparingly. |
| **Floating sidebar** | Blog posts, long-form content | Fixed position, left or right edge, vertically stacked. Hide on mobile or collapse to bottom bar. |
| **Inline (post footer)** | Blog posts, articles, case studies | Share buttons at the end of content. "Share this post" with platform icons. |

**Footer is the default.** Put social icons in the footer unless you have a specific reason for another placement. Users scroll down to find social links — it is a learned behavior.

### Icon libraries and sizing

**Recommended libraries:**
- **Lucide** — clean, consistent line icons. Missing brand icons (no Twitter, LinkedIn logos). Use for generic share/link icons.
- **Simple Icons** (`simple-icons` npm package) — 3000+ brand icons, SVG, always current. This is the go-to for platform logos.
- **react-icons** — aggregator wrapping Font Awesome, Simple Icons, and others. Convenient but larger bundle if not tree-shaken.
- **Brand assets directly** — each platform publishes official SVGs. Use these if brand guidelines require exact logos.

**Sizing spec:**

```
Icon: 20-24px (visual size)
Touch target: 40-44px minimum (WCAG / Apple HIG)
Gap between icons: 12-16px
Container padding: 8-12px around the icon
```

```html
<a
  href="https://linkedin.com/company/yourco"
  target="_blank"
  rel="noopener noreferrer"
  aria-label="Follow us on LinkedIn"
  class="inline-flex items-center justify-center w-10 h-10 rounded-lg
         text-muted-foreground hover:text-foreground hover:bg-muted
         transition-colors"
>
  <LinkedInIcon class="w-5 h-5" />
</a>
```

**Rules:**
- Always include `aria-label` — icons without visible text are invisible to screen readers.
- Always use `target="_blank"` with `rel="noopener noreferrer"` for external social links.
- Use monochrome icons by default (foreground color). Color-on-hover is acceptable. Avoid full-color brand icons in footers — they clash with your design system.
- Limit to 4-6 platforms maximum. More than that creates decision paralysis and looks cluttered.

### Platform ordering by audience type

Order icons by relevance to your audience. Lead with the platform where your audience is most active.

| Audience | Recommended order |
|---|---|
| **B2B / SaaS** | LinkedIn, X (Twitter), YouTube, GitHub |
| **B2C / Consumer** | Instagram, TikTok, Facebook, X, YouTube |
| **Developer tools** | GitHub, X (Twitter), Discord, YouTube, LinkedIn |
| **Creative / Design** | Instagram, Dribbble/Behance, X, YouTube, TikTok |
| **Local business** | Facebook, Instagram, Google Business, Yelp |

### When to show follower counts

- **Do show** if counts are impressive and establish credibility (50k+). Display as "50K followers" near the icon.
- **Don't show** if counts are low (<5K). An empty-looking count hurts more than it helps.
- **Dynamic counts** require API calls and caching. Most platforms rate-limit these. Cache for 1-24 hours.
- **On marketing pages:** show only in social proof sections, not next to nav icons.

### Social proof widgets

Social proof belongs on landing pages, not inside the dashboard.

**Testimonial cards:**

```
Layout: card with 1px border, 16px padding, border-radius 12px
Content: quote text (text-sm, italic), author name (font-medium),
         title + company (text-xs, muted), avatar (32px)
Grid: 3 columns desktop, 2 tablet, 1 mobile
Max visible: 6-9 testimonials, then "See all" link
Rotation: optional auto-rotate carousel (pause on hover, 5s interval)
```

**Logo bars (client logos):**

```
Layout: horizontal row, grayscale logos, uniform height (24-32px)
Opacity: 60% at rest, 100% on hover (subtle life)
Count: 5-8 logos. If more, use horizontal scroll or two rows.
Heading: "Trusted by" or "Used by teams at" — keep it short.
Position: below hero, above features. Or above CTA at page bottom.
```

Logo bars are the single fastest trust signal. A recognizable enterprise logo communicates years of validation in under a second.

**Review counts / ratings:**

```
"4.8/5 from 2,400+ reviews on G2" with G2 logo
Star icons: 16-20px, filled gold for full, half-filled, outline for empty
```

**Tweet/post embeds:** Use sparingly. Each embed loads platform JS (~200-500KB). Prefer screenshot images of tweets with a link, or use the facade pattern (section 5).

### Social share buttons on content pages

For blog posts and content pages, place share buttons at the end of the article (primary) and optionally as a floating sidebar (secondary).

**Implementation approach — use the Web Share API with fallback:**

```tsx
async function handleShare(data: { title: string; url: string; text?: string }) {
  if (navigator.canShare?.(data)) {
    await navigator.share(data);
  } else {
    // Fallback: show custom share modal with platform links
    openShareModal(data);
  }
}
```

**Fallback share links (no SDK needed):**

```
Twitter/X: https://twitter.com/intent/tweet?text={text}&url={url}
LinkedIn:  https://www.linkedin.com/sharing/share-offsite/?url={url}
Facebook:  https://www.facebook.com/sharer/sharer.php?u={url}
Reddit:    https://reddit.com/submit?url={url}&title={title}
Email:     mailto:?subject={title}&body={text}%0A{url}
Copy link: navigator.clipboard.writeText(url) with "Copied!" toast
```

**React library:** `react-share` provides pre-built share buttons and share counts for all major platforms. Good starting point, but adds bundle weight. For simple use cases, the intent URLs above are lighter.

### Open Graph images

Every page that might be shared needs Open Graph meta tags. Without them, shared links look like plain URLs.

**Required meta tags:**

```html
<meta property="og:title" content="Page Title — Brand" />
<meta property="og:description" content="Concise description, 60-160 chars" />
<meta property="og:image" content="https://yoursite.com/og/page-slug.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:url" content="https://yoursite.com/page-slug" />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Page Title" />
<meta name="twitter:description" content="Concise description" />
<meta name="twitter:image" content="https://yoursite.com/og/page-slug.png" />
```

**OG image spec:**

```
Dimensions: 1200 x 630 px (1.91:1 aspect ratio)
Format: PNG or JPEG, under 8MB (aim for <500KB)
Safe zone: keep text within center 1080 x 530 area (platforms crop edges)
```

**What to include on the OG image:**
- Page/post title (large, readable at thumbnail size — minimum 40px equivalent)
- Brand logo or wordmark (corner, subtle)
- Brand colors as background or accent
- Optional: author avatar, category label, illustration

**Dynamic OG image generation** (for blog posts, dashboards, shared reports):
- **Vercel OG** (`@vercel/og`) — generates images at the edge using React components + Satori. Fast, serverless.
- **Cloudinary** — URL-based text overlays on template images.
- **Puppeteer/Playwright** — screenshot an HTML template. Slower, more flexible. Run as a background job, cache the result.

Template approach: design a 1200x630 template in brand colors with placeholder zones for title and subtitle. Generate per-page images by filling in the text.

**Testing:** Use Facebook's Sharing Debugger, Twitter's Card Validator, and LinkedIn's Post Inspector to verify how your OG tags render before launch.

---

## 2. Social sharing from within a dashboard

This covers sharing dashboard content — reports, charts, views, links — with people inside and outside the product.

### Share button placement

Put a Share button in the toolbar/header of any shareable artifact: dashboards, reports, charts, saved views.

```
Icon: Share / ArrowUpFromSquare (Lucide) or platform share icon
Position: top-right toolbar, after Edit/Export, before Settings
Label: "Share" (always show text label, not icon-only for primary share)
```

### Share modal anatomy

When the user clicks Share, open a modal with these sections:

```
┌─────────────────────────────────────────────┐
│  Share "Q4 Revenue Report"              [X] │
├─────────────────────────────────────────────┤
│                                             │
│  Link access                                │
│  ┌─────────────────────────────────────┐    │
│  │ 🔒 Only people with access    [▼]  │    │
│  └─────────────────────────────────────┘    │
│  Options: Only people with access           │
│           Anyone in the organization        │
│           Anyone with the link (public)     │
│                                             │
│  Share with people                          │
│  ┌─────────────────────────────────────┐    │
│  │ Enter name or email...              │    │
│  └─────────────────────────────────────┘    │
│  Role: Viewer | Editor | Admin              │
│                                             │
│  ─── Or share via ───                       │
│                                             │
│  [ Copy link ]  [ Email ]  [ Slack ]        │
│                                             │
│  ─── Embed ───                              │
│                                             │
│  [ Copy embed code ]                        │
│  <iframe src="..." width="800"              │
│   height="450" frameborder="0" />           │
│                                             │
├─────────────────────────────────────────────┤
│  Currently shared with:                     │
│  👤 Jane Doe (Editor)          [Remove]     │
│  👤 Marketing Team (Viewer)    [Remove]     │
└─────────────────────────────────────────────┘
```

### Access control levels

| Level | Who can view | Use case |
|---|---|---|
| **Private** | Only the creator | Default for new dashboards |
| **Team/Org** | Anyone in the organization with the link | Internal sharing |
| **Specific people** | Named users/emails only | Controlled external sharing |
| **Public** | Anyone with the link, no login required | Embedding, public reports |

**Permission-aware sharing:** The share modal should only show options the current user's role allows. A Viewer cannot grant Editor access. An Editor cannot make content public if the org restricts it. Check permissions server-side, not just in UI.

### Link preview generation for shared content

When someone shares a dashboard link on Slack, email, or social media, it should render a rich preview — not a bare URL.

**Implementation:**

1. Create a dedicated `/share/{token}` route for shared content.
2. Generate OG meta tags dynamically based on the shared artifact:
   ```html
   <meta property="og:title" content="Q4 Revenue Report" />
   <meta property="og:description" content="Revenue dashboard shared by Jane Doe" />
   <meta property="og:image" content="https://app.co/api/og/share/abc123.png" />
   ```
3. Generate a screenshot of the dashboard/chart as the OG image (Puppeteer, Playwright, or html-to-image).
4. Cache the generated image. Regenerate on content update or on a schedule.

### Embed codes

For public or org-wide shared content, offer an embed snippet:

```html
<iframe
  src="https://app.yourproduct.com/embed/report/abc123"
  width="800"
  height="450"
  frameborder="0"
  style="border: 1px solid #e5e7eb; border-radius: 8px;"
  loading="lazy"
  allow="fullscreen"
></iframe>
```

**Embed route requirements:**
- Strip all app chrome (nav, sidebar, header). Show only the content.
- Respect the access level — if the embed is public, serve without auth. If org-only, show a login prompt or "Request access" message.
- Add a subtle "Powered by YourProduct" footer with a link back. This is free marketing.
- Support URL parameters for customization: `?theme=dark`, `?hide-title=true`, `?refresh=60` (auto-refresh interval in seconds).

### Screenshot / image export

Allow users to export charts and dashboards as images for sharing in presentations, emails, and social media.

**Implementation options:**
- **html-to-image** / **html2canvas** — client-side. Captures the DOM as PNG/JPEG. Fast, but limited by browser rendering quirks.
- **Puppeteer / Playwright** — server-side. Screenshot a headless browser rendering the content. More reliable, supports custom viewports.

**Export button placement:** in the chart/report toolbar, grouped with Download (CSV, PDF) and Print.

**Formats:** PNG (default, lossless, good for charts), JPEG (smaller, good for photos), SVG (vector, good for illustrations).

### Share analytics

Track who views shared links to prove ROI and detect unauthorized access.

**Data model:**

```sql
CREATE TABLE share_views (
  id UUID PRIMARY KEY,
  share_link_id UUID REFERENCES share_links(id),
  viewer_id UUID NULL,           -- null for anonymous/public views
  viewer_email VARCHAR(255) NULL, -- if captured via email gate
  ip_address INET,
  user_agent TEXT,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  duration_seconds INTEGER NULL
);
```

Show view counts and viewer list in the share modal: "Viewed 47 times by 12 people."

---

## 3. Social media management features

This section is for products that manage social media publishing — scheduling, composing, and analyzing posts across platforms. Think Hootsuite, Buffer, Sprout Social, Postiz (open-source).

### Post composer

The composer is the central feature. It must handle multiple platforms with different constraints simultaneously.

**Layout:**

```
┌──────────────────────────────────────────────┐
│  Platform selector                           │
│  [✓ X] [✓ LinkedIn] [✓ Instagram] [ Facebook]│
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ Write your post...                   │    │
│  │                                      │    │
│  │                                      │    │
│  │                                      │    │
│  └──────────────────────────────────────┘    │
│  📎 Media  😀 Emoji  # Hashtag  @ Mention   │
│                                              │
│  Character count: 142 / 280 (X)              │
│  ━━━━━━━━━━━░░░░░░░░░░░░░░░░░ 51%           │
│                                              │
├──────────────────────────────────────────────┤
│  Platform previews (tabs or side-by-side)    │
│  ┌────────────┐ ┌────────────┐               │
│  │  X preview │ │ LI preview │               │
│  │            │ │            │               │
│  └────────────┘ └────────────┘               │
├──────────────────────────────────────────────┤
│  Schedule: [Now ▼] or [Pick date/time]       │
│  [Post now]  [Schedule]  [Save draft]        │
└──────────────────────────────────────────────┘
```

**Platform-specific content:** Allow overriding text per platform. The base text is shared, but a user may want a shorter version for X and a longer version for LinkedIn. Store as:

```ts
interface PostDraft {
  baseText: string;
  platformOverrides: {
    twitter?: string;
    linkedin?: string;
    instagram?: string;
    facebook?: string;
    tiktok?: string;
  };
  media: MediaAttachment[];
  scheduledAt: Date | null;
  status: 'draft' | 'scheduled' | 'published' | 'failed';
}
```

### Character limits reference (2026)

Build character counters into the composer. Show remaining characters, warn at 90%, error at limit.

| Platform | Post limit | Effective limit (before truncation) | Bio limit |
|---|---|---|---|
| **X (Twitter)** | 280 (free) / 25,000 (Premium) | ~100 chars for peak engagement | 160 |
| **LinkedIn** | 3,000 (post) / 100,000 (article) | 1,800-2,100 for best performance | 2,600 |
| **Instagram** | 2,200 (caption) | 125 before "more" truncation | 150 |
| **Facebook** | 63,206 | 480 before "See more" truncation | 101 |
| **TikTok** | 4,000 (caption) | First 2-3 lines visible | 80 |
| **YouTube** | 5,000 (description) | 100 (title limit) | 1,000 (channel about) |
| **Pinterest** | 500 (description) | 100 (title) | 160 (profile) |
| **Threads** | 500 | Full text visible | 150 |

**Character counter component:**

```tsx
function CharacterCounter({ current, max, warnAt = 0.9 }: Props) {
  const ratio = current / max;
  const remaining = max - current;
  const color = ratio >= 1 ? 'text-destructive'
    : ratio >= warnAt ? 'text-warning'
    : 'text-muted-foreground';

  return (
    <div className="flex items-center gap-2">
      <div className="h-1.5 flex-1 rounded-full bg-muted overflow-hidden">
        <div
          className={cn("h-full rounded-full transition-all", {
            "bg-primary": ratio < warnAt,
            "bg-warning": ratio >= warnAt && ratio < 1,
            "bg-destructive": ratio >= 1,
          })}
          style={{ width: `${Math.min(ratio * 100, 100)}%` }}
        />
      </div>
      <span className={cn("text-xs tabular-nums", color)}>
        {remaining}
      </span>
    </div>
  );
}
```

### Image sizes per platform (2026)

Build auto-resizing into your media upload flow. Accept one image, generate platform-specific crops.

| Platform | Feed post | Story / Reel | Profile pic |
|---|---|---|---|
| **Instagram** | 1080x1080 (1:1), 1080x1350 (4:5), 1080x566 (1.91:1) | 1080x1920 (9:16) | 320x320 |
| **Facebook** | 1080x1350 (4:5), 1080x1080 (1:1) | 1080x1920 (9:16) | 170x170 |
| **X (Twitter)** | 1200x675 (16:9), 1080x1080 (1:1) | — | 400x400 |
| **LinkedIn** | 1200x1200 (1:1), 1200x627 (1.91:1) | — | 400x400 |
| **TikTok** | — | 1080x1920 (9:16) | 200x200 |
| **YouTube** | 1280x720 (16:9, thumbnail) | 1080x1920 (9:16, Shorts) | 800x800 |
| **Pinterest** | 1000x1500 (2:3) | 1080x1920 (9:16, Idea Pins) | 165x165 |

**Safe zone for 9:16 vertical content:** keep text and key visuals within the center 1080x1420 area. The top ~150px is covered by platform UI (username, back button), and the bottom ~350px is covered by captions, CTA buttons, and engagement icons.

**Universal safe bet:** 1080px wide, 4:5 (1080x1350) for feed posts, 9:16 (1080x1920) for vertical video.

### Content calendar

The calendar is the second most important feature after the composer.

**Views:**
- **Month view** — grid of days, each cell shows post count and color-coded dots per platform. Click a day to see posts.
- **Week view** — time slots, posts displayed as blocks. Drag-and-drop to reschedule.
- **Day view** — timeline with detailed post cards.
- **List view** — table/list of all scheduled posts with sort and filter.

**Post cards on calendar:**

```
┌─────────────────────────────┐
│ 🟦 LinkedIn  9:30 AM       │
│ "Excited to announce our..."│
│ 📷 1 image                  │
│ Draft | Scheduled | Posted  │
└─────────────────────────────┘
```

Color-code by platform (X = black, LinkedIn = blue, Instagram = gradient pink/purple, Facebook = blue, TikTok = teal/pink). Use the platform's brand color as the accent.

**Drag-and-drop rescheduling:** Drag a post card to a new time slot or day. Confirm the new time in a small popover before saving. Show timezone clearly.

### Post scheduling

**Date/time picker requirements:**
- Show user's local timezone prominently. Store all times as UTC.
- "Best time to post" suggestions based on historical engagement data or industry benchmarks.
- Timezone selector for teams across time zones. Show "9:00 AM EST (2:00 PM UTC)".
- Quick options: "Now", "Tomorrow at 9 AM", "Next Monday at 10 AM".
- Queue system: "Add to queue" places the post in the next available slot based on a posting schedule (e.g., weekdays at 9 AM, 12 PM, 5 PM).

### Platform API integration

Each social platform requires OAuth 2.0 connection, with platform-specific quirks.

**Connection flow:**

```
User clicks "Connect X account"
  > Redirect to platform OAuth consent screen
  > User authorizes your app
  > Platform redirects back with authorization code
  > Your server exchanges code for access + refresh tokens
  > Store tokens encrypted (AES-256) in database
  > Display connected account with profile pic + handle
```

**Token management:**

| Platform | Access token lifetime | Refresh mechanism |
|---|---|---|
| **X (Twitter)** | 2 hours | Refresh token (valid until revoked) |
| **LinkedIn** | 60 days | Refresh token (365-day lifetime) |
| **Instagram/Facebook** | 60 days (long-lived) | Exchange short-lived (1hr) for long-lived |
| **TikTok** | 24 hours | Refresh token (365-day lifetime) |
| **YouTube/Google** | 1 hour | Refresh token (no expiry unless revoked) |

**Token refresh strategy:**
- Proactively refresh tokens before expiry (refresh at 75% of lifetime).
- On any 401 response, attempt token refresh once, then retry the request.
- If refresh fails, mark the connection as "disconnected" and notify the user.
- Encrypt tokens at rest. Never log tokens. Never expose tokens to the client.

**Unified API services (alternative to direct integration):**
- **Ayrshare** — unified REST API for major platforms.
- **Upload-Post** — white-label social API.
- **Late (getlate.dev)** — unified social media API.

These handle OAuth flows, token storage, and platform quirks. Trade-off: cost and dependency vs. months of integration work.

### Analytics dashboard

Show engagement metrics per post, per platform, and over time.

**Key metrics per platform:**

| Metric | Description |
|---|---|
| **Impressions** | Times the post was displayed |
| **Reach** | Unique accounts that saw the post |
| **Engagement** | Likes + comments + shares + saves |
| **Engagement rate** | Engagement / reach (or impressions) as percentage |
| **Clicks** | Link clicks, profile clicks, media clicks |
| **Follower growth** | Net new followers in period |

**Dashboard layout:**
- Top: summary cards (total posts, total engagement, follower growth, best-performing post) for the selected period.
- Middle: line chart of engagement over time, with platform toggles.
- Bottom: table of individual posts sorted by engagement, with platform icon, preview text, and metrics columns.

### Team collaboration

**Approval workflow:**

```
Drafter creates post (status: Draft)
  > Submits for review (status: Pending Review)
  > Reviewer approves or requests changes
  > If approved: status moves to Scheduled
  > If changes requested: back to Draft with comments
```

**Roles:**
- **Drafter** — can create and edit drafts, submit for review.
- **Reviewer/Approver** — can approve, reject, or edit pending posts.
- **Publisher** — can publish directly without review.
- **Admin** — can manage connected accounts, team members, and settings.

### Media library

Centralized storage for images and videos used in social posts.

**Features:**
- Upload with drag-and-drop, bulk upload support.
- Auto-generate platform-specific crops (show crop preview per platform).
- Tag and search media by name, tag, date, or usage.
- Show where each asset was used (linked posts).
- Storage: use S3 or equivalent object storage. Generate presigned URLs for uploads. Serve through CDN.

**Supported formats:** JPEG, PNG, GIF, WebP for images. MP4, MOV for video. Check platform-specific requirements (e.g., Instagram requires H.264 MP4).

### Hashtag and mention management

**Hashtag features:**
- Hashtag suggestion based on post content and trending tags.
- Saved hashtag groups (e.g., "#marketing #saas #growth" saved as "Marketing Group").
- Hashtag performance tracking (which hashtags drive the most engagement).
- Auto-insert hashtag groups with one click.

**Mention autocomplete:**
- As user types `@`, show a dropdown of known accounts (team members, frequently mentioned accounts, followed accounts).
- Fetch suggestions from platform APIs where available.
- Store a local cache of frequently mentioned handles for fast lookup.

### RSS-to-social automation

Auto-generate social posts from RSS feed items.

**Flow:**
1. User adds an RSS feed URL.
2. System polls the feed on a schedule (every 15-60 minutes).
3. New items trigger a draft post with the item title, link, and optional excerpt.
4. Post is either auto-published (if configured) or added to the review queue.

**Configuration:**
- Template: `"New post: {title} {url} #blog"` with variable interpolation.
- Platform selection: which platforms to post to.
- Frequency cap: max posts per day from this feed.
- Deduplication: track published URLs to avoid reposting.

---

## 4. Social login and social profile display

### Social login implementation

**Provider selection by audience:**
- **B2B SaaS:** Google (required), Microsoft (for enterprise), GitHub (for dev tools), LinkedIn (optional).
- **B2C Consumer:** Google, Apple (required for iOS apps), Facebook, X.
- **Developer tools:** GitHub (primary), Google, GitLab.

**Don't offer more than 4 social login options.** Research shows too many choices increase abandonment. Pick 2-3 that match your audience.

**Button layout:**

```
┌──────────────────────────────────┐
│  ┌──────────────────────────┐    │
│  │ 🔵 Continue with Google  │    │
│  └──────────────────────────┘    │
│  ┌──────────────────────────┐    │
│  │ ⬛ Continue with GitHub   │    │
│  └──────────────────────────┘    │
│                                  │
│  ─────── or ───────              │
│                                  │
│  Email: [________________]       │
│  Password: [______________]      │
│  [Sign in]                       │
└──────────────────────────────────┘
```

**Rules:**
- Use official brand colors and logos for social buttons. Google's brand guidelines require specific button styling.
- Label format: "Continue with {Provider}" (not "Sign in with" — "continue" works for both signup and login).
- Social buttons go above the email/password form. They are the faster path — put them first.
- Show a divider ("or") between social and email options.

**What to auto-populate from social profile:**
- Display name, email, profile photo. Pre-fill during onboarding.
- Never auto-fill sensitive fields (billing, phone) from social data.

### Connected accounts management

In Settings > Connected Accounts, show all linked social providers with the ability to link/unlink.

```
┌─────────────────────────────────────────┐
│  Connected accounts                     │
├─────────────────────────────────────────┤
│  🟢 Google          jane@gmail.com      │
│     Connected       [Disconnect]        │
│                                         │
│  ⬛ GitHub          @janedoe            │
│     Connected       [Disconnect]        │
│                                         │
│  🔵 LinkedIn        Not connected       │
│                     [Connect]           │
└─────────────────────────────────────────┘
```

**Disconnect rules:**
- If the user has only one login method (social only, no password), prevent disconnecting it. Show: "Set a password before disconnecting your only login method."
- Show a confirmation dialog before disconnecting.
- Revoking a connection should delete stored tokens but preserve user data.

### User profile cards with social links

Display social links on user profile cards for community features, team directories, and public profiles.

```
┌──────────────────────────────────┐
│  [Avatar 48px]                   │
│  Jane Doe                        │
│  Product Designer at Acme        │
│                                  │
│  🔗 janedoe.com                  │
│  in  X  🐙                      │
│  (LinkedIn, X, GitHub icons)     │
└──────────────────────────────────┘
```

**Profile card spec:**
- Avatar: 48px (lg size), with status dot if applicable.
- Name: font-semibold, text-base.
- Title/company: text-sm, text-muted-foreground.
- Social icons: 16px, in a row, 8px gap, muted color, hover to brand color.
- Max 4 social links on the card. More in the full profile page.

### Team directory with social profiles

For team-facing features, show a directory of team members.

```
Table layout:
| Avatar | Name         | Role     | Email              | Social        |
|--------|-------------|----------|--------------------|-----------    |
| [32px] | Jane Doe    | Designer | jane@acme.com      | in  X  🐙    |
| [32px] | John Smith  | Engineer | john@acme.com      | 🐙  X        |
```

Or a grid of profile cards (3-4 columns) for a more visual layout.

### Social activity feeds

Show social activity within the dashboard — useful for community platforms, social apps, or team collaboration tools.

**Feed item anatomy:**

```
[Avatar 32px] Jane Doe · 2 hours ago
Shared "Q4 Revenue Report" with Marketing team
[Thumbnail of shared content]
  ♡ 3    💬 1    ↗ Share
```

Keep feed items compact. Use relative timestamps ("2h ago", not "April 12, 2026 at 2:47 PM"). Group related activities (e.g., "Jane and 3 others liked your report").

---

## 5. Social embeds and widgets

### Embedding social content

Embed tweets, LinkedIn posts, Instagram posts, YouTube videos, and TikTok videos within your app.

**The oEmbed protocol:**

oEmbed is a standard for fetching embed HTML from a URL. Send a GET request to the platform's oEmbed endpoint, receive HTML to render.

```
GET https://publish.twitter.com/oembed?url=https://twitter.com/user/status/123
Response: { "html": "<blockquote class=\"twitter-tweet\">...</blockquote>...", ... }
```

**Platform oEmbed endpoints:**

| Platform | oEmbed endpoint | Notes |
|---|---|---|
| **X (Twitter)** | `https://publish.twitter.com/oembed` | Returns blockquote + script tag |
| **YouTube** | `https://www.youtube.com/oembed` | Returns iframe |
| **Instagram** | `https://graph.facebook.com/v18.0/instagram_oembed` | Requires app token |
| **TikTok** | `https://www.tiktok.com/oembed` | Returns blockquote + script |
| **LinkedIn** | No public oEmbed | Use LinkedIn's share plugin or screenshot |
| **Spotify** | `https://open.spotify.com/oembed` | Returns iframe |

### Performance impact and the facade pattern

Social embeds are expensive. A single YouTube embed loads ~750KB. A Twitter embed loads ~200-500KB of JS. Multiple embeds on one page can add megabytes of third-party scripts.

**The facade pattern:** Replace the live embed with a static placeholder (facade) that looks like the embed. Load the actual embed only when the user clicks or scrolls it into view.

**YouTube facade example:**

```tsx
function YouTubeFacade({ videoId, title }: Props) {
  const [loaded, setLoaded] = useState(false);
  const thumbUrl = `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`;

  if (loaded) {
    return (
      <iframe
        src={`https://www.youtube-nocookie.com/embed/${videoId}?autoplay=1`}
        title={title}
        allow="autoplay; encrypted-media"
        allowFullScreen
        className="aspect-video w-full rounded-lg"
      />
    );
  }

  return (
    <button
      onClick={() => setLoaded(true)}
      className="relative aspect-video w-full rounded-lg overflow-hidden
                 group cursor-pointer"
      aria-label={`Play: ${title}`}
    >
      <img src={thumbUrl} alt="" className="w-full h-full object-cover" />
      <div className="absolute inset-0 flex items-center justify-center
                      bg-black/20 group-hover:bg-black/30 transition-colors">
        <PlayIcon className="w-16 h-16 text-white drop-shadow-lg" />
      </div>
    </button>
  );
}
```

This saves ~750KB per YouTube embed until the user actually wants to watch.

**Facade libraries:**
- **lite-youtube-embed** — web component, 100x faster than default YouTube embed.
- **lite-vimeo-embed** — same pattern for Vimeo.
- Build custom facades for Twitter/X: render a styled blockquote with the tweet text and a "Load tweet" button.

**Lazy loading strategy:**
1. Use `loading="lazy"` on iframes.
2. Use Intersection Observer to load embeds when they enter the viewport.
3. For heavy pages (10+ embeds), use virtual scrolling — only render embeds in/near the viewport.

### Social feed widgets

Show a live feed from a social platform within your site.

**Options:**
- **Platform widgets** (Twitter timeline widget, Facebook Page Plugin) — easy but add third-party JS and limited customization.
- **API-powered custom feeds** — fetch posts via platform API, render with your own components. Full control, but requires API access and token management.
- **Aggregator services** (Curator.io, Juicer, Tagembed) — pull from multiple platforms, provide embeddable widgets. Good for marketing pages.

Prefer API-powered custom feeds for dashboard features and aggregator services for marketing pages.

### Comment systems

If your dashboard needs user comments (on reports, articles, knowledge base pages), here are the options:

| System | Type | Notes |
|---|---|---|
| **Custom-built** | Self-hosted | Full control. Table: comments(id, user_id, content, parent_id, created_at). Threaded via parent_id. |
| **Giscus** | GitHub Discussions-backed | Free, no tracking, supports reactions and threading. Best for developer-facing sites. |
| **Utterances** | GitHub Issues-backed | Simpler than Giscus, no threading. Lightweight. |
| **Isso** | Self-hosted Python | Lightweight Disqus alternative. SQLite storage. |
| **Commento** | Self-hosted or managed | Privacy-focused, ~11KB. Paid managed option. |

**Avoid Disqus** for new projects. It injects ads, tracks users, and loads excessive third-party scripts.

**Custom comment data model:**

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_type VARCHAR(50) NOT NULL,    -- 'report', 'dashboard', 'article'
  artifact_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id),
  parent_id UUID REFERENCES comments(id), -- null for top-level, set for replies
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL             -- soft delete
);

CREATE INDEX idx_comments_artifact ON comments(artifact_type, artifact_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);
```

---

## 6. Social media-specific UX patterns

### Mention and tag autocomplete

When a user types `@` in the composer, show an autocomplete dropdown.

**Behavior:**
- Trigger on `@` character typed after a space or at the start of input.
- Show dropdown with matching accounts: avatar (24px), display name, handle.
- Keyboard navigation: arrow keys to move, Enter to select, Escape to dismiss.
- Insert the mention as a styled chip/pill in the composer, stored as `@[handle]` or `@[user_id]` in the data model.
- Debounce API calls: 300ms after last keystroke.

**Data source priority:**
1. Recently mentioned accounts (local cache).
2. Team members / contacts.
3. Platform API search (if available and rate limits allow).

### Emoji picker

Use a library — don't build this from scratch.

**Recommended:**
- **emoji-mart** (`@emoji-mart/react`) — Slack-style picker. Full categorization, search, skin tone support, frequently used tracking. The most complete option.
- **emoji-picker-react** — lighter alternative, good React hooks integration.
- **Frimousse** — minimal, from Liveblocks. Good for chat-style UIs.

**Integration:**

```tsx
import data from '@emoji-mart/data';
import Picker from '@emoji-mart/react';

<Picker
  data={data}
  onEmojiSelect={(emoji) => insertAtCursor(emoji.native)}
  theme="auto"        // respects system dark mode
  previewPosition="none"
  skinTonePosition="search"
  maxFrequentRows={2}
/>
```

**Placement:** trigger via a smiley icon button in the composer toolbar. Open as a popover anchored to the button, not a modal.

**Size:** the picker is typically 352x435px. On mobile, open as a bottom sheet.

### Preview rendering

Show the user how their post will look on each platform before publishing.

**Implementation approach:**
- Build a preview component per platform that mimics the platform's visual style.
- Show platform-specific UI chrome: avatar, name, handle, timestamp, action buttons (like/comment/share).
- Render the post text with platform-specific truncation (e.g., Instagram truncates after 125 chars with "... more").
- Show attached media at the correct aspect ratio per platform.

**Layout:** tabs (one platform per tab) or side-by-side panels (2 platforms visible at once). Tabs scale better with many platforms.

**Key rendering differences to mimic:**
- **X:** compact layout, 280 char visible, link card preview, rounded media corners.
- **LinkedIn:** wider layout, "... see more" after ~210 chars in feed, link preview below text.
- **Instagram:** square/portrait image dominant, caption below, truncated after 125 chars.
- **Facebook:** text above media, "See more" after ~480 chars.

### Link shortening and UTM parameter management

**UTM parameters:**

Every link shared to social media should have UTM tags for attribution tracking.

```
https://yoursite.com/feature?
  utm_source=linkedin&
  utm_medium=social&
  utm_campaign=product-launch-2026&
  utm_content=feature-announcement
```

**Standard parameter mapping:**

| Parameter | Value | Purpose |
|---|---|---|
| `utm_source` | Platform name (linkedin, twitter, facebook) | Where the click came from |
| `utm_medium` | `social` (always, for social posts) | Marketing channel type |
| `utm_campaign` | Campaign slug (product-launch-q2) | Which campaign |
| `utm_content` | Post variant identifier | A/B test or content variant |

**UTM builder UI:** auto-generate UTM parameters based on the selected platform and campaign. Store campaign names for reuse. Show the full URL with UTMs in a preview.

**Link shortening:**
- Use a service: Bitly, Dub (open-source), short.io, or your own domain (`go.yourco.com/abc`).
- Shorten after adding UTMs so the UTMs are preserved but the URL is clean.
- Short links also provide click tracking independent of UTM/analytics.

**Auto-shorten in composer:** when a user pastes a URL, offer to shorten it. Or auto-shorten all URLs in scheduled posts. Show both the short URL and the destination URL.

---

## Implementation priority

For most dashboards, build in this order:

1. **OG meta tags and social icons** — near-zero effort, high ROI for any site.
2. **Share modal with copy link** — basic sharing for dashboard content.
3. **Social login** — reduces signup friction, most auth libraries support this out of the box.
4. **Embed codes** — if customers need to embed your content.
5. **Social proof widgets** — for marketing/landing pages.
6. **Social media management** — only if your product is a social media tool.

Build the simple things first. Social login with Google takes an afternoon. A full post composer with multi-platform preview takes months.
