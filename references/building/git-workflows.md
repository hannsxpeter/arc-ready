# Git Workflows, Automation, and Issue Management

Reference for branching strategies, repository bots, label systems, merge policies, Git LFS, and dependency management. Load this file when configuring Tier 2+ repositories that need collaboration infrastructure.

---

## 1. Git Workflows

Pick one workflow per project and document it in CONTRIBUTING.md. Mixing workflows confuses contributors.

### Trunk-Based Development

The simplest model. Everyone commits to `main` (or `trunk`). Short-lived feature branches are optional and last hours, not days. Feature flags gate incomplete work.

```
main  ──●──●──●──●──●──●──●──●──●──●──
         │        │
         └──●──●──┘   (short-lived branch, < 1 day)
```

**How it works:**
- All developers commit directly to `main` or merge very short branches (< 1 day)
- CI runs on every push to `main`
- Feature flags hide incomplete features from users
- Releases are cut from `main` via tags or release branches

**When to use:** High-trust teams with strong CI, continuous deployment, mobile/web apps shipping daily.

**Team size:** 1-20 engineers. Requires discipline and good CI coverage. Breaks down without automated testing.

**Pros:** Minimal merge conflicts, fast integration, simple mental model.
**Cons:** Requires feature flags for incomplete work, CI must be fast and reliable, no gatekeeping on `main`.

---

### GitHub Flow (Recommended Default)

Branch from `main`, open a PR, get review, merge back. The workflow GitHub itself uses and the right default for most projects.

```
main     ──●──────────●──────────●──────────●──
            \        /            \        /
feature/a    ●──●──●              |       |
                                   \     /
            feature/b               ●──●
```

**How it works:**
1. Create a branch from `main`: `git checkout -b feature/add-search`
2. Make commits on the branch
3. Open a pull request against `main`
4. Discuss, review, get CI green
5. Merge to `main` (squash merge recommended)
6. Deploy from `main`

**When to use:** Most projects. Web apps, libraries, CLIs, APIs. Any project with continuous delivery or frequent releases.

**Team size:** 1-50+ engineers. Scales well with branch protection and CODEOWNERS.

**Pros:** Simple, well-understood, native GitHub support, good PR review flow.
**Cons:** No explicit release staging (use tags or release branches if needed).

**This is the recommended default.** If you have no strong reason to pick another workflow, use GitHub Flow.

---

### GitFlow

A structured model with dedicated branches for features, releases, and hotfixes. Designed for software with versioned releases (desktop apps, libraries, mobile apps).

```
main       ──●─────────────────●───────────●──
              \               / \         /
release/1.0    ●──●──●──●──●    |        |
              /               \  |       |
develop  ──●──●──●──●──●──●──●──●──●──●──●──
              \        /          \     /
feature/a      ●──●──●            |   |
                                   \ /
              feature/b             ●
```

**How it works:**
- `main` holds production-ready code, tagged with version numbers
- `develop` is the integration branch for features
- `feature/*` branches are created from `develop` and merged back
- `release/*` branches are created from `develop` for release prep (bug fixes, version bumps)
- `hotfix/*` branches are created from `main` for emergency production fixes, merged to both `main` and `develop`

**When to use:** Software with explicit version numbers and release cycles: desktop apps, mobile apps, libraries with SemVer, anything that ships to customers on a schedule.

**Team size:** 5-100+. The ceremony is justified for larger teams with release managers.

**Pros:** Clear release process, parallel release prep and feature development, explicit hotfix path.
**Cons:** Complex, many long-lived branches, merge conflicts between `develop` and `main`, overkill for web apps with continuous deployment.

---

### Ship/Show/Ask

A trust-based model where developers choose the review level for each change.

```
main  ──●──●──●──●──●──●──●──●──●──
         │     ↑     │        ↑
         │    Ship    │       Show
         │  (direct)  │    (merge, then
         │            │     review async)
         └──●──●──●──┘
              Ask
          (PR + review
           before merge)
```

**How it works:**
- **Ship:** Commit directly to `main`. For trivial changes: typo fixes, config tweaks, dependency bumps. No review needed.
- **Show:** Open a PR, merge immediately, then request async review. For confident changes that benefit from visibility: refactors, small features. Review happens after merge.
- **Ask:** Open a PR and wait for review before merging. For risky, complex, or unfamiliar changes: new architecture, security-sensitive code, changes to shared APIs.

**When to use:** High-trust teams where developers have good judgment about what needs review. Common in senior-heavy teams and some open-source projects.

**Team size:** 3-15. Requires team members who can accurately assess risk. New team members default to Ask.

**Pros:** Fast for low-risk changes, reduces review bottlenecks, builds trust.
**Cons:** Requires good judgment, mistakes ship to `main` without review, not suitable for regulated environments.

---

### Forking Workflow (Open Source)

External contributors fork the repo, work in their fork, and submit PRs back to the upstream repository.

```
upstream/main  ──●──────────●──────────●──
                              ↑
                              │  PR
                              │
fork/main      ──●──●──●──●──●
                  \        /
fork/feature       ●──●──●
```

**How it works:**
1. Contributor forks the repository on GitHub/GitLab
2. Clones their fork locally
3. Creates a feature branch in their fork
4. Pushes to their fork and opens a PR against upstream
5. Maintainers review and merge (or request changes)
6. Contributor syncs their fork: `git fetch upstream && git rebase upstream/main`

**When to use:** Open-source projects accepting external contributions. The forking model is the only option when contributors don't have write access.

**Team size:** Unlimited. Core maintainers use GitHub Flow on the upstream repo; external contributors use the forking workflow.

**Pros:** No write access needed for contributors, isolates experimental work, natural trust boundary.
**Cons:** Contributors must keep forks synced, more complex for first-time contributors, CI must run on fork PRs.

**Combine with GitHub Flow:** Maintainers use GitHub Flow on the upstream repo. External contributors fork and PR.

---

### Release Branching

A lightweight alternative to GitFlow. Development happens on `main`, release branches are created for stabilization and long-term support.

```
main           ──●──●──●──●──●──●──●──●──●──
                  \              \
release/1.x        ●──●──●       |
                   (v1.0) (v1.1)  |
                                   \
release/2.x                         ●──●
                                   (v2.0)
```

**How it works:**
- All development happens on `main` (using GitHub Flow)
- When ready to release, create `release/X.x` from `main`
- Bug fixes for the release go to the release branch (cherry-pick or backport)
- Tags mark specific versions: `v1.0.0`, `v1.0.1`, `v1.1.0`
- Multiple release branches can exist for long-term support

