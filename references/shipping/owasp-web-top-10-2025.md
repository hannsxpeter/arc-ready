# OWASP Web Top 10:2025 Walkthrough Router

This is the authoritative web-risk order for current hardening work. OWASP published the 2025 list as the current released edition. Use the detailed manual procedures in `owasp-walkthrough.md` through the mappings below, then write one evidence row per 2025 category to `.harden-ready/FINDINGS.md`.

| Current category | Manual test route | 2025-specific requirement |
|---|---|---|
| A01:2025 Broken Access Control | `owasp-walkthrough.md`, A01:2021 and A10:2021 | Test object and function authorization plus SSRF and internal-resource access. SSRF moved into this category. |
| A02:2025 Security Misconfiguration | `owasp-walkthrough.md`, A05:2021 | Include application, framework, cloud, CORS, error, default, and debug configuration. |
| A03:2025 Software Supply Chain Failures | `owasp-walkthrough.md`, A06:2021 | Expand beyond vulnerable versions to dependency provenance, build systems, CI identities, artifact signing, package substitution, and distribution integrity. |
| A04:2025 Cryptographic Failures | `owasp-walkthrough.md`, A02:2021 | Verify current algorithms, key lifecycle, nonce or IV handling, password hashing, and transport policy. |
| A05:2025 Injection | `owasp-walkthrough.md`, A03:2021 | Trace untrusted input through every interpreter and output context. |
| A06:2025 Insecure Design | `owasp-walkthrough.md`, A04:2021 | Verify threat models, abuse cases, rate limits, step-up controls, and secure defaults against the deployed design. |
| A07:2025 Authentication Failures | `owasp-walkthrough.md`, A07:2021 | Verify credential, session, MFA, recovery, token, rotation, revocation, and throttling behavior. |
| A08:2025 Software or Data Integrity Failures | `owasp-walkthrough.md`, A08:2021 | Verify trust boundaries and integrity checks for code, software, data, updates, and serialized content. |
| A09:2025 Security Logging and Alerting Failures | `owasp-walkthrough.md`, A09:2021 | Do not pass on logging alone. Exercise detection, alert delivery, ownership, and response. |
| A10:2025 Mishandling of Exceptional Conditions | New procedure below | Test fail-open paths, abnormal transitions, resource exhaustion, partial operations, rollback, and recovery. |

## A10:2025 manual procedure

Inventory each external dependency, state transition, asynchronous job, transaction boundary, parser, and resource limit. Exercise at least these conditions where applicable:

1. Timeout, connection reset, malformed response, and dependency unavailability.
2. Partial success across a multi-step write, including retry and duplicate delivery.
3. Disk, memory, queue, connection-pool, file-descriptor, and request-size exhaustion.
4. Unexpected enum values, nulls, empty collections, oversized values, and invalid state transitions.
5. Authorization, policy, or validation dependency failure.
6. Rollback failure and recovery from a restart between steps.

Record the exact request, fault injection, or reproduction procedure. A pass requires secure failure, bounded resource use, no unauthorized state transition, no sensitive error leakage, idempotent or compensating recovery where required, and an observable alert for operator action. A catch-all exception that returns success, silently drops work, or bypasses a control is a finding.

## Completion evidence

The web walkthrough passes only when all ten 2025 rows have a reproducible manual test, result, and finding link or justified Not Applicable status. Scanner output alone cannot satisfy a row. Use [OWASP Top 10:2025](https://owasp.org/Top10/2025/) as the category authority and verify that link before a release when standards freshness is material.
