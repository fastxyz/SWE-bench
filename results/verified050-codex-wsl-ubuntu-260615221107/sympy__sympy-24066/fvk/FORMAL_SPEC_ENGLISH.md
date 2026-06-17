# Formal Spec In English

FS1. `_is_dimensionless(D)` is true only when the configured dimension system
exists and proves `D` has no dimensional dependencies. If analysis raises
`TypeError`, it is false.

FS2. Collecting a one-argument function with collected argument `(F, D)` returns
`(func(F), Dimension(1))` when FS1 is true for `D`; otherwise it returns
`(func(F), D)`.

FS3. Collecting `100 + exp(second/(ohm*farad))` under SI returns normally with a
dimensionless dimension.

FS4. Collecting an addition of non-equivalent dimensions raises `ValueError`.

FS5. `_dimensions_equivalent(D1, D2)` is true for structural equality or
dimension-system equivalence. If analysis raises `TypeError`, it is false.

FC1. The fix preserves the public collector signature and the existing
non-strict behavior for dimensionful function arguments.
