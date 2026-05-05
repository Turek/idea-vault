---
description: Force re-score of an already-scored idea.
---

You are running the **rescore** workflow. This forces a fresh evaluation
even if a score already exists.

Argument: `$ARGUMENTS` is the slug. Required.

Read the score skill at `${CLAUDE_PLUGIN_ROOT}/skills/score/SKILL.md`
and follow it. Overwrite the existing score block in `index.md` (located
under `$PWD/ideas/<slug>/`) and regenerate `top-ideas.md` in `$PWD`.

Final output: old score, new score, delta, and any new status suggestion.
