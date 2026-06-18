# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

The public issue reports that `Eq(n*cos(n) - 3*sin(n), 0).as_set()` raises
`NotImplementedError`. The expected public behavior is that this univariate real
relation is represented as `ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)`.

## Obligations

1. For a univariate relational with one free symbol whose exact solution set is
   computed by `solve_univariate_inequality(..., relational=False)`,
   `Relational._eval_as_set()` must return that exact set unchanged.
2. For a univariate relational where that solver raises `NotImplementedError`
   because the solution cannot be determined, `Relational._eval_as_set()` must
   return `ConditionSet(symbol, relational, S.Reals)`.
3. For the public `Boolean.as_set()` path on a non-periodic univariate
   relational, the result must be the result of `_eval_as_set()`, so the reported
   input must return the same `ConditionSet` rather than surfacing
   `NotImplementedError`.
4. The fix must not change public signatures, the solver API, or already-solved
   relational cases such as `Eq(x, 0).as_set()` and `(x**2 >= 4).as_set()`.
5. Existing multivariate handling and non-trivial periodic handling are outside
   the reported intent and must remain unmodified unless a concrete proof
   finding implicates them.

## Default Domain Assumption

`Boolean.as_set()` rewrites Boolean expressions in terms of real sets, and
`solve_univariate_inequality` defaults to `S.Reals`. The fallback base set is
therefore `S.Reals`, not `S.UniversalSet` or `S.Complexes`.

## Frame Conditions

- No source change may modify test files.
- No source change may alter the signature of `Relational._eval_as_set()`,
  `Boolean.as_set()`, or `solve_univariate_inequality`.
- Exact solver results must still pass through unchanged.
- Exceptions other than solver `NotImplementedError` are not part of the V1
  catch and are not converted by the intent.
