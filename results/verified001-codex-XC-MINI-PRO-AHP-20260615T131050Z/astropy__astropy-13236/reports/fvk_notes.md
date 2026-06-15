# FVK Notes

## Decisions

- Restored `NdarrayMixin` as an import-only binding in
  `repo/astropy/table/table.py`. This addresses `fvk/FINDINGS.md` F-001 and
  discharges `fvk/PROOF_OBLIGATIONS.md` PO-004: `astropy.table.__init__`
  imports `NdarrayMixin` from `.table`, so V1's removal of the import broke a
  public re-export path. The `# noqa: F401` marker follows the repository's
  existing pattern for imports kept for public availability.

- Kept V1's deletion of the automatic structured-ndarray-to-`NdarrayMixin`
  branch. This is justified by `fvk/FINDINGS.md` F-003 and
  `fvk/PROOF_OBLIGATIONS.md` PO-001/PO-002: once the special branch is gone,
  a non-mixin structured ndarray reaches the normal `ColumnClass` constructor,
  which is the behavior required by the public issue and hints.

- Kept explicit `NdarrayMixin` behavior unchanged. This follows
  `fvk/PROOF_OBLIGATIONS.md` PO-003: `_is_mixin_for_table` still recognizes an
  explicit `NdarrayMixin` and the unchanged `data_is_mixin` branch returns it as
  a mixin.

- Did not modify test files. `fvk/FINDINGS.md` F-002 and
  `fvk/PROOF_OBLIGATIONS.md` PO-005 classify the existing public
  `test_ndarray_mixin` assertions for plain structured arrays as SUSPECT legacy
  evidence because they encode the behavior the issue asks to remove. The task
  also forbids test edits.

- Did not run tests, Python, or K tooling. This is required by the task and is
  recorded in `fvk/FINDINGS.md` F-004 and `fvk/PROOF_OBLIGATIONS.md` PO-006.

## Outcome

The FVK audit changed V1 only to restore the `NdarrayMixin` public re-export.
The core behavior fix stands: plain structured ndarrays are no longer forcibly
viewed as `NdarrayMixin`, while deliberate `NdarrayMixin` inputs remain mixins.
