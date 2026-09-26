#!/usr/bin/env bash
# Ablation harness: does arc-ready change outcomes, and at what token cost?
#
# Runs every task under every arm on every model through headless Claude Code,
# then scores each run, judges the plan-task documents blind, and writes a
# report. Arms:
#   none    no skill
#   lean    the 2.x core in this working tree (SKILL.md, arc-check.sh, guided pack)
#   guided  the lean core with guided mode requested
#   full    the 1.x reference library, extracted from the FULL_REF tag
#
# This spends real API credit. Maintainer tool; not run in CI.
# Usage: bash evals/ablation/run.sh            (whole matrix, then judge and report)
#        bash evals/ablation/run.sh one TASK MODEL ARM REP
# Settings come from the environment; see evals/ablation/README.md.
# Bash 3.2 compatible.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"

MODELS="${MODELS:-claude-sonnet-5 claude-haiku-4-5}"
ARMS="${ARMS:-none lean full}"
GUIDED_MODELS="${GUIDED_MODELS:-claude-haiku-4-5}"
TASKS="${TASKS:-plan build resume launch}"
REPS="${REPS:-1}"
PARALLEL="${PARALLEL:-4}"
FULL_REF="${FULL_REF:-v1.2.1}"
TIMEOUT="${TIMEOUT:-1800}"
OUT="${OUT:-${TMPDIR:-/tmp}/arc-ready-ablation/$(date -u +%Y%m%dT%H%M%SZ)}"
export MODELS ARMS GUIDED_MODELS TASKS REPS PARALLEL FULL_REF TIMEOUT OUT

budget_for() {
  case "$1" in
    *haiku*) echo "${BUDGET_SMALL:-3}" ;;
    *) echo "${BUDGET_LARGE:-8}" ;;
  esac
}

prepare_skills() {
  mkdir -p "$OUT/skills"
  if [ ! -d "$OUT/skills/lean" ]; then
    mkdir -p "$OUT/skills/lean/scripts" "$OUT/skills/lean/references"
    cp "$REPO/SKILL.md" "$OUT/skills/lean/"
    cp "$REPO/scripts/arc-check.sh" "$OUT/skills/lean/scripts/"
    cp -R "$REPO/references/guided" "$OUT/skills/lean/references/"
    chmod -R a-w "$OUT/skills/lean"
  fi
  if [ ! -d "$OUT/skills/full" ]; then
    mkdir -p "$OUT/skills/full"
    git -C "$REPO" archive "$FULL_REF" | tar -x -C "$OUT/skills/full"
    chmod -R a-w "$OUT/skills/full"
  fi
  [ -f "$OUT/manifest.txt" ] && return 0
  {
    echo "claude_cli: $(claude --version 2>/dev/null | head -1)"
    echo "lean_source: $(git -C "$REPO" rev-parse --short HEAD) plus working tree"
    echo "full_ref: $FULL_REF ($(git -C "$REPO" rev-parse --short "$FULL_REF"))"
    echo "lean_skill_bytes: $(wc -c < "$OUT/skills/lean/SKILL.md" | tr -d ' ')"
    echo "full_reference_bytes: $(find "$OUT/skills/full/references" -name '*.md' -exec cat {} + | wc -c | tr -d ' ')"
    echo "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$OUT/manifest.txt"
}

run_one() {
  task="$1"; model="$2"; arm="$3"; rep="$4"
  dir="$OUT/runs/$task/$model/$arm/rep$rep"
  if [ -f "$dir/score.tsv" ]; then echo "skip $task $model $arm rep$rep (done)"; return 0; fi
  rm -rf "$dir"
  mkdir -p "$dir/project"
  bash "$HERE/fixtures.sh" "$task" "$dir/project"
  skill=""
  case "$arm" in
    none) ;;
    lean|guided) skill="$OUT/skills/lean" ;;
    full) skill="$OUT/skills/full" ;;
    *) echo "unknown arm: $arm" >&2; return 2 ;;
  esac
  prompt="$(cat "$HERE/tasks/$task.txt")

