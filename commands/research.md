---
description: Run automated research (Gemini primary, Claude fallback) on a single idea.
---

You are running the **research** workflow for one specific idea.

Argument: `$ARGUMENTS` is the slug. If empty, list all `Status: Researching`
ideas without `research.md` and ask which to research.

Read the research skill at `${CLAUDE_PLUGIN_ROOT}/skills/research/SKILL.md`
and follow it. All idea data lives in `$PWD`.

Final output: brief summary of what was researched, key findings, and any
suggested next steps.
