# Shipping Workflow

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

### Tier 3: Shipping

The shipping tier consists of four sub-steps. Deploy and observe are sequential (deploy first; observe wires onto the deployed app). Launch asset preparation and hardening run in parallel. Public activation is a separate serial action that requires a fresh hardening recheck.

#### Step 3.1. Deploy: ship safely, repeatably, reversibly

Load `references/shipping/deploy-research.md` for mode detection. Then load `references/shipping/preflight-and-gating.md`.

Sub-steps:

1. **Preflight and gating.** Build is green, tests pass, security scan is clean (above accepted-risk threshold), schema migration plan is reviewed.
2. **Pipeline patterns.** Build once, promote the same artifact through environments. Load `references/shipping/pipeline-patterns.md`.
3. **Environment parity.** Pre-prod, staging, prod parity rules. Diffs are explicit, not accidental. Load `references/shipping/environment-parity.md`.
4. **First-deploy checklist.** First production deploy gets extra scrutiny. Load `references/shipping/first-deploy-checklist.md`.
5. **Deployment topologies.** Single-region, multi-region, edge, hybrid. Load `references/shipping/deployment-topologies.md`.
6. **Zero-downtime migrations.** Expand-contract pattern, multi-deploy migration calendar. Schema changes are NEVER one-deploy operations on a populated database. Load `references/shipping/zero-downtime-migrations.md`.
7. **Progressive delivery.** Canary, blue-green, feature-flagged rollout. Each pattern has a stop rule, not a label. Load `references/shipping/progressive-delivery.md`.
8. **Rollback playbook.** Code-only rollback is straightforward. Data-forward rollback is a compensating-forward plan plus a restore point, never a "redeploy previous image" bullet. Load `references/shipping/rollback-playbook.md`.
9. **Secrets injection.** Vault-pulled, runtime-injected, never-committed. Load `references/shipping/secrets-injection.md`.

**Passes when:** the same-artifact-promotion grep test passes (the prod artifact hash equals the staging artifact hash); every schema change is classified as code-only or data-forward with the corresponding plan; canary stop rules are concrete (not "monitor and decide"); rollback paths are proven reachable from post-deploy state.

#### Step 3.2. Observe: keep the deployed app healthy

Load `references/shipping/observe-research.md` for mode detection. Then load `references/shipping/slo-design.md`.

Sub-steps:

1. **SLO design.** User-facing journeys named; SLI per journey defined; SLO threshold and window stated; error-budget policy declared (what triggers a code freeze; who owns the policy). Load `references/shipping/slo-design.md`.
2. **Metrics taxonomy.** Service-level indicators, supporting diagnostics, business metrics. Each charted metric is explicitly classified. Load `references/shipping/metrics-taxonomy.md`.
3. **Logging patterns.** Structured logging, sampling, correlation IDs, retention. Load `references/shipping/logging-patterns.md`.
4. **Tracing.** OpenTelemetry distributed tracing, span structure, baggage. Load `references/shipping/tracing.md`.
5. **Error tracking.** Sentry/Bugsnag/Honeybadger integration, source-map upload, release tagging. Load `references/shipping/error-tracking.md`.
6. **Alert patterns.** Symptom-based, not cause-based; SLO-breaking, not threshold-tripping; pageable vs ticketable. Load `references/shipping/alert-patterns.md`.
7. **Dashboards.** Bound to SLOs; supporting diagnostics labeled non-alerting; no decoration charts. Load `references/shipping/dashboards.md`.
8. **Incident response.** Severity definitions, on-call rotation, status page, runbooks. Load `references/shipping/incident-response.md`.
9. **Post-mortem.** Blameless, action-item-tracked, class-not-instance fixes. Load `references/shipping/post-mortem.md`.
10. **Vendor landscape.** Datadog/Honeycomb/Grafana/New Relic/Sentry/Axiom selection grid. Load `references/shipping/vendor-landscape.md`.

**Installation-ready passes when:** every charted/alerted/SLOed number is bound to a journey or explicitly labeled non-alerting; the error-budget policy names a freeze trigger and an owner; runbooks have been executed at least once (paper runbooks fail this gate); and a controlled production-equivalent signal has exercised alert delivery and ownership end to end.

Track `operationally-mature` separately in `.observe-ready/STATE.md`. It requires a recent real service event and tuning evidence. A controlled fire is valid installation evidence but must stay labeled synthetic. If no real or controlled fire exists, keep Tier 3.2 `in-flight`; do not fabricate recent-fire history.

#### Step 3.3. Launch: tell the world without shipping AI-slop

Load `references/shipping/launch-research.md`. Then load `references/shipping/positioning-and-copy.md`.