You are running unattended: nobody will answer questions. Make reasonable assumptions, label them, and finish the work."
  if [ -n "$skill" ]; then
    prompt="$prompt

An agent skill for this kind of work is installed at $skill. Read $skill/SKILL.md first and follow it."
    [ "$arm" = guided ] && prompt="$prompt Use the skill's guided mode."
  fi
  printf '%s\n' "$prompt" > "$dir/prompt.txt"
  echo "start $task $model $arm rep$rep"
  start=$(date +%s)
  (
    cd "$dir/project" || exit 1
    exec env -i HOME="$HOME" PATH="$PATH" USER="${USER:-}" LOGNAME="${LOGNAME:-}" SHELL="${SHELL:-/bin/bash}" \
      TMPDIR="${TMPDIR:-/tmp}" LANG="${LANG:-en_US.UTF-8}" TERM=dumb \
      claude -p "$prompt" --model "$model" --output-format json \
        --permission-mode acceptEdits --allowedTools "Bash Read Write Edit Glob Grep" \
        --disallowedTools "Skill Agent Task WebFetch WebSearch" --disable-slash-commands \
        --strict-mcp-config --mcp-config '{"mcpServers":{}}' --setting-sources project,local \
        --no-session-persistence --max-budget-usd "$(budget_for "$model")" \
        ${skill:+--add-dir "$skill"}
  ) > "$dir/result.json" 2> "$dir/stderr.txt" &
  pid=$!
  # Polls instead of sleeping for the whole timeout, so it exits with the run.
  (
    waited=0
    while [ "$waited" -lt "$TIMEOUT" ] && kill -0 "$pid" 2>/dev/null; do sleep 5; waited=$((waited + 5)); done
    kill -TERM "$pid" 2>/dev/null
  ) &
  watchdog=$!
  wait "$pid"
  code=$?
  wait "$watchdog" 2>/dev/null
  printf '%s\t%s\n' "$code" "$(( $(date +%s) - start ))" > "$dir/exit.tsv"
  bash "$HERE/score.sh" "$task" "$dir" > "$dir/score.tsv"
  echo "done  $task $model $arm rep$rep exit=$code score=$(cut -f1 "$dir/score.tsv")"
}

specs() {
  for task in $TASKS; do
    for model in $MODELS; do
      arms="$ARMS"
      case " $GUIDED_MODELS " in *" $model "*) arms="$arms guided" ;; esac
      for arm in $arms; do
        rep=1
        while [ "$rep" -le "$REPS" ]; do
          echo "$task $model $arm $rep"
          rep=$((rep + 1))
        done
      done
    done
  done
}

case "${1:-all}" in
  one)
    shift
    [ $# -eq 4 ] || { echo "usage: run.sh one TASK MODEL ARM REP" >&2; exit 2; }
    prepare_skills
    run_one "$@" ;;
  prepare)
    prepare_skills
    echo "$OUT" ;;
  judge)
    for d in "$OUT"/runs/plan/*/*/rep*; do
      [ -f "$d/score.tsv" ] && [ ! -f "$d/judge.tsv" ] && bash "$HERE/judge.sh" "$d"
    done ;;
  report)
    bash "$HERE/report.sh" "$OUT" ;;
  all)
    prepare_skills
    echo "output: $OUT"
    specs | xargs -P "$PARALLEL" -L 1 bash "$HERE/run.sh" one
    for d in "$OUT"/runs/plan/*/*/rep*; do
      [ -f "$d/score.tsv" ] && [ ! -f "$d/judge.tsv" ] && bash "$HERE/judge.sh" "$d"
    done
    bash "$HERE/report.sh" "$OUT" ;;
  *)
    echo "usage: run.sh [all | one TASK MODEL ARM REP | prepare | judge | report]" >&2
    exit 2 ;;
esac
