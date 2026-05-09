# API & Integrations

This file covers connecting the dashboard to external services and offering your own API to the outside world. `data-layer.md` covers the dashboard's own internal API contracts; `system-integration.md` covers internal feature-to-feature connectivity. This file is about the boundary between your dashboard and everything outside it.

**Canonical scope:** external APIs, OAuth2 clients, webhooks (inbound and outbound), data sync, building a public API for third-party consumers. **See also:** `data-layer.md` for internal queries and mutations, `system-integration.md` for internal event bus and feature flags.

---

## Integration architecture

### The adapter pattern

Every external API call goes through a dedicated adapter module. Never call third-party APIs directly from route handlers or service functions.

```typescript
// interfaces/email.ts — the contract your codebase uses
interface EmailProvider {
  send(params: { to: string; subject: string; html: string }): Promise<{ id: string }>;
}

// adapters/email/sendgrid.ts — one implementation
export class SendGridAdapter implements EmailProvider {
  constructor(private apiKey: string) {}
  async send(params) { /* SendGrid SDK calls */ }
}

// adapters/email/resend.ts — swap by changing one line
export class ResendAdapter implements EmailProvider {
  async send(params) { /* Resend SDK calls */ }
}

// adapters/email/index.ts — factory
export function createEmailProvider(): EmailProvider {
  switch (config.email.provider) {
    case 'sendgrid': return new SendGridAdapter(config.email.apiKey);
    case 'resend': return new ResendAdapter(config.email.apiKey);
  }
}
```

Why adapters matter:
- **Swappability** — switching SendGrid to Resend means changing one file. The 47 places that send emails stay untouched.
- **Testability** — inject a fake adapter in tests. No HTTP mocking needed.
- **Normalization** — each provider returns errors and data differently. The adapter normalizes into your internal format.
- **Observability** — the adapter is the single place for latency tracking, error counting, and circuit breaker logic.
- **Credential isolation** — the adapter owns its credentials. No route handler knows API keys.

Name the interface after its role (`EmailProvider`, `FileStorage`), not the vendor. Name the implementation after the vendor (`SendGridAdapter`).

### Credential management

**Single-tenant:** store API keys in environment variables or secrets manager. Design for rotation — credentials are read from config, never hardcoded.

**Multi-tenant (each org connects their own):** store per-tenant credentials in the database, encrypted with envelope encryption (per-org key derived from a master key in KMS). Never return raw credentials to the frontend — show masked versions (`sk_...abc`). Audit every credential read, write, and rotation.

### Configuration-driven integrations

Enable/disable integrations via config, not code:

```typescript
const integrationConfig = {
  slack: { enabled: env.SLACK_ENABLED === 'true', clientId: env.SLACK_CLIENT_ID },
  sendgrid: { enabled: env.SENDGRID_ENABLED === 'true', apiKey: env.SENDGRID_API_KEY },
};
```

For multi-tenant: store enabled state per org in the database. Config defines what's available at the platform level; each org toggles what they use.

### Integration health monitoring

Track per-integration: latency (p50/p95/p99), error rate (rolling 1min/5min/1hr), circuit breaker state, rate limit headroom. Surface in the admin UI as a health dashboard per connected service.

---

## OAuth2 for user-connected services

### The "Connect your Slack" flow

```
1. User clicks "Connect Slack"
2. Frontend redirects to provider's authorize URL with client_id, scopes, redirect_uri, state
3. User authorizes in provider's UI
4. Provider redirects back with ?code=AUTH_CODE&state=STATE
5. Backend verifies state matches session (CSRF prevention)
6. Backend exchanges code for access_token + refresh_token
7. Backend encrypts and stores tokens, scoped to user/org
8. Frontend shows "Slack connected" with disconnect option
```

**PKCE for SPAs:** Generate `code_verifier` (random 43-128 chars), compute `code_challenge = base64url(sha256(code_verifier))`, send challenge in authorize request, send verifier in token exchange. Required in OAuth 2.1 for all clients.

**State parameter:** cryptographically random, stored in session, verified on callback. Prevents CSRF attacks where an attacker tricks a user into connecting the attacker's account.

### Token storage

- Encrypt access + refresh tokens at rest (AES-256-GCM or KMS envelope encryption).
- Never store in the browser. Frontend knows "connected" (boolean), never the token.
- Schema: `oauth_connections` with `org_id`, `user_id`, `provider`, `encrypted_access_token`, `encrypted_refresh_token`, `token_expires_at`, `scopes`, `provider_account_id`, `status`.

### Token refresh

