# Idea Vault

A Claude Code / Cowork plugin for capturing, deduping, researching, and
scoring ideas. The plugin ships only code — `/idea-vault:init` scaffolds
the data files into whichever project you run it in.

## Install

This plugin installs directly from a local directory. No marketplace needed.

### 1. Clone or place this folder somewhere stable

For example: `~/Code/idea-vault/`. Don't put it inside the Cowork project
that will store your ideas — keep them separate.

### 2. Install the plugin

From any Claude Code or Cowork session:

```
/plugin install /absolute/path/to/idea-vault
```

After install, run `/reload-plugins` to activate.

### 3. Initialize a project

Open (or create) the Cowork project where you want your idea vault to live.
With that project as your working directory, ask Claude to "initialize idea vault".

This creates:

```
<your project>/
├── CLAUDE.md            Project context + all configurable knobs.
├── .env.example         Copy to .env and fill in API keys.
├── inbox.md             Source of truth for all ideas.
├── top-ideas.md         Auto-generated leaderboard.
└── ideas/               One folder per captured idea (notes.md + index.md, plus research.md after first research run).
```

### 4. Add API keys

In your project root:

```
cp .env.example .env
```

Edit `.env` and fill in:
- `GEMINI_API_KEY` — get from https://aistudio.google.com/apikey
- `PERPLEXITY_API_KEY` — get from https://www.perplexity.ai/settings/api

### 5. Set up scheduled tasks (optional but recommended)

In Cowork, type `/schedule` and create:

- **Idea Vault — Research pass** — every 2 hours.
  Prompt: `Pick the oldest Researching idea without research.md and research it.`

- **Idea Vault — Scoring pass** — once daily, e.g. 09:00.
  Prompt: `Score every researched idea that doesn't yet have a current score.`

Cowork Desktop scheduled tasks require the app to stay open. Cloud
scheduled tasks have hard caps (3/day on Max) — likely not enough for
2-hour research cadence, so use Desktop scheduling.

## Skills

The plugin ships skills (no slash commands). Each skill activates on natural-language triggers:

| Skill | Triggers on |
|-------|-------------|
| `init` | "initialize idea vault", "set up idea vault", "scaffold idea vault" |
| `capture` | "capture idea …", "add idea …", "save this idea …" |
| `research` | "research X", "validate X", "investigate X" (Gemini → Claude fallback; Perplexity for deep dives) |
| `score` | "score X", "evaluate X", "rate X", "rank ideas" |

## How it works

- **Capture** — appends a short paragraph to `inbox.md` and creates
  `ideas/<slug>/` with `index.md` (short summary) and `notes.md` (your
  full raw input + a cleaned-up rewrite). Dedupe is automatic
  (auto-merge >85% similar, ask 60–85%). No separate promote step.
- **Research** — Gemini grounded search runs first (every 2h via scheduler).
  Falls back to Claude built-in web search on failure. Creates
  `ideas/<slug>/research.md` on first run.
- **Deep research** — manual command using Perplexity Sonar Deep Research.
  Pre-call cost estimate, hard cap from `CLAUDE.md` (default $0.50).
  Output merges into `research.md` (replaces stale sections, appends new
  info, keeps an updates log).
- **Score** — 7-dimension weighted rubric (market, gap, differentiation,
  complexity, monetization, fit, time-to-signal). Updates `top-ideas.md`.
  Suggests Validated (>=80) or Killed (<40) but never auto-applies.

## Status lifecycle

```
Researching -> Validated -> Building -> Shipped
            -> Killed
```

## Configuration

After init, all knobs live in your project's `CLAUDE.md`:
research cadence, daily caps, scoring weights, cost caps, dedupe thresholds,
provider preferences. Edit there, no code changes.

## Architecture notes

- **Plugin lives in `~/.claude/plugins/cache/`** after install. Claude Code
  copies the plugin there from the source directory you specified.
- **Project files live in your Cowork project directory.** That's where
  `inbox.md`, `ideas/`, `.env`, etc. all go.
- **Scripts use `$CLAUDE_PLUGIN_ROOT`** to find sibling helpers and `$PWD`
  to find your project's `.env` and data files.
- **`.env` stays in the project.** Different projects can have different
  API keys.

## Packaging as a `.plugin` / `.zip` upload (Cowork)

Cowork accepts both `.plugin` and `.zip` bundles. The archive must have `.claude-plugin/plugin.json` at its **root** — not nested inside an `idea-vault/` folder.

From the parent of the plugin directory, build both:

```
(cd idea-vault && zip -r ../idea-vault.plugin . -x ".git/*" ".gitignore" "*.DS_Store" ".claude/*")
(cd idea-vault && zip -r ../idea-vault.zip    . -x ".git/*" ".gitignore" "*.DS_Store" ".claude/*")
```

## Updating the plugin

After editing files in this repo:

```
/plugin uninstall idea-vault
/plugin install /absolute/path/to/idea-vault
```

Then reload plugins.

## Costs

- **Gemini grounding**: ~$0.01–0.05 per idea. Effectively free at typical
  volumes.
- **Claude built-in web search** (fallback): no per-call API cost; counts
  against Cowork usage.
- **Perplexity Sonar Deep Research**: ~$0.30–0.50 per idea. Hard-capped.
