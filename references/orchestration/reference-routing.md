# Reference Routing Catalog

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## Reference files: load on demand

The reference catalog is organized by tier. It contains 219 focused files across five tiers. The former large domain catalog is now a compact router plus 37 profiles under `references/building/domains/`. Load individual files on demand per the per-tier tables below; loading the whole catalog at once is a known anti-pattern.

### Orchestration

| File | When to load |
|---|---|
| `references/orchestration/handoff-protocols.md` | Step 0.1, 1.x, 2.x, 3.x. Per-harness invocation patterns. |
| `references/orchestration/progress-tracking.md` | Step 0.2, 0.3, 0.5. PROGRESS.md schema, status vocabulary, resume protocol. |
| `references/orchestration/scope-fence.md` | Step 0.4 always; on demand otherwise. Boundary catalog. |
| `references/orchestration/sequencing-rules.md` | Step 0.3, Step 1, Step 2, Step 3. Tier dependency rules, parallelism, gate logic. |
| `references/orchestration/kickoff-antipatterns.md` | On demand during verification. |
| `references/orchestration/trigger-disambiguation.md` | When a user phrase plausibly matches more than one tier sub-step. The disambiguation table maps ambiguous user phrases to the canonical tier sub-step. |
| `references/orchestration/agents-md-template.md` | Step 0.6 and Step 2.1. The Pillars-compatible AGENTS.md template arc-ready emits when no AGENTS.md exists. |

### Planning

| File | When to load |
|---|---|
| `references/planning/prd-research.md` | Step 1.1 mode detection. |
| `references/planning/prd-anatomy.md` | Step 1.1 structure. |
| `references/planning/prd-antipatterns.md` | Step 1.1 audit and verification. |
| `references/planning/EXAMPLE-PRD.md` | Step 1.1 calibration. |
| `references/planning/problem-framing.md` | Step 1.1 sub-step 3. |
| `references/planning/user-personas.md` | Step 1.1 sub-step 4. |
| `references/planning/success-criteria.md` | Step 1.1 sub-step 5. |
| `references/planning/requirements.md` | Step 1.1 sub-steps 6, 7. |
| `references/planning/scope-and-out-of-scope.md` | Step 1.1 sub-step 8. |
| `references/planning/risks-and-assumptions.md` | Step 1.1 sub-step 9. |
| `references/planning/stakeholder-alignment.md` | Step 1.1 sub-step 11. |
| `references/planning/iterate-vs-freeze.md` | Step 1.1 sub-step 12. |
| `references/planning/architecture-research.md` | Step 1.2 mode detection. |
| `references/planning/architecture-antipatterns.md` | Step 1.2 audit and verification. |
| `references/planning/EXAMPLE-ARCH.md` | Step 1.2 calibration. |
| `references/planning/system-shape.md` | Step 1.2 sub-step 1. |
| `references/planning/component-breakdown.md` | Step 1.2 sub-step 2. |
| `references/planning/data-architecture.md` | Step 1.2 sub-step 3. |
| `references/planning/integration-architecture.md` | Step 1.2 sub-step 4. |
| `references/planning/non-functional-architecture.md` | Step 1.2 sub-step 5. |
| `references/planning/trust-boundaries.md` | Step 1.2 sub-step 6. |
| `references/planning/adr-discipline.md` | Step 1.2 sub-step 7. |
| `references/planning/diagrams.md` | Step 1.2 sub-step 8. |
| `references/planning/evolutionary-architecture.md` | Step 1.2 sub-step 9. |
| `references/planning/roadmap-research.md` | Step 1.3 mode detection. |
| `references/planning/roadmap-anatomy.md` | Step 1.3 structure. |
| `references/planning/roadmap-antipatterns.md` | Step 1.3 audit and verification. |
| `references/planning/EXAMPLE-ROADMAP.md` | Step 1.3 calibration. |
| `references/planning/cadence-models.md` | Step 1.3 sub-step 2. |
| `references/planning/dependency-graph.md` | Step 1.3 sub-steps 1, 3. |
| `references/planning/risk-driven-prioritization.md` | Step 1.3 sub-step 4. |
| `references/planning/sequencing-principles.md` | Step 1.3 sub-step 5. |
| `references/planning/scope-vs-time.md` | Step 1.3 sub-step 6. |
| `references/planning/launch-sequencing.md` | Step 1.3 sub-step 7. |
| `references/planning/review-cadence.md` | Step 1.3 sub-step 8. |
| `references/planning/handoff-to-execution.md` | Step 1.3 sub-step 9. |
| `references/planning/stack-research.md` | Step 1.4 mode detection. |
| `references/planning/stack-antipatterns.md` | Step 1.4 audit and verification. |
| `references/planning/EXAMPLE-STACK.md` | Step 1.4 calibration. |
| `references/planning/preflight-and-constraints.md` | Step 1.4 sub-step 1. |
| `references/planning/domain-stacks.md` | Step 1.4 sub-step 2. |
| `references/planning/scoring-framework.md` | Step 1.4 sub-step 3. |
| `references/planning/dimension-deep-dives.md` | Step 1.4 sub-step 3. |
| `references/planning/stack-bundles.md` | Step 1.4 sub-step 3. |
| `references/planning/pairing-rules.md` | Step 1.4 sub-step 4. |
| `references/planning/tradeoff-narratives.md` | Step 1.4 sub-step 5. |
| `references/planning/migration-paths.md` | Step 1.4 sub-step 6. |

