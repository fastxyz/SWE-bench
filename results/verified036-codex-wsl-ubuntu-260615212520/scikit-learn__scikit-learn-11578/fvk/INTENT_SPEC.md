# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Target

The audited unit is the scorer-facing portion of
`repo/sklearn/linear_model/logistic.py::_log_reg_scoring_path`, specifically
the temporary `LogisticRegression` instance passed to `scoring(log_reg,
X_test, y_test)` for each candidate `C`.

## Required behavior

1. A scorer invoked by `_log_reg_scoring_path` must receive an estimator whose
   `multi_class` option is the same option used to compute the coefficient
   path.

2. When `multi_class='multinomial'`, probability-based scorers that call
   `predict_proba` must observe multinomial probability behavior. In
   `LogisticRegression.predict_proba`, this means the softmax branch, not the
   OvR normalization branch.

3. The temporary scorer estimator should inherit the constructor parameters
   that `_log_reg_scoring_path` shares with `LogisticRegression`: `penalty`,
   `dual`, `tol`, `fit_intercept`, `intercept_scaling`, `class_weight`,
   `random_state`, `solver`, `max_iter`, `multi_class`, and `verbose`.

4. For each score in the path, the estimator visible to the scorer should
   represent the current candidate `C`, not a fixed constructor default.

5. The fix should not change public function signatures, return shapes, or
   test files. It should remain local to production source.

## Explicit non-goals

The FVK audit does not prove the numerical optimizer, the numerical value of
softmax, or the numerical value of log loss. It proves the control/data
obligation that caused the bug: scorer calls must see estimator parameters
consistent with the path being scored.
