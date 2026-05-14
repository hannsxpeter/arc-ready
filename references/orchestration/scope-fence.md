# The scope fence: what arc-ready refuses, and why each refusal is load-bearing

This file is the boundary catalog. Every refusal arc-ready makes is enumerated here with the reasoning. The fence is the most important property of the skill: arc-ready exists specifically because the arc needs an orchestrator that does NOT collapse into a god-skill, and the only thing keeping it from that fate is this list.

Loaded at SKILL.md Step 7. Cross-referenced from the have-nots list.

## The single load-bearing rule

> arc-ready calls tiers; it never impersonates them.

If arc-ready ever produces content a specialist already produces, the boundary is broken. The skill becomes the mega-skill the tiered arc was designed to prevent. The Praetorian "monolithic agents" critique (research Section 2.4) and the references/shared/ORCHESTRATORS.md invariants (lines 9-13) are the load-bearing citations.

## The eleven canonical refusals

### Refusal 1: Writing the PRD

**The trigger.** The user says "kick off this project: it's a SaaS for X" and expects arc-ready to draft a PRD inline.

**The refusal.** arc-ready does not write product requirements, problem statements, success metrics, functional specs, non-functional requirements, scope and no-gos, or open-question logs. None of those.

**Why.** Those are prd-ready's deliverables. The full skill exists for the discipline of writing each one well; arc-ready cannot replicate that discipline in passing.

**Route.** Invoke prd-ready. On harnesses with a Skill tool: emit `/prd-ready` (Claude Code), `$prd-ready` (Codex), or per-harness equivalent. On harnesses without: emit the guidance-text handoff per `references/orchestration/handoff-protocols.md`.

**Grep test.** Search arc-ready's output for: `# Product Requirements`, `## Problem statement`, `## Functional requirements`, `## Success metrics`, `## Out of scope`, `## Open questions`. If any appear in arc-ready's output (not in PROGRESS.md import-record references), scope leak fired.

### Refusal 2: Designing the architecture

**The trigger.** The user says "let me know what architecture you'd recommend for this" mid-kickoff.

**The refusal.** arc-ready does not draw diagrams, design integration shapes, propose service boundaries, write ADRs, document trust boundaries, or pick monolith-vs-microservices.

**Why.** architecture-ready owns this with its full workflow (PRD-grounded, three-question threat model, trust-boundary identification, NFR-to-architecture mapping). A one-paragraph arc-ready response cannot replicate it.

**Route.** Invoke architecture-ready.

**Grep test.** Search for: `# System Architecture`, `## Trust Boundaries`, `## Data Flow`, `ADR-`, `C4 Diagram`, `## Integration shapes`. If any appear in arc-ready's output, scope leak fired.

### Refusal 3: Sequencing a roadmap

**The trigger.** "Give me a quick roadmap so I know what to build first."

**The refusal.** arc-ready does not produce Now / Next / Later horizons, milestone tables, slice queues, capacity plans, KPI handoffs, or launch-gate dates.

**Why.** roadmap-ready consumes the PRD and ARCH and a team-capacity input to produce a defensible roadmap. arc-ready does not have those inputs validated; it would produce a paper roadmap.

**Route.** Invoke roadmap-ready.

**Grep test.** Search for: `## Now`, `## Next`, `## Later`, `## Milestones`, `## Slice queue`, `## Capacity`. If any appear in arc-ready's output, scope leak fired.

### Refusal 4: Picking a stack

**The trigger.** "Should I use Next.js or Remix? Postgres or Mongo?"

**The refusal.** arc-ready does not score frameworks, recommend ORMs, evaluate auth providers, suggest hosting platforms, or output stack tables.

**Why.** stack-ready is built for this with a domain-aware scoring rubric. arc-ready picking from training-data familiarity is exactly the failure mode stack-ready exists to refuse.

**Route.** Invoke stack-ready.

**Grep test.** Search for: `## Stack recommendation`, `## Framework comparison`, `## Database choice`, table rows comparing Next.js / Remix / Astro / etc. If any appear in arc-ready's output, scope leak fired.

### Refusal 5: Setting up the repo

**The trigger.** "Let's just get the repo started; you can drop in a README and CI later."

**The refusal.** arc-ready does not write README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY.md, .editorconfig, .gitignore, package.json scripts, GitHub Actions workflows, or any repo hygiene file.

**Why.** repo-ready owns this with stack-aware templates and a no-placeholder rule. arc-ready scaffolding files inline produces exactly the placeholder-laden repos repo-ready exists to refuse.

**Route.** Invoke repo-ready.

**Grep test.** Search for: any of the canonical repo-hygiene file names appearing as arc-ready output rather than as references in PROGRESS.md.

### Refusal 6: Building app code

