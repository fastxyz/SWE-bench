# Baseline Notes

## Root cause

`RepeatedKFold` and `RepeatedStratifiedKFold` inherit from
`_RepeatedSplits`, which did not implement `__repr__`. Unlike most other
cross-validation splitters, `_RepeatedSplits` also does not inherit from
`BaseCrossValidator`, so it did not receive the shared `BaseCrossValidator`
`__repr__` implementation.

Adding `__repr__` alone is not sufficient because `_build_repr` gathers
constructor parameters by reading attributes with the same names. The repeated
splitters pass `n_splits` through `_RepeatedSplits.__init__` as part of
`cvargs`, so there is no direct `self.n_splits` attribute. Without accounting
for `cvargs`, the generated representation would include `n_splits=None`.

## Files changed

`repo/sklearn/model_selection/_split.py`

- Added `__repr__` to `_RepeatedSplits`, delegating to the existing
  `_build_repr` helper used by other cross-validation splitters.
- Updated `_build_repr` to fall back to `self.cvargs` when a constructor
  parameter is not present as a direct attribute. This exposes `n_splits` for
  repeated splitters while preserving existing behavior for splitters that keep
  all parameters as direct attributes.

## Assumptions and alternatives considered

I assumed the repr output should continue to use the existing `_build_repr` and
`_pprint` behavior, including the current sorted parameter ordering used by
other cross-validation splitters. I considered adding a custom `__repr__`
implementation only to `RepeatedKFold` and `RepeatedStratifiedKFold`, but
rejected that because the shared `_RepeatedSplits` base class is the common
source of the missing behavior.

I also considered copying values such as `n_splits` from `cvargs` onto
`_RepeatedSplits` instances during initialization. I rejected that because it
would duplicate state and could diverge from the `cvargs` dictionary used to
construct the underlying randomized CV splitter. Reading from `cvargs` only
when the direct attribute is absent keeps the change targeted to
representation building.
