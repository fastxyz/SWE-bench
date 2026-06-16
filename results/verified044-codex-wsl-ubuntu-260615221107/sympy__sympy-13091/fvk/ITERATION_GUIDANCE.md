# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 needed one correction. Finding F4 showed that V1 added `_sympify` to singleton equality methods whose prior behavior was identity-based. V2 removes that sympification while preserving fallback for unsupported operands.

All other V1 changes stand:

- `Basic.__eq__` now returns `NotImplemented` for the two unsupported branches required by the issue.
- `Basic.__ne__` and numeric `__ne__` methods preserve `NotImplemented`.
- `Expr` ordering returns `NotImplemented` for unsympifiable operands.
- Numeric overrides no longer bypass fallback for unsupported operands.

## Recommended follow-up tests

Do not edit tests in this task. If tests are added later, target these cases:

- custom object with `__eq__` supporting `Basic`: `sympy_object == custom` delegates
- custom `Basic` subclass with reflected equality: mismatched SymPy types delegate
- `sympy_object != custom` preserves reflected inequality behavior
- `Expr` ordering with a custom reflected ordering object delegates
- core numeric objects compared to unsupported custom objects delegate
- `oo`, `-oo`, and `nan` equality do not gain new equality through sympification of non-identical non-SymPy values

## Future cleanup

The repository contains many specialized comparison methods outside the shared core paths. The public issue frames broader cleanup as a bonus, so this FVK pass does not apply a package-wide refactor. A future task could audit those methods with the same result-category model.

## Machine-check guidance

When a K environment exists, run:

```sh
kompile fvk/mini-python-richcompare.k --backend haskell
kast --backend haskell fvk/sympy-richcompare-spec.k
kprove fvk/sympy-richcompare-spec.k
```

Keep all tests until those claims are machine-checked and concrete tests are mapped to proved obligations.
