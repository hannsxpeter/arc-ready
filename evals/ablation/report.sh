#!/usr/bin/env bash
# report.sh OUT: collect every scored run into results.tsv and summary.md.
# Bash 3.2 compatible; needs jq.

set -u

OUT="$1"
tsv="$OUT/results.tsv"
printf 'task\tmodel\tarm\trep\tscore\tjudge\tcontract\tcost_usd\tinput_tokens\toutput_tokens\tturns\tseconds\texit\terror\tnotes\n' > "$tsv"

for d in "$OUT"/runs/*/*/*/rep*; do
  [ -f "$d/score.tsv" ] || continue
  rel=${d#"$OUT"/runs/}
  task=$(echo "$rel" | cut -d/ -f1)
  model=$(echo "$rel" | cut -d/ -f2)
  arm=$(echo "$rel" | cut -d/ -f3)
  rep=$(echo "$rel" | cut -d/ -f4 | sed 's/^rep//')
  score=$(cut -f1 "$d/score.tsv")
  contract=$(cut -f2 "$d/score.tsv")
  notes=$(cut -f3 "$d/score.tsv")
  judge=NA
  [ -f "$d/judge.tsv" ] && judge=$(cut -f2 "$d/judge.tsv")
  if jq -e . "$d/result.json" >/dev/null 2>&1; then
    cost=$(jq -r '.total_cost_usd // 0' "$d/result.json")
    input=$(jq -r '(.usage.input_tokens // 0) + (.usage.cache_creation_input_tokens // 0) + (.usage.cache_read_input_tokens // 0)' "$d/result.json")
    output=$(jq -r '.usage.output_tokens // 0' "$d/result.json")
    turns=$(jq -r '.num_turns // 0' "$d/result.json")
    err=$(jq -r 'if .is_error then (.subtype // "error") else "" end' "$d/result.json")
  else
    cost=0; input=0; output=0; turns=0; err="no-json"
  fi
  code=$(cut -f1 "$d/exit.tsv" 2>/dev/null)
  secs=$(cut -f2 "$d/exit.tsv" 2>/dev/null)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$task" "$model" "$arm" "$rep" "$score" "$judge" "$contract" "$cost" "$input" "$output" "$turns" "$secs" "$code" "$err" "$notes" >> "$tsv"
done

{
  echo "# Ablation summary"
  echo
  sed 's/^/    /' "$OUT/manifest.txt" 2>/dev/null
  echo
  echo "Score is the deterministic outcome score (0-10). Judge is the blinded quality score for plan documents (0-10, mean of samples). Contract is the share of runs that kept arc-ready's own artifacts and ledger. Cost and tokens are per run, including cache reads."
  echo
  echo "| Model | Arm | Runs | Mean score | Plan judge | Contract | Mean cost (USD) | Mean input tokens | Mean output tokens |"
  echo "|---|---|---:|---:|---:|---:|---:|---:|---:|"
  awk -F'\t' 'NR > 1 {
      k = $2 "|" $3; n[k]++; sc[k] += $5; ct[k] += $7; co[k] += $8; it[k] += $9; ot[k] += $10
      if ($6 != "NA" && $1 == "plan") { j[k] += $6; jn[k]++ }
    }
    END {
      for (k in n) {
        split(k, p, "|")
        judge = (jn[k] ? sprintf("%.1f", j[k] / jn[k]) : "NA")
        printf "| %s | %s | %d | %.1f | %s | %.0f%% | %.2f | %.0f | %.0f |\n", p[1], p[2], n[k], sc[k] / n[k], judge, 100 * ct[k] / n[k], co[k] / n[k], it[k] / n[k], ot[k] / n[k]
      }
    }' "$tsv" | sort
  echo
  echo "Per task (mean score / mean cost):"
  echo
  echo "| Task | Model | Arm | Score | Judge | Cost (USD) | Input tokens | Notes |"
  echo "|---|---|---|---:|---:|---:|---:|---|"
  awk -F'\t' 'NR > 1 { printf "| %s | %s | %s | %s | %s | %.2f | %d | %s |\n", $1, $2, $3, $5, $6, $8, $9, $15 }' "$tsv" | sort
  echo
  awk -F'\t' 'NR > 1 { t += $8 } END { printf "Total contestant cost: %.2f USD\n", t }' "$tsv"
  judge_cost=$(cat "$OUT"/runs/plan/*/*/rep*/judge.tsv 2>/dev/null | awk -F'\t' '{ t += $4 } END { printf "%.2f", t }')
  echo "Total judge cost: $judge_cost USD"
} > "$OUT/summary.md"

cat "$OUT/summary.md"
