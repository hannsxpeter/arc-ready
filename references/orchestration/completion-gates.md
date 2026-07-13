# Completion and Release Gates

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Tier completion gates

A gate must pass before the next tier begins. Skips are recorded; silence is not a skip.

| Gate | Passes when |
|---|---|
| Tier 0 -> Tier 1 | Mode detected; PROGRESS.md initialized; intent captured (Mode A) or gap identified (Mode B) or audit target identified (Mode C). |
| Tier 1.1 -> Tier 1.2 | `.prd-ready/PRD.md` exists, non-empty; three-label test passes on every sentence; substitution test passes on Problem and Target User; sign-off recorded; downstream handoff block filled. |
| Tier 1.2 -> Tier 1.3 | `.architecture-ready/ARCH.md` exists, non-empty; every box/arrow/ADR has a flip point; substitution test passes on component names and rationales; trust boundaries mapped to specific files/configs; component dependency graph in `.architecture-ready/HANDOFF.md`. |
| Tier 1.3 -> Tier 1.4 | `.roadmap-ready/ROADMAP.md` exists, non-empty; every row labeled (commitment, direction, open question); every commitment grounded in upstream artifact; parallel tracks <= team size; handoff section filled. |
| Tier 1.4 -> Tier 2 | `.stack-ready/STACK.md` exists, non-empty; weights stated; flip points named; pairing-rules check clean; migration paths documented; ADRs cross-linked to architecture. |
| Tier 2.1 -> Tier 2.2 | Repo scaffolded for the detected stack and project profile; README is project-specific; CI runs and passes on a fresh clone; Pillars-compatible AGENTS.md and floor pillars exist or adoption is blocked with reason; no placeholder-in-production files. |
| Tier 2.2 -> Tier 3 | Slice queue from roadmap is processed; every shipped slice is end-to-end-wired; no-scaffold-no-placeholder grep clean; `.production-ready/STATE.md` records progress. |
| Tier 3.1 -> Tier 3.2 | Pipeline promotes the same artifact through environments; expand/contract calendars exist for data-forward changes; canary stop rules are concrete; rollback paths proven; secrets vault-injected. |
| Tier 3.2 -> Tier 3.3 / 3.4 | Installation-ready evidence exists: every charted/alerted/SLOed number is bound to a journey; error-budget policy has an owner; runbooks are executed; alert delivery fires end to end through the production-equivalent path. Operational-maturity evidence is tracked separately and cannot be invented. |
| Tier 3.3 -> Launch assets ready | Substitution test passes on hero, sub-hero, every card, OG card, Show HN title, launch email subject; OG card renders in three preview surfaces; waitlist has source attribution; launch-day telemetry implemented (not stubbed). This status does not authorize publication. |
| Tier 3.4 -> Done | Every OWASP category has a verdict with evidence; every compliance control mapped to specific implementation; every accepted risk has owner and expiration; findings actionable per `references/shipping/actionable-findings.md`; critical-finding gate to launch resolved. |
| Pre-publication -> Public activation | `.launch-ready/PREPUBLICATION.md` records a pass, `checked_at` is later than the latest hardening update, the checked hardening revision matches disk, and no unresolved gate-blocking finding exists. |
| Arc -> Done | All in-scope tiers verified-done or recorded-skip; PROGRESS.md complete-block written; Pillars-compatible AGENTS.md and floor pillars emitted, existing-respected, or blocked with reason; next-step orchestrator named for ongoing operations. |

### Tier 3.2 evidence states

Observability has two distinct evidence states:

1. `installation-ready`: telemetry, SLOs, error-budget policy, dashboards, alert routes, and runbooks are installed. At least one controlled production-equivalent signal has exercised detection, page delivery, ownership, and the linked runbook end to end. Label controlled fires as synthetic.
2. `operationally-mature`: a recent real service event has exercised the alert and produced tuning evidence, or the project records that this evidence is not yet available. Never rewrite a controlled fire as real incident history.

Tier 3.2 can authorize launch asset preparation and hardening after `installation-ready`. Record operational maturity in `.observe-ready/STATE.md`. If neither a real recent fire nor a controlled production-equivalent fire exists, Tier 3.2 remains `in-flight`. Public activation policy may require operational maturity for regulated or high-risk systems.

## Critical-finding gate (Tier 3.4 -> Tier 3.3)

If harden-ready (Tier 3.4) emits a finding at severity Critical, arc-ready may continue launch asset preparation but blocks public activation until one of:

1. The finding is resolved (fix landed; retest passed; verified in `.harden-ready/FINDINGS.md`).
2. The user explicitly accepts the risk in `.arc-ready/PROGRESS.md` with: named risk owner, justification, dated acceptance, expiration date.
3. Public activation is removed from scope. A prototype with no real user surface may record hardening as skipped, but it cannot use that skip to authorize a public release.

The gate is the default. Security-sensitive projects (healthcare, finance, regulated industries) have an additional override locked: even with risk acceptance, public activation remains gated. The override flag is `gate-launch-on-hardening: hard` in PROGRESS.md.

### Timestamped pre-publication recheck

Immediately before a public release action:

1. Read `.harden-ready/FINDINGS.md` and `.harden-ready/STATE.md` from disk again.
2. Record a content hash or revision for the checked hardening artifacts.
3. Count unresolved Critical findings and validate every permitted acceptance for owner, justification, acceptance date, and expiration.
4. Write `.launch-ready/PREPUBLICATION.md` with `checked_at`, `hardening_revision`, finding counts, policy, and `verdict: pass|block`.
5. Require `checked_at` to be later than the latest hardening update.
6. Invalidate the gate whenever hardening artifacts change. Recheck before retrying publication.

Launch work can therefore proceed in parallel without allowing a late Critical to race behind an already prepared release.

The grep test:

```bash
# Canonical FINDINGS.md finding shape: a `severity: <level>` line immediately
# followed by a `status: <state>` line (matches the actionable-findings format
# and the dogfood-smoke fixture). The gate scans FORWARD from each Critical to
# read its status; using `-B 1` here would read the line above severity and the
# gate would never fire.
critical_count=$(grep -cE '^severity: critical$' .harden-ready/FINDINGS.md)
if [ "$critical_count" -gt 0 ]; then
  unresolved=$(grep -A 1 'severity: critical' .harden-ready/FINDINGS.md | grep -cE '^status: (open|wip)')
  accepted=$(grep -A 5 'risk-acceptance:' .arc-ready/PROGRESS.md | grep -c '^owner:')
  if [ "$unresolved" -gt 0 ] && [ "$accepted" -lt "$unresolved" ]; then
    echo "[block] launch held by critical-finding gate"
  fi
fi
```

This gate is one of the most important integrity properties of the arc. Skipping it or publishing from a stale gate is a Tier-0 have-not (critical-finding gate breach).
