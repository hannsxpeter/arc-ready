# Animation & Motion

Deep reference for animation in dashboards and SaaS applications. The summary table lives in `ui-design-patterns.md` (motion section). This file is the implementation manual — timing values, CSS keyframes, library choices, and code patterns for every animation surface in a dashboard.

The core rule: **animation in a dashboard serves function, not decoration.** Every motion must communicate state change, provide feedback, or orient the user spatially. If it doesn't do one of those three things, cut it.

---

## Transition fundamentals

### Only animate compositor properties

The browser rendering pipeline: Style > Layout > Paint > Composite. Animating `width`, `height`, `top`, `left`, `margin`, or `padding` triggers layout recalculation on every frame. Animating `background-color` or `box-shadow` triggers paint on every frame. Both kill 60fps on complex pages.

**Animate only these properties:**
- `transform` (translate, scale, rotate)
- `opacity`
- `filter` (with care — can be expensive on large elements)

Everything else is off-limits for animation in a data-dense dashboard.

```css
/* WRONG — triggers layout on every frame */
.drawer { transition: width 250ms ease; }

/* RIGHT — compositor only, GPU-accelerated */
.drawer { transition: transform 250ms ease; }
```

### Hardware acceleration

Force GPU compositing when you know an element will animate:

```css
.will-animate {
  will-change: transform, opacity;
}
```

**Rules for `will-change`:**
- Apply it *before* the animation starts (e.g., on hover of a parent, or when a class is added).
- Remove it after the animation completes. Leaving `will-change` on permanently wastes GPU memory.
- Never put `will-change` on more than ~10 elements simultaneously. Each one creates a new compositor layer.
- Never use `will-change: auto` — it does nothing.

```js
// Apply before, remove after
element.style.willChange = 'transform';
element.addEventListener('transitionend', () => {
  element.style.willChange = 'auto';
}, { once: true });
```

The old `transform: translateZ(0)` hack still works but `will-change` is the correct modern approach.

### Duration guidelines

These are hard limits, not suggestions:

| Category | Duration | Examples |
|---|---|---|
| **Micro-interaction** | 100-200ms | Button press, toggle, hover state, focus ring |
| **Standard transition** | 150-250ms | Dropdown open/close, tooltip appear, accordion expand |
| **Panel transition** | 200-300ms | Drawer slide, modal enter, sidebar collapse |
| **Page/route transition** | 300-500ms | View transition, skeleton-to-content, shared element morph |

**Hard ceiling: 500ms.** Never exceed this in a dashboard. Users visit the same pages hundreds of times. An animation that feels "smooth" on first visit becomes an obstacle by the tenth.

Exception: data visualization draw-in on first page load can go to 600-800ms because it only runs once.

### Easing functions

Easing determines how an animation accelerates and decelerates. Wrong easing makes correct durations feel sluggish or jarring.

```css
:root {
  /* Enters — fast start, gentle landing */
  --ease-out: cubic-bezier(0, 0, 0.2, 1);

  /* Exits — gentle start, fast departure */
  --ease-in: cubic-bezier(0.4, 0, 1, 1);

  /* Symmetric — for looping or bidirectional */
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);

  /* Overshoot — for modals, popovers (slight bounce at end) */
  --ease-spring: cubic-bezier(0.16, 1, 0.3, 1);

  /* Snappy — for drawers, panels */
  --ease-snappy: cubic-bezier(0.32, 0.72, 0, 1);
}
```

**The rule:** ease-out for things entering. Ease-in for things exiting. Ease-in-out only for symmetric motions (sidebar toggle, accordion). Linear only for infinite loops (shimmer, progress bars, spinners).

---

## Page and route transitions

### View Transitions API (2025-2026 status)

Same-document view transitions are Baseline Newly Available as of late 2025: Chrome 111+, Edge 111+, Firefox 133+, Safari 18+. Cross-document (MPA) transitions work in Chrome 126+, Edge 126+, Safari 18.2+. Firefox cross-document support is still landing.

**Same-document transition (SPA):**

```js
// Wrap your DOM update in startViewTransition
document.startViewTransition(() => {
  // Update the DOM — swap route content, update state, etc.
  updateRoute(newPath);
});
```

