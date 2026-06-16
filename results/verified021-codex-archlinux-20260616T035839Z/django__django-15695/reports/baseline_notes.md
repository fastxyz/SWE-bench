# Baseline Notes

## Root cause

`RenameIndex.database_backwards()` treated operations created with `old_fields`
as a no-op. That left the database index under `new_name` after reversing the
migration, while the migration state had moved back to an unnamed
`index_together` entry. Re-applying the same `RenameIndex` then found the
existing index by its columns and attempted to rename `new_name` to `new_name`,
which can fail on backends such as PostgreSQL because the target relation name
already exists.

The old unnamed `index_together` name is deterministic: schema creation uses
`SchemaEditor._create_index_name()` with the model table, field columns, and the
`"_idx"` suffix. The reverse operation can therefore restore that generated name
instead of leaving the renamed index in place.

## Changed files

`repo/django/db/migrations/operations/models.py`

Changed `RenameIndex.database_backwards()` for `old_fields` operations so it now:

- Loads the target-state model and respects `allow_migrate_model()`.
- Resolves `old_fields` to database columns on that model.
- Builds an index object for the current `new_name`.
- Builds an index object using the auto-generated `index_together` name from
  `schema_editor._create_index_name(..., suffix="_idx")`.
- Calls `schema_editor.rename_index()` to restore the generated name.

No test files were changed.

## Assumptions and alternatives considered

I assumed `RenameIndex(old_fields=...)` is the migration operation for moving
from an unnamed `index_together` index to a named `Index`, matching the
operation's `state_forwards()` behavior and documentation. Although the issue
text mentions `unique_together`, this operation does not update
`unique_together` state, and its forward path searches for `index=True` rather
than `unique=True`, so broadening it to rename unique constraints would be a
larger behavior change outside the described failing path.

I considered leaving the reverse as a no-op and special-casing the forward path
when the found index already has `new_name`. That would avoid the immediate
rename-to-self crash, but it would still leave the database schema name out of
sync with the reversed migration state. Restoring the deterministic old name
matches the migration state and makes repeated forwards/backwards application
stable.

I did not run tests or project code because the task instructions explicitly
forbid doing so in this session.
