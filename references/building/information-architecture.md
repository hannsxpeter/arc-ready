# Information Architecture

The shell of a dashboard — the layout, navigation, header, sidebar, breadcrumbs, page structure — is where convention is your friend. Users learn dashboards by transferring expectations from every other dashboard they've used. Deviating from the conventions costs more than it gains. This file is the rules for the shell.

**Canonical scope:** dashboard shell layout, sidebar nav, breadcrumbs, responsive collapse, grid systems, page structure. **See also:** `headers-and-navigation.md` for public-site horizontal headers and footers, `ui-design-patterns.md` for components and design tokens.

## Quick decision: which layout?

```
How many pages?     User's primary task?          → Layout
─────────────────────────────────────────────────────────────
1 page              View/monitor                  → Content only (no sidebar)
2–5, flat           Short labels, won't grow      → Top nav + content
2–5, flat           Will grow past 6              → Sidebar + content
5+, or sub-pages    Navigate between sections     → Sidebar + content (default)
Any count           Select-from-list + details    → Three-pane (master-detail)
Any count           Side-by-side comparison       → Split pane (resizable)
N/A                 Monitor only, no interaction  → Full-bleed / no chrome
Detail pages        3–7 facets per entity         → Sidebar + tabs in content
```

**Default when unsure:** Sidebar + content. It handles growth, supports sub-nav, and matches user expectations from every other dashboard. Detailed descriptions of each layout are below.

## The canonical layout

Adopt this layout unless the domain demands otherwise. It is the convention used by Stripe, Linear, Notion, Vercel, GitHub, GitLab, AWS, Datadog, Tableau, Power BI, Looker, Mixpanel, Segment, Asana, Jira, Atlassian, ServiceNow, Salesforce, HubSpot, Intercom, Shopify admin, Airtable, Retool, Metabase, and roughly every internal tool you've used.

```
┌─────────────────────────────────────────────────────────────┐
│ [LOGO]   ┊ optional global search ┊         [user menu ▾]  │  ← header (56–64px)
├──────────┬──────────────────────────────────────────────────┤
│          │  Breadcrumbs > nested > location                 │
│ Sidebar  │  ┌──────────────────────────────────────────┐    │
│  nav     │  │  Page header                              │    │
│          │  │  Page title          [primary action ▸]   │    │
│  240px   │  │  optional subtitle / description          │    │
│          │  └──────────────────────────────────────────┘    │
│  collap- │                                                    │
│  sible   │  Main content area                                 │
│  to 64px │                                                    │
│          │                                                    │
│          │                                                    │
│          │                                                    │
└──────────┴──────────────────────────────────────────────────┘
```

### Why this layout

- **Logo top-left**: where everyone looks first. Click → home. Anchors brand identity.
- **User menu top-right**: where everyone goes for "log out" and "settings." Standard since at least Gmail (2004).
- **Sidebar left**: vertical lists scale better than horizontal ones. You can fit 12 nav items on a sidebar; you cannot fit 12 on a topbar.
- **Persistent sidebar, not hamburger**: on desktop, hiding nav behind a click is friction. The sidebar collapses to icons on narrow screens, to a drawer on mobile — but on a typical 1440px monitor, it stays open.
- **Content area on the right**: gets the most pixels because it's where work happens.
- **Breadcrumbs above the page header**: orient the user inside hierarchy. Skip on top-level pages; use on every nested page.
- **Page header inside the content area**: title, subtitle, primary action button. Same shape on every page so the eye knows where to land.

### Dimensions that work

- Header: 56–64px tall
- Sidebar: 240–280px wide expanded, 56–64px collapsed
- Content max width: 1280–1440px (centered) or full-width depending on density needs — full-width for tables and dashboards, centered for forms and reading
- Page padding: 24–32px on desktop, 16px on mobile
- Section spacing: 24–32px between major sections, 12–16px between rows

## Layout patterns

The canonical layout (sidebar + content) is the default, but it's not the only valid layout. Different workflows demand different spatial arrangements. Pick the layout that matches the user's primary task, not the one that looks most impressive.

### 1. Sidebar + Content (the default)

```
┌──────────┬───────────────────────────────────────────┐
│          │                                           │
│ Sidebar  │  Content area                             │
│  nav     │                                           │
│          │                                           │
│  240px   │  Fills remaining width                    │
│          │                                           │
└──────────┴───────────────────────────────────────────┘
```

