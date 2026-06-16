# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed Symbols

`matplotlib.offsetbox.DraggableBase.canvas`

- V1 changed direct attribute storage into a property backed by `_canvas`.
- V2 keeps a property setter, so code assigning `helper.canvas = canvas` still
  stores the canvas value.
- Internal callsites continue to read `self.canvas`.
- Constructor signatures are unchanged.
- Compatibility verdict: PASS.

`matplotlib.offsetbox.DraggableBase.__getstate__`

- New serialization hook; no public signature impact.
- V2 drops both `_canvas` and any legacy/manual `canvas` key from serialized
  state.
- Compatibility verdict: PASS.

`matplotlib.offsetbox.DraggableBase._use_blitting`

- Private helper added for current-canvas blit checks.
- No public API impact.
- Compatibility verdict: PASS.

## Public Producers

`Legend.set_draggable(state, use_blit=False, update='loc')`

- Signature unchanged.
- Still returns `.DraggableLegend` when enabled and `None` when disabled.
- Uses `DraggableLegend`, a `DraggableBase` subclass, so it inherits the
  serialization invariant.
- Compatibility verdict: PASS.

`Annotation.draggable(state=None, use_blit=False)`

- Signature unchanged.
- Still returns `.DraggableAnnotation` when enabled and `None` when disabled.
- Uses `DraggableAnnotation`, a `DraggableBase` subclass, so it inherits the
  serialization invariant.
- Compatibility verdict: PASS.

No public callsite or subclass override requiring code changes was identified
under `repo/lib/matplotlib`.
