# Community Standards Files Reference

Templates and guidance for every community standards file a repository should have.
Each template uses `<!-- CUSTOMIZE: ... -->` markers where project-specific content must be inserted.

---

## 1. README.md

The single most important file. GitHub renders it as the repository landing page.
A README without install instructions or usage examples is worse than no README -- it signals abandonment.

**Minimum viable sections:** Name, one-line description, installation, basic usage, license reference.

### Full Template

````markdown
<!-- CUSTOMIZE: Replace logo path with your project's logo -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/logo-light.svg">
  <img alt="Project Name" src="docs/assets/logo-light.svg" width="300">
</picture>

<!-- CUSTOMIZE: Replace all badge URLs with your org/repo -->
[![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/PACKAGE.svg)](https://www.npmjs.com/package/PACKAGE)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![codecov](https://codecov.io/gh/ORG/REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/ORG/REPO)

<!-- CUSTOMIZE: One sentence. What is this and why should someone care? -->
> Short, compelling description of what this project does and the problem it solves.

## Features

<!-- CUSTOMIZE: 3-6 bullet points. Focus on outcomes, not implementation. -->
- **Feature one** -- what it enables for the user
- **Feature two** -- what it enables for the user
- **Feature three** -- what it enables for the user

## Quick Start

<!-- CUSTOMIZE: Shortest possible path from zero to working. Max 5 commands. -->
```bash
npm install PACKAGE
```

```typescript
import { thing } from 'PACKAGE';

const result = thing({ option: 'value' });
console.log(result);
```

## Installation

<!-- CUSTOMIZE: All supported package managers and methods. -->
```bash
# npm
npm install PACKAGE

# yarn
yarn add PACKAGE

# pnpm
pnpm add PACKAGE
```

### Requirements

<!-- CUSTOMIZE: Minimum runtime versions, OS requirements, system dependencies. -->
- Node.js >= 18

## Usage

<!-- CUSTOMIZE: Common use cases with code examples. One subsection per use case. -->

### Basic Usage

```typescript
// Example code here
```

### Advanced Usage

```typescript
// Example code here
```

## Configuration

<!-- CUSTOMIZE: All configuration options. Use a table for clarity. -->

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `option1` | `string` | `"default"` | What it controls |
| `option2` | `boolean` | `false` | What it controls |

## API Reference

<!-- CUSTOMIZE: Public API surface. Link to full docs if extensive. -->

### `functionName(param1, param2)`

Description of what this function does.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `param1` | `string` | Yes | What it is |
| `param2` | `Options` | No | Configuration object |

**Returns:** `Promise<Result>`

## Contributing

<!-- CUSTOMIZE: Keep this brief. Point to CONTRIBUTING.md for details. -->
Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

<!-- CUSTOMIZE: Match your actual LICENSE file. -->
[MIT](LICENSE) -- see [LICENSE](LICENSE) for details.
````

### Badge URL Patterns

Common badge services and their URL patterns:

```
# GitHub Actions CI
https://github.com/ORG/REPO/actions/workflows/WORKFLOW.yml/badge.svg
Link: https://github.com/ORG/REPO/actions/workflows/WORKFLOW.yml

# npm version
https://img.shields.io/npm/v/PACKAGE.svg
Link: https://www.npmjs.com/package/PACKAGE

# PyPI version
https://img.shields.io/pypi/v/PACKAGE.svg
Link: https://pypi.org/project/PACKAGE

# License (shields.io)
https://img.shields.io/badge/License-MIT-blue.svg
https://img.shields.io/badge/License-Apache_2.0-blue.svg

# Codecov
https://codecov.io/gh/ORG/REPO/branch/main/graph/badge.svg
Link: https://codecov.io/gh/ORG/REPO

# Downloads (npm)
https://img.shields.io/npm/dm/PACKAGE.svg

# Bundle size
https://img.shields.io/bundlephobia/minzip/PACKAGE.svg
Link: https://bundlephobia.com/package/PACKAGE

# TypeScript types included
https://img.shields.io/badge/types-TypeScript-blue.svg

# Custom shields.io badge
https://img.shields.io/badge/LABEL-MESSAGE-COLOR.svg
```

### Dark Mode Logo Pattern

GitHub Markdown supports the `<picture>` element for theme-aware images. Provide two logo variants:

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="path/to/logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="path/to/logo-light.svg">
  <img alt="Project Name" src="path/to/logo-light.svg" width="300">
</picture>
```

The `<img>` fallback is required for contexts that do not support `<picture>` (npm, other renderers). Point it at the light variant since most fallback contexts have light backgrounds.

---

## 2. LICENSE

Do not hand-write license text. Use SPDX-canonical text from https://spdx.org/licenses/ or the `spdx-license-list` npm package to get legally exact wording.

### License Decision Flowchart

```
Is commercial use of your code acceptable?
├── No → GPL-3.0-only (copyleft, forces derivative works open)
│         └── Is your project a web service (SaaS)?
│             └── Yes → AGPL-3.0-only (closes the SaaS loophole)
└── Yes → Do you need patent protection?
          ├── Yes → Apache-2.0 (explicit patent grant + retaliation clause)
          └── No → MIT (maximum permissiveness, simplest terms)
```

### License Summary

| License | SPDX ID | Commercial | Patent Grant | Copyleft | SaaS Copyleft |
|---------|---------|------------|-------------|---------|---------------|
| MIT | `MIT` | Yes | No | No | No |
| Apache 2.0 | `Apache-2.0` | Yes | Yes | No | No |
| GPL v3 | `GPL-3.0-only` | Restricted | Yes | Yes | No |
| AGPL v3 | `AGPL-3.0-only` | Restricted | Yes | Yes | Yes |

### Guidance

- **MIT** -- Default for most projects. Short, well-understood, maximum adoption.
- **Apache 2.0** -- Use when contributors may hold patents related to the code. The explicit patent grant and patent retaliation clause protect everyone.
- **GPL v3** -- Use when you want all derivative works to remain open source. Companies can still use it internally but cannot distribute closed-source forks.
- **AGPL v3** -- Use for server-side / SaaS code where you want network use to trigger copyleft. GPL alone does not cover the "SaaS loophole" where a company modifies code but never distributes binaries.

### Template (MIT example -- structure only)

```
MIT License

Copyright (c) YEAR AUTHOR_OR_ORG

[SPDX-canonical full text here -- do NOT type this by hand.
 Retrieve from spdx-license-list or https://spdx.org/licenses/MIT.html]
```

**Key implementation detail:** Use the `spdx-license-list` npm package at generation time:

```typescript
import licenses from 'spdx-license-list';
const mitText = licenses['MIT'].licenseText;
// Replace "Copyright (c) <year> <copyright holders>" with actual values
```

---

## 3. CONTRIBUTING.md

Must match the project's actual workflow. A contributing guide that says "fork and PR" when the team uses trunk-based development actively harms contributors.

### Full Template (Fork-Based -- Open Source)

````markdown
# Contributing to <!-- CUSTOMIZE: project name -->

Thank you for considering a contribution. This guide covers everything you need to get started.

## Development Setup

<!-- CUSTOMIZE: All steps from clone to running tests. Must be copy-pasteable. -->

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/REPO.git
cd REPO

# Install dependencies
npm install

# Run tests to verify setup
npm test

# Start development
npm run dev
```

### Prerequisites

<!-- CUSTOMIZE: Required tools and versions. -->
- Node.js >= 18
- npm >= 9

## Branching Strategy

This project uses a **fork-based workflow**:

1. Fork the repository on GitHub
2. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. Make your changes
4. Push to your fork and open a Pull Request against `main`

### Branch Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New feature | `feat/add-export-csv` |
| `fix/` | Bug fix | `fix/null-check-parser` |
| `docs/` | Documentation only | `docs/update-api-ref` |
| `refactor/` | Code restructuring | `refactor/extract-utils` |
| `test/` | Test additions | `test/edge-cases-validator` |

## Commit Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

**Examples:**
```
feat(parser): add support for nested arrays
fix(cli): handle missing config file gracefully
docs(readme): add dark mode logo
```

## Pull Request Process

1. **Before opening a PR:**
   - Ensure all tests pass: `npm test`
   - Ensure linting passes: `npm run lint`
   - Add tests for new functionality
   - Update documentation if behavior changes

2. **PR description must include:**
   - What changed and why
   - How to test the change
   - Screenshots for UI changes
   - Link to the related issue (if any)

3. **After opening a PR:**
   - CI must pass
   - At least one maintainer approval required
   - Address review feedback in new commits (do not force-push during review)

4. **Merge strategy:** Squash and merge. The PR title becomes the commit message.

## Code Review Expectations

- **Reviewers** will focus on: correctness, test coverage, readability, and architectural fit.
- **Authors** should keep PRs small and focused. One concern per PR.
- Reviews are expected within 2 business days.
- Be kind. Assume good intent. Ask questions rather than make demands.

## Reporting Issues

### Bug Reports

Open an issue using the **Bug Report** template. Include:

- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (OS, runtime version, package version)

### Feature Requests

Open an issue using the **Feature Request** template. Include:

- Problem you are trying to solve (not just the solution you want)
- Any alternatives you have considered

## Code Style

<!-- CUSTOMIZE: Specific linting/formatting tools and configs. -->
- ESLint and Prettier are configured. Run `npm run lint` before committing.
- The CI pipeline enforces these checks.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project: [MIT](LICENSE).
````

### Variant: Branch-Based (Team Workflow)

Replace the "Branching Strategy" section for internal / team projects:

````markdown
## Branching Strategy

This project uses a **trunk-based workflow with short-lived branches**:

1. Create a branch from `main`:
   ```bash
   git checkout -b TICKET-123/short-description
   ```
2. Keep branches short-lived (< 2 days ideally)
3. Open a PR against `main`
4. After approval and CI pass, squash-merge

### Branch Naming

```
TICKET-123/short-description
```

Use your issue tracker ID as the prefix. This enables automatic linking.

### Protected Branches

- `main` -- requires PR, CI pass, and 1 approval
- `release/*` -- cut from `main` for release stabilization
````

---

## 4. CODE_OF_CONDUCT.md

Use the **Contributor Covenant v2.1** verbatim. Do not write a custom code of conduct -- it will be incomplete and untested.

### Guidance

- The full text is at https://www.contributor-covenant.org/version/2/1/code_of_conduct/
- You MUST replace the enforcement contact placeholder with a real, monitored email address. Using `example.com` addresses means you have no enforcement mechanism.
- Consider creating a dedicated email alias (e.g., `conduct@yourproject.org`) rather than using a personal address.
- If your project is part of an organization, link to the org-wide conduct policy.

### Template

````markdown
# Contributor Covenant Code of Conduct

<!-- 
  Do NOT modify the Contributor Covenant text. Use it verbatim from:
  https://www.contributor-covenant.org/version/2/1/code_of_conduct/
  
  The only customization is the enforcement contact below.
-->

## Our Pledge

[Full Contributor Covenant v2.1 text here -- retrieve from the official source]

## Enforcement

<!-- CUSTOMIZE: REQUIRED. Replace with a real, monitored contact. -->
Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement at
**<!-- CUSTOMIZE: conduct@your-real-domain.org -->**.

All complaints will be reviewed and investigated promptly and fairly.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org),
version 2.1, available at
https://www.contributor-covenant.org/version/2/1/code_of_conduct.html
````

**Critical warning:** A CODE_OF_CONDUCT.md with `example@example.com` as the contact is worse than having none. It signals that the project adopted the file performatively without building an actual enforcement process.

---

## 5. SECURITY.md

GitHub detects this file and links it from the "Security" tab. A SECURITY.md with fake contact info actively harms security researchers trying to do responsible disclosure.

### Full Template

````markdown
# Security Policy

## Supported Versions

<!-- CUSTOMIZE: List currently supported versions. Remove unsupported ones. -->

| Version | Supported          |
|---------|--------------------|
| 2.x.x  | :white_check_mark: |
| 1.x.x  | :white_check_mark: (security fixes only) |
| < 1.0  | :x:                |

## Reporting a Vulnerability

<!-- CUSTOMIZE: REQUIRED. Replace with a real, monitored security contact. -->

**Do not open a public GitHub issue for security vulnerabilities.**

To report a vulnerability, email **<!-- CUSTOMIZE: security@your-real-domain.org -->**
with the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

<!-- CUSTOMIZE: Adjust timelines to what you can actually commit to. -->

| Stage | Timeline |
|-------|----------|
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 1 week |
| Fix development | Within 30 days for critical issues |
| Public disclosure | After fix is released, coordinated with reporter |

### Process

1. **Report received** -- You get an acknowledgment with a tracking ID.
2. **Triage** -- We assess severity using CVSS scoring.
3. **Fix development** -- We develop and test a fix on a private branch.
4. **Release** -- We publish the fix and issue a security advisory via GitHub.
5. **Disclosure** -- We coordinate public disclosure timing with the reporter.

## Disclosure Policy

- We follow [coordinated vulnerability disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure).
- We will credit reporters in security advisories unless they prefer to remain anonymous.
- We ask reporters to give us reasonable time to fix issues before public disclosure.

## Security Advisories

<!-- CUSTOMIZE: Replace with your repo URL. -->
Past advisories are published at:
https://github.com/ORG/REPO/security/advisories

## Scope

<!-- CUSTOMIZE: Define what is in scope for security reports. -->
The following are in scope:

- The core library/application code
- Official plugins and extensions
- The project website (if applicable)

The following are out of scope:

- Third-party integrations not maintained by this project
- Social engineering attacks
- Denial of service attacks
````

**Critical warning:** The contact email MUST be real and monitored. `security@example.com` means vulnerability reporters will disclose publicly instead. Set up the email alias and assign a responder before publishing this file.

---

## 6. CHANGELOG.md

Use [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format strictly. This format is compatible with `conventional-changelog`, `semantic-release`, and `changesets` tooling.

### Full Template

````markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

<!-- CUSTOMIZE: Add entries above as changes are made. Example entries below. -->

## [1.0.0] - YYYY-MM-DD

### Added
- Initial public release
- Core feature description

<!-- CUSTOMIZE: Replace with your repo URL for diff links. -->
[Unreleased]: https://github.com/ORG/REPO/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ORG/REPO/releases/tag/v1.0.0
````

### Category Definitions

| Category | What goes here |
|----------|---------------|
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed in a future version |
| **Removed** | Features removed in this version |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

### Rules

- Most recent version at the top.
- Each version gets a date in `YYYY-MM-DD` format.
- `[Unreleased]` section is always present at the top for in-progress changes.
- Link each version header to a diff on GitHub/GitLab.
- Never delete old entries. The changelog is append-only.

---

## 7. SUPPORT.md

GitHub links to this file from the "New Issue" page, directing users to appropriate support channels before they open an issue.

### Full Template

````markdown
# Support

<!-- CUSTOMIZE: Project name -->

## Getting Help

<!-- CUSTOMIZE: List your actual support channels. Remove any you don't use. -->

### Community Support (Free)

- **GitHub Issues** -- Bug reports and feature requests: [Issues](https://github.com/ORG/REPO/issues)
- **GitHub Discussions** -- Questions and general discussion: [Discussions](https://github.com/ORG/REPO/discussions)
- **Discord** -- Real-time chat: [Join server](https://discord.gg/INVITE_CODE)
- **Stack Overflow** -- Tag: `your-project-tag`

### Paid Support

<!-- CUSTOMIZE: Remove this section if no paid support exists. -->
- **Enterprise support** -- Contact sales@your-domain.com
- **Priority bug fixes** -- Available through [sponsorship tiers](https://github.com/sponsors/ORG)

## Response Times

| Channel | Typical Response |
|---------|-----------------|
| GitHub Issues (bugs) | Within 1 week |
| GitHub Issues (features) | Best effort |
| GitHub Discussions | Community-driven |
| Discord | Community-driven |

## FAQ

<!-- CUSTOMIZE: Link to FAQ if one exists, or list top 3-5 common questions. -->
See the [FAQ](docs/faq.md) for answers to common questions.

## Before Asking for Help

1. Check the [documentation](https://your-docs-site.com)
2. Search [existing issues](https://github.com/ORG/REPO/issues)
3. Search [discussions](https://github.com/ORG/REPO/discussions)
4. Include version numbers, error messages, and steps to reproduce when reporting issues
````

---

## 8. AUTHORS / CONTRIBUTORS

### When to Use

- **AUTHORS** -- Use when you need to track copyright holders. Required by some licenses (Apache 2.0 recommends it). Lists people or organizations with copyright interest.
- **CONTRIBUTORS** -- Use to credit people who contributed code, docs, design, testing, etc. Broader than AUTHORS.
- Many projects use only one file, not both. For most open-source projects, CONTRIBUTORS is more appropriate.
- GitHub's contributors graph often makes a separate file unnecessary. Use one when you want to credit non-code contributions or when required by license.

### AUTHORS Template

````markdown
# Authors

<!-- CUSTOMIZE: List copyright holders. Format: Name <email> or Name (URL) -->

## Original Author

- <!-- CUSTOMIZE: Your Name <your.email@domain.com> -->

## Contributors

<!-- This file lists individuals and organizations with copyright interest.
     For a complete list of all contributors, see:
     https://github.com/ORG/REPO/graphs/contributors -->

- Contributor Name <email@domain.com>
````

### CONTRIBUTORS Template

````markdown
# Contributors

Thank you to everyone who has contributed to this project.

<!-- CUSTOMIZE: Update as contributions are accepted. -->

## Core Team

| Name | Role | GitHub |
|------|------|--------|
| <!-- CUSTOMIZE --> | Creator / Maintainer | [@handle](https://github.com/handle) |

## Contributors

<!-- For a complete list, see: https://github.com/ORG/REPO/graphs/contributors -->

- [@contributor](https://github.com/contributor) -- description of contribution
````

---

## 9. CITATION.cff

Use for academic, research, and scientific projects. GitHub renders a "Cite this repository" button when this file is present.

### Full Template

```yaml
# CITATION.cff
# See: https://citation-file-format.github.io/

cff-version: 1.2.0
title: "<!-- CUSTOMIZE: Project name -->"
message: "If you use this software, please cite it as below."
type: software

# CUSTOMIZE: List all authors
authors:
  - given-names: "<!-- CUSTOMIZE: First -->"
    family-names: "<!-- CUSTOMIZE: Last -->"
    email: "<!-- CUSTOMIZE: email@domain.com -->"
    orcid: "https://orcid.org/0000-0000-0000-0000"  # CUSTOMIZE: optional
    affiliation: "<!-- CUSTOMIZE: University or Organization -->"

# CUSTOMIZE: Repository URL
repository-code: "https://github.com/ORG/REPO"

# CUSTOMIZE: Project URL (docs site, homepage, etc.)
url: "https://your-project-site.com"

# CUSTOMIZE: Current version
version: "1.0.0"

# CUSTOMIZE: Release date
date-released: "2026-01-15"

# CUSTOMIZE: Use SPDX identifier
license: MIT

# CUSTOMIZE: Keywords for discoverability
keywords:
  - keyword-one
  - keyword-two
  - keyword-three

# CUSTOMIZE: If there is a related paper
# references:
#   - type: article
#     title: "Paper Title"
#     authors:
#       - given-names: "First"
#         family-names: "Last"
#     journal: "Journal Name"
#     year: 2026
#     doi: "10.1234/example.5678"
```

### When to Include

- Your project is used in academic research
- You want to be cited in publications
- Your project originated from a research paper
- Your funding requires tracking citations

---

## 10. ACKNOWLEDGMENTS.md

### When to Include

- Your project builds on significant prior work
- You received funding or grants
- You want to credit inspirations, tools, or communities
- Your project was developed during a residency, fellowship, or sponsored program

### Template

````markdown
# Acknowledgments

<!-- CUSTOMIZE: Remove sections that don't apply. -->

## Inspiration

<!-- CUSTOMIZE: Projects, papers, or ideas that inspired this work. -->
- [Project Name](https://link) -- for pioneering the approach to X
- [Paper Title](https://doi.org/...) -- for the algorithm behind Y

## Funding

<!-- CUSTOMIZE: Grants, sponsors, or financial supporters. -->
This project was supported by:
- [Organization Name](https://link) -- Grant #12345
- [Sponsor Name](https://link)

## Built With

<!-- CUSTOMIZE: Key libraries, tools, or services this project depends on. -->
- [Library Name](https://link) -- used for X
- [Service Name](https://link) -- provides Y

## Special Thanks

<!-- CUSTOMIZE: Individuals, communities, or teams who helped. -->
- [@person](https://github.com/person) -- for mentorship on X
- The [Community Name](https://link) community -- for feedback and testing
````

---

## Tier-Aware Generation Rules

Generated files must not reference other files that don't exist yet. Adapt templates based on the current tier.

### CONTRIBUTING.md Adaptations by Tier

**Tier 1 (Essentials):** CONTRIBUTING.md is NOT generated at Tier 1. Don't add a "Contributing" section to README that links to a non-existent file. Instead, add a one-liner: `Contributions welcome — open an issue or PR.`

**Tier 2 (Team Ready):** CONTRIBUTING.md IS generated. It may reference:
- CODE_OF_CONDUCT.md — **only if CODE_OF_CONDUCT.md is also being generated.** If not, omit the "Code of Conduct" section from CONTRIBUTING.md and remove the license-agreement line that references it.
- Issue templates — only if `.github/ISSUE_TEMPLATE/` is being generated. Otherwise, say "Open an issue on GitHub" without referencing specific templates.

**Tier 3+ (Mature):** All cross-references are safe — SECURITY.md, SUPPORT.md, CODEOWNERS all exist.

### README.md Adaptations by Tier

**Tier 1:** README links to LICENSE only. No Contributing, Security, or Changelog sections.

**Tier 2:** README adds:
- `## Contributing` section linking to CONTRIBUTING.md
- `## Changelog` section linking to CHANGELOG.md
- Only add `## Code of Conduct` link if CODE_OF_CONDUCT.md was generated

**Tier 3:** README adds:
- `## Security` section linking to SECURITY.md
- Badge row (CI, coverage, version, license)
- CODEOWNERS reference in Contributing section

### Template Conditional Markers

When generating templates, use these conditional patterns:

```markdown
<!-- IF:CODE_OF_CONDUCT -->
Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.
<!-- ENDIF:CODE_OF_CONDUCT -->

<!-- IF:SECURITY -->
## Security

Please see [SECURITY.md](SECURITY.md) for reporting vulnerabilities.
<!-- ENDIF:SECURITY -->
```

The agent should evaluate these conditions based on which files are being generated in the current run, then include or omit the sections accordingly. Do not leave conditional markers in the output.

---

## Cross-File Consistency Checklist

When generating multiple community standards files, ensure consistency across them:

| Check | Details |
|-------|---------|
| Project name | Same name in README, CONTRIBUTING, SECURITY, SUPPORT, CITATION.cff |
| License reference | README, CONTRIBUTING, and LICENSE all agree on the license type |
| Contact emails | SECURITY and CODE_OF_CONDUCT have real, different-purpose contacts |
| Repository URLs | All badge URLs, diff links, and references use the same org/repo |
| Branch name | CI badges, contributing guide, and changelog diffs all reference `main` (or whatever the default branch is) |
| Version numbers | CHANGELOG, CITATION.cff, and SECURITY supported-versions table are in sync |

## File Location Rules

GitHub is path-sensitive. Files in wrong locations will not be detected.

| File | Valid Locations | Notes |
|------|----------------|-------|
| README.md | Root, `docs/`, `.github/` | Root is standard |
| LICENSE | Root only | `LICENSE` or `LICENSE.md` or `LICENSE.txt` |
| CONTRIBUTING.md | Root, `docs/`, `.github/` | Root is standard |
| CODE_OF_CONDUCT.md | Root, `docs/`, `.github/` | Root is standard |
| SECURITY.md | Root, `docs/`, `.github/` | Root or `.github/` |
| SUPPORT.md | Root, `docs/`, `.github/` | Root or `.github/` |
| CHANGELOG.md | Root only | Convention, not platform-enforced |
| CODEOWNERS | Root, `docs/`, `.github/` | `.github/` is standard |
| FUNDING.yml | `.github/` only | Must be `.github/FUNDING.yml` |
| CITATION.cff | Root only | Must be exact filename |
| Issue templates | `.github/ISSUE_TEMPLATE/` only | Must use `.yml` for issue forms |
