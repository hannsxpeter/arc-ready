# Audit Mode

Audit mode scores an existing repository against 42 criteria and writes a prioritized fix-it list to `AUDIT-REPORT.md` at the repo root. The 42 points break down as 39 items from `references/repo-audit.md` plus 3 new v1.4 agent-safety checks from `references/agent-safety.md §2`. The three v1.3 unfixable-behavior classes (slopsquatting, bypass-by-fallback, session-startup reconciliation) are surfaced in a dedicated `agent_runtime_concerns` section but are explicitly NOT counted in the 42-point denominator — see §8 for the rationale.

This file wraps `references/repo-audit.md` with the scoring engine, the score-object schema, the AUDIT-REPORT.md template, and the re-audit loop. Load it whenever SKILL.md Step 0 routes to Mode C.

## 1. What audit mode is

Audit mode is a read-only assessment of an existing repository against a binary, reproducible 42-point checklist. It produces three outputs: (a) an overall score `N/42`, (b) a tier label (Needs work / Basic / Good / Excellent / Exemplary), and (c) a paste-ready `AUDIT-REPORT.md` at the repo root that groups every gap by severity with a concrete fix and an effort estimate.

Use audit mode in four situations:

1. **Existing repo needing assessment.** A contributor inherits a repo and wants to know where it stands before filing feature PRs.
2. **Before a v1.0 milestone.** A team wants to ship a public release and needs to know which hygiene gaps block "credibly professional."
3. **After a major refactor.** A large restructuring churned file layout, CI, and docs; re-audit confirms nothing regressed.
4. **Quarterly hygiene check.** A maintainer runs the skill on a schedule to catch drift (stale CHANGELOG, expired badges, Dependabot PRs piled up).

Audit mode is read-only — it never writes into your repo except to drop `AUDIT-REPORT.md` at the root. The report is informational; the user decides which gaps to fix and when.

## 2. Entry mode context

The skill has three entry modes, routed from SKILL.md Step 0:

- **Mode A (Greenfield).** Empty directory or bare `package.json`. Generate a fresh scaffold from scratch.
- **Mode B (Enhancement).** Existing codebase. Detect stack and platform, inventory what exists, fill gaps without overwriting.
- **Mode C (Audit).** Existing repo where the user asked to audit/improve/assess. Run the scorecard and emit `AUDIT-REPORT.md`.

Mode C is the focus of this reference. Modes A and B are documented inline in `SKILL.md` because they don't need a scorecard.

## 3. Scoring logic

42 points total — 39 from `references/repo-audit.md` plus 3 new v1.4 agent-safety checks. The three v1.3 unfixable behaviors are NOT scored; see §8. Each check is binary: pass or fail, no partial credit. The mapping below gives the point ID, the one-line pass criterion, and the source of the full check.

### Category 1 — Essentials (7 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-1.1 | README.md exists with project description, install, and at least one usage example | `repo-audit.md §1.1` |
| REPO-1.2 | LICENSE file exists with valid SPDX text (no template variables) | `repo-audit.md §1.2` |
| REPO-1.3 | `.gitignore` exists and includes build dirs, IDE files, OS files, and `.env` | `repo-audit.md §1.3` |
| REPO-1.4 | `.gitattributes` exists with `* text=auto` | `repo-audit.md §1.4` |
| REPO-1.5 | `.editorconfig` exists with `indent_style` defined | `repo-audit.md §1.5` |
| REPO-1.6 | Source in conventional directory; tests separated; no build artifacts committed | `repo-audit.md §1.6` |
| REPO-1.7 | No `.env`, `.pem`, `.key`, or hardcoded credentials tracked in git | `repo-audit.md §1.7` |

