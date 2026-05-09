# Codebase Research

Before planning what to build, understand what already exists. The skill's workflow assumes greenfield by default, which causes three failures when dropped into an existing project: rebuilding what's already wired, missing integration points with the existing data layer or auth, and contradicting established conventions. This file is the protocol for reading the project state before generating a plan or todo list.

Run this before the pre-flight. The output is a structured document any agent's planner can consume to produce precise, gap-filling tasks instead of generic ones.

## Mode detection

Determine which mode applies before doing anything else. This is a 30-second check, not a deep analysis.

| Signal | How to detect | Mode |
|---|---|---|
| Empty directory, or only config/boilerplate | `ls` returns no source files, or only `package.json`/`README.md`/config stubs with no routes, components, or schema | **A: Greenfield** |
| Source files with routes, components, schema | Glob for route files, component directories, migration files (see patterns below) | **B: Assessment** |
| User says "audit," "verify," "harden," "check," "review" | Keyword in the user's prompt | **C: Audit** |
| Off-the-shelf template, prior agent's unfinished work, or cross-framework port | Recognizable template markers (Retool exports, shadcn admin kit folder structure, Appsmith `application.json`), half-built features with visible hollows, or the user says "we started with X, help us move to Y" | **D: Migration** |

**Detection patterns:**

```
# Routes
glob **/app/**/page.{tsx,jsx,ts,js}       # Next.js App Router
glob **/pages/**/*.{tsx,jsx,vue}           # Next.js Pages Router / Nuxt
glob **/src/routes/**/+page.svelte         # SvelteKit
grep -rl "router\.\|createRouter\|defineRoute" --include="*.ts" --include="*.js"

# Schema / persistence
glob **/prisma/schema.prisma
glob **/drizzle/**/*.ts
glob **/migrations/**
glob **/models/**/*.{rb,py}

# Components
count of .tsx/.vue/.svelte files in src/ or app/ directories
```

**Threshold:** Fewer than 5 source files containing fewer than 50 total lines of non-config code = greenfield. When in doubt, treat as greenfield — the cost of a quick scaffold is lower than the cost of a bad assessment.

## Mode A: Greenfield research

Even an empty project may have constraints. A 60-second scan prevents the agent from making choices that conflict with decisions already made.

**Check for:**

| What | Where to look |
|---|---|
| Pre-chosen dependencies | `package.json`, `Gemfile`, `requirements.txt`, `go.mod` — anything already installed? |
| Config locked in | `tsconfig.json`, `.eslintrc`, `tailwind.config`, `prettier.config` — conventions already set? |
| Deployment target | `vercel.json`, `fly.toml`, `Dockerfile`, `netlify.toml`, `render.yaml` — hosting decided? |
| External API | `.env.example` or `.env.local` referencing `API_URL`, `BACKEND_URL`, `SUPABASE_URL` |
| Design assets | `README.md` or `/docs` mentioning Figma links, brand guides, color specs |
| Existing data source | Database URL in env, or API docs linked in README |

**What not to do:** Do not spend 5 minutes researching an empty directory. If nothing is found, confirm greenfield and move to the pre-flight.

### Greenfield output format

```markdown
## Research output: Greenfield

**Mode:** Greenfield (no existing codebase)
**External constraints:**
- Deployment: [none | vercel.json targeting Vercel | Dockerfile found]
- Existing deps: [none | package.json has X, Y, Z pre-installed]
- Design assets: [none | Figma link in README | brand guide in /docs]
- External API: [none | .env.example references API_BASE_URL at X]
- Conventions: [none | ESLint + Prettier config present]
- Database: [none | DATABASE_URL in .env.example pointing to Supabase/Neon/etc.]

**Recommendation:** Proceed with full scaffolding. Respect constraints above.
```

## Mode B: Assessment research

This is the full scan. It produces a structured inventory of everything that exists, everything that is hollow, and every convention established. The goal is to prevent the agent from contradicting what the codebase already does.

Run subsections B1 through B7 in order. Each produces a structured output block. The blocks roll up into a single assessment document at the end.

### B1: Stack inventory

The agent needs to know exactly what's in place before making any decisions.

