# 10. Logistics / Supply Chain / Fleet

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Operations team managing shipments, vehicles, drivers, routes, and warehousing.

**Core entities:** Shipment/Consignment, Vehicle/Asset, Route, Driver/Operator, Warehouse/Depot, Load/Cargo, Proof of Delivery, Geofence

**Gotchas:**
- **Location tracking is a high-frequency data stream** — vehicles report GPS every 5-30 seconds. This is time-series data needing specialized storage (TimescaleDB, InfluxDB). PostgreSQL rows will fail at scale.
- **Route optimization is NP-hard** — vehicle capacity, delivery time windows, driver hours-of-service, traffic, multi-stop optimization. Integrate with an optimization engine (Google OR-Tools, HERE, Routific). Don't build one.
- **Chain of custody and proof of delivery are legal documents** — photos, signatures, timestamps, GPS at delivery are evidence in disputes. This data must be immutable.
- **Hours of Service regulations are strict** — US DOT: max 11 hours driving after 10 hours off, 14-hour window, 30-minute break after 8 hours. EU tachograph rules differ. Violations mean heavy fines.
- **ETA calculations must account for real-world constraints** — loading/unloading time, traffic, driver breaks, customs for cross-border, weight stations. Naive distance/speed is always wrong.
- **Vehicle maintenance is predictive, not just calendar-based** — intervals based on mileage, engine hours, AND time. Deferred maintenance must trigger escalating alerts.

**Compliance:** DOT/FMCSA, EU driving/rest regulations, hazmat transport rules, customs/import-export docs, cold chain compliance (temperature logging for perishables), ELD mandate.

**UX users expect:** Real-time map with vehicle positions, route visualization, driver HOS status bars, shipment tracking timeline, warehouse slot grid, vehicle maintenance dashboard with red/yellow/green, geofence alerts.

**Seed data shape:** 15 vehicles (12 active, 2 in maintenance, 1 decommissioned). 8 drivers with varied HOS states (2 near daily limit, 1 on mandatory rest). 50 shipments (30 delivered with proof-of-delivery, 10 in transit with GPS breadcrumbs, 5 pending pickup, 3 delayed, 2 with exceptions). 2 warehouses with slot occupancy. 100,000 GPS data points across the fleet. 5 geofences. 3 vehicles with upcoming maintenance based on mileage.
