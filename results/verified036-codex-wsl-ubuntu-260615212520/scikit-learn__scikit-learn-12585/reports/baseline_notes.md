# Baseline Notes

## Root cause

`clone` decided whether an object was estimator-like by checking only
`hasattr(estimator, 'get_params')`. Estimator classes also expose
`get_params`, but as an unbound method on the class rather than as a bound
method on an instance. When such a class was used as a parameter value,
recursive cloning called `get_params(deep=False)` on the class and raised a
missing-`self` `TypeError`.

The same loose check existed in `BaseEstimator.get_params(deep=True)`, so a
class-valued parameter could also fail during normal deep parameter
introspection even after `clone` itself was fixed.

## Changed files

`repo/sklearn/base.py`

- Updated `clone` so objects that are classes are not treated as estimator
  instances solely because they define `get_params`. With `safe=False`, which
  is used for parameter values, class-valued parameters now follow the existing
  non-estimator fallback path and are deep-copied.
- Updated `BaseEstimator.get_params(deep=True)` with the same class exclusion
  so class-valued parameters are reported as ordinary parameters instead of
  being expanded as nested estimators.

## Assumptions and alternatives

- I assumed estimator classes should be accepted as parameter values, but not
  as estimator instances to clone directly. This matches the existing
  `safe=False` fallback behavior used for non-estimator parameter values.
- I used `six.class_types` rather than `type` so the check follows the
  repository's compatibility style.
- I rejected checking `isinstance(obj, BaseEstimator)` because the existing
  code deliberately supports estimator-like objects outside `BaseEstimator`,
  including Gaussian-process kernels with `get_params`.
- I considered changing only `clone`, but rejected that because
  `get_params(deep=True)` and callers such as `set_params` would still trip on
  class-valued parameters.
- I did not modify tests and did not run tests or code, per the task
  instructions.
