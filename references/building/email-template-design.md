# Email Template Design

This file covers the visual and structural layer of transactional and marketing email — the HTML, CSS, responsive techniques, dark mode handling, CTA buttons, accessibility, testing, and tooling that make emails render correctly across every client. The notification pipeline, delivery tracking, and preference architecture are in `notifications-and-email.md`; this file is about what the email looks like and how to build it.

Email is not the web. You're writing HTML for 30+ rendering engines, several of which are from 2007. Every technique here exists because something is broken somewhere.

---

## HTML email fundamentals

### Why tables in 2025-2026

Outlook (2016, 2019, 2021, Microsoft 365 desktop for Windows) uses Microsoft Word's rendering engine. Word has zero support for CSS flexbox, grid, or float-based layouts. Tables are the only layout mechanism that works everywhere.

Use `<table>` for structure. Use `<div>` only for non-layout content blocks that don't need to sit side-by-side. Never nest deeper than 3-4 table levels — rendering becomes unreliable and debugging is miserable.

### Inline styles are mandatory

Gmail (web and mobile) strips `<style>` blocks from the `<head>` entirely. The only reliable way to style elements is inline `style` attributes on every element.

Use `<style>` in `<head>` only for media queries and progressive enhancement — clients that strip it will still get the inline-styled version.

### CSS support matrix

| CSS Property | Gmail | Outlook (Word) | Apple Mail | Yahoo |
|---|---|---|---|---|
| `background-color` | Yes | Yes | Yes | Yes |
| `color`, `font-size`, `font-family` | Yes | Yes | Yes | Yes |
| `padding` | Yes | Yes (tables only) | Yes | Yes |
| `margin` | Partial | Partial | Yes | Partial |
| `border`, `border-radius` | Yes | No (`border-radius`) | Yes | Yes |
| `width`, `max-width` | Yes | `max-width` ignored | Yes | Yes |
| `display: flex` | No | No | Yes | No |
| `display: grid` | No | No | Yes | No |
| `float` | No (stripped) | No | Yes | Yes |
| `position` | No | No | Yes | No |
| `@media` queries | No (web), Yes (app) | No | Yes | Partial |
| `background-image` | Yes | VML only | Yes | Yes |
| `box-shadow` | Yes | No | Yes | Yes |

**Safe everywhere:** `background-color`, `color`, `font-*`, `text-align`, `vertical-align`, `border` (not radius), `padding` (on `<td>`), `width` (explicit px), `line-height`.

**Never use in email:** flexbox, grid, CSS custom properties, `calc()`, `position`, `float`, `object-fit`, `:root`, CSS animations.

### HTML attributes over CSS

Use HTML attributes where supported — they have better compatibility than CSS equivalents:

```html
<!-- Prefer this -->
<table width="600" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr>
    <td align="center" valign="top" bgcolor="#ffffff">

<!-- Over this -->
<table style="width:600px; border-collapse:collapse; margin:0 auto;">
  <tr>
    <td style="text-align:center; vertical-align:top; background-color:#ffffff;">
```

Use both for safety. The HTML attribute is the floor; the inline style is the upgrade.

---

## Email template structure

### Standard layout skeleton

