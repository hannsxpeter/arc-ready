# Monorepo Patterns Reference

Tier 3 reference for multi-package monorepos. Load this when the repo holds more than one deployable, publishable, or independently versioned package in a single Git root — an Nx workspace, a Turborepo, a pnpm/yarn workspace, a moon polyglot workspace, a Cargo workspace, or a Go multi-module layout. Covers the seven mainstream tools with paste-ready configs, affected-only CI patterns, per-package changelog strategy, root-vs-package boundary rules, and the anti-patterns that kill monorepos in year two.

A monorepo helps when packages share owners, CI gates, versions, or atomic breaking changes. It hurts when packages release on different cadences with no shared code, when teams fight over root config, or when affected-only tooling is never wired up and CI is O(packages). If you land in the "hurts" column, multi-repo is the correct answer.

> **Scope boundary.** Multi-package monorepos only. Polyglot within a **single** package (one Python service also shipping a TypeScript SDK) is covered in `SKILL.md` §"Polyglot repositories — layering tools across languages".

## 1. Decision matrix — which tool for which stack

| Tool | Best for stack | Team size | Recommendation notes |
|---|---|---|---|
| **Nx** | Large JS/TS (Next, NestJS, Angular, React Native) with >10 packages, strong plugin needs | 10+ devs, multi-squad | Task graph + remote caching + generators. Highest ceiling, highest floor. Overkill for 3 packages. |
| **Turborepo** | Small–medium JS/TS (Next, Vite, Remix, Svelte) with 2–20 packages | 2–20 devs | Fast to set up, opinionated pipeline config, Vercel Remote Cache in ~5 minutes. Picks up where pnpm-workspaces ends. |
| **pnpm workspaces** | Minimal JS/TS where you want the package manager to do everything and no extra tool | 1–10 devs | Just `pnpm-workspace.yaml` + `workspace:*` deps. No task graph. Add Turborepo/Nx later if needed. |
| **yarn workspaces** | Teams already on Yarn 4 (Berry) with Plug'n'Play or zero-installs | 1–20 devs | Roughly feature-parity with pnpm workspaces; `yarn workspaces foreach --since` covers affected-only. Choose on ecosystem familiarity. |
| **moon** | Polyglot JS + Go + Rust + Python in one repo | 5–30 devs | Rust-written orchestrator that treats each language as a first-class task. Use when you need one tool across four ecosystems. |
| **Cargo workspaces** | Rust-only monorepos (crates sharing `[workspace.dependencies]`) | 1–50 devs | First-party in `cargo`. Zero extra dependency. Use for any Rust repo with >1 crate. |
| **Go workspaces** | Go-only multi-module repos (Go 1.18+) | 1–50 devs | `go.work` replaces `replace` directives for local development. Use when you have >1 `go.mod` in one repo. |
| Bazel | Enterprise polyglot, massive codebases, remote execution cluster | 50+ devs, dedicated build eng | Out of depth-scope here — high setup cost, strong guarantees. See [bazel.build/docs](https://bazel.build/docs). |
| uv workspaces | Python monorepos (2024+, emerging) | 1–10 devs | Brief mention only — API still evolving. See [docs.astral.sh/uv/concepts/workspaces](https://docs.astral.sh/uv/concepts/workspaces/). |

**One-line selection rule:** JS/TS → Turborepo (default) or Nx (scale). Rust → Cargo workspaces. Go → Go workspaces. Polyglot → moon. Enterprise polyglot → Bazel. Python → uv workspaces (watch this space) or per-package `pyproject.toml` with no workspace tool.

## 2. Nx

Nx is the heavyweight JS/TS option: task graph, project graph, generators, and a plugin system covering Next, NestJS, React Native, Angular, Storybook, Playwright. Larger config surface; payoff is affected-only CI, remote caching, and consistent task names (`nx test`, `nx lint`, `nx build`) across every package.

### Layout

```
my-workspace/
├── nx.json
├── package.json
├── tsconfig.base.json
├── apps/
│   ├── web/
│   │   └── project.json
│   └── api/
│       └── project.json
└── libs/
    ├── ui/
    │   └── project.json
    └── data-access/
        └── project.json
```

### `nx.json` (root)

```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": [
      "default",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)",
      "!{projectRoot}/tsconfig.spec.json",
      "!{projectRoot}/jest.config.[jt]s"
    ],
    "sharedGlobals": ["{workspaceRoot}/tsconfig.base.json"]
  },
  "targetDefaults": {
    "build": {
      "cache": true,
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"]
    },
    "test": {
      "cache": true,
      "inputs": ["default", "^production"]
    },
    "lint": {
      "cache": true,
      "inputs": ["default", "{workspaceRoot}/.eslintrc.json"]
    }
  },
  "defaultBase": "main"
}
```

### `project.json` (per-package, `apps/web/project.json`)

```json
{
  "name": "web",
  "$schema": "../../node_modules/nx/schemas/project-schema.json",
  "projectType": "application",
  "sourceRoot": "apps/web/src",
  "tags": ["scope:web", "type:app"],
  "targets": {
    "build": {
      "executor": "@nx/next:build",
      "outputs": ["{options.outputPath}"],
      "options": { "outputPath": "dist/apps/web" }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "options": { "jestConfig": "apps/web/jest.config.ts" }
    }
  }
}
```

### Affected-only CI (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
jobs:
  affected:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - uses: nrwl/nx-set-shas@v4
      - run: pnpm nx affected --target=lint --parallel=3
      - run: pnpm nx affected --target=test --parallel=3
      - run: pnpm nx affected --target=build --parallel=3
```

`nrwl/nx-set-shas` resolves the "base" and "head" SHAs for affected detection on PRs and on main. Remote caching (Nx Cloud) turns subsequent CI runs near-instant for unchanged packages — configure once via `npx nx connect`.

### Deep features worth learning

- **Project graph (`nx graph`)** — renders an HTML graph of project dependencies; use it when a package shows up as "affected" unexpectedly.
- **Module boundary tags** — the `tags` array in `project.json` plus `@nx/enforce-module-boundaries` ESLint rule prevents `apps/web` from importing `apps/api` internals; enforces scope-based architecture in CI.
- **Generators** — `nx g @nx/react:lib ui-buttons` scaffolds a new library with the right config, tsconfig path mappings, and target definitions. Custom generators keep new packages consistent.

## 3. Turborepo

Turborepo is the lighter JS/TS option: one `turbo.json`, a pipeline DAG, content-addressed caching, and Remote Cache via Vercel or a self-hosted S3-compatible store. No project files per package, no generators, no plugins — just `turbo run <task>` with `dependsOn` wiring. Start here for a 2–20 package repo on pnpm or Yarn.

### Layout

```
my-monorepo/
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
├── apps/
│   ├── web/
│   │   └── package.json
│   └── docs/
│       └── package.json
└── packages/
    ├── ui/
    │   └── package.json
    └── eslint-config/
        └── package.json
```

### `turbo.json`

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local", "tsconfig.base.json"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"],
      "inputs": ["$TURBO_DEFAULT$", ".env*"]
    },
    "lint": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"],
      "inputs": ["$TURBO_DEFAULT$", "!README.md"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

### Root `package.json`

```json
{
  "name": "acme-monorepo",
  "private": true,
  "packageManager": "pnpm@9.12.0",
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "dev": "turbo run dev"
  },
  "devDependencies": {
    "turbo": "^2.1.0"
  }
}
```

### Affected-only CI (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo run lint build test --filter='...[origin/main]'
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

The `...[origin/main]` filter means "every package that changed since `origin/main`, plus every package that depends on a changed package." `TURBO_TOKEN` + `TURBO_TEAM` enable Vercel Remote Cache; omit them for local-cache-only CI.

### Deep features worth learning

- **Pipeline `dependsOn: ["^build"]`** — the caret means "build all upstream dependencies first." The most common cause of flaky monorepo CI is forgetting this and racing on stale dist output.
- **`inputs` globs** — by default, `turbo` hashes the entire package. Scoping `inputs` to source files keeps the cache sharp when you only touched a README.
- **Remote Cache** — push and pull cache artifacts across machines. The payoff: CI and local dev hit the same cache; a PR lint run finishes in seconds after a teammate's main-branch run warmed the cache.

## 4. pnpm workspaces

pnpm workspaces is the minimal option: a `pnpm-workspace.yaml`, `workspace:*` deps, `pnpm --filter` on the CLI. No orchestrator. Reach for this at 2–10 packages with some shared libs and no task-graph need. Graduate to Turborepo when you want `dependsOn` wiring.

### Layout

```
my-workspace/
├── pnpm-workspace.yaml
├── package.json
├── pnpm-lock.yaml
├── apps/
│   └── web/
│       └── package.json
└── packages/
    └── utils/
        └── package.json
```

### `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "!**/test/**"

catalog:
  react: ^18.3.0
  typescript: ^5.5.0
  vitest: ^2.0.0
```

The `catalog` block (pnpm 9.5+) centralises version pins — packages reference them as `"react": "catalog:"` instead of repeating `^18.3.0` across every `package.json`.

### Consumer `package.json` (`apps/web/package.json`)

```json
{
  "name": "@acme/web",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@acme/utils": "workspace:*",
    "react": "catalog:"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "vitest": "catalog:"
  }
}
```

`workspace:*` resolves to the local package at install time; published artefacts get the real version number via `pnpm publish`'s version rewriting. `workspace:^` is "match the caret range"; `workspace:~` is "match the tilde range" — pick one convention and stick to it.

### Affected-only CI (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter '...[origin/main]' lint
      - run: pnpm --filter '...[origin/main]' test
      - run: pnpm --filter '...[origin/main]' build
```

