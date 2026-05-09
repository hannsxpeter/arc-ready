# Stack Research

The Step 0 protocol. Before generating any recommendation, know which mode the session is in and what the current project state actually contains.

**Scope owned by this file:** mode detection (A/B/C/D), codebase stack-sniffing for existing projects, the structured output block each mode must produce. Scoring, weighting, and candidate shortlisting live elsewhere.

## Modes

Four modes. Each produces a different research output block. Pick one explicitly before continuing.

### Mode A: Greenfield

**Trigger:** no code yet, or a fresh directory, or a `package.json` with no dependencies in an otherwise empty repo. The user is picking a stack from scratch.

**Output block:**

```
## Research (Mode A: Greenfield)

- Starting point: [empty directory / boilerplate / blank Next.js app / etc.]
- Known external constraints: [deployment target, existing API, existing design system]
- Pre-installed dependencies: [none / list]
- Skill-declared defaults carried forward: [none unless user restated them]
```

If the user has an existing deployment target (e.g., "we already use AWS"), a mandated framework ("we're a Django shop"), or an identity provider in use ("we already use Okta company-wide"), capture those as inherited constraints. They will feed Step 2.

### Mode B: Assessment

**Trigger:** existing codebase, user is evaluating whether to continue with the current stack or layer in a new capability. Typical phrasing: "we have a Rails app, should we use Postgres or Convex for the new analytics feature," "our Next.js app is mature, where should we add background jobs."

**Output block:**

```
## Research (Mode B: Assessment)

### Current stack inventory
| Dimension | Current | Source of evidence |
|---|---|---|
| Framework | [detected] | [file path or config key] |
| Language | [detected] | [file] |
| Database | [detected] | [ENV var / config / migration file] |
| ORM | [detected] | [schema file / package] |
| Auth | [detected] | [middleware / package] |
| UI library | [detected] | [package.json / imports] |
| Client state | [detected] | [imports / hooks] |
| Hosting | [detected] | [deploy config / README] |
| Observability | [detected] | [SDK imports / config] |
| Payments | [detected / none] | [package / API calls] |
| Email | [detected / none] | [package / API calls] |
| Background jobs | [detected / none] | [worker config / package] |

### Gaps (dimensions with no current choice)
- [dimension]: [implication]

### Friction signals in existing stack
- [anything that's clearly fighting the team: rewrites-in-progress, TODOs around a specific lib, recent migrations]
```

In Assessment mode, the job is inventory, not judgment. Judgment happens in Step 5.

### Mode C: Audit

**Trigger:** the user asks "did we pick right," "should we move off X," "is our stack still appropriate," "we're considering a migration, is it worth it." Often driven by a recent friction event (bill shock, scale issue, incident, team turnover).

**Output block:**

```
## Research (Mode C: Audit)

### Current stack inventory
(same table as Mode B)

### Trigger for audit
[what prompted this: bill, incident, scale, team change, new requirement]

### Keep/adjust/replace verdict per dimension (preview)
| Dimension | Current | Verdict | Short reason |
|---|---|---|---|
| Framework | ... | Keep | fits domain, no scale pressure |
| Database | ... | Adjust | add read replica, no replacement needed |
| Auth | ... | Replace | pricing cliff hit, alternatives exist |

(Full scoring and migration plan come in Step 5 and Step 7; this is the triage.)
```

Audit mode typically produces 1-3 replace verdicts, 1-2 adjust verdicts, and the rest keep. If every dimension is verdict-"replace," the team is asking the wrong question (they want a rewrite, not an audit). Push back before scoring.

### Mode D: Migration

**Trigger:** the user has already decided to move from X to Y, or has narrowed it to X-or-Y and wants the cost. Typical phrasing: "we're moving off Firebase to Postgres, what's the sequence," "Clerk to Better Auth migration plan," "how do we get off Vercel."

**Output block:**

```
## Research (Mode D: Migration)

### Source stack (current)
[full stack inventory, same shape as Mode B]

### Target stack (proposed)
| Dimension | Target | Replacing |
|---|---|---|
| [dim] | [new] | [old] |
(only the dimensions being migrated; others stay)

### Explicit goal of migration
[what the user is trying to achieve: cost, compliance, capability, ops simplicity, exit a vendor]

### Constraints on the migration
- Must remain up throughout (dual-run needed)
- Data must survive (migration is non-negotiable)
- Cutover window: [hours / days / weeks acceptable]
- Rollback window: [if we're not confident at T+7d, we need to be able to revert]
```

