# Verification Grep Tests

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Per-tier inline grep tests

Each tier has mechanical grep tests that an agent can run to verify a gate is passing. These are inline reproductions of the same tests in the per-tier antipatterns catalogs; load the full catalog for the failure-mode interpretation.

### Tier 1.1 (PRD) grep tests

```bash
# Hollow PRD: every R-NN entry must have an acceptance criterion within 3 lines.
grep -nE '^- \*\*R-[0-9]+ \(Must\)' .prd-ready/PRD.md > /tmp/musts.txt
# For each line in musts.txt, check the next 3 lines for "Acceptance:" or equivalent.

# Substitution test: the Problem and Target User sections must contain a named-role
# or named-context noun phrase, not generic adjectives.
awk '/^## Problem/,/^## /' .prd-ready/PRD.md | grep -iE '\b(generic|users|customers|teams|companies)\b' | head

# MoSCoW distribution: at most 50% of entries are Must.
must=$(grep -cE 'R-[0-9]+ \(Must\)' .prd-ready/PRD.md)
total=$(grep -cE 'R-[0-9]+' .prd-ready/PRD.md)
echo "Must: $must / $total"

# Open questions have owner and date.
grep -E '^OQ-[0-9]+' .prd-ready/PRD.md | grep -vE 'owner: [A-Z]|due: 20[0-9]{2}-[0-9]{2}-[0-9]{2}'
```

### Tier 1.2 (architecture) grep tests

```bash
# Every NFR has a number, not an adjective.
grep -E 'p9[59] (latency|response|duration)' .architecture-ready/ARCH.md | grep -vE '<[0-9]+ ?(ms|s)'

# Every component has a flip point in its ADR.
ls .architecture-ready/adr/*.md | while read adr; do
  grep -q '^## Flip point' "$adr" || echo "[fail] $adr missing Flip point"
done

# Trust boundaries map to specific code/configs.
grep -E 'trust boundary' .architecture-ready/ARCH.md | grep -vE '\.(ts|js|py|yml|conf)' | head

# Component dependency graph in HANDOFF.md
test -f .architecture-ready/HANDOFF.md && grep -q 'dependency graph' .architecture-ready/HANDOFF.md
```

### Tier 1.3 (roadmap) grep tests

```bash
# Every commitment references upstream.
grep -E '^- \[(commitment|direction)\]' .roadmap-ready/ROADMAP.md | grep -vE '\(R-[0-9]+\)|\(C-[A-Z]+\)|\(external:'

# Parallel tracks <= team size.
team_size=$(grep -E '^team size:' .roadmap-ready/ROADMAP.md | head -1 | awk '{print $NF}')
max_parallel=$(grep -E '^parallel tracks:' .roadmap-ready/ROADMAP.md | sort -k3 -n | tail -1 | awk '{print $NF}')
[ "$max_parallel" -le "$team_size" ] || echo "[fail] $max_parallel > $team_size"

# No fictional precision: only Now horizon has dated commitments.
grep -A 100 '^## Later' .roadmap-ready/ROADMAP.md | grep -E '20[0-9]{2}-[0-9]{2}-[0-9]{2}' && echo "[fail] dates in Later horizon"
```

### Tier 1.4 (stack) grep tests

```bash
# Every score has a weight.
grep -E '^- (Performance|Cost|DX|Operability)' .stack-ready/STACK.md | grep -vE 'weight: [0-9.]+'

# Every recommendation has a flip point.
grep -E '^## Recommendation' .stack-ready/STACK.md | head -1
grep -A 50 '^## Recommendation' .stack-ready/STACK.md | grep -E 'flip point:' || echo "[fail] no flip point"

# Migration path exists.
grep -q '^## Migration paths' .stack-ready/STACK.md || echo "[fail] no Migration paths section"
```

### Tier 2.1 (repo) grep tests

```bash
# README is non-placeholder.
grep -E 'TODO|FIXME|lorem ipsum' README.md && echo "[fail] placeholder in README"

# CI workflow exists and is non-empty.
test -s .github/workflows/ci.yml || test -s .github/workflows/test.yml || echo "[fail] no CI workflow"

# Pillars loader and floor files exist, unless adoption is blocked in PROGRESS.md.
test -f AGENTS.md || echo "[fail] AGENTS.md missing"
grep -q 'Pillars' AGENTS.md || echo "[fail] AGENTS.md is not Pillars-compatible"
test -f agents/context.md || echo "[fail] agents/context.md missing"
test -f agents/repo.md || echo "[fail] agents/repo.md missing"
grep -E 'pillars: (adopted|adoption-blocked-existing-agents|guidance-text)' .arc-ready/PROGRESS.md || echo "[fail] PROGRESS.md missing Pillars adoption status"

# License is real, not placeholder.
grep -E 'MIT|Apache|GPL|BSD|MPL|EUPL' LICENSE | head -1
```

