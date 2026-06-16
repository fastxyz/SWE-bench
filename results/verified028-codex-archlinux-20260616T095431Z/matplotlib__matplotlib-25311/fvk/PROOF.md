# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test command was executed.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-python-pickle.k --backend haskell
kast --backend haskell fvk/draggable-pickle-spec.k
kprove fvk/draggable-pickle-spec.k
```

Expected result after any necessary syntax adaptation for a local K
installation: all claims discharge to `#Top`.

## Proof Summary

The issue reports a failed `pickle.dumps(fig)` when the figure contains a
draggable legend, and notes the same failure for draggable annotations. Both
public producers store a `DraggableBase` subclass on the artist as
`_draggable`. Therefore the proof centers on the helper state, not on separate
legend and annotation implementations.

`Figure.__getstate__` already removes the figure's own `canvas`, so the failing
path is any independent live canvas reference retained by the draggable helper.
The constructed proof shows that V2's helper serialization removes that path.

## Claim C-001: `DRAGGABLE-GETSTATE-NO-CANVAS`

Symbolic state:

- helper dictionary `H`;
- `H[KCanvas]` may be `LiveCanvas`;
- `H[KLegacyCanvas]` may be `LiveCanvas`;
- `H[KBackground]` may be a transient renderer buffer;
- all other fields are framed.

Execution:

1. `draggableGetState(H)` rewrites to `stripTransient(H)`.
2. `stripTransient` updates `KCanvas` to `None`.
3. It removes `KLegacyCanvas`.
4. It updates `KGotArtist` to `Bool(false)`.
5. It removes `KBackground`.
6. All other fields are framed unchanged.

Postcondition:

- no legacy canvas key remains;
- `_canvas` is `None`;
- no transient background remains;
- the helper state contains no modeled live canvas.

This discharges PO-002 and PO-003.

## Claim C-002: `DRAGGABLE-SETSTATE-CANVAS-DEFAULT`

Case split:

- If restored state lacks `_canvas`, `restoreState` inserts `_canvas = None` and
  removes `canvas`.
- If restored state already contains `_canvas`, `restoreState` removes
  `canvas` and preserves the existing `_canvas` entry.

In both cases, the old live backend canvas is not revived through a legacy
`canvas` key. This discharges PO-004.

## Claim C-003: `DRAGGABLE-CANVAS-LAZY-RESTORE`

Given a restored helper with `_canvas = None` and a still-parented reference
artist, the modeled `draggableCanvas` rule returns `KRefFigureCanvas`, the
current canvas attached to the artist's figure. This establishes that preserved
callbacks can use a post-unpickle canvas without storing the pre-pickle backend
canvas. This discharges PO-005.

## Claim C-004: `DRAGGABLE-BLIT-SAFE-WHEN-NO-CANVAS`

Given `_canvas = None` and no current figure canvas, `draggableUseBlitting`
rewrites to `Bool(false)`. Thus the helper cannot select a blit-only path
without a current canvas. This discharges PO-007.

## Claim C-005: `FIGURE-PICKLE-WITH-DRAGGABLE`

The figure-level proof composes two facts:

1. Existing source code removes `Figure.canvas` in `Figure.__getstate__`.
2. C-001 removes the draggable helper's canvas path.

By transitivity over pickle traversal of the modeled object graph, a figure
with a draggable legend or annotation has no live backend canvas reachable
through either modeled path. This discharges PO-006 for the reported root cause.

## Adequacy Check

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every claim. `fvk/SPEC_AUDIT.md`
marks each claim as matching the intent in `fvk/INTENT_SPEC.md`.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API or signature break.

## Test Recommendation

Do not remove tests. The proof was constructed but not machine-checked, and it
models a serialization invariant rather than full integration behavior. Useful
future tests would cover:

- pickling a figure after `Legend.set_draggable(True)`;
- pickling a figure after `Annotation.draggable(True)`;
- pickle round trip preserves `legend.get_draggable()`;
- `use_blit=True` does not retain the original backend canvas in helper state.
