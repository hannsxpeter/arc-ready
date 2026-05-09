# Repo Structure

A repository's folder structure is its first impression to contributors. A well-structured repo lets someone `ls` the root and immediately understand: where the source code lives, where tests go, where to find documentation, and where build artifacts end up. A poorly structured repo forces them to grep for answers.

This reference covers folder conventions, stack-specific canonical structures, project type layouts, and naming conventions. It is prescriptive -- when the ecosystem has a convention, follow it. When it doesn't, use the defaults here.

## Universal folder conventions

These directories appear across most ecosystems. The name varies; the purpose is constant.

### Source code

| Directory | When to use | Ecosystem examples |
|---|---|---|
| `src/` | Default source directory when no framework dictates otherwise | JS/TS (non-framework), Rust, C#, C/C++, Dart |
| `lib/` | Ruby, Elixir, and libraries that distinguish "library code" from "executable code" | Ruby (`lib/gem_name/`), Elixir (`lib/app_name/`), Perl |
| `app/` | Framework convention for application code | Next.js App Router, Rails, Laravel, Phoenix |
| `cmd/` | Go convention for executable entry points | Go (one subdirectory per binary) |
| `internal/` | Go convention for non-importable packages | Go only -- compiler-enforced |
| `pkg/` | Go convention for importable library packages | Go -- use sparingly, prefer `internal/` |
| `Sources/` | Swift Package Manager convention | Swift (PascalCase, compiler-enforced) |

**Decision rule:** If your framework or build tool expects a specific directory, use it. If not, use `src/`.

### Tests

| Directory | When to use | Ecosystem examples |
|---|---|---|
| `tests/` | Default test directory | Python, Rust, C#, PHP |
| `test/` | Singular form convention | Go (`*_test.go` colocated), Ruby, Elixir, Dart |
| `spec/` | RSpec/BDD convention | Ruby (RSpec), JavaScript (Jasmine) |
| `__tests__/` | Jest/Vitest colocated convention | JavaScript/TypeScript (placed alongside source) |
| `Tests/` | Swift/Xcode convention | Swift (PascalCase, SPM-enforced) |

**Colocation vs separation:** Some ecosystems colocate tests with source (Go: `foo_test.go` next to `foo.go`; JS: `foo.test.ts` next to `foo.ts`). Others separate them (Python: `tests/` at root; Rust: `tests/` for integration tests). Follow the ecosystem convention.

### Documentation

```
docs/
  getting-started.md       # Tutorial: zero to running
  architecture.md          # Explanation: how and why
  api/                     # Reference: generated or hand-written API docs
  adr/                     # Architecture Decision Records
    0001-record-architecture-decisions.md
    template.md
  runbooks/                # Operational procedures (SaaS/DevOps)
  migration/               # Version migration guides (libraries)
  rfcs/                    # Design proposals (large projects)
```

Use the Diataxis framework to categorize docs: tutorials (learning-oriented), how-to guides (task-oriented), reference (information-oriented), explanation (understanding-oriented). Not every project needs all four.

### Scripts

```
scripts/
  setup.sh                 # Developer environment setup
  seed.sh                  # Database seed data
  deploy.sh                # Deployment script
  benchmark.sh             # Performance benchmarks
```

Scripts go in `scripts/`, not the root. The root is for config files that tooling requires there. Scripts are for human-invoked automation that doesn't belong in CI.

### Executables

| Directory | When to use |
|---|---|
| `bin/` | Executable entry points for CLIs, dev scripts |
| `cmd/` | Go-specific: one subdirectory per binary |

### Configuration

Most config files must live in the root (tooling expects them there). When a tool supports a config directory, use it to reduce root clutter.

**Must be in root:**
- `package.json`, `tsconfig.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `mix.exs`, `pubspec.yaml`
- `.gitignore`, `.gitattributes`, `.editorconfig`
- `Makefile`, `Justfile`, `Taskfile.yml`
- `Dockerfile`, `docker-compose.yml`

**Can be consolidated (prefer this):**
- Python: put tool configs in `pyproject.toml` (ruff, mypy, pytest, black all support it)
- JS/TS: put tool configs in `package.json` where supported (jest, eslint less so with flat config)
- Config directory: `.config/` for tools that support it

### Assets and static files

| Directory | When to use |
|---|---|
| `assets/` | Images, fonts, icons used in documentation or the project itself |
| `public/` | Static files served as-is by web frameworks (Next.js, Vite, CRA) |
| `static/` | Alternative to `public/` in some frameworks (Hugo, Gatsby) |
| `resources/` | Java/Kotlin convention for non-code resources |

### Build output

**Never committed to git.** Always in `.gitignore`.

| Directory | Ecosystem |
|---|---|
| `dist/` | JS/TS compiled output |
| `build/` | General build output, C/C++ |
| `target/` | Rust (Cargo), Java (Maven/Gradle) |
| `out/` | Next.js, some Java projects |
| `bin/` | Go compiled binaries (when used as output, not source) |
| `__pycache__/` | Python bytecode |
| `.next/` | Next.js build cache |
| `node_modules/` | Node.js dependencies |
| `.venv/`, `venv/` | Python virtual environments |

---

## Stack-specific canonical structures

For each ecosystem: the canonical folder tree, what is enforced by tooling vs. convention only, and standard `.gitignore` entries.

### JavaScript / TypeScript

```
project-root/
  src/
    index.ts               # Library entry point
    components/             # React/Vue components (if applicable)
    hooks/                  # React hooks (if applicable)
    utils/                  # Utility functions
    types/                  # Shared TypeScript types
  tests/                    # Or __tests__/ colocated with src/
  docs/
  scripts/
  public/                   # Static assets (web apps)
  .github/
  package.json
  tsconfig.json
  eslint.config.js          # ESLint v9 flat config (or biome.json)
  .prettierrc               # If not using Biome
  vitest.config.ts           # Or jest.config.ts
  .editorconfig
  .gitignore
  .gitattributes
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
```

**Framework overrides:**

| Framework | Source directory | Convention |
|---|---|---|
| Next.js (App Router) | `app/` | `app/page.tsx`, `app/layout.tsx`, `app/api/route.ts` |
| Next.js (Pages) | `pages/` | `pages/index.tsx`, `pages/api/hello.ts` |
| Remix | `app/` | `app/routes/`, `app/root.tsx` |
| Vite / CRA | `src/` | `src/main.tsx`, `src/App.tsx` |
| NestJS | `src/` | `src/app.module.ts`, `src/main.ts` |
| Express | `src/` | `src/index.ts`, `src/routes/`, `src/middleware/` |

**Enforced vs. convention:**
- `node_modules/` location: enforced by npm/yarn/pnpm
- `package.json` in root: enforced by all package managers
- `tsconfig.json` in root: enforced by TypeScript compiler
- `src/` directory: convention only (configurable in tsconfig)
- Component naming PascalCase: convention only (but universal)

**Standard .gitignore:**
```gitignore
node_modules/
dist/
build/
.next/
out/
coverage/
*.tsbuildinfo
.env
.env.local
.env.*.local
.DS_Store
*.log
```

### Python

```
project-root/
  src/
    package_name/           # The actual package (snake_case)
      __init__.py
      module.py
      subpackage/
        __init__.py
  tests/
    __init__.py
    test_module.py
    conftest.py             # Pytest fixtures
  docs/
  scripts/
  pyproject.toml            # Project metadata, build system, tool config
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  .python-version           # pyenv version pinning
  Makefile                  # Standard targets: install, test, lint, format
