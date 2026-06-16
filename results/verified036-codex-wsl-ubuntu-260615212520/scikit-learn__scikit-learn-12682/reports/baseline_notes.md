# Baseline Notes

## Root Cause

`sparse_encode` already accepted a `max_iter` argument and passed it to the
coordinate-descent `Lasso` estimator used by `algorithm='lasso_cd'`. The
`algorithm='lasso_lars'` branch constructed `LassoLars` without forwarding that
same value, so `LassoLars` always used its constructor default. In addition,
`SparseCodingMixin.transform` did not pass any transform-level iteration limit
to `sparse_encode`, so estimators such as `SparseCoder` could not expose the
control that `sparse_encode` already had.

## Files Changed

`repo/sklearn/decomposition/dict_learning.py`

- Forwarded `_sparse_encode(..., max_iter=...)` into the `LassoLars`
  constructor for `algorithm='lasso_lars'`, matching the existing forwarding to
  `Lasso` for `algorithm='lasso_cd'`.
- Added `transform_max_iter` to `SparseCodingMixin` and passed it from
  `transform` into `sparse_encode`.
- Added `transform_max_iter` to `SparseCoder`, `DictionaryLearning`, and
  `MiniBatchDictionaryLearning` so all estimators using the shared sparse
  coding transform path expose the same control.
- Updated in-source parameter documentation to state that `max_iter` applies to
  both `lasso_cd` and `lasso_lars`.

## Assumptions and Alternatives

- I assumed the intended public estimator parameter should be
  `transform_max_iter`, not a bare `max_iter`, because the existing estimator
  API prefixes transform-time controls with `transform_`, and
  `DictionaryLearning.max_iter` already controls the dictionary-learning fit
  loop.
- I considered adding a generic `algorithm_kwargs` or lasso-specific kwargs
  parameter, but rejected it as broader than the issue requires and inconsistent
  with the existing explicit estimator parameters.
- I considered changing only the default `LassoLars` call in `_sparse_encode`.
  That would make direct `sparse_encode` calls honor `max_iter`, but would not
  let `SparseCoder` users configure the transform-time solver limit.
- I did not modify tests or run tests, per the task constraints.
