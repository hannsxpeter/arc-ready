# Bitbucket Platform Reference

Bitbucket Cloud-specific repository configuration: project settings, branch permissions, merge checks, issue tracker, Pipelines 2.0 (for all 12 supported stacks), Pipes, deployment environments, self-hosted runners, and the build status API. Load this reference when the target platform is Bitbucket Cloud (detected by `bitbucket-pipelines.yml` at repo root, a `bitbucket.org` remote, or user statement).

Bitbucket Cloud is Atlassian's Git host. Teams reach for it when they already live inside the Atlassian ecosystem — Jira for issues, Confluence for docs, Trello for planning — and want the tightest possible integration across those surfaces. Pipelines 2.0 is Docker-image-based, YAML-defined, configured from a single `bitbucket-pipelines.yml` file at the repo root, and runs on Atlassian-hosted or self-hosted runners. Deployment environments (`test`, `staging`, `production`) are first-class pipeline features with their own variable scopes, and Pipes — Bitbucket's marketplace of composable Docker steps — fill the role GitHub Actions plays on GitHub.

> **Scope note.** This reference covers **Bitbucket Cloud** (`bitbucket.org`). Bitbucket Server / Data Center is a different product with a different Pipelines engine and is out of scope for this reference.
>
> **Example conventions.** Examples use `acme` as the workspace and `widget-api` as the repository. Substitute your own workspace and repo slug when you paste. UI paths are the current Bitbucket Cloud paths as of the Atlassian docs linked in the Sources section.

## When to use Bitbucket

Reach for Bitbucket Cloud when at least one of these is already true:

- **You already pay for Atlassian.** Jira + Confluence + Bitbucket share one identity, admin surface, and billing line.
- **Jira is the system of record for work.** Smart Commits and branch/PR linking are first-class — more native than any third-party Jira integration on GitHub or GitLab.
- **You want deployment environments as a built-in pipeline feature.** Declare `deployment: production` on a step and Bitbucket tracks the deploy with zero extra config.
- **You need mixed-platform self-hosted runners.** Linux, Windows, and macOS runners are first-class alongside Atlassian-hosted runners, targeted by label from YAML.

Reach for GitHub or GitLab instead when you want the biggest open-source ecosystem, the biggest Actions / CI marketplace, or Pages-style static hosting. Bitbucket does not ship a static-site feature comparable to Pages.

---

## Project settings

Configure these under **Repository settings** (per-repo) or **Workspace settings** (shared across all repos in the workspace). Feature toggles at the workspace level cascade to repos unless overridden.

### Feature toggles

Toggle under **Repository settings → Repository details** and **Repository settings → Features**:

- **Pipelines** — on if the repo runs CI. Enabled per-repo; workspace admins can disable entirely for cost control.
- **Deployments** — on if the repo deploys anywhere. Requires Pipelines.
- **Issue tracker** — on if you want native Bitbucket issues. Off if you use Jira or an external tracker (most teams on Atlassian turn this off and route everything through Jira).
- **Wiki** — on if you want in-repo wiki. Most teams use Confluence instead.
- **Forks** — allow / restrict to workspace / disallow. Public repos typically allow; private repos typically restrict.

### Access levels

Bitbucket uses three per-repo permission levels — **Admin**, **Write**, and **Read**. Grants come from direct users, groups, or workspace-level defaults.

| Level | Can do |
|---|---|
| **Admin** | Everything, including repo settings, branch permissions, deleting the repo |
| **Write** | Push to unprotected branches, open PRs, merge PRs (subject to branch permissions and merge checks) |
| **Read** | Clone, fork, open PRs from forks, comment |

Configure under **Repository settings → User and group access**. Workspace-wide defaults live at **Workspace settings → User groups**; repo-level grants override group defaults.

For PR reviewer enforcement, map these to branch permission rules (see next section) — access level alone does not gate merge. A Write user still cannot merge a protected branch without satisfying the branch's merge checks.

### Visibility

Bitbucket repos are either **Private** (explicit members) or **Public** (world-readable). There is no "Internal" tier like GitLab's — workspace-wide visibility is modeled via private repos plus workspace membership.

---

## Branch permissions

Bitbucket's equivalent of GitHub branch protection rules and GitLab protected branches. Configure under **Repository settings → Branch restrictions**. Unlike GitHub rulesets, branch permissions are **UI- and API-configured only** — there is no file-based representation that round-trips into the repo.

### Mapping GitHub rulesets → Bitbucket branch restrictions

| GitHub ruleset concept | Bitbucket branch restriction |
|---|---|
| Require a pull request before merging | Restriction type: **Prevent changes without a pull request** |
| Require N approving reviews | Merge check: **Minimum number of approvals** |
| Require review from code owners | Use **Default reviewers** — no CODEOWNERS file equivalent (see next section) |
| Dismiss stale approvals on new commits | Merge check: **Reset approvals when new changes are pushed** |
| Require status checks to pass | Merge check: **Minimum successful builds** |
| Require conversation resolution | Merge check: **No failed tasks** / no unresolved tasks |
| Block force pushes | Restriction type: **Prevent rewriting history** |
| Restrict deletions | Restriction type: **Prevent deletion** |
| Restrict pushes (allow list) | Restriction type: **Prevent changes** (plus user/group allow list) |
| Require linear history | Merge strategy: **fast-forward** (see Merge strategies) |

