# Resume Protocol

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Resume protocol elaborated

The resume protocol is the single most-important defense against phantom resume (a known Anthropic claude-code failure mode, Issue #42338, #42260, #42309). Every arc-ready turn begins with this protocol; never trust the cached conversation about what tier or sub-step we are on.

### The protocol, step by step

```bash
# 1. Read the ledger.
test -f .arc-ready/PROGRESS.md && cat .arc-ready/PROGRESS.md > /tmp/progress.txt

# 2. Drift check: every "done" or "imported" tier must have its artifact on disk.
for tier in prd architecture roadmap stack repo production deploy observe launch harden; do
  tier_uc=$(printf '%s' "$tier" | tr 'a-z' 'A-Z')   # Bash 3.2 (macOS default) has no ${tier^^}
  [ "$tier" = architecture ] && tier_uc=ARCH        # ledger label is (ARCH), dir is .architecture-ready
  if grep -qE "^- [0-9.]+ \(${tier_uc}\): (done|imported)" /tmp/progress.txt 2>/dev/null \
     || grep -qiE "^- ${tier}-ready: (done|imported)" /tmp/progress.txt; then
    if [ ! -d ".${tier}-ready" ] || [ -z "$(ls .${tier}-ready 2>/dev/null)" ]; then
      echo "[drift] PROGRESS.md says ${tier} done/imported but .${tier}-ready/ is missing or empty"
    fi
  fi
done

# 3. Identify the next sub-step in DEPENDENCY order, not file order.
# The dependency order is fixed: 1.1 -> 1.2 -> 1.3 -> 1.4 -> 2.1 -> 2.2 ->
# 3.1 -> 3.2 -> (3.3 || 3.4 in parallel). The next sub-step is the FIRST
# entry in that order whose status is `pending` or `in-flight` AND whose
# upstream tier is `done` or `imported` (or is itself the user-declared
# starting tier in Mode B).
ordered_tiers="1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4"
next_substep=""
prior_done=true
for t in $ordered_tiers; do
  status=$(grep -E "^- ${t}" /tmp/progress.txt | sed -E 's/.*: *([a-z-]+).*/\1/' | head -1)
  case "$status" in
    done|imported|skipped)
      prior_done=true
      continue
      ;;
    pending|in-flight|failed|"")
      if [ "$prior_done" = "true" ]; then
        next_substep="$t"
        break
      fi
      ;;
  esac
done
echo "next_sub_step: ${next_substep:-arc-complete}"

# 4. Record the resume verification with a timestamp.
echo "" >> .arc-ready/PROGRESS.md
echo "## Resume verification: $(date -u +%FT%TZ)" >> .arc-ready/PROGRESS.md
echo "next_sub_step: ${next_substep:-arc-complete}" >> .arc-ready/PROGRESS.md
```

Two things this heuristic gets right that the v0.1.5 version did not:

1. It walks tiers in **dependency order**, so a Mode A project with PRD imported and ARCH in-flight resolves to next-sub-step `1.2`, not `0`.
2. It treats `skipped` as a complete status, so an explicit skip does not block downstream tier dispatch.

The launch / harden parallelism (3.3 || 3.4) is handled by the heuristic returning whichever is first non-complete; the actual parallelism decision is made in SKILL.md Tier 3 dispatch text, not in this resume snippet.

The protocol runs every turn, not just on explicit resume. Cache invalidations, compression-summary loss, stale tool-result state can all drift the conversation away from disk truth. Disk wins.

### What disk-wins means in practice

If PROGRESS.md says Tier 1.4 (stack) is done but `.stack-ready/STACK.md` does not exist, the conversation is wrong; PROGRESS.md is wrong; only disk is right. Correct PROGRESS.md (downgrade Tier 1.4 to `pending`) and re-run the sub-step.

If PROGRESS.md says Tier 1.1 is `pending` but `.prd-ready/PRD.md` exists and is non-empty, the user has imported a PRD. Verify the import, mark `1.1: imported`, and proceed.

If the conversation memory says "we just finished Tier 2.2 in the last reply," but `.production-ready/STATE.md` does not show the slice queue completed, the conversation is hallucinating progress. The first turn after a long pause must always re-derive state from disk before claiming any progress.
