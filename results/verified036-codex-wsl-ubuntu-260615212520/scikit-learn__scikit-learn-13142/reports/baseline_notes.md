# Baseline Notes

## Root cause

`BaseMixture.fit_predict` records the best parameter set across initialization
runs in `best_params`, but it computed the final responsibilities before
calling `_set_parameters(best_params)`. With `n_init > 1`, that final E-step
therefore used the parameters from the last initialization run, while the fitted
estimator was then restored to the best initialization. As a result,
`fit_predict(X)` could return labels from the last run and `predict(X)` could
return labels from the best run.

## Changed files

`repo/sklearn/mixture/base.py`

Moved the final `_e_step(X)` in `BaseMixture.fit_predict` to after
`_set_parameters(best_params)`, `n_iter_`, and `lower_bound_` are restored. The
returned labels are now computed from the same fitted parameters that
`predict(X)` uses.

## Assumptions and alternatives considered

Assumption: the intended behavior is for `fit_predict(X)` to be equivalent to
`fit(X).predict(X)` after fitting, including when multiple initializations are
evaluated.

Alternative considered: changing `GaussianMixture.predict` to mirror the
pre-restore responsibilities from `fit_predict`. Rejected because `predict`
correctly uses the estimator's fitted parameters, and the estimator is
explicitly restored to the best parameters after fitting.

Alternative considered: storing the final `log_resp` together with
`best_params` during the initialization loop. Rejected because a final E-step is
already present to ensure consistency after EM convergence, and moving it after
parameter restoration is simpler and applies to all `BaseMixture` subclasses.
