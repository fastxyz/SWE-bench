# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Same-Field AlterField Branch

If `operation` is an `AlterField` and `self.is_same_field_operation(operation)`
is true, `AlterField.reduce()` must return `[operation]`.

Evidence: E-003 and E-004 in `fvk/SPEC.md`.

Discharge status: satisfied by the V1 branch in
`repo/django/db/migrations/operations/fields.py`.

## PO-002: Later Operation Payload Preservation

The replacement must be the later `operation` object, preserving its field and
`preserve_default` payload rather than reconstructing or merging it.

Evidence: E-004 in `fvk/SPEC.md`.

Discharge status: satisfied because V1 returns `[operation]` directly.

## PO-003: Existing Same-Field Predicate

The new branch must use the existing same-field predicate so matching remains
case-insensitive in the same way as other field operation reductions.

Evidence: E-005 in `fvk/SPEC.md`.

Discharge status: satisfied by the call to `self.is_same_field_operation()`.

## PO-004: Finite Chain Collapse

For any finite consecutive chain of same-field `AlterField` operations and no
non-optimizable boundary, repeated pairwise optimizer reduction must terminate
with the last `AlterField`.

Evidence: E-001, E-002, and E-006 in `fvk/SPEC.md`.

Discharge status: constructed proof. Each V1 pairwise reduction shortens the
chain by one while preserving the last operation. The optimizer loop repeats
until stable, so induction on chain length gives the result.

## PO-005: Existing Remove/Rename Frame

The added branch must not change pre-existing same-field `RemoveField` and
`RenameField` behavior.

Evidence: E-007 in `fvk/SPEC.md`.

Discharge status: satisfied by source order and type distinction: the new branch
matches only `AlterField`; `RemoveField` and `RenameField` continue to reach
their existing branches.

## PO-006: Different Field/Model Frame

The added branch must not collapse different model or different field
`AlterField` pairs.

Evidence: E-005 in `fvk/SPEC.md`.

Discharge status: satisfied because the branch requires
`self.is_same_field_operation(operation)`.

## PO-007: Public Compatibility

The public method signature and optimizer return contract must remain stable.

Evidence: IS-005 and the Public Compatibility Audit in `fvk/SPEC.md`.

Discharge status: satisfied. V1 changes only one internal branch result and
keeps the existing `reduce(self, operation, app_label)` signature and list return
shape.

## PO-008: Machine-Check Caveat

The K claims should be checked later with the emitted `kompile`, `kast`, and
`kprove` commands.

Evidence: FVK task instructions and F-005.

Discharge status: not executed by instruction. This blocks claiming
machine-checked verification but does not identify a code change.
