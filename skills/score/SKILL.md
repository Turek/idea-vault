---
name: score
description: Score a researched idea on the 10-dimension rubric using a weighted geometric mean and confidence scalar, classify into one of four tiers, and update top-ideas.md. Use when the user runs the score, rescore, or score-pending commands, or asks to evaluate, rate, or rank an idea.
---

# Score skill

Applies a 10-dimension weighted **geometric-mean** rubric tempered by an
evidence-quality **confidence scalar**, classifies the idea into one of
four strategic tiers, writes the score block into `index.md`, and
regenerates `top-ideas.md`.

## Inputs

- Slug.
- `$PWD/ideas/<slug>/index.md` (description).
- `$PWD/ideas/<slug>/research.md` (must exist and be non-empty —
  otherwise refuse and tell the user to run research first).
- `$PWD/CLAUDE.md` for weights, critical pillars, confidence anchors,
  and tier thresholds.

All idea data lives in the user's project (`$PWD`), not the plugin.

## Why geometric mean and confidence

The previous rubric summed `score × weight` and returned a 0–100 band.
That model lets a fatal flaw in one dimension (e.g. zero monetization)
get masked by strengths in unrelated ones. Real venture viability is
multiplicative — without distribution, money, or legal headroom, the
idea fails regardless of how good the rest looks.

Geometric mean penalizes weakness in any single dimension. The
confidence scalar then discounts the result based on how much of the
research is hard evidence vs. assumption. The result classifies into
**Ready to Build / Needs Empirical Validation / Structural Pivot
Required / Unviable** rather than a vanilla 0–100 band.

## The rubric (10 dimensions)

Score each dimension as an integer 0–10. Weights sum to 1.00.
**Critical** pillars (5) trigger an immediate Tier 4 disqualifier if
they score 0 or 1, bypassing the math entirely.

| # | Dimension | Weight | Critical? | Anchor 10 | Anchor 5 | Anchor 0 |
|---|-----------|--------|-----------|-----------|----------|----------|
| 1 | Problem Urgency | 0.12 | Yes | recurring "this is killing us" complaints, named workarounds, paid hacks, active forum threads with 50+ upvotes | pain real but tolerated; users mention it but haven't sought solutions | no evidence of pain; speculative "people might want" framing |
| 2 | Market Scale (TAM/SOM) | 0.10 | Yes | SOM with named segment, count, bottom-up reasoning (e.g. 120k US indie podcasters at $20/mo) | TAM cited, SOM hand-wavy | only undefined "huge market" or top-down TAM with no segmentation |
| 3 | Competition Landscape | 0.10 | No | several incumbents with documented repeated user complaints; clear gap | crowded with adequate tools; or empty market with unclear demand | no incumbents AND no demand evidence; or dominant incumbent with no complaints |
| 4 | Unfair Advantage | 0.12 | No | defensible moat: proprietary data, network effect, regulatory cert, non-replicable founder access | real differentiator copyable in under 12 months | "same but better/cheaper"; no asymmetry |
| 5 | Distribution Viability | 0.12 | Yes | named low-CAC channel with comparables (organic loop, owned audience, SEO, partner); LTV:CAC over 3 plausible | one channel identified, costs unknown | only "we'll do content marketing" or paid-only with no LTV math |
| 6 | Monetization & WTP | 0.12 | Yes | comparable products priced; named WTP signal (interviews, pre-orders, existing spend) | plausible model, no direct WTP evidence | no revenue model OR free-only with no upgrade path |
| 7 | Regulatory Feasibility | 0.08 | Yes | no exposure, or clear precedent and bounded compliance cost | some exposure (PII, payments, content) but well-trodden | hard blockers: HIPAA without infra, securities, FDA, IP held by incumbent |
| 8 | Execution Complexity | 0.08 | No | solo MVP under 3 months, off-the-shelf stack | small team, 3–9 months | needs team plus funding plus over 12 months, novel research |
| 9 | Founder-Market Fit | 0.08 | No | direct domain experience, network, unique access | adjacent skills, must learn the space | outside wheelhouse with no entry point |
| 10 | Validation Velocity | 0.08 | No | landing page / smoke test / 5 interviews in days | needs prototype, weeks | requires building the product (months+) |

