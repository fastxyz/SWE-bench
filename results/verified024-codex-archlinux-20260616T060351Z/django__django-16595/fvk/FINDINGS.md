# FVK Findings

Status: constructed, not machine-checked.

## F-001: Missing Same-Field AlterField Reduction - Resolved by V1

Input: a detached chain such as
`AlterField("book", "title", F1)`,
`AlterField("book", "title", F2)`,
`AlterField("book", "title", F3)`.

Observed before V1: the issue reports that the optimizer returned all three
`AlterField` operations when the preceding `AddField` was absent.

Expected: the optimizer should reduce the same-field chain to the last
`AlterField`, matching the public hint that `AlterField.reduce()` should return
`[operation]` when `operation` is another same-field `AlterField`.

FVK status: resolved. PO-001, PO-002, and PO-004 cover this behavior, and the
V1 source branch implements the required reducer case.

## F-002: Over-Broad Reduction Risk - Not Present in V1

Input: `AlterField("book", "title", F1)` followed by
`AlterField("book", "subtitle", F2)` or by an alter on another model.

Observed in V1: the new branch is guarded by `self.is_same_field_operation()`.

Expected: different model/field operations must not be collapsed by this fix.

FVK status: no code defect found. PO-003 and PO-006 show that the new branch is
limited to same-field `AlterField` pairs and otherwise falls through to the
existing reducer logic.

## F-003: Existing Remove/Rename Semantics - Preserved

Input: an `AlterField` followed by a same-field `RemoveField` or a same-field
`RenameField`.

Observed in V1: the pre-existing `RemoveField` and `RenameField` branches remain
in the same method after the new `AlterField` branch.

Expected: the issue does not ask to change these cases, and the optimizer
contract requires existing special reductions to keep working.

FVK status: no code defect found. PO-005 covers this frame condition.

## F-004: preserve_default Payload - Later Operation Retained

Input: same-field `AlterField` followed by another `AlterField` with any field
payload and any `preserve_default` value.

Observed in V1: the replacement list contains the later operation object itself,
not a reconstructed operation.

Expected: the public suggested fix says to return `[operation]`, so the later
operation's payload is preserved exactly. Adding an extra guard on
`preserve_default` would under-satisfy the public issue by refusing to collapse
valid same-field alters whose later operation differs in payload.

FVK status: no code defect found. PO-002 records this payload preservation.

## F-005: Formal Tooling Not Executed - Residual Verification Caveat

Input: the constructed K semantics and claims under `fvk/`.

Observed in this environment: the task forbids running K framework tooling,
tests, Python, or project code.

Expected: artifacts must include exact commands and be labeled constructed, not
machine-checked.

FVK status: residual caveat, not a source defect. PO-008 covers the unexecuted
machine-check obligation.
