# Pre-flight & Verification

This file is the bookends of every dashboard build. Read the **pre-flight** section before writing any code. Read the **verification** section before declaring the dashboard done. Both sections exist to catch the failure modes that make dashboards feel hollow.

---

## Part 1 — Pre-flight

The pre-flight is a thinking exercise that takes 2–5 minutes and saves hours of rework. Do not skip it. Do not collapse it into "I'll figure it out as I go." A dashboard built without pre-flight has incompatible decisions in different layers and you discover the incompatibility on page four.

### The 12 questions

Answer all 12 in writing — even one or two sentences each — before coding. If you don't know an answer, pick the most plausible default and label it as an assumption.

#### 1. Who uses this dashboard, and for what job?
Not "admins" — what does an admin actually open this dashboard to *do*? "Approve pending refunds." "See which servers are down." "Add a user to a team." The job determines the landing page, the primary navigation, and which features get the vertical-slice treatment first.

#### 2. What domain entities exist?
List them. Three to seven is normal for a starter dashboard. For each entity, name 3–5 attributes and the relationships between entities. This becomes the schema. A dashboard without a clear entity list ends up with pages that don't know what they're listing.

Example: For an e-commerce admin — `Order`, `Customer`, `Product`, `Refund`, `Shipment`. Order has many Products, belongs to Customer, may have a Refund and a Shipment.

#### 3. What's the stack?
Framework, language, database, ORM, auth library, UI library, styling system, state library, chart library. Write them all down. If the user hasn't specified, pick a coherent set and state it. Coherent sets that work well in 2026:

- **Next.js + TypeScript + Postgres + Prisma + NextAuth/Auth.js + shadcn/ui + Tailwind + TanStack Query + Recharts** — the safe default
- **React Router v7 (framework mode) + TypeScript + SQLite + Drizzle + Better Auth + shadcn/ui + Tailwind + Recharts** — when SSR-first matters
- **SvelteKit + TypeScript + Postgres + Drizzle + Auth.js + shadcn-svelte + Tailwind + LayerChart** — when Svelte is preferred
- **Vue 3 + Nuxt + TypeScript + Postgres + Drizzle + Sidebase Auth + shadcn-vue + Tailwind + unovis** — when Vue is preferred
- **Rails 7 + Postgres + Devise + Hotwire/Turbo + ViewComponent + Chartkick** — when the user wants Rails
- **Django + Postgres + django-allauth + HTMX + Tailwind + Chart.js** — when the user wants Django
- **Laravel + Postgres + Breeze + Inertia + Vue/React + Tailwind + ApexCharts** — when the user wants Laravel

The point is that the stack must be a *set*, not "we'll pick auth later." Picking later means the auth shape doesn't match the data layer shape and one of them gets refactored.

#### 4. Where does the data actually live?
Three cases:

- **Real existing API/DB** — the user has a running backend. Get the schema, the auth method, the base URL, and a test credential. Build the dashboard against the real thing from line one.
- **Real backend the user wants you to build** — build it. Pick a DB (Postgres for production-shaped, SQLite for fast local), pick an ORM, write migrations, run them.
- **No backend yet, but the user wants a working dashboard** — use a real local persistence layer (SQLite + Prisma/Drizzle, Convex, Supabase local, or PocketBase). Never use in-memory state or hardcoded JSON. Reloading the page must not reset data.

The forbidden fourth case: "I'll mock it for now and the user can wire it up later." This is the no-scaffold violation. There is no "later." Build it real.

#### 5. What's the auth model?
- Session-based or token-based?
- Where is the user record? (own table vs. third-party IdP)
- Is there registration, or are users provisioned?
- Are there organizations/tenants, or single-tenant?
- Is there SSO/OAuth in scope, or email+password only?
- Where do credentials get hashed? (argon2 / bcrypt — never plain, never sha256)

#### 6. What's the permission model?
At minimum: name 2–4 roles and write a `resource × action` matrix for them. Even a tiny table beats hand-waving.

```
                listUsers  createUser  deleteUser  viewBilling  editSettings
admin               ✓           ✓           ✓           ✓             ✓
manager             ✓           ✓                       ✓
member                                                                
```

If the dashboard is multi-tenant, every permission check must also include "and this resource belongs to my org." See `auth-and-rbac.md`.

#### 7. What's the route map?
Write out every URL the dashboard will have, with parent → child nesting. This becomes the sidebar nav. A 5-page dashboard has a 5-line route map. Don't hand-wave it.

```
/login
/
/users
/users/:id
/users/new
/orders
/orders/:id
/settings
/settings/profile
/settings/team
/settings/billing
```

#### 8. What does "done" look like for v1?
Give yourself a finite definition. "Done" cannot be "everything works perfectly forever." It should be: which features must be complete for v1, which are explicitly out of scope, and what the smoke test looks like (the sequence of clicks a real user does to validate).

