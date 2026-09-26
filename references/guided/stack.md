# Guided: stack (tier 1.4)

Copy this skeleton into `.stack-ready/STACK.md` and replace every `{{...}}`. Look up current versions, prices, and vendor status before you score; do not rely on memory.

~~~markdown
# {{Product}} stack

Checked as of {{YYYY-MM-DD}} against {{sources}}.

## Criteria

| Criterion | Weight | Why it matters here |
|---|---|---|
| {{criterion}} | {{0.0-1.0}} | {{tie to a PRD or architecture item}} |

## Shortlist

| Option | {{criterion}} | {{criterion}} | Weighted score |
|---|---|---|---|
| {{option}} | {{score}} | {{score}} | {{total}} |

## Recommendation

{{Pick for each layer: language, framework, data, hosting, observability.}}
Flip point: {{condition that would change the pick}}.
Scale ceiling: {{where this bundle stops working}}.

## Migration path

{{What leaving this bundle would take, and the lock-in to watch.}}
~~~

Before `arc-check.sh mark 1.4 done`:

1. The user can change the weights and see the ranking change.
2. The picks work together (framework, data layer, hosting, auth).
