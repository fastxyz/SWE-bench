# Baseline Notes

## Root cause

`_BaseVoting.fit` already treats `None` as a dropped estimator when fitting:
it filters those entries out before cloning and fitting the remaining
estimators. However, when `sample_weight` is passed, the earlier support check
iterates over every configured estimator and calls `has_fit_parameter` on each
one. If an estimator has been set to `None`, `has_fit_parameter` attempts to
inspect `None.fit`, causing the reported `AttributeError` before the normal
dropped-estimator filtering can run.

The same filtered/non-filtered mismatch also affected `named_estimators_`: it
zipped the full configured estimator list with the filtered fitted estimator
list, so names after a dropped estimator could point to the wrong fitted model.

## Files changed

`repo/sklearn/ensemble/voting.py`

- Skipped `None` estimators in the `sample_weight` support loop so dropped
  estimators are ignored consistently with the later fit loop.
- Built `named_estimators_` from only the names of non-`None` estimators so the
  fitted estimator list remains aligned with its names after an estimator is
  dropped.

## Assumptions and alternatives

- I treated `None` as the supported dropped-estimator sentinel because the local
  voting code and tests already document and exercise `set_params(name=None)`.
- I kept the existing behavior that all non-dropped estimators must support
  `sample_weight` when weights are passed.
- I considered only guarding the `has_fit_parameter` call. That would fix the
  immediate exception, but it would leave `named_estimators_` inconsistent for
  the same dropped-estimator scenario, so I aligned that mapping with the
  existing filtered fitting behavior.
- I did not add or modify tests, and I did not run tests or project code, per
  the benchmark instructions.