```html
<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <!--[if mso]>
  <xml>
    <o:OfficeDocumentSettings>
      <o:PixelsPerInch>96</o:PixelsPerInch>
    </o:OfficeDocumentSettings>
  </xml>
  <![endif]-->
  <title>Email Subject</title>
  <style>
    /* Media queries for clients that support them */
    @media only screen and (max-width: 600px) {
      .email-container { width: 100% !important; }
      .stack-column { display: block !important; width: 100% !important; }
    }
  </style>
</head>
<body style="margin:0; padding:0; background-color:#f4f4f5; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;">

  <!-- Preheader (hidden preview text) -->
  <div style="display:none; max-height:0; overflow:hidden; font-size:1px; line-height:1px; color:#f4f4f5;">
    Your preview text here (40-100 chars). &#847; &#847; &#847; &#847; &#847;
  </div>

  <!-- Email wrapper -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#f4f4f5">
    <tr>
      <td align="center" style="padding: 20px 10px;">

        <!-- Email container: 600px max -->
        <table role="presentation" class="email-container" width="600" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff" style="max-width:600px; border-radius:8px; overflow:hidden;">

          <!-- Header with logo -->
          <tr>
            <td align="center" style="padding: 32px 40px 24px;">
              <img src="https://example.com/logo.png" alt="Company Name" width="140" height="40" style="display:block; border:0;">
            </td>
          </tr>

          <!-- Body content -->
          <tr>
            <td style="padding: 0 40px 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size:16px; line-height:1.5; color:#1a1a1a;">
              <h1 style="margin:0 0 16px; font-size:24px; font-weight:700; line-height:1.3; color:#09090b;">
                Heading
              </h1>
              <p style="margin:0 0 16px;">Body text here.</p>
            </td>
          </tr>

          <!-- CTA button -->
          <tr>
            <td align="center" style="padding: 0 40px 32px;">
              <!-- Bulletproof button (see CTA section) -->
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 40px; background-color:#fafafa; border-top: 1px solid #e4e4e7; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size:12px; line-height:1.5; color:#71717a;">
              <p style="margin:0 0 8px;">Company Name · 123 Street · City, ST 12345</p>
              <p style="margin:0;">
                <a href="{{preferences_url}}" style="color:#71717a; text-decoration:underline;">Email preferences</a> ·
                <a href="{{unsubscribe_url}}" style="color:#71717a; text-decoration:underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

### Widths

- **Container:** 600px max. This is the standard — fits all clients without horizontal scroll.
- **Content padding:** 40px sides on desktop (520px content), 20px on mobile (shrink via media query or fluid technique).
- **Mobile:** 480px design target, but use 100% width so it fills any screen.
- **Images:** Always set explicit `width` and `height` attributes. Use `style="display:block; max-width:100%; height:auto;"` for fluid scaling.

### Preheader text

The preview text shown after the subject line in inbox views. Place immediately after `<body>`, hidden with CSS.

```html
<div style="display:none; max-height:0; overflow:hidden; mso-hide:all; font-size:1px; line-height:1px; color:#f4f4f5;">
  Preheader content here.
  <!-- Zero-width whitespace to prevent email client from pulling body text -->
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
</div>
```

**Length:** 40-100 characters. Front-load the message — mobile shows ~40 chars, desktop ~100.

**Note:** Apple Mail iOS 18.2+ replaces preheaders with AI-generated summaries. Preheaders still matter for Gmail, Outlook, Yahoo, and older Apple Mail. Write good opening sentences as a fallback.

---

## Responsive email

### Fluid hybrid approach

The recommended technique for 2025-2026. Combines fluid percentage widths with `max-width` constraints. Works without media queries — meaning it works in Gmail (web), which strips `<style>` blocks.

**Principle:** Elements flow at 100% width by default (mobile). `max-width` constrains them on desktop. Outlook ignores `max-width`, so you wrap with conditional comments for a fixed-width fallback.

```html
<!-- Two-column layout: fluid hybrid -->

<!--[if mso]>
<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" align="center">
<tr>
<td width="290">
<![endif]-->

<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td style="padding:20px; font-size:16px; line-height:1.5; color:#1a1a1a;">
        Column 1 content
      </td>
    </tr>
  </table>
</div>

<!--[if mso]>
</td>
<td width="290">
<![endif]-->

<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td style="padding:20px; font-size:16px; line-height:1.5; color:#1a1a1a;">
        Column 2 content
      </td>
    </tr>
  </table>
</div>

