# 28. Telecommunications / ISP

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Telecom or ISP managing subscribers, service provisioning, network operations, and usage-based billing.

**Core entities:** Subscriber/Account, Service Plan, Circuit/Connection, Network Element, Trouble Ticket, Usage Record (CDR), Invoice, Coverage Area

**Gotchas:**
- **Service provisioning is a multi-system orchestration** — activating a new subscriber touches: billing system (create account), network (provision bandwidth, assign IP, configure RADIUS), hardware (ship modem/router, schedule install), and CRM (create contact, schedule onboarding). Each step can fail independently. Rollback on failure is a saga/compensation problem.
- **Usage-based billing with CDRs (Call Detail Records) is high-volume metering** — millions of CDR events per day. Each record: caller, callee, start time, duration, data transferred, cell tower, service type. Rating (converting CDR events to charges) applies complex rules: time-of-day rates, bundle allowances, roaming surcharges, family plan sharing, rollover data.
- **Network monitoring is a real-time operations concern** — SNMP traps, syslog events, performance metrics (latency, packet loss, utilization) from thousands of network elements. Outage detection, root cause analysis, SLA compliance tracking. The dashboard must show network health maps with drill-down to individual elements.
- **Trouble ticket SLAs are regulated** — the FCC and state PUCs mandate response and resolution times for service outages. Telecom SLAs are contractual AND regulatory, unlike typical helpdesk SLAs.
- **Number portability is a regulated workflow** — customers porting phone numbers in/out. The Local Number Portability process has specific timelines (simple port: 1 business day), and losing carriers cannot block ports. Tracking port status and compliance is dashboard functionality.

**Compliance:** FCC regulations, state PUC rules, CALEA (lawful intercept), CPNI (Customer Proprietary Network Information) privacy, E-911 requirements, universal service fund contributions, number portability regulations.

**UX users expect:** Subscriber account dashboard with service status, network health map with outage overlay, trouble ticket queue with SLA timers, usage analytics (data/voice/text), provisioning workflow tracker, coverage map, invoice management with CDR detail drill-down.

**Seed data shape:** 200 subscribers across 4 plan types (basic, standard, premium, business). 50,000 CDR events spanning 30 days. 10 network elements with health metrics. 30 trouble tickets (20 resolved, 10 open with SLA tracking). 3 service outages with affected subscriber counts. 5 active number port requests. Monthly invoices with usage breakdown.
