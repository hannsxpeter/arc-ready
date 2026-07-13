# 3. CMS / Content / Blog

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Content team managing articles, pages, media, and publishing workflows.

**Core entities:** Content Item (Post/Page), Content Type/Schema, Media Asset, Taxonomy (Category/Tag), Revision/Version, Workflow Stage, Author

**Gotchas:**
- **Content is not a single "body" text field** — content types have structured fields (hero image, SEO metadata, excerpt, related posts, custom fields). Storing everything in one rich text blob blocks structured queries, API delivery, and multi-channel publishing.
- **Draft/publish lifecycle requires revision history** — every save creates a version. Published content and draft edits coexist simultaneously. Scheduled publishing requires a background job.
- **Slugs and URLs are a data integrity concern** — changing a slug must create redirects from the old URL. Duplicate slugs, slug collisions, and locale-specific slugs cause SEO damage if missed.
- **Media management is its own subsystem** — images need multiple generated sizes, alt text, focal point cropping, CDN delivery, and deduplication. Deleting a media asset referenced by 50 posts is a cascade problem.
- **Localization is not just translation** — different locales may have entirely different content. Fallback chains (show English if French is missing), RTL support, and locale-specific URLs are structural decisions.
- **Content workflows are org-specific** — "Draft > Review > Legal > Scheduled > Published" vs. "Draft > Published." The workflow should be configurable, not hardcoded.

**Compliance:** WCAG 2.1 AA for published content, GDPR (comment forms, cookies), copyright/licensing metadata for media, DMCA takedown process.

**UX users expect:** WYSIWYG with structured blocks (Notion-style), side-by-side preview, version diff view, drag-to-reorder blocks, inline media upload, SEO score indicator, editorial calendar view.

**Seed data shape:** 3 content types (Post, Page, Case Study). 20 posts across 4 categories and 10 tags — 12 published, 3 drafts, 2 scheduled (one for tomorrow, one for next week), 2 in review, 1 archived. 3 authors with different roles (editor, writer, admin). 30 media assets (images with alt text, 2 PDFs). 1 post with 5 revisions showing meaningful diffs. Realistic slugs, SEO metadata, and featured images.
