# Scoring Framework

The Step 5 protocol. Twelve scoring dimensions, default weights, override mechanics, and the discipline that keeps scores from being horoscopes.

**Scope owned by this file:** the scoring rubric, weighting math, and per-score discipline rules. Per-dimension candidate detail lives in `dimension-deep-dives.md`; per-domain picks live in `domain-stacks.md`.

## The 12 dimensions

Each candidate in each dimension gets a score 1-10 plus a one-line rationale. Dimensions are scored independently, then aggregated under weights.

| # | Dimension | Primary score axis |
|---|---|---|
| 1 | Framework | DX + ecosystem + domain fit |
| 2 | Language / runtime | Team fit + ecosystem + hireability |
| 3 | Database | Data model fit + scale ceiling + ops burden |
| 4 | ORM / query layer | DX + type safety + migration story |
| 5 | Auth / identity | Feature fit + pricing at scale + compliance posture |
| 6 | UI library | Customization + accessibility + ecosystem |
| 7 | Client state / data fetching | Integration with framework + cache model + DX |
| 8 | Hosting / deploy | Ops burden + cost at scale + compliance fit |
| 9 | Observability | Signal quality + cost + ops burden |
| 10 | Payments | Feature fit (one-time vs. recurring vs. marketplace) + geographic coverage + fees |
| 11 | Email / notifications | Deliverability + DX + cost at volume |
| 12 | Background jobs / queues | Reliability + DX + ops burden |

## Score discipline

The rules that make scores honest.

### 1. No 10/10 unless no rational alternative exists

A 10 means "any alternative is a mistake for this job." That threshold is high. Stripe is a 10 for recurring B2B payments. Postgres is a 10 for relational data in the SaaS domain. TypeScript is not a 10 for "frontend" since Ruby with Hotwire is a legitimate alternative.

### 2. No 1-2/10 without a documented failure mode

A 1 or 2 means "ship and regret in the first three months." Usually driven by a documented incident (ProvideRocket incident, pricing cliff, acquisition with integration loss, archived repo). If the score is 1-2, the rationale must name the failure mode.

### 3. Scores are context-dependent, not universal

Prisma is 8/10 for a small Next.js team and 5/10 for a team with heavy SQL ops needs. Drizzle is 9/10 for TypeScript purists and 6/10 for a team that won't look at the generated SQL. Supabase is 9/10 for a solo founder and 5/10 for an enterprise with compliance in scope. Context shapes the number.

Do not produce a "universal" score. Score against the pre-flight answers.

### 4. Rationale is one line, not a paragraph

A good rationale: "Best-in-class migration story, weaker SQL ergonomics than Drizzle, excellent domain fit for SaaS with simple-to-medium queries."

A bad rationale: "Prisma is a great ORM that many teams love. It has a schema language, generates types, and supports lots of databases." (No context, no tradeoff, no judgment.)

### 5. Score what matters to this job, not what matters in general

If the pre-flight says "DX is the top priority," the Framework score leans heavily on DX. If "scale ceiling is the top priority," it leans on scale ceiling. Scoring the same way regardless of priorities is a category error.

### 6. Disclose commercial ties

If the agent or the author of the skill has a commercial relationship with a vendor being scored (affiliate, employment, contract), disclose it in the output or recuse that specific score. Undisclosed ties are disqualifying.

## Default weights

Use these weights unless the user overrides. State the default vector in the output.

```
DX                        20%
Scale ceiling             13%
Cost at target scale      13%
Ecosystem depth            8%
Ecosystem trajectory       7%
Exit cost / reversibility  7%
Ops burden                12%
Compliance fit            10%
Hireability               10%
```

Rationale:

- **DX (20%)**: the team builds this every day. A 1-point DX difference compounds over months of work.
- **Scale ceiling (13%)**: hitting a ceiling is a forced rewrite; weight enough to matter.
- **Cost at target scale (13%)**: price at the 12-month scale, not today.
- **Ecosystem depth (8%)**: current scale of the community. StackOverflow questions, npm/PyPI downloads, library count, hireability overlap. Proxies the resources available *today*.
- **Ecosystem trajectory (7%)**: where the ecosystem is going. State of JS "interest" and "retention" axes, release cadence, maintainer activity, bus factor. Split out from depth because a library can have high depth and flat trajectory (a stable default like Postgres) or low depth and high trajectory (a rising candidate like Hono). Collapsing both loses signal.
- **Exit cost / reversibility (7%)**: the rebuild bill if this pick is wrong. Scored 1-10 where 10 = "swap in a day, no data migration" and 1 = "full rewrite in a proprietary query language." Convex and Firebase score well on DX but lower here; Postgres + a thin ORM scores high. This axis used to live only in the Tier 3 tradeoff narrative; evidence from migration postmortems (see `RESEARCH-2026-04.md`) shows it is material at score-time, not just narrative-time.
- **Ops burden (12%)**: self-host vs. managed is about team-hours.
- **Compliance fit (10%)**: for unregulated domains this rounds down; for regulated domains, compliance acts as a *filter* in Step 2, and this weight governs compliance *quality* within the filtered set (audit log depth, subprocessor chain, BAA tier availability).
- **Hireability (10%)**: matters at scale, less for solo founders.

