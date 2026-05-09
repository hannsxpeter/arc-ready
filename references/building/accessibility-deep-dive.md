# Accessibility Deep Dive

This file goes beyond WCAG basics. The fundamentals — contrast ratios, focus rings, touch targets, aria-labels — are covered in `ui-design-patterns.md` and `states-and-feedback.md`. This document covers everything else: screen reader behavior, ARIA authoring patterns, keyboard navigation for SPAs, visual accessibility beyond contrast, form accessibility, data table patterns, dashboard-specific challenges, automated testing, legal compliance, and cognitive accessibility.

The standard is WCAG 2.2 AA. Not 2.1, not 2.0. WCAG 2.2 became ISO/IEC 40500:2025 in October 2025 and is backward-compatible — meeting 2.2 satisfies 2.1 and 2.0 automatically. The European Accessibility Act enforces EN 301 549 (which maps to WCAG 2.1 AA) since June 2025. The U.S. ADA Title II rule requires WCAG 2.1 AA by April 2026. Build to 2.2 AA and you cover both.

---

## 1. Screen reader testing and patterns

### Which screen readers to test

Test with at least two. The minimum viable matrix:

| Screen reader | OS | Browser | Market context |
|---|---|---|---|
| **NVDA** | Windows | Firefox | Free, strict DOM adherence, catches structural issues. Primary dev testing tool. |
| **VoiceOver** | macOS / iOS | Safari | Ships with every Mac/iPhone. Required for Apple user coverage. |
| **JAWS** | Windows | Chrome / Edge | Enterprise standard. ~40% of desktop screen reader users. Test if you sell to enterprise. |
| **TalkBack** | Android | Chrome | Required for Android mobile coverage. |

**Start with NVDA + Firefox.** This single combination catches the vast majority of accessibility issues because NVDA reads the accessibility tree strictly — if your markup is wrong, NVDA exposes it. Add VoiceOver + Safari second. Add JAWS only for enterprise products or when your user research shows JAWS usage.

### Essential testing commands

**NVDA (Windows):**
```
NVDA + Space         → Toggle browse mode / focus mode
H                    → Next heading
D                    → Next landmark
T                    → Next table
K                    → Next link
F                    → Next form field
NVDA + F7            → Elements list (headings, links, landmarks, form fields)
Ctrl                 → Stop speaking
NVDA + S             → Toggle speech mode (speech / beeps / off)
Insert + F5          → List all form fields on page
```

**VoiceOver (macOS):**
```
Cmd + F5             → Toggle VoiceOver on/off
VO + Right/Left      → Navigate next/previous element (VO = Ctrl + Option)
VO + Cmd + H         → Next heading
VO + U               → Open rotor (headings, links, landmarks, tables)
VO + Space           → Activate element
VO + Shift + Down    → Enter web content / group
VO + Shift + Up      → Exit group
```

**VoiceOver (iOS):**
```
Swipe right/left     → Next/previous element
Double tap           → Activate
Rotor (twist)        → Switch navigation mode (headings, links, form fields)
Swipe up/down        → Move within rotor category
Three-finger swipe   → Scroll
```

### Screen reader behaviors developers don't expect

**Browse mode vs. focus mode.** Screen readers on Windows (NVDA, JAWS) operate in two modes. Browse mode intercepts all keystrokes for navigation — pressing "H" jumps to next heading, not typing "h". Focus mode passes keystrokes to the page — for form inputs, custom widgets. NVDA auto-switches when focus enters an input. If your custom widget doesn't trigger this switch, keyboard users can't type in it. Set `role="application"` only on widgets that truly handle all keyboard interaction themselves — misuse breaks browse mode navigation for the entire subtree.

**Virtual buffer.** NVDA and JAWS build a linearized "virtual buffer" of the page content. They don't read the visual layout — they read the DOM order. If your CSS grid visually reorders content but the DOM order is different, screen reader users get a different reading order than sighted users. Always keep DOM order logical.

**Repetitive announcements.** Screen readers announce the role, name, and state of every element on focus. If you have `aria-label="Close"` on a button that contains the text "Close", users hear "Close, Close, button." Don't duplicate.

**Live region timing.** `aria-live` regions must exist in the DOM before content is injected. If you dynamically create the region and inject content simultaneously, screen readers miss the announcement. Render the live region empty on page load, then populate it.

### Live regions — aria-live

Use live regions to announce dynamic content changes that happen outside the user's current focus: toast notifications, form validation errors, table sort confirmations, real-time data updates.

```html
<!-- Render empty on page load. Populate later via JS. -->
<div aria-live="polite" aria-atomic="true" class="sr-only" id="announcer"></div>
```

**Polite vs. assertive:**

| Value | Behavior | Use for |
|---|---|---|
| `polite` | Waits until screen reader finishes current speech | Toast notifications, status updates, sort confirmations, saved confirmations |
| `assertive` | Interrupts immediately | Error alerts, session timeout warnings, critical failures |

**Use `assertive` sparingly.** It interrupts whatever the user is doing. For 90% of dashboard announcements, `polite` is correct.

**Related roles with built-in live region behavior:**

```html
<!-- role="alert" = aria-live="assertive" + aria-atomic="true" -->
<div role="alert">Session expires in 2 minutes.</div>

<!-- role="status" = aria-live="polite" + aria-atomic="true" -->
<div role="status">3 items saved successfully.</div>

<!-- role="log" = aria-live="polite" + aria-atomic="false" -->
<div role="log"><!-- Chat messages, activity feed --></div>

<!-- role="timer" = aria-live="off" by default (don't auto-announce every tick) -->
<div role="timer" aria-live="off" aria-label="Session timeout">04:59</div>
```

**Announcement helper pattern:**

```js
// Reusable announcer — one per app, rendered once at root
const announcer = document.getElementById('announcer');

function announce(message, priority = 'polite') {
  announcer.setAttribute('aria-live', priority);
  // Clear then set — forces re-announcement of identical messages
  announcer.textContent = '';
  requestAnimationFrame(() => {
    announcer.textContent = message;
  });
}

// Usage
announce('Table sorted by date, ascending.');
announce('Form has 3 errors. First error: email is required.', 'assertive');
```

### Making dynamic content accessible

**Toasts / snackbars:**
- Render the toast container as a live region on page mount. Inject toast text into it.
- Auto-dismiss is hostile to screen reader users. If you auto-dismiss, use `aria-live="assertive"` AND give at least 8 seconds. Better: don't auto-dismiss critical messages.
- If the toast has an action (Undo, View), it must be keyboard-focusable. Move focus to the toast on appearance, or at minimum announce it.

**Table updates (sort, filter, pagination):**
- After sorting: `announce('Table sorted by Name, ascending. Showing 25 of 142 results.')`
- After filtering: `announce('Filter applied. 12 results match.')`
- After pagination: `announce('Page 3 of 7. Showing rows 51 through 75.')`
- Don't announce every cell change during a sort animation. Announce the result once.

**Form errors:**
- On submit with errors: move focus to the first invalid field, or to an error summary at the top.
- Each error field: `aria-invalid="true"` + `aria-describedby` pointing to the error message.
- Error summary: use `role="alert"` or inject into an existing `aria-live="assertive"` region.

