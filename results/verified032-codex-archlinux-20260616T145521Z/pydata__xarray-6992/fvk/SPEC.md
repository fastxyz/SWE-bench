# FVK Spec for pydata__xarray-6992

Status: constructed, not machine-checked.

## Scope

The audited unit is the internal state transition in
`Dataset.reset_index` that rebuilds `coord_names` after `drop_variables` and
`new_variables` have been computed:

```python
coord_names = self._coord_names & variables.keys() | set(new_variables)
```

The proof models the observable state needed for this issue:

- `V`: old `_variables` keys.
- `C`: old `_coord_names`.
- `D`: names removed from `_variables` by `drop=True`.
- `N`: keys of `new_variables`, created when resetting only some multi-index
  levels.
- `V' = (V - D) union N`: rebuilt `variables.keys()`.
- `C' = (C intersect V') union N`: rebuilt `coord_names`.

This is a partial-correctness audit of that transition. It does not model
pandas values or array contents, because the issue is about name-set consistency.

## Intent Spec

INT-1: The reported MCVE must not raise `ValueError: __len__() should return >=
0` during repr or data-variable mapping operations after
`set_index(...).reset_index(..., drop=True)`.

INT-2: `reset_index(..., drop=True)` removes the specified index coordinate or
multi-index level variables instead of extracting them as coordinates.

INT-3: Resetting and dropping the multi-index array coordinate must keep the
surviving level coordinate variables as coordinates.

INT-4: `_coord_names` must name only variables still present in the dataset, so
coordinate and data-variable mappings have coherent lengths and lookups.

INT-5: The public API signature and return shape of `Dataset.reset_index` must
remain unchanged.

## Public Evidence Ledger

E-1 `prompt`: "`_coord_names` than `_variables` ... breaks ... repr" imposes
INT-1 and INT-4.

E-2 `prompt`: MCVE
`xr.Dataset(coords={"a": ("x", [1, 2, 3]), "b": ("x", ['a', 'b', 'c'])}).set_index(z=['a', 'b']).reset_index("z", drop=True)`
imposes the concrete state obligation in PO-5.

E-3 `prompt`: relevant log output
`ValueError: __len__() should return >= 0` identifies the symptom and the
non-negative length obligation in PO-4.

E-4 `docs`: `Dataset.reset_index` docstring says `drop=True` removes specified
indexes and/or levels instead of extracting them, supporting INT-2.

E-5 `public-test`: `DataArray.reset_index("x", drop=True)` expects level
coordinates to remain after the multi-index array coordinate is removed,
supporting INT-3.

E-6 `implementation`: `new_variables` is merged into `variables` before
`coord_names` is computed, so every `N` member is in `V'`. This is a proof side
condition, not independent intent.

E-7 `implementation`: `DataVariables.__len__` computes
`len(_variables) - len(_coord_names)`, so INT-4 implies PO-4.

## Formal Spec English

K-1 Exact transition: executing `rebuildCoordNames(C, V', N)` sets the
coordinate-name set to `(C intersect V') union N`.

K-2 Invariant: if every new variable name is present in the rebuilt variable-key
set, then every rebuilt coordinate name is present in the rebuilt variable-key
set.

K-3 Frame: any old coordinate name that still has a variable remains a
coordinate, and any old coordinate name with no surviving variable is removed.

K-4 Replacement coordinates: every new index variable created by reset_index is
marked as a coordinate.

K-5 MCVE: for `V = C = {z, a, b}`, `D = {z}`, and `N = {}`, the rebuilt state is
`V' = {a, b}` and `C' = {a, b}`, so there are zero data variables and no stale
`z` coordinate name.

## Spec Audit

K-1 passes: it exactly paraphrases the source expression and is needed to prove
the intent-derived invariant.

K-2 passes: it is the direct formal version of INT-4 and E-1.

K-3 passes: it combines INT-2 and INT-3. Dropped names with no variable are not
coordinates; surviving level coordinates remain coordinates.

K-4 passes: it is required for partial multi-index level resets, where
`new_variables` holds the replacement index coordinate variables.

K-5 passes: it is the concrete MCVE from E-2 and removes the E-3 failure mode.

No formal claim is supported only by current implementation behavior. E-6 is
used solely as a source-code side condition for reachable states.

## Public Compatibility Audit

Changed public symbol: none. The patch changes only an internal expression in
`Dataset.reset_index`.

Signature compatibility: unchanged.

Return type compatibility: unchanged; `reset_index` still returns
`self._replace(...)`.

Producer/consumer compatibility: compatible. Consumers of `_coord_names`,
including `Dataset.coords`, `Dataset.data_vars`, and repr formatting, receive a
subset of `variables.keys()` instead of a stale superset.

Test files: not modified.
