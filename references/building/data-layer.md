# Data Layer

The data layer is the wiring that takes data from the database/API to the screen and takes user input back the other way. A dashboard's data layer is the part most likely to feel "broken" if done badly: stale lists, slow loads, lost edits, double submits, race conditions, "I clicked save but it didn't save."

This file is the rules for building the data layer so it feels solid.

**Canonical scope:** server components, internal API contracts, queries, mutations, cache invalidation, optimistic updates, server state vs. client state. **See also:** `api-and-integrations.md` for external APIs and webhooks, `system-integration.md` for internal event bus and feature flags.

## The big idea: server state is not client state

Server state is data that lives on a server, can be modified by other users, requires async to access, and can become stale at any moment. Client state is data that lives entirely in the browser (form input values, "is this modal open," "which tab is selected").

These have different needs:

- **Client state** wants: simple updates, instant reflection, no network involved. `useState`, `useReducer`, signals, stores.
- **Server state** wants: caching, deduplication, background refetch, stale-while-revalidate, retry on failure, optimistic updates with rollback, invalidation after mutations.

Mixing them is the most common dashboard mistake. Don't put server data in Redux/Zustand/Vuex/Pinia — those are client-state tools. Use a server-state library instead. The dashboards that feel snappy and consistent are the ones that respect this distinction.

### Pick a server-state library

For the major frameworks:

- **React** — TanStack Query (recommended default), SWR, RTK Query, Apollo Client (if GraphQL)
- **Vue** — TanStack Query for Vue, VueQuery, Pinia Colada
- **Svelte** — TanStack Query for Svelte
- **Solid** — TanStack Query for Solid, Solid Query
- **Angular** — TanStack Query for Angular, Apollo Angular, NgRx Data
- **Next.js / Remix / SvelteKit** — framework loaders + a query library on the client. Loaders give you SSR; the query library gives you client-side caching, mutations, and invalidation. Use both.
- **Plain HTML / HTMX / Hotwire** — the framework is the data layer. Server-rendered partials with htmx/Turbo updates. No client-side cache to manage.

### React Server Components and server actions

For Next.js App Router dashboards (the default in 2026), the data-fetching model has shifted:

- **Server Components fetch data directly** — no hooks, no query library needed for initial load. The component is async, runs on the server, and returns rendered HTML.
- **Server actions handle mutations** — no explicit API routes needed for same-app mutations. Define a function with `'use server'`, call it from client components.
- **TanStack Query is for client-side interactivity** — polling, optimistic updates, infinite scroll, cache invalidation after mutations. It complements Server Components, not replaces them.
- **Suspense boundaries control progressive loading** — wrap sections in `<Suspense fallback={<Skeleton />}>`. The shell renders immediately; each section streams in as its data resolves.

If you're building with Next.js App Router, start with Server Components + server actions. Add TanStack Query only for surfaces that need client-side caching or real-time updates.

**The concrete pattern for Next.js App Router dashboards:**

```tsx
// --- Server Component: fetches data, no hooks needed ---
// app/customers/page.tsx
export default async function CustomersPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = Number(params.page) || 1;
  const { data, totalCount } = await db.customer.findMany({
    where: params.search ? { name: { contains: params.search } } : undefined,
    skip: (page - 1) * 25,
    take: 25,
  });
  return (
    <Suspense fallback={<TableSkeleton rows={5} />}>
      <CustomerTable data={data} totalCount={totalCount} />
    </Suspense>
  );
}

// --- Server Action: handles mutations, no API route needed ---
// app/customers/actions.ts
'use server';
import { revalidatePath } from 'next/cache';

export async function createCustomer(formData: FormData) {
  const session = await auth();
  if (!session) throw new Error('Unauthorized');
  if (!can(session.user.role, 'customers:create')) throw new Error('Forbidden');

  const parsed = customerSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };

  await db.customer.create({ data: parsed.data });
  await db.auditLog.create({
    data: { userId: session.user.id, action: 'customer.created', entity: 'customer' },
  });
  revalidatePath('/customers');
}

// --- Client Component: only when you need interactivity ---
// components/customers/DeleteCustomerButton.tsx
'use client';
export function DeleteCustomerButton({ id }: { id: string }) {
  const [pending, startTransition] = useTransition();
  return (
    <Button
      variant="destructive"
      disabled={pending}
      onClick={() => startTransition(() => deleteCustomer(id))}
    >
      {pending ? 'Deleting...' : 'Delete'}
    </Button>
  );
}
```