Sub-steps:

1. **Positioning.** Who-it-is-for line that fails the substitution test. Load `references/shipping/positioning-and-copy.md`.
2. **Landing page anatomy.** Hero, sub-hero, feature cards, social proof, pricing, FAQ, CTA. Each section has a substitution-test-pass criterion. Load `references/shipping/landing-page-anatomy.md`.
3. **Copy refinement.** Hero, sub-hero, every card. Run substitution test sentence by sentence. AI-slop hero copy is the dominant launch failure mode.
4. **Visual surface.** Renders to actual designs or actual screenshots, not "AI illustration of an abstract concept." (Frontend craft from Tier 2 carries forward.)
5. **SEO fundamentals.** Meta tags, OG tags, Twitter cards, canonical, sitemap, robots. Load `references/shipping/seo-fundamentals.md`.
6. **Social share cards.** OG card renders in actual previews (Slack, iMessage, Twitter, LinkedIn). Test before launch. Load `references/shipping/social-share-cards.md`.
7. **Waitlist and email.** Funnel from waitlist signup to launch-day notification; double-opt-in; unsubscribe; deliverability. Load `references/shipping/waitlist-and-email.md`.
8. **Launch channels.** Product Hunt, Show HN, Reddit, X, IH, dev.to, LinkedIn. Per-channel format and timing. Load `references/shipping/launch-channels.md`.
9. **Launch-week runbook.** D-7 to D+7 schedule. Load `references/shipping/launch-week-runbook.md`.
10. **Launch telemetry.** Source attribution, conversion funnel, signup quality. Load `references/shipping/launch-telemetry.md`.
11. **Press and outreach.** Press kit, embargoed previews, journalist outreach. Load `references/shipping/press-and-outreach.md`.
12. **Post-launch transition.** From launch-day push to ongoing marketing; launch-ready hands off. Load `references/shipping/post-launch-transition.md`.

**Launch-assets-ready passes when:** the substitution test passes on the hero, sub-hero, every feature card, the OG card title, the Show HN title, the launch email subject; the OG card renders in at least three preview surfaces; the waitlist has source attribution; launch-day telemetry has a real implementation, not a "we'll wire it up later" stub.

This status authorizes preparation only. Immediately before any public activation, run the timestamped pre-publication gate in `references/orchestration/completion-gates.md`. A hardening update after that check invalidates the gate.

#### Step 3.4. Harden: survive adversarial attention

Load `references/shipping/harden-research.md`. Then load `references/shipping/owasp-walkthrough.md`.

Sub-steps:

1. **OWASP Top 10 walkthrough.** Per-category review: each category passes, partials, or fails for the deployed app. Load `references/shipping/owasp-web-top-10-2025.md` for the current web categories and `references/shipping/owasp-walkthrough.md` for the detailed manual tests, API list, and LLM list.
2. **OWASP API Security Top 10.** API-specific category review. Same structure.
3. **OWASP LLM Top 10.** If the app has an LLM surface. Same structure.
4. **Compliance frameworks.** SOC 2 Common Criteria, HIPAA 164.312, PCI-DSS 4.0, GDPR Article 32. Each control mapped to specific code/config evidence. Load `references/shipping/compliance-frameworks.md`.
5. **Auth hardening.** Session policy, MFA enforcement, brute-force protection, OAuth misconfigurations. Load `references/shipping/auth-hardening.md`.
6. **API hardening.** Rate limiting, input validation, output encoding, contract enforcement. Load `references/shipping/api-hardening.md`.
7. **Crypto primitives.** Algorithm selection, key management, rotation policy. Load `references/shipping/crypto-primitives.md`.
8. **Pen-test prep.** Scope, environment, RoE, retest discipline. Load `references/shipping/pentest-prep.md`.
9. **Responsible disclosure.** SECURITY.md, security@<domain>, bug-bounty program design. Load `references/shipping/responsible-disclosure.md`.
10. **Post-incident hardening.** Class-not-instance fixes from past incidents. Load `references/shipping/post-incident-hardening.md`.
11. **Actionable findings.** Every finding has: title, severity with justification, affected asset, reproduction steps, impact, root cause, proposed fix with code example, regression-prevention plan, retest plan, references. Load `references/shipping/actionable-findings.md`.
12. **Security tooling landscape.** SAST, DAST, SCA, secrets scanning, container scanning. Tools are inputs, not the audit itself. Load `references/shipping/security-tooling-landscape.md`.

**Passes when:** every OWASP category has a verdict with evidence; every compliance control maps to specific implementation; every "accepted risk" has a named owner and an expiration date; the findings report is actionable per the actionable-findings format; the critical-finding gate to launch has resolved.
