# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged. The FVK audit found the original issue as finding F1 and
discharged the relevant proof obligations with the V1 patch:

- PO2 proves solved-case preservation.
- PO3 proves the `NotImplementedError` fallback.
- PO4 proves the returned `ConditionSet` is well-formed in the audited domain.
- PO5 and PO6 prove exception hygiene and public compatibility.

No proof-derived finding requires another source edit.

## Keep

Keep the V1 change in `repo/sympy/core/relational.py`:

```python
try:
    return solve_univariate_inequality(self, x, relational=False)
except NotImplementedError:
    return ConditionSet(x, self, S.Reals)
```

This is the minimal source change that satisfies F1 without changing solved
cases or direct solver behavior.

## Do Not Change for This Issue

Do not modify `solve_univariate_inequality`. Its documentation still permits
`NotImplementedError` for direct solver calls, and this issue concerns the
relational `as_set()` conversion path.

Do not broaden the exception handler beyond `NotImplementedError`. Catching
other exceptions would hide failures not identified by the public issue or the
solver contract.

Do not change multivariate or periodic `as_set()` behavior as part of this
issue. Those paths have separate existing control flow and require separate
intent evidence.

## Suggested Follow-Up Tests

No tests were edited here. Maintainers should add a regression test equivalent
to:

```python
n = Symbol('n')
assert Eq(n*cos(n) - 3*sin(n), 0).as_set() == \
    ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), S.Reals)
```

Existing solved-case tests should be kept unless the K proof is later
machine-checked and maintainers decide that some are redundant.

## Commands to Machine-Check Later

These commands were not run in this session:

```sh
cd fvk
kompile mini-sympy-as-set.k --backend haskell
kast --backend haskell relational-as-set-spec.k
kprove relational-as-set-spec.k
```

Expected machine-check result: `#Top`.
