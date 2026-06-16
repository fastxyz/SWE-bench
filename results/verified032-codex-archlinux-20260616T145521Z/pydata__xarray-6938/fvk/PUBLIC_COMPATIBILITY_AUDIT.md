# Public Compatibility Audit

Constructed, not machine-checked.

## Changed symbol

`xarray.core.dataset.Dataset.swap_dims`

## Signature and dispatch

- Signature unchanged: `swap_dims(self, dims_dict: Mapping[Any, Hashable] = None, **dims_kwargs)`.
- No new keyword arguments.
- No virtual dispatch call shape changed.
- `DataArray.swap_dims()` delegates through `Dataset.swap_dims()` and therefore observes the same public API.

## Return shape and behavior

- Return type family unchanged: a new `Dataset` is still returned by `Dataset.swap_dims()`, and `DataArray.swap_dims()` still reconstructs a `DataArray` from the temporary dataset.
- Existing validation behavior is unchanged.
- Returned dimension rewriting is unchanged.
- Metadata aliasing is reduced: the result no longer reuses an existing `IndexVariable` object before assigning `.dims`.

## Public callsites and overrides searched

Searched source references to `swap_dims(`, `def swap_dims`, and `to_index_variable()` under `repo/xarray`, `repo/doc`, and public tests. No subclass override or public caller requires the result variable object to be identical to the input variable object.

## Compatibility verdict

Pass. V1 changes only internal object ownership before a metadata mutation. It does not alter public API, accepted inputs, documented result shape, or documented errors.
