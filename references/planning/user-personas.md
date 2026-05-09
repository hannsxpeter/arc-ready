# Target user: specificity is the discipline (Step 3)

The Target User section is where generic AI-generated PRDs collapse fastest. "Sarah is a 35-year-old marketing manager who values efficiency" is the default failure mode. This reference covers how to replace persona fiction with concrete, cited user descriptions.

## 1. Why persona paragraphs fail

Three independent failures, stacking:

1. **Substitution-test failure.** "Sarah, 35, marketing manager, values efficiency" is plausible for every B2B SaaS product. The sentence decides nothing.
2. **Fiction-becomes-evidence failure.** Invented details get quoted back in design reviews: "but Sarah drinks coffee in the morning, so the dashboard should default to morning view." The fiction calcifies.
3. **Irrelevant-demographic accretion.** Age, beverage, podcast tastes, marital status, commute mode. None drive product decisions. They pad the page and signal effort where effort is missing.

Cagan (Marty Cagan, SVPG), Dunford (April Dunford), and Intercom's product-principles series all argue against the invented-persona artifact for this reason. Replace with what follows.

## 2. The five-bullet user description

One primary user. Optionally one or two secondary users. Each named user has five bullets, not five paragraphs:

### 1. Role

The job title and organizational context. Specific enough that a competitor cannot reuse the sentence.

- **Pass:** "Engineering manager at a Series B US-based SaaS startup with 8-15 engineers, live production on AWS, at least one SOC 2 Type II audit scheduled in the next 6 months."
- **Fail:** "Technical leaders at growing companies."

The role also names the organizational shape (company stage, size, team size) because behavior varies hugely between a 5-engineer Series A and a 200-engineer pre-IPO.

### 2. Context

The specific workday moment. What they are doing when they hit the problem.

- **Pass:** "Every Friday between 2pm and 6pm PT, preparing the weekly client status update for three concurrent agency projects."
- **Fail:** "When they want to improve productivity."

The context is observed (or should be). If the PM hasn't actually watched a user in this moment, the context is a hypothesis; flag it as such.

### 3. Constraint

The thing that shapes what solutions are acceptable. Budget, time, tooling, org politics, compliance.

- **Pass:** "Cannot replace Asana because the client has visibility into Asana; must work alongside. IT-approved tools only; self-serve signup is blocked by SSO requirement."
- **Fail:** "Budget-conscious."

Constraints rule out solutions; they are load-bearing. A PRD that names the problem without naming the constraints usually proposes a solution that cannot actually ship to this user.

### 4. Current workaround

The specific alternative they use today. Consistent with the Problem section (Step 2).

- **Pass:** "Opens five tabs every Friday: Figma (for current mockups), Asana (for task status), Harvest (for time tracking), last week's status doc (as a template), the client-facing status template. Copy-pastes between them; reformats. 'Save As' renames the prior week's doc."
- **Fail:** "Uses various productivity tools."

The current workaround describes the competitive alternative; it is what the product must replace or complement.

### 5. Cited quote or flagged research gap

If user research has happened, one direct quote with attribution. If not, a flagged gap.

- **Pass (research exists):** "'Fridays are my least favorite part of the week. The status doc is 80% mechanical and 20% thinking, and I do the mechanical first because it feels urgent, so by the time I'm thinking I'm tired.' -- Jenna M., Design Agency PM, Jan 2026 user interview n=7."
- **Pass (no research yet):** "No direct user quotes available. Hypothesis to validate via 5 PM interviews by May 7, 2026. [OQ-01] Owner: product-research@company.com."
- **Fail:** "Sarah says she loves efficient tools." (Invented quote.)

Invented quotes are the single worst PRD anti-pattern in this section. They feel like evidence and are not. Refuse to write them.

## 3. The primary-secondary-tertiary hierarchy

Most products have more than one user. The PRD names:

- **Primary user.** The person whose problem the product directly solves. Their success metric drives the PRD's top-line success metric.
- **Secondary user (optional).** Adjacent stakeholder who benefits or blocks. Example: the client of the design agency (consumes the output); the VP of Engineering (approves the purchase).
- **Tertiary user (optional, for multi-sided products).** Rare. Use only if the product has genuinely three distinct user roles (a marketplace's buyer, seller, and platform operator).

A PRD with five personas is almost always over-modeled. Consolidate. The user who is "someone who might also benefit" is not a persona; mention in passing under the primary.

## 4. Research inputs the PRD consumes

prd-ready does not run user research. It consumes research output. Acceptable sources, in roughly decreasing strength:

1. **Direct user interviews.** Quotes with attribution and date. Sample size named.
2. **Usability studies.** Recorded sessions with named participants, task completion rates, observed friction.
3. **Surveys.** Representative sample with n, response rate, and question text. Likert and frequency data.
4. **Analytics.** Behavior data from the existing product (session duration, feature usage, drop-off). Named events.
5. **Support ticket analysis.** Complaint frequency, common themes, named quotes from tickets.
6. **Customer interviews (non-users).** What they do today, why they don't use any current solution.
7. **Competitor reviews.** G2, Capterra, Trustpilot, subreddit complaints. Not primary research but useful input.
8. **Sales call recordings.** Gong, Chorus, or equivalent. Direct language from prospects.

If the PRD has none of the above, it is running on hypothesis. Mark everything user-related as hypothesis, log validation as an open question (Step 8), and cap the tier at 1 or 2 until the research happens.

## 5. When research is thin

Small teams, early products, or pre-launch products often have thin research. This is fine; pretending otherwise is not.

Acceptable patterns when research is thin:

- **"We interviewed 3 users in March 2026. Quotes are attributed. The sample is small and likely biased toward early-adopter types. We will validate with 10 more interviews by June."**
- **"No direct user research yet. This PRD is running on the founder's 8 years of domain experience in this space. Key claims about user behavior are flagged as hypotheses with validation plans in Step 8."**
- **"Research sample is 12 internal users; we treat this as a dogfood proxy and flag that external-user patterns may differ."**

Unacceptable patterns:

- "Extensive user research confirms..." (with no citation).
- "Our research shows..." (without naming the research).
- Invented quotes ("Sarah, a typical user, says...").
- "Best practices indicate..." (not user research; industry aphorism).

The gap between strong and weak research is not "faking confidence"; it is naming what you know and what you don't.

## 6. Jobs-to-be-Done (JTBD) as an input

JTBD (Clayton Christensen, 2016) frames the user by the job they're hiring the product to do. JTBD is a useful input to the Role and Context bullets; it is not a substitute for them.

**JTBD applied correctly:**

- The user hires the product to do: "Prepare the Friday client status update in under 15 minutes instead of 40-90, without having to explain missing items to the client."
- The functional job: summarize multi-tool data into a client-readable format.
- The emotional job: feel confident that the status doc is accurate and complete before sending.
- The social job: look prepared and on top of things to the client.

**JTBD applied incorrectly:**

- The user hires the product to do: "save time and feel empowered." (Too generic; the substitution test fails.)

Use JTBD as a lens on the Context bullet (what job the user is doing in this workday moment). Do not let JTBD language replace role/constraint specificity.

## 7. Anti-personas (optional section)

Some PRDs benefit from naming the user the product is *not* for. Example: "We are not building for enterprise teams with 100+ engineers; their workflow has different failure modes (approval chains, vendor procurement cycles, custom SAML) that we are deferring to v2 at earliest."

Anti-personas are useful for:

- Clarifying scope (helps Step 7 no-gos).
- Pre-empting stakeholder asks ("why doesn't this work for a 500-person team?" -- because it isn't for them).
- Sharpening the primary-user description by contrast.

Not every PRD needs anti-personas. Include if you catch yourself repeatedly saying "that's not who this is for."

## 8. The specificity grep

A cheap audit. After drafting the Target User section, grep for these abstractions:

| Abstraction | Replace with |
|---|---|
| "users" | the named role |
| "customers" | the named role |
| "small teams" | a specific team shape (size, stage, tooling) |
| "enterprise users" | a specific enterprise shape (size, industry, compliance) |
| "modern teams" | drop; this is filler |
| "tech-forward" | drop; this is filler |
| "busy professionals" | drop; this is filler |
| "growth-stage companies" | a specific stage (Series A, B, C) with revenue or employee count |
| "values efficiency" | drop; everyone claims to value efficiency |

If the section survives the grep with minimal changes, it is specific. If most bullets need rewriting, the section is abstracted; rewrite with the five-bullet structure above.

## 9. The user sheet (optional artifact for teams)

For products with complex or multi-sided users, maintain a separate `.prd-ready/USERS.md` file with a dense description of each primary/secondary user. The PRD references this file rather than duplicating content.

The user sheet is not a persona deck; it is a living user-description artifact. Update when new research lands; cite the date.

Format:

```markdown
# Users

## Primary: Design-Agency PM

- Role: (5 bullets)
- Context: (5 bullets)
- Constraint: (5 bullets)
- Workaround: (5 bullets)
- Research: Jenna M. (Jan 2026), Priya K. (Feb 2026), Tom S. (Feb 2026). 3 interviews. Sample skewed toward US West Coast; EU and APAC not sampled.

## Secondary: Design-Agency Account Manager

- Role: ...
- Context: ...
```

## 10. The "who would be surprised" test

Before declaring the Target User section done, ask: **"If this user read their own description, would they be surprised by any claim?"**

If yes (they would disagree with something, they would find a detail wrong, they would laugh at an invented preference), rewrite. Genuine user research produces descriptions users recognize as themselves. Invented personas produce descriptions users find off-putting.

For products pre-launch, swap "would be surprised" for "would a user in this role, if shown this description, nod and say 'yes, that's my Friday'." If the answer is ambiguous, do one more interview.

## 11. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 3: Intercom, Cagan, Horowitz, Atlassian on target users.
- April Dunford, *Obviously Awesome* (2019), chapter 4 on positioning to a segment.
- Clayton Christensen, *Competing Against Luck* (2016) on Jobs-to-be-Done.
- Erika Hall, *Just Enough Research* (2nd ed., 2019) on lightweight user research for small teams.
