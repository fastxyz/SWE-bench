# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Migration Alias Is the Intended Write Alias

Statement: In `_rename()`, the database alias for content type updates is `schema_editor.connection.alias`.

Evidence: `benchmark/PROBLEM.md` names `schema_editor.connection.alias` as the database specified to the migration command, and the source assigns `db = schema_editor.connection.alias`.

Discharge: V1 uses `db` in the save call.

Findings: F-1, F-3.

## PO-2: Atomic Context Does Not Route the Save

Statement: `transaction.atomic(using=db)` must not be treated as sufficient evidence that the enclosed `save()` writes to `db`.

Evidence: `transaction.atomic()` stores transaction state on `get_connection(self.using)`. It does not alter the `using` argument of enclosed ORM calls.

Discharge: V1 passes `using=db` directly to `content_type.save()`.

Findings: F-2.

## PO-3: Explicit Save Alias Reaches the SQL Update

Statement: If `content_type.save(using=db, update_fields={'model'})` is called, the update query is executed using `db`.

Evidence: `Model.save()` computes `using = using or router.db_for_write(...)`; with explicit `using=db`, router fallback is skipped. `Model._save_table()` then uses `cls._base_manager.using(using)` for the update.

Discharge: V1 satisfies this obligation.

Findings: F-1, F-2, F-3.

## PO-4: Migration-Disallowed Branch Is a No-Op

Statement: If `router.allow_migrate_model(db, ContentType)` is false, `_rename()` returns without lookup or save.

Evidence: Source branch is before the lookup and unchanged by V1.

Discharge: V1 preserves this branch.

Findings: F-4.

## PO-5: Lookup Remains Scoped to the Migration Alias

Statement: The old content type lookup must query `db`.

Evidence: `_rename()` uses `ContentType.objects.db_manager(db).get_by_natural_key(...)`; `BaseManager.db_manager()` sets `_db`, and the manager's `db` property returns `_db` before consulting read routing.

Discharge: V1 does not alter lookup behavior.

Findings: F-3.

## PO-6: Missing Old Content Type Remains a No-Op

Statement: If the old content type does not exist on `db`, `_rename()` should not save anything.

Evidence: Source catches `ContentType.DoesNotExist` and `pass`es.

Discharge: V1 does not alter this branch.

Findings: F-4.

## PO-7: IntegrityError Conflict Fallback Is Preserved

Statement: If saving the new model value raises `IntegrityError`, `_rename()` restores `content_type.model = old_model` and does not run the success cache clear path.

Evidence: Source catches `IntegrityError` around the atomic save and restores the old model.

Discharge: V1 changes only the save alias, not the exception handling or success/failure branch shape.

Findings: F-4.

## PO-8: Public API and Dispatch Compatibility

Statement: The patch must not require a new public API or break virtual dispatch.

Evidence: `Model.save()` already accepts `using` and `update_fields`. The changed call is to a concrete model instance method with an existing keyword argument.

Discharge: V1 satisfies this obligation.

Findings: F-5.

## PO-9: Honesty Gate

Statement: The formal proof is constructed only; no claim may be described as machine-checked and no test may be removed based on this run.

Evidence: The benchmark forbids running K tooling and tests.

Discharge: `fvk/PROOF.md` records commands and expected outcomes without executing them.

Findings: F-6.

## Coverage Check

The obligations cover every branch of `_rename()` relevant to the reported issue:

- migration disallowed;
- old content type absent;
- old content type present and save succeeds;
- old content type present and save conflicts.

There is no loop or recursive obligation in this unit.
