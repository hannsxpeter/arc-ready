# Login & Auth Pages

This file covers the design and UX of login pages and the full login-to-dashboard journey. The authentication *logic* (hashing, sessions, tokens, RBAC) is in `auth-and-rbac.md`. The loading states and skeletons are in `states-and-feedback.md`. This file is about *what the user sees* — the login screen, the auth flow, the transition into the dashboard, and all the states in between.

The single most important principle: **fast in, fast working.** Every second between "I want to use the dashboard" and "I'm using the dashboard" is a cost. Minimize screens, minimize fields, minimize thinking.

**Canonical scope:** login page UX, signup flows, password reset, email verification, MFA screens, social login buttons. **See also:** `auth-and-rbac.md` for auth logic and RBAC, `security-deep-dive.md` for session security, `states-and-feedback.md` for loading and error state patterns.

---

## Login page layout

### Two viable patterns — pick one

**Centered card** — the login form floats in a centered card on a subtle background (solid color, soft gradient, or very muted pattern). The card is the only focus element. Best for: internal tools, admin panels, developer dashboards, anything where brand expression is secondary to speed.

**Split-screen** — the login form sits on one side (usually left, 40-50% width), brand content or illustration on the other (right, 50-60%). The illustration panel carries brand personality. Best for: customer-facing SaaS, products where first impressions drive conversion.

Both are valid. Do not use: full-screen background images with overlaid form (low contrast, hard to read), login in a modal over the landing page (breaks back-button, confuses screen readers), or a standalone form with no container (looks unfinished).

### Layout measurements

**Centered card layout:**
- Card max-width: 400-440px
- Card padding: 32-40px (24px on mobile)
- Card border-radius: 12-16px
- Card shadow: `0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)` — subtle, not dramatic
- Background: solid color or very gentle gradient. No stock photos behind the form.
- Center vertically with `min-h-screen flex items-center justify-center` or equivalent. On short viewports, let the card scroll rather than clip.

**Split-screen layout:**
- Form panel: 40-50% of viewport width, minimum 380px
- Illustration panel: remaining width, hidden below 768px (goes to centered card on mobile)
- Form panel padding: 48-64px horizontal, centered vertically within panel
- Illustration panel: use brand illustration, abstract art, or product screenshot — never stock photography of people at laptops
- On tablet (768-1024px): reduce illustration panel to 35-40%, or hide it

### Responsive behavior

This is non-negotiable:
- **Desktop (>1024px):** full layout (centered card or split-screen)
- **Tablet (768-1024px):** if split-screen, shrink or hide illustration panel; form panel fills more space
- **Mobile (<768px):** always single-column, full-width form with 16-24px horizontal padding, no illustration panel
- Touch targets: minimum 44px height on desktop, 48-56px on mobile (WCAG 2.2 requires 24x24px minimum, but 44px is the practical floor)

### Brand placement

- Logo: top of form area, 32-40px height, 24-32px margin below
- Product name: optional, directly under logo, `text-sm` or `text-base`, muted color
- Do not put a full navigation bar on the login page — there is nothing to navigate to
- Footer (optional): links to privacy policy, terms of service, help center. `text-xs`, muted, at page bottom or card bottom
- If split-screen: logo goes on the form side, not the illustration side

---

## Login form UX

### Field order and structure

The form is minimal. In order:

1. **Email field** — `type="email"`, `autocomplete="username"`, `inputmode="email"`. Label: "Email" or "Email address." Never "Username" unless your system genuinely uses usernames.
2. **Password field** — `type="password"`, `autocomplete="current-password"`. Label: "Password." Include a visibility toggle (eye icon, right side of input).
3. **Remember me** (optional) — checkbox, below password field, left-aligned. Label: "Remember me" or "Keep me signed in." Default: unchecked. Controls session duration (e.g., 24h vs 30 days).
4. **Forgot password link** — right-aligned on the same row as "Remember me," or directly below the password field. Text: "Forgot password?" Not "Forgot your password?" (shorter is better).
5. **Submit button** — full width, primary style. Label: "Sign in" (not "Login," "Log in," or "Submit"). Below the forgot-password row with 16-24px gap.
6. **Separator** — "or" divider between email+password and alternative auth methods. Styled as a horizontal rule with centered text.
7. **Alternative auth buttons** — social login, SSO, passkey (see auth method ordering below).
8. **Sign-up link** — at the bottom: "Don't have an account? Sign up." Secondary text treatment.

### Identifier-first pattern (when to use)

If your app supports SSO alongside password auth, use the identifier-first pattern: show only the email field first. On submit, check the email domain against your SSO config. If it matches an SSO provider, redirect there. If not, show the password field (with a smooth expand animation, not a full page change).

This eliminates the "which button do I press?" problem for SSO users and avoids exposing password fields to users who should never see them. Auth.js, Clerk, and WorkOS all support this pattern.

### Label placement

**Always above the input. No exceptions.** Top-aligned labels have the fastest scan time and work in every language direction. Never use:
- Placeholder text as the label — it disappears on focus, breaking context
- Floating labels — they start as placeholders (same problem) and shrink to tiny text that fails contrast ratios
- Left-aligned labels beside the field — wastes horizontal space, breaks on mobile

If you need extra context for a field, use helper text below the input in `text-xs`, muted color. Example: "We'll send a verification code to this address."

### Input field specifications

| Property | Desktop | Mobile |
|---|---|---|
| Height | 40-44px | 48-56px |
| Font size | 14-16px (`text-sm` to `text-base`) | 16px minimum (prevents iOS zoom on focus) |
| Padding horizontal | 12-16px | 14-16px |
| Border | 1px solid, muted gray | Same |
| Border-radius | 6-8px | Same |
| Focus ring | 2px ring, brand color, offset 2px | Same |
| Gap between fields | 16-20px | 16-20px |
| Label to input gap | 4-6px | 6-8px |

Always set `font-size: 16px` or larger on mobile inputs. iOS Safari zooms the viewport when focusing an input with font-size below 16px, and the zoom is disorienting.

### Password visibility toggle

- Icon: eye (hidden) / eye-off (visible) — right side of the input, inside the field border
- Toggle: `<button type="button">` (not a checkbox, not a link)
- Icon size: 18-20px, muted color, darker on hover
- `aria-label`: "Show password" / "Hide password"
- Default state: password hidden
- Never clear the password field when toggling visibility
- Support clipboard paste into the password field — never block it

### Remember me behavior

"Remember me" controls the session duration, not a stored password. Checked = long session (14-30 days), unchecked = short session (12-24 hours or browser-session only). Make the default match your security posture — unchecked for sensitive dashboards, checked for low-risk ones.

### Submit button states

The submit button has four states, all of which must be implemented:

1. **Default** — full-width, primary color, "Sign in" label. Active and ready.
2. **Disabled** — shown only when required fields are empty. 50% opacity, `cursor: not-allowed`. Do not disable on invalid input — let the user submit and show validation errors instead.
3. **Loading** — shown from click until the server responds. Label changes to "Signing in..." with an inline spinner (16px, left of text or replacing text). The button is disabled to prevent double-submit. The form fields are also disabled.
4. **Success** (optional) — brief flash of a checkmark icon or "Success" text before the redirect. Duration: 300-600ms. Only useful if there is a visible redirect delay.

### Form autocomplete attributes

These matter for password managers. Get them right:

```html
<!-- Login form -->
<input type="email" autocomplete="username" />
<input type="password" autocomplete="current-password" />

<!-- Sign-up form -->
<input type="email" autocomplete="username" />
<input type="password" autocomplete="new-password" />

<!-- Password reset form -->
<input type="password" autocomplete="new-password" />
```

---

## Authentication method presentation

### Visual hierarchy and ordering

Present auth methods in this order. The principle: most common/frictionless first, most legacy last.

**For B2B / enterprise dashboards:**
1. SSO button — "Sign in with your organization" or "Sign in with SSO" (primary or secondary button style)
2. Passkey option — "Sign in with passkey" (secondary button)
3. Email + password form (the fallback)

**For consumer / SaaS products:**
1. Social login buttons — Google first (highest adoption), then GitHub, Microsoft, Apple as relevant
2. Or-divider
3. Email + password form
4. Passkey — offered inline or as a browser prompt after email entry (identifier-first)

