# Spec

Status: constructed, not machine-checked.

## Target

Audit V1 of `repo/sympy/geometry/point.py` for issue
`sympy__sympy-17655`, specifically reflected scalar multiplication of
`Point`.

## Developer-Readable Contract

For any in-domain point coordinate list `CS` and scalar `F`, scalar-left
multiplication dispatches to point reflected multiplication and returns:

```text
exprMul(scalar(F), point(CS)) => point(scale(CS, F))
```

The issue expression has the same result as the existing working expression:

```text
issueLeft(A, scalar(F), B)
  => point(addCoords(A.coords, scale(B.coords, F)))

issueRight(A, scalar(F), B)
  => point(addCoords(A.coords, scale(B.coords, F)))
```

where `issueLeft` models `A + F * B` and `issueRight` models `A + B * F`.

## Frame Conditions

The audit also records frame claims for reflected add, subtract, and division
under `Expr`-left operands. These were touched by V1 because `_op_priority`
changes SymPy's reflected dispatch. V1 preserves symbolic expression
construction for those cases and preserves direct point-to-point reflected
add/sub delegation for non-`Expr` operands.

Priority frame: `Point._op_priority == 10.0001` is above plain `Expr` priority
(`10.0`) and below public higher-priority matrix/vector-style values, so V1
does not redirect those richer left operands to `Point.__rmul__`.

## Public Ledger Mirror

- `E1/E3`: The two issue lines must give the same result.
- `E4/E5`: `__rmul__` should reuse coordinate-wise point scaling.
- `E6`: Public direct reflected add/sub behavior is a compatibility condition.
- `E7/E8`: `_op_priority` is required for SymPy scalar dispatch and must be
  bounded to avoid stealing higher-priority operations.

## Scope Notes

The mini-K model abstracts SymPy expressions to integer scalars and integer
coordinate lists. This is adequate for the structural dispatch and
coordinate-wise scaling obligation. It does not claim full Python runtime or
floating-point semantics.