```css
/* Default crossfade — works out of the box */
::view-transition-old(root) {
  animation: fade-out 200ms ease-in forwards;
}
::view-transition-new(root) {
  animation: fade-in 200ms ease-out forwards;
}

@keyframes fade-out {
  to { opacity: 0; }
}
@keyframes fade-in {
  from { opacity: 0; }
}
```

**Shared element transitions (morph between list item and detail page):**

```css
/* On the list page — tag the card */
.project-card {
  view-transition-name: project-hero;
}

/* On the detail page — tag the hero */
.project-detail-header {
  view-transition-name: project-hero;
}

/* The browser automatically morphs between them */
::view-transition-group(project-hero) {
  animation-duration: 300ms;
  animation-timing-function: cubic-bezier(0.32, 0.72, 0, 1);
}
```

**When to use in dashboards:**
- Route changes (settings > billing, overview > detail) — crossfade, 200-300ms.
- List-to-detail navigation — shared element morph on the card/row that was clicked.
- Tab switching within a page — slide left/right based on tab direction.

**When NOT to use:**
- Real-time data updates (live metrics, WebSocket pushes) — swap instantly.
- Pagination — just replace content.
- Filter/sort results — re-render without transition.

### Skeleton-to-content transitions

When a skeleton placeholder resolves to real content, don't just hard-swap. Crossfade:

```css
.skeleton-container {
  position: relative;
}

.skeleton-placeholder {
  transition: opacity 150ms ease-out;
}

.skeleton-placeholder[data-loaded="true"] {
  opacity: 0;
  pointer-events: none;
}

.real-content {
  opacity: 0;
  transition: opacity 150ms ease-out 50ms; /* 50ms delay after skeleton starts fading */
}

.real-content[data-loaded="true"] {
  opacity: 1;
}
```

The 50ms overlap creates a smooth crossfade rather than a flash of empty space between skeleton and content.

---

## Micro-interactions

Micro-interactions are the fastest animations in the system — 100-200ms, always triggered by direct user action. They provide immediate tactile feedback.

### Button press

```css
.btn {
  transition: transform 100ms var(--ease-out),
              background-color 100ms var(--ease-out);
}

.btn:hover {
  background-color: var(--btn-hover);
}

.btn:active {
  transform: scale(0.97);
}
```

Scale 0.97-0.98 on press. Not 0.95 (too dramatic) or 0.99 (imperceptible). Return is handled by the transition — no explicit "release" animation needed.

### Toggle / switch

```css
.switch-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  transition: transform 150ms var(--ease-spring);
}

.switch[data-state="checked"] .switch-thumb {
  transform: translateX(20px);
}
```

Use `transform: translateX()` — never animate `left` or `margin-left`. The slight overshoot from `--ease-spring` makes the toggle feel physical.

### Checkbox

```css
.checkbox-indicator {
  transform: scale(0);
  transition: transform 150ms var(--ease-spring);
}

.checkbox[data-state="checked"] .checkbox-indicator {
  transform: scale(1);
}

/* The checkmark draws in with a stroke animation */
.checkmark-path {
  stroke-dasharray: 16;
  stroke-dashoffset: 16;
  transition: stroke-dashoffset 200ms ease-out 50ms;
}

.checkbox[data-state="checked"] .checkmark-path {
  stroke-dashoffset: 0;
}
```

### Focus ring animation

```css
:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
  transition: outline-offset 100ms ease-out;
}

/* Animate from 0 to 2px offset for a subtle "expand" effect */
@starting-style {
  :focus-visible {
    outline-offset: 0px;
  }
}
```

### Ripple effect (Material-style)

Use sparingly in dashboards. Ripples make sense on primary action buttons. They do not make sense on every clickable element in a data table.

```css
.ripple-container {
  position: relative;
  overflow: hidden;
}

.ripple {
  position: absolute;
  border-radius: 50%;
  background: currentColor;
  opacity: 0.15;
  transform: scale(0);
  animation: ripple-expand 400ms ease-out forwards;
}

@keyframes ripple-expand {
  to {
    transform: scale(2.5);
    opacity: 0;
  }
}
```

