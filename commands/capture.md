---
description: Capture a new idea into the inbox with dedupe check.
---

You are running the **capture** workflow for the Idea Vault plugin.

The user has provided idea text (raw, possibly messy) in `$ARGUMENTS`. If
`$ARGUMENTS` is empty, ask the user for the idea text first.

Read the capture skill at `${CLAUDE_PLUGIN_ROOT}/skills/capture/SKILL.md`
and follow it step by step. All idea data files live in the current
working directory (`$PWD`), not in the plugin folder.

Final output: confirm what was added (slug + title), or what it merged with,
or what borderline match it asked about.