```

**The `src/` layout vs. flat layout:**

| Layout | Structure | When to use |
|---|---|---|
| **src layout** (recommended) | `src/package_name/` | Libraries, packages distributed via PyPI |
| **Flat layout** | `package_name/` in root | Simple scripts, small applications |

The `src/` layout prevents accidental imports of the development version during testing. Use it for anything published to PyPI.

**Enforced vs. convention:**
- `__init__.py` for packages: enforced by Python import system (optional in some cases with namespace packages)
- `pyproject.toml`: enforced by PEP 621 / build tools (setuptools, hatch, poetry, flit)
- `snake_case` for modules: PEP 8 convention, enforced by Ruff
- `tests/` directory: convention (pytest auto-discovers)
- `conftest.py`: recognized by pytest (enforced name)
- `src/` layout: convention only

**Standard .gitignore:**
```gitignore
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.eggs/
*.egg
.venv/
venv/
.env
.mypy_cache/
.ruff_cache/
.pytest_cache/
htmlcov/
.coverage
*.so
.DS_Store
```

### Go

```
project-root/
  cmd/
    myapp/                  # One directory per binary
      main.go
  internal/                 # Non-importable packages
    server/
      server.go
    database/
      database.go
  pkg/                      # Importable library code (use sparingly)
  api/                      # API definitions (protobuf, OpenAPI)
  web/                      # Web assets (if applicable)
  scripts/
  docs/
  go.mod
  go.sum
  Makefile
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  .golangci.yml             # golangci-lint config
```

**For a library (no `cmd/`):**
```
project-root/
  parser.go
  parser_test.go
  lexer.go
  lexer_test.go
  internal/
    detail.go
  go.mod
  go.sum
```

Go libraries keep `.go` files in the root package. No `src/` directory. Tests are colocated (same directory, `_test.go` suffix).

**Enforced vs. convention:**
- `go.mod` in module root: enforced by Go modules
- `internal/` visibility restriction: enforced by the Go compiler
- `_test.go` suffix for tests: enforced by `go test`
- `cmd/` for binaries: convention (but near-universal)
- `pkg/` for library code: convention (increasingly discouraged -- put code in root or `internal/`)
- Lowercase package names: enforced by Go compiler

**Standard .gitignore:**
```gitignore
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test artifacts
*.test
*.out
coverage.out

# Build
/bin/

# IDE
.idea/
.vscode/
*.swp
.DS_Store

# Vendor (if not vendoring)
# vendor/
```

### Rust

```
project-root/
  src/
    main.rs                 # Binary entry point
    lib.rs                  # Library entry point
    module_name/
      mod.rs
  tests/                    # Integration tests
    integration_test.rs
  benches/                  # Benchmarks
    benchmark.rs
  examples/                 # Example programs
    basic.rs
  docs/
  scripts/
  Cargo.toml
  Cargo.lock                # Commit for binaries, gitignore for libraries
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  rust-toolchain.toml       # Pin Rust version
  clippy.toml               # Clippy config (optional)
  rustfmt.toml              # Formatting config (optional)
```

**Workspace (multi-crate):**
```
project-root/
  Cargo.toml                # [workspace] definition
  crates/
    core/
      Cargo.toml
      src/
        lib.rs
    cli/
      Cargo.toml
      src/
        main.rs
