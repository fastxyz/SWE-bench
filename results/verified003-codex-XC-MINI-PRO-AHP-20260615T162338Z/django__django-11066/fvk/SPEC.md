# FVK Specification for django__django-11066

Status: constructed, not machine-checked.

## Scope

The audited unit is `RenameContentType._rename()` in `repo/django/contrib/contenttypes/management/__init__.py`. The observable behavior under review is which database alias receives the content type update after a `RenameModel` migration operation.

The source change from V1 is retained:

```python
content_type.save(using=db, update_fields={'model'})
```

No tests or project code were executed.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`RenameContentType._rename()` doesn't save the content type on the correct database" | A content type rename must update the database selected for the migration, not an unrelated default or router-selected write database. | Encoded by S1 and PO-1. |
| I2 | `benchmark/PROBLEM.md` | "`schema_editor.connection.alias`" and "database specified via schema_editor.connection.alias" | The authoritative target alias for the rename write is `schema_editor.connection.alias`. | Encoded by S1 and PO-2. |
| I3 | `benchmark/PROBLEM.md` | "`transaction.atomic(using=db)` doesn't route any query and `save(using)` skips query routing" | Transaction alias selection alone is insufficient; the save operation itself must receive the explicit alias. | Encoded by S2 and PO-3. |
| I4 | Source: `RenameContentType._rename()` | `if not router.allow_migrate_model(db, ContentType): return` | If the content type model is not allowed to migrate on the alias, no lookup or save is required. | Encoded by S3 and PO-4. |
| I5 | Source: `RenameContentType._rename()` | `ContentType.objects.db_manager(db).get_by_natural_key(...)` | The lookup for the old content type is already scoped to the migration database alias. | Encoded by S4 and PO-5. |
| I6 | Source: `RenameContentType._rename()` | `except ContentType.DoesNotExist: pass` | Missing old content type remains a no-op. | Encoded by S5 and PO-6. |
| I7 | Source: `RenameContentType._rename()` | `except IntegrityError: content_type.model = old_model` | A stale conflicting content type keeps the existing graceful fallback behavior. | Encoded by S6 and PO-7. |
| I8 | Source: `Model.save()` in `repo/django/db/models/base.py` | `using = using or router.db_for_write(...)` | Passing `using=db` prevents router fallback for this save. | Encoded by S2 and PO-3. |
| I9 | Source: `Model._save_table()` in `repo/django/db/models/base.py` | `base_qs = cls._base_manager.using(using)` | The lower-level update query uses the alias supplied to save. | Encoded by S2 and PO-3. |
| I10 | Compatibility audit | `Model.save(..., using=None, update_fields=None)` | Adding `using=db` at this call site does not change any public signature or virtual dispatch shape. | Encoded by S7 and PO-8. |

## Intent-Only Specification

S1. For every invocation of `_rename(apps, schema_editor, old_model, new_model)`, let `db = schema_editor.connection.alias`. If a content type row for `(self.app_label, old_model)` exists on `db` and migration is allowed for `ContentType` on `db`, the write that changes `model` to `new_model` must be issued to `db`.

S2. The save operation must carry `using=db`; the surrounding `transaction.atomic(using=db)` is a transaction constraint and is not the routing mechanism for the model write.

S3. If `router.allow_migrate_model(db, ContentType)` is false, `_rename()` must return without performing the content type lookup or save.

S4. The old content type lookup must remain scoped to `db`.

S5. If the old content type row is absent, `_rename()` must preserve the existing no-op behavior.

S6. If saving the renamed content type raises `IntegrityError`, `_rename()` must preserve the existing stale-conflict fallback by restoring `content_type.model = old_model` and not clearing the cache as a successful rename.

S7. The fix must not change public APIs, operation injection semantics, or the `update_fields={'model'}` limitation.

## Formal Model Summary

The supporting K sketches model only the routing-relevant state:

- `fvk/mini-rename-contenttype.k`: an abstract transition system with a content type table keyed by `(db, app_label, model)`, an `allow_migrate` map, a router-selected write alias, and an explicit save target.
- `fvk/rename-contenttype-spec.k`: claims for the successful rename path, migrate-disallowed path, missing-content-type path, conflict path, and a pre-fix counterexample.

This abstraction is intentionally small but property-complete for the issue: it preserves the axis under verification, namely whether the save write targets `db` or a different alias.

## K Claim Paraphrase

C1. If migration is allowed on `DB` and the old content type exists on `DB`, `renameContentType(APP, OLD, NEW, DB)` reaches a state where the saved database is exactly `DB`, the row on `DB` has model `NEW`, and the cache is cleared.

C2. If migration is not allowed on `DB`, `renameContentType(...)` reaches a skipped state with no save target.

C3. If the old row is missing on `DB`, `renameContentType(...)` reaches a missing state with no save target.

C4. If the save on `DB` conflicts, the operation reaches a conflict state and restores the in-memory model to `OLD`.

C5. In the pre-fix variant `renameContentTypePreFix(...)`, if `routerWrite(ContentType) = DEFAULT` and `DEFAULT != DB`, the saved database is `DEFAULT`, violating S1.

## Adequacy Audit

The formal claims match the public intent because they make the save target observable and distinguish a passing state (`savedDb == DB`) from the reported failing state (`savedDb == DEFAULT`). The claims do not assert that `transaction.atomic(using=db)` routes the query. Instead, they model transaction selection as a separate frame condition and make explicit save aliasing the proof-critical transition.

No claim is derived solely from V1 behavior. The key postcondition `savedDb == DB` is derived from `benchmark/PROBLEM.md` and from the source-level fact that `Model.save(using=...)` bypasses router fallback.

## Public Compatibility Audit

The changed call uses an existing keyword parameter on `Model.save()`. The audited source did not change method signatures, operation classes, migration plan structure, signal signatures, or manager APIs. Static searches found the relevant public call path:

- `ContentTypesConfig.ready()` connects `inject_rename_contenttypes_operations` to `pre_migrate`.
- `emit_pre_migrate_signal(..., db, ...)` passes the migration alias as `using`.
- `inject_rename_contenttypes_operations(...)` inserts `RenameContentType` after `RenameModel`.
- `_rename()` obtains the concrete write alias from `schema_editor.connection.alias`.

No compatibility finding blocks V1.