---

## 2. ARIA authoring patterns

### The five rules of ARIA

1. **Don't use ARIA if native HTML does the job.** A `<button>` is always better than `<div role="button" tabindex="0">`. Native elements have built-in keyboard handling, focus management, and screen reader semantics.
2. **Don't change native semantics.** Don't put `role="heading"` on a `<button>`. Use the right element.
3. **All interactive ARIA controls must be keyboard operable.** `role="button"` does not add keyboard handling. You must add `tabindex="0"`, Enter/Space handlers, and focus styles yourself.
4. **Don't use `role="presentation"` or `aria-hidden="true"` on focusable elements.** This hides the element from screen readers while keeping it keyboard-focusable — users can focus an element that doesn't exist to them.
5. **All interactive elements must have an accessible name.** Every button, link, input, and widget needs a name — via visible text, `aria-label`, or `aria-labelledby`.

### Common ARIA mistakes

**Redundant roles:**
```html
<!-- BAD — <button> already has role="button" -->
<button role="button">Save</button>

<!-- BAD — <a href> already has role="link" -->
<a href="/settings" role="link">Settings</a>

<!-- BAD — <nav> already has role="navigation" -->
<nav role="navigation">...</nav>
```

**aria-label on non-interactive elements:**
```html
<!-- BAD — aria-label is ignored on <div>, <span>, <p> by most screen readers -->
<div aria-label="Important notice">This is a notice.</div>

<!-- GOOD — use aria-labelledby or just rely on text content -->
<div role="region" aria-labelledby="notice-heading">
  <h3 id="notice-heading">Important notice</h3>
  <p>This is a notice.</p>
</div>
```

**aria-label overriding visible text:**
```html
<!-- BAD — screen reader says "Dismiss notification" but sighted users see "X" -->
<!-- Sighted users and SR users get different info -->
<button aria-label="Dismiss notification">X</button>

<!-- GOOD — visible label matches accessible name (WCAG 2.5.3 Label in Name) -->
<button aria-label="Close notification">
  <span aria-hidden="true">&times;</span>
  <span class="sr-only">Close notification</span>
</button>
```

**Missing keyboard support on ARIA widgets:**
```html
<!-- BAD — role="tab" but no keyboard handling -->
<div role="tab" aria-selected="true">Tab 1</div>

<!-- GOOD — full keyboard support -->
<button role="tab" aria-selected="true" aria-controls="panel-1"
        tabindex="0" id="tab-1">Tab 1</button>
```

### Widget patterns reference

Every pattern below follows the W3C ARIA Authoring Practices Guide (APG). Implement these exactly — screen reader users have muscle memory for these keyboard conventions.

**Tabs:**
```html
<div role="tablist" aria-label="Account settings">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1"
          tabindex="0">Profile</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2"
          tabindex="-1">Security</button>
  <button role="tab" id="tab-3" aria-selected="false" aria-controls="panel-3"
          tabindex="-1">Billing</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1" tabindex="0">
  <!-- Profile content -->
</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" tabindex="0" hidden>
  <!-- Security content -->
</div>
```

Keyboard: Arrow Left/Right move between tabs (roving tabindex). Home/End go to first/last tab. Tab key moves into the panel content. Enter/Space activate a tab (if using manual activation).

**Dialog (modal):**
```html
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title"
     aria-describedby="dialog-desc">
  <h2 id="dialog-title">Delete project?</h2>
  <p id="dialog-desc">This action cannot be undone. All data will be permanently removed.</p>
  <button>Cancel</button>
  <button>Delete</button>
</div>
```

Keyboard: Tab cycles within the dialog only (focus trap). Escape closes the dialog. On open, focus moves to the first focusable element (or the dialog itself). On close, focus returns to the element that triggered the dialog.

**Combobox (autocomplete/select):**
```html
<label for="user-search">Search users</label>
<div role="combobox" aria-expanded="false" aria-haspopup="listbox"
     aria-owns="user-listbox">
  <input id="user-search" type="text" aria-autocomplete="list"
         aria-controls="user-listbox" aria-activedescendant="">
</div>
<ul id="user-listbox" role="listbox" hidden>
  <li role="option" id="opt-1">Alice Johnson</li>
  <li role="option" id="opt-2">Bob Smith</li>
</ul>
```

Keyboard: Down Arrow opens the listbox and moves to first option. Arrow Up/Down navigate options. Enter selects. Escape closes. Type-ahead filters. `aria-activedescendant` on the input tracks the visually focused option without moving DOM focus.

**Accordion:**
```html
<div>
  <h3>
    <button aria-expanded="true" aria-controls="section-1-content"
            id="section-1-header">Billing details</button>
  </h3>
  <div id="section-1-content" role="region" aria-labelledby="section-1-header">
    <!-- Content -->
  </div>
  <h3>
    <button aria-expanded="false" aria-controls="section-2-content"
            id="section-2-header">Payment methods</button>
  </h3>
  <div id="section-2-content" role="region" aria-labelledby="section-2-header" hidden>
    <!-- Content -->
  </div>
</div>
```

Keyboard: Enter/Space toggle the section. Optionally: Arrow Up/Down move between headers, Home/End go to first/last.

**Menu (action menu, not navigation):**
```html
<button aria-haspopup="true" aria-expanded="false" aria-controls="action-menu"
        id="menu-trigger">Actions</button>
<ul role="menu" id="action-menu" aria-labelledby="menu-trigger" hidden>
  <li role="menuitem" tabindex="-1">Edit</li>
  <li role="menuitem" tabindex="-1">Duplicate</li>
  <li role="separator"></li>
  <li role="menuitem" tabindex="-1">Delete</li>
</ul>
```

Keyboard: Enter/Space/Down Arrow open menu. Arrow Up/Down navigate items. Enter activates. Escape closes and returns focus. Type-ahead by first character.

**Do not use `role="menu"` for site navigation.** Menus are for action lists (right-click menus, dropdown action lists). Navigation uses `<nav>` with links.

**Toolbar:**
```html
<div role="toolbar" aria-label="Text formatting" aria-orientation="horizontal">
  <button tabindex="0" aria-pressed="false">Bold</button>
  <button tabindex="-1" aria-pressed="false">Italic</button>
  <button tabindex="-1" aria-pressed="false">Underline</button>
</div>
```

Keyboard: roving tabindex. Arrow Left/Right move between tools. Tab exits the toolbar entirely. Home/End go to first/last.

**Tree view:**
```html
<ul role="tree" aria-label="File browser">
  <li role="treeitem" aria-expanded="true" tabindex="0">
    src/
    <ul role="group">
      <li role="treeitem" tabindex="-1">index.ts</li>
      <li role="treeitem" tabindex="-1">App.tsx</li>
    </ul>
  </li>
</ul>
```

Keyboard: Arrow Up/Down move between visible items. Arrow Right expands a collapsed node / moves to first child. Arrow Left collapses / moves to parent. Enter activates. Home/End go to first/last visible.

**Grid (interactive data grid, not a display table):**

Use `role="grid"` only when cells are individually interactive (editable cells, cell-level actions). For display-only data tables, use `<table>` — do not use grid role.

