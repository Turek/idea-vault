---
description: Force re-score of an already-scored idea.
---

You are running the **rescore** workflow. This forces a fresh evaluation
even if a score already exists.

Argument: `$ARGUMENTS` is the slug, or a partial. Resolve it before
running the skill:

1. **Eligible set**: ideas under `$PWD/ideas/<slug>/` that already have
   a score block in `index.md`. Rescore is meaningless without a prior
   score.
2. **Empty argument**: list every eligible idea (slug + current score)
   and ask the user which to rescore. Stop.
3. **Exact match** in eligible set: use it.
4. **Prefix match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker of just those matches
   - none → fall through to substring match
5. **Substring match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker
   - none → list every eligible idea and ask
6. If a candidate matches outside the eligible set (no score yet), tell
   the user and offer to run `/idea-vault:score <slug>` instead.

Read the score skill at `${CLAUDE_PLUGIN_ROOT}/skills/score/SKILL.md`
and follow it. Overwrite the existing score block in `index.md` (located
under `$PWD/ideas/<slug>/`) and regenerate `top-ideas.md` in `$PWD`.

Final output: old score, new score, delta, and any new status suggestion.
