# Baseline Notes

## Root cause

`SelectorMixin.transform` validates pandas input with `_validate_data`, which converts a mixed-dtype `DataFrame` to a homogeneous array before selecting columns. The generic `set_output(transform="pandas")` wrapper then builds a new `DataFrame` from that already-converted array, so selectors such as `SelectKBest` preserve feature names and index but cannot preserve per-column pandas dtypes.

## Files changed

`repo/sklearn/feature_selection/_base.py`

- Imported `_safe_indexing` so selector output can be sliced from either arrays, sparse matrices, or pandas dataframes through the same indexing helper used elsewhere in scikit-learn.
- Imported `_get_output_config` and `_auto_wrap_is_configured` to detect the existing pandas output configuration without adding a new public option.
- Updated `SelectorMixin.transform` to keep a reference to the original pandas `DataFrame` only when pandas output wrapping is configured. Validation still runs on the input first, preserving the existing checks for finiteness, feature names, and number of features.
- Updated `_transform` to use `_safe_indexing` for selected columns and to return an empty pandas `DataFrame` for empty selections when the input being sliced is pandas. This lets feature selectors pass through the original selected columns, preserving their dtypes, while default NumPy and sparse behavior remains unchanged.

## Assumptions and alternatives

I assumed the intended short-term fix is limited to selectors whose transform result is exactly a subset of the input columns. That matches the public discussion in the issue and avoids applying dtype preservation to transformers that compute new values.

I considered changing the generic `set_output` wrapper to accept or infer original dtypes and cast the output `DataFrame` back. I rejected that because it can silently lose information after numeric conversions and would affect transformers that do not merely pass through input columns.

I also considered changing only `SelectKBest`, but the shared bug is in `SelectorMixin`: `SelectPercentile`, `SelectFromModel`, `RFE`, `SequentialFeatureSelector`, and `VarianceThreshold` all perform the same selected-column pass-through and can safely benefit from the same targeted behavior.
