# Trust boundaries

The architecture's job at the trust-boundary layer is not to list security features. It is to mark every line in the system where authority transitions, to name what protects the transition, to name what an attacker gains when the transition fails, and to hand that list to production-ready's Step 2 threat model as a pre-filled input. An architecture that names components and interfaces but leaves trust boundaries silent is not an architecture; it is a box-and-arrow diagram that will ship a breach.

The skill refuses Tier 1 completion until the trust-boundary section names, at minimum, four boundaries: network edge, authentication, authorization, tenant/data isolation. For regulated domains a fifth boundary, compliance scope, is mandatory. "We use HTTPS and JWTs" is not a trust-boundary section; it is a stack list with security vocabulary.

## Section 1. What a trust boundary is and why it matters

A trust boundary is a line in the system where the authority of the caller transitions. Above the boundary, some assumption about identity, permission, or provenance holds. Below the boundary, that assumption may not hold, and the system must either re-establish it or refuse the request. Trust boundaries are not physical; they are assertional. The code on the inside of a boundary assumes the caller has been vouched for; the code on the outside assumes nothing.

Adam Shostack, "Threat Modeling: Designing for Security" (Wiley, 2014), defines trust boundaries as the central artifact of threat modeling: "wherever the level of trust changes, you have a trust boundary." Shostack's STRIDE mnemonic (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege) is organized around what can go wrong at each boundary: spoofing crosses an authentication boundary; tampering crosses an integrity boundary; information disclosure crosses a confidentiality boundary; elevation of privilege crosses an authorization boundary. A system whose threat model does not identify boundaries first cannot apply STRIDE meaningfully; the letters become a checklist with nothing to check against.

Why the architecture document owns this and not the security review: the boundaries are structural. Moving an auth check from middleware into a controller, or moving tenant isolation from the DB row-level policy into application code, is an architectural change, not a security patch. The placement of the boundary is the decision; the decision belongs in ARCH.md, not in a parallel security document that engineering ignores until audit.

The load-bearing claim: every PRD entity that represents real assets (user data, money, identity, content, access) passes through a trust boundary at every mutation. If the architecture does not name where those boundaries sit, the code will place them by accident, in different places per feature, and the gaps will be found adversarially.

## Section 2. The four canonical boundaries (plus one)

### 2.1 Network edge

**What it is.** The line where external traffic enters the system. Before the edge, the traffic is untrusted; after the edge, the traffic has at least been through basic sanitization, TLS termination, and coarse filtering.

**Typical placement.** CDN with WAF (Cloudflare, Fastly, AWS CloudFront + AWS WAF), load balancer with TLS termination (NLB/ALB, Nginx, HAProxy, Caddy), edge proxy (Envoy). Placement is not the cloud SKU; placement is "the first hop that inspects the bytes."

**What an attacker gains if it falls.** Direct access to internal services, no rate limiting, no bot defense, no TLS, no basic request validation. The origin is exposed to full internet volume, which enables DDoS, credential-stuffing floods, and scraping at origin cost.

**How it is enforced.** TLS with modern ciphers (TLS 1.3; TLS 1.2 with forward secrecy minimum). WAF rules for top-10 injection classes. Rate limiting keyed by IP plus identity when identity is known. Bot detection (managed or custom). IP allowlists for admin surfaces. mTLS where service-to-service traffic crosses the edge back in.

**Defense-in-depth minimum.** TLS at edge AND origin (do not terminate at edge and send plaintext to origin over a "private" link; private links have been breached). WAF at edge AND input validation at service. Rate limit at edge AND per-user quota at service.

### 2.2 Authentication

**What it is.** The line where an anonymous request becomes an identified one. The system asserts "this request is from user X" or "this request is from service Y" based on cryptographic evidence (password plus second factor, session cookie, signed token, mTLS certificate).

**Typical placement.** Identity provider (Auth0, Clerk, Okta, Cognito, Keycloak, homegrown). Session middleware in the application. Token verifier at service entry. mTLS cert verification at service mesh or load balancer.

**What an attacker gains if it falls.** Impersonation of any identity, including administrators. Full takeover of any account. Bypass of every downstream authorization check, because those checks assume the identity claim is valid.

