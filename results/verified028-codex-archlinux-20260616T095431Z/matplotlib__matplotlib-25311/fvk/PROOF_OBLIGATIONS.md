# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Common Producer Coverage

Both reported public paths must reach `DraggableBase`:

- `Legend.set_draggable(True)` creates `DraggableLegend`, which inherits from
  `DraggableOffsetBox`, which inherits from `DraggableBase`.
- `Annotation.draggable(True)` creates `DraggableAnnotation`, which inherits
  from `DraggableBase`.

This discharges S-001 and S-002 at the producer level.

## PO-002: Helper Pickle State Contains No Live Canvas

For any helper dictionary state `H`, `DraggableBase.__getstate__` must remove or
neutralize every direct canvas storage slot before pickle serializes `H`.

Required postcondition:

- no `canvas` key;
- `_canvas is None`;
- no `background` key;
- `got_artist is False`.

Formal claim: `DRAGGABLE-GETSTATE-NO-CANVAS`.

## PO-003: Legacy Canvas-Key Robustness

Because V1 introduced a `canvas` property and `_canvas` backing field, a helper
state with a legacy/manual `canvas` dictionary key must still be sanitized by
`__getstate__`.

Formal claim contribution: `DRAGGABLE-GETSTATE-NO-CANVAS`.

## PO-004: Restore State Does Not Revive Old Canvas

For any restored helper state, `__setstate__` must drop a legacy `canvas` key
and ensure `_canvas` exists, defaulting to `None`.

Formal claim: `DRAGGABLE-SETSTATE-CANVAS-DEFAULT`.

## PO-005: Lazy Canvas Resolution Preserves Draggability

After unpickling, if the reference artist is still parented to a figure,
`helper.canvas` must resolve the current `ref_artist.figure.canvas`, not the
pre-pickle backend canvas.

Formal claim: `DRAGGABLE-CANVAS-LAZY-RESTORE`.

## PO-006: Figure Pickle Graph Has No Helper Canvas Path

Given existing `Figure.__getstate__` removes `Figure.canvas`, and PO-002 removes
the helper canvas path, a figure containing draggable helpers has no live
backend canvas reachable through the modeled helper state.

Formal claim: `FIGURE-PICKLE-WITH-DRAGGABLE`.

## PO-007: Blitting Requires A Current Canvas

`_use_blitting()` must be false when no current canvas can be resolved.

Formal claim: `DRAGGABLE-BLIT-SAFE-WHEN-NO-CANVAS`.

## PO-008: Honesty Boundary

The proof is constructed over a minimal state-transition model, not full Python
pickle or a real backend. It must be labeled constructed, not machine-checked,
and no test removal is justified until the emitted commands are run and normal
integration coverage remains in place.
