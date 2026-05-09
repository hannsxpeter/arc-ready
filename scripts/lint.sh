#!/usr/bin/env bash
# scripts/lint.sh: meta-linter for arc-ready (single-repo).
#
# Mechanically enforces the discipline rules. Replaces "the rule says X"
# with "CI fails if X is violated."
#
# Checks (run with --all, default):
#
#   unicode-clean          no em-dashes, en-dashes, arrows, or box-drawing
#                          characters in load-bearing files (SKILL.md whole-file,
#                          README.md whole-file, AGENTS.md, SECURITY.md,
#                          CONTRIBUTING.md, MAINTAINING.md, MIGRATION.md, top
#                          CHANGELOG entry only). Inherited reference files are
#                          exempt (faithful copies from source ready-suite skills).
#   frontmatter-version    SKILL.md frontmatter `version:` matches the top
#                          CHANGELOG entry version `## [X.Y.Z]`.
#   compatible-with        SKILL.md `compatible_with:` includes the standards-
#                          level harness names.
#   references-exist       every `references/<tier>/<file>.md` mentioned in
#                          SKILL.md exists on disk.
#   tier-folders-populated `references/{orchestration,planning,building,shipping,
#                          shared}` each have at least one .md file.
#   tag-release-parity     every git tag has a matching GitHub Release.
#                          Requires `gh` authenticated. CI-only by default.
#
# Usage:
#   bash scripts/lint.sh [check-name | --all] [--verbose] [--fail-fast]
#
# Bash 3.2 compatible (macOS default). No associative arrays, no mapfile.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load-bearing files: arc-ready-authored, lint-enforced for unicode cleanliness.
LOAD_BEARING_FILES="SKILL.md README.md AGENTS.md SECURITY.md CONTRIBUTING.md MAINTAINING.md MIGRATION.md"

# Standards-level compatible_with values SKILL.md must declare.
EXPECTED_COMPAT="claude-code codex cursor windsurf pi openclaw any-agentskills-compatible-harness"

# Forbidden unicode in load-bearing files.
# Em-dash, en-dash, horizontal-bar, hyphen-point, figure-dash, minus, arrows.
FORBIDDEN_PATTERN=$'\xe2\x80\x94\|\xe2\x80\x93\|\xe2\x80\x95\|\xe2\x80\x90\|\xe2\x80\x92\|\xe2\x88\x92\|\xe2\x86\x92\|\xe2\x86\x90\|\xe2\x86\x91\|\xe2\x86\x93'

VERBOSE=0
FAIL_FAST=0
SELECTED="--all"

