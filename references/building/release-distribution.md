# Release Automation & Package Distribution

Reference for versioning, changelog management, release automation, and publishing packages across ecosystems.

---

## 1. Semantic Versioning

### SemVer Rules (semver.org)

Format: `MAJOR.MINOR.PATCH`

| Component | Bump when | Example |
|-----------|-----------|---------|
| MAJOR | Breaking change to public API | Rename exported function, remove feature, change return type |
| MINOR | New feature, backward-compatible | Add new CLI flag, new optional parameter, new export |
| PATCH | Bug fix, backward-compatible | Fix off-by-one, correct typo in output, security patch |

Rules:
- `0.x.y` signals instability. Anything can change. `0.1.0` to `0.2.0` may break.
- `1.0.0` declares the public API stable.
- Once released, the contents of that version MUST NOT be modified. Any change requires a new version.
- Patch version resets to 0 when minor increments. Minor resets to 0 when major increments.

### Pre-release Conventions

Append a hyphen and identifiers: `MAJOR.MINOR.PATCH-prerelease`

| Stage | Format | Meaning |
|-------|--------|---------|
| Alpha | `2.0.0-alpha.1` | Unstable, features incomplete, API will change |
| Beta | `2.0.0-beta.1` | Feature-complete, bugs expected, API may change |
| RC | `2.0.0-rc.1` | Release candidate, production-ready unless bugs found |

Precedence: `1.0.0-alpha.1 < 1.0.0-alpha.2 < 1.0.0-beta.1 < 1.0.0-rc.1 < 1.0.0`

### CalVer as Alternative

Format: `YYYY.MM.DD` or `YYYY.MM.MICRO`

Use CalVer when:
- The project is time-driven, not feature-driven (Ubuntu: `24.04`)
- There is no meaningful API to version (infrastructure tools, data pipelines)
- Users care more about recency than compatibility

Stick with SemVer for libraries, frameworks, and anything with a public API.

---

## 2. Changelog Management

### Keep a Changelog Format

File: `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New `--dry-run` flag for preview mode

### Changed
- Updated minimum Node.js version to 20

## [1.2.0] - 2026-04-10

### Added
- Interactive project type selection
- SECURITY.md template generation

### Fixed
- License file encoding on Windows

### Deprecated
- `--no-interactive` flag (use `--yes` instead)

## [1.1.0] - 2026-03-15

### Added
- CONTRIBUTING.md template with PR checklist

### Security
- Updated dependencies to resolve CVE-2026-12345

## [1.0.0] - 2026-02-01

### Added
- Initial release with README, LICENSE, and .gitignore generation

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

Section types (use only these, in this order):
- **Added** -- new features
- **Changed** -- changes to existing functionality
- **Deprecated** -- features to be removed
- **Removed** -- removed features
- **Fixed** -- bug fixes
- **Security** -- vulnerability fixes

### Auto-generation from Conventional Commits

Conventional Commits map to changelog sections:

| Commit prefix | Changelog section |
|---------------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `perf:` | Changed |
| `refactor:` | Changed |
| `docs:` | (usually excluded) |
| `chore:` | (usually excluded) |
| `BREAKING CHANGE:` | breaking changes callout |

Tools that generate changelogs from commits:
- `conventional-changelog-cli` -- standalone generation
- `semantic-release` -- generates as part of release
- `release-please` -- generates as part of release PR
- `changesets` -- uses manual changeset files, not commit messages

### GitHub Auto-generated Release Notes

File: `.github/release.yml`

```yaml
changelog:
  exclude:
    labels:
      - ignore-for-release
    authors:
      - dependabot
      - renovate
  categories:
    - title: Breaking Changes
      labels:
        - breaking-change
        - semver-major
    - title: New Features
      labels:
        - enhancement
        - feature
    - title: Bug Fixes
      labels:
        - bug
        - fix
    - title: Documentation
      labels:
        - documentation
    - title: Dependency Updates
      labels:
        - dependencies
    - title: Other Changes
      labels:
        - "*"
