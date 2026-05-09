# Performance & Security

A dashboard that works but loads in 8 seconds or leaks data across tenants isn't production-grade. This file covers the performance optimizations and security hardening that separate a working dashboard from a shippable one.

**Canonical scope:** bundle size, SSR, code-splitting, CSP, CORS, rate limiting, security headers, supply-chain hygiene, basic dependency scanning. **See also:** `security-deep-dive.md` for session hardening, secrets, and incident response; `auth-and-rbac.md` for authorization logic.

---

## Part 1 — Performance

Dashboard performance is about two things: **how fast the page loads** and **how fast it responds to interaction**. Both matter. A dashboard that takes 5 seconds to load trains users to dread opening it. A dashboard that lags 400ms on every click trains users to distrust it.

### The performance budget

Set explicit targets before optimizing. Without targets, "make it faster" is endless.

| Metric | Target | Why |
|---|---|---|
| First Contentful Paint (FCP) | < 1.5s | User sees something quickly |
| Largest Contentful Paint (LCP) | < 2.5s | Main content is visible |
| Interaction to Next Paint (INP) | < 200ms | Clicks feel instant |
| Cumulative Layout Shift (CLS) | < 0.1 | Nothing jumps around |
| Time to Interactive (TTI) | < 3.5s | User can click things |
| JavaScript bundle (initial) | < 200KB gzipped | The #1 controllable factor |
| API response (p95) | < 500ms | Server isn't the bottleneck |

Measure with Lighthouse (lab), `web-vitals` library (field), and your RUM tool (real users). Lab scores don't match field scores — measure both.

### Bundle size

The single biggest lever. Dashboards love to ship 2MB of JavaScript because they import everything at the top level.

#### Code splitting by route

Every route should be a separate chunk. The user loading `/customers` should not download the code for `/settings/billing`.

- **Next.js** — automatic per-page splitting. `next/dynamic` for component-level.
- **Remix** — automatic per-route splitting.
- **Vite + React/Vue/Svelte** — `React.lazy()` / dynamic `import()` / `defineAsyncComponent()` with the router.
- **SvelteKit** — automatic per-route splitting.

```tsx
// React Router with lazy loading
const Customers = lazy(() => import('./pages/Customers'));
const Settings = lazy(() => import('./pages/Settings'));
const Billing = lazy(() => import('./pages/Settings/Billing'));
```

#### Tree-shaking

Import only what you use. The difference between `import { format } from 'date-fns'` and `import * as dateFns from 'date-fns'` is 200KB.

Common offenders in dashboards:
- **Icon libraries** — import individual icons (`import { Home } from 'lucide-react'`), not the whole set
- **Chart libraries** — import specific chart types, not the kitchen sink
- **Lodash** — use `lodash-es` or individual imports (`import debounce from 'lodash/debounce'`)
- **Date libraries** — `date-fns` tree-shakes well; `moment` doesn't (don't use moment)
- **UI libraries** — most modern ones (shadcn, Radix, Headless UI) tree-shake. Older ones (Ant Design, Material UI full import) may not — check the docs.

#### Analyze the bundle

Run the bundle analyzer before shipping. Every framework has one:
- `@next/bundle-analyzer`
- `rollup-plugin-visualizer` (Vite)
- `webpack-bundle-analyzer`
- `source-map-explorer`

Look for: duplicated dependencies, unexpectedly large libraries, code that should be lazy-loaded but isn't.

### Lazy loading heavy components

Chart libraries, rich text editors, code editors, and PDF renderers are large. Don't load them until the user navigates to a page that needs them.

```tsx
// Lazy-load the chart library
const RevenueChart = lazy(() => import('./components/RevenueChart'));

function DashboardHome() {
  return (
    <div>
      <KPICards data={kpis} />       {/* renders immediately */}
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart data={revenue} />  {/* loads when needed */}
      </Suspense>
    </div>
  );
}
```

