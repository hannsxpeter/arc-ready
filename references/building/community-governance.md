# Community, Governance, Funding, and Lifecycle

Reference for community management files, governance structures, funding configuration, contributor recognition, and repository lifecycle management. Use this when a project has outgrown single-maintainer mode or needs formal community infrastructure.

---

## When to add what

Not every project needs governance. Match community infrastructure to project reality:

| Signal | What to add |
|---|---|
| Solo maintainer, <10 stars | Nothing beyond README and LICENSE |
| 3+ regular contributors | MAINTAINERS file, basic governance statement |
| 10+ contributors, external PRs | GOVERNANCE.md, GitHub Discussions, contributor recognition |
| Corporate users or dependencies | GOVERNANCE.md (formal model), FUNDING.yml, SECURITY.md |
| Foundation-hosted or multi-org | Full governance charter, steering committee, RFC process |
| Project winding down | Deprecation notices, archive flag, successor links |

Adding governance too early signals a project that cares more about process than code. Adding it too late creates ambiguity about who decides what.

---

## 1. GOVERNANCE.md

### When to create

Create GOVERNANCE.md when a project has 3+ regular contributors and decisions can no longer be made by a single person saying "I'll just merge it." The file answers one question: "Who decides, and how?"

### Governance models

Pick one. Do not hybridize until you have a reason.

**BDFL (Benevolent Dictator for Life)** -- Best for projects with a clear creator/visionary. Most small-to-medium open source projects. The BDFL has final say on all decisions. Contributors can propose and discuss, but one person breaks ties.

**Consensus** -- Best for small teams (3-7 people) with high trust. Decisions require agreement from all active maintainers. If consensus cannot be reached, a fallback mechanism (usually a vote) resolves it.

**Meritocratic** -- Best for projects with a clear contribution ladder. Influence is earned through sustained, quality contributions. Common in Apache-style projects. Roles are formally defined with explicit promotion criteria.

**Foundation/Committee** -- Best for projects that are critical infrastructure or have corporate sponsors. A steering committee or board makes strategic decisions. Technical decisions are delegated to maintainers. Used by Kubernetes, Node.js, Rust.

### Full GOVERNANCE.md template (BDFL model)

```markdown
# Governance

## Overview

[Project Name] follows a Benevolent Dictator for Life (BDFL) governance model. This document describes how decisions are made, how contributors can grow their involvement, and how the governance model itself can evolve.

## Roles

### BDFL (Project Lead)

**Current:** [Name] ([@handle](https://github.com/handle))

The BDFL has final authority on all project decisions, including:

- Technical direction and architecture
- Release timing and versioning
- Accepting or rejecting contributions
- Appointing and removing maintainers
- Modifying this governance document

The BDFL is expected to:

- Act in the best interest of the project and its users
- Seek input from maintainers and the community before major decisions
- Provide clear reasoning when overriding community consensus
- Delegate day-to-day decisions to maintainers

### Maintainers

Maintainers have write access to the repository and are responsible for:

- Reviewing and merging pull requests in their area of ownership
- Triaging issues
- Participating in release processes
- Mentoring contributors

Maintainers are appointed by the BDFL based on sustained, quality contributions. See the [MAINTAINERS](MAINTAINERS) file for the current list.

**Becoming a maintainer:** There is no fixed threshold. Typically, a contributor who has made significant contributions over 3+ months, demonstrates good judgment in reviews, and is trusted by existing maintainers will be invited. The BDFL makes the final decision.

### Contributors

Anyone who has had a pull request merged. Contributors are recognized in the README and the [contributors list](.all-contributorsrc).

### Community Members

Anyone who uses the project, files issues, participates in discussions, or helps others. Community members are valued and their input shapes the project's direction.

## Decision-Making Process

1. **Day-to-day decisions** (bug fixes, small features, documentation) -- Maintainers decide. Any maintainer can merge a PR in their area after review.
2. **Significant changes** (new features, API changes, dependency additions) -- Discussed in a GitHub issue or Discussion. Maintainers provide input. The relevant area maintainer decides, or escalates to the BDFL.
3. **Major decisions** (architecture changes, breaking changes, governance changes) -- Discussed publicly for at least 7 days. The BDFL decides after considering community input.
4. **Disputes** -- If maintainers disagree, the BDFL makes the final call.

## Changing This Governance

This governance model can be changed by the BDFL. Any changes will be:

- Discussed publicly for at least 14 days
- Announced in a GitHub Discussion
- Documented in the changelog

If the project outgrows the BDFL model, the BDFL is expected to transition to a consensus or committee model and document the new structure here.

## BDFL Succession

If the BDFL is unable or unwilling to continue:

1. The BDFL appoints a successor (documented in this file).
2. If no successor is appointed, active maintainers vote to select a new BDFL or transition to a committee model.
3. If no active maintainers remain, the project enters maintenance mode (security fixes only) until a new maintainer steps up.

## Code of Conduct

All participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
```

