# Licensing, Legal, and Compliance

Reference for license selection, contributor agreements, compliance documents, and dependency scanning. This file covers the legal surface area of a repository — from choosing a license to scanning dependencies for compatibility.

**Not legal advice.** This reference provides practical guidance for common scenarios. Consult a lawyer for anything involving regulated industries, dual licensing, or commercial relicensing.

---

## License selection flowchart

Use this decision tree to pick a license. Start at the top, follow the branch that matches your intent.

```
START → What is your goal?
│
├─ Maximum adoption, minimum friction?
│   └─ MIT (SPDX: MIT)
│      Simple, well-understood, universally compatible.
│
├─ Maximum adoption + patent protection?
│   └─ Apache 2.0 (SPDX: Apache-2.0)
│      Explicit patent grant. Required if your code implements patented techniques.
│
├─ Derivatives must stay open source?
│   │
│   ├─ Strong copyleft (entire linked work)?
│   │   │
│   │   ├─ Traditional distribution?
│   │   │   └─ GPL v3 (SPDX: GPL-3.0-only)
│   │   │
│   │   └─ SaaS / network use must share source?
│   │       └─ AGPL v3 (SPDX: AGPL-3.0-only)
│   │
│   ├─ Weak copyleft (only modified files)?
│   │   │
│   │   ├─ File-level copyleft?
│   │   │   └─ MPL 2.0 (SPDX: MPL-2.0)
│   │   │
│   │   └─ Library-level copyleft?
│   │       └─ LGPL v3 (SPDX: LGPL-3.0-only)
│   │
│   └─ Copyleft but compatible with Apache 2.0?
│       └─ MPL 2.0 (SPDX: MPL-2.0)
│
├─ Source-available but not open source?
│   │
│   ├─ Time-delayed open source?
│   │   └─ BSL 1.1 (SPDX: BUSL-1.1)
│   │      Converts to open source after a set date. Used by MariaDB, HashiCorp, Sentry.
│   │
│   └─ Restrict competing SaaS offerings?
│       └─ Elastic License 2.0 (SPDX: Elastic-2.0)
│          or SSPL (SPDX: SSPL-1.0)
│          Neither is OSI-approved. SSPL is more restrictive.
│
├─ Documentation or creative content (not code)?
│   └─ Creative Commons
│      CC BY 4.0 for attribution-only. CC BY-SA 4.0 for share-alike.
│      Never use CC for code — it doesn't address patents or software distribution.
│
└─ Dual licensing (open source + commercial)?
    └─ GPL v3 or AGPL v3 for the open source track.
       Separate commercial license for customers who can't comply with copyleft.
       Requires CLA or full copyright ownership. See the CLA section below.
```

### Top 8 licenses compared

| License | SPDX | Type | Patent grant | Copyleft | SaaS copyleft | OSI approved | Use when |
|---|---|---|---|---|---|---|---|
| **MIT** | `MIT` | Permissive | No | No | No | Yes | Default choice for maximum adoption |
| **Apache 2.0** | `Apache-2.0` | Permissive | Yes | No | No | Yes | Need patent protection; enterprise adoption |
| **GPL v3** | `GPL-3.0-only` | Strong copyleft | Yes | Yes | No | Yes | Derivatives must remain open source |
| **AGPL v3** | `AGPL-3.0-only` | Network copyleft | Yes | Yes | Yes | Yes | SaaS must share modifications |
| **MPL 2.0** | `MPL-2.0` | Weak copyleft | Yes | File-level | No | Yes | Copyleft for your files, permissive for theirs |
| **LGPL v3** | `LGPL-3.0-only` | Weak copyleft | Yes | Library-level | No | Yes | Libraries that proprietary code can link |
| **BSL 1.1** | `BUSL-1.1` | Source-available | Varies | Delayed | Varies | No | Time-delayed open source conversion |
| **ELv2** | `Elastic-2.0` | Source-available | No | No | Restricted | No | Prevent competing managed services |

**Default recommendation:** MIT for libraries, Apache 2.0 for anything touching patents, GPL v3 or AGPL v3 for copyleft intent. If you don't know what you need, use MIT.

---

## License details

For each license: what it permits, what it requires, what it restricts, and the SPDX identifier.

### Permissive licenses

#### MIT License

- **SPDX:** `MIT`
- **Permits:** Commercial use, modification, distribution, private use, sublicensing
- **Requires:** License and copyright notice included in copies
- **Restricts:** Nothing. No warranty, no liability.
- **Notes:** The most popular open source license. Two paragraphs. No ambiguity. If your only goal is "let people use this," MIT is the answer. Does not include an explicit patent grant — this is its one weakness compared to Apache 2.0.

