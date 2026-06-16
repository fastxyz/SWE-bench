# PUBLIC_COMPATIBILITY_AUDIT

Status: source-level compatibility audit, constructed not executed.

## Public API

`QuerySet.bulk_create()` and `QuerySet.abulk_create()` signatures are unchanged.
The accepted public inputs remain model field names for `update_fields` and
`unique_fields`, with the existing `"pk"` alias support for `unique_fields`.

## Internal Producer/Consumer Boundary

`InsertQuery.update_fields` and `InsertQuery.unique_fields` now carry `Field`
objects on the `OnConflict.UPDATE` path. This is an internal Django query object
producer/consumer path from `QuerySet._insert()` to `SQLInsertCompiler`.

The backend hook `connection.ops.on_conflict_suffix_sql()` continues to receive
identifier strings, not `Field` objects. V2 materializes those identifiers as
lists on the update-conflict path and forwards existing values unchanged on
non-update-conflict paths.

## Backend Overrides

Built-in PostgreSQL, SQLite, and MySQL/MariaDB implementations quote the
identifier strings they receive. V2 preserves that contract while correcting the
values to database column names.

No unhandled public method signature, return type, or virtual dispatch shape
change was found in the audited path.
