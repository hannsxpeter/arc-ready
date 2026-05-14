# Trigger disambiguation

arc-ready's tier sub-steps have tight scopes but adjacent triggers overlap. This file maps the most likely confusion cases to the canonical tier sub-step with one-line rationale.

This table uses tier sub-step labels instead of skill names so the routing stays native to arc-ready.

When a user phrase plausibly matches more than one tier sub-step, the agent picks one; this file is the reference for the canonical answer and the disambiguating question to ask if the routing is genuinely ambiguous.

## How to use

User says X. You're not sure which tier sub-step should run. Look up X in the table below or scan the rationale for the closest match. If still ambiguous, ask the user one clarifying question; do not run a five-option meeting.

## The disambiguation table

| User phrase | Canonical tier sub-step | Rationale |
|---|---|---|
| "set up CI" | Tier 2.1 (REPO) | Initial scaffolding (lint+test on PR) is repo hygiene. Add a deploy pipeline on top is Tier 3.1. |
| "CI/CD pipeline" | Tier 3.1 (DEPLOY) | Pipeline that promotes builds is deployment. |
| "GitHub Actions" | Tier 2.1 (REPO) (default) | "Set up GitHub Actions" is scaffolding workflows. If user means promotion pipeline specifically, Tier 3.1. |
| "release automation" | Tier 2.1 (REPO) (default) | Tag-and-release workflow on push is Tier 2.1. Promote-to-prod on tag is Tier 3.1. |
| "SECURITY.md" | Tier 2.1 (REPO) (scaffold) | Scaffolding the file is Tier 2.1. Designing the disclosure program beyond the file is Tier 3.4. |
| "dependency scanning" | Tier 2.1 (REPO) (config) | Scaffold the scanner (Dependabot, Renovate) is Tier 2.1. Adversarial review of the dependency landscape is Tier 3.4. |
| "branch protection" | Tier 2.1 (REPO) (config) | Scaffold the rules is Tier 2.1. Verify they hold against bypass attempts is Tier 3.4. |
| "ADR" | Tier 1.2 (ARCH) (system shape) | System-shape ADRs (monolith vs services, sync vs async, trust boundaries) are Tier 1.2. Tech-pick ADRs (Postgres vs Mongo, Next.js vs Remix) are Tier 1.4. |
| "pick a database" | Tier 1.2 (do we need one) or Tier 1.4 (which one) | Whether to have a DB at all and what shape (relational, document, time-series) is Tier 1.2. Which DB product is Tier 1.4. |
| "trust boundaries" | Tier 1.2 (declare) or Tier 3.4 (verify) | Declare boundaries in architecture is Tier 1.2. Verify they hold in implementation is Tier 3.4. |
| "runbook" | Tier 3.2 (ops) or Tier 3.4 (incident response) | Operational runbooks (alert response, rollback procedure, dashboard interpretation) are Tier 3.2. Incident-response and disclosure runbooks are Tier 3.4. |
| "audit" | Tier 2.1 (hygiene) or Tier 3.4 (security) | Repo-hygiene audit (audit-mode) is Tier 2.1. Security audit is Tier 3.4. |
| "performance" | Tier 2.2 (build fast) or Tier 3.2 (monitor) | Build it fast in the first place is Tier 2.2. Verify it stays fast in prod is Tier 3.2. |
| "make this Tier 2.2" | Tier 2.2 (if dashboard) or Tier 3.4 (if pre-launch) | Skill-name overlap. If user is building a multi-page admin app, Tier 2.2. If they mean "harden it before shipping," Tier 3.4. |
| "we need to launch" | Tier 3.3 (if app exists) or Tier 0 (if greenfield) | App built but not announced is Tier 3.3. "I have an idea, ship it" is Tier 0. |
| "deploy" / "deploy this" | Tier 3.1 (DEPLOY) | Single deploy event is Tier 3.1. |
| "first deploy" | Tier 3.1 (DEPLOY) | First-time deploy ceremony is Tier 3.1. |
| "monitor" / "monitoring" / "alerting" | Tier 3.2 (OBSERVE) | All operational signal-wiring is Tier 3.2. |
| "metrics" / "dashboards (operational)" | Tier 3.2 (OBSERVE) | Operational metrics and ops dashboards are Tier 3.2. App dashboards (Grafana, Honeycomb) are Tier 3.2; product dashboards (admin panel, analytics view) are Tier 2.2. |
| "structured logging" | Tier 3.2 (OBSERVE) | Logging discipline for ops is Tier 3.2. |
| "OpenTelemetry" / "tracing" | Tier 3.2 (OBSERVE) | Distributed tracing is Tier 3.2. |
| "post-mortem" | Tier 3.2 (ops) or Tier 3.4 (security incident) | Generic incident post-mortem is Tier 3.2. Security post-incident hardening is Tier 3.4. |
| "OWASP" / "Top 10" | Tier 3.4 (HARDEN) | OWASP walkthrough is Tier 3.4. |
| "pen test" / "penetration testing" | Tier 3.4 (HARDEN) | Pen-test prep, retest discipline, and finding triage are Tier 3.4. |
| "compliance" / "SOC 2" / "HIPAA" / "PCI-DSS" / "GDPR" | Tier 3.4 (HARDEN) | All compliance mapping with control-to-code evidence is Tier 3.4. |
| "responsible disclosure" / "bug bounty" | Tier 3.4 (HARDEN) | Disclosure program design beyond `SECURITY.md` is Tier 3.4. |
| "system diagram" / "C4" / "arc42" | Tier 1.2 (ARCH) | All system-shape diagrams are Tier 1.2. |
| "service boundaries" / "monolith vs microservices" | Tier 1.2 (ARCH) | All boundary decisions are Tier 1.2. |
| "what stack" / "which framework" / "which DB" | Tier 1.4 (STACK) | Tech-pick is Tier 1.4. |
| "Next.js vs. Remix" / "Postgres vs Mongo" | Tier 1.4 (STACK) | Comparison shopping is Tier 1.4. |
| "PRD" / "product spec" / "requirements doc" / "one-pager" | Tier 1.1 (PRD) | All product-definition docs are Tier 1.1. |
| "build a roadmap" / "milestone plan" / "Now-Next-Later" | Tier 1.3 (ROADMAP) | Sequencing work over time is Tier 1.3. |
| "set up the repo" / "initialize the project" / "add README" | Tier 2.1 (REPO) | All repo-hygiene scaffolding is Tier 2.1. |
| "dashboard" / "admin panel" / "internal tool" / "back office" | Tier 2.2 (PRODUCTION) | All dashboard-class apps are Tier 2.2. |
| "build the app" | Tier 2.2 (if dashboard) | Default is Tier 2.2. If user means scaffolding from scratch, Tier 2.1 first then Tier 2.2. |
| "landing page" / "marketing site" | Tier 3.3 (LAUNCH) | Marketing landing is Tier 3.3 (Tier 2.2 explicitly excludes marketing sites). |
| "Product Hunt" / "Show HN" / "Reddit launch" | Tier 3.3 (LAUNCH) | Launch channels are Tier 3.3. |
| "waitlist" / "OG card" / "press kit" | Tier 3.3 (LAUNCH) | Launch artifacts are Tier 3.3. |
| "kickoff" / "new project from scratch" / "I have an idea" | Tier 0 (orchestration) | Greenfield orchestration from raw user intent is Tier 0. |
| "constitution.md" | (none) | arc-ready does not own a `constitution.md` equivalent. That slot belongs to Spec Kit; arc-ready treats it as project-root context when present. See ORCHESTRATORS.md Pattern: Spec Kit. |
| "AGENTS.md" / "CLAUDE.md" | Tier 2.1 (scaffold) or Tier 0 (post-arc emit) | Project-conventions agent brief is Tier 2.1. arc-ready artifact-map emit when none exists is Tier 0 Step 0.6. |
| "DESIGN.md" | Tier 2.2 (consume) | Detect and consume the Google Labs DESIGN.md format in Step 3 sub-step 3a is Tier 2.2. |

