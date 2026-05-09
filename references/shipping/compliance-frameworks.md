# compliance-frameworks: control-to-code mapping for SOC 2, HIPAA, PCI-DSS, GDPR

Loaded at Tier 4 (Step 7). Mode B makes this step the anchor; other modes include it when an audit is in a twelve-month horizon.

This file is not legal advice. It is the engineering view: what each framework expects from the code and configuration, and the specific evidence artifacts an auditor will ask for. Every framework cites the primary source.

## The compliance-without-security trap

Every control in every framework can be checked off with a weakly-implemented version that passes audit and fails adversary. The cross-framework mapping (Section 5 below) shows that nine engineering controls dominate the overlap; those nine at adversarial depth cover most of the framework-specific residual. harden-ready's job is the adversarial verification on top of the check-box pass.

Examples of the trap:
- "Encryption at rest" passes when disk-level encryption is enabled. Adversary: SQL injection extracts unencrypted column data. Real control: column-level encryption for Restricted fields.
- "Access control" passes with an RBAC matrix. Adversary: BOLA on the front page. Real control: server-side authorization verified per object.
- "Audit logging" passes with log retention. Adversary: the logs are retained, never reviewed. Real control: logs are queried on cadence; alerts fire on anomalies.
- "Incident response" passes with a documented policy. Adversary: the policy is three years old, the on-call is different, nobody has run a tabletop. Real control: tabletop within the audit window.

## SOC 2 Trust Services Criteria

**Source.** AICPA Trust Services Criteria (2017, revised 2022). The full TSC is paywalled through AICPA; Secureframe, Drata, Vanta, and Tugboat Logic publish freely-available control matrices that map directly to the criteria.

### Scope

SOC 2 is an attestation framework. A CPA firm attests that the service organization's controls are (a) designed appropriately (Type I) or (b) designed and operating effectively over a period (Type II).

**Trust Services Categories.** Five, one required:

1. **Security** (Common Criteria, required).
2. **Availability** (optional).
3. **Processing Integrity** (optional).
4. **Confidentiality** (optional).
5. **Privacy** (optional).

Most engineering orgs audit Security (only) or Security + Availability. The Common Criteria (CC) is the core of Security and is organized into nine groups (CC1 - CC9).

### Type I vs Type II

| Type | Report covers | Observation period | Typical duration |
|---|---|---|---|
| Type I | Point in time: "as of date, controls designed appropriately" | Not applicable | 4-8 weeks readiness + 2-4 weeks audit |
| Type II | Observation period: "controls operating effectively over period" | 3 months minimum, typically 6-12 months | 3-4 months readiness + observation period + 2-4 months audit |