### Full GOVERNANCE.md template (Consensus model)

```markdown
# Governance

## Overview

[Project Name] is governed by consensus among its active maintainers. This document describes roles, decision-making processes, and how governance evolves.

## Roles

### Maintainers

Active maintainers collectively govern the project. Responsibilities:

- Review and merge pull requests
- Triage issues and discussions
- Participate in decision-making
- Mentor contributors toward maintainership

The current maintainer list is in [MAINTAINERS](MAINTAINERS).

### Contributors

Anyone who has had a contribution accepted (code, documentation, design, or other).

## Decision-Making

### Lazy Consensus

Most decisions use lazy consensus:

1. A proposal is made via issue, pull request, or Discussion.
2. Maintainers have 72 hours to object.
3. If no maintainer objects, the proposal is accepted.
4. Silence is consent. Explicit approval is welcome but not required.

### Active Consensus

Significant decisions require active consensus:

- Breaking API changes
- New runtime dependencies
- Changes to governance
- Removing a maintainer

Process:

1. A proposal is posted as a GitHub Discussion (category: Announcements).
2. Discussion period: minimum 7 days.
3. All active maintainers must participate (approve, object, or abstain).
4. Approval requires agreement from at least 2/3 of active maintainers.
5. Any maintainer can request an extension of the discussion period.

### Deadlock Resolution

If consensus cannot be reached after two rounds of discussion:

1. The proposal is tabled for 30 days.
2. After 30 days, a simple majority vote among active maintainers decides.
3. In case of a tie, the most senior active maintainer (by tenure) casts the deciding vote.

## Becoming a Maintainer

1. Contributor demonstrates sustained engagement (typically 6+ months).
2. Any active maintainer can nominate them.
3. Existing maintainers discuss privately.
4. Approval requires consensus (no objections within 7 days).
5. New maintainer is announced in a Discussion post.

## Removing a Maintainer

A maintainer is moved to emeritus status when:

- They request it.
- They have been inactive for 12+ months with no response to a check-in.
- Active consensus determines they should be removed (requires 2/3 agreement).

Emeritus maintainers retain recognition but lose write access and voting rights. They can return to active status through the standard nomination process.

## Code of Conduct

All participants must follow the [Code of Conduct](CODE_OF_CONDUCT.md).
```

### Full GOVERNANCE.md template (Meritocratic model)

