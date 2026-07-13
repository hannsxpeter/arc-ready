# 24. Cybersecurity / SOC

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Security team monitoring threats, investigating incidents, managing vulnerabilities, and tracking compliance.

**Core entities:** Alert/Event, Incident, Vulnerability, Asset/Host, Threat Intelligence Feed, Investigation/Case, Policy/Rule, Compliance Control

**Gotchas:**
- **Alert volume is overwhelming by design** — a SOC receives thousands to millions of events per day. Without correlation (grouping related alerts into incidents), deduplication, and automated triage, the dashboard is unusable. Build for filtering and prioritization, not for showing everything.
- **MITRE ATT&CK framework is the shared language** — every alert and incident should map to ATT&CK tactics and techniques. Analysts expect to see TTPs (Tactics, Techniques, Procedures), not just raw log lines.
- **Mean Time to Detect (MTTD) and Mean Time to Respond (MTTR) are the KPIs** — the dashboard must track these per incident type, per analyst, over time. They drive staffing and process decisions.
- **Investigation workflows are non-linear** — an analyst pivots from an IP to a host to a user to a file hash to another host. The dashboard must support this "investigation graph" pattern — click an IOC (Indicator of Compromise), see everything related.
- **Threat intelligence feeds are external data integrations** — STIX/TAXII format feeds, commercial threat intel (Recorded Future, CrowdStrike), OSINT feeds. IOCs (IPs, domains, file hashes) must be enriched and correlated against internal telemetry.
- **Chain of custody matters for forensics** — evidence collected during an investigation (memory dumps, disk images, log exports) must be hashed, timestamped, and stored immutably. This is legal evidence.
- **Compliance posture tracking is continuous** — SOC 2, ISO 27001, NIST CSF, PCI DSS, HIPAA controls mapped to evidence. Each control has a status (met/partially met/not met) with supporting evidence and review dates.
- **SOAR playbook execution is how modern SOCs actually respond** — automated workflows: phishing alert > extract URLs > check threat intel > isolate endpoint > reset credentials > notify user. Dashboard needs: playbook builder, execution trace per incident, manual approval gates, playbook metrics. Without SOAR, the dashboard is read-only.
- **Vulnerability management is a full lifecycle, not just scan results** — discovery > enrichment (add EPSS score, check CISA KEV catalog) > prioritization (CVSS + exploitability + asset criticality + exposure) > assignment with SLA > remediation > verification rescan > exception management. CVSS alone is inadequate — a CVSS 10 on an air-gapped test server is lower priority than a CVSS 7.5 on an internet-facing production database.
- **Attack surface management is distinct from vulnerability scanning** — external asset discovery (including shadow IT), exposure validation, cloud security posture (CSPM), certificate monitoring, DNS/subdomain takeover risks. This is what an attacker sees from outside.
- **Threat hunting is proactive, not reactive** — analysts form hypotheses and search historical data for evidence. Dashboard needs: hunting query workspace, campaign tracker, and the ability to convert findings into automated detection rules.

**Compliance:** SOC 2, ISO 27001, NIST CSF, PCI DSS, HIPAA (if healthcare data), GDPR (incident notification within 72 hours), industry-specific regulations, breach notification laws (vary by state/country).

**UX users expect:** Alert queue with severity/priority, incident timeline with event correlation, threat map (geographic), MITRE ATT&CK matrix heatmap, vulnerability scanner results with CVSS scores, asset inventory with risk scores, compliance control matrix with evidence status, runbook/playbook execution tracker.

**Seed data shape:** 200 assets (servers, endpoints, network devices) across 3 network segments. 5,000 security events spanning 7 days. 15 incidents (10 resolved, 3 investigating, 2 new) mapped to MITRE ATT&CK TTPs. 100 vulnerabilities from scan results with CVSS scores (20 critical, 30 high, 50 medium). 3 threat intel feeds with 500 IOCs. 1 active investigation with a 5-hop pivot chain (IP > host > user > file hash > second host). 40 compliance controls with evidence status (30 met, 5 partially met, 5 not assessed). MTTD and MTTR metrics for last 90 days.
