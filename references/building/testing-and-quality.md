# Testing & Quality

A dashboard that passes the verification checklist once is good. A dashboard that passes it every time someone pushes code is production-grade. This file is the rules for testing dashboards so they stay working as they grow.

## Quick decision: what to test first

Budget is always limited. Prioritize tests by the damage a regression causes:

```
Priority  What to test                         Why
────────────────────────────────────────────────────────────────
1 (must)  Auth flow: login, session, logout     Broken auth = nobody can use the app
1 (must)  Permission denial: admin vs member    Broken RBAC = data leak / unauthorized action
2 (high)  CRUD happy path per entity            Broken CRUD = the core job fails
2 (high)  Form validation (server-side)         Missing validation = bad data in production
3 (mid)   Empty, loading, error states          Broken states = user confusion, not data loss
3 (mid)   Accessibility (axe) per page          Catches WCAG violations mechanically
4 (nice)  Filter/sort/paginate round-trip       Regression-prone but lower blast radius
4 (nice)  Visual regression (screenshots)       Catches CSS drift, low urgency
```

**Minimum viable test suite:** 1 auth flow test, 1 CRUD flow test, 1 permission denial test, axe scan on every page. This covers priorities 1–3 in ~4 test files. Add priority 4 tests when the dashboard stabilizes.

## The testing pyramid for dashboards

Dashboards are UI-heavy, data-heavy, and auth-heavy. The testing strategy reflects that:

```
            /  E2E  \              ← few, slow, high confidence
           / Integration \         ← moderate, test real flows
          /   Component    \       ← many, fast, isolated UI
         /      Unit        \      ← many, fastest, pure logic
```

Most dashboard teams over-invest in unit tests for utility functions and under-invest in integration tests that exercise real auth + real queries + real UI. Flip that. The highest-value tests for a dashboard are integration tests that walk through a real user flow with a real (or realistic) database.

## Unit tests

Test pure logic: permission checks, data formatting, validation schemas, utility functions. These are fast, stable, and cheap.

### What to unit test

- **Permission logic** — `can(role, permission)` for every role × permission combination. This is a truth table; test it exhaustively.
- **Validation schemas** — Zod/Yup/Valibot schemas with valid input, invalid input, edge cases (empty strings, null, boundary values).
- **Formatters** — currency, date, number, percentage formatting. Edge cases: zero, negative, very large, undefined.
- **URL builders** — filter-to-query-string and query-string-to-filter round-trip.
- **Derived state** — any function that transforms server data for display (aggregations, sorting, grouping).

### What NOT to unit test

- React/Vue/Svelte components in isolation with no data. Testing that a `<Button>` renders is not useful.
- API route handlers that just call a service function. Test the service function instead.
- Framework boilerplate (layouts, providers, wrappers).

### Tools

- **JavaScript/TypeScript** — Vitest (recommended; fast, ESM-native, compatible with Jest API), Jest
- **Python** — pytest
- **Ruby** — RSpec, Minitest
- **Go** — stdlib `testing`
- **PHP** — PHPUnit, Pest

## Component tests

Test UI components with realistic data and interactions. These are the middle layer — faster than E2E, more realistic than unit tests.

### What to component test

- **Forms** — render the form, fill fields, submit, assert the mutation was called with correct data. Test validation: submit with invalid data, assert error messages appear next to the right fields.
- **Tables** — render with mock data, test sort (click header, assert order changes), test pagination (click next, assert new rows), test empty state (render with empty array, assert empty state message).
- **Permission-gated UI** — render as admin, assert the delete button exists. Render as member, assert it doesn't. This catches regressions where someone removes a permission check.
- **Loading/error/empty states** — render each state explicitly and assert the right UI appears.
- **Modals and drawers** — open, interact, close. Assert focus management (focus trapped inside, returns on close).

### How to component test

Use a tool that renders real DOM and supports user interactions:

- **React** — React Testing Library + Vitest (or Jest). Render components, query by role/text/label, fire events, assert DOM state.
- **Vue** — Vue Testing Library + Vitest
- **Svelte** — Svelte Testing Library + Vitest
- **Angular** — Angular Testing Library or TestBed + Jest

The testing library philosophy: test what the user sees and does, not implementation details. Query by `role`, `label`, `text` — not by CSS class or component internals.

