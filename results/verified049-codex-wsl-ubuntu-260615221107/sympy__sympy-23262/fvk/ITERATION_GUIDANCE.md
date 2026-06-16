# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

F-001 identifies the original defect and maps it to PO-2 and PO-5. V1's singleton tuple branch directly satisfies both obligations. F-002 and PO-3/PO-4 show that the unchanged shared formatting path preserves empty tuple, multi-element tuple, list, and nested rendering behavior. F-003 and PO-6 show no compatibility issue.

No FVK finding justifies further source edits.

## Future Tests When Test Edits Are Allowed

Add focused tests for:

- native singleton tuple source in `lambdify`;
- native multi-element tuple source as a frame condition;
- nested singleton tuple source;
- `lambdastr` with native singleton tuple expression if that public helper is expected to preserve the same expression semantics.

Do not remove existing tests based on these artifacts until the K commands in `PROOF.md` have been run and returned `#Top`.

