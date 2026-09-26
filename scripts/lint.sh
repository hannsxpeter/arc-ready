#!/usr/bin/env bash
# arc-ready repository meta-linter. Bash 3.2 compatible.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXPECTED_COMPAT="claude-code codex cursor windsurf pi openclaw any-agentskills-compatible-harness"
# Archival source material kept verbatim; exempt from the punctuation check.
ARCHIVAL='^docs/research/'
# SKILL.md is the whole default context: about 4k tokens at most.
SKILL_MAX_BYTES=16384
GUIDED_MAX_BYTES=4096

VERBOSE=0
FAIL_FAST=0
SELECTED="--all"
EXIT_CODE=0

usage() {
  cat <<'EOF'
arc-ready-lint: repository and skill contract checks

Usage: bash scripts/lint.sh [check | --all] [--verbose] [--fail-fast]

Offline checks run by --all:
  punctuation-clean      no forbidden dash, arrow, or box characters in authored text
  emoji-free             no emoji in any tracked text file
  version-parity         metadata.version matches CHANGELOG and arc-check.sh
  compatible-with        compatibility metadata names supported clients
  standards-shape        Agent Skills fields and scalar limits are valid
  skill-budget           SKILL.md and guided skeletons stay inside their byte budgets
  no-default-loads       SKILL.md routes to no reference outside guided mode
  skill-paths-exist      every path SKILL.md names exists
  links-resolve          relative markdown links resolve
  shell-syntax           every repository Bash script parses
  test-suite             scripts/test.sh passes
  official-validator     runs skills-ref when installed, otherwise skips

Release-only check:
  tag-release-parity     every existing tag has a GitHub Release
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=1 ;;
    --fail-fast) FAIL_FAST=1 ;;
    --all|all) SELECTED="--all" ;;
    -h|--help) usage; exit 0 ;;
    --*) printf 'unknown flag: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) SELECTED="$1" ;;
  esac
  shift
done

mark_fail() {
  EXIT_CODE=1
  if [ "$FAIL_FAST" = "1" ]; then
    printf '[fail-fast] stopping\n' >&2
    exit 1
  fi
}

report() {
  if [ "$2" = "1" ]; then mark_fail; printf '  [%s] FAILED\n\n' "$1"; else printf '  [%s] passed\n\n' "$1"; fi
}

metadata_value() {
  awk -v wanted="$1" '
    /^metadata:/ { inside=1; next }
    inside && /^[^ ]/ { exit }
    inside && $0 ~ "^  " wanted ":" {
      sub("^  " wanted ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$REPO_DIR/SKILL.md"
}

text_files() {
  cd "$REPO_DIR"
  git ls-files --cached --others --exclude-standard | sort | while IFS= read -r file; do
    [ -f "$file" ] || continue
    perl -e 'exit((-B $ARGV[0]) ? 0 : 1)' "$file" 2>/dev/null && continue
    printf '%s\n' "$file"
  done
}

check_punctuation_clean() {
  printf '== punctuation-clean ==\n'
  local_fail=0
  for file in $(text_files | grep -Ev "$ARCHIVAL"); do
    count=$(perl -CSD -ne 'while (/[\x{2010}-\x{2015}\x{2190}-\x{21FF}\x{2500}-\x{257F}\x{2212}]/g) {$n++} END {print $n || 0}' "$REPO_DIR/$file" 2>/dev/null || printf '0')
    if [ "$count" -gt 0 ]; then
      printf '  [fail] %s has %s forbidden dash, arrow, or box characters\n' "$file" "$count"
      local_fail=1
    fi
  done
  report punctuation-clean "$local_fail"
}

check_emoji_free() {
  printf '== emoji-free ==\n'
  local_fail=0
  for file in $(text_files); do
    count=$(perl -CSD -ne 'while (/\p{Extended_Pictographic}/g) {$n++} END {print $n || 0}' "$REPO_DIR/$file" 2>/dev/null || printf '0')
    if [ "$count" -gt 0 ]; then printf '  [fail] %s has %s emoji\n' "$file" "$count"; local_fail=1; fi
  done
  report emoji-free "$local_fail"
}

check_version_parity() {
  printf '== version-parity ==\n'
  skill_v=$(metadata_value version)
  changelog_v=$(awk '/^## \[/{line=$0; sub(/^## \[/,"",line); sub(/\].*$/,"",line); print line; exit}' "$REPO_DIR/CHANGELOG.md")
  script_v=$(sed -n 's/^ARC_CHECK_VERSION="\(.*\)"$/\1/p' "$REPO_DIR/scripts/arc-check.sh")
  usage_v=$(bash "$REPO_DIR/scripts/arc-check.sh" --help | head -1 | awk '{print $2}' | tr -d ':')
  if [ -n "$skill_v" ] && [ "$skill_v" = "$changelog_v" ] && [ "$skill_v" = "$script_v" ] && [ "$skill_v" = "$usage_v" ]; then
    printf '  [ok] %s everywhere\n' "$skill_v"
    report version-parity 0
  else
    printf '  [fail] metadata=%s changelog=%s arc-check=%s usage=%s\n' "$skill_v" "$changelog_v" "$script_v" "$usage_v"
    report version-parity 1
  fi
}

check_compatible_with() {
  printf '== compatible-with ==\n'
  compat=$(metadata_value compatible-with)
  compatibility=$(awk -F': ' '/^compatibility:/{sub(/^compatibility: /,""); gsub(/^"|"$/,""); print; exit}' "$REPO_DIR/SKILL.md")
  local_fail=0
  [ -n "$compatibility" ] || { printf '  [fail] top-level compatibility is empty\n'; local_fail=1; }
  for expected in $EXPECTED_COMPAT; do
    case ",$compat," in
      *,$expected,*) [ "$VERBOSE" = "1" ] && printf '  [ok] %s\n' "$expected" ;;
      *) printf '  [fail] metadata.compatible-with missing %s\n' "$expected"; local_fail=1 ;;
    esac
  done
  report compatible-with "$local_fail"
}

