# Sequencing rules: the dependency DAG arc-ready encodes

This file defines the order arc-ready invokes the ten arc-ready tiers, the parallelism rules, the harden-ready gate logic, and the skip-detection semantics. The DAG is the single most important data structure in arc-ready. Encoded declaratively here; referenced by SKILL.md Steps 3, 4, and 5.

The full chain verification with citations is in `references/shared/RESEARCH-2026-04.md` Section 5.

## The DAG

```
prd-ready
   |
   v
architecture-ready
   |
   +---> roadmap-ready ---+
   |                       |
   +---> stack-ready  ----+
                          |
                          v
                       repo-ready (pairs production-ready)
                          |
                          v
                       production-ready
                          |
                          v
                       deploy-ready
                          |
                          v
                       observe-ready
                          |
                          +---> launch-ready -----+
                          |                       |
                          +---> harden-ready -----+ (parallel; harden-ready
                                                    Critical findings gate
                                                    launch-ready completion)
```

Topological order: prd-ready, architecture-ready, (roadmap-ready, stack-ready), repo-ready, production-ready, deploy-ready, observe-ready, (launch-ready, harden-ready). Two pairs of nodes are technically parallelizable (roadmap-ready and stack-ready in planning; launch-ready and harden-ready in shipping). Production reality, parallelism rules, and gate logic are below.

## Per-tier upstream contract

This is the data arc-ready uses to verify the ghost-handoff guard. Before invoking a tier, arc-ready confirms every entry in its upstream column exists on disk.