**When to add TanStack Query on top of this:** polling/real-time surfaces, infinite scroll, optimistic updates with rollback, or client-side filtering that needs a local cache. For standard CRUD pages, Server Components + server actions are sufficient.

Hand-rolling `useEffect + fetch + useState` is acceptable for one-off tiny dashboards. Beyond ~3 pages, the ad-hoc approach produces inconsistent loading states, missed cache invalidations, double-fetches on mount, and stale lists. Use the library.

### Database connection pooling in serverless

If deploying to Vercel, AWS Lambda, or Cloudflare Workers: every function invocation opens a new database connection. This exhausts the pool within minutes under load. Solutions:

- **Supabase Supavisor** — connection pooler for Supabase Postgres
- **Neon serverless driver** — HTTP-based Postgres access, no persistent connections
- **PlanetScale HTTP driver** — HTTP-based MySQL
- **Prisma Accelerate** — connection pooling proxy for Prisma
- **Drizzle + `@neondatabase/serverless`** — direct serverless Postgres

If the file recommends Prisma + Postgres + serverless deployment, connection pooling is mandatory, not optional.

## API contracts

### Pick a contract style

Three viable styles:

- **REST + JSON** — the safe default. Resources at predictable URLs, standard verbs. Easy to debug, easy to inspect, works with any tool. The right choice for ~90% of dashboards.
- **GraphQL** — when the client needs flexibility in what it fetches and the entity graph is complex. Adds setup cost; pays off with deeply nested data and many clients. Overkill for small dashboards.
- **RPC (tRPC, gRPC, JSON-RPC)** — when the dashboard and the API are in the same repo with the same language, especially TypeScript. tRPC gives you end-to-end types for free. Excellent developer experience, slightly less interop with other clients.

For a single-team dashboard, the right answer is usually **REST for external clients + tRPC for the dashboard's own backend** (if both are TypeScript) or **just REST** (if not). GraphQL is correct less often than people pick it.

### REST conventions

Use the standard ones. Don't invent.

```
GET    /api/projects              → list (with ?page=&sort=&filter=)
POST   /api/projects              → create
GET    /api/projects/:id          → fetch one
PATCH  /api/projects/:id          → partial update
PUT    /api/projects/:id          → full update (rare; PATCH is more common)
DELETE /api/projects/:id          → delete

GET    /api/projects/:id/tasks    → nested list
POST   /api/projects/:id/tasks    → nested create
```

Status codes:
- `200` — success with body
- `201` — created (return the new resource)
- `204` — success without body (deletes)
- `400` — bad request (validation failed)
- `401` — not authenticated
- `403` — authenticated but not authorized
- `404` — not found
- `409` — conflict (e.g., unique violation, version conflict)
- `422` — unprocessable (validation, semantic errors)
- `429` — rate limited
- `500` — server error

