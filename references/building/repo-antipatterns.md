# Repo-ready antipatterns

Named failure modes repo-ready refuses. Each pattern carries a concrete shape, the grep test the skill applies to catch it, and the guard.

Loaded on demand during Mode C audits, and at every tier-gate check before declaring repo scaffolding done. Complements `references/repo-audit.md` (the 42-criteria scorecard) and `references/audit-mode.md` (the scoring engine).

## Core principle (recap)

> Every generated file must contain actionable content tailored to the project's stack, type, and stage. No generic TODO markers, no lorem ipsum, no `{{author}}` left behind.

The patterns below are violations of this principle.

## Pattern catalog

### `{{author}}` in LICENSE (Critical)

**Shape.** The LICENSE file ships with template variables unresolved: `{{author}}`, `<YEAR>`, `[fullname]`. SPDX text expects a real year and real author.

**Grep test.** `grep -E '\{\{|<YEAR>|\[fullname\]|TODO' LICENSE` returns zero matches.

**Guard.** Step 2 of the workflow requires the user to confirm copyright year + holder before generating LICENSE. The audit-mode REPO-1.2 check fails the file if any template marker survives.

### README with just the project name (Critical)

**Shape.** A README that contains the title and one sentence; no install, no usage, no contributing pointer, no license note.

**Grep test.** README has at least: a one-paragraph description, an Install section, a Quick Start, a License section, a CONTRIBUTING pointer. A README with fewer than 3 of these 5 sections fails.

**Guard.** `references/readme-craft.md` enumerates the canonical sections. The audit-mode REPO-5.1 + REPO-5.6 checks enforce the onboarding path.

### CI runs `echo "test"` (Critical)

**Shape.** A `.github/workflows/ci.yml` (or equivalent) that runs `echo` instead of the project's actual lint, test, build commands.

**Grep test.** CI workflow's command lines must match the project's stack (`pnpm test` for Node, `pytest` for Python, `cargo test` for Rust). Workflow with only `echo` / `true` / `exit 0` placeholders fails.

**Guard.** Step 2 stack detection drives the CI matrix. The audit-mode REPO-3.2 check verifies CI commands are real.

### `.gitignore` missing half the stack (High)

**Shape.** `.gitignore` lacks the stack's standard ignores: `node_modules/` for Node, `__pycache__/` for Python, `target/` for Rust, `.next/` for Next.js, `.venv/` for Python projects.

**Grep test.** Stack-detected ignores must all appear in `.gitignore`. Missing canonical entries fail.

**Guard.** `references/repo-structure.md` carries per-stack `.gitignore` baselines. The audit-mode REPO-1.3 check verifies stack-appropriate ignores.

### ESLint config in a Python project (High)

**Shape.** Tooling that does not match the stack. ESLint configured in a Python repo; rustfmt in a JavaScript repo; Prettier in a Go-only repo.

**Grep test.** Detected stack must match installed lint/format tooling. Mismatched tooling fails.

**Guard.** Step 2 stack detection runs before tooling pick. `references/quality-tooling.md` carries the per-stack canonical tooling.

### 20 empty template files with TODOs (Critical)

**Shape.** Scaffold drops files for "everything that might be needed" - issue templates, PR template, CODEOWNERS, multiple workflows - all containing `TODO: customize this`.

**Grep test.** `grep -rE 'TODO|FIXME|customize|placeholder' .github/ docs/` returns the legitimate-but-rare hits, not pervasive markers across every scaffolded file.

**Guard.** The no-placeholder rule is structural. Step 0 mode detection asks what tier the repo needs; lower tiers omit files rather than ship empty ones.

### CONTRIBUTING.md nobody customized (High)

**Shape.** CONTRIBUTING.md generic enough to apply to any project: "Please open an issue first," "Follow our coding standards," with no actual coding standards named, no actual setup commands, no actual branching model.

**Grep test.** CONTRIBUTING.md must name: the dev-setup command (`pnpm install`, `make setup`), the test command (`pnpm test`), the branching model (PR-against-main / GitFlow / trunk), and at least one project-specific convention. A file missing any fails.

**Guard.** `references/community-governance.md` requires real-content checks at audit-mode REPO-2.1.

### `security@example.com` in SECURITY.md (Critical)

**Shape.** SECURITY.md ships with a placeholder reporting address that doesn't route anywhere.

**Grep test.** `grep -E 'example\.com|TODO|placeholder' SECURITY.md` returns zero matches; the contact must be a real email address or a real URL (GitHub Security Advisories tab counts).

**Guard.** Step 2 of the workflow requires the user to confirm the disclosure channel. The audit-mode REPO-2.3 check fails on placeholder addresses.

### Branch protection on paper but not in code (High)

**Shape.** README claims "main is protected" but `gh api repos/.../branches/main/protection` returns 404 or shows no required reviews.

**Grep test.** Branch protection rule exists at GitHub, with required PR review and required status checks listed. Documentation-only protection fails.

