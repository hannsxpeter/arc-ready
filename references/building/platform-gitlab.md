# GitLab Platform Reference

GitLab-specific repository configuration: project settings, templates, CI/CD, registries, deployments, and compliance. Load this reference when the target platform is GitLab (detected by `.gitlab-ci.yml`, `.gitlab/` directory, or user statement).

GitLab bundles what GitHub splits across third-party services. CI/CD, container registry, package registry, issue tracking, wikis, pages, environments, and security scanning are all built in. This changes the setup strategy: instead of stitching together Actions + Dependabot + CodeQL + Docker Hub + npm, you configure one platform.

---

## Project settings

Configure these in **Settings > General** or via the [Projects API](https://docs.gitlab.com/ee/api/projects.html).

### Visibility

| Level | Who can see | When to use |
|---|---|---|
| **Private** | Explicit members only | Internal/proprietary projects |
| **Internal** | Any authenticated user on the instance | Company-wide visibility on self-managed |
| **Public** | Anyone, no authentication | Open source |

### Features to enable/disable

Toggle under **Settings > General > Visibility, project features, permissions**:

- **Issues** -- on for most projects, off if using external tracker (Jira, Linear)
- **Merge requests** -- always on
- **Wiki** -- on if you want in-platform docs, off if docs live in-repo
- **Snippets** -- off unless the team uses them
- **Container registry** -- on if the project ships Docker images
- **Package registry** -- on if publishing packages (npm, PyPI, Maven, etc.)
- **CI/CD** -- always on
- **Pages** -- on if deploying a static site
- **Analytics** -- on for visibility into merge request and CI metrics
- **Security and compliance** -- on for enterprise/regulated projects

### Merge request settings

Configure under **Settings > Merge requests**:

**Merge method** -- pick one:

| Method | Effect | Best for |
|---|---|---|
| **Merge commit** | Creates merge commit, preserves branch history | Projects that want full branch history |
| **Merge commit with semi-linear history** | Requires branch to be rebased before merge | Clean history with merge points |
| **Fast-forward merge** | No merge commit, linear history required | Small teams, simple workflows |

Recommended: **Merge commit with semi-linear history** for most teams. It keeps history clean without requiring squash.

**Squash commits** -- set to "Encourage" or "Require" depending on team preference. Squash cleans up WIP commits but loses granular history.

**Other settings to configure:**

```
Merge checks:
  [x] Pipelines must succeed
  [x] All threads must be resolved
  [x] Skipped pipelines are considered successful: OFF

Merge suggestions:
  [x] Enable "Suggest merge" button

After merge:
  [x] Delete source branch by default

Merge request approvals:
  Approvals required: 1 (minimum for team projects)
  [x] Prevent approval by author
  [x] Prevent editing approval rules in merge requests
  [x] Remove all approvals when commits are added
```

### Approval rules

Configure under **Settings > Merge requests > Merge request approvals** or in `CODEOWNERS`.

**Basic approval rule:**

```
Rule name: Default
Approvals required: 1
Eligible approvers: [project members with Developer+ role]
```

**CODEOWNERS-based approval** (recommended for larger projects):

Create a `CODEOWNERS` file in the repo root, `docs/`, or `.gitlab/`:

```
# CODEOWNERS
# Syntax: path @user-or-group

# Default owners for everything
* @team-leads

# Frontend
/src/components/ @frontend-team
/src/styles/ @frontend-team

# Backend
/src/api/ @backend-team
/src/models/ @backend-team

# Infrastructure
/terraform/ @devops-team
/.gitlab-ci.yml @devops-team
/Dockerfile @devops-team

# Documentation
/docs/ @tech-writers
README.md @tech-writers
```

Enable **Settings > Merge requests > Merge request approvals > Require CODEOWNERS approval** to enforce this.

### Protected branches

Configure under **Settings > Repository > Protected branches**:

```
Branch: main
  Allowed to merge: Maintainers
  Allowed to push and merge: No one
  Allowed to force push: No
  Require approval from code owners: Yes (if CODEOWNERS exists)
```

For projects using release branches:

```
Branch: release/*
  Allowed to merge: Maintainers
  Allowed to push and merge: No one
  Allowed to force push: No
```

### Protected tags

```
Tag: v*
  Allowed to create: Maintainers
```

---

## Issue templates

GitLab uses Markdown files in `.gitlab/issue_templates/`. Each `.md` file becomes a selectable template when creating a new issue.

### Bug report template

**File: `.gitlab/issue_templates/Bug.md`**

```markdown
## Summary

<!-- A clear, concise description of the bug. -->

## Environment

- **Version/Commit:** <!-- e.g., v2.1.0 or commit SHA -->
- **OS:** <!-- e.g., macOS 15.4, Ubuntu 24.04, Windows 11 -->
- **Browser (if applicable):** <!-- e.g., Chrome 124, Firefox 126 -->
- **Runtime (if applicable):** <!-- e.g., Node 22, Python 3.12 -->

## Steps to reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected behavior

<!-- What should happen. -->

## Actual behavior

<!-- What actually happens. Include error messages, stack traces, or screenshots. -->

## Screenshots / Logs

<!-- Paste relevant logs or attach screenshots. Use code blocks for log output. -->

<details>
<summary>Full error output</summary>

```
Paste logs here
```

</details>

## Possible fix

<!-- Optional: if you have an idea of what's wrong or a suggested fix. -->

## Additional context

<!-- Any other context: related issues, workarounds tried, frequency of occurrence. -->

/label ~"type::bug" ~"status::needs-triage"
```

### Feature request template

**File: `.gitlab/issue_templates/Feature.md`**

```markdown
## Problem statement

<!-- What problem does this feature solve? Who is affected? -->

## Proposed solution

<!-- Describe the desired behavior or feature. Be specific about the user experience. -->

## Alternatives considered

<!-- What other approaches did you consider? Why were they insufficient? -->

## User stories

<!-- Optional: describe from the user's perspective. -->

- As a [type of user], I want [action] so that [benefit].

## Acceptance criteria

<!-- What conditions must be met for this feature to be considered complete? -->

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Design / Mockups

<!-- Optional: attach wireframes, mockups, or design references. -->

## Implementation notes

<!-- Optional: technical considerations, affected components, dependencies. -->

## Additional context

<!-- Links to related issues, competitor examples, user research. -->

/label ~"type::feature" ~"status::needs-triage"
```

### Default issue template

To set a default template for all new issues, go to **Settings > General > Default description template for issues** and enter the template name (e.g., `Bug`).

### Quick actions in templates

GitLab supports [quick actions](https://docs.gitlab.com/ee/user/project/quick_actions.html) at the bottom of templates. Common ones:

```
/label ~"type::bug"              # Apply labels
/assign @username                # Assign to someone
/milestone %"v1.0"              # Set milestone
/weight 3                        # Set weight (for boards)
/due 2026-05-01                  # Set due date
/confidential                    # Mark confidential
```

---

## Merge request templates

Markdown files in `.gitlab/merge_request_templates/`. The file named `Default.md` is used automatically.

### Default MR template

**File: `.gitlab/merge_request_templates/Default.md`**

```markdown
## What does this MR do?

<!-- Briefly describe the change. Link the related issue(s). -->

Closes #

## Type of change

<!-- Mark the relevant option with an "x". -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactor (no functional changes)
- [ ] Documentation update
- [ ] CI/CD or infrastructure change
- [ ] Dependency update

## How to test

<!-- Step-by-step instructions to verify this change. -->

1. Check out this branch
2. Run `...`
3. Verify that `...`

## Screenshots / Recordings

<!-- If UI changes, include before/after screenshots. -->

| Before | After |
|--------|-------|
|        |       |

## Checklist

- [ ] My code follows the project's coding standards
- [ ] I have added/updated tests that prove my fix or feature works
- [ ] All new and existing tests pass locally
- [ ] I have updated documentation (if applicable)
- [ ] I have added an entry to CHANGELOG.md (if applicable)
- [ ] This MR has a descriptive title (used in squash commit message)

## Reviewer notes

<!-- Anything the reviewer should pay special attention to. -->

/label ~"workflow::in-review"
```

### Additional MR templates

Create specialized templates for common MR types:

**File: `.gitlab/merge_request_templates/Hotfix.md`**

```markdown
## Hotfix

**Severity:** <!-- Critical / High -->
**Related incident:** <!-- Link to incident or alert -->

## Root cause

<!-- What caused the issue? -->

## Fix

<!-- What does this change do to resolve it? -->

## Verification

- [ ] Fix verified in staging
- [ ] Monitoring confirms issue is resolved
- [ ] No regression in related functionality

## Rollback plan

<!-- How to revert if the fix causes problems. -->

/label ~"type::bug" ~"priority::critical"
/milestone %"Current"
```

---

## GitLab CI/CD

GitLab CI/CD is configured entirely in `.gitlab-ci.yml` at the repository root. No marketplace -- everything is built on Docker images and shell commands.

### Structure overview

```yaml
# .gitlab-ci.yml

# ─── Global settings ───────────────────────────────────────────

# Default Docker image for all jobs
default:
  image: node:22-alpine
  # Retry failed jobs (network issues, runner flakes)
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure

# Variables available to all jobs
variables:
  # Disable interactive prompts
  CI: "true"
  # Cache settings
  CACHE_FALLBACK_KEY: "default"

# ─── Stages ────────────────────────────────────────────────────

# Stages run in order. Jobs within a stage run in parallel.
stages:
  - install
  - check
  - test
  - build
  - deploy

# ─── Jobs ──────────────────────────────────────────────────────

install:
  stage: install
  script:
    - npm ci --prefer-offline
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
    policy: pull-push

lint:
  stage: check
  script:
    - npm run lint
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
    policy: pull

typecheck:
  stage: check
  script:
    - npm run typecheck
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
    policy: pull

test:
  stage: test
  script:
    - npm run test -- --coverage
  coverage: '/All files\s*\|\s*(\d+\.?\d*)\s*\|/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/
    expire_in: 7 days
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
    policy: pull

build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
    policy: pull
```

### Rules (when jobs run)

Rules replaced `only`/`except`. Always use `rules`.

```yaml
# Run on merge requests and pushes to main
lint:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

# Run only on tags
publish:
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'

# Run only on main branch
deploy-production:
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual
      allow_failure: false

# Run on schedule only
nightly-scan:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'

# Never run on certain paths
deploy:
  rules:
    - changes:
        - "docs/**/*"
        - "*.md"
      when: never
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

### Variables

```yaml
# Project-level variables (Settings > CI/CD > Variables)
# Store secrets here, NOT in .gitlab-ci.yml
#   NPM_TOKEN (masked, protected)
#   DEPLOY_KEY (masked, protected, file type)

# In-file variables
variables:
  NODE_VERSION: "22"
  # Predefined variables (available automatically):
  #   CI_COMMIT_SHA, CI_COMMIT_SHORT_SHA
  #   CI_COMMIT_BRANCH, CI_COMMIT_TAG
  #   CI_DEFAULT_BRANCH
  #   CI_PROJECT_NAME, CI_PROJECT_NAMESPACE, CI_PROJECT_PATH
  #   CI_PIPELINE_SOURCE (push, merge_request_event, schedule, etc.)
  #   CI_MERGE_REQUEST_IID, CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
  #   CI_REGISTRY, CI_REGISTRY_IMAGE (container registry)
  #   CI_API_V4_URL
```

### Caching

```yaml
# Cache by lockfile hash -- busts when dependencies change
cache:
  key:
    files:
      - package-lock.json    # or yarn.lock, pnpm-lock.yaml
    prefix: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
  policy: pull-push          # pull = read only, push = write only, pull-push = both

# Python example
cache:
  key:
    files:
      - requirements.txt
  paths:
    - .venv/

# Go example
cache:
  key:
    files:
      - go.sum
  paths:
    - .cache/go-build/
  variables:
    GOPATH: "$CI_PROJECT_DIR/.cache"
```

### Artifacts

```yaml
# Build output for downstream jobs
artifacts:
  paths:
    - dist/
    - build/
  expire_in: 1 week

# Test reports (rendered in MR widget)
artifacts:
  reports:
    junit: report.xml                    # Test results in MR
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura.xml       # Line-by-line coverage in MR diff
    sast: gl-sast-report.json            # Security scanning
    dependency_scanning: gl-dependency-report.json
    license_scanning: gl-license-report.json
  when: always                           # Upload even if job fails
```

### Includes (reusable config)

```yaml
# Include templates from the same repo
include:
  - local: '.gitlab/ci/lint.yml'
  - local: '.gitlab/ci/test.yml'
  - local: '.gitlab/ci/deploy.yml'

# Include from another project
include:
  - project: 'my-group/ci-templates'
    ref: main
    file: '/templates/node.yml'

# Include from a remote URL
include:
  - remote: 'https://example.com/ci-template.yml'

# Include GitLab's built-in templates
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Code-Quality.gitlab-ci.yml
```

### Services (databases, Redis, etc.)

```yaml
test:
  services:
    - name: postgres:16-alpine
      alias: db
    - name: redis:7-alpine
      alias: cache
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: runner
    POSTGRES_PASSWORD: runner_password
    DATABASE_URL: "postgresql://runner:runner_password@db:5432/test_db"
    REDIS_URL: "redis://cache:6379"
  script:
    - npm run test:integration
```

### Complete pipeline patterns

**Node.js / TypeScript project:**

```yaml
default:
  image: node:22-alpine

stages:
  - check
  - test
  - build
  - publish

variables:
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

cache:
  key:
    files:
      - package-lock.json
  paths:
    - .npm/
    - node_modules/

lint:
  stage: check
  script:
    - npm ci
    - npm run lint
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

typecheck:
  stage: check
  script:
    - npm ci
    - npm run typecheck
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: test
  script:
    - npm ci
    - npm run test -- --coverage --reporter=junit --outputFile=junit.xml
  coverage: '/All files\s*\|\s*(\d+\.?\d*)\s*\|/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    when: always
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG =~ /^v\d+/'

publish-npm:
  stage: publish
  script:
    - echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc
    - npm publish
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

**Python project:**

```yaml
default:
  image: python:3.12-slim

stages:
  - check
  - test
  - build
  - publish

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"

cache:
  key:
    files:
      - pyproject.toml
  paths:
    - .pip-cache/
    - .venv/

.setup-venv: &setup-venv
  before_script:
    - python -m venv .venv
    - source .venv/bin/activate
    - pip install -e ".[dev]"

lint:
  stage: check
  <<: *setup-venv
  script:
    - ruff check .
    - ruff format --check .
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

typecheck:
  stage: check
  <<: *setup-venv
  script:
    - mypy src/
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: test
  <<: *setup-venv
  script:
    - pytest --cov=src --cov-report=xml --junitxml=junit.xml
  coverage: '/TOTAL.*\s(\d+)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    when: always
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  <<: *setup-venv
  script:
    - python -m build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+/'

publish-pypi:
  stage: publish
  <<: *setup-venv
  script:
    - pip install twine
    - twine upload dist/*
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

**Go project:**

```yaml
default:
  image: golang:1.23-alpine

stages:
  - check
  - test
  - build

variables:
  GOPATH: "$CI_PROJECT_DIR/.go"
  GOFLAGS: "-mod=readonly"

cache:
  key:
    files:
      - go.sum
  paths:
    - .go/pkg/mod/

lint:
  stage: check
  image: golangci/golangci-lint:v1.62-alpine
  script:
    - golangci-lint run --timeout 5m
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: test
  script:
    - go test -v -race -coverprofile=coverage.out ./...
    - go tool cover -func=coverage.out
  coverage: '/total:\s+\(statements\)\s+(\d+\.?\d+)%/'
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
  script:
    - CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/app ./cmd/app
  artifacts:
    paths:
      - bin/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG =~ /^v\d+/'
```

**Rust project:**

```yaml
default:
  image: rust:1.82-slim

stages:
  - check
  - test
  - build

variables:
  CARGO_HOME: "$CI_PROJECT_DIR/.cargo"

cache:
  key:
    files:
      - Cargo.lock
  paths:
    - .cargo/registry/
    - .cargo/git/
    - target/

lint:
  stage: check
  script:
    - rustup component add clippy rustfmt
    - cargo fmt -- --check
    - cargo clippy -- -D warnings
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test:
  stage: test
  script:
    - cargo test --verbose
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

build:
  stage: build
  script:
    - cargo build --release
  artifacts:
    paths:
      - target/release/
    expire_in: 1 week
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG =~ /^v\d+/'
```

**Docker build and push:**

```yaml
build-image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - docker build
      --tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
      --tag "$CI_REGISTRY_IMAGE:latest"
      --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      --build-arg VCS_REF=$CI_COMMIT_SHORT_SHA
      .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
    - docker push "$CI_REGISTRY_IMAGE:latest"
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

# Tag-based push for releases
build-release-image:
  extends: build-image
  script:
    - docker build
      --tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
      --tag "$CI_REGISTRY_IMAGE:latest"
      .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
    - docker push "$CI_REGISTRY_IMAGE:latest"
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

### Multi-project and parent-child pipelines

```yaml
# Trigger a downstream project pipeline
trigger-deploy:
  stage: deploy
  trigger:
    project: my-group/deploy-configs
    branch: main
    strategy: depend     # Wait for downstream pipeline to finish

# Parent-child pipeline (same repo)
trigger-integration:
  stage: test
  trigger:
    include: .gitlab/ci/integration.yml
    strategy: depend
```

---

## Auto DevOps

Auto DevOps provides a pre-built CI/CD pipeline that automatically detects your project's language and runs build, test, code quality, security scanning, and deployment.

### What it provides

- **Auto Build** -- builds a Docker image using Buildpacks or Dockerfile
- **Auto Test** -- runs detected test framework
- **Auto Code Quality** -- runs Code Climate analysis
- **Auto SAST** -- static application security testing
- **Auto Dependency Scanning** -- checks dependencies for known vulnerabilities
- **Auto Secret Detection** -- scans for leaked secrets in code
- **Auto License Compliance** -- checks dependency licenses
- **Auto Container Scanning** -- scans Docker images for vulnerabilities
- **Auto Review Apps** -- deploys MR branches to temporary environments
- **Auto Deploy** -- deploys to Kubernetes
- **Auto Monitoring** -- sets up Prometheus monitoring

### When to use Auto DevOps vs custom CI

| Use Auto DevOps when | Use custom `.gitlab-ci.yml` when |
|---|---|
| Prototyping or getting started fast | You need specific build steps |
| Standard web app deploying to Kubernetes | Non-standard deployment targets |
| You want security scanning without config | You need fine-grained pipeline control |
| The detected language/framework is correct | Your build process is non-standard |

### Enabling Auto DevOps

```
Settings > CI/CD > Auto DevOps
  [x] Default to Auto DevOps pipeline
  Deployment strategy: Continuous deployment to production
  (or) Automatic deployment to staging, manual to production
```

### Overriding parts of Auto DevOps

You can keep Auto DevOps enabled but override specific jobs:

```yaml
# .gitlab-ci.yml -- override just the test job
include:
  - template: Auto-DevOps.gitlab-ci.yml

test:
  script:
    - npm run test:custom
```

**Recommendation:** For most production projects, write a custom `.gitlab-ci.yml`. Auto DevOps is best for getting something running quickly or for projects that fit the standard mold. Custom pipelines give you control and transparency.

---

## GitLab Pages

GitLab Pages serves static content from a CI job named `pages` that outputs to `public/`.

### Basic deployment

```yaml
pages:
  stage: deploy
  script:
    - npm run build
    - mv dist public        # GitLab Pages serves from public/
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

### Static site generators

**MkDocs:**

```yaml
pages:
  stage: deploy
  image: python:3.12-slim
  script:
    - pip install mkdocs-material
    - mkdocs build --site-dir public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

**Hugo:**

```yaml
pages:
  stage: deploy
  image: registry.gitlab.com/pages/hugo:latest
  script:
    - hugo --minify -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

**Docusaurus / React / Vite:**

```yaml
pages:
  stage: deploy
  image: node:22-alpine
  script:
    - npm ci
    - npm run build
    - mv build public       # Adjust output dir name as needed
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

### Custom domain

Configure under **Settings > Pages > New Domain**. Add a DNS CNAME record pointing your domain to `<namespace>.gitlab.io`. GitLab provides automatic Let's Encrypt certificates.

### Access control

- **Public Pages** -- anyone can view (default for public projects)
- **Access control** -- only project members can view (enable under **Settings > Pages**)

---

## Container Registry

Every GitLab project has a built-in Docker registry at `registry.gitlab.com/<namespace>/<project>`.

### Authentication

```bash
# CI/CD -- automatic credentials
docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY

# Local development -- personal access token
docker login registry.gitlab.com -u <username> -p <personal-access-token>
```

### Naming convention

```
registry.gitlab.com/<namespace>/<project>              # Default image
registry.gitlab.com/<namespace>/<project>/<image>       # Named image
registry.gitlab.com/<namespace>/<project>:<tag>          # Tagged image
```

### Building and pushing in CI

```yaml
build-image:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - |
      docker build \
        --tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA" \
        --tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" \
        .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

### Cleanup policy

Configure under **Settings > Packages and registries > Container Registry > Cleanup policies**:

```
Run cleanup: Every week
Keep the most recent: 10 tags per image name
Remove tags older than: 90 days
Remove tags matching: .*           # Regex for tags to remove
Keep tags matching: latest|v\d+    # Regex for tags to keep (never remove)
```

### Using Kaniko (no Docker-in-Docker)

Kaniko builds containers without requiring privileged mode:

```yaml
build-image:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.2-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context "$CI_PROJECT_DIR"
      --dockerfile "$CI_PROJECT_DIR/Dockerfile"
      --destination "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
      --destination "$CI_REGISTRY_IMAGE:latest"
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

---

## Package Registry

GitLab's package registry supports multiple formats. Each is accessed at the project or group level.

### npm

**Publish to GitLab:**

```json
// .npmrc (for CI)
@my-scope:registry=https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/
//gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

```json
// package.json
{
  "name": "@my-scope/my-package",
  "publishConfig": {
    "@my-scope:registry": "https://gitlab.com/api/v4/projects/PROJECT_ID/packages/npm/"
  }
}
```

```yaml
# .gitlab-ci.yml
publish-npm:
  stage: publish
  image: node:22-alpine
  script:
    - echo "@my-scope:registry=https://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/" > .npmrc
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm publish
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

**Install from GitLab:**

```
# .npmrc (for consumers)
@my-scope:registry=https://gitlab.com/api/v4/packages/npm/
//gitlab.com/api/v4/packages/npm/:_authToken=<personal-access-token>
```

### PyPI

```yaml
publish-pypi:
  stage: publish
  image: python:3.12-slim
  script:
    - pip install build twine
    - python -m build
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token
      twine upload
      --repository-url "https://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/pypi"
      dist/*
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

**Install from GitLab:**

```bash
pip install my-package --index-url "https://__token__:<personal-access-token>@gitlab.com/api/v4/projects/PROJECT_ID/packages/pypi/simple"
```

### Maven (Java)

```xml
<!-- pom.xml -->
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</distributionManagement>
```

```yaml
publish-maven:
  stage: publish
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn deploy -s ci_settings.xml
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

### Go modules

GitLab acts as a Go module proxy. No special publishing step needed -- Go modules are served directly from the repository when tags follow SemVer.

```bash
# Consumers use the module directly
GONOSUMCHECK="gitlab.com/my-group/*" \
GOFLAGS="-insecure" \
go get gitlab.com/my-group/my-project@v1.0.0
```

For private modules, configure `GOPRIVATE`:

```bash
export GOPRIVATE="gitlab.com/my-group/*"
git config --global url."https://oauth2:${PERSONAL_TOKEN}@gitlab.com".insteadOf "https://gitlab.com"
```

### Generic packages

Upload arbitrary files (binaries, tarballs, etc.):

```yaml
publish-binary:
  stage: publish
  script:
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN"
       --upload-file bin/my-app
       "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my-app/${CI_COMMIT_TAG}/my-app-linux-amd64"'
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
```

---

## Environments and deployments

GitLab tracks deployments to environments, providing deploy history, rollback, and review apps.

### Environment configuration

```yaml
deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual
      allow_failure: false
```

### Review apps (per-MR environments)

Review apps deploy each merge request to a temporary environment:

```yaml
deploy-review:
  stage: deploy
  script:
    - ./deploy.sh review "$CI_ENVIRONMENT_SLUG"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop-review
    auto_stop_in: 1 week
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

stop-review:
  stage: deploy
  script:
    - ./teardown.sh review "$CI_ENVIRONMENT_SLUG"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: manual
      allow_failure: true
```

### Deploy freezes

Configure deploy freezes under **Settings > CI/CD > Deploy freezes** to prevent deployments during critical periods (holidays, end-of-quarter, etc.).

```
Freeze period: Every Friday 5 PM to Monday 9 AM
Timezone: America/New_York
```

### Deployment safety

```yaml
deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://example.com
    deployment_tier: production   # Marks as production-tier
  resource_group: production      # Only one deploy at a time
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual
      allow_failure: false
```

`resource_group` ensures only one deployment to a given environment runs at a time -- no concurrent deploys to production.

### Rollback

GitLab tracks every deployment. To rollback: go to **Operate > Environments > production** and click the re-deploy button on a previous deployment.

---

## Project badges

Badges are configured under **Settings > General > Badges** or via API.

### Built-in badge templates

**Pipeline status:**

```
Link:  https://gitlab.com/%{project_path}/-/commits/%{default_branch}
Image: https://gitlab.com/%{project_path}/badges/%{default_branch}/pipeline.svg
```

**Coverage:**

```
Link:  https://gitlab.com/%{project_path}/-/commits/%{default_branch}
Image: https://gitlab.com/%{project_path}/badges/%{default_branch}/coverage.svg
```

**Latest release:**

```
Link:  https://gitlab.com/%{project_path}/-/releases
Image: https://gitlab.com/%{project_path}/-/badges/release.svg
```

### Using badges in README

```markdown
# My Project

[![pipeline status](https://gitlab.com/my-group/my-project/badges/main/pipeline.svg)](https://gitlab.com/my-group/my-project/-/commits/main)
[![coverage report](https://gitlab.com/my-group/my-project/badges/main/coverage.svg)](https://gitlab.com/my-group/my-project/-/commits/main)
[![Latest Release](https://gitlab.com/my-group/my-project/-/badges/release.svg)](https://gitlab.com/my-group/my-project/-/releases)
```

### Custom badges

Add custom badges for external services:

```
Name:  License
Link:  https://gitlab.com/%{project_path}/-/blob/main/LICENSE
Image: https://img.shields.io/badge/license-MIT-blue.svg

Name:  Documentation
Link:  https://my-project.gitlab.io
Image: https://img.shields.io/badge/docs-online-brightgreen.svg
```

### Coverage in CI

For the coverage badge to work, the CI job must output a coverage percentage that matches a regex. Configure the regex in `.gitlab-ci.yml`:

```yaml
test:
  script:
    - npm run test -- --coverage
  coverage: '/All files\s*\|\s*(\d+\.?\d*)\s*\|/'
```

Or set the regex globally under **Settings > CI/CD > General pipelines > Test coverage parsing**.

---

## Compliance frameworks

For regulated environments, GitLab provides compliance pipelines and frameworks.

### Compliance frameworks

Assign a compliance framework label to the project under **Settings > General > Compliance framework**. This is a visual marker plus optional pipeline enforcement.

Available on GitLab Ultimate. Common frameworks: SOC 2, HIPAA, PCI-DSS, ISO 27001, GDPR, FedRAMP.

### Compliance pipelines

A compliance pipeline runs in addition to the project's own CI pipeline. It is defined in a separate project and applied to all projects with a given compliance framework.

**In the compliance project, create `.compliance-gitlab-ci.yml`:**

```yaml
# This pipeline runs for all projects with the compliance framework assigned

include:
  # Include the project's own CI config
  - project: '$CI_PROJECT_PATH'
    ref: '$CI_COMMIT_SHA'
    file: '.gitlab-ci.yml'

# Add mandatory compliance jobs
compliance-sast:
  stage: .pre
  image: registry.gitlab.com/security-products/sast:latest
  script:
    - /analyzer run
  artifacts:
    reports:
      sast: gl-sast-report.json

compliance-secret-detection:
  stage: .pre
  image: registry.gitlab.com/security-products/secrets:latest
  script:
    - /analyzer run
  artifacts:
    reports:
      secret_detection: gl-secret-detection-report.json

compliance-audit:
  stage: .post
  script:
    - echo "Compliance checks completed for $CI_PROJECT_NAME"
    # Add custom compliance verification here
  allow_failure: false
```

### Approval rules for compliance

For compliance-sensitive projects, enforce stricter approval rules:

```
Merge request approvals:
  Approvals required: 2
  [x] Prevent approval by author
  [x] Prevent editing approval rules in merge requests
  [x] Remove all approvals when commits are added to source branch
  [x] Prevent approval by users who add commits

Eligible approvers:
  - Security team (for security-related changes)
  - Compliance officer (for regulated components)
```

### Audit events

GitLab logs audit events for compliance tracking. View under **Security and Compliance > Audit events**. Key events tracked:

- Member additions/removals
- Permission changes
- Protected branch modifications
- Merge request approvals and merges
- Project setting changes
- CI/CD variable changes

### Security scanning in CI

Add GitLab's built-in security scanners:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml

# Override variables if needed
variables:
  SAST_EXCLUDED_PATHS: "spec,test,tests,docs"
  DS_EXCLUDED_PATHS: "spec,test,tests,docs"
```

Results appear in the MR security widget and under **Security and Compliance > Vulnerability Report**.

---

## Service Desk

Service Desk provides an email address that automatically creates GitLab issues from incoming emails. Useful for external users who do not have GitLab accounts.

### Enabling Service Desk

**Settings > General > Service Desk**:

```
[x] Enable Service Desk
Email address: incoming+my-group-my-project-HASH@incoming.gitlab.com
  (or custom: support@example.com via email forwarding)
```

### Service Desk templates

Create an issue template for Service Desk emails under `.gitlab/issue_templates/`. Set the default template in Service Desk settings.

**File: `.gitlab/issue_templates/ServiceDesk.md`**

```markdown
## Support Request

**Submitted by:** {{EXTERNAL_AUTHOR}}
**Email:** {{EXTERNAL_AUTHOR_EMAIL}}
**Received:** {{CREATED_AT}}

---

### Original message

{{DESCRIPTION}}

---

### Internal notes

<!-- For team use only. The external user does not see content below this line in email replies. -->

**Status:** Needs triage
**Priority:** TBD
**Assigned to:** TBD

/label ~"source::service-desk" ~"status::needs-triage"
```

### Customizing Service Desk

- **Custom email address** -- forward `support@yourdomain.com` to the generated GitLab address
- **Reply template** -- configure a thank-you auto-reply under Service Desk settings
- **Label assignment** -- use quick actions in the template to auto-label incoming issues
- **Confidential issues** -- toggle to make all Service Desk issues confidential by default

### Workflow

1. External user emails `support@yourdomain.com`
2. GitLab creates an issue with the email body as description
3. Team triages and works the issue in GitLab
4. Comments on the issue (non-internal) are emailed back to the sender
5. When the issue is closed, the sender receives a resolution notification

---

## GitLab-specific files summary

When setting up a GitLab project, generate this file tree:

```
project-root/
  .gitlab/
    issue_templates/
      Bug.md
      Feature.md
    merge_request_templates/
      Default.md
  .gitlab-ci.yml
  CODEOWNERS                 # If team project with ownership rules
```

### Settings to recommend (cannot auto-configure from files)

Document these in the project README or a setup guide:

- **Visibility level** appropriate for the project
- **Merge method** set to semi-linear or squash
- **Pipeline must succeed** before merge
- **All threads must be resolved** before merge
- **Delete source branch** after merge (default on)
- **Approval rules** with minimum 1 approver, prevent self-approval
- **Protected branches** on `main` -- no direct push
- **Protected tags** on `v*` -- only maintainers create
- **Container registry cleanup** policy
- **Deploy freezes** if applicable
- **Service Desk** enabled if accepting external feedback

### Differences from GitHub

| Capability | GitHub | GitLab |
|---|---|---|
| Issue templates | `.github/ISSUE_TEMPLATE/*.yml` (YAML forms) | `.gitlab/issue_templates/*.md` (Markdown) |
| PR/MR templates | `.github/PULL_REQUEST_TEMPLATE.md` | `.gitlab/merge_request_templates/*.md` |
| CI/CD | GitHub Actions (`.github/workflows/*.yml`) | GitLab CI (`.gitlab-ci.yml`, single file or includes) |
| Container registry | GitHub Packages / ghcr.io | Built-in per-project registry |
| Package registry | GitHub Packages (npm, Maven, NuGet, etc.) | Built-in (npm, PyPI, Maven, Go, NuGet, generic, etc.) |
| Dependency updates | Dependabot (`.github/dependabot.yml`) | Renovate (self-hosted or third-party) or GitLab Dependency Scanning |
| Security scanning | CodeQL, third-party Actions | Built-in SAST, DAST, dependency scanning, secret detection |
| Pages | GitHub Pages (from branch or Actions) | GitLab Pages (from `pages` CI job) |
| Environments | GitHub Environments with protection rules | GitLab Environments with deploy boards, review apps |
| Code owners | `CODEOWNERS` in `.github/` or root | `CODEOWNERS` in root, `docs/`, or `.gitlab/` |
| Funding | `.github/FUNDING.yml` | No equivalent -- link in README |
| Release notes | Auto-generated from `.github/release.yml` | Release from CI or API, no auto-generation config file |

When migrating between platforms, these mappings tell you what to translate. The concepts are parallel; the file locations and formats differ.
