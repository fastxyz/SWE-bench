# Formal Spec English

These are plain-English paraphrases of the nontrivial claims in
`point-scalar-spec.k`.

## CLAIM-POINT-RMUL

For any point with coordinate list `Cs` and any scalar `S` in the verified
domain, evaluating `Scalar(S) * Point(Cs)` dispatches to `Point.__rmul__` and
returns `Point(scale(Cs, S))`.

## CLAIM-POINT-MUL

For any point with coordinate list `Cs` and any scalar `S` in the verified
domain, evaluating `Point(Cs) * Scalar(S)` returns `Point(scale(Cs, S))`.

## CLAIM-LEFT-RIGHT-EQUIV

For every in-domain point `P` and scalar `S`, scalar-left multiplication and
scalar-right multiplication produce the same point value.

## CLAIM-ADD-COMPOSITION

For same-dimensional points `P` and `Q` and scalar `S`, evaluating
`P + (S * Q)` produces the same coordinate-wise point as evaluating
`P + (Q * S)`.

## CLAIM-EXPR-ADD-FRAME

When an ordinary SymPy expression is added to a point on the left,
`Expr + Point` still constructs a symbolic `Add(Expr, Point)` rather than
recursing through `GeometryEntity.__radd__`.

## CLAIM-EXPR-SUB-FRAME

When an ordinary SymPy expression subtracts a point on the right,
`Expr - Point` still constructs the symbolic expression equivalent to
`Add(Expr, -Point)`.

## CLAIM-EXPR-DIV-FRAME

When an ordinary SymPy expression divides by a point, the result remains the
same symbolic division form as before the priority change:
`Mul(Expr, Pow(Point, -1))`.

## CLAIM-PRIORITY-FRAME

`Point._op_priority = 10.001` is greater than ordinary `Expr` priority `10.0`
and not greater than known higher-priority non-scalar systems inspected in the
source, so ordinary scalar expressions dispatch to `Point.__rmul__` while those
higher-priority systems keep their precedence.
