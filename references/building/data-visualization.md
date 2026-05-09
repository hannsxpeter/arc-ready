# Data Visualization

Charts, KPI cards, and tables are how a dashboard tells its story. This file is the rules for choosing the right one and building it correctly.

## The chart-selection decision tree

Don't pick a chart by which one looks coolest. Pick by what question the user is trying to answer. Walk this tree:

```
What does the user need to see?
│
├── A single number that matters right now
│       → KPI card
│
├── How a number changes over time
│   ├── 1 series, smooth trend → Line chart
│   ├── 1 series, with totals visible → Area chart
│   ├── 2–4 series compared → Multi-line chart
│   ├── 5+ series → Multi-line with legend toggle, OR small multiples
│   └── Discrete time buckets (months, weeks) → Column chart
│
├── How values compare across categories
│   ├── < 8 categories, fixed order → Column chart (vertical bars)
│   ├── < 8 categories, ranked → Bar chart (horizontal bars, sorted)
│   ├── > 8 categories → Bar chart (horizontal, sorted, scrollable)
│   ├── 2 dimensions (category × subcategory) → Grouped or stacked bar
│   └── A category vs a target → Bullet chart
│
├── Parts of a whole
│   ├── 2–3 parts → Pie or donut (rare; bar is usually better)
│   ├── 4+ parts → Stacked bar (single bar) OR table with %
│   └── Hierarchical parts → Treemap
│
├── Distribution of values
│   ├── Single variable, continuous → Histogram
│   ├── Categorical comparison of distributions → Box plot
│   └── Two variables → Scatter plot
│
├── Geographic data
│   └── → Map (choropleth for regions, pins for points)
│
├── Status across many items
│   └── → Heatmap or status grid
│
├── Relationships between many items
│   └── → Network graph (rare; usually wrong choice)
│
└── A list with attributes the user wants to scan
        → Table (not a chart)
```

If two chart types both fit, pick the simpler one. Bar > Pie almost always. Line > Area when totals don't matter.

## KPI cards

KPI cards are the most-looked-at element on most dashboards. Build them carefully.

### Anatomy of a KPI card

A bare number is useless. A number with context is a KPI. Context means:

1. **The number**, formatted appropriately (`$42,103`, not `42103`)
2. **The label** — what is this counting? ("Monthly recurring revenue")
3. **The comparison** — vs. what? Previous period, target, or both. ("↑ 12% vs last month" / "82% of $50k goal")
4. **The direction signal** — up/down arrow + color, *and* an icon or word, never color alone (color blindness)
5. **Optional sparkline** — a tiny trend line in the corner showing the last N periods

```
┌─────────────────────────────┐
│ Monthly Recurring Revenue   │
│                             │
│   $42,103                   │
│   ↑ 12% vs last month       │
│                       ╱╲ ╱  │  ← sparkline
└─────────────────────────────┘
```

### KPI rules

- **3–6 KPIs above the fold, never more.** Above 6 they become wallpaper. Four is the sweet spot.
- **Order by importance, left to right.** The most important one gets the leftmost slot.
- **Compare against the same thing across all KPIs.** Don't mix "vs last month" and "vs goal" in adjacent cards — pick one.
- **Format the number** to the right precision. `$42,103` not `$42,103.27` (decimals are noise on big numbers). `42.0%` not `42.00000%`. `1.2k` not `1,213` if space is tight.
- **Color the comparison, not the number.** Green/red on the percentage delta. The big number stays neutral.
- **Make the card clickable** if there's a meaningful drill-down (e.g., MRR card → revenue page). Cursor pointer + subtle hover state.
- **Show the time period** somewhere. "MRR — March 2026" or "MRR (last 30 days)." Without it, the user doesn't know what the number means.

### KPI anti-patterns

- **A KPI without context.** Just "$42,103" with no comparison. Useless.
- **More than 6 KPIs.** The user can't process them.
- **KPIs that all show the same metric in different time windows.** "Revenue today / this week / this month / this quarter." Use a time selector instead.
- **Big numbers in different scales side by side.** "247" next to "$1.2M" next to "98.7%" — the eye can't compare them. Group by scale or separate visually.
- **Animations that bounce the number on every render.** Distracting. Animate once on load, then stay still.

## Bar and column charts

The workhorse of dashboard charts. Use them more than you think.

### Bar (horizontal) vs column (vertical)

