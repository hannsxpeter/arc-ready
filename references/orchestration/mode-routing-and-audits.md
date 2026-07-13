# Mode Routing and Audits

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Mode B: existing-codebase routing

Mode B fires when the user's project already has one or more arc artifacts on disk and they want to fill a gap rather than run the full arc. The Tier 0 detection step inventories the `.<tier>-ready/` directories and routes to the smallest tier-set that closes the gap.

### Mode B decision tree

Start at the inventory and walk the tree:

1. **No `.prd-ready/PRD.md`?** Route to Tier 1.1. The PRD is the upstream of every other planning artifact; without it, downstream work has no grounding. (Exception: the user explicitly says "I have an external PRD; here is the path." Treat as Mode A import.)
2. **PRD exists; no `.architecture-ready/ARCH.md`?** Route to Tier 1.2.
3. **PRD + ARCH exist; no `.roadmap-ready/ROADMAP.md`?** Route to Tier 1.3.
4. **PRD + ARCH + ROADMAP exist; no `.stack-ready/STACK.md` (or `DECISION.md`)?** Route to Tier 1.4.
5. **All planning artifacts exist; repo not scaffolded (no README, no `.github/workflows/`)?** Route to Tier 2.1.
6. **Repo scaffolded; no `.production-ready/STATE.md` and no end-to-end-wired feature?** Route to Tier 2.2.
7. **App built; no deploy pipeline (no `.deploy-ready/DEPLOY.md`, no `.github/workflows/deploy*.yml`)?** Route to Tier 3.1.
8. **Deploy works; no SLOs (no `.observe-ready/OBSERVE.md` or `SLOs.md`)?** Route to Tier 3.2.
9. **App deployed and observed; user wants public launch (no `.launch-ready/STATE.md`)?** Route to Tier 3.3.
10. **App deployed; user wants pre-launch security review (no `.harden-ready/FINDINGS.md`)?** Route to Tier 3.4.

The decision tree honors dependency order. Skipping ahead (e.g., scaffolding the repo before the PRD exists) is allowed only with an explicit user override and a recorded `Mode B override:` note in `.arc-ready/PROGRESS.md`. Otherwise the prior gap is filled first.

### Mode B routing examples

| Existing state | Gap | Route |
|---|---|---|
| PRD only | Architecture, roadmap, stack | Tier 1.2 first; user may chain to 1.3 and 1.4 |
| PRD + ARCH + half-built app | Roadmap, stack settled by code, deploy missing | Tier 1.3 (slice queue), then Tier 3.1 |
| Repo scaffolded but no PRD | Planning entirely | Tier 1.1; treat the existing repo as input to Tier 2.1's stack detection |
| Deployed app, no observability | SLO design, runbooks | Tier 3.2 only |
| Deployed app, post-incident | Class-not-instance hardening | Tier 3.4 with focus on `references/shipping/post-incident-hardening.md` |
| Public launch needed for a private-pilot product | Launch surface | Tier 3.3 only; Tier 3.4 already done |

### Mode B refusal

If the user requests a tier whose upstream is absent, refuse and route. "You're asking me to design the architecture, but `.prd-ready/PRD.md` does not exist. Either run Tier 1.1 first, or declare an explicit Mode B override with the PRD-equivalent assumptions inline." Ghost-handoff is a Tier-0 failure mode; Mode B routing is its prevention.

## Mode C: retroactive audit

Mode C fires when the user wants to verify an already-produced artifact against arc-ready's discipline. The output is `<TIER>-AUDIT.md` at the canonical artifact path with severity-classified findings, no source-artifact modifications. The user runs the audit, reads the findings, and decides whether to remediate (which may invoke Mode B) or accept the findings as risk.

### Per-tier audit procedure

Each tier has a dedicated audit protocol in its `references/<tier>/<skill>-antipatterns.md` file. The shape is consistent across tiers:

