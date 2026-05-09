# harden-research: Step 0 mode detection and attack-surface framing

Loaded always. The research report `RESEARCH-2026-04.md` is the source-citation base; this file is the operational procedure that Step 0 of the skill runs against.

## The five modes

Every hardening pass starts with one. Declare it in writing, in the STATE.md, before any verification step.

### Mode A: Pre-launch hardening

No incidents yet. No audit pending. Founder or team wants to ship with a credible security posture. Time horizon is typically days to a few weeks before launch.

- **Load-bearing sections:** all of Steps 1 through 13 at baseline depth. The manual OWASP walkthrough is the single highest-leverage activity.
- **Artifact shape:** a findings report formatted for an internal engineering audience, with severity-ordered backlog for pre-launch fix-sprint planning.
- **Stopping rule:** Tier 2 (Audited) before launch is the minimum; Tier 3 (Hardened) before a paid customer is the preferred shape; Tier 4 (Accountable) before a compliance-triggering customer (a bank, a healthcare buyer, an enterprise with security review).

### Mode B: Pre-audit hardening

An external audit is on the calendar. SOC 2 Type I or Type II, HIPAA, PCI-DSS 4.0, GDPR-shaped European enterprise review, or a customer-driven security questionnaire. The observation period is within twelve months or already started.

- **Load-bearing sections:** Step 7 (compliance control-to-code mapping) is the anchor. Step 3 to Step 6 run to ensure the auditor's ad-hoc checks do not find anything the organization has not already mapped. Step 10 (responsible-disclosure) is load-bearing because a missing program is a near-universal SOC 2 finding.
- **Artifact shape:** a compliance binder organized by framework control ID, with each control pointing to file paths, configuration keys, or log queries. Separate findings report for non-compliance technical findings the auditor will not see but the engineering team must fix.
- **Stopping rule:** Tier 4 (Accountable) is the only honest stopping point; earlier tiers are mid-flight, not done.

**The compliance-without-security pitfall.** Every Mode B engagement risks producing a clean audit over an unhardened app. The cross-framework control list (Section 5 of the research) names the nine engineering controls that dominate the overlap; verify those at adversarial depth before the check-box pass. If the control is "encryption at rest" and the evidence is "TDE enabled," verify whether the Restricted PII column is also protected against SQL injection extraction (column-level encryption), not just the disk-file-theft scenario. Otherwise the control passes audit and fails adversary.

### Mode C: Post-incident hardening

An incident landed. Initial patch is deployed. The on-call is out of crisis mode. The question now is: what class did that bug belong to, what other instances exist, and what architectural change prevents the class from recurring.

- **Load-bearing sections:** Step 13 (class-not-instance) is the anchor. Step 3 is re-run narrowly against the class. Step 11 adds the incident-as-finding to the report, with the class-identification and the class-survey documented.
- **Artifact shape:** a class-fix registry entry in `.harden-ready/CLASS-FIXES.md`; an updated findings report with the class-survey results; a post-incident hardening brief for the on-call and engineering team describing the architectural or policy change landed.
- **Stopping rule:** Tier 3 (Hardened) with the class-level regression guard committed. Not just the instance fix; the guard.

**The CVE-of-the-week trap.** Mode C fails into CVE-of-the-week the moment the instance fix is declared done and the class-review is skipped. Log4Shell's patch sequence (2.15 incomplete, 2.16 incomplete, 2.17 discovered bypass, 2.17.1 final) is the canonical example of what happens when the class is not hardened on the first pass.

### Mode D: Continuous hardening

Ongoing program. The skill runs at a cadence: monthly for tool-review, quarterly for tabletop and class review, annually for pen test or continuous bug-bounty triage.

- **Load-bearing sections:** Step 13 across incidents in the quarter; Step 8 for scanner drift; Step 10 for disclosure-program health (time-to-first-response trending, bounty payout distribution); Step 7 for compliance evidence refresh (annual SOC 2, annual HIPAA risk assessment).
- **Artifact shape:** an additive-delta against the prior pass's findings report; a cadence calendar in `.harden-ready/CADENCE.md` with the next execution dates per activity.
- **Stopping rule:** the cadence is met. Mode D has no terminal "done"; a gap in cadence is the finding.

### Mode E: Pre-pen-test hardening

An external engagement is scheduled (Cobalt, HackerOne Pentest, a boutique firm, a customer-required third-party test). The ask is to minimize the external team's time spent on already-known-class findings so their budget goes to the novel surface.

