# Payments & Billing

This file covers the payment integration layer — how to charge customers, manage subscriptions, process refunds, handle webhooks, and build the billing UI in a dashboard. This applies to any dashboard that touches money: SaaS, e-commerce, marketplace, non-profit, legal, hospitality, entertainment, or anything with a "billing settings" page.

The core principles: **webhooks are the source of truth** for payment state, **tokens are the only safe way** to handle card data, **integer cents are the only safe way** to handle money, and your billing UI is a read-optimized view of state managed by your payment provider + your webhook handlers.

---

## Payment provider selection

### When to use which

| Provider | Best for | Model | Base fee |
|---|---|---|---|
| **Stripe** | SaaS, e-commerce, marketplaces, platforms needing max API control | Payment Processor (you are the seller) | 2.9% + 30c |
| **Paddle** | SaaS selling globally without a finance team for multi-jurisdiction tax | Merchant of Record (they are the seller) | 5% + 50c (includes tax handling) |
| **LemonSqueezy** | Solo developers, digital products, simple subscriptions | Merchant of Record | Similar to Paddle |
| **Square** | Businesses with physical retail + online (restaurants, shops) | Payment Processor | 2.6% + 10c (in-person) |
| **Adyen** | Enterprise, high-volume, 200+ global payment methods | Payment Processor | Custom pricing |
| **Braintree** | When PayPal buyer trust matters (e-commerce, marketplace) | Payment Processor | 2.59% + 49c |

### Merchant of Record vs Payment Processor

This distinction matters for **who is legally responsible for collecting and remitting sales tax / VAT / GST.**

**Payment Processor (Stripe, Adyen, Braintree):**
- You are the seller. The processor moves money on your behalf.
- You must register for tax in each jurisdiction where you have obligations.
- You calculate, collect, file, and remit taxes. You can use Stripe Tax, TaxJar, or Avalara to automate, but you're still legally responsible.
- Pro: maximum control over pricing, billing, and customer relationship.
- Con: tax compliance burden scales with geography.

**Merchant of Record (Paddle, LemonSqueezy, FastSpring):**
- The MoR is the seller. They sell your product and pay you a royalty.
- They handle all tax calculation, collection, remittance, and filing globally.
- Pro: zero tax compliance burden.
- Con: less control over customer relationship, invoice formatting, and payment methods.

**Decision rule:** If you sell to consumers/businesses in multiple countries and don't have a finance team for multi-jurisdiction tax, use an MoR. If you need full control, use a processor + tax automation.

### Marketplace payments (Stripe Connect)

For two-sided platforms (buyers and sellers):

- **Standard accounts** — seller has their own Stripe dashboard. Least platform control, easiest onboarding.
- **Express accounts** — simplified onboarding, you control the dashboard. Best for most marketplaces.
- **Custom accounts** — you build everything. Full control, most work.

Split payments natively: charge buyer, take your platform fee, pay seller — all in one API call. Handles KYC, identity verification, and 1099 reporting.

---

## Tokenization and PCI compliance

### How tokenization works

The customer enters their card into a Stripe-hosted iframe (Element) or Stripe-hosted page (Checkout). Stripe captures the card, stores it securely, and returns a token (`pm_1234abc`). Your server never sees the raw card number.

### PCI SAQ levels

| SAQ | When it applies | Requirements | Dashboard guidance |
|---|---|---|---|
| **SAQ A** | Hosted payment page / iframe (Stripe Checkout, Elements in iframe) | ~22 | **This is what you want.** |
| **SAQ A-EP** | Your page embeds payment form via JavaScript (Stripe.js on your page) | ~140 | Acceptable. Stripe often qualifies you as SAQ A anyway. |
| **SAQ D** | You handle/store/transmit raw card data | 300+ | **Never do this.** |

### What you can and cannot store

| Can store | Cannot store |
|---|---|
| Last 4 digits, card brand, expiry, cardholder name | Full card number (PAN) |
| Stripe PaymentMethod ID (token) | CVV / CVC |
| Billing address | Magnetic stripe data, PIN |

### Practical PCI checklist

- Use Stripe Elements or Checkout — card data never touches your server
- Serve your site over HTTPS always
- Don't log request bodies that might contain card data
- Don't store card data in analytics, error tracking, or logging tools
- Set CSP headers on pages with payment forms to prevent script injection
- Load Stripe.js from `js.stripe.com` — never self-host
- Complete the SAQ annually via Stripe Dashboard