#### 10. What are the performance constraints?
Set targets before building: initial JS bundle under 200KB gzipped, LCP under 2.5s, INP under 200ms, API p95 under 500ms. Without upfront budgets, teams optimize retroactively — which means never.

#### 11. Where does this deploy?
Vercel, AWS, Docker, self-hosted VPS, Cloudflare Workers? The deployment target affects the data layer (serverless connection pooling is mandatory on Vercel/Lambda), auth (edge runtime compatibility), and SSR strategy. Write it down.

#### 12. What's the responsive scope?
Desktop-only (many internal tools)? Responsive down to tablet? Full mobile with offline/PWA? The answer changes the layout approach. Stating "desktop-only" is valid — not stating it leads to a half-baked mobile experience.

#### 9. What already exists vs. what must be built?
If the user is adding to an existing project, inventory what's there (auth library, design system, base layout, existing pages) before adding anything. Adding a second auth library or a second design system is a project-level mistake that's hard to reverse.

### Stating assumptions

If the user's request is sparse, do not interrogate them. Pick defaults, write a 5–10 line assumptions paragraph at the top of your response, and proceed. They'll redirect if you guessed wrong.

Good assumption paragraph:

> I'm assuming: Next.js 15 + TypeScript, Postgres via Prisma, Auth.js with email/password (no SSO for v1), shadcn/ui + Tailwind, TanStack Query for server state, Recharts for charts. Two roles: `admin` and `member`. Single-tenant. Entities: `User`, `Project`, `Task`. Landing page shows project count, task count, and a recent-activity feed. If any of this doesn't fit, tell me what to change and I'll adjust before going further.

---

## Part 2 — Verification

Run this checklist before stopping. It's the difference between "the pages exist" and "the dashboard works." Treat each item as a yes/no — anything that isn't yes is a remaining task.

### Foundation checks

- [ ] The app starts with a single command from a clean clone (`npm install && npm run db:setup && npm run dev` or equivalent), and the README says exactly that.
- [ ] Visiting `/` while logged out redirects to login.
- [ ] Submitting wrong credentials shows an error and stays on login.
- [ ] Submitting correct credentials lands on the dashboard home.
- [ ] Refreshing the page while logged in keeps you logged in.
- [ ] Logging out invalidates the session — re-visiting `/` after logout sends you back to login.
- [ ] The seeded admin user exists and the seed script is documented.
- [ ] At least one non-admin user exists in seed data, with different visible permissions.

### Auth & RBAC checks

- [ ] Every protected route has a server-side guard. Try hitting one with no session — must return 401/redirect.
- [ ] Every mutation endpoint checks the caller's permissions on the server, not just on the client.
- [ ] Open the app as a non-admin. Confirm at least one action is hidden in the UI *and* rejected by the server if you try to call it directly (curl/Postman).
- [ ] Passwords are hashed with argon2 or bcrypt. Search the codebase for `sha256`, `md5`, `plain`, `password.toLowerCase()` — none should appear.
- [ ] Session cookies are `httpOnly`, `sameSite=lax`, and `secure` in production.

### Navigation & shell checks

- [ ] Logo is top-left and links to the dashboard home.
- [ ] User menu is top-right with at least: profile link, settings link, logout.
- [ ] Sidebar shows the actual nav from your route map.
- [ ] Every sidebar link goes to a real page that renders something — no 404s, no "coming soon."
- [ ] The active sidebar item is visually highlighted.
- [ ] Sub-menus expand and collapse and remember which one is open.
- [ ] Breadcrumbs appear on every page deeper than one level and reflect the actual route.
- [ ] At a 1024px-wide viewport, the sidebar is still visible.
- [ ] At a 768px viewport, the sidebar collapses to icons or to a drawer.
- [ ] At 375px wide, the dashboard is still usable (drawer nav, stacked content, no horizontal scroll except inside tables).

### Data layer checks

- [ ] No file in the codebase contains a hardcoded array of "fake" rows that a page renders directly. Search for `const mockX`, `const sampleX`, `const dummyX`.
- [ ] No file uses `Math.random()` or `Date.now()` to generate displayed data.
- [ ] All list pages get data via the chosen server-state library (or framework loader), not via raw `useEffect + fetch`.
- [ ] All mutations invalidate the relevant queries on success.
- [ ] All mutations have an explicit error path and show the user the error.
- [ ] Pagination works on any table that could have >25 rows. The page number is in the URL.
- [ ] Sort works on any table where sort is expected. The sort key is in the URL.
- [ ] Filter works on any table with a filter UI. The filter is in the URL.
- [ ] Reloading a list page after sorting/filtering/paginating preserves the state.

### Feature completeness checks

