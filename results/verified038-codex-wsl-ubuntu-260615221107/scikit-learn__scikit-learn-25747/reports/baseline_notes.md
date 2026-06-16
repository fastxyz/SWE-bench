# Baseline Notes

## Root cause

`FeatureUnion.fit_transform` is automatically wrapped by the `set_output`
machinery when pandas output is selected. In the failing case, the union first
concatenates the child transformer output into a pandas `DataFrame` whose index
reflects the aggregation result. The generic pandas wrapper then treated that
existing `DataFrame` like a container needing a restored input index, and tried
to assign the original, longer input index to it. That raised pandas' length
mismatch error when the transformer reduced the number of rows.

The problematic behavior was in `_wrap_in_pandas_container`: it changed both
columns and index in place for an existing `DataFrame`. For existing pandas
output, the index is already defined by the transformer or meta-estimator result,
so replacing it with the original input index is too restrictive.

## Files changed

- `repo/sklearn/utils/_set_output.py`: updated `_wrap_in_pandas_container` so an
  existing pandas `DataFrame` keeps its own index while still allowing the
  wrapper to set output column names. New `DataFrame` objects created from
  non-DataFrame output still receive the provided index.

## Assumptions

- The intended relaxation is limited to existing pandas `DataFrame` output. This
  keeps the normal same-row transformer behavior for array-like outputs, where
  the wrapper creates a new `DataFrame` and can safely apply the original input
  index.
- Column-name wrapping remains desirable for existing `DataFrame` output because
  `set_output` uses `get_feature_names_out` to provide consistent feature names.

## Alternatives considered

- Adding special handling in `FeatureUnion._hstack` or `ColumnTransformer._hstack`
  was rejected because both paths already produce the correct pandas index before
  the generic wrapper runs. The issue is shared wrapper behavior, not the
  concatenation logic.
- Skipping all wrapping for existing `DataFrame` output was rejected because it
  would also skip the established column-name handling from
  `get_feature_names_out`.
