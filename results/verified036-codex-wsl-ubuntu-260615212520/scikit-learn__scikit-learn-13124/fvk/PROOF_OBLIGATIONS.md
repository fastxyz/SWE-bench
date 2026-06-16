# Proof Obligations

Status: constructed, not machine-checked.

## Adequacy obligations

PO1. Intent adequacy: the formal claims must encode "shuffle each
stratification" and "do not shuffle every class in the same way with the same
random state," not the legacy observed output. Evidence: E1-E6. Status:
discharged by `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.

## Code and formal proof obligations

PO2. Single RNG normalization for integer seeds: on the `shuffle=True` path,
`_make_test_folds` must call `check_random_state(self.random_state)` once before
constructing per-class `KFold` splitters. Status: discharged by static source
inspection of `_split.py` line 653 and by claim `V1-INT-SEED-SHARED-RNG`.

PO3. Shared object consumption: every per-class `KFold` must receive the same
RNG object, not a fresh integer seed. Status: discharged by `_split.py` lines
654-657 and by the mini-K transition from `rng(S, D)` to consecutive
`draw(S, D, count)` entries.

PO4. Reported equal-class case: for two equal-sized classes with count `N`, V1
must produce abstract draws `(0, 1)` while the legacy implementation produced
`(0, 0)`. Status: discharged by claims `V1-INT-SEED-SHARED-RNG` and
`LEGACY-RESEED-BUG`.

PO5. Frame conditions: V1 must preserve non-shuffled behavior, integer-seed
reproducibility, stateful `RandomState` behavior, class balance/coverage, and
validation/warning order. Status: discharged by unchanged surrounding code,
`check_random_state` source, public tests, and claims `NO-SHUFFLE-FRAME` and
`RNG-OBJECT-ADVANCES`.

PO6. Public compatibility: V1 must not change public signatures, return shapes,
or virtual dispatch requirements. Status: discharged by
`PUBLIC_COMPATIBILITY_AUDIT.md`.

PO7. Honesty boundary: the proof must label itself constructed, not
machine-checked, because no K tooling may be run in this session. Status:
discharged by `PROOF.md` and emitted commands.

## Rejected obligation

R1. Universal seed injectivity: "for all distinct integer seeds, final fold
membership is distinct." Rejected as stronger than public intent and false in
principle for finite random outputs. The accepted obligation is PO2-PO4.
