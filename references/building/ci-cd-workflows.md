# CI/CD Workflow Templates

This reference provides complete, runnable CI/CD workflow files for every major stack. Every workflow is opinionated, production-tested, and ready to drop into a repository. No pseudocode, no placeholder steps.

Use this reference when setting up Tier 2 (Team Ready) and above. Match the workflow to the detected stack and project stage.

---

## Table of Contents

1. [GitHub Actions CI Templates](#github-actions-ci-templates)
   - [Node.js / TypeScript](#nodejs--typescript)
   - [Python](#python)
   - [Go](#go)
   - [Rust](#rust)
   - [Java / Kotlin](#java--kotlin)
   - [Ruby](#ruby)
   - [Zig](#zig)
   - [Gleam](#gleam)
   - [Deno](#deno)
   - [Bun](#bun)
   - [Multi-language / Polyglot](#multi-language--polyglot)
2. [GitHub Actions Specialized Workflows](#github-actions-specialized-workflows)
   - [Release Automation](#release-automation)
   - [Docker Build and Push](#docker-build-and-push)
   - [npm Publish](#npm-publish)
   - [PyPI Publish](#pypi-publish)
   - [Security Scanning](#security-scanning)
   - [Deploy Previews](#deploy-previews)
   - [Stale Issues and PRs](#stale-issues-and-prs)
   - [Auto-labeler](#auto-labeler)
   - [PR Size Labeler](#pr-size-labeler)
3. [GitLab CI Templates](#gitlab-ci-templates)
   - [Node.js](#gitlab-nodejs)
   - [Python](#gitlab-python)
   - [Go](#gitlab-go)
   - [Rust](#gitlab-rust)
   - [GitLab-Specific Features](#gitlab-specific-features)
4. [CI Best Practices](#ci-best-practices)
   - [What to Run When](#what-to-run-when)
   - [Caching Strategies](#caching-strategies)
   - [Matrix Testing](#matrix-testing)
   - [Parallel Jobs for Speed](#parallel-jobs-for-speed)
   - [Required Status Checks](#required-status-checks)
   - [When to Add Each Workflow](#when-to-add-each-workflow)

---

## GitHub Actions CI Templates

### Node.js / TypeScript

Covers setup-node, pnpm (preferred) or npm, linting with Biome or ESLint, type checking, testing with Vitest, and building. Caches pnpm store for fast installs.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

# Cancel in-progress runs for the same PR/branch
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Lint, Type Check, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # pnpm must be installed before setup-node so caching works
      - name: Install pnpm
        uses: pnpm/action-setup@v4
        # Version is read from packageManager field in package.json.
        # If your package.json doesn't have it, add: with: { version: 9 }

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'   # or .nvmrc, or set node-version: '22'
          cache: 'pnpm'                         # Caches ~/.local/share/pnpm/store

      - name: Install dependencies
        run: pnpm install --frozen-lockfile      # Fails if lockfile is out of date

      - name: Lint
        run: pnpm lint                           # biome check . OR eslint .

      - name: Type check
        run: pnpm type-check                     # tsc --noEmit

      - name: Test
        run: pnpm test                           # vitest run

      - name: Build
        run: pnpm build                          # tsup OR tsc OR next build
```

**npm variant** -- replace the pnpm steps:

```yaml
      # No pnpm install step needed

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'
          cache: 'npm'                           # Caches ~/.npm

      - name: Install dependencies
        run: npm ci                              # Clean install from lockfile
```

**With coverage reporting:**

```yaml
      - name: Test with coverage
        run: pnpm test -- --coverage

      - name: Upload coverage
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage/lcov.info
```

---

### Python

Covers setup-python, pip with uv (preferred) or poetry, linting with Ruff, type checking with mypy, testing with pytest, and caching.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Lint, Type Check, Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true                     # Caches uv's package cache

      - name: Setup Python
        run: uv python install                   # Reads .python-version or pyproject.toml

      - name: Install dependencies
        run: uv sync --frozen                    # Installs from uv.lock, fails if stale

      - name: Lint
        run: uv run ruff check .                 # Linting

      - name: Format check
        run: uv run ruff format --check .        # Verify formatting without modifying

      - name: Type check
        run: uv run mypy .                       # Static type checking

      - name: Test
        run: uv run pytest                       # Run test suite
```

**Poetry variant:**

```yaml
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version-file: '.python-version' # or python-version: '3.12'

      - name: Install Poetry
        run: pipx install poetry

      - name: Cache Poetry virtualenv
        uses: actions/cache@v4
        with:
          path: ~/.cache/pypoetry
          key: poetry-${{ runner.os }}-${{ hashFiles('poetry.lock') }}
          restore-keys: poetry-${{ runner.os }}-

      - name: Install dependencies
        run: poetry install --no-interaction

      - name: Lint
        run: poetry run ruff check .

      - name: Format check
        run: poetry run ruff format --check .

      - name: Type check
        run: poetry run mypy .

      - name: Test
        run: poetry run pytest
```

**pip variant (no lockfile manager):**

```yaml
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'                           # Caches pip download cache

      - name: Install dependencies
        run: pip install -e ".[dev]"              # Reads pyproject.toml extras

      - name: Lint
        run: ruff check .

      - name: Test
        run: pytest
```

---

### Go

Covers setup-go with module caching, golangci-lint, go test with race detection, and go build.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Lint, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: 'go.mod'              # Reads go directive from go.mod
          # setup-go@v5 caches ~/go/pkg/mod and ~/.cache/go-build by default

      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest
          # golangci-lint config is read from .golangci.yml in repo root

      - name: Test
        run: go test -race -coverprofile=coverage.out ./...
        # -race enables race detector; ./... runs all packages

      - name: Build
        run: go build ./...
        # Ensures all packages compile. For binaries, use go build -o bin/ ./cmd/...
```

**With coverage upload:**

```yaml
      - name: Upload coverage
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage.out
```

---

### Rust

Covers rust toolchain via dtolnay/rust-toolchain, clippy linting, cargo test, cargo build, and Swatinem/rust-cache for target directory caching.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Clippy, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt

      - name: Cache Cargo registry, index, and build artifacts
        uses: Swatinem/rust-cache@v2
        # Caches ~/.cargo/registry, ~/.cargo/git, and target/

      - name: Format check
        run: cargo fmt --all -- --check
        # Verify formatting without modifying files

      - name: Clippy lint
        run: cargo clippy --all-targets --all-features -- -D warnings
        # -D warnings treats warnings as errors

      - name: Test
        run: cargo test --all-features
        # Runs all tests including doc tests

      - name: Build
        run: cargo build --release
        # Release build to catch optimisation-only issues
```

**For workspaces (multi-crate projects):**

```yaml
      - name: Clippy (workspace)
        run: cargo clippy --workspace --all-targets --all-features -- -D warnings

      - name: Test (workspace)
        run: cargo test --workspace --all-features

      - name: Build (workspace)
        run: cargo build --workspace --release
```

---

### Java / Kotlin

Covers setup-java with Temurin, Gradle (preferred) or Maven, testing, building, and Gradle build cache.

**Gradle:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Lint, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'                # Eclipse Temurin (recommended)
          java-version: '21'                     # LTS version

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
        # Caches Gradle wrapper, dependencies, and build cache automatically

      - name: Lint
        run: ./gradlew detekt                    # For Kotlin; use checkstyle/spotless for Java
        # Alternative: ./gradlew spotlessCheck

      - name: Test
        run: ./gradlew test

      - name: Build
        run: ./gradlew build -x test             # Build without re-running tests
```

**Maven:**

```yaml
  check:
    name: Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'                         # Caches ~/.m2/repository

      - name: Test and Build
        run: mvn --batch-mode --no-transfer-progress verify
        # verify runs compile, test, and package phases
```

---

### Ruby

Covers setup-ruby with bundler caching, RuboCop linting, and RSpec testing.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Lint, Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '.ruby-version'          # Reads from .ruby-version file
          bundler-cache: true                    # Caches gems installed by bundler

      - name: Lint
        run: bundle exec rubocop                 # RuboCop for style and correctness

      - name: Test
        run: bundle exec rspec                   # RSpec test suite
        # Alternative: bundle exec rake test     # For Minitest
```

**With Rails-specific steps:**

```yaml
      - name: Setup database
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec rails db:create db:schema:load

      - name: Test
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec rspec

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd="pg_isready"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
```

---

### Zig

Zig pre-1.0 breaks between releases — pin Zig 0.13.0 explicitly in CI. Uses `goto-bus-stop/setup-zig@v2` (alternative: `mlugg/setup-zig@v0.1.0`). Runs formatter check, then the `test` step, then a full build.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Format, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.13.0

      - name: Cache Zig artifacts
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/zig
            ./zig-cache
            ./.zig-cache
            ./zig-out
          key: ${{ runner.os }}-zig-0.13.0-${{ hashFiles('build.zig.zon') }}

      - name: Check formatting
        run: zig fmt --check src/ build.zig

      - name: Run tests
        run: zig build test --summary all

      - name: Build
        run: zig build
```

- Cache paths cover both legacy (`zig-cache/`) and new (`.zig-cache/`) layouts so the workflow works across 0.12 → 0.13 toolchains; `build.zig.zon` is the cache key so dependency changes bust the cache.
- Cross-compile matrix (e.g. `-Dtarget=x86_64-linux-musl` + `-Dtarget=aarch64-macos`) is a natural extension; it's deferred here to keep the baseline minimal.
- Windows and macOS runners work identically with `setup-zig@v2` — add them to `runs-on` via matrix if you need per-OS smoke tests.

---

### Gleam

Gleam runs on the BEAM — use the canonical `erlef/setup-beam@v1` action, which pins both Erlang/OTP and Gleam in a single step. Pin Gleam to `1.4.0` on OTP `27.0`.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: Format, Check, Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup BEAM (Erlang + Gleam)
        uses: erlef/setup-beam@v1
        with:
          otp-version: "27.0"
          gleam-version: "1.4.0"

      - name: Cache Hex + build
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/hex
            ./build
            ./deps
          key: ${{ runner.os }}-gleam-1.4.0-otp-27.0-${{ hashFiles('manifest.toml') }}

      - name: Download dependencies
        run: gleam deps download

      - name: Check formatting
        run: gleam format --check src test

      - name: Type check
        run: gleam check

      - name: Run tests
        run: gleam test
```

- `manifest.toml` is the lockfile, so it's the cache key — any new dep refreshes the cache.
- For pure-Gleam projects you do NOT need `rebar3-version`; add it only if you have Erlang deps that require rebar3.
- Matrix across OTP 26/27 is a simple extension — add `strategy.matrix.otp` and reference it in `otp-version`.

---

### Deno

Deno 2.x ships everything in one binary, so CI is a single job with linear steps. Pin `deno-version: v2.0.x`. This template also shows an optional JSR publish job that fires on tag push and uses OIDC (`id-token: write`) — no secrets needed.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]
    tags: ["v*"]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    name: Format, Lint, Type-check, Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Deno
        uses: denoland/setup-deno@v2
        with:
          deno-version: v2.0.x

      - name: Cache Deno modules
        uses: actions/cache@v4
        with:
          path: ~/.cache/deno
          key: ${{ runner.os }}-deno-${{ hashFiles('deno.lock') }}

      - name: Check formatting
        run: deno fmt --check

      - name: Lint
        run: deno lint

      - name: Type check
        run: deno check **/*.ts

      - name: Test
        run: deno test --allow-read --allow-env

  publish:
    name: Publish to JSR
    needs: ci
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write          # required for JSR OIDC
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v2
        with:
          deno-version: v2.0.x
      - name: Publish
        run: deno publish
```

- `id-token: write` is mandatory for JSR's OIDC trust — no npm-style token in `secrets` needed.
- Deno caches modules under `~/.cache/deno`; keying on `deno.lock` gives reproducible cache hits.
- `deno compile` can be added as a separate matrix job to produce per-OS standalone binaries for release artifacts.

---

### Bun

Bun 1.1+ ships the package manager, runtime, and test runner — so the CI boils down to install, fmt+lint (via Biome), test, build. Use `oven-sh/setup-bun@v2` pinned to `bun-version: 1.1.x`.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    name: Install, Check, Test, Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: 1.1.x

      - name: Install dependencies
        run: bun install --frozen-lockfile

      - name: Biome (format + lint)
        run: bunx biome ci .

      - name: Test
        run: bun test

      - name: Build
        run: bun run build
```

- `--frozen-lockfile` is critical in CI — any drift in `bun.lockb` that wasn't committed will fail the install instead of silently resolving.
- `bunx biome ci .` is Biome's combined format+lint check (no writes); it replaces two steps.
- For Bun-drop-in projects (Node is the runtime, Bun is just the installer), swap the last step to `npm run build` or `node --run build` and keep the rest.

---

### Multi-language / Polyglot

Use matrix strategies to test across multiple versions, operating systems, or languages in a single workflow.

**Multi-version matrix (Node.js example):**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: Node ${{ matrix.node-version }} on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false                           # Don't cancel other jobs if one fails
      matrix:
        node-version: ['20', '22']
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Test
        run: pnpm test
```

**True polyglot (multiple languages in one repo):**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  # Frontend (TypeScript)
  frontend:
    name: Frontend
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend              # Scope all commands to frontend/
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: 'frontend/.node-version'
          cache: 'pnpm'
          cache-dependency-path: 'frontend/pnpm-lock.yaml'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint and type check
        run: pnpm lint && pnpm type-check

      - name: Test
        run: pnpm test

      - name: Build
        run: pnpm build

  # Backend (Go)
  backend:
    name: Backend
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend               # Scope all commands to backend/
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: 'backend/go.mod'

      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest
          working-directory: backend

      - name: Test
        run: go test -race ./...

      - name: Build
        run: go build ./cmd/server

  # Python (data pipeline, scripts, etc.)
  python:
    name: Python
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: pipeline
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true

      - name: Setup Python
        run: uv python install

      - name: Install dependencies
        run: uv sync --frozen

      - name: Lint
        run: uv run ruff check .

      - name: Test
        run: uv run pytest
```

---

## GitHub Actions Specialized Workflows

### Release Automation

Three main options. Pick one per project -- do not combine them.

**Option A: release-please (recommended for most projects)**

Creates a release PR that accumulates changes. When merged, it bumps the version, updates the changelog, and creates a GitHub Release. Requires Conventional Commits.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    name: Create Release PR
    runs-on: ubuntu-latest
    steps:
      - name: Run release-please
        uses: googleapis/release-please-action@v4
        with:
          # For a single package:
          release-type: node                     # or python, go, rust, java, ruby, etc.
          # release-please reads conventional commits since last release,
          # opens a PR with version bump + changelog update,
          # and creates a GitHub Release when the PR merges.
```

Configure via `release-please-config.json` in repo root for monorepos or customization:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "node",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {}
  }
}
```

**Option B: semantic-release (fully automated, no human review)**

Runs on every push to main. Analyzes commits, bumps version, generates changelog, publishes, and creates a GitHub Release -- all in one step. No PR review of version bumps.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    name: Semantic Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0                         # Full history for commit analysis
          persist-credentials: false

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}    # Only if publishing to npm
        run: npx semantic-release
```

Requires `.releaserc.json` in repo root:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version}\n\n${nextRelease.notes}"
    }]
  ]
}
```

**Option C: changesets (best for monorepos)**

Developers add changeset files describing their changes. A bot opens a "Version Packages" PR that batches pending changesets into version bumps and changelog entries.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

concurrency: ${{ github.workflow }}-${{ github.ref }}

jobs:
  release:
    name: Version or Publish
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Create Release PR or Publish
        uses: changesets/action@v1
        with:
          publish: pnpm run release              # Runs when Version PR merges
          title: 'chore: version packages'
          commit: 'chore: version packages'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

### Docker Build and Push

Builds a multi-platform Docker image and pushes to GitHub Container Registry (GHCR) or Docker Hub.

**Push to GHCR (recommended -- no extra credentials needed):**

```yaml
# .github/workflows/docker.yml
name: Docker

on:
  push:
    branches: [main]
    tags: ['v*']                                 # Build on version tags

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  packages: write                                # Required for GHCR

jobs:
  build:
    name: Build and Push
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        # Buildx enables multi-platform builds and layer caching

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            # Tag with branch name on push to main
            type=ref,event=branch
            # Tag with semver on version tags (v1.2.3 -> 1.2.3, 1.2, 1)
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            # Tag with sha for traceability
            type=sha,prefix=

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          platforms: linux/amd64,linux/arm64      # Multi-platform
          cache-from: type=gha                    # Use GitHub Actions cache for layers
          cache-to: type=gha,mode=max
```

**Push to Docker Hub** -- replace the login step:

```yaml
      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
```

And change the `images` in metadata:

```yaml
          images: ${{ secrets.DOCKERHUB_USERNAME }}/${{ github.event.repository.name }}
```

---

### npm Publish

Publishes to npm using OIDC trusted publishing (no long-lived NPM_TOKEN needed). Triggered when a GitHub Release is created (pairs with release-please or semantic-release).

```yaml
# .github/workflows/publish-npm.yml
name: Publish to npm

on:
  release:
    types: [published]

permissions:
  contents: read
  id-token: write                                # Required for npm OIDC provenance

jobs:
  publish:
    name: Publish
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Publish to npm
        run: pnpm publish --no-git-checks --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
          # --provenance generates SLSA provenance attestation via OIDC
          # --access public is needed for scoped packages (@org/pkg)
          # --no-git-checks skips git-related checks since we're in CI
```

**Setup on npm side:** Go to npmjs.com > Access Tokens > Generate New Token (Granular Access Token). Add it as `NPM_TOKEN` in GitHub repo settings > Secrets.

---

### PyPI Publish

Publishes to PyPI using OIDC trusted publishing (no API token needed). Triggered when a GitHub Release is created.

```yaml
# .github/workflows/publish-pypi.yml
name: Publish to PyPI

on:
  release:
    types: [published]

permissions:
  contents: read
  id-token: write                                # Required for PyPI trusted publishing

jobs:
  publish:
    name: Build and Publish
    runs-on: ubuntu-latest
    environment: pypi                            # Must match the PyPI trusted publisher config
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Setup Python
        run: uv python install

      - name: Build package
        run: uv build
        # Creates sdist and wheel in dist/

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
        # Uses OIDC trusted publishing -- no token needed
        # The GitHub repo must be registered as a trusted publisher on PyPI
```

**Setup on PyPI side:** Go to pypi.org > Your Project > Settings > Publishing > Add a new publisher. Fill in the GitHub repository owner, name, workflow filename (`publish-pypi.yml`), and environment name (`pypi`).

---

### Security Scanning

**CodeQL analysis (SAST):**

```yaml
# .github/workflows/codeql.yml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'                          # Weekly on Monday at 6:00 UTC

permissions:
  actions: read
  contents: read
  security-events: write

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        language: ['javascript-typescript']
        # Options: javascript-typescript, python, go, ruby, java-kotlin, csharp, cpp, swift
        # Add more languages if your repo is polyglot
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          # CodeQL queries: security-extended includes more rules than default
          queries: security-extended

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3
        # For compiled languages (Java, C#, Go, C++), this builds the project.
        # For interpreted languages (JS, Python, Ruby), it indexes source files.

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: '/language:${{ matrix.language }}'
```

**Dependency review (block PRs that introduce vulnerable dependencies):**

```yaml
# .github/workflows/dependency-review.yml
name: Dependency Review

on:
  pull_request:

permissions:
  contents: read

jobs:
  review:
    name: Dependency Review
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Dependency Review
        uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high                 # Block PRs with high/critical vulns
          # deny-licenses: 'GPL-3.0, AGPL-3.0'  # Optionally block copyleft licenses
```

---

### Deploy Previews

**Vercel preview deploys:**

```yaml
# .github/workflows/preview.yml
name: Preview Deploy

on:
  pull_request:

permissions:
  contents: read
  pull-requests: write                           # To post preview URL as comment
  deployments: write

jobs:
  deploy:
    name: Deploy Preview
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          github-comment: true                   # Posts preview URL on the PR
```

**Netlify preview deploys:**

```yaml
# .github/workflows/preview.yml
name: Preview Deploy

on:
  pull_request:

permissions:
  contents: read
  pull-requests: write

jobs:
  deploy:
    name: Deploy Preview
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install and Build
        run: |
          pnpm install --frozen-lockfile
          pnpm build

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v3
        with:
          publish-dir: './dist'                  # or ./build, ./out -- your build output
          production-deploy: false               # Preview only, not production
          github-token: ${{ secrets.GITHUB_TOKEN }}
          enable-pull-request-comment: true
          enable-commit-comment: false
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

---

### Stale Issues and PRs

Automatically marks and closes issues/PRs that have been inactive.

```yaml
# .github/workflows/stale.yml
name: Stale

on:
  schedule:
    - cron: '0 0 * * *'                          # Daily at midnight UTC

permissions:
  issues: write
  pull-requests: write

jobs:
  stale:
    name: Close Stale Issues and PRs
    runs-on: ubuntu-latest
    steps:
      - name: Mark and close stale items
        uses: actions/stale@v9
        with:
          # Issues
          days-before-stale: 60                  # Mark stale after 60 days of inactivity
          days-before-close: 14                  # Close 14 days after being marked stale
          stale-issue-label: 'stale'
          stale-issue-message: >
            This issue has been automatically marked as stale because it has not had
            recent activity. It will be closed in 14 days if no further activity occurs.
            If this issue is still relevant, please leave a comment.
          close-issue-message: >
            This issue was closed because it has been stale for 14 days with no activity.
            Feel free to reopen if this is still relevant.

          # PRs
          stale-pr-label: 'stale'
          stale-pr-message: >
            This pull request has been automatically marked as stale because it has not had
            recent activity. It will be closed in 14 days if no further activity occurs.
          close-pr-message: >
            This pull request was closed because it has been stale for 14 days with no activity.

          # Exempt labels -- issues with these labels are never marked stale
          exempt-issue-labels: 'pinned,security,bug'
          exempt-pr-labels: 'pinned,security'
```

---

### Auto-labeler

Automatically labels PRs based on which files were changed.

```yaml
# .github/workflows/labeler.yml
name: Labeler

on:
  pull_request_target:                           # _target has write access to add labels

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    name: Label PR
    runs-on: ubuntu-latest
    steps:
      - name: Label PR based on changed files
        uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          # Configuration is in .github/labeler.yml
```

Create `.github/labeler.yml` to define label rules:

```yaml
# .github/labeler.yml
# Maps labels to file path glob patterns

'area: frontend':
  - changed-files:
      - any-glob-to-any-file:
          - 'frontend/**'
          - 'src/components/**'
          - '*.css'
          - '*.tsx'

'area: backend':
  - changed-files:
      - any-glob-to-any-file:
          - 'backend/**'
          - 'src/api/**'
          - 'src/server/**'

'area: docs':
  - changed-files:
      - any-glob-to-any-file:
          - 'docs/**'
          - '*.md'
          - 'README*'

'area: ci':
  - changed-files:
      - any-glob-to-any-file:
          - '.github/**'
          - 'Dockerfile'
          - 'docker-compose*.yml'

'area: deps':
  - changed-files:
      - any-glob-to-any-file:
          - 'package.json'
          - 'pnpm-lock.yaml'
          - 'pyproject.toml'
          - 'uv.lock'
          - 'go.mod'
          - 'go.sum'
          - 'Cargo.toml'
          - 'Cargo.lock'
          - 'Gemfile'
          - 'Gemfile.lock'

'area: tests':
  - changed-files:
      - any-glob-to-any-file:
          - 'tests/**'
          - 'test/**'
          - '**/*.test.*'
          - '**/*.spec.*'
          - '**/*_test.go'
```

---

### PR Size Labeler

Labels PRs by the number of lines changed. Encourages small PRs.

```yaml
# .github/workflows/pr-size.yml
name: PR Size

on:
  pull_request:
    types: [opened, synchronize]

permissions:
  pull-requests: write

jobs:
  size:
    name: Label PR Size
    runs-on: ubuntu-latest
    steps:
      - name: Label PR by size
        uses: codelytv/pr-size-labeler@v1
        with:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          xs_label: 'size: xs'
          xs_max_size: 10
          s_label: 'size: s'
          s_max_size: 50
          m_label: 'size: m'
          m_max_size: 200
          l_label: 'size: l'
          l_max_size: 500
          xl_label: 'size: xl'
          fail_if_xl: false                      # Set true to block XL PRs
          message_if_xl: >
            This PR is very large. Consider breaking it into smaller PRs
            for easier review.
          files_to_ignore: |
            pnpm-lock.yaml
            package-lock.json
            uv.lock
            go.sum
            Cargo.lock
            *.snap
```

---

## GitLab CI Templates

### Node.js {#gitlab-nodejs}

```yaml
# .gitlab-ci.yml
stages:
  - check
  - build

# Shared configuration for all Node.js jobs
.node-setup:
  image: node:22-slim
  before_script:
    - corepack enable                            # Enables pnpm via packageManager field
    - pnpm install --frozen-lockfile
  cache:
    key:
      files:
        - pnpm-lock.yaml                         # Cache key changes when lockfile changes
    paths:
      - .pnpm-store/                             # pnpm's content-addressable store
    policy: pull-push

lint:
  stage: check
  extends: .node-setup
  script:
    - pnpm lint
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

type-check:
  stage: check
  extends: .node-setup
  script:
    - pnpm type-check
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: check
  extends: .node-setup
  script:
    - pnpm test
  coverage: '/All files\s*\|\s*\d+\.?\d*/'      # Regex to extract coverage from output
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    when: always
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  extends: .node-setup
  script:
    - pnpm build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

### Python {#gitlab-python}

```yaml
# .gitlab-ci.yml
stages:
  - check
  - build

.python-setup:
  image: python:3.12-slim
  before_script:
    - pip install uv
    - uv sync --frozen
  cache:
    key:
      files:
        - uv.lock
    paths:
      - .venv/
    policy: pull-push

lint:
  stage: check
  extends: .python-setup
  script:
    - uv run ruff check .
    - uv run ruff format --check .
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

type-check:
  stage: check
  extends: .python-setup
  script:
    - uv run mypy .
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: check
  extends: .python-setup
  script:
    - uv run pytest --cov --cov-report=xml
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    when: always
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: check
  extends: .python-setup
  script:
    - uv build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v/'               # Only build on version tags
```

### Go {#gitlab-go}

```yaml
# .gitlab-ci.yml
stages:
  - check
  - build

.go-setup:
  image: golang:1.23
  before_script:
    - go mod download
  cache:
    key:
      files:
        - go.sum
    paths:
      - /go/pkg/mod/
    policy: pull-push

lint:
  stage: check
  extends: .go-setup
  image: golangci/golangci-lint:latest           # Use the official lint image
  script:
    - golangci-lint run ./...
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: check
  extends: .go-setup
  script:
    - go test -race -coverprofile=coverage.out ./...
    - go tool cover -func=coverage.out           # Print coverage summary
  coverage: '/total:\s+\(statements\)\s+(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    when: always
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  extends: .go-setup
  script:
    - go build -o bin/ ./cmd/...
  artifacts:
    paths:
      - bin/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG =~ /^v/'
```

### Rust {#gitlab-rust}

```yaml
# .gitlab-ci.yml
stages:
  - check
  - build

.rust-setup:
  image: rust:1.82
  before_script:
    - rustup component add clippy rustfmt
  cache:
    key:
      files:
        - Cargo.lock
    paths:
      - target/
      - /usr/local/cargo/registry/
    policy: pull-push

format:
  stage: check
  extends: .rust-setup
  script:
    - cargo fmt --all -- --check
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

lint:
  stage: check
  extends: .rust-setup
  script:
    - cargo clippy --all-targets --all-features -- -D warnings
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: check
  extends: .rust-setup
  script:
    - cargo test --all-features
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  extends: .rust-setup
  script:
    - cargo build --release
  artifacts:
    paths:
      - target/release/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG =~ /^v/'
```

### GitLab-Specific Features

**`include` -- reuse shared CI config from another file or project:**

```yaml
# .gitlab-ci.yml
include:
  # Include from the same repo
  - local: '.gitlab/ci/lint.yml'
  - local: '.gitlab/ci/test.yml'
  - local: '.gitlab/ci/deploy.yml'

  # Include from another project (shared CI templates)
  - project: 'my-org/ci-templates'
    ref: main
    file: '/templates/node.yml'

  # Include from a remote URL
  - remote: 'https://gitlab.com/my-org/ci-templates/-/raw/main/node.yml'

  # Include official GitLab templates
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

**`extends` -- DRY job definitions:**

```yaml
# Base job that others extend
.deploy-base:
  image: alpine:3.19
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to $DEPLOY_ENV"
  tags:
    - docker

deploy-staging:
  extends: .deploy-base
  variables:
    DEPLOY_ENV: staging
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

deploy-production:
  extends: .deploy-base
  variables:
    DEPLOY_ENV: production
  environment:
    name: production
    url: https://example.com
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v/'
  when: manual                                   # Require manual click to deploy
```

**`rules` -- conditional job execution (replaces only/except):**

```yaml
deploy:
  script: ./deploy.sh
  rules:
    # Run on merge requests
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: never                                # Don't deploy on MRs

    # Run on main branch
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: on_success

    # Run on tags
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
      when: manual
      allow_failure: false                       # Block pipeline until approved

    # Run on schedule
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: always

    # Don't run in other cases
    - when: never
```

**Review apps (deploy preview per MR):**

```yaml
review:
  stage: deploy
  script:
    - echo "Deploy review app for $CI_MERGE_REQUEST_IID"
    # Your deploy script here, e.g., deploy to a dynamic environment
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    url: https://$CI_MERGE_REQUEST_IID.review.example.com
    on_stop: stop-review                         # Job to run when MR is merged/closed
    auto_stop_in: 1 week                         # Auto-cleanup after 1 week
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

stop-review:
  stage: deploy
  script:
    - echo "Tearing down review app for $CI_MERGE_REQUEST_IID"
  environment:
    name: review/$CI_MERGE_REQUEST_IID
    action: stop
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: manual
```

---

## CI Best Practices

### What to Run When

Different triggers need different pipelines. Running the full matrix on every push to a feature branch wastes minutes. Running only lint on a release tag misses the point.

| Trigger | What to run | Why |
|---------|-------------|-----|
| **Pull request** | Lint, type check, test, build | Catch issues before merge. This is the gatekeeper. |
| **Push to main** | Lint, type check, test, build, coverage upload, release check | Same checks as PR (in case of direct pushes), plus post-merge tasks. |
| **Version tag (`v*`)** | Build, publish, deploy | The code was already tested on main. Just build and ship. |
| **Schedule (weekly)** | Security scanning, dependency audit, full matrix | Catch newly disclosed vulnerabilities even without code changes. |

**Implementation pattern:**

```yaml
on:
  pull_request:                                  # All checks on PRs
  push:
    branches: [main]                             # All checks + extras on main
    tags: ['v*']                                 # Publish on version tags

jobs:
  check:
    # Runs on PRs and pushes to main
    if: github.event_name != 'push' || !startsWith(github.ref, 'refs/tags/')
    # ...lint, test, build steps...

  publish:
    # Only runs on version tags
    if: startsWith(github.ref, 'refs/tags/v')
    needs: []                                    # No dependency on check -- code was already tested
    # ...publish steps...
```

### Caching Strategies

Caching is the single biggest speed optimization for CI. Every ecosystem has a different cache target.

| Ecosystem | What to cache | Cache key | Action support |
|-----------|---------------|-----------|----------------|
| **Node.js (pnpm)** | `~/.local/share/pnpm/store` | `pnpm-lock.yaml` hash | `setup-node` with `cache: 'pnpm'` |
| **Node.js (npm)** | `~/.npm` | `package-lock.json` hash | `setup-node` with `cache: 'npm'` |
| **Python (uv)** | uv cache dir | `uv.lock` hash | `setup-uv` with `enable-cache: true` |
| **Python (pip)** | `~/.cache/pip` | `requirements*.txt` hash | `setup-python` with `cache: 'pip'` |
| **Python (poetry)** | `~/.cache/pypoetry` | `poetry.lock` hash | Manual `actions/cache` |
| **Go** | `~/go/pkg/mod`, `~/.cache/go-build` | `go.sum` hash | `setup-go@v5` caches automatically |
| **Rust** | `~/.cargo`, `target/` | `Cargo.lock` hash | `Swatinem/rust-cache@v2` |
| **Java (Gradle)** | `~/.gradle/caches`, `~/.gradle/wrapper` | `*.gradle*`, `gradle-wrapper.properties` | `gradle/actions/setup-gradle@v4` |
| **Java (Maven)** | `~/.m2/repository` | `pom.xml` hash | `setup-java` with `cache: 'maven'` |
| **Ruby** | Bundler gem dir | `Gemfile.lock` hash | `setup-ruby` with `bundler-cache: true` |

**Rules of caching:**

1. Always hash the lockfile as the cache key. If the lockfile changes, the cache is invalidated.
2. Use `--frozen-lockfile` (pnpm), `npm ci` (npm), `uv sync --frozen` (uv) in CI. This fails if the lockfile is out of date, preventing "works on my machine" issues.
3. Prefer built-in caching in setup actions over manual `actions/cache`. It is simpler and handles cache paths correctly.
4. For Rust, always use `Swatinem/rust-cache` -- manual caching of `target/` is tricky because of incremental compilation artifacts.

### Matrix Testing

Use matrices to test across versions and platforms without duplicating workflow code.

**When to use a matrix:**

- **Libraries:** Test across multiple runtime versions (Node 20 + 22, Python 3.11 + 3.12 + 3.13)
- **CLI tools:** Test across OS (ubuntu, macos, windows)
- **Both:** Full cross-product for libraries that must run everywhere

**When NOT to use a matrix:**

- **Web apps:** Only need to build on one OS/version (the production one)
- **Microservices:** Usually target one runtime version

**Efficient matrix patterns:**

```yaml
strategy:
  fail-fast: false                               # Always set false -- you want to see ALL failures
  matrix:
    # Full cross-product: 6 jobs (2 versions x 3 OS)
    node-version: ['20', '22']
    os: [ubuntu-latest, windows-latest, macos-latest]

    # Exclude specific combinations that don't matter
    exclude:
      - os: windows-latest
        node-version: '20'                       # Don't test old Node on Windows

    # Add specific one-off combinations
    include:
      - os: ubuntu-latest
        node-version: '23'                       # Test next version on Linux only
```

**Cost-conscious matrix (test on Linux, verify on others):**

```yaml
jobs:
  # Full checks on Linux (fast, cheap)
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: ['20', '22']
    steps:
      # ...lint, type check, test, build...

  # Smoke test on other OS (only test, skip lint/build)
  test-os:
    needs: test                                  # Only run if Linux tests pass
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [windows-latest, macos-latest]
    steps:
      # ...setup, install, test only...
```

### Parallel Jobs for Speed

Split work across parallel jobs when a single job takes too long. This trades runner minutes for wall-clock time.

**Split by concern (most common):**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ...setup...
      - run: pnpm lint

  type-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ...setup...
      - run: pnpm type-check

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ...setup...
      - run: pnpm test

  build:
    needs: [lint, type-check, test]              # Only build if all checks pass
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ...setup...
      - run: pnpm build
```

**When to keep it in one job vs split:**

| Scenario | Recommendation |
|----------|----------------|
| Total CI time < 3 minutes | One job. Overhead of spinning up multiple runners outweighs the benefit. |
| Total CI time 3-10 minutes | Split lint/test/build into parallel jobs. |
| Total CI time > 10 minutes | Split further: shard tests, parallelize matrix. |
| Monorepo with independent packages | One job per package, triggered by path filters. |

**Path filters to avoid unnecessary work:**

```yaml
on:
  pull_request:
    paths:
      - 'frontend/**'
      - 'package.json'
      - 'pnpm-lock.yaml'
      - '.github/workflows/frontend.yml'
```

### Required Status Checks

Required status checks block merging until specific CI jobs pass. This is the enforcement mechanism for code quality.

**What to make required (set in GitHub branch protection or rulesets):**

| Check | Required? | Why |
|-------|-----------|-----|
| Lint | Yes | Prevents style drift and catches common errors |
| Type check | Yes | Prevents type errors from reaching main |
| Test | Yes | Prevents regressions |
| Build | Yes | Ensures the project compiles/bundles |
| CodeQL | No | Can be slow; run but don't block merge |
| Dependency review | Yes | Blocks introduction of known-vulnerable dependencies |
| PR size labeler | No | Informational only |

**Setup:** GitHub repo > Settings > Branches > Branch protection rules > Require status checks to pass. Select the job names that must pass.

**Naming matters:** The job name in GitHub's status checks comes from the `name` field in the workflow file. Use clear, stable names:

```yaml
jobs:
  check:
    name: CI                                     # This is what appears in required checks
```

If you use a matrix, the name includes the matrix values:

```yaml
jobs:
  test:
    name: Test (Node ${{ matrix.node-version }}, ${{ matrix.os }})
```

Make required checks point to the non-matrix job or use a separate "gate" job:

```yaml
  # Gate job that requires all matrix jobs to pass
  ci-ok:
    name: CI                                     # Single stable name for branch protection
    needs: [lint, test, build]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Check results
        run: |
          if [[ "${{ needs.lint.result }}" != "success" ]] ||
             [[ "${{ needs.test.result }}" != "success" ]] ||
             [[ "${{ needs.build.result }}" != "success" ]]; then
            echo "One or more required jobs failed"
            exit 1
          fi
```

### When to Add Each Workflow

Not every project needs every workflow on day one. Add them as the project matures.

**Day 1 (Tier 1 -- every project):**

| Workflow | File | Why now |
|----------|------|---------|
| CI (lint, test, build) | `.github/workflows/ci.yml` | Catches bugs before merge. Non-negotiable. |

**When you have contributors (Tier 2):**

| Workflow | File | Why now |
|----------|------|---------|
| Auto-labeler | `.github/workflows/labeler.yml` | Helps triage PRs from contributors |
| PR size labeler | `.github/workflows/pr-size.yml` | Encourages small, reviewable PRs |
| Dependency review | `.github/workflows/dependency-review.yml` | Blocks vulnerable dependencies in PRs |

**When you're publishing (Tier 3):**

| Workflow | File | Why now |
|----------|------|---------|
| Release automation | `.github/workflows/release.yml` | Automates version bumps and changelogs |
| npm/PyPI publish | `.github/workflows/publish-*.yml` | Automates package publishing on release |
| Docker build | `.github/workflows/docker.yml` | Automates container image publishing |
| CodeQL | `.github/workflows/codeql.yml` | SAST scanning for security vulnerabilities |
| Deploy previews | `.github/workflows/preview.yml` | Preview changes before merge |

**When the project is mature (Tier 3+):**

| Workflow | File | Why now |
|----------|------|---------|
| Stale issues | `.github/workflows/stale.yml` | Keeps the issue tracker manageable |

**Never add preemptively:**

- Don't add stale bot to a new project with 3 issues
- Don't add deploy previews before you have a deploy target
- Don't add release automation before you have something to release
- Don't add Docker build before you have a Dockerfile
- Don't add npm publish before your package is ready for users
