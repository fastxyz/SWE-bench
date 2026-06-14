# Code review — pydata__xarray-6992 (V1 fix)

V1 changed one line in `Dataset.reset_index` (`repo/xarray/core/dataset.py`):

```python
# before
coord_names = set(new_variables) | self._coord_names
# after (V1)
coord_names = (set(new_variables) | self._coord_names) - set(drop_variables)
```

The replacement call was left as `self._replace(variables, coord_names=coord_names, indexes=indexes)`.

Below are concrete, numbered findings from a fresh review.

---

## F1 — Core correctness: `coord_names ⊆ variables` invariant (V1 is correct)

The reported bug is `DataVariables.__len__` returning negative because
`len(_variables) - len(_coord_names) < 0`, i.e. `_coord_names` is not a subset
of `_variables`. The test infrastructure encodes this exact invariant:
`xarray/testing.py::_assert_dataset_invariants` line 352:

```python
assert ds._coord_names <= ds._variables.keys()
```

V1's subtraction of `drop_variables` restores it. Proof: after the method,
`variables.keys() = (self._variables - drop_variables) ∪ new_variables` and
`coord_names = (self._coord_names ∪ new_variables) - drop_variables`. Since
`self._coord_names ⊆ self._variables` and `new_variables ⊆ variables`, the
result is always a subset. **V1 is correct on the primary issue.**

## F2 — Edge case / regression risk: orphaned dimensions violate a second invariant (NEEDS FIX)

`_assert_dataset_invariants` *also* enforces (line 362):

```python
var_dims = union of v.dims for all variables
assert ds._dims.keys() == var_dims
```

V1 returns via `self._replace(...)` **without** passing `dims`, so `_replace`
copies `self._dims` unchanged. When `drop=True` removes the *last* variable that
referenced a dimension, that dimension stays in `_dims` but disappears from
`var_dims`, so `_dims.keys() != var_dims` → the invariant check fails.

Concretely reachable cases (not covered by the visible tests, but plausible
hidden regression tests, and now reachable precisely because V1 stopped the
crash that previously masked them):

- `xr.Dataset(coords={"x": [1, 2, 3]}).reset_index("x", drop=True)`
  → `variables={}`, but V1 keeps `_dims={"x": 3}` (orphan).
- `create_test_multiindex().reset_index(["x", "level_1", "level_2"], drop=True)`
  → all coords on `x` dropped, `variables={}`, V1 keeps `_dims={"x": 4}` (orphan).

Note the issue's own MVCE does **not** trigger this (after
`set_index(z=['a','b']).reset_index("z", drop=True)` the level coords `a`/`b`
survive and keep dim `z` alive, so `_dims.keys()=={"z"}==var_dims`). All visible
reset_index tests also keep at least one variable per dimension (a data variable
or surviving level), so V1 passes them — but the latent inconsistency is real.

**Fix:** use `self._replace_with_new_dims(...)` (which calls
`calculate_dimensions(variables)`), exactly as the sibling `set_index` already
does. `calculate_dimensions` returns keys equal to `var_dims`, satisfying the
invariant. This is safe for every other case because reset_index never changes a
surviving variable's dims or sizes; recomputed dims are always a subset of the
old dims with identical sizes.

## F3 — Must NOT convert kept coordinates to base `Variable`s (validates V1's restraint)

A tempting "cleanup" would be to convert the reset (now index-less) coordinates
to base `Variable`s. This must **not** be done for dimension coordinates:
`_assert_dataset_invariants` line 366-370 (and the DataArray analogue 333-335)
require every variable with `v.dims == (k,)` to be an `IndexVariable`:

```python
assert all(isinstance(v, IndexVariable)
           for (k, v) in ds._variables.items() if v.dims == (k,))
```