**Critical pillars** (default; from `CLAUDE.md`):
Problem Urgency, Market Scale, Distribution Viability, Monetization & WTP,
Regulatory Feasibility.

## The math

Per-dimension integer score `s_i ∈ {0..10}`. Normalize with a 0.5 floor
to keep `log(0)` out of the math (critical-pillar zeros short-circuit
before this step):

```
s_i_norm = max(s_i, 0.5) / 10
```

Weighted geometric mean:

```
G    = product over i of (s_i_norm ^ w_i)        # weights sum to 1.0
base = round(G * 100)                             # integer 0–100
```

Confidence scalar `C ∈ [0, 1]`, picked once per scoring pass from the
dominant evidence quality across `research.md`:

| Level  | C    | Trigger |
|--------|------|---------|
| High   | 1.00 | real user testing, signed LOIs, statistically significant surveys, paid pre-orders |
| Medium | 0.80 | secondary market research, competitive teardowns, public feature requests, sized waitlists |
| Low    | 0.50 | team opinions, deductions from analogous markets, anecdotal feedback |
| Guess  | 0.30 | pure intuition, no citations available |

Final:

```
final = round(base * C)        # integer 0–100
```

### Worked example

Scores: Urgency 8, Scale 6, Competition 7, Advantage 7, Distribution 6,
Monetization 7, Regulatory 9, Execution 6, Fit 5, Velocity 8.
Confidence Medium (0.80).

```
ln(G) ≈ 0.12·ln(.8) + 0.10·ln(.6) + 0.10·ln(.7) + 0.12·ln(.7) + 0.12·ln(.6)
      + 0.12·ln(.7) + 0.08·ln(.9) + 0.08·ln(.6) + 0.08·ln(.5) + 0.08·ln(.8)
      ≈ -0.383
G    ≈ 0.682   →   base = 68
final = round(68 × 0.80) = 54
```

The same scores under the old additive rubric would yield ~69. The
geometric model compresses meaningfully, and that compression widens
sharply if any single dimension falls. If Distribution were 1 instead
of 6, the path bypasses math: Tier 4, "Disqualifier: Distribution
Viability = 1".

## Tier classification

```
disqualified = any critical-pillar dimension is 0 or 1

if disqualified:                                    tier = 4
elif final < 30:                                    tier = 4
elif base >= 70 and C < 0.80:                       tier = 2
elif final >= 70:                                   tier = 1
elif final >= 50:                                   tier = 2
elif final >= 30:                                   tier = 3
elif (any non-critical dim is 0 or 1) and base >= 50: tier = 3
else:                                               tier = 4
```

Order matters; first match wins. Labels:

- **Tier 1 — Ready to Build.** Strong score, strong evidence, no
  disqualifier. Move toward MVP.
- **Tier 2 — Needs Empirical Validation.** Either a strong score with
  weak evidence, or a moderate score with solid evidence. Run smoke
  tests / customer-dev calls before building.
- **Tier 3 — Structural Pivot Required.** Promising overall, but a
  specific dimension is sinking it. Address that dimension or pivot
  scope.
- **Tier 4 — Unviable.** Critical-pillar disqualifier, or final under
  30. Move to Killed unless the blocker can be removed.

Threshold values come from `$PWD/CLAUDE.md` (`scoring.tiers`).

## Steps

### 1. Load context

Read `$PWD/ideas/<slug>/index.md` (description),
`$PWD/ideas/<slug>/research.md` (full report). If `research.md` is
missing or has fewer than 200 words of real content, refuse:
"This idea needs research first. Run /idea-vault:research <slug>."