1. **Run the named-pattern grep tests.** Each pattern in the antipatterns catalog has a grep target that is mechanically detectable in the artifact. Run all grep tests.
2. **Run the substitution test** on user-facing claims (PRD problem and target-user; architecture component names and rationales; roadmap commitments; stack rationales; landing-page hero/cards; security claims).
3. **Run the three-label test** on every sentence (PRD), every row (roadmap), every box and arrow (architecture), every score (stack), every metric (observe), every finding (harden).
4. **Score severity per finding.** The standard severity vocabulary: Critical (artifact fails the tier's gate; do not advance), High (artifact passes the gate but a load-bearing claim is shaky), Medium (style or formatting issue), Low (typo or polish).
5. **Write `<TIER>-AUDIT.md` at the canonical artifact path** with: total findings, breakdown by severity, per-finding entry (location, excerpt, named pattern, severity, remediation), and a verdict line (PASS / PASS WITH FINDINGS / BLOCK).
6. **Do not modify the source artifact.** Mode C is read-only on the artifact under audit.

### Audit-output canonical paths

| Tier | Audit output |
|---|---|
| 1.1 (PRD) | `.prd-ready/AUDIT.md` |
| 1.2 (architecture) | `.architecture-ready/AUDIT.md` |
| 1.3 (roadmap) | `.roadmap-ready/AUDIT.md` |
| 1.4 (stack) | `.stack-ready/AUDIT.md` |
| 2.1 (repo) | `.repo-ready/AUDIT-REPORT.md` |
| 2.2 (production / app) | `.production-ready/AUDIT.md` |
| 3.1 (deploy) | `.deploy-ready/AUDIT.md` |
| 3.2 (observe) | `.observe-ready/AUDIT.md` |
| 3.3 (launch) | `.launch-ready/AUDIT.md` |
| 3.4 (harden) | `.harden-ready/AUDIT.md` (or the `FINDINGS.md` for a fresh audit pass) |

### Audit verdict semantics

- **PASS**: zero Critical, zero High. Artifact passes the tier's gate without remediation.
- **PASS WITH FINDINGS**: zero Critical; some High. Artifact technically passes the gate, but the High findings are load-bearing risks the user should remediate before relying on the artifact downstream.
- **BLOCK**: at least one Critical. Artifact does not pass the tier's gate. Downstream tiers cannot proceed until the Critical findings are resolved or explicitly accepted with named-owner risk-acceptance entries.

The verdict is the audit's load-bearing output. A PASS WITH FINDINGS audit is not a clean bill of health; it is a signed-off "passes the bar with documented warts." The user reading the audit must understand which interpretation applies.

## Mode D: multi-repo suite layout

Mode D fires when the user is designing a collection of related repositories that will pair as a suite (a multi-skill collection, a microservice cluster, a monorepo split, a multi-app product family).

The Mode D pattern is documented in `references/building/multi-repo-suite-layout.md`. It is the generalization of the discipline that produced the eleven-skill hannsxpeter/ready-suite itself. arc-ready inherits the pattern reference for users who need to scaffold a different multi-repo collection beyond arc-ready.

The Mode D dispatch:

1. **Determine the collection shape.** Hub-and-spoke (one hub repo, N spoke repos), peer-cluster (N equal-rank repos), or monorepo-with-published-packages. Load `references/building/multi-repo-suite-layout.md` section 1.
2. **Decide what is byte-identical across repos.** Common: a SUITE.md or COLLECTION.md, a CONTRIBUTING.md, a SECURITY.md. The byte-identical-collection-map invariant is enforced by lint, not by convention.
3. **Decide what is per-repo.** Each repo's own SKILL.md (if it is a skill collection), its own CHANGELOG.md, its own README.md.
4. **Coordinated patch ritual.** When a change affects multiple repos, the maintainer runs the change in a defined order with the lint as the gate. Document this ritual in MAINTAINING.md per `references/building/multi-repo-suite-layout.md` section 5.
5. **Versioning and tagging.** Each repo carries its own semver; coordinated breaking changes get matching minor or major bumps. Tag-release parity is checked across repos.
6. **Hub vs specialist split.** The hub does not have a version of its own (it is the discovery surface); specialists do.

Mode D is rare. arc-ready's primary modes are A, B, and C. If the user asks for "a suite of skills" or "a collection of microservices" without a current arc-ready arc context, route to Mode D.
