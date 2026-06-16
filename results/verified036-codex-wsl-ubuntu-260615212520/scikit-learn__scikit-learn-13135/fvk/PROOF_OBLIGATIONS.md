# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Audited domain

For each audited feature, input is finite numeric data accepted by
`check_array`, `strategy == 'kmeans'`, `n_bins[jj] >= 2`, the feature is
nonconstant, and KMeans fitting succeeds with exactly `n_bins[jj]` centers.

Reason: the public issue concerns the unordered-edge defect in this path, not
validation errors or KMeans infeasibility.

## PO-002: Sorting establishes center order

`np.sort(km.fit(...).cluster_centers_[:, 0])` returns the same center multiset
in nondecreasing coordinate order.

Reason: center order returned by KMeans is not specified as value order; the
code must explicitly impose the one-dimensional interval order.

## PO-003: Centers are inside the fitted feature range

For a successful one-dimensional KMeans fit on a feature with minimum `MIN` and
maximum `MAX`, every center `c` satisfies `MIN <= c <= MAX`.

Reason: endpoint monotonicity of `[MIN, midpoints..., MAX]` depends on this.

## PO-004: Sorted centers produce monotonic midpoint edges

Given sorted centers `c0 <= c1 <= ... <= c{k-1}` with all centers in
`[MIN, MAX]`, the edge vector

`[MIN, (c0+c1)/2, (c1+c2)/2, ..., (c{k-2}+c{k-1})/2, MAX]`

is nondecreasing.

Reason: `MIN <= c0 <= (c0+c1)/2`; for adjacent midpoints,
`(ci+c{i+1})/2 <= (c{i+1}+c{i+2})/2` follows from `ci <= c{i+2}`; and the last
midpoint is `<= c{k-1} <= MAX`.

## PO-005: Digitize receives monotonic bins

If `bin_edges_[jj]` is nondecreasing, then `bin_edges_[jj][1:]` is
nondecreasing. Therefore the monotonicity precondition of the modeled
`np.digitize` call is satisfied.

Reason: `transform` passes the suffix, not the full vector, to `np.digitize`.

## PO-006: Feature-loop invariant

After processing any prefix of features in `fit`, every processed k-means
feature in the audited domain has monotonic learned edges. Processing the next
k-means feature with V1 preserves this invariant by PO-002 through PO-005.

Reason: `fit` loops over features independently and stores each feature's edges
in `bin_edges[jj]`.

## PO-007: Frame and compatibility conditions

The V1 edit changes no public signature, no learned attribute name, and no
non-k-means branch. Existing validation and encoding behavior are framed.

Reason: the source edit is local to the k-means center-to-edge construction.