if [ -t 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_RED="$(printf '\033[31m')"
  C_CYAN="$(printf '\033[36m')"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""
fi

usage() {
  cat <<EOF
arc-ready-lint: meta-linter for arc-ready

Usage: bash scripts/lint.sh [check | --all] [--verbose] [--fail-fast]

Checks:
  unicode-clean          no em-dashes / en-dashes / arrows / box-drawing
                         in load-bearing files
  frontmatter-version    SKILL.md version matches top CHANGELOG entry
  compatible-with        SKILL.md compatible_with frontmatter contains
                         standards-level harness names
  references-exist       every references/<tier>/*.md path in SKILL.md exists
  tier-folders-populated all five tier folders have at least one file
  tag-release-parity     every git tag has a matching GitHub Release
                         (CI-only by default; requires gh auth)

Flags:
  --all                  run every check (default)
  --verbose              show ok lines, not just failures
  --fail-fast            stop at the first failing check
  -h, --help             this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=1 ;;
    --fail-fast) FAIL_FAST=1 ;;
    --all) SELECTED="--all" ;;
    -h|--help) usage; exit 0 ;;
    --*) printf "%sunknown flag: %s%s\n" "$C_RED" "$1" "$C_RESET" >&2; usage >&2; exit 2 ;;
    *) SELECTED="$1" ;;
  esac
  shift
done

EXIT_CODE=0
mark_fail() {
  EXIT_CODE=1
  if [ "$FAIL_FAST" = "1" ]; then
    printf "%s[fail-fast] stopping%s\n" "$C_RED" "$C_RESET" >&2
    exit 1
  fi
}

# ---------- check: unicode-clean ----------
check_unicode_clean() {
  printf "%s== unicode-clean ==%s\n" "$C_BOLD" "$C_RESET"
  local local_fail=0
  cd "$REPO_DIR"

  for f in $LOAD_BEARING_FILES; do
    if [ ! -f "$f" ]; then
      printf "  %s[skip] %s (missing)%s\n" "$C_YELLOW" "$f" "$C_RESET"
      continue
    fi
    if grep -nE "$FORBIDDEN_PATTERN" "$f" >/dev/null 2>&1; then
      printf "  %s[fail] %s contains forbidden unicode:%s\n" "$C_RED" "$f" "$C_RESET"
      grep -nE "$FORBIDDEN_PATTERN" "$f" | head -10 | sed 's/^/      /'
      local_fail=1
    elif [ "$VERBOSE" = "1" ]; then
      printf "  %s[ok] %s%s\n" "$C_GREEN" "$f" "$C_RESET"
    fi
  done

  if [ -f "CHANGELOG.md" ]; then
    awk '/^## /{n++; if (n==2) exit} {print}' CHANGELOG.md > /tmp/arc-ready-top-changelog.txt
    if grep -nE "$FORBIDDEN_PATTERN" /tmp/arc-ready-top-changelog.txt >/dev/null 2>&1; then
      printf "  %s[fail] top CHANGELOG entry contains forbidden unicode:%s\n" "$C_RED" "$C_RESET"
      grep -nE "$FORBIDDEN_PATTERN" /tmp/arc-ready-top-changelog.txt | head -10 | sed 's/^/      /'
      local_fail=1
    elif [ "$VERBOSE" = "1" ]; then
      printf "  %s[ok] CHANGELOG.md (top entry)%s\n" "$C_GREEN" "$C_RESET"
    fi
    rm -f /tmp/arc-ready-top-changelog.txt
  fi

  if [ "$local_fail" = "1" ]; then
    mark_fail
    printf "  %s[unicode-clean] FAILED%s\n\n" "$C_RED" "$C_RESET"
  else
    printf "  %s[unicode-clean] passed%s\n\n" "$C_GREEN" "$C_RESET"
  fi
}

# ---------- check: frontmatter-version ----------
check_frontmatter_version() {
  printf "%s== frontmatter-version ==%s\n" "$C_BOLD" "$C_RESET"
  cd "$REPO_DIR"

  if [ ! -f "SKILL.md" ] || [ ! -f "CHANGELOG.md" ]; then
    printf "  %s[skip] SKILL.md or CHANGELOG.md missing%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi

  local skill_v
  skill_v=$(awk -F': *' '/^version:/{gsub(/["'"'"' ]/,"",$2); print $2; exit}' SKILL.md)
  local changelog_v
  changelog_v=$(awk '/^## \[/{
    line=$0
    sub(/^## \[/, "", line)
    sub(/\].*$/, "", line)
    print line
    exit
  }' CHANGELOG.md)

  if [ -z "$skill_v" ]; then
    printf "  %s[fail] SKILL.md missing version: in frontmatter%s\n\n" "$C_RED" "$C_RESET"
    mark_fail
    return
  fi
  if [ -z "$changelog_v" ]; then
    printf "  %s[fail] CHANGELOG.md missing top ## [X.Y.Z] entry%s\n\n" "$C_RED" "$C_RESET"
    mark_fail
    return
  fi

  if [ "$skill_v" = "$changelog_v" ]; then
    printf "  %s[ok] SKILL.md version=%s matches CHANGELOG top=%s%s\n\n" "$C_GREEN" "$skill_v" "$changelog_v" "$C_RESET"
  else
    printf "  %s[fail] SKILL.md version=%s != CHANGELOG top=%s%s\n\n" "$C_RED" "$skill_v" "$changelog_v" "$C_RESET"
    mark_fail
  fi
}

# ---------- check: compatible-with ----------
check_compatible_with() {
  printf "%s== compatible-with ==%s\n" "$C_BOLD" "$C_RESET"
  cd "$REPO_DIR"

  if [ ! -f "SKILL.md" ]; then
    printf "  %s[skip] SKILL.md missing%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi

  awk '
    /^compatible_with:/ { inblk=1; next }
    inblk && /^[a-z]/ { inblk=0 }
    inblk && /^  - / { sub(/^  - /,""); print }
  ' SKILL.md > /tmp/arc-ready-compat.txt

  local local_fail=0
  for expected in $EXPECTED_COMPAT; do
    if grep -qx "$expected" /tmp/arc-ready-compat.txt; then
      [ "$VERBOSE" = "1" ] && printf "  %s[ok] %s%s\n" "$C_GREEN" "$expected" "$C_RESET"
    else
      printf "  %s[fail] missing compatible_with: %s%s\n" "$C_RED" "$expected" "$C_RESET"
      local_fail=1
    fi
  done
  rm -f /tmp/arc-ready-compat.txt

  if [ "$local_fail" = "1" ]; then
    mark_fail
    printf "  %s[compatible-with] FAILED%s\n\n" "$C_RED" "$C_RESET"
  else
    printf "  %s[compatible-with] passed%s\n\n" "$C_GREEN" "$C_RESET"
  fi
}

# ---------- check: references-exist ----------
check_references_exist() {
  printf "%s== references-exist ==%s\n" "$C_BOLD" "$C_RESET"
  cd "$REPO_DIR"

  if [ ! -f "SKILL.md" ]; then
    printf "  %s[skip] SKILL.md missing%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi

  grep -oE 'references/[a-z]+/[a-zA-Z0-9_./-]+\.md' SKILL.md | sort -u > /tmp/arc-ready-refs.txt

  local local_fail=0
  while IFS= read -r ref; do
    if [ -z "$ref" ]; then continue; fi
    if [ ! -f "$ref" ]; then
      printf "  %s[fail] %s mentioned in SKILL.md but does not exist%s\n" "$C_RED" "$ref" "$C_RESET"
      local_fail=1
    elif [ "$VERBOSE" = "1" ]; then
      printf "  %s[ok] %s%s\n" "$C_GREEN" "$ref" "$C_RESET"
    fi
  done < /tmp/arc-ready-refs.txt
  rm -f /tmp/arc-ready-refs.txt

  if [ "$local_fail" = "1" ]; then
    mark_fail
    printf "  %s[references-exist] FAILED%s\n\n" "$C_RED" "$C_RESET"
  else
    printf "  %s[references-exist] passed%s\n\n" "$C_GREEN" "$C_RESET"
  fi
}

# ---------- check: tier-folders-populated ----------
check_tier_folders_populated() {
  printf "%s== tier-folders-populated ==%s\n" "$C_BOLD" "$C_RESET"
  cd "$REPO_DIR"

  local local_fail=0
  for tier in orchestration planning building shipping shared; do
    local count
    count=$(find "references/$tier" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -lt 1 ]; then
      printf "  %s[fail] references/%s has 0 .md files%s\n" "$C_RED" "$tier" "$C_RESET"
      local_fail=1
    elif [ "$VERBOSE" = "1" ]; then
      printf "  %s[ok] references/%s has %s .md files%s\n" "$C_GREEN" "$tier" "$count" "$C_RESET"
    fi
  done

  if [ "$local_fail" = "1" ]; then
    mark_fail
    printf "  %s[tier-folders-populated] FAILED%s\n\n" "$C_RED" "$C_RESET"
  else
    printf "  %s[tier-folders-populated] passed%s\n\n" "$C_GREEN" "$C_RESET"
  fi
}

# ---------- check: tag-release-parity ----------
check_tag_release_parity() {
  printf "%s== tag-release-parity ==%s\n" "$C_BOLD" "$C_RESET"
  cd "$REPO_DIR"

  if ! command -v gh >/dev/null 2>&1; then
    printf "  %s[skip] gh CLI not available%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi
  if ! gh auth status >/dev/null 2>&1; then
    printf "  %s[skip] gh not authenticated%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi

  local tags
  tags=$(git tag 2>/dev/null || true)
  if [ -z "$tags" ]; then
    printf "  %s[skip] no tags yet%s\n\n" "$C_YELLOW" "$C_RESET"
    return
  fi

  local local_fail=0
  for tag in $tags; do
    if gh release view "$tag" >/dev/null 2>&1; then
      [ "$VERBOSE" = "1" ] && printf "  %s[ok] %s has release%s\n" "$C_GREEN" "$tag" "$C_RESET"
    else
      printf "  %s[fail] tag %s has no GitHub Release%s\n" "$C_RED" "$tag" "$C_RESET"
      local_fail=1
    fi
  done

  if [ "$local_fail" = "1" ]; then
    mark_fail
    printf "  %s[tag-release-parity] FAILED%s\n\n" "$C_RED" "$C_RESET"
  else
    printf "  %s[tag-release-parity] passed%s\n\n" "$C_GREEN" "$C_RESET"
  fi
}

# ---------- run ----------
run_all() {
  check_unicode_clean
  check_frontmatter_version
  check_compatible_with
  check_references_exist
  check_tier_folders_populated
  check_tag_release_parity
}

case "$SELECTED" in
  --all|all) run_all ;;
  unicode-clean) check_unicode_clean ;;
  frontmatter-version) check_frontmatter_version ;;
  compatible-with) check_compatible_with ;;
  references-exist) check_references_exist ;;
  tier-folders-populated) check_tier_folders_populated ;;
  tag-release-parity) check_tag_release_parity ;;
  *) printf "%sunknown check: %s%s\n" "$C_RED" "$SELECTED" "$C_RESET" >&2; usage >&2; exit 2 ;;
esac

if [ "$EXIT_CODE" = "0" ]; then
  printf "%s== arc-ready lint passed ==%s\n" "$C_GREEN$C_BOLD" "$C_RESET"
else
  printf "%s== arc-ready lint FAILED ==%s\n" "$C_RED$C_BOLD" "$C_RESET"
fi

exit $EXIT_CODE
