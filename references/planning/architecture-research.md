# Architecture Research

The Step 0 protocol. Load at the start of every architecture-ready session. Lighter than [RESEARCH-2026-04.md](RESEARCH-2026-04.md), which is the full 35K-token dossier; this file is ~5K tokens and supports mode detection, load-bearing triage, and the canonical-sources index.

**Scope owned by this file:** mode detection (A through F), the research block each mode writes into STATE.md, the architecture-load-bearing quick check, the 2026 industry posture in three paragraphs, the canonical-sources index, staleness triggers, AI-slop architecture signature, and the ARCH.md / HANDOFF.md output schema. Deep reasoning on each lives in the topical reference files and in RESEARCH-2026-04.md.

## 1. Mode detection protocol

Run this decision tree at Step 0 of every session. Declare the mode in writing before proceeding to Step 1.

```
Start
 |
 +-- Does `.architecture-ready/ARCH.md` already exist?
 |    |
 |    +-- No  -> Is there a running codebase (any non-trivial `src/`, `app/`, `packages/`)?
 |    |        |
 |    |        +-- No  -> Mode A (Greenfield)
 |    |        +-- Yes -> Mode B (Assessment: retroactive ARCH.md from reality)
 |    |
 |    +-- Yes -> Was it produced by an AI tool, never human-reviewed?
 |             |
 |             +-- Yes -> Mode C (Theater audit; Step 1.5 before Step 1)
 |             +-- No  -> Is the system visibly broken or mid-rearchitecture?
 |                      |
 |                      +-- Broken post-ship        -> Mode F (Rescue)
 |                      +-- Planned material change -> Mode E (Evolution)
 |                      +-- None of the above       -> Mode D (Iteration / refresh)
```

Detection questions to ask (or infer from input and filesystem):

1. Does `.prd-ready/PRD.md` exist? If yes, read it; if no, warn the user and proceed only with explicit PRD-equivalent assumptions inline. Architecture without a PRD is guessing; this is the have-nots list item "architecture without a PRD."
2. Does `.architecture-ready/ARCH.md` exist? If yes, was it produced by an AI tool in a single prompt with no human editing? A tell: every section is filled, no section has an open question, no ADR names an alternative that was rejected for a PRD-specific reason.
3. Is there a running codebase? If yes, the architecture-as-implemented exists whether or not ARCH.md exists. Mode B produces a retroactive description of reality.
4. Is the user asking to refresh, rearchitect, or diagnose? "Refresh" is D. "Rearchitect" is E. "Diagnose" is F.

Detection anti-patterns to refuse:

- Skipping Step 0 and proceeding as if the mode were A by default. A is a decision, not a default.
- Declaring Mode D when ARCH.md was AI-generated and no one has ever approved it; that is Mode C.
- Declaring Mode B when the codebase is trivial (one file, no integrations, no trust boundaries). Run the load-bearing check first; Mode B on a trivial codebase usually becomes "architecture is not load-bearing, stop here."

## 2. Research blocks per mode

Each mode produces a STATE.md block at Step 0. Templates below; one paragraph each; fill with project specifics.

### Mode A (Greenfield)

```
Mode: A (Greenfield)
Why this mode: no prior ARCH.md; the PRD exists (or is being written) and the team is designing the system shape from scratch.
Starting artifact: .prd-ready/PRD.md [exists / absent, warned].
Expected tier destination: Tier 1 (Sketch) mandatory; Tier 2 (Contract) expected before build starts; Tier 3 (Living) after first ship.
Key risks for this mode: cargo-cult cloud-native defaults (K8s + Kafka for a 10-user app), premature microservices without a forcing function, stackitecture (tool picks masquerading as architecture), horoscope architecture (prose that reads plausibly for any product). See RESEARCH-2026-04.md sections 1.1, 1.2, 2.3, 2.4.
Mitigations: default to modular monolith unless a forcing function applies; pick shape before stack; apply the substitution test to every ADR.
```

### Mode B (Assessment)

