# Headers and Navigation

This file covers website headers and navigation — the top bar, nav links, mega menus, mobile menus, breadcrumbs, and responsive collapse behavior for public-facing sites, marketing pages, docs, and multi-page apps. Dashboard shell navigation (sidebar-based) is in `information-architecture.md`; this file is about the horizontal header pattern that sits at the top of every page on a traditional website.

Headers are the single most interacted-with UI region. Users touch them on every page. Get the header wrong — too tall, too cluttered, inaccessible, broken on mobile — and every page suffers. Get it right and the user never thinks about it.

**Canonical scope:** public-site headers, mega menus, mobile nav, footer design, responsive header collapse. **See also:** `information-architecture.md` for the dashboard sidebar shell, `marketing-and-landing-pages.md` for hero and landing-page patterns.

---

## Header layout

### Sticky vs static vs scroll-hide

There are three header behaviors. Pick one and commit.

| Behavior | How it works | When to use | Trade-off |
|---|---|---|---|
| **Static** | Header sits at the top, scrolls away with the page | Long-form content, blogs, documentation where vertical space matters more than persistent nav | Users must scroll to top to navigate. Fine for content sites with few nav needs. |
| **Sticky** | Header stays fixed at the top as user scrolls (`position: sticky; top: 0`) | Most marketing sites, SaaS landing pages, e-commerce, any site where the CTA must remain visible | Eats vertical space on every page. Must be slim. |
| **Scroll-hide** | Header hides on scroll-down, reveals on scroll-up | Best compromise for mobile and content-heavy sites. Used by Medium, dev.to, many news sites | Requires JavaScript. Slightly more complex but best UX for most sites. |

**Default recommendation: scroll-hide on mobile, sticky on desktop.** This gives desktop users persistent nav without eating mobile screen real estate.

#### Sticky header CSS

```css
.site-header {
  position: sticky;
  top: 0;
  z-index: 1000;
  /* Parent container must NOT have overflow: hidden — breaks sticky */
}
```

`position: sticky` has ~97% browser support. Prefer it over `position: fixed` — sticky participates in document flow so it doesn't require a spacer element to prevent content from jumping behind it.

#### Scroll-hide implementation

Use a scroll direction detector. Track `lastScrollY` and toggle a class:

```css
.site-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  transform: translateY(0);
  transition: transform 300ms ease-out;
}

.site-header.header--hidden {
  transform: translateY(-110%);
  /* -110% not -100% — accounts for any box-shadow or border */
}
```

```js
let lastScrollY = window.scrollY;
let ticking = false;

window.addEventListener('scroll', () => {
  if (!ticking) {
    requestAnimationFrame(() => {
      const header = document.querySelector('.site-header');
      const currentScrollY = window.scrollY;

      if (currentScrollY > lastScrollY && currentScrollY > 80) {
        header.classList.add('header--hidden');    // scrolling down
      } else {
        header.classList.remove('header--hidden'); // scrolling up
      }

      lastScrollY = currentScrollY;
      ticking = false;
    });
    ticking = true;
  }
});
```

The `currentScrollY > 80` threshold prevents the header from hiding when the user is near the top of the page. Adjust to match your header height.

**Alternative: IntersectionObserver sentinel.** Place an invisible 1px element at the top of the page. When it leaves the viewport, toggle the header state. Lighter than scroll listeners:

```js
const sentinel = document.querySelector('.header-sentinel');
const header = document.querySelector('.site-header');

new IntersectionObserver(([entry]) => {
  header.classList.toggle('header--scrolled', !entry.isIntersecting);
}).observe(sentinel);
```

### Header height

These are the proven ranges. Going outside them causes problems — too short and touch targets are cramped, too tall and you waste screen real estate.

| Context | Height | Notes |
|---|---|---|
| Desktop | 64–80px | 64px is the sweet spot for most sites. 80px if the logo needs breathing room. |
| Desktop (sticky, scrolled) | 48–64px | Shrink by 16px on scroll for density. Animate with `transition: height 200ms ease`. |
| Tablet | 56–72px | Usually same as desktop or slightly shorter. |
| Mobile | 48–60px | 56px is the standard. Never exceed 60px — mobile viewport is precious. |

**Critical rule: a sticky header must never exceed 20% of the viewport height.** On mobile at 667px viewport height, that means absolute max of ~133px — but aim for under 60px. Baymard research shows user satisfaction drops when sticky headers exceed this threshold.

```css
.site-header {
  height: 64px; /* desktop */
}

@media (max-width: 768px) {
  .site-header {
    height: 56px;
  }
}
```

### Logo placement and sizing

**Logo goes top-left. Always.** Left-aligned logos have near-universal recognition as the "home" link. Center-aligned logos work for fashion, editorial, and portfolio sites — nowhere else. If you're building a SaaS site, e-commerce, docs, or anything functional, the logo sits left.

| Guideline | Value |
|---|---|
| Logo max height | 32–40px (inside a 64px header, gives 12–16px breathing room top/bottom) |
| Logo area width | 120–200px (enough for most wordmarks) |
| Logo link target | Always wraps the logo in `<a href="/">` — the click area should be the full logo bounding box |
| Logo padding | 16–24px from left edge of header |

For sticky headers that shrink on scroll, scale the logo down proportionally — 40px in default state, 28–32px in compact state. Use `transition: height 200ms ease` for smooth scaling.

