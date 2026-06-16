# Proof Obligations

Status: constructed, not machine-checked.

## PO-VALIDATE-FIRST

`SelectorMixin.transform` must call `_validate_data` before selecting from either the validated array or the original pandas `DataFrame`.

Status: discharged by code inspection. V2 stores `X_original` before validation, but does not pass it to `_transform` until after `_validate_data` returns.

## PO-DF-DTYPE-PRESERVE

When input is a pandas `DataFrame`, output config is pandas, auto wrapping is configured, validation succeeds, and support mask selects columns, the transform result before wrapper adjustment must be a selected-column slice of the original `DataFrame`.

Status: discharged by code inspection. V2 sets `X = X_original` only under `_is_pandas_output_configured(self)`, then `_transform` uses `_safe_indexing(X, safe_mask(X, mask), axis=1)`.

## PO-DEFAULT-UNCHANGED

When pandas output is not configured, selectors must not return a pandas `DataFrame` merely because the input was pandas.

Status: discharged. `_is_pandas_output_configured` must be true before `X_original` is used; otherwise `_transform` receives the validated data.

## PO-ARRAY-SPARSE-UNCHANGED

For dense arrays and sparse matrices, selected-column behavior must remain equivalent to the old `X[:, safe_mask(X, mask)]` behavior.

Status: discharged by equivalence of `_safe_indexing(X, safe_mask(X, mask), axis=1)` to column slicing for array-like and sparse inputs under the audited helper implementation.

## PO-EMPTY-PANDAS

For pandas input on the pandas-preserving path with no selected features, the result must be a zero-column DataFrame rather than attempting to access `X.dtype`.

Status: discharged. `_transform` checks `hasattr(X, "iloc")` in the empty-mask branch and returns `_safe_indexing(X, safe_mask(X, mask), axis=1)`.

## PO-EMPTY-ARRAY

For non-pandas empty selections, preserve the existing empty array result with shape `(n_samples, 0)` and dtype `X.dtype`.

Status: discharged. The existing `np.empty(0, dtype=X.dtype).reshape((X.shape[0], 0))` branch remains for non-DataFrame inputs.

## PO-WRAPPER-FRAME

The set-output wrapper may adjust DataFrame columns and index, but must not cast or recompute DataFrame values/dtypes.

Status: discharged by static source: `_wrap_in_pandas_container` mutates `columns` and `index` for existing `pd.DataFrame` input and returns it.

## PO-INVALID-CONFIG-ORDER

Invalid output config must not be used to route raw selector transform into the pandas-preserving branch before validation/raw transform can run.

Status: discharged by V2. `_is_pandas_output_configured` catches `ValueError` from `_get_output_config` and returns `False`; the existing wrapper still reports invalid config if transform reaches wrapping.

## PO-SCOPE-LIMIT

The fix must not claim or implement heterogeneous dtype preservation for transformers that compute new values.

Status: discharged. Only `SelectorMixin` changed; `_SetOutputMixin` and generic wrapper code are unchanged.

## PO-PUBLIC-COMPAT

No public method signature, public `set_output` value, or subclass override contract may change.

Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.
