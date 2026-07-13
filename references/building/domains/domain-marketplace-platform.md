# 26. Marketplace / Platform

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Two-sided platform connecting buyers and sellers (or providers and consumers), managing trust, transactions, and disputes.

**Core entities:** Seller/Provider, Buyer/Consumer, Listing, Transaction/Order, Review/Rating, Dispute, Commission/Fee, Payout, Verification

**Gotchas:**
- **Two-sided means two dashboards (at least)** — sellers see their listings, orders, payouts, and performance. Buyers see their orders, reviews, and saved items. Platform admins see everything plus disputes, compliance, and marketplace health. Three distinct RBAC contexts, not one.
- **Trust and safety is a dedicated function** — user verification (ID, business license, background check), content moderation (listing photos, descriptions), fraud detection (fake reviews, shill bidding, payment fraud), and abuse reporting. This is not an afterthought; it's a full team's worth of tooling.
- **Escrow/payment splitting is complex** — buyer pays > platform holds > seller fulfills > platform releases to seller minus commission. Refund flows, dispute holds, partial fulfillment, split payments to multiple sellers in one order. You need a payment orchestration layer (Stripe Connect, PayPal for Marketplaces).
- **Commission structures are rarely simple** — they vary by category, by seller tier, by volume, by promotional period. "15% on electronics, 8% on books, 5% for Gold sellers, 0% for the first 90 days" is a real commission table.
- **Search and discovery are core product features** — not just a search bar. Relevance ranking, category navigation, filters (price, location, rating, availability), promoted/sponsored listings, and personalized recommendations. Search quality directly drives GMV.
- **Dispute resolution is a three-party workflow** — buyer claims item not received, seller provides tracking, platform arbitrates. Escalation tiers, evidence submission, resolution deadlines, and appeal processes. The dispute dashboard is as important as the order dashboard.
- **Review integrity affects the entire marketplace** — fake review detection, review gating (only verified purchasers), review response from sellers, rating aggregation with recency weighting, and review moderation for prohibited content.
- **Geographic and regulatory complexity** — a marketplace operating in multiple countries must handle: local payment methods, local tax collection and remittance (marketplace facilitator laws in 46+ US states — the marketplace, not the seller, collects and remits), local consumer protection, and local seller verification requirements.
- **Seller onboarding is a multi-step verification pipeline** — identity verification (KYC/KYB), bank account verification (micro-deposits or Plaid), tax form collection (W-9/W-8BEN), 1099-K threshold tracking, restricted category approval. The pipeline is a state machine: `registered > identity_verified > bank_verified > tax_form_verified > active`. Blocking at any step needs clear communication.
- **Category taxonomy is a schema-per-category problem** — each leaf category has different required attributes: "Laptops" needs RAM/storage/screen; "Dresses" needs size/color/material. Attribute types include enums, free text, numeric with units. Changing taxonomy after thousands of listings exist is a major migration.
- **Multi-channel inventory sync prevents overselling** — sellers list on your marketplace + Amazon + eBay. A sale on Amazon must decrement your quantity within seconds. Real-time sync, safety stock buffers, centralized order management across channels.
- **Shipping integration is the physical fulfillment layer** — rate calculation (carrier APIs), label generation, tracking integration, shipping SLA enforcement (ship within X days or face penalties), return logistics. Makes or breaks buyer trust.
- **Seller analytics is a dashboard-within-a-dashboard** — every seller needs: sales trends, top listings, conversion rates, traffic sources, return rate, satisfaction metrics, payout history, listing quality scores with improvement recommendations.

**Compliance:** Marketplace facilitator tax laws (US, state-by-state), consumer protection (EU Consumer Rights Directive, right of withdrawal), payment services regulations (PSD2 in EU), KYC/AML for seller onboarding, digital services act (EU, content moderation obligations), platform liability laws.

**UX users expect:** Seller dashboard with earnings/payouts/performance, buyer order tracking, admin moderation queue, dispute resolution workflow with evidence viewer, marketplace health dashboard (GMV, take rate, seller churn, buyer satisfaction), category management, search analytics (top queries, zero-result queries), promoted listing management.

**Seed data shape:** 30 sellers (20 active, 5 new/unverified, 3 suspended, 2 churned) across 3 tiers with different commission rates. 100 listings across 8 categories with varied pricing. 200 orders spanning 60 days (160 completed, 15 in transit, 10 pending, 5 disputed, 5 refunded, 5 cancelled). 500 reviews with ratings (4 flagged for moderation — 2 suspected fake). 3 active disputes at different stages. 10 payouts completed, 2 pending. Search analytics: top 20 queries with click-through rates, 5 zero-result queries. 5 promoted listings with spend and impression data. GMV and take-rate metrics for 6 months.
