# auth-hardening: post-deploy adversarial verification of auth and authorization

Loaded at Tier 2 (Step 4). Extends production-ready's `auth-and-rbac.md`, which owns the pre-build decisions (library choice, RBAC matrix design, session-vs-JWT tradeoff). This file owns the post-deploy adversarial verification: the attacks production-ready's defaults may not cover, the reproduction steps to run them, and the specific CVE patterns active in 2025-2026.

## Coverage vs. production-ready

production-ready's auth content (`auth-and-rbac.md`, 446 lines) covers: "real auth" criteria, library choice per framework, email+password flow, sessions vs JWTs, magic links, OAuth/OIDC integration, passkeys/WebAuthn introduction, MFA, RBAC matrix design, multi-tenant isolation principles, impersonation patterns.

This file does not repeat any of it. It adds the adversarial verification layer: the specific attacks tested, the commands issued, the passes / fails, and the class-level regression guards filed.

## Session fixation deep verification

**Attack.** Attacker sets a known session ID on the victim before login; after victim logs in, attacker uses the known ID to ride the session. Canonical defense: regenerate session ID on every privilege transition.

**Modern framework behavior.** Express-session, Next.js auth libraries, and most auth-as-a-service products regenerate by default. The recurring failure is custom session management that skips this step.

**Test.**
```
# Step 1: get a session ID before login
curl -c cookies.txt https://app.example.com/
grep session cookies.txt
# note the value, e.g., sess=abc123

# Step 2: log in with this cookie
curl -b cookies.txt -c cookies.txt -X POST https://app.example.com/login \
  -d 'email=test@example.com&password=REDACTED'

# Step 3: re-inspect
grep session cookies.txt
# the value should be different. If it is the same, session fixation is possible.
```

Also verify regeneration on: role elevation (user -> admin), password change, MFA enrollment. If the session ID does not rotate at these points, file a Medium finding.

**Pass condition.** Session ID differs before/after every privilege transition.

## CSRF: SameSite, Origin, token (defense-in-depth)

**production-ready says.** Use `SameSite=Lax` (modern browser default) plus Origin/Referer check for SPAs.

