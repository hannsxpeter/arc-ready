# 37. Research / Lab / LIMS

**Taxonomy role:** Industry overlay.

**Archetype:** Researchers, technicians, and lab managers tracking samples, experiments, protocols, instruments, results, and chain of custody.

**Core entities:** Study, Sample, Aliquot, Batch, Protocol, Method Version, Experiment Run, Instrument, Calibration, Reagent Lot, Result, Notebook Entry, Chain-of-Custody Event

**Domain landmines:** Sample identity is lost during splits and pools; protocol edits rewrite historical interpretation; units and detection limits are omitted; instrument calibration is disconnected from results; files lack checksums and provenance; negative and inconclusive results disappear; reagent lot changes are not traceable; timezone and clock drift reorder custody events; spreadsheet imports silently coerce identifiers and scientific notation.

**Compliance and freshness caveat:** Research-only labs, clinical labs, and regulated manufacturing labs have different obligations. Verify applicability of GLP, GCP, CLIA, CAP, 21 CFR Part 11, data-integrity guidance, biosafety, and privacy requirements with qualified owners. Add Healthcare only for clinical or PHI-bearing work.

**Expected operator experience:** Barcode-first sample handling, custody timeline, protocol and method version selection, plate and batch views, instrument queue, calibration status, structured results with raw-file links, deviation handling, and reproducible export for analysis.

**Test and fixture shape:** Parent samples with aliquots and pools, blinded identifiers, multiple units, detection-limit results, method revisions, calibration expiry, instrument reruns, reagent-lot changes, import coercion traps, checksummed raw files, and custody transfers. Tests prove provenance from result to sample, method, instrument, calibration, operator, and raw artifact.

**Stack mapping:** Start with `Internal Tools / Back-office` in `references/planning/domain-stacks.md`. Add `Analytics / BI / Dashboards` for large result sets and Healthcare only when clinical workflows or PHI are evidenced.
