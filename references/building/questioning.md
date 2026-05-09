# Adaptive Questioning for Project Detection

When filesystem auto-detection is insufficient — the directory is empty, config files are ambiguous, or the user's intent doesn't match the detected stack — use these structured questions to determine project type, stack, and stage.

## When to Use This Reference

- **Empty directory** — no config files to detect from
- **Ambiguous codebase** — multiple stacks present (e.g., `package.json` + `pyproject.toml`)
- **User intent mismatch** — detected stack doesn't match what the user described
- **Greenfield with no context** — user said "set up my repo" with no further detail

If auto-detection succeeds (clear stack indicators, unambiguous project type), skip this reference entirely. Don't ask questions the filesystem already answered.

## Question Strategy

**Ask at most 3 questions.** Each question should eliminate multiple possibilities. Don't interrogate — collaborate.

**Order matters:**
1. What is this? (project type)
2. What's it built with? (stack — skip if detected)
3. Who's it for? (stage + audience)

## Question 1: Project Type

Ask when the project type can't be inferred from the directory structure.

**Signals to look for first** (before asking):

| Signal | Inferred type |
|---|---|
| `bin/` or CLI-related deps | CLI tool |
| `src/lib.rs` or `src/index.ts` with no `app/` | Library |
| `app/` or `pages/` or `routes/` | Web app |
| `Dockerfile` + `api/` or `routes/` | API / Microservice |
| `android/` + `ios/` | Mobile app |
| `electron.js` or `tauri.conf.json` | Desktop app |
| `terraform/` or `ansible/` or `k8s/` | DevOps / IaC |
| `notebooks/` or `models/` or `data/` | Data / ML |
| `packages/` or `apps/` with workspace config | Monorepo |
| `docusaurus.config.js` or `mkdocs.yml` | Documentation site |

**If signals are ambiguous or absent, ask:**

```
What type of project is this?
- Library / SDK — published package others install
- CLI tool — command-line application
- Web app — SaaS, website, or web service
- API / Microservice — backend service with API endpoints
- Other — [describe]
```

Use AskUserQuestion with the 4 most likely options based on any partial signals. The user can always select "Other."

## Question 2: Stack

Ask only if auto-detection failed. If `package.json` exists → Node/TS. If `pyproject.toml` exists → Python. Don't ask what you already know.

**When multiple config files exist:**

```
I see both package.json and pyproject.toml. Which is the primary stack?
- JavaScript / TypeScript — Node.js ecosystem
- Python — Python ecosystem
- Both (polyglot) — configure tooling for both
```

**When no config files exist:**

```
What language/framework will this use?
- JavaScript / TypeScript
- Python
- Go
- Rust
- Other — [specify]
```

Limit to 4 options based on the project type selected in Q1. A CLI tool is most likely Go/Rust/Node. A web app is most likely JS/TS/Python. A data project is most likely Python.

## Question 3: Stage & Audience

Ask when you can't infer from the codebase size and git history.

**Signals to look for first:**

| Signal | Inferred stage |
|---|---|
| 0-5 commits, 1 contributor | MVP |
| 10-100 commits, 2-5 contributors | Growth |
| 100+ commits, 5+ contributors, CI exists | Enterprise |
| No `.github/` or `.gitlab/` | Likely MVP or internal |
| CONTRIBUTING.md exists | Growth or above |
| SECURITY.md exists | Enterprise |

**If signals are insufficient, ask:**

```
What stage is this project at?
- Just starting — solo or small team, proving the concept
- Growing — team project, contributors arriving, needs structure
- Established — production traffic, compliance needs, mature open source
```

**Follow-up if needed (combine with above):**

```
Who's the audience?
- Open source community — public repo, external contributors
- Internal team — private or internal, team-only
- Enterprise customers — compliance, SLA, security requirements
```

## Framework Detection Within Stacks

When the stack is known but the framework isn't (affects folder structure and tooling):

### JavaScript / TypeScript
```
Which framework?
- Next.js — app/ directory, server components
- React (Vite/CRA) — src/ directory, SPA
- SvelteKit — src/routes/, server/client split
- Node.js (no framework) — src/ with custom structure
```

### Python
```
Which framework?
- Django — django project structure
- FastAPI — src/ with routers
- Flask — app factory pattern
- None (library/script) — src/package_name/
```

## Handling Ambiguity

**User says something vague:**

| User says | Interpret as | Ask to confirm |
|---|---|---|
| "Set up my repo" | Enhancement mode — scan what exists | "I see [stack] files. Setting up [type] with [stage] — sound right?" |
| "Make this professional" | Audit mode | "I'll scan for gaps and suggest improvements." |
| "Add docs" | Community standards | "Starting with README, CONTRIBUTING, and LICENSE." |
| "Initialize everything" | Greenfield Tier 2 | Ask project type, then generate |

**Conflicting signals:**

If the user's description conflicts with what's detected (e.g., they say "CLI tool" but the directory has `app/routes/`), ask:

```
The directory looks like a web app (I see app/routes/), but you mentioned a CLI tool. Which is it?
- It's a web app — I misspoke
- It's a CLI tool — ignore those files, they're from something else
- It's both — the CLI serves a web interface
```

## What NOT to Ask

- Don't ask about license choice during detection — handle that during file generation (references/licensing-legal.md)
- Don't ask about CI provider — detect from `.github/` vs `.gitlab/`
- Don't ask about specific tool preferences (ESLint vs Biome) — the stack profile handles that
- Don't ask more than 3 questions total — if still unsure after 3, make your best inference and state your assumptions
- Don't ask questions the filesystem already answers — read before you ask

## Integration with SKILL.md Workflow

This reference is used in **Step 0 (Detect project state)** and **Step 1 (Establish project profile)** of the SKILL.md workflow. After detection:

1. Project type → determines which files to generate (references/project-profiles.md)
2. Stack → determines folder structure (references/repo-structure.md) and tooling (references/quality-tooling.md)
3. Stage → determines how many files (Tier 1/2/3/4)
4. Audience → adjusts tone and community file selection

All four answers feed into the project profile that drives the rest of the workflow.
