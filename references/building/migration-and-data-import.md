# Migration & Data Import

Moving data into a dashboard — and moving users from one system to another — is where onboarding succeeds or dies. A CSV upload that silently drops 200 rows kills trust. A platform migration that forces a Big Bang cutover with no rollback kills accounts. This file is the rules for building import flows, migration UIs, and cutover strategies that actually work.

---

## Data import flows

### The four-stage import pipeline

Every file import follows the same four stages. Skip one and the import feels broken.

1. **Upload** — accept the file, show progress, validate the format
2. **Map** — match source columns to your schema
3. **Validate** — check every row against your rules, surface errors
4. **Confirm** — preview results, let the user commit or abort

Build them as four distinct screens (or panels). Don't collapse them into a single "upload and pray" button.

### File upload

**Accept CSV, XLSX, and JSON.** CSV is universal but messy (encoding issues, delimiter inconsistencies, malformed quotes). XLSX is what non-technical users have. JSON is what developers send. Support all three.

```typescript
const ACCEPTED_FORMATS = {
  'text/csv': ['.csv'],
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
  'application/json': ['.json'],
};

const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
const MAX_ROWS = 500_000;
```

**Drag-and-drop + click-to-browse.** Show both options in the same drop zone. The drop zone should be large (at least 200x150px), have a dashed border, and change state on hover/drag-over.

```
┌─────────────────────────────────────┐
│                                     │
│   Drag a file here, or browse       │
│                                     │
│   CSV, XLSX, or JSON — up to 100MB  │
│                                     │
└─────────────────────────────────────┘
```

**Chunked upload for large files.** Files over 10MB should use chunked uploads (5MB chunks). This prevents browser timeouts, enables resume on failure, and lets you show real progress instead of a spinner.

```typescript
async function uploadChunked(file: File, onProgress: (pct: number) => void) {
  const CHUNK_SIZE = 5 * 1024 * 1024;
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);
  const uploadId = await initiateUpload(file.name, file.size);

  for (let i = 0; i < totalChunks; i++) {
    const chunk = file.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE);
    await uploadChunk(uploadId, i, chunk);
    onProgress(((i + 1) / totalChunks) * 100);
  }

  return await finalizeUpload(uploadId);
}
```

**Cache upload progress in localStorage** so users can resume if the browser tab closes.

**Show a determinate progress bar** during upload. Never show an indeterminate spinner for file uploads — users need to know if they're waiting 5 seconds or 5 minutes.

### Field mapping

Field mapping is where most imports fail. The user's columns never match your schema exactly. "First Name" vs "first_name" vs "fname" vs "Given Name" — same data, four names.

**Auto-detect column mappings** using string similarity and header analysis. Modern importers (Flatfile, Dromo, OneSchema) use AI trained on billions of mapping decisions. Show confidence scores: auto-accept matches above 90% confidence, present matches between 60-90% as suggestions the user confirms, flag anything below 60% as "needs manual mapping."

```
Source Column         →  Target Field          Confidence
─────────────────────────────────────────────────────────
"Customer Name"       →  full_name             ✓ 95%
"Email Address"       →  email                 ✓ 98%
"Phone #"             →  phone                 ● 82% (confirm)
"Acct Balance"        →  ?                     ✗ Manual map needed
```

**Show a preview row** under each mapping so users can verify the data flows correctly. Display the first 3-5 actual values from the file alongside the target field.

**Let users skip columns.** Not every column in a source file belongs in your system. Provide a "Don't import" option for each source column.

**Remember mapping profiles.** If a user imports from the same source regularly (e.g., weekly Salesforce export), save their mapping as a named profile they can reuse.

### Validation

Run validation in two passes:

1. **Format validation** (client-side, immediate) — data types, required fields, string lengths, regex patterns. Runs in the browser for instant feedback.
2. **Business rule validation** (server-side) — uniqueness constraints, foreign key references, custom rules. Runs on the server where you have access to existing data.

**Show errors inline in a spreadsheet-like grid.** Highlight cells with errors in red, show the error message on hover or in a sidebar. Users should be able to fix errors in-place without re-uploading.

```
Row  | Name          | Email              | Phone        | Status
─────┼───────────────┼────────────────────┼──────────────┼────────
1    | Alice Chen    | alice@co.com       | 555-0101     | ✓
2    | Bob Smith     | not-an-email       | 555-0102     | ✗ Invalid email
3    | Carol Díaz    | carol@co.com       |              | ⚠ Phone missing (optional)
4    |               | dave@co.com        | 555-0104     | ✗ Name required
```

