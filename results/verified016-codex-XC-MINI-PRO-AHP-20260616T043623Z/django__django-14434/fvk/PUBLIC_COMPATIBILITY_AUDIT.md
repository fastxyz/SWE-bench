# Public Compatibility Audit

Status: source audit only; no code or tests executed.

## Changed public symbols

No public symbol signature changed.

`BaseDatabaseSchemaEditor._create_unique_sql()` keeps the same parameters and still returns either `None` or a `Statement`.

`BaseDatabaseSchemaEditor._index_columns()` keeps the same call shape.

## Callers

The edited function is called internally by schema-editor paths that create field uniqueness, `unique_together`, and `UniqueConstraint` SQL. The return shape remains a `Statement`, so callers do not require changes.

## Overrides

`django/db/backends/postgresql/schema.py` overrides `_index_columns(table, columns, col_suffixes, opclasses)` and forwards `table` into `IndexColumns`. The V2 source passes the raw table name string, matching `_create_index_sql()` and the base `Columns` contract.

No override of `_create_unique_sql()` was found in `repo/django/db/backends`.

## Producer/consumer protocol

Producer: `_create_unique_sql()` now sets `table = model._meta.db_table`, passes that raw value to `IndexName`, `_index_columns()`, and `Expressions`, and wraps it as `Table(table, self.quote_name)` only for the rendered SQL `table` part.

Consumer: `Statement.references_column(table, column)` delegates to parts with `references_column()`. `TableColumns.references_column()` compares `self.table == table`, so producer and consumer now agree on raw table names.

## Compatibility conclusion

The refactor is compatible with existing callers and backend overrides. It narrows the internal value type supplied to `TableColumns` subclasses back to the already-established raw-name protocol.

