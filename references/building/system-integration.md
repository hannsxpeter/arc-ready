# System Integration

This file covers the connective tissue between dashboard features. The skill builds dashboards feature-by-feature (auth, CRUD, charts, billing, notifications, audit logs), and each feature risks becoming an isolated island. The result: editing a user's role doesn't update the permission-gated UI, a webhook updates the DB but the dashboard shows stale data, clicking a customer name in an order table goes nowhere, background jobs vanish into the void.

This file is the rules for keeping everything connected.

---

## The service layer

### Why every mutation goes through a service function

The fundamental problem: mutations happen in multiple places — the API route, the background job, the webhook handler, the admin bulk action. Each place independently touches the database, and each must independently remember to write audit logs, invalidate caches, send notifications, and enforce permissions. They inevitably diverge.

The fix: every entity mutation is a single service function. The API route, the webhook handler, the background job, and the admin action all call the same function. None of them touch the database directly.

```typescript
// services/users.ts
export async function updateUserRole(userId: string, newRole: Role, performedBy: string) {
  return await db.transaction(async (tx) => {
    const previous = await tx.user.findUnique({ where: { id: userId } });

    const user = await tx.user.update({
      where: { id: userId },
      data: { role: newRole },
    });

    await tx.auditLog.create({
      data: {
        entityType: 'user', entityId: userId,
        action: 'role_changed',
        previousValue: previous.role, newValue: newRole,
        performedBy,
      },
    });

    eventBus.emit('user.updated', { userId, changes: { role: newRole }, performedBy });

    return user;
  });
}
```

The service function does all five things in one place:
1. Validates and executes the mutation (in a transaction)
2. Writes the audit log entry
3. Emits an event for downstream side effects
4. Enforces permissions (or the caller does, before calling the service)
5. Returns the result

This prevents "I added audit logging to the API route but forgot the background job also modifies this entity."

### Service layer vs repository vs domain events

- **Repository** — solves data access abstraction (how you talk to the DB). Useful underneath the service layer, but a `userRepo.update()` still leaves the caller responsible for side effects. Not a substitute for services.
- **Service layer** — solves operation coordination (what happens when a mutation occurs). The right default for dashboards. Each function is the canonical way to perform an operation.
- **Domain events** — solves complex choreography across bounded contexts. At dashboard scale, in-process events emitted by service functions are sufficient. You don't need a separate event infrastructure.

Start with service functions that emit in-process events. Graduate to a message queue only when you have background processing that must survive process restarts.

---

## Event bus

### In-process vs message queue

| Use in-process events when... | Use a message queue when... |
|---|---|
| Side effect takes < 100ms | Side effect takes > 1 second |
| Failure is acceptable (cache invalidation) | Failure must be retried (email, webhook) |
| The effect is local (update counter, push WebSocket) | The effect calls external services |
| Zero infrastructure overhead | Work must survive a process crash |

**The hybrid pattern (most dashboards):** The service function emits an in-process event. Fast subscribers handle it synchronously. Slow subscribers enqueue a background job.

```typescript
// Fast subscriber (runs in-process):
eventBus.on('user.created', ({ user }) => {
  queryInvalidator.invalidate(['users']);
  wsServer.broadcast('entity.changed', { type: 'user', id: user.id });
});

// Slow subscriber (enqueues to background):
eventBus.on('user.created', ({ user }) => {
  emailQueue.add('welcome-email', { userId: user.id });
  provisioningQueue.add('create-defaults', { userId: user.id });
});
```

### Event taxonomy

Standardize names: `entity.verb_past_tense`.

```
user.created, user.updated, user.deleted, user.role_changed
order.created, order.fulfilled, order.cancelled, order.refunded
auth.login, auth.logout, auth.password_changed, auth.mfa_enabled
billing.payment_succeeded, billing.payment_failed, billing.subscription_changed
export.started, export.completed, export.failed
```

Every event payload includes: `entityType`, `entityId`, `action`, `performedBy` (user ID or "system"), `timestamp`, and `changes` (diff of what changed).

### Fan-out

One event triggers multiple independent side effects:

```
user.created -->
  [1] Send welcome email (queued)
  [2] Create audit log entry (sync, already in service)
  [3] Notify admin channel (queued)
  [4] Provision default settings (sync)
  [5] Invalidate user list cache (sync)
  [6] Push WebSocket event (sync)
```

### Error isolation

