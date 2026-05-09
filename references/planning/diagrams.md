# Diagrams

Diagrams in an architecture document are not illustrations. They are carriers of decisions. Every box represents a responsibility someone has to own; every arrow represents an interaction someone has to implement; every label represents a commitment about how the interaction behaves. If a diagram element cannot be annotated with "this was decided because," it is decoration, and decoration in an architecture document actively harms: it signals thoroughness without delivering rationale, and it invites future readers to treat the diagram as ground truth when the decisions behind it were never made.

This reference specifies which diagram styles the skill supports, how to use them, and what to refuse. The default is the C4 model (Simon Brown); arc42 and 4+1 views are alternatives for specific contexts. Every diagram the skill produces must be text-formatted, version-controlled, labeled on every arrow, and traceable to an ADR.

## Section 1. Diagrams carry decisions, not decoration

The load-bearing claim: a diagram's value is a function of the decisions it records, not the boxes it contains. A seven-box diagram that names a system shape, seven responsibilities, and six labeled interactions has recorded twenty-one decisions. A seven-box diagram with unlabeled arrows and generic names has recorded none.

The test applied to every element:

- **Every box has a responsibility** that a new engineer can point at and say "that is what this owns." If the responsibility is "the backend" or "core service," the box is generic and fails the test.
- **Every arrow has a semantic** that names the protocol, the direction of causation, and the failure mode if the interaction fails. If the arrow is labeled "uses" or "calls" or is unlabeled entirely, the arrow fails the test.
- **Every element traces to an ADR** or to an actor named in the PRD. If the diagram shows a Redis cache, a Kafka queue, a service mesh, or any element whose presence is an architectural decision, the decision must have an ADR. Diagrams without ADRs are decoration.
- **Every diagram has a legend** if color, shape variation, or line style carries information. If no legend, no variation.

A diagram that fails any of the above is either rewritten or removed. An architecture document with zero diagrams is preferable to one with decorative diagrams; the zero-diagram version at least does not mislead.

## Section 2. The C4 model (Simon Brown)