### Server-side rendering (SSR) and static generation

For dashboards behind auth, SSR has a specific benefit: the initial page load shows real content instead of a loading skeleton. The server fetches data, renders HTML, sends it — the user sees content before JavaScript hydrates.

- **Use SSR for the shell and landing page.** The sidebar, header, and KPI cards render server-side. The user sees the dashboard shape immediately.
- **Use client-side fetching for interactive content.** Tables with sort/filter/paginate are better as client-side queries (with SSR-prefetched initial data).
- **Don't SSR everything.** SSR adds server load and TTFB latency. SSR the first paint; let the client handle the rest.

### Image optimization

Dashboards display avatars, logos, product images, and chart exports.

- **Use `next/image`, `@unpic/react`, or a CDN transform service** (Cloudinary, Imgix, Cloudflare Images) for automatic resizing, format conversion (WebP/AVIF), and lazy loading.
- **Set explicit `width` and `height`** on every image to prevent CLS.
- **Lazy-load images below the fold.** `loading="lazy"` is sufficient for most cases.
- **Serve avatars at the size they're displayed.** A 32px avatar doesn't need a 512px source image.
- **Use SVG for icons and logos.** They're resolution-independent and tiny.

### Font loading

- **Use `font-display: swap`** so text is visible immediately with a fallback font, then swaps when the custom font loads.
- **Subset the font** to the characters you actually use. Latin-only dashboards don't need CJK glyphs.
- **Self-host the font** instead of loading from Google Fonts. One fewer DNS lookup, better privacy, no third-party dependency.
- **Preload the primary font** in the `<head>` with `<link rel="preload" as="font" type="font/woff2" crossorigin>`.
- **Limit to 2 font families** — one for headings, one for body (or one for both). Each additional font is a network request and a rendering delay.

### Database query performance

Slow dashboards are usually slow databases, not slow JavaScript.

- **Add indices for every column used in `WHERE`, `ORDER BY`, or `JOIN`.** The ORM won't do this for you.
- **Use `EXPLAIN ANALYZE`** on slow queries to find sequential scans and missing indices.
- **Paginate server-side.** `OFFSET` + `LIMIT` for offset pagination; keyset (`WHERE id > :cursor`) for cursor pagination. Keyset is faster for large offsets.
- **Don't `SELECT *`.** Select only the columns the page needs. Especially on list endpoints.
- **Use database-level aggregations** for KPIs and charts, not application-level loops. `SELECT COUNT(*), SUM(revenue) FROM orders WHERE created_at > :start` is faster than fetching all orders and summing in JavaScript.
- **Cache expensive aggregations.** Materialized views (Postgres), query caching (Redis), or a pre-computed stats table updated by a background job.
- **Connection pooling.** Use PgBouncer, Prisma connection pool, or the ORM's built-in pooling. Don't open a new connection per request.

### Virtualization

Tables with hundreds of rows and charts with thousands of points need virtualization — rendering only the visible portion.

- **Tables** — TanStack Virtual, react-window, react-virtuoso, vue-virtual-scroller, svelte-virtual-list. Virtualize when rows exceed ~100.
- **Charts** — downsample data before rendering. A 10,000-point line chart is visually indistinguishable from a 1,000-point chart. Libraries like uPlot and ECharts (canvas mode) handle large datasets natively.
- **Long lists** — any scrollable list (notifications, activity feeds, audit logs) with potentially hundreds of items should virtualize.

### Caching strategy

| Layer | Tool | What to cache |
|---|---|---|
| Browser | Query library (`staleTime`) | API responses, per-query TTL |
| CDN/edge | Vercel, Cloudflare, Fastly | Static assets, SSR responses (with `s-maxage`) |
| API | Redis, in-memory LRU | Expensive aggregations, session lookups |
| Database | Materialized views, query cache | Pre-computed stats, denormalized counts |

