# Guided: harden (tier 3.4)

Write `.harden-ready/FINDINGS.md`. The script reads the `id:`, `severity:`, and `status:` lines, so keep them exactly like this.

~~~markdown
# Hardening findings

## OWASP Top 10 ({{edition}}) walkthrough

- A01 {{category}}: {{pass or finding id}}. Evidence: {{file, test, or request}}.
- {{one line for each of the ten categories}}

### {{C-1}}: {{title}}

id: {{C-1}}
severity: {{critical, high, medium, or low}}
status: {{open, fixed, or accepted}}
reproduction: {{exact steps or request}}
fix: {{change, and the class of bug it closes}}
retest: {{how it was verified, and when}}
~~~

Accepting a risk is the finding owner's decision, not yours. The owner runs `arc-check.sh accept <id> --owner <name> --expires <YYYY-MM-DD> --justification <why>` at a terminal. Never write or edit an acceptance line yourself. If a Critical finding is open, report it and what its owner must do, then stop.

Checklist:

1. Walk every category by hand. A scanner result is evidence, not a verdict.
2. Check the authentication and API boundaries directly.
3. `arc-check.sh gate 3.4` passes, and `arc-check.sh prepublish` passes before any public release.
