# Internationalization & Localization

This file covers how to build a dashboard that works across languages, locales, writing directions, and cultural conventions. i18n is structural — retrofitting it after building a monolingual dashboard is a rewrite. If the dashboard will ever serve users who speak different languages or live in different countries, make the decisions in this file during pre-flight, not after launch.

The scope: string translation, number/date/currency formatting, RTL layout support, timezone handling, translation workflows, and dashboard-specific i18n concerns.

---

## Architecture decisions (decide during pre-flight)

### String extraction strategy

**Use key-based translation (`t('dashboard.welcome')`) for dashboards.**

Why: dashboard strings are short and context-dependent (the word "Status" translates differently as a table header vs. a filter label). Keys serve as stable identifiers — changing the English copy doesn't break the translation key. Tooling (scanners, TMS sync, unused-key detection) is more mature for key-based workflows.

Use ICU MessageFormat as the *value* format so translators see real sentences:

```json
{
  "dashboard": {
    "welcome": "Welcome back, {name}!",
    "rowCount": "{count, plural, one {# row} other {# rows}}"
  }
}
```

### Translation file format

**Use nested JSON.** Native to the JS toolchain, all libraries support it, every TMS syncs with it. Structure by feature domain, not by page:

```
locales/
  en/
    common.json         // Save, Cancel, Delete, Loading...
    auth.json           // Login, Reset password, 2FA
    dashboard.json      // Overview metrics, sidebar
    users.json          // User management CRUD
    billing.json        // Plans, invoices, payment
    settings.json       // Account settings
    errors.json         // Error messages
    notifications.json  // Toasts, alerts
```

Keep `common.json` lean — only truly universal strings. If a string appears in only 2-3 features, put it in each feature file rather than common.

### Where to store locale preference

**User profile (DB) as primary, cookie as fallback.**

Detection chain at page load:
1. Authenticated? Read `user.locale` from DB/session.
2. Not authenticated? Read `locale` cookie.
3. No cookie? Parse `Accept-Language` header.
4. Nothing matches supported locales? Fall back to default (`en`).

URL-based locale (`/en/dashboard`) is only needed for SEO on public-facing pages. Admin panels behind auth rarely need it.

### Default locale and fallback chain

```
User's locale > language without region (pt-BR > pt) > default (en)
```

Configure your i18n library to warn (not crash) on missing keys in development, and silently fall back in production. Never show an empty string.

### Build-time vs runtime loading

- **Bundle the default locale** (English) into the main JS bundle so first paint never waits for a fetch.
- **Lazy-load other locales** per namespace on demand: when a user with `locale=de` navigates to billing, fetch `de/billing.json`.
- For Next.js with `next-intl`, translations load in Server Components — zero client-side fetch.
- Compile-time approaches (Lingui, Paraglide) produce tree-shakable JS modules per locale — the most performant option.

---

## Library selection

### By framework (2026 recommendations)

| Framework | Library | Why |
|---|---|---|
| **Next.js (App Router)** | next-intl | Purpose-built for App Router. Server Components, middleware routing, TypeScript-first. The clear winner. |
| **React SPA (Vite)** | react-i18next | Largest ecosystem — plugins for backends, caching, language detection. Works everywhere. |
| **React (performance-critical)** | Lingui | Compile-time extraction and optimization. Smallest runtime. |
| **Vue / Nuxt** | vue-i18n (Composition API mode) | The standard. Use `legacy: false` for Composition API. |
| **SvelteKit** | Paraglide JS | Officially recommended. Compiler approach, tree-shakable, type-safe. |
| **Cross-framework** | i18next | Same core library, different bindings (React, Vue, Node, vanilla). |

### Server-side i18n

For API responses, emails, and PDFs, the server needs its own i18n instance:

- Create a server-side translator initialized with the request user's locale.
- API error responses: return both a machine-readable `code` (never translated) and a human-readable `message` (translated). The client can use either.
- Emails: always render in the *recipient's* locale, not the sender's.
- PDFs/exports: render in the user's locale. For invoices sent to others, ask which locale.

---

## String handling patterns

### Interpolation

```
// ICU MessageFormat
"welcome": "Welcome back, {name}!"
"lastLogin": "Last login: {date, date, medium}"
```

Rules:
- Never concatenate translated strings: `t('hello') + ' ' + name` breaks in languages with different word order.
- Use named placeholders (`{name}`), not positional (`{0}`).
- Pass variables to the translation function: `t('welcome', { name: user.name })`.

### Pluralization (ICU MessageFormat)

ICU plural categories: `zero`, `one`, `two`, `few`, `many`, `other`. English uses only `one` and `other`. Arabic uses all six. Always include `other` as fallback.

```
"itemCount": "{count, plural,
  =0 {No items}
  one {# item}
  other {# items}
}"
```

