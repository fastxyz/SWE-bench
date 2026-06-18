# Intent Spec

Status: constructed, not machine-checked.

## Public Intent Obligations

1. Scalar-left multiplication of a `geometry.Point` must produce the same point
   value as scalar-right multiplication when the scalar is a SymPy number-like
   expression accepted by `Point.__mul__`.
2. The reported expression forms must agree:
   `point1 + point2 * sympify(2.0)` and
   `point1 + sympify(2.0) * point2` should return the same point.
3. Existing right-side point scaling remains unchanged: multiplying a point by a
   scalar scales each coordinate and returns a `Point`.
4. The repair must not break existing reflected point addition/subtraction
   behavior, including direct `Point.__radd__(Point)` and `Point.__rsub__(Point)`
   usage visible in public tests.
5. Introducing arithmetic priority for `Point` must not steal multiplication
   from higher-priority SymPy objects such as matrix/vector-style operands.

## Domain

The in-domain scalar is a commutative scalar SymPy expression/number accepted by
the existing `Point.__mul__` implementation. The K model uses integer scalars and
integer coordinate lists as a faithful finite abstraction of coordinate-wise
scaling. Noncommutative scalar ordering, floating precision, and the full Python
runtime dispatch implementation are outside this mini-semantics but are noted as
residual proof boundaries, not code findings.
