# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged. The audit found no additional production-code defect.

## Why no source edit is justified

- F-001 is resolved by PO-1 and PO-7: internal `fit` offset scoring no longer
  calls the public validation path that emitted the reported warning.
- F-002 is resolved by PO-3: public `score_samples` validation and warnings are
  preserved.
- F-003 is resolved by PO-5: sparse fit data is converted to CSR in the private
  scoring helper before scoring.
- F-004 is acceptable under PO-6: public signatures are unchanged and no in-repo
  override conflict exists.
- F-005 is a proof capability boundary, not a code bug.

## Suggested tests for a normal development environment

Do not add or modify tests in this benchmark task. In a normal PR, useful tests
would be:

- Fit `IsolationForest(contamination=0.05)` on a pandas DataFrame with valid
  string columns under a warning-as-error context and assert no feature-name
  warning is emitted.
- Fit on a DataFrame and then call public `score_samples` on an ndarray, and
  assert the standard public feature-name warning still occurs.
- Fit with sparse input and fixed contamination to cover the internal
  CSC-to-CSR scoring path.

## Commands for future machine checking

Do not run these in this benchmark session. In an environment with K installed:

```sh
kompile fvk/mini-iforest.k --backend haskell
kast --backend haskell fvk/iforest-fit-spec.k
kprove fvk/iforest-fit-spec.k
```

Until those commands return `#Top`, keep all existing tests.
