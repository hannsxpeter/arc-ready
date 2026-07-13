# 36. Developer Platform / API / SDK

**Taxonomy role:** Product archetype, not an industry.

**Archetype:** Developers integrating through APIs, SDKs, CLIs, webhooks, credentials, sandboxes, and a control-plane console.

**Core entities:** Organization, Project, Environment, API Credential, Service Account, Permission Scope, API Version, SDK Release, Webhook Endpoint, Usage Event, Quota, Integration, Audit Event

**Domain landmines:** Documentation and implementation drift; retries create duplicate side effects; sandbox behavior differs from production; API keys lack scopes or rotation; pagination and rate-limit contracts are inconsistent; webhook delivery lacks signatures, ordering semantics, and replay; SDKs diverge by language; breaking changes ship without migration windows; examples compile only inside the source repository.

**Compliance and freshness caveat:** Security, privacy, export, and retention duties follow the data handled by integrations. Verify current authentication standards, provider limits, package-registry requirements, and deprecation policies. Never treat an SDK wrapper as a substitute for a versioned service contract.

**Expected developer experience:** Five-minute quickstart, self-service credentials and sandbox, copyable tested examples, searchable API reference, webhook inspector and replay, usage and quota visibility, changelog, deprecation notices, status page, and consistent errors across SDKs.

**Test and fixture shape:** External consumer repositories per supported language, contract fixtures, idempotency collisions, pagination boundaries, rate-limit responses, credential rotation, webhook signature and replay cases, sandbox-to-production promotion, and compatibility tests across supported versions.

**Stack mapping:** Start with `SaaS / Multi-tenant` in `references/planning/domain-stacks.md` for the control plane. Use API / Microservice plus Library / SDK and CLI project profiles as applicable. Add an industry overlay only when the platform itself encodes industry rules.
