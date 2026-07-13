# 15. IoT / Device Management

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Operations team monitoring devices, telemetry, firmware, and alerts at scale.

**Core entities:** Device, Sensor, Telemetry Reading, Alert/Alarm, Firmware Version, Device Group/Fleet, Command, Configuration Profile

**Gotchas:**
- **Telemetry volume is orders of magnitude beyond CRUD** — 10,000 devices x 10 metrics x every 10 seconds = 600,000 data points/minute. PostgreSQL won't handle this. Use a time-series database (InfluxDB, TimescaleDB, QuestDB) with retention policies and downsampling.
- **Devices are offline by default** — commands queue and retry. Telemetry arrives out of order and in batches. "Offline" is normal, not an error, with its own alerting thresholds.
- **OTA firmware updates are high-risk deployments** — a bad update bricks thousands of devices. Staged rollouts (1% > 10% > 50% > 100%), rollback, and success reporting are critical.
- **Alert fatigue kills usefulness** — deduplication, suppression windows (maintenance mode), severity escalation, acknowledgment workflows, and alert correlation (100 devices in same location = one root cause).
- **Device provisioning is a security boundary** — unique credentials (certificates), device attestation, secure enrollment. Compromised credentials must be revocable per-device.
- **Edge vs. cloud processing determines architecture** — some computation must happen at the edge. The dashboard manages edge gateway config, local rule engines, and data forwarding.

**Compliance:** FDA (medical devices), FCC (RF devices), GDPR (if devices collect personal data), IEC 62443 (industrial IoT), data sovereignty for cross-border deployments.

**UX users expect:** Real-time device map, telemetry time-series charts with zoom/pan, alert list with severity and acknowledgment, live device metrics, fleet health scores, firmware rollout tracker, threshold configuration.

**Seed data shape:** 50 devices across 3 device groups (20 sensors, 20 actuators, 10 gateways). 35 online, 10 offline (last seen varied), 5 in error state. 7 days of telemetry data (temperature, humidity, battery) at 30-second intervals — downsampled to hourly for older data. 200 alerts (150 acknowledged, 30 open, 20 auto-resolved). 3 firmware versions with 1 staged rollout in progress (40% complete). 5 alert threshold configurations.