Error response shape — pick one and use it everywhere:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "One or more fields are invalid",
    "fields": {
      "email": "must be a valid email address",
      "name": "is required"
    }
  }
}
```

Field-level errors are critical for forms — without them, the form has to guess where to highlight.

### Pagination

Two styles:

- **Offset/limit** (`?page=2&pageSize=25`) — simple, allows jumping to arbitrary pages, doesn't degrade gracefully when rows shift between requests
- **Cursor** (`?cursor=abc&limit=25`) — stable across writes, no count needed, can't jump to "page 5," better for infinite scroll and very large datasets

For dashboards with classic table UIs and "page 1, 2, 3 ... 50" navigation, use offset. For infinite-scroll feeds and very large datasets, use cursor. Don't mix on a single endpoint.

The list response shape:

```json
{
  "data": [...],
  "page": 2,
  "pageSize": 25,
  "totalCount": 1247,
  "totalPages": 50
}
```

### Filtering and sorting in URLs

Encode filters and sort in the query string. This makes URLs shareable and reload-safe.

```
/api/projects?status=active&owner=alice&sort=-createdAt&page=2
```

Convention: `sort=-field` for descending, `sort=field` for ascending. Multiple sorts: `sort=-createdAt,name`.

Mirror the same scheme in the frontend URL — the dashboard's URL bar should reflect the table state. Reloading the page restores the same view. This is one of the highest-leverage dashboard quality wins.

## Query patterns

The TanStack Query / SWR / RTK Query mental model — the same model applies to all of them with different API surfaces:

### Reads: queries

```ts
// Define once, in a queries file
export const projectsListOptions = (filters: ProjectFilters) =>
  queryOptions({
    queryKey: ['projects', filters],          // serializable cache key
    queryFn: () => api.projects.list(filters), // how to fetch
    staleTime: 30_000,                         // fresh for 30s
  });

// Use anywhere
const { data, isLoading, error } = useQuery(projectsListOptions(filters));
```

Rules:
- **Query keys are arrays starting with the resource name.** `['projects']`, `['projects', 'list', filters]`, `['projects', id]`. Consistent prefixes enable bulk invalidation.
- **Define query options in a single file per resource**, not inline at every call site. Otherwise, a typo in one query key creates a phantom cache entry that never invalidates. This is the #1 query-library bug.
- **`staleTime` controls how often background refetches happen.** Default of 0 means "refetch on every mount" — fine for small datasets, wasteful for large. Pick per-query: 30s for fast-moving, 5min for slow, infinity for static.
- **`gcTime`** (formerly `cacheTime`) controls how long unused cache entries stay in memory. Default is 5 minutes; usually fine.

### Writes: mutations

```ts
const updateProject = useMutation({
  mutationFn: (input: ProjectUpdate) => api.projects.update(input.id, input),
  onSuccess: (updated) => {
    // 1. Update the single-item cache so the detail page reflects immediately
    queryClient.setQueryData(['projects', updated.id], updated);
    // 2. Invalidate the list so it refetches
    queryClient.invalidateQueries({ queryKey: ['projects', 'list'] });
    // 3. Show feedback
    toast.success('Project updated');
  },
  onError: (error) => {
    toast.error(error.message);
  },
});