---

## Checkout flows

### One-time payment flow

```
Cart / order summary
  > Create PaymentIntent server-side (amount, currency, customer)
  > Return client_secret to frontend
  > Frontend collects payment via Payment Element
  > stripe.confirmPayment() called
  > If SCA required: 3DS challenge modal appears automatically
  > Webhook: payment_intent.succeeded fires
  > Webhook handler triggers fulfillment
  > Show confirmation page
```

### Payment Intent lifecycle

```
created
  > requires_payment_method  (waiting for card)
    > requires_confirmation  (card attached, awaiting confirm)
      > requires_action      (3DS/SCA challenge)
      |   > processing       (bank processing)
      |     > succeeded  or  failed
      > processing           (no 3DS needed)
        > succeeded  or  failed
```

Update your database via webhooks, not API responses. The API tells you the current state; webhooks tell you about async changes (3DS completion, delayed processing).

### Strong Customer Authentication (SCA / 3D Secure)

Required for electronic card payments in the EEA. In practice:
- Stripe triggers 3DS automatically when regulations require it or when the issuer requests it.
- Using Payment Intents + Payment Element, 3DS is handled transparently — a modal appears.
- You don't build a 3DS flow manually. Just use `stripe.confirmPayment()`.
- For recurring subscriptions: first payment triggers SCA, subsequent charges use the saved mandate.

### Client-side integration choice

| Method | How | Best for |
|---|---|---|
| **Payment Element** (Elements) | Stripe-hosted iframe embedded in your page. Full UX control around it. | Billing embedded inline in your dashboard settings. |
| **Checkout Sessions** | Redirect to Stripe-hosted page (or embed as iframe). Stripe handles the entire checkout. | Faster integration, upgrade flows, less code. |
| **Payment Links** | No-code shareable URL. | Ad-hoc invoicing, manual charges. |

### Tax calculation integration

Three options:
1. **Stripe Tax** — enable in Dashboard, add `automatic_tax: { enabled: true }` to Checkout/Invoice. Covers 50+ countries. Simplest.
2. **TaxJar** — deeper US tax calculation. AutoFile for automated filing/remittance.
3. **Avalara** — enterprise-grade, most comprehensive global coverage.

Tax is calculated at the line-item level before payment confirmation.

---

## Subscription management

### Subscription lifecycle

```
trialing > active > past_due > unpaid > canceled
                  > paused (if enabled)
```

- **trialing** — free trial. Charges at trial end if payment method is on file.
- **active** — payment succeeded, subscription running.
- **past_due** — payment failed, retry window open (dunning in progress).
- **unpaid** — all retries exhausted, not yet canceled (grace period).
- **canceled** — terminated. Customer loses access.
- **paused** — no invoices generated. Customer retains the subscription object.

### Trial-to-paid conversion

**With payment method upfront** (higher conversion, recommended):
Collect card at signup, trial starts, card charged automatically when trial ends.

**Without payment method upfront** (higher trial signup rate, lower conversion):
When trial ends, invoice is created. Prompt user to add payment method. If they don't, subscription goes to `past_due`.

### Plan changes and proration

**Upgrade (immediate):** Customer on $50/mo upgrades to $100/mo mid-cycle (day 15 of 30).
- Credit for unused old plan: $50 x (15/30) = $25
- Charge for remaining new plan: $100 x (15/30) = $50
- Net: $25 charged immediately

**Downgrade (end of period):** No proration. New price takes effect at next renewal.

**Proration options:**
- `create_prorations` (default) — line items added to next invoice
- `always_invoice` — proration invoiced immediately
- `none` — no proration, change at next renewal

### Dunning (failed payment handling)

When payment fails, the dunning sequence begins:

**Retry schedule (configurable):**
- Day 0: initial failure. `invoice.payment_failed` webhook fires.
- Day 1: first retry. Email: "Your payment failed, update your card."
- Day 3: second retry. Email: "Still unable to charge your card."
- Day 5: third retry. Email: "Subscription will be canceled in 2 days."
- Day 7: final retry. If fails: subscription canceled or moved to unpaid.

**Smart retries:** Stripe's ML picks the optimal retry time (e.g., Fridays when paydays are common). Recovers 15-20% of failures automatically.

