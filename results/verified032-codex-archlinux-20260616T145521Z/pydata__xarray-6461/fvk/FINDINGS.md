# FVK Findings

Status: constructed from public evidence and source inspection; not machine-checked.

## F1 - Closed: scalar `x` must not trigger positional attrs indexing

Input: `xr.where(xr.DataArray([1, 2, 3]) > 0, 1, 0)` with `keep_attrs=True` effective through explicit argument or global option.

Pre-fix observed: `IndexError: list index out of range` from a callable equivalent to `attrs[1]`.

Expected: no attrs-indexing failure. Because `x=1` is scalar, the attrs preserved from `x` are empty.

V1 status: fixed. V1 creates an attrs selector whose `x_attrs` list is empty for scalar `x`; for any merge attrs list it returns `{}` without indexing position `1`.

Related obligations: PO1, PO2.

## F2 - Closed: scalar `x` must not preserve attrs from `y`

Input family: `xr.where(cond, 1, y_with_attrs, keep_attrs=True)`.

Risk in a minimal fallback patch: replacing `attrs[1]` with `attrs[1] if len(attrs) > 1 else {}` can still select `y` attrs when `cond` and `y` are the two xarray contributors.

Expected: scalar `x` has no attrs, so result attrs from the `keep_attrs=True` policy are empty.

V1 status: fixed. Because scalar `x` contributes no attrs sources, V1 returns `{}` rather than any attrs from `cond` or `y`.

Related obligations: PO2, PO4.

## F3 - Confirmed: xarray `x` attrs are preserved by content

Input family: `xr.where(cond, x_with_attrs, y, keep_attrs=True)`.

Expected: resulting attrs equal `x.attrs` for object/global attrs merges, and equal the relevant x variable or coordinate attrs when that x source participates in the corresponding merge.

V1 status: confirmed by source-level proof. V1 records attrs dictionaries associated with `x` and returns a matching attrs dictionary when the current merge list contains matching x attrs content. The public contract is content equality, not object identity.

Related obligations: PO3.

## F4 - Confirmed: V1 preserves public API compatibility

Input family: existing public calls to `xr.where(cond, x, y, keep_attrs=...)`.

Expected: no signature change and no new public calling convention.

V1 status: confirmed by source inspection. Only the local callable used when `keep_attrs is True` changed.

Related obligations: PO5.

## F5 - Residual proof and test limitation

The proof is constructed, not machine-checked. No tests or Python snippets were run because the task forbids execution. Existing tests should not be removed on the basis of these artifacts unless the emitted K commands are later run successfully.

Related obligations: PO6.
