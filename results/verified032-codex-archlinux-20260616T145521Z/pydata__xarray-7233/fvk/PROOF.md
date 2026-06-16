# Constructed Proof

Status: constructed, not machine-checked.

No tests, Python, `kompile`, `kast`, or `kprove` commands were run.

## Theorem

For every successful `Coarsen.construct` call in the audited domain, every
variable name that was a coordinate before the call is a coordinate in the
result.

Formally, if the input object is abstracted as `ds(VARS, COORDS)` with
`COORDS subsetSet VARS`, then:

```k
constructV2(ds(VARS, COORDS)) => ds(VARS, RCOORDS)
ensures COORDS subsetSet RCOORDS
```

## Proof sketch

1. The implementation validates `window_dim` and builds an empty `reshaped`
   dataset. These branches do not alter the coordinate-preservation theorem for
   successful calls.
2. The loop over `obj.variables.items()` processes every original variable key.
   In both branches, changed dimensions and unchanged dimensions, the same key
   is assigned into `reshaped`.
3. Therefore every original coordinate name remains present as a variable name
   in `reshaped`; this discharges PO1.
4. V1 sets `should_be_coords = set(self.obj.coords)`, i.e. all original
   coordinate names.
5. `Dataset.set_coords` asserts those names exist, copies the dataset, and
   updates `_coord_names` with those names.
6. Therefore every original coordinate name is in the result coordinate set;
   this discharges PO2 and proves the theorem.

## Pre-fix counterexample

For the public example shape:

- original variable names: `{T, day}`
- original coordinate names: `{day}`
- `window_dim` keys: `{time}`

The pre-fix expression computes:

```python
set(window_dim) & set(self.obj.coords) == {"time"} & {"day"} == set()
```

The reshape loop keeps `day` as a variable, but the final `set_coords` call
does not receive `day`. The result can therefore expose `day` as a data
variable. This is F1 and claim `PREFIX-COUNTEREXAMPLE`.

## DataArray path

`DataArray._to_temp_dataset` creates a temporary dataset whose coordinate names
are the real DataArray coordinate names, and whose data variable is
`_THIS_ARRAY`. Since V1 uses `set(self.obj.coords)`, `_THIS_ARRAY` is not part
of the set used to preserve coordinate membership. `_from_temp_dataset` still
pops `_THIS_ARRAY` and returns a DataArray. This discharges PO3.

## Machine-check commands

These commands are recorded for later machine checking only. They were not run.

```sh
kompile fvk/mini-xarray.k --backend haskell
kast --backend haskell fvk/coarsen-construct-spec.k
kprove fvk/coarsen-construct-spec.k
```

Expected result if run in an environment with the K toolchain: all claims
discharge to `#Top`. Until then, this proof remains constructed, not
machine-checked.

## Test-redundancy recommendation

No test deletion is recommended. The benchmark forbids modifying tests, and the
proof has not been machine-checked. Existing and hidden tests that check
coordinate preservation should be kept.

Useful tests for a normal development environment would cover:

- a Dataset with a non-dimension coordinate depending on a coarsened dimension;
- a Dataset with an existing dimension coordinate;
- a DataArray with coordinates through the shared `construct` path.
