# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

Keep the V1 axes-level visibility guard and tightbbox `None` guard, and add the renderer-precondition guard before the visibility guard in `Axes3D.draw`.

This is the smallest V2 change that satisfies all proof obligations:

- `F-001` / `PO-DRAW-INVISIBLE`: keep the early visibility return before any 3D draw side effects.
- `F-002` / `PO-DRAW-NONE-RENDERER`: add the inherited no-renderer guard before the visibility return.
- `F-003` / `PO-BBOX-INVISIBLE`: keep the early `None` return in `get_tightbbox`.
- `PO-DRAW-VISIBLE-FRAME` and `PO-BBOX-VISIBLE-FRAME`: leave visible behavior unchanged.

## Deferred or rejected hypotheses

`NF-001` records an adjacent per-axis visibility hypothesis. Do not include it in this patch unless new public intent specifically asks for `ax.xaxis.set_visible(False)` / `ax.yaxis.set_visible(False)` / `ax.zaxis.set_visible(False)` behavior on 3D axes, or a follow-up audit scopes that public `Axis3D` contract explicitly.

## Suggested tests for a normal development environment

Do not run these in this benchmark session. They are suggestions for a future environment:

- Render a figure with two 3D subplots, call `ax1.set_visible(False)`, and assert the left 3D axes patch/panes/axes are absent from the output.
- Call `Axes3D.draw(None)` directly and assert it raises `RuntimeError('No renderer defined')`.
- Exercise `Axes3D.get_tightbbox(...)` after `set_visible(False)` and assert it returns `None`.

No existing tests are recommended for deletion. Any removal would be conditioned on machine-checking the K claims first.
