# Login & Auth Pages

This file covers the design and UX of login pages and the full login-to-dashboard journey. The authentication *logic* (hashing, sessions, tokens, RBAC) is in `auth-and-rbac.md`. The loading states and skeletons are in `states-and-feedback.md`. This file is about *what the user sees* — the login screen, the auth flow, the transition into the dashboard, and all the states in between.

The single most important principle: **fast in, fast working.** Every second between "I want to use the dashboard" and "I'm using the dashboard" is a cost. Minimize screens, minimize fields, minimize thinking.

**Canonical scope:** login page UX, password reset, email verification, MFA screens, social login buttons. Sign-up and registration UX lives in `registration-pages.md`. **See also:** `registration-pages.md` for sign-up flows, `auth-and-rbac.md` for auth logic and RBAC, `security-deep-dive.md` for session security, `states-and-feedback.md` for loading and error state patterns.

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
