# Guided: repo (tier 2.1)

Scaffold only what this stack and stage need, then record it in `.repo-ready/SCAFFOLD.md`.

~~~markdown
# Scaffold

Stack: {{from .stack-ready/STACK.md}}
Created: {{files and folders, one line each with why}}
Skipped on purpose: {{files a bigger project would have, and why not yet}}
CI: {{workflow path}} runs {{lint, test, build}}; it passed on a fresh clone on {{date}}.
~~~

Checklist:

1. `README.md` says what this project does, how to install it, and how to run it. No template text.
2. CI configuration exists and passes on a fresh clone.
3. `LICENSE` and `SECURITY.md` exist for public code.
4. Run `arc-check.sh pillars`, then fill `agents/context.md` from the PRD and `agents/repo.md` from the scaffold, citing each source path.
5. `arc-check.sh gate 2.1` passes.
