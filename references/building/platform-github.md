# GitHub Platform Configuration Reference

Everything GitHub-specific for repository setup. Complete templates, exact file paths, opinionated defaults. Copy-paste and customize.

---

## Repository Metadata

Configure via Settings > General or `gh repo edit`.

**Description** — one sentence, no period, under 350 characters. Appears in search results, social cards, and `gh repo list` output.

```bash
gh repo edit --description "Fast, type-safe ORM for TypeScript and PostgreSQL"
```

**Topics** — max 20, lowercase, hyphens only. GitHub indexes these for Explore and search. Strategy:

| Category | Examples | Purpose |
|---|---|---|
| Language/runtime | `typescript`, `python`, `go`, `rust` | Discovery by stack |
| Framework | `nextjs`, `fastapi`, `gin`, `actix-web` | Framework ecosystem |
| Domain | `orm`, `cli`, `http-client`, `auth` | What it does |
| Category | `developer-tools`, `machine-learning`, `devops` | Broad classification |
| Ecosystem tags | `hacktoberfest`, `good-first-issues` | Community programs |

```bash
gh repo edit --add-topic typescript,orm,postgresql,database,developer-tools
```

Pick topics that real humans search for. Don't waste slots on `awesome` or `cool-project`.

**Website URL** — documentation site, landing page, or npm/PyPI package page.

```bash
gh repo edit --homepage "https://docs.example.com"
```

**Social preview** — 1280x640px PNG or JPG. Displayed on social media shares, Slack unfurls, and GitHub link previews. Upload via Settings > General > Social preview. Use a branded image with the project name and a one-line description — not a screenshot of code.

