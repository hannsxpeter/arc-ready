# Security Deep Dive

This file extends the security coverage beyond `auth-and-rbac.md` (login, sessions basics, RBAC, multi-tenant) and `performance-and-security.md` (CSP, HSTS, CORS, XSS, SQLi, rate limiting, basic dependency scanning, basic file uploads). Everything here goes deeper into areas those files don't cover.

**Canonical scope:** session hardening, secrets management, incident response, advanced data protection (encryption at rest, PII handling, backup security). **See also:** `performance-and-security.md` for CSP, CORS, rate limits, and headers; `auth-and-rbac.md` for authorization logic and RBAC.

---

## Session security

### Session fixation prevention

Session fixation: an attacker sets a known session ID on the victim's browser, waits for login, then hijacks the session.

**Defense: regenerate the session ID on every privilege change.**

Critical moments to regenerate:
1. On login (anonymous > authenticated)
2. On role/privilege escalation
3. On password change

```typescript
app.post('/login', async (req, res) => {
  const user = await authenticateUser(req.body.email, req.body.password);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });

  req.session.regenerate((err) => {
    req.session.userId = user.id;
    req.session.save(() => res.json({ ok: true }));
  });
});
```

### Concurrent session management

Modern users have multiple devices. Don't block concurrent sessions outright. Instead:
1. Set a maximum (e.g., 5 active sessions per user).
2. When exceeded: deny the new login with a message, or evict the oldest session.
3. Show active sessions on the profile page: device, IP, last active, "this device" indicator.
4. "Sign out all other devices" button.
5. Optionally alert on login from unrecognized device/IP.

### Session binding

