# Workflows & Actions

A dashboard's value is the actions you can take in it: creating things, editing things, deleting things, running operations, completing multi-step processes, exporting reports. This file is the rules for building these flows so they actually work end-to-end and feel competent.

## Forms

Forms are the most common interaction in a dashboard and the easiest to do badly. Every CRUD operation is a form. Settings are forms. Account changes are forms. Get them right and the dashboard feels solid.

### Form layout

- **One column.** Multi-column forms scatter the eye. The only exception is short paired fields (first name + last name on one row).
- **Labels above fields, not beside them.** Easier to scan, works on mobile, accommodates long labels.
- **Group related fields into sections** with subtle headings. "Basics," "Plan & billing," "Notification preferences." Even a 10-field form benefits from 2–3 sections.
- **Generous spacing between fields** — 16–24px. Cramped forms feel hostile.
- **Sticky footer with primary action** for forms that scroll. The Save button must always be reachable without scrolling.
- **Cancel + Save** in the footer. Cancel on the left, primary action on the right (or per your locale convention).
- **Width** — forms read best at 480–640px. Don't stretch to fill the page.

### Field anatomy

```
Label *                              ← required marker if applicable
Help text in subtle color            ← optional, above the field
[__________________________]         ← the input
Validation error in red              ← only when invalid
```

- **Label** — short, descriptive, sentence case. "Email address," not "EMAIL_ADDRESS" or "Your Email Address Here:"
- **Required marker** — a small `*` after the label. Or, conversely, mark optional fields with "(optional)" — pick one and stay consistent. The "(optional)" approach is friendlier when most fields are required.
- **Help text** — when the field needs explanation, show it above the field, not as a tooltip. Tooltips hide critical info.
- **Placeholder** — only for format hints, never as a substitute for label. "you@example.com" is fine; "Enter your email" instead of a label is not.
- **Validation error** — below the field, in the danger color, with an icon. Replaces help text temporarily.

### Input types — use the right one

The HTML standard has many input types. Most dashboards use ~3. Use them all:

| Use | Type / control |
|---|---|
| Email | `type="email"` |
| Password | `type="password"` (with "show password" toggle) |
| Phone | `type="tel"` |
| Number | `type="number"` (with `min`, `max`, `step`) |
| Date | A date picker library, not the native control |
| Time | Same — use a library |
| Date range | A range picker |
| URL | `type="url"` |
| Long text | `<textarea>` with auto-resize |
| Single choice from few options | Radio group (for ≤5) or select |
| Single choice from many options | Searchable select (combobox) |
| Multiple choices | Checkbox group (for ≤5) or multi-select |
| Boolean | Toggle (for settings) or checkbox (for "I agree") |
| Tags / chips | Tag input |
| File upload | Drag-and-drop area + click-to-browse |
| Rich text | An RTE library (Tiptap, Lexical, ProseMirror, Slate, Quill) |
| Code | A code editor (Monaco, CodeMirror) |
| Color | Color picker library |

Native date/time pickers are inconsistent across browsers and locales — use a library (react-day-picker, react-aria, vaul, melt-ui, etc.).

### Validation timing

Three moments to validate:

1. **On blur** — when the user leaves a field. Shows errors as the user moves through the form.
2. **On submit** — final check, also catches fields they skipped.
3. **On server response** — the server is the source of truth. Display field-level errors next to the relevant fields.

Don't validate on every keystroke (annoying). Don't only validate on submit (the user fills the whole form before learning the first field was wrong).

Use a schema validation library:
- **TypeScript** — Zod (recommended), Valibot, ArkType, Yup, Joi
- **Python** — Pydantic
- **Ruby** — dry-validation, ActiveModel
- **PHP** — Laravel validators, Symfony Validator
- **Java** — Bean Validation (JSR 380)

Schema validation gives you one source of truth that runs on both client and server (in TS) or on the server only (otherwise). Don't write validation logic twice.

### Submit button states

