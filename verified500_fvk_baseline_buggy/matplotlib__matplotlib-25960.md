# matplotlib__matplotlib-25960

- **Verdict:** A_GENUINE_FIX — baseline reads spacing from the public `GridSpec.wspace/hspace`, so a user-built GridSpec's *subplot* spacing leaks into `add_subfigure()` placement; fvk scopes spacing to a private marker set only by `Figure.subfigures`, restoring the historical/gold behavior.
- **Pitch-worthiness (1-5):** 4

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
`Figure.subfigures(nrows, ncols, wspace=, hspace=)` ignored `wspace`/`hspace` (the gap between subfigures was always zero). The fix should make `subfigures(...)` honor the requested spacing.

## What baseline did
Baseline made `_redo_transform_rel_fig` read spacing from the gridspec (`gs.wspace`/`gs.hspace`, with a `gs._wspace` fallback for `GridSpecFromSubplotSpec`). This fixes the reported `subfigures(...)` path **but** also makes the separate public `add_subfigure(gs[i])` path pick up subplot spacing from any user-built GridSpec — a backward-compat regression (subplot spacing was never meant to affect subfigure placement).

## What fvk changed and why
fvk routes spacing through a private `_subfigure_wspace`/`_subfigure_hspace` marker that **only `Figure.subfigures` sets**. So `subfigures(...)` honors spacing (bug fixed) while `add_subfigure(user_gridspec)` ignores subplot spacing (historical/gold behavior preserved). The downstream geometry arithmetic is byte-identical between baseline and fvk.

## Concrete demonstration (numeric, from 3.6.3-structure source)
```python
fig.add_subfigure(fig.add_gridspec(1, 2, wspace=0.5)[0, 0])   # equal width ratios
```
| variant | x-extent of the subfigure |
|---|---|
| original / **gold** | `[0, 0.5]` (no gap) ✅ |
| **baseline** | `[0, 0.4]` — spurious 0.2 gap injected ❌ |
| **fvk** | `[0, 0.5]` (no gap) ✅ |

(baseline: `cell_w = 1/(2 + 0.5) = 0.4`; gold/fvk: `cell_w = 0.5`.)

## Why the tests missed it
The hidden test only exercises Path 1 (`Figure.subfigures(...)` with explicit wspace/hspace), which baseline and fvk both handle. No test calls `add_subfigure()` with a user GridSpec carrying subplot spacing, so baseline's leak is invisible to grading.

## FVK vs. Human Fix

**Human fix issue:** no.

Gold and FVK both distinguish subfigure spacing metadata from ordinary user-created `GridSpec` subplot spacing. Baseline reads public spacing too broadly, so unrelated subplot spacing leaks into subfigure placement.

Gold resets `left/right/bottom/top` only for the `subfigures`-created gridspec and routes spacing through a separate step — specifically *so* `add_subfigure` won't inherit gridspec spacing. fvk's private-marker approach reproduces gold's intent; baseline's public-attribute read does not. **GOLD_MATCH: partial.**

## Confidence & caveats
- **Med confidence:** behavior derived by reading matplotlib 3.6.3-structure source and computing the cell geometry by hand for all three variants (not executed on 3.8-dev). The gold patch's design choices strongly corroborate that `add_subfigure` is intended to ignore gridspec subplot spacing.
- The leak manifests only on `add_subfigure(user_gridspec_with_spacing)`, a less-common usage.
