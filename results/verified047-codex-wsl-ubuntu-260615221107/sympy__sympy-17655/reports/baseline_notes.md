# Baseline Notes

## Root cause

`Point.__mul__` already scales a point by a right-hand scalar, but `Point`
did not provide its own reflected multiplication behavior. For Python scalar
objects this left `GeometryEntity.__rmul__` to delegate back to the left
operand. For SymPy scalar expressions, the left operand's `Expr.__mul__`
machinery did not dispatch to `Point` because `Point` had no `_op_priority`.
As a result, `sympify(2.0) * Point(1, 1)` was built as a symbolic `Mul`
containing a `Point`, and later `Point.__add__` rejected that `Mul` because it
could not convert it into point coordinates.

## Files changed

`repo/sympy/geometry/point.py`

- Added a small `_op_priority` value to `Point`, just above the default
  `Expr` priority, so SymPy scalar-left multiplication can dispatch to the
  point implementation.
- Added `Point.__rmul__` and routed it through the existing `Point.__mul__`
  coordinate-scaling logic, preserving current right-multiplication behavior.
- Added reflected add, subtract, and divide overrides for `Point` so the new
  priority does not make inherited `GeometryEntity` reflected methods recurse
  for existing SymPy expression operations.

`reports/baseline_notes.md`

- Added this report describing the cause, implementation, and assumptions.

## Assumptions and alternatives considered

I assumed the intended behavior is scalar multiplication of every coordinate
when a scalar appears on the left, matching the existing behavior for
`Point * scalar` including the existing float-preserving `evaluate=False`
result construction.

I used `_op_priority = 10.001` rather than a larger value so ordinary SymPy
expressions hand scalar multiplication to `Point` while higher-priority
systems such as matrices and vectors keep their existing dispatch precedence.

I rejected changing `GeometryEntity.__rmul__` because the issue is specific to
points as coordinate containers; other geometry entities do not necessarily
have scalar multiplication semantics.

I rejected special-casing points in SymPy core multiplication because that
would couple `sympy.core` to `sympy.geometry` for a behavior that belongs on
`Point`.

I did not modify tests or run tests/code, per the benchmark instructions.
