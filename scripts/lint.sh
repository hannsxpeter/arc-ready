#!/usr/bin/env bash
# arc-ready repository meta-linter. Bash 3.2 compatible.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOAD_BEARING_FILES="SKILL.md README.md AGENTS.md SECURITY.md CONTRIBUTING.md MAINTAINING.md MIGRATION.md EVALS.md"
EXPECTED_COMPAT="claude-code codex cursor windsurf pi openclaw any-agentskills-compatible-harness"
FORBIDDEN_PATTERN=$'\xe2\x80\x94\|\xe2\x80\x93\|\xe2\x80\x95\|\xe2\x80\x90\|\xe2\x80\x92\|\xe2\x88\x92\|\xe2\x86\x92\|\xe2\x86\x90\|\xe2\x86\x91\|\xe2\x86\x93'

VERBOSE=0
FAIL_FAST=0
SELECTED="--all"
EXIT_CODE=0

usage() {
  cat <<'EOF'
arc-ready-lint: repository and skill contract checks

Usage: bash scripts/lint.sh [check | --all] [--verbose] [--fail-fast]

Offline checks run by --all:
  unicode-clean             load-bearing files contain no forbidden punctuation
  unicode-baseline          no net-new inherited punctuation or emoji
  frontmatter-version       metadata.version matches CHANGELOG top entry
  skill-version-body        body schema version lines match metadata.version
  compatible-with           compatibility metadata names supported clients
  standards-shape           Agent Skills fields and scalar limits are valid
  skill-size-budget         SKILL.md stays below 500 lines and 5000 words
  references-exist          every direct SKILL.md reference exists
  reference-basenames       reference basenames remain globally unique
  relative-links-resolve    reference markdown links resolve
  reference-citations       references/<basename>.md citations exist
  tier-folders-populated    all five tier folders contain markdown
  shell-syntax              every repository Bash script parses
  eval-suite                deterministic evaluation suite passes
  official-validator        runs skills-ref when installed, otherwise skips

Release-only check:
  tag-release-parity        every existing tag has a GitHub Release
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

metadata_value() {
  key="$1"
  awk -v wanted="$key" '
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

check_unicode_clean() {
  printf '== unicode-clean ==\n'
  local_fail=0
  cd "$REPO_DIR"
  for file in $LOAD_BEARING_FILES; do
    if [ ! -f "$file" ]; then
      printf '  [fail] missing load-bearing file %s\n' "$file"
      local_fail=1
    elif grep -nE "$FORBIDDEN_PATTERN" "$file" >/dev/null 2>&1; then
      printf '  [fail] %s contains forbidden punctuation\n' "$file"
      grep -nE "$FORBIDDEN_PATTERN" "$file" | head -10 | sed 's/^/      /'
      local_fail=1
    elif [ "$VERBOSE" = "1" ]; then
      printf '  [ok] %s\n' "$file"
    fi
  done

  awk '/^## /{count++; if (count==2) exit} {print}' CHANGELOG.md > "${TMPDIR:-/tmp}/arc-ready-top-changelog.$$"
  if grep -nE "$FORBIDDEN_PATTERN" "${TMPDIR:-/tmp}/arc-ready-top-changelog.$$" >/dev/null 2>&1; then
    printf '  [fail] top CHANGELOG entry contains forbidden punctuation\n'
    local_fail=1
  fi
  rm -f "${TMPDIR:-/tmp}/arc-ready-top-changelog.$$"

  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [unicode-clean] FAILED\n\n'; else printf '  [unicode-clean] passed\n\n'; fi
}

check_unicode_baseline() {
  printf '== unicode-baseline ==\n'
  cd "$REPO_DIR"
  baseline="config/unicode-baseline.txt"
  if [ ! -f "$baseline" ]; then
    printf '  [fail] %s missing\n\n' "$baseline"
    mark_fail
    return
  fi

  local_fail=0
  for file in $(git ls-files --cached --others --exclude-standard | sort); do
    [ -f "$file" ] || continue
    policy=$(perl -CSD -ne 'while (/[\x{2010}-\x{2015}\x{2190}-\x{21FF}\x{2500}-\x{257F}]/g) {$n++} END {print $n || 0}' "$file" 2>/dev/null || printf '0')
    emoji=$(perl -CSD -ne 'while (/\p{Extended_Pictographic}/g) {$n++} END {print $n || 0}' "$file" 2>/dev/null || printf '0')
    allowed_line=$(awk -F'|' -v path="$file" '$1 == path {print; exit}' "$baseline")
    allowed_policy=$(printf '%s' "$allowed_line" | awk -F'|' '{print $2}')
    allowed_emoji=$(printf '%s' "$allowed_line" | awk -F'|' '{print $3}')
    allowed_policy=${allowed_policy:-0}
    allowed_emoji=${allowed_emoji:-0}
    if [ "$policy" -gt "$allowed_policy" ] || [ "$emoji" -gt "$allowed_emoji" ]; then
      printf '  [fail] %s policy=%s/%s emoji=%s/%s\n' "$file" "$policy" "$allowed_policy" "$emoji" "$allowed_emoji"
      local_fail=1
    elif [ "$VERBOSE" = "1" ] && { [ "$policy" -gt 0 ] || [ "$emoji" -gt 0 ]; }; then
      printf '  [ok] %s policy=%s emoji=%s\n' "$file" "$policy" "$emoji"
    fi
  done

  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [unicode-baseline] FAILED\n\n'; else printf '  [unicode-baseline] passed\n\n'; fi
}

check_frontmatter_version() {
  printf '== frontmatter-version ==\n'
  skill_v=$(metadata_value version)
  changelog_v=$(awk '/^## \[/{line=$0; sub(/^## \[/,"",line); sub(/\].*$/,"",line); print line; exit}' "$REPO_DIR/CHANGELOG.md")
  if [ -n "$skill_v" ] && [ "$skill_v" = "$changelog_v" ]; then
    printf '  [ok] metadata.version=%s matches CHANGELOG\n\n' "$skill_v"
  else
    printf '  [fail] metadata.version=%s CHANGELOG=%s\n\n' "$skill_v" "$changelog_v"
    mark_fail
  fi
}

check_skill_version_body() {
  printf '== skill-version-body ==\n'
  cd "$REPO_DIR"
  skill_v=$(metadata_value version)
  local_fail=0
  matches="${TMPDIR:-/tmp}/arc-ready-skill-version.$$"
  grep -RnE '^## Skill version: ' SKILL.md references > "$matches" 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    body_v=$(printf '%s' "$line" | sed -E 's/.*Skill version: *//; s/[[:space:]]*$//')
    if [ "$body_v" != "$skill_v" ]; then
      printf '  [fail] %s does not match metadata.version %s\n' "$line" "$skill_v"
      local_fail=1
    fi
  done < "$matches"
  rm -f "$matches"
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [skill-version-body] FAILED\n\n'; else printf '  [skill-version-body] passed\n\n'; fi
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
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [compatible-with] FAILED\n\n'; else printf '  [compatible-with] passed\n\n'; fi
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
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [standards-shape] FAILED\n\n'; else printf '  [standards-shape] passed (%s description chars)\n\n' "$description_chars"; fi
}

check_skill_size_budget() {
  printf '== skill-size-budget ==\n'
  lines=$(wc -l < "$REPO_DIR/SKILL.md" | tr -d ' ')
  words=$(wc -w < "$REPO_DIR/SKILL.md" | tr -d ' ')
  if [ "$lines" -lt 500 ] && [ "$words" -lt 5000 ]; then
    printf '  [ok] SKILL.md lines=%s words=%s\n\n' "$lines" "$words"
  else
    printf '  [fail] SKILL.md lines=%s words=%s\n\n' "$lines" "$words"
    mark_fail
  fi
}

check_references_exist() {
  printf '== references-exist ==\n'
  cd "$REPO_DIR"
  refs="${TMPDIR:-/tmp}/arc-ready-refs.$$"
  grep -oE 'references/[a-z]+/[a-zA-Z0-9_./-]+\.md' SKILL.md | sort -u > "$refs"
  local_fail=0
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if [ ! -f "$ref" ]; then printf '  [fail] missing %s\n' "$ref"; local_fail=1; elif [ "$VERBOSE" = "1" ]; then printf '  [ok] %s\n' "$ref"; fi
  done < "$refs"
  rm -f "$refs"
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [references-exist] FAILED\n\n'; else printf '  [references-exist] passed\n\n'; fi
}

check_reference_basenames() {
  printf '== reference-basenames ==\n'
  cd "$REPO_DIR"
  dupes=$(find references -name '*.md' -exec basename {} \; | sort | uniq -d)
  if [ -n "$dupes" ]; then
    printf '  [fail] duplicate reference basenames:\n%s\n\n' "$dupes"
    mark_fail
  else
    printf '  [reference-basenames] passed\n\n'
  fi
}

check_relative_links() {
  printf '== relative-links-resolve ==\n'
  cd "$REPO_DIR"
  refnames="${TMPDIR:-/tmp}/arc-ready-refnames.$$"
  files="${TMPDIR:-/tmp}/arc-ready-reffiles.$$"
  fails="${TMPDIR:-/tmp}/arc-ready-rellinks.$$"
  find references -name '*.md' -exec basename {} \; | sort -u > "$refnames"
  find references -name '*.md' | sort > "$files"
  : > "$fails"
  while IFS= read -r file; do
    dir=$(dirname "$file")
    grep -oE '\]\([^)]+\.md[^)]*\)' "$file" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | while IFS= read -r target; do
      [ -n "$target" ] || continue
      case "$target" in http*|/*|.*-ready/*) continue ;; esac
      base=$(basename "$target")
      if grep -qx "$base" "$refnames" && [ ! -f "$dir/$target" ]; then
        printf '%s links unresolved %s\n' "$file" "$target" >> "$fails"
      fi
    done
  done < "$files"
  if [ -s "$fails" ]; then sed 's/^/  [fail] /' "$fails"; mark_fail; printf '  [relative-links-resolve] FAILED\n\n'; else printf '  [relative-links-resolve] passed\n\n'; fi
  rm -f "$refnames" "$files" "$fails"
}

check_reference_citations() {
  printf '== reference-citations ==\n'
  cd "$REPO_DIR"
  refnames="${TMPDIR:-/tmp}/arc-ready-refnames-citations.$$"
  find references -name '*.md' -exec basename {} \; | sort -u > "$refnames"
  local_fail=0
  for base in $(grep -rhoE 'references/[a-z][a-z0-9-]+\.md' references 2>/dev/null | sed 's|references/||' | sort -u); do
    if ! grep -qx "$base" "$refnames"; then printf '  [fail] missing cited reference %s\n' "$base"; local_fail=1; fi
  done
  rm -f "$refnames"
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [reference-citations] FAILED\n\n'; else printf '  [reference-citations] passed\n\n'; fi
}

check_tier_folders() {
  printf '== tier-folders-populated ==\n'
  local_fail=0
  for tier in orchestration planning building shipping shared; do
    count=$(find "$REPO_DIR/references/$tier" -name '*.md' | wc -l | tr -d ' ')
    if [ "$count" -lt 1 ]; then printf '  [fail] references/%s is empty\n' "$tier"; local_fail=1; elif [ "$VERBOSE" = "1" ]; then printf '  [ok] references/%s has %s files\n' "$tier" "$count"; fi
  done
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [tier-folders-populated] FAILED\n\n'; else printf '  [tier-folders-populated] passed\n\n'; fi
}

check_shell_syntax() {
  printf '== shell-syntax ==\n'
  if bash -n "$REPO_DIR"/scripts/*.sh; then printf '  [shell-syntax] passed\n\n'; else mark_fail; printf '  [shell-syntax] FAILED\n\n'; fi
}

check_eval_suite() {
  printf '== eval-suite ==\n'
  if bash "$REPO_DIR/scripts/eval.sh" >/dev/null; then printf '  [eval-suite] passed\n\n'; else mark_fail; printf '  [eval-suite] FAILED\n\n'; fi
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
  if "$validator" validate "$REPO_DIR"; then printf '  [official-validator] passed\n\n'; else mark_fail; printf '  [official-validator] FAILED\n\n'; fi
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
  if [ "$local_fail" = "1" ]; then mark_fail; printf '  [tag-release-parity] FAILED\n\n'; else printf '  [tag-release-parity] passed\n\n'; fi
}

run_all() {
  check_unicode_clean
  check_unicode_baseline
  check_frontmatter_version
  check_skill_version_body
  check_compatible_with
  check_standards_shape
  check_skill_size_budget
  check_references_exist
  check_reference_basenames
  check_relative_links
  check_reference_citations
  check_tier_folders
  check_shell_syntax
  check_eval_suite
  check_official_validator
}

case "$SELECTED" in
  --all) run_all ;;
  unicode-clean) check_unicode_clean ;;
  unicode-baseline) check_unicode_baseline ;;
  frontmatter-version) check_frontmatter_version ;;
  skill-version-body) check_skill_version_body ;;
  compatible-with) check_compatible_with ;;
  standards-shape) check_standards_shape ;;
  skill-size-budget) check_skill_size_budget ;;
  references-exist) check_references_exist ;;
  reference-basenames) check_reference_basenames ;;
  relative-links-resolve) check_relative_links ;;
  reference-citations) check_reference_citations ;;
  tier-folders-populated) check_tier_folders ;;
  shell-syntax) check_shell_syntax ;;
  eval-suite) check_eval_suite ;;
  official-validator) check_official_validator ;;
  tag-release-parity) check_tag_release_parity ;;
  *) printf 'unknown check: %s\n' "$SELECTED" >&2; usage >&2; exit 2 ;;
esac

if [ "$EXIT_CODE" = "0" ]; then printf '== arc-ready lint passed ==\n'; else printf '== arc-ready lint FAILED ==\n'; fi
exit "$EXIT_CODE"
