# Security policy

## Reporting a vulnerability

Report security vulnerabilities **privately**, not via public issues or pull requests. Two channels, in order of preference:

1. **GitHub Security Advisories** at the repository's `Security` tab. Click "Report a vulnerability." This is the canonical path; the report goes directly to the maintainer, stays private until disclosure, and produces a CVE if applicable.
2. **Email** to `hprincivil@gmail.com` with subject line `SECURITY: arc-ready` and a clear description of the issue, reproduction steps, and any proposed mitigation.

Expect an acknowledgment within **3 business days**. Disclosure timelines depend on severity:

- **Critical** (remote code execution, data exfiltration, auth bypass): triaged within 24 hours; fix targeted within 7 days; coordinated public disclosure after fix lands.
- **High** (escalation, sensitive-data exposure): triaged within 3 days; fix targeted within 14 days.
- **Medium / Low**: triaged within 7 days; fix scheduled per the project's release cadence.

This skill is **markdown-only content** (a `SKILL.md` file plus references and a Bash lint script). The realistic security surface is small: prompt-injection attacks against an agent that loads the file, supply-chain risk if the repository is tampered with, or a malicious PR that introduces hidden instructions. The reporting channels above cover all three.

## Supported versions

The skill follows semantic versioning. Security fixes land on the latest minor release; older minors do not receive backports. Users are encouraged to track the latest release via the `hannsxpeter/arc-ready/releases` feed.

## Known non-issues

The skill is documentation plus a Bash lint script; it does not execute code at runtime, store secrets, or process user data. Reports about "no encryption at rest" or "no rate limiting" are misdirected; this is a static markdown repository.

## Predecessor

arc-ready is the consolidated successor to the eleven-skill hannsxpeter/ready-suite. Vulnerabilities affecting both arc-ready and the predecessor suite should be reported here; the maintainer will coordinate disclosure across both.

If a report affects emitted Pillars agent memory (`AGENTS.md` or `agents/*.md`) in a way that could steer agents toward unsafe behavior, treat it as in scope. Include the generated files and the source arc artifacts that informed them.
