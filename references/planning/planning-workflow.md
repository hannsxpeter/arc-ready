# Planning Workflow

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

### Tier 1: Planning

The planning tier produces four artifacts in dependency order: `.prd-ready/PRD.md` (what), `.architecture-ready/ARCH.md` (how), `.roadmap-ready/ROADMAP.md` (when), `.stack-ready/STACK.md` (with what tools). Each gates the next.

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
8. **Decision artifact.** Ranked shortlist with scores, weighted rationale, named flip points. Output `.stack-ready/STACK.md`.

The worked example is `references/planning/EXAMPLE-STACK.md`.

**Passes when:** every score has stated weights the user can override; every recommendation has a named flip point; the bundle pairs (frontend, backend, data, hosting, observability, etc.) compose without compatibility-violating overlap; the migration path is documented. The artifact at `.stack-ready/STACK.md` is non-empty and the have-nots check returns clean.
