# Evolutionary Architecture

Loaded at Step 10 (fitness functions) and Mode E (rearchitecture). The content here is the reason Tier 3 exists as a distinct gate: without automated conformance, the architecture as documented and the architecture as implemented diverge within months. This file names the practice, the categories, the tooling, the enforcement cadence, and the pragmatics.

Canonical reference: Neal Ford, Rebecca Parsons, Patrick Kua, Pramod Sadalage, "Building Evolutionary Architectures: Automated Software Governance," O'Reilly, 2nd ed 2023, ISBN 978-1-492-09754-9. First edition (Ford / Parsons / Kua, 2017) introduced the concept; the 2nd edition with Sadalage (2023) codified eight categories of fitness function and added generative-testing chapters. Companion site: https://evolutionaryarchitecture.com/.

## 1. Why architecture decays

Architecture decays because four forces compound over time and no automated mechanism resists them.

**The team forgets the decisions.** The engineers who made ADR-001 leave. The new engineers inherit a codebase whose shape is visible but whose rationale is not. The first time a feature pushes against a boundary, the new team makes a locally-reasonable choice that the original architect would have refused; the precedent compounds; within twelve months the shape is not the one the ADR claims. Nygard's ADR format explicitly exists to survive team turnover; the practical failure is that ADRs are read once and never again. See RESEARCH-2026-04.md section 7.2 for documented ADR-practice failure modes (retroactive writing, never superseded, buried in Confluence).

**Constraints drift.** The PRD's scale ceiling at kickoff was 10K org-users; the product succeeded and now serves 500K. The latency budget at kickoff was p95 under 500ms; the product is in the checkout path now and the real budget is p95 under 100ms. The compliance posture at kickoff was "no PII"; a regulatory requirement added PII handling and no one revisited the trust-boundary section. Architecture decisions are load-bearing against specific constraints; when constraints shift and no one flips the decision, the architecture silently becomes wrong.

**New features push the shape into places the architecture did not anticipate.** A new feature needs a graph traversal; there is no graph store in the architecture; the engineer writes recursive CTEs in Postgres because that is faster than negotiating a new ADR; three years later the recursive CTE is load-bearing, performs poorly under scale, and the architecture has a shadow graph store it never acknowledged. This is the paper-tiger failure mode (RESEARCH-2026-04.md section 2.2): the original document looks robust, but the first real load on an unanticipated axis collapses it.

**Without conformance testing, documented and implemented diverge.** This is the generalization. Every decay force above has the same fix: a fitness function that fails the build (or pages on-call) when the architecture drifts from intent. Fitness functions are the mechanism that keeps architecture alive; the ARCH.md without them becomes a historical document the next team ignores. Ford / Parsons / Kua / Sadalage 2023 is explicit: evolutionary architecture is automated software governance, not periodic-review architecture governance.

## 2. Fitness functions defined

**A fitness function is an automated test that fails when the architecture drifts from intent.** Ford / Parsons / Kua (2017) coined the term; the second edition (2023) refined the definition to "objective integrity measurements for architectural characteristics."

Difference from regular tests: fitness functions are scoped to **architectural invariants**, not business logic. A test that "creating an order with negative quantity returns a 400" is business logic; a test that "the Orders module does not import from the Identity module" is architectural. A test that "the checkout endpoint returns within 200ms under 1K QPS" is architectural (the NFR from the PRD); a test that "the checkout returns the correct tax calculation" is business logic.

The three pillars (evolutionaryarchitecture.com):

1. **Fitness functions.** Automated, objective checks of architectural characteristics.
2. **Incremental change.** Small, reversible steps rather than big-bang rearchitecture.
3. **Appropriate coupling.** The architecture makes the right things easy and the wrong things hard; the fitness function enforces "hard."

The practical definition SKILL.md adopts: an automated check, running in CI or at runtime, whose pass/fail state is binary, whose failure traces to an architectural decision in an ADR, and whose remediation is either fix-the-code or supersede-the-ADR; ambiguity is not allowed.

## 3. Fitness function categories

