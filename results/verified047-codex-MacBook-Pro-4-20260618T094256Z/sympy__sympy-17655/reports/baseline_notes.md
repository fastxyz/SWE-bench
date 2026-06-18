# Baseline Notes

## Root cause

`Point.__mul__` scales coordinates when the point is on the left, so
`Point(1, 1) * sympify(2.0)` returns a scaled point. With a SymPy scalar on
the left, however, `Expr.__mul__` did not defer to `Point` because `Point` did
not define an `_op_priority`. The scalar therefore constructed a symbolic
`Mul` containing the `Point` instead of invoking point scaling. That `Mul`
then reached `Point.__add__`, which tried to convert it to a `Point` and raised
the reported geometry error.

## Changed files

`repo/sympy/geometry/point.py`

- Added a small `_op_priority` value just above `Expr` so SymPy scalar
  arithmetic defers reflected operations to `Point`.
- Added `Point.__rmul__` and routed it through the existing `Point.__mul__`
  coordinate-scaling implementation, making scalar-left multiplication match
  scalar-right multiplication.
- Added `Point` overrides for reflected add, subtract, and division when the
  left operand is a SymPy `Expr`. These preserve the previous expression
  construction behavior for those operations and avoid recursion through the
  inherited `GeometryEntity` reflected methods once `_op_priority` is present.

`reports/baseline_notes.md`

- Added this report to document the root cause, implementation choices, and
  alternatives considered, as required by the benchmark task.

## Assumptions and alternatives

I assumed the intended fix is for scalar-left multiplication to produce a
scaled `Point`, not merely for `Point.__add__` to special-case `Mul` objects.
Special-casing `Point.__add__` would make the issue example pass only in that
specific addition context while leaving `sympify(2.0) * Point(1, 1)` as a
symbolic `Mul`.

I also considered adding only `Point.__rmul__`, as suggested in the public
hint, but SymPy's `Expr` arithmetic dispatch requires the right operand to
advertise `_op_priority` before it will call the reflected method. The priority
chosen is above `Expr` and below the existing matrix, vector, tensor, and other
non-scalar priorities so those richer arithmetic types keep their own
multiplication semantics.
