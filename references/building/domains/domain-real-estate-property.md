# 9. Real Estate / Property Management

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Property manager handling units, tenants, leases, maintenance, and owner reporting.

**Core entities:** Property, Unit, Tenant, Lease, Maintenance Request, Rent Payment, Listing, Inspection

**Gotchas:**
- **Lease terms are legal contracts with complex date logic** — start/end dates, renewal options (auto-renew vs. month-to-month), rent escalation clauses, security deposit rules (state-specific maximums and return timelines), early termination penalties.
- **Rent accounting has trust account requirements** — many jurisdictions require security deposits in separate escrow/trust accounts. Commingling operating funds with tenant deposits is illegal in most US states.
- **Maintenance requests have legal response timelines** — habitability issues (heat, water, structural) have legally mandated response times. Treating all requests equally causes legal violations.
- **Property financials need owner-level reporting** — each owner needs P&L statements, 1099 generation, reserve fund accounting, and CAM reconciliation. This is per-property-owner accounting.
- **Vacancy and turnover is a workflow** — move-out inspection > deposit itemization > unit make-ready > listing > showing > application > lease signing > move-in inspection. Each step has timelines and dependencies.
- **Fair housing compliance is non-negotiable** — screening criteria must be applied uniformly. The dashboard must not surface protected class information to decision-makers during application review.

**Compliance:** Fair Housing Act, state-specific landlord-tenant laws (vary wildly), security deposit laws, lead paint disclosure (pre-1978), habitability requirements, eviction process requirements, 1099-MISC for owner payments.

**UX users expect:** Portfolio overview with vacancy rates, unit-level P&L, lease expiration timeline, maintenance request kanban, tenant ledger, inspection checklist with photo capture, comparative market analysis.

**Seed data shape:** 3 properties with 20 total units (15 occupied, 3 vacant, 2 in turnover). 15 active leases with varied terms (1 expiring this month, 1 month-to-month, 1 with rent escalation). 30 maintenance requests (20 completed, 5 open, 3 urgent/habitability, 2 scheduled). 6 months of rent payments with 2 late payments and 1 partial. 2 property owners with separate financials. Security deposits in trust. 1 unit in make-ready workflow.
