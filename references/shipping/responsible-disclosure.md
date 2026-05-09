# responsible-disclosure: the program beyond SECURITY.md

Loaded at Tier 4 (Step 10). Extends repo-ready's baseline SECURITY.md into a functioning program with a triage workflow, severity vocabulary, safe-harbor language, and a coordinated-disclosure timeline.

**The load-bearing rule.** A SECURITY.md with a contact email is not a disclosure program. The Lovable CVE-2025-48757 disclosure timeline is the cautionary case: 48 days between initial researcher contact and public disclosure because there was no triage owner, no SLA, and no coordinated-fix workflow. [TNW: Lovable security crisis](https://thenextweb.com/news/lovable-vibe-coding-security-crisis-exposed), [Matt Palmer: statement on CVE-2025-48757](https://mattpalmer.io/posts/statement-on-CVE-2025-48757/).

## The minimum: security.txt + policy

RFC 9116 (`security.txt`) is the machine-readable version of the disclosure contact. The policy page is the human-readable one. Both are required.

### security.txt per RFC 9116

[RFC 9116: File Format to Aid in Security Vulnerability Disclosure](https://www.rfc-editor.org/rfc/rfc9116).

Served at `/.well-known/security.txt`. Example:

```
Contact: mailto:security@example.com
Contact: https://example.com/security/report
Expires: 2027-04-22T00:00:00.000Z
Encryption: https://example.com/pgp-key.txt
Policy: https://example.com/security/policy
Acknowledgments: https://example.com/security/hall-of-fame
Preferred-Languages: en
Canonical: https://example.com/.well-known/security.txt
Hiring: https://example.com/careers#security
```

**Required fields.**

- `Contact:` (multiple allowed). Email alias (`security@`) preferred over individual humans.
- `Expires:` ISO 8601; must be in the future. Refresh before expiry; a passed `Expires` invalidates the file.

**Recommended fields.**

- `Encryption:` URL to PGP key for encrypted communication.
- `Policy:` URL to the public disclosure policy (see below).
- `Acknowledgments:` URL to a hall-of-fame page.
- `Preferred-Languages:` for international reporter handling.
- `Canonical:` canonical URL for this file; prevents spoofing on subdomains.

### Verification

```
curl https://example.com/.well-known/security.txt
# Expected: 200 OK, Content-Type: text/plain, valid RFC 9116 format.

# Check Expires is in the future
grep ^Expires .security.txt

# Check Contact resolves
dig MX $(grep ^Contact security.txt | grep mailto | sed 's/.*mailto://')
```

**Pass condition.** security.txt is served; Expires is in the future; Contact address resolves to a monitored inbox.

## The policy page

Separate URL (`/security/policy` or similar). Written; version-controlled; reviewed annually.

### Required sections

1. **Scope.** Which domains, which apps, which classes of issues are in scope. Explicit out-of-scope list (social engineering, DoS, physical, third-party services, theoretical crypto concerns).
2. **Safe harbor.** Written commitment not to pursue legal action against good-faith researchers operating within scope. Use standard language; [disclose.io](https://disclose.io/) maintains open-source templates.
3. **Submission format.** What format reports should take; PGP expected or optional.
4. **Response SLA.** "We acknowledge within X business days; triage within Y; fix critical within Z days."
5. **Severity vocabulary.** CVSS 3.1 or 4.0; internal severity mapping.
6. **Public disclosure timeline.** How long after remediation; coordination expectation with the reporter.
7. **Bounty statement.** If not running a bounty, say so. If running one, link.

### Safe harbor language

The disclose.io "Open Source Terms" template is the industry default. Adopt verbatim or adapt per legal review. Minimum substance:

> We will not take legal action against security researchers who operate in good faith within the scope of this policy. We consider the following activities authorized: (a) accessing data only to the extent necessary to demonstrate a vulnerability, (b) avoiding privacy violations, destruction of data, and interruption or degradation of services, (c) providing us reasonable time to respond before public disclosure.

## Severity vocabulary

CVSS is the industry standard; EPSS adds likelihood; KEV adds ground truth. Pick one baseline and document.

### CVSS 3.1 vs 4.0

**CVSS 3.1.** Still most common in reports as of April 2026. Base metrics: AV, AC, PR, UI, Scope, CIA impacts.

**CVSS 4.0.** Released late 2023. Base + threat + environmental + supplemental metrics. "Attacked" is the new high-signal state. [Malwarebytes: how CVSS v4.0 works](https://www.malwarebytes.com/blog/news/2025/11/how-cvss-v4-0-works-characterizing-and-scoring-vulnerabilities), [isMalicious: CVSS 4.0 explained](https://ismalicious.com/posts/cvss-4-vulnerability-scoring-explained-2026).

**Adoption.** Vendors that want threat and supplemental metrics adopt 4.0; most platforms still record 3.1. harden-ready's finding template supports both; record whichever your workflow uses, or both.

### EPSS + KEV composite

**EPSS.** Daily-updated probability (0.0 to 1.0) that a vulnerability will be exploited in the next 30 days. EPSS v4 (March 2025) is current. [FIRST.org EPSS](https://www.first.org/epss/), [Intruder: EPSS vs CVSS](https://www.intruder.io/blog/epss-vs-cvss), [NVD: vulnerability metrics](https://nvd.nist.gov/vuln-metrics/cvss), [Cloudsmith: CVSS vs EPSS](https://cloudsmith.com/blog/vulnerability-scoring-systems).

**CISA KEV.** Binary: confirmed exploited in the wild. [CISA KEV catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog).

**The composite.** 28% of exploited vulnerabilities in Q1 2025 had only "medium" CVSS base scores [Picus: vulnerability prioritization](https://www.picussecurity.com/resource/blog/vulnerability-prioritization-why-cvss-isnt-enough). Use CVSS + EPSS + KEV together; prioritize KEV = Yes regardless of CVSS.

### Internal severity mapping

Most programs publish a five-point scale:

- **Critical.** CVSS 9.0+ OR confirmed KEV OR business impact "full data loss or admin bypass."
- **High.** CVSS 7.0-8.9 OR business impact "partial data loss or significant privilege escalation."
- **Medium.** CVSS 4.0-6.9 OR exploitation requires user interaction.
- **Low.** CVSS 0.1-3.9 OR defense-in-depth concerns.
- **Informational.** No direct exploitation path.

## Triage SLA

### Stages and timings

1. **Intake.** Email, form, platform. **Acknowledged within 48 hours.**
2. **Validation.** Reproduced or dismissed. **Within 5 business days.**
3. **Severity assignment.** CVSS + internal weighting. **Within validation.**
4. **Owner assignment.** Engineering team. **Within severity assignment.**
5. **Fix and retest.** Engineering ships; security verifies. **Time bounded by severity.**
6. **Reporter coordination.** Keep reporter informed; bounty if applicable. **Throughout.**
7. **Public disclosure.** After fix + grace period. **Per disclosure timeline.**

### Fix SLA by severity

- **Critical.** 7 days from validation to fix (KEV: 24-72 hours).
- **High.** 30 days.
- **Medium.** 90 days.
- **Low.** 180 days or next scheduled release.

## Coordinated disclosure timelines

Pick one as the policy default; explain exceptions.

- **Google Project Zero: 90+30.** 90 days to patch from notification; 30 additional days post-patch before public disclosure; shortened to 7+30 if actively exploited. 97.7% of Project Zero's reported vulnerabilities fixed within the 90-day window [Project Zero: Vulnerability Disclosure FAQ](https://projectzero.google/vulnerability-disclosure-faq.html), [Project Zero: Policy 2020 Edition](https://googleprojectzero.blogspot.com/2020/01/policy-and-disclosure-2020-edition.html).
- **CERT/CC: 45 days.** Coordinated disclosure default. Conservative benchmark.
- **ZDI: 120 days.** [ZDI Disclosure Policy](https://www.zerodayinitiative.com/advisories/disclosure_policy/).
- **CISA KEV-driven.** US federal agencies have specific deadlines (typically 14-30 days) for KEV-listed vulnerabilities.

**Recommended default for most startups.** 90 days (Project Zero default). Shorter if actively exploited.

## Triage workflow

### Who reads the inbox

A named human, not "security@." The alias forwards to a person on rotation; the person acknowledges within 48h. If rotation is planned (vacation, on-call), coverage is named in the schedule.

The Lovable case: reports went to an email address; nobody owned the alias. 48-day gap.

### Validation protocol

Reproduce the reported bug. If unreproducible, ask the reporter for clarification; do not dismiss. If the report is in scope, assign severity; if out of scope, respond with scope reference.

### Escalation

For Critical or KEV findings: page the on-call security-engineer within 1 hour of validation. Bypass normal business hours.

### Reporter relationship

- Acknowledge every report.
- Provide a reference ID.
- Give status updates on the triage-SLA cadence.
- Coordinate on disclosure timing; the reporter is a partner, not an adversary.
- Credit the reporter in the hall of fame (with consent) on public disclosure.
- Pay the bounty (if applicable) before the reporter asks.

### CVE assignment

For a vulnerability reusable across similar deployments (a framework bug, a library bug, a widely-duplicated pattern), assign a CVE via a CNA (CVE Numbering Authority) or GitHub Security Advisories. harden-ready names this step when the finding crosses the "this is a class" threshold.

### Public disclosure

On the agreed timeline: publish an advisory with CVE (if assigned), severity, affected versions, reproduction (sanitized), mitigation. Publish to the company blog, the CVE database, and send to relevant aggregators (oss-security mailing list, ISAC if applicable).

## Bounty economics

Data: HackerOne 2024-2025. [Bleeping Computer: HackerOne $81M](https://www.bleepingcomputer.com/news/security/hackerone-paid-81-million-in-bug-bounties-over-the-past-year/), [TechLogHub: bounty trends 2025](https://techloghub.com/blog/hackerone-bug-bounties-81-million-year-in-review-2025), [Cybersecurity Ventures: HackerOne's largest program](https://cybersecurityventures.com/hackerones-largest-bug-bounty-program-boasts-300-hackers-2m-in-rewards/).

### Market-level numbers

- $81M paid across ~1,950 programs in 12 months ending mid-2025 (13% YoY).
- Average annual payout per active program: ~$42K (mean; median is lower).
- Top 100 programs: $51M collectively.
- Top 10 programs: $21.6M (~$2M+ per program annually).

### Severity distribution (typical program)

| Severity | Share of findings | Typical payout |
|---|---|---|
| Critical | 3-7% | $5,000 - $50,000+ |
| High | 10-15% | $1,000 - $10,000 |
| Medium | 25-35% | $250 - $2,500 |
| Low | 30-40% | $100 - $500 |
| Informational/dupe | 15-25% | $0 |

Top-tier programs (Google, Microsoft, Meta) pay substantially above average.

### AI-specific trends

- 1,121 programs included AI in scope in 2025 (270% YoY growth).
- Prompt-injection findings: 540% YoY growth.
- Autonomous-AI researchers: 560+ valid submissions in 2025.

[HackerOne: AI vulnerability reports 210% spike](https://www.hackerone.com/press-release/hackerone-report-finds-210-spike-ai-vulnerability-reports-amid-rise-ai-autonomy).

### When a program pays off

**Ready indicators.**
- VDP in place for 3-6 months without being overwhelmed.
- Triage capacity: at minimum 0.5 engineer-FTE dedicated.
- Internal appsec maturity: can ship Critical in under 7 days.
- Scope definable in writing.
- Legal signoff on safe-harbor language.

**Not-ready indicators.**
- No one owns triage.
- Backlog of known-but-unfixed findings.
- Cannot patch Critical in under a week.
- No public-facing app (nothing to test).

### When a program becomes noise

- Scope too broad ("everything" invites auto-scanner-generated low-quality reports).
- No triage SLA bounds: researchers spam when unresponded.
- Payout below market: motivated researchers go elsewhere.
- Poor triage signal-to-noise (inexperienced triage mis-labels criticals as duplicates).

The 95%-quit-rate figure [System Weakness: Why 95% of bug bounty hunters quit](https://systemweakness.com/why-95-of-bug-bounty-hunters-quit-and-how-the-5-actually-make-money-730863b854d5) reflects researcher churn, but also signals that most programs do not attract persistent researcher attention.

### VDP vs private vs public

| Type | Cost | Signal | Risk |
|---|---|---|---|
| **VDP** (security.txt + policy, no payouts) | Low | Low-to-medium | Controllable; swarm risk if high-profile |
| **Private bounty** (invite-only) | Medium | High | Low; triage-scoped |
| **Public bounty** | Medium-to-high | Highest | High; swarm risk real |

**Recommendation.** Start with a real VDP (security.txt + SECURITY.md + policy + triage SLA + safe harbor + severity vocabulary). Operate 3-6 months. If triage capacity and fix velocity are healthy, consider a private program on HackerOne or Bugcrowd. Public programs are later-stage.

### Stage-appropriate posture

| Stage | Posture |
|---|---|
| Pre-launch (no users) | VDP ready in repo; no program open |
| Post-launch, <1K users | VDP active; SECURITY.md real; triage SLA documented |
| Series A | Private program on HackerOne/Bugcrowd |
| Series B+ | Public program |
| Late-stage / enterprise | Public program + annual pen test + continuous bug bounty |

## The `.harden-ready/DISCLOSURE.md` artifact

Record the program's state:

```markdown
# Disclosure Program

## Public policy URL
https://example.com/security/policy

## security.txt
Served at /.well-known/security.txt. Last refreshed: 2026-04-22. Next Expires: 2027-04-22.

## Triage owner
Jamie Chen (jamie@example.com). Backup: Alex Kim.

## SLA
- Acknowledgment: 48h.
- Validation: 5 business days.
- Fix: Critical 7d, High 30d, Medium 90d, Low 180d.
- Public disclosure: 90 days after fix (Project Zero default).

## Severity vocabulary
CVSS 3.1 (primary) + EPSS + KEV composite. Internal mapping per policy.

## Safe harbor
disclose.io Open Source Terms, adapted 2026-02-15.

## Program type
VDP; operating since 2026-01-15.
Transition plan: evaluate private bounty at 1000 users or 6 months (whichever first).

## Metrics (last 90 days)
- Reports received: 12
- Valid reports: 5
- Duplicates: 4
- Out of scope: 3
- Average acknowledgment time: 14 hours
- Average fix time (Critical): 5 days
- Average fix time (High): 21 days

## Hall of fame
- [Researcher name] for finding F-07 (disclosed 2026-03-15)
```

## Test the program before declaring it live

Before telling researchers the program is open:

1. **Send a test report** to the contact alias. Verify it reaches the triage owner.
2. **Reply within SLA.** Verify acknowledgment within 48 hours.
3. **Triage through the full workflow** on a contrived internal finding.
4. **Publish a sample hall-of-fame entry** (yourself or a colleague with consent).
5. **Verify the policy URL** is readable, not Lorem Ipsum.
6. **Run security.txt through a validator** ([securitytxt.org validator](https://securitytxt.org/)).

If any step fails, the program is not live; it is a façade. Researchers will bypass it within a month.

## The have-nots

Refuse the program as "live" if any of these is true:

- **No named triage owner.** security@ forwards to "nobody owns it." The Lovable pattern.
- **No published SLA.** Researchers cannot tell when they should escalate.
- **No safe-harbor language.** Researchers legally at risk; responsible ones decline.
- **security.txt missing, expired, or invalid.** RFC 9116 compliance is the floor.
- **No test-report verification.** The inbox might be silently broken.
- **Public bounty with no triager.** Guaranteed to become noise within 90 days.
- **Scope "everything."** Auto-scanner reports will swamp.
- **Severity vocabulary missing.** Researchers and triage disagree on what "critical" means.
- **Program advertised on landing page but not operational.** The first researcher email goes nowhere; the bad publicity is in a screenshot on Twitter within a week.
