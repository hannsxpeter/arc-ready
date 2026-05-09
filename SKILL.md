---
name: arc-ready
description: "Take a software project from raw idea through PRD, architecture, roadmap, stack pick, repo scaffolding, application build, deploy pipeline, observability, launch, and adversarial hardening. The full arc, mechanically enforced, in one skill. Triggers on 'kickoff,' 'I have an idea,' 'walk me through idea to launch,' 'orchestrate the whole arc,' 'help me ship it end-to-end,' 'new project from scratch,' 'write a PRD,' 'product spec,' 'design the architecture,' 'system design,' 'monolith or microservices,' 'C4 diagram,' 'ADR,' 'build a roadmap,' 'milestone plan,' 'quarterly plan,' 'sequence the work,' 'Now-Next-Later,' 'Shape Up cycle,' 'what stack should I use,' 'pick a database,' 'which framework,' 'set up a repo,' 'add CI,' 'GitHub Actions,' 'configure linting,' 'add a README,' 'dashboard,' 'admin panel,' 'internal tool,' 'back office,' 'CRUD app,' 'deploy this,' 'CI/CD pipeline,' 'promote to staging,' 'zero-downtime migration,' 'expand-contract,' 'rollback,' 'canary,' 'blue/green,' 'add monitoring,' 'define an SLO,' 'alerts when X,' 'write a runbook,' 'structured logging,' 'distributed tracing,' 'error budget policy,' 'launch my product,' 'build a landing page,' 'Product Hunt,' 'Show HN,' 'waitlist,' 'OG card,' 'launch-day SEO,' 'press kit,' 'adversarial review,' 'pen-test prep,' 'OWASP walkthrough,' 'SOC 2 / HIPAA / PCI-DSS / GDPR gap check,' 'responsible disclosure,' 'bug bounty,' 'post-incident hardening,' 'security review before launch.' Refuses scope leak (one tier doing another tier's work), AI-slop output (PRDs/architectures/roadmaps/launches that read the same across any product), hollow output (sections filled, decisions absent), feature-factory output (un-prioritized feature lists), paper SLOs (numbers with no error budget), paper canaries (deploy mechanics absent under canary labels), AI-slop landings (substitution-test failures), scanner-only security (Snyk-passed-but-front-door-exploitable), rubber-stamp orchestration (advancing without artifact verification), and ghost handoff (a tier consuming an absent upstream artifact). Greenfield projects use Mode A (full arc); existing-codebase work uses Mode B (specific tiers); audit work uses Mode C (retroactive review); multi-repo collections use Mode D (suite-layout patterns). Successor to and consolidation of the eleven-skill aihxp/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready). Full trigger list and mode-routing table in README."
version: 0.1.0
updated: 2026-05-09
changelog: CHANGELOG.md
tier: arc
upstream: []
downstream: []
pairs_with: []
compatible_with:
  - claude-code
  - codex
  - cursor
  - windsurf
  - antigravity
  - pi
  - openclaw
  - any-agentskills-compatible-harness
---

# arc-ready

This skill consolidates the eleven-skill aihxp/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready) into a single tier-routed orchestrator. The discipline, the named failure modes, the grep tests, and the artifact contracts are unchanged. The installation footprint is one repo instead of twelve.

The arc is what every software project traverses, ordered or not, named or not: idea -> PRD -> architecture -> roadmap -> stack pick -> repo scaffolding -> app build -> deploy pipeline -> observability -> launch -> adversarial hardening. arc-ready makes the arc explicit, gates each tier on a verified artifact from the prior tier, and refuses the dominant AI failure modes at every step. Each tier was previously a sibling skill; consolidation preserves every tier's content and contract while removing the multi-repo coordination cost.

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

1. **Tier 0** (orchestration scaffolding): detection, intent capture, progress ledger, AGENTS.md emission.
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
3. Identify the next sub-step from disk, not conversation. If PROGRESS.md says Tier 1 done but `.stack-ready/DECISION.md` does not exist, the next sub-step is to run Step 1.4 (stack pick), not advance to Tier 2.
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

### Tier 1: Planning

The planning tier produces four artifacts in dependency order: `.prd-ready/PRD.md` (what), `.architecture-ready/ARCH.md` (how), `.roadmap-ready/ROADMAP.md` (when), `.stack-ready/DECISION.md` (with what tools). Each gates the next.

#### Step 1.1. PRD: write a PRD engineering can build from

Load `references/planning/prd-research.md` for mode detection (A/B/C/D/E/F per the PRD-mode taxonomy). Then load `references/planning/prd-anatomy.md` for the section-by-section structure.

Sub-steps:

1. **Pre-flight.** Confirm the user has: a problem worth solving (not a solution looking for a problem), a target user specific enough to fail the substitution test, a measurable success criterion, an appetite or deadline. Load `references/planning/problem-framing.md`.
2. **Mode C audit (only if a prior AI-slop PRD exists).** Run the three-label audit (`references/planning/prd-antipatterns.md` section 3). Output `.prd-ready/AUDIT.md` with sentence-by-sentence findings. The audit is the input to the rewrite.
3. **Problem framing.** Rewrite the Problem section in the form "users today do X manually, which takes Y time and costs Z." Do not name the solution until after the problem is framed.
4. **Target user.** Load `references/planning/user-personas.md`. Specificity is the discipline: named role, named context, named constraints, named workarounds or competitors. The target-user section must fail the substitution test.
5. **Success criteria.** Load `references/planning/success-criteria.md`. Outcome metrics with thresholds and measurement methods, not output counts. Avoid vanity metrics.
6. **Functional requirements.** MoSCoW distribution. At most 50% Must. Cut line below which Could/Won't items live. Load `references/planning/requirements.md`.
7. **Non-functional requirements.** Performance, scale, availability, security, accessibility, internationalization. Load `references/planning/requirements.md` section on NFRs.
8. **Scope and no-gos.** Out-of-scope is a load-bearing PRD section, not an afterthought. Load `references/planning/scope-and-out-of-scope.md`.
9. **Risks, assumptions, open questions.** Each labeled as hypothesis with validation, decision with rationale, or open question with owner. Load `references/planning/risks-and-assumptions.md`.
10. **Downstream handoff block.** Architecture-ready inputs, roadmap-ready inputs, stack-ready inputs, production-ready inputs. Each consumed downstream tier looks here for its inputs.
11. **Alignment and sign-off protocol.** Load `references/planning/stakeholder-alignment.md` for the sign-off ledger pattern. Sign-off lives in the PRD, not in Slack or email.
12. **Iterate-vs-freeze lifecycle.** Load `references/planning/iterate-vs-freeze.md`. Living, soft-frozen, and frozen phases. Every edit during soft-frozen or frozen gets a changelog entry and a broadcast.

The worked example is `references/planning/EXAMPLE-PRD.md`. Use it to calibrate the PRD's specificity and substitution-test resistance.

**Passes when:** every sentence labels as decision, hypothesis, or open question; the substitution test is run on the Problem and Target User sections; sign-off is recorded; the downstream handoff block is filled. The artifact at `.prd-ready/PRD.md` is non-empty and the have-nots check (see PRD have-nots in the consolidated section below) returns clean.

#### Step 1.2. Architecture: design the shape of the system before any code is written

Load `references/planning/architecture-research.md` for mode detection. The architectural anatomy is described across the per-section sub-steps below; load each as needed.

Sub-steps:

1. **System shape.** Monolith, modular monolith, microservices, distributed monolith, serverless, hybrid. Load `references/planning/system-shape.md`. The choice ties to the PRD's scale ceiling, team size, and operational appetite.
2. **Component breakdown.** Bounded contexts, components, services. Each component has a name, a purpose, an upstream dependency list, and an owner. Load `references/planning/component-breakdown.md`.
3. **Data architecture.** Data stores, ownership, consistency requirements, partition strategy. Load `references/planning/data-architecture.md`.
4. **Integration architecture.** API styles (REST/GraphQL/gRPC/messaging), contract-versioning policy, error-handling shape. Load `references/planning/integration-architecture.md`.
5. **Non-functional architecture.** Performance budgets, scale thresholds, availability targets. Numbers, not adjectives. Load `references/planning/non-functional-architecture.md`.
6. **Trust boundaries.** Where authentication, authorization, encryption are enforced. Each boundary mapped to specific code/config that implements it. Load `references/planning/trust-boundaries.md`.
7. **ADRs.** Each load-bearing decision is an ADR with context, decision, consequences, flip points. Load `references/planning/adr-discipline.md`.
8. **Diagrams.** C4 (Context, Container, Component, Code) or arc42. Diagrams support decisions; they do not replace them. Load `references/planning/diagrams.md`.
9. **Evolutionary architecture.** Fitness functions, change-cost analysis, the "what would flip this" test. Load `references/planning/evolutionary-architecture.md`.
10. **Component dependency graph.** The topological sort that feeds roadmap-ready (Step 1.3). Without this, roadmap sequencing is guessing.