| Step | Tier | Upstream artifacts (must exist before invocation) | Primary artifact (arc-ready verifies after) |
|---|---|---|---|
| 1 | prd-ready | (none) | `.prd-ready/PRD.md` |
| 2 | architecture-ready | `.prd-ready/PRD.md` | `.architecture-ready/ARCH.md` |
| 3 | roadmap-ready | `.prd-ready/PRD.md`, `.architecture-ready/ARCH.md` | `.roadmap-ready/ROADMAP.md` |
| 4 | stack-ready | `.prd-ready/PRD.md`, `.architecture-ready/ARCH.md` (recommended; not required) | `.stack-ready/DECISION.md` |
| 5 | repo-ready | (none formally; benefits from `.stack-ready/DECISION.md`) | Repo scaffolding presence: README.md at repo root AND any of (`.github/workflows/*.yml`, `.gitlab-ci.yml`, `.editorconfig`, `.repo-ready/SECURITY.md`). repo-ready does not produce a single canonical STATE.md; verification is a multi-file scaffolding check. |
| 6 | production-ready | `.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, `.roadmap-ready/ROADMAP.md`, `.stack-ready/DECISION.md` | `.production-ready/STATE.md` |
| 7 | deploy-ready | `.production-ready/STATE.md`, `.stack-ready/DECISION.md`, repo scaffolding (per row 5) | `.deploy-ready/STATE.md` |
| 8 | observe-ready | `.production-ready/STATE.md`, `.stack-ready/DECISION.md`, `.deploy-ready/STATE.md`, repo scaffolding (per row 5) | `.observe-ready/STATE.md` |
| 9 | launch-ready | `.production-ready/STATE.md`, `.stack-ready/DECISION.md`, `.deploy-ready/STATE.md`, `.observe-ready/STATE.md` | `.launch-ready/STATE.md` |
| 10 | harden-ready | `.architecture-ready/ARCH.md`, `.production-ready/STATE.md`, `.deploy-ready/STATE.md`, `.observe-ready/STATE.md`, `.repo-ready/SECURITY.md` (the specific repo-ready file harden-ready consumes) | `.harden-ready/STATE.md` and `.harden-ready/FINDINGS.md` |

The upstream lists come directly from each tier's `upstream:` frontmatter and "Consumes from upstream" sections. Two notes on the rough edges this dogfood walk surfaced:

1. **stack-ready and repo-ready declare graceful-degradation.** Their frontmatter `upstream:` lists are empty (or stack-ready has no field), but the per-skill body documents recommended upstream reads. Within arc-ready, we keep them in the documented order to maximize artifact quality.
2. **repo-ready does not produce a single STATE.md.** Its outputs are top-level repo files (README.md, CI workflows, .editorconfig, etc.) and `.repo-ready/SECURITY.md` (the file harden-ready consumes). arc-ready's verification gate for repo-ready is a multi-file scaffolding check, not a single-file existence check. The "Post-invocation checks" section below codifies the multi-file pattern for tiers whose primary artifact is plural.

## Parallelism rules

### 4.1 Building tier: repo-ready and production-ready

Both list `pairs_with` each other. They write to different paths primarily (repo-ready: top-level files, CI workflows, package.json scripts; production-ready: src/, app/, the actual feature code). The exception is `package.json` itself, which both touch.

**Default: sequential.** repo-ready first, then production-ready. Reasons:

1. **Cognitive cost.** Two agent sessions writing to the same repo simultaneously is hard for a human to supervise. A sequential pass is reviewable in one PR per tier.
2. **package.json merge.** Sequential avoids the merge problem entirely.
3. **Better production-ready output.** A properly-scaffolded repo (with lint config, CI, test runner, devcontainer) makes production-ready's output materially better. The reverse order produces an app on a half-configured repo.

**Optional advanced parallel mode.** A user with two harness sessions and the operational discipline to handle a package.json merge can run repo-ready and production-ready concurrently. Document this in PROGRESS.md as `parallelism: building-tier-concurrent` and accept the merge cost. arc-ready will not initiate the parallel mode by default.

### 4.2 Shipping tier: launch-ready and harden-ready

Both consume the same shipping-tier inputs (deployed app, monitored app). Neither lists the other as upstream.

**Default: parallel with critical-finding gate.** harden-ready and launch-ready run concurrently after observe-ready completes. The critical-finding gate (Section 5 below) is the only synchronization point.

**Reasons for parallel default:**

- harden-ready's `pairs_with: [deploy-ready, observe-ready, launch-ready]` declares it is designed to run alongside, not as a launch gate.
- The shipping tier already takes long enough; serializing harden-ready and launch-ready doubles the wall-clock time without proportional benefit.
- Most projects benefit from a soft-launch (private alpha, invite-only beta) running concurrently with adversarial review, with a hard public-launch gate when a Critical finding lands.

**Override option 1: gate-launch-on-hardening.** For security-sensitive projects (healthcare, finance, regulated industries), the user can declare in PROGRESS.md `harden_gate: launch-blocked-until-clean`. Then launch-ready does not start until harden-ready emits a clean (no-Critical, no-High) report.

**Override option 2: skip harden-ready.** For one-day prototypes with no real user surface (internal demo, single-use proof-of-concept, throwaway script), the user can declare `harden-ready: skipped` with reason. PROGRESS.md records the skip explicitly. The skip is an audit-visible decision, not silence.

### 4.3 Planning tier: roadmap-ready and stack-ready

Both consume `.prd-ready/PRD.md` and `.architecture-ready/ARCH.md`. Neither consumes the other.

**Default: sequential.** roadmap-ready first, then stack-ready. Reasons:

1. The roadmap shapes which stack decisions matter. A two-week roadmap weights "ship fast" stack picks; a six-month roadmap weights "compound on the framework choice" stack picks.
2. Sequential keeps planning-tier output reviewable in a single PR.

The two are technically parallelizable; arc-ready does not initiate parallel by default, but a user with a clear separation of concerns can run them concurrently.

## Critical-finding gate logic

The gate exists because harden-ready is the only tier whose output can require arc-ready to halt a tier that is already in-flight (launch-ready). Every other tier boundary is an upstream dependency, not a synchronization gate.

### Gate inputs

- `.harden-ready/FINDINGS.md` (or equivalent, per harden-ready's schema). The findings file lists each finding with severity (Critical, High, Medium, Low, Info).
- launch-ready status in PROGRESS.md (in-flight, done, or pending).

### Gate algorithm

```
On every arc-ready turn during shipping tier:
  1. Read .harden-ready/FINDINGS.md if present.
  2. Identify Critical findings with status != Closed.
  3. If any Critical findings are open:
     a. If launch-ready is in-flight or done:
        - Halt launch-ready (or note the violation if already done).
        - Surface the finding to the user.
        - Require either:
          (i) the finding to move to Closed (the fix lands and is verified),
              OR
          (ii) an explicit risk acceptance in PROGRESS.md with named risk
               owner, justification, and dated acceptance per the
               harden-ready risk-register pattern.
     b. If launch-ready is pending:
        - Block launch-ready start until (i) or (ii) above.
  4. If no Critical findings are open: launch-ready proceeds normally.