### Building

| File | When to load |
|---|---|
| `references/building/repo-structure.md` | Step 2.1 sub-step 3. |
| `references/building/repo-audit.md` | Step 2.1 Mode B audit. |
| `references/building/repo-antipatterns.md` | Step 2.1 verification. |
| `references/building/audit-mode.md` | Step 2.1 Mode B. |
| `references/building/community-standards.md` | Step 2.1 sub-step 5. |
| `references/building/community-governance.md` | Step 2.1 sub-step 5. |
| `references/building/readme-craft.md` | Step 2.1 sub-step 4. |
| `references/building/ci-cd-workflows.md` | Step 2.1 sub-step 7. |
| `references/building/quality-tooling.md` | Step 2.1 sub-step 8. |
| `references/building/git-workflows.md` | Step 2.1 sub-step 9. |
| `references/building/licensing-legal.md` | Step 2.1 sub-step 10. |
| `references/building/monorepo-patterns.md` | Step 2.1 sub-step 17. |
| `references/building/multi-repo-suite-layout.md` | Step 2.1 Mode D. |
| `references/building/onboarding-dx.md` | Step 2.1 sub-step 12. |
| `references/building/platform-github.md` | Step 2.1 sub-step 7 (GitHub). |
| `references/building/platform-gitlab.md` | Step 2.1 sub-step 7 (GitLab). |
| `references/building/platform-bitbucket.md` | Step 2.1 sub-step 7 (Bitbucket). |
| `references/building/project-profiles.md` | Step 2.1 sub-step 2. |
| `references/building/product-form-router.md` | Before Tier 2 routing. Select one primary delivery form and its gate. |
| `references/building/domain-registry.md` | Tier 1.4 and Tier 2 domain composition. Map archetypes and overlays to stack profiles. |
| `references/building/release-distribution.md` | Step 2.1 sub-step 13. |
| `references/building/security-setup.md` | Step 2.1 sub-step 11. |
| `references/building/technical-docs.md` | Step 2.1 sub-step 6. |
| `references/building/questioning.md` | Step 2.1 pre-flight. |
| `references/building/pillars-integration.md` | Step 2.1 sub-step 15. Pillars memory layer for every file-system project. |
| `references/building/agent-safety.md` | Step 2.1 sub-step 19. |
| `references/building/production-antipatterns.md` | Step 2.2 verification. |
| `references/building/preflight-and-verification.md` | Step 2.2 pre-flight. |
| `references/building/codebase-research.md` | Step 2.2 existing-codebase mode. |
| `references/building/ui-design-patterns.md` | Step 2.2 sub-step 2. |
| `references/building/design-md-integration.md` | Step 2.2 sub-step 3. |
| `references/building/states-and-feedback.md` | Step 2.2 sub-step 4. |
| `references/building/data-layer.md` | Step 2.2 sub-step 5. |
| `references/building/auth-and-rbac.md` | Step 2.2 sub-step 6. |
| `references/building/headers-and-navigation.md` | Step 2.2 sub-step 7. |
| `references/building/information-architecture.md` | Step 2.2 sub-step 8. |
| `references/building/naming.md` | Step 2.2 sub-step 9. |
| `references/building/domain-considerations.md` | Step 2.2 sub-step 10. Router to focused profiles in `references/building/domains/`. |
| `references/building/performance-and-security.md` | Step 2.2 sub-step 11. |
| `references/building/api-and-integrations.md` | Step 2.2 sub-step 12. |
| `references/building/data-visualization.md` | Step 2.2 sub-step 13. |
| `references/building/analytics-and-telemetry.md` | Step 2.2 sub-step 14. |
| `references/building/animation-and-motion.md` | Step 2.2 sub-step 15. |
| `references/building/ai-product-patterns.md` | Step 2.2 sub-step 16. |
| `references/building/accessibility-deep-dive.md` | Step 2.2 sub-step 17. |
| `references/building/dark-mode-deep-dive.md` | Step 2.2 sub-step 18. |
| `references/building/email-template-design.md` | Step 2.2 sub-step 26. |
| `references/building/error-pages-and-offline.md` | Step 2.2 sub-step 19. |
| `references/building/expansion-and-scalability.md` | Step 2.2 sub-step 20. |
| `references/building/file-management-and-uploads.md` | Step 2.2 sub-step 21. |
| `references/building/internationalization.md` | Step 2.2 sub-step 22. |
| `references/building/login-pages.md` | Step 2.2 sub-step 23 (login / sign-in surfaces). |
| `references/building/registration-pages.md` | Step 2.2 sub-step 23 (registration / sign-up surfaces). |
| `references/building/marketing-and-landing-pages.md` | Step 2.2 sub-step 24. |
| `references/building/migration-and-data-import.md` | Step 2.2 sub-step 25. |
| `references/building/notifications-and-email.md` | Step 2.2 sub-step 26. |
| `references/building/payments-and-billing.md` | Step 2.2 sub-step 27. |
| `references/building/realtime-and-collaboration.md` | Step 2.2 sub-step 28. |
| `references/building/reporting.md` | Step 2.2 sub-step 29. |
| `references/building/security-deep-dive.md` | Step 2.2 sub-step 11. |
| `references/building/seo-and-web-standards.md` | Step 2.2 sub-step 30. |
| `references/building/settings-and-configuration.md` | Step 2.2 sub-step 31. |
| `references/building/social-media-features.md` | Step 2.2 sub-step 32. |
| `references/building/system-integration.md` | Step 2.2 sub-step 33. |
| `references/building/testing-and-quality.md` | Step 2.2 sub-step 34. |
| `references/building/workflows-and-actions.md` | Step 2.2 sub-step 35. |

