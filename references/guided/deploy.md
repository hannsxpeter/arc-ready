# Guided: deploy (tier 3.1)

Copy this skeleton into `.deploy-ready/DEPLOY.md` and replace every `{{...}}`.

~~~markdown
# Deploy

## Pipeline

Build once: {{artifact type}} with digest recorded. The same artifact is promoted through {{environments}}; nothing is rebuilt per environment.

## Migrations

{{Each migration}}: code-only or data-forward. Data-forward changes use expand and contract across {{number}} deploys, with a compensating-forward plan.

## Canary

{{Share of traffic}} for {{duration}}. Stop rule: roll back automatically if {{metric}} exceeds {{threshold}}.

## Rollback

Procedure: {{steps}}. Tested on {{date}}: {{what was rolled back and how long it took}}.

## Secrets

Injected from {{vault or platform store}}. None are committed.
~~~

Before `arc-check.sh mark 3.1 done`: execute the rollback once and record the date and result.
