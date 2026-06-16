# Baseline Notes

## Root cause

`Relational._eval_as_set()` assumed that every univariate relational with
non-periodic set conversion could be solved by `solve_univariate_inequality`.
For equations such as `Eq(n*cos(n) - 3*sin(n), 0)`, that solver can raise
`NotImplementedError` when it cannot determine the solution set. Because the
exception was not handled in `Relational._eval_as_set()`, `as_set()` raised
instead of returning an unevaluated set representation.

`solveset` already treats this solver limitation as an unsolved set conversion
case and returns `ConditionSet(symbol, relation, domain)`. The relational
`as_set()` path needed the same fallback.

## Changed files

`repo/sympy/core/relational.py`

Added a local import of `ConditionSet` in `Relational._eval_as_set()` and wrapped
the existing `solve_univariate_inequality(..., relational=False)` call. When the
solver raises `NotImplementedError`, the method now returns
`ConditionSet(x, self, S.Reals)`, preserving the original relation over the real
domain instead of propagating the exception.

`reports/baseline_notes.md`

Created this report to document the diagnosis, source change, assumptions, and
alternatives considered for the benchmark task.

## Assumptions and alternatives considered

I assumed that `Relational.as_set()` represents real-valued solutions because it
already delegates to `solve_univariate_inequality`, whose default domain is
`S.Reals`, and boolean `as_set()` complements are also taken relative to
`S.Reals`.

I considered changing `solve_univariate_inequality` itself to return a
`ConditionSet`, but rejected that because its public contract documents
`NotImplementedError` for solver limitations and other callers may rely on that
exception. I also considered special-casing only equality relations, but the same
source of failure can occur for inequalities, so the fallback is applied to any
univariate relational handled by this method.
