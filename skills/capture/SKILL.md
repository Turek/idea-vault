---
name: capture
description: Capture a new idea. Writes the full raw input plus a cleaned-up rewrite to ideas/slug/notes.md, creates ideas/slug/index.md, and adds a short paragraph entry to inbox.md. Dedupe-checked. Use when the user wants to capture, add, dump, or save an idea.
---

# Capture skill

Single-step capture. No promote step — every captured idea immediately
gets its own folder under `ideas/`, with the user's verbatim input
preserved in `notes.md`. The `inbox.md` entry stays as a short flat
index pointing at the folder.

## Inputs

- Raw idea text from `$ARGUMENTS` or follow-up user message.
- Existing `$PWD/inbox.md` and all `$PWD/ideas/*/index.md` for dedupe.

All idea data lives in the user's project (`$PWD`), never in the plugin
folder.

## Steps

### 1. Parse the input

Extract:

- **Title** — short, descriptive, under 60 chars. If user did not provide
  one explicitly, derive from the first sentence.
- **Short summary** — one paragraph (3–6 sentences) for `inbox.md` and
  for the `## Description` section in `index.md`. If the input is shorter,
  ask the user to expand. If it is longer or rambling, summarize to a
  single paragraph.
- **Cleaned-up long form** — the user's full input rewritten into
  meaningful prose. Preserve every distinct point. Do not aggressively
  shorten. This goes into `notes.md` alongside the raw input.

Do not invent details that are not in the input.

### 2. Generate a slug

- Lowercase, kebab-case, derived from title.
- Strip stop words if needed to stay 40 chars or less.
- Strip punctuation, replace spaces with `-`.
- If a folder `$PWD/ideas/<slug>/` already exists, append `-2`, `-3`, etc.

### 3. Dedupe check

Load all existing entries from `$PWD/inbox.md` and titles + descriptions
from every `$PWD/ideas/*/index.md`. For each existing idea, compute a
similarity score against the new title + short summary.

Use a simple lexical approach: lowercase, strip stopwords, tokenize, compute
Jaccard similarity on the union of (title tokens) + (summary tokens).
You can do this in your head for small vaults, or write a one-shot Python
helper in `/tmp/` if there are more than 50 ideas.

Thresholds (from `$PWD/CLAUDE.md`):

- `>= 0.85` → **auto-merge**. Append the new wording as a sub-bullet under
  the existing entry in `inbox.md`, and append a dated section to the
  existing `ideas/<existing-slug>/notes.md`. Tell the user what was
  merged. Do not create a new folder.
- `0.60–0.85` → **ask**. Show the user the top 1–3 candidates and ask:
  "Merge with one of these, or treat as new idea?"
- `< 0.60` → proceed as a new entry.

### 4. Create the folder and files

Create `$PWD/ideas/<slug>/` and write three files.

#### a. index.md

```markdown
# <Title>

- Slug: <slug>
- Status: Researching
- Created: <YYYY-MM-DD>
- Last researched: —
- Last scored: —

## Description

<short summary paragraph from step 1>
```

#### b. notes.md

```markdown
# Notes — <Title>

## Original input

<the user's verbatim text, unmodified>

## Cleaned up

<the cleaned-up long-form rewrite from step 1>

## Free-form notes

_Add longer-form thinking here. Not auto-edited by skills._
```

#### c. research.md

Do **not** create `research.md` at capture time. It is created by the
research skill on first run.

### 5. Append to inbox.md

Append below the `<!-- Ideas below this line. -->` marker:

```markdown
## <slug> — <Title>
- Status: Researching
- Created: <YYYY-MM-DD>
- Folder: ideas/<slug>/
- Last researched: —
- Score: —

<short summary paragraph from step 1>
```

`inbox.md` remains the flat source of truth for status. The folder under
`ideas/` holds the long-form content.

### 6. Confirm to the user

Two short lines:

- "Captured `<slug>`. Folder created at `ideas/<slug>/`."
- "Will be picked up by the next research pass (or run research manually)."

For an auto-merged idea, instead say: "Merged into `<existing-slug>`.
Appended to inbox entry and `ideas/<existing-slug>/notes.md`."

## Edge cases

- **Multiple ideas in one input** ("idea 1: ... idea 2: ..."): parse each
  separately, run capture for each, summarize all at end.
- **User dictates raw stream of consciousness**: extract one cohesive idea.
  If it genuinely contains multiple distinct ideas, ask: "I found N ideas
  here, capture all separately?"
- **Title collision but distinct content**: append `-2` to slug, log a note.
- **Empty input**: ask the user to provide the idea text.