```html
<a href="/" class="site-logo" aria-label="Home">
  <img src="/logo.svg" alt="Company Name" height="36" width="120" />
</a>
```

Always set explicit `width` and `height` on the logo `<img>` to prevent layout shift (CLS).

### Content hierarchy in the header

The header has a fixed reading order. Do not rearrange it.

```
┌──────────────────────────────────────────────────────────────────┐
│ [Logo]     Primary Nav Links          [Search] [CTA] [Auth/Avatar] │
│  ← left                                               right →      │
└──────────────────────────────────────────────────────────────────┘
```

**Left zone:** Logo (always first). On mobile, this may be the only thing on the left side.

**Center zone:** Primary navigation. 5–7 top-level items max. This is the main nav.

**Right zone:** Actions, in this order:
1. Search (icon or bar)
2. CTA button ("Get Started", "Sign Up", "Try Free")
3. Auth state: logged out = "Log In" text link + "Sign Up" CTA; logged in = avatar/user menu

**Rules:**
- Do not put nav links on the right side and actions on the left. Users scan left-to-right: identity → navigation → actions.
- Do not mix navigation and actions in the same visual group. Separate them with space or a divider.
- The CTA button is visually distinct from nav links — it is a button, not a link. Primary fill color, stands out from the text links.

```css
.header-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  height: 64px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 32px; /* space between logo and nav */
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px; /* tighter spacing between action items */
}
```

### Transparent header over hero

Use transparent headers only on pages with a hero section (landing pages, homepages). The header overlaps the hero image/gradient with no background color, then gains a solid or blurred background on scroll.

```css
.site-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  background: transparent;
  transition: background-color 300ms ease, backdrop-filter 300ms ease;
}

.site-header.header--scrolled {
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: saturate(180%) blur(12px);
  -webkit-backdrop-filter: saturate(180%) blur(12px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}
```

**Dark hero gotcha:** If the hero is dark, header text and logo must be white/light over the hero, then switch to dark text when the background appears on scroll. Handle this with a class toggle:

```css
.site-header { color: white; }
.site-header.header--scrolled { color: var(--text-primary); }
```

Or use `color-scheme` and CSS custom properties for dark/light mode support with the `light-dark()` function:

```css
.site-header {
  background: light-dark(
    rgba(255, 255, 255, 0.85),
    rgba(10, 10, 10, 0.85)
  );
}
```

### z-index management

Header z-index must be lower than modals/dialogs but higher than page content.

| Layer | z-index |
|---|---|
| Page content | 1 (auto) |
| Sticky header | 1000 |
| Dropdown menus (child of header) | 1000 (inherits from header, uses DOM stacking) |
| Mobile menu overlay | 1100 |
| Modal backdrop | 1200 |
| Modal content | 1300 |
| Toast notifications | 1400 |
| Tooltip | 1500 |

**Rules:**
- Never use `z-index: 9999`. That's a sign of z-index wars. Use a deliberate scale.
- Define z-index as CSS custom properties for consistency:

```css
:root {
  --z-header: 1000;
  --z-mobile-menu: 1100;
  --z-modal-backdrop: 1200;
  --z-modal: 1300;
  --z-toast: 1400;
  --z-tooltip: 1500;
}
```

- Never set `overflow: hidden` on a parent of a sticky header — it breaks sticky positioning.
- Dropdowns that are children of the header inherit its stacking context. They don't need a separate z-index unless they must overlay sibling content.

### Backdrop-filter / glass effect headers

The frosted glass look (`backdrop-filter: blur()`) is the current standard for sticky headers on modern sites (Apple, Linear, Vercel, Stripe). It lets page content show through while keeping the header readable.

```css
.site-header {
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: saturate(180%) blur(12px);
  -webkit-backdrop-filter: saturate(180%) blur(12px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

/* Dark mode */
.dark .site-header {
  background: rgba(0, 0, 0, 0.72);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}
```

**Performance note:** `backdrop-filter` triggers compositing. Keep the header area small (slim height) and avoid applying it to large areas. On low-end mobile devices, it can cause jank — test on real hardware. Fallback for unsupported browsers:

```css
@supports not (backdrop-filter: blur(1px)) {
  .site-header {
    background: rgba(255, 255, 255, 0.97);
  }
}
```

---

## Navigation in the header

### Horizontal nav patterns

Primary navigation sits in the header as horizontal links. Three tiers:

1. **Simple links** — 3–7 text items, no dropdowns. Best for small sites. Clean, fast, accessible by default.
2. **Dropdown nav** — top-level items trigger dropdown panels with 3–10 sub-items. Standard for most SaaS and corporate sites.
3. **Mega menu** — top-level items trigger wide panels with multiple columns, images, featured content. For sites with 50+ pages organized in deep hierarchies (e-commerce, enterprise).

**Default recommendation: simple links or dropdown nav.** Use mega menus only when you have genuinely complex information architecture. Most sites that use mega menus would be better served by a simpler nav with a good search.

### Simple horizontal nav

```html
<nav aria-label="Main">
  <ul role="list">
    <li><a href="/products">Products</a></li>
    <li><a href="/pricing">Pricing</a></li>
    <li><a href="/docs">Docs</a></li>
    <li><a href="/blog">Blog</a></li>
    <li><a href="/about" aria-current="page">About</a></li>
  </ul>
</nav>
```

