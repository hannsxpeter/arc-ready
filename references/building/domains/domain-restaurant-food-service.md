# 16. Restaurant / Food Service

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Restaurant operator managing menus, orders, tables, kitchen workflow, and multi-platform delivery.

**Core entities:** Menu Item, Modifier/Addon, Order (dine-in/takeout/delivery), Table, Reservation, Ingredient/Inventory, Shift, POS Terminal

**Gotchas:**
- **Menu structure is deeply nested** — Category > Subcategory > Item > Size > Modifiers (with modifier groups: "Choose protein" allows 1, "Choose toppings" allows up to 3). Modifiers have prices, some are free, some required, availability may differ by item.
- **Kitchen Display requires order routing** — a single order's items may go to different stations (grill, fryer, bar). Each station sees only its items, tracks prep time, and coordinates firing (apps before entrees).
- **Menu availability is time-sensitive** — breakfast menu until 11 AM, happy hour 4-6 PM, 86'd items (out of stock mid-service). The POS must prevent ordering unavailable items in real-time.
- **Ingredient-level inventory affects menu availability** — running out of chicken affects 12 menu items. The system must trace ingredient-to-item relationships.
- **Split checks and partial payments are the norm** — "Split 4 ways," "pay for my items only," "put $30 on this card and the rest on that." Tip distribution across splits adds complexity.
- **Delivery integration is multi-platform** — Uber Eats, DoorDash, Grubhub arrive through different APIs with different menu mappings, commissions, and delivery areas.

**Compliance:** Food safety (HACCP, FDA Food Code), allergen disclosure (EU requires 14 allergen categories), calorie labeling, tip reporting (IRS), liquor licensing.

**UX users expect:** Visual menu builder with modifier groups, table map with status colors, KDS ticket display with timers, 86 board, daily sales summary with prior period comparison, labor cost gauge, delivery aggregation view.

**Seed data shape:** 40 menu items across 6 categories with 3 modifier groups (proteins, toppings, sizes). 15 tables in a floor plan. 100 orders from today (60 dine-in, 25 takeout, 15 delivery from 2 platforms). 5 orders in active preparation with KDS timestamps. 2 items 86'd. 8 staff with shift schedules. 30 days of daily sales history. Allergen flags on 10 items. Tip data across 50 completed checks. 3 split-check examples.