```markdown
# Governance

## Overview

[Project Name] follows a meritocratic governance model. Influence and responsibility are earned through sustained, quality contributions. This document defines the contribution ladder and decision-making processes.

## Contribution Ladder

### 1. Community Member

Anyone who uses the project or participates in discussions.

**Responsibilities:** Follow the Code of Conduct.
**Rights:** File issues, participate in discussions, submit pull requests.

### 2. Contributor

A community member who has had at least one contribution accepted.

**Responsibilities:** Follow contribution guidelines, respond to feedback on their PRs.
**Rights:** Listed in contributors, can be assigned issues.

### 3. Committer

A contributor who has demonstrated reliability, good judgment, and deep knowledge of a project area.

**Responsibilities:**
- Review pull requests in their area
- Triage issues
- Maintain documentation for their area
- Mentor contributors

**Rights:**
- Write access to the repository (scoped via CODEOWNERS where possible)
- Vote on standard decisions

**Path to committer:**
- 10+ accepted contributions over 3+ months
- Demonstrated understanding of project conventions
- Nominated by an existing committer, approved by maintainers

### 4. Maintainer

A committer who takes responsibility for the project's overall health.

**Responsibilities:**
- Set technical direction
- Manage releases
- Resolve disputes between committers
- Ensure project sustainability

**Rights:**
- Admin access to the repository
- Vote on all decisions including governance changes
- Appoint and remove committers

**Path to maintainer:**
- 6+ months as an active committer
- Demonstrated leadership and architectural judgment
- Nominated by an existing maintainer, approved by all other maintainers

### 5. Emeritus

Former committers or maintainers who are no longer active. Retain recognition and honorary title but no access or voting rights. Can return through the standard promotion process.

## Decision-Making

| Decision type | Who decides | Process |
|---|---|---|
| Bug fixes, docs, small changes | Any committer | Merge after one review |
| New features, refactors | Committers in the area | Lazy consensus (72h) |
| API changes, new dependencies | All committers | Active consensus (7 days, 2/3 approval) |
| Governance, releases, removals | Maintainers | Active consensus (14 days, unanimous) |

## Code of Conduct

All participants must follow the [Code of Conduct](CODE_OF_CONDUCT.md).
```

### Foundation/Committee model -- key additions

For foundation-hosted projects, add these sections to whichever base template fits:

```markdown
## Steering Committee

The Steering Committee provides strategic direction. It does not make day-to-day technical decisions.

### Composition

- [N] seats total
- [N] elected by active contributors (annual election)
- [N] appointed by sponsoring organizations
- [N] maintainer representatives (selected by maintainers)

### Responsibilities

- Project roadmap and long-term vision
- Budget allocation (if applicable)
- Trademark and brand decisions
- Conflict resolution (appeals from maintainer decisions)
- Liaising with the host foundation

### Meetings

- Monthly public meetings (notes published within 48 hours)
- Quarterly roadmap reviews
- Annual contributor summit

### Elections

- Eligible voters: anyone with 5+ contributions in the past 12 months
- Nomination period: 14 days
- Voting period: 7 days
- Method: Condorcet/ranked-choice voting via [platform]
- Term: 2 years, staggered (half the seats elected each year)

## Technical Steering Committee (TSC)

For projects that separate strategic and technical governance:

- Composed of senior maintainers
- Makes binding technical decisions
- Owns the RFC process
- Reports to the Steering Committee on technical matters
```

---

## 2. MAINTAINERS file

### Format

Use a structured plaintext format. Avoid YAML/JSON -- a human should be able to read this at a glance.

### Full MAINTAINERS template

```markdown
# Maintainers

This file lists the maintainers of [Project Name] and their areas of responsibility.

## Active Maintainers

| Name | GitHub | Area | Since |
|---|---|---|---|
| Jane Smith | [@jsmith](https://github.com/jsmith) | Project Lead / Overall | 2022-01 |
| Alex Chen | [@achen](https://github.com/achen) | Core Engine / Performance | 2022-06 |
| Maria Garcia | [@mgarcia](https://github.com/mgarcia) | API / Documentation | 2023-03 |
| David Kim | [@dkim](https://github.com/dkim) | CI/CD / Release Process | 2023-09 |

## Emeritus Maintainers

These individuals made significant contributions but are no longer actively maintaining the project. We are grateful for their work.

| Name | GitHub | Area | Active Period |
|---|---|---|---|
| Bob Johnson | [@bjohnson](https://github.com/bjohnson) | CLI / Testing | 2021-03 to 2023-12 |

## Becoming a Maintainer

See [GOVERNANCE.md](GOVERNANCE.md) for the process of becoming a maintainer.

## Maintainer Responsibilities

- Respond to issues and PRs in your area within 5 business days
- Participate in release planning
- Review at least 2 PRs per week from outside contributors
- Attend the monthly maintainer sync (or send async updates)
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md)

## Succession Planning

If all active maintainers become inactive:

1. Emeritus maintainers are contacted and invited to return.
2. Top 3 contributors (by recent activity) are invited to become maintainers.
3. If no one steps up within 90 days, the project is archived with a notice in the README.

The project lead maintains a private succession document with:

- Access credentials and secrets inventory (CI tokens, npm publish, etc.)
- Critical contacts (hosting, domain registrar, foundation)
- Instructions for emergency releases (security patches)
```

