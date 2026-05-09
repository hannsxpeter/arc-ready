# Quality Tooling Reference

This reference provides complete, paste-ready configuration for code quality tooling across every major stack. Each config is opinionated and production-tested. When multiple tools exist for the same job, one is recommended and the alternative is documented for migration scenarios.

The configs here are starting points calibrated for professional projects. Loosen rules for MVPs, tighten them for enterprise. But always start with something — adding linting to a 50,000-line codebase after the fact is exponentially harder than starting with it.

---

## 1. JavaScript / TypeScript

Two viable paths exist. Pick one and commit.

### Option A: Biome (recommended for new projects)

Biome replaces ESLint + Prettier in a single tool. It is faster (written in Rust), requires less configuration, and eliminates the ESLint-Prettier conflict dance. Use this for any new project started after 2024.

**Install:**

```bash
npm install --save-dev --exact @biomejs/biome
npx @biomejs/biome init
```

**biome.json** (complete):

```jsonc
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "organizeImports": {
    "enabled": true
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    // Enforce trailing newline for POSIX compatibility
    "lineEnding": "lf"
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "trailingCommas": "all",
      "semicolons": "always",
      "arrowParentheses": "always",
      // Consistent quote style in JSX
      "jsxQuoteStyle": "double"
    }
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      // Catch real bugs
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error",
        "useExhaustiveDependencies": "warn",
        "noUndeclaredVariables": "error"
      },
      // Enforce modern patterns
      "style": {
        "noNonNullAssertion": "warn",
        "useConst": "error",
        "useTemplate": "error",
        "noParameterAssign": "error"
      },
      // Prevent common mistakes
      "suspicious": {
        "noExplicitAny": "warn",
        "noArrayIndexKey": "warn",
        "noConsoleLog": "warn",
        "noDebugger": "error"
      },
      // Performance
      "performance": {
        "noAccumulatingSpread": "warn",
        "noDelete": "warn"
      },
      // Accessibility for React/JSX projects
      "a11y": {
        "recommended": true
      }
    }
  },
  "overrides": [
    {
      // Relax rules for test files
      "include": [
        "**/*.test.ts",
        "**/*.test.tsx",
        "**/*.spec.ts",
        "**/*.spec.tsx",
        "**/__tests__/**"
      ],
      "linter": {
        "rules": {
          "suspicious": {
            "noExplicitAny": "off",
            "noConsoleLog": "off"
          }
        }
      }
    },
    {
      // Config files may use require() and CommonJS
      "include": ["*.config.ts", "*.config.js", "*.config.mjs"],
      "linter": {
        "rules": {
          "style": {
            "noDefaultExport": "off"
          }
        }
      }
    }
  ]
}
```

**package.json scripts:**

```json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "ci:lint": "biome ci ."
  }
}
```

### Option B: ESLint v9 flat config + Prettier

Use this when you need ESLint plugins that Biome does not yet cover (e.g., `eslint-plugin-react-compiler`, specialized framework plugins). ESLint v9 uses flat config by default — do not use `.eslintrc.*` files.

**Install:**

```bash
npm install --save-dev eslint @eslint/js typescript-eslint \
  eslint-config-prettier eslint-plugin-import-x \
  prettier globals
```

**eslint.config.js** (complete):

```js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import-x';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default tseslint.config(
  // Global ignores — replaces .eslintignore
  {
    ignores: [
      'dist/**',
      'build/**',
      'coverage/**',
      'node_modules/**',
      '*.config.js',
      '*.config.mjs',
    ],
  },

  // Base JS rules
  js.configs.recommended,

  // TypeScript rules — type-aware linting
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
      globals: {
        ...globals.node,
        ...globals.browser,
      },
    },
  },

  // Import ordering and validation
  {
    plugins: { 'import-x': importPlugin },
    rules: {
      'import-x/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            ['parent', 'sibling'],
            'index',
            'type',
          ],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import-x/no-duplicates': 'error',
      'import-x/no-cycle': ['error', { maxDepth: 4 }],
    },
  },

  // Project-specific overrides
  {
    rules: {
      // Catch unused code
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          destructuredArrayIgnorePattern: '^_',
        },
      ],
      // Prevent floating promises (common source of bugs)
      '@typescript-eslint/no-floating-promises': 'error',
      // Require awaiting async functions
      '@typescript-eslint/no-misused-promises': 'error',
      // Ban console in production code
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      // Require strict equality
      eqeqeq: ['error', 'always'],
    },
  },

  // Relax rules for test files
  {
    files: ['**/*.test.ts', '**/*.test.tsx', '**/*.spec.ts', '**/__tests__/**'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-floating-promises': 'off',
      'no-console': 'off',
    },
  },

  // Prettier must be last — disables formatting rules that conflict
  prettier,
);
```

**.prettierrc** (complete):

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "endOfLine": "lf",
  "arrowParens": "always",
  "bracketSpacing": true,
  "jsxSingleQuote": false,
  "proseWrap": "preserve"
}
```

**.prettierignore:**

```
dist
build
coverage
node_modules
pnpm-lock.yaml
package-lock.json
```

**package.json scripts:**

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint --fix .",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "ci:lint": "eslint . && prettier --check ."
  }
}
```

### TypeScript configuration

**tsconfig.json** (strict, modern, for applications):

