# Public Compatibility Audit

Status: source-inspection only; no tests or code were executed.

## Changed symbols

`_RepeatedSplits.__repr__`

- Change type: new method on an internal base class used by public
  `RepeatedKFold` and `RepeatedStratifiedKFold`.
- Signature: `def __repr__(self)`, consistent with other splitter repr methods.
- Public callsites: Python's `repr(obj)` and printing. No existing caller can be
  broken by adding the method; it replaces object identity output with a
  constructor-like string.
- Override audit: no subclasses outside `RepeatedKFold` and
  `RepeatedStratifiedKFold` were found under `repo/sklearn`.
- Status: compatible.

`_build_repr`

- Change type: private helper behavior expanded for objects with `cvargs`.
- Signature: unchanged.
- Existing public consumers: `BaseCrossValidator.__repr__` and
  `BaseShuffleSplit.__repr__` call this helper.
- Compatibility condition: direct attributes must be read exactly as before;
  only missing direct attributes may fall back to `cvargs`.
- V1 status: satisfied by the sentinel fallback. Existing objects without
  `cvargs` still get `None` for missing attributes, and direct attributes are
  not overridden.
- Status: compatible.

## Producer/consumer shape

`_RepeatedSplits.__init__` already stores `cvargs` as a mapping and the repeated
subclasses already pass `n_splits` there. The V1 change consumes that existing
storage; it does not alter the storage shape.

## Test-file constraint

No test files were modified. Existing public tests remain compatibility
evidence, especially the exact repr strings for `KFold`, `StratifiedKFold`, and
other splitters.

