# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Coordinate Scaling Equivalence

For any in-domain point `P = Point(c1, ..., cn)` and scalar `s`,
`Point.__rmul__(P, s)` must return the same point as `Point.__mul__(P, s)`:

```text
Point.__rmul__(P, s) = Point([simplify(c1*s), ..., simplify(cn*s)], evaluate=False)
```

Justification: public issue says left and right scalar multiplication should
give the same result. V1 discharges this by implementing
`Point.__rmul__` as `return self*factor`.

## PO2: SymPy Scalar-Left Dispatch

For an ordinary SymPy scalar expression `s` with `_op_priority = 10.0` and a
point `P` with `_op_priority = 10.001`, `s * P` must call
`Point.__rmul__(P, s)` through `call_highest_priority('__rmul__')`.

Justification: the reported scalar is `sympify(2.0)`, a SymPy scalar whose
left multiplication path otherwise creates `Mul(s, P)`.

## PO3: Right Multiplication Preservation

For any in-domain point `P` and scalar `s`, `P * s` must still use the existing
`Point.__mul__` coordinate-scaling path.

Justification: the issue identifies right multiplication as working and uses it
as the expected reference.

## PO4: Composed Addition

For same-dimensional in-domain points `P`, `Q` and scalar `s`:

```text
P + (s * Q) = P + (Q * s)
```

The right operand of `P + (s * Q)` must be a `Point`, not a symbolic `Mul`
containing a point.

Justification: this is the exact shape of the reported failing expression.

## PO5: Reflected Add/Sub/Div Frame

After adding `_op_priority` to `Point`, ordinary `Expr + Point`,
`Expr - Point`, and `Expr / Point` must preserve the previous symbolic forms:

```text
Expr + Point -> Add(Expr, Point)
Expr - Point -> Add(Expr, -Point)
Expr / Point -> Mul(Expr, Pow(Point, -1))
```

Justification: otherwise `Expr` priority dispatch would route these operations
to inherited `GeometryEntity` reflected methods that delegate back to `Expr`.

## PO6: Priority Narrowness

`Point._op_priority` must be greater than ordinary `Expr` priority and not
greater than known higher-priority non-scalar systems inspected in source.

Justification: it must fix scalar-left multiplication without broadly stealing
dispatch from matrices, vectors, and other systems with stronger operator
protocols.

## PO7: Public Compatibility

The V1 fix must not change public signatures, test files, `GeometryEntity`
semantics for non-points, or `Point2D`/`Point3D` subclass construction.

Justification: the public issue and hint are point-specific, and benchmark
instructions forbid test changes.

## Disposition

All obligations are discharged by V1 under the constructed proof. No source
change is justified by the FVK audit.
