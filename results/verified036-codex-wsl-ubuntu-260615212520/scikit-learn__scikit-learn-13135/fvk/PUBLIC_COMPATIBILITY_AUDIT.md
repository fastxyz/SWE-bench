# Public Compatibility Audit

Changed public symbols: none.

Changed implementation point:

- `repo/sklearn/preprocessing/_discretization.py`
- Method: `KBinsDiscretizer.fit`
- Branch: `strategy == 'kmeans'`
- Statement changed: the fitted one-dimensional cluster center vector is sorted
  before midpoint edge construction.

Compatibility results:

| Surface | Status | Reason |
| --- | --- | --- |
| Constructor signature | Compatible | `__init__(n_bins, encode, strategy)` is unchanged. |
| `fit` signature and return | Compatible | Signature is unchanged and still returns `self`. |
| Learned attributes | Compatible | `bin_edges_`, `n_bins_`, and `_encoder` are still populated by the same paths. |
| `transform` signature and return shape | Compatible | No change. It now receives monotonic k-means edges in the audited case. |
| `inverse_transform` behavior | Compatible | It consumes the same learned edge representation; V1 only makes k-means edges value-ordered. |
| Other strategies | Compatible | `uniform`, `quantile`, constant-feature, validation, and encoding branches are untouched. |
| Subclass/override dispatch | Compatible | No new virtual method, keyword, or method signature was added. |

No compatibility finding requires a source change beyond V1.
