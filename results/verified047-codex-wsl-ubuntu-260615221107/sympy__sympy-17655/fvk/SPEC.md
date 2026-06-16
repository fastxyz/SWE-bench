# FVK Specification: Point Scalar-Left Multiplication

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

This FVK pass audits the V1 fix for `sympy.geometry.point.Point` scalar-left
multiplication. The relevant public surface is:

- `Point.__mul__`
- `Point.__rmul__`
- `Point._op_priority`
- reflected compatibility shims `Point.__radd__`, `Point.__rsub__`,
  `Point.__rdiv__`, and `Point.__rtruediv__`

There are no loops in the audited code path.

## Public Intent Ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

1. The issue reports `point1 + sympify(2.0) * point2` raising an exception.
   Obligation: scalar-left point multiplication by a number is in-domain.
2. The issue states `point1 + point2 * sympify(2.0)` works.
   Obligation: existing right scalar multiplication is the reference behavior.
3. The issue states both forms should give the same result.
   Obligation: `P + s * Q == P + Q * s` for in-domain point addition and
   scalar multiplication.
4. The public hint identifies `Point.__rmul__`.
   Obligation: repair point reflected multiplication, not all geometry
   entities and not SymPy core multiplication.
5. SymPy `Expr` dispatch uses `_op_priority`.
   Obligation: `Point` needs priority greater than ordinary `Expr` for a
   SymPy scalar on the left to call `Point.__rmul__`.

## Intent-Level Contract

For every point `P = Point(c1, ..., cn)` in the verified domain and scalar `s`
accepted by the existing `Point.__mul__` path:

```text
s * P == P * s == Point([simplify(c1*s), ..., simplify(cn*s)], evaluate=False)
```

For same-dimensional points `P` and `Q`:

```text
P + s * Q == P + Q * s
```

The contract is partial over the existing point arithmetic domain. It does not
define point-point multiplication, invalid coordinates, or scalar-left
multiplication for non-point geometry entities.

## Frame Conditions

- Existing `Point * scalar` behavior remains unchanged.
- `Point2D` and `Point3D` inherit the behavior without signature changes.
- Adding priority to `Point` must not make `Expr + Point`, `Expr - Point`, or
  `Expr / Point` recurse through inherited `GeometryEntity` reflected methods.
  Those expressions preserve their previous symbolic construction behavior.
- `Point._op_priority` is intentionally just above ordinary `Expr` priority and
  not above known higher-priority non-scalar systems inspected in source.

## Formal Artifacts

- `mini-python-point.k`: minimal semantics fragment for point/scalar operator
  dispatch and coordinate-wise point multiplication.
- `point-scalar-spec.k`: reachability claims for scalar-left multiplication,
  right multiplication preservation, composed addition, and reflected
  add/sub/div compatibility frames.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of each K claim.
- `SPEC_AUDIT.md`: adequacy check comparing the formal English against
  `INTENT_SPEC.md`.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: API/callsite/override compatibility check.

## Reproduce Later

Commands to run in an environment with K installed:

```sh
kompile fvk/mini-python-point.k --backend haskell
kast --backend haskell fvk/point-scalar-spec.k
kprove fvk/point-scalar-spec.k
```

Expected result: all claims discharge to `#Top`. This FVK run did not execute
those commands.
