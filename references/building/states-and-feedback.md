# States & Feedback

A dashboard is in one of four states for any async surface: **loading, empty, error, or loaded**. Forgetting any of them produces a hollow-feeling product. Building all four is what separates a real dashboard from a scaffold.

Plus the feedback loop: every user action gets visible acknowledgment. If you click a button and nothing happens, the dashboard feels broken — even if the action succeeded server-side.

**Canonical scope:** loading, empty, error, and loaded states; toasts; undo; offline indicators; inline error messages. **See also:** `ui-design-patterns.md` for component tokens and styling, `error-pages-and-offline.md` for full-page 404/500/offline surfaces.

## The four states rule

Every page, panel, table, chart, or widget that loads data asynchronously needs all four states. Build them as a habit, not an afterthought.

```
┌─────────────────┐
│   LOADING       │ ← while the request is in flight
└─────────────────┘
        │
        ▼
   request done
        │
   ┌────┴────┬─────────┐
   │         │         │
   ▼         ▼         ▼
EMPTY   LOADED      ERROR
(0 rows) (data)    (failure)
```

If any of these is missing, the user sees a confusing in-between (a blank screen, a flash of "no data" before the data arrives, an unhandled exception). Quality dashboards never have these gaps.

## Progressive loading with Suspense

The four-states model assumes data arrives all at once. With React Suspense + streaming SSR (Next.js App Router, React 19), data arrives in sections:

1. The page shell renders immediately (header, sidebar, page title).
2. Each data section is wrapped in `<Suspense fallback={<Skeleton />}>`.
3. As each section's data resolves, it replaces its skeleton independently.
4. Slow sections don't block fast ones.

This is the modern default for Next.js dashboards. The skeleton is no longer a whole-page state — it's a per-section state. Design skeletons per component, not per page.

## Loading states

A loading state tells the user "I heard you, I'm working on it." Without one, the user doesn't know if their click registered.

### Skeleton vs. spinner — pick by duration

- **< 200ms** — show nothing. The eye doesn't notice and a loading flash is more distracting than useful.
- **200–1000ms** — a subtle inline spinner or a thin progress bar at the top of the page (NProgress style). Don't tear down the existing content.
- **> 1000ms or first load** — a skeleton that matches the eventual layout. Same shape, same dimensions, gray placeholder rectangles.

**Skeletons beat spinners for most dashboard work** because they show the structure of what's coming and prevent layout shift when content arrives. A page that boots into a centered spinner and then jumps into a complex layout feels worse than a page that boots into a skeleton of the same layout and progressively fills in.

### Skeleton rules

- **Match the actual final layout.** The skeleton for a table has the same number of columns. The skeleton for a card grid has the same number of cards.
- **Use a subtle shimmer animation** — a gradient sliding across the gray rectangles every ~1.5s. Not a fast pulse. Not a spinning element. Subtle.
- **Don't show real data behind the skeleton.** Pick one or the other.
- **Don't skeleton the page header.** The title and primary action are known immediately; render them. Skeleton only the data-driven content.

### Background refetches

When data is being refreshed (cached data is stale, the user clicked refresh, polling fired) — show the existing data with a small indicator (a spinning icon next to the page title, a thin progress bar at the top, or `isFetching` styling on the affected component). Do not tear down the page and show a skeleton. The user already has the old data; they want the new data, not nothing.

## Empty states

The empty state is the page when there are zero rows. It's the most overlooked surface in dashboards and one of the most important. A new user sees the empty state first.

### What an empty state must contain

1. **A short title** explaining what would normally appear here. "No customers yet."
2. **A short body** explaining why it's empty and what to do. "Customers will appear here after they sign up. You can also invite one manually."
3. **A primary action button** to do the obvious next step. "Invite customer."
4. **A secondary action**, optional. "Import from CSV" or "Read the docs."
5. **An optional illustration** — a small, simple icon or illustration. Not a full-color marketing splash.

### Empty state variants

- **Empty because nothing has been created yet** (the new-user case) — guide them to create the first one.
- **Empty because filters returned no results** — different copy. "No customers match your filters." Action: "Reset filters." This is the most-forgotten variant.
- **Empty because of a permission boundary** — "You don't have access to view customers in this organization."
- **Empty because the action genuinely has no entries** (e.g., audit log right after install) — "Nothing has happened here yet. Activity will appear as your team uses the app."

Render the right one based on context. Showing "create your first customer" when the user has 50 customers but a filter that excluded them all makes the user think their data is gone.

### Empty state copy rules

- **Specific** — "No customers yet" not "No data."
- **Active** — "Invite a customer" not "You can invite customers."
- **Honest** — don't use cute jokes for serious tools. The user is at work.

## Error states

Errors happen. Quality dashboards make them recoverable instead of dead-end.

### Error categories

| Cause | What to show | What to do |
|---|---|---|
| Network offline | "You appear to be offline." | Retry button, auto-retry when online |
| Server 5xx | "Something went wrong on our end." | Retry button, log to error tracker |
| Auth 401 | (no message; redirect) | Redirect to login with `next` |
| Auth 403 | "You don't have permission to view this." | Link to support, link to dashboard home |
| Not found 404 | "We couldn't find that customer." | Link back to the list |
| Validation 4xx | Field-level errors next to form fields | User corrects and resubmits |
| Conflict 409 | "This was modified by someone else." | Refresh button |
| Rate limit 429 | "Too many requests. Please wait a moment." | Show retry-after countdown |

