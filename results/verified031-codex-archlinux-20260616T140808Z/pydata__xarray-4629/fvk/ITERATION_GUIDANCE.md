# Iteration Guidance

Status: constructed for FVK audit, not machine-checked.

## Decision

V1 stands unchanged. The audit found that `dict(variable_attrs[0])` is exactly the source change required by PO1, PO2, and PO3. No additional source edit is justified by the public intent.

## Why No V2 Source Edit

- F1 shows the pre-fix defect was returning the first attrs mapping itself.
- PO2 is discharged by the V1 `dict(...)` allocation.
- PO3 shows `merge` needs the helper to allocate because `_construct_direct` stores attrs directly; V1 does that.
- F2 and PO5 reject deep copy as over-scoped.
- F4 and PO4 show signatures and caller protocols remain compatible.

## Follow-Up Tests To Add In A Normal Development Setting

Do not edit tests in this benchmark task. In normal development, add a regression test equivalent to:

```python
xds1 = xr.Dataset(attrs={"a": "b"})
xds2 = xr.Dataset(attrs={"a": "c"})
xds3 = xr.merge([xds1, xds2], combine_attrs="override")
xds3.attrs["a"] = "d"
assert xds1.attrs["a"] == "b"
assert xds3.attrs["a"] == "d"
```

Optionally add a lower-level helper test asserting `merge_attrs([attrs1, attrs2], "override") == attrs1` and `is not attrs1`.

## Machine Verification Next Step

Run the commands in `fvk/PROOF.md` in an environment with K installed. Treat any test-redundancy claim as conditional until `kprove` returns `#Top`.
