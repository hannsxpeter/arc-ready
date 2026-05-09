# api-hardening: rate-limit design, GraphQL cost, adversarial API verification

Loaded at Tier 2 (Step 5). Extends production-ready's `performance-and-security.md` (which owns baseline rate limiting per endpoint, basic input validation shape) and `security-deep-dive.md` (which owns API key lifecycle, GraphQL introspection, idempotency keys). This file owns the adversarial verification: the attack classes those defaults do not cover.

## Rate-limit design: algorithm choice and key selection

Most AI-generated apps ship with a single "100 requests per minute per IP" middleware and call it done. The attacker's question is always: what is the cost of rotating the key. If the key is IP, the cost is pennies for an IPv4 attacker and approximately zero for an IPv6 attacker. If the key is a user-session, the cost is creating accounts. If the key is nothing at all (unauth endpoint), there is no key to rotate.

References: [API7.ai: rate limiting guide](https://api7.ai/blog/rate-limiting-guide-algorithms-best-practices), [Arcjet: token bucket vs sliding window vs fixed window](https://blog.arcjet.com/rate-limiting-algorithms-token-bucket-vs-sliding-window-vs-fixed-window/), [Apisec: API rate limiting strategies](https://www.apisec.ai/blog/api-rate-limiting-strategies-preventing).

### Algorithm choice

| Algorithm | Bursts allowed | Memory cost | Edge cases |
|---|---|---|---|
| **Token bucket** | Yes, capped by bucket size | O(1) per key | Natural fit for API rate limits; Stripe, GitHub use this. |
| **Leaky bucket** | No (smooths) | O(1) per key | Good for downstream protection; not for user-facing throttling. |
| **Sliding window log** | No | O(n) per key, n = window requests | Accurate but memory-expensive at scale. |
| **Sliding window counter** | No (approximated) | O(1) per key | Blends current and previous fixed windows. Industry default for mid-scale. |
| **Fixed window** | No (but has boundary attacks) | O(1) per key | Vulnerable: attacker hits 2x intended rate across boundary. |

**Recommended default.** Token bucket for user-facing endpoints (permits short bursts, predictable for clients); sliding window counter for aggregate backend protection. Fixed window is the anti-pattern; its boundary attack is trivial.

### Key selection: the IPv6 trap

**IPv4.** One attacker typically controls one address. `rate_limit(key=IP)` is adequate.

**IPv6.** One attacker controls a `/48` to `/32` block: 2^48 to 2^80 addresses. `rate_limit(key=IP_exact)` is trivially bypassed by rotating through the block's addresses. Defense: key on the `/64` prefix (the smallest block an ISP assigns to a residential customer) for consumer-facing, or `/48` for enterprise-reach.

**Test.**
```
# Assuming IPv6 reachability, send N+1 requests from N different IPv6 addresses within the same /64:
for i in $(seq 1 10); do
  # Pseudocode: bind to 2001:db8:abcd:1234::$i
  curl --interface 2001:db8:abcd:1234::$i https://api.example.com/login \
    -d 'email=test&password=wrong'
done
# If all 10 succeed (no 429), the limit is per-exact-address, not per-prefix.
```

**Pass condition.** IPv6 rate limiting is keyed on `/64` or `/48`, not exact address.

### Key selection: account, session, API key, composite

- **Account ID.** Useful for per-user quotas. Useless pre-login.
- **Session token.** Useful for per-session. Useless for login itself.
- **API key.** Appropriate for machine-to-machine; key rotation is the attacker's cost.
- **Composite (IP + account + fingerprint).** Harder to rotate; privacy implications.

**Pattern.** Pre-login: rate-limit by IP (with /64 for v6) and by email target ("too many attempts on this email"). Post-login: rate-limit by account + session. API: rate-limit by API key.

### The common rate-limit-bypass patterns

- **Host header rotation.** If the server routes by Host but rate-limits by IP only, attacker sets a fake Host header to hit a different rate-limit bucket.
- **X-Forwarded-For spoofing.** If the server trusts X-Forwarded-For and the IP limiter reads it, attacker can spoof. Defense: trust only the direct proxy's header, not client-supplied.
- **WebSocket bypass.** Rate limit applies to HTTP, not WebSocket messages. WebSockets must have their own throttle.
- **GraphQL single-request amplification.** One HTTP request, thousands of queries via aliasing. Rate-limit at query-cost, not request-count.

## GraphQL attack surface

References: [OWASP GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html), [Apollo: 9 ways to secure your GraphQL API](https://www.apollographql.com/blog/9-ways-to-secure-your-graphql-api-security-checklist), [Apollo: securing supergraphs](https://www.apollographql.com/docs/technotes/TN0021-graph-security).

### Nested query explosion

**Attack.** `users { posts { comments { author { posts { comments { ... } } } } } }` explodes exponentially. A 5-level nested query on N-at-each-level data is N^5 items.

**Defense.** Depth limit (graphql-depth-limit). Max 6-8 levels for typical apps.

**Test.** Craft a 10-level nested query; expect rejection.

### Alias abuse

**Attack.** One HTTP request with 1,000 aliased queries; bypasses per-request rate limit.

```graphql
query {
  a1: user(id: 1) { ... }
  a2: user(id: 2) { ... }
  ...
  a1000: user(id: 1000) { ... }
}
```

**Defense.** Max-aliases limit (graphql-operation-limits). Typical: 15 aliases per field.

**Test.** Craft a 50-alias query; expect rejection.

### Query-cost analysis

**Attack.** A query can look cheap (two fields) but resolve to N+1 queries (fetching comments on 10,000 posts). Per-field cost analysis catches this.

**Defense.** Assign each field a cost; cap total cost per query. Cost = 1 for scalar fields; cost proportional to expected result-set size for list resolvers.

**Test.** Craft a query that resolves to >1M items; verify rejection.

### Introspection in production

**Attack.** Schema introspection reveals private types and admin fields. A public introspection endpoint is a treasure map.

**Defense.** Disable introspection in production. Apollo: `introspection: false` in ApolloServer config. Gateway: enforce via plugin.

**Test.**
```
curl -X POST https://api.example.com/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ __schema { types { name } } }"}'
# Expected: error or empty response. Full schema return is a finding.
```

### Batch-query mutations

**Attack.** Some GraphQL servers allow batched queries (multiple operations in one request). Attacker can smuggle a mutation inside a query batch.

**Defense.** Disable batch queries, or apply mutation-specific rate limits per operation in a batch.

## Mass assignment / BOPLA: write-side adversarial verification

**Problem.** The controller accepts the request body and spreads it into the database record. Extra fields become database values.

```typescript
// vulnerable
app.patch('/api/users/me', async (req, res) => {
  await db.users.update({ where: { id: req.session.userId }, data: req.body });
});

// user can POST {"role": "admin", "tenant_id": "other"} to escalate
```

### Defense patterns

1. **Allowlist.** The controller defines an explicit list of fields; rejects or ignores others.
2. **Schema validation.** Zod, Pydantic, or equivalent schema that rejects unknown keys.
3. **ORM-level denylist.** Some ORMs support "guarded" fields that cannot be mass-assigned.

### Test

For every write endpoint:
```
# POST with privileged fields
curl -X POST https://api.example.com/api/users/me \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","role":"admin","tenantId":"other","isVerified":true,"createdAt":"2020-01-01","balance":999999}'

# For each extra field, query the user record and verify the field was NOT updated.
```

Every field that was accepted is a finding. Special attention to: `role`, `tenantId`, `organizationId`, `isAdmin`, `isVerified`, `price`, `balance`, `createdAt`, `userId`.

## Input validation beyond shape

**Problem.** Zod / Pydantic / io-ts shape validation catches type mismatches but not semantic violations:

- A negative quantity in an order.
- A future-dated expiration in the past.
- A path-traversal filename (`../../etc/passwd`).
- A URL with `file://`, `javascript:`, or `data:` scheme where only `https:` is intended.
- A UUID that matches the shape but is not a valid reference.
- An email that parses but is in a disposable-email domain if that matters.

### The audit

For every input-accepting endpoint, trace the input to every sink. At each sink, the input should have been validated for semantic constraints, not just type shape.

Examples:
- Filename: magic byte validation, not extension.
- URL: scheme allowlist (`https:` only for external; plus `http:` for internal); DNS resolution before fetch; no redirects past the first (or validate each redirect target); size limit.
- Ranges: explicit min/max business-valid ranges.
- References: `tenantId` / `userId` / foreign key values must resolve to rows the caller has access to.

## Webhook HMAC verification

**Problem.** Inbound webhooks (Stripe, GitHub, Slack, Shopify, custom partners) are unauthenticated HTTP POST requests. The only authentication is HMAC signature + timestamp.

### The verification

1. **Canonical string.** Per the vendor's documentation: typically `{timestamp}.{body}`. Concatenate exactly as specified; any whitespace or encoding mismatch breaks verification.
2. **HMAC-SHA-256.** Computed with the shared secret.
3. **Constant-time comparison.** `crypto.timingSafeEqual`; never `===` or string equality.
4. **Timestamp window.** Reject if `|now - timestamp| > 5 minutes`; prevents replay.
5. **Idempotency.** Store webhook IDs in a deduplication cache; reject replays.

### Test

```
# Capture a valid webhook
# Modify the body (change "payment_amount": 100 to "payment_amount": 10000)
# Re-send with the ORIGINAL signature
curl -X POST https://api.example.com/webhooks/stripe \
  -H "Stripe-Signature: $ORIGINAL_SIG" \
  -d '$MODIFIED_BODY'
# Expected: 400 or 401. Acceptance is a Critical finding.

# Re-send the original valid webhook with the original signature
# Expected: 200 the first time, 409 or 200 with "already processed" the second.
# Repeated processing is a Medium-to-High finding depending on the action.
```

### Pass condition

HMAC verified with constant-time comparison; timestamp within window; idempotency prevents replay.

## File upload adversarial depth

production-ready's `security-deep-dive.md` covers magic-byte validation, SVG sanitization, EXIF stripping, presigned URL expiry. harden-ready verifies these are running on the deployed app.

### Test

```
# 1. Upload a file renamed with .jpg extension but containing PHP (or other executable)
cp malicious.php photo.jpg
curl -X POST https://api.example.com/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@photo.jpg"
# Expected: rejection based on magic bytes, not extension.

# 2. Upload an SVG with embedded JavaScript
cat > xss.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)">
EOF
curl -X POST https://api.example.com/upload -F "file=@xss.svg"
# Then retrieve and render; expect no script execution (sanitized).

# 3. Upload a very large file (100 GB, sparse)
dd if=/dev/zero of=large.bin bs=1 count=0 seek=100G
curl -X POST https://api.example.com/upload -F "file=@large.bin"
# Expected: rejection at middleware based on Content-Length; no disk exhaustion.

# 4. Directory traversal via filename
curl -X POST https://api.example.com/upload -F "file=@test.jpg;filename=../../../etc/passwd"
# Expected: filename normalized or rejected.

# 5. Presigned URL scope test
# Generate a presigned URL for user A; use it as user B; verify it works (URLs are capability-based)
# Confirm TTL; verify expired URL rejects.
```

### Pass condition

Magic byte validation; SVG sanitized; size limit at middleware; filename normalized; presigned URLs have appropriate TTL.

## Idempotency key verification

**Problem.** API supports `Idempotency-Key` header (Stripe, modern payment APIs). The contract: first request with a given key is processed; subsequent requests with the same key return the stored response without re-processing. If not enforced correctly, a retried payment can double-charge.

**Test.**

```
# Issue two payment requests with the same key
curl -X POST https://api.example.com/payments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: test-key-123" \
  -d '{"amount":100}'
# Response 1: 200, payment_id: pay_xxx

curl -X POST https://api.example.com/payments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: test-key-123" \
  -d '{"amount":100}'
# Response 2: 200, payment_id: pay_xxx (same; stored response returned)

# Vary the body with the same key
curl -X POST https://api.example.com/payments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: test-key-123" \
  -d '{"amount":200}'
# Response 3: 409 or 400 (key conflict; different body)

# Concurrent duplicate
# (race two requests simultaneously; expect one processed, one blocked)
```

**Pass condition.** Same key + same body returns stored response; different body with same key returns conflict; concurrent duplicate is blocked.

## Authorization-vs-authentication confused-deputy verification

Covered deeply in `auth-hardening.md` for object-level (BOLA). For API-level, the question is function-level authorization (OWASP API5).

**Test.** Enumerate every admin endpoint. Log in as a non-admin user (customer, support). Attempt each admin endpoint. Expected: 403 on every one.

**Common failure.** Admin endpoint is `/api/admin/...`. The router matches `/api/admin/*` with role middleware, but a single endpoint was added outside the `/admin` prefix (`/api/internal/users/delete`) and the role middleware does not apply. The endpoint is discoverable via API spec or the JS bundle.

**Pass condition.** Every admin endpoint rejects non-admin tokens, regardless of URL prefix.

## Request size limits

**Problem.** JSON body parsing allocates memory proportional to input. A 2 GB JSON body OOM-kills the app.

**Defense.** Middleware-level body size limit before parsing. Per-endpoint override when larger bodies are needed (bulk import).

**Test.** POST a 100 MB JSON body to a regular endpoint; expect 413 Payload Too Large.

## Error response leakage

**Problem.** Production errors leak stack traces, library versions, internal paths. An attacker fingerprints the stack and targets known CVEs.

**Test.** Trigger a handled error (invalid JSON body). Trigger an unhandled error (null pointer, assertion failure). Inspect the response body.

**Pass condition.** Error responses contain: error code, human-readable message. No stack trace, no internal path, no library version.

## Verbose HTTP methods

**Problem.** OPTIONS, TRACE, PUT-on-GET-endpoints can leak information or create unintended actions.

**Test.**
```
curl -X OPTIONS https://api.example.com/api/users/me
# Expected: list of allowed methods for this endpoint. Not a list of all server methods.

curl -X TRACE https://api.example.com/api/users/me
# Expected: 405 Method Not Allowed. TRACE support can enable XST (cross-site tracing).
```

## The `.harden-ready/API-VERIFICATION.md` artifact

Record every test and its result. Sample structure:

```markdown
## Rate limits
- Login endpoint: 5 attempts per 15 minutes per IP (IPv4), per /64 (IPv6). Verified.
- Account creation: 3 per hour per IP + email. Verified.
- Password reset: 3 per hour per email. Verified.
- General API: 1000 per minute per session. Verified.
- Expensive endpoints: 100 per minute per user. Verified.

## IPv6 prefix keying
- Tested with 10 addresses from one /64; 429 after 5. Pass.

## GraphQL
- Introspection in production: disabled. Tested. Pass.
- Max depth: 8. Tested with 10-level query; rejected. Pass.
- Max aliases: 15. Tested with 50-alias query; rejected. Pass.
- Query cost: per-field budget; tested with 1M-item-resolving query; rejected. Pass.

## Mass assignment (BOPLA)
- Tested every PATCH endpoint (12 endpoints) with privileged extra fields. All ignored or rejected. Pass.

## Input validation beyond shape
- Filename path-traversal: normalized. Pass.
- URL scheme: allowlist `https:` for external fetches. Pass.
- Numeric ranges: business-valid ranges enforced on `quantity`, `price`. Pass.
- Foreign key validation: tested with other-tenant references; rejected. Pass.

## Webhooks
- Stripe: HMAC verified with timing-safe-equal. Timestamp window 5 min. Idempotent via Stripe-Id. Pass.
- GitHub: same verification. Pass.
- Custom partner webhook (vendor X): HMAC NOT verified. F-11 filed. Fail.

## File upload
- Magic bytes: verified, not extension. Pass.
- SVG: sanitized with DOMPurify server-side. Pass.
- Size limit: 50 MB at Express middleware. Pass.
- Filename normalization: UUIDs used. Pass.
- Presigned URL TTL: 1 hour. Pass.

## Idempotency
- /api/payments: Idempotency-Key header enforced. Tested. Pass.
- Other mutation endpoints: N/A (not required).

## Admin authorization
- 14 admin endpoints tested with non-admin token. All 403. Pass.

## Request size limit
- 100 MB body rejected with 413 at middleware. Pass.

## Error response
- Production errors return {"error": "INTERNAL_ERROR"}; no stack trace. Pass.

## HTTP methods
- TRACE disabled. OPTIONS returns per-endpoint allowed methods. Pass.
```

Every Fail row points to an F-NN finding. Every Pass implies a reproducible test is in the log.
