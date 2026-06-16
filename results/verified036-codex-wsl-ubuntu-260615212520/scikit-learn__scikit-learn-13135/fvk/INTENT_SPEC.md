# Intent Spec

Status: constructed from public issue text, local source, local docs/tests, and
baseline notes. Current implementation behavior is treated as a candidate to
check, not as the specification.

## Required behavior

1. For `KBinsDiscretizer(strategy='kmeans')`, fitting and transforming finite
   numeric data in the supported domain must not fail because learned
   `bin_edges_` are unordered.

2. The learned k-means bin edges for each nonconstant feature must be monotonic
   in feature-value order before `transform` passes them to `np.digitize`.

3. The k-means strategy defines intervals by nearest one-dimensional cluster
   center. Therefore midpoint boundaries must be computed between neighboring
   centers in numeric order, not in the arbitrary order returned by the KMeans
   estimator.

4. The fix must preserve the public estimator API: constructor parameters,
   learned attribute names, `fit`, `transform`, and `inverse_transform` shapes
   are unchanged.

5. Existing behavior for `uniform`, `quantile`, constant features, validation
   errors, and encoding choices is outside the bug mechanism and should remain
   unchanged.

## Domain fixed by intent

The audited domain is the `strategy='kmeans'` path for finite numeric two-
dimensional input accepted by `check_array`, valid `n_bins >= 2`, nonconstant
features, and KMeans fits that return one center per requested bin. KMeans
configuration or data choices that make KMeans itself fail are not part of the
reported unordered-edge defect.

## Observed candidate behavior to check

The V1 patch sorts `km.fit(...).cluster_centers_[:, 0]` before midpoint edge
construction. The audit checks whether this is sufficient to make learned edges
monotonic and whether it changes any public API or unrelated strategy.