The worked example is `references/planning/EXAMPLE-ARCH.md`.

**Passes when:** every box, arrow, and ADR is a decision with rationale and a flip point; the substitution test is run on every component name and rationale; trust boundaries are mapped to specific files/configs; the dependency graph is in `.architecture-ready/HANDOFF.md` ready for roadmap-ready. The artifact at `.architecture-ready/ARCH.md` is non-empty and the have-nots check returns clean.

#### Step 1.3. Roadmap: sequence the work over time

Load `references/planning/roadmap-research.md` for mode detection. Then load `references/planning/roadmap-anatomy.md`.

Sub-steps:

1. **Capacity input.** Team size in engineers, available engineer-weeks per cycle, serial-fraction estimate. Without this, roadmap-ready produces direction without dates, explicitly labeled as such. Load `references/planning/dependency-graph.md` section 4.
2. **Cadence model.** Now-Next-Later, Shape Up cycles, PI planning, OKR-driven, or hybrid. Load `references/planning/cadence-models.md`.
3. **Dependency graph.** Topological sort of components from `.architecture-ready/HANDOFF.md`. Slices are produced in dependency order. Load `references/planning/dependency-graph.md`.
4. **Risk-driven prioritization.** Highest-risk items go first; lowest-risk items go later. Load `references/planning/risk-driven-prioritization.md`.
5. **Sequencing principles.** Load-bearing-first, latency-of-feedback-minimizing, demo-stable. Load `references/planning/sequencing-principles.md`.
6. **Scope-vs-time tradeoffs.** Fixed-date vs fixed-scope per Shape Up. Load `references/planning/scope-vs-time.md`.
7. **Launch sequencing.** Launch milestone gates, launch-day dependencies, the critical-finding gate from harden. Load `references/planning/launch-sequencing.md`.
8. **Review cadence.** When the roadmap is re-planned, who attends, what triggers an off-cycle re-plan. Load `references/planning/review-cadence.md`.
9. **Handoff to execution.** Slice queue for production-ready, cutover cadence for deploy-ready, KPI handoff for observe-ready, launch-milestone gate dates for launch-ready. Load `references/planning/handoff-to-execution.md`.

The worked example is `references/planning/EXAMPLE-ROADMAP.md`.

**Passes when:** every row labels as grounded commitment, outcome-framed direction, or named open question; every commitment references an upstream PRD section, architecture component, or external constraint; the parallel-track count does not exceed team-engineer-count; the handoff section is filled. The artifact at `.roadmap-ready/ROADMAP.md` is non-empty and the have-nots check returns clean.

#### Step 1.4. Stack: pick the right tech bundle for this job

Load `references/planning/stack-research.md` for mode detection. Then load `references/planning/scoring-framework.md` for the 12-dimension framework.

Sub-steps:

1. **Pre-flight and constraints.** Domain, team size, budget, time-to-ship, regulatory environment, existing investments. Load `references/planning/preflight-and-constraints.md`.
2. **Domain stack selection.** Twelve domain profiles in `references/planning/domain-stacks.md`. Match the project to a domain profile.
3. **Bundle scoring.** Score candidate bundles across the 12 dimensions with stated weights. Load `references/planning/dimension-deep-dives.md` for per-dimension definitions and `references/planning/stack-bundles.md` for the 36+ pre-scored bundles.
4. **Pairing rules.** Cross-bundle compatibility checks. Load `references/planning/pairing-rules.md`.
5. **Tradeoff narratives.** Per-bundle "what flips this" and scale ceiling. Load `references/planning/tradeoff-narratives.md`.
6. **Migration paths.** What it takes to leave the bundle if scale or team or domain changes. Load `references/planning/migration-paths.md`.
7. **ADR emission.** S-prefix ADRs for every load-bearing tech pick. Cross-link to architecture ADRs.
8. **Decision artifact.** Ranked shortlist with scores, weighted rationale, named flip points. Output `.stack-ready/DECISION.md`.

The worked example is `references/planning/EXAMPLE-STACK.md`.

**Passes when:** every score has stated weights the user can override; every recommendation has a named flip point; the bundle pairs (frontend, backend, data, hosting, observability, etc.) compose without compatibility-violating overlap; the migration path is documented. The artifact at `.stack-ready/DECISION.md` is non-empty and the have-nots check returns clean.

### Tier 2: Building

The building tier produces a scaffolded repository and an end-to-end-wired application. Sequential by default: repo first, then app.

#### Step 2.1. Repo scaffolding: production-grade repository structure, docs, CI/CD, quality tooling

Load `references/building/questioning.md` for the pre-flight question protocol. Then load `references/building/project-profiles.md` for the project-type x stage x audience matrix.

Sub-steps:

1. **Stack detection.** Read existing files to detect the stack. If stack-ready ran (Step 1.4), consume `.stack-ready/DECISION.md`. If not, run a detection pass per the existing-codebase mode.
2. **Project profile.** Type (CLI, library, app, API, monorepo, etc.) x stage (prototype, beta, production) x audience (internal, OSS, commercial). Determines which files are scaffolded.
3. **Repo structure.** Standard top-level layout for the chosen stack. Load `references/building/repo-structure.md`.
4. **README.** Adapted to project type and audience. Load `references/building/readme-craft.md`.
5. **Community standards.** LICENSE, CODE_OF_CONDUCT, CONTRIBUTING, SECURITY. Load `references/building/community-standards.md` and `references/building/community-governance.md`.
6. **Technical docs.** ARCHITECTURE, DECISIONS (ADR), DEVELOPMENT, RELEASE. Load `references/building/technical-docs.md`.
7. **CI/CD.** Build, test, lint, security-scan workflows. Platform-specific: load `references/building/platform-github.md`, `references/building/platform-gitlab.md`, or `references/building/platform-bitbucket.md`. Load `references/building/ci-cd-workflows.md`.
8. **Quality tooling.** Linter, formatter, test runner, type checker, pre-commit hooks. Load `references/building/quality-tooling.md`.
9. **Git workflows.** Branching strategy, commit conventions, PR template, merge policy. Load `references/building/git-workflows.md`.
10. **Licensing and legal.** License selection, third-party-attribution policy, trademark notes. Load `references/building/licensing-legal.md`.
11. **Security setup.** Dependabot/Renovate, secret scanning, branch protection, signed commits. Load `references/building/security-setup.md`.
12. **Onboarding DX.** First-run experience, dev container, devbox, codespace, Makefile. Load `references/building/onboarding-dx.md`.
13. **Release distribution.** Versioning, tagging, release-notes generation, package publishing. Load `references/building/release-distribution.md`.
14. **AGENTS.md.** Cross-tool agent brief at project root. Load `references/orchestration/agents-md-template.md`. Detect existing AGENTS.md; respect or augment per the emission rules.
15. **Mode B audit-only path.** If the user wants an audit, not a scaffold, run `references/building/repo-audit.md` and `references/building/audit-mode.md`. Output `.repo-ready/AUDIT-REPORT.md` with severity-classified findings, no file modifications.
16. **Mode D multi-repo suite layout.** If the user is designing a collection of related repos, load `references/building/multi-repo-suite-layout.md` for the suite-layout pattern (skill-suite, microservice-cluster, monorepo-split).
17. **Monorepo patterns.** Workspace tools (pnpm/yarn/npm workspaces, Turborepo, Nx, Lerna, Rush). Load `references/building/monorepo-patterns.md`.
18. **Agent safety.** Forbidden actions, scope of agent edits, tool-permission policy. Load `references/building/agent-safety.md`.

**Passes when:** the relevant-files-not-maximum-files principle is satisfied (no scaffolded file is unmaintained-template); README is non-placeholder; CI workflows run and pass on a fresh clone; AGENTS.md exists at project root; the project profile is recorded.

#### Step 2.2. Production: build the end-to-end-wired application

Load `references/building/preflight-and-verification.md` for the pre-flight protocol. Then load `references/building/codebase-research.md` if existing code is present.

Sub-steps:

1. **Pre-flight.** Stack confirmed (from Step 1.4 or detection), repo scaffolded (from Step 2.1), PRD's slice queue available (from Step 1.3 handoff).
2. **Vertical slice discipline.** Build one feature end-to-end (schema + API + permission + service + queries + UI + states + tests) before touching the next. Load `references/building/ui-design-patterns.md`. The principle is non-negotiable.
3. **DESIGN.md detection.** If `DESIGN.md` exists at project root, consume it (sub-step 3a). If not, derive the visual identity and scaffold one (sub-step 3b). Load `references/building/design-md-integration.md`.
4. **States and feedback.** Loading, empty, error, partial, success. Every state covered for every surface. Load `references/building/states-and-feedback.md`.
5. **Data layer.** Schema, migrations, ORM/query layer, transactional boundaries. Load `references/building/data-layer.md`.
6. **Auth and RBAC.** Authentication mechanism, role model, permission checks at boundaries. Load `references/building/auth-and-rbac.md`.
7. **Headers and navigation.** Top nav, side nav, breadcrumbs, command palette. Load `references/building/headers-and-navigation.md`.
8. **Information architecture.** Page hierarchy, URL structure, route organization. Load `references/building/information-architecture.md`.
9. **Naming.** Variable, function, file, route, component naming conventions. Load `references/building/naming.md`.
10. **Domain considerations.** Per-domain UX patterns (healthcare, finance, e-commerce, etc.). Load `references/building/domain-considerations.md`.
11. **Performance and security.** Bundle size, render performance, OWASP-aligned input validation, output encoding. Load `references/building/performance-and-security.md` and `references/building/security-deep-dive.md`.
12. **API and integrations.** Endpoint design, request/response shape, retry and idempotency, third-party integrations. Load `references/building/api-and-integrations.md`.
13. **Data visualization.** Chart libraries, accessibility of data viz, real-data-not-fake-data principle. Load `references/building/data-visualization.md`.
14. **Analytics and telemetry.** Product analytics events, frontend telemetry, opt-out and consent. Load `references/building/analytics-and-telemetry.md`.
15. **Animation and motion.** Purpose-driven motion, prefers-reduced-motion compliance. Load `references/building/animation-and-motion.md`.
16. **AI product patterns.** Streaming UI, partial outputs, hallucination guards, agent-tool surfaces. Load `references/building/ai-product-patterns.md`.
17. **Accessibility deep-dive.** WCAG 2.2 AA baseline, keyboard navigation, screen-reader testing. Load `references/building/accessibility-deep-dive.md`.
18. **Dark mode.** Token-based theming, prefers-color-scheme, contrast preservation. Load `references/building/dark-mode-deep-dive.md`.
19. **Error pages and offline.** 404, 500, offline, maintenance. Load `references/building/error-pages-and-offline.md`.
20. **Expansion and scalability.** Multi-tenant, multi-region, internationalization-ready. Load `references/building/expansion-and-scalability.md`.
21. **File management and uploads.** Upload UI, virus scanning, signed URLs, retention. Load `references/building/file-management-and-uploads.md`.
22. **Internationalization.** i18n framework, locale negotiation, RTL support. Load `references/building/internationalization.md`.
23. **Login and auth pages.** Sign-up, sign-in, password reset, magic link, MFA, SSO. Load `references/building/login-and-auth-pages.md`.
24. **Marketing and landing pages.** Pre-product marketing surfaces inside the app shell. Load `references/building/marketing-and-landing-pages.md`. (Standalone marketing-launch surfaces are Tier 3 launch's job; this is the in-app subset.)
25. **Migration and data import.** CSV/JSON import, pipeline-driven migration, dry-run mode. Load `references/building/migration-and-data-import.md`.
26. **Notifications and email.** In-app notifications, transactional email, digest patterns. Load `references/building/notifications-and-email.md` and `references/building/email-template-design.md`.
27. **Payments and billing.** Stripe/Paddle/Lemon-Squeezy integration, invoice flows, dunning. Load `references/building/payments-and-billing.md`.
28. **Realtime and collaboration.** Presence, cursor sharing, CRDT vs OT, WebSocket/SSE. Load `references/building/realtime-and-collaboration.md`.
29. **Reporting.** Dashboard reports, export (CSV/PDF), scheduled delivery. Load `references/building/reporting.md`.
30. **SEO and web standards.** robots.txt, sitemap, canonical URLs, structured data. Load `references/building/seo-and-web-standards.md`.
31. **Settings and configuration.** User settings, org settings, feature flags. Load `references/building/settings-and-configuration.md`.
32. **Social media features.** Comments, reactions, share, embed. Load `references/building/social-media-features.md`.
33. **System integration.** Webhooks, OAuth providers, third-party API contracts. Load `references/building/system-integration.md`.
34. **Testing and quality.** Unit, integration, E2E, visual regression, contract tests. Load `references/building/testing-and-quality.md`.
35. **Workflows and actions.** Background jobs, scheduled tasks, action queues. Load `references/building/workflows-and-actions.md`.

The principle: every feature ships wired end-to-end to a real backend, not stubbed with TODO, fake JSON, or "hook this up later." No-scaffold-no-placeholder is the load-bearing rule.

**Passes when:** every slice in the queue is end-to-end-wired (real backend, real data, all states, tests passing); the no-scaffold-no-placeholder grep test (TODO/FIXME/lorem-ipsum/fake-data) returns clean for shipped slices; `.production-ready/STATE.md` records the slice queue, completed slices, and active ADRs.

### Tier 3: Shipping

The shipping tier consists of four sub-steps. Deploy and observe are sequential (deploy first; observe wires onto the deployed app). Launch and harden run in parallel (with the critical-finding gate).

#### Step 3.1. Deploy: ship safely, repeatably, reversibly

Load `references/shipping/deploy-research.md` for mode detection. Then load `references/shipping/preflight-and-gating.md`.

Sub-steps:

1. **Preflight and gating.** Build is green, tests pass, security scan is clean (above accepted-risk threshold), schema migration plan is reviewed.
2. **Pipeline patterns.** Build once, promote the same artifact through environments. Load `references/shipping/pipeline-patterns.md`.
3. **Environment parity.** Pre-prod, staging, prod parity rules. Diffs are explicit, not accidental. Load `references/shipping/environment-parity.md`.
4. **First-deploy checklist.** First production deploy gets extra scrutiny. Load `references/shipping/first-deploy-checklist.md`.
5. **Deployment topologies.** Single-region, multi-region, edge, hybrid. Load `references/shipping/deployment-topologies.md`.
6. **Zero-downtime migrations.** Expand-contract pattern, multi-deploy migration calendar. Schema changes are NEVER one-deploy operations on a populated database. Load `references/shipping/zero-downtime-migrations.md`.
7. **Progressive delivery.** Canary, blue-green, feature-flagged rollout. Each pattern has a stop rule, not a label. Load `references/shipping/progressive-delivery.md`.
8. **Rollback playbook.** Code-only rollback is straightforward. Data-forward rollback is a compensating-forward plan plus a restore point, never a "redeploy previous image" bullet. Load `references/shipping/rollback-playbook.md`.
9. **Secrets injection.** Vault-pulled, runtime-injected, never-committed. Load `references/shipping/secrets-injection.md`.

**Passes when:** the same-artifact-promotion grep test passes (the prod artifact hash equals the staging artifact hash); every schema change is classified as code-only or data-forward with the corresponding plan; canary stop rules are concrete (not "monitor and decide"); rollback paths are proven reachable from post-deploy state.

#### Step 3.2. Observe: keep the deployed app healthy

Load `references/shipping/observe-research.md` for mode detection. Then load `references/shipping/slo-design.md`.

Sub-steps:

1. **SLO design.** User-facing journeys named; SLI per journey defined; SLO threshold and window stated; error-budget policy declared (what triggers a code freeze; who owns the policy). Load `references/shipping/slo-design.md`.
2. **Metrics taxonomy.** Service-level indicators, supporting diagnostics, business metrics. Each charted metric is explicitly classified. Load `references/shipping/metrics-taxonomy.md`.
3. **Logging patterns.** Structured logging, sampling, correlation IDs, retention. Load `references/shipping/logging-patterns.md`.
4. **Tracing.** OpenTelemetry distributed tracing, span structure, baggage. Load `references/shipping/tracing.md`.
5. **Error tracking.** Sentry/Bugsnag/Honeybadger integration, source-map upload, release tagging. Load `references/shipping/error-tracking.md`.
6. **Alert patterns.** Symptom-based, not cause-based; SLO-breaking, not threshold-tripping; pageable vs ticketable. Load `references/shipping/alert-patterns.md`.
7. **Dashboards.** Bound to SLOs; supporting diagnostics labeled non-alerting; no decoration charts. Load `references/shipping/dashboards.md`.
8. **Incident response.** Severity definitions, on-call rotation, status page, runbooks. Load `references/shipping/incident-response.md`.
9. **Post-mortem.** Blameless, action-item-tracked, class-not-instance fixes. Load `references/shipping/post-mortem.md`.
10. **Vendor landscape.** Datadog/Honeycomb/Grafana/New Relic/Sentry/Axiom selection grid. Load `references/shipping/vendor-landscape.md`.

**Passes when:** every charted/alerted/SLOed number is bound to a journey or explicitly labeled non-alerting; the error-budget policy names a freeze trigger and an owner; runbooks have been executed at least once (paper runbooks fail this gate); paging alerts have a real-recent-fire history (alert hygiene).

#### Step 3.3. Launch: tell the world without shipping AI-slop

Load `references/shipping/launch-research.md`. Then load `references/shipping/positioning-and-copy.md`.

Sub-steps:

1. **Positioning.** Who-it-is-for line that fails the substitution test. Load `references/shipping/positioning-and-copy.md`.
2. **Landing page anatomy.** Hero, sub-hero, feature cards, social proof, pricing, FAQ, CTA. Each section has a substitution-test-pass criterion. Load `references/shipping/landing-page-anatomy.md`.
3. **Copy refinement.** Hero, sub-hero, every card. Run substitution test sentence by sentence. AI-slop hero copy is the dominant launch failure mode.
4. **Visual surface.** Renders to actual designs or actual screenshots, not "AI illustration of an abstract concept." (Frontend craft from Tier 2 carries forward.)
5. **SEO fundamentals.** Meta tags, OG tags, Twitter cards, canonical, sitemap, robots. Load `references/shipping/seo-fundamentals.md`.
6. **Social share cards.** OG card renders in actual previews (Slack, iMessage, Twitter, LinkedIn). Test before launch. Load `references/shipping/social-share-cards.md`.
7. **Waitlist and email.** Funnel from waitlist signup to launch-day notification; double-opt-in; unsubscribe; deliverability. Load `references/shipping/waitlist-and-email.md`.
8. **Launch channels.** Product Hunt, Show HN, Reddit, X, IH, dev.to, LinkedIn. Per-channel format and timing. Load `references/shipping/launch-channels.md`.
9. **Launch-week runbook.** D-7 to D+7 schedule. Load `references/shipping/launch-week-runbook.md`.
10. **Launch telemetry.** Source attribution, conversion funnel, signup quality. Load `references/shipping/launch-telemetry.md`.
11. **Press and outreach.** Press kit, embargoed previews, journalist outreach. Load `references/shipping/press-and-outreach.md`.
12. **Post-launch transition.** From launch-day push to ongoing marketing; launch-ready hands off. Load `references/shipping/post-launch-transition.md`.

**Passes when:** the substitution test passes on the hero, sub-hero, every feature card, the OG card title, the Show HN title, the launch email subject; the OG card renders in at least three preview surfaces; the waitlist has source attribution; launch-day telemetry has a real implementation, not a "we'll wire it up later" stub.

#### Step 3.4. Harden: survive adversarial attention

Load `references/shipping/harden-research.md`. Then load `references/shipping/owasp-walkthrough.md`.

Sub-steps:

1. **OWASP Top 10 walkthrough.** Per-category review: each category passes, partials, or fails for the deployed app. Load `references/shipping/owasp-walkthrough.md`.
2. **OWASP API Security Top 10.** API-specific category review. Same structure.
3. **OWASP LLM Top 10.** If the app has an LLM surface. Same structure.
4. **Compliance frameworks.** SOC 2 Common Criteria, HIPAA 164.312, PCI-DSS 4.0, GDPR Article 32. Each control mapped to specific code/config evidence. Load `references/shipping/compliance-frameworks.md`.
5. **Auth hardening.** Session policy, MFA enforcement, brute-force protection, OAuth misconfigurations. Load `references/shipping/auth-hardening.md`.
6. **API hardening.** Rate limiting, input validation, output encoding, contract enforcement. Load `references/shipping/api-hardening.md`.
7. **Crypto primitives.** Algorithm selection, key management, rotation policy. Load `references/shipping/crypto-primitives.md`.
8. **Pen-test prep.** Scope, environment, RoE, retest discipline. Load `references/shipping/pentest-prep.md`.
9. **Responsible disclosure.** SECURITY.md, security@<domain>, bug-bounty program design. Load `references/shipping/responsible-disclosure.md`.
10. **Post-incident hardening.** Class-not-instance fixes from past incidents. Load `references/shipping/post-incident-hardening.md`.
11. **Actionable findings.** Every finding has: title, severity with justification, affected asset, reproduction steps, impact, root cause, proposed fix with code example, regression-prevention plan, retest plan, references. Load `references/shipping/actionable-findings.md`.
12. **Security tooling landscape.** SAST, DAST, SCA, secrets scanning, container scanning. Tools are inputs, not the audit itself. Load `references/shipping/security-tooling-landscape.md`.

**Passes when:** every OWASP category has a verdict with evidence; every compliance control maps to specific implementation; every "accepted risk" has a named owner and an expiration date; the findings report is actionable per the actionable-findings format; the critical-finding gate to launch has resolved.

### Tier 0 (continued): Final ledger and AGENTS.md

#### Step 0.5. Final ledger

Once all in-scope tiers are verified-done or recorded-skip, the arc is complete. PROGRESS.md becomes the durable record. Produce a `## Arc complete` block:

1. **Per-tier summary table.** Tier, status (done / skipped / deferred / imported), artifact path, verification timestamp.
2. **Open items handed off to ongoing work.** Anything arc-ready did not complete (deferred harden findings, post-launch follow-ups). These are not arc-ready's responsibility going forward; they are the project's.
3. **Recommended next-step orchestrator.** GSD, BMAD, the user's own phase orchestrator. arc-ready is one-shot per project; the iteration loop after arc completion is a different orchestration pattern. See `references/shared/ORCHESTRATORS.md`.

#### Step 0.6. Emit project-root AGENTS.md if absent

If no `AGENTS.md` exists at project root, arc-ready writes a minimal one. This is one of the few files arc-ready writes outside `.arc-ready/` and the per-tier `.<tier>-ready/` directories; it is orchestration metadata. Load `references/orchestration/agents-md-template.md`.

Emit conditions are strict:

1. **Only if absent.** If `AGENTS.md` already exists, leave it untouched. Record `AGENTS.md: existing-respected`.
2. **Only artifact metadata.** The emitted file lists the arc-ready artifacts produced and a one-paragraph pointer. It does NOT contain stack, build commands, conventions, forbidden actions, or specialist content. Those belong to repo-ready scaffolding (Step 2.1) or to the user.
3. **Skip on out-of-fs harnesses.** On chat-only frontends with no file system, surface the AGENTS.md template as a guidance string for the user to paste.

**Passes when:** the summary table is in PROGRESS.md; deferred items are explicit; AGENTS.md exists at project root (either user-authored or arc-ready-emitted); the emit decision is recorded.

## The "have-nots": consolidated failure-mode catalog

These have-nots disqualify the artifact at the corresponding tier. Every one is grep-testable. Every one is preserved verbatim from the source eleven skills. The full per-tier catalogs (with citations, severity, remediation) are in `references/<tier>/<skill>-antipatterns.md`.

### Tier 0 (orchestration) have-nots

- **Scope leak.** arc-ready writes specialist content. Any markdown produced by arc-ready that fulfills a specialist tier's job from outside that tier's sub-step. Grep target: arc-ready output that contains a section header from a tier's artifact template (`# Product Requirements`, `## Trust Boundaries`, `## Now / Next / Later`, `## OWASP Walkthrough`, etc.) outside that tier's sub-step.
- **Rubber-stamp orchestration.** PROGRESS.md says step done with no artifact on disk. For every PROGRESS.md row where `status: done`, the declared `artifact:` path exists and is non-empty. Without that, rubber-stamp fired.
- **Phantom resume.** Resume that did not re-derive state from disk. Every arc-ready turn begins with a `Read .arc-ready/PROGRESS.md` and an `ls` of every claimed-complete `.<tier>-ready/`. If a turn skipped these and acted on cached conversation memory, phantom resume fired.
- **Ghost handoff.** Tier invoked before its declared upstream artifact exists. For every tier sub-step, the prior tier's artifact-verification timestamp is earlier than the sub-step start. Without that, ghost handoff fired.
- **Happy-path orchestration.** No status code in PROGRESS.md for the failure / skip / import / re-invoke cases. Every PROGRESS.md row's `status` field is one of `pending`, `in-flight`, `done`, `skipped`, `imported`, `failed`, `re-invoked`.
- **Critical-finding gate breach.** arc-ready proceeds with launch after a Critical finding from harden without an explicit risk-acceptance entry. If `.harden-ready/FINDINGS.md` contains an unresolved Critical and PROGRESS.md shows launch as `done` without a `risk-acceptance:` block, the gate failed.
- **Out-of-scope inline answer.** Any conversation turn where the user asked for a non-arc deliverable, and arc-ready produced markdown that fulfills the request rather than refusing and routing.
- **Silence as skip.** A tier that does not appear in PROGRESS.md at all (neither as done nor as skipped). Silence is not a status.

### Tier 1.1 (PRD) have-nots

- **Hollow PRD.** Every section is filled, but the sentences are decisions-that-aren't. The PRD passes visual review and decides nothing.
- **Invisible PRD.** The PRD reads the same across any product in the category. Substitution test fails on the Problem and Target User sections.
- **Feature laundry list.** A flat list of features (or requirements) with no prioritization. No cut line. Every item is Must, or nothing is ranked.
- **Solution-first PRD.** The Problem section names the product's solution. The product is assumed; the problem is backfilled.
- **Assumption-soup PRD.** User-behavior claims stated as facts without evidence, validation plan, or hypothesis labeling.
- **Moving-target PRD.** Edited frequently without changelog or broadcasts. Engineers stop trusting the document.
- **Theater PRD.** Sections present, structure pristine, every sentence decoration. The visual completeness substitutes for decision content.
- **Quill-and-inkwell PRD.** Tone elevated to match the gravity the writer thinks the document deserves. Decisions buried in prose.
- **Superficial-completion PRD.** The PRD reaches "frozen" status before downstream consumers have signed off on the handoff blocks.
- **Engineer-can-not-start-building.** The PRD does not contain enough specificity for an engineer to start the first slice without a clarification meeting.

### Tier 1.2 (architecture) have-nots

- **Architecture theater.** Diagrams without decisions. C4 diagrams rendered, ADRs absent or non-load-bearing.
- **Paper-tiger architecture.** Decisions without failure-mode analysis. Looks robust until first real load.
- **Cargo-cult cloud-native.** Kubernetes and Kafka for a ten-user CRUD. Scale predictions invented; the PRD's actual scale ceiling ignored.
- **Stackitecture.** Tool choices dressed up as architecture. "We use Postgres and Next.js" is not an architectural decision.
- **Resume-driven architecture.** Decisions picked for the writer's career rather than the system's constraints.
- **Non-architecture.** "We'll figure it out later." Absence of decision masquerading as agility.
- **"Scalable" as a claim with no numbers.** Adjectives where thresholds belong.
- **Trust boundaries on paper only.** Declared in the architecture document, absent in code or configuration.
- **ADRs without flip points.** "We chose X" without "what would flip this."
- **Component graph absent.** No topological dependency graph in `.architecture-ready/HANDOFF.md`. Roadmap-ready then guesses.

### Tier 1.3 (roadmap) have-nots

- **Feature factory.** Items listed with no outcome. Bare feature names.
- **Build trap.** Roadmap reads as a feature backlog instead of an outcome plan (Perri).
- **Roadmap theater.** Dates asserted with no capacity input.
- **Fictional precision.** Gantt-to-the-day with no team-capacity input.
- **Fictional parallelism.** More concurrent tracks than engineers.
- **Quarter-stuffing.** All four quarters equally full. Far horizons treated at near-horizon precision.
- **Speculative roadmap.** Items invented without upstream PRD or architecture reference.
- **Shelf roadmap.** Written once, never refreshed. Cycle boundaries pass with no replan.
- **Polish-indefinitely.** Items extended without explicit decision. The "we'll just keep iterating" trap.
- **Silent re-prioritization.** Order changed without changelog or broadcast.

### Tier 1.4 (stack) have-nots

- **Unweighted recommendation.** Scores without stated weights the user can override.
- **Flip-point-free recommendation.** "Use X" without "what would flip this."
- **Familiarity-as-fit.** The stack the writer knows, regardless of project domain.
- **Resume-driven stack pick.** Same shape as resume-driven architecture, applied to tech bundle.
- **Bundle incompatibility.** Frontend-backend-data-hosting-observability picks that fail the pairing-rules check.
- **Migration-cost ignored.** No "what does it take to leave this bundle" answer.
- **Single-domain stack across all domains.** The Next.js-Postgres-Vercel stack proposed for healthcare, finance, edge IoT, ML training, mobile-only.
- **Bundle without scale ceiling.** No statement of "this bundle works up to N users / requests / engineers and then needs replacement."

### Tier 2.1 (repo) have-nots

- **Maximum-files-everywhere.** Every project gets every file regardless of stage and audience. Weekend CLI gets GOVERNANCE.md and a 39-point audit.
- **Placeholder-in-production.** Files scaffolded with TODO/lorem-ipsum that never get filled in. Worse than no file: signals an unmaintained project.
- **Stack-detection skipped.** Same scaffold for every stack. Node-shaped scaffold dropped onto a Python project.
- **AGENTS.md collision.** repo-ready overwrites an existing AGENTS.md instead of respecting it.
- **CI workflow that does not run.** The .github/workflows/*.yml file is present but the build fails on a fresh clone.
- **README that does not describe the project.** Generic README with no project-specific content.
- **License absent.** OSS distribution without a LICENSE file.
- **SECURITY.md absent.** Public repo without a vulnerability-reporting channel.

### Tier 2.2 (production / app) have-nots

- **Hollow dashboard.** Database-API-Auth scaffold, no feature wired end-to-end.
- **Hollow button.** UI element present, no backend behind it. "Save" that doesn't save.
- **Fake data.** Lorem-ipsum, faker.js, hardcoded JSON in production code paths.
- **Missing states.** Feature has happy path; loading, empty, error, partial, success states absent.
- **TODO/FIXME in shipped slice.** Production code has unresolved markers.
- **Permission check absent.** Endpoint runs without a permission check; UI surfaces hide what the API permits.
- **Data viz with fake data.** Chart renders synthetic data, not real backend output.
- **DESIGN.md ignored.** Project root has DESIGN.md; the build does not consume it.
- **Real-backend-not-stubbed broken.** Feature claims end-to-end-wired but uses a mock instead of the real backend.
- **Slice not demo-able.** A "completed" slice that an actual user cannot do an actual job with.

### Tier 3.1 (deploy) have-nots

- **Different-artifact-per-environment.** Build runs separately in staging and prod. The same hash does not promote.
- **Code-only rollback for data-forward change.** "Rollback: redeploy previous image" written next to a schema migration.
- **Single-deploy expand-contract.** Schema change attempted in one deploy on a populated database.
- **Paper canary.** "Canary" label on a deploy step with no stop rule, no metrics watched, no automatic abort.
- **First-deploy ad-hoc.** First production deploy bypasses the checklist; "we'll formalize the pipeline later."
- **Secrets in repo.** Any value that should be vault-fetched is present in version control.
- **Environment parity drift unrecorded.** Staging and prod differ silently. The diff is not documented.
- **Rollback never tested.** Rollback path exists in the runbook but has never been executed.
- **Migration calendar invisible.** Multi-deploy migration with no calendar showing the deploy sequence and the contract step.

### Tier 3.2 (observe) have-nots

- **Paper SLO.** Numbers with no error-budget policy. "p95 latency < 200ms" with no statement of what happens when it breaches.
- **Blind dashboard.** Charts bound to no SLO. Decoration metrics above the fold.
- **Paper runbook.** Written once, never executed. Cannot be run by an on-call engineer cold.
- **Alert that does not page on real fires.** Pageable alert that has not fired in months when incidents have shipped.
- **Cause-based alerting.** Alerts that fire on internal causes ("queue depth > X") instead of user-visible symptoms.
- **Tracing not propagated.** Spans terminate at service boundaries; cross-service traces broken.
- **Logging without correlation IDs.** Logs cannot be joined to a request trace.
- **Error tracking off.** No Sentry/Bugsnag/Honeybadger; uncaught exceptions invisible.
- **Vendor lock without exit plan.** Observability vendor chosen without a "what if we leave" answer.
- **Independence of telemetry from app.** Observability runs out-of-band; if the app is down, the telemetry is also down.

### Tier 3.3 (launch) have-nots

- **AI-slop landing.** Hero, feature cards, sub-hero produced by an LLM with no substitution-test pass. Reads the same as competitors.
- **Hero-fatigue copy.** "Empower your team with AI-powered productivity." Substitution test fails in one sentence.
- **Spec-sheet positioning.** Feature list where positioning belongs.
- **Paper waitlist.** Waitlist UI present; the email funnel does not actually deliver to launch day.
- **Unrendered OG card.** OG meta tags present; the card does not render in actual previews (Slack, iMessage, Twitter, LinkedIn).
- **Silent launch.** Signups arrive on launch day; source attribution is absent. Cannot tell which channel converted.
- **Launch without channel plan.** Product Hunt / Show HN / Reddit / X / IH / dev.to / LinkedIn ad-hoc'd day-of.
- **Press kit absent.** Outreach without a press kit means the journalist has to assemble it.
- **Post-launch transition unwritten.** Launch-week ends; the next-week motion is not defined.
- **Substitution test failed on a card.** Any of the six feature cards fails the substitution test.

### Tier 3.4 (harden) have-nots

- **Scanner-only security.** "Snyk passed; we are secure." Veracode 2025: 45% of AI code has at least one OWASP Top 10 bug despite scanner-clean.
- **Paper trust boundary.** Boundary declared in architecture document; absent in code or configuration.
- **Hardening as ritual.** Annual pen test, nothing between.
- **Compliance without security.** Checklist green; the app is still adversarially exploitable.
- **Shallow-audit trap.** Only finds what tools surface; OWASP categories not walked manually.
- **CVE-of-the-week patching.** Reactive to disclosed CVEs; no class-of-issue investigation.
- **"Accepted risk" without owner or expiration.** Scanner finding marked accepted; no owner named, no expiration date.
- **Compliance control unmapped.** SOC 2 / HIPAA / PCI / GDPR control claimed; no specific code/config evidence.
- **Pen test, no retest.** Findings reported; remediation never verified.
- **SECURITY.md absent.** No responsible-disclosure channel. Researchers route through whatever email they can find.
- **Bug bounty program with no triage SLA.** Reports come in; no commitment on response time.
- **Post-incident fixes are instance, not class.** "We fixed THIS bug" without "what class of bug was it."

## Tier completion gates

A gate must pass before the next tier begins. Skips are recorded; silence is not a skip.

| Gate | Passes when |
|---|---|
| Tier 0 -> Tier 1 | Mode detected; PROGRESS.md initialized; intent captured (Mode A) or gap identified (Mode B) or audit target identified (Mode C). |
| Tier 1.1 -> Tier 1.2 | `.prd-ready/PRD.md` exists, non-empty; three-label test passes on every sentence; substitution test passes on Problem and Target User; sign-off recorded; downstream handoff block filled. |
| Tier 1.2 -> Tier 1.3 | `.architecture-ready/ARCH.md` exists, non-empty; every box/arrow/ADR has a flip point; substitution test passes on component names and rationales; trust boundaries mapped to specific files/configs; component dependency graph in `.architecture-ready/HANDOFF.md`. |
| Tier 1.3 -> Tier 1.4 | `.roadmap-ready/ROADMAP.md` exists, non-empty; every row labeled (commitment, direction, open question); every commitment grounded in upstream artifact; parallel tracks <= team size; handoff section filled. |
| Tier 1.4 -> Tier 2 | `.stack-ready/DECISION.md` exists, non-empty; weights stated; flip points named; pairing-rules check clean; migration paths documented; ADRs cross-linked to architecture. |
| Tier 2.1 -> Tier 2.2 | Repo scaffolded for the detected stack and project profile; README is project-specific; CI runs and passes on a fresh clone; AGENTS.md exists; no placeholder-in-production files. |
| Tier 2.2 -> Tier 3 | Slice queue from roadmap is processed; every shipped slice is end-to-end-wired; no-scaffold-no-placeholder grep clean; `.production-ready/STATE.md` records progress. |
| Tier 3.1 -> Tier 3.2 | Pipeline promotes the same artifact through environments; expand/contract calendars exist for data-forward changes; canary stop rules are concrete; rollback paths proven; secrets vault-injected. |
| Tier 3.2 -> Tier 3.3 / 3.4 | Every charted/alerted/SLOed number bound to a journey; error-budget policy declared with owner; runbooks executed at least once; alerts have real-recent-fire history. |
| Tier 3.3 -> Done | Substitution test passes on hero, sub-hero, every card, OG card, Show HN title, launch email subject; OG card renders in three preview surfaces; waitlist has source attribution; launch-day telemetry implemented (not stubbed). |
| Tier 3.4 -> Done | Every OWASP category has a verdict with evidence; every compliance control mapped to specific implementation; every accepted risk has owner and expiration; findings actionable per `references/shipping/actionable-findings.md`; critical-finding gate to launch resolved. |
| Arc -> Done | All in-scope tiers verified-done or recorded-skip; PROGRESS.md complete-block written; AGENTS.md emitted (or existing-respected); next-step orchestrator named for ongoing operations. |

## Reference files: load on demand

The reference catalog is organized by tier. Load on demand per the workflow above. Eighty-plus files at ~5-15K each preserves the agent attention budget; loading them all at once is a known anti-pattern.

### Orchestration

| File | When to load |
|---|---|
| `references/orchestration/handoff-protocols.md` | Step 0.1, 1.x, 2.x, 3.x. Per-harness invocation patterns. |
| `references/orchestration/progress-tracking.md` | Step 0.2, 0.3, 0.5. PROGRESS.md schema, status vocabulary, resume protocol. |
| `references/orchestration/scope-fence.md` | Step 0.4 always; on demand otherwise. Boundary catalog. |
| `references/orchestration/sequencing-rules.md` | Step 0.3, Step 1, Step 2, Step 3. Tier dependency rules, parallelism, gate logic. |
| `references/orchestration/kickoff-antipatterns.md` | On demand during verification. |
| `references/orchestration/agents-md-template.md` | Step 0.6 and Step 2.1. The AGENTS.md template arc-ready emits when no AGENTS.md exists. |

### Planning

| File | When to load |
|---|---|
| `references/planning/prd-research.md` | Step 1.1 mode detection. |
| `references/planning/prd-anatomy.md` | Step 1.1 structure. |
| `references/planning/prd-antipatterns.md` | Step 1.1 audit and verification. |
| `references/planning/EXAMPLE-PRD.md` | Step 1.1 calibration. |
| `references/planning/problem-framing.md` | Step 1.1 sub-step 3. |
| `references/planning/user-personas.md` | Step 1.1 sub-step 4. |
| `references/planning/success-criteria.md` | Step 1.1 sub-step 5. |
| `references/planning/requirements.md` | Step 1.1 sub-steps 6, 7. |
| `references/planning/scope-and-out-of-scope.md` | Step 1.1 sub-step 8. |
| `references/planning/risks-and-assumptions.md` | Step 1.1 sub-step 9. |
| `references/planning/stakeholder-alignment.md` | Step 1.1 sub-step 11. |
| `references/planning/iterate-vs-freeze.md` | Step 1.1 sub-step 12. |
| `references/planning/architecture-research.md` | Step 1.2 mode detection. |
| `references/planning/architecture-antipatterns.md` | Step 1.2 audit and verification. |
| `references/planning/EXAMPLE-ARCH.md` | Step 1.2 calibration. |
| `references/planning/system-shape.md` | Step 1.2 sub-step 1. |
| `references/planning/component-breakdown.md` | Step 1.2 sub-step 2. |
| `references/planning/data-architecture.md` | Step 1.2 sub-step 3. |
| `references/planning/integration-architecture.md` | Step 1.2 sub-step 4. |
| `references/planning/non-functional-architecture.md` | Step 1.2 sub-step 5. |
| `references/planning/trust-boundaries.md` | Step 1.2 sub-step 6. |
| `references/planning/adr-discipline.md` | Step 1.2 sub-step 7. |
| `references/planning/diagrams.md` | Step 1.2 sub-step 8. |
| `references/planning/evolutionary-architecture.md` | Step 1.2 sub-step 9. |
| `references/planning/roadmap-research.md` | Step 1.3 mode detection. |
| `references/planning/roadmap-anatomy.md` | Step 1.3 structure. |
| `references/planning/roadmap-antipatterns.md` | Step 1.3 audit and verification. |
| `references/planning/EXAMPLE-ROADMAP.md` | Step 1.3 calibration. |
| `references/planning/cadence-models.md` | Step 1.3 sub-step 2. |
| `references/planning/dependency-graph.md` | Step 1.3 sub-steps 1, 3. |
| `references/planning/risk-driven-prioritization.md` | Step 1.3 sub-step 4. |
| `references/planning/sequencing-principles.md` | Step 1.3 sub-step 5. |
| `references/planning/scope-vs-time.md` | Step 1.3 sub-step 6. |
| `references/planning/launch-sequencing.md` | Step 1.3 sub-step 7. |
| `references/planning/review-cadence.md` | Step 1.3 sub-step 8. |
| `references/planning/handoff-to-execution.md` | Step 1.3 sub-step 9. |
| `references/planning/stack-research.md` | Step 1.4 mode detection. |
| `references/planning/stack-antipatterns.md` | Step 1.4 audit and verification. |
| `references/planning/EXAMPLE-STACK.md` | Step 1.4 calibration. |
| `references/planning/preflight-and-constraints.md` | Step 1.4 sub-step 1. |
| `references/planning/domain-stacks.md` | Step 1.4 sub-step 2. |
| `references/planning/scoring-framework.md` | Step 1.4 sub-step 3. |
| `references/planning/dimension-deep-dives.md` | Step 1.4 sub-step 3. |
| `references/planning/stack-bundles.md` | Step 1.4 sub-step 3. |
| `references/planning/pairing-rules.md` | Step 1.4 sub-step 4. |
| `references/planning/tradeoff-narratives.md` | Step 1.4 sub-step 5. |
| `references/planning/migration-paths.md` | Step 1.4 sub-step 6. |

### Building

| File | When to load |
|---|---|
| `references/building/repo-structure.md` | Step 2.1 sub-step 3. |
| `references/building/repo-audit.md` | Step 2.1 Mode B audit. |
| `references/building/repo-antipatterns.md` | Step 2.1 verification. |
| `references/building/audit-mode.md` | Step 2.1 Mode B. |
| `references/building/community-standards.md` | Step 2.1 sub-step 5. |
| `references/building/community-governance.md` | Step 2.1 sub-step 5. |
| `references/building/readme-craft.md` | Step 2.1 sub-step 4. |
| `references/building/ci-cd-workflows.md` | Step 2.1 sub-step 7. |
| `references/building/quality-tooling.md` | Step 2.1 sub-step 8. |
| `references/building/git-workflows.md` | Step 2.1 sub-step 9. |
| `references/building/licensing-legal.md` | Step 2.1 sub-step 10. |
| `references/building/monorepo-patterns.md` | Step 2.1 sub-step 17. |
| `references/building/multi-repo-suite-layout.md` | Step 2.1 Mode D. |
| `references/building/onboarding-dx.md` | Step 2.1 sub-step 12. |
| `references/building/platform-github.md` | Step 2.1 sub-step 7 (GitHub). |
| `references/building/platform-gitlab.md` | Step 2.1 sub-step 7 (GitLab). |
| `references/building/platform-bitbucket.md` | Step 2.1 sub-step 7 (Bitbucket). |
| `references/building/project-profiles.md` | Step 2.1 sub-step 2. |
| `references/building/release-distribution.md` | Step 2.1 sub-step 13. |
| `references/building/security-setup.md` | Step 2.1 sub-step 11. |
| `references/building/technical-docs.md` | Step 2.1 sub-step 6. |
| `references/building/questioning.md` | Step 2.1 pre-flight. |
| `references/building/agent-safety.md` | Step 2.1 sub-step 18. |
| `references/building/production-antipatterns.md` | Step 2.2 verification. |
| `references/building/preflight-and-verification.md` | Step 2.2 pre-flight. |
| `references/building/codebase-research.md` | Step 2.2 existing-codebase mode. |
| `references/building/ui-design-patterns.md` | Step 2.2 sub-step 2. |
| `references/building/design-md-integration.md` | Step 2.2 sub-step 3. |
| `references/building/states-and-feedback.md` | Step 2.2 sub-step 4. |
| `references/building/data-layer.md` | Step 2.2 sub-step 5. |
| `references/building/auth-and-rbac.md` | Step 2.2 sub-step 6. |
| `references/building/headers-and-navigation.md` | Step 2.2 sub-step 7. |
| `references/building/information-architecture.md` | Step 2.2 sub-step 8. |
| `references/building/naming.md` | Step 2.2 sub-step 9. |
| `references/building/domain-considerations.md` | Step 2.2 sub-step 10. |
| `references/building/performance-and-security.md` | Step 2.2 sub-step 11. |
| `references/building/api-and-integrations.md` | Step 2.2 sub-step 12. |
| `references/building/data-visualization.md` | Step 2.2 sub-step 13. |
| `references/building/analytics-and-telemetry.md` | Step 2.2 sub-step 14. |
| `references/building/animation-and-motion.md` | Step 2.2 sub-step 15. |
| `references/building/ai-product-patterns.md` | Step 2.2 sub-step 16. |
| `references/building/accessibility-deep-dive.md` | Step 2.2 sub-step 17. |
| `references/building/dark-mode-deep-dive.md` | Step 2.2 sub-step 18. |
| `references/building/email-template-design.md` | Step 2.2 sub-step 26. |
| `references/building/error-pages-and-offline.md` | Step 2.2 sub-step 19. |
| `references/building/expansion-and-scalability.md` | Step 2.2 sub-step 20. |
| `references/building/file-management-and-uploads.md` | Step 2.2 sub-step 21. |
| `references/building/internationalization.md` | Step 2.2 sub-step 22. |
| `references/building/login-and-auth-pages.md` | Step 2.2 sub-step 23. |
| `references/building/marketing-and-landing-pages.md` | Step 2.2 sub-step 24. |
| `references/building/migration-and-data-import.md` | Step 2.2 sub-step 25. |
| `references/building/notifications-and-email.md` | Step 2.2 sub-step 26. |
| `references/building/payments-and-billing.md` | Step 2.2 sub-step 27. |
| `references/building/realtime-and-collaboration.md` | Step 2.2 sub-step 28. |
| `references/building/reporting.md` | Step 2.2 sub-step 29. |
| `references/building/security-deep-dive.md` | Step 2.2 sub-step 11. |
| `references/building/seo-and-web-standards.md` | Step 2.2 sub-step 30. |
| `references/building/settings-and-configuration.md` | Step 2.2 sub-step 31. |
| `references/building/social-media-features.md` | Step 2.2 sub-step 32. |
| `references/building/system-integration.md` | Step 2.2 sub-step 33. |
| `references/building/testing-and-quality.md` | Step 2.2 sub-step 34. |
| `references/building/workflows-and-actions.md` | Step 2.2 sub-step 35. |

### Shipping

| File | When to load |
|---|---|
| `references/shipping/deploy-research.md` | Step 3.1 mode detection. |
| `references/shipping/deploy-antipatterns.md` | Step 3.1 verification. |
| `references/shipping/preflight-and-gating.md` | Step 3.1 sub-step 1. |
| `references/shipping/pipeline-patterns.md` | Step 3.1 sub-step 2. |
| `references/shipping/environment-parity.md` | Step 3.1 sub-step 3. |
| `references/shipping/first-deploy-checklist.md` | Step 3.1 sub-step 4. |
| `references/shipping/deployment-topologies.md` | Step 3.1 sub-step 5. |
| `references/shipping/zero-downtime-migrations.md` | Step 3.1 sub-step 6. |
| `references/shipping/progressive-delivery.md` | Step 3.1 sub-step 7. |
| `references/shipping/rollback-playbook.md` | Step 3.1 sub-step 8. |
| `references/shipping/secrets-injection.md` | Step 3.1 sub-step 9. |
| `references/shipping/observe-research.md` | Step 3.2 mode detection. |
| `references/shipping/observe-antipatterns.md` | Step 3.2 verification. |
| `references/shipping/slo-design.md` | Step 3.2 sub-step 1. |
| `references/shipping/metrics-taxonomy.md` | Step 3.2 sub-step 2. |
| `references/shipping/logging-patterns.md` | Step 3.2 sub-step 3. |
| `references/shipping/tracing.md` | Step 3.2 sub-step 4. |
| `references/shipping/error-tracking.md` | Step 3.2 sub-step 5. |
| `references/shipping/alert-patterns.md` | Step 3.2 sub-step 6. |
| `references/shipping/dashboards.md` | Step 3.2 sub-step 7. |
| `references/shipping/incident-response.md` | Step 3.2 sub-step 8. |
| `references/shipping/post-mortem.md` | Step 3.2 sub-step 9. |
| `references/shipping/vendor-landscape.md` | Step 3.2 sub-step 10. |
| `references/shipping/launch-research.md` | Step 3.3 mode detection. |
| `references/shipping/launch-antipatterns.md` | Step 3.3 verification. |
| `references/shipping/positioning-and-copy.md` | Step 3.3 sub-step 1. |
| `references/shipping/landing-page-anatomy.md` | Step 3.3 sub-step 2. |
| `references/shipping/seo-fundamentals.md` | Step 3.3 sub-step 5. |
| `references/shipping/social-share-cards.md` | Step 3.3 sub-step 6. |
| `references/shipping/waitlist-and-email.md` | Step 3.3 sub-step 7. |
| `references/shipping/launch-channels.md` | Step 3.3 sub-step 8. |
| `references/shipping/launch-week-runbook.md` | Step 3.3 sub-step 9. |
| `references/shipping/launch-telemetry.md` | Step 3.3 sub-step 10. |
| `references/shipping/press-and-outreach.md` | Step 3.3 sub-step 11. |
| `references/shipping/post-launch-transition.md` | Step 3.3 sub-step 12. |
| `references/shipping/harden-research.md` | Step 3.4 mode detection. |
| `references/shipping/harden-antipatterns.md` | Step 3.4 verification. |
| `references/shipping/owasp-walkthrough.md` | Step 3.4 sub-steps 1-3. |
| `references/shipping/compliance-frameworks.md` | Step 3.4 sub-step 4. |
| `references/shipping/auth-hardening.md` | Step 3.4 sub-step 5. |
| `references/shipping/api-hardening.md` | Step 3.4 sub-step 6. |
| `references/shipping/crypto-primitives.md` | Step 3.4 sub-step 7. |
| `references/shipping/pentest-prep.md` | Step 3.4 sub-step 8. |
| `references/shipping/responsible-disclosure.md` | Step 3.4 sub-step 9. |
| `references/shipping/post-incident-hardening.md` | Step 3.4 sub-step 10. |
| `references/shipping/actionable-findings.md` | Step 3.4 sub-step 11. |
| `references/shipping/security-tooling-landscape.md` | Step 3.4 sub-step 12. |

### Shared

| File | When to load |
|---|---|
| `references/shared/RESEARCH-2026-04.md` | On demand for citations and prior-art. The consolidated source-citations file. |
| `references/shared/ORCHESTRATORS.md` | When integrating with GSD, BMAD, Spec Kit, Superpowers, or other orchestrators. |

## Suite membership

arc-ready is a single skill, not a suite. It is the consolidated successor to the eleven-skill aihxp/ready-suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready). The eleven-skill version remains available for users who prefer the multi-repo footprint; arc-ready is the recommended starting point for new projects.

The transition is documented in `MIGRATION.md`. Briefly: every named failure mode, every grep test, every workflow guard from the eleven skills exists in arc-ready under the corresponding tier folder. The artifact paths (`.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, etc.) are unchanged. The dogfood (`aihxp/ready-suite-example`) verifies cleanly against arc-ready's tier dispatch.

## Consumes from upstream

arc-ready has no upstream skills. It triggers from raw user intent and reads from disk to detect the import mode.

When the agent starts, it inventories existing arc artifacts and adjusts the dispatch:

| If present | Effect | Recorded as |
|---|---|---|
| `.prd-ready/PRD.md` | Skip Tier 1.1; verify import; advance to 1.2 | `1.1: imported` in PROGRESS.md |
| `.architecture-ready/ARCH.md` | Skip 1.2; verify; advance | `1.2: imported` |
| `.roadmap-ready/ROADMAP.md` | Skip 1.3; verify; advance | `1.3: imported` |
| `.stack-ready/DECISION.md` | Skip 1.4; verify; advance | `1.4: imported` |
| Repo scaffolding presence (README.md, .github/workflows/*.yml, .repo-ready/SECURITY.md) | Skip 2.1; verify scaffolding; advance | `2.1: imported` |
| `.production-ready/STATE.md` | Skip 2.2; verify | `2.2: imported` |
| `.deploy-ready/STATE.md` | Skip 3.1; verify | `3.1: imported` |
| `.observe-ready/STATE.md` | Skip 3.2; verify | `3.2: imported` |
| `.launch-ready/STATE.md` | Skip 3.3; verify | `3.3: imported` |
| `.harden-ready/FINDINGS.md` | Skip 3.4; verify | `3.4: imported` |

If an imported artifact is present but the user wants to re-run the tier (because the input changed), the user explicitly invokes the tier and PROGRESS.md is rolled back from that point forward. Re-invocation is a recorded event, not silent overwrite.

## Produces for downstream

arc-ready produces the arc artifacts at canonical `.<tier>-ready/` paths. Downstream orchestrators (GSD, BMAD, Spec Kit, plain harnesses) consume these artifacts directly.

| Artifact | Path | Tier |
|---|---|---|
| Kickoff/arc progress ledger | `.arc-ready/PROGRESS.md` | Tier 0 |
| Product Requirements | `.prd-ready/PRD.md` (+ HANDOFF.md, AUDIT.md) | Tier 1.1 |
| Architecture | `.architecture-ready/ARCH.md` (+ HANDOFF.md, adr/NNN-*.md) | Tier 1.2 |
| Roadmap | `.roadmap-ready/ROADMAP.md` (+ HANDOFF.md, retrospectives/) | Tier 1.3 |
| Stack decision | `.stack-ready/DECISION.md` (or STACK.md) | Tier 1.4 |
| Repo scaffold report | `.repo-ready/AUDIT-REPORT.md`, plus the scaffolded files at repo root | Tier 2.1 |
| Production state | `.production-ready/STATE.md` | Tier 2.2 |
| Deploy state | `.deploy-ready/STATE.md` (+ runbook/, calendar/) | Tier 3.1 |
| Observe state | `.observe-ready/STATE.md` (+ runbook/, dashboards/) | Tier 3.2 |
| Launch state | `.launch-ready/STATE.md` (+ runbook/, copy/) | Tier 3.3 |
| Hardening findings | `.harden-ready/FINDINGS.md` (+ remediation/) | Tier 3.4 |
| Cross-tool agent brief | `AGENTS.md` at project root (+ symlink `CLAUDE.md` -> `AGENTS.md`) | Tier 0 / 2.1 |

The artifact paths are stable. Downstream consumers can hard-code these paths and trust them. arc-ready does not move or rename artifacts as it evolves; the eleven-skill suite established the contract, and arc-ready preserves it.

## Session state and resume

The arc spans sessions. The planning tier alone can span days. The building tier can span weeks. The full arc routinely spans a month or more. Without a state file, every resume rediscovers the chain from scratch.

Maintain `.arc-ready/PROGRESS.md` as the source of truth about the arc. Read it first on every turn. If it conflicts with disk (artifacts present that PROGRESS.md does not record, or PROGRESS.md says done for a tier whose artifact is missing), trust disk and update PROGRESS.md.

Each tier's intermediate state lives in the tier's `.<tier>-ready/STATE.md` file. PROGRESS.md is the arc-level summary; the per-tier STATE files are the deep state.

The schema is in `references/orchestration/progress-tracking.md`. The resume protocol is the load-bearing defense against phantom resume. Run it every turn. Never trust the cached conversation about what tier or sub-step we are on.

## Handoff: ongoing operations is not arc-ready's job

arc-ready is one-shot per project. The arc is idea -> launch and hardening; what comes after the arc (sprint-by-sprint feature work, ongoing security hardening, ongoing observability tuning, ongoing roadmap re-planning) is the project's ongoing motion.

Hand off to a phase orchestrator after the arc completes. Options include:

- **GSD** (`gsd-*` slash commands in Claude Code): phase-based orchestration with discuss / plan / execute / verify / ship loops.
- **BMAD**: agile-method orchestration with explicit story and milestone management.
- **Spec Kit**: spec-driven development with intent / specification / plan / tasks loops.
- **Superpowers**: skill composition with brainstorm / plan / implement / verify loops.
- **The user's own process.** No orchestrator required; the artifacts at `.<tier>-ready/` paths are stable enough that any process can consume them.

The arc-ready / orchestrator boundary: arc-ready owns the arc. The orchestrator owns the iteration loop after the arc. PROGRESS.md is the handoff contract. See `references/shared/ORCHESTRATORS.md` for the integration patterns.

## Keep going until the arc is actually done

The arc completes when every in-scope tier has either a verified-done status or a recorded-skip. Silence is not a status; the absence of a tier from PROGRESS.md is itself a have-not (silence-as-skip). Every tier either runs or is explicitly recorded as skipped with reason.

If at any point arc-ready feels the urge to "just sketch" what a tier would produce instead of running the tier, the urge is the failure mode. The right answer is to run the sub-step or to surface the skip and continue. Every line arc-ready writes that is not arc orchestration metadata or a tier sub-step's defined output is a step toward becoming the god-skill the arc-ready discipline exists to prevent.

The first inline content from arc-ready that should have come from a tier sub-step is the next thing to refuse.