**Card updater:** When Visa/Mastercard reissues a card, Stripe receives the updated details and silently updates the token. Prevents many expiration failures without customer action. Enabled by default.

**Notification sequence:**
1. Pre-dunning (30 days before card expiry): "Your Visa ending in 4242 expires next month."
2. Payment failed (immediately): "We couldn't charge your card."
3. Retry 1 failed (day 3): "Second attempt failed."
4. Final warning (day 6): "Your subscription will be canceled tomorrow."
5. Canceled (day 7): "Your subscription has been canceled. Reactivate anytime."

### Cancellation flows

**End-of-period (recommended default):** Customer retains access until current period ends. No refund needed.

**Immediate:** Access revoked immediately. Proration credit generated for unused time.

**Cancellation UX:**
1. "Cancel subscription" button in billing settings
2. Ask reason (dropdown: too expensive, not using it, switching, missing features, other)
3. Show what they lose with the date ("You'll lose access to X, Y, Z on March 15")
4. Offer alternatives: pause, downgrade, discount
5. Confirm cancellation
6. Confirmation with reactivation option

**Win-back offers:** When user selects "too expensive," offer 20-30% discount for 3 months. Saves 10-15% of cancellations.

### Coupons and discounts

| Type | Example | Duration options |
|---|---|---|
| Percentage off | 20% off | Once, repeating (N months), forever |
| Fixed amount off | $5 off | Once, repeating, forever |
| Promotion code | "WELCOME20" | Same, plus redemption limits, first-time-only |

Create coupons server-side, expose promotion codes to customers. Track redemption counts.

---

## Invoice system

### Invoice data model

```
Invoice
  id, number, status
  customer_id, customer_email
  currency, period_start, period_end, due_date
  subtotal (before tax/discount)
  tax (total)
  total (subtotal + tax - discount)
  amount_due (total - credits)
  amount_paid, amount_remaining
  line_items[]
    description, quantity, unit_amount, amount, tax_amounts[], discount_amounts[]
  payment_intent_id
  metadata{}
```

### Invoice states

```
draft > open > paid
             > void (canceled, no payment expected)
             > uncollectible (written off)
```

### Auto-invoicing vs manual

**Auto-invoicing:** Stripe generates an invoice each billing period. Created as draft, finalized, payment attempted against default method. Use `collection_method: "charge_automatically"`.

**Manual invoicing:** Create via API, set `collection_method: "send_invoice"` with `days_until_due: 30` (Net 30). Stripe sends the invoice with a hosted payment link.

### Invoice PDF — legal requirements

At minimum: your business name/address/tax ID, customer name/address, invoice number (unique, sequential), date and due date, line items with quantities/prices/amounts, tax breakdown by jurisdiction, total and currency, payment terms.

**EU-specific:** VAT numbers of both parties (for B2B reverse charge), VAT rate per line item, "Reverse charge" notation when applicable.

### Credit notes

Adjust a previous invoice without voiding it. Use for:
- Partial refund (wrong line item)
- Goodwill credit (service outage)
- Pricing correction

The credit is applied to the customer's balance or refunded to their payment method.

### Overdue invoice handling (B2B / Net terms)

- Due date: send invoice
- +7 days: "Friendly reminder" email
- +14 days: "Your invoice is overdue" email
- +30 days: "Final notice" + escalate to account manager
- +60 days: consider marking as uncollectible

---

## Refunds, credits, and disputes

### Refund types

- **Full refund** — entire payment returned. Order canceled, product returned, service not delivered.
- **Partial refund** — portion returned. One item returned, prorated credit.
- **Account credit** — no money moves to payment method. Credit applied to customer's balance for future invoices. Use for service credit, goodwill.

### Refund timing

| Payment method | Time to appear |
|---|---|
| Card | 5-10 business days |
| ACH / bank transfer | 3-5 business days |
| SEPA | 5-8 business days |
| Store credit | Immediate |

Tell customers the timeline. The #1 post-refund support ticket is "where is my money?"

### Chargeback / dispute lifecycle

```
Transaction
  > Cardholder disputes with bank
  > Bank issues chargeback
  > Stripe notifies you (charge.dispute.created webhook)
  > You have 7-21 days to respond with evidence
  > Submit evidence via Stripe Dashboard or API
  > Card network reviews (60-75 days)
  > Decision: won (funds returned) or lost (funds stay with cardholder)
```

