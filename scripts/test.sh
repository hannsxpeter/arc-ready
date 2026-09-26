#!/usr/bin/env bash
# Behavioral tests for scripts/arc-check.sh against synthetic projects.
# Every assertion runs the shipped script; nothing here re-implements its logic.
# Bash 3.2 compatible.

set -u

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AC="$SCRIPT_DIR/arc-check.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0
OUT=""
CODE=0

good() { PASS=$((PASS + 1)); [ "$VERBOSE" = 1 ] && printf '  [ok] %s\n' "$1"; return 0; }
bad() {
  FAIL=$((FAIL + 1))
  printf '  [fail] %s\n' "$1"
  printf '%s\n' "$OUT" | head -25 | sed 's/^/        /'
}

# expect CODE PATTERN DESCRIPTION COMMAND...   (PATTERN is an ERE, or - for none)
expect() {
  want="$1"; pattern="$2"; desc="$3"; shift 3
  OUT=$("$@" 2>&1); CODE=$?
  if [ "$CODE" -ne "$want" ]; then bad "$desc (exit $CODE, want $want)"; return; fi
  if [ "$pattern" != - ] && ! printf '%s\n' "$OUT" | grep -Eq -- "$pattern"; then bad "$desc (output lacks /$pattern/)"; return; fi
  good "$desc"
}

# assert DESCRIPTION TEST-COMMAND...
assert() {
  desc="$1"; shift
  if "$@"; then good "$desc"; else OUT="(assertion failed: $*)"; bad "$desc"; fi
}

ac() { bash "$AC" -C "$P" "$@"; }
section() { [ "$VERBOSE" = 1 ] && printf '%s\n' "$1"; return 0; }

