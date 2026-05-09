# Developer Onboarding & DX Setup

Reference for task runners, dev containers, local services, setup scripts, version managers, IDE configuration, deployment config, and the "zero to running" checklist. Every template is complete and paste-ready.

---

## 1. Task Runners

Every project needs a single entry point for common operations. A new contributor should never have to read a CI config to figure out how to run tests locally.

### Makefile

The universal default. Works everywhere, ships with every Unix system, understood by every developer. Use this for polyglot projects, projects without Node.js, or when you want zero dependencies.

```makefile
.PHONY: help setup dev test build lint format clean check ci

# Self-documenting help target — grep all targets with ## comments
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies and set up local environment
	@echo "==> Installing dependencies..."
	npm install
	@echo "==> Setting up environment..."
	@if [ ! -f .env ]; then cp .env.example .env && echo "Created .env from .env.example"; fi
	@echo "==> Setup complete. Run 'make dev' to start."

dev: ## Start development server
	npm run dev

test: ## Run test suite
	npm test

test-watch: ## Run tests in watch mode
	npm run test:watch

build: ## Build for production
	npm run build

lint: ## Run linter
	npm run lint

format: ## Format code
	npm run format

check: ## Run all checks (lint + type check + test)
	npm run lint
	npm run typecheck
	npm test

ci: check build ## Run full CI pipeline locally

clean: ## Remove build artifacts and caches
	rm -rf dist/ node_modules/.cache coverage/ .next/ .nuxt/ .output/
	@echo "Cleaned build artifacts."

clean-all: clean ## Remove everything including node_modules
	rm -rf node_modules/
	@echo "Cleaned node_modules. Run 'make setup' to reinstall."

.DEFAULT_GOAL := help
```

**Cross-platform considerations:**
- Makefile requires tabs for indentation (spaces break it silently)
- On Windows, `make` is not installed by default. Options: install via `choco install make`, use WSL, or use an alternative runner
- Avoid bash-only syntax in commands. Use `$(shell ...)` over backticks. Use `rm -rf` cautiously (safe on Unix, needs adjustment on Windows without WSL)
- The `@` prefix suppresses command echo. Use it for cleaner output
- `.PHONY` prevents conflicts with files named after targets
- `.DEFAULT_GOAL := help` means bare `make` shows the help menu

**Python variant — replace the command bodies:**

```makefile
setup: ## Install dependencies and set up local environment
	python -m venv .venv
	.venv/bin/pip install -e ".[dev]"
	@if [ ! -f .env ]; then cp .env.example .env; fi

dev: ## Start development server
	.venv/bin/python -m uvicorn app.main:app --reload

test: ## Run test suite
	.venv/bin/pytest

lint: ## Run linter
	.venv/bin/ruff check .

format: ## Format code
	.venv/bin/ruff format .

check: ## Run all checks
	.venv/bin/ruff check .
	.venv/bin/mypy .
	.venv/bin/pytest
```

**Go variant:**

```makefile
BINARY_NAME := myapp

setup: ## Install dependencies and tools
	go mod download
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@if [ ! -f .env ]; then cp .env.example .env; fi

dev: ## Run with hot reload (requires air)
	air

test: ## Run test suite
	go test ./...

test-cover: ## Run tests with coverage
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

build: ## Build binary
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/$(BINARY_NAME) ./cmd/$(BINARY_NAME)

lint: ## Run linter
	golangci-lint run

format: ## Format code
	gofmt -w .
	goimports -w .

clean: ## Remove build artifacts
	rm -rf bin/ coverage.out coverage.html
```

### Justfile

Modern alternative to Make. Better syntax, no tab requirement, built-in parameters, cross-platform by design. Use this when you want Make's ergonomics without Make's quirks.

Requires installing `just`: `cargo install just`, `brew install just`, or `winget install just`.

```justfile
# Show available recipes
default:
    @just --list

# Install dependencies and set up local environment
setup:
    npm install
    [ -f .env ] || cp .env.example .env
    @echo "Setup complete. Run 'just dev' to start."

# Start development server
dev:
    npm run dev

# Start development server on custom port
dev-port port="3000":
    PORT={{port}} npm run dev

# Run test suite
test *args="":
    npm test {{args}}

# Run tests in watch mode
test-watch:
    npm run test:watch

# Build for production
build:
    npm run build

# Run linter
lint:
    npm run lint

# Fix lint issues automatically
lint-fix:
    npm run lint -- --fix

# Format code
format:
    npm run format

# Run all checks (lint + typecheck + test)
check: lint
    npm run typecheck
    npm test

# Run full CI pipeline locally
ci: check build

# Remove build artifacts and caches
clean:
    rm -rf dist/ node_modules/.cache coverage/ .next/

# Remove everything including node_modules
clean-all: clean
    rm -rf node_modules/
    @echo "Run 'just setup' to reinstall."

# Run database migrations
db-migrate:
    npm run db:migrate

# Seed the database
db-seed:
    npm run db:seed

# Reset database (migrate + seed)
db-reset: db-migrate db-seed
```

**Justfile advantages over Makefile:**
- Spaces work for indentation (no tab traps)
- Parameters with defaults (`dev-port port="3000"`)
- Variadic arguments (`test *args=""`)
- Recipe dependencies are explicit and readable
- `just --list` is built in (no grep hack needed)
- Cross-platform: runs identically on macOS, Linux, Windows
- `just --choose` gives an interactive fuzzy picker

### Taskfile (go-task)

YAML-based task runner with dependency tracking, environment variable support, and watch mode built in. Use this for teams that prefer YAML configuration or need dependency-aware task graphs.

Requires installing `task`: `brew install go-task`, `go install github.com/go-task/task/v3/cmd/task@latest`, or via package managers.

