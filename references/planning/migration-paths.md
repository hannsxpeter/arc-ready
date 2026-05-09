# Migration Paths

The Step 7 protocol. When the user has already decided to move from X to Y, this file carries the sequenced path: blast radius, steps, rollback checkpoints, data migration strategy, and honest team cost.

**Scope owned by this file:** X-to-Y migration sequences for common stack transitions. Tradeoff analysis lives in `tradeoff-narratives.md`; pairing conflicts live in `pairing-rules.md`.

## How to read a migration path

Each migration has:
- **When to do it.** Preconditions: what must be true before starting.
- **Blast radius.** What stops working temporarily. What risks permanent data loss. What integrations break.
- **Phased sequence.** Step-by-step plan with cutover points.
- **Rollback checkpoints.** At each phase, what reverts the system if a step fails.
- **Data migration strategy.** Schema transforms, backfills, reconciliation.
- **Engineer-week cost.** Honest estimate for the migration itself; does not include the new-features work that motivated the migration.

## Pattern: the safe migration

Most migrations should follow this pattern, adapted to the specifics:

1. **Dual-run phase.** Write to both old and new systems. Read from old.
2. **Backfill phase.** Migrate historical data to new.
3. **Shadow-read phase.** Read from both; compare; alert on divergence.
4. **Cutover phase.** Flip reads to new. Keep writes dual for safety.
5. **Single-run phase.** Stop writing to old.
6. **Decommission phase.** Turn off old infrastructure.

Every phase has a rollback to the previous phase. Every phase has a validation gate before advancing.

---

## Migration 1: Firebase Firestore to Postgres

**When to do it.** Cross-collection queries have become central; Firestore's query model is forcing workarounds. Read pricing at scale is hurting the unit economics. Team wants relational integrity guarantees.

**Blast radius.** Real-time listeners need a new architecture (Postgres + LISTEN/NOTIFY, or a real-time layer like Supabase Realtime or a WebSocket service). Firebase Auth is separate; keep it or migrate. Client SDKs change; every read/write site gets touched.

**Phased sequence:**

1. **Design the Postgres schema.** Not a 1:1 port of Firestore collections; reshape for relational integrity. Expect 1-2 weeks for a non-trivial app.
2. **Dual-write.** Every write to Firestore also writes to Postgres. Run for 2-4 weeks to validate. Add telemetry for divergence.
3. **Backfill.** Export Firestore collections via batched reads; transform and load into Postgres. For large apps, this is the dominant cost.
4. **Shadow-read and reconcile.** Read from both; log divergences; fix the dual-write bugs you find.
5. **Flip reads to Postgres.** Client-by-client or feature-by-feature. Dual-write continues.
6. **Stop writing to Firestore.** After 2-4 weeks of stable Postgres-only reads.
7. **Archive and decommission Firestore.** Keep read-only access for 30 days minimum.

**Rollback checkpoints:**

- After step 2: revert to Firestore-only reads. Turn off dual-write.
- After step 5 (reads flipped): re-enable reads from Firestore. Dual-write still active.
- After step 6: this is the first hard cutover. Rollback means re-enabling writes to Firestore and back-filling any new writes.

**Data migration strategy.**

- Export via Firestore Admin SDK with cursor-based pagination.
- Transform in a script that produces Postgres COPY-compatible files.
- Load via `COPY` or via INSERT batches.
- Validate: row counts, checksums on key fields, sample spot-checks.
- Reconciliation: maintain a divergence log during dual-write; manual reconciliation pass before flipping reads.

**Engineer-week cost.**

- Small app (tens of collections, low-tens-of-thousands of documents): 4-6 engineer-weeks.
- Medium app (hundreds of collections or millions of documents): 10-16 weeks.
- Large app (complex cross-collection queries, real-time heavy): 16-32 weeks.

**Common traps.**

- Assuming Postgres schema equals Firestore structure. It shouldn't.
- Forgetting real-time; Firestore listeners don't translate to plain Postgres without work.
- Forgetting Firebase Auth; migrate it separately with its own plan (see Migration 9).
- Skipping the dual-write reconciliation; divergence will bite you.