**For developer tools:**
1. GitHub button — "Continue with GitHub" (primary)
2. Google button (secondary)
3. Or-divider
4. Email + password form

### Social login button styling

Follow each provider's brand guidelines, but keep consistent sizing:
- Height: 40-44px (same as form inputs)
- Full width, matching form field width
- Provider icon (20-24px) left-aligned with 12px gap to text
- Text: "Continue with Google" (not "Sign in with Google" or "Log in with Google") — "Continue" is neutral and works for both login and signup
- Background: white or light gray for all providers (consistent look), or provider brand colors (Google blue, GitHub black, Microsoft gray). Pick one approach and use it for all buttons.
- Gap between social buttons: 8-12px
- Gap between social buttons and or-divider: 20-24px

### The "or" divider

A horizontal line with centered "or" text. Implementation:
```css
.divider {
  display: flex;
  align-items: center;
  gap: 16px;
  color: var(--text-muted);
  font-size: 0.75rem; /* text-xs */
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.divider::before,
.divider::after {
  content: "";
  flex: 1;
  height: 1px;
  background: var(--border);
}
```

### Passkey presentation

Passkeys are technically invisible — the user doesn't "see" a passkey. They see a biometric prompt. Frame it that way:
- Label the button "Sign in with fingerprint or face" or "Use passkey" — not "Sign in with FIDO2 WebAuthn credential"
- If the browser supports passkeys and the user has one registered, auto-prompt on page load (or after email entry)
- If passkeys aren't available, hide the button entirely — don't show a greyed-out option for something the user can't use
- Fallback: always have password or magic link available alongside passkeys

### Magic link presentation

Show as a secondary flow: "Email me a sign-in link" below the password field, or as an alternative after failed password attempts. The flow:
1. User enters email, clicks "Email me a link"
2. Show confirmation: "Check your email — we sent a link to [email]. It expires in 15 minutes."
3. No spinner — the user needs to go to their email. Show the confirmation immediately after the API call.
4. Include a "Resend" link with a 60-second cooldown (show countdown)

### SSO / Enterprise login

For apps with SSO support, the cleanest pattern is identifier-first:
1. User enters email
2. System checks the domain against configured SSO providers
3. If SSO match: redirect to the IdP. Show a brief "Redirecting to your organization's login..." message with a spinner
4. If no match: show the password field with smooth expand animation

Alternative: a standalone "Sign in with SSO" button that opens a domain/company input field or dropdown.

---

## Visual design

### Typography

- Page title: "Sign in" or "Welcome back" — `text-xl` to `text-2xl` (20-24px), `font-semibold`
- Subtitle (optional): "Enter your credentials to continue" — `text-sm` (14px), muted color. Keep it short or omit it.
- Labels: `text-sm` (14px), `font-medium`, standard foreground color
- Helper text: `text-xs` (12px), muted color
- Error text: `text-xs` (12px), destructive/red color
- Button text: `text-sm` (14px), `font-medium`
- Footer links: `text-xs` (12px), muted or link color

### Spacing rhythm

Use a consistent spacing scale (4px base, 8px increments):
- Card padding to form content: 32-40px (8 or 10 units)
- Logo to page title: 24-32px
- Page title to first field: 24-32px
- Between form groups (label + input + helper): 16-20px
- Label to input: 4-6px
- Input to helper/error text: 4px
- Last field to submit button: 24px
- Submit button to or-divider: 20-24px
- Or-divider to social buttons: 20-24px
- Social buttons to sign-up link: 24-32px

### Color usage

- Background: neutral — white, off-white, or very light gray in light mode; dark gray or near-black in dark mode. Never a saturated color.
- Card background: white (light) / elevated dark surface (dark). Must have clear contrast against page background.
- Primary action (sign-in button): brand color. Must meet 4.5:1 contrast against button text (WCAG AA).
- Input borders: muted gray. Focus state: brand color ring with 3:1 contrast against surrounding area.
- Error state: red/destructive color for borders, text, and icons. Never rely on color alone — always pair with an icon or text.
- Links: standard link color, underlined on hover

### Dark mode

Support it. Use `prefers-color-scheme` media query for automatic switching, with a manual toggle if your dashboard has one.

Dark mode login-specific rules:
- Card background: elevated surface (e.g., `hsl(0 0% 12%)` or `hsl(0 0% 15%)`), not pure black
- Input backgrounds: slightly lighter than card (`hsl(0 0% 16%)`)
- Input borders: visible but not harsh (`hsl(0 0% 25%)`)
- Social login buttons: adjust backgrounds so they read against dark surface — white-on-dark buttons work well
- Maintain all contrast ratios — dark mode is not an excuse for low contrast

### Accessibility requirements

These are not optional. They are the floor.

**WCAG AA (the minimum for login pages):**
- Text contrast: 4.5:1 against background (normal text), 3:1 (large text, 18px+ bold or 24px+)
- UI component contrast: 3:1 for borders, icons, focus indicators against adjacent colors
- Focus indicators: 2px solid ring, 3:1 contrast against adjacent background. Never `outline: none` without a replacement.
- Touch targets: 24x24px CSS minimum (WCAG 2.2 SC 2.5.8), but aim for 44px+ in practice

**Focus management:**
- On page load: auto-focus the first input field (email). Use `autoFocus` attribute or `useEffect` with `ref.focus()`.
- Tab order: email field > password field > remember me > forgot password > submit button > social login buttons > sign-up link. Matches visual order top-to-bottom, left-to-right.
- After validation error: move focus to the first field with an error. Announce the error to screen readers via `aria-describedby` linking the input to its error message.
- After submit with errors: do not move focus to a generic error summary unless there are multiple errors. For single-field errors, focus the offending field.
- `aria-live="polite"` on error message containers so screen readers announce them without interrupting.

**Screen reader experience:**
- Use `<form>` with a visible or `aria-label` heading (e.g., "Sign in to [Product Name]")
- Each input must have an associated `<label>` — not just `placeholder`, not just `aria-label`
- Password toggle button: `aria-label="Show password"` / `aria-label="Hide password"`, toggled on click
- Social login buttons: "Continue with Google" is sufficient — the icon adds visual context but the text is the accessible name
- Error messages: linked to inputs via `aria-describedby`, marked with `role="alert"` or `aria-live`

**Keyboard navigation:**
- Everything must be operable with keyboard only — Tab, Shift+Tab, Enter, Space
- Enter in any input field submits the form (standard HTML behavior — do not break it)
- Escape closes any open popover or tooltip (e.g., password requirements popup)
- No keyboard traps — the user can Tab through and past the form

---

## Error handling

### Wrong credentials

The most common error. Handle it exactly like this:
- Message: "Invalid email or password." — generic, prevents enumeration. Do not say "no account with that email" or "wrong password."
- Display: inline above the form or directly below the submit button. Use `role="alert"` for screen reader announcement.
- Styling: red/destructive text with an alert icon (circle-exclamation or similar). Red border on both email and password fields (since you are not revealing which is wrong).
- Behavior: do NOT clear the email field. Do NOT clear the password field. The user should only have to retype what they think was wrong.
- Focus: move focus to the password field (most likely the field the user needs to retype).

### Account locked

After N failed attempts (typically 5-10):
- Message: "Too many failed attempts. Your account has been temporarily locked. Try again in [time remaining] or reset your password."
- Include a link to the password reset flow
- Show a countdown if the lockout is time-based (e.g., "Try again in 14 minutes")
- Disable the submit button during lockout (with tooltip explaining why)
- On the backend: use exponential backoff — 1 min, 5 min, 15 min, 1 hour

### Rate limited

If the user (or an attacker) is hitting the endpoint too fast:
- Message: "Too many requests. Please wait a moment and try again."
- This is different from account lock — rate limiting is per-IP or per-session, not per-account
- Show a brief cooldown timer or just re-enable the form after 30-60 seconds
- Do not reveal rate limit thresholds in the error message

### Network errors

When the auth endpoint is unreachable:
- Message: "Unable to connect. Check your internet connection and try again."
- Show a retry button that re-submits the form
- Do not lose the form data — fields stay filled
- If the error persists across multiple retries, suggest: "If this keeps happening, contact support."

### Session expired