check_standards_shape() {
  printf '== standards-shape ==\n'
  cd "$REPO_DIR"
  front="${TMPDIR:-/tmp}/arc-ready-frontmatter.$$"
  awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside {print}' SKILL.md > "$front"
  local_fail=0
  for field in $(awk -F: '/^[a-z][a-z0-9-]*:/{print $1}' "$front"); do
    case "$field" in
      name|description|license|compatibility|metadata|allowed-tools) ;;
      *) printf '  [fail] unexpected top-level field: %s\n' "$field"; local_fail=1 ;;
    esac
  done
  for required in name description license compatibility metadata; do
    grep -q "^${required}:" "$front" || { printf '  [fail] missing %s\n' "$required"; local_fail=1; }
  done
  [ "$(sed -n 's/^name: //p' "$front")" = "arc-ready" ] || { printf '  [fail] name must be arc-ready\n'; local_fail=1; }
  description=$(sed -n 's/^description: "\(.*\)"$/\1/p' "$front")
  compatibility=$(sed -n 's/^compatibility: "\(.*\)"$/\1/p' "$front")
  description_chars=$(LC_ALL=C printf '%s' "$description" | wc -c | tr -d ' ')
  compatibility_chars=$(LC_ALL=C printf '%s' "$compatibility" | wc -c | tr -d ' ')
  [ -n "$description" ] && [ "$description_chars" -le 1024 ] || { printf '  [fail] description length=%s\n' "$description_chars"; local_fail=1; }
  [ -n "$compatibility" ] && [ "$compatibility_chars" -le 500 ] || { printf '  [fail] compatibility length=%s\n' "$compatibility_chars"; local_fail=1; }
  metadata_lines=$(awk '/^metadata:/{inside=1; next} inside && /^[^ ]/{exit} inside {print}' "$front")
  if printf '%s\n' "$metadata_lines" | grep -vE '^  [a-z0-9-]+: ".*"$' | grep -q .; then
    printf '  [fail] metadata values must be quoted strings\n'
    local_fail=1
  fi
  rm -f "$front"
  [ "$local_fail" = "0" ] && printf '  [ok] %s description chars\n' "$description_chars"
  report standards-shape "$local_fail"
}