The `...` ancestor syntax matches Turborepo's. `pnpm --filter '@acme/web...'` selects `@acme/web` and everything it depends on; `pnpm --filter '...@acme/web'` selects `@acme/web` and everything that depends on it.

### Deep features worth learning

- **Catalogs** (pnpm 9.5+) — single source of truth for cross-package versions; kills "three packages on three different React minors" drift.
- **`workspace:` protocol** — install-time vs publish-time resolution; get the rules right or published packages will point to unpublished workspace versions.
- **`pnpm deploy`** — produces a fully resolved, flattened `node_modules` tree for a single package; ideal for Dockerfile `COPY` lines in multi-stage builds.

For workspace-protocol semantics (`workspace:*`, `workspace:^`, `workspace:~`, `workspace:./path`), see [pnpm.io/workspaces](https://pnpm.io/workspaces) — resolver rules have sharp edges.

## 5. yarn workspaces

Yarn workspaces (Yarn 4, Berry line) is the feature-par alternative to pnpm workspaces for teams already on Yarn. Plug'n'Play (PnP) is optional — many teams stay on `nodeLinker: node-modules` for compatibility with tools that expect a real `node_modules` tree. The `yarn workspaces foreach --since` command is the native affected-only query.

### Layout

```
my-workspace/
├── .yarnrc.yml
├── package.json
├── yarn.lock
├── apps/
│   └── web/
│       └── package.json
└── packages/
    └── utils/
        └── package.json
```

### Root `package.json`

```json
{
  "name": "acme-monorepo",
  "private": true,
  "packageManager": "yarn@4.5.0",
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "build": "yarn workspaces foreach -A -pt run build",
    "test": "yarn workspaces foreach -A -pi run test",
    "lint": "yarn workspaces foreach -A -pi run lint"
  }
}
```

`-A` = all workspaces; `-p` = parallel; `-t` = topological order (dependencies first); `-i` = interlaced output. The topological flag matters for `build` (dependencies first) but not for `test` / `lint`.

### `.yarnrc.yml`

```yaml
nodeLinker: node-modules
enableGlobalCache: false

packageExtensions:
  "react-scripts@*":
    dependencies:
      "@babel/plugin-syntax-flow": "*"

plugins:
  - path: .yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs
    spec: "@yarnpkg/plugin-workspace-tools"
```

`nodeLinker: pnp` enables Plug'n'Play — faster, stricter, but some tools (Next.js < 14, some TS language-server configs) need extra wiring. Start on `node-modules` and migrate to `pnp` intentionally.

### Consumer `package.json` (`apps/web/package.json`)

```json
{
  "name": "@acme/web",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@acme/utils": "workspace:^",
    "react": "^18.3.0"
  }
}
```

### Affected-only CI (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: corepack enable
      - run: yarn install --immutable
      - run: yarn workspaces foreach -A --since=origin/main -pi run lint
      - run: yarn workspaces foreach -A --since=origin/main -pti run build
      - run: yarn workspaces foreach -A --since=origin/main -pi run test
```

`--since=origin/main` filters to workspaces whose files (or dependencies' files) changed since the given ref. Combine with `-t` on `build` to ensure upstream libs build before downstream apps.

### Deep features worth learning

- **Zero-installs** — commit `.yarn/cache` and skip `yarn install` in CI entirely. Trade-off: repo size grows. Best for repos with few deps changing often.
- **Constraints** — declarative `yarn constraints` rules that enforce "every workspace must declare the same React version" or "no workspace may depend on `lodash`". Caught version drift that would otherwise silently diverge.
- **`yarn workspaces foreach` with `-W`** — limits a command to workspaces matching a pattern; useful for running one command across the `apps/*` slice only.

## 6. moon

moon is the polyglot orchestrator — a Rust-written task runner that treats JavaScript, TypeScript, Go, Rust, Python, Ruby, and the rest as first-class with per-project toolchains, a task graph, file-hash-based caching, and an affected-only query (`moon query touched-files`). Reach for moon when one repo genuinely hosts more than one ecosystem and you want a single CLI instead of five.

### Layout

```
my-workspace/
├── .moon/
│   ├── workspace.yml
│   ├── toolchain.yml
│   └── tasks.yml
├── apps/
│   ├── web/                 # TypeScript
│   │   └── moon.yml
│   └── server/              # Go
│       └── moon.yml
└── packages/
    └── core/                # Rust
        └── moon.yml
```

### `.moon/workspace.yml`

```yaml
$schema: "https://moonrepo.dev/schemas/workspace.json"
projects:
  - "apps/*"
  - "packages/*"
vcs:
  manager: "git"
  defaultBranch: "main"
runner:
  archivableTargets:
    - ":build"
    - ":test"
  cacheLifetime: "7 days"
```

### `.moon/toolchain.yml`

```yaml
$schema: "https://moonrepo.dev/schemas/toolchain.json"
node:
  version: "20.17.0"
  packageManager: "pnpm"
  pnpm:
    version: "9.12.0"
rust:
  version: "1.82.0"
  components: ["clippy", "rustfmt"]
go:
  version: "1.23.0"
```

### Per-project `moon.yml` (`apps/web/moon.yml`)

```yaml
$schema: "https://moonrepo.dev/schemas/project.json"
type: "application"
language: "typescript"
stack: "frontend"
dependsOn:
  - "core"

tasks:
  build:
    command: "next build"
    inputs:
      - "src/**/*"
      - "next.config.mjs"
    outputs:
      - ".next"
  test:
    command: "vitest run"
  lint:
    command: "eslint src"
```

Mixing languages per project: `apps/server/moon.yml` uses `language: "go"` and Go-flavoured tasks; `packages/core/moon.yml` uses `language: "rust"` with `cargo build` tasks. Each project declares its own commands; the orchestrator handles dependency order.

### Affected-only CI (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
jobs:
  affected:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: moonrepo/setup-toolchain@v0
        with:
          moon-version: "latest"
      - run: moon ci --job=0 --job-total=1
```

`moon ci` automatically computes affected projects from `git diff` against the default branch and runs the `build`, `test`, `lint` tasks only for touched projects and their dependents. For larger repos, shard by passing `--job=<N> --job-total=<M>` across matrix runners.

### Deep features worth learning

- **Toolchain pinning** — `moon` installs and manages the exact Node/Rust/Go/pnpm versions declared in `.moon/toolchain.yml`; no nvm/rustup/goenv dance per developer.
- **Polyglot task graph** — a TS app can `dependsOn` a Rust crate; moon orders `cargo build` before `next build` automatically.
- **Project tags + constraints** — `tags: ["frontend"]` plus `constraints` in `workspace.yml` enforce "frontend projects can't depend on backend projects"; monorepo-wide architecture rules in one place.

## 7. Cargo workspaces

Cargo workspaces is first-party Rust: a root `Cargo.toml` with a `[workspace]` table, member crates in subdirectories, and `[workspace.dependencies]` for shared version pins. No extra tool, no extra config file. Every Rust monorepo with >1 crate should be a workspace from day one.

### Layout

```
my-workspace/
├── Cargo.toml
├── Cargo.lock
└── crates/
    ├── core/
    │   ├── Cargo.toml
    │   └── src/lib.rs
    ├── cli/
    │   ├── Cargo.toml
    │   └── src/main.rs
    └── server/
        ├── Cargo.toml
        └── src/main.rs
```

### Root `Cargo.toml`

```toml
[workspace]
resolver = "2"
members = ["crates/*"]
default-members = ["crates/cli"]

[workspace.package]
version = "0.1.0"
edition = "2021"
authors = ["Acme <dev@acme.example>"]
license = "MIT OR Apache-2.0"
repository = "https://github.com/acme/widget"

[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.40", features = ["full"] }
anyhow = "1.0"
clap = { version = "4.5", features = ["derive"] }

[profile.release]
lto = "thin"
codegen-units = 1
```

`resolver = "2"` enables the Rust 2021 feature resolver — required for feature unification to behave correctly in workspaces. `default-members` controls which members run when you type `cargo build` at the root with no `-p`.

### Member `Cargo.toml` (`crates/cli/Cargo.toml`)

```toml
[package]
name = "acme-cli"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true
repository.workspace = true

[dependencies]
acme-core = { path = "../core", version = "0.1.0" }
anyhow.workspace = true
clap.workspace = true
```

`.workspace = true` pulls the value from the root's `[workspace.package]` or `[workspace.dependencies]` — fields stay consistent across all crates without copy-paste.

### Affected-only CI (GitHub Actions)

Cargo does not ship an affected query; use `git diff` + per-package `cargo test -p <pkg>`:

```yaml
name: CI
on:
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt
      - uses: Swatinem/rust-cache@v2
      - name: Determine changed crates
        id: changed
        run: |
          BASE="${{ github.event.pull_request.base.sha }}"
          CHANGED=$(git diff --name-only "$BASE" HEAD \
            | grep '^crates/' \
            | cut -d/ -f1-2 \
            | sort -u \
            | sed 's|crates/|-p acme-|g' \
            | tr '\n' ' ')
          echo "pkgs=${CHANGED}" >> "$GITHUB_OUTPUT"
      - run: cargo fmt --all -- --check
      - run: cargo clippy ${{ steps.changed.outputs.pkgs }} --all-targets -- -D warnings
      - run: cargo test ${{ steps.changed.outputs.pkgs }}
```

The changed-crate detection assumes a `crates/<name>/` → `acme-<name>` naming convention; adjust the `sed` for your scheme. For a small workspace (<10 crates), skip the filter and just run `cargo test --workspace` — it's simpler and Cargo's incremental compilation keeps it fast.

### Deep features worth learning

- **Shared `[workspace.dependencies]`** — single source of truth for versions across every crate; eliminates "crate A pulls serde 1.0.150, crate B pulls 1.0.152" drift.
- **Feature unification** — features enabled on a dep in one crate unify across the workspace under resolver v2; test with `cargo check -p <single-crate>` to surface hidden feature dependencies.
- **`cargo-release` + `release-plz`** — workspace-aware release automation; bumps versions, writes `CHANGELOG.md`, and tags per-crate or workspace-wide. See [release-plz.ieni.dev](https://release-plz.ieni.dev).

## 8. Go workspaces

Go workspaces (Go 1.18+) solve the "I have multiple modules in one repo and want to develop across them without `replace` directives" problem. A top-level `go.work` file declares the modules; `go build`, `go test`, and `go run` automatically resolve inter-module references from local source when inside the workspace. Use this for any Go repo with more than one `go.mod`.

### Layout

```
my-workspace/
├── go.work
├── go.work.sum
├── core/
│   ├── go.mod
│   └── core.go
├── cli/
│   ├── go.mod
│   └── main.go
└── server/
    ├── go.mod
    └── main.go
```

### `go.work`

```
go 1.23

use (
    ./core
    ./cli
    ./server
)
```

### Module `go.mod` (`cli/go.mod`)

```
module github.com/acme/widget/cli

go 1.23

require (
    github.com/acme/widget/core v0.0.0
    github.com/spf13/cobra v1.8.1
)
```

No `replace` directive. The `go.work` file at the repo root tells the Go toolchain to resolve `github.com/acme/widget/core` from `./core` during local development. When consumers outside the repo pull your modules, they get the published versions via normal `go.mod` resolution.

### Affected-only CI (GitHub Actions)

Go workspaces have no built-in affected query either; use `git diff` + per-module `go test`:

```yaml
name: CI
on:
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-go@v5
        with:
          go-version: "1.23"
          cache: true
      - name: Determine changed modules
        id: changed
        run: |
          BASE="${{ github.event.pull_request.base.sha }}"
          MODS=$(git diff --name-only "$BASE" HEAD \
            | awk -F/ 'NF>=2 {print $1"/"$2}' \
            | sort -u \
            | while read dir; do [ -f "$dir/go.mod" ] && echo "./$dir/..."; done)
          echo "mods<<EOF" >> "$GITHUB_OUTPUT"
          echo "$MODS" >> "$GITHUB_OUTPUT"
          echo "EOF" >> "$GITHUB_OUTPUT"
      - name: Vet + test changed modules
        run: |
          while IFS= read -r mod; do
            [ -n "$mod" ] || continue
            echo "== $mod =="
            go vet "$mod"
            go test -race -timeout 5m "$mod"
          done <<< "${{ steps.changed.outputs.mods }}"
      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with: { version: v1.61 }
```

For workspaces with <10 modules, `go test ./...` at the root runs tests across every `use`d module and is simpler than the affected filter. Switch to filtering when full-workspace test times exceed ~5 minutes.

### Deep features worth learning

- **`go work sync`** — rewrites each module's `go.sum` to match the workspace-resolved versions; run after updating shared deps.
- **`go.work.sum`** — checksum file for workspace-resolved modules; commit this alongside `go.work` so CI sees the same resolution.
- **Don't `replace` in `go.mod`** — the common pre-workspaces pattern of `replace github.com/acme/core => ../core` still works but is fragile (forgotten in PRs, breaks downstream consumers). Use `go.work` instead.

## 9. Bazel and uv — brief mentions only

**Bazel** is the enterprise-scale polyglot build system — hermetic builds, remote execution, cross-language correctness guarantees no other tool here matches. High fixed cost: `BUILD` files per directory, `WORKSPACE` / `MODULE.bazel` external dep wiring, and Starlark to learn. Reach for Bazel when (a) incremental rebuilds are the dominant bottleneck, (b) you have a dedicated build-engineering team, and (c) remote execution pays for itself. Overkill otherwise. Docs: [bazel.build/start](https://bazel.build/start); rules for [JS/TS](https://github.com/bazelbuild/rules_nodejs), [Go](https://github.com/bazelbuild/rules_go), [Rust](https://github.com/bazelbuild/rules_rust).

**uv workspaces** (Python) arrived with uv 0.4+ (2024) — the closest Python has had to Cargo workspaces. Declare members in root `pyproject.toml` `[tool.uv.workspace]`; each member has its own `pyproject.toml`; `uv sync` resolves across the workspace. API is young — feature flags, lockfile layout, and publish semantics have shifted between minor versions. Docs: [docs.astral.sh/uv/concepts/workspaces](https://docs.astral.sh/uv/concepts/workspaces/). For conservative repos, per-package `pyproject.toml` managed by Poetry or Hatch with path deps during local dev still works.

## 10. Affected-only CI patterns — cross-tool summary

Every mature monorepo runs CI only against PR-touched packages; full-repo CI past ~20 packages is where reviewers stop waiting and merge on green-from-last-week. The hooks each tool exposes:

| Tool | Affected command | CI integration pattern | Caveats |
|---|---|---|---|
| Nx | `nx affected --target=test` | `nrwl/nx-set-shas@v4` resolves base/head SHAs; requires `fetch-depth: 0` | First-run cache miss is slow; Nx Cloud Remote Cache fixes this |
| Turborepo | `turbo run test --filter='...[origin/main]'` | `fetch-depth: 2` plus `TURBO_TOKEN`/`TURBO_TEAM` for Remote Cache | `...` syntax means "changed plus dependents"; `..` is "changed plus deps" (opposite direction) |
| pnpm workspaces | `pnpm --filter '...[origin/main]' test` | `pnpm/action-setup@v4` + `fetch-depth: 0` | Shares filter syntax with Turborepo; works without a task runner |
| yarn workspaces | `yarn workspaces foreach --since=origin/main run test` | `corepack enable` + `fetch-depth: 0` | `--since` compares against a ref, not a PR-specific base; set the ref explicitly |
| moon | `moon ci` | `moonrepo/setup-toolchain@v0`; sharding via `--job=N --job-total=M` | Computes affected graph automatically from `git diff` against `vcs.defaultBranch` |
| Cargo workspaces | `cargo test -p <changed-pkgs>` via `git diff` | No native affected; glue-script `git diff` → crate list → `-p` args | For <10 crates, skip filter and run `cargo test --workspace` |
| Go workspaces | `go test $(changed-modules)` via `git diff` | No native affected; walk `git diff` → module dirs containing `go.mod` | For <10 modules, skip filter and run `go test ./...` at root |

**Shared rules across all seven:**

- **`fetch-depth: 0`** (or `2` for Turborepo) on `actions/checkout` is mandatory — shallow clones have no base to diff against.
- **Run affected-only on PRs, full on main.** The main-branch run warms the cache and catches drift the PR filter missed.
- **Don't short-circuit format/lint.** Even affected-only CI should run formatter checks on the whole repo — formatter misses creep in as "untouched" config edits.
- **Pair with caching.** Affected filtering reduces work; remote caching reduces repeated work. Nx Cloud, Turbo Remote Cache, moon's `archivableTargets`, `Swatinem/rust-cache`, `actions/setup-go` `cache: true` — set one up before the affected filter, not after.

## 11. Per-package changelog strategy

Three working patterns. Pick one per repo and stick to it.

### Pattern A: Changesets (JS/TS monorepos)

[Changesets](https://github.com/changesets/changesets) is the de facto standard for JS/TS monorepos on pnpm, yarn, or npm workspaces. Contributors add a markdown "changeset" file per PR describing the change and the bump level (patch/minor/major) per affected package; on release, the CLI aggregates changesets, bumps `package.json` versions, writes per-package `CHANGELOG.md`, and tags/publishes.

`.changeset/config.json`:

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [["@acme/web", "@acme/docs"]],
  "access": "public",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": ["@acme/examples"]
}
```

`linked` keeps the listed packages on the same version (e.g., a Next app and its docs site that ship together). `fixed` is stricter — fixed packages always share a version even when unrelated. `updateInternalDependencies: patch` auto-bumps a package when a workspace dep it consumes gets any version bump, preventing downstream consumers from pointing at stale internal versions.

Release workflow (GitHub Actions):

```yaml
name: Release
on:
  push:
    branches: [main]
concurrency: ${{ github.workflow }}-${{ github.ref }}
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - uses: changesets/action@v1
        with:
          publish: pnpm changeset publish
          version: pnpm changeset version
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

The action opens (or updates) a "Version Packages" PR each time changesets land on main; merging that PR runs `changeset publish` and pushes to npm.

### Pattern B: Language-native release tools (Rust / Go)

- **Rust — `release-plz`** ([release-plz.ieni.dev](https://release-plz.ieni.dev)) opens a PR per push to main with `Cargo.toml` version bumps, updated `CHANGELOG.md` files (Keep-a-Changelog format), and on merge runs `cargo publish` for each changed crate in dependency order. Configure via `release-plz.toml` at the repo root.
- **Rust — `cargo-release`** ([crates.io/crates/cargo-release](https://crates.io/crates/cargo-release)) is the manual alternative; run `cargo release minor -p <crate>` to bump and publish one crate at a time.
- **Go — `goreleaser`** ([goreleaser.com](https://goreleaser.com)) handles binary builds, archives, and GitHub releases per module. Changelogs are generated from conventional commits via the `changelog` section of `.goreleaser.yaml`.
- **Language-agnostic — `release-please`** (Google, [github.com/googleapis/release-please](https://github.com/googleapis/release-please)) works across Rust, Go, Python, JS, Java in a single monorepo; reads conventional commits, opens a release PR per changed package, writes per-package `CHANGELOG.md`.

### Pattern C: Manual per-package `CHANGELOG.md`

For small repos (<5 packages) or repos where releases are coordinated by hand, keep one `CHANGELOG.md` per package following [Keep a Changelog](https://keepachangelog.com). Contributors update the relevant package's changelog in their PR. The root has no changelog — only packages do.

### One-root vs per-package — which?

**Per-package changelog** wins when packages release independently (a utils lib moves faster than the app that consumes it). **One root changelog** wins when packages always ship together (fixed versioning, single published artefact). Don't do both — readers will never know which is authoritative. If you must have both, the root changelog links to per-package files; it does not duplicate entries.

## 12. Root-vs-package boundary rules

Fastest way to kill a monorepo: let everybody edit everything at the root. These rules keep root config small and package autonomy real.

| Config | Root or Package? | Why |
|---|---|---|
| `tsconfig.base.json` | **Root** (base) + **package** (`tsconfig.json` extends base) | Shared `compilerOptions` in base; per-package `include` / `paths` / `references` in package tsconfigs |
| ESLint flat config (`eslint.config.js`) | **Root** (flat config + overrides per project glob) | Single ESLint invocation across the repo; per-package rule deltas via `files: ['packages/ui/**']` entries |
| `.editorconfig` | **Root only** | Whitespace and line-ending rules are universal; per-package overrides confuse editors |
| `package.json` `scripts` | **Package** (per-package) | Each package owns its build/test commands; root scripts delegate via `turbo run` / `nx run-many` / `pnpm -r` |
| Root `package.json` `scripts` | **Root** (orchestrator only) | `build`, `test`, `lint` here call the task runner; never contain real build logic |
| `Cargo.toml` `[workspace.dependencies]` | **Root only** | Single version source; members use `dep.workspace = true` |
| Member `Cargo.toml` `[dependencies]` | **Package** | Per-crate feature flags, path deps, dev-deps |
| `go.work` | **Root only** | Workspace manifest; never committed at package level |
| Module `go.mod` | **Package** | Each module declares its own deps; `go.work` composes them |
| CI config (`.github/workflows/`, `.gitlab-ci.yml`) | **Root only** | One CI surface per repo; per-package CI forks are an anti-pattern — use affected filters instead |
| `.gitignore` | **Root** (shared) + **package** (package-specific artefacts) | Language artefacts (`node_modules`, `target/`, `dist/`) at root; package-local test fixtures at the package |
| `LICENSE` | **Root** (default) + **package** (only when a package needs a different license) | Most packages inherit the root license; document overrides in each package's `package.json` `license` field |
| `README.md` | **Root** (repo overview) + **package** (per-package README) | Root README orients contributors; package READMEs describe that package's API and local dev loop |
| `CHANGELOG.md` | Depends on release pattern | Per-package under Changesets/release-plz; root only under one-root-changelog |
| `CODEOWNERS` | **Root only** | One GitHub/GitLab-level file; path patterns target packages (`/packages/ui/ @acme/ui-team`) |
| Dependabot / Renovate config | **Root only** | One schedule, one grouping policy; per-directory targeting via glob |

**When a rule collides:** the root rule wins unless the package explicitly overrides with a documented reason. "We needed different ESLint rules in `apps/legacy`" is documented; "I didn't know there was a root config" is the "unclear ownership" anti-pattern in §13.

## 13. Anti-patterns

Failure modes that reliably eat monorepos in year two. All are recoverable; all are cheaper to prevent.

1. **Circular package dependencies.** `@acme/ui` imports `@acme/app`; `@acme/app` imports `@acme/ui`. Task-graph tools flag the cycle; native package managers silently succeed and break incremental builds. **Fix:** extract the shared bit into a third package; enforce with module-boundary lint rules (Nx `@nx/enforce-module-boundaries`; custom ESLint elsewhere).
2. **Mixing workspace tools in one repo.** Nx + Turborepo both owning the task graph; pnpm + yarn both declaring packages. Result: contradictory caches, dueling CLIs, broken CI. **Fix:** one orchestrator per repo. If migrating, complete the switch in one PR.
3. **Conflicting peer dependencies across packages.** `@acme/ui` wants `react@18`; `@acme/legacy` wants `react@17`. Package managers hoist whichever wins first and the other silently breaks. **Fix:** pin via `catalog:` (pnpm) or `[workspace.dependencies]` (Cargo); drop the conflicting package if unresolvable.
4. **Shared `node_modules` corruption from mismatched package managers.** Dev A runs `npm install`, Dev B runs `pnpm install`; trees disagree and CI fails. **Fix:** commit `packageManager` in root `package.json`; enable Corepack in dev and CI; delete the stale lockfile.
5. **Unclear ownership.** Eight teams edit `/packages/utils` for unrelated reasons; a breaking change ships unreviewed. **Fix:** `CODEOWNERS` at the root mapping paths to teams; require review.
6. **Root scripts that mutate package state.** A root `postinstall` writing into every package's `dist/`; a root `clean` deleting state packages depend on for local dev. **Fix:** root scripts delegate to the task runner; mutation happens inside the touched package's script.
7. **Full-repo CI past 20 packages.** Every PR runs every test; queue time climbs until PRs land on stale bases. **Fix:** affected-only on PRs (§10); full-workspace CI on main and nightly.
8. **Per-package CI forks.** Each package has its own `.github/workflows/pkg-X.yml`. Drift is inevitable; onboarding a new package means copy-pasting YAML. **Fix:** one root workflow using the tool's affected filter; matrices only for truly per-package config (e.g., deploy targets).
9. **Root `package.json` as dumping ground.** Deps used by one package creep into the root; the root becomes the biggest package. **Fix:** root has only `devDependencies` (orchestrator, formatters, commit-linters). Runtime deps live in the package that uses them.
10. **No "why is this a monorepo" answer.** Three repos get cargo-culted into one because "monorepo is modern," nothing is actually shared, and every CI run costs 3× what separate repos would. **Fix:** before starting, write down what you expect to share. Empty list → keep the repos separate.

## Sources

- **Nx** — [nx.dev/concepts/mental-model](https://nx.dev/concepts/mental-model), [nx.dev/ci/features/affected](https://nx.dev/ci/features/affected), [nx.dev/recipes/running-tasks/configure-inputs](https://nx.dev/recipes/running-tasks/configure-inputs)
- **Turborepo** — [turbo.build/repo/docs/crafting-your-repository](https://turbo.build/repo/docs/crafting-your-repository), [turbo.build/repo/docs/crafting-your-repository/running-tasks#using-filters](https://turbo.build/repo/docs/crafting-your-repository/running-tasks#using-filters)
- **pnpm** — [pnpm.io/workspaces](https://pnpm.io/workspaces), [pnpm.io/catalogs](https://pnpm.io/catalogs), [pnpm.io/filtering](https://pnpm.io/filtering)
- **yarn** — [yarnpkg.com/features/workspaces](https://yarnpkg.com/features/workspaces), [yarnpkg.com/cli/workspaces/foreach](https://yarnpkg.com/cli/workspaces/foreach), [yarnpkg.com/features/constraints](https://yarnpkg.com/features/constraints)
- **moon** — [moonrepo.dev/docs](https://moonrepo.dev/docs), [moonrepo.dev/docs/config/workspace](https://moonrepo.dev/docs/config/workspace), [moonrepo.dev/docs/guides/ci](https://moonrepo.dev/docs/guides/ci)
- **Cargo workspaces** — [doc.rust-lang.org/cargo/reference/workspaces.html](https://doc.rust-lang.org/cargo/reference/workspaces.html), [doc.rust-lang.org/cargo/reference/resolver.html](https://doc.rust-lang.org/cargo/reference/resolver.html)
- **Go workspaces** — [go.dev/ref/mod#workspaces](https://go.dev/ref/mod#workspaces), [go.dev/blog/get-familiar-with-workspaces](https://go.dev/blog/get-familiar-with-workspaces)
- **Bazel** — [bazel.build/start](https://bazel.build/start), [bazelbuild/rules_nodejs](https://github.com/bazelbuild/rules_nodejs), [bazelbuild/rules_go](https://github.com/bazelbuild/rules_go), [bazelbuild/rules_rust](https://github.com/bazelbuild/rules_rust)
- **uv workspaces** — [docs.astral.sh/uv/concepts/workspaces](https://docs.astral.sh/uv/concepts/workspaces/)
- **Changesets** — [github.com/changesets/changesets](https://github.com/changesets/changesets)
- **release-plz (Rust)** — [release-plz.ieni.dev](https://release-plz.ieni.dev)
- **release-please (polyglot)** — [github.com/googleapis/release-please](https://github.com/googleapis/release-please)
- **Keep a Changelog** — [keepachangelog.com](https://keepachangelog.com)