**How it is enforced.** Strong password rules OR passkeys OR SSO. MFA for privileged accounts; MFA for all accounts in regulated domains. Short-lived tokens (15 minutes for access tokens; refresh with rotation). HttpOnly, Secure, SameSite cookies. Audience and issuer validation on every JWT. Clock-skew tolerance bounded. Key rotation on a schedule.

**Defense-in-depth minimum.** Authentication AND session fixation protection AND credential-stuffing detection. JWT verification AND audience check AND not-before/expiry check AND revocation check for high-blast-radius operations. Never "the token is signed, therefore the user is valid"; a stolen token is a signed token.

### 2.3 Authorization

**What it is.** The line where an authenticated identity is allowed (or not) to do a specific thing to a specific resource. Authentication says who you are; authorization says what you can do.

**Typical placement.** Middleware wrapper per route. Service-level permission check at method entry. Resource-level ACL at data access. Database-level row-level security policy. OPA (Open Policy Agent) sidecar. Service mesh policy enforcement.

**What an attacker gains if it falls.** Privilege escalation to any role, including admin. Access to any resource, including other tenants' data and administrative endpoints. The "horizontal" break (user A reads user B's data) and the "vertical" break (regular user performs admin action) both happen here.

**How it is enforced.** RBAC role table plus route-to-role matrix. ABAC attribute evaluator for context-dependent rules ("manager can approve expenses under $10k for reports in their own org"). ReBAC relationship graph for hierarchical or team-based access (Google Zanzibar, SpiceDB, OpenFGA). Tenant-scoped query filters. Deny-by-default default rule. Permission decisions logged for audit.

**Defense-in-depth minimum.** Authorization at service AND at database (row-level security). Authorization at API layer AND at UI layer (never trust the UI alone; treat UI checks as UX hints). Authorization check AND audit log entry for every mutation above a trivial threshold.

### 2.4 Tenant / data isolation

**What it is.** In a multi-tenant system, the line between tenant A's data and tenant B's data. The assertion: "a query issued on behalf of tenant A can return only tenant A's rows; a mutation on behalf of tenant A can modify only tenant A's rows." This is not an authorization decision at the per-resource level; it is a structural property of the data plane.

**Typical placement.** Application-level tenant column in every WHERE clause (WORST). Database row-level security policy bound to session context (BETTER). Per-tenant schema with schema search_path bound to session (GOOD). Per-tenant database selected by routing layer (STRONG). Per-tenant deployment / cell (STRONGEST, most expensive). See Section 7.

**What an attacker gains if it falls.** Cross-tenant data read. Cross-tenant data write. Cross-tenant DELETE. For a B2B SaaS, this is the single worst incident class; it is customer-facing in ways other breaches are not. Every tenant's data visible to every other tenant, plus the credibility cost that puts the company out of business.

**How it is enforced.** Row-level security (Postgres RLS, MySQL 8 VIEW-based equivalents) with session-scoped tenant context. Tenant ID foreign key on every tenant-scoped table, indexed, and NOT NULL. Integration tests that run as tenant A and assert tenant B's data is invisible. Fitness function in CI that parses queries for missing tenant filters.

**Defense-in-depth minimum.** Tenant filter at application AND at database (RLS). Integration test that tries to break the boundary from both the API layer and direct SQL. Audit log of any query that returns rows from more than one tenant (should be zero except for admin operations).

### 2.5 Compliance scope (the implicit fifth boundary, mandatory for regulated domains)

**What it is.** The line between "data the system processes that falls under regulation X" and "data that does not." HIPAA's PHI boundary, PCI-DSS's Cardholder Data Environment (CDE) boundary, GDPR's personal-data scope, SOX's financial-reporting scope. A compliance regime does not apply uniformly; it applies to specific data flowing through specific components.

**Typical placement.** A component boundary (this service handles PHI; this service does not). A database boundary (this database is in the CDE; this database is not). A network boundary (this VPC segment holds cardholder data; that one does not). A person boundary (this operator has HIPAA training and signed a BAA; that one has not).

