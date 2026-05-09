# Auth & RBAC

Authentication answers "who are you." Authorization answers "what are you allowed to do." A dashboard needs both, working, on day one. This file is the rules for both layers.

The single most important principle: **enforce on the server, reflect on the client.** The client never decides whether something is allowed — the client only decides whether to *show* the option. The server is the source of truth for every permission decision. Treat the client as untrusted, because it is.

**Canonical scope:** authentication mechanisms (passkeys, magic links, OAuth, sessions), RBAC role design, multi-tenant auth, impersonation. **See also:** `login-and-auth-pages.md` for login and signup UX, `security-deep-dive.md` for session hardening and incident response.

## Quick decision: which auth method?

```
What kind of dashboard?
│
├── Internal / corporate (users have company email)
│   ├── Company uses SSO (Okta, Entra, Google Workspace)?
│   │   YES → OIDC/SAML with the existing IdP. No local passwords.
│   │   NO  → Magic link (lowest friction) or email+password with invite-only
│   │
│   └── Fewer than 20 users, low sensitivity?
│       YES → Magic link. No passwords to manage.
│       NO  → Email+password + enforce MFA
│
├── SaaS product (public sign-up)
│   ├── Consumer-facing (broad audience)?
│   │   YES → Social login (Google/GitHub) + email+password fallback
│   │         + passkey enrollment after first login
│   │   NO  → Email+password + optional social login
│   │         + MFA for admin roles
│   │
│   └── Enterprise tier exists?
│       YES → Add SAML/OIDC SSO for enterprise orgs
│
├── Sensitive data (healthcare, finance, legal)?
│   └── Email+password + mandatory MFA + session timeout ≤ 12h
│       + passkey offered as upgrade
│
└── Default when unsure
    └── Email+password (invite-only) + passkey enrollment in settings
```

**Sessions vs. JWTs:** Use sessions unless you have multiple services that need stateless token verification. Sessions are revocable, simpler, and the right default for single-app dashboards. See "Sessions vs. JWTs" below for the full comparison.

## Authentication

### What "real auth" means

Real auth has these properties. If any are missing, the auth isn't real and the dashboard isn't done.

1. There is a login page that rejects unknown users and wrong passwords.
2. Passwords are hashed with `argon2id` or `bcrypt` (cost ≥ 12). Never `sha256`, `md5`, plaintext, or "we'll add hashing later."
3. Successful login establishes a session — either an HTTP-only cookie holding a session ID, or an HTTP-only cookie holding a signed JWT. Not localStorage, not query strings, not URL fragments.
4. The session cookie is `httpOnly`, `sameSite=lax` (or `strict` if no cross-site flows), and `secure` in production.
5. Every protected route is gated by a server-side check that runs before the route handler — middleware, decorator, or framework hook.
6. Logout invalidates the session on the server (delete the row, revoke the token, clear the cookie). Never just clear the cookie client-side and hope.
7. Sessions expire — both an absolute lifetime (30 days max for "remember me," 12–24 hours for sensitive dashboards) and an idle timeout.

### Picking an auth library

Do not roll your own auth in 2026. The libraries below handle the details (hashing, session storage, CSRF, refresh, OAuth) so you don't have to.

- **Next.js / TypeScript** — Auth.js v5 (formerly NextAuth), Better Auth, Clerk, Stack Auth
- **React Router v7 / TypeScript** — Auth.js, Better Auth, remix-auth, Clerk
- **SvelteKit** — Auth.js for SvelteKit, Better Auth, Clerk
- **Nuxt / Vue** — Sidebase nuxt-auth, Better Auth

Note: Lucia was deprecated in January 2025. If you see it recommended elsewhere, use Better Auth or Auth.js instead. The Lucia author's session management guide remains useful as a reference for rolling your own.
- **Rails** — Devise, Rodauth
- **Django** — django-allauth, dj-rest-auth
- **Laravel** — Breeze, Fortify, Sanctum
- **Phoenix** — phx_gen_auth (built into the generators)
- **Spring Boot** — Spring Security
- **Go** — auth0-go, ory/kratos, custom with `crypto/rand` + `argon2`

