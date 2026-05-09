# Real-Time and Collaborative UX Patterns

This file covers everything about making a dashboard feel alive and multi-user: presence, live cursors, collaborative editing, real-time data, notifications, and the WebSocket plumbing underneath. These patterns turn a static CRUD app into a workspace people share simultaneously.

The goal is **awareness without distraction**. Users should always know who else is here and what's changing, but never feel overwhelmed by movement.

---

## Presence indicators

Presence answers the question "who's here right now?" It's the foundation of every collaborative feature.

### Status dot system

Use the avatar status dot from `ui-design-patterns.md` (8-12px circle, bottom-right, 2px white ring), with these states:

| Status | Color | Meaning | Auto-trigger |
|---|---|---|---|
| Online | Green (`#22c55e`) | Active in the last 2 minutes | Any interaction (click, keystroke, scroll) |
| Away | Amber (`#f59e0b`) | No interaction for 2-5 minutes | Idle timer fires |
| Offline | Gray (`#9ca3af`) | Disconnected or inactive > 5 minutes | WebSocket close or timeout |
| DND | Red (`#ef4444`) | User manually set Do Not Disturb | User action only, never auto-set |

**Rules:**
- Transition online-to-away after **2 minutes** of no interaction. This is the Slack/Discord consensus.
- Transition away-to-offline after **5 minutes** or on WebSocket disconnect.
- DND is always user-initiated. Never auto-set it.
- Show a "last seen" timestamp for offline users: "Last seen 3h ago". Use relative time, not absolute.

### "X users viewing" indicator

Show a count + avatar stack when multiple users are on the same page/resource.

```
[avatar][avatar][avatar] +4 viewing
```

**Implementation:**
- Avatar stack: overlap by 25% of width (`margin-left: -8px` for 32px avatars). Show max 3 faces, then `+N` pill.
- Position: top-right of the page header or within a resource card header.
- Update count via WebSocket presence channel — subscribe to `presence:page:{pageId}`.
- Clicking the avatar stack opens a popover listing all viewers: avatar, name, role, and how long they've been on the page.

```css
.avatar-stack {
  display: flex;
  flex-direction: row-reverse; /* newest on left */
}
.avatar-stack > * {
  margin-left: -8px;
  border: 2px solid var(--bg-surface);
  border-radius: 9999px;
}
.avatar-stack > *:last-child {
  margin-left: 0;
}
```

### WebSocket vs polling for presence

**Use WebSocket.** Polling for presence is wasteful and laggy.

| Approach | Latency | Server load | When to use |
|---|---|---|---|
| WebSocket presence channel | ~50ms | Low (push-based) | Default choice. Always. |
| Short polling (5s interval) | 0-5s | High (N users * 12 req/min) | Legacy fallback only |
| Long polling | ~100ms | Medium | If WebSocket is blocked by proxy |
| SSE (Server-Sent Events) | ~100ms | Medium | Read-only presence (no client-to-server) |

WebSocket presence pattern:
1. Client connects and joins a channel: `presence:page:{id}`.
2. Server broadcasts `user_joined` with user metadata (id, name, avatar, color).
3. Client receives existing member list on join.
4. Heartbeat every **30 seconds** — server marks user offline if 2 heartbeats missed (60s timeout).
5. On disconnect, server broadcasts `user_left` after a **5-second grace period** (covers brief reconnects).

---

## Live cursors

Live cursors show where other users are pointing in real time. This is the signature feature of multiplayer tools like Figma and Notion.

### When to use

- **Yes:** Whiteboards, design tools, spreadsheets, document editors, kanban boards, any spatial canvas.
- **No:** Simple forms, settings pages, table views with no spatial context. Don't show cursors where they add no information.

### Cursor rendering

Each remote cursor is an absolutely positioned element with:
- A **colored arrow** (SVG, 16-20px). Each user gets a unique color from a preset palette of 8-12 high-contrast colors.
- A **name label** pinned to the cursor. Background matches cursor color, white text, `text-xs` (12px), `font-medium`, `border-radius: 4px`, `padding: 2px 8px`. Appears 4px below and 12px right of the cursor tip.
- **Smooth interpolation** between positions. Don't snap — lerp (linear interpolation) over 50-100ms for fluid movement.

