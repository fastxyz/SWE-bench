# Baseline Notes

## Root cause

`RidgeClassifierCV` inherits the `_BaseRidgeCV` implementation, which already
supports `store_cv_values` and forwards it to `_RidgeGCV` when `cv=None`.
However, `RidgeClassifierCV.__init__` did not expose that keyword or pass it to
the base class. As a result, using the documented `store_cv_values=True`
argument raised `TypeError: __init__() got an unexpected keyword argument
'store_cv_values'` before fitting could reach the existing storage logic.

## Changed files

`repo/sklearn/linear_model/ridge.py`

- Added `store_cv_values=False` to `RidgeClassifierCV.__init__`.
- Passed `store_cv_values` through to `_BaseRidgeCV.__init__`, reusing the
  existing implementation that stores `cv_values_` for generalized
  cross-validation and raises for incompatible `cv != None`.
- Added the missing `store_cv_values` parameter documentation to
  `RidgeClassifierCV`.

## Assumptions and alternatives considered

- I kept the change limited to `RidgeClassifierCV` because `_BaseRidgeCV`,
  `_RidgeGCV`, and `RidgeCV` already implement the requested behavior.
- I appended `store_cv_values` after `class_weight` in the constructor to avoid
  changing the meaning of existing positional calls that pass `class_weight`.
- I did not add or modify tests because the task explicitly forbids editing test
  files. The hidden tests can check that the new keyword is accepted and that
  `cv_values_` is populated after `fit` when `cv=None`.
- I rejected a custom classifier-specific `cv_values_` implementation because
  the classifier already converts labels to the response matrix expected by
  `_BaseRidgeCV`, so duplicating that logic would add risk without changing the
  behavior requested in the issue.