### Tier 2.2 (production / app) grep tests

```bash
# No placeholder in shipped slice.
git grep -E '\b(TODO|FIXME|XXX|lorem ipsum)\b' -- 'src/**' && echo "[fail] placeholder in shipped code"

# Real-backend-not-stubbed: search for fake-data signatures.
git grep -E 'faker\.|fake_data|hardcoded_response' -- 'src/**' && echo "[fail] fake data in production paths"

# Every API endpoint has a permission check (heuristic).
git grep -lE 'router\.(get|post|put|delete)' src/ | while read f; do
  grep -qE 'requireAuth|withAuth|@authorize' "$f" || echo "[heuristic-fail] $f"
done

# Every page has loading/empty/error states.
git grep -lE 'export default function .*Page' app/ | while read f; do
  grep -qE 'isLoading|isEmpty|isError|<Skeleton|<EmptyState' "$f" || echo "[heuristic-fail] $f"
done
```

### Tier 3.1 (deploy) grep tests

```bash
# Same-artifact promotion: deploy script does not rebuild.
grep -E 'docker build|npm run build' .github/workflows/deploy*.yml && echo "[fail] rebuild during deploy"

# Schema migrations classified.
grep -E '^migration: ' .deploy-ready/DEPLOY.md | grep -vE 'classification: (code-only|data-forward)'

# Canary has stop rule.
grep -A 5 '^## Canary' .deploy-ready/DEPLOY.md | grep -qE 'abort if|stop rule:|rollback at' || echo "[fail] paper canary"

# Rollback plan for data-forward changes is compensating-forward.
grep -B 2 -A 5 'classification: data-forward' .deploy-ready/DEPLOY.md | grep -qE 'compensating forward|restore point' || echo "[fail] code-only rollback for data-forward"
```

### Tier 3.2 (observe) grep tests

```bash
# Every chart bound to a journey.
grep -E '^- (chart|metric):' .observe-ready/OBSERVE.md | grep -vE 'journey: |non-alerting|diagnostic-only'

# Error budget policy named with owner.
grep -A 5 '^## Error budget policy' .observe-ready/SLOs.md | grep -qE 'freeze trigger|owner:' || echo "[fail] paper SLO"

# Runbooks executed at least once.
grep -E '^last_executed:' .observe-ready/runbook/*.md | grep -vE 'last_executed: 20[0-9]{2}-[0-9]{2}-[0-9]{2}'

# Independence test recorded.
test -f .observe-ready/INDEPENDENCE.md || echo "[fail] no independence test"
```

### Tier 3.3 (launch) grep tests

```bash
# Substitution test: hero copy does not contain generic phrases.
grep -E '^hero:' .launch-ready/POSITIONING.md | grep -iE 'empower|productivity|seamlessly|leverage|unleash' && echo "[fail] hero-fatigue copy"

# OG card exists and has dimensions.
test -f public/og-image.png || test -f static/og-image.png || echo "[fail] no OG card image"

# Source attribution wired.
grep -rE 'utm_source|ref=|source=' src/landing/ | head -1 || echo "[fail] no source attribution"

# Launch-week runbook covers D-7 to D+7.
grep -E '^## D[+-]?[0-9]' .launch-ready/runbook/*.md | wc -l | grep -vE '^14$|^1[3-9]$' && echo "[heuristic-warn] runbook may be incomplete"
```

### Tier 3.4 (harden) grep tests

```bash
# Every OWASP category has a verdict.
grep -E '^### A0?[1-9]:' .harden-ready/FINDINGS.md | wc -l | grep -vE '^10$'

# Every accepted risk has owner and expiration.
grep -E 'accepted risk' .harden-ready/FINDINGS.md | grep -vE 'owner: [A-Z].*expires: 20[0-9]{2}-[0-9]{2}-[0-9]{2}'

# Every compliance control mapped.
grep -E '^### [A-Z]+ ' .harden-ready/COMPLIANCE.md 2>/dev/null | while read line; do
  grep -A 5 "$line" .harden-ready/COMPLIANCE.md | grep -qE 'evidence: \./|implemented at: \./' || echo "[fail] $line missing evidence"
done

# Findings actionable.
grep -E '^## Finding' .harden-ready/FINDINGS.md | while read line; do
  for required in 'severity:' 'reproduction:' 'fix:' 'retest:'; do
    grep -A 30 "$line" .harden-ready/FINDINGS.md | grep -q "$required" || echo "[fail] $line missing $required"
  done
done
```

These grep tests are not exhaustive; they catch the dominant failure modes. The full per-tier antipatterns catalogs in `references/<tier>/<skill>-antipatterns.md` have the complete grep matrix.