### Relationship with CODEOWNERS

MAINTAINERS is for humans. CODEOWNERS is for GitHub's automated review assignment. Keep them in sync:

```
# CODEOWNERS -- auto-generated from MAINTAINERS, do not edit directly
# See MAINTAINERS for roles and contact info

* @jsmith
/src/engine/ @achen
/src/api/ @mgarcia
/docs/ @mgarcia
/.github/ @dkim
/scripts/ @dkim
```

---

## 3. GitHub Discussions setup

### When to enable

Enable Discussions when issues are being used for questions, feature brainstorming, or general conversation. Issues are for actionable work. Discussions are for everything else.

### Category configuration

Set up these categories in repository Settings > Discussions:

| Category | Format | Who can post | Purpose | Emoji |
|---|---|---|---|---|
| **Announcements** | Announcement | Maintainers only | Releases, breaking changes, governance decisions | :loudspeaker: |
| **Q&A** | Question/Answer | Anyone | Support questions with markable answers | :raising_hand: |
| **Ideas** | Open | Anyone | Feature proposals, upvoteable | :bulb: |
| **Show and Tell** | Open | Anyone | Projects built with the library, demos | :star2: |
| **General** | Open | Anyone | Everything else | :speech_balloon: |
| **RFCs** | Open | Anyone (if project uses RFCs) | Formal proposals for significant changes | :scroll: |

### Pinned discussions

Pin these immediately after enabling:

1. **Welcome** -- Project overview, links to docs, how to ask good questions, link to Code of Conduct.
2. **Roadmap / What's next** -- Current priorities. Update quarterly.
3. **FAQ** -- Common questions pulled from issues. Link to docs where possible.

### Converting between issues and discussions

**Issue to Discussion:** When an issue is actually a question or feature brainstorm, not actionable work. Use the "Convert to discussion" button in the issue sidebar. Choose the right category. Leave a comment explaining why before converting.

**Discussion to Issue:** When a Discussion produces an actionable outcome. Create the issue manually (reference the Discussion), then lock the Discussion with a comment linking to the new issue.

### Discussion templates

Create `.github/DISCUSSION_TEMPLATE/` for structured discussions:

```yaml
# .github/DISCUSSION_TEMPLATE/ideas.yml
title: "[Idea] "
labels: []
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting an improvement! Please fill out the sections below.
  - type: textarea
    id: problem
    attributes:
      label: Problem or motivation
      description: What problem does this solve? Why should we consider it?
    validations:
      required: true
  - type: textarea
    id: proposal
    attributes:
      label: Proposed solution
      description: How would this work? Include examples if possible.
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
      description: What other approaches did you consider?
    validations:
      required: false
```

---

## 4. Community channels

### Linking strategy

Every external channel must be linked from two places: the README and SUPPORT.md. If a channel exists but is not linked, it does not exist for new users.

### Discord server setup

Discord is the most common choice for real-time community chat. Setup:

1. Create a server with the project name.
2. Set up these channels:

```
INFORMATION
  #welcome          -- Rules, CoC link, getting started
  #announcements    -- Releases, breaking changes (maintainers only)
  #faq              -- Pinned common questions

COMMUNITY
  #general          -- Open chat
  #help             -- Support questions
  #show-and-tell    -- Share what you built

DEVELOPMENT
  #contributing     -- Contributor discussion
  #maintainers      -- Private, maintainers only

VOICE
  #office-hours     -- Scheduled community calls
```

