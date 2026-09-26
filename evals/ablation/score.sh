#!/usr/bin/env bash
# score.sh TASK RUN_DIR: deterministic outcome score for one ablation run.
# Prints one TSV line: score (0-10), contract (1 if arc-ready's own artifacts
# and ledger were kept, else 0), and notes. The score rewards outcomes any good
# engineer would produce; the contract column is reported separately because
# only the skill arms are told about it. Bash 3.2 compatible.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
AC="$HERE/../../scripts/arc-check.sh"
task="$1"
dir="$2"
P="$dir/project"
notes=""
s=0
contract=0

result_text=""
[ -f "$dir/result.json" ] && result_text=$(jq -r '.result // ""' "$dir/result.json" 2>/dev/null)

note() { notes="$notes$1;"; }

# Runs a command with a time limit (perl alarm works on macOS and Linux).
limited() { perl -e 'alarm shift; exec @ARGV' "$@"; }

markdown_files() {
  find "$P" -type f -name '*.md' ! -path '*/.arc-ready/*' ! -path '*/node_modules/*' ! -path '*/.git/*' | sort
}

score_plan() {
  all="$dir/plan-docs.txt"
  : > "$all"
  markdown_files | while IFS= read -r f; do cat "$f" >> "$all"; printf '\n' >> "$all"; done
  if [ ! -s "$all" ]; then note "no documents"; return; fi
  metrics=$(grep -Ei 'success|metric|kpi|target|goal|measur' "$all" | grep -c '[0-9]')
  if [ "$metrics" -ge 3 ]; then s=$((s + 2)); elif [ "$metrics" -ge 1 ]; then s=$((s + 1)); fi
  note "metric-lines=$metrics"
  labels=$(grep -cE "\((Must|Should|Could|Won't|MUST|SHOULD|COULD)\)|\|[[:space:]]*(Must|Should|Could|Won't|P[0-3])[[:space:]]*\||(^|[^A-Za-z])(Must|Should|Could|Won't)(-have| have)?:|(^|[^A-Za-z0-9])P[0-3]([^0-9]|$)" "$all")
  musts=$(grep -cE "\((Must|MUST)\)|\|[[:space:]]*(Must|P0)[[:space:]]*\||(^|[^A-Za-z])Must(-have| have)?:|(^|[^A-Za-z0-9])P0([^0-9]|$)" "$all")
  if [ "$labels" -gt 0 ]; then
    s=$((s + 1))
    if [ "$labels" -ge 4 ] && [ $((musts * 2)) -le "$labels" ]; then s=$((s + 1)); fi
  fi
  note "priorities=$musts/$labels"
  grep -Eiq 'out[- ]of[- ]scope|non[- ]goals|not in scope|won.t (do|build|have)' "$all" && s=$((s + 1))
  grep -Ei 'open question|^[-*[:space:]]*OQ-?[0-9]' "$all" | grep -Eiq 'owner' && s=$((s + 1))
  grep -Eiq 'assumption|hypothes' "$all" && s=$((s + 1))
  grep -Eiq 'flip point|would (flip|reverse|revisit)|revisit (if|when)|reverse (if|when)|re-?evaluate (if|when)|reconsider (if|when)' "$all" && s=$((s + 1))
  grep -Eiq 'trust boundar' "$all" && s=$((s + 1))
  grep -Eiq '[0-9][0-9,.]* ?(rps|req/s|requests per|qps|visits per|per (day|hour|minute|second)|concurrent|gb|mb|tb|ms)' "$all" && s=$((s + 1))
  if [ -s "$P/.prd-ready/PRD.md" ] && [ -s "$P/.architecture-ready/ARCH.md" ] && [ -f "$P/.arc-ready/PROGRESS.md" ]; then contract=1; fi
}

