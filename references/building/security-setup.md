# Security Setup Reference

Reference for configuring repository security: vulnerability reporting, dependency scanning, code analysis, branch protection, signed commits, supply chain integrity, SBOM generation, and secret management.

Every config in this file is complete and ready to use. Copy, adjust project-specific values, commit.

---

## 1. SECURITY.md

Every project at growth stage or above needs a SECURITY.md. It tells security researchers how to report vulnerabilities privately instead of opening a public issue. GitHub surfaces this file in the repository's Security tab.

### Full template

```markdown
# Security Policy

## Supported versions

<!-- REPLACE: List your actively maintained versions. Remove rows for unsupported versions. -->

| Version | Supported          |
|---------|--------------------|
| 3.x     | :white_check_mark: |
| 2.x     | :white_check_mark: (security fixes only, until YYYY-MM-DD) |
| 1.x     | :x:                |
| < 1.0   | :x:                |

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

To report a vulnerability, use one of these channels:

<!-- REPLACE: Use your real security contact. Options below — pick one or both. -->

- **GitHub Security Advisories (preferred):** Use the "Report a vulnerability" button on the [Security tab](../../security/advisories/new) of this repository. This creates a private discussion between you and the maintainers.
- **Email:** Send details to **security@YOUR_DOMAIN.com** <!-- REPLACE with real email -->

### What to include

- Description of the vulnerability
- Steps to reproduce or proof of concept
- Affected versions
- Impact assessment (what can an attacker do?)
- Any suggested fix, if you have one

### What to expect

| Step | Timeline |
|------|----------|
| Acknowledgment of your report | Within **2 business days** |
| Initial assessment and severity rating | Within **5 business days** |
| Fix development and testing | Within **30 days** for critical/high severity |
| Public disclosure | After fix is released, coordinated with reporter |

We follow [coordinated vulnerability disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure). We will:

1. Confirm receipt of your report and assign a tracking ID.
2. Investigate and determine the impact and severity (using CVSS where applicable).
3. Develop and test a fix in a private fork.
4. Release the fix across all supported versions simultaneously.
5. Publish a security advisory with credit to the reporter (unless you prefer anonymity).
6. Request a CVE identifier for significant vulnerabilities.

### Scope

The following are **in scope** for security reports:

- The core project code in this repository
- Official published packages/releases
- Project-maintained infrastructure (CI/CD, published containers)

The following are **out of scope:**

- Third-party dependencies (report to the upstream project)
- Social engineering attacks against maintainers
- Denial of service via excessive API requests (rate limiting is expected behavior)

### Safe harbor

We consider security research conducted in good faith to be authorized. We will not pursue legal action against researchers who:

- Act in good faith and avoid privacy violations, data destruction, and service disruption
- Report vulnerabilities promptly and provide reasonable time for remediation
- Do not exploit vulnerabilities beyond what is necessary to demonstrate the issue

## Security best practices for contributors

- Never commit secrets, API keys, tokens, or credentials
- Use environment variables for all sensitive configuration
- Keep dependencies updated and review Dependabot/Renovate PRs promptly
- Sign your commits (see contributing guidelines)

## Past advisories

See the [Security Advisories](../../security/advisories) page for previously disclosed vulnerabilities and their fixes.
```

### Guidance for the skill

- **MVP / side project**: Skip SECURITY.md unless the project handles user data, authentication, or runs as a service.
- **Growth / team project**: Include SECURITY.md. Use GitHub Security Advisories as the primary channel (no infrastructure needed).
- **Enterprise / open source**: Include SECURITY.md with both advisory and email channels. Add PGP key for encrypted email. Add bug bounty program link if applicable.
- Always enable GitHub Private Vulnerability Reporting in repository settings (Settings > Security > Private vulnerability reporting).

---

## 2. Dependabot configuration

Dependabot checks for outdated dependencies and opens PRs. Lives at `.github/dependabot.yml`.

### Complete multi-ecosystem config

```yaml
# .github/dependabot.yml
version: 2

registries:
  # Uncomment and configure if you use private registries
  # npm-private:
  #   type: npm-registry
  #   url: https://npm.pkg.github.com
  #   token: ${{ secrets.GITHUB_TOKEN }}

updates:
  # --- GitHub Actions ---
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "ci"
    groups:
      actions-minor:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # --- npm ---
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "javascript"
    commit-message:
      prefix: "deps"
    groups:
      # Group all minor and patch production deps
      production-minor:
        dependency-type: "production"
        update-types:
          - "minor"
          - "patch"
      # Group all dev dependency updates together
      dev-dependencies:
        dependency-type: "development"
        patterns:
          - "*"
      # Group linting tools
      linting:
        patterns:
          - "eslint*"
          - "prettier*"
          - "@typescript-eslint/*"
      # Group testing tools
      testing:
        patterns:
          - "jest*"
          - "vitest*"
          - "@testing-library/*"
          - "playwright*"
          - "cypress*"
      # Group type definitions
      types:
        patterns:
          - "@types/*"
    ignore:
      # Ignore major versions — review those manually
      - dependency-name: "*"
        update-types:
          - "version-update:semver-major"
    open-pull-requests-limit: 15

  # --- pip (Python) ---
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "python"
    commit-message:
      prefix: "deps"
    groups:
      python-minor:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # --- Go modules ---
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "go"
    commit-message:
      prefix: "deps"
    groups:
      go-minor:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # --- Cargo (Rust) ---
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "rust"
    commit-message:
      prefix: "deps"
    groups:
      cargo-minor:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # --- Maven (Java/Kotlin) ---
  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "java"
    commit-message:
      prefix: "deps"
    groups:
      maven-minor:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  # --- Docker ---
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "wednesday"
      time: "09:00"
      timezone: "America/New_York"
    labels:
      - "dependencies"
      - "docker"
    commit-message:
      prefix: "deps"
```

