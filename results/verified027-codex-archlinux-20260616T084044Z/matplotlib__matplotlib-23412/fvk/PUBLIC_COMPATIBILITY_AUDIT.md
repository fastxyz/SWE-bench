# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed public behavior

`matplotlib.patches.Patch.draw(renderer)` now honors the stored dash offset
instead of temporarily forcing it to `0`.

## API signatures

| Symbol | Signature changed? | Result |
| --- | --- | --- |
| `Patch.draw(self, renderer)` | No | Compatible |
| `Patch._bind_draw_path_function(self, renderer)` | No | Compatible |
| `Patch.set_linestyle(self, ls)` | No | Compatible |
| `Patch.set_linewidth(self, w)` | No | Compatible |

## Dispatch and subclass impact

- Subclasses that inherit `Patch.draw()` now receive the intended behavior:
  rectangles, ellipses, path patches, and other base-patch draw users forward
  non-zero offsets.
- `Shadow.draw()` delegates to `super().draw(renderer)`, so it receives the same
  fix through normal inheritance.
- `Arc.draw()` calls `Patch.draw(self, renderer)` for its generated arc path
  segments, so each segment now forwards the requested dash offset rather than
  zeroing it.
- `FancyArrowPatch.draw()` already calls `_bind_draw_path_function()` directly
  and did not contain the zero-offset override. V1 does not change its dispatch
  shape.
- `ConnectionPatch.draw()` delegates through `FancyArrowPatch`, so no new
  compatibility issue is introduced.

## Caller compatibility

No call sites need updates because no method accepts new parameters or returns a
new shape. The only compatibility break is behavioral: code that explicitly set
a non-zero dash offset on a patch while relying on that offset being ignored
will now see the offset honored. Public evidence E7 rejects preserving that
legacy behavior.

## Result

No unhandled public callsite, subclass override, or signature compatibility
problem blocks V1.