## When to fall back to the user

If a phrase is ambiguous and the rationale above does not disambiguate cleanly, ask one short clarifying question with two options. Examples:

- "Set up CI" -> "Just scaffold lint+test on PR (Tier 2.1), or also wire promote-to-prod (Tier 3.1)?"
- "We need to launch" -> "Do you have an app already, or are you starting from idea?"
- "Audit the project" -> "Repo hygiene (Tier 2.1 audit-mode), or security (Tier 3.4)?"
- "Performance work" -> "Build it fast (Tier 2.2), or monitor it stays fast (Tier 3.2)?"
- "Make this Tier 2.2" -> "Build the dashboard (Tier 2.2), or harden before launch (Tier 3.4)?"

One question, two options. Do not list five.

## When the harness routes wrong

The user is the final authority. If a harness or orchestrator routes to sub-step X but Y is correct, the user invokes Y by name explicitly. arc-ready tier sub-steps are addressable directly; nothing requires going through an orchestrator's router.

## Out-of-scope phrases

These look like arc-ready triggers but are NOT. Route elsewhere:

| User phrase | Why not arc-ready |
|---|---|
| "fix this bug" | Generic debugging, not an arc-ready tier. Use the harness's general agent. |
| "refactor this module" | Not an arc-ready tier. Use the harness's general agent. |
| "write tests" (alone) | Generic testing. arc-ready tiers include testing within their tier verification, but a standalone "add tests" request routes to general agent. |
| "translate to Spanish" | Not in scope. |
| "explain this code" | Generic code explanation, not an arc-ready tier. |
| "debug a memory leak" | Not in scope. |
| "write a blog post" | Not in scope (Tier 3.3 writes launch-day copy, not ongoing content). |
| "pick a logo" | Not in scope. |

## How this file is maintained

When a new ambiguity case is observed (the agent or a user surfaces a phrase that plausibly fits two or more tier sub-steps), this file gets a new row.

The grep test for completeness: every row's "User phrase" column should be either a direct trigger phrase from arc-ready's `description` frontmatter, or a synonym a real user is likely to type. Phrases that match exactly one tier sub-step's triggers and have no plausible cross-tier confusion do not need a row here; rows exist for ambiguity, not for documentation.

## See also

- `../shared/ORCHESTRATORS.md`: cross-orchestrator composition with GSD, BMAD, Spec Kit, Superpowers, plain harnesses.
- `../../README.md`: the four-tier diagram and the install entry point.
- arc-ready's `SKILL.md`: the workflow body. Each tier sub-step's triggers are in the `description:` frontmatter and in the README's trigger surface.