```yaml
# Taskfile.yml
version: "3"

vars:
  BINARY_NAME: myapp

dotenv: [".env"]

tasks:
  default:
    desc: Show available tasks
    cmds:
      - task --list
    silent: true

  setup:
    desc: Install dependencies and set up local environment
    cmds:
      - npm install
      - cmd: cp .env.example .env
        status:
          - test -f .env
      - echo "Setup complete. Run 'task dev' to start."

  dev:
    desc: Start development server
    cmds:
      - npm run dev

  test:
    desc: Run test suite
    cmds:
      - npm test

  test:watch:
    desc: Run tests in watch mode
    cmds:
      - npm run test:watch

  build:
    desc: Build for production
    cmds:
      - npm run build
    sources:
      - src/**/*
      - package.json
    generates:
      - dist/**/*

  lint:
    desc: Run linter
    cmds:
      - npm run lint

  format:
    desc: Format code
    cmds:
      - npm run format

  check:
    desc: Run all checks (lint + typecheck + test)
    deps: [lint]
    cmds:
      - npm run typecheck
      - npm test

  ci:
    desc: Run full CI pipeline locally
    cmds:
      - task: check
      - task: build

  clean:
    desc: Remove build artifacts and caches
    cmds:
      - rm -rf dist/ node_modules/.cache coverage/ .next/

  clean:all:
    desc: Remove everything including node_modules
    deps: [clean]
    cmds:
      - rm -rf node_modules/
      - echo "Run 'task setup' to reinstall."

  db:migrate:
    desc: Run database migrations
    cmds:
      - npm run db:migrate

  db:seed:
    desc: Seed the database
    cmds:
      - npm run db:seed

  db:reset:
    desc: Reset database (migrate + seed)
    cmds:
      - task: db:migrate
      - task: db:seed
```

**Taskfile advantages:**
- `sources` and `generates` enable incremental builds (skip if unchanged)
- `status` conditions make tasks idempotent (only copy `.env` if it doesn't exist)
- `dotenv` loads `.env` automatically
- `deps` runs dependencies in parallel
- Colon-namespaced tasks (`db:migrate`) for organization
- Built-in `--watch` flag on any task

### npm scripts (package.json)

For Node.js-only projects, `package.json` scripts are the natural choice. No additional tool to install, every Node developer knows how they work.

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "lint": "biome check .",
    "lint:fix": "biome check --fix .",
    "format": "biome format --write .",
    "typecheck": "tsc --noEmit",
    "check": "npm run lint && npm run typecheck && npm test",
    "ci": "npm run check && npm run build",
    "db:migrate": "prisma migrate dev",
    "db:seed": "prisma db seed",
    "db:reset": "prisma migrate reset --force",
    "db:studio": "prisma studio",
    "clean": "rm -rf .next/ dist/ coverage/ node_modules/.cache",
    "prepare": "husky",
    "preinstall": "npx only-allow pnpm"
  }
}
```

**npm script conventions:**
- `dev` starts the development server (universal convention)
- `build` creates a production build
- `start` runs the production build
- `test` runs tests without watch mode (CI uses this)
- Colons group related scripts: `test:watch`, `test:coverage`, `db:migrate`, `db:seed`
- `prepare` runs after `npm install` (used for Husky hook setup)
- `preinstall` with `only-allow` enforces a single package manager
- `&&` chains sequential steps; use `concurrently` for parallel
- Do not put complex logic in npm scripts. If a script exceeds one line, move it to `scripts/` and call it: `"setup": "bash scripts/setup.sh"`

### Decision Matrix: Which Task Runner to Use

| Factor | Makefile | Justfile | Taskfile | npm scripts |
|---|---|---|---|---|
| **Best for** | Polyglot projects, CI environments, universal availability | Modern teams wanting Make ergonomics | Teams preferring YAML, need incremental builds | Node.js-only projects |
| **Install required** | No (ships with Unix) | Yes (`just`) | Yes (`task`) | No (ships with Node) |
| **Windows support** | Poor (needs make/WSL) | Native | Native | Native |
| **Parameters** | Awkward (`make target ARG=val`) | Clean (`just target val`) | Via variables | Not supported |
| **Dependencies** | Manual ordering | Explicit | Parallel + dependency graph | Manual with `&&` |
| **Incremental builds** | Manual (timestamp checks) | No | Built-in (sources/generates) | No |
| **Learning curve** | Medium (tab traps, implicit rules) | Low | Low | None |
| **Adoption** | Universal | Growing | Growing | Node ecosystem |

**Recommendation:**
- **Node.js project, no other languages** → npm scripts. No additional tooling.
- **Polyglot project or non-Node** → Makefile. Zero-dependency, universally understood.
- **Team that wants modern DX** → Justfile. Better ergonomics than Make, cross-platform.
- **Complex build dependencies, incremental builds** → Taskfile. Best dependency graph support.

---

## 2. Dev Containers

Dev Containers define reproducible development environments in a Docker container. Every team member gets the same toolchain regardless of their host OS. Works in VS Code, JetBrains IDEs, GitHub Codespaces, and Devpod.

### .devcontainer/devcontainer.json — Complete Template

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "Project Dev Environment",

  // Option A: Simple image-based setup
  "image": "mcr.microsoft.com/devcontainers/typescript-node:22",

  // Option B: Docker Compose (uncomment and remove "image" above)
  // "dockerComposeFile": "../docker-compose.yml",
  // "service": "app",
  // "workspaceFolder": "/workspace",

  // Option C: Custom Dockerfile (uncomment and remove "image" above)
  // "build": {
  //   "dockerfile": "Dockerfile",
  //   "context": "..",
  //   "args": {
  //     "NODE_VERSION": "22"
  //   }
  // },

  // Features add tools on top of the base image
  "features": {
    // Node.js (if not in base image)
    // "ghcr.io/devcontainers/features/node:1": {
    //   "version": "22"
    // },

    // Python
    // "ghcr.io/devcontainers/features/python:1": {
    //   "version": "3.12"
    // },

    // Go
    // "ghcr.io/devcontainers/features/go:1": {
    //   "version": "1.22"
    // },

    // Rust
    // "ghcr.io/devcontainers/features/rust:1": {},

    // Docker-in-Docker (for projects that build/run containers)
    // "ghcr.io/devcontainers/features/docker-in-docker:2": {},

    // Common utilities (curl, git, jq, etc.)
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true,
      "configureZshCompletion": true
    },

    // GitHub CLI
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },

  // VS Code extensions to auto-install in the container
  "customizations": {
    "vscode": {
      "extensions": [
        // Core
        "editorconfig.editorconfig",
        "streetsidesoftware.code-spell-checker",

        // JavaScript / TypeScript
        "biomejs.biome",
        "dbaeumer.vscode-eslint",
        "bradlc.vscode-tailwindcss",

        // Testing
        "vitest.explorer",

        // Git
        "eamodio.gitlens",
        "mhutchie.git-graph",

        // Docker
        "ms-azuretools.vscode-docker",

        // Database
        "prisma.prisma",
        "mtxr.sqltools"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "biomejs.biome"
      }
    }
  },

  // Ports to forward from the container to the host
  "forwardPorts": [3000, 5432, 6379],
  "portsAttributes": {
    "3000": { "label": "App", "onAutoForward": "openBrowser" },
    "5432": { "label": "PostgreSQL", "onAutoForward": "silent" },
    "6379": { "label": "Redis", "onAutoForward": "silent" }
  },

  // Commands that run at different lifecycle stages
  "postCreateCommand": "npm install && cp -n .env.example .env 2>/dev/null; true",
  "postStartCommand": "npm run db:migrate",
  "postAttachCommand": "echo 'Dev environment ready. Run: npm run dev'",

  // Run as non-root user
  "remoteUser": "node",

  // Environment variables available in the container
  "remoteEnv": {
    "DATABASE_URL": "postgresql://postgres:postgres@db:5432/myapp_dev",
    "REDIS_URL": "redis://redis:6379",
    "NODE_ENV": "development"
  },

  // Mount the host's SSH keys and Git config for git operations
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/node/.ssh,type=bind,readonly"
  ]
}
```

