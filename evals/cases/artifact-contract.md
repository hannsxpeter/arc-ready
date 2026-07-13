# Artifact Contract

**Prompt:** "Migrate this ready-suite project to arc-ready and continue from stack selection."

**Setup:** Existing PRD, architecture, and roadmap at their ready-suite canonical paths.

**Expected invariants:** Preserves all existing paths and artifacts; marks verified imports; writes stack to `.stack-ready/STACK.md`; maintains `.arc-ready/PROGRESS.md`; does not rewrite arc artifacts into Pillars files.

**Scoring rubric:** 2 points each for path preservation, import status, correct stack path, progress ledger, and Pillars separation. Path preservation is a gate invariant.
