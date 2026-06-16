# Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

Keep V1 unchanged. The FVK audit found the V1 edit matches the intent-derived
contract and discharges the relevant proof obligations:

- PO2 and PO3 are discharged by sharing one normalized RNG object across all
  per-class `KFold` splitters.
- PO4 is discharged by the formal model's `(0, 1)` draw-index result for the
  equal-class issue shape.
- PO5 is discharged by unchanged validation, non-shuffle, balancing, and
  stateful-RNG behavior.

## Recommended future tests

If tests were allowed in a normal development setting:

- Add a regression test for `n_splits == samples_per_class` with two equal-sized
  classes and `shuffle=True`, checking that class pairings are not the same
  fixed offset pattern caused by identical per-class permutations.
- Keep reproducibility tests for integer seeds.
- Keep stateful behavior tests for `RandomState` instances and `None`.
- Keep non-shuffled ordering and coverage tests.

## Verification commands for a future environment

Do not run these in this benchmark session. They are the commands a later
machine-checking pass should use:

```sh
cd fvk
kompile mini-python-stratified-kfold.k --backend haskell
kast --backend haskell stratified-kfold-spec.k
kprove stratified-kfold-spec.k
```

## Open boundary

The mini-model proves that V1 removes the structural reseeding bug. It does not
prove concrete NumPy permutation tables, performance, or total correctness of
the complete scikit-learn splitter stack. Those are outside this FVK pass and
should remain covered by ordinary tests.