**When:** The dashboard has 5+ pages, persistent navigation matters, and the user's job is "go to a page, do work, go to another page." This is ~70% of dashboards: admin panels, SaaS back-offices, internal tools, settings-heavy apps.

**Why it works:** Vertical nav scales to 12+ items. The sidebar is always visible so the user never loses orientation. Content gets the majority of screen real estate.

### 2. Sidebar + Content + Right panel (three-pane / master-detail)

```
┌──────────┬──────────────────────────┬───────────────┐
│          │                          │               │
│ Sidebar  │  Main content            │  Context      │
│  nav     │  (list, conversation,    │  panel        │
│          │   document)              │  (details,    │
│  240px   │                          │   properties, │
│          │  Fills middle            │   activity)   │
│          │                          │  280-360px    │
└──────────┴──────────────────────────┴───────────────┘
```

**When:** The user's job is "scan a list, select an item, see details about it without leaving the list." This is the natural layout for:
- **Email / messaging** — inbox left, message center, conversation details right
- **Helpdesk / ticketing** — ticket queue left, ticket content center, customer context right
- **CRM** — contact list left, contact detail center, activity/notes right
- **Chat / AI conversations** — conversation list left, chat center, context/settings right
- **IDE-style builders** — file tree left, editor center, properties/preview right
- **Document management** — folder tree left, document center, metadata right

**Rules:**
- The right panel is **contextual** — it shows information about whatever is selected in the main content. When nothing is selected, it either hides or shows a "select an item" prompt.
- The right panel is **collapsible** — a toggle button (or keyboard shortcut) hides it so the main content gets full width. Power users toggle constantly.
- On **tablet** (~1024px), collapse the right panel by default and show it as an overlay when triggered.
- On **mobile** (<768px), the three panes become a stack: the list is page 1, selecting an item navigates to page 2 (content), and the context panel is a slide-up sheet or a tab within the content.
- The right panel should be **resizable** when the content varies in density (wide for CRM contact timelines, narrow for simple metadata). A drag handle on the left edge of the panel. Persist the width in localStorage.
- **Don't put navigation in the right panel.** The right panel is context, not nav. Navigation lives in the sidebar (left) only.

**Common mistake:** Making all three panes equal width. The main content should always get the most space. A 240/flex/320 split is a good starting point.

### 3. Content only (no sidebar)

```
┌─────────────────────────────────────────────────────┐
│ [Logo]  optional tabs/breadcrumbs     [user menu]   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Content area (full width or centered max-width)    │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**When:** The dashboard has 1-3 pages, or the user is in a focused flow where navigation is a distraction:
- **Single-screen analytics** — one page with filter bar and charts. Nav is unnecessary.
- **Wizard / onboarding flows** — linear progression with a step indicator, not a sidebar.
- **Checkout / payment flows** — focused, distraction-free, no sidebar.
- **Embedded dashboards** — the host app already has nav. Don't duplicate.
- **Public-facing dashboards** — status pages, analytics portals, read-only reports.
- **Settings pages** (when standalone) — the settings page itself has internal nav (vertical tabs on the left of the content area, not a full sidebar).

**Rules:**
- If there are 2-3 pages, use **tabs or a minimal top nav** inside the header instead of a sidebar.
- Center the content at a max-width of 800-1200px for readability. Full-bleed content is harder to scan.
- Always keep the header with logo + user menu for orientation.

### 4. Top nav + Content

```
┌─────────────────────────────────────────────────────┐
│ [Logo]  Dashboard  Reports  Settings     [user ▾]   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Content area                                       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**When:** The dashboard has 3-6 pages with short labels and no sub-navigation. Works for:
- **Simple dashboards** — a landing page, a reports page, a settings page. Three items fit comfortably in a top bar.
- **Customer portals** — end-user-facing, lighter UI, fewer features than an admin panel.
- **Marketing / analytics dashboards** — overview, campaigns, audience, reports.

**Rules:**
- **Maximum 6 items** in the top nav. Beyond that, the horizontal space runs out and the nav wraps or truncates. Switch to a sidebar.
- Top nav items don't support sub-menus well — dropdowns in horizontal nav are clunky. If any item has children, use a sidebar instead.
- On mobile, the top nav collapses into a hamburger menu (same as sidebar-to-drawer).
- Active state is a bottom border or background fill on the active item.

