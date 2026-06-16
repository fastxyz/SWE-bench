# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Intended Behavior

1. `Axes.hexbin(..., mincnt=M)` uses `M` as an inclusive minimum count:
   a bin with exactly `M` points is in scope for display.
2. For explicit positive `mincnt`, the set of displayed grid cells must be the
   same whether `C` is omitted or supplied, assuming the same `x`, `y`,
   `extent`, and `gridsize`.
3. When `C` is supplied and `mincnt` is omitted, empty bins are not reduced or
   displayed. This preserves the issue text's accepted default because arbitrary
   `reduce_C_function` callables need not be defined on empty input.
4. When `C` is omitted and `mincnt` is omitted, count-only `hexbin` displays all
   grid cells, including cells with count zero, as described in the issue.
5. The fix must not change the public `Axes.hexbin` or `pyplot.hexbin`
   signatures, the bin-assignment geometry, color normalization, or marginal
   plotting behavior.

## Domain Assumptions

- The verified threshold contract covers finite per-bin point counts generated
  by the existing bin-assignment code.
- Explicit `mincnt` in the documented API is positive (`int > 0`). The issue
  mentions `mincnt=0`; that case is treated as a compatibility/edge behavior:
  the inclusive threshold rule applies if the reducer is defined on empty bins
  and returns a non-NaN result for bins intended to be displayed.
- The proof reasons about selected bin indices. It frames out the numeric result
  of `reduce_C_function`, except for the existing `np.isnan(accum)` filtering
  behavior, which can still remove a selected bin if the reducer returns NaN.
