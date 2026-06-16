# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is `StratifiedKFold._make_test_folds` in
`repo/sklearn/model_selection/_split.py`, specifically the interaction between
`shuffle`, `random_state`, and the per-class internal `KFold` splitters. The
formal model is intentionally smaller than Python/NumPy but property-complete
for the reported defect: it preserves the observable axis that matters, namely
which RNG draw supplies each class's per-class permutation.

## Intent-derived contract

For binary or multiclass targets that pass the existing validation and
class-count checks:

1. If `shuffle=False`, the existing ordered per-class fold assignment behavior
   is unchanged and `random_state` is unused.
2. If `shuffle=True` and `random_state` is an integer seed `S`, `_make_test_folds`
   creates one RNG stream from `S` for the whole call and all per-class `KFold`
   splitters consume that stream sequentially.
3. For two equal-sized classes of size `N`, the first class uses draw index `0`
   from stream `S` and the second class uses draw index `1` from stream `S`.
   The legacy behavior used draw index `0` for both classes.
4. Repeated calls with the same integer seed recreate the same stream at draw
   index `0`, preserving reproducibility.
5. A `RandomState` instance remains stateful because `check_random_state` returns
   the object itself; consecutive per-class shuffles and later split calls keep
   advancing that object.
6. Stratification balancing, sample coverage, validation, warning behavior, and
   public API signatures remain unchanged.

## Public intent ledger summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E4 derive the postcondition that `shuffle=True` acts inside each class,
  not only on fold order.
- E5-E6 identify the root cause as giving every class the same random state and
  require different split membership when the RNG draws differ.
- E7-E10 are frame conditions: random-state reproducibility, stateful
  `RandomState`, `shuffle=False` behavior, balancing, and trim behavior.
- E11 is the compatibility frame: no public signature or override change.

## Formal model

`fvk/mini-python-stratified-kfold.k` models:

- seed kinds: integer seeds, stateful RNG objects, and no RNG;
- `check_random_state` behavior relevant to the issue;
- per-class assignment as a list of abstract permutation draws
  `draw(seed, draw_index, class_count)`;
- the legacy reseeding behavior for contrast.

`fvk/stratified-kfold-spec.k` states claims for:

- V1 integer-seed behavior: equal-sized classes use draw indexes `0` and `1`;
- legacy behavior: equal-sized classes used draw index `0` twice;
- `shuffle=False` frame behavior;
- stateful RNG-object consumption.

The model abstracts away the concrete NumPy permutation values. This is
deliberate: the public issue is caused by forced reuse of the same RNG draw, not
by a particular permutation table. The proof obligation is therefore "the
implementation uses distinct consecutive draw positions"; the derived runtime
consequence is "sample pairings differ whenever those consecutive RNG draws
produce different permutations."

## V2 decision

V1 stands unchanged. Static source inspection discharges the proof obligations:
line 653 normalizes the integer seed once when `shuffle=True`, and lines 654-657
pass the resulting shared RNG object to every per-class `KFold`. Since
`KFold._iter_test_indices` calls `check_random_state(self.random_state).shuffle`,
each class consumes the same object sequentially rather than rebuilding the same
seed. No additional source edit is justified by the FVK findings.
