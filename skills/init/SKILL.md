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

**b. Set up API keys via the gateway** — research now runs through the
`idea-vault-gateway` MCP server, which holds keys globally so you only
configure them once across all projects.

1. Install the gateway binary if you haven't already (see the plugin
   README's install section).
2. Run `idea-vault-gateway init` once. It will prompt for
   `GEMINI_API_KEY` and `PERPLEXITY_API_KEY` and write them to
   `~/.config/idea-vault-gateway/.env`.
3. Get keys at https://aistudio.google.com/apikey (Gemini, free tier
   is plenty) and https://www.perplexity.ai/settings/api (Perplexity,
   paid — only needed for `/idea-vault:deep-research`).
4. The plugin's per-project `.env` is no longer used for API keys. It
   exists only for project-specific overrides if you need them later.

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
- Scoring suggests `Validated` (Tier 1: Ready to Build) or `Killed`
  (Tier 4: Unviable); never auto-applied.
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
    problem_urgency: 0.12
    market_scale: 0.10
    competition_landscape: 0.10
    unfair_advantage: 0.12
    distribution_viability: 0.12
    monetization_wtp: 0.12
    regulatory_feasibility: 0.08
    execution_complexity: 0.08
    founder_market_fit: 0.08
    validation_velocity: 0.08
  critical_pillars:                     Score 0 or 1 here -> Tier 4 (Unviable).
    - problem_urgency
    - market_scale
    - distribution_viability
    - monetization_wtp
    - regulatory_feasibility
  confidence_anchors:                   Multiplier applied to base score.
    high: 1.00                          User testing, LOIs, significant surveys.
    medium: 0.80                        Secondary research, competitive analysis.
    low: 0.50                           Team opinions, deductions.
    guess: 0.30                         Pure intuition, no citations.
  tiers:
    tier1_min_final: 70                 AND confidence >= 0.80. Tier 1: Ready to Build.
    tier2_min_final: 50                 Tier 2: Needs Empirical Validation.
    tier3_min_final: 30                 Tier 3: Structural Pivot Required.
    # Below 30, or any critical pillar at 0 or 1: Tier 4 (Unviable).
  disqualifier_score_max: 1             Critical pillar at this score or lower -> Tier 4.

dedupe:
  auto_merge_threshold: 0.85
  ask_threshold: 0.60
```

## Conventions

- **Slugs** are kebab-case, derived from title, max 40 chars.
- **Dates** use ISO 8601 (`2026-05-04`).
- **Scores** are integers 0-100 with a per-dimension breakdown table,
  base (geometric mean × 100), final (base × confidence), confidence
  level, and tier (1–4).
- **Inbox entries** are paragraph-length, not one-liners.
- **No HTML comments** added by skills.
- **research.md** is the single source of truth for research; deep-research
  output merges into it.

## Security

- API keys live globally in `~/.config/idea-vault-gateway/.env`,
  managed by `idea-vault-gateway init`. The plugin never sees keys.
- The plugin's per-project `.env` should still be gitignored even
  though it currently holds no secrets — future per-project config
  might.
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
# This file exists for project-specific overrides only.
# API keys live globally in ~/.config/idea-vault-gateway/.env,
# managed by `idea-vault-gateway init` — not here.

# (Reserved for future per-project config.)
```

## Edge cases

- **Empty directory**: just create everything, no questions.
- **Existing Idea Vault** (CLAUDE.md mentions Idea Vault, inbox.md exists):
  refuse with "This directory already contains an Idea Vault. Use existing
  files."
- **Permission errors**: report which file failed, suggest checking
  directory permissions.