### Scheduling strategy

| Ecosystem | Recommended interval | Rationale |
|-----------|---------------------|-----------|
| github-actions | Weekly (Monday) | Actions updates are low-risk, process first |
| Application deps | Weekly (Tuesday) | Stagger after actions to avoid PR floods |
| Docker | Weekly (Wednesday) | Base image updates can break builds — review separately |
| Security-only | Daily | Use `open-pull-requests-limit: 0` with security alerts enabled for immediate patches |

### Grouping strategy

Grouping is essential. Without it, a project with 80 dependencies generates 80 PRs per week. Rules:

1. **Group minor + patch by type** (production vs dev). One PR for all non-breaking production updates, one for dev.
2. **Group related tools** (linting, testing, types). These move in lockstep.
3. **Never group major versions.** Review each major bump individually — they have breaking changes.
4. **Never group security patches with regular updates.** Security patches should merge fast; don't delay them behind a large batch.

---

## 3. Renovate (alternative to Dependabot)

Renovate is more configurable than Dependabot. Choose Renovate when you need auto-merge, monorepo support with path-based rules, or fine-grained scheduling.

### When to use Renovate over Dependabot

| Feature | Dependabot | Renovate |
|---------|-----------|----------|
| Auto-merge | Requires separate workflow | Built-in |
| Monorepo support | Basic (per-directory) | Advanced (path filtering, package rules) |
| Grouping | Good (since 2023) | More flexible |
| Private registry auth | Limited | Extensive |
| Lock file maintenance | No | Yes (dedicated PRs) |
| Replacement suggestions | No | Yes (deprecated package alternatives) |
| Platform support | GitHub only | GitHub, GitLab, Bitbucket, Azure DevOps |
| Config complexity | Simple YAML | More complex but more powerful |

**Recommendation:** Use Dependabot for straightforward GitHub projects. Use Renovate for monorepos, projects needing auto-merge, GitLab/Bitbucket, or when you need lock file maintenance PRs.

### Complete renovate.json

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    "helpers:pinGitHubActionDigests",
    ":dependencyDashboard",
    ":semanticCommits",
    ":automergePatch",
    "schedule:earlyMondays"
  ],
  "labels": ["dependencies"],
  "rangeStrategy": "bump",
  "platformAutomerge": true,
  "packageRules": [
    {
      "description": "Auto-merge minor and patch updates for production deps",
      "matchUpdateTypes": ["minor", "patch"],
      "matchDepTypes": ["dependencies"],
      "automerge": true,
      "automergeType": "pr",
      "minimumReleaseAge": "3 days"
    },
    {
      "description": "Auto-merge all dev dependency updates",
      "matchDepTypes": ["devDependencies"],
      "automerge": true,
      "automergeType": "pr",
      "minimumReleaseAge": "1 day"
    },
    {
      "description": "Group linting tools",
      "groupName": "linting",
      "matchPackagePatterns": ["eslint", "prettier", "stylelint"],
      "matchPackagePrefixes": ["@typescript-eslint/"]
    },
    {
      "description": "Group testing tools",
      "groupName": "testing",
      "matchPackagePatterns": ["jest", "vitest"],
      "matchPackagePrefixes": ["@testing-library/"]
    },
    {
      "description": "Group type definitions",
      "groupName": "type-definitions",
      "matchPackagePrefixes": ["@types/"]
    },
    {
      "description": "Group GitHub Actions",
      "groupName": "github-actions",
      "matchManagers": ["github-actions"],
      "automerge": true
    },
    {
      "description": "Do not auto-merge major updates",
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["dependencies", "breaking"]
    },
    {
      "description": "Pin Docker digests for reproducibility",
      "matchDatasources": ["docker"],
      "pinDigests": true
    },
    {
      "description": "Require approval for sensitive packages",
      "matchPackageNames": [
        "node",
        "typescript",
        "react",
        "next",
        "express"
      ],
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true
    }
  ],
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "automerge": true,
    "minimumReleaseAge": "0 days"
  },
  "lockFileMaintenance": {
    "enabled": true,
    "automerge": true,
    "schedule": ["before 5am on the first day of the month"]
  }
}
```

### Key presets

| Preset | What it does |
|--------|-------------|
| `config:recommended` | Sensible defaults: enable major/minor/patch, auto-detect managers |
| `helpers:pinGitHubActionDigests` | Pin Actions to SHA digests for supply chain security |
| `:dependencyDashboard` | Creates a tracking issue listing all pending updates |
| `:semanticCommits` | Uses `chore(deps):` commit prefix |
| `:automergePatch` | Auto-merges patch updates after CI passes |
| `schedule:earlyMondays` | Runs Monday mornings to avoid mid-week noise |

---

## 4. Security scanning workflows

### 4a. CodeQL analysis

CodeQL is GitHub's semantic code analysis engine. It finds vulnerabilities that pattern-matching tools miss: SQL injection, XSS, path traversal, insecure deserialization.

```yaml
# .github/workflows/codeql.yml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    # Run weekly on Monday at 6 AM UTC — catches vulnerabilities
    # introduced by dependency updates between PRs
    - cron: "0 6 * * 1"

