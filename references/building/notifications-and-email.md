# Notifications & Email

This file covers the notification system and email subsystem — the infrastructure that keeps users informed across channels. Almost every dashboard needs this: in-app notifications, transactional email, and optionally push, SMS, and Slack/Teams. The other reference files mention email and notifications in passing; this file covers how to actually build them.

---

## Notification architecture

### The pipeline

Every notification flows through a pipeline:

```
Domain event (order.placed)
  > Notification service (subscribes via event bus)
  > Workflow resolution (which notification types to generate)
  > Preference resolution (which channels this user wants)
  > Quiet hours check (hold if DND active)
  > Digest check (batch or send immediately)
  > Channel fan-out (generate per-channel payload)
  > Provider routing (SendGrid for email, Twilio for SMS)
  > Delivery queue (Redis + BullMQ per channel)
  > Delivery + tracking (sent > delivered > opened > bounced)
```

### Tools

If you don't want to build the pipeline from scratch:
- **Novu** (open-source) — Node.js, MongoDB, Redis + BullMQ, Socket.io. Workflow engine with digest/delay/batching steps. Self-hostable.
- **Knock** — managed. Workflow engine with cross-channel orchestration, batching, preferences.
- **Courier** — managed. Visual workflow builder, routing engine with fallback logic.
- **MagicBell** — focused on the in-app inbox. Real-time via WebSocket. Pre-built React components.

