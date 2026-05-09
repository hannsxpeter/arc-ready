# UI Design Patterns

This file covers the visual design layer — the components, typography, spacing, tokens, motion, and micro-copy that make a dashboard feel polished and professional. The layout structure is in `information-architecture.md`; this file is about what goes inside it.

Dashboard UI is not marketing-site UI. Dashboards are data-dense, functional, used for hours daily. Every decision here optimizes for **scannability, density, and clarity** — not novelty.

**Precedence note.** If a project-root `DESIGN.md` exists (the [Google Labs format](https://github.com/google-labs-code/design.md), Apache 2.0; YAML frontmatter holds machine-readable design tokens), it is the canonical token source and supersedes the archetype + 5-decision derivation in this file. See SKILL.md Step 3 sub-step 3a and `references/design-md-integration.md` for the consumption recipe. This file is the scaffold-from-scratch path: read it when no `DESIGN.md` is present, and optionally use the chosen archetype to scaffold a `DESIGN.md` before Step 4 so the next agent starts from sub-step 3a, not 3b.

**Canonical scope:** component library, typography, spacing and density tokens, visual identity decision framework, 10 archetype token sets, dark mode, micro-copy. **See also:** `design-md-integration.md` for the cross-tool design-system contract, `states-and-feedback.md` for state patterns, `information-architecture.md` for layout, `data-visualization.md` for charts and tables, `animation-and-motion.md` for transitions.

---

## Component patterns

### Button hierarchy

Use exactly these variants, in descending visual weight. **One primary per visible context.**

| Variant | Use case | Visual treatment |
|---|---|---|
| **Primary** | Single main action per view (Save, Create, Submit) | Solid brand color bg, white foreground |
| **Secondary** | Supporting actions (Cancel, Back, Export) | Muted bg, standard foreground |
| **Outline** | Tertiary actions, filters, toggles | Border only, transparent bg, hover fills |
| **Ghost** | Inline actions, table row actions, toolbar items | No visible bg at rest, hover fills |
| **Destructive** | Delete, revoke, disconnect — anything irreversible | Red/danger bg, white foreground |
| **Link** | Navigation-styled action, "Learn more" | Text-only, underline on hover |

**Sizes:** `sm` (h-8, text-xs), `default` (h-9, text-sm), `lg` (h-10, text-base), `icon` (h-9 w-9, square).

**Rules:**
- Never put two primary buttons next to each other.
- If a destructive action is the main CTA (like "Delete Account"), use destructive as the primary, paired with ghost/outline cancel.
- Loading state: swap label to present participle ("Saving..."), show spinner inside the button, disable to prevent double-submit.
- Disabled state: reduced opacity (50%), `cursor: not-allowed`, tooltip explaining why.

### Badge / chip / pill

- **Badge** — read-only label, no interaction. Padding 2px 10px, border-radius full, text-xs, font-medium. Use for counts, categories, metadata.
- **Chip** — dismissible or selectable. Same styling plus an X icon (16px) with 4px gap. Use for active filters, tag inputs.
- Semantic colors: `default` (muted bg), `success` (green), `warning` (amber), `error` (red), `info` (blue). Always pair color with a text label — never color alone.

### Avatar

- **Sizes:** 24px (xs), 32px (sm), 40px (md), 48px (lg), 64px (xl).
- **Fallback order:** image > initials (first+last, bg derived from name hash for consistency) > generic user icon.
- **Stack:** Overlap by 25% of width (e.g., -8px margin-left for 32px avatars). Show max 3-5, then `+N` counter in same-size circle with muted bg.
- **Status dot:** 8-12px circle, bottom-right corner, 2px white ring. Green = online, amber = away, gray = offline, red = DND.

### Status indicators

**Always: dot + label + color. Never color alone.**

| Status | Color | Icon supplement |
|---|---|---|
| Active / Healthy / Success | Green | Checkmark |
| Warning / Degraded | Amber | Triangle |
| Error / Failed / Critical | Red | X circle |
| Processing / Pending | Blue | Spinning |
| Inactive / Draft / Disabled | Gray | Dash or empty circle |

Dot: 8px circle, 6px gap to label. In tables, the dot sits inline left of the text in the status cell.

### Toggle vs checkbox

- **Toggle/switch** — for settings that take effect immediately (enable notifications, dark mode). No form submission needed.
- **Checkbox** — for settings that require explicit save/submit (form fields, bulk selection, consent).
- Never use a toggle inside a form that has a Save button — that conflates immediate and deferred actions.

### Progress components

- **Bar:** 8px height (4px compact), border-radius full. Show percentage label above or right. Use `aria-valuenow`, `aria-valuemin`, `aria-valuemax`.
- **Ring/circle:** 40-64px diameter, 4px stroke. Value centered inside. Good for stat cards.
- **Steps:** Horizontal for <6 steps, vertical for 6+. Current = primary fill, completed = primary + checkmark, future = muted/border-only. Connect with 2px lines.

### Dropdown vs command palette

- **Dropdown menu** — 3-12 known options, contextual to a trigger. Max height ~300px, then scroll.
- **Command palette** (Cmd+K) — 10+ items, search-driven, keyboard-first. Group by category. Show keyboard shortcuts right-aligned in muted text.

---

## Typography

### Heading scale

Dashboards rarely need large headings. The working scale:

| Level | Size | Weight | Use |
|---|---|---|---|
| Page title (h1) | 30px / 1.875rem | 700 (bold) | One per page, top of content area |
| Section title (h2) | 24px / 1.5rem | 600 (semibold) | Card group headers, major sections |
| Card title (h3) | 20px / 1.25rem | 600 (semibold) | Individual card/panel headers |
| Subsection (h4) | 16px / 1rem | 600 (semibold) | Sub-headers within cards |
| Label (h5) | 14px / 0.875rem | 500 (medium) | Form group labels, small headers |
| Overline (h6) | 12px / 0.75rem | 500 (medium) | Category labels, ALL CAPS, letter-spacing 0.05em |

### Body text

| Role | Size | Line height | Weight |
|---|---|---|---|
| Body | 14px / 0.875rem | 1.43 (20px) | 400 |
| Body large | 16px / 1rem | 1.5 (24px) | 400 |
| Small / Caption | 12px / 0.75rem | 1.33 (16px) | 400 |
| Tiny / Fine print | 11px / 0.6875rem | 1.27 (14px) | 400 |

**Dashboard base body size is 14px, not 16px.** This is the consensus across Linear, Vercel, Stripe, Ant Design, and every serious data-dense tool. 16px is for marketing sites and long-form reading.

### Monospace and numbers

- Use `font-variant-numeric: tabular-nums` (tabular figures) for all numbers in tables, stat cards, and charts. This ensures digits align vertically.
- For code, IDs, and hashes, use a dedicated monospace font (JetBrains Mono, Fira Code, Geist Mono) at the same size or 1px smaller than surrounding text.
- Right-align all numeric columns. Right-align their headers too.
- Currency: consistent decimal places (always 2 for money). Percentages: 1-2 decimal places.

### Line height rules

- Headings: 1.2-1.3 (tight)
- Body text: 1.4-1.5 (comfortable)
- Single-line labels/values: 1.0
- Multiline table cells: 1.4

### Letter spacing

- Headings >= 24px: `-0.01em` to `-0.02em` (slightly tighter)
- Body: `0` (default)
- Overlines / ALL CAPS: `0.05em` to `0.1em` (looser for legibility)
- Small text < 12px: `0.01em` (slightly looser)

### Font weight usage

- **400** (regular): body text, table cells, descriptions
- **500** (medium): labels, active nav items, badge text, emphasized inline text
- **600** (semibold): headings, card titles, stat values, column headers
- **700** (bold): page titles, hero numbers. Use sparingly in dashboards.

### Truncation

- **Single-line ellipsis:** `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` — for table cells, nav labels, card titles.
- **Multi-line clamp:** `-webkit-line-clamp: 2` (or 3) — for descriptions, preview text.
- **Middle truncation** for URLs/paths: `/users/.../profile` not `/users/settings/pr...` — keep the meaningful suffix visible.
- Always provide full text via `title` attribute or tooltip on hover.
- Tags/badges in a row: show 3, then `+N more` pill. Expand on click.

---

## Spacing and rhythm

### Spacing scale (4px base)

The 4px grid is the standard. Every spacing value is a multiple of 4.

| Value | Use |
|---|---|
| 2px | Icon-to-text micro gap |
| 4px | Tight element gap, badge padding-y |
| 6px | Dense list item padding-y, label-to-input gap |
| 8px | Button padding-y, input padding-y, inline element gap |
| 10px | Badge padding-x |
| 12px | Card padding (compact), button padding-x (sm) |
| 16px | Card padding (default), button padding-x, standard gap |
| 20px | Between form fields |
| 24px | Card padding (comfortable), section spacing within card |
| 32px | Between cards in a grid, between sections |
| 40px | Between major page sections |
| 48px | Page top/bottom margin |
| 64px | Sidebar width collapsed, large section gaps |

### Key decisions

| Element | Spacing |
|---|---|
| Card internal padding | 16px default, 12px compact, 24px comfortable |
| Card gap (grid) | 16px compact, 24px comfortable |
| Between form fields | 16-20px |
| Between form label and input | 6-8px |
| Table cell padding | 8px vertical, 12-16px horizontal (compact: 6px/8px) |
| Section spacing on page | 32px between major sections |
| Sidebar item padding | 8px vertical, 12px horizontal |
| Sidebar width | 240px expanded, 64px collapsed |

### Density modes

Build two modes if the dashboard is data-dense:

| Property | Comfortable | Compact |
|---|---|---|
| Body text | 14px | 13px |
| Table row height | 48px | 36px |
| Table cell padding | 12px 16px | 6px 8px |
| Card padding | 24px | 16px |
| Card gap | 24px | 16px |
| Button height | 36px | 32px |
| Input height | 36px | 32px |

Store the preference per user. Apply via a CSS class on `<body>` or a `data-density` attribute.

---

## Design tokens

### Three-tier system

```
Primitive (raw values) -> Semantic (intent) -> Component (specific usage)
```

**Tier 1 — Primitives:** Raw palette values. Never used directly in components.
```css
--color-gray-50: oklch(0.985 0 0);
--color-gray-900: oklch(0.205 0 0);
--color-blue-500: oklch(0.623 0.214 259);
```

**Tier 2 — Semantic:** Describe purpose, reference primitives. This is where dark mode swapping happens.
```css
--background: var(--color-gray-50);         /* page bg */
--foreground: var(--color-gray-900);        /* primary text */
--muted: var(--color-gray-100);             /* subtle bg */
--muted-foreground: var(--color-gray-500);  /* secondary text */
--primary: var(--color-blue-500);           /* brand action */
--destructive: var(--color-red-500);        /* danger action */
--border: var(--color-gray-200);            /* default borders */
```

**Tier 3 — Component** (optional, for complex systems):
```css
--button-primary-bg: var(--primary);
--card-bg: var(--card);
--card-border: var(--border);
```

### The practical token set

These are the tokens that cover a complete dashboard (matching the shadcn/ui convention, which has become the de facto standard):

`background`, `foreground`, `card`, `card-foreground`, `popover`, `popover-foreground`, `primary`, `primary-foreground`, `secondary`, `secondary-foreground`, `muted`, `muted-foreground`, `accent`, `accent-foreground`, `destructive`, `destructive-foreground`, `border`, `input`, `ring`, `radius`

Plus sidebar variants: `sidebar-background`, `sidebar-foreground`, `sidebar-primary`, `sidebar-accent`, `sidebar-border`

Plus chart tokens: `chart-1` through `chart-5` for data visualization series.

### Naming convention

Pattern: `--{category}-{element}-{property}-{state}`

- `--color-primary` (semantic color)
- `--button-primary-bg` (component token)
- `--button-primary-bg-hover` (component + state)

### Token categories

| Category | What to define |
|---|---|
| Color | background, foreground, primary, secondary, muted, accent, destructive, border, ring, chart-1 through chart-5 |
| Radius | One base value (e.g., 6px), compute sm/md/lg/xl/full from it |
| Shadow | xs through 2xl (use Tailwind defaults) |
| Z-index | See z-index section below |
| Motion | duration-fast (100ms), duration-normal (200ms), duration-slow (300ms), easing |

### Dark mode swapping

Light tokens on `:root`, dark tokens on `.dark`. Use the class strategy (not media query) for dashboards — users want explicit control.

```css
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
}
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
}
```

---

## Motion and animation

### What to animate (and how fast)

| Element | Animation | Duration | Easing |
|---|---|---|---|
| Button hover/press | Background color, scale(0.98) | 150ms | `ease-out` |
| Dropdown open | Opacity 0>1, translateY(-4px>0) | 150ms | `ease-out` |
| Dropdown close | Reverse | 100ms | `ease-in` |
| Modal enter | Overlay fade + content scale(0.95>1) | 200ms | `cubic-bezier(0.16, 1, 0.3, 1)` |
| Modal exit | Reverse | 150ms | `ease-in` |
| Drawer slide in | translateX(100%>0) | 250ms | `cubic-bezier(0.32, 0.72, 0, 1)` |
| Drawer slide out | Reverse | 200ms | `ease-in` |
| Toast enter | translateY(100%>0) + fade | 200ms | `ease-out` |
| Toast exit | Opacity 0, height collapse | 150ms | `ease-in` |
| Skeleton shimmer | Gradient sweep left-to-right | 1.5-2s | `linear` (infinite) |
| Sidebar collapse | Width 240px>64px | 200ms | `ease-in-out` |
| Accordion expand | Height 0>auto | 200ms | `ease-out` |
| Chart data update | Value interpolation | 300-500ms | `ease-out` |

### Duration guidelines

- **Instant feedback** (hover, press, toggle): 100-150ms
- **Standard transitions** (open/close, show/hide): 150-250ms
- **Complex motion** (drawer slide, page transition): 200-350ms
- **Data animation** (charts, counters): 300-600ms
- **Never exceed 500ms** for any UI transition. This is a tool, not a presentation.

### Easing curves

| Use | CSS value |
|---|---|
| Default / general | `ease` or `cubic-bezier(0.4, 0, 0.2, 1)` |
| Enter / appear | `ease-out` or `cubic-bezier(0, 0, 0.2, 1)` |
| Exit / disappear | `ease-in` or `cubic-bezier(0.4, 0, 1, 1)` |
| Modal open (overshoot) | `cubic-bezier(0.16, 1, 0.3, 1)` |
| Drawer slide | `cubic-bezier(0.32, 0.72, 0, 1)` |
| Linear (shimmer, progress) | `linear` |

### Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Keep opacity fades (safe for motion-sensitive users). Remove all transforms, slides, and bounces.

### What NOT to animate

- Table row data changes — just swap values
- Filter application results — just re-render
- Pagination — just swap content
- Sort column changes
- Breadcrumb updates
- Anything that would delay a power user

---

## Data-dense UI patterns

### Number formatting

Use `Intl.NumberFormat` for all number display. Never hand-roll.

```javascript
// Compact (1.2K, 3.4M)
new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 })

// Currency
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })

// Percentage
new Intl.NumberFormat('en', { style: 'percent', minimumFractionDigits: 1 })
```

Rules:
- Compact display for stat cards and chart axes. Full precision in tables and detail views.
- Always locale-aware — pass the user's locale, never hardcode `'en-US'`.
- Tabular figures for all number columns.
- Right-align all numeric columns AND their headers.

### Timestamps

| Context | Format | Example |
|---|---|---|
| Within 1 minute | Relative | "just now" |
| Within 1 hour | Relative | "12 min ago" |
| Within 24 hours | Relative | "3 hours ago" |
| Within 7 days | Relative | "2 days ago" |
| Older than 7 days | Absolute | "Mar 15, 2026" |
| Older than 1 year | Absolute with year | "Mar 15, 2025" |
| Tables / audit logs | Absolute always | "2026-03-15 14:32:05" |
| Hover tooltip on relative | Full absolute | "March 15, 2026 at 2:32 PM EST" |

Rule: Audit logs and data tables always use absolute timestamps. Relative is for activity feeds and casual contexts. Always show full timestamp on hover.

### Inline editing affordance

- Hover: show subtle pencil icon or background change (`bg-accent/50`).
- Click: replace content with an input, auto-focused, pre-filled.
- Save on Enter or blur. Cancel on Escape.
- Brief inline success indicator (checkmark, fades after 1.5s).
- Never inline-edit critical fields (email, permissions, financial amounts) — use a modal or detail page.

### Skeleton loading

- Skeleton shape must match the content it replaces: rectangle for text, circle for avatars, rounded rect for cards.
- Table skeletons: 5-8 rows with **randomized widths** (not identical) so they look organic.
- Shimmer: `linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent)` sweeping at 1.5s, linear, infinite.
- If data loads in <200ms, don't show a skeleton at all — use a `setTimeout` delay before rendering to prevent flash.

---

## Micro-copy

### Button labels

- **Primary actions:** Verb + noun. "Create Project", "Save Changes", "Send Invite", "Export Report".
- **When context is obvious:** Verb only. "Save", "Delete" (in a dialog where the noun is clear from the title).
- **Never:** "OK", "Yes", "No", "Click Here", "Submit" (as a generic).
- **Destructive confirmation:** Repeat the specific action. "Delete 3 Users" not "Confirm" or "Yes".
- **Loading state:** Present participle. "Creating..." "Saving..."

### Form labels

- **Sentence case** for all labels ("First name", "Email address", not "First Name", "EMAIL ADDRESS"). This is the modern standard.
- Label above input (not beside, not placeholder-as-label).
- Required: if most fields are required, mark optional fields with "(optional)" suffix instead of asterisks.
- Help text: muted color, 12px, below the input. Specific instructions, not restating the label.

### Error messages

Three parts: **What happened** + **Why** + **What to do.**
- "That email is already registered. Try signing in instead, or use a different email."
- "Password must be at least 8 characters. Add 3 more characters."
- Never: "Invalid input", "Error", "Something went wrong", "Validation failed."

Show inline under the field in danger color, not in a banner at the top (unless the error is form-wide).

### Empty state copy

Structure: **Title** + **Description** + **CTA button**.
- Title: what the user will see here. "No projects yet."
- Description: one sentence of value. "Create your first project to start tracking work."
- CTA: verb + noun. "Create Project".
- Don't say "Nothing to see here." Frame positively.

### Toast messages

| Type | Icon | Duration | Example |
|---|---|---|---|
| Success | Checkmark (green) | 3-5s auto-dismiss | "Project created successfully." |
| Error | X circle (red) | Persistent | "Failed to save. Please try again." |
| Warning | Triangle (amber) | 5-8s | "API key expires in 3 days." |
| Info | Info circle (blue) | 5s | "2 users were imported." |

Position: bottom-right (or top-right). Stack max 3, queue the rest. Always include a dismiss X.

### Confirmation dialog copy

- Title: verb + noun, specific. "Delete 3 users?" not "Are you sure?"
- Body: state the consequence. "This will permanently remove these users and all their data."
- Cancel: "Cancel" (secondary). Always present.
- Confirm: specific verb matching action. "Delete 3 Users" (destructive variant). Never "OK" or "Yes".

### Placeholder text

- Format hints only, not labels. `placeholder="name@company.com"` not `placeholder="Email"`.
- Muted color, lighter weight than real input text.
- If the user needs persistent help, use help text below the input, not placeholder.

---

## Responsive adaptation

### Component-specific behavior

**Tables:**
- >= 1024px: full table, all columns.
- 768-1023px: hide low-priority columns. Keep: name/title, status, primary metric, actions.
- < 768px: horizontal scroll with sticky first column and shadow fade on the right edge. OR convert to card layout (each row becomes a stacked card).

**Filter bars:**
- Desktop: inline horizontal row.
- Tablet: wrap to 2 rows or collapse less-used into "More Filters" dropdown.
- Mobile: single "Filters" button > full-screen drawer with stacked controls. Badge with active filter count.

**Button groups:**
- Desktop: all visible in a row.
- Mobile: primary action visible, rest overflow into a `...` menu.

**Stat cards:**
- Desktop: 4-column grid.
- Tablet: 2-column.
- Mobile: 2-column compact or single-column stack.
- Never 3-column — breaks awkwardly to 2.

**Charts:**
- Maintain aspect ratio, single chart per row on mobile.
- Remove legends on mobile, use direct labels instead.
- Enable horizontal scroll for wide bar charts.

**Forms:**
- Always single column on mobile.
- Desktop: single column for standard forms (reads better). Two columns ONLY for short paired fields (city + state, first + last name).
- Never three-column forms.

---

## Dark mode

### Surface elevation

In dark mode, **lighter = higher elevation** (closer to the light source). Inverted from light mode.

| Level | Light mode | Dark mode |
|---|---|---|
| Page background | White | Near-black (`#0a0a0a` to `#171717`) |
| Card / panel | White (border-separated) | Slightly lighter (`#1a1a1a`) |
| Popover / dropdown | White + shadow | Lighter still (`#262626`) |
| Modal | White + heavy shadow | Even lighter (`#2a2a2a`) |

**Never pure black** (`#000`) for the page background. It creates excessive contrast with text and looks harsh. Use `#0a0a0a` to `#171717`.

### Color adjustments

- **Brand colors:** Reduce saturation ~20%, increase lightness ~10-15%. Vibrant blue on white looks neon/jarring on dark gray.
- **Text hierarchy:** Primary text at ~87-90% white, secondary at ~60-65%, disabled at ~38%.
- **Borders:** More important in dark mode (shadows are less visible). Adjust opacity up slightly.
- **Shadows:** Increase opacity from 10% to 25-40%. Or skip shadows entirely in dark mode and rely on surface color differences + borders.

### Chart colors

- Desaturate ~15-20% and lighten ~10%.
- Every chart color must meet WCAG 3:1 contrast against the chart area background.
- Define dark-mode chart tokens (`chart-1` through `chart-5`) that swap with the theme.

### Image treatment

- Reduce brightness slightly (`filter: brightness(0.9)`) on user-uploaded images.
- Provide light-on-dark logo variant. `filter: invert(1)` as last resort.

---

## Icons

### Sizing scale

| Size | Use |
|---|---|
| 12px | Inline with small/caption text (rare) |
| 16px | Inline with body text, table row actions, dense UI |
| 20px | Inside buttons (with text), form field icons, nav items (compact) |
| 24px | Standalone, nav items (standard), card actions — the default icon size |
| 32px | Empty state feature icons, large action buttons |
| 40-48px | Empty state centerpieces, hero illustrations |

### Filled vs outlined

- **Outlined (stroke):** Default for dashboards. Lower visual weight, cleaner in data-dense layouts. Use for nav, toolbars, table actions, form icons.
- **Filled (solid):** Use for active/selected states (active nav item), status indicators, and sizes below 20px where stroke detail breaks down.
- Never mix filled and outlined in the same context. Active state can switch to filled as a selection indicator.

### Icon + label pairing

- Gap: 8px (default), 6px (compact).
- Icon left of label (LTR). Exception: external link arrow goes right.
- Icon color matches label color unless it's a status indicator.
- Vertical alignment: center to the text's x-height, not full line-height.

### Icon-only buttons

Acceptable ONLY when:
1. The icon is universally understood (X/close, search/magnifier, gear/settings, hamburger/menu, plus/add, trash/delete), AND
2. The button has `aria-label` ("Close dialog", not "X"), AND
3. A tooltip shows the label on hover.

Minimum touch target: 44x44px even if the icon is 16px.

---

## Shadow and elevation

### Shadow scale

| Token | Use |
|---|---|
| `shadow-xs` | Subtle lift — input fields, secondary buttons |
| `shadow-sm` | Standard cards (when not using border-only), floating toolbar |
| `shadow-md` | Dropdowns, popovers, elevated cards |
| `shadow-lg` | Drawers, panels, command palette |
| `shadow-xl` | Modals, dialogs |

### Border vs shadow

Modern dashboard trend (Linear, Vercel, shadcn/ui): prefer **1px borders** over shadows for cards and sections. Reserve shadows for overlays (dropdowns, modals, drawers). This produces a cleaner, flatter, more data-focused look.

### Focus states

- Use `ring` utilities for keyboard focus, not shadow.
- Default: 2px ring in the `ring` token color, 2px offset from the element.
- **Never remove focus outlines.** Style them if the defaults are ugly — don't delete them.

### Dark mode shadows

Increase opacity from 10% to 25-40%. Or skip shadows entirely in dark mode and rely on surface color + borders (the Material Design 3 approach).

---

## Z-index management

### Layering system

| Layer | Value | Components |
|---|---|---|
| Base content | `0` | Page content, cards, tables |
| Sticky elements | `100` | Sticky table headers, sticky sidebar |
| Floating actions | `200` | FABs, floating toolbars |
| Dropdown / Popover | `1000` | Menus, popovers, date pickers, selects |
| Sticky header | `1100` | App bar, top navigation |
| Drawer | `1200` | Sidebar drawer overlay, sheets |
| Modal backdrop + modal | `1300` | Dialog content and overlay |
| Toast | `1400` | Toast notifications (must appear above modals) |
| Tooltip | `1500` | Tooltips (above everything) |

### Rules

1. **Never use arbitrary values** (no `z-index: 99999`). Reference a token.
2. **100-increment gaps** between layers for sub-layering room.
3. **Portals solve most problems:** render modals, dropdowns, tooltips, and toasts at the end of `<body>`. Removes them from parent stacking contexts.
4. **Z-index only works on positioned elements** (relative, absolute, fixed, sticky).
5. **Toasts above modals:** error toasts must be visible even when a modal is open.

```css
:root {
  --z-base: 0;
  --z-sticky: 100;
  --z-dropdown: 1000;
  --z-header: 1100;
  --z-drawer: 1200;
  --z-modal: 1300;
  --z-toast: 1400;
  --z-tooltip: 1500;
}
```

---

## Color pairing and contrast

### Every background needs a tested foreground

Never use `bg-primary text-white`. Use `bg-primary text-primary-foreground`. The `-foreground` token pattern (from shadcn/ui) pairs every background with a tested, accessible text color. When the primary color changes or dark mode activates, the foreground adjusts automatically.

The auto-foreground algorithm: compute relative luminance of the background. If luminance > ~0.18, use dark text. Otherwise, use light text. Mid-tone backgrounds (grays ~50%, muted pastels) may fail with BOTH pure black and white — use off-black/off-white or avoid these as text backgrounds.

### Contrast requirements

| Element | Minimum ratio | Standard |
|---|---|---|
| Normal text | 4.5:1 | WCAG AA (the baseline) |
| Large text (18pt+ or 14pt+ bold) | 3:1 | WCAG AA |
| UI components (borders, icons, controls) | 3:1 | WCAG AA |
| Enhanced (aim for this) | 7:1 | WCAG AAA |

Check with: Chrome DevTools color picker (inline contrast ratio), axe DevTools (automated audit), WebAIM Contrast Checker.

### Buttons need three contrast checks

Not just text-vs-button, but three relationships simultaneously:
1. **Button text vs. button background** — 4.5:1
2. **Button background vs. page surface** — 3:1 (so the button is visually distinct)
3. **Focus state vs. default state** — 3:1 change in the focus indicator

### Status colors: the inversion pattern

Every status color needs three variants: foreground (text/icon), background (badges/alerts), and muted (large areas/row highlights).

The Tailwind inversion pattern for badges that work in both modes:

```
Light mode:  bg-green-100 text-green-800
Dark mode:   bg-green-900 text-green-200

Light mode:  bg-red-100 text-red-800
Dark mode:   bg-red-900 text-red-200
```

Backgrounds use the 100/900 ends of the scale, text uses the 800/200 ends. This guarantees high contrast in both modes.

For alerts, add a left border in the full-strength color:
```
Error:   bg-red-50 border-l-4 border-red-500 text-red-800
Warning: bg-yellow-50 border-l-4 border-yellow-500 text-yellow-800
```

### Sidebar and header with colored backgrounds

When the sidebar or header has a dark or colored background, ALL elements inside must use separate tokens:

- **Sidebar tokens:** `sidebar-background`, `sidebar-foreground`, `sidebar-primary`, `sidebar-accent`, `sidebar-border` — separate from the main content tokens
- **Why:** if the sidebar is dark navy and the content area is white, they need independent foreground colors. Using the main `foreground` token inside a dark sidebar produces invisible text.
- **Active nav item:** needs EXTRA contrast against the sidebar background — lighter/darker background strip + bold text or left border indicator
- **Hover:** subtle background change (white at 5-10% opacity on dark sidebars)

### Brand color problems

**Too light (yellow, lime):** white text fails contrast. Solutions: use dark text (auto-foreground), darken for interactive use, or relegate to decorative role and create a darker "accessible primary."

**Too dark (navy, near-black):** disappears in dark mode, loses brand identity against dark surfaces. Solutions: lighten for dark mode (use mid-tone 400-500), add saturation.

**Dark mode adaptation:** reduce saturation ~10-20% and increase lightness ~10-15%. Vibrant colors cause eye strain on dark backgrounds. The Radix Colors approach: a 12-step scale with step 9 as the pure brand color, steps 1-8 for backgrounds/borders, steps 10-12 for text — all with guaranteed accessible pairings.

### Color accessibility

**Color blindness-safe palette:** blue + orange is the universally safest combination. Avoid red-green as the primary distinction. The Wong palette (from Nature Methods) is specifically designed for all common color vision deficiencies.

**Simulation tools:** Chrome DevTools Rendering tab > Emulate vision deficiencies (protanopia, deuteranopia, tritanopia). Sim Daltonism (macOS) for real-time overlay.

**The triple-indicator rule:** every status uses icon (distinct shape) + label (text) + color. A checkmark and an X are recognizable regardless of color. Use: checkmark circle for success, X circle for error, triangle for warning, info circle for info — distinct shapes, not just colors.

### Focus ring that works on ALL backgrounds

The two-color technique: a white inner ring + black outer ring (or vice versa). As long as the two colors have 9:1 contrast with each other, at least ONE will always have 3:1 contrast against any background. Mathematically guaranteed.

```css
*:focus-visible {
  outline: 2px solid #FFFFFF;
  outline-offset: 2px;
  box-shadow: 0 0 0 4px #000000;
}
```

Do NOT use `outline: none` and rely on `box-shadow` alone — Windows High Contrast Mode suppresses box-shadow.

---

## UI consistency

### Visual consistency rules

Same component, same appearance, everywhere. No exceptions.

- **Sizes:** if buttons are 36px tall, they're 36px tall on EVERY page. Inputs match button height.
- **Spacing:** if cards have 16px padding, they have 16px padding everywhere. Form field gaps are identical across all forms.
- **Typography:** h1 is h1 everywhere — same size, weight, line-height. Don't use a different heading scale on Settings vs Dashboard.
- **Border radius:** one radius for everything — buttons, cards, inputs, modals, dropdowns. 6px or 8px. Don't mix 4px buttons with 12px cards.
- **Shadows:** same shadow for the same elevation level across all pages.

**Design tokens are the enforcement mechanism.** `rounded-md` is easier than `rounded-[7px]`. `text-foreground` is easier than `text-[#1a1a1a]`. When someone reaches for an arbitrary value, that's a violation. Catch it in code review.

### Interaction consistency

- **Same action = same pattern:** if "Delete User" shows a confirmation dialog with red button, then "Delete Project" shows the exact same dialog structure, colors, and button order.
- **Same feedback:** success toast for create, success toast for edit. Not toast for one and inline for another.
- **Same loading pattern per component type:** tables use skeleton rows (not spinners), cards use skeleton cards, buttons show inline spinner when pending. Choose once, apply everywhere.
- **Same empty state structure:** title + description + CTA on every empty page. Not varied formats.
- **Same error handling:** inline field errors on ALL forms. Not inline on login but banner on settings.
- **Same hover/focus:** every clickable element at the same level gets the same hover treatment.

### Layout consistency

- **Page header:** same structure on every page — title left, actions right, same height, same spacing.
- **Content width:** same max-width or same full-width behavior across pages of the same type.
- **Table alignment:** numbers right-aligned in ALL tables. Dates in the same format everywhere. Actions always the rightmost column.
- **Form layout:** labels above inputs on ALL forms. Not above on some and beside on others.
- **Action placement:** primary action always top-right of page header. Form submit always bottom-right. Never inconsistent.

### Consistency audit

How to catch drift:

1. **Component inventory:** search for duplicate implementations (`StatusBadge` in two files with different styling).
2. **Hardcoded value scan:** `grep` for hex codes, `rgb(`, arbitrary Tailwind values (`text-[#...]`, `p-[...]`) in component files. These bypass the token system.
3. **Cross-page comparison:** render the same data type (dates, currency, status badges) on different pages. They must look identical.
4. **Storybook:** see all component variants in one place. Every button state, every badge color, every form input state — side by side.
5. **Visual regression in CI:** Chromatic or Playwright screenshots catch unintended changes before merge.
6. **ESLint/Stylelint rules:** flag hardcoded colors, arbitrary spacing values, raw Tailwind scale usage when semantic tokens exist.

---

## Don'ts

- **Don't use more than 2 font families.** One sans-serif for UI, one monospace for data/code. A third is clutter.
- **Don't use 16px as body text in a dashboard.** 14px is the standard for data-dense tools. 16px wastes space.
- **Don't animate pagination, sort, or filter results.** Swap the content instantly.
- **Don't use rainbow colors for status.** Five semantic colors (green/amber/red/blue/gray) cover every status. Map them consistently.
- **Don't use shadow AND border on the same card.** Pick one. Border is the modern default.
- **Don't mix icon families.** One family (Lucide, Heroicons, Phosphor). Mixed families look chaotic.
- **Don't mix filled and outlined icons** in the same context.
- **Don't use custom z-index values.** Use the token scale. `z-index: 99999` is a symptom.
- **Don't remove focus outlines.** Style them — don't delete them.
- **Don't use `color` alone to convey meaning.** Always pair with icon, label, or shape.
- **Don't exceed 500ms** on any UI transition in a dashboard.
- **Don't show skeletons for loads under 200ms.** Add a delay before rendering the skeleton.
- **Don't use pure black** (`#000`) as dark mode background. Use `#0a0a0a` to `#171717`.
- **Don't hand-roll number formatting.** Use `Intl.NumberFormat` with the user's locale.
- **Don't use "Submit" as a button label.** Use verb + noun: "Create Project", "Save Changes".

---

## Visual identity: the decision framework

Every dashboard must have its own visual personality, derived from the user's prompt (the domain, the audience, the emotional register), not from randomness and never from component library defaults.

AI-generated dashboards converge on the same look: white background, gray sidebar, blue primary, Inter font, 8px radius, shadcn defaults. After seeing three of them, they're indistinguishable. This is the visual equivalent of `const users = [{ name: "User 1" }]`: technically present, functionally hollow. A dashboard built for a hospital should not look identical to one built for a gaming company.

### Step A. Pick an aesthetic archetype

Read the user's domain, audience, and tone, then choose the closest match:

| Archetype | Domains | Personality |
|---|---|---|
| **Clean corporate** | Finance, legal, insurance, government, enterprise SaaS | Trust, precision, neutrality. Navy/slate palette, sharp corners, serif or geometric sans headings. |
| **Warm neutral** | HR, education, hospitality, non-profit, recruiting | Approachable, human, calm. Earth tones or warm grays, medium radius, friendly sans-serif. |
| **Bold saturated** | Marketing, CRM, gaming, esports, social media | Energy, confidence, action. Vibrant primary, high-contrast accents, punchy headings, rounded UI. |
| **Dark-first technical** | DevOps, cybersecurity, IoT, AI/ML, monitoring | Precision, control, immersion. Dark surfaces, monospace accents, sharp corners, terminal-inspired. |
| **Soft modern** | Healthcare, wellness, consumer SaaS, productivity | Clean, gentle, trustworthy. Soft blues/greens, generous whitespace, rounded corners, light shadows. |
| **High-contrast editorial** | Media, publishing, CMS, content platforms | Authority, readability, density. Strong typographic hierarchy, serif headings, tight grids. |
| **Playful rounded** | Food service, consumer apps, community platforms | Fun, inviting, casual. Saturated pastels, large radius, bouncy micro-interactions, illustration-friendly. |
| **Industrial minimal** | Logistics, construction, manufacturing, supply chain | Function-first, utilitarian, dense. Neutral palette, minimal decoration, compact spacing, strong borders. |
| **Luxury restrained** | Real estate, premium SaaS, fashion, high-end retail | Sophistication, restraint, space. Muted palette, generous whitespace, thin fonts, subtle shadows. |
| **Data-dense operational** | Analytics, trading, fleet management, telecom | Information density, scanability, speed. Compact layout, tabular data, monospace numbers, minimal chrome. |

If the domain spans two archetypes (e.g., "premium analytics"), blend them. Take the palette from one and the density from the other. State the choice in the architecture note.

### Step B. Make 5 concrete decisions

Write these into the architecture note alongside the stack and route map.

**Decision 1. Color palette.** Derive from the domain's emotional register:

| Domain mood | Primary hue range | Example |
|---|---|---|
| Trust, stability (finance, healthcare, legal) | Blue 200–230, Slate 210–220 | `hsl(217 71% 45%)` |
| Growth, nature (agriculture, sustainability) | Green 130–160 | `hsl(142 64% 38%)` |
| Energy, urgency (gaming, marketing, sales) | Orange 15–30, Red 0–10 | `hsl(24 95% 53%)` |
| Creativity, premium (media, design, luxury) | Purple 260–290, Rose 330–350 | `hsl(271 76% 53%)` |
| Warmth, hospitality (HR, education, food) | Amber 35–50, Warm gray | `hsl(43 96% 56%)` |
| Technology, precision (DevOps, IoT, cyber) | Cyan 180–200, Cool gray | `hsl(192 91% 36%)` |
| Neutrality, authority (government, enterprise) | Slate 200–220, minimal accent | `hsl(215 16% 47%)` |

Build the full palette from one primary:
1. Pick the primary hue from the table above.
2. Derive the secondary accent: +120° or +180° on the hue wheel, reduced saturation.
3. Surface tones: desaturate the primary to 5–10% saturation for backgrounds.
4. Sidebar: darken the primary to 15–20% lightness for dark sidebars, or use the surface tone for light sidebars.
5. Semantic colors (success/warning/error/info) stay constant. Only adjust lightness to contrast with your surfaces.

**Decision 2. Typography pairing.** Pick one pair from the table. Every pair is on Google Fonts and tested for dashboard readability.

| Personality | Heading font | Body font | Best for |
|---|---|---|---|
| **Corporate precision** | DM Sans (500–700) | DM Sans (400) | Finance, legal, enterprise |
| **Warm professional** | Nunito (600–700) | Nunito Sans (400) | HR, education, hospitality |
| **Modern technical** | Space Grotesk (500–700) | IBM Plex Sans (400) | DevOps, analytics, developer tools |
| **Editorial authority** | Fraunces (600) | Source Serif 4 (400) | Media, publishing, CMS |
| **Soft consumer** | Plus Jakarta Sans (600–700) | Plus Jakarta Sans (400) | Consumer SaaS, productivity |
| **Bold startup** | Outfit (600–700) | Inter (400) | Marketing, CRM, general SaaS |
| **Playful friendly** | Quicksand (600–700) | Nunito Sans (400) | Food, community, consumer |
| **Luxury restrained** | Cormorant Garamond (500) | Lato (400) | Real estate, premium, fashion |
| **Industrial utility** | Barlow (600–700) | Barlow (400) | Logistics, construction, manufacturing |
| **Data-dense mono** | JetBrains Mono (500–700) | Inter (400) | Trading, monitoring, cybersecurity |
| **Clean geometric** | Satoshi (500–700) | General Sans (400) | Minimal SaaS, design tools |
| **Humanist warmth** | Merriweather Sans (700) | Source Sans 3 (400) | Healthcare, wellness, non-profit |
| **Tech-forward** | Sora (600) | DM Sans (400) | AI/ML, IoT, futuristic |
| **Dense professional** | Figtree (600) | Figtree (400) | Analytics, reporting, dense data |

If the user specifies a font or brand, use it. The table is for when no font is specified.

**Decision 3. Border radius.**

| Style | Values | Personality |
|---|---|---|
| **Sharp** | `--radius-sm: 2px; --radius-md: 4px; --radius-lg: 6px;` | Corporate, technical, editorial, industrial |
| **Medium** | `--radius-sm: 4px; --radius-md: 8px; --radius-lg: 12px;` | General SaaS, professional, most dashboards |
| **Rounded** | `--radius-sm: 8px; --radius-md: 12px; --radius-lg: 16px;` | Consumer, playful, friendly, soft |
| **Pill** | `--radius-sm: 12px; --radius-md: 16px; --radius-lg: 24px;` | Ultra-modern, opinionated, design-forward |

Apply uniformly: buttons, cards, inputs, badges, dropdowns, modals all use the same scale. Inconsistent radius (round buttons + sharp cards) looks broken.

**Decision 4. Density.**

| Level | Row height | Gap | Padding | Best for |
|---|---|---|---|---|
| **Compact** | 32px | 8–12px | 12–16px | Data-heavy: analytics, trading, monitoring, tables with 50+ rows |
| **Comfortable** | 40px | 16px | 16–24px | General SaaS, admin panels, most dashboards |
| **Spacious** | 48px | 20–24px | 24–32px | Consumer-facing, onboarding-heavy, low data density |

Density affects every surface: table rows, sidebar items, form fields, card padding, section gaps. Set it once via the spacing unit token and derive everything from it.

**Decision 5. Signature detail.** One distinctive element that makes this dashboard recognizable. Pick one:

- **Colored sidebar.** Sidebar uses a dark or tinted version of the primary color instead of neutral gray.
- **Accent header bar.** A 3 to 4px colored bar at the top of the page or under the header.
- **Card left-border.** Cards and panels have a colored left border (3 to 4px) using the primary or accent.
- **Gradient sidebar.** Sidebar background is a subtle gradient from primary-dark to primary-darker.
- **Tinted page headers.** Each section's header area has a light tint of the primary (5 to 10% opacity).
- **Shadow depth.** Distinctive shadow treatment: deep layered (luxury), flat no-shadow (industrial), soft diffused (modern).
- **Icon style.** Outlined thin (minimal), filled (bold), or duotone (premium), consistent across the entire dashboard.
- **Sidebar dividers.** Thin lines, spacing gaps, or labeled section headers with different styling.
- **Active nav indicator.** Left border accent, full background fill, or pill-shaped highlight.
- **Number styling.** Tabular or monospace numbers in all data displays with distinct weight or color.

### Step C. Output the design tokens

Before building any components, create the CSS variable block and apply it globally:

```css
:root {
  /* --- Visual identity: [archetype name] --- */
  --color-primary: hsl(222 47% 31%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(222 47% 25%);
  --color-accent: hsl(173 58% 39%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(220 14% 96%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(222 47% 18%);
  --color-sidebar-foreground: hsl(220 14% 90%);
  --color-success: hsl(142 71% 35%);
  --color-warning: hsl(38 92% 50%);
  --color-error: hsl(0 84% 50%);
  --color-info: hsl(210 92% 45%);
  --font-heading: 'DM Sans', sans-serif;
  --font-body: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --radius-sm: 4px; --radius-md: 8px; --radius-lg: 12px; --radius-full: 9999px;
  --spacing-unit: 16px; --row-height: 40px;
}
```

Adjust every value to match the chosen archetype. This block is the source of truth. Every component references these tokens, never hardcoded colors or font stacks.

### Applying tokens to common setups

- **shadcn/ui plus Tailwind.** Override the CSS variables in `globals.css`. shadcn's theming already uses `--primary`, `--secondary`, etc. Map your identity tokens to their variable names. Change the font in `tailwind.config.ts` under `theme.extend.fontFamily`.
- **Plain Tailwind.** Add the tokens to `:root` in your global CSS. Reference via `var(--color-primary)` in custom classes, or extend the Tailwind config to use them.
- **CSS Modules or Vanilla CSS.** Same `:root` variables. Import the global stylesheet first.
- **MUI, Chakra, or Mantine.** Create a custom theme object that maps to your token values. Pass it to the ThemeProvider at the root.

### Visual identity anti-patterns

- Using unmodified shadcn/ui default theme (the gray/blue one every AI uses)
- Using Inter as both heading and body font with no variation
- Using `hsl(222.2 47.4% 11.2%)` as primary (this is shadcn's literal default, which means you didn't customize)
- Applying a color to the primary button but leaving everything else default
- Picking a color palette but not applying it to the sidebar, header, and page backgrounds
- Using different border radii on different component types (round buttons plus sharp cards)
- Choosing "dark mode" as the personality instead of an actual aesthetic direction

---

## Visual identity token sets

These are 10 ready-to-use token sets, one per aesthetic archetype from Step A above. Copy the closest match, adjust to the specific project, and paste into your global stylesheet. Every component should reference these variables, never hardcoded values.

### Clean Corporate

For: finance, legal, insurance, government, enterprise SaaS.

```css
:root {
  /* --- Visual identity: Clean Corporate --- */
  --color-primary: hsl(217 71% 45%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(217 71% 38%);
  --color-accent: hsl(199 89% 48%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(210 20% 98%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(217 33% 17%);
  --color-sidebar-foreground: hsl(214 32% 91%);
  --color-sidebar-active: hsl(217 71% 45%);
  --color-muted: hsl(215 16% 47%);
  --color-border: hsl(214 32% 91%);
  --color-success: hsl(142 71% 35%);
  --color-warning: hsl(38 92% 50%);
  --color-error: hsl(0 84% 50%);
  --color-info: hsl(210 92% 45%);
  --font-heading: 'DM Sans', sans-serif;
  --font-body: 'DM Sans', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --radius-sm: 2px; --radius-md: 4px; --radius-lg: 6px;
  --spacing-unit: 16px; --row-height: 40px;
}
```

Signature: dark navy sidebar with sharp corners. Professional, restrained, trustworthy.

### Warm Neutral

For: HR, education, hospitality, non-profit, recruiting.

```css
:root {
  /* --- Visual identity: Warm Neutral --- */
  --color-primary: hsl(25 75% 47%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(25 75% 40%);
  --color-accent: hsl(173 58% 39%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(30 25% 97%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(30 10% 96%);
  --color-sidebar-foreground: hsl(25 10% 30%);
  --color-sidebar-active: hsl(25 75% 47%);
  --color-muted: hsl(25 8% 52%);
  --color-border: hsl(30 15% 90%);
  --color-success: hsl(152 56% 39%);
  --color-warning: hsl(43 96% 56%);
  --color-error: hsl(4 80% 52%);
  --color-info: hsl(210 75% 50%);
  --font-heading: 'Nunito', sans-serif;
  --font-body: 'Nunito Sans', sans-serif;
  --font-mono: 'IBM Plex Mono', monospace;
  --radius-sm: 6px; --radius-md: 8px; --radius-lg: 12px;
  --spacing-unit: 16px; --row-height: 40px;
}
```

Signature: warm-tinted surfaces with a light sidebar. Approachable, human, calming.

### Bold Saturated

For: marketing, CRM, gaming, esports, social media.

```css
:root {
  /* --- Visual identity: Bold Saturated --- */
  --color-primary: hsl(262 83% 58%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(262 83% 50%);
  --color-accent: hsl(330 81% 60%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(260 10% 97%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(262 50% 15%);
  --color-sidebar-foreground: hsl(262 20% 90%);
  --color-sidebar-active: hsl(262 83% 58%);
  --color-muted: hsl(262 10% 50%);
  --color-border: hsl(262 15% 90%);
  --color-success: hsl(142 71% 35%);
  --color-warning: hsl(38 92% 50%);
  --color-error: hsl(0 84% 50%);
  --color-info: hsl(210 92% 45%);
  --font-heading: 'Outfit', sans-serif;
  --font-body: 'Inter', sans-serif;
  --font-mono: 'Fira Code', monospace;
  --radius-sm: 8px; --radius-md: 12px; --radius-lg: 16px;
  --spacing-unit: 16px; --row-height: 40px;
}
```

Signature: vibrant purple-to-pink gradient sidebar. Energetic, bold, confident.

### Dark-First Technical

For: DevOps, cybersecurity, IoT, AI/ML, monitoring.

```css
:root {
  /* --- Visual identity: Dark-First Technical --- */
  --color-primary: hsl(192 91% 36%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(192 91% 30%);
  --color-accent: hsl(142 72% 50%);
  --color-accent-foreground: hsl(0 0% 10%);
  --color-background: hsl(220 13% 10%);
  --color-surface: hsl(220 13% 14%);
  --color-sidebar: hsl(220 13% 8%);
  --color-sidebar-foreground: hsl(220 10% 75%);
  --color-sidebar-active: hsl(192 91% 36%);
  --color-muted: hsl(220 10% 50%);
  --color-border: hsl(220 13% 20%);
  --color-success: hsl(142 72% 50%);
  --color-warning: hsl(43 96% 56%);
  --color-error: hsl(0 72% 55%);
  --color-info: hsl(192 91% 50%);
  --font-heading: 'Space Grotesk', sans-serif;
  --font-body: 'IBM Plex Sans', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --radius-sm: 2px; --radius-md: 4px; --radius-lg: 6px;
  --spacing-unit: 12px; --row-height: 32px;
}
```

Signature: dark background by default, cyan/green accents, monospace numbers in data. Terminal-inspired.

### Soft Modern

For: healthcare, wellness, consumer SaaS, productivity.

```css
:root {
  /* --- Visual identity: Soft Modern --- */
  --color-primary: hsl(210 85% 55%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(210 85% 48%);
  --color-accent: hsl(168 65% 45%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(210 20% 98%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(0 0% 100%);
  --color-sidebar-foreground: hsl(215 16% 35%);
  --color-sidebar-active: hsl(210 85% 96%);
  --color-muted: hsl(215 16% 55%);
  --color-border: hsl(210 18% 92%);
  --color-success: hsl(152 56% 39%);
  --color-warning: hsl(38 92% 50%);
  --color-error: hsl(0 72% 51%);
  --color-info: hsl(210 85% 55%);
  --font-heading: 'Plus Jakarta Sans', sans-serif;
  --font-body: 'Plus Jakarta Sans', sans-serif;
  --font-mono: 'IBM Plex Mono', monospace;
  --radius-sm: 8px; --radius-md: 12px; --radius-lg: 16px;
  --spacing-unit: 20px; --row-height: 44px;
}
```

Signature: white sidebar with soft blue active states, generous whitespace, rounded everything. Clean, gentle, trustworthy.

### High-Contrast Editorial

For: media, publishing, CMS, content platforms.

```css
:root {
  /* --- Visual identity: High-Contrast Editorial --- */
  --color-primary: hsl(0 0% 9%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(0 0% 20%);
  --color-accent: hsl(12 76% 50%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(40 23% 97%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(0 0% 100%);
  --color-sidebar-foreground: hsl(0 0% 20%);
  --color-sidebar-active: hsl(0 0% 9%);
  --color-muted: hsl(0 0% 45%);
  --color-border: hsl(0 0% 85%);
  --color-success: hsl(142 71% 35%);
  --color-warning: hsl(38 92% 50%);
  --color-error: hsl(0 84% 50%);
  --color-info: hsl(210 92% 45%);
  --font-heading: 'Fraunces', serif;
  --font-body: 'Source Serif 4', serif;
  --font-mono: 'IBM Plex Mono', monospace;
  --radius-sm: 0px; --radius-md: 2px; --radius-lg: 4px;
  --spacing-unit: 16px; --row-height: 40px;
}
```

Signature: serif typography, near-zero radius, strong black-and-white contrast with a single warm accent. Authoritative, literary.

### Playful Rounded

For: food service, consumer apps, community platforms.

```css
:root {
  /* --- Visual identity: Playful Rounded --- */
  --color-primary: hsl(340 82% 52%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(340 82% 45%);
  --color-accent: hsl(45 93% 58%);
  --color-accent-foreground: hsl(0 0% 15%);
  --color-background: hsl(340 15% 97%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(340 50% 18%);
  --color-sidebar-foreground: hsl(340 15% 90%);
  --color-sidebar-active: hsl(340 82% 52%);
  --color-muted: hsl(340 10% 50%);
  --color-border: hsl(340 10% 90%);
  --color-success: hsl(142 65% 40%);
  --color-warning: hsl(43 96% 56%);
  --color-error: hsl(0 80% 55%);
  --color-info: hsl(210 80% 55%);
  --font-heading: 'Quicksand', sans-serif;
  --font-body: 'Nunito Sans', sans-serif;
  --font-mono: 'Fira Code', monospace;
  --radius-sm: 12px; --radius-md: 16px; --radius-lg: 24px;
  --spacing-unit: 18px; --row-height: 44px;
}
```

Signature: large border radius everywhere, warm pink palette, friendly typography. Fun, inviting, approachable.

### Industrial Minimal

For: logistics, construction, manufacturing, supply chain.

```css
:root {
  /* --- Visual identity: Industrial Minimal --- */
  --color-primary: hsl(220 14% 30%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(220 14% 23%);
  --color-accent: hsl(43 96% 50%);
  --color-accent-foreground: hsl(0 0% 10%);
  --color-background: hsl(220 10% 96%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(220 14% 20%);
  --color-sidebar-foreground: hsl(220 10% 80%);
  --color-sidebar-active: hsl(43 96% 50%);
  --color-muted: hsl(220 10% 50%);
  --color-border: hsl(220 10% 85%);
  --color-success: hsl(142 71% 35%);
  --color-warning: hsl(43 96% 50%);
  --color-error: hsl(0 84% 50%);
  --color-info: hsl(210 80% 50%);
  --font-heading: 'Barlow', sans-serif;
  --font-body: 'Barlow', sans-serif;
  --font-mono: 'IBM Plex Mono', monospace;
  --radius-sm: 2px; --radius-md: 4px; --radius-lg: 6px;
  --spacing-unit: 12px; --row-height: 36px;
}
```

Signature: dark slate sidebar, yellow/amber accents on dark backgrounds (like safety markings), compact density, strong borders. Utilitarian, no-nonsense.

### Luxury Restrained

For: real estate, premium SaaS, fashion, high-end retail.

```css
:root {
  /* --- Visual identity: Luxury Restrained --- */
  --color-primary: hsl(30 10% 25%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(30 10% 18%);
  --color-accent: hsl(38 40% 55%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(30 15% 97%);
  --color-surface: hsl(0 0% 100%);
  --color-sidebar: hsl(0 0% 100%);
  --color-sidebar-foreground: hsl(30 10% 30%);
  --color-sidebar-active: hsl(30 10% 25%);
  --color-muted: hsl(30 5% 55%);
  --color-border: hsl(30 10% 90%);
  --color-success: hsl(152 45% 42%);
  --color-warning: hsl(38 80% 50%);
  --color-error: hsl(0 65% 48%);
  --color-info: hsl(210 60% 50%);
  --font-heading: 'Cormorant Garamond', serif;
  --font-body: 'Lato', sans-serif;
  --font-mono: 'IBM Plex Mono', monospace;
  --radius-sm: 0px; --radius-md: 2px; --radius-lg: 4px;
  --spacing-unit: 24px; --row-height: 48px;
}
```

Signature: serif headings with generous whitespace, muted warm palette, near-zero radius, subtle shadows. Sophisticated, unhurried, premium.

### Data-Dense Operational

For: analytics, trading, fleet management, telecom.

```css
:root {
  /* --- Visual identity: Data-Dense Operational --- */
  --color-primary: hsl(210 80% 50%);
  --color-primary-foreground: hsl(0 0% 100%);
  --color-primary-hover: hsl(210 80% 42%);
  --color-accent: hsl(142 72% 45%);
  --color-accent-foreground: hsl(0 0% 100%);
  --color-background: hsl(220 13% 10%);
  --color-surface: hsl(220 13% 14%);
  --color-sidebar: hsl(220 13% 8%);
  --color-sidebar-foreground: hsl(220 10% 70%);
  --color-sidebar-active: hsl(210 80% 50%);
  --color-muted: hsl(220 10% 45%);
  --color-border: hsl(220 13% 22%);
  --color-success: hsl(142 72% 45%);
  --color-warning: hsl(43 96% 56%);
  --color-error: hsl(0 72% 55%);
  --color-info: hsl(210 80% 55%);
  --font-heading: 'Figtree', sans-serif;
  --font-body: 'Figtree', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --radius-sm: 2px; --radius-md: 4px; --radius-lg: 6px;
  --spacing-unit: 8px; --row-height: 32px;
}
```

Signature: dark mode default, maximum density, monospace numbers in all data cells, minimal chrome. Every pixel is information.
