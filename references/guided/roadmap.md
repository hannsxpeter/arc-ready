# Guided: roadmap (tier 1.3)

Copy this skeleton into `.roadmap-ready/ROADMAP.md` and replace every `{{...}}`.

~~~markdown
# {{Product}} roadmap

Team size: {{number}} engineers with {{number}} available weeks.
Parallel tracks: {{number, never more than the team size}}

## Now

- [commitment] {{slice}} ({{upstream id, for example R-01 or ADR-02}}). Done when {{observable check}}. Target: {{date}}.

## Next

- [direction] {{outcome}} ({{upstream id}}). No date yet.

## Later

- [open question] {{item}}. Owner: {{name}}. Decide by {{event or date}}.

## Slice queue for the build

1. {{first vertical slice, riskiest or most load-bearing first}}
2. {{second slice}}
~~~

Before `arc-check.sh mark 1.3 done`:

1. Every commitment cites an upstream requirement, component, or ADR.
2. Only the Now horizon carries dates.
3. The riskiest work comes first.
