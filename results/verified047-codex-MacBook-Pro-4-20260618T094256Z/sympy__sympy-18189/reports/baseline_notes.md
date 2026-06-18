# Baseline Notes

## Root cause

`diophantine` normalizes output ordering by solving in its default sorted
symbol order and then reordering each returned tuple when the caller supplies
`syms` in a different order. That recursive solve did not forward the caller's
`permute` argument, so `permute=True` was silently reset to the default
`False`. As a result, the reordered-symbol path only saw the base solution set,
while calls whose `syms` order already matched the sorted variable order used
the full permuted solution set.

## Changed files

`repo/sympy/solvers/diophantine.py`

Forwarded `permute=permute` to the recursive `diophantine` call used by the
`syms` reordering branch. This preserves the caller's requested permutation
behavior before remapping tuple positions into the requested symbol order.

`reports/baseline_notes.md`

Recorded the diagnosis, changed-file rationale, assumptions, and rejected
alternatives for the benchmark task.

## Assumptions and alternatives considered

The issue concerns polynomial equations whose result set depends on `syms`
ordering only when `permute=True`, so the minimal fix is to preserve `permute`
across the existing recursive solve used for symbol-order normalization.

I considered changing other internal recursive calls in `diophantine`, such as
the numerator/denominator handling for rational expressions, but rejected that
for this task because it would affect separate behavior outside the reported
symbol-ordering path.

I did not add or modify tests because the task explicitly forbids changing test
files. I also did not run tests or execute project code because the task
explicitly says this session has no execution environment.
