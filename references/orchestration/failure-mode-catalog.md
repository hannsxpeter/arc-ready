# Consolidated Failure-Mode Catalog

This reference preserves the detailed workflow and enforcement semantics extracted from the pre-v1.1.0 SKILL.md. Load it only when the routed work needs this detail.

## The "have-nots": consolidated failure-mode catalog

These have-nots disqualify the artifact at the corresponding tier. Every one is grep-testable. Every one is preserved verbatim from the source eleven skills. The full per-tier catalogs (with citations, severity, remediation) are in `references/<tier>/<skill>-antipatterns.md`.

### Tier 0 (orchestration) have-nots

- **Scope leak.** arc-ready writes specialist content. Any markdown produced by arc-ready that fulfills a specialist tier's job from outside that tier's sub-step. Grep target: arc-ready output that contains a section header from a tier's artifact template (`# Product Requirements`, `## Trust Boundaries`, `## Now / Next / Later`, `## OWASP Walkthrough`, etc.) outside that tier's sub-step.
- **Rubber-stamp orchestration.** PROGRESS.md says step done with no artifact on disk. For every PROGRESS.md row where `status: done`, the declared `artifact:` path exists and is non-empty. Without that, rubber-stamp fired.
- **Phantom resume.** Resume that did not re-derive state from disk. Every arc-ready turn begins with a `Read .arc-ready/PROGRESS.md` and an `ls` of every claimed-complete `.<tier>-ready/`. If a turn skipped these and acted on cached conversation memory, phantom resume fired.
- **Ghost handoff.** Tier invoked before its declared upstream artifact exists. For every tier sub-step, the prior tier's artifact-verification timestamp is earlier than the sub-step start. Without that, ghost handoff fired.
- **Happy-path orchestration.** No status code in PROGRESS.md for the failure / skip / import / re-invoke cases. Every PROGRESS.md row's `status` field is one of `pending`, `in-flight`, `done`, `skipped`, `imported`, `failed`, `re-invoked`.
- **Critical-finding gate breach.** arc-ready proceeds with launch after a Critical finding from harden without an explicit risk-acceptance entry. If `.harden-ready/FINDINGS.md` contains an unresolved Critical and PROGRESS.md shows launch as `done` without a `risk-acceptance:` block, the gate failed.
- **Out-of-scope inline answer.** Any conversation turn where the user asked for a non-arc deliverable, and arc-ready produced markdown that fulfills the request rather than refusing and routing.
- **Silence as skip.** A tier that does not appear in PROGRESS.md at all (neither as done nor as skipped). Silence is not a status.

### Tier 1.1 (PRD) have-nots

- **Hollow PRD.** Every section is filled, but the sentences are decisions-that-aren't. The PRD passes visual review and decides nothing.
- **Invisible PRD.** The PRD reads the same across any product in the category. Substitution test fails on the Problem and Target User sections.
- **Feature laundry list.** A flat list of features (or requirements) with no prioritization. No cut line. Every item is Must, or nothing is ranked.
- **Solution-first PRD.** The Problem section names the product's solution. The product is assumed; the problem is backfilled.
- **Assumption-soup PRD.** User-behavior claims stated as facts without evidence, validation plan, or hypothesis labeling.
- **Moving-target PRD.** Edited frequently without changelog or broadcasts. Engineers stop trusting the document.
- **Theater PRD.** Sections present, structure pristine, every sentence decoration. The visual completeness substitutes for decision content.
- **Quill-and-inkwell PRD.** Tone elevated to match the gravity the writer thinks the document deserves. Decisions buried in prose.
- **Superficial-completion PRD.** The PRD reaches "frozen" status before downstream consumers have signed off on the handoff blocks.
- **Engineer-can-not-start-building.** The PRD does not contain enough specificity for an engineer to start the first slice without a clarification meeting.

### Tier 1.2 (architecture) have-nots