Eight categories, drawn from Ford / Parsons / Kua / Sadalage 2023 chapter 3 and RESEARCH-2026-04.md section 8. Per category: what it tests, when it runs, and canonical tooling. Detail lives in Sections 4-7 below for the four highest-leverage categories.

| # | Category | What it tests | When it runs | Tooling (common) |
|---|---|---|---|---|
| 1 | Dependency conformance | Module A does not depend on Module B; no cycles; layer direction is respected | CI (per PR) | ArchUnit, NetArchTest, dependency-cruiser, Packwerk, Modularize |
| 2 | Data-ownership conformance | Only Component X writes to Table T | CI + nightly | SQL grant audit, static analysis of write paths, integration test |
| 3 | Trust-boundary conformance | Auth middleware is not bypassed; tenant A cannot read tenant B's data; authorization is not client-side | CI + runtime | ESLint / golangci-lint custom rules, integration tests, OPA / Cedar policy tests |
| 4 | NFR conformance | p95 latency under threshold; availability SLO met; throughput capacity sustained | Runtime + nightly | Load tests (k6, Locust, Gatling), synthetic probes, SLO alerts |
| 5 | Schema-drift detection | Migrations are forward-only and backward-compatible for the rollout window | CI | Buf (Protobuf), Atlas (SQL), avro-tools, custom lint |
| 6 | Deprecation conformance | Deprecated APIs are not re-imported after removal; sunset dates are enforced | CI + nightly | Custom AST lints, API gateway metrics, grep-based checks in CI |
| 7 | Security conformance | No secrets in code; no known-bad patterns (SSRF, insecure-cookies, plain-text credentials) | CI (per PR) | Semgrep, TruffleHog, Gitleaks, CodeQL, trivy, Snyk |
| 8 | Contract conformance | Producer-consumer contracts hold; event payloads are backward-compatible; OpenAPI / gRPC contracts not broken | CI | Pact, Spring Cloud Contract, Buf breaking-change detection, OpenAPI-diff |

The rule: every load-bearing architectural decision in ARCH.md maps to one or more category cells above. If a decision has no fitness function candidate, it is not enforceable; name it as un-enforceable and revisit the decision. Un-enforceable decisions drift first.

## 4. Dependency conformance deep dive

The most common, most load-bearing, and most production-proven fitness-function category. The decisions it enforces: module boundaries in a modular monolith; layer direction in Hexagonal / Clean / Onion architectures; service-to-service dependency direction in service-oriented architectures.

**ArchUnit (Java, Kotlin).** https://www.archunit.org/. A JUnit-style library. Rules are written as unit tests and run in CI with the rest of the test suite. Example rules:

```java
noClasses().that().resideInAPackage("..domain..")
    .should().dependOnClassesThat().resideInAPackage("..infrastructure..");

classes().that().resideInAPackage("..orders..")
    .should().onlyBeAccessed().byClassesThat().resideInAPackages("..orders..", "..api..");

classes().should().beFreeOfCycles();
```

Failure surfaces in CI output as a failing test. Baeldung and InfoQ have walkthrough material (RESEARCH-2026-04.md section 8.2). Shopify-scale production use was not practical in the JVM ecosystem; the Ruby equivalent is Packwerk.

**Packwerk (Ruby).** https://github.com/Shopify/packwerk. Shopify open-sourced in 2020. The existence proof that fitness functions scale to 2.8M-line monoliths (section 8.3 RESEARCH-2026-04.md). Packwerk enforces "package" boundaries in a Ruby codebase through declared public APIs and dependency lists; violations surface in CI. The Shopify monolith has 4000+ packages with enforced boundaries and hundreds of concurrent contributors; without Packwerk, it would have degenerated into a big ball of mud. The practical lesson: dependency conformance is the fitness function that scales; skip it and no other fitness function matters because the shape will not survive.

**dependency-cruiser (JS / TS).** https://github.com/sverweij/dependency-cruiser. CLI and CI tool. Supports import-rule DSL, cycle detection, dependency-graph visualization. Used in production at GitLab (config in the GitLab monorepo). Example rule:

```javascript
{
  name: "no-domain-to-infra",
  severity: "error",
  from: { path: "^src/domain" },
  to: { path: "^src/infrastructure" }
}
```

