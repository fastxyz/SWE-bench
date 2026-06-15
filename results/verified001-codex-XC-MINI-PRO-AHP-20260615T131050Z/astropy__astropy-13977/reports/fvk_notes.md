# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the existing guard in
`repo/astropy/units/quantity.py` satisfies the intended behavior for the issue:
unknown non-ndarray objects with `.unit` are delegated with `NotImplemented`
before converter lookup, while Quantities, ndarray subclasses, Columns, `None`
outputs, and non-unit plain objects remain on the existing path.

## Trace to Findings and Proof Obligations

Finding F1 is the root bug from the public issue: converter application to an
unknown unit-bearing duck array caused `ValueError`. V1 addresses it through
PO1, PO2, and PO5: the guard scans inputs and outputs, returns
`NotImplemented` for unsupported unit-bearing objects, and is ordered before
`converters_and_unit()`.

Finding F2 records the intentional behavior change for non-ndarray objects that
have `.unit` and `__array__`. I kept V1 unchanged because PO2 and PO3 match the
public hint: Quantity should not coerce such objects merely because they can be
turned into an array.

Finding F3 covers the main compatibility concern from the public hint: table
Columns should continue to work. I kept V1 unchanged because PO4 is discharged
by the source fact that `BaseColumn` subclasses `numpy.ndarray`, and V1 accepts
all `np.ndarray` instances before checking `.unit`.

Finding F4 identifies `FunctionQuantity.__array_ufunc__` as a separate policy
surface. I did not edit it because the issue and public hint localize this fix
to generic `Quantity.__array_ufunc__` treating arbitrary `.unit` objects as
Quantity-like during converter selection. Changing `FunctionQuantity` would
broaden the patch without a corresponding proof obligation for this task.

Finding F5 is a proof capability boundary, not a code defect. The constructed K
model proves the dispatch gate rather than all NumPy and Astropy ufunc
semantics. That is sufficient for the code decision because PO6 confirms the
model distinguishes the failing behavior (`OTHER_UNIT` enters conversion) from
the intended behavior (`OTHER_UNIT` returns `NotImplemented`).

PO7 controls the honesty gate: no tests, Python, or K commands were run. The
artifacts include exact commands for later machine-checking, but no test removal
or stronger machine-checked claim is made.

## Code Changes

No new production code changes were made during the FVK pass. The only retained
production edit is the V1 guard in `Quantity.__array_ufunc__`.

## Artifacts

The required artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK adequacy and formal-core artifacts were also written:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-ufunc-dispatch.k`
- `fvk/quantity-ufunc-dispatch-spec.k`

