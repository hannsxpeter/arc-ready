# Expansion & Scalability Preparedness

A dashboard that works for 10 users and 3 features is a prototype. A dashboard that works for 10,000 users, 50 features, 12 languages, and 3 pricing tiers is a product. The difference is not "scale it later" — it's the architectural decisions you make in week one that determine whether scaling is a refactor or a rewrite.

This file covers what to build now, what to add hooks for, and what to defer entirely. The goal is zero rewrites as the product grows from MVP to enterprise.

---

## Part 1 — Multi-Tenancy and Org Scaling

Tenancy is a first-class dimension of your domain model. Every piece of data belongs to exactly one tenant. Every request runs with a tenant context. Every read/write path enforces that context. Every authorization decision evaluates within the tenant, not globally. If you skip this, you will rewrite your data layer.

### Tenant isolation patterns

Three patterns, each with distinct cost/compliance/performance tradeoffs:

| Pattern | Isolation | Cost per tenant | Migration complexity | Best for |
|---|---|---|---|---|
| **Shared DB, shared schema** (tenant_id column) | Lowest — row-level only | Cheapest | Easiest — one migration, all tenants | MVP, free tiers, < 1,000 tenants |
| **Schema-per-tenant** (tenant_a.projects, tenant_b.projects) | Medium — schema boundary | Moderate | Hard — N schemas x N migrations | Mid-market with compliance needs |
| **Database-per-tenant** (silo model) | Highest — full DB isolation | Most expensive | Hardest — N databases x N migrations | Enterprise, regulated industries (HIPAA, SOC2) |

**Decision rule:** Start with shared schema + tenant_id. Move enterprise customers to isolated schemas/databases when they ask (and pay for it). This hybrid model is now the most common pattern in mature SaaS.

### Row-Level Security (RLS) — build it from day one

PostgreSQL RLS is the standard for shared-schema tenancy. It enforces tenant isolation at the database level, not the application level. This means a bug in your application code cannot leak data across tenants.

```sql
-- Every table gets a tenant_id column
ALTER TABLE projects ADD COLUMN tenant_id UUID NOT NULL REFERENCES tenants(id);

-- Enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their tenant's data
CREATE POLICY tenant_isolation ON projects
  USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

Set `app.current_tenant` at the beginning of every request in your middleware. Every query automatically filters by tenant. No WHERE clause required in application code, no risk of forgetting one.

**Do this now.** Retrofitting RLS onto an existing database with millions of rows and hundreds of queries is a 3-6 month project. Adding it on day one costs hours.

### Org hierarchy — when to introduce each level

Don't over-engineer your hierarchy. Add levels only when the lack of them becomes painful.

| Level | When to introduce | Examples |
|---|---|---|
| **Single org** (all users in one flat space) | Day one — MVP | Most products at launch |
| **Teams within an org** | 10+ users per org, distinct departments | Linear, Notion, Slack |
| **Workspaces** (isolated orgs under one billing entity) | Enterprise customers with multiple business units | Slack Enterprise Grid, Notion teamspaces |
| **Projects within teams** | Teams working on 5+ parallel streams | Linear projects, Jira projects |

The pattern from Slack, Notion, and Linear: start with a flat org, add teams when customers with 10+ users complain about noise, add workspaces when enterprise customers need isolated data boundaries under one billing account. The team-owner role pattern (used by Linear) sits between member and admin — team leads manage their own domain without workspace-wide admin access.

**Build now:** Org with members. **Add hooks for:** Teams (a `team_id` foreign key you don't populate yet). **Defer:** Workspaces and cross-org collaboration.

### Tenant-level customization

**Branding (white-labeling):** Store theme configuration as JSON per tenant — logo URL, primary/accent colors, font family. Serve it at the layout level. Use CSS custom properties so one JSON object drives the entire visual layer. Don't embed brand values deep in component code.

```json
{
  "tenant_id": "abc-123",
  "branding": {
    "logo_url": "https://cdn.example.com/acme/logo.svg",
    "primary_color": "#1a73e8",
    "accent_color": "#fbbc04",
    "font_family": "Inter, sans-serif"
  }
}
```

**Custom domains:** Use subdomain-based tenant resolution (acme.yourapp.com) as the default. Support custom domains (app.acme.com) for enterprise tiers. Provision TLS certs automatically with Let's Encrypt / Caddy / Cloudflare for SaaS.

**Custom fields:** Covered in detail in the Feature Expansion section below.

### Data partitioning as tenant count grows

| Tenant count | Strategy |
|---|---|
| < 100 | Shared DB, shared schema. Single Postgres instance. |
| 100 - 10,000 | Shared schema with connection pooling (PgBouncer / Supavisor). Read replicas for analytics. |
| 10,000 - 100,000 | Shard by tenant_id. Use Citus for Postgres or partition tables by tenant_id hash. |
| 100,000+ | Tenant-aware routing layer. Hot tenants get dedicated resources. Cold tenants stay on shared pools. |

**Build now:** Tenant_id on every table, RLS policies, connection pooling. **Defer:** Sharding, Citus, dedicated tenant infrastructure.

---

## Part 2 — Feature Expansion Patterns

The wrong architecture makes adding feature #6 as hard as building the whole product. The right architecture makes feature #50 a config change.

### Feature flag systems

Feature flags are not optional. They decouple deployment from release, enable gradual rollout, and let you kill bad features without a redeploy.

**Rollout strategy:**

| Stage | Percentage | Duration | Purpose |
|---|---|---|---|
| Internal dogfooding | 0% (team-only) | 1-2 weeks | Catch obvious bugs |
| Canary | 1-5% of users | 3-7 days | Catch edge cases at scale |
| Early access | 10-25% | 1-2 weeks | Validate value with real usage |
| General availability | 50% then 100% | 1 week | Monitor for performance regression |

**Tool selection:**

| Tool | Best for | Pricing |
|---|---|---|
| **LaunchDarkly** | Enterprise, complex targeting, experimentation | $$$$ (starts ~$10/seat/mo) |
| **Flagsmith** | Open-source option, self-hosted or cloud | Free tier, paid cloud |
| **Unleash** | Open-source, Kubernetes-native | Free self-hosted, paid cloud |
| **PostHog** | Combined flags + analytics + session replay | Free tier, usage-based |
| **Custom (DB + cache)** | Simple boolean flags, < 20 flags | Free but maintenance cost |

For early-stage products: PostHog or Flagsmith. For enterprise: LaunchDarkly. Don't build a custom system until you have a specific reason the off-the-shelf options don't work — the maintenance cost of retry logic, caching, audit trails, and targeting rules is higher than the subscription.

LaunchDarkly delivers flag updates to all clients within 200ms via server-sent events (SSE). If you build custom, you need to match this — stale flags are worse than no flags.

### Plugin/extension architecture

Don't build a plugin system until you have 3+ customers asking for the same integration you can't prioritize. The progression:

1. **Webhooks** (build first) — let customers react to events in their own systems
2. **REST/GraphQL API** (build second) — let customers read/write your data
3. **Embed SDK** (build when needed) — let customers embed your UI in their product
4. **Plugin marketplace** (build last) — let third parties build and distribute extensions

The marketplace pattern: define a plugin manifest (JSON schema for permissions, hooks, UI injection points), a sandboxed execution environment (iframe or Web Worker for frontend, Lambda/container for backend), and a review/approval pipeline. Shopify, Figma, and Linear all follow this pattern.

**Build now:** Webhooks + API. **Add hooks for:** Plugin manifest schema. **Defer:** Marketplace, plugin review pipeline.

### Module-based architecture (lazy-loaded features)

Every feature should be a lazy-loaded module. The user loading the CRM should not download the code for the billing dashboard.

```tsx
// Feature registry — config-driven
const FEATURES = {
  crm:      { path: '/crm',      loader: () => import('./features/crm') },
  billing:  { path: '/billing',  loader: () => import('./features/billing') },
  reports:  { path: '/reports',   loader: () => import('./features/reports') },
  ai_chat:  { path: '/ai',       loader: () => import('./features/ai-chat') },
};