```js
function createRipple(event) {
  const btn = event.currentTarget;
  const rect = btn.getBoundingClientRect();
  const ripple = document.createElement('span');
  const size = Math.max(rect.width, rect.height);
  ripple.style.width = ripple.style.height = `${size}px`;
  ripple.style.left = `${event.clientX - rect.left - size / 2}px`;
  ripple.style.top = `${event.clientY - rect.top - size / 2}px`;
  ripple.classList.add('ripple');
  btn.appendChild(ripple);
  ripple.addEventListener('animationend', () => ripple.remove());
}
```

### When micro-interactions help vs. hurt

**Help:** Confirming a user action happened (toggle flipped, item selected). Providing directional context (drawer came from the right, so the content is "to the right"). Smoothing perceived state changes (value updated, not teleported).

**Hurt:** On frequently-clicked elements where 150ms * 50 clicks = noticeable delay. On hover states for table rows (hundreds of rows = hundreds of potential animations). On elements the user interacts with in rapid succession (bulk select checkboxes, rapid pagination).

**Rule of thumb:** If a user might trigger the same interaction more than 10 times in 30 seconds, skip the animation or make it < 80ms.

---

## Loading choreography

### Staggered skeleton reveals

Don't show all skeleton elements at once. Stagger them top-to-bottom to create a "loading down the page" effect:

