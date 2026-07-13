# 22. Entertainment / Events

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Event organizer or venue managing shows, ticketing, artists, and attendee experience.

**Core entities:** Event, Venue/Location, Ticket/Tier, Performer/Artist, Attendee, Seating Map, Promotion/Discount, Settlement/Payout

**Gotchas:**
- **Seating maps are spatial data with business logic** — reserved seating requires a visual seat picker where each seat has a section, row, seat number, price tier, accessibility designation, and obstructed-view flag. Hold-release patterns (seats held for 10 minutes during checkout) prevent double-selling.
- **Ticket inventory has high-concurrency pressure** — 10,000 people trying to buy 500 tickets in 30 seconds. Standard database locks won't hold. Queue-based purchase flows, waiting rooms, and atomic inventory decrement (optimistic locking or database-level constraints) are required.
- **Dynamic/surge pricing is expected** — prices change based on demand, time-to-event, and remaining inventory. Early bird, last-minute, and demand-based tiers. The pricing engine must be fast and auditable.
- **Refund and transfer policies vary per event** — some events allow transfers (name change on ticket), some allow refunds until X days before, some are final sale. Policies must be per-event configurable.
- **Settlement/payout to artists and venues is a financial workflow** — ticket revenue minus fees, taxes, and venue costs, split among multiple parties. This is accounting with multiple payees per event.
- **Check-in and access control are real-time** — QR code/barcode scanning at doors, preventing duplicate entry (a scanned ticket can't enter twice), VIP vs. GA routing, and real-time attendance counts.
- **Multi-day and recurring events add calendar complexity** — festivals with multiple stages and overlapping acts, weekly show series, season passes valid for specific dates.
- **ADA accessibility is structural data, not just UI** — every seat needs an `accessibility_type` field (wheelchair, companion, limited mobility, hearing impaired). Accessible seats must be distributed throughout the venue (legal requirement), not clustered. Companion seats sell with accessible seats (1:1 ratio). If you build the seating map without accessibility types, you need a schema migration.
- **Ticket fraud and bot detection are day-one concerns** — 10,000 bots hitting your endpoint in 30 seconds. Purchase velocity detection, CAPTCHA during high-demand on-sales, verified fan queues, dynamic QR codes that change periodically, device fingerprinting.
- **Venue configurations are one-to-many** — a single venue hosts different events with different layouts: concert (standing floor, 2,500 cap) vs. gala (seated tables, 800 cap) vs. conference (theater-style, 1,200 cap). Each configuration has its own seating map.

**Compliance:** ADA accessibility for venues, local fire code capacity limits, sales tax on tickets (varies by jurisdiction), age restrictions for certain events, anti-scalping laws (jurisdiction-specific), payment card industry compliance.

**UX users expect:** Visual seating map editor, drag-and-drop event scheduling, ticket sales dashboard with real-time counters, check-in scanner interface (mobile-optimized), settlement/payout breakdown per event, marketing campaign tracking (promo code performance), attendee demographics.

**Seed data shape:** 10 events (3 upcoming, 5 past, 2 recurring weekly). 1 venue with a 500-seat map (sections, rows, accessibility seats, 2 obstructed-view). 800 tickets sold across events with 3 price tiers. 5 promo codes (2 active, 2 expired, 1 maxed out). 2 past events with completed settlements showing revenue splits. 300 check-in records for past events (including 5 duplicate scan attempts). 1 upcoming event with 60% sold and dynamic pricing active. 3 refunded tickets and 2 transfers.