<!--[if mso]>
</td>
</tr>
</table>
<![endif]-->
```

**How it works:**
1. `display:inline-block` lets divs sit side-by-side when space allows.
2. `width:100%` makes them stack on narrow screens.
3. `max-width:290px` constrains them on desktop.
4. The `<!--[if mso]>` wrapper gives Outlook a fixed table layout (Outlook ignores `max-width` and `display:inline-block`).

### Media query enhancements

For clients that support `<style>` blocks (Apple Mail, Outlook.com, Yahoo, Gmail app):

```css
@media only screen and (max-width: 600px) {
  .email-container {
    width: 100% !important;
    max-width: 100% !important;
  }
  .stack-column {
    display: block !important;
    width: 100% !important;
    max-width: 100% !important;
  }
  .mobile-padding {
    padding-left: 20px !important;
    padding-right: 20px !important;
  }
  .mobile-hide {
    display: none !important;
    max-height: 0 !important;
    overflow: hidden !important;
  }
  .mobile-full-width {
    width: 100% !important;
    height: auto !important;
  }
}
```

### Mobile rules

- **Single column** on screens under 480px.
- **Touch targets:** min 44px height for buttons and links.
- **Font sizes:** 16px minimum body, 22px minimum headings. Don't let mobile scale text smaller.
- **Padding:** 20px sides on mobile (not 40px desktop padding).
- **Images:** fluid, max-width 100%, height auto.

---

## Dark mode in email

### How email clients implement dark mode

Email clients handle dark mode in three distinct ways. You cannot choose which method a client uses.

**No color changes (client respects your design):**
Apple Mail (when `color-scheme: light dark` meta tag is present and you provide dark-mode styles).

**Partial inversion (client modifies some colors):**
Outlook.com, Outlook apps. Inverts background and text colors on elements it detects as "light." Preserves images and elements it can't easily invert.

**Full inversion (client rewrites everything):**
Gmail (Android/iOS in dark mode), Outlook (Windows desktop). Applies aggressive color transformations. You have very limited control.

### Targeting dark mode in email

```html
<head>
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <style>
    :root { color-scheme: light dark; }

    /* For Apple Mail, Outlook.com, and clients that support prefers-color-scheme */
    @media (prefers-color-scheme: dark) {
      .dark-bg { background-color: #1a1a1a !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-secondary { color: #a1a1aa !important; }
      .dark-border { border-color: #3f3f46 !important; }
    }

    /* For Outlook.com (data attribute targeting) */
    [data-ogsc] .dark-bg { background-color: #1a1a1a !important; }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsb] .dark-bg { background-color: #1a1a1a !important; }
  </style>
</head>
```

### Image strategies for dark mode

**Problem:** Logos and images with white or transparent backgrounds look harsh on dark surfaces.

**Solutions:**

1. **Transparent PNGs with padding/glow:** Add a subtle transparent padding or soft drop shadow around logos so they don't touch the dark background directly.

2. **Swap images for dark mode:**
```html
<!-- Light mode image (hidden in dark) -->
<img src="logo-dark-on-light.png" alt="Company" class="dark-hide"
     style="display:block; max-width:140px;">

<!-- Dark mode image (hidden in light, shown in dark) -->
<div class="dark-show" style="display:none; max-height:0; overflow:hidden;">
  <img src="logo-light-on-dark.png" alt="Company"
       style="display:block; max-width:140px;">
</div>

<style>
  @media (prefers-color-scheme: dark) {
    .dark-hide { display: none !important; max-height: 0 !important; }
    .dark-show { display: block !important; max-height: none !important; }
  }
</style>
```

3. **Add a border to images:** For clients that force dark mode and can't be targeted with CSS:
```html
<img src="logo.png" alt="Company" style="display:block; border: 1px solid #e4e4e7; border-radius:4px;">
```
The border is barely visible on light backgrounds but provides definition on dark.

4. **Avoid pure white (#ffffff) backgrounds in images.** Use near-white (#fafafa or #f5f5f5) — forced inversion often skips near-white values, producing less jarring results.

### Dark mode CTA button colors

Buttons with very dark backgrounds may become invisible on forced dark mode. Use mid-tone brand colors (not near-black). Test buttons on both dark and light backgrounds.

---

## Email types for SaaS

### Transactional

Must reach the inbox. Use your primary sending domain/provider. Never batch these.

| Template | Trigger | Key content |
|---|---|---|
| **Welcome** | Account creation | Greeting, getting started steps, primary CTA to dashboard |
| **Email verification** | Signup / email change | Verification link (expires 24h), explain why |
| **Password reset** | User request | Reset link (expires 1h), security notice if not requested |
| **Magic link** | Login attempt | Login link (expires 10min), device/IP context |
| **Invoice** | Payment processed | Amount, date, line items, PDF attachment or link |
| **Receipt** | Payment confirmed | Confirmation number, what was purchased, support link |
| **Account change** | Settings modified | What changed, when, revert link for security |

### Notification

Can be batched into digests. Honor user preferences per type.

| Template | Trigger | Key content |
|---|---|---|
| **Activity alert** | Someone interacted | Who did what, where, link to context |
| **Assignment** | Task/item assigned | What, by whom, due date, link |
| **Mention** | @mentioned in comment | Context snippet, link to thread |
| **Daily/weekly digest** | Cron schedule | Grouped summaries, counts, top-level links |
| **Threshold alert** | Metric exceeded | What metric, current value, threshold, link to dashboard |

### Marketing

Use a separate subdomain (`marketing.yourdomain.com`) to isolate sending reputation. Must include one-click unsubscribe.

| Template | Trigger | Key content |
|---|---|---|
| **Product update** | Feature release | What's new, screenshot/GIF, CTA to try it |
| **Newsletter** | Schedule | Curated content sections, multiple links |
| **Onboarding drip** | Days after signup | Progressive feature introduction, one CTA per email |
| **Re-engagement** | Inactivity (30/60/90 days) | Value reminder, what they're missing, CTA to return |
| **NPS/survey** | Post-milestone | 1-click rating, brief survey link |

---

## CTA buttons in email

### Bulletproof button pattern

Padding-based, not image-based. Works in all clients including Outlook with VML fallback.

```html
<!-- Bulletproof button with VML fallback for Outlook -->
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr>
    <td align="center" bgcolor="#2563eb" style="border-radius:6px;">
      <!--[if mso]>
      <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml"
                   xmlns:w="urn:schemas-microsoft-com:office:word"
                   href="https://example.com/action"
                   style="height:48px; v-text-anchor:middle; width:240px;"
                   arcsize="13%"
                   strokecolor="#2563eb"
                   fillcolor="#2563eb">
        <w:anchorlock/>
        <center style="color:#ffffff; font-family:Helvetica,Arial,sans-serif; font-size:16px; font-weight:bold;">
          Get Started
        </center>
      </v:roundrect>
      <![endif]-->
      <!--[if !mso]><!-->
      <a href="https://example.com/action"
         target="_blank"
         style="display:inline-block; padding:14px 40px; background-color:#2563eb; color:#ffffff; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; font-size:16px; font-weight:600; text-decoration:none; border-radius:6px; line-height:1; text-align:center;">
        Get Started
      </a>
      <!--<![endif]-->
    </td>
  </tr>
</table>
```

### Button specifications

| Property | Value | Reason |
|---|---|---|
| Min height | 44px (48px recommended) | Touch target accessibility |
| Width | 200-300px, or auto with 32-48px horizontal padding | Readable, tappable |
| Font size | 16px minimum | Legible on mobile |
| Font weight | 600 (semi-bold) or 700 (bold) | Visual prominence |
| Border radius | 4-8px | Modern look; Outlook ignores it, VML `arcsize` handles it |
| Color contrast | 4.5:1 minimum (text vs background) | WCAG AA |

### Button rules

- **One primary CTA per email.** If you need a secondary action, use a text link below the button.
- **Action-oriented label.** "Get Started," "View Invoice," "Reset Password" — not "Click Here" or "Submit."
- **Full-width on mobile.** Add a media query class to make buttons 100% width on small screens.
- **Dark mode caution.** Some clients invert button colors. Test with mid-range brand colors. Avoid very dark button backgrounds that become invisible on forced dark mode.

### Ghost/outline button alternative (secondary CTA)

```html
<a href="https://example.com/secondary"
   style="display:inline-block; padding:12px 32px; border:2px solid #2563eb; color:#2563eb; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; font-size:14px; font-weight:600; text-decoration:none; border-radius:6px;">
  Learn More
</a>
```

---

## Email testing

### Tools

| Tool | What it does | Cost (2025) |
|---|---|---|
| **Litmus** | Preview in 90+ clients, spam testing, analytics, accessibility checks | $500+/mo (enterprise positioning after 2025 price increase) |
| **Email on Acid** | Preview in 70+ clients, spam testing, accessibility checks | ~$74-134/mo (remained affordable) |
| **mail-tester.com** | Free spam score check — send an email to their address, get a score | Free (10 tests/day) |
| **Mailtrap** | Email testing sandbox, preview, spam analysis | Free tier + paid |
| **Postmark DMARC Digests** | Free weekly DMARC reports | Free |

### Testing checklist

**Per-client rendering (minimum set):**
- Gmail (web) — strips `<style>`, inline only
- Gmail (Android/iOS app) — supports `<style>`, media queries
- Outlook 2019/365 (Windows) — Word rendering engine
- Outlook.com (web) — modern renderer, partial dark mode
- Apple Mail (macOS/iOS) — best CSS support, full dark mode
- Yahoo Mail — strips some CSS, partial media query support

**Per-email checks:**
- [ ] Subject line and preheader display correctly
- [ ] Images load with correct dimensions; alt text shows when blocked
- [ ] All links work and point to correct URLs (including UTM params)
- [ ] CTA button is tappable (44px+ height) and contrasts properly
- [ ] Unsubscribe link present and functional
- [ ] Footer contains physical address (CAN-SPAM requirement)
- [ ] Responsive: stacks to single column on mobile widths
- [ ] Dark mode: logo, images, buttons, text all remain readable
- [ ] Total HTML size under 102KB (Gmail clips larger emails)
- [ ] No broken conditional comments (test Outlook specifically)

### Spam score checking

Run every template through mail-tester.com before production use. Target a score of 9+/10. Common issues that lower the score:
- Missing SPF/DKIM/DMARC
- URL shorteners in links
- Excessive image-to-text ratio
- Spammy words in subject or body
- Missing unsubscribe mechanism
- Broken HTML

---

## Email frameworks and tools

### Framework comparison

| Framework | Syntax | Best for | Output quality |
|---|---|---|---|
| **MJML** | Custom XML (`<mj-section>`, `<mj-column>`) | Broadest client compatibility, non-React teams | Excellent — battle-tested table output |
| **React Email** | React/JSX components | React/TypeScript teams, programmatic templates | Good — improving, not as battle-tested as MJML |
| **Maizzle** | HTML + Tailwind classes | Tailwind teams, hand-tuned control | Excellent — compiles Tailwind to inline styles |

### MJML example

```xml
<mjml>
  <mj-body>
    <mj-section background-color="#ffffff">
      <mj-column>
        <mj-image src="logo.png" alt="Company" width="140px" />
        <mj-text font-size="16px" line-height="1.5" color="#1a1a1a">
          <h1 style="font-size:24px; margin:0 0 16px;">Welcome aboard</h1>
          <p>Your account is ready.</p>
        </mj-text>
        <mj-button background-color="#2563eb" color="#ffffff" font-size="16px"
                   font-weight="600" border-radius="6px" inner-padding="14px 40px"
                   href="https://example.com/dashboard">
          Go to Dashboard
        </mj-button>
      </mj-column>
    </mj-section>
  </mj-body>
</mjml>
```

MJML compiles this to table-based HTML with inline styles and Outlook conditionals. VS Code extension provides live preview.

### React Email example

```tsx
import { Html, Head, Body, Container, Section, Text, Button, Img } from '@react-email/components';

export default function WelcomeEmail({ userName }: { userName: string }) {
  return (
    <Html>
      <Head />
      <Body style={{ backgroundColor: '#f4f4f5', margin: 0, padding: 0 }}>
        <Container style={{ maxWidth: 600, margin: '0 auto', backgroundColor: '#ffffff', borderRadius: 8 }}>
          <Section style={{ padding: '32px 40px' }}>
            <Img src="https://example.com/logo.png" alt="Company" width={140} height={40} />
          </Section>
          <Section style={{ padding: '0 40px 24px' }}>
            <Text style={{ fontSize: 24, fontWeight: 700, color: '#09090b' }}>
              Welcome, {userName}
            </Text>
            <Text style={{ fontSize: 16, lineHeight: '1.5', color: '#1a1a1a' }}>
              Your account is ready.
            </Text>
          </Section>
          <Section style={{ padding: '0 40px 32px', textAlign: 'center' }}>
            <Button href="https://example.com/dashboard"
                    style={{ backgroundColor: '#2563eb', color: '#ffffff', padding: '14px 40px',
                             borderRadius: 6, fontSize: 16, fontWeight: 600, textDecoration: 'none' }}>
              Go to Dashboard
            </Button>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}
```

React Email has a dev server (`npx email dev`) with hot reload and per-client previews. Pairs naturally with Resend for sending.

### When to use what

- **Hand-coded HTML:** You need absolute control, are debugging a specific client, or building a one-off template.
- **MJML:** You need the widest client support and don't use React. The XML syntax is approachable for designers.
- **React Email:** Your app is React/Next.js, you want TypeScript type-checking on template props, and you want hot-reload preview during development.
- **Maizzle:** Your team thinks in Tailwind. You want to use the same utility-class mental model across web and email.

### Sending services

| Service | Strengths |
|---|---|
| **Resend** | Modern DX, React Email native, simple API, good for startups |
| **Postmark** | Best deliverability for transactional email, fast delivery, excellent docs |
| **SendGrid** | High volume, marketing + transactional, event webhooks |
| **Amazon SES** | Cheapest at scale ($0.10/1000 emails), requires more setup |
| **Mailgun** | Good API, flexible routing, reasonable pricing |

---

## Accessibility in email

### Requirements

These are not optional. 99.89% of HTML emails have serious accessibility issues — don't be in that statistic.

**Images:**
- Every `<img>` needs an `alt` attribute. Informative images get descriptive alt text. Decorative images (spacers, dividers) get `alt=""` (empty, not omitted).
- Don't use "image of" or "picture of" — screen readers already announce it's an image.
- Always set `width` and `height` attributes so layout doesn't shift when images are blocked.

**Headings:**
- Use semantic heading tags (`<h1>` through `<h3>`). One `<h1>` per email.
- Don't skip levels (h1 > h3). Screen readers use headings to navigate.

**Links:**
- Descriptive link text. "View your invoice" — not "Click here" or "Read more."
- Underline links in body text (don't rely on color alone).
- Ensure links have sufficient color contrast against surrounding text.

**Color and contrast:**
- 4.5:1 contrast ratio for normal text (WCAG AA).
- 3:1 for large text (18px bold / 24px regular).
- Never convey information through color alone. Pair with text labels, icons, or patterns.

**Font sizes:**
- Body text: 14px minimum, 16px recommended.
- Headlines: 22px minimum.
- Footer/legal: 12px minimum.

**Structure:**
- Use `role="presentation"` on all layout tables so screen readers don't announce them as data tables.
- Use `lang` attribute on `<html>` tag.
- Logical reading order — the source order should match visual order.

---

## Deliverability basics

### Authentication (required — not optional)

**SPF (Sender Policy Framework):**
DNS TXT record listing which servers can send email for your domain. Without it, any server can forge your domain.

```
v=spf1 include:_spf.google.com include:sendgrid.net include:amazonses.com -all
```

**DKIM (DomainKeys Identified Mail):**
Cryptographic signature on every email. Receiving servers verify the signature against a public key in your DNS. Proves the email was sent by an authorized sender and wasn't tampered with.

**DMARC (Domain-based Message Authentication, Reporting, and Conformance):**
Policy telling receivers what to do when SPF/DKIM fail. Start with monitoring, then tighten.

```
# Start here — monitor only
v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com;

# After verification — quarantine failures
v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com;

# Full protection — reject failures
v=DMARC1; p=reject; rua=mailto:dmarc@yourdomain.com;
```

### Gmail/Yahoo/Microsoft requirements (enforced 2024-2025)

All senders: SPF or DKIM authentication required.

Bulk senders (5,000+ emails/day):
- SPF AND DKIM AND DMARC (minimum `p=none`).
- One-click unsubscribe via `List-Unsubscribe` and `List-Unsubscribe-Post` headers (RFC 8058).
- Honor unsubscribe within 2 days.
- Spam complaint rate below 0.3% (target <0.1%).
- Valid forward and reverse DNS.
- Non-compliant emails face temporary or permanent rejection since November 2025.

Microsoft Outlook joined these requirements in May 2025.

### Domain warm-up

New domains or IPs have no sender reputation. ISPs throttle unknown senders.

| Week | Daily volume | Notes |
|---|---|---|
| 1 | 50-100 | Send to most engaged users only |
| 2 | 200-500 | Monitor bounce rates carefully |
| 3 | 500-1,000 | Check Postmaster Tools for reputation |
| 4 | 1,000-5,000 | Gradually increase |
| 5+ | Scale to target | Maintain consistent volume |

**Rules:** Send to engaged users first (recent openers/clickers). Don't import a cold list and blast it. Monitor Google Postmaster Tools and Yahoo Sender Hub daily during warm-up.

### List hygiene

- Remove hard bounces immediately (first occurrence).
- Suppress soft bounces after 3 consecutive failures.
- Sunset unengaged subscribers (no opens in 90 days) — move to re-engagement campaign or remove.
- Validate email addresses at signup (syntax + MX record check). Libraries: `email-validator` (Python), `deep-email-validator` (Node).
- Never buy or rent email lists.

---

## Don'ts

- **Don't use CSS flexbox or grid in email.** No Outlook support, partial support elsewhere. Tables only.
- **Don't rely on `<style>` blocks.** Gmail web strips them. Inline everything critical.
- **Don't use CSS custom properties (variables).** Zero support across email clients.
- **Don't skip the Outlook VML fallback for CTA buttons.** Padding-based buttons break in Word rendering. VML is ugly to write but necessary.
- **Don't use images for text.** Unscalable, invisible when images are blocked, not accessible.
- **Don't exceed 102KB HTML size.** Gmail clips larger emails with a "View entire message" link — most users won't click it.
- **Don't send without testing in at least Gmail, Outlook, and Apple Mail.** These three cover the major rendering engines.
- **Don't use URL shorteners in emails.** Spam filters flag them aggressively.
- **Don't skip preheader text.** Without it, email clients pull the first text they find — often "View in browser" or alt text.
- **Don't use a pure black background for dark mode email styles.** Use #1a1a1a or similar. Matches how dark mode apps actually look.