**When to use:** Projects that maintain multiple supported versions simultaneously: databases, language runtimes, frameworks, enterprise software.

**Team size:** 5-100+. Requires discipline around backporting fixes.

**Pros:** Simpler than GitFlow, supports multiple active versions, clear release history.
**Cons:** Cherry-pick/backport overhead, release branches can diverge from `main`.

---

### Workflow Selection Guide

| Scenario | Recommended Workflow |
|---|---|
| Solo project or side project | Trunk-based (just commit to `main`) |
| Small team, web app, continuous deployment | GitHub Flow |
| Open-source library with SemVer | GitHub Flow + Release Branching |
| Open-source with external contributors | Forking + GitHub Flow upstream |
| Mobile app with App Store releases | GitFlow or Release Branching |
| Desktop app with versioned installers | GitFlow |
| Enterprise with release cycles | Release Branching or GitFlow |
| Senior team wanting minimal process | Ship/Show/Ask |
| Multiple supported versions (LTS) | Release Branching |

---

## 2. Bots and Automation

Complete GitHub Actions workflow configurations for repository automation. Place these in `.github/workflows/` or configure as GitHub Apps where noted.

### Stale Bot (actions/stale)

Automatically labels and closes issues and PRs that have had no activity. Prevents the issue tracker from becoming a graveyard of abandoned requests.

```yaml
# .github/workflows/stale.yml
name: Close stale issues and PRs

on:
  schedule:
    - cron: '30 1 * * *'  # Run daily at 01:30 UTC

permissions:
  issues: write
  pull-requests: write

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          # Issue configuration
          days-before-issue-stale: 60
          days-before-issue-close: 14
          stale-issue-label: 'status: stale'
          stale-issue-message: >
            This issue has been automatically marked as stale because it has not had
            recent activity. It will be closed in 14 days if no further activity occurs.
            If this issue is still relevant, please leave a comment or remove the stale label.
          close-issue-message: >
            This issue was closed because it has been stale for 14 days with no activity.
            Feel free to reopen if this is still relevant.
          exempt-issue-labels: 'priority: critical,priority: high,status: confirmed,status: in-progress'

          # PR configuration
          days-before-pr-stale: 30
          days-before-pr-close: 7
          stale-pr-label: 'status: stale'
          stale-pr-message: >
            This pull request has been automatically marked as stale because it has not had
            recent activity. It will be closed in 7 days if no further activity occurs.
          close-pr-message: >
            This PR was closed because it has been stale for 7 days with no activity.
            Feel free to reopen when ready to continue.
          exempt-pr-labels: 'status: blocked,status: in-progress'

          # General
          exempt-all-milestones: true
          remove-stale-when-updated: true
          operations-per-run: 100
```

---

### Auto-Labeler (actions/labeler)

Automatically labels PRs based on which files were changed. Reduces manual triage work.

```yaml
# .github/workflows/labeler.yml
name: Label PRs by file path

on:
  pull_request_target:
    types: [opened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          repo-token: '${{ secrets.GITHUB_TOKEN }}'
          sync-labels: true
```

```yaml
# .github/labeler.yml
# Label definitions — map file globs to labels

area: frontend:
  - changed-files:
    - any-glob-to-any-file:
      - 'src/components/**'
      - 'src/pages/**'
      - 'src/styles/**'
      - '**/*.css'
      - '**/*.scss'

area: backend:
  - changed-files:
    - any-glob-to-any-file:
      - 'src/api/**'
      - 'src/services/**'
      - 'src/models/**'
      - 'src/middleware/**'

area: api:
  - changed-files:
    - any-glob-to-any-file:
      - 'src/routes/**'
      - 'src/controllers/**'
      - 'openapi.yml'
      - 'swagger.*'

area: docs:
  - changed-files:
    - any-glob-to-any-file:
      - 'docs/**'
      - '**/*.md'
      - 'README.md'
      - 'CONTRIBUTING.md'

area: ci:
  - changed-files:
    - any-glob-to-any-file:
      - '.github/**'
      - '.gitlab-ci.yml'
      - 'Dockerfile'
      - 'docker-compose*.yml'

area: infra:
  - changed-files:
    - any-glob-to-any-file:
      - 'terraform/**'
      - 'pulumi/**'
      - 'k8s/**'
      - 'helm/**'
      - 'infrastructure/**'

type: dependencies:
  - changed-files:
    - any-glob-to-any-file:
      - 'package.json'
      - 'package-lock.json'
      - 'yarn.lock'
      - 'pnpm-lock.yaml'
      - 'pyproject.toml'
      - 'poetry.lock'
      - 'requirements*.txt'
      - 'go.mod'
      - 'go.sum'
      - 'Cargo.toml'
      - 'Cargo.lock'
      - 'Gemfile'
      - 'Gemfile.lock'

type: test:
  - changed-files:
    - any-glob-to-any-file:
      - '**/*.test.*'
      - '**/*.spec.*'
      - '**/*_test.*'
      - 'tests/**'
      - 'test/**'
      - '__tests__/**'
      - 'spec/**'
```

---

### PR Size Labeler

Labels PRs by lines changed so reviewers can estimate review effort at a glance.

```yaml
# .github/workflows/pr-size.yml
name: Label PR size

on:
  pull_request_target:
    types: [opened, synchronize]

permissions:
  pull-requests: write

jobs:
  size-label:
    runs-on: ubuntu-latest
    steps:
      - uses: codelytv/pr-size-labeler@v1
        with:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          xs_label: 'size: XS'
          xs_max_size: 10
          s_label: 'size: S'
          s_max_size: 50
          m_label: 'size: M'
          m_max_size: 200
          l_label: 'size: L'
          l_max_size: 500
          xl_label: 'size: XL'
          fail_if_xl: false
          message_if_xl: >
            This PR is very large. Consider breaking it into smaller PRs for easier review.
          files_to_ignore: |
            package-lock.json
            pnpm-lock.yaml
            yarn.lock
            go.sum
            Cargo.lock
            poetry.lock
            *.snap
            **/*.generated.*
```

**Size thresholds:**

| Label | Lines Changed | Review Expectation |
|---|---|---|
| `size: XS` | 0-10 | Glance review, merge quickly |
| `size: S` | 11-50 | Quick review, 5-10 minutes |
| `size: M` | 51-200 | Standard review, 15-30 minutes |
| `size: L` | 201-500 | Deep review, 30-60 minutes |
| `size: XL` | 501+ | Should probably be split |

