---
description: Run Perplexity Sonar Deep Research on a specific idea (manual, costs money).
---

You are running the **deep research** workflow.

Argument: `$ARGUMENTS` is the slug, or a partial. Resolve it before
running the skill:

1. **Eligible set**: ideas under `$PWD/ideas/<slug>/` with a non-empty
   `research.md` (deep research enriches an existing research file).
2. **Empty argument**: list every eligible idea (slug + title) and ask
   the user which to deep-dive. Stop.
3. **Exact match** in eligible set: use it.
4. **Prefix match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker of just those matches
   - none → fall through to substring match
5. **Substring match** in eligible set:
   - one match → use it, tell the user which slug was selected
   - multiple → numbered picker
   - none → list every eligible idea and ask
6. If a candidate matches outside the eligible set (no `research.md`
   yet), tell the user and offer to run standard research first via
   `/idea-vault:research <slug>`.

Read the research skill at `${CLAUDE_PLUGIN_ROOT}/skills/research/SKILL.md`,
specifically the **Deep research (Perplexity)** section. Follow it. All
idea data lives in `$PWD`.

Cost discipline:
- Estimate cost before the call.
- Hard cap from project's `CLAUDE.md` (`deep_research.cost_cap_usd`,
  default $0.50). The CLAUDE.md is in `$PWD`, not the plugin.
- If estimate exceeds cap, abort and report.
- After the call, log actual cost (input/output/citation/reasoning tokens
  + search query count) in the updates log of `research.md`.

Output behavior into `research.md`:
- Where Perplexity output is clearly more current/comprehensive: replace
  that section.
- Where it adds genuinely new info: append.
- Always add a dated entry to the **Updates log** at the bottom of
  `research.md` summarizing what changed.

Final output: brief diff summary + actual cost.