**NetArchTest (.NET).** https://github.com/BenMorris/NetArchTest. Same shape as ArchUnit for the .NET ecosystem. Fluent API for dependency rules in xUnit or NUnit tests.

**Python.** Less mature than the JVM or Ruby. Two options: **Modularize** (https://github.com/modularize/modularize, declarative package-boundary rules) and **import-linter** (https://github.com/seddonym/import-linter, ini-file rules enforced in CI). Custom AST-based checks in tools like Ruff or a dedicated pre-commit hook cover remaining gaps.

**Go.** No single dominant tool; the community uses combinations of `go list`, `golangci-lint` custom linters, and scripts against the output of `go mod graph`. Some teams use ArchUnit's Go port efforts; none has the maturity of the JVM ecosystem.

Example rules that apply across languages:

- **Module A must not depend on module B.** Protects bounded-context boundaries (DDD).
- **The domain layer must not depend on the infrastructure layer.** Protects Hexagonal / Clean Architecture.
- **The orders module may be imported by the api and workers modules; by no other.** Protects the public-API declaration of a module.
- **No cycles.** Catches the gradual devolution into a ball of mud.
- **No imports from tests into production code.** Catches the accidental-leak failure mode.

The rule of three: if the architecture has three module boundaries to protect, wire three dependency-conformance rules. One seeded violation in CI per rule validates that the rule fires. If the rule catches nothing, the rule is aspirational; rewrite to catch the class.

## 5. Data-ownership conformance

The antipattern: two services writing to the same database table. Named by Sam Newman as the distributed-monolith signature (RESEARCH-2026-04.md section 2.6). Enforcement shifts the antipattern from silent to loud.

Three enforcement options, ordered by strength.

**Schema grants (strongest).** In Postgres or MySQL, create a per-service database user; REVOKE write permissions on a table from every user except the one owned by the component the ADR says is the writer. The test runs at startup for each service: attempt to write to a forbidden table; expect a permission error; fail loudly if the write succeeds. Example:

```sql
REVOKE INSERT, UPDATE, DELETE ON TABLE orders FROM identity_service_user;
GRANT INSERT, UPDATE, DELETE ON TABLE orders TO orders_service_user;
```

The integration test at startup:

```python
def test_identity_cannot_write_orders():
    with pytest.raises(DatabaseError, match="permission denied"):
        identity_service_conn.execute("INSERT INTO orders (id, total) VALUES (1, 100)")
```

**Static analysis of write paths (medium).** For a service that does not use runtime grants (or a monolith with a shared user), parse the code for SQL statements and their target tables; assert that only the module the ADR lists as the owner issues writes. Tools: CodeQL for complex cases; simpler regex-based CI checks for the common case. The limitation: indirect writes through ORMs can escape regex, so pair with an integration test.

**Integration test (weakest, always useful).** Start a minimal system; stand up two components; have the non-owner attempt a cross-service write through the only reasonable path; assert the write fails. This catches the class of error even if the specific mechanism (grants, static analysis, ORM-level guards) changes.

The practical rule: at minimum, schema grants for the top 3-5 load-bearing entities (orders, payments, users, audit log). Every other table gets a looser grant; fitness-function effort concentrates on the highest-blast-radius tables.

## 6. NFR conformance

The PRD stated NFRs as targets; Step 6 of SKILL.md computed the latency, throughput, and availability chains; fitness functions keep the chains holding.

**Load tests in CI.** A k6 / Locust / Gatling script that drives the checkout endpoint at the PRD's target QPS; the CI job fails if p95 latency exceeds the budget. Runs nightly for cost reasons (load tests are expensive) and on PRs touching hot-path code.

**Synthetic probes.** Datadog, New Relic, Grafana Cloud, Checkly: a periodic request from a remote location to a production endpoint, asserting latency and success. Runs every 1-5 minutes; SLO alerts fire when the rolling window exceeds the budget.

**Contract tests for backward compatibility.** A test that fails when a schema change breaks the rollout window. Buf breaking-change detection for Protobuf; OpenAPI-diff for REST; Atlas for SQL migrations. Runs in CI on every PR that touches a schema.

**The observability crossover.** This category crosses into observe-ready's territory. The rule: **architecture-ready names the NFR fitness function and its threshold; observe-ready wires the alert, the dashboard, and the runbook.** ARCH.md cites the fitness function by name ("checkout p95 < 200ms at 1K QPS, sustained for 5 minutes"); observe-ready's SLO doc cites the same function and adds the alert rule. If there is no observe-ready session, architecture-ready's naming is what exists; downstream incident response will thank the author.

Example (SKILL.md Step 10 minimum):

```
Fitness function NFR-001: checkout p95 latency < 200ms at 1K QPS
Scope: the checkout POST endpoint.
Threshold: p95 < 200ms, sustained for 5 minutes at 1K QPS.
Runs: nightly load test in CI; synthetic probe every 5 minutes in production.
Tooling: k6 for the load test; Datadog synthetic probes for production.
Failure action: CI job fails, blocks merges to main; production probe fires PagerDuty.
Owner: the orders team.
ADR source: ADR-004 (checkout-latency-budget.md).
```

## 7. Trust-boundary conformance

The Step 7 trust-boundary map names four boundaries (network edge, authentication, authorization, tenant isolation). Fitness functions enforce each.

**Auth-middleware bypass lint.** An ESLint / golangci-lint / custom rule that fails if a route handler is defined outside the framework's auth middleware wrapper. Example for Express:

```javascript
// fails: a route declared outside `app.use(authMiddleware)`
app.get('/admin/dangerous', (req, res) => { ... });

// passes: route inside the middleware-wrapped router
authedRouter.get('/admin/dangerous', (req, res) => { ... });
```

**Tenant-isolation integration test.** Stand up the system with two tenants; authenticate as tenant A; attempt to read / write / delete tenant B's resources through every public endpoint; assert every attempt fails with 403 or 404. The test is parametrized across the API surface and runs in CI. This is the most load-bearing fitness function in any multi-tenant architecture; a breach here is catastrophic (RESEARCH-2026-04.md section 5.6, Atlassian 2022 identifier-polymorphism failure; RESEARCH-2026-04.md section 5.1, Knight Capital shared-binary failure as the same shape at a lower layer).

**Policy-as-code.** OPA (Open Policy Agent) or Cedar (AWS) lets authorization policies be expressed in a dedicated language and tested with unit tests. A fitness function is then: every mutation on a resource goes through the policy evaluator; policy tests cover the role / resource / action matrix; CI fails if coverage drops. Grounds the authorization boundary in a testable artifact.

**The rule.** Trust-boundary fitness functions are mandatory for Tier 3 in regulated domains (HIPAA / PCI / SOC 2); they are strongly recommended for Tier 2 in multi-tenant systems. The production-ready skill's Step 2 threat model consumes Step 7 of architecture-ready; the fitness functions close the loop from "we named the boundary" to "we enforce the boundary."

## 8. Where fitness functions run

Four enforcement loops; pick the tightest one that catches the failure class.

**CI (per PR, per push).** Blocks merges. The default for dependency conformance, schema-drift detection, security conformance, and contract conformance. Pros: catches drift before it ships. Cons: slow checks (load tests, full integration suites) cannot run on every PR; some will move to nightly.

**Nightly.** Runs on the main branch against a staging environment. The default for load tests and expensive integration tests (the full tenant-isolation sweep across every endpoint, for example). Pros: catches drift within 24 hours. Cons: drift has already landed in main; remediation requires reverts or hotfixes.

**Runtime.** Synthetic probes against production; SLO alerts in observability tooling; runtime policy evaluators (OPA sidecar). The default for NFR conformance and for trust-boundary enforcement at request time. Pros: catches drift at the moment it manifests in user-visible behavior. Cons: drift reaches production first; fitness function is detective, not preventive.

**Preview / staging.** Runs on pre-production environments as part of the deploy pipeline. Default for load tests too expensive to run on every PR and for integration tests that require a deployed system (cross-service contracts, real-DB grants). Pros: catches drift before production; more realistic than unit tests. Cons: longer feedback loop than CI.

**Per category, pick the tightest loop that catches the class of failure.** Dependency conformance belongs in CI (drift appears in one PR). NFR conformance belongs in runtime (drift appears under real load). Trust-boundary conformance belongs in both: static CI checks for middleware bypass; runtime policy evaluation for request-time enforcement.

## 9. Adoption pragmatics

Fitness functions die when they are aspirational; they live when they block merges. The pragmatics below are drawn from Shopify / GitLab / InfoQ case studies (RESEARCH-2026-04.md section 8.3) and from the Ford / Parsons / Kua / Sadalage 2023 guidance.

**Start with one. Name it. Wire it. Fail a build on a seeded violation.** The seed-violation step is the practical proof that the function works: add a line of code that should violate the rule; confirm the CI job fails; remove the line; confirm the CI job passes; commit both commits as evidence. Without the seeded violation, the function is theater; the Step 10 have-nots list refuses "named but not wired" as the Tier 3 disqualifier.

**Then add more.** Start with dependency conformance (highest leverage, cheapest to wire). Add data-ownership next if the architecture has multiple writers risk. Add NFR conformance third, once the team has load-testing infrastructure. The sequence matters: wiring all eight categories at once produces a brittle test suite that everyone bypasses; adding one at a time each with a seeded-violation proof produces a suite the team trusts.

**Rewrite to catch the class, not the instance.** A fitness function that catches one specific case of the failure is too strict; it will flag refactors that do not violate the architectural intent. Rewrite to catch the class: instead of "Module A must not call `OrderService.createOrder`," write "Module A must not depend on `orders.*`." The class-level rule survives refactors; the instance-level rule does not.

**Fitness functions that catch business logic are not fitness functions.** The scope discipline from Section 2: fitness functions guard architectural invariants, not business rules. If a fitness function is failing because the business logic changed (new discount type, new tax jurisdiction, new user role), the function is mis-scoped; move it to the regular test suite and let the architectural invariant stay in the fitness-function suite.

**Build the supersession discipline alongside.** When a fitness function catches a drift that should be allowed (the architecture legitimately changed), the fix is to supersede the ADR and update the fitness function, not to delete the fitness function silently. The ADR supersession chain (SKILL.md Step 13 change classification) and the fitness-function evolution are the same practice; drift-with-no-update is the pathology.

## 10. Anti-patterns

Three anti-patterns specific to fitness-function practice. Each appears in the SKILL.md have-nots list at Tier 3.

**(a) Fitness functions named but never wired.** The Tier 3 disqualifier in SKILL.md. An ARCH.md that lists "ArchUnit for module boundaries, load tests for latency, integration tests for tenant isolation" with no pointer to a running CI job or a commit that proves the function exists is theater. The remediation: wire one; seed one violation; show the commit. Tier 3 fails until the evidence is in the repo.

**(b) Fitness functions so strict no one can ship.** The opposite pathology. A dependency-conformance rule that forbids any import across module boundaries, including the ones the API exposes; a data-ownership rule that includes audit-log tables written by every service; an NFR rule that fires on p99 spikes during deploys. The team routes around the rule (override flags, `// eslint-disable`, `// archunit-ignore`), and once routing-around is normal, every rule is bypassable. The remediation: rewrite to catch the class, not the instance; audit the override-annotation count monthly (a high count is the tell).

**(c) Fitness functions catching business logic (not architectural).** A test labeled "fitness function" that asserts "orders with negative quantity return 400" is business logic in the wrong folder. It dilutes the fitness-function suite, confuses the architecture conversation, and its failures do not map to ADRs. Remediation: move it to the regular test suite; keep fitness functions scoped to invariants named in ADRs.

**(d, extended) No supersession discipline on ADRs.** Adjacent pathology: the ADR behind the fitness function is superseded; the fitness function is not updated; CI fires on the new legitimate code. Engineers start treating the CI failure as noise. The fitness-function suite erodes into "CI job that fails sometimes; override as needed." Remediation: every ADR change is paired with a fitness-function diff; `adr link N supersedes M` (adr-tools) triggers a fitness-function review by the tech lead.

End of evolutionary-architecture.md.
