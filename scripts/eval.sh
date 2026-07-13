#!/usr/bin/env bash
# Deterministic structural evaluations for arc-ready.
# Bash 3.2 compatible.

set -eu

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0

mark_pass() {
  PASS=$((PASS + 1))
  printf "  [ok] %s\n" "$1"
}

mark_fail() {
  FAIL=$((FAIL + 1))
  printf "  [fail] %s\n" "$1"
}

contains_all() {
  file="$1"
  shift
  for expected in "$@"; do
    grep -Fq "$expected" "$file" || return 1
  done
  return 0
}

cd "$REPO_DIR"

printf "Eval 1: Modes A, B, C, and D\n"
if contains_all SKILL.md "| A |" "| B |" "| C |" "| D |"; then
  mark_pass "all four modes are routed"
else
  mark_fail "mode router is incomplete"
fi

printf "Eval 2: dependency-ordered next-step routing\n"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
printf '%s\n' \
  '- 1.1 (PRD): imported' \
  '- 1.2 (ARCH): in-flight' \
  '- 1.3 (ROADMAP): pending' \
  '- 1.4 (STACK): pending' \
  '- 2.1 (REPO): pending' \
  '- 2.2 (PRODUCTION): pending' \
  '- 3.1 (DEPLOY): pending' \
  '- 3.2 (OBSERVE): pending' \
  '- 3.3 (LAUNCH): pending' \
  '- 3.4 (HARDEN): pending' > "$WORK/PROGRESS.md"
next_substep=""
for tier in 1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4; do
  status=$(grep -E "^- ${tier} " "$WORK/PROGRESS.md" | sed -E 's/.*: *([a-z-]+).*/\1/' | head -1)
  case "$status" in
    done|imported|skipped) continue ;;
    *) next_substep="$tier"; break ;;
  esac
done
if [ "$next_substep" = "1.2" ]; then
  mark_pass "dependency router selects architecture"
else
  mark_fail "dependency router selected $next_substep"
fi

printf "Eval 3: disk-drift correction contract\n"
mkdir -p "$WORK/.prd-ready"
printf '# PRD\n' > "$WORK/.prd-ready/PRD.md"
drift=0
[ -s "$WORK/.prd-ready/PRD.md" ] || drift=$((drift + 1))
[ -e "$WORK/.roadmap-ready/ROADMAP.md" ] || drift=$((drift + 1))
if [ "$drift" = "1" ] && grep -Fq "Disk wins" SKILL.md; then
  mark_pass "missing claimed artifact is detected and disk is authoritative"
else
  mark_fail "disk-drift contract is not represented"
fi

printf "Eval 4: canonical artifact contract\n"
artifact_ok=1
for artifact in \
  '.arc-ready/PROGRESS.md' \
  '.prd-ready/PRD.md' \
  '.architecture-ready/ARCH.md' \
  '.roadmap-ready/ROADMAP.md' \
  '.stack-ready/STACK.md' \
  '.repo-ready/SCAFFOLD.md' \
  '.production-ready/STATE.md' \
  '.deploy-ready/DEPLOY.md' \
  '.observe-ready/OBSERVE.md' \
  '.launch-ready/STATE.md' \
  '.harden-ready/FINDINGS.md'; do
  grep -Fq "$artifact" SKILL.md || artifact_ok=0
done
if [ "$artifact_ok" = "1" ]; then
  mark_pass "all stable canonical artifacts remain routed"
else
  mark_fail "canonical artifact map drifted"
fi

printf "Eval 5: product-form routing\n"
if contains_all references/building/product-form-router.md \
  "## Web application" \
  "## API or service" \
  "## CLI or SDK" \
  "## Mobile or desktop" \
  "## Data or ML" \
  "## Infrastructure or IaC"; then
  mark_pass "six required product forms have concerns and gates"
else
  mark_fail "product-form router is incomplete"
fi

printf "Eval 6: domain composition\n"
if contains_all references/building/domain-registry.md \
  "Project form" \
  "Product archetype" \
  "Industry overlay" \
  "Regulatory overlay"; then
  mark_pass "four-axis domain composition is explicit"
else
  mark_fail "domain composition axes are incomplete"
fi

printf "Eval 7: domain and stack registry coverage\n"
registry_rows=$(grep -cE '^\| [0-9]+ \|' references/building/domain-registry.md)
if [ "$registry_rows" = "37" ] && grep -Fq "12 stack profiles" references/building/domain-registry.md; then
  mark_pass "37 build profiles map through the stack registry"
else
  mark_fail "registry rows=$registry_rows, expected 37"
fi

