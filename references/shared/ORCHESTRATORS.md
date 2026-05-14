# Composing arc-ready with orchestrators

arc-ready tiers are orchestrator-agnostic by design. They work with any harness that handles tier routing: plain Claude Code, Codex, Cursor, Windsurf, GSD (get-shit-done), BMAD, Superpowers, or a custom orchestrator. The principle is one-way: an orchestrator can know about arc-ready tiers and invoke them at the right moment; arc-ready tiers do not know about, and do not invoke, each other or any orchestrator.

This file documents what composing looks like in practice.

## The principles

1. **The harness is the router.** No specialist tier calls another. The harness, the user, or arc-ready chooses which tier fires when.
2. **Artifacts are the contract.** Tier sub-steps do not pass arguments; they read and write files at known paths (`.<tier>-ready/*.md`). Any orchestrator can sit between two tier sub-steps as long as it preserves the artifacts.
3. **Project-level state is the orchestrator's job.** Phases, milestones, roadmap, sign-off ceremony belong to whatever orchestrates the project. arc-ready tiers track their own intra-tier state in `.<tier>-ready/STATE.md` files; the orchestrator owns the project view above that.
4. **Tier sub-steps work standalone.** Every tier can run without an external orchestrator present. The composition is opt-in.

## Pattern: GSD as orchestrator

GSD (get-shit-done) is a phase- and milestone-oriented workflow framework. Its commands map cleanly onto arc-ready tiers at phase boundaries. The integration runs entirely in GSD's command prompts; arc-ready stays unchanged.

| GSD command | arc-ready invocation |
|---|---|
| `/gsd-new-project` | Starts the planning tier. Optionally invokes `prd-ready` to write `.prd-ready/PRD.md`, then `architecture-ready` for `.architecture-ready/ARCH.md`, then `roadmap-ready` for `.roadmap-ready/ROADMAP.md`. Stack picked via `stack-ready` once architecture is settled. |
| `/gsd-plan-phase` | Reads existing `.<tier>-ready/*.md` planning artifacts to pre-fill phase decisions. Invokes the relevant planning tier if the phase requires fresh planning (e.g., a new sub-feature with its own success criteria fires `prd-ready`). |
| `/gsd-execute-phase` | Maps to building tier. Invokes `production-ready` for app feature work, `repo-ready` for repo hygiene work. The phase's slice queue (from roadmap-ready) becomes production-ready's vertical-slice input. |
| `/gsd-ship` | Maps to shipping tier. Invokes `deploy-ready` to cut the release, then `observe-ready` to wire dashboards and alerts, then `launch-ready` if there is a public-facing launch component. |
| `/gsd-secure-phase` | Invokes `harden-ready` for adversarial review of the phase output. Consumes architecture trust boundaries, production-ready threat model, deploy-ready environment list, observe-ready alert catalog. |
| `/gsd-code-review` | Invokes `production-ready` Tier 4 verification (have-nots scan, hollow-check, contract tests). Optionally invokes `harden-ready` for security-focused review. |
| `/gsd-verify-work` | Invokes `production-ready` proof tests for each completed slice. |
| `/gsd-audit-milestone` | Invokes `harden-ready` if the milestone touches security-sensitive surfaces. Otherwise pure GSD audit. |

The integration cost is entirely in GSD: each command's prompt gets a few additional lines describing when to invoke which specialist tier. arc-ready is consumed, not modified. New arc-ready tiers released later inherit the composition pattern without GSD code changes.

## Pattern: BMAD as orchestrator

BMAD's Greek-named agent personas (Architect, PM, QA, Dev, etc.) overlap with several arc-ready tiers. Two integration shapes work; pick one per project.

**Shape A: BMAD owns the planning tier; arc-ready owns building and shipping.** BMAD's PM and Architect agents produce equivalents of PRD.md and ARCH.md (call them `docs/prd.md` and `docs/architecture.md` in BMAD parlance). At the planning-to-building handoff, write the BMAD outputs into `.prd-ready/PRD.md` and `.architecture-ready/ARCH.md` paths so building- and shipping-tier arc-ready tiers can read them. From that point forward, arc-ready drives. Pros: each side does what it is good at. Cons: requires path translation at one boundary.

**Shape B: BMAD off for arc-ready projects.** If the project is using arc-ready, do not also run BMAD. Pick one orchestration philosophy per project. This is the cleanest interop and the lowest cognitive load.

Mixing BMAD personas with arc-ready tiers inside the same session creates a fragmented workflow. The persona-driven model (BMAD) and the harness-routed model (arc-ready) can compose at boundaries but should not compose within a single feature build.

## Pattern: Spec Kit as orchestrator