### Evidence to store proactively

For every transaction, store these before a dispute happens:
- Delivery proof (tracking, download logs, feature access logs)
- Usage logs (IP addresses, timestamps proving the real cardholder used the product)
- Customer communication (emails, chat transcripts, support tickets)
- AVS/CVV match results
- 3DS authentication result (if completed, liability shifts to issuer — strongest defense)
- Terms of service / refund policy acknowledged at checkout
- Customer IP address and device fingerprint

### Chargeback rate monitoring

**Critical threshold: 1% for Visa/Mastercard.** Exceeding this triggers a monitoring program with fines ($25K-$100K/month), higher fees, and eventual merchant account termination.

Track: `disputes this month / transactions this month`. Surface this in the admin dashboard.

### Fraud prevention layers

Stack these — don't rely on any single one:
1. **AVS** — billing address matches issuer records. Block mismatches.
2. **CVV** — always require for first-time payments. Block mismatches.
3. **3D Secure** — bank authentication, shifts fraud liability to issuer.
4. **Stripe Radar** — ML fraud scoring. Radar for Fraud Teams adds custom rules and blocklists.
5. **Velocity checks** — block same card used N times in M minutes, same email/IP with multiple payment methods.
6. **Device fingerprinting** — identify repeat fraudsters across accounts.

---

## Payment method management

### Adding a payment method

1. User clicks "Add payment method" in billing settings
2. Stripe Payment Element loads (card input or alternative methods)
3. User enters card, clicks Save
4. Frontend calls `stripe.confirmSetup()` with a SetupIntent
5. PaymentMethod attached to Customer
6. Display new card: brand icon, last 4, expiry

### Removing a payment method

Prevent removal of the last payment method if there's an active subscription. Show a warning: "You can't remove your only payment method while you have an active subscription."

### Default payment method

Show which is default with a visual indicator. Allow one-click switching. When updating default, also update the subscription's default to match.

### Card expiration handling

- **30 days before expiry:** send email "Your Visa ending in 4242 expires next month."
- **Automatic card updater:** Stripe silently updates tokens when Visa/Mastercard reissues cards.
- **On failure:** dunning sequence kicks in (see above).

### Regional payment methods

Use Stripe's Payment Element — it dynamically shows relevant methods by customer country:

| Region | Key methods |
|---|---|
| US/CA | Cards, ACH, Apple Pay, Google Pay |
| EU | Cards, SEPA, Apple Pay, Google Pay, Klarna, iDEAL, Bancontact |
| UK | Cards, Bacs, Apple Pay, Google Pay, Klarna |
| Brazil | Cards, PIX, Boleto |
| India | Cards, UPI, Netbanking |
| Japan | Cards, Konbini |

You don't build separate flows. The Payment Element handles it.

---

## Webhook processing

### Why webhooks are the source of truth

API responses tell you state at the moment you called. But payment processing is asynchronous: 3DS completes later, bank transfers settle later, disputes arrive days later, renewals happen on schedule. Webhooks are how your system learns about async state changes. If you rely only on API responses, your state will be inconsistent.

### Critical events to handle

| Event | Action |
|---|---|
| `payment_intent.succeeded` | Fulfill order, activate feature, send receipt |
| `payment_intent.payment_failed` | Notify customer, show error |
| `invoice.payment_succeeded` | Extend subscription access |
| `invoice.payment_failed` | Trigger dunning, show payment failure banner |
| `customer.subscription.created` | Provision features |
| `customer.subscription.updated` | Handle plan/status changes |
| `customer.subscription.deleted` | Revoke access, trigger offboarding |
| `charge.dispute.created` | Alert team, start evidence collection |
| `charge.refunded` | Update order status |

### Idempotency

Every webhook handler must be idempotent. Stripe may deliver the same event multiple times.

Pattern: check if the event ID has been processed (store in a `webhook_events` table), skip if yes. Process if no. Record after processing.

### Event ordering

Events can arrive out of order. Don't rely on arrival order. Use the event's `created` timestamp, or fetch the current object state from the Stripe API within your handler.

### Webhook signature verification

Always verify. Never skip. This prevents spoofed events.

Critical detail: verify against the raw request body (bytes), not parsed-then-reserialized JSON. Re-serialization changes the signature.

### Webhook endpoint architecture