permissions:
  security-events: write
  contents: read
  actions: read

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ${{ matrix.language == 'swift' && 'macos-latest' || 'ubuntu-latest' }}
    timeout-minutes: ${{ matrix.language == 'swift' && 120 || 60 }}
    strategy:
      fail-fast: false
      matrix:
        # REPLACE: Keep only the languages your project uses.
        # Supported: javascript-typescript, python, java-kotlin, csharp, cpp, go, ruby, swift
        language:
          - javascript-typescript
          # - python
          # - java-kotlin
          # - go
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          # Use extended queries for more thorough analysis
          queries: +security-extended,security-and-quality

      # For compiled languages (java-kotlin, csharp, cpp, go, swift),
      # CodeQL needs to observe the build. Uncomment and configure:
      # - name: Build
      #   run: |
      #     make build

      # For interpreted languages (javascript-typescript, python, ruby),
      # autobuild works automatically:
      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{ matrix.language }}"
```

### 4b. Dependency review (PR check)

Blocks PRs that introduce dependencies with known vulnerabilities. Zero config, high value.

```yaml
# .github/workflows/dependency-review.yml
name: Dependency review

on:
  pull_request:
    branches: [main]

permissions:
  contents: read
  pull-requests: write

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Dependency review
        uses: actions/dependency-review-action@v4
        with:
          # Fail on vulnerabilities with severity >= low
          fail-on-severity: low
          # Also fail if a dependency uses a disallowed license
          deny-licenses: AGPL-3.0-only, GPL-3.0-only
          # Comment a summary on the PR
          comment-summary-in-pr: always
          # Fail on known malware packages
          fail-on-scopes: runtime
```

### 4c. Trivy container scanning

Trivy scans container images for OS and application vulnerabilities.

```yaml
# .github/workflows/trivy.yml
name: Trivy container scan

on:
  push:
    branches: [main]
    paths:
      - "Dockerfile*"
      - "docker-compose*.yml"
      - ".github/workflows/trivy.yml"
  pull_request:
    branches: [main]
    paths:
      - "Dockerfile*"
      - "docker-compose*.yml"
  schedule:
    - cron: "0 6 * * 1"

permissions:
  security-events: write
  contents: read

jobs:
  scan:
    name: Trivy scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build image
        run: docker build -t ${{ github.repository }}:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{ github.repository }}:${{ github.sha }}"
          format: "sarif"
          output: "trivy-results.sarif"
          severity: "CRITICAL,HIGH"
          # Ignore unfixed vulnerabilities — you can't do anything about them
          ignore-unfixed: true

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: "trivy-results.sarif"

      - name: Run Trivy (table output for PR comment)
        if: github.event_name == 'pull_request'
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{ github.repository }}:${{ github.sha }}"
          format: "table"
          severity: "CRITICAL,HIGH"
          ignore-unfixed: true
          exit-code: "1"

  scan-config:
    name: Trivy config scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Trivy config scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "config"
          scan-ref: "."
          format: "sarif"
          output: "trivy-config.sarif"
          severity: "CRITICAL,HIGH"

      - name: Upload config scan results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: "trivy-config.sarif"
          category: "trivy-config"
```

### 4d. Gitleaks (secret detection)

Gitleaks detects hardcoded secrets (API keys, passwords, tokens) in code and git history.

#### CI workflow

```yaml
# .github/workflows/gitleaks.yml
name: Gitleaks

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Pre-commit hook

Install gitleaks locally and add a pre-commit hook to catch secrets before they reach the remote.

```bash
# Install gitleaks
# macOS
brew install gitleaks

# Linux
curl -sSfL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_linux_x64 -o /usr/local/bin/gitleaks
chmod +x /usr/local/bin/gitleaks
```

**Option A: Direct git hook** (`.git/hooks/pre-commit` or `.husky/pre-commit`):

```bash
#!/usr/bin/env bash
# Pre-commit hook: scan staged changes for secrets
gitleaks git --pre-commit --staged --verbose
if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: Gitleaks detected secrets in staged changes."
  echo "If this is a false positive, add the finding to .gitleaksignore"
  echo "To bypass (NOT recommended): git commit --no-verify"
  exit 1
fi
```

