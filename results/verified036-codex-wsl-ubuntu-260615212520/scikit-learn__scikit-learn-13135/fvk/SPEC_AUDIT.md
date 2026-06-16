# Spec Audit

Status: pass for the audited issue. The formal English matches the public
intent for the unordered-edge defect. No formal claim relies solely on the
legacy unordered center order.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| KMEANS-SORT-CENTERS | Intent items 2 and 3 | Pass | Sorting is required because the public issue identifies unordered centers as the cause and one-dimensional bins are ordered by value. |
| KMEANS-EDGES-MONOTONE | Intent items 1, 2, and 3 | Pass | Midpoints between neighboring sorted centers are the needed interval boundaries. |
| DIGITIZE-SAFE-SUFFIX | Intent items 1 and 2 | Pass | The traceback identifies `np.digitize` monotonicity as the failing consumer of `bin_edges_`. |
| FEATURE-LOOP-FRAME | Intent items 4 and 5 | Pass | V1 changes no public API and no unrelated strategy branch. |
| KMeans center in-range side condition | Domain fixed by intent | Pass with named side condition | This is a k-means algorithm/domain fact, not a new public API precondition. |

No fail or ambiguous adequacy item blocks keeping V1 unchanged.