Also read the `scoring:` block from `$PWD/CLAUDE.md` so weights,
critical pillars, confidence anchors, and tier thresholds reflect any
project-specific overrides.

### 2. Atomic per-criterion evaluation

For each of the 10 dimensions, in order, emit this five-step block in
the chat output **before** writing any number:

1. **Isolate.** Name the dimension and its one-sentence rubric
   definition.
2. **Cite.** Quote a verbatim passage from `research.md` with section
   header. If no passage exists, write `NO EVIDENCE` — that forces a
   low score and degrades the confidence selection.
3. **Compare.** Map the citation to the 10/5/0 anchor. State which
   anchor it sits closest to and why.
4. **Detect vanity.** If the citation relies on **vanity metrics** —
   page views, follower counts, generic positive sentiment, undefined
   "huge TAM", "people are excited" — flag explicitly and discount one
   anchor step (e.g. 6 → 4). If the citation is **actionable**
   (waitlist conversion %, pre-orders, signed LOI, smoke-test CTR,
   existing-spend interviews), note "actionable" and do not discount.
5. **Quantify.** Now and only now, write the integer 0–10 with a
   one-sentence justification referencing the citation.

If a critical-pillar dimension lands at 0 or 1, stop the loop, list
which remaining dimensions were unscored (so a future rescore knows
what to revisit), and skip directly to Step 5 (disqualified output).

For **Founder-Market Fit**: if you have no information about the
user's skills/background, default to 5 with the note `(user input
needed)` and ask the user once at the end of the run, then store the
answer in `$PWD/ideas/<slug>/index.md` for future rescores.

### 3. Pick confidence

Across the full set of citations, choose the dominant evidence
quality once: High / Medium / Low / Guess. Do not average per-dimension
confidence; pick the level that best describes the research as a whole.
If most citations are anecdotal but two are LOIs, that is still Low —
the dominant character of the evidence is what matters.

### 4. Compute base, final, and tier

Apply the math from "The math" above. Then run the tier classification
flow.

### 5. Write the score block to `index.md`

In `$PWD/ideas/<slug>/index.md`, replace or insert (after the
description) the appropriate block.

#### Normal case

```markdown
## Score: 54/100 — Tier 2: Needs Empirical Validation

Last scored: 2026-05-06
Base (geometric mean × 100): 68
Confidence: Medium (0.80)
Disqualifier: none

| # | Dimension | Score | Weight | Evidence (research.md) |
|---|-----------|-------|--------|------------------------|
| 1 | Problem Urgency | 8 | 0.12 | "users routinely lose 2h/week to manual reconciliation" — Pain Signals §2 |
| 2 | Market Scale | 6 | 0.10 | "~40k US indie bookkeepers; SOM ~$8M ARR at $200/yr" — Market §1 |
| 3 | Competition Landscape | 7 | 0.10 | "QuickBooks owns SMB; gap in 1–5 employee segment" — Competitors §3 |
| 4 | Unfair Advantage | 7 | 0.12 | "Founder ran a bookkeeping practice 2018–2023; direct customer access" — Fit §1 |
| 5 | Distribution Viability | 6 | 0.12 | "r/Bookkeeping (28k) and 4 active newsletters; SEO opportunity for 'small biz reconciliation'" — Distribution §2 |
| 6 | Monetization & WTP | 7 | 0.12 | "Bench priced at $299/mo; interview subjects volunteered $50–80/mo" — WTP §1 |
| 7 | Regulatory Feasibility | 9 | 0.08 | "no PII beyond standard SaaS; no financial-license exposure" — Risk §1 |
| 8 | Execution Complexity | 6 | 0.08 | "Plaid + LLM categorization, ~4mo solo MVP" — Build §1 |
| 9 | Founder-Market Fit | 5 | 0.08 | (user input needed) |
| 10 | Validation Velocity | 8 | 0.08 | "Landing page + 10 customer-dev calls feasible in 2 weeks" — Validation §1 |

