# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the V1 edit directly addresses
the construction-time root cause from the public issue and did not surface a
source defect requiring a V2 patch.

## Trace To Findings And Proof Obligations

1. Keep `SpanSelector.new_axes` using `Axes.add_artist` for `self._rect`.

   Justification: Finding F2 confirms that V1 removes the `add_patch` path that
   polluted `dataLim`. PO2 discharges the specific obligation: `add_artist`
   attaches the rectangle without calling `_update_patch_limits` or
   `update_datalim`. This is the intended fix for F1's old rectangle-side root
   cause.

2. Keep `ToolLineHandles.__init__` constructing `Line2D` handles directly and
   attaching them with `Axes.add_artist`.

   Justification: Finding F2 confirms that V1 removes the old `axvline`/
   `axhline` path. PO3 discharges the handle obligation: direct `Line2D`
   construction plus `add_artist` avoids `_update_line_limits` and
   `_request_autoscale_view`, so the initial handle coordinate `0` no longer
   becomes plotted data or an autoscale trigger.

3. Do not add a second source edit for handle geometry.

   Justification: Finding F3 and PO4 show that V1 preserves the required helper
   artists. The rectangle creation code is unchanged except for attachment, and
   handle lines still use the same blended x-axis/y-axis transforms and data
   arrays needed by `positions`, `set_data`, visibility toggling, and removal.

4. Do not change public signatures or tests.

   Justification: Finding F4 and PO6 show no public API compatibility issue in
   local source inspection. The task also forbids test edits. Suggested future
   tests are recorded only in `fvk/ITERATION_GUIDANCE.md`.

5. Do not claim machine-checked proof or delete tests.

   Justification: Finding F5 and PO7 record that the environment forbids tests,
   Python execution, and K tooling. `fvk/PROOF.md` therefore labels the proof
   constructed, not machine-checked, and records the `kompile`/`kast`/`kprove`
   commands for future use rather than executing them.

## Alternative Considered

The main alternative was to add another source edit around `ToolLineHandles`
argument compatibility. The compatibility audit found no public signature
change, no new virtual dispatch call, and no public evidence requiring
standalone `ToolLineHandles` to autoscale axes. Because F2/PO3 already discharge
the issue-critical behavior and F3/PO4 preserve helper semantics, an additional
edit would be unrelated to the public bug and was rejected.

## Execution Constraint

No tests, Python snippets, or K commands were run. All conclusions are from
local source inspection and constructed FVK reasoning.