```
Mode: B (Assessment)
Why this mode: an existing codebase has an architecture-as-implemented that was never written down; the ask is a retroactive ARCH.md that matches reality.
Starting artifact: the codebase; .prd-ready/PRD.md optional (retroactive PRDs are common here).
Expected tier destination: Tier 1 for the retroactive snapshot; Tier 2 once gaps between intent and implementation are reconciled.
Key risks for this mode: writing the architecture the team wishes it had rather than the one that runs in production (ghost architecture; RESEARCH-2026-04.md section 2.10); missing undocumented coupling (distributed monolith hiding in the shape; RESEARCH-2026-04.md section 2.6); accidentally promoting accidental architecture to Accepted without critique (RESEARCH-2026-04.md section 2.9).
Mitigations: run the codebase-shape scan before Step 1; name every piece of coupling the code actually has, not the coupling the team intended; flag divergences as open questions with owners.
```

### Mode C (Theater audit)

```
Mode: C (Theater audit)
Why this mode: a prior AI-generated ARCH.md exists and fails the core principle (every box, arrow, ADR is a decision with a flip point). The ask is fix-before-ship.
Starting artifact: the existing ARCH.md; quote at least one failing element before proceeding.
Dominant failure mode (name one): architecture theater / paper tiger / cargo-cult cloud-native / stackitecture / resume-driven / horoscope. See RESEARCH-2026-04.md section 2 for the full named-term table and section 1 for symptoms.
Expected tier destination: rewrite to Tier 1 first; do not layer additions on top of theater.
Key risks for this mode: partial rewrites leaving theater in low-traffic sections (trust boundaries, NFR numbers, fitness functions are the usual survivors of AI-slop); writing on top of the existing doc rather than starting from the load-bearing check.
Mitigations: Step 1.5 audit before Step 1; quote every failing section; rewrite from the pre-flight answers up, not from the existing prose.
```

### Mode D (Iteration / refresh)

```
Mode: D (Iteration / refresh)
Why this mode: an approved ARCH.md exists; the system evolved; the doc needs to catch up without silent revisionism.
Starting artifact: the existing ARCH.md plus the ADR directory.
Expected tier destination: same tier as the existing doc, or one higher if refresh expands scope.
Key risks for this mode: silent edits that hide decision reversals (the moving-target failure); stacking new requirements on stale no-gos; losing historical rationale by rewriting ADRs in place instead of superseding them.
Mitigations: every edit logs to the changelog; every decision reversal is a new ADR with `Superseded by ADR-MMM` and the old ADR retained; broadcast the change to engineering.
```

### Mode E (Evolution / rearchitecture)

```
Mode: E (Evolution / rearchitecture)
Why this mode: a material change is planned (monolith to services, services to modular monolith, sync to async, region to cell-based). The current architecture is the "from" state; a new ARCH.md is the "to" state.
Starting artifact: current ARCH.md plus the rearchitecture trigger (what forced it: scale, team, cost, compliance, outage).
Expected tier destination: Tier 2 minimum for the "to" ARCH.md before any code moves; Tier 3 once fitness functions for the new shape are wired.
Key risks for this mode: rearchitecting without a forcing function (resume-driven rearchitecture; see RESEARCH-2026-04.md section 2.5); partial migrations that leave a distributed monolith (RESEARCH-2026-04.md section 2.6); deleting the old ARCH.md instead of keeping both linked.
Mitigations: fork the ARCH.md (from-state plus to-state, both live); produce an evolution plan with fitness functions on the transition; cite the public migration precedent if one applies (Prime Video audio monitoring 2023, Segment 2018, Istio 2020; RESEARCH-2026-04.md section 4.1).
```

### Mode F (Rescue)

```
Mode: F (Rescue)
Why this mode: the architecture shipped; the system is misbehaving in a way traceable to the architecture (cascading failure, storage-shape mismatch, blast-radius surprise, boundary breach, identifier-polymorphism bug).
Starting artifact: the existing ARCH.md (if any), the incident / outage / symptom, and the running system.
Dominant architectural root cause (name one): distributed monolith / shared-database-for-writes / synchronous-chain-under-burst / missing-trust-boundary / storage-shape-wrong / no-cell-isolation / observability-shares-fate-with-system. See RESEARCH-2026-04.md section 5 for precedent outages (Knight Capital, S3, Cloudflare WAF, Facebook BGP, GitLab DB, Atlassian deletion, Roblox Consul, Crowdstrike).
Expected tier destination: Tier 2 for the remediation plan; Tier 3 once the fitness function catching this class of failure is wired.
Key risks for this mode: patching the symptom (a retry here, a queue there) without rearchitecting the root cause; treating the rescue as an incident response rather than an architecture decision.
Mitigations: name the architectural root cause in writing before proposing remediation; write an ADR for the remediation with a flip point and blast-radius field; wire the fitness function that would have caught this before Tier 3 is claimed.
```