**What an attacker gains if it falls.** Legal liability, not just technical compromise. A breach of the PHI boundary triggers HHS notification within 60 days, press disclosure for breaches over 500 records, OCR investigation, and civil monetary penalties up to $2M per violation category per year. A breach of the PCI CDE boundary triggers card-brand fines, forensic audit at the merchant's cost, and typical loss of merchant status for 6 to 24 months. A GDPR personal-data breach triggers DPA notification within 72 hours and administrative fines up to 4% of global annual turnover.

**How it is enforced.** Component-level labeling (this service is in-scope; this service is not). Data classification at the entity level. Network segmentation (PCI requires demonstrable segmentation to reduce CDE scope). Access logging at the boundary. Data-residency enforcement (GDPR).

**Defense-in-depth minimum.** Compliance scope declared in the data architecture (Step 4) AND in the trust boundaries (Step 7). Every cross-boundary dataflow named explicitly. A "data leaving the CDE" event is an architectural event, not a runtime one.

**Where architecture-ready stops.** This skill names the boundary and the in-scope components. The specific control mapping (which SOC 2 CC, which HIPAA 45 CFR 164.312 requirement, which PCI 4.0 requirement) is the future harden-ready skill's job. The architecture names the structural fact; compliance maps the controls.

## Section 3. The blast-radius catalog

Every architecture has a finite list of mutations that, if performed by the wrong actor or at the wrong scale, destroy the system or its customers. Name them explicitly. The following ten are load-bearing across essentially every B2B or B2C system with user data:

1. **Cross-tenant DELETE.** Tenant A issues a DELETE that affects tenant B's rows. Defense: tenant-scoped connection context, RLS, integration test per mutation endpoint. The Atlassian April 2022 outage (Section 6) is this class at a different layer: a deletion API that accepted the wrong identifier type.

2. **Admin impersonation.** Any user becomes any other user, or any user becomes an admin. Defense: separate admin-user table from customer-user table (no role flag on the customer user); impersonation only via explicit "support mode" with per-session audit log and customer notification; impersonation tokens tagged and refused by sensitive endpoints (password change, MFA enrollment, billing).

3. **Billing mutations.** Prices, plans, discounts, refunds, subtracting balances. Defense: separate billing service with its own auth boundary; every mutation logged immutably; amounts bounded by plan limits at the service; out-of-band notification to the account owner for any charge over a threshold.

4. **Password reset.** The attacker's favorite door. Defense: reset tokens scoped to the account, single-use, 15-minute TTL, delivered to verified channel only; MFA challenge required if enrolled; never reset as a side effect of any other flow.

5. **API key rotation.** An attacker who can rotate a key can substitute their own and lock out the legitimate user. Defense: rotation requires MFA, notification to a second channel, grace window in which both keys work, revocation audit.

6. **Export-all-data.** The "download everything" endpoint. One request, full blast radius. Defense: gated by admin role plus MFA plus an async job with email notification; rate limit per account per day; signed, expiring URL for the export artifact; export logs immutable.

7. **Role elevation.** A user's role changes from member to admin, or admin to owner. Defense: role changes require the higher-level role's approval, logged with signer identity, out-of-band notification to other admins.

8. **Subscription plan change.** Plan downgrade can delete data (by crossing tier-gated feature thresholds); plan upgrade can incur charges. Defense: downgrades confirmed out-of-band for plans with data-retention gates; upgrades confirm the charge amount before applying.

9. **Tenant creation.** A new tenant is a new isolation domain. Defense: tenant-create endpoint requires platform-admin role (not customer-admin); new tenants start with restricted quotas; tenant ID generation is cryptographically random, not sequential.

10. **Data deletion (destructive, not soft-delete).** Hard DELETE of rows without recovery path. Defense: prefer soft-delete by default; hard-delete only after a documented retention window, behind a separate pipeline with independent approvals; backups verified before destructive operations.

Every one of these mutations deserves a line in the trust-boundary section: what role can invoke it, what additional factor is required, what is logged, what is the out-of-band notification.

## Section 4. Defense in depth

The principle: no single enforcement layer is load-bearing on its own. For any boundary whose breach would constitute a company-ending incident, at least two independent enforcement layers must be in place, and neither layer is allowed to assume the other is working.

