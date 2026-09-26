# Migration

Two paths lead here: from arc-ready 1.x, and from the eleven-skill hannsxpeter/ready-suite.

## From arc-ready 1.x to 2.0

### What changes

- **One file of instructions.** `SKILL.md` now carries everything an agent is told, in about 3,700 tokens, and loads nothing else by default. In 1.x it routed each tier to reference files; loading what the four planning tiers named came to about 254,000 tokens.
- **A script instead of self-grading.** `scripts/arc-check.sh` keeps the ledger, verifies claimed progress against disk, runs a gate before a tier can be recorded as done, writes Pillars memory, and runs the pre-publication gate. Agents call it; it does not call a model.
- **The reference library is frozen.** The 220-file library (tier references, 37 domain profiles, worked examples, antipattern catalogs) stays available at the `v1.2.1` tag and is not part of 2.0. The have-not names and the three tests moved into `SKILL.md`, and the source citations moved to `docs/research/`.
- **Guided mode for smaller models.** Ten short skeletons in `references/guided/` load only when the ledger says `guided: true` (from `arc-check.sh init --guided`) or the user asks for guided mode.
- **Lookups instead of frozen data.** Pre-scored stack bundles, vendor landscapes, and dated survey statistics are gone. `SKILL.md` tells agents to check current sources and record the date.
- **An evidence rule.** Agents write only evidence they produced, and stop at any tier that needs access they do not have.
- **Removed:** the plugin packaging under `plugins/` (it could not install; see `docs/drift-audit.md`), the Unicode baseline, the 1.x string-matching evaluations and manual live cases, and the four-axis domain composition router. The product-form table remains, plus a rule to verify industry and regulatory obligations when the project shows them.

### What does not change

- Every canonical artifact path: `.arc-ready/PROGRESS.md`, `.prd-ready/PRD.md`, `.architecture-ready/ARCH.md`, `.roadmap-ready/ROADMAP.md`, `.stack-ready/STACK.md`, `.repo-ready/SCAFFOLD.md` (or `AUDIT-REPORT.md`), `.production-ready/STATE.md`, `.deploy-ready/DEPLOY.md`, `.observe-ready/OBSERVE.md`, `.launch-ready/STATE.md` with `PREPUBLICATION.md`, and `.harden-ready/FINDINGS.md`.
- Modes A to D, the tier order, the status vocabulary, the Pillars floor (`AGENTS.md`, `agents/context.md`, `agents/repo.md`), and the rule that public activation needs a fresh pre-publication pass tied to the current hardening state.

### Existing projects

No project file needs to move. `arc-check.sh` reads 1.x ledgers in all three documented shapes (list lines, `- prd-ready: done` lines, and the step table).

1. Install 2.0 (below).
2. Run `bash <skill-dir>/scripts/arc-check.sh -C <project> status`. It reports any tier whose claimed artifact is missing.
3. The first `mark` for a tier writes that tier's line in the 2.x format, which then takes precedence over the old row. Nothing else in the ledger changes.
4. Findings: `prepublish` reads `severity:` and `status:` lines, including the 1.x flat format. Give each finding an `id:` line so that a risk acceptance can name it.
5. Risk acceptances are recorded by the risk's owner at a terminal: `arc-check.sh accept <id> --owner <name> --expires <YYYY-MM-DD> --justification <why>`. Hand-written lines are ignored, including every 1.x acceptance, so the owner must re-record any that should still count (see entry 10 of `docs/drift-audit.md` and `evals/results/2026-09-26-ablation.md`).

### Staying on 1.2.1

If you want the full library, for example to give a smaller model long worked examples, install the tag:

```bash
git clone --branch v1.2.1 https://github.com/hannsxpeter/arc-ready ~/.claude/skills/arc-ready
```

1.2.1 receives no further changes. Do not install 1.2.1 and 2.0 side by side under the same skill name.

### Install 2.0

```bash
git clone https://github.com/hannsxpeter/arc-ready ~/.claude/skills/arc-ready
```

To update an existing clone, run `git -C ~/.claude/skills/arc-ready pull`.

## From hannsxpeter/ready-suite

The eleven-skill suite (kickoff-ready, prd-ready, architecture-ready, roadmap-ready, stack-ready, repo-ready, production-ready, deploy-ready, observe-ready, launch-ready, harden-ready) wrote the same artifact paths arc-ready uses, so projects move without file changes.

### Install change

Remove the eleven skill directories, for example `~/.claude/skills/prd-ready`, so their triggers do not collide with arc-ready. Then clone arc-ready once, as above.

### Where each skill went

| Former skill | arc-ready 2.0 |
|---|---|
| kickoff-ready | Tier 0: the ledger and `arc-check.sh status` |
| prd-ready | Tier 1.1 |
| architecture-ready | Tier 1.2 |
| roadmap-ready | Tier 1.3 |
| stack-ready | Tier 1.4 |
| repo-ready | Tier 2.1 and `arc-check.sh pillars` |
| production-ready | Tier 2.2 and `arc-check.sh scan` |
| deploy-ready | Tier 3.1 |
| observe-ready | Tier 3.2 |
| launch-ready | Tier 3.3 and `arc-check.sh prepublish` |
| harden-ready | Tier 3.4 |

Each skill's full reference set, antipattern catalog, and worked examples are preserved under `references/<tier>/` at the arc-ready `v1.2.1` tag, and in the original repositories.

### Running both

Do not install the suite and arc-ready together. Their triggers overlap, and the harness routes to whichever matches first. The artifacts are compatible in both directions, so switching is safe at any point.