For most dashboards, build in-app notifications yourself (it's a table + SSE) and use a provider for email/SMS/push delivery.

---

## In-app notifications

### Data model

```sql
notifications
  id            UUID PRIMARY KEY
  user_id       UUID NOT NULL
  type          VARCHAR(100)     -- 'comment.added', 'task.assigned'
  category      VARCHAR(50)      -- 'activity', 'system', 'security'
  title         TEXT NOT NULL
  body          TEXT
  icon          VARCHAR(255)
  action_url    VARCHAR(2048)    -- where clicking navigates
  data          JSONB            -- flexible payload for rendering
  read_at       TIMESTAMPTZ      -- NULL = unread
  seen_at       TIMESTAMPTZ      -- NULL = unseen (for badge count)
  archived_at   TIMESTAMPTZ
  created_at    TIMESTAMPTZ DEFAULT NOW()
```

Index on `(user_id, created_at DESC) WHERE read_at IS NULL` for the unread query.

### Real-time delivery

When a notification is created:
1. Insert into `notifications` table.
2. Publish to Redis Pub/Sub channel `user:{user_id}:notifications`.
3. SSE server pushes `{ type: 'new_notification', notification, unreadCount }` to connected clients.
4. Client updates bell badge and optionally shows a toast.

SSE is sufficient (server-to-client only). Use WebSocket only if you also need bidirectional communication.

### Notification center UI

- **Bell icon** with badge showing unread count (update in real-time).
- **Dropdown panel** — recent notifications grouped by date, read/unread visual distinction.
- **Full page** — paginated list with filters (all, unread, by category).
- **Mark as read** — individual (on click) and bulk ("Mark all as read").
- **Archive/delete** — soft-delete with `archived_at`.

### API

```
GET    /api/notifications?status=unread&category=activity&page=1&limit=20
GET    /api/notifications/unread-count
PATCH  /api/notifications/:id/read
POST   /api/notifications/mark-all-read
DELETE /api/notifications/:id
```

---

## Notification preferences

### Per-user channel matrix

A three-tier hierarchy:

1. **Admin/workflow level** — admin sets which channels are available per notification type. If email is disabled at the workflow level, user preferences are irrelevant.
2. **User global defaults** — user sets global defaults per channel ("I never want SMS").
3. **User per-type overrides** — user overrides for specific types ("Send me email for deploy alerts but not for comments").

```sql
notification_preferences
  user_id             UUID NOT NULL
  notification_type   VARCHAR(100)   -- NULL = global defaults
  channel_email       BOOLEAN DEFAULT true
  channel_in_app      BOOLEAN DEFAULT true
  channel_push        BOOLEAN DEFAULT false
  channel_sms         BOOLEAN DEFAULT false
  channel_slack       BOOLEAN DEFAULT false
  UNIQUE (user_id, notification_type)
```

### Non-disableable notifications

Mark certain types as "critical" (password reset, security alerts, account verification). Critical notifications bypass preferences entirely and aren't shown in the preferences UI.

### Batching and digests

Instead of 50 individual "new comment" emails, send one digest:

1. When an event arrives, check if a digest window is active for that (user, type) pair.
2. If yes, append to the digest buffer (Redis or a `digest_items` table).
3. If no, start a new window with configurable duration (1 hour, 1 day).
4. When the window expires, collect all buffered items, render a single digest, deliver.
5. Some types (security alerts) should never be digested.

### Quiet hours / do not disturb

- User configures DND window (e.g., 10 PM - 7 AM) with timezone.
- Before delivering non-urgent notifications, check if current time in user's timezone is within DND.
- If yes, queue with scheduled delivery at end of DND window.
- Critical notifications bypass DND.

### Escalation chains

For ops/on-call dashboards:

1. Send notification to primary recipient.
2. Start acknowledgment timer (e.g., 5 minutes).
3. If not acknowledged, escalate: try a different channel, or notify the next person in chain.
4. Continue until acknowledged or chain exhausted.
5. If exhausted, trigger final alert (page on-call manager, post to incident channel).

---

## Transactional email

### When to use each channel

| Scenario | Email | In-app | Both |
|---|---|---|---|
| Password reset | Yes | No | — |
| Welcome / onboarding | Yes | Yes | Yes |
| Payment receipt | Yes | Yes | Yes |
| Someone commented | Maybe | Yes | User's choice |
| Task assigned | Maybe | Yes | User's choice |
| Security alert | Yes | Yes | Yes |
| Daily digest | Yes | No | — |

Rule: email when the user may not be active. In-app for real-time context. Both for important actions.

### Email template system

- **React Email** (by Resend) — write templates as React components. Pre-built components, dev server with preview. Best for React teams.
- **MJML** — markup language that compiles to responsive HTML compatible with all clients including Outlook. Abstracts table-based layout.
- **Server-rendered HTML** (Handlebars/Pug/EJS) — simplest but no built-in responsiveness.

### Email categories

| Category | Examples | Separate provider? |
|---|---|---|
| **Auth** | Welcome, password reset, magic link, invite, 2FA | No |
| **System** | Subscription change, payment receipt, account alerts | No |
| **Activity** | Comment added, task assigned, mention | No |
| **Digest** | Daily/weekly summary | No |
| **Marketing** | Product updates, announcements | **Yes** — separate domain to protect transactional reputation |

### Sender configuration

- **From address** — use a subdomain: `notifications@mail.yourdomain.com`. Isolates transactional reputation from marketing.
- **DKIM** — cryptographic signature proving the email is from your domain. Required.
- **SPF** — DNS record listing authorized senders. Required.
- **DMARC** — policy for failing SPF/DKIM. Start with `p=none`, move to `p=quarantine` after verification.

### Gmail/Yahoo sender requirements (2024-2025, enforced)

- All senders: SPF or DKIM.
- Bulk senders (5,000+/day): SPF AND DKIM AND DMARC with alignment.
- Must include `List-Unsubscribe` header with one-click unsubscribe (RFC 8058).
- Must include `List-Unsubscribe-Post: List-Unsubscribe=One-Click`.
- Must honor unsubscribe within 2 days.
- Spam complaint rate must stay below 0.3% (aim for <0.1%).
- Non-compliant emails face rejection since November 2025.

### Deliverability monitoring

| Metric | Healthy threshold | Action on breach |
|---|---|---|
| Hard bounce rate | < 2% | Suppress immediately on first hard bounce |
| Complaint rate | < 0.1% | Investigate, clean list, review content |
| Soft bounce rate | < 5% | Suppress after 3 consecutive soft bounces |

### Unsubscribe handling

- **Per-category** — users can turn off "activity" emails while keeping "security."
- **One-click** via `List-Unsubscribe-Post` header (RFC 8058).
- **Footer link** in every non-auth email pointing to preferences page with category toggles.
- **Auth/security emails are non-unsubscribable.**
- Honor unsubscribe immediately (2-day max per Gmail/Yahoo).

### Email rendering

- Outlook uses the Word rendering engine — no CSS grid, no flexbox. Use table-based layout.
- Gmail strips `<style>` in `<head>` — inline styles required.
- Keep total email under 102KB (Gmail clips larger messages).
- Test with Litmus or Email on Acid.
- Always include `alt` text on images. Use `width`/`height` attributes (not just CSS).

---

## Push notifications

### Web Push API

1. Register service worker.
2. User grants permission via `Notification.requestPermission()`.
3. Subscribe via `pushManager.subscribe()` with VAPID public key.
4. Send subscription to server (endpoint, p256dh key, auth key).
5. Server sends push via `web-push` library.
6. Service worker receives `push` event, calls `showNotification()`.

### Permission UX — critical

**NEVER prompt on first visit.** Users reflexively deny and recovery requires manual browser settings.

Pattern: show a custom pre-permission UI explaining the value ("Get notified when deployments complete"). If user clicks "Enable," THEN trigger the browser dialog. Don't re-prompt for 30 days after "not now."

### When to use push

Time-sensitive notifications needing attention when the user isn't on the dashboard: deployment failed, payment received, security alert, task with deadline.

### Subscription lifecycle

- Store multiple subscriptions per user (desktop, mobile, PWA).
- Handle `pushsubscriptionchange` event (browser reassigns endpoint).
- Delete subscriptions when push service returns 404/410 (expired).

---

## SMS and WhatsApp

### When SMS is appropriate

2FA codes, critical operational alerts, appointment reminders. NOT for high-volume activity notifications.

### Cost awareness

SMS is expensive: ~$0.008/segment US, $0.05-0.15 international. Prefer push/email where possible. Cap per-user daily SMS. Use single-segment messages (160 chars GSM-7).

### WhatsApp Business API

Requires pre-approved message templates for outbound messages outside the 24-hour conversation window. Templates submitted to Meta (1-2 day approval). Supports rich media (images, buttons, lists).

### Compliance

- **TCPA (US)** — prior express consent for transactional, written consent for marketing. $500-$1,500/message violation.
- **10DLC (US)** — mandatory since February 2025. Brand and campaign registration via provider (3-15 day approval).
- **GDPR** — explicit consent, right to withdraw.
- Every SMS must include opt-out instructions ("Reply STOP"). Honor immediately.

---

## Slack and Teams

### Slack tiers

1. **Incoming webhooks** (simplest) — one-way, post to a channel. Block Kit formatting. No interactivity. ~1 msg/sec rate limit.
2. **Bot messages** (richer) — post to any channel, send DMs, update/delete messages, interactive buttons/menus.
3. **Interactive notifications** — buttons that POST to your API: "New order #1234. [View] [Assign to Me]." Your server processes the action and updates the Slack message.

### Channel routing

Store mapping: `{ notification_type: channel_id }`. Deploy alerts to #engineering, payment alerts to #finance. Configurable via admin UI.

### Microsoft Teams

Incoming webhooks with Adaptive Cards (richer than Slack Block Kit). Bot Framework for interactive notifications. ~4 req/sec rate limit.

---

## Email inbox (CRM/helpdesk pattern)

### Receiving email

- **Webhook-based (recommended)** — SendGrid Inbound Parse, Postmark Inbound, Mailgun Routes. Provider parses email, POSTs structured data to your API.
- **IMAP polling** — connect to mailbox, poll for new messages. More complex but works with any provider.

### Email threading

Three headers govern threading (RFC 2822):
- **Message-ID** — unique per email.
- **In-Reply-To** — the Message-ID being replied to.
- **References** — chain of all Message-IDs in the thread.

On receive: match In-Reply-To/References to existing threads. On send: set In-Reply-To and References to maintain the thread.

### Shared inbox

- Multiple team members access the same inbox.
- **Assignment** — anyone can assign to themselves or others.
- **Collision detection** — soft lock (Redis key with TTL) when someone is viewing/replying. Show "Alice is replying" to others.
- **Internal notes** — comments visible only to the team, not sent to customer.
- **Status** — open, pending (waiting on customer), resolved, closed.

---

## Notification templates

### Versioning

Every edit creates a new version. Previous versions retained. Rollback = activate a previous version. React Email + Resend supports this natively.

### Multi-language

Per-locale variants keyed by `(template_id, locale)`. Fallback: exact locale > language > default. ICU MessageFormat for pluralization. Ties into `internationalization.md`.

### Dynamic content

- **Variables** — `{user_name}`, `{order_total}`, `{action_url}`.
- **Conditional blocks** — show/hide sections based on user attributes.
- **Loops** — iterate over items (order line items, digest entries).
- **Partials** — reusable header, footer, button, card components.

### Preview and testing

- React Email dev server with hot reload and sample data.
- "Send test" endpoint to render with sample data and deliver to a test address.
- Automated rendering tests: render each template, assert no errors, check size < 102KB.

### Consistent structure

Every email: branded header > body content > primary CTA button > footer (company info, unsubscribe link, preference management link). Preheader text for email client preview.

---

## Delivery tracking

### Status pipeline

```
created > queued > sent > delivered > opened > clicked
                                    > bounced (hard/soft)
                                    > complained (spam)
                                    > dropped (suppression)
```

### Provider webhook integration

- **SendGrid** — Event Webhook: processed, dropped, delivered, bounce, open, click, spam_report.
- **Postmark** — separate webhooks per event type: Bounce, Delivery, Open, Click, Spam Complaint.
- **Twilio (SMS)** — status callback per message: queued, sent, delivered, undelivered, failed.

### Delivery log

Store in `notification_deliveries` table. Searchable by: user, notification type, channel, status, date range. Admin UI with status badges and error details for failed deliveries.

### Failed delivery handling

- **Retry** — exponential backoff (1min, 5min, 15min, 1hr, 4hr). Max 5 retries for transient failures.
- **Channel fallback** — email fails after retries > fall back to in-app. Push fails (expired subscription) > fall back to email.
- **Hard bounce suppression** — on first hard bounce, add to suppression list permanently.
- **Provider circuit breaker** — if error rate exceeds 50% in 5 minutes, failover to backup provider.

---

## Rate limiting and abuse prevention

### Per-user caps

| Channel | Daily max | Why |
|---|---|---|
| Email | 50 | Prevents runaway automation from spamming |
| SMS | 10 | Cost control |
| Push | 30 | Prevents notification fatigue |

Implement with Redis counters: `INCR notifications:{user_id}:{channel}:{date}` with 24-hour TTL.

### Duplicate detection

Before sending, check `(user_id, type, content_hash)` within a deduplication window (5 minutes). Use Redis SET with NX: `SET dedup:{hash} 1 EX 300 NX`. If key exists, skip.

### Spike detection

Monitor rate per workflow type. If a single workflow generates 10,000+ notifications in 5 minutes (50x normal), alert admin and pause the workflow.

### Opt-out enforcement

Check preferences BEFORE queuing, not just before sending. Maintain a suppression list (hard bounces, spam complaints, unsubscribes). The suppression check is a hard gate that cannot be bypassed by application code.

---

## Don'ts

- **Don't prompt for push permission on first visit.** Users reflexively deny. Use a pre-permission UI.
- **Don't send email without SPF + DKIM + DMARC.** Gmail/Yahoo reject non-compliant senders.
- **Don't let users unsubscribe from security emails.** Password resets, login alerts, and 2FA are non-optional.
- **Don't use `<style>` in email `<head>`.** Gmail strips it. Inline all styles.
- **Don't skip delivery tracking.** "We sent it" is not "they received it." Track through to delivered/opened/bounced.
- **Don't send SMS for anything that can wait.** SMS is expensive and interruptive.
- **Don't process notifications synchronously.** Queue everything. The domain event should not wait for email delivery.
- **Don't skip duplicate detection.** Event replay, at-least-once delivery, and retry logic all produce duplicates.
- **Don't ignore complaint rate.** Above 0.3% and Gmail starts rejecting all your email.
- **Don't let runaway workflows generate unlimited notifications.** Spike detection and per-user caps are essential.
- **Don't send digests with the same urgency styling as individual notifications.** Digests are lower priority — style them accordingly.
- **Don't build shared inbox without collision detection.** Two agents replying to the same customer simultaneously is a support disaster.