---

### Welcome Bot

Greets first-time contributors when they open their first issue or PR. Builds community and reduces confusion.

```yaml
# .github/workflows/welcome.yml
name: Welcome first-time contributors

on:
  issues:
    types: [opened]
  pull_request_target:
    types: [opened]

permissions:
  issues: write
  pull-requests: write

jobs:
  welcome:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/first-interaction@v1
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          issue-message: |
            Thanks for opening your first issue! We appreciate you taking the time to report this.

            A maintainer will review this soon. In the meantime, please make sure you've:
            - [ ] Searched existing issues to avoid duplicates
            - [ ] Included steps to reproduce (if reporting a bug)
            - [ ] Specified the version you're using

            If you're interested in contributing a fix, check out our [Contributing Guide](CONTRIBUTING.md).
          pr-message: |
            Thanks for your first pull request! We're excited to review your contribution.

            A maintainer will review this soon. While you wait, please make sure:
            - [ ] Tests pass (`npm test` / `pytest` / equivalent)
            - [ ] The PR description explains what changed and why
            - [ ] You've read our [Contributing Guide](CONTRIBUTING.md)

            We aim to review PRs within 48 hours. Thanks for your patience!
```

---

### Semantic PR Title Check

Enforces Conventional Commits format in PR titles. This matters because squash merges use the PR title as the commit message, so the PR title becomes the permanent commit history.

```yaml
# .github/workflows/pr-title.yml
name: Validate PR title

on:
  pull_request_target:
    types: [opened, edited, synchronize]

permissions:
  pull-requests: read

jobs:
  lint-pr-title:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          # Allowed types (Conventional Commits)
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            build
            ci
            chore
            revert
          # Require a scope in parentheses (optional — set to true if you want)
          requireScope: false
          # Allowed scopes (leave empty to allow any scope)
          scopes: |
            api
            auth
            core
            db
            deps
            ui
          # Disallow ALL CAPS titles
          subjectPattern: ^(?![A-Z]).+$
          subjectPatternError: >
            The PR title "{subject}" must not start with an uppercase letter.
            Use lowercase: "feat: add search" not "feat: Add search".
          # Require the title to be at least 10 characters
          headerPattern: ^.{10,}$
          headerPatternError: >
            The PR title must be at least 10 characters long.
          # Validate the entire header (type + scope + description)
          validateSingleCommit: false
          wip: true
```

**Valid titles:**
```
feat: add user search functionality
fix(auth): resolve token refresh loop
docs: update API reference for v2 endpoints
chore(deps): bump vitest to v3.1
refactor(core): extract validation into shared module
```

**Invalid titles:**
```
Add search              # Missing type prefix
feat: Add search        # Uppercase subject
fix: bug                # Too short
FEAT: add search        # Uppercase type
```

---

### AllContributors Bot

Recognizes all types of contributions (code, docs, design, ideas, bug reports, etc.), not just code commits. Generates a contributors table in the README.

