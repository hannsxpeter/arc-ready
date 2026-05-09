# Problem framing (Steps 1 and 2)

Problem framing is upstream of every other section in the PRD. Target user, success metrics, requirements, scope, risks: they all collapse if the problem is framed wrong. This reference covers the pre-flight 7 questions, the substitution test applied to PRDs, the problem-first discipline (Intercom), the competitive-alternative frame (April Dunford), and the cost-of-friction rule.

## 1. The seven pre-flight questions (Step 1)

These run before the Problem section is drafted. Every answer is written; no question is skipped silently. If the user cannot answer a question, it becomes an open question at Step 8 and the PRD's tier destination is capped until it is resolved.

### 1. What is the problem

One paragraph. Name the specific friction a specific person hits on a specific workday.

**Pass:** "When a design-agency PM preps a Friday status update for three concurrent client projects, they pull screenshots from Figma, status blurbs from Asana, and time tallies from Harvest; the combination takes 40-90 minutes per week, and 60% of that time is reformatting, not writing."

**Fail:** "Users struggle with inefficient status reporting."

The difference: the passing paragraph has a role (design-agency PM), a context (Friday status update, three concurrent client projects), tooling specificity (Figma, Asana, Harvest), and a cost (40-90 minutes, 60% reformatting). The failing paragraph names none of these.

### 2. Who has it

A named role, a named context, a named constraint.

**Role:** not "managers," not "teams," not "leaders." "Design-agency PMs managing 3-5 concurrent client projects."

**Context:** the workday moment. Not "when they want to improve productivity" (aspirational, not observed). "Every Friday afternoon preparing client status updates."

**Constraint:** the thing that shapes what solutions are acceptable. Budget, time, tooling, org politics, compliance. "Cannot replace Asana (the client has visibility into Asana); must work alongside it."

### 3. How they solve it today

The competitive alternative, per April Dunford's framing (*Obviously Awesome*, 2019). The existing workaround is usually not another product; it is a Notion page, a cron job, a Slack channel, a Google Sheet, a habit.

**Pass:** "Today, PMs open five tabs on Friday (Figma, Asana, Harvest, the prior week's status doc, and the client-facing status template), copy content across, and reformat. The prior-week doc is the template; each status doc gets 'Save As' renamed."

**Fail:** "Users currently don't have a good solution."

Specificity here pays compounding dividends: the target user is named by their actual behavior, the product's replacement target is concrete, and success can be measured against the specific workaround.

### 4. Why now

The forcing function. What changed that makes this the right moment.

Acceptable answers:

- A technology shift ("LLMs can now summarize multi-tool outputs coherently enough to replace the reformatting step").
- A regulatory shift ("SOC 2 now requires audit trails on vendor data access, which Asana exports don't provide").
- A market shift ("three competitors launched adjacent tools in Q1 2026; the category is forming").
- A user shift ("our own team grew from 4 PMs to 12, which made the hand-assembled status process untenable").
- A cost shift ("the incumbent raised prices by 40% in February; users are shopping").

Unacceptable answers: "because our CEO asked," "because we have budget," "because it's a natural next step." These are organizational reasons, not user or market reasons.

### 5. What it costs them

The current friction, translated into time, money, morale, or risk. Concrete numbers beat adjectives.

**Time:** "40-90 minutes per PM per week."
**Money:** "at $80/hour loaded, $150/PM/month of direct time cost."
**Morale:** "Friday afternoon is the #1 flagged 'low-energy hour' in our 2025 team survey; status-doc prep is the top-cited source."
**Risk:** "3 of 12 PMs report missing errors in pasted status data; one wrong budget number reached a client in Q4 2025 and required apology."

A PRD that claims friction without a number costs the team the ability to prioritize. "Saves time" is not actionable; "saves 40 minutes per PM per week" is.

### 6. What success looks like in 90 days

The outcome, not the ship. Success is user behavior or business outcome, not feature-shipped.

**Pass:** "By day 90 post-launch, 8 of 12 PMs generate their Friday status via the tool (measured by count of `status.generated` events in Amplitude), and the median time-from-open-to-send is under 10 minutes (down from 40-90)."

**Fail:** "The status-doc feature is launched and stable."

The passing statement names an adoption threshold, a behavior change, and a time-delta measurement. The failing statement could be true even if nobody uses the feature.

### 7. Appetite

Shape Up's load-bearing insight: state how much time you are willing to spend before you stop, not how long you think it will take. Appetite is a commitment; estimate is a guess.

**Appetite frames:**

