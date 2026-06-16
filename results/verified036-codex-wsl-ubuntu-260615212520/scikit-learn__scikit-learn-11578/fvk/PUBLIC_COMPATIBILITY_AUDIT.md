# Public Compatibility Audit

Status: constructed from source inspection, not machine-checked.

## Changed symbol

`repo/sklearn/linear_model/logistic.py::_log_reg_scoring_path`

The V1 source change modifies only the construction and per-candidate state of
the temporary `LogisticRegression` object used internally for scoring. It does
not change `_log_reg_scoring_path`'s signature, return tuple, or documented
argument names.

## Public callsites and overrides

- `LogisticRegressionCV.fit` remains the only production callsite found under
  `repo/sklearn` for `_log_reg_scoring_path`.
- No subclass override or virtual dispatch signature was changed.
- The scorer callable protocol remains `scorer(estimator, X, y)`.

## Compatibility conclusion

No compatibility code changes are required. The changed estimator parameters are
observable only through the estimator object supplied to scoring, which is the
behavior the issue asks to correct.
