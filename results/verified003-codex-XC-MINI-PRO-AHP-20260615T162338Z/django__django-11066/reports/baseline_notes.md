# Baseline Notes

## Root cause

`RenameContentType._rename()` correctly derives the migration database alias from `schema_editor.connection.alias`, checks routing for that alias, reads the existing `ContentType` through `ContentType.objects.db_manager(db)`, and wraps the update in `transaction.atomic(using=db)`. However, the actual `content_type.save()` call did not pass `using=db`.

`transaction.atomic(using=db)` controls the transaction connection but does not route model writes. Without `save(using=db)`, the save path can consult routing/default database behavior and write to the wrong connection. In a dynamic multi-database setup where the default database does not contain `django_content_type`, this causes the rename migration to fail against the default database instead of updating the content type on the migration database.

## Changed files

`repo/django/contrib/contenttypes/management/__init__.py`

Changed `content_type.save(update_fields={'model'})` to `content_type.save(using=db, update_fields={'model'})` inside `RenameContentType._rename()`. This keeps the write on the same database alias used for the schema editor, route check, content type lookup, and transaction.

## Assumptions

The intended database for content type rename updates is the same alias used by the migration schema editor. This matches the rest of the function, which already uses that alias for `allow_migrate_model()`, the content type lookup, and the transaction.

The existing `IntegrityError` handling and cache clearing behavior should remain unchanged. The fix only changes which database connection receives the save.

## Alternatives considered

One alternative was to rely on `transaction.atomic(using=db)` to select the target database. I rejected this because `atomic()` manages transaction state for the given connection; it does not override model save routing.

Another alternative was to use `ContentType.objects.using(db).filter(...).update(model=new_model)`. I rejected this because the existing instance save preserves the current control flow, `IntegrityError` fallback, and cache behavior with the smallest targeted change.
