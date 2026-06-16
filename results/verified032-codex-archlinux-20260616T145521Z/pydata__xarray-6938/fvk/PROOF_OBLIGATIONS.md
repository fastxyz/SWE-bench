# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: No-mutation frame condition

For every in-domain `Dataset.swap_dims()` call and every variable object stored in the input dataset, the variable's `dims` metadata after the call equals its `dims` metadata before the call.

- Proven by: C-001, C-002, C-003.
- Findings: F-001, F-002.

## PO-002: Promoted `IndexVariable` alias isolation

When a variable name is in `result_dims`, the code assigns `.dims` only after obtaining a distinct result variable object. This must hold even when `v.to_index_variable()` returns `v`.

- V1 code path: `var = v.to_index_variable().copy(deep=False); var.dims = dims`.
- Proof idea: `copy(deep=False)` returns a distinct object `R`; assigning `R.dims` cannot modify `v.dims`.
- Findings: F-001, F-002, F-003.

## PO-003: Returned promoted variable has rewritten dimensions

For a promoted replacement variable, the returned variable's dimensions are `tuple(dims_dict.get(dim, dim) for dim in v.dims)`.

- V1 code path: `dims = ...`; copied `var.dims = dims`; result stores `var` or index variables derived from `var`.
- Findings: none unresolved.

## PO-004: Non-promoted branch owns fresh variable before mutation

When a variable name is not in `result_dims`, `v.to_base_variable()` constructs a fresh base `Variable` before `.dims` is assigned.

- V1 code path unchanged from baseline.
- Findings: none unresolved.

## PO-005: Existing validation behavior unchanged

The method must continue rejecting missing source dimensions and invalid replacement variables before constructing result variables.

- V1 code path unchanged before `result_dims`.
- Findings: none unresolved.

## PO-006: Public compatibility and shallow-copy behavior

The fix must not change public method signature, accepted input domain, documented output shape, or validation errors. It may change internal variable object identity to prevent metadata mutation, while preserving shallow data behavior.

- Audited in: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Findings: F-003.

## PO-007: Honesty gate

Because no execution environment exists, the proof is partial correctness, constructed but not machine-checked. Test removal must remain conditional on running the emitted K commands later.

- Findings: F-004.
