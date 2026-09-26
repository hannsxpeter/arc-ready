# Drift audit: 1.2.1 to 2.0.0

Recorded 2026-09-26 while preparing arc-ready 2.0.0. Each entry is a place where the 1.2.1 documentation or contracts disagreed with what was actually true, how that was checked, and what 2.0.0 does about it. The 1.2.1 files cited here remain readable at the `v1.2.1` tag.

## Install and packaging

**1. An install command that does not exist.** The README said to "run `/skills install` from this repo" in Claude Code. Claude Code has no such command; a skill installs by placing its directory under `~/.claude/skills/` (or a project's `.claude/skills/`). Checked against the Claude Code CLI 2.1.274 help and documentation. The README now documents `git clone` into the skills directory.

**2. A plugin that could not install.** `plugins/arc-ready/` held a `plugin.json`, but the repository had no `.claude-plugin/marketplace.json`, so `/plugin marketplace add hannsxpeter/arc-ready` had nothing to find. The plugin's skill directory was two symlinks pointing outside the plugin root, which the plugin documentation does not cover, and its description and version had drifted from `SKILL.md`. Removed in 2.0.0.

**3. A Cursor and Windsurf path that dropped the workflow.** The README said to copy `SKILL.md` into the editor's rules directory. In 1.x, `SKILL.md` routed every tier to files under `references/` that a copied `SKILL.md` could not reach. The 2.0.0 `SKILL.md` is self-contained, and `.cursorrules` now points at the cloned skill so `scripts/arc-check.sh` is available too.

## Claims about enforcement and evidence

**4. "A mechanical check behind" every failure mode.** The README said each refusal was "a named failure mode with a mechanical check behind it". The checks were shell snippets inside `references/orchestration/verification-grep-tests.md`; nothing shipped ran them, so enforcement depended on the agent choosing to. In 2.0.0, `scripts/arc-check.sh` runs a gate whenever an agent records a tier as done, and the README separates what the script enforces from what remains judgment.

**5. "Deterministic behavioral evaluations" that tested text.** `AGENTS.md` and `EVALS.md` described 14 deterministic behavioral evaluations. `scripts/eval.sh` checked that files contained strings such as `| A |` and `Disk wins`, and re-implemented the resume logic inside the test. `scripts/dogfood-smoke.sh` described itself as "a STRUCTURAL smoke test, not a functional test". Neither exercised anything an agent runs. `scripts/test.sh` now drives the shipped `arc-check.sh` against synthetic projects.

**6. A live evaluation that measured compliance, not effect.** The 2026-07-13 Codex run (`evals/results/2026-07-13-codex.md`) scored whether the model followed arc-ready's own rules and reached 100 of 100. Nothing compared a project built with the skill to the same model without it, so the scores could not show whether the skill helped. `evals/ablation/` now runs that comparison and records cost.

**7. A progressive-disclosure budget that measured the wrong file.** The size check capped `SKILL.md` at 500 lines and 5,000 words, but `SKILL.md` only routed; the cost was in what it routed to. Loading what `references/planning/planning-workflow.md` names for the four planning tiers comes to about 254,000 tokens (at 4 bytes per token), plus about 20,000 for the orchestration set, and one routed source, `references/shared/RESEARCH-2026-04.md`, is about 178,000 tokens on its own and was cited from 47 references. The 2.0.0 lint caps `SKILL.md` at 16,384 bytes and fails if it routes to anything outside the opt-in guided pack.

## Contract inconsistencies

**8. A resume parser that misread its own ledger.** `references/orchestration/resume-protocol.md` extracted statuses with `sed -E 's/.*: *([a-z-]+).*/\1/'`. The expression is greedy, so for the documented ledger line `- 1.2 (ARCH): in-flight | artifact: .architecture-ready/ARCH.md | verified: -` it returns `-`. Reproduced with the exact command. `arc-check.sh` parses the status as the first word after the tier label, with a regression test.

**9. Three ledger formats.** `artifact-contract.md` documented list lines (`- 1.1 (PRD): <status> | ...`), `progress-tracking.md` documented a table with steps 1 to 10 and names such as `prd-ready`, and the resume protocol parsed list lines and `- prd-ready: done` but not the table. 2.0.0 writes one format and reads all three, so 1.x ledgers keep working.

**10. Risk acceptances the gate could not see.** The ledger schema recorded an acceptance as one line (`- finding: <id> | ... | owner: <name> | expires: <date> | justification: ...`), but the gate in `completion-gates.md` counted `owner:` lines within five lines after a `risk-acceptance:` key, a different shape. An acceptance written to the documented schema never counted, and expiry was never checked. `arc-check.sh prepublish` reads the one-line format and rejects incomplete or expired acceptances.

**11. A status the vocabulary did not allow.** The ledger vocabulary was pending, in-flight, done, skipped, imported, failed, and re-invoked, but the AGENTS.md template and the final-ledger instructions also used `deferred`. `arc-check.sh` enforces the single vocabulary, and the emitted `AGENTS.md` no longer copies statuses at all.

**12. Two names for the audit output.** `core-orchestration.md` said Mode C writes `<TIER>-AUDIT.md`; `mode-routing-and-audits.md` said `.prd-ready/AUDIT.md` and similar. `SKILL.md` now names `.<tier>-ready/AUDIT.md`, with `.repo-ready/AUDIT-REPORT.md` for the repository.

## References to things that do not exist

**13. A dogfood example repository.** `artifact-contract.md` and `MIGRATION.md` said `hannsxpeter/ready-suite-example` verified cleanly against arc-ready. That repository does not exist (GitHub returns "could not resolve"). References removed.

**14. Downstream consumers.** The README said downstream orchestrators (GSD, BMAD, Spec Kit, Superpowers) "keep working unchanged", and `artifact-contract.md` said they "consume these artifacts directly". No integration or test with any of them exists. The artifact paths stay stable; the documentation no longer claims consumers.

**15. A code owner account.** `.github/CODEOWNERS` assigned every path to `@aihxp`. That account does not exist (GitHub API 404), so no owner was ever requested. Now `@hannsxpeter`.

## Repository hygiene

**16. A CI action downgrade.** Commit `bd86b51` (2026-06-22) moved `actions/checkout` to v7. The 1.1.0 release then pinned it by SHA to v6.0.2, undoing the upgrade. CI now pins `actions/checkout` v7.0.1 and `actions/setup-python` v7.0.0 by commit SHA.

**17. A pull request template that contradicted AGENTS.md.** The template required tier-relative cross-reference paths; `AGENTS.md` had documented the tier-agnostic `references/<basename>.md` convention since 1.0.2. Both are obsolete now that the reference library is gone, and the template is rewritten.

**18. Stale defaults and badges.** The bug-report template suggested version 1.1.0, and the README carried hand-edited "smoke 12/12" and "eval 14/14" badges that no pipeline updated. The template now suggests 2.0.0, and only the CI badge remains.

**19. A security policy for a skill with no code.** `SECURITY.md` said the skill "does not execute code at runtime". That was true for 1.x. In 2.0.0, agents run `scripts/arc-check.sh` inside user projects, so `SECURITY.md` now states what the script reads and writes.

**20. Compatibility without evidence.** Metadata listed eight compatible harnesses, and live evidence existed for one (Codex, 1.1.0). The list stays, as a statement of structural Agent Skills compatibility, and `EVALS.md` names where live evidence exists: Codex for 1.1.0, and Claude Code for the 2.0.0 ablation.
