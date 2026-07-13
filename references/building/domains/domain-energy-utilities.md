# 29. Energy / Utilities

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Utility company or energy provider managing meters, consumption, grid operations, and regulatory compliance.

**Core entities:** Meter, Customer/Account, Rate Schedule, Usage Reading, Outage, Work Order, Regulatory Filing, Renewable Certificate

**Gotchas:**
- **Meter data management is the foundation** — smart meters report consumption at 15-minute intervals. A utility with 500,000 meters generates 48 million readings per day. This is time-series data requiring specialized storage. Data validation (detecting faulty meters, estimated reads, meter tampering) is a continuous process.
- **Rate schedules are regulated and complex** — time-of-use rates (different price per kWh by time of day and season), tiered rates (first 500 kWh at one price, next 500 at another), demand charges (peak kW usage), net metering (solar customers selling back to grid). Rate changes require regulatory approval and public notice periods.
- **Outage management is safety-critical** — outage detection (from meter last-gasp signals, customer reports, SCADA), crew dispatch, estimated restoration time, rolling status updates to affected customers. Mutual aid coordination during major events (storms). Regulatory reporting of outage duration and frequency (SAIDI, SAIFI metrics).
- **Demand forecasting drives grid operations** — predicting load 15 minutes, 1 hour, 1 day, and 1 year ahead. Weather-dependent. Affects wholesale energy procurement, generation dispatch, and grid stability. Machine learning models are standard.
- **Renewable energy certificates (RECs) are tradeable compliance instruments** — each MWh of renewable generation produces a REC. Tracking generation, certification, sale, and retirement of RECs is a compliance requirement for renewable portfolio standards.

**Compliance:** NERC (reliability standards), FERC (wholesale markets), state PUC rate regulation, Green Button (data access standard), EPA emissions reporting, renewable portfolio standards, PURPA (qualifying facilities), cybersecurity (NERC CIP for critical infrastructure).

**UX users expect:** Grid operations dashboard with real-time load, outage map with affected customers and ETR, customer consumption charts with rate tier visualization, demand response event management, meter health monitoring, regulatory filing tracker, renewable generation dashboard.

**Seed data shape:** 500 meters with 30 days of 15-minute interval readings. 3 rate schedules (residential, commercial, time-of-use). 10 outage events (5 resolved, 5 active with crew assignments). 200 customer accounts with billing history. 50 work orders across types (meter install, line repair, tree trimming). 30 days of demand/generation data for forecasting.
