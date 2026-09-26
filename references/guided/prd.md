# Guided: PRD (tier 1.1)

Copy this skeleton into `.prd-ready/PRD.md` and replace every `{{...}}`. The gate fails while any `{{` remains.

~~~markdown
# {{Product}} PRD

## Problem

{{Who does what today, how long it takes or what it costs, and how often. Name no solution yet.}}

## Target user

{{One role in one context, with their constraints and current workaround. It must not fit a competitor's user.}}

## Success metrics

- Decision: {{metric}} moves from {{baseline}} to {{target}} by {{date}}, measured by {{method}}.
- Hypothesis: {{expected outcome}}. Validation: {{how and when you will check}}.

## Requirements

- R-01 (Must): {{capability}}
- R-02 (Must): {{capability}}
- R-03 (Should): {{capability}}
- R-04 (Could): {{capability}}
- R-05 (Won't): {{capability deliberately left out of this release}}

Cut line: ship R-01 and R-02 first.

## Non-functional requirements

{{Numbers only: p95 latency in ms, availability in percent, data volume, privacy rules, accessibility level.}}

## Out of scope

{{What this release will not do, and why.}}

## Risks and assumptions

- Hypothesis: {{assumption}}. Validation: {{test}}.
- Risk: {{risk}}. Mitigation: {{plan}}.

## Open questions

- OQ-1: {{question}} Owner: {{name}}. Due: {{YYYY-MM-DD}}.

## Handoff

- Architecture: {{scale ceiling, integrations, trust concerns}}
- Roadmap: {{deadline or appetite, team size}}
- Stack: {{hard constraints: platform, language, budget, compliance}}
~~~

Example lines that pass:

- Problem: "Solo freelance developers rebuild billable hours from memory at invoice time, losing about 2 hours a month and under-billing by about 9 percent."
- Metric: "Decision: median time to monthly totals drops from 120 minutes to under 10 within 60 days, measured by command timing."

Before `arc-check.sh mark 1.1 done`:

1. Swap a competitor's name into Problem and Target user. If the sentences still read true, rewrite them.
2. At most half the requirements are Must.
3. Every sentence is a decision, a hypothesis with a validation plan, or an open question with an owner and a date.
