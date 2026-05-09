# Harden-ready antipatterns

Named failure modes harden-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand at every adversarial review, every pen-test prep cycle, every compliance gap-check, and every Mode C audit of an existing security posture. Complements `references/owasp-walkthrough.md`, `references/compliance-frameworks.md`, `references/pentest-prep.md`, and `references/post-incident-hardening.md`.

## Core principle (recap)

> Every compliance claim and every scanner finding is verified by an adversarial read, or it is refused. Hardening is class-not-instance, mechanism-not-ritual.

The patterns below are violations of this principle.

## Pattern catalog

### Scanner-first security (Critical)

**Shape.** Snyk green. Dependabot empty. CodeQL clean. The team declares "we're secure" and stops. Pen-test reveals SQL injection on the admin endpoint that no scanner could see because the endpoint takes structured input.

**Grep test.** Every scanner-pass declaration is paired with an adversarial-review pass. SAST/SCA results inform the review; they don't replace it. Engagements that ended at "scanners are green" fail.

**Guard.** Step 3 of the workflow runs gray-box adversarial review against the architecture's named trust boundaries (`.architecture-ready/ARCH.md` §6). Scanners feed the review; they don't gate it.

### Paper trust boundaries (Critical)

**Shape.** The architecture document declares five trust boundaries. The implementation enforces three of them. The other two exist only on paper. (The Pulse worked example F-02 caught one: tenant boundary declared in ARCH.md §6 but the touchpoint endpoint bypassed the helper.)

**Grep test.** Every named trust boundary in `.architecture-ready/ARCH.md` §6 has a code-path attribution. The harden-ready review verifies the code path enforces what the document claims.

**Guard.** Step 4 of the workflow walks each boundary, code in hand. Findings against paper-boundaries are blocking.

### Hardening as ritual (Critical)

**Shape.** Annual pen test. Findings get logged. None are fixed before the next annual pen test. Compliance auditor checks the box ("annual pen test conducted: yes"); the actual security posture doesn't move.

**Grep test.** Every pen-test engagement has: pre-engagement scope, findings list, remediation status per finding (resolved / risk-accepted / open), retest verification, and a documented next-engagement trigger (calendar or scope-change-driven, not "next year").

**Guard.** `references/pentest-prep.md` mandates retest discipline. The "annual = ritual" critique is named explicitly.

### Compliance without security (Critical)

**Shape.** SOC 2 Type II achieved. HIPAA assessment passed. The audit found nothing because nothing was looked at adversarially; checklists were filled. App still has SQL injection.

**Grep test.** Every compliance claim (SOC 2 CC, HIPAA 164.312, PCI-DSS 4.0, GDPR Article 32) has control-to-code evidence: the named control maps to a specific file/function in the codebase. Unmapped claims fail.

**Guard.** Step 5 of the workflow produces the control-to-code map. `references/compliance-frameworks.md` carries the per-framework canonical mapping templates.

### Shallow-audit traps (High)

**Shape.** The audit found only what tools surface. SAST caught the obvious eval-of-user-input. SCA caught the known CVE in lodash. The auth-bypass via JWT-secret-leak in CI logs went undetected because no tool looks for that.

**Grep test.** Audit scope includes: tool-surfaced findings, gray-box review against architecture, business-logic walkthrough (per-role per-resource), supply-chain check beyond CVE-database (typosquats, abandoned-package risk), secrets-leak audit (git history, CI logs, error tracker payloads).

**Guard.** Step 3 of the workflow runs all five layers. The "shallow audit" critique is named.

### CVE-of-the-week patching (Medium)

**Shape.** A new CVE drops in a popular library. The team panics, pins to a non-vulnerable version, ships. Repeats next week with the next CVE. Never asks: which CVE classes does our architecture make us vulnerable to; which classes are off-table.