**When NOT:** If the dashboard will grow beyond 6 pages, start with a sidebar. Migrating from top nav to sidebar later is a layout rewrite that touches every page.

### 5. Full-bleed / no chrome

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Widgets, tiles, charts fill the entire screen      │
│  No header, no sidebar, no padding                  │
│                                                     │
│  Optimized for large screens / TV displays          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**When:** The user monitors, not navigates:
- **NOC / operations dashboards** — on a wall-mounted TV showing server health, uptime, alerts. No one clicks anything; they watch.
- **Kiosk mode** — retail displays, restaurant order status boards, airport departure boards.
- **Presentation / projection** — a dashboard projected during a standup or all-hands meeting.
- **TV dashboards** — Grafana-style boards for engineering teams.

**Rules:**
- No header, no sidebar, no user menu. The entire viewport is content.
- Design for **distance readability** — larger fonts (18-24px minimum), high contrast, minimal text, big numbers.
- Auto-refresh or stream data. The user can't interact.
- If the user also needs a navigable version (they usually do), build full-bleed as a **mode toggle** or a separate `/tv` route on top of the standard layout. Don't build two separate dashboards.
- Include a subtle "last updated" timestamp somewhere so watchers know the data is fresh.

### 6. Split pane (resizable)

```
┌──────────────────────────┬──────────────────────────┐
│                          │                          │
│  Left pane               │  Right pane              │
│                          │                          │
│  (source, before,        │  (target, after,         │
│   editor, original)      │   preview, translated)   │
│                          │                          │
│          ←  drag handle  →                          │
└──────────────────────────┴──────────────────────────┘
```

**When:** The user's job is side-by-side comparison or synchronized editing:
- **Diff / version comparison** — old version left, new version right, with synchronized scrolling.
- **Code editors** — source left, preview right (or editor + terminal).
- **Translation workflows** — source language left, target language right.
- **Content preview** — editor left, rendered preview right (CMS, email builder, markdown).
- **Reconciliation** — bank statement left, ledger entries right, drag to match.
- **Before/after** — original data left, transformed data right.

**Rules:**
- The divider between panes is **draggable**. Persist the position in localStorage.
- Support a **keyboard shortcut to equalize** the split (50/50) or maximize one pane.
- **Synchronized scrolling** is expected when the content in both panes corresponds line-by-line (diffs, translations). Make it toggleable.
- On mobile, split panes don't work. Stack them vertically or use tabs ("Source" / "Preview").
- The split can be **horizontal** (top/bottom) for some workflows — terminal output below editor, for example. Offer orientation toggle if both make sense.

### 7. Sidebar + Tabs in content

```
┌──────────┬───────────────────────────────────────────┐
│          │  Entity name              [Edit] [⋯]      │
│ Sidebar  │  Overview · Orders · Billing · Activity   │
│  nav     │  ┌───────────────────────────────────────┐│
│          │  │  Tab content                          ││
│          │  │                                       ││
│          │  └───────────────────────────────────────┘│
└──────────┴───────────────────────────────────────────┘
```

**When:** A detail page has 3-7 facets that the user switches between. This is the standard detail page layout, not really a separate layout pattern — but it's worth calling out because it's often implemented badly.

**Rules:**
- Tabs are **inside the content area**, not in the sidebar. The sidebar still shows the global nav with the parent page highlighted.
- **Tabs route to URLs** — `/customers/123/orders`, `/customers/123/billing`. Not client-side-only tab state. This makes tabs shareable and reload-safe.
- The active tab is **visually distinct** (bottom border is the convention).
- On mobile, tabs become a **scrollable horizontal strip** or a **dropdown select**. Don't wrap tabs to multiple lines.
- **Don't use tabs for more than 7 items.** Beyond that, use a secondary sidebar inside the content area (the settings pattern) or group tabs into sections.

### Choosing the right layout

```
How many pages does the dashboard have?
│
├── 1 page
│   └── Content only (no sidebar)
│
├── 2-5 pages, flat (no sub-pages)
│   ├── Labels are short → Top nav + Content
│   └── Labels are long or will grow → Sidebar + Content
│
├── 5+ pages or pages with sub-pages
│   └── Sidebar + Content (the default)
│
├── User's job is "select from list, see details"
│   └── Sidebar + Content + Right panel (three-pane)
│
├── User's job is side-by-side comparison
│   └── Split pane
│
├── User monitors, doesn't navigate
│   └── Full-bleed / no chrome
│
└── Detail pages with 3-7 facets
    └── Sidebar + Tabs in content
```

