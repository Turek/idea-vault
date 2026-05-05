---
description: Run Perplexity Sonar Deep Research on a specific idea (manual, costs money).
---

You are running the **deep research** workflow.

Argument: `$ARGUMENTS` is the slug. If empty, list ideas with existing
`research.md` and ask which to deep-dive.

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
