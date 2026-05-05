---
description: Scheduler entry point. Pick the oldest unresearched Researching idea and process it.
---

You are running the **scheduled research pass**. This is invoked by a Cowork
scheduled task every 2 hours.

Steps:

1. Read `$PWD/inbox.md`. Find ideas with `Status: Researching` AND no
   `research.md` in `$PWD/ideas/<slug>/` (or `research.md` exists but is
   empty).
2. Sort by `Created` date, oldest first.
3. Check the per-run cap from `$PWD/CLAUDE.md` (default 1) and the daily
   cap (default 3). Skip if today's research count already at daily cap.
4. Pick the top N (= per-run cap) ideas.
5. For each: read `${CLAUDE_PLUGIN_ROOT}/skills/research/SKILL.md` and run
   the workflow. All idea data is in `$PWD`.
6. If no ideas qualify, exit silently with a one-line summary.

Final output: short status message — what was processed, what was skipped, why.
Do not produce a long report.