When a user lands on a protected page with an expired session:
- Redirect to `/login?next=<original_path>&reason=session_expired`
- Show a non-alarming message at the top of the login form: "Your session has expired. Please sign in again."
- After re-authentication, redirect to the original path — do not dump them on the home page
- Styling: info-level (blue) not error-level (red). Session expiry is normal, not an error.

### MFA required

When the server responds that MFA is needed after successful password auth:
- Transition smoothly to the MFA screen — same page context, not a full page redirect
- Show: "Enter the 6-digit code from your authenticator app"
- Input: single field, `inputmode="numeric"`, `autocomplete="one-time-code"`, 6 characters max
- Auto-submit when all 6 digits are entered (with a manual submit button as fallback)
- Show a countdown for code expiry if time-based (30 seconds for TOTP)
- Provide a "Use a recovery code" fallback link
- On wrong code: "Invalid code. Please try again." — do not reset to the email screen

### Email not verified

For dashboards with email verification:
- Message: "Please verify your email before signing in. Check your inbox for a verification link."
- Include a "Resend verification email" button with 60-second cooldown
- Do not reveal this to unauthenticated requests — only show after successful credential check (prevents enumeration of verified vs unverified accounts)

---

## Security UX tradeoffs

### Generic messages vs helpful messages

The tension: security wants generic messages ("Invalid credentials"), UX wants specific messages ("Wrong password — try again or reset it"). The resolution:

**Use generic messages for credential errors.** "Invalid email or password" is the standard. The security risk of enumeration outweighs the UX cost of ambiguity. Compensate with a visible, easy "Forgot password?" link.

**Use specific messages for everything else.** Account locked, rate limited, network error, session expired, MFA required, email not verified — these can be specific because they don't reveal whether an email is registered.

### Password requirements display

- On the login form: never show password requirements. The user is entering an existing password, not creating one. Showing "must be 8+ characters with a number" is confusing and irrelevant.
- On the sign-up / password-reset form: show requirements as a checklist that updates in real-time as the user types. Each requirement shows a check or X. Show this on focus of the password field, not before.
- Requirements themselves: minimum 8 characters with MFA, minimum 15 without. Do not mandate uppercase/lowercase/number/special — this leads to predictable patterns like `Password1!`. Instead, block common passwords and check against breach databases (HaveIBeenPwned API).

### Breach detection notices

If a user's password is found in a known breach database:
- On login: do not block the login. Allow it, then show a warning on the dashboard: "Your password was found in a data breach. Change it now to protect your account." Include a direct link to password change.
- On sign-up / password change: block the password and show: "This password has been found in a data breach and can't be used. Choose a different password."
- Never reveal which breach or how the password was found.

### Timing attack prevention

Make login responses take consistent time whether the email exists or not. Without this, attackers can measure response times to determine valid emails:
- If the email doesn't exist, still run the password hash function (hash a dummy) before returning the error
- Or add a random delay (200-500ms) to all login responses
- The user-facing UX doesn't change — this is a backend concern, but it's worth noting here because inconsistent response times undermine the generic error message

---

## Post-login transition

### The moment after "Sign in"

The gap between clicking "Sign in" and seeing the dashboard is where most login experiences fail. Handle it in layers:

1. **Button loading state (0-300ms):** Button shows "Signing in..." with spinner. Form fields disabled.
2. **Auth response (300ms-2s typical):** Server validates credentials, creates session.
3. **Redirect (immediate after auth):** Client receives session cookie, begins redirect to dashboard.
4. **Dashboard shell (immediate):** The page chrome (sidebar, header, navigation) renders instantly from static layout — no data needed.
5. **Dashboard data (200ms-2s):** Individual sections load with skeleton placeholders. See `states-and-feedback.md` for skeleton patterns.

The user should never see a blank white screen during this transition. The sequence is: login form with loading button > (brief) > dashboard shell with skeletons > content filling in.

### Skeleton screens for the dashboard

After redirect, the dashboard page renders in this order:
1. **Immediately:** sidebar navigation, top header, page title — these are static and need no data
2. **Skeleton phase:** data-dependent sections show gray placeholder shapes matching the final layout. Subtle shimmer animation (gradient sliding left-to-right, ~1.5s cycle).
3. **Progressive fill:** each section replaces its skeleton as data arrives. Cross-fade transition, 200-300ms.

Rules from `states-and-feedback.md` apply: match the skeleton to the final layout shape, don't skeleton the navigation chrome, use per-component skeletons with `<Suspense>` boundaries, don't tear down content for background refetches.

### Redirect handling

After successful auth:
- Redirect to the `next` parameter if present and validated (see security note below)
- Otherwise redirect to `/` or `/dashboard` — the default landing page
- **Validate the redirect URL server-side.** Only allow relative paths or paths on your domain. Never redirect to an absolute URL from a query parameter — that is an open redirect vulnerability.
- Use `router.replace()` (not `push`) for the login-to-dashboard redirect so the user can't "back" into the login page after authenticating

### First-time vs returning user

Detect whether this is the user's first login. The simplest method: a `lastLoginAt` field on the user record. `null` means first time.

**First-time user (onboarding):**
1. Redirect to an onboarding flow, not the raw dashboard
2. Welcome screen: "Welcome to [Product], [Name]!" with a brief value proposition or setup wizard
3. Keep it short — 1-3 steps maximum. Collect only what is truly needed for the first session (role, team, preferences)
4. End with a redirect to the dashboard, now with a contextual product tour or tooltip highlights
5. Mark onboarding as complete in user metadata so they are never shown it again

**Returning user:**
1. Redirect straight to the dashboard — no welcome screen, no tour
2. Optional: a subtle "Welcome back, [Name]" in the top header or as a brief toast. This disappears after 3-5 seconds.
3. Optional: if there is important news (new features, system status), show a non-blocking notification badge or banner — not a modal

### Loading performance targets

Aim for these timelines (measured from clicking "Sign in"):
- Auth response: < 1 second
- Redirect + shell render: < 500ms
- First meaningful content (above-fold data loaded): < 2 seconds
- Full page interactive: < 3 seconds

If your auth is slow (external IdP, cold starts), fake progress: show the dashboard shell with skeletons immediately after the redirect, even before the auth token is fully validated, and swap in real content when ready. The user perceives speed from the layout appearing quickly, not from the data arriving quickly.

---

## Mobile login patterns

### Thumb-zone layout

75% of mobile users interact with their thumb. The comfortable zone is the bottom third of the screen. Design for it:
- Place the submit button and primary actions in the bottom half of the viewport
- The email and password fields will naturally be in the middle — that is fine; text input requires intentional focus regardless of position
- Social login buttons: below the form, within thumb reach
- "Forgot password" and "Sign up" links: above the submit button or at the very bottom
- Do not place critical actions at the top of the screen on mobile

### Mobile input behavior

- Always use `font-size: 16px` or larger for inputs. iOS Safari zooms the viewport on focus for anything smaller. This is the single most common mobile login bug.
- Use `inputmode="email"` on the email field for the @ keyboard layout
- Use `inputmode="numeric"` on OTP/MFA code fields for the number pad
- Set `autocomplete="current-password"` so password managers and biometric autofill work
- Test with biometric autofill (Face ID, Touch ID, Android biometric prompt). If your input attributes are correct, the OS will offer to autofill credentials automatically.

### Biometric authentication prompts

On mobile, biometric login replaces the password field entirely:
1. User opens the app or lands on the login page
2. If the device has stored credentials (via passkey or platform authenticator), the OS biometric prompt appears automatically
3. User authenticates with face/fingerprint
4. Session created, redirect to dashboard

This should be the **primary** mobile login path for returning users. The email+password form is the fallback for users without biometrics set up.

Important: not every user has biometrics configured. The fallback path (password, magic link) must be equally smooth and equally visible — not buried behind three taps.

### Responsive form design

- Single column only. No side-by-side fields on mobile.
- Full-width inputs and buttons — no margin that shrinks the tap targets
- Padding: 16-24px horizontal on the form container
- Minimum input height: 48px (some design systems use 56px for extra comfort)
- Gap between fields: 16px
- The keyboard will cover the bottom of the screen when focused — ensure the active field scrolls into view above the keyboard. iOS handles this natively; Android may need `android:windowSoftInputMode="adjustResize"` or JavaScript scrolling.