**Option B: pre-commit framework** (`.pre-commit-config.yaml`):

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2  # REPLACE: Use latest version
    hooks:
      - id: gitleaks
```

#### Custom rules (`.gitleaks.toml`)

```toml
# .gitleaks.toml
title = "Gitleaks config"

[allowlist]
description = "Global allowlist"
paths = [
  '''\.gitleaksignore''',
  '''(.*?)(jpg|gif|doc|pdf|bin|svg|png)$''',
  '''go\.sum''',
  '''package-lock\.json''',
  '''yarn\.lock''',
  '''pnpm-lock\.yaml''',
]

# Add false positive hashes to .gitleaksignore (one per line)
```

---

## 5. Branch protection and rulesets

### Branch protection (legacy — still widely used)

Apply to `main` (or `master`) via Settings > Branches > Branch protection rules.

#### Recommended settings for main branch

| Setting | Value | Why |
|---------|-------|-----|
| Require pull request before merging | Yes | No direct pushes to main |
| Required approving reviews | 1 (small team), 2 (larger team) | Code review gate |
| Dismiss stale reviews | Yes | Re-review after force push |
| Require review from code owners | Yes (if CODEOWNERS exists) | Domain experts review their areas |
| Require status checks to pass | Yes | CI must be green |
| Require branches to be up to date | Yes | Merge conflicts caught before merge |
| Required status checks | `build`, `test`, `lint` (match your CI job names) | Specific checks, not just "any" |
| Require signed commits | Recommended | Verify commit author identity |
| Require linear history | Recommended | Clean git log, no merge commits |
| Include administrators | Yes | Rules apply to everyone |
| Restrict pushes | Maintainers only | Prevents accidental force push |
| Allow force pushes | Never | Protect history |
| Allow deletions | Never | Protect the branch |

### Rulesets (modern GitHub — recommended for new repos)

Rulesets replace branch protection rules with more flexibility: they can target multiple branches, tags, apply to specific teams, and support bypass lists. Available on all GitHub plans since 2024.

#### Setting up via repository settings

Settings > Rules > Rulesets > New ruleset

#### Recommended ruleset for main

```
Name: Protect main
Enforcement: Active
Target: Default branch

Bypass list:
  - Organization admins (for emergency hotfixes only)

Rules:
  ✅ Restrict deletions
  ✅ Require linear history
  ✅ Require a pull request before merging
       - Required approvals: 1
       - Dismiss stale reviews on push: Yes
       - Require review from code owners: Yes
       - Require approval of most recent push: Yes
  ✅ Require status checks to pass
       - Require branches to be up to date: Yes
       - Status checks: ci / build, ci / test, ci / lint
  ✅ Require signed commits
  ✅ Block force pushes
  ✅ Require code scanning results (if CodeQL enabled)
       - Tool: CodeQL
       - Alerts threshold: None (block on any alert)
       - Security alerts threshold: None
```

#### Rulesets vs branch protection: when to use which

| Aspect | Branch protection | Rulesets |
|--------|------------------|---------|
| Scope | One branch pattern per rule | Multiple branch/tag patterns per ruleset |
| Bypass | Admins exempt by default | Explicit bypass list with audit trail |
| Stacking | Rules don't compose | Multiple rulesets can layer |
| Organization level | No | Yes — apply across all repos |
| API management | Mature | Newer API, well-documented |
| Tag protection | Separate feature | Included in rulesets |
| **Recommendation** | Use if you need simplicity or are on an older plan | Use for new projects — more flexible and auditable |

---

## 6. Signed commits

Signing commits proves the commit was made by the person who claims to have made it. Without signing, anyone can set `git config user.email` to your email and forge commits.

### SSH signing (recommended — simpler setup)

SSH signing was added in Git 2.34. It reuses your existing SSH key. No GPG keychain, no key servers, no expiration hassles.

#### Setup

```bash
# 1. Use your existing SSH key or generate a new one
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Configure Git to use SSH for signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub

# 3. Sign all commits by default
git config --global commit.gpgsign true

# 4. Sign all tags by default
git config --global tag.gpgsign true

# 5. Add the SSH key to GitHub as a SIGNING key
#    (This is separate from authentication keys)
#    GitHub > Settings > SSH and GPG keys > New SSH key
#    Key type: Signing Key
#    Paste contents of ~/.ssh/id_ed25519.pub
```

#### Verify locally (optional)

```bash
# Create an allowed signers file for local verification
echo "$(git config user.email) $(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

# Now `git log --show-signature` works locally
git log --show-signature -1
```

### GPG signing (traditional — required by some organizations)

```bash
# 1. Generate a GPG key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits, reasonable expiration (1-2 years)

# 2. List your keys and get the key ID
gpg --list-secret-keys --keyid-format=long
# Output: sec   rsa4096/ABCDEF1234567890 2024-01-01 [SC]
# The key ID is the part after rsa4096/

