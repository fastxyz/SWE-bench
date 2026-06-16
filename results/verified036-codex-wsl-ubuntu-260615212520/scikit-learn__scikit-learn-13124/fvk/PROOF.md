# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## What is proved

For the property-complete mini-model in
`fvk/mini-python-stratified-kfold.k`, the V1 implementation satisfies the
intent-derived RNG-sharing contract:

- with `shuffle=True` and integer seed `S`, one `_make_test_folds` call uses one
  RNG stream and equal-sized classes consume consecutive draw indexes;
- the legacy reseeding mechanism consumes draw index `0` for every class and is
  therefore the source of the fixed class-pairing symptom;
- `shuffle=False` remains ordered and does not use an RNG;
- a stateful RNG object starts from its current draw index and advances across
  classes.

This is a partial-correctness proof over the mini-model, not a full proof of
Python, NumPy, or scikit-learn.

## Proof sketch

1. For `makeTestFolds(true, intSeed(S), count(N) count(N) .Counts)`, the
   semantics rewrites through `checkRandomState(true, intSeed(S))` to
   `rng(S, 0)`.
2. `assignPerms(true, rng(S, 0), count(N) count(N) .Counts)` emits
   `draw(S, 0, N)` for the first class and recurs with `rng(S, 1)`.
3. The second class emits `draw(S, 1, N)` and recurs with `rng(S, 2)`.
4. The empty count list rewrites to `.Perms`, yielding
   `draw(S, 0, N) draw(S, 1, N) .Perms`. This proves claim
   `V1-INT-SEED-SHARED-RNG`.
5. The legacy claim follows similarly except `legacyAssignPerms` receives
   `intSeed(S)` for every class, so both recursive steps emit `draw(S, 0, N)`.
   This proves the localized bug mechanism.
6. The `shuffle=False` claim follows from `checkRandomState(false, _) => noRng`
   and the ordered assignment rules.
7. The `rngObj` claim follows from `checkRandomState(true, rngObj(S, D)) =>
   rng(S, D)` and the same consecutive-consumption rule.

All side conditions are linear integer checks (`N >= 0`, `N >= 2`,
`D + 1`) in the mini-model. There are no loop circularities in this abstraction;
the recursion over `Counts` is modeled as terminating structural simplification
over the finite per-class count list.

## Source-to-proof correspondence

- `_split.py` line 653 corresponds to `checkRandomState(true, intSeed(S)) =>
  rng(S, 0)`: the integer seed is normalized once per `_make_test_folds` call.
- `_split.py` lines 654-657 correspond to `assignPerms`: every per-class `KFold`
  receives the same RNG object.
- `KFold._iter_test_indices` shuffles via `check_random_state(self.random_state)`
  only when `self.shuffle` is true; with a shared `RandomState` object this
  consumes consecutive RNG state.
- `validation.py` lines 760-778 justify the seed normalization model:
  integers create a new `RandomState`; existing `RandomState` instances are
  returned as themselves.

## Exact commands to machine-check later

These commands are recorded for a future environment with K installed. They were
not run here.

```sh
cd fvk
kompile mini-python-stratified-kfold.k --backend haskell
kast --backend haskell stratified-kfold-spec.k
kprove stratified-kfold-spec.k
```

Expected machine-check result after a successful proof: `#Top`.

## Test recommendations

No tests were edited. If test edits were allowed, add or keep tests that assert:

- for the issue shape (`samples_per_class == n_splits`), `shuffle=True` with an
  integer seed does not pair every class by the same within-class position;
- repeated calls with the same integer seed remain identical;
- `shuffle=False` output remains unchanged;
- `RandomState` instance behavior remains stateful.

Any recommendation to remove tests is conditional on actually running the K
commands and obtaining `#Top`; until then, keep existing tests.

## Residual risk

The proof is constructed, not machine-checked. The mini-model abstracts concrete
NumPy permutation values and proves the RNG-sharing mechanism, not distribution
quality or universal seed injectivity. Full validation, warning, and coverage
behavior is audited by static source inspection because the relevant source
around V1 is unchanged.
