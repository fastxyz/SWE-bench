# Baseline Notes

## Root cause

`IterativeImputer` documents `initial_strategy` as matching the `strategy`
parameter of `SimpleImputer`, but it did not expose or forward
`SimpleImputer.fill_value`. As a result, users could choose
`initial_strategy="constant"` but could not control the constant used during
the first imputation pass.

There was also a related `np.nan` handling issue. The internal
`SimpleImputer` stores the constant in `statistics_`; `IterativeImputer` used
`np.isnan(initial_imputer_.statistics_)` to decide which features were valid.
That is appropriate for empty-feature detection with non-constant strategies,
but with `initial_strategy="constant"` and `fill_value=np.nan`, it treats an
intentional fill value as an invalid statistic and would drop every feature.

## Files changed

- `repo/sklearn/impute/_iterative.py`: Added a public `fill_value` parameter
  to `IterativeImputer`, included it in parameter validation, stored it on the
  estimator, documented it, and forwarded it to the internal `SimpleImputer`.
  The initial-imputation validity mask now treats all features as valid for the
  constant strategy, matching `SimpleImputer` behavior and allowing
  `fill_value=np.nan` for estimators that support missing values.

## Assumptions and alternatives considered

- I assumed the issue should be fixed by adding `fill_value` to
  `IterativeImputer`, not by allowing an arbitrary `SimpleImputer` instance as
  `initial_strategy`. Passing an imputer instance would be a broader API change
  than the requested bug fix and would conflict with the current documented
  string-valued strategy validation.
- I assumed `fill_value` should use the same permissive parameter validation as
  `SimpleImputer`, so `np.nan` is accepted at the API level. Whether the chosen
  estimator can fit or predict with `np.nan` remains the estimator's
  responsibility.
- I did not modify tests because the task requires source-only changes and a
  fixed hidden test suite.
