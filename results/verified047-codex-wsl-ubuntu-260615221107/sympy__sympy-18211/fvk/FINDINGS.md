# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and constructed proof obligations only.

## F1: Resolved code bug - solver incompleteness escaped from `as_set`

Input:

```python
Eq(n*cos(n) - 3*sin(n), 0).as_set()
```

Observed before V1:

```text
NotImplementedError
```

Expected from public intent:

```python
ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), S.Reals)
```

Root cause:

`Relational._eval_as_set()` delegated directly to
`solve_univariate_inequality(self, x, relational=False)`. When that solver
reported an unsolved relation by raising `NotImplementedError`, the exception
escaped through `as_set()`.

V1 status:

Resolved. V1 catches `NotImplementedError` and returns
`ConditionSet(x, self, S.Reals)`.

Proof obligations:

- PO1: domain entry
- PO3: solver-incompleteness fallback
- PO4: valid `ConditionSet` construction

Recommended code action:

No further source change needed.

## F2: Confirmed frame condition - solved cases are preserved

Input family:

Solved univariate relationals such as `Eq(x, 0)`, `x > 0`, `x >= 0`,
`x < 0`, `x <= 0`, and `x**2 >= 4`.

Expected from public tests:

These continue to return the exact set produced by the existing solver path,
such as `FiniteSet(0)` or the documented real intervals.

V1 status:

Confirmed. V1 returns directly from the `try` block when the solver returns
normally, so it does not wrap solved results in `ConditionSet`.

Proof obligations:

- PO2: solved-case preservation
- PO6: API and public compatibility

Recommended code action:

No further source change needed.

## F3: Confirmed compatibility - direct solver behavior remains unchanged

Input family:

Direct calls to `solve_univariate_inequality` that are outside the relational
`as_set()` wrapper.

Expected from source documentation:

The solver may raise `NotImplementedError` when it cannot determine a solution.

V1 status:

Confirmed. V1 changes only `Relational._eval_as_set()` and does not modify
`solve_univariate_inequality`.

Proof obligations:

- PO5: exception hygiene
- PO6: API and public compatibility

Recommended code action:

Do not change `solve_univariate_inequality` for this issue.

## F4: Residual non-goal - periodic relational `as_set` behavior

Input family:

Nontrivial periodic relationals handled by the periodicity gate in
`Boolean.as_set()`.

Expected from current public code:

`Boolean.as_set()` has separate logic for periodic relationals and can still
raise `NotImplementedError` for periodic solution sets that are not one of
`EmptySet`, `UniversalSet`, or `Reals`.

V1 status:

Not changed. This issue's reported expression is not a pure periodic relation,
and the public hint targets `Relational._eval_as_set()` after the existing
periodicity gate. The FVK proof does not certify periodic relational
conversion.

Proof obligations:

- PO1: domain entry

Recommended code action:

No change for this issue. Treat broader periodic `as_set()` behavior as a
separate feature or bug with its own intent evidence.

## Proof-Derived Findings From `/verify`

No proof-derived bug requiring a V2 source edit was found. The constructed proof
has two claims:

- solved solver outcome -> return the solver set unchanged;
- `NotImplementedError` solver outcome -> return
  `ConditionSet(symbol, relation, Reals)`.

Both claims align with the intent ledger in `SPEC.md` and with proof
obligations PO2 and PO3. Because the proof is constructed rather than
machine-checked, existing tests should be kept, and a targeted regression test
for F1 should be added by maintainers in the normal test suite.
