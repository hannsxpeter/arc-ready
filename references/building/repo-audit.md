# Repo Health Audit Checklist

39-point scorecard for evaluating repository health. Used by the skill in two modes: audit mode (score an existing repo) and verification mode (confirm setup is complete before declaring a tier done).

Every item has a check method, a pass criteria, a fail criteria, and a fix. No subjective judgment calls — each item is binary pass/fail.

---

## Scoring Overview

| Score | Rating | Meaning |
|---|---|---|
| 0-13 | **Needs work** | Missing essentials. Not ready for collaborators. |
| 14-22 | **Basic** | Functional but unprofessional. Would not pass a first-impression check. |
| 23-30 | **Good** | Team-ready. Supports collaboration and basic quality gates. |
| 31-35 | **Excellent** | Mature open source. Handles security, releases, and community at scale. |
| 36-39 | **Exemplary** | Top-tier repository. Nothing left to improve. |

Map to skill tiers:
- Tier 1 (Essentials) covers points 1-7
- Tier 2 (Team Ready) needs ~22+ to be credible
- Tier 3 (Mature) needs ~31+ to be credible
- Tier 4 (Hardened) needs 36+ and additional items outside this scorecard

---

## Category 1: Essentials (7 points)

The absolute minimum. If these fail, the repo is not ready for anyone other than the original author.

### 1.1 README.md exists and has content

**Check:**
```bash
# File exists and has more than 3 lines of real content
test -f README.md && [ "$(grep -c '[a-zA-Z]' README.md)" -gt 3 ]
```

**Pass:** README.md exists with a project description, install instructions, and at least one usage example. More than just a heading with the project name.

**Fail:** README.md is missing, empty, or contains only a heading (`# my-project` and nothing else).

**Fix:** Generate a README following `references/readme-craft.md`. At minimum: project name, one-paragraph description, install command, basic usage, license reference.

---

### 1.2 LICENSE file exists with valid SPDX text

**Check:**
```bash
# File exists (check common names)
ls LICENSE* LICENCE* COPYING* 2>/dev/null | head -1

# Verify it contains actual license text, not a template variable
! grep -qiE '\{\{author\}\}|\[year\]|\[fullname\]|INSERT.*NAME' LICENSE* 2>/dev/null
```

**Pass:** A file named `LICENSE`, `LICENSE.md`, or `LICENSE.txt` exists containing the full text of a recognized open-source license (MIT, Apache-2.0, GPL-3.0, etc.) with the correct year and copyright holder filled in.

**Fail:** No license file exists. Or the file exists but contains unresolved template variables (`[year]`, `{{author}}`). Or the file contains a license identifier without the actual text.

**Fix:** Choose the appropriate license for the project. Use the full SPDX text. Fill in the copyright year and holder. If unsure, read `references/licensing-legal.md`.

---

### 1.3 .gitignore exists and matches the stack

**Check:**
```bash
# File exists
test -f .gitignore

# Stack-specific entries present (examples)
# Node.js:
grep -q 'node_modules' .gitignore 2>/dev/null
# Python:
grep -q '__pycache__' .gitignore 2>/dev/null
# Go:
grep -qE '^\*\.exe$|/vendor/' .gitignore 2>/dev/null
# Rust:
grep -q '/target' .gitignore 2>/dev/null
# Java:
grep -qE '\.class$|/build/' .gitignore 2>/dev/null

# Secrets and OS files excluded
grep -q '\.env' .gitignore 2>/dev/null
grep -qE '\.DS_Store|Thumbs\.db' .gitignore 2>/dev/null
```

**Pass:** `.gitignore` exists and includes: (1) build output directories for the detected stack, (2) dependency directories, (3) IDE/editor files, (4) OS files (`.DS_Store`, `Thumbs.db`), (5) secret files (`.env`, `*.pem`, `*.key`).

**Fail:** `.gitignore` missing. Or present but doesn't match the stack (e.g., a Python project missing `__pycache__/` and `*.pyc`). Or missing `.env` exclusion.

**Fix:** Generate from GitHub's gitignore templates for the detected stack. Add `.env*`, IDE directories, and OS files. Verify no build artifacts are currently tracked (`git ls-files --cached | grep -E 'node_modules|__pycache__|/target/|/build/'`).

---

### 1.4 .gitattributes exists with `* text=auto`

**Check:**
```bash
test -f .gitattributes && grep -q '^\* text=auto' .gitattributes
```

**Pass:** `.gitattributes` exists and contains `* text=auto` for line ending normalization. May also include linguist overrides and LFS tracking patterns.

**Fail:** File missing or doesn't contain `* text=auto`.

**Fix:** Create `.gitattributes` with at minimum:
```
* text=auto
```
Add linguist overrides if the repo has generated files that skew language stats. Add LFS patterns for binary assets if applicable.

---

### 1.5 .editorconfig exists

**Check:**
```bash
test -f .editorconfig && grep -q 'indent_style' .editorconfig
```

**Pass:** `.editorconfig` exists with at least: `root = true`, `indent_style`, `indent_size`, `charset`, `end_of_line`, `trim_trailing_whitespace`, `insert_final_newline`.

**Fail:** File missing or present but effectively empty (no `indent_style` defined).

**Fix:** Create `.editorconfig` matching the project's existing style. Detect indent style from source files before generating — do not impose a style that conflicts with what's already committed.

---

### 1.6 Folder structure follows stack conventions

**Check:**
```bash
# Detect stack and check for conventional directories
# Node/TS: src/ or app/ exists, not source code in root
# Python: src/<package>/ or <package>/ exists
# Go: cmd/ or internal/ or main.go at root
# Rust: src/ with main.rs or lib.rs

# Generic check: source and test separation
ls -d src/ lib/ app/ cmd/ internal/ 2>/dev/null | head -1
ls -d tests/ test/ spec/ __tests__/ 2>/dev/null | head -1
```

**Pass:** Source code lives in a conventional directory for the stack (not scattered in the root). Tests are separated from source. No `dist/`, `build/`, or `out/` directories committed.

**Fail:** Source files dumped in the project root alongside config files. No separation between source and tests. Build artifacts committed to the repository.

**Fix:** Reorganize following the conventions in `references/repo-structure.md` for the detected stack.

---

### 1.7 No secrets committed