| Layer | How to detect |
|---|---|
| **Framework** | `package.json` deps: `next`, `nuxt`, `@sveltejs/kit`, `@angular/core`, `remix`, `astro`; or `Gemfile` for Rails, `requirements.txt` for Django/Flask |
| **Language** | `tsconfig.json` = TypeScript; `jsconfig.json` = JavaScript; `Gemfile` = Ruby; `requirements.txt` = Python; `go.mod` = Go |
| **ORM / DB** | deps: `prisma`, `drizzle-orm`, `typeorm`, `sequelize`, `mongoose`, `@supabase/supabase-js`; files: `schema.prisma`, `drizzle/`, `models/` |
| **Auth** | deps: `next-auth`, `@auth/core`, `better-auth`, `@clerk/nextjs`, `lucia`, `supabase` (auth module); or `devise` (Rails), `django-allauth` (Django) |
| **UI library** | deps: `@radix-ui/*`, `@mui/material`, `@chakra-ui/*`, `@mantine/*`; or `components/ui/` directory (shadcn pattern) |
| **Styling** | `tailwind.config` = Tailwind; `styled-components` or `@emotion/*` in deps = CSS-in-JS; `*.module.css` files = CSS Modules; `sass` in deps |
| **State management** | deps: `@tanstack/react-query`, `swr`, `zustand`, `pinia`, `@reduxjs/toolkit`, `jotai`, `valtio` |
| **Charts** | deps: `recharts`, `chart.js`, `react-chartjs-2`, `apexcharts`, `@nivo/*`, `d3`, `visx` |
| **Testing** | deps: `vitest`, `jest`, `@testing-library/*`, `playwright`, `cypress` |

Also read `.env.example` or `.env.local` — list every variable and whether it has a value or is a placeholder.

**Output format:**

```markdown
### Stack
| Layer | Choice | Version | Config file |
|---|---|---|---|
| Framework | Next.js | 15.2.1 | next.config.ts |
| Language | TypeScript | 5.6 | tsconfig.json |
| ORM | Prisma | 6.2 | prisma/schema.prisma |
| Auth | Auth.js | 5.0 | auth.ts |
| UI | shadcn/ui + Radix | — | components/ui/ |
| Styling | Tailwind CSS | 4.0 | tailwind.config.ts |
| State | TanStack Query | 5.62 | — |
| Charts | Recharts | 2.15 | — |
| Testing | Vitest + Playwright | — | vitest.config.ts |
```

### B2: Route and page map

Every route that exists, classified by whether it renders real content or is a placeholder.

**Framework-specific detection:**

| Framework | Glob pattern |
|---|---|
| Next.js App Router | `app/**/page.tsx` (each match = a route) |
| Next.js Pages Router | `pages/**/*.tsx` excluding `_app`, `_document` |
| SvelteKit | `src/routes/**/+page.svelte` |
| Nuxt | `pages/**/*.vue` |
| Remix | `app/routes/**/*.tsx` |
| React Router | `grep -rn "path:" src/router` or `grep -rn "<Route" src/` |
| Rails | `config/routes.rb` |
| Django | `urls.py` files |

**For each route found, read the file and classify:**

| Status | What it means |
|---|---|
| **Real** | Fetches data from a query/loader, handles states, has working actions |
| **Skeleton** | Returns JSX/HTML but data is hardcoded, lorem ipsum, or `Math.random()` |
| **Placeholder** | "Coming soon", empty component, or just a heading with no content |
| **Missing** | Referenced in navigation but file does not exist (will 404) |

How to classify: search the file for query hooks (`useQuery`, `useSWR`, `loader`, `getServerSideProps`), hardcoded arrays (`const data = [`), and placeholder text (`coming soon`, `lorem`, `TODO`).

**Output format:**

```markdown
### Routes
| Route | File | Status | Notes |
|---|---|---|---|
| /dashboard | app/dashboard/page.tsx | real | Fetches from /api/stats |
| /users | app/users/page.tsx | real | TanStack Query, pagination |
| /settings | app/settings/page.tsx | skeleton | Form renders but save does nothing |
| /reports | app/reports/page.tsx | placeholder | "Coming soon" text only |
| /billing | — | missing | In sidebar nav but no page exists |
```

### B3: Data layer state

What persistence exists, what schema is defined, what's real vs. mock.

