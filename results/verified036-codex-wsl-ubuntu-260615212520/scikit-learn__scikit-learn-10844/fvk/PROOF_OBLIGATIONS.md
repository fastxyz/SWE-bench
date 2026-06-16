# FVK PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-1: Valid contingency-count domain

For all valid labelings after `check_clusterings` and contingency construction:

- `tk`, `pk`, and `qk` are nonnegative pair counts.
- `tk <= pk` because every pair counted together in both labelings is counted
  together in the predicted-label marginal.
- `tk <= qk` because every pair counted together in both labelings is counted
  together in the true-label marginal.

This obligation is intent-derived from the FMI definition and
implementation-derived from the contingency-count formulas.

## PO-2: Zero branch

If `tk == 0`, the function returns `0.0` without evaluating any denominator.

This discharges the documented completely split case and avoids `0 / 0` when
`pk` or `qk` is also zero.

## PO-3: Positive denominators on the nonzero branch

Given PO-1, if `tk > 0`, then `pk >= tk > 0` and `qk >= tk > 0`.

Therefore `tk / pk` and `tk / qk` are defined on the V1 branch.

## PO-4: Algebraic equivalence to the public FMI formula

For `tk > 0`, `pk > 0`, `qk > 0`:

```text
sqrt(tk / pk) * sqrt(tk / qk)
= sqrt((tk / pk) * (tk / qk))
= sqrt(tk * tk / (pk * qk))
= tk / sqrt(pk * qk)
```

The last step uses `tk >= 0`.

## PO-5: No overflowing integer denominator product

The V1 expression evaluates two true divisions first:

```python
np.sqrt(tk / pk) * np.sqrt(tk / qk)
```

It never evaluates the integer expression `pk * qk`. Under PO-1 and PO-3, both
ratios are in `(0, 1]` on the nonzero path, so the remaining floating
multiplication is bounded and is not the reported integer overflow site.

## PO-6: Public examples and invariants are preserved

The V1 expression preserves:

- Perfect labelings: `tk == pk == qk > 0`, so the score is `1.0`.
- Completely split labelings: `tk == 0`, so the score is `0.0`.
- Handcrafted examples: formula equivalence from PO-4.
- Symmetry and label-permutation invariance: the count definitions are
  unchanged, and PO-4 preserves the same count-based formula.
- Bounded range: from PO-1, both ratios are in `[0, 1]`, so the score is in
  `[0, 1]`.

## PO-7: Abstraction boundary for count construction

The proof assumes the source has already computed the mathematical counts
`tk`, `pk`, and `qk` represented in PO-1. It does not machine-check SciPy sparse
matrix construction, NumPy dtype promotion, or floating-point rounding.

This boundary is acceptable for the reported issue because the public defect is
the final product `pk * qk`, but it prevents recommending removal of public
integration tests over label arrays.

## PO-8: Compatibility

The fix must not change:

- Function name: `fowlkes_mallows_score`.
- Signature: `(labels_true, labels_pred, sparse=False)`.
- Import/export surface in `sklearn.metrics`, `sklearn.metrics.cluster`, and
  scorer registration.
- Return kind: scalar score.

V1 changes only the internal arithmetic expression, so this obligation is
discharged.

## Constructed K commands

These commands were written as artifacts only and were not executed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/fowlkes-mallows-spec.k
kprove fvk/fowlkes-mallows-spec.k
```

Expected machine-check result, if the compact semantics and claims parse and
the simplification lemmas are accepted: `#Top`.
