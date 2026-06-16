# Public Compatibility Audit

Status: constructed from source inspection; no code or tests were run.

## Changed symbol

`BaseMixture.fit_predict(self, X, y=None)`

- Signature changed: no.
- Return type changed: no; still returns component labels as an array-like
  result from `argmax(axis=1)`.
- Public validation changed: no; `_check_X` and `_check_initial_parameters`
  remain before fitting.
- Public fitted attributes changed: no intentional change to names or types;
  `n_iter_` and `lower_bound_` are still assigned from the best run.
- Warning behavior changed: no intentional change; the convergence warning
  remains before final fitted-state assignment.

## Public callers and subclasses

`BaseMixture.fit` calls `self.fit_predict(X, y)` and returns `self`. The changed
ordering is compatible because it only affects labels returned by
`fit_predict`; `fit` already relies on the fitted state restored by
`_set_parameters(best_params)`.

`GaussianMixture` inherits `fit_predict` and implements `_get_parameters` /
`_set_parameters` for weights, means, covariances, and precision cholesky
factors. `_estimate_weighted_log_prob` reads the restored weights and precision
state, so the final E-step after `_set_parameters(best_params)` is compatible.

`BayesianGaussianMixture` inherits `fit_predict` and implements
`_get_parameters` / `_set_parameters` for concentration, mean precision, means,
degrees of freedom, covariances, and precision cholesky factors. Its log-weight
and log-probability methods read the restored variational parameters, so the
same ordering is compatible.

## Result

No unhandled public callsite, signature, override, or producer/consumer change
was found. Compatibility supports keeping the V1 source change.