**When in doubt, use sidebar + content.** It's the safest default and the easiest to extend later. Every other layout is a specialization that solves a specific problem — use them when that problem exists, not preemptively.

### Combining layouts

Real dashboards combine layouts. A single app might use:
- **Sidebar + Content** for the main pages (dashboard home, user list, settings)
- **Sidebar + Content + Right panel** on the helpdesk ticket page
- **Sidebar + Tabs in content** on the customer detail page
- **Content only** for the onboarding wizard
- **Full-bleed** for a `/tv` monitoring view
- **Split pane** for the content diff/preview feature

This is fine. The sidebar stays consistent across layouts; only the content area's internal structure changes. The user always knows where they are because the sidebar is the anchor.

## The header

### Logo

- **Position**: top-left corner. Vertically centered in the header bar.
- **Size**: 28–36px tall. Width whatever the logo demands.
- **Behavior**: clickable, links to dashboard home (`/` after login). On hover, very subtle feedback (slight opacity change). No big "click me" treatment.
- **For unbranded internal tools**: a simple wordmark or the project name in a distinctive font is better than no logo. The header feels naked without something there.

### Optional global search

If the dashboard has more than ~50 navigable items (records, pages, users, projects), put a global search in the center of the header (or center-left of the content area). Keyboard shortcut to focus it: `⌘K` / `Ctrl+K`. This is the "command palette" pattern from Linear, Notion, Slack, Vercel, etc.

If the dashboard has fewer items, skip global search — it adds clutter for nothing.

### User menu

Top-right corner. Avatar (or initials) with the user's name beside it on desktop, just the avatar on mobile. Click opens a dropdown:

```
┌───────────────────────┐
│ Hanns C.              │
│ admin@acme.com        │
├───────────────────────┤
│ Profile               │
│ Account settings      │
│ Theme           ▸     │  ← optional submenu
├───────────────────────┤
│ Help                  │
│ Keyboard shortcuts    │
├───────────────────────┤
│ Sign out              │
└───────────────────────┘
```

The order matters: identity at top, account/personal settings in the middle, help below, sign out at the bottom. This is the convention. Sign out is always last.

### Notifications bell

Optional. Place it just left of the user menu. Show a dot or count when there are unread items. Click opens a dropdown of recent notifications with a "view all" link to a full notifications page.

Skip the bell entirely if the dashboard doesn't generate notifications. An empty notifications icon is worse than no icon.

## The sidebar

### Item ordering

Order items by **frequency of use**, not alphabetically and not by section weight. Most-used at the top, least-used (settings, admin) at the bottom.

A typical order for a SaaS admin:

```
Dashboard       ← always first; the landing page
Inbox           ← if there are user-actionable items
Customers
Orders
Products
─────
Reports
Audit log
─────
Settings        ← always last (or in the user menu)
```

Group related items into sections separated by a thin divider or a small section label. Don't over-section — three sections max for a typical dashboard. More than three and you're describing an app, not a dashboard.

### Item count

- **Sweet spot**: 5–8 top-level items
- **Maximum**: 10 top-level items
- **Beyond that**: collapse the bottom half into "More" or move into settings

If the dashboard genuinely has 15 distinct top-level features, it might be three apps in a trench coat. Push back on the user before building it as one.

### Sub-menus

Use a sub-menu when a top-level area has 2–6 child pages that share the parent. Render it as an indented list under the parent that expands when the parent is clicked or active.

```
▾ Customers
    All customers
    Segments
    Activity
    Imports
```

Rules:
- Sub-menus expand when you visit any child page (so the active path is always visible)
- The expanded/collapsed state for each parent is remembered across sessions (localStorage)
- Don't nest more than two levels deep — third-level navigation belongs inside the page, not in the sidebar
- Clicking the parent label navigates to the parent's index page; the chevron handles expand/collapse separately

### Icons

Each top-level item gets an icon. Icons help scanning, and they make the collapsed sidebar usable. Use a single icon family (Lucide, Heroicons, Phosphor, Tabler) — don't mix.

Sub-menu items typically don't get icons; they're text-only and indented under the parent's icon.

### Active state

The current page must be visually distinct in the sidebar. The conventions:
- A solid background fill (slightly darker or accent-colored) on the active item
- A 2–3px vertical bar on the left edge of the active item
- Bolder text weight on the active item

