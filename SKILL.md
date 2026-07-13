---
name: arc-ready
description: "Plan, build, ship, and audit software across the full idea-to-launch arc: PRD, architecture, roadmap, stack, repo, implementation, deploy, observability, launch, and hardening. Use for greenfield kickoff, brownfield gap filling, retroactive artifact audits, multi-repo suites, or requests to write a PRD, design architecture, choose a stack, scaffold a repo, build a web app, API, CLI/SDK, mobile or desktop app, data/ML system, or infrastructure project, add CI/CD or SLOs, launch a product, or run an OWASP or compliance review. Routes by product form, archetype, industry, and regulatory overlay; preserves stable tier artifact paths; enforces disk-backed completion, upstream grounding, vertical slices, real backends, tested rollback, and a hardening recheck immediately before public release."
license: MIT
compatibility: "Works with Agent Skills compatible file-system agents. Chat-only clients can use guidance mode."
metadata:
  version: "1.1.0"
  updated: "2026-07-13"
  changelog: "CHANGELOG.md"
  tier: "arc"
  predecessor: "hannsxpeter/ready-suite"
  compatible-with: "claude-code,codex,cursor,windsurf,antigravity,pi,openclaw,any-agentskills-compatible-harness"
---

# arc-ready

arc-ready routes software work across the idea-to-launch arc while preserving the artifact contract established by the eleven-skill ready-suite. Keep orchestration in this file. Load detailed workflow, examples, schemas, grep tests, and catalogs only when the routed work needs them.

## Non-negotiable discipline

1. Every artifact element is a grounded decision with rationale, a labeled hypothesis with a validation plan, or a named open question with an owner and due date.
2. Run the substitution test on user-facing claims, architecture rationales, roadmap commitments, stack recommendations, launch copy, and security claims. If a near-equivalent product or choice can replace the subject without making the claim false, the element is not specific enough.
3. Downstream commitments cite upstream artifacts. Ungrounded work is cut or routed back upstream.
4. Disk is authoritative. A tier is complete only when its canonical artifact exists, is non-empty, is not an unmodified scaffold, and passes its gate.
5. Silence is not a skip. Every in-scope tier is `pending`, `in-flight`, `done`, `skipped`, `imported`, `failed`, or `re-invoked` in `.arc-ready/PROGRESS.md`.
6. Scope leak is refused and routed. arc-ready does not silently perform work outside the selected arc tier.

Load [core orchestration](references/orchestration/core-orchestration.md) for the full principles, scope fence, Tier 0 procedures, AGENTS.md rules, and completion behavior. Load the [failure-mode catalog](references/orchestration/failure-mode-catalog.md) when verifying any tier.

## The have-nots

The canonical have-nots list is the load-on-demand [failure-mode catalog](references/orchestration/failure-mode-catalog.md). Its tier-specific references preserve every inherited named pattern, grep signal, severity, and remediation without loading the full catalog during activation.

## Start or resume every turn

1. Read `.arc-ready/PROGRESS.md` when present.
2. Inventory every canonical `.<tier>-ready/` directory and verify artifacts claimed complete or imported.
3. Correct ledger drift from disk evidence. Disk wins over conversation memory.
4. Detect and record Mode A, B, C, or D.
5. Select project form before selecting domain guidance.
6. Identify the first unfinished dependency-valid tier. Do not dispatch through a missing upstream artifact unless the user records a Mode B override.
7. Record a timestamped resume verification and next sub-step.

Load the [resume protocol](references/orchestration/resume-protocol.md) for the Bash 3.2-compatible drift and next-step procedure. Load the [artifact and state contract](references/orchestration/artifact-contract.md) for imports, status vocabulary, and per-tier state schemas.

## Mode router

| Mode | Use when | Dispatch |
|---|---|---|
| A | Greenfield project or full arc from raw intent | Tier 0, then Tiers 1-3 in dependency order |
| B | Existing codebase or a request to fill a specific gap | Smallest dependency-valid tier set that closes the gap |
| C | Read-only retroactive audit of an existing artifact | Tier-specific audit, severity findings, no source-artifact edits |
| D | Multi-repo suite, service collection, or monorepo split | Collection layout first, then per-repo Tier 2 routing |