Refresh proactively before expiry (5-minute buffer), not after a 401. Handle revoked tokens gracefully — mark connection as revoked, show "Please reconnect" in UI. If provider issues new refresh token during refresh (rotation), store the new one.

### Scopes

- Request minimum necessary. Start read-only, add write scopes when needed.
- Explain to users what you're requesting before the redirect.
- Store the granted scopes (may differ from requested).

### Disconnect flow

1. Revoke token with provider (best effort).
2. Delete stored encrypted tokens.
3. Clean up synced data if appropriate.
4. Update UI.
5. Log in audit trail.

### Re-authorization (scope upgrade)

When a new feature needs more permissions: detect the gap, explain to user, re-initiate OAuth with expanded scopes. Most providers (Google, Slack) handle additive scopes.

### Multi-tenant OAuth

Each org connects their own instance. Tokens are org-scoped. The `state` parameter encodes `org_id` so the callback knows which org is connecting.

### Provider quirks

| Provider | Key quirk |
|---|---|
| **Google** | Refresh tokens only on first auth (or with `prompt=consent`). Use `include_granted_scopes=true` for incremental. |
| **Microsoft** | v2 endpoint for personal + work. Admin consent required for some scopes. 1hr token lifetime. |
| **Slack** | Bot tokens (`xoxb-`) vs user tokens (`xoxp-`). Installations are additive. Token rotation is opt-in. |
| **GitHub** | Prefer GitHub Apps over OAuth Apps (installation tokens, granular permissions). Classic tokens don't expire. |
| **Salesforce** | `refresh_token` scope must be explicitly requested. Sandbox vs production have different URLs. |
| **HubSpot** | Tokens expire every 30 min. Refresh tokens expire after 6 months of inactivity. |

---

## Outbound webhook delivery

### Your dashboard sends events to customer-configured URLs

**Data model:**

```
webhook_endpoints: id, org_id, url, secret, events[], status, created_at
webhook_deliveries: id, endpoint_id, event_type, payload, status, attempt_count,
                    response_status_code, response_body, last_attempt_at, next_retry_at
```

### Payload signing (HMAC-SHA256)

Follow the Stripe/Svix convention:

```typescript
function signPayload(payload: string, secret: string, timestamp: number): string {
  const signedContent = `${timestamp}.${payload}`;
  return crypto.createHmac('sha256', secret).update(signedContent).digest('hex');
}

// Headers: Webhook-Id, Webhook-Timestamp, Webhook-Signature: v1=<hex>
```

Include timestamp in the signed content to prevent replay. Receivers reject timestamps >5 minutes old.

### Delivery with retry

```
Attempt 1: immediately
Attempt 2: 5 minutes
Attempt 3: 30 minutes
Attempt 4: 2 hours
Attempt 5: 24 hours
After max retries: mark as failed
```

Use a job queue (BullMQ, Celery, SQS). Never deliver synchronously.

### Delivery log

Show customers every attempt per endpoint: event type, status, attempts, response code, timestamp. Click into a delivery for full request/response details.

### Endpoint verification

On creation, send a test event. Require a 2xx response before activating.

### Auto-disable unhealthy endpoints

After 5 consecutive failures across any events, auto-disable and notify the customer. Provide a "Re-enable" button that resets the counter.

### Payload format

Consistent JSON envelope:

```json
{
  "id": "evt_2Kj8Bx7Yz",
  "type": "order.created",
  "timestamp": "2026-04-11T14:30:00Z",
  "version": "1",
  "data": { ... }
}
```

`id` is the idempotency key. `type` follows `entity.verb_past_tense`. `version` allows schema evolution.

---

## Inbound webhook consumption

### Generic receiver pattern

```
1. Receive POST to /api/webhooks/:provider
2. Read RAW body (don't parse JSON — signature needs raw bytes)
3. Verify signature (provider-specific)
4. Check idempotency (skip if already processed)
5. Store raw event in webhook_events table
6. Respond 200 immediately
7. Process async via background job
```

Critical: respond 200 before processing. Providers timeout and retry within 2-10 seconds.

### Per-provider signature verification

Each provider signs differently (Stripe: `Stripe-Signature` header, GitHub: `X-Hub-Signature-256`, Slack: `X-Slack-Signature` with versioned basestring). Always use `crypto.timingSafeEqual` for comparison.

### Event normalization

Transform provider-specific payloads into your internal format. The normalizer is where you decouple your business logic from the provider:

```typescript
// Stripe's invoice.payment_succeeded -> your billing.payment_succeeded
function normalizeStripeEvent(raw: StripeEvent): InternalEvent {
  return { type: 'billing.payment_succeeded', entityType: 'invoice', ... };
}
```