**Default branch** — `main` (GitHub's default since 2020). Change via Settings > General > Default branch, or:

```bash
gh api repos/{owner}/{repo} -X PATCH -f default_branch=main
```

---

## Issue Templates (YAML Form Syntax)

GitHub supports two formats: legacy Markdown templates and modern YAML form-based templates. Use YAML forms — they produce structured data, enforce required fields, and render as proper form elements instead of a blank textarea.

All templates go in `.github/ISSUE_TEMPLATE/`.

### Bug Report

`.github/ISSUE_TEMPLATE/bug_report.yml`

```yaml
name: Bug Report
description: Report a bug or unexpected behavior
title: "[Bug]: "
labels: ["bug", "triage"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to report this bug. Please fill out the form below.

  - type: input
    id: version
    attributes:
      label: Version
      description: What version are you using? Run `<tool> --version` to check.
      placeholder: "e.g., 2.4.1"
    validations:
      required: true

  - type: dropdown
    id: os
    attributes:
      label: Operating System
      description: What OS are you running?
      options:
        - macOS
        - Linux
        - Windows
        - Other
    validations:
      required: true

  - type: dropdown
    id: runtime
    attributes:
      label: Runtime / Environment
      description: Select the relevant runtime.
      multiple: true
      options:
        - Node.js 18
        - Node.js 20
        - Node.js 22
        - Bun
        - Deno
        - Docker
        - Other
    validations:
      required: false

  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: A clear description of the bug.
      placeholder: Describe what happened.
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      description: Minimal steps to reproduce the behavior.
      value: |
        1. 
        2. 
        3. 
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What did you expect to happen?
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
      description: What actually happened? Include error messages and stack traces.
      render: shell
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Relevant Log Output
      description: Paste any relevant logs. This will be automatically formatted as code.
      render: shell
    validations:
      required: false

  - type: textarea
    id: additional
    attributes:
      label: Additional Context
      description: Screenshots, config files, or anything else that might help.
    validations:
      required: false

  - type: checkboxes
    id: terms
    attributes:
      label: Checklist
      options:
        - label: I have searched existing issues to make sure this is not a duplicate.
          required: true
        - label: I can reproduce this bug consistently.
          required: false
```

### Feature Request

`.github/ISSUE_TEMPLATE/feature_request.yml`

```yaml
name: Feature Request
description: Suggest a new feature or improvement
title: "[Feature]: "
labels: ["enhancement"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        Describe the feature you'd like. We prioritize features that solve real problems.

  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this feature solve? Describe the pain point.
      placeholder: "I'm always frustrated when..."
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: Describe the solution you'd like. Be specific about the API or behavior.
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: What alternatives have you considered? Workarounds, other tools, etc.
    validations:
      required: false

  - type: dropdown
    id: importance
    attributes:
      label: How important is this feature?
      options:
        - Nice to have
        - Important — affects my workflow
        - Critical — blocking my use case
    validations:
      required: true

  - type: textarea
    id: additional
    attributes:
      label: Additional Context
      description: Mockups, code examples, links to related issues or discussions.
    validations:
      required: false

  - type: checkboxes
    id: contribution
    attributes:
      label: Contribution
      options:
        - label: I would be willing to submit a PR for this feature.
          required: false
```

### Template Chooser Configuration

`.github/ISSUE_TEMPLATE/config.yml`

```yaml
blank_issues_enabled: false
contact_links:
  - name: Questions & Support
    url: https://github.com/{owner}/{repo}/discussions/categories/q-a
    about: Ask questions in GitHub Discussions — don't open an issue for support.
  - name: Security Vulnerability
    url: https://github.com/{owner}/{repo}/security/advisories/new
    about: Report security vulnerabilities privately via GitHub Security Advisories.
```

Setting `blank_issues_enabled: false` forces users to pick a template or contact link. This prevents unstructured issues. If you want to allow freeform issues, set it to `true`.

---

## Pull Request Template

`.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## What does this PR do?

<!-- Describe the change in 1-3 sentences. Link the issue it addresses. -->

Closes #

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactor (no functional changes)
- [ ] Documentation update
- [ ] CI/build/infrastructure change

## How was this tested?

<!-- Describe the tests you ran. Include commands and relevant config. -->

## Checklist

- [ ] My code follows the project's code style
- [ ] I have added tests that prove my fix/feature works
- [ ] All new and existing tests pass
- [ ] I have updated documentation as needed
- [ ] I have checked for breaking changes and noted them above
- [ ] I have added a changeset / changelog entry (if applicable)

## Screenshots (if applicable)

<!-- Add screenshots for UI changes. Before/after if it's a visual change. -->
```

You can have multiple PR templates. Place them in `.github/PULL_REQUEST_TEMPLATE/` as separate files. Contributors select them via query parameter: `?template=refactor.md`. The default template at `.github/PULL_REQUEST_TEMPLATE.md` is used when no template is specified.

---

## FUNDING.yml

`.github/FUNDING.yml`

Controls the "Sponsor" button on the repository page. Supports these platforms:

```yaml
# GitHub Sponsors — accepts up to 4 usernames
github: [username]
# github: [user1, user2]

# Open Collective
open_collective: project-name

# Patreon
patreon: creator-name

# Ko-fi
ko_fi: creator-name

# Tidelift
tidelift: npm/package-name
# tidelift: pypi/package-name

# Community Bridge (deprecated — use LFX Mentorship)
community_bridge: project-name

# Liberapay
liberapay: username

# IssueHunt
issuehunt: username

# Polar
polar: username

# Buy Me a Coffee
buy_me_a_coffee: username

# Thanks.dev
thanks_dev: gh/username

# Custom URLs — up to 4
custom: ["https://donate.example.com"]
# custom: ["https://link1.com", "https://link2.com"]
```

Only include platforms you actually use. An empty platform key is ignored. Most projects use one or two: `github` + one custom link.

---

## CODEOWNERS

Place at: `.github/CODEOWNERS` (or repo root, or `docs/`). GitHub checks these locations in order; `.github/CODEOWNERS` is the convention.

CODEOWNERS auto-requests reviews from the specified owners when a PR touches matching files. Requires branch protection with "Require review from code owners" enabled.

### Syntax

```
# Each line is a file pattern followed by one or more owners.
# Owners can be @username, @org/team-name, or email.
# Last matching pattern takes precedence (like .gitignore).

# Default owner for everything
* @org/engineering

# Frontend team owns all frontend code
/src/components/ @org/frontend
/src/pages/ @org/frontend
/src/styles/ @org/frontend
*.css @org/frontend
*.tsx @org/frontend

# Backend team owns API and database
/src/api/ @org/backend
/src/db/ @org/backend
/src/models/ @org/backend

# DevOps owns CI/CD and infrastructure
/.github/workflows/ @org/devops
/infrastructure/ @org/devops
/terraform/ @org/devops
Dockerfile @org/devops
docker-compose*.yml @org/devops

# Documentation team
/docs/ @org/docs-team
*.md @org/docs-team

# Security-sensitive files require security team review
/src/auth/ @org/security
/src/crypto/ @org/security
SECURITY.md @org/security

# Package manifest changes need lead review
package.json @techleaduser
package-lock.json @techleaduser
go.mod @techleaduser
go.sum @techleaduser
Cargo.toml @techleaduser
Cargo.lock @techleaduser
pyproject.toml @techleaduser
requirements*.txt @techleaduser
```

### Rules

- Last match wins. Put specific patterns after general patterns.
- Teams must have explicit read access to the repository.
- A pattern with no owner disables ownership for matching files.
- Directories need trailing `/` to match all contents.
- `*` at root matches everything. Use it sparingly — it means every PR requires that owner's review.
- Empty lines and `#` comments are ignored.

---

## Dependabot Configuration

`.github/dependabot.yml`

```yaml
version: 2
updates:
  # JavaScript / TypeScript (npm)
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "America/New_York"
    open-pull-requests-limit: 10
    reviewers:
      - "org/engineering"
    labels:
      - "dependencies"
      - "automated"
    commit-message:
      prefix: "chore(deps):"
    groups:
      # Group minor and patch updates to reduce PR noise
      dev-dependencies:
        dependency-type: "development"
        update-types:
          - "minor"
          - "patch"
      production-dependencies:
        dependency-type: "production"
        update-types:
          - "patch"
      # Group related packages
      typescript:
        patterns:
          - "typescript"
          - "@types/*"
      linting:
        patterns:
          - "eslint*"
          - "@eslint/*"
          - "prettier*"
          - "biome"
          - "@biomejs/*"
      testing:
        patterns:
          - "vitest*"
          - "@vitest/*"
          - "jest*"
          - "@jest/*"
          - "@testing-library/*"
    ignore:
      # Ignore major version bumps for specific packages (handle manually)
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
    # Vulnerability alerts still create PRs for ignored major bumps

  # Python (pip)
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "python"
    groups:
      dev:
        dependency-type: "development"
      typing:
        patterns:
          - "mypy"
          - "pyright"
          - "types-*"

  # Go modules
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "go"
    groups:
      all-go-deps:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # Rust (Cargo)
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "rust"
    groups:
      all-cargo-deps:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # Java / Kotlin (Maven)
  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "java"

  # Docker
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "docker"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(ci):"
    labels:
      - "ci"
      - "automated"
    groups:
      github-actions:
        patterns:
          - "*"
```

### Ecosystem Reference

| Ecosystem | `package-ecosystem` value | Manifest file |
|---|---|---|
| npm / yarn / pnpm | `npm` | `package.json` |
| pip / pipenv / poetry | `pip` | `requirements.txt`, `Pipfile`, `pyproject.toml` |
| Go modules | `gomod` | `go.mod` |
| Cargo (Rust) | `cargo` | `Cargo.toml` |
| Maven | `maven` | `pom.xml` |
| Gradle | `gradle` | `build.gradle`, `build.gradle.kts` |
| NuGet (.NET) | `nuget` | `.csproj`, `packages.config` |
| Bundler (Ruby) | `bundler` | `Gemfile` |
| Composer (PHP) | `composer` | `composer.json` |
| Hex (Elixir) | `mix` | `mix.exs` |
| Pub (Dart/Flutter) | `pub` | `pubspec.yaml` |
| Docker | `docker` | `Dockerfile` |
| GitHub Actions | `github-actions` | `.github/workflows/*.yml` |
| Terraform | `terraform` | `*.tf` |
| Helm | `helm` | `Chart.yaml` |
| Swift (SPM) | `swift` | `Package.swift` |

### Grouping Strategy

Group aggressively to reduce PR volume. One PR with 12 minor dev dependency bumps is better than 12 individual PRs.

- **Group by dependency type**: `development` vs `production`. Dev deps can be batched more aggressively.
- **Group by pattern**: packages from the same org or toolchain (`@types/*`, `eslint*`, `@testing-library/*`).
- **Group by update type**: batch `minor` + `patch` together, keep `major` separate for manual review.
- **Ignore major bumps globally**: set `ignore` with `version-update:semver-major` and handle majors manually. Dependabot still creates security alert PRs for ignored packages.

### Monorepo Configuration

For monorepos, define separate entries per package directory:

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/packages/frontend"
    schedule:
      interval: "weekly"
    groups:
      all:
        patterns: ["*"]
        update-types: ["minor", "patch"]

  - package-ecosystem: "npm"
    directory: "/packages/backend"
    schedule:
      interval: "weekly"
    groups:
      all:
        patterns: ["*"]
        update-types: ["minor", "patch"]
```

---

## Release Notes Configuration

`.github/release.yml`

Controls how GitHub auto-generates release notes. When you create a release and click "Generate release notes," GitHub groups merged PRs by the categories defined here.

```yaml
changelog:
  exclude:
    labels:
      - "skip-changelog"
      - "automated"
      - "dependencies"
    authors:
      - "dependabot"
      - "renovate"
      - "github-actions"
  categories:
    - title: "Breaking Changes"
      labels:
        - "breaking-change"
        - "major"
    - title: "New Features"
      labels:
        - "enhancement"
        - "feature"
    - title: "Bug Fixes"
      labels:
        - "bug"
        - "bugfix"
        - "fix"
    - title: "Performance"
      labels:
        - "performance"
        - "perf"
    - title: "Documentation"
      labels:
        - "documentation"
        - "docs"
    - title: "Infrastructure"
      labels:
        - "ci"
        - "infrastructure"
        - "devops"
    - title: "Other Changes"
      labels:
        - "*"
```

The `"*"` label in the last category acts as a catch-all for PRs that don't match any other category. Without it, unlabeled PRs appear in an "Other" section by default.

PRs with labels in `exclude.labels` and commits by authors in `exclude.authors` are omitted entirely from generated notes. This keeps dependency bot noise out of your changelogs.

---

## Releases

### Creating Releases

Releases are Git tags with attached metadata. Create via UI (Releases > Draft a new release) or CLI:

```bash
# Create a tag and release with auto-generated notes
gh release create v1.2.0 --generate-notes

# Create from a specific commit/branch
gh release create v1.2.0 --target main --generate-notes

# Draft release (not published until manually released)
gh release create v1.2.0 --draft --generate-notes

# Pre-release (marked as non-production)
gh release create v2.0.0-beta.1 --prerelease --generate-notes

# With a custom title and notes
gh release create v1.2.0 --title "v1.2.0 — Performance Release" --notes-file RELEASE_NOTES.md

# Attach binary assets
gh release create v1.2.0 --generate-notes \
  ./dist/myapp-linux-amd64.tar.gz \
  ./dist/myapp-darwin-amd64.tar.gz \
  ./dist/myapp-windows-amd64.zip
```

### Release Assets

Attach build artifacts to releases. Common assets:

| Project type | Typical assets |
|---|---|
| CLI tool | Platform-specific binaries (`linux-amd64`, `darwin-arm64`, `windows-amd64.exe`), checksums file |
| Desktop app | `.dmg`, `.AppImage`, `.exe`, `.msi` |
| Library | Source archive (auto-generated), SBOM |
| Container | No assets — push to GHCR instead |

```bash
# Upload assets to an existing release
gh release upload v1.2.0 ./dist/checksums.txt ./dist/myapp-linux-amd64.tar.gz

# Delete an asset
gh release delete-asset v1.2.0 myapp-linux-amd64.tar.gz
```

### Release Automation

For automated releases, use GitHub Actions to create releases on tag push:

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Create GitHub Release
        run: gh release create ${{ github.ref_name }} --generate-notes
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Pre-release Strategy

Use pre-releases for testing before stable release:

```
v2.0.0-alpha.1  →  v2.0.0-alpha.2  →  v2.0.0-beta.1  →  v2.0.0-rc.1  →  v2.0.0
```

Pre-releases are shown on the Releases page but are not marked as "Latest." Users won't accidentally install them unless they explicitly opt in.

---

## GitHub Pages

### Branch Deployment (Simple)

1. Go to Settings > Pages.
2. Source: "Deploy from a branch."
3. Select branch (`main` or `gh-pages`) and folder (`/` or `/docs`).
4. GitHub builds with Jekyll by default. Add `.nojekyll` to the root if you don't use Jekyll.

Best for: static HTML, simple documentation sites, projects that build docs into `docs/`.

### GitHub Actions Deployment (Recommended)

For any static site generator (Docusaurus, VitePress, MkDocs, Astro, Next.js static export):

1. Go to Settings > Pages.
2. Source: "GitHub Actions."

```yaml
# .github/workflows/pages.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist  # or ./build, ./out — wherever your SSG outputs

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

### Custom Domains

1. Settings > Pages > Custom domain: enter `docs.example.com`.
2. Add a CNAME DNS record: `docs.example.com` -> `{username}.github.io`.
3. GitHub creates a `CNAME` file in your repo (or add it manually).
4. Enable "Enforce HTTPS" after DNS propagates.

For apex domains (`example.com`), use A records pointing to GitHub's IPs:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

And an AAAA record for IPv6:

```
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

---

## Repository Settings

Settings that cannot be configured via files in the repo — configure via GitHub UI or API.

### Feature Toggles

Settings > General > Features:

| Setting | Recommendation | Why |
|---|---|---|
| Wikis | **Off** | Put docs in the repo. Wikis are unsearchable, unversioned, and disconnected from code. |
| Issues | **On** | Required for issue templates to work. |
| Sponsorships | On if FUNDING.yml exists | Shows Sponsor button. |
| Discussions | **On** for open source | Separates Q&A from bugs. See Discussions section below. |
| Projects | On if using GitHub Projects | Otherwise off to reduce clutter. |

### Merge Strategies

Settings > General > Pull Requests:

| Strategy | When to use | Setting |
|---|---|---|
| Squash and merge | **Most projects.** One commit per PR. Clean history. | Enable, set as default. |
| Merge commit | When you need to preserve full branch history. | Enable as fallback. |
| Rebase and merge | When you want linear history without squash. | Disable unless team prefers it. |

Recommended: enable "Squash and merge" as default, disable "Rebase and merge," keep "Merge commit" as fallback. Check "Automatically delete head branches" to clean up merged branches.

```
[x] Allow squash merging        — Default commit message: PR title
[x] Allow merge commits          — (fallback)
[ ] Allow rebase merging          — (disabled)
[x] Always suggest updating PR branches
[x] Automatically delete head branches
```

### Branch Protection vs. Rulesets

GitHub offers two systems. **Rulesets** are the modern replacement and should be preferred for new repos.

#### Rulesets (Modern — Recommended)

Settings > Rules > Rulesets > New ruleset

Rulesets are more flexible: they support multiple branches, bypass lists, org-level application, and don't require admin access to configure at the org level.

```bash
# Create a ruleset via API
gh api repos/{owner}/{repo}/rulesets -X POST --input - <<'EOF'
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "bypass_actors": [
    {
      "actor_id": 1,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    { "type": "required_status_checks",
      "parameters": {
        "strict_status_checks_policy": true,
        "required_status_checks": [
          { "context": "CI" }
        ]
      }
    },
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" }
  ]
}
EOF
```

#### Branch Protection (Legacy)

Settings > Branches > Add branch protection rule

Still works, still widely used. Key settings for the `main` branch:

| Setting | Value | Why |
|---|---|---|
| Require a pull request before merging | **Yes** | No direct pushes to main. |
| Required approving reviews | **1** (2 for enterprise) | Code review gate. |
| Dismiss stale reviews on new pushes | **Yes** | Re-review after changes. |
| Require review from code owners | **Yes** (if CODEOWNERS exists) | Domain expert review. |
| Require status checks to pass | **Yes** | CI must be green. |
| Require branches to be up to date | **Yes** | No merge skew. |
| Require conversation resolution | **Yes** | Address all review comments. |
| Require linear history | Optional | Forces squash or rebase. |
| Include administrators | **Yes** | No bypass, even for admins. |
| Restrict force pushes | **Yes** | Prevent history rewriting. |
| Prevent deletions | **Yes** | Can't delete main. |

### Environments

Settings > Environments. Used for deployment protection rules.

| Environment | Protection rules | Use case |
|---|---|---|
| `production` | Required reviewers, wait timer (optional) | Production deploys |
| `staging` | None or required reviewers | Pre-production testing |
| `github-pages` | None (auto-created by Pages) | Documentation site |

Environments enable deployment branch restrictions (only `main` can deploy to production) and environment secrets (separate credentials per environment).

---

## GitHub Discussions

Settings > General > Features > Discussions (enable).

### Recommended Category Setup

Configure via Discussions > Categories (pencil icon):

| Category | Format | Description | Who can post |
|---|---|---|---|
| **Announcements** | Announcement | Release notes, breaking changes, project updates | Maintainers only |
| **Q&A** | Question/Answer | Support questions — mark accepted answers | Anyone |
| **Ideas** | Open-ended | Feature ideas and proposals before they become issues | Anyone |
| **Show and Tell** | Open-ended | Share projects, integrations, and use cases built with this project | Anyone |
| **General** | Open-ended | Anything that doesn't fit the other categories | Anyone |

**Why these five:**
- **Announcements** keeps release communication in one place and prevents issue tracker noise.
- **Q&A** with accepted answers creates a searchable knowledge base. The answer format prevents "me too" chains.
- **Ideas** separates brainstorming from actionable feature requests (which belong in Issues).
- **Show and Tell** builds community and provides social proof.
- **General** is the catch-all so nothing falls through the cracks.

### Pinning and Labels

Pin an "About This Repository" or "Welcome" discussion in General to orient newcomers. Link from your SUPPORT.md and issue template `config.yml` to drive traffic from issues to discussions for support questions.

Convert discussions to issues when an idea becomes actionable: Discussion > sidebar > "Create issue from discussion."

---

## GitHub Packages / GitHub Container Registry (GHCR)

### Container Registry (GHCR)

GHCR hosts Docker/OCI images at `ghcr.io/{owner}/{image}`.

**Publishing from GitHub Actions:**

```yaml
# .github/workflows/docker-publish.yml
name: Publish Docker Image
on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

**Visibility:** Packages inherit visibility from the repo by default. For public images from public repos, no authentication is needed to pull. For private repos, users need a PAT with `read:packages` scope.

### npm Registry

GHCR also serves as an npm registry at `https://npm.pkg.github.com`.

**Package configuration** (in `package.json`):

```json
{
  "name": "@owner/package-name",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

**Publishing from Actions:**

```yaml
# In your release workflow
- uses: actions/setup-node@v4
  with:
    node-version: 22
    registry-url: https://npm.pkg.github.com
- run: npm publish
  env:
    NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Consumer configuration** (`.npmrc` in the consuming project):

```
@owner:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

Most open source projects should publish to npmjs.com instead. Use GitHub npm registry for internal/private packages.

### Other Supported Package Types

| Type | Registry URL | Ecosystem |
|---|---|---|
| Container (Docker/OCI) | `ghcr.io` | Docker, Podman, Kubernetes |
| npm | `npm.pkg.github.com` | Node.js |
| Maven | `maven.pkg.github.com` | Java, Kotlin, Scala |
| Gradle | `maven.pkg.github.com` | Java, Kotlin |
| NuGet | `nuget.pkg.github.com` | .NET, C# |
| RubyGems | `rubygems.pkg.github.com` | Ruby |

---

## Quick Reference: File Placement

```
.github/
  ISSUE_TEMPLATE/
    bug_report.yml
    feature_request.yml
    config.yml
  PULL_REQUEST_TEMPLATE.md
  CODEOWNERS
  FUNDING.yml
  dependabot.yml
  release.yml
  workflows/
    ci.yml
    release.yml
    docker-publish.yml
    pages.yml
```

All paths are relative to the repository root. GitHub only recognizes these exact paths — no variations.
