# Settings & Configuration

This file covers how to architect the settings layer of a dashboard — the hierarchy of user, org, and system settings, how to store them, how to build the UI, and how to handle the configuration lifecycle. The skill already says "a settings page that actually saves" is required. This file covers how to make it real.

## Quick decision: settings architecture

**Default: use the hybrid approach.** Typed columns for security-critical settings, JSONB for display preferences.

```
What kind of setting?               → Storage         → Save pattern
─────────────────────────────────────────────────────────────────────
Queried in middleware/auth           → Typed column    → Explicit save
Security policy (MFA, password)      → Typed column    → Explicit save
Display preference (theme, density)  → JSONB column    → Auto-save on change
Notification toggle                  → JSONB column    → Auto-save on change
Profile fields (name, email, avatar) → Typed columns   → Explicit save
Org branding (logo, colors)          → JSONB column    → Explicit save
System-wide (rate limits, flags)     → Key-value table → Explicit save (admin only)
```

**Auto-save vs. explicit save rule:** If the effect is instantly visible and easily reversible (theme toggle, density), auto-save. If it involves text input, affects other users, or has side effects (profile info, security policies), require a Save button. Never mix both patterns in the same form section.

---

## Settings hierarchy

### Three scopes

Every non-trivial dashboard has settings at three levels:

**User-level** (personal preferences, no impact on others):
- Theme, density, locale, timezone
- Notification preferences (per-channel, per-type)
- Default views (table columns, sort order, dashboard layout)
- Keyboard shortcuts, accessibility preferences

**Org/workspace-level** (affect all members, require org admin):
- Branding (logo, favicon, brand color, custom domain)
- Security policies (password requirements, MFA enforcement, session timeout, IP allowlist, SSO)
- Team management (invite flow, default role, auto-join rules)
- Billing (plan, payment method, invoices)
- Integrations (connected services, API keys, webhooks)
- Data policies (retention, export, deletion)

**System/admin-level** (affect all orgs, require super admin):
- Feature flags (global, per-org, per-plan)
- Rate limits (global defaults, per-org overrides)
- Maintenance mode
- File upload limits, allowed types
- Default session timeout, maximum timeout
- System health thresholds

### How scopes interact

Resolution order: **system default < plan-level default < org override < user override.**

But higher scopes can *constrain* lower scopes:

| Mode | Behavior | Example |
|---|---|---|
| **Default with override** | Higher scope provides default, lower can change freely | System default theme "light," user picks "dark" |
| **Constrained override** | Higher scope sets floor/ceiling | System minimum password length 8, org can raise to 12 but not lower to 6 |
| **Forced (no override)** | Higher scope locks the value | Org enforces MFA, users cannot disable |

When a setting is locked by a higher scope, show it read-only with an explanation: "This setting is managed by your organization."

### Who can see and edit

```
System settings:  visible to super admins only
Org settings:     visible to org admins + super admins
User settings:    visible to the user + org admins (for audit)
```

Org admins don't edit individual user settings directly — they set org-level locks that cascade.

---

## Settings data model

### Four strategies

| Strategy | Pros | Cons | Best for |
|---|---|---|---|
| **Key-value table** | Infinitely flexible, zero migration for new settings | No type safety, hard to query | System settings loaded on startup, plugin config |
| **Typed columns** | Type-safe, fast queries, DB constraints | Migration for every new setting, wide tables | Critical settings queried in middleware (security, auth) |
| **JSONB column** | Flexible + queryable, no migration | No schema enforcement at DB level | User preferences, branding, display settings |
| **Hybrid** (recommended) | Best of each | Slightly more complex | Production dashboards |

### Hybrid approach (recommended)

```sql
-- Critical settings as typed columns (queried in auth/middleware)
ALTER TABLE users ADD COLUMN locale VARCHAR(10) DEFAULT 'en';
ALTER TABLE users ADD COLUMN timezone VARCHAR(50) DEFAULT 'UTC';

-- Extensible preferences as JSONB
ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}';

-- Org security as typed columns
ALTER TABLE organizations ADD COLUMN enforce_mfa BOOLEAN DEFAULT false;
ALTER TABLE organizations ADD COLUMN session_timeout INTEGER DEFAULT 720;
ALTER TABLE organizations ADD COLUMN password_min_length INTEGER DEFAULT 8;

-- Org branding as JSONB
ALTER TABLE organizations ADD COLUMN branding JSONB DEFAULT '{}';

-- System settings as key-value (loaded on startup)
CREATE TABLE system_settings (
  key         VARCHAR(255) PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  updated_by  UUID REFERENCES users(id)
);
```

**Decision rule:** typed column if queried in middleware, needs DB constraints, or is security-critical. JSONB if it's a display preference, changes frequently, or new settings are added regularly. Key-value for system settings loaded once on startup.

### Default value resolution

