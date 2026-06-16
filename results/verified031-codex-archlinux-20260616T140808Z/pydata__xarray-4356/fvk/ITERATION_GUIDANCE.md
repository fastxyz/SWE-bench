# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by the FVK audit. The V1 change directly
addresses F-001 and discharges PO-001 through PO-006. The only remaining issue,
F-004 / PO-007, is a proof-scope limitation: the mini semantics does not replace
ordinary NumPy/Dask tests or machine checking.

## Why V1 Stands

- F-001 is resolved because the explicit multi-axis rejection was removed.
- F-002 is resolved because `np.take(mask.shape, axis).prod()` supplies the
  product-of-reduced-axis-sizes count required by PO-002.
- F-003 is resolved because the single-axis formula is preserved and the scalar
  branch was not changed.
- F-004 does not call for a source edit; it calls for keeping tests and labeling
  the proof as constructed, not machine-checked.

## Next Iteration If More Assurance Is Needed

- Add public tests for the cross-product that was missing: multi-axis reduction
  plus `min_count`, with both keep and null outcomes.
- Add Dask-backed coverage for the same behavior if Dask is in scope.
- Machine-check the supporting K files in an environment with K installed:

```sh
kompile fvk/mini-nanops.k --backend haskell
kast --backend haskell fvk/nanops-min-count-spec.k
kprove fvk/nanops-min-count-spec.k
```

## Non-Goals For This Iteration

- Do not edit test files in this benchmark task.
- Do not broaden the patch to unrelated reduction documentation or API cleanup.
- Do not claim test redundancy until the proof is machine-checked against an
  adequate semantics.
