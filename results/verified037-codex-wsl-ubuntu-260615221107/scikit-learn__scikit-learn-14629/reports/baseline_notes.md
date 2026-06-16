# Baseline Notes

## Root cause

`cross_val_predict(..., method='predict_proba')` enforces a stable probability
column order across folds by reading `estimator.classes_`. For multi-output
probability predictions it expects `estimator.classes_[i]` for each output.

`MultiOutputClassifier` already fits one classifier per target and each fitted
underlying classifier exposes its own `classes_`, but `MultiOutputClassifier`
did not copy those per-output labels onto itself. As a result, a fitted
`MultiOutputClassifier` lacked `classes_`, causing `cross_val_predict` to fail
with `AttributeError` after calling `predict_proba`.

## Files changed

`repo/sklearn/multioutput.py`

- Added a documented `classes_` fitted attribute to `MultiOutputClassifier`.
- Added `MultiOutputClassifier.fit` to delegate to the existing shared fitting
  implementation, then set `self.classes_` from the fitted per-output
  estimators.
- Added `MultiOutputClassifier.partial_fit` with the same delegation pattern so
  incrementally fitted classifiers expose the same fitted attribute.

`reports/baseline_notes.md`

- Recorded the required root-cause analysis, changed-file rationale,
  assumptions, and rejected alternatives for this benchmark task.

## Assumptions

- A wrapped classifier follows the scikit-learn classifier contract and exposes
  `classes_` after `fit` or after the first valid `partial_fit`.
- `classes_` should be a list aligned with `estimators_`, matching the shape
  that `cross_val_predict` already expects for list-valued multi-output
  probability predictions.
- The existing shared `MultiOutputEstimator.fit` and `partial_fit`
  implementations should remain the source of validation, parallel fitting,
  and sample-weight handling.

## Alternatives considered

- Changing `cross_val_predict` to inspect `estimators_[i].classes_` directly was
  rejected because it would special-case one meta-estimator and leave
  `MultiOutputClassifier` without a standard fitted classifier attribute.
- Adding `classes_` in `MultiOutputEstimator` was rejected because that base
  class is also used by `MultiOutputRegressor`, which should not expose
  classifier-only attributes.
- Adding only a `fit` override was rejected because `partial_fit` also produces
  fitted classifiers and should maintain the same public fitted-state contract.
