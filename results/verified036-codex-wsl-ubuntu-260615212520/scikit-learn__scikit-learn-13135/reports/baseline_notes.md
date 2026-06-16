# Baseline Notes

## Root cause

`KBinsDiscretizer` derives bin edges for `strategy='kmeans'` from adjacent
KMeans cluster centers. The KMeans estimator does not guarantee that
`cluster_centers_` are returned sorted by their coordinate value. When centers
come back out of order, the midpoint array used as `bin_edges_` can also be out
of order. `transform` later passes these edges to `np.digitize`, which requires
monotonic bins and raises `ValueError` for unsorted edges.

## Files changed

`repo/sklearn/preprocessing/_discretization.py`

Sorted the one-dimensional KMeans centers before computing adjacent midpoint
edges. In one-dimensional discretization, intervals are ordered by the center
locations, so sorting the centers preserves the intended k-means partition while
ensuring the resulting bin edges are monotonic for `np.digitize`.

`reports/baseline_notes.md`

Added these notes as required by the task.

## Assumptions and alternatives considered

I assumed the issue is specific to the k-means edge construction path, because
`uniform` creates ordered edges with `np.linspace` and `quantile` creates ordered
edges from percentiles.

I considered sorting the final `bin_edges_` array instead of sorting centers.
Sorting centers is the narrower fix: midpoint boundaries are meaningful only
between neighboring centers in value order, while sorting edges after midpoint
construction would hide the fact that the wrong center pairs had been averaged.

I also considered changing `transform` to sort the bins before calling
`np.digitize`, but that would mutate or reinterpret learned model state during
transformation and would not address non-monotonic `bin_edges_` stored after
`fit`.

No tests or project code were run, per the task instructions.