```tsx
// Example: testing a create form
test('creates a customer with valid data', async () => {
  const onSubmit = vi.fn();
  render(<CustomerForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText('Name'), 'Acme Corp');
  await userEvent.type(screen.getByLabelText('Email'), 'admin@acme.com');
  await userEvent.selectOptions(screen.getByLabelText('Plan'), 'pro');
  await userEvent.click(screen.getByRole('button', { name: /create/i }));

  expect(onSubmit).toHaveBeenCalledWith({
    name: 'Acme Corp',
    email: 'admin@acme.com',
    plan: 'pro',
  });
});

test('shows validation errors for empty required fields', async () => {
  render(<CustomerForm onSubmit={vi.fn()} />);
  await userEvent.click(screen.getByRole('button', { name: /create/i }));

  expect(screen.getByText(/name is required/i)).toBeInTheDocument();
  expect(screen.getByText(/email is required/i)).toBeInTheDocument();
});
```

### Mocking the data layer

Component tests need data but shouldn't hit a real API. Two approaches:

1. **Mock the query hooks** — override `useQuery` / `useMutation` to return controlled data. Fast, but tightly coupled to the library.
2. **Mock the network layer** — use MSW (Mock Service Worker) to intercept `fetch`/`xhr` and return realistic responses. Decoupled from the query library, closer to real behavior.

**MSW is the recommended approach** for dashboard testing. Define handlers once, reuse across tests. The handlers mirror your real API contract, so mismatches surface as test failures.

```ts
// handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/customers', () => {
    return HttpResponse.json({
      data: [
        { id: '1', name: 'Acme Corp', email: 'admin@acme.com', plan: 'pro' },
        { id: '2', name: 'Globex', email: 'hank@globex.com', plan: 'free' },
      ],
      totalCount: 2,
      page: 1,
      pageSize: 25,
    });
  }),
  http.post('/api/customers', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: '3', ...body }, { status: 201 });
  }),
];
```

## Integration tests

Test real user flows that cross multiple components, hit the API (or a realistic mock), and exercise auth. These are the highest-value tests for a dashboard.

### What to integration test

Write one integration test per vertical slice. The test walks through the full flow a real user would:

1. **Auth flow** — visit protected page, get redirected to login, log in with valid credentials, land on dashboard home. Log out, confirm redirect back to login.
2. **CRUD flow per entity** — navigate to the list, create a new record, verify it appears in the list, open it, edit it, save, verify the edit is reflected, delete it, confirm it's gone.
3. **Permission flow** — log in as admin, verify admin-only actions are available. Log in as member, verify they're hidden and the API rejects direct access.
4. **Filter/sort/paginate** — apply filters, verify URL updates and table narrows. Sort, verify order changes. Paginate, verify new rows load.

### Tools

- **Playwright** (recommended) — cross-browser, fast, reliable, built-in assertions, API testing, network interception. The best E2E tool in 2026.
- **Cypress** — good developer experience, single-browser focus, slightly slower than Playwright for parallel runs.
- **Testing Library + MSW** — for integration tests that don't need a real browser (faster, but less realistic).

For dashboards, **Playwright** is the right default. It handles auth flows, cookie management, multiple browser contexts (testing two users simultaneously), and network interception natively.

### Integration test structure

```ts
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('redirects to login when not authenticated', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveURL(/\/login/);
  });

  test('logs in with valid credentials and lands on dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('admin@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page).toHaveURL('/');
    await expect(page.getByText(/welcome/i)).toBeVisible();
  });

  test('rejects invalid credentials', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('admin@example.com');
    await page.getByLabel('Password').fill('wrong');
    await page.getByRole('button', { name: /sign in/i }).click();
    await expect(page.getByText(/invalid/i)).toBeVisible();
    await expect(page).toHaveURL(/\/login/);
  });

  test('logout invalidates session', async ({ page }) => {
    // ... login first ...
    await page.getByRole('button', { name: /user menu/i }).click();
    await page.getByRole('menuitem', { name: /sign out/i }).click();
    await expect(page).toHaveURL(/\/login/);
    await page.goto('/');
    await expect(page).toHaveURL(/\/login/);
  });
});
```

### Auth in tests

Don't log in through the UI for every test — it's slow. Use one of:

1. **Storage state** — log in once in a setup step, save cookies/localStorage to a file, reuse across tests. Playwright has built-in support (`storageState`).
2. **API login** — call the login endpoint directly and set the cookies programmatically. Faster than UI login.
3. **Test-only auth bypass** — in test environments only, accept a special header or token that skips the login flow. Guard with environment checks.

Create separate storage states for each role: `admin.storageState.json`, `member.storageState.json`. Tests that check permissions use the appropriate state.

## Accessibility testing

