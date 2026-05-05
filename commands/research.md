---
description: Run automated research (Gemini primary, Claude fallback) on a single idea.
---

You are running the **research** workflow for one specific idea.

Argument: `$ARGUMENTS` is the slug, or a partial. Resolve it before
running the skill:

1. **Eligible set**: ideas in `$PWD/inbox.md` with `Status: Researching`
   that do not yet have a non-empty `$PWD/ideas/<slug>/research.md`.
2. **Empty argument**: list every eligible idea (slug + title) and ask
   the user which to research. Stop.
3. **Exact match** in eligible set: use it.
4. **Prefix match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → show a numbered picker of just those matches and ask
   - none → fall through to substring match
5. **Substring match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker
   - none → list every eligible idea and ask
6. If a candidate matches outside the eligible set (e.g. it already has
   `research.md`), tell the user explicitly and ask whether to re-run
   research on it before proceeding.

Read the research skill at `${CLAUDE_PLUGIN_ROOT}/skills/research/SKILL.md`
and follow it. All idea data lives in `$PWD`.

Final output: brief summary of what was researched, key findings, and any
suggested next steps.