Pick one or two; don't pile all three. Make sure the active state is obvious from across the room.

### Collapsed state (icon rail)

When the sidebar collapses on narrow screens:
- Width drops to ~64px
- Only icons remain
- Hovering an icon shows a tooltip with the item label
- The active state still shows (vertical bar or background fill)
- A toggle button at the top or bottom expands it back

### Mobile (drawer)

Below ~768px the sidebar should not occupy persistent space. Replace it with a hamburger button in the header that opens the sidebar as an overlay drawer from the left edge. Tapping outside or pressing `Esc` closes it.

## Breadcrumbs

Show breadcrumbs on every page deeper than the top level. They orient the user and provide one-click escape upward.

```
Dashboard / Customers / Acme Corp / Orders / #4521
```

Rules:
- Each segment except the last is clickable
- The last segment is the current page (not a link)
- Use `/` or `>` as the separator — pick one and stay consistent
- Truncate long names with ellipsis if the breadcrumb threatens to wrap
- Don't show breadcrumbs on the dashboard home — there's nothing above it
- Don't include the user's name or any state in breadcrumbs — only structural location

## The page header

Every content page has the same header shape. Consistency is the point.

```
┌────────────────────────────────────────────────────┐
│ Page title                       [Secondary] [Primary action] │
│ Optional subtitle or description                              │
└────────────────────────────────────────────────────┘
```

- **Title**: the noun this page is about. "Customers." "Order #4521." "Settings — Billing."
- **Subtitle**: optional. One sentence of context. Often the count, the last-updated time, or a description.
- **Primary action**: top-right of the header. The most common action a user takes on this page. "New customer," "Export," "Save changes."
- **Secondary actions**: to the left of the primary. "Filter," "Import," "Refresh." Use icon-only buttons for very common ones, labeled buttons for less common ones.

The page header is sticky on long-scrolling pages so the primary action is always reachable.

## The landing page

The page after login is special. It's the first thing the user sees every session. Treat it as a real designed page, not a placeholder.

The conventional landing page for a dashboard:

```
┌────────────────────────────────────────────────────┐
│ Welcome back, Hanns                                │
│ Here's what's happened since you were last here.   │
├──────────┬──────────┬──────────┬──────────────────┤
│ KPI 1    │ KPI 2    │ KPI 3    │ KPI 4            │
│ 1,247    │ $42.1k   │ 98.2%    │ 12               │
│ ↑ 12% MoM│ ↓ 3% WoW │ → flat   │ +3 today         │
├──────────┴──────────┴──────────┴──────────────────┤
│ Main chart (revenue over time, etc.)               │
│                                                     │
├─────────────────────┬──────────────────────────────┤
│ Secondary chart     │ Recent activity feed         │
│                     │ • Alice created Project X    │
│                     │ • Bob updated Order #123     │
│                     │ • System restarted at …      │
└─────────────────────┴──────────────────────────────┘
```

Rules:
- 3–6 KPI cards across the top — never more than 6, four is the sweet spot
- Each KPI shows: the number, the unit/format, the comparison (vs. previous period or target), and the direction
- One large chart below the KPIs that tells the main story
- One secondary panel: another smaller chart, or a recent-activity feed, or a "needs attention" list
- All data is real, sourced from the data layer, and reflects the actual current state of the database
- A "last updated" timestamp somewhere near the top so the user knows the freshness

Do not put 12 charts on the landing page. The landing page answers "is everything OK?" in 5 seconds. Drill-down lives on dedicated pages.

## Page templates

There are five page templates that cover ~95% of dashboard pages. Build them once as reusable components and reuse them.

### 1. Dashboard / overview

KPIs + charts + activity feed. Used for the landing page and any "summary" page (e.g., "Customer overview").

### 2. List / table

A single primary table with filter bar, search, pagination, and per-row actions. Used for "all customers," "all orders," etc.

```
┌────────────────────────────────────────────────────┐
│ Customers                              [+ New]     │
│ 1,247 total                                         │
├────────────────────────────────────────────────────┤
│ [Search]  [Status ▾] [Plan ▾] [Created ▾]  [↓]    │  ← filter bar
├────────────────────────────────────────────────────┤
│ ☐ Name     │ Email      │ Plan │ Created │  ⋯    │
│ ☐ Acme Co  │ ...        │ Pro  │ Jan 12  │  ⋯    │
│ ☐ ...      │ ...        │ ...  │ ...     │  ⋯    │
├────────────────────────────────────────────────────┤
│ Showing 1–25 of 1,247         ‹ 1 2 3 ... 50 ›    │
└────────────────────────────────────────────────────┘
```