If the user already has an identity provider (Okta, Auth0, Cognito, Microsoft Entra, Google Workspace, etc.), use it via OIDC instead of building local accounts. This is the right answer for any internal corporate dashboard.

### Email + password flow

The minimum-viable login flow:

1. User visits any protected route → server middleware checks for a valid session → no session → redirect to `/login?next=<original_path>`.
2. User submits the login form. Server validates: email exists, password hash matches.
3. Server creates a session row (or signs a JWT), sets the cookie, redirects to `next` (or `/`).
4. Subsequent requests include the cookie automatically. Middleware looks up the session, attaches `currentUser` to the request, calls the handler.
5. Logout: POST to `/logout` (POST, not GET — GET logouts can be triggered by `<img src>`). Server deletes the session row, clears the cookie, redirects to `/login`.

Things to add once the basics work:

- **Rate limiting on the login endpoint** — 5 attempts per email per 15 minutes is reasonable. Without this, the login endpoint is a credential-stuffing buffet.
- **Generic error messages** — "Invalid email or password," not "no user with that email." Don't help attackers enumerate accounts.
- **Password reset flow** — request token by email, set new password with token, single-use token, 1-hour expiry.
- **Email verification** — for self-service sign-up dashboards. For invited-user dashboards, the invite link is the verification.
- **MFA / TOTP** — once the dashboard handles anything sensitive. `otplib`, `pyotp`, `rotp`, `speakeasy`. Show a QR code on enrollment, ask for a 6-digit code on subsequent logins.

### Passkey / WebAuthn (passwordless)

Passkeys have gone mainstream — 15 billion accounts support them. For dashboards built in 2026, passkeys should be offered alongside email+password, not as an afterthought.

The flow: user enters email (identifier-first pattern) > system checks for a registered passkey > if found, prompt biometric/device auth > session created. No password involved. If no passkey, fall back to password.

Enrollment: after login, prompt to register a passkey from the security settings page. Store the credential ID and public key. Libraries: `@simplewebauthn/server` + `@simplewebauthn/browser` (TypeScript), `py-webauthn` (Python).

### Magic link authentication

Common for internal dashboards and low-friction SaaS. User enters email > receives a link > clicks it > session created. No password needed. The link is single-use, expires in 15-60 minutes, and contains a signed token.

Use when: the dashboard doesn't warrant users remembering a password, or when the user base is small and you want minimal friction. Libraries: Auth.js + Resend, Better Auth + any email provider.

### Social login (Google / GitHub / Microsoft)

Table-stakes for customer-facing SaaS dashboards. The pattern: show "Continue with Google" + "Continue with GitHub" buttons above the email+password form. On click, redirect to the provider's OAuth flow (covered in `api-and-integrations.md`). On callback, create or link the user account.

Gotchas: handle the case where a user signs up with email+password and later tries Google with the same email (account linking). Handle the case where a user uses Google on desktop and email+password on mobile (same account, different auth methods).

### Sign-up vs. invite-only

Most dashboards are not public products. Default to **invite-only**: an admin creates the user (or sends an invite link with a one-time token), and the invitee sets their password on first use. Self-service sign-up is for SaaS products with a public landing page. Don't add it just because you have a "Sign up" link in the design — it's a whole separate flow with its own security surface (email verification, anti-abuse, plan assignment).

### Sessions vs. JWTs (the short version)

- **Sessions (server-side store)** — simpler, revocable, slightly more DB load. Default choice for anything single-region or anything where revoke-on-logout matters.
- **JWTs** — stateless, scales horizontally, hard to revoke before expiry. Use when you have many services that need to verify identity without hitting a central session store. Always combine with short expiry (15 min) + refresh tokens.

