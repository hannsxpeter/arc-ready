# 35. Manufacturing / MES / Industrial Operations

**Taxonomy role:** Industry overlay.

**Archetype:** Plant operators, production supervisors, quality teams, and maintenance staff controlling work orders, equipment, material flow, and traceability.

**Core entities:** Plant, Line, Work Center, Machine, Work Order, Routing, Bill of Materials, Material Lot, Production Run, Downtime Event, Quality Check, Nonconformance, Maintenance Order

**Domain landmines:** Enterprise resource planning and machine state disagree; work-in-progress quantities are treated as simple counters; genealogy from raw lot to finished serial is missing; units and tolerances are ambiguous; clock drift corrupts event order; downtime reasons are overwritten; offline shop-floor clients lose transactions; safety interlocks are exposed as ordinary UI actions; recipe and routing versions are not tied to produced units.

**Compliance and freshness caveat:** Applicable controls depend on product and jurisdiction, such as FDA 21 CFR Part 11, GMP, ISO 9001, IATF 16949, IEC 62443, or food traceability rules. Verify current applicability with qualified owners. Separate human workflow software from safety-rated control systems.

**Expected operator experience:** Shift dashboard, line state and OEE, dispatch queue, electronic work instructions, barcode or RFID material moves, traceability search, quality holds, downtime capture, maintenance escalation, and offline-safe tablet workflows.

**Test and fixture shape:** Multiple plants and lines, versioned routings and bills of material, serialized and lot-tracked materials, partial completions, scrap, rework, machine disconnects, out-of-order telemetry, quality holds, shift changes, and recall trace exercises. Tests prove genealogy, idempotent event ingestion, unit conversion, offline synchronization, and authorization for production overrides.

**Stack mapping:** Start with `Internal Tools / Back-office` in `references/planning/domain-stacks.md`. Add `Analytics / BI / Dashboards` for historian-scale analysis and the Infrastructure or IaC form for edge and plant deployment concerns.
