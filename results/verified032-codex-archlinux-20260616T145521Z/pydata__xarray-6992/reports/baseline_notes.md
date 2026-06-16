# Baseline Notes

## Root cause

`Dataset.reset_index(..., drop=True)` removes the requested index coordinate
variables from the dataset's `_variables` mapping, but it rebuilt
`_coord_names` by unconditionally unioning the old coordinate-name set with any
newly created index variables. For a dataset like:

```python
(
    xr.Dataset(coords={"a": ("x", [1, 2, 3]), "b": ("x", ["a", "b", "c"])})
    .set_index(z=["a", "b"])
    .reset_index("z", drop=True)
)
```

the multi-index array coordinate `z` is removed from `_variables`, while `z`
remains in `_coord_names`. That violates the internal expectation that
coordinate names identify variables present in the dataset. The stale name then
makes `DataVariables.__len__` compute `len(_variables) - len(_coord_names)` as a
negative number, which raises `ValueError: __len__() should return >= 0` during
repr and other data-variable mapping operations.

## Changed files

`repo/xarray/core/dataset.py`

- Updated `Dataset.reset_index` so the resulting `coord_names` set is filtered
  to names still present in the rebuilt `variables` mapping before adding any
  replacement index variables created while dropping only some levels of a
  multi-index.
- This keeps surviving level coordinates marked as coordinates, but removes
  coordinate names for variables actually deleted by `drop=True`.

## Assumptions and alternatives considered

- I assumed `_coord_names` should remain a subset of `_variables`, because other
  dataset and coordinate mapping code relies on that invariant for lengths,
  iteration, reprs, and item lookup.
- I considered changing `DataVariables.__len__` to count only variables not in
  `_coord_names`. That would avoid the negative length symptom, but it would
  leave stale coordinate names in the dataset and could still affect coordinate
  mapping behavior.
- I considered subtracting only `drop_variables` from `_coord_names`. Filtering
  against the rebuilt `variables` mapping is equivalent for the expected valid
  state, while also preventing any stale coordinate name from being propagated
  through this reset path.