**Guard.** The audit-mode REPO-4.3 check verifies via the GitHub API, not via README scraping.

### Bureaucracy without users (Medium)

**Shape.** A small repo with no users, no contributors, ships with: `CODE_OF_CONDUCT.md`, `.github/ISSUE_TEMPLATE/bug.yml`, `.github/ISSUE_TEMPLATE/feature.yml`, `PULL_REQUEST_TEMPLATE.md`, three labeling workflows, a Discord integration, etc. None of it gets used; all of it adds friction to the next maintenance pass.

**Grep test.** For each "community" file, the audit asks: does this repo have an issue tracker with > 5 issues? a contributor list with > 1 person? a release with > 0 downloads? If the answer to all three is no, the community files are bureaucracy not enabling.

**Guard.** Step 0 mode detection asks the project's stage. Tier 1 (essentials) and Tier 2 (team) skip the community pack until traction arrives. The tier discipline is the antidote.

### Badge without service (Low)

**Shape.** README badges point at services that aren't wired up. CI badge for a workflow that doesn't exist; coverage badge from a service that's never been invoked; npm version badge for a package that isn't published.

**Grep test.** Each badge URL fetches a real status. Badges that fetch 404 or "no data" fail.

**Guard.** The audit-mode REPO-5.5 check verifies badges return live data.

### License with template year (Critical)

**Shape.** LICENSE shows `Copyright 2024` when the project started in 2026, or shows `Copyright {{year}}` literal.

**Grep test.** LICENSE year matches `git log --format=%cI --reverse | head -1` (first commit year) or current year if newer.

**Guard.** Step 2 of the workflow requires year confirmation; the audit-mode REPO-1.2 check fails on placeholder or wrong year.

### Secrets in git history (Critical)

**Shape.** `.env`, `credentials.json`, `*.pem`, `*.key`, or hardcoded API keys committed to history. Even if removed in a later commit, the history retains them.

**Grep test.** `gitleaks detect` returns clean. `git log -p | grep -E 'API_KEY|SECRET|password=' | head` returns the legitimate-config-template hits, not real secrets.

**Guard.** `.gitleaks.toml` + pre-commit hook + CI gitleaks workflow. The audit-mode REPO-1.7 + REPO-4.5 checks combine to catch this at multiple layers.

### Dependency pile-up (Medium)

**Shape.** Dependabot opens 47 PRs, none merged. Every dependency is one or more major versions behind. The repo's last "deps update" commit is 8 months old.

**Grep test.** Open Dependabot PR count <= 5. No dep more than one major version behind on the latest stable.

**Guard.** The audit-mode REPO-4.6 check counts pile-up. `references/release-distribution.md` carries the merge cadence.

### CHANGELOG that is the git log (Medium)

**Shape.** CHANGELOG.md content is `git log --oneline` output pasted in. No release sections, no [Unreleased], no Keep-a-Changelog format.

**Grep test.** CHANGELOG.md has at least one `## [X.Y.Z]` heading and an `[Unreleased]` section. Bare commit-list dumps fail.

**Guard.** `references/release-distribution.md` carries the Keep-a-Changelog template. Audit-mode REPO-2.6 enforces the format.

### Tag-release parity gap (Low)

**Shape.** Git tags exist (`v1.0`, `v1.1`, `v1.2`) but `gh release list` returns empty or only `v1.0`. Tags without releases produce silent ship-no-notes.

**Grep test.** For every git tag, a matching GitHub Release exists with non-empty notes. Mismatch fails.

**Guard.** The audit-mode REPO-6.5 check verifies via `gh release view`. The hub `scripts/lint.sh` `tag-release-parity` check enforces this across the suite.

### CI never executed on `main` (Medium)

**Shape.** Branch protection ruleset registers status checks by name, but no CI run has completed on `main` yet, so the named checks aren't selectable in GitHub's status-check index.

**Grep test.** `gh run list --workflow=ci.yml --branch=main` returns at least one completed run.

**Guard.** Open a trivial PR to trigger CI before declaring the protection live. Documented in repo-ready's own `AUDIT-REPORT.md` follow-up.

## Severity ladder

- **Critical**: blocks the scaffold. Must be fixed before declaring done.
- **High**: blocks the tier gate. Must be fixed before next tier.
- **Medium**: flagged in the audit; fix recommended.
- **Low**: cosmetic; flagged for awareness.

## Cross-references

- `SKILL.md` §workflow: per-step guards.
- `references/repo-audit.md`: the 42-criteria scorecard.
- `references/audit-mode.md`: the scoring engine and `AUDIT-REPORT.md` template.
- `references/agent-safety.md`: agent-runtime concerns (slopsquatting, bypass-by-fallback, session-startup reconciliation).
- `references/quality-tooling.md`: per-stack tooling.
- `references/community-governance.md`: real-content checks for community files.