```jsonc
{
  "compilerOptions": {
    // Target modern runtimes — Node 20+ / modern browsers
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2023"],

    // Output
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,

    // Strictness — all of these matter, do not disable them
    "strict": true,
    "noUncheckedIndexedAccess": true, // Forces undefined checks on array/object access
    "noImplicitOverride": true,       // Requires 'override' keyword
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true, // Distinguishes undefined from missing
    "forceConsistentCasingInFileNames": true,

    // Module interop
    "esModuleInterop": true,
    "isolatedModules": true,     // Required for esbuild/swc/Vite
    "verbatimModuleSyntax": true, // Forces 'import type' for type-only imports

    // Emit control
    "skipLibCheck": true, // Skip .d.ts checking for speed
    "incremental": true   // Cache type-check results
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

**tsconfig.json** (for libraries — adds stricter emit requirements):

```jsonc
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    // Libraries must produce clean declarations
    "declaration": true,
    "declarationMap": true,
    // Composite enables project references for monorepos
    "composite": true,
    // Strip internal markers from declarations
    "stripInternal": true
  }
}
```

### Testing: Vitest vs Jest

**Vitest** (recommended for new projects — native ESM, TypeScript, fast):

**vitest.config.ts:**

```ts
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    // Use globals so tests don't need imports
    globals: true,
    // jsdom for React/DOM testing, 'node' for pure Node
    environment: 'node',
    // Where to find tests
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    // Coverage configuration
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      // What to measure
      include: ['src/**/*.{ts,tsx}'],
      // What to exclude
      exclude: [
        'src/**/*.test.{ts,tsx}',
        'src/**/*.spec.{ts,tsx}',
        'src/**/index.ts',       // Re-export barrels
        'src/**/*.d.ts',
        'src/types/**',
      ],
      // Enforce coverage minimums — prevent regression
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
    // Path aliases matching tsconfig
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
    // Setup files run before each test file
    setupFiles: ['./src/test/setup.ts'],
  },
});
```

**Jest** (for existing projects or when Vitest is not compatible):

**jest.config.ts:**

```ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts', '**/*.spec.ts'],
  // Transform TypeScript
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
        // Use ESM if your project uses it
        useESM: false,
      },
    ],
  },
  // Path aliases matching tsconfig
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  // Coverage
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
  ],
  coverageThreshold: {
    global: {
      statements: 80,
      branches: 75,
      functions: 80,
      lines: 80,
    },
  },
  // Clear mocks between tests
  clearMocks: true,
  restoreMocks: true,
};

export default config;
```

---

## 2. Python

### Ruff (recommended — replaces Flake8, Black, isort, pydocstyle, pyupgrade, and more)

Ruff is written in Rust, is 10-100x faster than the tools it replaces, and consolidates configuration into a single `pyproject.toml` section. There is no reason to use Flake8 + Black + isort separately on a new project.

**pyproject.toml** (complete `[tool.ruff]` section):

```toml
[tool.ruff]
# Target Python version — controls which syntax/builtins are allowed
target-version = "py312"
# Line length — matches Black default
line-length = 88
# Files to lint
include = ["*.py", "*.pyi", "pyproject.toml"]
# Files to skip
extend-exclude = [
    "migrations",
    ".venv",
    "build",
    "dist",
    "__pycache__",
    "*.egg-info",
]

[tool.ruff.lint]
# Rule sets to enable — each letter maps to a legacy tool
select = [
    "E",     # pycodestyle errors
    "W",     # pycodestyle warnings
    "F",     # pyflakes — unused imports, undefined names
    "I",     # isort — import sorting
    "N",     # pep8-naming — naming conventions
    "UP",    # pyupgrade — modernize syntax to target version
    "B",     # flake8-bugbear — common gotchas and design problems
    "A",     # flake8-builtins — prevent shadowing builtins
    "C4",    # flake8-comprehensions — simplify comprehensions
    "SIM",   # flake8-simplify — suggest simpler code
    "TCH",   # flake8-type-checking — move imports to TYPE_CHECKING blocks
    "RUF",   # Ruff-specific rules
    "PT",    # flake8-pytest-style — pytest best practices
    "S",     # flake8-bandit — security checks
    "DTZ",   # flake8-datetimez — enforce timezone-aware datetimes
    "PIE",   # flake8-pie — miscellaneous lints
    "T20",   # flake8-print — catch print statements
    "RSE",   # flake8-raise — raise improvements
    "RET",   # flake8-return — return statement checks
    "ARG",   # flake8-unused-arguments
    "ERA",   # eradicate — find commented-out code
    "PL",    # pylint subset
]

# Rules to ignore (with reasons)
ignore = [
    "E501",   # Line too long — handled by formatter
    "S101",   # assert used — fine in tests, caught by bandit in prod
    "PLR0913", # Too many arguments — sometimes unavoidable
    "PLR2004", # Magic value comparison — too noisy
]

# Per-file rule overrides
[tool.ruff.lint.per-file-ignores]
# Tests can use assert, print, magic numbers, and don't need docstrings
"tests/**/*.py" = ["S101", "T20", "PLR2004", "D"]
# Init files can have unused imports (re-exports)
"__init__.py" = ["F401"]
# Scripts and CLIs can use print
"scripts/**/*.py" = ["T20"]
# Config files
"conftest.py" = ["S101"]

[tool.ruff.lint.isort]
# isort configuration
known-first-party = ["your_package_name"]
# Force single-line imports for clarity
force-single-line = false
# Combine 'from' imports from the same module
combine-as-imports = true

[tool.ruff.lint.pydocstyle]
# Use Google-style docstrings
convention = "google"

[tool.ruff.format]
# Formatting options (replaces Black)
quote-style = "double"
indent-style = "space"
line-ending = "auto"
# Format docstrings
docstring-code-format = true
```

### Type checking: mypy or pyright

**mypy** (most common, better third-party stub coverage):

```toml
# In pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
# Disallow dynamic typing
disallow_any_generics = true
disallow_subclassing_any = true
disallow_untyped_calls = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
# Check untyped defs
check_untyped_defs = true
# Warn about unused ignores
warn_unused_ignores = true
# No implicit re-exports from __init__.py
no_implicit_reexport = true
# Strict equality checks
strict_equality = true

# Per-module overrides for third-party libraries without stubs
[[tool.mypy.overrides]]
module = ["some_untyped_lib.*"]
ignore_missing_imports = true
```

**pyright** (faster, better for VS Code, more strict by default):

```toml
# In pyproject.toml
[tool.pyright]
pythonVersion = "3.12"
# "strict" enables all type checks
typeCheckingMode = "strict"
# Report specifics
reportMissingImports = true
reportMissingTypeStubs = false
reportUnusedImport = true
reportUnusedVariable = true
reportUnnecessaryTypeIgnoreComment = true
# Include/exclude
include = ["src"]
exclude = [
    "**/__pycache__",
    "**/node_modules",
    ".venv",
    "build",
    "dist",
]
```

### pytest configuration

```toml
# In pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
# Test file patterns
python_files = ["test_*.py", "*_test.py"]
python_functions = ["test_*"]
python_classes = ["Test*"]
# CLI options: verbose, short traceback, strict markers
addopts = [
    "-ra",           # Show summary of all non-passing tests
    "-q",            # Quieter output
    "--strict-markers",  # Fail on unknown markers (catches typos)
    "--strict-config",   # Fail on config errors
    "--tb=short",        # Short tracebacks
]
# Register custom markers to prevent typos
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests",
    "e2e: marks end-to-end tests",
]
# Minimum pytest version
minversion = "8.0"
# Filter specific warnings
filterwarnings = [
    "error",                          # Turn warnings into errors
    "ignore::DeprecationWarning",     # Except deprecation warnings from deps
]

[tool.coverage.run]
source = ["src"]
branch = true
omit = [
    "*/tests/*",
    "*/__pycache__/*",
    "*/migrations/*",
]

[tool.coverage.report]
# Enforce coverage minimum
fail_under = 80
# Lines to exclude from coverage
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if TYPE_CHECKING:",
    "if __name__ == .__main__.",
    "raise NotImplementedError",
    "pass",
    "@abstractmethod",
]
show_missing = true
```

---

## 3. Go

### golangci-lint v2

golangci-lint is the standard meta-linter for Go. Version 2 changed the config format. This config targets v2.

**.golangci.yml** (complete):

```yaml
version: "2"

run:
  # Timeout for analysis
  timeout: 5m
  # Include test files
  tests: true
  # Build tags to consider
  build-tags: []

linters:
  # Start from the default set
  default: standard
  # Enable additional linters
  enable:
    # Bug detection
    - bodyclose        # Checks HTTP response body is closed
    - contextcheck     # Checks context.Context is first param
    - durationcheck    # Checks duration multiplication
    - errcheck         # Checks unchecked errors
    - exhaustive       # Checks exhaustiveness of enum switch
    - govet            # Official Go vet
    - nilerr           # Checks for err != nil returning nil
    - sqlclosecheck    # Checks sql.Rows/Stmt are closed
    - staticcheck      # The best Go static analyzer

    # Style and convention
    - gofmt            # Checks code is gofmt-ed
    - goimports        # Checks imports are sorted
    - goconst          # Finds repeated strings that could be constants
    - misspell         # Finds misspelled English words
    - revive           # Fast, configurable, extensible linter (golint replacement)
    - unconvert        # Removes unnecessary type conversions
    - unparam          # Finds unused function parameters

    # Performance
    - prealloc         # Finds slice append in loops that could be preallocated

    # Security
    - gosec            # Security-oriented linter

  settings:
    errcheck:
      # Check for unchecked type assertions
      check-type-assertions: true
      # Check for unchecked errors in blank assignments
      check-blank: true

    govet:
      # Report shadowed variables
      shadow: true

    revive:
      rules:
        - name: blank-imports
        - name: context-as-argument
        - name: context-keys-type
        - name: dot-imports
        - name: error-return
        - name: error-strings
        - name: error-naming
        - name: exported
        - name: increment-decrement
        - name: indent-error-flow
        - name: range
        - name: receiver-naming
        - name: time-naming
        - name: unexported-return
        - name: var-declaration
        - name: var-naming

    gosec:
      excludes:
        # Allow math/rand for non-crypto use
        - G404

  exclusions:
    # Increase default max issues per linter
    max-issues-per-linter: 50
    max-same-issues: 10

    rules:
      # Relax some rules for test files
      - path: "_test\\.go$"
        linters:
          - gosec
          - errcheck
          - goconst

