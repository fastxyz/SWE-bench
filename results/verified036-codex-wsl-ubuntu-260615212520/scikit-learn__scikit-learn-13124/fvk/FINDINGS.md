# FVK Findings

Status: constructed, not machine-checked.

## F1: Legacy integer-seed shuffling reused the same per-class draw

- Classification: code bug, resolved by V1.
- Input shape: two classes with equal count `N`, `n_splits == N`,
  `shuffle=True`, and integer `random_state=S`.
- V0 observed by source inspection: every per-class `KFold` received integer
  seed `S`, so every class constructed a fresh RNG at draw index `0`. Abstract
  result: `draw(S, 0, N), draw(S, 0, N)`.
- Expected from E1-E6: one split call should use one deterministic RNG stream,
  so the two classes consume `draw(S, 0, N), draw(S, 1, N)`.
- V1 status: resolved. `_make_test_folds` now calls `check_random_state` once
  when `shuffle=True` and passes the shared RNG object to all per-class `KFold`
  instances.
- Source trace: `repo/sklearn/model_selection/_split.py` lines 653-657.
- Proof obligations: PO2, PO3, PO4.

## F2: "Every different seed gives different splits" is too strong

- Classification: underspecified / rejected over-specification.
- Input shape: arbitrary two distinct integer seeds on arbitrary class counts.
- Observed issue wording: users expect different batches for different seeds.
- Formal audit: a random generator can collide in principle, and the public
  issue specifically points to structural reseeding of each class with the same
  seed. The enforceable obligation is that different seeds and successive RNG
  draws are allowed to affect sample-to-fold assignment, not that all possible
  seeds are globally injective.
- V1 status: acceptable. V1 removes the structural reason that class pairings
  are independent of sample-level RNG draws.
- Proof obligations: PO1 and PO4.

## F3: Full NumPy permutation values are outside the mini-model

- Classification: proof capability boundary, not a code bug.
- Input shape: concrete NumPy `RandomState` permutations for all seeds/counts.
- Audit decision: the formal model tracks `draw(seed, draw_index, count)` rather
  than the concrete permutation list. This abstraction is property-complete for
  the defect because the failing and passing mechanisms map to different draw
  indexes: legacy maps equal-sized classes to `(0, 0)`, V1 maps them to `(0, 1)`.
- Residual risk: machine-checking the full Python/NumPy semantics is not done in
  this benchmark session and is outside the FVK mini-model.
- Proof obligations: PO7.

## F4: No additional production-code change is justified

- Classification: V2 confirmation.
- Audit result: all intent-derived obligations are discharged by V1 or are frame
  conditions preserved by unchanged code. No FVK finding requires a source edit
  beyond the V1 line that shares the RNG.
- Proof obligations: PO2-PO7.
