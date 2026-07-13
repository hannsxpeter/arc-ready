#!/usr/bin/env bash
# Release-grade local evidence. Requires the pinned official validator installed.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${SKILLS_REF_BIN:-}" ]; then
  VALIDATOR="$SKILLS_REF_BIN"
elif command -v skills-ref >/dev/null 2>&1; then
  VALIDATOR="$(command -v skills-ref)"
else
  printf '%s\n' "[fail] skills-ref is required for release validation." >&2
  printf '%s\n' "Install the pinned validator in an isolated environment:" >&2
  printf '%s\n' "  python3 -m venv .venv-skills-ref" >&2
  printf '%s\n' "  .venv-skills-ref/bin/pip install -r requirements/skills-ref.txt" >&2
  printf '%s\n' "Then set SKILLS_REF_BIN=.venv-skills-ref/bin/skills-ref and rerun." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  printf '%s\n' "[fail] authenticated gh CLI is required for release tag parity." >&2
  exit 1
fi

cd "$REPO_DIR"
bash -n scripts/*.sh
SKILLS_REF_BIN="$VALIDATOR" bash scripts/lint.sh --all --verbose
bash scripts/dogfood-smoke.sh --verbose
bash scripts/eval.sh --verbose
"$VALIDATOR" validate "$REPO_DIR"
bash scripts/lint.sh tag-release-parity --verbose
printf '%s\n' "== local release checks passed =="
printf '%s\n' "Live-harness scores remain separately required by EVALS.md."