```

This configures the "Generate release notes" button on the GitHub Releases page. It groups PRs by label into sections.

---

## 3. Release Automation Tools

### semantic-release

Fully automated. Analyzes commits since last release, determines version bump, generates changelog, publishes package, creates GitHub release. Zero human decisions after merge.

#### .releaserc (JSON config)

```json
{
  "branches": [
    "main",
    { "name": "next", "prerelease": true },
    { "name": "beta", "prerelease": true },
    { "name": "alpha", "prerelease": true }
  ],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/npm",
      {
        "npmPublish": true
      }
    ],
    [
      "@semantic-release/github",
      {
        "assets": [
          { "path": "dist/*.tgz", "label": "Distribution" }
        ]
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json", "package-lock.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

#### GitHub Actions Workflow

```yaml
name: Release
on:
  push:
    branches: [main, next, beta, alpha]

permissions:
  contents: write
  issues: write
  pull-requests: write
  id-token: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - run: npm ci

      - run: npm test

      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Install dependencies:

```bash
npm install -D semantic-release @semantic-release/changelog @semantic-release/git @semantic-release/github
```

### release-please

Creates a "Release PR" that stays open and updates as you merge. Merging the Release PR triggers the actual release. Gives humans a review step before release.

#### release-please-config.json

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "node",
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "release-type": "node",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true,
      "draft": false,
      "prerelease": false
    }
  },
  "changelog-sections": [
    { "type": "feat", "section": "Features" },
    { "type": "fix", "section": "Bug Fixes" },
    { "type": "perf", "section": "Performance Improvements" },
    { "type": "revert", "section": "Reverts" },
    { "type": "docs", "section": "Documentation" },
    { "type": "chore", "section": "Miscellaneous" },
    { "type": "refactor", "section": "Code Refactoring" },
    { "type": "test", "section": "Tests", "hidden": true },
    { "type": "build", "section": "Build System", "hidden": true },
    { "type": "ci", "section": "CI", "hidden": true }
  ]
}
```

#### .release-please-manifest.json

```json
{
  ".": "1.0.0"
}
```

This tracks the current version. Release-please updates it automatically.

#### GitHub Actions Workflow

```yaml
name: Release Please
on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  publish:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npm test
      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### changesets

Human-authored changeset files describe each change. Best for monorepos. Contributors add a changeset file with each PR describing the change and bump type.

#### .changeset/config.json

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "public",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": [],
  "___experimentalUnsafeOptions_WILL_CHANGE_IN_PATCH": {
    "onlyUpdatePeerDependentsWhenOutOfRange": false
  }
}
```

#### Creating a Changeset

```bash
npx changeset
```

This creates a file like `.changeset/cool-tigers-dance.md`:

```markdown
---
"@myorg/package-a": minor
"@myorg/package-b": patch
---

Added new template engine with Handlebars support
```

#### GitHub Actions Workflow

```yaml
name: Release
on:
  push:
    branches: [main]

concurrency: ${{ github.workflow }}-${{ github.ref }}

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - run: npm ci

      - name: Create Release PR or Publish
        uses: changesets/action@v1
        with:
          publish: npm run release
          version: npm run version
          title: "chore: version packages"
          commit: "chore: version packages"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "version": "changeset version",
    "release": "changeset publish"
  }
}
```

#### Monorepo Support

Changesets handles monorepos natively. Each changeset file can reference multiple packages with independent bump types. The `linked` config option keeps specified packages on the same version. The `fixed` option forces packages to always share a version.

```json
{
  "fixed": [["@myorg/core", "@myorg/cli"]],
  "linked": [["@myorg/plugin-a", "@myorg/plugin-b"]]
}
```

### Decision Matrix

| Scenario | Tool | Why |
|----------|------|-----|
| Single package, fully automated | semantic-release | Zero-touch releases from commit messages |
| Single package, human review step | release-please | Release PR gives review before publish |
| Monorepo, multiple packages | changesets | Per-package versioning, linked/fixed groups |
| Monorepo (Google-style) | release-please | Supports multi-package configs natively |
| Team unfamiliar with Conventional Commits | changesets | Changeset files are easier than commit discipline |
| Strict commit message enforcement | semantic-release | Commit analyzer rewards discipline |
| Pre-release channels needed | semantic-release | Best multi-branch pre-release support |
| Open source with external contributors | changesets | Contributors add changesets in PRs, no commit format required |

---

## 4. Package Publishing

### npm

#### package.json Metadata

```json
{
  "name": "@myorg/my-package",
  "version": "1.0.0",
  "description": "A concise description of the package",
  "keywords": ["cli", "documentation", "template"],
  "homepage": "https://github.com/myorg/my-package",
  "bugs": {
    "url": "https://github.com/myorg/my-package/issues"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/myorg/my-package.git"
  },
  "license": "MIT",
  "author": "Your Name <you@example.com>",
  "type": "module",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  },
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "bin": {
    "my-cli": "./dist/cli.js"
  },
  "files": [
    "dist",
    "templates",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ],
  "scripts": {
    "build": "tsup",
    "prepublishOnly": "npm run build && npm test"
  },
  "engines": {
    "node": ">=20"
  },
  "publishConfig": {
    "access": "public",
    "registry": "https://registry.npmjs.org"
  }
}
```

**`files` field vs `.npmignore`:** Use the `files` field. It is an allowlist of what to include. `.npmignore` is a denylist and is error-prone. The `files` field is explicit and preferred.

**`prepublishOnly`:** Runs before `npm publish` and before `npm pack`. Use it to build and test. It does NOT run on `npm install`.

#### npm OIDC Trusted Publishing Workflow

No long-lived `NPM_TOKEN` needed. Uses GitHub's OIDC token to authenticate with npm.

Configure on npmjs.com: Package Settings > Publishing access > Add trusted publisher > GitHub Actions.

```yaml
name: Publish to npm
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npm test
      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

The `--provenance` flag generates a signed SLSA provenance statement linking the package to its source commit and build.

### PyPI

#### pyproject.toml Metadata

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-package"
version = "1.0.0"
description = "A concise description"
readme = "README.md"
license = "MIT"
requires-python = ">=3.10"
authors = [
    { name = "Your Name", email = "you@example.com" },
]
keywords = ["cli", "documentation"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]
dependencies = [
    "click>=8.0",
    "rich>=13.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.4",
]

[project.urls]
Homepage = "https://github.com/myorg/my-package"
Repository = "https://github.com/myorg/my-package"
Issues = "https://github.com/myorg/my-package/issues"
Changelog = "https://github.com/myorg/my-package/blob/main/CHANGELOG.md"

[project.scripts]
my-cli = "my_package.cli:main"
```

#### Trusted Publishing via OIDC Workflow

Configure on pypi.org: Your Projects > Manage > Publishing > Add a new publisher > GitHub Actions.

```yaml
name: Publish to PyPI
on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - run: pip install build
      - run: python -m build

      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  publish:
    needs: build
    runs-on: ubuntu-latest
    environment: pypi
    permissions:
      id-token: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/

      - uses: pypa/gh-action-pypi-publish@release/v1
```

No tokens or passwords needed. The `id-token: write` permission and the `environment: pypi` configuration enable OIDC authentication. This is the recommended approach as of 2024+.

### crates.io

#### Cargo.toml Metadata

```toml
[package]
name = "my-package"
version = "1.0.0"
edition = "2021"
rust-version = "1.75"
description = "A concise description"
documentation = "https://docs.rs/my-package"
homepage = "https://github.com/myorg/my-package"
repository = "https://github.com/myorg/my-package"
readme = "README.md"
license = "MIT"
keywords = ["cli", "documentation"]
categories = ["command-line-utilities"]
exclude = ["tests/", ".github/", "benches/"]

[dependencies]
clap = { version = "4", features = ["derive"] }
```

#### cargo publish Workflow

```yaml
name: Publish to crates.io
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable

      - run: cargo test

      - run: cargo publish
        env:
          CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

Generate a token at crates.io > Account Settings > API Tokens. Add it as a repository secret.

### Docker

#### Multi-stage Dockerfile

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build
RUN npm prune --production

# Production stage
FROM node:20-alpine AS production
RUN apk add --no-cache tini
WORKDIR /app

# Don't run as root
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup
USER appuser

COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

EXPOSE 3000
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/index.js"]
```

#### .dockerignore

```
node_modules
.git
.github
.gitignore
*.md
!README.md
Dockerfile
docker-compose*.yml
.env*
.vscode
.idea
coverage
.nyc_output
test
tests
__tests__
*.test.*
*.spec.*
.changeset
.planning
```

#### GHCR Push Workflow

```yaml
name: Build and Push Docker Image
on:
  release:
    types: [published]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha

      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

#### Docker Hub Push

Replace the login and registry:

```yaml
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: myorg/my-package
```

### Go Modules

#### go.mod

```
module github.com/myorg/my-package

go 1.22

require (
    github.com/spf13/cobra v1.8.0
)
```

#### Releasing

Go modules use git tags. No registry upload needed -- the Go module proxy fetches from the git repo.

```bash
git tag v1.2.0
git push origin v1.2.0
```

The Go module proxy (`proxy.golang.org`) automatically caches the module when anyone requests it.

**GOPROXY:** Controls where `go get` fetches modules. Default: `https://proxy.golang.org,direct`. The proxy caches modules for availability and performance.

**Major version paths:** Go requires major versions v2+ to have the major version in the module path:

```
module github.com/myorg/my-package/v2
```

Import paths change accordingly: `import "github.com/myorg/my-package/v2/pkg"`

#### Go Release Workflow

```yaml
name: Release Go Binary
on:
  release:
    types: [published]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"

      - uses: goreleaser/goreleaser-action@v6
        with:
          version: "~> v2"
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Maven Central

#### pom.xml (minimal for publishing)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.myorg</groupId>
    <artifactId>my-package</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>My Package</name>
    <description>A concise description</description>
    <url>https://github.com/myorg/my-package</url>

    <licenses>
        <license>
            <name>MIT License</name>
            <url>https://opensource.org/licenses/MIT</url>
        </license>
    </licenses>

    <developers>
        <developer>
            <name>Your Name</name>
            <email>you@example.com</email>
        </developer>
    </developers>

    <scm>
        <connection>scm:git:git://github.com/myorg/my-package.git</connection>
        <developerConnection>scm:git:ssh://github.com:myorg/my-package.git</developerConnection>
        <url>https://github.com/myorg/my-package</url>
    </scm>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-gpg-plugin</artifactId>
                <version>3.2.4</version>
                <executions>
                    <execution>
                        <id>sign-artifacts</id>
                        <phase>verify</phase>
                        <goals><goal>sign</goal></goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.sonatype.central</groupId>
                <artifactId>central-publishing-maven-plugin</artifactId>
                <version>0.6.0</version>
                <extensions>true</extensions>
                <configuration>
                    <publishingServerId>central</publishingServerId>
                    <autoPublish>true</autoPublish>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

Maven Central requires: sources JAR, javadoc JAR, GPG signature, and all POM metadata above.

#### Publishing Workflow

```yaml
name: Publish to Maven Central
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          java-version: "21"
          distribution: temurin
          server-id: central
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          gpg-passphrase: GPG_PASSPHRASE

      - run: mvn -B deploy -P release
        env:
          MAVEN_USERNAME: ${{ secrets.OSSRH_USERNAME }}
          MAVEN_PASSWORD: ${{ secrets.OSSRH_TOKEN }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

### NuGet

#### .csproj (replaces .nuspec for SDK-style projects)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <PackageId>MyOrg.MyPackage</PackageId>
    <Version>1.0.0</Version>
    <Authors>Your Name</Authors>
    <Description>A concise description</Description>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <PackageProjectUrl>https://github.com/myorg/my-package</PackageProjectUrl>
    <RepositoryUrl>https://github.com/myorg/my-package</RepositoryUrl>
    <PackageTags>cli;documentation</PackageTags>
    <PackageReadmeFile>README.md</PackageReadmeFile>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
  </PropertyGroup>
  <ItemGroup>
    <None Include="README.md" Pack="true" PackagePath="\" />
  </ItemGroup>
</Project>
```

#### Publishing Workflow

```yaml
name: Publish to NuGet
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"

      - run: dotnet build --configuration Release
      - run: dotnet test --configuration Release --no-build
      - run: dotnet pack --configuration Release --no-build --output nupkgs

      - run: dotnet nuget push nupkgs/*.nupkg --api-key ${{ secrets.NUGET_API_KEY }} --source https://api.nuget.org/v3/index.json --skip-duplicate
```

### RubyGems

#### .gemspec

```ruby
Gem::Specification.new do |spec|
  spec.name          = "my_package"
  spec.version       = "1.0.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]
  spec.summary       = "A concise description"
  spec.description   = "A longer description of the package"
  spec.homepage      = "https://github.com/myorg/my-package"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/myorg/my-package"
  spec.metadata["changelog_uri"] = "https://github.com/myorg/my-package/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + ["README.md", "LICENSE", "CHANGELOG.md"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
```

#### Publishing Workflow

```yaml
name: Publish to RubyGems
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"

      - run: bundle install
      - run: bundle exec rake test

      - run: gem build *.gemspec
      - run: gem push *.gem
        env:
          GEM_HOST_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }}
```

### Homebrew

#### Formula Creation

```ruby
class MyPackage < Formula
  desc "A concise description"
  homepage "https://github.com/myorg/my-package"
  url "https://github.com/myorg/my-package/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "abc123..."
  license "MIT"

  depends_on "node@20"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "1.0.0", shell_output("#{bin}/my-cli --version")
  end
end
```

#### Tap Setup

A tap is a GitHub repository named `homebrew-<tapname>`. Structure:

```
homebrew-tap/
  Formula/
    my-package.rb
  README.md
```

Users install with:

```bash
brew tap myorg/tap
brew install my-package
```

#### Automated Formula Update Workflow

```yaml
name: Update Homebrew Formula
on:
  release:
    types: [published]

jobs:
  homebrew:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: myorg/homebrew-tap
          token: ${{ secrets.TAP_GITHUB_TOKEN }}

      - name: Update formula
        run: |
          VERSION="${{ github.event.release.tag_name }}"
          VERSION="${VERSION#v}"
          URL="https://github.com/${{ github.repository }}/archive/refs/tags/${{ github.event.release.tag_name }}.tar.gz"
          SHA256=$(curl -sL "$URL" | shasum -a 256 | cut -d' ' -f1)
          sed -i "s|url \".*\"|url \"$URL\"|" Formula/my-package.rb
          sed -i "s|sha256 \".*\"|sha256 \"$SHA256\"|" Formula/my-package.rb

      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add Formula/my-package.rb
          git commit -m "my-package ${VERSION}"
          git push
```

---

## 5. Distribution Channels

### GitHub Releases with Binary Assets and Checksums

```yaml
name: Release with Binaries
on:
  release:
    types: [published]

permissions:
  contents: write

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: linux-x64
          - os: macos-latest
            target: darwin-arm64
          - os: windows-latest
            target: win-x64
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - run: npm ci
      - run: npm run build

      - name: Package binary
        run: |
          tar -czf my-package-${{ matrix.target }}.tar.gz -C dist .

      - name: Upload release asset
        uses: softprops/action-gh-release@v2
        with:
          files: my-package-${{ matrix.target }}.tar.gz

  checksums:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Download all assets
        uses: robinraju/release-downloader@v1
        with:
          tag: ${{ github.event.release.tag_name }}
          fileName: "*.tar.gz"

      - name: Generate checksums
        run: sha256sum *.tar.gz > checksums-sha256.txt

      - name: Upload checksums
        uses: softprops/action-gh-release@v2
        with:
          files: checksums-sha256.txt
```

### GitHub Packages

GitHub Packages supports npm, Docker (GHCR), Maven, Gradle, NuGet, and RubyGems.

**npm to GitHub Packages:**

```json
{
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: 20
    registry-url: https://npm.pkg.github.com

- run: npm publish
  env:
    NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Packages are scoped to the repository owner. Package name must match `@owner/package-name`.

**Docker to GHCR:** See the GHCR push workflow in section 4 above.

**Maven to GitHub Packages:**

```xml
<distributionManagement>
    <repository>
        <id>github</id>
        <url>https://maven.pkg.github.com/myorg/my-package</url>
    </repository>
</distributionManagement>
```

### Platform-specific Registries

| Language | Registry | Auth method |
|----------|----------|-------------|
| JavaScript | npmjs.com | Token or OIDC |
| Python | pypi.org | Trusted publishing (OIDC) |
| Rust | crates.io | API token |
| Java | Maven Central (central.sonatype.com) | Token + GPG |
| .NET | nuget.org | API key |
| Ruby | rubygems.org | API key |
| Go | proxy.golang.org | None (fetches from git) |
| PHP | packagist.org | API token |
| Swift | Swift Package Registry | Git-based |

### System Package Repositories

**Homebrew tap:** See section 4 above.

**APT repository (Debian/Ubuntu):**

Host a repository on GitHub Pages or a static file host. Structure:

```
dists/
  stable/
    main/
      binary-amd64/
        Packages
        Packages.gz
pool/
  main/
    m/
      my-package/
        my-package_1.0.0_amd64.deb
```

Users add it:

```bash
curl -fsSL https://myorg.github.io/apt-repo/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/myorg.gpg
echo "deb [signed-by=/usr/share/keyrings/myorg.gpg] https://myorg.github.io/apt-repo stable main" | sudo tee /etc/apt/sources.list.d/myorg.list
sudo apt update && sudo apt install my-package
```

**RPM repository (Fedora/RHEL):**

```ini
# /etc/yum.repos.d/myorg.repo
[myorg]
name=MyOrg Packages
baseurl=https://myorg.github.io/rpm-repo
enabled=1
gpgcheck=1
gpgkey=https://myorg.github.io/rpm-repo/gpg.key
```

---

## 6. Pre-releases

### Alpha/Beta/RC Versioning

| Phase | Version | When |
|-------|---------|------|
| Alpha | `2.0.0-alpha.1`, `2.0.0-alpha.2` | Active development, testing internally |
| Beta | `2.0.0-beta.1`, `2.0.0-beta.2` | Feature-complete, testing with early adopters |
| RC | `2.0.0-rc.1`, `2.0.0-rc.2` | Production-ready candidate, final testing |
| Stable | `2.0.0` | Ship it |

Increment the numeric suffix for each pre-release build: `alpha.1`, `alpha.2`, etc.

### npm dist-tags

By default, `npm install my-package` installs the `latest` tag. Pre-releases should use different tags so users don't get unstable versions by accident.

```bash
# Publish a beta
npm publish --tag beta

# Publish an alpha
npm publish --tag alpha

# Publish a release candidate
npm publish --tag next

# Promote to latest (stable release)
npm publish  # automatically tags as latest
```

Users install specific channels:

```bash
npm install my-package@beta
npm install my-package@next
npm install my-package@latest  # default
```

Manage tags manually:

```bash
# Move a tag to a specific version
npm dist-tag add my-package@2.0.0-rc.1 next

# Remove a tag
npm dist-tag rm my-package next

# List tags
npm dist-tag ls my-package
```

In `package.json` with semantic-release, configure branches:

```json
{
  "branches": [
    "main",
    { "name": "beta", "prerelease": true },
    { "name": "alpha", "prerelease": true }
  ]
}
```

Commits to `beta` branch publish as `2.0.0-beta.1` with the `beta` dist-tag. Commits to `main` publish as stable with `latest`.

### PyPI Pre-release Versioning

PyPI follows PEP 440:

```
2.0.0a1    # alpha
2.0.0b1    # beta
2.0.0rc1   # release candidate
2.0.0      # stable
```

Note: no dots or hyphens before the pre-release tag. `a`, `b`, `rc` are the only valid prefixes.

By default, `pip install my-package` ignores pre-releases. Users opt in:

```bash
pip install --pre my-package
pip install my-package==2.0.0a1
```

In `pyproject.toml`:

```toml
[project]
version = "2.0.0a1"
```

### GitHub Pre-release Flag

When creating a release via API or UI, set `prerelease: true`. Pre-releases:
- Display a "Pre-release" badge
- Are NOT shown as the "Latest release"
- Are still visible on the releases page
- Can be installed via direct URL or tag

In a workflow:

```yaml
- uses: softprops/action-gh-release@v2
  with:
    prerelease: ${{ contains(github.ref, 'alpha') || contains(github.ref, 'beta') || contains(github.ref, 'rc') }}
    generate_release_notes: true
```

With `gh` CLI:

```bash
gh release create v2.0.0-beta.1 --prerelease --generate-notes --title "v2.0.0-beta.1"
```

### Pre-release Workflow Pattern

A complete workflow that handles both stable and pre-release publishing:

```yaml
name: Release
on:
  push:
    tags:
      - "v*"

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: https://registry.npmjs.org

      - run: npm ci
      - run: npm test

      - name: Determine npm tag
        id: npm-tag
        run: |
          VERSION="${GITHUB_REF_NAME#v}"
          if [[ "$VERSION" == *"-alpha"* ]]; then
            echo "tag=alpha" >> "$GITHUB_OUTPUT"
          elif [[ "$VERSION" == *"-beta"* ]]; then
            echo "tag=beta" >> "$GITHUB_OUTPUT"
          elif [[ "$VERSION" == *"-rc"* ]]; then
            echo "tag=next" >> "$GITHUB_OUTPUT"
          else
            echo "tag=latest" >> "$GITHUB_OUTPUT"
          fi

      - run: npm publish --tag ${{ steps.npm-tag.outputs.tag }} --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      - name: Determine prerelease flag
        id: prerelease
        run: |
          VERSION="${GITHUB_REF_NAME#v}"
          if [[ "$VERSION" == *"-"* ]]; then
            echo "is_prerelease=true" >> "$GITHUB_OUTPUT"
          else
            echo "is_prerelease=false" >> "$GITHUB_OUTPUT"
          fi

      - uses: softprops/action-gh-release@v2
        with:
          prerelease: ${{ steps.prerelease.outputs.is_prerelease }}
          generate_release_notes: true
```
