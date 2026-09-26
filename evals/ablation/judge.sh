#!/usr/bin/env bash
# judge.sh RUN_DIR: blinded quality score for a plan-task run.
# The judge sees only the documents, with file names and arc-ready vocabulary
# removed, and scores five dimensions 0-2. Runs JUDGE_SAMPLES times and writes
# judge.tsv with the mean total and each sample. Bash 3.2 compatible.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
dir="$1"
P="$dir/project"
JUDGE_MODEL="${JUDGE_MODEL:-claude-opus-5}"
JUDGE_SAMPLES="${JUDGE_SAMPLES:-2}"

docs="$dir/judge-docs.txt"
: > "$docs"
i=0
find "$P" -type f -name '*.md' ! -path '*/.arc-ready/*' ! -path '*/.git/*' | sort | while IFS= read -r f; do
  i=$((i + 1))
  printf '=== Document %s ===\n' "$i" >> "$docs"
  sed -E 's#\.(arc|prd|architecture|roadmap|stack|repo|production|deploy|observe|launch|harden)-ready/##g; s#arc-ready#the planning process#g; /arc-check/d' "$f" >> "$docs"
  printf '\n\n' >> "$docs"
done

if [ ! -s "$docs" ]; then
  printf 'judge\t0\tno documents\n' > "$dir/judge.tsv"
  exit 0
fi

request=$(cat "$HERE/tasks/plan.txt")
prompt="You are grading planning documents that an AI agent produced for this request:

<request>
$request
</request>

Grade only the documents below. Ignore file names, formatting style, length, and any process bookkeeping. Score each dimension 0, 1, or 2:

1. specificity: 0 = generic, would fit any product in the category; 1 = partly specific; 2 = concrete users, numbers, and constraints throughout.
2. measurability: 0 = no measurable success criteria; 1 = metrics without baselines, targets, or a measurement method; 2 = metrics with a baseline, a target, a time window, and a measurement method.
3. prioritization: 0 = a flat feature list; 1 = priorities, but no clear first-release cut or non-goals; 2 = prioritized requirements, a clear first-release cut, and explicit non-goals.
4. decisions: 0 = the architecture lists technologies or diagrams without reasons; 1 = decisions with reasons but without alternatives, capacity numbers, or conditions to revisit them; 2 = decisions justified against stated constraints, with capacity estimates and the conditions under which they should be revisited.
5. risk: 0 = unlabeled assumptions and hand-waving such as scalable or secure; 1 = some assumptions or risks named; 2 = assumptions labeled with validation plans, open questions with owners, and security, trust boundaries, and failure modes handled concretely.

Respond with only one JSON object and nothing else:
{\"specificity\": 0, \"measurability\": 0, \"prioritization\": 0, \"decisions\": 0, \"risk\": 0, \"total\": 0, \"notes\": \"one sentence\"}

<documents>
$(cat "$docs")
</documents>"

totals=""
n=0
while [ "$n" -lt "$JUDGE_SAMPLES" ]; do
  n=$((n + 1))
  out="$dir/judge-$n.json"
  (cd "$dir" && env -i HOME="$HOME" PATH="$PATH" USER="${USER:-}" LOGNAME="${LOGNAME:-}" SHELL="${SHELL:-/bin/bash}" TMPDIR="${TMPDIR:-/tmp}" LANG="${LANG:-en_US.UTF-8}" TERM=dumb \
    claude -p "$prompt" --model "$JUDGE_MODEL" --output-format json \
    --disallowedTools "Bash Read Write Edit Glob Grep Skill Agent Task WebFetch WebSearch NotebookEdit" \
    --disable-slash-commands --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
    --setting-sources project,local --no-session-persistence --max-budget-usd 2) > "$out" 2> "$dir/judge-$n.err"
  verdict=$(jq -r '.result // ""' "$out" 2>/dev/null | sed -n '/{/,/}/p' | tr '\n' ' ' | sed -E 's/^[^{]*//; s/[^}]*$//')
  total=$(printf '%s' "$verdict" | jq -r '(.specificity + .measurability + .prioritization + .decisions + .risk)' 2>/dev/null)
  case "$total" in ''|null|*[!0-9]*) total="NA" ;; esac
  printf '%s\n' "$verdict" > "$dir/judge-$n.verdict.json"
  totals="$totals $total"
done

mean=$(printf '%s\n' $totals | awk '$1 != "NA" { t += $1; c++ } END { if (c) printf "%.1f", t / c; else print "NA" }')
cost=$(ls "$dir"/judge-[0-9]*.json 2>/dev/null | grep -v verdict | while IFS= read -r f; do jq -r '.total_cost_usd // 0' "$f" 2>/dev/null; done | awk '{ t += $1 } END { printf "%.4f", t }')
printf 'judge\t%s\t%s\t%s\n' "$mean" "$(printf '%s' "$totals" | sed 's/^ //')" "$cost" > "$dir/judge.tsv"
cat "$dir/judge.tsv"