output:
  # Sort results for reproducible output
  sort-order:
    - linter
    - file

formatters:
  enable:
    - goimports
    - gofmt
```

**Makefile targets for Go quality:**

```makefile
.PHONY: lint test vet fmt

lint:
	golangci-lint run ./...

vet:
	go vet ./...

fmt:
	gofmt -s -w .
	goimports -w .

test:
	go test -race -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out

test-short:
	go test -short -race ./...
```

---

## 4. Rust

### Clippy configuration

Clippy is Rust's official linter. Configure it in `Cargo.toml` or `clippy.toml`.

**Cargo.toml** (lints section):

```toml
[lints.rust]
unsafe_code = "forbid"
missing_docs = "warn"

[lints.clippy]
# Enable all pedantic lints, then selectively allow noisy ones
pedantic = { level = "warn", priority = -1 }
# Allow these pedantic lints that are too noisy
module_name_repetitions = "allow"     # e.g., config::ConfigError is fine
must_use_candidate = "allow"          # Too many false positives
missing_errors_doc = "allow"          # Not every error needs doc

# Deny actual bugs and correctness issues
correctness = { level = "deny", priority = -1 }

# Additional useful lints beyond pedantic
enum_glob_use = "warn"          # Don't use glob imports for enums
unwrap_used = "warn"            # Prefer expect() or ? over unwrap()
expect_used = "warn"            # Consider proper error handling
todo = "warn"                   # Flag TODO comments
dbg_macro = "warn"              # Catch leftover debug macros
print_stdout = "warn"           # Use proper logging
print_stderr = "warn"           # Use proper logging
string_to_string = "warn"       # Redundant .to_string() on String
inefficient_to_string = "warn"  # Use Display instead of Debug for to_string
wildcard_imports = "warn"       # Avoid glob imports
```

### rustfmt.toml

```toml
# Rust edition — must match Cargo.toml
edition = "2021"
# Maximum line width
max_width = 100
# Use spaces, not tabs
hard_tabs = false
tab_spaces = 4
# Import grouping: std, external, crate
group_imports = "StdExternalCrate"
imports_granularity = "Module"
# Format strings in macros
format_strings = true
# Trailing commas everywhere
trailing_comma = "Vertical"
# Use field init shorthand: Point { x, y } instead of Point { x: x, y: y }
use_field_init_shorthand = true
# Chain formatting
chain_width = 60
# Function args
fn_params_layout = "Tall"
```

**Cargo.toml test profile:**

```toml
# Faster test compilation (skip optimizations)
[profile.test]
opt-level = 0
debug = true

# CI profile — like release but with debug info for backtraces
[profile.ci]
inherits = "release"
debug = 1
```

**Makefile targets for Rust quality:**

```makefile
.PHONY: lint fmt test check

check:
	cargo check --all-targets --all-features

lint:
	cargo clippy --all-targets --all-features -- -D warnings

fmt:
	cargo fmt --all -- --check

fmt-fix:
	cargo fmt --all

test:
	cargo test --all-features

# Full CI pipeline
ci: fmt lint test
```

---

## 5. Java / Kotlin

### Kotlin: ktlint + detekt

**ktlint** (formatting, like Prettier for Kotlin):

```bash
# Install via Gradle
# build.gradle.kts
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
}

ktlint {
    version.set("1.2.1")
    android.set(false)
    verbose.set(true)
    outputToConsole.set(true)
    // Enable experimental rules
    enableExperimentalRules.set(true)
}
```

**.editorconfig** (ktlint reads this for style):

```ini
[*.{kt,kts}]
# ktlint-specific settings
ktlint_code_style = ktlint_official
# Disable specific rules if needed
ktlint_standard_no-wildcard-imports = disabled
# Max line length
max_line_length = 120
```

**detekt** (static analysis, like ESLint for Kotlin):

**detekt.yml** (key sections):

```yaml
build:
  maxIssues: 0  # Fail on any issue

complexity:
  LongMethod:
    active: true
    threshold: 60
  LongParameterList:
    active: true
    functionThreshold: 6
    constructorThreshold: 8
  ComplexCondition:
    active: true
    threshold: 4
  CyclomaticComplexMethod:
    active: true
    threshold: 15
  TooManyFunctions:
    active: true
    thresholdInFiles: 15
    thresholdInClasses: 15

coroutines:
  GlobalCoroutineUsage:
    active: true
  SuspendFunWithCoroutineScopeReceiver:
    active: true

exceptions:
  TooGenericExceptionCaught:
    active: true
    exceptionNames:
      - 'Exception'
      - 'RuntimeException'
      - 'Throwable'
  SwallowedException:
    active: true
  ThrowingExceptionsWithoutMessageOrCause:
    active: true

naming:
  FunctionNaming:
    active: true
    # Allow Compose @Composable naming
    ignoreAnnotated: ['Composable']
  TopLevelPropertyNaming:
    active: true
    constantPattern: '[A-Z][_A-Z0-9]*'

performance:
  SpreadOperator:
    active: true
  UnnecessaryTemporaryInstantiation:
    active: true

potential-bugs:
  UnsafeCast:
    active: true
  UselessPostfixExpression:
    active: true

style:
  MagicNumber:
    active: true
    ignoreNumbers: ['-1', '0', '1', '2']
    ignoreAnnotated: ['Preview']
  MaxLineLength:
    active: true
    maxLineLength: 120
  WildcardImport:
    active: true
  UnusedPrivateMember:
    active: true
  ReturnCount:
    active: true
    max: 3
```

**build.gradle.kts** (detekt integration):

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.6"
}

detekt {
    config.setFrom("$rootDir/detekt.yml")
    buildUponDefaultConfig = true
    allRules = false
    parallel = true
}

// Make detekt part of the check task
tasks.named("check") {
    dependsOn(tasks.named("detekt"))
}
```

### Java: Checkstyle + SpotBugs

**checkstyle.xml** (Google style base with practical adjustments):

```xml
<?xml version="1.0"?>
<!DOCTYPE module PUBLIC
  "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
  "https://checkstyle.org/dtds/configuration_1_3.dtd">
<module name="Checker">
  <property name="charset" value="UTF-8"/>
  <property name="severity" value="error"/>
  <property name="fileTabCharacter" value="spaces"/>

  <module name="LineLength">
    <property name="max" value="120"/>
    <!-- Ignore import lines and URLs -->
    <property name="ignorePattern" value="^import |https?://"/>
  </module>

  <module name="TreeWalker">
    <!-- Naming conventions -->
    <module name="ConstantName"/>
    <module name="LocalVariableName"/>
    <module name="MemberName"/>
    <module name="MethodName"/>
    <module name="PackageName"/>
    <module name="ParameterName"/>
    <module name="TypeName"/>

    <!-- Import rules -->
    <module name="AvoidStarImport"/>
    <module name="RedundantImport"/>
    <module name="UnusedImports"/>

    <!-- Code structure -->
    <module name="NeedBraces"/>
    <module name="LeftCurly"/>
    <module name="RightCurly"/>
    <module name="OneStatementPerLine"/>
    <module name="MultipleVariableDeclarations"/>

    <!-- Common bugs -->
    <module name="EqualsHashCode"/>
    <module name="MissingSwitchDefault"/>
    <module name="FallThrough"/>
    <module name="StringLiteralEquality"/>

    <!-- Complexity -->
    <module name="CyclomaticComplexity">
      <property name="max" value="15"/>
    </module>
    <module name="MethodLength">
      <property name="max" value="80"/>
    </module>
    <module name="ParameterNumber">
      <property name="max" value="7"/>
    </module>
  </module>
</module>
```