**Schema detection:**
- Read `schema.prisma` or equivalent — list every model with field count and relationships
- Read migration files — are they applied? Is there a migration history?
- Check for seed script: `seed.ts`, `seed.js`, `seeds.rb`, `db/seeds/`, `fixtures/`
  - If found: is the data realistic ("Jane Smith, jane@acme.com") or generic ("User 1, test@test.com")?

**API route inventory:**
- Glob for API routes: `app/api/**/route.ts` (Next.js), `api/**/*.ts` (generic), `controllers/` (Rails/Django)
- For each: classify as real handler (reads/writes DB) vs. stub (returns hardcoded JSON or `// TODO`)

**Mock data detection:**

```
grep -rn "mockData\|fakeData\|dummyData\|sampleData" src/ --include="*.ts" --include="*.tsx"
grep -rn "Math\.random()\|Date\.now()" src/ --include="*.tsx"   # random data in components
grep -rn "const.*=.*\[" src/ --include="*.tsx" | head -20       # hardcoded arrays in components
```

**Output format:**

```markdown
### Data layer
**Schema:** 6 models in prisma/schema.prisma (User, Organization, Project, Task, Comment, AuditLog)
**Migrations:** 4 applied, up to date
**Seed data:** exists (prisma/seed.ts), realistic names/emails, 15 users, 8 projects
**Database:** PostgreSQL (DATABASE_URL in .env.example)

| API Route | Method | Status | Notes |
|---|---|---|---|
| /api/users | GET, POST | real | Pagination, filtering |
| /api/users/[id] | GET, PATCH, DELETE | real | Permission checks present |
| /api/projects | GET, POST | real | — |
| /api/reports/generate | POST | stub | Returns hardcoded JSON |

**Mock data locations:**
- src/app/dashboard/page.tsx:14 — `const stats = [...]` hardcoded array
- src/components/RevenueChart.tsx:8 — `Math.random()` generating chart data
```

### B4: Auth state

Auth is the most dangerous thing to rebuild or duplicate. Get this right.

**Provider detection:** Check which auth library is installed (see B1). Then:

```
# Protected routes
grep -rn "getServerSession\|auth()\|requireAuth\|protect\|authenticate_user\|before_action :auth" \
  --include="*.ts" --include="*.tsx" --include="*.rb" --include="*.py"

# Role model
grep -rn "role.*admin\|role.*member\|Role\.\|UserRole\|has_role\|user\.role" \
  --include="*.ts" --include="*.prisma" --include="*.rb"

# Session config
grep -rn "session.*strategy\|session.*maxAge\|SESSION_\|cookie.*httpOnly\|jwt.*secret" \
  --include="*.ts" --include="*.js" --include="*.py"
```

**Read the user model** — what fields exist? Email? Password hash? Role? Organization? Profile fields?

Count protected vs. unprotected routes. If 12 of 15 routes are protected, the 3 unprotected ones are gaps worth flagging.

**Output format:**

```markdown
### Auth
- **Provider:** Auth.js v5 (next-auth)
- **Session:** Cookie-based, 30-day expiry, httpOnly
- **User model:** id, email, passwordHash, name, role, organizationId, createdAt
- **Roles defined:** admin, member (in Prisma enum)
- **Protected routes:** 12 of 15 (unprotected: /reports, /exports, /audit-log)
- **Password hashing:** bcrypt (via Auth.js default)
- **Middleware:** middleware.ts protects /dashboard/* routes
```

### B5: UI inventory

What components exist and whether they are wired to real data or decorative.

**Component count:**

```
find src/components -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" | wc -l
```

**Design tokens:** Check for CSS variables in `globals.css`, `app.css`, or a theme file:

```
grep -c "^  --" src/app/globals.css    # count of CSS custom properties
```

Categorize tokens found: colors? spacing? radius? typography? All four = full token system. Some = partial. None = no design system.

**Shared vs. feature components:**
- `components/ui/` = shared design system (shadcn pattern)
- `components/{feature}/` = feature-specific components
- Count each category

**Wired vs. decorative:** For major page-level components, search for data-fetching patterns:

```
grep -l "useQuery\|useSWR\|loader\|getServerSideProps\|trpc\." src/app/**/page.tsx
```