// Only registered + enabled features get routes
const enabledFeatures = features.filter(f => tenant.enabledFeatures.includes(f.id));
```

This gives you: per-tenant feature gating (admin toggles features on/off), lazy loading (unused features never download), and clean boundaries between feature teams.

### Configuration-driven UI

Store feature availability per tenant in the database, not in code:

```json
{
  "tenant_id": "abc-123",
  "enabled_features": ["crm", "billing", "reports"],
  "disabled_features": ["ai_chat"],
  "feature_limits": {
    "crm.contacts": 10000,
    "reports.scheduled": 5
  }
}
```

The admin panel reads this config to show/hide navigation items, enable/disable functionality, and enforce limits. Adding a new feature means adding a row to the feature registry — no code deployment required to enable it for specific tenants.

### Custom fields and user-defined schemas

Users will ask for custom fields. Three approaches:

| Approach | Performance | Flexibility | Query complexity | Best for |
|---|---|---|---|---|
| **JSONB column** | Good (with GIN index) | High | Moderate (JSON operators) | Most SaaS products |
| **EAV tables** (entity-attribute-value) | Poor at scale | Highest | High (many JOINs) | Legacy — avoid for new builds |
| **Dedicated columns** (ALTER TABLE per field) | Best | Lowest | Simplest | < 50 custom fields total |

**Use JSONB.** PostgreSQL JSONB with GIN indexes outperforms EAV by orders of magnitude and avoids the join explosion. Store custom field definitions in a `custom_field_definitions` table (name, type, validation rules, tenant_id) and values in a `custom_data JSONB` column on the entity table.

```sql
-- Custom field definition
CREATE TABLE custom_field_definitions (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  entity_type TEXT NOT NULL,  -- 'contact', 'deal', etc.
  field_name TEXT NOT NULL,
  field_type TEXT NOT NULL,   -- 'text', 'number', 'date', 'select'
  options JSONB,              -- for select fields: ["Option A", "Option B"]
  required BOOLEAN DEFAULT FALSE
);

-- Entity with custom data
ALTER TABLE contacts ADD COLUMN custom_data JSONB DEFAULT '{}';
CREATE INDEX idx_contacts_custom_data ON contacts USING GIN (custom_data);
```

**Build now:** JSONB column + custom field definition table. **Defer:** Custom field UI builder, cross-field validation rules, custom field reporting.

---

## Part 3 — Internationalization (i18n) Preparedness

i18n is the single most expensive thing to retrofit. A product with 200 screens and hardcoded strings takes 2-4 months to internationalize. A product that extracts strings from day one takes 2-4 days to add a new language.

### String extraction — do this from day one

Even if you launch in English only. Every user-facing string goes through a translation function. No exceptions.

```tsx
// Wrong — hardcoded string
<Button>Save changes</Button>

