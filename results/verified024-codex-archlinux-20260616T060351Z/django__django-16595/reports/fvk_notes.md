# FVK Notes

## Summary

The FVK audit confirms V1 without further source edits. The same-field
`AlterField` branch in `AlterField.reduce()` is the minimal change required by
the public issue and is justified by F-001 plus PO-001, PO-002, and PO-004.

## Decisions Traced to Findings and Obligations

D-001: Kept V1's `return [operation]` branch unchanged.

Trace: F-001, PO-001, PO-002, PO-004.

Reason: F-001 identifies the missing same-field `AlterField` reduction as the
root defect. PO-001 requires the new reducer branch, PO-002 requires retaining
the later operation object, and PO-004 shows repeated optimizer passes collapse
finite same-field chains.

D-002: Did not broaden the fix into `FieldOperation.reduce()`.

Trace: F-002, PO-006.

Reason: F-002 records the over-broad reduction risk. PO-006 requires different
model/field pairs to remain outside the new branch, which the V1 localized
change satisfies.

D-003: Did not add special handling for `preserve_default`.

Trace: F-004, PO-002.

Reason: F-004 records that V1 preserves the later operation payload by returning
the operation object directly. PO-002 makes that preservation the formal
obligation. A `preserve_default` guard would reject cases the public reduction
rule covers.

D-004: Did not change `RemoveField` or `RenameField` behavior.

Trace: F-003, PO-005.

Reason: F-003 confirms no defect in the existing branches. PO-005 requires them
to remain framed, and the V1 type check is disjoint from those operation types.

D-005: Did not run tests, Python, or K tooling and did not edit test files.

Trace: F-005, PO-008.

Reason: the task forbids execution and test edits. The FVK proof is therefore
constructed, not machine-checked, and `fvk/PROOF.md` records the commands a
later unrestricted environment should run.

## Files Changed in This FVK Pass

Added `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
`fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` as the requested FVK
artifacts.

Added `fvk/mini-migration-optimizer.k` and `fvk/alter-field-reduce-spec.k` as
supporting formal artifacts required by the FVK method documentation.

Added `reports/fvk_notes.md` to trace the V1 confirmation and no-change
decisions to the FVK findings and proof obligations.
