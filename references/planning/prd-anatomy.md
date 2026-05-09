# PRD anatomy: the full annotated template (Step 9 and across)

This reference is the annotated PRD template. It covers the section order, length conventions, what each section does and does not contain, the format of the downstream handoff block, and the PR-FAQ / Working Backwards optional mode.

## 1. The section order

Every PRD, regardless of tier, uses the same section order. Tiers differ in which sections are filled.

```
1. Title and tier badge
2. Changelog (top-visible for Living / Soft-frozen PRDs)
3. Open Questions log (top-visible)
4. Mode and context
5. Problem
6. Target user
7. Success criteria
8. Appetite
9. Functional requirements
10. Non-functional requirements
11. Scope and out-of-scope
12. Rabbit holes
13. Risks
14. Assumptions
15. Downstream handoff block
16. Prior art (Tier 3+)
17. Sign-off ledger (Tier 2+)
18. Visual identity direction (Tier 3+)
19. Launch plan (Tier 4)
20. Post-launch retrospective (archived state)
```

Order matters because the PRD is read top-to-bottom by engineers, designers, and stakeholders who have limited time. The top of the doc is the most-read; it gets the most load-bearing content (changelog, OQs, problem, user, success).

## 2. Title and tier badge

One line:

```markdown
# [Project name] PRD

**Tier:** Brief | Spec | Full PRD | Launch-Ready PRD
**State:** Draft | Living | Soft-frozen | Archived
**Version:** 1.0 | 1.1 | 2.0 (semver-like: major for pivots, minor for scope adjustments)
**Last updated:** YYYY-MM-DD
**Owner:** [PM name]
```

The tier badge tells any reader what to expect; the state badge tells them whether they can edit.

## 3. Changelog section (top-visible)

In the Living and Soft-frozen states, every edit writes here.

```markdown
## Changelog

- **2026-04-23** @priya-k (PM): added Slack integration to Out-of-Scope Part 1 with survey evidence; downgraded multi-tenant admin from Should to Won't (this release).
- **2026-04-21** @raj-p (eng lead): added NFR for p99 latency under 800ms based on SLA negotiation with Acme Corp customer.
- **2026-04-19** @priya-k: tightened target-user definition to exclude >50-person agencies (removed from scope); updated success metric baseline after dogfood week.
- **2026-04-17** (initial draft from prd-ready skill v1.0.0)
```

Changelog-at-top matters for the broadcast discipline: readers see what changed since their last visit without hunting.

## 4. Open Questions log (top-visible)

Every unresolved OQ with owner and due date. See [risks-and-assumptions.md](risks-and-assumptions.md) section 4.

```markdown
## Open questions

| ID | Question | Owner | Due | Blocks |
|---|---|---|---|---|
| OQ-01 | Asana token expiration mid-generation handling | Raj P. | 2026-05-12 | Tier 3 |
| OQ-02 | Pricing model for the Enterprise tier | Exec sponsor | 2026-05-20 | Ship |
| OQ-03 | Browser support for IE / legacy Edge | Design lead | 2026-05-02 | Tier 2 |
```

## 5. Mode and context

A few sentences on why this PRD exists and what it is not.

```markdown
## Mode and context

**Mode:** A (Greenfield product).
**Context:** Initial v1 PRD for a new product that replaces the current manual Friday-status-doc workflow at design agencies. No prior PRD exists.
**Related artifacts:** Jan 2026 user-interview notes in /research/. Dogfood observations in /internal/ops-notes.md.
```

## 6. Problem

The three-paragraph structure from [problem-framing.md](problem-framing.md) section 3.

```markdown
## Problem

**Friction.** Design-agency PMs preparing client status updates on Friday afternoons spend 40-90 minutes reformatting content across five tools (Figma, Asana, Harvest, the prior week's status doc, the client template) before they begin actually writing the substantive summary. Our user research (n=12, Jan-Mar 2026) showed that 60% of the total prep time is reformatting, not analysis.

**Who.** Design-agency PMs at 10-50-person agencies managing 3-5 concurrent client projects. Cannot replace Asana (client visibility); cannot replace Harvest (billing integration). Constrained by IT-approved-tools-only policies at ~40% of target agencies.

**Workaround.** Today, users open five tabs, copy-paste between them, reformat, and then write. The prior-week status doc is the template; each status doc gets "Save As"-renamed. No current product specifically targets this workflow.
```

No sentence starts with "Our product" or "The system"; the problem-first discipline is enforced.

## 7. Target user

Five bullets from [user-personas.md](user-personas.md) section 2.