**Check:**
```bash
# Scan for common secret patterns
git log --all --diff-filter=A --name-only --pretty=format: -- '*.env' '*.pem' '*.key' '*.p12' '*.pfx' '*credentials*' '*secret*' '*.keystore' | sort -u | grep .

# Check for hardcoded secrets in source
grep -rn --include='*.{js,ts,py,go,rs,java,rb,php}' -E '(api[_-]?key|secret[_-]?key|password|aws_access_key|private[_-]?key)\s*[:=]\s*["\x27][a-zA-Z0-9+/]{16,}' . 2>/dev/null | grep -v node_modules | grep -v '.git/' | head -20

# Check for .env files tracked
git ls-files | grep -E '\.env$|\.env\.local$|\.env\.production$'
```

**Pass:** No `.env` files tracked in git. No hardcoded API keys, passwords, or private keys in source. No credential files (`.pem`, `.key`, `.p12`) in the repository.

**Fail:** Any secret file tracked. Any hardcoded credential found in source. Any `.env` file committed (`.env.example` is fine — `.env` is not).

**Fix:** Remove secrets from git history with `git filter-repo` or BFG Repo Cleaner. Add secret patterns to `.gitignore`. Rotate any exposed credentials immediately. Consider enabling GitHub secret scanning.

---

## Category 2: Community (7 points)

The collaboration layer. Without these, the repo is a solo project that happens to be public.

### 2.1 CONTRIBUTING.md exists with real workflow

**Check:**
```bash
test -f CONTRIBUTING.md && [ "$(wc -w < CONTRIBUTING.md)" -gt 100 ]

# Check it describes a real workflow, not just a placeholder
grep -qiE 'fork|branch|pull request|clone|npm install|pip install|go build|cargo build' CONTRIBUTING.md 2>/dev/null
```

**Pass:** CONTRIBUTING.md exists with 100+ words describing: how to set up the development environment, the branching/PR workflow, code style expectations, and how to run tests. References real commands for the detected stack.

**Fail:** Missing. Or exists but contains only "We welcome contributions!" with no actual workflow. Or describes a workflow that doesn't match the project (e.g., references `npm` in a Python project).

**Fix:** Write CONTRIBUTING.md describing the actual workflow. Include: prerequisites, setup commands, branch naming convention, PR process, code review expectations, and how to run the test suite.

---

### 2.2 CODE_OF_CONDUCT.md exists with real enforcement contact

**Check:**
```bash
test -f CODE_OF_CONDUCT.md

# Check for real contact (not example.com)
! grep -qi 'example\.com' CODE_OF_CONDUCT.md 2>/dev/null

# Has enforcement section
grep -qi 'enforcement' CODE_OF_CONDUCT.md 2>/dev/null
```

**Pass:** CODE_OF_CONDUCT.md exists (Contributor Covenant v2.1 recommended), contains a real enforcement contact email (not `@example.com`), and includes an enforcement section explaining the process.

**Fail:** Missing. Or uses `@example.com` as the enforcement contact. Or contains no enforcement mechanism.

**Fix:** Adopt Contributor Covenant v2.1. Replace the enforcement email with a real address monitored by the project maintainers.

---

### 2.3 SECURITY.md exists with real reporting process

**Check:**
```bash
test -f SECURITY.md

# Not a placeholder
! grep -qi 'example\.com' SECURITY.md 2>/dev/null
! grep -qiE '\[INSERT|TODO|TBD|PLACEHOLDER' SECURITY.md 2>/dev/null

# Has supported versions and reporting instructions
grep -qi 'supported' SECURITY.md 2>/dev/null
grep -qiE 'report|email|advisory' SECURITY.md 2>/dev/null
```

**Pass:** SECURITY.md exists with: a supported versions table, a real reporting mechanism (email or GitHub Security Advisories link), and a response timeline commitment.

**Fail:** Missing. Or contains placeholder emails. Or has no actual reporting instructions.

**Fix:** Create SECURITY.md with the project's supported version matrix, a real reporting email or GitHub Security Advisories link, and a response time commitment (e.g., "We will acknowledge within 48 hours").

---

### 2.4 Issue templates exist

**Check:**
```bash
# GitHub YAML forms (preferred)
ls .github/ISSUE_TEMPLATE/*.yml 2>/dev/null | grep -v config.yml | head -5

# Or legacy markdown templates
ls .github/ISSUE_TEMPLATE/*.md 2>/dev/null | head -5

# Template chooser config
test -f .github/ISSUE_TEMPLATE/config.yml
```

**Pass:** At least two issue templates exist (bug report + feature request). On GitHub, uses YAML form syntax (`.yml`). Template chooser `config.yml` exists to direct support questions away from issues.

**Fail:** No issue templates. Or only legacy markdown templates when YAML forms are available. Or templates are unmodified copies from a template generator.

**Fix:** Create YAML-based issue templates following `references/platform-github.md`. Include bug report and feature request at minimum. Add `config.yml` to disable blank issues and link to Discussions for support.

---

### 2.5 PR template exists

**Check:**
```bash
test -f .github/PULL_REQUEST_TEMPLATE.md || \
  ls .github/PULL_REQUEST_TEMPLATE/*.md 2>/dev/null | head -1
```

**Pass:** A pull request template exists at `.github/PULL_REQUEST_TEMPLATE.md` with a meaningful checklist: what the PR does, type of change, testing approach, and review checklist.

**Fail:** No PR template. Or template is a single line ("Describe your changes").

**Fix:** Create a PR template with sections for: description, type of change, testing approach, and a checklist reflecting the project's review standards.

---

### 2.6 CHANGELOG.md exists in Keep a Changelog format

**Check:**
```bash
test -f CHANGELOG.md

# Follows Keep a Changelog format
grep -q '## \[Unreleased\]' CHANGELOG.md 2>/dev/null || \
  grep -q '## Unreleased' CHANGELOG.md 2>/dev/null

# Has category headers
grep -qE '### (Added|Changed|Deprecated|Removed|Fixed|Security)' CHANGELOG.md 2>/dev/null
```

