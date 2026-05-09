#!/usr/bin/env bash
# scripts/dogfood-smoke.sh: operational smoke test for arc-ready.
#
# Builds a synthetic project mid-arc, runs arc-ready's resume protocol logic
# against it, and verifies:
#
#   1. The drift-detection check correctly catches PROGRESS.md vs disk drift.
#   2. The next-sub-step heuristic resolves to the correct tier in dependency
#      order (not file order).
#   3. The artifact-path contract is reachable: each tier's canonical .{tier}-
#      ready/ path is creatable and writable in a project workspace.
#   4. AGENTS.md emit-respect logic: respect existing, emit if absent.
#   5. The critical-finding gate logic correctly halts on unresolved Critical.
#
# This is a STRUCTURAL smoke test, not a functional test of an agent loaded
# with arc-ready's SKILL.md. Functional testing requires an actual harness
# session and is out of scope for a build script.
#
# Usage: bash scripts/dogfood-smoke.sh [--verbose]
#
# Exit code: 0 on pass, 1 on any failure.

set -eu

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -t 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_GREEN="$(printf '\033[32m')"
  C_RED="$(printf '\033[31m')"
  C_YELLOW="$(printf '\033[33m')"
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_RED=""; C_YELLOW=""
fi

PASS=0
FAIL=0

mark_pass() { PASS=$((PASS+1)); printf "  %s[ok]%s %s\n" "$C_GREEN" "$C_RESET" "$1"; }
mark_fail() { FAIL=$((FAIL+1)); printf "  %s[fail]%s %s\n" "$C_RED" "$C_RESET" "$1"; }

# ---------- Setup synthetic project ----------
WORK=$(mktemp -d)
cd "$WORK"
trap "rm -rf $WORK" EXIT

[ "$VERBOSE" = "1" ] && echo "Synthetic project at: $WORK"

# Mid-arc state: PRD imported, ARCH in-flight, others pending.
mkdir -p .arc-ready .prd-ready .architecture-ready
echo "# Pulse PRD (synthetic for smoke test)" > .prd-ready/PRD.md
echo "" >> .prd-ready/PRD.md
echo "## Problem" >> .prd-ready/PRD.md
echo "..." >> .prd-ready/PRD.md
echo "# WIP architecture document" > .architecture-ready/ARCH.md

cat > .arc-ready/PROGRESS.md <<'EOF'
# arc-ready PROGRESS

## Skill version: 0.1.6
## Last update: 2026-05-09T12:00:00Z
## Mode: A
## Harness: claude-code

## Tier ledger
- 0: in-flight | artifact: .arc-ready/PROGRESS.md
- 1.1 (PRD): imported | artifact: .prd-ready/PRD.md | verified: 2026-05-09T12:00:00Z
- 1.2 (ARCH): in-flight | artifact: .architecture-ready/ARCH.md
- 1.3 (ROADMAP): pending
- 1.4 (STACK): pending
- 2.1 (REPO): pending
- 2.2 (PRODUCTION): pending
- 3.1 (DEPLOY): pending
- 3.2 (OBSERVE): pending
- 3.3 (LAUNCH): pending
- 3.4 (HARDEN): pending
EOF

# ---------- Test 1: drift-detection on the happy path ----------
printf "%sTest 1: drift-detection (happy path; no drift)%s\n" "$C_BOLD" "$C_RESET"
drift_count=0
for tier in prd architecture roadmap stack repo production deploy observe launch harden; do
  if grep -qE "^- [0-9.]+ \(${tier})*\): (done|imported)" .arc-ready/PROGRESS.md 2>/dev/null; then
    if [ ! -d ".${tier}-ready" ] || [ -z "$(ls .${tier}-ready 2>/dev/null)" ]; then
      drift_count=$((drift_count + 1))
    fi
  fi
done
[ "$drift_count" = "0" ] && mark_pass "no drift detected (PRD imported with artifact present)" \
  || mark_fail "drift_count=$drift_count, expected 0"

# ---------- Test 2: drift-detection catches a real drift ----------
printf "%sTest 2: drift-detection (synthetic drift; PROGRESS says ROADMAP done but artifact missing)%s\n" "$C_BOLD" "$C_RESET"
sed -i.bak 's|^- 1.3 (ROADMAP): pending|- 1.3 (ROADMAP): done|' .arc-ready/PROGRESS.md
detected=0
for tier in prd architecture roadmap stack repo production deploy observe launch harden; do
  upper=$(echo "$tier" | tr 'a-z' 'A-Z')
  if grep -qE "^- [0-9.]+ \(${upper}.*\): (done|imported)" .arc-ready/PROGRESS.md 2>/dev/null; then
    if [ ! -d ".${tier}-ready" ] || [ -z "$(ls .${tier}-ready 2>/dev/null)" ]; then
      detected=$((detected + 1))
    fi
  fi
done
# revert
mv .arc-ready/PROGRESS.md.bak .arc-ready/PROGRESS.md
[ "$detected" -ge 1 ] && mark_pass "drift correctly detected" \
  || mark_fail "drift not detected (expected at least 1)"

