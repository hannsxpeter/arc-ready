# Scope and out-of-scope (Step 7)

The Out-of-Scope section is the most load-bearing section of the PRD and the most commonly botched. This reference covers why it is hard, how to write it well, how it pairs with appetite and rabbit holes, the change-control protocol that depends on it, and the common shapes of "bad out-of-scope."

## 1. Why the Out-of-Scope section is hard

Three reasons:

1. **Loss aversion.** Naming something as out-of-scope feels like giving up. PMs avoid the admission.
2. **Optionality bias.** "We might want that later, so let's not close the door." The result is a 3-line Out-of-Scope that commits to nothing.
3. **Adversarial stakeholder management.** Every stakeholder has their pet feature; listing it as out-of-scope invites pushback. PMs paper over.

The consequences of a weak Out-of-Scope:

- **Scope creep during build.** Every week, some stakeholder asks "while we're doing this, can we also..." and the PRD can't push back.
- **Vapor promises.** The landing page or sales deck starts referencing features the PRD doesn't actually cover.
- **Missed-expectation launches.** Users arrive expecting features that were implied-but-not-stated.
- **Engineering burnout.** Scope keeps expanding; ship date doesn't. Shape Up's entire model is designed around this failure.

Shape Up's "no-gos," Kevin Yien's Square template, Intercom, Reforge, and Atlassian all elevate Out-of-Scope to first-class. AI-generated PRDs consistently minimize it. This is one of the widest gaps between AI output and good human practice.

## 2. The three-part Out-of-Scope section

Every Tier 2+ PRD's Out-of-Scope section has three parts:

### Part 1: Explicit no-gos

Things the team has considered and decided NOT to build.

Each entry names:
- What was considered.
- Why it was cut (reason: data, constraint, appetite, strategic).
- When (or if) it will be reconsidered.

**Example:**

> **Slack integration.** Cut for v1. In a Jan 2026 survey of 40 target users (n=40, 22% response), 78% reported using Microsoft Teams as their primary async tool, not Slack. Building Slack adds 2-3 eng weeks for <25% of users. Reconsidered at v1.5 if we ship Teams and user feedback requests Slack parity.

> **Mobile app.** Cut for v1. Mobile usage of the core workflow (assembling status docs from 5 desktop tools) is low; 3 of 12 dogfood users reported trying the workflow on mobile-web once and not since. Mobile app is a 6-8 week effort; defer to the v2 cycle.

> **Public API.** Cut for v1. Enterprise-tier ask, but the enterprise tier is not open yet; adding public API before a dedicated API product manager is in place creates support burden we can't absorb.

### Part 2: Deferrals

Things that are in the product plan but not this release. Cross-linked to the Won't (this release) MoSCoW tier.

Each entry names:
- What is deferred.
- The earliest release it is considered for.
- The deferral condition (what must be true to reconsider).

**Example:**

> **Multi-tenant admin panel.** Deferred to v2. Single-tenant admin is sufficient at v1 because we are onboarding one customer at a time (high-touch). Considered for v2 when we open self-serve signup (projected Q3 2026).

> **Custom branding (white-label).** Deferred to v2. Enterprise tier ask. Gated on: at least 3 paying enterprise customers at v1.

### Part 3: Explicit non-ownership

Things this PRD's team is not responsible for, to prevent downstream confusion.

Each entry names:
- The thing.
- Who owns it.
- What this PRD assumes about it.

**Example:**

> **Email deliverability.** Owned by platform team. This PRD assumes Postmark is already configured for the domain with SPF/DKIM/DMARC passing; deliverability issues route to platform-team@company.com.

> **Single sign-on (SSO).** Owned by identity team. This PRD uses the existing SSO surface; any SSO changes are out of scope and require identity-team review.

> **Billing and payments.** Owned by commerce team. This PRD's "paid tier" entitlement flags are consumed via the existing subscriptions service; changes to billing plans or payment flows are out of scope.

## 3. The length rule

The Out-of-Scope section is expected to be **longer than the Won't (this release) MoSCoW tier** because it catches things nobody thought to rank.

A three-bullet Out-of-Scope on a Tier 2+ PRD is a red flag. It probably means:

- The team hasn't actually thought through what's in vs. out.
- The Won't tier of MoSCoW is doing all the work (and a Won't-only list misses non-ranked concerns entirely).
- The PM is avoiding the hard conversation with stakeholders.

Tier-2+ PRDs should have at least 5-8 Out-of-Scope entries. Tier-3 PRDs usually 10-15.

## 4. Rabbit holes

From Shape Up (Ryan Singer, *Shape Up*, 2019). A rabbit hole is a risk that could blow up scope if not addressed during problem shaping.

Every rabbit hole names:

- **What could go wrong.** The specific failure mode. "Real-time sync becomes a full CRDT implementation."
- **Why it is tempting to over-build.** The pull. "Users might prefer the correct version; we might feel guilty about data loss."
- **The smallest version that avoids the rabbit hole.** The explicit alternative. "Optimistic locking with last-writer-wins and a 'refresh to see latest' banner."

**Examples:**

> **Real-time collaborative editing.** Tempting to build full CRDT-based sync (Yjs, Automerge). Rabbit hole: CRDT is a 6-month sidequest; it is 90% of a new product. v1 alternative: optimistic locking with last-writer-wins plus a "last updated by X, refresh to see latest" banner. Full real-time collaboration deferred to v2+ where CRDT investment is justified.

> **Offline-first.** Tempting to build full offline with sync queue. Rabbit hole: offline correctness is a distributed-systems problem; spec alone is 2 weeks. v1 alternative: online-only with a clear "you're offline" banner and a blocked submit button. Offline decision deferred to post-launch based on actual mobile-use data.

> **Multi-role permissions (custom roles).** Tempting to build a flexible role system (users can define arbitrary roles with arbitrary permissions). Rabbit hole: permission-systems-as-configuration is a 3-month effort. v1 alternative: fixed roles (admin, editor, viewer). Custom roles deferred to v2 based on real enterprise pull.

### Why rabbit holes are load-bearing

PRDs without rabbit holes tend to fail in the third week of build when engineering hits the ambiguity. The PM is surprised; engineering is frustrated; the appetite is blown. Rabbit holes pre-commit to the "smallest version that works" so engineering has authority to ship that version without re-litigating.

Every Tier 2+ PRD has at least one named rabbit hole. Most have 2-4.

## 5. Appetite discipline

From Shape Up. Appetite is the inversion of estimate: stating how much time we are willing to spend *before* engineering estimates the work.

**Appetite frames:**

- **Small batch.** 2-3 engineer-weeks. Feature additions.
- **Big batch.** 6-8 engineer-weeks. Cohesive new capabilities.
- **Quarter.** 10-12 weeks. Platform shifts or new product areas.

The appetite is stated in the PRD; engineering's estimate is not required for the PRD to be complete. Engineering's job is to say "can we fit the scope in the appetite, or do we need to cut scope" -- not "how long will this take."

The Out-of-Scope section, the rabbit holes, and the MoSCoW distribution all flow from the appetite:

- Appetite too small -> MoSCoW pushes more items to Should/Could/Won't; Out-of-Scope grows.
- Appetite too large -> Musts expand; Out-of-Scope shrinks; the team builds more than users asked for.

## 6. Change-control protocol

The Out-of-Scope section is the reference for change control. When a stakeholder proposes adding scope mid-build, the protocol:

1. **Check Out-of-Scope Part 1 (explicit no-gos).** If the proposed addition is a named no-go, the change is escalated; it violates a prior decision.
2. **Check Out-of-Scope Part 2 (deferrals).** If it is a deferral, confirm whether the deferral condition has been met. If not, hold.
3. **Check Out-of-Scope Part 3 (non-ownership).** If it is non-ownership territory, reroute to the owning team.
4. **Check appetite.** If accepting the change fits within remaining appetite, document the trade-off (what gets cut to make room) and log in the changelog.
5. **Check rabbit holes.** If the change opens a rabbit hole, refuse or re-scope.
6. **Log the change.** Every accepted or rejected change writes to the PRD's changelog with date, author, and decision.

Silent scope additions (changes accepted without this protocol) are the canonical moving-target-PRD failure. See [iterate-vs-freeze.md](iterate-vs-freeze.md) section 3 for the full change-control lifecycle.

## 7. The "kitchen sink" anti-pattern