// Trigger
updateProject.mutate({ id: '123', name: 'New name' });
```

The `onSuccess` invalidation is what makes the list reflect the change. **Forgetting to invalidate is the #1 "feels broken" bug.** The user edits something, navigates back to the list, and sees the old value. They lose trust.

### Optimistic updates

For high-confidence actions (toggles, simple edits, drag-to-reorder), update the cache immediately and roll back on error:

```ts
const toggleStarred = useMutation({
  mutationFn: (project) => api.projects.toggleStar(project.id),
  onMutate: async (project) => {
    await queryClient.cancelQueries({ queryKey: ['projects'] });
    const prev = queryClient.getQueryData(['projects', project.id]);
    queryClient.setQueryData(['projects', project.id], {
      ...prev,
      starred: !prev.starred,
    });
    return { prev };
  },
  onError: (err, project, context) => {
    queryClient.setQueryData(['projects', project.id], context.prev);
    toast.error('Failed to update');
  },
  onSettled: (data, err, project) => {
    queryClient.invalidateQueries({ queryKey: ['projects', project.id] });
  },
});
```

Do this for actions where success is the overwhelming case. Don't do it for actions that often fail (validation-heavy forms, financial transactions).

### Dependent queries

When one query depends on the result of another (fetch user, then fetch user's projects), use the `enabled` option:

```ts
const { data: user } = useQuery(currentUserOptions());
const { data: projects } = useQuery({
  ...projectsListOptions({ ownerId: user?.id }),
  enabled: !!user?.id,
});
```

Don't await one query before starting another in `useEffect` — let the library handle the dependency.

### Prefetching

For predictable navigation (hovering a row → likely to click into it), prefetch the detail query:

```ts
function ProjectRow({ project }) {
  const queryClient = useQueryClient();
  return (
    <tr
      onMouseEnter={() => {
        queryClient.prefetchQuery(projectDetailOptions(project.id));
      }}
      onClick={() => navigate(`/projects/${project.id}`)}
    >
      …
    </tr>
  );
}
```

The detail page then loads instantly. Cheap, big perception win.

## Sync over polling, polling over manual refresh

For data that needs to stay fresh, in increasing order of complexity:

1. **Manual refresh** — the user clicks a refresh button. Acceptable for low-stakes reports and analytics.
2. **Window focus refetch** — refetch when the tab becomes visible. Default in TanStack Query and SWR. Free freshness, no extra code.
3. **Polling** — refetch on an interval (`refetchInterval: 10_000`). Use for operational dashboards (NOC, monitoring). Set the interval based on how stale data can be without harm — usually 10–60 seconds.
4. **WebSockets / Server-Sent Events** — push from server to client. Use for chat, live collaboration, real-time alerts. The query library typically integrates: receive a message, call `queryClient.setQueryData` or `invalidateQueries`.
5. **CRDT-based sync** (Yjs, Automerge, Zero, Convex) — full bidirectional sync with conflict resolution. Use for collaborative editing dashboards. Big upfront cost; transformative when needed.

Don't jump to websockets just because real-time sounds cool. Start at the lowest level that's adequate. Most dashboards are fine with polling on the few widgets that need it.

## File uploads

Dashboards routinely upload avatars, logos, CSVs, attachments. Implement uploads correctly the first time:

1. **Don't POST files through your application server for anything > a few MB.** Use direct-to-storage uploads: client requests a presigned URL from your API → server returns URL + form fields → client PUTs/POSTs directly to S3/R2/GCS/Azure Blob → client tells your API "upload complete, here's the key."
2. **Validate size and type on the client before starting** — instant feedback, no wasted bandwidth.
3. **Validate again on the server** when the upload is finalized (the client check is courtesy; the server check is truth).
4. **Show progress** — the upload library should expose progress events. A bar that fills is essential for files > 1MB.
5. **Allow cancel and retry.**
6. **For images**: generate thumbnails server-side or via a transform URL (Cloudinary, Imgix, Cloudflare Images). Don't store and serve full-resolution avatars.
7. **For CSV imports**: parse a sample of rows on the client to preview, then upload, then process server-side with a background job. Show a progress page that polls the job status. Don't block the request thread on a 100k-row import.

## CSV / Excel exports

Almost every dashboard ends up with "export to CSV." Build it correctly:

1. **For < 10k rows** — generate on-demand server-side, stream the response, set `Content-Disposition: attachment; filename="..."`.
2. **For larger exports** — kick off a background job, email the user a download link when done, or show a notification in the UI.
3. **Use the same filters as the on-screen view** — the export should reflect what the user is currently looking at, not "all rows everywhere."
4. **Format like a human spreadsheet** — proper headers, ISO dates or formatted dates (not Unix timestamps), money as numbers (not "$1,234.00" strings the user can't sum).
5. **For Excel-specific**, use a real library (`exceljs`, `openpyxl`, `xlsx-populate`) — don't try to fake it with a CSV renamed to .xls.
6. **PDF exports** belong to a different complexity bucket. Use a server-side renderer (Puppeteer, PrinceXML, weasyprint) and treat them as background jobs.

## Error handling

Every fetch can fail. Plan for it.

### Categories of failure

- **Network errors** — offline, DNS, timeout. Show "Couldn't reach the server. Check your connection." Provide a retry button.
- **4xx client errors** — show the server's error message. For validation, surface field-level errors.
- **401** — session expired. Redirect to login (preserving `next`).
- **403** — show "You don't have permission." Don't redirect; the user is logged in, just not authorized.
- **404** — show "Not found." Don't pretend it's a generic error.
- **5xx server errors** — show "Something went wrong on our end. We're looking into it." Log to error tracking. Provide a retry button.
- **Timeouts** — same as network errors but possibly with a different message.

### Retry policy

The query library's default retry policy (3 attempts, exponential backoff) is fine for queries. For mutations, **don't retry automatically** — retrying a mutation can double-charge a customer or send two emails. Let the user retry manually with full awareness.

### Global error handling

Have a global error handler that catches unhandled query/mutation errors and either toasts them or sends them to an error tracker (Sentry, Bugsnag, Rollbar). Don't let errors disappear silently. Don't `console.error` to no one in production.

## Concurrency: avoiding race conditions

Two patterns to handle:

### Stale closures in async handlers

When a search input fires a query for each keystroke, an old request can return after a newer one and overwrite the fresh data. Solutions:

- **Request cancellation** — the query library passes an `AbortSignal` to your fetch function. Pass it to `fetch(url, { signal })`. The library will cancel obsolete requests when the input changes.
- **Debouncing** — wait 250–400ms after the last keystroke before firing. Reduces request count and indirectly fixes most race conditions.
- **Both** — debounce + cancel. The combination is robust.

### Concurrent edits to the same record

Two users open the same record, both edit, both save. Without protection, the second save overwrites the first silently.

- **Optimistic locking** — store a `version` (or `updatedAt`) on the record. Send it with the update. The server compares and rejects with `409 Conflict` if it doesn't match.
- **Pessimistic locking** — rare in dashboards. Heavy.
- **Last-write-wins** — fine for many cases (settings pages, profile fields). Document it.
- **Merge / CRDT** — needed for true collaborative editing. Big lift.

For most dashboards, optimistic locking is the right answer. When conflict is detected, show "This record was modified by someone else. Refresh and try again."

## Caching gotchas

- **Cache key typos** — a typo in one place creates a parallel cache entry that's never invalidated. Define query options once per resource. Lint for it.
- **Forgetting to invalidate after a mutation** — the most common "feels broken" bug. Every mutation's `onSuccess` invalidates something.
- **Over-invalidating** — `invalidateQueries({})` with no key invalidates everything. Refetches all queries. Slow. Be specific.
- **Cache lifetime mismatched with reality** — `staleTime: Infinity` on data that changes often shows stale data. `staleTime: 0` on data that never changes wastes requests. Tune per-query.
- **SSR hydration mismatches** — when using Next.js / Remix / SvelteKit with a query library, hydrate the cache from the server's prefetched data so the first client render matches the SSR output. The libraries document this — read their SSR section before shipping.

## Don'ts

- **Don't put server state in your client store.** Redux / Zustand / Pinia / NgRx are for client state. Server state goes in the query library's cache.
- **Don't use raw `useEffect + fetch` on more than ~3 pages.** Adopt a query library.
- **Don't forget invalidation after mutations.**
- **Don't retry mutations automatically.**
- **Don't hand-roll cache management** with `useState` of a list and manually splicing items in. Use the library's `setQueryData` / `invalidate`.
- **Don't return `200 { error: ... }`.** Use HTTP status codes correctly.
- **Don't paginate client-side** for any list that could exceed ~200 rows. Server-side pagination above 200, client-side acceptable below.
- **Don't put tokens or sensitive IDs in URLs.** They leak via referrer headers and browser history.
- **Don't auto-refresh the entire dashboard on a timer** unless it's an operational/monitoring dashboard. Refresh per-widget instead.
- **Don't swallow errors.** Every error gets either a toast, an inline message, or a logged error track entry — preferably more than one.