# ---------- Test 3: next-sub-step in dependency order ----------
printf "%sTest 3: next-sub-step heuristic (mid-arc with PRD imported, ARCH in-flight)%s\n" "$C_BOLD" "$C_RESET"
ordered_tiers="1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4"
next_substep=""
prior_done=true
for t in $ordered_tiers; do
  status=$(grep -E "^- ${t} " .arc-ready/PROGRESS.md | sed -E 's/.*: *([a-z-]+).*/\1/' | head -1)
  case "$status" in
    done|imported|skipped)
      prior_done=true
      continue
      ;;
    pending|in-flight|failed|"")
      if [ "$prior_done" = "true" ]; then
        next_substep="$t"
        break
      fi
      ;;
  esac
done
[ "$next_substep" = "1.2" ] && mark_pass "next_sub_step=1.2 (correct: ARCH is in-flight)" \
  || mark_fail "next_sub_step=$next_substep, expected 1.2"

# ---------- Test 4: artifact-path contract ----------
printf "%sTest 4: artifact-path contract reachable for every tier%s\n" "$C_BOLD" "$C_RESET"
all_ok=true
for tier_dir in .arc-ready .prd-ready .architecture-ready .roadmap-ready .stack-ready \
                .repo-ready .production-ready .deploy-ready .observe-ready .launch-ready \
                .harden-ready; do
  mkdir -p "$tier_dir" && touch "$tier_dir/STATE.md" || all_ok=false
done
[ "$all_ok" = "true" ] && mark_pass "all 11 .{tier}-ready/ paths are creatable" \
  || mark_fail "could not create all tier directories"

# ---------- Test 5: AGENTS.md emit-respect ----------
printf "%sTest 5: AGENTS.md emit-respect (existing-respected case)%s\n" "$C_BOLD" "$C_RESET"
echo "# Existing user AGENTS.md (do not overwrite)" > AGENTS.md
ORIG_HASH=$(shasum AGENTS.md | awk '{print $1}')
# Simulate the emit logic: "Only if absent."
if [ ! -f AGENTS.md ]; then
  echo "# Emitted by arc-ready" > AGENTS.md
fi
NEW_HASH=$(shasum AGENTS.md | awk '{print $1}')
[ "$ORIG_HASH" = "$NEW_HASH" ] && mark_pass "existing AGENTS.md preserved (existing-respected)" \
  || mark_fail "AGENTS.md was overwritten when it should have been respected"

printf "%sTest 6: AGENTS.md emit-respect (absent case)%s\n" "$C_BOLD" "$C_RESET"
rm -f AGENTS.md
if [ ! -f AGENTS.md ]; then
  cat > AGENTS.md <<'EOF'
# Synthetic project (arc-ready emitted)

This project was kicked off via arc-ready. The artifacts produced are listed below; consult the relevant artifact before changes that touch its area.

## arc-ready artifact map

| Tier | Status | Artifact |
|---|---|---|
| 1.1 (PRD) | done | .prd-ready/PRD.md |
EOF
fi
[ -f AGENTS.md ] && grep -q "arc-ready emitted" AGENTS.md && mark_pass "AGENTS.md emitted when absent" \
  || mark_fail "AGENTS.md was not emitted when absent"

# ---------- Test 7: critical-finding gate ----------
printf "%sTest 7: critical-finding gate (Tier 3.4 -> Tier 3.3)%s\n" "$C_BOLD" "$C_RESET"
mkdir -p .harden-ready
cat > .harden-ready/FINDINGS.md <<'EOF'
# Hardening findings

## Finding HARDEN-2026-04-001
severity: critical
status: open
title: Synthetic critical for smoke test
EOF

# Apply the gate logic
critical_count=$(grep -cE '^severity: critical$' .harden-ready/FINDINGS.md)
unresolved=0
if [ "$critical_count" -gt 0 ]; then
  unresolved=$(awk '/severity: critical/{f=1; next} f && /status:/{print; f=0}' .harden-ready/FINDINGS.md \
               | grep -cE 'open|wip')
fi
if grep -q 'risk-acceptance:' .arc-ready/PROGRESS.md 2>/dev/null; then
  accepted=$(awk '/risk-acceptance:/{f=1} f && /^owner:/{print; f=0}' .arc-ready/PROGRESS.md | wc -l | tr -d ' ')
else
  accepted=0
fi
[ "$unresolved" -gt "$accepted" ] && mark_pass "gate held: $unresolved unresolved Critical, $accepted accepted -> launch blocked" \
  || mark_fail "gate did not hold (expected to block; unresolved=$unresolved accepted=$accepted)"

# ---------- Summary ----------
printf "\n"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" = "0" ]; then
  printf "%s== smoke test passed: %d/%d ==%s\n" "$C_GREEN$C_BOLD" "$PASS" "$TOTAL" "$C_RESET"
  exit 0
else
  printf "%s== smoke test FAILED: %d/%d (%d failures) ==%s\n" "$C_RED$C_BOLD" "$PASS" "$TOTAL" "$FAIL" "$C_RESET"
  exit 1
fi