A canonical stack for a tenant-isolated multi-tenant SaaS:

1. **Edge layer.** WAF rules reject obvious injection, rate limits per IP, TLS termination.
2. **Service layer.** Authentication middleware verifies session or token. Authorization middleware verifies the role can invoke this route.
3. **Application layer.** Permission check at the handler: "this user has permission to mutate this specific resource." Tenant context attached to the DB session.
4. **Database layer.** Row-level security policy bound to session tenant context. Query returns zero rows if the tenant context is missing or mismatched.
5. **Audit layer.** Every mutation above a trivial threshold emits an audit event to an append-only log in separate storage.

"Defense in depth" is misused when it means "we have many security features." It is correctly used when it means "the failure of any single layer does not cause a breach." Test the property, not the inventory: remove layer N in a staging drill and confirm layers 1 through N-1 refuse the malicious request.

The anti-pattern to name: trusting the network. "Internal services don't need authentication because they're behind the VPC." The Capital One 2019 breach (Section 6) was an SSRF that turned an internal metadata service into an attack surface. Zero-trust architecture (Section 8) exists because the VPC is not a trust boundary.

## Section 5. Threat-model pre-fill for production-ready

production-ready Step 2 reads this file. Its threat-model block (from `/Users/hprincivil/Projects/production-ready/SKILL.md` lines 80 to 93) requires three one-line answers plus an optional compliance line. This section shows exactly what to write in ARCH.md so production-ready consumes it without interpretation.

The exact template production-ready expects:

```markdown
## Threat model (pre-fill for production-ready Step 2)

1. What does an attacker gain from this system?
   [One line. Concrete assets, not abstractions. "Patient PHI, enough to support
   insurance fraud or blackmail" is concrete. "Sensitive data" is not. Name the
   nouns: money, identity, data, content, access to third-party systems.]

2. What is the highest-blast-radius mutation?
   [One line. The mutation that, if performed by the wrong actor, destroys the
   customer or the company. For a B2B SaaS with tenant isolation: cross-tenant
   DELETE. For a payments system: unauthorized transfer. For a health record:
   modification of prescription. Name the action AND the actor who should not
   be able to do it.]

3. Where is each trust boundary?
   - Network edge: [where; how enforced.]
   - Authentication: [where; how enforced.]
   - Authorization: [where; how enforced.]
   - Tenant isolation: [where; how enforced.]
   [For regulated domains, add:]
   - Compliance scope (HIPAA PHI / PCI CDE / GDPR personal data): [which
     components are in-scope; what crosses the boundary.]

4. Compliance blast radius (regulated domains only).
   [One line. What kind of incident triggers disclosure. HIPAA breach notification
   within 60 days for PHI exposure of 500+ records. GDPR DPA notification within
   72 hours. PCI forensic audit and card-brand fines. SOX material misstatement.
   Name the regime AND the trigger AND the rough cost envelope.]
```

This is literally what production-ready Step 2 reads. If this section is missing, production-ready will stop and refuse to proceed; it will not guess. That refusal is by design; silent guessing at the threat model is the failure mode both skills exist to prevent.

## Section 6. Canonical trust-boundary failures

The postmortem record has documented the failure modes well. Each of the following is a real incident with a public writeup; cite them in ADRs when the architecture makes a decision that the incident informs. Sources are in `RESEARCH-2026-04.md` Section 5.

### 6.1 Facebook BGP, October 4, 2021 (the cleanest single trust-boundary failure on record)

A routine backbone-capacity audit command, with a bug in the audit tool that should have caught it, disabled Facebook's backbone network globally. Facebook's DNS servers are designed to withdraw BGP advertisements when they cannot reach data centers; the DNS servers could not reach the data centers, so they withdrew themselves from the internet. Internal tools required DNS. Badge readers required DNS. WhatsApp and Instagram required DNS. Recovery required physical access to data centers, and the physical-access systems partially required DNS.