**build.gradle.kts** (Checkstyle + SpotBugs):

```kotlin
plugins {
    java
    checkstyle
    id("com.github.spotbugs") version "6.0.9"
}

checkstyle {
    toolVersion = "10.15.0"
    configFile = file("$rootDir/checkstyle.xml")
    maxWarnings = 0
}

spotbugs {
    effort.set(com.github.spotbugs.snom.Effort.MAX)
    reportLevel.set(com.github.spotbugs.snom.Confidence.MEDIUM)
    excludeFilter.set(file("$rootDir/spotbugs-exclude.xml"))
}

tasks.withType<com.github.spotbugs.snom.SpotBugsTask> {
    reports.create("html") { required.set(true) }
    reports.create("xml") { required.set(false) }
}
```

**Maven equivalent** (pom.xml snippets):

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.3.1</version>
      <configuration>
        <configLocation>checkstyle.xml</configLocation>
        <failOnViolation>true</failOnViolation>
        <maxAllowedViolations>0</maxAllowedViolations>
      </configuration>
      <executions>
        <execution>
          <id>validate</id>
          <phase>validate</phase>
          <goals><goal>check</goal></goals>
        </execution>
      </executions>
    </plugin>
    <plugin>
      <groupId>com.github.spotbugs</groupId>
      <artifactId>spotbugs-maven-plugin</artifactId>
      <version>4.8.4.0</version>
      <configuration>
        <effort>Max</effort>
        <threshold>Medium</threshold>
      </configuration>
      <executions>
        <execution>
          <phase>verify</phase>
          <goals><goal>check</goal></goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

---

## 6. Ruby

### RuboCop

**.rubocop.yml** (complete):

```yaml
# Use the latest Ruby parser
AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable
  SuggestExtensions: false
  Exclude:
    - 'db/schema.rb'
    - 'bin/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'tmp/**/*'

# --- Layout ---
Layout/LineLength:
  Max: 120
  AllowedPatterns:
    - '^\s*#'  # Allow long comments

Layout/MultilineMethodCallIndentation:
  EnforcedStyle: indented

Layout/ArgumentAlignment:
  EnforcedStyle: with_fixed_indentation

# --- Metrics ---
Metrics/MethodLength:
  Max: 25
  CountAsOne:
    - 'array'
    - 'hash'
    - 'heredoc'

Metrics/ClassLength:
  Max: 150

Metrics/AbcSize:
  Max: 25

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'        # RSpec blocks are long by nature
    - 'config/routes.rb'
    - '**/*.rake'
    - 'Gemfile'

Metrics/CyclomaticComplexity:
  Max: 10

# --- Naming ---
Naming/PredicateName:
  # Allow 'has_' prefix — common in Rails
  ForbiddenPrefixes: []

# --- Style ---
Style/Documentation:
  Enabled: false  # Too noisy for most projects

Style/FrozenStringLiteralComment:
  Enabled: true
  EnforcedStyle: always

Style/StringLiterals:
  EnforcedStyle: double_quotes

Style/TrailingCommaInArrayLiteral:
  EnforcedStyleForMultiline: trailing_comma

Style/TrailingCommaInHashLiteral:
  EnforcedStyleForMultiline: trailing_comma

Style/TrailingCommaInArguments:
  EnforcedStyleForMultiline: trailing_comma

Style/HashSyntax:
  EnforcedShorthandSyntax: always

Style/SymbolArray:
  EnforcedStyle: brackets

Style/WordArray:
  EnforcedStyle: brackets

# --- Rails-specific (if using rubocop-rails) ---
# Uncomment if project uses Rails:
# require:
#   - rubocop-rails
#   - rubocop-rspec
#   - rubocop-performance

# Rails/SkipsModelValidations:
#   Enabled: true
# Rails/HasManyOrHasOneDependent:
#   Enabled: true
```

### RSpec configuration

**.rspec:**

```
--require spec_helper
--format documentation
--color
--order random
--warnings
```

**spec/spec_helper.rb** (key settings):

```ruby
RSpec.configure do |config|
  # Enforce new expect() syntax
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  # Verify partial doubles
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Filter run — focus on tagged examples
  config.filter_run_when_matching :focus

  # Disable monkey patching (no should syntax)
  config.disable_monkey_patching!

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed

  # Profile slow tests
  config.profile_examples = 5
end
```

---

## 7. Zig

Zig ships compiler, build system, formatter, and test runner in one binary. There is no separate linter — `zig build` performs semantic and safety checks during compilation. Pin examples to **Zig 0.13.0**; the language is pre-1.0 and semantics change between minor releases, so never float to `latest`.

### Package manager

Zig uses `build.zig.zon` (introduced in Zig 0.11) as both manifest and lockfile. Dependencies are declared with content hashes; there is no separate package index in 0.13 — deps are fetched by URL (tarball or git) and verified against the committed hash.

```zig
// build.zig.zon
.{
    .name = "zig-cli-tool",
    .version = "0.1.0",
    .minimum_zig_version = "0.13.0",

    .dependencies = .{
        .clap = .{
            .url = "https://github.com/Hejsil/zig-clap/archive/refs/tags/0.9.1.tar.gz",
            .hash = "1220b5c8c5c0e8...",
        },
    },

    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
        "LICENSE",
        "README.md",
    },
}
```

Commit `build.zig.zon` — it is both manifest and lockfile. A hash mismatch will fail CI; document how to regenerate (delete hash field, rerun `zig build`, paste new hash).

### Formatter

`zig fmt` is built into the compiler. No config file, no flags. Opinionated — 4-space indent, 100-column soft wrap, no configuration knobs by design.

```bash
# Format in place
zig fmt src/

# CI: check only, exit non-zero on formatting diffs
zig fmt --check src/ build.zig
```

### Linter

**N/A as a separate tool.** Do not install ESLint, clippy, or a Zig equivalent — none exists. Semantic, type, and safety checks run during `zig build` and `zig build test`. Treat `zig build test` as your lint + test pipeline.

### Test runner

Zig tests live in `test "name" { ... }` blocks inline within any module, and are discovered by the build system via a `test` step.

**Minimal `build.zig` with a test step:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-cli-tool",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Test step: `zig build test`
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
```

**Sample test block** (lives in `src/main.zig`):

```zig
const std = @import("std");
const testing = std.testing;

test "addition works" {
    try testing.expectEqual(@as(i32, 4), 2 + 2);
}
```

Run with:
```bash
zig build test --summary all
# Or a single file:
zig test src/main.zig
```

### Common pitfalls

- **Version drift.** Zig 0.x releases break. Pin `minimum_zig_version` in `build.zig.zon`, pin the CI action version, and pin your local toolchain (zigup / asdf / mise).
- **Hash mismatches brick CI.** `build.zig.zon` hashes are content-addressed. If upstream re-tags or a mirror changes, the hash fails. Commit hashes, document regeneration, and prefer stable tarballs over moving git refs.
- **Don't hunt for a linter.** Several agents (and humans) try to install ESLint-equivalents for Zig. There isn't one and doesn't need to be — `zig build` is the check.
- **Allocator hygiene.** Every allocation is explicit; every test block should defer its `deinit()`. The compiler won't warn you about a leaked `ArenaAllocator`.

---

## 8. Gleam

Gleam is a statically-typed functional language on the BEAM (Erlang VM). Its toolchain ships formatter, type checker, and test runner; there is no separate linter — the type system fills that role. Pin examples to **Gleam 1.4+** on **OTP 27.x**.

### Package manager

Gleam uses **Hex** (shared with Erlang and Elixir). Dependencies declared in `gleam.toml`, locked in `manifest.toml`.

```bash
# Add a dependency
gleam add gleam_stdlib
gleam add gleeunit --dev

