# Baseline notes — pydata__xarray-6992

## Issue

`xr.core.dataset.DataVariables` assumes that everything in
`ds._variables` and not in `ds._coord_names` is a "data variable". Its
`__len__` therefore computes:

```python
def __len__(self) -> int:
    return len(self._dataset._variables) - len(self._dataset._coord_names)
```

This relies on the invariant that `_coord_names` is a **subset** of the keys of
`_variables`. Since the index refactor (#5692) a `Dataset` could end up with
*more* `_coord_names` than `_variables`, making this subtraction negative and
raising `ValueError: __len__() should return >= 0`, which in turn breaks the
repr and anything that iterates `data_vars`.

MVCE:

```python
ds = xr.Dataset(coords={"a": ("x", [1, 2, 3]), "b": ("x", ['a', 'b', 'c'])})
ds.set_index(z=['a', 'b']).reset_index("z", drop=True)
```

## Root cause

The bad state is *produced* by `Dataset.reset_index`
(`xarray/core/dataset.py`). The invariant `_coord_names ⊆ variables` is the
caller's responsibility, and `reset_index` violated it.

At the end of the method the new coordinate names were computed as:

```python
coord_names = set(new_variables) | self._coord_names
```

This keeps **every** old coordinate name, including the ones whose variables
were just removed via `drop_variables` (populated when `drop=True`). It never
subtracts the dropped names.

Tracing the MVCE:

1. `set_index(z=['a', 'b'])` builds a `PandasMultiIndex` on a new dimension
   `z` with level coordinates `a`, `b`. Result:
   `variables = {z, a, b}`, `coord_names = {z, a, b}`, dim `z`.
2. `reset_index("z", drop=True)`:
   - `drop_indexes = ['z', 'a', 'b']` (all coords of the index) → all index
     entries removed.
   - `z` is the dimension, so the multi-index "keep levels" special case is
     skipped and `new_variables = {}`.
   - `drop=True` → `drop_variables = ['z']`, so `variables = {a, b}`.
   - `coord_names = set({}) | {z, a, b} = {z, a, b}`.

   Result: `variables = {a, b}` (2) but `coord_names = {z, a, b}` (3). `z` is a
   coordinate name with **no** backing variable, so
   `len(data_vars) = 2 - 3 = -1` → `ValueError`.

Notably, the sibling method `Dataset.set_index` already gets this right
(`coord_names = self._coord_names - set(drop_variables) | set(new_variables)`),
confirming `reset_index` simply omitted the `- drop_variables` step.

## Change

`repo/xarray/core/dataset.py`, in `Dataset.reset_index`, replaced:

```python
coord_names = set(new_variables) | self._coord_names
```

with:

```python
# also drop any reset coordinate from the coordinate names so that
# ``coord_names`` stays a subset of ``variables`` (GH6992)
coord_names = (set(new_variables) | self._coord_names) - set(drop_variables)
```

This restores the invariant `coord_names ⊆ variables.keys()`:

- `variables.keys() = (self._variables - drop_variables) ∪ new_variables`
- `coord_names    = (self._coord_names ∪ new_variables) - drop_variables`

Because `self._coord_names ⊆ self._variables` and `new_variables` is always
added to `variables`, the result is always a subset, so `DataVariables.__len__`
can never go negative again.

`drop_variables` and the keys of `new_variables` are always disjoint
(`new_variables` only ever holds the *kept* multi-index levels, i.e. names
**not** in `dims_or_levels`, whereas `drop_variables` only holds names that
**are** in `dims_or_levels`), so subtracting `drop_variables` never demotes a
freshly-created coordinate.

Only the `drop=True` paths change behaviour. When `drop=False`,
`drop_variables` is empty, so the expression is byte-for-byte identical to the
old one and `reset_index(..., drop=False)` is completely unchanged.

No other source file needed changing. `DataArray.reset_index` delegates to the
`Dataset` implementation via a temporary dataset, so it is fixed transparently.

## Why fix the producer, not `DataVariables.__len__`

`_coord_names ⊆ variables` is a structural invariant of `Dataset` relied upon
across the codebase (iteration over `data_vars`, `to_dataframe`, `identical`'s
`_coord_names == other._coord_names` check, etc.), not just by `__len__`.
Clamping `__len__` (e.g. `max(0, ...)`) or counting via iteration would only
paper over the symptom while leaving an internally inconsistent `Dataset`
(a `coord_names` entry pointing at a non-existent variable) that would
misbehave elsewhere. Fixing the method that creates the inconsistency is the
correct, minimal root-cause fix.

## Behaviour after the fix (the MVCE)

`ds.set_index(z=['a', 'b']).reset_index("z", drop=True)` now returns a
consistent `Dataset` whose coordinates are `a` and `b` (the multi-index level
coordinates kept as plain, non-indexed coordinates) with no data variables and
no indexes — and the repr/`len(data_vars)` work. This matches the established
semantics already asserted by the existing tests, e.g.
`test_dataarray.py::test_reset_index`, where
`reset_index("x", drop=True)` on a multi-index drops only the dimension
coordinate `x` and keeps the level coordinates `level_1`, `level_2`.

## Assumptions / alternatives considered and rejected

- **Make `DataVariables.__len__`/`__iter__` robust instead.** Rejected — masks
  an invalid `Dataset` state rather than preventing it; the inconsistency would
  still break `assert_identical` (which compares `_coord_names`), `to_dataframe`,
  indexing, etc.
- **Also drop the multi-index level coordinates (`a`, `b`) when
  `drop=True` on the whole multi-index dimension.** Rejected — the existing
  `test_reset_index` (both Dataset and DataArray) asserts that
  `reset_index(<multiindex-dim>, drop=True)` keeps the level coordinates and
  only removes the dimension/multi-index coordinate itself. The minimal fix
  preserves that semantics.
- **Also convert the kept index variables to base `Variable`s when
  `drop=False`.** Considered but rejected as out of scope: it does not affect
  the reported bug, the existing tests pass without it (they compare by value
  via `assert_identical`, which does not distinguish `IndexVariable` from
  `Variable`), and it would be an unrelated behavioural change. Keeping the
  change to the single `coord_names` line keeps it minimal and targeted.
- **Recompute `dims` in the final `_replace`.** Not needed: in every realistic
  path at least one variable referencing the dimension survives (a level or the
  multi-index coordinate), so `self._dims` stays correct; the original code did
  not recompute dims either, so behaviour here is unchanged.
