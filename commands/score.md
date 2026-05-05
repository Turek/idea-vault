---
description: Score a single researched idea using the 7-dimension rubric.
---

You are running the **score** workflow.

Argument: `$ARGUMENTS` is the slug. If empty, list ideas with `research.md`
present and ask which to score.

Read the score skill at `${CLAUDE_PLUGIN_ROOT}/skills/score/SKILL.md`
and follow it. All idea data lives in `$PWD`.

Final output: the score, the band, and any suggested status transition
(Validated / Killed). Ask the user before applying any status change.
