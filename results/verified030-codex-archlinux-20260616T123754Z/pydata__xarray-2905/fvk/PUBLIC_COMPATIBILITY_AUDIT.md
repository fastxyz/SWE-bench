# Public Compatibility Audit

Status: source inspection only; no tests or code were run.

## Changed public symbols

No public function or method signature was changed. V1 edits only the internal
implementation of `xarray.core.variable.as_compatible_data` and its docstring.

## Public call paths inspected

| Path | Compatibility status |
| --- | --- |
| `Variable.__init__` -> `as_compatible_data` | Compatible. Arbitrary `.values` objects now remain scalar objects; existing `Variable`, supported array, datetime, timedelta, masked-array, and ndarray branches remain in place. |
| `Variable.data` setter -> `as_compatible_data` | Compatible. Shape validation still happens after helper conversion. |
| `Variable.__setitem__` -> `as_compatible_data` | Intended behavior change for arbitrary `.values` scalar objects; existing broadcasting/shape checks remain unchanged. |
| `Variable.copy(data=...)` -> `as_compatible_data` | Compatible. Shape validation remains unchanged. |
| `DataArray.__init__` -> `as_compatible_data` | Intended behavior change for arbitrary `.values` scalar objects. Existing `DataArray`, `Series`, `DataFrame`, `Panel`, and `Index` construction evidence remains covered. |
| `as_variable(..., name=...)` -> `as_compatible_data` | Compatible. Arbitrary `.values` objects are treated as scalar object data rather than self-described arrays. |

## Type-specific frame checks

- `xarray.Variable`: still handled before the explicit `.values` branch by
  `if isinstance(data, Variable): return data.data`.
- `pandas.Index`: still handled before the explicit `.values` branch through
  `NON_NUMPY_SUPPORTED_ARRAY_TYPES` and `_maybe_wrap_data`, preserving the
  repository's adapter behavior.
- `pandas.Series`, `pandas.DataFrame`, `pdcompat.Panel`, and `xarray.DataArray`:
  still intentionally unwrapped through `.values`.
- `PandasIndexAdapter`, `LazilyOuterIndexedArray`, dask/cupy arrays, and other
  supported non-NumPy arrays: still bypass generic NumPy coercion through the
  existing early branch.

## Overrides and virtual dispatch

No virtual method signature or keyword call was changed. No subclass override
updates are required.

## Result

No compatibility finding blocks keeping V1 unchanged.
