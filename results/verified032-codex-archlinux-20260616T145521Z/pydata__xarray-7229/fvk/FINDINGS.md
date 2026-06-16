# FVK Findings

Status: constructed; not machine-checked. Findings are based on public intent
and source inspection only.

## Resolved Findings

### F1: Callable attrs strategy was applied at the wrong semantic level

- Input: `xr.where(True, ds.air, ds.air, keep_attrs=True).time.attrs`
- V0 observed behavior: `time.attrs` became attrs from the data variable
  `ds.air`.
- Expected behavior: `time.attrs` remains coordinate attrs, e.g.
  `{'standard_name': 'time', 'long_name': 'Time'}` from the issue.
- Cause: the old callable returned `getattr(x, "attrs", {})` for every
  `merge_attrs` call, including coordinate merging in
  `build_output_coords_and_indexes`.
- V1 status: resolved. The keep-attrs branch now calls `apply_ufunc` with `x`
  first and `keep_attrs=True`, so normal `"override"` coordinate merging sees
  coordinate attrs, not data attrs.
- Related proof obligations: O2, O4.

### F2: The historical `attrs[1]` strategy is not valid for scalar `x`

- Input: `xr.where(cond, 1, y, keep_attrs=True)` where `y` is labeled and has
  attrs.
- Risk: selecting `attrs[1]` from the filtered attrs list would copy attrs from
  `y`, because scalar `x` contributes no attrs entry.
- Expected behavior: scalar `x` contributes `{}`.
- V1 status: resolved. V1 snapshots `getattr(x, "attrs", {})`, and after
  `apply_ufunc` normalizes result attrs/data-var attrs from that snapshot.
- Related proof obligations: O3, O5.

### F3: Dataset variable attrs need per-variable handling

- Input: `xr.where(cond, ds_x, ds_y, keep_attrs=True)` where `ds_x.attrs` and
  `ds_x[var].attrs` differ.
- Risk in the old callable approach: output variables could receive top-level
  Dataset attrs instead of matching variable attrs.
- Expected behavior: Dataset result attrs come from `ds_x.attrs`; each data
  variable's attrs come from `ds_x[var].attrs`.
- V1 status: resolved by the post-`apply_ufunc` Dataset data variable attrs
  normalization loop.
- Related proof obligations: O2, O3.

### F4: `x`-first ordering is justified, not a legacy-derived choice

- Input class: `xr.where(cond_da, x_da, y_da, keep_attrs=True)` where all three
  are labeled.
- Potential concern: V1 changes the internal `apply_ufunc` argument order for
  this branch from `(cond, x, y)` to `(x, cond, y)`.
- Expected behavior: public docs say attrs come from `x`, and the method
  implementation is `apply_ufunc(..., self, cond, other, keep_attrs=True)`.
- V1 status: confirmed. The ordering is intent-derived from the docstring and
  method compatibility, not from hidden tests or legacy behavior.
- Related proof obligations: O1, O2, O4, O7.

## Open Findings / Residual Risk

### F5: Constructed proof has not been machine-checked

- Input: all in-domain inputs of the abstract model.
- Observed status: no `kompile`, `kast`, or `kprove` command was run, per task
  constraints.
- Expected verification upgrade: run the commands recorded in `fvk/PROOF.md`
  and require `kprove` to return `#Top`.
- Classification: proof capability / execution-environment limitation, not a
  source-code bug.
- Related proof obligations: all.

### F6: Full xarray alignment/value semantics are outside the mini-model

- Input: pathological alignment/indexing cases outside the attrs regression.
- Observed status: the FVK model abstracts the established `apply_ufunc` value
  and exact-alignment behavior, because the issue concerns attr propagation.
- Expected coverage: ordinary xarray tests must continue covering integration,
  alignment, dask, and indexing semantics.
- Classification: proof scope boundary, not a V1 bug.
- Related proof obligations: O1, O8.