### Category 2 — Community (7 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-2.1 | CONTRIBUTING.md has 100+ words describing real setup, workflow, and test commands | `repo-audit.md §2.1` |
| REPO-2.2 | CODE_OF_CONDUCT.md exists with a real enforcement contact (not a placeholder address) | `repo-audit.md §2.2` |
| REPO-2.3 | SECURITY.md exists with real reporting mechanism and response timeline | `repo-audit.md §2.3` |
| REPO-2.4 | At least two issue templates (bug + feature) in `.github/ISSUE_TEMPLATE/*.yml` | `repo-audit.md §2.4` |
| REPO-2.5 | PR template at `.github/PULL_REQUEST_TEMPLATE.md` with meaningful checklist | `repo-audit.md §2.5` |
| REPO-2.6 | CHANGELOG.md in Keep a Changelog format with `[Unreleased]` section | `repo-audit.md §2.6` |
| REPO-2.7 | Labels include at minimum `bug`, `enhancement`, and `good first issue` | `repo-audit.md §2.7` |

### Category 3 — Quality (7 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-3.1 | CI pipeline triggers on `pull_request` and `push: branches: [main]` | `repo-audit.md §3.1` |
| REPO-3.2 | CI runs real lint + test + build commands (no `echo` placeholders) | `repo-audit.md §3.2` |
| REPO-3.3 | Linter configured for the stack; CI invokes it | `repo-audit.md §3.3` |
| REPO-3.4 | Formatter configured (gofmt/rustfmt/Ruff/Biome/Prettier) — exactly one per language | `repo-audit.md §3.4` |
| REPO-3.5 | Git hook manager (Husky/pre-commit/Lefthook) with `pre-commit` running lint+format on staged files | `repo-audit.md §3.5` |
| REPO-3.6 | Type checker configured: `tsconfig.json` strict for TS, mypy/pyright for Python, compiler for Go/Rust | `repo-audit.md §3.6` |
| REPO-3.7 | Test files exist, runnable with the project's test runner, pass; CI runs them | `repo-audit.md §3.7` |

### Category 4 — Security (6 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-4.1 | Dependabot or Renovate configured with appropriate schedule and ecosystems | `repo-audit.md §4.1` |
| REPO-4.2 | SAST in CI (CodeQL, Semgrep, or equivalent), triggered on PRs or schedule | `repo-audit.md §4.2` |
| REPO-4.3 | Branch protection on `main`: required PR review + required status checks | `repo-audit.md §4.3` |
| REPO-4.4 | Zero high/critical CVEs in production dependencies | `repo-audit.md §4.4` |
| REPO-4.5 | Secret scanning enabled (GitHub secret scanning + push protection, or gitleaks equivalent) | `repo-audit.md §4.5` |
| REPO-4.6 | Dependencies current: no deps more than one major version behind; no Dependabot PR pile-up | `repo-audit.md §4.6` |

### Category 5 — DX (6 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-5.1 | README has a Quick Start section with 5 or fewer commands | `repo-audit.md §5.1` |
| REPO-5.2 | Task runner configured (Makefile/Justfile/npm scripts) with standard targets | `repo-audit.md §5.2` |
| REPO-5.3 | Development setup documented in CONTRIBUTING.md with concrete commands | `repo-audit.md §5.3` |
| REPO-5.4 | `.env.example` exists if the project reads env vars; `.env` is gitignored | `repo-audit.md §5.4` |
| REPO-5.5 | README badges accurate, linked to real services, CI badge green | `repo-audit.md §5.5` |
| REPO-5.6 | Clear onboarding path: README → CONTRIBUTING → issue templates → PR template | `repo-audit.md §5.6` |

### Category 6 — Release (6 points)

| ID | Pass criterion | Source |
|---|---|---|
| REPO-6.1 | Git tags follow SemVer (`vX.Y.Z`); at least one release tagged | `repo-audit.md §6.1` |
| REPO-6.2 | Release automation configured (semantic-release, release-please, changesets, or tag-push workflow) | `repo-audit.md §6.2` |
| REPO-6.3 | CHANGELOG maintained or auto-generated via `.github/release.yml` | `repo-audit.md §6.3` |
| REPO-6.4 | Package publishing automated via CI on release/tag (if applicable) | `repo-audit.md §6.4` |
| REPO-6.5 | GitHub Releases exist for tagged versions with non-empty notes | `repo-audit.md §6.5` |
| REPO-6.6 | CODEOWNERS exists at `.github/CODEOWNERS` with at least a catch-all rule | `repo-audit.md §6.6` |

### Category 7 — Agent Safety (3 points, new in v1.4)