---

## Login-to-dashboard journey map

The full journey, with every state and transition:

```
User arrives at protected route
    │
    ├── Has valid session? ─── YES ─── Render dashboard
    │
    NO
    │
    ▼
Redirect to /login?next=<original_path>
    │
    ▼
Login page renders
    ├── Auto-focus email field
    ├── If ?reason=session_expired, show info banner
    ├── If passkey available, offer biometric prompt
    │
    ▼
User authenticates (password, social, passkey, SSO, magic link)
    │
    ├── Invalid credentials ─── Show error, stay on page
    ├── Account locked ─── Show lockout message + timer
    ├── Rate limited ─── Show cooldown message
    ├── Network error ─── Show retry option
    ├── MFA required ─── Show MFA input screen
    │       │
    │       ├── MFA success ─── Continue below
    │       └── MFA failure ─── Show error, allow retry
    │
    ▼
Auth success
    ├── Button shows "Signing in..." (300-600ms)
    ├── Server creates session
    │
    ▼
Redirect to `next` param or /dashboard
    │
    ▼
Dashboard page loads
    ├── Shell renders immediately (nav, header)
    ├── Data sections show skeletons
    ├── Content fills in progressively
    │
    ├── First-time user? ─── YES ─── Onboarding flow (1-3 steps)
    │                                   │
    │                                   ▼
    │                                Dashboard with guided tour
    │
    └── Returning user? ─── YES ─── Dashboard at full productive state
                                    Optional "Welcome back" toast (3-5s)
```

---

## Common anti-patterns

Things to avoid — every one of these actively harms the login experience:

**1. Clearing form fields on error.** When the password is wrong, clear only the password field (or nothing). Never clear the email. Never clear both. The user has to retype everything, and 88% of users won't come back after a bad experience.

**2. Placeholder text as labels.** Placeholders disappear on focus, leaving the user wondering what field they are typing in. Floating labels are a half-fix — they shrink to sizes that fail contrast checks. Use real labels above inputs.

**3. Blocking paste on password fields.** This breaks password managers, which are the single best thing users can do for their security. Never set `oncopy`, `onpaste`, or `oncut` to prevent clipboard operations.

**4. Forcing username instead of email.** Users remember their email. They do not remember the username they chose for your specific service three years ago. Use email as the identifier.

**5. Two-page login without reason.** Showing email on page 1 and password on page 2 only makes sense for identifier-first SSO routing. If you do not have SSO, show both fields on one page. Two pages doubles the interaction cost for zero benefit.

**6. CAPTCHAs on every login attempt.** Show CAPTCHAs only after 2-3 failed attempts, or use invisible CAPTCHA (reCAPTCHA v3, Turnstile). A CAPTCHA on every login is hostile to all users to stop a few bots.

**7. Overly strict password rules.** "Must contain uppercase, lowercase, number, and special character" produces `Password1!` every time. Check against breach databases and enforce minimum length instead.

**8. "Login" and "Log in" and "Sign in" mixed on the same page.** Pick one term ("Sign in" is the modern standard) and use it everywhere. Mixing terms makes the page feel unpolished and confuses screen readers.

**9. Auto-redirecting away from the login page for OAuth.** Do not automatically redirect to Google/GitHub OAuth on page load. The user needs to choose their auth method. Auto-redirect is disorienting and breaks the back button.

**10. Missing loading state on submit.** If clicking "Sign in" produces no visual feedback for 1-2 seconds, the user will click again (double submit) or think the page is broken. Always show a spinner/loading state immediately on click.

**11. No error message for empty fields.** If the user clicks "Sign in" with empty fields, show "Email is required" and "Password is required" inline — do not silently do nothing.

**12. Login page with full app navigation.** The login page is not part of the app. Do not show the app's sidebar, header, or navigation chrome. The only actions available should be login-related.

**13. Requiring email confirmation before first login on invite-only systems.** If an admin invited the user, the invite IS the confirmation. Don't make them verify an email you already know is valid.

**14. Background video or heavy animations.** These slow down page load, drain mobile batteries, and distract from the one thing the user needs to do: type their credentials. A static background is always better.

**15. No visible path to help.** If a user is stuck — wrong email, forgotten password, no account — they need a way out. Include "Forgot password?", "Sign up", and a help/support link.

---
---

# Registration / Sign-Up Pages

This section covers the design and UX of registration pages — the full journey from "I want to create an account" to "I'm using the product." It mirrors the login section above but covers what changes when you are creating a new user rather than authenticating an existing one.

The single most important principle: **collect the minimum to create the account, defer everything else.** Every field you add to the registration form costs you users. HubSpot's analysis of 40,000 landing pages found that dropping from 4 fields to 3 increased conversions by 50%. Expedia removed one field (company name) and recovered $12 million per year in abandoned signups.

---

## Registration page layout

### Should it mirror the login page?

Yes — use the same layout pattern (centered card or split-screen) for both login and registration. This creates visual consistency and reduces cognitive load when users switch between the two. The form card, typography scale, spacing rhythm, and color usage should be identical. The only differences are the form content, page title, and CTA text.

If you chose centered card for login, use centered card for signup. If you chose split-screen, use split-screen. Do not mix patterns.

### Layout adjustments for registration

**Centered card:** The card may need to be slightly taller to accommodate more fields, but keep the same max-width (400-440px). If the form exceeds the viewport height, the card scrolls — do not widen the card to reduce height.

**Split-screen:** The illustration panel is more valuable on signup than login because new users benefit from brand context. Use this panel to communicate 1-3 key value propositions — short bullet points with icons, a product screenshot, or a customer testimonial. Do not put a wall of marketing copy here. Three bullet points, max 8 words each.

**Split-screen illustration panel content for registration:**
- Social proof: "Join 10,000+ teams" or a recognizable logo bar (4-6 logos)
- Value props: 2-3 bullet points with check icons — "Free 14-day trial", "No credit card required", "Cancel anytime"
- Product screenshot (optional): a single clean screenshot showing the dashboard in use — not a feature collage
- Customer quote (optional): one sentence, with name and company. No headshots in the illustration panel.

### What NOT to put on the registration page

- Full marketing landing page content (that belongs on the landing page, not the form page)
- Video embeds or auto-playing media
- Multiple CTAs competing with the registration form
- Navigation bars or site headers — the registration page is a focused conversion page, same as login
- Pricing information (the user already decided to sign up; pricing belongs on the pricing page)

---

## Registration types and recommended fields

Different products need different registration forms. Here are the four common patterns with exact field lists.

### Type 1: Self-service SaaS signup (public, anyone can create an account)

This is the most common pattern. Optimize aggressively for conversion — every unnecessary field is a leak in the funnel.

**Required fields (collect at signup):**
1. Full name — single field, `autocomplete="name"`. Not first/last split (see field-specific section below).
2. Email — `type="email"`, `autocomplete="email"`.
3. Password — `type="password"`, `autocomplete="new-password"`. With strength indicator and show/hide toggle.

**That is it. Three fields.** This is what Dropbox, Slack, ClickUp, and Notion use. Three fields plus a submit button.

**Defer to onboarding (collect after account creation):**
- Company/organization name
- Role/job title
- Team size
- Use case / what brought you here
- Avatar/profile photo
- Phone number
- Timezone (auto-detect silently via `Intl.DateTimeFormat().resolvedOptions().timeZone`)

**Alternative minimal form (email-only start):**
Some products (Miro, Figma) collect only the email first, then expand to password and name on the next step. This gets the email captured before the user can abandon the form — useful for re-engagement campaigns.

**Field order:** Full name > Email > Password > Submit. Name first because it personalizes the experience immediately ("Welcome, Sarah!"). Email second because it is the identifier. Password last because it requires the most cognitive effort.

### Type 2: Invite-only dashboard (admin sends invite, user completes profile)

The admin has already validated this person should have access. The invite email IS the identity verification. Minimize friction ruthlessly.

**Pre-filled from invite:**
- Email (read-only, shown but not editable — the admin specified this)
- Role/permissions (set by admin, shown as context: "You've been invited as an Editor")
- Organization/team name (shown as context: "Join Acme Corp's workspace")