- **Architecture theater.** Diagrams without decisions. C4 diagrams rendered, ADRs absent or non-load-bearing.
- **Paper-tiger architecture.** Decisions without failure-mode analysis. Looks robust until first real load.
- **Cargo-cult cloud-native.** Kubernetes and Kafka for a ten-user CRUD. Scale predictions invented; the PRD's actual scale ceiling ignored.
- **Stackitecture.** Tool choices dressed up as architecture. "We use Postgres and Next.js" is not an architectural decision.
- **Resume-driven architecture.** Decisions picked for the writer's career rather than the system's constraints.
- **Non-architecture.** "We'll figure it out later." Absence of decision masquerading as agility.
- **"Scalable" as a claim with no numbers.** Adjectives where thresholds belong.
- **Trust boundaries on paper only.** Declared in the architecture document, absent in code or configuration.
- **ADRs without flip points.** "We chose X" without "what would flip this."
- **Component graph absent.** No topological dependency graph in `.architecture-ready/HANDOFF.md`. Roadmap-ready then guesses.

### Tier 1.3 (roadmap) have-nots

- **Feature factory.** Items listed with no outcome. Bare feature names.
- **Build trap.** Roadmap reads as a feature backlog instead of an outcome plan (Perri).
- **Roadmap theater.** Dates asserted with no capacity input.
- **Fictional precision.** Gantt-to-the-day with no team-capacity input.
- **Fictional parallelism.** More concurrent tracks than engineers.
- **Quarter-stuffing.** All four quarters equally full. Far horizons treated at near-horizon precision.
- **Speculative roadmap.** Items invented without upstream PRD or architecture reference.
- **Shelf roadmap.** Written once, never refreshed. Cycle boundaries pass with no replan.
- **Polish-indefinitely.** Items extended without explicit decision. The "we'll just keep iterating" trap.
- **Silent re-prioritization.** Order changed without changelog or broadcast.

### Tier 1.4 (stack) have-nots

- **Unweighted recommendation.** Scores without stated weights the user can override.
- **Flip-point-free recommendation.** "Use X" without "what would flip this."
- **Familiarity-as-fit.** The stack the writer knows, regardless of project domain.
- **Resume-driven stack pick.** Same shape as resume-driven architecture, applied to tech bundle.
- **Bundle incompatibility.** Frontend-backend-data-hosting-observability picks that fail the pairing-rules check.
- **Migration-cost ignored.** No "what does it take to leave this bundle" answer.
- **Single-domain stack across all domains.** The Next.js-Postgres-Vercel stack proposed for healthcare, finance, edge IoT, ML training, mobile-only.
- **Bundle without scale ceiling.** No statement of "this bundle works up to N users / requests / engineers and then needs replacement."

### Tier 2.1 (repo) have-nots