// Right — extracted string
<Button>{t('common.save_changes')}</Button>
```

**Key naming convention:** Use dot-separated namespaces that match your feature structure.

```
common.save           // shared across features
common.cancel
common.delete_confirm // "Are you sure you want to delete {name}?"
crm.contacts.title    // feature-specific
crm.contacts.empty_state
billing.plan.upgrade_cta
```

**Libraries:**
- **React** — react-i18next (recommended), react-intl
- **Vue** — vue-i18n
- **Svelte** — svelte-i18n
- **Next.js** — next-intl (App Router native), next-i18next (Pages Router)

Store translations in JSON files per locale (`en.json`, `fr.json`, `de.json`). Use a translation management platform (Crowdin, Phrase, Lokalise) once you have > 500 strings — manual JSON editing doesn't scale.

### RTL layout support preparation

You don't need to build full RTL support on day one. But you need to not make it impossible.

**Do now:**
- Use CSS logical properties everywhere: `margin-inline-start` not `margin-left`, `padding-block-end` not `padding-bottom`
- Use `flexbox` and `grid` — they respect `dir="rtl"` automatically
- Never use `float: left` for layout (use flexbox)
- Set `dir` attribute at the `<html>` level based on locale

**Don't do:**
- Hardcoded `px` values for left/right positioning
- Absolute positioning for layout elements
- Icon arrows that assume left-to-right flow (use a mirroring class)

German text is 15-30% longer than English. Arabic and Hebrew read right-to-left. Japanese uses different line-breaking rules. Design for flexibility: avoid fixed-width containers for text, use `min-width` instead of `width`, and test with 2x-length pseudo-translations during development.

### Currency, date, and number formatting

Use the `Intl` API — it's built into every modern browser and Node.js. Don't build custom formatters.

```tsx
// Currency — respects locale automatically
new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(1234.56)
// → "1.234,56 €"

// Date — locale-aware
new Intl.DateTimeFormat('ja-JP', { dateStyle: 'long' }).format(new Date())
// → "2026年4月12日"

// Number — locale-aware separators
new Intl.NumberFormat('en-IN').format(1234567)
// → "12,34,567" (Indian numbering system)
```

**Store dates as UTC timestamps in the database.** Display in the user's local timezone. Never store formatted date strings. Use `Intl.DateTimeFormat` or `date-fns` with timezone support for display.

### Timezone handling at scale

| Layer | Rule |
|---|---|
| **Database** | Store all timestamps as `TIMESTAMPTZ` (UTC). Never `TIMESTAMP` without timezone. |
| **API** | Send/receive ISO 8601 with timezone offset: `2026-04-12T14:30:00Z` |
| **Server** | All logic runs in UTC. Convert to user timezone only at the display layer. |
| **Client** | Detect timezone from browser (`Intl.DateTimeFormat().resolvedOptions().timeZone`). Store user preference. Display in user's timezone. |
| **Scheduled jobs** | Store in UTC. Convert at send time. A "9am daily email" runs at 9am in the user's timezone, not 9am UTC. |

**Build now:** UTC everywhere, Intl API formatting, user timezone preference. **Defer:** Content translation workflow, translation memory, locale-aware search.

---

## Part 4 — API and Integration Scalability

Your API is a contract with every customer who integrates with you. Breaking changes lose customers. Not versioning loses trust. Not rate-limiting loses uptime.

### API versioning — do it from the start

Pick a strategy and stick with it:

| Strategy | Example | Pros | Cons |
|---|---|---|---|
| **URL path** (recommended) | `/api/v1/contacts` | Clear, easy to route, easy to cache | New endpoints per version |
| **Header-based** | `Accept: application/vnd.api+json; version=2` | Clean URLs | Hidden, harder to test in browser |
| **Query parameter** | `/api/contacts?version=2` | Simple | Complicates caching |

**Use URL path versioning.** It's the most widely understood, the easiest to route at the load balancer level, and every developer who hits your API docs will understand it immediately.

**Version policy:**
- Support the current version and one prior version
- Deprecation warning headers 6 months before shutdown (`Sunset: Sat, 01 Jan 2028 00:00:00 GMT`)
- Breaking changes only in new major versions
- Additive changes (new fields, new endpoints) are non-breaking — ship them anytime

### Webhook system architecture

Build a webhook delivery system, not just webhook endpoints. The difference is retry logic, delivery guarantees, and observability.

**Core components:**

1. **Event bus** — internal pub/sub that fires when state changes (order.created, user.updated)
2. **Subscription store** — which tenant wants which events delivered where
3. **Delivery queue** — async job queue (BullMQ/Redis, SQS) that processes deliveries
4. **Retry policy** — exponential backoff: 1min, 5min, 30min, 2hr, 24hr, then dead-letter
5. **Signature verification** — HMAC-SHA256 signature on every payload so receivers can verify authenticity
6. **Delivery log** — every attempt recorded with status code, latency, response body (truncated)

**Payload structure:**

```json
{
  "id": "evt_abc123",
  "type": "contact.updated",
  "created_at": "2026-04-12T14:30:00Z",
  "data": {
    "id": "con_xyz789",
    "name": "Jane Doe",
    "email": "jane@example.com"
  },
  "previous_data": {
    "name": "Jane Smith"
  }
}
```

Include `previous_data` for update events. Customers need to know what changed, not just the current state. Include an idempotency key (`id` field) so receivers can deduplicate.

### Rate limiting that scales with plan tiers

Rate limiting is a control plane, not a guardrail. Combine global, tenant, user, and endpoint limits:

| Tier | Requests/min | Burst | Concurrent |
|---|---|---|---|
| Free | 60 | 10 | 5 |
| Pro | 600 | 50 | 25 |
| Enterprise | 6,000 | 200 | 100 |
| Custom | Negotiated | Negotiated | Negotiated |

Use sliding window rate limiting (not fixed window — it prevents burst-at-boundary attacks). Return standard headers:

```
X-RateLimit-Limit: 600
X-RateLimit-Remaining: 423
X-RateLimit-Reset: 1712937600
Retry-After: 30
```

Implement with Redis + sliding window algorithm. Store limits in the tenant config so plan changes take effect immediately.

### GraphQL vs REST — when to use which

| Factor | REST | GraphQL |
|---|---|---|
| **Public API** | Better — universally understood, easy to cache | Harder for external developers |
| **Internal API** (web + mobile clients) | Requires multiple endpoints or BFF | Better — clients fetch exactly what they need |
| **Caching** | HTTP caching works natively | Requires client-side cache (Apollo, urql) |
| **Schema evolution** | Requires versioning | Fields added/deprecated without versioning |
| **Tooling** | Mature, well-understood | Strong but smaller ecosystem |
| **File uploads** | Standard multipart | Requires workarounds |
| **Real-time** | Requires separate WebSocket setup | Subscriptions built-in |

**Recommendation:** REST for public API (customer integrations). GraphQL for internal API (your own web and mobile clients). This is the pattern used by Shopify, GitHub, and most mature SaaS platforms — GraphQL internally for flexible data fetching, REST externally for simplicity and compatibility.

### OAuth provider expansion

Build your auth layer to support multiple providers from day one:

```
auth_providers table:
  id, tenant_id, provider_type (google, github, saml, oidc),
  client_id, client_secret (encrypted), config JSONB, enabled BOOLEAN
