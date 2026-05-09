# Handoff protocols: per-harness invocation patterns

This file specifies how kickoff-ready hands off to a sibling on each major harness. The handoff has two shapes: programmatic (the harness exposes a Skill tool that kickoff-ready can invoke directly) and guidance-text (the harness has no Skill tool; kickoff-ready surfaces an instruction string the user copies to the next prompt).

Loaded at SKILL.md Steps 0, 3, 4, and 5. The harness landscape research is in `references/RESEARCH-2026-04.md` Section 4.

## Detection: which harness is running

kickoff-ready cannot ask the harness directly. It infers from environmental signals:

| Signal | Likely harness |
|---|---|
| `CLAUDE_SESSION_ID` env or `${CLAUDE_SKILL_DIR}` placeholder works | Claude Code |
| Codex-style `$skill-name` invocation worked previously this session | OpenAI Codex CLI |
| Antigravity Skills Directory paths or `agentskills.io` references in the user's setup | Antigravity |
| `.cursor/`, `.cursorrules`, or notepads in the working directory | Cursor |
| `.windsurf/` directory or workflow files | Windsurf |
| No file system, single-conversation interface | Generic chat frontend (chat.openai.com, claude.ai) |

When detection is ambiguous, ask the user: "Which harness are you in: Claude Code, Codex, Cursor, Windsurf, Antigravity, or a chat-only interface?" Record the answer in PROGRESS.md frontmatter `harness:` field.

## Claude Code

Programmatic handoff is supported.

### Invocation form

Skills are invoked via slash command in chat: `/skill-name <args>`. From within kickoff-ready, the orchestrator emits the slash command into the conversation; the harness routes the command to the named skill.

The Skill tool in Claude Code 2026 supports nested invocation. Per `references/RESEARCH-2026-04.md` Section 4.1, the `claude_code.skill_activated` OpenTelemetry event carries `invocation_trigger=nested-skill` for skills invoked from within other skills.

### Pattern

After verifying upstream artifacts exist and updating PROGRESS.md to mark the next step `in-flight`:

```
[kickoff-ready writes a short status update]

Invoking prd-ready now. PROGRESS.md row 1 is in-flight. I will return when
.prd-ready/PRD.md exists and verifies.

/prd-ready <one-line project intent quoted from PROGRESS.md>
```

The harness picks up the slash command and routes to prd-ready. prd-ready runs its own workflow. When it returns (the user types something kickoff-ready interprets as "prd-ready done"), kickoff-ready reads PROGRESS.md, runs the post-invocation checks, and either marks the row `done` or `failed`.

### Caveat: forked subagents do not nest

From the Claude Code Skills docs: "subagents cannot nest, as a skill running in a forked subagent cannot spawn another subagent." kickoff-ready must not declare `context: fork` in its own frontmatter if it intends to invoke siblings. The orchestrator runs in the main context; each invoked sibling is a regular skill load.

### Failure modes