For most dashboards: **use sessions**. JWTs are over-recommended. Don't pick them unless you have a specific reason.

### What gets stored where

| Data | Where |
|---|---|
| Session ID / token | HTTP-only cookie |
| User ID | Inside the session row, not the cookie |
| User profile (name, email) | DB, fetched per request via the session |
| Permissions / role | DB, fetched per request — never trust client-supplied roles |
| CSRF token | Separate cookie or rendered into the page; verified on every state-changing request |
| Auth state in the SPA | Never. The server tells the client who the user is on each render. Don't shadow it in Redux. |

## Authorization (RBAC)

RBAC = Role-Based Access Control. Users have roles, roles have permissions, permissions are checked on every action. Implementing it well is the difference between "the dashboard works" and "anyone can delete anything if they know the URL."

### The three-layer model

Every dashboard with more than one user type needs all three layers:

1. **Roles** — named groups of users (`admin`, `manager`, `member`, `viewer`)
2. **Permissions** — the atomic actions (`users:read`, `users:write`, `users:delete`, `billing:read`, `billing:write`)
3. **The matrix** — which roles have which permissions

Don't check roles directly in code (`if (user.role === 'admin')`). Check permissions (`if (user.can('users:delete'))`). Roles are an organizational concept that changes over time; permissions are stable. Code that checks roles directly has to be rewritten every time the role list changes.

### Designing roles

Start with **3–4 roles**. Resist the urge to add more. Common patterns:

- **2 roles**: `admin`, `member`. Smallest viable RBAC. Works for tiny teams.
- **3 roles**: `admin`, `manager`, `member`. Manager can do most things but not billing/team management.
- **4 roles**: `owner`, `admin`, `member`, `viewer`. Owner can transfer ownership and delete the org. Viewer is read-only.
- **5+ roles**: only when the domain genuinely demands it (hospital systems, legal review chains, regulated finance). For most dashboards, 5+ roles is a smell.

The 80/20 test: if 80% of users in a role need 80% of the role's permissions, the role is well-sized. If a role exists for one person, it's not a role — it's a hack.

### The permission matrix

Write the matrix down before coding. It becomes the source of truth.

```
                        owner  admin  manager  member  viewer
─────────────────────────────────────────────────────────────
users:read                ✓      ✓       ✓        ✓       ✓
users:invite              ✓      ✓       ✓
users:edit                ✓      ✓
users:delete              ✓      ✓
roles:assign              ✓      ✓
billing:read              ✓      ✓                ✓
billing:edit              ✓      ✓
org:settings              ✓      ✓
org:transfer              ✓
org:delete                ✓
projects:read             ✓      ✓       ✓        ✓       ✓
projects:create           ✓      ✓       ✓
projects:edit             ✓      ✓       ✓        ✓
projects:delete           ✓      ✓       ✓
audit_log:read            ✓      ✓       ✓
```

Encode this once in the codebase as data, not as scattered conditionals. The simplest encoding:

```ts
// permissions.ts
export const PERMISSIONS = {
  owner: new Set([
    'users:read', 'users:invite', 'users:edit', 'users:delete',
    'roles:assign', 'billing:read', 'billing:edit',
    'org:settings', 'org:transfer', 'org:delete',
    'projects:read', 'projects:create', 'projects:edit', 'projects:delete',
    'audit_log:read',
  ]),
  admin: new Set([/* … */]),
  manager: new Set([/* … */]),
  member: new Set([/* … */]),
  viewer: new Set(['users:read', 'billing:read', 'projects:read']),
} as const;

export function can(role: Role, permission: Permission): boolean {
  return PERMISSIONS[role].has(permission);
}
```

Now every check, server-side or client-side, calls `can(user.role, 'projects:delete')`. One source of truth. Easy to test. Easy to change.

### Server-side enforcement

The server enforces permissions. Always. On every mutation. There are two enforcement patterns:

**1. Middleware per route** — wrap each protected route with a permission check.

```ts
// Express-style
router.delete('/projects/:id',
  requireAuth,
  requirePermission('projects:delete'),
  async (req, res) => {
    await deleteProject(req.params.id);
    res.json({ ok: true });
  }
);
```

**2. Service-layer check** — the service function takes the current user and checks before acting.

```ts
async function deleteProject(currentUser: User, projectId: string) {
  if (!can(currentUser.role, 'projects:delete')) {
    throw new ForbiddenError('You do not have permission to delete projects');
  }
  // also: does this project belong to the user's org?
  const project = await db.project.findUnique({ where: { id: projectId } });
  if (!project || project.orgId !== currentUser.orgId) {
    throw new NotFoundError('Project not found');
  }
  await db.project.delete({ where: { id: projectId } });
  await audit.log({ actor: currentUser.id, action: 'project.delete', target: projectId });
}
```

The service-layer pattern is preferred because it works regardless of how the action was triggered (HTTP, background job, GraphQL, RPC, CLI). Middleware-only enforcement breaks the moment you add a second entry point.

### Multi-tenant: scope every query by org

Almost every dashboard with multiple users is multi-tenant — there are organizations (or teams, workspaces, accounts), and a user belongs to one. Every query and every mutation must include the org filter. **Forgetting this once is the most common dashboard data leak.**

Enforce it structurally so it can't be forgotten:

- Use a query helper that automatically scopes by `orgId` (e.g., a Prisma extension, Drizzle wrapper, or scoped repository class)
- In Postgres, consider RLS (Row-Level Security) policies that enforce `org_id = current_setting('app.current_org_id')` at the database level — defense in depth
- Code review every new query: does it scope by org? If not, why not?

The check pattern:

```ts
const project = await db.project.findFirst({
  where: { id: projectId, orgId: currentUser.orgId }, // ← org filter every time
});
if (!project) throw new NotFoundError(); // 404, not 403 — don't leak existence
```

Note: when a user *can't* see a resource because of org scoping, return 404, not 403. 403 confirms the resource exists. 404 doesn't.

### Client-side reflection

The client should hide actions a user can't perform — but only as UX courtesy, never as security. Pattern:

```tsx
// Make `can` available everywhere via context or hook
const { can } = useCurrentUser();

// Use it to gate UI
{can('projects:delete') && (
  <button onClick={() => deleteProject(project.id)}>Delete</button>
)}

// Or disable with explanation
<button
  disabled={!can('projects:delete')}
  title={!can('projects:delete') ? 'Only admins can delete projects' : undefined}
>
  Delete
</button>
```

Disabling-with-explanation is often kinder than hiding. A user who sees a disabled button knows the feature exists but isn't theirs; a user who sees nothing wonders if they're missing an update.

### Resource ownership & relationship-based access

RBAC alone covers "can this role do this action?" but not "can this user do this action *to this resource*?" For that you need ownership/relationship checks layered on top.

Examples:
- A user can edit *their own* profile but not other users' profiles, regardless of role
- A project member can edit projects they belong to but not other projects in the same org
- A document owner can share their document but a viewer can't

Encode these as predicates in the service layer:

```ts
async function editProject(user: User, projectId: string, changes: ProjectUpdate) {
  const project = await db.project.findFirst({
    where: { id: projectId, orgId: user.orgId },
    include: { members: true },
  });
  if (!project) throw new NotFoundError();

  const isMember = project.members.some(m => m.userId === user.id);
  const hasGlobalEdit = can(user.role, 'projects:edit:any');
  const hasOwnEdit = can(user.role, 'projects:edit:own') && isMember;

  if (!hasGlobalEdit && !hasOwnEdit) {
    throw new ForbiddenError();
  }
  // proceed
}
```