- **Small batch:** 2-3 engineer-weeks. For feature additions with clear scope.
- **Big batch:** 6-8 engineer-weeks. For cohesive new capabilities.
- **Quarter:** 10-12 weeks. For platform shifts or new product areas.

The appetite shapes the requirements list: MoSCoW distribution, rabbit-hole decisions, and no-gos are all downstream of the appetite. A Must-heavy requirements list under a 3-week appetite is unrealistic; either the list is wrong or the appetite is wrong.

## 2. The substitution test applied to PRDs

The load-bearing discipline. Applied sentence by sentence to the user-facing sentences in the PRD.

### Procedure

1. **Isolate the sentence.** Problem statement, each target-user bullet, each success metric headline, each no-go entry, the appetite paragraph. These are the sections where specificity pays most.
2. **Substitute.** Replace the product's name (or the implicit "we") with a named competitor or adjacent product. If no competitor is named, pick the two most obvious ones in the category.
3. **Read.** If the resulting sentence is plausible and reads as the competitor's marketing or PRD would read, the original fails the substitution test. Rewrite.

### Examples

**Fail:**

> Problem: "Users want a faster way to manage their inbox."
> Substitute: "Gmail users want a faster way to manage their inbox." "Superhuman users want a faster way to manage their inbox." Both read plausibly. The sentence decides nothing specific.

> Target user: "Small business owners who value efficiency and growth."
> Substitute: "Small business owners who use QuickBooks..." "Small business owners who use Shopify..." Plausible across the category. Fails.

**Pass:**

> Problem: "When a Ruby on Rails shop upgrades Rails from 7.0 to 7.1 and the app has over 400 model files, `rails app:update` produces 200+ conflicting diffs; 70% of the time is spent reconciling, not reviewing."
> Substitute: "[Competitor] Ruby on Rails shops upgrading from 7.0 to 7.1 with 400 model files..." Only plausible if the competitor in fact targets this exact workflow. Most do not; the sentence is specific.

> Target user: "Engineering managers at a Series B startup with 8-15 engineers, a live production system on AWS, and at least one SOC 2 Type II audit scheduled in the next 6 months."
> Substitute: "[Competitor]'s target: engineering managers at a Series B..." Either the competitor targets this segment or does not; the claim is auditable.

### What the test catches

- Category-level claims (the sentence describes the product category, not the product).
- Adjective-heavy problem framing (faster, better, easier, more efficient) with no named baseline.
- Persona abstractions (age, title without context, generic values).
- Success metrics that could describe any product's success.

### What the test misses

- Factual errors (a specific claim that is specifically wrong).
- Scope-creep within specific claims (the claim is specific but describes 10 features).
- Prose quality (a sentence can be specifically unreadable).

Those are caught elsewhere: Step 5 requirements for scope, Step 8 assumptions-and-risks for evidence, and basic proofreading for prose.

## 3. The problem-first discipline (Intercom's rule)

Intercom's product-principles series (2016-2019) formalized the rule: *do not name the solution in the problem box.* The Problem section describes the friction; the Requirements section names what the system does about it.

### Signs the Problem section has named the solution

- Any sentence starting "Our product..." or "The tool..." or "The system..."
- Any sentence of the form "Users need a [thing that does X]..."
- Any sentence that presupposes the shape of the solution: "a central place where users can...," "automated X," "intelligent Y."
- Any sentence that names a mechanism: "by integrating with Stripe," "using an LLM," "with real-time sync."

### Rewrites

**Before:** "Users need a central dashboard that shows all their project status in one place."
**After:** "Users currently switch between five tabs every Friday to assemble status updates. The reformatting takes 60% of the prep time; 40-90 minutes per PM per week goes to copying between tools rather than thinking."

**Before:** "We need to build an intelligent notification system that surfaces the right alerts at the right time."
**After:** "On-call engineers currently receive 40-120 pages per rotation. Post-rotation surveys (n=28, Q1 2026) show that 70% of pages were not actionable; the median time between a non-actionable page and the next page is 14 minutes, fragmenting sleep."

The rewritten versions do not yet name the solution. That is on purpose; the solution is a downstream decision. Naming it in the Problem section collapses the decision space.

## 4. The competitive-alternative frame (April Dunford)

From *Obviously Awesome* (2019). The competitive alternative is almost never another product; it is usually a process, a habit, or a hack.

### Examples of competitive alternatives in passing PRDs

- "A Notion page and a Slack channel."
- "Five rows in a Google Sheet and a monthly team meeting."
- "A cron job and a prayer."
- "The founder's personal email forwarding rules."
- "Copy-pasting between three SaaS tools every Friday afternoon."
- "A weekly standup where everyone reports the same blockers from last week."