Switching from Stripe to Paddle means changing the normalizer, not the business logic.

### Webhook replay

Store raw payloads. Build an admin UI to reprocess individual events or bulk-replay all failed events. Essential for debugging and recovery.

---

## Data sync strategies

### Full sync

Fetch all records, reconcile with local. Use for: initial setup, periodic reconciliation (weekly), recovery after downtime.

### Incremental sync

Fetch only records changed since last sync:
- **Timestamp cursor:** `?updated_after=2026-04-11T00:00:00Z`. Simple, widely supported. Use 5-minute overlap buffer for clock skew.
- **Sync tokens:** Provider gives opaque position token (Google `syncToken`, Microsoft `deltaLink`). Most reliable.
- **Change data capture:** Database-level change streams. Best for self-hosted systems.

### Real-time sync

Webhooks or streaming APIs for immediate propagation. Supplement with periodic incremental sync as a safety net for missed webhooks.

### Conflict resolution

| Strategy | When |
|---|---|
| **Last write wins** | Simple, acceptable data loss risk. Default for most. |
| **Source of truth** | One system is authoritative per entity type. Recommended. |
| **Field-level** | Different fields owned by different systems. For bi-directional CRM sync. |
| **Manual queue** | Flag conflicts for human review. For critical data (financial, legal). |

### Sync status tracking

```
sync_status: org_id, provider, entity_type, last_synced_at, result,
             records_synced, records_failed, error_message, sync_cursor
```

### Sync UI

Show per integration: last synced time, record count, error count with "View Errors" link, "Sync Now" button, sync history table.

### Field mapping

External schemas don't match yours. Provide configurable mapping (dropdown selectors per field). Store mapping per org. Auto-detect by header names where possible.

### Rate limiting awareness

Read `X-RateLimit-Remaining` headers and throttle preemptively. Batch API calls where providers support it. Exponential backoff with jitter on 429s.

---

## Integration marketplace UI

### Connected apps page

List available integrations by category (communication, CRM, storage, email, identity, monitoring). Each shows: logo, name, status (connected/disconnected), last activity, Configure/Connect button.

### Per-integration settings

When configured: connection status, granted scopes, sync settings (frequency, direction, entity types), field mapping, event selection, activity log.

### Admin vs user-level integrations

| Type | Examples | Who configures |
|---|---|---|
| **Org-wide** | SSO, Stripe, Slack bot | Org admin |
| **User-level** | Calendar sync, personal GitHub | Each user |

Guard org-wide settings with admin permissions. User-level integrations go in personal settings.

---

## Building your own public API

### Documentation

Use OpenAPI/Swagger spec as the source of truth. Render with Scalar (recommended, modern UI), Redoc, or Swagger UI.

Include: authentication guide, every endpoint with examples, error format, rate limits, pagination, webhook catalog, code examples (JS, Python, cURL), changelog.

### API key management

- Generate: cryptographically random, 32+ bytes. Show full key ONCE. Store only the hash.
- Scope: per-resource permissions (read/write per entity type).
- Display: prefix only (`sk_live_...abc`), last-used date, created-by user.
- Rotate: support key pairs with overlap period.
- Revoke: immediate, returns 401.
- Format: `sk_live_` prefix for production, `sk_test_` for test mode.

### Versioning

URL path (`/v1/`) is the standard. Increment only for breaking changes. Support N-1 versions. Give 6-12 months to migrate. Return `Sunset` and `Deprecation` headers on deprecated endpoints.

### Rate limiting

Per-key and per-plan limits. Response headers on every request:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1694000060
```

429 response with `Retry-After` header when exceeded.

### Pagination

**Cursor-based** (recommended for large/dynamic datasets): opaque cursor, `has_more` boolean, `Link` header.

**Offset-based** (for simple cases): `limit`, `offset`, `total_count`.

### Filtering and sorting

```
GET /v1/orders?status=active&created_after=2026-01-01&sort=-created_at&fields=id,status,total
```

`-` prefix for descending sort. `fields` for sparse fieldsets. `q` for full-text search.

### Error format

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request body contains invalid fields.",
    "details": [
      { "field": "email", "code": "invalid_format", "message": "Must be a valid email." }
    ],
    "request_id": "req_abc123"
  }
}
```

Always include `request_id` for support debugging.

### Developer portal

Separate page for API consumers: interactive docs, key management, usage dashboard (request count, error rate, top endpoints), webhook configuration, changelog, status page link.

---

## Error handling for external APIs

### Retry with backoff and jitter

```typescript
const delay = Math.min(baseDelay * Math.pow(2, attempt) * (0.5 + Math.random()), maxDelay);
```