Pages that appear in this list are wired. Pages that don't are likely decorative or use hardcoded data.

**Output format:**

```markdown
### UI
- **Total components:** 42
- **Shared (ui/):** 18 (Button, Input, Card, Table, Dialog, etc.)
- **Feature components:** 24
- **Design tokens:** Yes — globals.css defines 28 CSS variables (colors: 12, spacing: 4, radius: 4, fonts: 3, semantic: 5)
- **Token gaps:** Animation/motion tokens not defined. Dark mode tokens not present.
- **Wired pages:** 8 of 12 use query hooks
- **Decorative pages:** 4 use hardcoded data or render static content
```

### B6: Conventions scan

An existing codebase has established patterns. Violating them creates inconsistency worse than a suboptimal-but-consistent convention.

**What to check:**

| Convention | How to detect | Example output |
|---|---|---|
| **File structure** | `ls -R src/` — feature-based (files grouped by feature) or layer-based (files grouped by type)? | "Feature-based: src/app/users/, src/app/projects/" |
| **File naming** | Scan filenames — kebab-case? camelCase? PascalCase? | "Components: PascalCase. Hooks: camelCase with `use` prefix. Files: kebab-case." |
| **Import style** | `grep -m5 "from ['\"]@/" src/` — absolute paths with `@/`? Relative? Barrel exports? | "Absolute imports via @/ alias" |
| **Error handling** | Read 2-3 pages — try-catch? Error boundaries? Both? | "Error boundaries at layout level, try-catch in server actions" |
| **API patterns** | Read 2-3 API routes — consistent response shape? Error format? | "All routes return { data, error, meta } shape" |
| **Commit style** | `git log --oneline -10` — conventional commits? Free-form? | "Conventional commits: feat:, fix:, chore:" |

**Output format:**

```markdown
### Conventions
- **File structure:** Feature-based, colocated (components + hooks + types in same feature dir)
- **Naming:** PascalCase components, camelCase hooks/utils, kebab-case files
- **Imports:** Absolute via @/ alias (tsconfig paths)
- **Error handling:** Error boundaries at layout level, try-catch in server actions
- **API response shape:** { success: boolean, data: T, error?: string }
- **State management:** TanStack Query for server state, Zustand for client state
- **Commit style:** Conventional commits (feat/fix/chore)
```

### B7: Hollow indicators

The core Production Ready concern — identifying what looks done but is not.

**Run these searches:**

```
# Incomplete code markers
grep -rn "// TODO\|// FIXME\|// HACK\|// XXX\|// TEMP" src/

# Debug artifacts
grep -rn "console\.log\|console\.warn\|console\.error" src/ --include="*.tsx" --include="*.ts"

# Fake/mock data in components
grep -rn "mockData\|fakeData\|dummyData\|placeholder\|lorem\|Lorem" src/

# Empty handlers
grep -rn "() => {}\|onClick={() => console\|onClick={() => {}" src/

# Placeholder UI
grep -rn "Coming soon\|Under construction\|Not implemented\|TBD\|WIP" src/

# Unconnected forms
grep -rn "onSubmit.*prevent\|handleSubmit" src/ --include="*.tsx"
# Then check: do those handlers call an API or just console.log?
```

**Classify each hit:**

| Type | Severity | Action |
|---|---|---|
| TODO/FIXME in a feature file | **High** | Must implement before shipping |
| console.log in a component | **Low** | Remove (debug artifact) |
| Hardcoded data array in a page | **High** | Wire to real data layer |
| Empty onClick handler | **High** | Implement the real action |
| "Coming soon" text | **High** | Build the feature or remove the nav link |
| console.error in a catch block | **None** | Intentional error logging — skip |

**Output format:**

```markdown
### Hollow indicators
| File | Line | Type | Severity |
|---|---|---|---|
| src/app/dashboard/page.tsx | 14 | Hardcoded data array | high |
| src/components/DeleteButton.tsx | 8 | Empty onClick handler | high |
| src/app/settings/page.tsx | 42 | TODO: wire to API | high |
| src/app/reports/page.tsx | 1 | "Coming soon" placeholder | high |
| src/lib/api.ts | 23 | console.log | low |
| src/app/api/users/route.ts | 15 | console.log | low |

**Summary:** 4 high-severity hollows, 2 low-severity debug artifacts
```