[ISMS.online: SOC 2 Type II timelines and evidence](https://www.isms.online/soc-2/type-2/), [Sprinto: SOC 2 Type II implementation timeline](https://sprinto.com/blog/soc-2-type-2-implementation-timeline-attestation/).

### Typical control count

Approximately 80 controls in scope for Security-only Type II audit. [Secureframe: SOC 2 controls list](https://secureframe.com/hub/soc-2/controls).

### Engineering control-to-code mapping

| CC / TSC | Engineering implementation | Evidence artifact |
|---|---|---|
| **CC1 Control Environment** | Written security policy; leadership signoff. | `docs/security-policy.md` with signed-off commit; board minutes with approval. |
| **CC2 Communication** | Onboarding checklist; annual security training. | HR record of training completion; onboarding-checklist template. |
| **CC3 Risk Assessment** | Threat model document; annual risk review. | `.architecture-ready/ARCH.md` threat model section; risk-review meeting minutes. |
| **CC4 Monitoring** | Observability stack; internal audit calendar. | `.observe-ready/SLOs.md`, `.observe-ready/alert-catalog.md`; audit calendar. |
| **CC5 Control Activities** | Separation of duties; least-privilege IAM; change management. | IAM role documentation; `CODEOWNERS` for security-sensitive paths; PR review policy. |
| **CC6.1 Logical Access** | SSO for employees; MFA enforced at IdP. | SSO config; IdP MFA enforcement policy; MFA-usage reports. |
| **CC6.2 User Provisioning** | IdP-group-based role assignment. | IdP group membership audit; onboarding runbook. |
| **CC6.3 User Termination** | Deprovisioning within 24h. | Offboarding runbook; deprovisioning-time metrics; exit checklist. |
| **CC6.4 Physical Access** | Cloud provider attestation. | AWS / GCP / Azure SOC 2 reports on file (inherited). |
| **CC6.6 Encryption at rest** | TDE plus column-level for Restricted. | DB configuration; column-encryption code file; `.harden-ready/CRYPTO-VERIFICATION.md`. |
| **CC6.7 Transmission security** | TLS 1.2+ in transit. | SSL Labs A+ screenshot; HSTS header; cert-renewal runbook. |
| **CC6.8 Malicious software** | EDR on employee devices; container scanning. | EDR management-console proof; Trivy / Grype CI logs. |
| **CC7.1 Anomaly detection** | Centralized logging; alerting. | `.observe-ready/alert-catalog.md`; SIEM / log-aggregator dashboard. |
| **CC7.2 Monitoring** | SLOs, SLIs, alert-to-pager. | Alert routing config; on-call schedule. |
| **CC7.3 Evaluation of events** | Incident response runbook; on-call. | `.observe-ready/incident-response.md`; PagerDuty rotation proof. |
| **CC7.4 Incident response** | IR plan in repo; tested annually. | Tabletop-exercise meeting notes, quarterly cadence. |
| **CC7.5 Recovery** | Backup + tested restore. | Last successful restore test date; restore-test runbook. |
| **CC8.1 Change management** | PR review; CI gates; deploy pipeline. | Branch protection rules; PR templates; `.deploy-ready/` pipeline-as-code. |
| **CC9.1 Vendor risk** | Vendor review SOP; DPA and SOC 2 for subprocessors. | Vendor inventory; subprocessor SOC 2 reports on file. |
| **CC9.2 Vendor selection** | Documented selection criteria. | Vendor selection checklist; SOC 2 report review note per subprocessor. |

### Common pre-audit findings

[Drata: SOC 2 Type 2 guide](https://drata.com/grc-central/soc-2/type-2), [Complyjet: SOC 2 controls founder guide](https://www.complyjet.com/blog/soc-2-controls).

1. Missing or stale policies (written once, never reviewed).
2. Access reviews not performed at documented frequency.
3. Terminated users still have access (offboarding gap).
4. No evidence of backup-restore test within the audit window.
5. IR plan exists but no tabletop in the audit window.
6. Vendor inventory incomplete.
7. Change-management exceptions without documented approval.
8. Production data used in dev/test without masking.

### The SOC 2 compliance-without-security trap

Every CC6 and CC7 control can pass while the application has IDOR on its main API. The auditor tests controls (access reviews, MFA configured, backups restored) and not the application code. harden-ready's adversarial review catches what the auditor's checklist will not.

## HIPAA 164.312 Technical Safeguards

**Source.** [45 CFR 164.312 (Cornell LII)](https://www.law.cornell.edu/cfr/text/45/164.312), [HHS Security Series #4: Technical Safeguards (PDF)](https://www.hhs.gov/sites/default/files/ocr/privacy/hipaa/administrative/securityrule/techsafeguards.pdf).

### Five standards

| Standard | Specification | Req / Addressable | Engineering implementation |
|---|---|---|---|
| **164.312(a)(1) Access Control** | Unique User Identification | Required | Per-user accounts; no shared ePHI-accessing accounts. |
| | Emergency Access Procedure | Required | Break-glass account with auditing; runbook. |
| | Automatic Logoff | Addressable | Session timeout on ePHI UIs. |
| | Encryption / Decryption | Addressable | Column-level encryption for ePHI at rest. |
| **164.312(b) Audit Controls** | Record and examine activity | Required | Application audit log; centralized logging; retention >= 6 years. |
| **164.312(c)(1) Integrity** | Protect ePHI from improper alteration | Required | Checksums or HMAC; append-only audit logs. |
| | Mechanism to Authenticate ePHI | Addressable | Signature on inter-service transfer. |
| **164.312(d) Person/Entity Authentication** | Verify identity | Required | MFA for ePHI access; strong authentication. |
| **164.312(e)(1) Transmission Security** | Guard in transit | Required | TLS 1.2+ for all ePHI in transit; private links server-to-server. |
| | Integrity Controls | Addressable | TLS plus application HMAC for high-value flows. |
| | Encryption | Addressable | TLS; end-to-end where appropriate. |

### Addressable vs Required

"Addressable" means implement a reasonable-and-appropriate control OR document in writing why an equivalent is in use. HHS has stated repeatedly that addressable is not optional; the documentation burden is higher if the control is not implemented.

### Common pre-audit findings

- Encryption at rest documented but not verified for all ePHI stores.
- Audit log retention under 6 years.
- Shared accounts in legacy systems touching ePHI.
- Session timeout not enforced.
- BAA (Business Associate Agreement) missing for subprocessors.
- Administrative safeguards (164.308) gaps alongside technical.

### Adjacent sections worth knowing

- **164.308 Administrative Safeguards.** Risk assessment, workforce training, sanction policy, access management procedures.
- **164.310 Physical Safeguards.** Facility access, workstation security. Largely inherited from cloud provider.
- **164.400 Breach Notification.** 60-day notification if breach affects >500 individuals.

## PCI-DSS v4.0 / v4.0.1

**Source.** [PCI Security Standards Council: PCI DSS v4.0.1 announcement](https://blog.pcisecuritystandards.org/just-published-pci-dss-v4-0-1), [Middlebury: PCI DSS v4.0.1 PDF](https://www.middlebury.edu/sites/default/files/2025-01/PCI-DSS-v4_0_1.pdf).

All v4.0 requirements mandatory as of March 31, 2025. Twelve principal requirements, 300+ sub-controls, 47 new in v4.0 vs v3.2.1.

### Twelve principal requirements

| # | Requirement | Engineering implementation |
|---|---|---|
| 1 | Network security controls | VPCs, security groups, WAF. |
| 2 | Secure configurations | CIS benchmarks; IaC with drift detection. |
| 3 | Protect stored account data | Tokenization preferred; if PAN stored, strong encryption + key mgmt. |
| 4 | Protect in transit | TLS 1.2+ (1.3 preferred); no cleartext over public networks. |
| 5 | Malware protection | EDR on servers; DMARC/SPF/DKIM for phishing (new 5.4.1). |
| 6 | Secure SDLC | SAST/SCA integrated; **6.4.1 requires automated technical solutions for public-facing web apps**. |
| 7 | Least-privilege access | IAM roles and policies. |
| 8 | Identify and authenticate users | **MFA required for ALL access to CDE systems (8.3.1)**, broadly expanded in v4.0. |
| 9 | Physical access | Cloud provider inherited. |
| 10 | Log and monitor | Centralized logging; 1-year retention with 3-months online; anomaly monitoring. |
| 11 | Regular testing | Quarterly vulnerability scans; annual pen test; segmentation testing. |
| 12 | Policies and procedures | Written policies; annual risk assessment; IR plan tested annually. |

### Notable v4.0 engineering impacts

The v4.0-vs-v3.2.1 deltas that most affect engineering:

- **MFA expanded beyond admins to cover all CDE users.** Every developer with production CDE access needs MFA.
- **Req 6.4.1.** Manual annual vulnerability assessment is no longer acceptable for public-facing web apps; must be automated (WAF or equivalent at 6.4.2).
- **Req 6.4.3 (Magecart).** Scripts loaded in the consumer's browser (payment pages) must have inventory, authorization, and integrity verification. The single most-disruptive v4.0 change for e-commerce.
- **Req 11.6.1.** Change-and-tamper detection for payment page scripts.
- **Req 8.3.10.1.** If passwords are the sole authentication factor, change at least every 90 days OR dynamic posture analysis.

### Common pre-audit findings

- Payment pages with third-party scripts lacking integrity verification (SRI).
- Logs collected but not actively monitored.
- MFA for admins, not for developers with production access.
- Segmentation testing missed the required cadence.

[Linford: PCI DSS 4.0 requirements 2025](https://linfordco.com/blog/pci-dss-4-0-requirements-guide/), [Secureframe: What is new in PCI DSS 4.0](https://secureframe.com/blog/pci-dss-4.0), [Varonis: PCI DSS 4.0 checklist](https://www.varonis.com/blog/pci-dss-requirements).

## GDPR Article 32

**Source.** [Article 32 GDPR](https://gdpr-info.eu/art-32-gdpr/), [ICO: guide to data security](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/security/a-guide-to-data-security/).

### Mandate

Appropriate technical and organizational measures ("TOMs") to ensure a level of security appropriate to the risk. The article names four examples without requiring them universally.

### Four examples, engineering view

| Art 32(1) example | Engineering implementation |
|---|---|
| (a) Pseudonymization and encryption | Column-level encryption for PII; reversible pseudonymization for analytics; tokenization for payment data. |
| (b) Ongoing CIA + resilience | CIA triad plus operational resilience (overlaps with observe-ready's SLOs). |
| (c) Ability to restore availability and access | Backup with tested restore; RPO/RTO measured. |
| (d) Regular testing, assessment, evaluation | Pen test cadence; internal audit; DPIA for high-risk processing. |

### Risk-based proportionality

GDPR does not prescribe specific controls. "State of the art" imports ENISA guidance, ISO 27001/27002 baselines, and member-state DPA guidance. Engineering orgs implementing ISO 27002 plus ICO checklist generally meet Art 32 for standard processing.

### Breach notification (Art 33)

Within 72 hours to the supervisory authority unless unlikely to result in risk. Drives incident response SLA. Notification to data subjects if high risk to rights and freedoms.

### Common Art 32 findings

- Personal data accessible to developers in production without documented necessity.
- No pseudonymization in analytics or QA datasets.
- Logs retaining raw PII beyond necessity.
- No DPIA for new high-risk processing (especially LLM-integrated features).

## Cross-framework mapping: the nine high-leverage controls

Many controls are the same control implemented once, mapped to multiple frameworks. The canonical overlap:

| Engineering control | SOC 2 | HIPAA | PCI 4.0 | GDPR Art 32 |
|---|---|---|---|---|
| Unique user IDs + MFA | CC6.1 | 164.312(a)(1), (d) | 8 | (a), (b) |
| Encryption at rest | CC6.6 | 164.312(a)(1) encryption specification | 3 | (a) |
| Encryption in transit | CC6.7 | 164.312(e)(1) | 4 | (a) |
| Centralized audit logging | CC7.1 | 164.312(b) | 10 | (b), (c) |
| Change management / SDLC | CC8.1 | (admin safeguards) | 6 | (b), (d) |
| Incident response | CC7.4 | (admin safeguards) | 12 | (d) + Art 33 |
| Backup + tested restore | CC7.5 | 164.308(a)(7) | 12 | (c) |
| Vulnerability scanning | CC7.1 | (addressable) | 11.3 | (d) |
| Pen test | CC7.1 | (addressable) | 11.4 | (d) |

**The trap.** The same nine items satisfy most of the frameworks at a control-design level without actually hardening the application. A SOC 2 Type II report describing these controls as "operating effectively" over a six-month observation period is consistent with an app that has a BOLA on its main API. harden-ready's adversarial review exists to close this gap.

## The `.harden-ready/COMPLIANCE.md` artifact

One row per in-scope framework per control. Template:

```markdown
# Compliance Mapping

## Framework: SOC 2 Type II Security (Common Criteria)
Observation period: 2026-06-01 to 2026-12-01
Auditor: [firm name]
Status as of: 2026-04-23

### CC6.1 Logical Access: authentication
**Framework language.** The entity implements logical access security software, infrastructure, and architectures over protected information assets to protect them from security events to meet the entity's objectives.

**Evidence.**
- SSO configured: Okta (okta.example.com).
- MFA enforced at IdP: Okta policy `require-mfa-all-users` (screenshot 2026-04-22).
- Application-layer MFA: `src/auth/mfa.ts` line 14 (mandatory for admin role).
- MFA enforcement config: `.production-ready/adr/007-mfa-policy.md`.

**Implementer.** @security-team.
**Last verified.** 2026-04-22 by @alice.
**Adversarial verification.** Tested authentication-bypass scenarios per `.harden-ready/AUTH-VERIFICATION.md`; no findings. Status: Pass.

### CC6.6 Logical Access: encryption
**Evidence.**
- Encryption at rest: AWS RDS TDE enabled (configuration: `infra/rds.tf` line 45).
- Column-level encryption for Restricted fields: `src/crypto/field-encrypt.ts`; applied to `users.ssn`, `users.dob`, `users.medical_notes`.
- Backup encryption: S3 bucket policy `backups-bucket-policy.json` enforces SSE-KMS.

**Implementer.** @platform-team.
**Last verified.** 2026-04-22 by @bob.
**Adversarial verification.** Column encryption verified; SQL injection test returned ciphertext, not plaintext. Status: Pass.

### CC7.5 Recovery: backup and restore
**Evidence.**
- Backup: automated daily via AWS Backup; retention 30 days hot, 1 year archive.
- Restore test: last performed 2026-03-15; runbook `.operations/restore-test.md`; result: successful RPO 6h, RTO 2h.
- Monitoring: backup-failure alert wired (observe-ready).

**Implementer.** @platform-team.
**Last verified.** 2026-03-15.
**Adversarial verification.** N/A (operational).

### ... (continuing per control)

## Framework: HIPAA 164.312
[One entry per standard/specification, same structure]

## Framework: PCI-DSS 4.0
[One entry per requirement, same structure]

## Framework: GDPR Article 32
[One entry per example + risk-based mapping]
```

## Audit-readiness signal

A compliance mapping is ready when a third party (an auditor unknown to the engineering team) can:

1. Pick any five random controls.
2. Navigate to the evidence artifact from the mapping alone.
3. Confirm the artifact demonstrates the control is in place and operating.
4. Ask a follow-up question that the engineering team answers from `.harden-ready/` artifacts, not ad-hoc search.

If any of those steps fails, the mapping is incomplete; the finding is "document the evidence path for control X."

## Common anti-patterns

- **Evidence by Slack screenshot.** A screenshot of a chat message confirming a policy is not evidence; it is an anecdote. Evidence is version-controlled or a system artifact (commit hash, CI log, IaC config, exported log).
- **Policy without enforcement.** A written policy that says "access reviews quarterly" with no tooling that forces the access review is a paper control.
- **Control copy-paste.** The same paragraph applied to SOC 2, HIPAA, and PCI without translation into each framework's language. Auditors detect this immediately.
- **Missing "when."** A control that exists today with no signal of when it was last verified or reviewed is stale on arrival.
- **Scope drift.** The SOC 2 audit covers `api.example.com`; the app also has `staging.example.com` and `internal.example.com` that an engineer mentioned during the interview. The auditor now has scope questions. Resolve before the audit.

## SOC 2 exceptions: the standard ones

SOC 2 Type II reports often include "exceptions" (controls not operating effectively during some sample). Common ones:

- One terminated user retained access for N days past termination.
- One quarter's access review was one week late.
- Backup-restore test was skipped in one quarter due to migration.

Exceptions are allowed; they reduce the report quality but do not fail the engagement. The skill notes exceptions with: what happened, when, remediation committed, future prevention. An auditor reading a clean report with no exceptions often suspects under-reporting; an auditor reading a report with documented exceptions plus remediation sees a healthy process.
