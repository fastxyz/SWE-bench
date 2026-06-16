# Intent Spec

Status: constructed for audit, not machine-checked.

## Required behavior from public intent

I1. `StratifiedKFold(shuffle=True)` must shuffle samples within each
stratification before assigning fold batches. It must not merely reorder a
fixed set of fold batches.

I2. When `random_state` is an integer and `shuffle=True`, the seed must make the
whole split reproducible, but the implementation must not reinitialize the same
seed independently for every class. Equal-sized classes must be allowed to draw
different per-class permutations from the deterministic RNG stream.

I3. Different integer seeds should affect the sample-to-fold assignment whenever
the underlying RNG produces different permutations. The public issue cannot
impose the stronger mathematical guarantee that every possible pair of seeds
always gives different final splits.

I4. Existing stratification frame conditions remain in scope: each sample is
assigned to exactly one test fold; per-class fold counts are still produced by
the existing `KFold` balancing logic; and under-populated classes keep the
existing warning/trim behavior.

I5. Existing random-state frame conditions remain in scope: integer seeds make
repeated `split` calls reproducible; `RandomState` instances and `None` are
stateful because their RNG objects advance; and `random_state` is only used when
`shuffle=True`.

I6. The public API must remain compatible. `StratifiedKFold` must keep the same
constructor signature, `split` signature, yielded index shape, and error/warning
behavior for target validation and class-count validation.

## Observed behavior to check

V0 observed behavior: `_make_test_folds` passed the integer `self.random_state`
to every per-class `KFold`, so each class rebuilt the same RNG and equal-sized
classes received the same permutation pattern.

V1 candidate behavior: `_make_test_folds` normalizes `self.random_state` once
with `check_random_state(self.random_state)` when `shuffle=True`, then passes the
same RNG object to all per-class `KFold` instances. Consecutive class shuffles
therefore consume consecutive draws from one deterministic stream.
