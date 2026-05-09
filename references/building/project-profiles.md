# Project Profiles

The master reference for determining what to generate. Every decision about which files to create, which tools to configure, and how much ceremony to apply flows through this matrix.

**Usage:** When the skill triggers, look up the project type, stage, and audience. The intersection tells you exactly which files to generate and which tools to configure. Do not guess. Do not dump everything. Use this file.

---

## 1. Stage Definitions

### MVP (1-2 developers, proving concept)

The project exists to validate an idea. Documentation serves the author six months from now and anyone evaluating whether to use or contribute. Ceremony is the enemy -- every unnecessary file is a maintenance burden on a team that cannot afford it.

| Attribute | Value |
|---|---|
| Team size | 1-2 developers |
| Users | None to handful of early adopters |
| File count target | 5-8 files |
| CI complexity | Single workflow: lint + test + build |
| Quality tooling | Linter and formatter only |
| Release process | Manual or tag-triggered |
| Documentation depth | README with install/usage, LICENSE, .gitignore |
| Security posture | .gitignore covers secrets, basic branch protection |
| Tier ceiling | Tier 1 (Essentials) |

### Growth (3-10 developers, users arriving)

The project has proven its concept and others are joining. Documentation now serves contributors who did not write the original code. Process exists to prevent the "works on my machine" problem and keep quality from degrading as velocity increases.

| Attribute | Value |
|---|---|
| Team size | 3-10 developers |
| Users | Growing user base, early production traffic |
| File count target | 12-18 files |
| CI complexity | Lint + type check + test + build, possibly matrix |
| Quality tooling | Linter, formatter, type checker, git hooks, commit lint |
| Release process | Semi-automated (release-please or changesets) |
| Documentation depth | CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, issue/PR templates |
| Security posture | Dependabot, branch protection with reviews, secret scanning |
| Tier ceiling | Tier 2 (Team Ready) progressing to Tier 3 (Mature) |

### Enterprise (10+ developers, production traffic, compliance needs)

The project operates at scale. Documentation serves auditors, incident responders, new hires onboarding, and customers evaluating the product. Every gap in documentation is a bus-factor risk or a compliance finding.

| Attribute | Value |
|---|---|
| Team size | 10+ developers, possibly multiple teams |
| Users | Significant production traffic, paying customers |
| File count target | 20-30+ files |
| CI complexity | Full matrix, security scanning, SBOM, deploy previews |
| Quality tooling | Everything from Growth plus security linting, license scanning |
| Release process | Fully automated with provenance and signing |
| Documentation depth | ADRs, runbooks, architecture docs, API reference, governance |
| Security posture | CodeQL/SAST, dependency review, signed commits, SBOM, supply chain |
| Tier ceiling | Tier 3 (Mature) through Tier 4 (Hardened) |

---

## 2. Audience Modifiers

Audience modifiers are applied on top of the project type and stage. They adjust tone, add or remove specific files, and shift priorities.

### Open Source

Applied when the project is publicly available and accepts external contributions.

