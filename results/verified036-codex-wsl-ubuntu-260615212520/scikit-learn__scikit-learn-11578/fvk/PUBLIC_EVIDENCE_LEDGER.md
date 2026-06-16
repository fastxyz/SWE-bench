# Public Evidence Ledger

Status: constructed from allowed public inputs only.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "For probabilistic scorers ... LogisticRegressionCV(multi_class='multinomial') uses OvR to calculate scores" | The scorer path must not use OvR behavior when the requested CV path is multinomial. | Encoded by PO-003 and K claim `MULTINOMIAL-SOFTMAX`. |
| E2 | `benchmark/PROBLEM.md` | "`LogisticRegression()` instance supplied to the scoring function ... is initialised ... without a multi_class argument" | The temporary estimator's `multi_class` must equal the `_log_reg_scoring_path` argument. | Encoded by PO-001 and PO-003. |
| E3 | `benchmark/PROBLEM.md` public hint | "`LogisticRegression(fit_intercept=fit_intercept, multi_class=multi_class)` ... Sounds good" | Passing `multi_class` to the scorer estimator is an intent-derived fix. | Satisfied by V1. |
| E4 | `benchmark/PROBLEM.md` public hint | "parameters from the list above should be passed as arguments to logistic regression constructor" | The scorer estimator should inherit all matching constructor parameters available in `_log_reg_scoring_path`, not just `multi_class`. | Encoded by PO-001. |
| E5 | `repo/sklearn/linear_model/logistic.py` docstring | "`multi_class='multinomial'` ... the loss minimised is the multinomial loss" | Coefficients fit for a multinomial path must be scored through a multinomial estimator view. | Encoded by PO-003. |
| E6 | `repo/sklearn/linear_model/logistic.py` `predict_proba` docstring | "if multi_class is set to be \"multinomial\" the softmax function is used" | A scorer that calls `predict_proba` observes softmax exactly when estimator `multi_class` is multinomial. | Encoded by PO-003. |
| E7 | `_log_reg_scoring_path` docstring | "`Cs` ... inverse of regularization strength" and "Scores obtained for each Cs" | Each scorer call corresponds to the current candidate `C`. | Encoded by PO-002. |
| E8 | User task constraints | "Do not modify any test files" and "do not attempt to run tests" | Verification artifacts may mention test commands but must not run or edit tests. | Followed; no tests run or edited. |