```

### Gate override

The `gate-launch-on-hardening` mode (Section 4.2 override 1) extends the gate to High findings as well. The `skip harden-ready` mode disables the gate entirely (since there are no findings to gate on).

### Risk acceptance schema

When the user explicitly accepts a Critical finding to proceed, PROGRESS.md gets a row in the `## Risk acceptances` section (per `references/orchestration/progress-tracking.md`). The acceptance is dated, named, justified, and time-bounded. Without all four, the acceptance is not valid and the gate remains active.

## Skip-detection semantics

A skip is a recorded decision, not silence. The Shape Up "no-gos" discipline (research Section 3.3) is the model.

### When skips are detected

1. **Step 2 declaration.** The user declares skips during kickoff intent capture. ("Skip launch-ready; this is internal-only.")
2. **Mid-arc declaration.** The user changes their mind during the chain. ("On second thought, skip harden-ready; the prototype is throwaway.") PROGRESS.md is updated; downstream effects are noted.
3. **Implicit skip via override.** The `skip harden-ready` and `skip launch-ready` modes from Section 4.2 are explicit overrides that produce skip rows.

### Skip cascade rules

When a tier is skipped, downstream tiers that depend on its artifact must either:

a. **Refuse to run** (raise an error; the user must un-skip the upstream or skip the downstream too). This applies when the upstream artifact is structurally required.

b. **Proceed with implicit defaults** (the downstream tier falls back to its graceful-degradation behavior). This applies when the upstream artifact is recommended but not required (stack-ready and repo-ready, per their frontmatter).

The cascade table:

| If skipped | Downstream effect |
|---|---|
| prd-ready | architecture-ready cannot run (refuse). User must un-skip prd-ready or skip architecture-ready and downstream. |
| architecture-ready | roadmap-ready, production-ready, harden-ready cannot run cleanly (refuse). |
| roadmap-ready | production-ready works with degraded slice queue (proceed with note). |
| stack-ready | repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready proceed with the user's existing stack choice (proceed with note). |
| repo-ready | production-ready, deploy-ready, observe-ready proceed but lose repo-hygiene benefits (proceed with note). |
| production-ready | deploy-ready, observe-ready, launch-ready, harden-ready cannot run (refuse). The app does not exist to ship. |
| deploy-ready | observe-ready, launch-ready, harden-ready cannot run (refuse). |
| observe-ready | launch-ready, harden-ready proceed with degraded telemetry (proceed with note). |
| launch-ready | (nothing downstream depends; harden-ready unaffected) |
| harden-ready | (nothing downstream depends; launch-ready gate disabled) |

Whenever the cascade is "proceed with note," the note appears in PROGRESS.md row `notes` so the auditor can see what was lost.

## Re-invocation rules

Re-invocation happens when the user changes the input to a tier that has already produced its artifact. The simplest case: the PRD changed; architecture-ready, roadmap-ready, and production-ready may need to re-run.

### Re-invocation trigger