### Features by Stack

Uncomment the relevant features block:

**Node.js + TypeScript:**
```jsonc
"features": {
  "ghcr.io/devcontainers/features/node:1": { "version": "22" },
  "ghcr.io/devcontainers/features/common-utils:2": {},
  "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

**Python:**
```jsonc
"features": {
  "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
  "ghcr.io/devcontainers/features/common-utils:2": {},
  "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

**Go:**
```jsonc
"features": {
  "ghcr.io/devcontainers/features/go:1": { "version": "1.22" },
  "ghcr.io/devcontainers/features/common-utils:2": {},
  "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

**Full-stack (Node + Python + Docker):**
```jsonc
"features": {
  "ghcr.io/devcontainers/features/node:1": { "version": "22" },
  "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
  "ghcr.io/devcontainers/features/docker-in-docker:2": {},
  "ghcr.io/devcontainers/features/common-utils:2": {},
  "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

### VS Code Extensions by Stack

**JavaScript / TypeScript:**
```json
[
  "biomejs.biome",
  "dbaeumer.vscode-eslint",
  "bradlc.vscode-tailwindcss",
  "vitest.explorer",
  "prisma.prisma",
  "editorconfig.editorconfig"
]
```

**Python:**
```json
[
  "ms-python.python",
  "ms-python.vscode-pylance",
  "charliermarsh.ruff",
  "ms-python.debugpy",
  "editorconfig.editorconfig"
]
```

**Go:**
```json
[
  "golang.go",
  "editorconfig.editorconfig"
]
```

**Rust:**
```json
[
  "rust-lang.rust-analyzer",
  "tamasfe.even-better-toml",
  "vadimcn.vscode-lldb",
  "editorconfig.editorconfig"
]
```

### GitHub Codespaces Compatibility

`devcontainer.json` works in GitHub Codespaces without modification. Additional Codespaces-specific settings:

```jsonc
{
  // Codespaces machine type (controls CPU/RAM)
  "hostRequirements": {
    "cpus": 4,
    "memory": "8gb",
    "storage": "32gb"
  },

  // Codespace-specific secrets (reference org/repo secrets)
  "secrets": {
    "API_KEY": {
      "description": "API key for external service integration"
    },
    "DATABASE_URL": {
      "description": "Connection string for the database"
    }
  },

  // Prebuild configuration (speeds up Codespace creation)
  // Configure in repo Settings > Codespaces > Prebuild configuration
  "updateContentCommand": "npm install"
}
```

### Docker Compose Integration

When the project needs services (database, cache, etc.), use Docker Compose with the dev container:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "Project Dev Environment",
  "dockerComposeFile": ["../docker-compose.yml", "docker-compose.dev.yml"],
  "service": "app",
  "workspaceFolder": "/workspace",
  "shutdownAction": "stopCompose",
  "forwardPorts": [3000, 5432, 6379],
  "postCreateCommand": "npm install",
  "postStartCommand": "npm run db:migrate"
}
```

```yaml
# .devcontainer/docker-compose.dev.yml
# Extends the project's docker-compose.yml with dev-specific overrides
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspace:cached
      - node_modules:/workspace/node_modules
    command: sleep infinity
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/myapp_dev
      - REDIS_URL=redis://redis:6379

volumes:
  node_modules:
```

```dockerfile
# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/typescript-node:22

# Install additional tools needed for development
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*
```

---

## 3. Docker Compose for Local Development

A `docker-compose.yml` for local development services. The application itself runs on the host (not in a container) for fast iteration. The services (database, cache, queue, etc.) run in containers for zero-install setup.

### docker-compose.yml — Common Services

```yaml
# docker-compose.yml
services:
  # PostgreSQL database
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myapp_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
      # Optional: seed SQL runs on first start
      # - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Redis cache / session store / queue
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  # MinIO — S3-compatible object storage
  minio:
    image: minio/minio:latest
    restart: unless-stopped
    ports:
      - "9000:9000"    # API
      - "9001:9001"    # Console
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Mailpit — local email testing (catches all outgoing email)
  mailpit:
    image: axllent/mailpit:latest
    restart: unless-stopped
    ports:
      - "8025:8025"    # Web UI
      - "1025:1025"    # SMTP
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8025/api/v1/info"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

### Environment Variable Management

Create `.env.example` with all variables and safe defaults. Never commit `.env`.

```shell
# .env.example — copy to .env and fill in real values
# cp .env.example .env

# Application
NODE_ENV=development
PORT=3000
APP_URL=http://localhost:3000

# Database (matches docker-compose.yml defaults)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp_dev

# Redis (matches docker-compose.yml defaults)
REDIS_URL=redis://localhost:6379

# Object Storage (matches MinIO defaults in docker-compose.yml)
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=myapp-dev

# Email (matches Mailpit defaults in docker-compose.yml)
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_FROM=noreply@localhost

# Auth — generate real values for production
JWT_SECRET=dev-jwt-secret-change-in-production
SESSION_SECRET=dev-session-secret-change-in-production

# External APIs — get your own keys
# STRIPE_SECRET_KEY=sk_test_...
# OPENAI_API_KEY=sk-...
```

### Volume Mounting for Hot Reload

When the application runs inside Docker (instead of on the host), mount the source for hot reload:

```yaml
# docker-compose.override.yml — development overrides
services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app:cached
      - /app/node_modules    # Prevent host node_modules from overriding container's
    environment:
      - NODE_ENV=development
    command: npm run dev
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
```

The `:cached` flag on the volume mount improves performance on macOS by allowing the container's view of the filesystem to be slightly behind the host. The anonymous volume for `node_modules` prevents the host's `node_modules` (which may have different native binaries) from overriding the container's copy.

### Health Checks

Every service in `docker-compose.yml` should have a health check. This enables `depends_on` with `condition: service_healthy` so the application waits for services to be ready before starting.

Pattern for each service type:

| Service | Health check command |
|---|---|
| PostgreSQL | `pg_isready -U postgres` |
| MySQL | `mysqladmin ping -h localhost` |
| Redis | `redis-cli ping` |
| MongoDB | `mongosh --eval "db.runCommand('ping')"` |
| MinIO | `curl -f http://localhost:9000/minio/health/live` |
| Elasticsearch | `curl -f http://localhost:9200/_cluster/health` |
| RabbitMQ | `rabbitmq-diagnostics -q ping` |
| HTTP service | `curl -f http://localhost:PORT/health` or `wget --spider` |

---

## 4. Setup Scripts

### scripts/setup.sh — Idempotent Setup

The setup script must be safe to run multiple times. Running it twice should produce the same result as running it once. It checks for prerequisites, installs what's missing, and skips what's already done.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()   { error "$@"; exit 1; }

# ─── Check Prerequisites ───────────────────────────────────────────

check_command() {
  if command -v "$1" &>/dev/null; then
    ok "$1 found ($(command -v "$1"))"
    return 0
  else
    error "$1 not found"
    return 1
  fi
}

check_version() {
  local cmd="$1" min_version="$2" actual_version
  actual_version=$($cmd --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
  if [ -z "$actual_version" ]; then
    warn "Could not determine $cmd version"
    return 0
  fi
  # Simple version comparison (major.minor)
  if printf '%s\n' "$min_version" "$actual_version" | sort -V | head -1 | grep -q "$min_version"; then
    ok "$cmd version $actual_version (>= $min_version)"
    return 0
  else
    error "$cmd version $actual_version is below minimum $min_version"
    return 1
  fi
}

info "Checking prerequisites..."
MISSING=0

check_command git       || MISSING=1
check_command node      || MISSING=1
check_command npm       || MISSING=1
check_command docker    || MISSING=1

# Optional: check minimum versions
check_version node "18.0" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
  echo ""
  die "Missing prerequisites. Install the tools above and re-run this script."
fi

echo ""

# ─── Install Dependencies ──────────────────────────────────────────

info "Installing dependencies..."
npm install
ok "Dependencies installed"

# ─── Set Up Environment ────────────────────────────────────────────

if [ ! -f .env ]; then
  info "Creating .env from .env.example..."
  cp .env.example .env
  ok "Created .env — review and update values as needed"
else
  ok ".env already exists (skipping)"
fi

# ─── Start Services ────────────────────────────────────────────────

info "Starting Docker services..."
docker compose up -d
ok "Services started (PostgreSQL, Redis)"

# Wait for database to be ready
info "Waiting for database..."
RETRIES=30
until docker compose exec -T db pg_isready -U postgres &>/dev/null; do
  RETRIES=$((RETRIES - 1))
  if [ "$RETRIES" -le 0 ]; then
    die "Database failed to start. Check: docker compose logs db"
  fi
  sleep 1
done
ok "Database is ready"

# ─── Run Migrations ────────────────────────────────────────────────

info "Running database migrations..."
npm run db:migrate
ok "Migrations complete"

# ─── Seed Data (optional) ──────────────────────────────────────────

if [ "${SEED:-}" = "1" ] || [ "${1:-}" = "--seed" ]; then
  info "Seeding database..."
  npm run db:seed
  ok "Database seeded"
else
  info "Skipping database seed (run with --seed or SEED=1 to seed)"
fi

# ─── Done ───────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}=== Setup complete ===${NC}"
echo ""
echo "Next steps:"
echo "  npm run dev        Start the development server"
echo "  npm test           Run the test suite"
echo "  make help          See all available commands"
echo ""
```

**Python variant — prerequisite section:**

```bash
check_command python3   || MISSING=1
check_command pip3      || MISSING=1
check_version python3 "3.10" || MISSING=1

# Install dependencies
info "Creating virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
ok "Dependencies installed in .venv"
```

**Go variant — prerequisite section:**

```bash
check_command go        || MISSING=1
check_version go "1.21" || MISSING=1

# Install dependencies
info "Downloading Go modules..."
go mod download
ok "Go modules downloaded"

info "Installing development tools..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/air-verse/air@latest
ok "Development tools installed"
```

### Key Design Principles for Setup Scripts

1. **Idempotent** — running twice does not break anything. Use `[ -f .env ] || cp .env.example .env` not bare `cp`.
2. **Fail fast** — `set -euo pipefail` at the top. Check prerequisites before doing anything.
3. **Informative** — print what you are doing and what succeeded. Color-coded output.
4. **No sudo** — never require root. If a tool needs root, tell the user to install it themselves.
5. **No interactivity** — the script should run unattended. Use flags or env vars for options.
6. **Platform-aware** — detect macOS vs Linux when commands differ. Use `uname -s` to branch.

---

## 5. Version Managers

Version manager config files pin the language runtime version. Commit these files so every developer and CI uses the same version.

### .nvmrc / .node-version (Node.js)

```
22
```

Both `.nvmrc` and `.node-version` use the same format. `.nvmrc` is for nvm, `.node-version` is for fnm, nodenv, volta, and mise. Use `.node-version` — it has broader tool support.

To auto-switch on `cd`, add to `~/.zshrc`:
- **fnm**: `eval "$(fnm env --use-on-cd)"`
- **nvm**: install the `avn` plugin or use `nvm use` manually

### .python-version (Python)

```
3.12
```

Used by pyenv, mise, and other Python version managers. Specifying a minor version (not patch) lets the manager pick the latest patch release.

### .ruby-version (Ruby)

```
3.3
```

Used by rbenv, rvm, mise, and chruby.

### .tool-versions (asdf / mise)

For polyglot projects with multiple language runtimes:

```
nodejs 22.12.0
python 3.12.8
ruby 3.3.6
golang 1.22.10
```

Both asdf and mise read `.tool-versions`. mise also supports its own `mise.toml` format:

```toml
# mise.toml (alternative to .tool-versions for mise users)
[tools]
node = "22"
python = "3.12"
ruby = "3.3"
go = "1.22"

[env]
NODE_ENV = "development"

[tasks.dev]
run = "npm run dev"
```

**Recommendation:** Use `.tool-versions` if the team uses asdf or mise. Use individual version files (`.node-version`, `.python-version`) if the team uses language-specific managers. The individual files have the broadest compatibility.

### rust-toolchain.toml (Rust)

```toml
[toolchain]
channel = "1.78"
components = ["rustfmt", "clippy"]
targets = ["x86_64-unknown-linux-gnu", "wasm32-unknown-unknown"]
profile = "default"
```

Rustup reads this file automatically. The `components` field ensures rustfmt and clippy are installed alongside the compiler. Specifying targets is only needed for cross-compilation.

### .go-version (Go)

```
1.22
```

Less common than the others. Used by goenv and some CI systems. Go's built-in toolchain management (`go1.22.0 download`) is increasingly popular and does not use a dotfile — it reads the `go` directive in `go.mod`:

```
// go.mod
module github.com/user/project

go 1.22
```

**Recommendation:** For Go projects, rely on the `go` directive in `go.mod` rather than a separate `.go-version` file. The `go` directive is standard and read by `go build` itself.

---

## 6. IDE Configuration

### .vscode/settings.json — Format on Save, Linter Integration

```jsonc
// .vscode/settings.json
{
  // Format on save — the single most impactful DX setting
  "editor.formatOnSave": true,

  // Default formatter (pick one per ecosystem)
  // JavaScript/TypeScript with Biome:
  "editor.defaultFormatter": "biomejs.biome",
  // JavaScript/TypeScript with Prettier:
  // "editor.defaultFormatter": "esbenp.prettier-vscode",
  // Python:
  // "editor.defaultFormatter": "charliermarsh.ruff",
  // Go:
  // "editor.defaultFormatter": "golang.go",
  // Rust:
  // "editor.defaultFormatter": "rust-lang.rust-analyzer",

  // Language-specific overrides
  "[json]": { "editor.defaultFormatter": "biomejs.biome" },
  "[jsonc]": { "editor.defaultFormatter": "biomejs.biome" },
  "[markdown]": { "editor.defaultFormatter": null, "editor.wordWrap": "on" },
  "[yaml]": { "editor.defaultFormatter": "redhat.vscode-yaml" },

  // Ruler at conventional line lengths
  "editor.rulers": [80, 120],

  // Trim whitespace (matches .editorconfig)
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,

  // ESLint integration (if using ESLint instead of Biome)
  // "eslint.validate": ["javascript", "typescript", "javascriptreact", "typescriptreact"],
  // "editor.codeActionsOnSave": {
  //   "source.fixAll.eslint": "explicit"
  // },

  // Python settings
  // "python.analysis.typeCheckingMode": "standard",
  // "python.defaultInterpreterPath": ".venv/bin/python",

  // File exclusions — hide noise in the explorer
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/.next": true,
    "**/dist": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/coverage": true
  },

  // Search exclusions — keep search results relevant
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/coverage": true,
    "**/*.min.js": true,
    "**/package-lock.json": true,
    "**/pnpm-lock.yaml": true
  },

  // TypeScript settings
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.preferences.importModuleSpecifier": "non-relative"
}
```

### .vscode/extensions.json — Recommended Extensions

```jsonc
// .vscode/extensions.json
{
  "recommendations": [
    // ── Core ────────────────────────────────────────────
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker",

    // ── JavaScript / TypeScript ─────────────────────────
    "biomejs.biome",
    // "dbaeumer.vscode-eslint",         // if using ESLint
    // "esbenp.prettier-vscode",         // if using Prettier

    // ── Framework-specific ──────────────────────────────
    // "bradlc.vscode-tailwindcss",      // Tailwind CSS
    // "prisma.prisma",                  // Prisma ORM
    // "graphql.vscode-graphql",         // GraphQL

    // ── Testing ─────────────────────────────────────────
    "vitest.explorer",

    // ── Git ─────────────────────────────────────────────
    "eamodio.gitlens",

    // ── Docker ──────────────────────────────────────────
    "ms-azuretools.vscode-docker",

    // ── Data ────────────────────────────────────────────
    "redhat.vscode-yaml",
    "tamasfe.even-better-toml"
  ],
  "unwantedRecommendations": [
    // Prevent conflicting formatters
    // "esbenp.prettier-vscode"          // if using Biome
  ]
}
```

**Python stack variant — replace the JS/TS recommendations:**
```json
[
  "ms-python.python",
  "ms-python.vscode-pylance",
  "charliermarsh.ruff",
  "ms-python.debugpy"
]
```

**Go stack variant:**
```json
[
  "golang.go"
]
```

**Rust stack variant:**
```json
[
  "rust-lang.rust-analyzer",
  "tamasfe.even-better-toml",
  "vadimcn.vscode-lldb"
]
```

### .vscode/launch.json — Debug Configurations

```jsonc
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    // ── Node.js / TypeScript ────────────────────────────
    {
      "name": "Debug Server",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "console": "integratedTerminal",
      "skipFiles": ["<node_internals>/**", "node_modules/**"]
    },
    {
      "name": "Debug Current Test File",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/vitest",
      "args": ["run", "${relativeFile}"],
      "console": "integratedTerminal",
      "skipFiles": ["<node_internals>/**", "node_modules/**"]
    },
    // ── Next.js ─────────────────────────────────────────
    {
      "name": "Debug Next.js",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "env": { "NODE_OPTIONS": "--inspect" },
      "console": "integratedTerminal",
      "serverReadyAction": {
        "pattern": "- Local:.+(https?://.+)",
        "uriFormat": "%s",
        "action": "debugWithChrome"
      }
    },
    // ── Chrome (frontend) ───────────────────────────────
    {
      "name": "Debug in Chrome",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}/src"
    }

    // ── Python ──────────────────────────────────────────
    // {
    //   "name": "Debug Python",
    //   "type": "debugpy",
    //   "request": "launch",
    //   "module": "uvicorn",
    //   "args": ["app.main:app", "--reload"],
    //   "console": "integratedTerminal"
    // },
    // {
    //   "name": "Debug Python Tests",
    //   "type": "debugpy",
    //   "request": "launch",
    //   "module": "pytest",
    //   "args": ["${relativeFile}", "-v"],
    //   "console": "integratedTerminal"
    // }

    // ── Go ──────────────────────────────────────────────
    // {
    //   "name": "Debug Go",
    //   "type": "go",
    //   "request": "launch",
    //   "mode": "auto",
    //   "program": "${workspaceFolder}/cmd/server"
    // },
    // {
    //   "name": "Debug Go Test",
    //   "type": "go",
    //   "request": "launch",
    //   "mode": "test",
    //   "program": "${fileDirname}"
    // }
  ]
}
```

### JetBrains (.idea/) — What to Commit vs .gitignore

JetBrains IDEs store project configuration in `.idea/`. Some files are shareable, some are user-specific.

**Commit these (shared project config):**
```
.idea/codeStyles/
.idea/inspectionProfiles/
.idea/runConfigurations/
.idea/dictionaries/
.idea/scopes/
.idea/externalDependencies.xml
```

**Gitignore these (user-specific):**
```gitignore
# .gitignore — JetBrains section
.idea/*
!.idea/codeStyles/
!.idea/inspectionProfiles/
!.idea/runConfigurations/
!.idea/dictionaries/
!.idea/scopes/
!.idea/externalDependencies.xml

# Always ignore these
.idea/*.iml
.idea/modules.xml
.idea/workspace.xml
.idea/tasks.xml
.idea/usage.statistics.xml
.idea/shelf/
.idea/httpRequests/
.idea/dataSources/
.idea/dataSources.local.xml
```

**Rule of thumb:** If it controls code style, inspections, or run configurations that the team should share, commit it. If it stores personal workspace state, caches, or local paths, ignore it.

---

## 7. Deployment Configuration Files

### Dockerfile — Multi-Stage Build Template

```dockerfile
# ── Stage 1: Dependencies ────────────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app

# Copy package files first (cache layer for dependencies)
COPY package.json package-lock.json ./
RUN npm ci --production=false

# ── Stage 2: Build ───────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# Prune dev dependencies after build
RUN npm prune --production

# ── Stage 3: Production ─────────────────────────────────────────
FROM node:22-alpine AS production
WORKDIR /app

# Security: run as non-root
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup appuser

# Copy only what's needed to run
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./

USER appuser

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

**Python variant:**
```dockerfile
FROM python:3.12-slim AS build
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir .
COPY . .

FROM python:3.12-slim AS production
WORKDIR /app
RUN useradd --system --no-create-home appuser
COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /app .
USER appuser
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Go variant:**
```dockerfile
FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/server ./cmd/server

FROM scratch AS production
COPY --from=build /bin/server /server
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### .dockerignore — Comprehensive Template

```
# .dockerignore

# Version control
.git
.gitignore

# Dependencies (re-installed in container)
node_modules
.venv
vendor

# Build output
dist
build
out
.next
.nuxt
coverage

# Development files
.devcontainer
.vscode
.idea
*.swp
*.swo
*~

# Environment and secrets
.env
.env.local
.env.*.local
*.pem
*.key

# Documentation (not needed in image)
docs
*.md
LICENSE
CHANGELOG.md
CONTRIBUTING.md

# CI/CD
.github
.gitlab
.gitlab-ci.yml

# Docker (prevent recursive copies)
Dockerfile*
docker-compose*
.dockerignore

# Testing
tests
test
__tests__
*.test.*
*.spec.*
jest.config.*
vitest.config.*
.nyc_output
coverage

# OS files
.DS_Store
Thumbs.db
```

### Platform Configuration Files

**vercel.json** (Vercel):
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "regions": ["iad1"],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/:path*" }
  ],
  "crons": [
    {
      "path": "/api/cron/cleanup",
      "schedule": "0 3 * * *"
    }
  ]
}
```

**netlify.toml** (Netlify):
```toml
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "22"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[dev]
  command = "npm run dev"
  port = 3000
  targetPort = 3000
```

**fly.toml** (Fly.io):
```toml
app = "myapp"
primary_region = "iad"
kill_signal = "SIGINT"
kill_timeout = "5s"

[build]

[env]
  PORT = "8080"
  NODE_ENV = "production"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0

  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

[[http_service.checks]]
  grace_period = "10s"
  interval = "30s"
  method = "GET"
  path = "/health"
  timeout = "5s"

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

**render.yaml** (Render):
```yaml
services:
  - type: web
    name: myapp
    runtime: node
    region: ohio
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm start
    healthCheckPath: /health
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: myapp-db
          property: connectionString

databases:
  - name: myapp-db
    plan: free
    region: ohio
```

**Procfile** (Heroku / Dokku):
```
web: npm start
worker: npm run worker
release: npm run db:migrate
```

---

## 8. "Zero to Running" Checklist

The gold standard: a new developer goes from `git clone` to a running application in five commands or fewer, with no tribal knowledge required.

### The Five-Command Rule

```bash
git clone <repo-url>
cd <project>
make setup          # or: npm run setup, ./scripts/setup.sh
make dev            # or: npm run dev
# App is running at http://localhost:3000
```

If setup takes more than five commands, the onboarding process needs work. If it takes more than ten minutes, automate whatever is slow.

### The Checklist

This is the sequence every `CONTRIBUTING.md` "Development Setup" section should cover:

| Step | What happens | Who does it |
|---|---|---|
| 1. Clone | `git clone` + `cd` into the project | Developer |
| 2. Install tools | Install runtime (Node, Python, Go) at the right version | Developer (guided by `.node-version`, `.python-version`, or `.tool-versions`) |
| 3. Install deps | `npm install`, `pip install`, `go mod download` | Setup script |
| 4. Set up env | Copy `.env.example` to `.env`, fill in secrets | Setup script (copy) + developer (secrets) |
| 5. Start services | `docker compose up -d` for database, Redis, etc. | Setup script |
| 6. Run migrations | Create/update database schema | Setup script |
| 7. Run app | `make dev` or `npm run dev` | Developer |
| 8. Run tests | `make test` or `npm test` to verify everything works | Developer |

Steps 3-6 should be automated in a single `make setup` or `scripts/setup.sh`. The developer should only need to do steps 1, 2, 7, and 8 manually.

### CONTRIBUTING.md — Development Setup Section Template

```markdown
## Development Setup

### Prerequisites

- [Node.js](https://nodejs.org/) v22+ (use [fnm](https://github.com/Schniz/fnm) or check `.node-version`)
- [Docker](https://www.docker.com/) and Docker Compose (for local PostgreSQL and Redis)
- [Git](https://git-scm.com/)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/org/project.git
cd project

# Run the setup script (installs deps, creates .env, starts services, runs migrations)
make setup

# Start the development server
make dev

# Open http://localhost:3000
```

### Verify Your Setup

```bash
# Run the test suite
make test

# Run the full CI check locally
make check
```

### Common Tasks

| Task | Command |
|---|---|
| Start dev server | `make dev` |
| Run tests | `make test` |
| Run tests in watch mode | `make test-watch` |
| Lint code | `make lint` |
| Format code | `make format` |
| Run all checks | `make check` |
| Reset database | `make db-reset` |
| Clean build artifacts | `make clean` |

### Troubleshooting

**Port 3000 is already in use:**
```bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9
```

**Database connection refused:**
```bash
# Check if Docker services are running
docker compose ps

# Restart services
docker compose down && docker compose up -d
```

**`make setup` fails on dependency install:**
```bash
# Clear caches and retry
rm -rf node_modules package-lock.json
npm install
```
```

### Verification: The Stranger Test

Before declaring onboarding complete, apply this test:

1. Clone the repo into a fresh directory
2. Follow only the instructions in CONTRIBUTING.md (nothing from memory)
3. Can you run the app within 5 minutes?
4. Can you run the tests?
5. Do the tests pass?
6. Is there a `make help` or equivalent that shows all available commands?

If any step fails or requires information not in the docs, the onboarding is incomplete.

## 9. AI coding agent config files

If you use Claude Code / Cursor / Copilot / Windsurf on this repo, tell them your conventions once, in a file they'll read, instead of re-typing them every conversation. Every major AI coding agent now looks for a project-local config file at start-of-session; leaving that file empty wastes the first five minutes of every interaction on re-establishing context the agent could have loaded in one shot.

This is developer-experience plumbing: the file exists to shorten the feedback loop for contributors who use AI tools, the same way a `Makefile` shortens the feedback loop for contributors at the shell. Treat it as part of onboarding DX — not as a meta-document about the project.

### The five config files covered

| File | Agent | Format | Location | Status |
|---|---|---|---|---|
| `AGENTS.md` | Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, others | Markdown | Repo root | Official (Linux Foundation Agentic AI Foundation; cross-tool standard at [agents.md](https://agents.md/)) |
| `CLAUDE.md` | Claude Code / Claude Agent SDK | Markdown | Repo root | Official (tool-specific; commonly symlinked to `AGENTS.md`) |
| `.cursorrules` | Cursor (legacy path; still read) | Plain text | Repo root | Official (deprecated in favour of `.cursor/rules/*.mdc`) |
| `.windsurfrules` | Windsurf (Codeium) | Plain text | Repo root | Official |
| `.github/copilot-instructions.md` | GitHub Copilot (VS Code, Visual Studio, JetBrains) | Markdown | `.github/` | Official |

Five formats, one job: tell an agent what the repo is, how to build and test it, and what never to do. Differences between files are almost entirely about location and the tool that reads them; the content is 80% the same. **Default canonical: `AGENTS.md`.** It is the cross-tool standard read by the broadest set of harnesses and is the file most external contributors' agents will discover first. `CLAUDE.md` is the Claude-Code-specific overlay; mirror it from `AGENTS.md` (or symlink `CLAUDE.md` -> `AGENTS.md`).

### Per-file treatment

#### `AGENTS.md`

- **Purpose:** Cross-tool agent brief governed by the Linux Foundation's Agentic AI Foundation; the open standard at [agents.md](https://agents.md/). Read natively by Codex CLI, GitHub Copilot, Cursor, Windsurf, Aider, Zed, Warp, Roo Code, Jules, Factory, Amp, Devin, and a growing list of newer harnesses. Treat this as the canonical agent brief and mirror it for tools that read tool-specific paths.
- **Location:** Repo root.
- **Format:** GitHub-flavoured Markdown. Headings, tables, fenced code blocks, and cross-references all render.
- **What to include:** One-sentence project description; primary language and framework; the two or three commands a developer runs most (build, test, lint); non-obvious conventions (commit message style, branching model, where not to put files); forbidden actions (don't commit to `main`, don't add deps without discussion, don't regenerate lockfiles casually).
- **What NOT to include:** Secrets, API keys, or full API documentation (link to the real docs). Redundant content already in `CODE_OF_CONDUCT.md` or `CONTRIBUTING.md` (link, don't duplicate). Generated content. The README. Vendor-specific instructions ("when running in Claude Code, do X"); those belong in `CLAUDE.md` as an overlay.

#### `CLAUDE.md`

- **Purpose:** Claude Code and the Claude Agent SDK read this file at session start. With `AGENTS.md` as the cross-tool canonical, `CLAUDE.md` is best treated as either (a) a symlink to `AGENTS.md` (`ln -s AGENTS.md CLAUDE.md`), or (b) a thin overlay that contains only Claude-Code-specific instructions (Skill tool usage, `.claude/settings.json` references, slash-command preferences) on top of an `@AGENTS.md` import.
- **Location:** Repo root.
- **Format:** GitHub-flavoured Markdown. Same syntax support as `AGENTS.md`. Claude Code resolves `@<file>` imports up to five levels deep, so `@AGENTS.md` at the top of `CLAUDE.md` reuses the canonical content without duplication.
- **What to include (overlay shape):** A first line that imports `AGENTS.md` (`@AGENTS.md`), then any Claude-Code-specific notes (Skill tool invocations, harness-specific settings, slash-command preferences). Keep the overlay short; the bulk of the brief belongs in `AGENTS.md`.
- **What NOT to include:** Content that contradicts `AGENTS.md`. If a rule applies to every agent, it belongs in `AGENTS.md`. The grep test: `diff CLAUDE.md AGENTS.md` (after resolving `@AGENTS.md`) should surface only Claude-Code-specific items.

#### `.cursorrules`

- **Purpose:** Cursor reads this file as a plain-text rules blob. The newer `.cursor/rules/*.mdc` directory layout is preferred going forward, but Cursor still honours `.cursorrules` for backward compatibility and many teams haven't migrated.
- **Location:** Repo root.
- **Format:** Plain text. No Markdown rendering. Keep lines under ~100 characters and use blank lines to separate sections.
- **What to include:** The same project intro + stack + conventions + forbidden actions as `CLAUDE.md`, stripped of Markdown headings.
- **What NOT to include:** Markdown tables (rendered as broken ASCII in the prompt). Long code blocks (tokens add up fast). Generated content.

#### `.windsurfrules`

- **Purpose:** Windsurf (Codeium's agentic IDE) reads this file for project-local rules. Parallel to `.cursorrules` in both purpose and format.
- **Location:** Repo root.
- **Format:** Plain text.
- **What to include:** Same content as `.cursorrules`. In practice, teams symlink `.windsurfrules` → `.cursorrules` or copy the content. Keep one canonical source and mirror into the others during release.
- **What NOT to include:** Same exclusions as `.cursorrules`.

#### `.github/copilot-instructions.md`

- **Purpose:** GitHub Copilot (VS Code, Visual Studio, JetBrains, and Copilot in the browser on github.com) reads this file as repository-scoped instructions. It applies to Copilot Chat, Copilot Edits, and inline code suggestions when the feature is enabled in the repo/workspace.
- **Location:** `.github/copilot-instructions.md` — not the repo root.
- **Format:** Markdown.
- **What to include:** Project intro, stack, conventions, build/test commands, forbidden actions — same canonical content as `CLAUDE.md`. Copilot responds especially well to explicit style directives ("Prefer `async/await` over `.then()`"; "Use `const` unless reassignment is required").
- **What NOT to include:** Organization-wide policies (those go in GitHub Copilot enterprise settings, not a per-repo file). User-specific preferences. Secrets.

### Tier placement

Which tier to include which config at depends on who reads the repo and who uses AI tools:

- **Tier 1 (Essentials).** Include `AGENTS.md` as the canonical brief **when the user IS an AI coding agent.** The meta case: a repo whose primary audience is an agent (this skill itself, an MCP server, a prompt library, a coding-agent framework). If a human reads the repo at all, they do so to debug the agent-facing contract. For these repos, `AGENTS.md` is load-bearing; it's the primary interface across every harness the agent might run in.
- **Tier 2 (Team project).** Include if at least one team member uses an AI coding agent, which today is nearly every team. Default canonical: `AGENTS.md` (cross-tool, broadest reach). Add `CLAUDE.md` as a symlink (`ln -s AGENTS.md CLAUDE.md`) or a thin Claude-Code-specific overlay if any team member uses Claude Code. Keep the canonical in sync with onboarding docs.
- **Tier 3 (Public / mature / AI-discoverable).** `AGENTS.md` is mandatory; `CLAUDE.md` recommended as an overlay or symlink. External contributors' agents (whichever harness they use) discover `AGENTS.md` first; open-source repos that omit it end up with PRs that re-learn the conventions the hard way, one reviewer round at a time.
- **Tier 4 (Hardened / regulated).** Tier 3 content plus a review process: treat `AGENTS.md` like `CONTRIBUTING.md`. It passes through code review, it's covered by `CODEOWNERS`, and changes to it appear in `CHANGELOG.md` if conventions changed.

### Canonical template

Use this as `AGENTS.md`; mirror or symlink to `CLAUDE.md` for Claude Code; mirror into `.github/copilot-instructions.md` verbatim; mirror into `.cursorrules` / `.windsurfrules` with Markdown headings stripped.

```markdown
# Acme Widget API

TypeScript + Node.js 20 HTTP API backed by PostgreSQL. Deployed to Fly.io from `main`.

## Stack

- Runtime: Node.js 20 LTS (pinned in `.node-version`)
- Language: TypeScript 5.x, strict mode
- Framework: Fastify 4.x
- Database: PostgreSQL 16, migrations via `drizzle-kit`
- Test: Vitest 1.x, integration tests via `supertest`
- Lint/format: Biome 1.x (no ESLint, no Prettier)
- Package manager: pnpm 9.x (enforced via Corepack)

## Conventions

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full contributor guide. Non-obvious rules the contributing guide does not cover:

- All new routes live under `src/routes/<domain>/`; each route exports a `register(app)` function.
- Database access goes through `src/db/` repositories; route handlers never import `drizzle` directly.
- Error responses use the `src/lib/errors.ts` helpers; never throw bare `new Error(...)` at the HTTP boundary.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `chore:`...) — enforced by `commitlint` on push.

## Commands

- `pnpm dev` — start the API in watch mode on port 3000
- `pnpm test` — run the full Vitest suite (unit + integration)
- `pnpm lint` — run Biome lint + format check
- `pnpm build` — compile TypeScript to `dist/`
- `pnpm db:migrate` — apply pending Drizzle migrations to the local database
- `pnpm db:reset` — drop and recreate the local database (destructive)

## Forbidden actions

- Do not commit directly to `main`. All changes land via pull request with at least one review.
- Do not add new runtime dependencies without opening a proposal issue first.
- Do not edit `pnpm-lock.yaml` by hand; run `pnpm install` and commit the result.
- Do not write to `dist/` — it is generated by `pnpm build` and is gitignored.
- Do not disable Biome rules inline. If a rule is wrong, change the config in `biome.json` so the exception is reviewable.
- Do not run `pnpm db:reset` against anything except your local database.
```

Keep the file under ~150 lines. Agents load it every session; long files bleed into the response budget.

**Per-tool deltas:**

- `.cursorrules` / `.windsurfrules` — same content, Markdown headings stripped. Replace `## Commands` with a blank line + `Commands:` on its own line, then the bullets.
- `.github/copilot-instructions.md` — identical Markdown content; only the path differs (`.github/copilot-instructions.md` instead of the repo root).
- `CLAUDE.md` when `AGENTS.md` is canonical: symlink (`ln -s AGENTS.md CLAUDE.md`) or a thin overlay starting with `@AGENTS.md` followed by Claude-Code-specific notes (Skill tool invocations, slash-command preferences, `.claude/settings.json` references).

### Anti-patterns

1. **Duplicating the same rules in five files.** Updates drift, agents read stale content, contributors stop trusting any of them. **Fix:** make `AGENTS.md` canonical; symlink `CLAUDE.md -> AGENTS.md` (or use a `@AGENTS.md` overlay for Claude-Code-specific additions); regenerate `.cursorrules` / `.windsurfrules` / `.github/copilot-instructions.md` from the canonical source as a pre-commit step.
2. **Listing every convention.** Agents re-read the file every session; long configs burn tokens on the obvious. **Fix:** list only non-obvious rules. Link to `CONTRIBUTING.md` for the rest.
3. **Letting agent-config rules contradict `CODE_OF_CONDUCT.md` or `CONTRIBUTING.md`.** When the `CLAUDE.md` says "always rebase before merging" and `CONTRIBUTING.md` says "use merge commits, never rebase," the agent picks one and the human team fights about the other. **Fix:** the human-facing docs are authoritative. The agent-config file should never contain policy the community docs don't already state.
4. **Including secrets or full API surfaces.** API keys in `CLAUDE.md` get committed to git history; full generated OpenAPI specs in `.cursorrules` burn tokens on content the agent could fetch on demand. **Fix:** link to secret management (`.env.example`); link to `openapi.yaml` — don't inline either.
5. **Letting the file grow past ~200 lines.** Every line costs tokens every session. **Fix:** summarise aggressively; move depth into the referenced docs (`ARCHITECTURE.md`, `CONTRIBUTING.md`).
6. **Writing once and letting it rot.** The config file documents a snapshot of conventions; six months later the team has moved on and the file still says "we use ESLint" when the team is on Biome. **Fix:** treat it as a living document — include it in the same review cycle as `CONTRIBUTING.md`; flag it in `CHANGELOG.md` when conventions change.

### Verification

A good agent-config file passes this check: clone the repo into a fresh directory, open Claude Code / Cursor / Copilot with no prior context, ask "what do I need to know to contribute?" The first response should correctly state the stack, the test command, and at least one non-obvious convention — all from the config file, with no follow-up questions.