#### Apache License 2.0

- **SPDX:** `Apache-2.0`
- **Permits:** Commercial use, modification, distribution, patent use, private use, sublicensing
- **Requires:** License and copyright notice, state changes, include NOTICE file if one exists
- **Restricts:** Trademark use (explicitly does not grant trademark rights). No warranty, no liability.
- **Notes:** The enterprise-friendly permissive license. Explicit patent grant protects both contributors and users. Includes a patent retaliation clause: if you sue for patent infringement over the software, your patent license terminates. Use this when your code implements algorithms that could be patented, or when enterprise adopters need patent clarity.

#### BSD 2-Clause ("Simplified")

- **SPDX:** `BSD-2-Clause`
- **Permits:** Commercial use, modification, distribution, private use
- **Requires:** License and copyright notice in source and binary distributions
- **Restricts:** Nothing beyond MIT. No warranty, no liability.
- **Notes:** Functionally identical to MIT. Historically used by BSD-derived projects. No reason to choose this over MIT for new projects unless you're contributing to the BSD ecosystem.

#### BSD 3-Clause ("New" or "Revised")

- **SPDX:** `BSD-3-Clause`
- **Permits:** Same as BSD 2-Clause
- **Requires:** Same as BSD 2-Clause + third clause: may not use contributor names for endorsement without permission
- **Restricts:** Using contributor names/organization for endorsement
- **Notes:** The "no endorsement" clause is the only difference from BSD 2-Clause. Used by some corporate projects (Google's Go uses BSD 3-Clause). Slightly more protective for the original authors.

#### ISC License

- **SPDX:** `ISC`
- **Permits:** Commercial use, modification, distribution, private use
- **Requires:** License and copyright notice
- **Restricts:** Nothing. No warranty, no liability.
- **Notes:** Functionally equivalent to MIT but with simpler language. Preferred by OpenBSD and some npm packages. Two sentences instead of MIT's two paragraphs. Use MIT instead for new projects — it's better understood.

### Copyleft licenses

#### GPL v2

- **SPDX:** `GPL-2.0-only` (exactly v2) or `GPL-2.0-or-later` (v2 or any later version)
- **Permits:** Commercial use, modification, distribution
- **Requires:** Source code disclosure, license and copyright notice, state changes, same license for derivative works
- **Restricts:** Sublicensing (copyleft terms pass through). No warranty, no liability.
- **Notes:** The Linux kernel uses GPL v2-only. The key difference from v3: no explicit patent grant, no anti-tivoization clause. Projects locked to GPL-2.0-only cannot upgrade to v3. New projects should use GPL v3 unless they have a specific reason to use v2. **GPL v2 is incompatible with Apache 2.0** — this is one of the most common license conflicts.

#### GPL v3

- **SPDX:** `GPL-3.0-only` or `GPL-3.0-or-later`
- **Permits:** Commercial use, modification, distribution, patent use
- **Requires:** Source code disclosure, license and copyright notice, state changes, same license for derivative works, installation information (anti-tivoization)
- **Restricts:** Sublicensing, tivoization (hardware that prevents running modified versions). No warranty, no liability.
- **Notes:** Strong copyleft. Any work that links to, includes, or is derived from GPL v3 code must also be GPL v3. Explicit patent grant. Anti-tivoization clause requires that users can install modified versions on the hardware. Compatible with Apache 2.0 (one-way: Apache code can go into GPL v3, but not the reverse).

#### LGPL v3

- **SPDX:** `LGPL-3.0-only` or `LGPL-3.0-or-later`
- **Permits:** Commercial use, modification, distribution, patent use, linking without copyleft
- **Requires:** Source code disclosure for modifications to the LGPL library itself, license and copyright notice, ability for users to replace the LGPL library
- **Restricts:** Modifications to the library must stay LGPL. No warranty, no liability.
- **Notes:** "Library GPL." Proprietary applications can link to an LGPL library without becoming copyleft, as long as the user can swap out the library. Modifications to the library itself must be shared. Used by glibc, Qt (dual-licensed). Good for libraries where you want copyleft protection but don't want to prevent proprietary use.

#### AGPL v3

- **SPDX:** `AGPL-3.0-only` or `AGPL-3.0-or-later`
- **Permits:** Commercial use, modification, distribution, patent use
- **Requires:** Everything GPL v3 requires + source code must be provided to users who interact with the software over a network
- **Restricts:** Running modified versions as a service without sharing source. No warranty, no liability.
- **Notes:** Closes the "SaaS loophole" in GPL. If you modify AGPL code and run it as a web service, you must provide the source to your users. This is the strongest copyleft license. Used by MongoDB (before SSPL), Grafana, Mastodon. Some companies have policies that prohibit using AGPL software — factor this into adoption considerations.

#### MPL 2.0

- **SPDX:** `MPL-2.0`
- **Permits:** Commercial use, modification, distribution, patent use
- **Requires:** Source code disclosure for modified MPL files, license and copyright notice
- **Restricts:** Copyleft applies only at the file level — new files in the same project can be under any license. No warranty, no liability.
- **Notes:** The "middle ground" copyleft. Modifications to MPL-licensed files must stay MPL, but you can add proprietary files alongside them. Compatible with Apache 2.0 and GPL v3 (MPL 2.0 code can be combined with either). Used by Firefox, Terraform (before BSL). Good for projects that want some copyleft protection without the viral nature of GPL.

### Source-available licenses

These are **not** OSI-approved open source licenses. They restrict certain uses.

#### Business Source License 1.1 (BSL)

- **SPDX:** `BUSL-1.1`
- **Permits:** Non-production use, viewing source, modification for non-production
- **Requires:** Compliance with "Additional Use Grant" and "Change Date" terms
- **Restricts:** Production use beyond what the Additional Use Grant allows (typically: no competing products). Converts to an open source license (specified in the license) on the Change Date.
- **Notes:** Time-delayed open source. The license specifies a Change Date (typically 3-4 years) after which the code converts to the specified open source license (usually Apache 2.0 or GPL). Used by MariaDB (creator of BSL), HashiCorp (Terraform, Vault), Sentry, CockroachDB. The Additional Use Grant defines what production use is allowed before the Change Date — this varies by project.

#### Server Side Public License (SSPL)

- **SPDX:** `SSPL-1.0`
- **Permits:** Use, modification, distribution
- **Requires:** If you offer the software as a service, you must open source your entire service stack (not just the SSPL software, but the management, monitoring, user interface — everything needed to run the service)
- **Restricts:** Offering as a managed service without open sourcing your entire stack
- **Notes:** Created by MongoDB. Rejected by OSI and not considered open source. The "offer your entire stack" requirement is intentionally onerous to prevent cloud providers from offering competing managed services. MongoDB, Elastic (briefly), and Graylog have used SSPL. Most projects choose BSL or ELv2 over SSPL due to the extreme scope of the requirement.

#### Elastic License 2.0 (ELv2)

- **SPDX:** `Elastic-2.0`
- **Permits:** Use, modification, distribution, including commercial use
- **Requires:** License and copyright notice
- **Restricts:** Two things: (1) providing the software as a managed service, (2) circumventing license key functionality or removing/obscuring features protected by license keys
- **Notes:** Simpler than SSPL, less restrictive than BSL. You can use and modify the software commercially — you just cannot offer it as a managed service that competes with the licensor. Used by Elastic (Elasticsearch, Kibana). Short and readable. Not OSI-approved.

### Creative Commons (for documentation and content, NOT code)

Creative Commons licenses are designed for creative works, not software. Use them for documentation, blog posts, tutorials, images, and other non-code content.

| License | SPDX | Permits | Requires | Restricts |
|---|---|---|---|---|
| **CC BY 4.0** | `CC-BY-4.0` | Share, adapt, commercial use | Attribution | Nothing else |
| **CC BY-SA 4.0** | `CC-BY-SA-4.0` | Share, adapt, commercial use | Attribution, share-alike | Derivatives must use same license |
| **CC BY-NC 4.0** | `CC-BY-NC-4.0` | Share, adapt | Attribution | Commercial use |
| **CC BY-ND 4.0** | `CC-BY-ND-4.0` | Share, commercial use | Attribution | No derivatives |
| **CC0 1.0** | `CC0-1.0` | Everything | Nothing | Nothing (public domain dedication) |

**For docs in a code repo:** Use `CC-BY-4.0` for documentation. This lets anyone share and adapt your docs with attribution. If you want your docs to be completely free, use `CC0-1.0`.

**Never use Creative Commons for code.** CC licenses don't address patents, software distribution, or linking — use a proper software license instead.

**Dual licensing for repos with code + docs:** License code under MIT/Apache/GPL and docs under CC BY 4.0. State this clearly in your README and LICENSE file.

---

## License compatibility matrix

Not all licenses can be combined in the same project. This matrix shows which combinations work.

### Compatibility rules

**Permissive into copyleft:** Permissive-licensed code (MIT, Apache 2.0, BSD, ISC) can always be included in a copyleft project. The combined work uses the copyleft license.

**Copyleft into permissive:** Copyleft code cannot be included in a permissive project. The copyleft terms would require the entire project to become copyleft.

**Copyleft into different copyleft:** Generally incompatible unless one license explicitly allows it (e.g., MPL 2.0 has a GPL compatibility clause).

### Compatibility table

Reading: "Can code under the **row** license be included in a project under the **column** license?"

| From \ Into | MIT | Apache 2.0 | GPL v2 | GPL v3 | AGPL v3 | MPL 2.0 | LGPL v3 |
|---|---|---|---|---|---|---|---|
| **MIT** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **Apache 2.0** | Yes | Yes | **No** | Yes | Yes | Yes | Yes |
| **BSD 2/3** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **ISC** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **GPL v2** | No | No | Yes | **No** | No | No | No |
| **GPL v3** | No | No | No | Yes | Yes | No | No |
| **AGPL v3** | No | No | No | No | Yes | No | No |
| **MPL 2.0** | No | No | Yes* | Yes* | Yes* | Yes | Yes* |
| **LGPL v3** | No | No | No | Yes | Yes | No | Yes |

*MPL 2.0 has an explicit "GPL compatibility" clause (Section 3.3) that allows MPL code to be combined with GPL/AGPL code. The combined work is under the GPL/AGPL.

### Common conflicts

**Apache 2.0 + GPL v2:** Incompatible. Apache 2.0's patent retaliation clause imposes additional restrictions that GPL v2 does not allow. This is one of the most common license conflicts in practice. If you depend on a GPL v2-only library and want to use Apache 2.0 code, you have a problem. GPL v3 resolved this — Apache 2.0 code can be included in GPL v3 projects.

**GPL v2-only + GPL v3:** Incompatible. Code licensed under `GPL-2.0-only` (not "or later") cannot be combined with GPL v3 code. Code licensed under `GPL-2.0-or-later` can be used under GPL v3.

**AGPL + proprietary:** Most corporate legal teams treat AGPL as a hard blocker. If your library targets enterprise adoption, AGPL will significantly limit your user base.

**Practical advice:** Before adding any dependency, check its license. Use automated scanning (see Dependency License Scanning below). When in doubt, check the SPDX license expression in the dependency's package manifest.

---

## CLAs vs DCOs

Two mechanisms for managing contributor intellectual property. Every project with external contributors needs one or the other.

### Contributor License Agreement (CLA)

**What it is:** A legal agreement that contributors sign, granting the project certain rights over their contributions. Typically grants a copyright license and patent license to the project maintainers or organization.

**Why use it:**
- Required for dual licensing (open source + commercial). Without a CLA, you cannot relicense contributions.
- Required for copyright assignment or broad license grants to a foundation or company.
- Provides explicit patent grants from contributors.
- Gives the project legal standing to defend against IP claims.

**Two types:**
- **Individual CLA (ICLA):** Signed by individual contributors. Covers contributions made on their own time.
- **Corporate CLA (CCLA):** Signed by a company. Covers contributions made by their employees during work.

**CLA templates:**
- **Apache ICLA/CCLA:** The standard. Used by Apache Foundation, Google, Facebook, Microsoft. Well-tested legally.
- **Canonical Contributor Agreement:** Alternative with copyright assignment option.
- **Custom CLA:** Only if you have a lawyer draft it. Don't write your own.

**CLA Assistant setup (GitHub):**

1. Use [CLA Assistant](https://cla-assistant.io/) (free, hosted by SAP)
2. Create a gist with your CLA text
3. Go to https://cla-assistant.io/ and link your repository
4. CLA Assistant bot will comment on PRs from contributors who haven't signed
5. Contributors sign by commenting on the PR (no separate form)

Alternative: [CLA Assistant Lite](https://github.com/contributor-assistant/github-action) — a GitHub Action that stores signatures in a file in the repo instead of an external service.

**.github/workflows/cla.yml:**

```yaml
name: CLA Assistant
on:
  issue_comment:
    types: [created]
  pull_request_target:
    types: [opened, synchronize, reopened]

permissions:
  actions: write
  contents: write
  pull-requests: write
  statuses: write

jobs:
  cla:
    runs-on: ubuntu-latest
    if: |
      (github.event.comment.body == 'recheck' || github.event.comment.body == 'I have read the CLA Document and I hereby sign the CLA')
      || github.event_name == 'pull_request_target'
    steps:
      - uses: contributor-assistant/github-action@v2
        with:
          path-to-signatures: 'signatures/cla.json'
          path-to-document: 'https://github.com/YOUR_ORG/YOUR_REPO/blob/main/CLA.md'
          branch: 'main'
          allowlist: 'bot*,dependabot*,renovate*'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Developer Certificate of Origin (DCO)

**What it is:** A lightweight attestation that the contributor has the right to submit their contribution. Not a license grant — it's a certification that the contributor wrote the code (or has permission to submit it) and agrees to the project's license.

**The full DCO text is short:** Contributors certify that their contribution is their original work or they have the right to submit it, and they agree to the project's license terms.

**Why use it:**
- Simpler than a CLA — no legal agreement to sign
- Used by the Linux kernel, CNCF projects, and many large open source projects
- Lower barrier to entry for contributors
- Sufficient for projects that don't need to relicense contributions

**How it works:**

Contributors add a `Signed-off-by` line to their commits:

```bash
git commit -s -m "feat: add user search endpoint"
# Produces: feat: add user search endpoint
#
#           Signed-off-by: Jane Developer <jane@example.com>
```

The `-s` flag automatically adds the `Signed-off-by` line using the committer's `user.name` and `user.email` from git config.

**DCO bot setup (GitHub):**

Install the [DCO GitHub App](https://github.com/apps/dco) on your repository. It checks every commit in a PR for a valid `Signed-off-by` line and sets a required status check.

No workflow file needed — the DCO app runs as a GitHub App, not an Action.

**Document it in CONTRIBUTING.md:**

Add a section explaining:
- The project uses DCO
- Every commit must be signed off with `git commit -s`
- What the DCO means (link to https://developercertificate.org/)
- How to fix commits that are missing the sign-off: `git commit --amend -s`
- How to sign off retroactively on a branch: `git rebase --signoff HEAD~N`

### Decision guide: CLA vs DCO

| Factor | CLA | DCO |
|---|---|---|
| **Contributor friction** | Higher — must sign before first PR | Lower — just add `-s` to commits |
| **Relicensing** | Enables it | Does not enable it |
| **Dual licensing** | Required | Not sufficient |
| **Patent grant** | Explicit | Implicit (through project license) |
| **Corporate contributions** | CCLA handles employer IP | Contributors responsible for their own |
| **Legal standing** | Stronger | Weaker (attestation, not agreement) |
| **Adoption** | Google, Apache, Meta, Microsoft | Linux, CNCF, Kubernetes, Helm |

**Use CLA when:**
- You need to dual-license (open source + commercial)
- You're a company that may need to relicense in the future
- You need explicit patent grants from contributors
- Your legal team requires it

**Use DCO when:**
- You're a community-driven project with no relicensing plans
- You want the lowest possible barrier to contribution
- You're under a foundation (CNCF, Linux Foundation) that uses DCO
- Simplicity is more important than legal flexibility

**Use neither when:**
- The project is personal/hobby with no external contributors
- The project is internal to your company (employment agreement covers IP)

---

## Compliance documents

Not every project needs these. The triggers below tell you when each document becomes legally relevant.

### Privacy Policy

**What:** Describes what personal data you collect, how you use it, who you share it with, and users' rights.

**When legally required:**
- You collect any personal data (names, emails, IP addresses, cookies, analytics)
- You have users in the EU/EEA (GDPR)
- You have users in California (CCPA/CPRA)
- You use any analytics service (Google Analytics, Plausible, Mixpanel)
- You have user accounts with email/password login
- You process data from children under 13 (COPPA in the US)

**Where to put it:**
- Hosted web app: `/privacy` or `/privacy-policy` page, linked from footer
- SaaS: `/legal/privacy` page
- Open source tool that phones home: `PRIVACY.md` in repo root + link in README
- Mobile app: App Store / Play Store listing + in-app settings

**Not needed for:** Libraries, CLI tools with no telemetry, self-hosted software that doesn't collect data.

### Terms of Service

**What:** The legal agreement between you and your users. Covers acceptable use, liability limitations, termination, and dispute resolution.

**When legally required:**
- You operate a web application or SaaS
- You have paid users or customers
- You provide an API that others consume
- You host user-generated content

**Where to put it:**
- Hosted web app: `/terms` or `/terms-of-service` page, linked from footer
- SaaS: `/legal/terms` page
- API: Link in API documentation and developer portal

**Not needed for:** Open source libraries (the LICENSE file covers this), self-hosted software, documentation sites.

### Cookie Policy

**What:** Describes what cookies and tracking technologies you use, their purpose, and how users can manage them.

**When legally required:**
- You use cookies beyond strictly necessary ones (GDPR ePrivacy Directive)
- You have users in the EU/EEA
- You use any third-party analytics, advertising, or tracking scripts

**Where to put it:**
- Combined with Privacy Policy (common and acceptable)
- Or separate `/cookies` page linked from cookie consent banner

**Not needed for:** Sites that only use strictly necessary cookies (session cookies, CSRF tokens). Not needed for repos, libraries, or CLI tools.

### Data Processing Agreement (DPA)

**What:** A contract between a data controller (your customer) and data processor (you) that governs how personal data is handled.

**When legally required:**
- You process personal data on behalf of customers (you're a data processor under GDPR)
- Your SaaS stores or processes customer data containing personal information
- Enterprise customers request it (they're legally required to have DPAs with their processors)

**Where to put it:**
- `/legal/dpa` page on your website
- Downloadable PDF linked from your legal/security page
- Often pre-signed and available on request

**Not needed for:** Open source projects, self-hosted software, tools that don't process third-party personal data.

### HIPAA Business Associate Agreement (BAA)

**What:** A contract required when you handle Protected Health Information (PHI) on behalf of a healthcare entity (a "covered entity" under HIPAA).

**When legally required:**
- You store, process, or transmit PHI for healthcare organizations
- Your SaaS is used by hospitals, clinics, health insurers, or their business associates
- You're a subcontractor that touches PHI

**Where to put it:**
- Separate legal agreement, not a repo file
- Available on request from your legal/compliance team
- Listed on your security/compliance page

**Not needed for:** The vast majority of software projects. Only relevant if you're specifically building for healthcare and handling PHI.

### Accessibility Statement

**What:** Declares your commitment to accessibility, states which WCAG conformance level you target, and provides contact information for accessibility issues.

**When legally required:**
- Public sector websites in the EU (EN 301 549)
- US federal agencies and contractors (Section 508)
- Increasingly required for private sector under ADA case law in the US
- Good practice for any public-facing web application

**Where to put it:**
- `/accessibility` page on your website, linked from footer
- For open source: note WCAG conformance target in README or CONTRIBUTING

**WCAG levels:**
- **Level A:** Minimum. Basic accessibility requirements.
- **Level AA:** The standard target. Required by most regulations.
- **Level AAA:** Maximum. Aspirational for most projects.

### Export Compliance

**What:** Statements and controls related to export regulations that govern the distribution of software, especially software containing cryptography.

**When legally required:**
- Your software includes or uses encryption (EAR Category 5, Part 2)
- You distribute software to sanctioned countries or entities (OFAC)
- Your software has military or dual-use applications (ITAR)
- You distribute from the United States (EAR applies to all US-origin software)

**Where to put it:**
- `EXPORT_COMPLIANCE.md` or a section in your README for open source projects
- For US-based projects using encryption: file a TSU (Technology and Software Unrestricted) notification with BIS if distributing openly
- Note the ECCN (Export Control Classification Number) in your documentation

**Practical impact for most projects:**
- Open source software using standard encryption (TLS, HTTPS, SSH) is generally covered under License Exception TSU (publicly available technology)
- You still need to ensure you're not distributing to sanctioned entities
- Most open source hosting platforms (GitHub, GitLab) handle geographic restrictions at the platform level

**Not needed for:** Projects that don't use encryption and have no military/dual-use applications. However, if your project uses HTTPS (most do), technically EAR applies — the TSU exception covers this for open source.

---

## SPDX license identifiers

SPDX (Software Package Data Exchange) identifiers are the standard way to reference licenses in machine-readable formats. Use the exact identifier from the [SPDX License List](https://spdx.org/licenses/).

### Common identifiers

| License | SPDX Identifier |
|---|---|
| MIT | `MIT` |
| Apache 2.0 | `Apache-2.0` |
| GPL v2 only | `GPL-2.0-only` |
| GPL v2 or later | `GPL-2.0-or-later` |
| GPL v3 only | `GPL-3.0-only` |
| GPL v3 or later | `GPL-3.0-or-later` |
| AGPL v3 only | `AGPL-3.0-only` |
| LGPL v3 only | `LGPL-3.0-only` |
| MPL 2.0 | `MPL-2.0` |
| BSD 2-Clause | `BSD-2-Clause` |
| BSD 3-Clause | `BSD-3-Clause` |
| ISC | `ISC` |
| BSL 1.1 | `BUSL-1.1` |
| Elastic License 2.0 | `Elastic-2.0` |
| CC BY 4.0 | `CC-BY-4.0` |
| CC0 1.0 | `CC0-1.0` |
| Unlicense | `Unlicense` |

### SPDX expressions

For dual-licensed or multi-licensed projects, use SPDX expressions:

```
MIT OR Apache-2.0          # User can choose either license
MIT AND CC-BY-4.0          # Both licenses apply (code + docs)
GPL-3.0-only WITH Classpath-exception-2.0  # License with exception
(MIT OR Apache-2.0) AND CC-BY-4.0          # Grouped expression
```

### Usage in package manifests

**package.json (Node.js):**
```json
{
  "license": "MIT"
}
```

For dual licensing:
```json
{
  "license": "(MIT OR Apache-2.0)"
}
```

**Cargo.toml (Rust):**
```toml
[package]
license = "MIT OR Apache-2.0"
```

Rust ecosystem convention is dual MIT/Apache-2.0.

**pyproject.toml (Python):**
```toml
[project]
license = "MIT"

# Or with SPDX expression (PEP 639):
license = "MIT OR Apache-2.0"
```

Note: Older Python projects use classifiers instead. PEP 639 introduced the `license` field with SPDX expressions. Use SPDX for new projects.

**go.mod (Go):**

Go doesn't have a license field in `go.mod`. Place a `LICENSE` file in the module root. Go tooling uses the file name and content for detection.

**Gemspec (Ruby):**
```ruby
spec.license = "MIT"
# or for multiple:
spec.licenses = ["MIT", "Apache-2.0"]
```

**pom.xml (Java/Maven):**
```xml
<licenses>
  <license>
    <name>MIT License</name>
    <url>https://opensource.org/licenses/MIT</url>
    <distribution>repo</distribution>
  </license>
</licenses>
```

**composer.json (PHP):**
```json
{
  "license": "MIT"
}
```

**pubspec.yaml (Dart/Flutter):**

Dart does not have a license field in `pubspec.yaml`. Place a `LICENSE` file in the package root. `pub.dev` detects the license from the file.

**nuspec / .csproj (C#/.NET):**
```xml
<PropertyGroup>
  <PackageLicenseExpression>MIT</PackageLicenseExpression>
</PropertyGroup>
```

**mix.exs (Elixir):**
```elixir
defp package do
  [
    licenses: ["Apache-2.0"],
    # ...
  ]
end
```

### SPDX headers in source files

For copyleft licenses (GPL, AGPL, LGPL, MPL), add an SPDX header to each source file:

```
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 Your Name
```

For permissive licenses, this is optional but can be useful for large codebases or projects where files may be copied individually.

The [REUSE](https://reuse.software/) specification from the FSFE provides a standard for adding SPDX headers to every file and is required by some European public sector projects.

---

## Dependency license scanning

Automated scanning catches license conflicts before they become legal problems. Set this up in CI for any project with external dependencies.

### Tools

**FOSSA** (commercial, free tier available):
- Deep license detection across all package managers
- Policy engine for approved/denied licenses
- SBOM generation
- CI integration via CLI or GitHub Action
- Best for: Enterprise projects that need compliance reporting

**Snyk** (commercial, free tier available):
- Combined security vulnerability + license scanning
- Policy-based license compliance
- CI integration via CLI or GitHub Action
- Best for: Projects that already use Snyk for security scanning

**license-checker (npm):**
```bash
npx license-checker --summary
npx license-checker --failOn "GPL-3.0-only;AGPL-3.0-only"
npx license-checker --json --out licenses.json
```
Best for: Node.js projects that need a quick, free solution.

**pip-licenses (Python):**
```bash
pip-licenses --format=table
pip-licenses --fail-on="GPLv3;AGPLv3"
pip-licenses --format=json --output-file=licenses.json
```
Best for: Python projects.

**cargo-license (Rust):**
```bash
cargo install cargo-license
cargo license
cargo license --json
```
Best for: Rust projects.

**go-licenses (Go):**
```bash
go install github.com/google/go-licenses@latest
go-licenses check ./...
go-licenses csv ./...
```
Best for: Go projects.

**ScanCode Toolkit** (open source):
- Language-agnostic license detection
- Scans actual file contents, not just package manifests
- Detects embedded license notices and copyright statements
- Best for: Deep analysis, detecting licenses in vendored code

### CI integration

**GitHub Actions example (Node.js with license-checker):**

```yaml
name: License Check
on:
  pull_request:
  push:
    branches: [main]

jobs:
  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
      - name: Check dependency licenses
        run: |
          npx license-checker \
            --failOn "GPL-3.0-only;GPL-3.0-or-later;AGPL-3.0-only;AGPL-3.0-or-later;SSPL-1.0" \
            --excludePrivatePackages
```

**FOSSA GitHub Action:**

```yaml
- uses: fossas/fossa-action@main
  with:
    api-key: ${{ secrets.FOSSA_API_KEY }}
```

### License policy

Define which licenses are acceptable for your project. A typical policy for a permissively licensed project:

| Category | Licenses | Action |
|---|---|---|
| **Allowed** | MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, CC0-1.0, Unlicense, 0BSD | No action needed |
| **Review** | MPL-2.0, LGPL-2.1-only, LGPL-3.0-only, CC-BY-4.0 | Manual review — usually fine for dependencies |
| **Denied** | GPL-2.0-only, GPL-3.0-only, AGPL-3.0-only, SSPL-1.0, BUSL-1.1 | Cannot use in a permissively licensed project |
| **Unknown** | Unlisted or custom licenses | Must be reviewed by a human before inclusion |

Adjust this policy based on your project's license. A GPL v3 project can freely use GPL-licensed dependencies. A proprietary project has the most restrictive policy.

---

## Trademark

Trademarks protect your project's name, logo, and brand identity. Separate from copyright (which the LICENSE file covers).

### When to include a TRADEMARK.md

- Your project has a recognizable name or logo
- You're an open source project with a brand to protect
- You want to prevent confusing or misleading use of your project's identity
- You're under a foundation that owns the trademark (CNCF, Apache, Linux Foundation)

Not needed for personal projects, early-stage MVPs, or internal tools.

### TRADEMARK.md template

```markdown
# Trademark Policy

## Project Name

"[PROJECT NAME]" and the [PROJECT NAME] logo are trademarks of
[OWNER NAME / ORGANIZATION].

## Acceptable Use

You MAY:
- Use the project name to refer to the project itself (e.g., "built with
  [PROJECT NAME]," "compatible with [PROJECT NAME]")
- Use the project name in blog posts, articles, and tutorials about
  the project
- Use the project name in community presentations and talks
- Display the logo when linking to the official project

You MAY NOT:
- Use the project name or logo in your own product name or branding
- Modify the logo (colors, proportions, elements)
- Use the project name in a way that implies official endorsement
  or affiliation
- Use the project name in a domain name for an unofficial project
- Use the logo as your own product's icon or app icon

## Logo Usage Guidelines

- Minimum clear space: equal to the height of the logo mark on all sides
- Minimum size: [specify, e.g., 24px height for digital, 0.5in for print]
- Do not rotate, skew, add effects, or alter the logo
- Use only the official color versions:
  - Full color (for light backgrounds)
  - White (for dark backgrounds)
  - Monochrome (for single-color contexts)
- Logo files are available at: [link to brand assets]

## Questions

For trademark questions or permission requests, contact
[trademark@your-project.org].
```

### Logo usage guidelines

If your project has a logo, provide:

1. **Official logo files** in a `/brand` or `/assets` directory (SVG + PNG at 1x and 2x)
2. **Color specifications** (hex values for primary, secondary, background)
3. **Clear space requirements** (how much padding around the logo)
4. **Minimum size** (smallest acceptable rendering)
5. **Do/don't examples** (correct usage vs. modifications to avoid)

### Trademark in LICENSE and README

Your open source license covers copyright, not trademarks. Add a note in your README:

```markdown
## Trademark

"[PROJECT NAME]" is a trademark of [OWNER]. See [TRADEMARK.md](TRADEMARK.md)
for usage guidelines.
```

Apache 2.0 explicitly states it does not grant trademark rights (Section 6). Other licenses are silent on trademarks. Either way, trademark rights exist independently — the TRADEMARK.md file makes your policy explicit.

---

## Quick reference: what to set up by project stage

| Document / Tool | MVP | Team / Growth | Enterprise / Mature OS |
|---|---|---|---|
| LICENSE file with SPDX text | Yes | Yes | Yes |
| SPDX identifier in package manifest | Yes | Yes | Yes |
| TRADEMARK.md | No | If branded | Yes |
| CLA or DCO | No | DCO if external contributors | CLA if dual licensing, DCO otherwise |
| Dependency license scanning | No | Recommended | Required in CI |
| Privacy Policy | If collecting data | If collecting data | Yes |
| Terms of Service | If SaaS | If SaaS | Yes |
| Cookie Policy | If EU users + cookies | If EU users + cookies | If EU users + cookies |
| DPA | No | If processing customer data | Yes |
| HIPAA BAA | No | If healthcare | If healthcare |
| Accessibility statement | No | If public web app | Yes |
| Export compliance notice | No | If encryption + distribution | Yes |
| SBOM generation | No | No | Yes |
