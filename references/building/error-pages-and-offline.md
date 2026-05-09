# Error Pages & Offline States

Error pages are not edge cases — they are guaranteed UI surfaces. Every user will see a 404 eventually. Every app will have a server hiccup. Every mobile user will lose signal. Build these surfaces with the same care as your main dashboard. A well-crafted error page turns a frustrating dead end into a recoverable moment.

**Canonical scope:** full-page 404/403/500/503 pages, maintenance mode, PWA offline shell. **See also:** `states-and-feedback.md` for inline error states and toasts within active pages.

---

## Custom error pages

### The decision: app shell or standalone?

**Use the app shell** (sidebar, header, navigation) for error pages that the user reaches while already inside the app — 404 not found, 403 forbidden, section-level errors. The user is already oriented; ripping away the shell is disorienting.

**Use a standalone page** (no app shell, just the brand logo and centered content) for errors that prevent the app from loading at all — 500 server error, 503 maintenance, offline fallback. The app shell can't render because the app itself is down.

```
App-shell errors (user is inside the app):
┌──────────────────────────────────────────────────┐
│  [Logo]    Dashboard    Settings    [Avatar]     │
├──────┬───────────────────────────────────────────┤
│      │                                           │
│ Nav  │   ┌─────────────────────────────────┐     │
│      │   │  [Illustration]                 │     │
│      │   │                                 │     │
│      │   │  Page not found                 │     │
│      │   │  We couldn't find that page.    │     │
│      │   │  It may have been moved or      │     │
│      │   │  deleted.                       │     │
│      │   │                                 │     │
│      │   │  [Go to Dashboard]  [Go Back]   │     │
│      │   └─────────────────────────────────┘     │
│      │                                           │
└──────┴───────────────────────────────────────────┘

Standalone errors (app can't load):
┌──────────────────────────────────────────────────┐
│                                                  │
│              [Brand Logo]                        │
│                                                  │
│           [Illustration]                         │
│                                                  │
│        Something went wrong                      │
│        Our servers are having trouble.            │
│        We've been notified and are                │
│        working on it.                             │
│                                                  │
│       [Try Again]  [Status Page →]               │
│                                                  │
│      support@yourapp.com                         │
└──────────────────────────────────────────────────┘
```

### Layout specs for all error pages

- **Content is vertically and horizontally centered** within the available area (the content area if app-shell, the viewport if standalone).
- **Max content width:** 480px. Don't let error messages stretch across a widescreen monitor.
- **Illustration:** Optional. 200–300px wide, muted colors, brand-consistent. SVG preferred. Don't use stock photography. If you skip the illustration, use a large status code or icon instead.
- **Title:** h2 (24px, semibold). Short and scannable. "Page not found" not "Error 404: The requested resource could not be located."
- **Body:** 14–16px, regular weight, muted text color. 1–2 sentences max. Explain what happened and what the user should do.
- **Actions:** 1–2 buttons, primary + ghost/link. Always provide a way forward. Never leave the user with just a message and no action.
- **Spacing:** 24px between illustration and title, 12px between title and body, 24px between body and actions.

### 404 — Not Found

The most common error page. Users arrive here via stale bookmarks, broken links, typos in the URL, or deleted resources.

**Copy pattern:**
```
Title:  Page not found
Body:   The page you're looking for doesn't exist or has been moved.
```

**Actions to offer (in priority order):**
1. **Go to Dashboard** (primary button) — the safe home base
2. **Go Back** (ghost/link button) — `router.back()` or `history.back()`
3. **Search** (optional) — if your app has global search, include an inline search bar or link to it
4. **Contact Support** (link) — for apps where a missing page might indicate a real problem

**Framework implementation (Next.js App Router):**

```typescript
// app/not-found.tsx — catches unmatched routes
export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] max-w-md mx-auto text-center px-4">
      <NotFoundIllustration className="w-64 h-48 mb-6" />
      <h2 className="text-2xl font-semibold mb-2">Page not found</h2>
      <p className="text-muted-foreground mb-6">
        The page you're looking for doesn't exist or has been moved.
      </p>
      <div className="flex gap-3">
        <Button asChild>
          <Link href="/dashboard">Go to Dashboard</Link>
        </Button>
        <BackButton variant="ghost" />
      </div>
    </div>
  );
}
```