The user explicitly invokes a previously-done tier, or arc-ready detects that the user manually edited an upstream artifact (file mtime is newer than the downstream artifact's `disk_state_hash`).

### Cascade

When tier N is re-invoked, every downstream tier whose upstream includes N is marked `re-invoked` in PROGRESS.md. The user is informed of the cascade and chooses:

a. **Full cascade re-run.** arc-ready re-invokes every cascaded tier in topological order. Costly but correct.

b. **Manual reconciliation.** The user manually edits the downstream artifacts to reflect the new upstream. PROGRESS.md records the manual edit with a note. Cheaper but trusts the user's edit discipline.

c. **Selective re-run.** The user picks which downstream tiers to re-invoke. PROGRESS.md records the choice.

The default is to ask. arc-ready does not auto-cascade re-invocation without confirmation, because re-running the entire shipping tier on a small PRD edit is rarely what the user wants.

### Re-invocation preserves history

The prior `done` row is preserved with status moved to `re-invoked` and a `notes` field pointing to the new row. PROGRESS.md grows monotonically; nothing is deleted.

## Static error checks (Just-style)

Per the Just / Make discipline (research Section 3.4), arc-ready should resolve errors statically before the run begins.

### Pre-flight checks

Run at Step 0:

1. **Tier install check.** For every tier in the DAG, verify the tier is loadable in the current harness. If a tier is not installed:
   - Surface the install instruction (the tier's GitHub URL).
   - Give the user the choice: install now and resume, or skip this tier.
   - Do not silently fail mid-arc.
2. **DAG integrity check.** The encoded DAG should be acyclic. (arc-ready's DAG is hard-coded in this file; the check is a sanity guard against future extensions.)
3. **PROGRESS.md schema check.** If PROGRESS.md exists and the schema does not match the current arc-ready version, the user is informed and a migration path is offered (or the user re-runs from scratch).

### Mid-arc checks

Run before every tier invocation:

1. **Upstream artifact existence.** Per the per-tier upstream contract above. Without all upstream artifacts present, the invocation is refused (ghost-handoff guard).
2. **Tier not already in-flight.** PROGRESS.md should not show two rows in `in-flight` for the same tier.

### Post-invocation checks

Run after every tier invocation:

1. **Artifact existence.** The declared `artifact_path` exists. For tiers with a single canonical artifact (rows 1-4 and 6-10 above), this is one file check. For repo-ready (row 5), the check is multi-file: README.md at repo root must exist AND at least one of (`.github/workflows/*.yml`, `.gitlab-ci.yml`, `.editorconfig`, `.repo-ready/SECURITY.md`) must exist. The PROGRESS.md `artifact_path` field for repo-ready stores the multi-file expression as a string (e.g., `README.md + .github/workflows/`); the verification walks each component.
2. **Artifact non-empty.** Each file in the artifact (single or multi) is larger than the empty template scaffold (size > 100 bytes is a useful default; tiers with tiny canonical artifacts can override).
3. **Artifact mtime is later than invocation timestamp.** Otherwise, the artifact existed before the tier ran (rubber-stamp orchestration risk). For multi-file artifacts, the latest mtime among the files must exceed the invocation timestamp.

If any post-invocation check fails, the row is marked `failed` and the user is informed.

## Why this DAG and not another

The DAG is derived directly from the documented `upstream:` frontmatter of each tier, not from preference. The verification walk (research Section 5.2) confirms every handoff has the artifacts it expects.

Two specific design choices are worth recording:

1. **stack-ready after roadmap-ready, not before architecture-ready.** stack-ready's description explicitly accepts a project with only a one-paragraph idea; it does not require PRD + ARCH + ROADMAP. But within arc-ready's full chain, putting stack-ready after roadmap-ready means the stack decision is informed by the time horizon (the roadmap) and the system shape (the architecture). This produces better stack picks. A user with no PRD and no ARCH can invoke stack-ready directly outside arc-ready; that is graceful degradation, not an arc-ready optimization.

2. **harden-ready in parallel with launch-ready, not before.** harden-ready's `pairs_with: [deploy-ready, observe-ready, launch-ready]` is the load-bearing signal. The skill is designed to run alongside the shipping tier. The critical-finding gate handles the case where adversarial review surfaces a launch-blocking issue.

The full justification for each design choice is in `references/shared/RESEARCH-2026-04.md` Section 5.

## Summary

The DAG is data. The parallelism rules and the gate logic are mechanical. arc-ready encodes them here and follows them per turn. When a new tier joins the arc, the DAG entry is the diff; everything else stays unchanged.