check_skill_budget() {
  printf '== skill-budget ==\n'
  local_fail=0
  bytes=$(wc -c < "$REPO_DIR/SKILL.md" | tr -d ' ')
  if [ "$bytes" -le "$SKILL_MAX_BYTES" ]; then
    printf '  [ok] SKILL.md is %s bytes (about %s tokens; limit %s bytes)\n' "$bytes" "$((bytes / 4))" "$SKILL_MAX_BYTES"
  else
    printf '  [fail] SKILL.md is %s bytes; limit %s. Move detail into scripts/arc-check.sh or cut it.\n' "$bytes" "$SKILL_MAX_BYTES"
    local_fail=1
  fi
  for file in "$REPO_DIR"/references/guided/*.md; do
    size=$(wc -c < "$file" | tr -d ' ')
    if [ "$size" -gt "$GUIDED_MAX_BYTES" ]; then printf '  [fail] %s is %s bytes; limit %s\n' "${file#$REPO_DIR/}" "$size" "$GUIDED_MAX_BYTES"; local_fail=1; fi
  done
  report skill-budget "$local_fail"
}

check_no_default_loads() {
  printf '== no-default-loads ==\n'
  local_fail=0
  if grep -nE 'references/' "$REPO_DIR/SKILL.md" | grep -v 'references/guided/' | grep -q .; then
    printf '  [fail] SKILL.md routes to references outside guided mode:\n'
    grep -nE 'references/' "$REPO_DIR/SKILL.md" | grep -v 'references/guided/' | sed 's/^/      /'
    local_fail=1
  fi
  outside=$(awk '/^## Guided mode/{g=1; next} /^## /{g=0} !g && /references\/guided/' "$REPO_DIR/SKILL.md")
  if [ -n "$outside" ]; then
    printf '  [fail] guided skeletons are referenced outside the Guided mode section\n'
    local_fail=1
  fi
  extra=$(find "$REPO_DIR/references" -type f ! -path "$REPO_DIR/references/guided/*" | sed "s|^$REPO_DIR/||")
  if [ -n "$extra" ]; then printf '  [fail] files under references/ outside guided/: %s\n' "$extra"; local_fail=1; fi
  report no-default-loads "$local_fail"
}

check_skill_paths_exist() {
  printf '== skill-paths-exist ==\n'
  cd "$REPO_DIR"
  local_fail=0
  for path in $(grep -oE '(scripts|references/guided)/[A-Za-z0-9_./-]+\.(sh|md)' SKILL.md | sort -u); do
    if [ -f "$path" ]; then [ "$VERBOSE" = "1" ] && printf '  [ok] %s\n' "$path"; else printf '  [fail] SKILL.md names missing %s\n' "$path"; local_fail=1; fi
  done
  guided_line=$(awk '/^## Guided mode/{g=1; next} /^## /{g=0} g' SKILL.md)
  for name in $(printf '%s\n' "$guided_line" | grep -oE '`[a-z]+\.md`' | tr -d '`' | sort -u); do
    [ -f "references/guided/$name" ] || { printf '  [fail] guided skeleton missing: references/guided/%s\n' "$name"; local_fail=1; }
  done
  for file in references/guided/*.md; do
    base=$(basename "$file")
    printf '%s\n' "$guided_line" | grep -q "\`$base\`" || { printf '  [fail] %s is not listed in SKILL.md guided mode\n' "$file"; local_fail=1; }
  done
  report skill-paths-exist "$local_fail"
}

check_links_resolve() {
  printf '== links-resolve ==\n'
  cd "$REPO_DIR"
  local_fail=0
  for file in $(text_files | grep -E '\.md$' | grep -Ev "$ARCHIVAL"); do
    dir=$(dirname "$file")
    for target in $(grep -oE '\]\([^)[:space:]]+\)' "$file" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//'); do
      [ -n "$target" ] || continue
      case "$target" in http://*|https://*|mailto:*) continue ;; esac
      if [ ! -e "$dir/$target" ]; then printf '  [fail] %s links missing %s\n' "$file" "$target"; local_fail=1; fi
    done
  done
  report links-resolve "$local_fail"
}

check_shell_syntax() {
  printf '== shell-syntax ==\n'
  local_fail=0
  for script in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/evals/ablation/*.sh; do
    bash -n "$script" || { printf '  [fail] %s\n' "${script#$REPO_DIR/}"; local_fail=1; }
  done
  report shell-syntax "$local_fail"
}

check_test_suite() {
  printf '== test-suite ==\n'
  if out=$(bash "$REPO_DIR/scripts/test.sh" 2>&1); then
    printf '  %s\n' "$(printf '%s\n' "$out" | tail -1)"
    report test-suite 0
  else
    printf '%s\n' "$out" | sed 's/^/  /'
    report test-suite 1
  fi
}

check_official_validator() {
  printf '== official-validator ==\n'
  if [ -n "${SKILLS_REF_BIN:-}" ]; then
    validator="$SKILLS_REF_BIN"
  elif command -v skills-ref >/dev/null 2>&1; then
    validator="$(command -v skills-ref)"
  else
    printf '  [skip] skills-ref not installed; release-check requires it\n\n'
    return
  fi
  if "$validator" validate "$REPO_DIR"; then report official-validator 0; else report official-validator 1; fi
}

check_tag_release_parity() {
  printf '== tag-release-parity ==\n'
  cd "$REPO_DIR"
  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    printf '  [skip] authenticated gh CLI not available\n\n'
    return
  fi
  local_fail=0
  for tag in $(git tag); do
    if ! gh release view "$tag" >/dev/null 2>&1; then printf '  [fail] %s has no GitHub Release\n' "$tag"; local_fail=1; fi
  done
  report tag-release-parity "$local_fail"
}

run_all() {
  check_punctuation_clean
  check_emoji_free
  check_version_parity
  check_compatible_with
  check_standards_shape
  check_skill_budget
  check_no_default_loads
  check_skill_paths_exist
  check_links_resolve
  check_shell_syntax
  check_test_suite
  check_official_validator
}

case "$SELECTED" in
  --all) run_all ;;
  punctuation-clean) check_punctuation_clean ;;
  emoji-free) check_emoji_free ;;
  version-parity) check_version_parity ;;
  compatible-with) check_compatible_with ;;
  standards-shape) check_standards_shape ;;
  skill-budget) check_skill_budget ;;
  no-default-loads) check_no_default_loads ;;
  skill-paths-exist) check_skill_paths_exist ;;
  links-resolve) check_links_resolve ;;
  shell-syntax) check_shell_syntax ;;
  test-suite) check_test_suite ;;
  official-validator) check_official_validator ;;
  tag-release-parity) check_tag_release_parity ;;
  *) printf 'unknown check: %s\n' "$SELECTED" >&2; usage >&2; exit 2 ;;
esac

if [ "$EXIT_CODE" = "0" ]; then printf '== arc-ready lint passed ==\n'; else printf '== arc-ready lint FAILED ==\n'; fi
exit "$EXIT_CODE"
