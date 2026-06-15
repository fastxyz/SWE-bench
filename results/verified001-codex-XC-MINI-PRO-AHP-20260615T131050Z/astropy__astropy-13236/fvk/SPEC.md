# FVK Spec: astropy__astropy-13236

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The verified unit is the observable conversion decision in
`Table._convert_data_to_col` for column-like data added through table
construction, assignment, replacement, or `add_column`. The audit also covers
the public `NdarrayMixin` re-export path because V1 touched the only import that
made `astropy.table.table.NdarrayMixin` available to `astropy.table.__init__`.

## Intent Spec

- I1: A plain structured `np.ndarray` supplied as one table column must not be
  automatically viewed as `NdarrayMixin`.
- I2: Such data must enter the normal table column path and become the table's
  normal `ColumnClass` result: `Column` for an ordinary `Table`, and the existing
  configured column class for table variants such as masked tables.
- I3: The change should be immediate, not a staged `FutureWarning`, because the
  public discussion concludes with "just changing it" and "Delete a few lines of
  code".
- I4: Explicit `NdarrayMixin` input remains valid mixin input. The issue targets
  automatic conversion of plain structured arrays, not removal of `NdarrayMixin`.
- I5: Public imports of `NdarrayMixin` must remain compatible.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "structured `np.array` ... gets turned into an `NdarrayMixin`" | Identify the automatic conversion as the defect. | Encoded by C1. |
| E2 | prompt | "the structured array will be added as a `Column`" | Plain structured ndarray must reach the normal column path. | Encoded by C1 and PO-001. |
| E3 | public hints | "no longer is any reason to put structured arrays into `NdarrayMixin`" | Do not preserve legacy conversion for compatibility. | Encoded by C1; public legacy test marked SUSPECT. |
| E4 | public hints | "just changing it" / "Delete a few lines of code" | No deprecation warning is required for this fix. | Encoded by I3. |
| E5 | code | `astropy.table.__init__` imports `NdarrayMixin` from `.table`. | Keep `astropy.table.table.NdarrayMixin` bound. | Encoded by C3; V1 failed, V2 fixed. |
| E6 | public test | `test_ndarray_mixin` asserts plain structured arrays are `NdarrayMixin`. | Suspect legacy evidence because it asserts the reported bug. | Finding F-002; not used as intent. |

## Formal Model

The K core is intentionally abstract and property-complete for this issue:

- `plainStructuredNdarray` represents data satisfying the removed legacy branch:
  `isinstance(data, np.ndarray)`, structured dtype, not `Column`, not already a
  valid table mixin, and not handled by the mixin registry.
- `explicitNdarrayMixin` represents a user-supplied valid mixin.
- `columnResult(data)` means `_convert_data_to_col` proceeds through the
  existing `ColumnClass(name=name, data=data, ...)` construction path.
- `mixinResult(data)` means `_convert_data_to_col` returns through the
  `data_is_mixin` branch.
- `tableModuleNdarrayMixin` models the public module attribute used by
  `astropy.table.__init__`.

Machine-checkable core files:

- `fvk/mini-astropy-table.k`
- `fvk/structured-column-spec.k`

## Formal Spec English

- C1: For every plain structured ndarray in scope, conversion returns
  `columnResult(plainStructuredNdarray)`, not `mixinResult`.
- C2: For every explicit `NdarrayMixin` in scope, conversion returns
  `mixinResult(explicitNdarrayMixin)`.
- C3: Looking up `NdarrayMixin` on `astropy.table.table` returns the
  `NdarrayMixin` class binding.

## Spec Audit

| Claim | Adequacy | Reason |
| --- | --- | --- |
| C1 | pass | Directly matches E1-E4 and rejects the legacy branch the issue identifies as undesirable. |
| C2 | pass | The issue only removes automatic conversion; it does not deprecate explicit mixins. |
| C3 | pass | Public compatibility follows from E5 and was a concrete V1 regression. |

## Public Compatibility Audit

| Symbol or path | V1 status | V2 status |
| --- | --- | --- |
| `astropy.table.__init__` importing `NdarrayMixin` from `.table` | Broken by removing the binding from `table.py`. | Fixed by restoring `from .ndarray_mixin import NdarrayMixin  # noqa: F401`. |
| `astropy.table.table.NdarrayMixin` | Broken in V1. | Preserved in V2 as an import-only compatibility binding. |
| Existing explicit `NdarrayMixin` columns | Preserved by V1 and V2. | Still handled by `_is_mixin_for_table` and the `data_is_mixin` branch. |