```

**Enforced vs. convention:**
- `Cargo.toml` in root: enforced by Cargo
- `src/main.rs` or `src/lib.rs`: enforced by Cargo (default entry points)
- `tests/` for integration tests: enforced by Cargo
- `benches/` for benchmarks: enforced by Cargo
- `examples/` for examples: enforced by Cargo
- `snake_case` for files and modules: enforced by Rust compiler warnings

**Standard .gitignore:**
```gitignore
/target/
**/*.rs.bk
Cargo.lock          # Only for libraries; commit for binaries
.DS_Store
```

### Java / Kotlin

```
project-root/
  src/
    main/
      java/                 # Or kotlin/
        com/example/project/
          Application.java
          service/
          controller/
          model/
          repository/
      resources/
        application.yml     # Spring Boot config
  src/
    test/
      java/
        com/example/project/
          ApplicationTest.java
      resources/
  docs/
  scripts/
  build.gradle.kts          # Or pom.xml for Maven
  settings.gradle.kts
  gradle/
    wrapper/
      gradle-wrapper.jar
      gradle-wrapper.properties
  gradlew
  gradlew.bat
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
```

**Enforced vs. convention:**
- `src/main/java/` and `src/test/java/`: enforced by Maven/Gradle (default source sets)
- `src/main/resources/`: enforced by Maven/Gradle
- Package structure matching directory: enforced by Java compiler
- `PascalCase` for class files: enforced by Java compiler
- Gradle wrapper files: convention (but universal for reproducibility)

**Standard .gitignore:**
```gitignore
# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar

# Maven
target/

# IDE
.idea/
*.iml
.project
.classpath
.settings/
out/
*.class

# Environment
.env
.DS_Store
```

### Ruby

```
project-root/
  lib/
    gem_name/
      version.rb
      module.rb
    gem_name.rb              # Main require entry point
  spec/                      # Or test/ for Minitest
    spec_helper.rb
    gem_name/
      module_spec.rb
  bin/                       # CLI executables
    console
  sig/                       # RBS type signatures (optional)
  docs/
  scripts/
  gem_name.gemspec
  Gemfile
  Gemfile.lock               # Commit for apps, gitignore for gems
  Rakefile
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  .rubocop.yml
  .ruby-version
```

**Rails application:**
```
project-root/
  app/
    controllers/
    models/
    views/
    jobs/
    mailers/
    channels/
  config/
  db/
    migrate/
    seeds.rb
  lib/
  spec/                      # Or test/
  public/
  log/
  tmp/
  Gemfile
  Gemfile.lock
  Rakefile
  config.ru
```

**Enforced vs. convention:**
- `lib/` structure: enforced by Bundler's `require` resolution
- `spec/` or `test/`: convention (RSpec discovers `spec/`, Minitest discovers `test/`)
- Rails directory structure: enforced by Rails autoloader
- `snake_case` for all files: convention, enforced by RuboCop
- `.gemspec` in root: enforced by RubyGems

**Standard .gitignore:**
```gitignore
/.bundle/
/vendor/bundle
/tmp/
/log/
*.gem
.byebug_history
.env
.DS_Store

# Rails-specific
/db/*.sqlite3
/db/*.sqlite3-journal
/storage/
/public/packs
/public/packs-test
/node_modules
/yarn-error.log
```

### C# / .NET

```
project-root/
  src/
    ProjectName/
      ProjectName.csproj
      Program.cs
      Services/
      Models/
      Controllers/
  tests/
    ProjectName.Tests/
      ProjectName.Tests.csproj
      ServiceTests.cs
  docs/
  scripts/
  ProjectName.sln
  Directory.Build.props       # Shared build properties
  global.json                 # SDK version pinning
  nuget.config                # NuGet feed config (optional)
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
```

**Enforced vs. convention:**
- `.csproj` per project: enforced by .NET SDK
- `.sln` referencing projects: enforced by Visual Studio / dotnet CLI
- `PascalCase` for files and directories: convention (strong, matches namespace)
- `src/` and `tests/` separation: convention (but recommended by .NET team)
- `Directory.Build.props`: recognized by MSBuild (enforced name)

**Standard .gitignore:**
```gitignore
bin/
obj/
.vs/
*.user
*.suo
*.DotSettings.user
TestResults/
*.nupkg
.env
.DS_Store

# NuGet
packages/
```

### Swift

```
project-root/
  Sources/
    PackageName/
      PackageName.swift
      Models/
      Services/
  Tests/
    PackageNameTests/
      PackageNameTests.swift
  docs/
  scripts/
  Package.swift               # SPM manifest
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  .swiftlint.yml
```

**Xcode project (iOS/macOS app):**
```
project-root/
  AppName/
    AppNameApp.swift
    ContentView.swift
    Models/
    Views/
    Services/
    Assets.xcassets/
    Info.plist
  AppNameTests/
  AppNameUITests/
  AppName.xcodeproj/          # Or .xcworkspace with SPM
```

**Enforced vs. convention:**
- `Sources/` and `Tests/`: enforced by Swift Package Manager (exact names, PascalCase)
- `Package.swift` in root: enforced by SPM
- `PascalCase` for files: convention (matches type names)
- Xcode project structure: enforced by Xcode

**Standard .gitignore:**
```gitignore
.build/
.swiftpm/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
.DS_Store
Packages/
Package.resolved        # Commit for apps, gitignore for libraries
```

### PHP

```
project-root/
  src/
    Controller/
    Model/
    Service/
    Repository/
  tests/
    Unit/
    Feature/
  config/
  public/
    index.php               # Web entry point
  resources/
    views/
  database/
    migrations/
    seeders/
  storage/
  docs/
  scripts/
  composer.json
  composer.lock
  phpunit.xml
  phpstan.neon              # Or psalm.xml
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
  .php-cs-fixer.php         # Code style config
```

**Laravel application:**
```
project-root/
  app/
    Http/
      Controllers/
      Middleware/
    Models/
    Providers/
  config/
  database/
    migrations/
    seeders/
  public/
  resources/
    views/
    css/
    js/
  routes/
    web.php
    api.php
  storage/
  tests/
  artisan
  composer.json
```

**Enforced vs. convention:**
- PSR-4 autoloading namespace-to-directory mapping: enforced by Composer
- `PascalCase` for class files: enforced by PSR-4
- `composer.json` in root: enforced by Composer
- `public/` as web root: convention (but universal for security)
- Laravel directory structure: enforced by the framework

**Standard .gitignore:**
```gitignore
/vendor/
node_modules/
.env
.phpunit.result.cache
Homestead.yaml
Homestead.json
npm-debug.log
yarn-error.log
.DS_Store

# Laravel-specific
/storage/*.key
/public/hot
/public/storage
/bootstrap/cache/*
```

### Elixir

```
project-root/
  lib/
    app_name/
      application.ex
      module.ex
    app_name.ex             # Main module
  test/
    app_name/
      module_test.exs
    test_helper.exs
  priv/                     # Static assets, migrations
    repo/
      migrations/
    static/
  config/
    config.exs
    dev.exs
    prod.exs
    test.exs
    runtime.exs
  docs/
  scripts/
  mix.exs
  mix.lock
  .formatter.exs
  .credo.exs                # Credo linter config
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
```

**Phoenix application:**
```
project-root/
  lib/
    app_name/               # Business logic (context modules)
    app_name_web/            # Web layer
      controllers/
      components/
      live/                  # LiveView
      router.ex
      endpoint.ex
  assets/
    css/
    js/
  priv/
    repo/migrations/
    static/
  test/
    app_name/
    app_name_web/
  config/
  mix.exs
```

**Enforced vs. convention:**
- `lib/` for source: enforced by Mix
- `test/` for tests: enforced by Mix
- `priv/` for static assets: enforced by OTP release conventions
- `config/` for configuration: enforced by Mix
- `mix.exs` in root: enforced by Mix
- `snake_case` for files: convention (matches Elixir module naming)

**Standard .gitignore:**
```gitignore
/_build/
/cover/
/deps/
/doc/
erl_crash.dump
*.ez
*.beam
/config/*.secret.exs
.env
.DS_Store

# Phoenix
/priv/static/assets/
/tmp/
```

### C / C++

```
project-root/
  include/
    project_name/           # Public headers
      header.h
  src/
    main.cpp
    module.cpp
  tests/
    test_module.cpp
  lib/                      # Third-party libraries (or use package manager)
  docs/
  scripts/
  build/                    # Out-of-source build (gitignored)
  cmake/                    # CMake modules
  CMakeLists.txt
  .clang-format
  .clang-tidy
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
```

**Header-only library:**
```
project-root/
  include/
    library_name/
      library.hpp
  tests/
  examples/
  CMakeLists.txt
```

**Enforced vs. convention:**
- `CMakeLists.txt` location: enforced by CMake
- `include/` for public headers: convention (but universal for installed libraries)
- `src/` for implementation: convention
- `.clang-format` in root: recognized by clang-format (walks up to find it)
- Everything else: convention only -- C/C++ has the least enforced structure

**Standard .gitignore:**
```gitignore
build/
cmake-build-*/
*.o
*.obj
*.so
*.dylib
*.dll
*.a
*.lib
*.exe
*.out
*.app
compile_commands.json
.cache/
.DS_Store
.vscode/
.idea/
```

### Dart / Flutter

```
project-root/
  lib/
    src/                    # Private implementation
      widgets/
      services/
      models/
    main.dart               # Or package entry point
  test/
    widget_test.dart
  integration_test/         # Integration/E2E tests
  assets/                   # Images, fonts
  docs/
  scripts/
  pubspec.yaml
  pubspec.lock
  analysis_options.yaml     # Dart analyzer / lint rules
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
  .gitattributes
