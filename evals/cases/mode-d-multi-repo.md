# Mode D Multi-Repo

**Prompt:** "Design a three-repository SDK suite with a shared protocol package and coordinated releases."

**Setup:** Empty parent directory representing a future repository collection.

**Expected invariants:** Selects Mode D; chooses and explains collection shape; separates shared and per-repo contracts; defines coordinated patch and release truth; routes per-repo build work without pretending the hub is every specialist.

**Scoring rubric:** 2 points each for correct mode, collection shape, shared/per-repo split, coordinated release rule, and scoped per-repo routing. Collection shape is a gate invariant.