```markdown
## Target user

### Primary: Design-agency PM

- **Role:** PM at 10-50-person design agency managing 3-5 concurrent client projects. US and EU; APAC not sampled.
- **Context:** Every Friday afternoon (2-6pm local), preparing the weekly client status update.
- **Constraint:** Cannot replace Asana (client visibility). IT-approved-tools-only policy at ~40% of target agencies. Budget: $30-100/seat/month acceptable.
- **Workaround:** Five-tab manual workflow (Figma + Asana + Harvest + prior-week doc + client template).
- **Research:** Interviews with Jenna M. (2026-01-14), Priya K. (2026-02-03), Tom S. (2026-02-17), plus 9 follow-ups (2026-03). Sample skewed US West Coast.

### Secondary: Account manager (consumes the output)

- [5 bullets]
```

## 8. Success criteria

From [success-criteria.md](success-criteria.md) section 1-3.

```markdown
## Success criteria

### Leading (steers)

- **Activation rate, day 7.** >50% of new user accounts generate at least one status doc within 7 days of signup. Measured via `status.generated` in Amplitude.
- **Onboarding completion, first session.** >70% of new users complete the 4-step onboarding (connect Figma + Asana + Harvest + first generation) within their first session. Measured via `onboarding.completed`.

### Lagging (ratifies)

- **Weekly active users, 90 days.** >400 weekly active PMs at day 90 post-launch. Active = at least one `status.generated` event in the trailing 7 days.
- **Median time-to-generate, 90 days.** <10 minutes end-to-end (from opening the tool to clicking "Send"). Baseline: 40-90 minutes. Measured via `session.duration` for sessions with `status.generated`.

### Counter-metric (watches for gaming)

- **Factual-error rate.** <2% of generated status docs contain a user-flagged factual error (wrong number, wrong project, wrong teammate). Measured via an in-product "flag this as wrong" button.
```

## 9. Appetite

One paragraph.

```markdown
## Appetite

Big batch: 8 engineer-weeks. This is the time we are willing to spend before we stop and evaluate. If the scope cannot fit, we cut scope, not time.
```

## 10. Functional requirements

From [requirements.md](requirements.md) section 1-5.

```markdown
## Functional requirements

### R-01 (Must): Connect Figma / Asana / Harvest

Users can connect their Figma, Asana, and Harvest accounts via OAuth on the onboarding screen.

**Acceptance criteria:**
- Given a user on the Connect step, when they click "Connect Figma," a Figma OAuth flow opens in a new tab and, on success, the Figma connection shows as "Connected" within 5 seconds.
- [...same for Asana, Harvest...]
- Given a user's OAuth fails (user cancels, permission denied, network error), the UI renders a specific error state with a retry affordance within 3 seconds.

**Dependencies:** Figma, Asana, Harvest API keys provisioned (BLOCKING).

### R-02 (Must): Generate a status doc from connected sources

[full structure]

### R-03 (Should): Manual section override

[full structure]

### R-04 (Could): Save templates for future sessions

[full structure]

### Won't (this release):
- R-W1: AI-powered executive summaries in the status doc (cut; save for v2 after measuring baseline adoption).
- R-W2: Integration with Slack (cut; 78% of target users on Teams).
- R-W3: Mobile app (cut; desktop-only at v1).
```

## 11. Non-functional requirements

From [requirements.md](requirements.md) section 7.

```markdown
## Non-functional requirements

| Dimension | Threshold |
|---|---|
| Performance | p95 end-to-end doc generation under 15 seconds on a typical 50 Mbps connection |
| Scale | 10,000 concurrent users, 50,000 generations/day at v1; 4x projected 12 months |
| Availability | 99.9% uptime monthly; 43 min max downtime |
| Security | TLS 1.3; OAuth for third-party connections; tokens encrypted at rest with AWS KMS |
| Privacy | GDPR subject-access within 30 days; no third-party analytics on authenticated pages |
| Compliance | SOC 2 Type II controls via Vanta; no HIPAA/PCI at v1 (non-applicable) |
| Accessibility | WCAG 2.2 AA; automated axe-core + manual screen-reader pass |
| i18n | English-only at v1; strings externalized (react-i18next); no hardcoded strings |
| Observability | Every user error logs trace ID; Honeycomb dashboards; SLOs for availability + latency |
| Data retention | Active users: indefinite. Inactive 24+ months: purge after 30-day notice. |
| Browser support | Chrome, Safari, Firefox, Edge latest-2. No IE. Mobile-web read-only. |
| Operational | Zero-downtime deploys; expand-contract migrations; rollback-window last 3 deploys |
```

## 12. Scope and out-of-scope