```html
<table role="grid" aria-label="User permissions">
  <thead>
    <tr>
      <th scope="col">User</th>
      <th scope="col">Read</th>
      <th scope="col">Write</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td tabindex="-1">Alice</td>
      <td tabindex="-1"><input type="checkbox" aria-label="Alice read permission"></td>
      <td tabindex="-1"><input type="checkbox" aria-label="Alice write permission"></td>
    </tr>
  </tbody>
</table>
```

Keyboard: Arrow keys move between cells. Tab moves out of the grid. Enter/Space interact with the active cell.

---

## 3. Keyboard navigation deep dive

### Focus management for SPAs

When a SPA navigates between routes, the browser doesn't reload — so it doesn't move focus or announce a new page. You must handle this manually.

**Route change pattern:**

```js
// After every client-side route change:
function onRouteChange(pageTitle) {
  // 1. Update document title
  document.title = `${pageTitle} | MyApp`;

  // 2. Move focus to the main content area or page heading
  const main = document.querySelector('main');
  const heading = main?.querySelector('h1');
  const target = heading || main;

  if (target) {
    target.setAttribute('tabindex', '-1'); // Make focusable without adding to tab order
    target.focus({ preventScroll: false });
  }

  // 3. Announce the page change
  announce(`Navigated to ${pageTitle}`);
}
```

Why `tabindex="-1"` on the heading: headings aren't normally focusable. Setting `tabindex="-1"` makes them programmatically focusable (via `.focus()`) without adding them to the Tab order. The user gets an announcement of the page title, then can Tab forward into the page content.

### Focus traps

A focus trap constrains Tab/Shift+Tab cycling within a container. Required for: modals, dialogs, slide-over panels, full-screen drawers, and any overlay that blocks interaction with the page behind it.

```js
function trapFocus(container) {
  const focusableSelectors = [
    'a[href]', 'button:not([disabled])', 'input:not([disabled])',
    'select:not([disabled])', 'textarea:not([disabled])',
    '[tabindex]:not([tabindex="-1"])', '[contenteditable]'
  ].join(', ');

  const focusableElements = container.querySelectorAll(focusableSelectors);
  const first = focusableElements[0];
  const last = focusableElements[focusableElements.length - 1];

  function handleKeyDown(e) {
    if (e.key !== 'Tab') return;

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault();
        last.focus();
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  }

  container.addEventListener('keydown', handleKeyDown);
  first?.focus();

  return () => container.removeEventListener('keydown', handleKeyDown);
}
```

**Focus restoration:** When the trap closes, return focus to the element that triggered it. Always. Store a reference to `document.activeElement` before opening the overlay, and call `.focus()` on it when the overlay closes.

```js
function openModal(modalEl) {
  const trigger = document.activeElement; // Remember who opened it
  modalEl.hidden = false;
  const releaseTrap = trapFocus(modalEl);

  function closeModal() {
    modalEl.hidden = true;
    releaseTrap();
    trigger?.focus(); // Restore focus to trigger
  }

  modalEl.querySelector('[data-close]')?.addEventListener('click', closeModal);
  modalEl.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });
}
```

### Roving tabindex

Use roving tabindex for composite widgets where Arrow keys navigate within the widget and Tab moves out of it entirely. Applies to: tablists, toolbars, menus, listboxes, tree views, radio groups.

The pattern: exactly one item has `tabindex="0"` (the current item). All others have `tabindex="-1"`. Arrow keys move `tabindex="0"` to the next item and focus it.

```js
function rovingTabindex(container, itemSelector, orientation = 'horizontal') {
  const items = Array.from(container.querySelectorAll(itemSelector));
  let currentIndex = items.findIndex(el => el.getAttribute('tabindex') === '0');
  if (currentIndex === -1) currentIndex = 0;

  function setActive(index) {
    items[currentIndex].setAttribute('tabindex', '-1');
    currentIndex = index;
    items[currentIndex].setAttribute('tabindex', '0');
    items[currentIndex].focus();
  }

  container.addEventListener('keydown', (e) => {
    const next = orientation === 'horizontal' ? 'ArrowRight' : 'ArrowDown';
    const prev = orientation === 'horizontal' ? 'ArrowLeft' : 'ArrowUp';

    if (e.key === next) {
      e.preventDefault();
      setActive((currentIndex + 1) % items.length);
    } else if (e.key === prev) {
      e.preventDefault();
      setActive((currentIndex - 1 + items.length) % items.length);
    } else if (e.key === 'Home') {
      e.preventDefault();
      setActive(0);
    } else if (e.key === 'End') {
      e.preventDefault();
      setActive(items.length - 1);
    }
  });
}
```

### Skip links

Provide a "Skip to main content" link as the first focusable element on every page. It's the first thing keyboard users Tab to — lets them bypass repetitive navigation.

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <nav><!-- Full sidebar navigation --></nav>
  <main id="main-content" tabindex="-1">
    <!-- Page content -->
  </main>
</body>
```

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 9999;
  padding: 8px 16px;
  background: var(--color-primary);
  color: white;
  font-weight: 600;
  text-decoration: none;
}

.skip-link:focus {
  top: 0;
}
```

**Don't hide skip links with `display: none`.** That removes them from the accessibility tree. Use off-screen positioning and show on focus.

For dashboards with complex layouts, consider multiple skip links: "Skip to main content," "Skip to navigation," "Skip to search."

### Keyboard shortcuts and screen reader conflicts

**Problem:** Screen readers intercept single-key shortcuts in browse mode. Pressing "G" in NVDA browse mode might navigate to the next graphic, not trigger your app's "go to" shortcut.

**WCAG 2.1 SC 1.3.6 (Character Key Shortcuts):** If you implement single-character shortcuts, provide a way to remap or disable them. This isn't optional — it's a Level A requirement.

