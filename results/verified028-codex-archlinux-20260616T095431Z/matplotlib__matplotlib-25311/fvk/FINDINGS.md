# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof-obligation construction only.

## F-001: V1 Correctly Localized The Main Bug

Input/state: a `Figure` containing a draggable legend or annotation whose
helper stores a live backend canvas.

Observed before the repair: the draggable helper kept an independent canvas
reference, so pickle traversal could reach `FigureCanvasQTAgg` even though
`Figure.__getstate__` removed the figure's own `canvas`.

Expected: helper pickle state must not contain a live backend canvas.

Trace: S-001, S-002, S-003; PO-001, PO-002, PO-006.

Disposition: confirmed. V1's `_canvas = None` in `__getstate__` addresses the
normal helper state created by patched `DraggableBase.__init__`.

## F-002: V1 Missed A Legacy/Manual `canvas` Dictionary Key In `__getstate__`

Input/state: a `DraggableBase` instance whose `__dict__` contains a legacy or
manually inserted `canvas` key in addition to, or instead of, `_canvas`.

Observed in V1: `__setstate__` removed `canvas`, but `__getstate__` did not.
If such a key pointed to a live backend canvas, pickle would still try to
serialize it before `__setstate__` could run.

Expected: every direct canvas storage key on the helper serialization path must
be removed before pickle serializes the state dictionary.

Trace: S-003, S-004; PO-002, PO-003.

Disposition: fixed in V2 by adding `state.pop("canvas", None)` to
`DraggableBase.__getstate__`.

## F-003: Blit Predicate Should Not Assume A Resolved Canvas

Input/state: a restored or detached helper with `_canvas = None` and no current
figure canvas resolvable.

Observed in V1: `_use_blitting()` dereferenced `self.canvas.supports_blit`.
Most event paths short-circuit before this state, but the predicate itself had
an unnecessary proof side condition: `self.canvas is not None`.

Expected: blitting is disabled when no current canvas is available.

Trace: S-003, S-005; PO-007.

Disposition: fixed in V2 by resolving `canvas = self.canvas` and returning
false if it is `None`.

## F-004: Draggable State Preservation Is Justified

Input/state: a pickle round trip of a figure containing a draggable legend or
annotation.

Observed alternative considered: dropping `_draggable` from legends and
annotations would make pickling succeed by losing draggable state.

Expected: preserve draggable helper state where possible, because the callback
registry explicitly offers `_connect_picklable` and the public APIs expose a
helper object while dragging is enabled.

Trace: S-005, S-006; PO-004, PO-005.

Disposition: V2 keeps V1's preservation strategy.

## F-005: Residual Proof Boundary

Input/state: arbitrary Python pickle traversal, GUI backend internals, and
mid-event GUI lifecycle interactions.

Observed: the FVK model abstracts these as dictionary-state transitions and
does not prove full Python or backend semantics.

Expected: the constructed proof should be machine-checked later and supported
by normal integration tests.

Trace: PO-008.

Disposition: residual risk, not a source-code change. The task forbids running
tests or K tooling here.
