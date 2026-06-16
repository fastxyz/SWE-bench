# FVK Notes

## Summary

The FVK audit confirmed V1's main design: the correct repair point is
`DraggableBase`, because both draggable legends and draggable annotations use
that helper and the reported failure is a live backend canvas reachable through
helper state.

The audit justified two small V2 hardening edits in
`repo/lib/matplotlib/offsetbox.py`.

## Source Changes

1. `DraggableBase.__getstate__` now also calls `state.pop("canvas", None)`.

   - Finding: `fvk/FINDINGS.md` F-002.
   - Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO-002 and PO-003.
   - Reason: V1 cleared `_canvas`, which covers helpers created by the patched
     constructor. The proof obligation requires every direct canvas storage key
     on the helper serialization path to be removed before pickle serializes the
     state. Dropping a legacy/manual `canvas` key makes that invariant explicit.

2. `DraggableBase._use_blitting()` now resolves `canvas = self.canvas` and
   returns false when the result is `None`.

   - Finding: `fvk/FINDINGS.md` F-003.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO-007.
   - Reason: V1's normal event paths should already avoid this detached state,
     but the predicate itself had an unnecessary side condition. The V2 version
     makes "no current canvas means no blitting" explicit.

## Decisions To Keep V1 Behavior

The audit kept V1's decision to preserve draggable helper state rather than
dropping `_draggable` during pickling.

- Finding: `fvk/FINDINGS.md` F-004.
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO-004 and PO-005.
- Reason: `CallbackRegistry._connect_picklable` is public implementation
  evidence that selected callbacks are intended to survive pickling. Preserving
  the helper while removing the live canvas satisfies the issue without
  silently disabling dragging after a pickle round trip.

The audit kept V1's decision not to change `Figure.__getstate__`.

- Finding: `fvk/FINDINGS.md` F-001.
- Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO-006.
- Reason: `Figure.__getstate__` already removes the figure's own `canvas`; the
  extra path is the draggable helper's independent canvas reference.

## Verification Status

The FVK proof is constructed, not machine-checked. The commands to run later are
recorded in `fvk/PROOF.md` and `fvk/draggable-pickle-spec.k`; they were not run
because this task forbids executing K tooling, Python, or tests.