### Error handling strategy

Pick one of three strategies based on your data type:

| Strategy | When to use | Behavior |
|---|---|---|
| **Abort (reject all)** | Financial data, regulatory submissions, compliance | Reject entire file if any row fails. User must fix and re-upload. |
| **Skip invalid rows** | Operational data, contact lists, general imports | Import valid rows, return invalid rows in a downloadable error report. |
| **Threshold-based** | Mixed criticality data | Accept if < 5% of rows fail; reject if failure rate is higher. |

**Always produce a downloadable error report** with: row number, field name, the invalid value, the rule that failed, and a human-readable explanation.

```csv
row,field,value,rule,message
2,email,"not-an-email",format,"Must be a valid email address"
4,name,"","required","Name is required"
17,phone,"+1-555-CALL",format,"Phone must contain only digits, spaces, hyphens, and parentheses"
```

**Don't silently drop rows.** This is the cardinal sin of import UX. If 200 out of 5,000 rows were skipped, the summary screen must say "4,800 imported, 200 skipped — download error report."

### Import confirmation and preview

Before committing, show a summary:

```
┌─────────────────────────────────────────────┐
│  Import Preview                             │
│                                             │
│  Total rows:        5,000                   │
│  Ready to import:   4,800  ✓                │
│  Errors (skipped):    200  ✗  Download CSV  │
│  Warnings:             34  ⚠                │
│                                             │
│  New records:       4,200                   │
│  Updates to existing:  600                  │
│                                             │
│  [ Cancel ]              [ Import 4,800 ]   │
└─────────────────────────────────────────────┘
```

**Dry run mode.** For imports that modify existing data (updates, merges), offer a "Preview changes" mode that shows what will change without committing. Display a diff: "Current value → New value" for every field that would change.

### Import progress

For imports that take more than 2 seconds, show:

- **Determinate progress bar** with percentage
- **Row counter** — "Processing row 3,420 of 5,000"
- **Estimated time remaining** — update every 2-3 seconds, don't flicker
- **Error count** — running tally so users can see if the import is going sideways
- **Allow background processing** — let users navigate away. Show a persistent notification (toast or drawer, like Google Drive's upload indicator) so progress is visible without blocking the UI.

```typescript
// WebSocket-based progress updates
interface ImportProgress {
  importId: string;
  status: 'processing' | 'completed' | 'failed';
  totalRows: number;
  processedRows: number;
  errorCount: number;
  estimatedSecondsRemaining: number;
}
```

Push progress updates via WebSocket or SSE (Server-Sent Events), not polling. Polling at 1-second intervals creates unnecessary load; SSE gives you real-time updates on a single HTTP connection.

### Rollback

**Every import must be reversible for at least 72 hours.** When a user imports 5,000 contacts and discovers the mapping was wrong, "just re-import with the correct mapping" is not a rollback — it's data corruption layered on data corruption.

Implementation:

1. **Tag imported records** with an `import_id` and `imported_at` timestamp.
2. **Soft-delete on rollback** — mark all records from that import as deleted, don't hard-delete.
3. **Show rollback in the import history** — a list of past imports with status, row counts, and an "Undo import" button.
4. **Warn before rollback** — "This will remove 4,800 records imported on April 10. Records modified after import will not be affected."

```typescript
async function rollbackImport(importId: string) {
  const records = await db.record.findMany({
    where: { importId, deletedAt: null },
  });

  await db.record.updateMany({
    where: { importId },
    data: { deletedAt: new Date(), deletedReason: 'import_rollback' },
  });

  await db.importJob.update({
    where: { id: importId },
    data: { status: 'rolled_back', rolledBackAt: new Date() },
  });

  return { rolledBackCount: records.length };
}
```

---

## API-based migration

### Connecting to source systems

When importing from another SaaS product (migrating from Competitor X), the flow is:

1. **OAuth connection** — user authorizes access to the source system. Show which permissions you're requesting and why.
2. **Discovery** — scan the source system for available data (contacts, deals, projects, etc.). Show a checklist of what can be imported.
3. **Configuration** — let the user choose what to import, how to handle duplicates, and how to map custom fields.
4. **Sync** — run the migration with real-time progress.
5. **Verification** — show a comparison summary of source vs imported data.

**Don't require API keys.** OAuth is the standard. If the source system doesn't support OAuth, provide a step-by-step guide with screenshots for finding the API key, and validate it immediately on entry.

### Conflict resolution

When imported data conflicts with existing data, present three options:

| Strategy | Behavior | Best for |
|---|---|---|
| **Source wins** | Overwrite existing data with imported data | Fresh migrations, replacing stale data |
| **Existing wins** | Keep existing data, skip conflicts | Incremental syncs, protecting manual edits |
| **Manual review** | Queue conflicts for user review | High-value data, regulatory requirements |

Show the conflict count upfront: "247 records match existing data. How should we handle them?" Don't bury this in settings.

### Incremental sync

For ongoing integrations (not one-time imports), use cursor-based sync:

```typescript
interface SyncState {
  sourceSystem: string;
  lastSyncedAt: Date;
  cursor: string | null; // opaque cursor from source API
  totalSynced: number;
  status: 'idle' | 'syncing' | 'error';
}
```

Show sync status in the UI: last synced time, next scheduled sync, and a "Sync now" button. Surface errors prominently — a sync that's been failing silently for 3 days is worse than no sync at all.

---

## Platform migration flows

### Phased rollout

Rolling out a new version of your dashboard to all users at once is reckless. Use percentage-based rollout controlled by feature flags.

**The standard progression:**

| Day | Audience | Purpose |
|---|---|---|
| Day 1 | Internal team only | Catch obvious bugs |
| Day 3 | 1% of users (canary) | Validate under real traffic |
| Day 5 | 5% of users | Monitor error rates and performance |
| Day 7 | 10% of users | Validate at scale |
| Day 10 | 25% of users | Watch for edge cases |
| Day 14 | 50% of users | Confidence check |
| Day 21 | 100% of users | Full rollout |

**Gate each expansion on metrics.** Don't advance to 10% if error rates at 5% are above your baseline. Key metrics to watch:

- Error rate (should stay within 1.1x of baseline)
- p95 latency (should not increase by more than 20%)
- Core business KPIs (conversion rate, engagement, etc.)
- Support ticket volume

**Use feature flags, not deployments.** A feature flag lets you instantly roll back to 0% without deploying code. Tools: LaunchDarkly, Unleash, Flagsmith, ConfigCat, or your own flag service.

```typescript
// Feature flag check
const showNewDashboard = featureFlags.isEnabled('new-dashboard-v2', {
  userId: user.id,
  orgId: user.orgId,
  percentage: 10, // 10% rollout
});

if (showNewDashboard) {
  return <NewDashboard />;
} else {
  return <LegacyDashboard />;
}
```

### Parallel running

Run old and new systems side by side. This is non-negotiable for high-stakes migrations (financial data, healthcare, anything with SLAs).

**Dual-write pattern:** Write data to both systems during the transition. The old system remains the source of truth until the new system is validated.

```
User action → API → Write to new system (primary)
                  → Write to old system (shadow)
                  → Compare results
                  → Log discrepancies
```

**Keep the old system in read-only mode for 24-72 hours after cutover.** This gives you an immediate fallback target. If critical issues emerge, flip the router back.

**Comparison dashboard.** Build an internal tool that compares data between old and new systems. Row counts, checksums, aggregate values. Run this continuously during the parallel period.

### "Try the new version" opt-in

Let users switch between old and new at will. This is the Salesforce Classic → Lightning model, and it works.

**UI pattern:**

```
┌─────────────────────────────────────────────────────┐
│  ⓘ  A new version of [Product] is available.        │
│     Try the new experience →   |  Dismiss           │
└─────────────────────────────────────────────────────┘
```

Rules for the opt-in banner:
- Show it at the top of the page, below the nav. Not a modal — modals interrupt work.
- Include a "Dismiss" option. Don't show it again for 7 days after dismissal.
- After the user tries the new version, show a "Switch back to classic" link in the footer or settings. Make it effortless to return.
- Track opt-in/opt-out rates. If users try the new version and immediately switch back, you have a UX problem to fix before forcing migration.
- Label the new version clearly — a "Beta" or "New" badge next to the product name removes ambiguity.

### Cutover strategies

**Gradual cutover (recommended).** Move users in cohorts over 2-4 weeks. Start with power users who are most likely to find issues, then move casual users.

**Big Bang cutover.** Everyone moves at once. Only appropriate when:
- The old system genuinely cannot coexist with the new one (schema incompatibility)
- The migration window is short (e.g., a weekend maintenance window)
- You have a tested rollback plan that takes < 1 hour to execute

**Rollback plan for every cutover:**
1. Define the rollback trigger (error rate > 5%, data loss detected, P0 bug)
2. Document the rollback steps (who does what, in what order)
3. Test the rollback in staging before the production cutover
4. Keep the old environment warm for 72 hours minimum after cutover

---

## Account migration patterns

### Merging duplicate accounts

Duplicate accounts happen when the same person signs up with different emails, or when an organization uses both personal and work accounts.

**Merge flow:**

1. **Identify** — user selects the accounts to merge, or the system detects potential duplicates (same name + similar email, overlapping data).
2. **Choose the primary** — one account survives. Show a side-by-side comparison of both accounts: name, email, org, creation date, last activity, data counts.
3. **Resolve conflicts** — for each field that differs, let the user pick which value to keep. Default to the most recently updated value.
4. **Transfer data** — move all records (contacts, projects, files) from the secondary account to the primary. Update all foreign key references.
5. **Confirm and execute** — show a summary of what will change. Make it irreversible only after explicit confirmation ("Type 'MERGE' to confirm").

**Salesforce's model:** Select up to 3 accounts, choose the master record, and all contacts, opportunities, cases, and activities merge into it. The secondary records are deleted but all associated data transfers.

### Ownership transfer

Transferring ownership of an org, project, or dataset between users or organizations.

**Required safeguards:**
- Verify the current owner's identity (re-authentication or 2FA confirmation)
- Notify both parties (current owner and new owner) via email
- Require the new owner to accept the transfer (don't silently dump ownership)
- Set a 48-hour grace period during which the original owner can cancel
- Transfer all associated resources (sub-projects, team members, billing) or let the owner choose what transfers

### SSO migration

Adding SSO to existing password-based accounts is one of the trickiest migrations because you're changing the authentication method for active users.

**The safe sequence:**

1. **Configure SSO in parallel** — keep password auth working while SSO is set up. Don't disable passwords until SSO is validated.
2. **Pilot with admins first** — the IT admin configures SSO and tests it with their own account before rolling out.
3. **Link accounts automatically** — match existing accounts by email domain. When a user signs in via SSO, link it to their existing account if the email matches.
4. **Grace period** — allow both password and SSO login for 30-90 days. This handles edge cases (contractors not in the IdP, shared accounts, service accounts).
5. **Enforce SSO** — after the grace period, require SSO for all users on the domain. Show a clear message: "Your organization now requires SSO. Sign in with [IdP name]."

```
┌───────────────────────────────────────────────┐
│  Your organization has enabled SSO             │
│                                                │
│  Starting [date], sign in with your company    │
│  credentials through [Okta/Azure AD/etc.]      │
│                                                │
│  [ Sign in with SSO ]                          │
│                                                │
│  Still using a password? You have until         │
│  [date] to transition. Learn more →            │
└───────────────────────────────────────────────┘
```

**Don't break service accounts.** SSO enforcement should have an escape hatch for API tokens and service accounts that can't go through an IdP flow.

---

## Schema migration (what the user sees)

### Zero-downtime migrations

Users should never see a maintenance page for a schema migration. Use the expand-migrate-contract pattern:

1. **Expand** — add new columns/tables alongside existing ones. No breaking changes. The old code still works.
2. **Migrate** — backfill data into the new schema. Run in background, show progress if user-facing.
3. **Contract** — remove old columns/tables after all code uses the new schema.

**From the user's perspective:** nothing changes during expand and contract. During migrate, if the user needs to review or approve changes to their data, show a task:

```
┌─────────────────────────────────────────────────┐
│  ⓘ  We're upgrading how [Feature] stores data.  │
│     Some of your records need review.            │
│                                                  │
│     12 records need your input →                 │
│                                                  │
│  This won't affect your existing workflows.      │
└─────────────────────────────────────────────────┘
```

### Feature flags during migration

Use feature flags to show or hide features as the migration progresses:

```typescript
// Phase 1: New feature behind flag, old feature still default
if (flags.isEnabled('new-reporting-engine', user)) {
  showNewReports();
} else {
  showLegacyReports();
}

// Phase 2: New feature is default, old feature behind "classic" flag
if (flags.isEnabled('legacy-reporting-engine', user)) {
  showLegacyReports();
} else {
  showNewReports();
}

// Phase 3: Old feature removed, flag cleaned up
showNewReports();
```

**Invert the flag at the halfway point.** Start with the new feature as opt-in (Phase 1). Once validated, make the new feature the default and the old feature opt-out (Phase 2). This catches users who never opted in but whose workflows might break.

### Data transformation review

When a schema change requires transforming user data (e.g., splitting a "Name" field into "First Name" + "Last Name"), show the user a review UI:

```
We're splitting the Name field into First Name and Last Name.
Please review these automatic splits:

Name (current)       →  First Name    Last Name
─────────────────────────────────────────────────
"Alice Chen"         →  "Alice"       "Chen"        ✓
"Bob van der Berg"   →  "Bob"         "van der Berg" ✓
"Madonna"            →  "Madonna"     ""             ⚠ Review
"Kim Jong-un"        →  "Kim"         "Jong-un"      ⚠ Review
```

Flag ambiguous cases for manual review. Don't silently guess on names, addresses, or any data where a wrong split corrupts the record.

### Backward compatibility indicators

When rolling out breaking API changes or schema modifications, show compatibility status in the developer dashboard:

```
API Version    Status           Sunset Date
────────────────────────────────────────────
v3 (current)   ✓  Active        —
v2             ⚠  Deprecated    June 15, 2026
v1             ✗  Sunset        Removed
```

---

## User communication during migration

### The communication timeline

For any migration that affects user workflows, follow this sequence:

| Timing | Channel | Content |
|---|---|---|
| **6-12 months before** | Email + blog post | Announcement: what's changing, why, high-level timeline |
| **3 months before** | Email + in-app banner | Reminder: specific dates, migration guide link, opt-in access |
| **30 days before** | Email + persistent banner | Deadline approaching: action required, support contact |
| **7 days before** | Email + modal (once) | Final warning: specific cutover date and time |
| **Day of** | Status page + in-app notice | Migration in progress, expected duration, status updates |
| **Day after** | Email | Confirmation: migration complete, what's new, how to get help |
| **1 week after** | Email | Follow-up: tips for the new system, feedback survey |

**For security-critical deprecations** (auth protocol changes, encryption upgrades), the fast-track timeline is 30-90 days.

### In-app banners

Use three banner tiers:

```
INFO (blue):
┌─────────────────────────────────────────────────────────┐
│ ⓘ  We're launching a new dashboard experience on June 1.│
│    Learn what's changing →                     Dismiss  │
└─────────────────────────────────────────────────────────┘

WARNING (yellow):
┌─────────────────────────────────────────────────────────┐
│ ⚠  The classic dashboard will be retired on June 1.     │
│    Migrate your settings before then. Start →  Dismiss  │
└─────────────────────────────────────────────────────────┘

CRITICAL (red, no dismiss):
┌─────────────────────────────────────────────────────────┐
│ ✗  The classic dashboard will shut down in 3 days.      │
│    Action required: export your data now. Export →       │
└─────────────────────────────────────────────────────────┘
```

**Rules:**
- Info banners are dismissible. Don't show again for 7 days.
- Warning banners are dismissible but reappear after 3 days.
- Critical banners (< 7 days before deadline) are not dismissible.
- Place banners below the nav bar, above page content. Never cover content.
- Include a clear CTA: "Learn more," "Start migration," "Export data."

### Sunset email sequence

Five emails for a product/feature sunset:

1. **Announcement** (6+ months out) — what's happening, why, high-level timeline. Warm, appreciative tone. Thank users for their time with the product. Link to a detailed blog post or migration guide.
2. **Migration guide** (3 months out) — step-by-step instructions. Screenshots. Video walkthrough if the migration is complex. Link to support.
3. **Deadline reminder** (30 days out) — specific date. What happens if they don't migrate. Data export instructions.
4. **Final warning** (7 days out) — urgent but not aggressive. Offer 1:1 migration help for high-value accounts.
5. **Completion/post-migration** (day after) — confirm the migration is done. Link to "getting started with the new system." Feedback survey.

**Tone guidance:** Be direct but not cold. Acknowledge disruption. Never blame the user for not migrating sooner.

### Status page during migration

During active migration windows, publish a dedicated status page (or update your existing one) with:

- Current migration phase and progress
- Expected completion time (update every 15-30 minutes)
- Known issues and workarounds
- Rollback status ("We can restore the previous version within 30 minutes if needed")
- Real-time incident updates if something goes wrong

Link to the status page from the in-app banner and from your support channels.

### Support escalation

During migration windows, expect 3-5x normal support volume. Prepare:

- **Dedicated migration FAQ** — cover the top 20 questions before they're asked
- **Escalation path** — frontline support → migration specialist → engineering on-call
- **Canned responses** for common migration issues, personalized with the user's specific data
- **Extended support hours** during the cutover window

---

## Migration testing and validation

### Dry run / preview

**Every migration should support a dry run.** A dry run executes the full migration pipeline — reads source data, transforms it, validates it — but writes nothing. It produces a report:

```
Dry Run Report — April 10, 2026, 2:34 PM
─────────────────────────────────────────
Source records scanned:    12,450
Records to create:          8,200
Records to update:          3,100
Records to skip (no change): 1,150
Errors:                        47

Estimated duration:         ~8 minutes
Estimated storage impact:   +240 MB

[ View error details ]  [ View sample changes ]  [ Run migration ]
```

**For user-facing imports:** Show the dry run results in the confirmation step (Stage 4 of the import pipeline). Let users download a preview of the transformed data before committing.

### Data integrity verification

After migration, run automated checks:

1. **Row count comparison** — source count vs target count for every entity type. A mismatch is a P0.
2. **Checksum validation** — hash key columns and compare between source and target.
3. **Aggregate comparisons** — sum of financial fields, count of records per status, count of records per category. These catch subtle data corruption that row counts miss.
4. **Random sample spot-check** — pull 50-100 random records and compare field-by-field between source and target.
5. **Referential integrity** — verify all foreign keys resolve. Orphaned records are a common migration bug.

```typescript
interface MigrationValidation {
  entityType: string;
  sourceCount: number;
  targetCount: number;
  checksumMatch: boolean;
  aggregateChecks: {
    field: string;
    sourceValue: number;
    targetValue: number;
    match: boolean;
  }[];
  sampleChecksPassed: number;
  sampleChecksTotal: number;
}
```

**Surface validation results to the user** when they're the ones running the import. A simple summary:

```
✓  All 4,800 records imported successfully
✓  Data integrity verified (checksums match)
✓  No orphaned references detected
```

Or, if there are issues:

```
⚠  4,780 of 4,800 records imported
✗  20 records failed integrity check — Download report
✓  No orphaned references detected
```

### Comparison views

For platform migrations (old system → new system), build a comparison view that lets stakeholders verify data side by side:

```
┌─────────────────────┬─────────────────────┐
│  Legacy System      │  New System         │
├─────────────────────┼─────────────────────┤
│  Contacts: 12,450   │  Contacts: 12,450 ✓│
│  Deals: 3,200       │  Deals: 3,198    ✗ │
│  Revenue: $1.2M     │  Revenue: $1.2M  ✓ │
│  Tasks: 8,900       │  Tasks: 8,900    ✓ │
└─────────────────────┴─────────────────────┘

2 deals missing — View details
```

**Click into discrepancies.** The comparison view should let users drill into mismatches to see exactly which records are missing or different.

### User acceptance testing

For enterprise migrations, build a UAT checklist into the product:

1. Present the user with a list of verification tasks: "Verify your contacts imported correctly," "Check that your reports still produce the same numbers," "Confirm your integrations are working."
2. Let users mark each task as passed or failed.
3. Block final cutover until the key stakeholders have signed off (or until the deadline, whichever comes first).

```
Migration Verification Checklist
────────────────────────────────
☑  Contact data matches legacy system
☑  Deal pipeline totals are correct
☐  Custom reports produce expected results
☐  Email integration is sending/receiving
☐  API integrations are functional

2 of 5 verified — Complete verification to finalize migration
```

---

## Implementation checklist

For every import or migration feature, verify:

- [ ] File upload supports drag-and-drop, click-to-browse, and paste
- [ ] Large files use chunked upload with resume capability
- [ ] Field mapping auto-detects with confidence scores
- [ ] Mapping profiles can be saved and reused
- [ ] Validation runs client-side (format) and server-side (business rules)
- [ ] Errors are shown inline with row/field context
- [ ] Error report is downloadable as CSV
- [ ] Import summary shows counts before committing
- [ ] Dry run mode is available for destructive operations
- [ ] Progress bar is determinate with ETA and error count
- [ ] Background processing lets users navigate away
- [ ] Every import is reversible for 72+ hours
- [ ] Rollback is a single button click, not a support ticket
- [ ] Phased rollout uses feature flags with percentage-based targeting
- [ ] Rollout gates on error rate, latency, and business KPIs
- [ ] Communication follows the 6-month → 3-month → 30-day → 7-day sequence
- [ ] In-app banners escalate from info → warning → critical
- [ ] Post-migration validation runs automatically (row counts, checksums, samples)
- [ ] Comparison view surfaces discrepancies with drill-down