```typescript
// app/customers/[id]/not-found.tsx — resource-specific 404
export default function CustomerNotFound() {
  return (
    <ErrorState
      title="Customer not found"
      description="This customer may have been deleted or you may not have access."
      actions={[
        { label: 'View all customers', href: '/customers', primary: true },
        { label: 'Go back', action: 'back' },
      ]}
    />
  );
}
```

**Resource-specific copy is better than generic copy.** "Customer not found" beats "Page not found" when the user was trying to view a customer. Use route-segment `not-found.tsx` files in Next.js to customize per entity.

### 403 — Forbidden

The user is authenticated but doesn't have permission. This is a trust-sensitive surface — the user might be confused or suspicious. Don't be vague.

**Copy pattern:**
```
Title:  You don't have access to this page
Body:   Contact your admin to request access, or return to the dashboard.
```

**Never say:** "Forbidden" (intimidating), "Access denied" (ambiguous — could mean auth problem). Say what they can do about it.

**Actions:**
1. **Go to Dashboard** (primary)
2. **Contact Admin** (link) — link to the team admin's profile or a support email
3. **Request Access** (link/button) — if your app supports access requests, include this

**What not to show:** Don't reveal what's behind the permission wall. Don't say "This is the billing page and you don't have billing access" if the user shouldn't know billing exists. Just say "You don't have access."

### 500 — Server Error

Something broke on your end. This is a trust-damaging moment. Acknowledge responsibility, give the user a next step, and log aggressively on the backend.

**Copy pattern:**
```
Title:  Something went wrong
Body:   We're having trouble on our end. Our team has been notified. 
        Please try again in a moment.
```

**Actions:**
1. **Try Again** (primary) — refreshes the page or retries the request
2. **Go to Dashboard** (ghost)
3. **Status Page** (link) — if you have one (you should)
4. **Contact Support** (link) — include a reference ID

**The reference ID pattern:** Generate a unique error ID on the server, include it in the error response, display it on the error page. "Error reference: ERR-a1b2c3d4." When the user contacts support, they cite this ID and the support team can find the exact error in the logs.

```typescript
// app/error.tsx — per-route error boundary
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] max-w-md mx-auto text-center px-4">
      <ServerErrorIllustration className="w-64 h-48 mb-6" />
      <h2 className="text-2xl font-semibold mb-2">Something went wrong</h2>
      <p className="text-muted-foreground mb-4">
        We're having trouble on our end. Our team has been notified.
      </p>
      {error.digest && (
        <p className="text-xs text-muted-foreground mb-6 font-mono">
          Reference: {error.digest}
        </p>
      )}
      <div className="flex gap-3">
        <Button onClick={reset}>Try Again</Button>
        <Button variant="ghost" asChild>
          <Link href="/dashboard">Go to Dashboard</Link>
        </Button>
      </div>
    </div>
  );
}
```

```typescript
// app/global-error.tsx — root layout crashes (standalone, no app shell)
'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <div className="min-h-screen flex flex-col items-center justify-center bg-background text-foreground px-4">
          <BrandLogo className="h-8 mb-12" />
          <h2 className="text-2xl font-semibold mb-2">Something went wrong</h2>
          <p className="text-muted-foreground mb-6 text-center max-w-md">
            We're having trouble loading the app. Please try refreshing.
          </p>
          <Button onClick={reset}>Refresh</Button>
          <a href="https://status.yourapp.com" className="mt-4 text-sm text-muted-foreground underline">
            Check system status
          </a>
        </div>
      </body>
    </html>
  );
}
```

### 503 — Maintenance Mode

