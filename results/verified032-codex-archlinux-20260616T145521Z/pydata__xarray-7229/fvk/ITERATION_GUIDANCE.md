# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No additional source edit is justified by the FVK findings. V1 discharges the
public obligations in `fvk/PROOF_OBLIGATIONS.md`:

- O1 preserves value semantics through the wrapper.
- O2 and O3 preserve attrs from `x` at the top level and per Dataset variable.
- O4 fixes the reported coordinate-attrs overwrite by using normal coordinate
  merge with `x` first, instead of a callable that returns data attrs.
- O5 preserves the scalar-`x` behavior called out in the public hints.
- O6 and O7 preserve public API compatibility and non-true `keep_attrs` behavior.

## Recommended Follow-Up Tests

Do not edit tests in this task. A future test patch should add or keep tests for:

- `xr.where(True, da, da, keep_attrs=True)` preserving coordinate attrs.
- `xr.where(cond_da, da, da, keep_attrs=True)` preserving coordinate attrs from
  `x` when all inputs are labeled.
- `xr.where(cond, 1, da, keep_attrs=True)` producing empty result attrs.
- `xr.where(cond, ds_x, ds_y, keep_attrs=True)` preserving both `ds_x.attrs` and
  `ds_x[var].attrs`.

## Machine-Check Follow-Up

The proof is constructed, not machine-checked. When a K environment exists, run:

```sh
kompile fvk/mini-xarray.k --backend haskell
kast --backend haskell fvk/xarray-where-spec.k
kprove fvk/xarray-where-spec.k
```

Until then, do not remove tests based on the proof.
