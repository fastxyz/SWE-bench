# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

- `StratifiedKFold._make_test_folds(self, X, y=None)`: private helper changed
  only in how it prepares the internal `random_state` value for per-class
  `KFold` splitters.

## Public API

- `StratifiedKFold.__init__(n_splits='warn', shuffle=False, random_state=None)`
  is unchanged.
- `StratifiedKFold.split(self, X, y, groups=None)` is unchanged.
- Yielded train/test index shape is unchanged.
- No new keyword arguments or virtual dispatch calls are introduced.

## Callsite and override audit

Static search found `_make_test_folds` defined and used only inside
`repo/sklearn/model_selection/_split.py`. No public subclass override or caller
needs a signature update.

## Behavioral compatibility

- `shuffle=False`: the V1 code sets the internal RNG variable to `None` and
  passes `shuffle=False` to `KFold`; `KFold` does not consult `random_state`
  when shuffling is off. Existing non-shuffled behavior is preserved.
- Integer `random_state`: repeated `split` calls remain reproducible because
  each `_make_test_folds` call creates a fresh `RandomState(seed)` once.
- `RandomState` instance: stateful behavior is preserved because
  `check_random_state` returns the same object.
- Validation order: V1 performs target-type and class-count validation before
  normalizing the RNG, matching the legacy order more closely than validating
  `random_state` at function entry.

Compatibility verdict: pass.