**The trust-boundary lesson.** DNS advertised itself via the same network whose health DNS was meant to report on. The "internal" network and the "DNS availability" signal were the same trust boundary, but the architecture treated them as separate. The assumption "DNS will tell us if the backbone is down" failed because DNS could not speak without the backbone. See the official postmortems at https://engineering.fb.com/2021/10/04/networking-traffic/outage/ and https://engineering.fb.com/2021/10/05/networking-traffic/outage-details/.

### 6.2 Capital One, July 2019 (SSRF across a metadata trust boundary)

A misconfigured ModSecurity WAF on an EC2 instance allowed a server-side request forgery. The attacker used the SSRF to hit the EC2 instance metadata service, obtained the instance role's temporary credentials, and used the credentials to list and download 100M credit applications from S3 buckets the role had access to.

**The trust-boundary lesson.** The metadata service was implicitly trusted by anything running on the instance; the WAF bug made "anything running on the instance" include the attacker. The internal-network trust boundary was not a boundary; it was an assumption. Capital One settled for $80M in OCC penalties and $190M in class-action. IMDSv2 (Instance Metadata Service v2) was the AWS-side response: require a session token to fetch metadata, blocking naive SSRF.

### 6.3 Atlassian, April 2022 (polymorphic identifiers across a deletion API)

A maintenance script received site IDs where the deletion API expected app IDs. The deletion API accepted both without type-level validation; the script deleted 775 customer sites instead of deprecated apps. Recovery required 14 days because multi-tenant restore was not a first-class operation in the architecture.

**The trust-boundary lesson.** Polymorphic identifiers across a high-blast-radius mutation are a trust-boundary failure waiting to fire. Type-level boundaries (site-ID type vs. app-ID type) are part of the trust boundary at the deletion API; silent polymorphism is a breach of the "authority to delete" check. See https://www.atlassian.com/blog/atlassian-engineering/post-incident-review-april-2022-outage.

### 6.4 Knight Capital, August 2012 (dead code across a deployment trust boundary)

The shared binary contained a deprecated flag ("Power Peg"). Deployment to eight servers succeeded on seven; the eighth was not updated but received requests with the reused flag, activated the old code path, and lost $460M in 45 minutes.

**The trust-boundary lesson.** Deploy-parity was a trust boundary that was not enforced. The architecture assumed that all eight servers ran the same code; the deploy script's silent failure broke the assumption. Dead code is not neutral; it is a latent weapon waiting for a trigger. See the SEC release and Henrico Dolfing's case study in `RESEARCH-2026-04.md` Section 5.1.

### 6.5 Roblox, October 2021 (observability sharing fate with the observed system, a trust-boundary corollary)

HashiCorp Consul served as service discovery, configuration, and health reporting. Consul fell over under load (a Go-channel contention bug plus a BoltDB freelist linear-scan). Nomad, Vault, and the monitoring system all depended on Consul; recovery took 73 hours.

**The trust-boundary lesson.** The tool that reports on the system's health must not share fate with the system. Consul was across every trust boundary in the architecture (discovery, secrets, config, monitoring), making it a single point whose failure crossed every boundary at once. "Observability must not share fate with the system it observes." See https://corp.roblox.com/newsroom/2022/01/roblox-return-to-service-10-28-10-31-2021/.

The common thread across these five: the trust boundary existed, but the architecture either did not name it, or named it and assumed it would hold. Architecture-ready exists to force the naming; fitness functions (Step 10) exist to force the holding.

## Section 7. Multi-tenancy isolation models

The tenant-isolation boundary is the single highest-blast-radius boundary in most B2B SaaS, and the model chosen here constrains everything else. Four models, worst-to-best isolation, cheap-to-expensive operation:

### 7.1 Shared-schema with tenant-column filter (WORST isolation)

Every tenant-scoped table has a `tenant_id` column. Every query filters by `WHERE tenant_id = ?`. One tenant's rows sit next to another's in the same table.

- **Cost.** Cheapest. One database, one schema, one migration path.
- **Isolation.** Worst. A single missing WHERE clause returns every tenant's data. An ORM misuse, a direct SQL query in a report, a cache key that omits tenant_id, any of these is a breach.
- **Defense.** Row-level security bound to session context is mandatory, not optional. Integration tests per mutation per tenant. Code review specifically for cross-tenant queries. Fitness function that parses SQL for missing tenant filters.
- **When to use.** B2C with a tenant column that is effectively "the user," small B2B with low regulatory exposure, early-stage SaaS where per-tenant operational cost is not yet justifiable AND the team has RLS discipline.