```
Hardcoded app default (in code, always present)
  > System setting (from system_settings table)
  > Plan-level default (from plan config)
  > Org override (from org record)
  > User override (from user preferences)
```

Define all defaults in a single constants file. The application never reads raw database values — it goes through a resolver that handles missing values.

### "Write on first change" pattern

When adding a new setting with a default, do NOT run an UPDATE on every user row. Instead:

1. Define the default in code.
2. The resolver returns the default when no database value exists.
3. Write to the database only when a user explicitly changes the setting.
4. Result: zero migration. Existing users get the default via code.

This is how VS Code, Notion, and most modern apps handle settings.

---

## Settings UI patterns

### Auto-save vs explicit save

| Pattern | When to use | Examples |
|---|---|---|
| **Auto-save** (immediate on toggle/change) | Effect is instantly visible, easily reversible, single-value | Theme toggle, density, notification on/off, view mode |
| **Explicit save** (Save button required) | Text fields, multi-field forms, side effects, affects others | Profile info, billing details, security policies |

**Critical rule:** never mix auto-save and explicit-save controls in the same form section. If a page has both, visually separate them into distinct sections. Otherwise users assume text fields also auto-save and navigate away without clicking Save.

### Section-by-section save

Each settings group has its own form and Save button. The profile section saves independently from the security section. Benefits: users don't lose changes across sections, validation errors in one section don't block another, each section has its own loading state.

### Danger zone

Always at the bottom of the page. Red/destructive border. Each action requires confirmation. Irreversible actions require typing the resource name.

```
┌─────────────────────────────────────────────┐
│ Danger Zone                      (red border)│
│                                              │
│ Delete this organization                     │
│ This will delete 47 users, 1,203 issues,     │
│ and 89 projects. This cannot be undone.       │
│                                [Delete Org]  │
│                                              │
│ Transfer ownership                           │
│                              [Transfer...]   │
└─────────────────────────────────────────────┘
```

### Reset to defaults

- **Per-setting:** small reset icon next to any setting that differs from default. VS Code shows a gear icon.
- **Per-section:** "Reset to defaults" link at the bottom. Requires confirmation.
- Visually indicate which settings have been customized (VS Code uses a blue left-border bar).

### Settings search

When 30+ options: search bar at the top, filters settings in real-time, highlights matching text, hides sections with no matches. For under 20 settings: rely on section nav.

### Settings diff for admin changes

For org/system settings that affect others, show consequences before saving:

```
You are about to change:
  Session timeout: 12 hours > 4 hours (affects 47 users)
  MFA required: No > Yes (23 users will need to enroll)
  
[Cancel]  [Apply changes]
```

### Settings audit log

For org and system settings, log every change with who, what, when, old value, new value. Show as a timeline in the admin UI.

### Unsaved changes warning

When a user has modified an explicit-save section and tries to navigate away, show an inline banner: "You have unsaved changes" with Save and Discard buttons. Also hook `beforeunload` for browser navigation.

---

## Admin configuration panel

### Runtime config vs deployment config

| Bucket | Where stored | Changed by | Examples |
|---|---|---|---|
| **Environment variables** | Secrets manager, `.env` | Redeploy required | DB URL, API keys, secrets |
| **Config files (git)** | Repository | Deploy required | Setting definitions, role schemas, flag definitions |
| **Database (runtime)** | `system_settings` table | Admin UI, instant | Maintenance mode, rate limits, feature flag values |

**Rule:** definitions and schemas in code (version-controlled, reviewable). Values and overrides in the database (runtime-changeable). Secrets in env vars (never in code or admin UI).

### What goes in the admin panel

- **Maintenance mode** toggle (immediate effect, global banner)
- **Rate limits** (requests per minute, configurable per org)
- **Default session timeout** and maximum
- **File upload limits** (size, types)
- **Feature flag controls** (toggle per org, per plan, globally)
- **System health indicators** (DB status, queue health, storage usage, external service circuit breaker states) — read-only, not settings

### Feature flags from the UI

```sql
feature_flags
  key              VARCHAR(100) PRIMARY KEY
  description      TEXT
  enabled          BOOLEAN DEFAULT false
  rollout_percent  INTEGER DEFAULT 0
  enabled_org_ids  UUID[]
  enabled_plan_ids VARCHAR[]
  updated_at       TIMESTAMPTZ
  updated_by       UUID
```

Show in admin: flag name, description, current state, controls to toggle, last changed by/when. Connect to the evaluation function in `system-integration.md`.

---

## Org settings organization

### Structuring 15+ sections

Use the two-column layout (nav left, content right) with domain grouping:

```
WORKSPACE
  General           (name, logo, URL, timezone)
  Members           (invite, roles, groups)

PRODUCT
  Features          (toggles, defaults)
  Notifications     (channel defaults, templates)
  Integrations      (connected services)
  Import / Export   (data policies)

ADMIN
  Security          (SSO, MFA, passwords, sessions)
  Billing           (plan, payment, invoices)
  API               (keys, webhooks, rate limits)
  Data Management   (retention, deletion, backups)
  Audit Log         (change history)

DANGER ZONE
  Delete workspace
  Transfer ownership
```

Most-used at top. Admin-only sections hidden from non-admins. Danger zone always last.

### Security policies

```
Password Policy
  Minimum length:       [__8__] (min: system default)
  Require uppercase:    [toggle]
  Require number:       [toggle]

Authentication
  Require MFA:          [toggle] (all members must enroll within 7 days)
  SSO:                  [Configure SAML/OIDC...]
  SSO enforcement:      [ ] Require SSO (disables password login)

Sessions
  Session timeout:      [__12__] hours idle (max: system limit)
  Concurrent sessions:  [__5__] per user

Network
  IP allowlist:         [Add IP range...] (empty = allow all)
```

### Branding

```
Logo:          [Upload] (SVG/PNG, max 2MB, 32x32 display)
Favicon:       [Upload] (ICO/PNG, 32x32)
Brand color:   [Color picker] #3B82F6
Custom domain: [________].yourdomain.com [Verify DNS]
Email sender:  From: [________]@yourdomain.com [Verify]
```

---

## Multi-tenant settings

### Plan-level defaults

The plan defines not just feature access but default values and limits:

```typescript
const PLAN_DEFAULTS = {
  free:       { max_members: 5,  storage_gb: 1,   custom_branding: false, sso: false,  api_rate: 100   },
  pro:        { max_members: 50, storage_gb: 100,  custom_branding: true,  sso: false,  api_rate: 1000  },
  enterprise: { max_members: Infinity, storage_gb: Infinity, custom_branding: true, sso: true, api_rate: 10000 },
};
```

### Plan-gated settings

Show the setting, don't hide it (discovery drives upgrades). Gray out controls. Show "Upgrade to unlock" with CTA. Badge the section name with required plan tier.

```
Custom branding                              PRO
  Logo:        [Upload]  ← grayed out
  ┌─────────────────────────────────────────┐
  │ Upgrade to Pro to customize branding    │
  │                         [Upgrade now →] │
  └─────────────────────────────────────────┘
```

### White-labeling depth

| Level | Includes | Typical plan |
|---|---|---|
| **Branding** | Logo, colors, favicon | Pro |
| **Branding + domain** | + custom domain, email sender | Business |
| **Full white-label** | + custom login page, remove "powered by," custom docs URL | Enterprise |

---

## Validation and constraints

### Input validation

Validate both client-side (instant feedback) and server-side (truth). Common validations: email format, URL format, hex color (`#[0-9A-Fa-f]{6}`), numeric ranges (session timeout 15-43200 minutes), domain format.

### Cross-setting constraints

Higher scopes constrain lower scopes:
- Org session timeout cannot exceed system maximum
- Org password length cannot be lower than system minimum
- Org cannot disable MFA if system enforces it

Check constraints on every save. Return specific error: "Cannot be lower than system minimum of 8 characters."

### Settings with side effects

Some changes trigger actions. Show consequences before saving:

| Change | Side effect | What to tell the admin |
|---|---|---|
| Change org name | Updates email templates, invoices | "Updates name everywhere it appears" |
| Change billing email | Verification sent to new address | "Verification email will be sent" |
| Enable MFA requirement | Users get enrollment deadline | "23 users will need to set up MFA within 7 days" |
| Reduce session timeout | Active sessions terminated | "12 active sessions will be terminated" |
| Disable feature flag | Users lose access | "147 users used this feature in the last 7 days" |

---

## Don'ts

- **Don't mix auto-save and explicit-save** in the same section. Users will assume everything auto-saves and lose data.
- **Don't run UPDATE on all users** when adding a new setting. Use the "write on first change" pattern with code-defined defaults.
- **Don't put secrets in the admin UI.** API keys and DB URLs belong in env vars, not the settings page.
- **Don't hide plan-gated settings.** Show them grayed out with upgrade prompts. Hidden features don't drive upgrades.
- **Don't skip the settings audit log** for org/system changes. "Who changed the session timeout?" is a question you must answer.
- **Don't let org admins set weaker security** than system policy. Constraints flow downward only.
- **Don't put the danger zone at the top.** Always last, always visually distinct, always behind confirmation.
- **Don't store setting definitions only in the database.** Definitions in code (version-controlled), values in the database (runtime-changeable).
- **Don't skip the unsaved-changes warning.** Users will navigate away and lose 5 minutes of form input.
- **Don't show admin-only settings to non-admins.** Filter sections by role.
- **Don't let settings changes happen silently** when they affect other users. Show the blast radius before confirming.
