# FVK Proof Obligations

Status: constructed, not machine-checked. The obligations below correspond to `fvk/axes3d-visible-spec.k`.

## PO-DRAW-INVISIBLE

Claim: `draw3d(validRenderer, false)` reaches normal return with only `returnInvisible` in the observable event log.

Intent evidence: E1, E2, E3.

Required code shape: the `self.get_visible()` guard must occur before `_unstale_viewLim`, `self.patch.draw(renderer)`, aspect/projection work, child projection, pane drawing, axis drawing, and `super().draw(renderer)`.

V2 status: discharged by `repo/lib/mpl_toolkits/mplot3d/axes3d.py:392`.

## PO-DRAW-NONE-RENDERER

Claim: `draw3d(noneRenderer, false)` raises the no-renderer error, represented by `raiseNoRenderer`, before any visibility-dependent return.

Intent evidence: E4 and public compatibility with `Axes.draw`.

Required code shape: `if renderer is None: raise RuntimeError('No renderer defined')` must precede the visibility guard.

V2 status: discharged by `repo/lib/mpl_toolkits/mplot3d/axes3d.py:390`.

## PO-DRAW-VISIBLE-FRAME

Claim: `draw3d(validRenderer, true)` preserves the existing visible draw sequence: view limit unstaling, patch draw, aspect application, projection computation, 3D child projection/zordering, pane draw, axis draw, then base draw delegation.

Intent evidence: I3 and implementation frame condition.

Required code shape: no visible-path side effects are removed or reordered except by the new guards on paths that do not reach the visible draw sequence.

V2 status: discharged by inspection of `repo/lib/mpl_toolkits/mplot3d/axes3d.py:394-448`.

## PO-BBOX-INVISIBLE

Claim: `tightbbox3d(false, noneBBox)` returns `bboxNone` with only `returnInvisibleBBox` in the event log.

Intent evidence: E5 plus the issue's invisible-axes expectation for layout-adjacent visibility.

Required code shape: after delegating to `super().get_tightbbox(...)`, `Axes3D.get_tightbbox` must return `None` immediately when `ret is None`.

V2 status: discharged by `repo/lib/mpl_toolkits/mplot3d/axes3d.py:3109`.

## PO-BBOX-VISIBLE-FRAME

Claim: `tightbbox3d(true, someBBox)` preserves visible behavior by starting from the base bbox and unioning visible 3D-axis bboxes.

Intent evidence: I4 and implementation frame condition.

Required code shape: the visible `batch = [ret]` and subsequent axis-bbox union logic remain unchanged.

V2 status: discharged by inspection of `repo/lib/mpl_toolkits/mplot3d/axes3d.py:3111-3119`.

## Machine-check commands not run

These commands are recorded for a future environment with K installed:

```sh
cd fvk
kompile mini-mpl3d-draw.k --backend haskell
kast --backend haskell axes3d-visible-spec.k
kprove axes3d-visible-spec.k
```
