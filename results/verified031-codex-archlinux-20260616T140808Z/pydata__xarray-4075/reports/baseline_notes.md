# Baseline Notes

## Root cause

Weighted reductions use `Weighted._reduce`, which delegates to `xarray.core.computation.dot`.
For `sum_of_weights`, the data array is first converted to a non-null mask with
`da.notnull()`, then that boolean mask is reduced against the weights.

When the weights are also boolean, the reducer passes two boolean arrays into
`dot`. The dot implementation uses `np.einsum`/`dask.array.einsum`; with boolean
operands this can preserve boolean reduction semantics and return `True` instead
of the numeric count of valid true weights. The weighted mean then divides by
`True` (effectively `1`) rather than by the intended sum of weights.

## Files changed

- `repo/xarray/core/weighted.py`: added a small guard in `Weighted._reduce` that
  casts the data operand to `int` when both the data operand and weights are
  boolean. This happens before calling `dot`, so the reduction produces a numeric
  sum instead of collapsing to a boolean result. The change also keeps
  `_reduce` aligned with its documented equivalence to `(da * weights).sum(...)`
  for boolean data and boolean weights.

## Assumptions

- Boolean weights should behave like 0/1 numeric weights for weighted sums,
  `sum_of_weights`, and means.
- The issue is specific to boolean/boolean products inside the dot-based
  reducer. Numeric weights and mixed boolean/numeric products should keep their
  existing dtype behavior.
- It is acceptable for the sum of boolean weights to be an integer count, which
  matches ordinary summation of boolean values.

## Alternatives considered

- Casting the result of `sum_of_weights` after `dot`: rejected because the count
  has already been lost once `dot` returns `True`.
- Casting only the mask inside `_sum_of_weights`: rejected because the shared
  reducer has the same boolean/boolean problem for weighted sums of boolean data
  with boolean weights, and `_reduce` explicitly claims to match
  `(da * weights).sum(...)`.
- Converting all weights in `Weighted.__init__`: rejected because it would alter
  stored weights and could unnecessarily change dtype behavior for operations
  outside the failing boolean/boolean dot case.

## Verification

No tests or project code were run, per the task constraints.