Mode D usually skips to Step 7 after a brief Step 1 pre-flight. The scoring pass is usually not needed (the target stack is already chosen); the value is the sequenced plan, not the comparison.

## How to detect the mode

Sometimes the user states it. Often they don't. Infer from signal:

| Signal | Likely mode |
|---|---|
| Empty repo or boilerplate only | A |
| User says "should I use X or Y" | A or B, depending on existing code |
| Existing code, user asks "where to add [capability]" | B |
| Existing code, user asks "did we pick right" | C |
| User names a source and a target ("Firebase to Postgres") | D |
| User describes friction + asks about alternatives | C |
| User describes a new feature + asks what to use | B (if existing code) or A (if greenfield) |

If a single session spans multiple modes (e.g., "we're auditing the stack AND planning a migration off the payment provider"), run Mode C first, then Mode D for the specific dimension being migrated.

## Codebase stack-sniffing

In Modes B, C, and D, inventory the current stack before recommending anything. Do not ask the user for facts the filesystem can answer.

### Framework / language detection

| File | Inference |
|---|---|
| `next.config.js` / `next.config.ts` | Next.js |
| `app/routes/` directory with `*.tsx` | Remix |
| `svelte.config.js` | SvelteKit |
| `nuxt.config.ts` | Nuxt |
| `astro.config.mjs` | Astro |
| `Gemfile` with `rails` | Rails |
| `manage.py` and `settings.py` | Django |
| `artisan` CLI and `composer.json` with `laravel/framework` | Laravel |
| `mix.exs` with `phoenix` | Phoenix |
| `main.py` with `from fastapi import` | FastAPI |
| `app.py` or `application.py` with `from flask import` | Flask |
| `go.mod` with `github.com/gin-gonic/gin` or `labstack/echo` | Go web framework (name from dep) |
| `pom.xml` or `build.gradle(.kts)` with Spring | Spring Boot |
| `Program.cs` with `WebApplication.CreateBuilder` | ASP.NET Core |

### Database detection

| Signal | Inference |
|---|---|
| `DATABASE_URL=postgres://` in `.env.example` | Postgres |
| `DATABASE_URL=mysql://` | MySQL |
| `DATABASE_URL=file:./dev.db` or `sqlite` | SQLite |
| `convex/` directory with `schema.ts` | Convex |
| `firebase.json` with Firestore config | Firestore |
| `@supabase/supabase-js` in dependencies | Supabase (Postgres-backed) |
| `aws-sdk` with `DynamoDB` imports | DynamoDB |
| `mongoose` or `mongodb` package | MongoDB |
| `prisma/schema.prisma` with `provider` field | Check the provider value |

### ORM detection

| Signal | Inference |
|---|---|
| `prisma/schema.prisma` | Prisma |
| `drizzle.config.ts` | Drizzle |
| `kysely` in dependencies | Kysely |
| `sqlalchemy` in `requirements.txt` or `pyproject.toml` | SQLAlchemy |
| `config/database.yml` with ActiveRecord conventions | ActiveRecord (Rails) |
| `lib/*/repo.ex` | Ecto (Phoenix) |
| Raw SQL files in `sql/` or `db/` with no ORM package | Raw SQL |

### Auth detection

| Signal | Inference |
|---|---|
| `@clerk/nextjs` or `@clerk/clerk-react` | Clerk |
| `better-auth` package | Better Auth |
| `next-auth` or `@auth/core` | Auth.js |
| `@workos-inc/node` or `@workos-inc/authkit-nextjs` | WorkOS |
| `@supabase/auth-helpers-*` or `supabase.auth` calls | Supabase Auth |
| `firebase/auth` imports | Firebase Auth |
| `Gemfile` with `devise` | Devise (Rails) |
| `django-allauth` in `requirements.txt` | django-allauth |
| Custom middleware with JWT or session code and no auth SDK | Rolled-their-own |

### UI library detection

| Signal | Inference |
|---|---|
| `components/ui/` directory with `button.tsx` and `components.json` at root | shadcn/ui |
| `@radix-ui/*` in deps (without shadcn) | Radix primitives |
| `@mantine/core` | Mantine |
| `@mui/material` | MUI |
| `@chakra-ui/react` | Chakra UI |
| `antd` | Ant Design |
| `tailwindcss` with no component library | Tailwind + custom |
| Only plain CSS / no framework | Custom / raw |

