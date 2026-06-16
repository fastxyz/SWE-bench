# FVK Findings

Status: no blocking V2 code change found beyond V1 for the reported issue.

## F-01: Resolved Code Bug - Zero Decimal Precision Can Be Invalid

Input:

- `floatformat("0.00", 0)`
- `floatformat(Decimal("0.00"), 0)`

Observed before V1:

- `ValueError: valid range for prec is [1, MAX_PREC]`

Expected:

- No exception; precision `0` formats zero as `"0"`.

Cause:

For Decimal zero with scale `S = 2`, the old raw precision is
`P + 2 - S = 0 + 2 - 2 = 0`. `decimal.Context(prec=0)` is invalid.

Resolution:

V1 changes the precision to `max(1, raw)`, discharging PO-02 and PO-03.

Classification: code bug, resolved.

## F-02: Confirmed Frame - Existing Valid Precision Is Unchanged

Input class:

- Any path where the pre-existing raw precision is already at least `1`.

Observed under V1:

- `max(1, raw)` equals `raw`.

Expected:

- Existing non-regression behavior for nonzero values, valid zero precisions,
  suffix handling, and documented formatting remains unchanged.

Resolution:

PO-04 and PO-06 confirm this frame condition. No additional source edit is
justified.

Classification: proof-derived confirmation.

## F-03: Proof Capability Boundary - Full `floatformat()` Not Modeled

Input class:

- Nonzero Decimal rounding, float fallback, localization, grouping, infinity,
  NaN, and invalid argument parsing.

Observed:

- These paths are outside the mini semantics used for the reported precision
  bug.

Expected:

- They remain governed by Django's existing implementation, documentation, and
  tests.

Resolution:

Do not use this FVK pass to remove tests for those paths or to claim full
machine-checked verification of `floatformat()`. This is a proof capability
boundary, not a V1 code bug.

Classification: proof capability gap / keep tests.

## F-04: Test Gap Recommendation - Add Regression Coverage

Input:

- `floatformat("0.00", 0)`
- `floatformat(Decimal("0.00"), 0)`

Expected:

- Both return `"0"`.

Recommendation:

Add conventional regression tests for these public issue cases in a normal test
editing context. This benchmark task forbids modifying test files, so no test
files were changed.

Classification: test gap.