From [scope-and-out-of-scope.md](scope-and-out-of-scope.md) sections 2-3.

```markdown
## Scope and out-of-scope

### Part 1: Explicit no-gos

- **Slack integration.** Cut for v1. Jan 2026 survey (n=40, 22% response) showed 78% of target users on MS Teams. Reconsider at v1.5 if Teams integration ships and user feedback requests Slack parity.
- **Mobile app.** Cut for v1. Dogfood mobile usage negligible. Mobile-web read-only. Reconsider at v2 based on mobile-use data.
- [...4-6 more no-gos with full reasoning...]

### Part 2: Deferrals

- **Multi-tenant admin panel.** Deferred to v2. Single-tenant admin sufficient at v1 (one customer at a time, high-touch). Reconsidered when self-serve signup opens (projected Q3 2026).

### Part 3: Non-ownership

- **Email deliverability.** Owned by platform team. This PRD assumes Postmark is configured with SPF/DKIM/DMARC passing.
- **SSO.** Owned by identity team. This PRD uses the existing SSO surface unchanged.
```

## 13. Rabbit holes

```markdown
## Rabbit holes

### Real-time collaborative editing

Tempting to build full CRDT-based sync (Yjs, Automerge). Rabbit hole: CRDT is a 6-month sidequest; 90% of a new product.

**Smallest version that avoids:** optimistic locking with last-writer-wins plus a "last updated by X at HH:MM, refresh to see latest" banner. Real-time collaboration deferred to v2+.

### OAuth refresh-token rotation edge cases

Tempting to build full automatic refresh + proactive re-auth prompts. Rabbit hole: correct behavior across 3 providers (Figma, Asana, Harvest) has 12+ edge cases, each with its own provider quirks.

**Smallest version that avoids:** refresh on 401 only; user sees a "Reconnect your [tool] account" banner if any fails. Full automatic refresh deferred; measured post-launch.
```

## 14. Risks, assumptions

See [risks-and-assumptions.md](risks-and-assumptions.md).

## 15. Downstream handoff block

The contract with the four downstream skills. This lives at `.prd-ready/HANDOFF.md` as a separate artifact; the PRD references it:

```markdown
## Downstream handoff

Full handoff block lives at `.prd-ready/HANDOFF.md`. Summary:

- **To stack-ready:** 6 pre-flight answers pre-filled. Domain: SaaS productivity tool. Team: 4 engineers + 1 PM + 1 designer. Budget posture: cash-efficient growth. Time-to-ship: 8 weeks. Scale: 50k generations/day at 12 months. Compliance: SOC 2 Type II; no HIPAA/PCI.
- **To architecture-ready:** entities (Users, Connections, StatusDocs, Sources), flows (connect -> fetch -> generate -> review -> send), NFRs, trust boundaries, integration points.
- **To roadmap-ready:** MoSCoW priority, dependencies, rabbit holes, 8-week appetite.
- **To production-ready:** entities and CRUD, roles (PM, Account Manager), audit requirements, acceptance criteria, visual-identity direction ("modern clinical, slightly playful").
```

See section 17 below for the full template.

## 16. Prior art (Tier 3+)

Borrowed from stack-ready. Three comparable products or internal projects, honestly cited:

```markdown
## Prior art

- **Geckoboard** (2012-present). Dashboards pulling data from multiple SaaS sources. Status: still operating, profitable, ~50 people. Relevant: shows the integration-hub approach is viable long-term. Differs: their output is dashboards (numerical); ours is prose (status docs).
- **Toggle Plan / Plan-app.** Status-doc generation for consulting agencies. Status: product sunset in 2024 after founder pivoted. Relevant: target user overlap; their failure mode was pricing ($15/user felt too low, $30/user blocked adoption). Differs: narrower scope; no tool integrations.
- **Monograph** (2020-present). PM tool for architecture agencies with time tracking and client reporting. Status: Series A 2024, scaling. Relevant: adjacent market; suggests the agency-vertical workflow-tool thesis is live. Differs: they own the full PM workflow, not a single artifact.
```

## 17. The downstream handoff block (full template)

This is the load-bearing compositional artifact. It lives at `.prd-ready/HANDOFF.md`:

```markdown
# PRD handoff

**From:** prd-ready v1.0.0, 2026-04-23
**PRD:** `.prd-ready/PRD.md` (Tier 2 Spec, signed 2026-04-22)
**Project:** [project name]

## To stack-ready (live, v1.1.5)

### Pre-flight answers

- **Domain:** [one of stack-ready's 12 profiles, or closest with overrides]. Our case: SaaS productivity tool (multi-tenant, B2B, moderate-scale).
- **Team:** 4 engineers (2 backend TypeScript, 1 frontend TypeScript/React, 1 full-stack Python), 1 PM, 1 designer. On-call rotation: backend + full-stack share (2-week rotation).
- **Budget posture:** cash-efficient growth. No enterprise-indifferent tools; free-tier and startup-tier services preferred.
- **Time-to-ship:** 8 weeks to v1 launch (appetite).
- **Scale ceiling (12 months):** 10k concurrent users, 50k generations/day at launch; projected 40k concurrent and 200k generations/day at 12 months.
- **Regulatory constraints:** SOC 2 Type II (enterprise customers require); GDPR (EU users expected); no HIPAA (not healthcare); no PCI direct (Stripe-hosted only).

### Ready to skip stack-ready's Step 1. stack-ready can proceed to Step 2 (constraint mapping).

## To architecture-ready (not yet released)

### Entities

- **User** (id, email, team_id, role, oauth_tokens[])
- **Team** (id, name, plan_tier, created_at, created_by_user_id)
- **Connection** (id, user_id, provider: figma|asana|harvest, oauth_token, refresh_token, expires_at, scopes[])
- **Project** (id, team_id, name, source_ids[])
- **StatusDoc** (id, project_id, generated_at, generated_by_user_id, sources[], content, sent_at, sent_to)
- **AuditEvent** (id, user_id, action, payload, created_at)

### Flows

- **Onboarding:** signup -> team creation -> connect Figma -> connect Asana -> connect Harvest -> first generation.
- **Weekly generation:** open app -> select project -> click Generate -> review draft -> edit -> send.
- **Reconnection (error path):** OAuth token expired -> prompt re-auth -> resume generation.
- **Empty state (error path):** no activity last 7 days -> prompt manual summary.

### Non-functional requirements

[See PRD.md Non-Functional Requirements section, or copy inline]

### Integration points

- Figma API (OAuth 2.0, read comments + file activity).
- Asana API (OAuth 2.0, read tasks + project activity).
- Harvest API (OAuth 2.0, read time entries).
- Postmark (email delivery; out-of-scope for this PRD, assume configured).
- Stripe (billing; deferred to v1.1).
- OpenAI API (LLM summarization; latency-sensitive, budget-sensitive).

### Trust boundaries

- Users only see their own team's projects.
- OAuth tokens are team-scoped, not user-scoped (shared access).
- Audit log is team-admin-read-only.

### Explicitly deferred to architecture

- Queue / job processing mechanism (for async generation; PRD requires async, architecture-ready picks the queue).
- Caching strategy for LLM responses.
- Multi-region data residency (deferred to v1.5).

## To roadmap-ready (not yet released)

### Priority ordering

- R-01 (Must) Connect Figma / Asana / Harvest
- R-02 (Must) Generate status doc from connected sources
- R-03 (Should) Manual section override
- R-04 (Could) Save templates for future sessions
- Won't: R-W1, R-W2, R-W3

### Release-gating criteria

- R-01 gates launch (cannot ship without integrations).
- R-02 gates launch (core feature).
- R-03 does not gate launch; ships within 2 weeks post-launch if not in v1.
- R-04 does not gate launch.

### Dependencies

- R-01 blocks R-02 (cannot generate without connections).
- R-03 depends on R-02 (override presupposes a draft exists).

### Must-haves vs. nice-to-haves (the cut line)

Cut line: below R-02. Everything above the line must ship; everything below ships if appetite permits.

### Rabbit holes

(See PRD.md Rabbit Holes section.)

### Dates or ranges

Target launch: 2026-06-15 (8 weeks from 2026-04-20 start).

## To production-ready (live, v2.5.6)

### Entities and CRUD surface

- **User**: create (signup), read (self + team members), update (profile), delete (admin).
- **Team**: create (signup), read, update (admin), delete (admin).
- **Connection**: create (OAuth), read (self), update (re-auth), delete (disconnect).
- **Project**: create, read (team), update (team), delete (admin).
- **StatusDoc**: create (generate), read (team), update (edit), delete (admin).

### Roles and permissions

- **User (default):** read team; create/update own StatusDocs; create/read/update/delete own Connections; read own Projects.
- **Team admin:** user permissions + delete any team resource + manage team settings + read audit log.

### Audit trail requirements

- Every StatusDoc generation and send event logged with user_id, project_id, sources_used, timestamp.
- Every Connection create/update/delete logged.
- Every team setting change logged.
- Retention: 2 years for all audit events (aligns with SOC 2 practice).
- Visibility: team admins read own team's audit log; platform admins read all.

### Acceptance criteria per feature

(See PRD.md Functional Requirements section; production-ready's Tier 1 proof tests map 1:1 to acceptance criteria.)

### Error and edge states

(See PRD.md Functional Requirements section, Acceptance Criteria subsections.)

### Visual identity direction

"Modern clinical, slightly playful." Think: Notion's precision with a hint of Figma's warmth. Not fintech-serious; not SaaS-gray. Muted neutrals (stone + warm gray) with a single accent (coral or amber). Typography: system font stack, large scale, lots of whitespace. No gradients; no glassmorphism. No shadcn default aesthetic.

### Domain landmines

- Third-party API rate limits. Harvest is the tightest (180 req/min per account). Architecture should batch.
- OAuth scope creep. Users accustomed to minimal scopes; requesting too much triggers drop-off. Only request read scopes at v1.
- Client data privacy. Status docs may contain client-confidential information; ensure no third-party analytics on authenticated pages; logs are PII-scrubbed.
```

