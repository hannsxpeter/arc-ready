# Security policy

## Reporting a vulnerability

Report security vulnerabilities **privately**, not via public issues or pull requests. Two channels, in order of preference:

1. **GitHub Security Advisories** at the repository's `Security` tab. Click "Report a vulnerability." This is the canonical path; the report goes directly to the maintainer, stays private until disclosure, and produces a CVE if applicable.
2. **Email** to `hannsxpeter@gmail.com` with subject line `SECURITY: arc-ready` and a clear description of the issue, reproduction steps, and any proposed mitigation.

Expect an acknowledgment within **3 business days**. Disclosure timelines depend on severity:

- **Critical** (remote code execution, data exfiltration, auth bypass): triaged within 24 hours; fix targeted within 7 days; coordinated public disclosure after fix lands.
- **High** (escalation, sensitive-data exposure): triaged within 3 days; fix targeted within 14 days.
- **Medium / Low**: triaged within 7 days; fix scheduled per the project's release cadence.

## What runs

arc-ready is a `SKILL.md` file, ten optional guided skeletons, and one runtime script, `scripts/arc-check.sh`, which agents execute inside the user's project. The script:

- reads project files: the ledger, the tier artifacts, and source files for the placeholder scan;
- writes only `.arc-ready/PROGRESS.md`, `.launch-ready/PREPUBLICATION.md`, and, through `pillars`, `AGENTS.md`, a `CLAUDE.md` symlink, and `agents/context.md` and `agents/repo.md` when those are absent, plus its own short-lived files under `$TMPDIR`;
- never overwrites an existing `AGENTS.md`, never deletes files, makes no network calls, and never evaluates project content as code;
- records a risk acceptance (`accept`) only when run at an interactive terminal, so an agent running commands without one cannot record it. Each recorded line carries a `check:` digest, and `prepublish` ignores acceptance lines written or edited by hand. The digest is tamper evidence, not a signature: someone with write access to the project can forge it deliberately.

In scope: a way to make `arc-check.sh` execute attacker-controlled input, write outside the project directory, or pass a gate it should block (for example, a crafted findings file that lets `prepublish` pass with an unresolved Critical, or a way for an agent to record a risk acceptance without a person); prompt-injection text in `SKILL.md` or the guided skeletons; supply-chain tampering with the repository; and emitted `AGENTS.md` or `agents/*.md` content that could steer agents toward unsafe behavior. Include the ledger, the findings file, and the exact command you ran.

The evaluation harness under `evals/ablation/` is a maintainer tool that runs headless agents in disposable directories. It is not part of the installed skill's runtime path.

## Supported versions

Security fixes land on the latest release. Version 1.2.1 is frozen as the full reference library and receives no further changes.

## Known non-issues

The skill stores no secrets and processes no personal data. Reports about encryption at rest or rate limiting are misdirected; there is no service.

## Predecessor

arc-ready is the consolidated successor to the eleven-skill hannsxpeter/ready-suite. Vulnerabilities affecting both should be reported here; the maintainer will coordinate disclosure across both.
