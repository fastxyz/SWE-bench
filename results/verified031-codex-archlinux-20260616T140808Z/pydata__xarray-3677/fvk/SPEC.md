# FVK Specification: `Dataset.merge(DataArray)`

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

The audited unit is `dataset_merge_method()` as called by `Dataset.merge()`.
The observable behavior under audit is whether `Dataset.merge(other)` accepts a
named `DataArray` in the same way the top-level `xarray.merge([dataset,
dataarray])` path accepts it, while preserving existing Dataset/mapping merge
behavior.

No tests, Python, or K tooling were executed.

## Intent Spec

- `I-001`: A named `DataArray` is in-domain for merging with a `Dataset` via the
  `Dataset.merge()` method.
- `I-002`: For a named `DataArray`, `ds.merge(da)` should produce the same
  merged dataset as `xr.merge([ds, da])`, modulo the method-specific
  `overwrite_vars` option.
- `I-003`: `DataArray` conversion must happen before the merge internals treat
  `other` as mapping-like, because the issue reports `.items()` access on a
  `DataArray` as the bug symptom.
- `I-004`: Unnamed `DataArray` inputs remain invalid, matching top-level
  `merge()` behavior that requires `DataArray` objects to have a name.
- `I-005`: Existing `Dataset` and mapping inputs to `Dataset.merge()` must retain
  their prior behavior, including `overwrite_vars`, `compat`, `join`, and
  `fill_value` handling.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| `E-001` | problem | "`xr.merge([ds, da])  # works fine`" | Top-level merge is the reference behavior for a Dataset/DataArray merge. |
| `E-002` | problem | "`ds.merge(da)  # fails`" and traceback at `obj.items()` | The method failure is the bug; raw `DataArray` must not reach mapping-only code. |
| `E-003` | problem | Expected display includes variables `a` and `b` | The named array should become a dataset variable named by `da.name`. |
| `E-004` | source docstring | `merge()` says DataArray objects "must have a name" | Preserve `to_dataset()`'s ValueError for unnamed arrays. |
| `E-005` | source code | Top-level `merge()` uses `obj.to_dataset()` for `DataArray` before `merge_core()` | Reuse the existing normalization boundary instead of widening `merge_core()`. |
| `E-006` | source comment | `dataset_merge_method()` says `overwrite_vars` is retained for backwards compatibility | Normalize before overwrite branching so all method-specific paths are covered. |
| `E-007` | public tests | Existing merge tests cover Dataset/mapping behavior and `xr.merge` with arrays | Non-DataArray merge behavior is a frame condition. |

## Formal Spec English

- `C-001`: If `other` is a named `DataArray`, `dataset_merge_method()` first
  rewrites `other` to `other.to_dataset()`.
- `C-002`: In the no-overwrite case, the call to `merge_core()` receives
  `[dataset, other.to_dataset()]` and `priority_arg=None`.
- `C-003`: In the overwrite-all case, the call to `merge_core()` receives
  `[dataset, other.to_dataset()]` and `priority_arg=1`.
- `C-004`: In the partial-overwrite case, iteration and `.items()` apply to the
  converted dataset/mapping, not to the original `DataArray`; the call to
  `merge_core()` receives `[dataset, other_no_overwrite, other_overwrite]` and
  `priority_arg=2`.
- `C-005`: If `other` is already a `Dataset` or mapping, the runtime control
  flow and merge arguments are unchanged from the pre-fix implementation.
- `C-006`: If `other.to_dataset()` raises for an unnamed `DataArray` or a
  name/coordinate conflict, that error is preserved and no mapping-only access
  is attempted first.

## Spec Audit

| Claim | Intent match | Rationale |
| --- | --- | --- |
| `C-001` | pass | Directly discharges `I-001`, `I-002`, and `I-003`; it mirrors top-level `merge()`. |
| `C-002` | pass | Covers the reported `ds.merge(da)` default call. |
| `C-003` | pass | Covers method-specific overwrite compatibility for the all-overwrite branch. |
| `C-004` | pass | Covers method-specific partial overwrite compatibility and the `.items()` symptom. |
| `C-005` | pass | Required by `I-005`; the code only adds a DataArray branch. |
| `C-006` | pass | Required by `I-004` and top-level merge behavior. |

No claim depends on hidden tests, evaluator output, or upstream patch knowledge.

## Public Compatibility Audit

- Changed public symbol: `Dataset.merge`.
- Runtime signature shape: unchanged; the new accepted runtime input is a
  previously documented "castable to Dataset" object made explicit in the
  annotation and docstring.
- Direct helper callsites: `dataset_merge_method()` is called from
  `Dataset.merge()` only.
- Virtual dispatch/subclass risk: no new method is called on `self`; the new
  call is `other.to_dataset()` only after `isinstance(other, DataArray)`.
- Producer/consumer shape: `merge_core()` continues to receive only Dataset or
  mapping-like objects, matching its documented contract.
- Test-file changes: none.

## Formal Core Summary

The constructed model has no loops. It is a case split over `isDataArray(other)`
followed by a case split over normalized `overwrite_vars`.

K-style claims are recorded in `PROOF_OBLIGATIONS.md` and in the abstract
constructed files `mini-xarray-merge.k` and `xarray-merge-spec.k`; the proof
narrative and non-executed commands are recorded in `PROOF.md`.
