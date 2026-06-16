# Intent Spec

Status: intent-first, constructed from public issue text and in-repository
source/docstrings only. Current V1 behavior is treated as a candidate to audit,
not as the source of truth.

## Required Behavior

I1. For a geometry `Point` `P` and scalar number `s`, left scalar
multiplication must produce the same point as right scalar multiplication:
`s * P == P * s`.

I2. The result of scalar multiplication is coordinate-wise scaling using the
existing `Point.__mul__` semantics: each coordinate `c` becomes
`simplify(c*s)`, and the resulting `Point` is constructed with
`evaluate=False`.

I3. In composed point arithmetic, `P + s * Q` must behave the same as
`P + Q * s` whenever `P + Q * s` is in-domain for existing point addition.
The reported traceback is not intended behavior.

I4. Existing right multiplication of a point by a scalar is an intended public
behavior and must be preserved.

I5. The fix is specific to `Point` and its subclasses. Public intent does not
require scalar-left multiplication semantics for every `GeometryEntity`.

I6. Adding dispatch priority for `Point` must not turn unrelated reflected
arithmetic into recursion or unintentionally take precedence over higher
priority non-scalar systems such as matrices and vectors.

## Domain

The verified domain is finite-dimensional SymPy geometry points whose
coordinates are valid SymPy expressions and scalar factors accepted by the
existing `Point.__mul__` path after `sympify`. This includes the issue's
`sympify(2.0)` scalar and ordinary SymPy scalar expressions.

Out of scope: point-point multiplication, scalar multiplication of non-point
geometry entities, and behavior of invalid coordinate or non-scalar operands
that the existing `Point.__mul__` path already rejects or leaves undefined.

## Frame Conditions

F1. `Point * scalar` remains unchanged.

F2. `Point2D` and `Point3D` inherit the corrected point behavior without
signature changes.

F3. `Expr + Point`, `Expr - Point`, and `Expr / Point` keep their previous
symbolic construction behavior when `Point` priority causes reflected dispatch
to be considered.

F4. No test files are modified.