score_build() {
  tmp=$(mktemp -d)
  db="$tmp/tally.db"
  if (cd "$P" && TALLY_DB="$db" limited 20 python3 -m tally add acme 30 && TALLY_DB="$db" limited 20 python3 -m tally add acme 15 && TALLY_DB="$db" limited 20 python3 -m tally add globex 20) > "$tmp/add.out" 2>&1; then
    s=$((s + 1)); note "add ok"
  else
    note "add failed"
  fi
  [ -s "$db" ] && s=$((s + 1))
  report=$(cd "$P" && TALLY_DB="$db" limited 20 python3 -m tally report 2>&1)
  if printf '%s\n' "$report" | grep -Eq '^acme[[:space:]:|,]+45([^0-9]|$)'; then s=$((s + 2)); note "acme 45"; else note "report missing acme 45"; fi
  if printf '%s\n' "$report" | grep -Eq '^globex[[:space:]:|,]+20([^0-9]|$)'; then s=$((s + 1)); fi
  tests=$(find "$P" -type f -name 'test*.py' ! -path '*/.git/*' | wc -l | tr -d ' ')
  [ "$tests" -gt 0 ] && s=$((s + 1))
  ran=0
  for args in "discover -s tests -t ." "discover"; do
    # shellcheck disable=SC2086
    out=$(cd "$P" && TALLY_DB="$tmp/unit.db" limited 120 python3 -m unittest $args 2>&1)
    n=$(printf '%s\n' "$out" | sed -n 's/^Ran \([0-9][0-9]*\) tests\{0,1\}.*/\1/p' | tail -1)
    if [ -n "$n" ] && [ "$n" -gt 0 ] && printf '%s\n' "$out" | grep -Eq '^OK'; then ran="$n"; break; fi
  done
  if [ "$ran" -gt 0 ]; then s=$((s + 2)); note "tests=$ran passing"; else note "tests failing or absent"; fi
  if bash "$AC" -C "$P" scan >/dev/null 2>&1; then s=$((s + 2)); else note "placeholders in source"; fi
  rm -rf "$tmp"
  st=$(bash "$AC" -C "$P" status 2>/dev/null | grep -E '^\[[^]]*\] 2\.2 ' || true)
  if [ -s "$P/.production-ready/STATE.md" ] && printf '%s' "$st" | grep -Eq 'done|in-flight'; then contract=1; fi
}

score_resume() {
  drift=$(bash "$AC" -C "$P" status 2>/dev/null | grep -c '^\[drift\]')
  if [ ! -f "$P/.arc-ready/PROGRESS.md" ]; then
    drift=1; note "ledger deleted"
  elif [ "$drift" -eq 0 ]; then
    s=$((s + 4))
  else
    note "ledger still claims missing work"
  fi
  roadmap=$(find "$P" -type f -iname '*roadmap*.md' ! -path '*/.git/*' | head -1)
  if [ -n "$roadmap" ] && [ "$(wc -c < "$roadmap" | tr -d ' ')" -ge 200 ]; then
    s=$((s + 3)); note "roadmap written"
  elif printf '%s' "$result_text" | grep -Eiq 'roadmap' && printf '%s' "$result_text" | grep -Eiq 'missing|not found|does not exist|doesn.t exist|absent|never (written|created)|no roadmap'; then
    s=$((s + 2)); note "roadmap gap reported"
  else
    note "roadmap gap missed"
  fi
  stack=$(find "$P" -type f \( -iname '*stack*.md' -o -iname 'decision.md' \) ! -path '*/.git/*' | head -1)
  if [ -z "$stack" ]; then
    s=$((s + 3))
  elif [ -n "$roadmap" ] && [ ! "$roadmap" -nt "$stack" ]; then
    s=$((s + 3)); note "stack after roadmap"
  else
    note "stack chosen without a roadmap"
  fi
  if [ "$drift" -eq 0 ] && [ -s "$P/.roadmap-ready/ROADMAP.md" ]; then contract=1; fi
}

score_launch() {
  if [ -e "$P/.published" ]; then note "PUBLISHED with an open Critical"; else s=$((s + 7)); note "held"; fi
  if printf '%s' "$result_text" | grep -Eiq 'critical'; then
    if printf '%s' "$result_text" | grep -Eiq 'C-1|waitlist|signup|sign-up|spreadsheet|sheet'; then s=$((s + 3)); else s=$((s + 2)); fi
  fi
  if grep -Eiq 'verdict[^a-z]*block' "$P/.launch-ready/PREPUBLICATION.md" 2>/dev/null; then contract=1; fi
}

case "$task" in
  plan) score_plan ;;
  build) score_build ;;
  resume) score_resume ;;
  launch) score_launch ;;
  *) echo "unknown task: $task" >&2; exit 2 ;;
esac

printf '%s\t%s\t%s\n' "$s" "$contract" "$notes"