### On the 12-dimension count

ASQ, Pugh, and ThoughtWorks frameworks converge on 4-8 criteria as the sweet spot for a single decision. stack-ready uses 12 dimensions because a fullstack bundle has 12 independent architectural seams (framework, language, database, ORM, auth, UI, client state, hosting, observability, payments, email, background jobs), each of which meaningfully changes the bundle. Collapsing seams loses information. The *aggregate* is a summary, not the decision; the per-dimension scores and the tradeoff narrative are where the actual reasoning lives. Users who find 12 axes overwhelming can read the aggregate alone; users who want depth can read the full table.

## Override mechanics

Users override in two ways.

### 1. Named shifts

The user says in natural language:

- "I care about DX" -> DX +10%, other dimensions proportionally reduced.
- "Cost matters more than anything" -> Cost +20%, proportionally redistribute.
- "We don't care about hireability, solo founder" -> Hireability 0%, redistribute 10% proportionally.
- "Compliance is the thing" -> Compliance +15%, typically for regulated domains.

### 2. Numeric vector

The user hands over a vector:

```
DX 30, Scale 10, Cost 20, EcoDepth 6, EcoTraj 4, Exit 5, Ops 10, Compliance 5, Hireability 10
```

Must sum to 100. Skill states it back to confirm before scoring.

## When to skip the scoring pass entirely