## 18. The PR-FAQ / Working Backwards mode (optional)

Amazon's Working Backwards approach (Colin Bryar, *Working Backwards*, 2021) writes the hypothetical press release and FAQ *before* building. For prd-ready Mode A (greenfield product) or novel features, the PR-FAQ pass runs as a complement to the full PRD:

### PR (press release, always under 1 page)

One page, dated as of hypothetical launch day. Written in the style of a real press release.

- **Headline.** The product's value in one line.
- **Sub-headline.** The customer and their problem.
- **Opening paragraph.** Summary of the launch, city, date.
- **Problem paragraph.** The customer's problem today.
- **Solution paragraph.** How the product solves it.
- **Quote from leader.** Why we built it.
- **Customer experience paragraph.** How it works in the user's life.
- **Customer quote.** What they say (can be hypothetical if pre-launch).
- **Closing.** How to get started.

If the PR doesn't describe something meaningfully better than what exists, it isn't worth building. This is the forcing function.

### FAQ (external + internal)

Five pages or less.

**External FAQ** (what customers ask):
- What does it do?
- How is it different from X?
- How much does it cost?
- When can I get it?
- What does it not do?

**Internal FAQ** (what the team asks):
- Why did we build this?
- Why now?
- What's the biggest risk?
- What did we cut and why?
- What's the next version?

The PR-FAQ runs parallel to the PRD; both feed into Tier 2 sign-off. Many teams find the PR-FAQ's customer-outcome framing surfaces assumptions the PRD's requirements-framing misses.

## 19. Length conventions

| Tier | Target length | Format |
|---|---|---|
| Tier 1 (Brief) | 1 page | Single-column markdown; 600-1000 words |
| Tier 2 (Spec) | 2-3 pages | Markdown with tables; 1500-3000 words |
| Tier 3 (Full PRD) | 3-8 pages | Markdown with tables, sub-sections; 3000-7000 words |
| Tier 4 (Launch-Ready) | Tier 3 + launch plan | Adds 500-1500 words for launch sections |

PRDs longer than 10 pages usually have the "good-for-many, great-for-no-one" template bloat problem (research pass section 1.9). Cut.

## 20. Format conventions

- **Markdown.** Not a Google Doc, not a Notion block-tree, not a Confluence page. Markdown in a git repo, consumed by both humans and the downstream skills' handoff readers.
- **Tables for structured data.** Requirements, NFRs, Open Questions, changelogs.
- **No nested bullets beyond 2 levels.** Deeper nesting signals unclear structure; split into sub-sections instead.
- **Links.** Internal cross-links to other sections, external links to research and citations.
- **Date stamps.** Every decision, every change, every assumption gets a date.
- **Attribution.** Every claim sourced; every edit signed.

## 21. The document-as-artifact principle

The PRD is not a meeting artifact. It is not a slide deck. It is a self-contained document that a reader, with no other context, can use to understand what is being built, for whom, and why.

The test: hand the PRD to an engineer or designer who was not in any of the planning meetings. Can they, after 20 minutes, understand what to build? If no, the document has not done its job, regardless of what was said in meetings.

## 22. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 3: canonical PRD literature.
- Amazon PR-FAQ: Colin Bryar and Bill Carr, *Working Backwards* (2021).
- Atlassian PRD template: https://www.atlassian.com/software/confluence/templates/product-requirements
- HashiCorp PRD (markdown, problem-first): https://www.hashicorp.com/en/how-hashicorp-works/articles/prd-template
- Lenny Rachitsky's PRD templates (Confluence; paywalled newsletter).
