# Public Compatibility Audit

Changed public symbols: none.

Audited symbol: `sklearn.linear_model.LogisticRegressionCV.fit`.

## Signature and Dispatch

- Constructor signature: unchanged.
- `fit(self, X, y, sample_weight=None)`: unchanged.
- No new keyword arguments are sent through virtual dispatch.
- No public return type changes: `fit` still returns `self`.
- No public parameter storage changes: `self.multi_class` and
  `self.l1_ratios` remain the constructor inputs.

## Attribute Compatibility

- `C_`: selection semantics preserved.
- `l1_ratio_`: non-elastic-net fits record `None`; elastic-net fits record the
  averaged selected ratio.
- `coefs_paths_`, `scores_`, `n_iter_`: V2 preserves elastic-net shape behavior
  and prevents ignored non-elastic-net `l1_ratios` from adding an l1 dimension.

Compatibility status: pass.
