# Dark Mode Deep-Dive

This file covers everything about implementing dark mode in a dashboard/SaaS product — the CSS architecture, color mapping, image handling, chart adjustments, preference persistence, transitions, common bugs, and component-level patterns. The color system foundations are in `ui-design-patterns.md` (which covers the token hierarchy and basic dark mode surface rules); this file goes deeper into implementation.

Dark mode is not optional. It's a baseline UX expectation. But doing it well — not just inverting colors — requires deliberate decisions at every layer.

---

## Implementation approaches

### CSS custom properties + prefers-color-scheme

The foundational pattern. Define semantic tokens on `:root`, override them in a media query or class.

```css
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f4f4f5;
  --bg-tertiary: #e4e4e7;
  --bg-card: #ffffff;
  --bg-elevated: #ffffff;

  --text-primary: #09090b;
  --text-secondary: #71717a;
  --text-tertiary: #a1a1aa;

  --border-default: #e4e4e7;
  --border-strong: #d4d4d8;

  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #09090b;
    --bg-secondary: #18181b;
    --bg-tertiary: #27272a;
    --bg-card: #18181b;
    --bg-elevated: #27272a;

    --text-primary: #fafafa;
    --text-secondary: #a1a1aa;
    --text-tertiary: #71717a;

    --border-default: #27272a;
    --border-strong: #3f3f46;

    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.4);
  }
}
```

### Class-based toggle (.dark)

For manual user control. Apply a class to `<html>` and scope overrides.

```css
:root {
  --bg-primary: #ffffff;
  --text-primary: #09090b;
  /* ... all light tokens */
}

html.dark {
  --bg-primary: #09090b;
  --text-primary: #fafafa;
  /* ... all dark tokens */
}
```

```js
// Toggle
document.documentElement.classList.toggle('dark');
```

### Tailwind dark: variant

Tailwind uses the `dark:` prefix with either `media` (system preference) or `class` (manual toggle) strategy.

```js
// tailwind.config.js
module.exports = {
  darkMode: 'class', // or 'media' for system-only
};
```

```html
<div class="bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-50">
  <p class="text-zinc-600 dark:text-zinc-400">Secondary text</p>
  <div class="border border-zinc-200 dark:border-zinc-800 rounded-lg p-4">
    Card content
  </div>
</div>
```

**When using Tailwind with a design token layer,** map your tokens to Tailwind's config so you use semantic names, not raw `dark:bg-zinc-950` everywhere:

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        background: 'var(--bg-primary)',
        foreground: 'var(--text-primary)',
        card: 'var(--bg-card)',
        'card-foreground': 'var(--text-primary)',
        muted: 'var(--bg-secondary)',
        'muted-foreground': 'var(--text-secondary)',
        border: 'var(--border-default)',
      },
    },
  },
};
```

Then use `bg-background text-foreground` — no `dark:` prefix needed because the variable itself swaps.

### next-themes / ThemeProvider pattern

The standard for Next.js applications. Handles system detection, manual toggle, persistence, and flash prevention.

```tsx
// app/layout.tsx
import { ThemeProvider } from 'next-themes';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

```tsx
// components/theme-toggle.tsx
'use client';
import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';

export function ThemeToggle() {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);
  if (!mounted) return null; // Avoid hydration mismatch

  return (
    <button onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}>
      {resolvedTheme === 'dark' ? 'Light' : 'Dark'}
    </button>
  );
}
```

