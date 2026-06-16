# FVK Proof

Status: constructed, not machine-checked. No K tooling was run.

## Summary

The proof models only the control-flow slice relevant to the issue and V2 change: renderer validity, axes visibility, draw side effects, and tightbbox contribution. The observable event log distinguishes the reported failure (`drawPatch`, `draw3dPanes`, and `draw3dAxes` occurring while invisible) from the fixed behavior (`returnInvisible` only).

## Constructed proof sketch

`PO-DRAW-NONE-RENDERER`: symbolic execution of `draw3d(noneRenderer, V)` matches the first mini-semantics rule. The result is `raised` and the event log contains `raiseNoRenderer`. Because this rule is independent of `V`, it covers both visible and invisible states. In the source, this corresponds to the first branch in `Axes3D.draw`.

`PO-DRAW-INVISIBLE`: symbolic execution of `draw3d(validRenderer, false)` cannot match the no-renderer rule and matches the visibility rule. It reaches `.K` with only `returnInvisible`. This proves no patch/pane/axis/base-draw event can occur on the invisible path in the model. In the source, the visibility guard precedes every 3D-specific draw side effect.

`PO-DRAW-VISIBLE-FRAME`: symbolic execution of `draw3d(validRenderer, true)` reaches the visible rule. Its event list includes the same visible-path effects present before the patch: unstale view limits, patch drawing, aspect application, projection, 3D child projection/zordering, pane drawing, axis drawing, and base draw delegation. The V2 guards only affect invalid-renderer and invisible paths, so the visible frame is preserved.

`PO-BBOX-INVISIBLE`: symbolic execution of `tightbbox3d(false, noneBBox)` reaches `bboxNone` with `returnInvisibleBBox`. In the source, this is the `ret is None` guard immediately after `super().get_tightbbox(...)`; because the method returns there, no 3D-axis bbox union can occur.

`PO-BBOX-VISIBLE-FRAME`: symbolic execution of `tightbbox3d(true, someBBox)` reaches `bboxSome` after `baseTightbbox` and `union3dAxisBBoxes`. In the source, V2 leaves the visible union path unchanged after the `ret is None` guard.

## Adequacy and residual risk

The claims match the public intent ledger in `fvk/SPEC.md`: the issue requires axes-level invisibility after `ax1.set_visible(False)`, and the source-level API contract requires draw methods to have no effect when invisible. The renderer-precondition claim is a compatibility obligation from `Axes.draw` and is why V2 differs from V1.

This proof is partial correctness over a control-flow abstraction, not a pixel-level renderer proof. It does not prove GUI backend behavior, z-order numeric details, or termination/performance. It is constructed, not machine-checked; the recorded K commands must be run in an environment with K before treating the claims as machine verified.

## Test recommendations

No tests were inspected beyond public source context, no test files were edited, and no tests should be removed. A future public test for `ax.set_visible(False)` on a 3D axes rendering no visible patch/panes/axes would be covered by `PO-DRAW-INVISIBLE` after machine-checking. A future direct-call test for `ax.draw(None)` raising `RuntimeError` would be covered by `PO-DRAW-NONE-RENDERER` after machine-checking.

## Reproduce the machine check later

```sh
cd fvk
kompile mini-mpl3d-draw.k --backend haskell
kast --backend haskell axes3d-visible-spec.k
kprove axes3d-visible-spec.k
```
