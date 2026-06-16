# Baseline Notes

## Root Cause

`Axes.hexbin` used two different comparisons for `mincnt`. When `C` was not
provided, count-only bins were hidden only when their count was less than
`mincnt`, so `mincnt=1` kept bins with exactly one point. When `C` was provided,
the per-bin `C` values were reduced only when `len(acc) > mincnt`, so
`mincnt=1` incorrectly dropped bins with exactly one point.

## Files Changed

- `repo/lib/matplotlib/axes/_axes.py`
  - Changed the `C` aggregation path from a strict `len(acc) > mincnt` check to
    an inclusive `len(acc) >= mincnt` check.
  - Changed the internal default threshold for the `C` path from `0` to `1` so
    omitting `mincnt` still skips empty bins and avoids calling
    `reduce_C_function` on empty arrays.
  - Updated the `mincnt` docstring wording from "more than" to "at least" to
    match the inclusive behavior.

## Assumptions and Alternatives

- I assumed the intended meaning of `mincnt` is an inclusive minimum number of
  points, matching the behavior already used when `C` is not provided and the
  issue reporter's expected behavior for `mincnt=1`.
- I kept the `C` path's omitted-`mincnt` behavior as "non-empty bins only".
  Reducing empty `C` lists is not generally valid for arbitrary
  `reduce_C_function` callables, so simply switching the old default
  `mincnt = 0` to an inclusive comparison would have changed the default path
  to call reducers on empty inputs.
- I considered forcing explicit `mincnt=0` in the `C` path to behave like the
  omitted case, but rejected that because the targeted bug is the strict
  comparison for positive `mincnt` values and the documented parameter is
  `int > 0`.
