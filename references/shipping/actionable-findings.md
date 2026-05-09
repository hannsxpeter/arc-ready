# actionable-findings: the finding template, severity vocabulary, and retest discipline

Loaded at Tier 2 (Step 11) and Tier 3 (Step 12). The load-bearing reference for what harden-ready ships. A hardening pass's deliverable stands or falls on the quality of the findings in its report.

## The non-negotiable template

Every finding in every harden-ready report uses this structure. Deviation is a finding against the hardening pass itself.

```
## F-NN: <specific title>

**Severity.** <Critical|High|Medium|Low|Informational>
**CVSS 3.1.** <vector string> (<score>)
**CVSS 4.0.** <vector string> (<score>)   <-- if the vendor workflow uses 4.0; include both if both are used
**EPSS.** <percentile or score>    <-- if applicable and the vulnerability is in the NVD
**KEV.** <Yes|No>                  <-- CISA Known Exploited Vulnerabilities
**CWE.** <CWE-N with title>
**OWASP.** <Top 10 category, e.g., "Web A01:2021 Broken Access Control" or "API API1:2023 BOLA">
**Status.** <Open|Triaged|Assigned|In Progress|Fixed|Retested|Closed|Accepted>
**Assignee.** <named engineer or team>
**Due.** <ISO date by which Critical/High must close>

### Affected asset
<file path, URL, service, version, commit hash, environment>

### Description
<one paragraph describing the bug in engineering terms. Not marketing terms. Not hedged. Direct.>

### Reproduction
1. <exact step 1; commands run verbatim>
2. <exact step 2>
3. <observe: specific expected output or screenshot referenced>

### Impact
<what the attacker accomplishes; what user data is exposed; what system state can be modified; the business-impact translation (one sentence) of the CVSS vector>

### Root cause
<the design or implementation error. Not the symptom. "Missing authZ check on /orders/:id" is symptom; "the controller reads the object by client-supplied ID without re-resolving ownership through the session's tenant predicate" is root cause.>

### Proposed fix
<specific code or configuration change. Include a code example in the language of the affected asset.>

```<lang>
// before
app.get('/api/orders/:id', requireAuth, async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  res.json(order);
});

// after
app.get('/api/orders/:id', requireAuth, async (req, res) => {
  const order = await db.orders.findOne({
    id: req.params.id,
    tenantId: req.session.tenantId,
  });
  if (!order) return res.status(404).end();
  res.json(order);
});
```

### Regression prevention
<test, lint rule, architectural change that prevents the class from recurring. A Semgrep rule against the `findById` pattern on tenant-scoped resources. A new integration test in the CI suite. A policy: "all new routes on tenant-scoped tables require a tenant-scoped find".>

### Retest
<the exact command or action that verifies the fix. "With user A's token, curl GET /api/orders/<user_B_order_id>; expected 404; observed: [fill in after retest]".>

### References
- CWE: <link>
- OWASP: <link>
- Related advisory or CVE: <link>
- Related finding in this report: F-MM (if any)
```

A finding missing any section is incomplete. `Status = Open` on an incomplete finding is a shallow-audit signature.

## Severity vocabulary

The scale is five-point: Critical, High, Medium, Low, Informational. Severity is a triage signal; it drives which findings block release, which are ticketed, and which are tracked.

### Anchoring severity

Severity is not a label. It is justified by:

1. **CVSS vector string** calculating the base score. CVSS 3.1 is still the most common in reports as of April 2026 [Picus: why CVSS is not enough, 2025](https://www.picussecurity.com/resource/blog/vulnerability-prioritization-why-cvss-isnt-enough). CVSS 4.0 (released late 2023) is adopted by vendors that want the new threat and supplemental metrics; dual-publish if the workflow requires both.
2. **EPSS score** (Exploit Prediction Scoring System), when the vulnerability is in the NVD and has a CVE. EPSS v4 as of March 2025 is the current model [FIRST.org EPSS](https://www.first.org/epss/). EPSS gives a 30-day exploitation probability; above 0.70 is "likely to be exploited."
3. **CISA KEV** membership. If the CVE is in the CISA Known Exploited Vulnerabilities catalog, it is confirmed exploited in the wild [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog).
4. **Business-impact sentence.** CVSS is asset-neutral; the finding is about this specific app. "CVSS 8.1 High. Attacker can read all customer orders in a multi-tenant SaaS; for the median customer with 50K orders containing PII, exposes the full revenue ledger."

### The CVSS + EPSS + KEV composite

CVSS alone systematically deprioritizes 28%+ of actually-exploited vulnerabilities [Picus analysis cited above]. The 2025 best practice is the composite:

| Signal | What it tells you |
|---|---|
| CVSS Base (severity) | How bad if exploited. |
| EPSS (likelihood) | How likely exploited in next 30 days. |
| KEV (ground truth) | Whether in-the-wild exploitation is confirmed. |

Prioritize Critical fixes by: KEV = Yes > EPSS > 0.70 > CVSS >= 9.0 > everything else. A "Medium CVSS" (4.0 - 6.9) vuln that is in KEV is a Critical triage priority. A "Critical CVSS" (9.0+) vuln with EPSS 0.01 and not in KEV can wait behind the Medium-KEV item.

### Severity assignment rubric

For findings that are NOT in the NVD (most of them, since harden-ready findings are app-specific), anchor severity from the CVSS vector and the business impact. The rubric:

- **Critical.** CVSS 9.0+ OR business impact = "loss of all customer data" OR business impact = "unauthenticated remote code execution or authz bypass to full data." Blocks release.
- **High.** CVSS 7.0 - 8.9 OR business impact = "loss of one tenant's data, or loss of one sensitive data class, or auth bypass requiring user interaction." Blocks release for Mode A; fix before audit for Mode B.
- **Medium.** CVSS 4.0 - 6.9 OR business impact = "loss of low-sensitivity data class, or ergonomic attack surface, or exploitable only by authenticated user against their own data." Ticketed; fix within the quarter.
- **Low.** CVSS 0.1 - 3.9 OR informational gaps with minor impact. Tracked; fix when touching the area.
- **Informational.** No direct exploitation path but the absence of a defense-in-depth control. Tracked.

## What makes a finding actionable

Synthesized from canon report formats (Trail of Bits, Doyensec, NCC Group, Latacora; see citations in RESEARCH-2026-04.md Section 11).

An actionable finding answers five questions for five readers:

1. **The engineer who will fix it:** where is it, what is the root cause, what is the fix, how do I test the fix?
2. **The on-call who needs to know if it is being exploited:** what does exploitation look like in logs, what is the detection signal (observe-ready's domain, but the finding names the signal)?
3. **The founder / leadership who will decide on release blocking:** what is the business impact, what is the fix timeline, what is the risk of shipping with it open?
4. **The auditor:** what is the CWE, what is the OWASP mapping, what is the fix evidence (commit hash, retest log)?
5. **The security engineer on the next hardening pass:** what is the class of weakness, what class-level guard was or was not landed, has it recurred?

A finding template that omits any of the five answers fails at least one reader. The F-NN template covers all five.

## What a generic finding leaves out (the anti-pattern)

The AI-generated or automated-tool generic finding has this shape:

- Title: "SQL Injection vulnerability detected" (vague; which route, which parameter, which query).
- Severity: "High" (no CVSS, no justification).
- Description: "The application is vulnerable to SQL injection" (no specifics).
- Remediation: "Use parameterized queries" (no code example, no file reference).
- No reproduction.
- No retest.
- No CWE, no OWASP.

Why it fails:

1. The engineer cannot find the bug.
2. The engineer cannot reproduce the bug.
3. The engineer cannot verify the fix.
4. The auditor cannot confirm the fix landed.
5. The next hardening pass cannot tell if the class was hardened.

This is the shape of output that many automated SAST tools produce and that some paid pen testers output when the engagement is run to billable hours rather than deliverable quality. harden-ready refuses findings in this shape. An "issue" with only a title and a severity is rewritten to actionable or discarded as noise.

## Canon report examples

The following firms publish engagement reports that represent the quality bar. Read one end-to-end before writing findings at scale.

- **Trail of Bits.** [publications.trailofbits.com](https://publications.trailofbits.com/), [GitHub trailofbits/publications](https://github.com/trailofbits/publications). Reports include codebase-maturity evaluations scoring categories (Testing, Documentation, Memory Safety, Error Handling). Findings numbered, cross-referenced, graded H/M/L/Informational. Each finding has full reproduction. The format is the industry reference.
- **Doyensec.** [doyensec.com/resources.html](https://doyensec.com/resources.html). Engagement summaries public where clients permit. Clear reproduction, named maintainer engagement, retest state.
- **NCC Group.** [research.nccgroup.com](https://research.nccgroup.com/). Public advisories include status markers (Fixed / Risk Accepted / Not Fixed).
- **Latacora.** [latacora.com/blog](https://www.latacora.com/blog/). Blog-format writeups, opinionated, engineering-deep. The "Cryptographic Right Answers" post is canon for crypto-finding format.
- **HackerOne Hacktivity.** [hackerone.com/hacktivity](https://hackerone.com/hacktivity). Individual disclosure reports. Quality is variable but the best reports of any given year demonstrate reproduction depth.
- **Bugcrowd Priority One Report.** [bugcrowd.com/priority-one](https://www.bugcrowd.com/resources/reports/). Annual industry summary plus top-finding reproductions.

## The retest discipline

A finding is not closed until retest passes AND the regression guard is committed. The retest workflow:

1. **Fix landed.** The engineer commits the fix. The commit message references the finding ID.
2. **Retest commanded.** The retest command from the finding's Retest field is executed against the fixed version. The output is recorded in the finding as a Retest Log entry with a timestamp.
3. **Retest passes.** The observed output matches the "expected" described in the retest.
4. **Regression prevention landed.** The test, lint rule, or architectural change is committed. Reference the commit.
5. **Status changes to Closed.** Timestamp and the engineer's name recorded.

If retest fails, the finding reopens to In Progress. A failed retest is the second-most-valuable data point in the hardening pass (the first is the original finding); it teaches the team where the fix was incomplete.

### Retest log template

```
## F-NN Retest Log

### 2026-04-22T14:30:00Z -- first retest
- Fix commit: abcd1234
- Command: `curl -H "Authorization: Bearer $USER_A_TOKEN" https://api.example.com/orders/ORDER_ID_BELONGING_TO_USER_B`
- Expected: 404 Not Found
- Observed: 404 Not Found
- Pass.

### Regression prevention
- Semgrep rule: `.semgrep/find-by-id-without-tenant.yml` committed in commit abcd1234.
- Integration test: `tests/integration/orders.tenant-isolation.spec.ts` committed in commit abcd1234.
- Status: Closed.
```

## The findings index

At the top of `.harden-ready/FINDINGS.md`, maintain an index table for quick triage:

| ID | Title | Severity | CVSS | OWASP | Status | Assignee | Due |
|---|---|---|---|---|---|---|---|
| F-01 | BOLA on GET /api/orders/:id allows cross-tenant order read | Critical | 9.1 | API1:2023 | Closed | @alice | 2026-04-22 |
| F-02 | JWT verification accepts alg:none tokens | Critical | 9.8 | Web A07:2021 | Closed | @bob | 2026-04-20 |
| F-03 | OAuth callback does not validate state parameter | High | 7.4 | Web A01:2021 | In Progress | @charlie | 2026-04-30 |
| F-04 | Supabase anon key exposes unauth write to `user_profiles` | Critical | 9.3 | API1:2023 | Closed | @alice | 2026-04-21 |
| F-05 | Argon2id parameters too low (t=1, m=1024) | Medium | 5.3 | Web A02:2021 | Fixed | @bob | 2026-05-15 |
| F-06 | No lethal-trifecta assessment on email-summary LLM feature | High | 7.5 | LLM01:2025 | Triaged | @dana | 2026-05-15 |

The index is the answer to "what is the state of the hardening posture." Updated on every finding-state change. Readers of the report read the index first, drill into specific findings on demand.

## Severity-driven triage flow

```
Finding lands in report
      |
      v
Is this a release-blocker (Critical/High) for the next ship?
      |       \
      Yes      No
      |         |
 Block ship    Ticket in backlog
      |         |
 Fix now      Fix in sprint / quarter
      |         |
 Retest       Retest
      |         |
 Class survey  Class survey
      |         |
 Class fix    Class fix (if class is hot)
      |         |
 Close        Close
```

Every Critical and High passes through class-survey and class-fix (Step 13). Medium and Low pass through class-survey only if the class is hot (multiple instances found in the survey); otherwise they close on individual retest.

## Multi-pass convergence

Hardening passes compound over time. Second-pass findings are often:

- Instances of a class that was identified but not fully hardened on the first pass.
- New classes that emerged from feature development between passes.
- Tooling drift (a scanner that ran on pass 1 is no longer running; a secret-scanning rule was disabled).

A healthy multi-pass trajectory shows:
- Critical / High count declining across passes.
- Class-fix registry growing (more classes hardened, not more instances patched).
- Time-to-retest decreasing (regression guards catch repeats in CI before a hardening pass re-discovers them).
- Compliance evidence refreshes in place, not re-discovered.

If the trajectory is flat or worsening, the hardening process is running but not effective. The retrospective conversation to have: are we patching instances (CVE-of-the-week) rather than hardening classes?

## Two worked examples

### Example A: BOLA finding written well

```
## F-01: BOLA on GET /api/orders/:id allows cross-tenant order read

**Severity.** Critical
**CVSS 3.1.** AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:N (8.5)
**EPSS.** N/A (application-specific; not in NVD)
**KEV.** No
**CWE.** CWE-639: Authorization Bypass Through User-Controlled Key
**OWASP.** API API1:2023 Broken Object Level Authorization
**Status.** Closed
**Assignee.** @alice (platform team)
**Due.** 2026-04-22

### Affected asset
src/app/api/orders/[id]/route.ts, commit bef12de, production at https://api.example.com

### Description
The GET handler for /api/orders/:id resolves the order by the URL-supplied ID without re-resolving ownership through the authenticated session's tenant_id. A user authenticated in tenant A can read orders belonging to tenant B by supplying a valid order ID from tenant B.

### Reproduction
1. Log in as User A (tenant A). Note the session cookie `session=...`.
2. Log in as User B (tenant B) in an incognito window. Create an order; note the returned order ID `ord_xyz123`.
3. Back in User A's browser, request `GET https://api.example.com/api/orders/ord_xyz123`.
4. Observe: 200 OK with the full order JSON belonging to tenant B.

Expected: 404 Not Found (do not even confirm the order exists to tenant A).

### Impact
Any authenticated user on any tenant can enumerate order IDs (sequential or derived) and read orders from every other tenant. For the median customer with 50K orders containing PII (customer email, shipping address, purchase history), this is a full ledger leak. GDPR Article 32 and HIPAA 164.312(a)(1) both imply access control of Protected Health Information and personal data; this finding violates both.

### Root cause
The controller at src/app/api/orders/[id]/route.ts line 14 calls `db.orders.findUnique({ where: { id: params.id } })` which does not scope by tenant. The session contains `tenantId` but it is not read in this code path.

### Proposed fix
Re-resolve the order through the tenant scope. Also return 404 (not 403) on mismatch to avoid confirming the ID's existence across tenants.

```typescript
// before
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession(req);
  if (!session) return new Response('Unauthorized', { status: 401 });
  const order = await db.orders.findUnique({ where: { id: params.id } });
  if (!order) return new Response('Not Found', { status: 404 });
  return Response.json(order);
}

// after
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession(req);
  if (!session) return new Response('Unauthorized', { status: 401 });
  const order = await db.orders.findFirst({
    where: { id: params.id, tenantId: session.tenantId },
  });
  if (!order) return new Response('Not Found', { status: 404 });
  return Response.json(order);
}
```

### Regression prevention
1. Semgrep rule in `.semgrep/rules/tenant-scoped-find.yml` that flags any `db.orders.findUnique` or `db.orders.findById` without a `tenantId` predicate; extended to the six other tenant-scoped tables (users, invoices, payments, sessions, webhooks, api_keys).
2. Integration test in `tests/integration/orders.bola.spec.ts` that provisions two tenants, creates an order in one, and asserts the other tenant cannot GET the order.
3. Architectural: new tenant-scoped tables added in future require the rule in (1) to apply; enforced by the code review checklist in CONTRIBUTING.md.

### Retest
Rerun the reproduction steps against the fixed version. Expected 404 on step 4.

Retest Log 2026-04-22T14:30Z: ran reproduction, observed 404, pass. Regression Semgrep rule, integration test, and checklist update all committed in commit abcd1234. Status -> Closed.

### References
- CWE-639: https://cwe.mitre.org/data/definitions/639.html
- OWASP API1:2023 BOLA: https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/
- Related finding: F-04 (same class, different table; see CLASS-FIXES.md class "paper trust boundary at object layer")
```

### Example B: Same finding written badly (the anti-pattern)

```
## Finding: Authorization issue

**Severity.** High

The application has an authorization issue on the orders endpoint. An authenticated user can view orders belonging to other tenants. This is a high-severity vulnerability.

**Remediation.** Add authorization checks to the endpoint.
```

Everything the engineer, auditor, on-call, leadership, and next-pass reader need to do their job is missing. This is noise. Rewrite or reject.

## The "is this actionable" grep

Before closing a finding for shipping in the report, verify each of these is present. Grep-friendly:

- `^\*\*Severity.\*\*` 
- `^\*\*CVSS`
- `^\*\*CWE`
- `^\*\*OWASP`
- `^### Affected asset`
- `^### Reproduction`
- `^### Impact`
- `^### Root cause`
- `^### Proposed fix`
- `^\`\`\`` (at least one code fence for the code example)
- `^### Regression prevention`
- `^### Retest`
- `^### References`

Any finding failing any of these grep checks goes back to Triaged status until the missing sections are filled.