Test with: 0, 1, 2, 5, 21, 100. Different languages have different break points (Russian: 21 uses `one` form, not `other`).

### Gender and grammatical agreement

Use ICU `select`:

```
"profileUpdate": "{gender, select,
  male {He updated his profile}
  female {She updated her profile}
  other {They updated their profile}
}"
```

### Context-dependent translations

The same English word often needs different translations. Use namespace keys to disambiguate:

```json
{
  "table": { "status": "Status" },
  "filter": { "status": "Filter by status" },
  "order": { "status": { "pending": "Pending", "shipped": "Shipped" } }
}
```

Never use a single "Status" key everywhere — translators need context.

---

## Date, time, and timezone handling

### Core rules

1. **Store as UTC** in the database. Always. Use `TIMESTAMPTZ` in PostgreSQL.
2. **Display in the user's timezone.** Get it from user profile or `Intl.DateTimeFormat().resolvedOptions().timeZone`.
3. **Use ISO 8601 in APIs.** Send `2026-04-11T14:30:00Z`. Let the client format.

### Formatting per locale

Never hardcode date formats. Use `Intl.DateTimeFormat`:

```javascript
new Intl.DateTimeFormat('en-US', { dateStyle: 'medium' }).format(date) // "Apr 11, 2026"
new Intl.DateTimeFormat('de-DE', { dateStyle: 'medium' }).format(date) // "11.04.2026"
new Intl.DateTimeFormat('ja-JP', { dateStyle: 'medium' }).format(date) // "2026/04/11"
```

### Relative time

```javascript
const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' })
rtf.format(-1, 'day')    // "yesterday"
rtf.format(-2, 'hour')   // "2 hours ago"
```

### Calendar systems

`Intl.DateTimeFormat` supports non-Gregorian calendars via the `calendar` option: `islamic`, `buddhist`, `japanese`. Default to Gregorian; offer as a user preference if your audience needs it.

### First day of week

Varies by locale: Sunday (US), Monday (Europe), Saturday (Middle East). Use `new Intl.Locale('ar-SA').getWeekInfo()` to configure calendar/date picker components.

### Locale-aware date pickers

For shadcn/ui: the Calendar component wraps React DayPicker. Pass `locale` and `dir` props. For other frameworks, ensure your date picker library accepts locale configuration.

---

## Number and currency formatting

### All formatting via `Intl.NumberFormat`

```javascript
// Currency — position and symbol vary by locale
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(1234.5) // "$1,234.50"
new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(1234.5) // "1 234,50 €"
new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY' }).format(1000)   // "¥1,000"

// Compact notation — varies by language
new Intl.NumberFormat('en', { notation: 'compact' }).format(1500000)  // "1.5M"
new Intl.NumberFormat('de', { notation: 'compact' }).format(1500000)  // "1,5 Mio."
new Intl.NumberFormat('ja', { notation: 'compact' }).format(1500000)  // "150万"

// Percentage
new Intl.NumberFormat('fr-FR', { style: 'percent', minimumFractionDigits: 1 }).format(0.856) // "85,6 %"

// Accounting negatives (parenthesized)
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', currencySign: 'accounting' }).format(-100)
// "($100.00)"
```

### Locale-specific gotchas

| Locale | Decimal | Thousands | Currency |
|---|---|---|---|
| en-US | `.` | `,` | `$100.00` |
| de-DE | `,` | `.` | `100,00 €` |
| fr-FR | `,` | ` ` (thin space) | `100,00 €` |
| hi-IN | `.` | `,` (lakhs grouping: 12,34,567) | `₹12,34,567.89` |

### List formatting

```javascript
new Intl.ListFormat('en', { type: 'conjunction' }).format(['Alice', 'Bob', 'Carol'])
// "Alice, Bob, and Carol"

new Intl.ListFormat('de', { type: 'conjunction' }).format(['Alice', 'Bob', 'Carol'])
// "Alice, Bob und Carol"
```

---

## RTL (Right-to-Left) support

### Languages requiring RTL

Primary: Arabic (`ar`), Hebrew (`he`), Persian (`fa`), Urdu (`ur`). Also: Pashto, Dari, Kurdish (Sorani), Yiddish.

### CSS logical properties

Replace all physical properties with logical equivalents:

| Physical (don't use) | Logical (use this) |
|---|---|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `text-align: left` | `text-align: start` |
| `float: left` | `float: inline-start` |
| `left: 0` (positioning) | `inset-inline-start: 0` |
| `border-top-left-radius` | `border-start-start-radius` |

Vertical properties (`top`, `bottom`, `padding-top`, `padding-bottom`) stay physical — the block axis doesn't change in RTL.

### Tailwind CSS RTL

Tailwind v4 uses logical properties by default. In v3.3+:

| Physical | Logical | Meaning |
|---|---|---|
| `ml-4` | `ms-4` | margin-inline-start |
| `mr-4` | `me-4` | margin-inline-end |
| `pl-4` | `ps-4` | padding-inline-start |
| `text-left` | `text-start` | text-align: start |

For conditional styles: `rtl:space-x-reverse`, `rtl:-scale-x-100`.

Set `dir="rtl"` on the `<html>` element.

### Icon mirroring

**Icons that MUST mirror in RTL:** arrows (back, forward, next, previous), navigation chevrons, text-direction icons (indent, outdent), reply/forward, external link arrow, undo/redo, progress bars.

**Icons that must NOT mirror:** checkmarks, X/close, play/pause/stop (media controls), search, plus/minus, clock, lock, star/heart, globe, gear, upload/download (vertical).

Apply: `[dir="rtl"] .icon-mirror { transform: scaleX(-1); }` or Tailwind `rtl:-scale-x-100`.

### Dashboard layout in RTL

- Sidebar moves from left to right
- Breadcrumb trail starts from the right
- Table text alignment and cell padding swap
- Form label-input pairs flip
- Scrollbar moves to the left
- Charts: Y-axis may move to right; X-axis (time) still flows left-to-right

Use `dir="auto"` on user-generated content inputs so the browser detects direction from the first strong character.

### Testing RTL without knowing Arabic

1. Chrome DevTools: select `<html>`, add `dir="rtl"`. Instant layout flip.
2. Set your app to Hebrew (`he`) with English fallback — layout flips, strings stay readable.
3. Storybook: `@storybook/addon-rtl` adds a toolbar toggle.
4. Pseudo-RTL locale: transform English text with RTL Unicode markers.

---

## Translation workflow

### String extraction tools

| Library | Tool |
|---|---|
| i18next | `i18next-cli` (extraction, linting, syncing, type generation) |
| FormatJS | `@formatjs/cli extract` |
| Lingui | `lingui extract` |
| next-intl | No extraction needed — author keys in JSON directly |

### Translation management platforms

| Platform | Best for |
|---|---|
| **Crowdin** | Teams scaling to many locales, open-source, affordable |
| **Lokalise** | Engineering-led teams, best DX, CLI/API automation |
| **Phrase** | Enterprise with professional translators, TM, quality checks |
| **POEditor** | Small teams, budget-conscious |

**Workflow:**
1. Developer adds key in code and source JSON.
2. CI pushes source JSON to TMS (via GitHub integration or CLI).
3. Translators work in TMS with context screenshots, glossary, and translation memory.
4. Completed translations auto-merge back via PR.
5. CI validates no missing keys, runs pseudo-locale tests.

### Machine translation

Use DeepL or Google Translate as initial fill, then mark as "needs review." Translators edit rather than translate from scratch — 2-3x faster.

**Never ship machine-translated strings without human review** for: legal content, error messages, marketing copy, anything where tone matters.

### Glossary

Maintain a curated glossary of terms with approved translations:
- Product-specific terms (feature names, plan names)
- Technical terms that stay in English (API, webhook, endpoint)
- Status labels (Active, Inactive, Pending)
- Action verbs (Save, Delete, Archive, Export)

This prevents inconsistency — "Cancel" should always be "Annuler" in French, not sometimes "Abandonner."

### String change management

When the English source changes:
- **Key-based** (recommended): key stays the same, TMS shows diff to translator, marks translation as "fuzzy" (needs re-review). Old translation preserved until updated.
- **Content-based**: old string removed, new one created. All translations lost unless TM catches it.

This is the #1 reason key-based wins for production dashboards — you can fix a typo without invalidating 15 translations.

---

## Hard-to-internationalize content

### Images with text

Avoid text in images. Use SVG with translatable `<text>` elements, or overlay text with CSS. For screenshots, maintain locale-specific variants.

### PDFs and generated documents

- Use a PDF library that accepts locale parameters.
- Store the user's locale and generate in that locale.
- Invoices may require the *jurisdiction's* locale, not the user's UI locale.
- Embed fonts that support target scripts (Arabic, CJK, Devanagari).

### Email templates

- Render in the recipient's locale.
- Include timezone abbreviation in timestamps: "April 11, 2026 at 2:30 PM EDT".
- Translate subject lines.
- Test with German/Finnish — longer strings break fixed-width email layouts.

### Hardcoded units

Store measurements in a canonical unit (metric), convert for display based on locale or user preference:
- Temperature: Celsius (world) vs Fahrenheit (US)
- Distance: kilometers vs miles
- Chart axis labels: format with i18n number formatter + translatable unit labels

### Exported CSV/PDF locale

- Default to user's locale, with option to override.
- **CSV gotcha:** `1.234,56` (German) breaks Excel in US locale. Offer ISO format option (dot decimals, YYYY-MM-DD dates).
- Translate column headers. A German user expects "Vorname" not "First Name."
- Use ASCII-safe filenames.

---

## Dashboard-specific i18n

### Charts

- Pass the user's locale to your charting library.
- Use `Intl.NumberFormat` for Y-axis labels (locale-appropriate separators and compact notation).
- Use `Intl.DateTimeFormat` for X-axis date labels.
- RTL: chart data still flows left-to-right (time is universal), but axis labels and legend text format in RTL.

### Table headers and pagination

- All column headers must be translation keys, not hardcoded.
- "Showing 1-10 of 100 results" needs pluralization and number formatting.
- Sort direction labels: some languages sort differently (Swedish: a-z then å, ä, ö).

### Filter values

Some filter values are translatable (status labels), some are not (user-entered tags, CMS categories):

```typescript
// Status: translated
const label = t(`status.${status.toLowerCase()}`)

// Tags: displayed as-is from the database
// These are user data, not UI strings
```

### Status labels

- **UI layer:** translate for display. "Active" > "Aktiv" (German).
- **Database:** store English enum values (`ACTIVE`, `INACTIVE`). Never store translated values.
- **Mapping:** frontend maps enum to translation key.

### Audit log descriptions

Store the action *key* and *parameters*, not the rendered string. Render at display time in the viewer's locale:

```sql
action_key: 'audit.roleChanged'
params: '{"actor": "Alice", "target": "Bob", "oldRole": "viewer", "newRole": "admin"}'
```

Role names also need translation — store as keys, not literals.

### Sidebar navigation

- Keep labels short (1-2 words).
- Test with German/Finnish for text expansion.
- Tooltip on icon-only mode must also be translated.
- If using abbreviations, they differ per language — use separate translation keys for full and abbreviated forms.

---

## Testing i18n

### Pseudo-localization

Transform English to reveal i18n issues:

```
"Welcome back" > "[Ẃéĺçömé ẞäçk --------]"
```

Three effects:
1. **Accented characters** — tests UTF-8 encoding and font rendering.
2. **Padding** — adds ~30-40% characters to simulate German/Finnish length.
3. **Brackets** — wraps string so any hardcoded (non-extracted) text is visually obvious.

Add pseudo-locale as a dev environment option. Run visual regression tests against it.

### Text expansion testing

German: 20-35% longer. Finnish: 30-40% longer. Verify:
- Table columns don't overflow
- Buttons don't break containers
- Nav labels fit in sidebar (expanded and collapsed)
- Modal titles don't overflow
- Toast messages have room

Automate: run Playwright tests with the pseudo-expanded locale, assert no unexpected overflow.

### RTL testing

Toggle `dir="rtl"` and verify: sidebar flips, text reverses, correct icons mirror, charts render, tables are readable. Use pseudo-RTL locale or Storybook addon.

### Missing translation testing

- Dev: log warnings for missing keys.
- CI: compare all locale JSON files against source locale, fail if keys are missing.
- Test that fallback chain works: `de-AT` > `de` > `en`.

### Pluralization edge cases

Test these values for every pluralized string: 0, 1, 2, 5, 21, 100. Russian and Polish treat 21 as `one`, not `other`.

### Visual regression across locales

Screenshot the same page in `en`, `de`, `ar`, `ja` and compare against baselines. Focus on: dashboard overview, tables, forms, modals, empty states.

---

## Don'ts

- **Don't concatenate translated strings.** `t('hello') + ' ' + name` breaks in languages with different word order. Use interpolation.
- **Don't use the same key for different UI contexts.** "Status" as a column header and "Status" as a filter label may need different translations.
- **Don't hardcode date formats.** `MM/DD/YYYY` is only correct in the US. Use `Intl.DateTimeFormat`.
- **Don't hardcode number formats.** Decimal separator is `.` in US and `,` in Europe. Use `Intl.NumberFormat`.
- **Don't store translated strings in the database.** Store enum keys, translate at display time.
- **Don't use physical CSS properties** (`margin-left`) when you need RTL support. Use logical properties (`margin-inline-start`).
- **Don't bake text into images.** It can't be translated without image editing.
- **Don't ship machine translations without human review** for anything user-facing.
- **Don't store timestamps in local time.** UTC in the database, user's timezone for display.
- **Don't forget to translate:** error messages, empty states, toast messages, email subjects, PDF headers, CSV column names, chart tooltips, and sidebar labels. These are the most commonly missed.
- **Don't assume all users read left-to-right.** If you support Arabic, Hebrew, Persian, or Urdu, your entire layout must support RTL.
- **Don't retrofit i18n after building a monolingual dashboard.** The architecture decisions (key extraction, file structure, locale storage, CSS logical properties) must be made upfront. Adding them later touches every file.