**Rules:**
- Always use modifier keys for shortcuts (Ctrl+K, Cmd+Shift+F). Single-letter shortcuts will conflict.
- If you must use single-letter shortcuts (like Gmail's "C" for compose), provide a setting to disable them.
- Document all shortcuts in an accessible shortcut dialog (Shift+?).
- Never override browser or OS shortcuts (Ctrl+C, Ctrl+V, Ctrl+Z, Tab, Escape).
- Never override screen reader shortcuts (NVDA+key, VO+key combinations).

```html
<!-- Keyboard shortcut hint in buttons -->
<button aria-keyshortcuts="Control+S">
  Save
  <kbd class="shortcut-hint" aria-hidden="true">Ctrl+S</kbd>
</button>
```

---

## 4. Color and visual accessibility

### Beyond contrast ratios

Contrast ratios (4.5:1 for text, 3:1 for large text and UI components) are the floor, not the ceiling. This section covers what else matters.

### Color blindness safe palettes

8% of men and 0.5% of women have color vision deficiency. The most common types — protanopia and deuteranopia — make red and green look nearly identical. Tritanopia (blue-yellow) is rarer.

**Rules:**
- Never use color as the only means of conveying information. Pair color with text labels, icons, or patterns. Always.
- Never use red/green to encode binary states (success/error) without additional cues.
- For charts with multiple series, use the Wong/Okabe-Ito palette and supplement with shapes, patterns, or line styles.

**Wong/Okabe-Ito palette (8 colorblind-safe colors):**

```css
:root {
  --cb-black:       #000000;
  --cb-orange:      #E69F00;
  --cb-sky-blue:    #56B4E9;
  --cb-green:       #009E73;
  --cb-yellow:      #F0E442;
  --cb-blue:        #0072B2;
  --cb-vermillion:  #D55E00;
  --cb-pink:        #CC79A7;
}
```

**Sequential data (heatmaps, continuous values):** Use `viridis` (purple-blue-green-yellow) or `cividis` (optimized specifically for deuteranopia/protanopia). Both are perceptually uniform — equal data steps produce equal perceived color steps.

**Testing:** Use a CVD simulator on every chart and color-coded UI. Chrome DevTools has one built in: DevTools → Rendering → Emulate vision deficiencies. Test protanopia, deuteranopia, and tritanopia.

### Windows High Contrast Mode and forced-colors

Windows High Contrast Mode (WHCM) overrides all author colors with a user-chosen palette. If your dashboard relies on custom colors for state indication, WHCM may erase them. About 4% of Windows users enable WHCM.

**The `forced-colors` media query:**

```css
@media (forced-colors: active) {
  /* The browser replaces most colors. Use system color keywords. */

  .badge {
    /* Ensure badges are visible — add borders since background colors are overridden */
    border: 1px solid ButtonText;
  }

  .icon-status {
    /* forced-colors strips SVG fills. Use currentColor. */
    fill: currentColor;
  }

  .focus-ring:focus-visible {
    /* Ensure focus indicators survive. Use Highlight system color. */
    outline: 2px solid Highlight;
    outline-offset: 2px;
  }

  .chart-legend-swatch {
    /* Color swatches get stripped. Add a visible border. */
    border: 2px solid CanvasText;
  }
}
```

**System color keywords available in forced-colors mode:** `Canvas`, `CanvasText`, `LinkText`, `VisitedText`, `ActiveText`, `ButtonFace`, `ButtonText`, `ButtonBorder`, `Field`, `FieldText`, `Highlight`, `HighlightText`, `SelectedItem`, `SelectedItemText`, `Mark`, `MarkText`, `GrayText`.

**Rules for forced-colors:**
- Never put essential information in background color alone — it gets overridden.
- Add visible borders to elements that rely on background color for distinction (badges, status dots, chart swatches).
- Use `currentColor` for SVG icons so they adapt.
- Test in Windows High Contrast Mode (Settings → Accessibility → Contrast themes).

### prefers-reduced-motion

Some users enable reduced motion because of vestibular disorders, motion sensitivity, or cognitive load preferences. Respect it.

```css
/* Default: full motion */
.toast-enter {
  animation: slide-in 300ms ease-out;
}

/* Reduced motion: instant transitions, no sliding, no parallax */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Don't set `animation: none`. Some animations serve a functional purpose (progress spinners, loading indicators). Instead, shorten durations to near-zero so the state change still happens instantly without visual motion.

**What to reduce:**
- Slide-in/slide-out transitions → instant appear/disappear.
- Parallax scrolling → remove entirely.
- Auto-playing carousels → stop. Provide manual controls.
- Chart animation (bars growing, lines drawing) → show final state immediately.
- Skeleton loading shimmer → static skeleton or simple opacity fade.

**What to keep (functionally necessary):**
- Loading spinners (but prefer a static "Loading..." message as alternative).
- Progress bar fills (but make them instant, not animated).
- Focus ring transitions (keep short, ~100ms).

### prefers-contrast

```css
@media (prefers-contrast: more) {
  :root {
    --border-default: 1px solid #000;
    --text-muted: #444;           /* Darker than usual muted text */
    --bg-subtle: transparent;      /* Remove subtle backgrounds that reduce contrast */
  }

  .card {
    border: 2px solid CanvasText;  /* Add visible borders to cards that rely on shadow */
    box-shadow: none;
  }
}

@media (prefers-contrast: less) {
  /* Rare — for users who find high contrast uncomfortable (photosensitivity) */
  :root {
    --text-default: #555;
    --border-default: 1px solid #ddd;
  }
}
```

---

## 5. Forms accessibility

### Error announcement patterns

**Inline validation (on blur):**
```html
<div class="field">
  <label for="email">Email address <span aria-hidden="true">*</span></label>
  <input id="email" type="email" required
         aria-required="true"
         aria-invalid="false"
         aria-describedby="email-hint email-error">
  <p id="email-hint" class="hint">We'll send a confirmation link.</p>
  <p id="email-error" class="error" role="alert" hidden>
    Enter a valid email address (e.g. name@example.com).
  </p>
</div>
```

On validation failure:
```js
function showFieldError(inputEl, errorEl, message) {
  inputEl.setAttribute('aria-invalid', 'true');
  errorEl.textContent = message;
  errorEl.hidden = false;
  // role="alert" on the error element triggers immediate announcement
}

function clearFieldError(inputEl, errorEl) {
  inputEl.setAttribute('aria-invalid', 'false');
  errorEl.hidden = true;
}
```

**Submission error summary:**
```html
<div role="alert" aria-labelledby="error-summary-heading" id="error-summary"
     tabindex="-1" hidden>
  <h2 id="error-summary-heading">There are 3 errors in this form</h2>
  <ul>
    <li><a href="#email">Email address — enter a valid email</a></li>
    <li><a href="#password">Password — must be at least 8 characters</a></li>
    <li><a href="#terms">Terms — you must accept the terms</a></li>
  </ul>
</div>
```

On submit failure, show this summary and focus it. Each link jumps to the corresponding field. This pattern (error summary + inline errors) is the gold standard recommended by the UK Government Design System.

### Required field indication

**Don't rely on the asterisk alone.** Some screen reader users don't hear it.

```html
<!-- State the convention at the top of the form -->
<p>Fields marked with <abbr title="required">*</abbr> are required.</p>

<!-- On each required field, use aria-required -->
<label for="name">
  Full name <span aria-hidden="true">*</span>
</label>
<input id="name" type="text" aria-required="true" required>
```

Why both `required` and `aria-required="true"`? The HTML `required` attribute triggers native validation (which you may want to override with custom validation). `aria-required` ensures screen readers announce "required" regardless of whether you use native validation.

### Fieldset and legend for groups

Group related fields. Screen readers announce the legend when a user focuses any field in the group — providing context.

```html
<fieldset>
  <legend>Billing address</legend>
  <label for="street">Street</label>
  <input id="street" type="text">
  <label for="city">City</label>
  <input id="city" type="text">
  <!-- ... -->
</fieldset>

<!-- Radio groups MUST use fieldset/legend -->
<fieldset>
  <legend>Notification preference</legend>
  <label><input type="radio" name="notify" value="email"> Email</label>
  <label><input type="radio" name="notify" value="sms"> SMS</label>
  <label><input type="radio" name="notify" value="none"> None</label>
</fieldset>
```

### Autocomplete attributes

Use `autocomplete` on fields that accept personal data. This enables browsers and password managers to auto-fill, and assistive technologies to identify field purpose (WCAG 1.3.5 Identify Input Purpose, Level AA).

```html
<input type="text" autocomplete="given-name" name="firstName">
<input type="text" autocomplete="family-name" name="lastName">
<input type="email" autocomplete="email" name="email">
<input type="tel" autocomplete="tel" name="phone">
<input type="text" autocomplete="street-address" name="address">
<input type="text" autocomplete="postal-code" name="zip">
<input type="text" autocomplete="cc-name" name="cardName">
<input type="password" autocomplete="new-password" name="newPassword">
<input type="password" autocomplete="current-password" name="currentPassword">
<input type="text" autocomplete="one-time-code" name="otp">
```

### Validation timing

**Don't validate on every keystroke.** Screen readers would announce errors continuously as the user types.

**Recommended timing:**
- **On blur (field exit):** Validate when the user leaves the field. This catches errors early without interrupting typing.
- **On submit:** Validate all fields, show error summary, focus first error.
- **After first error shown:** Switch to live validation (on input change) for that specific field so users get immediate feedback as they correct.
- **Never on focus.** Users haven't entered anything yet.

### Accessible date pickers

The hardest form control to get right. Two W3C-endorsed patterns:

**Pattern 1: Combobox date picker** — Text input for typing + calendar popup for picking.
- Users can type the date directly (not everyone can use a calendar grid).
- Describe the expected format: `aria-describedby="date-format"` → "Format: MM/DD/YYYY."
- Calendar grid opens with Down Arrow or a "Choose date" button.
- Calendar grid is a `role="grid"` inside a `role="dialog"`.
- Arrow keys navigate days. Page Up/Down change months. Escape closes.
- Calendar heading (month/year) is a live region so screen readers announce month changes.

**Pattern 2: Native `<input type="date">`** — simpler, decent screen reader support in modern browsers, but limited styling control. Acceptable for admin tools and internal dashboards where pixel-perfect design is less important.

**Rule:** Always allow manual text entry alongside any calendar widget. Users with motor impairments, screen reader users, and power users all prefer typing dates.

---

## 6. Data table accessibility

### Basic table requirements

```html
<table aria-label="Active users">
  <caption class="sr-only">Active users showing name, role, and last login</caption>
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Role</th>
      <th scope="col">Last login</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Alice Johnson</td>
      <td>Admin</td>
      <td>Apr 11, 2026</td>
    </tr>
  </tbody>
</table>
```

**Required:** `<th scope="col">` for column headers, `<th scope="row">` for row headers. Without scope, screen readers can't associate data cells with their headers.

### Sortable tables

```html
<table aria-label="Users">
  <thead>
    <tr>
      <th scope="col" aria-sort="ascending">
        <button>Name <span aria-hidden="true">&#9650;</span></button>
      </th>
      <th scope="col" aria-sort="none">
        <button>Role</button>
      </th>
      <th scope="col" aria-sort="none">
        <button>Last login</button>
      </th>
    </tr>
  </thead>
  <!-- tbody -->
</table>

<!-- Live region for sort announcements -->
<div aria-live="polite" class="sr-only" id="sort-status"></div>
```

**Rules:**
- Wrap sortable column headers in `<button>` elements. This makes them keyboard-focusable and interactive.
- Set `aria-sort="ascending"`, `"descending"`, or `"none"` on the `<th>`.
- Only one column should have `aria-sort` set to ascending/descending at a time. Others get `"none"`.
- After sort: update `aria-sort` values and announce via live region: "Table sorted by Name, ascending."
- Don't use `aria-sort="other"` — it's meaningless to screen reader users.

### Filterable tables

```html
<div>
  <label for="role-filter">Filter by role</label>
  <select id="role-filter" aria-controls="users-table">
    <option value="">All roles</option>
    <option value="admin">Admin</option>
    <option value="editor">Editor</option>
  </select>
</div>

<table id="users-table" aria-label="Users">
  <!-- ... -->
</table>

<div aria-live="polite" class="sr-only" id="filter-status"></div>
```

After filter change: `announce('Filter applied: Admin. Showing 5 of 142 users.')`.

Use `aria-controls` on the filter to establish a relationship with the table. Not all screen readers support `aria-controls` yet, but it's semantically correct and support is improving.

### Row selection and bulk actions

```html
<table aria-label="Users" role="grid">
  <thead>
    <tr>
      <th scope="col">
        <input type="checkbox" aria-label="Select all rows"
               id="select-all">
      </th>
      <th scope="col">Name</th>
      <th scope="col">Role</th>
    </tr>
  </thead>
  <tbody>
    <tr aria-selected="false">
      <td>
        <input type="checkbox" aria-label="Select Alice Johnson">
      </td>
      <td>Alice Johnson</td>
      <td>Admin</td>
    </tr>
  </tbody>
</table>

<!-- Bulk action bar — appears when rows are selected -->
<div role="toolbar" aria-label="Bulk actions" id="bulk-actions" hidden>
  <span>3 users selected</span>
  <button>Export selected</button>
  <button>Change role</button>
  <button>Delete selected</button>
</div>

<div aria-live="polite" class="sr-only" id="selection-status"></div>
```

On selection change: `announce('3 users selected. Bulk actions available.')`.

When the bulk action bar appears, don't auto-focus it — the user may be selecting more rows. Let them Tab to it.

### Expandable rows

```html
<tr>
  <td>
    <button aria-expanded="false" aria-controls="detail-row-1"
            aria-label="Show details for Alice Johnson">
      <span aria-hidden="true">&#9654;</span> <!-- Caret icon -->
    </button>
  </td>
  <td>Alice Johnson</td>
  <td>Admin</td>
</tr>
<tr id="detail-row-1" hidden>
  <td colspan="3">
    <!-- Expanded detail content -->
  </td>
</tr>
```

`aria-expanded` announces the state. `aria-controls` links the button to the detail row. Toggle `hidden` to show/hide.

### Pagination

```html
<nav aria-label="Table pagination">
  <ul>
    <li><a href="#" aria-label="Previous page" aria-disabled="true">&laquo;</a></li>
    <li><a href="#" aria-current="page" aria-label="Page 1">1</a></li>
    <li><a href="#" aria-label="Page 2">2</a></li>
    <li><a href="#" aria-label="Page 3">3</a></li>
    <li><a href="#" aria-label="Next page">&raquo;</a></li>
  </ul>
</nav>

<div aria-live="polite" class="sr-only" id="page-status"></div>
```

After page change: `announce('Page 2 of 7. Showing rows 26 through 50 of 142.')`.

Mark the current page with `aria-current="page"`. Disable the previous button on page 1 with `aria-disabled="true"`.

### Virtual / infinite scroll tables

Virtual scrolling renders only visible rows to the DOM. This breaks screen reader table navigation because the full table doesn't exist.

```html
<table role="grid" aria-rowcount="10000" aria-label="Log entries">
  <thead>
    <tr>
      <th scope="col">Timestamp</th>
      <th scope="col">Level</th>
      <th scope="col">Message</th>
    </tr>
  </thead>
  <tbody>
    <!-- Only ~20 rows rendered at a time -->
    <tr aria-rowindex="51">
      <td>2026-04-12 09:14:22</td>
      <td>ERROR</td>
      <td>Connection refused</td>
    </tr>
    <tr aria-rowindex="52">
      <td>2026-04-12 09:14:23</td>
      <td>INFO</td>
      <td>Retry attempt 1</td>
    </tr>
    <!-- ... -->
  </tbody>
</table>
```

**Required attributes for virtual scroll:**
- `aria-rowcount` on the table — total number of rows (or -1 if unknown).
- `aria-rowindex` on every `<tr>` — the row's position in the full dataset (1-indexed).

**Warning:** Inconsistent or missing `aria-rowindex` values will cause screen reader table navigation to skip rows or break completely. Every rendered row must have it, and values must be sequential for the current window.

**Prefer paginated tables over infinite scroll.** Pagination gives screen reader users clear boundaries and position awareness. Infinite scroll makes it impossible to know where you are in the dataset. If you must use infinite scroll, add a `role="feed"` wrapper with `aria-busy="true"` during loads and provide keyboard commands (Page Up/Down) for chunked navigation.

---

## 7. Dashboard-specific accessibility

### Charts for screen readers

Charts are the biggest accessibility gap in dashboards. An SVG line chart is invisible to screen readers by default.

**Strategy: layered accessibility.**

1. **Alt text on the chart container** — a brief summary of the insight.
2. **Structured data table** — the same data in an accessible `<table>`, toggleable or always visible.
3. **Sonification** — optional, for users who want auditory data exploration.

```html
<figure>
  <figcaption id="chart-caption">Monthly revenue, January through December 2025</figcaption>
  <div role="img" aria-labelledby="chart-caption"
       aria-describedby="chart-summary">
    <!-- SVG chart rendered here -->
  </div>
  <p id="chart-summary" class="sr-only">
    Revenue grew from $120K in January to $340K in December,
    with a dip to $95K in March. The overall trend is upward
    with 183% year-over-year growth.
  </p>
  <details>
    <summary>View data table</summary>
    <table>
      <caption>Monthly revenue 2025</caption>
      <thead>
        <tr><th scope="col">Month</th><th scope="col">Revenue</th></tr>
      </thead>
      <tbody>
        <tr><td>January</td><td>$120,000</td></tr>
        <tr><td>February</td><td>$145,000</td></tr>
        <!-- ... -->
      </tbody>
    </table>
  </details>
</figure>
```

**Rules for chart alt text:**
- Describe the insight, not the visual. "Revenue grew 183% over the year" is better than "A line chart going up."
- For comparison charts: state which item leads and by how much.
- For pie/donut: state the top 2-3 segments and their percentages.
- Keep it under 150 words. Link to the full data table for details.

**Sonification:** Libraries like Highcharts include built-in sonification — data points are mapped to audio tones. Higher values = higher pitch. Users can navigate data points with arrow keys and hear the trend. This is cutting-edge (Highcharts demonstrated AI-enhanced sonification at CSUN 2026) but worth implementing for data-heavy dashboards.

### KPI cards for screen readers

```html
<section aria-label="Key metrics">
  <div role="group" aria-labelledby="kpi-revenue">
    <h3 id="kpi-revenue">Monthly Revenue</h3>
    <p class="kpi-value" aria-label="Monthly Revenue: $342,500">$342.5K</p>
    <p class="kpi-change" aria-label="Up 12.3% from last month">
      <span aria-hidden="true">&#9650;</span> 12.3%
    </p>
  </div>
</section>
```

**Problems with the naive approach:**
- "$342.5K" is read as "three hundred forty-two point five K" — meaningless. Use `aria-label` with the full value.
- The up-arrow icon is decorative but may be read as a Unicode character. Mark it `aria-hidden="true"`.
- "12.3%" without context is meaningless. Include direction and comparison period in the `aria-label`.

### Real-time data updates

Dashboards that show live data (monitoring, analytics, operations) create a screen reader problem: if every data change triggers an announcement, the screen reader talks non-stop.

**Rules:**
- Do NOT make every data cell a live region.
- Announce only meaningful threshold changes: "CPU usage exceeded 90%." "3 new errors in the last minute."
- Use `aria-live="polite"` for status summaries. Update them on a reasonable cadence (every 30 seconds, not every second).
- Provide a manual refresh button for users who want control over when data updates.
- If auto-refresh is enabled, announce it: "Data refreshes automatically every 30 seconds."
- Provide a way to pause auto-refresh. Auto-updating content is a WCAG 2.2.2 (Pause, Stop, Hide) requirement.

```html
<!-- Summary that updates periodically, not on every data change -->
<div role="status" aria-live="polite" aria-atomic="true">
  System status: 3 healthy, 1 degraded. Last updated 30 seconds ago.
</div>

<button aria-pressed="true" id="auto-refresh-toggle">
  Auto-refresh: On
</button>
```

### Notification accessibility

Dashboard notifications (bell icon with count, dropdown list of notifications):

```html
<button aria-label="Notifications, 5 unread" aria-haspopup="true"
        aria-expanded="false">
  <svg aria-hidden="true"><!-- bell icon --></svg>
  <span class="badge" aria-hidden="true">5</span>
</button>
```

- The badge count is in `aria-label`, not read separately. `aria-hidden` on the visual badge prevents double-announcement.
- When new notifications arrive, announce via live region: "New notification: Deploy to production completed."
- Notification list should be a `role="menu"` or `role="list"` with clear items.
- Each notification needs a timestamp that screen readers can parse: use `<time datetime="2026-04-12T09:14:00Z">5 minutes ago</time>`.

---

## 8. Accessibility testing and CI

### What automated tools catch

Automated tools (axe-core, Lighthouse, pa11y) detect **30-40% of WCAG issues**. They catch:
- Missing alt text
- Color contrast failures
- Missing form labels
- Missing document language
- Duplicate IDs
- Missing landmark roles
- Empty buttons/links
- Incorrect heading hierarchy (partially)

### What automated tools miss

The other 60-70%:
- Is the alt text actually accurate and descriptive?
- Does the tab order make logical sense?
- Are keyboard traps present in custom widgets?
- Do screen reader announcements make sense in context?
- Is the reading order logical when CSS reorders content?
- Are live region announcements helpful and not excessive?
- Is focus managed correctly after dynamic changes (modals, route changes, deletions)?
- Do custom widgets follow APG keyboard patterns?
- Is the content actually understandable?

**This is why automated testing is a floor, not a ceiling.** You need both.

### axe-core integration

**In unit/integration tests (Jest/Vitest):**
```js
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('form has no accessibility violations', async () => {
  const { container } = render(<UserForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

**In E2E tests (Playwright):**
```js
import AxeBuilder from '@axe-core/playwright';

test('dashboard page passes axe', async ({ page }) => {
  await page.goto('/dashboard');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

**In Cypress:**
```js
import 'cypress-axe';

describe('Dashboard accessibility', () => {
  it('has no detectable violations on load', () => {
    cy.visit('/dashboard');
    cy.injectAxe();
    cy.checkA11y(null, {
      runOnly: {
        type: 'tag',
        values: ['wcag2a', 'wcag2aa', 'wcag22aa'],
      },
    });
  });
});
```

### pa11y-ci for CI pipelines

```yaml
# .github/workflows/a11y.yml
name: Accessibility
on: [push, pull_request]

jobs:
  a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
      - run: npx serve -l 3000 dist &
      - run: npx wait-on http://localhost:3000
      - run: npx pa11y-ci --config .pa11yci.json
```

```json
// .pa11yci.json
{
  "defaults": {
    "standard": "WCAG2AA",
    "runners": ["axe", "htmlcs"],
    "chromeLaunchConfig": { "args": ["--no-sandbox"] },
    "timeout": 30000
  },
  "urls": [
    "http://localhost:3000/",
    "http://localhost:3000/dashboard",
    "http://localhost:3000/settings",
    "http://localhost:3000/users"
  ]
}
```

**Use both axe-core and pa11y together.** They use different rule engines and each catches things the other misses. Combined, they detect roughly 35% of known issues — more than either alone.

### Lighthouse CI

```json
// lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:accessibility": ["error", { "minScore": 0.95 }]
      }
    },
    "collect": {
      "url": [
        "http://localhost:3000/",
        "http://localhost:3000/dashboard"
      ]
    }
  }
}
```

Set the threshold at 0.95, not 1.0. Lighthouse accessibility scores fluctuate slightly between runs. A 0.95 threshold catches real regressions without flaky failures.

### Manual testing checklist

Run this checklist before every release. Automated tools cannot cover these items.

**Keyboard:**
- [ ] Tab through the entire page — is the order logical?
- [ ] Can you reach and operate every interactive element with keyboard alone?
- [ ] Do modals trap focus correctly?
- [ ] Does focus return to the trigger when modals/drawers close?
- [ ] Are there any keyboard traps (can't Tab out of a component)?
- [ ] Do skip links work?
- [ ] Do custom widgets follow APG keyboard patterns?

**Screen reader:**
- [ ] Navigate by headings — is the hierarchy logical (h1 → h2 → h3, no skips)?
- [ ] Navigate by landmarks — are main, nav, banner, contentinfo present?
- [ ] Do all images have meaningful alt text (or empty alt for decorative)?
- [ ] Do form fields have visible labels AND programmatic labels?
- [ ] Are error messages announced?
- [ ] Are dynamic content changes announced (toasts, table updates)?
- [ ] Do charts have text alternatives?

**Visual:**
- [ ] Zoom to 200% — does the layout still work?
- [ ] Zoom to 400% — is content still accessible (WCAG 1.4.10 Reflow)?
- [ ] Enable High Contrast Mode — is everything still visible?
- [ ] Enable reduced motion — are animations removed?
- [ ] Simulate color blindness — is information conveyed without color alone?

---

## 9. Legal compliance

### WCAG 2.2 AA — the new success criteria

WCAG 2.2 adds 9 criteria over 2.1. The ones most relevant to dashboards:

**Focus Not Obscured (Minimum) — 2.4.11 (Level AA):**
When a UI component receives keyboard focus, it must not be entirely hidden by sticky headers, fixed footers, or overlapping content. This is a common dashboard failure — sticky table headers or fixed nav bars cover the focused element as the user tabs down.

Fix: ensure scroll-padding or scroll-margin accounts for sticky element heights.
```css
html {
  scroll-padding-top: 80px; /* Height of sticky header */
}
```

**Dragging Movements — 2.5.7 (Level AA):**
Any functionality that requires dragging must have a non-dragging alternative. Dashboards love drag-and-drop (kanban boards, dashboard widget rearrangement, drag-to-reorder). Every drag action needs an alternative: arrow buttons, "Move to" menu, or keyboard arrow key controls.

**Target Size (Minimum) — 2.5.8 (Level AA):**
Interactive targets must be at least 24x24 CSS pixels, with exceptions for inline text links and targets where size is determined by the user agent. This means table action icons, small chart interactors, and toolbar buttons must meet the minimum.

**Accessible Authentication (Minimum) — 3.3.8 (Level AA):**
Authentication must not require a cognitive function test (memorization, transcription, puzzle solving) unless an alternative is provided. CAPTCHAs fail this unless they offer an audio or logic-based alternative. Copy-paste of passwords must be allowed (don't block paste in password fields). Support password managers via correct `autocomplete` attributes.

**Redundant Entry — 3.3.7 (Level A):**
If the user has already entered information in a process, don't make them enter it again. Auto-populate from previous steps. This applies to multi-step forms, checkout flows, and settings wizards.

**Consistent Help — 3.2.6 (Level A):**
If help mechanisms (contact info, help chat, FAQ link) exist on multiple pages, they must appear in the same relative position on each page. Dashboard help buttons should be in a consistent location (e.g., always in the top-right header or always in the sidebar footer).

### ADA and Section 508 (United States)

- **ADA Title II** (government entities): WCAG 2.1 AA required by April 24, 2026.
- **ADA Title III** (private businesses): No explicit WCAG requirement in statute, but courts increasingly use WCAG 2.1 AA as the benchmark.
- **Section 508** (federal agencies): Requires conformance to WCAG 2.0 AA (being updated to 2.1).
- **Legal risk for SaaS:** ADA lawsuits against websites tripled between 2018-2023. SaaS products serving U.S. customers face real litigation risk. Settlements range from $10K to $6M+ depending on company size and willfulness.

### European Accessibility Act (EAA)

- **Enforcement date:** June 28, 2025. Fully enforceable now across all EU member states.
- **Technical standard:** EN 301 549, which maps to WCAG 2.1 AA.
- **Scope:** Any business selling digital products or services to EU consumers, regardless of where the business is located. A U.S. SaaS company with EU customers must comply.
- **Affected sectors:** E-commerce, SaaS, fintech, media, travel, banking.
- **Penalties:** Up to EUR 500K in fines (varies by member state), plus public enforcement actions.
- **Exemption:** Micro-enterprises with fewer than 10 employees AND annual turnover below EUR 2M.
- **Requirements beyond WCAG:** Publish an accessibility statement. Provide a feedback mechanism for reporting accessibility issues. Maintain compliance on an ongoing basis for all new content and updates.

### AODA (Canada)

- **Accessibility for Ontarians with Disabilities Act:** Applies to organizations with 50+ employees operating in Ontario.
- **Standard:** WCAG 2.0 AA for web content.
- **The Accessible Canada Act (federal):** Applies to federally regulated entities. Broader scope than AODA.

### What this means for SaaS products

If your SaaS product has users in the U.S., EU, Canada, or UK, you're subject to accessibility law in at least one jurisdiction. The practical compliance target is WCAG 2.2 AA — it satisfies all current legal standards.

**Minimum actions:**
1. Build to WCAG 2.2 AA.
2. Publish an accessibility statement (required by EAA, recommended for ADA).
3. Provide a feedback mechanism for accessibility issues.
4. Include accessibility in your CI pipeline (axe-core + pa11y).
5. Manual audit annually or with major redesigns.
6. Maintain a VPAT (Voluntary Product Accessibility Template) if selling to enterprises — procurement teams require it.

---

## 10. Cognitive accessibility

### Plain language

Write UI text at a lower-secondary reading level (grade 7-8). This isn't about dumbing down — it's about being clear. Technical content can be precise while using short sentences and common words.

**Rules:**
- Sentences under 25 words.
- One idea per sentence.
- Active voice, not passive. "The system deleted the file" not "The file was deleted by the system."
- Define jargon on first use. If a term is domain-specific, provide a tooltip or glossary link.
- Action labels describe outcomes: "Delete project" not "Submit" or "Process" or "Continue."
- Error messages state what happened AND what to do: "Password must be at least 8 characters. Add more characters." Not just "Invalid password."

**Test readability:** Use the Flesch-Kincaid readability test. Aim for a Flesch Reading Ease score of 60-70 (easily understood by 13-15 year olds). Hemingway Editor (hemingwayapp.com) highlights complex sentences and passive voice.

### Predictable navigation

- **Consistent layout:** Navigation components must appear in the same relative position across all pages (WCAG 3.2.3). If the sidebar is on the left on the dashboard, it's on the left on settings, on users, on reports.
- **Consistent identification:** Elements with the same function must be labeled the same way across pages (WCAG 3.2.4). If you call it "Search" in the header, don't call it "Find" on another page.
- **No context changes on focus.** Focusing a form field must not change the page, open a new window, or move focus elsewhere.
- **No context changes on input without warning.** Changing a select dropdown should filter content, not navigate to a new page, unless the user is warned.

### Error prevention

For actions that are destructive, legal, financial, or submit user data:

```html
<!-- Confirmation pattern for destructive actions -->
<dialog role="alertdialog" aria-labelledby="confirm-title" aria-describedby="confirm-desc">
  <h2 id="confirm-title">Delete project "Acme Dashboard"?</h2>
  <p id="confirm-desc">
    This will permanently delete the project, all its data, and 47 associated reports.
    This action cannot be undone.
  </p>
  <button>Cancel</button>
  <button class="destructive">Delete permanently</button>