**Key concepts:**
- `theme` returns "system", "light", or "dark" (the user's selection).
- `resolvedTheme` returns "light" or "dark" (the actual applied theme). Use this for conditional rendering.
- The provider injects a blocking `<script>` in `<head>` that reads localStorage before paint — no flash.
- `suppressHydrationWarning` on `<html>` is required because the server doesn't know the theme.

### CSS light-dark() function (2024+)

A native CSS function that selects one of two values based on the computed `color-scheme`. Supported in all modern browsers since May 2024 (~87% support in early 2025, baseline by late 2026).

```css
:root {
  color-scheme: light dark;
}

body {
  background-color: light-dark(#ffffff, #09090b);
  color: light-dark(#09090b, #fafafa);
}

.card {
  background-color: light-dark(#ffffff, #18181b);
  border-color: light-dark(#e4e4e7, #27272a);
}
```

**Requires** `color-scheme: light dark` on `:root` or the element. Without it, `light-dark()` always returns the first (light) value.

**Limitation:** Only works for color values. You still need media queries or class-based approaches for non-color properties (shadows, images, border-width).

**Fallback for older browsers:** Use PostCSS or Lightning CSS to transpile. Or provide a fallback declaration before:
```css
body {
  background-color: #ffffff; /* fallback */
  background-color: light-dark(#ffffff, #09090b);
}
```

---

## Color mapping strategy

### Don't invert — remap

Color inversion (filter: invert) is lazy and produces garbage. Dark mode requires intentional remapping of every semantic role.

### Surface hierarchy

In light mode, elevation is conveyed by shadows (higher = more shadow). In dark mode, shadows barely register against dark backgrounds. Replace shadow-based hierarchy with luminance-based hierarchy.

| Surface level | Light mode | Dark mode | Use |
|---|---|---|---|
| Page background | `#f4f4f5` (zinc-100) | `#09090b` (zinc-950) | Page canvas |
| Card / panel | `#ffffff` | `#18181b` (zinc-900) | Content containers |
| Elevated (dropdown, modal) | `#ffffff` + shadow | `#27272a` (zinc-800) | Floating surfaces |
| Hover state | `#f4f4f5` (zinc-100) | `#27272a` (zinc-800) | Interactive feedback |
| Active/pressed | `#e4e4e7` (zinc-200) | `#3f3f46` (zinc-700) | Press state |

**Key insight:** In dark mode, lighter surface = higher elevation. Material Design 3 calls this "tonal elevation." Each step up the z-axis gets 2-4% lighter.

### Text hierarchy

| Role | Light mode | Dark mode |
|---|---|---|
| Primary | `#09090b` (zinc-950) | `#fafafa` (zinc-50) |
| Secondary | `#71717a` (zinc-500) | `#a1a1aa` (zinc-400) |
| Tertiary / placeholder | `#a1a1aa` (zinc-400) | `#71717a` (zinc-500) |
| Disabled | `#d4d4d8` (zinc-300) | `#3f3f46` (zinc-700) |

**Don't use pure white (#ffffff) for text in dark mode.** It's too bright and causes eye strain. Use `#fafafa` or `#e4e4e7` for primary text.

**Don't use pure black (#000000) for dark mode backgrounds.** It creates excessive contrast and looks unnatural on OLED screens (the "black hole" effect). Use `#09090b` to `#171717`.

### Border handling

Borders become more important in dark mode because shadows are less visible.

```css
:root {
  --border-default: #e4e4e7;    /* Visible on white */
  --border-opacity: 0.1;
}

html.dark {
  --border-default: #27272a;    /* Visible on dark surfaces */
  --border-opacity: 0.15;       /* Slightly increase for definition */
}
```

**Opacity-based alternative** (works well for components that appear on varied backgrounds):
```css
.card {
  border: 1px solid rgb(128 128 128 / var(--border-opacity));
}
```

### Accent and brand colors

Brand colors often need adjustment between modes:

```css
:root {
  --accent: #2563eb;           /* Blue-600 — works on white */
  --accent-foreground: #ffffff;
}

html.dark {
  --accent: #3b82f6;           /* Blue-500 — lighter for visibility on dark */
  --accent-foreground: #ffffff;
}
```

Mid-range tones (400-500) work better on dark backgrounds than deep tones (700-900), which disappear. Light tones (100-200) that work as backgrounds in light mode become unreadable text on dark backgrounds.

### Status colors

Adjust saturation and lightness for dark mode — the same green/red/yellow that works on white looks different on dark gray.

```css
:root {
  --status-success: #16a34a;   /* Green-600 */
  --status-warning: #d97706;   /* Amber-600 */
  --status-error: #dc2626;     /* Red-600 */
  --status-info: #2563eb;      /* Blue-600 */
}

html.dark {
  --status-success: #22c55e;   /* Green-500 — more vibrant */
  --status-warning: #f59e0b;   /* Amber-500 */
  --status-error: #ef4444;     /* Red-500 */
  --status-info: #3b82f6;      /* Blue-500 */
}
```

---

## Image handling in dark mode

### The problem

Images with white or light backgrounds look harsh and glaring against dark surfaces. Logos on transparent backgrounds may have dark elements that become invisible.

### Strategy 1: Reduce brightness with CSS filter

```css
html.dark img:not([data-no-filter]) {
  filter: brightness(0.9);
}
```

Subtle, universal, minimal effort. 10% brightness reduction softens the transition without noticeably degrading images. Use `data-no-filter` to opt out specific images.

### Strategy 2: Add a subtle backdrop

```css
html.dark .image-container {
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 8px;
}
```

Creates a slightly lighter surface behind images, providing a visual boundary.

### Strategy 3: Provide dark-mode-specific images

```html
<picture>
  <source srcset="/logo-dark.svg" media="(prefers-color-scheme: dark)">
  <img src="/logo-light.svg" alt="Company Logo">
</picture>
```

For React with next-themes:
```tsx
const { resolvedTheme } = useTheme();
<img src={resolvedTheme === 'dark' ? '/logo-dark.svg' : '/logo-light.svg'} alt="Logo" />
```

Best for logos and brand assets. Maintain two versions.

### Strategy 4: SVG with currentColor

```svg
<svg viewBox="0 0 24 24" fill="currentColor">
  <path d="M12 2L2 19h20L12 2z"/>
</svg>
```

The SVG inherits the text color of its parent, automatically adapting to dark mode. Use for icons, simple illustrations, and UI graphics. Set `fill="currentColor"` or `stroke="currentColor"`.

### Strategy 5: Border on transparent PNGs

```css
html.dark .logo-img {
  border: 1px solid var(--border-default);
  border-radius: 6px;
  padding: 4px;
}
```

Simple fallback for logos you can't replace with dark variants.

### Strategy 6: Background-blend for photos

```css
html.dark .photo-card img {
  opacity: 0.85;
}
```

Slightly reduces photo intensity in dark mode. Less jarring than full brightness images against dark cards.

---

## Chart colors in dark mode

### Vibrancy adjustment

Colors that look good on white backgrounds appear washed out or overly saturated on dark backgrounds. The fix is not one-size-fits-all — it depends on the color.

**General rule:** Increase lightness and reduce saturation slightly for dark mode chart colors.

```css
:root {
  --chart-1: hsl(221, 83%, 53%);   /* Blue */
  --chart-2: hsl(160, 84%, 39%);   /* Green */
  --chart-3: hsl(38, 92%, 50%);    /* Amber */
  --chart-4: hsl(0, 72%, 51%);     /* Red */
  --chart-5: hsl(262, 83%, 58%);   /* Purple */
}

html.dark {
  --chart-1: hsl(217, 91%, 60%);   /* Lighter, more vibrant blue */
  --chart-2: hsl(160, 84%, 45%);   /* Lighter green */
  --chart-3: hsl(38, 92%, 56%);    /* Lighter amber */
  --chart-4: hsl(0, 84%, 60%);     /* Lighter, more vibrant red */
  --chart-5: hsl(262, 83%, 68%);   /* Lighter purple */
}
```

### Grid lines and axes

```css
:root {
  --chart-grid: #e4e4e7;           /* Subtle on white */
  --chart-axis: #71717a;
  --chart-axis-label: #71717a;
}

html.dark {
  --chart-grid: #27272a;           /* Subtle on dark */
  --chart-axis: #52525b;
  --chart-axis-label: #a1a1aa;
}
```

**Grid lines** should be barely visible — structural guides, not visual elements. On dark backgrounds, use very low contrast (1-2 steps lighter than the background).

### Tooltip styling

```css
:root {
  --chart-tooltip-bg: #ffffff;
  --chart-tooltip-border: #e4e4e7;
  --chart-tooltip-text: #09090b;
  --chart-tooltip-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

html.dark {
  --chart-tooltip-bg: #27272a;
  --chart-tooltip-border: #3f3f46;
  --chart-tooltip-text: #fafafa;
  --chart-tooltip-shadow: 0 4px 6px rgba(0, 0, 0, 0.4);
}
```

### Palette size

Limit to 4-5 colors per chart in dark mode. More colors compete for attention on dark backgrounds where everything appears more vibrant. Use opacity variations of a single hue for secondary data series.

### Specific chart types

**Line charts:** Increase stroke width from 2px to 2.5px on dark backgrounds. The thinner lines are harder to see.

**Bar charts:** Reduce opacity to 85-90% on dark backgrounds to prevent color blocks from feeling overwhelming.

**Area charts:** Use 10-15% fill opacity (not 20-30% as in light mode). Filled areas glow on dark backgrounds.

**Pie/donut charts:** Add a 1px gap (stroke on the segments matching the background color) to separate slices visually.

---

## User preference persistence

### Detection and storage layers

```
System preference (OS-level) → prefers-color-scheme
Manual override (user toggle) → localStorage or server-side
```

### Implementation pattern

```ts
type Theme = 'light' | 'dark' | 'system';

function getResolvedTheme(stored: Theme): 'light' | 'dark' {
  if (stored === 'system') {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  return stored;
}

// Read: localStorage first, fallback to system
const stored = (localStorage.getItem('theme') as Theme) || 'system';
const resolved = getResolvedTheme(stored);
document.documentElement.classList.toggle('dark', resolved === 'dark');

// Listen for system changes (when user selected "system")
window.matchMedia('(prefers-color-scheme: dark)')
  .addEventListener('change', (e) => {
    const current = localStorage.getItem('theme') || 'system';
    if (current === 'system') {
      document.documentElement.classList.toggle('dark', e.matches);
    }
  });
```

### Per-device vs per-account

| Approach | Storage | Pros | Cons |
|---|---|---|---|
| **Per-device (localStorage)** | Browser | Instant, no API call, works offline | Doesn't sync across devices |
| **Per-account (server-side)** | User settings in DB | Syncs everywhere, survives device changes | Requires API call on load, flash risk |
| **Hybrid (recommended)** | localStorage + DB | Fast load from local, sync from server | Slight complexity |

### Hybrid approach (recommended for SaaS)

```ts
// On page load (blocking script in <head>)
const localTheme = localStorage.getItem('theme') || 'system';
applyTheme(localTheme);

// After auth/hydration (non-blocking)
async function syncTheme() {
  const serverTheme = await fetchUserPreference('theme');
  if (serverTheme && serverTheme !== localStorage.getItem('theme')) {
    localStorage.setItem('theme', serverTheme);
    applyTheme(serverTheme);
  }
}

// On toggle (write both)
function setTheme(theme: Theme) {
  localStorage.setItem('theme', theme);
  applyTheme(theme);
  updateUserPreference('theme', theme); // fire-and-forget API call
}
```

### When to sync across devices

Sync theme preference across devices when:
- User explicitly chose light or dark (not "system").
- Your product has a settings page where theme is a visible preference.

Don't sync when:
- User is on "system" — each device has its own system preference for a reason.
- The user hasn't explicitly changed the default.

---

## Transition between modes

### Smooth transition

```css
/* Apply to body or html — NOT * (too expensive) */
body {
  transition: background-color 200ms ease, color 200ms ease;
}

.card, .sidebar, .header, .modal {
  transition: background-color 200ms ease, color 200ms ease, border-color 200ms ease;
}
```

**Duration:** 150-300ms. Under 150ms feels jarring; over 300ms feels sluggish. 200ms is the sweet spot.

**Don't transition everything.** Only transition background-color, color, and border-color on major surfaces. Transitioning `*` causes performance issues with complex DOMs and produces weird effects on shadows, outlines, and pseudo-elements.

### Preventing flash of wrong theme (FOWT)

The most common dark mode bug. The server renders light mode HTML, the browser paints it, then JavaScript reads localStorage and switches to dark — producing a visible white flash.

**Solution: Blocking script in `<head>`**

```html
<head>
  <script>
    (function() {
      var theme = localStorage.getItem('theme') || 'system';
      var resolved = theme;
      if (theme === 'system') {
        resolved = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
      }
      document.documentElement.classList.add(resolved);
      document.documentElement.style.colorScheme = resolved;
    })();
  </script>
  <!-- Rest of head -->
</head>
```

This runs before the browser paints, so the correct class is applied from the first frame.

**For Next.js:** Use next-themes (already does this). Or use a custom `Script` with `strategy="beforeInteractive"`.

**For SSR without Next.js:** Inject the script inline in your HTML template's `<head>`. Don't load it as an external file — that defeats the purpose.

### color-scheme CSS property

Tell the browser which scheme the page supports. This affects native UI elements (scrollbars, form controls, selection highlight).

```css
:root {
  color-scheme: light dark;
}

/* Or when manually controlled: */
html.dark {
  color-scheme: dark;
}
html.light, html:not(.dark) {
  color-scheme: light;
}
```

Without this, browsers render form inputs, scrollbars, and the page background in light mode even when your CSS says otherwise.

---

## Common dark mode bugs

### 1. White flash on navigation (SPA)

**Symptom:** Brief white flash when navigating between pages in a SPA or when Next.js renders a new route.

**Cause:** The `<body>` or root element doesn't have a background-color set, so the browser's default white shows during route transitions.

**Fix:**
```css
html, body {
  background-color: var(--bg-primary);
}

html.dark, html.dark body {
  background-color: #09090b;
}
```

Set it on `html` too — some browsers paint `html`'s background during transitions before `body` is ready.

### 2. Form autofill colors

**Symptom:** Chrome autofill applies a light yellow/blue background to filled inputs, breaking dark mode aesthetics.

**Fix:**
```css
input:-webkit-autofill,
input:-webkit-autofill:hover,
input:-webkit-autofill:focus {
  -webkit-box-shadow: 0 0 0 1000px var(--bg-card) inset !important;
  -webkit-text-fill-color: var(--text-primary) !important;
  transition: background-color 5000s ease-in-out 0s;
}
```

The `box-shadow` trick covers the autofill background. The infinite transition delay prevents the autofill style from visually appearing.

### 3. Scrollbar colors

**Symptom:** Light scrollbars on dark pages. Especially jarring on content-heavy dashboards.

**Fix:**
```css
/* Firefox and Chrome */
html.dark {
  scrollbar-color: #3f3f46 #18181b;
}

/* Safari — relies on color-scheme */
html.dark {
  color-scheme: dark;
}

/* Webkit custom scrollbar (Chrome, Edge) */
html.dark ::-webkit-scrollbar {
  width: 8px;
}
html.dark ::-webkit-scrollbar-track {
  background: #18181b;
}
html.dark ::-webkit-scrollbar-thumb {
  background: #3f3f46;
  border-radius: 4px;
}
```

### 4. Text selection highlight

**Symptom:** Default blue selection highlight clashes with dark backgrounds or makes selected text unreadable.

**Fix:**
```css
::selection {
  background-color: var(--accent);
  color: var(--accent-foreground);
}

html.dark ::selection {
  background-color: hsl(217, 91%, 40%);
  color: #ffffff;
}
```

### 5. Placeholder text contrast

**Symptom:** Placeholder text that was adequately visible on white becomes invisible on dark backgrounds.

**Fix:**
```css
::placeholder {
  color: var(--text-tertiary);
  opacity: 1; /* Firefox reduces opacity by default */
}

/* Ensure dark mode value is actually visible */
html.dark ::placeholder {
  color: #71717a; /* zinc-500 — visible on zinc-900 backgrounds */
}
```

### 6. Disabled state visibility

**Symptom:** Disabled elements at 50% opacity that were visible on white become nearly invisible on dark backgrounds.

**Fix:** Don't rely solely on opacity for disabled states in dark mode. Use explicit muted colors:

```css
html.dark button:disabled {
  background-color: #27272a;
  color: #52525b;
  cursor: not-allowed;
}

html.dark input:disabled {
  background-color: #18181b;
  color: #52525b;
  border-color: #27272a;
}
```

### 7. Third-party embeds

**Symptom:** Embedded widgets (Intercom, Stripe Elements, iframes) remain in light mode, creating jarring bright rectangles.

**Fix:** Most third-party tools support a `theme` or `appearance` config:

```ts
// Stripe Elements
const elements = stripe.elements({ appearance: { theme: resolvedTheme === 'dark' ? 'night' : 'stripe' }});

// Intercom
window.intercomSettings = { color_mode: resolvedTheme };
```

For iframes with no theme API, add a subtle border and accept the mismatch, or apply a CSS filter as a last resort:

```css
html.dark iframe.no-dark-support {
  filter: brightness(0.85);
  border: 1px solid var(--border-default);
  border-radius: 8px;
}
```

---

## Dark mode for specific components

### Tables with alternating rows

```css
:root {
  --table-row-alt: #fafafa;
  --table-row-hover: #f4f4f5;
  --table-header-bg: #f4f4f5;
  --table-border: #e4e4e7;
}

html.dark {
  --table-row-alt: #111113;
  --table-row-hover: #1c1c1f;
  --table-header-bg: #18181b;
  --table-border: #27272a;
}

table {
  border-collapse: collapse;
  width: 100%;
}

thead th {
  background-color: var(--table-header-bg);
  color: var(--text-secondary);
  font-weight: 500;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 10px 16px;
  text-align: left;
  border-bottom: 1px solid var(--table-border);
}

tbody tr:nth-child(even) {
  background-color: var(--table-row-alt);
}

tbody tr:hover {
  background-color: var(--table-row-hover);
}

tbody td {
  padding: 12px 16px;
  border-bottom: 1px solid var(--table-border);
  color: var(--text-primary);
}
```

**Dark mode note:** The alternating row color difference should be very subtle — 1-2 lightness steps. `#111113` vs `#09090b` is enough. Too much contrast between rows creates a distracting zebra effect.

### Modals and backdrop

```css
:root {
  --modal-bg: #ffffff;
  --modal-border: #e4e4e7;
  --modal-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  --backdrop: rgba(0, 0, 0, 0.5);
}

html.dark {
  --modal-bg: #18181b;
  --modal-border: #27272a;
  --modal-shadow: 0 20px 60px rgba(0, 0, 0, 0.6);
  --backdrop: rgba(0, 0, 0, 0.7);
}

.modal-overlay {
  background-color: var(--backdrop);
  backdrop-filter: blur(4px);
}

.modal {
  background-color: var(--modal-bg);
  border: 1px solid var(--modal-border);
  border-radius: 12px;
  box-shadow: var(--modal-shadow);
}
```

**Dark mode note:** Increase backdrop opacity from 0.5 to 0.7 — dark backgrounds behind the backdrop need a stronger overlay to create adequate separation. The modal itself should be one surface level above the page (e.g., zinc-900 on zinc-950 background).

### Tooltips

```css
:root {
  --tooltip-bg: #18181b;
  --tooltip-text: #fafafa;
  --tooltip-border: transparent;
}

html.dark {
  --tooltip-bg: #fafafa;
  --tooltip-text: #18181b;
  --tooltip-border: transparent;
}

.tooltip {
  background-color: var(--tooltip-bg);
  color: var(--tooltip-text);
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  line-height: 1.4;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}
```

**Tooltips invert between modes.** Dark tooltip on light background; light tooltip on dark background. This ensures maximum contrast and clear visual separation from the surface behind them.

### Dropdowns and popovers

```css
:root {
  --dropdown-bg: #ffffff;
  --dropdown-border: #e4e4e7;
  --dropdown-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  --dropdown-hover: #f4f4f5;
  --dropdown-separator: #e4e4e7;
}

html.dark {
  --dropdown-bg: #27272a;
  --dropdown-border: #3f3f46;
  --dropdown-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
  --dropdown-hover: #3f3f46;
  --dropdown-separator: #3f3f46;
}

.dropdown {
  background-color: var(--dropdown-bg);
  border: 1px solid var(--dropdown-border);
  border-radius: 8px;
  box-shadow: var(--dropdown-shadow);
  padding: 4px;
}

.dropdown-item {
  padding: 8px 12px;
  border-radius: 4px;
  color: var(--text-primary);
  cursor: pointer;
}

.dropdown-item:hover {
  background-color: var(--dropdown-hover);
}

.dropdown-separator {
  height: 1px;
  background-color: var(--dropdown-separator);
  margin: 4px 0;
}
```

**Dark mode note:** Dropdowns should be one level higher than cards (zinc-800 if card is zinc-900). Border is critical in dark mode — without it, the dropdown blends into the surface behind it.

### Syntax highlighting / code blocks

```css
:root {
  --code-bg: #f4f4f5;
  --code-text: #09090b;
  --code-keyword: #7c3aed;      /* Purple */
  --code-string: #16a34a;       /* Green */
  --code-comment: #a1a1aa;      /* Muted */
  --code-function: #2563eb;     /* Blue */
  --code-number: #d97706;       /* Amber */
  --code-operator: #71717a;
}

html.dark {
  --code-bg: #0a0a0a;
  --code-text: #e4e4e7;
  --code-keyword: #a78bfa;      /* Purple-400 — lighter */
  --code-string: #4ade80;       /* Green-400 */
  --code-comment: #52525b;      /* zinc-600 */
  --code-function: #60a5fa;     /* Blue-400 */
  --code-number: #fbbf24;       /* Amber-400 */
  --code-operator: #a1a1aa;
}

pre, code {
  background-color: var(--code-bg);
  color: var(--code-text);
  font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', Menlo, monospace;
  font-size: 13px;
  line-height: 1.6;
}

pre {
  padding: 16px 20px;
  border-radius: 8px;
  border: 1px solid var(--border-default);
  overflow-x: auto;
}

code {
  padding: 2px 6px;
  border-radius: 4px;
}
```

**Dark mode note:** Shift syntax colors from the 600 range to the 400 range. 600-level colors that contrast well on white look muddy on dark backgrounds. 400-level colors are more vibrant and legible. Keep comments muted in both modes.

For existing highlighting libraries (Prism, Shiki, Highlight.js), swap themes on mode change:
- Light: `github-light`, `one-light`, `vs`
- Dark: `github-dark`, `one-dark-pro`, `tokyo-night`, `dracula`

### Status badges

```css
:root {
  --badge-success-bg: #dcfce7;
  --badge-success-text: #166534;
  --badge-warning-bg: #fef3c7;
  --badge-warning-text: #92400e;
  --badge-error-bg: #fee2e2;
  --badge-error-text: #991b1b;
  --badge-info-bg: #dbeafe;
  --badge-info-text: #1e40af;
  --badge-default-bg: #f4f4f5;
  --badge-default-text: #3f3f46;
}

html.dark {
  --badge-success-bg: rgba(34, 197, 94, 0.15);
  --badge-success-text: #4ade80;
  --badge-warning-bg: rgba(245, 158, 11, 0.15);
  --badge-warning-text: #fbbf24;
  --badge-error-bg: rgba(239, 68, 68, 0.15);
  --badge-error-text: #f87171;
  --badge-info-bg: rgba(59, 130, 246, 0.15);
  --badge-info-text: #60a5fa;
  --badge-default-bg: #27272a;
  --badge-default-text: #a1a1aa;
}
```

**Dark mode note:** In light mode, badges use soft pastel backgrounds (green-100, red-100) with dark text. In dark mode, use the accent color at low opacity (10-15%) for the background with a vibrant text color. This produces a subtle glow effect that's legible without being overwhelming.

### Input fields and forms

```css
:root {
  --input-bg: #ffffff;
  --input-border: #d4d4d8;
  --input-border-focus: #2563eb;
  --input-text: #09090b;
  --input-ring: 0 0 0 3px rgba(37, 99, 235, 0.15);
}

html.dark {
  --input-bg: #09090b;
  --input-border: #3f3f46;
  --input-border-focus: #3b82f6;
  --input-text: #fafafa;
  --input-ring: 0 0 0 3px rgba(59, 130, 246, 0.25);
}

input, select, textarea {
  background-color: var(--input-bg);
  border: 1px solid var(--input-border);
  color: var(--input-text);
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 14px;
  outline: none;
  transition: border-color 150ms ease, box-shadow 150ms ease;
}

input:focus, select:focus, textarea:focus {
  border-color: var(--input-border-focus);
  box-shadow: var(--input-ring);
}
```

**Dark mode note:** Increase the focus ring opacity from 15% to 25% on dark backgrounds — it needs to be more visible against the dark surface. Input background should match or be slightly darker than the card it sits on.

---

## Testing dark mode

### Automated

- Toggle your app to dark mode programmatically in tests.
- Screenshot comparison tests (Playwright, Cypress) with dark mode variant.
- Check color contrast ratios with axe-core in both modes.

### Manual checklist

- [ ] No white flash on initial load (check with localStorage cleared)
- [ ] No white flash on navigation between routes
- [ ] Theme toggle works and persists across page reloads
- [ ] System preference changes are reflected when set to "system"
- [ ] All text meets 4.5:1 contrast in both modes
- [ ] Images and logos are visible and not jarring
- [ ] Charts are legible with adjusted colors
- [ ] Form inputs, autofill, and focus states look correct
- [ ] Modals, dropdowns, and tooltips have proper contrast
- [ ] Scrollbars match the theme
- [ ] Status badges are distinguishable
- [ ] Code blocks use appropriate syntax theme
- [ ] Third-party embeds don't create bright rectangles
- [ ] Disabled states are visible (not invisible)
- [ ] Placeholder text is readable

### Browser testing

- **Chrome DevTools:** Rendering tab > Emulate CSS media feature `prefers-color-scheme`
- **Firefox:** about:config > `ui.systemUsesDarkTheme` set to 1
- **Safari:** Settings > Developer > Force Dark Mode / Force Light Mode

---

## Don'ts

- **Don't invert colors with `filter: invert(1)`.** It produces garbage — inverted images, wrong brand colors, broken semantics.
- **Don't use pure black (#000000) backgrounds.** Use #09090b to #171717. Pure black creates excessive contrast and the "OLED hole" effect.
- **Don't use pure white (#ffffff) text.** Use #fafafa or #e4e4e7. Pure white on dark backgrounds causes eye strain.
- **Don't rely on shadows for hierarchy in dark mode.** Use surface color differences (lighter = higher).
- **Don't forget to set `color-scheme` on `:root`.** Without it, native form controls, scrollbars, and selection highlights stay in light mode.
- **Don't transition with `* { transition: all }`.** Transition only major surfaces (body, cards, headers). Wildcard transitions cause performance issues and visual artifacts.
- **Don't assume dark mode colors are just "lighter versions" of light mode colors.** Status colors, brand accents, and chart palettes all need individual tuning.
- **Don't skip the blocking `<head>` script.** Without it, every dark-mode user sees a white flash on every page load. This is the most common dark mode bug in production.
- **Don't store theme preference only on the server.** The client needs it before the first paint. Use localStorage as the fast path, server as the sync mechanism.
- **Don't forget about third-party embeds.** They'll remain in their default mode unless you configure them.
