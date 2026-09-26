# Guided: architecture (tier 1.2)

Copy this skeleton into `.architecture-ready/ARCH.md`, replace every `{{...}}`, and put the dependency graph in `.architecture-ready/HANDOFF.md`.

~~~markdown
# {{Product}} architecture

## System shape

{{Monolith, modular monolith, services, serverless, or a single process, chosen against the PRD's scale, team size, and budget.}}
Flip point: {{the measurable condition that would make you change this shape}}.

## Components

| Component | Purpose | Owner | Depends on |
|---|---|---|---|
| {{name}} | {{one job}} | {{person or team}} | {{components}} |

## Data

{{Each store, who owns it, consistency needs, retention.}}

## Integrations

{{Each external contract: protocol, versioning, timeout, retry budget, behavior when it fails.}}

## Capacity

{{Peak requests per second, storage growth, and cost at 12 months. Label every input measured, published, derived, or assumed.}}

## Trust boundaries

{{Where authentication, authorization, and encryption happen, each mapped to the file or config that enforces it.}}

## Decisions (ADRs)

### ADR-01: {{decision}}

Context: {{forces}}. Decision: {{choice}}. Consequences: {{costs}}. Flip point: {{evidence that would reverse it}}.
~~~

`HANDOFF.md` holds the component dependency graph in build order, for example `store -> api -> web`, plus anything the roadmap must know.

Before `arc-check.sh mark 1.2 done`:

1. Every box and arrow is a decision with a rationale, not decoration.
2. "Scalable" and "fast" carry numbers.
3. Every trust boundary names the code or config that enforces it.