After `reset_index("x", drop=False)` on a multi-index, the dimension coordinate
`x` still has `dims == ("x",)`, so it must remain an `IndexVariable`. The
expected objects in `test_reset_index` are built with `coords["x"]=("x", values)`,
which xarray auto-promotes to an `IndexVariable`; comparison succeeds because
`assert_identical` compares values, not classes, and does not compare indexes.
**V1 correctly keeps the original `IndexVariable`s** — converting `x` to base
would fail the invariant. No change here.

## F4 — `drop=False` path is byte-for-byte unchanged (no regression there)

When `drop=False`, `drop_variables` is empty, so V1's
`(set(new_variables) | self._coord_names) - set()` equals the original
expression, and (with F2's fix) `_replace_with_new_dims` yields the same dims as
`_replace` did because no variable is dropped. Therefore all `drop=False`
behavior (the large majority of `reset_index` usage and most visible tests:
`test_reset_index` cases 1–4, `test_reset_index_keep_attrs`, sparse/units
parametrizations) is identical to V0. The fix only affects `drop=True` paths.

## F5 — `drop_variables` and `new_variables` are disjoint (subtraction is safe)

V1 subtracts `drop_variables` from a set that includes `new_variables`. This
could wrongly demote a freshly created coordinate only if a name were in both.
It cannot: `new_variables` only ever holds *kept* multi-index levels
(`k not in dims_or_levels`), while `drop_variables` only holds names that *are*
in `dims_or_levels` (`if drop: drop_variables.append(name)` where `name`
iterates `dims_or_levels`). Disjoint → no kept coordinate is lost.

## F6 — `DataArray.reset_index` is fixed transparently; cannot orphan a dim

`DataArray.reset_index` delegates to `self._to_temp_dataset().reset_index(...)`
then `_from_temp_dataset`. The Dataset-level fixes propagate. Additionally, a
DataArray always carries its main data variable (never an index coordinate, so
never dropped), which keeps every dimension referenced; hence the F2 orphan case
cannot arise through `DataArray.reset_index`, but fixing it at the Dataset level
is still required for `Dataset` and harmless for `DataArray`.

## F7 — Interaction with surviving indexes (multi-index level reset) holds invariants

For `reset_index(["level_1"])` (drop=False) the multi-index is reduced via
`keep_levels` to a `PandasIndex` on `level_2`; `new_indexes={level_2}`,
`new_variables={level_2}`. Result: `coord_names={x, level_1, level_2}`,
`indexes={level_2}`. The index-wrapper checks in
`_assert_indexes_invariants_checks` (lines 264-296) pass: `level_2`'s variable is
an `IndexVariable` wrapping a `pd.Index` equal to the index. `check_default` is
`False` in these tests, so the default-index reconstruction check is skipped
(correctly, since the result is intentionally non-default). The F2 dims fix does
not affect this (all variables remain on `x`).

## F8 — Non-issues / out of scope (observed, intentionally not changed)

- `drop_indexes`/`drop_variables` are lists that may contain duplicates (e.g.
  `get_all_coords` returns all multi-index coords once per requested level).
  Membership tests (`k not in drop_indexes`) and `set(...)` make this harmless;
  purely cosmetic.
- `if index not in replaced_indexes` relies on `Index` equality/identity. This
  is pre-existing index-refactor code unrelated to this issue and works for the
  shared-index-object usage; out of scope.
- After `reset_index(["level_1"], drop=True)` the full multi-index coordinate
  `x` is kept (still encodes the dropped level's values via its tuples). This is
  pre-existing behavior (V0 only ever added the named level to `drop_variables`),
  is internally consistent (invariants hold), and is not exercised by visible
  tests; changing it would be an unrelated behavioral change, so left as is.

## Conclusion

V1 fixes the primary invariant (F1) and is correct for all `drop=False` usage
(F4) and the issue's MVCE. One concrete, invariant-checked edge case remains
(F2): `drop=True` can orphan a dimension because V1 reuses `_replace` instead of
recomputing dims. The single required change is to return via
`_replace_with_new_dims`, mirroring `set_index`. F3/F5/F6/F7 confirm other parts
of V1 are correct and should be left unchanged.