### Hosting detection

| Signal | Inference |
|---|---|
| `vercel.json` or `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `fly.toml` | Fly |
| `railway.json` or `nixpacks.toml` | Railway |
| `render.yaml` | Render |
| `serverless.yml` or `cdk.json` with AWS | AWS |
| `app.yaml` (GCP App Engine) or GCP-specific configs | GCP |
| `azure-pipelines.yml` with Azure deploy steps | Azure |
| `wrangler.toml` | Cloudflare Workers / Pages |
| `Dockerfile` with no cloud-specific config | Portable container, hosting unknown |

### Observability detection

| Signal | Inference |
|---|---|
| `@sentry/*` packages | Sentry |
| `dd-trace` or `datadog-ci` | Datadog |
| `newrelic` package | New Relic |
| `@honeycombio/*` or OpenTelemetry config pointing at honeycomb.io | Honeycomb |
| `axiom` or `@axiomhq/*` | Axiom |
| Plain console.log and nothing else | No observability |

### Payments detection

| Signal | Inference |
|---|---|
| `stripe` package, webhook routes | Stripe |
| `paddle-js` or server-side Paddle SDK | Paddle |
| `@lemonsqueezy/*` | Lemon Squeezy |
| `braintree` package | Braintree |
| `@adyen/*` | Adyen |
| Stripe package with `stripe.transfers.create` or Connect account IDs | Stripe Connect (marketplace) |

### Email detection

| Signal | Inference |
|---|---|
| `resend` package | Resend |
| `postmark` package | Postmark |
| `@sendgrid/*` | SendGrid |
| `@aws-sdk/client-ses` | AWS SES |
| `loops` package | Loops |
| Raw SMTP with nodemailer pointed at a custom relay | Self-hosted SMTP |

### Background jobs detection

| Signal | Inference |
|---|---|
| `inngest` package with `inngest/client` | Inngest |
| `@trigger.dev/*` | Trigger.dev |
| `bullmq` or `bull` package with Redis | BullMQ / Bull |
| `aws-sdk` with `SQS.send` calls | SQS |
| `Gemfile` with `sidekiq` | Sidekiq (Rails) |
| `celery` in Python deps | Celery |
| `oban` in Elixir deps | Oban |
| `temporalio` package | Temporal |

## Rules for working with existing codebases (Modes B, C, D)

- **The filesystem is the source of truth.** If a package is in `package.json` but never imported, note it as "declared but unused" rather than counting it as the current stack.
- **Check the ENV.** A `.env.example` with `DATABASE_URL=postgres://` is a stronger signal than a `prisma/schema.prisma` in a branch the user hasn't merged.
- **Look at recent commits.** A stack in active migration (lots of commits touching adapter files, switched ORMs in the last 3 months) is not the same as a stack that has been stable for 2 years. Audit decisions should account for the direction of travel.
- **Identify the primary service vs. the experimental branch.** A monorepo with a production Next.js app and a side experiment in Remix is still a Next.js shop.
- **Do not recommend removing what's working unless the user named it as a problem.** If Mode C audit says "database is fine," do not volunteer "but maybe you should try Convex." Stay in the user's scope.

## Anti-patterns in the research phase

Signals that the research phase went wrong and must be redone before proceeding:

- **Asking the user questions the repo already answered.** If `next.config.js` exists, "are you using Next.js" is a tax, not research.
- **Treating a half-migrated codebase as a stable one.** If the repo has both Prisma and Drizzle configs, something is mid-migration; surface that before scoring the other dimensions.
- **Inferring hosting from the user's preference instead of the `vercel.json`.** Current state beats stated intent.
- **Skipping ENV inspection.** A Postgres app with an undocumented read replica, a separate analytics DB, or a ghost Redis is a common source of Mode C surprises.
- **Not reading the README.** If the README says "hosted on AWS ECS" and the codebase has a `vercel.json`, something is stale. Ask.

## When to re-run the research

The research output lives for the session. If any of the following happen, re-run Step 0:

- The user adds a new constraint that changes the scope (e.g., "oh, we also need HIPAA").
- The user corrects a detected value ("no, we're actually on Render, not Railway").
- The user pastes a package.json or config file that contradicts the inventory.
- The session resumes after hours and the codebase may have changed.

Do not silently update the inventory; declare the re-run and overwrite the block.