# Fetch and compile deps
gleam deps download
```

**Minimal `gleam.toml`:**

```toml
name = "gleam_app"
version = "1.0.0"
target = "erlang"              # "erlang" or "javascript"
gleam = ">= 1.4.0"

[dependencies]
gleam_stdlib = ">= 0.40.0 and < 2.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

Commit `manifest.toml` (the lockfile) — `gleam deps download` reads it for reproducible builds.

### Formatter

`gleam format` is built-in, opinionated, zero-config.

```bash
# Format in place
gleam format src test

# CI: check only, exit non-zero on diffs
gleam format --check src test
```

### Type checker / linter

`gleam check` runs the full type checker without compiling. There is no separate linter — the type system catches what linters would in dynamically-typed languages. For additional rigor, treat unused-import warnings as errors in CI.

```bash
gleam check
```

### Test runner

`gleam test` runs **gleeunit** by default (the ecosystem-standard test framework). Tests live in `test/<package>_test.gleam` and are plain Gleam functions ending in `_test`.

**Sample test file** (`test/gleam_app_test.gleam`):

```gleam
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn pipe_chain_test() {
  "  hello  "
  |> string.trim
  |> string.uppercase
  |> should.equal("HELLO")
}

pub fn list_reduce_test() {
  [1, 2, 3, 4]
  |> list.fold(0, fn(acc, n) { acc + n })
  |> should.equal(10)
}
```

Run with:
```bash
gleam test
```

### Common pitfalls

- **Young ecosystem.** Gleam 1.x is stable, but Hex packages for pure Gleam are fewer than for Elixir/Erlang. Prefer stdlib + gleeunit before reaching for a dep; fall back to Erlang/Elixir interop when needed.
- **OTP version matters.** Gleam compiles to BEAM bytecode; the OTP version at build AND runtime must be compatible. Pin `otp-version: "27.0"` in CI explicitly — `erlef/setup-beam` handles this.
- **No `rebar3-version` needed for pure Gleam.** Some examples in the wild include it; you only need it if your project has Erlang deps that rely on rebar3.
- **Compiled to Erlang or JS.** `target = "erlang"` is default; `target = "javascript"` emits ES modules. Decide up front — mixed targets need per-target tests.

---

## 9. Deno

Deno 2.x is the JavaScript/TypeScript runtime that ships everything: formatter, linter, type checker, test runner, task runner, and publisher. No `node_modules/` required, no `package.json` — `deno.json` is the single config surface. Pin examples to **Deno 2.x**.

### Package manager / runtime

Deno has no separate package manager. Import from URLs, JSR, or npm:

```typescript
import { assertEquals } from "jsr:@std/assert@^1.0.0";
import express from "npm:express@^4.21.0";
```

`deno.json` holds config; `deno.lock` locks resolved versions.

**Minimal `deno.json`:**

```jsonc
{
  "name": "@my-scope/my-deno-lib",
  "version": "0.1.0",
  "exports": "./mod.ts",

  "tasks": {
    "dev":   "deno run --watch --allow-net src/main.ts",
    "test":  "deno test --allow-read --allow-env",
    "check": "deno check **/*.ts",
    "ci":    "deno fmt --check && deno lint && deno check **/*.ts && deno test"
  },

  "imports": {
    "@std/assert": "jsr:@std/assert@^1.0.0",
    "@std/http":   "jsr:@std/http@^1.0.0"
  },

  "fmt": {
    "indentWidth": 2,
    "lineWidth": 100,
    "useTabs": false,
    "singleQuote": false,
    "semiColons": true
  },

  "lint": {
    "rules": {
      "tags": ["recommended"],
      "exclude": ["no-unused-vars"]
    }
  },

  "test": {
    "include": ["tests/"]
  }
}
```

Commit `deno.lock`.

### Formatter

`deno fmt` is built-in. Config lives in `deno.json` under `"fmt"`.

```bash
deno fmt              # Format in place
deno fmt --check      # CI
```

### Linter

`deno lint` is built-in. Config lives in `deno.json` under `"lint"`. Rule tags: `recommended` (default), plus individual includes/excludes.

```bash
deno lint
```

### Type checker

TypeScript is integrated — no separate `tsc`. Runtime strips types; `deno check` runs the full checker statically.

```bash
deno check **/*.ts
# Or a specific entry point:
deno check src/main.ts
```

### Test runner

`deno test` discovers `*_test.ts`, `*.test.ts`, and `test_*.ts` files. Assertions come from `jsr:@std/assert`.

**Sample test** (`tests/math_test.ts`):

```typescript
import { assertEquals } from "jsr:@std/assert@^1.0.0";
import { add } from "../src/math.ts";

Deno.test("add: basic", () => {
  assertEquals(add(2, 2), 4);
});

Deno.test("add: negative numbers", () => {
  assertEquals(add(-1, 1), 0);
});
```

Run:
```bash
deno test --allow-read
```

### Task runner

Instead of `npm run`, Deno uses `deno task <name>` defined in `deno.json` `"tasks"` (see minimal config above). Tasks are shell-executed and portable.

```bash
deno task ci
```

### Publishing

JSR (jsr.io) is the modern publishing target for Deno-first packages. `deno publish` uses OIDC via GitHub Actions (no tokens needed).

```bash
deno publish
```

For binary distribution, `deno compile` produces a standalone executable per target:

```bash
deno compile --output bin/mycli src/main.ts
```

### Common pitfalls

- **Don't mix `node_modules/` with Deno unless intentional.** The `"nodeModulesDir"` flag in `deno.json` turns on npm compatibility with a real `node_modules/` folder — opt in deliberately.
- **`import_map.json` is legacy.** Modern Deno uses the `"imports"` field in `deno.json`. Don't add `import_map.json` to new projects.
- **Permissions.** `deno run` refuses network/file access by default. Document required `--allow-*` flags in README and set them in tasks; don't use `--allow-all`.
- **JSR vs deno.land/std.** `https://deno.land/std/...` imports are frozen at stdlib 0.224; new code should use `jsr:@std/...` (actively versioned).

---

## 10. Bun

Bun 1.1+ is a Node-compatible runtime, package manager, and test runner in a single binary. It does NOT ship a formatter or linter — use **Biome** for both (same tool recommended for JS/TS in §1, matches the ecosystem pattern and avoids the ESLint+Prettier dance).

**Bun-first vs Bun-drop-in — pick one before configuring tooling:**

- **Bun-first:** `bun` is the runtime. Use `bun run`, `bun test`, `bun install`. Commit `bun.lockb`. All examples below assume this mode.
- **Bun-drop-in:** Node is still the runtime; Bun is only a faster installer. Use `bun install` only — keep `package-lock.json`, use `npm test` / `node` / etc.
- If you commit `bun.lockb`, you're Bun-first. If you commit `package-lock.json`, you're Bun-drop-in. Don't commit both.

Pin examples to **Bun 1.1+**.

### Package manager