### 3. Detail

A header with the entity's identity + tabs or sections for different facets. Used for "Customer #1234," "Order #4521," "User profile."

```
┌────────────────────────────────────────────────────┐
│ ← Back to Customers                                │
│ Acme Corp                            [Edit] [⋯]    │
│ acme.com · Pro plan · Customer since Jan 2023       │
├────────────────────────────────────────────────────┤
│ Overview · Orders · Users · Billing · Activity      │  ← tabs
├────────────────────────────────────────────────────┤
│ Tab content here                                    │
└────────────────────────────────────────────────────┘
```

### 4. Form

Used for create / edit. Single column, generous spacing, fields grouped into sections, primary action sticky at the bottom.

```
┌────────────────────────────────────────────────────┐
│ New customer                                        │
├────────────────────────────────────────────────────┤
│ Basics                                              │
│   Name           [_____________________________]    │
│   Email          [_____________________________]    │
│   Phone          [_____________________________]    │
│                                                      │
│ Plan & billing                                      │
│   Plan           [Free ▾]                           │
│   Trial days     [14]                                │
├────────────────────────────────────────────────────┤
│                                  [Cancel] [Create]  │  ← sticky footer
└────────────────────────────────────────────────────┘
```

### 5. Settings

Two-column: secondary nav on the left listing settings sections, content on the right. Each section is its own form that saves independently.

```
┌────────────────────────────────────────────────────┐
│ Settings                                            │
├──────────────┬─────────────────────────────────────┤
│ Profile      │ Profile                              │
│ Security     │   Name        [_________________]    │
│ Notifications│   Email       [_________________]    │
│ Team         │   Avatar      [_________________]    │
│ Billing      │                              [Save]  │
│ API keys     │                                      │
└──────────────┴─────────────────────────────────────┘
```

## Density: how much fits on a page

Two density modes are common:

- **Comfortable**: row height 48–56px, padding 16–24px. Default. Easier to scan, friendlier to new users.
- **Compact**: row height 32–40px, padding 8–12px. For power users with lots of data. Offer it as a toggle on data-heavy tables.

Pick one as the default and only build the second mode if users will be living in the dashboard all day. Most dashboards only need comfortable.

## Responsive breakpoints

Think in three sizes. Test all three.

- **Desktop (>1024px)**: full layout, persistent sidebar, multi-column content where appropriate
- **Tablet (768–1024px)**: collapsed icon-rail sidebar, content stacks where it doesn't fit
- **Mobile (<768px)**: hamburger drawer for nav, single-column content, tables become cards (each row a stacked card), filter bar collapses into a "Filters" button that opens a drawer

Tables are the hardest part of mobile dashboards. Two strategies:

1. **Horizontal scroll inside the table** with a "frozen" first column. Acceptable for power-user dashboards.
2. **Card layout per row**. Each row becomes a stacked card showing the most important fields. Better for end-user dashboards.

Pick based on who the user is. Don't ship desktop-only and call it done.

## Theming and tokens

Use a single source of truth for design tokens: CSS custom properties or a theme object. Define:

- 1 background, 1 surface, 1 surface-elevated
- 1 border, 1 border-strong
- 1 text-primary, 1 text-secondary, 1 text-muted
- 1 brand color (the accent), 1 brand-hover, 1 brand-foreground
- 4 status colors: success, warning, danger, info — each with foreground and subtle background variants
- A radius scale (4, 6, 8, 12), a spacing scale (4, 8, 12, 16, 24, 32, 48), a font-size scale

Light and dark mode are *both* defined by swapping the values of these tokens. Build dark mode from day one — retrofitting it later is painful and the result usually looks like inverted light mode. Test both modes before finishing.

## Iconography

Pick one icon family. Stick to it. Lucide and Heroicons are the safe defaults. Phosphor, Tabler, and Material Symbols are also good. Mixing families produces visual chaos.

Use icons consistently:
- Same icon for the same concept across the app (one icon for "delete," one for "edit," one for "settings")
- Same icon size in the same context
- Icons in primary nav are filled or outlined consistently

## Avoiding redundant actions