3. Set up a bot to cross-post GitHub releases to `#announcements`.
4. Add a link to the GitHub repository in the server description.
5. Use Discord's Community features for server insights.

### Slack workspace

Slack works for projects with corporate users. Same channel structure as Discord. Add a self-signup link via Slack Connect or a community Slack bot.

### Matrix rooms

Matrix is preferred by privacy-conscious communities. Use Element as the reference client. Create a Space for the project with rooms mirroring the Discord structure. Bridge to Discord if you run both.

### Linking from README

Add a community section to README.md:

```markdown
## Community

- [GitHub Discussions](https://github.com/org/project/discussions) -- Questions, ideas, and general discussion
- [Discord](https://discord.gg/invite-code) -- Real-time chat with the community
- [Twitter/X](https://twitter.com/project) -- Announcements and updates
```

### SUPPORT.md reference

```markdown
# Support

## How to Get Help

| Channel | Best for | Response time |
|---|---|---|
| [GitHub Discussions Q&A](link) | Usage questions, troubleshooting | 1-3 days |
| [Discord #help](link) | Quick questions, real-time chat | Hours (community-driven) |
| [GitHub Issues](link) | Bug reports and confirmed feature requests | 1-5 days |
| [Stack Overflow](link) | Questions with broader relevance | Community-driven |

## What NOT to do

- Do not open GitHub issues for support questions. They will be converted to Discussions.
- Do not DM maintainers for support. Use public channels so others can benefit.
- Do not use the security reporting email for general bugs. See [SECURITY.md](SECURITY.md).

## Commercial Support

[If applicable: link to paid support options, consulting, or enterprise tier]
```

---

## 5. Funding and sponsorship

### FUNDING.yml

Place in `.github/FUNDING.yml`. GitHub renders this as a "Sponsor" button on the repository.

```yaml
# .github/FUNDING.yml
#
# Each key accepts a username/URL. Remove or comment out platforms you don't use.
# GitHub renders up to 4 platforms plus a custom URL.

# GitHub Sponsors -- preferred, zero fees, direct integration
github: [username]
# github: [username1, username2]  # multiple maintainers

# Open Collective -- good for projects with expenses (hosting, events)
open_collective: project-name

# Patreon -- good for ongoing content creation alongside code
patreon: username

# Ko-fi -- simpler alternative to Patreon, one-time and recurring
ko_fi: username

# Polar -- open source-native, issue-based funding
polar: org-name

# Buy Me a Coffee
# buy_me_a_coffee: username

# Liberapay -- privacy-focused, Europe-based
# liberapay: username

# IssueHunt -- bounty-based funding per issue
# issuehunt: username

# LFX Crowdfunding (Linux Foundation)
# lfx_crowdfunding: project-name

# Community Bridge (deprecated, use LFX)
# community_bridge: project-name

# Tidelift -- enterprise subscription model
# tidelift: platform-name/package-name

# Custom URL -- your own donation page, OpenCollective project, etc.
custom: ["https://example.com/donate"]
```

### When to add funding

Add FUNDING.yml when:

- The project has users who depend on it (not just stars).
- Maintenance requires real time (10+ hours/month).
- There are hosting, infrastructure, or event costs.
- You want to signal that the project is actively maintained and welcomes support.

Do NOT add funding to a project that is a weekend experiment, abandoned, or corporate-sponsored (unless the corporation explicitly supports external funding).

### README funding messaging

Be direct but not desperate. One line, one link, end of the relevant section:

**Good:**

```markdown
## Support This Project

If [Project Name] saves you time, consider [sponsoring the maintainers](link).
Your support helps us keep the project maintained and free for everyone.
```

**Also good (minimal):**

```markdown
---

[Project Name] is maintained by volunteers.
[Become a sponsor](link) to support continued development.
```

**Bad (too aggressive):**

```markdown
## PLEASE DONATE!!!

This project is maintained by ONE PERSON who spends 40 HOURS A WEEK on it
for FREE. Without your donations, this project WILL DIE. Please consider...
```

