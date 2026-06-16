# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

This FVK pass audits the pickle-relevant behavior of draggable Matplotlib
helpers introduced by:

- `Legend.set_draggable(...) -> DraggableLegend`
- `Annotation.draggable(...) -> DraggableAnnotation`

Both helpers inherit from `DraggableBase`, so the common serialization contract
belongs in `repo/lib/matplotlib/offsetbox.py`.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| S-001 | Issue expected outcome: "Pickling successful" after `leg.set_draggable(True)` | A figure with a draggable legend must be picklable. |
| S-002 | Issue says "Same error comes for draggable annotations." | The same invariant must hold for draggable annotations. |
| S-003 | Issue actual outcome: `TypeError: cannot pickle 'FigureCanvasQTAgg' object` | A live backend canvas must not be reachable from the serialized draggable helper state. |
| S-004 | `Figure.__getstate__` removes `canvas` because "The canvas cannot currently be pickled" | The fix should mirror figure-level canvas removal on the helper path rather than changing figure pickling policy. |
| S-005 | `CallbackRegistry._connect_picklable` keeps selected callbacks through pickling | Draggable state and callbacks may be preserved if the live canvas is not preserved. |
| S-006 | Public signatures of `Legend.set_draggable` and `Annotation.draggable` | The repair must not require API changes. |

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For every draggable helper `H` created through the public legend or annotation
API:

1. `DraggableBase.__getstate__(H)` returns a state dictionary that:
   - has no legacy `canvas` entry;
   - has `_canvas` set to `None`;
   - has `got_artist` set to `False`;
   - has no `background` entry;
   - preserves non-transient fields such as `ref_artist`, `_use_blit`, and
     callback ids.
2. `DraggableBase.__setstate__(state)` removes any legacy `canvas` entry and
   guarantees an `_canvas` key exists, defaulting to `None`.
3. `DraggableBase.canvas` resolves lazily:
   - if `_canvas` is already present, it returns that value;
   - if `_canvas is None` and `ref_artist.figure` is still present, it resolves
     the current `ref_artist.figure.canvas`;
   - if no figure is present, it returns `None`.
4. `_use_blitting()` is false when no current canvas can be resolved.
5. Given the existing `Figure.__getstate__` behavior that removes the figure's
   own `canvas`, a draggable legend or annotation helper contributes no live
   backend canvas to the figure pickle graph.

## Preconditions and Frame Conditions

- The object graph is a normal Matplotlib figure graph with draggable helpers
  created by public APIs.
- The proof abstracts Python pickle traversal as dictionary-state traversal.
- The proof is partial correctness: if pickle traverses the modeled graph, the
  helper path is canvas-free.
- No public signatures, return types, or public draggable toggling semantics are
  changed.

## Formal Core

The formal core files are:

- `fvk/mini-python-pickle.k`
- `fvk/draggable-pickle-spec.k`

The exact commands to machine-check later are recorded in the spec file and in
`fvk/PROOF.md`; they were not executed in this session.
