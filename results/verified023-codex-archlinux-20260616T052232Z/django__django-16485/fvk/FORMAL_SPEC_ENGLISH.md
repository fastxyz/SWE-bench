# Formal Spec English

The K files are constructed, not machine-checked.

## C-01: Safe Precision

For any nonnegative requested precision `P` and any finite zero Decimal scale
`S`, the V1 precision expression `max(1, P + 2 - S)` evaluates to an integer
greater than or equal to `1`. Therefore it is within Decimal's minimum context
precision requirement.

## C-02: Zero With Precision 0

For any finite zero Decimal scale `S`, formatting the zero value at precision
`0` returns `"0"` after the precision has been made valid.

## C-03: Negative Precision Zero Branch

For any negative precision `P`, zero-valued input returns `"0"` through the
existing early branch before Decimal context precision is constructed. V1 does
not change this behavior.

## Frame Conditions

When the pre-existing raw precision is already at least `1`, `max(1, raw)` is
identical to `raw`. The change therefore only affects paths where the previous
code attempted to construct an invalid Decimal context precision.
