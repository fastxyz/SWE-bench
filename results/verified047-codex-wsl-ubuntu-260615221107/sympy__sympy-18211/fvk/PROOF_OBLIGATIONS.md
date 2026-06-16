# Proof Obligations

Status: constructed, not machine-checked. These obligations were reasoned about
statically; no tests, Python, `kompile`, `kast`, or `kprove` were run.

## PO1: Domain Entry

For the audited method body, `self.free_symbols` contains exactly one symbol
`x`.

Evidence:

- `Relational._eval_as_set` asserts `len(syms) == 1`.
- `Boolean.as_set()` only reaches a relational `_eval_as_set()` for a Boolean
  expression with one free symbol, after handling nontrivial periodic cases.

Why it matters:

- The fallback `ConditionSet(x, self, S.Reals)` requires a symbolic binder.
- Multivariate behavior is not silently certified by this proof.

Status: discharged for the audited domain.

## PO2: Solved-Case Preservation

If `solve_univariate_inequality(self, x, relational=False)` returns normally
with set `S`, `_eval_as_set()` returns exactly `S`.

Formal claim:

- `relational-as-set-spec.k`, first claim `(AS-SET-SOLVED)`.

Public evidence:

- Existing univariate relational tests assert intervals and finite sets for
  solved cases.

Status: discharged by the `try` block returning the solver result directly.

## PO3: Solver-Incompleteness Fallback

If `solve_univariate_inequality(self, x, relational=False)` raises
`NotImplementedError`, `_eval_as_set()` catches that exception and returns
`ConditionSet(x, self, S.Reals)`.

Formal claim:

- `relational-as-set-spec.k`, second claim `(AS-SET-NOTIMPLEMENTED)`.

Public evidence:

- The problem reports `NotImplementedError` for
  `Eq(n*cos(n) - 3*sin(n), 0).as_set()`.
- The problem states the obvious result as
  `ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)`.
- The public hint identifies `NotImplementedError` from
  `solve_univariate_inequality` as the failing branch.

Status: discharged by the `except NotImplementedError` branch in V1.

## PO4: ConditionSet Construction Validity

The fallback expression `ConditionSet(x, self, S.Reals)` is well-formed for the
audited domain.

Evidence:

- `x` comes from `self.free_symbols`, so it is a `Symbol`.
- `self` is a `Relational`, which is Boolean-compatible for
  `ConditionSet`'s condition.
- `S.Reals` is a `Set`.

Status: discharged.

## PO5: Exception Hygiene

The fix must not convert unrelated failures into `ConditionSet`.

Evidence:

- V1 catches only `NotImplementedError`.
- The public hint and solver doc specifically identify `NotImplementedError`
  as the signal for this solver limitation.

Status: discharged. Other exception types remain outside the catch.

## PO6: API and Public Compatibility

The fix must not change public call signatures or the documented behavior of
`solve_univariate_inequality`.

Evidence:

- The method signature of `_eval_as_set(self)` is unchanged.
- The solver is still called with the same arguments.
- `solve_univariate_inequality` itself is not modified and can still raise
  `NotImplementedError` for direct callers, as documented.

Status: discharged.

## PO7: No Loop or Termination Obligation

The changed method contains no loop and no recursion. FVK partial correctness is
sufficient for the two branch obligations.

Status: discharged.

## Machine-Check Commands

These commands are intentionally not executed in this session:

```sh
cd fvk
kompile mini-sympy-as-set.k --backend haskell
kast --backend haskell relational-as-set-spec.k
kprove relational-as-set-spec.k
```

Expected machine-check result: `#Top` for both claims.
