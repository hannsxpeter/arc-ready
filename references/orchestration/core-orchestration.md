# Core Orchestration

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Core principle: every artifact element is a decision, a hypothesis, or a named open question

The unifying discipline across the entire arc is one rule, applied tier by tier:

> **Every sentence in the PRD, every box and arrow and ADR in the architecture, every row on the roadmap, every score in the stack pick, every file in the repo, every feature in the app, every step in the deploy plan, every metric on the dashboard, every claim on the landing page, and every finding in the hardening report is exactly one of three things: a grounded decision with rationale, a flagged hypothesis with a validation plan, or a named open question with an owner and a due date. Anything that is none of the three is theater and must be rewritten or deleted.**

This principle is non-negotiable. The whole taxonomy of AI-slop output across the arc reduces to "elements that pretend to be decisions but are not." A hollow PRD is sentences without decisions. An invisible PRD is sentences that could describe any product in the category, which means they decide nothing specific. A feature laundry list is features listed without prioritization, which means the prioritization was never decided. A paper SLO is a number without an error budget, which means the threshold was never decided. A paper canary is a "canary" label without a stop rule, which means the canary mechanism was never decided. An AI-slop landing is a hero sentence that survives competitor substitution, which means the positioning was never decided. A scanner-only security pass is "zero criticals" without an adversarial read, which means the trust boundaries were never verified. The shape of the failure changes per tier; the load-bearing test does not.

