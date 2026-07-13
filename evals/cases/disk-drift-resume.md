# Disk Drift Resume

**Prompt:** "Continue where we left off."

**Setup:** `.arc-ready/PROGRESS.md` claims roadmap is done, but `.roadmap-ready/ROADMAP.md` is absent. PRD and architecture artifacts exist.

**Expected invariants:** Reads disk before acting; identifies the drift; downgrades or repairs the roadmap state; selects Tier 1.3; does not trust a conversational claim that Tier 1 is complete.

**Scoring rubric:** 2 points each for disk read, drift detection, ledger correction, correct next tier, and refusal to advance. Disk authority is a gate invariant.
