# Production-ready antipatterns

Named failure modes production-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand during Mode C audits, mid-build hollow-checks (Step 5.1), and tier-gate verifications. Complements `references/preflight-and-verification.md` (per-tier checklists) and `references/codebase-research.md` (Mode B/C/D scans).

## Core principle (recap)

> One feature at a time, end-to-end, working, before moving on. No layer-by-layer scaffolding; no fake JSON; no "hook this up later."

The patterns below are violations of this principle.

## Pattern catalog

### Hollow buttons (Critical)

**Shape.** A button on the screen that doesn't save anything. Click it, nothing persists. The handler is `console.log("clicked")` or empty.

**Grep test.** Run `grep -rE 'onClick|onSubmit' src/components | xargs -I{} grep -L "fetch\|mutate\|action" {}`. Every interactive element with `onClick` / `onSubmit` must call into a real persistence path. Handlers without one fail.

**Guard.** Step 5.1 hollow-check runs after every slice. The "click every CTA" verification at the M1 gate requires every primary action to chain to a real outcome.

### Fake JSON in charts (Critical)

**Shape.** Chart on the screen displaying hardcoded data: `const data = [{ month: 'Jan', revenue: 1234 }, ...]`. The chart "works" but doesn't reflect the database.

**Grep test.** `grep -rE 'const \w+Data = \[' src/components` returns the legitimate-test-fixture hits, not chart-feed data. Chart data must come from a real query (`useQuery`, `loader`, server action).

**Guard.** Step 4 foundation verifies real data source before any chart slice. Step 5.1 hollow-check greps for hardcoded chart fixtures.

### Sidebar with 404 links (Critical)

**Shape.** Sidebar nav lists 12 routes. Clicking 5 of them lands on a 404 or an empty page. The nav was scaffolded ahead of the routes.

**Grep test.** Every link in the sidebar component resolves to a route that exists. `grep -E 'href=' src/components/sidebar` cross-referenced against the route map (Next.js: `src/app/**/page.tsx`).

**Guard.** Step 2 architecture note declares the route map. Slices add routes only when the slice is end-to-end. The proof test at M1 walks every nav link.

### Login that accepts anything (Critical)

**Shape.** Sign-in form that calls `auth.signIn()` without verifying the credential. Or worse: a magic-link form that "redirects to dashboard" without actually issuing or verifying a token.

**Grep test.** Auth handler must call into a real auth provider (Auth.js, Clerk, custom-with-bcrypt). Handler that calls `router.push('/dashboard')` directly fails.

**Guard.** Step 4 foundation slice = sign-in must work end-to-end. The "sign in as admin, see admin UI; sign in as non-admin, see 403 on forbidden mutations" proof test at M1 verifies real auth.

### Hook this up later (Critical)

**Shape.** A form that submits, the network tab shows the request fire, the server returns 200, the toast says "saved," but the data is never persisted. The endpoint was scaffolded with `// TODO: actually save`.

**Grep test.** `grep -rE 'TODO|FIXME|hook.*up.*later|\.\.\.' src/api src/server src/app/api` returns zero structural placeholders. (Function bodies missing return values fail at `tsc`; the grep covers the comment-as-stub case.)

**Guard.** The "no-scaffold-no-placeholder" rule is structural. Every endpoint slice ships persistent: schema migration + server action + tests. Mid-build hollow-check (Step 5.1) catches the surviving comment stubs.

### Vertical-slice violation (High)

**Shape.** Layer-by-layer build. The DB schema is done for 12 entities; the API layer is half-done; the UI is wireframe screenshots. Every layer is at 80%; nothing user-visible works.

**Grep test.** Per slice: schema + API + permission check + service + query hook + UI page + tests, all referencing the same feature. A slice that ships the API without the UI (or vice versa) fails.

**Guard.** Step 4 foundation + Step 5 sequence enforce vertical slices. Each slice gates on "an actual person can do an actual job with it."

### Default component-library styling (Medium)

**Shape.** Unmodified shadcn/Radix/MUI defaults visible to the user. Buttons are the library's default purple. Headers are the library's default font. Cards have the library's default shadow.

**Grep test.** The `--color-primary` token (or framework equivalent) traces from a project-specific value, not the library default. At least one rendered component visibly inherits from the project's tokens.

**Guard.** Step 3 derives a visual identity (sub-step 3a from `DESIGN.md` if present; sub-step 3b from the archetype framework). The proof test at M1 inspects one button and verifies its color traces to `--color-primary`.

### Missing empty / loading / error state (High)

**Shape.** UI page that renders the happy path only. When the list is empty: blank screen. When loading: nothing. When the API errors: nothing or a console warning.

**Grep test.** Every list / detail / form component has explicit handling for: empty state (no data), loading state (request in flight), error state (request failed). Components that skip any of these fail.

