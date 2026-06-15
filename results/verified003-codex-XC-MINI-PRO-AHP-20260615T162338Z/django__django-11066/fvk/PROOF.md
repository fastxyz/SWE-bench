# FVK Proof

Status: constructed, not machine-checked.

## Claim Under Proof

For `RenameContentType._rename()`, when a migration runs on database alias `db = schema_editor.connection.alias`, any successful content type model rename save must write to `db`.

The proof is partial correctness: if `_rename()` reaches its normal save path and the save succeeds, the database alias used for the write equals `db`. Termination is not separately proved; the audited function contains no loop or recursion.

## Supporting Formal Core

The formal core is represented by:

- `fvk/mini-rename-contenttype.k`
- `fvk/rename-contenttype-spec.k`

The model abstracts Django objects into the state needed for this issue:

- content type rows keyed by `(database alias, app label, model name)`;
- a migration-allowed map;
- a router-selected write alias used only by the pre-fix variant;
- a `savedDb` observable recording the target of the save.

This abstraction distinguishes the reported failure (`savedDb = "default"`) from the intended behavior (`savedDb = db`).

## Proof Sketch

1. `_rename()` binds `db = schema_editor.connection.alias`. By PO-1, this is the intended database alias for the content type rename.

2. If `router.allow_migrate_model(db, ContentType)` is false, the function returns before lookup or save. This discharges PO-4.

3. If migration is allowed, the lookup uses `ContentType.objects.db_manager(db).get_by_natural_key(...)`. `db_manager(db)` sets the manager database, so lookup remains scoped to `db`. This discharges PO-5.

4. If the old content type is missing, `ContentType.DoesNotExist` is caught and no save occurs. This discharges PO-6.

5. If the old content type exists, `_rename()` sets `content_type.model = new_model` and enters `transaction.atomic(using=db)`. The transaction context binds transaction state to `db`, but does not route model writes. This is why PO-2 is necessary.

6. V1 calls `content_type.save(using=db, update_fields={'model'})`. In `Model.save()`, `using = using or router.db_for_write(...)`; because `using` is already `db`, router fallback is skipped. In `_save_table()`, the update uses `cls._base_manager.using(using)`, so the SQL update target is `db`. This discharges PO-3.

7. If the update raises `IntegrityError`, the existing exception handler restores `content_type.model = old_model` and skips the success cache clear path. V1 does not alter this behavior. This discharges PO-7.

8. `Model.save()` already accepts `using` and `update_fields`, and the patch changes no public signature. This discharges PO-8.

Therefore V1 satisfies the public intent: the successful rename save is performed on `schema_editor.connection.alias`, and the previously reported default-database write is eliminated.

## Counterexample for the Pre-Fix Code

Pre-fix state:

- `db = "tenant"`
- `router.db_for_write(ContentType, instance=content_type) = "default"`
- the content type row exists on `"tenant"`
- the `"default"` database has no `django_content_type` table

Pre-fix transition:

```python
with transaction.atomic(using=db):
    content_type.save(update_fields={'model'})
```

Because `save()` receives no `using`, `Model.save()` may select `"default"` through the router. The write target is `"default"`, violating PO-1 and producing the reported `OperationalError`.

V1 transition:

```python
with transaction.atomic(using=db):
    content_type.save(using=db, update_fields={'model'})
```

The save target is `"tenant"` regardless of router fallback.

## Commands to Machine-Check Later

These commands are recorded for a future environment with K installed. They were not run in this session.

```sh
kompile fvk/mini-rename-contenttype.k --backend haskell
kast --backend haskell fvk/rename-contenttype-spec.k
kprove fvk/rename-contenttype-spec.k
```

Expected result after machine checking: `#Top` for the V1 claims, and a failing counterexample for the pre-fix claim if asserted as the intended postcondition.

## Test Guidance

Do not remove tests based on this constructed proof. A useful public regression test would configure a router that would route writes to `"default"` unless `using` is explicit, run a `RenameModel` migration on another alias, and assert that the content type row is renamed on that alias without touching `"default"`.