One subscriber failing must not break the primary operation or other subscribers. Wrap each handler in try/catch, log the failure, continue to the next handler. For queued work, use built-in retry with exponential backoff (BullMQ, Celery, Sidekiq).

### Idempotency

Events may be delivered more than once (especially with queues). Every handler must be idempotent — processing the same event twice produces the same result. Use the event's entity ID + action + timestamp as a deduplication key. For database writes, use upserts. For emails, check if already sent for this event.

---

## Query invalidation chains

### The problem

You edit a user's role. TanStack Query has cached: the user list (`['users']`), the user detail (`['users', userId]`), the permissions check (`['permissions', userId]`), and the activity feed (`['activity']`). All four are now stale. If you only invalidate one, the others show the old data.

### Centralized invalidation mapping

Build a single registry of which events invalidate which queries:

```typescript
const INVALIDATION_MAP: Record<string, string[][]> = {
  'user.created':     [['users'], ['stats', 'users']],
  'user.updated':     [['users'], ['permissions'], ['activity']],
  'user.deleted':     [['users'], ['stats', 'users'], ['activity']],

  'order.created':    [['orders'], ['customers'], ['stats', 'orders'], ['activity']],
  'order.updated':    [['orders'], ['activity']],

  'customer.deleted': [['customers'], ['orders'], ['invoices'], ['activity']],
};

export function invalidateForEvent(queryClient: QueryClient, event: string, entityId?: string) {
  const keys = INVALIDATION_MAP[event] ?? [];
  for (const key of keys) {
    queryClient.invalidateQueries({ queryKey: key });
  }
  if (entityId) {
    const entityType = event.split('.')[0];
    queryClient.invalidateQueries({ queryKey: [entityType, entityId] });
  }
}
```

This replaces ad-hoc `invalidateQueries` sprinkled across mutation handlers — the exact same "forgot to update this other place" problem the service layer solves on the backend.

### Broad vs narrow invalidation

- **Broad** (`invalidateQueries({ queryKey: ['users'] })`): invalidates the list, every detail page, every sub-query. Safe but may trigger extra refetches.
- **Narrow** (`invalidateQueries({ queryKey: ['users', userId], exact: true })`): only the specific entry. Precise but you must know every cache key.
- **Predicate** (`invalidateQueries({ predicate: (query) => ... })`): full control based on mutation payload.

**Default to broad invalidation by entity type prefix.** It causes extra refetches but never leaves stale data. Optimize to narrow only for high-frequency mutations where the refetches cause performance problems.

### Cross-entity invalidation

Deleting a customer should also invalidate their orders, invoices, and activity. The invalidation map handles this — one entry per event type, listing all affected query prefixes.

### Optimistic updates spanning multiple caches

When optimistically updating, snapshot all modified caches in `onMutate` for rollback, update each with `setQueryData`, and always call `invalidateQueries` in `onSettled` as the final consistency guarantee.

### Testing invalidation completeness

```typescript
test('updating user role invalidates all related queries', async () => {
  await renderWithQuery(<UserDashboard />);
  await mutateUserRole(userId, 'admin');

  expect(queryClient.getQueryState(['users', userId])?.isInvalidated).toBe(true);
  expect(queryClient.getQueryState(['users'])?.isInvalidated).toBe(true);
  expect(queryClient.getQueryState(['permissions', userId])?.isInvalidated).toBe(true);
});
```

---

## Cross-entity linking

### Every entity reference is a link

The most common integration failure: a customer name in an orders table is plain text. Clicking it does nothing. In a connected dashboard, every entity reference is a clickable link to that entity's detail page.

### The entity registry

A single data structure that knows about every entity type. Used by: entity links, hover cards, audit log renderer, activity feed, search results, notification renderer, breadcrumbs.

```typescript
const ENTITY_REGISTRY: Record<EntityType, {
  route: (id: string) => string;
  icon: IconComponent;
  labelField: string;
  previewFields: string[];
  searchable: boolean;
}> = {
  customer: {
    route: (id) => `/customers/${id}`,
    icon: UserIcon,
    labelField: 'name',
    previewFields: ['email', 'plan', 'createdAt'],
    searchable: true,
  },
  order: {
    route: (id) => `/orders/${id}`,
    icon: ShoppingCartIcon,
    labelField: 'number',
    previewFields: ['status', 'total', 'customerName'],
    searchable: true,
  },
  // ... every entity type
};
```

This makes it mechanically impossible to render an entity reference without a link.

