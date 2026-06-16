# Baseline Notes

## Root cause

`IndexVariable` stores coordinate index data in a `PandasIndexAdapter`. The
adapter keeps two pieces of state: the underlying `pandas.Index` and an explicit
NumPy dtype used when exposing the index values through xarray. For fixed-width
unicode coordinates, pandas may represent the corresponding `Index` with object
dtype, while the adapter still preserves the original NumPy unicode dtype such
as `<U3`.

`IndexVariable.copy(deep=True)` deep-copied the underlying pandas index and then
created a new `PandasIndexAdapter` without passing along the old adapter dtype.
The new adapter inferred its dtype from the copied pandas index, so unicode
dimension coordinates were exposed as object dtype after deep copy. This affected
`Dataset.copy(deep=True)`, default `DataArray.copy()`/`DataArray.copy(deep=True)`,
and `copy.deepcopy()` through the same variable copy path. In this checkout,
`copy.copy()` routes through `deep=False`, so it keeps the original adapter and
does not take the buggy deep-copy branch.

## Changed files

`repo/xarray/core/variable.py`

Preserved `self._data.dtype` when `IndexVariable.copy(deep=True)` builds a new
`PandasIndexAdapter` around the copied pandas index. This keeps the existing
deep-copy behavior for pandas indexes while retaining xarray's dtype metadata
for fixed-width unicode index coordinates.

`reports/baseline_notes.md`

Added this report with the root cause, changed files, assumptions, and rejected
alternatives.

## Assumptions

The intended behavior is that copying an xarray object must not change the dtype
xarray reports for any copied variable. The copied pandas index can still be a
separate object for deep-copy semantics; only the adapter dtype metadata needs to
be carried forward.

I also assumed that the fix should live at the `IndexVariable` layer because the
issue is specific to index-coordinate wrapping. Plain `Variable` copies already
copy NumPy-backed unicode arrays without converting them to object dtype.

## Alternatives considered and rejected

One option was to ignore `deep=True` for `IndexVariable` and reuse the existing
`PandasIndexAdapter`, matching the method documentation that pandas indexes are
immutable. I rejected that because the current implementation intentionally
creates a copied pandas index for deep copies, and preserving that behavior is a
smaller behavioral change.

Another option was to change `PandasIndexAdapter` dtype inference or
`safe_cast_to_index`. I rejected that because the regression occurs only when a
copy path reconstructs an adapter without the original dtype; changing adapter
construction globally would affect many unrelated index creation paths.

No tests or project code were run, per the task constraints.