**Guard.** `references/states-and-feedback.md` is the canonical reference. Step 5.1 hollow-check greps for components missing state handlers.

### Audit log skipped (High)

**Shape.** A security-sensitive event happens (role change, account reassignment, at-risk flag set) and the audit log table records nothing.

**Grep test.** Every state-change handler on a security-sensitive table writes an `audit_log` entry within the same transaction. Handlers that skip the audit write fail.

**Guard.** Step 2 architecture note names the audit-log table; Step 5 slices wire the audit write per handler. The "click every primary CTA" proof test verifies the audit-log row appears.

### Role check client-side only (Critical)

**Shape.** UI hides the "Delete" button for non-admin users. The DELETE endpoint accepts the request from any authenticated user. The non-admin gets the button hidden but can still call `curl DELETE /api/...`.

**Grep test.** Every mutation endpoint (PUT/POST/DELETE) checks the role server-side before persisting. Endpoints that rely on client-side UI hiding fail.

**Guard.** Step 4 RBAC layer applies as middleware before every domain handler. The proof test at M1 includes "sign in as non-admin, attempt forbidden mutation, verify 403."

### Ghost-package install (Critical)

**Shape.** AI suggested `@tansatck/react-query` (typosquat of `@tanstack/react-query`); the project ran `pnpm install` without verifying; the typosquatted package is now in the dependency tree.

**Grep test.** Every dependency in `package.json` (or equivalent) verifies on the registry: real publisher, weekly downloads >= 1k, last release within 18 months. Suspect packages fail.

**Guard.** Step 4 foundation slice verifies every dependency before installing. `references/performance-and-security.md` has the supply-chain deep dive. Cited: Socket 2025 slopsquatting research.

### Float for currency (Critical)

**Shape.** A billing or financial domain stores money as `decimal` in the schema but as JavaScript `number` (a float) in the UI / API layer. Rounding errors accumulate.

**Grep test.** Domain check: the project domain (from PRD) is finance / billing / accounting. The codebase's currency type is integer-cents or `Decimal` (or framework equivalent), not float. Float storage in a financial domain fails.

**Guard.** `references/domain-considerations.md` finance section names this trap. Step 1 pre-flight asks the domain; Step 2 architecture note declares the currency type.

### Dashboard with no audit / export / search (Medium)

**Shape.** Tier-2 dashboard with the basic CRUD wired but no global search, no audit log viewer, no exports, no notifications. Works for one user; falls apart in real teams.

**Grep test.** Tier-2 dashboards include: search (entity-level or global), audit log viewer (admin-only), at least one export path, at least one notification channel. Missing any of these fails Tier 2.

**Guard.** `references/preflight-and-verification.md` Tier 2 checklist enforces.

### Settings page that doesn't persist (High)

**Shape.** A settings UI with toggles and inputs. Changing them flips the UI state. Reload the page: the changes are gone.

**Grep test.** Every settings input persists via a server action / mutation, not just local state. Settings that update only `useState` fail.

**Guard.** Step 5 slices ship settings vertically: schema + API + UI in one slice.

### Unmodified default error pages (Low)

**Shape.** Next.js default 404, default 500. The framework's "Application error: a server-side exception has occurred" page in production.

**Grep test.** Project has a custom `not-found.tsx` and `error.tsx` (or framework equivalent). Defaults visible to users fail.

**Guard.** `references/error-pages-and-offline.md` is the canonical reference. Step 4 foundation slice ships custom error pages.

### Cross-tenant data leak via missing `tenant_id` (Critical)

**Shape.** A multi-tenant app where a domain query reads from a table without the `tenant_id` filter. User in tenant A guesses or enumerates an ID and reads tenant B's data.

**Grep test.** `grep -rE 'db\.\w+\.findBy(Id|Email)\([^,]+\)' src/` returns zero matches; every data-access call passes `tenant_id`. (Same test repo-ready's audit applies; a Pulse worked-example finding.)

**Guard.** Step 2 architecture note declares the tenant model and the enforcement layer (`db/tenant.ts` helper). The harden-ready pen-test verifies it.

## Severity ladder

- **Critical**: blocks the slice. Must be fixed before declaring done.
- **High**: blocks the tier gate. Must be fixed before next tier.
- **Medium**: flagged in the verification; fix recommended this tier or next.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": canonical have-nots list.
- `references/preflight-and-verification.md`: per-tier checklists.
- `references/codebase-research.md`: Mode B/C/D scan modes.
- `references/states-and-feedback.md`: empty / loading / error patterns.
- `references/domain-considerations.md`: per-domain failure modes (finance, healthcare, etc.).
- `references/performance-and-security.md`: supply-chain (slopsquatting) deep dive.
- `references/auth-and-rbac.md`: role-check discipline.