**Required fields (collect at invite acceptance):**
1. Full name — the admin may or may not have provided this. If provided, pre-fill and let user edit.
2. Password — with strength indicator and show/hide toggle. Or offer "Continue with Google/GitHub" to skip password creation entirely.

**That is it. One or two fields.** The invite link should land on a page that says "You've been invited to [Org] by [Admin Name]. Set up your account to get started." Pre-filled email, name field (maybe pre-filled), password field, submit.

**Defer to onboarding/settings:**
- Avatar/profile photo
- Job title
- Notification preferences
- Everything else

**Do NOT require email verification for invite-based signups.** The admin sent the invite to that email, and the user clicked the link from that inbox. That IS verification. Requiring a separate verification step is redundant friction that insults the user's intelligence.

### Type 3: B2B / team-based signup (org creation + first user)

The user is creating both an organization and their personal account. This requires more information but should be broken into logical steps.

**Step 1 — Personal account (same as self-service):**
1. Full name
2. Work email — emphasize "work email" in the label or helper text to signal this is a professional context
3. Password

**Step 2 — Organization setup (shown after account creation, during onboarding):**
1. Organization/company name — required
2. Organization URL/slug — auto-generated from company name, editable. Format: `yourcompany.app.com` or `app.com/yourcompany`
3. Team size — dropdown or radio buttons: "Just me", "2-5", "6-20", "21-50", "51-200", "200+"
4. Role/department (optional) — helps with personalization

**Step 3 — Invite team (shown after org creation, skippable):**
- Bulk email input — textarea or multi-input for teammate emails
- "Skip for now" button — always available, prominently placed. Never force team invitations.
- Pre-fill with same-domain emails if the user's email domain is a company domain (not gmail/hotmail/etc.)

**Step 4 — Configure (optional, onboarding):**
- Industry/use case selection for template recommendations
- Notification preferences
- Integration connections

This is the one registration type where multi-step is clearly better than single-page. Four steps is the upper limit — anything beyond that should be deferred to settings.

### Type 4: Developer tool signup (GitHub-first, minimal friction)

Developer tools should lead with OAuth (GitHub primarily, Google secondary) and treat email+password as the fallback.

**Primary signup path:**
1. "Continue with GitHub" button — prominent, top of form
2. "Continue with Google" button — secondary
3. Or-divider
4. Email + password fields (fallback)

**What you get from GitHub OAuth:**
- Email (verified) — may be hidden; request `user:email` scope
- Display name
- Username
- Avatar URL
- Profile URL

**What you still need after GitHub OAuth:**
Usually nothing for the initial account. The OAuth callback creates the account and redirects to the dashboard or onboarding. If you need additional information:
- Organization name (if B2B) — collect in onboarding, not on signup
- Use case — collect in onboarding survey, not on signup

**What you get from Google OAuth:**
- Email (verified)
- Full name (given name + family name)
- Avatar URL
- Locale

**After social signup, do NOT show a "complete your profile" form before letting the user in.** They chose social login specifically to avoid forms. Let them into the product. Collect anything else through progressive profiling — settings page nudges, onboarding tooltips, or contextual prompts when a field becomes relevant.

---

## Registration form UX

### Single-page vs multi-step registration

**Single-page (use when you have 3-5 fields):**
- Best for: self-service SaaS, invite-only, developer tools
- Show all fields on one screen
- One submit button, one action, done
- Faster perceived completion — the user sees the entire scope upfront
- Multi-step forms can increase conversions by 300% for LONG forms (10+ fields), but for SHORT forms (3-4 fields), single-page wins because multi-step adds unnecessary navigation overhead

**Multi-step (use when you have 6+ fields or distinct logical groups):**
- Best for: B2B org creation, enterprise onboarding, forms that require conditional logic
- Break into 2-4 steps maximum. More than 4 steps is an onboarding flow, not a registration form.
- Each step should have a clear purpose: "Your account" > "Your organization" > "Invite your team"
- Progress indicator is mandatory — show which step the user is on and how many remain
- Allow backward navigation — users must be able to go back and edit previous steps
- Save progress server-side after each step. If the user abandons at step 3, their step 1-2 data is preserved for re-engagement.

**Progress indicator specifications:**
- Style: numbered steps with labels, connected by a line. Active step is filled/colored, completed steps show a checkmark, future steps are outline/muted.
- Position: top of the form card, below the page title, above the fields
- Step label font: `text-xs` to `text-sm` (12-14px), muted for inactive, standard for active
- Horizontal layout on desktop, vertical or condensed on mobile
- Do not use a generic progress bar (0-100%) — users need to know WHAT the steps are, not just a percentage

### Progressive disclosure

Collect the absolute minimum at signup. Fill in the rest through these mechanisms, in order of preference:

1. **Auto-detection** — timezone, locale, country (from IP), company name (from email domain via Clearbit/similar). Silently set these as defaults. Let the user change them in settings.
2. **Post-signup onboarding** — a 1-3 step welcome flow after account creation that asks role, team size, use case. This converts at a much higher rate than pre-signup fields because the user is already invested.
3. **Contextual prompts** — when the user first encounters a feature that needs missing data, prompt for it then. Example: first time inviting a teammate, ask for company name.
4. **Settings page nudges** — a "complete your profile" progress bar in the settings page. Non-blocking, non-annoying.

Never show all possible profile fields on the registration form. The registration form is for account creation. Everything else is profile completion.

### Password creation UX

The password field on registration is different from login — the user is creating a new password, not recalling one. Specific patterns:

**Real-time strength indicator:**
- Show a requirements checklist that updates as the user types. Each requirement gets a checkmark (green) or X (muted gray) in real time.
- Minimum requirements: 8+ characters (with MFA available) or 12+ characters (without MFA). Do not mandate specific character classes (uppercase, lowercase, number, special). Mandating classes produces `Password1!` and teaches users nothing.
- Supplement with a strength meter — a horizontal bar that fills from red (weak) through yellow (fair) to green (strong). The bar should be 100% width of the input field, 4px height, positioned directly below the input.
- Strength assessment should consider length, character variety, and dictionary/pattern checks. Libraries: zxcvbn (Dropbox) is the standard — it scores 0-4 and provides meaningful feedback.
- Display the strength label in text alongside the meter: "Weak", "Fair", "Good", "Strong". Do not rely on color alone — accessibility.

**Show/hide toggle:**
- Same pattern as login: eye icon inside the input, right side, `<button type="button">`, `aria-label="Show password"` / `aria-label="Hide password"`.
- Default state: hidden (masked). The toggle replaces the confirm password field entirely.

**Confirm password field — do NOT use one:**
- Remove it. Research shows the confirm password field is responsible for over 25% of signup form abandonments. It doubles the typing effort with no real benefit.
- Instead: use a single password field with a show/hide toggle. The user can unmask the password to verify it visually. This is faster, less error-prone, and results in higher completion rates.
- If you absolutely must have confirmation (regulated industries, legal requirements), show the confirm field only after the user has finished typing in the primary field, and display a real-time "Passwords match" / "Passwords don't match" indicator.

**Breach checking:**
- Check the password against the HaveIBeenPwned Pwned Passwords API on blur or on submit. The API uses k-anonymity — you send only the first 5 characters of the SHA-1 hash, so the full password never leaves the client. This is the approach NIST recommends.
- If the password is found in a breach: block it. Message: "This password has been found in a data breach and can't be used. Please choose a different password." Do not reveal which breach or how many times it appeared.
- Do not check on every keystroke — check on field blur or form submit to avoid excessive API calls.

**Password field autocomplete:**
```html
<input type="password" autocomplete="new-password" />
```
This tells password managers to generate a new password rather than autofill an existing one. Critical for registration forms.

### Email verification flow

Two approaches. Pick based on your security requirements.

**Approach A: Verify-then-access (blocking verification)**
- Flow: signup > "Check your email" screen > user clicks verification link > redirected to dashboard
- Show: "We sent a verification email to [email]. Click the link to activate your account."
- Include: a "Resend email" button with 60-second cooldown (show countdown timer)
- Include: a "Change email" link in case of typo
- Token expiration: 24 hours (standard). Verification tokens are low-risk — longer expiration is fine.
- Best for: financial products, healthcare, any product where unverified email access is a liability
- Downside: if the email is slow or lands in spam, the user is stuck. You lose users at this step — verification emails have a 20-30% non-completion rate in typical SaaS.