### Assessment output format

Roll up B1–B7 into a single document. This is the complete output that any agent's planner consumes.

```markdown
## Research output: Assessment

**Mode:** Assessment (existing codebase)
**Scanned at:** [timestamp]

### Stack
[B1 output table]

### Routes
[B2 output table]

### Data layer
[B3 output — schema summary, API inventory, mock locations]

### Auth
[B4 output — provider, session, roles, protected routes]

### UI
[B5 output — component count, tokens, wired vs decorative]

### Conventions
[B6 output — file structure, naming, imports, error handling]

### Hollow indicators
[B7 output table + summary]

### Current tier
Evaluate the codebase against the completion tiers defined in SKILL.md:

- **Tier 1 (Foundation):** Auth + real data + shell + nav + landing page + one CRUD entity + logout + visual identity
- **Tier 2 (Functional):** + RBAC + all states + validation + feedback + pagination + settings + profile
- **Tier 3 (Polished):** + audit log + keyboard accessibility + responsive + breadcrumbs + cross-cutting
- **Tier 4 (Hardened):** + tests + security headers + verification green + zero hollow indicators

State the highest tier fully satisfied and what's blocking the next tier.

```
**Current tier:** Tier 1 (Foundation) — complete
**Blocking Tier 2:** RBAC not enforced server-side, settings page doesn't persist, no empty/error states
```

### Gap analysis
From the assessment and tier evaluation above, derive the gaps. Each gap becomes a todo item for the planner. Tag each with the tier it belongs to.

- [ ] [Tier 2] [Gap 1: what's missing or hollow, with specific file references]
- [ ] [Tier 2] [Gap 2: ...]
- [ ] [Tier 3] [Gap 3: ...]

Order gaps by tier, then by severity within each tier: high-severity hollows first (broken features), then missing features, then polish items.
```

The gap analysis section is what a planner converts directly into a todo list. Each checkbox maps to one task. The agent does not need to re-discover the gaps — they are already enumerated with file paths and evidence.

## Mode C: Audit research

The user has a dashboard they believe is done and wants verification. This is not about building new features — it's about catching what's broken or hollow.

**Process:**
1. Run the same scans as Mode B (B1–B7) to produce the assessment
2. Additionally, walk the full verification checklist from `references/preflight-and-verification.md`
3. For each checklist item, test it and record pass/fail with evidence

**What to test beyond Mode B scans:**
- Start the app with a single command — does it work?
- Log in as admin — does auth work end-to-end?
- Log in as non-admin — is the experience correctly restricted?
- Click every nav link — any 404s?
- Create, edit, delete a record — does the full CRUD cycle work?
- Check browser DevTools — any red errors or failed requests?
- Resize to mobile — does the layout hold?
- Tab through the page — is everything keyboard-accessible?

### Audit output format

```markdown
## Research output: Audit

**Mode:** Audit (verification scan)
**Scanned at:** [timestamp]

### Assessment
[Full Mode B output — stack, routes, data, auth, UI, conventions, hollows]

### Verification checklist
| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | App starts with single command | PASS | `npm run dev` works, documented in README |
| 2 | Login rejects bad credentials | PASS | Returns 401 with error message |
| 3 | Session persists across refresh | PASS | Cookie-based, httpOnly |
| 4 | Non-admin sees restricted view | FAIL | All routes accessible regardless of role |
| 5 | Every sidebar link resolves | FAIL | /reports returns 404 |
| 6 | Settings page persists changes | FAIL | Form renders but save handler is empty |
| ... | ... | ... | ... |

### Current tier
**Current tier:** Tier 1 (Foundation) — partial (auth works, RBAC not enforced)
**Blocking Tier 2:** RBAC middleware missing, settings doesn't persist, no empty/error states
**Blocking Tier 3:** No audit log, responsive untested, no keyboard accessibility pass
**Blocking Tier 4:** No tests, no security headers, 3 TODOs remain

### Fix-it list (sorted by tier, then severity)
**Tier 1 gaps (Foundation):**
1. **Critical:** Passwords stored as SHA-256 — migrate to argon2id or bcrypt
2. **High:** /reports nav link 404s — build the page or remove from nav

**Tier 2 gaps (Functional):**
3. **Critical:** Non-admin can access all routes — add RBAC middleware
4. **High:** Settings page save handler is empty — wire to PATCH /api/settings
5. **Medium:** Dashboard chart uses Math.random() — wire to real data

**Tier 3 gaps (Polished):**
6. **Medium:** 3 TODO comments remain in production paths

**Tier 4 gaps (Hardened):**
7. **Low:** Favicon is default framework icon — replace with product logo
```