```css
.nav-links {
  display: flex;
  align-items: center;
  gap: 4px; /* gap between items; padding on each link provides the click target */
  list-style: none;
  margin: 0;
  padding: 0;
}

.nav-links a {
  display: flex;
  align-items: center;
  padding: 8px 16px;
  font-size: 0.875rem; /* 14px */
  font-weight: 500;
  color: var(--text-secondary);
  text-decoration: none;
  border-radius: 6px;
  transition: color 150ms ease, background-color 150ms ease;
}

.nav-links a:hover {
  color: var(--text-primary);
  background-color: var(--bg-subtle);
}

.nav-links a[aria-current="page"] {
  color: var(--text-primary);
  font-weight: 600;
}
```

**Item count rule: 5–7 top-level items max.** Nielsen Norman Group research consistently shows this as the sweet spot. Beyond 7, users struggle to scan. At 8+, move lower-priority items to a footer or "More" dropdown — but "More" is itself an anti-pattern (see anti-patterns section), so restructure the IA first.

### Dropdown menus

Dropdowns extend a top-level nav item with a panel of sub-items.

**Hover vs click trigger:**

| Trigger | Pros | Cons | Use when |
|---|---|---|---|
| **Hover** | Faster for mouse users, feels responsive | Accidental triggering, unusable on touch, accessibility harder | Desktop-only audience, simple dropdowns with few items |
| **Click** | Intentional, works on touch and keyboard, accessible by default | Slightly slower — one extra click | Any site with mobile users (so: every site) |

**Recommendation: click on mobile, hover-with-delay on desktop.** The hover delay is critical.

#### Hover delay timing (Baymard / NNg research)

- **Open delay:** 300–500ms after hover enters the trigger. This prevents accidental activation when the user is just passing the mouse over the nav. 60% of sites fail to implement this, causing the "flickering menu" problem.
- **Close delay:** 300–500ms after hover leaves both the trigger and the dropdown panel. This gives users a "grace period" to move the mouse diagonally from the trigger to the dropdown content without the menu snapping shut.
- **Display speed:** Once the delay threshold passes, the menu should appear in < 100ms (essentially instant). Do not add a slow fade-in after the delay — the delay *is* the buffer.

```css
.dropdown-panel {
  opacity: 0;
  visibility: hidden;
  transform: translateY(-4px);
  transition: opacity 150ms ease, transform 150ms ease, visibility 0s 150ms;
}

.nav-item:hover .dropdown-panel,
.nav-item:focus-within .dropdown-panel {
  opacity: 1;
  visibility: visible;
  transform: translateY(0);
  transition: opacity 150ms ease, transform 150ms ease, visibility 0s 0s;
}
```

Implement the 300ms hover delay in JavaScript — CSS `:hover` doesn't support delayed activation natively. Use `mouseenter` / `mouseleave` with `setTimeout` and clear the timer on re-entry.

#### Dropdown panel styling

```css
.dropdown-panel {
  position: absolute;
  top: 100%; /* flush with bottom of nav item */
  left: 0;
  min-width: 220px;
  max-width: 320px;
  padding: 8px;
  background: var(--bg-primary);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.04);
}

.dropdown-item {
  display: block;
  padding: 10px 12px;
  font-size: 0.875rem;
  color: var(--text-secondary);
  text-decoration: none;
  border-radius: 8px;
  transition: background-color 150ms ease;
}

.dropdown-item:hover {
  background-color: var(--bg-subtle);
  color: var(--text-primary);
}
```

#### Keyboard navigation for dropdowns

This is non-negotiable for accessibility. The pattern:

| Key | Action |
|---|---|
| `Enter` / `Space` | Open dropdown (on trigger), follow link (on item) |
| `Escape` | Close dropdown, return focus to trigger |
| `ArrowDown` | Move to next item in dropdown |
| `ArrowUp` | Move to previous item in dropdown |
| `Tab` | Move to next top-level nav item (close dropdown) |
| `Home` | Move to first item in dropdown |
| `End` | Move to last item in dropdown |

Use `aria-expanded="true|false"` on the trigger, `aria-haspopup="true"`, and `role="menu"` / `role="menuitem"` on the panel and items.

### Mega menus

Mega menus are full-width or near-full-width panels with multiple columns of links, organized by category. They are appropriate when:
- The site has 50+ pages in 5+ categories (e-commerce, enterprise software, universities)
- Users need to see all sub-options at once to choose between them
- Categories benefit from visual previews (product images, icons)

**Do not use mega menus on sites with fewer than 30 pages.** They add complexity for no benefit.

#### Mega menu grid layout

```css
.mega-menu {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  padding: 32px;
  background: var(--bg-primary);
  border-top: 1px solid var(--border-subtle);
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.1);
}

.mega-menu-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr); /* 4 columns for wide menus */
  gap: 32px;
  max-width: 1200px;
  margin: 0 auto;
}

/* For smaller menus, use 2–3 columns */
.mega-menu-grid--compact {
  grid-template-columns: repeat(3, 1fr);
  max-width: 900px;
}
```

#### Mega menu content structure

Each column is a category:

```html
<div class="mega-menu-column">
  <h3 class="mega-menu-heading">Products</h3>
  <ul>
    <li>
      <a href="/products/analytics" class="mega-menu-item">
        <span class="mega-menu-icon"><!-- svg --></span>
        <div>
          <span class="mega-menu-label">Analytics</span>
          <span class="mega-menu-desc">Track user behavior</span>
        </div>
      </a>
    </li>
    <!-- more items -->
  </ul>
</div>
```

**Rules:**
- Max 7–9 items per category column before cognitive load becomes an issue. If you have more, split into sub-categories or reconsider the IA.
- Include a "featured" area (right column or bottom row) for promoted content, new features, or key CTAs.
- Add icons/illustrations only if they genuinely aid scanning — decorative icons slow users down.
- Category headings should be clickable links to the category landing page, not dead text.
- Animate with `opacity` and `transform: translateY(-8px)` on open, 150–200ms duration.

### Navigation grouping

Structure nav into tiers based on priority:

| Tier | Location | Content | Item count |
|---|---|---|---|
| **Primary nav** | Header, center | Core pages users visit most (Products, Pricing, Docs, Solutions) | 5–7 max |
| **Secondary nav** | Footer, or collapsed under "More" | Supporting pages (About, Careers, Press, Partners, Legal) | No strict limit |
| **Utility nav** | Header, far right, above primary nav or inline | Actions and tools (Search, Language, Log In, Sign Up) | 2–4 |

On complex sites (enterprise, e-commerce), you may see a thin utility bar above the main header:

```
┌────────────────────────────────────────────────────────────┐
│ 🌐 EN  |  Support  |  Contact Sales  |  Log In            │  ← utility nav (32px)
├────────────────────────────────────────────────────────────┤
│ [Logo]      Products ▾   Solutions ▾   Pricing   Docs     │  ← primary header (64px)
└────────────────────────────────────────────────────────────┘
```

Utility nav bar: 28–36px tall, smaller text (12–13px), muted colors, right-aligned content. This is optional and adds height. Only use it if the site genuinely needs these items persistent and visible.

### Active state indicators

The current page's nav link must be visually distinct. Do not rely on color alone (WCAG 1.4.1). Combine at least two indicators:

| Indicator | CSS approach | Visual effect |
|---|---|---|
| **Font weight** | `font-weight: 600` on active | Bolder text stands out from 400/500 siblings |
| **Color** | `color: var(--text-primary)` vs `var(--text-secondary)` | Active is darker/more prominent |
| **Bottom border** | `border-bottom: 2px solid var(--brand-primary)` | Underline effect, classic and reliable |
| **Background** | `background-color: var(--bg-subtle)` | Pill/highlight effect |
| **Dot indicator** | `::before` pseudo-element, 6px circle below text | Minimal, modern — used by Vercel, Linear |

**Recommended default: font weight + color shift + bottom border.** This is the clearest, most accessible combination.

```css
.nav-links a[aria-current="page"] {
  color: var(--text-primary);
  font-weight: 600;
  position: relative;
}

.nav-links a[aria-current="page"]::after {
  content: '';
  position: absolute;
  bottom: -1px; /* aligns to header bottom edge */
  left: 16px;  /* matches link padding */
  right: 16px;
  height: 2px;
  background: var(--brand-primary);
  border-radius: 1px;
}
```

Use `aria-current="page"` in the HTML, not just a `.active` class. Screen readers announce it as "current page," which gives keyboard/assistive tech users the same orientation as sighted users.

### CTA button in the nav

The header CTA ("Get Started", "Sign Up", "Try Free") is the most important action on the page. It must visually break from the text links.

**Placement:** Far right of the header, after all nav links and the login link. Standard layout: `[nav links] ... [Log In] [Get Started button]`.

**Styling rules:**
- Use a solid filled button, not an outline button. Research shows solid buttons have higher click-through rates than outline/ghost buttons.
- Brand primary color background, white or contrast text.
- Same height as nav items (36–40px) but visually distinct through fill color and border-radius.
- `font-weight: 600`, slightly more prominent than nav link text.
- On mobile: the CTA should remain visible even when nav is collapsed. Place it next to the hamburger icon, or as the first/last item in the mobile menu.

```css
.header-cta {
  display: inline-flex;
  align-items: center;
  padding: 8px 20px;
  font-size: 0.875rem;
  font-weight: 600;
  color: white;
  background: var(--brand-primary);
  border-radius: 8px;
  text-decoration: none;
  transition: background-color 150ms ease;
  white-space: nowrap;
}

.header-cta:hover {
  background: var(--brand-primary-hover);
}
```

**Do not put two CTA buttons in the header.** If you have both "Log In" and "Sign Up", "Log In" is a text link or ghost button, and "Sign Up" is the filled CTA. Two filled buttons compete for attention and neither wins.

### Breadcrumbs

Breadcrumbs show the user's position in the site hierarchy. They are secondary navigation — they supplement the primary nav, never replace it.

**When to use:**
- Sites with 3+ levels of hierarchy (Category > Sub-category > Product)
- E-commerce (always)
- Documentation sites (always)
- Multi-level marketing sites (often)
- Single-level sites or flat sites with < 10 pages: skip breadcrumbs