```
[Save Changes]              ← idle, enabled
[Save Changes] (gray)       ← idle but form invalid
[Saving...] (disabled)      ← in flight
[✓ Saved] (briefly)         ← success
[Save Changes]              ← back to idle
```

Disable the button while in-flight to prevent double submits. Disable until the form is valid (or always enable but show errors on click — pick one and stay consistent). Show a spinner inside the button, not somewhere else.

### Auto-save patterns

For long forms or settings the user is exploring, auto-save reduces anxiety:

- Debounce 500–1000ms after the last change
- Show a small indicator: "Saved" / "Saving..." / "Failed to save — retry"
- Never auto-save invalid data — wait until validation passes
- For complex forms, save as a draft (not the live record) and require explicit "Publish" to commit

## Onboarding / first-time user experience

The first 5 minutes after login determine whether a user becomes active or churns. Onboarding is the guided path from first login to first value — the moment the user does something real with the dashboard. Empty states (covered in `states-and-feedback.md`) handle what the user sees on each empty page. This section covers the orchestrated flow that gets them to a productive state.

### The onboarding sequence

A good onboarding flow has 3-5 steps, takes under 3 minutes, and ends with the user seeing real value (their first data, their first completed action).

```
Welcome screen (who are you, what's your goal)
  > Guided setup (configure the essentials)
  > First action (create the first real thing)
  > Success moment (show what they just accomplished)
  > Dashboard home (with the data they just created)
```

### Welcome screen

Shown on first login only. Keep it brief:
- Greeting with the user's name (from the signup/invite).
- One sentence about what the dashboard helps them do.
- A primary CTA: "Let's get started" or "Set up your workspace."
- Optional "Skip setup" link for power users who want to explore on their own.

Don't: show a video, show a wall of text, ask 10 questions before showing the product.

### Guided setup (the essential configuration)

Collect only what's needed to make the dashboard useful. Everything else can be configured later in settings.

**For a SaaS admin:** org name, invite 1-2 team members (or skip), choose a plan (or start trial).

**For a CRM:** import contacts (CSV upload or skip), connect email (OAuth to Gmail/Outlook or skip), create the first deal.

**For a project tool:** create the first project, name it, add 2-3 tasks.

**For an analytics dashboard:** connect the data source, verify data is flowing, see the first chart.

