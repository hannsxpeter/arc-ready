# 8. Sports / Fitness

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Gym, studio, or club managing members, classes, schedules, and trainer assignments.

**Core entities:** Member/Athlete, Class/Session, Schedule, Membership Plan, Trainer/Coach, Booking/Check-in, Workout/Program, Body Metrics

**Gotchas:**
- **Class capacity and waitlists are real-time constraints** — a class with 20 spots must enforce capacity at booking time, manage a waitlist with auto-promotion on cancellation, and handle no-shows (which may incur penalties).
- **Recurring schedules with exceptions are hard** — "Spinning every Tuesday/Thursday at 6 PM, except holidays, with a substitute instructor on March 5th" is a recurring event with overrides. iCal RRULE + EXDATE is the minimum viable approach.
- **Membership freezes, pauses, and transfers are not edge cases** — members freeze for injury/travel, pause seasonally, transfer locations, or convert monthly to annual. Each has proration and billing implications.
- **Wearable/device integration generates high-volume time-series data** — heart rate every second, GPS tracks, rep counts. This needs time-series storage and aggregation, not relational rows.
- **Late cancellation and no-show policies drive revenue** — "Cancel 2+ hours before or lose a class credit" is business-critical logic. Grace periods, penalty credits, and strike systems are expected.
- **Family/group accounts share billing but have individual profiles** — a parent pays for the family membership but each member has their own bookings and progress.

**Compliance:** Health data privacy (jurisdiction-dependent), minor athlete protections (parental consent, safeguarding), PCI for recurring billing, liability waivers (digital signature).

**UX users expect:** Weekly schedule grid, class capacity indicators, member check-in kiosk mode, workout builder (sets x reps x weight), progress charts, leaderboards, trainer schedule calendar.

**Seed data shape:** 80 members (60 active, 10 frozen, 5 expired, 5 on trial). 4 membership plans (monthly, annual, family, drop-in). 6 class types with recurring weekly schedules. 200 bookings over 30 days — 3 classes at capacity with waitlists, 5 no-shows, 2 late cancellations. 4 trainers with schedules. 1 family account with 3 members. 10 members with body metric histories (weight/measurements over 6 months).