The fix-it list is the todo. Each item maps to a tier and has enough context to implement without re-investigation. Work through tiers in order — don't start Tier 3 fixes while Tier 2 has critical gaps.

## Mode D: Migration research

The user inherited something. Sources: an off-the-shelf admin template (Retool export, Appsmith, Tooljet, shadcn admin kit, Mantine admin starter, Nuxt UI dashboard template), a previous AI agent's half-built work, or a cross-framework port (Vue to React, PHP to Rails, WordPress back-office to a custom dashboard). The existing code is not a contract. It's scaffolding measured against the tier requirements.

The failure this mode prevents: adopting hollow patterns because they are already there. Template kits ship with default shadcn styling, stub auth, and mock data, all of which violate the skill's tier requirements. A migration that preserves the template wholesale inherits every one of those hollows.

**Process:**

1. Run Mode B scans (B1 through B7) to produce the raw assessment.
2. Additionally, run the hollow-check protocol across the entire codebase. Every hit is migration-relevant.
3. For each artifact in the assessment, assign one of three dispositions: **keep**, **rewrite**, or **discard**.

**Disposition rules:**

| Keep | Rewrite | Discard |
|---|---|---|
| Meets the tier bar as-is (real auth, real data, real states, no hollow indicators). | The shape is right but the implementation is hollow (UI exists but uses mock data; API endpoint exists but skips permission check; form posts and ignores response). | The path is not on the route map; the entity is not in the domain model; the feature does not survive the pre-flight's "who uses this, for what job?" question. |
| Passing tests. Meaningful. | Tests exist but mock everything. Rewrite to hit a real boundary. | Tests for discarded code. |
| Design tokens and visual identity that match or can be adapted to the chosen archetype. | Components wired to shadcn defaults instead of project tokens. Rewrite the token layer; keep the component structure. | Components named `ExampleDashboard`, `DemoSidebar`, placeholder illustrations, or lorem-ipsum copy. |
| Conventions that are internally consistent (file layout, naming, test patterns). | Conventions that are inconsistent (two auth libraries, mixed state management). Pick one, rewrite to unify. | Dead conventions with no active code referencing them. |

### Migration output format

```markdown
## Research output: Migration

**Mode:** Migration
**Origin:** [Retool export | shadcn admin kit v1.2 | prior agent work (last touched 2026-03-15) | Vue 3 admin, porting to Next.js]
**Scanned at:** [timestamp]

### B1–B7 assessment
[Same structure as Mode B output.]

### Hollow-check results
- High-severity hits: [count] across [files]
- `GHOST:` dependencies: [list or "none"]

### Disposition inventory

**Keep ([N] items):**
- [path]: [why it meets the tier bar]

**Rewrite ([N] items):**
- [path]: [current shape / required shape] (tier blocked: [tier])

**Discard ([N] items):**
- [path]: [reason]

### Migration plan
Phase 1 (Tier 1 foundation): rewrite [auth, data layer, shell] items, keep [X, Y]. Discard before starting: [list].
Phase 2 (Tier 2 functional slices): [ordered slice list, each marked keep/rewrite].
Phase 3 (Tier 3 polish): [items].
Phase 4 (Tier 4 harden): [items].
```

The plan is the todo. The key discipline: **no item crosses from "rewrite" to "keep" without an ADR explaining why it now meets the tier bar.** This prevents the common migration failure where scope creeps and half-done template code gets blessed as "good enough."

### Migration closure gate

The disposition inventory has the same graveyard risk as `.production-ready/deferred-cta.md` and the STATE.md open-questions block: a phased list with no forcing function. Without closure, a migration inherits 40 `rewrite` items, ships 20 in the first pass, and the remaining 20 quietly persist as unshipped scaffolding while the project looks progressing.