The same action appearing in the sidebar, the user menu, AND a header icon confuses users about which is "the real one." Research shows users don't recognize duplicates — they scan each one separately, doubling cognitive effort, and may click both expecting different content.

### One canonical location per action

Every visible UI element that a user can click should have ONE canonical location. Use this decision framework:

| Question | Canonical location | Examples |
|---|---|---|
| **Is it about the user personally?** | Avatar dropdown (top-right). Nowhere else. | Profile, preferences, theme, logout |
| **Is it about the workspace/team?** | Sidebar, labeled with workspace scope. Nowhere else. | Workspace settings, members, billing, features |
| **Is it a high-frequency navigation destination?** | Sidebar primary items. | Projects, issues, customers, analytics |
| **Is it a creation action?** | ONE visible button (page header or sidebar, not both). | "Create Customer", "+ New Project" |
| **Is it search?** | ONE visible trigger (header bar or sidebar item). | Search bar or "Search" nav item |
| **Is it a power-user shortcut?** | Invisible accelerators are acceptable alongside visible actions. | Cmd+K for search, `C` for create, right-click context menu |

**Invisible accelerators (keyboard shortcuts, right-click menus) don't count as redundancy** — they don't compete for visual attention.

### How real products solve this

Every major dashboard product follows the same pattern:

- **Personal actions** (profile, preferences, theme, logout) → avatar dropdown only
- **Workspace settings** → sidebar or workspace switcher, clearly labeled with scope
- **Search** → one visible trigger + Cmd+K (the only universally accepted visible redundancy)
- **Create new** → one visible button + optional keyboard shortcut
- **Logout** → avatar dropdown, last item. Never in the sidebar.

Linear, Notion, Stripe, Vercel, and GitHub all put Settings in exactly ONE visible location. None of them duplicate it.

### Disambiguating multiple "settings"

When a dashboard has personal settings AND workspace settings AND admin settings, use different names and different locations:

| Scope | Label | Location |
|---|---|---|
| Personal | "Preferences", "My account", "Profile" | Avatar dropdown |
| Workspace/team | "Workspace settings", "[Team name] settings" | Sidebar |
| Admin/system | "Administration", "Admin console" | Inside workspace settings, role-gated |

Never label all three "Settings." The user can't tell which is which.

### Redundancy anti-patterns

- **Triple settings** — gear icon in header + "Settings" in sidebar + "Settings" in user menu. Users assume three different destinations.
- **Triple "New" button** — sidebar + page header + floating action button. Users don't know which to click.
- **Dual profile** — "My Profile" in sidebar AND in avatar dropdown. Profile is a personal action, not a navigation destination — avatar dropdown only.
- **Dual notifications** — bell icon in header AND "Notifications" in sidebar. Pick one.
- **Same dropdown from two triggers** — if two UI elements open the identical dropdown, remove one.

### Mobile: resolve all desktop redundancy

Desktop has room for 3 navigation zones (sidebar + header + user menu). Mobile has room for at most 2. If "Settings" was in two places on desktop, it must be in exactly one on mobile.

- **Bottom tab bar** (3-5 items max) for highest-frequency destinations
- **Hamburger** for everything else — but deduplicate: never show the same action in both the tab bar and the hamburger
- **Avatar icon** in mobile header (if present) is the sole entry point for personal actions — don't duplicate in hamburger

## What to avoid

- **Hamburger menu on desktop.** Hides the nav behind a click for no reason. Use a persistent sidebar.
- **Top nav with 8+ items.** Horizontal nav doesn't scale. Use a sidebar.
- **Two sidebars.** Causes orientation problems. If you need secondary nav, put it inside the page (tabs or sub-nav above the content).
- **Sticky everything.** Sticky header, sticky sidebar, sticky page header, sticky footer, sticky filter bar — and the user has 200px of actual content in the middle. Pick the few things that genuinely need to stay visible.
- **Carousels of widgets on the landing page.** If it's important enough to show, it's important enough to not hide behind a "next" button.
- **Modal-on-modal-on-modal.** Two layers max. Beyond that, use a dedicated page or a side drawer.
- **Cute branded loading screens.** They're charming the first time and infuriating the tenth. A subtle skeleton or top-of-page progress bar is enough.
- **Animations longer than 200ms** on routine interactions. The dashboard is a tool, not a presentation. Snappier is better.
- **Tooltips on everything.** A dashboard littered with `(?)` icons is a dashboard with a labeling problem. Fix the labels.