### Entity link component

```tsx
function EntityLink({ type, id, label }: { type: EntityType; id: string; label: string }) {
  const { route, icon: Icon } = ENTITY_REGISTRY[type];
  return (
    <Link href={route(id)} className="entity-link">
      <Icon className="h-4 w-4" />
      <span>{label}</span>
    </Link>
  );
}
```

Use this everywhere: table cells, audit logs, activity feeds, notifications, search results.

### Hover preview cards

On hovering an entity link, fetch a lightweight preview (not the full detail) and display in a popover. Use Radix HoverCard or shadcn/ui hover-card. Set `staleTime: 30_000` on preview queries — they can be slightly stale.

### Backlinks

On every detail page, show related entities with counts and filtered-list links:

```
Customer: John Smith
  12 orders  |  3 invoices  |  1 support ticket
```

Each count links to the filtered list view: `/orders?customerId=123`.

### Universal entity resolution

Given a type + id, resolve to URL + label + icon. Needed by audit logs ("User Alice changed Order #1234"), activity feeds, notifications, and search results.

```typescript
async function resolveEntity(type: EntityType, id: string): Promise<ResolvedEntity> {
  const { route, icon } = ENTITY_REGISTRY[type];
  const label = await fetchEntityLabel(type, id);
  return { type, id, url: route(id), label, icon };
}
```

---

## Real-time state propagation

### The problem