## 3. The architecture-load-bearing quick check

Before running the full skill, answer the load-bearing check. Deep version in [system-shape.md](system-shape.md) Section 1; this summary supports the Step 0 triage.

Architecture is load-bearing if **any** of these are true:

1. More than one persistence layer is in play (DB plus queue, DB plus event log, DB plus object store, DB plus load-bearing cache).
2. More than one deployable service is in play.
3. A third-party integration is load-bearing in a failure mode (Stripe, Twilio, partner API).
4. A non-functional target in the PRD constrains the shape (tight p95, compliance carve-out, data-residency rule, strong-consistency requirement on a hot path).
5. The team is larger than two engineers and will grow (Team Topologies; Conway's Law; RESEARCH-2026-04.md section 3.8).
6. The product will live longer than 12 months under maintenance by people other than the original authors.

Architecture is **not** load-bearing if all of these are true: one engineer, one service, one database, no partner integration, no compliance constraint, appetite under eight weeks, no team-growth intent, no post-launch maintenance intent. Single-file scripts, one-off automations, throwaway landing pages, toy personal projects: skip the skill.

If the check fails (none of the six load-bearing criteria are met), write a one-page minimal ARCH.md covering only system shape, data shape, and trust boundary, declare the skill stopped, and refer the user to production-ready for the build.

If the check passes, proceed to Step 1's 8 pre-flight questions.

## 4. Industry posture summary (2026)

Three paragraphs. Pointer list at the end; full treatment in RESEARCH-2026-04.md section 4.

**Modular-monolith resurgence. Microservices backlash. Evidence, not slogans.** Shopify runs a 2.8M-line Ruby modular monolith with 4000+ internal components enforced by Packwerk (RESEARCH-2026-04.md section 4.1 and section 8.3). GitHub remains a single Rails application since 2008. Stack Overflow serves the internet from nine web servers and one SQL Server plus hot standby (Nick Craver, 2016 baseline, still accurate in 2024). Amazon Prime Video's audio-quality monitoring service consolidated a specific distributed pipeline into a monolith in March 2023 and reported a 90% cost reduction; widely mis-cited as "Amazon abandoned microservices," read the post directly before citing (section 4.1). Segment consolidated microservices to a monolith in 2018. Istio merged its control-plane microservices back to a single binary in 2020. ThoughtWorks has held microservices at "Trial" not "Adopt" on the Tech Radar since 2018 (section 4.7). The 2015-2021 "microservices by default" posture is over; the default in 2026 is modular monolith unless a forcing function applies (team size greater than ~20, independent scaling curve, or a regulatory boundary that forces separation).

**Serverless matured, edge-native won reads, event-driven cooled, cell-based emerged.** Serverless (Lambda, Cloudflare Workers, Vercel) is the right shape for bursty, event-driven, sparsely-triggered workloads; wrong for sustained-load APIs, long-running workflows, and heavy-state applications. Cold starts stay under 1% of requests for most workloads (AWS, 2024; section 4.2) but the latency tail still matters for sub-100ms p99 targets. Edge compute has won for geographically-sensitive read-heavy workloads; Cloudflare Workers, Deno Deploy, and Vercel Edge Functions are the practical choices (section 4.3). Greenfield event-driven adoption cooled after the 2018-2021 peak: teams now reach for SQS/Pub-Sub/RabbitMQ for point-to-point async and Kafka only when they need the log (section 4.4). Event sourcing applied to a whole system is itself an antipattern (InfoQ 2016, Kiehl 2024; section 4.5). Cell-based architecture (partitioned independent replicas) is the 2024-2026 resilience answer; AWS re:Invent 2024 ARC312 / ARC335 are the canonical refs (section 4.6). Cells are orthogonal to microservices: a cell can be a monolith.

**The AI-slop architecture document has a signature.** LLMs produce plausible-looking ARCH.md documents that collapse under light technical questioning (Pragmatic Engineer 2025; Haryanto 2024; section 1.8). The signature is nine items: components listed with no rationale, C4 vocabulary used without C4 discipline, "scalable/highly available/fault-tolerant" claimed with no numbers, tools picked by training-data frequency (Kafka for any event, Redis for any cache, Postgres for any data, Kubernetes for any deployment), no "alternatives rejected" section, no NFR numbers, no trust boundaries, no failure modes named, no fitness functions. See Section 7 below and RESEARCH-2026-04.md sections 1.8 and 11 for the full refusal target.

Pointers: RESEARCH-2026-04.md sections 4.1 (monolith resurgence), 4.2 (serverless), 4.3 (edge), 4.4 (event-driven), 4.5 (event sourcing / CQRS), 4.6 (cell-based), 4.7 (microservices backlash), 4.8 (Hexagonal / Clean critiques).

## 5. Canonical sources to pull in when needed

Short pointer list. Full citations and URLs in RESEARCH-2026-04.md sections 3 and 10.

- **Richards / Ford, "Fundamentals of Software Architecture," 2nd ed (2024).** The structural reference; architectural characteristics, trade-off analysis. RESEARCH-2026-04.md section 3.1.
- **Ford / Parsons / Kua / Sadalage, "Building Evolutionary Architectures," 2nd ed (2023).** Fitness functions, incremental change, appropriate coupling. RESEARCH-2026-04.md section 3.2. Central to Step 10; see [evolutionary-architecture.md](evolutionary-architecture.md).
- **Ford / Richards / Sadalage / Dehghani, "Software Architecture: The Hard Parts" (2021).** Trade-off analyses for distributed architectures: granularity, workflow orchestration, contracts, distributed transactions. RESEARCH-2026-04.md section 3.3.
- **Kleppmann, "Designing Data-Intensive Applications," 1st ed (2017); 2nd ed with Riccomini GA January 2026.** The data-architecture canon: storage engines, replication, partitioning, consistency, stream processing. RESEARCH-2026-04.md section 3.10. Central to Step 4.
- **Nygard, "Documenting Architecture Decisions" (2011).** The ADR template. RESEARCH-2026-04.md section 3.4 and section 7.1. Central to Step 8; see [adr-discipline.md](adr-discipline.md).
- **Brown, C4 model (c4model.com) and "The C4 Model" (2024 book).** Context / Container / Component / Code. Misuses catalog documented by Brown at GOTO 2024. RESEARCH-2026-04.md sections 3.5 and 7.3. Central to Step 9; see [diagrams.md](diagrams.md).
- **Skelton / Pais, "Team Topologies" (2019).** Team-shape / software-shape co-determination; four team types; three interaction modes. RESEARCH-2026-04.md section 3.8. Grounds Step 2 and Step 3 decisions that depend on team size.
- **Hohpe / Woolf, "Enterprise Integration Patterns" (2003).** The vocabulary for async-messaging architecture: channels, endpoints, routers, transformers, correlation IDs. RESEARCH-2026-04.md section 3.12. Central to Step 5.
- **Helland, "Life beyond Distributed Transactions" (CIDR 2007); "Immutability Changes Everything" (ACM Queue 2015).** The foundation for modern distributed-data architecture. Read before picking event sourcing or CQRS. RESEARCH-2026-04.md section 3.11.
- **Evans, "Domain-Driven Design" (2003); Vernon, "Implementing DDD" (2013).** Bounded contexts, ubiquitous language, aggregates. Central to Step 3 component-boundary decisions. RESEARCH-2026-04.md section 3.13.
- **Foote / Yoder, "Big Ball of Mud" (PLoP 1997).** The original characterization of haphazard architecture. Historical anchor; still cited weekly. RESEARCH-2026-04.md section 3.13.
- **Shostack, "Threat Modeling: Designing for Security" (2014).** The threat-modeling canon; architecture-ready produces the trust-boundary inputs that downstream threat models consume. Full citation in RESEARCH-2026-04.md section 3.13 / 10 (production-ready pairs with it).
- **Newman, "Monolith to Microservices" (2019).** The "MonolithFirst" discipline; the canonical definition of the distributed monolith failure mode. RESEARCH-2026-04.md section 1.1.

Tooling (fitness functions, ADR, diagramming): ArchUnit, dependency-cruiser, Packwerk, NetArchTest; adr-tools (Pryce and Henderson forks), log4brains; Structurizr, Mermaid, PlantUML, D2. URLs in RESEARCH-2026-04.md section 10.

## 6. Staleness triggers

The four dimensions most likely to drift between skill versions. Link to SKILL.md Step 14.

- **Cloud-vendor primitives.** Managed databases, edge runtimes, serverless limits, multi-region primitives change quarterly. Lambda cold-start numbers, Workers CPU time, Neon / PlanetScale / Turso availability, Durable Object semantics: any of these shifting can re-shape a Step 2 decision. If the skill version is more than six months old, assume the serverless / edge section of RESEARCH-2026-04.md is partially stale.
- **Monolith-vs-microservices sentiment.** This moved materially between 2014 (microservices emerging), 2020 (default), and 2026 (backlash / modular-monolith resurgence). Any skill version older than 12 months likely underweights the modular-monolith default.
- **Event-streaming tooling.** Kafka still dominates, but Redpanda (Go-native, no JVM) and WarpStream (S3-backed, stateless brokers) changed the cost curve in 2023-2025. If the Step 5 integration-architecture section reads "use Kafka" as a default, that is a staleness tell.
- **Fitness-function tooling.** ArchUnit, dependency-cruiser, Packwerk are stable; newer entrants (Modularize for Python, ts-arch, fitness-function-as-a-service platforms) emerged 2023-2026. See [evolutionary-architecture.md](evolutionary-architecture.md) Section 4 for the current production-proof list.

Staleness trigger action: at the end of the run (SKILL.md Step 14), print the skill version, the last-updated date, and today's date. If the version is older than 6 months, warn explicitly and list the four dimensions above.

## 7. Pitfalls specific to AI-generated architecture

Three paragraphs distilled from RESEARCH-2026-04.md section 1 (complaints and failure modes) and section 8 (fitness-function gap). This is the refusal target for Mode C and the banned-phrase filter for Modes A and B.

**The signature of LLM slop architecture. Components listed with no rationale.** The doc renders a C4 container diagram with eight boxes; each box has a name; none has a why. The "Auth Service" is there because auth services are in the training corpus, not because the PRD's identity boundary forced a separation. The "Notification Service" exists because notification services exist in every example, not because the PRD's delivery-guarantee requirements demand an independent deployable. The "API Gateway" is drawn because it looks sophisticated, not because the PRD has cross-cutting rate-limiting or routing needs that justify the extra hop. Substitution test: replace every component name with a generic placeholder (Component-1, Component-2). If the rationale still reads plausibly, the rationale was horoscope (section 2 of [architecture-antipatterns.md](architecture-antipatterns.md)). Every component must name the PRD number, entity, or NFR that justifies its separation; components without that naming are decoration.

**"Scalable" without numbers. Patterns picked by training-data frequency. No trust boundaries. No failure modes. No rejected alternatives.** LLMs overfit to training-data frequency: Kafka appears in high-scale blog posts, so any event need gets Kafka; Kubernetes appears in Medium tutorials, so any deployment gets Kubernetes; microservices appears next to "scalable," so any system that wants to sound scalable gets microservices. The fixes are the fixed steps: the Step 6 NFR math check (every "scalable" gets a number or a deletion), the Step 7 trust-boundary map (four named boundaries with all four attributes), the Step 8 ADR discipline (every decision has alternatives-rejected). See Korokithakis 2015 "microservices cargo cult"; Thoughtworks Radar "layered microservices architecture" antipattern; RESEARCH-2026-04.md sections 1.2 and 1.4. The banned-phrase filter in SKILL.md's have-nots list catches the surface-level tells; the Step 1.5 audit in Mode C catches the deeper ones.

**No trust boundaries. No failure modes. No rejected alternatives.** The three omissions most frequently seen in AI-generated ARCH.md documents. The trust-boundary section is either missing or three words ("auth, authz, encryption"); the document never says where tenant data isolates from other tenants' data, how an authenticated user is scoped to a specific resource, or what an attacker gains if the boundary falls. Failure modes are absent: every integration is described as if it always succeeds; no circuit breaker is configured; no dead-letter queue; no idempotency discipline; no compensation. Rejected alternatives: the ADR has a Decision and a Rationale but no "Alternatives considered and rejected"; the reader cannot tell whether the author weighed any option or picked the first plausible one. The refusal: if these three sections are absent or thin in Mode C, mark the entire document as theater and rewrite from the pre-flight answers up. RESEARCH-2026-04.md section 1.8 catalogs the signature; SKILL.md's have-nots list refuses it.

## 8. Artifact schema summary

ARCH.md and HANDOFF.md must produce these sections. This is a pointer at the fuller SKILL.md Step 11 content; use it to check work, not to replace the SKILL.md read.

### ARCH.md required sections

1. **Skill version.** architecture-ready NNN, YYYY-MM-DD.
2. **Upstream inputs consumed.** Copied from `.prd-ready/HANDOFF.md` "Architecture-ready inputs" sub-section.
3. **System shape.** One of: single-service monolith / modular monolith / service-oriented / microservices / event-driven / serverless / edge-native. ADR-001 with rationale, flip point, blast radius, alternatives rejected.
4. **Component breakdown.** Per component: bounded context, one-sentence responsibility, interface (sync/async + protocol + idempotency posture), data ownership (one writer per entity), dependencies (for the component dependency graph), failure posture.
5. **Data architecture.** Per entity group: tenancy model, lifecycle, storage shape (relational / document / key-value / time-series / event-log / search / graph / object), consistency and invariants. Database brand is stack-ready's job, not this section's. ADR-002 for non-obvious storage-shape choices.
6. **Integration architecture.** Per integration: sync or async, transport (REST / gRPC / event log / queue / webhook), idempotency posture (key, retry policy, dedup window), failure mode (circuit breaker / DLQ / graceful degradation / hard failure).
7. **Non-functional architecture.** Latency chain, throughput chain, availability chain; each computed to the PRD's target. Resource envelope, cost envelope, data-residency posture.
8. **Trust boundaries.** Four boundaries: network edge, authentication, authorization, tenant isolation. Per boundary: where it sits, what it protects, what an attacker gains if it falls, how it is enforced (defense-in-depth for load-bearing). Highest-blast-radius mutations explicitly named. ADR-003.
9. **Diagrams.** C4 Level 1 (Context) for Tier 1; Level 2 (Container) for Tier 2; Level 3 (Component) for architecturally-weighty bounded contexts at Tier 2. Text-format (Mermaid / PlantUML / Structurizr DSL / D2). Every arrow labeled with protocol and purpose.
10. **Evolutionary architecture.** At least three fitness functions: dependency conformance, data-ownership conformance, NFR conformance. Tooling named; enforcement point (CI / nightly / runtime) named. At Tier 3, at least one wired.
11. **ADR corpus.** `.architecture-ready/adr/NNN-slug.md`. Minimum ADR-001 (shape), ADR-002 (storage shape), ADR-003 (trust boundaries), plus one per load-bearing integration.
12. **Rejected shapes.** Three alternative system shapes considered and why each lost. Prior-art section (Tier 2): three comparable public systems that informed the architecture.
13. **Open questions.** Each with owner and due date. Unowned open questions fail the tier.
14. **Changelog.** Dated entries per edit; superseded-ADR chain preserved.

### HANDOFF.md required sub-sections

1. **To stack-ready:** storage shapes (not brands), compute shapes, integration shapes (sync/async + idempotency), NFR numbers, hard constraints (data-residency, compliance, self-host posture).
2. **To roadmap-ready:** component dependency graph (nodes + edges + critical path), load-bearing-first ordering, risk-ordered items, evolution plan (Mode E only).
3. **To production-ready:** system shape (ADR-001 title and one-paragraph decision), component boundaries, trust boundaries (copied from Step 7 wholesale), data-model shape, integration shapes, NFR targets, pointers to ADR directory and fitness functions.

HANDOFF.md reads standalone; a downstream skill consumes its sub-section without opening ARCH.md to make its own pre-flight work. If a sub-section is deferred (because an upstream answer is still open), the deferral is explicit with owner and due date; silent gaps fail the Tier 1 gate.

End of architecture-research.md.
