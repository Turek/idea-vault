---
description: Score a single researched idea using the 10-dimension rubric (weighted geometric mean and confidence scalar, four-tier output).
---

You are running the **score** workflow.

Argument: `$ARGUMENTS` is the slug, or a partial. Resolve it before
running the skill:

1. **Eligible set**: ideas under `$PWD/ideas/<slug>/` with a non-empty
   `research.md` and no current score block in `index.md`.
2. **Empty argument**: list every eligible idea (slug + title) and ask
   the user which to score. Stop.
3. **Exact match** in eligible set: use it.
4. **Prefix match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker of just those matches
   - none → fall through to substring match
5. **Substring match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker
   - none → list every eligible idea and ask
6. If a candidate matches outside the eligible set (e.g. already scored,
   or no `research.md` yet), tell the user and ask whether to proceed
   anyway (e.g. point them at `/idea-vault:rescore` if it's already
   scored).

Read the score skill at `${CLAUDE_PLUGIN_ROOT}/skills/score/SKILL.md`
and follow it. All idea data lives in `$PWD`.

Final output: the score, the band, and any suggested status transition
(Validated / Killed). Ask the user before applying any status change.