[Spec Kit](https://github.com/github/spec-kit) is GitHub's spec-driven development framework. It scopes a project around three feature-grained artifacts (`spec.md`, `plan.md`, `tasks.md`) plus an optional project-wide governance file (`constitution.md`) carrying non-negotiable principles. The grain is per-feature: each feature gets its own `spec/plan/tasks` triple under `.specify/specs/<feature>/`. The grain difference matters: arc-ready's planning-tier artifacts are project-wide (one `PRD.md`, one `ARCH.md`, one `ROADMAP.md`); Spec Kit's are per-feature.

arc-ready does not own a `constitution.md` equivalent. `constitution.md` is the governance file Spec Kit asks projects to maintain ("we never log PII," "all tests run on every PR," "no merge to main without two approvals"); arc-ready's planning artifacts are scoped to a single product surface (PRD, architecture, roadmap, stack), not to standing project principles. If the user wants standing principles, that slot belongs to Spec Kit's `constitution.md` and arc-ready stays out of it.

Two integration shapes work; pick one per project.

**Shape A: Spec Kit owns governance and feature-grained spec/plan/tasks; arc-ready owns project-grained planning, building, and shipping.** `constitution.md` sits above both as the project's principle layer. arc-ready's `PRD.md` is the project-wide product brief that Spec Kit's per-feature `spec.md` files refine in scope; arc-ready's `ARCH.md` is the project-wide system architecture that Spec Kit's per-feature `plan.md` files cite for boundary decisions. arc-ready's `ROADMAP.md` and Spec Kit's per-feature `tasks.md` files compose: ROADMAP sequences the features, `tasks.md` per feature breaks the slice into discrete work units. Building tier (repo-ready, production-ready) and shipping tier (deploy-ready, observe-ready, launch-ready, harden-ready) run unmodified, consuming the artifact stack from both sides. Pros: constitution.md fills a real governance slot arc-ready leaves empty; per-feature spec/plan/tasks gives finer-grained execution than ROADMAP slice queues alone. Cons: contributors must understand two artifact paths (`.specify/` and `.<tier>-ready/`); cross-references between them are manual.

**Shape B: Pick one per project.** If running Spec Kit end-to-end, skip the arc-ready planning tier (prd-ready, architecture-ready, roadmap-ready, stack-ready) and use Spec Kit's spec/plan/tasks for the planning content. Pick up arc-ready at the building tier (repo-ready, production-ready), reading from `.specify/specs/<feature>/spec.md` and `plan.md` instead of arc-ready planning artifacts. Pros: one artifact path; less cognitive load. Cons: loses arc-ready's named-failure-mode discipline at the planning tier (hollow PRDs, paper-tiger architecture, fictional-precision roadmaps); Spec Kit's planning artifacts are governance-flavored, not failure-mode-disciplined.

Mixing both Shape A and Shape B inside a single project (running prd-ready and Spec Kit's spec.md for the same scope) creates artifact drift: two source-of-truth files for one decision. Pick the shape at project kickoff and stay consistent. arc-ready's import detection handles either shape: if it sees `.specify/memory/constitution.md` and `.specify/specs/*/spec.md` on disk and no arc-ready planning artifacts, it routes to Shape B and starts the chain at repo-ready.

`constitution.md` itself is consumed by every arc-ready tier incidentally: the tier sub-steps read project-root context files (`AGENTS.md`, `CLAUDE.md`) and `constitution.md` when present, treating its content as standing have-nots. A `constitution.md` that says "no PII in logs" surfaces in observe-ready's logging defaults and harden-ready's review checklist; a `constitution.md` that says "every public API is versioned" surfaces in production-ready's API design step. The interaction is pull-only: arc-ready tiers read `constitution.md`, never write to it.

## Pattern: Superpowers (working-style skills) alongside arc-ready

Superpowers and similar plugin families ship working-style skills like `/think-harder`, `/brainstorm`, `/tdd`, `/research`. These operate at a different layer than arc-ready: they shape how the agent reasons within a session, not what artifacts the session produces.

The two compose orthogonally with zero integration work. A user can invoke `/think-harder` mid-session while building with `production-ready`. There is no overlap to resolve.

The only soft duplication: each arc-ready planning tier has its own research pass (`references/RESEARCH-*.md`), and Superpowers ships a generic `/research` skill. Use whichever is preferred; they do not conflict, but running both on the same question is redundant.

## Pattern: plain Claude Code, Codex, Cursor, Windsurf (no orchestrator)

The default. The user types a request, the harness routes to the matching arc-ready tier by trigger word, the tier runs end-to-end. No orchestration layer required. This is what every arc-ready tier assumes is the baseline.

The harness's tier-routing decision is what makes the "tight scope per tier" principle valuable: when triggers are precise and non-overlapping, the harness can route correctly without ambiguity.

## What arc-ready refuses to do

- **No tier invokes another.** An arc-ready specialist tier does not call `production-ready` from inside `deploy-ready`, even when the dependency is obvious. The orchestrator (or the user) makes that call.
- **No tier stores project-level state.** STATE.md files inside `.<tier>-ready/` are intra-tier working memory, not project ledgers. If the project needs a phase or milestone tracker, that is the orchestrator's responsibility (or a manual file).
- **No tier knows about a specific orchestrator.** arc-ready never gains a "GSD mode" or a "BMAD mode." Coupling to an orchestrator would defeat the orchestrator-agnostic principle and would force arc-ready to track every orchestrator's evolution.

## What arc-ready welcomes

- **An orchestrator that documents its arc-ready invocation pattern in its own command prompts**, the way GSD does in the table above.
- **A tool that reads arc-ready artifacts** (`.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, etc.) to pre-fill its own work, and writes its outputs back into the same artifact-shaped files when relevant.
- **A harness that improves tier-trigger precision**, so the routing layer stays accurate as more tier sub-steps get added to the user's installed set.

## When the orchestrator is wrong about which tier to invoke

The user is the final authority. If a harness or orchestrator routes to the wrong tier, the user can invoke the right one explicitly by name. arc-ready tiers are addressable directly; nothing requires going through an orchestrator.
