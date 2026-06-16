# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

- F1 and PO-DAGGER-RIGHT-ID show that V1 fixes the exact reported behavior:
  `Dagger(Operator) * IdentityOperator()` now returns `Dagger(Operator)`.
- F2 and PO-DAGGER-LEFT-ID show that V1 also satisfies the two-sided identity
  contract for the same operator-valued dagger expression.
- F3, PO-DAGGER-NONOP-FRAME, and PO-NONOP-FRAME show that the fix does not
  broaden identity erasure to non-operator operands, preserving public frame
  behavior like `IdentityOperator() * x` remaining a generic `Mul`.

## Next Checks For A Full Environment

Run, in this order, if an execution environment is later available:

```sh
kompile fvk/mini-sympy-quantum.k --backend haskell
kast --backend haskell fvk/identity-dagger-spec.k
kprove fvk/identity-dagger-spec.k
```

Then run the relevant SymPy public tests, especially quantum operator and dagger
tests. This task explicitly forbids those runs, so they remain future checks.

## Suggested Future Tests

Do not edit tests in this benchmark. In normal development, add assertions for:

- right identity on `Dagger(Operator)`;
- left identity on `Dagger(Operator)`;
- non-operator frame behavior.
