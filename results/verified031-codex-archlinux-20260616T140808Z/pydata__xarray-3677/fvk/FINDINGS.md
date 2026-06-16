# FVK Findings

Status: constructed from public intent and source inspection; not machine-checked.

## F-001: Bare `DataArray` reached mapping-only merge internals

- Classification: code bug in the original pre-fix baseline, resolved by
  current source.
- Input: `ds = xr.Dataset({"a": 0})`; `da = xr.DataArray(1, name="b")`;
  call `ds.merge(da)`.
- Observed pre-fix behavior from the issue: `AttributeError: 'DataArray' object
  has no attribute 'items'`.
- Expected behavior from public intent: same merged variables as
  `xr.merge([ds, da])`, namely variables `a` and `b`.
- Evidence: `E-001`, `E-002`, `E-003`.
- Proof obligations: `PO-001`, `PO-002`.
- Current status: resolved by normalizing `other` with `to_dataset()` before any
  mapping-specific branch in `dataset_merge_method()`.

## F-002: `overwrite_vars` needed the same normalization point

- Classification: potential branch bug, resolved by current source.
- Input family: `ds.merge(da, overwrite_vars=...)` where `da` is a named
  `DataArray`.
- Observed pre-fix risk: `set(other)` or `other.items()` would operate on the
  `DataArray` rather than a Dataset/mapping.
- Expected behavior: overwrite branching should operate on the one-variable
  Dataset produced by `da.to_dataset()`, matching Dataset inputs.
- Evidence: `E-006`.
- Proof obligations: `PO-003`, `PO-004`.
- Current status: resolved because conversion occurs before overwrite
  normalization and branch selection.

## F-003: Unnamed `DataArray` remains an intentional error

- Classification: preserved precondition, not a code bug.
- Input: `ds.merge(xr.DataArray([1, 2], dims="x"))`.
- Expected behavior: raise the same `ValueError` as `xr.merge([dataarray])`
  because a DataArray must have a name to become a Dataset variable.
- Evidence: `E-004`.
- Proof obligation: `PO-005`.
- Current status: preserved because `DataArray.to_dataset()` raises before
  merge internals run.

## F-004: Non-DataArray merge behavior must be framed unchanged

- Classification: compatibility frame condition, satisfied by current source.
- Input family: existing `Dataset.merge(Dataset)` and `Dataset.merge(mapping)`
  calls, including `compat`, `join`, `fill_value`, and `overwrite_vars`.
- Expected behavior: existing behavior is unchanged.
- Evidence: `E-005`, `E-006`, `E-007`.
- Proof obligation: `PO-006`.
- Current status: satisfied because the only runtime branch added is guarded by
  `isinstance(other, DataArray)`.

## F-005: Proof and test-redundancy claims are not machine-checked

- Classification: verification honesty boundary.
- Input: all audited cases.
- Observed limitation: K tooling, Python, and tests were not executed by
  instruction.
- Expected handling: treat the proof as constructed, not machine-checked; do not
  delete or weaken tests based on it.
- Evidence: task instructions and FVK honesty gate.
- Proof obligation: `PO-007`.
- Current status: recorded; no test files modified.