```

**Flutter application:**
```
project-root/
  lib/
    main.dart
    app/
    features/
      feature_name/
        data/
        domain/
        presentation/
    core/
  test/
  integration_test/
  android/
  ios/
  web/
  macos/
  linux/
  windows/
  assets/
  pubspec.yaml
```

**Enforced vs. convention:**
- `lib/` for source: enforced by Dart package system
- `test/` for tests: enforced by `dart test` / `flutter test`
- `pubspec.yaml` in root: enforced by Dart/Flutter
- `analysis_options.yaml`: recognized by Dart analyzer
- Platform directories (`android/`, `ios/`, etc.): enforced by Flutter
- `snake_case` for files: enforced by Dart linter (file_names rule)

**Standard .gitignore:**
```gitignore
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
*.iml
.idea/
.DS_Store

# Flutter
/android/app/debug
/android/app/profile
/android/app/release
/ios/Flutter/
/ios/Pods/
```

---

### Zig

Zig is a systems-programming language positioned as a modern alternative to Rust and C — explicit memory management, no hidden control flow, and a toolchain that ships compiler, build system, test runner, and formatter in one binary. Pin to **Zig 0.13.0** for examples; Zig is pre-1.0 and language semantics change between minor releases.

```
zig-cli-tool/
  src/
    main.zig                # Entry point (pub fn main)
    root.zig                # Optional library surface
    commands/               # Convention for CLI subcommands
      build.zig
      run.zig
  tests/
    integration_test.zig    # Optional — most tests live inline via test blocks
  build.zig                 # Build script (REQUIRED, root-only)
  build.zig.zon             # Manifest + dependencies (Zig 0.11+)
  zig-out/                  # Build output (gitignored)
  .zig-cache/               # Per-project cache (Zig 0.13+; gitignored)
  zig-cache/                # Legacy cache name (Zig <=0.12; gitignored)
  docs/
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .gitattributes
```

**Library layout** (single `src/root.zig` entry point instead of `main.zig`):
```
zig-lib/
  src/
    root.zig                # pub fn + re-exports
  build.zig
  build.zig.zon
  examples/
    basic.zig
```

**Enforced vs. convention:**
- `build.zig` at repo root: enforced by the Zig toolchain (`zig build` looks here)
- `build.zig.zon` filename: enforced by Zig 0.11+ when using package deps
- `src/main.zig` vs `src/root.zig`: convention (executable vs library idiom)
- `zig-out/` and `.zig-cache/` / `zig-cache/`: hard-coded output/cache names, always gitignore
- `tests/` directory: convention only — Zig allows `test "name" { ... }` blocks inline in any module
- Zig does not have "zero-cost abstractions" hidden under macros; every allocation is explicit via `std.mem.Allocator`

**Standard .gitignore:**
```gitignore
# Zig build output + cache
zig-out/
zig-cache/
.zig-cache/

# Binaries and object files
*.o
*.obj
*.a
*.lib
*.exe
*.out

# Debug/crash artifacts
core
*.core
vgcore.*

# Editor + OS
.vscode/
.idea/
.DS_Store
```

---

### Gleam

Gleam is a statically-typed functional language that runs on the BEAM (Erlang virtual machine), with first-class interop into Erlang and Elixir via Hex. Pin examples to **Gleam 1.4+** on **OTP 27.x**. Idiomatic Gleam uses the pipe operator (`|>`) heavily — snippets should reflect that.

```
gleam_app/
  src/
    gleam_app.gleam         # Entry module (matches package name)
    gleam_app/
      router.gleam          # Submodules under the package namespace
      models.gleam
  test/
    gleam_app_test.gleam    # gleeunit convention: <module>_test.gleam
  build/                    # Compiler output (gitignored)
  deps/                     # Fetched Hex deps (gitignored)
  gleam.toml                # Manifest (name, version, deps, targets)
  manifest.toml             # Lockfile — COMMIT this
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .gitattributes
```

**Idiomatic test snippet** (`test/gleam_app_test.gleam`):
```gleam
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn pipe_test() {
  "  hello  "
  |> string.trim
  |> string.uppercase
  |> should.equal("HELLO")
}
```

**Enforced vs. convention:**
- `gleam.toml` filename + schema: enforced by the Gleam compiler
- `manifest.toml` (lockfile): generated and read by `gleam deps`; COMMIT it
- `src/<package_name>.gleam` entry module: convention, but `gleam run` looks for it
- `test/` directory + `_test.gleam` suffix: enforced by gleeunit (the default test runner)
- `build/` and `deps/`: auto-generated, always gitignore
- BEAM interop: Gleam modules can `@external(erlang, ...)` into Erlang and call Elixir modules directly; same Hex package index

**Standard .gitignore:**
```gitignore
# Gleam build output + deps
build/
deps/

# BEAM crash dumps
erl_crash.dump