- **Maximum-files-everywhere.** Every project gets every file regardless of stage and audience. Weekend CLI gets GOVERNANCE.md and a 39-point audit.
- **Placeholder-in-production.** Files scaffolded with TODO/lorem-ipsum that never get filled in. Worse than no file: signals an unmaintained project.
- **Stack-detection skipped.** Same scaffold for every stack. Node-shaped scaffold dropped onto a Python project.
- **Pillars adoption collision.** repo-ready overwrites an existing AGENTS.md or `agents/` directory instead of respecting it and recording the blocker.
- **CI workflow that does not run.** The .github/workflows/*.yml file is present but the build fails on a fresh clone.
- **README that does not describe the project.** Generic README with no project-specific content.
- **License absent.** OSS distribution without a LICENSE file.
- **SECURITY.md absent.** Public repo without a vulnerability-reporting channel.

### Tier 2.2 (production / app) have-nots

- **Hollow dashboard.** Database-API-Auth scaffold, no feature wired end-to-end.
- **Hollow button.** UI element present, no backend behind it. "Save" that doesn't save.
- **Fake data.** Lorem-ipsum, faker.js, hardcoded JSON in production code paths.
- **Missing states.** Feature has happy path; loading, empty, error, partial, success states absent.
- **TODO/FIXME in shipped slice.** Production code has unresolved markers.
- **Permission check absent.** Endpoint runs without a permission check; UI surfaces hide what the API permits.
- **Data viz with fake data.** Chart renders synthetic data, not real backend output.
- **DESIGN.md ignored.** Project root has DESIGN.md; the build does not consume it.
- **Real-backend-not-stubbed broken.** Feature claims end-to-end-wired but uses a mock instead of the real backend.
- **Slice not demo-able.** A "completed" slice that an actual user cannot do an actual job with.

### Tier 3.1 (deploy) have-nots

- **Different-artifact-per-environment.** Build runs separately in staging and prod. The same hash does not promote.
- **Code-only rollback for data-forward change.** "Rollback: redeploy previous image" written next to a schema migration.
- **Single-deploy expand-contract.** Schema change attempted in one deploy on a populated database.
- **Paper canary.** "Canary" label on a deploy step with no stop rule, no metrics watched, no automatic abort.
- **First-deploy ad-hoc.** First production deploy bypasses the checklist; "we'll formalize the pipeline later."
- **Secrets in repo.** Any value that should be vault-fetched is present in version control.
- **Environment parity drift unrecorded.** Staging and prod differ silently. The diff is not documented.
- **Rollback never tested.** Rollback path exists in the runbook but has never been executed.
- **Migration calendar invisible.** Multi-deploy migration with no calendar showing the deploy sequence and the contract step.

### Tier 3.2 (observe) have-nots

- **Paper SLO.** Numbers with no error-budget policy. "p95 latency < 200ms" with no statement of what happens when it breaches.
- **Blind dashboard.** Charts bound to no SLO. Decoration metrics above the fold.
- **Paper runbook.** Written once, never executed. Cannot be run by an on-call engineer cold.
- **Alert that does not page on real fires.** Pageable alert that has not fired in months when incidents have shipped.
- **Cause-based alerting.** Alerts that fire on internal causes ("queue depth > X") instead of user-visible symptoms.
- **Tracing not propagated.** Spans terminate at service boundaries; cross-service traces broken.
- **Logging without correlation IDs.** Logs cannot be joined to a request trace.
- **Error tracking off.** No Sentry/Bugsnag/Honeybadger; uncaught exceptions invisible.
- **Vendor lock without exit plan.** Observability vendor chosen without a "what if we leave" answer.
- **Independence of telemetry from app.** Observability runs out-of-band; if the app is down, the telemetry is also down.

### Tier 3.3 (launch) have-nots

- **AI-slop landing.** Hero, feature cards, sub-hero produced by an LLM with no substitution-test pass. Reads the same as competitors.
- **Hero-fatigue copy.** "Empower your team with AI-powered productivity." Substitution test fails in one sentence.
- **Spec-sheet positioning.** Feature list where positioning belongs.
- **Paper waitlist.** Waitlist UI present; the email funnel does not actually deliver to launch day.
- **Unrendered OG card.** OG meta tags present; the card does not render in actual previews (Slack, iMessage, Twitter, LinkedIn).
- **Silent launch.** Signups arrive on launch day; source attribution is absent. Cannot tell which channel converted.
- **Launch without channel plan.** Product Hunt / Show HN / Reddit / X / IH / dev.to / LinkedIn ad-hoc'd day-of.
- **Press kit absent.** Outreach without a press kit means the journalist has to assemble it.
- **Post-launch transition unwritten.** Launch-week ends; the next-week motion is not defined.
- **Substitution test failed on a card.** Any of the six feature cards fails the substitution test.

### Tier 3.4 (harden) have-nots

- **Scanner-only security.** "Snyk passed; we are secure." Veracode 2025: 45% of AI code has at least one OWASP Top 10 bug despite scanner-clean.
- **Paper trust boundary.** Boundary declared in architecture document; absent in code or configuration.
- **Hardening as ritual.** Annual pen test, nothing between.
- **Compliance without security.** Checklist green; the app is still adversarially exploitable.
- **Shallow-audit trap.** Only finds what tools surface; OWASP categories not walked manually.
- **CVE-of-the-week patching.** Reactive to disclosed CVEs; no class-of-issue investigation.
- **"Accepted risk" without owner or expiration.** Scanner finding marked accepted; no owner named, no expiration date.
- **Compliance control unmapped.** SOC 2 / HIPAA / PCI / GDPR control claimed; no specific code/config evidence.
- **Pen test, no retest.** Findings reported; remediation never verified.
- **SECURITY.md absent.** No responsible-disclosure channel. Researchers route through whatever email they can find.
- **Bug bounty program with no triage SLA.** Reports come in; no commitment on response time.
- **Post-incident fixes are instance, not class.** "We fixed THIS bug" without "what class of bug was it."
