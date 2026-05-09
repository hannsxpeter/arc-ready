# Reporting

This file covers report generation, scheduling, and delivery — the structured documents a dashboard produces for sharing, printing, compliance, or archival. Reporting is different from dashboards and analytics: a dashboard is a live screen for the user looking at it; a report is a document for someone else — a manager, a client, an auditor, a regulator.

---

## Report types

### Choosing the right type

| Need | Type | Format |
|---|---|---|
| Raw data to analyze in Excel | **Tabular / data dump** | CSV, XLSX |
| Quick snapshot for leadership | **Summary / executive** | PDF (1-3 pages) |
| Regulator requires this format | **Compliance / regulatory** | PDF (fixed layout) |
| Ops team needs this every morning | **Operational** | Email with key metrics + attachment |
| Answer a one-off question | **Ad-hoc / custom** | Screen or export |
| How does this period compare to that one? | **Comparative** | PDF or screen with delta columns |
| Summary with click-through to detail | **Drill-down** | Screen with linked sub-reports |

### Tabular / data dump

Raw data in rows and columns. Minimal formatting — column headers, consistent types. Use when the consumer wants to do their own analysis, import into another system, or audit individual records.

### Summary / executive

KPIs at the top, 2-3 charts in the middle, optional narrative at the bottom. Answers "how are we doing?" in under 60 seconds. Keep to 1-3 pages. Branded PDF with headers/footers.

### Compliance / regulatory

Fixed format dictated by regulation — SOX controls, HIPAA access logs, financial statements. The structure is NOT negotiable: specific line items, specific ordering, specific labels. Implement as hard-coded templates that pull data into predetermined slots. Don't let users customize the layout. Validate output against the regulatory schema before delivery.

### Operational

Daily/weekly summaries for people running the operation. Tables with conditional highlighting (red/yellow/green), sparklines for trends, comparison to previous period. Often scheduled and delivered via email or Slack.

### Ad-hoc / custom

The user selects columns, filters, grouping, and generates a one-off report. This is the "report builder" feature. The UI must be approachable for non-technical users — a visual query builder, not a SQL editor (though an advanced mode with SQL is acceptable for power users).

### Comparative

Period-over-period (this month vs. last month, this quarter vs. same quarter last year), actual vs. budget. Always three columns per metric: Period A, Period B, and delta (absolute and percentage). Color the delta (green for favorable, red for unfavorable). Normalize for different period lengths.

### Drill-down

Summary where every row or metric links to a detail sub-report. The summary renders as a table where each value is a link carrying filter context (`/reports/transactions?region=APAC&period=2026-Q1`). The detail is a parameterized report that accepts those filters. Composition of reports, not a monolith.

---

## Report builder UI

### Parameter panel

A left sidebar or top collapsible section with:

- **Date range** — range picker with presets (Today, Last 7 days, Last 30 days, This month, Last month, This quarter, Custom). Always default to something reasonable. Include timezone handling.
- **Entity filters** — multi-select dropdowns (region, product, team, segment). Searchable combobox when list exceeds 20 items. Show count ("3 regions selected").
- **Grouping / pivot** — choose how to group rows. "Group by Region, then by Product" produces a nested table with subtotals at each level.
- **Sort** — column + direction. Multi-column sort for tabular reports.
- **Column picker** — checkboxes to include/exclude columns with drag handles for reordering. Default to a sensible set. Persist selection per user.

### Live preview vs generate-then-view

- **Live preview** — report updates as parameters change (with debounce). For small-medium datasets that query in under 2 seconds.
- **Generate-then-view** — configure parameters, click "Generate Report," wait with progress indicator. For large datasets, PDF rendering, or heavy queries. If >5 seconds, show estimated time.

### Report templates vs saved views

A **saved view** (covered in workflows) is a saved filter on live data — it shows current data every time. A **report template** is a saved configuration that produces a snapshot at generation time. The template defines: report type, fixed parameters, variable parameters (user fills in), and output format.

