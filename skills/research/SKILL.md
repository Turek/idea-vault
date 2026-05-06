---
name: research
description: Run market and competitor research on a single idea. Claude built-in web search by default, with optional Gemini grounded-search upgrade for environments with longer bash timeouts. Includes deep research mode via Perplexity Sonar Deep Research. Use when user runs /idea-vault:research, /idea-vault:research-next, /idea-vault:deep-research, or asks to research/validate/investigate an idea.
---

# Research skill

Two modes:

1. **Standard research** (default): Claude built-in `web_search`. Cheap,
   reliable, runs once per idea unless triggered again. Optional Gemini
   grounded-search upgrade if the user has set `IDEA_VAULT_GEMINI_OK=1`
   in `.env` (only viable from environments without short bash sandbox
   timeouts — see "Why web_search is the default" below).
2. **Deep research** (manual only via `/idea-vault:deep-research`):
   Perplexity Sonar Deep Research. Costs real money. Hard cap from
   `$PWD/CLAUDE.md`.

## Why web_search is the default

Cowork (desktop and scheduled tasks) runs each bash invocation in a
sandbox capped at ~45 seconds, with backgrounded children dying with
the parent. Gemini grounded search empirically takes longer than that,
so the helper script will be killed mid-curl every time in Cowork —
no amount of script-level retry, backoff, or backgrounding can work
around the host wall-clock. Defaulting to `web_search` saves ~45 s of
wasted helper-launch time per research run and produces equivalent
research quality from Claude's built-in tool.

The helper script remains in the plugin so users who run the skill
from a real terminal (Claude Code CLI, where Bash supports up to
10-minute timeouts) can opt into grounded search by setting
`IDEA_VAULT_GEMINI_OK=1` in their project's `.env`.

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

### Step 2. Pick the provider

Read `$PWD/.env`. If `IDEA_VAULT_GEMINI_OK=1` is set AND
`GEMINI_API_KEY` is set, attempt Gemini grounded search via the
helper (Step 2A). Otherwise, go straight to Claude `web_search`
(Step 2B).

In Cowork (desktop or scheduled), the helper will be killed at the
~45 s sandbox cap before completing — you'll fall through to Step 2B
either way. Treating this as the default saves the wasted launch.

### Step 2A. Gemini grounded search via the helper (opt-in only)

This branch runs only if both flags above are set. Two hard rules
apply throughout.

**Rule 1 — Use the helper script. Never write your own curl.**
You MUST invoke `${CLAUDE_PLUGIN_ROOT}/scripts/gemini_research.sh
<prompt-file>`. Do NOT write an inline `curl` to the Gemini API, even
"as a quick check" or "because the script seems to be failing". The
helper handles things you will get wrong if you reinvent it:
`--max-time 480`, retry-with-backoff on 429/503, and a Flash fallback.
A hand-written `curl` with a short `--max-time` will fail every time
on grounded research. If the helper genuinely fails after running,
proceed to Step 2B — do not bypass it with curl.

**Rule 2 — Always launch in the background.** Use
`run_in_background: true` on the Bash invocation. Foreground (even
with an explicit `timeout:`) is forbidden.

The helper script:

- Sources `$PWD/.env` (the user's project, not the plugin).
- Calls Gemini's `generateContent` with `google_search` grounding.
- Retries the configured model on 429/503 (10 s, then 30 s).
- Falls back once to `gemini-2.5-flash` on persistent failure.
- Routinely runs 2–5 minutes; sometimes longer.

Launch:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/gemini_research.sh" \
  /tmp/idea_research_prompt.txt \
  > /tmp/gemini_response.json \
  2> /tmp/gemini_err.log
echo $? > /tmp/gemini_exit
```

Wait for the completion notification (do not poll with sleep loops),
then read `/tmp/gemini_response.json`, `/tmp/gemini_exit`, and on
non-zero exit `/tmp/gemini_err.log`.

If the helper failed for a fixable reason (`/tmp` path, `.env` not
found, `GEMINI_API_KEY` missing), fix and re-launch the helper (still
backgrounded). Never substitute inline curl. If the helper failed
because the host bash sandbox killed it before completion, that's the
documented Cowork limitation — fall through to Step 2B and remember
to advise the user that `IDEA_VAULT_GEMINI_OK=1` only helps in
non-Cowork environments.

On success: parse `candidates[0].content.parts[*].text` (concatenate)
for the report text. Parse `candidates[0].groundingMetadata.groundingChunks`
for sources to cite. Skip Step 2B and proceed to Step 3.

### Step 2B. Claude built-in web search (default path)

Use the `web_search` tool. Run several searches covering the idea's
core concepts:

- "<idea concept> competitors"
- "<idea concept> reviews complaints"
- "<idea concept> market size"
- "<idea concept> reddit"
- Domain-specific terms from the description.

Synthesize the results into the report structure shown at the top of
this file.

### Step 3. Write research.md

Write the structured report to `$PWD/ideas/<slug>/research.md`. Replace
any existing placeholder. Set `Last updated: <today>` and `Provider(s):`
to whichever ran.

### Step 4. Update index.md

Update `Last researched: <today>` in `$PWD/ideas/<slug>/index.md`.

### Step 5. Brief confirmation

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