Rules:
- **3-5 steps maximum.** Each step has one clear action.
- **Every step is skippable** except the one that creates the minimum viable data (you can't show an empty dashboard and call it onboarded).
- **Show progress** — step indicator at the top ("Step 2 of 4").
- **Persist state** — if the user closes the tab and comes back, resume where they left off.
- **Pre-fill where possible** — if they signed up with a Google account, pre-fill name and email. If the domain is `@acme.com`, suggest "Acme" as the org name.

### First value moment

The setup must end with the user seeing something real — not an empty dashboard. Strategies:

- **Seed sample data** if the user skips data entry. Show 3-5 example records with a banner: "These are sample records to show you around. Delete them anytime." Better than nothing.
- **Import existing data** as part of setup (CSV upload, connect an existing tool). The user sees their own data immediately.
- **Create one real record** as the final setup step. "Create your first project" → the user lands on their project page with the project they just named.

### Post-onboarding guidance

After the initial setup, the dashboard is no longer empty but the user doesn't know where everything is. Two patterns:

**Checklist (recommended):** A persistent card on the dashboard home showing 5-7 tasks that gradually introduce features. Each task links to the relevant page with context. Tasks check off as completed. The checklist disappears (or collapses) when all tasks are done.

```
Getting started                           3 of 6 complete
  ✓ Create your first project
  ✓ Invite a team member
  ✓ Connect your email
  ○ Set up your first automation
  ○ Customize your dashboard
  ○ Explore reports
```

Rules:
- The checklist is **dismissible** — "Hide this" link. Don't force it.
- Each item is a **link** to the relevant page, not just a label.
- **Celebrate completion** — when all items are done, show a brief congratulations, then remove the checklist permanently.
- **Track completion** server-side, not just in localStorage (survives device switches).

**Guided tour (use sparingly):** Tooltip-based walkthrough highlighting UI elements. Libraries: Driver.js, Shepherd.js, Intro.js. Keep it to 4-5 steps max. Let the user dismiss at any time. **Never replay on subsequent logins.** A guided tour shown twice is hostile.

### What NOT to do during onboarding

- **Don't show a modal on every page** explaining what the page does. One tooltip tour (once) is enough.
- **Don't block the product behind onboarding.** Users should be able to skip and explore freely.
- **Don't ask questions you can infer.** If they're on a Pro trial, don't ask "What plan are you on?"
- **Don't collect information that isn't needed yet.** Billing details can wait until trial ends. Notification preferences can wait until there are notifications.
- **Don't treat returning users as new users.** The onboarding state is a flag on the user record (`onboarding_completed_at`). Check it on every login.
- **Don't build onboarding as a separate app.** It's a state of the main dashboard — same layout, same nav, just with guided elements and empty state handling.

### Invite-based onboarding (team members)

When a user is invited (not self-signup), the onboarding is different:
- They already have an org and team context.
- Skip org setup entirely.
- Show: set name/password (if invite-based auth), profile photo (optional), then land on the dashboard with their team's data already visible.
- The checklist can be shorter: "Complete your profile, explore the dashboard, create your first [entity]."

### Role-based onboarding paths

Different roles need different onboarding:

**Admin/creator** (full onboarding): workspace name, branding, invite members, connect integrations, configure settings. This is the standard flow above.

**Member (invited)**: abbreviated. Accept invite, set profile, learn the workspace that already exists. Show "Here's what your team has set up" — not "Let's set things up." Skip org setup entirely. The workspace already has data, channels, or projects visible.

**Viewer/guest**: minimal or zero onboarding. Read-only access. A single tooltip: "You have view access to this workspace." Don't show creation tutorials.

**Permission-aware checklist**: filter checklist items by role. Don't show "Connect email integration" to a viewer. Don't show "Configure billing" to a member.

### Template / quickstart gallery

Instead of starting from scratch, offer starter templates during onboarding (after welcome, before dashboard):

**Two types:**
- **Data templates** — pre-seeded records (sample contacts, projects, invoices). The user deletes or modifies them. Think Trello's "Welcome Board."
- **Structural templates** — create entities, custom fields, views, and workflows. When a user selects "Project Management," the template creates databases with specific properties, Kanban/Timeline views, and sample pages. More complex to implement.

**UI:** Show 3-6 templates with name, one-line description, preview icon. "Use this template" or "Start from scratch." Allow switching or clearing template data later.

**Implementation:** templates are JSON fixtures or seed scripts run against the user's workspace. Structural templates need a definition format describing: which entities to create, which fields to add, which views to configure, which sample records to insert.

### Onboarding email sequence

The emails sent in the first 7-14 days, tied to in-app onboarding state:

| Day | Email | Trigger |
|---|---|---|
| 0 | Welcome (confirm signup, link to get started) | Immediate on signup |
| 1 | "Getting started" — one specific action with deep link | Time-based |
| 3 | Feature highlight — one feature they haven't used yet | Behavioral (based on in-app state) |
| 5-7 | Social proof / case study | Time-based |
| 7 | "You haven't done X yet" nudge | Behavioral (only if they haven't) |
| 10-12 | Trial expiry warning (if applicable) | Time-based |
| 14 | Final nudge or upgrade prompt | Time-based |

**Key principles:**
- Send from a real person's name, not "noreply@." Real-person emails achieve 68% open rate vs ~25% for branded emails.
- Behavioral triggers outperform time-based. "You ingested data but haven't created a dashboard" beats "It's day 3."
- Every email has exactly one CTA that deep-links to the specific in-app location.
- The email system checks onboarding state before sending. If the user already completed the action, don't send the nudge.
- Expect to iterate through 5-10 versions of the flow.

**Benchmarks:** open rate goal >40%, CTR goal >4%, unsubscribe <1%.

### Progressive disclosure (post-onboarding feature discovery)

Initial onboarding covers 3-5 features. A dashboard with 15+ features needs a long-tail discovery strategy for weeks 2-4:

**Contextual first-visit tooltips:** show a tooltip the first time a user visits a specific page or encounters a feature — not during initial onboarding, but days later. Dismissible, never replay, never block interaction.

**Behavioral triggers for education:** when a user manually does something 3+ times that could be automated, show a tooltip about the automation. When they create their 10th record, suggest bulk operations. Trigger on behavior, not time.

**Feature announcements (layered):**
- **Major feature:** one-time modal on first login after release (max 1/month).
- **Medium improvement:** inline banner on the relevant page.
- **Minor change:** changelog entry only.

Track which educational moments have been shown/dismissed per user in a `user_feature_discovery` table.

**In-product learning center:** a persistent "Learn" or "?" section in the nav with getting-started guides, feature tutorials, and documentation links. Replaces the need to introduce every feature during onboarding.

### Re-engagement (returning after absence)

When a dormant user returns (30+ days inactive):

- Do NOT restart onboarding or show the welcome screen.
- If onboarding was incomplete, show the checklist in its previous state (completed items still checked).
- Show a subtle "Welcome back" banner (not modal) with what's changed: "3 new features since your last visit" with changelog link.
- If teammates were active: "Your team has been busy — 12 new projects were created."
- Track `last_seen_at` on the user record. When >30 days ago, set a `returning_user` session flag.

### Activation metrics

Onboarding completion is not activation. Activation is the specific behavior that predicts long-term retention — the "aha moment":

- Slack: team sends 2,000 messages (93% retention after threshold)
- Dropbox: 1 file in 1 folder on 1 device
- PostHog: events ingested + 1 insight created + 1 dashboard created

**How to find your activation metric:** compare users who retained at 90 days vs. those who churned. Find the action that differs. Your onboarding flow should be reverse-engineered from this metric.

**Benchmarks:** activation rate <20% = major problem, 20-40% = typical, 40-60% = good, >60% = excellent.

For B2B dashboards, measure activation at the org/team level, not individual. Anyone in the org performing the action counts.

### Onboarding state data model

All onboarding state is server-side (survives device switches):

```sql
user_onboarding
  user_id                UUID PRIMARY KEY
  current_step           VARCHAR(50)
  completed_at           TIMESTAMPTZ     -- null until finished
  skipped_at             TIMESTAMPTZ     -- null unless skipped
  checklist_state        JSONB           -- per-item completion + timestamps

user_feature_discovery
  user_id                UUID
  feature_key            VARCHAR(100)    -- 'bulk_export', 'api_keys'
  first_shown_at         TIMESTAMPTZ
  dismissed_at           TIMESTAMPTZ
  interacted_at          TIMESTAMPTZ     -- when user actually used the feature

user_announcements
  user_id                UUID
  announcement_id        UUID
  seen_at                TIMESTAMPTZ
  dismissed_at           TIMESTAMPTZ
```

**Key implementation rule:** the checklist should observe actual application state, not just track clicks. If a user creates a project through the normal UI (not the checklist link), the "Create first project" item auto-completes. Query real data (`SELECT COUNT(*) FROM projects WHERE org_id = ?`) rather than checking a boolean flag.

Provide an admin API to reset onboarding state for testing and customer support.

### Onboarding analytics

Track the funnel:
- `onboarding.started` — user hit the welcome screen
- `onboarding.step_completed` — per step, with step name
- `onboarding.skipped` — user clicked "Skip setup"
- `onboarding.completed` — user finished all steps
- `checklist.item_completed` — per checklist item
- `checklist.dismissed` — user hid the checklist
- `activation.reached` — user hit the activation metric threshold

Measure: completion rate (what % finish all steps), drop-off per step (which step loses users), time to first value (signup to first real action), activation rate (what % reach the aha moment), email sequence performance (open rate, CTR per email).

## Multi-step flows (wizards)

Some operations are too big for one form: onboarding, multi-page checkout, complex setup, data imports. Use a wizard.

### Wizard rules

- **Show progress** — a step indicator at the top. "Step 2 of 4: Plan selection." A linear progress bar or a numbered tab strip.
- **Each step is self-contained** — the user can complete the current step without thinking about future steps.
- **Allow going back** without losing data from earlier steps.
- **Validate per step** before allowing "Next."
- **Persist state across reloads** — save partial state to the server (preferred) or localStorage. The user expects to come back tomorrow and continue.
- **Allow saving as a draft and resuming.**
- **The last step is a confirmation** — show the summary of what's about to happen before the final commit.
- **After commit, redirect to the result** — never leave the user staring at the wizard's final step.

### When *not* to use a wizard

- The user only does this once. (A linear page works.)
- The user does this often. (A wizard is friction; a single power form is faster.)
- The steps could be reordered or skipped. (A non-linear form is more honest.)

## Tables, bulk actions, and inline editing

### Bulk actions

When the user needs to do something to many rows at once:

```
☑ 12 of 1,247 selected   [Assign...] [Tag...] [Export] [Delete]
```

Rules:
- **A toolbar appears above (or replaces) the filter bar** when 1+ rows are selected.
- **Show the count** of selected items.
- **Show the actions** as buttons or a "Bulk actions" menu for many actions.
- **"Select all" inside the toolbar** with two modes: "All on this page" (default) and "All matching filter (1,247)" — both are useful.
- **Destructive bulk actions** require confirmation with the affected count: "Delete 12 customers?"
- **For destructive actions on many rows**, require typing a confirmation word: "Type DELETE to confirm."
- **Provide undo** when feasible — even bulk delete can soft-delete with a 30-second undo window.

### Inline editing

Some tables benefit from editing in place — settings tables, simple data grids, spreadsheet-like surfaces.

- **Click to edit** (single click for power users, double click for safer). Make the editable affordance visible — pencil icon on hover, or always-visible cell border.
- **Save on blur or Enter.** Cancel on Esc.
- **Show pending state** while saving — a small spinner in the cell or row.
- **Field-level errors** displayed below the cell.
- **Undo via Ctrl+Z** is too much for most apps; offer "undo" toast after each save.

Inline editing is great for power tables but bad for primary data entry. Most CRUD should still use a dedicated form page or drawer.

## Side drawers (sheets)

A side drawer slides in from the right (or left) and overlays the page without leaving it. Excellent for:

- Editing a row from a list without losing the list context
- Detail views that don't justify a full page
- Filter panels with many filters
- Activity / history panels

Rules:
- **Slide in from the side** (right is conventional)
- **Overlay covers the page** but the page underneath is dimmed but visible
- **Esc closes** the drawer
- **Click outside closes** (with confirmation if dirty)
- **Width** — 400–600px for forms, 720+ for detail views
- **Sticky header with title and close button**
- **Sticky footer with actions**
- **Don't open a drawer over another drawer.** One layer max.

Drawers are better than modals for forms with > 4 fields. Modals trap the user in a small box; drawers feel like an extension of the page.

## Modals

Modals are an interruption. Use them for:

- Confirmations (delete, irreversible actions)
- Quick choices ("Pick a project to copy this to")
- Brief announcements that block ("Your trial ends tomorrow")
- Short forms (≤4 fields)

Don't use modals for:
- Long forms — use a drawer or a page
- Multi-step flows — use a wizard page
- Anything the user might want to refer to while interacting with the page below
- Notifications that don't block — use a toast

### Modal rules

- **Centered, with a backdrop**
- **Esc closes**
- **Click outside closes** (or doesn't, if there's a confirmation button — be consistent)
- **Tab focus is trapped** inside the modal
- **First focusable element receives focus** on open (usually the cancel button for destructive modals, the input for form modals)
- **Focus returns** to the trigger element on close
- **Close button (X) in the top-right corner**
- **Title in the top-left**
- **Content in the body**
- **Action buttons in the footer**, primary on the right
- **Don't open modals from modals.** Two layers max, and only when necessary.

## Search

Three kinds of search live in dashboards:

1. **Global search** — `⌘K` command palette across everything
2. **Page search** — search inside a single list/table
3. **Filter search** — typeahead inside a select dropdown

### Global search (command palette)

The pattern from Linear, Notion, Slack, Vercel, Stripe. Open with `⌘K` (Mac) / `Ctrl+K` (other). Shows recent items and lets you type to search across everything: pages, records, settings, actions.

Build it when the dashboard has > 50 navigable destinations or > 100 records the user might look up.

**Implementation:** Use `cmdk` (React) or `kbar` (React) as the foundation. Key patterns:

- **Action registration** — each page/feature registers its own actions. The palette aggregates them.
- **Async search** — for records (customers, orders), search the server with debounce. Show recent items while results load.
- **Nested commands** — select a project, then select an action on it ("Open" / "Edit" / "Archive").
- **Recent items** — show the last 5-10 visited pages when the palette opens with no query.
- **Action mode** — `>` prefix shows actions ("Export," "Invite user"), not navigation.
- **Feedback** — when an action executes, close the palette and show a toast. If it fails, keep the palette open with an error.

Rules:
- **Fuzzy match** — match words out of order, ignore minor typos
- **Group results by type** — Pages, Customers, Orders, Actions
- **Show recent items when empty** — recently visited pages and records
- **Keyboard-only navigation** — arrows to move, Enter to select, Esc to close
- **Action mode** — `>` prefix shows actions ("> Export," "> Invite user") not just navigation. The Linear pattern.

### Page search

A search input above a table, narrows the rows shown. Debounce 250–400ms. Use server-side search for tables > 500 rows; client-side filtering is fine below.

### Filter typeaheads

Inside a select with > 10 options, add a search input at the top. Esc closes. Arrow keys navigate. Enter selects.

## Drag-and-drop

Three use cases in dashboards:

1. **Kanban boards** — drag cards between columns (status changes). The drop triggers a mutation.
2. **List reordering** — drag to reorder items in a priority list. Save the new order immediately or on explicit save.
3. **File organization** — drag files into folders.

**Libraries:** `dnd-kit` (React, modular, accessible), `pragmatic-drag-and-drop` (Atlassian, headless, framework-agnostic), `@hello-pangea/dnd` (fork of react-beautiful-dnd, list-focused).

**UX pattern:** idle > hover (show grab cursor) > grab (element lifts, placeholder appears) > move (element follows cursor, drop zones highlight) > drop (element settles, mutation fires). Show a loading indicator on the dropped item if the mutation is async.

**Accessibility:** drag-and-drop must have a keyboard alternative. Provide "Move up" / "Move down" buttons or a "Move to..." menu as a non-drag fallback.

## Approval workflows

Multi-step approval routing for procurement, expenses, content publishing, or HR requests:

1. User submits a request.
2. Request routes to their manager (based on org hierarchy or configured routing rules).
3. Manager approves or rejects (with comments).
4. If approved, routes to next approver (finance, legal, etc.).
5. Final approval triggers execution (payment, publication, access grant).

The request is a state machine: `draft > pending_manager > pending_finance > approved > executed` (or `rejected` at any step). Each transition logs who, when, and any comments. Show the approval chain visually with current status highlighted.

## Collaborative editing

When multiple users can edit the same record simultaneously:

- **Presence indicators** — "Alice is also editing this record" with avatar badge.
- **Live cursors** — show where others are editing (for rich text / spreadsheet surfaces).
- **Conflict resolution** — optimistic locking (version field) for form-based editing. CRDTs (Yjs, Automerge) for real-time collaborative text.
- **Tools:** Liveblocks (managed, easiest), Yjs + a provider (self-hosted), Convex (built-in reactivity).

Build this only when the use case demands it. Most CRUD dashboards don't need real-time collaboration — optimistic locking (covered in `data-layer.md`) is sufficient.

## Conditional form fields

Fields that appear/disappear based on other selections:

- Selecting "Payment method: Credit card" reveals card fields; "Bank transfer" reveals bank fields.
- **Preserve values** of hidden fields (don't clear on hide) — the user may toggle back.
- **Validate only visible fields** — hidden fields should not block submission.
- **Animate show/hide** with a brief height transition (150ms).

## Filtering and saved views

Filter bars belong above the table. The pattern:

```
[Search]  [Status ▾]  [Owner ▾]  [Date ▾]  [+ Filter]    [Reset]  [Save view ▾]
```

Each dropdown shows the available filter options. Active filters appear as removable chips below or as colored dropdown buttons.

### Saved views

Power users with consistent workflows ("show me overdue invoices for my accounts") want to save filter combinations as named views. The pattern from Linear, Asana, GitHub Issues:

- After applying filters, "Save view" prompts for a name
- Saved views appear in a dropdown next to the filter bar
- Each user has their own; some can be shared with the org
- The current view is reflected in the URL
- "Default" view is built-in and can't be deleted

Saved views are a 10x quality-of-life improvement for power-user dashboards. Build them once you have basic filtering working.

## Imports

Many dashboards need to import CSV/XLSX files. Build the import flow as a first-class feature, not an afterthought.

### The import flow

1. **Upload step** — drag-and-drop area + browse button. Accept CSV, XLSX. Show file size limits up front.
2. **Preview step** — parse the first 50 rows and show a table. The user confirms the data looks right.
3. **Mapping step** — map source columns to target fields. Auto-detect by header names. Let the user override.
4. **Validation step** — server-side validation of all rows. Show a summary: "1,247 rows valid. 12 have errors." For errored rows, show the row number, the column, and the error. Let the user download the error report or fix it inline.
5. **Confirm step** — "Import 1,235 customers? 12 will be skipped." Accept.
6. **Background job** — for imports > 100 rows, kick off a background job. Show a progress page that polls the job status. Don't make the user wait on a request thread.
7. **Result page** — "Imported 1,235 customers. 12 skipped." Link to the new records.

Key rules:
- **Validate everything before committing.** Don't import 800 rows successfully and then fail on row 801, leaving the database in a half-state. Use a transaction.
- **Provide a sample file** the user can download to see the expected format.
- **Match columns by header name**, not by position. Be tolerant of column order.
- **Skip empty rows.**
- **Trim whitespace.** Be lenient with input.
- **Preserve the original file** for audit until the import is committed.

## Exports

Almost every dashboard needs export. Build them right:

- **Match the on-screen view.** Export reflects the user's current filters. Not "all data ever."
- **CSV is the default.** Excel (XLSX) is a feature flag, not the default.
- **For < 10k rows** — generate on demand, stream the response. The browser's download manager handles it.
- **For larger** — kick off a background job, email a download link or show a notification when ready.
- **Format properly** — currency as numbers (not strings), dates in ISO or a documented format, no smart quotes, BOM for UTF-8 if Excel users will open it on Windows.
- **Include a header row** with field names.
- **Include a metadata row** at the top, optional: "Exported by alice@acme.com on 2026-04-11 at 14:32 UTC. Filters: status=active, owner=Alice."
- **Document the limit** if there is one. "Export limited to 50,000 rows."

### Scheduled / recurring exports

Some dashboards need "email me this report every Monday." The pattern:

- A "Schedule export" button next to the export button
- Set frequency (daily, weekly, monthly), time, day, recipients, format
- Manage scheduled exports from a settings page
- Each scheduled run logs to the audit trail

This is a full feature with its own backend. Don't fake it.

## Background jobs and long-running operations

Any operation longer than ~5 seconds should be a background job:

- Imports
- Exports beyond a few thousand rows
- Email blasts
- Data migrations
- Report generation
- Bulk operations on > 100 records

### Job UI patterns

- **Initiate**: the user clicks the action. The server creates a job, returns a job ID, and the UI navigates to a status page or shows a status panel.
- **Status**: the UI polls the job (or subscribes via WebSocket). Show progress: "Processing 247 of 1,247 records (20%)." Show ETA when possible.
- **Cancel**: a cancel button when feasible. Server marks the job for cancellation; the worker checks periodically and stops gracefully.
- **Result**: when complete, show what happened, what failed, and what to do next. Link to the affected resources.
- **Notification**: send a notification (in-app and/or email) when long jobs complete so the user doesn't have to babysit.

The "fire and forget" pattern (kick off a job, navigate away, never see results) is hostile. Always close the loop.

## Confirmations and undo

For destructive actions, prefer **undo over confirm** when possible.

- **Confirm** asks the user "are you sure?" before they act. They must decide twice. Slow.
- **Undo** lets the action happen instantly and provides a brief window to reverse it. Fast and forgiving.

The Gmail / Linear pattern: delete an email, see a toast "Deleted. Undo." for ~6 seconds. Click "Undo" to restore.

Undo works when:
- The action is reversible (soft-delete, archive, status changes)
- The reversal is fast (no async cascading effects)
- The user is likely to notice within the undo window

Use confirm when:
- The action is irreversible (hard delete, key revocation, payment)
- The action has cascading consequences the user must understand
- The user is likely to be on autopilot

Combining both is fine: undo for the common path, confirm for the bulk path. "Delete 1 customer" → undo. "Delete 47 customers" → confirm with type-to-delete.

## Keyboard shortcuts

Power users live in dashboards. Keyboard shortcuts make them faster.

The conventional set:

| Shortcut | Action |
|---|---|
| `⌘K` / `Ctrl+K` | Open command palette |
| `⌘/` / `Ctrl+/` | Show keyboard shortcuts cheat sheet |
| `g` then `d` | Go to Dashboard |
| `g` then `c` | Go to Customers |
| `c` | Create new (context-aware) |
| `e` | Edit current item |
| `/` | Focus search |
| `?` | Show shortcuts |
| `Esc` | Close modal/drawer/menu |
| `j` / `k` | Move down / up in list |
| `Enter` | Open selected item |
| `Shift+Enter` | Open selected item in new tab |

Provide a shortcuts cheat sheet (`?` opens it) so users can discover them. Don't hide shortcuts; expose them.

## Don'ts

- **Don't use placeholder text as a label.** The placeholder vanishes when the user types and they forget what the field is for.
- **Don't validate only on submit.** Tell the user the email is wrong before they click Save.
- **Don't show validation errors before the user has touched the field.** Initial empty state isn't an error.
- **Don't reset the form on submission failure.** The user wants to correct, not retype.
- **Don't open a modal from another modal.** One layer.
- **Don't use modals for forms longer than ~4 fields.** Use a drawer or a page.
- **Don't put the primary action on the left.** Right side, primary on the right.
- **Don't make destructive actions look the same as safe actions.** Red for destructive, distinct from primary.
- **Don't use the browser `confirm()` or `alert()`.** Real dialogs.
- **Don't autoplay focus into the first input on a form** if it's a settings page (the user wants to scan first). Do autofocus on a "Sign in" form.
- **Don't trigger destructive actions on Enter** in confirmation dialogs. The default focus must be on Cancel, or the destructive button must be tabbed to.
- **Don't lose user data on validation error.** Preserve every field.
- **Don't lose draft data on accidental navigation.** Save drafts.
- **Don't ship a dashboard without keyboard shortcuts** if users will be in it daily.
- **Don't ship a dashboard without bulk actions** if users will manage > 50 records.
- **Don't make the user wait on requests > 5 seconds.** Background job, show progress.