# 3. Configure Git
git config --global user.signingkey ABCDEF1234567890
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# 4. Export and add to GitHub
gpg --armor --export ABCDEF1234567890
# Copy output to GitHub > Settings > SSH and GPG keys > New GPG key

# 5. macOS: configure pinentry for passphrase
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

### Vigilant mode

Enable vigilant mode on GitHub (Settings > SSH and GPG keys > Vigilant mode) to mark unsigned commits as "Unverified." Without vigilant mode, unsigned commits show no badge at all, making it unclear whether signing is enforced.

With vigilant mode:
- Signed commits by you: **Verified** (green)
- Unsigned commits by you: **Unverified** (yellow warning)
- Signed commits by others: **Verified** (green)
- Unsigned commits by others: No badge

**Recommendation:** Enable vigilant mode for all maintainers. Require signed commits in branch protection. Use SSH signing unless your organization mandates GPG.

---

## 7. Supply chain security

### SLSA framework

SLSA (Supply-chain Levels for Software Artifacts) is a security framework for preventing tampering and ensuring integrity throughout the software supply chain. Four levels:

| Level | Requirements | What it prevents |
|-------|-------------|-----------------|
| SLSA 1 | Build process is documented | Unknown build process |
| SLSA 2 | Hosted build, authenticated provenance | Tampered builds |
| SLSA 3 | Hardened build platform, non-falsifiable provenance | Compromised build platform |
| SLSA 4 | Hermetic, reproducible builds, two-person review | All known supply chain attacks |

#### SLSA 3 with GitHub Actions (using slsa-github-generator)

```yaml
# .github/workflows/slsa-provenance.yml
name: SLSA Provenance

on:
  push:
    tags:
      - "v*"

permissions: read-all

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.hash.outputs.digest }}
      artifact-name: ${{ steps.build.outputs.artifact-name }}
    steps:
      - uses: actions/checkout@v4

      # REPLACE: Your actual build step
      - name: Build
        id: build
        run: |
          # Build your artifact
          make build
          echo "artifact-name=my-binary" >> "$GITHUB_OUTPUT"

      - name: Generate hash
        id: hash
        run: |
          sha256sum my-binary > checksums.txt
          echo "digest=$(sha256sum my-binary | cut -d ' ' -f1)" >> "$GITHUB_OUTPUT"

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: my-binary
          path: my-binary

  provenance:
    needs: build
    permissions:
      actions: read
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.0.0
    with:
      base64-subjects: ${{ needs.build.outputs.digest }}
      upload-assets: true
```

### Sigstore / cosign (artifact signing)

Sigstore provides keyless signing using OIDC identity. No key management required — your GitHub Actions identity is your signing identity.

```yaml
# Sign a container image in CI
jobs:
  sign:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      packages: write
    steps:
      - name: Install cosign
        uses: sigstore/cosign-installer@v3

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Sign image
        run: |
          cosign sign --yes ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}

      # Verify (consumers run this)
      # cosign verify \
      #   --certificate-identity-regexp="https://github.com/YOUR_ORG/YOUR_REPO" \
      #   --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
      #   ghcr.io/YOUR_ORG/YOUR_REPO@sha256:abc123
```

### npm provenance

npm provenance links a published package to its source commit and build. Available since npm 9.5.0.

```yaml
# In your publish workflow:
- name: Publish with provenance
  run: npm publish --provenance --access public
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Requirements:
- Package must be built and published in GitHub Actions
- Workflow must have `id-token: write` permission
- npm 9.5.0+ or Node.js 20+

Consumers verify provenance on npmjs.com — a "Provenance" badge appears on the package page.

### PyPI attestations and trusted publishing

#### OIDC Trusted Publishing (no API tokens needed)

Configure on PyPI: Your projects > Manage > Publishing > Add a new pending publisher.

```yaml
# .github/workflows/publish-pypi.yml
name: Publish to PyPI

on:
  release:
    types: [published]

permissions:
  id-token: write
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    environment: pypi
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.x"

      - name: Install build tools
        run: pip install build

      - name: Build
        run: python -m build

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
        # No token needed — OIDC handles authentication
```

#### PyPI attestations (since 2024)

```yaml
      - name: Publish with attestations
        uses: pypa/gh-action-pypi-publish@release/v1
        with:
          attestations: true
```

### OIDC Trusted Publishing summary

| Registry | Setup location | Token needed? | Provenance support |
|----------|---------------|---------------|-------------------|
| npm | npmjs.com > Access Tokens > Granular | Optional (OIDC preferred) | Yes (`--provenance`) |
| PyPI | pypi.org > Manage > Publishing | No (OIDC only) | Yes (attestations) |
| GitHub Packages | Automatic via GITHUB_TOKEN | No | Inherent (built in GitHub) |

**Recommendation:** Always use OIDC trusted publishing for npm and PyPI. It eliminates long-lived tokens and provides cryptographic proof of build provenance.

---

## 8. SBOM generation

An SBOM (Software Bill of Materials) is a machine-readable inventory of all components in your software. Think of it as a nutrition label for code.

### CycloneDX vs SPDX

| Aspect | CycloneDX | SPDX |
|--------|-----------|------|
| Origin | OWASP | Linux Foundation |
| Focus | Security and vulnerability management | License compliance and legal |
| Formats | JSON, XML | JSON, RDF, tag-value, XLSX |
| VEX support | Built-in (CycloneDX VEX) | Separate document |
| Adoption | Growing (preferred for security use cases) | Widely adopted (government, legal) |
| Tooling | syft, cdxgen, trivy | syft, trivy, spdx-sbom-generator |
| **Recommendation** | Use for security-focused projects | Use when required by contract or regulation |

### CI workflow for automatic SBOM generation

```yaml
# .github/workflows/sbom.yml
name: Generate SBOM

