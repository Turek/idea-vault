---
name: research
description: Run market and competitor research on a single idea via the idea-vault-gateway MCP server. Standard research uses the gemini_research tool with perplexity_research as fallback. Deep research uses perplexity_research with deep mode. Use when user runs /idea-vault:research, /idea-vault:research-next, /idea-vault:deep-research, or asks to research, validate, or investigate an idea.
---

# Research skill

Two modes, both routed through the `idea-vault-gateway` MCP server.
The MCP layer handles long-running API calls without bash sandbox
timeouts and centralizes API-key management in
`~/.config/idea-vault-gateway/.env` (set once via
`idea-vault-gateway init`).

1. **Standard research** (default): call the `gemini_research` MCP
   tool. If it fails or is unavailable, fall back to Claude built-in
   `web_search`. Perplexity is NOT used in standard research.
2. **Deep research** (manual only via `/idea-vault:deep-research`):
   call `perplexity_research` with `deep: true`. Costs real money.
   Hard cap from `$PWD/CLAUDE.md`.

## Inputs

- Slug.
- `$PWD/ideas/<slug>/index.md` (description, title).
- `$PWD/CLAUDE.md` for caps and provider config.

API keys are NOT in the plugin's `.env`. They live globally in
`~/.config/idea-vault-gateway/.env`, managed by the gateway's `init`
command. The plugin does not see or pass keys.

## Output structure (research.md)

```markdown
# Research — <Title>

Last updated: <ISO date>
Provider(s): Gemini | Perplexity | Claude (list any that contributed)

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

## Mode 1 — Standard research

### Step 1. Build the research prompt

Construct one focused prompt that asks for the full report structure
above. Reference the idea's title and description from
`$PWD/ideas/<slug>/index.md`.

Prompt template (use as the `prompt` argument to the MCP tool):

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

### Step 2. Call gemini_research

Call the **`gemini_research`** tool from the `idea-vault-gateway` MCP
server with `prompt=<the prompt from Step 1>`.

Do NOT fall back to bash, curl, or any helper script — the gateway is
the only sanctioned grounded-research path. If the tool isn't
registered (server not installed) or it errors, go to Step 3.

The tool returns the markdown report text and citations. On success,
parse and proceed to Step 4 (Write research.md). Skip Step 3.

### Step 3. On gemini_research failure: Claude built-in web_search

If `gemini_research` errored, returned empty content, or is
unavailable: use the built-in `web_search` tool. Run several searches:

- "<idea concept> competitors"
- "<idea concept> reviews complaints"
- "<idea concept> market size"
- "<idea concept> reddit"
- Domain-specific terms from the description.

Synthesize into the same output structure.

### Step 4. Write research.md

Write the structured report to `$PWD/ideas/<slug>/research.md`.
Replace any existing placeholder. Set `Last updated: <today>` and
`Provider(s):` to whichever ran (Gemini or Claude).

### Step 5. Update index.md

Update `Last researched: <today>` in `$PWD/ideas/<slug>/index.md`.

### Step 6. Brief confirmation

One paragraph summary back to the user: which provider ran, top 1–2
findings, suggested next step.

## Mode 2 — Deep research (Perplexity, manual)

Triggered only via `/idea-vault:deep-research <slug>`.

### Step D1. Pre-flight cost check

Read `$PWD/CLAUDE.md` `deep_research.cost_cap_usd` (default 0.50).

The gateway returns actual cost in the tool response. Pre-call estimate
heuristic for a typical idea: ~$0.30–0.45.

If you have reason to expect the call will exceed the cap (e.g. an
unusually large existing `research.md` will inflate the prompt), warn
the user before calling and let them decide.

### Step D2. Build the deep prompt

Include:
- Title and description.
- The current contents of `$PWD/ideas/<slug>/research.md` (so
  Perplexity can build on, not duplicate).
- Explicit instruction: "Find what the existing research missed.
  Verify the claims that look weak. Surface dissenting views."

### Step D3. Call perplexity_research with deep=true

Call **`perplexity_research`** with `prompt=<the deep prompt>` and
`deep: true`. The gateway handles the long-running call without
timeout concerns.

The tool returns:
- The markdown report text.
- Citations (array of URLs).
- Actual cost (USD), broken down by token type and search queries.

If the actual cost exceeds the cap from D1, surface that to the user
along with the report — the call already happened, so don't abort,
but flag the overage.

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
  Sections appended to: <list>. Cost: $0.XX.
```

### Step D6. Confirmation

One paragraph: what changed, actual cost, top new finding.

## General rules

- Never invent citations. If a source can't be verified, omit it.
- Keep `research.md` as one file (in `$PWD/ideas/<slug>/`). No
  `research-perplexity.md` split.
- Do NOT call the Gemini or Perplexity HTTP APIs directly with bash
  or curl. The MCP gateway is the only sanctioned path. If the
  gateway is unavailable, fall through to Claude `web_search` per
  Step 4 — never reach for raw HTTP as a workaround.
- If all paths fail (MCP tools unavailable AND `web_search`
  unavailable): write a stub `research.md` noting the failure, leave
  `Last researched: —` in `index.md`, ask the user.