| ID | Pass criterion | Source |
|---|---|---|
| AGENT-01 | `.claude/settings.json` exists and contains `Bash(git reset --hard *)` in `permissions.deny` | `agent-safety.md §2` |
| AGENT-02 | `.githooks/pre-push` exists AND `core.hooksPath` is pointed at `.githooks` (via install script or `.git/config`) | `agent-safety.md §3` |
| AGENT-03 | `.gitleaks.toml` exists at repo root AND gitleaks is wired into `.pre-commit-config.yaml` or a CI workflow | `agent-safety.md §7` + `quality-tooling.md §8` |

**Totals:** 7 + 7 + 7 + 6 + 6 + 6 + 3 = 42 points.

### Severity ladder

Assign each failing check a severity using this fixed mapping. Severity drives the order gaps appear in `AUDIT-REPORT.md`.

| Severity | Checks |
|---|---|
| **critical** | REPO-1.1, REPO-1.2, REPO-1.3, REPO-1.7, REPO-4.4, REPO-4.5 |
| **high** | REPO-2.3, REPO-3.1, REPO-3.2, REPO-3.7, REPO-4.1, REPO-4.2, REPO-4.3, REPO-4.6, AGENT-01, AGENT-02, AGENT-03 |
| **medium** | REPO-2.1, REPO-2.2, REPO-2.4, REPO-2.5, REPO-2.6, REPO-2.7, REPO-3.3, REPO-3.4, REPO-3.5, REPO-3.6, REPO-5.1, REPO-5.2, REPO-5.3, REPO-5.6 |
| **low** | REPO-1.4, REPO-1.5, REPO-1.6, REPO-5.4, REPO-5.5, REPO-6.1, REPO-6.2, REPO-6.3, REPO-6.4, REPO-6.5, REPO-6.6 |

**Rule of thumb.** A failure is `critical` if it breaks essentials (no README/LICENSE/.gitignore) or leaks secrets. It's `high` if it breaks security, CI, or core tests, or fails one of the three agent-safety checks. It's `medium` if it breaks community standards or quality tooling but the repo still runs. It's `low` if it's cosmetic, polish, or release-only and the user can ship without it.

## 4. Score object schema

`AUDIT-REPORT.md` opens with a YAML frontmatter block that encodes the score in a machine-readable shape. The schema below is canonical — every audit report uses exactly these keys in this order.

```yaml
audit_date: 2026-04-22          # ISO-8601 date
overall_score: 28/42            # string "N/42"
tier: "Tier 2 (Good)"           # string from §5 Tier mapping
scores:
  essentials: 7/7               # per-category strings, denominators fixed
  community: 5/7
  quality: 6/7
  security: 4/6
  dx: 4/6
  release: 0/6
  agent_safety: 2/3             # new v1.4 category
gaps:
  critical: [REPO-4.5]
  high: [REPO-2.3, REPO-3.5, REPO-4.1, AGENT-03]
  medium: [REPO-2.7, REPO-5.3, REPO-6.2, REPO-6.3]
  low: [REPO-6.1, REPO-6.5, REPO-6.6]
agent_runtime_concerns:
  - slopsquatting
  - bypass_by_fallback
  - startup_reconciliation
```

**Invariant.** The sum of the numerators in `scores` MUST equal the numerator in `overall_score`. In the example above: 7 + 5 + 6 + 4 + 4 + 0 + 2 = 28 = overall. The sum of the denominators MUST equal 42: 7 + 7 + 7 + 6 + 6 + 6 + 3 = 42. Any audit report where these sums disagree is malformed and must be corrected before the report is written.

**Every gap ID in `gaps` MUST also appear in the body of the report** under the matching severity section, with the full four-field entry (Current / Target / Fix / Effort). The frontmatter is the index; the body is the content. Neither stands alone.

## 5. Tier mapping

| Score range | Tier label |
|---|---|
| 0–13 | **Needs work** — missing essentials, not ready for collaborators |
| 14–22 | **Basic** — functional but unprofessional, fails first-impression check |
| 23–30 | **Good** — team-ready, supports collaboration and basic quality gates |
| 31–35 | **Excellent** — mature open source, handles security and releases at scale |
| 36–42 | **Exemplary** — top-tier, nothing left to improve |