Accessibility is a requirement, not a nice-to-have. Automate what you can; manually verify the rest.

### Automated accessibility tests

Use `axe-core` (the engine behind most a11y tools) integrated into your test suite:

- **Component tests** — `jest-axe` or `vitest-axe` to run axe on rendered components
- **E2E tests** — `@axe-core/playwright` to run axe on full pages in Playwright

```ts
// Component test with axe
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('customer form has no accessibility violations', async () => {
  const { container } = render(<CustomerForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

```ts
// Playwright test with axe
import AxeBuilder from '@axe-core/playwright';

test('dashboard home has no a11y violations', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

Run axe on every page. It catches ~30-40% of accessibility issues automatically: missing labels, bad contrast, missing alt text, broken ARIA roles, keyboard traps.

### Manual accessibility checks

Axe can't catch everything. Do these manually at least once:

- **Keyboard walkthrough** — Tab through every page. Can you reach every interactive element? Can you see where focus is? Can you operate every control with keyboard alone?
- **Screen reader test** — use VoiceOver (Mac), NVDA (Windows), or Orca (Linux) to navigate the dashboard. Does it make sense spoken aloud? Are headings in order? Are buttons labeled?
- **Zoom test** — zoom to 200%. Does the layout still work? Is text readable? Do controls still function?
- **Reduced motion** — enable "prefers-reduced-motion" in the OS. Do animations respect it?
- **High contrast** — enable high contrast mode. Is everything still visible?

## API tests

Test your API endpoints directly — independent of the UI. This catches issues the UI tests miss (malformed responses, missing fields, wrong status codes).

### What to API test

- **Every endpoint returns the documented response shape.** Assert the JSON structure matches the contract.
- **Validation rejects bad input with field-level errors.** Send invalid data, assert 400/422 with the right error fields.
- **Auth is enforced.** Call every protected endpoint without a session — assert 401. Call with wrong role — assert 403.
- **Org scoping works.** Create a resource in Org A, try to access it as a user in Org B — assert 404 (not 403).
- **Pagination, sorting, filtering.** Assert the response reflects the query params.

### Tools

- **Playwright's `request` API** — make HTTP calls directly in your E2E test suite. Shares auth setup with browser tests.
- **Supertest** (Node.js) — test Express/Fastify/Koa handlers without starting a server.
- **httpx** / **requests** (Python) — for Django/FastAPI/Flask.
- **Hurl** — a command-line HTTP testing tool with a declarative syntax. Good for CI.

## Database setup for tests

Tests need a database. Three strategies:

1. **Real database, per-test-suite** — spin up a Postgres/SQLite instance for the test run, run migrations, seed, test, tear down. The most realistic. Use Docker for Postgres; use in-memory SQLite for speed.
2. **Transaction rollback** — each test runs inside a transaction that rolls back at the end. Fast, clean, but doesn't test transaction behavior or constraints that only fire on commit.
3. **Seed + truncate** — seed once, truncate tables between tests. Faster than re-seeding, but tests must not depend on seed data order.

For dashboards, **real database with seed data per test suite** is the right default. It matches production most closely and catches migration issues.

## Visual regression testing

Catch unintended visual changes before they ship. Especially valuable for dashboards where layout consistency matters.

### Tools

- **Playwright screenshots** — built-in, compare screenshots between runs. Good enough for most teams.
- **Percy** (BrowserStack) — cloud service that diffs screenshots with smart comparison (ignores anti-aliasing, font rendering). SaaS.
- **Chromatic** — from the Storybook team. Tests components in isolation with visual diffs.
- **Argos** — open-source visual testing.

### How to use

Take screenshots of key pages in known states (loaded with seed data, empty state, error state) and compare against baselines. Update baselines when changes are intentional.

```ts
test('dashboard home looks correct', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('dashboard-home.png', {
    maxDiffPixelRatio: 0.01,
  });
});
```

Don't screenshot every page in every state — the maintenance burden grows fast. Focus on: landing page, main list page, main form, empty states, and the login page.

## Playwright component testing

Playwright now supports component testing for React, Vue, Svelte, and Angular. This sits between Testing Library (JSDOM, not a real browser) and full E2E (real browser, full app). Components render in a real browser with full CSS — ideal for testing visual states, focus management, and responsive behavior that JSDOM misses.

Use for: components with complex CSS (dark mode, responsive breakpoints), focus management (modals, drawers), and hover/animation states.

## Contract testing

When frontend and backend are developed by different teams (or when consuming third-party APIs), contract tests ensure the API shape doesn't break without both sides knowing.

- **Consumer-driven contracts:** frontend defines expected interactions, backend verifies them.
- **Tool:** Pact (v4+ supports GraphQL and async messages).
- **Pattern:** consumer publishes contract > Pact Broker shares it > provider CI verifies against it > mismatch fails the build.

## Load testing

Dashboards that work for 1 user may crash with 100 concurrent users. Test under load:

- **Tools:** k6 (scriptable, modern, CLI-first), Artillery (YAML-based).
- **What to test:** list API endpoints with filters under concurrent load, WebSocket connections at scale, concurrent writes to the same record.
- **Establish baselines:** record p50/p95/p99 response times. Alert when they regress.

## Testing dark mode

Run visual regression tests in both light and dark themes:

```typescript
// Playwright: test in dark mode
test('dashboard in dark mode', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.goto('/');
  await expect(page).toHaveScreenshot('dashboard-dark.png');
});
```

Catches: unreadable text in dark mode, chart colors that disappear, invisible borders.

## Testing webhooks and background jobs

- **Webhooks:** POST test payloads to your handler with valid signatures (compute HMAC with test secret). Assert side effects (DB updates, notifications).
- **Background jobs:** invoke the worker function directly with test data. Assert the result, verify retry behavior on failure.

## Test data factories

Functions that generate realistic test data with sensible defaults and overrides:

```typescript
// Using @faker-js/faker + fishery
const userFactory = Factory.define<User>(() => ({
  id: faker.string.uuid(),
  name: faker.person.fullName(),
  email: faker.internet.email(),
  role: 'member',
  createdAt: faker.date.recent({ days: 90 }),
}));

// In tests: unique data, easy edge cases
const admin = userFactory.build({ role: 'admin' });
const oldUser = userFactory.build({ createdAt: subDays(new Date(), 365) });
```

Every test gets unique data. No test depends on specific seed IDs.

## Test organization

```
tests/
  unit/                  ← pure logic, fast
    permissions.test.ts
    formatters.test.ts
    validators.test.ts
  components/            ← component tests with Testing Library
    CustomerForm.test.tsx
    CustomerTable.test.tsx
    EmptyState.test.tsx
  e2e/                   ← Playwright integration + E2E
    auth.spec.ts
    customers.spec.ts
    settings.spec.ts
    permissions.spec.ts
  fixtures/              ← shared test data
    customers.ts
    users.ts
  mocks/                 ← MSW handlers
    handlers.ts
    server.ts
```

## CI integration

Tests must run on every push. A test that only runs locally is a test that stops running after week two.

- **Run unit + component tests first** — they're fast. Fail fast.
- **Run E2E tests in parallel** — Playwright supports sharding across CI workers.
- **Run a11y tests as part of E2E** — axe adds negligible time.
- **Run visual regression as a separate job** — it's slower and the diffs need human review.
- **Seed the test database in CI** — same seed script as local dev. If the seed breaks, CI catches it.
- **Report coverage** — not as a gate (100% coverage is a vanity metric), but as a trend. Declining coverage on critical paths (auth, permissions, CRUD) is a signal.

## The minimum test suite

If you can only write 10 tests for the dashboard, write these:

1. Unauthenticated user gets redirected to login
2. Login with valid credentials reaches dashboard home
3. Login with invalid credentials shows error
4. Logout invalidates session
5. Admin can create a record (full form flow)
6. Created record appears in the list
7. Admin can edit the record
8. Admin can delete the record
9. Non-admin cannot access admin-only action (server rejects)
10. Dashboard home has no accessibility violations

These 10 tests catch the most common regressions. They're the starting point, not the finish line.

## Don'ts

- **Don't test implementation details.** Test behavior the user cares about. "Button has class `btn-primary`" is fragile; "button is visible and labeled Create" is stable.
- **Don't mock everything.** The more you mock, the less you test. Use real databases, real auth, and MSW for external APIs.
- **Don't write tests that pass with broken code.** If you can delete the feature and the test still passes, the test is useless.
- **Don't skip flaky tests.** Fix them. A flaky test is a test telling you the code has a race condition.
- **Don't test only the happy path.** The sad path (validation errors, permission denials, network failures) is where bugs live.
- **Don't write E2E tests for pure logic.** Formatting functions don't need a browser.
- **Don't delay testing until "after the build."** Write tests alongside each vertical slice. A slice isn't done until it has tests.
- **Don't gate merges on 100% coverage.** Gate on "critical paths are tested" instead.