# Editor + OS
.DS_Store
.idea/
.vscode/
```

---

### Deno

Deno is a JavaScript/TypeScript runtime with built-in tooling (formatter, linter, type checker, test runner, bundler, JSR publisher) and secure-by-default permissions. Distinct enough from Node that it warrants its own layout — no `node_modules/`, no `package.json`, URL/JSR-based imports. Pin examples to **Deno 2.x** (v2 was the API-stability release) and use `jsr:@scope/mod` imports, not legacy `https://deno.land/std/...`.

```
my-deno-lib/
  src/
    mod.ts                  # Public entry (or use root mod.ts — both common)
    handlers.ts
    types.ts
  tests/
    mod_test.ts             # Deno convention: <name>_test.ts
  scripts/
    build.ts                # Deno tasks live in deno.json, scripts are optional
  deno.json                 # Manifest: tasks, imports, fmt/lint/test config
  deno.lock                 # Lockfile — COMMIT this
  import_map.json           # Optional — legacy; prefer deno.json "imports"
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .gitattributes
```

**JSR-publishable library** (minimal — `mod.ts` at root is idiomatic for small libs):
```
deno-lib/
  mod.ts                    # Root entry, re-exports the public API
  src/
    internal.ts
  deno.json                 # Must contain "name", "version", "exports"
  deno.lock
  README.md
```

**Deno application** (server, CLI, script):
```
deno-app/
  src/
    main.ts                 # Entry (deno run --allow-net src/main.ts)
    server.ts
  static/
  deno.json                 # Tasks: "dev", "start", "test"
  deno.lock
```

**Enforced vs. convention:**
- `deno.json` (or `deno.jsonc`) filename: enforced by the Deno CLI
- `deno.lock` filename: enforced; commit for reproducibility
- Layout itself (`src/`, `mod.ts` root): convention — Deno does not enforce a folder shape
- `_test.ts` / `.test.ts` suffix: enforced by `deno test` discovery
- Permissions (`--allow-net`, `--allow-read`): enforced at runtime; document required flags in README
- JSR imports (`jsr:@scope/pkg`) are the modern idiom; `import_map.json` is legacy vs `"imports"` in `deno.json`

**Standard .gitignore:**
```gitignore
# Deno cache and compile artifacts
.deno/
coverage/

# deno compile output (single-file binaries)
bin/
*.exe

# node_modules only if mixed-mode with npm: compat
node_modules/

# Editor + OS
.DS_Store
.idea/
.vscode/
```

---

### Bun

Bun is a Node-compatible runtime + package manager + test runner + bundler in a single binary. Choose between two usage modes up front:

**Bun-first vs Bun-drop-in — pick one:**

- **New JS/TS project in 2026+?** Bun-first — use `bun` as the runtime, commit `bun.lockb`, use `bun test`, skip `node_modules` conflicts.
- **Migrating a Node project and just want faster installs?** Bun-drop-in — keep Node as the runtime, use `bun install` only, and keep your existing `package-lock.json` (or switch to `bun.lockb` if you also want `bun test`).
- **Rule of thumb:** if you commit `bun.lockb`, you're Bun-first; if you commit `package-lock.json`, you're Bun-drop-in. Don't commit both.

Pin examples to **Bun 1.1+**. Bun is Node-compatible, so the folder shape mirrors Node.

```
bun-api/
  src/
    index.ts                # Entry (bun run src/index.ts)
    routes/
      users.ts
    services/
  tests/
    users.test.ts           # Bun picks up *.test.ts automatically
  dist/                     # Build output from bun build (gitignored)
  package.json              # Node-compatible manifest
  bun.lockb                 # Binary lockfile — commit (Bun-first)
  bunfig.toml               # Optional — Bun runtime config
  tsconfig.json
  biome.json                # Biome for fmt + lint (Bun does not ship a formatter)
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .gitattributes
```