Tie sessions to contextual attributes:
- **User-agent**: store at creation, flag if it changes (don't kill — browser updates change it). Log the mismatch.
- **IP range**: if IP changes dramatically (different /16 or different country), prompt re-authentication.
- **Fingerprint**: hash user-agent + accept-language + timezone. Cheap anomaly detection.

### Absolute vs idle timeouts

Two separate timers running simultaneously:

| Timeout | Purpose | Sensitive dashboard | General dashboard |
|---|---|---|---|
| **Absolute** | Limits window if token is stolen | 8-12 hours | 24 hours |
| **Idle** | Protects unattended sessions | 15-30 minutes | 60 minutes |

Session expires when EITHER fires. Show "Session expiring" warning 2 minutes before idle timeout.

### "Remember me" implementation

Don't extend the session lifetime. Use a separate long-lived token:

1. On login with "remember me," create: normal session (8-12hr) + remember-me token (30 days) in a `remember_tokens` table.
2. Set the token in a separate `httpOnly`, `secure`, `sameSite=lax` cookie.
3. When session expires but remember-me cookie is valid: auto-create a new session.
4. Token is single-use: on each use, delete and issue a new one (token rotation).
5. Logout deletes both session and remember-me token.
6. "Sign out all devices" deletes all sessions AND all remember-me tokens.

### Forced session invalidation

Admin capability to kill sessions:
- Kill all sessions for a specific user (account compromise).
- Kill all sessions globally (incident response).
- Kill a specific session (targeted revocation).

This is why server-side sessions (Redis, database) are preferred over JWTs for dashboards — JWTs can't be revoked without a blocklist.

### Session storage tradeoffs

| Storage | Revocable | Latency | Best for |
|---|---|---|---|
| **Redis** | Yes | ~1ms | Most production dashboards |
| **Database** | Yes | ~5ms | Simpler deployments |
| **Signed cookies** | No (without blocklist) | 0ms | Stateless architectures |
| **JWTs** | No (without blocklist) | 0ms | Microservices (with short expiry + refresh) |

---

## API security

### API key lifecycle

1. **Generate:** cryptographically random, 32+ bytes, hex/base64. Show full key ONCE at creation. After: prefix/suffix only (`sk_live_...abc123`).
2. **Store:** hash with SHA-256 (API keys are already high-entropy, unlike passwords). Look up by hash.
3. **Scope:** permissions per key (read-only, read-write, admin) + optional resource scoping.
4. **Rate limit per key:** separate from per-user limits. A misbehaving integration shouldn't exhaust the user's other integrations.
5. **Rotate:** support key pairs — create new, update integration, delete old. Both work during overlap.
6. **Expire:** optional expiration date. Audit keys unused for 90 days and suggest revocation.

### API versioning

**URL path** (`/api/v1/`) is the standard for dashboard APIs. Most visible, easiest to route.

Strategy: maintain N-1 versions. When v3 ships, deprecate v1. Give 6-12 months to migrate. Return deprecation warnings in headers (`Deprecation: true`, `Sunset: 2026-12-31`).

### Request signing

For webhooks and API-to-API communication:
1. HMAC-SHA256 of the request body using a shared secret.
2. Include signature in header (`X-Signature-256: sha256=<hex>`).
3. Include timestamp to prevent replay (signed as part of the payload).
4. Receiver: recompute HMAC, compare with constant-time comparison, reject if timestamp >5 minutes old.

### Idempotency keys

For mutation endpoints, accept `Idempotency-Key` header:
- First request: process normally, store `{key, response_status, response_body}` with 24hr TTL.
- Duplicate: return stored response without re-processing.
- Concurrent duplicate: return 409 or block until first completes.

Prevents: double-charges, duplicate creates, retry-caused duplicates.

### Request body size limits

- JSON: 1MB default, increase per endpoint for bulk imports.
- File uploads: per use case (5MB avatars, 50MB documents).
- Reject oversized requests at the middleware/proxy level before parsing.

### GraphQL-specific security

- **Query depth limiting:** max 10 levels. Without this, deeply nested queries exhaust server resources.
- **Query complexity analysis:** assign costs per field, reject queries exceeding threshold.
- **Disable introspection in production.** Exposes entire schema.
- **Batch query limits:** max 10 operations per request.

### API abuse patterns

- **Sequential ID enumeration:** use UUIDs for public-facing IDs, not sequential integers.
- **Scraping:** rate limit per IP and per key. Monitor for sequential page crawling.
- **Credential stuffing on API auth endpoints:** aggressive rate limiting, monitor high-volume failed auth.

---

## Data protection and privacy

### Data classification

| Level | Examples | Controls |
|---|---|---|
| **Public** | Company name, product descriptions | None special |
| **Internal** | Project names, non-PII metrics | Access control |
| **Confidential** | Revenue, customer lists, contracts | Encryption at rest, access logging, role-restricted |
| **Restricted** | SSN, health records, card data, passwords | Column-level encryption, audit trail, masking in non-prod, retention policies |

Maintain a data inventory: every table, which columns contain PII, classification level, who has access, retention policy.

### Encryption at rest — layered approach

1. **Database-level TDE:** encrypts entire database on disk. Protects against physical theft, file system access. Baseline — enable it on every database.
2. **Column-level encryption:** encrypt specific PII columns. Protects against SQL injection (attacker gets ciphertext), database dumps, backup exposure.
3. **Application-level encryption:** encrypt before data reaches the database. Maximum protection. Use envelope encryption: data key (DEK) encrypts data, key encryption key (KEK) from KMS encrypts DEK. Allows key rotation without re-encrypting all data.

**Strategy:** TDE for everything, column-level for Restricted fields, separate keys per tenant for multi-tenant SaaS.

### Data masking in non-production

Staging/dev should have realistic data shapes but no real PII:
- **Deterministic masking:** same input always produces same fake output (preserves referential integrity).
- **Selective masking:** mask Restricted/Confidential fields, leave Public/Internal intact.
- **Automated pipeline:** snapshot production > mask > restore to staging. Weekly schedule.

### Data retention and purging

Define policies per data type:
- Audit logs: 1-7 years (regulatory dependent)
- User activity: 90 days to 2 years
- Deleted user data: 30-day soft-delete, then hard-delete/anonymize
- Backups: rotate on the same schedule

Automate purging with a daily job. Don't rely on manual cleanup.

### GDPR right to deletion (Article 17)

Implementing "right to be forgotten":
1. **Inventory** every table, service, log, backup, and third-party integration that stores user data.
2. **Cascade** deletion/anonymization across all of them. Handle foreign keys (reassign content to a "deleted user" placeholder).
3. **Backups:** don't alter existing backups, but don't restore deleted data. Mark user as deleted so restore processes skip/re-anonymize.
4. **Logs:** anonymize user identity (replace ID with hash, remove IP).
5. **Analytics:** use deletion APIs (Mixpanel, Amplitude, PostHog all have them).
6. **Third parties:** notify Stripe, email providers, etc.
7. **Confirm** to the user within 30 days.

### Anonymization vs pseudonymization

- **Anonymization:** irreversible. No longer personal data under GDPR. Hard to achieve in practice.
- **Pseudonymization:** reversible with a key. Still personal data under GDPR. Data subject rights still apply.

Use pseudonymization for non-prod (can restore for debugging). Use anonymization for broadly shared analytics datasets.

---

## Secure file handling (beyond basics)

### Upload validation depth

- **Magic bytes:** check the file's actual bytes, not extension/MIME. Libraries: `file-type` (Node.js), `python-magic` (Python). A `photo.jpg` with executable magic bytes is an attack.
- **Virus scanning:** ClamAV as daemon + client library. Update definitions daily. For serverless: managed service or VirusTotal API.
- **Image re-encoding:** strip EXIF data (GPS, device info) with `sharp` (Node.js) or `Pillow` (Python). Re-encode images to strip embedded payloads. For SVGs: sanitize with DOMPurify (SVGs can contain JavaScript).

### Download security

- `Content-Disposition: attachment` — forces download, prevents rendering.
- `X-Content-Type-Options: nosniff` — prevents MIME-sniffing.
- **Serve from a different origin** (`files.example.com`, not `dashboard.example.com`) — isolates any script execution from dashboard cookies.

### Presigned URLs

```typescript
const url = await s3.getSignedUrl('getObject', {
  Bucket: 'uploads', Key: 'reports/file.pdf', Expires: 3600
});
```

Never permanent public URLs for user-generated files. Presigned URLs expire, can't be shared beyond the window.

### Directory traversal

Never use user-supplied filenames in paths. Rename to UUID on upload:
```typescript
const filename = crypto.randomUUID() + path.extname(originalName);
```

Use object storage (S3, R2, GCS) — no directory structure to traverse.

### File type allowlists

Allowlist (not blocklist) the exact types you accept. Reject everything else. A blocklist will always miss something.

---

## Secrets management

### Environment variable patterns

- **`.env.local`** — actual secrets. Never committed. In `.gitignore`.
- **`.env.example`** — committed. Every variable name with empty/placeholder values. Documentation for new developers.
- **Validation on startup:** use a schema (Zod, envalid, pydantic) to verify all required vars are present. Fail fast with clear error.

### Secrets in CI/CD

- GitHub Actions: repository secrets, masked in logs.
- GitLab CI: CI/CD variables, marked Masked + Protected.
- Never echo secrets in logs. Never pass as command-line arguments.

### Runtime secrets services

| Service | Best for |
|---|---|
| **Doppler** | Zero infrastructure overhead, syncs to all envs |
| **AWS Secrets Manager** | AWS-native stacks, auto-rotation for RDS |
| **HashiCorp Vault** | Multi-cloud, dynamic secrets, PKI. Most powerful, most complex. |
| **Infisical** | Open-source Doppler alternative, self-hostable |

**Design for rotation:** secrets will be rotated. Read from env vars or a secrets client, not hardcoded. DB connection pools should handle credential refresh without restart.

### Detecting leaked secrets

- **Pre-commit:** `gitleaks` or `git-secrets` as hooks to prevent commits containing secrets.
- **CI:** TruffleHog (scans full git history, verifies if leaked creds are still active), Gitleaks, GitHub secret scanning.
- **GitHub:** since 2025, detects base64-encoded secrets and push-protects by default.

### When a secret leaks

1. **Rotate immediately** — generate new secret, deploy. Before investigating.
2. **Revoke the old secret** in the service that issued it.
3. **Audit** access logs for unauthorized use.
4. **Scrub from git** — `git filter-repo` or BFG Repo-Cleaner. Force-push.
5. **Post-mortem** — how did it get committed? Add pre-commit hooks.
6. **Notify** if the leak could have exposed user data.

---

## Logging security

### What to log

- Authentication events (logins, failures, logouts, MFA)
- Authorization failures (every 403, every permission denial)
- Mutation operations (create, update, delete with before/after)
- Configuration changes (role changes, API key creation, webhook config)
- Security events (rate limit hits, CSP violations, suspicious patterns, account lockouts)

### What NOT to log

- Passwords (any form)
- Session tokens / API keys (prefix/suffix only)
- Full credit card numbers (last 4 only)
- PII in query parameters
- Request/response bodies with sensitive data (log summary, not full body)

### Log injection prevention

User input in logs can forge entries (inject newlines) or exploit parsing tools.

- Use structured logging (JSON) — newlines are escaped in strings.
- Use a logging library (pino, winston, structlog) — not string concatenation.
- Never pass user input as the log format string.

### Structured format

```json
{
  "timestamp": "2026-04-11T14:32:05.123Z",
  "level": "info",
  "event": "user.login",
  "userId": "usr_abc123",
  "ip": "203.0.113.42",
  "correlationId": "req_xyz789",
  "service": "api",
  "duration_ms": 145
}
```

Consistent field names across services. Include `correlationId` for distributed tracing.

### Log access and retention

- Production logs: accessible only to on-call engineers and security team. Role-based access in your log aggregator.
- Security logs: append-only, separate restricted store.
- Retention: 90 days operational, 1-7 years security/audit.

### Security alerting

Alert on:
- Failed login spikes (>10 per account in 5 min, >50 per IP in 5 min)
- Permission escalation (any role change to admin/owner)
- Unusual data access (10x normal download volume)
- New admin user creation outside onboarding
- API key creation with admin permissions
- CSP violation spikes (possible XSS in progress)
- Rate limit bursts (scraping, credential stuffing)

Route: PagerDuty for critical (credential stuffing, escalation), Slack for warning (unusual patterns).

---

## Dependency and supply chain security

### The threat landscape (2025-2026)

Supply chain attacks have escalated. In September 2025, 18 popular npm packages (including `debug` and `chalk`) were hijacked — 2.6 billion combined weekly downloads. In February 2026, the "SANDWORM_MODE" attack used 19 typosquatting packages that spread worm-like, stealing API keys and SSH keys.

Attack vectors:
- **Typosquatting:** `axois` instead of `axios`.
- **Package takeover:** compromised maintainer credentials.
- **Dependency confusion:** private package name exists publicly.
- **Malicious install scripts:** `postinstall` runs arbitrary code.
- **Lockfile manipulation:** modified lockfile pins malicious version without changing package.json.

### Lockfile integrity

- Always commit lockfiles.
- Use `npm ci` (not `npm install`) in CI — fails if lockfile doesn't match package.json.
- Verify lockfile hasn't changed from what was committed.

### Scanning tools

| Tool | Catches |
|---|---|
| `npm audit` / `pip audit` | Known CVEs |
| Dependabot / Renovate | Auto-creates update PRs |
| Snyk | Deep vulnerability DB, fix PRs, license compliance |
| **Socket.dev** | Behavioral analysis — typosquatting, install-time network requests, obfuscated code. Catches what `npm audit` misses. |
| TruffleHog | Leaked secrets in code and dependencies |

### SCA in CI

Run on every PR:
1. Scan dependencies for CVEs. Fail on critical/high.
2. Check for problematic patterns: install scripts, network requests during install, obfuscated code.
3. License compliance: flag copyleft (GPL) if your project needs permissive licensing.

### Minimizing dependencies

Before adding a dependency:
- Can you implement this in <50 lines? Don't add it.
- Last committed? (6 months is the threshold.)
- Transitive dependency count? (`npm ls --all <package>`)
- Weekly downloads? (Trust signal.)
- Maintainer count? (Single = bus factor risk.)

Periodically audit: `depcheck` (Node.js) finds unused dependencies. Remove them.

---

## Incident response

### What constitutes a security incident

In a dashboard context:
- Unauthorized data access (user sees another tenant's data)
- Data breach (customer data exposed externally)
- Credential compromise (API key leaked, admin password compromised)
- Service takeover (attacker gains admin access)
- Supply chain compromise (dependency compromised)
- Persistent XSS or injection
- Insider threat (employee accessing data beyond role)

### Incident response checklist

**1. DETECT (minutes)**
- Confirm real incident (not false positive).
- Assign incident commander.
- Open incident channel (Slack/Teams).
- Record detection time.

**2. CONTAIN (minutes to hours)**
- Stop the bleeding: revoke credentials, block IPs, disable accounts, take services offline if needed.
- Preserve evidence: do NOT modify logs, do NOT restart servers. Snapshot affected systems.
- Determine scope: which data, which users, how much.

**3. ERADICATE (hours to days)**
- Remove root cause: patch vulnerability, remove malicious code, rotate all possibly compromised secrets.
- Scan for persistence (backdoors, additional compromised accounts).
- Rebuild from known-good state if infrastructure is compromised.

**4. RECOVER (hours to days)**
- Restore services with fix in place.
- Monitor for recurrence.
- Verify data integrity.

**5. POST-MORTEM (within 1 week)**
Blameless. Cover: timeline, root cause, impact, what went well, what went wrong, specific action items with owners and deadlines, lessons learned.

### Breach notification requirements

| Regulation | Timeline | Notes |
|---|---|---|
| **GDPR** | 72 hours to supervisory authority | Notify individuals "without undue delay" if high risk. Document all breaches. |
| **US state laws** | 30-60 days (varies) | All 50 states have laws. Comply with the strictest applicable. |
| **HIPAA** | 60 days to HHS | Media notification if >500 individuals affected. |

### Evidence preservation

- Don't restart servers or clear logs before capturing evidence.
- Take disk snapshots and memory dumps.
- Export logs to secure isolated storage.
- Record chain of custody (who touched evidence, when).
- Use write-once storage (S3 Object Lock) for legal proceedings.

### Post-mortem template

```
## Post-Mortem: [Title]
Date, Severity, Duration, Author, Participants

### Summary (2-3 sentences)
### Impact (users affected, data exposed, downtime, financial)
### Timeline (minute-by-minute)
### Root Cause
### Detection (how discovered, could we have detected sooner)
### Response (actions taken)
### What Went Well
### What Could Be Improved
### Action Items (specific, assigned, with deadlines)
### Lessons Learned
```

---

## Don'ts

- **Don't skip session regeneration on login.** Session fixation is trivial to exploit.
- **Don't block concurrent sessions outright.** Modern users have multiple devices. Limit and manage.
- **Don't store API keys in plaintext.** Hash them (SHA-256).
- **Don't use sequential integer IDs** in public API URLs. Use UUIDs.
- **Don't enable GraphQL introspection** in production.
- **Don't skip encryption at rest** because "the database is behind a firewall." Defense in depth.
- **Don't use production data in staging** without masking PII.
- **Don't leave GDPR deletion requests unautomated.** Manual processes miss tables, logs, and third parties.
- **Don't log passwords, tokens, or full card numbers.** Ever. In any form.
- **Don't pass user input as log format strings.** Use structured logging with field parameters.
- **Don't use `npm install` in CI.** Use `npm ci` to enforce lockfile integrity.
- **Don't ignore Socket.dev-style behavioral analysis.** `npm audit` catches known CVEs but misses typosquatting and install-time attacks.
- **Don't delay secret rotation when a leak is discovered.** Rotate first, investigate second.
- **Don't modify evidence before capturing it** during an incident. Snapshot first.
- **Don't write post-mortems that say "improve monitoring."** Write specific actions with owners and deadlines.