Always add jitter (random +/-50%). Pure exponential backoff creates thundering herds. Only retry retryable errors (429, 5xx, network timeouts). Never retry 4xx (except 429).

### Timeout configuration

- **Connect timeout:** 3-5 seconds. Fail fast if unreachable.
- **Read timeout:** 10-60 seconds, varies by provider and operation.

### Circuit breaker per service

Each external service gets its own circuit breaker. When open, return fallback immediately without network calls. See `system-integration.md` for the pattern.

### Graceful degradation

Core principle: a third-party outage never breaks the user's primary action.

| Service down | User action | Behavior |
|---|---|---|
| Slack | Creates an order | Order succeeds. Notification queued. "Delivery delayed." |
| SendGrid | Invites teammate | Invitation created. Email queued. "Email may be delayed." |
| Salesforce | Views contacts | Show cached data with "Last synced 15 min ago." |
| S3 | Uploads file | Show error — no fallback for storage. But clear message, not crash. |

### Error mapping

Translate provider-specific errors into user-friendly messages. A Stripe `card_declined` becomes "Your card was declined." A generic 500 becomes "Salesforce is experiencing issues. We'll retry."

---

## Testing integrations

### Mock strategy

- **Unit tests:** inject fake adapter implementations. No HTTP mocking needed.
- **Integration tests:** use MSW (Mock Service Worker) or nock to intercept at the network level.
- **Contract tests:** hit real provider sandboxes (Stripe test mode, Salesforce sandbox) on a schedule (weekly CI job). Verify response shapes match your adapter's expectations.

### Provider sandbox environments

| Provider | Test environment |
|---|---|
| Stripe | Test mode with `sk_test_` keys. Test card numbers. |
| Salesforce | Developer Edition or Sandbox orgs. |
| HubSpot | Developer test accounts. |
| SendGrid | Test inbox services (Mailosaur, Mailtrap). |
| Slack | Separate workspace for dev/testing. |

### Webhook testing

- **Local dev:** Stripe CLI (`stripe listen --forward-to`), ngrok, Hookdeck, Cloudflare Tunnel.
- **CI:** simulate deliveries by POSTing test payloads with valid signatures (compute HMAC with test secret). Store sample payloads from real deliveries (redacted) for replay.

### Replay testing

Capture real API responses during development, store as fixtures, replay in tests for deterministic results. Refresh fixtures periodically to catch API changes.

---

## Common integrations for dashboards

### Email (SendGrid, Resend, Postmark, SES)

Transactional (user-triggered) vs marketing (bulk) — often separate providers or at least separate sending domains to protect deliverability. Track bounce rate, complaint rate, delivery rate via provider webhooks.

### File storage (S3, R2, GCS)

Presigned URLs for direct upload/download. CDN in front for public assets. Signed URLs with expiry for private assets.

### Communication (Slack, Teams, Discord)

Incoming webhooks for simple notifications. Bot + OAuth for interactive features (buttons, commands). Adapter interface: `send(channel, text, blocks)`.

### Identity (Okta, Auth0, Entra)

SAML SSO for enterprise login. SCIM provisioning for automated user lifecycle (create/update/deactivate pushed from IdP).

### CRM (Salesforce, HubSpot)

Bi-directional sync with field-level source-of-truth rules. Include `last_modified_by` to detect and prevent sync loops.

### Monitoring (Sentry, PagerDuty)

Alert routing with deduplication keys. PagerDuty Events API v2 with `dedup_key` to prevent duplicate incidents.

---

## Don'ts

- **Don't call external APIs directly from route handlers.** Use the adapter pattern.
- **Don't store OAuth tokens in plaintext.** Encrypt at rest.
- **Don't store tokens in the browser.** Server-side only.
- **Don't skip the state parameter** in OAuth flows. CSRF is real.
- **Don't deliver webhooks synchronously.** Queue and process async.
- **Don't skip signature verification** on inbound webhooks. Use `timingSafeEqual`.
- **Don't let a third-party outage crash the user's action.** Queue, fallback, degrade gracefully.
- **Don't retry 4xx errors** (except 429). The request is wrong.
- **Don't use pure exponential backoff without jitter.** Thundering herds.
- **Don't use sequential IDs in your public API.** UUIDs prevent enumeration.
- **Don't skip the delivery log** for outbound webhooks. Customers need to debug.
- **Don't run full syncs on every request.** Use incremental with periodic full sync as reconciliation.
- **Don't hardcode field mappings.** External schemas change. Make mapping configurable.
- **Don't let stale integration health go unmonitored.** Track latency, error rate, circuit state per provider.
