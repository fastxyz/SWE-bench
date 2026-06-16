# FVK Findings

Status: constructed, not machine-checked.

## F-001: Unordered KMeans centers can produce nonmonotonic edges

- Classification: code bug, resolved by V1.
- Evidence: E-001, E-002, E-003.
- Input: the public reproducer uses
  `X = [0, 0.5, 2, 3, 9, 10]`, `n_bins=5`, `strategy='kmeans'`,
  `encode='ordinal'`.
- Observed before V1: `transform` can raise `ValueError` because the learned
  bins are not monotonic.
- Expected: no error caused by unordered k-means edges.
- V1 status: sorting centers before midpoint construction addresses the cause.
- Proof obligations: PO-001 through PO-006.

## F-002: Returned KMeans center order is not interval order

- Classification: specification mismatch in the legacy implementation, resolved
  by V1.
- Evidence: E-004 and E-006.
- Input class: any one-dimensional k-means fit where center coordinates are
  returned out of numeric order.
- Observed before V1: adjacent midpoint edges were computed from returned
  cluster-index order.
- Expected: midpoint edges are computed from neighboring centers in numeric
  order.
- V1 status: `np.sort` establishes the required interval order.
- Proof obligations: PO-002 and PO-004.

## F-003: Edge monotonicity proof depends on centers lying in the feature range

- Classification: named proof side condition, not a new code bug.
- Evidence: E-008.
- Input class: successful one-dimensional KMeans fits in the audited domain.
- Required fact: each produced center lies between `col_min` and `col_max`.
- Reason: the proof of endpoint monotonicity uses
  `col_min <= first_center` and `last_center <= col_max`.
- V1 status: no source edit needed; this is a k-means/domain fact.
- Proof obligations: PO-003 and PO-004.

## F-004: Digitize consumes the edge suffix, not the full learned edge vector

- Classification: proof-derived check, resolved by V1.
- Evidence: E-005.
- Input class: any learned nondecreasing edge vector.
- Observed before audit: the baseline note discussed full `bin_edges_`.
- Expected: verify that `bin_edges_[1:]` is also monotonic because that is the
  array passed to `np.digitize`.
- V1 status: suffixes of nondecreasing lists are nondecreasing.
- Proof obligations: PO-005.

## F-005: No compatibility or unrelated-branch regression found

- Classification: compatibility confirmation.
- Evidence: E-007 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input class: public API calls and non-k-means branches.
- Observed after audit: V1 changes only center ordering in the k-means fit
  branch.
- Expected: public signatures, learned attributes, and unrelated strategies stay
  unchanged.
- V1 status: confirmed; no additional code edit recommended.
- Proof obligations: PO-006 and PO-007.

## Proof-derived findings from verify

No proof-derived code bug was found after adding the explicit side conditions in
PO-003 and PO-005. The proof remains constructed, not machine-checked, so tests
must not be removed on the strength of this FVK run alone.