The four lower bands match `repo-audit.md` §Scoring Overview verbatim. The only widened band is `36–42 Exemplary` (was `36–39`) — adding the 3 agent-safety checks never demotes a previously-graded repo. A repo that scored 32/39 under the old scale scores 32/42 or higher under the new scale and stays in the same tier (or moves up).

**Why the thresholds.** 14+ means all essentials passed and at least a few community/quality items are in place. 23+ means a second-time contributor can find setup instructions and the CI runs. 31+ means security is actively managed (Dependabot, SAST, branch protection). 36+ means release hygiene is automated and the repo operates without maintainer intervention.

## 6. AUDIT-REPORT.md template

`AUDIT-REPORT.md` has a fixed structure. Every audit report MUST contain all seven sections below, in this order, even if a section is empty:

1. **YAML frontmatter** — the score object from §4 with every key populated. Gap arrays are empty `[]` if a severity had no failures.
2. **H1 title** — `# Repo Audit Report — {iso-date}` with the audit date from frontmatter.
3. **Executive summary paragraph** — one paragraph naming the score, the tier label, and the top three gaps. Reader should be able to stop here and have enough to prioritize the next week of work.
4. **`## Critical gaps (must-fix before next milestone)`** — one gap entry per critical failure. Entry schema below. Include the literal heading even if the section is empty — write `No critical gaps.` as the only body line.
5. **`## High priority (strongly recommended)`** — one gap entry per high failure.
6. **`## Medium priority (nice to have)`** — one gap entry per medium failure.
7. **`## Low priority (cosmetic / edge-case)`** — one gap entry per low failure.
8. **`## Agent runtime concerns (informational, not scored)`** — three bullets, one per unfixable behavior, each ending with `Not counted in score. See references/agent-safety.md §6.`
9. **`## How to re-audit`** — one line: `Re-run the skill in Mode C. The new report is written in place; diff with git diff AUDIT-REPORT.md to see the score-delta.`

**Gap entry schema** — every entry in every severity section uses this shape, with all four fields:

```markdown
#### {ID} — {one-line gap title}
- **Current:** {what the audit found — concrete, file-path-specific}
- **Target:** {what passing looks like — concrete}
- **Fix:** {exact command sequence or file list, with references to the relevant reference file}
- **Effort:** {trivial | small | moderate | large}
```

The `Fix` line should be runnable — a developer should be able to copy-paste the commands or follow the referenced file section without further interpretation. The `Effort` estimate is a rough t-shirt size: `trivial` = under 5 minutes, `small` = under an hour, `moderate` = half a day, `large` = a day or more.

For a complete, paste-ready example with all sections populated, see §11 (the `acme-dashboard` worked example). That example is the canonical template: copy it, swap the values, and you have a valid `AUDIT-REPORT.md`.

**Where the file goes.** `AUDIT-REPORT.md` lives at the audited repo's **root**, next to `README.md` and `CHANGELOG.md`. It does NOT live under `.planning/` — this report is user-facing and meant to be visible in the repo's default GitHub view. Keeping it at root puts it one click from the repo landing page so maintainers and new contributors see the score immediately.

## 7. Re-audit loop

Re-audit is literally re-running audit mode. Before scoring, the skill reads any existing `AUDIT-REPORT.md` at the repo root. If one is present, the skill parses the frontmatter's `overall_score` and `gaps` fields to compute a score-delta and prepends a one-line summary to the new report.

The delta format is fixed:

```
Score: 28/42 → 34/42 (+6). Closed: REPO-2.3, REPO-3.5, AGENT-03. New gaps: none.
```

Rules for computing the delta:

- **Closed** lists gap IDs that appeared in the prior report's `gaps` (any severity) and are now passing. Format: comma-separated IDs, sorted by category then number.
- **New gaps** lists IDs that fail in the current run but weren't reported previously. If the list is empty, write `New gaps: none.` verbatim.
- **Score arrow** uses the literal characters `→ ` (unicode right-arrow + space). The `+N` suffix is signed: `+6` for an improvement, `-3` for a regression, `±0` for no change.