```
Stripe POST to /webhooks/stripe
  > Verify signature (reject if invalid)
  > Check idempotency (skip if processed)
  > Write event to queue (DB table, Redis, SQS)
  > Respond 200 immediately (within 3 seconds)
  > Background worker picks up event
  > Worker processes (update DB, send emails)
  > Worker marks event as processed
```

Don't do heavy processing in the handler. Stripe expects 200 within 20 seconds. Respond first, process async.

Stripe retries failed deliveries for up to 72 hours with exponential backoff.

### Reconciliation

Run a periodic job (hourly or daily) comparing local state with Stripe:

Fetch recent subscriptions/payments from Stripe, compare status with your database. Log mismatches, auto-correct where safe. This catches missed webhooks from infrastructure gaps or deployment windows.

---

## Money handling

### Integer cents — non-negotiable

Never use floating-point for money. Use integers in the smallest currency unit.

```javascript
// WRONG
const price = 19.99;
const tax = price * 0.0825;  // 1.649175 — floating point horror

// RIGHT
const priceInCents = 1999;
const taxInCents = Math.round(priceInCents * 0.0825);  // 165
const totalInCents = priceInCents + taxInCents;  // 2164 = $21.64
```

### Currency-specific minor units

Not all currencies use 2 decimal places:

| Decimals | Currencies | Example |
|---|---|---|
| 0 | JPY, KRW, VND | 1000 JPY = amount: 1000 |
| 2 | USD, EUR, GBP, CAD | $19.99 = amount: 1999 |
| 3 | BHD, KWD, OMR | 1.500 BHD = amount: 1500 |

Stripe handles this automatically when you pass `amount` + `currency`. Your display logic must also know.

### Multi-currency rule

Always store amount + currency as a pair. Never store just an amount.

```sql
-- RIGHT
CREATE TABLE orders (
  total_amount INTEGER NOT NULL,     -- 1999
  currency     VARCHAR(3) NOT NULL   -- 'usd'
);
```

Never implicitly convert between currencies. Use explicit exchange rates, store them, show both values.

### Display formatting

Use `Intl.NumberFormat` — it knows minor units per ISO 4217:

```javascript
function formatMoney(cents, currency) {
  const divisor = ['jpy', 'krw', 'vnd'].includes(currency) ? 1 : 100;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: currency.toUpperCase(),
  }).format(cents / divisor);
}
```

Cache formatter instances when formatting many values in a table.

---

## Revenue metrics

### MRR (Monthly Recurring Revenue)

```
MRR = sum of all active subscriptions, normalized to monthly

$1200/year plan = $100/month MRR
$50/month plan = $50/month MRR
$150/quarter plan = $50/month MRR
```

Only count active, paying subscriptions. Not trialing, not canceled, not past_due.

### MRR movements

Track these separately — they tell different stories:

| Movement | What it measures |
|---|---|
| New MRR | Revenue from new subscriptions |
| Expansion MRR | Revenue increase from upgrades/add-ons |
| Contraction MRR | Revenue decrease from downgrades |
| Churn MRR | Revenue lost from cancellations |
| Reactivation MRR | Revenue from previously canceled customers returning |

```
Net New MRR = New + Expansion + Reactivation - Contraction - Churn
```

### Churn rates — they're different

| Metric | Formula | What it tells you |
|---|---|---|
| Customer churn | Customers lost / customers at start | How many logos you're losing |
| Gross revenue churn | (Churn MRR + Contraction) / MRR at start | How much revenue you're losing |
| Net revenue churn | (Churn + Contraction - Expansion) / MRR at start | Net revenue impact. Can be negative (good). |

A company can have 5% customer churn but negative net revenue churn if remaining customers expand enough.

### LTV (Lifetime Value)

```
LTV = ARPU / Monthly Customer Churn Rate
```

$50 ARPU, 5% monthly churn = $50 / 0.05 = $1,000 LTV.

For better accuracy, use cohort analysis: track each signup cohort's cumulative revenue over time.

### Revenue recognition (ASC 606)

Core principle: recognize revenue when you deliver the service, not when you receive payment.

- Annual $1,200 payment: $100/month revenue, $1,100 initially as deferred revenue.
- Usage-based: recognize as usage occurs.
- Setup fees: recognize immediately if standalone value, spread over lifetime if not.

