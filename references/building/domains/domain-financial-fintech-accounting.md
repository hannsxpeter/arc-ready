# 4. Financial / Fintech / Accounting

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Finance team managing ledgers, transactions, invoices, and reconciliation.

**Core entities:** Account (asset/liability/equity/revenue/expense), Transaction/Journal Entry, Ledger, Invoice, Reconciliation, Chart of Accounts, Fiscal Period

**Gotchas:**
- **Double-entry bookkeeping is non-negotiable** — every transaction must have equal debits and credits. A single-entry "transactions" table requires a full rewrite when an accountant reviews it.
- **Money must never use floating point** — use integer cents or a decimal type with fixed precision. $0.01 rounding error across 100,000 transactions is $1,000 that fails an audit.
- **Financial records are append-only** — never edit or delete a transaction. Create a correcting/reversing entry. The original record must remain with a linked reversal.
- **Fiscal periods close and lock** — once a month/quarter/year is "closed," no transactions post to it without a formal reopening process. Not optional.
- **Multi-currency requires exchange rates at transaction time** — store both the original currency amount AND the converted amount at the rate used. Rates change daily; retroactive revaluation is a separate process.
- **Reconciliation is a first-class workflow** — matching bank statement lines to ledger entries is core, not an afterthought. Unreconciled items must be surfaced prominently.
- **Rounding rules vary by jurisdiction** — some countries round to nearest 0.05, some use banker's rounding, tax rounding has locale-specific rules.

**Compliance:** SOX (public companies), GAAP/IFRS accounting standards, PCI DSS for payment data, AML/KYC for fintech, data retention 7+ years.

**UX users expect:** T-account visualization, trial balance report, aged receivables/payables, bank reconciliation matching interface, chart of accounts tree, journal entry form with auto-balancing, fiscal period lock indicators.

**Seed data shape:** Chart of accounts with 20-30 accounts across all 5 types (asset/liability/equity/revenue/expense). 200 journal entries spanning 6 months — all balanced (debits = credits). 1 closed fiscal period (last quarter), 1 open. 15 invoices (10 paid, 3 outstanding, 2 overdue). 50 bank statement lines with 40 reconciled and 10 unreconciled. All amounts in integer cents. 1 multi-currency transaction with stored exchange rate. 1 reversing entry linked to its original.
