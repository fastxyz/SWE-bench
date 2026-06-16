# Baseline Notes

## Root cause

`SequentialFeatureSelector` evaluates many candidate feature subsets during a
single `fit`. For every candidate, `_get_best_new_feature_score` called
`cross_val_score(..., cv=self.cv)`. When `self.cv` was a one-shot iterable such
as the generator returned by `LeaveOneGroupOut().split(...)`, the first
candidate consumed the iterable. Later candidates then saw no splits, leading to
an empty score list inside cross-validation aggregation and the reported
`IndexError`.

Other scikit-learn estimators normalize `cv` once with `check_cv`. For iterable
splits without a `split` method, `check_cv` stores the splits in a reusable
wrapper, allowing repeated `split` calls within the same fit.

## Files changed

`repo/sklearn/feature_selection/_sequential.py`

- Imported `check_cv` and `is_classifier`.
- In `SequentialFeatureSelector.fit`, converted `self.cv` once to a checked CV
  object using `check_cv(self.cv, y, classifier=is_classifier(cloned_estimator))`.
- Passed that checked CV object into `_get_best_new_feature_score` so each
  candidate subset is scored against reusable splits instead of repeatedly
  consuming the original `self.cv` value.

## Assumptions and alternatives considered

- I assumed the documented API should continue accepting iterable split inputs,
  including generator-style inputs, because this matches `check_cv` and the
  `*SearchCV` classes referenced in the issue discussion.
- I did not change `_parameter_constraints` to reject generators. That would make
  `SequentialFeatureSelector` less consistent with the rest of scikit-learn's CV
  API and would only document the failure instead of fixing it.
- I did not assign the checked CV object back to `self.cv`, because estimator
  constructor parameters should remain the user-provided values for parameter
  inspection and cloning.
- I did not add or modify tests because the benchmark instructions forbid
  modifying test files.