**For dashboards:** don't build ASC 606 into billing UI unless you're building accounting software. Track cash received, export to accounting software (QuickBooks, Xero, NetSuite) that handles recognition. Label whether metrics show cash or accrual basis.

---

## Usage-based / metered billing

### Event ingestion pipeline

```
Your app emits usage events
  > Events sent to Stripe Meters API (or your aggregation layer)
  > Stripe aggregates per billing period per customer
  > At period end, Stripe generates invoice with usage line items
  > Invoice charged or sent to customer
```

### Idempotent event reporting

Always include a unique identifier per event to prevent double-counting. If the same identifier is sent twice, Stripe deduplicates.

### Billing period edge cases

Events are assigned to periods by timestamp. Use server-side timestamps, not client-side, for consistency. An event at 11:59 PM March 31 goes in March; 12:01 AM April 1 goes in April.

### Invoice preview

Show current usage and projected cost before the period closes: "Your current usage: 15,000 API calls. Estimated cost: $75.00." Use the upcoming invoice API.

### Prepaid vs postpaid

- **Prepaid credits:** Customer buys credits upfront. Usage deducts. Prompt to top up when low.
- **Postpaid:** Billed at end of period for actual usage. Higher risk, lower friction.
- **Hybrid:** Free tier (prepaid at $0), overage charged postpaid. Common in SaaS.

---

## Payment UX in the dashboard

### Billing settings page

The billing page has four sections in this order:

1. **Current plan** — plan name, price, next billing date. Buttons: Change Plan, Cancel Subscription.
2. **Payment method** — card brand icon, last 4, expiry, default indicator. Buttons: Update, Remove, Add New.
3. **Usage this period** (if metered) — progress bars showing usage vs limits. Projected cost.
4. **Billing history** — table of invoices with date, amount, status, PDF download link.

### Upgrade flow

When user clicks "Change Plan":
- Side-by-side plan cards with feature comparison
- Current plan highlighted
- Clear price difference: "You'll be charged $25 today (prorated)" for upgrades
- "Your plan will change at end of period" for downgrades
- One-click with confirmation

### Payment failure banner

When a subscription payment fails, show a **persistent, non-dismissible banner** at the top of every page:

```
Your payment failed. Update your payment method to avoid service interruption. [Update Payment Method]
```

- Appears on every page, not just billing
- Red/warning color, high contrast
- Shows urgency with countdown: "Your account will be downgraded in 3 days"
- Direct action button, not just a link

### Upgrade prompts

- **Feature-gated:** when user hits a limit, show inline: "You've used 5/5 projects. Upgrade to Pro for unlimited."
- **Usage approaching limit:** "You've used 80% of your storage."
- **Navigation nudge:** small "Upgrade" badge next to plan name in sidebar
- **Non-blocking:** banner or callout, not a modal. Let users dismiss, re-show next visit.

### Invoice history table

Columns: Date, Invoice Number, Amount, Status (Paid/Open/Overdue/Void), Actions (View/Download PDF).

- PDF download as a direct link
- Filter by date range
- Show payment method used
- "Pay Now" button for open/overdue invoices

---

## Don'ts

- **Don't touch raw card data.** Use tokenization. Always. No exceptions.
- **Don't use floating-point for money.** Integer cents or decimal with fixed precision.
- **Don't rely on API responses for payment state.** Webhooks are the source of truth.
- **Don't process webhooks synchronously.** Queue the event, respond 200, process async.
- **Don't skip webhook signature verification.** Spoofed webhooks are a real attack vector.
- **Don't retry mutations on webhook redelivery.** Idempotency keys prevent double-charges.
- **Don't hard-code tax rates.** They change, they vary by jurisdiction. Use a tax service.
- **Don't store currency amounts without the currency code.** Amount + currency is a pair.
- **Don't let users remove their last payment method** while a subscription is active.
- **Don't show "Submit" on payment buttons.** Show the amount: "Pay $49.00" or "Subscribe — $49/mo."
- **Don't silently fail on payment errors.** Show the specific error and what to do about it.
- **Don't build your own subscription billing engine.** Use Stripe Billing, Paddle, or a dedicated platform. The edge cases will eat you alive.
- **Don't ignore your chargeback rate.** Monitor it. 1% is the cliff.
- **Don't auto-dismiss payment failure banners.** They stay until the problem is resolved.
- **Don't assume all currencies have 2 decimal places.** JPY has 0, BHD has 3.