on:
  push:
    branches: [main]
  release:
    types: [published]

permissions:
  contents: write

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Syft
        uses: anchore/sbom-action/download-syft@v0

      - name: Generate CycloneDX SBOM
        run: |
          syft dir:. -o cyclonedx-json=sbom.cdx.json
          syft dir:. -o spdx-json=sbom.spdx.json

      - name: Upload SBOM as artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: |
            sbom.cdx.json
            sbom.spdx.json

      # Attach SBOM to GitHub release
      - name: Attach to release
        if: github.event_name == 'release'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release upload ${{ github.event.release.tag_name }} \
            sbom.cdx.json \
            sbom.spdx.json

  # For container images, generate a separate SBOM
  container-sbom:
    runs-on: ubuntu-latest
    if: hashFiles('Dockerfile') != ''
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build image
        run: docker build -t ${{ github.repository }}:${{ github.sha }} .

      - name: Generate container SBOM with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{ github.repository }}:${{ github.sha }}"
          format: "cyclonedx"
          output: "container-sbom.cdx.json"

      - name: Upload container SBOM
        uses: actions/upload-artifact@v4
        with:
          name: container-sbom
          path: container-sbom.cdx.json
```

### When SBOMs are required

| Scenario | Requirement | Format |
|----------|------------|--------|
| US Federal government contracts | Executive Order 14028 (May 2021) | SPDX or CycloneDX |
| EU Cyber Resilience Act | Required for products sold in EU (phased 2025-2027) | CycloneDX or SPDX |
| Healthcare (FDA) | Required for medical device software | SPDX preferred |
| Financial services | Increasingly required by regulators | Either format |
| Enterprise customers | Often required in vendor security questionnaires | Either format |
| Open source best practice | Recommended but not mandated | Either format |

**Recommendation:** Generate SBOMs for any project that ships to customers, handles sensitive data, or targets regulated industries. Attach SBOMs to every release. Use CycloneDX for security focus, SPDX for compliance focus. When in doubt, generate both (syft does it in one command).

---

## 9. Secret management

### .env practices

```
# What gets committed:
.env.example      ← Template with placeholder values, committed to repo
.env.test         ← Test environment config (no real secrets), committed

# What NEVER gets committed:
.env              ← Local development secrets, NEVER committed
.env.local        ← Local overrides, NEVER committed
.env.production   ← Production secrets, NEVER committed
.env.*.local      ← Any local override, NEVER committed
```

#### .gitignore entries (non-negotiable)

```gitignore
# Environment files with secrets
.env
.env.local
.env.*.local
.env.production
.env.staging

# Keep templates
!.env.example
!.env.test
```

#### .env.example template

```bash
# .env.example
# Copy this file to .env and fill in real values
# NEVER commit .env to version control

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/myapp_dev

# Authentication
# Generate a secret: openssl rand -base64 32
JWT_SECRET=replace-with-generated-secret
SESSION_SECRET=replace-with-generated-secret

# External APIs
# Get your key at: https://example.com/api-keys
API_KEY=your-api-key-here

# Optional / Feature flags
DEBUG=false
LOG_LEVEL=info
```

### GitHub Actions secrets

#### Repository secrets vs environment secrets

| Type | Scope | Use case |
|------|-------|---------|
| Repository secrets | All workflows in the repo | Shared tokens (NPM_TOKEN, CODECOV_TOKEN) |
| Environment secrets | Workflows targeting a specific environment | Per-stage values (production DB URL, API keys) |
| Organization secrets | All repos (or selected repos) in the org | Shared across projects (registry credentials) |

#### Setting up environment-based secrets

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging          # Uses staging secrets
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production            # Uses production secrets
      url: https://myapp.com
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
```

#### Environment protection rules

Configure in Settings > Environments:

| Setting | Staging | Production |
|---------|---------|-----------|
| Required reviewers | None | 1-2 team leads |
| Wait timer | None | 5 minutes (cancel window) |
| Deployment branches | `main`, `staging/*` | `main` only |
| Custom rules | None | Require passing security scan |

### Secret rotation procedures

#### Rotation schedule

