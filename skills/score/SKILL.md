---
name: score
description: Score a researched idea on the 7-dimension rubric and update top-ideas.md. Use when user runs /idea-vault:score, /idea-vault:rescore, /idea-vault:score-pending, or asks to evaluate/rate/rank an idea.
---

# Score skill

Applies a 7-dimension weighted rubric to a researched idea, writes the score
block into `index.md`, and regenerates `top-ideas.md`.

## Inputs

- Slug.
- `$PWD/ideas/<slug>/index.md` (description).
- `$PWD/ideas/<slug>/research.md` (must exist and be non-empty — otherwise
  refuse and tell the user to run research first).
- `$PWD/CLAUDE.md` for weights and band thresholds.

All idea data lives in the user's project (`$PWD`), not the plugin.

## The rubric

Score each dimension 0–10 (integers). Multiply by weight. Sum × 10 gives a
0–100 score.

| # | Dimension | Weight | Anchor: 10 (high) | Anchor: 0 (low) |
|---|-----------|--------|-------------------|-----------------|
| 1 | Market size & demand | 0.15 | Large active audience, paid alternatives exist, search/community signal strong | No evidence of demand, niche of niche |
| 2 | Competition gap | 0.20 | Multiple existing tools, all with clear, repeated user complaints | Crowded market with no real gripes; or no tools but no demand |
| 3 | Differentiation potential | 0.15 | Clear unique angle that's defensible | "Same but better" — no real moat |
| 4 | Build complexity (inverted) | 0.15 | Solo MVP < 3 months | Needs team + funding + > 1 year |
| 5 | Monetization clarity | 0.10 | Obvious paid model with WTP signals (existing comparables priced > $0) | No clear path to revenue |
| 6 | Personal fit | 0.15 | You have skills, network, or domain edge | Outside your wheelhouse entirely |
| 7 | Time-to-signal | 0.10 | Validate in days (landing page, survey, prototype) | Validation needs a year of building |

**Final score** = round(sum(dimension × weight × 10)).

## Bands

From `$PWD/CLAUDE.md` (defaults shown):

- `>= 80` — **Strong**. Suggest moving to `Validated`.
- `60–79` — **Worth deeper research**. Suggest `/idea-vault:deep-research`
  if not already run.
- `40–59` — **Marginal**. Park.
- `< 40` — **Kill**. Suggest moving to `Killed`.

## Steps

### 1. Load context

Read `$PWD/ideas/<slug>/index.md` (description),
`$PWD/ideas/<slug>/research.md` (full report). If `research.md` is missing
or has fewer than 200 words of real content, refuse: "This idea needs
research first. Run /idea-vault:research <slug>."

### 2. Evaluate each dimension

For each of the 7 dimensions:

- Read the relevant evidence from `research.md`.
- Pick a 0–10 integer. Be honest, not generous.
- Write a 1-sentence rationale citing specific evidence ("Reddit
  r/foo has 40k members and 3 paid SaaS comparables exist").

For **personal fit**: if you have no information about the user's
skills/background, assume neutral (5) and note "user input needed".

### 3. Compute final score

```
final = round(sum(score_i * weight_i) * 10)
```

Example: scores [8,9,7,6,8,5,7], weights [.15,.20,.15,.15,.10,.15,.10]:
```
0.15*8 + 0.20*9 + 0.15*7 + 0.15*6 + 0.10*8 + 0.15*5 + 0.10*7 = 7.10
final = 71
```

### 4. Write score block to index.md

In `$PWD/ideas/<slug>/index.md`, replace or insert (after the description)
a block like:

```markdown
## Score: 71/100 — Worth deeper research

Last scored: <YYYY-MM-DD>

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Market size & demand | 8 | <evidence cite> |
| Competition gap | 9 | <evidence cite> |
| Differentiation potential | 7 | <evidence cite> |
| Build complexity | 6 | <evidence cite> |
| Monetization clarity | 8 | <evidence cite> |
| Personal fit | 5 | (user input needed) |
| Time-to-signal | 7 | <evidence cite> |

**Suggested action:** run `/idea-vault:deep-research <slug>` to firm up
borderline dimensions.
```

Update `Last scored: <date>` in the metadata block at the top of
`$PWD/ideas/<slug>/index.md`.

### 5. Suggest status transition (do not apply)

- Score >= 80 and current status is `Researching` → suggest `Validated`.
- Score < 40 and current status is `Researching` → suggest `Killed`.
- Otherwise: no suggestion.

If a suggestion fires, ask the user: "Apply status change to <X>? (yes/no)".
Only update `$PWD/inbox.md` and `$PWD/ideas/<slug>/index.md` `Status:`
lines after explicit yes.

### 6. Regenerate top-ideas.md

Walk all `$PWD/ideas/*/index.md`, collect (slug, title, score, status).
Sort descending by score. Write `$PWD/top-ideas.md`:

```markdown
# Top Ideas

Auto-generated. Do not edit manually.

Last updated: <ISO datetime>

## Top 10 by score

| Rank | Idea | Score | Status | Updated |
|------|------|-------|--------|---------|
| 1 | <slug> — <title> | 87 | Validated | 2026-05-04 |
| 2 | ...

## Recently scored

(Last 5 scoring events, newest first.)

- 2026-05-04 — `<slug>` scored 71 (was —).
- ...
```

### 7. Confirmation

One line: "Scored `<slug>` 71/100 (Worth deeper research). top-ideas.md
updated."

If status suggestion fires, add a second line asking yes/no.

## Edge cases

- **Re-score** (existing score block present): show old vs new in
  confirmation. Overwrite the block. Update `Last scored`.
- **No research yet**: refuse, do not score.
- **Research is a stub from a failed run**: refuse with same message.
- **Personal fit unknown**: default to 5 with note. Ask the user once,
  then remember in `$PWD/ideas/<slug>/index.md` for future re-scores.
