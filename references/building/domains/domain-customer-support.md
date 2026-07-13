# 13. Customer Support / Helpdesk

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Support team managing tickets, SLAs, queues, and customer communication.

**Core entities:** Ticket/Case, Queue, Agent, SLA, Canned Response/Macro, Knowledge Base Article, Customer, Escalation

**Gotchas:**
- **SLA tracking is a contractual obligation** — "First response within 1 business hour" must account for business hours, timezone of the contract, holidays, and SLA pausing when waiting on customer response. A ticket opened Friday at 4:30 PM with a 4-hour SLA is due Monday, not Saturday.
- **Ticket routing is multi-factor** — skills-based (language, product expertise), round-robin with capacity limits, priority queue jumping, VIP routing, and follow-the-sun for global teams.
- **Merging duplicate tickets must preserve context** — keep all messages from both, notify both requesters, consolidate SLA timers (use the earlier/stricter one).
- **Collision detection prevents duplicate work** — two agents viewing the same ticket need real-time presence indicators ("Agent Smith is typing").
- **Escalation paths are time-triggered and condition-triggered** — "If no response in 30 minutes, escalate to Tier 2. If Enterprise plan, escalate immediately." Automated rules running continuously.
- **CSAT surveys have timing requirements** — too early or too late = low response. Survey fatigue must be managed (don't survey the same customer every time).

**Compliance:** GDPR (right to delete, but ticket history may be needed for disputes), PCI DSS (mask card numbers in messages), data retention policies.

**UX users expect:** Queue with SLA countdown timers (red when breaching), split-pane (list + detail), customer context sidebar, canned response insertion, internal notes vs. public replies, collision indicators, satisfaction trends.

**Seed data shape:** 100 tickets spanning 30 days — 15 open (3 breaching SLA, 2 escalated), 80 resolved, 5 pending customer response. 6 agents across 2 tiers. 3 SLA policies (enterprise 1hr, pro 4hr, free 24hr). 20 canned responses. 10 knowledge base articles. 500 messages (mix of public replies and internal notes). CSAT scores on 60% of resolved tickets. 2 merged tickets. 1 VIP customer with priority routing.
