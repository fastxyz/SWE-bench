# Formal Spec In English

Status: constructed, not machine-checked.

## Claim `SELECTOR-DEFAULT-ARRAY`

For any selector input `X`, support mask `M`, and estimator whose dense transform output is configured as `default` or whose auto wrapping is disabled, `transform(X)` validates `X` and returns the validated data selected by `M`. If `X` is a pandas `DataFrame`, default output still does not return pandas merely because the input was pandas.

## Claim `SELECTOR-PANDAS-PRESERVE`

For any valid pandas `DataFrame` input `X`, support mask `M`, and estimator whose transform output is configured as pandas with auto wrapping enabled, `transform(X)` validates `X` first and then returns the selected columns from the original `DataFrame` `X`, not from the homogeneous validated array. The result preserves the selected original columns' values, index, column labels before final wrapper adjustment, and dtype metadata.

## Claim `SELECTOR-EMPTY-PANDAS`

If the selector support mask contains no selected features and pandas output is configured for a pandas `DataFrame`, `transform(X)` emits the existing "No features were selected" warning and returns a zero-column `DataFrame` with the input index and no dtype-carrying columns.

## Claim `SELECTOR-EMPTY-ARRAY`

If the selector support mask contains no selected features and the transform path is not the pandas-preserving DataFrame path, `transform(X)` keeps the existing behavior: it emits the existing warning and returns an empty array of shape `(n_samples, 0)` with the validated array dtype.

## Claim `WRAPPER-FRAME`

After `SelectorMixin.transform` returns, the existing `set_output` wrapper still controls final pandas column names and index through `_wrap_data_with_container`. If the selector returned a `DataFrame`, `_wrap_in_pandas_container` mutates only columns and index, not values or dtypes.

## Claim `INVALID-CONFIG-ORDER`

An invalid output configuration is not used to decide the selector's raw transform result. The helper treats invalid config as "not pandas-preserving" inside raw `transform`, so validation and raw transform errors keep their existing precedence; the existing wrapper remains the normal place where invalid output config is reported when transform otherwise succeeds.

## Non-Claim: Generic Transformer Dtype Preservation

No claim is made that transformers which compute new values preserve heterogeneous pandas dtypes. That behavior is intentionally outside this spec.