**Approach B: Access-then-verify (non-blocking, recommended for most SaaS)**
- Flow: signup > redirect immediately to dashboard > show a persistent banner: "Verify your email to unlock all features"
- The user can explore the product, set up their account, experience value — but certain actions are gated until verification (sending emails, inviting teammates, publishing content, connecting integrations).
- This approach lets users hit the "aha moment" before hitting the verification wall. Products using this approach see higher activation rates because the user is already invested when they verify.
- Show a verification reminder banner at the top of the dashboard — dismissable but returns on next page load until verified.
- Send a follow-up reminder email at +4 hours and +24 hours if not yet verified.
- Best for: most SaaS products, developer tools, productivity apps, anything where immediate product access drives activation.

**For social login users (Google, GitHub):** the email is already verified by the OAuth provider. Do NOT require separate email verification. The provider has already confirmed the email. Requiring re-verification is redundant and annoying.

### Terms of service / privacy policy consent

Three patterns, from lightest to heaviest. Use the lightest that satisfies your legal requirements.

**Pattern 1: Passive consent (lightest, US/most countries)**
- Text below the submit button: "By creating an account, you agree to our [Terms of Service] and [Privacy Policy]."
- No checkbox. Submitting the form constitutes acceptance.
- Links open in a new tab.
- This is sufficient for most US-based SaaS products. Consult your lawyer for your jurisdiction.

**Pattern 2: Active consent checkbox (GDPR, EU)**
- A checkbox above the submit button: "I agree to the [Terms of Service] and [Privacy Policy]."
- The checkbox MUST be unchecked by default. Pre-checked checkboxes violate GDPR.
- The submit button is disabled until the checkbox is checked.
- The checkbox label links to both documents (opening in new tabs).

**Pattern 3: Separate consents (GDPR with marketing)**
- Checkbox 1 (required): "I agree to the [Terms of Service] and [Privacy Policy]."
- Checkbox 2 (optional, unchecked): "I'd like to receive product updates and tips via email."
- Never bundle terms acceptance with marketing consent. GDPR requires separate, specific consent for each processing purpose.
- Newsletter/marketing checkbox must always be optional and unchecked by default.

**GDPR-specific requirements:**
- Consent must be freely given, specific, informed, and unambiguous.
- Pre-ticked boxes are not valid consent.
- Users must be able to withdraw consent as easily as they gave it — explain where in the privacy policy.
- Record the consent: timestamp, IP address, what was consented to, which version of the terms. Store this for audit purposes.
- If you serve EU users, use Pattern 2 or 3 regardless of where your company is based.

**Styling:**
- Consent text: `text-xs` to `text-sm` (12-14px), muted color
- Checkbox size: minimum 18x18px (visual), 24x24px minimum touch target
- Links within consent text: standard link color, underlined
- Position: between the last form field and the submit button, with 16px spacing above and below

---

## Registration journey / flow maps

### Flow 1: Standard self-service signup

```
Landing page / pricing page
    │
    ├── User clicks "Sign up" / "Start free trial" / "Get started"
    │
    ▼
Registration page
    ├── Form: name, email, password
    ├── Social login options (Google, GitHub)
    ├── Terms/privacy consent
    ├── Submit button: "Create account" or "Start free trial"
    │
    ▼
Account created
    │
    ├── [If verify-then-access] ─── "Check your email" screen
    │       │                         Resend button (60s cooldown)
    │       │                         Change email link
    │       ▼
    │   User clicks verification link
    │       │
    │       ▼
    │   Redirect to onboarding
    │
    ├── [If access-then-verify] ─── Redirect directly to onboarding
    │                                 Verification banner shown
    │
    ▼
Onboarding (1-3 steps)
    ├── Step 1: "What brings you here?" (role/use case)
    ├── Step 2: "Tell us about your team" (company, size) [skippable]
    ├── Step 3: "Invite teammates" [skippable]
    │
    ▼
Dashboard (first session)
    ├── Guided tour / tooltip highlights on key features
    ├── Empty states with clear CTAs: "Create your first [X]"
    ├── Checklist widget: "Getting started" with 3-5 items
    │
    ▼
First value (target: under 2 minutes from signup)
    └── User performs their first meaningful action
```

### Flow 2: Social signup (Google / GitHub OAuth)

```
Registration page
    │
    ├── User clicks "Continue with Google"
    │
    ▼
Redirect to Google OAuth consent screen
    ├── Scopes requested: email, profile (display name, avatar)
    ├── User authorizes
    │
    ▼
OAuth callback to your app
    ├── Receive: email (verified), full name, avatar URL, locale
    ├── Check: does an account with this email already exist?
    │     ├── YES ─── Link OAuth provider to existing account, sign in
    │     └── NO ─── Create new account with OAuth data
    │
    ▼
Account created (no password, no email verification needed)
    │
    ├── [If you need additional fields] ─── Short profile completion
    │     Only ask for fields OAuth didn't provide AND that are truly needed.
    │     Typical: nothing. Maybe company name for B2B products.
    │     Do NOT show a "complete your profile" gate — let them in.
    │
    ▼
Redirect to onboarding or dashboard
    └── Same onboarding as email signup
```

**What to do about missing fields after OAuth:**
- Name: Google provides it. GitHub may or may not (display_name can be null). If missing, ask on first login or infer from email prefix.
- Email: Google always provides it. GitHub may hide it — request `user:email` scope and use the primary verified email.
- Password: not needed. The user authenticates via OAuth. If they later want to add password login, offer it in account settings.
- Avatar: provided by both Google and GitHub. Use it as default, let user change later.

### Flow 3: Invite-based signup

```
Admin panel
    │
    ├── Admin clicks "Invite member" ─── enters email, selects role
    │
    ▼
System sends invitation email
    ├── From: "teamname via [Product]" or "[Admin name] invited you to [Product]"
    ├── Subject: "[Admin] invited you to join [Org] on [Product]"
    ├── Body: who invited them, what org, clear "Accept invitation" button
    ├── Invitation link expires in 7 days (standard, configurable)
    │
    ▼
User clicks invitation link
    │
    ├── Account exists? ─── YES ─── Sign in, auto-join org, redirect to dashboard
    │
    └── No account?
            │
            ▼
        Invite registration page
            ├── Context: "[Admin] invited you to [Org]" with org logo/name
            ├── Email field: pre-filled, read-only
            ├── Full name field (maybe pre-filled if admin provided it)
            ├── Password field (or "Continue with Google/GitHub")
            ├── Submit: "Join [Org]" (not generic "Sign up")
            │
            ▼
        Account created, auto-joined to org with assigned role
            │
            ▼
        Redirect to org dashboard
            ├── Skip generic onboarding — this user was invited, they have context
            ├── Show: "[Org] workspace" with guided pointer to key areas
            ├── Optional: brief role-specific tips ("As an Editor, you can...")
```

### Flow 4: B2B org creation (team signup)

```
Pricing page / "Start trial" CTA
    │
    ▼
Step 1: Personal account
    ├── Full name
    ├── Work email
    ├── Password
    ├── Submit: "Continue"
    │
    ▼
Step 2: Organization setup
    ├── Company/organization name
    ├── Workspace URL (auto-generated from org name, editable)
    │     Format: orgname.product.com — validate availability in real-time
    ├── Team size (dropdown: "Just me", "2-5", "6-20", "21-50", "51-200", "200+")
    ├── Industry (optional dropdown, for template/onboarding customization)
    ├── Submit: "Create workspace"
    │
    ▼
Step 3: Invite team (skippable)
    ├── Heading: "Invite your team"
    ├── Multi-email input field (comma or newline separated)
    ├── Optional role selection per invitee
    ├── "Send invitations" button
    ├── "Skip for now — I'll do this later" link (prominent, not hidden)
    │
    ▼
Step 4: Quick configure (skippable)
    ├── Select a starting template or use case
    ├── Connect key integrations (Slack, GitHub, etc.)
    ├── "Start using [Product]" button
    │
    ▼
Dashboard
    ├── Workspace created, user is owner/admin
    ├── If team was invited: show "Invitations sent" confirmation
    ├── Getting started checklist
```

