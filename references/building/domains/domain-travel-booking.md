# 7. Travel / Hospitality / Booking

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Property or tour operator managing listings, availability, reservations, and guest communication.

**Core entities:** Listing/Property/Room, Reservation/Booking, Availability, Rate/Pricing, Guest, Channel (OTA), Calendar Block

**Gotchas:**
- **Availability is a time-slot matrix, not a boolean** — a hotel room is available per-night, a tour per-time-slot. Overbooking is intentional in some domains (airlines) and catastrophic in others (vacation rentals).
- **Rate management is multi-dimensional** — rates vary by date, day of week, season, length of stay, occupancy, booking channel, lead time, member status, and promo code. A "price" field is meaningless; you need a rate engine.
- **Channel management creates double-booking risk** — listings on Booking.com, Airbnb, Expedia, and direct must sync availability in near-real-time. A booking on one channel must instantly block dates on all others.
- **Cancellation policies are complex business logic** — "Free until 48 hours before check-in, 50% for 24-48 hours, no refund within 24 hours" with timezone considerations (whose timezone?), force majeure, and partial cancellations.
- **Timezone handling is critical and pervasive** — a hotel in Tokyo booked by a user in New York: checkout is 11 AM JST but the confirmation email shows the guest's local time. Cancellation deadlines evaluate in the property's timezone.
- **Guest communication has timing requirements** — confirmation immediately, pre-arrival info 3 days before, check-in instructions day-of, review request post-checkout. Automated sequences tied to booking dates.

**Compliance:** PCI DSS for payment, local tourism/lodging taxes and reporting, ADA for US properties, anti-discrimination laws, data retention for tax.

**UX users expect:** Calendar grid for availability (green/yellow/red), drag-to-block dates, rate calendar (price heatmap), reservation timeline (Gantt-style), channel distribution status, guest communication timeline, dynamic pricing suggestions.

**Seed data shape:** 3 properties (hotel with 10 rooms, vacation rental with 1 unit, tour operator with 3 daily slots). 40 reservations spanning next 90 days in mixed states (confirmed, checked-in, checked-out, cancelled, no-show). Rates that vary by day-of-week and season. 2 channel sources (direct + Booking.com). 5 calendar blocks (owner stays, maintenance). 1 reservation with a pending cancellation inside the refund window. Guest communications at various stages.
