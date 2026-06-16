# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt issue | "fails ... due to centers and consequently bin_edges being unsorted" | The defect is unordered k-means centers producing unordered edges. | Encoded in SPEC and K claims. |
| E-002 | prompt issue | "fatal for np.digitize" and traceback says bins must be monotonic | `transform` requires monotonic learned edges before calling `np.digitize`. | Encoded as digitize-safety obligation. |
| E-003 | prompt issue | Reproducer uses `n_bins=5` on `[0, 0.5, 2, 3, 9, 10]` and expected "No error is thrown" | In-domain k-means discretization must not raise solely because learned edges are unordered. | Resolved by V1 under proof obligations. |
| E-004 | local docstring | k-means strategy: "same nearest center of a 1D k-means cluster" | Boundaries must be between neighboring centers in one-dimensional value order. | Supports sorting centers before midpoint construction. |
| E-005 | local source | `transform` calls `np.digitize(..., bin_edges[jj][1:])` | The learned edge suffix consumed by transform must be monotonic. | Encoded as suffix/digitize proof obligation. |
| E-006 | local KMeans doc/source | `cluster_centers_` are coordinates of cluster centers; local example shows center order is not sorted by coordinate | KMeans center order is not a valid interval order by itself. | Supports rejecting "use returned order" as a spec. |
| E-007 | local source | The V1 edit only changes the k-means center vector before edge midpoint construction | No public API, validation branch, or unrelated strategy is intentionally changed. | Encoded in compatibility audit. |
| E-008 | implementation fact | KMeans centers are produced by k-means updates from data points and are center coordinates | For the edge proof, centers are assumed within the feature min/max range when KMeans succeeds. | Encoded as proof side condition PO-003. |
