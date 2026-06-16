# FINDINGS

Status: constructed, not machine-checked.

## FVK-F1: Missing same-model manager reduction is the reported bug

Input:

`[CreateModel("Foo", fields=F, options=O, bases=B, managers=M0),
AlterModelManagers("Foo", managers=M1)]`

Observed before V1 from source structure: `CreateModel.reduce()` had branches
for `AlterModelOptions`, together options, order-with-respect-to, and field
operations, but no `AlterModelManagers` branch, so the optimizer could not
collapse this pair at the `CreateModel.reduce()` step.

Expected from E1: a one-operation result,
`[CreateModel("Foo", fields=F, options=O, bases=B, managers=M1)]`.

Status: closed by V1. Covered by PO1 and PO2.

## FVK-F2: Manager replacement must not merge old and new managers

Input:

`CreateModel("Foo", managers=[("old", old_manager)])` followed by
`AlterModelManagers("Foo", managers=[("new", new_manager)])`.

Observed risk: a naive reducer could preserve `self.managers`, append managers,
or otherwise combine `M0` and `M1`.

Expected from E3 and E4: final managers are exactly `list(M1)`.

Status: closed by V1 because it passes `managers=operation.managers` to the
replacement `CreateModel`. Covered by PO3.

## FVK-F3: Empty manager replacement is in-domain

Input:

`CreateModel("Foo", managers=M0)` followed by
`AlterModelManagers("Foo", managers=[])`.

Expected from E4 and E6: final managers are `[]`; the original managers are not
preserved.

Status: closed by V1. Passing `operation.managers` into `CreateModel` preserves
the empty-list final state through `CreateModel.__init__()` normalization.
Covered by PO7.

## FVK-F4: Different-model operations must not be absorbed

Input:

`CreateModel("Foo", managers=M0)` followed by
`AlterModelManagers("Bar", managers=M1)`.

Expected from E5: the manager alteration for `Bar` must not be folded into the
`Foo` `CreateModel`.

Status: closed by V1 because the new branch requires
`self.name_lower == operation.name_lower`. Covered by PO4.

## FVK-F5: Proof is not machine-checked in this environment

Input: the constructed K artifacts and proof commands in `fvk/`.

Observed: benchmark instructions prohibit running K tooling, Python, or tests.

Expected: artifacts must state the commands and reason about their expected
outcome without executing them.

Status: residual process limitation, not a code bug. Covered by PO8.

## Summary

No new source-code bug was found in V1. The audit confirms V1 discharges the
issue-specific obligations. The fix stands unchanged.
