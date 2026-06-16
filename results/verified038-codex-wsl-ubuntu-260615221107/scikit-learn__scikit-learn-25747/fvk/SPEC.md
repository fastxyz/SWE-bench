# FVK Spec

Status: constructed, not machine-checked. K artifacts:
`fvk/mini-pandas-output.k` and `fvk/set-output-spec.k`.

## Scope

The audited units are:

- `repo/sklearn/utils/_set_output.py::_wrap_in_pandas_container`
- `repo/sklearn/utils/_set_output.py::_wrap_data_with_container`

These are the units on the public traceback path. `FeatureUnion._hstack` and
`ColumnTransformer._hstack` are audited as producer callsites because they return
pandas `DataFrame` objects that flow into `_wrap_in_pandas_container`.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations
are:

- E1/E2: remove the reported pandas-output length mismatch caused by assigning
  an original input index to an aggregated output `DataFrame`.
- E3/E4: an existing `DataFrame` already has an index; the wrapper must preserve
  it.
- E5: `set_output` column-name behavior must remain intact.
- E6: sparse pandas output remains unsupported.
- E7: the legacy helper test that overwrote an existing `DataFrame` index is
  suspect because it conflicts with the bug report and hint.

## Function Contracts

### `_wrap_in_pandas_container`

Preconditions and domain assumptions:

- Pandas support is available.
- `data_to_wrap` is sparse, an existing pandas `DataFrame`, or dense
  non-DataFrame data accepted by `pd.DataFrame`.
- `columns` is either `None`, a resolved column-name sequence, or a callable
  abstracted as either returning column names or raising.

Postconditions:

- Sparse input raises `ValueError`.
- Existing `DataFrame` input preserves its existing index for all values of the
  provided `index` argument.
- Existing `DataFrame` input updates columns only when resolved column names are
  available.
- Dense non-DataFrame input returns a newly constructed `DataFrame` using the
  provided `index` and resolved columns, with pandas defaults when columns are
  unavailable.

### `_wrap_data_with_container`

Preconditions and domain assumptions:

- Output configuration is either default or pandas.
- Auto wrapping is either enabled or disabled.

Postconditions:

- Default output or disabled auto wrapping returns `data_to_wrap` unchanged.
- Pandas output with auto wrapping delegates to `_wrap_in_pandas_container`,
  passing the original input index and estimator feature-name provider.
- In the FeatureUnion/ColumnTransformer aggregation case, the delegated helper
  preserves the concatenated output `DataFrame` index instead of assigning the
  original input index.

## Formal Claims

The claims in `fvk/set-output-spec.k` encode:

- DataFrame index preservation through `_wrap_data_with_container`.
- DataFrame column update without index replacement.
- Callable-column failure semantics for existing DataFrames.
- Non-DataFrame index application.
- Sparse error behavior.
- Default/disabled wrapping frame conditions.

There are no loops or recursive calls, so no circularity claims are required.