### Why the replacement frame wins

The user's brain already has a mental model of the competitive alternative (because they are using it today). Anchoring the PRD's Problem section on the thing the user already does makes the comparison concrete. It is also the most honest framing: if the PRD cannot name the competitive alternative, the team does not yet understand the problem.

### The "nothing" edge case

If the honest answer to "how do they solve it today" is "they don't," the PRD is on thin ice. "Users don't currently solve this" is a red flag for:

- The problem is not real (if it were, they would have a workaround).
- The problem is real but the users have given up (non-consumption, which is a valid but much harder market).
- The PM does not know how users solve it because they haven't looked.

Pass the PRD only if the PM has done the looking and genuinely believes the user has no workaround. Otherwise, flag as an open question and go talk to three users before Tier 1 sign-off.

## 5. The cost-of-friction rule

Every Problem section includes a cost line. The cost makes the problem prioritizable against other problems.

**Units of cost:**

- **Time.** Minutes, hours, or days per user per cycle.
- **Money.** Direct cost (subscriptions, labor) or indirect (missed revenue, support burden).
- **Morale.** Measured via survey scores, attrition, or direct quotes.
- **Risk.** Compliance exposure, customer trust, data loss.

**Sources of cost:**

- User interviews with time-tracking ("I timed myself last Friday: 52 minutes").
- Tool logs (session duration, tab switches, copy-paste events).
- Surveys (Likert scales on friction, frequency).
- Support tickets (how often does this complaint surface).
- Business data (churn, usage decline, time-to-first-value).

Cost without source is an assumption; mark it as such (Step 8). Cost without a source but claimed as fact is assumption soup.

## 6. The "why now" test

If the PRD cannot answer "why now," it probably cannot answer "why this team, why not a competitor." Why-now is the forcing function that turns a standing problem into a present opportunity.

Acceptable why-now answers cluster into five shapes:

| Forcing function | Example |
|---|---|
| Technology shift | "LLMs are now cheap and accurate enough to summarize multi-tool output" |
| Regulatory shift | "SOC 2 now requires audit trails on vendor data access" |
| Market shift | "Three competitors launched adjacent tools in Q1 2026" |
| User shift | "Our team grew from 4 to 12, which broke the manual process" |
| Cost shift | "Incumbent raised prices 40%; users are shopping" |

Unacceptable why-now answers:

- "We have capacity to build it." (Capacity is not a forcing function.)
- "Leadership asked." (This is an organizational reason, not a market reason.)
- "It's a natural next step." (Without naming the forcing function, this is hand-waving.)

## 7. The PRD's vocabulary (what to call things)

Small discipline that compounds: the PRD uses a consistent vocabulary for the user, the problem, and the competitive alternative. Every subsequent section refers back to these terms.

- **Primary user:** the named role. "The design-agency PM," not "the user," not "PMs," not "customers."
- **Secondary user:** named differently. "The account manager who sees the weekly output," not "other stakeholders."
- **Workaround:** the specific alternative. "The five-tab Friday workflow," not "the current process."
- **Cost:** the specific number. "40-90 minutes per PM per week," not "time spent."

If section 3 refers to "the design-agency PM" and section 5 refers to "users," the PRD has drifted. A grep for "users" in a tier-2+ PRD is a cheap audit; every hit is either correct (a specific use) or drift (the PM's name should have been used instead).

## 8. The "specificity is the discipline" rule

The sum of the above: specificity at every layer. The specific user, the specific workday moment, the specific workaround, the specific cost, the specific forcing function, the specific 90-day outcome. Each layer of specificity cuts the solution space and makes the downstream sections easier.

**Test:** read the Problem section aloud to someone unfamiliar with the project. If they say "interesting, tell me more about that person" rather than "what do you mean by 'users'?", the Problem section is working.

## 9. Further reading

- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 3: canonical PRD literature (Cagan, Horowitz, Lenny, Intercom, Shape Up, Amazon Working Backwards, Biddle, Reforge, Atlassian, HashiCorp, Fishman, Aakash).
- [RESEARCH-2026-04.md](RESEARCH-2026-04.md) section 1.7: the solution-in-search-of-a-problem failure mode with citations.
- April Dunford, *Obviously Awesome* (2019), chapter 3: competitive-alternative framing.
- Intercom, *Intercom on Product: Start with the problem* (2017).
- Shape Up, chapter 6, *Write the Pitch* (Singer, 2019).
