# Public Evidence Ledger

E-001

- Source: prompt issue statement.
- Evidence: "Statement created by _create_unique_sql makes references_column always false"
- Obligation: A `Statement` produced by `_create_unique_sql()` must be able to identify references to its unique columns.
- Status: encoded by PO-001 and PO-002.

E-002

- Source: prompt issue statement.
- Evidence: "This is due to an instance of Table is passed as an argument to Columns when a string is expected."
- Obligation: `Columns(table, ...)` must receive the raw table-name string, not `Table(table, quote_name)`.
- Status: encoded by PO-001, PO-003, and the V2 source edit.

E-003

- Source: `repo/django/db/backends/ddl_references.py`.
- Evidence: `TableColumns.references_column()` returns `self.table == table and column in self.columns`.
- Obligation: A `TableColumns.table` value must be directly comparable to the raw table string passed by `Statement.references_column(model._meta.db_table, field.column)`.
- Status: encoded by PO-001 through PO-003.

E-004

- Source: `repo/django/db/backends/base/schema.py`.
- Evidence: `remove_field()` removes deferred statements when `sql.references_column(model._meta.db_table, field.column)` is true.
- Obligation: Deferred unique statements must return true on removed unique columns so they can be discarded.
- Status: encoded by PO-001 and FINDING F-001.

E-005

- Source: neighboring implementation in `repo/django/db/backends/base/schema.py`.
- Evidence: `_create_index_sql()` uses `table = model._meta.db_table`, passes that raw value to `IndexName`, `_index_columns()`, and `Expressions`, and wraps only the rendered SQL part with `Table(table, self.quote_name)`.
- Obligation: `_create_unique_sql()` should follow the same raw-name-first producer contract.
- Status: encoded by PO-003 and the V2 refactor.

E-006

- Source: `repo/django/db/backends/postgresql/schema.py`.
- Evidence: PostgreSQL overrides `_index_columns()` and returns `IndexColumns(table, columns, ...)`.
- Obligation: The `table` argument supplied by `_create_unique_sql()` must remain the raw table name for backend overrides as well as the base implementation.
- Status: encoded by PO-004.