**Pass:** CHANGELOG.md exists following [Keep a Changelog](https://keepachangelog.com/) format: has an `[Unreleased]` section, uses category headers (Added, Changed, Deprecated, Removed, Fixed, Security), and entries are human-readable.

**Fail:** Missing. Or exists with only `# Changelog` and no content. Or uses a non-standard format.

**Fix:** Create CHANGELOG.md with the Keep a Changelog preamble, an `[Unreleased]` section, and category headers. If the project has existing releases, back-fill from git tags or GitHub releases.

---

### 2.7 Labels configured

**Check:**
```bash
# GitHub CLI
gh label list --json name --jq '.[].name' 2>/dev/null | sort

# Check for minimum required labels
gh label list --json name --jq '.[].name' 2>/dev/null | grep -qiE '^bug$'
gh label list --json name --jq '.[].name' 2>/dev/null | grep -qiE '^enhancement$'
gh label list --json name --jq '.[].name' 2>/dev/null | grep -qiE '^good.first.issue$'
```

**Pass:** Repository has at minimum: `bug`, `enhancement`, and `good first issue` labels. Better: a full taxonomy including type labels (bug, enhancement, question), priority labels, status labels (needs triage), and area labels.

**Fail:** Only GitHub's default labels, which are a grab bag. Or no labels configured. Or missing `good first issue` (GitHub uses this for its contributor matching features).

**Fix:** Delete GitHub's defaults and create a purposeful label set. At minimum: `bug`, `enhancement`, `good first issue`, `documentation`, `help wanted`, `duplicate`, `wontfix`, `invalid`.

---

## Category 3: Quality (7 points)

The automated enforcement layer. Without these, code quality depends entirely on human discipline.

### 3.1 CI pipeline exists and runs on PRs

**Check:**
```bash
# GitHub Actions
ls .github/workflows/*.yml 2>/dev/null | head -5

# Runs on PRs
grep -l 'pull_request' .github/workflows/*.yml 2>/dev/null

# GitLab
test -f .gitlab-ci.yml
```

**Pass:** A CI configuration exists (GitHub Actions, GitLab CI, or equivalent) and is triggered on pull requests and pushes to main.

**Fail:** No CI config. Or CI exists but only runs on push to main (not on PRs). Or CI is disabled/broken.

**Fix:** Create a CI workflow following `references/ci-cd-workflows.md` for the detected stack. Must trigger on `pull_request` and `push: branches: [main]`.

---

### 3.2 CI runs lint, test, and build (not echo placeholders)

**Check:**
```bash
# Check for real commands vs echo placeholders
grep -rn 'echo.*test\|echo.*lint\|echo.*build\|echo "hello"\|echo "done"' .github/workflows/*.yml 2>/dev/null

# Check for real tool invocations
grep -rn 'npm test\|npm run lint\|pytest\|go test\|cargo test\|cargo clippy\|ruff\|eslint\|biome' .github/workflows/*.yml 2>/dev/null
```

**Pass:** CI pipeline runs the project's actual linter, test runner, and build command. Commands reference real tools installed for the stack. No `echo "test"` placeholders.

**Fail:** CI steps use `echo` commands instead of real tool invocations. Or CI only runs one of lint/test/build but not all applicable steps.

**Fix:** Replace placeholder commands with the project's real tooling. Read the project's package manager config (`package.json` scripts, `pyproject.toml` tool config, `Makefile` targets) to determine the correct commands.

---

### 3.3 Linter configured for the stack

**Check:**
```bash
# JavaScript/TypeScript
ls eslint.config.* .eslintrc* biome.json biome.jsonc 2>/dev/null | head -1

# Python
grep -q '\[tool.ruff\]' pyproject.toml 2>/dev/null || \
  test -f .flake8 || test -f ruff.toml

# Go
test -f .golangci.yml || test -f .golangci.yaml

# Rust (clippy is built-in, check for config)
grep -q 'clippy' Cargo.toml 2>/dev/null || test -f clippy.toml
```

**Pass:** A linter is configured for the project's primary language. Config file exists. CI runs the linter.

**Fail:** No linter configuration. Or a linter config file exists for a different language than the project uses. Or the linter is configured but not run in CI.

**Fix:** Install and configure the standard linter for the stack. See `references/quality-tooling.md` for recommendations per language.

---

### 3.4 Formatter configured for the stack

**Check:**
```bash
# JavaScript/TypeScript
ls .prettierrc* biome.json biome.jsonc 2>/dev/null | head -1 && \
  grep -qE 'prettier|biome.*format' package.json 2>/dev/null

# Python
grep -q '\[tool.ruff.format\]' pyproject.toml 2>/dev/null || \
  grep -q '\[tool.black\]' pyproject.toml 2>/dev/null

# Go: gofmt is built-in, always present

# Rust: rustfmt is built-in
test -f rustfmt.toml 2>/dev/null || test -f .rustfmt.toml 2>/dev/null
```

**Pass:** A formatter is configured. For languages with a built-in formatter (Go, Rust), this is automatic. For others, a formatter config exists and is integrated into the workflow (CI or pre-commit hooks).

**Fail:** No formatter for a language that requires explicit configuration. Or two formatters configured (Prettier + Biome both formatting JS).

**Fix:** Configure one formatter per language. Prefer the stack standard (gofmt for Go, rustfmt for Rust, Ruff for Python, Biome or Prettier for JS/TS). Do not install two formatters for the same language.

---

### 3.5 Git hooks configured

**Check:**
```bash
# Husky (Node.js)
test -d .husky && ls .husky/pre-commit 2>/dev/null

# pre-commit (Python and polyglot)
test -f .pre-commit-config.yaml

# Lefthook (language-agnostic)
test -f lefthook.yml || test -f .lefthook.yml

# lint-staged (Node.js, usually paired with Husky)
grep -q 'lint-staged' package.json 2>/dev/null
```

**Pass:** A git hook manager is configured with at least a `pre-commit` hook that runs the linter/formatter on staged files. Optionally a `commit-msg` hook for conventional commit enforcement.

**Fail:** No git hooks configured. Or hooks are configured but don't run anything meaningful (empty hook scripts).

**Fix:** Install the appropriate hook manager for the stack: Husky + lint-staged for Node.js, pre-commit for Python, Lefthook for Go/Rust/polyglot. Configure `pre-commit` to run lint and format on staged files.

---

### 3.6 Type checking configured (if applicable)

**Check:**
```bash
# TypeScript
test -f tsconfig.json && grep -q '"strict"' tsconfig.json 2>/dev/null

# Python
grep -qE '\[tool\.(mypy|pyright)\]' pyproject.toml 2>/dev/null || \
  test -f mypy.ini || test -f pyrightconfig.json

# Languages with built-in type systems (Go, Rust, Java, C#) — auto-pass
```

**Pass:** For TypeScript: `tsconfig.json` exists with `strict: true` (or equivalent strict settings). For Python: mypy or pyright configured. For statically typed languages (Go, Rust, Java, C#, Swift): automatic pass — the compiler is the type checker. Type checker runs in CI.

**Fail:** TypeScript project without `tsconfig.json` or with `strict: false` and no alternate strict settings. Python project using type hints but no type checker configured.

**Fix:** For TypeScript: create or fix `tsconfig.json` with `strict: true`. For Python: add `[tool.mypy]` or `[tool.pyright]` to `pyproject.toml`. Add type check step to CI.

**Not applicable:** Dynamically typed languages without type hint support (shell scripts, legacy PHP, etc.). Mark as N/A and do not penalize.

---

### 3.7 Tests exist and pass

**Check:**
```bash
# Find test files
find . -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.go' -o -name 'test_*.py' -o -name '*_test.py' -o -name '*Test.java' -o -name '*_test.rs' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' | head -10

# Count test files
find . -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.go' -o -name 'test_*.py' -o -name '*_test.py' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' | wc -l
```

**Pass:** Test files exist (at least one per major module/package). Tests can be run with the project's test runner and pass. CI runs the tests.

**Fail:** No test files. Or test files exist but tests are all skipped/pending. Or tests fail when run.

**Fix:** Write tests for the project's core functionality. At minimum: one integration test that verifies the primary use case works end to end, and unit tests for critical business logic.

---

## Category 4: Security (6 points)

The defense layer. Without these, the repo is one `npm audit` away from embarrassment.

### 4.1 Dependency scanning configured (Dependabot/Renovate)

**Check:**
```bash
# Dependabot
test -f .github/dependabot.yml

# Renovate
test -f renovate.json || test -f .renovaterc || test -f .renovaterc.json || \
  grep -q '"renovate"' package.json 2>/dev/null
```

**Pass:** Dependabot or Renovate is configured with an appropriate update schedule and ecosystem matching the project's dependencies.

**Fail:** Neither configured. Or configured for the wrong ecosystem (e.g., `npm` entry but the project uses Python). Or configured with no grouping strategy (will flood the repo with individual PRs).

**Fix:** Create `.github/dependabot.yml` following `references/platform-github.md`. Configure update grouping to batch minor+patch updates. Include all relevant ecosystems (code dependencies + GitHub Actions + Docker).

---

### 4.2 SAST scanning in CI (CodeQL or equivalent)

**Check:**
```bash
# CodeQL
grep -rl 'codeql' .github/workflows/ 2>/dev/null
grep -rl 'github/codeql-action' .github/workflows/ 2>/dev/null

# Semgrep
grep -rl 'semgrep' .github/workflows/ 2>/dev/null

# Snyk
grep -rl 'snyk' .github/workflows/ 2>/dev/null
```

**Pass:** A SAST (Static Application Security Testing) tool is configured in CI and runs on PRs or on a schedule. CodeQL is the free default for GitHub repositories.

**Fail:** No security scanning in CI. Or scanning is configured but disabled or commented out.

**Fix:** Add a CodeQL workflow for GitHub repositories. CodeQL supports JavaScript, TypeScript, Python, Go, Java, C/C++, C#, Ruby, Swift, and Kotlin. For languages CodeQL doesn't support, use Semgrep or an equivalent.

---

### 4.3 Branch protection on main

**Check:**
```bash
# GitHub CLI — check branch protection rules
gh api repos/{owner}/{repo}/branches/main/protection 2>/dev/null | \
  grep -oE '"required_pull_request_reviews|required_status_checks"'

# Or check rulesets
gh api repos/{owner}/{repo}/rulesets 2>/dev/null | \
  grep -o '"name"'
```

**Pass:** The `main` branch has protection rules requiring: (1) pull request reviews before merging, (2) CI status checks to pass. Direct pushes to main are blocked.

**Fail:** No branch protection. Or protection exists but doesn't require PR reviews. Or protection doesn't require CI to pass.

**Fix:** Enable branch protection or create a ruleset. See `references/platform-github.md` for ruleset configuration. At minimum: require 1 approving review + require status checks. Enable "Do not allow bypassing the above settings."

---

### 4.4 No vulnerable dependencies with known CVEs

**Check:**
```bash
# npm
npm audit --production 2>/dev/null | tail -5

# Python (pip-audit)
pip-audit 2>/dev/null | tail -5

# Go
govulncheck ./... 2>/dev/null | tail -5

# Rust
cargo audit 2>/dev/null | tail -5

# GitHub CLI — check Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts --jq '[.[] | select(.state=="open")] | length' 2>/dev/null
```

**Pass:** Zero high or critical CVEs in production dependencies. Low/medium CVEs acceptable if acknowledged.

**Fail:** Open Dependabot alerts with high/critical severity. Or `npm audit` / `pip-audit` / `cargo audit` reports high/critical vulnerabilities.

**Fix:** Run the appropriate audit command. Update vulnerable packages. If a fix isn't available upstream, document the risk and apply mitigations. Do not ignore high/critical CVEs.

---

### 4.5 Secret scanning enabled

**Check:**
```bash
# GitHub — check if push protection is enabled
gh api repos/{owner}/{repo} --jq '.security_and_analysis.secret_scanning.status' 2>/dev/null
gh api repos/{owner}/{repo} --jq '.security_and_analysis.secret_scanning_push_protection.status' 2>/dev/null
```

**Pass:** GitHub secret scanning is enabled for the repository. Push protection is enabled to prevent secrets from being committed.

**Fail:** Secret scanning disabled or not available. No mechanism to prevent secret leaks.

**Fix:** Enable secret scanning in repository Settings > Code security and analysis. Enable push protection. For non-GitHub platforms, configure a pre-commit hook with `detect-secrets` or `gitleaks`.

---

### 4.6 Dependencies up to date

**Check:**
```bash
# npm
npm outdated 2>/dev/null | tail -20

# Python
pip list --outdated 2>/dev/null | tail -20

# Go
go list -m -u all 2>/dev/null | grep '\[' | tail -20

# Rust
cargo outdated 2>/dev/null | tail -20
```

**Pass:** No dependencies more than one major version behind. Minor/patch versions may be behind if intentional. Dependabot/Renovate is actively processing updates (PRs are being created and merged, not piling up).

**Fail:** Multiple dependencies are 2+ major versions behind. Or Dependabot PRs are piling up unmerged (10+ open dependency PRs is a smell).

**Fix:** Update dependencies in batches. Handle major version upgrades individually with testing. Merge or close stale Dependabot PRs. If a dependency is intentionally pinned, document why.

---

## Category 5: DX — Developer Experience (6 points)

The onboarding layer. If a new contributor can't go from clone to running in five minutes, these are failing.

### 5.1 README has Quick Start section (5 or fewer commands)

**Check:**
```bash
# Quick Start section exists
grep -qiE '## (quick.?start|getting.?started|setup|installation)' README.md 2>/dev/null

# Count commands in that section (rough heuristic)
sed -n '/## [Qq]uick/,/^## /p' README.md 2>/dev/null | grep -c '^\$\|^```'
```

**Pass:** README has a clearly labeled Quick Start (or Getting Started) section. A developer can go from zero to running in 5 or fewer commands. Commands are copy-pasteable (use `$` prefix or code blocks).

**Fail:** No Quick Start section. Or the setup requires reading 3 different files. Or the instructions require more than 5 commands. Or commands reference tools that aren't documented as prerequisites.

**Fix:** Add a Quick Start section to README. Format:
```
git clone <url>
cd <project>
<install deps>
<configure>
<run>
```
Five commands maximum. Link to CONTRIBUTING.md for the full development setup.

---

### 5.2 Task runner configured

**Check:**
```bash
# Makefile
test -f Makefile && grep -qE '^[a-zA-Z_-]+:' Makefile

# Justfile
test -f Justfile || test -f justfile

# npm scripts (Node.js)
grep -q '"scripts"' package.json 2>/dev/null && \
  node -e "const p=require('./package.json'); const s=Object.keys(p.scripts||{}); console.log(s.join(' '))" 2>/dev/null

# Python (Makefile or tox)
test -f tox.ini || test -f noxfile.py

# Go (Makefile is standard)
test -f Makefile
```

**Pass:** A task runner exists with at least these standard targets: `setup`/`install`, `dev`/`start`, `test`, `build`, `lint`, `clean`. New developers can discover available tasks by reading the task runner config.

**Fail:** No task runner. Or only raw commands documented in README with no automation. Or a Makefile exists but has only one or two targets.

**Fix:** Create a Makefile (universal), Justfile (modern alternative), or npm scripts (Node.js projects) with standard targets. Every common development action should be one command.

---

### 5.3 Development setup documented in CONTRIBUTING.md

**Check:**
```bash
# CONTRIBUTING.md has setup/development section
grep -qiE '## (development|setup|prerequisites|getting.started|local.development)' CONTRIBUTING.md 2>/dev/null

# Lists prerequisites
grep -qiE 'node|python|go|rust|java|ruby|docker|prerequisite|require' CONTRIBUTING.md 2>/dev/null
```

**Pass:** CONTRIBUTING.md contains a development setup section listing: prerequisites (language version, tools), installation steps, how to run the project locally, and how to run tests. Steps are specific to this project, not generic.

**Fail:** No development setup in CONTRIBUTING.md. Or setup section says "See README" (circular). Or lists prerequisites without versions.

**Fix:** Add a development setup section to CONTRIBUTING.md with: required tool versions, step-by-step setup commands, how to verify the setup works (e.g., "run `make test` and all tests should pass").

---

### 5.4 .env.example exists (if env vars needed)

**Check:**
```bash
# Check if the project uses environment variables
grep -rlE 'process\.env\.|os\.environ|os\.Getenv|std::env::var|ENV\[' \
  --include='*.{js,ts,py,go,rs,rb,java,php}' . 2>/dev/null | \
  grep -v node_modules | grep -v '.git/' | head -5

# If env vars are used, check for .env.example
test -f .env.example || test -f .env.sample || test -f .env.template

# Ensure .env is NOT committed
! git ls-files --error-unmatch .env 2>/dev/null
```

**Pass:** If the project uses environment variables: `.env.example` exists with all required variables listed (values blanked or set to safe defaults), and `.env` is in `.gitignore`. If the project doesn't use environment variables: automatic pass.

**Fail:** Project uses `process.env` / `os.environ` / equivalent but no `.env.example` exists. Or `.env` is committed to the repo. Or `.env.example` exists but is out of date (missing variables that the code references).

**Fix:** Create `.env.example` with every environment variable the project needs. Use placeholder values or safe defaults. Add comments explaining each variable. Ensure `.env` is in `.gitignore`.

---

### 5.5 README badges are accurate and green

**Check:**
```bash
# Extract badge URLs from README
grep -oE '\[!\[.*?\]\(https?://[^)]+\)' README.md 2>/dev/null | head -10

# Check for common badge services
grep -oE 'shields\.io|img\.shields\.io|github\.com/.*/(actions|workflows)/.*badge|coveralls|codecov|npmjs\.com.*badge' README.md 2>/dev/null
```

**Pass:** Badges exist for at least CI status and license. All badges link to real, active services. CI badge shows a passing status. No broken badge images (the dreaded gray "badge not found" rectangle).

**Fail:** Badges pointing to wrong repos or non-existent workflows. Broken badge images. CI badge showing failing. Badges for services not actually configured (e.g., Codecov badge but no coverage reporting set up).

**Fix:** Verify every badge URL. Remove badges for unconfigured services. Fix badge URLs to point to the correct repo/workflow/package. Add missing badges in order: CI status, coverage (if configured), version, license.

---

### 5.6 Clear onboarding path

**Check:**
```bash
# README links to CONTRIBUTING
grep -qi 'contributing' README.md 2>/dev/null

# CONTRIBUTING references setup steps
grep -qiE 'setup|install|getting.started' CONTRIBUTING.md 2>/dev/null

# README has license section
grep -qi '## license' README.md 2>/dev/null
```

**Pass:** A new contributor can follow a clear path: README (what is this, how to use it) -> CONTRIBUTING.md (how to develop it) -> issue templates (how to report problems) -> PR template (how to submit changes). Each document links to the next step. No dead ends.

**Fail:** README doesn't mention contributing. CONTRIBUTING.md doesn't reference setup. Documents exist but don't link to each other. A contributor has to guess the workflow.

**Fix:** Add a "Contributing" section to README linking to CONTRIBUTING.md. Add cross-references between documents. Verify the full path works: README -> setup -> first issue -> PR.

---

## Category 6: Release (6 points)

The distribution layer. Without these, releases are manual, error-prone, and undocumented.

### 6.1 Semantic versioning used for tags

**Check:**
```bash
# List tags
git tag -l 'v*' | sort -V | tail -10

# Check format matches semver
git tag -l | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | tail -5
```

**Pass:** Git tags follow Semantic Versioning (`v1.2.3`, `v2.0.0-beta.1`). Tags exist for at least one release.

**Fail:** No tags. Or tags don't follow SemVer (e.g., `release-20240101`, `latest`, `stable`). Or inconsistent prefix usage (mix of `v1.0` and `1.0`).

**Fix:** Adopt SemVer with `v` prefix convention. Tag the current state as `v0.1.0` if no tags exist. Use `v` prefix consistently.

---

### 6.2 Release automation configured

**Check:**
```bash
# semantic-release
grep -q 'semantic-release' package.json 2>/dev/null || \
  test -f .releaserc || test -f .releaserc.json || test -f .releaserc.yml || \
  test -f release.config.js || test -f release.config.cjs

# release-please
grep -rl 'release-please' .github/workflows/ 2>/dev/null
test -f release-please-config.json

# changesets
test -d .changeset

# GitHub release workflow on tag push
grep -l 'tags.*v\*\|gh release create' .github/workflows/*.yml 2>/dev/null
```

**Pass:** A release automation tool is configured (semantic-release, release-please, changesets, or a custom GitHub Actions workflow that creates releases on tag push).

**Fail:** No release automation. Releases are created manually or not at all.

**Fix:** Configure release automation appropriate for the project type. For most projects: release-please (creates a release PR for human review). For fully automated: semantic-release. For monorepos: changesets. At minimum: a workflow that creates a GitHub Release with auto-generated notes when a tag is pushed.

---

### 6.3 Changelog auto-generated or maintained

**Check:**
```bash
# Check CHANGELOG.md is non-trivial
test -f CHANGELOG.md && [ "$(wc -l < CHANGELOG.md)" -gt 10 ]

# Check for auto-generation config
test -f .github/release.yml  # GitHub auto-generated release notes categories
grep -q 'changelog' .releaserc* release.config.* 2>/dev/null
```

**Pass:** CHANGELOG.md is actively maintained (has entries for recent releases) OR release notes are auto-generated via `.github/release.yml` categories OR a release tool generates changelog entries.

**Fail:** CHANGELOG.md exists but hasn't been updated in over 6 months. Or no changelog mechanism at all.

**Fix:** Configure `.github/release.yml` for auto-generated release notes at minimum. Better: maintain CHANGELOG.md in Keep a Changelog format, either manually or via release automation.

---

### 6.4 Package publishing automated (if applicable)

**Check:**
```bash
# npm publishing
grep -rl 'npm publish\|npx.*publish' .github/workflows/ 2>/dev/null

# PyPI publishing
grep -rl 'pypi\|twine upload\|python.*publish' .github/workflows/ 2>/dev/null

# crates.io
grep -rl 'cargo publish' .github/workflows/ 2>/dev/null

# Docker
grep -rl 'docker.*push\|ghcr.io' .github/workflows/ 2>/dev/null

# GitHub Packages
grep -rl 'packages.*write\|npm\.pkg\.github\.com' .github/workflows/ 2>/dev/null
```

**Pass:** If the project publishes a package (npm, PyPI, crates.io, Docker image): publishing is automated via CI on release/tag. Uses OIDC trusted publishing where available (PyPI, npm).

**Fail:** Package is published manually (`npm publish` from a developer's laptop). Or publishing workflow exists but is broken or commented out.

**Not applicable:** Projects that don't publish packages (internal tools, applications). Mark as N/A and do not penalize.

**Fix:** Add a publishing workflow triggered on release creation or tag push. Use OIDC trusted publishing instead of token-based auth where the registry supports it.

---

### 6.5 GitHub Releases created with notes

**Check:**
```bash
# List recent releases
gh release list --limit 5 2>/dev/null

# Check if releases have notes (not empty body)
gh release view "$(git tag -l 'v*' | sort -V | tail -1)" --json body --jq '.body | length' 2>/dev/null
```

**Pass:** GitHub Releases exist for tagged versions. Releases have release notes (not empty). Notes are either auto-generated or manually written with meaningful content.

**Fail:** Tags exist but no GitHub Releases. Or Releases exist but have empty bodies. Or the only release is from 3 years ago.

**Fix:** Create GitHub Releases for existing tags: `gh release create v1.2.3 --generate-notes`. Configure `.github/release.yml` for categorized auto-generated notes.

---

### 6.6 CODEOWNERS configured

**Check:**
```bash
test -f .github/CODEOWNERS || test -f CODEOWNERS || test -f docs/CODEOWNERS

# Check it has actual rules (not just comments)
grep -v '^#' .github/CODEOWNERS 2>/dev/null | grep -v '^$' | head -5
```

**Pass:** CODEOWNERS file exists (preferably at `.github/CODEOWNERS`) with ownership rules mapping directories and file patterns to reviewers. At least a catch-all rule (`* @owner`) exists.

**Fail:** No CODEOWNERS file. Or file exists but contains only comments. Or rules reference teams/users that don't exist.

**Fix:** Create `.github/CODEOWNERS` with ownership mappings. At minimum: a catch-all `*` rule. Better: per-directory rules for major areas (frontend, backend, CI, docs). See `references/platform-github.md` for syntax.

---

## Running the Audit

### Automated scan script

Run this from the repository root to get a quick score:

```bash
#!/usr/bin/env bash
set -euo pipefail

score=0
total=39
results=""

pass() { score=$((score + 1)); results+="  PASS  $1\n"; }
fail() { results+="  FAIL  $1\n"; }
skip() { score=$((score + 1)); results+="  SKIP  $1 (not applicable)\n"; }

# === ESSENTIALS ===
results+="\n--- Essentials (7) ---\n"

# 1.1 README
[ -f README.md ] && [ "$(grep -c '[a-zA-Z]' README.md 2>/dev/null)" -gt 3 ] \
  && pass "1.1 README.md has content" || fail "1.1 README.md missing or empty"

# 1.2 LICENSE
(ls LICENSE* LICENCE* COPYING* 2>/dev/null | head -1 | grep -q .) && \
  ! grep -qiE '\{\{author\}\}|\[year\]|\[fullname\]' LICENSE* 2>/dev/null \
  && pass "1.2 LICENSE exists" || fail "1.2 LICENSE missing or has template vars"

# 1.3 .gitignore
[ -f .gitignore ] && grep -q '\.env' .gitignore 2>/dev/null \
  && pass "1.3 .gitignore exists" || fail "1.3 .gitignore missing or incomplete"

# 1.4 .gitattributes
[ -f .gitattributes ] && grep -q 'text=auto' .gitattributes 2>/dev/null \
  && pass "1.4 .gitattributes configured" || fail "1.4 .gitattributes missing"

# 1.5 .editorconfig
[ -f .editorconfig ] && grep -q 'indent_style' .editorconfig 2>/dev/null \
  && pass "1.5 .editorconfig exists" || fail "1.5 .editorconfig missing"

# 1.6 Folder structure
(ls -d src/ lib/ app/ cmd/ internal/ 2>/dev/null | head -1 | grep -q .) \
  && pass "1.6 Folder structure follows conventions" || fail "1.6 No conventional source directory"

# 1.7 No secrets
! git ls-files 2>/dev/null | grep -qE '\.env$|\.pem$|\.key$|credentials' \
  && pass "1.7 No secrets committed" || fail "1.7 Possible secrets in tracked files"

# === COMMUNITY ===
results+="\n--- Community (7) ---\n"

# 2.1 CONTRIBUTING.md
[ -f CONTRIBUTING.md ] && [ "$(wc -w < CONTRIBUTING.md 2>/dev/null)" -gt 100 ] \
  && pass "2.1 CONTRIBUTING.md has content" || fail "2.1 CONTRIBUTING.md missing or thin"

# 2.2 CODE_OF_CONDUCT.md
[ -f CODE_OF_CONDUCT.md ] && ! grep -qi 'example\.com' CODE_OF_CONDUCT.md 2>/dev/null \
  && pass "2.2 CODE_OF_CONDUCT.md exists" || fail "2.2 CODE_OF_CONDUCT.md missing or placeholder"

# 2.3 SECURITY.md
[ -f SECURITY.md ] && ! grep -qi 'example\.com' SECURITY.md 2>/dev/null \
  && pass "2.3 SECURITY.md exists" || fail "2.3 SECURITY.md missing or placeholder"

# 2.4 Issue templates
(ls .github/ISSUE_TEMPLATE/*.yml 2>/dev/null | grep -v config.yml | head -1 | grep -q .) \
  && pass "2.4 Issue templates exist" || fail "2.4 No issue templates"

# 2.5 PR template
[ -f .github/PULL_REQUEST_TEMPLATE.md ] \
  && pass "2.5 PR template exists" || fail "2.5 No PR template"

# 2.6 CHANGELOG.md
[ -f CHANGELOG.md ] && grep -qiE 'unreleased|## \[' CHANGELOG.md 2>/dev/null \
  && pass "2.6 CHANGELOG.md in proper format" || fail "2.6 CHANGELOG.md missing or malformed"

# 2.7 Labels (requires gh CLI and network)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  label_count=$(gh label list --json name --jq 'length' 2>/dev/null || echo 0)
  [ "$label_count" -gt 5 ] \
    && pass "2.7 Labels configured ($label_count labels)" || fail "2.7 Labels not configured"
else
  fail "2.7 Labels — cannot check (gh CLI not authenticated)"
fi

# === QUALITY ===
results+="\n--- Quality (7) ---\n"

# 3.1 CI pipeline
(ls .github/workflows/*.yml 2>/dev/null | head -1 | grep -q .) && \
  grep -ql 'pull_request' .github/workflows/*.yml 2>/dev/null \
  && pass "3.1 CI pipeline runs on PRs" || fail "3.1 No CI pipeline on PRs"

# 3.2 CI runs real commands
if ls .github/workflows/*.yml &>/dev/null; then
  ! grep -rq 'echo.*test\|echo.*lint\|echo "hello"' .github/workflows/*.yml 2>/dev/null \
    && pass "3.2 CI runs real commands" || fail "3.2 CI has echo placeholders"
else
  fail "3.2 No CI workflows to check"
fi

# 3.3 Linter
(ls eslint.config.* .eslintrc* biome.json biome.jsonc ruff.toml .golangci.yml .golangci.yaml clippy.toml 2>/dev/null | head -1 | grep -q . || \
  grep -q '\[tool.ruff\]' pyproject.toml 2>/dev/null) \
  && pass "3.3 Linter configured" || fail "3.3 No linter configured"

# 3.4 Formatter
(ls .prettierrc* biome.json rustfmt.toml .rustfmt.toml 2>/dev/null | head -1 | grep -q . || \
  grep -qE '\[tool\.ruff\.format\]|\[tool\.black\]' pyproject.toml 2>/dev/null || \
  [ -f go.mod ]) \
  && pass "3.4 Formatter configured" || fail "3.4 No formatter configured"

# 3.5 Git hooks
([ -d .husky ] || [ -f .pre-commit-config.yaml ] || [ -f lefthook.yml ] || [ -f .lefthook.yml ]) \
  && pass "3.5 Git hooks configured" || fail "3.5 No git hooks"

# 3.6 Type checking
if [ -f tsconfig.json ] || grep -qE '\[tool\.(mypy|pyright)\]' pyproject.toml 2>/dev/null || \
   [ -f go.mod ] || [ -f Cargo.toml ]; then
  pass "3.6 Type checking configured"
else
  if [ -f package.json ] && ! [ -f tsconfig.json ]; then
    fail "3.6 No type checking (JS project without TypeScript)"
  else
    skip "3.6 Type checking (not applicable)"
  fi
fi

# 3.7 Tests exist
test_count=$(find . -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.go' -o -name 'test_*.py' -o -name '*_test.py' -o -name '*_test.rs' -o -name '*Test.java' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' 2>/dev/null | wc -l | tr -d ' ')
[ "$test_count" -gt 0 ] \
  && pass "3.7 Tests exist ($test_count test files)" || fail "3.7 No test files found"

# === SECURITY ===
results+="\n--- Security (6) ---\n"

# 4.1 Dependency scanning
([ -f .github/dependabot.yml ] || [ -f renovate.json ] || [ -f .renovaterc ] || [ -f .renovaterc.json ]) \
  && pass "4.1 Dependency scanning configured" || fail "4.1 No Dependabot/Renovate"

# 4.2 SAST
grep -rql 'codeql\|semgrep\|snyk' .github/workflows/ 2>/dev/null \
  && pass "4.2 SAST scanning in CI" || fail "4.2 No SAST scanning"

# 4.3 Branch protection (requires gh CLI)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  gh api repos/{owner}/{repo}/branches/main/protection &>/dev/null \
    && pass "4.3 Branch protection on main" || fail "4.3 No branch protection"
else
  fail "4.3 Branch protection — cannot check (gh CLI not authenticated)"
fi

# 4.4 No vulnerable deps (basic check)
if [ -f package-lock.json ]; then
  high_vulns=$(npm audit --production --json 2>/dev/null | grep -o '"high":[0-9]*' | head -1 | cut -d: -f2)
  crit_vulns=$(npm audit --production --json 2>/dev/null | grep -o '"critical":[0-9]*' | head -1 | cut -d: -f2)
  [ "${high_vulns:-0}" -eq 0 ] && [ "${crit_vulns:-0}" -eq 0 ] \
    && pass "4.4 No high/critical CVEs" || fail "4.4 Vulnerable dependencies found"
else
  skip "4.4 Dependency vulnerabilities (no lockfile to audit)"
fi

# 4.5 Secret scanning (requires gh CLI)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  ss_status=$(gh api repos/{owner}/{repo} --jq '.security_and_analysis.secret_scanning.status' 2>/dev/null)
  [ "$ss_status" = "enabled" ] \
    && pass "4.5 Secret scanning enabled" || fail "4.5 Secret scanning not enabled"
else
  fail "4.5 Secret scanning — cannot check (gh CLI not authenticated)"
fi

# 4.6 Dependencies up to date (heuristic: check Dependabot PR count)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  dep_prs=$(gh pr list --label dependencies --state open --json number --jq 'length' 2>/dev/null || echo 0)
  [ "${dep_prs:-0}" -lt 10 ] \
    && pass "4.6 Dependencies reasonably current" || fail "4.6 Too many open dependency PRs ($dep_prs)"
else
  fail "4.6 Dependency freshness — cannot check (gh CLI not authenticated)"
fi

# === DX ===
results+="\n--- DX (6) ---\n"

# 5.1 Quick Start
grep -qiE '## (quick.?start|getting.?started|installation|setup)' README.md 2>/dev/null \
  && pass "5.1 README has Quick Start section" || fail "5.1 No Quick Start in README"

# 5.2 Task runner
([ -f Makefile ] || [ -f Justfile ] || [ -f justfile ] || [ -f tox.ini ] || [ -f noxfile.py ] || \
  ([ -f package.json ] && grep -q '"scripts"' package.json 2>/dev/null)) \
  && pass "5.2 Task runner configured" || fail "5.2 No task runner"

# 5.3 Dev setup in CONTRIBUTING
grep -qiE '## (development|setup|prerequisites|local)' CONTRIBUTING.md 2>/dev/null \
  && pass "5.3 Dev setup documented in CONTRIBUTING" || fail "5.3 No dev setup in CONTRIBUTING"

# 5.4 .env.example
env_usage=$(grep -rlE 'process\.env\.|os\.environ|os\.Getenv|std::env::var' \
  --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rs' \
  . 2>/dev/null | grep -v node_modules | grep -v '.git/' | head -1)
if [ -n "$env_usage" ]; then
  ([ -f .env.example ] || [ -f .env.sample ] || [ -f .env.template ]) \
    && pass "5.4 .env.example exists" || fail "5.4 Uses env vars but no .env.example"
else
  skip "5.4 .env.example (no env var usage detected)"
fi

# 5.5 Badges
grep -qE '!\[.*\]\(https?://' README.md 2>/dev/null \
  && pass "5.5 README has badges" || fail "5.5 No badges in README"

# 5.6 Onboarding path
grep -qi 'contributing' README.md 2>/dev/null && \
  grep -qiE 'setup|install' CONTRIBUTING.md 2>/dev/null \
  && pass "5.6 Clear onboarding path" || fail "5.6 Broken onboarding path"

# === RELEASE ===
results+="\n--- Release (6) ---\n"

# 6.1 Semver tags
git tag -l 2>/dev/null | grep -qE '^v?[0-9]+\.[0-9]+\.[0-9]+' \
  && pass "6.1 Semantic versioning tags" || fail "6.1 No semver tags"

# 6.2 Release automation
([ -f .releaserc ] || [ -f .releaserc.json ] || [ -f .releaserc.yml ] || \
  [ -f release.config.js ] || [ -f release.config.cjs ] || \
  [ -f release-please-config.json ] || [ -d .changeset ] || \
  grep -ql 'gh release create\|release-please' .github/workflows/*.yml 2>/dev/null) \
  && pass "6.2 Release automation configured" || fail "6.2 No release automation"

# 6.3 Changelog maintained
[ -f CHANGELOG.md ] && [ "$(wc -l < CHANGELOG.md 2>/dev/null)" -gt 10 ] \
  && pass "6.3 Changelog maintained" || fail "6.3 Changelog missing or trivial"

# 6.4 Package publishing
if grep -qE '"publishConfig"|"prepublishOnly"' package.json 2>/dev/null || \
   grep -qE '\[project\]' pyproject.toml 2>/dev/null || \
   grep -qE '^\[package\]' Cargo.toml 2>/dev/null; then
  grep -rql 'npm publish\|twine\|cargo publish\|docker.*push\|pypi' .github/workflows/ 2>/dev/null \
    && pass "6.4 Package publishing automated" || fail "6.4 Publishable package but no publish workflow"
else
  skip "6.4 Package publishing (not a publishable package)"
fi

# 6.5 GitHub Releases
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  release_count=$(gh release list --limit 1 --json tagName --jq 'length' 2>/dev/null || echo 0)
  [ "${release_count:-0}" -gt 0 ] \
    && pass "6.5 GitHub Releases exist" || fail "6.5 No GitHub Releases"
else
  fail "6.5 GitHub Releases — cannot check (gh CLI not authenticated)"
fi

# 6.6 CODEOWNERS
([ -f .github/CODEOWNERS ] || [ -f CODEOWNERS ] || [ -f docs/CODEOWNERS ]) \
  && pass "6.6 CODEOWNERS configured" || fail "6.6 No CODEOWNERS"

# === REPORT ===
echo ""
echo "=============================="
echo "  REPO HEALTH AUDIT"
echo "=============================="
printf "$results"
echo ""
echo "------------------------------"
echo "  Score: $score / $total"
echo "------------------------------"

if [ "$score" -ge 36 ]; then
  echo "  Rating: EXEMPLARY"
elif [ "$score" -ge 31 ]; then
  echo "  Rating: EXCELLENT"
elif [ "$score" -ge 23 ]; then
  echo "  Rating: GOOD"
elif [ "$score" -ge 14 ]; then
  echo "  Rating: BASIC"
else
  echo "  Rating: NEEDS WORK"
fi
echo "=============================="
```

---

## Audit Report Template

Use this format when reporting audit results to the user:

```
## Repo Health Audit: {project-name}

**Score: {score}/39 — {rating}**

### Summary
- Essentials: {n}/7
- Community: {n}/7
- Quality: {n}/7
- Security: {n}/6
- DX: {n}/6
- Release: {n}/6

### Critical failures (fix first)
- {item}: {one-line description of the failure}

### Recommended fixes (priority order)
1. {highest impact fix}
2. {next fix}
3. ...

### Passing items
{list of items that passed}

### Not applicable
{items skipped with justification}
```

Order fixes by impact: Essentials > Security > Quality > Community > DX > Release. Within a category, fix items that unblock other items first (e.g., fix CI before adding SAST scanning, since SAST runs in CI).

---

## How the Skill Uses This Checklist

**Audit mode (Mode C):** Run the full scorecard. Report the score, rating, and prioritized fix list. Offer to fix items in priority order.

**Verification mode (end of setup):** Run the scorecard items relevant to the completed tier. All items in the tier must pass before declaring the tier complete. Items in higher tiers are informational only.

**Enhancement mode (Mode B):** Run the scorecard to determine the current tier. Use failures to build the work list for advancing to the next tier.

The scorecard is the single source of truth for "is this repo ready?" If the scorecard says it fails, it fails — regardless of how the files look at a glance.