| Modification | Details |
|---|---|
| Add files | CODE_OF_CONDUCT.md, CONTRIBUTING.md (welcoming tone), FUNDING.yml, SUPPORT.md, CITATION.cff (if academic) |
| Add templates | Bug report, feature request, good-first-issue label guidance in CONTRIBUTING |
| Add config | .github/ISSUE_TEMPLATE/config.yml with external links to discussions/docs |
| Tone shift | Welcoming, assumes reader has never seen the codebase, explain jargon |
| README additions | Badges (CI, coverage, npm/PyPI version, license), "Contributing" section, "Community" section |
| Priority boost | CHANGELOG (users track releases), migration guides (users upgrade), SECURITY.md (reporters need process) |
| Labels | good first issue, help wanted, priority/*, type/*, status/* |

### Internal Team

Applied when the project is used within a single organization and not published externally.

| Modification | Details |
|---|---|
| Remove/skip files | FUNDING.yml, CITATION.cff, CODE_OF_CONDUCT.md (org-level policy applies), SUPPORT.md (use internal channels) |
| Simplify files | CONTRIBUTING.md becomes lighter (skip fork workflow, assume repo access), README skips marketing |
| Add files | docs/architecture.md (critical for onboarding), docs/runbooks/ (for on-call), docs/adr/ (decision trail) |
| Tone shift | Direct, assumes familiarity with internal tools and processes |
| README additions | Internal links (wiki, Slack channel, Jira board), team ownership, on-call rotation |
| Priority boost | Architecture docs, runbooks, ADRs, onboarding guide |

### Enterprise Customers

Applied when the project is sold to or used by enterprise customers who have compliance, security, and SLA requirements.

| Modification | Details |
|---|---|
| Add files | SECURITY.md (mandatory), SLA documentation, privacy policy reference, compliance certifications |
| Add config | Signed commits policy, SBOM generation, artifact provenance |
| Tone shift | Formal, precise, auditor-friendly language |
| README additions | Security section, compliance badges, support tiers |
| Priority boost | SECURITY.md, supply chain security, audit trail (ADRs), incident response runbooks |
| Additional docs | Data processing agreements reference, SOC2/ISO references, vulnerability disclosure policy |

---

## 3. Project Type Profiles

For each project type: the files appropriate at each stage, and type-specific notes.

### 3.1 Library / SDK

Published package consumed by other developers. API stability, versioning, and upgrade paths are paramount.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | API examples, install from registry, badges |
| LICENSE | Y | Y | Y | Critical for adoption; MIT/Apache-2.0 common |
| .gitignore | Y | Y | Y | Stack-specific + dist/build artifacts |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | Y | Y | Y | Essential from day 1 for libraries |
| CONTRIBUTING.md | - | Y | Y | |
| CODE_OF_CONDUCT.md | - | Y | Y | |
| SECURITY.md | - | Y | Y | Supported versions table critical |
| SUPPORT.md | - | - | Y | |
| CODEOWNERS | - | - | Y | |
| AUTHORS / CONTRIBUTORS | - | - | Y | |
| CITATION.cff | - | - | M | If academic/research |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Bug report must capture version |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/FUNDING.yml | - | M | M | Open source only |
| .github/dependabot.yml | - | Y | Y | |
| .github/release.yml | - | Y | Y | |
| CI workflow (ci.yml) | Y | Y | Y | Test across multiple runtime versions |
| Release workflow | - | Y | Y | Publish to registry (npm/PyPI/crates.io) |
| Security scanning workflow | - | - | Y | |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Type checker config | M | Y | Y | If applicable to stack |
| Git hooks config | - | Y | Y | |
| Commit lint config | - | Y | Y | |
| docs/getting-started.md | - | M | Y | |
| docs/api/ | - | M | Y | Generated API reference |
| docs/migration/ | - | M | Y | Breaking change guides |
| docs/adr/ | - | - | Y | |
| Makefile / Justfile | M | Y | Y | Standard targets |
| .env.example | - | - | - | Libraries rarely need env vars |
| openapi.yml | - | - | - | Not applicable |
| Dockerfile | - | - | M | For dev/test containers |
| .dockerignore | - | - | M | |
| docs/runbooks/ | - | - | - | Not applicable |

**Type-specific notes:**
- CHANGELOG.md is critical from MVP because consumers need to track breaking changes
- CI should test across multiple versions of the runtime (Node 18/20/22, Python 3.10/3.11/3.12)
- Package metadata must be complete before first publish (description, keywords, repository URL, license field)
- Do NOT commit lockfiles for libraries (they should be testing against latest compatible)
- Include a `files` or `include` field to control what ships to the registry

### 3.2 CLI Tool

Installed globally or via package manager. User experience centers on help text, install methods, and shell integration.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Install methods (brew, npm, cargo, binary), usage examples, GIF demo |
| LICENSE | Y | Y | Y | |
| .gitignore | Y | Y | Y | + binary artifacts |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | M | Y | Y | |
| CONTRIBUTING.md | - | Y | Y | |
| CODE_OF_CONDUCT.md | - | Y | Y | |
| SECURITY.md | - | M | Y | |
| SUPPORT.md | - | - | Y | |
| CODEOWNERS | - | - | Y | |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Include OS/version/shell fields |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | |
| .github/release.yml | - | Y | Y | |
| CI workflow | Y | Y | Y | Test on macOS + Linux + Windows |
| Release workflow | - | Y | Y | Build binaries for all platforms |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Git hooks config | - | Y | Y | |
| Commit lint config | - | Y | Y | |
| Makefile / Justfile | Y | Y | Y | install, build, test targets |
| man page or --help | M | Y | Y | |
| Shell completions | - | M | Y | bash, zsh, fish |
| docs/getting-started.md | - | M | Y | |
| Dockerfile | - | M | Y | For distribution |
| .dockerignore | - | M | Y | |
| Homebrew formula / Scoop manifest | - | M | Y | |
| docs/adr/ | - | - | Y | |

**Type-specific notes:**
- README must show install methods for every distribution channel (brew, npm/cargo/pip global, binary download)
- CI must test across all supported operating systems
- Release workflow should produce binaries for linux-amd64, linux-arm64, darwin-amd64, darwin-arm64, windows-amd64
- Shell completion scripts are a major UX differentiator at Growth stage
- Include a GIF or asciicast demo in README

### 3.3 Web App (SaaS)

Deployed service with users, uptime requirements, and operational complexity.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Local dev setup focus, architecture overview |
| LICENSE | Y | Y | Y | May be proprietary/source-available |
| .gitignore | Y | Y | Y | + .env, build output, uploads |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | - | M | Y | |
| CONTRIBUTING.md | - | Y | Y | |
| CODE_OF_CONDUCT.md | - | M | Y | |
| SECURITY.md | - | Y | Y | Critical -- user data at stake |
| SUPPORT.md | - | - | Y | |
| CODEOWNERS | - | M | Y | Per-feature ownership |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | Y | Y | Y | Lint + type check + test + build |
| Deploy workflow | M | Y | Y | Preview deploys on PR, production on main |
| Security scanning workflow | - | M | Y | CodeQL + dependency review |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Type checker config | M | Y | Y | |
| Git hooks config | - | Y | Y | |
| Commit lint config | - | Y | Y | |
| .env.example | Y | Y | Y | All env vars documented |
| Dockerfile | M | Y | Y | Multi-stage build |
| .dockerignore | M | Y | Y | |
| docker-compose.yml | M | Y | Y | Local dev environment |
| Makefile / Justfile | M | Y | Y | setup, dev, test, build, deploy |
| docs/architecture.md | - | Y | Y | System design, service map |
| docs/adr/ | - | M | Y | |
| docs/runbooks/ | - | M | Y | Incident response, deploy, rollback |
| docs/getting-started.md | - | Y | Y | Developer onboarding |
| openapi.yml | - | M | Y | If API-backed SaaS |
| GOVERNANCE.md | - | - | M | Large team governance |

**Type-specific notes:**
- SECURITY.md is high priority even at Growth -- SaaS handles user data
- .env.example is essential from day 1; document every environment variable
- Runbooks become critical as soon as there is production traffic
- Architecture docs prevent tribal knowledge as the team grows
- Deploy workflow should include preview/staging environments at Growth stage
- Docker setup accelerates onboarding significantly

### 3.4 API / Microservice

Headless service consumed by other services or frontends. Contract stability and operational docs matter most.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | API overview, authentication, quickstart |
| LICENSE | Y | Y | Y | |
| .gitignore | Y | Y | Y | |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | M | Y | Y | API versioning changelog |
| CONTRIBUTING.md | - | Y | Y | |
| SECURITY.md | - | Y | Y | API handles data |
| CODEOWNERS | - | M | Y | |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | Y | Y | Y | Lint + test + build + contract tests |
| Deploy workflow | M | Y | Y | |
| Security scanning workflow | - | M | Y | |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Type checker config | M | Y | Y | |
| Git hooks config | - | Y | Y | |
| openapi.yml / graphql schema | Y | Y | Y | API contract from day 1 |
| .env.example | Y | Y | Y | |
| Dockerfile | Y | Y | Y | APIs are almost always containerized |
| .dockerignore | Y | Y | Y | |
| docker-compose.yml | M | Y | Y | Local dev with dependencies |
| Makefile / Justfile | M | Y | Y | |
| docs/architecture.md | - | Y | Y | Service boundaries, data flow |
| docs/adr/ | - | M | Y | |
| docs/runbooks/ | - | Y | Y | Health checks, scaling, incidents |
| docs/api/ | M | Y | Y | Generated from OpenAPI spec |
| Health check endpoint | Y | Y | Y | /health or /healthz |
| docs/getting-started.md | - | Y | Y | Consumer quickstart |

**Type-specific notes:**
- OpenAPI spec or GraphQL schema is essential from MVP -- it IS the documentation
- Dockerfile is needed from day 1; APIs are deployed as containers
- Health check endpoint is a minimum operational requirement
- Runbooks are high priority once the service has consumers
- API versioning strategy should be documented in an ADR
- Contract/integration tests matter more than unit test coverage

### 3.5 Mobile App

iOS/Android application with platform-specific build, store submission, and release processes.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Build instructions, simulator setup, screenshots |
| LICENSE | Y | Y | Y | May be proprietary |
| .gitignore | Y | Y | Y | Xcode/Gradle artifacts, Pods, derived data |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | LFS for assets |
| CHANGELOG.md | - | Y | Y | Mapped to store release notes |
| CONTRIBUTING.md | - | Y | Y | Device testing requirements |
| SECURITY.md | - | M | Y | |
| CODEOWNERS | - | M | Y | |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Device/OS version fields |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | Screenshot checklist |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | M | Y | Y | Build + test (device matrix complex) |
| Release workflow | - | M | Y | Fastlane / store submission |
| Linter config | Y | Y | Y | SwiftLint / ktlint / eslint (RN) |
| Formatter config | Y | Y | Y | |
| Git hooks config | - | M | Y | |
| Makefile / Justfile | M | Y | Y | |
| Fastlane config | - | M | Y | Automated builds and store submission |
| docs/architecture.md | - | M | Y | |
| docs/adr/ | - | - | Y | |
| .env.example | M | Y | Y | API keys, endpoints |
| docs/getting-started.md | - | Y | Y | Dev environment setup is complex |

**Type-specific notes:**
- .gitattributes should configure Git LFS for images, fonts, and other binary assets
- .gitignore is critical and platform-specific (Xcode derived data, Gradle caches, CocoaPods)
- CI is expensive (macOS runners for iOS, emulators for Android) -- may defer to Growth
- PR template should require screenshots/screen recordings for UI changes
- Store metadata (screenshots, descriptions) may live in the repo via Fastlane
- Getting-started docs are essential because mobile dev environments are complex

### 3.6 Desktop App

Electron, Tauri, native app distributed via installers or app stores.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Download links, screenshots, system requirements |
| LICENSE | Y | Y | Y | |
| .gitignore | Y | Y | Y | Build artifacts, installers, platform dirs |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | LFS for icons/assets |
| CHANGELOG.md | M | Y | Y | Users track releases |
| CONTRIBUTING.md | - | Y | Y | |
| CODE_OF_CONDUCT.md | - | M | Y | |
| SECURITY.md | - | M | Y | Auto-update security |
| CODEOWNERS | - | - | Y | |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | OS/version/hardware fields |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | M | Y | Y | Cross-platform build matrix |
| Release workflow | - | Y | Y | Build installers, notarize, sign |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Type checker config | M | Y | Y | |
| Git hooks config | - | Y | Y | |
| Makefile / Justfile | M | Y | Y | |
| docs/architecture.md | - | M | Y | |
| docs/adr/ | - | - | Y | |
| Auto-update config | - | M | Y | Electron-updater / Sparkle / WinSparkle |
| Code signing config | - | M | Y | Platform-specific signing |

**Type-specific notes:**
- Release workflow must produce signed installers for each platform (.dmg, .exe/.msi, .AppImage/.deb)
- Code signing and notarization (macOS) are required for distribution at Growth
- Auto-update mechanism should be planned at Growth stage
- .gitattributes needs LFS for app icons and bundled assets
- CI cross-platform builds are expensive but necessary
- Issue templates should capture OS, OS version, app version, and hardware info

### 3.7 DevOps / IaC

Terraform modules, Ansible playbooks, Kubernetes manifests, infrastructure code.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Module usage, inputs/outputs, examples |
| LICENSE | Y | Y | Y | |
| .gitignore | Y | Y | Y | .terraform/, *.tfstate, credentials |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | M | Y | Y | |
| CONTRIBUTING.md | - | Y | Y | Testing infra changes |
| SECURITY.md | - | Y | Y | Infra = high security impact |
| CODEOWNERS | - | Y | Y | Infra changes need review |
| .github/ISSUE_TEMPLATE/ | - | M | Y | |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | Plan output checklist |
| .github/dependabot.yml | - | Y | Y | Terraform provider updates |
| CI workflow | Y | Y | Y | terraform fmt + validate + plan |
| Security scanning workflow | - | Y | Y | tfsec/checkov/trivy |
| Linter config | Y | Y | Y | tflint, ansible-lint, hadolint |
| Formatter config | Y | Y | Y | terraform fmt, yamllint |
| Git hooks config | - | Y | Y | Pre-commit with terraform hooks |
| Makefile / Justfile | Y | Y | Y | plan, apply, destroy targets |
| .env.example | M | Y | Y | Provider credentials (names only) |
| docs/architecture.md | M | Y | Y | Infrastructure topology |
| docs/adr/ | - | Y | Y | Infrastructure decisions are critical |
| docs/runbooks/ | M | Y | Y | Incident response, failover, scaling |
| examples/ | M | Y | Y | Usage examples for modules |
| tests/ | M | Y | Y | Terratest, kitchen-terraform |
| docs/getting-started.md | - | Y | Y | |

**Type-specific notes:**
- .gitignore MUST exclude .terraform/, *.tfstate, *.tfvars (credentials) -- security critical
- CODEOWNERS is high priority even at Growth -- infrastructure changes need mandatory review
- Security scanning (tfsec/checkov) should be in CI from Growth stage
- PR template should require `terraform plan` output
- ADRs are especially valuable for infrastructure decisions (they are expensive to reverse)
- Runbooks are essential for operational infrastructure
- Module README should document all inputs, outputs, and requirements (terraform-docs)

### 3.8 Data / ML

Jupyter notebooks, training pipelines, model serving, data processing.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Dataset description, model performance, reproduce steps |
| LICENSE | Y | Y | Y | Check data license compatibility |
| .gitignore | Y | Y | Y | Datasets, model weights, checkpoints, .ipynb_checkpoints |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | LFS for models/data |
| CHANGELOG.md | - | M | Y | |
| CONTRIBUTING.md | - | Y | Y | Data handling, experiment protocol |
| SECURITY.md | - | M | Y | Data privacy concerns |
| CODEOWNERS | - | - | Y | |
| .github/ISSUE_TEMPLATE/ | - | M | Y | |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | Experiment results checklist |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | M | Y | Y | Lint + test (training tests are expensive) |
| Linter config | Y | Y | Y | Ruff for Python |
| Formatter config | Y | Y | Y | |
| Type checker config | - | M | Y | |
| Git hooks config | - | M | Y | Notebook clean hooks |
| Makefile / Justfile | Y | Y | Y | data, train, evaluate, serve targets |
| .env.example | M | Y | Y | API keys, data paths, GPU config |
| Model card (MODEL_CARD.md) | M | Y | Y | Intended use, limitations, bias |
| Data card / datasheet | - | M | Y | Dataset provenance, preprocessing |
| docs/architecture.md | - | M | Y | Pipeline architecture |
| docs/adr/ | - | - | Y | |
| requirements.txt / pyproject.toml | Y | Y | Y | Pinned dependencies for reproducibility |
| Dockerfile | M | Y | Y | Reproducible environment |
| .dockerignore | M | Y | Y | |
| notebooks/ conventions | M | Y | Y | Naming, clearing outputs |
| DVC config (.dvc/) | - | M | Y | Data version control |
| CITATION.cff | M | Y | Y | Research citation |
| docs/experiments/ | - | M | Y | Experiment tracking |

**Type-specific notes:**
- .gitignore must exclude large data files, model weights, checkpoints -- use Git LFS or DVC
- Model card is a differentiator: intended use, limitations, ethical considerations, performance metrics
- Dependencies must be pinned for reproducibility (exact versions, not ranges)
- Makefile targets should cover the full pipeline: download data, preprocess, train, evaluate, serve
- Notebooks should have a naming convention (01-exploration, 02-preprocessing, etc.)
- .gitattributes should configure LFS for *.h5, *.pt, *.pkl, *.parquet
- CITATION.cff is high priority for academic/research projects

### 3.9 Monorepo

Multiple packages/services in one repository with shared tooling and coordinated releases.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md (root) | Y | Y | Y | Overview, package index, getting started |
| README.md (per-package) | Y | Y | Y | Each package needs its own README |
| LICENSE | Y | Y | Y | May vary per package |
| .gitignore | Y | Y | Y | Workspace-aware (node_modules, dist in all packages) |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md (root) | - | M | Y | Or per-package changelogs |
| CHANGELOG.md (per-package) | - | Y | Y | Changesets or per-package release-please |
| CONTRIBUTING.md | - | Y | Y | Monorepo-specific workflow |
| CODE_OF_CONDUCT.md | - | Y | Y | |
| SECURITY.md | - | Y | Y | |
| CODEOWNERS | - | Y | Y | Per-package ownership |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Package selection dropdown |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | Per-package ecosystems |
| CI workflow | Y | Y | Y | Affected-only: test changed packages |
| Release workflow | - | Y | Y | Coordinated multi-package releases |
| Security scanning workflow | - | - | Y | |
| Linter config (root) | Y | Y | Y | Shared config, per-package overrides |
| Formatter config (root) | Y | Y | Y | |
| Type checker config (root) | M | Y | Y | Project references / composite |
| Git hooks config | - | Y | Y | |
| Commit lint config | - | Y | Y | Scoped commits: feat(package-name): |
| Workspace config | Y | Y | Y | pnpm-workspace.yaml, Cargo.toml workspace, etc. |
| Makefile / Justfile | M | Y | Y | |
| docs/architecture.md | - | Y | Y | Package relationships, dependency graph |
| docs/adr/ | - | M | Y | |
| Turborepo / Nx config | M | Y | Y | Build orchestration and caching |

**Type-specific notes:**
- CODEOWNERS is essential at Growth -- different teams own different packages
- CI must be optimized to only test affected packages (Turborepo, Nx, or path-based filtering)
- Issue templates need a package selector dropdown
- Commit messages must be scoped to packages: `feat(auth): add OAuth flow`
- Root README must index all packages with brief descriptions and links
- Each package README must stand alone (installable instructions, API docs)
- Release coordination is the hardest problem -- changesets or release-please multi-package

### 3.10 Documentation Site

Docusaurus, MkDocs, VitePress, or similar documentation-as-code project.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | How to contribute docs, local preview |
| LICENSE | Y | Y | Y | CC-BY or similar for content |
| .gitignore | Y | Y | Y | Build output, .cache |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | - | M | Y | |
| CONTRIBUTING.md | M | Y | Y | Content style guide, PR process for docs |
| CODE_OF_CONDUCT.md | - | M | Y | |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Doc bug, missing content, improvement |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/dependabot.yml | - | Y | Y | |
| CI workflow | Y | Y | Y | Build + link check + spell check |
| Deploy workflow | Y | Y | Y | Deploy to hosting (Vercel, Netlify, GH Pages) |
| Linter config | M | Y | Y | markdownlint, Vale |
| Formatter config | M | Y | Y | Prettier for Markdown |
| Git hooks config | - | M | Y | |
| Doc site config | Y | Y | Y | docusaurus.config.js, mkdocs.yml, etc. |
| Makefile / Justfile | M | Y | Y | dev, build, serve, deploy |
| Content style guide | - | Y | Y | Voice, terminology, formatting rules |
| docs/ structure | Y | Y | Y | Diataxis or topic-based organization |
| Sidebar / nav config | Y | Y | Y | |
| Search config | - | M | Y | Algolia, Pagefind |
| Redirect config | - | M | Y | Moved/renamed pages |
| Vale config (.vale.ini) | - | M | Y | Prose linting |

**Type-specific notes:**
- Deploy workflow is needed from MVP -- docs that are not deployed are not docs
- Link checking in CI prevents broken internal and external links
- Spell checking (cspell or similar) prevents embarrassing typos in published docs
- Content structure should follow Diataxis: tutorials, how-to guides, reference, explanation
- LICENSE should be a content license (CC-BY-4.0, CC-BY-SA-4.0) not a code license
- CONTRIBUTING.md should include a content style guide or link to one
- Vale (prose linting) is a significant quality differentiator

### 3.11 Framework / Platform

Extensible framework or platform with plugin/extension APIs, used by other developers to build products.

| File / Config | MVP | Growth | Enterprise | Notes |
|---|---|---|---|---|
| README.md | Y | Y | Y | Getting started, plugin/extension quickstart |
| LICENSE | Y | Y | Y | MIT/Apache-2.0 common |
| .gitignore | Y | Y | Y | |
| .editorconfig | Y | Y | Y | |
| .gitattributes | Y | Y | Y | |
| CHANGELOG.md | Y | Y | Y | Breaking changes must be prominent |
| CONTRIBUTING.md | - | Y | Y | Plugin development guide |
| CODE_OF_CONDUCT.md | - | Y | Y | |
| SECURITY.md | - | Y | Y | Frameworks are high-value targets |
| SUPPORT.md | - | M | Y | |
| CODEOWNERS | - | M | Y | |
| GOVERNANCE.md | - | - | Y | Decision-making for a framework |
| .github/ISSUE_TEMPLATE/ | - | Y | Y | Bug, feature, plugin/extension issue |
| .github/PULL_REQUEST_TEMPLATE.md | - | Y | Y | |
| .github/FUNDING.yml | - | M | M | |
| .github/dependabot.yml | - | Y | Y | |
| .github/release.yml | - | Y | Y | |
| CI workflow | Y | Y | Y | Test framework + example plugins |
| Release workflow | - | Y | Y | |
| Security scanning workflow | - | M | Y | |
| Linter config | Y | Y | Y | |
| Formatter config | Y | Y | Y | |
| Type checker config | M | Y | Y | |
| Git hooks config | - | Y | Y | |
| Commit lint config | - | Y | Y | |
| Makefile / Justfile | M | Y | Y | |
| docs/getting-started.md | Y | Y | Y | Framework quickstart |
| docs/api/ | M | Y | Y | Plugin/extension API reference |
| docs/architecture.md | - | Y | Y | Core architecture, extension points |
| docs/migration/ | - | Y | Y | Major version migration guides |
| docs/adr/ | - | Y | Y | |
| docs/rfcs/ | - | M | Y | Design proposals for new features |
| examples/ | Y | Y | Y | Example projects/plugins |
| CITATION.cff | - | - | M | |

**Type-specific notes:**
- CHANGELOG must clearly mark breaking changes -- framework users depend on API stability
- Migration guides are essential from Growth -- framework upgrades break user code
- Extension/plugin API documentation is the most important doc after README
- Examples directory should contain working, tested example projects/plugins
- ADRs are high priority -- framework architecture decisions are very expensive to change
- RFC process (docs/rfcs/) is valuable at Enterprise for community-driven design
- GOVERNANCE.md becomes relevant when the framework has a community of maintainers
- CI should test both the framework and the example projects

---

## 4. Stack-Specific Tool Recommendations

For each major stack, the recommended tool for each quality job. Pick ONE tool per job. Do not install overlapping tools.

### JavaScript / TypeScript

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | Biome | ESLint v9 (flat config) | Biome is faster; ESLint has more plugins |
| Format | Biome | Prettier | Use same tool as linter when possible |
| Type check | TypeScript (tsc) | - | Built-in, no alternative needed |
| Test | Vitest | Jest | Vitest is faster, native ESM/TS |
| Git hooks | Husky v9 + lint-staged | Lefthook | Husky is standard in JS ecosystem |
| Commit lint | commitlint | - | @commitlint/cli + conventional config |
| Build | tsup / Vite | esbuild, Rollup, webpack | tsup for libraries, Vite for apps |
| Package manager | pnpm | npm, yarn, bun | pnpm for monorepos especially |

### Python

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | Ruff | Flake8 + isort | Ruff replaces Flake8 + isort + pyflakes |
| Format | Ruff format | Black | Ruff format is a drop-in Black replacement |
| Type check | pyright | mypy | pyright is faster, better editor integration |
| Test | pytest | unittest | pytest is the ecosystem standard |
| Git hooks | pre-commit | Lefthook | pre-commit is the Python ecosystem standard |
| Commit lint | commitlint (via pre-commit) | - | |
| Build | hatch / flit | setuptools, poetry | hatch for modern Python packaging |
| Project config | pyproject.toml | setup.cfg | pyproject.toml is the standard (PEP 621) |

### Go

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | golangci-lint | staticcheck | golangci-lint bundles multiple linters |
| Format | gofmt / goimports | gofumpt | gofmt is the standard; gofumpt is stricter |
| Type check | (built-in) | - | Go compiler handles this |
| Test | go test | - | Built-in, use testify for assertions |
| Git hooks | Lefthook | pre-commit | Lefthook is a single binary, no runtime needed |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | go build | GoReleaser | GoReleaser for cross-platform releases |
| Task runner | Makefile | Taskfile (task) | Makefile is conventional in Go |

### Rust

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | clippy | - | Built-in, comprehensive |
| Format | rustfmt | - | Built-in, canonical |
| Type check | (built-in) | - | Rust compiler handles this |
| Test | cargo test | - | Built-in test framework |
| Git hooks | Lefthook | pre-commit | Single binary, no runtime |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | cargo build | - | Built-in |
| Task runner | Makefile / cargo-make | just | |

### Java / Kotlin

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint (Java) | Checkstyle | PMD, SpotBugs | Checkstyle for style, SpotBugs for bugs |
| Lint (Kotlin) | detekt | ktlint | detekt for analysis, ktlint for style |
| Format (Java) | google-java-format | Spotless | Spotless integrates with Gradle |
| Format (Kotlin) | ktfmt / ktlint | Spotless | |
| Type check | (built-in) | - | Compiler handles this |
| Test | JUnit 5 | TestNG | JUnit 5 is the standard |
| Git hooks | Lefthook | pre-commit | |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | Gradle (Kotlin DSL) | Maven | Gradle is faster, more flexible |

### Ruby

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | RuboCop | Standard | Standard is zero-config RuboCop |
| Format | RuboCop (auto-correct) | - | RuboCop handles both |
| Type check | Sorbet | Steep (RBS) | Sorbet for large codebases |
| Test | RSpec | Minitest | RSpec for BDD style, Minitest for simplicity |
| Git hooks | Lefthook | Overcommit | Lefthook preferred, Overcommit is Ruby-native |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | Bundler / Rake | - | |

### Swift

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | SwiftLint | swift-format (Apple) | SwiftLint has more rules |
| Format | SwiftFormat (nicklockwood) | swift-format (Apple) | Community vs Apple flavor |
| Type check | (built-in) | - | Compiler handles this |
| Test | XCTest / Swift Testing | - | Swift Testing is the modern API |
| Git hooks | Lefthook | pre-commit | |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | SPM / Xcode | Bazel | SPM for packages, Xcode for apps |

### C# / .NET

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | .NET Analyzers (Roslyn) | StyleCop Analyzers | Roslyn analyzers are built-in from .NET 5+ |
| Format | dotnet format | CSharpier | dotnet format is built-in |
| Type check | (built-in) | - | Compiler handles this |
| Test | xUnit | NUnit, MSTest | xUnit is the community standard |
| Git hooks | Lefthook | Husky.Net | |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | dotnet build / MSBuild | - | |
| Task runner | dotnet CLI / Makefile | Nuke | |

### PHP

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | PHPStan | Psalm, Phan | PHPStan is the most popular |
| Format | PHP-CS-Fixer | Pint (Laravel) | Pint is PHP-CS-Fixer with Laravel defaults |
| Type check | PHPStan (level 9) | Psalm | PHPStan doubles as linter and type checker |
| Test | PHPUnit | Pest | Pest is a wrapper with better DX |
| Git hooks | pre-commit | Lefthook | |
| Commit lint | commitlint (via pre-commit/Lefthook) | - | |
| Build | Composer | - | |

### Elixir

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | Credo | - | Static analysis and style |
| Format | mix format | - | Built-in formatter |
| Type check | Dialyzer / dialyxir | Gradient | Dialyzer is the standard |
| Test | ExUnit | - | Built-in test framework |
| Git hooks | Lefthook | pre-commit | |
| Commit lint | commitlint (via Lefthook) | - | |
| Build | Mix | - | Built-in build tool |

### Zig

Zig is a systems-programming language positioned as a modern alternative to Rust and C — explicit memory management, no hidden control flow, single toolchain. Best fit: CLI tools, libraries (single-binary / FFI-friendly), systems tooling, and embedded / freestanding targets.

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | (none — `zig build`) | - | Compiler performs semantic + safety checks; no separate linter |
| Format | `zig fmt` | - | Built-in, zero-config |
| Type check | (built-in) | - | Part of `zig build` / `zig build test` |
| Test | `zig build test` | - | Inline `test "name" { ... }` blocks; Zig 0.13.0 pinned |
| Git hooks | Lefthook | pre-commit | Single-binary hook runner matches Zig's minimalism |
| Package manager | `build.zig.zon` | - | Zig 0.11+; hashes committed with manifest |
| Build | `zig build` | - | `build.zig` at repo root; pin Zig 0.13.0 |

See `repo-structure.md` § Zig and `quality-tooling.md` § 7. Zig.

### Gleam

Gleam is a statically-typed functional language on the BEAM (Erlang VM), with first-class Erlang / Elixir interop via Hex. Best fit: API / web services (Wisp, Mist), actor-based concurrency, Hex-published libraries, and Elixir-adjacent tooling.

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | `gleam check` | - | Type system acts as the linter — no separate tool |
| Format | `gleam format` | - | Built-in, zero-config |
| Type check | `gleam check` | - | Static, sound, inferred |
| Test | `gleam test` (gleeunit) | - | Tests in `test/<pkg>_test.gleam` |
| Git hooks | Lefthook | pre-commit | |
| Package manager | Hex | - | Shared with Erlang/Elixir; `manifest.toml` committed |
| Build | `gleam build` | - | Emits Erlang BEAM or JavaScript; Gleam 1.4+ / OTP 27 |

See `repo-structure.md` § Gleam and `quality-tooling.md` § 8. Gleam.

### Deno

Deno 2.x is a JavaScript / TypeScript runtime with built-in tooling (fmt, lint, type check, test, publish) and secure-by-default permissions. Best fit: CLI tools (via `deno compile`), JSR-published libraries, web services (Deno Deploy, Hono, Fresh), and scripting where Node's `node_modules/` overhead is unwanted.

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | `deno lint` | - | Built-in; rules configured in `deno.json` `"lint"` |
| Format | `deno fmt` | - | Built-in; config in `deno.json` `"fmt"` |
| Type check | `deno check` | - | TypeScript integrated into the runtime |
| Test | `deno test` | - | Built-in; assertions from `jsr:@std/assert` |
| Git hooks | Lefthook | pre-commit | |
| Package manager | (URL / JSR / npm-compat) | - | No separate manager; `deno.lock` committed |
| Publish | `deno publish` (JSR) | `deno compile` | JSR via OIDC; `deno compile` for single-file binaries |

See `repo-structure.md` § Deno and `quality-tooling.md` § 9. Deno.

### Bun

Bun 1.1+ is a Node-compatible runtime, package manager, and test runner in a single binary. Use **Bun-first** for new JS/TS projects in 2026+; use **Bun-drop-in** when migrating a Node project and only want faster installs / tests (runtime stays Node). Best fit: web services (`Bun.serve`, Hono, Elysia), npm-published libraries, test-heavy projects, and Node migrations.

| Job | Recommended (2026) | Alternative | Notes |
|---|---|---|---|
| Lint | Biome | ESLint v9 | Bun ships no linter — match JS/TS recommendation |
| Format | Biome | Prettier | Bun ships no formatter |
| Type check | `tsc --noEmit` | - | Bun executes TS at runtime but doesn't type-check |
| Test | `bun test` | Vitest, Jest | Built-in, Jest-compatible API |
| Git hooks | Husky + lint-staged | Lefthook | Matches the JS/TS ecosystem default |
| Package manager | `bun install` | - | `bun.lockb` (binary) committed in Bun-first mode |
| Build | `bun build` | tsup, Vite | Bun's bundler is fine for apps; use tsup for libs |

See `repo-structure.md` § Bun and `quality-tooling.md` § 10. Bun.

---

## 5. File Priority System

Every file falls into one of four priority levels. The priority determines the minimum project stage at which the file should exist.

### Critical -- must exist in every project

These files are required regardless of project type, stage, or audience. A repository without these is incomplete.

| File | Why critical |
|---|---|
| README.md | The entry point. Without it, nobody knows what this is or how to use it. |
| LICENSE | Legal requirement for distribution. GitHub cannot determine usage rights without it. |
| .gitignore | Prevents committing build artifacts, secrets, and OS files. Security and hygiene. |

### High -- must exist for team and open-source projects

These files become necessary as soon as more than one person works on the project or it accepts external contributions. Corresponds to Growth stage and above.

| File | Why high priority |
|---|---|
| CONTRIBUTING.md | Contributors need to know the workflow. Without it, PRs are inconsistent. |
| CODE_OF_CONDUCT.md | GitHub Community Standards requirement. Sets behavioral expectations. |
| SECURITY.md | GitHub Community Standards requirement. Vulnerability reporters need a process. |
| CHANGELOG.md | Users and contributors need to track changes between versions. |
| .editorconfig | Prevents formatting inconsistencies across editors and developers. |
| .gitattributes | Line ending normalization prevents cross-platform diff noise. |
| .github/ISSUE_TEMPLATE/ | Structured issue reporting with required fields saves triage time. |
| .github/PULL_REQUEST_TEMPLATE.md | Consistent PR descriptions with checklists improve review quality. |
| CI workflow (.github/workflows/ci.yml) | Automated quality gates prevent broken code from merging. |
| Linter config | Enforces code consistency without manual review overhead. |
| Formatter config | Eliminates formatting arguments and noisy diffs. |

### Medium -- recommended for mature projects

These files are appropriate for established open-source projects, enterprise projects, and any project with significant users or production traffic. Corresponds to Enterprise stage.

| File | Why medium priority |
|---|---|
| SUPPORT.md | Separates support requests from bug reports. |
| CODEOWNERS | Auto-assigns reviewers, ensures the right people review the right code. |
| .github/dependabot.yml | Automated dependency updates prevent security vulnerabilities from aging. |
| .github/FUNDING.yml | Enables sustainability for open-source projects. |
| .github/release.yml | Categorizes auto-generated release notes. |
| AUTHORS / CONTRIBUTORS | Credits contributors, required by some licenses (Apache-2.0). |
| docs/getting-started.md | Extends README for projects with complex setup. |
| docs/architecture.md | Prevents tribal knowledge, helps new developers understand the system. |
| docs/adr/ | Records why decisions were made, prevents relitigating settled questions. |
| Makefile / Justfile | Standard targets (setup, dev, test, build) accelerate onboarding. |
| Git hooks config | Catches lint/format issues before they reach CI. |
| Commit lint config | Enforces conventional commits for automated changelogs. |
| Type checker config | Catches type errors before runtime. |
| Release workflow | Automates version bumps, changelog, and publishing. |
| Security scanning workflow | Catches vulnerabilities before they ship. |

### Low -- nice-to-have, domain-specific

These files are appropriate for specific project types or advanced use cases. They should never be generated unless the project type or user request calls for them.

| File | When applicable |
|---|---|
| CITATION.cff | Academic/research projects that should be citable |
| GOVERNANCE.md | Large open-source projects with multiple maintainers |
| ACKNOWLEDGMENTS.md | Projects with significant third-party contributions |
| docs/runbooks/ | SaaS, API, and DevOps projects with operational responsibilities |
| docs/rfcs/ | Frameworks and platforms with community-driven design |
| docs/migration/ | Libraries and frameworks with breaking version changes |
| openapi.yml | API and microservice projects |
| Model card (MODEL_CARD.md) | ML/AI projects |
| Data card | Data/ML projects with dataset documentation needs |
| Dockerfile / .dockerignore | Projects that deploy as containers |
| docker-compose.yml | Projects with multi-service local development |
| .env.example | Projects that use environment variables |
| DVC config | ML projects with large dataset versioning |
| Fastlane config | Mobile apps with automated store submission |
| Shell completions | CLI tools |
| docs/experiments/ | ML projects tracking experiment results |
| Vale config | Documentation sites with prose quality requirements |

---

## 6. The Master Matrix

Rows = all files and configurations. Columns = project types.
Values: **Y** = yes (generate for this type), **M** = maybe (generate if stage/audience warrants), **N** = no (not applicable to this type).

This matrix represents the *maximum* file set. Stage filtering (section 3) determines which Y/M files are actually generated.

### Repository Root Files

| File | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| README.md | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| LICENSE | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| .gitignore | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| .editorconfig | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| .gitattributes | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| CHANGELOG.md | Y | Y | M | Y | M | M | M | M | Y | M | Y |
| CONTRIBUTING.md | Y | Y | Y | Y | M | M | M | M | Y | Y | Y |
| CODE_OF_CONDUCT.md | Y | Y | M | M | M | M | M | M | Y | M | Y |
| SECURITY.md | Y | M | Y | Y | Y | M | Y | M | Y | M | Y |
| SUPPORT.md | M | M | M | M | M | M | M | M | M | M | M |
| AUTHORS / CONTRIBUTORS | M | M | M | M | M | M | M | M | M | M | M |
| CITATION.cff | M | N | N | N | N | N | N | Y | N | N | M |
| GOVERNANCE.md | M | N | N | N | N | N | N | N | M | N | M |
| ACKNOWLEDGMENTS.md | M | M | M | M | M | M | M | M | M | M | M |
| Makefile / Justfile | Y | Y | M | M | M | M | Y | Y | M | M | M |
| .env.example | N | N | Y | Y | M | M | M | M | M | N | M |

### GitHub Platform Files

| File | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| .github/ISSUE_TEMPLATE/bug_report.yml | Y | Y | Y | Y | Y | Y | Y | M | Y | Y | Y |
| .github/ISSUE_TEMPLATE/feature_request.yml | Y | Y | Y | Y | Y | Y | M | M | Y | Y | Y |
| .github/ISSUE_TEMPLATE/config.yml | Y | Y | Y | Y | Y | Y | M | M | Y | Y | Y |
| .github/PULL_REQUEST_TEMPLATE.md | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| .github/FUNDING.yml | Y | M | N | N | N | N | N | M | M | M | Y |
| .github/CODEOWNERS | M | M | M | M | M | M | Y | M | Y | M | M |
| .github/dependabot.yml | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| .github/release.yml | Y | Y | M | M | M | M | M | M | Y | N | Y |

### CI/CD Workflows

| Workflow | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CI (lint + test + build) | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| Release / Publish | Y | Y | M | M | M | M | M | M | Y | M | Y |
| Deploy (preview + production) | N | N | Y | Y | N | N | M | M | N | Y | N |
| Security scanning (CodeQL) | M | M | Y | Y | M | M | Y | M | Y | N | Y |
| Dependency review | M | M | Y | Y | M | M | Y | M | Y | M | Y |
| Link check / spell check | M | M | N | N | N | N | N | N | M | Y | M |
| Cross-platform build matrix | M | Y | N | N | Y | Y | N | N | N | N | M |

### Quality Tooling

| Tool / Config | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Linter config | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| Formatter config | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| Type checker config | M | M | Y | Y | M | M | N | M | M | N | M |
| Git hooks config | M | M | M | M | M | M | M | M | M | M | M |
| Commit lint config | M | M | M | M | M | M | M | M | Y | M | M |
| Markdownlint config | M | M | M | M | N | N | M | M | M | Y | M |
| Vale config (.vale.ini) | N | N | N | N | N | N | N | N | N | Y | N |

### Documentation Files

| File / Path | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| docs/getting-started.md | Y | Y | Y | Y | Y | Y | Y | Y | M | Y | Y |
| docs/architecture.md | M | M | Y | Y | M | M | Y | M | Y | N | Y |
| docs/api/ (reference) | Y | N | M | Y | N | N | N | N | M | N | Y |
| docs/adr/ | M | M | Y | Y | M | M | Y | M | Y | N | Y |
| docs/runbooks/ | N | N | Y | Y | N | N | Y | M | M | N | N |
| docs/migration/ | Y | M | N | M | N | N | N | N | M | N | Y |
| docs/rfcs/ | M | N | N | M | N | N | N | N | M | N | Y |
| docs/experiments/ | N | N | N | N | N | N | N | Y | N | N | N |
| Content style guide | N | N | N | N | N | N | N | N | N | Y | N |
| examples/ | Y | M | N | Y | N | N | Y | M | N | M | Y |
| openapi.yml / GraphQL schema | N | N | M | Y | N | N | N | N | M | N | M |
| Model card (MODEL_CARD.md) | N | N | N | N | N | N | N | Y | N | N | N |
| Data card | N | N | N | N | N | N | N | Y | N | N | N |

### Container and Environment Files

| File | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dockerfile | M | M | Y | Y | N | M | M | Y | M | M | M |
| .dockerignore | M | M | Y | Y | N | M | M | Y | M | M | M |
| docker-compose.yml | N | N | Y | Y | N | N | M | M | M | N | M |
| .devcontainer/ | M | M | M | M | M | M | M | M | M | M | M |

### Release and Distribution

| File / Config | Library | CLI | Web App | API | Mobile | Desktop | DevOps | Data/ML | Monorepo | Doc Site | Framework |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Package metadata (npm/PyPI/crates) | Y | Y | N | N | N | N | N | M | Y | N | Y |
| .npmignore / files field | Y | M | N | N | N | N | N | N | Y | N | Y |
| Semantic release config | Y | Y | M | M | M | M | M | M | Y | M | Y |
| Changesets config | M | N | N | N | N | N | N | N | Y | N | M |
| Homebrew formula / Scoop | N | Y | N | N | N | N | N | N | N | N | N |
| Fastlane config | N | N | N | N | Y | N | N | N | N | N | N |
| Auto-update config | N | N | N | N | N | Y | N | N | N | N | N |
| Code signing config | N | M | N | N | Y | Y | N | N | N | N | N |
| Shell completions | N | Y | N | N | N | N | N | N | N | N | N |
| Man page | N | Y | N | N | N | N | N | N | N | N | N |

---

## 7. How to Use This Reference

### Step 1: Identify the project type

Match the codebase to one of the 11 project types. If it spans multiple types (e.g., a SaaS with an API), use the primary type and pull in relevant files from the secondary type.

### Step 2: Identify the project stage

Use team size, user count, and codebase maturity to determine MVP, Growth, or Enterprise.

### Step 3: Identify the audience

Determine if the project is open source, internal team, or serving enterprise customers. Apply audience modifiers from section 2.

### Step 4: Look up the project type profile

Go to section 3, find the matching project type, and read the stage-specific table. Generate only the files marked for that stage and above.

### Step 5: Look up stack-specific tools

Go to section 4, find the matching stack, and use the recommended tool for each quality job. Do not install alternative tools unless there is a specific reason.

### Step 6: Apply the priority filter

Cross-reference with section 5. Never skip Critical files. Only generate Low-priority files when the project type explicitly calls for them.

### Step 7: Validate against the master matrix

Use section 6 to verify that the file list makes sense for the project type. If a file is marked N for the project type, do not generate it regardless of stage.

### Resolution rules

When the matrix and the type profile disagree, the type profile (section 3) wins -- it has more granular stage information. The master matrix (section 6) is a cross-check, not the source of truth for stage-specific decisions.

When the audience modifier adds a file that the type profile does not mention, add it. Audience modifiers are additive.

When a file is marked M (maybe) in both the type profile and the master matrix, generate it only if: (a) the project is at Growth stage or above, AND (b) the audience modifier does not exclude it, AND (c) there is a concrete use case in this specific project.