**Grep test.** The hardening report includes a class-of-vulnerability map: which classes the architecture makes us susceptible to; which it eliminates by design. CVE response triages against the map (high-class CVEs get priority; off-table-class CVEs get logged but don't drop everything).

**Guard.** `references/post-incident-hardening.md` mandates the class-not-instance discipline. Per-CVE patching is allowed; per-CVE-as-strategy is not.

### Risk-accept without owner (High)

**Shape.** Pen-test finding logged as "risk-accepted." No named owner; no documented compensating control; no re-evaluation date. A year later the finding is forgotten; nobody knows the risk was accepted.

**Grep test.** Every risk-accepted finding has: named owner (CEO / CISO / VP Eng), compensating control (named mechanism that reduces likelihood or blast radius), re-evaluation date (specific date, not "later"), CHANGELOG-grade audit trail.

**Guard.** `references/actionable-findings.md` mandates the four-element risk-acceptance template. Findings without all four are "open," not "risk-accepted."

### Front-door exploitable, side-door scanned (Critical)

**Shape.** The team scans the API. Finds nothing. The web UI form has a CSRF gap that lets a malicious site trigger a fund transfer. The scanner didn't see the form-side issue because it was scanning the API.

**Grep test.** Adversarial review covers: web UI (forms, navigation, state mutations), API (every documented endpoint), worker / cron (scheduled jobs), integrations (third-party callbacks, webhooks). Reviews that scope only one fail.

**Guard.** Step 3 of the workflow forces multi-surface review. The "front-door" critique is named.

### Responsible disclosure with no policy (High)

**Shape.** SECURITY.md exists. Lists `security@example.com`. The mailbox is unmonitored; reports bounce or sit unread. A real vulnerability report goes silent for 90 days; the researcher publishes publicly.

**Grep test.** SECURITY.md lists: real reporting channel (GitHub Security Advisories preferred, real email fallback), response-time SLA per severity, disclosure timeline policy, hall-of-fame or bounty disclosure. The reporting channel must be monitored (someone reads it weekly minimum).

**Guard.** `references/responsible-disclosure.md` mandates the four-element template. Step 6 of the workflow verifies the channel is monitored.

### Pen-test scope that excludes the actual app (Critical)

**Shape.** Pen-test engagement scoped to "the marketing website." The dashboard at `app.example.com` is excluded ("internal only"). The dashboard is the product. The marketing website is a static page. The engagement passes; nothing meaningful was tested.

**Grep test.** Pen-test scope covers: production application, authentication surface, authenticated data plane, integrations. Engagements that scope only marketing surfaces fail.

**Guard.** Step 1 of pen-test prep sets scope against the architecture's component diagram. The engagement letter is reviewed against the component list.

### Logging secrets to log aggregator (Critical)

**Shape.** Refresh tokens, API keys, OAuth secrets logged at INFO level and shipped to a third-party log aggregator. The aggregator now stores secrets; if the aggregator is compromised, the secrets leak. (Pulse F-01 worked example.)

**Grep test.** Logging code passes through a redacter that masks named-sensitive fields (`refresh_token`, `access_token`, `password`, `email`, `ssn`, etc.). A `grep -rE 'console\.log\(.*token|console\.log\(.*password' src/` returns zero matches.

**Guard.** `references/api-hardening.md` mandates the redaction list. The lint catches log-emission code that emits sensitive fields outside the auth module.

### Authentication of any-credential-passes (Critical)

**Shape.** The auth handler returns 200 if the credential is "valid format" (not actually valid). Any well-formed JWT signs in. Any email-without-verification redeems the magic link.

**Grep test.** Auth handler verifies cryptographic signature (JWT) or one-shot token redemption (magic link). Format-only checks fail.

**Guard.** `references/auth-hardening.md` carries the verification checklist.

### Cross-tenant data leak via missing scope (Critical)

**Shape.** Multi-tenant app. A domain query reads from a table without `tenant_id` filter. User in tenant A can read tenant B's data by guessing or enumerating IDs.

**Grep test.** Same as production-ready's antipattern: every data-access call passes `tenant_id`. The harden-ready review verifies independently of production-ready's own review.

**Guard.** Step 4 of the workflow walks the tenant boundary. Findings here are blocking for any multi-tenant deployment.

### Verbose error responses revealing internals (High)

**Shape.** The login endpoint returns "user not found" vs "invalid password" depending on which is true. Attackers enumerate registered email addresses by attempting login with various addresses.

**Grep test.** Authentication and account-related endpoints return generic "verification failed" / "invalid credentials" responses. Endpoints that distinguish between user-not-found and password-wrong fail.

**Guard.** `references/auth-hardening.md` mandates generic error responses on auth surfaces.

### Security findings without retest (High)

**Shape.** Pen-test finds 8 issues. Team fixes all 8. Pen-test report stays as the original 8-issue document. The retest never happened. Did the fixes actually resolve the issues? Unknown.

**Grep test.** Every fixed-or-risk-accepted finding has a retest verification: the auditor confirmed the fix works, in writing, with date. Unverified fixes fail.

**Guard.** `references/pentest-prep.md` mandates retest discipline. The engagement letter scopes the retest as a separate phase.

### Branch protection bypassed via MCP commit tool (Medium)

**Shape.** `.claude/settings.json` denies `git commit --no-verify`. An MCP tool installed on the agent provides a `commit` capability that writes commits directly via libgit2, skipping pre-commit hooks. The denylist is bypassed via the alternate path.

**Grep test.** Audit of installed MCP tools / agent extensions. Tools that can write commits without hooks are flagged.

**Guard.** Cited from repo-ready's `references/agent-safety.md` §6b. The harden-ready review covers agent-runtime concerns alongside app-code concerns.

## Severity ladder

- **Critical**: blocks the security tier. Must be fixed (or risk-accepted with named owner) before declaring hardening complete.
- **High**: blocks the tier gate. Must be fixed before next milestone or pen-test retest.
- **Medium**: flagged in the report; fix recommended this cycle.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §"The 'have-nots'": canonical have-nots list.
- `references/owasp-walkthrough.md`: OWASP Top 10 (Web / API / LLM) systematic walkthrough.
- `references/compliance-frameworks.md`: SOC 2 / HIPAA / PCI-DSS / GDPR control-to-code mapping.
- `references/pentest-prep.md`: pre-engagement scope, retest discipline.
- `references/post-incident-hardening.md`: class-not-instance learning.
- `references/responsible-disclosure.md`: SECURITY.md beyond the file.
- `references/auth-hardening.md`: authentication verification, generic errors.
- `references/api-hardening.md`: rate limiting, redaction, validation.
- `references/actionable-findings.md`: risk-acceptance four-element template.
- `references/security-tooling-landscape.md`: scanner / SAST / SCA inventory.