The C4 model is Simon Brown's proposal for a hierarchical, four-level way to diagram software architecture. Canonical reference: c4model.com. Primary book: "The C4 Model," Simon Brown, O'Reilly, 2024 (https://www.oreilly.com/library/view/the-c4-model/9798341660113/). The LeanPub predecessor "The C4 model for visualising software architecture" is freely available at https://leanpub.com/visualising-software-architecture.

### 2.1 The four levels

- **Level 1: System Context.** The system as a single box, with actors (users, external systems) around it. Answers "what does this system do and who does it talk to." Zoom level: the business.
- **Level 2: Container.** The internals of the system as a set of deployable units (services, databases, queues, frontends, mobile apps). Answers "what is the system made of." Zoom level: the deployment.
- **Level 3: Component.** The internals of one container, showing components (modules, packages, classes of architectural weight). Answers "what is inside this specific container." Zoom level: the code structure.
- **Level 4: Code.** Class diagrams or equivalent. Almost never worth drawing; code reads better than diagrams at this level.

### 2.2 Core notation

- **Boxes** are software units. Each box has a name, a type (person, software system, container, component), and a responsibility in the caption.
- **Arrows** are interactions. Each arrow has a direction, a label (protocol and purpose), and optionally technology annotation.
- **Labels on every arrow.** "Uses" is not a label. "POST /api/orders (REST/JSON, authenticated via session cookie)" is a label.
- **Legend on every diagram.** Even a minimal one: what do the shape variations mean, what do the colors mean.

### 2.3 Authoritative misuse catalog

Simon Brown's own GOTO 2024 talk, "The C4 Model: Misconceptions, Misuses, and Mistakes" (https://gotocph.com/2024/sessions/3326/the-c4-model-misconceptions-misuses-and-mistakes), catalogs the failure modes this skill's reviewers should watch for. Working Software has a companion writeup at https://www.workingsoftware.dev/misuses-and-mistakes-of-the-c4-model/. See Section 4 of this document for the subset of misuses this skill refuses.

## Section 3. The four C4 levels in detail

### 3.1 Level 1: System Context

**What it shows.** The system as a single opaque box. Around it: the primary users (customer, admin, support agent, etc.) and the external systems the system integrates with (Stripe, Twilio, an SSO provider, a partner API, an internal system not under this project's control).

**What every arrow says.** The interaction between the system and each external entity. "Admin manages orders via web browser (HTTPS)." "System sends email notifications via SendGrid (HTTPS, API key)." "System receives webhook events from Stripe (HTTPS, signed with shared secret)."

**When to draw it.** Every architecture. Tier 1 requires it. The Level 1 diagram is the single most reused artifact in downstream conversations: onboarding, security review, partner conversations, executive briefings.

**Size discipline.** Under 10 boxes. If Level 1 exceeds 10 boxes, either the system's external surface is genuinely large (multi-system enterprise) and deserves a per-domain Level 1, or the diagram is showing implementation detail that belongs at Level 2.

**Common defect.** Missing external systems. Every integration that is load-bearing for a feature must appear on Level 1. If Stripe is critical to the payment flow, Stripe is on Level 1; if an internal HR API is critical for employee lookup, it is on Level 1.

### 3.2 Level 2: Container

**What it shows.** The deployable units inside the system: the web app, the API service, the background worker, the database, the queue, the cache, the object store. Each container has its technology annotation (Next.js app, Postgres 16, Redis 7, Cloudflare Workers, S3 bucket) and its responsibility.

**What every arrow says.** The protocol and purpose of each interaction between containers. "API service reads order rows from Postgres via pooled connection (Prisma)." "Worker consumes OrderPlaced events from the queue (Kafka, at-least-once)." "Frontend calls API over HTTPS with session cookie authentication."

**When to draw it.** Every architecture beyond the trivial. Tier 2 requires it. A single-container architecture (a monolith with its database) is still drawn at Level 2, and the diagram is short and honest; the point is to record the technology choices and the interactions that do exist, not to invent complexity.

**Size discipline.** Under 15 boxes. Most Level 2 diagrams land at 5 to 10. Beyond 15, the diagram is unreadable and should be split (one Level 2 per subsystem, with a parent Level 2 showing the subsystem composition).

**Common defect.** Missing technology annotations on containers ("Database" instead of "Postgres 16"), missing protocols on arrows ("uses" instead of "REST/JSON"), mixing abstraction levels (components inside containers).

### 3.3 Level 3: Component

**What it shows.** The internal components of one container. For a modular monolith, each bounded context is a component. For a service, the components might be the controllers, the application services, the domain model, and the repositories; or, at a higher abstraction, the logical modules (Orders, Billing, Inventory).

**What every arrow says.** The calls or data flow between components. Call direction, synchronous or asynchronous, the interface shape.

**When to draw it.** Only for architecturally-weighty containers. Not every container needs a component diagram. A simple API service whose components are "controllers, services, repositories" in the conventional layered pattern does not need a diagram; that is the pattern, and the diagram adds no decision. A container whose internal structure records a non-obvious choice (bounded-context boundaries in a modular monolith, a hexagonal-architecture split between adapters and core, a CQRS split between command and query sides) does need a diagram.

**Size discipline.** Under 15 boxes. Split if larger. A component diagram with 30 boxes is a code diagram (Level 4) under a false label.

**Common defect.** Drawing a Level 3 for every container. The diagram proliferation dilutes the ones that matter. Be selective: Level 3 is for where the internal structure is architecturally load-bearing.

### 3.4 Level 4: Code

**What it shows.** Classes, functions, and their relationships. A UML class diagram or equivalent.

**When to draw it.** Almost never. Modern IDEs let engineers read the code structure directly; a class diagram derived from source is either stale immediately (if drawn by hand) or a restatement of what the IDE already shows (if auto-generated). The rare case where Level 4 adds value: a particularly intricate algorithm, a state machine with non-obvious transitions, a concurrency pattern where the read-order matters. Even then, a sequence diagram or a state diagram is usually more useful than a class diagram.

**Guidance.** Skip Level 4 unless there is a specific reason. The skill does not require it at any tier.

## Section 4. Common C4 misuses (per Brown's own catalog)

The following are the failure modes Simon Brown's GOTO 2024 talk and subsequent blog posts flag as most common. This skill refuses diagrams exhibiting any of them.

### 4.1 Mixed abstraction levels

A Container diagram with Components nested inside a Container. A Context diagram with internal services spilling out. Breaks the "one abstraction per diagram" rule.

Fix: if the internal structure of a Container matters enough to show, draw a Level 3 Component diagram for that Container, linked from Level 2. Do not nest.

### 4.2 Missing technology on Containers

A Level 2 Container diagram where boxes are named "Web App," "API," "Database," without the technology. The point of Level 2 is to record the deployment shape; the shape includes technology. "Web App (Next.js 15, deployed to Vercel)," "API (FastAPI, running in a container on Fly.io)," "Database (Postgres 16, managed, Neon)."

Fix: annotate every Container with its technology in parentheses. If the technology is not yet decided (stack-ready's job), annotate the shape requirement: "Long-running process for request handling; technology TBD per stack-ready."

### 4.3 Missing direction on arrows

Arrows drawn as lines without arrowheads, or double-headed where the semantics are actually one-directional. The direction carries information: who initiates the call.

Fix: every arrow has a direction. Bidirectional interactions (rare, usually a mistake) are drawn as two arrows with two labels.

### 4.4 "Uses" as arrow label

"A uses B." Vacant. Every arrow is "uses" in some sense. Replace with protocol and purpose: "A sends order events to B (Kafka, at-least-once, idempotency key = order_id)." "A queries customer records from B (REST/JSON over HTTPS, cached 60s)."

### 4.5 Unnamed external systems

A Context diagram with a box labeled "Third-party API" or "External service." Every external system has a name. If the external system is not yet chosen, the box is premature; replace with the actor or wait.

Fix: name every external system. "Stripe API." "Twilio SMS." "Internal HRIS (Workday)." "Partner reconciliation service (vendor TBD, requirements in PRD Section 4)."

### 4.6 The word "container" itself

Simon Brown has publicly said that "container" was a regret: the word predates Docker's ubiquity, and now readers frequently confuse C4 containers with Docker containers. A C4 container is a deployable unit (a running process, a database, a frontend app, a browser tab, a mobile app); it is independent of whether Docker is the runtime.

Fix: in diagram captions and in the ARCH.md text, briefly clarify the term when a diagram is introduced. "Container here is the C4 sense: a deployable unit; Docker is our deployment technology, which is a separate decision (see ADR-NNNN)." After the first clarification, readers track.

## Section 5. arc42 (Peter Hruschka, Gernot Starke)

arc42 is an alternative template, broader in scope than C4. Origin: 2005, Gernot Starke and Peter Hruschka. Current template: https://arc42.org/ and https://github.com/arc42/arc42-template. Docs: https://docs.arc42.org/. The 20th-anniversary ecosystem update is at https://arc42.org/20yrs-ecosystem.

arc42 has 12 sections:

1. Introduction and Goals
2. Constraints
3. Context and Scope
4. Solution Strategy
5. Building Block View
6. Runtime View
7. Deployment View
8. Crosscutting Concepts
9. Architecture Decisions
10. Quality Requirements
11. Risks and Technical Debt
12. Glossary

### 5.1 arc42 vs. C4

C4 is a diagramming notation. arc42 is a document template. They are complements, not competitors; the arc42 "Building Block View" (Section 5) is typically rendered with C4 diagrams. Section 9 of arc42 is an ADR slot.

### 5.2 When to use arc42

- Enterprise architecture engagements where the full template is a contractual deliverable.
- Regulated domains where a specific documentation template is mandated (healthcare, automotive, finance) and arc42 matches the mandate.
- Teams already invested in arc42 from prior work.

### 5.3 When not to use arc42

- Small teams on greenfield projects. The 12 sections are overhead; most sections will be stubs.
- Teams where the deliverable is decision capture, not full document structure. This skill's ARCH.md is closer to "load-bearing decisions plus handoff" than to arc42's "full architecture document"; arc42 sections 1 through 3 and 10 through 12 are largely covered by the PRD, not ARCH.md.
- Teams with no prior arc42 exposure. The template has a learning curve; adopting it alongside everything else architecture-ready requires is counterproductive.

## Section 6. 4+1 views (Philippe Kruchten)

Philippe Kruchten, "Architectural Blueprints: The '4+1' View Model of Software Architecture," IEEE Software, vol. 12 no. 6, November 1995, pp. 42 to 50. Commonly mirrored at https://www.cs.ubc.ca/~gregor/teaching/papers/4+1view-architecture.pdf. Wikipedia: https://en.wikipedia.org/wiki/4%2B1_architectural_view_model.

### 6.1 The five views

- **Logical view.** The static structure of the system from the end-user's perspective. Classes, objects, inheritance. Closest to C4 Level 3.
- **Process view.** The runtime processes, their communication, concurrency, synchronization. Closest to a sequence or activity diagram.
- **Development view.** The static organization of the code: modules, packages, layers. The developer's view.
- **Physical view.** The mapping of software to hardware: servers, networks, data centers. Closest to a deployment diagram (which is deploy-ready's territory, not architecture-ready's).
- **Scenarios (the "+1").** Use cases that tie the other four views together.

### 6.2 When to use 4+1

Multi-stakeholder architecture work where different audiences need different cuts:

- Operations team cares about the Physical view (what runs where, how is it deployed, how does it fail).
- Development team cares about the Development view (code layout, module structure).
- End users and PMs care about the Logical view and Scenarios.
- Performance engineers and SREs care about the Process view (concurrency, synchronization, bottlenecks).

When a single C4 stack cannot serve all audiences because their questions fundamentally differ, 4+1 gives each audience its own view.

### 6.3 When not to use 4+1

- Most small-to-medium projects. C4's hierarchical zoom serves most audiences; adding four extra views is overhead.
- Teams with no shared 4+1 vocabulary. The views are distinct in theory; in practice, teams conflate Logical and Development views frequently.

### 6.4 Historical note

4+1 predates C4 by two decades and predates widespread cloud computing. The Physical view made more sense when physical view meant "which blade server in which rack"; in a cloud context, the Physical view compresses into deploy-ready's territory and loses some of its original utility. C4's Level 2 Container diagram, paired with a separate deployment diagram, covers the same ground more cleanly for most modern systems.

## Section 7. Rules for every diagram this skill produces

The following are non-negotiable at every tier. A diagram that fails any rule is rewritten or removed.

### 7.1 Text format, version-controlled

Acceptable formats:

- **Mermaid.** https://mermaid.js.org/. Widely supported; GitHub, GitLab, Notion, and most Markdown renderers render natively. Best for small diagrams and broad accessibility.
- **PlantUML.** https://plantuml.com/. More expressive than Mermaid; steeper learning curve; requires a rendering step. Best for sequence diagrams, state diagrams, and larger structural diagrams.
- **Structurizr DSL.** https://docs.structurizr.com/dsl. Simon Brown's tool, purpose-built for C4. Text format, CI-renderable, diagram-as-code first-class. Best when the team is committed to C4 and wants the full workflow.
- **D2.** https://d2lang.com/. Newer entry (2022), Terraform-style syntax, strong layout engine. Best for teams who prefer a declarative style and high-quality default layouts.
- **Graphviz DOT.** https://graphviz.org/. The oldest of the bunch; powerful, stable, syntax is spartan. Best for automated generation (script produces DOT, DOT renders).

Unacceptable:

- PNG, JPG, or SVG exports from Lucidchart, Miro, Excalidraw, Whimsical, or similar. These diagrams are not version-controllable (diffs are binary), not editable without a license (or at least without the original tool), and not grep-able. A PR reviewer cannot comment on a specific arrow in a PNG; they cannot cherry-pick changes.
- Screenshots of whiteboards. Acceptable as working material during a discussion; unacceptable as the final artifact.
- Proprietary-format exports that require the vendor's tool to edit.

### 7.2 Every arrow labeled with protocol and purpose

The label answers two questions: what protocol or mechanism does this interaction use, and what is it for. Examples:

- "POST /api/orders (REST/JSON, authenticated with tenant-scoped JWT, idempotency-key header)."
- "Publishes OrderPlaced (Kafka, at-least-once, key=order_id, partitioned by tenant_id)."
- "Reads customer rows (Postgres, row-level security bound to session tenant)."
- "Invokes webhook on order completion (HTTPS, retries with exponential backoff, DLQ after 5 failures)."

### 7.3 Every box has a responsibility in caption or diagram

The box's name is not enough. "Orders Service" is a name; "Orders Service (owns the order lifecycle from cart to fulfillment, including pricing at commit time and state transitions)" pairs the name with a responsibility. Responsibilities go either directly on the diagram (for short ones) or in the caption (for longer ones); either way, every box has one.

### 7.4 Every element traces to an ADR or is a labeled PRD-sourced actor

If the diagram shows a Redis cache, there is an ADR for why Redis, not why an in-process cache. If the diagram shows a Kafka topic, there is an ADR for why Kafka, not why a database-as-queue. If the diagram shows an API gateway, there is an ADR for why an API gateway, not direct edge-to-service calls.

PRD-sourced actors (users, roles, external systems named in the PRD) are labeled as such; they do not need ADRs but must be consistent with the PRD.

### 7.5 Keep diagrams small (under 15 boxes)

Cognitive-load research from Team Topologies and from general UX work converges around 7-plus-or-minus-2 as the limit for a diagram's scannable content. Fifteen is the skill's upper bound; most diagrams should land around 5 to 10. If a diagram exceeds 15, split into multiple diagrams at consistent abstraction levels, linked with a parent index diagram.

### 7.6 No cloud-vendor icons

AWS rectangles, GCP hexagons, Azure slabs. These are deploy-ready's territory, not architecture-ready's. A diagram full of AWS icons is a deployment diagram; it specifies infrastructure choices that are downstream of architecture.

An architecture diagram is technology-agnostic or technology-low: it mentions protocols (REST, gRPC, events) and shapes (relational store, object store, queue), not products (AWS Aurora, Google Cloud Pub/Sub, Azure Service Bus). The product pick is stack-ready's job; the deployment diagram is deploy-ready's.

### 7.7 No rainbow color without legend

If color carries information (orange means async, blue means sync, red means in-scope for PCI), the diagram has a legend. If color is decorative (because one vendor's default theme is colorful), recolor to monochrome or near-monochrome. Color without a legend is ambiguous; the reader invents meanings that may not match the author's.

## Section 8. Structurizr DSL and diagram-as-code

Simon Brown's Structurizr (https://structurizr.com/) is the purpose-built tool for C4. The DSL (https://docs.structurizr.com/dsl) is a text-based language that describes the model once and renders all levels consistently.

### 8.1 Benefits of diagram-as-code

- **Version control.** Diagrams live next to the code they describe. Diffs are line-level.
- **CI rendering.** A push to `main` triggers a render; the rendered diagrams live in a known location. Out-of-date diagrams are caught by CI (the rendering fails) rather than by the reader.
- **Refactoring.** Renaming a component in the DSL updates every diagram that references it. Renaming in a Lucidchart export requires editing every diagram by hand.
- **Code review.** A reviewer sees the DSL diff and can reason about the structural change; they cannot reason about a PNG diff.

### 8.2 Choosing among the text formats

- **Mermaid.** Pick when the primary constraint is accessibility (every GitHub, GitLab, Notion, and Obsidian reader can render it without setup). Weak for large diagrams; layout control is limited. Works well for Context and small Container diagrams.
- **PlantUML.** Pick when expressiveness matters (sequence diagrams, state diagrams, component diagrams with detailed notation). Requires a renderer (server or local); most CI systems handle it. Syntax is learnable but not trivial.
- **Structurizr DSL.** Pick when the team is committed to C4 and wants a purpose-built tool. The DSL models the system once and renders all four levels; the tool enforces C4 conventions. Requires a renderer (Structurizr Lite, self-hosted, or the Structurizr cloud).
- **D2.** Pick when layout quality matters and the team wants a modern declarative language. Renders to PNG or SVG; integrates with most CI systems.
- **Graphviz DOT.** Pick when automation is the goal (a script generates the DOT from a source of truth like an ADR corpus or a dependency graph). Graphviz's layout engine is mature, though the diagram aesthetic is old-school.

### 8.3 Recommendation per use case

- **Small project, Tier 1 only.** Mermaid. One diagram, rendered in GitHub, in the ARCH.md directly.
- **Medium project, Tier 2.** Mermaid for Level 1 (accessibility), Structurizr DSL or PlantUML for Levels 2 and 3. Renders in CI; diagrams live at a known URL.
- **Large project or platform, Tier 3.** Structurizr DSL with CI rendering, a diagram-browsing site (Structurizr Lite or the cloud tier), and fitness functions (Section 10) that flag drift.

## Section 9. Deployment diagrams are NOT architecture diagrams

This is the single most common boundary confusion in AI-generated architecture documents. An "architecture diagram" with AWS icons, ECS boxes, RDS cylinders, Lambda circles, and VPC subnets is a deployment diagram under the wrong label.

### 9.1 The distinction

- **Architecture diagram.** Describes the logical shape of the system: what services exist, what responsibilities they own, what protocols they use, what data they hold. Technology-agnostic or technology-low. The diagram is valid whether the system runs on AWS, GCP, Fly.io, or bare metal.
- **Deployment diagram.** Describes the physical placement of the system: which regions, which availability zones, which managed services, which networks, which IAM roles. Technology-specific and vendor-specific.

### 9.2 Why the confusion happens

Cloud vendor marketing trains engineers to think of architecture as "the set of AWS services we use." The AWS Well-Architected Framework, the GCP Cloud Architecture Center, and Azure's Architecture Center all present architecture in vendor-specific terms. This is useful for picking managed services; it is misleading as a substitute for architectural thinking.

The test: would the architecture make sense if you swapped the cloud vendor? If yes, it is an architecture diagram. If no, it is a deployment diagram that has substituted vendor choice for architectural reasoning.

### 9.3 The routing rule

If your "architecture diagram" has AWS icons, ECS boxes, RDS cylinders, Lambda circles, or anything that reads as "we picked these specific SKUs," move the diagram to deploy-ready. Architecture-ready's diagrams name protocols, not products, and shapes, not SKUs.

The stack-ready skill picks the SKUs after architecture-ready has named the shape; the deploy-ready skill diagrams the deployment topology after both have finished. The separation of concerns is strict; conflating them is how the architecture becomes the stack, and the system loses the chance to make architectural decisions before tool choices lock them in.

## Section 10. Keeping diagrams current

The single biggest diagram failure in practice is staleness. Diagrams go stale faster than ADRs, because the visual form hides drift: a reader glances at a diagram, sees familiar shapes, and trusts it; they would not trust a six-month-old ADR with the same credulity. Stale diagrams are actively misleading; a diagram that reads "three services" when the system has five is worse than no diagram.

### 10.1 Remedies

1. **Diagram-as-code in version control with the project.** The diagram source lives in the repo. Changes are diff-able. The source and the rendered output travel together.
2. **Re-render at every tier boundary and every ADR that changes the shape.** Tier 1 to Tier 2 transition, every new accepted ADR that adds or removes a component or changes an interaction, every rearchitecture: re-render.
3. **Fitness function that flags component names in code not in the diagram.** ArchUnit (Java/Kotlin), dependency-cruiser (JS/TS), Packwerk (Ruby), or a custom script can compare the set of module names in the code to the set of component names in the diagram. Drift is a CI warning; sustained drift is a CI failure.
4. **Explicit maintenance owner.** Every architecture diagram has a named maintainer in the ARCH.md. When the maintainer leaves the team, the ownership transfers; when neither holds, the diagram is flagged for review or deletion.
5. **Post-build audit at Tier 3.** 30, 60, or 90 days after initial build, a review confirms that the architecture-as-built matches the architecture-as-documented. Drift is reconciled with either a doc update or an ADR explaining the evolution.

### 10.2 What "current" means

A diagram is current when:

- Every box in the diagram corresponds to a component that exists in the code.
- Every arrow in the diagram corresponds to an interaction that exists in the code.
- Every technology annotation matches the actual technology in use.
- Every responsibility in the caption matches what the component actually does.

A diagram that has three out of four is partially current, which is to say: stale. Partial currency is not a middle state; it is a failure mode, because readers trust the parts they see and are blind to the parts that are wrong.

## Section 11. Diagram antipatterns

The following patterns are refused at every tier. Each is a signal that the diagram has been made to look like architecture without doing architecture's work.

### 11.1 Cloud-vendor icon dumps

A Level 2 "architecture diagram" that is twenty AWS service icons, arrows between them, and nothing else. Sometimes with a title like "Cloud-Native Architecture." This is a deployment topology, not an architecture; move to deploy-ready. The architecture question "what does this system do, how is it shaped, why" is unanswered.

### 11.2 "Uses" as arrow label

Vacant. Replace with protocol and purpose. See Section 4.4.

### 11.3 Rainbow diagrams

Every service a different color, no legend. The reader infers meaning from color (maybe warm colors are user-facing and cool colors are internal?); the author had no such intent. Recolor to monochrome or add a legend.

### 11.4 Diagrams without legend

Shape variation (rounded vs. square boxes), line-style variation (solid vs. dashed arrows), color variation, all without a legend. Ambiguity is the default interpretation.

### 11.5 Diagrams so dense the text is unreadable

Seventy boxes on one page; text at 6-point font. The reader zooms and squints and gives up. Split into hierarchical levels or scope to a specific concern.

### 11.6 Diagrams that mix abstraction levels

See Section 4.1. Containers with components inside, or components drawn alongside containers as peers.

### 11.7 Diagrams more than 18 months out of date

Staleness past 18 months is near-certain; the diagram described a different system. The honest response is: re-render, or remove the diagram and replace with a placeholder noting the gap, or accept that the architecture itself is no longer tracked and move to Mode F (rescue) in the skill's workflow.

### 11.8 Diagrams generated once and never edited

The AI-generated "professional-looking diagram" that the team shipped with the initial ARCH.md and never touched again. No ADR trail, no maintenance owner, no rendering pipeline. The diagram becomes a relic: readers see it, assume it reflects the current system, and learn a system that was never quite true and is now definitely not true. The fix is not redraw; the fix is to wire it into the diagram-as-code discipline (Section 10) so that rendering it is a CI step, updating it is a PR concern, and staleness is visible.

### 11.9 Box-and-line impressionism

The diagram has thirty shapes, ten colors, five line styles, twelve nested groups, and no caption. The author wanted to convey "the system is complex"; they conveyed nothing specific. Rewrite or remove.

Each antipattern has the same underlying failure: the diagram was produced as documentation without being produced as a decision record. The fix in every case is to ask the question this reference opens with: what decision does this element record, and can a future reader trace it to an ADR? If the answer is no, the element is decoration, and decoration in an architecture document is harm.