`bun install` is the fastest of the four JS package managers. Lockfile is `bun.lockb` (binary — faster to parse, smaller on disk, but **unreadable in merge conflicts**).

```bash
bun install
bun add hono
bun add -d @biomejs/biome
```

**Lockfile conflict protocol:** do not hand-resolve `bun.lockb` conflicts. Take one side, run `bun install` fresh, commit the regenerated binary.

### Test runner

`bun test` is Jest-compatible and built-in. Discovers `*.test.ts`, `*.test.js`, `*_test.ts` by default.

**Sample test** (`tests/users.test.ts`):

```typescript
import { describe, expect, test } from "bun:test";
import { formatUser } from "../src/users";

describe("formatUser", () => {
  test("renders full name", () => {
    expect(formatUser({ first: "Ada", last: "Lovelace" })).toBe("Ada Lovelace");
  });

  test("handles missing last name", () => {
    expect(formatUser({ first: "Ada" })).toBe("Ada");
  });
});
```

Run:
```bash
bun test
bun test --coverage
bun test --watch
```

### Formatter: Biome

Bun does not ship a formatter. Use **Biome** (recommended) — matches the JS/TS recommendation in §1, single binary, handles both format and lint in one pass.

**Minimal `biome.json`:**

```jsonc
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": { "enabled": true },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double",
      "semicolons": "always",
      "trailingCommas": "all"
    }
  },
  "files": {
    "ignore": ["dist/", "node_modules/", "coverage/"]
  }
}
```

Run via Bun:
```bash
bunx biome format --write .
bunx biome check --write .       # Format + lint + import-sort
bunx biome ci .                  # CI: check only, no writes
```

### Linter: Biome

Same tool, same config — `"linter"` block in `biome.json` above. No separate ESLint install needed.

### Type checker

Bun executes TypeScript directly (no separate compile step) but does **not** type-check at runtime. For static checks, use `tsc --noEmit`:

```bash
bun run tsc --noEmit
# Or with pinned TS version:
bunx typescript@5.6 --noEmit
```

Include `typescript` as a dev dependency so the version is pinned in `package.json`.

### Minimal `bunfig.toml` (optional)

```toml
[install]
# Pin exact versions (no caret/tilde ranges) in package.json
exact = true

[test]
# Stop after N failed test files
bail = 5
coverage = false
```

Only add `bunfig.toml` when defaults don't fit — most projects don't need it.

### Common pitfalls

- **`bun.lockb` is binary.** Merge conflicts cannot be hand-resolved. Accept one side, run `bun install`, commit the fresh binary. If PRs frequently clash, consider a merge-queue or a CODEOWNER on the lockfile.
- **`"type": "module"` must match the runtime.** When migrating a Node project to Bun, check `package.json` `"type"` — some Bun APIs only work in ESM, and mixed CJS/ESM files will surprise you.
- **Don't confuse `bun test` with `bun run test`.** `bun test` runs Bun's built-in runner; `bun run test` executes the `"test"` script in `package.json` (which may invoke Jest, Vitest, or anything else).
- **Biome is not Prettier.** Biome prints slightly different output (trailing commas, quote style); pick one and don't flip back to Prettier mid-project.

---

## 11. Git Hooks

Three options depending on stack. Pick the one that matches your ecosystem.

### Option A: Husky + lint-staged + commitlint (Node.js projects)

**Install:**

```bash
npm install --save-dev husky lint-staged @commitlint/cli @commitlint/config-conventional
npx husky init
```

**.husky/pre-commit:**

```bash
npx lint-staged
```

**.husky/commit-msg:**

```bash
npx --no-install commitlint --edit "$1"
```

**package.json** (lint-staged config):

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "biome check --write --no-errors-on-unmatched"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ],
    "*.css": [
      "prettier --write"
    ]
  }
}
```

If using ESLint + Prettier instead of Biome:

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix --max-warnings 0",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml,css}": [
      "prettier --write"
    ]
  }
}
```

### Option B: Lefthook (polyglot / non-Node projects)

Lefthook is a fast, language-agnostic Git hook manager. Use this for Go, Rust, Python, Ruby, polyglot, or any project where you don't want a Node.js dependency.

**Install:**

```bash
# macOS
brew install lefthook
# or via Go
go install github.com/evilmartians/lefthook@latest
# Then initialize
lefthook install
```

**lefthook.yml** (complete, multi-language example):

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    # JavaScript/TypeScript (if applicable)
    biome:
      glob: "*.{ts,tsx,js,jsx}"
      run: npx biome check --write {staged_files}
      stage_fixed: true  # Re-stage after fix

    # Python
    ruff-lint:
      glob: "*.py"
      run: ruff check --fix {staged_files}
      stage_fixed: true

    ruff-format:
      glob: "*.py"
      run: ruff format {staged_files}
      stage_fixed: true

    # Go
    go-fmt:
      glob: "*.go"
      run: gofmt -l -w {staged_files}
      stage_fixed: true

    go-vet:
      glob: "*.go"
      run: go vet ./...

    golangci-lint:
      glob: "*.go"
      run: golangci-lint run --new-from-rev=HEAD~1

    # Rust
    cargo-fmt:
      glob: "*.rs"
      run: cargo fmt -- --check

    cargo-clippy:
      glob: "*.rs"
      run: cargo clippy --all-targets -- -D warnings

    # Ruby
    rubocop:
      glob: "*.rb"
      run: bundle exec rubocop --force-exclusion {staged_files}

    # Universal — prevent secrets from being committed
    secrets:
      run: |
        if command -v gitleaks &> /dev/null; then
          gitleaks protect --staged --no-banner
        fi

commit-msg:
  commands:
    # Conventional commit enforcement
    commitlint:
      run: |
        if command -v commitlint &> /dev/null; then
          commitlint --edit "$1"
        fi

pre-push:
  parallel: true
  commands:
    # Run tests before push
    test:
      run: |
        if [ -f "package.json" ]; then
          npm test
        elif [ -f "pyproject.toml" ]; then
          pytest --tb=short -q
        elif [ -f "go.mod" ]; then
          go test -short ./...
        elif [ -f "Cargo.toml" ]; then
          cargo test
        elif [ -f "Gemfile" ]; then
          bundle exec rspec --fail-fast
        fi
```

### Option C: pre-commit framework (Python ecosystem)

**Install:**

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

**.pre-commit-config.yaml** (complete):

```yaml
# .pre-commit-config.yaml
repos:
  # General file fixes
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--unsafe']  # Allow custom YAML tags
      - id: check-json
      - id: check-toml
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: detect-private-key
      - id: no-commit-to-branch
        args: ['--branch', 'main', '--branch', 'master']

  # Python — Ruff for linting and formatting
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: ['--fix']
      - id: ruff-format

  # Python — type checking
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        additional_dependencies: []  # Add type stubs here
        args: ['--ignore-missing-imports']

  # Commit message linting
  - repo: https://github.com/commitizen-tools/commitizen
    rev: v3.25.0
    hooks:
      - id: commitizen
        stages: [commit-msg]

  # Secret detection
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  # Shell script linting
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.10.0.1
    hooks:
      - id: shellcheck

  # YAML linting
  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
        args: ['-c', '{extends: default, rules: {line-length: {max: 120}}}']
