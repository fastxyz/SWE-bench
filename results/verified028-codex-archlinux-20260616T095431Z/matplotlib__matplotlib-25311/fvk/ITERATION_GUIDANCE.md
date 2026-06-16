# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V2 should keep V1's architecture: fix `DraggableBase`, the common helper for
draggable legends and annotations, instead of dropping `_draggable` from each
artist type or changing figure pickling.

Two small hardening edits are justified by the audit:

1. Add `state.pop("canvas", None)` to `DraggableBase.__getstate__`.
   - Justification: F-002, PO-002, PO-003.
2. Make `_use_blitting()` return false when `self.canvas` cannot be resolved.
   - Justification: F-003, PO-007.

No other source edits are justified by the public intent or proof obligations.

## Follow-Up Verification

When an execution environment is available, run the commands recorded in
`fvk/PROOF.md` after adapting any K syntax required by the local toolchain.
Then run the project's normal pickle-related tests plus targeted coverage for
draggable legends and annotations.

## Future Test Ideas

Do not modify tests in this task. Future tests should assert:

- `pickle.dumps(fig)` succeeds after `ax.legend().set_draggable(True)`;
- `pickle.dumps(fig)` succeeds after `annotation.draggable(True)`;
- a pickle round trip does not preserve the original canvas object through
  `legend._draggable`;
- draggable state remains enabled after unpickling when callbacks are restored.

## Residual Risk

The constructed proof abstracts Python object graph traversal and backend
objects. It proves the intended local invariant over helper state, but it is not
a machine-checked proof of all Python pickle behavior.