write_good_prd() {
  mkdir -p "$1/.prd-ready"
  cat > "$1/.prd-ready/PRD.md" <<'EOF'
# Tally PRD

## Problem

Freelance developers who bill 3 to 8 clients a month rebuild their hours from memory at invoice time. The 12 we interviewed each lose about 2 hours a month to it and under-bill by roughly 9 percent.

## Target user

Solo freelance developers who bill hourly, live in the terminal, and keep one git repository per client.

## Success metrics

- Decision: median time to produce a monthly per-client total drops from 120 minutes to under 10 minutes within 60 days of first use.
- Hypothesis: under-billing falls below 2 percent. Validate with 5 users comparing invoices before and after.

## Requirements

- R-01 (Must): record a time entry for a project in one command.
- R-02 (Must): report per-project totals for a date range.
- R-03 (Should): export a report as CSV.
- R-04 (Could): tag entries.
- R-05 (Won't): team accounts.

## Out of scope

Invoicing, payments, and team features.

## Open questions

- OQ-1: Should reports round to 15 minutes? Owner: Dana. Due: 2026-10-15.
EOF
}

write_good_upstream() {
  write_good_prd "$1"
  mkdir -p "$1/.architecture-ready" "$1/.roadmap-ready" "$1/.stack-ready"
  cat > "$1/.architecture-ready/ARCH.md" <<'EOF'
# Tally architecture

## System shape

A single-process CLI over an embedded SQLite file, with no server. Flip point: add a sync service if more than 20 percent of users run Tally on two machines.

## Components

- cli: parses commands and prints reports. Owner: Dana. Depends on store.
- store: SQLite persistence. Owner: Dana.

## Trust boundaries

The only trust boundary is the local file system. tally/store.py creates the database with 0600 permissions.

## Capacity

About 10,000 entries per user per year, under 5 MB, with reports under 50 ms.

## Dependency graph

store, then cli.
EOF
  cat > "$1/.roadmap-ready/ROADMAP.md" <<'EOF'
# Tally roadmap

Team size: 1 engineer with 6 available weeks.
Parallel tracks: 1

## Now

- [commitment] Slice 1: add and report entries end to end (R-01, R-02).

## Next

- [direction] CSV export (R-03).

## Later

- [open question] Tags (R-04). Owner: Dana. Decide after slice 1 ships.
EOF
  cat > "$1/.stack-ready/STACK.md" <<'EOF'
# Tally stack

Versions checked as of 2026-09-26 against the Python release notes.

| Criterion | Weight |
|---|---|
| No install friction | 0.5 |
| Portability | 0.3 |
| Startup speed | 0.2 |

Recommendation: the Python 3 standard library with sqlite3.
Flip point: move to Go if startup exceeds 150 ms on the reference laptop.
Migration path: the SQLite file is portable, so a rewrite reads the same database.
EOF
}

findings_open() {
  mkdir -p "$1/.harden-ready"
  cat > "$1/.harden-ready/FINDINGS.md" <<'EOF'
# Hardening findings

### C-1: Database backups are publicly readable

id: C-1
severity: critical
status: open
reproduction: request the backup bucket URL without credentials.
fix: restrict the bucket policy to the backup role.
retest: the same request returns 403.

### M-2: Verbose errors leak stack traces

id: M-2
severity: medium
status: fixed
reproduction: send a malformed date. fix: generic error text. retest: verified 2026-09-20.
EOF
}

# ------------------------------------------------------------------
section "basics"
P="$WORK/basics"; mkdir -p "$P"
expect 0 'arc-check 2\.' "version prints" ac version
expect 0 'Commands:' "help prints" ac --help
expect 2 - "unknown command is a usage error" ac frobnicate
expect 3 'no ledger' "status without a ledger exits 3" ac status

# ------------------------------------------------------------------
section "init and ordering"
P="$WORK/greenfield"; mkdir -p "$P"
expect 0 'created .arc-ready/PROGRESS.md' "init creates the ledger" ac init --mode A
assert "ledger lists every tier" [ "$(grep -cE '^- (0|[123]\.[1-4]) \(' "$P/.arc-ready/PROGRESS.md")" -eq 11 ]
expect 1 'already exists' "init refuses to overwrite" ac init --mode A
expect 0 'next: 1\.1 PRD' "fresh ledger points at the PRD" ac status
expect 1 'refused: .*gate failed' "done is refused without an artifact" ac mark 1.1 done
expect 1 'refused: upstream not complete' "a tier cannot start before its upstream" ac mark 1.3 in-flight
expect 0 'override' "an override is recorded" ac mark 1.3 in-flight --override "planning in parallel for a spike"
expect 0 - "an overridden tier is not an ordering problem" ac status
mkdir -p "$P/.roadmap-ready" && write_good_upstream "$WORK/donor-order" && cp "$WORK/donor-order/.roadmap-ready/ROADMAP.md" "$P/.roadmap-ready/ROADMAP.md"
expect 0 'override: planning in parallel' "a recorded override carries forward to done" ac mark 1.3 done
expect 1 'needs --reason' "skip without a reason is refused" ac mark 1.2 skipped
expect 0 'reason: ' "skip with a reason is recorded" ac mark 1.2 skipped --reason "architecture is a single script"
expect 1 'tier 0 is done only after' "tier 0 cannot close early" ac mark 0 done

# ------------------------------------------------------------------
section "PRD gate"
P="$WORK/prd"; mkdir -p "$P/.prd-ready"
bash "$AC" -C "$P" init --mode A >/dev/null
cat > "$P/.prd-ready/PRD.md" <<'EOF'
# PRD

## Problem

Users want a better way to track their time across many projects and clients.

## Users

Freelancers and teams of every size.

## Success

Users are happy and more productive than before.

## Requirements

- R-01 (Must): track time
- R-02 (Must): reports
- R-03 (Must): export
- R-04 (Must): tags
EOF
expect 1 'no measurable success criteria' "vague success criteria fail" ac gate 1.1
expect 1 'more than half of prioritized items are Must' "all-Must requirements fail" ac gate 1.1
expect 1 'no out-of-scope' "missing scope boundary fails" ac gate 1.1
expect 1 'refused' "done is refused while the gate fails" ac mark 1.1 done
write_good_prd "$P"
expect 0 'gate 1\.1: pass' "a specific PRD passes" ac gate 1.1
expect 0 'recorded: - 1\.1 \(PRD\): done' "done is recorded after the gate passes" ac mark 1.1 done
assert "done carries a verification timestamp" grep -Eq '^- 1\.1 \(PRD\): done \| artifact: \.prd-ready/PRD\.md \| verified: 20[0-9]{2}-' "$P/.arc-ready/PROGRESS.md"
assert "the transition is logged" grep -q 'PRD done' "$P/.arc-ready/PROGRESS.md"
printf '# PRD\n\n## Problem\n\n{{problem}}\n\n%s\n' "$(printf 'x%.0s' $(seq 1 220))" > "$P/.prd-ready/PRD.md"
expect 1 'unfilled template placeholders' "an unfilled template fails" ac gate 1.1

# ------------------------------------------------------------------
section "planning gates"
P="$WORK/planning"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode A >/dev/null
write_good_upstream "$P"
expect 0 'gate 1\.2: pass' "architecture with flip points and trust boundaries passes" ac gate 1.2
expect 0 'gate 1\.3: pass' "roadmap with capacity passes" ac gate 1.3
expect 0 'gate 1\.4: pass' "weighted stack with an exit path passes" ac gate 1.4
sed 's/Flip point: add a sync service/Later we may add a sync service/' "$P/.architecture-ready/ARCH.md" > "$P/arch.tmp" && mv "$P/arch.tmp" "$P/.architecture-ready/ARCH.md"
expect 1 'no flip point' "architecture without flip points fails" ac gate 1.2
sed 's/^Parallel tracks: 1/Parallel tracks: 3/' "$P/.roadmap-ready/ROADMAP.md" > "$P/road.tmp" && mv "$P/road.tmp" "$P/.roadmap-ready/ROADMAP.md"
expect 1 'more parallel tracks' "fictional parallelism fails" ac gate 1.3

# ------------------------------------------------------------------
section "drift and imports"
P="$WORK/drift"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode B >/dev/null
write_good_prd "$P"
bash "$AC" -C "$P" mark 1.1 done >/dev/null
sed 's/^- 1\.2 (ARCH): pending/- 1.2 (ARCH): done/; s/^- 1\.3 (ROADMAP): pending/- 1.3 (ROADMAP): done/' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 '\[drift\] 1\.2 ARCH is done but' "a claimed tier with no artifact is drift" ac status
expect 1 'next: 1\.2 ARCH' "drift sends the arc back to the missing tier" ac status
mkdir -p "$P/.stack-ready"
write_good_upstream "$WORK/donor" && cp "$WORK/donor/.stack-ready/STACK.md" "$P/.stack-ready/STACK.md"
expect 1 '\[import\?\] 1\.4 STACK' "an artifact on disk is offered as an import" ac status
expect 0 'imported' "import is recorded when the artifact exists" ac mark 1.4 imported
expect 1 'nothing to import' "import is refused when nothing exists" ac mark 2.2 imported

# ------------------------------------------------------------------
section "1.x ledger compatibility"
P="$WORK/legacy-list"; mkdir -p "$P/.arc-ready"
write_good_prd "$P"
cat > "$P/.arc-ready/PROGRESS.md" <<'EOF'
# arc-ready PROGRESS

## Skill version: 1.2.1
## Mode: A

## Tier ledger
- 0: in-flight | artifact: .arc-ready/PROGRESS.md | verified: -
- 1.1 (PRD): done | artifact: .prd-ready/PRD.md | verified: 2026-09-01T10:00:00Z
- 1.2 (ARCH): in-flight | artifact: .architecture-ready/ARCH.md | verified: -
- 1.3 (ROADMAP): pending | artifact: .roadmap-ready/ROADMAP.md | verified: -
- 1.4 (STACK): pending
- 2.1 (REPO): pending
- 2.2 (PRODUCTION): pending
- 3.1 (DEPLOY): pending
- 3.2 (OBSERVE): pending
- 3.3 (LAUNCH): pending
- 3.4 (HARDEN): pending
EOF
expect 0 '\[ \] 1\.2 ARCH in-flight' "1.x list lines with trailing fields parse (the 1.x sed parser read '-')" ac status
P="$WORK/legacy-named"; mkdir -p "$P/.arc-ready"
write_good_prd "$P"
{
  printf '# arc-ready PROGRESS\n\narc_mode: B\n\n'
  printf -- '- kickoff-ready: in-flight\n- prd-ready: done\n- architecture-ready: done\n'
  for n in roadmap stack repo production deploy observe launch harden; do printf -- '- %s-ready: pending\n' "$n"; done
} > "$P/.arc-ready/PROGRESS.md"
expect 1 '\[drift\] 1\.2 ARCH is done but' "1.x named lines (- prd-ready: done) are read" ac status
expect 1 '\[ok\] 1\.1 PRD done' "a named 1.x line with its artifact on disk passes" ac status
P="$WORK/legacy-table"; mkdir -p "$P/.arc-ready"
write_good_prd "$P"
cat > "$P/.arc-ready/PROGRESS.md" <<'EOF'
# arc-ready PROGRESS

arc_mode: A

| Step | Tier | Status | Artifact path | Invocation TS | Verification TS | Disk hash | Notes |
|---|---|---|---|---|---|---|---|
| 0 | kickoff-ready | in-flight | .arc-ready/PROGRESS.md | | | | |
| 1 | prd-ready | done | .prd-ready/PRD.md | 2026-05-06T14:02:11Z | 2026-05-06T14:18:33Z | 1746540513 | |
| 2 | architecture-ready | done | .architecture-ready/ARCH.md | | | | |
| 3 | roadmap-ready | pending | | | | | |
| 4 | stack-ready | pending | | | | | |
| 5 | repo-ready | pending | | | | | |
| 6 | production-ready | pending | | | | | |
| 7 | deploy-ready | pending | | | | | |
| 8 | observe-ready | pending | | | | | |
| 9 | launch-ready | pending | | | | | |
| 10 | harden-ready | pending | | | | | |
EOF
expect 1 '\[drift\] 1\.2 ARCH is done but' "1.x table ledgers are read and checked against disk" ac status
expect 0 'recorded: - 1\.2 \(ARCH\): pending' "marking a 1.x ledger writes a 2.x line" ac mark 1.2 pending
expect 0 'next: 1\.2 ARCH' "the 2.x line wins over the table row" ac status

# ------------------------------------------------------------------
section "build gate and scan"
P="$WORK/build"; mkdir -p "$P/tally" "$P/tests" "$P/.production-ready"
cat > "$P/.production-ready/STATE.md" <<'EOF'
# Production state

Slice 1 (add and report entries end to end) is done: tally add and tally report round-trip through SQLite, and python3 -m unittest passes with 6 tests.
Next slice: CSV export (R-03). No open questions block it; the slice queue lives in .roadmap-ready/ROADMAP.md.
EOF
cat > "$P/tally/store.py" <<'EOF'
import sqlite3

STATUSES = ["TODO", "DONE"]

def add(db, project, minutes):
    # TODO: validate minutes
    db.execute("insert into entries values (?, ?)", (project, minutes))
EOF
: > "$P/tests/__init__.py"
expect 1 'no tests found' "an empty tests package is not a test suite" ac gate 2.2
printf 'import unittest\n' > "$P/tests/test_store.py"
expect 1 '\[hit\] tally/store\.py:[0-9]+: +# TODO' "a TODO comment in shipped code fails" ac gate 2.2
expect 1 - "scan exits non-zero on a hit" ac scan
sed 's/    # TODO: validate minutes/    minutes = int(minutes)/' "$P/tally/store.py" > "$P/s.tmp" && mv "$P/s.tmp" "$P/tally/store.py"
expect 0 'gate 2\.2: pass' "a TODO string value is not a placeholder" ac gate 2.2
printf 'from faker import Faker\nrows = [faker.name() for _ in range(3)]\n' > "$P/tally/seed.py"
expect 1 'faker' "fake data in shipped code fails" ac gate 2.2
printf 'from faker import Faker\n' > "$P/tests/fixtures_seed.py"
rm -f "$P/tally/seed.py"
expect 0 'gate 2\.2: pass' "fake data in tests is allowed" ac gate 2.2

# ------------------------------------------------------------------
section "pillars"
P="$WORK/pillars"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode A >/dev/null
expect 0 'wrote\] AGENTS\.md' "pillars writes the loader when absent" ac pillars --name Tally
assert "CLAUDE.md links to AGENTS.md" [ -L "$P/CLAUDE.md" ]
assert "floor pillars exist as stubs" grep -q 'status: stub' "$P/agents/context.md"
assert "repo pillar exists" [ -f "$P/agents/repo.md" ]
assert "adoption is recorded" grep -q '^pillars: adopted' "$P/.arc-ready/PROGRESS.md"
expect 0 'left unchanged' "pillars is idempotent" ac pillars
P="$WORK/pillars-blocked"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode B >/dev/null
printf '# Team conventions\n\nUse tabs.\n' > "$P/AGENTS.md"
expect 0 'blocked' "a non-Pillars AGENTS.md is respected" ac pillars
assert "the existing AGENTS.md is untouched" grep -q 'Use tabs' "$P/AGENTS.md"
assert "no floor pillars are forced" [ ! -d "$P/agents" ]
assert "the block is recorded" grep -q '^pillars: adoption-blocked-existing-agents' "$P/.arc-ready/PROGRESS.md"

# ------------------------------------------------------------------
section "repo gate"
P="$WORK/repo"; mkdir -p "$P/.repo-ready" "$P/.github/workflows"
bash "$AC" -C "$P" init --mode A >/dev/null
printf '# Scaffold\n\nPython package layout sized for a single-maintainer CLI: tally/, tests/, a unittest CI job, an MIT license, and SECURITY.md.\nGovernance, code of conduct, and release automation are skipped on purpose until a second maintainer joins.\n' > "$P/.repo-ready/SCAFFOLD.md"
printf '# Tally\n\nTally records freelance time entries per client from the terminal and reports monthly totals from a local SQLite file.\n\nInstall with pipx install tally, then run tally add acme 30 and tally report --month 2026-09.\n' > "$P/README.md"
expect 1 'no CI configuration' "a repo without CI fails" ac gate 2.1
printf 'name: ci\non: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - run: python3 -m unittest\n' > "$P/.github/workflows/ci.yml"
expect 1 'no Pillars memory' "a repo without project memory fails" ac gate 2.1
bash "$AC" -C "$P" pillars --name Tally >/dev/null
expect 0 'gate 2\.1: pass' "a scaffolded repo with CI and Pillars passes" ac gate 2.1

# ------------------------------------------------------------------
section "shipping gates"
P="$WORK/ship"; mkdir -p "$P/.deploy-ready" "$P/.observe-ready" "$P/.launch-ready"
bash "$AC" -C "$P" init --mode A >/dev/null
cat > "$P/.deploy-ready/DEPLOY.md" <<'EOF'
# Deploy

One wheel is built once in CI and promoted to TestPyPI, then PyPI; the same artifact digest is recorded at each step.
Schema changes are data-forward and use expand and contract across two releases.
Rollback: tested on 2026-09-20 by reinstalling 0.1.0 over 0.2.0; it completed in 3 minutes.
EOF
expect 0 'gate 3\.1: pass' "deploy with an exercised rollback passes" ac gate 3.1
sed 's/^Rollback: tested on 2026-09-20 by reinstalling 0.1.0 over 0.2.0; it completed in 3 minutes./Rollback: reinstall the previous version./' "$P/.deploy-ready/DEPLOY.md" > "$P/d.tmp" && mv "$P/d.tmp" "$P/.deploy-ready/DEPLOY.md"
expect 1 'rollback was executed' "an untested rollback fails" ac gate 3.1
printf '\n## Rollback\n\nProcedure: reinstall the previous wheel.\nTested on 2026-09-22: 0.2.0 was replaced by 0.1.0 in 3 minutes.\n' >> "$P/.deploy-ready/DEPLOY.md"
expect 0 'rollback exercised' "a rollback section with test evidence passes" ac gate 3.1
cat > "$P/.observe-ready/OBSERVE.md" <<'EOF'
# Observe

SLO: 99.5% of report commands finish under 200 ms over 28 days.
Error budget policy: owner Dana. Feature work freezes when half the budget is spent.
Evidence: installation-ready. A synthetic fire on 2026-09-21 paged Dana through the real delivery path.
Runbook: the slow-report runbook was executed on 2026-09-21.
EOF
expect 0 'gate 3\.2: pass' "observability with an owned budget passes" ac gate 3.2
sed 's/^Error budget policy: owner Dana. Feature work freezes when half the budget is spent./Alerts go to the team channel./' "$P/.observe-ready/OBSERVE.md" > "$P/o.tmp" && mv "$P/o.tmp" "$P/.observe-ready/OBSERVE.md"
expect 1 'paper SLO' "an SLO without a budget policy fails" ac gate 3.2
cat > "$P/.launch-ready/STATE.md" <<'EOF'
# Launch state

Positioning: the time tracker for freelancers who invoice from their git history.
Every channel link carries utm_source for attribution. The D-7 to D+7 runbook is written and the waitlist email was delivered to a test inbox.
EOF
expect 0 'prepared is not published' "launch gate passes and reminds that prepared is not published" ac gate 3.3

# ------------------------------------------------------------------
section "hardening and the public activation gate"
# Mirrors what `accept` writes when a person confirms at a terminal.
recorded_acceptance() {
  id="$1"; sev="$2"; owner="$3"; acc="$4"; expd="$5"; just="$6"
  if command -v shasum >/dev/null 2>&1; then sum="shasum -a 256"; else sum=sha256sum; fi
  chk=$(printf '%s' "$(printf '%s' "$id" | tr 'A-Z' 'a-z')|$sev|$owner|$acc|$expd|$just" | $sum | cut -c1-16)
  printf -- '- finding: %s | severity: %s | owner: %s | accepted: %s | expires: %s | justification: %s | check: %s\n' "$id" "$sev" "$owner" "$acc" "$expd" "$just" "$chk"
}
P="$WORK/gate"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode A >/dev/null
expect 1 'hardening has not run' "prepublish blocks when hardening never ran" ac prepublish
findings_open "$P"
expect 1 'prepublish: block' "an open Critical blocks publication" ac prepublish
expect 1 'Do not write or edit a risk acceptance yourself' "a block tells the agent to stop, not to accept the risk" ac prepublish
assert "the block is written to disk" grep -q '^verdict: block' "$P/.launch-ready/PREPUBLICATION.md"
expect 0 'gate 3\.4: pass' "findings with ids, severity, and status pass the gate" ac gate 3.4
next_year=$(( $(date -u +%Y) + 1 ))
expect 1 'needs a person at an interactive terminal' "accept refuses to run without a terminal" ac accept C-1 --owner Dana --expires "$next_year-01-31" --justification "sheet fixed by Friday"
expect 1 'no finding with id' "accept rejects an unknown finding" ac accept C-9 --owner Dana --expires "$next_year-01-31" --justification "n/a"
expect 1 'in the past' "accept rejects a past expiry" ac accept C-1 --owner Dana --expires 2020-01-31 --justification "n/a"
sed 's/^status: open/status: accepted/' "$P/.harden-ready/FINDINGS.md" > "$P/f.tmp" && mv "$P/f.tmp" "$P/.harden-ready/FINDINGS.md"
expect 1 'no current acceptance was recorded with arc-check.sh accept' "an accepted status without a recorded acceptance fails the gate" ac gate 3.4
printf -- '- finding: C-1 | owner: Priya (marketing) | accepted: 2026-09-26 | expires: %s-01-31 | justification: external team will fix the sheet\n' "$next_year" >> "$P/.arc-ready/PROGRESS.md"
expect 1 'ignored an acceptance line that was written or edited by hand' "a hand-written acceptance is ignored" ac prepublish
recorded_acceptance C-1 critical Dana 2026-09-26 "$next_year-01-31" "sheet is empty until launch" >> "$P/.arc-ready/PROGRESS.md"
expect 0 'prepublish: pass' "an acceptance recorded by accept passes" ac prepublish
expect 0 'gate 3\.4: pass' "a recorded acceptance satisfies the gate" ac gate 3.4
expect 0 'current and passing' "verify accepts an unchanged pass" ac prepublish --verify
printf '\n### H-3: Rate limit missing on login\n\nid: H-3\nseverity: high\nstatus: open\n' >> "$P/.harden-ready/FINDINGS.md"
expect 1 'stale' "any hardening change invalidates the pass" ac prepublish --verify
sed 's/^gate-launch-on-hardening: default/gate-launch-on-hardening: hard/' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 'prepublish: block' "the hard policy ignores risk acceptance" ac prepublish
expect 1 'cannot be accepted' "accept refuses Critical findings under the hard policy" ac accept C-1 --owner Dana --expires "$next_year-01-31" --justification "n/a"
sed 's/^gate-launch-on-hardening: hard/gate-launch-on-hardening: default/' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
sed "s/| owner: Dana | accepted: 2026-09-26 | expires: $next_year-01-31/| owner: Dana | accepted: 2026-09-26 | expires: $((next_year + 5))-01-31/" "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 'prepublish: block' "an acceptance edited after recording is ignored" ac prepublish
recorded_acceptance C-1 critical Dana 2019-01-01 2020-01-31 "old waiver" > "$P/expired.txt"
grep -v '^- finding: C-1 | severity: critical | owner: Dana' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && cat "$P/expired.txt" >> "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 'prepublish: block' "an expired acceptance blocks" ac prepublish
sed 's/^status: accepted/status: fixed/' "$P/.harden-ready/FINDINGS.md" > "$P/f.tmp" && mv "$P/f.tmp" "$P/.harden-ready/FINDINGS.md"
expect 0 'prepublish: pass' "a fixed Critical no longer blocks" ac prepublish
P="$WORK/gate-flat"; mkdir -p "$P/.harden-ready"
printf 'hardening_revision: 2\nseverity: critical\nstatus: open\n\nseverity: low\nstatus: fixed\n' > "$P/.harden-ready/FINDINGS.md"
expect 1 'finding-1: critical, status open' "the 1.x flat finding format is read" ac prepublish

# ------------------------------------------------------------------
section "review regressions: the release gate fails closed"
next_year=$(( $(date -u +%Y) + 1 ))
gate_case() {
  P="$WORK/rr-$1"; mkdir -p "$P/.harden-ready"
  bash "$AC" -C "$P" init --mode A >/dev/null
  printf '%s\n' "$2" > "$P/.harden-ready/FINDINGS.md"
  expect "$3" "$4" "$5" ac prepublish
}
gate_case table '| ID | Severity | Status |
|---|---|---|
| C-1 | Critical | Open |' 1 'prepublish: block' "a findings table with an open Critical blocks"
gate_case brackets 'id: C-1
severity: [Critical]
status: open' 1 'prepublish: block' "severity: [Critical] is read"
gate_case qualifier 'id: C-1
Severity (CVSS): Critical
status: open' 1 'prepublish: block' "a severity key with a qualifier is read"
gate_case underscores 'id: C-1
__Severity__: Critical
status: open' 1 'prepublish: block' "a bold severity key is read"
gate_case numbered '1. id: C-1
2. Severity: Critical
3. Status: Open' 1 'prepublish: block' "numbered-list findings are read"
gate_case phrase 'id: C-1
severity: CVSS 9.8 (Critical)
status: open' 1 'prepublish: block' "a severity phrase containing Critical is read"
gate_case empty '' 1 'no findings could be read' "an empty findings file blocks"
gate_case none '# Hardening

findings: none' 0 'prepublish: pass' "an explicit findings: none passes"
gate_case unknown 'id: C-1
severity: catastrophic
status: open' 1 'severity could not be read' "an unreadable severity blocks"
gate_case regex-id 'id: ^$
severity: critical
status: open' 1 'prepublish: block' "a regex-shaped id cannot match the acceptance list"
gate_case tab-id "$(printf 'id:\tC-1\t(bucket)\nseverity: critical\nstatus: open')" 1 'C-1: critical' "a tab-separated id does not shift columns"
gate_case no-status 'severity: critical

id: M-2
status: fixed
severity: medium' 1 'prepublish: block' "a Critical without a status does not borrow the next finding's"
gate_case duplicate '## A01-2025 Access control

severity: low
status: fixed

severity: critical
status: open' 1 'duplicate finding ids' "findings that share an id block"
expect 1 'names more than one finding' "accept refuses an ambiguous id" ac accept A01-2025 --owner Dana --expires "$next_year-01-31" --justification "n/a"
P="$WORK/rr-tmpdir"; mkdir -p "$P"; bash "$AC" -C "$P" init --mode A >/dev/null; findings_open "$P"
expect 1 'prepublish: block' "a broken TMPDIR cannot turn a block into a pass" env TMPDIR=/nonexistent/arc-check bash "$AC" -C "$P" prepublish
P="$WORK/rr-sevbind"; mkdir -p "$P/.harden-ready"; bash "$AC" -C "$P" init --mode A >/dev/null
printf 'id: C-1\nseverity: low\nstatus: accepted\n' > "$P/.harden-ready/FINDINGS.md"
recorded_acceptance C-1 low Dana 2026-09-26 "$next_year-01-31" "low risk for launch" >> "$P/.arc-ready/PROGRESS.md"
sed 's/^severity: low/severity: critical/' "$P/.harden-ready/FINDINGS.md" > "$P/f.tmp" && mv "$P/f.tmp" "$P/.harden-ready/FINDINGS.md"
expect 1 'names another severity' "an acceptance recorded for a lower severity does not cover a raised finding" ac prepublish
P="$WORK/rr-policy"; mkdir -p "$P"; bash "$AC" -C "$P" init --mode A >/dev/null; findings_open "$P"
recorded_acceptance C-1 critical Dana 2026-09-26 "$next_year-01-31" "sheet is empty until launch" >> "$P/.arc-ready/PROGRESS.md"
expect 0 'prepublish: pass' "a recorded acceptance passes under the default policy" ac prepublish
expect 0 'current and passing' "verify passes while nothing changed" ac prepublish --verify
printf 'gate-launch-on-hardening: hard\n' >> "$P/.arc-ready/PROGRESS.md"
expect 1 'stale' "a policy change invalidates an earlier pass" ac prepublish --verify
expect 1 'prepublish: block' "an appended hard policy wins over the default line" ac prepublish
grep -v '^gate-launch-on-hardening: hard' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && printf '**gate-launch-on-hardening:** hard\r\n' >> "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 'prepublish: block' "a bold hard policy line with CRLF is read" ac prepublish
grep -v 'gate-launch-on-hardening:\*\* hard' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
bash "$AC" -C "$P" prepublish >/dev/null
grep -v '^- finding: C-1' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 1 'stale' "removing an acceptance invalidates an earlier pass" ac prepublish --verify

section "review regressions: pull request review"
gate_case mixed 'id: L-1
severity: low
status: fixed

Critical: remote code execution in the upload handler, still open.' 1 'mentions Critical outside a readable finding' "an unstructured Critical next to a valid finding blocks"
gate_case critical-heading '## Critical findings

### C-1: Backups were public

id: C-1
severity: critical
status: fixed' 0 'prepublish: pass' "a Critical section heading over structured findings does not block"
gate_case unstructured-heading '### L-1: Verbose errors

id: L-1
severity: low
status: fixed

### C-9: Critical RCE in the upload handler

The handler runs uploaded files.' 1 'line 7' "a Critical finding heading with no severity line blocks"
gate_case declared-none 'id: L-1
severity: low
status: fixed

Critical findings: none' 0 'prepublish: pass' "critical findings: none is an explicit statement"
gate_case sentence 'id: L-1
severity: low
status: fixed

No critical findings remain.' 0 'prepublish: pass' "a one-line no-critical-findings sentence passes"
gate_case compound 'id: L-1
severity: low
status: fixed

The login flow is business-critical, so it was reviewed twice.' 0 'prepublish: pass' "a hyphenated compound is not a Critical finding"
P="$WORK/rr-baddate"; mkdir -p "$P"; bash "$AC" -C "$P" init --mode A >/dev/null; findings_open "$P"
recorded_acceptance C-1 critical Dana 2026-09-26 2026-19-39 "impossible date" >> "$P/.arc-ready/PROGRESS.md"
expect 1 'prepublish: block' "an acceptance with an impossible expiry is never current" ac prepublish
expect 2 'real date' "accept rejects an impossible month and day" ac accept C-1 --owner Dana --expires 2026-19-39 --justification "n/a"
expect 2 'real date' "accept rejects February 29 outside a leap year" ac accept C-1 --owner Dana --expires 2027-02-29 --justification "n/a"
P="$WORK/rr-web"; mkdir -p "$P/site"
printf '<main>\n<!-- TODO: real copy -->\n</main>\n' > "$P/site/index.html"
expect 1 'index\.html:2' "an HTML comment TODO is scanned" ac scan
printf '<p>Lorem ipsum dolor sit amet.</p>\n' > "$P/site/index.html"
printf '.hero { color: red; } /* FIXME: brand color */\n' > "$P/site/app.css"
expect 1 'app\.css:1' "a CSS comment FIXME is scanned" ac scan
expect 1 'index\.html:1' "lorem ipsum in HTML is scanned" ac scan
P="$WORK/rr-nosource"; mkdir -p "$P/.production-ready"
printf '# Production state\n\nSlice 1 shipped: the add and report commands round-trip through SQLite and the unit tests pass with 6 tests. Next: CSV export (R-03).\n' > "$P/.production-ready/STATE.md"
expect 1 'no shipped source files' "the build gate fails when there is no source to check" ac gate 2.2

section "review regressions: ledger, writes, and scanning"
P="$WORK/rr-intent"; mkdir -p "$P"; bash "$AC" -C "$P" init --mode A >/dev/null
sed 's/^Replace this line with the request.*/- 1.2: skipped, noted during kickoff/' "$P/.arc-ready/PROGRESS.md" > "$P/l.tmp" && mv "$P/l.tmp" "$P/.arc-ready/PROGRESS.md"
expect 0 'recorded: - 1\.2 \(ARCH\): skipped' "mark writes the Tiers line, not an Intent bullet" ac mark 1.2 skipped --reason "spike"
expect 0 '\[ok\] 1\.2 ARCH skipped' "status reads the Tiers line" ac status
assert "the Intent bullet is untouched" grep -q '^- 1\.2: skipped, noted during kickoff' "$P/.arc-ready/PROGRESS.md"
expect 0 'reason: docs.new\.md' "a backslash in a reason is kept" ac mark 1.3 skipped --reason 'docs\new.md'
assert "a backslash does not split the tier line" [ "$(grep -cE '^- (0|[123]\.[1-4]) \(' "$P/.arc-ready/PROGRESS.md")" -eq 11 ]
expect 2 'cannot contain' "a reason with a pipe is refused" ac mark 1.4 skipped --reason 'a | b'
expect 0 '^gate 0: pass' "gate 0 reports its own tier" ac gate 0
P="$WORK/rr-symlink"; mkdir -p "$P" "$WORK/rr-outside"; bash "$AC" -C "$P" init --mode A >/dev/null
ln -s ../rr-outside/AGENTS.md "$P/AGENTS.md"
expect 0 'blocked' "a dangling AGENTS.md symlink is respected" ac pillars
assert "pillars wrote nothing outside the project" [ ! -e "$WORK/rr-outside/AGENTS.md" ]
assert "pillars records one pillars line" [ "$(grep -c '^pillars:' "$P/.arc-ready/PROGRESS.md")" -eq 1 ]
rm -f "$P/AGENTS.md"
ln -s ../rr-outside "$P/.launch-ready"
findings_open "$P"
expect 1 'refused' "prepublish will not write through a symlinked directory" ac prepublish
assert "prepublish wrote nothing outside the project" [ ! -e "$WORK/rr-outside/PREPUBLICATION.md" ]
P="$WORK/rr-git"; mkdir -p "$P/src/agents"
(cd "$P" && git init -q && git config core.fsmonitor "touch $WORK/rr-fsmonitor-ran; false")
printf '# TODO: wire it\n' > "$P/src/caf$(printf '\303\251').py"
expect 1 'caf' "a non-ASCII path with a TODO is scanned" ac scan
assert "git never ran the project's fsmonitor command" [ ! -e "$WORK/rr-fsmonitor-ran" ]
rm -f "$P/src/caf"*.py
printf '# TODO \351t\351\n' > "$P/src/latin.py"
expect 1 'latin\.py' "a line with invalid UTF-8 is scanned" ac scan
rm -f "$P/src/latin.py"
printf '// TODO: plan steps\n' > "$P/src/agents/planner.ts"
expect 1 'planner\.ts' "source under an agents directory is scanned" ac scan
P="$WORK/rr-deploy"; mkdir -p "$P/.deploy-ready"; bash "$AC" -C "$P" init --mode A >/dev/null
cat > "$P/.deploy-ready/DEPLOY.md" <<'EOF'
# Deploy

The image is built once as ghcr.io/acme/tally:${{ github.sha }} and promoted by digest through staging and production.
Rollback: executed on 2026-09-20 by redeploying the previous digest; traffic recovered in 2 minutes.
Secrets come from the platform store.
EOF
expect 0 'gate 3\.1: pass' "a CI expression is not an unfilled template" ac gate 3.1
sed 's/^Rollback: executed on 2026-09-20 by redeploying the previous digest; traffic recovered in 2 minutes\./Rollback: untested so far; redeploy the previous digest./' "$P/.deploy-ready/DEPLOY.md" > "$P/d.tmp" && mv "$P/d.tmp" "$P/.deploy-ready/DEPLOY.md"
expect 1 'rollback was executed' "an untested rollback is not evidence" ac gate 3.1
P="$WORK/rr-legacy-mode"; mkdir -p "$P/.arc-ready"; write_good_prd "$P"
{
  printf '# arc-ready PROGRESS\n\n## Mode: A\n\n## Step ledger\n\n| Step | Tier | Status |\n|---|---|---|\n'
  printf '| 1 | prd-ready | done |\n'
  n=2; for x in architecture roadmap stack repo production deploy observe launch harden; do printf '| %s | %s-ready | pending |\n' "$n" "$x"; n=$((n + 1)); done
} > "$P/.arc-ready/PROGRESS.md"
expect 0 'arc_mode: A' "a 1.x ledger without a tier-0 row and with ## Mode is read" ac status

# ------------------------------------------------------------------
section "guided skeletons pass their gates once filled"
GUIDED="$SCRIPT_DIR/../references/guided"
fill() {
  awk '/^~~~markdown/ { inside = 1; next } /^~~~$/ { if (inside) exit } inside' "$GUIDED/$1" \
    | sed -e 's/{{YYYY-MM-DD}}/2026-09-26/g; s/{{date}}/2026-09-26/g; s/{{percent}}/99.5%/g; s/{{ms}}/300 ms/g' \
          -e 's/{{C-1}}/C-1/g; s/{{critical, high, medium, or low}}/high/g; s/{{open, fixed, or accepted}}/fixed/g' \
          -e 's/{{0\.0-1\.0}}/0.5/g; s/{{[^}]*}}/the 42 caregivers at Northside Home Care/g'
}
P="$WORK/guided"; mkdir -p "$P/.prd-ready" "$P/.architecture-ready" "$P/.roadmap-ready" "$P/.stack-ready" \
  "$P/.repo-ready" "$P/.production-ready" "$P/.deploy-ready" "$P/.observe-ready" "$P/.launch-ready" "$P/.harden-ready" \
  "$P/.github/workflows" "$P/app" "$P/tests"
bash "$AC" -C "$P" init --mode A --guided >/dev/null
assert "init --guided records guided mode" grep -q '^guided: true' "$P/.arc-ready/PROGRESS.md"
fill prd.md > "$P/.prd-ready/PRD.md"
fill architecture.md > "$P/.architecture-ready/ARCH.md"
printf '# Handoff\n\nDependency graph (build order): store, then api, then web.\n' > "$P/.architecture-ready/HANDOFF.md"
fill roadmap.md > "$P/.roadmap-ready/ROADMAP.md"
fill stack.md > "$P/.stack-ready/STACK.md"
fill repo.md > "$P/.repo-ready/SCAFFOLD.md"
printf '# Pilot\n\nPilot schedules home-care visits for agencies with 5 to 50 caregivers, handles last-minute shift swaps, and texts families when a visit starts and ends.\n\nRun it with `python3 -m app` and test it with `python3 -m unittest`.\n' > "$P/README.md"
printf 'name: ci\non: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - run: python3 -m unittest\n' > "$P/.github/workflows/ci.yml"
bash "$AC" -C "$P" pillars --name Pilot >/dev/null
fill build.md > "$P/.production-ready/STATE.md"
printf 'def visits(rows):\n    return [r for r in rows if r["status"] == "scheduled"]\n' > "$P/app/visits.py"
printf 'import unittest\n' > "$P/tests/test_visits.py"
fill deploy.md > "$P/.deploy-ready/DEPLOY.md"
fill observe.md > "$P/.observe-ready/OBSERVE.md"
fill launch.md > "$P/.launch-ready/STATE.md"
fill harden.md > "$P/.harden-ready/FINDINGS.md"
for t in 1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4; do
  expect 0 "gate $t: pass" "filled guided skeleton passes gate $t" ac gate "$t"
done

# ------------------------------------------------------------------
section "completion"
P="$WORK/done"; mkdir -p "$P"
bash "$AC" -C "$P" init --mode A >/dev/null
write_good_prd "$P"
bash "$AC" -C "$P" mark 1.1 done >/dev/null
for t in 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4; do
  bash "$AC" -C "$P" mark "$t" skipped --reason "test fixture" >/dev/null
done
expect 0 'arc complete' "status reports completion" ac status
expect 0 'recorded: - 0 \(ARC\): done' "tier 0 closes last" ac mark 0 done

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  printf '== arc-check tests passed: %s/%s ==\n' "$PASS" "$TOTAL"
  exit 0
fi
printf '== arc-check tests FAILED: %s/%s (%s failures) ==\n' "$PASS" "$TOTAL" "$FAIL"
exit 1