For very complex authorization (relationships across multiple entities, document hierarchies, sharing), reach for a policy engine: Oso, OpenFGA, Cedar, Casbin. Don't reach for them on day one — they're worth it once the rules outgrow predicates in code.

## User management

Every dashboard needs at least minimal user management. The pages:

### `/users` — list

Table of users in the current org with: avatar, name, email, role, last active, status (active / invited / disabled), and per-row actions (edit role, resend invite, disable, delete).

### `/users/invite` — invite

Form: email + role. Sends an email with a one-time invite link. The link goes to `/accept-invite?token=…` which lets the invitee set a name and password and creates the user.

### `/users/:id` — detail

Shows the user's profile, role, last login, audit trail of recent actions. Admin can change the role here. The user themselves goes to `/settings/profile` for their own profile (different page, simpler UI).

### `/settings/profile` — self-service

The currently logged-in user editing their own info. This page looks simple but has more depth than most builders expect. Build it as a sectioned form, not a single flat list of fields.

**Identity section:**
- **Display name** — text input, saved on blur or explicit save.
- **Email** — changing email requires verification of the new address before the switch takes effect. Send a confirmation link to the new email; only swap on click. Show "pending verification: newemail@..." until confirmed. Never change email without verification — it's an account takeover vector.
- **Avatar** — upload with client-side crop/resize (circle preview at the size it'll appear in the UI). Serve at the display size, not the original 4MB upload. Show initials as fallback when no avatar is set.
- **Timezone** — dropdown of IANA timezone names. Default to browser-detected. Used for displaying dates throughout the dashboard. Store as `timezone` on the user record, apply server-side when rendering timestamps.
- **Language / locale** — if the dashboard supports i18n. Affects date formats, number formats, and UI language.

**Security section:**
- **Change password** — require the current password before setting a new one. Never let a session token alone authorize a password change. Show strength indicator. Validate against breached password lists (HaveIBeenPwned API) if the dashboard handles sensitive data.
- **Active sessions** — list all active sessions with: device/browser, IP address (or rough location), last active time, and "this device" indicator. A "Sign out all other devices" button that revokes every session except the current one. This is the first thing a user does when they suspect compromise.
- **MFA / two-factor** — enrollment flow: show QR code for TOTP app, verify with a 6-digit code, show backup codes (one-time, store hashed). Unenrollment requires the current password or a backup code. Show MFA status prominently.
- **Login history** — last 10-20 logins with timestamp, IP, device, and success/failure. Helps users spot suspicious access.

**Preferences section:**
- **Theme** — light / dark / system. Apply immediately on toggle (optimistic). Persist to the user record so it follows across devices.
- **Notification preferences** — a matrix of notification types x channels (email, in-app, push if applicable). Each row is a notification type ("New comment on my task," "Weekly digest," "Security alert"), each column is a channel. Users toggle individually. Security notifications (login from new device, password changed) should be non-disableable.
- **Density** — comfortable / compact for tables and lists, if the dashboard supports it.

**Connected accounts section (if applicable):**
- **OAuth / SSO links** — show connected providers (Google, GitHub, Microsoft) with "Connect" / "Disconnect" buttons. Prevent disconnecting the last auth method (if they have no password and disconnect their only OAuth provider, they're locked out).
- **API keys** — generate, name, copy (shown once), revoke. Show last-used date per key. Never show the full key after creation — only the last 4 characters.

**Danger zone:**
- **Export my data** — GDPR right of access. Generate a zip of the user's data (profile, activity, content they created). Background job with email notification when ready.
- **Delete my account** — requires typing a confirmation word, requires the current password, and shows the consequences in concrete terms ("This will delete your profile and remove you from 3 organizations. Your content will be reassigned to the org admin."). Implement as soft-delete with a 30-day grace period before hard deletion. Send a confirmation email with an "undo" link.

**What NOT to put on the profile page:**
- Org settings, billing, team management — those belong on separate org-level settings pages. The profile page is personal.
- Other users' information — the profile page is about "me," not about managing others.
- Feature flags or developer settings — those go in a separate admin/developer page.

### Disable vs. delete

Don't hard-delete users. Disable them (set `disabled_at` timestamp). Their audit trail and historical references stay intact. Hard-delete is only for GDPR / right-to-be-forgotten requests, and even then it's usually anonymization, not deletion.

## Account impersonation (support access)

Admin-as-user is critical for customer support. The pattern:

1. Admin clicks "Login as [user]" on the user management page.
2. Server creates a time-limited session (30-60 minutes max) as that user, with a flag marking it as impersonated.
3. The UI shows a persistent banner: "You are impersonating Alice. [Return to admin]"
4. All actions are logged to the audit trail as "admin (impersonating alice)" — both the admin and the user are recorded.
5. Impersonating sessions cannot: change the user's password, modify billing, delete the account, or access other impersonation features.
6. Clicking "Return to admin" destroys the impersonation session and restores the admin's original session.

## Groups

If the dashboard has > ~50 users, RBAC alone gets unwieldy and groups become useful. A group is a named set of users; permissions can be granted to groups instead of individuals.

```
Group: "Customer Support"
  Members: alice@, bob@, carol@
  Permissions: tickets:read, tickets:respond, customers:read
```

Now adding a new support agent is one click (add to the group) instead of remembering to grant five permissions. Groups become essential at organizational scale.

For smaller dashboards, skip groups. They're overhead until they're not.

## Audit logging

Every mutation should write an audit log entry. This is non-negotiable for any dashboard handling real data. The schema is roughly:

```
audit_log:
  id           uuid
  actor_id     fk to users (the person who did it)
  actor_email  string (denormalized for readability)
  action       string ("project.create", "user.role.change", "billing.payment_method.update")
  target_type  string ("project", "user", "payment_method")
  target_id    uuid (the affected resource)
  before       jsonb (state before, optional)
  after        jsonb (state after)
  ip_address   string
  user_agent   string
  org_id       fk to orgs
  created_at   timestamp
```

Write to it from the service layer, after the mutation succeeds. Never block the user-facing mutation on the audit write — if audit fails, log the failure, alert, but don't fail the user's action (or do, depending on compliance needs — pick a policy and document it).

Show the audit log in the dashboard at `/audit-log`. Filter by actor, action type, target, date range. The audit log is one of the most-used pages for any admin investigating "who did that?"

Common gotchas:
- Don't store passwords, tokens, or other secrets in `before`/`after` — redact them
- Use a structured `action` taxonomy, not free-text. `action: "user.role.change"` not `action: "Changed Bob's role to admin"`. The free-text version goes in a derived `description` field.
- Make the audit log append-only. No edits, no deletes from the application.

## What to avoid

- **Storing passwords reversibly.** Hash them. Always. The fact that the user "wants to recover their password" is what reset flows are for.
- **JWTs in localStorage.** Vulnerable to XSS. Use HTTP-only cookies.
- **Permission checks only on the client.** Trivially bypassed by hitting the API directly.
- **Role checks in routes (`if user.role === 'admin'`) instead of permission checks.** Brittle. Refactor when roles change.
- **Forgetting org scoping on a query.** Causes data leaks across tenants. Make scoping structural so it can't be forgotten.
- **Returning 403 when 404 would do.** Leaks resource existence.
- **Verbose login error messages.** "User not found" → enumeration. Use "Invalid email or password."
- **No rate limiting on login.** Free credential stuffing.
- **Same session lifetime for "remember me" and not.** "Remember me" is 30 days; default should be hours.
- **Trusting `X-User-Id` headers from the client.** The user is the session, not the header.
- **Audit logs that anyone can edit or delete.** Append-only. Restricted access.
- **A hidden "super admin" role that bypasses checks.** When (not if) it leaks, it's catastrophic. Use a documented break-glass account with separate auth and short-lived sessions.