```

Use a provider-agnostic auth library (NextAuth/Auth.js, Clerk, WorkOS) that supports adding new providers without code changes. Store provider config per tenant so enterprise customers can bring their own IdP.

**Build now:** Email/password + Google OAuth. **Add hooks for:** SAML/OIDC config table. **Defer:** Custom IdP per tenant, SCIM provisioning.

---

## Part 5 — Data Layer Expansion

### Schema evolution without downtime

Use the expand-contract pattern. Never make breaking schema changes in a single deployment.

**The three phases:**

1. **Expand** — Add new columns/tables alongside existing ones. Old code is unaware and keeps working.
2. **Migrate** — Deploy code that writes to both old and new. Backfill existing data in batches (1,000-10,000 rows per batch, not all at once).
3. **Contract** — Remove old columns/tables after all code uses the new ones.

**Example: Renaming a column from `name` to `display_name`**

```
Deploy 1: ALTER TABLE users ADD COLUMN display_name TEXT;
          -- Backfill: UPDATE users SET display_name = name WHERE display_name IS NULL (in batches)
          -- Deploy trigger: sync writes to both columns

Deploy 2: Update application code to read from display_name, write to both

Deploy 3: Update application code to only use display_name

Deploy 4: ALTER TABLE users DROP COLUMN name;
```

Each deploy is independently rollback-safe. If Deploy 2 fails, roll back to Deploy 1 — the old column still works.

**Tools:** pgroll (open-source, automates expand-contract for Postgres), Flyway, Liquibase, or Drizzle Kit with manual expand-contract discipline.

**Rules for safe migrations:**
- Adding a nullable column: always safe
- Adding a column with a default: safe in Postgres 11+ (no table rewrite)
- Adding a NOT NULL constraint: unsafe without backfill first
- Dropping a column: only after all code stops referencing it
- Renaming a column: expand-contract, never a direct rename
- Adding an index: use `CREATE INDEX CONCURRENTLY` (Postgres) — non-blocking

### Adding new entity types

Design your data model to expect new entity types without breaking existing ones.

**Pattern: Entity-type registry**

```sql
CREATE TABLE entity_types (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  name TEXT NOT NULL,        -- 'contact', 'deal', 'ticket'
  schema JSONB NOT NULL,     -- field definitions
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

New entity types are rows, not new tables. Custom fields attach to entity types via the JSONB pattern described in Part 2. This means customers can define their own entity types without schema migrations.

### Audit trail — from day one

Every mutation (create, update, delete) should produce an audit record. This is not optional — enterprise customers require it, compliance demands it, and debugging without it is blind.

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action TEXT NOT NULL,         -- 'created', 'updated', 'deleted'
  actor_id UUID NOT NULL,       -- who did it
  actor_type TEXT NOT NULL,     -- 'user', 'api_key', 'system'
  changes JSONB,                -- { "name": { "old": "Jane", "new": "Jane Doe" } }
  metadata JSONB,               -- IP address, user agent, request ID
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for common queries
CREATE INDEX idx_audit_entity ON audit_log (tenant_id, entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_log (tenant_id, actor_id);
CREATE INDEX idx_audit_time ON audit_log (tenant_id, created_at);
```

**Write audit logs asynchronously** — don't slow down the user's mutation. Use a background job or database trigger. Partition the audit_log table by month once it exceeds 10M rows.

### Soft delete — never hard delete

Every table gets `deleted_at TIMESTAMPTZ NULL`. A row with `deleted_at IS NOT NULL` is "deleted." Every query includes `WHERE deleted_at IS NULL` (enforce this with a view or RLS policy so developers can't forget).

```sql
-- Soft delete columns on every table
ALTER TABLE contacts ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE contacts ADD COLUMN deleted_by UUID;

-- View that hides deleted rows (use this for all application queries)
CREATE VIEW active_contacts AS
  SELECT * FROM contacts WHERE deleted_at IS NULL;
```

**Why soft delete:**
- Undo is trivial — set `deleted_at = NULL`
- Audit trail preserves the full record
- Foreign key integrity is maintained
- GDPR "right to erasure" can be handled by a separate hard-delete job that runs after the retention period
- Debugging data issues is possible because the data still exists

**Archive strategy:** Move rows with `deleted_at` older than 90 days to an archive table or cold storage. Move rows with `updated_at` older than 2 years to a read-only archive database. This keeps the primary database fast.

### Search infrastructure — when to add it

| Stage | Records | Solution |
|---|---|---|
| MVP | < 10,000 | PostgreSQL `ILIKE` or `tsvector` full-text search |
| Growth | 10,000 - 500,000 | PostgreSQL full-text search with `GIN` indexes + `ts_rank` |
| Scale | 500,000 - 5M | Typesense or Meilisearch (simpler, faster setup) |
| Enterprise | 5M+ | Elasticsearch (distributed, complex queries, aggregations) |

**Typesense** keeps the entire index in RAM — sub-50ms queries, built-in clustering, predictable pricing. Best for most SaaS products.

**Meilisearch** uses memory-mapped disk storage — handles larger datasets without proportional RAM costs. Best for content-heavy products.

**Elasticsearch** is justified only when you need distributed search across multiple nodes, complex aggregations, or billions of documents. Its operational complexity and cost (often five to six figures annually) make it the wrong default.

**Build now:** PostgreSQL full-text search. **Add hooks for:** A search abstraction layer so you can swap the backend later. **Defer:** Elasticsearch/Typesense deployment until PostgreSQL search becomes the bottleneck (you'll know because search queries exceed 200ms at p95).

---

## Part 6 — UI/UX Expansion Preparedness

### Navigation patterns that accommodate growth

A sidebar with 5 items is clean. A sidebar with 25 items is a wall of text. Design for both.

**Sidebar architecture:**

```
Primary nav (always visible):     5-7 items max
  - Dashboard
  - Contacts / [Core entity]
  - Reports
  - Settings
  + More (collapsible section)

Collapsible sections:             grouped by domain
  - Sales: Deals, Pipeline, Forecasts
  - Marketing: Campaigns, Forms, Landing Pages

Command palette (Cmd+K):          everything searchable
  - Navigate to any page
  - Execute actions (create contact, export report)
  - Search entities
```

**Sidebar width:** 240-280px. Collapsible to icon-only (64px) on small screens or user preference. Store collapsed state per user in localStorage.

**The command palette is not optional** once you exceed 10 navigation destinations. It's the fastest way for power users to navigate, and it scales infinitely — adding a new feature means adding an entry to the command registry, not rethinking the sidebar.

Use a config-driven navigation structure:

```tsx
const NAV_ITEMS = [
  { id: 'dashboard', label: t('nav.dashboard'), icon: Home, path: '/' },
  { id: 'contacts',  label: t('nav.contacts'),  icon: Users, path: '/contacts',
    requiredFeature: 'crm' },
  { id: 'billing',   label: t('nav.billing'),    icon: CreditCard, path: '/billing',
    requiredFeature: 'billing', requiredRole: 'admin' },
];

// Filter by tenant features + user role
const visibleItems = NAV_ITEMS.filter(item =>
  (!item.requiredFeature || tenant.features.includes(item.requiredFeature)) &&
  (!item.requiredRole || user.roles.includes(item.requiredRole))
);
```

### Component library / design system investment

Invest in a design system from day one. Not a comprehensive one — start with these foundational components:

**Build immediately (week 1):**
- Button (primary, secondary, ghost, destructive variants)
- Input, Select, Textarea, Checkbox, Radio
- Card, Table, Modal/Dialog
- Toast/notification system
- Loading skeleton

**Build by month 2:**
- DataTable with sorting, filtering, pagination
- Form system with validation
- Empty state component
- Error boundary with fallback UI
- Dropdown menu, command palette

**Build when needed:**
- Chart components (wrap a library — Recharts, Chart.js, or Nivo)
- Rich text editor (wrap Tiptap or ProseMirror)
- Date/time pickers (wrap a library)
- File upload with drag-and-drop

**Use shadcn/ui as a foundation** (React/Next.js). It gives you unstyled, accessible primitives built on Radix UI that you own (copied into your codebase, not a dependency). This means you can customize everything without fighting a library's opinions.

### Layout patterns that scale

**The three-panel layout** (sidebar + list + detail) works from 5 features to 50 features. Gmail, Linear, and Notion all use it.

**Card-based metric strips** (4-6 KPI cards) work for dashboards with 3 metrics and dashboards with 30 — users scroll horizontally or the grid wraps.

**Tab-based sub-navigation** keeps feature pages organized without sidebar bloat. A contact detail page with 3 tabs (Overview, Activity, Files) works identically with 10 tabs.

Use CSS Grid with `auto-fill` for responsive layouts that accommodate new content without layout rework:

```css
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1rem;
}
```

### White-labeling preparation

Store all brand-able values in a tenant config object, not scattered through the codebase:

- **CSS custom properties** for colors, fonts, spacing
- **Config object** for logo, favicon, app name, support email
- **Template system** for emails (company name, logo, colors pulled from tenant config)

```css
:root {
  --brand-primary: var(--tenant-primary, #1a73e8);
  --brand-accent: var(--tenant-accent, #fbbc04);
  --brand-font: var(--tenant-font, 'Inter, sans-serif');
}
```

**Build now:** CSS custom properties, tenant config schema. **Defer:** Full white-label UI builder, custom email templates per tenant.

### Accessibility as a foundation

Accessibility is not a retrofit. It's a foundation. Every component you build without accessibility is a component you'll rebuild.

**Non-negotiable from day one:**
- All interactive elements keyboard-accessible (Tab, Enter, Escape, Arrow keys)
- All images have alt text (or `aria-hidden` for decorative)
- All form inputs have labels (visible or `aria-label`)
- Color contrast meets WCAG 2.1 AA (4.5:1 for text, 3:1 for large text/UI)
- Focus indicators visible (never `outline: none` without a replacement)
- ARIA roles on custom components (dialog, menu, tablist, alert)
- Screen reader announcements for dynamic content (live regions)
- Reduced motion preference respected (`prefers-reduced-motion` media query)

**Test with:** axe-core (automated), keyboard-only navigation (manual), VoiceOver/NVDA (screen reader).

---

## Part 7 — Performance at Scale

### Pagination patterns

| Pattern | Best for | Performance at depth | Supports total count |
|---|---|---|---|
| **Offset** (`LIMIT 50 OFFSET 500`) | Admin tables, small datasets (< 10K rows) | Degrades — 17x slower at page 100 vs page 1 | Yes |
| **Cursor** (`WHERE id > :cursor LIMIT 50`) | Feeds, large datasets, real-time data | Constant O(1) regardless of depth | No (expensive to compute) |
| **Keyset** (`WHERE (created_at, id) > (:ts, :id) LIMIT 50`) | Time-ordered data with ties | Constant, handles duplicates | No |

**Default to cursor-based pagination** for any list that might exceed 10,000 records. Use offset only for admin interfaces where users need to jump to page 47.

For total counts: cache the count and accept staleness (update every 5 minutes), or show "1,000+" instead of an exact number. `SELECT COUNT(*)` on a 1M-row table takes 200-500ms in Postgres — don't run it on every page load.

### Caching strategies

| Layer | Tool | Cache duration | Invalidation |
|---|---|---|---|
| **Browser** | HTTP cache headers (Cache-Control, ETag) | Static assets: 1 year. API: no-cache with ETag. | ETag changes on data change |
| **CDN** | Cloudflare, CloudFront, Vercel Edge | Static assets: immutable. HTML: short (60s) or stale-while-revalidate. | Purge on deploy. API: bypass CDN. |
| **Application** | Redis, Memcached | Varies: 5min for lists, 1hr for config, 24hr for computed aggregations | Invalidate on write (explicit key deletion) |
| **Query** | TanStack Query, SWR | `staleTime: 30s`, `gcTime: 5min` | Invalidate after mutations |
| **Database** | Materialized views, pg_stat_statements | Refresh on schedule (every 5-15 min for dashboards) | Refresh manually or on trigger |

**Cache dashboard aggregations aggressively.** A "total revenue this month" query doesn't need to be real-time — 5-minute staleness is acceptable. Pre-compute expensive aggregations in materialized views and refresh them on a schedule.

### Real-time features at scale

| Users | Approach |
|---|---|
| < 1,000 concurrent | Single WebSocket server (Socket.io, ws) |
| 1,000 - 50,000 | Redis Pub/Sub for cross-server message distribution |
| 50,000 - 500,000 | Dedicated real-time infrastructure (Ably, Pusher, Liveblocks) |
| 500,000+ | Custom infrastructure with connection pooling, presence management |

**Don't build real-time infrastructure.** Use a managed service (Ably, Pusher, Supabase Realtime, Liveblocks) until you have a specific cost or latency reason to bring it in-house. Building WebSocket connection management, heartbeats, reconnection logic, presence tracking, and horizontal scaling is months of work.

**What to make real-time (and what not to):**
- **Yes:** Notifications, collaborative editing cursors, chat messages, status indicators
- **No:** Dashboard charts (poll every 30-60s instead), list views (refetch on focus), settings pages
- **Maybe:** Activity feeds (real-time if social, polling if audit log)

### Background job architecture

Use a job queue for anything that takes > 500ms or can fail independently of the user's request.

**Common background jobs in SaaS:**
- Email sending (always async — never block a request on SMTP)
- Report generation and export
- Webhook delivery
- Data import/export
- Billing metering aggregation
- Search index updates
- Scheduled tasks (daily digests, usage alerts)

**Stack:** BullMQ + Redis (Node.js). Celery + Redis/RabbitMQ (Python). Sidekiq + Redis (Ruby). For any stack: managed queues (AWS SQS, Google Cloud Tasks) avoid operational overhead.

BullMQ provides: job priorities, delayed jobs, rate limiting per queue, retries with exponential backoff, and a monitoring dashboard (bull-board). It's rebuilt in TypeScript and uses Redis Streams for reliability.

**Job design rules:**
- Jobs must be idempotent (safe to retry)
- Jobs must be small (< 30 seconds — break large tasks into batches)
- Jobs must record their outcome (success/failure/error) for observability
- Dead-letter queue for jobs that fail after all retries

### File storage and CDN

- **User uploads** go to object storage (S3, R2, GCS) — never the application server's filesystem
- **Generate signed URLs** for private files (expire in 1-24 hours)
- **Serve public assets through a CDN** — immutable filenames (`logo-abc123.png`), `Cache-Control: public, max-age=31536000, immutable`
- **Process images on upload** — generate thumbnails, compress to WebP, strip EXIF data
- **Set file size limits per plan tier** — Free: 10MB/file, 1GB total. Pro: 100MB/file, 50GB total. Enterprise: negotiated.

---

## Part 8 — Billing and Plan Expansion

### Pricing architecture

67% of SaaS companies now use some form of usage-based pricing. Hybrid models (subscription base + usage) deliver ~21% median revenue growth vs ~13% for pure subscription. Design your billing system to support all three models from the start.

| Model | Best for | Complexity | Example |
|---|---|---|---|
| **Seat-based** | Collaboration tools, low per-user cost | Low | $10/user/month |
| **Feature-gated** | Products with distinct tiers | Medium | Free (3 projects), Pro (unlimited + API), Enterprise (SSO + audit) |
| **Usage-based** | API products, compute/storage | High | $0.01/API call, $0.10/GB stored |
| **Hybrid** (recommended) | Most SaaS | Medium-High | $49/mo base + $0.01/API call over 10K |

**The billing data model:**

```sql
-- Plans define what's available
CREATE TABLE plans (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,           -- 'free', 'pro', 'enterprise'
  base_price_cents INTEGER,     -- 0, 4900, 19900
  billing_interval TEXT,        -- 'monthly', 'yearly'
  features JSONB,               -- {"api_access": true, "sso": false, "max_seats": 5}
  usage_limits JSONB            -- {"api_calls": 10000, "storage_gb": 5}
);

-- Subscriptions track what tenants have
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  plan_id UUID NOT NULL,
  status TEXT NOT NULL,          -- 'active', 'trialing', 'past_due', 'canceled'
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  stripe_subscription_id TEXT
);

-- Usage metering (high-volume — consider TimescaleDB)
CREATE TABLE usage_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  event_type TEXT NOT NULL,      -- 'api_call', 'storage_upload', 'ai_generation'
  quantity INTEGER DEFAULT 1,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Usage tracking and metering

Metering must be: real-time (users see current usage), accurate (billing disputes are expensive), and high-throughput (API call counting can be millions of events/day).

**Architecture:**
1. **Ingest** — fire-and-forget event from application code to a queue (Redis stream, Kafka)
2. **Aggregate** — background worker rolls up raw events into hourly/daily buckets
3. **Query** — API reads aggregated buckets for display and billing
4. **Bill** — at period end, pull aggregated usage, calculate charges, send to Stripe/billing provider

Don't count in the hot path. Increment a Redis counter on each event, flush to the database in batches every minute. This handles millions of events/day without slowing down the application.

### Plan changes mid-cycle

- **Upgrade:** Apply immediately. Prorate the remaining days of the current period. Stripe handles this natively with `proration_behavior: 'create_prorations'`.
- **Downgrade:** Apply at the end of the current billing period. Don't yank features mid-cycle — that generates support tickets.
- **Cancel:** Set `cancel_at_period_end = true`. Keep access until the period ends. Send a "we miss you" email 3 days before access ends.

### Free tier to paid conversion

| Metric | Target | How to measure |
|---|---|---|
| Free-to-paid conversion rate | 2-5% (self-serve), 10-15% (sales-assisted) | Monthly signups / monthly upgrades |
| Time to conversion | 14-30 days median | Signup date to upgrade date |
| Activation rate | > 40% within 7 days | Users who complete the "aha moment" action |

**Design the free tier to create upgrade pressure:**
- Limit the resource that scales with value (contacts, API calls, seats), not the features that demonstrate value (don't hide the best features behind the paywall — let users see what they're missing)
- Show usage meters prominently: "You've used 847 of 1,000 contacts"
- Trigger upgrade prompts at 80% of limits, not at 100%
- Make the upgrade flow < 3 clicks: see limit warning, click upgrade, confirm plan, done

---

## Part 9 — Team and Role Expansion

### RBAC that scales

Start simple. Flat roles with explicit permissions beat nested hierarchies.

**Phase 1 (MVP) — three built-in roles:**

| Role | Permissions |
|---|---|
| **Owner** | Everything, including billing and danger zone |
| **Admin** | Manage members, settings, all data — no billing |
| **Member** | CRUD on data they own or are assigned to |

**Phase 2 (Growth) — add Viewer and custom roles:**

| Role | Permissions |
|---|---|
| **Viewer** | Read-only access, no mutations |
| **Custom** | Admin-defined permission sets |

**Phase 3 (Enterprise) — add team-level roles and scoping:**

Permissions scoped to teams/projects, not just the org. A "CRM Admin" can manage contacts but can't see billing. A "Marketing Viewer" can see campaigns but can't edit them.

**Permission model:**

```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  name TEXT NOT NULL,
  is_system BOOLEAN DEFAULT FALSE,  -- built-in roles can't be deleted
  permissions JSONB NOT NULL
  -- {"contacts.read": true, "contacts.write": true, "billing.read": false}
);

CREATE TABLE role_assignments (
  user_id UUID NOT NULL,
  role_id UUID NOT NULL,
  scope_type TEXT,     -- NULL (org-wide), 'team', 'project'
  scope_id UUID,       -- NULL (org-wide), or team_id/project_id
  PRIMARY KEY (user_id, role_id, scope_type, scope_id)
);
```

**Permission resolution:** Check org-level role first, then team-level role. Permissions are additive — if a user has "contacts.read" at the org level and "contacts.write" at the team level, they can read org-wide and write within that team.

Avoid deeply nested role hierarchies. Most organizations are better served by flat role structures with explicit permission assignments. When roles inherit from other roles, permission troubleshooting becomes exponentially more complex.

### SSO and SCIM provisioning

**SSO (Single Sign-On):**
- Support SAML 2.0 and OIDC — enterprise customers require one or both
- Use a library (WorkOS, Auth0, Clerk) — implementing SAML from scratch takes 2-4 weeks and has subtle security pitfalls
- Store SSO config per tenant: IdP metadata URL, entity ID, certificate, attribute mapping
- Enforce SSO-only login for enterprise orgs (disable password login when SSO is active)

**SCIM (System for Cross-domain Identity Management):**
- SCIM automates user provisioning/deprovisioning — when someone joins or leaves in the IdP (Okta, Azure AD, Google Workspace), your app creates/deactivates their account automatically
- Essential for enterprise sales — companies with 100+ employees won't manually manage users
- SCIM syncs role assignments from the IdP — map IdP groups to your app's roles
- When a user's role changes in the IdP, SCIM updates their access across all connected apps

**Build now:** Email/password + social login (Google). **Add hooks for:** SSO config table per tenant. **Defer:** SCIM endpoint implementation, SSO-only enforcement.

### API key management

```sql
CREATE TABLE api_keys (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  name TEXT NOT NULL,           -- "Production API Key", "CI/CD Key"
  key_hash TEXT NOT NULL,       -- bcrypt hash — never store the raw key
  key_prefix TEXT NOT NULL,     -- "sk_live_abc..." for identification
  scopes JSONB,                 -- ["contacts.read", "contacts.write"]
  created_by UUID NOT NULL,
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ
);
```

Show the full key only once at creation. Store only the hash. Display the prefix (`sk_live_abc...`) for identification. Support scoped permissions per key. Track last-used timestamps for security audits.

---

## Part 10 — Operational Expansion

### Monitoring and observability — from day one

You cannot scale what you cannot see. Instrument before you need it, not after the first outage.

**The three pillars:**

| Pillar | What | Tool |
|---|---|---|
| **Metrics** | Numeric measurements over time (request rate, error rate, latency, CPU, memory) | Datadog, Prometheus + Grafana, CloudWatch |
| **Logs** | Structured event records (JSON, not plaintext) | Datadog, Loki + Grafana, CloudWatch Logs |
| **Traces** | Request flow across services (which service took how long) | Datadog APM, Jaeger, Honeycomb |

**Essential metrics to track from day one:**

| Metric | Alert threshold | Why |
|---|---|---|
| API error rate (5xx) | > 1% of requests | Something is broken |
| API latency (p95) | > 2s | Users are waiting |
| API latency (p99) | > 5s | Worst-case is terrible |
| Database query time (p95) | > 500ms | Slow query detected |
| Background job failure rate | > 5% | Jobs are silently failing |
| Queue depth | > 1,000 (growing) | Processing can't keep up |
| Disk usage | > 80% | Running out of space |
| Memory usage | > 85% | OOM kill incoming |

**Structured logging:** Every log entry should be JSON with: `timestamp`, `level`, `message`, `request_id`, `tenant_id`, `user_id`, `duration_ms`. Structured logs are searchable. Plaintext logs are not.

```json
{
  "timestamp": "2026-04-12T14:30:00.123Z",
  "level": "error",
  "message": "Failed to send webhook",
  "request_id": "req_abc123",
  "tenant_id": "ten_xyz789",
  "webhook_url": "https://example.com/hooks",
  "status_code": 503,
  "retry_attempt": 3,
  "duration_ms": 2340
}
```

### Error tracking and alerting

Use a dedicated error tracking service (Sentry, Bugsnag, Datadog Error Tracking). Don't rely on log grep.

**Alert rules:**
- **Page** (wake someone up): 5xx rate > 5% for 5+ minutes, database unreachable, payment processing failure
- **Notify** (Slack/email): 5xx rate > 1%, slow query detected, job queue growing, disk > 80%
- **Log** (review tomorrow): 4xx rate spike, deprecated API version used, slow third-party API

**Alert fatigue kills alerting.** If your on-call gets more than 5 pages/week that don't require action, your alerts are wrong. Tune thresholds, suppress flapping, and have a weekly alert review.

### CI/CD patterns for multiple environments

| Environment | Purpose | Deploy trigger | Data |
|---|---|---|---|
| **Development** | Individual developer testing | On push to feature branch | Seed data |
| **Staging** | Integration testing, QA | On PR merge to main | Anonymized production snapshot |
| **Production** | Real users | Manual approval after staging green | Real data |

**Preview environments** (Vercel, Netlify, Railway) for every PR — reviewers see the actual UI, not just code diff. Pair with a seeded database per preview environment.

**Database migrations in CI/CD:**
1. Run migrations before deploying new code (expand phase)
2. Deploy new code
3. Run post-deploy migrations (contract phase) — only after monitoring confirms the deploy is healthy
4. Never run migrations manually in production. Always through the pipeline.

### Multi-region deployment preparation

Don't deploy multi-region on day one. But don't make it impossible.

**Do now:**
- Store all timestamps in UTC
- Use region-agnostic object storage (S3 with cross-region replication)
- Use a CDN for static assets
- Don't hardcode region-specific URLs
- Use environment variables for all service endpoints

**Do when you have customers in multiple continents:**
- Active-passive: primary region handles writes, read replicas in secondary region
- Active-active: both regions handle reads and writes with conflict resolution
- Database: use a globally distributed database (CockroachDB, PlanetScale, Neon) or PostgreSQL with logical replication

**Data residency matters.** EU customers may require data stored in EU regions. Plan for region-specific tenant routing: `tenant.data_region = 'eu-west-1'` determines which database cluster holds their data.

### Disaster recovery

| Metric | Target |
|---|---|
| **RPO** (Recovery Point Objective — max data loss) | < 1 hour (< 5 min for enterprise) |
| **RTO** (Recovery Time Objective — max downtime) | < 4 hours (< 30 min for enterprise) |

**Minimum viable DR:**
- Automated daily database backups (test restores monthly — untested backups are not backups)
- Point-in-time recovery enabled (Postgres WAL archiving, or managed DB provider)
- Application infrastructure defined as code (Terraform, Pulumi) — rebuild from scratch in < 1 hour
- Runbook for common failure scenarios: database failover, DNS switchover, third-party provider outage
- Chaos testing quarterly (simulate failures: kill a service, corrupt a cache, overload the database)

**Build now:** Automated backups, infrastructure as code, basic runbook. **Defer:** Multi-region active-active, automated failover, chaos engineering framework.

---

## Part 11 — Build Now / Hook / Defer Summary

This is the cheat sheet. For each category, what to build in the MVP, what to prepare hooks for, and what to defer entirely.

### Build now (MVP)

- Tenant_id on every table + PostgreSQL RLS
- Feature flags (use a service, not custom)
- i18n string extraction (even in English-only)
- CSS logical properties for future RTL
- UTC timestamps everywhere
- API versioning (URL path, `/api/v1/`)
- Webhook event system (internal pub/sub)
- Audit trail table
- Soft delete on all tables
- PostgreSQL full-text search
- Three built-in roles (Owner, Admin, Member)
- Structured JSON logging
- Error tracking (Sentry or equivalent)
- Automated database backups
- CI/CD with staging environment
- Design system foundation (10-15 core components)
- Cursor-based pagination for lists
- Background job queue (BullMQ/equivalent)
- Object storage for file uploads (never local filesystem)

### Add hooks (prepare but don't build)

- Team_id foreign key (not populated yet)
- SSO config table per tenant (empty)
- Custom field definition table (schema ready)
- Plugin manifest schema (defined, no runtime yet)
- Search abstraction layer (interface, Postgres implementation)
- Tenant branding config (JSON schema defined)
- Usage metering event table (schema ready)
- SCIM endpoint stubs (routes defined, not implemented)
- Multi-region tenant routing column (`data_region`)

### Defer entirely

- Schema-per-tenant / DB-per-tenant isolation
- Plugin marketplace
- Full white-label UI builder
- SCIM provisioning implementation
- Multi-region active-active deployment
- Elasticsearch/dedicated search infrastructure
- Custom role UI builder
- Automated chaos testing
- Cross-org collaboration
- AI-powered features (unless core to your value prop)

The principle: build the foundation that makes expansion possible without making expansion mandatory. Every hook costs hours. Every missing hook costs months.