Record the mode before other work. For decision trees, audit paths, verdict semantics, and Mode D rules, load [mode routing and audits](references/orchestration/mode-routing-and-audits.md). For ambiguous phrases, load [trigger disambiguation](references/orchestration/trigger-disambiguation.md).

## Product-form router

Select exactly one primary project form before domain composition:

| Form | Typical signals | Required reference |
|---|---|---|
| Web application | Browser UI, SaaS, portal, dashboard | [product-form router](references/building/product-form-router.md) |
| API or service | Headless contract, service endpoint, worker | [product-form router](references/building/product-form-router.md) |
| CLI or SDK | Terminal workflow, package, developer library | [product-form router](references/building/product-form-router.md) |
| Mobile or desktop | App stores, native capabilities, offline client | [product-form router](references/building/product-form-router.md) |
| Data or ML | Pipelines, datasets, training, models, analytics | [product-form router](references/building/product-form-router.md) |
| Infrastructure or IaC | Terraform, Kubernetes, platform operations | [product-form router](references/building/product-form-router.md) |

The form router reuses [project profiles](references/building/project-profiles.md) and defines form-specific build concerns and gates. It prevents web-dashboard assumptions from leaking into other forms.

## Domain composition

Compose domain guidance in this order:

1. Project form: delivery shape and build gate.
2. Product archetype: SaaS, marketplace, developer platform, workflow automation, internal tool, or another product pattern.
3. Industry overlay: healthcare, finance, manufacturing, research, education, and other domain rules.
4. Regulatory overlay: only the jurisdictions and frameworks evidenced by the project.

Load the [domain registry](references/building/domain-registry.md) for mappings between build profiles and the 12 stack profiles. Load the [domain router](references/building/domain-considerations.md) and only the directly applicable focused profiles. Regulatory and vendor details are freshness-sensitive; verify current obligations and provider capabilities before making a grounded commitment.

## Tier routing

### Tier 0: orchestration

Detect harness and mode, capture Mode A intent, maintain the progress ledger, enforce the scope fence, and emit or respect Pillars-compatible project memory. Load [core orchestration](references/orchestration/core-orchestration.md), [progress tracking](references/orchestration/progress-tracking.md), and [handoff protocols](references/orchestration/handoff-protocols.md).

### Tier 1: planning

Run in dependency order:

1. PRD at `.prd-ready/PRD.md`.
2. Architecture at `.architecture-ready/ARCH.md`.
3. Roadmap at `.roadmap-ready/ROADMAP.md`.
4. Stack at `.stack-ready/STACK.md`.

Load [planning workflow](references/planning/planning-workflow.md) for all sub-steps and direct reference routes. Planning gates require the three-label test, substitution resistance, grounded dependencies, explicit capacity, weighted stack criteria, flip points, and downstream handoffs.

### Tier 2: building

1. Scaffold the repository for the detected project profile at `.repo-ready/SCAFFOLD.md`, or audit it at `.repo-ready/AUDIT-REPORT.md`.
2. Build end-to-end vertical slices and record `.production-ready/STATE.md`.

Load [building workflow](references/building/building-workflow.md), then the selected [product-form router](references/building/product-form-router.md) section and composed domain profiles. Every shipped slice uses a real backend where the form has one, covers relevant states, enforces permissions at boundaries, contains no placeholders or fake production data, and has form-appropriate tests. For non-UI forms, use the equivalent user-operable slice, such as a CLI command round trip, SDK consumer example, API contract path, pipeline execution, or IaC plan/apply verification.

### Tier 3: shipping

1. Deploy: same-artifact promotion, explicit migration classification, concrete canary stop rules, and proven rollback.
2. Observe: journey-bound SLOs, owned error-budget policy, exercised runbooks, and independent telemetry.
3. Prepare launch assets and hardening in parallel after observe passes.
4. Public activation is serial and gated. Immediately before any public release action, re-read hardening state, record a timestamped pre-publication gate, and block on every unresolved Critical unless the documented policy permits an explicit acceptance. Regulated hard gates cannot be bypassed.