---

## Migration 2: Supabase to self-hosted Postgres

**When to do it.** Cost at scale has crossed the threshold; compliance requires VPC isolation; team wants operational control.

**Blast radius.** Postgres itself moves cleanly. Supabase Auth, Storage, Realtime, and Edge Functions each need individual replacement plans. RLS policies move with the data but may need review.

**Phased sequence:**

1. **Inventory Supabase usage.** DB, Auth, Storage, Realtime, Edge Functions, Vector. Plan replacement for each.
2. **Stand up self-hosted Postgres** (AWS RDS, Neon, Railway, or self-managed on a VPS). Replicate schema.
3. **Migrate DB first.** Use `pg_dump` / `pg_restore` or logical replication for zero-downtime. For apps without Supabase Realtime, this is much of the work.
4. **Replace Auth.** Better Auth, Clerk, or WorkOS depending on requirements. User export from Supabase is supported.
5. **Replace Storage.** S3 (with CloudFront) or similar. Migrate files; update URLs.
6. **Replace Realtime** if used. Depending on pattern: WebSocket service (Pusher, Ably), Postgres LISTEN/NOTIFY, or a real-time framework feature.
7. **Replace Edge Functions.** Next.js API routes, Lambda, or your framework's native server functions.
8. **Cutover, validate, decommission Supabase.**

**Rollback checkpoints:** each component has its own. DB can revert to Supabase via reverse replication until cutover. Auth rollback requires reverse user-data migration. Storage rollback requires file mirror.

**Data migration strategy.**

