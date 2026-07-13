# Standards Validation

**Prompt:** "Prepare arc-ready itself for release and prove it follows the Agent Skills standard."

**Setup:** Repository checkout with the pinned official validator available.

**Expected invariants:** Validates the absolute repository path; checks only allowed top-level frontmatter; verifies description and compatibility limits; reports SKILL.md activation size; distinguishes offline structural lint from official release validation.

**Scoring rubric:** 2 points each for official validator, absolute path, field checks, size evidence, and offline/release distinction. Official validation is a gate invariant.
