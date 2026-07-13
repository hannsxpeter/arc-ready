# 2. E-commerce / Retail

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Store admin managing products, orders, inventory, and fulfillment.

**Core entities:** Product/Variant/SKU, Order, Cart, Inventory Location, Fulfillment, Return/Refund, Promotion/Discount

**Gotchas:**
- **A product is not a row — it's a tree.** Product > Variant (size/color) > SKU > Inventory per location. Flattening this causes data integrity nightmares when a size is out of stock at one warehouse but available at another.
- **Price is not a single number** — list price, sale price, member price, bulk/tiered pricing, currency-specific pricing, tax-inclusive vs. tax-exclusive. A "price" column is always wrong.
- **Inventory is a ledger, not a counter** — decrementing a quantity field causes race conditions. Inventory should be event-sourced: reserved, allocated, shipped, returned, adjusted, damaged. "Available" is a computed projection.
- **Order state machines are complex and partially reversible** — pending > paid > partially_shipped > shipped > partially_returned > refunded. Many transitions happen in parallel.
- **Tax calculation is locale-specific and changes constantly** — US sales tax varies by state/county/city, EU VAT varies by product category and buyer location. Use a tax service API (Avalara, TaxJar). Never hardcode rates.
- **Promotions interact combinatorially** — "20% off + free shipping + buy-2-get-1" — which stack? Promotion engines are their own domain.
- **Returns are not the inverse of orders** — partial refunds, restocking fees, store credit vs. original payment method, inventory going to a different location.

**Compliance:** PCI DSS if handling card data (use tokenized payment providers), consumer protection laws (EU cooling-off periods), ADA/WCAG for storefront.

**UX users expect:** Drag-to-reorder product images, bulk inventory update via spreadsheet, order timeline with every state transition, SKU matrix editor (size x color grid), real-time inventory badges.

**Seed data shape:** 25 products with 2-4 variants each (size/color), realistic pricing ($9.99-$299.99 in integer cents). 2 inventory locations. 50 orders spanning 90 days in mixed states (3 pending, 5 shipped, 2 partially_returned, 1 refunded, rest completed). 5 customers with multiple orders, 15 with one. 2 active promotions (one percentage, one free-shipping). 1 product out of stock at one location but available at the other.