- **Load-bearing sections:** Step 9 (pen-test prep) leads. Steps 3 to 6 run before the engagement with the explicit goal of clearing the known-class findings so the pen test finds what the internal team cannot.
- **Artifact shape:** scope and ROE documents the external team signs; a pre-test baseline findings report the external team receives; a retest-tracking table for the engagement's findings.
- **Stopping rule:** Tier 4 with the retest complete, not Tier 3 with fixes landed. A pen-test engagement without retest is hardening-as-ritual in the most expensive form.

## Mode detection protocol

If the user did not declare a mode, ask. If the ask would delay the first productive step, detect from signals:

- **"We are launching next month" / "we want security review before Product Hunt"** -> Mode A.
- **"Our SOC 2 starts next quarter" / "enterprise prospect is asking for HIPAA BAA"** -> Mode B.
- **"Someone reported a vulnerability" / "we had an incident last week"** -> Mode C.
- **"Quarterly security review" / "what should I do this sprint for security"** -> Mode D.
- **"Cobalt is starting in two weeks" / "we are engaging NCC"** -> Mode E.

Modes can co-occur. A pre-audit (B) with a recent incident (C) with a pen test scheduled (E) is a real posture. The mode declaration is a prioritization decision, not a type classification.

## The attack-surface inventory procedure

Step 1 of the skill. This section is the procedural companion.

### Enumerate endpoints

Do not trust a single source. Walk all three and reconcile.

1. **Code-side enumeration.** Grep the routing code for HTTP route declarations. Next.js `app/` directory, Express `app.METHOD`, Django `urls.py`, Rails `routes.rb`, FastAPI `@app.METHOD`, Hono `app.METHOD`. Record every route with its auth requirement (from the middleware chain).
2. **Schema-side enumeration.** If the app has an OpenAPI/Swagger document, a GraphQL schema, or a gRPC `.proto`, enumerate from there. A route that exists in code but not in the schema is a private or accidental endpoint. A route in the schema but not in code is dead documentation. Both are findings.
3. **Runtime enumeration.** Against the deployed app, request `/sitemap.xml`, `/robots.txt`, `/.well-known/`, `/openapi.json`, `/graphql` (introspection), `/debug`, `/admin`, `/status`, `/_next/static/`, `/__next/data/`, and similar. Inspect the frontend JavaScript bundle for API calls (search for `fetch(`, `axios.`, Apollo client URLs). The goal is to find endpoints the code-side enumeration missed.

Reconcile the three lists. Discrepancies are Step 1 findings.

### Classify endpoints by auth requirement

Four buckets:

- **Unauth.** Public access. The attack surface from an anonymous attacker.
- **User.** Logged-in, no role check. The attack surface from a free-tier customer.
- **Role.** Specific role required. The attack surface from a privileged user compromised (admin-token phishing, support-account insider).
- **Service.** Internal-only, service-to-service. The attack surface from a compromised internal service (container escape, supply-chain).

A route that says "requires auth" in a comment and has no middleware check is Unauth; trust the middleware, not the comment.

### Identify data assets

Every storage system the app writes to or reads from. Databases, object stores, caches, message queues, vector stores, search indexes, secret stores, feature-flag stores, telemetry sinks.

For each, the data classification from production-ready's four-tier scale (Public / Internal / Confidential / Restricted). Name the PII and Restricted columns explicitly. A table with an `email` column, a `phone` column, a `date_of_birth` column, and a `password_hash` column is four PII fields on one table; name them. A Restricted classification implies encryption-at-rest-plus-app-layer-encryption; the compliance map in Step 7 will ask for evidence of both.

### Map trust boundaries to enforcement

For every declared trust boundary in `.architecture-ready/ARCH.md`, name the enforcement mechanism:

| Boundary type | Enforcement candidates |
|---|---|
| Internet <-> edge | CDN rules, WAF, Cloudflare, Cloud Armor |
| Edge <-> application | Ingress controller, reverse proxy, API gateway auth |
| Application <-> database | ORM-level scope, RLS policy, Postgres roles, connection-string isolation |
| Application <-> third-party | OAuth scopes, API key scoping, network-level egress policy |
| Tenant A <-> Tenant B (multi-tenant) | Row-level security, tenant-aware query wrapper, separate schema per tenant |
| Admin <-> customer | Role check at middleware, Separate admin subdomain with IP allowlist |
| Production <-> staging / PR envs | Separate VPC, separate credentials, no cross-env network |

A boundary without any of these backing it is a paper trust boundary. File it.

### Third-party privileged integrations

For every external service the app gives a credential to, record:

1. The service name and what it does.
2. The credential type (API key, OAuth token, service-account key, IAM role).
3. The scope of privilege: read-only, read-write, admin, billing access.
4. What data the third party sees (raw or redacted).
5. The rotation cadence and owner.

