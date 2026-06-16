# INTENT SPEC

Intent-only obligations from public evidence:

1. `fowlkes_mallows_score` computes the Fowlkes-Mallows index:
   `tk / sqrt(pk * qk)` for nonzero shared-pair count.
2. The function returns `0.0` when the shared-pair count is zero.
3. The function should return a scalar float and should not produce `nan` from
   integer overflow in `pk * qk`.
4. The score is in `[0, 1]` for valid contingency-derived counts.
5. Perfect relabelings score `1.0`; fully split/shared-pair-free cases score
   `0.0`; symmetry and label-permutation invariance are preserved.
6. Public function signature and import/export behavior are unchanged.
