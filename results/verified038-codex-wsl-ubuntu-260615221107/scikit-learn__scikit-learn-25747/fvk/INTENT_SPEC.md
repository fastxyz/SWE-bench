# Intent Spec

Status: constructed from public issue text, public hints, existing source, and
V1 notes; not machine-checked.

## Required Behaviors

1. When pandas transform output is selected, `FeatureUnion` must not raise a
   length-mismatch error solely because a child or union result is an existing
   pandas `DataFrame` whose row count/index differs from the original input.

2. Existing pandas `DataFrame` output already has an index. The output wrapper
   must preserve that index instead of restoring the original input index.

3. The pandas output wrapper may still update column names for an existing
   `DataFrame` using `get_feature_names_out` when that information is available.

4. For non-DataFrame dense outputs, the wrapper creates a new pandas
   `DataFrame` and should still use the original input index. This preserves the
   ordinary same-row transformer behavior documented by the existing API.

5. Sparse output remains unsupported for pandas output and must continue to
   raise `ValueError`.

6. If output configuration is `"default"` or automatic wrapping is not
   configured, `_wrap_data_with_container` must return `data_to_wrap` unchanged.

## Domain Assumptions

- Pandas is available. The proof abstracts `check_pandas_support` as successful;
  import failure behavior is not part of this issue.
- `data_to_wrap` is either a pandas `DataFrame`, a dense non-DataFrame object
  accepted by the pandas `DataFrame` constructor, or sparse data rejected by the
  existing guard.
- Direct `Series` wrapping is not specified by the helper docstring, which names
  `{ndarray, dataframe}`. The issue's `Series` output reaches this helper through
  `FeatureUnion._hstack`, which first constructs a `DataFrame` via `pd.concat`.
