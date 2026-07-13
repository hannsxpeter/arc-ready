# Product-Form Router

Select product form before domain. Product form defines how users operate the software, what a vertical slice means, which project profile applies, and which completion evidence is valid. Domain composition adds product and industry constraints after this decision.

## Routing procedure

1. Inventory the primary user interaction and distribution channel.
2. Pick one primary form. Record secondary forms only when they have independent deliverables.
3. Load the linked section of `references/building/project-profiles.md`.
4. Apply product archetype, industry, and regulatory overlays from `references/building/domain-registry.md`.
5. Use the common Tier 2 discipline plus the form-specific build gate below.

Do not infer web application merely because the request says product, platform, tool, or dashboard. Do not infer infrastructure merely because the repository contains YAML.

## Common vertical-slice discipline

Every form ships user-operable increments with real integration boundaries and production-shaped fixtures. The translation differs by form:

| Form | A vertical slice means |
|---|---|
| Web application | Persistence or external source -> service and permission boundary -> API or server action -> UI states -> tests |
| API or service | Contract -> validation and authorization -> domain operation -> persistence or dependency -> telemetry -> contract and integration tests |
| CLI or SDK | Public command or API -> parsing and validation -> domain operation -> output or return contract -> consumer fixture -> cross-platform tests |
| Mobile or desktop | Native interaction -> local state -> sync or service boundary -> offline and recovery states -> device or platform tests |
| Data or ML | Versioned input -> validated transform or training step -> reproducible output -> quality evaluation -> lineage and operational checks |
| Infrastructure or IaC | Versioned configuration -> static validation -> plan -> policy check -> isolated apply or simulation -> rollback or destroy proof |

Real backend discipline applies when the product has a backend. It does not require inventing one for a local-only CLI, embedded SDK, offline desktop utility, notebook workflow, or declarative module.

## Web application

**Signals:** Browser-delivered UI, authenticated portal, SaaS surface, dashboard, customer or admin console.

**Project profile:** `references/building/project-profiles.md`, section 3.3 Web App (SaaS). Pull API requirements from section 3.4 when the web product exposes a public contract.

**Build concerns:** Route and information architecture, loading/empty/error/success states, authorization at API boundaries, accessibility, real data, browser security, responsive behavior, and user-journey telemetry.

**Completion gate:** At least one roadmap-grounded job works from user action through real data and back, all relevant UI states exist, permission checks are server-side, accessibility checks pass for the slice, and unit, integration, and browser tests are green.

## API or service

**Signals:** Headless service, HTTP or RPC contract, event consumer, worker, internal microservice.

**Project profile:** `references/building/project-profiles.md`, section 3.4 API / Microservice.

**Build concerns:** Versioned contract, idempotency, authentication and authorization, validation, timeouts, retry budgets, dependency failure behavior, health endpoints, structured telemetry, migrations, and consumer compatibility.

**Completion gate:** A real consumer fixture completes one contract path against real dependencies or faithful local substitutes, schema and error responses are tested, retries are bounded and idempotent where required, health and telemetry are observable, and contract plus integration tests are green.

## CLI or SDK

**Signals:** Terminal command, globally installed tool, package consumed by developers, language SDK, embeddable library.

**Project profiles:** `references/building/project-profiles.md`, sections 3.1 Library / SDK and 3.2 CLI Tool. If both exist, record separate public contracts and distribution paths.

**Build concerns:** Stable command or API surface, exit codes and error types, configuration precedence, deterministic output, shell completion where warranted, package metadata, examples, compatibility matrix, semantic versioning, and cross-platform distribution.

**Completion gate:** A clean consumer fixture installs the package or binary, completes the primary job without repository internals, receives documented errors for invalid input, examples compile or execute, supported runtime or OS checks pass, and the release artifact can be built reproducibly.

## Mobile or desktop

**Signals:** App-store distribution, native device capability, offline client, signed installer, Electron or Tauri application.

**Project profiles:** `references/building/project-profiles.md`, sections 3.5 Mobile App and 3.6 Desktop App.

**Build concerns:** Platform navigation, lifecycle and background behavior, local persistence, synchronization and conflict rules, offline states, permissions, secure storage, accessibility, crash reporting, signing, update strategy, and store or installer metadata.

**Completion gate:** A signed or development build runs on every declared platform class, the primary job survives lifecycle transitions and the declared connectivity model, secrets use platform storage, accessibility and device tests pass, crash telemetry is wired, and install or store packaging is reproducible.

## Data or ML

**Signals:** Dataset pipeline, analytics engineering, model training, inference service, notebooks, feature or evaluation pipeline.

**Project profile:** `references/building/project-profiles.md`, section 3.8 Data / ML. Add section 3.4 when an inference or data API is a separate service.

**Build concerns:** Dataset provenance, schemas and quality rules, versioned transforms, reproducible environments, experiment tracking, evaluation thresholds, leakage and bias checks, model and data cards, artifact registry, lineage, drift monitoring, and cost.

**Completion gate:** A clean environment reproduces one pipeline or model artifact from versioned inputs, quality and evaluation thresholds are explicit and pass, lineage identifies code, data, and configuration versions, fixtures contain no unauthorized sensitive data, and serving behavior is tested when serving is in scope.

## Infrastructure or IaC

**Signals:** Terraform or OpenTofu module, Kubernetes package, Ansible automation, cloud platform configuration, deployment foundation.

**Project profile:** `references/building/project-profiles.md`, section 3.7 DevOps / IaC.

**Build concerns:** State handling, secret exclusion, module inputs and outputs, provider and tool pinning, policy as code, environment separation, least privilege, drift detection, plan review, rollback, disaster recovery, and cost impact.

**Completion gate:** Formatting and static validation pass, an isolated plan is reviewed, policy checks pass, a sandbox apply or faithful simulation proves the main path, destructive behavior is guarded, state and secrets are protected, and rollback or destroy is exercised and documented.

## Secondary forms

A product may include multiple forms, such as a web console plus public SDK or a data pipeline plus inference API. Keep one primary form for Tier 2 sequencing. Create a secondary-form slice only when it has its own user, contract, distribution path, and completion evidence. Shared architecture and stack choices stay grounded in the same upstream artifacts.