No state file beyond `AUDIT-REPORT.md` itself. The repo is self-contained — everything needed to compute a delta lives in the previous report, which git versions for you. The full diff is always one command away: `git log -p AUDIT-REPORT.md` shows every audit's delta in order.

## 8. Score adjustment — unfixable behaviors

v1.3's honesty-over-coverage principle: the skill should not imply that a paste-ready file can close every agent failure mode. Three behavior classes cannot be fixed by generated files — they are agent-runtime concerns. Scoring against them would dock the repo for something outside its control, so they're excluded from the 42-point denominator to keep the score measurable. See `references/agent-safety.md §6` for the full argument and incident citations.

### Slopsquatting

AI agents hallucinate package names that don't exist on the public registry. An attacker who pre-registers a commonly-hallucinated name executes code the moment a user runs `npm install` or `pip install` against it. No file in the repo distinguishes a real package from a squatted one — the commands are structurally identical. Agent runtimes should verify proposed package names against the registry; users should pin dependencies and review every new dependency. See `references/agent-safety.md §6a`.

### Bypass-by-fallback

When `.claude/settings.json` denies a destructive git command, the agent may route around the denial via an MCP commit tool that writes commits directly, skipping pre-commit hooks. Deny rules are tool-name specific (`Bash(…)`) and can't enumerate every MCP tool a user might install. Users must audit installed MCP servers and add explicit deny rules for each. See `references/agent-safety.md §6b`.

### Startup reconciliation

On session start, some agents propose `git reset --hard origin/main` to "sync with upstream" before any settings are read, or the user accepts the proposal interactively and overrides the denial. Neither hole is closable by a generated file. The fix is runtime: agents should never auto-propose destructive reconciliation on session start; users should read every `reset`/`clean`/`checkout --` variant before accepting. See `references/agent-safety.md §6c`.

These three concerns surface in every `AUDIT-REPORT.md` under `## Agent runtime concerns` so users know the risks exist — they just don't affect the 42-point score.

## 9. Integration

Cross-links to other references, ordered by how often they're needed during fix work:

- `references/repo-audit.md` — the 39-point scorecard source-of-truth; every REPO-* ID maps to a section there
- `references/agent-safety.md §2, §6` — source of AGENT-01/02 (denylist + pre-push) and the three unfixable behaviors
- `references/quality-tooling.md §8` — source of AGENT-03 (gitleaks) and the fix for REPO-3.5 (git hooks)
- `references/security-setup.md` — fixes for REPO-4.2 (SAST) and REPO-4.5 (secret scanning)
- `references/platform-github.md` — fixes for REPO-2.4, REPO-2.5, REPO-4.1, REPO-4.3, REPO-6.6
- `references/release-distribution.md` — fixes for REPO-6.1 through REPO-6.5
- `references/community-standards.md` — fixes for REPO-2.1, REPO-2.2, REPO-2.3
- `references/readme-craft.md` — fixes for REPO-1.1 and REPO-5.1
- `references/licensing-legal.md` — fix for REPO-1.2
- `references/repo-structure.md` — fix for REPO-1.6
- `references/project-profiles.md` — tier determination from project type × stage × audience
- `SKILL.md §Step 0 Mode C` — entry point that loads this file

## 10. Sources

- `references/repo-audit.md` (this repo) — the 39-point scorecard, source of all REPO-* IDs
- `references/agent-safety.md §2` (this repo) — source of AGENT-01 and AGENT-02 checks
- `references/agent-safety.md §7` (this repo) + `references/quality-tooling.md §8` — source of AGENT-03 (gitleaks) check
- `references/agent-safety.md §6` (this repo) — source of the three unfixable behaviors excluded from scoring
- `.planning/milestones/v1.3-MILESTONE-AUDIT.md` (this repo) — precedent for the frontmatter + severity-grouped-gaps report shape that `AUDIT-REPORT.md` mirrors
- https://keepachangelog.com/ — Keep a Changelog format referenced in REPO-2.6
- https://semver.org/ — Semantic Versioning spec referenced in REPO-6.1
- https://docs.github.com/en/code-security/secret-scanning — GitHub secret scanning documentation referenced in REPO-4.5

## 11. Worked example — acme-dashboard

