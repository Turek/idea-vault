---
name: research
description: Run market and competitor research on a single idea. Gemini primary, Claude built-in web search fallback. Includes deep research mode via Perplexity Sonar Deep Research. Use when user runs /idea-vault:research, /idea-vault:research-next, /idea-vault:deep-research, or asks to research/validate/investigate an idea.
---

# Research skill

Two modes:

1. **Standard research** (default): Gemini grounded search → Claude web
   search fallback. Cheap, automated, runs once per idea unless triggered
   again.
2. **Deep research** (manual only via `/idea-vault:deep-research`):
   Perplexity Sonar Deep Research. Costs real money. Hard cap from
   `$PWD/CLAUDE.md`.

## Inputs

- Slug.
- `$PWD/ideas/<slug>/index.md` (description, title).
- `$PWD/.env` for API keys.
- `$PWD/CLAUDE.md` for caps and provider config.

All idea data files live in the user's project (`$PWD`). Helper scripts
live at `${CLAUDE_PLUGIN_ROOT}/scripts/`.

## Output structure (research.md)

```markdown
# Research — <Title>

Last updated: <ISO date>
Provider(s): Gemini | Claude | Perplexity (list any that contributed)

## Market signal

<2–4 sentences: is there real demand? Search trends, community size,
existing paid tools, recent press.>

## Top competitors

| # | Name | URL | What they offer | Pricing | Notable gaps |
|---|------|-----|-----------------|---------|--------------|
| 1 | ...  | ... | ...             | ...     | ...          |

(5–10 rows.)

## Gaps and complaints

What users complain about across the existing solutions. Pull from forums
(Reddit, HN, G2, Trustpilot, niche communities). Each bullet should cite
where it came from.

- ... (source)
- ... (source)

## Pros (why this idea is interesting)

- ...

## Cons (why this idea might not work)

- ...

## Open questions

Things research couldn't resolve and that need user judgment or deeper dive.

- ...

## Suggested next steps

1. ...
2. ...

## Updates log

- <date> — Initial research via <provider>. Notes: ...
```

## Mode 1 — Standard research (Gemini primary)

### Step 1. Build the research prompt

Construct one focused prompt that asks for the full report structure above.
Reference the idea's title and description from `$PWD/ideas/<slug>/index.md`.

Prompt template (string in your head, do not paste verbatim):

> You are doing market research for the following idea: **<title>**.
> Description: <description from index.md>.
>
> Produce a structured report with these sections:
> 1. Market signal (real demand? trends? size?)
> 2. Top 5–10 competitors with name, URL, offer, pricing, notable gaps.
> 3. Gaps and complaints from real user forums (Reddit, HN, G2,
>    Trustpilot, domain-specific). Cite the source for each.
> 4. Pros (why it could work).
> 5. Cons (why it might not).
> 6. Open questions.
> 7. Suggested next steps.
>
> Use real citations. Be honest about uncertainty. If you can't find
> data, say so.

### Step 2. Call Gemini (mandatory background launch + poll)

**Two hard rules. Both apply every time. No exceptions.**

**Rule 1 — Use the helper script. Never write your own curl.**
You MUST invoke `${CLAUDE_PLUGIN_ROOT}/scripts/gemini_research.sh
<prompt-file>`. Do NOT write an inline `curl` to the Gemini API, even
"as a quick check" or "because the script seems to be failing". The
helper handles things you will get wrong if you reinvent it:
`--max-time 480`, retry-with-backoff on 429/503, and a Flash fallback.
A hand-written `curl` with `--max-time 38` (or anything under ~60 s)
will fail every time on grounded research and is the single most
common reason research silently degrades. If the script genuinely
fails after running, proceed to Step 3 — do not bypass it with curl.

**Rule 2 — Always launch in the background.** The Bash tool's default
sandbox timeout (~40 s) will kill any foreground call. You MUST use
`run_in_background: true` on the Bash invocation. Do NOT run the
helper inline, even with an explicit `timeout:` value — backgrounding
is the only path that reliably survives. There is no alternative.

The helper script:

- Sources `$PWD/.env` (the user's project, not the plugin).
- Calls Gemini's `generateContent` with `google_search` grounding.
- Retries the configured model on 429/503 (10 s, then 30 s).
- Falls back once to `gemini-2.5-flash` on persistent failure.
- Routinely runs 2–5 minutes; sometimes longer.

#### 2a. Launch in the background

Bash tool, **`run_in_background: true`** (this is non-negotiable —
without it the call dies at the sandbox timeout), command:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gemini_research.sh" \
  /tmp/idea_research_prompt.txt \
  > /tmp/gemini_response.json \
  2> /tmp/gemini_err.log
echo $? > /tmp/gemini_exit
```

The Bash call returns immediately. Do not wait inline. Do not write
your own curl as a parallel attempt while waiting.

#### 2b. Wait for completion via notification

You will be notified when the background command exits. Do NOT proactively
poll with `sleep` loops. Just wait for the completion notification, then
proceed to step 2c. Allow up to 10 minutes.

#### 2c. Read the result

Once notified:

- Read `/tmp/gemini_response.json` for the response body.
- Read `/tmp/gemini_exit` for the exit code.
- If exit code is non-zero or response is empty, also read
  `/tmp/gemini_err.log` for diagnostic output, then proceed to Step 3
  (Claude web-search fallback).

Parse `candidates[0].content.parts[*].text` (concatenate) for the report
text. Parse `candidates[0].groundingMetadata.groundingChunks` for sources
to cite.

### Step 3. On failure, fall back to Claude built-in web search

Failure conditions:
- HTTP non-2xx from Gemini.
- Empty `candidates` array.
- `groundingMetadata` absent (model didn't actually search).
- Script timeout (> 8 min).

On failure: use the built-in `web_search` tool. Run multiple searches:
- "<idea concept> competitors"
- "<idea concept> reviews complaints"
- "<idea concept> market size"
- "<idea concept> reddit"
- Domain-specific terms from the description.

Synthesize into the same output structure.

### Step 4. Write research.md

Write the structured report to `$PWD/ideas/<slug>/research.md`. Replace
any existing placeholder. Set `Last updated: <today>` and `Provider(s):`
to whichever ran.

### Step 5. Update index.md

Update `Last researched: <today>` in `$PWD/ideas/<slug>/index.md`.

### Step 6. Brief confirmation

One paragraph summary back to the user: which provider, top 1–2 findings,
suggested next step.

## Mode 2 — Deep research (Perplexity, manual)

Triggered only via `/idea-vault:deep-research <slug>`.

### Step D1. Pre-flight cost check

Read `$PWD/CLAUDE.md` `deep_research.cost_cap_usd` (default 0.50).

Estimate cost:
- Input tokens: ~ idea description + research.md current contents + prompt
  scaffolding ≈ 2000–5000 tokens.
- Output tokens: budget ~3000 tokens for a deep report.
- Search queries: Sonar Deep Research typically runs 10–30 queries.
- Reasoning tokens: typically 2000–10000.

Pricing (verify against current Perplexity docs at runtime, do not
hardcode in skill output):
- Input: $2/1M tokens
- Output: $8/1M tokens
- Citation: $2/1M tokens
- Reasoning: $3/1M tokens
- Search: $5 per 1000 queries

Estimate formula:
```
cost ≈ (in_tokens/1e6 * 2) + (out_tokens/1e6 * 8)
     + (cite_tokens/1e6 * 2) + (reason_tokens/1e6 * 3)
     + (queries/1000 * 5)
```

Conservative estimate for a typical idea: ~$0.30–0.45.

If estimate > cap: **abort**. Tell the user the estimate and the cap.
Suggest they raise the cap in `$PWD/CLAUDE.md` or skip.

### Step D2. Build the deep prompt

Include:
- Title and description.
- The current contents of `$PWD/ideas/<slug>/research.md` (so Perplexity
  can build on, not duplicate).
- Explicit instruction: "Find what the existing research missed. Verify
  the claims that look weak. Surface dissenting views."

### Step D3. Call Perplexity

Use the helper `${CLAUDE_PLUGIN_ROOT}/scripts/perplexity_deep.sh <prompt-file>`.

The script:
- Sources `$PWD/.env` (the user's project, not the plugin).
- POSTs to `https://api.perplexity.ai/chat/completions` with
  `model: sonar-deep-research`.
- Returns JSON.

Parse:
- `choices[0].message.content` — markdown report.
- `citations` — array of URL strings.
- `usage` — token counts. Calculate **actual** cost.

### Step D4. Merge into existing research.md

Per-section logic:

| Section | Decision rule |
|---------|---------------|
| Market signal | Replace if Perplexity's data is more current OR more specific (e.g. has dollar figures the original lacked). Otherwise append. |
| Top competitors | Merge tables: keep existing rows, add new ones, update existing rows with newer info. Deduplicate by URL. |
| Gaps and complaints | Append new bullets. Don't replace — old complaints don't disappear. |
| Pros / Cons | Merge bullets, dedupe semantically. |
| Open questions | Replace if Perplexity answered some, append new ones. |
| Suggested next steps | Replace — newer thinking supersedes older. |

### Step D5. Append to Updates log

```markdown
## Updates log

- <date> — Initial research via Gemini. ...
- <date> — Deep research via Perplexity. Sections updated: <list>.
  Sections appended to: <list>. Cost: $0.XX (in:NNN out:NNN cite:NNN
  reason:NNN queries:NN).
```

### Step D6. Confirmation

One paragraph: what changed, actual cost, top new finding.

## General rules

- Never invent citations. If a source can't be verified, omit it.
- Keep `research.md` as one file (in `$PWD/ideas/<slug>/`). No
  `research-perplexity.md` split.
- Don't write API keys, request bodies, or raw API responses anywhere
  except temporary files in `/tmp/`.
- If both Gemini and Claude fallback fail: write a stub `research.md`
  noting the failure, leave `Last researched: —` in `index.md`, ask the
  user.
