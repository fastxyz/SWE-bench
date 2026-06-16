# FVK Specification

Status: constructed, not machine-checked.

## Scope

This specification covers the scorer-proxy fragment of
`_log_reg_scoring_path`: after `logistic_regression_path` returns candidate
`coefs` and `Cs`, the helper builds a temporary `LogisticRegression`, assigns
candidate coefficients, and passes that estimator to the configured scorer.

The model abstracts away numerical optimization, matrix slicing, and the
actual probability arrays. That abstraction is deliberate but property-complete
for this issue: the defect is whether `predict_proba` sees `multi_class='ovr'`
or `multi_class='multinomial'`.

## Preconditions

The specification assumes:

- `_check_solver_option` has accepted the solver, penalty, dual, and
  `multi_class` combination.
- `logistic_regression_path` returns aligned `coefs` and `Cs`, one coefficient
  row for each candidate `C`.
- `multi_class` is either `ovr` or `multinomial`, matching the local validation
  already present in `_log_reg_scoring_path`.
- The scorer follows the documented callable shape `scorer(estimator, X, y)`.

## Postconditions

For every candidate pair `(C_i, coef_i)` in the returned path:

1. The estimator passed to the scorer has the same `penalty`, `dual`, `tol`,
   `fit_intercept`, `intercept_scaling`, `class_weight`, `random_state`,
   `solver`, `max_iter`, `multi_class`, and `verbose` values that
   `_log_reg_scoring_path` used for fitting the path.

2. The estimator passed to the scorer has `C == C_i`.

3. If `multi_class == 'multinomial'`, the estimator's `predict_proba` branch is
   softmax. If `multi_class == 'ovr'`, the branch is OvR normalization.

4. The estimator's assigned coefficients and intercept are the current
   candidate's values, with the same existing shape convention:
   `fit_intercept=True` splits the last column into `intercept_`; otherwise
   the intercept is zero. The existing OvR single-class reshaping is preserved.

5. The helper signature and returned tuple shape are unchanged.

## Intent ledger summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The central public
evidence is the issue report that a multinomial CV scorer used OvR probabilities
because the temporary `LogisticRegression` was constructed without
`multi_class`. The public hints broaden that to the matching constructor
parameters available in `_log_reg_scoring_path`.

## Formal artifacts

- `fvk/mini-logistic-scoring.k` defines a minimal scorer-proxy semantics.
- `fvk/log-reg-scoring-spec.k` states the K claims:
  - `SCORER-PARAMS`
  - `MULTINOMIAL-SOFTMAX`
  - `SCORE-ALL-CANDIDATES`

These claims are constructed for later `kprove`; they have not been executed in
this session.
