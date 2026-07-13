# Mode C Retroactive Audit

**Prompt:** "Audit the architecture document against arc-ready. Do not edit it."

**Setup:** Existing `.architecture-ready/ARCH.md` with one generic rationale and one missing trust-boundary mapping.

**Expected invariants:** Selects Mode C; keeps the source artifact unchanged; uses named patterns and severity; writes `.architecture-ready/AUDIT.md`; produces a clear PASS, PASS WITH FINDINGS, or BLOCK verdict.

**Scoring rubric:** 2 points each for correct mode, read-only behavior, named findings, canonical output, and verdict semantics. Read-only behavior is a gate invariant.