Below is the `AUDIT-REPORT.md` that a first-pass Mode C audit would produce for a fictional Node 20 + TypeScript 5 + Next.js 14 + Prisma SaaS dashboard called `acme-dashboard`. The repo scores 28/42 (Tier 2 — Good): it clears every essential, has solid quality tooling, but is weak on release hygiene and missing two critical security bits.

```markdown
---
audit_date: 2026-04-22
overall_score: 28/42
tier: "Tier 2 (Good)"
scores:
  essentials: 7/7
  community: 5/7
  quality: 6/7
  security: 4/6
  dx: 4/6
  release: 0/6
  agent_safety: 2/3
gaps:
  critical: [REPO-4.5]
  high: [REPO-2.3, REPO-3.5, REPO-4.1, AGENT-03]
  medium: [REPO-2.7, REPO-5.3, REPO-6.2, REPO-6.3]
  low: [REPO-6.1, REPO-6.5, REPO-6.6]
agent_runtime_concerns:
  - slopsquatting
  - bypass_by_fallback
  - startup_reconciliation
---

# Repo Audit Report — 2026-04-22

Score **28/42 — Tier 2 (Good)**. `acme-dashboard` clears every essential and has solid CI, linting, and type checking for its Next.js 14 + Prisma stack. The biggest gaps are on the security side (secret scanning disabled, no SECURITY.md, no Dependabot) and on release hygiene (zero tags, no automation, no CHANGELOG entries). Top three fixes: (1) enable GitHub secret scanning and push protection, (2) add SECURITY.md with a real reporting email, (3) configure Dependabot for npm + GitHub Actions + Docker.

 ## Critical gaps (must-fix before next milestone)

#### REPO-4.5 — Secret scanning not enabled
- **Current:** GitHub secret scanning disabled in Settings > Code security and analysis. No `.gitleaks.toml`, no pre-commit secret-scan hook.
- **Target:** Secret scanning + push protection enabled at repo level.
- **Fix:** In GitHub UI, enable "Secret scanning" and "Push protection". Also add `.gitleaks.toml` + gitleaks pre-commit hook in a single pass — this closes AGENT-03 at the same time. Reference: `references/quality-tooling.md §8`.
- **Effort:** trivial

 ## High priority (strongly recommended)

#### REPO-2.3 — SECURITY.md missing
- **Current:** No `SECURITY.md` at repo root.
- **Target:** `SECURITY.md` with supported-versions table, real reporting email, 48h acknowledgement commitment.
- **Fix:** Create `SECURITY.md` using `references/community-standards.md §SECURITY.md`. Use `security@acme-dashboard.example` as the reporting email (replace `.example` with the real production TLD).
- **Effort:** small

#### REPO-3.5 — No git hooks
- **Current:** No `.husky/`, no `.pre-commit-config.yaml`.
- **Target:** Pre-commit hook running `next lint` + `prettier --check` on staged files.
- **Fix:** `npm install -D husky lint-staged`, `npx husky init`, add `npx lint-staged` to `.husky/pre-commit`, configure `"lint-staged"` in `package.json` to run `next lint --fix` and `prettier --write` on `*.ts`, `*.tsx`.
- **Effort:** small

#### REPO-4.1 — No Dependabot
- **Current:** No `.github/dependabot.yml`.
- **Target:** Dependabot configured for npm, GitHub Actions, and Docker; minor+patch grouped into weekly PRs.
- **Fix:** Create `.github/dependabot.yml` with three `updates` entries (`npm`, `github-actions`, `docker`), each with `schedule: weekly` and a `groups` block. Reference: `references/platform-github.md §Dependabot`.
- **Effort:** small

#### AGENT-03 — Gitleaks not configured
- **Current:** No `.gitleaks.toml`, no gitleaks invocation anywhere.
- **Target:** `.gitleaks.toml` with `useDefault = true` at repo root, plus gitleaks step in `.github/workflows/ci.yml` running on every PR.
- **Fix:** Copy the templates from `references/quality-tooling.md §8`. The CI step is a single `uses: gitleaks/gitleaks-action@v2` block.
- **Effort:** trivial

 ## Medium priority (nice to have)

#### REPO-2.7 — Labels not configured
- **Current:** Only GitHub's default labels (no `good first issue`, no area labels).
- **Target:** Full taxonomy: `bug`, `enhancement`, `good first issue`, `documentation`, `help wanted`, `area: frontend`, `area: api`, `area: db`.
- **Fix:** Run `gh label create` for each missing label, or edit `.github/labels.yml` if a label-sync action is in use. Reference: `references/platform-github.md §Labels`.
- **Effort:** trivial

#### REPO-5.3 — Dev setup thin in CONTRIBUTING.md
- **Current:** `CONTRIBUTING.md` mentions "run npm install" but doesn't document Node version, Postgres requirement, or `.env.local` setup.
- **Target:** Full setup section listing Node 20 LTS, PostgreSQL 16, `cp .env.example .env.local`, `npx prisma migrate dev`, `npm run dev`.
- **Fix:** Expand the `## Development setup` section in `CONTRIBUTING.md` with concrete prerequisites and verification command (`npm test` should pass cleanly).
- **Effort:** small

