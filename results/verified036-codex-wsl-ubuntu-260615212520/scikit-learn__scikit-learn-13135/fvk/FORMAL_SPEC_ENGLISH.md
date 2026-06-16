# Formal Spec English

This file paraphrases the nontrivial formal claims in
`kbins-discretizer-spec.k`.

## Claim KMEANS-SORT-CENTERS

For any finite list of one-dimensional KMeans centers, the operation modeled as
`sortCenters` returns a list that is nondecreasing and contains the same center
multiset. This corresponds to the `np.sort(...)` call in V1.

## Claim KMEANS-EDGES-MONOTONE

For a nonconstant feature with `MIN < MAX`, at least two centers, and every
center in `[MIN, MAX]`, if the centers are sorted before edge construction, then
the edge list

`[MIN, midpoint(c0,c1), midpoint(c1,c2), ..., midpoint(c{k-2},c{k-1}), MAX]`

is nondecreasing.

## Claim DIGITIZE-SAFE-SUFFIX

If learned `bin_edges_` for a feature are nondecreasing, then the suffix
`bin_edges_[1:]` passed to `np.digitize` is also nondecreasing. Therefore the
modeled `digitizeWithBins` step does not raise the monotonicity error.

## Claim FEATURE-LOOP-FRAME

The feature loop in `fit` may be reasoned about per feature: once every
processed feature has monotonic edges, processing one more k-means feature with
the sorted-center construction preserves the invariant. Branches for constant,
uniform, and quantile features are unchanged by V1.

## Side conditions

The proof is partial correctness over the audited domain. It assumes finite
numeric inputs accepted by existing validation, successful KMeans fitting, and
the standard k-means fact that produced one-dimensional center coordinates lie
within the fitted feature range.
