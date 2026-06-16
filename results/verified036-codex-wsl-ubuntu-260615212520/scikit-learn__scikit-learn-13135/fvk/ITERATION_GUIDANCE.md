# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is recommended. Findings F-001, F-002, and F-004 are
resolved by sorting KMeans centers before midpoint construction. Finding F-005
confirms there is no public compatibility or unrelated-branch reason to revise
the patch.

## Why not change more

- Sorting final `bin_edges_` instead of centers is rejected by F-002 and PO-004:
  midpoint edges must be computed between neighboring centers, not repaired
  after averaging arbitrary pairs.
- Sorting bins inside `transform` is rejected by F-004 and PO-005: learned
  `bin_edges_` should already satisfy the monotonicity invariant after `fit`.
- Changing validation for KMeans infeasibility is outside the unordered-edge
  finding and not required by PO-001.
- Editing tests is forbidden by the task and not recommended by this constructed
  proof.

## Suggested tests for a normal development workflow

These are recommendations only; no test file was edited.

- Add or keep a regression test for the public reproducer:
  `X = [0, 0.5, 2, 3, 9, 10]`, `n_bins=5`, `strategy='kmeans'`,
  `encode='ordinal'`, asserting no monotonicity error.
- Add or keep a direct assertion that learned k-means `bin_edges_[0]` is
  nondecreasing for a case where KMeans returns unsorted centers.
- Keep existing integration tests for encoding, inverse transform, constant
  features, and non-k-means strategies.

## Next verification step

The FVK proof is constructed, not machine-checked. A future environment with K
available should run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/kbins-discretizer-spec.k
kprove fvk/kbins-discretizer-spec.k
```
