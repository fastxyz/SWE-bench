# Baseline Notes

## Root cause

`StratifiedKFold._make_test_folds` created one internal `KFold` splitter per
class and passed `self.random_state` to each of them. When `random_state` was an
integer and `shuffle=True`, every per-class `KFold` rebuilt a fresh RNG from the
same seed. Classes with the same number of samples therefore received the same
shuffled fold pattern, so samples were paired across classes in the same way for
every seed; only the fold order changed.

## Files changed

- `repo/sklearn/model_selection/_split.py`: convert `self.random_state` into a
  single shared `RandomState` instance when `StratifiedKFold` is shuffling.
  Passing that shared RNG to the per-class `KFold` splitters lets each class draw
  a different permutation from the same deterministic stream, while keeping
  integer seeds reproducible. When `shuffle=False`, the RNG is still unused.

## Assumptions and alternatives considered

- I assumed the intended behavior is the documented one: shuffle each class's
  samples before assigning fold batches, not merely shuffle the order in which
  otherwise identical batches are emitted.
- I considered changing the public documentation instead, but rejected that
  because the issue and public hint identify the behavior as a regression and
  state that different random seeds should produce different splits.
- I considered replacing the per-class `KFold` construction entirely, but the
  existing code already handles fold sizes, under-populated classes, and
  coverage. Sharing one RNG across those existing splitters is the smallest
  targeted fix.
- I did not run tests or project code because the task explicitly forbids
  execution in this benchmark session.