**Item schema.** Every `rewrite` item in the inventory must carry a status: `planned` (not yet started), `in-progress` (active in the current slice), `shipped` (the replacement code is in place and meets the tier bar), or `reclassified-as-dropped` (decided not to rewrite; the original code stays or the feature is cut). Every `reclassified-as-dropped` item must have an accompanying ADR explaining why the earlier rewrite judgment was reversed.

**Tier-boundary review.** At every tier boundary (Tier 1 to 2, 2 to 3, 3 to 4), walk the inventory. For each `planned` or `in-progress` item, confirm it is scheduled into a named slice. Items that cross two tier boundaries still in `planned` status are either the next slice's mandatory content or deserve to be reclassified.

**Tier 4 closure gate.** Mode D projects cannot declare Tier 4 (Hardened) while any `rewrite` item is `planned` or `in-progress`. Every inventory item must be `shipped` or `reclassified-as-dropped`. The migration is not complete while half of the inherited scaffold remains half-replaced.

**File-growth signal.** If the inventory starts with more than 25 `rewrite` items, the migration is not a migration. It is a rewrite dressed as a migration, and the better path is to declare that openly, preserve only the `keep` items as seed data and conventions, and restart the app as a greenfield Mode A project.

## Research-to-planning bridge

The research output feeds the next step in the workflow differently per mode.

**Greenfield → Step 1 (pre-flight):** Research confirmed the project is empty. Proceed with full pre-flight, full architecture decisions, full scaffolding. Respect any external constraints found (deployment target, pre-chosen deps, existing API).

**Assessment → Step 1 (pre-flight), then Step 2 (architecture):** The research pre-fills most pre-flight answers. The stack is decided (don't re-decide it). The auth model is in place (don't install a second auth library). The route map exists (extend it, don't replace it). The architecture step becomes: "Existing: [what the research found]. Adding: [what the gap analysis identified]." Feature slice order comes from the gap analysis — fix hollows first, then build new features.

**Audit → Fix-it list:** Skip the pre-flight and architecture steps. The dashboard already exists. Go directly to the fix-it list and work through it by severity. Each fix is a vertical slice: identify the hollow → implement the real version → verify it works.

**Migration → Step 1 (pre-flight), then disposition-driven execution:** The research produced a keep/rewrite/discard inventory plus a phased migration plan. Walk the pre-flight using the inventory: stack is inherited (question 3 is whatever the template shipped with, unless you are porting frameworks), domain entities are whatever is in the keep/rewrite lists after discarding dead ones. Architecture note (Step 2) adopts the keep items and documents the rewrites as planned work. Work the migration plan phase by phase; each rewrite item is a vertical slice.

### Rules for working with existing codebases

These are non-negotiable when Mode B, C, or D is active:

1. **Never install a second auth library** when one already exists. Extend it, configure it, fix it — don't replace it.
2. **Never introduce a different CSS methodology** when tokens or a design system exist. If the project uses Tailwind + CSS variables, you use Tailwind + CSS variables.
3. **Never change file naming conventions** mid-project. If existing files are kebab-case, new files are kebab-case.
4. **Never rebuild a route that already works.** Extend it, fix its hollows, add missing states — but don't rewrite a working page.
5. **Never change the API response shape.** If existing routes return `{ data, error }`, new routes return `{ data, error }`.
6. **Never swap the state management library.** If the project uses Zustand for client state, you use Zustand for client state, even if you would have chosen differently.
7. **Adopt the existing commit style.** If the project uses conventional commits, your commits use conventional commits.
8. **Match the existing test patterns.** If existing tests use Vitest with Testing Library, new tests use Vitest with Testing Library.

The only exception: if the existing choice is actively broken or insecure (SHA-256 password hashing, no CSRF protection), fix it and document the change. Convention-following does not extend to perpetuating security vulnerabilities.

**Mode D caveat:** in a migration, the above rules apply *only to "keep" items*. Anything marked "rewrite" or "discard" in the disposition inventory is, by definition, not the convention going forward. The new convention is whatever the migration plan establishes for the target state. When a rewrite replaces a keep item, write an ADR so the shift is legible to the next maintainer.