**Minimal `bunfig.toml`** (optional — only needed if defaults don't fit):
```toml
[install]
# Use exact versions in package.json instead of carets
exact = true

[test]
# Bail after N failures
bail = 5
coverage = false
```

**Enforced vs. convention:**
- `package.json` at root: enforced (Node-compatible)
- `bun.lockb` is a **binary** lockfile — merge conflicts cannot be hand-resolved; regenerate via `bun install` and commit the new binary
- `bunfig.toml` filename: enforced only if you use it (optional)
- `*.test.ts` / `*_test.ts` discovery: enforced by `bun test`
- Bun workspaces: handled in `monorepo-patterns.md` — not covered here (single-package only)
- Bun respects `package.json` `"type": "module"`; match it to runtime expectations when migrating Node code

**Standard .gitignore:**
```gitignore
# Node-compatible
node_modules/
dist/
build/

# Bun
.bun/
*.log

# Bun doesn't use these, but include for mixed-mode repos:
.npm/
.yarn/

# Editor + OS
.DS_Store
.idea/
.vscode/
```

---

## Project type structures

### Monorepo

```
project-root/
  packages/                  # Or apps/ + packages/
    package-a/
      src/
      tests/
      package.json           # Per-package manifest
      README.md              # Per-package README
      CHANGELOG.md
    package-b/
      src/
      tests/
      package.json
      README.md
      CHANGELOG.md
  apps/                      # Applications that consume packages
    web/
    api/
  docs/
  scripts/
  .github/
  package.json               # Root workspace config
  turbo.json                 # Or nx.json, pnpm-workspace.yaml, lerna.json
  tsconfig.base.json         # Shared TypeScript config
  eslint.config.js           # Shared lint config
  README.md                  # Root README: overview, getting started, package index
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md               # Root changelog (optional if per-package)
  .editorconfig
  .gitignore
  .gitattributes
```

**Go monorepo (multi-module):**
```
project-root/
  services/
    api/
      go.mod
      main.go
    worker/
      go.mod
      main.go
  pkg/                       # Shared packages
    shared/
      go.mod
  tools/
```

**Python monorepo:**
```
project-root/
  packages/
    core/
      pyproject.toml
      src/core/
    api/
      pyproject.toml
      src/api/
```

**When to use:** Multiple related packages that are versioned independently, or apps that share code. Not for "I have a frontend and a backend" -- that's typically two repos or a simple `client/` + `server/` split.

### Microservices

```
project-root/
  services/
    user-service/
      src/
      tests/
      Dockerfile
      package.json            # Or go.mod, pyproject.toml, etc.
      README.md
    order-service/
      src/
      tests/
      Dockerfile
      package.json
      README.md
    notification-service/
      src/
      tests/
      Dockerfile
      package.json
      README.md
  shared/                     # Shared types, proto definitions
    proto/
    types/
  infrastructure/             # IaC, Kubernetes manifests
    k8s/
    terraform/
  docker-compose.yml
  docs/
    architecture.md
    service-map.md
  README.md
  LICENSE
  .editorconfig
  .gitignore
```

**When to use:** Multiple independently deployable services that communicate via APIs. Each service has its own build, test, and deploy pipeline.

### CLI tool

```
project-root/
  src/
    cli.ts                   # Entry point, argument parsing
    commands/
      init.ts
      build.ts
      serve.ts
    utils/
  tests/
  bin/
    mycli.js                 # Executable entry point (shebang line)
  docs/
    commands.md
  man/                       # Man pages (optional)
  completions/               # Shell completions (optional)
    mycli.bash
    mycli.zsh
    mycli.fish
  package.json
  tsconfig.json
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
```

**Go CLI:**
```
project-root/
  cmd/
    mycli/
      main.go
  internal/
    commands/
    config/
  docs/
  go.mod
```

**When to use:** A command-line tool distributed as a binary or via a package manager.

### Library / SDK

```
project-root/
  src/
    index.ts                 # Public API entry point
    module-a/
    module-b/
  tests/
    unit/
    integration/
  examples/                  # Usage examples (executable)
    basic.ts
    advanced.ts
  docs/
    api/                     # Generated API docs
  benchmarks/                # Performance benchmarks (optional)
  package.json
  tsconfig.json
  tsconfig.build.json        # Build-specific tsconfig (excludes tests)
  README.md
  LICENSE
  CONTRIBUTING.md
  CHANGELOG.md
  .editorconfig
  .gitignore
```

**Key difference from apps:** Libraries have `examples/`, API reference docs, a `files` or `.npmignore` for controlling published contents, and `Cargo.lock` / `package-lock.json` gitignored (not committed).

### Web application (SPA)

```
project-root/
  src/
    app/                     # Or pages/, routes/
    components/
      ui/                    # Primitive UI components
      features/              # Feature-specific components
    hooks/
    lib/                     # Utilities, API clients
    styles/
    types/
    assets/
  public/
  tests/
    e2e/                     # Playwright, Cypress
  docs/
  .env.example
  package.json
  tsconfig.json
  vite.config.ts
  README.md
  LICENSE
  .editorconfig
  .gitignore
```

### Web application (SSR / Full-stack)

```
project-root/
  app/                       # Next.js App Router
    (marketing)/              # Route groups
    (dashboard)/
    api/
    layout.tsx
    page.tsx
  components/
    ui/
    features/
  lib/
    db/                      # Database client, schema
    auth/                    # Auth configuration
    api/                     # API utilities
  public/
  tests/
  docs/
  prisma/                    # Or drizzle/, database/
    schema.prisma
    migrations/
  .env.example
  next.config.ts
  package.json
  tsconfig.json
  tailwind.config.ts
  README.md
  LICENSE
  .editorconfig
  .gitignore
```

### API server

```
project-root/
  src/
    routes/                  # Or controllers/
    middleware/
    services/                # Business logic
    models/                  # Or entities/, schemas/
    repositories/            # Data access layer (optional)
    utils/
    types/
    config/
  tests/
    unit/
    integration/
    fixtures/
  docs/
    api/                     # OpenAPI spec
  migrations/                # Database migrations
  scripts/
    seed.ts
  .env.example
  package.json
  tsconfig.json
  Dockerfile
  docker-compose.yml
  README.md
  LICENSE
  .editorconfig
  .gitignore
```

### Mobile application

```
project-root/
  # React Native
  src/
    screens/
    components/
    navigation/
    services/
    hooks/
    assets/
    types/
  android/
  ios/
  __tests__/
  app.json
  package.json
  metro.config.js
  tsconfig.json

  # Flutter (see Dart/Flutter section above)

  # Native iOS (see Swift section above)
```

### Desktop application

```
project-root/
  src/
    main/                    # Main process (Electron)
    renderer/                # Renderer process (Electron)
      # Or standard app structure for Tauri, native
    preload/
  resources/                 # App icons, installer assets
  scripts/
    build-installer.sh
  tests/
  docs/
  package.json
  electron-builder.yml       # Or tauri.conf.json
  README.md
  LICENSE
  .editorconfig
  .gitignore
```

### Data / ML

```
project-root/
  src/                       # Or package_name/
    data/                    # Data loading, preprocessing
    features/                # Feature engineering
    models/                  # Model definitions
    training/                # Training scripts
    evaluation/              # Evaluation and metrics
    serving/                 # Model serving / inference
  notebooks/                 # Jupyter notebooks (exploratory only)
  tests/
  data/                      # Data directory (gitignored, or DVC-tracked)
    raw/
    processed/
    external/
  models/                    # Trained model artifacts (gitignored, or DVC-tracked)
  configs/                   # Experiment configs (YAML)
  docs/
    model-card.md            # Model documentation
  scripts/
  pyproject.toml
  Makefile
  Dockerfile
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .dvc/                      # DVC config (if using Data Version Control)
  dvc.yaml
  dvc.lock
```

**Key rules:**
- Never commit large data files or model artifacts to git. Use DVC, Git LFS, or cloud storage.
- Notebooks are for exploration. Production code goes in `src/`.
- Every model needs a model card (`docs/model-card.md`).

### DevOps / Infrastructure as Code

```
project-root/
  modules/                   # Reusable Terraform modules
    networking/
      main.tf
      variables.tf
      outputs.tf
    compute/
  environments/              # Environment-specific configs
    dev/
      main.tf
      terraform.tfvars
    staging/
    production/
  scripts/
  docs/
    runbooks/
    architecture.md
  Makefile
  README.md
  LICENSE
  .editorconfig
  .gitignore
  .gitattributes
  .terraform-version         # tfenv version pinning
```

**Kubernetes:**
```
project-root/
  base/                      # Kustomize base
    deployment.yaml
    service.yaml
    kustomization.yaml
  overlays/
    dev/
    staging/
    production/
  charts/                    # Helm charts
    app-name/
      Chart.yaml
      values.yaml
      templates/
```

---

## Naming conventions

### Files and directories

| Ecosystem | File naming | Directory naming | Example |
|---|---|---|---|
| **JS/TS** | `kebab-case.ts` for utilities, `PascalCase.tsx` for components | `kebab-case/` | `date-utils.ts`, `UserProfile.tsx`, `hooks/` |
| **Python** | `snake_case.py` always | `snake_case/` | `user_service.py`, `data_loader/` |
| **Go** | `snake_case.go`, tests: `_test.go` suffix | `lowercase` (no separators) | `user_handler.go`, `middleware/` |
| **Rust** | `snake_case.rs` | `snake_case/` | `config_parser.rs`, `error_handling/` |
| **Java/Kotlin** | `PascalCase.java` matching class name | Reverse domain packages, `lowercase` | `UserService.java`, `com/example/service/` |
| **Ruby** | `snake_case.rb` | `snake_case/` | `user_service.rb`, `concerns/` |
| **C#/.NET** | `PascalCase.cs` matching class name | `PascalCase/` matching namespace | `UserService.cs`, `Services/` |
| **Swift** | `PascalCase.swift` | `PascalCase/` | `UserService.swift`, `Models/` |
| **PHP** | `PascalCase.php` for classes (PSR-4) | `PascalCase/` | `UserService.php`, `Controllers/` |
| **Elixir** | `snake_case.ex` / `.exs` | `snake_case/` | `user_service.ex`, `contexts/` |
| **C/C++** | `snake_case.cpp` / `.hpp` or `snake_case.c` / `.h` | `snake_case/` | `config_parser.cpp`, `include/` |
| **Dart** | `snake_case.dart` | `snake_case/` | `user_service.dart`, `widgets/` |

### Branch naming

```
# Pattern: type/optional-ticket-description
feature/PROJ-123-add-user-auth
fix/null-pointer-on-empty-cart
hotfix/v2.3.1-memory-leak
docs/update-api-reference
chore/upgrade-dependencies
refactor/extract-payment-module
test/add-e2e-checkout-flow
```

**Rules:**
- Lowercase with hyphens (`kebab-case`)
- Type prefix: `feature/`, `fix/`, `hotfix/`, `chore/`, `docs/`, `refactor/`, `test/`
- Include ticket number if the project uses an issue tracker
- Keep under 50 characters after the type prefix
- Never use spaces, underscores, or uppercase in branch names

### Commit messages

Conventional Commits format:

```
type(scope): imperative description

feat(auth): add OAuth2 login flow
fix(api): handle timeout in payment webhook
docs(readme): add deployment section
test(cart): add edge case for empty cart
chore(deps): update lodash to 4.17.21
ci: add Node 22 to test matrix
refactor(db): extract connection pool config
perf(query): add index for user lookup
build: switch from webpack to vite
style: apply prettier formatting
revert: revert "feat(auth): add OAuth2 login flow"
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Breaking changes:** Add `!` after type or `BREAKING CHANGE:` in footer:
```
feat(api)!: remove deprecated v1 endpoints

BREAKING CHANGE: v1 API endpoints have been removed. Migrate to v2.
```

### Tags

```
v1.0.0               # Release
v1.0.0-beta.1        # Pre-release
v1.0.0-rc.1          # Release candidate
v1.0.0-alpha.3       # Alpha
```

Always use `v` prefix. Always use Semantic Versioning. Pre-release identifiers use dot notation.

### Environment files

```
.env                 # Local development (gitignored, NEVER committed)
.env.example         # Template with placeholder values (committed)
.env.local           # Local overrides (gitignored)
.env.development     # Environment-specific (gitignored unless placeholders)
.env.staging         # Environment-specific (gitignored unless placeholders)
.env.production      # Environment-specific (gitignored unless placeholders)
.env.test            # Test environment (gitignored)
```

**Rules:**
- `.env` and all environment-specific `.env.*` files are gitignored
- Only `.env.example` is committed -- it contains placeholder values showing required variables
- Never put real secrets in `.env.example`
- Use descriptive placeholder values: `DATABASE_URL=postgresql://user:password@localhost:5432/dbname`

### Config files per ecosystem

| Ecosystem | Consolidated config | Standalone configs |
|---|---|---|
| **JS/TS** | `package.json` (some tools) | `tsconfig.json`, `eslint.config.js`, `vitest.config.ts`, `biome.json` |
| **Python** | `pyproject.toml` (ruff, mypy, pytest, black, isort, coverage) | `tox.ini` (if using tox) |
| **Go** | None -- Go has minimal config | `.golangci.yml` |
| **Rust** | `Cargo.toml` (most config) | `clippy.toml`, `rustfmt.toml` |
| **Java** | `build.gradle.kts` / `pom.xml` | `checkstyle.xml`, `spotbugs.xml` |
| **Ruby** | None | `.rubocop.yml`, `.rspec` |
| **C#** | `.csproj` files, `Directory.Build.props` | `.editorconfig` (extensive for C#) |

**Prefer consolidation.** If a tool supports configuration in the project's main manifest (`pyproject.toml`, `package.json`, `Cargo.toml`), put it there instead of creating another dotfile in the root.

---

## Hidden and dotfile conventions

### Universal (every project)

| File | Purpose | Priority |
|---|---|---|
| `.gitignore` | Files git should never track | Critical |
| `.gitattributes` | Line ending normalization, LFS, linguist overrides | High |
| `.editorconfig` | Consistent formatting across editors | High |

**Minimal `.gitattributes`:**
```gitattributes
# Normalize line endings
* text=auto

# Explicitly declare text files
*.md text diff=markdown
*.ts text diff=typescript
*.js text diff=javascript
*.json text
*.yml text
*.yaml text

# Declare binary files
*.png binary
*.jpg binary
*.gif binary
*.ico binary
*.woff2 binary

# Linguist overrides (for GitHub language detection)
docs/ linguist-documentation
vendor/ linguist-vendored
*.generated.* linguist-generated
```

**Minimal `.editorconfig`:**
```editorconfig
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[*.py]
indent_size = 4

[*.go]
indent_style = tab

[*.rs]
indent_size = 4

[Makefile]
indent_style = tab
```

### Version managers

| File | Tool | Ecosystem |
|---|---|---|
| `.nvmrc` or `.node-version` | nvm, fnm, volta | Node.js |
| `.python-version` | pyenv | Python |
| `.ruby-version` | rbenv, rvm | Ruby |
| `.tool-versions` | asdf | Multi-language |
| `rust-toolchain.toml` | rustup | Rust |
| `.java-version` | jenv | Java |
| `.go-version` | goenv | Go |
| `global.json` | .NET SDK | C#/.NET |
| `.flutter-version` | fvm | Flutter |
| `.terraform-version` | tfenv | Terraform |

**Rule:** Commit version pinning files. They ensure all developers and CI use the same toolchain version.

### Linter and formatter configs

| Ecosystem | Linter config | Formatter config |
|---|---|---|
| **JS/TS** | `eslint.config.js` (flat config, v9+) or `biome.json` | `.prettierrc` / `.prettierignore` or `biome.json` |
| **Python** | `pyproject.toml` [tool.ruff] | `pyproject.toml` [tool.ruff.format] |
| **Go** | `.golangci.yml` | `gofmt` (no config -- zero-config) |
| **Rust** | `clippy.toml` | `rustfmt.toml` |
| **Java** | `checkstyle.xml` or `config/detekt/detekt.yml` | Built into checkstyle or IDE |
| **Ruby** | `.rubocop.yml` | Built into RuboCop |
| **C#** | `.editorconfig` (extensive rule sets) | `.editorconfig` or `.globalconfig` |
| **Swift** | `.swiftlint.yml` | `.swiftformat` (if using SwiftFormat) |
| **PHP** | `phpstan.neon` or `psalm.xml` | `.php-cs-fixer.php` or `.pint.json` |
| **Elixir** | `.credo.exs` | `.formatter.exs` |
| **C/C++** | `.clang-tidy` | `.clang-format` |
| **Dart** | `analysis_options.yaml` | `dart format` (no config -- zero-config) |

### CI/CD platform configs

| File | Platform |
|---|---|
| `.github/workflows/*.yml` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| `.circleci/config.yml` | CircleCI |
| `Jenkinsfile` | Jenkins |
| `.travis.yml` | Travis CI (legacy) |

### Container and infrastructure

| File | Purpose |
|---|---|
| `Dockerfile` | Container image definition |
| `.dockerignore` | Files excluded from Docker build context |
| `docker-compose.yml` | Local multi-container development |
| `.devcontainer/devcontainer.json` | VS Code Dev Containers |
| `.devcontainer/Dockerfile` | Dev container image |

---

## Anti-patterns

### God folders

**Problem:** A single `utils/`, `helpers/`, `common/`, or `shared/` directory that grows to contain everything that doesn't fit elsewhere.

**Symptoms:**
- `src/utils/` has 50+ files covering auth, formatting, validation, API calls, and date math
- Multiple "utility" directories exist: `utils/`, `helpers/`, `lib/`, `common/`, `shared/`
- New developers can't find anything without grepping

**Fix:** Break utilities by domain. `src/auth/utils.ts`, `src/formatting/currency.ts`, `src/validation/email.ts`. If a utility is used by exactly one module, it belongs in that module, not in a global util folder.

### Deep nesting

**Problem:** Directory trees nested 5+ levels deep.

**Symptoms:**
```
# Bad
src/modules/user/features/profile/components/avatar/hooks/useAvatar.ts
```

**Fix:** Flatten to 2-3 levels. Group by feature, not by technical role:
```
# Good
src/features/user-profile/
  UserAvatar.tsx
  useAvatar.ts
  user-profile.test.ts
```

**Rule of thumb:** If a file path has more than 4 segments after `src/`, the nesting is too deep.

### Mixed naming conventions

**Problem:** The same repo uses `camelCase`, `PascalCase`, `snake_case`, and `kebab-case` for the same type of file.

**Symptoms:**
```
# Bad
src/
  UserService.ts
  order-service.ts
  payment_service.ts
  inventoryservice.ts
```

**Fix:** Pick the ecosystem convention (see naming table above) and enforce it with a linter rule. One style, everywhere, always.

### Committed build artifacts

**Problem:** Build output (`dist/`, `build/`, `node_modules/`, `__pycache__/`, `target/`) checked into git.

**Symptoms:**
- Repository size is 500MB+ for a small project
- `git diff` shows thousands of changed files after a build
- PRs include minified JavaScript or compiled bytecode

**Fix:** Add all build directories to `.gitignore` before the first commit. If they're already committed, remove them with `git rm -r --cached <dir>` and add to `.gitignore`.

### Committed secrets

**Problem:** `.env` files, API keys, passwords, private keys, or tokens checked into git.

**Symptoms:**
- `.env` file with real database URLs and API keys in the repo
- `config.json` with `"api_key": "sk-..."` committed
- Private keys (`.pem`, `.key`) in the repo

**Fix:**
1. Remove the secret from git history (use `git filter-repo` or BFG Repo-Cleaner)
2. Rotate every exposed credential immediately
3. Add `.env`, `*.pem`, `*.key`, `*.p12` to `.gitignore`
4. Commit only `.env.example` with placeholder values
5. Enable GitHub secret scanning on the repository

### Dead code directories

**Problem:** Directories that exist but contain no meaningful content -- empty folders, abandoned experiments, or code nobody references.

**Symptoms:**
- `src/legacy/` or `src/old/` directories
- `experiments/` with 6-month-old notebooks nobody uses
- Directories with only a `.gitkeep` file

**Fix:** Delete them. If the code has historical value, it lives in git history. An empty directory with `.gitkeep` that has no planned content should not exist -- create directories when they have content, not before.

### Config file explosion

**Problem:** The project root has 15+ dotfiles and config files.

**Symptoms:**
```
# Bad root
.babelrc
.browserslistrc
.commitlintrc.js
.editorconfig
.env.example
.eslintrc.js
.gitattributes
.gitignore
.huskyrc
.lintstagedrc
.npmrc
.nvmrc
.prettierrc
.stylelintrc
jest.config.js
postcss.config.js
tailwind.config.js
tsconfig.json
webpack.config.js
```

**Fix:**
- Consolidate where possible: use `pyproject.toml` for all Python tool configs, `biome.json` to replace both ESLint and Prettier, `package.json` fields where supported
- Use modern tools with less config: Biome replaces ESLint + Prettier. Ruff replaces Black + isort + Flake8.
- Prefer `eslint.config.js` (flat config) over `.eslintrc` -- it's the modern standard and supports imports
- Check if the tool supports a `config/` subdirectory

### Wrong ecosystem files

**Problem:** Config files from the wrong ecosystem in a project.

**Symptoms:**
- `.npmrc` in a Python project
- `tox.ini` in a JavaScript project
- `Cargo.lock` in a Go project
- `.rubocop.yml` in a Rust project

**Fix:** Every config file in the root must correspond to a tool the project actually uses. Audit config files when taking over a project. Remove orphaned configs.
