# FVK Iteration Guidance

Status: V2 source repair applied.

## Decision

V1 did not fully satisfy the elastic-net-only shape obligation O-005. V2 keeps
the V1 branch and l1-ratio fixes and adds one targeted source edit:

- `repo/sklearn/linear_model/logistic.py`: final l1-ratio dimension reshape now
  checks `self.penalty == 'elasticnet'` instead of `self.l1_ratios is not None`.

No other source changes are justified by the current FVK findings.

## Next Tests to Add in a Normal Development Environment

Do not add tests in this benchmark session. In a normal session, add focused
coverage for:

1. Binary `multi_class='auto'`, `solver='saga'`, `refit=False`,
   non-elastic-net penalty: no `IndexError`.
2. Multi-class or binary `solver='liblinear'`, `multi_class='auto'`,
   `refit=False`: resolved OvR indexing is used.
3. Non-elastic-net penalty with a supplied, ignored `l1_ratios`: warning is
   emitted and no l1-ratio axis is added to `coefs_paths_`, `scores_`, or
   `n_iter_`.
4. Existing elastic-net no-refit tests remain valid, including list and array
   `l1_ratios` inputs.

## Commands for Later Verification

Do not run these in this environment:

```sh
kompile fvk/mini-logregcv.k --backend haskell
kast --backend haskell fvk/logregcv-refit-false-spec.k
kprove fvk/logregcv-refit-false-spec.k
```

## Residual Risk

- The proof is partial correctness only and abstracts away upstream optimizer
  convergence, scoring behavior, and NumPy implementation details.
- The proof is constructed, not machine-checked.
- No tests or project code were executed.