### Example configuration

A typical `main` branch restriction for a small team looks like:

- **Branch match:** `main` (exact name — glob patterns like `release/*` are supported)
- **Prevent changes without a pull request:** on
- **Prevent rewriting history:** on (no force pushes)
- **Prevent deletion:** on
- **Merge checks** (configured on the same restriction):
  - Minimum number of approvals: **1** (or 2 for production-critical repos)
  - Minimum successful builds: **1** (all default pipeline builds must pass)
  - No failed tasks
  - Reset approvals when new changes are pushed

### Creating a restriction via REST API

Bitbucket's REST API can create restrictions programmatically — useful for applying the same policy across a workspace's repos. Authenticate with a workspace access token or app password.

```bash
curl -X POST \
  -u "$BB_USER:$BB_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  "https://api.bitbucket.org/2.0/repositories/acme/widget-api/branch-restrictions" \
  -d '{
    "kind": "require_approvals_to_merge",
    "pattern": "main",
    "value": 1
  }'
```

Each restriction "kind" is a separate API call — apply them one by one:

- `push` (who can push at all)
- `force` (prevent force-push)
- `delete` (prevent deletion)
- `require_approvals_to_merge` (N approvals required)
- `require_default_reviewer_approvals_to_merge` (default reviewers must approve)
- `require_passing_builds_to_merge` (N successful builds required)
- `require_tasks_to_be_completed` (no unresolved tasks)
- `reset_pullrequest_approvals_on_change` (stale approvals dismissed)

See the Sources section for the full Atlassian API reference.

### Difference from GitHub rulesets

GitHub rulesets can be exported, version-controlled, and reimported as JSON. Bitbucket branch permissions are stateful server-side only — the REST API is the backup/replay story. If you need branch permissions checked into the repo itself, that's a gap; teams work around it by scripting the REST calls in a `scripts/apply-branch-permissions.sh` file and running it via Pipelines on workspace setup.

---

## Merge strategies and merge checks

### Supported merge strategies

Bitbucket PR merges support three strategies, configurable per-repo under **Repository settings → Merge strategies**:

| Strategy | Effect | Best for |
|---|---|---|
| **Merge commit** | Creates a merge commit; preserves full branch history | Teams that want audit trail of branches |
| **Squash** | Collapses all PR commits into one commit on the target branch | Teams that want clean linear history (**recommended default**) |
| **Fast-forward** | Merges only if the PR branch is already rebased onto target; no merge commit | Teams enforcing strictly linear history |

**Recommendation: squash.** Parallels this skill's default for GitHub and GitLab. One commit per PR maps cleanly to reviewed units of work and keeps `main`'s history readable. Teams that want preserved branch history use merge-commit; fast-forward is strictest but requires every contributor to rebase before merge. You can allow multiple strategies and let the merger pick, or restrict to exactly one.

### Merge checks

Merge checks are configured per branch restriction (see Branch permissions above), not as a separate branch-protection object. Supported checks:

- **Minimum number of approvals** — N reviewer approvals before merge is allowed
- **Minimum approvals from default reviewers** — N of the configured default reviewers must approve
- **Minimum successful builds** — N pipeline builds must report green on the PR's head commit
- **No failed tasks** — all inline tasks (task checkboxes in PR comments) must be resolved
- **Reset approvals on new commits** — approvals are dismissed when the PR branch is updated

Enabling all five on the `main` branch restriction is the recommended default for production repos.

### No CODEOWNERS — use default reviewers

Bitbucket does **not** have a CODEOWNERS file. The closest analog is **default reviewers**, a workspace- or repo-scoped list of users who are automatically added as reviewers to every PR targeting the repo's main branch.

Configure under **Repository settings → Default reviewers**:

1. Navigate to **Repository settings → Default reviewers**.
2. Click **Add default reviewer** and select users from the workspace.
3. Optionally set the number of required approvals from this list on the branch restriction (`require_default_reviewer_approvals_to_merge` via API).

Limitations compared to CODEOWNERS:

- **No path globs.** Default reviewers apply to every PR in the repo, not to specific directories or file patterns. Document path-based conventions in `CONTRIBUTING.md` and rely on team discipline or a third-party bot.
- **No group assignment.** Individual users only; no teams or groups.
- **Repo-scoped, not path-scoped.** One flat list per repo.

For path-based ownership, use default reviewers as the "everyone who touches this repo" baseline and document module ownership in `CONTRIBUTING.md` or an `OWNERS.md`.

---

## Issue tracker

### Native Bitbucket issues vs Jira

Bitbucket ships a lightweight native issue tracker. It's suitable for:

- **Solo developers and small teams** (under ~5 people) who don't want a separate Jira project
- **Open-source repos on Bitbucket** where external contributors need to file bugs without a Jira account
- **Simple bug and feature lists** without sprints, epics, custom fields, or workflow automation

For anything beyond that — sprint planning, custom workflows, time tracking, cross-project epics, formal ITSM — use **Jira Cloud** and turn the native tracker off. Teams already on Atlassian almost universally do this.

### Jira integration (brief)

When a Bitbucket repo is connected to a Jira Cloud site (configured at the workspace level under **Workspace settings → Jira integration**), these work automatically with zero per-repo setup:

- **Smart Commits** — write `ACME-123 #comment Fixed login bug #time 2h #close` in a commit message and Jira adds the comment, logs the time, and transitions the issue to Done.
- **Issue key auto-linking** — any `ACME-123`-style token in a branch name, commit message, PR title, or PR description becomes a clickable link in both Bitbucket and Jira, and the PR shows up on the Jira issue's "Development" panel.
- **Branch and PR creation from Jira** — Jira issues have a "Create branch" action that opens the Bitbucket branch-creation dialog pre-populated with the issue key.

Deep Jira configuration is out of scope for this reference. See the Sources section for the Atlassian doc.

### Issue templates for native Bitbucket issues

Bitbucket's native issue tracker accepts Markdown bodies (not YAML issue forms like GitHub). Templates are managed under **Repository settings → Issues → Templates** — you paste the Markdown once and it becomes the default body when contributors open a new issue of that type.

Bitbucket issues are lighter-weight than GitHub issue forms, so keep templates short.

**Bug report template:**

```markdown
## Summary

One-line description of the bug.

## Steps to reproduce

1.
2.
3.

## Expected

What should happen.

## Actual

What actually happens.

## Environment

- Version / commit:
- OS:
- Browser / runtime (if applicable):

## Logs / screenshots

Paste any relevant logs or screenshots.
```

**Feature request template:**

```markdown
## Problem

What problem does this solve? Who hits it?

## Proposed solution

Describe the feature. Keep it to one concrete approach — alternatives go in the next section.

## Alternatives considered

- Option A: …
- Option B: …

## Additional context

Links, mockups, related issues.
```

These two templates cover 90% of the native tracker's use. Add a third "Question / support" template only if your repo actually accepts support questions as issues (most don't — point them to a discussion forum or Stack Overflow tag instead).

---

## Bitbucket Pipelines

Bitbucket Pipelines 2.0 is the current generation CI/CD. Configuration lives in **`bitbucket-pipelines.yml` at the repo root** (not in a `.bitbucket/` subdirectory). Pipelines are Docker-image-based: every step declares an `image:` and runs its script inside that container. Default step timeout is 10 minutes (configurable up to 120), default build size is 4 GB / 4 vCPU (configurable up to 8 GB / 8 vCPU via `size: 2x` or `size: 4x`).

Top-level keys: `image:` (default container), `definitions:` (reusable caches / services / anchors), `pipelines:` (triggers: `default`, `branches`, `pull-requests`, `custom`, `tags`).

For per-stack install / lint / test / build command rationale (why `ruff check` over `flake8`, why `cargo clippy -- -D warnings`, etc.), cross-reference `references/ci-cd-workflows.md`. This file documents Bitbucket-specific YAML shape; `ci-cd-workflows.md` documents the commands themselves across all three CI systems.

### Structure overview

Every `bitbucket-pipelines.yml` follows this shape. Copy this skeleton, then fill in stack-specific steps from the sections below.

```yaml
# Default image applied to every step that doesn't declare its own.
image: atlassian/default-image:4

definitions:
  # Reusable caches — declared once, referenced by name from steps.
  caches:
    pnpm: $HOME/.local/share/pnpm/store
  # Reusable service containers (databases, Redis, etc.).
  services:
    postgres:
      image: postgres:16
      variables:
        POSTGRES_DB: test
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test

pipelines:
  # Runs on every push to any branch that has no more specific rule.
  default:
    - step:
        name: Test
        caches:
          - node
        script:
          - npm ci
          - npm test

  # Branch-specific pipelines override `default` for matching branches.
  branches:
    main:
      - step:
          name: Build and deploy staging
          deployment: staging
          script:
            - npm ci
            - npm run build
            - ./scripts/deploy-staging.sh

  # Pull request pipelines run on every PR targeting the repo.
  pull-requests:
    '**':
      - step:
          name: PR checks
          script:
            - npm ci
            - npm run lint
            - npm test

  # Custom pipelines are triggered manually from the Bitbucket UI or API.
  custom:
    deploy-production:
      - step:
          name: Deploy production
          deployment: production
          trigger: manual
          script:
            - ./scripts/deploy-production.sh

  # Tag pipelines run when a matching tag is pushed.
  tags:
    'v*':
      - step:
          name: Release
          script:
            - ./scripts/release.sh
```

The stack-specific blocks below fill in the `script:` and `caches:` parts for each of the 12 supported ecosystems.