</dialog>
```

**Rules:**
- Destructive actions require confirmation. Always.
- State what will be lost in the confirmation dialog. "Delete project" is not enough — "Delete project, 47 reports, and all associated data" is.
- Provide undo for reversible actions (archive instead of delete, soft-delete with 30-day recovery).
- For form submissions: provide a review step before final submit.
- For financial transactions: show a summary and require explicit confirmation.

### Undo support

Undo transforms a "careful decision" into a "try and see" action. It reduces cognitive load dramatically.

**Patterns:**
- **Toast with undo:** "3 items archived. [Undo]" — 8+ second auto-dismiss, user can undo before it disappears.
- **Soft delete:** Items move to a trash/archive, recoverable for 30 days.
- **Version history:** For edited content, keep previous versions accessible.
- **Draft auto-save:** For forms, auto-save drafts so the user never loses work.

### Information hierarchy

- **Progressive disclosure:** Show essential information first. Details are one click deeper (expandable sections, detail drawers, "Show more" links).
- **Chunk content:** Break long forms into steps. Break long pages into sections with headings.
- **Visual hierarchy:** Headings, whitespace, and grouping convey structure. Don't rely on color or font weight alone.
- **Consistent grouping:** Related actions are together. Destructive actions are visually separated (different section, different color, extra confirmation).

### Reading level considerations for dashboards

Dashboards are data-dense by nature. Cognitive accessibility doesn't mean removing density — it means organizing it:

- **KPI cards at the top** — the most important numbers, large, with clear labels. Users with cognitive disabilities can get the headline without processing a full data table.
- **Filters before data** — let users reduce the dataset before presenting it.
- **Empty states with guidance** — "No results found" isn't helpful. "No users match your filter. Try removing the 'Admin' filter or search by name." gives a next action.
- **Tooltips for abbreviations** — don't assume everyone knows MRR, ARR, DAU, MAU, CLTV. Define on hover and on first use.

---

## WCAG 2.2 AA quick reference for dashboards

The full checklist is 50+ criteria at Level A and 20+ at Level AA. These are the ones that dashboard developers fail most often:

| Criterion | Level | Dashboard failure mode |
|---|---|---|
| 1.1.1 Non-text Content | A | Charts without alt text, icon buttons without labels |
| 1.3.1 Info and Relationships | A | Tables without `<th>` scope, visual-only grouping |
| 1.3.5 Identify Input Purpose | AA | Missing `autocomplete` attributes on form fields |
| 1.4.1 Use of Color | A | Status indicators using color alone (no icon/text) |
| 1.4.3 Contrast (Minimum) | AA | Muted text, disabled states, placeholder text too light |
| 1.4.10 Reflow | AA | Dashboard layout breaks at 320px/400% zoom |
| 1.4.11 Non-text Contrast | AA | Chart lines, form borders, focus indicators below 3:1 |
| 1.4.13 Content on Hover or Focus | AA | Tooltips disappear too quickly, can't be dismissed |
| 2.1.1 Keyboard | A | Custom widgets not keyboard operable |
| 2.1.2 No Keyboard Trap | A | Focus stuck in custom widget or modal |
| 2.2.2 Pause, Stop, Hide | A | Auto-refreshing dashboards with no pause control |
| 2.4.3 Focus Order | A | Tab order doesn't match visual order |
| 2.4.6 Headings and Labels | AA | Generic headings ("Section 1"), unlabeled form fields |
| 2.4.7 Focus Visible | AA | Custom focus styles removed, invisible focus state |
| 2.4.11 Focus Not Obscured | AA | Sticky headers covering focused elements |
| 2.5.7 Dragging Movements | AA | Kanban drag-only, no keyboard reorder alternative |
| 2.5.8 Target Size (Minimum) | AA | Tiny table action icons, small chart interactors |
| 3.2.6 Consistent Help | A | Help button in different position across pages |
| 3.3.1 Error Identification | A | Error messages not associated with fields |
| 3.3.3 Error Suggestion | AA | "Invalid input" with no guidance on correct format |
| 3.3.7 Redundant Entry | A | Re-entering data in multi-step forms |
| 3.3.8 Accessible Authentication | AA | CAPTCHA without alternative, paste blocked on passwords |
| 4.1.3 Status Messages | AA | Toast/filter/sort changes not announced to screen readers |

---

## Accessibility statement template

Required by the EAA, recommended everywhere. Publish at `/accessibility` or `/accessibility-statement`.

The statement should include:
1. Which standard you conform to (WCAG 2.2 Level AA).
2. Known limitations and their timelines for remediation.
3. How to contact you about accessibility issues (email, phone, form).
4. Date of last assessment and who performed it.
5. Feedback mechanism and response time commitment.

```markdown
## Accessibility Statement

[Product Name] is committed to ensuring digital accessibility for people with disabilities.
We are continually improving the user experience for everyone and applying relevant
accessibility standards.

### Conformance status
[Product Name] is partially conformant with WCAG 2.2 Level AA.
"Partially conformant" means that some parts of the content do not fully conform
to the accessibility standard.

### Known limitations
- [Chart component]: Data visualizations do not yet have full screen reader descriptions.
  Workaround: data tables are available for all charts. Fix timeline: Q3 2026.

### Feedback
We welcome your feedback on the accessibility of [Product Name].
Please let us know if you encounter accessibility barriers:
- Email: accessibility@example.com
- Response time: 5 business days

### Assessment
This statement was last updated on [date]. It is based on a self-assessment
and third-party audit by [auditor name] conducted on [audit date].
```
