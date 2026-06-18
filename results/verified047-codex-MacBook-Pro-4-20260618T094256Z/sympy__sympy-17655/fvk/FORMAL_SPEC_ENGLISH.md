# Formal Spec English

Status: constructed, not machine-checked.

## Claim Paraphrases

`POINT-RMUL`: For any coordinate list `CS` and scalar `F`, evaluating
`exprMul(scalar(F), point(CS))` reaches `point(scale(CS, F))`. This formalizes
SymPy scalar-left multiplication deferring to `Point.__rmul__`.

`POINT-RMUL-DIRECT`: For any coordinate list `CS` and scalar `F`, direct
reflected point multiplication `pointRMul(scalar(F), point(CS))` reaches the
same scaled point as `pointMul(point(CS), scalar(F))`.

`ISSUE-EXAMPLE`: For symbolic 2D coordinates, `issueLeft`, representing
`point1 + scalar * point2`, and `issueRight`, representing
`point1 + point2 * scalar`, both reach the same coordinate-wise result.

`RADD-FRAME`: For an `Expr`-left scalar plus a point, the result remains a
symbolic add expression rather than recursing through the inherited
`GeometryEntity.__radd__`.

`RSUB-FRAME`: For an `Expr`-left scalar minus a point, the result remains the
symbolic add of the scalar and negated point, mirroring `Expr.__sub__`.

`RDIV-FRAME`: For an `Expr`-left scalar divided by a point, the result remains
symbolic multiplication by the point inverse form, mirroring `Expr.__div__`.

`HIGHER-PRIORITY-FRAME`: A left operand with priority `10010`, representing
matrix/vector-style priorities above `Point`, keeps control of multiplication
with a point. V1's point priority does not steal that operation.

## Side Conditions

The scalar domain is commutative scalar arithmetic accepted by the existing
`Point.__mul__`. The coordinate list is well-formed and same-length where point
addition is modeled.
