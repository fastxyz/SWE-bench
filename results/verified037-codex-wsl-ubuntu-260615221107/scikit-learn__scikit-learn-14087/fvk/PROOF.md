# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Summary

The proof establishes partial correctness for the audited no-refit branch of
`LogisticRegressionCV.fit`: if fitting reaches the coefficient-selection block
with valid scoring-path shapes, then V2 selects the index form compatible with
the resolved multiclass strategy, avoids l1-ratio averaging for non-elastic-net
penalties, and adds l1-ratio attribute dimensions only for elastic-net fits.

## Formal Files

- Semantics fragment: `fvk/mini-logregcv.k`
- Claims: `fvk/logregcv-refit-false-spec.k`
- Obligations: `fvk/PROOF_OBLIGATIONS.md`

The fragment models only the proof-relevant control and shape facts. It does
not model numerical optimization, NumPy storage, joblib parallelism, or scorer
behavior.

## Constructed Proof Sketch

### O-001: Auto-OvR Indexing

1. `_check_multi_class('auto', solver, n_classes)` resolves to OvR when
   `n_classes <= 2` or `solver == 'liblinear'`.
2. In the OvR fit path, `self.coefs_paths_[cls]` is a class-specific
   three-axis path `(fold, candidate, coefficient)`.
3. V2 branches on the resolved local `multi_class`; therefore the OvR branch is
   selected for that shape.
4. The list comprehension indexes one fold and one candidate:
   `coefs_paths[i, best_indices[i], :]`.
5. The indexed axes match the three-axis path, so the reported four-index
   access is unreachable for resolved OvR cases.

### O-002: Multinomial Indexing

1. If `_check_multi_class` returns multinomial, the code did not narrow
   `coefs_paths` to a class-specific three-axis path.
2. The multinomial path retains axes `(class, fold, candidate, coefficient)`.
3. Since the resolved local `multi_class` is not OvR, V2 takes the multinomial
   branch and indexes `coefs_paths[:, i, best_indices[i], :]`.
4. Each axis access is defined under the modeled shape.

### O-004: l1_ratio_ Selection

Non-elastic-net case:

1. The validation block sets local `l1_ratios_` to `[None]`.
2. V2 checks `self.penalty == 'elasticnet'` before any vector indexing or
   averaging of `l1_ratios_`.
3. For all non-elastic-net penalties, the else branch appends `None`.
4. Therefore no mean over `[None]` is required and the public absence marker is
   preserved.

Elastic-net case:

1. Validation requires a non-empty list-like of numeric ratios in `[0, 1]`.
2. `best_indices_l1 = best_indices // len(self.Cs_)` selects one l1 block per
   fold.
3. `np.asarray(l1_ratios_)` makes accepted list-like inputs compatible with
   NumPy array indexing by `best_indices_l1`.
4. The mean is therefore defined over numeric selected l1 ratios.

### O-005: Attribute Shape Guard

1. The public docstring ties the extra l1-ratio dimension to
   `penalty='elasticnet'`, not to whether the ignored constructor argument was
   supplied.
2. V2 guards final path/scores/n_iter reshaping with
   `self.penalty == 'elasticnet'`.
3. Thus ignored `l1_ratios` on non-elastic-net fits cannot alter public
   attribute rank.

### O-006: API Frame

No public method signature, constructor parameter, return type, or virtual
dispatch protocol changed. The patch changes only internal branch guards and
selection logic inside `fit`.

## Machine-Check Commands Not Run

The environment forbids K tooling. These are the commands a later environment
should run:

```sh
kompile fvk/mini-logregcv.k --backend haskell
kast --backend haskell fvk/logregcv-refit-false-spec.k
kprove fvk/logregcv-refit-false-spec.k
```

Expected machine result after a complete K pass: `#Top` for all claims. This
has not been observed in this session.

## Test Recommendation

No tests were modified or run. Recommended future tests, not added here:

- A binary `multi_class='auto'`, `solver='saga'`, `refit=False` fit with the
  issue's default non-elastic-net penalty should complete without
  `IndexError`.
- The same family with `solver='liblinear'` should complete without
  `IndexError`.
- A non-elastic-net fit with an ignored non-`None` `l1_ratios` argument should
  warn but should not expose an l1-ratio dimension in `coefs_paths_`,
  `scores_`, or `n_iter_`.
- Existing elastic-net no-refit shape coverage should be kept.

Test removal is not recommended until a real machine-checked proof exists.
