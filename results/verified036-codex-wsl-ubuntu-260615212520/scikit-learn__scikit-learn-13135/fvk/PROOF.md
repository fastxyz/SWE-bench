# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or project code were run.

## Claims

The formal claims are written in `kbins-discretizer-spec.k` against the
minimal ordered-list fragment in `mini-python.k`.

- `KMEANS-SORT-CENTERS`: sorting the KMeans center list returns a nondecreasing
  list with the same center multiset.
- `KMEANS-EDGES-MONOTONE`: sorted in-range centers produce nondecreasing
  k-means midpoint edges with `col_min` and `col_max` endpoints.
- `DIGITIZE-SAFE-SUFFIX`: the suffix passed to digitization is nondecreasing
  whenever learned edges are nondecreasing.

## Proof outline

1. Start from one nonconstant feature in the audited k-means domain.
2. By PO-002, V1 rewrites the center vector to a nondecreasing center list while
   preserving the center multiset.
3. By PO-003, every center is between `col_min` and `col_max`.
4. For the first learned midpoint, `col_min <= c0 <= c1`, so
   `col_min <= (c0+c1)/2`.
5. For every adjacent pair of midpoints,
   `(ci+c{i+1})/2 <= (c{i+1}+c{i+2})/2` because `ci <= c{i+2}` after sorting.
6. For the final midpoint, `c{k-2} <= c{k-1} <= col_max`, so
   `(c{k-2}+c{k-1})/2 <= col_max`.
7. Therefore the whole learned edge vector is nondecreasing.
8. A suffix of a nondecreasing vector is nondecreasing, so
   `bin_edges[jj][1:]` satisfies the modeled monotonicity precondition for
   `np.digitize`.
9. The feature loop composes this per-feature argument independently for every
   processed feature.

## Symbolic execution sketch

In the K fragment:

1. `kmeansEdges(MIN, MAX, CENTERS)` rewrites to
   `edgesFromSortedCenters(MIN, MAX, sortInts(CENTERS))`.
2. Simplification rules for `sortInts` establish `sorted(sortInts(CENTERS))`,
   `sameBag(CENTERS, sortInts(CENTERS))`, and range preservation.
3. The midpoint-edge lemma rewrites
   `sorted(edgesFromSortedCenters(MIN, MAX, SORTED))` to `true` under
   `MIN < MAX`, `sorted(SORTED)`, and `inRange(MIN, MAX, SORTED)`.
4. `tail` preserves sortedness, so `digitizeWithBins(tail(EDGES))` rewrites to
   `true` under `sorted(EDGES)`.

These steps discharge PO-002 through PO-005. PO-006 is the standard loop
invariant over the feature loop: processed features have monotonic k-means
edges; processing one additional audited feature preserves the invariant.

## Machine-check commands, not executed

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/kbins-discretizer-spec.k
kprove fvk/kbins-discretizer-spec.k
```

Expected result after a real machine check: `#Top` for the claims in
`kbins-discretizer-spec.k`.

## Test recommendations

Do not remove any tests based on this constructed proof. After a successful
machine check, point tests that only assert no digitize monotonicity error for
in-domain k-means center orderings would be subsumed by the proof. Integration,
validation, KMeans infeasibility, encoding, inverse-transform, and
cross-strategy tests should be kept.

## Residual risk

This proof is partial correctness and constructed only. It relies on the
adequacy of the ordered-scalar abstraction for the monotonicity property, the
KMeans in-range side condition, and a future machine check of the emitted K
claims.
