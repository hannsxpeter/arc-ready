# 19. Media / Streaming

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Content team managing a media catalog, licensing rights, distribution, and subscriber analytics.

**Core entities:** Title/Asset, Episode/Season/Series, License/Rights Window, Catalog Entry, Subscription Tier, Viewing Session, Content Rating, Distribution Channel

**Gotchas:**
- **Content rights are territorial and temporal** — a movie may be licensed for US streaming Jan-Dec 2026, UK from March, unavailable in Germany. Every availability check evaluates: territory + date range + platform + rights type (SVOD/TVOD/AVOD). Expired rights must auto-remove content.
- **Metadata standards are industry-specific** — EIDR for title IDs, per-territory content ratings (PG-13 US, 12A UK, FSK 12 Germany), available subtitles/dubs, audio formats (Stereo, 5.1, Atmos), HDR formats, aspect ratios.
- **Content ingestion is a pipeline, not an upload** — source master > quality check > transcode to multiple formats/bitrates > generate thumbnails > extract captions > DRM packaging > CDN. Each step can fail. A single title may produce 20+ output files.
- **Parental controls and ratings require player-level enforcement** — age-gated profiles, PIN for mature content, kids profiles must never serve tracked ads (COPPA).
- **Playback analytics drive the business** — start rate, completion rate, drop-off points, buffering events, concurrent stream limits, device fingerprinting for DRM. High-volume event data.
- **Content windowing is business-critical** — theatrical > premium VOD > standard VOD > pay TV > free. The dashboard must manage release windows and prevent premature availability.

**Compliance:** COPPA (kids content), regional rating board requirements, accessibility (audio description, closed captions mandated), GDPR for viewing history, royalty reporting to rights holders.

**UX users expect:** Catalog browser with territory/rights filters, rights availability calendar heatmap, ingestion pipeline status, viewing analytics with engagement curves, subscriber cohorts, content performance rankings, editorial curation tools.

**Seed data shape:** 200 titles (120 movies, 60 series with 3-10 episodes each, 20 documentaries). Rights windows for 3 territories (US, UK, Germany) — 150 titles available in US, 90 in UK, 60 in Germany, with 5 expiring within 30 days. Per-territory content ratings. 10 titles in ingestion pipeline (3 transcoding, 2 QA, 5 complete). 3 subscription tiers. 50,000 viewing session records with completion rates. 5 curated editorial rows.
