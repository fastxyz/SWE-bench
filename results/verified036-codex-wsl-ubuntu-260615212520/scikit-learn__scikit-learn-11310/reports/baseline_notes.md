# Baseline Notes

## Root cause

`BaseSearchCV.fit` records cross-validation fit and score timings through
`_fit_and_score`, but the final refit of `best_estimator_` on the full dataset
was called directly without timing. As a result, callers could inspect
`mean_fit_time` and `mean_score_time` in `cv_results_`, but could not retrieve
the elapsed time for the final refit step requested in the issue.

## Changed files

`repo/sklearn/model_selection/_search.py`

- Imported `time`, matching the existing timing approach used by
  `model_selection._validation`.
- Timed only the final `best_estimator_.fit(...)` call inside the existing
  `if self.refit:` branch and stored the elapsed seconds as `self.refit_time_`
  after a successful refit.
- Documented `refit_time_` in both `GridSearchCV` and `RandomizedSearchCV`
  attribute lists because both classes share `BaseSearchCV.fit` and expose the
  same refit behavior.

## Assumptions and alternatives considered

- Assumed `refit_time_` should exist only when a refit is performed, consistent
  with `best_estimator_` being unavailable when `refit=False`.
- Assumed the measured duration should be wall-clock seconds around the final
  full-data fit only, not estimator cloning, parameter assignment, scoring, or
  any cross-validation work.
- Considered adding the timing to `cv_results_`, but rejected it because the
  issue asks for an attribute and `cv_results_` stores per-candidate
  cross-validation results rather than final-search metadata.
- Considered timing with a helper in `_validation.py`, but rejected that as
  unnecessary because the missing behavior is localized to `BaseSearchCV.fit`.
