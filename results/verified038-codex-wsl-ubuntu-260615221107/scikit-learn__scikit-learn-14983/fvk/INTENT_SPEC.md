# Intent Specification

Status: constructed from public evidence only; no tests, Python, or K tooling
were executed.

## Required behavior

I1. `repr(RepeatedKFold(...))` must return a constructor-like string for the
public splitter, not Python's default object-at-address representation.

I2. `repr(RepeatedStratifiedKFold(...))` must return the analogous
constructor-like string, not Python's default object-at-address representation.

I3. The repeated splitter representation must include the public constructor
parameters `n_splits`, `n_repeats`, and `random_state` with their actual values.
For default construction, the required values are `n_splits=5`,
`n_repeats=10`, and `random_state=None`.

I4. The value for `n_splits` must be taken from `_RepeatedSplits.cvargs` because
the repeated splitter subclasses do not store it as `self.n_splits`.

I5. Existing cross-validator representation behavior must be preserved where it
is not part of the reported defect. In particular, other splitters already use
`_build_repr` and `_pprint`, and public in-repository expectations show sorted
parameter order such as `KFold(n_splits=2, random_state=None, shuffle=False)`.

I6. The fix must not change splitting behavior, constructor signatures, public
method call shapes, or test files.

## Parameter-order resolution

The issue's expected-output block lists `n_splits` before `n_repeats`. The public
hint, however, says the fix should add `_RepeatedSplits.__repr__` delegating to
`_build_repr`, and that `_build_repr` should include values stored in `cvargs`.
The existing project helper sorts parameter keys through `_pprint`, and public
tests already assert that ordering for other cross-validation splitters.

Therefore the intent used for this audit is: repeated splitters must use the
same `_build_repr`/`_pprint` convention as the rest of `model_selection`, while
including the correct values. Under that convention the default repeated
splitter strings are:

- `RepeatedKFold(n_repeats=10, n_splits=5, random_state=None)`
- `RepeatedStratifiedKFold(n_repeats=10, n_splits=5, random_state=None)`