- **Skill not installed.** The slash command fails. kickoff-ready surfaces the install instruction (sibling's GitHub URL) and pauses the chain. PROGRESS.md status remains `pending` for the un-invokable sibling.
- **Permission denied.** `.claude/settings.json` denies `Skill(prd-ready *)`. kickoff-ready surfaces a clean error: "Claude Code permissions deny invoking prd-ready. Update your `.claude/settings.json` allowlist or invoke prd-ready manually outside this session."
- **Skill description budget exceeded.** With many skills installed, descriptions get truncated to fit the 1% / 8000-char budget. kickoff-ready's description has its key use case in the first sentence.
- **Circular invocation.** Not protected. kickoff-ready must not invoke itself. The static check at Step 0 verifies the next-step sibling is not `kickoff-ready`.

## OpenAI Codex CLI

Programmatic handoff is supported with a different invocation form.

### Invocation form

Skills in Codex are invoked via `$skill-name <args>` (dollar-sign instead of slash). Per `references/RESEARCH-2026-04.md` Section 4.2, the form is documented at developers.openai.com/codex/skills. Slash commands (`/review`, `/fork`) are a separate facility for specialized workflows.

### Pattern

```
Invoking prd-ready now. PROGRESS.md row 1 is in-flight.

$prd-ready <one-line project intent>
```

### Caveat: nested invocation undocumented

The Codex docs as of May 2026 do not explicitly document skill-to-skill invocation. The form is invocable from any context including inside another skill, but the failure modes are unspecified. kickoff-ready treats Codex as supporting nested invocation in practice but emits the command as text the agent or user can act on, rather than relying on a programmatic spawn.

### AGENTS.md

`AGENTS.md` is the cross-tool agent brief read natively by Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and others, per the [agents.md open standard](https://agents.md/) (governed by the Linux Foundation's Agentic AI Foundation). On Claude Code the equivalent is `CLAUDE.md`; many teams symlink `CLAUDE.md` -> `AGENTS.md` to avoid drift.

kickoff-ready emits a minimal `AGENTS.md` at project root in Step 6 sub-step 6a if none exists, scoped to artifact metadata only (the per-sibling artifact map). It does not write stack, commands, conventions, or forbidden actions; those belong to repo-ready or to the user. If `AGENTS.md` exists, kickoff-ready records `existing-respected` in PROGRESS.md and does not touch the file. See [`references/agents-md-template.md`](agents-md-template.md) for the template, the substitution rules, and the kickoff-ready / repo-ready handshake on a shared file.

On chat-only harnesses (no file system), kickoff-ready surfaces the template as a guidance string for the user to paste, instead of writing.

## Antigravity

Programmatic handoff is supported via the Agent Skills open standard (agentskills.io). The invocation form is per-harness; consult Antigravity's docs.

kickoff-ready behaves identically to Claude Code on Antigravity in practice: emit the invocation, wait for the sibling's artifact to appear on disk, verify, advance.

## Cursor

No programmatic Skill tool. Cursor has notepads and `.cursorrules`, both of which are context-injection mechanisms, not invocation mechanisms. kickoff-ready operates in **guidance-text mode** on Cursor.

### Pattern

```
[kickoff-ready writes the guidance string]

The next step is to run prd-ready. Cursor does not support programmatic skill
invocation, so please:

1. Open prd-ready's SKILL.md (path: ~/.cursor/skills/prd-ready/SKILL.md if you
   installed via the recommended symlink, or wherever you installed it).
2. Start a new chat with Cursor.
3. Paste the SKILL.md contents into the system prompt or invoke via
   .cursorrules pattern.
4. Provide the project intent: "<intent quoted from PROGRESS.md>"
5. When prd-ready writes .prd-ready/PRD.md and you have verified it,
   return to this kickoff-ready session.

PROGRESS.md row 1 is now `in-flight`. I will pick up when you confirm prd-ready
is done.
```

The user runs prd-ready in a separate Cursor chat. kickoff-ready's session waits.

### Practical reality on Cursor

The user typically opens two Cursor windows: one running kickoff-ready, one running the active sibling. PROGRESS.md (in the working directory) is shared. kickoff-ready's resume protocol re-reads PROGRESS.md every turn, so the wait is trivially handled.

## Windsurf

No programmatic Skill tool. Windsurf has workflows in `.windsurf/` and global rules. Same posture as Cursor: kickoff-ready operates in guidance-text mode.

The Windsurf-specific note: workflows are reusable prompts. A user can wrap a sibling's SKILL.md as a Windsurf workflow and invoke it via the workflow runner. kickoff-ready can suggest this pattern but does not author the workflow file.

## Generic chat frontends (chat.openai.com, claude.ai)

No file system. No `.kickoff-ready/PROGRESS.md` possible. kickoff-ready operates in **degraded mode**.

### Pattern

PROGRESS.md exists only inside the conversation as a markdown block the user copies between sessions. The kickoff-ready turn produces:

1. A markdown block tagged `<!-- PROGRESS.md -->` containing the current ledger.
2. The guidance string for the next sibling.
3. An instruction to the user: "Open a new conversation, paste prd-ready's SKILL.md, run it, and paste its output back here. I will update PROGRESS.md and continue."

This is genuinely degraded. The user's resume across sessions requires them to copy PROGRESS.md back. There is no artifact-existence check possible (no file system); the verification gate degrades to "the user pastes the artifact back and kickoff-ready reads it."

### Honesty rule

kickoff-ready is explicit on chat-only frontends: "This harness has no file system. PROGRESS.md is in this conversation only. If you close this tab, the kickoff state is lost. For a multi-day kickoff, install Claude Code, Codex, Cursor, or Windsurf and run kickoff-ready there."

## Verification gate (harness-independent)

After every sibling invocation, regardless of harness:

1. **Programmatic harness (Claude Code, Codex, Antigravity).** Read the declared artifact path. Check exists and non-empty. Compute disk_state_hash (file mtime). Update PROGRESS.md row.
2. **Guidance-text harness (Cursor, Windsurf).** Same as above. PROGRESS.md is in the working directory; the verification is a file read.
3. **Chat-only harness.** The user pastes the artifact back. kickoff-ready treats the pasted content as the artifact for verification purposes; the file does not exist on disk because there is no disk.

The two-check verification (exists, non-empty) is invariant. Only the read mechanism varies.

## Skill not installed: graceful failure

If kickoff-ready reaches a step where the next sibling is not installed:

1. **Detect.** The Skill tool errors (Claude Code, Codex, Antigravity), or the user reports the sibling is not on disk (Cursor, Windsurf), or the user does not have access (chat-only).
2. **Surface install instructions.** Each sibling has a GitHub URL: https://github.com/aihxp/<sibling-name>. The recommended install on Claude Code is symlinking the dev copy:
   ```bash
   ln -s ~/Projects/<sibling-name> ~/.claude/skills/<sibling-name>
   ```
   On Codex and Antigravity, equivalent symlink paths.
3. **Pause.** PROGRESS.md row stays `pending`. kickoff-ready does not advance.
4. **Resume on user signal.** The user installs the sibling and tells kickoff-ready to continue. kickoff-ready re-runs Step 0 (harness and install detection), confirms the sibling is now available, and proceeds.

## Skip-via-guidance: when a harness cannot do the handoff

A user on chat-only frontends or a Cursor / Windsurf user without access to the sibling skill files might choose to skip a sibling rather than install. kickoff-ready respects the choice:

1. The user declares the skip in PROGRESS.md (Step 2 declaration or mid-arc declaration).
2. kickoff-ready records the skip with reason.
3. The skip cascade rules from `references/sequencing-rules.md` apply.

This is the explicit-skip path. No silent failure.

## On-disk handoff (orchestrator-agnostic baseline)

The deepest handoff pattern in the ready-suite is on-disk, not in-conversation. Every sibling reads upstream artifacts from `.{skill}-ready/` directories on disk. The Skill-tool invocation is a convenience; the artifact-on-disk handoff is the contract.

This means kickoff-ready works even when the harness has no Skill tool at all. The user manually invokes each sibling (in any harness, in any tool, with any prompt); kickoff-ready's PROGRESS.md tracks which artifacts have appeared on disk and verifies them. This is the most degraded mode but is fully functional.

For full automation, use Claude Code, Codex, or Antigravity. For semi-automated, use Cursor or Windsurf with one window per sibling. For zero-automation, use any harness and let kickoff-ready be the audit ledger only.

## Composition with phase orchestrators

kickoff-ready ends when the kickoff arc completes. Ongoing phase / milestone work is a different orchestration pattern. kickoff-ready hands off explicitly:

1. **Step 6 produces the handoff block.** "Recommended next-step orchestrator: GSD" (or BMAD, or the user's own process).
2. **PROGRESS.md remains.** The next orchestrator reads PROGRESS.md to understand what was kicked off. Per production-ready/ORCHESTRATORS.md, GSD's `/gsd-new-project` is the canonical follow-on.
3. **The siblings continue without kickoff-ready.** kickoff-ready exits the chain. Each sibling can be re-invoked directly later (a roadmap revision, a new architecture decision, a hardening pass) without going through kickoff-ready again.

The composition is one-way: kickoff-ready knows about the suite, hands off to phase orchestrators, and gets out of the way. Phase orchestrators do not call kickoff-ready back.

## Per-harness summary table

| Harness | Skill tool | Invocation form | kickoff-ready mode | Verification source |
|---|---|---|---|---|
| Claude Code | Yes | `/skill-name args` | Programmatic; nested-skill supported | File system |
| Codex CLI | Yes | `$skill-name args` | Programmatic; nested-skill undocumented but works | File system |
| Antigravity | Yes (Agent Skills standard) | Per-harness (similar to Claude Code) | Programmatic | File system |
| Cursor | No | Manual (notepads, .cursorrules) | Guidance-text; user runs siblings in separate windows | File system |
| Windsurf | No | Manual (workflows, global rules) | Guidance-text; user runs siblings in separate windows | File system |
| chat.openai.com | No | None | Degraded; PROGRESS.md is in conversation | Pasted-back content |
| claude.ai | No | None | Degraded; PROGRESS.md is in conversation | Pasted-back content |

## Summary

Programmatic handoff is fastest. Guidance-text handoff is the universal fallback. On-disk artifact verification is invariant. The user's harness choice changes only the invocation mechanism; the contract (each sibling produces its declared artifact at its declared path; kickoff-ready verifies and advances) is the same everywhere.