- **Column** — categories on the X-axis, values on Y. Use when categories have natural order (months, sequential bins) or when category labels are short.
- **Bar** — categories on Y-axis, values on X. Use when categories are unordered (rank them by value) or when labels are long enough that vertical text would be awkward. **Default to horizontal bar for ranked data** — humans compare bar lengths better when they share a baseline.

### Bar chart rules

- **Start the value axis at zero.** Cutting the axis exaggerates differences and is misleading. The only exception is when "zero" is meaningless (e.g., temperature in Celsius for a city that ranges 18–24°C, where zero would crush all the variation).
- **Sort by value** for ranking comparisons. Sort by category for ordered comparisons (months, day of week).
- **Use one color** for a single series. Multiple colors for one series make the eye think they mean something.
- **Direct labels are better than legends** for ≤6 categories.
- **Stacked bars** are for parts-of-whole within each category. Avoid more than 4 segments — past that, segments become uncomparable.
- **Grouped bars** are for comparing the same dimensions across categories. Don't go past 3 groups per category.

## Line charts

For continuous time-series. The most common dashboard chart after KPI cards.

### Line chart rules

- **Time on the X-axis, value on Y.** Always.
- **Start the Y-axis at the natural baseline.** Often zero, but for things like temperature or stock price, a contextually meaningful range is fine — just don't manipulate it to mislead.
- **Limit to 4–6 series before legibility collapses.** Past that, use small multiples (one chart per series in a grid) or a multi-line chart with hover-to-highlight.
- **Use distinct, hue-different colors** for series. Don't use a sequential gradient for categorical series.
- **Show the data points as dots when there are few of them** (< 30 points). Hide the dots and show only the line for dense series.
- **Hover should reveal the exact value** at that point, for all series at once (a vertical crosshair with tooltip).
- **Show grid lines but make them subtle.** Light gray, behind the data. They aid reading but shouldn't compete with it.
- **For sparse data, use the line with a fill below it (area chart)** to make the trend more visible.

### When to use area instead of line

Use an area chart when:
- The total under the line matters (cumulative volume, total time)
- The trend is more important than precise values
- You're stacking multiple series to show composition over time

Don't use area when comparing 4+ series — the stacked area becomes unreadable.

## Pie and donut charts

Use sparingly. Use almost never.

### When pies are acceptable

- 2 slices ("active vs inactive") — fine
- 3 slices, all clearly different sizes — fine
- 4 slices — borderline
- 5+ slices — never

For anything else, use a horizontal bar chart sorted by value. Bars communicate the same information more accurately because humans are better at comparing lengths than angles.

### Pie rules (if you must)

- **Sort slices clockwise from largest, starting at 12 o'clock.**
- **Direct labels with values and percentages**, not a legend that forces eye-tracking back and forth.
- **Donut > pie** if you want to put a total or label in the center.
- **No 3D pies. Ever.** They distort proportions because the slices in the front look bigger than slices of the same size in the back.

## Tables

Tables are not charts but they're the most-used surface in many dashboards. Build them as carefully as charts.

### Table rules

- **Right-align numbers**, left-align text, center status badges. The eye scans down a column much faster when the format is consistent.
- **Format numbers consistently.** Currency with $ and commas, percentages with %, dates in one format throughout. Mixed formats are visual noise.
- **Show units** in the column header or beside the value. "Revenue ($)" not just "Revenue."
- **Truncate long values** with ellipsis and reveal the full value on hover. Don't let one row blow out the column width.
- **Zebra striping is optional.** Subtle row dividers are usually enough; over-striped tables look like spreadsheets from 2003.
- **Sticky table header** if the table scrolls. The user always needs to know which column is which.
- **Sortable columns** — clicking a header sorts. The current sort is indicated by an arrow. Re-clicking reverses. Default sort makes sense for the entity (newest first for activity, alphabetical for names).
- **Per-row actions** in the rightmost column. Either as visible buttons (for 1–2 actions) or as a `⋯` icon menu (for 3+).
- **Bulk select** with a checkbox column on the left if bulk actions exist.
- **Empty state** when there are no rows — see `states-and-feedback.md`.
- **Don't load 10,000 rows.** Paginate or virtualize. The browser is fine with 100 DOM nodes; it's not fine with 100,000.
- **Hide low-value columns by default**, let users show them via a column picker. A table with 14 visible columns is unscannable.
- **Wrap or truncate, but pick one per column.** A column where some rows wrap and others don't is jarring.

