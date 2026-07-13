# 34. Data / Analytics / BI

**Taxonomy role:** Product archetype. Add the subject-matter industry as a separate overlay.

**Archetype:** Analysts, operators, or customers exploring governed metrics, reports, semantic models, and data freshness.

**Core entities:** Data Source, Dataset, Metric Definition, Dimension, Query, Dashboard, Report, Refresh Job, Data Quality Check, Access Policy

**Domain landmines:** Metric definitions drift across dashboards; OLTP workloads are starved by analytical scans; freshness is unstated; late-arriving data rewrites history; row-level security is lost in exports or caches; timezone and fiscal-calendar choices change aggregates; query cost and concurrency are invisible; charts omit the underlying rows and provenance.

**Compliance and freshness caveat:** Privacy, residency, retention, and purpose limitation follow the source data and jurisdiction. Verify connector capabilities, warehouse pricing, and current access-control behavior before committing. Do not expose sensitive dimensions merely because the warehouse can query them.

**Expected operator experience:** A semantic metric catalog, visible freshness and lineage, filterable dashboards with drill-through, query status and cancellation, scheduled delivery, export controls, and warnings when data is partial or stale.

**Test and fixture shape:** Versioned small and large datasets with late events, nulls, duplicates, timezone boundaries, row-level policies, metric goldens, freshness breaches, cancelled queries, and cost ceilings. Tests cover semantic consistency, access propagation, incremental recomputation, and export parity.

**Stack mapping:** Start with `Analytics / BI / Dashboards` in `references/planning/domain-stacks.md`. Select Data or ML in `references/building/product-form-router.md` for pipeline products and Web application for customer-facing analytics.
