# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the source edit directly
discharges the public intent and proof obligations:

- PO1: `Min()` returns `oo`.
- PO2: `Max()` returns `-oo`.
- PO3: zero-argument calls no longer reach the old exception path.
- PO4: non-empty calls remain on the original constructor path.
- PO5: public signature and dispatch compatibility are preserved.

No FVK finding justifies an additional source edit.

## Future Work When Execution Is Available

1. Run the constructed K commands in `fvk/PROOF_OBLIGATIONS.md`.
2. Run the relevant SymPy tests.
3. When test edits are allowed, replace the visible legacy assertions:
   - `raises(ValueError, lambda: Min())`
   - `raises(ValueError, lambda: Max())`
   with assertions for `oo` and `-oo`.

## Tests to Keep

Keep non-empty Min/Max tests. This FVK proof covers the zero-argument fix and
the frame condition that non-empty calls still enter the existing constructor
tail; it does not replace tests for the full non-empty simplification algorithm.

