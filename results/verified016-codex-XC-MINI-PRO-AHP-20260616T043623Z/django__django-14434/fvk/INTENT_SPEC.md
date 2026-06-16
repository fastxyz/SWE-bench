# Intent Spec

Status: constructed from public issue text and in-repository source only.

## Scope

Target unit: `BaseDatabaseSchemaEditor._create_unique_sql()` as it constructs a `Statement` containing `ddl_references` parts, plus the `Statement.references_column()` and `TableColumns.references_column()` protocol that later removes deferred SQL referencing a deleted column.

Verified domain:

- The backend feature gates allow `_create_unique_sql()` to return a `Statement`, not `None`.
- The `columns` argument is non-empty, so `_create_unique_sql()` uses `_index_columns()`.
- The queried column is one of those unique columns.
- Both explicit-name and generated-name unique statements remain in scope.

Expression-based unique indexes and included columns are compatibility/frame conditions, not the primary bug path.

## Intent-Only Obligations

I-001: A unique `Statement` created for table `T` and unique column list `CS` must report `references_column(T, C) == True` for every `C` in `CS`.

I-002: `Columns` and other `TableColumns` subclasses store a raw database table name for reference tracking. They must not receive a renderable `Table` object in place of that table name.

I-003: SQL rendering must still receive a `Table` wrapper for the `%(table)s` placeholder so quoting behavior remains unchanged.

I-004: The fix must not change public method signatures, return type, or backend override protocol. `_index_columns(table, columns, col_suffixes, opclasses)` must continue to receive the same kind of `table` value used by `_create_index_sql()`.

I-005: The audit must not preserve the reported legacy behavior. The issue says the legacy `Statement.references_column()` result is the bug, so that behavior is suspect evidence, not a specification.