Notice that each error has different copy and different actions. **Don't show the same generic "Error" toast for every failure** — that's the hollow-feeling pattern.

### Error UI placement

- **Field-level errors** — inline next to the field, in red, with an icon. Critical for forms.
- **Section-level errors** — when one part of the page failed but the rest is fine. Render an inline error block in that section with a retry button. The rest of the page keeps working.
- **Page-level errors** — when the whole page failed to load. A centered error state with the message and a retry button.
- **Global toast** — for transient errors during mutations on otherwise-loaded pages. "Couldn't save, please try again." Auto-dismiss after 5–8 seconds for non-critical.
- **Persistent banner** — for errors the user must address. Expired session, payment failed, etc. Doesn't auto-dismiss.

### Don't expose stack traces

Never show stack traces, raw exception messages, library names, or version numbers in error UIs visible to users. Send those to your error tracker (Sentry, Bugsnag, Rollbar, Datadog) and show the user a friendly message. Stack traces in production are an information leak.

### Retry button rules

- The button text says "Try again" or "Retry," not "Reload page."
- Clicking retries only the failed request, not the whole page (preserves user's state).
- After retry, show the loading state again.
- After 3 failed retries, change the message to "Still failing — please contact support" with a link.

## Success feedback

Every user action that mutates state needs visible confirmation. Without it, the user doesn't trust that the action succeeded — even when it did.

### The feedback patterns, ranked by stakes

1. **Optimistic update + no toast** — the change appears instantly in the UI; no extra confirmation needed. Use for low-stakes toggles, drag-to-reorder, simple field edits.
2. **Inline confirmation** — the field shows a green checkmark for ~2s after save. Use for inline-edited fields and auto-saving forms.
3. **Toast** — "Customer updated." Auto-dismiss after 3–5 seconds. Use for most mutations.
4. **Toast with undo** — "Order deleted. Undo." Auto-dismiss after 6–8 seconds. Use for destructive but reversible actions. Critical UX win.
5. **Modal confirmation** — "Order successfully refunded. Customer has been notified." Use only for high-stakes actions with multiple effects.
6. **Redirect to result page** — after creating a new resource, navigate to its detail page. The new page implicitly confirms creation.

### Toast rules

- **Top-right corner** is the convention. Bottom-center is also acceptable.
- **One toast at a time**, or stack newer below older with a max of 3 visible.
- **Auto-dismiss with a visible timer** — a thin progress bar at the bottom of the toast.
- **Pause on hover** so the user can read it.
- **Dismissible** with an `X`.
- **Color-coded by type** — green/success, red/error, blue/info, yellow/warning.
- **Action button optional** — "Undo," "View," "Retry."
- **Don't toast on every keystroke** in autosaving forms — debounce or use inline confirmation instead.

### Action button states

A button that triggers an async action has at least three states:

```
[Save Changes]              ← idle
[Saving...]    (disabled)   ← pending
[✓ Saved]                   ← success (briefly), then back to idle
[Save Changes]              ← back to idle
```

And on error: the button returns to idle, the error appears as a toast or inline message, and the user can try again.

**Disable the button while pending.** Otherwise, fast users double-submit and create duplicate records. This is the #2 "feels broken" bug after missed cache invalidation.

## Confirmation dialogs

Used for destructive or irreversible actions. Used too liberally, they become noise the user dismisses without reading. Used too sparingly, the user accidentally deletes important things.

### When to confirm

**Always confirm:**
- Delete (single or bulk) of any persistent record
- Cancel subscription / downgrade plan
- Transfer ownership
- Remove user from organization
- Revoke API key
- Reset / regenerate keys
- Bulk operations affecting > 5 records

**Don't confirm:**
- Save (unless data loss is involved)
- Edit
- Toggle / boolean setting
- Add / create
- Filter / search

### Confirmation dialog anatomy

```
┌─────────────────────────────────────┐
│  Delete customer "Acme Corp"?       │
│                                     │
│  This will permanently delete the   │
│  customer and all 47 associated     │
│  orders. This cannot be undone.     │
│                                     │
│        [Cancel]      [Delete]       │
└─────────────────────────────────────┘
```

Rules:
- **Title is a question.** "Delete customer?" not "Confirm Delete."
- **Body explains the consequences in concrete terms.** "This will delete 47 associated orders" — not "Are you sure?"
- **Primary destructive action is on the right, in the destructive color.** Cancel on the left.
- **Cancel is the default focus** so accidental Enter doesn't destroy data.
- **Esc closes the dialog** as cancel.
- **For irreversible actions, require typing the resource name** before the destructive button enables. The "type the project name to confirm" pattern. Slows the user enough to break autopilot.

```
┌─────────────────────────────────────┐
│  Delete project "Production"?       │
│                                     │
│  This will permanently delete the   │
│  project and everything in it.      │
│                                     │
│  Type "Production" to confirm:      │
│  [____________________________]     │
│                                     │
│        [Cancel]      [Delete]       │
└─────────────────────────────────────┘
```

## Undo as a primary pattern

For reversible destructive actions, prefer undo over confirmation dialogs. The Gmail/Linear pattern:

1. User clicks Delete.
2. Item is instantly removed from the UI (optimistic).
3. Backend performs a soft-delete.
4. A toast appears: "Deleted. [Undo]" with a 6-8 second countdown.
5. If the user clicks Undo: restore the item, remove the toast.
6. If the countdown expires: the soft-delete becomes permanent (or stays soft with a longer TTL).

Undo is faster and more forgiving than confirmation. Use it for: single-item deletes, archiving, status changes, drag-to-move. Use confirmation for: bulk deletes, irreversible actions, actions with financial consequences.

## Optimistic updates

For high-confidence actions, update the UI before the server confirms. The action *feels* instant. On error, roll back.

### When optimistic is right

- Toggling a star, like, favorite, archive
- Reordering items (drag and drop)
- Editing a single field with simple validation
- Changing a status

### When optimistic is wrong

- Creating a record (you don't yet have the server-assigned ID)
- Operations that have heavy server-side validation (the optimistic state is often wrong)
- Operations with side effects the user needs confirmed (sending an email, charging a card)
- Operations where rollback would lose user input

### Optimistic implementation rules

- **Only update the local cache.** Don't pretend the server confirmed anything else.
- **Roll back on error** *and* show the user what happened. Silent rollback is worse than no optimism.
- **Always invalidate after settle** so the UI reflects the server's final truth, optimistic or not.
- **Don't optimistic-update the same record from two different actions concurrently.** Cancel the in-flight before starting a new one.

## Auto-save vs. explicit save

Two patterns. Pick per surface:

- **Explicit save** — the user fills the form, clicks "Save," gets confirmation. Best for forms with validation interdependencies, multi-step flows, settings that affect billing or security.
- **Auto-save** — every change persists immediately (debounced 500–1000ms). Best for long-form text editors, settings the user is exploring, anything where losing changes would be a tragedy.

**Auto-save needs a visible status indicator.** "Saved 2 seconds ago" or a checkmark. Otherwise, the user doesn't trust it and presses Ctrl+S anyway.

**Explicit-save forms need a "you have unsaved changes" warning** when the user navigates away. Use the framework's beforeunload hook or router blocker.

## Dirty state and unsaved changes

If the user has typed in a form and tries to navigate away:

- Show a confirmation: "You have unsaved changes. Discard them and leave?"
- Or, even better, save automatically as a draft and offer to restore.

Don't let the user lose 10 minutes of work because they clicked the wrong link. This is a baseline expectation.

## Notifications (in-app)

Distinct from toasts. Notifications are persistent items in a notifications panel — past events the user hasn't seen yet.

- **Bell icon in the header** with a badge for unread count.
- **Click opens a dropdown** of recent notifications, newest first.
- **Each notification has**: an icon, a one-line description, a relative timestamp, and a click target (the resource).
- **"View all" link at the bottom** to a full notifications page with filtering.
- **Mark as read** automatically on open or explicitly.
- **Notifications page** for the full history with filter and search.

Skip notifications entirely if the dashboard doesn't generate user-relevant events. An empty notifications bell is worse than no bell.

## Real-time updates

If the dashboard polls or streams:

- **Show "Last updated 2s ago"** somewhere prominent
- **For polled widgets, show a subtle pulse on update** so the user knows new data arrived
- **For streamed updates, animate new rows in** with a fade or slide — but briefly (200ms max)
- **Don't auto-scroll or jump the user's view** when new data arrives. They're reading something. Show "5 new items" as a banner they can click to load.

## Offline state

For dashboards that may be used on unreliable connections (field services, mobile, travel):

- Show a persistent banner: "You're offline. Changes will sync when you reconnect."
- Queue mutations locally (IndexedDB or localStorage).
- Replay queued mutations on reconnection.
- Handle conflicts if server state changed while offline (show diff, let user resolve).
- Use `navigator.onLine` + the `online`/`offline` events for detection, but verify with a heartbeat fetch (the events are unreliable on some platforms).

## Don'ts

- **Don't show a generic "Loading..." text on a centered blank page** for slow loads. Use a skeleton.
- **Don't use the same toast for success and error** distinguished only by color. Use icons + text.
- **Don't use `alert()` or `confirm()`** ever. Use a real dialog.
- **Don't auto-dismiss error toasts** containing critical info — let the user dismiss.
- **Don't show a stack trace** to the end user.
- **Don't say "Error: undefined is not a function"** — translate to user language.
- **Don't show the same empty state** for "nothing exists" and "filters returned nothing."
- **Don't forget to disable the submit button** during in-flight requests.
- **Don't make the user re-enter form data** on validation error — preserve everything they typed.
- **Don't silently roll back** an optimistic update on error — tell them what happened.
- **Don't toast on every save** during auto-save — use a quiet inline indicator.
- **Don't show success toasts that block the next action** the user wants to take. Toasts are non-modal.