printf "Eval 8: added domain profile completeness\n"
added_ok=1
for profile in \
  references/building/domains/domain-data-analytics-bi.md \
  references/building/domains/domain-manufacturing-mes.md \
  references/building/domains/domain-developer-platform.md \
  references/building/domains/domain-research-lab-lims.md; do
  contains_all "$profile" \
    "**Archetype:**" \
    "**Core entities:**" \
    "**Domain landmines:**" \
    "**Compliance and freshness caveat:**" \
    "**Expected" \
    "**Test and fixture shape:**" \
    "**Stack mapping:**" || added_ok=0
done
if [ "$added_ok" = "1" ]; then
  mark_pass "added profiles contain required product evidence"
else
  mark_fail "an added domain profile is incomplete"
fi

printf "Eval 9: Agent Skills progressive-disclosure budget\n"
skill_lines=$(wc -l < SKILL.md | tr -d ' ')
skill_words=$(wc -w < SKILL.md | tr -d ' ')
if [ "$skill_lines" -lt 500 ] && [ "$skill_words" -lt 5000 ]; then
  mark_pass "SKILL.md is $skill_lines lines and $skill_words words"
else
  mark_fail "SKILL.md exceeds the recommended activation budget"
fi

printf "Eval 10: late Critical blocks public activation\n"
printf '%s\n' \
  'hardening_revision: 2' \
  'severity: critical' \
  'status: open' > "$WORK/FINDINGS.md"
printf '%s\n' \
  'checked_at: 2026-07-13T10:00:00Z' \
  'hardening_revision: 1' \
  'verdict: pass' > "$WORK/PREPUBLICATION.md"
unresolved=$(grep -A 1 '^severity: critical$' "$WORK/FINDINGS.md" | grep -c '^status: open$' || true)
finding_revision=$(awk -F': *' '/^hardening_revision:/{print $2; exit}' "$WORK/FINDINGS.md")
checked_revision=$(awk -F': *' '/^hardening_revision:/{print $2; exit}' "$WORK/PREPUBLICATION.md")
if [ "$unresolved" -gt 0 ] && [ "$finding_revision" != "$checked_revision" ]; then
  mark_pass "late Critical invalidates a stale pre-publication pass"
else
  mark_fail "shipping race simulation did not block"
fi

printf "Eval 11: direct reference integrity\n"
missing=0
for reference in $(grep -oE 'references/[a-z]+/[a-zA-Z0-9_./-]+\.md' SKILL.md | sort -u); do
  [ -f "$reference" ] || missing=$((missing + 1))
done
if [ "$missing" = "0" ]; then
  mark_pass "every direct SKILL.md reference exists"
else
  mark_fail "$missing direct references are missing"
fi

printf "Eval 12: live-harness case coverage\n"
case_count=$(find evals/cases -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
case_ok=1
for phrase in "Mode A" "Mode B" "Mode C" "Mode D" "disk drift" "Critical" "artifact contract" "product form" "domain composition" "official validator"; do
  grep -Rqi "$phrase" evals/cases || case_ok=0
done
if [ "$case_count" -ge 10 ] && [ "$case_ok" = "1" ]; then
  mark_pass "$case_count live-harness cases cover the required behaviors"
else
  mark_fail "live-harness case coverage is incomplete"
fi

printf "Eval 13: current OWASP web routing\n"
if contains_all references/shipping/owasp-web-top-10-2025.md \
  "A01:2025 Broken Access Control" \
  "A03:2025 Software Supply Chain Failures" \
  "A09:2025 Security Logging and Alerting Failures" \
  "A10:2025 Mishandling of Exceptional Conditions" && \
  grep -Fq "owasp-web-top-10-2025.md" references/shipping/shipping-workflow.md; then
  mark_pass "current OWASP Top 10:2025 categories are routed"
else
  mark_fail "current OWASP Top 10:2025 routing is incomplete"
fi

printf "Eval 14: unambiguous state and maturity contracts\n"
if contains_all references/orchestration/progress-tracking.md \
  "arc_mode: <A | B | C | D>" \
  "session_kind: <new | resume | import>" \
  'deploy-ready | `.deploy-ready/DEPLOY.md`' \
  'observe-ready | `.observe-ready/OBSERVE.md`' && \
  ! grep -Fq "mode: <new | resume | import>" references/orchestration/progress-tracking.md && \
  contains_all references/orchestration/completion-gates.md \
    "installation-ready" \
    "operationally-mature" \
    "Never rewrite a controlled fire as real incident history"; then
  mark_pass "mode, primary artifacts, and observability maturity are unambiguous"
else
  mark_fail "state or maturity contracts are ambiguous"
fi

TOTAL=$((PASS + FAIL))
if [ "$VERBOSE" = "1" ]; then
  printf "Evaluated %s deterministic cases.\n" "$TOTAL"
fi
if [ "$FAIL" = "0" ]; then
  printf "== eval suite passed: %s/%s ==\n" "$PASS" "$TOTAL"
  exit 0
fi

printf "== eval suite FAILED: %s/%s (%s failures) ==\n" "$PASS" "$TOTAL" "$FAIL"
exit 1
