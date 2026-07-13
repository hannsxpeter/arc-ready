# Live-Harness Evaluation Guide

Run each case in a clean fixture or disposable repository. Give the harness only the case prompt and setup plus the installed arc-ready skill. Do not coach it with expected answers.

Score each case from 0-10 using its five 0-2 criteria:

- 0: missing or contradicts the invariant.
- 1: partially present, ambiguous, or not evidenced on disk.
- 2: complete, explicit, and evidenced.

Passing is 8/10 or higher with no zero on a gate invariant. Record harness, model, skill commit, date, transcript or artifact links, scores, failures, and rerun outcome in `evals/RESULTS-TEMPLATE.md`.

The cases intentionally test behavior that static grep cannot establish: correct mode selection, minimal questioning, refusal boundaries, read-only audit behavior, disk-backed resume, product-form adaptation, and a fresh pre-publication security decision.