Set `staleTime` per query based on how fast the data changes:
- KPIs on the landing page: 60–300s (poll for freshness)
- List pages: 30–60s
- Detail pages: 10–30s
- Settings: 300s+ (rarely changes)

### Memory leaks

SPAs that stay open for hours (operational dashboards, internal tools) are prone to memory leaks. Common causes:

- **Polling intervals not cleared** on unmount. Always clean up `setInterval` in the effect's cleanup function.
- **WebSocket connections not closed** on unmount.
- **Event listeners not removed** (`window.addEventListener` without cleanup).
- **Stale closures holding references** to large objects.
- **Growing caches** without eviction. Set `gcTime` on your query library; set max size on custom caches.

Profile with Chrome DevTools → Memory → Heap snapshot before and after navigating away from a page. If memory doesn't drop, something is leaking.

---

## Part 2 — Security hardening

Auth and RBAC are in `auth-and-rbac.md`. This section covers everything else: the HTTP headers, input handling, dependency management, and infrastructure-level protections that complete the security picture.

### Security headers

Set these on every response. Most can be configured in your framework's middleware or in a reverse proxy (nginx, Caddy, Vercel, Cloudflare).

```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://api.example.com; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

#### Content Security Policy (CSP)

CSP is the strongest defense against XSS. It tells the browser which sources are allowed to load scripts, styles, images, and other resources.

- **Start with `default-src 'self'`** and add only what's needed. Every additional source is an attack surface.
- **Avoid `'unsafe-inline'` for scripts.** Use nonces or hashes instead. `'unsafe-inline'` for styles is usually acceptable (many UI libraries need it).
- **Avoid `'unsafe-eval'`.** If a dependency requires it, that dependency has a problem.
- **Use `report-uri` or `report-to`** to collect CSP violation reports. They tell you when something is blocked — or when an attacker is probing.
- **Test in `Content-Security-Policy-Report-Only`** mode first so you don't break the app while tightening the policy.

#### HSTS

`Strict-Transport-Security` forces HTTPS. Without it, the first request can be intercepted on HTTP before the redirect. Set `max-age` to at least 1 year (31536000 seconds). Add `includeSubDomains`. Consider HSTS preloading.

### Cross-Site Request Forgery (CSRF)

CSRF attacks trick a logged-in user's browser into making requests to your dashboard. Defenses:

- **SameSite cookies** — `SameSite=Lax` (the default in modern browsers) blocks most CSRF. `SameSite=Strict` is stronger but breaks legitimate cross-site navigation (e.g., links from email).
- **CSRF tokens** — for traditional form submissions, include a unique token in a hidden field and verify on the server. Most frameworks handle this (Django's `{% csrf_token %}`, Rails' `authenticity_token`, Laravel's `@csrf`).
- **For SPA dashboards with JSON APIs** — `SameSite=Lax` cookies + checking the `Origin` or `Referer` header on mutations is sufficient. CSRF tokens are harder to implement in SPAs and add less value when cookies are `SameSite`.
- **Never use GET for mutations.** GET requests are the easiest to forge (an `<img src>` tag is enough).

### Cross-Origin Resource Sharing (CORS)

If the dashboard's frontend and API are on different origins, configure CORS on the API:

```ts
// Express example
app.use(cors({
  origin: 'https://dashboard.example.com',   // specific origin, never '*' for credentialed requests
  credentials: true,                          // allow cookies
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

Rules:
- **Never use `origin: '*'` with `credentials: true`.** The browser blocks it, and if you work around it, you've created a security hole.
- **Whitelist specific origins.** Don't reflect the `Origin` header back as `Access-Control-Allow-Origin` — that's equivalent to `*`.
- **Restrict methods and headers** to what the dashboard actually uses.

### Input sanitization and XSS prevention

XSS is the most common web vulnerability. Dashboards are particularly vulnerable because they display user-generated content (names, descriptions, comments).

- **Use framework-native rendering.** React's JSX, Vue's templates, Svelte's `{variable}` — all auto-escape HTML by default. Don't bypass with `dangerouslySetInnerHTML`, `v-html`, or `{@html}` unless you've sanitized.
- **When you must render user HTML** (rich text editors, markdown), sanitize with DOMPurify (client-side) or `sanitize-html` (server-side). Never render raw HTML from the database.
- **Sanitize on output, not (only) on input.** Input sanitization strips legitimate content and can be bypassed. Output escaping is the primary defense.
- **Validate and reject unexpected characters** in structured fields (emails, URLs, phone numbers). Use your schema validation library (Zod, etc.).
- **Encode data in the right context.** HTML context → HTML-encode. URL context → URL-encode. JavaScript context → JSON-encode. CSS context → CSS-encode. Getting the context wrong is how XSS happens.

### SQL injection

ORMs (Prisma, Drizzle, ActiveRecord, Django ORM, Eloquent) prevent SQL injection by default through parameterized queries. The risk appears when you drop to raw SQL:

- **Always use parameterized queries** for raw SQL. `db.$queryRaw\`SELECT * FROM users WHERE id = ${id}\`` (Prisma) or `db.execute(text("SELECT * FROM users WHERE id = :id"), {"id": id})` (SQLAlchemy). Never concatenate user input into SQL strings.
- **Audit every raw query in the codebase.** Search for `$queryRawUnsafe`, `$executeRawUnsafe`, `raw(`, `execute(` and verify each one uses parameters.
- **Use the ORM for everything you can.** Drop to raw SQL only for complex queries the ORM can't express.

### Rate limiting

Auth rate limiting is covered in `auth-and-rbac.md`. But every public-facing endpoint should have rate limiting:

- **Login** — 5 attempts per email per 15 minutes (already in auth-and-rbac.md)
- **API endpoints** — 100–1000 requests per minute per user, depending on the endpoint. More for reads, fewer for writes.
- **File uploads** — 10 uploads per minute per user
- **Exports** — 5 per minute per user (exports are expensive)
- **Password reset** — 3 per hour per email

Use a rate limiter middleware:
- **Node.js** — `express-rate-limit`, `@fastify/rate-limit`, `rate-limiter-flexible`
- **Django** — `django-ratelimit`, DRF throttling
- **Rails** — `rack-attack`
- **Laravel** — built-in `throttle` middleware
- **Go** — `golang.org/x/time/rate`, `limiter`

Return `429 Too Many Requests` with a `Retry-After` header. Show the user a friendly message, not a raw error.

### Dependency security

Your dashboard has hundreds of dependencies. Some of them have vulnerabilities.

- **Run `npm audit` / `pip audit` / `bundle audit`** in CI on every push. Fail the build on critical/high vulnerabilities.
- **Use Dependabot, Renovate, or Snyk** to auto-create PRs when updates are available.
- **Pin dependency versions** in lockfiles (`package-lock.json`, `yarn.lock`, `poetry.lock`). Don't use `^` ranges in production without a lockfile.
- **Audit new dependencies before adding them.** Check the package's: last update date (abandoned?), download count (trust signal), known vulnerabilities, maintainer count (bus factor), license.
- **Remove unused dependencies.** `depcheck` (Node.js) finds them. Every unused dependency is attack surface for free.

### Environment variables and secrets

- **Never commit secrets to git.** Not in code, not in config files, not in comments. Use `.env` files locally (gitignored) and secrets managers in production (Vercel env vars, AWS Secrets Manager, Doppler, Vault).
- **Don't expose server secrets to the client.** In Next.js, only `NEXT_PUBLIC_*` vars reach the browser. In Vite, only `VITE_*`. Verify the framework's behavior.
- **Rotate secrets regularly.** Especially API keys and database passwords. Design the system so rotation is a config change, not a code change.
- **Use separate secrets per environment.** Dev, staging, and production must have different database credentials, API keys, and signing secrets.

### File upload security

Dashboards that accept file uploads (avatars, imports, attachments) need these protections:

- **Validate file type on the server** by inspecting the file's magic bytes, not just the extension or MIME type from the client. The client can lie.
- **Limit file size** on both client and server. Set the limit as low as the use case allows.
- **Rename uploaded files** with a random UUID. Never use the user-supplied filename in the storage path — it can contain path traversal (`../../etc/passwd`).
- **Store uploads outside the web root** or in object storage (S3, R2, GCS). Never serve uploaded files from the same domain as the app without a CDN or transform layer.
- **Scan for malware** on sensitive uploads. ClamAV is free and self-hostable.
- **Set `Content-Disposition: attachment`** when serving uploaded files so the browser downloads them instead of rendering (prevents stored XSS via HTML/SVG uploads).

### Logging and monitoring for security

Beyond the audit log (which is for users), maintain operational security logs:

- **Log authentication events** — successful logins, failed logins, password resets, MFA challenges. These are the first thing you check in a breach investigation.
- **Log authorization failures** — 403 responses, permission denials. A spike in 403s from one user may indicate account probing.
- **Log rate-limit hits** — a spike indicates abuse or an attack.
- **Don't log sensitive data** — passwords, tokens, session IDs, PII. Log enough to investigate, not enough to compromise.
- **Centralize logs** — send to a log aggregator (Datadog, Grafana Loki, ELK, Axiom). Logs only on the server are logs you can't search.
- **Set up alerts** — alert on: failed login spikes, new admin user creation, permission escalation, unusual export patterns, rate-limit bursts.

### The security checklist

Run this alongside the verification checklist in `preflight-and-verification.md`:

- [ ] All cookies are `httpOnly`, `sameSite=lax`, `secure` (in production)
- [ ] CSP header is set and blocks inline scripts
- [ ] HSTS header is set with `max-age` >= 1 year
- [ ] `X-Content-Type-Options: nosniff` is set
- [ ] `X-Frame-Options: DENY` is set (or `frame-ancestors 'none'` in CSP)
- [ ] CORS allows only the dashboard's origin, not `*`
- [ ] No raw user input is rendered as HTML without sanitization
- [ ] All raw SQL uses parameterized queries
- [ ] Rate limiting is active on login, mutations, uploads, and exports
- [ ] `npm audit` (or equivalent) shows no critical/high vulnerabilities
- [ ] No secrets are committed to git (search for API keys, passwords, tokens)
- [ ] Environment variables with secrets are not exposed to the client bundle
- [ ] File uploads are validated by magic bytes, renamed, and stored outside the web root
- [ ] Error messages don't expose stack traces, library versions, or internal paths
- [ ] Operational security events are logged and alerting is configured

## Don'ts

- **Don't ship without security headers.** They're free and prevent entire classes of attacks.
- **Don't use `dangerouslySetInnerHTML` / `v-html` / `{@html}` on user content** without DOMPurify.
- **Don't concatenate user input into SQL.** Use parameterized queries.
- **Don't store secrets in git, even in "private" repos.** They get cloned, forked, and leaked.
- **Don't serve uploaded files from the same origin without Content-Disposition.** Stored XSS via SVG/HTML uploads.
- **Don't skip rate limiting** because "it's an internal tool." Internal tools get brute-forced too.
- **Don't load 2MB of JavaScript on the landing page.** Code-split by route. Lazy-load heavy libraries.
- **Don't `SELECT *` on list endpoints.** Select only what's needed.
- **Don't skip the bundle analyzer.** You'll be surprised what's in there.
- **Don't use `moment.js` in 2026.** Use `date-fns`, `dayjs`, or the `Intl` API.
- **Don't serve full-resolution images for 32px avatars.** Resize on upload or use a transform CDN.
- **Don't trust that your ORM prevents all injection.** Audit raw queries.
- **Don't treat internal dashboards as exempt from security.** Internal networks get compromised. Defense in depth applies everywhere.
