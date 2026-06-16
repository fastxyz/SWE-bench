# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "If you fit an `IsolationForest` using a `pd.DataFrame` it generates a warning" | The relevant observable is a warning emitted during `fit` on DataFrame input. | Encoded by I-001 and PO-1. |
| E-002 | `benchmark/PROBLEM.md` | "This only seems to occur if you supply a non-default value ... for the `contamination` parameter." | The non-auto contamination branch is the branch under audit. | Encoded by I-003 and PO-1/PO-2. |
| E-003 | `benchmark/PROBLEM.md` | "This warning is unexpected as ... X does have valid feature names ... it is being raised by the `fit()` method" | Internal `fit` work must not be treated like a public post-fit ndarray scoring call. | Encoded by I-001 and I-003. |
| E-004 | `benchmark/PROBLEM.md` | "`fit` is called with a `DataFrame` so there are some feature names in ... at the end of `fit` ... `X` is now an array ... `score_samples(X)` calls `_validate_data(X)`" | Root-cause model must represent feature-name recording followed by transformed-array revalidation. | Encoded in `mini-iforest.k` and FINDING F-001. |
| E-005 | `benchmark/PROBLEM.md` | "add a `_scores_sample` method without validation ... have `scores_sample` validate the data and then call `_scores_sample` ... call `_scores_sample` at the end of `.fit`" | A private no-user-validation scoring path is publicly suggested as the intended fix shape. | Encoded by PO-1/PO-2/PO-3. |
| E-006 | `repo/sklearn/ensemble/_iforest.py` docstring | `contamination` different from `"auto"` defines `offset_` so the expected number of training outliers is obtained. | The non-auto offset computation must still use training-data scores and percentile. | Encoded by I-006 and PO-2. |
| E-007 | `repo/sklearn/ensemble/_iforest.py` docstring | `score_samples` returns the anomaly score; lower is more abnormal. | Public score semantics must be preserved. | Encoded by I-006 and PO-3. |
| E-008 | `repo/sklearn/base.py` | `_check_feature_names` warns if fitted feature names exist and new `X` has none. | Public `score_samples` on ndarray after fitting with DataFrame should still warn. | Encoded by I-005 and PO-3. |
| E-009 | `repo/sklearn/utils/validation.py` | `_get_feature_names` returns DataFrame string columns and returns `None` for other array containers. | DataFrame vs ndarray/sparse name status is the model's warning discriminator. | Encoded by D-002 and K constructors. |
| E-010 | `repo/sklearn/tree/_classes.py` | Tree prediction validation accepts sparse CSR; `check_input=False` still checks feature count. | Internal sparse scoring should use CSR when bypassing public validation. | Encoded by I-008 and PO-5. |
| E-011 | `repo/sklearn/ensemble/tests/test_iforest.py` | `test_score_samples` asserts `score_samples == decision_function + offset_`. | Public score/decision relation is a frame condition. | Encoded by I-006 and PO-3. |
| E-012 | `repo/sklearn/ensemble/tests/test_iforest.py` | `test_iforest_sparse` checks sparse fit/predict compatibility. | Sparse behavior must not regress. | Encoded by I-008 and PO-5. |
| E-013 | `repo/sklearn/tests/test_base.py` | Base estimator feature-name tests expect public transform on ndarray after DataFrame fit to warn. | The fix must not globally suppress feature-name warnings. | Encoded by I-004/I-005 and PO-3. |