### 7.2 Per-tenant schema (BETTER isolation)

One database, one schema per tenant. Queries run against the session's schema search path. Tables in tenant A's schema are not visible in tenant B's connection.

- **Cost.** Medium. Migrations must run per schema (sometimes thousands). Schema enumeration tools need care. Connection routing requires middleware.
- **Isolation.** Better. Cross-schema leaks require explicit schema-qualified queries; the default query path is isolated.
- **Defense.** Still run RLS within each schema for defense in depth. Migration tooling must be idempotent and parallel-safe.
- **When to use.** Mid-size B2B SaaS (hundreds to low thousands of tenants), regulatory pressure but not physical-separation requirements, team has schema-management discipline.

### 7.3 Per-tenant database (STRONG isolation)

One database per tenant. Connection routing selects the database at request time. Entirely separate tables, separate backup streams, separate restore paths.

- **Cost.** High. Database instance overhead per tenant (managed databases charge per instance). Cross-tenant analytics requires ETL to a separate warehouse. Migrations at scale are a deployment event.
- **Isolation.** Strong. A query in tenant A's database cannot reach tenant B's. Backups and restores are per-tenant naturally.
- **Defense.** Connection-pool-per-tenant or serverless database (Neon, PlanetScale, CockroachDB multi-tenant). Validation that the request's claimed tenant matches the connection's tenant.
- **When to use.** Enterprise SaaS with per-tenant compliance requirements (HIPAA BAAs sometimes require demonstrable data separation), high-ARPU tenants where the infra cost is amortized, regulated domains where audit demands per-tenant backup restoration.

### 7.4 Per-tenant deployment (cell-based, STRONGEST isolation)

A full deployment of the application per tenant or per cell (a pool of tenants). Separate compute, separate database, separate network. AWS Cell-Based Architecture (re:Invent 2023 onward) is the canonical industry reference.

- **Cost.** Highest. Per-cell deploy pipeline. Cross-cell operations require explicit integration. Operational complexity grows with cell count.
- **Isolation.** Strongest. Blast radius of any bug is one cell, not all tenants. Gradual rollouts can deploy to one cell first.
- **Defense.** Cell routing at the edge; cell identity in every log line; per-cell observability.
- **When to use.** Very high-ARPU enterprise, strict regulatory requirements, very large scale where blast-radius containment is load-bearing. AWS runs this internally; Slack Enterprise Grid runs a version of it; Datadog and Snowflake use cell-based architectures for customer isolation.

### 7.5 Decision framework

Pick the strongest isolation that the cost envelope supports. Write the choice as ADR-003 (tenant isolation model) with:

- The PRD constraint that drove the choice (tenant count, compliance regime, ARPU).
- The flip point: what would move you up the isolation ladder (regulatory event, scale threshold, a near-miss breach).
- The blast radius if wrong: a shared-schema breach is the "every tenant's data is visible" incident; a per-tenant-deployment breach is "one tenant's data is visible," which is a different severity.

The skill's default recommendation: start with shared-schema plus RLS for a greenfield B2B SaaS with no regulatory pressure and an appetite under 6 months. Plan the migration path to per-tenant-schema as a named flip point at a specific tenant count (commonly 1000 to 10000 tenants, where per-tenant operations start to matter). Do not default to per-tenant-deployment without a concrete forcing function; the cost is real and the team must be ready.

## Section 8. Zero-trust architecture as a posture (not a product)

Zero-trust is the explicit rejection of the "internal network is trusted" assumption. Every request, whether external or internal, is authenticated and authorized as if it came from a hostile network. There is no implicit perimeter.

Google's BeyondCorp is the canonical industry reference (https://cloud.google.com/beyondcorp). BeyondCorp started after the 2010 Aurora attacks on Google made it clear that perimeter defense had failed. The key claims:

1. Every request is authenticated (including service-to-service).
2. Every request is authorized against the specific resource.
3. Trust is not granted by network location.
4. Device identity and health are part of the authorization decision.

Zero-trust is a posture, not a product. "We bought a zero-trust gateway" is a stack list with zero-trust vocabulary. A real zero-trust architecture has:

- mTLS or signed tokens on every service-to-service call.
- Per-request authorization at every service entry, not just at the edge.
- Device identity in addition to user identity for privileged operations.
- Audit logs for every authorization decision that would have been implicit in a perimeter model.
- No "internal-only" endpoints that trust the calling network.

For architecture-ready, the zero-trust posture is an ADR (ADR-NNN zero-trust posture). If the answer is "we trust the VPC," write that as the decision with its blast radius (Capital One 2019 is the blast radius). If the answer is "we enforce every call," name the mechanism (service mesh, OPA sidecars, per-call JWT with short TTL) and the fitness function that catches regressions.

## Section 9. Auditing as a trust boundary

Audit logs are the tamper-evidence layer. When every other enforcement fails, the audit log is what enables forensics, what enables legal attestation, and what enables the organization to know that a breach happened at all. An architecture that names trust boundaries without naming the audit layer has missed the last boundary.

Requirements for a load-bearing audit log:

1. **Append-only.** No mutation of past entries; no delete. Use a backend that enforces this at the storage layer (S3 Object Lock, WORM storage, a blockchain-style hash chain, or an append-only Postgres table with REVOKE DELETE).
2. **Cryptographic chain.** Each entry includes a hash of the previous entry (or a Merkle tree commitment). Tampering with entry N invalidates every subsequent hash. Rekor (sigstore), Trillian (Google's general-purpose transparency log), and AWS QLDB are production-grade implementations.
3. **Separate storage from the audited service.** The service cannot write to its own audit log's storage directly; a sidecar, queue, or dedicated service owns the write path. Compromising the audited service must not compromise the audit record.
4. **Time source that is trusted and logged.** Use a time source independent of the audited service. RFC 3339 timestamps with timezone. Log the time source.
5. **What to log.** Every mutation above a trivial threshold; every authorization decision for high-blast-radius operations (Section 3); every authentication event; every administrative action.

When the audit log is compromised, the trust boundary is gone. "We discovered the breach, but the logs from the relevant period were also deleted" is the headline that ends companies. The architecture must name the audit boundary, its placement, and its independence properties.

## Section 10. The silent-trust-boundary refusal

Trust boundaries cannot be silent. A multi-tenant architecture with no named tenant-isolation boundary is a ticking time bomb. A payment-processing system with no named authorization boundary is a liability. A public API with no named edge or authentication boundary is an invitation.

The skill refuses to pass Tier 1 without:

- **Network edge** named with placement and enforcement.
- **Authentication** named with model, issuer, expiry, refresh.
- **Authorization** named with model (RBAC/ABAC/ReBAC) and placement (middleware, service, DB).
- **Tenant/data isolation** named with model (Section 7) and defense layers.
- **For regulated domains:** compliance scope named with in-scope components and what crosses the boundary.
- **The ten high-blast-radius mutations from Section 3** either explicitly addressed in the architecture, or explicitly acknowledged as not applicable with a reason (e.g., "no billing mutations in this system because billing is entirely Stripe-side").
- **Audit layer** named with placement and independence properties.

"We'll figure out auth later" is not an acceptable answer. The architecture is either load-bearing (Step 1 check), in which case trust boundaries are load-bearing, or it is not load-bearing (skip the skill with a one-page minimal ARCH.md). There is no intermediate state where the boundaries are "coming in a follow-up."

The hardest case: a greenfield project whose PRD does not mention security in detail. The architecture note is not excused; it must state the boundaries on the basis of the PRD's entities, flows, and implicit threats. If the PRD says "users can upload files," the architecture must name (a) who uploads, (b) what authentication gates the upload, (c) what authorization gates the visibility, (d) what tenant boundary applies, (e) what the blast radius of a cross-tenant upload leak would be, (f) what the compliance implication is if any uploaded file contains regulated data. The architecture is answerable to the PRD, and the PRD's silence on security is not the architecture's excuse.