The anti-scoring camp (Dan McKinley's "Choose Boring Technology," DHH's "one-person framework," Pieter Levels' "PHP + SQLite") argues formal scoring can itself be a failure mode: a small experienced team already knows the answer, and paralysis by analysis costs more than the occasional wrong pick. stack-ready should honor this when it applies.

**Skip the full scoring pass when all three are true:**

1. The user states an explicit preference grounded in experience: "we've shipped three apps on Rails; we're picking Rails again."
2. The decision is reversible within ~4 weeks if wrong (see pre-flight question 7).
3. No hard constraints are in flux (compliance posture unchanged, scale ceiling same order of magnitude).

In that case, run a compact pre-flight + constraint check only (5 minutes, not 30). Confirm the stated pick against the domain's hard constraints. If it passes, write the DECISION.md with "Bundle chosen by experience-based preference; full scoring pass skipped per §skip-scoring-pass in scoring-framework.md."

**Do not skip** when:
- The decision is foundational (database, compliance posture, hosting platform for a multi-year product).
- The user is asking "should we pick X" (the question implies they want the scoring).
- A regulated domain is in scope (compliance filter is still mandatory, even if picks beyond the filter are trusted).
- The user has named conflicting preferences ("we want both Convex and Prisma") that require a scoring pass to resolve.

This is not a concession to vibes-based decision-making. It is recognition that formal scoring has a target domain: non-trivial, non-reversible, non-obvious decisions. Small, reversible, obvious decisions do not need it.

## Domain-specific weight remaps

Some domains force weight shifts before the user overrides. These are the built-in remaps.

| Domain | Remap |
|---|---|
| Healthcare / Medical | Compliance to 25%, redistribute from DX and Hireability |
| Fintech / Financial | Compliance to 20%, Scale ceiling to 18%, redistribute from DX |
| Government / Public Sector (if in scope) | Compliance to 30%, Cost to 5%, redistribute |
| Education / LMS | Accessibility (as a sub-score of UI library) moved to Tier 1 gate; not a weight shift so much as a filter |
| Internal Tools / Back-office | DX to 25%, Scale to 8%, redistribute; ceiling is low by design |
| AI / ML / LLM products | Ecosystem to 20% (fast-moving space); DX to 25% (streaming UX, eval integration) |

State the remap in the output. "Healthcare domain: Compliance weight bumped to 25% before scoring."

## How the aggregate works

Weighted average:

```
AggregateScore = Sum(dimension_score * dimension_weight / 100)
```

Round to one decimal place. An aggregate of 7.8 vs. 7.6 is meaningful; 7.85 vs. 7.83 is false precision.

## The ranking output

The Step 5 output is a table like this:

```
| Bundle | Framework | DB | ORM | Auth | UI | State | Host | Obs | Pay | Email | Jobs | Lang | Aggregate |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Safe Default | Next.js (9) | Postgres (9) | Drizzle (8) | Better Auth (8) | shadcn (9) | TanStack (9) | Vercel (8) | Sentry (8) | Stripe (9) | Resend (9) | Inngest (8) | TS (9) | 8.6 |
| Fast-to-Ship | Next.js (9) | Convex (9) | (N/A) | Clerk (9) | shadcn (9) | Convex hooks (9) | Vercel (8) | Sentry (8) | Stripe (9) | Resend (9) | Inngest (7) | TS (9) | 8.7 |
| Enterprise | Next.js (9) | Postgres (9) | Prisma (8) | WorkOS (10) | custom+Radix (8) | TanStack (9) | AWS (7) | Datadog (8) | Stripe (9) | Postmark (9) | Temporal (8) | TS (9) | 8.4 |
```

**Notes on this format:**

- "(N/A)" for dimensions the bundle replaces (Convex has no separate ORM).
- Parenthetical scores per dimension.
- Aggregate at the end.
- Hand-picked example; actual scoring follows pre-flight.

## Avoiding common scoring mistakes

### Mistake 1: Scoring the same candidate the same way across all domains

Prisma is not 8/10 everywhere. It's 8/10 for a Next.js SaaS with simple-medium queries, 5/10 for a reporting-heavy analytics app, 7/10 for a marketplace with moderate complexity. Score against this domain.

### Mistake 2: Rewarding novelty

"New" is not "better." A 2025-released library scoring above a 2019-stable library needs to justify the age gap. Novelty is usually reflected in Ecosystem (lower) and Maturity (lower); if the candidate's core capability is better, that shows up in DX or Scale.

### Mistake 3: Punishing popularity

"Everyone uses X" is not "X is mediocre." Popularity usually reflects ecosystem depth, which is a legitimate score contributor. Next.js is not overrated because it is popular; it is popular partly because it is legitimately strong for its domain.

### Mistake 4: Letting aesthetics override fit

"Prisma's DSL annoys me" is a real score input (DX), but it should be stated as a preference and not dressed up as a universal objection. "The team dislikes Prisma's DSL, score Prisma DX-1" is honest. "Prisma is bad because its DSL is ugly" is false objectivity.

### Mistake 5: Ignoring ecosystem churn in fast-moving spaces

AI/ML frameworks, identity providers, and payment providers all churn fast. A score taken in 2024 may not hold in 2026. The staleness check (Step 9) warns users when this risk is material.

## How to score a close call

When two candidates are within 0.3 points of each other on the aggregate, the aggregate is not the deciding factor. Decide on:

1. **Team preference.** Do they have strong positive or negative history with either?
2. **Ecosystem trajectory.** Which library has more momentum over the last 12 months?
3. **Switching cost.** If wrong, which is cheaper to move off?
4. **Specific domain fit.** Is there a dimension where one candidate clearly wins for this job?

Do not break a tie with a fourth decimal place; break it with a narrative.

## How scoring interacts with the pairing check

Scoring happens after pairing compatibility (Step 4). A bundle that survives pairing and then scores 7.2 beats a bundle that scores 8.9 but contains a rejected anti-pairing. Pairing is gate, scoring is ranking.

If a user tries to override the pairing check to include a rejected bundle (e.g., "I really want Convex + Prisma, score it anyway"), surface the pairing objection, and if they insist, score it with the rationale "anti-pairing accepted against recommendation."

## When scoring should be skipped

Not every session needs a full scoring pass.

- **Mode D (Migration)** usually does not need scoring. The user has already picked the target; the value is the sequenced plan.
- **Single-dimension questions** ("Prisma or Drizzle") may only need that one dimension scored, not all 12.
- **Audit with clear verdicts** (Mode C where the current stack is clearly fine except for one dimension) can skip scoring on the "keep" dimensions.

State when scoring is skipped and why. "Skipped scoring on Framework, Language, DB, ORM, UI, State (Mode C keep verdicts). Scored only Auth (replace) and Email (replace)."

## What to do with scores going forward

The scores inform Tier 4 `.stack-ready/DECISION.md`. Every dimension in the chosen bundle carries its score forward. Rejected bundles preserve their aggregate so a future reader can see how close the call was.

Scores are not timestamped at the individual-score level (that's too much work). The skill version and date on the document are the timestamp. When the user re-runs this in 6 months, the scoring may shift materially; that's expected and why Step 9 exists.
