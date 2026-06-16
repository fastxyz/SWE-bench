# FVK Iteration Guidance

Status: V2 source changes are complete; proof is constructed, not
machine-checked.

## Code Decisions

- Keep the V1 `repo/sklearn/base.py::clone` class exclusion. It discharges
  F-001 through PO-1 without weakening PO-2.
- Keep the V1 `repo/sklearn/base.py::BaseEstimator.get_params` class exclusion.
  It discharges PO-3 and prevents the same unbound-method failure during deep
  parameter introspection.
- Add the same class exclusion to
  `repo/sklearn/utils/metaestimators.py::_BaseComposition._get_params`. This
  resolves F-002 and discharges PO-4 across public composition `get_params`
  paths.
- Do not change direct `clone(EstimatorClass, safe=True)` behavior. F-003 and
  PO-5 classify that as outside the issue's required support.

## Suggested Tests For A Future Test Pass

Do not add tests in this benchmark task. In a normal development pass, useful
tests would cover:

- `clone(StandardScaler(with_mean=StandardScaler))` does not raise and preserves
  the class-valued parameter.
- A custom `BaseEstimator` with `estimator=SomeEstimatorClass` returns that class
  from `get_params(deep=True)` without nested `estimator__...` keys.
- A composition with a class-valued named entry does not call unbound
  `Class.get_params` during `get_params(deep=True)`.
- A Gaussian-process kernel or other non-`BaseEstimator` object with
  `get_params` is still cloned/expanded as estimator-like.

## Commands For Later Verification

These are documentation-only in this session:

```sh
kompile fvk/mini-sklearn-clone.k --backend haskell
kast --backend haskell fvk/clone-params-spec.k
kprove fvk/clone-params-spec.k
```

Keep all relevant tests until those commands are actually run and return a
successful proof result.
