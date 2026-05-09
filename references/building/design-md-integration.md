# DESIGN.md integration

This file covers how production-ready consumes a project-root [`DESIGN.md`](https://github.com/google-labs-code/design.md) (Google Labs format, open-sourced under Apache 2.0). DESIGN.md is the cross-tool design-system file: YAML frontmatter holds machine-readable design tokens (colors, typography, spacing, radii, components), and the markdown body holds human-readable rationale plus an Agent Prompt Guide section where designers leave explicit instructions for the AI.

Loaded at SKILL.md Step 3 sub-step 3a when `DESIGN.md` is detected at project root. The fallback path (no `DESIGN.md` present) is in `references/ui-design-patterns.md`.

## What DESIGN.md is

A single portable file that tells any coding agent (Claude Code, Cursor, Copilot, Codex, Stitch, others) how the project's UI should look, so the agent stops hallucinating styles and matches the actual brand. The format is hybrid:

```yaml
---
name: Heritage
colors:
  primary: "#1A1C1E"
  secondary: "#6C7278"
  tertiary: "#B8422E"
typography:
  h1: { fontFamily: Public Sans, fontSize: 3rem }
rounded: { sm: 4px, md: 8px }
spacing: { sm: 8px, md: 16px }
---

## Overview
Architectural Minimalism meets Journalistic Gravitas...

## Colors
- **Primary (#1A1C1E):** Deep ink for headlines and core text.

## Agent Prompt Guide
- Use the accent color sparingly; reserve it for the primary CTA only.
- No gradients. Solid fills only.
- ...
```

The YAML frontmatter is the machine-readable contract. The markdown body is the human-readable rationale and the agent guidance. Both matter.

## Detection

production-ready detects `DESIGN.md` at project root in Step 3 before any component code. If detected, sub-step 3a fires and the archetype + 5-decision derivation in sub-step 3b is skipped.

Detection rules:

1. The file is at the repo root (not nested in `docs/` or `design/`).
2. The file has YAML frontmatter delimited by `---` lines, parseable as YAML, containing at least a `name` field.
3. If a file named `DESIGN.md` exists but does not parse as the Google Labs format (e.g., it's a generic architecture doc carrying the same filename), production-ready surfaces the conflict to the user and asks whether to (a) treat it as the design system anyway, (b) rename one of the two, or (c) treat it as a generic doc and run sub-step 3b.

## The three consumption paths

In order of preference. Pick one; do not mix.

### Path 1: DTCG export (preferred)

```bash
npx @google/design.md export --format dtcg DESIGN.md > tokens.json
```

Produces a [W3C Design Tokens Community Group](https://www.designtokens.org/) tokens.json. This is the format Claude and Codex generate against natively, the format Style Dictionary consumes, and the format that survives framework migrations (the same tokens.json works for Tailwind v4, vanilla CSS, React Native, iOS, Android).

Wire-in:

- **Tailwind v4 project:** the DTCG-to-Tailwind bridge is `@import` plus the `@theme` directive; Tailwind v4 reads the tokens.json natively.
- **Style Dictionary project:** add tokens.json as a source; the existing build emits per-platform variables.
- **Vanilla CSS / framework-agnostic project:** use Style Dictionary or the `@google/design.md export --format css-vars` shorthand to emit a `:root { --color-primary: ... }` block.

### Path 2: Tailwind v4 export

If the project is on Tailwind v4 and the user does not want a tokens.json round-trip:

```bash
npx @google/design.md export --format css-tailwind DESIGN.md > theme.css
```

Produces a Tailwind v4 `@theme` block. Import in the project's global stylesheet:

```css
@import "tailwindcss";
@import "./theme.css";
```

Tailwind v4 wires the rest. The exported file replaces (does not augment) the project's existing theme tokens.

### Path 3: Direct YAML read

If neither export fits the framework (an exotic framework, or a project without npx), parse the YAML frontmatter and emit the CSS variable block manually:

```css
:root {
  --color-primary: #1A1C1E;
  --color-secondary: #6C7278;
  --color-tertiary: #B8422E;
  --font-h1-family: "Public Sans";
  --font-h1-size: 3rem;
  --rounded-sm: 4px;
  --rounded-md: 8px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
}
```

Keep the variable names matching the frontmatter keys (kebab-case the dotted paths). This keeps round-trip consistency: a future agent can re-derive the YAML from the CSS by reversing the mapping.

This path loses the linter (run it separately on the source `DESIGN.md`); it loses the diff command; and it is the slowest to maintain. Use it only when the export paths are unavailable.

## Lint and validate before component code

After tokens are wired, run the linter:

```bash
npx @google/design.md lint DESIGN.md
```

The seven rules:

1. **Token references resolve.** Every `{tokens.colors.primary}`-style reference points at a real key.
2. **WCAG AA contrast.** Every foreground/background pair stated in the file (or implied by the components section) hits 4.5:1 minimum for body text.
3. **WCAG AAA contrast.** Optional, opt-in via the `--aaa` flag. 7:1 minimum.
4. **Color format consistency.** All colors are the same format (all hex, or all hsl); no mixing.
5. **Typography scale present.** A typography section exists with at least one heading and one body style.
6. **Spacing scale monotonic.** Spacing tokens increase consistently (no `sm: 16px, md: 8px` typos).
7. **Required sections present.** `name`, `colors`, `typography` are mandatory.

Any failure blocks the slice. Fix the design system, not the components. **Do not work around a contrast failure by hand-tuning a single component's color**; that's how you ship dashboards where the design system says one thing and the components say another.

## Consume the Agent Prompt Guide

If the markdown body has a `## Agent Prompt Guide` section (or `## Prompt Guide`, or `## AI Guidance`; the format is permissive), read it and treat each bullet as a have-not. The guide is designer-authored intent that the YAML cannot express. Examples:

- "Use the accent color sparingly; reserve it for the primary CTA only." -> only the single primary CTA per view uses `--color-accent`; secondary buttons fall back to `--color-secondary`.
- "No gradients. Solid fills only." -> no `linear-gradient`, no `radial-gradient`, no Tailwind `bg-gradient-*` utility, anywhere in the slice.
- "Type sizes in steps of 1.25x; never improvise." -> any new typography variant must use `--font-size-{token}`, not a hand-typed `font-size: 1.18rem`.

Record the prompt-guide rules in the architecture note alongside the tokens. They are part of the visual identity contract.

## Practical caveats

**Token discipline depends on the model.** Claude (Sonnet 4.6 / Opus 4.6 / 4.7) and Codex/GPT-5-class models follow token references reliably. Smaller or older models drift and start inventing hex codes anyway. If the harness driving the slice is a smaller model, treat the linter as the enforcement layer (it runs locally; it is deterministic; it does not depend on the model's compliance).

**The linter and contrast checker are local CLI tools, not LLM checks.** WCAG validation is deterministic regardless of which agent wrote the code. Wire `npx @google/design.md lint DESIGN.md` into the project's pre-commit hook (or CI) so token regressions block at the boundary, not at code review.

**The diff command catches token-level regressions.** When the design system changes:

```bash
npx @google/design.md diff DESIGN.md@HEAD~1 DESIGN.md
```

Surfaces token-level changes (a color renamed, a spacing scale shifted) so reviewers see the design-system delta separately from the component-code delta. Adopt this in PRs that touch `DESIGN.md`.

**`DESIGN.md` does not replace `AGENTS.md` or `CLAUDE.md`.** Those are agent briefs (project conventions, build commands, forbidden actions). `DESIGN.md` is the design system. The recommended pattern: keep `DESIGN.md` at project root and add a one-liner in `AGENTS.md` or `CLAUDE.md`: "Always refer to `DESIGN.md` when generating UI components. Use the tokens in the YAML frontmatter for colors, typography, spacing, and radii." On Claude Code, the cleaner shape is `@DESIGN.md` from `CLAUDE.md` (Claude Code resolves `@<file>` imports up to five levels deep).

**The format is alpha as of late April 2026.** Frontmatter keys may shift. Pin `@google/design.md` to a known-good version (`npx @google/design.md@x.y.z`) for repeatable exports.

## Scaffold-when-absent

If sub-step 3b fired (no `DESIGN.md` was detected) and the slice has settled on tokens, scaffold a `DESIGN.md` from those tokens before declaring Step 3 complete. Two paths:

1. **CLI init.** `npx @google/design.md init` produces a starter file with placeholder values; fill in the tokens from the architecture note's visual identity section.
2. **Hand authorship from a reference.** Pick a starter from [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) (69+ files reverse-engineered from Stripe, Vercel, Linear, Notion, Anthropic, xAI, others) closest to the chosen archetype, then edit the tokens to match.
3. **Stitch import.** [Google Labs Stitch](https://stitch.google.com) generates a `DESIGN.md` from a text description or by extracting it from any URL the user names. Useful when the visual identity is "make it look like X."

After scaffolding, run the lint, then move to Step 4. The next agent (any model, any harness) consuming this project starts at sub-step 3a, not 3b.

## Cross-references

- [DESIGN.md spec](https://github.com/google-labs-code/design.md) - the format, governance, contribution
- [agentskills.io](https://agentskills.io) - the Agent Skills standard sibling for SKILL.md
- [agents.md](https://agents.md/) - the cross-tool agent-brief standard sibling for AGENTS.md
- [W3C DTCG](https://www.designtokens.org/) - the design tokens format DESIGN.md exports to
- `references/ui-design-patterns.md` - the fallback path when no DESIGN.md exists
- `references/accessibility-deep-dive.md` - WCAG context the linter validates against
- `references/dark-mode-deep-dive.md` - dark-variant handling within the DESIGN.md token set