| Secret type | Rotation frequency | Automated? |
|-------------|-------------------|-----------|
| API keys (external services) | 90 days | Manual — set calendar reminders |
| Database passwords | 90 days | Automate via cloud provider |
| JWT / session secrets | 180 days | Manual — requires coordinated deploy |
| SSH deploy keys | Annually | Manual |
| Personal access tokens | 90 days (use fine-grained tokens with expiry) | GitHub enforces expiration |
| Service account credentials | 90 days | Automate via cloud IAM |

#### Rotation checklist

```markdown
## Secret rotation runbook

### Before rotation
- [ ] Identify all locations where the secret is used (CI, deployments, services)
- [ ] Ensure the system supports dual-key operation (old + new simultaneously)
- [ ] Schedule rotation during low-traffic window

### During rotation
1. Generate new secret/key
2. Add new secret to GitHub (Actions secrets, environments)
3. Deploy with new secret (verify it works)
4. Revoke old secret at the provider
5. Verify no workflows or services are broken

### After rotation
- [ ] Update rotation date in team documentation
- [ ] Set reminder for next rotation
- [ ] Verify old secret is fully invalidated (try using it — should fail)
```

#### Preventing secrets in code

Layer these defenses:

1. **Pre-commit hook** — Gitleaks catches secrets before they leave the developer's machine (see section 4d).
2. **CI scan** — Gitleaks in CI catches anything the pre-commit hook missed.
3. **GitHub secret scanning** — Automatic scanning of push events. Enable in Settings > Code security and analysis > Secret scanning.
4. **GitHub push protection** — Blocks pushes containing detected secrets. Enable in Settings > Code security and analysis > Push protection.

Enable both secret scanning and push protection. They are free for public repos and included in GitHub Advanced Security for private repos.

---

## Decision matrix: what to enable by project stage

| Security feature | MVP | Growth | Enterprise |
|-----------------|-----|--------|-----------|
| SECURITY.md | Skip (unless handles user data) | Yes | Yes + PGP + bug bounty |
| Dependabot / Renovate | Dependabot (basic) | Dependabot with grouping | Renovate with auto-merge |
| CodeQL | Skip | Yes (primary language) | Yes (all languages) |
| Dependency review | Skip | Yes | Yes |
| Trivy | Skip | Only if using containers | Yes |
| Gitleaks | Pre-commit hook | Pre-commit + CI | Pre-commit + CI + push protection |
| Branch protection | Basic (require PR) | Full settings | Rulesets + CODEOWNERS |
| Signed commits | Optional | Recommended | Required |
| SLSA provenance | Skip | Skip | Yes (level 2-3) |
| SBOM | Skip | Optional | Required |
| Secret scanning | Enable (free) | Enable + push protection | Enable + push protection + alerts |
| Environment secrets | Basic | Staging + production | Full environment matrix |

This is not a checklist to blindly follow. A side project API that handles auth tokens needs SECURITY.md and secret scanning even at MVP stage. A static documentation site at enterprise stage does not need Trivy. Match security measures to actual risk, not project size alone.

## Enforcement contact sourcing for solo developers and small teams

Most open source projects are solo-run and don't have `security@example.com`. The SECURITY.md template asks for a reporting address, and the solo maintainer is stuck: a personal email is noisy, a role mailbox doesn't exist, and faking one with an `example.com` address disqualifies the whole file. This section gives four real options in recommendation order, plus anti-patterns to avoid.

### Option 1: GitHub Private Vulnerability Reporting (PVR)

**Recommended for any public GitHub repository.** Zero setup, zero cost, no email infrastructure required. The reporter gets a structured form, the disclosure thread stays private until you publish an advisory, and GitHub handles CVE request coordination.

**Enable it:** Settings → Code security and analysis → Private vulnerability reporting → Enable. Takes about 10 seconds.

**Wire it into SECURITY.md:**

```markdown
## Reporting a vulnerability

Report vulnerabilities privately via GitHub's Private Vulnerability Reporting:
**Security tab → Report a vulnerability** (or https://github.com/OWNER/REPO/security/advisories/new).

We aim to acknowledge within 72 hours and publish a fix coordinated with an advisory.
```

Docs: <https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability>

PVR is the default answer for solo maintainers on GitHub. If you only read one option, use this one.

### Option 2: Tidelift enterprise subscription

For projects with funding and an enterprise tier. Tidelift pays the maintainer a subscription fee and provides a coordinated disclosure channel for subscribers. Reporters who are Tidelift customers file through them; you respond through their tooling.

**When it fits:** funded libraries with known enterprise consumers. Not appropriate for unfunded hobby projects — there is no free tier.

### Option 3: security.txt at the repo root

