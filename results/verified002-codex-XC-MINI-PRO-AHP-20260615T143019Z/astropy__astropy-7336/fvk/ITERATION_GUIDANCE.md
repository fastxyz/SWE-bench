# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

- F-001 is the reported bug. PO-RNONE and QI-NONE show V1 removes the `.to`
  call for `-> None` and returns the constructor's `None` result unchanged.
- F-002 protects the existing unit-return feature. PO-RUNIT and QI-UNIT show V1
  still converts non-`None` unit annotations.
- PO-FRAME-ARGS and PO-FRAME-API show V1 does not change argument validation,
  decorator signatures, wrapped-function signatures, or public call shape.
- F-003 is real residual ambiguity, but public evidence does not justify adding
  stringified-annotation support in this issue.

## Rejected V2 Changes

- Do not change the guard to "skip conversion whenever `return_ is None`".
  That would address the reproducer but would also weaken the unit-return
  annotation contract for functions annotated with a real unit target.
- Do not special-case the string `"None"` in this pass. The public issue uses
  runtime annotation `None`, and string annotations raise broader questions for
  argument unit annotations.

## Recommended Future Tests

Do not edit tests in this benchmark task. Future tests should assert:

- a decorated constructor with `-> None` accepts a quantity argument and returns
  normally;
- a decorated function with `-> u.deg` still converts the return quantity;
- a decorated function with no return annotation returns its original value.

## Verification Status

The proof is constructed but not machine-checked. The emitted commands in
`PROOF.md` should be run in an environment with K before using the proof to
remove tests.