**Setup:** Install the [AllContributors GitHub App](https://allcontributors.org/) or use the CLI.

```json
// .all-contributorsrc
{
  "projectName": "my-project",
  "projectOwner": "my-org",
  "repoType": "github",
  "repoHost": "https://github.com",
  "files": ["README.md"],
  "imageSize": 80,
  "commit": true,
  "commitConvention": "angular",
  "contributorsPerLine": 7,
  "skipCi": true,
  "contributors": []
}
```

**Usage:** Comment on an issue or PR:
```
@all-contributors please add @username for code, docs
```

**Contribution types:** `code`, `doc`, `design`, `ideas`, `bug`, `test`, `review`, `maintenance`, `infra`, `translation`, `question`, `tutorial`, `example`, `financial`, `tool`, `platform`, `projectManagement`, `mentoring`, `content`, `security`, `a11y`, `data`, `research`, `audio`, `video`, `userTesting`

---

### Release Drafter

Automatically drafts release notes from merged PR labels. When you cut a release, the notes are already written.

```yaml
# .github/workflows/release-drafter.yml
name: Draft release notes

on:
  push:
    branches: [main]
  pull_request_target:
    types: [opened, reopened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  update-release-draft:
    runs-on: ubuntu-latest
    steps:
      - uses: release-drafter/release-drafter@v6
        with:
          config-name: release-drafter.yml
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

```yaml
# .github/release-drafter.yml
name-template: 'v$RESOLVED_VERSION'
tag-template: 'v$RESOLVED_VERSION'
template: |
  ## What's Changed

  $CHANGES

  **Full Changelog**: https://github.com/$OWNER/$REPOSITORY/compare/$PREVIOUS_TAG...v$RESOLVED_VERSION

categories:
  - title: 'Breaking Changes'
    labels:
      - 'type: breaking'
    collapse-after: 10
  - title: 'New Features'
    labels:
      - 'type: enhancement'
      - 'type: feature'
    collapse-after: 10
  - title: 'Bug Fixes'
    labels:
      - 'type: bug'
    collapse-after: 10
  - title: 'Performance'
    labels:
      - 'type: performance'
    collapse-after: 10
  - title: 'Documentation'
    labels:
      - 'type: documentation'
    collapse-after: 10
  - title: 'Dependencies'
    labels:
      - 'type: dependencies'
    collapse-after: 5
  - title: 'Other Changes'
    labels:
      - '*'
    collapse-after: 5

change-template: '- $TITLE @$AUTHOR (#$NUMBER)'
change-title-escapes: '\<*_&'

exclude-labels:
  - 'skip-changelog'

version-resolver:
  major:
    labels:
      - 'type: breaking'
  minor:
    labels:
      - 'type: enhancement'
      - 'type: feature'
  patch:
    labels:
      - 'type: bug'
      - 'type: documentation'
      - 'type: dependencies'
      - 'type: performance'
  default: patch

autolabeler:
  - label: 'type: documentation'
    files:
      - '*.md'
      - 'docs/**'
    branch:
      - '/docs\/.+/'
  - label: 'type: bug'
    branch:
      - '/fix\/.+/'
      - '/hotfix\/.+/'
    title:
      - '/^fix/i'
  - label: 'type: enhancement'
    branch:
      - '/feature\/.+/'
      - '/feat\/.+/'
    title:
      - '/^feat/i'
  - label: 'type: dependencies'
    files:
      - 'package.json'
      - 'package-lock.json'
      - 'yarn.lock'
      - 'pnpm-lock.yaml'
      - 'go.mod'
      - 'go.sum'
      - 'Cargo.toml'
      - 'Cargo.lock'
      - 'pyproject.toml'
      - 'poetry.lock'
      - 'requirements*.txt'
```

---

### Lock Threads

Locks old closed issues and PRs to prevent necroposting. Old threads attract "me too" comments and spam.

```yaml
# .github/workflows/lock-threads.yml
name: Lock old threads

on:
  schedule:
    - cron: '0 3 * * 1'  # Run weekly on Monday at 03:00 UTC

permissions:
  issues: write
  pull-requests: write

jobs:
  lock:
    runs-on: ubuntu-latest
    steps:
      - uses: dessant/lock-threads@v5
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

          # Issues
          issue-inactive-days: 365
          issue-lock-reason: 'resolved'
          issue-comment: >
            This issue has been automatically locked since there has not been
            any recent activity after it was closed. Please open a new issue
            if the problem persists or you have a related question.

          # Pull requests
          pr-inactive-days: 365
          pr-lock-reason: 'resolved'
          pr-comment: >
            This pull request has been automatically locked since there has not been
            any recent activity after it was closed. Please open a new issue
            if you have a related question.

          # Exemptions
          exclude-any-issue-labels: 'status: keep-open'
          exclude-any-pr-labels: 'status: keep-open'
```

---

### Auto-Assign Reviewers

Automatically assign reviewers to PRs using CODEOWNERS and round-robin patterns.

#### CODEOWNERS

```
# .github/CODEOWNERS
# Each line is a file pattern followed by one or more owners.
# Last matching pattern takes precedence.

# Default owners for everything
*                           @myorg/core-team

# Frontend
/src/components/            @myorg/frontend-team
/src/pages/                 @myorg/frontend-team
/src/styles/                @myorg/frontend-team
*.css                       @myorg/frontend-team
*.scss                      @myorg/frontend-team

# Backend
/src/api/                   @myorg/backend-team
/src/services/              @myorg/backend-team
/src/models/                @myorg/backend-team
/src/middleware/             @myorg/backend-team

# Infrastructure
/terraform/                 @myorg/infra-team
/k8s/                       @myorg/infra-team
Dockerfile                  @myorg/infra-team
docker-compose*.yml         @myorg/infra-team

# CI/CD
/.github/workflows/         @myorg/devops-team
/.github/actions/           @myorg/devops-team

# Documentation
/docs/                      @myorg/docs-team
*.md                        @myorg/docs-team

# Security-sensitive files — require security team review
/src/auth/                  @myorg/security-team
/src/crypto/                @myorg/security-team
SECURITY.md                 @myorg/security-team

# Config files — require senior review
package.json                @myorg/core-team
tsconfig.json               @myorg/core-team
pyproject.toml              @myorg/core-team
```

#### Round-Robin Auto-Assignment

```yaml
# .github/workflows/auto-assign.yml
name: Auto-assign reviewers

on:
  pull_request_target:
    types: [opened, ready_for_review]

permissions:
  pull-requests: write

jobs:
  assign:
    runs-on: ubuntu-latest
    if: github.event.pull_request.draft == false
    steps:
      - uses: actions/auto-assign-action@v1.2.6
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          configuration-path: '.github/auto-assign.yml'
```

```yaml
# .github/auto-assign.yml
addReviewers: true
addAssignees: author

# Reviewers
numberOfReviewers: 2
reviewers:
  - reviewer-1
  - reviewer-2
  - reviewer-3
  - reviewer-4

# Round-robin (each reviewer gets assigned in turn)
# Alternatives: 'random' for random selection
reviewerSelectionMethod: round-robin

# Skip reviewers who are the PR author
skipIfAlreadyAssigned: true

# Don't assign on draft PRs (handled by the `if` condition above)
skipDraft: true

# Assign specific teams for specific paths (optional)
# useReviewGroups: true
# reviewGroups:
#   frontend:
#     - frontend-dev-1
#     - frontend-dev-2
#   backend:
#     - backend-dev-1
#     - backend-dev-2
```

**Repository settings required:** Enable "Require pull request reviews before merging" in branch protection and set CODEOWNERS as a required check if using code ownership.

---

## 3. Issue and PR Label Taxonomy

A complete label system. Every label has a name, hex color, and description. Apply this system to any repository for consistent triage and tracking.

### Type Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `type: bug` | Red | `#d73a4a` | Something is broken |
| `type: enhancement` | Teal | `#a2eeef` | New feature or improvement |
| `type: documentation` | Blue | `#0075ca` | Documentation changes only |
| `type: question` | Purple | `#d876e3` | Needs clarification or discussion |
| `type: feature` | Teal | `#a2eeef` | Alias for enhancement (optional) |
| `type: performance` | Yellow-green | `#7bea4e` | Performance improvement |
| `type: breaking` | Dark red | `#b60205` | Breaking change |
| `type: dependencies` | Blue-gray | `#0366d6` | Dependency updates |
| `type: test` | Orange | `#f9d0c4` | Test additions or fixes |

### Priority Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `priority: critical` | Dark red | `#b60205` | Must fix immediately — system down or data loss |
| `priority: high` | Red-orange | `#d93f0b` | Fix in current sprint/cycle |
| `priority: medium` | Yellow | `#fbca04` | Fix soon but not urgent |
| `priority: low` | Green | `#0e8a16` | Nice to have, fix when convenient |

### Status Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `status: triage` | Light gray | `#ededed` | Needs review and categorization |
| `status: confirmed` | Light blue | `#bfd4f2` | Confirmed and accepted |
| `status: in-progress` | Blue | `#0052cc` | Actively being worked on |
| `status: blocked` | Dark red | `#b60205` | Blocked by another issue or external factor |
| `status: wontfix` | White | `#ffffff` | Will not be addressed (with border) |
| `status: duplicate` | Light gray | `#cfd3d7` | Duplicate of another issue |
| `status: stale` | Pale yellow | `#fef2c0` | No recent activity |
| `status: keep-open` | Green | `#0e8a16` | Exempt from stale bot |

### Area Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `area: frontend` | Purple | `#7057ff` | Frontend/UI changes |
| `area: backend` | Dark blue | `#1d76db` | Backend/server changes |
| `area: api` | Blue | `#0075ca` | API changes |
| `area: docs` | Light green | `#0e8a16` | Documentation area |
| `area: ci` | Orange | `#e4e669` | CI/CD configuration |
| `area: infra` | Gray-blue | `#5319e7` | Infrastructure changes |

### Effort Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `effort: small` | Light green | `#c2e0c6` | Less than 2 hours |
| `effort: medium` | Yellow | `#fef2c0` | Half a day to 2 days |
| `effort: large` | Light red | `#f9d0c4` | More than 2 days |

### Size Labels (PRs)

| Label | Color | Hex | Description |
|---|---|---|---|
| `size: XS` | Green | `#3cbf00` | 0-10 lines changed |
| `size: S` | Light green | `#5d9801` | 11-50 lines changed |
| `size: M` | Yellow | `#7f7203` | 51-200 lines changed |
| `size: L` | Orange | `#a14c05` | 201-500 lines changed |
| `size: XL` | Red | `#c32607` | 500+ lines changed |

### Community Labels

| Label | Color | Hex | Description |
|---|---|---|---|
| `good first issue` | Purple | `#7057ff` | Good for newcomers (GitHub surfaces these) |
| `help wanted` | Green | `#008672` | Contributions welcome (GitHub surfaces these) |

**Note:** `good first issue` and `help wanted` are special labels that GitHub recognizes and surfaces in the "Contribute" tab and search filters. Use these exact names.

### Label Setup Script

Run this with the GitHub CLI to create all labels at once. Delete default labels first if desired.

```bash
#!/usr/bin/env bash
# setup-labels.sh — Create a complete label taxonomy for a GitHub repository.
# Usage: ./setup-labels.sh owner/repo

set -euo pipefail

REPO="${1:?Usage: ./setup-labels.sh owner/repo}"

echo "Setting up labels for ${REPO}..."

# Optional: delete default GitHub labels first
# gh label delete "bug" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "documentation" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "duplicate" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "enhancement" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "good first issue" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "help wanted" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "invalid" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "question" --repo "$REPO" --yes 2>/dev/null || true
# gh label delete "wontfix" --repo "$REPO" --yes 2>/dev/null || true

# Type labels
gh label create "type: bug"           --color "d73a4a" --description "Something is broken" --repo "$REPO" --force
gh label create "type: enhancement"   --color "a2eeef" --description "New feature or improvement" --repo "$REPO" --force
gh label create "type: documentation" --color "0075ca" --description "Documentation changes only" --repo "$REPO" --force
gh label create "type: question"      --color "d876e3" --description "Needs clarification or discussion" --repo "$REPO" --force
gh label create "type: performance"   --color "7bea4e" --description "Performance improvement" --repo "$REPO" --force
gh label create "type: breaking"      --color "b60205" --description "Breaking change" --repo "$REPO" --force
gh label create "type: dependencies"  --color "0366d6" --description "Dependency updates" --repo "$REPO" --force
gh label create "type: test"          --color "f9d0c4" --description "Test additions or fixes" --repo "$REPO" --force

# Priority labels
gh label create "priority: critical"  --color "b60205" --description "Must fix immediately" --repo "$REPO" --force
gh label create "priority: high"      --color "d93f0b" --description "Fix in current sprint" --repo "$REPO" --force
gh label create "priority: medium"    --color "fbca04" --description "Fix soon but not urgent" --repo "$REPO" --force
gh label create "priority: low"       --color "0e8a16" --description "Nice to have" --repo "$REPO" --force

# Status labels
gh label create "status: triage"      --color "ededed" --description "Needs review and categorization" --repo "$REPO" --force
gh label create "status: confirmed"   --color "bfd4f2" --description "Confirmed and accepted" --repo "$REPO" --force
gh label create "status: in-progress" --color "0052cc" --description "Actively being worked on" --repo "$REPO" --force
gh label create "status: blocked"     --color "b60205" --description "Blocked by another issue or dependency" --repo "$REPO" --force
gh label create "status: wontfix"     --color "ffffff" --description "Will not be addressed" --repo "$REPO" --force
gh label create "status: duplicate"   --color "cfd3d7" --description "Duplicate of another issue" --repo "$REPO" --force
gh label create "status: stale"       --color "fef2c0" --description "No recent activity" --repo "$REPO" --force
gh label create "status: keep-open"   --color "0e8a16" --description "Exempt from stale bot" --repo "$REPO" --force

# Area labels
gh label create "area: frontend"      --color "7057ff" --description "Frontend/UI changes" --repo "$REPO" --force
gh label create "area: backend"       --color "1d76db" --description "Backend/server changes" --repo "$REPO" --force
gh label create "area: api"           --color "0075ca" --description "API changes" --repo "$REPO" --force
gh label create "area: docs"          --color "0e8a16" --description "Documentation area" --repo "$REPO" --force
gh label create "area: ci"            --color "e4e669" --description "CI/CD configuration" --repo "$REPO" --force
gh label create "area: infra"         --color "5319e7" --description "Infrastructure changes" --repo "$REPO" --force

# Effort labels
gh label create "effort: small"       --color "c2e0c6" --description "Less than 2 hours" --repo "$REPO" --force
gh label create "effort: medium"      --color "fef2c0" --description "Half a day to 2 days" --repo "$REPO" --force
gh label create "effort: large"       --color "f9d0c4" --description "More than 2 days" --repo "$REPO" --force

# Size labels (for PRs)
gh label create "size: XS"            --color "3cbf00" --description "0-10 lines changed" --repo "$REPO" --force
gh label create "size: S"             --color "5d9801" --description "11-50 lines changed" --repo "$REPO" --force
gh label create "size: M"             --color "7f7203" --description "51-200 lines changed" --repo "$REPO" --force
gh label create "size: L"             --color "a14c05" --description "201-500 lines changed" --repo "$REPO" --force
gh label create "size: XL"            --color "c32607" --description "500+ lines changed" --repo "$REPO" --force

# Community labels (GitHub special labels — use exact names)
gh label create "good first issue"    --color "7057ff" --description "Good for newcomers" --repo "$REPO" --force
gh label create "help wanted"         --color "008672" --description "Contributions welcome" --repo "$REPO" --force

echo "Done. Labels created for ${REPO}."
```

---

## 4. Merge Strategies

Three strategies for merging PRs. Pick one as the project default and configure it in repository settings.

### Squash Merge (Recommended Default)

All commits in the PR become a single commit on `main`. The PR title becomes the commit message.

```
Feature branch:     ●──●──●──●  (4 messy commits: "wip", "fix", "oops", "done")
                          ↓ squash merge
main:               ──●──●──    (1 clean commit: "feat: add user search")
```

**When to use:** Most projects. Web apps, libraries, CLIs. Any project using GitHub Flow.

**Why it's the default:**
- Clean, linear history on `main`
- Each commit on `main` corresponds to one PR and one feature/fix
- Developers can make messy WIP commits without polluting `main`
- PR title becomes the commit message (enforce with semantic PR title check)
- Easy to revert: one commit = one feature

**Configure in GitHub:**
- Settings > General > Pull Requests
- Check "Allow squash merging"
- Set "Default commit message" to "Pull request title"
- Optionally uncheck "Allow merge commits" and "Allow rebase merging"

### Merge Commit

Creates a merge commit that preserves the full branch history. The branch's individual commits appear in `main`'s history.

```
Feature branch:     ●──●──●──●
                    \        \
main:               ──●──────M──  (merge commit M, plus 4 individual commits visible)
```

**When to use:**
- Projects where individual commit history matters (large features with meaningful intermediate steps)
- GitFlow workflows where branch history is important
- Projects that enforce clean commits on branches (rebase before merge)

**Why you might want it:**
- Preserves the full development history
- `git bisect` can find the exact commit that introduced a bug
- Merge commits mark feature boundaries clearly

**Why you might not:** Noisy history if developers don't write clean commits. Most web projects don't need per-commit granularity.

### Rebase Merge

Replays the branch's commits on top of `main`, creating a linear history without merge commits.

```
Feature branch:     ●──●──●
                          ↓ rebase
main:               ──●──●'──●'──●'──  (commits replayed, new SHAs)
```

**When to use:**
- Projects that want linear history but also want individual commits preserved
- Open-source projects where contributors craft meaningful commits
- When combined with interactive rebase before merge (`git rebase -i`)

**Why you might want it:** Clean linear history with preserved individual commits. Best of both worlds if developers write good commits.

**Why you might not:** Rewrites commit SHAs (breaks references), requires clean commit history on branches, harder for contributors unfamiliar with rebase.

### Strategy Selection Guide

| Project Type | Recommended Strategy | Reason |
|---|---|---|
| Web app (continuous deploy) | **Squash** | Clean history, PR = commit |
| Library with SemVer | **Squash** | Each release is a set of PRs, not individual commits |
| Open source with careful contributors | **Rebase** | Honor contributor's commit craft |
| Enterprise with release branches | **Merge commit** | Preserve branch history for auditing |
| Monorepo | **Squash** | Reduce noise across many packages |
| Solo project | Doesn't matter | Use whatever you prefer |

### GitHub Repository Settings

```
Settings > General > Pull Requests:

  [x] Allow squash merging
      Default commit message: Pull request title

  [ ] Allow merge commits        ← uncheck for squash-only projects
  [ ] Allow rebase merging       ← uncheck for squash-only projects

  [x] Automatically delete head branches
  [x] Always suggest updating pull request branches
```

---

## 5. Git LFS (Large File Storage)

Git is designed for text files. Binary files (images, videos, ML models, compiled assets) bloat the repository because Git stores the full content of every version. Git LFS replaces large files with text pointers in the repo and stores the actual file content on a separate server.

### When to Use Git LFS

| File Type | Examples | Use LFS? |
|---|---|---|
| Source code | `.js`, `.py`, `.go`, `.rs` | No — Git handles text well |
| Config files | `.json`, `.yaml`, `.toml` | No |
| Documentation | `.md`, `.txt`, `.rst` | No |
| Images | `.png`, `.jpg`, `.gif`, `.svg`, `.ico` | Yes (except `.svg` which is text) |
| Videos | `.mp4`, `.mov`, `.avi`, `.webm` | Yes |
| Audio | `.mp3`, `.wav`, `.ogg` | Yes |
| Fonts | `.woff`, `.woff2`, `.ttf`, `.otf` | Yes |
| Design files | `.psd`, `.sketch`, `.fig`, `.ai` | Yes |
| Compiled binaries | `.exe`, `.dll`, `.so`, `.dylib` | Yes |
| ML models | `.pt`, `.onnx`, `.h5`, `.pkl`, `.safetensors` | Yes (or use DVC) |
| Datasets | `.csv` (large), `.parquet`, `.arrow` | Yes (or use DVC) |
| Archives | `.zip`, `.tar.gz`, `.7z` | Yes |
| PDFs | `.pdf` | Yes (if many or large) |
| Office docs | `.docx`, `.xlsx`, `.pptx` | Yes |

### .gitattributes Configuration for LFS

```gitattributes
# .gitattributes — Git LFS tracking patterns

# Images
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.ico filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.bmp filter=lfs diff=lfs merge=lfs -text
*.tiff filter=lfs diff=lfs merge=lfs -text

# Videos
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.avi filter=lfs diff=lfs merge=lfs -text
*.webm filter=lfs diff=lfs merge=lfs -text

# Audio
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text

# Fonts
*.woff filter=lfs diff=lfs merge=lfs -text
*.woff2 filter=lfs diff=lfs merge=lfs -text
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text

# Design files
*.psd filter=lfs diff=lfs merge=lfs -text
*.sketch filter=lfs diff=lfs merge=lfs -text
*.ai filter=lfs diff=lfs merge=lfs -text
*.fig filter=lfs diff=lfs merge=lfs -text

# Compiled / binary
*.exe filter=lfs diff=lfs merge=lfs -text
*.dll filter=lfs diff=lfs merge=lfs -text
*.so filter=lfs diff=lfs merge=lfs -text
*.dylib filter=lfs diff=lfs merge=lfs -text

# ML models
*.pt filter=lfs diff=lfs merge=lfs -text
*.pth filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text
*.pkl filter=lfs diff=lfs merge=lfs -text
*.safetensors filter=lfs diff=lfs merge=lfs -text

# Archives
*.zip filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.7z filter=lfs diff=lfs merge=lfs -text
*.rar filter=lfs diff=lfs merge=lfs -text

# Documents
*.pdf filter=lfs diff=lfs merge=lfs -text
*.docx filter=lfs diff=lfs merge=lfs -text
*.xlsx filter=lfs diff=lfs merge=lfs -text
*.pptx filter=lfs diff=lfs merge=lfs -text
```

### GitHub LFS Pricing

Every GitHub repository includes:
- **1 GB** of free LFS storage
- **1 GB** of free LFS bandwidth per month

Data packs (purchased per repository or organization):
- **$5/month** per data pack: 50 GB storage + 50 GB bandwidth
- Storage is cumulative (total across all LFS-tracked files across all history)
- Bandwidth resets monthly

**Cost management tips:**
- Use `.gitattributes` to track only the file types you actually need
- Run `git lfs prune` to remove old local LFS objects
- Consider alternatives for very large files (see DVC below)
- GitHub Enterprise has configurable LFS limits

### Alternatives to Git LFS

#### DVC (Data Version Control) — for ML and Data Projects

DVC is purpose-built for versioning datasets and ML models. It uses Git for metadata and stores large files on cloud storage (S3, GCS, Azure Blob).

**When to use DVC over LFS:**
- Datasets larger than a few GB
- ML model files that change frequently
- Projects needing cloud-native storage (S3, GCS)
- Data pipelines with reproducibility requirements
- Budget sensitivity (cloud storage is cheaper than GitHub LFS at scale)

**When to stick with LFS:**
- Game assets, design files, media
- Small to medium binary files (< 1 GB total)
- Teams already on GitHub that want zero additional infrastructure
- Projects where every contributor needs the files locally

```
# Quick DVC setup
pip install dvc[s3]           # or [gs], [azure]
dvc init
dvc remote add -d storage s3://my-bucket/dvc-store
dvc add data/training-set.parquet
git add data/training-set.parquet.dvc data/.gitignore
git commit -m "chore: track training data with DVC"
dvc push
```

---

## 6. Dependency Management

### Lock File Commit Strategy

| Project Type | Commit Lock File? | Rationale |
|---|---|---|
| **Application** (web app, API, CLI) | **Yes, always** | Guarantees deterministic builds. Every deploy uses the exact same versions. |
| **Library** (npm package, PyPI package) | **Debated — lean toward no** | The consumer's lock file determines final versions. Committing a library lock file tests against pinned versions but may mask compatibility issues. |
| **Monorepo** | **Yes** | Contains applications and shared packages that need reproducible installs. |
| **Docker image** | **Yes** | The lock file ensures the image build is reproducible. |

**The opinion:** Commit lock files for applications. For libraries, the npm/yarn/pnpm ecosystem convention is to commit `package-lock.json` (npm themselves recommend it), but some library authors exclude it so CI tests against the range the consumer will get. If you commit it for a library, also run CI with `--no-frozen-lockfile` occasionally to catch range issues.

**Lock file names by ecosystem:**

| Ecosystem | Lock File | Commit for Apps |
|---|---|---|
| npm | `package-lock.json` | Yes |
| yarn | `yarn.lock` | Yes |
| pnpm | `pnpm-lock.yaml` | Yes |
| Python (pip) | `requirements.txt` (frozen) | Yes |
| Python (Poetry) | `poetry.lock` | Yes |
| Python (uv) | `uv.lock` | Yes |
| Go | `go.sum` | Yes (always) |
| Rust | `Cargo.lock` | Yes for binaries, debated for libraries |
| Ruby | `Gemfile.lock` | Yes |
| PHP | `composer.lock` | Yes |
| .NET | `packages.lock.json` | Yes (if enabled) |

### Renovate vs Dependabot

Both automatically open PRs to update dependencies. Renovate is more configurable; Dependabot is simpler and built into GitHub.

| Feature | Dependabot | Renovate |
|---|---|---|
| **Setup** | `dependabot.yml` in `.github/` | `renovate.json` in repo root or GitHub App |
| **Runs on** | GitHub only | GitHub, GitLab, Bitbucket, Azure DevOps |
| **Grouping** | Basic grouping by pattern | Advanced grouping, package rules, regex |
| **Auto-merge** | Via GitHub auto-merge | Built-in auto-merge with configurable policies |
| **Monorepo support** | Limited | Strong (detects workspaces, updates atomically) |
| **Schedule** | Daily, weekly, monthly | Any cron expression, timezone-aware |
| **Custom managers** | No | Yes (regex-based custom managers for any file) |
| **Replacement PRs** | No | Yes (deprecated package replacement suggestions) |
| **Dashboard issue** | No | Yes (Dependency Dashboard tracking all updates) |
| **Lock file maintenance** | Manual | Built-in `lockFileMaintenance` PRs |
| **Preset sharing** | No | Yes (shareable config presets across repos) |
| **Noise level** | Can be noisy | Highly configurable noise reduction |
| **Pricing** | Free | Free (open source, Mend-hosted app is free) |
| **Recommendation** | Small projects, GitHub-only | Teams, monorepos, cross-platform, advanced needs |

#### Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2

updates:
  # JavaScript/TypeScript dependencies
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: '09:00'
      timezone: America/New_York
    open-pull-requests-limit: 10
    reviewers:
      - myorg/core-team
    labels:
      - 'type: dependencies'
    groups:
      # Group minor and patch updates together
      minor-and-patch:
        update-types:
          - minor
          - patch
      # Keep major updates separate (they may have breaking changes)
      # Major updates get individual PRs by default

  # GitHub Actions
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    labels:
      - 'type: dependencies'
      - 'area: ci'
    groups:
      actions:
        patterns:
          - '*'

  # Docker (if applicable)
  - package-ecosystem: docker
    directory: /
    schedule:
      interval: weekly
    labels:
      - 'type: dependencies'
      - 'area: infra'

  # Python (if applicable)
  # - package-ecosystem: pip
  #   directory: /
  #   schedule:
  #     interval: weekly
  #   labels:
  #     - 'type: dependencies'
```

#### Renovate Configuration

```json5
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":semanticCommits",
    ":preserveSemverRanges",
    "group:recommended",
    "schedule:earlyMondays"
  ],

  // Labels for all Renovate PRs
  "labels": ["type: dependencies"],

  // Limit concurrent PRs
  "prConcurrentLimit": 10,

  // Auto-merge minor and patch updates that pass CI
  "packageRules": [
    {
      "description": "Auto-merge minor and patch updates",
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "automergeType": "pr",
      "automergeStrategy": "squash"
    },
    {
      "description": "Group all non-major dev dependencies",
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "dev dependencies (non-major)",
      "automerge": true
    },
    {
      "description": "Do not auto-merge major updates",
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["type: dependencies", "type: breaking"]
    },
    {
      "description": "Group ESLint-related packages",
      "matchPackagePatterns": ["eslint"],
      "groupName": "eslint"
    },
    {
      "description": "Group testing packages",
      "matchPackagePatterns": ["vitest", "jest", "@testing-library"],
      "groupName": "testing"
    },
    {
      "description": "Group TypeScript packages",
      "matchPackagePatterns": ["typescript", "^@types/"],
      "groupName": "typescript"
    },
    {
      "description": "Auto-merge GitHub Actions minor/patch",
      "matchManagers": ["github-actions"],
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "groupName": "github actions"
    },
    {
      "description": "Widen ranges for peerDependencies",
      "matchDepTypes": ["peerDependencies"],
      "rangeStrategy": "widen"
    }
  ],

  // Lock file maintenance — weekly PR to update all transitive deps
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on monday"]
  },

  // Dependency Dashboard — tracking issue for all pending updates
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "Dependency Dashboard"
}
```

### Auto-Merge Policies

Auto-merging dependency updates reduces maintenance burden. But only do it for updates with passing CI.

**Recommended policy:**

| Update Type | Auto-Merge? | Rationale |
|---|---|---|
| **Patch** (1.2.3 -> 1.2.4) | Yes | Bug fixes only, lowest risk |
| **Minor** (1.2.0 -> 1.3.0) | Yes (with good CI) | New features, backwards-compatible |
| **Major** (1.0.0 -> 2.0.0) | No | Breaking changes, review manually |
| **Dev dependencies patch/minor** | Yes | Don't affect production |
| **Dev dependencies major** | Yes (usually) | Build tools rarely break apps |
| **GitHub Actions minor/patch** | Yes | Low risk, high noise if manual |
| **Security updates** | Yes (all severity) | Fix vulnerabilities fast |

**Requirements for safe auto-merge:**
1. CI must run the full test suite on dependency update PRs
2. Branch protection must require CI to pass before merge
3. Auto-merge must use squash merge for clean history
4. Major updates must always require manual review

**GitHub auto-merge setup:**
1. Enable "Allow auto-merge" in repository settings
2. Configure branch protection to require status checks
3. Dependabot or Renovate marks eligible PRs for auto-merge
4. GitHub merges automatically when all checks pass

---

## 7. Atomic commits — splitting by concern

AI coding agents default to one giant end-of-session commit — a review problem and a security problem. Snyk's 2025 report counts **28.65M secrets leaked to public GitHub**, with AI-assisted commits leaking at ~2× the baseline rate: larger diffs slip past human reviewers (<https://snyk.io/articles/state-of-secrets/>). raine.dev's atomic-commits-for-AI-agents analysis makes the same case from reviewability (<http://raine.dev/blog/atomic-commits-for-ai-agents/>). Atomic commits and pre-commit secret scanning (`references/quality-tooling.md` §8 "Secret scanning (pre-commit)") are complements: smaller diffs let reviewers see what gitleaks might miss.

### The five-step protocol

1. **One concern per commit.** Don't bundle a feature change with drive-by formatting. If the diff description needs the word "and," it's probably two commits.

2. **The message describes intent, not scope.** `feat(auth): add OAuth2 login` beats `update 3 files`. Use Conventional Commits (<https://www.conventionalcommits.org/en/v1.0.0/>) for scope grammar; see `references/quality-tooling.md` §10 "Commit Linting" for enforcement.

3. **Use `git add -p` to stage by hunk** when changes span concerns. Walk each hunk interactively, stage only what belongs in the current commit, leave the rest for the next. Example below.

4. **`git commit --fixup=<sha>` + `git rebase -i --autosquash`** to fix an earlier commit on a PR branch. Don't add a new `fix typo` commit — mark the fixup, squash into its target before pushing.

5. **Pre-push log check.** Run `git log --oneline origin/main..HEAD` before every push. If any message doesn't describe a clear single concern, squash or split it. Anything pushed becomes permanent.

### `git add -p` transcript

```
$ git add -p
diff --git a/src/auth.ts b/src/auth.ts
@@ -42,6 +42,10 @@
 +// Feature: password reset token
 +export function generateResetToken() { ... }
