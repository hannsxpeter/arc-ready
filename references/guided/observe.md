# Guided: observe (tier 3.2)

Copy this skeleton into `.observe-ready/OBSERVE.md` and replace every `{{...}}`.

~~~markdown
# Observe

## SLOs

- Journey: {{user journey}}. SLO: {{percent}} of {{events}} succeed under {{ms}} over {{window}}.

## Error budget policy

Owner: {{name}}. When {{percent}} of the budget is spent: {{action, for example freeze feature work}}.

## Alerts

{{User-visible symptom}} pages {{who}} through {{delivery path}}.

## Runbooks

{{Runbook}}: executed on {{date}} ({{drill or real}}).

## Evidence state

installation-ready: synthetic fire on {{date}} reached {{person}} through the real paging path.
operationally-mature: {{only after a real event, with its date; otherwise write "not yet evidenced"}}.
~~~

Before `arc-check.sh mark 3.2 done`: fire one controlled alert end to end, label it synthetic, and never describe a drill as an incident.