- DB: logical replication is the safest path; point-in-time snapshot + CDC for zero-downtime.
- Auth: export users including hashed passwords (verify compatibility with target provider's hash scheme).
- Storage: rsync or `aws s3 cp` in chunks; validate checksums.

**Engineer-week cost.**

- DB-only migration: 1-3 weeks.
- Full Supabase exit (DB + Auth + Storage + Realtime): 4-10 weeks.

**Common traps.**

- Treating Supabase as just a Postgres host; underestimating Auth/Storage/Realtime work.
- Forgetting RLS policies (they move with the schema but may reference Supabase-specific functions).
- Underestimating Edge Function replacement if they carry business logic.

---

## Migration 3: Convex to Postgres

**When to do it.** Cross-tenant aggregations, complex reporting, or SQL-style ad-hoc queries have become central. Pricing at scale has become a concern.

**Blast radius.** Convex is not just a DB; it's schema, queries, mutations, reactivity, and scheduled functions. Every layer needs a replacement. This is a medium-to-large migration.

**Phased sequence:**

1. **Map Convex functions to server-side handlers.** Each Convex query/mutation becomes an API route or Server Action.
2. **Design Postgres schema.** Translate Convex tables. Add indexes for the queries the app actually runs.
3. **Stand up Postgres + ORM** (Drizzle recommended for TypeScript Convex teams).
4. **Dual-run.** Mirror writes from Convex to Postgres via a background job; run for 2-4 weeks.
5. **Shadow-read.** Add reads from Postgres in parallel with Convex; compare responses; fix bugs.
6. **Add a reactivity layer.** Convex hooks don't map to anything on Postgres directly; consider TanStack Query with WebSocket invalidation, Supabase Realtime (if staying on Supabase-adjacent), or domain-specific event-driven updates.
7. **Flip reads to Postgres.** Feature by feature.
8. **Stop dual-write.** Decommission Convex.

**Rollback checkpoints:** at step 4 (dual-run) and step 7 (reads flipped). Each is reversible.

**Data migration strategy.**

- Export Convex data via the Convex CLI or Admin API.
- Transform to Postgres-compatible format.
- Load via COPY or equivalent.
- Reactivity: the biggest challenge; plan the real-time layer early, don't leave it for step 6.

**Engineer-week cost.**

- Small Convex app: 6-10 weeks.
- Medium app with reactive UI: 12-20 weeks.
- Large app with scheduled functions and complex reactivity: 20-40 weeks.

**Common traps.**

- Underestimating reactivity replacement. Convex's real-time sync is a key feature; recreating it on Postgres is real work.
- Treating migration as a direct schema port; Convex's data shapes may not be relational-optimal.
- Forgetting scheduled Convex functions; they become cron jobs or workflow steps.

---

## Migration 4: Clerk to Better Auth (or vice versa)

**When to do it.** Clerk to Better Auth: pricing has crossed the threshold; team wants self-host control. Better Auth to Clerk: want polished UI without building it; happy to pay for MAU.

**Blast radius.** User sessions invalidate (if not handled carefully). User passwords may or may not migrate depending on hash compatibility. Session cookie format changes.

**Phased sequence (Clerk to Better Auth):**

1. **Export users from Clerk.** Clerk provides user export including hashed passwords (bcrypt).
2. **Import into Better Auth.** Better Auth supports bcrypt; import users with hashed passwords.
3. **Dual-auth period.** Both providers are live; new registrations go to Better Auth only. Existing users reauthenticate on next login (if password hashing is compatible, login is transparent).
4. **Migrate sessions.** Existing Clerk sessions don't transfer; users log in again.
5. **Update app code.** Auth middleware, session reads, role checks, all switch to Better Auth.
6. **Cutover.** Turn off Clerk. Keep user export as backup for 90 days.

**Rollback checkpoints:**

- During dual-auth: can revert by flipping middleware back to Clerk.
- After sessions invalidate: rollback becomes harder; users already re-authenticated to new provider.

**Data migration strategy.**

- Passwords: verify hash compatibility. Clerk uses bcrypt; Better Auth uses bcrypt. Compatible.
- OAuth-linked accounts: re-link on first login.
- MFA: users may need to re-enroll if MFA implementations differ.

**Engineer-week cost.**

- Small app: 2-3 weeks.
- Medium app with RBAC, organizations, custom claims: 4-8 weeks.
- Large app with complex auth flows: 8-16 weeks.

**Common traps.**

- Forcing users to reset passwords when hash formats are actually compatible.
- Not communicating the migration to users; trust drops when sessions invalidate without notice.
- Forgetting OAuth provider re-authorization.
- Losing user metadata (custom fields, roles) because export/import mapping was incomplete.

---

## Migration 5: Vercel to AWS (ECS / Fargate)

**When to do it.** Cost at scale has surpassed expected AWS cost plus ops. Compliance requires VPC. Long-running workloads fight the serverless model.

**Blast radius.** Deploy pipeline rebuilds. Preview environments need new infra. Edge middleware needs replacement (API Gateway, CloudFront, or drop edge altogether). Secrets management moves to AWS Secrets Manager or Parameter Store.

**Phased sequence:**

1. **Containerize the app.** `Dockerfile` for Next.js / Remix / whatever. Build locally first; verify.
2. **Set up AWS infrastructure.** VPC, subnets, ECS cluster, Fargate service, ALB, CloudFront (if needed), RDS connectivity, Secrets Manager.
3. **Replicate ENV and secrets.** Migrate from Vercel Env Variables to AWS Secrets Manager.
4. **Deploy to AWS in parallel with Vercel.** Use a different subdomain to test.
5. **Replace Vercel-specific features.**
   - Edge Middleware: move to CloudFront Functions or Lambda@Edge, or drop.
   - ISR / on-demand ISR: implement equivalent with Next.js standalone + S3 cache or similar.
   - Image Optimization: self-host (e.g., `next/image` with a loader pointing at Lambda, or a third-party like Imgix/Cloudinary).
6. **Cutover DNS.** Route traffic to AWS; leave Vercel as standby for rollback.
7. **Monitor for 1-2 weeks.** Watch error rates, latency, cost.
8. **Decommission Vercel.**

**Rollback checkpoints:** DNS flip is the main one. Revert DNS to Vercel if AWS is misbehaving.

**Data migration strategy.** N/A for pure compute migration. Database stays where it is, or is migrated separately.

**Engineer-week cost.**

- Simple Next.js app with no edge features: 2-3 weeks.
- App with middleware, ISR, image optimization: 4-8 weeks.
- Complex app with edge-first architecture: 8-16 weeks plus ongoing ops.

**Common traps.**

- Underestimating ops learning curve; AWS is not Vercel.
- Missing Vercel-native features (preview URLs per PR, team management, analytics) that CI/CD must recreate.
- Forgetting image optimization; it is a big DX and performance loss.
- Under-provisioning Fargate; ECS auto-scaling tuning takes weeks of real-world traffic.

---

## Migration 6: Prisma to Drizzle

**When to do it.** SQL ergonomics matter more than schema DSL ergonomics; team wants first-class query transparency; performance tuning on complex queries is getting hard.

**Blast radius.** Every data access site gets rewritten. Migration files are re-authored in Drizzle's format. Tests that mocked Prisma now mock Drizzle or use integration tests.

**Phased sequence:**

1. **Set up Drizzle alongside Prisma.** Drizzle connects to the same Postgres DB.
2. **Re-author the schema in Drizzle.** Keep Prisma for runtime; Drizzle schema as source of truth for types going forward.
3. **Migrate data access site-by-site.** Start with leaf functions; move inward.
4. **Migrate migration tooling.** `drizzle-kit` replaces `prisma migrate`.
5. **Delete Prisma.** After all sites migrated.

**Rollback checkpoints:** each migrated site can be reverted individually.

**Data migration strategy.** N/A; DB schema is shared.

**Engineer-week cost.**

- Small app: 2-3 weeks.
- Medium app with many query sites: 4-8 weeks.
- Large app: 6-12 weeks.

**Common traps.**

- Migrating the schema without updating all data-access code; you end up with both ORMs live.
- Skipping the leaf-first order; bugs concentrate at the boundaries.
- Forgetting Prisma-specific features (relationLoadStrategy, preview features) that need Drizzle equivalents or raw SQL.

---

## Migration 7: REST/GraphQL to tRPC

**When to do it.** Monolithic TypeScript app where the backend is owned by the same team, wants type-safe API calls without GraphQL schema duplication.

**Blast radius.** Public API consumers (if any) lose tRPC-typed access; they need REST stays up. Mobile app (if any) needs a REST layer or a tRPC mobile client.

**Phased sequence:**

1. **Set up tRPC alongside the existing REST or GraphQL API.**
2. **Migrate internal (frontend-to-backend) calls to tRPC** incrementally.
3. **Keep REST/GraphQL for external API consumers.**
4. **Possibly delete the internal-only REST/GraphQL routes** after frontend migration complete.

**Rollback checkpoints:** each route can be reverted.

**Engineer-week cost.**

- Small app: 1-2 weeks.
- Medium app with shared auth/validation: 3-6 weeks.
- Large app: 6-12 weeks.

**Common traps.**

- Trying to migrate a public API to tRPC; tRPC is not a public API protocol.
- Forgetting request validation; Zod or Valibot at the tRPC boundary.
- Not moving auth middleware cleanly; tRPC has its own middleware model.

---

## Migration 8: MUI to shadcn/ui

**When to do it.** Want to escape Material Design aesthetic; want to own your component code; want to reduce bundle size.

**Blast radius.** Every component that used MUI gets re-authored. Theme switches from MUI's system to Tailwind + CSS variables. Responsive breakpoints may differ.

**Phased sequence:**

1. **Install shadcn/ui.** Configure Tailwind, design tokens.
2. **Design the token set.** Colors, radius, typography; map from current MUI theme.
3. **Replace components leaf-up.** Buttons, inputs, cards first; complex components (DataGrid, Autocomplete) last.
4. **Rewrite layout system.** Tailwind for layout; CSS Grid / Flexbox patterns.
5. **Delete MUI.** Package and all imports.

**Rollback checkpoints:** each component replacement is individual.

**Engineer-week cost.**

- Small app: 2-4 weeks.
- Medium app: 4-10 weeks.
- Large app with many unique components: 8-20 weeks.

**Common traps.**

- Trying to preserve the exact same visual design; MUI and shadcn will look subtly different, and insisting on pixel parity is a trap.
- Forgetting accessibility; MUI's a11y is already good; Radix (via shadcn) is also good, but custom work may regress.
- Underestimating DataGrid-equivalent work; TanStack Table is the shadcn-adjacent path but takes real work.

---

## Migration 9: Firebase Auth to Clerk (or Better Auth)

**When to do it.** Moving off Firebase overall; wants polished auth UI (Clerk) or self-host (Better Auth). Firebase Auth features (phone, anonymous, etc.) are not deal-breakers or have equivalents.

**Blast radius.** All users must re-authenticate (sessions don't transfer). OAuth providers may need re-authorization. Password hashes may or may not transfer; verify at both ends.

**Phased sequence:**

1. **Export users from Firebase Auth.** Includes hashed passwords for users who signed up with email/password (Firebase uses scrypt or bcrypt depending on settings).
2. **Transform hashes.** Firebase scrypt hashes can be imported into Clerk (with custom import logic) or Better Auth (verify compatibility).
3. **Import users into new provider.**
4. **Dual-auth period.** New signups on new provider; existing users are created on new provider with old hashes.
5. **Migrate client code.** Firebase Auth SDK calls to new provider SDK.
6. **Cutover.** Users sign in and are authenticated via new provider.
7. **Decommission Firebase Auth** after grace period.

**Rollback checkpoints:** during dual-auth, rollback is a code change. After full cutover, rollback is hard (new users are on new provider only).

**Data migration strategy.**

- Password hashes: verify the target provider supports importing Firebase's specific hash scheme. If not, force password reset on migration.
- Phone auth: migrate verified phone numbers; users re-verify on first login.
- OAuth-linked accounts: re-link on first login.

**Engineer-week cost.**

- Small app: 2-3 weeks.
- Medium app: 4-8 weeks.
- Large app with custom claims, custom OAuth providers: 8-16 weeks.

**Common traps.**

- Forcing password reset unnecessarily; verify hash compatibility first.
- Losing custom user claims (Firebase custom claims don't map 1:1 to Clerk/Better Auth metadata).
- Forgetting server-side Firebase Admin SDK usage; it must also be replaced.

---

## Migration 10: Heroku to anywhere

**When to do it.** Cost concerns, feature gaps, shutdowns, or compliance needs.

**Blast radius.** Depends on Heroku features used: dynos, Postgres, Redis, workers, cron (Heroku Scheduler), add-ons.

**Phased sequence (target: Railway, as the closest DX analog):**

1. **Provision Railway** environment.
2. **Move Postgres.** `pg_dump` / `pg_restore` or logical replication for zero-downtime.
3. **Move Redis.** Snapshot + restore.
4. **Move app code.** Railway deploys from GitHub.
5. **Recreate Scheduler.** Railway cron or similar.
6. **Recreate add-ons.** Papertrail -> Axiom or similar. Heroku Connect -> manual replication. Mailgun/SendGrid stays or moves.
7. **Cutover DNS.**
8. **Decommission Heroku.**

**Rollback checkpoints:** DNS cutover is the main one.

**Data migration strategy.**

- Postgres: standard `pg_dump` / `pg_restore`, or logical replication for near-zero downtime.
- Redis: `SAVE` + restore, or `BGSAVE` + dump/restore.

**Engineer-week cost.**

- Simple Heroku app: 1-2 weeks.
- App with many add-ons: 3-6 weeks.
- Complex app with Heroku Connect or Private Spaces: 6-12 weeks.

**Common traps.**

- Forgetting buildpacks; Railway/Render auto-detect is usually fine, but custom buildpacks need attention.
- Free-tier dyno assumptions that don't map (always-on requirements on destination).
- Heroku Scheduler jobs forgotten (Railway has its own cron model).
- Environment variable transfer; Heroku config vars don't always map cleanly.

---

## Migration 11: Monolith to microservices

**When to do it.** Rarely, for teams under 15 engineers. More often, for teams that have outgrown a monolith at 20+ engineers with genuine ownership boundaries.

**Blast radius.** Massive. This is not a migration; it is an architectural transformation. Expect 6+ months.

**Phased sequence:**

1. **Verify the need.** A 5-engineer team asking for microservices is usually asking for the wrong thing.
2. **Identify service boundaries.** By domain, by team, by rate of change.
3. **Extract one service first.** Usually the least-entangled. Use strangler-fig pattern.
4. **Establish service infrastructure.** Service discovery, API gateway, distributed tracing, cross-service auth, shared CI/CD patterns.
5. **Extract additional services** one at a time. Each takes 4-16 weeks.
6. **Retire the monolith** (or accept it as a service itself).

**Rollback checkpoints:** each service extraction is individual and can be reverted.

**Engineer-week cost.**

- Extracting one service: 4-16 weeks.
- Full monolith decomposition into 5-10 services: 6-24 months.

**Common traps.**

- Doing it because "everyone else is." Microservices are a scale solution; below scale, they add complexity without benefit.
- Splitting data while keeping cross-service transactions. Either commit to eventual consistency or don't split.
- Underestimating ops cost. Microservices are an ops multiplier.
- Losing the monolith's transactional simplicity before replacing it with a sufficient alternative.

**Strong note:** Stack Ready recommends against this migration for teams under 15 engineers except in specific situations where domain boundaries are extremely clean and the ceiling is genuinely reached. In most cases, the "monolith" narrative is misdiagnosed; the actual problem is code organization within the monolith.

---

## Migration 12: Self-hosted to managed (Postgres)

**When to do it.** Ops burden exceeds savings. Backups, PITR, failover, and upgrades are taking meaningful engineering time.

**Blast radius.** Minimal, done carefully. Connection strings change. Some extensions may differ.

**Phased sequence (target: AWS RDS, Neon, or Supabase):**

1. **Select destination.** Check Postgres version support, extension support, pricing tier.
2. **Set up target.** Match schema, users, extensions.
3. **Replicate.** Logical replication from source to target. Run for hours to days.
4. **Cutover.** Stop writes to source (brief maintenance window), wait for replication to catch up, redirect app to target.
5. **Decommission source** after confidence interval.

**Rollback checkpoints:** pre-cutover, revert is free. Post-cutover, rollback requires replaying writes to source.

**Data migration strategy.**

- Logical replication (pglogical or built-in): near-zero downtime.
- `pg_dump` / `pg_restore`: simple, but requires downtime for the dump.

**Engineer-week cost.**

- 1-3 weeks for a routine DB migration.
- 3-6 weeks if the app has many extensions, replicas, or complex auth setup.

**Common traps.**

- Missing extensions on the destination (pg_cron, pg_stat_statements on some tiers).
- Connection pool sizing; managed DBs often have lower connection limits than self-hosted.
- Cost surprises; managed costs more than bare VPS but saves engineer time.

---

## General migration principles

- **Prefer additive to destructive.** Add the new before removing the old, even if it is redundant for a few weeks.
- **Keep a rollback live at every phase.** If you cannot revert, you cannot safely advance.
- **Validate before cutover.** Shadow reads, reconciliation logs, checksum checks.
- **Communicate with users.** Sessions invalidating, API contracts changing, third-party re-authorizations all require notice.
- **Do not migrate and ship new features simultaneously.** Pick one. Attempting both doubles the risk.
- **Honest engineer-week estimates are compounding gifts.** Under-estimating the migration tanks trust and wastes the org's time.

## When a migration is the wrong answer

Sometimes the user asks "how do I move off X" and the right answer is "don't, for now." Signs:

- The team is 2 engineers and the migration is 3+ engineer-months.
- The pain point is a specific feature that can be worked around.
- The destination stack is being picked because it is new, not because it fits better.
- There are active product commitments that will suffer from the migration distraction.

Stack Ready should surface the "stay" option explicitly when it's the honest answer.