#### REPO-6.2 — No release automation
- **Current:** No `release-please-config.json`, no `.changeset/`, no tag-push workflow.
- **Target:** release-please configured to open a release PR on every merge to `main`.
- **Fix:** Add `release-please-config.json` and `.github/workflows/release-please.yml` using templates from `references/release-distribution.md §release-please`.
- **Effort:** moderate

#### REPO-6.3 — CHANGELOG trivial
- **Current:** `CHANGELOG.md` contains only `# Changelog` + an empty `[Unreleased]` section.
- **Target:** CHANGELOG actively maintained by release-please once REPO-6.2 is fixed, or manually updated per release.
- **Fix:** Resolves automatically once release-please is configured (REPO-6.2). Until then, back-fill from git log and add a first `[0.1.0]` section.
- **Effort:** small

 ## Low priority (cosmetic / edge-case)

#### REPO-6.1 — No SemVer tags
- **Current:** `git tag -l` returns empty.
- **Target:** At least `v0.1.0` tagged.
- **Fix:** `git tag v0.1.0 && git push --tags`.
- **Effort:** trivial

#### REPO-6.5 — No GitHub Releases
- **Current:** No releases created (follows from REPO-6.1).
- **Target:** GitHub Release with auto-generated notes for every SemVer tag.
- **Fix:** Resolves automatically once REPO-6.2 (release-please) is in place. Backfill once with `gh release create v0.1.0 --generate-notes`.
- **Effort:** trivial

#### REPO-6.6 — No CODEOWNERS
- **Current:** No `.github/CODEOWNERS`.
- **Target:** CODEOWNERS with at least a catch-all rule plus per-directory rules for `app/`, `prisma/`, and `.github/`.
- **Fix:** Create `.github/CODEOWNERS` with `* @acme-dashboard/maintainers`, `app/ @acme-dashboard/frontend`, `prisma/ @acme-dashboard/db`, `.github/ @acme-dashboard/platform`. Reference: `references/platform-github.md §CODEOWNERS`.
- **Effort:** trivial

 ## Agent runtime concerns (informational, not scored)

- **slopsquatting** — AI agents may propose `npm install` commands for hallucinated package names. Not counted in score. See `references/agent-safety.md §6`.
- **bypass-by-fallback** — Agents may route around denied git commands via MCP tools. Not counted in score. See `references/agent-safety.md §6`.
- **startup-reconciliation** — Agents may propose `git reset --hard origin/main` on session start. Not counted in score. See `references/agent-safety.md §6`.

 ## How to re-audit

Re-run the skill in Mode C. The new report is written in place; diff with `git diff AUDIT-REPORT.md` to see the score-delta.
```

After fixing the critical and high items, a second pass would produce a new report opening with the one-line delta summary:

```
Score: 28/42 → 35/42 (+7). Closed: REPO-2.3, REPO-3.5, REPO-4.1, REPO-4.5, AGENT-03, REPO-6.2, REPO-6.3. New gaps: none.
```

The gap IDs listed under `Closed` are exactly the ones in the prior report that now pass. `New gaps: none` confirms the fixes didn't introduce regressions. The arrow character is the literal unicode `→` — keep the exact formatting so users can grep the delta line across audit history.