(1/3) Stage this hunk [y,n,q,a,d,s,e,?]? y
@@ -58,3 +62,8 @@
 +// Drive-by: unrelated whitespace normalization
(2/3) Stage this hunk [y,n,q,a,d,s,e,?]? s    # split this hunk
(2a/4) Stage this hunk [y,n,q,a,d,s,e,?]? y
(2b/4) Stage this hunk [y,n,q,a,d,s,e,?]? n   # save for separate commit
(3/4) Stage this hunk [y,n,q,a,d,s,e,?]? q    # quit; commit what's staged
```

Prompt-key legend: `y` stage, `n` skip, `s` split hunk into smaller hunks, `q` stop and commit what's staged, `a` stage this and all remaining, `d` skip this and all remaining, `e` edit the hunk manually, `?` help.

### Anti-patterns

- **One giant commit at the end of the session.** AI agents' default behavior, per raine.dev. Reviewers can't audit a 2000-line, ten-file diff — and that's exactly the diff shape in which secrets hide.
- **Bonus changes.** Drive-bys bundled into a feature commit. Reviewers approve the primary change and inherit everything else unreviewed. Split them out.
- **`fix typo`, `WIP`, `oops` commits on a PR branch.** Use `git commit --fixup=<sha>` + `git rebase -i --autosquash` instead. Final history should read as intentional changes, not a debugging session.
- **Squash-everything-at-merge as a substitute for atomic discipline.** Squash-on-merge is a repo-level policy knob, not a license to be careless on the branch. Squashing hides evidence of mixed concerns; it doesn't remove them.

---

## Summary: What to Configure by Project Stage

| Stage | Workflow | Bots | Labels | Merge Strategy | LFS | Deps |
|---|---|---|---|---|---|---|
| **MVP / Solo** | Trunk-based or GitHub Flow | None needed | Basic types only | Squash | If needed | Manual |
| **Team / Growth** | GitHub Flow | Labeler, PR size, PR title check | Full taxonomy | Squash | .gitattributes ready | Dependabot |
| **Open Source** | GitHub Flow + Forking | All bots (stale, welcome, labeler, release drafter, lock threads, AllContributors) | Full taxonomy + community labels | Squash | Configure LFS | Renovate |
| **Enterprise** | GitHub Flow + Release Branching | Labeler, PR size, PR title, auto-assign, release drafter | Full taxonomy + custom area labels | Squash or Merge Commit | LFS + policies | Renovate with auto-merge |
