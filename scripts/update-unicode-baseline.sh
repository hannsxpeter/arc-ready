#!/usr/bin/env bash
# Regenerate the inherited Unicode baseline after a reviewed mechanical move.
# Review the diff. Do not use this command to approve new authored symbols.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT="$REPO_DIR/config/unicode-baseline.txt"
TMP="${TMPDIR:-/tmp}/arc-ready-unicode-baseline.$$"

mkdir -p "$REPO_DIR/config"
trap 'rm -f "$TMP"' EXIT

printf '# path|policy_unicode_count|emoji_count\n' > "$TMP"
cd "$REPO_DIR"

for file in $(git ls-files --cached --others --exclude-standard | sort); do
  [ -f "$file" ] || continue
  policy=$(perl -CSD -ne 'while (/[\x{2010}-\x{2015}\x{2190}-\x{21FF}\x{2500}-\x{257F}]/g) {$n++} END {print $n || 0}' "$file" 2>/dev/null || printf '0')
  emoji=$(perl -CSD -ne 'while (/\p{Extended_Pictographic}/g) {$n++} END {print $n || 0}' "$file" 2>/dev/null || printf '0')
  if [ "$policy" -gt 0 ] || [ "$emoji" -gt 0 ]; then
    printf '%s|%s|%s\n' "$file" "$policy" "$emoji" >> "$TMP"
  fi
done

mv "$TMP" "$OUTPUT"
printf 'Updated %s. Review the baseline diff before publication.\n' "$OUTPUT"