A PRD is not a place to record every future idea. "Someday maybe" items belong in a separate backlog (Linear, Notion, wherever the team keeps future ideas). If the PRD contains a 20-bullet "future considerations" section, cut it and link to the backlog.

Future-considerations bloat has two harms:

- Readers can't tell what is in scope now vs. what is aspirational. The PRD loses meaning.
- The future-considerations section becomes the PM's opportunity to avoid decisions ("we'll do it eventually").

## 8. The "scope transparency" test

Before declaring the Out-of-Scope section done, run this test with a stakeholder who has pet features:

1. Read them the Out-of-Scope section.
2. Ask: "Is there anything you expected to be in this release that isn't?"

If yes, that thing either needs to be added to Out-of-Scope (with the reason) or reconsidered as in-scope. The conversation that this test surfaces is uncomfortable but load-bearing; having it during PRD drafting prevents it during build.

## 9. Scope creep detection

Post-Tier-3, during build, watch for these scope-creep signals:

- Multiple "while we're doing this..." requests in the same week.
- Engineering asking "is this in scope?" about things the PRD didn't address.
- Design showing mockups that include features not in the requirements list.
- Marketing/sales drafting collateral that implies features not in the requirements list.

Each signal is a scope-control failure. The fix: run the Step 6 protocol (check Out-of-Scope, check appetite, log). Do not silently absorb.

## 10. Common shapes of bad Out-of-Scope sections

### Shape 1: "Features beyond v1 scope"

The classic AI-slop entry. Replace with enumerated no-gos with reasons.

### Shape 2: "Mobile app"

Too broad. Specify: "Native mobile app (iOS and Android). Mobile-web functional for read operations; write operations require desktop at v1. Native app deferred to v2 based on mobile-usage data."

### Shape 3: A single paragraph with no structure

Out-of-Scope works best as a bulleted list, with each entry having the "what / why / when" structure.

### Shape 4: No non-ownership section

PRDs that omit non-ownership invite cross-team confusion. Include it even if there are only 1-2 entries.

### Shape 5: Deferrals with no conditions

"Deferred to v2" tells no one when it will actually ship. Include the deferral condition ("when enterprise tier has 3 paying customers," "based on mobile-usage data post-launch").

### Shape 6: No rabbit holes

Scope without rabbit holes is scope that will blow up. Include at least one.

### Shape 7: Out-of-Scope shorter than MoSCoW Won't tier

If MoSCoW Won't has 8 items and Out-of-Scope has 3, there are Won't items that do not have reasons or conditions. Migrate them to Out-of-Scope with full context.

## 11. Scope and the different tiers

- **Tier 1 (Brief):** Out-of-Scope is 3-5 high-signal entries. Focus on "what this is NOT" more than deferrals or non-ownership.
- **Tier 2 (Spec):** Out-of-Scope expands to 5-10 entries, includes deferrals and non-ownership, has at least one rabbit hole.
- **Tier 3 (Full PRD):** Out-of-Scope is fully enumerated, cross-linked to MoSCoW Won't tier, rabbit holes named with smallest-version alternatives, change-control protocol is active.
- **Tier 4 (Launch-Ready):** Out-of-Scope is frozen except for deferral-condition updates; any addition triggers the change-control protocol and requires executive sponsor approval.

## 12. The "say no to be able to say yes" rule

Every no-go is a yes to the in-scope items. A PRD with no no-gos has no in-scope focus; the team will do everything and finish nothing.

Stakeholder management tip: when a stakeholder pushes back on a no-go, the answer is not to absorb. It is to name what we would cut from in-scope to add their ask. "We can build Slack integration, but we'd cut the weekly-report view to make room. Which trade-off do you want?" The trade-off usually resolves the request; stakeholders rarely want the trade.

## 13. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 1.3 (missing non-goals failure mode) and section 3 (Shape Up on no-gos and rabbit holes).
- Ryan Singer, *Shape Up* (2019), chapters 4-6 on appetite, pitches, rabbit holes, no-gos.
- Kevin Yien (Square) PRD template -- prodmgmt.world PRD template guide -- on non-goals as a first-class section.
- Basecamp, *It Doesn't Have to be Crazy at Work* (2018) on scope discipline.
- Ken Norton, *How to Hire a Product Manager* (2005-2023) on scope-creep anti-patterns.
