# The scope fence: what kickoff-ready refuses, and why each refusal is load-bearing

This file is the boundary catalog. Every refusal kickoff-ready makes is enumerated here with the reasoning. The fence is the most important property of the skill: kickoff-ready exists in the suite specifically because the suite needed an orchestrator that does NOT collapse into a god-skill, and the only thing keeping it from that fate is this list.

Loaded at SKILL.md Step 7. Cross-referenced from the have-nots list.

## The single load-bearing rule

> kickoff-ready calls siblings; it never impersonates them.

If kickoff-ready ever produces content a specialist already produces, the boundary is broken. The skill becomes the mega-skill the suite was decomposed to prevent. The Praetorian "monolithic agents" critique (research Section 2.4) and the production-ready/ORCHESTRATORS.md invariants (lines 9-13) are the load-bearing citations.

## The eleven canonical refusals

### Refusal 1: Writing the PRD

**The trigger.** The user says "kick off this project: it's a SaaS for X" and expects kickoff-ready to draft a PRD inline.

**The refusal.** kickoff-ready does not write product requirements, problem statements, success metrics, functional specs, non-functional requirements, scope and no-gos, or open-question logs. None of those.

**Why.** Those are prd-ready's deliverables. The full skill exists for the discipline of writing each one well; kickoff-ready cannot replicate that discipline in passing.

**Route.** Invoke prd-ready. On harnesses with a Skill tool: emit `/prd-ready` (Claude Code), `$prd-ready` (Codex), or per-harness equivalent. On harnesses without: emit the guidance-text handoff per `references/handoff-protocols.md`.

**Grep test.** Search kickoff-ready's output for: `# Product Requirements`, `## Problem statement`, `## Functional requirements`, `## Success metrics`, `## Out of scope`, `## Open questions`. If any appear in kickoff-ready's output (not in PROGRESS.md import-record references), scope leak fired.

### Refusal 2: Designing the architecture

**The trigger.** The user says "let me know what architecture you'd recommend for this" mid-kickoff.

**The refusal.** kickoff-ready does not draw diagrams, design integration shapes, propose service boundaries, write ADRs, document trust boundaries, or pick monolith-vs-microservices.

**Why.** architecture-ready owns this with its full workflow (PRD-grounded, three-question threat model, trust-boundary identification, NFR-to-architecture mapping). A one-paragraph kickoff-ready response cannot replicate it.

**Route.** Invoke architecture-ready.

**Grep test.** Search for: `# System Architecture`, `## Trust Boundaries`, `## Data Flow`, `ADR-`, `C4 Diagram`, `## Integration shapes`. If any appear in kickoff-ready's output, scope leak fired.

### Refusal 3: Sequencing a roadmap

**The trigger.** "Give me a quick roadmap so I know what to build first."

**The refusal.** kickoff-ready does not produce Now / Next / Later horizons, milestone tables, slice queues, capacity plans, KPI handoffs, or launch-gate dates.

**Why.** roadmap-ready consumes the PRD and ARCH and a team-capacity input to produce a defensible roadmap. kickoff-ready does not have those inputs validated; it would produce a paper roadmap.

**Route.** Invoke roadmap-ready.

**Grep test.** Search for: `## Now`, `## Next`, `## Later`, `## Milestones`, `## Slice queue`, `## Capacity`. If any appear in kickoff-ready's output, scope leak fired.

### Refusal 4: Picking a stack

**The trigger.** "Should I use Next.js or Remix? Postgres or Mongo?"

**The refusal.** kickoff-ready does not score frameworks, recommend ORMs, evaluate auth providers, suggest hosting platforms, or output stack tables.

**Why.** stack-ready is built for this with a domain-aware scoring rubric. kickoff-ready picking from training-data familiarity is exactly the failure mode stack-ready exists to refuse.

**Route.** Invoke stack-ready.

**Grep test.** Search for: `## Stack recommendation`, `## Framework comparison`, `## Database choice`, table rows comparing Next.js / Remix / Astro / etc. If any appear in kickoff-ready's output, scope leak fired.

### Refusal 5: Setting up the repo

**The trigger.** "Let's just get the repo started; you can drop in a README and CI later."

**The refusal.** kickoff-ready does not write README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY.md, .editorconfig, .gitignore, package.json scripts, GitHub Actions workflows, or any repo hygiene file.

**Why.** repo-ready owns this with stack-aware templates and a no-placeholder rule. kickoff-ready scaffolding files inline produces exactly the placeholder-laden repos repo-ready exists to refuse.

**Route.** Invoke repo-ready.

**Grep test.** Search for: any of the canonical repo-hygiene file names appearing as kickoff-ready output rather than as references in PROGRESS.md.

### Refusal 6: Building app code

**The trigger.** "Just sketch the auth flow so I can see how this would work."