---

## Field-specific best practices

### Name: single "Full name" vs first/last split

**Default recommendation: use a single "Full name" field.**

Reasons:
- Fewer fields = higher completion rates. One name field vs two cuts the form by one field.
- Culturally inclusive. Not everyone has a first/last name structure. Chinese names put family name first. Latin American names commonly have two surnames. Icelandic names use patronymics. Mononymous names exist. A single field handles all of these.
- Users think of their name as one thing. Usability studies show users frequently enter their full name in the "First name" field and then have to go back and delete.

**When to use first/last split:**
- Your product needs structured name parts for formal addressing ("Dear Ms. Rodriguez"), alphabetical directory sorting, or mail-merge templates
- Legal/compliance requirements mandate separate name fields
- Your product integrates with systems that require structured names (payroll, HR, legal document generation)

**If you need both:** collect "Full name" at signup (single field), then parse and allow the user to confirm/edit first/last split in their profile settings. Or collect a single field and use a simple split heuristic (last space = divider between given and family name) with an option to correct in settings.

**Implementation:**
```html
<label for="name">Full name</label>
<input type="text" id="name" autocomplete="name" required />
```

### Email

- `type="email"`, `autocomplete="email"`, `inputmode="email"`
- Validate format client-side (basic regex or HTML5 built-in validation), but do the real validation server-side by sending the verification email. Do not reject unusual but valid email formats (plus addressing like `user+tag@domain.com`, long TLDs, internationalized domains).
- For B2B products: consider domain-based restrictions or routing. If a user signs up with `user@acme.com` and Acme already has a workspace, offer to request access to the existing workspace rather than creating a new account. Auto-detect company from email domain (skip this for consumer email providers like gmail.com, yahoo.com, hotmail.com, outlook.com).
- Show clear error messages: "Please enter a valid email address" (not "Invalid input" or "Error").
- For invite-only: pre-fill the email from the invitation token and make it read-only.
- Add helper text when relevant: "Use your work email for team features" (B2B) or "We'll send a verification link to this address."

### Password

See the "Password creation UX" section above for full details. Summary:
- Single field, no confirm field, show/hide toggle
- Strength meter + requirements checklist, real-time
- `autocomplete="new-password"` (not `current-password`)
- Check against HaveIBeenPwned on blur/submit
- Minimum 8 characters (with MFA) or 12 characters (without)
- Do not mandate character class rules (uppercase/lowercase/number/special)

### Company / organization name

- **When to ask:** only on B2B org-creation signup (Type 3). Never on self-service or invite-only signup.
- **Auto-detection from email domain:** use a service like Clearbit or a simple whois-based lookup to suggest the company name based on the email domain. Pre-fill the field but let the user edit. Skip auto-detection for consumer email domains.
- **Field behavior:** when the user types an org name, auto-generate a URL slug below it (e.g., "Acme Corp" > `acme-corp.yourapp.com`). The slug field should be editable. Check slug availability with a debounced API call (300ms delay) and show real-time availability: green checkmark for available, red X for taken with a suggestion.
- **Defer if possible.** If your product works fine without an org name initially (single-user mode), collect it when the user first invites a teammate or accesses team features.

### Role / job title

- **When useful:** B2B products that personalize the onboarding based on role (showing different features/templates to a "Designer" vs "Developer" vs "Project Manager").
- **Collect in onboarding, not on signup.** Role information does not block account creation. It is a personalization signal.
- **Dropdown vs free text:** Use a dropdown with 5-8 common roles plus an "Other" option with a free-text field. Free text alone produces garbage data ("boss", "i do stuff", "n/a"). Dropdown alone misses edge cases.
- **Common role options for SaaS:** Developer/Engineer, Designer, Product Manager, Marketing, Sales, Executive/Founder, Operations, Other.

### Phone number

- **When to collect:** only if your product uses SMS for notifications, MFA, or the phone number is required for the core product function (calling features, SMS marketing tools). Never collect phone numbers "just in case."
- **International format:** use a phone input component with country code selector and flag icons (libraries: `react-phone-number-input`, `intl-tel-input`). Default the country based on IP geolocation. Store in E.164 format (`+14155551234`).
- **Collect in settings, not at signup.** If you need a phone number for MFA, prompt for it during MFA setup in account settings — not during registration.

### Avatar / profile photo

