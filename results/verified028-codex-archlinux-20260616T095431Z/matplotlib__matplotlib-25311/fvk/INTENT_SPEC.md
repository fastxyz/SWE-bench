# Intent Specification

Status: constructed for FVK audit; not machine-checked.

## Required Behavior

I-001. A Matplotlib `Figure` that contains a draggable legend must be picklable.

Evidence: `benchmark/PROBLEM.md` says "Unable to pickle figure with draggable
legend" and the expected outcome is "Pickling successful" for a figure after
`leg.set_draggable(True)`.

I-002. The same pickling behavior must hold for draggable annotations.

Evidence: `benchmark/PROBLEM.md` says "Same error comes for draggable
annotations."

I-003. A draggable helper must not keep a live backend canvas reachable from its
pickle state.

Evidence: the issue's actual outcome is `TypeError: cannot pickle
'FigureCanvasQTAgg' object`; `Figure.__getstate__` already documents that "The
canvas cannot currently be pickled" and removes `Figure.canvas`.

I-004. Draggable state should be preserved unless doing so is the source of the
unpicklable backend object.

Evidence: `DraggableBase` connects callbacks through
`CallbackRegistry._connect_picklable`, whose documented behavior is to keep the
callback when pickling/unpickling. The public legend and annotation APIs return a
draggable helper when dragging is enabled.

I-005. Public APIs and constructor signatures must remain compatible.

Evidence: the public user paths are `Legend.set_draggable(...)` and
`Annotation.draggable(...)`; the issue asks only for successful pickling, not an
API change.

## Domain

The in-scope domain is a normal Matplotlib object graph containing a `Figure`
with at least one draggable `Legend` or draggable `Annotation` created through
the public API. The proof is partial-correctness only: if Python pickle traverses
the modeled state graph, the draggable helper contributes no live canvas object
to that graph.

The audit does not attempt to prove full Python pickle semantics, GUI backend
internals, or termination of pickling.