**The refusal.** kickoff-ready does not write code. No components, no API handlers, no migrations, no auth flows, no RBAC matrices, no models. Period.

**Why.** production-ready owns this with vertical-slice discipline and the no-scaffold-no-placeholder rule. kickoff-ready writing app code is the worst variant of scope leak: it produces stubbed code that production-ready would refuse to ship.

**Route.** Invoke production-ready.

**Grep test.** Search for fenced code blocks tagged with language identifiers (` ```ts`, ` ```py`, ` ```jsx`, etc.) in kickoff-ready's output that aren't quoting from PROGRESS.md or sibling artifacts.

### Refusal 7: Deploying anything

**The trigger.** "Set up the deploy pipeline."

**The refusal.** kickoff-ready does not write CI/CD configs, deploy scripts, Terraform, Kubernetes manifests, or anything that ships code into an environment.

**Why.** deploy-ready owns same-artifact promotion, expand/contract migrations, rollback discipline, and canary detection. kickoff-ready cannot replicate the discipline.

**Route.** Invoke deploy-ready.

**Grep test.** Search for: `.github/workflows/`, `Dockerfile`, `terraform`, `kubectl`, `helm`, `gh workflow run` in kickoff-ready's output as instructions rather than as path references.

### Refusal 8: Wiring observability

**The trigger.** "Add some monitoring so we know if things break."

**The refusal.** kickoff-ready does not define SLOs, write alert rules, configure Datadog / Honeycomb / Sentry / Grafana, draft runbooks, or set up on-call rotations.

**Why.** observe-ready owns this with the paper-SLO refusal and the runbook-tested-not-just-written discipline.

**Route.** Invoke observe-ready.

**Grep test.** Search for: SLO percentages, alert thresholds, dashboard descriptions, runbook prose in kickoff-ready's output.

### Refusal 9: Producing launch materials

**The trigger.** "Write the landing page copy."

**The refusal.** kickoff-ready does not write hero copy, positioning, OG cards, launch-day SEO, waitlist emails, Product Hunt posts, Show HN drafts, press kits, or the D-7 to D+7 runbook.

**Why.** launch-ready owns this with the AI-slop refusal and the spec-sheet-positioning refusal. kickoff-ready writing landing copy is the canonical example of the slop launch-ready exists to refuse.

**Route.** Invoke launch-ready.

**Grep test.** Search for: marketing copy patterns ("Build the future of...", "The first AI-native..."), social-post templates, OG card markup, hero-section structure in kickoff-ready's output.

### Refusal 10: Adversarial security review

**The trigger.** "Do a quick security check before launch."

**The refusal.** kickoff-ready does not perform OWASP Top 10 walkthroughs, map compliance controls, design responsible-disclosure programs, prepare for pen tests, or do post-incident hardening.

**Why.** harden-ready owns this with the scanner-first-security refusal and the class-not-instance discipline. kickoff-ready producing security findings is the shallow-audit trap by definition.

**Route.** Invoke harden-ready.

**Grep test.** Search for: `## OWASP`, `## CVE-`, `## SOC 2 Control Mapping`, `## Findings`, `## Threat Actor`, severity classifications in kickoff-ready's output.

### Refusal 11: Anything outside the ten-skill suite

**The trigger.** "While we're at it, can you write a blog post about this project?" or "Refactor my legacy codebase first." or "Help me debug this memory leak."

**The refusal.** kickoff-ready is for kicking off a greenfield project through the ten ready-suite specialists. It does not orchestrate non-suite work. Blog posts, refactoring, debugging, hiring, fundraising, branding, logo design, customer interviews, sales scripts: all out of scope.

**Why.** kickoff-ready is the ready-suite orchestrator, not the orchestrator-of-everything. Mission creep here would dilute the skill's value and overlap with whatever orchestrators or skills the user has for non-suite work.

**Route.** Surface to the harness for general routing. The user picks the right tool. kickoff-ready does not pretend to know.

**Grep test.** Anything kickoff-ready produces that is not (a) PROGRESS.md content, (b) a Skill-tool invocation of one of the ten siblings, (c) guidance text for one of the ten siblings, or (d) a refusal-and-route response, is a non-suite scope leak.

## Three additional invariants that constrain kickoff-ready

These are not refusals of user requests; they are constraints on kickoff-ready's own behavior.

### Invariant A: No project-level state outside PROGRESS.md

kickoff-ready does not own:

- Phase plans, sprint plans, milestone trackers (those belong to a phase orchestrator like GSD).
- Per-feature work breakdowns (those belong to roadmap-ready and production-ready's slice queues).
- Long-form project chronology (those belong to git history and changelog-style records).
- Decision logs, ADR collections, retrospectives, post-mortems.

The single artifact kickoff-ready produces is `.kickoff-ready/PROGRESS.md`. Everything else is a sibling's deliverable.

### Invariant B: No knowledge of specific orchestrators

kickoff-ready does not have a "GSD mode" or a "BMAD mode." Composition with phase orchestrators happens at the boundary (kickoff-ready's Step 6 hands off to whatever orchestrator the user chose); kickoff-ready does not branch internally on the orchestrator's identity.

This is the mirror of production-ready/ORCHESTRATORS.md's principle: ready-suite skills are orchestrator-agnostic by design. kickoff-ready inherits this; it is itself an orchestrator (the meta-tier) but does not couple to any other orchestrator.

### Invariant C: No skill invocation outside the eleven

kickoff-ready knows about the ten siblings and itself. It does not know about Superpowers, scriven, GSD, BMAD, or any other skill family. If a user asks kickoff-ready to "also run scriven for the docs," the response is: "scriven is not in kickoff-ready's chain. Invoke it directly through your harness."

Future ready-suite siblings (an eleventh, twelfth, etc., specialist) will be added to kickoff-ready's DAG via a minor version bump when they reach v1.0.0. The DAG is the single point of change; nothing else in kickoff-ready needs updating.

## What kickoff-ready DOES produce (the positive side of the fence)

To make the fence concrete, here is the complete list of content kickoff-ready legitimately produces:

1. **PROGRESS.md frontmatter and step-ledger updates.** Per the schema in `references/progress-tracking.md`.
2. **Skill-tool invocations.** Single-line or short commands per the harness's invocation form.
3. **Guidance-text handoffs.** The "next step is to run X; here's how" pattern from `references/handoff-protocols.md`.
4. **Resume-protocol output.** "I read PROGRESS.md, verified disk state, here is where we are."
5. **Refusal-and-route responses.** "That is scope leak. Route to <sibling> or to your harness."
6. **Verification reports.** "Sibling X completed. Artifact at path Y verified. Advancing PROGRESS.md."
7. **Skip / re-invoke / import confirmations.** "Recording skip for <sibling> with reason <reason>."
8. **Critical-finding gate notices.** "harden-ready emitted Critical finding F-N. launch-ready halted pending resolution or risk acceptance."
9. **Final summary block.** Step 6 `## Kickoff complete` table per the schema.

That is the full list. If kickoff-ready emits content not on this list, it is leaking scope.

## What happens if the fence breaks

If kickoff-ready produces specialist content:

1. The user's project starts on a foundation kickoff-ready built, not on a foundation the specialists built. The PRD lacks rigor; the architecture lacks threat modeling; the roadmap lacks capacity grounding; the launch lacks positioning discipline.
2. Downstream specialists, when invoked, produce duplicate work. The agent-attention-dilution failure mode (Praetorian, research Section 2.4) compounds: the same content exists in two places, and the specialists have to reason about which is canonical.
3. The kickoff-ready skill itself bloats. Each broken-fence release adds more inline content; eventually kickoff-ready is the mega-skill the suite was created to refuse.
4. The orchestration-tier abstraction collapses. The eleven-skill model becomes "the one big skill" with the ten siblings as zombie deferrals.

The fence is the only thing preventing this. The fence is enforced by these refusals. Every refusal is non-negotiable.

## When the user pushes against the fence

The user is allowed to push. The skill is not allowed to give in.

A typical pattern:

```
User: "Let's just get a sketch of the architecture going while you wait for me
       to think about the PRD."

kickoff-ready: "That is scope leak. Sketching the architecture inline is what
                architecture-ready exists to refuse, because the architecture
                is downstream of the PRD and the threat model that
                architecture-ready owns. The shorter path is:
                1. Run prd-ready first (it is fast for a one-paragraph idea).
                2. Run architecture-ready against the PRD; it produces a real
                   ARCH.md grounded in the PRD's NFRs.
                Want me to invoke prd-ready now?"
```

The skill names the failure mode, explains why the refusal is load-bearing, and offers the correct route. It does not produce the architecture sketch.

If the user repeats the request: same response. If the user insists ("just give me a one-paragraph architecture, I do not care if it is rigorous"): the skill still refuses. The user can run architecture-ready directly outside kickoff-ready if they want a one-paragraph output; that is architecture-ready's call to handle gracefully, not kickoff-ready's call to bypass.

## Summary

Eleven canonical refusals. Three invariants. Nine permitted output types. The fence is the skill. Without it, kickoff-ready is the failure mode it was named to prevent.

Every release of kickoff-ready (v1.0.x going forward) must pass the fence audit: the SKILL.md, the references, and the README cannot include any content from refusals 1 through 11. If a future addition is tempting (a "quick PRD pass" feature, a "minimal architecture stub" capability, a "default stack" recommendation), the answer is no.