```css
.remote-cursor {
  position: absolute;
  pointer-events: none;
  z-index: 50;
  transition: transform 80ms linear; /* smooth interpolation */
}
.remote-cursor__label {
  position: absolute;
  top: 20px;
  left: 12px;
  font-size: 12px;
  font-weight: 500;
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  white-space: nowrap;
  line-height: 1.2;
}
```

### Performance at scale

Cursor updates are high-frequency. Unthrottled, they generate 60+ events/second per user. This destroys performance at scale.

**Throttle to 50-100ms** (10-20 updates/second). This is imperceptible to humans but cuts bandwidth 3-6x.

| Users in room | Unthrottled (60fps) | Throttled (15fps) | Savings |
|---|---|---|---|
| 5 | 300 msg/s | 75 msg/s | 75% |
| 20 | 1,200 msg/s | 300 msg/s | 75% |
| 50 | 3,000 msg/s | 750 msg/s | 75% |

**Additional optimizations:**
- **Viewport culling:** Don't render cursors outside the visible viewport. Still receive updates (for the avatar stack count), but skip DOM rendering.
- **Idle hiding:** Fade out cursors that haven't moved in 5 seconds. Fade back on movement.
- **Batch updates:** Send cursor position changes in batches rather than individual messages. Collect positions over a 50ms window, send once.
- **Binary protocol:** Use binary WebSocket frames for cursor positions (userId as uint32 + x,y as float32 = 12 bytes vs ~80 bytes JSON).

```typescript
// Throttled cursor broadcast — 50ms minimum interval
let lastSent = 0;
const THROTTLE_MS = 50;

document.addEventListener('mousemove', (e) => {
  const now = Date.now();
  if (now - lastSent < THROTTLE_MS) return;
  lastSent = now;
  ws.send(JSON.stringify({
    type: 'cursor',
    x: e.clientX,
    y: e.clientY,
  }));
});
```

---

## Collaborative editing

When multiple users edit the same resource, you need conflict resolution, visual indicators of who's editing what, and version history.

### Conflict resolution strategies

Pick one. Don't mix them within the same feature.

| Strategy | How it works | Best for | Trade-off |
|---|---|---|---|
| **Last-write-wins (LWW)** | Latest timestamp wins, earlier edit discarded | Simple fields (name, status, single values) | Edits can be silently lost |
| **Operational Transform (OT)** | Server transforms concurrent operations to preserve intent | Rich text (Google Docs model) | Requires central server, complex to implement |
| **CRDT** | Data structure merges automatically without conflicts | Offline-first, decentralized, rich text | Higher memory overhead, eventual consistency |
| **Field-level locking** | Lock the field when someone starts editing, release on blur | Forms, structured data, config pages | Blocks concurrent edits entirely |

**For dashboards, use this decision tree:**
1. **Simple form fields (name, description, single values):** Field-level locking. Show who holds the lock.
2. **Rich text / long-form content:** CRDT (Yjs or Automerge). OT if you need Google Docs-level intent preservation and have a dedicated server.
3. **Structured data (status, assignee, dates):** Last-write-wins with optimistic UI and conflict toast.

### Field-level locking UI

When User A focuses on a field, broadcast a lock. Other users see:

- A **colored border** (2px solid, User A's assigned color) around the locked field.
- User A's **name label** above or beside the field (same style as cursor labels: colored bg, white text, 12px, border-radius 4px).
- The field becomes **read-only** for others while locked. Show `cursor: not-allowed` on hover.
- **Auto-release** the lock after **30 seconds** of no keystrokes (idle timeout). Also release on blur, navigation, or disconnect.

```css
.field-locked {
  border: 2px solid var(--lock-owner-color);
  border-radius: 6px;
  position: relative;
}
.field-locked::before {
  content: attr(data-locked-by);
  position: absolute;
  top: -24px;
  left: 8px;
  background: var(--lock-owner-color);
  color: white;
  font-size: 12px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 4px;
}
```

### "Someone else is editing this" warnings

For last-write-wins fields that don't use locking, show a warning when a conflict occurs:

- **Pre-conflict:** "Sarah is also editing this field" — shown as an inline hint below the field when another user focuses the same field. Informational, doesn't block.
- **Post-conflict:** "This field was updated by Sarah. Your version: [X]. Current version: [Y]. Keep yours / Accept theirs / View diff" — toast or inline conflict resolver.

### Highlighted editing sections

In document/content editors, show each user's active selection or cursor position:

- Background highlight in the user's assigned color at **10-15% opacity**.
- Cursor line (blinking caret) in the user's color at full opacity, 2px wide.
- Name label at the cursor position (same style as live cursors).

### Version history sidebar

Every collaborative document needs a version history. Pattern:

- **Trigger:** "History" or clock icon in the toolbar. Opens a right sidebar (320-400px wide).
- **Timeline:** Vertical list, newest at top. Each entry shows: user avatar, name, relative timestamp, and a summary of changes ("Edited section 3", "Changed title").
- **Grouping:** Collapse rapid edits from the same user within 5 minutes into a single entry.
- **Restore:** "Restore this version" button per entry. Restoring creates a new version (non-destructive).
- **Diff view:** Clicking an entry shows additions (green bg) and deletions (red bg with strikethrough) inline.

---

## Real-time data updates

Dashboards display live data — metrics, charts, tables. Updates must feel smooth, not jarring.

### Animating number changes

Never hard-swap a number. Always transition.

- **Count-up/count-down animation:** Interpolate from old value to new over **300-400ms** using `ease-out`. CSS `@property` with `counter` or JS `requestAnimationFrame`.
- **Use `font-variant-numeric: tabular-nums`** so digits don't cause layout shifts as values change.

```css
@property --num {
  syntax: "<integer>";
  initial-value: 0;
  inherits: false;
}

.stat-value {
  transition: --num 400ms ease-out;
  counter-reset: num var(--num);
  font-variant-numeric: tabular-nums;
}
.stat-value::after {
  content: counter(num);
}
```

### Diff highlighting (flash new values)

When a value changes, briefly flash the cell/element to draw attention.

- **Flash color:** Use a subtle background flash. Green tint (`rgba(34, 197, 94, 0.15)`) for increases, red tint (`rgba(239, 68, 68, 0.15)`) for decreases, blue tint for neutral changes.
- **Duration:** Flash on for **200ms**, fade out over **1000ms** (total 1.2s). Long enough to notice, short enough to not distract.
- **Scope:** Flash the specific cell, not the entire row. If many cells update simultaneously, consider flashing only cells that changed meaningfully (>1% delta).

```css
@keyframes flash-increase {
  0% { background-color: rgba(34, 197, 94, 0.2); }
  100% { background-color: transparent; }
}
@keyframes flash-decrease {
  0% { background-color: rgba(239, 68, 68, 0.2); }
  100% { background-color: transparent; }
}
.cell-updated-up {
  animation: flash-increase 1.2s ease-out;
}
.cell-updated-down {
  animation: flash-decrease 1.2s ease-out;
}
```

### Charts and graphs

- **Append new data points** with a smooth slide-in animation (300ms). Don't redraw the entire chart.
- **Axis rescaling:** If the new data forces an axis change, animate the axis transition over 400ms before the new data renders. Jumping axes is disorienting.
- **Streaming mode:** For continuously updating charts (1-5s intervals), use a rolling window. New point enters right, oldest exits left.

### Connection status indicator

Always show WebSocket connection state. Users must know if their data is live.

| State | Icon | Label | Color | Position |
|---|---|---|---|---|
| Connected | Filled circle or signal bars | "Live" or "Connected" | Green | Bottom-left of page or header bar |
| Reconnecting | Spinning circle | "Reconnecting..." | Amber | Same position |
| Disconnected | Slashed circle | "Offline — data may be stale" | Red | Same position, more prominent |

**Rules:**
- Don't show "Connected" status at all when things are healthy — it's noise. Only show status when it degrades.
- "Reconnecting" should appear after **2 seconds** of disconnect (not immediately — brief drops are invisible).
- "Disconnected" appears after **3 failed reconnection attempts** or 30 seconds without connection.
- Clicking the disconnected indicator triggers a manual reconnect attempt.

### Stale data warnings

When the WebSocket is disconnected and data is potentially stale:

- Show a **banner** at the top of the data area: "Data last updated 2 minutes ago. Reconnecting..." — amber background, dismiss-on-reconnect.
- **Dim** the data area slightly (`opacity: 0.7`) to visually signal staleness.
- Add a **timestamp** to stat cards and tables: "Updated 2m ago" in caption text (12px, muted).
- On reconnect, fetch a full state snapshot before removing the stale warning.

---

## Real-time notifications

Notifications tell users about events they didn't directly cause — other users' actions, system events, background job completions.

### Toast notifications

Toasts are the primary vehicle for transient notifications.

**Positioning:** Top-right corner, 16px from edge. Stack vertically, newest on top, max 3 visible at once (queue the rest).

**Anatomy:**

```
[icon] [title — bold, 14px]                              [X close]
       [description — regular, 13px, muted color]
       [action link — "View" / "Undo" — 13px, primary color]
```

- **Width:** 360-420px fixed.
- **Duration:** 5 seconds for informational, 8 seconds if there's an action. Persistent (no auto-dismiss) for errors.
- **Animation:** Slide in from right, 200ms ease-out. Fade + slide out, 150ms.
- **Hover pauses** the auto-dismiss timer.

**Types:**

| Type | Icon | Use case | Auto-dismiss |
|---|---|---|---|
| Info | Info circle (blue) | "Sarah created a new order" | 5s |
| Success | Checkmark (green) | "Export completed" | 5s |
| Warning | Triangle (amber) | "API rate limit approaching" | 8s |
| Error | X circle (red) | "Failed to save changes" | Never |

### Activity feed

For a persistent log of team activity, use an activity feed panel.

- **Position:** Right sidebar (320-400px) or dedicated page. Toggle via bell icon in header.
- **Entry format:** `[avatar] [user name] [action verb] [object] — [relative time]`
  - Example: "Sarah created Order #1234 — 5m ago"
- **Grouping:** Collapse repeated actions from the same user within 2 minutes. "Sarah created 3 orders — 5m ago".
- **Filtering:** Tabs or dropdown to filter by: All, Mentions, My Activity, System.
- **Pagination:** Infinite scroll with "Load more" at the bottom.

### @mention notifications

- In-app: Toast + activity feed entry + unread badge on bell icon.
- Push: Desktop notification (if permission granted) with sound.
- Email: Digest email if user is offline for >15 minutes (configurable).

**Desktop notification permissions:** Ask for permission contextually, not on page load. Trigger the browser permission prompt when the user first enables notifications in their settings, not randomly.

### Sound

- **Default: off.** Sound is disruptive in shared workspaces.
- Provide a toggle in notification settings. If enabled, use a single short tone (<500ms) for mentions only, not for every notification.
- Never auto-play sound without user opt-in.

---

## WebSocket UX patterns

### Connection lifecycle

Every WebSocket implementation must handle this state machine:

```
[Connecting] --> [Connected] --> [Disconnected]
                     ^                |
                     |                v
                [Reconnecting] <------
```

**States and UI behavior:**

| State | User sees | System behavior |
|---|---|---|
| Connecting | Loading spinner or skeleton | Initial handshake in progress |
| Connected | Normal UI, data flowing | Full-duplex active |
| Reconnecting | "Reconnecting..." indicator | Exponential backoff in progress |
| Disconnected | "Offline" banner + stale data treatment | All retries exhausted or user offline |

### Reconnection with exponential backoff

On disconnect, reconnect automatically with increasing delays.

```typescript
function reconnect(attempt: number = 0) {
  const maxDelay = 30_000; // 30s cap
  const baseDelay = 500;   // Start at 500ms
  const delay = Math.min(
    baseDelay * Math.pow(2, attempt) + Math.random() * 1000, // jitter
    maxDelay
  );

  setTimeout(() => {
    const ws = new WebSocket(url);
    ws.onopen = () => {
      attempt = 0; // reset on success
      resync();    // fetch missed state
    };
    ws.onclose = () => reconnect(attempt + 1);
  }, delay);
}
```

**Schedule:** 500ms, 1s, 2s, 4s, 8s, 16s, 30s, 30s, 30s... (cap at 30s).

**Jitter:** Add 0-1000ms random jitter to every delay. Without jitter, thousands of clients reconnect simultaneously after a server restart (thundering herd).

**Max retries:** After **10 attempts** (~2.5 minutes), stop automatic reconnection. Show "Connection lost. Click to retry." Users can manually trigger a fresh attempt.

### Offline queue

If the user performs actions while disconnected, queue them and replay on reconnect.

```typescript
class OfflineQueue {
  private queue: QueuedAction[] = [];
  private maxSize = 50;
  private maxAge = 5 * 60 * 1000; // 5 minutes

  enqueue(action: QueuedAction) {
    if (this.queue.length >= this.maxSize) {
      this.queue.shift(); // drop oldest
    }
    this.queue.push({ ...action, timestamp: Date.now() });
  }

  async flush(ws: WebSocket) {
    const now = Date.now();
    const valid = this.queue.filter(
      (a) => now - a.timestamp < this.maxAge
    );
    for (const action of valid) {
      ws.send(JSON.stringify(action));
      await new Promise((r) => setTimeout(r, 50)); // pace to avoid burst
    }
    this.queue = [];
  }
}
```

**Rules:**
- Queue max **50 actions**. Beyond that, drop the oldest. Users won't remember what they did 50 actions ago while offline.
- Expire queued actions after **5 minutes**. Stale actions applied to changed state cause confusion.
- Show a count: "3 pending changes will sync when reconnected."
- On reconnect: fetch latest state first, then apply queued actions. Discard any that conflict.
- Use optimistic UI for queued actions (show them as applied immediately), but mark them with a "pending sync" indicator (small clock icon or muted styling).

### Heartbeat / keepalive

WebSocket connections silently die without heartbeats (firewalls, load balancers, NAT timeouts).

- **Client sends ping** every **30 seconds**.
- **Server responds with pong** within 5 seconds.
- If **2 consecutive pings** go unanswered (60 seconds), client assumes disconnect and enters reconnection.
- Use WebSocket protocol-level ping/pong frames where possible. Fall back to application-level JSON `{ type: "ping" }` if the framework doesn't expose protocol pings.

---

## Real-time anti-patterns

These are the mistakes that make real-time features feel broken.

### Updating every cell in a large table

**Problem:** Pushing updates to every visible row on every tick. A 1000-row table with 10 columns = 10,000 DOM updates per tick. The browser grinds to a halt.

**Fix:**
- Only update **cells that actually changed**. Diff incoming data against current state.
- Use **virtualized tables** (only render visible rows). Libraries: TanStack Virtual, react-window.
- Batch DOM updates into a single `requestAnimationFrame` call.
- Throttle table updates to **1-2 per second** max, even if data arrives faster.

### Cursor jank from unthrottled updates

**Problem:** Broadcasting cursor position on every `mousemove` (60+ events/second per user). Receiving side tries to render all of them.

**Fix:** Throttle to 50ms send interval, interpolate on receive (see Live Cursors section above).

### Notification storms

**Problem:** A batch import creates 500 records and generates 500 "new record created" notifications.

**Fix:**
- **Aggregate:** "Sarah imported 500 records" instead of 500 individual toasts.
- **Rate limit:** Max 1 toast per 2 seconds from the same source. Queue and batch the rest.
- **Tiered delivery:** Not everything deserves a toast. Use the severity ladder:

| Event type | Delivery method |
|---|---|
| @mention, direct message | Toast + badge + sound (if enabled) |
| Team activity (created, updated) | Activity feed only |
| Bulk operations | Single summary toast |
| System events (deploy, maintenance) | Banner |

### Reconnection loops

**Problem:** Server is down. Client reconnects every 500ms forever, hammering the server and draining mobile battery.

**Fix:** Exponential backoff with jitter and a retry cap (see Reconnection section). After exhausting retries, require manual action.

### Optimistic UI without rollback

**Problem:** Show the action as completed immediately, but if the server rejects it, the UI is now lying.

**Fix:** Every optimistic update must have a rollback path:
1. Apply change to local state immediately.
2. Send to server.
3. On success: no-op (already showing correct state).
4. On failure: revert local state, show error toast with details.

Store the pre-mutation state snapshot for rollback. Don't try to "undo" the mutation — replace with the saved snapshot.