This is the supply-chain inventory the auditor will ask for and the incident-response plan will need. A third party with data-read privilege and no rotation cadence is a slow-motion breach waiting for the third party's compromise.

### Users and roles

The RBAC matrix from `.production-ready/STATE.md` is the input. Verify:

- Every role has a defined set of capabilities. Wildcard roles ("admin can do everything") are flagged for Step 4 verification.
- The "role escalation path" is documented: how does a customer become an admin, who has the capability, how is the change audited.
- Impersonation capability (support can view as customer) is documented, scoped, and audited. Impersonation with full write access is usually wrong; read-only impersonation with signed audit log is the pattern.

## The "where to look first" heuristic

When the session has limited time, prioritize:

1. **Unauth endpoints first.** Anything a curl from the internet can hit is the immediate surface. The Lovable CVE-2025-48757 class is exactly this (anon-key Supabase access).
2. **BOLA-class object-ID endpoints.** Anything with an ID in the path (`/api/orders/:id`, `/users/:id/documents/:docId`). API1 from OWASP API 2023 is the most common finding in AI-generated apps.
3. **LLM integration surfaces.** If the app has an LLM feature, the lethal-trifecta check (Willison) and Rule-of-Two check (Meta) come before anything else. The 540% bounty finding rate in 2025 is empirical.
4. **Auth library surface.** JWT verification path, OAuth callback, session regeneration.
5. **File upload endpoints.** Magic byte validation and presigned-URL discipline.
6. **GraphQL introspection and cost.** If a GraphQL endpoint is exposed unauth or under-authenticated, introspection in production is a leak.

If the pass catches only these six classes, it has covered 70% of the adversarial surface for a typical AI-generated web app in 2026.

## The upstream-artifact checklist

At Step 0, check for and read:

- `.architecture-ready/ARCH.md` (trust boundaries, data-flow diagrams, NFRs).
- `.production-ready/STATE.md` (user journeys, RBAC matrix, feature inventory).
- `.production-ready/adr/*.md` (security-relevant decisions).
- `.deploy-ready/TOPOLOGY.md` (environments, services, public URLs, WAFs).
- `.deploy-ready/STATE.md` (current deploy state, migration in flight).
- `.observe-ready/SLOs.md` (availability targets, error-budget policy).
- `.observe-ready/alert-catalog.md` or equivalent (existing detections).
- `.observe-ready/INDEPENDENCE.md` (status page / disclosure inbox out-of-band status).
- `.repo-ready/SECURITY.md` (baseline disclosure contact).
- `.stack-ready/DECISION.md` (chosen security tools).
- `.launch-ready/STATE.md` if a launch is in flight (the timing constraint).

Absences are not failures. They are context. Record which artifacts were absent in the findings report's "Scope and Context" section so the reader understands what harden-ready inferred versus what it consumed from upstream.

## Research-report index

When a section of the skill needs deeper citation, load the corresponding research-report section on demand rather than loading the full report.

| Research section | When to load |
|---|---|
| Section 1 | When naming or refusing a failure-mode (skill body). |
| Section 2 | When writing a finding that cites an incident as precedent. |
| Section 3 | When citing OWASP, NIST, ISO, or a canonical book. |
| Section 4 | When writing the tooling-verification notes in Step 8. |
| Section 5 | When writing the compliance control mapping in Step 7. |
| Section 6 | When designing or reviewing a bug-bounty program (Step 10). |
| Section 7 | When running the OWASP walkthrough in Step 3. |
| Section 8 | When running the auth / API / crypto deep verification. |
| Section 9 | When preparing a pen test (Step 9). |
| Section 10 | When running the class-fix discipline (Step 13). |
| Section 11 | When writing findings (Step 11). |
| Section 12 | When the app integrates LLMs (Step 3 LLM Top 10, Step 4 Rule-of-Two). |
| Appendix D | When a finding needs narrative incident context. |
| Appendix E | When a compliance question needs deeper framework detail. |
| Appendix F | When choosing or configuring a specific tool. |

Every citation in the skill body traces back to these sections. A finding that cites "industry best practice" without pointing to a research-section citation is under-grounded.

## The single most important sentence

From the research summary: every have-not in harden-ready's SKILL.md should trace to one of the five catalog findings: (1) scanner-passed-but-exploitable (Veracode 45%); (2) RLS-configured-but-curlable (Lovable CVE-2025-48757); (3) dependencies-pinned-without-hash-integrity (slopsquatting); (4) SECURITY.md-without-triage-workflow (Lovable 48-day disclosure gap); (5) system-prompt-says-not-to-do-X (HackerOne 540% prompt-injection bounty growth).

If the hardening pass is not actively looking for these five classes, it is not actually looking.
