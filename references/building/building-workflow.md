# Building Workflow

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

### Tier 2: Building

The building tier produces a scaffolded repository and an end-to-end-wired application. Sequential by default: repo first, then app.

#### Step 2.1. Repo scaffolding: production-grade repository structure, docs, CI/CD, quality tooling

Load `references/building/questioning.md` for the pre-flight question protocol. Then load `references/building/project-profiles.md` for the project-type x stage x audience matrix.

Sub-steps:

1. **Stack detection.** Read existing files to detect the stack. If stack-ready ran (Step 1.4), consume `.stack-ready/STACK.md`. If not, run a detection pass per the existing-codebase mode.
2. **Project profile.** Type (CLI, library, app, API, monorepo, etc.) x stage (prototype, beta, production) x audience (internal, OSS, commercial). Determines which files are scaffolded.
3. **Repo structure.** Standard top-level layout for the chosen stack. Load `references/building/repo-structure.md`.
4. **README.** Adapted to project type and audience. Load `references/building/readme-craft.md`.
5. **Community standards.** LICENSE, CODE_OF_CONDUCT, CONTRIBUTING, SECURITY. Load `references/building/community-standards.md` and `references/building/community-governance.md`.
6. **Technical docs.** ARCHITECTURE, DECISIONS (ADR), DEVELOPMENT, RELEASE. Load `references/building/technical-docs.md`.
7. **CI/CD.** Build, test, lint, security-scan workflows. Platform-specific: load `references/building/platform-github.md`, `references/building/platform-gitlab.md`, or `references/building/platform-bitbucket.md`. Load `references/building/ci-cd-workflows.md`.
8. **Quality tooling.** Linter, formatter, test runner, type checker, pre-commit hooks. Load `references/building/quality-tooling.md`.
9. **Git workflows.** Branching strategy, commit conventions, PR template, merge policy. Load `references/building/git-workflows.md`.
10. **Licensing and legal.** License selection, third-party-attribution policy, trademark notes. Load `references/building/licensing-legal.md`.
11. **Security setup.** Dependabot/Renovate, secret scanning, branch protection, signed commits. Load `references/building/security-setup.md`.
12. **Onboarding DX.** First-run experience, dev container, devbox, codespace, Makefile. Load `references/building/onboarding-dx.md`.
13. **Release distribution.** Versioning, tagging, release-notes generation, package publishing. Load `references/building/release-distribution.md`.
14. **AGENTS.md.** Cross-tool agent brief at project root. Load `references/orchestration/agents-md-template.md`. Detect existing AGENTS.md; respect or augment per the emission rules.
15. **Pillars memory layer.** Load `references/building/pillars-integration.md`. Every file-system project arc-ready shapes adopts Pillars: a Pillars-compatible `AGENTS.md` plus `agents/*.md` files distilled from arc-ready artifacts. Pillars steers future agent outputs; canonical `.<tier>-ready/` artifacts remain the source of truth. Respect any existing AGENTS.md and any existing `agents/` directory, but record non-Pillars conflicts as adoption blockers.
16. **Mode B audit-only path.** If the user wants an audit, not a scaffold, run `references/building/repo-audit.md` and `references/building/audit-mode.md`. Output `.repo-ready/AUDIT-REPORT.md` with severity-classified findings, no file modifications.
17. **Mode D multi-repo suite layout.** If the user is designing a collection of related repos, load `references/building/multi-repo-suite-layout.md` for the suite-layout pattern (skill-suite, microservice-cluster, monorepo-split).
18. **Monorepo patterns.** Workspace tools (pnpm/yarn/npm workspaces, Turborepo, Nx, Lerna, Rush). Load `references/building/monorepo-patterns.md`.
19. **Agent safety.** Forbidden actions, scope of agent edits, tool-permission policy. Load `references/building/agent-safety.md`.

**Passes when:** the relevant-files-not-maximum-files principle is satisfied (no scaffolded file is unmaintained-template); README is non-placeholder; CI workflows run and pass on a fresh clone; AGENTS.md exists at project root as a Pillars loader or the adoption blocker is recorded; the project profile is recorded; `agents/context.md` and `agents/repo.md` exist or the adoption blocker is recorded.

#### Step 2.2. Production: build the end-to-end-wired application

Load `references/building/preflight-and-verification.md` for the pre-flight protocol. Then load `references/building/codebase-research.md` if existing code is present.

The 35 sub-steps below cluster into six concerns. Use the cluster as a navigation aid; the load-on-demand discipline is per individual reference, not per cluster.

- **Foundations (sub-steps 1-9)**: vertical slice discipline, DESIGN.md, states, data, auth, navigation, IA, naming, domain.
- **Quality (sub-steps 10-13)**: performance and security, API design, data viz, telemetry.
- **Polish (sub-steps 14-18)**: motion, AI patterns, a11y, dark mode, error pages.
- **Scale and i18n (sub-steps 19-22)**: expansion, file management, internationalization, login surfaces.
- **Engagement and ops (sub-steps 23-29)**: marketing pages in-app, migration, notifications, billing, realtime, reporting, SEO.
- **Integration and testing (sub-steps 30-35)**: settings, social features, system integration, testing and quality, workflows.

Sub-steps:

1. **Pre-flight.** Stack confirmed (from Step 1.4 or detection), repo scaffolded (from Step 2.1), PRD's slice queue available (from Step 1.3 handoff).
2. **Vertical slice discipline.** Build one feature end-to-end (schema + API + permission + service + queries + UI + states + tests) before touching the next. Load `references/building/ui-design-patterns.md`. The principle is non-negotiable.
3. **DESIGN.md detection.** If `DESIGN.md` exists at project root, consume it (sub-step 3a). If not, derive the visual identity and scaffold one (sub-step 3b). Load `references/building/design-md-integration.md`.
4. **States and feedback.** Loading, empty, error, partial, success. Every state covered for every surface. Load `references/building/states-and-feedback.md`.
5. **Data layer.** Schema, migrations, ORM/query layer, transactional boundaries. Load `references/building/data-layer.md`.
6. **Auth and RBAC.** Authentication mechanism, role model, permission checks at boundaries. Load `references/building/auth-and-rbac.md`.
7. **Headers and navigation.** Top nav, side nav, breadcrumbs, command palette. Load `references/building/headers-and-navigation.md`.
8. **Information architecture.** Page hierarchy, URL structure, route organization. Load `references/building/information-architecture.md`.
9. **Naming.** Variable, function, file, route, component naming conventions. Load `references/building/naming.md`.
10. **Domain considerations.** Per-domain UX patterns (healthcare, finance, e-commerce, etc.). Load `references/building/domain-considerations.md`.
11. **Performance and security.** Bundle size, render performance, OWASP-aligned input validation, output encoding. Load `references/building/performance-and-security.md` and `references/building/security-deep-dive.md`.
12. **API and integrations.** Endpoint design, request/response shape, retry and idempotency, third-party integrations. Load `references/building/api-and-integrations.md`.
13. **Data visualization.** Chart libraries, accessibility of data viz, real-data-not-fake-data principle. Load `references/building/data-visualization.md`.
14. **Analytics and telemetry.** Product analytics events, frontend telemetry, opt-out and consent. Load `references/building/analytics-and-telemetry.md`.
15. **Animation and motion.** Purpose-driven motion, prefers-reduced-motion compliance. Load `references/building/animation-and-motion.md`.
16. **AI product patterns.** Streaming UI, partial outputs, hallucination guards, agent-tool surfaces. Load `references/building/ai-product-patterns.md`.
17. **Accessibility deep-dive.** WCAG 2.2 AA baseline, keyboard navigation, screen-reader testing. Load `references/building/accessibility-deep-dive.md`.
18. **Dark mode.** Token-based theming, prefers-color-scheme, contrast preservation. Load `references/building/dark-mode-deep-dive.md`.
19. **Error pages and offline.** 404, 500, offline, maintenance. Load `references/building/error-pages-and-offline.md`.
20. **Expansion and scalability.** Multi-tenant, multi-region, internationalization-ready. Load `references/building/expansion-and-scalability.md`.
21. **File management and uploads.** Upload UI, virus scanning, signed URLs, retention. Load `references/building/file-management-and-uploads.md`.
22. **Internationalization.** i18n framework, locale negotiation, RTL support. Load `references/building/internationalization.md`.
23. **Login and auth pages.** Sign-up, sign-in, password reset, magic link, MFA, SSO. Load `references/building/login-pages.md` (sign-in surfaces) and `references/building/registration-pages.md` (sign-up surfaces).
24. **Marketing and landing pages.** Pre-product marketing surfaces inside the app shell. Load `references/building/marketing-and-landing-pages.md`. (Standalone marketing-launch surfaces are Tier 3 launch's job; this is the in-app subset.)
25. **Migration and data import.** CSV/JSON import, pipeline-driven migration, dry-run mode. Load `references/building/migration-and-data-import.md`.
26. **Notifications and email.** In-app notifications, transactional email, digest patterns. Load `references/building/notifications-and-email.md` and `references/building/email-template-design.md`.
27. **Payments and billing.** Stripe/Paddle/Lemon-Squeezy integration, invoice flows, dunning. Load `references/building/payments-and-billing.md`.
28. **Realtime and collaboration.** Presence, cursor sharing, CRDT vs OT, WebSocket/SSE. Load `references/building/realtime-and-collaboration.md`.
29. **Reporting.** Dashboard reports, export (CSV/PDF), scheduled delivery. Load `references/building/reporting.md`.
30. **SEO and web standards.** robots.txt, sitemap, canonical URLs, structured data. Load `references/building/seo-and-web-standards.md`.
31. **Settings and configuration.** User settings, org settings, feature flags. Load `references/building/settings-and-configuration.md`.
32. **Social media features.** Comments, reactions, share, embed. Load `references/building/social-media-features.md`.
33. **System integration.** Webhooks, OAuth providers, third-party API contracts. Load `references/building/system-integration.md`.
34. **Testing and quality.** Unit, integration, E2E, visual regression, contract tests. Load `references/building/testing-and-quality.md`.
35. **Workflows and actions.** Background jobs, scheduled tasks, action queues. Load `references/building/workflows-and-actions.md`.

The principle: every feature ships wired end-to-end to a real backend, not stubbed with TODO, fake JSON, or "hook this up later." No-scaffold-no-placeholder is the load-bearing rule.

**Passes when:** every slice in the queue is end-to-end-wired (real backend, real data, all states, tests passing); the no-scaffold-no-placeholder grep test (TODO/FIXME/lorem-ipsum/fake-data) returns clean for shipped slices; `.production-ready/STATE.md` records the slice queue, completed slices, and active ADRs.