- **Never collect at signup.** Zero users want to upload a photo during registration. It breaks flow, adds complexity, and creates a decision that can stall the entire process.
- Use a generated default: initials on a colored background (deterministic color from name hash), or a pleasant abstract geometric avatar (like GitHub's identicons). The default should look intentional, not like a missing image.
- Prompt for avatar upload in settings or via a subtle nudge after the user has been active for a few sessions: "Add a profile photo so your team can recognize you."
- For social login users: use the avatar from the OAuth provider as default. No prompt needed.

### Timezone / locale

- **Auto-detect, never ask.** Use `Intl.DateTimeFormat().resolvedOptions().timeZone` on the client side to detect the user's timezone. Set it silently as a default on their profile.
- If auto-detection fails (rare), fall back to UTC and show a one-time prompt in settings: "We couldn't detect your timezone. Please set it so your notifications arrive on time."
- Locale: detect from the browser's `navigator.language` or `Accept-Language` header. Set silently.
- Allow the user to change both in settings. Never make them scroll through a timezone dropdown at signup.

---

## Common registration anti-patterns

Things to avoid — every one of these drives signup abandonment:

**1. Too many fields.** The number one killer. Forms with 11 fields convert at half the rate of forms with 4 fields. Ask yourself for every field: "Does this block account creation?" If no, defer it.

**2. Requiring a username.** Users do not want to invent a unique username for your SaaS product. They will try "john", get rejected, try "john123", get rejected, try "john_smith_2024", get frustrated, and leave. Use email as the identifier. If your product needs a display name, use their full name.

**3. Confirm password field.** Discussed above — it causes 25%+ of signup form abandonments. Use a show/hide toggle on a single password field instead.

**4. CAPTCHAs on registration.** CAPTCHAs reduce signups by up to 30%. Use invisible CAPTCHA (reCAPTCHA v3, Cloudflare Turnstile) or honeypot fields instead. If you must show a CAPTCHA, use it only when bot signals are detected, not on every registration.

**5. Mandatory phone number.** Unless your product uses SMS as a core function, requiring a phone number at signup feels invasive. Users know phone numbers are used for marketing calls and SMS spam. Collect it later if needed.

**6. Asking for credit card on free trial signup.** This is a business model decision, not a UX one, but the data is clear: requiring a credit card at signup reduces trial signups by 60-80%. If you do require it, make the value proposition crystal clear and offer a money-back guarantee.

**7. Email-only registration without social login.** Not offering Google/GitHub sign-in in 2025 is leaving easy conversions on the table. Social login reduces signup time from 30-60 seconds to under 5 seconds.

**8. Redirect loops after signup.** User creates account, gets redirected to a "verify email" page, clicks verify link, gets redirected to login page, has to log in again, then finally reaches the dashboard. Every unnecessary redirect is a drop-off point. After verification, land the user directly in the dashboard with an active session.

**9. Password rules displayed only after submission.** Show password requirements immediately when the user focuses the password field. Discovering on submit that you need a special character after you already typed a password is infuriating.

**10. Pre-checked marketing consent.** Violates GDPR, annoys users everywhere else, and erodes trust. Marketing email opt-in must always be unchecked by default.

**11. No "Sign in" link on the registration page.** Returning users land on the signup page all the time. "Already have an account? Sign in" must be visible without scrolling — top or bottom of the form.

**12. Disabling paste on email or password fields.** This breaks password managers, breaks the user's workflow, and has zero security benefit. Never prevent clipboard operations.

**13. Unclear CTA text.** "Submit" tells the user nothing. "Get started", "Create account", "Start free trial", or "Join [Product]" — match the CTA to what happens next.

**14. Showing a pricing page or plan selection during registration.** If the user clicked "Start free trial", they chose the free trial. Do not interrupt their signup to re-show pricing tiers. Plan selection belongs in settings or after the trial.

**15. Requiring terms acceptance before showing the form.** If the user has to check a box or click "Accept" before even seeing the form fields, they may leave. Show the form first, put terms consent at the bottom next to the submit button.

---

## Conversion optimization

### Reducing signup abandonment

The average form abandonment rate is 67%. Here is what moves the needle:

**Field count (the biggest lever):**
- 3 fields: ~25% completion rate
- 4 fields: ~20% completion rate
- Every additional field decreases conversion by roughly 8-15%
- The ideal signup form has exactly 3 fields: name, email, password. Or 2 fields (email, password) with name collected in onboarding.

**Social login (the second biggest lever):**
- Offering Google sign-in can increase signup conversions by 20-30%
- For developer tools, GitHub sign-in converts even better
- Place social options above the email form, not below it. The most frictionless option should be the most visible.

**CTA button text:**
- "Start my free trial" converts up to 90% better than "Start your free trial" (first person vs second person, per Unbounce testing)
- Match the CTA to the value: "Create free account", "Start building", "Get started free" — not "Submit" or "Register"
- Full-width button, primary color, matching input field width

**Trust signals near the form:**
- "No credit card required" — if true, say it. Place it directly below the submit button or in the illustration panel.
- "Free for up to X users" or "14-day free trial"
- "256-bit encryption" or a security badge if handling sensitive data
- Social proof: "Join 10,000+ teams" or a small logo bar of recognizable customers (4-6 logos, grayscale, below the form or in the illustration panel)

**Inline validation (reduces corrections by 22%):**
- Validate email format on blur (when the field loses focus), not on every keystroke
- Show password strength in real-time as the user types
- Show green checkmarks for valid fields — positive reinforcement
- Error messages appear 500ms after the user stops typing, directly below the relevant field
- Never wait until form submission to show validation errors

**Progress indicators (for multi-step only):**
- Show step count: "Step 1 of 3" — reduces anxiety about form length
- Use a visual progress bar or numbered step indicator
- Show step labels: "Account" > "Organization" > "Team" — so the user knows what is ahead

**Mobile optimization:**
- Minimum input height: 48px (some systems use 56px)
- Minimum font: 16px on all inputs (prevents iOS zoom)
- Full-width inputs and buttons — no side margins that shrink tap targets
- Use `inputmode` attributes for appropriate keyboard layouts: `email` for email, `numeric` for phone/OTP
- Context-specific keyboards improve mobile completion by 40%

### What NOT to test (because the answer is already known)

- Do not A/B test "should we add more fields" — fewer fields always wins for signup forms
- Do not test dark patterns (pre-checked marketing consent, hidden terms) — they convert short-term and destroy trust long-term
- Do not test removing social login — it always helps conversion
- Do not test putting the form below the fold — the form must be visible without scrolling

---

## Post-registration transitions

### What happens immediately after clicking "Create account"

The 30 seconds after signup determine whether the user activates or churns. Handle them deliberately:

**1. Button loading state (0-300ms):**
- Button text changes to "Creating account..." with an inline spinner
- Form fields disabled to prevent double-submit
- Same pattern as login button loading state

**2. Account creation response (300ms-1.5s):**
- Server creates the user record, sends verification email (if applicable), creates session
- Target: under 1 second. If your backend is slow, start the redirect while processing completes asynchronously (send the verification email after redirecting, not before).

**3. Redirect (immediate after response):**
- Use `router.replace()` so the user cannot "back" into the registration form after creating an account
- Where to redirect depends on your verification model:

### Verify email screen (blocking model)

If using verify-then-access:
- Clean, focused page: centered card, same layout as registration
- Heading: "Check your email"
- Body: "We sent a verification link to **[email]**. Click the link to activate your account."
- Show the email address in bold so the user can spot typos
- "Resend email" button — disabled for 60 seconds after send, show countdown
- "Use a different email" link — re-opens the email field for correction, resends to new address
- "Didn't receive it?" help text with suggestions: check spam folder, whitelist our domain, contact support
- Auto-detect verification: poll the backend every 5-10 seconds or use WebSocket to detect when the email is verified, then auto-redirect to the dashboard/onboarding. The user should not have to come back to this tab and click something after verifying.

### Welcome email

Send immediately after account creation (regardless of verification model):
- From: a human-sounding name — "[Founder name] from [Product]" or "The [Product] Team"
- Subject: "Welcome to [Product]" or "You're in! Here's how to get started"
- Content: brief welcome, 1-2 key first actions with buttons/links, link to help docs, link to reply for support
- Do not include the user's password in the email. Ever.
- Do not send a separate verification email AND a separate welcome email — combine them if using verify-then-access. One email with both the verification link and the welcome content.

### Redirect to onboarding vs dashboard

**Redirect to onboarding when:**
- First-time user (no previous login)
- You need 1-3 more data points to personalize the experience (role, use case, team size)
- The product requires initial setup before it is useful (connecting an integration, importing data, creating a first project)

**Redirect to dashboard when:**
- The product is immediately usable without setup (note-taking apps, simple tools)
- The user signed up via social login and you have all the data you need
- The user was invited to an existing workspace (the workspace is already configured)

**Onboarding best practices (brief — this topic has its own depth):**
- 1-3 steps maximum. Each step collects one logical unit of information.
- Every step after the first must be skippable. The user should always be able to reach the dashboard.
- Target: deliver first perceived value within 2 minutes of signup. If a new user does not experience an "aha" moment quickly, they churn — usually within 24 hours.
- Use interactive walkthroughs (user performs real actions with guidance) rather than passive product tours. Interactive walkthroughs cut time-to-value by 40% compared to static tours.
- Send a coordinated email sequence alongside in-app onboarding: welcome email (day 0), quick-start tips (day 1), feature highlight (day 3), check-in (day 7).

### The first dashboard load

After registration + onboarding (or direct to dashboard):
- Dashboard shell renders immediately (sidebar, header) — same pattern as post-login
- Data sections show skeletons until content loads
- Empty states are critical: every section that has no data yet should show a clear, actionable empty state — not a blank area, not an error. Example: "No projects yet. Create your first project to get started." with a prominent CTA button.
- Optional: a "Getting started" checklist widget (3-5 items) that persists until completed or dismissed. Items like: "Create your first [X]", "Invite a teammate", "Connect [integration]", "Explore [key feature]."
- The checklist should be non-blocking — it can be a sidebar widget, a banner, or a card, not a modal that prevents dashboard use.

---

## Registration form autocomplete attributes

Get these right for password managers and browser autofill:

```html
<!-- Registration form -->
<input type="text" autocomplete="name" />          <!-- Full name -->
<input type="text" autocomplete="given-name" />     <!-- First name (if split) -->
<input type="text" autocomplete="family-name" />    <!-- Last name (if split) -->
<input type="email" autocomplete="email" />         <!-- Email -->
<input type="password" autocomplete="new-password" /> <!-- Password (new, not current) -->
<input type="text" autocomplete="organization" />   <!-- Company name -->
<input type="tel" autocomplete="tel" />             <!-- Phone number -->
```

The `new-password` value is critical — it signals to password managers that this is a password creation field, triggering password generation suggestions rather than autofill of existing credentials.

---

## Registration page visual design

Follow the same visual design system as the login page (see Login & Auth Pages > Visual design section above). Specific additions for registration:

**Page title:** "Create your account", "Get started", or "Sign up for [Product]" — `text-xl` to `text-2xl` (20-24px), `font-semibold`. Do not use "Register" — it sounds bureaucratic.

**Subtitle:** "Start your free trial" or "No credit card required" — `text-sm` (14px), muted color. Use this space for a value reinforcement, not a generic instruction.

**Sign-in link:** "Already have an account? Sign in" — at the bottom of the form, `text-sm`, link color on "Sign in". This is the mirror of the "Don't have an account? Sign up" link on the login page. Same position, same styling, just reversed.

**CTA button label:** "Create account", "Get started", "Start free trial" — not "Register", "Submit", or "Sign up" (too generic). Match the language used on the landing page CTA that led to this form.

**Social login button text:** "Continue with Google" (not "Sign up with Google") — "Continue" is neutral and works whether the user is creating a new account or linking an existing one.

**All other visual specifications** (typography, spacing, colors, dark mode, accessibility) are identical to the login page. Do not create visual inconsistency between your login and registration pages.
