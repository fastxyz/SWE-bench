# Baseline Notes

## Root Cause

`DraggableBase` stored a direct reference to `ref_artist.figure.canvas` on
`self.canvas`. Draggable legends and draggable annotations keep a
`DraggableBase` subclass instance on the artist as `_draggable`, so pickling a
figure with dragging enabled reached the live backend canvas through that
helper. `Figure.__getstate__` already removes the figure's own `canvas`
attribute because canvases are not generally picklable, but the draggable
helper kept an independent canvas reference. With GUI backends such as QtAgg,
that reference caused `TypeError: cannot pickle 'FigureCanvasQTAgg' object`.

## Changed Files

`repo/lib/matplotlib/offsetbox.py`

- Changed `DraggableBase` to store the canvas internally as `_canvas`.
- Added a `canvas` property that lazily resolves the current figure canvas when
  `_canvas` is absent after unpickling.
- Added `__getstate__` to omit the live canvas from draggable helper pickles
  and clear transient in-progress drag state that depends on a live renderer
  buffer.
- Added `__setstate__` compatibility handling for older state dictionaries and
  ensured restored helpers start with `_canvas = None`.
- Gated blitting operations on the currently resolved canvas, so a helper
  restored onto a different canvas class does not reuse stale support
  assumptions from the original canvas.
- Updated `disconnect` to tolerate the absence of a resolvable canvas, which can
  happen if an unpickled helper is detached before it has resolved a new canvas.

## Assumptions and Alternatives

I assumed the intended behavior is that draggable legends and annotations remain
draggable after a pickle round trip when their callback registry entries are
restored, because `DraggableBase` registers its callbacks with
`_connect_picklable`.

I considered dropping `_draggable` from `Legend` and `Annotation` during
pickling, but rejected that because it would make pickling succeed by silently
losing draggable state. Fixing `DraggableBase` directly addresses both affected
artist types and preserves the existing callback design.

I also considered changing `Figure.__getstate__`, but rejected that because the
figure already removes its own canvas reference; the extra unpicklable reference
is introduced specifically by the draggable helper.

No tests or project code were run, per the task constraints. I only performed
static source inspection and a `git diff --check` whitespace check.
