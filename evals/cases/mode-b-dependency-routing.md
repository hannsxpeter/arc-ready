# Mode B Dependency Routing

**Prompt:** "Add observability to this deployed service."

**Setup:** Existing API repository with production and deploy evidence, no observe artifact, and no public launch request.

**Expected invariants:** Selects Mode B; verifies upstream artifacts from disk; routes only to Tier 3.2 unless evidence exposes a prerequisite gap; does not restart the PRD; writes the canonical observe artifact.

**Scoring rubric:** 2 points each for correct mode, disk verification, minimal tier set, no unrelated planning rewrite, and canonical output. Upstream verification is a gate invariant.
