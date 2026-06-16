# Baseline Notes

## Root cause

`BaseDatabaseSchemaEditor._create_unique_sql()` creates a `Table` reference object for the SQL statement's table placeholder, then reused that `Table` object when constructing the `Columns` reference for unique constraints and unique indexes.

`Columns` inherits `TableColumns.references_column()`, which expects `self.table` to be the raw database table name string. Because `self.table` was instead a `Table` instance, `Statement.references_column(model._meta.db_table, field.column)` could never match the unique statement's columns. As a result, deferred unique SQL could remain in `deferred_sql` even when the referenced column was removed.

## Changed files

`repo/django/db/backends/base/schema.py`

Changed `_create_unique_sql()` so `_index_columns()` receives `model._meta.db_table`, matching the contract used by `_create_index_sql()` and by `Columns.references_column()`. The `Statement` still receives the `Table` object for the rendered SQL `table` placeholder.

## Assumptions and alternatives

I assumed the intended invariant is that `Table` objects are only used for renderable table placeholders, while `TableColumns` subclasses store raw table names for reference tracking. This is consistent with `_create_index_sql()`, `_create_fk_sql()`, `Expressions`, and `IndexName`.

An alternative would have been to make `TableColumns.references_column()` unwrap or compare `Table` instances. I rejected that because it broadens a narrow bug into a shared helper behavior change, and it would make `TableColumns.table` accept mixed types despite the existing call sites consistently passing raw table names.

I did not modify tests or run tests/project code, per the task constraints.
