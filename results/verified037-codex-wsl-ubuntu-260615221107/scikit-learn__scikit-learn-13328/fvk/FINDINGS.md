# Findings

Status: constructed, not machine-checked.

## F-001: Resolved code bug - boolean `X` reached boolean unary minus

Input: valid `HuberRegressor.fit(X_bool, y)` where `X_bool.dtype == bool`.

Observed before V1: `check_X_y` used default `dtype="numeric"`, which preserves
boolean numeric arrays. The optimizer called `_huber_loss_and_gradient` with
boolean `X`, and the gradient attempted `-axis0_safe_slice(X, ...)`, producing
the TypeError shown in the issue.

Expected: boolean predictors are converted to a floating dtype by
`HuberRegressor.fit`, and the reported TypeError is unreachable.

Status: resolved by V1. The proof obligations PO-001, PO-002, and PO-003 are
discharged by the `dtype=FLOAT_DTYPES` validation change.

## F-002: No source change required - private helper direct boolean input

Input: a direct call to `_huber_loss_and_gradient(..., X_bool, ...)` bypassing
`HuberRegressor.fit`.

Observed: the private helper would still be able to reach boolean unary minus
if called with unvalidated boolean `X`.

Expected by public intent: the issue requires `HuberRegressor.fit` to convert
boolean predictors. It does not establish a public contract for direct calls to
the private helper.

Status: not a blocking code bug for this task. PO-007 records the helper's
validated-input precondition.

## F-003: Proof scope boundary - numerical optimization is not verified here

Input: any valid floating or boolean training data.

Observed: this FVK slice abstracts away L-BFGS-B iterations, coefficient values,
convergence warnings, and score/predict behavior.

Expected: the proof should certify only the dtype-safety property needed for
the reported TypeError. Existing numerical and integration tests should remain.

Status: open proof boundary, not a source bug. PO-008 records this limitation.

## F-004: Test guidance - boolean fit coverage would be useful

Input: dense boolean `X` and accepted CSR sparse boolean `X`.

Observed: no test file was edited in this task, and tests must remain fixed.

Expected: a future test pass should include `HuberRegressor().fit(X_bool, y)`
and, if sparse coverage is desired, `HuberRegressor().fit(csr_matrix(X_bool), y)`.

Status: test guidance only. Do not modify test files in this benchmark task.

## Summary

The FVK audit found no unresolved source bug in V1 for the public issue. V1
stands unchanged.