Two flavors: scheduled (planned downtime) and unscheduled (something broke and you're fixing it).

**Always standalone** — the app can't serve its shell.

**HTTP requirements:**
- Status code: `503 Service Unavailable`
- Header: `Retry-After: 3600` (seconds) or `Retry-After: Wed, 12 Apr 2026 07:00:00 GMT` (HTTP-date)
- Cache-Control: `no-store` — don't let CDNs cache the maintenance page permanently
- The maintenance page must be a static file served by the reverse proxy (Nginx, Cloudflare, etc.) — not by the application server, since the application server is down

**Scheduled maintenance copy:**
```
Title:  Scheduled maintenance
Body:   We're upgrading our systems and will be back shortly.
        Estimated return: [date/time with timezone].
```

**Unscheduled maintenance copy:**
```
Title:  We'll be right back
Body:   We're experiencing an issue and our team is working on it.
        Check our status page for updates.
```

**What to include on maintenance pages:**

1. **Brand logo** — reassures users they're in the right place
2. **Clear headline** — "Scheduled maintenance" or "We'll be right back"
3. **Expected return time** — for scheduled, show a countdown timer or specific time. Include timezone.
4. **Status page link** — always. Use a separate domain (status.yourapp.com) hosted on a different provider (Statuspage, Instatus, Betterstack) so it's reachable when your main app isn't.
5. **Email notification signup** — "Get notified when we're back." A simple email input + submit that posts to a third-party email service (not your own backend, which is down).
6. **Social media links** — Twitter/X and other channels where you post real-time updates

**Countdown timer spec:**
```
┌──────────────────────────────┐
│                              │
│  [Brand Logo]                │
│                              │
│  Scheduled maintenance       │
│                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ │
│  │  01  │ │  23  │ │  45  │ │
│  │ hrs  │ │ min  │ │ sec  │ │
│  └──────┘ └──────┘ └──────┘ │
│                              │
│  We'll be back by            │
│  April 12, 2026 at 7:00 AM  │
│  UTC                         │
│                              │
│  [Check Status Page]         │
│  [Notify me when back →]     │
│                              │
└──────────────────────────────┘
```

- Countdown digits: 48px+ font, monospace, centered in pill-shaped containers
- Segment labels ("hrs", "min", "sec"): 12px, muted, below the digits
- Update every second — use `setInterval` or `requestAnimationFrame`
- When the countdown hits zero, auto-reload the page with `location.reload()`

**Serving the maintenance page (Nginx):**

```nginx
# Maintenance mode — serve static page when maintenance file exists
if (-f /var/www/maintenance.html) {
    return 503;
}

error_page 503 @maintenance;

location @maintenance {
    root /var/www;
    rewrite ^(.*)$ /maintenance.html break;
    add_header Retry-After 3600 always;
    add_header Cache-Control "no-store" always;
}
```

**The maintenance page must be fully self-contained:** inline CSS, inline SVG, no external dependencies. Your CDN or asset pipeline might be down too. One HTML file, zero external requests.

---

## Offline fallback (PWA)

For dashboards used on unreliable connections — field services, mobile, travel — a PWA offline strategy keeps the app usable instead of showing a browser error page.

### Service worker caching strategies

Use the right strategy per resource type:

| Resource type | Strategy | Why |
|---|---|---|
| App shell (HTML, JS, CSS) | **Cache-first** | The shell rarely changes; serve instantly, update in background |
| Static assets (images, fonts, icons) | **Cache-first** | Immutable or versioned; always serve from cache |
| API data (dashboard data, lists) | **Network-first, fallback to cache** | Show fresh data when online, stale data when offline |
| User-generated content | **Network-first** | Must be fresh, but show cached version as fallback |
| Auth endpoints | **Network-only** | Never cache auth tokens or session data |
| Analytics/telemetry | **Network-only** | Queue and replay when online, don't cache |

### What to cache vs. what requires network

**Cache aggressively:**
- App shell HTML
- CSS and JS bundles (hashed filenames = safe to cache indefinitely)
- Brand assets (logo, icons, illustrations)
- Font files
- Recent API responses (for stale-while-revalidate display)
- Offline fallback page

**Never cache:**
- Authentication tokens or session cookies
- Payment or financial data
- Real-time data that's dangerous when stale (stock prices, medical data)
- File uploads in progress
- WebSocket connections

### The offline page

When a navigation request fails and there's no cached version, serve a branded offline page. This replaces the browser's "No internet" dinosaur game.

```typescript
// service-worker.ts — cache offline page on install
const OFFLINE_PAGE = '/offline';
const CACHE_NAME = 'app-shell-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => 
      cache.addAll([OFFLINE_PAGE, '/icons/offline.svg'])
    )
  );
});

// Serve offline page when navigation request fails
self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => 
        caches.match(OFFLINE_PAGE)
      )
    );
  }
});
```

**Offline page content:**
```
┌──────────────────────────────┐
│                              │
│  [Brand Logo]                │
│                              │
│  [Offline icon — cloud       │
│   with slash]                │
│                              │
│  You're offline              │
│                              │
│  Check your connection and   │
│  try again. Any changes      │
│  you've made will sync       │
│  when you're back online.    │
│                              │
│  [Try Again]                 │
│                              │
└──────────────────────────────┘
```

- Auto-retry: listen for the `online` event and reload automatically
- If the app supports offline work, show what's available: "You can still view recently opened [customers/reports/etc.]"
- Must be self-contained (inline CSS, cached SVG) — the network is down, you can't fetch external assets

### Sync-when-back patterns

When the user performs mutations while offline:

1. **Queue mutations** in IndexedDB (not localStorage — IndexedDB handles structured data and larger payloads)
2. **Show a persistent banner:** "You're offline. Changes will sync when you reconnect."
3. **Mark queued items visually** — a small clock icon or "Pending sync" label next to items modified offline
4. **On reconnection:** replay the queue in order, handle conflicts (server state may have changed)
5. **Clear the banner and pending indicators** after successful sync
6. **If a queued mutation fails on replay:** surface it to the user — "1 change couldn't be saved. [View details]"

```typescript
// Detect connectivity (events are unreliable — verify with heartbeat)
function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const verify = async () => {
      try {
        await fetch('/api/health', { method: 'HEAD', cache: 'no-store' });
        setIsOnline(true);
      } catch {
        setIsOnline(false);
      }
    };

    window.addEventListener('online', verify);
    window.addEventListener('offline', () => setIsOnline(false));

    // Heartbeat every 30s when supposedly online
    const interval = setInterval(verify, 30_000);
    return () => clearInterval(interval);
  }, []);

  return isOnline;
}
```

---

## Partial failures

The most realistic error scenario in dashboards: one API call fails but others succeed. The page is partially loaded. This is where error boundaries earn their keep.

### Error boundary strategy

Wrap each independent section of the dashboard in its own error boundary. A failure in the revenue chart should not take down the entire page.

```
┌──────────────────────────────────────────────────┐
│  Dashboard                                       │
├──────────────────┬───────────────────────────────┤
│                  │  ┌──────────┐  ┌──────────┐   │
│                  │  │ Revenue  │  │ Users    │   │
│  Navigation      │  │ ✓ loaded │  │ ✓ loaded │   │
│                  │  └──────────┘  └──────────┘   │
│                  │  ┌──────────┐  ┌──────────┐   │
│                  │  │ Activity │  │ Alerts   │   │
│                  │  │ ✗ FAILED │  │ ✓ loaded │   │
│                  │  │ [Retry]  │  │          │   │
│                  │  └──────────┘  └──────────┘   │
└──────────────────┴───────────────────────────────┘
```

### React implementation

```tsx
// Section-level error boundary
import { ErrorBoundary } from 'react-error-boundary';

function SectionErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 border border-dashed border-destructive/30 rounded-lg bg-destructive/5 min-h-[200px]">
      <AlertCircle className="h-8 w-8 text-destructive mb-3" />
      <p className="text-sm font-medium mb-1">Failed to load this section</p>
      <p className="text-xs text-muted-foreground mb-4">
        The rest of the page is working normally.
      </p>
      <Button size="sm" variant="outline" onClick={resetErrorBoundary}>
        Try again
      </Button>
    </div>
  );
}

// Usage — wrap each dashboard widget
function DashboardPage() {
  return (
    <div className="grid grid-cols-2 gap-6">
      <ErrorBoundary FallbackComponent={SectionErrorFallback}>
        <Suspense fallback={<RevenueChartSkeleton />}>
          <RevenueChart />
        </Suspense>
      </ErrorBoundary>

      <ErrorBoundary FallbackComponent={SectionErrorFallback}>
        <Suspense fallback={<UsersSkeleton />}>
          <UsersWidget />
        </Suspense>
      </ErrorBoundary>

      <ErrorBoundary FallbackComponent={SectionErrorFallback}>
        <Suspense fallback={<ActivitySkeleton />}>
          <ActivityFeed />
        </Suspense>
      </ErrorBoundary>

      <ErrorBoundary FallbackComponent={SectionErrorFallback}>
        <Suspense fallback={<AlertsSkeleton />}>
          <AlertsWidget />
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

### Vue/Nuxt equivalent

```vue
<!-- ErrorBoundary.vue -->
<script setup lang="ts">
import { onErrorCaptured, ref } from 'vue';

const error = ref<Error | null>(null);
const retry = () => { error.value = null; };

onErrorCaptured((err) => {
  error.value = err;
  return false; // prevent propagation
});
</script>

<template>
  <div v-if="error" class="section-error">
    <p>Failed to load this section</p>
    <button @click="retry">Try again</button>
  </div>
  <slot v-else />
</template>
```

### Section error fallback design rules

- **Match the dimensions** of the section it replaces. A failed chart widget should be the same height as the chart skeleton, not collapse to a tiny error box.
- **Use a dashed border** + subtle destructive background (`bg-destructive/5`) to visually distinguish from the surrounding content without being alarming.
- **Minimum height:** 200px for card-sized sections, 120px for smaller widgets.
- **Include the retry button** — retries only the failed section, not the whole page.
- **After 3 failed retries**, show: "This section is unavailable. [Contact support]" and stop auto-retrying.
- **Don't show technical details** in the fallback. Log them to your error tracker.

### Handling async errors in boundaries

React error boundaries only catch render-time errors by default. For async errors (failed API calls), convert them:

```typescript
// Hook to throw async errors into the nearest error boundary
function useAsyncError() {
  const [, setError] = useState();
  return useCallback((error: Error) => {
    setError(() => { throw error; });
  }, []);
}

// In a data-fetching component
function RevenueChart() {
  const throwError = useAsyncError();
  const { data, error } = useSWR('/api/revenue');
  
  if (error) throwError(error);
  if (!data) return <Skeleton />;
  
  return <Chart data={data} />;
}
```

---

## Rate limiting pages (429)

When users hit rate limits — either from legitimate heavy usage or automated actions — show a helpful page, not a raw error.

### HTTP response

```
HTTP/1.1 429 Too Many Requests
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1713000000
Content-Type: text/html
```

### User-facing design

**Copy pattern:**
```
Title:  Slow down — too many requests
Body:   You've made a lot of requests in a short time. 
        Please wait a moment before trying again.
```

**Don't say:** "Rate limited" (technical jargon), "Error 429" (meaningless to users), "Abuse detected" (accusatory).

**Countdown timer:**
- Parse the `Retry-After` header value (seconds until retry)
- Display a countdown: "You can try again in 47 seconds"
- Update every second
- When the countdown reaches zero, automatically enable the retry button or auto-navigate
- Use a circular progress indicator or simple text countdown — don't over-design this

```typescript
function RateLimitCountdown({ retryAfter }: { retryAfter: number }) {
  const [remaining, setRemaining] = useState(retryAfter);

  useEffect(() => {
    const timer = setInterval(() => {
      setRemaining((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [retryAfter]);

  if (remaining === 0) {
    return <Button onClick={() => location.reload()}>Try again now</Button>;
  }

  return (
    <p className="text-sm text-muted-foreground">
      You can try again in <span className="font-mono font-medium">{remaining}s</span>
    </p>
  );
}
```

### When to show the rate limit page

- **Full page 429:** when the entire page request is rate limited (rare — usually API-level)
- **Inline 429:** when a specific action is rate limited (more common — form submissions, API calls). Show as a toast or inline message, not a full page: "Too many attempts. Please wait 30 seconds."
- **Login rate limiting:** after N failed attempts, show: "Too many login attempts. Try again in 5 minutes." This is a security measure — include it in auth UX.

---

## Expired/invalid links

Users reach these from emails (password reset, invitation, share links) where the token has expired, been used, or is malformed.

### General principles

1. **Tell the user what happened** — "This link has expired" is clearer than "Invalid token"
2. **Tell them why** — "Password reset links expire after 24 hours for security"
3. **Give them a specific next action** — not just "go home" but "Request a new password reset link"
4. **Don't reveal security details** — don't say whether the link was used or expired, if that distinction matters for security. Just say it's no longer valid.

### Password reset link expired

```
Title:  This password reset link has expired
Body:   For security, password reset links are valid for 24 hours.
        Request a new one below.

Action: [Request new reset link] (primary)
        [Back to sign in] (link)
```

After clicking "Request new reset link," pre-fill the email address if you can derive it from the token (even an expired token can contain the email claim).

### Invitation link expired

```
Title:  This invitation has expired
Body:   Invitation links expire after 7 days. Ask your team admin
        to send a new one.

Action: [Contact your admin] (primary) — mailto: or in-app
        [Sign in] (link) — in case they already have an account
```

### Share link expired or revoked

```
Title:  This link is no longer active
Body:   The shared content may have been removed or the link 
        may have expired. Contact the person who shared it.

Action: [Go to Dashboard] (primary) — if authenticated
        [Sign in] (primary) — if not authenticated
```

### Magic link / email login link expired

```
Title:  This sign-in link has expired
Body:   Sign-in links are valid for 15 minutes. Request a new one.

Action: [Request new sign-in link] (primary)
```

### Design patterns for all expired link pages

- Use the **standalone layout** (no app shell) — the user likely isn't authenticated
- Include the **brand logo** at the top
- Keep the page **simple and focused** — one explanation, one primary action
- **Don't redirect to the login page with a generic error flash.** Show a dedicated expiration page. The user needs to understand what happened, not just see "something went wrong" on a login form.
- **Never expose the token** in error messages or URLs after determining it's invalid

---

## Error page copy rules

These apply across all error surfaces:

1. **Use plain language.** "Something went wrong" not "An unexpected error has occurred."
2. **Be specific when you can.** "Customer not found" beats "Resource not found" beats "Not found" beats "Error."
3. **Take responsibility for server errors.** "We're having trouble" not "An error occurred" (passive voice that implies it's nobody's fault, or worse, the user's fault).
4. **Don't use humor on error pages.** The user is at work, mid-task, frustrated. A witty 500 page is memorable the first time and infuriating the tenth.
5. **Don't show HTTP status codes prominently.** "404" means nothing to most users. Use it as a small subtitle or reference, not the headline.
6. **Always provide an action.** Every error page must have at least one button or link that moves the user forward. Dead-end error pages are never acceptable.
7. **Include a support escape hatch.** For any error that the user can't self-resolve, include a link to contact support, ideally pre-populated with the error reference ID.

---

## Don'ts

- **Don't show browser default error pages.** Every HTTP error code your app can produce should have a custom page.
- **Don't cache error pages.** Set `Cache-Control: no-store` on 5xx and 503 responses. You don't want CDNs serving a maintenance page for hours after the app is back up.
- **Don't use the same generic page for every error code.** 404 and 500 have different causes, different copy, and different actions.
- **Don't show stack traces, exception names, or library versions** in any user-facing error UI. Send them to Sentry/Datadog/Bugsnag.
- **Don't require JavaScript for standalone error pages.** The maintenance page and global error page should work with JS disabled — they're served when the app itself might be broken.
- **Don't forget to test error pages.** Visit `/this-page-does-not-exist`, kill your API server and reload, expire a test token. Error pages are UI — test them like UI.
- **Don't auto-retry indefinitely.** Cap automatic retries at 3 with exponential backoff (1s, 2s, 4s). After that, require manual action.
