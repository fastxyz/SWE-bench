# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Optimized Single-Object Fast Delete Clears PK

Precondition:
`Collector.delete()` has exactly one model in `self.data`, exactly one instance in that model's instance collection, `self.can_fast_delete(instance)` is true, and `DeleteQuery(model).delete_batch([instance.pk], using)` returns normally with count `C`.

Postcondition:
The method returns `C, {model._meta.label: C}` and the in-memory instance has `model._meta.pk.attname` set to `None`.

Status:
Discharged by V1 and represented by `OPT-FAST-SINGLE-CLEAR-PK`.

## PO2 - Normal Collected Delete Continues to Clear Collected PKs

Precondition:
`Collector.delete()` does not return through the optimized fast branch and reaches the existing collected-instance cleanup block.

Postcondition:
Every collected instance in `self.data` has its model primary-key attname set to `None`.

Status:
Unchanged source behavior; represented by `NORMAL-COLLECTED-CLEAR-PK` as the reference path.

## PO3 - No Fast-Branch Field-Update Cleanup Is Required

Precondition:
The optimized branch is selected through `self.can_fast_delete(instance)`.

Postcondition:
No `field_updates` cleanup is required in that branch because the fast-delete predicate excludes cascades, parents, signal listeners, and private bulk-related fields that force normal collection/update handling.

Status:
Discharged by source control-flow inspection of `can_fast_delete()` and `collect()`.

## PO4 - Exception Ordering Is Preserved

Precondition:
`DeleteQuery(model).delete_batch()` raises before returning.

Postcondition:
The new primary-key cleanup is not executed, matching the normal pattern that cleanup happens only after database deletion completes.

Status:
Discharged by source order: V1 places `setattr()` after the `with transaction.mark_for_rollback_on_error()` delete call.

## PO5 - Return Shape and Public Signatures Are Preserved

Precondition:
Any public caller invokes `Model.delete()`, `QuerySet.delete()`, or internal `Collector.delete()`.

Postcondition:
No method signature, return type, result shape, or virtual dispatch signature changes.

Status:
Discharged by diff inspection and `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO6 - QuerySet Fast Deletes Are Not Overclaimed

Precondition:
`QuerySet.delete()` takes a queryset fast-delete path with no in-memory model instance provided to the caller.

Postcondition:
The proof does not require per-instance PK mutation for rows deleted only through queryset raw deletion.

Status:
Discharged as a frame condition from `QuerySet.delete()` source behavior and issue wording.
