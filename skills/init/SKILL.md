---
name: init
description: Scaffold Idea Vault project files (CLAUDE.md, inbox.md, top-ideas.md, .env.example, .gitignore, ideas/) into the current working directory. Use when the user runs /idea-vault:init or asks to initialize / set up / bootstrap an idea vault in this project.
---

# Init skill

Creates the project files for an Idea Vault. Runs in `$PWD` (whatever
project the user is currently in). Idempotent — won't clobber existing
files unless the user explicitly says so.

## Steps

### 1. Pre-flight check

Check `$PWD` for these files:
- `CLAUDE.md`
- `inbox.md`
- `top-ideas.md`
- `.env.example`
- `ideas/` (directory)

For each one that already exists, list it. If any exist, ask the user:
"Some Idea Vault files already exist here: [list]. Skip existing, overwrite
all, or abort?"

Default behavior: skip existing.

### 2. Detect collision with non-vault project

If `$PWD` contains a `package.json`, `pyproject.toml`, `Cargo.toml`,
`.git/`, or other clear "this is some other project" markers, ask
the user: "This directory looks like a [type] project. Initialize Idea
Vault here anyway? It will add new files alongside your existing ones."

Skip this check if the directory is empty.

### 3. Create files

Write each file below into `$PWD`. Use the exact templates in the next
section.

After writing, create the empty `ideas/` directory.

### 4. Confirm and guide key setup

Output in this exact order. Keep each step to one line; no prose
paragraphs.

**a. Created** — list every file and the `ideas/` directory you wrote.
Note any files that already existed as "skipped: …".

**b. Set up API keys** — tell the user that research commands need keys
in `.env`. Walk them through it:

1. `cp .env.example .env` in this directory.
2. `GEMINI_API_KEY` — used by `/idea-vault:research` for grounded web
   search. Get one at https://aistudio.google.com/apikey (free tier is
   plenty for this workflow).
3. `PERPLEXITY_API_KEY` — used only by `/idea-vault:deep-research`
   (paid, ~$0.30–0.50/idea). Get one at
   https://www.perplexity.ai/settings/api. Optional — skip if you don't
   plan to run deep research yet.
4. Paste each key after the `=` in `.env`, no quotes.
5. Make sure `.env` is in your project's `.gitignore`. Init does not
   manage `.gitignore` for you.

**c. Try it now** — `/idea-vault:capture <your first idea>` works
without any keys; only research/deep-research need them.

**d. Optional** — set up the two Cowork scheduled tasks via `/schedule`
(see README) once you have ideas worth researching automatically.

## File templates

### CLAUDE.md

````markdown
# Idea Vault — Project Context

This Cowork project captures, researches, and scores ideas. The
`idea-vault` plugin powers the workflow. All configurable knobs live in
this file — edit here, no code changes needed.

## Folder layout

```
<project root>/
├── CLAUDE.md               This file.
├── .env                    API keys (gitignored).
├── .env.example            Template for .env.
├── .gitignore
├── inbox.md                Flat list of all ideas, source of truth.
├── top-ideas.md            Auto-generated top 10 by score.
└── ideas/<slug>/
    ├── index.md            Title, status, score, extended description.
    ├── research.md         Research output (auto + deep merged).
    └── notes.md            Free-form personal notes.
```

## Status lifecycle

```
Researching -> Validated -> Building -> Shipped
            -> Killed
```

- `Researching` is the default on capture. The idea immediately gets its
  own folder under `ideas/` and enters the automated research queue.
- Scoring suggests `Validated` (>=80) or `Killed` (<40); never auto-applied.
- `Building` and `Shipped` are manual transitions.

## Configurable knobs

```yaml
research:
  daily_cap: 3                          Max ideas processed per 24h window.
  per_run_cap: 1                        Ideas processed per scheduler run.
  cadence_hours: 2                      Documented cadence (informational).
  primary_provider: gemini              gemini | claude.
  gemini_model: gemini-2.5-pro
  fallback_provider: claude             Used when primary fails.

deep_research:
  provider: perplexity
  model: sonar-deep-research
  cost_cap_usd: 0.50                    Hard abort if pre-call estimate exceeds.

scoring:
  weights:
    market_size: 0.15
    competition_gap: 0.20
    differentiation: 0.15
    build_complexity: 0.15
    monetization: 0.10
    personal_fit: 0.15
    time_to_signal: 0.10
  bands:
    strong_min: 80                      Suggest Validated at or above.
    kill_max: 40                        Suggest Killed below or at.

dedupe:
  auto_merge_threshold: 0.85
  ask_threshold: 0.60
```

## Conventions

- **Slugs** are kebab-case, derived from title, max 40 chars.
- **Dates** use ISO 8601 (`2026-05-04`).
- **Scores** are integers 0-100 with a per-dimension breakdown table.
- **Inbox entries** are paragraph-length, not one-liners.
- **No HTML comments** added by skills.
- **research.md** is the single source of truth for research; deep-research
  output merges into it.

## Security

- `.env` holds `GEMINI_API_KEY` and `PERPLEXITY_API_KEY`. Gitignored.
- Skills source `.env` from this project's directory before curl calls.
- API keys are never echoed, logged, or written to idea files.

## Scheduling (do this once)

In Cowork, run `/schedule` and set up two tasks:

1. **Idea Vault — Research pass** — every 2 hours.
   Prompt: `Run /idea-vault:research-next from my idea vault project.`

2. **Idea Vault — Scoring pass** — once daily, e.g. 09:00.
   Prompt: `Run /idea-vault:score-pending from my idea vault project.`

Both are Cowork Desktop scheduled tasks (require the app to be open).
````

### inbox.md

```markdown
# Inbox

Flat list of all ideas. Source of truth for status. Each entry follows the
template below. New ideas are appended to the bottom. The capture skill
checks for duplicates before adding.

## Entry template

\`\`\`
## <slug> — <Title>
- Status: Researching
- Created: YYYY-MM-DD
- Folder: ideas/<slug>/
- Last researched: —
- Score: —

<One paragraph describing the idea, the problem it solves, and the rough
shape of a solution. Keep to 3–6 sentences.>
\`\`\`

---

<!-- Ideas below this line. -->
```

### top-ideas.md

```markdown
# Top Ideas

Auto-generated. Do not edit manually — the scoring skill regenerates this
file on every scoring pass.

Last updated: never

## Top 10 by score

_No scored ideas yet. Capture some ideas, let the research scheduler
process them, then run `/idea-vault:score` or wait for the daily scoring
pass._

## Recently scored

_None._
```

### .env.example

```
# Copy this file to .env and fill in your keys.
# Make sure your project's .gitignore excludes .env.

# Google Gemini API key (https://aistudio.google.com/apikey).
GEMINI_API_KEY=

# Perplexity API key (https://www.perplexity.ai/settings/api).
PERPLEXITY_API_KEY=
```

## Edge cases

- **Empty directory**: just create everything, no questions.
- **Existing Idea Vault** (CLAUDE.md mentions Idea Vault, inbox.md exists):
  refuse with "This directory already contains an Idea Vault. Use existing
  files."
- **Permission errors**: report which file failed, suggest checking
  directory permissions.
