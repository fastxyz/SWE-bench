# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`TypeError` when fitting `HuberRegressor` with boolean predictors." | Boolean predictor matrices are in the public bug domain for `HuberRegressor.fit`. | Encoded by I-001 and PO-001. |
| E-002 | `benchmark/PROBLEM.md` | "`No error is thrown when `dtype` of `X` is `bool`" | `fit(X_bool, y)` must complete without the boolean-unary-minus `TypeError`. | Encoded by C-001/C-002. |
| E-003 | `benchmark/PROBLEM.md` | "Boolean array is expected to be converted to `float` by `HuberRegressor.fit`" | The repair belongs at or before `fit`'s training-data validation boundary, not only inside one arithmetic operation. | Encoded by PO-002. |
| E-004 | `benchmark/PROBLEM.md` | "# Works ... `fit(X, y)` ... # Also works ... `fit(X_bool_as_float, y)`" | Existing floating-point input behavior is a frame condition. | Encoded by PO-004. |
| E-005 | `repo/sklearn/utils/validation.py` | `check_array` with a dtype list converts to the first dtype when the input dtype is not in the accepted list. | Passing `dtype=FLOAT_DTYPES` converts boolean `X` to `np.float64`. | Used in PO-002 and the K rule for `fitV1`. |
| E-006 | `repo/sklearn/utils/validation.py` | Sparse validation calls `_ensure_sparse_format(..., dtype=dtype, ...)`, which casts sparse matrices when dtype differs. | The same dtype coercion covers accepted CSR sparse boolean input. | Used in PO-006. |
| E-007 | `repo/sklearn/linear_model/huber.py` | `_huber_loss_and_gradient` computes `-axis0_safe_slice(X, ...)`. | The downstream gradient is safe from the reported TypeError if `fit` passes it floating-point `X`. | Used in PO-003. |
| E-008 | `repo/sklearn/linear_model/huber.py` | V1 changes only the `check_X_y` call and an import. | Public signature, optimizer call, sample-weight handling, and parameter checks are unchanged. | Used in PO-004 and PO-005. |