**Bad (guilt-tripping):**

```markdown
## Funding

Despite being used by Fortune 500 companies, this project receives $0
in funding. If you use this in production, the least you can do is...
```

---

## 6. Contributor recognition

### AllContributors specification

The [AllContributors](https://allcontributors.org) spec recognizes contributions beyond code. Set it up with the bot for automated management.

### Bot setup

1. Install the AllContributors GitHub App on the repository.
2. Initialize the config:

```json
// .all-contributorsrc
{
  "projectName": "project-name",
  "projectOwner": "org-name",
  "repoType": "github",
  "repoHost": "https://github.com",
  "files": ["README.md"],
  "imageSize": 80,
  "commit": true,
  "commitConvention": "angular",
  "contributors": [],
  "contributorsPerLine": 7
}
```

3. Add the placeholder in README.md where the table will be injected:

```markdown
## Contributors

Thanks to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of every kind are welcome!
```

4. Add contributors by commenting on any issue or PR:

```
@all-contributors please add @username for code, docs
```

### Contribution types

Recognize all forms of contribution, not just code:

| Type | Emoji | Description |
|---|---|---|
| `code` | :computer: | Code contributions |
| `doc` | :book: | Documentation |
| `design` | :art: | Design / UX |
| `ideas` | :bulb: | Ideas and planning |
| `review` | :eyes: | Reviewing pull requests |
| `test` | :warning: | Writing tests |
| `bug` | :bug: | Bug reports |
| `mentoring` | :mortar_board: | Mentoring new contributors |
| `infra` | :wrench: | Infrastructure (CI, hosting, etc.) |
| `maintenance` | :hammer: | Maintenance and refactoring |
| `tutorial` | :pencil: | Tutorials and examples |
| `talk` | :loudspeaker: | Talks and presentations |
| `translation` | :globe_with_meridians: | Translation |
| `question` | :grey_question: | Answering questions in issues/discussions |
| `financial` | :dollar: | Financial support |
| `security` | :lock: | Security reports and fixes |
| `a11y` | :wheelchair: | Accessibility improvements |

### Alternative: manual contributors section

If the AllContributors bot is too heavy, maintain a simple list:

```markdown
## Contributors

This project exists thanks to everyone who contributes.

**Maintainers:** [@jsmith](link), [@achen](link)

**Key contributors:** [@contributor1](link) (docs), [@contributor2](link) (testing),
[@contributor3](link) (design)

See the full list of [contributors on GitHub](https://github.com/org/project/graphs/contributors).

Special thanks to [@user](link) for the original idea, [@user2](link) for the logo,
and everyone who has filed issues and helped others in Discussions.
```

---

## 7. Deprecation and archival

### When to deprecate

Deprecate a project when:

- A better alternative exists (including your own successor project).
- The underlying platform/language/framework is no longer supported.
- No maintainer has capacity or interest to continue.
- The project's purpose is no longer relevant.

Do not deprecate silently. Users deserve clear notice and migration paths.

### Deprecation sequence

Follow this order. Each step has a specific purpose.

#### Step 1: README deprecation banner

Add this at the very top of README.md, before everything else:

```markdown
> [!CAUTION]
> **This project is deprecated and no longer maintained.**
>
> We recommend migrating to [Successor Project](https://github.com/org/successor).
> See the [migration guide](link-to-guide) for instructions.
>
> No new features will be added. Security issues will not be fixed.
> The repository will be archived on [DATE].
```

If there is no successor:

```markdown
> [!CAUTION]
> **This project is deprecated and no longer maintained.**
>
> No new features will be added and security issues will not be fixed.
> The repository will be archived on [DATE].
>
> **Alternatives:** [Alt1](link), [Alt2](link), [Alt3](link)
```

#### Step 2: Final release with deprecation notice

Cut a final release that:

- Includes the deprecation notice in release notes.
- Logs a deprecation warning at runtime (if the project is a library):

```javascript
// JavaScript -- log once on import
if (typeof console !== 'undefined') {
  console.warn(
    '[project-name] This package is deprecated. Migrate to "successor-package". ' +
    'See https://github.com/org/project#deprecated for details.'
  );
}
```

```python
# Python -- log once on import
import warnings
warnings.warn(
    "project-name is deprecated. Migrate to successor-package. "
    "See https://github.com/org/project#deprecated for details.",
    DeprecationWarning,
    stacklevel=2,
)
```

#### Step 3: Package registry deprecation

**npm:**

```bash
# Deprecate all versions
npm deprecate "package-name" "This package is deprecated. Use successor-package instead. See https://github.com/org/project"

# Deprecate specific versions
npm deprecate "package-name@<2.0.0" "Upgrade to 2.x or migrate to successor-package"
```

**PyPI:**

```bash
# Yank a specific version (removes from default install, still accessible by version)
# Note: PyPI does not have a project-level deprecate. Use the final release description
# and a setup.py classifier instead.

# In setup.py or pyproject.toml, add:
# classifiers = ["Development Status :: 7 - Inactive"]
```

**crates.io (Rust):**

```bash
cargo yank --version 1.2.3
```

**Go modules:**

```go
// Add to go.mod of the deprecated module:
// Deprecated: use github.com/org/successor instead.
module github.com/org/project
```

#### Step 4: Update SECURITY.md

```markdown
# Security Policy

## Deprecated Project

This project is deprecated and no longer maintained. **No versions are supported.**

Security vulnerabilities will not be fixed. If you are still using this project,
migrate to [Successor Project](link) immediately.

Do not report security issues to this repository. Report issues affecting the
successor project to [their security policy](link).
```

#### Step 5: Close and lock issues

1. Close all open issues with a comment explaining the deprecation.
2. Close all open PRs with a comment thanking the contributor and explaining the deprecation.
3. Lock the repository to prevent new issues (Settings > Moderation > Interaction limits).

#### Step 6: GitHub archive flag

Go to Settings > General > Danger Zone > Archive this repository.

This makes the repository read-only:

- No new issues, PRs, comments, or pushes.
- The repository remains visible and cloneable.
- A banner appears at the top: "This repository has been archived by the owner."

**Do this last.** Once archived, you cannot make changes without un-archiving.

#### Step 7: Redirect to successor (if applicable)

If you control the successor project, add a note in its README:

```markdown
> **Migrating from [old-project]?** See the [migration guide](link).
```

If the old project was an npm package and you want installs to redirect:

```bash
# Publish a final version that is just a wrapper around the successor
npm deprecate "old-package" "Moved to new-package. See migration guide: <url>"
```

---

## 8. Repository lifecycle

### Lifecycle stages

Every repository passes through these stages. What you do at each stage determines whether the project thrives or becomes abandonware.

```
Creation --> Setup --> Active Development --> Maintenance --> Deprecation --> Archive
```

### What to do at each stage

#### Creation

The repository exists but has no users.

**Actions:**
- README with project description, installation, and basic usage
- LICENSE file (choose before writing code -- changing later is painful)
- .gitignore appropriate for the stack
- Initial CI (linting and tests, even if there is only one test)

**Do not add:** GOVERNANCE.md, FUNDING.yml, elaborate issue templates, CoC (unless required by the hosting org). These create the impression of a mature project that is actually empty.

#### Setup (0-6 months)

First users and contributors appear.

**Actions:**
- Flesh out README with real examples, API docs, troubleshooting
- Add CONTRIBUTING.md with actual workflow (not a template)
- Add CODE_OF_CONDUCT.md if the project has any community interaction
- Set up semantic versioning and CHANGELOG
- Create issue templates for bugs and features
- Add PR template
- Configure branch protection on main

**Milestone:** When a stranger can go from "what is this?" to "I submitted a PR" using only the repository's documentation, setup is complete.

#### Active Development

Regular releases, growing contributor base, users in production.

**Actions:**
- Add SECURITY.md with supported versions and reporting process
- Add MAINTAINERS file (once 2+ people have merge access)
- Add GOVERNANCE.md (once 3+ regular contributors)
- Enable GitHub Discussions (once issues are being used for non-actionable conversations)
- Set up FUNDING.yml (if maintenance requires significant time)
- Add AllContributors or equivalent recognition
- Set up community channels (Discord/Slack) if demand exists
- Implement release automation (changelog generation, publishing)
- Add CODEOWNERS for automated review routing
- Consider ADRs (Architecture Decision Records) for significant decisions

**Milestone:** When a maintainer can take a 2-week vacation and the project continues functioning (issues triaged, PRs reviewed, questions answered), active development infrastructure is adequate.

#### Maintenance Mode

The project is stable. No major new features planned. Bug fixes and security patches only.

**Actions:**
- Update README to indicate maintenance status: "This project is in maintenance mode. Bug fixes and security patches are accepted. New features are unlikely to be merged."
- Reduce CI scope if needed (drop nightly builds, reduce matrix)
- Set expectations on response times in SUPPORT.md
- Keep dependencies updated (Dependabot/Renovate)
- Consider finding new maintainers if current ones are burning out

**Milestone:** The project is honest about its status and users know what to expect.

#### Deprecation

The project is being wound down. See Section 7 for the full deprecation sequence.

**Actions:** Follow the deprecation sequence above in order.

#### Archive

The project is read-only. No further action needed.

The repository remains available as a reference. Code can still be cloned and forked. Stars and links continue to work. GitHub shows the archived banner automatically.

### Transfer of ownership

When a maintainer leaves or an organization wants to adopt a project:

#### Individual to individual

1. New maintainer is added with admin access.
2. Old maintainer transfers the repository (Settings > Danger Zone > Transfer ownership).
3. GitHub creates a redirect from the old URL (redirects last indefinitely but can break with certain operations).
4. Update npm/PyPI/crates.io package ownership.
5. Transfer domain names if applicable.
6. Update MAINTAINERS and GOVERNANCE.md.
7. New maintainer rotates all secrets and tokens.

#### Individual to organization

1. Create the organization on GitHub.
2. Transfer the repository to the org.
3. Set up team permissions.
4. Update all references to the old namespace.
5. Update package registry ownership.
6. Announce the transfer in a Discussion/blog post.

#### Organization to foundation

1. Confirm intellectual property assignment or licensing.
2. Transfer repository to foundation's GitHub org.
3. Adopt foundation's governance model.
4. Set up CLA (Contributor License Agreement) if required.
5. Update GOVERNANCE.md with foundation-specific structure.
6. Transfer trademarks if applicable.
7. Announce via blog post and mailing lists.

#### Checklist for any ownership transfer

```markdown
- [ ] Repository transferred on GitHub
- [ ] All CI/CD secrets rotated and updated
- [ ] Package registry ownership updated (npm, PyPI, crates.io, etc.)
- [ ] Domain and DNS records transferred
- [ ] Social media accounts transferred or redirected
- [ ] MAINTAINERS file updated
- [ ] GOVERNANCE.md updated
- [ ] README updated with new links/org name
- [ ] Announcement posted to community channels
- [ ] Old URL redirect verified
- [ ] Bot accounts and integrations re-authorized
- [ ] Sponsor/funding links updated
```

---

## Quick reference: file placement

| File | Location | Required by |
|---|---|---|
| `GOVERNANCE.md` | Repository root | Projects with 3+ contributors |
| `MAINTAINERS` | Repository root | Projects with 2+ people with merge access |
| `.github/FUNDING.yml` | `.github/` | Any project seeking financial support |
| `.all-contributorsrc` | Repository root | Projects using AllContributors |
| `.github/DISCUSSION_TEMPLATE/` | `.github/` | Projects with GitHub Discussions |
| `SUPPORT.md` | Repository root | GitHub renders this in issue creation flow |
| `CODEOWNERS` | Repository root, `docs/`, or `.github/` | Projects with area-specific reviewers |
