# Guided: build (tier 2.2)

Build one vertical slice at a time from the roadmap's slice queue.

For each slice:

1. Write the failing test for the user-visible job first.
2. Wire the whole path for the product form: input, validation, permission check, domain logic, real storage or dependency, output, and every state (loading, empty, error, partial, success).
3. No `TODO` or `FIXME` comments, fake data, or stubbed calls in shipped code. Run `arc-check.sh scan`.
4. Run the tests and keep them green.
5. Update `.production-ready/STATE.md`:

~~~markdown
# Production state

## Slices
- Slice 1: {{name}}. Status: done. Tests: {{command}} passes ({{count}} tests). Demo: {{how a user performs the job}}.
- Slice 2: {{name}}. Status: {{pending or in-flight}}.

## Open questions
- {{question}} Owner: {{name}}.
~~~

Before `arc-check.sh mark 2.2 done`: a real user can do the job end to end, and `arc-check.sh gate 2.2` passes.
