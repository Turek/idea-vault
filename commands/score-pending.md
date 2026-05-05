---
description: Scheduler entry point. Score every researched idea that lacks a current score.
---

You are running the **scheduled scoring pass**. Invoked by a daily Cowork
scheduled task.

Steps:

1. Walk `$PWD/ideas/*/` directories.
2. For each idea, load `index.md`. Qualifies for scoring if:
   - `research.md` exists and is non-empty, AND
   - `index.md` has no score block, OR
   - `research.md` was modified after `Last scored` date (deep research
     happened since last score).
3. For each qualifying idea: follow `${CLAUDE_PLUGIN_ROOT}/skills/score/SKILL.md`.
4. After all ideas processed, regenerate `top-ideas.md` (in `$PWD`) with
   current top 10 sorted by score, plus a "Recently scored" section for
   ideas scored today.

Final output: short summary — count scored, count skipped, top 3 scores today.
For ideas suggesting status changes (Validated/Killed): list them but do not
apply. The user reviews top-ideas.md and decides.
