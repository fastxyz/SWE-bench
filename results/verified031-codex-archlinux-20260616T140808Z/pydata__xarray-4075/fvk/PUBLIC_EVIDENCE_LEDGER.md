# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`[bug] when passing boolean weights to weighted mean`" | Boolean weights are in scope for weighted mean. | Encoded in INTENT-1 and claims. |
| E2 | `benchmark/PROBLEM.md` | Reported result is `array(2.)`; expected result is `array(1.)`. | The issue example must compute mean `1.0`, not `2.0`. | Encoded in ISSUE-MEAN claim. |
| E3 | `benchmark/PROBLEM.md` | "`sum_of_weights` is calculated as `xr.dot(dta.notnull(), wgt)`"; boolean dot yields `array(True)`. | The defect is localized to a boolean/boolean dot in the denominator. | Finding F-001. |
| E4 | `benchmark/PROBLEM.md` | "`convert it to int or float`" gives `array(2)`. | Conversion must happen before the dot result loses the numeric count. | PO-1 and PO-2. |
| E5 | `repo/xarray/core/weighted.py` | `_reduce` docstring: "equivalent to `(da * weights).sum(dim, skipna)`". | Bool/bool weighted sums should match integer summation of 0/1 products. | PO-1 and PO-3. |
| E6 | `repo/xarray/core/weighted.py` | `_sum_of_weights` creates `mask = da.notnull()` and calls `_reduce(mask, self.weights, ...)`. | Boolean weights make the denominator a bool/bool reducer input. | PO-2. |
| E7 | `repo/xarray/tests/test_weighted.py` | Public helper computes `masked_weights = weights.where(da.notnull())` and `masked_weights.sum(...)`. | Public tests support numeric weight summation, but are evidence only. | Supports PO-2; not treated as sole oracle. |
| E8 | `repo/xarray/core/common.py` | `weighted` docs: each value contributes according to its associated weight. | A boolean weight contributes as 0 or 1, not as a collapsed any-true flag. | Encoded in INTENT-1. |