```css
.skeleton-item {
  opacity: 0;
  animation: skeleton-enter 200ms ease-out forwards;
}

.skeleton-item:nth-child(1) { animation-delay: 0ms; }
.skeleton-item:nth-child(2) { animation-delay: 40ms; }
.skeleton-item:nth-child(3) { animation-delay: 80ms; }
.skeleton-item:nth-child(4) { animation-delay: 120ms; }
.skeleton-item:nth-child(5) { animation-delay: 160ms; }

@keyframes skeleton-enter {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

Stagger interval: 30-50ms per item. More than 50ms and the page feels slow. Fewer than 30ms and the stagger is imperceptible. Cap at 5-8 items — beyond that, stagger the first 5 and show the rest simultaneously.

### Shimmer effect (synchronized)

The shimmer gradient should sweep across all skeleton elements in sync, not independently. Use `background-attachment: fixed` for viewport-relative alignment:

```css
.skeleton-bone {
  background-color: var(--skeleton-base); /* e.g., hsl(0 0% 90%) */
  background-image: linear-gradient(
    90deg,
    transparent 0%,
    var(--skeleton-shimmer) 50%, /* e.g., hsl(0 0% 96%) */
    transparent 100%
  );
  background-size: 200% 100%;
  background-attachment: fixed;
  animation: shimmer 1.5s linear infinite;
  border-radius: 4px;
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

For dark mode, use `hsl(0 0% 15%)` as base and `hsl(0 0% 20%)` as shimmer highlight.

### Spinner vs. skeleton decision tree

```
Is this the first load of this content?
  YES → Skeleton (matches final layout shape)
  NO → Is existing data visible?
    YES → Inline indicator (spinning icon, thin progress bar)
    NO → Skeleton again (content was removed from DOM)

Is the wait expected to be < 200ms?
  YES → Show nothing. Delay skeleton render by 200ms.
  NO → Show skeleton immediately.

Is the loading area < 48px in any dimension?
  YES → Use spinner (skeleton won't read at that size)
  NO → Use skeleton
```

### Top-of-page progress bar (NProgress-style)

For route transitions and background fetches — a thin bar at the very top of the viewport:

```css
.nprogress-bar {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: var(--primary);
  z-index: 9999;
  transition: width 200ms ease;
}

/* Animate from 0% to ~80% quickly, then slow down */
.nprogress-bar[data-state="loading"] {
  animation: nprogress-grow 8s cubic-bezier(0.1, 0.5, 0.1, 1) forwards;
}

.nprogress-bar[data-state="done"] {
  width: 100%;
  transition: width 150ms ease-out;
  opacity: 0;
  transition: opacity 300ms ease 200ms;
}

@keyframes nprogress-grow {
  0% { width: 0%; }
  10% { width: 30%; }
  50% { width: 70%; }
  100% { width: 85%; }
}
```

Never let the bar reach 100% while still loading. Jump to 100% only on completion, then fade out.

---

## List and table animations

### Adding a row

```css
.table-row-enter {
  animation: row-enter 200ms ease-out forwards;
}

@keyframes row-enter {
  from {
    opacity: 0;
    max-height: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    max-height: 60px; /* match your row height */
    transform: translateY(0);
  }
}
```

### Removing a row

```css
.table-row-exit {
  animation: row-exit 150ms ease-in forwards;
}

@keyframes row-exit {
  to {
    opacity: 0;
    max-height: 0;
    padding-top: 0;
    padding-bottom: 0;
    transform: translateX(-16px);
  }
}
```

Slide exits left (translateX negative) to suggest "removed." Slide enters down (translateY from above) to suggest "inserted." This matches reading direction and spatial metaphor.

### Reordering with the FLIP technique

FLIP: **F**irst, **L**ast, **I**nvert, **P**lay. The only reliable way to animate layout changes (reorders, grid shifts, filtering) at 60fps.

```js
function animateReorder(container) {
  const items = [...container.children];

  // FIRST — record current positions
  const firstRects = new Map();
  items.forEach(item => {
    firstRects.set(item, item.getBoundingClientRect());
  });

  // (DOM change happens here — sort, filter, reorder)
  reorderDOM(container);

  // LAST — record new positions
  items.forEach(item => {
    const first = firstRects.get(item);
    const last = item.getBoundingClientRect();

    // INVERT — apply transform to put element back at old position
    const dx = first.left - last.left;
    const dy = first.top - last.top;

    item.style.transform = `translate(${dx}px, ${dy}px)`;
    item.style.transition = 'none';

    // PLAY — remove transform and let transition animate it
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        item.style.transition = 'transform 250ms cubic-bezier(0.32, 0.72, 0, 1)';
        item.style.transform = '';
      });
    });
  });
}
```

The double `requestAnimationFrame` is intentional — it ensures the browser has painted the inverted state before starting the transition.

### Filtering (exit then enter)

When a filter changes the visible set of items:

1. **Exit**: items that no longer match fade out (opacity 0, 150ms ease-in).
2. **Layout**: remaining items move to fill gaps (FLIP, 200ms).
3. **Enter**: new items that now match fade in (opacity 0 to 1, 150ms ease-out, 50ms delay after layout).

Orchestrate with CSS classes and short delays. Do not try to run all three simultaneously — the visual result is chaos.

### Drag-and-drop visual feedback

```css
/* Element being dragged */
.dragging {
  opacity: 0.6;
  transform: scale(1.02) rotate(1deg);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  transition: transform 150ms ease-out, box-shadow 150ms ease-out;
  z-index: 100;
}

/* Drop target highlight */
.drop-target {
  outline: 2px dashed var(--primary);
  outline-offset: 2px;
  background: var(--primary-ghost); /* very faint primary bg */
  transition: background 100ms ease;
}

/* Placeholder gap where item will land */
.drag-placeholder {
  background: var(--muted);
  border-radius: var(--radius);
  animation: placeholder-pulse 1s ease-in-out infinite;
}

@keyframes placeholder-pulse {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.5; }
}
```

---

## Modal, drawer, popover, toast animations

### Modal

```css
/* Backdrop */
.modal-backdrop {
  background: rgba(0, 0, 0, 0.5);
  opacity: 0;
  transition: opacity 200ms ease-out;
}
.modal-backdrop[data-state="open"] {
  opacity: 1;
}

/* Content */
.modal-content {
  transform: scale(0.95) translateY(8px);
  opacity: 0;
  transition: transform 200ms cubic-bezier(0.16, 1, 0.3, 1),
              opacity 200ms ease-out;
}
.modal-content[data-state="open"] {
  transform: scale(1) translateY(0);
  opacity: 1;
}

/* Exit — faster, ease-in */
.modal-content[data-state="closed"] {
  transform: scale(0.97);
  opacity: 0;
  transition: transform 150ms ease-in,
              opacity 150ms ease-in;
}
```

### Drawer (slide from right)

```css
.drawer {
  position: fixed;
  top: 0;
  right: 0;
  height: 100vh;
  width: 400px;
  transform: translateX(100%);
  transition: transform 250ms cubic-bezier(0.32, 0.72, 0, 1);
}

.drawer[data-state="open"] {
  transform: translateX(0);
}

.drawer[data-state="closed"] {
  transform: translateX(100%);
  transition-duration: 200ms;
  transition-timing-function: ease-in;
}
```

Left drawers use `translateX(-100%)`. Bottom sheets use `translateY(100%)`.

### Popover with `@starting-style`

Modern CSS approach — no JavaScript animation library needed:

```css
.popover {
  opacity: 0;
  transform: scale(0.96) translateY(-4px);
  transition: opacity 150ms ease-out,
              transform 150ms ease-out,
              display 150ms allow-discrete;
}

.popover:popover-open {
  opacity: 1;
  transform: scale(1) translateY(0);
}

@starting-style {
  .popover:popover-open {
    opacity: 0;
    transform: scale(0.96) translateY(-4px);
  }
}
```

`@starting-style` tells the browser where to animate *from* when the element first appears. Combined with `transition-behavior: allow-discrete` (included via the `display` transition), this handles both entry and exit with pure CSS. Baseline available across Chrome 117+, Safari 17.5+, Firefox 129+.

### Toast enter / exit / stack

```css
.toast-container {
  position: fixed;
  bottom: 16px;
  right: 16px;
  display: flex;
  flex-direction: column-reverse;
  gap: 8px;
  z-index: 9999;
}

.toast {
  transform: translateX(calc(100% + 16px));
  opacity: 0;
  transition: transform 200ms var(--ease-spring),
              opacity 200ms ease-out;
}

.toast[data-state="visible"] {
  transform: translateX(0);
  opacity: 1;
}

.toast[data-state="exiting"] {
  transform: translateX(calc(100% + 16px));
  opacity: 0;
  transition-duration: 150ms;
  transition-timing-function: ease-in;
}

/* Stack effect: older toasts scale down slightly */
.toast-container .toast:nth-last-child(2) { transform: scale(0.95); opacity: 0.8; }
.toast-container .toast:nth-last-child(3) { transform: scale(0.90); opacity: 0.6; }
```

Toasts enter from the right (translateX). They exit to the right. New toasts push the stack up. Limit visible stack to 3; beyond that, collapse older toasts into a "+N more" indicator.

### Dropdown menu

```css
.dropdown-menu {
  transform-origin: top center;
  transform: scaleY(0.96) translateY(-4px);
  opacity: 0;
  transition: transform 150ms var(--ease-out),
              opacity 100ms ease-out;
}

.dropdown-menu[data-state="open"] {
  transform: scaleY(1) translateY(0);
  opacity: 1;
}

.dropdown-menu[data-state="closed"] {
  transform: scaleY(0.96) translateY(-4px);
  opacity: 0;
  transition-duration: 100ms;
  transition-timing-function: ease-in;
}
```

Set `transform-origin` based on which side of the trigger the menu opens. Top-left for left-aligned menus below a trigger. Bottom-left for menus that open upward.

---

## Chart and data visualization animation

### Number counting / rolling

For KPI cards, stat counters, dashboard headline numbers:

```js
function animateValue(element, start, end, duration = 500) {
  const startTime = performance.now();
  const range = end - start;

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);

    // Ease-out curve
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = start + range * eased;

    element.textContent = formatNumber(current);

    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }

  requestAnimationFrame(update);
}
```

**Duration:** 400-600ms for the initial load count-up. 200-300ms for subsequent value updates (the user is watching and waiting).

### CSS-only counter animation

For simpler cases using CSS `@property` (Chrome 85+, Safari 16.4+, Firefox 128+):

```css
@property --num {
  syntax: '<integer>';
  initial-value: 0;
  inherits: false;
}

.counter {
  counter-reset: num var(--num);
  transition: --num 500ms ease-out;
}

.counter::after {
  content: counter(num);
}

.counter[data-value="1284"] {
  --num: 1284;
}
```

### Chart draw-in on first load

For bar charts — grow bars from zero height:

```css
.bar {
  transform-origin: bottom;
  transform: scaleY(0);
  animation: bar-grow 500ms ease-out forwards;
}

.bar:nth-child(1) { animation-delay: 0ms; }
.bar:nth-child(2) { animation-delay: 50ms; }
.bar:nth-child(3) { animation-delay: 100ms; }
/* ... stagger 50ms per bar, cap at 400ms total delay */

@keyframes bar-grow {
  to { transform: scaleY(1); }
}
```

For line charts — draw the path with stroke-dasharray:

```css
.chart-line {
  stroke-dasharray: var(--path-length);
  stroke-dashoffset: var(--path-length);
  animation: line-draw 800ms ease-out forwards;
}

@keyframes line-draw {
  to { stroke-dashoffset: 0; }
}
```

Calculate `--path-length` via `path.getTotalLength()` in JS and set it as a CSS custom property.

### Data update transitions

When a chart's data changes (new time period selected, real-time update):

```css
.bar {
  transition: height 300ms ease-out, y 300ms ease-out;
}

.chart-line {
  transition: d 300ms ease-out; /* SVG path morphing — requires a library or SMIL */
}

.pie-slice {
  transition: d 400ms ease-out;
}
```

For React with a charting library, use the library's built-in transition config. Recharts uses `<Bar animationDuration={300} />`. Chart.js uses `options.animation.duration`. D3 uses `.transition().duration(300)`.

### KPI value change flash

When a KPI value updates, briefly flash the background to draw attention:

```css
.kpi-value {
  transition: color 200ms ease;
}

.kpi-value[data-trend="up"] {
  animation: flash-green 600ms ease-out;
}
.kpi-value[data-trend="down"] {
  animation: flash-red 600ms ease-out;
}

@keyframes flash-green {
  0% { background-color: hsl(142 70% 90%); }
  100% { background-color: transparent; }
}

@keyframes flash-red {
  0% { background-color: hsl(0 70% 93%); }
  100% { background-color: transparent; }
}
```

Flash once. Do not repeat or pulse. For dashboards with many KPIs updating simultaneously, skip the flash entirely — it becomes visual noise.

---

## Spring physics and gesture-based motion

### Why springs beat durations

Duration-based animations have a fixed end time. They cannot incorporate the velocity of a user's gesture, so a fast flick and a slow drag both resolve in the same number of milliseconds. Springs solve this — they model physical motion with mass, stiffness, and damping, and naturally incorporate input velocity.

### Spring parameters

| Parameter | What it does | Dashboard defaults |
|---|---|---|
| **stiffness** | How tight the spring is. Higher = snappier. | 200-400 for UI, 100-150 for gentle |
| **damping** | Friction/resistance. Higher = less bounce. | 20-30 for UI (critically damped to slightly underdamped) |
| **mass** | Weight of the moving object. Higher = more sluggish. | 1 (almost never change this) |

**Dashboard sweet spot:** `stiffness: 300, damping: 25, mass: 1`. Snappy, minimal overshoot, resolves in ~200ms.

For toggles and interactive elements that should feel physical: `stiffness: 500, damping: 30`. Tight and responsive.

For page transitions and large panels: `stiffness: 150, damping: 20`. Gentle and smooth.

### Spring implementation with Motion (React)

```jsx
import { motion } from 'motion/react';

function Drawer({ isOpen }) {
  return (
    <motion.div
      animate={{ x: isOpen ? 0 : '100%' }}
      transition={{
        type: 'spring',
        stiffness: 300,
        damping: 30,
      }}
    />
  );
}
```

### Spring with the `linear()` CSS function

CSS now supports custom easing curves via `linear()`. You can approximate a spring:

```css
/* Pre-computed spring curve (stiffness: 300, damping: 22) */
.spring-ease {
  transition-timing-function: linear(
    0, 0.013, 0.049, 0.104, 0.178, 0.264,
    0.36, 0.462, 0.567, 0.671, 0.77,
    0.861, 0.939, 1.001, 1.047, 1.076,
    1.089, 1.088, 1.075, 1.054, 1.027,
    0.998, 0.971, 0.949, 0.933, 0.924,
    0.921, 0.924, 0.932, 0.944, 0.958,
    0.974, 0.989, 1.001, 1.011, 1.017,
    1.019, 1.018, 1.014, 1.008, 1.002,
    0.997, 0.993, 0.991, 0.991, 0.992,
    0.994, 0.997, 0.999, 1
  );
}
```

Use a generator like `spring-easing` (npm) to compute these values from physics parameters.

### Gesture-driven animation

For drag-to-dismiss, swipe actions, pull-to-refresh:

```jsx
// Motion for React — drag gesture
<motion.div
  drag="x"
  dragConstraints={{ left: 0, right: 0 }}
  onDragEnd={(event, info) => {
    if (info.offset.x > 100) {
      dismiss();
    }
  }}
  transition={{
    type: 'spring',
    stiffness: 300,
    damping: 25,
  }}
/>
```

In dashboards, gesture animations are most useful for:
- Swiping to dismiss notifications/toasts on mobile.
- Dragging to reorder sidebar items or columns.
- Pull-to-refresh on mobile dashboard views.

They are NOT useful for:
- Data tables (use keyboard and click interactions).
- Charts (use hover tooltips and click, not drag).
- Forms (standard input behavior).

---

## Animation libraries — when to use each

### CSS-only (transitions + keyframes + `@starting-style`)

**Use for:** Simple enter/exit animations, hover states, focus rings, shimmer effects, dropdown/modal open/close. Anything that maps to a boolean state change (hidden/visible, open/closed, hover/normal).

**Strengths:** Zero JS, no bundle cost, hardware-accelerated by default (for transform/opacity), works with server-rendered HTML.

**Limits:** No spring physics, no gesture support, no orchestration (stagger requires manual `animation-delay`), no FLIP, no value interpolation.

### Motion (formerly Framer Motion) — React

**Use for:** React SPAs and dashboards. Spring-based transitions, layout animations (automatic FLIP), gesture handling, AnimatePresence for exit animations, shared layout animations.

**Bundle:** ~32KB gzipped for core. Tree-shakeable.

**Dashboard fit:** The best default for React dashboards. Spring defaults feel natural. `layout` prop handles list reordering automatically. `AnimatePresence` solves exit animations (a hard problem in React).

```jsx
import { AnimatePresence, motion } from 'motion/react';

function NotificationList({ items }) {
  return (
    <AnimatePresence>
      {items.map(item => (
        <motion.div
          key={item.id}
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          transition={{ type: 'spring', stiffness: 300, damping: 25 }}
        />
      ))}
    </AnimatePresence>
  );
}
```

### GSAP

**Use for:** Complex timeline-based sequences (onboarding tours, multi-step animation choreography), SVG morphing, scroll-driven animations, high-element-count animations (hundreds of simultaneous tweens).

**Bundle:** ~23KB gzipped core. Plugins add more.

**Dashboard fit:** Overkill for standard UI transitions. Reach for it when you need timeline orchestration (e.g., an animated onboarding sequence) or when you're animating data visualizations with complex sequencing.

### View Transitions API

**Use for:** Route transitions in SPAs and MPAs, shared element morphs between pages. Works with any framework or vanilla JS.

**Bundle:** Zero — it's a browser API.

**Dashboard fit:** Use for page/route transitions as a progressive enhancement. Always provide a fallback (instant swap) for browsers that don't support it. Do not build critical UX on it until Firefox cross-document support ships.

### When to use which

| Scenario | Recommendation |
|---|---|
| Hover states, focus rings, shimmer | CSS only |
| Dropdown, modal, tooltip open/close | CSS (`@starting-style`) or library |
| List item add/remove with exit animation | Motion (React) or FLIP + CSS |
| Route transition | View Transitions API + CSS fallback |
| Drag-to-reorder | Motion (React) or SortableJS + FLIP |
| Chart draw-in | CSS keyframes or D3 transitions |
| Complex onboarding sequence | GSAP timeline |
| Number counter | JS `requestAnimationFrame` or CSS `@property` |
| Spring-based interactive element | Motion (React) or spring-easing + CSS `linear()` |

---

## Accessibility and motion

### `prefers-reduced-motion` — do it right

The nuclear approach (set all durations to 0) is common but wrong. It removes *all* motion, including essential state indicators. The correct approach: **reduce to essential, don't eliminate.**

```css
/* Step 1: Reduce, don't eliminate */
@media (prefers-reduced-motion: reduce) {
  /* Remove transforms, slides, bounces, springs */
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }

  /* Step 2: Restore essential opacity transitions */
  .toast,
  .modal-content,
  .modal-backdrop,
  .dropdown-menu,
  .tooltip {
    transition: opacity 150ms ease !important;
    animation: none !important;
  }

  /* Step 3: Keep functional animations */
  .spinner {
    animation: spin 1s linear infinite !important;
  }

  .progress-bar {
    transition: width 200ms ease !important;
  }
}
```

### What to keep vs. remove with reduced motion

| Keep (essential) | Remove (decorative/spatial) |
|---|---|
| Opacity fades (show/hide) | translateX/Y slides |
| Spinner rotation | Scale animations |
| Progress bar movement | Spring/bounce overshoot |
| Color change feedback | Parallax effects |
| Focus ring appearance | Staggered entry sequences |
| Loading bar progress | Chart draw-in animations |

### JavaScript detection

```js
const prefersReducedMotion = window.matchMedia(
  '(prefers-reduced-motion: reduce)'
).matches;

// For animation libraries
const transition = prefersReducedMotion
  ? { duration: 0 }
  : { type: 'spring', stiffness: 300, damping: 25 };
```

### In-app motion toggle

Do not rely solely on the OS-level setting. Provide an in-app toggle in settings/preferences. Some users want reduced motion in your app but not system-wide.

```js
// Check both OS preference and in-app setting
function shouldReduceMotion() {
  const osPrefers = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const appSetting = getUserPreference('reducedMotion');
  return osPrefers || appSetting;
}
```

### Seizure safety

WCAG 2.3.1: nothing flashes more than 3 times per second. This is a hard accessibility requirement, not a preference.

- No flashing text, borders, or backgrounds at > 3Hz.
- No strobing skeleton shimmer (the standard 1.5s cycle is fine).
- If using a number counter, don't flash the background on every digit change.
- Autoplay videos or animated backgrounds are banned in dashboard contexts.

### Vestibular disorder triggers

Large-scale motion is the primary trigger — not small micro-interactions. Specifically:
- Full-page slides or zooms (zoom transitions between views).
- Parallax scrolling with large displacement.
- Elements that move when the user is not interacting (auto-rotating carousels, auto-scrolling banners).
- Rapid panning or scaling of large elements.

Small, user-initiated transitions (button press, dropdown open, modal appear) are generally safe.

---

## Animation anti-patterns in dashboards

### Things to never do

**Animations that block interaction.** If the user can't click the next thing until the animation finishes, you've turned motion into a gate. Modals should be interactive the moment they appear, not after a 300ms entrance animation completes. Ensure `pointer-events` are active immediately.

**Autoplay animations on data-heavy pages.** Dashboard overview pages with 10+ widgets should not have animated chart draw-ins on every page load. Animate on first visit; instant-render on subsequent visits.

```js
// Track whether the user has seen this view
const hasSeenDashboard = sessionStorage.getItem('dashboard-seen');
const animationDuration = hasSeenDashboard ? 0 : 500;
sessionStorage.setItem('dashboard-seen', 'true');
```

**Inconsistent timing.** If dropdown A opens in 150ms with ease-out and dropdown B opens in 300ms with ease-in-out, the dashboard feels broken even though both "work." Pick one timing/easing for each category and apply it everywhere.

**Decorative animation on frequently-visited pages.** A settings page that a user visits 5 times a day does not need a page transition. A data table that refreshes every 30 seconds does not need a loading animation. Reserve animation for infrequent, meaningful state changes.

**Animating layout properties.** Never animate `width`, `height`, `top`, `left`, `margin`, or `padding`. This triggers layout recalculation on every frame, which jankifies any page with more than a handful of elements.

**Over-animating real-time data.** WebSocket-driven dashboards that animate every value update create a sea of motion. If data updates more than once every 5 seconds, swap values instantly.

**Spring bounce on everything.** Spring easing with visible overshoot is appropriate for interactive elements (toggles, drag-drop). It is not appropriate for modals, menus, or toasts. Use slight overshoot (damping 25-30) for interactive elements only.

**Long stagger sequences.** Staggering 20 list items at 50ms each means the last item appears after 1000ms. Cap stagger at 5-8 items and show the rest simultaneously. Total stagger duration should never exceed 300ms.

### The litmus test

Before adding any animation, ask: **"Would this dashboard feel broken without this animation?"**

- If yes (toggle has no visual response, modal appears with no transition, element disappears with no feedback) — add the animation.
- If no (chart bars could just appear at full height, page content could just swap, list could just re-render) — skip it or make it so subtle and fast that it's subliminal.

The best dashboard animations are the ones users never consciously notice but would miss if they were gone.
