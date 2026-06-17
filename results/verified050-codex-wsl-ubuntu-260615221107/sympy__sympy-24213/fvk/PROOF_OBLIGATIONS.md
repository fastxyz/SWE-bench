# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Add Branch Uses Compatibility, Not Raw Equality Only

For each addend after the first, if `dim == addend_dim`, the addend is accepted.
If `dim != addend_dim`, acceptance depends on the active dimension system.

Source evidence: E1, E3.

## PO-2: Equivalent Dimensions Under A Dimension System Are Accepted

For a unit system with a non-`None` dimension system, if
`dimension_system.equivalent_dims(dim, addend_dim)` is true, `_collect_factor_and_dimension`
must not raise for that addend.

Source evidence: E1, E3.

## PO-3: Non-Equivalent Dimensions Are Rejected

For a unit system with a dimension system, if `dim != addend_dim` and
`equivalent_dims(dim, addend_dim)` is false, the method must raise the existing
`ValueError`.

Source evidence: E5.

## PO-4: Factor Accumulation Is Preserved

For accepted additions, the returned factor must be the sum of the collected
factors from all addends.

Source evidence: E6.

## PO-5: Return Dimension Is Preserved

For accepted additions, the returned dimension remains the first addend's
collected dimension expression.

Source evidence: E6.

## PO-6: No-Dimension-System Fallback

For a `UnitSystem` with `dimension_system is None`, unequal dimension objects
remain incompatible because no dependency map is available.

Source evidence: E7.

## PO-7: Reported SI Instance

In SI, `acceleration*time` and `velocity` have equal dimensional dependencies,
so `a1*t1 + v1` must pass the compatibility check.

Source evidence: E2, E4.

## PO-8: Compatibility And Honesty Gate

The fix must not change public signatures, return tuple shape, or tests. The
FVK proof is constructed but not machine-checked, so test removal is not
recommended in this task.

Source evidence: FVK methodology and compatibility audit.