### Density modes

Offer two modes:
- **Comfortable** — 48–56px row height. Default.
- **Compact** — 32–40px row height. For power users with lots of data.

A toggle in the table header lets the user switch. Save the preference per user.

### Filter bars

Above the table:

```
[Search...]  [Status ▾]  [Owner ▾]  [Date range ▾]   [Reset]   [⤓ Export]
```

Rules:
- Filters apply via dropdowns or chips, not modal dialogs
- Search debounces (250–400ms)
- Active filters are visible as removable chips below the bar, or by lighting up the dropdown
- "Reset" clears all filters back to defaults
- Filters are encoded in the URL — see `data-layer.md` for the URL convention
- Filters should narrow, not replace — combining multiple filters AND-s them

## Heatmaps and status grids

Useful for showing many discrete states at once: deployments per day, server health per region, test results across configurations, calendar contributions.

- **Use a sequential color scale** for ordinal data (none → low → med → high)
- **Use a diverging scale** for data centered on zero (negative is one color, positive another)
- **Never use rainbow.** Rainbow is the wrong scale for almost everything; humans don't perceive its colors as ordered.
- **Always include a legend.**
- **Hover should reveal the exact value** for the cell.

## Maps

Maps are powerful but oversold. Use them only when geography is the question.

- **Choropleth** — color regions by a value. Use for regional comparisons (sales by state, users by country).
- **Pins / markers** — discrete points. Use for locations (offices, customers, events).
- **Don't put a map in your dashboard for decoration.** A map of "where customers live" is interesting once and never useful.

Libraries: Mapbox GL, MapLibre GL, Leaflet, deck.gl. Pick based on data volume and interactivity needs.

## Color

The single biggest dashboard quality multiplier. Get color right.

### Color roles

Define and stick to a small palette with explicit roles:

- **Brand / accent** — primary action color, key data series, highlights. Used sparingly.
- **Neutral** — text, borders, backgrounds, axes, gridlines. Most of the dashboard is neutral.
- **Status colors**: success (green), warning (yellow/amber), danger (red), info (blue). Each with a foreground variant and a subtle background variant for badges/banners.
- **Categorical palette** — 6–10 distinct hues for chart series. Use a curated palette (D3 schemeTableau10, Observable Plot palette, ColorBrewer Set2). Don't pick rainbow.
- **Sequential palette** — single-hue gradient (light → dark of one color) for ordinal/heatmap data.
- **Diverging palette** — two-hue gradient (red ← white → blue) for data centered on zero.

### Color rules

- **Most of the dashboard should be neutral.** Color earns attention. Colored everything = colored nothing.
- **Use color to encode meaning, not to decorate.** A red button means "danger," a green badge means "success." Same meaning, same color, everywhere.
- **Pass WCAG AA contrast** — 4.5:1 for body text, 3:1 for UI components and large text. Use a contrast checker. Don't eyeball it.
- **Never use color alone** to convey information. Pair red/green with icons (✓ ✗) or labels. ~8% of men have red-green color blindness.
- **Sequential data uses one hue** ramped from light to dark. Don't use rainbow for sequential data.
- **Categorical data uses distinct hues**, not shades of one hue. Otherwise the eye thinks adjacent shades are related.

### Dark mode

Build it from the start. Both modes share the same token names; only the values swap. Test both before shipping. Common dark-mode mistakes:

- Pure white text on pure black background — too much contrast, fatigues the eye. Use `#e5e5e5` on `#0a0a0a` instead.
- Surface colors that don't elevate — in dark mode, surfaces get *lighter*, not darker, as they elevate (modal > card > background). Inverted from light mode.
- Brand colors that look great on light and ugly on dark — adjust the brand color per mode if needed. Most brand colors need ~10% saturation drop in dark mode.
- Forgetting chart colors — categorical palettes also need dark-mode variants.

## Chart accessibility

Charts are visual by nature, but they must be usable by everyone:

- **Provide a data table alternative** for every chart. Screen reader users cannot interpret SVG/canvas. A toggleable "View as table" button that shows the chart's data in a sortable table.
- **ARIA labels on chart elements** — each bar, line, or point should have a descriptive label ("Revenue: $42,103 in March 2026").
- **Keyboard navigation** within charts — tabbing through bars/data points with focus indicators. Not all chart libraries support this; test specifically.
- **`prefers-reduced-motion`** — respect it for chart animations. Disable transitions, show final state immediately.
- **High contrast mode** — test that all chart elements are visible with OS-level high contrast enabled.

