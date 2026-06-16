# Iteration Guidance

Status: V1 stands. No additional source edit is justified by the FVK audit.

## Decision

Keep the V1 source change in `repo/xarray/core/variable.py`:

```python
data = PandasIndexAdapter(self._data.array.copy(deep=True),
                          dtype=self._data.dtype)
```

This is the minimal change that discharges the bug-specific proof obligation:
the copied adapter must retain the xarray-visible dtype even if the copied
pandas index reports `object`.

## Why No V2 Source Change Was Applied

F-001 is resolved by PO-3. The only identified code bug was dtype metadata loss
when rebuilding `PandasIndexAdapter` in the deep-copy branch.

F-002 does not justify source edits. The issue text mentions `copy.copy()`, but
the current source routes `copy.copy()` through `deep=False`, and the public hint
states `DataArray.copy(deep=False)` is not affected. PO-2 proves the shallow
branch preserves dtype by reusing the adapter.

No public API compatibility issue was found. PO-7 confirms that V1 uses an
existing optional constructor argument and does not alter signatures or dispatch
shape.

## Future Work Outside This Benchmark

Add regression tests for unicode `IndexVariable` dtype preservation across:

- `Dataset.copy(deep=True)`
- `DataArray.copy()`
- `DataArray.copy(deep=True)`
- `copy.deepcopy()` for Dataset/DataArray
- optionally `copy.copy()` as a shallow-copy frame check

Do not remove tests based on this FVK pass unless the K claims are later
machine-checked and return `#Top`.