Per [RFC 9116](https://www.rfc-editor.org/rfc/rfc9116). A well-known file that tells automated scanners and researchers where to report. security.txt is a *redirector*, not a channel — the `Contact:` field points to whichever of the other three options you use.

**Place it at `/.well-known/security.txt` in web projects, or `/security.txt` in repo-only projects:**

```
Contact: https://github.com/OWNER/REPO/security/advisories/new
Contact: mailto:project-security+handle@example.com
Expires: 2027-01-01T00:00:00Z
Preferred-Languages: en
Canonical: https://example.com/.well-known/security.txt
```

`Expires:` is mandatory per the RFC — set it 12 months out and add a calendar reminder to renew. Expired security.txt is worse than none.

### Option 4: Personal email with a dedicated alias

Use plus-addressing (Gmail, Fastmail, Proton) or a dedicated alias domain to filter security reports from personal mail.

**Pattern:** `project-name-security+yourhandle@gmail.com` or `security@yourhandle.dev` (if you own a domain).

**Tradeoffs:** works but trains reporters to expect individual attention. Scales only as far as the maintainer's availability, and creates a single point of failure if the maintainer takes a break. Acceptable for small projects with low report volume; not a long-term answer for libraries with significant user bases.

**If you choose this:** create the alias *before* shipping SECURITY.md, route it to a folder with a notification rule, and document an expected response window (72 hours is a reasonable solo-maintainer SLA).

### Anti-patterns

Don't do any of these:

- **`security@example.com` or any `example.com` address** — fails the no-placeholder rule, signals an unmaintained project, and breaks automated scanners that validate `Contact:` URLs.
- **Your main personal email address as the primary contact** — security reports get buried among newsletters and personal correspondence. Missed reports become public zero-days.
- **A Discord or Slack server "for security reports"** — channel access complexity discourages good-faith reporters; real-time chat is a poor fit for written disclosures that need a paper trail; and there is no private DM-only model that scales.
- **"Open an issue"** — public issues turn security reports into public zero-days the moment they're filed. Never route disclosure through a public tracker.

### Summary for solo developers on public GitHub

Enable PVR. Add a `security.txt` with `Contact:` pointing to the PVR URL. Document the PVR flow in SECURITY.md with a 72-hour acknowledgement commitment. That covers 90% of cases with zero ongoing infrastructure cost, and it scales automatically if the project grows onto a team.

---

## README, PR comments, and issues as attack surface

In 2026, researchers documented **"Comment-and-Control" (CVSS 9.4)** — a prompt-injection class affecting Claude Code, Gemini CLI, and GitHub Copilot that exfiltrates repo secrets through poisoned PR comments or issue text (<https://venturebeat.com/security/ai-agent-runtime-security-system-card-audit-comment-and-control-2026>, <https://oddguan.com/blog/comment-and-control-prompt-injection-credential-theft-claude-code-gemini-cli-github-copilot/>). An attacker posts crafted text into a thread; when an AI agent reads it as context, the payload hijacks the agent into shipping a repo secret over the network. The **Antigravity `.env` exfiltration** generalized the same technique (<https://www.gnanaguru.com/blog/agent-security-patterns/>).

Any attacker-writable surface an agent reads as trusted context is an injection vector: a dependency's `README.md`, issue bodies, PR comments, merged commit messages, wiki pages. "Detect all injection" is unsolved; the practical defense is **isolation and least privilege**.

### Mitigation patterns

- **Don't let untrusted text reach an agent with shell access.** Review external-contributor PR comments and issue bodies before feeding to an autonomous agent, or route them through human-in-the-loop approval.

- **Run agents in sandboxed environments for external contributions.** Containers with read-only mounts, no egress to arbitrary hosts, ephemeral credentials. A compromised agent in a sandbox leaks only what the sandbox can see.

- **Treat `curl <url> | bash` install patterns as a red flag.** The skill's generator already forbids these; a README containing `curl | bash` puts an ingesting agent one step from arbitrary code execution. The `.claude/settings.json` denylist (SAFE-01, see `references/agent-safety.md` §2) is the first defense.

- **Pin GitHub Actions by commit SHA, not tag.** `uses: org/action@<40-char-sha>` can't be silently swapped the way `@main` or `@v1` can. Pair with Dependabot version-updates for actions (§2 of this file).

- **Secret scanning + branch protection defense-in-depth.** Even if injected code runs, exfiltrated content must pass a scanner before landing on the remote. Cross-refs: "Secret scanning (pre-commit)" in `references/quality-tooling.md` (SAFE-04); §4d Gitleaks CI workflow in this file; §5 Branch protection and rulesets.

### Anti-patterns

- **`curl SOMEURL | bash` in README install instructions.** Attacker controls SOMEURL; both humans and agents run arbitrary code.
- **Unpinned Actions (`@main`, `@latest`, `@v1`).** Upstream compromise silently propagates on next run.
- **Auto-merging Dependabot PRs on `.github/workflows/**` without review.** Workflow files run with elevated permissions — least eligible for auto-merge. Exclude workflow paths from auto-merge (nuances `references/git-workflows.md` §6).
- **Running Claude Code / Cursor / Copilot on a repo accepting external PRs without a sandbox or review gate.** Wrong default trust boundary.

A locked-down agent is the first defense — `references/agent-safety.md` §2 documents the `.claude/settings.json` denylist (SAFE-01). For deeper agent-credential patterns (scoped tokens, ephemeral credentials, secrets-manager brokered access), see <https://www.bitwarden.com/blog/secure-ai-agent-access-with-secrets-manager/>.
