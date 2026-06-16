# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed Symbol

`repo/xarray/core/merge.py::merge_attrs`

- Signature unchanged.
- Accepted `combine_attrs` strings unchanged.
- Return type shape unchanged: attrs mapping, `{}`, `None`, or errors as before by branch.
- Behavior change is limited to object identity for `combine_attrs="override"`: the returned mapping is now a shallow copy instead of the first source mapping itself.

## Public Callers and Producer/Consumer Shape

| Caller | Compatibility status |
| --- | --- |
| `merge_core` / public `merge` | Compatible and repaired. `merge` stores `_MergeResult.attrs` via `Dataset._construct_direct`, so the helper's fresh mapping is required to avoid aliasing. |
| `dataset_update_method` | Compatible. It passes `combine_attrs="override"` and benefits from fresh attrs; no signature or return-shape change. |
| `_dataset_concat` / public `concat` for Datasets | Compatible. It already passes result attrs through `Dataset(...)`, whose constructor copies attrs; the helper returning a fresh dict is still compatible and more robust. |
| `_dataarray_concat` / public `concat` for DataArrays | Compatible. It assigns through `result.attrs = merged_attrs`, whose setter copies attrs; helper copy remains compatible. |
| `combine.py` / backend open-mfdataset paths | Compatible through their existing merge/concat use; no public API changed. |

## Override/Subclass Audit

No virtual dispatch signature was changed. No subclass override needs a new argument or return protocol.

## Compatibility Risk

The only behavior no longer available is depending on the merged result attrs dictionary being the identical object as the first source attrs dictionary. That behavior is the reported bug and conflicts with public intent, so it is not preserved.
