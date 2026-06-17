# Baseline Notes

## Root Cause

`UnitSystem._collect_factor_and_dimension()` handled `Add` expressions by
requiring each addend's collected `Dimension` object to compare equal with the
first addend's dimension. That raw equality check misses dimensions that are
different expressions but equivalent in the active dimension system, such as
`acceleration*time` and the named derived dimension `velocity`.

For the reported expression, the product `a1*t1` collects as
`Dimension(acceleration*time)`, while `v1` collects as `Dimension(velocity)`.
The SI dimension system knows both reduce to `{length: 1, time: -1}`, but the
addition branch never asked the dimension system for equivalence and raised a
`ValueError` instead.

## Changed Files

`repo/sympy/physics/units/unitsystem.py`

Changed the `Add` branch of `_collect_factor_and_dimension()` so unequal
dimension objects are checked with the active dimension system's
`equivalent_dims()` method before raising. A unit system without a dimension
system keeps the previous direct-equality behavior.

## Assumptions and Alternatives

Assumption: the intended result is to accept addends whose dimensions have the
same dimensional dependencies in the current unit system, while still rejecting
physically incompatible dimensions.

Alternative considered: canonicalize every collected addend dimension before
adding factors. I rejected that because the existing method returns the first
addend's dimension expression, and changing that return shape would be a wider
behavioral change than needed for this issue.

Alternative considered: change `Dimension.__eq__` or `Dimension.__add__` to
treat named derived dimensions and compound dimensions as equal. I rejected that
because equivalence depends on the selected `DimensionSystem`, so the check
belongs in `UnitSystem`, where that context is available.