### Shipping

| File | When to load |
|---|---|
| `references/shipping/deploy-research.md` | Step 3.1 mode detection. |
| `references/shipping/deploy-antipatterns.md` | Step 3.1 verification. |
| `references/shipping/preflight-and-gating.md` | Step 3.1 sub-step 1. |
| `references/shipping/pipeline-patterns.md` | Step 3.1 sub-step 2. |
| `references/shipping/environment-parity.md` | Step 3.1 sub-step 3. |
| `references/shipping/first-deploy-checklist.md` | Step 3.1 sub-step 4. |
| `references/shipping/deployment-topologies.md` | Step 3.1 sub-step 5. |
| `references/shipping/zero-downtime-migrations.md` | Step 3.1 sub-step 6. |
| `references/shipping/progressive-delivery.md` | Step 3.1 sub-step 7. |
| `references/shipping/rollback-playbook.md` | Step 3.1 sub-step 8. |
| `references/shipping/secrets-injection.md` | Step 3.1 sub-step 9. |
| `references/shipping/observe-research.md` | Step 3.2 mode detection. |
| `references/shipping/observe-antipatterns.md` | Step 3.2 verification. |
| `references/shipping/slo-design.md` | Step 3.2 sub-step 1. |
| `references/shipping/metrics-taxonomy.md` | Step 3.2 sub-step 2. |
| `references/shipping/logging-patterns.md` | Step 3.2 sub-step 3. |
| `references/shipping/tracing.md` | Step 3.2 sub-step 4. |
| `references/shipping/error-tracking.md` | Step 3.2 sub-step 5. |
| `references/shipping/alert-patterns.md` | Step 3.2 sub-step 6. |
| `references/shipping/dashboards.md` | Step 3.2 sub-step 7. |
| `references/shipping/incident-response.md` | Step 3.2 sub-step 8. |
| `references/shipping/post-mortem.md` | Step 3.2 sub-step 9. |
| `references/shipping/vendor-landscape.md` | Step 3.2 sub-step 10. |
| `references/shipping/launch-research.md` | Step 3.3 mode detection. |
| `references/shipping/launch-antipatterns.md` | Step 3.3 verification. |
| `references/shipping/positioning-and-copy.md` | Step 3.3 sub-step 1. |
| `references/shipping/landing-page-anatomy.md` | Step 3.3 sub-step 2. |
| `references/shipping/seo-fundamentals.md` | Step 3.3 sub-step 5. |
| `references/shipping/social-share-cards.md` | Step 3.3 sub-step 6. |
| `references/shipping/waitlist-and-email.md` | Step 3.3 sub-step 7. |
| `references/shipping/launch-channels.md` | Step 3.3 sub-step 8. |
| `references/shipping/launch-week-runbook.md` | Step 3.3 sub-step 9. |
| `references/shipping/launch-telemetry.md` | Step 3.3 sub-step 10. |
| `references/shipping/press-and-outreach.md` | Step 3.3 sub-step 11. |
| `references/shipping/post-launch-transition.md` | Step 3.3 sub-step 12. |
| `references/shipping/harden-research.md` | Step 3.4 mode detection. |
| `references/shipping/harden-antipatterns.md` | Step 3.4 verification. |
| `references/shipping/owasp-walkthrough.md` | Step 3.4 sub-steps 1-3. |
| `references/shipping/compliance-frameworks.md` | Step 3.4 sub-step 4. |
| `references/shipping/auth-hardening.md` | Step 3.4 sub-step 5. |
| `references/shipping/api-hardening.md` | Step 3.4 sub-step 6. |
| `references/shipping/crypto-primitives.md` | Step 3.4 sub-step 7. |
| `references/shipping/pentest-prep.md` | Step 3.4 sub-step 8. |
| `references/shipping/responsible-disclosure.md` | Step 3.4 sub-step 9. |
| `references/shipping/post-incident-hardening.md` | Step 3.4 sub-step 10. |
| `references/shipping/actionable-findings.md` | Step 3.4 sub-step 11. |
| `references/shipping/security-tooling-landscape.md` | Step 3.4 sub-step 12. |

### Shared

| File | When to load |
|---|---|
| `references/shared/RESEARCH-2026-04.md` | On demand for citations and prior-art. The consolidated source-citations file. |
| `references/shared/ORCHESTRATORS.md` | When integrating with GSD, BMAD, Spec Kit, Superpowers, or other orchestrators. |