**When to skip:**
- Homepage (no breadcrumb needed — you're at the root)
- Top-level pages that are direct children of home (optional, low value)

#### Breadcrumb markup

Use `<nav aria-label="Breadcrumb">` with an ordered list and JSON-LD for schema.org:

```html
<nav aria-label="Breadcrumb">
  <ol class="breadcrumbs">
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/analytics" aria-current="page">Analytics</a></li>
  </ol>
</nav>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com/" },
    { "@type": "ListItem", "position": 2, "name": "Products", "item": "https://example.com/products" },
    { "@type": "ListItem", "position": 3, "name": "Analytics", "item": "https://example.com/products/analytics" }
  ]
}
</script>
```

**Critical:** The visible breadcrumbs and the JSON-LD must match exactly. Discrepancies can cause Google to remove your rich results.

**Note:** As of January 2025, Google removed breadcrumbs from mobile search results. They still appear on desktop search results. Breadcrumbs remain valuable for on-site UX regardless of search display.

#### Breadcrumb styling

```css
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 4px;
  list-style: none;
  margin: 0;
  padding: 12px 0;
  font-size: 0.8125rem; /* 13px */
  color: var(--text-tertiary);
}

.breadcrumbs li + li::before {
  content: '/';
  margin-right: 4px;
  color: var(--text-quaternary);
}

.breadcrumbs a {
  color: var(--text-tertiary);
  text-decoration: none;
}

.breadcrumbs a:hover {
  color: var(--text-primary);
  text-decoration: underline;
}

.breadcrumbs [aria-current="page"] {
  color: var(--text-primary);
  font-weight: 500;
  pointer-events: none; /* current page is not a link */
}
```

**Separator options:** `/` (most compact, modern), `>` or `›` (classic, implies hierarchy), `chevron-right` SVG icon (visual polish). Pick one and use it site-wide. Avoid heavy decorative separators.

**Depth:** Keep breadcrumb trails to 3–5 levels. Beyond 5, truncate middle items with `...` and show first + last 2 levels:

```
Home / Products / ... / Enterprise / Analytics
```

---

## Mobile navigation

### Hamburger menu

The hamburger icon (three horizontal lines) triggers the mobile menu. It is the universal signifier for "menu" on mobile, recognized by virtually all users.

**Icon placement: top-right.** This is the dominant convention (iOS, Android, and the vast majority of websites). Top-left placement exists but is less common and conflicts with the logo position. Right-hand placement puts the icon in the thumb zone for right-handed users (the majority).

**Icon specifications:**
- Size: 24px icon inside a 44px minimum touch target (padding makes up the difference)
- Three lines: each 20px wide, 2px tall, spaced 6px apart vertically
- Color: match primary text color for visibility

#### Hamburger animation (to X)

Animate the hamburger to an X on open. This gives clear visual feedback that the menu is open and the icon will close it.

```css
.hamburger {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: 44px;
  height: 44px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
}

.hamburger-line {
  display: block;
  width: 20px;
  height: 2px;
  background: var(--text-primary);
  transition: transform 300ms ease, opacity 300ms ease;
}

.hamburger-line + .hamburger-line {
  margin-top: 6px;
}

/* X state */
.hamburger[aria-expanded="true"] .hamburger-line:nth-child(1) {
  transform: translateY(8px) rotate(45deg);
}

.hamburger[aria-expanded="true"] .hamburger-line:nth-child(2) {
  opacity: 0;
}

.hamburger[aria-expanded="true"] .hamburger-line:nth-child(3) {
  transform: translateY(-8px) rotate(-45deg);
}
```

```html
<button class="hamburger" aria-expanded="false" aria-controls="mobile-menu" aria-label="Menu">
  <span class="hamburger-line"></span>
  <span class="hamburger-line"></span>
  <span class="hamburger-line"></span>
</button>
```

### Mobile menu types

There are three common patterns. Pick based on content volume and site type.

#### 1. Slide-in drawer

The menu slides in from the right (or left) as an overlay panel. Most common pattern for websites.

```css
.mobile-menu {
  position: fixed;
  top: 0;
  right: 0;
  width: min(320px, 85vw); /* never wider than 85% of screen */
  height: 100dvh;
  background: var(--bg-primary);
  transform: translateX(100%);
  transition: transform 300ms ease-out;
  z-index: var(--z-mobile-menu);
  overflow-y: auto;
  padding: 72px 24px 24px; /* top padding clears the header */
}

.mobile-menu.is-open {
  transform: translateX(0);
}

.mobile-menu-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  opacity: 0;
  visibility: hidden;
  transition: opacity 300ms ease;
  z-index: calc(var(--z-mobile-menu) - 1);
}

.mobile-menu-backdrop.is-visible {
  opacity: 1;
  visibility: visible;
}
```

**Slide direction:** Right-to-left (slide from right) is the modern default and matches swipe-to-dismiss gestures. Left-to-right works too but feels dated.

**Width:** `min(320px, 85vw)`. Never 100% width — leave a visible strip of the backdrop so users understand they can tap outside to close.

#### 2. Full-screen overlay

The menu expands to fill the entire screen. Good for sites with minimal menu items where the menu itself is a design statement.

```css
.mobile-menu-fullscreen {
  position: fixed;
  inset: 0;
  background: var(--bg-primary);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: var(--z-mobile-menu);
  opacity: 0;
  visibility: hidden;
  transition: opacity 300ms ease;
}

.mobile-menu-fullscreen.is-open {
  opacity: 1;
  visibility: visible;
}

.mobile-menu-fullscreen a {
  font-size: 1.5rem; /* larger text for full-screen menus */
  font-weight: 600;
  padding: 16px;
}
```

The close button (X or hamburger-to-X) must remain in the same position as the hamburger trigger — typically top-right. Users expect to close the menu by tapping where they opened it.

#### 3. Bottom sheet / slide-up

The menu slides up from the bottom of the screen. Feels native on mobile. Good for app-like experiences.

```css
.mobile-menu-bottom {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  max-height: 85dvh;
  background: var(--bg-primary);
  border-radius: 16px 16px 0 0;
  transform: translateY(100%);
  transition: transform 300ms ease-out;
  z-index: var(--z-mobile-menu);
  overflow-y: auto;
  padding: 24px;
}
```

### Bottom navigation bar

A fixed bar at the bottom of the screen with 3–5 primary actions. This is an app-pattern — use it for PWAs and app-like websites, not for traditional content sites.

**When to use:**
- Progressive web apps
- SaaS dashboards on mobile
- Sites where users perform frequent, repeated actions
- Sites with 3–5 equally important top-level sections

**When NOT to use:**
- Marketing/brochure sites
- Blogs and editorial sites
- E-commerce product pages (the bottom bar competes with Add to Cart)

**Specs:**
- Height: 56–64px (matches mobile header height for visual balance)
- Items: 3–5. Never more than 5. At 6+ items, the icons become too small and labels get truncated.
- Touch targets: each item gets equal width (100% / item count), minimum 48px wide
- Icon + label: 24px icon above 10–12px label text, centered vertically
- Active state: icon filled + label bold + accent color. Inactive: icon outlined + muted label.
- Position: `position: fixed; bottom: 0;` with safe-area inset for phones with home indicator bars

```css
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 56px;
  padding-bottom: env(safe-area-inset-bottom);
  display: flex;
  align-items: center;
  justify-content: space-around;
  background: var(--bg-primary);
  border-top: 1px solid var(--border-subtle);
  z-index: var(--z-header);
}

.bottom-nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  flex: 1;
  padding: 8px 0;
  font-size: 0.625rem; /* 10px label */
  color: var(--text-tertiary);
  text-decoration: none;
}

.bottom-nav-item.is-active {
  color: var(--brand-primary);
  font-weight: 600;
}
```

**Thumb zone:** The bottom 1/3 of the screen is the easiest reach zone for one-handed use. Bottom nav leverages this — it's the most ergonomic placement for frequent actions. Redbooth saw a 65% increase in daily active users and 70% increase in session time after switching from hamburger menu to bottom tab bar.

### Mobile menu content decisions

Not everything in the desktop nav belongs in the mobile menu. Prioritize ruthlessly.

**Always include:**
- All primary nav items
- CTA button (prominent, often styled differently than in the menu list)
- Log in / Sign up or user account access

**Include if space allows:**
- Search (at the top of the mobile menu, as a search input)
- Language/region selector
- Key secondary nav items (About, Contact)

**Move to the footer or omit:**
- Utility links (Press, Careers, Legal, Terms)
- Social media links
- Exhaustive sub-navigation items — collapse into accordion sections if needed

### Touch targets

Minimum touch target size is **44x44px** (Apple HIG) or **48x48px** (Material Design). Use 48px as the safe default — it satisfies both guidelines.

```css
.mobile-nav-link {
  display: block;
  min-height: 48px;
  padding: 12px 16px;
  font-size: 1rem; /* 16px — larger than desktop nav for readability */
  line-height: 1.5;
}
```

**Spacing between adjacent touch targets: minimum 8px.** This prevents accidental taps on the wrong item. For nav items in a vertical list, the padding between items naturally provides this. For icon buttons in a row, add explicit gap.

---

## Responsive behavior

### Breakpoint strategy

Use three breakpoints that map to header behavior changes. Do not add more unless content demands it.

| Breakpoint | Range | Header behavior |
|---|---|---|
| **Mobile** | 0–767px | Hamburger menu, collapsed nav, icon-only actions, 48–56px header |
| **Tablet** | 768–1023px | Partial collapse — show 3–4 top nav items, collapse rest to "More" or hamburger. Or full hamburger at tablet too. | 
| **Desktop** | 1024px+ | Full horizontal nav, all items visible, full search bar, complete header |

The 1024px mark is the critical transition point in modern web development. Below it, assume touch-first interfaces. Above it, assume cursor-driven.

```css
/* Mobile-first: hamburger by default */
.desktop-nav { display: none; }
.hamburger { display: flex; }

/* Desktop: show full nav */
@media (min-width: 1024px) {
  .desktop-nav { display: flex; }
  .hamburger { display: none; }
}

/* Tablet: optional intermediate state */
@media (min-width: 768px) and (max-width: 1023px) {
  /* Show abbreviated nav or keep hamburger — decide per project */
}
```

### What collapses first

When moving from desktop to smaller screens, collapse in this priority order:

1. **Search bar** → icon (magnifying glass) that expands to a full-width search input on tap
2. **Secondary/utility nav items** → hidden, moved to mobile menu
3. **CTA button text** → shorter text or icon-only (but keep visible if possible)
4. **Primary nav links** → hamburger menu
5. **Logo** → smaller variant or icon-only logo mark (last resort)

**Search responsive pattern:**

```css
/* Desktop: full search bar */
.search-bar { display: flex; width: 280px; }
.search-icon-btn { display: none; }

/* Mobile: icon only */
@media (max-width: 1023px) {
  .search-bar { display: none; }
  .search-icon-btn { display: flex; }
}
```

On tap, the search icon expands to a full-width input overlaying the header:

```css
.search-expanded {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  padding: 0 16px;
  background: var(--bg-primary);
  z-index: 1;
}
```

### Auth/profile responsive pattern

| Desktop | Tablet | Mobile |
|---|---|---|
| "Log In" text link + "Sign Up" filled button | "Log In" + "Sign Up" (may shorten to "Start") | Avatar icon (logged in) or single "Sign Up" button (logged out) |
| Full user dropdown: name, email, avatar, menu items | Same as desktop | Avatar icon → tap → full account menu in slide-in drawer |

```css
/* Desktop: full buttons */
.auth-full { display: flex; }
.auth-compact { display: none; }

/* Mobile: compact */
@media (max-width: 767px) {
  .auth-full { display: none; }
  .auth-compact { display: flex; }
}
```

---

## Accessibility

Accessible navigation is not optional. It is the baseline. Every pattern in this file must implement these requirements.

### Semantic HTML

Use `<header>` for the page header and `<nav>` for navigation regions. If the page has multiple `<nav>` elements (primary nav, breadcrumbs, footer nav), label each with `aria-label`:

```html
<header class="site-header">
  <a href="/" class="site-logo" aria-label="Home">
    <img src="/logo.svg" alt="Company Name" height="36" width="120" />
  </a>

  <nav aria-label="Main">
    <!-- primary navigation -->
  </nav>

  <nav aria-label="Breadcrumb">
    <!-- breadcrumbs -->
  </nav>
</header>
```

Do not use `<nav>` for everything that contains links. Reserve it for major navigation blocks. A list of social links in the footer is not a `<nav>`.

### Skip navigation link

The first focusable element on the page must be a skip link that jumps past the header to the main content. Keyboard users and screen reader users should not have to tab through 15 nav links on every page load.

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <header>...</header>
  <main id="main-content">...</main>
</body>
```

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 16px;
  padding: 8px 16px;
  background: var(--brand-primary);
  color: white;
  font-size: 0.875rem;
  font-weight: 600;
  border-radius: 0 0 8px 8px;
  z-index: 2000; /* above everything */
  transition: top 200ms ease;
}

.skip-link:focus {
  top: 0;
}
```

The skip link is invisible until focused via keyboard Tab. This is WCAG 2.4.1 (Bypass Blocks) — required for Level A compliance.

### Keyboard navigation through dropdowns

Follow the WAI-ARIA menu pattern. The full keyboard contract:

| Key | Behavior |
|---|---|
| `Tab` | Moves between top-level nav items. Does not enter dropdowns. |
| `Enter` / `Space` | On a trigger with `aria-haspopup`: opens the dropdown, moves focus to first item. On a link: follows the link. |
| `Escape` | Closes the currently open dropdown. Returns focus to the trigger that opened it. |
| `ArrowDown` | Moves focus to the next item within the dropdown. |
| `ArrowUp` | Moves focus to the previous item within the dropdown. |
| `Home` | Moves focus to the first item in the dropdown. |
| `End` | Moves focus to the last item in the dropdown. |
| `ArrowRight` / `ArrowLeft` | In a menubar, moves between top-level items. |

**ARIA attributes on the trigger:**

```html
<button
  aria-expanded="false"
  aria-haspopup="true"
  aria-controls="dropdown-products"
>
  Products
  <svg class="chevron" aria-hidden="true"><!-- chevron-down --></svg>
</button>
```

Toggle `aria-expanded` between `"true"` and `"false"` when the dropdown opens/closes. Screen readers announce "Products, expanded" or "Products, collapsed."

### Focus management in mobile menu

When the mobile menu opens, focus must be trapped inside it. When it closes, focus must return to the trigger (hamburger button).

**Focus trap requirements:**
1. On open: move focus to the first focusable element inside the menu (typically the close button or first nav link)
2. While open: Tab cycles only through elements inside the menu — it does not escape to the page behind
3. On close (Escape key or close button): return focus to the hamburger button that opened the menu
4. The backdrop is inert: clicking it closes the menu but does not move focus to the page

```js
function openMobileMenu() {
  const menu = document.getElementById('mobile-menu');
  const firstFocusable = menu.querySelector('a, button');

  menu.classList.add('is-open');
  document.body.style.overflow = 'hidden'; // prevent scroll behind menu

  // Move focus into menu
  firstFocusable?.focus();

  // Trap focus
  menu.addEventListener('keydown', trapFocus);
}

function closeMobileMenu() {
  const menu = document.getElementById('mobile-menu');
  const trigger = document.querySelector('.hamburger');

  menu.classList.remove('is-open');
  document.body.style.overflow = '';

  // Return focus to trigger
  trigger.focus();

  menu.removeEventListener('keydown', trapFocus);
}

function trapFocus(event) {
  if (event.key !== 'Tab') return;

  const menu = event.currentTarget;
  const focusable = menu.querySelectorAll('a, button, input, [tabindex="0"]');
  const first = focusable[0];
  const last = focusable[focusable.length - 1];

  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}
```

Also add `inert` attribute to the page content behind the menu for thorough focus management:

```js
document.getElementById('page-content').setAttribute('inert', '');
// Remove on close:
document.getElementById('page-content').removeAttribute('inert');
```

### aria-current for active links

Mark the current page in navigation with `aria-current="page"`. This is announced by screen readers and provides a hook for CSS styling.

```html
<a href="/pricing" aria-current="page">Pricing</a>
```

Do not use `aria-selected` for navigation — that is for widget patterns like tabs. `aria-current="page"` is the correct attribute for page-level navigation.

### Screen reader announcements for menu state

When the mobile menu opens or closes, screen reader users need to know. The `aria-expanded` attribute on the hamburger button handles this — screen readers announce the state change. But also consider:

- Adding `aria-live="polite"` to a visually hidden status region that announces "Navigation menu opened" / "Navigation menu closed"
- Using `role="dialog"` on the mobile menu overlay with `aria-label="Navigation menu"` so screen readers announce the context

---

## Anti-patterns

These are the things NOT to do. Each one degrades usability, accessibility, or both.

### Too many nav items

**Problem:** More than 7 top-level items in the primary nav. Users can't scan them, and on tablet widths they overflow or get crushed into unreadable sizes.

**Fix:** Audit nav items. Move low-traffic items to the footer or a secondary nav. Use analytics to identify which items actually get clicked — most sites discover that 2–3 items get 80% of nav traffic.

### Hidden navigation on desktop

**Problem:** Using a hamburger menu on desktop to look "clean" or "minimal." Forces every user to click to see their options, reduces discoverability, and lowers engagement.

**Fix:** Show the full horizontal nav on desktop. The hamburger is a mobile compromise, not a desktop design choice. If you have too many items to show horizontally, fix the information architecture — don't hide it.

### Double navigation

**Problem:** A hamburger menu AND a bottom nav bar AND a sidebar, or any combination where the user has multiple, conflicting navigation paradigms on the same screen.

**Fix:** One primary navigation paradigm per viewport size. Desktop: horizontal header nav. Mobile: hamburger OR bottom bar, not both. If using bottom bar for primary nav, the hamburger (if present) handles secondary/overflow items only.

### Navigation that changes between pages

**Problem:** Nav items, their order, or the nav structure changes depending on which page the user is on. This destroys the user's spatial model of the site.

**Fix:** Navigation is consistent across every page. The only thing that changes is the active state indicator. If different sections of the site need different sub-navigation, use sub-nav within the content area — not in the global header.

### Oversized sticky headers

**Problem:** A sticky header that takes up 100–200px of vertical space, blocking content as the user scrolls. Often caused by combining logo + primary nav + utility bar + banner/announcement bar, all sticky.

**Fix:** Keep the sticky portion under 64px. If you have an announcement bar, make it dismissible and non-sticky. If you have a utility bar, make it scroll away — only the primary header should stick. On scroll, shrink the header to 48–56px.

### Hover-only dropdowns

**Problem:** Dropdown menus that only work on mouse hover. Broken on touch devices, broken for keyboard users, broken for screen readers.

**Fix:** Every dropdown must work with click/tap AND keyboard. Hover is an enhancement for mouse users on desktop — not the primary interaction model.

### Slow or janky menu animations

**Problem:** Menu animations that take 500ms+ to complete, use `left`/`top` instead of `transform`, or cause layout shifts.

**Fix:** Keep menu animations under 300ms. Use `transform: translateX()` and `opacity` for GPU-accelerated, jank-free animation. Never animate `width`, `height`, `left`, `top`, or `margin` — these trigger layout recalculation.

```css
/* BAD — triggers layout */
.menu { left: -100%; transition: left 300ms; }

/* GOOD — GPU composited */
.menu { transform: translateX(-100%); transition: transform 300ms; }
```

### No visible focus indicators

**Problem:** Removing the browser's default focus outline (`outline: none`) without replacing it with a visible custom focus style. Makes the site completely unusable for keyboard users.

**Fix:** Never remove focus outlines without replacing them. Use a visible, high-contrast focus indicator:

```css
:focus-visible {
  outline: 2px solid var(--brand-primary);
  outline-offset: 2px;
}
```

Use `:focus-visible` (not `:focus`) so the outline only shows for keyboard navigation, not mouse clicks.

### Logo that doesn't link home

**Problem:** The logo in the header is not a link, or links to somewhere other than the homepage. This violates one of the most deeply ingrained web conventions.

**Fix:** The logo always links to `/`. Always. Add `aria-label="Home"` to the link for screen readers.

### Dropdown menus that require pixel-perfect cursor paths

**Problem:** A dropdown that closes the instant the cursor leaves the trigger button, requiring users to move the cursor in a perfect vertical line to reach the dropdown content. This is the "diagonal problem" — users naturally move diagonally from the trigger to the sub-items.

**Fix:** Implement a 300–500ms close delay (see hover delay timing above). Or use the "triangle" or "safe zone" technique: calculate the triangle between the cursor position, the near edge, and the far edge of the dropdown, and keep the menu open while the cursor is within that zone. Amazon popularized this approach.

### Missing skip link

**Problem:** No skip navigation link, forcing keyboard users to tab through the entire header on every page load.

**Fix:** Add a skip link as the first focusable element. This is WCAG 2.4.1 Level A — the minimum compliance level. There is no excuse for omitting it.