**harden-ready verifies.** Default SameSite is insufficient for high-sensitivity operations. The 2024-2025 PortSwigger research documents "SameSite Lax bypass via cookie refresh," where a victim-triggered refresh (visiting a cookie-setting page) refreshes the cookie to a fresh "Lax with grace period" state, permitting cross-site POST for a short window. [PortSwigger: SameSite Lax bypass via cookie refresh](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions/lab-samesite-strict-bypass-via-cookie-refresh), [Premsai: Advanced CSRF SameSite bypass](https://sajjapremsai.github.io/blogs/2025/06/28/adva-csrf/).

The correct posture: defense-in-depth. `SameSite=Lax` plus Origin header check plus CSRF token for state-changing endpoints on sensitive resources (change email, change password, payment, admin actions).

**Test.**
```
# Forge a cross-site POST from an attacker-controlled page
<form action="https://app.example.com/api/change-email" method="POST">
  <input name="email" value="attacker@example.com">
</form>
<script>document.forms[0].submit();</script>

# With logged-in victim, verify:
# - SameSite=Lax blocks: yes (for non-top-level navigation)
# - Origin check on server: required for defense-in-depth
# - CSRF token on sensitive endpoints: required
```

**Pass condition.** At least two of: SameSite=Lax (or Strict), Origin check on server, CSRF token. For financial or admin endpoints, all three.

## OAuth flow attacks

Primary sources: [IETF OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics), [OAuth 2.1 draft](https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1).

### Authorization code interception

**Attack.** Attacker intercepts the authorization code (public client on a shared device, URL logging, browser history).

**Defense.** PKCE (RFC 7636). Client generates `code_verifier`; sends `code_challenge = SHA-256(code_verifier)` on authorize; presents `code_verifier` on token exchange. Required for public clients in OAuth 2.1; now recommended for all clients including confidential.

**Test.** Inspect the authorization request; confirm `code_challenge` and `code_challenge_method=S256` are present. Inspect the token exchange; confirm `code_verifier` is required. Attempt token exchange without `code_verifier`; expect error.

**Pass condition.** PKCE enforced on every OAuth client.

### State parameter misuse

**Attack.** `state` is the CSRF token for the OAuth redirect. If predictable, static, or not validated, an attacker can craft a cross-site login flow that attaches the attacker's account to the victim's session.

**Test.** Issue two authorization requests; confirm `state` values differ. Alter `state` on the callback; expect rejection. Omit `state` on the callback; expect rejection.

**Pass condition.** `state` is unpredictable per request; mismatch causes rejection.

### Implicit flow deprecation

**Attack.** OAuth 2.0 Implicit flow returns tokens in URL fragment; exposed to browser history, Referer headers, shared links.

**Defense.** Deprecated in OAuth 2.1. Use authorization code + PKCE, even for SPAs.

**Test.** Verify no `response_type=token` in any client configuration; all clients use `response_type=code`.

**Pass condition.** No implicit-flow clients.

### redirect_uri matching

**Attack.** Loose `redirect_uri` matcher (substring match, wildcard subdomain). Attacker registers a matching path or subdomain; receives the authorization code; redeems it.

**Defense.** Exact-match `redirect_uri`. No wildcards. No substring matching.

**Test.** Configure a test OAuth client with a specific `redirect_uri`. Attempt authorization with a variation (different path segment, different port, different subdomain); expect rejection.

**Pass condition.** `redirect_uri` is exact-match across every OAuth client.

### Access-token audience

**Attack.** A token issued for service A is replayed against service B because B does not validate `aud`.

**Defense.** Each service validates `aud` matches its own identifier.

**Test.** Acquire a token for service A. Present it to service B. Expect rejection.

**Pass condition.** `aud` validated per service.

## JWT pitfalls: the full 2025-2026 checklist

References: [PentesterLab JWT guide](https://pentesterlab.com/blog/jwt-vulnerabilities-attacks-guide), [Auth0: critical vulnerabilities in JWT libraries](https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/), [PortSwigger: algorithm confusion](https://portswigger.net/web-security/jwt/algorithm-confusion), [WorkOS: JWT algorithm confusion](https://workos.com/blog/jwt-algorithm-confusion-attacks), [Red Sentry: JWT vulnerabilities 2026](https://redsentry.com/resources/blog/jwt-vulnerabilities-list-2026-security-risks-mitigation-guide).

### `alg: none` accepted

**Attack.** RFC 7519 defines `none` as an unsecured JWT. Some libraries historically treated it as valid.

**Test.**
```
# Craft a token with alg:none and no signature
echo -n '{"alg":"none","typ":"JWT"}' | base64url
# eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0
echo -n '{"sub":"admin","iat":1700000000}' | base64url
# eyJzdWIiOiJhZG1pbiIsImlhdCI6MTcwMDAwMDAwMH0

# Concatenate with empty signature
TOKEN="eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiIsImlhdCI6MTcwMDAwMDAwMH0."

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/admin
# Expected: 401 Unauthorized. Any other response is a Critical finding.
```

**Pass condition.** `alg:none` rejected.

### Algorithm confusion (RS256 -> HS256)

**Attack.** Server has an RSA public key for verifying RS256 tokens. Attacker flips the header to HS256 and signs with the public key as the HMAC secret. If the library looks up the key by KID and uses it for HS256 verification without re-checking algorithm compatibility, the forged token validates.

**Test.**
```
# Obtain the server's public key (often at /.well-known/jwks.json)
curl https://app.example.com/.well-known/jwks.json > jwks.json

# Extract the modulus, construct the PEM-encoded public key
# Use it as the HMAC secret to sign a forged token

# Sample with jwt_tool or manually:
python3 -m jwt_tool -S hs256 -p "$(cat pub_key.pem)" $ORIGINAL_TOKEN > forged.jwt

curl -H "Authorization: Bearer $(cat forged.jwt)" https://api.example.com/me
# Expected: 401. Any other is a Critical finding.
```

**Pass condition.** Algorithm confusion fails. The verifier enforces an algorithm allowlist before key lookup.

### Weak HMAC secret

**Attack.** Brute-forcable secret like `secret`, `changeme`, `test`.

**Test.** Run `hashcat` mode 16500 against a JWT with a wordlist (rockyou). If cracked, the secret is weak.

**Pass condition.** HMAC secret is at least 256 bits of entropy (32 random bytes).

### Missing claim validation

**Attack.** Server does not validate `exp` (token never expires), `nbf` (replay in the future), `aud` (cross-service replay), `iss` (forged issuer).

**Test.** Craft tokens with each claim manipulated; verify rejection.

**Pass condition.** Every claim validated.

### JWT revocation

**Attack.** Stateless tokens cannot be revoked mid-lifetime. User logs out; token still valid until `exp`.

**Defense pattern.** Short expiration (15 minutes) + refresh token + refresh-token deny-list on logout.

**Test.** Log in, capture token. Log out. Use the token; observe whether it still works before `exp`. Common finding: yes, it works.

**Pass condition.** Logout revokes the refresh token; access token's short TTL means the revocation window is tolerable.

### JWKS key confusion via `jku`

**Attack.** Some libraries honor the `jku` (JWK Set URL) header; attacker points it at an attacker-controlled JWKS that publishes the attacker's public key.

**Defense.** Server ignores `jku`; uses a hardcoded or config-locked JWKS URL.

**Test.** Craft a token with `jku` pointing to an attacker server. Verify rejection.

**Pass condition.** `jku` ignored; JWKS URL is locked.

### 2025 CVEs to check against

- **CVE-2025-4692** (cloud-platform library algorithm confusion).
- **CVE-2025-30144** (library bypass allowing signature verification skip).
- **CVE-2025-27371** (ECDSA public key recovery enabling forgery).

If the app uses any JWT library, verify the version is patched against these.

## Passkeys / WebAuthn pitfalls

References: [W3C WebAuthn Level 3 draft](https://w3c.github.io/webauthn/), [Yubico high-assurance relying party guidance](https://developers.yubico.com/Passkeys/Passkey_relying_party_implementation_guidance/High_assurance_passkey_relying_party.html).

### Backup Eligibility vs Backup State

**Context.** The authenticator reports whether a credential is backup-eligible (BE flag) and currently backed up (BS flag). High-assurance relying parties (financial, healthcare) may refuse backed-up passkeys; average-assurance RPs accept them.

**Policy decision.** Document the policy per data classification. "Our app accepts all passkeys; BS=1 is acceptable" for most apps. "Admin operations require BE=0, BS=0" for financial-grade.

**Test.** Attempt registration with a synced-passkey authenticator (iCloud Keychain, Google Password Manager); confirm policy applies.

### Attestation

**Context.** Attestation proves the authenticator's provenance (manufacturer, model). Most consumer flows use `attestation: none` for privacy. Enterprise flows may require attestation to enforce certified hardware.

**Test.** Confirm the server's attestation policy. If `attestation: none`, the registration response does not include metadata. If `attestation: direct`, verify the metadata chain against AAGUID allowlist.

### Recovery flow

**Context.** Passkeys synced via iCloud Keychain, Google Password Manager, Microsoft Authenticator survive device loss. Hardware-only keys do not; recovery is account-recovery, which is the weakest link.

**Policy.** Design account recovery with the same rigor as primary auth. Email-plus-SMS recovery is not the same rigor as passkey; document the downgrade explicitly, or do not permit it for sensitive accounts.

### Username enumeration via WebAuthn

**Attack.** `navigator.credentials.get` with a `userHandle` can leak username existence through timing or response shape.

**Defense.** Use resident credentials (discoverable credentials); do not expose username-existence through the WebAuthn flow.

## BOLA and authorization-vs-authentication deep audit

The most common finding class in AI-generated apps in 2025-2026. The overlap with OWASP API1:2023 is intentional; this is the most-important single check.

### The procedure

1. **Enumerate object-scoped endpoints.** Every route with an ID in the path (`/api/orders/:id`, `/:username`, `/documents/:docId`). Every GraphQL query with `id:` arguments.
2. **Provision two accounts in two tenants.** User A in tenant 1, User B in tenant 2. User A in role "customer"; User B in role "customer." Do not use admin accounts for BOLA testing; BOLA is about tenant/owner isolation, not role.
3. **Capture resource IDs.** User B creates an order, a document, a message, and a profile field. Note each resource's ID.
4. **Cross-tenant read.** Log in as User A. `GET` each of User B's resources. Expected: 404. Observed: record result.
5. **Cross-tenant write.** As User A, `PATCH` and `DELETE` each of User B's resources. Expected: 404. Observed: record.
6. **Cross-tenant enumeration.** As User A, list resources with a filter that should only match User A's items; verify User B's items do not appear.

Every observed non-404 (200, 403, 401) is a Critical or High finding. Even a 403 leaks existence information across tenants; 404 is the correct response.

### The confused-deputy case

**Scenario.** A serverless function runs as a service account with broad S3 access. A user-facing endpoint calls the function with a user-supplied S3 key; the function fetches the bucket object and returns it. If the function does not also check user-level permission on the S3 key, it is a confused deputy.

**Test.** User A has access to `/user-a/document.pdf`. User B has access to `/user-b/document.pdf`. User A calls the endpoint with `/user-b/document.pdf`; observe whether the function returns User B's document.

**Defense.** The function must include a per-user ACL check. The service-account permission is necessary but not sufficient.

Ross Anderson's *Security Engineering* chapter 4 is canonical for confused-deputy theory. Stanford CS155 notes are a free equivalent.

## Multi-tenant isolation: verify at the database layer

**Problem.** Even with correct middleware-level tenant checks, a query that omits the tenant predicate leaks cross-tenant data. The architectural question is: is tenant isolation enforced at the query layer or at the middleware layer.

### Enforcement patterns

1. **RLS (Row Level Security).** Postgres RLS policies evaluated at the database. Every query scoped by `tenant_id = current_setting('app.tenant_id')`. Middleware sets `app.tenant_id` per request.
2. **Separate schemas per tenant.** Each tenant gets a dedicated schema. Connection pool routes to the right schema per request.
3. **Separate databases per tenant.** Heaviest isolation. Scales poorly.
4. **ORM-layer scope.** ORM wraps all queries with a tenant predicate. Middleware-level, not database-level. Breaks if a query bypasses the ORM.

### The harden-ready verification

Regardless of pattern, verify by attack:

```
# Connect to the database directly as the application role
# Attempt a query without the tenant scope:
SELECT * FROM orders LIMIT 10;
# If RLS is enforced, returns zero rows (or error) because app.tenant_id is unset.
# If not enforced, returns rows across tenants.
```

If the database-layer enforcement fails, the tenant isolation is middleware-only; a bug anywhere in the middleware chain leaks data.

**Pass condition.** Database-layer enforcement (RLS or schema-per-tenant) at minimum for Restricted-data tables; ORM-layer for other tables.

## Step-up authentication for sensitive operations

**Problem.** A single auth event authorizes many later actions. Sensitive operations (change email, change password, payment, delete account, invite new admin) should require re-authentication or a fresh MFA challenge.

**Test.** Log in as a user. Leave the session idle for 10 minutes. Attempt to change the email address. Expected: re-authentication prompt. If the change succeeds without re-auth, step-up is missing.

**Pass condition.** Every high-sensitivity operation triggers step-up (re-auth, MFA challenge, or magic-link confirmation).

## Audit trail for admin operations

**Problem.** Admin actions are the highest-value target. Absence of an audit trail for admin actions makes post-incident forensics impossible.

**Test.** As an admin, perform five admin actions (impersonate user, change user role, delete user, create API key, change billing). Confirm each is logged with: actor, target, action, timestamp, IP, before/after state.

**Pass condition.** Admin actions are logged in an append-only, tamper-evident store separate from normal application logs.

Handoff: observe-ready owns the alert-on-new-admin-user rule and the anomaly-detection on impersonation volume. harden-ready names the contract; observe-ready wires the rule.

## The `.harden-ready/AUTH-VERIFICATION.md` artifact

For each of the above checks, record:

```markdown
## Session fixation
- Pre-login session ID: abc123
- Post-login session ID: def456
- Regenerated: Yes
- Status: Pass

## CSRF defense-in-depth
- SameSite=Lax: Yes (Session cookie)
- SameSite=Strict: N/A
- Origin header check: Yes (app/middleware/cors.ts line 22)
- CSRF token on sensitive ops: Yes (change-email, change-password, delete-account, invite-admin)
- Status: Pass

## OAuth flows (Google, GitHub)
- PKCE: Yes on both
- state parameter: unpredictable, validated
- Implicit flow: not used
- redirect_uri: exact-match (configured in Google/GitHub console)
- aud validation: Yes
- Status: Pass

## JWT configuration
- Library: jsonwebtoken 9.0.2
- Algorithm allowlist: ['RS256'] enforced server-side
- alg:none: rejected (tested)
- Algorithm confusion: rejected (tested with RS256->HS256 forgery)
- HMAC entropy: N/A (asymmetric)
- Claims validated: exp, nbf, aud, iss
- jku header: ignored
- CVE-2025-4692/30144/27371: library patched
- Status: Pass

## Passkey policy
- Backup eligibility: accepted (BE=1, BS=1)
- Attestation: none (consumer flow)
- Recovery: email+SMS with rate limit
- Username enumeration: resident credentials used
- Status: Pass

## BOLA audit
- Object-scoped endpoints tested: 14
- Cross-tenant reads: 14/14 returned 404
- Cross-tenant writes: 14/14 returned 404
- Cross-tenant enumerations: 14/14 filtered correctly
- Status: Pass (no findings; previously F-01 closed with RLS)

## Multi-tenant isolation at DB layer
- RLS enabled on: orders, users, documents, invoices, sessions (5 tables)
- Queries as application role without app.tenant_id: 0 rows (correct)
- Status: Pass

## Step-up auth
- change-email: re-auth required
- change-password: current password required
- payment: fresh MFA challenge
- delete-account: re-auth + confirmation
- invite-admin: re-auth + confirmation email
- Status: Pass

## Admin audit trail
- Admin actions logged: Yes
- Store: append-only S3 bucket with object-lock (separate from app logs)
- Fields: actor, target, action, timestamp, IP, before, after
- Status: Pass
```

Every row has a date and a tester identity. The artifact is the auditor's evidence for compliance-mapping Step 7.