Load [shipping workflow](references/shipping/shipping-workflow.md) for detailed sub-steps and [completion and release gates](references/orchestration/completion-gates.md) for gate semantics.

## Public activation gate

Launch preparation may finish while hardening continues. A prepared launch is not a published launch.

Immediately before publication:

1. Re-read `.harden-ready/FINDINGS.md` and `.harden-ready/STATE.md` from disk.
2. Confirm the hardening artifact revision or hash being checked.
3. Count unresolved Critical findings and validate any permitted risk acceptance for owner, justification, acceptance date, and expiration.
4. Record `checked_at`, the hardening revision, finding counts, and verdict in `.launch-ready/PREPUBLICATION.md`.
5. Publish only when the verdict is `pass` and the gate timestamp is later than the latest hardening update.
6. If hardening changes after the check, invalidate the gate and re-run it.

This gate closes the launch and hardening race. Load [completion and release gates](references/orchestration/completion-gates.md) for the full Critical-finding rules.

## Canonical artifact contract

| Tier | Canonical artifact |
|---|---|
| 0 | `.arc-ready/PROGRESS.md` |
| 1.1 | `.prd-ready/PRD.md` |
| 1.2 | `.architecture-ready/ARCH.md` |
| 1.3 | `.roadmap-ready/ROADMAP.md` |
| 1.4 | `.stack-ready/STACK.md` |
| 2.1 | `.repo-ready/SCAFFOLD.md` or `.repo-ready/AUDIT-REPORT.md` |
| 2.2 | `.production-ready/STATE.md` |
| 3.1 | `.deploy-ready/DEPLOY.md` |
| 3.2 | `.observe-ready/OBSERVE.md` |
| 3.3 | `.launch-ready/STATE.md` plus `.launch-ready/PREPUBLICATION.md` before public activation |
| 3.4 | `.harden-ready/FINDINGS.md` |
| 0/2.1 | Project-root `AGENTS.md` and Pillars floor files `agents/context.md`, `agents/repo.md` |

Companion artifact names and import aliases remain stable. Load [artifact and state contract](references/orchestration/artifact-contract.md) for the complete map.

## Completion gates

The next tier starts only after the current canonical artifact exists and its tier gate passes. A red test, lint, build, evaluation, deploy check, or unresolved Critical is repair work, not completion. Explicit user skips are recorded with reason.

Use the form-specific build gate plus the common tier gate. Run the detailed checks in [completion and release gates](references/orchestration/completion-gates.md). For mechanical heuristics, load [verification grep tests](references/orchestration/verification-grep-tests.md). Grep tests are signals, not substitutes for the full named-pattern audit.

## Reference routing

Load only the smallest direct set needed for the current tier:

- Core, resume, scope, modes, schemas: [reference routing catalog](references/orchestration/reference-routing.md).
- Planning sub-steps: [planning workflow](references/planning/planning-workflow.md).
- Repo and implementation sub-steps: [building workflow](references/building/building-workflow.md).
- Deploy, observe, launch, harden: [shipping workflow](references/shipping/shipping-workflow.md).
- Product form: [product-form router](references/building/product-form-router.md).
- Domain composition and stack mapping: [domain registry](references/building/domain-registry.md).
- Calibration: [worked examples](references/orchestration/worked-examples.md).
- Harness-specific operation: [harness integration](references/orchestration/harness-integration.md).

References are direct from this file. Do not load the whole catalog.

## Finish

The arc is complete only when every in-scope tier is verified `done`, `imported`, or explicitly `skipped`; the public activation gate passed when publication was in scope; `.arc-ready/PROGRESS.md` contains the final per-tier ledger and open handoffs; and project memory was emitted, respected, or blocked with reason.

Keep going until the disk-backed outcome is actually complete.