**The substitution corollary.** For any user-facing sentence, any architectural element, any roadmap row, any stack rationale, any landing-page claim, substitute a near-equivalent (a competitor's name, a different framework, a different microservice topology). If the sentence still reads plausibly, the sentence decides nothing specific and fails the test. "Users want a faster way to manage their inbox" substitutes into any email product ever shipped. "Fed-up Gmail users who archive more than 200 messages per week and have at least three filters they rewrite monthly" does not. Specificity is the discipline. The substitution test runs at every tier gate; see `references/planning/prd-antipatterns.md` section 1 (PRD form), `references/planning/architecture-antipatterns.md` section 1 (architecture form), `references/shipping/launch-antipatterns.md` (landing-page form), and `references/shipping/harden-antipatterns.md` (security-claim form).

**The grounding corollary.** Every grounded commitment downstream of the PRD must reference an upstream artifact: a PRD section, an architecture component, a roadmap milestone, a stack ADR. An item with no upstream reference is speculative and must be either cut or routed back to the upstream tier for inclusion. This is the defense against AI-generated "reasonable-sounding" content that no upstream tier has actually decided.

**The artifact-on-disk corollary.** A tier is not done because the agent says it is done. A tier is done when the canonical artifact at `.<tier>-ready/<ARTIFACT>.md` exists, is non-empty, is not the unmodified template scaffold, and passes the tier's own have-nots check. The agent's claim is not authoritative; disk is. Every arc-ready turn begins with a re-derivation of state from disk, not from cached conversation memory.

## When arc-ready does and does NOT apply

arc-ready applies when the work is anywhere on the idea-to-launch arc for software:

- Producing or auditing a PRD, architecture, roadmap, or stack pick.
- Scaffolding a repository or building an end-to-end-wired application (dashboards, admin panels, internal tools, SaaS back-offices, analytics consoles, ops centers).
- Wiring CI/CD, deploy pipelines, observability, launch surfaces, or post-deploy adversarial review.
- Orchestrating the whole arc from raw user intent (Mode A).
- Picking up an existing codebase and routing to the specific tier that fills a gap (Mode B).
- Auditing an already-shipped artifact (PRD, architecture, repo, deployed app) for compliance with the discipline (Mode C).
- Designing a multi-repo collection that pairs as a suite (Mode D).

arc-ready does NOT apply, and routes elsewhere, when the work is:

- **A single component or page in isolation** outside any arc context. Use the harness's general agent for one-off frontend work.
- **A marketing or content site without app surface.** Use a static-site skill or the harness's general agent. arc-ready's launch tier covers a product launch; pure content-marketing sites are downstream of that.
- **Pure repo-hygiene tasks on an established codebase** that already has its arc artifacts. The Mode B repo audit covers this; arc-ready does not run the full arc on an audit-only request.
- **Project-level state above the arc.** Phases, sprint plans, ticket queues, per-feature work breakdowns belong to whatever orchestrates the project (GSD, BMAD, the user's own process). arc-ready tracks one thing: where on the idea-to-launch arc the project currently sits, per `.arc-ready/PROGRESS.md`. It does not track sprint planning, ticket queues, or per-feature work.
- **Routing decisions for non-arc work.** If the user asks for a blog post, a memory-leak debug, a refactor of an existing module, or any non-arc task, arc-ready refuses and surfaces the request to the harness for general routing. The orchestrator-of-this-arc is not the orchestrator-of-everything.

## Mode detection: A, B, C, D

Determine the mode in writing before any other action.

- **Mode A (full arc, greenfield).** No prior arc artifacts on disk; the user is starting from raw intent. arc-ready runs Tier 0 (orchestration scaffolding) then Tier 1 -> Tier 2 -> Tier 3 in dependency order. The default for "I have an idea, help me ship it." Resume protocol applies across sessions.
- **Mode B (specific tier, existing codebase).** One or more arc artifacts already exist. The user is filling a gap (e.g., the codebase has a PRD and an architecture but no roadmap; or has a deployed app but no observability). arc-ready routes directly to the tier that fills the gap. Tier 0 is reduced to detection-and-pass-through; Tier 1/2/3 sub-steps run only for the requested tier.
- **Mode C (retroactive audit).** The user wants to verify an already-produced artifact against arc-ready's discipline. arc-ready runs the tier's audit procedure (the three-label test for PRDs, the substitution test for architecture, the row-by-row grounding check for roadmaps, the scoring re-derivation for stacks, the artifact map check for repos, the slice-completion verification for apps, the same-artifact-promotion check for deploys, the SLO-binding check for observability, the substitution-test check for landings, the OWASP-walkthrough audit for hardening). Output is `<TIER>-AUDIT.md` at the canonical artifact path with severity-classified findings.
- **Mode D (multi-repo suite layout).** The user is designing a collection of related repositories (a multi-skill suite, a microservice cluster, a monorepo split). arc-ready loads `references/building/multi-repo-suite-layout.md` for the design pattern and routes the per-repo arc through Tier 2 sub-steps as a per-repo iteration.

The mode is recorded in `.arc-ready/PROGRESS.md` at the start of every session. Mode misdetection is the root of "the agent ran the wrong tier"; correct detection is the prerequisite for everything else.

## Tier dispatch within Mode A

Mode A runs the tiers in dependency order. The default sequence:

1. **Tier 0** (orchestration scaffolding): detection, intent capture, progress ledger, Pillars-compatible AGENTS.md emission.
2. **Tier 1** (planning): PRD -> ARCH -> ROADMAP -> STACK.
3. **Tier 2** (building): REPO scaffolding -> PRODUCTION application build (vertical slices).
4. **Tier 3** (shipping): DEPLOY -> OBSERVE -> (LAUNCH and HARDEN in parallel, with the critical-finding gate).

Each tier has a completion gate (see "Tier completion gates" section below). The next tier begins only after the prior tier's gate passes. Skips are explicit and recorded in PROGRESS.md; silence is not a status.

## Workflow

The workflow is structured as four tiers. Each tier has named sub-steps lifted from the consolidated source skills. References are loaded on demand per the table at the bottom of this file.

### Tier 0: Orchestration

The orchestration tier is small by construction. Its product is sequence and handoff metadata, not specialist content. Tier 0 runs at the start of every session and at the end of the arc; the body of the work happens in Tiers 1-3.

#### Step 0.1. Detect harness, mode, and invocation context

Load `references/orchestration/handoff-protocols.md`. Determine in writing:

1. **Harness.** Claude Code, Codex, Antigravity, Cursor, Windsurf, Pi, OpenClaw, or generic chat frontend. Determines whether tier dispatch is programmatic (via Skill tool) or guidance-text.
2. **Mode.** A (greenfield, no `.arc-ready/PROGRESS.md`), B (specific tier, existing artifacts), C (audit), D (multi-repo).
3. **Project-state hint.** Inventory existing `.<tier>-ready/` artifacts. Each one present is either an import (Mode A with prior work) or a gap-filler target (Mode B).

**Passes when:** harness, mode, and inventory are in PROGRESS.md; the user has confirmed the detected state.

#### Step 0.2. Resume protocol: re-derive state from disk

Load `references/orchestration/progress-tracking.md`. On every arc-ready turn (not just explicit resume):

1. `Read .arc-ready/PROGRESS.md` if it exists. Cached conversation memory of "we already did step N" is not authoritative; disk is.
2. `ls .<tier>-ready/` for every tier claimed complete. Verify each artifact path exists and is non-empty (not the unmodified template scaffold).
3. Identify the next sub-step from disk, not conversation. If PROGRESS.md says Tier 1 done but `.stack-ready/STACK.md` does not exist, the next sub-step is to run Step 1.4 (stack pick), not advance to Tier 2.
4. Record the resume verification with a timestamp and the disk-state hash (file mtime suffices).

This protocol runs every turn. It is the only defense against phantom resume. Trust the file system; the conversation about state is unreliable across cache invalidations and compression-summary loss.

**Passes when:** PROGRESS.md state matches disk state; the next sub-step is identified; any drift is corrected (disk wins).

#### Step 0.3. Capture kickoff intent (Mode A only)

In Mode A only, before invoking any tier, capture the user's project intent in one paragraph. Tier 0's only "writing" is metadata, not specialist content. In PROGRESS.md, produce a `## Kickoff intent` block:

1. **One-line project description** in the user's own words, quoted verbatim from their request.
2. **Greenfield-or-not check.** If partial existing work exists (a draft PRD, a started repo), declare it as imports per the import schema in `references/orchestration/progress-tracking.md`.
3. **Skip declarations.** Record any tiers the user has declared they want to skip (e.g., "skip launch; this is internal," "skip harden; prototype only"). Skip is a recorded event, not silence.
4. **Time-budget hint.** Optional. The user may declare an appetite ("two weeks to launch," "no timeline; exploring"). Informs which tiers are skipped.

This is **not** a PRD. The PRD comes from Tier 1 Step 1.1.

**Passes when:** the kickoff intent block is in PROGRESS.md; greenfield is confirmed (or imports are declared); skip declarations are recorded; the user has confirmed the paragraph is correct.

#### Step 0.4. Refuse-and-surface for out-of-scope requests

At any point during the arc, if the user asks arc-ready to do something outside its scope (write a blog post, debug a memory leak, refactor an existing module, pick a logo, write copy for an unrelated landing page), the response is:

1. **Refuse the inline production.** Do not start writing.
2. **Name the failure mode.** "That is scope leak. arc-ready does not produce non-arc content."
3. **Route.** Surface the request to the harness for general routing.
4. **Continue.** Resume the arc from the prior sub-step without modification.

Load `references/orchestration/scope-fence.md` for the per-failure-mode routing table.

**Passes when:** every out-of-scope request receives one of (inline-refusal, named-failure-mode, route, resume) and never an inline-fulfillment.

### Tier 0 (continued): Final ledger and AGENTS.md

#### Step 0.5. Final ledger

Once all in-scope tiers are verified-done or recorded-skip, the arc is complete. PROGRESS.md becomes the durable record. Produce a `## Arc complete` block:

1. **Per-tier summary table.** Tier, status (done / skipped / deferred / imported), artifact path, verification timestamp.
2. **Open items handed off to ongoing work.** Anything arc-ready did not complete (deferred harden findings, post-launch follow-ups). These are not arc-ready's responsibility going forward; they are the project's.
3. **Recommended next-step orchestrator.** GSD, BMAD, the user's own phase orchestrator. arc-ready is one-shot per project; the iteration loop after arc completion is a different orchestration pattern. See `references/shared/ORCHESTRATORS.md`.

#### Step 0.6. Emit project-root AGENTS.md if absent

If no `AGENTS.md` exists at project root, arc-ready writes a Pillars-compatible one. This is one of the few files arc-ready writes outside `.arc-ready/` and the per-tier `.<tier>-ready/` directories; it is agent-memory metadata, not specialist tier content. Load `references/orchestration/agents-md-template.md`.

Emit conditions are strict:

1. **Only if absent or safely augmentable.** If `AGENTS.md` already exists and is not Pillars-compatible, leave it untouched and record `pillars: adoption-blocked-existing-agents`.
2. **Pillars loader plus artifact map.** The emitted file describes the Pillars loading protocol, points at `agents/*.md`, and lists the arc-ready artifacts produced. It does NOT inline stack rules, build commands, conventions, forbidden actions, or specialist content. Those belong to Pillars files, Tier 2.1 scaffolding, or the user.
3. **Skip on out-of-fs harnesses.** On chat-only frontends with no file system, surface the AGENTS.md template as a guidance string for the user to paste.

**Passes when:** the summary table is in PROGRESS.md; deferred items are explicit; AGENTS.md exists at project root as a Pillars loader or adoption is blocked with reason; `agents/context.md` and `agents/repo.md` exist when a file system is available; the emit decision is recorded.

## AGENTS.md emit and respect

Tier 0 sub-step 6a and Tier 2.1 sub-step 14 both touch `AGENTS.md`. The rule across both: respect existing user-authored content, but make Pillars the standard memory layer for file-system projects.

Emit conditions:

1. **Absent file.** If `AGENTS.md` is absent, emit the Pillars-compatible template from `references/orchestration/agents-md-template.md`.
2. **Pillars-compatible file.** If `AGENTS.md` already implements the Pillars loader, preserve it and add arc-ready artifact-map context only when there is an obvious safe insertion point.
3. **Non-Pillars file.** If `AGENTS.md` exists but conflicts with Pillars, leave it untouched and record `pillars: adoption-blocked-existing-agents` in `.arc-ready/PROGRESS.md`.
4. **Pillars memory layer.** Tier 2.1 emits or verifies `agents/*.md` files per `references/building/pillars-integration.md`. The layer distills arc-ready artifacts into durable project memory; it does not replace the canonical artifact files.
5. **Skip on out-of-fs harnesses.** On chat-only frontends, surface the AGENTS.md template as guidance text for the user to paste.

The CLAUDE.md symlink (`CLAUDE.md -> AGENTS.md`) is created at the same time as AGENTS.md. The symlink is harmless on Codex and other AGENTS.md-aware harnesses, and is required for Claude Code to consume the file.

The grep test for emit-respect:

```bash
# AGENTS.md exists at project root
test -f AGENTS.md || echo "[fail] no AGENTS.md"
# AGENTS.md is Pillars-compatible
grep -q 'Pillars' AGENTS.md || echo "[fail] AGENTS.md does not describe Pillars"
# Pillars floor files exist
test -f agents/context.md || echo "[fail] agents/context.md missing"
test -f agents/repo.md || echo "[fail] agents/repo.md missing"
# CLAUDE.md is a symlink to AGENTS.md
[ -L CLAUDE.md ] && [ "$(readlink CLAUDE.md)" = "AGENTS.md" ] || echo "[fail] CLAUDE.md not symlinked correctly"
# AGENTS.md was emitted-or-respected per PROGRESS.md
grep -E 'agents_md_emitted: (path|existing-respected|guidance-text)|pillars: (adopted|adoption-blocked-existing-agents|guidance-text)' .arc-ready/PROGRESS.md || echo "[fail] PROGRESS.md does not record AGENTS.md / Pillars decision"
```

## Closing

## Keep going until the arc is actually done

The arc completes when every in-scope tier has either a verified-done status or a recorded-skip. Silence is not a status; the absence of a tier from PROGRESS.md is itself a have-not (silence-as-skip). Every tier either runs or is explicitly recorded as skipped with reason.

If at any point arc-ready feels the urge to "just sketch" what a tier would produce instead of running the tier, the urge is the failure mode. The right answer is to run the sub-step or to surface the skip and continue. Every line arc-ready writes that is not arc orchestration metadata or a tier sub-step's defined output is a step toward becoming the god-skill the arc-ready discipline exists to prevent.

The first inline content from arc-ready that should have come from a tier sub-step is the next thing to refuse.
