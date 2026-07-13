# Harness Integration

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Per-harness integration

The arc spans sessions. arc-ready works across every Agent Skills compatible harness, with handoff details that vary by harness. The skill body is identical; the integration glue differs.

### Claude Code

Native invocation: `Skill arc-ready` or the slash form once registered. Resume protocol uses Claude Code's `Read` tool against `.arc-ready/PROGRESS.md`. AGENTS.md is consumed automatically (Claude Code respects the `AGENTS.md` standard via `CLAUDE.md` symlink). Long-running Tier 2.2 sessions benefit from `/compact` invocations between slices; resume re-derives state from disk per Step 0.2.

### Codex CLI

Native invocation: `$ arc-ready` (dollar-sign form). Codex respects the `AGENTS.md` standard directly without a symlink; `CLAUDE.md` is harmless but not required. Resume uses Codex's file-read tool against `.arc-ready/PROGRESS.md`.

### Cursor

No Skill tool. Surface the workflow as Cursor rules in `.cursor/rules/` referencing `SKILL.md` body. Resume is manual: the user opens `.arc-ready/PROGRESS.md` in Cursor and the AI reads it as context. Tier dispatch becomes guidance text.

### Windsurf

Similar to Cursor: no Skill tool; workflow surfaces via `.windsurfrules` referencing `SKILL.md`. Resume is manual.

### Antigravity

Native Agent Skills support per the Antigravity standard. Invocation form per the Antigravity docs.

### Pi / OpenClaw

Native Agent Skills support; invocation form per each tool's standard.

### Generic chat frontend (no file system)

arc-ready surfaces tier sub-step guidance as message blocks. The user copies the relevant artifact content into their own file system and reports back when each artifact is on disk. arc-ready cannot verify import or resume on a file-system-less frontend; the user is responsible for the verification.
