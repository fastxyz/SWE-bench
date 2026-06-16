# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public or Semi-Public Symbol

- Symbol: `sklearn.utils._set_output._wrap_in_pandas_container`
- Change: existing pandas `DataFrame` output no longer has its index overwritten
  by the `index` argument; columns may still be overwritten.
- Signature change: none.
- Return-type change: none; still returns a pandas `DataFrame` for dense output.
- Error-shape change: sparse `ValueError` unchanged.

## Public Callers and Producers

- `_wrap_data_with_container` passes `original_input.index` to
  `_wrap_in_pandas_container`. This call remains compatible. The changed helper
  decides not to use that index only when `data_to_wrap` is already a
  `DataFrame`.
- `_wrap_method_output` remains unchanged. Tuple handling for cross decomposition
  still wraps only the first output.
- `FeatureUnion._hstack` returns `pd.concat(Xs, axis=1)` for pandas outputs. That
  DataFrame now retains its concatenated index after the final auto-wrap step.
- `ColumnTransformer._hstack` also returns a concatenated `DataFrame` in pandas
  mode. The same preservation applies and matches the issue comment that
  ColumnTransformer has the same problem.

## Existing Tests

- Tests asserting ordinary same-row pandas output indexes for `FeatureUnion` and
  `ColumnTransformer` remain compatible because their child transformers produce
  arrays that are wrapped into DataFrames with the original input index before
  concatenation.
- The direct helper test expecting a DataFrame index override is suspect legacy
  evidence under the FVK rules because it asserts the behavior the issue
  identifies as too restrictive. It should be updated by maintainers, but this
  task forbids modifying tests.

Compatibility conclusion: no public signature or dispatch compatibility problem
was found. V1 is source-compatible while intentionally changing the legacy index
override behavior for existing `DataFrame` outputs.
