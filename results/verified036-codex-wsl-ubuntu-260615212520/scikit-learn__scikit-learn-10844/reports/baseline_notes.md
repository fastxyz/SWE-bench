Root cause
==========

`fowlkes_mallows_score` computed its nonzero score as
`tk / np.sqrt(pk * qk)`. The intermediate product `pk * qk` was evaluated
with integer arithmetic before `np.sqrt` converted the value to floating
point. For large clusterings this product can overflow the integer dtype,
which can emit a runtime warning and produce an invalid denominator such as
`nan`.

Changed files
=============

`repo/sklearn/metrics/cluster/supervised.py`

Changed the final Fowlkes-Mallows score calculation to
`np.sqrt(tk / pk) * np.sqrt(tk / qk)` for the nonzero case. This is
algebraically equivalent to `tk / sqrt(pk * qk)` when `tk >= 0`, and `tk` is a
pair count here. It avoids forming the overflowing integer product while
leaving the existing `tk == 0` return path unchanged.

`reports/baseline_notes.md`

Added this report describing the issue, the source change, and the assumptions
behind it.

Assumptions and alternatives
============================

Assumed the intended behavior is to preserve the Fowlkes-Mallows formula while
avoiding integer overflow in intermediate arithmetic. When `tk` is nonzero,
`pk` and `qk` should also be positive because any pair counted together in both
clusterings contributes to both marginal pair counts.

Considered casting `pk` or `qk` to `float` before multiplication. That would
also avoid integer multiplication, but the chosen expression follows the issue
proposal directly and never forms the large product at all.

Considered casting to `np.int64`. That can address an `int32` overflow, but it
only raises the overflow threshold and can still fail for larger valid inputs,
so it was rejected.

Considered a log-space calculation. That would avoid the product too, but it
would be a larger behavioral and numerical change than necessary for this
targeted fix.
