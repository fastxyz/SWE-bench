FVK audit notes
===============

Decision: V1 stands unchanged.

The audit identifies the original defect as the overflowing integer product in
the denominator (`F-1`). The V1 expression is retained because `PO-4` proves it
is algebraically equivalent to the public FMI formula on valid nonzero counts,
and `PO-5` proves it avoids forming `pk * qk` as an integer. The denominator
safety concern raised by the rewrite is discharged by `F-2` and `PO-3`: for
contingency-derived counts, `tk > 0` implies `pk > 0` and `qk > 0`.

No extra guard was added for `tk == 0` because the existing branch is part of
the intended behavior. `F-3` and `PO-2` trace that branch to the public
zero-score examples and to the need to avoid denominator evaluation when there
are no shared pairs.

I rejected the `int64` product alternative because it only raises the overflow
threshold and does not satisfy `PO-5`. I also rejected a log-space calculation
or a float-product rewrite because `PO-4` and `PO-5` are already satisfied by
the smaller public-proposed expression, and `F-5` confirms no compatibility
change is needed.

The compact K model intentionally verifies the arithmetic score kernel rather
than the full NumPy/SciPy contingency construction. That boundary is recorded
as `F-4` and `PO-7`, so the audit does not recommend removing integration tests
over label arrays. No tests, Python, or K tooling were run in this environment.
