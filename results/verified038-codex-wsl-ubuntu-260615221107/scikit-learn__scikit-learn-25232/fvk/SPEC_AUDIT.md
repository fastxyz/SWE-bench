# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal claim | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| C-001 stores the public fill value. | I-001 | Pass | Directly required by the issue's request to add `fill_value`. |
| C-002 forwards fill value to the internal imputer. | I-002, I-003 | Pass | The quoted `SimpleImputer` docs make forwarding the intended mechanism. |
| C-003 keeps all features valid for constant `NaNFill`. | I-004 | Pass | Required so `np.nan` is allowed for NaN-capable estimators rather than causing feature deletion. |
| C-004 keeps all features valid for any constant fill statistics. | I-002, I-003, I-004 | Pass | Matches `SimpleImputer`'s constant-strategy behavior and generalizes C-003. |
| C-005 preserves non-constant filtering by non-NaN statistics. | I-005 | Pass | Keeps the patch scoped to constant `fill_value`. |
| C-006 preserves `NoneFill` default delegation. | I-003 | Pass | Adds the parameter without changing previous defaults. |
| No claim accepts `SimpleImputer(...)` as `initial_strategy`. | I-006 | Pass | The issue discussion frames that as a separate future API idea, not this fix. |

## Adequacy Result

The formal English claims match the intent spec. No claim is based only on
legacy behavior, and no required intent entry is omitted within the audited
scope.

## Coverage Limits

The proof does not cover full chained imputation, estimator prediction
correctness, estimator-level missing-value support, convergence, sparse matrix
details, or all-empty target columns. These are outside the public bug-fix
contract and are not used to justify the V1 decision.

