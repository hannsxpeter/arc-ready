# 1. SaaS / Multi-tenant

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Platform admin for a multi-tenant product — managing organizations, subscriptions, users, feature access, and usage.

**Core entities:** Tenant/Organization, Subscription/Plan, Seat/License, Feature Flag, Usage Metric, Invoice, API Key

**Gotchas:**
- **Tenant isolation is not just auth** — a missing `WHERE org_id = ?` leaks data across tenants. Every query, every cache key, every background job must be tenant-scoped. Shared DB vs. schema-per-tenant vs. DB-per-tenant is an architectural decision that's nearly impossible to change later.
- **Plan limits are runtime constraints, not billing metadata** — "5 seats," "10GB storage," "1000 API calls/day" must be enforced in real-time at the application layer, not just checked at invoice time.
- **Subscription lifecycle has ~12 states, not 3** — trialing, active, past_due, paused, cancelled-but-active-until-period-end, downgraded-pending, upgraded-prorated, churned, reactivated, comped. Modeling this as "active/inactive" breaks.
- **Feature flags are per-tenant, per-plan, AND per-user** — a feature might be enabled for the plan but toggled off for the org, or enabled as a beta for one specific tenant. Three-dimensional matrix.
- **Usage-based billing requires idempotent event ingestion** — double-counted API calls mean incorrect invoices, chargebacks, and broken trust.
- **Impersonation/support access must be audited** — support staff viewing a tenant's dashboard must leave an audit trail and must not be able to modify billing.
- **White-labeling affects every layer** — custom domains, logos, and email from-addresses require SSL cert provisioning, DNS validation, and email deliverability config.

**Compliance:** SOC 2 Type II (expected by enterprise buyers), GDPR data processing agreements per tenant, data residency requirements (EU tenants may require EU-hosted data).

**UX users expect:** Tenant switcher in nav, plan comparison/upgrade flow inline, usage dashboards with limits as gauges, "impersonating [tenant]" banner for support staff.

**Seed data shape:** 3 orgs (1 on free, 1 on pro, 1 on enterprise trial expiring in 3 days). 8-12 users across them with all roles represented. 1 org approaching its seat limit. Usage data spanning 90 days with realistic daily variation. 2 pending invoices, 1 past-due. Feature flags with at least 1 beta feature enabled for only 1 org.