**The trigger.** "Just sketch the auth flow so I can see how this would work."

**The refusal.** arc-ready does not write code. No components, no API handlers, no migrations, no auth flows, no RBAC matrices, no models. Period.

**Why.** production-ready owns this with vertical-slice discipline and the no-scaffold-no-placeholder rule. arc-ready writing app code is the worst variant of scope leak: it produces stubbed code that production-ready would refuse to ship.

**Route.** Invoke production-ready.

**Grep test.** Search for fenced code blocks tagged with language identifiers (` ```ts`, ` ```py`, ` ```jsx`, etc.) in arc-ready's output that aren't quoting from PROGRESS.md or tier artifacts.

### Refusal 7: Deploying anything

**The trigger.** "Set up the deploy pipeline."

**The refusal.** arc-ready does not write CI/CD configs, deploy scripts, Terraform, Kubernetes manifests, or anything that ships code into an environment.

**Why.** deploy-ready owns same-artifact promotion, expand/contract migrations, rollback discipline, and canary detection. arc-ready cannot replicate the discipline.

**Route.** Invoke deploy-ready.

**Grep test.** Search for: `.github/workflows/`, `Dockerfile`, `terraform`, `kubectl`, `helm`, `gh workflow run` in arc-ready's output as instructions rather than as path references.

### Refusal 8: Wiring observability

**The trigger.** "Add some monitoring so we know if things break."

**The refusal.** arc-ready does not define SLOs, write alert rules, configure Datadog / Honeycomb / Sentry / Grafana, draft runbooks, or set up on-call rotations.

**Why.** observe-ready owns this with the paper-SLO refusal and the runbook-tested-not-just-written discipline.

**Route.** Invoke observe-ready.

**Grep test.** Search for: SLO percentages, alert thresholds, dashboard descriptions, runbook prose in arc-ready's output.

### Refusal 9: Producing launch materials

**The trigger.** "Write the landing page copy."

**The refusal.** arc-ready does not write hero copy, positioning, OG cards, launch-day SEO, waitlist emails, Product Hunt posts, Show HN drafts, press kits, or the D-7 to D+7 runbook.

**Why.** launch-ready owns this with the AI-slop refusal and the spec-sheet-positioning refusal. arc-ready writing landing copy is the canonical example of the slop launch-ready exists to refuse.

**Route.** Invoke launch-ready.

**Grep test.** Search for: marketing copy patterns ("Build the future of...", "The first AI-native..."), social-post templates, OG card markup, hero-section structure in arc-ready's output.

### Refusal 10: Adversarial security review

**The trigger.** "Do a quick security check before launch."

**The refusal.** arc-ready does not perform OWASP Top 10 walkthroughs, map compliance controls, design responsible-disclosure programs, prepare for pen tests, or do post-incident hardening.

**Why.** harden-ready owns this with the scanner-first-security refusal and the class-not-instance discipline. arc-ready producing security findings is the shallow-audit trap by definition.

**Route.** Invoke harden-ready.

**Grep test.** Search for: `## OWASP`, `## CVE-`, `## SOC 2 Control Mapping`, `## Findings`, `## Threat Actor`, severity classifications in arc-ready's output.

### Refusal 11: Anything outside the ten-skill suite

**The trigger.** "While we're at it, can you write a blog post about this project?" or "Refactor my legacy codebase first." or "Help me debug this memory leak."

**The refusal.** arc-ready is for kicking off a greenfield project through the ten arc-ready specialist tiers. It does not orchestrate non-suite work. Blog posts, refactoring, debugging, hiring, fundraising, branding, logo design, customer interviews, sales scripts: all out of scope.

**Why.** arc-ready is the arc orchestrator, not the orchestrator-of-everything. Mission creep here would dilute the skill's value and overlap with whatever orchestrators or skills the user has for non-arc work.

**Route.** Surface to the harness for general routing. The user picks the right tool. arc-ready does not pretend to know.

**Grep test.** Anything arc-ready produces that is not (a) PROGRESS.md content, (b) a Skill-tool invocation of one of the ten specialist tiers, (c) guidance text for one of the ten specialist tiers, or (d) a refusal-and-route response, is a non-suite scope leak.

## Three additional invariants that constrain arc-ready

These are not refusals of user requests; they are constraints on arc-ready's own behavior.

### Invariant A: No project-level state outside PROGRESS.md

arc-ready does not own:

- Phase plans, sprint plans, milestone trackers (those belong to a phase orchestrator like GSD).
- Per-feature work breakdowns (those belong to roadmap-ready and production-ready's slice queues).
- Long-form project chronology (those belong to git history and changelog-style records).
- Decision logs, ADR collections, retrospectives, post-mortems.

The single artifact arc-ready produces is `.arc-ready/PROGRESS.md`. Everything else is a tier's deliverable.

### Invariant B: No knowledge of specific orchestrators

arc-ready does not have a "GSD mode" or a "BMAD mode." Composition with phase orchestrators happens at the boundary (arc-ready's Step 6 hands off to whatever orchestrator the user chose); arc-ready does not branch internally on the orchestrator's identity.

This is the mirror of references/shared/ORCHESTRATORS.md's principle: arc-ready tiers are orchestrator-agnostic by design. arc-ready inherits this; it is itself an orchestrator (the meta-tier) but does not couple to any other orchestrator.

### Invariant C: No skill invocation outside the eleven

arc-ready knows about the ten specialist tiers and itself. It does not know about Superpowers, scriven, GSD, BMAD, or any other skill family. If a user asks arc-ready to "also run scriven for the docs," the response is: "scriven is not in arc-ready's chain. Invoke it directly through your harness."

Future arc-ready tiers (an eleventh, twelfth, etc., specialist) will be added to arc-ready's DAG via a minor version bump when they reach v1.0.0. The DAG is the single point of change; nothing else in arc-ready needs updating.

## What arc-ready DOES produce (the positive side of the fence)

To make the fence concrete, here is the complete list of content arc-ready legitimately produces:

1. **PROGRESS.md frontmatter and step-ledger updates.** Per the schema in `references/orchestration/progress-tracking.md`.
2. **Skill-tool invocations.** Single-line or short commands per the harness's invocation form.
3. **Guidance-text handoffs.** The "next step is to run X; here's how" pattern from `references/orchestration/handoff-protocols.md`.
4. **Resume-protocol output.** "I read PROGRESS.md, verified disk state, here is where we are."
5. **Refusal-and-route responses.** "That is scope leak. Route to <tier> or to your harness."
6. **Verification reports.** "Tier X completed. Artifact at path Y verified. Advancing PROGRESS.md."
7. **Skip / re-invoke / import confirmations.** "Recording skip for <tier> with reason <reason>."
8. **Critical-finding gate notices.** "harden-ready emitted Critical finding F-N. launch-ready halted pending resolution or risk acceptance."
9. **Final summary block.** Step 6 `## Kickoff complete` table per the schema.

That is the full list. If arc-ready emits content not on this list, it is leaking scope.

## What happens if the fence breaks

If arc-ready produces specialist content:

1. The user's project starts on a foundation arc-ready built, not on a foundation the specialists built. The PRD lacks rigor; the architecture lacks threat modeling; the roadmap lacks capacity grounding; the launch lacks positioning discipline.
2. Downstream specialists, when invoked, produce duplicate work. The agent-attention-dilution failure mode (Praetorian, research Section 2.4) compounds: the same content exists in two places, and the specialists have to reason about which is canonical.
3. The arc-ready skill itself bloats. Each broken-fence release adds more inline content; eventually arc-ready is the mega-skill the tiered arc was created to refuse.
4. The orchestration-tier abstraction collapses. The arc-ready model becomes "the one big skill" with the ten specialist tiers as zombie deferrals.

The fence is the only thing preventing this. The fence is enforced by these refusals. Every refusal is non-negotiable.

## When the user pushes against the fence

The user is allowed to push. The skill is not allowed to give in.

A typical pattern:

```
User: "Let's just get a sketch of the architecture going while you wait for me
       to think about the PRD."

arc-ready: "That is scope leak. Sketching the architecture inline is what
                architecture-ready exists to refuse, because the architecture
                is downstream of the PRD and the threat model that
                architecture-ready owns. The shorter path is:
                1. Run prd-ready first (it is fast for a one-paragraph idea).
                2. Run architecture-ready against the PRD; it produces a real
                   ARCH.md grounded in the PRD's NFRs.
                Want me to invoke prd-ready now?"
```

The skill names the failure mode, explains why the refusal is load-bearing, and offers the correct route. It does not produce the architecture sketch.

If the user repeats the request: same response. If the user insists ("just give me a one-paragraph architecture, I do not care if it is rigorous"): the skill still refuses. The user can run architecture-ready directly outside arc-ready if they want a one-paragraph output; that is architecture-ready's call to handle gracefully, not arc-ready's call to bypass.

## Summary

Eleven canonical refusals. Three invariants. Nine permitted output types. The fence is the skill. Without it, arc-ready is the failure mode it was named to prevent.

Every release of arc-ready (v1.0.x going forward) must pass the fence audit: the SKILL.md, the references, and the README cannot include any content from refusals 1 through 11. If a future addition is tempting (a "quick PRD pass" feature, a "minimal architecture stub" capability, a "default stack" recommendation), the answer is no.