**Tier rule fired:** base 68 + confidence 0.80 → final 54, mid-band → Tier 2.

**Suggested action:** firm up Market Scale and Distribution via deep
research; book 5 customer-dev calls to lift Confidence to High.
```

#### Disqualified case

```markdown
## Score: — — Tier 4: Unviable

Last scored: 2026-05-06
Disqualifier: Regulatory Feasibility = 1
Dimensions not scored: Execution Complexity, Founder-Market Fit, Validation Velocity

**Risk analysis.** "Requires HIPAA-compliant infra and BAA with every
covered entity; founder has no healthcare ops experience" — Risk §2.
This is a structural blocker, not a math result.

**Suggested action:** move to Killed, or pivot scope outside
HIPAA-covered data.
```

Update `Last scored: <date>` in the metadata block at the top of
`index.md`.

### 6. Suggest status transition (do not apply)

- Tier 1 and current status `Researching` → suggest `Validated`.
- Tier 4 and current status `Researching` → suggest `Killed`.
- Otherwise: no suggestion.

If a suggestion fires, ask: "Apply status change to <X>? (yes/no)".
Only update the `Status:` lines in `$PWD/inbox.md` and
`$PWD/ideas/<slug>/index.md` after explicit yes.

### 7. Regenerate `top-ideas.md`

Walk all `$PWD/ideas/*/index.md`, collect (slug, title, final, base,
confidence_level, tier, status, last_scored). Sort descending by
`final`. Tier 4 disqualified entries appear at the bottom with
`Final = 0` for sort stability. Write `$PWD/top-ideas.md`:

```markdown
# Top Ideas

Auto-generated. Do not edit manually.

Last updated: 2026-05-06T09:00:00Z

## Top 10 by score

| Rank | Idea | Final | Base | Conf | Tier | Status | Updated |
|------|------|-------|------|------|------|--------|---------|
| 1 | <slug> — <title> | 78 | 81 | High | 1 | Validated | 2026-05-04 |
| 2 | <slug> — <title> | 54 | 68 | Med  | 2 | Researching | 2026-05-06 |

## Recently scored

(Last 5 scoring events, newest first.)

- 2026-05-06 — `<slug>` scored 54 (was 71 under v1 rubric). Tier 2.
- ...
```

### 8. Confirmation

One line: `"Scored <slug> 54/100 Tier 2 (Needs Empirical Validation).
top-ideas.md updated."`

If the idea had a v1 7-dimension score block, append `(was 71 under v1
rubric)` to the confirmation, and add the same annotation to the
"Recently scored" section.

If a status suggestion fires, add a second line asking yes/no.

## Edge cases

- **Re-score** with an existing v2 block present: show old vs new
  finals in the confirmation. Overwrite the block. Update
  `Last scored`.
- **Re-score against a v1 7-dimension block** (the old rubric): detect
  by the presence of v1 dimension names (`Market size & demand`,
  `Competition gap`, `Differentiation potential`, `Build complexity`,
  `Personal fit`, `Time-to-signal`). Overwrite the entire block with
  the new format. The dimensions don't map 1:1, so re-evaluate
  against `research.md` from scratch — do not attempt to migrate the
  old per-dimension numbers. Confirmation includes
  `(was X under v1 rubric)`; the `top-ideas.md` Recently-scored
  entry annotates the migration once, then forgets it.
- **No research yet**: refuse, do not score.
- **Research is a stub from a failed run** (under 200 words of real
  content): refuse with the same message.
- **Founder-Market Fit unknown**: default to 5 with `(user input
  needed)`, ask the user once, then remember the answer in
  `index.md`.
- **All non-critical dims unknown** (NO EVIDENCE for everything
  except the criticals that passed): force confidence to Guess (0.30)
  and let the math fall where it falls. Final will almost always be
  Tier 3 or Tier 4 in this case.