Example: "Monthly Sales by Region" — type fixed (summary), grouping fixed (by region), format fixed (PDF), date range variable (user picks the month).

### Grouping and subtotals

When the user selects a grouping dimension, the table restructures: group header row > detail rows > subtotal row with aggregates (SUM, COUNT, AVG per column). Multiple grouping levels nest. Each group is collapsible. Grand total row at the bottom.

---

## PDF generation

### Tools

| Tool | Language | JS support | Best for |
|---|---|---|---|
| **Puppeteer / Playwright** | Node.js | Full (headless Chrome) | Maximum fidelity, charts included automatically |
| **Gotenberg** | Docker service | Full (Chromium inside) | Scalable, no Chromium in your app, supports merging and PDF/A |
| **WeasyPrint** | Python | None (static HTML only) | Python stacks, excellent CSS Paged Media support |
| **PrinceXML** | Any (CLI) | None | Best typography, PDF/A, commercial license |

**Recommendation:** Puppeteer/Gotenberg for most dashboards (renders the full page including charts). WeasyPrint for Python stacks with server-rendered charts (SVG).

### Page layout

**Headers and footers with page numbers:**

For Puppeteer: use `headerTemplate` / `footerTemplate` options with special CSS classes (`pageNumber`, `totalPages`). Critical: inline all styles (external CSS doesn't load in header/footer context).

For WeasyPrint/PrinceXML: use CSS `@page` margin boxes:
```css
@page {
  margin: 2cm 1.5cm;
  @top-center { content: "Monthly Revenue Report"; font-size: 9pt; }
  @bottom-right { content: "Page " counter(page) " of " counter(pages); font-size: 8pt; }
}
```

**Page breaks:**
```css
.report-section { break-before: page; }
.chart-container { break-inside: avoid; }
tr { break-inside: avoid; }
thead { display: table-header-group; }  /* repeat headers on each page */
```

**Landscape vs portrait per section:** WeasyPrint/PrinceXML support named pages (`@page landscape { size: A4 landscape; }`). Puppeteer doesn't support mixed orientation — generate separate PDFs and merge (Gotenberg has a merge endpoint, or use `pdf-lib`).

### Branded templates

Embed logo as base64 data URI (avoids external resource loading). Set brand colors via CSS. Embed fonts with `@font-face` and base64 `src`. Use a template engine (Handlebars, Jinja2, EJS) to inject data into a branded HTML skeleton.

### Chart rendering in PDFs

Three approaches:
1. **Screenshot (simplest)** — Puppeteer renders the page with charts and calls `page.pdf()`. Works with any client-side chart library.
2. **SVG capture** — render chart client-side, extract SVG, embed in PDF HTML. Charts render as vectors (crisp at any scale).
3. **Server-side chart libraries** — ECharts Node.js server-side mode, `chartjs-node-canvas`, Python `matplotlib`/`plotly` with `kaleido`. For WeasyPrint where JS isn't available.

### PDF/A for archival

PDF/A requires: all fonts embedded, no external dependencies, no JavaScript, no encryption. Use for compliance/regulatory reports. Gotenberg supports PDF/A conversion. PrinceXML supports it natively. For Puppeteer PDFs, post-process with Gotenberg or Ghostscript.

### File size optimization

- Compress images to JPEG quality 72-85 before embedding.
- Use SVG for charts.
- Subset fonts.
- Target: 10-page report with 5 charts under 2MB.

### Accessibility

Tagged PDFs with logical structure for screen readers: heading hierarchy, table headers with scope, alt text on images/charts, correct reading order. PrinceXML produces well-tagged PDFs. Puppeteer's tagging is limited — for accessibility-critical reports, post-process or use PrinceXML.

---

## Excel generation

### Libraries

| Language | Library | Notes |
|---|---|---|
| Node.js | **ExcelJS** | Full-featured: formatting, charts, images, streaming for large files |
| Node.js | xlsx-populate | Simpler API, good performance |
| Python | **openpyxl** | Read/write, charts, formulas, conditional formatting |
| Python | **XlsxWriter** | Write-only, faster for large files, excellent charts |
| Java | Apache POI | The standard. Verbose but complete. |
| Go | excelize | Read/write, charts, pivot tables |

### Proper .xlsx formatting

Every generated spreadsheet should have:
- **Frozen header row** with auto-filter enabled
- **Column widths** set appropriately (not default)
- **Number formatting** per column (`$#,##0.00` for currency, `0.0%` for percentages, `yyyy-mm-dd` for dates)
- **Styled header row** (bold, background color, centered)
- **Right-aligned numbers**, left-aligned text

### Multiple sheets

Structure: "Summary" sheet at position 0 (KPIs, totals), followed by detail sheets. Cross-sheet references in formulas work normally.

### Formulas

Write formulas as strings — Excel evaluates them when opened:
```
SUM(E2:E11)    // total row
E2/D2          // calculated margin
```

Libraries write formulas but don't evaluate them. Values compute when the user opens the file.

### CSV vs XLSX

| Use CSV when | Use XLSX when |
|---|---|
| Data exchange, ETL, import to another system | Human-readable report, analysis |
| Recipient may not have Excel | Formatting, formulas, multiple sheets matter |
| File size matters (large exports) | Presentation matters |

**CSV gotchas:**
- **BOM for UTF-8:** Excel requires a BOM (`\uFEFF`) at the start for correct character display.
- **Commas in values:** use a CSV library (csv-stringify, Python `csv` module) — don't manually concatenate.
- **Dates:** no standard format. Use ISO 8601 or document the format.

---

## Scheduled reports

### Scheduling UI

- **Frequency:** Daily, Weekly (pick day), Monthly (pick day 1-28 or "last day"), Quarterly.
- **Time:** time picker with user's timezone shown explicitly. Store as UTC internally.
- **Next run preview:** show the next 3-5 scheduled dates so the user can verify.
- **Recipient list:** internal users from directory + external emails (admin approval required for external to prevent spam relay).

### Delivery channels

| Channel | When |
|---|---|
| **Email with attachment** | Default. PDF or XLSX attached. Subject includes report name + date. Respect 25MB limit — fall back to link for large reports. |
| **Email with link** | For large reports. Link goes to stored report (requires auth). |
| **Slack** | Post to channel with key metrics + file upload. |
| **Webhook** | POST report URL or data as JSON to configured endpoint. |
| **S3 / cloud storage** | Write to configured bucket. Common for compliance archival. |

### Execution architecture

1. Cron scheduler fires at scheduled time.
2. Enqueues a job with report config (template ID, parameters, recipients, format).
3. Worker generates the report (queries data, renders PDF/XLSX), stores output.
4. Worker triggers delivery (email, Slack, etc.).
5. Job records status, output reference, and timestamps in `report_runs` table.

Make the job idempotent: use `schedule_id + scheduled_time` as deduplication key.

### Failure handling

- **Retry** 2-3 times with exponential backoff.
- **Admin notification** if all retries fail.
- **User notification:** "Your scheduled report failed" email with human-readable error and link to re-run.
- **Auto-pause** after 3 consecutive failures. Notify admin. Don't keep burning resources.

### Report history

Every generated instance stored:

```
report_runs:
  id, schedule_id, status (pending/running/completed/failed),
  started_at, completed_at, file_url, file_size,
  parameters (jsonb), error (text), delivered_to (jsonb)
```

Users can download past reports from the history table. Set retention policy (90 days default).

---

## Large dataset reports

### Streaming generation

Never load all rows into memory. Use database cursors to fetch in batches (1,000-10,000 rows). Pipe each batch through the formatter and directly to the output stream.

### Background job threshold

Any report that might exceed 30 seconds is a background job, not a synchronous request. Gateway timeouts (nginx: 60s, Cloudflare: 100s, Vercel: 10s hobby / 300s pro) will kill long-running requests.

**Rule:** if the query `EXPLAIN` estimates >5 seconds or the result set exceeds 50K rows, auto-route to the background job path.

### Data consistency

For reports that need consistency (financial, compliance, anything with totals that must add up): run the query inside a `REPEATABLE READ` transaction. This freezes the data as of transaction start. Note the snapshot time on the report.

### Pre-computed aggregations

For reports scanning millions of rows:
- **Materialized views** (Postgres): pre-aggregate daily/weekly/monthly. Refresh on schedule (`REFRESH MATERIALIZED VIEW CONCURRENTLY`).
- **Summary tables:** application-managed, populated by background jobs. More control than materialized views.

The 1000x speedup: scanning 25,000 pre-aggregated rows instead of 1.3 billion raw rows is 50ms vs. 50 seconds.

---

## Print optimization

### CSS @media print

```css
@media print {
  /* Hide interactive elements */
  nav, .sidebar, .toolbar, .filters-panel, .pagination,
  button, .tooltip, .modal, .toast { display: none !important; }

  /* Reset to full width */
  .main-content { margin: 0; padding: 0; width: 100%; max-width: none; }

  /* Preserve colors */
  * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }

  /* Remove shadows */
  * { box-shadow: none !important; }
}
```

### Page breaks

```css
@media print {
  .report-section { break-before: page; }
  .chart-container { break-inside: avoid; }
  tr { break-inside: avoid; }
  h2, h3 { break-after: avoid; }
  thead { display: table-header-group; }
}
```

### Print button

```typescript
function handlePrint() {
  // Option 1: simple
  window.print();

  // Option 2: open print-optimized view
  const w = window.open('/reports/print-view?id=123', '_blank');
  w.addEventListener('load', () => { w.print(); w.close(); });
}
```

The print-optimized view is a separate route without nav, sidebar, or interactive elements.

---

## Report permissions and security

### Role-based access

```
reports:generate           — can run reports
reports:generate:financial — financial reports (sensitive data)
reports:generate:hr        — HR reports (salary, PII)
reports:schedule           — can create scheduled reports
reports:admin              — can manage all scheduled reports
```

Check at generation time, not just at the UI level.

### Data redaction per role

Apply masking in the service layer, not the template. The template should never see unmasked data.

- Salary: show range ("$80K-$90K") instead of exact number for non-HR roles.
- SSN: show last 4 (`***-**-1234`).
- Email: show for managers, redact for viewers.

### Row-level security

A regional manager generating a sales report sees only their region. Enforce at the query level — inject the user's scope into every report query. For defense in depth, use Postgres RLS policies.

### Watermarking

Add a semi-transparent text overlay on every PDF page: user's email + generation timestamp. Discourages unauthorized sharing.

```css
.watermark {
  position: fixed;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%) rotate(-45deg);
  font-size: 48pt;
  color: rgba(0, 0, 0, 0.06);
  pointer-events: none;
}
```

### Expiring download links

Use presigned URLs with expiration. Default: 24 hours for routine, 1 hour for sensitive. After expiration, user can re-generate or request a new link from report history.

### Audit trail

Every report generation is logged: who, which report type, parameters, output format, row count, file size, timestamp, download count.

---

## Don'ts

- **Don't generate reports synchronously** if they might exceed 30 seconds. Background job with progress.
- **Don't load all rows into memory** for large reports. Stream with cursors.
- **Don't let users customize compliance report layouts.** Regulatory formats are fixed.
- **Don't serve reports from permanent public URLs.** Use presigned URLs with expiration.
- **Don't skip the BOM** for UTF-8 CSV files opened in Excel.
- **Don't embed full-resolution images** in PDFs. Compress to JPEG 72-85.
- **Don't show raw SQL errors** in report failure messages. Show "The report could not be generated" with a reference ID.
- **Don't let the template see unmasked data** the user's role doesn't permit. Mask in the service layer.
- **Don't forget to normalize period lengths** in comparative reports. February vs. March is not apples-to-apples.
- **Don't auto-retry scheduled reports indefinitely.** Pause after 3 consecutive failures.
- **Don't generate reports without audit logging.** "Who downloaded salary data?" is a question you must be able to answer.
