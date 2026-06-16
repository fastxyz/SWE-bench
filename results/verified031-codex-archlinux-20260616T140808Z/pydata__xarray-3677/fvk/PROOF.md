# FVK Proof

Status: constructed, not machine-checked.

## Proof Summary

The current source satisfies the specification. No V2 code edit is justified by
the FVK audit; V1 stands.

## Symbolic Proof

### PO-001: DataArray normalization

At entry to `dataset_merge_method()`, the current source imports `DataArray` and
case-splits on `isinstance(other, DataArray)`. In the true branch, it performs
`other = other.to_dataset()` before overwrite handling. Therefore every later
reference to `other` in the helper sees `DDA = toDataset(DA)`, not `DA`.

This discharges `PO-001`.

### PO-002: No-overwrite branch

After `PO-001`, normalize `overwrite_vars`. For the default
`overwrite_vars=frozenset()`, the normalized set is empty. The `if not
overwrite_vars` branch constructs `objs = [dataset, other]` and
`priority_arg = None`. Because `other` has already been rewritten to `DDA`, the
resulting abstract call is:

```text
core([DS, DDA], priority_arg=None, compat, join, fill_value)
```

No raw `DataArray` reaches `merge_core()` or `coerce_pandas_values()`.

This discharges `PO-002` and resolves `F-001`.

### PO-003: Overwrite-all branch

Again after `PO-001`, the condition `overwrite_vars == set(other)` uses the
normalized `other`. For a named `DataArray`, `other` is now a one-variable
Dataset, so membership is over Dataset data variables, matching existing
Dataset inputs. The branch constructs `objs = [dataset, other]` and
`priority_arg = 1`.

This discharges `PO-003`.

### PO-004: Partial-overwrite branch

If overwrite variables are non-empty and not equal to `set(other)`, the helper
enters the split branch:

```text
for k, v in other.items()
```

By `PO-001`, `other` is already `DDA`, so `.items()` is a Dataset/mapping
operation. The branch produces `other_no_overwrite` and `other_overwrite`, then
calls `merge_core([dataset, other_no_overwrite, other_overwrite],
priority_arg=2, ...)`.

This discharges `PO-004` and resolves `F-002`.

### PO-005: Conversion errors

`DataArray.to_dataset()` is the same conversion used by top-level `merge()`. If
the DataArray is unnamed, or if its name conflicts with one of its coordinates,
`to_dataset()` raises before the helper reaches `set(other)`, `.items()`, or
`merge_core()`. This preserves top-level error behavior instead of introducing
a new method-specific error.

This discharges `PO-005` and confirms `F-003`.

### PO-006: Non-DataArray frame condition

For non-DataArray inputs, the new `isinstance(other, DataArray)` guard is false.
The remaining runtime statements are the pre-existing overwrite normalization,
branching, and `merge_core()` call. The annotation and docstring edits do not
change runtime dispatch.

This discharges `PO-006` and confirms `F-004`.

### PO-007: Honesty boundary

The proof is source-level and constructed. The task forbids running tests,
Python, `kompile`, or `kprove`, so no artifact is machine-checked here and no
test deletion is recommended.

This discharges `PO-007` only as an honesty condition, not as a machine-check.

## Completeness Check

The proof covers the full intended behavior space for this issue:

- the reported default method call;
- the method-specific overwrite-all branch;
- the method-specific partial-overwrite branch;
- conversion errors for out-of-domain DataArray inputs;
- non-DataArray Dataset/mapping frame behavior.

There are no loops in the audited helper, so no loop circularity or termination
measure is required.

## Commands Not Run

The FVK command shape that would be used for a concrete K artifact is:

```sh
kompile fvk/mini-xarray-merge.k --backend haskell
kast --backend haskell fvk/xarray-merge-spec.k
kprove fvk/xarray-merge-spec.k
```

Expected constructed outcome: `#Top` for the abstract claims above, assuming
the abstract mini-semantics encodes the source-level case split described in
this proof. These commands were not executed.

## Test Recommendation

Do not remove tests. Because the proof is not machine-checked, test-redundancy
recommendations are not actionable. Useful public tests to add in a normal
development setting would cover:

- `ds.merge(named_da)` equals `xr.merge([ds, named_da])`;
- `ds.merge(named_da, overwrite_vars=da.name)` follows Dataset overwrite
  behavior;
- `ds.merge(unnamed_da)` raises the same `ValueError` as top-level `merge()`.