An external event (Stripe webhook, background job, another user's action) changes state, but the current user's dashboard is stale until they refresh.

### Server-push invalidation (recommended for most dashboards)

The server broadcasts which query keys should be invalidated. The client's query library refetches automatically.

```typescript
// Client: connect to SSE, invalidate queries on events
function useRealtimeInvalidation() {
  const queryClient = useQueryClient();

  useEffect(() => {
    const es = new EventSource('/api/events');
    es.addEventListener('invalidate', (event) => {
      const { queryKeys } = JSON.parse(event.data);
      for (const key of queryKeys) {
        queryClient.invalidateQueries({ queryKey: key });
      }
    });
    return () => es.close();
  }, [queryClient]);
}

// Server: after a mutation or webhook, broadcast
function broadcastInvalidation(queryKeys: string[][]) {
  for (const client of sseClients) {
    client.write(`event: invalidate\ndata: ${JSON.stringify({ queryKeys })}\n\n`);
  }
}
```

### Direct data push (for high-frequency updates)

For live metrics, chat, or streaming data, push the actual data over WebSocket and write directly to cache with `queryClient.setQueryData`. Avoids a refetch round-trip.

### Presence indicators

Show "Agent Smith is viewing this ticket" or "Alice is editing this record" via WebSocket:

```typescript
// Client sends presence on route change
ws.send(JSON.stringify({
  type: 'presence.enter', entityType: 'ticket', entityId: ticketId, userId: currentUser.id,
}));

// Server tracks and broadcasts to other clients on the same entity
```

### Conflict detection

Use optimistic locking with a `version` field. When two users edit the same record, the second save detects the mismatch:

- Server: `WHERE id = :id AND version = :expectedVersion`. If no rows updated, return 409 Conflict.
- Client: on 409, show "This record was modified by another user. Refreshing..." and invalidate the query.

### When NOT to use real-time

| Feature | Real-time? | Why |
|---|---|---|
| Live metrics / charts | Yes | Data changes continuously |
| Notification bell count | Yes | User expects instant updates |
| Collaborative editing | Yes | Multiple users, same record |
| CRUD list pages | Usually no | Stale-while-revalidate is fine |
| Settings pages | No | Only current user changes these |
| Reports / analytics | No | Periodic refresh is acceptable |

SSE is simpler than WebSockets and sufficient for server-to-client push (the vast majority of dashboard real-time needs). Use WebSockets only for bidirectional communication (chat, collaborative editing, presence).

---

## Background job observability

### Job status model

Every async operation follows this lifecycle:

```
pending --> running --> completed
                   \-> failed
                   \-> cancelled
```

With metadata: progress (0-100%), ETA, started_at, completed_at, result (download URL, error summary, record count), created_by (user ID).

### Progress propagation

The worker reports progress. The dashboard polls (or subscribes via WebSocket). The UI shows a progress bar.

```typescript
// Worker:
async function processExport(job: Job) {
  for (let i = 0; i < records.length; i++) {
    await writeRecord(records[i]);
    await job.updateProgress(Math.round((i / records.length) * 100));
  }
  return { downloadUrl: '/exports/file.csv', recordCount: records.length };
}

// API:
app.get('/api/jobs/:id', async (req, res) => {
  const job = await exportQueue.getJob(req.params.id);
  res.json({
    id: job.id,
    state: await job.getState(),
    progress: job.progress,
    result: job.returnvalue,
    failedReason: job.failedReason,
  });
});
```

### Job registry UI

A page or panel listing all recent jobs the current user triggered:

- Job type and description
- Status indicator (pending/running/completed/failed)
- Progress bar for running jobs
- Download link for completed jobs with file results
- Retry button for failed jobs
- Cancel button for running jobs

Poll every 3 seconds while any job is active. Stop polling when all are terminal.

### Cancellation

The worker checks for cancellation periodically within long loops. The user requests cancel via the UI. The API sets a `cancelRequested` flag. The worker reads it and throws a CancelledError.

### Notification on completion

When a job completes, push an in-app notification AND invalidate the jobs list cache. Optionally send email for long-running jobs the user might have walked away from.

---

## System health and dependencies

### Health check endpoint

```typescript
app.get('/health', async (req, res) => {
  const checks = await Promise.allSettled([
    checkDatabase(),
    checkRedis(),
    checkStripe(),
    checkEmailService(),
    checkObjectStorage(),
  ]);

  const results = Object.fromEntries(
    ['database', 'redis', 'stripe', 'email', 'storage'].map((name, i) => [
      name,
      checks[i].status === 'fulfilled' ? checks[i].value : { status: 'down', error: checks[i].reason.message },
    ])
  );

  const overall = Object.values(results).every(r => r.status === 'healthy') ? 'healthy' : 'degraded';
  res.status(overall === 'healthy' ? 200 : 503).json({ status: overall, checks: results });
});
```

### Graceful degradation

If the email service is down, the dashboard should still work. Show "email delivery delayed," queue the email for retry, don't crash. Wrap every external dependency call with fallback behavior.

### Circuit breaker

Three states: **Closed** (normal), **Open** (requests fail immediately after N failures), **Half-Open** (test a few requests after timeout to see if dependency recovered).

Implement per external dependency. When the circuit opens, use the fallback path (queue for retry, show degraded state). When it closes, resume normal operation.

### Admin system status page

An admin-only page showing green/yellow/red per dependency with latency and last-checked timestamp. Poll every 15 seconds. Useful for ops teams and for debugging "why isn't email sending?"

---

## Shared data contracts

### Single source of truth for the current user

The user object is needed by: auth, RBAC, sidebar (name + avatar), user menu, audit log, billing, profile, notifications. Fetch it once, share everywhere via a query with long `staleTime` and infinite `gcTime`:

```typescript
export function useCurrentUser() {
  return useQuery({
    queryKey: ['currentUser'],
    queryFn: fetchCurrentUser,
    staleTime: 5 * 60 * 1000,
    gcTime: Infinity,
  });
}
```

When the user updates their name, invalidate `['currentUser']` and every consumer re-renders automatically.

### Shared entity types

Define entity types once, share between frontend and backend:

```typescript
// packages/shared/src/entities/user.ts
export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string(),
  role: z.enum(['admin', 'editor', 'viewer']),
  avatarUrl: z.string().url().nullable(),
  createdAt: z.string().datetime(),
});

export type User = z.infer<typeof UserSchema>;
```

The backend validates outgoing responses against the schema. The frontend validates incoming. Mismatches are caught at build time (TypeScript) and runtime (Zod).

### API response shape contracts

One shape per entity, used everywhere. This prevents the "the user list returns `firstName` but the user detail returns `first_name`" inconsistency that plagues dashboards without contracts.

---

## Error propagation and recovery

### Transactional vs non-transactional side effects

**Rule: database writes are transactional; external side effects are not.**

Wrap the mutation and audit log in a database transaction. Side effects that call external services (email, webhook) happen outside the transaction. If they fail, they go to a retry queue — not into the void.

### Saga / compensation for multi-step operations

For operations spanning multiple services (provision tenant in DB + Stripe + auth provider):

```typescript
async function provisionTenant(data) {
  const compensations = [];
  try {
    const tenant = await createTenant(data);
    compensations.push(() => deleteTenant(tenant.id));

    const stripeCustomer = await stripe.customers.create({ ... });
    compensations.push(() => stripe.customers.del(stripeCustomer.id));

    const authOrg = await authProvider.createOrg({ ... });
    compensations.push(() => authProvider.deleteOrg(authOrg.id));

    return { tenant, stripeCustomer, authOrg };
  } catch (error) {
    // Run compensations in reverse
    for (const compensate of compensations.reverse()) {
      try { await compensate(); } catch (e) { logger.error('Compensation failed', e); }
    }
    throw error;
  }
}
```

### Dead letter queue

Side effects that fail go to a retry queue. After exhausting retries, they move to a dead letter state — inspectable and manually retryable from the admin UI. Never into the void.

### Error correlation via request ID

Generate a unique request ID at the entry point. Propagate through every layer as `X-Request-ID` header. Include it in error toasts ("Reference: abc123") so support can search backend logs by the same ID.

---

## Feature flags

### Flags as an integration concern

A new feature may affect auth, RBAC, billing, navigation, and API endpoints simultaneously. All must be gated by the same flag, evaluated consistently on both server and client.

### Server + client evaluation

- **Server-side:** gate API endpoints, background jobs, webhook handlers. Evaluate the flag with user/org/plan context.
- **Client-side:** gate UI elements (sidebar items, buttons, pages). Evaluate the same flag with the same context.
- Both must return the same result for the same user.

```typescript
// Server: gate API
if (!flags.isEnabled('ai-routing', { userId, orgId, plan })) {
  return res.status(404).json({ error: 'Not found' });
}

// Client: gate UI
const { enabled } = useFeatureFlag('ai-routing');
{enabled && <SidebarItem href="/ai-routing">AI Routing</SidebarItem>}
```

### Gradual rollout

- **Percentage-based:** 10% of users see the feature. Deterministic hashing ensures consistency.
- **Per-org:** enable for specific organizations.
- **Per-user:** enable for internal testers.
- **Per-plan:** only enterprise plans.

### Kill switch

A flag that instantly disables a feature across all layers. The one flag type you never clean up. Every significant feature should have one.

### Flag cleanup

Stale flags are tech debt. Each one adds two code paths that both need testing.

- **30-day removal deadline** for release flags after full rollout.
- **20-30 active flags max** per service. Block new flags when stale flags exceed the threshold.
- **Quarterly audit:** review all flags, remove the dead ones.
- **Process:** remove from code, deploy, then remove from flag service.

---

## The integration layer — how it all connects

```
Feature Flag Gate
       |
API Route / Webhook / Background Job
       |
Service Layer (mutation + audit + events)
       |
  +----+----+----+
  |    |    |    |
  DB   Event  Audit
  Tx   Bus    Log
       |
  +----+----+
  |         |
Cache    WebSocket/SSE
Invalidation  Push
  |         |
Query     Notification
Client    Service
  |         |
  UI      Background
  Update   Job Queue
              |
           Job Registry
           + Progress UI
```

Every mutation flows through the service layer. The service emits events. Events trigger cache invalidation, real-time push, notifications, and background jobs. Jobs report progress. The health check monitors all dependencies. Feature flags gate the entire flow.

The entity registry connects the other axis — horizontal linking between features. Every entity reference is resolvable to a URL, a label, and an icon. Audit logs, activity feeds, notifications, search results, and table cells all use the same resolution mechanism. Nothing is a dead end.

---

## Don'ts

- **Don't let API routes touch the database directly.** Route through the service layer. Every mutation, every time.
- **Don't emit events without error isolation.** One subscriber failing must not break the primary operation.
- **Don't sprinkle `invalidateQueries` in individual mutation handlers.** Use a centralized invalidation map.
- **Don't render entity references as plain text.** Every entity mention is a link. Use the entity registry.
- **Don't fire-and-forget background jobs.** Every job must be trackable, cancellable, and reportable.
- **Don't ignore dependency health.** If Stripe is down and your billing page crashes, that's a missing circuit breaker.
- **Don't evaluate feature flags differently on server and client.** Same flag, same context, same result.
- **Don't let stale feature flags accumulate.** Remove within 30 days of full rollout.
- **Don't rely on API responses for async state.** Use webhooks, SSE, or polling for state changes that happen outside the request cycle.
- **Don't skip error correlation.** Request IDs connecting frontend errors to backend logs save hours of debugging.
- **Don't let side effects disappear on failure.** Dead letter queues, not silent swallowing.
- **Don't share the user object by passing it through props everywhere.** One query, one context provider, consumed by everything that needs it.