- [ ] At least one entity has full CRUD: list, view, create, edit, delete.
- [ ] Create form has client-side validation that runs on blur/submit.
- [ ] Create form has server-side validation that returns field-level errors.
- [ ] Field-level errors render next to the relevant fields.
- [ ] Submit button shows a pending state while the request is in flight and is disabled to prevent double-submit.
- [ ] Successful create lands on the new resource (or the list with a success toast) — not the same empty form.
- [ ] Edit form pre-fills with current values.
- [ ] Delete shows a confirmation dialog.
- [ ] Destructive bulk actions require typing the resource name or selecting "I understand."
- [ ] Settings page actually saves and the change is visible after reload.
- [ ] User profile page actually saves and the change is visible after reload.

### State coverage checks

For every page that loads async data, all four states render correctly:

- [ ] **Loading** — skeleton or spinner that matches the eventual layout, not a blank screen.
- [ ] **Empty** — explains what would normally appear here and gives a CTA to create the first item.
- [ ] **Error** — shows the error class (network, server, permission), and offers a retry.
- [ ] **Loaded** — the actual data, properly formatted.

Test by: turning off the network in DevTools, deleting all rows in the DB, returning a 500 from the API, and reloading.

### Visualization checks

- [ ] Every chart reflects real data from the data layer.
- [ ] Every KPI card shows the actual number, the comparison (vs. previous period or target), and the unit.
- [ ] No chart has more than 6 series unless it's a time-series with a legend toggle.
- [ ] No pie chart has more than 4 slices.
- [ ] Currency, percentages, and large numbers are formatted (`$12,345`, `42.0%`, `1.2k`).
- [ ] Dates are formatted consistently (and time-zone aware if relevant).
- [ ] All charts have axis labels or titles that explain what they show.
- [ ] Color is not the only signal — every status uses an icon or label too (red/green color blindness).

### Accessibility checks

- [ ] Tab through every page in the keyboard. You can reach every interactive element. Focus styles are visible.
- [ ] Forms use `<label>` linked to inputs.
- [ ] Buttons are `<button>`, not `<div onClick>`.
- [ ] Modals trap focus while open and return focus on close. `Esc` closes them.
- [ ] Color contrast for text is at least 4.5:1, for UI components 3:1.
- [ ] Icons that convey meaning have an `aria-label`.
- [ ] No element relies solely on hover to reveal critical info on touch devices.

### Build and deploy checks

- [ ] `npm run build` (or equivalent) succeeds with zero errors. Not just locally — in a clean environment.
- [ ] `npm run lint` passes (or there is no linter configured, which is itself a check to add).
- [ ] A CI config exists (GitHub Actions, GitLab CI, or equivalent) that runs build + lint + tests on every push.
- [ ] All environment variables are documented in `.env.example` with placeholder values.
- [ ] The app fails gracefully with a clear error on startup if a required env var is missing, not with `TypeError: Cannot read property of undefined`.
- [ ] The deployment target is documented in the README.

### Polish checks

- [ ] No `console.log` statements left in production code paths (search and remove).
- [ ] No `// TODO` / `// FIXME` / `// hook this up` comments left (search and remove or convert to real implementations).
- [ ] No commented-out blocks of code more than 3 lines long.
- [ ] No leftover `Lorem ipsum`, `Example User`, `Test`, `asdf` strings visible in the UI.
- [ ] Every successful mutation shows feedback (toast, banner, or inline confirmation).
- [ ] Destructive mutation feedback uses a different visual treatment than normal feedback.
- [ ] The favicon and page title are set to the actual product name, not "Vite + React" or "Create Next App."
- [ ] The login page does not show a stack trace, the version of any library, or any internal info on bad input.

### The smoke test

Open the dashboard yourself and do this sequence end to end. If any step fails, fix it before stopping.

1. Open the app at root URL → you're redirected to login.
2. Log in as admin → you land on the dashboard home and see real data, not zeros.
3. Click each top-level nav item → each page renders without error.
4. Go to the main entity list page → see real seeded rows.
5. Sort by a column → URL updates, rows re-sort.
6. Filter or search → URL updates, rows filter.
7. Paginate to page 2 (if data is enough) → URL updates, new rows load.
8. Open one row's detail → see real data.
9. Edit it, save, return to the list → see your edit reflected.
10. Create a new one → land on the new one with success feedback.
11. Delete it → confirmation appears, accept, return to list, deleted row gone.
12. Open settings → change one setting, save, reload, change persists.
13. Open profile → change your name, save, reload, see new name in the user menu.
14. Log out → land back at login.
15. Log in as the non-admin user → see fewer items in the nav and at least one button you can't access.
16. Try to hit an admin route directly via URL → get 403 or redirect.
17. Open browser DevTools → no red errors in console, no failed requests in network.

If you reach step 17 with no failures, the dashboard meets the no-scaffold bar. If something fails, the failure is the next thing to fix — not a known issue, not a future task. Now.