## Responsive charts on mobile

Charts must work on small screens:

- Charts reflow to full-width on mobile.
- Legends move from side to bottom (or become a scrollable row).
- Tooltips work with touch (tap, not hover).
- Sparklines are better than full charts for mobile KPI cards.
- Wide bar charts may need horizontal scroll or conversion to vertical lists with inline bars.

## Sparklines and inline micro-charts

A tiny trend line inside a table cell showing the last 7-30 data points per row. High information density, no interaction needed. Use for: revenue trend per customer, error rate per service, stock price in a portfolio. Render as inline SVG, 60-100px wide, 20-30px tall, no axes or labels.

## Configurable dashboard layouts

Many modern dashboards (Grafana, Datadog, Vercel) let users add, remove, resize, and rearrange widgets:

- Grid-based layout with drag-to-resize and drag-to-reorder.
- Save custom layouts per user.
- Widget picker: add a chart, KPI card, table, or feed from a catalog.
- Libraries: `react-grid-layout`, `gridstack.js`, `@hello-pangea/dnd`.

Build this only when users need personalized views. Most dashboards with a fixed audience should have a fixed layout.

## Picking a chart library

Don't reinvent. Don't mix more than one in the same dashboard. Some good defaults:

- **React** — Recharts (composable, good defaults), Visx (lower-level, very flexible), Tremor (dashboard-focused, opinionated, fastest path to a good-looking dashboard), nivo, Apache ECharts via echarts-for-react
- **Vue** — unovis, vue-chartjs, Apache ECharts, vue-echarts
- **Svelte** — LayerChart, Layer Cake, svelte-chartjs
- **Angular** — Apache ECharts via ngx-echarts, ngx-charts
- **Vanilla / framework-agnostic** — Apache ECharts (extremely capable), Chart.js (simple, fast), D3 (full control, big learning cost), Observable Plot (concise, modern)
- **Realtime / streaming** — uPlot (very fast), Lightning Chart, Plotly (with WebGL)

For 90% of dashboards: **Recharts (React) / unovis (Vue) / LayerChart (Svelte) / Apache ECharts (anywhere)** are all correct answers. Pick one and commit.

For dashboards that need to look polished out of the box: **shadcn/ui charts** (built on Recharts, Tailwind-based) offer strong defaults with less lock-in than Tremor. Tremor (v3+) remains viable but shadcn/ui's composable approach is now the more popular choice.

## Performance

A dashboard slows down for two reasons: too many DOM nodes (huge tables, dense charts) or too much JavaScript per frame.

Quick wins:
- **Virtualize tables > 100 rows.** TanStack Virtual, react-window, vue-virtual-scroller, svelte-virtual-list.
- **Memoize chart data transforms.** Don't recompute on every render.
- **Don't re-render the chart on parent re-renders.** Wrap in memo or extract.
- **Sample large datasets** before charting. 10,000-point line charts are visually no different from 1,000-point line charts; downsample.
- **Use canvas-rendered charts** (uPlot, Lightning Chart, ECharts canvas mode) for very large series. SVG charts choke at ~5,000 elements.
- **Lazy-load chart libraries** if the landing page doesn't need them. Charts are big bundles; ship them only on the pages that use them.

## Don'ts

- **Don't 3D anything.** No 3D pies, no 3D bars, no isometric anything. Distorts proportions, looks dated.
- **Don't use a pie chart with > 4 slices.** Use a bar chart.
- **Don't truncate the Y-axis on a bar chart** to exaggerate differences. Misleading.
- **Don't use rainbow palettes** for sequential data.
- **Don't rely on color alone** to convey status. Pair with icons or labels.
- **Don't use a different chart library on every page.** Pick one and stick to it.
- **Don't put more than 6 series on one chart.** Use small multiples or a legend toggle.
- **Don't use cute custom illustrations** for empty states of charts. A subtle "No data for this period" is enough.
- **Don't show currency without the currency symbol** or assume USD by default in international apps.
- **Don't show timestamps without time zones** when users span multiple time zones.
- **Don't animate chart transitions longer than 200ms.** Snappier is better.