### Stack-specific pipelines

Each block below is a complete, paste-ready `bitbucket-pipelines.yml` that covers install → lint → test → build for one stack. Drop it in the repo root, replace the real test / build script paths, commit, and enable Pipelines in **Repository settings → Pipelines → Settings**.

#### JavaScript / TypeScript (Node.js)

Installs with `npm ci` (lockfile-strict), lints with ESLint, runs the test suite, and builds. The `node` cache is a Bitbucket built-in that caches `node_modules`.

```yaml
image: node:20

definitions:
  caches:
    npm: ~/.npm

pipelines:
  default:
    - parallel:
        - step:
            name: Lint
            caches:
              - node
              - npm
            script:
              - npm ci
              - npm run lint
        - step:
            name: Test
            caches:
              - node
              - npm
            script:
              - npm ci
              - npm test -- --ci --coverage
            artifacts:
              - coverage/**
        - step:
            name: Typecheck
            caches:
              - node
              - npm
            script:
              - npm ci
              - npm run typecheck
    - step:
        name: Build
        caches:
          - node
          - npm
        script:
          - npm ci
          - npm run build
        artifacts:
          - dist/**
```

For pnpm or yarn, swap `npm ci` → `pnpm install --frozen-lockfile` or `yarn install --frozen-lockfile`, and add a custom cache (see the Structure overview's `definitions.caches.pnpm` example).

#### Python

Installs with `pip` against `requirements.txt` (or `pip install -e .` for a src layout), lints with Ruff, runs Pytest with coverage. The `pip` cache is a Bitbucket built-in.

```yaml
image: python:3.12

definitions:
  caches:
    pip-venv: .venv

pipelines:
  default:
    - parallel:
        - step:
            name: Lint
            caches:
              - pip
              - pip-venv
            script:
              - python -m venv .venv
              - . .venv/bin/activate
              - pip install -r requirements-dev.txt
              - ruff check .
              - ruff format --check .
        - step:
            name: Typecheck
            caches:
              - pip
              - pip-venv
            script:
              - python -m venv .venv
              - . .venv/bin/activate
              - pip install -r requirements-dev.txt
              - mypy src
        - step:
            name: Test
            caches:
              - pip
              - pip-venv
            script:
              - python -m venv .venv
              - . .venv/bin/activate
              - pip install -r requirements-dev.txt
              - pytest --cov=src --cov-report=xml
            artifacts:
              - coverage.xml
```

For Poetry, swap `pip install -r requirements-dev.txt` → `poetry install --with dev` and cache `~/.cache/pypoetry`. For uv, swap to `uv sync --extra dev` and cache `~/.cache/uv`.

#### Go

Uses the Go module cache and the build cache. `go vet` catches shadowed variables and common mistakes; `staticcheck` is the community lint standard. Tests run with the race detector.

```yaml
image: golang:1.22

definitions:
  caches:
    go-mod: /go/pkg/mod
    go-build: /root/.cache/go-build

pipelines:
  default:
    - parallel:
        - step:
            name: Vet
            caches:
              - go-mod
              - go-build
            script:
              - go mod download
              - go vet ./...
        - step:
            name: Lint
            caches:
              - go-mod
              - go-build
            script:
              - go install honnef.co/go/tools/cmd/staticcheck@2024.1.1
              - staticcheck ./...
        - step:
            name: Test
            caches:
              - go-mod
              - go-build
            script:
              - go mod download
              - go test -race -coverprofile=coverage.out ./...
              - go tool cover -func=coverage.out
            artifacts:
              - coverage.out
    - step:
        name: Build
        caches:
          - go-mod
          - go-build
        script:
          - go build -o bin/widget-api ./cmd/widget-api
        artifacts:
          - bin/**
```

#### Rust

Uses the Cargo registry cache and the target directory cache. Clippy runs with `-D warnings` to fail the build on any lint. `cargo fmt --check` enforces formatting without rewriting files in CI.

```yaml
image: rust:1.77

definitions:
  caches:
    cargo-registry: /usr/local/cargo/registry
    cargo-target: target

pipelines:
  default:
    - parallel:
        - step:
            name: Fmt
            caches:
              - cargo-registry
            script:
              - rustup component add rustfmt
              - cargo fmt --all -- --check
        - step:
            name: Clippy
            caches:
              - cargo-registry
              - cargo-target
            script:
              - rustup component add clippy
              - cargo clippy --all-targets --all-features -- -D warnings
        - step:
            name: Test
            caches:
              - cargo-registry
              - cargo-target
            script:
              - cargo test --all-features --workspace
    - step:
        name: Build release
        caches:
          - cargo-registry
          - cargo-target
        script:
          - cargo build --release --workspace
        artifacts:
          - target/release/widget-api
```

#### Java / Kotlin (JVM)

Two variants below — Maven and Gradle — since the JVM ecosystem is split. Pick one. Both use Eclipse Temurin 21 (current LTS).

**Maven variant:**

```yaml
image: maven:3.9-eclipse-temurin-21

definitions:
  caches:
    maven: ~/.m2/repository

pipelines:
  default:
    - step:
        name: Verify (compile + test + package)
        caches:
          - maven
        script:
          - mvn -B verify
        artifacts:
          - target/*.jar
          - target/site/jacoco/jacoco.xml
```

**Gradle variant:**

```yaml
image: eclipse-temurin:21

definitions:
  caches:
    gradle: ~/.gradle/caches

pipelines:
  default:
    - step:
        name: Build and test
        caches:
          - gradle
        script:
          - ./gradlew --no-daemon check build
        artifacts:
          - build/libs/*.jar
          - build/reports/**
```

Kotlin projects follow the same shape — `./gradlew check build` works whether the build script is `.gradle` or `.gradle.kts`.

#### Ruby

Installs with Bundler, lints with RuboCop, tests with RSpec. The `bundler` cache is a Bitbucket built-in.

```yaml
image: ruby:3.3

definitions:
  caches:
    gems: vendor/bundle

pipelines:
  default:
    - parallel:
        - step:
            name: Lint
            caches:
              - gems
            script:
              - bundle config set --local path 'vendor/bundle'
              - bundle install --jobs 4
              - bundle exec rubocop
        - step:
            name: Test
            caches:
              - gems
            script:
              - bundle config set --local path 'vendor/bundle'
              - bundle install --jobs 4
              - bundle exec rspec --format documentation
            artifacts:
              - coverage/**
```

For Rails, add `RAILS_ENV: test` and a `services:` entry for PostgreSQL (see the Structure overview).

#### C# / .NET

Uses the official Microsoft .NET 8 SDK image. Caches the NuGet package directory.

```yaml
image: mcr.microsoft.com/dotnet/sdk:8.0

definitions:
  caches:
    nuget: ~/.nuget/packages

pipelines:
  default:
    - step:
        name: Restore and build
        caches:
          - nuget
        script:
          - dotnet restore
          - dotnet build --configuration Release --no-restore
          - dotnet format --verify-no-changes
        artifacts:
          - '**/bin/Release/**'
    - step:
        name: Test
        caches:
          - nuget
        script:
          - dotnet test --configuration Release --logger "trx;LogFileName=test-results.trx" --collect:"XPlat Code Coverage"
        artifacts:
          - '**/TestResults/**'
```

#### Swift

The official `swift:5.10` image is Linux-only and builds pure Swift packages via SPM. **iOS / macOS / watchOS builds require self-hosted macOS runners** — see the self-hosted runners section below.

**Linux SPM (library or Linux-only executable):**

```yaml
image: swift:5.10

definitions:
  caches:
    swift-pm: .build

pipelines:
  default:
    - step:
        name: Build
        caches:
          - swift-pm
        script:
          - swift build --configuration release
    - step:
        name: Test
        caches:
          - swift-pm
        script:
          - swift test --parallel
```

**macOS / iOS builds** need `runs-on: ['self.hosted', 'macos']` and typically call `xcodebuild` instead of `swift build`. Register a mac runner (see self-hosted runners), then target it:

```yaml
pipelines:
  default:
    - step:
        name: iOS build and test
        runs-on:
          - self.hosted
          - macos
        script:
          - xcodebuild -scheme WidgetApp -destination 'platform=iOS Simulator,name=iPhone 15' clean test
```

#### PHP

Uses Composer for dependency install, PHPUnit for tests, PHPStan for static analysis. Caches the Composer vendor directory.

```yaml
image: php:8.3-cli

definitions:
  caches:
    composer: ~/.composer/cache
    vendor: vendor

pipelines:
  default:
    - parallel:
        - step:
            name: Static analysis
            caches:
              - composer
              - vendor
            script:
              - apt-get update && apt-get install -y --no-install-recommends git unzip
              - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
              - composer install --no-interaction --prefer-dist
              - vendor/bin/phpstan analyse
        - step:
            name: Test
            caches:
              - composer
              - vendor
            script:
              - apt-get update && apt-get install -y --no-install-recommends git unzip
              - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
              - composer install --no-interaction --prefer-dist
              - vendor/bin/phpunit --coverage-clover coverage.xml
            artifacts:
              - coverage.xml
```

For Laravel or Symfony, add a `services:` block with MySQL or PostgreSQL and set `APP_ENV: testing`.

#### Elixir

Runs on the official `elixir:1.16` image. Caches `deps/` and the `_build/` directory. Includes `mix format --check-formatted` and Credo for linting.

```yaml
image: elixir:1.16

definitions:
  caches:
    mix-deps: deps
    mix-build: _build

pipelines:
  default:
    - parallel:
        - step:
            name: Format check
            caches:
              - mix-deps
              - mix-build
            script:
              - mix local.hex --force
              - mix local.rebar --force
              - mix deps.get
              - mix format --check-formatted
        - step:
            name: Credo
            caches:
              - mix-deps
              - mix-build
            script:
              - mix local.hex --force
              - mix local.rebar --force
              - mix deps.get
              - mix credo --strict
        - step:
            name: Test
            caches:
              - mix-deps
              - mix-build
            script:
              - mix local.hex --force
              - mix local.rebar --force
              - mix deps.get
              - mix test --cover
            artifacts:
              - cover/**
```

For Phoenix, add a PostgreSQL service and set `MIX_ENV: test`.

#### C / C++

Uses `gcc:13` for builds. CMake drives configure, build, and test; `ctest` runs the suite.

```yaml
image: gcc:13

definitions:
  caches:
    cmake-build: build

pipelines:
  default:
    - step:
        name: Configure, build, and test
        caches:
          - cmake-build
        script:
          - apt-get update && apt-get install -y --no-install-recommends cmake ninja-build
          - cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
          - cmake --build build --parallel
          - ctest --test-dir build --output-on-failure
        artifacts:
          - build/**
```

For `clang`-only builds, swap the image to `silkeh/clang:17`. For cross-compilation or hardware-specific toolchains, use a self-hosted runner with the toolchain preinstalled.

#### Dart / Flutter

Two variants — pure Dart (uses the official `dart:stable` image) and Flutter (uses the Cirrus Labs Flutter image, the community standard for CI).

**Pure Dart:**

```yaml
image: dart:stable

definitions:
  caches:
    pub: ~/.pub-cache

pipelines:
  default:
    - step:
        name: Analyze and test
        caches:
          - pub
        script:
          - dart pub get
          - dart analyze --fatal-infos
          - dart format --output=none --set-exit-if-changed .
          - dart test --coverage=coverage
        artifacts:
          - coverage/**
```

**Flutter (Android build + test):**

```yaml
image: ghcr.io/cirruslabs/flutter:stable

definitions:
  caches:
    pub: ~/.pub-cache
    gradle: ~/.gradle/caches

pipelines:
  default:
    - step:
        name: Analyze and test
        caches:
          - pub
        script:
          - flutter pub get
          - flutter analyze
          - flutter format --output=none --set-exit-if-changed .
          - flutter test --coverage
        artifacts:
          - coverage/**
    - step:
        name: Android build
        caches:
          - pub
          - gradle
        script:
          - flutter pub get
          - flutter build apk --release
        artifacts:
          - build/app/outputs/flutter-apk/app-release.apk
```

**iOS builds require a self-hosted macOS runner.** Target it from YAML:

```yaml
    - step:
        name: iOS build
        runs-on:
          - self.hosted
          - macos
        script:
          - flutter pub get
          - flutter build ios --release --no-codesign
```

### Pipes (Bitbucket's Action marketplace)

Pipes are composable Docker-based steps you invoke from `bitbucket-pipelines.yml` with a `pipe:` key — the Bitbucket equivalent of GitHub Actions `uses:`. Atlassian ships official Pipes for common deploy and notify tasks, and the community publishes third-party Pipes. Unlike GitHub Actions, Pipes are always Docker images — there is no JavaScript or composite pipe format.

Browse the marketplace at <https://bitbucket.org/product/features/pipelines/integrations>.

**Example 1 — Slack notification on build status:**

```yaml
pipelines:
  default:
    - step:
        name: Test
        script:
          - npm ci
          - npm test
    - step:
        name: Notify Slack
        script:
          - pipe: atlassian/slack-notify:2.2.0
            variables:
              WEBHOOK_URL: $SLACK_WEBHOOK_URL
              MESSAGE: "Build $BITBUCKET_BUILD_NUMBER on $BITBUCKET_BRANCH succeeded"
```

**Example 2 — Deploy a static site to AWS S3:**

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm ci
            - npm run build
          artifacts:
            - dist/**
      - step:
          name: Deploy to S3
          deployment: production
          script:
            - pipe: atlassian/aws-s3-deploy:1.7.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: us-east-1
                S3_BUCKET: acme-widget-api-prod
                LOCAL_PATH: dist
                ACL: public-read
                CACHE_CONTROL: 'max-age=3600'
```

Pin Pipes to a specific version (not `:latest`) so pipeline behavior doesn't drift under you. For supply-chain-sensitive repos, pin by image digest (`atlassian/slack-notify@sha256:...`) instead of by tag.

### Self-hosted runners

Use self-hosted runners when you need:

- **Private network access** (on-prem databases, internal APIs behind a firewall)
- **macOS builds** (Swift, Xcode, iOS Flutter — not available on Atlassian-hosted Linux runners)
- **Windows builds** with preinstalled toolchains (.NET Framework, MSVC)
- **GPU hardware** for ML workloads
- **Custom compliance** — air-gapped or regulated environments

**Registering a runner:**

1. Navigate to **Repository settings → Pipelines → Runners** (or **Workspace settings → Runners** for workspace-shared runners).
2. Click **Add runner**. Choose OS (Linux / macOS / Windows) and give it a name and labels (e.g. `macos`, `gpu`, `internal-network`).
3. Bitbucket generates a `docker run` command (Linux) or a shell script (macOS / Windows) containing the runner's UUID and OAuth credentials. Run it on your host.
4. The runner appears in the **Runners** tab as `Online` within ~30 seconds.

**Targeting from YAML:**

```yaml
pipelines:
  default:
    - step:
        name: Build on self-hosted Linux
        runs-on:
          - self.hosted
          - linux
        script:
          - ./scripts/build.sh
    - step:
        name: Build on self-hosted macOS
        runs-on:
          - self.hosted
          - macos
        script:
          - xcodebuild -scheme WidgetApp clean build
```

The `self.hosted` label is always required; additional labels (`linux`, `macos`, `windows`, or any custom label you gave the runner) further constrain which runner picks up the step. If no matching runner is online, the step queues until one appears.

### Deployment environments and deployment variables

Deployment environments are a first-class Pipelines feature. Declaring `deployment: <env>` on a step marks that step as a deploy, scopes environment-specific variables to it, and tracks the deploy in the repo's **Deployments** tab with history, status, and rollback.

**Configuration:**

1. Create environments under **Repository settings → Deployments**. The defaults `Test`, `Staging`, and `Production` are created automatically when you first use `deployment:` in YAML.
2. Set environment variables under **Repository settings → Deployments → {env} → Variables**. Scoped variables override repo- and workspace-level variables when the step runs with `deployment: <env>`.
3. Mark secrets as **Secured** (the toggle on the variable) so they are masked in build logs and not exposed to forked-PR builds.

**Multi-environment pipeline example.** Test on every push, deploy to staging automatically on `develop`, deploy to production manually on `main`:

```yaml
image: node:20

pipelines:
  default:
    - step:
        name: Test
        script:
          - npm ci
          - npm test
  branches:
    develop:
      - step:
          name: Test
          script:
            - npm ci
            - npm test
      - step:
          name: Deploy staging
          deployment: staging
          script:
            - npm ci
            - npm run build
            - ./scripts/deploy.sh "$DEPLOY_HOST" "$DEPLOY_KEY"
    main:
      - step:
          name: Test
          script:
            - npm ci
            - npm test
      - step:
          name: Deploy production
          deployment: production
          trigger: manual
          script:
            - npm ci
            - npm run build
            - ./scripts/deploy.sh "$DEPLOY_HOST" "$DEPLOY_KEY"
```

`trigger: manual` makes the step wait for a human to click **Deploy** in the Bitbucket UI — this is the typical production guard. Combine with default-reviewer approval on the PR to get a two-person deploy workflow.

**How secrets flow.** Secured variables set at the workspace, repo, or deployment level are injected as environment variables into the step's container. Precedence: **deployment > repo > workspace** (deployment variables win). Secured variables are masked in logs and — critically — are **not** exposed to pull-request pipelines that come from forks, which prevents credential exfiltration from malicious PRs.

### Build status API

Pipelines posts build statuses to commits automatically. For external systems (custom CI, Sonar, third-party scanners) to report status alongside Pipelines, use the **Commit Statuses** REST API.

```bash
curl -X POST \
  -u "$BB_USER:$BB_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  "https://api.bitbucket.org/2.0/repositories/acme/widget-api/commit/$COMMIT_SHA/statuses/build" \
  -d '{
    "state": "SUCCESSFUL",
    "key": "sonarqube",
    "name": "SonarQube analysis",
    "url": "https://sonar.example.com/dashboard?id=widget-api",
    "description": "Quality gate passed"
  }'
```

Supported `state` values:

- `INPROGRESS` — the external check is running
- `SUCCESSFUL` — passed
- `FAILED` — failed
- `STOPPED` — canceled

The `key` is the unique identifier per external system — posting a new status with the same `key` overwrites the previous one. These statuses show up alongside Pipelines' own statuses on the PR and can be required in branch-restriction merge checks (**Minimum successful builds** counts both Pipelines and external statuses with matching `key`).

---

## Bitbucket-specific files summary

When setting up a Bitbucket Cloud project, generate this tree:

```
project-root/
  bitbucket-pipelines.yml    # Pipelines 2.0 config (always at repo root)
  .bitbucket/
    PULL_REQUEST_TEMPLATE.md # Default PR description (optional)
```

Bitbucket puts more configuration into the UI and REST API than GitHub puts into `.github/`. The table below lists what is *not* stored as a file — document these in a generated `docs/bitbucket-setup.md`.

| Concern | Where it lives | File? |
|---|---|---|
| Pipelines config | `bitbucket-pipelines.yml` (repo root) | **Yes** |
| PR description default | `.bitbucket/PULL_REQUEST_TEMPLATE.md` | Yes (optional) |
| Issue templates | Repository settings → Issues → Templates | No — document body |
| Default reviewers | Repository settings → Default reviewers | No |
| Branch permissions | Repository settings → Branch restrictions | No — optional REST-API script |
| Deployment environments | Repository settings → Deployments | No |
| Repo / workspace variables | Repository or Workspace settings → Variables | No (never commit secrets) |
| Merge strategy defaults | Repository settings → Merge strategies | No |

### Settings to recommend (cannot auto-configure from files)

Document these in the project README or a generated `docs/bitbucket-setup.md`:

- Description, topics, avatar for workspace-level discoverability
- Branch permissions on `main` — see Branch permissions section
- Merge checks on the `main` restriction: min 1 approval, min 1 successful build, no failed tasks, reset-approvals-on-push
- Default reviewers populated with maintainers
- Deployment environments (`test`, `staging`, `production`) with scoped variables
- Workspace-level variables for cross-repo secrets (never commit these)
- Merge strategy default: `squash`
- Jira integration linked at the workspace level if the team uses Jira

---

## Migrating from GitHub — the five biggest differences

The five conceptual shifts that catch teams out when moving a repo from GitHub to Bitbucket. Translate each, and the rest of the platform follows.

1. **Pipelines YAML shape — single file, step-based, not job-based.** GitHub Actions lives in `.github/workflows/*.yml` — a *directory* where every file is an independent workflow with its own `jobs:` graph. Bitbucket Pipelines is **one** `bitbucket-pipelines.yml` at the repo root. Instead of jobs that depend on each other, you have an ordered list of `steps` inside named pipelines (`default`, `branches.main`, `pull-requests.**`, `custom.*`, `tags.v*`). Parallelism is declared inline with `parallel:` blocks, not by a separate `jobs.X.needs:` DAG.

2. **Pipes vs Actions — smaller marketplace, Docker-only, no `uses:`.** GitHub Actions has `uses: actions/checkout@v4` with a huge first- and third-party marketplace. Bitbucket Pipes use `pipe: atlassian/slack-notify:2.2.0` — always a Docker image, always with `variables:` instead of Actions' `with:`. The Pipes marketplace is substantially smaller than Actions', and community contribution is less common; expect to write more inline shell for deploy/notify glue on Bitbucket.

3. **Branch permissions UI, not rulesets — no file-based import/export.** GitHub rulesets can be exported as JSON, committed, code-reviewed, and reimported. Bitbucket branch permissions are configured only via UI or the REST API — there is no JSON document you can commit to the repo that round-trips. Fork restrictions also live on the branch restriction object (`restrict_merges` kind), not on a separate "who can fork" setting. Teams that want their branch-permission state in version control typically script it in `scripts/apply-branch-permissions.sh` using the REST endpoints listed in the Branch permissions section.

4. **No CODEOWNERS — default reviewers is the analog (with less granularity).** GitHub's `CODEOWNERS` file uses path globs to map directories to reviewing teams. Bitbucket has **no** CODEOWNERS-like file. The closest feature is **default reviewers** (see the merge-strategies section) — a flat list of users automatically added to every PR targeting main. There is no path-glob, no team-level assignment, and no per-directory override. Teams that need real path-based ownership either tolerate coarse-grained review or add a third-party bot.

5. **Merge checks on the branch restriction, not "required status contexts".** On GitHub, branch protection has a separate "require status checks to pass before merging" screen where you pick specific check names. On Bitbucket, merge checks are configured directly on the branch restriction: "Minimum successful builds: N", "Minimum number of approvals: N", "No failed tasks", "Reset approvals on new commits". There is no per-check-name selection — the count-based model is coarser but simpler. External systems that post build statuses via the Commit Statuses API count toward "Minimum successful builds" alongside Pipelines' own builds.

---

## Sources

Authoritative Atlassian documentation. Consult these first when behavior diverges from this reference — Pipelines and the REST API do evolve.

- Pipelines YAML reference — <https://support.atlassian.com/bitbucket-cloud/docs/configure-bitbucket-pipelinesyml/>
- Branch permissions — <https://support.atlassian.com/bitbucket-cloud/docs/branch-permissions/>
- Deployments and deployment variables — <https://support.atlassian.com/bitbucket-cloud/docs/deployments/>
- Default reviewers — <https://support.atlassian.com/bitbucket-cloud/docs/default-reviewers/>
- Pipes — <https://support.atlassian.com/bitbucket-cloud/docs/pipes/>
- Self-hosted runners — <https://support.atlassian.com/bitbucket-cloud/docs/runners/>
- Merge strategies and merge checks — <https://support.atlassian.com/bitbucket-cloud/docs/suggest-or-require-checks-before-a-merge/>
- Commit Statuses REST API (build status API) — <https://developer.atlassian.com/cloud/bitbucket/rest/api-group-commit-statuses/>
- Branch Restrictions REST API — <https://developer.atlassian.com/cloud/bitbucket/rest/api-group-branch-restrictions/>
- Pipes marketplace — <https://bitbucket.org/product/features/pipelines/integrations>
- Smart Commits and Jira integration — <https://support.atlassian.com/bitbucket-cloud/docs/use-smart-commits/>

**Cross-reference.** For per-stack install / lint / test / build command rationale (why Ruff, why `cargo clippy -- -D warnings`, etc.), see `references/ci-cd-workflows.md`.

