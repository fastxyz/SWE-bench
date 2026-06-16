# FVK Notes

## Source decisions

V1's early `Axes3D.draw` visibility guard stands because `fvk/FINDINGS.md` records the original bug as `F-001`, and `fvk/PROOF_OBLIGATIONS.md` requires `PO-DRAW-INVISIBLE`: for a valid renderer and invisible axes, no patch, pane, axis, projection, or delegated base draw side effects may occur.

V2 changes V1 by adding the inherited renderer guard before the visibility guard. This comes from `F-002` and `PO-DRAW-NONE-RENDERER`: V1 would return silently for `draw(None)` when the axes was invisible, while `Axes.draw` raises `RuntimeError('No renderer defined')` before visibility is considered. The added guard preserves that compatibility condition.

V1's `Axes3D.get_tightbbox` `ret is None` guard stands because `F-003` and `PO-BBOX-INVISIBLE` require invisible 3D axes to preserve the base `None` tightbbox result and skip 3D-axis bbox union.

Visible-path code remains unchanged. `PO-DRAW-VISIBLE-FRAME` and `PO-BBOX-VISIBLE-FRAME` require the existing visible draw sequence and visible tightbbox union behavior to be preserved.

No per-axis visibility code was changed. `NF-001` records the rejected adjacent hypothesis: changing `axis3d.Axis.draw` / `draw_pane` could be a separate consistency improvement, but the public issue and reproduction are axes-level, and the changed public symbols in this patch already satisfy the issue-derived and compatibility obligations.

## Artifacts

The FVK package is under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`, plus the formal core files `mini-mpl3d-draw.k` and `axes3d-visible-spec.k`.

All proof results are labeled constructed, not machine-checked. I did not run tests, Python, `kompile`, `kast`, or `kprove`, per the benchmark instructions.