```

---

## 12. Secret scanning (pre-commit)

Snyk's 2025 state-of-secrets report counted **28.65M secrets leaked to public GitHub**, roughly a 34% year-over-year increase (<https://snyk.io/articles/state-of-secrets/>). Analysis at toxsec.com found AI-assisted commits leak at ~**2× the baseline rate** — larger, faster commits slip past review (<https://www.toxsec.com/p/why-vibe-coding-leaks-your-secrets>). Pre-commit scanning catches leaks at the staging index, before the secret reaches anyone else's clone.

### Tool tradeoff

**gitleaks (recommended).** Single Go binary, fastest scanner, widest default detector set, most ecosystem adoption. Single-TOML config. <https://github.com/gitleaks/gitleaks>.

**trufflehog.** Best for *verified* secret detection — optionally probes live APIs to confirm a leaked key is active, reducing false-positive noise. Heavier runtime; most teams run it in CI. <https://github.com/trufflesecurity/trufflehog>.

**detect-secrets.** Python-native tool from Yelp with a distinctive "baseline" workflow — commit a `.secrets.baseline`; new findings report as diffs against it. Preferred by Python-heavy shops. <https://github.com/Yelp/detect-secrets>.

| Tool | Install | Default ruleset | Verified-secret mode | Best fit |
|---|---|---|---|---|
| gitleaks | Single Go binary | Broadest built-in | No (regex only) | Default choice for most stacks |
| trufflehog | Single Go binary | Broad + verifiers | Yes (live API probes) | CI-layer verification |
| detect-secrets | Python pip | Narrower built-in | No | Python shops with baseline workflow |

### Paste-ready `.gitleaks.toml`

```toml
# .gitleaks.toml — secret-scanning configuration for my-project
# Schema: https://github.com/gitleaks/gitleaks

[extend]
# Pull in all built-in detectors (AWS, GCP, Stripe, GitHub tokens, etc.)
useDefault = true

# Custom rule: your project's internal API key prefix
[[rules]]
id = "myproj-internal-api-key"
description = "my-project internal API key"
regex = '''(?i)myproj_api_[a-z0-9]{32}'''
tags = ["api", "internal"]

[allowlist]
description = "Allowlisted false positives for my-project"

# 1. example.com URLs in docs and templates — gitleaks' default rules can
#    fire on these; documentation uses them intentionally.
regexes = [
    '''example\.com''',
]

# 2. Test fixtures carry known-fake secrets by design.
paths = [
    '''(^|/)tests?/fixtures/''',
    '''(^|/)docs?/.*\.md$''',
]

# 3. Pin SHAs here to exempt specific historical commits.
# commits = [
#   "abc1234def5678...",
# ]
```

**False-positive note.** Gitleaks' default rules will fire on `example.com` URLs in documentation and on obviously-fake placeholder keys in template fixtures. The `[allowlist]` regex and paths above handle both without disabling the underlying rule — prefer scoped allowlisting to rule deletion so a real key in the same path still trips the scanner.

### Pre-commit integration

Use the [pre-commit](https://pre-commit.com/) framework to run gitleaks on every `git commit`. It reads `.gitleaks.toml` from repo root automatically.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
```

Install:

```sh
pip install pre-commit
pre-commit install
```

### Manual hook alternative

For projects not using pre-commit.com, install gitleaks as a native Git hook:

```sh
#!/bin/sh
# .git/hooks/pre-commit
gitleaks protect --staged --redact --verbose
```

Then `chmod +x .git/hooks/pre-commit`. `--staged` scans only the staging index; `--redact` hides matched secrets from output so a screenshot of a failed commit doesn't re-leak.

### CI backstop

In CI, run `gitleaks detect --redact --verbose` on every PR as a backstop for commits that arrived without the pre-commit hook. Full CI YAML lives in `references/ci-cd-workflows.md` and `references/security-setup.md` §4d — this file keeps the pre-commit scope.

---

## 13. Universal Config Files

### .editorconfig

This file is read by nearly every editor and IDE. It ensures consistent formatting regardless of individual developer settings. Put it in every project.

```ini
# .editorconfig
# Top-most EditorConfig file
root = true

# Default for all files
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

# JavaScript, TypeScript, JSON, YAML
[*.{js,jsx,ts,tsx,json,yml,yaml,css,scss,html,vue,svelte}]
indent_size = 2

# Python — PEP 8 mandates 4 spaces
[*.py]
indent_size = 4
max_line_length = 88

# Go — tabs, not spaces
[*.go]
indent_style = tab
indent_size = 4

# Rust — 4 spaces
[*.rs]
indent_size = 4

# Java / Kotlin
[*.{java,kt,kts}]
indent_size = 4

# Ruby
[*.rb]
indent_size = 2

# C / C++
[*.{c,cpp,h,hpp}]
indent_size = 4

# Makefiles require tabs
[Makefile]
indent_style = tab

[*.mk]
indent_style = tab

# Shell scripts
[*.{sh,bash,zsh}]
indent_size = 2

# Markdown — trailing spaces are significant (line breaks)
[*.md]
trim_trailing_whitespace = false

# Docker
[Dockerfile*]
indent_size = 4

# TOML
[*.toml]
indent_size = 2

# XML / Plist
[*.{xml,plist}]
indent_size = 4
```

### .gitattributes

Controls line endings, binary handling, LFS tracking, and GitHub language statistics.

```gitattributes
# .gitattributes

# === Line ending normalization ===
# Auto-detect text files and ensure LF in repo, native on checkout
* text=auto eol=lf

# Force LF for these file types regardless of platform
*.js    text eol=lf
*.jsx   text eol=lf
*.ts    text eol=lf
*.tsx   text eol=lf
*.json  text eol=lf
*.yml   text eol=lf
*.yaml  text eol=lf
*.md    text eol=lf
*.css   text eol=lf
*.html  text eol=lf
*.py    text eol=lf
*.rb    text eol=lf
*.go    text eol=lf
*.rs    text eol=lf
*.java  text eol=lf
*.kt    text eol=lf
*.sh    text eol=lf
*.sql   text eol=lf
*.toml  text eol=lf
*.xml   text eol=lf

# Windows-specific files keep CRLF
*.bat   text eol=crlf
*.cmd   text eol=crlf
*.ps1   text eol=crlf
*.sln   text eol=crlf

# === Binary files ===
# Images
*.png   binary
*.jpg   binary
*.jpeg  binary
*.gif   binary
*.ico   binary
*.svg   text eol=lf
*.webp  binary

# Fonts
*.woff  binary
*.woff2 binary
*.ttf   binary
*.eot   binary
*.otf   binary

# Archives
*.zip   binary
*.tar   binary
*.gz    binary

# Documents
*.pdf   binary

# Lock files — do not diff, treat as generated
package-lock.json  text eol=lf linguist-generated=true
pnpm-lock.yaml     text eol=lf linguist-generated=true
yarn.lock          text eol=lf linguist-generated=true
Cargo.lock         text eol=lf linguist-generated=true
Gemfile.lock       text eol=lf linguist-generated=true
poetry.lock        text eol=lf linguist-generated=true
go.sum             text eol=lf linguist-generated=true

# === LFS tracking (uncomment if using Git LFS) ===
# *.psd     filter=lfs diff=lfs merge=lfs -text
# *.sketch  filter=lfs diff=lfs merge=lfs -text
# *.fig     filter=lfs diff=lfs merge=lfs -text
# *.ai      filter=lfs diff=lfs merge=lfs -text
# *.mp4     filter=lfs diff=lfs merge=lfs -text
# *.mov     filter=lfs diff=lfs merge=lfs -text

# === GitHub Linguist overrides ===
# Exclude from language statistics
docs/**            linguist-documentation
*.md               linguist-documentation
vendor/**          linguist-vendored
third_party/**     linguist-vendored

# Generated code — exclude from stats and diffs
*.generated.*     linguist-generated=true
*.gen.go          linguist-generated=true
*_pb2.py          linguist-generated=true
*.pb.go           linguist-generated=true
dist/**           linguist-generated=true
build/**          linguist-generated=true
```

