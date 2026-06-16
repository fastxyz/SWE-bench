# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source defect that would
justify a V2 code edit.

## Trace to Findings and Proof Obligations

- `F-001` identified the original bug: a bare `DataArray` reached
  mapping-only internals. `PO-001` and `PO-002` show that the current source
  converts `DataArray` to `to_dataset()` before the no-overwrite `merge_core`
  path. This is why no additional code change is needed for the reported
  `ds.merge(da)` call.
- `F-002` checked the method-specific `overwrite_vars` paths. `PO-003` and
  `PO-004` show that conversion occurs before `set(other)` and
  `other.items()`, so the V1 conversion point covers those branches too.
- `F-003` records that unnamed `DataArray` inputs should remain invalid.
  `PO-005` confirms that V1 preserves the existing `to_dataset()` error
  boundary used by top-level `merge()`.
- `F-004` records the compatibility frame for existing Dataset and mapping
  inputs. `PO-006` confirms that the runtime change is guarded by
  `isinstance(other, DataArray)`, so non-DataArray behavior is unchanged.
- `F-005` and `PO-007` record the honesty boundary: no tests, Python, or K
  tooling were run. The proof is constructed, not machine-checked, and does not
  justify deleting tests.

## Source Changes in This FVK Pass

No source files under `repo/` were changed during the FVK pass. The only new
files are the FVK artifacts under `fvk/` and this report.