### .gitignore

Do not create a monolithic .gitignore. Start with your stack's template from GitHub's collection, then add project-specific entries. Here are the essential patterns per stack.

**Universal entries (every project):**

```gitignore
# === OS files ===
.DS_Store
Thumbs.db
Desktop.ini
*.swp
*.swo
*~

# === IDE/Editor ===
.idea/
.vscode/settings.json
.vscode/launch.json
*.sublime-project
*.sublime-workspace

# === Environment ===
.env
.env.local
.env.*.local
!.env.example

# === Logs ===
*.log
logs/
```

**Node.js additions:**

```gitignore
node_modules/
dist/
build/
coverage/
.turbo/
.next/
.nuxt/
.output/
*.tsbuildinfo
```

**Python additions:**

```gitignore
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
.eggs/
dist/
build/
.venv/
venv/
.mypy_cache/
.ruff_cache/
.pytest_cache/
htmlcov/
.coverage
*.cover
```

**Go additions:**

```gitignore
/vendor/
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
coverage.out
```

**Rust additions:**

```gitignore
/target/
*.pdb
```

**Java/Kotlin additions:**

```gitignore
*.class
*.jar
*.war
*.ear
build/
.gradle/
out/
target/
```

**Ruby additions:**

```gitignore
/.bundle/
/vendor/bundle
*.gem
.byebug_history
/coverage/
/tmp/
/log/
```

---

## 14. Commit Linting

### commitlint configuration

**commitlint.config.js:**

```js
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type must be one of these
    'type-enum': [
      2, // error
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Formatting, missing semicolons — no code change
        'refactor', // Code change that neither fixes a bug nor adds a feature
        'perf',     // Performance improvement
        'test',     // Adding or updating tests
        'build',    // Build system or external dependencies
        'ci',       // CI configuration
        'chore',    // Maintenance tasks
        'revert',   // Revert a previous commit
      ],
    ],
    // Type must be lowercase
    'type-case': [2, 'always', 'lower-case'],
    // Subject must not be empty
    'subject-empty': [2, 'never'],
    // Subject must not end with period
    'subject-full-stop': [2, 'never', '.'],
    // Subject max length
    'header-max-length': [2, 'always', 100],
    // Body max line length
    'body-max-line-length': [2, 'always', 100],
  },
};
```

### Conventional Commits summary

The format is:

```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

**Types and when to use them:**

| Type | When | Example |
|---|---|---|
| `feat` | New user-facing feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): handle null response from /users` |
| `docs` | Documentation changes only | `docs: update API endpoint table` |
| `style` | Formatting, whitespace, semicolons | `style: fix indentation in config` |
| `refactor` | Code restructuring, no behavior change | `refactor(db): extract query builder` |
| `perf` | Performance improvement | `perf: cache parsed templates` |
| `test` | Adding or fixing tests | `test(auth): add login edge cases` |
| `build` | Build system, dependencies | `build: upgrade webpack to v5` |
| `ci` | CI pipeline changes | `ci: add Node 20 to test matrix` |
| `chore` | Maintenance, tooling | `chore: update dev dependencies` |
| `revert` | Revert a commit | `revert: feat(auth): add OAuth2 login` |

**Breaking changes** — append `!` after type or add `BREAKING CHANGE:` footer:

```
feat(api)!: change /users response format

BREAKING CHANGE: The /users endpoint now returns { data: User[] }
instead of User[]. All clients must update their parsing logic.
```

**Scopes** — use the module, component, or area affected:

```
feat(auth): ...
fix(api): ...
refactor(db): ...
test(payments): ...
```

### CI integration for commit linting

**GitHub Actions:**

```yaml
# .github/workflows/commitlint.yml
name: Commit Lint
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
      - run: npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose
```

**For non-Node projects using commitizen (Python):**

```yaml
# .github/workflows/commitlint.yml
name: Commit Lint
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install commitizen
      - run: cz check --rev-range ${{ github.event.pull_request.base.sha }}..${{ github.event.pull_request.head.sha }}
```

---

## 15. Decision Matrix

### Which tools to combine per stack

| Stack | Linter | Formatter | Type Checker | Test Runner | Git Hooks |
|---|---|---|---|---|---|
| **TypeScript (new)** | Biome | Biome | `tsc --noEmit` | Vitest | Husky + lint-staged |
| **TypeScript (existing)** | ESLint v9 | Prettier | `tsc --noEmit` | Jest or Vitest | Husky + lint-staged |
| **Python** | Ruff | Ruff | mypy or pyright | pytest | pre-commit or Lefthook |
| **Go** | golangci-lint v2 | gofmt + goimports | (built-in) | `go test` | Lefthook |
| **Rust** | Clippy | rustfmt | (built-in) | `cargo test` | Lefthook |
| **Kotlin** | detekt + ktlint | ktlint | (built-in) | JUnit 5 | Lefthook |
| **Java** | Checkstyle + SpotBugs | Checkstyle | (built-in) | JUnit 5 | Lefthook |
| **Ruby** | RuboCop | RuboCop | Sorbet (opt.) | RSpec | Lefthook |
| **Zig** | (none — `zig build`) | `zig fmt` | (built-in) | `zig build test` | Lefthook |
| **Gleam** | `gleam check` | `gleam format` | `gleam check` | `gleam test` (gleeunit) | Lefthook |
| **Deno** | `deno lint` | `deno fmt` | `deno check` | `deno test` | Lefthook |
| **Bun** | Biome | Biome | `tsc --noEmit` | `bun test` | Lefthook |
| **Polyglot** | Per-language | Per-language | Per-language | Per-language | Lefthook |

### What to add at each project stage

**MVP / Side project** — get these working before your first PR:

- Linter + formatter (one command, auto-fix on save)
- .editorconfig
- .gitignore (from GitHub template for your stack)
- Basic CI: lint + test on push
- That is it. Do not over-engineer a weekend project.

**Growth / Team project** — add when you have 2+ contributors:

- Git hooks (Husky/Lefthook/pre-commit) for pre-commit linting
- Commit linting (Conventional Commits)
- Type checking in CI
- Coverage thresholds (start at 60%, raise to 80% over time)
- .gitattributes (line endings matter now)
- PR template mentioning quality checks

**Enterprise / Open source** — add when reliability and trust matter:

- All of the above, strictly enforced
- Security scanning (gitleaks, Snyk/Dependabot, CodeQL)
- CODEOWNERS for review routing
- Branch protection requiring passing checks
- Coverage thresholds at 80%+ with trend tracking
- License compliance scanning
- Performance benchmarks in CI (for libraries)
- Multiple CI environments (OS matrix, version matrix)
- Automated dependency updates with auto-merge for patch versions

### Anti-patterns to avoid

- **Tool soup**: Do not run ESLint + Biome + Prettier + dprint. Pick one formatting pipeline. Conflicts between tools waste more time than they save.
- **Warnings that nobody fixes**: If a warning has been ignored for 6 months, either fix it or disable the rule. A wall of warnings trains developers to ignore all warnings.
- **Coverage theater**: 100% line coverage with zero assertions. Coverage measures what code runs, not what code works. Pair coverage thresholds with mutation testing for critical paths.
- **Pre-commit hooks that take 60 seconds**: Lint only staged files, not the entire codebase. Run full checks in CI. Slow hooks get bypassed with `--no-verify`.
- **Skipping hooks in emergencies**: If `--no-verify` is a regular occurrence, the hooks are too slow or too strict. Fix the hooks, don't normalize bypassing them.
