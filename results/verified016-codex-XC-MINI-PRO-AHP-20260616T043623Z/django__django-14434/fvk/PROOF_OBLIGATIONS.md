# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Explicit-name unique statements reference their unique columns

For all table names `T`, columns `C`, and remaining column lists `CS`:

```text
stmtReferencesColumn(createUniqueV2(T, col(C, CS), explicitName), raw(T), C) == true
```

Evidence: E-001 through E-004.

Discharge: `createUniqueV2` stores `columnsPart(raw(T), col(C, CS))`. `referencesColumn(columnsPart(raw(T), col(C, CS)), raw(T), C)` reduces to `tableKeyEq(raw(T), raw(T)) and contains(C, col(C, CS))`, hence `true`.

## PO-002: Generated-name unique statements also reference their unique columns

For all table names `T`, columns `C`, and remaining column lists `CS`:

```text
stmtReferencesColumn(createUniqueV2(T, col(C, CS), generatedName), raw(T), C) == true
```

Evidence: E-001 through E-004.

Discharge: both `indexNamePart(raw(T), col(C, CS))` and `columnsPart(raw(T), col(C, CS))` satisfy the same raw-table membership condition. The statement-level `or` therefore reduces to `true`.

## PO-003: The V1 explicit-name shape is rejected by the spec

For all table names `T`, columns `C`, and remaining column lists `CS`:

```text
stmtReferencesColumn(createUniqueV1(T, col(C, CS), explicitName), raw(T), C) == false
```

Evidence: E-002, E-003, I-005.

Discharge: V1 stores `columnsPart(wrapped(T), col(C, CS))`. Since `wrapped(T)` and `raw(T)` are distinct constructors, table-key equality is false, so the column reference does not match.

## PO-004: Backend `_index_columns()` compatibility

The `table` argument supplied by `_create_unique_sql()` to `_index_columns()` must be the raw database table name.

Evidence: E-005 and E-006.

Discharge: V2 source sets `table = model._meta.db_table` before the call and passes `self._index_columns(table, ...)`. PostgreSQL's override therefore receives the same raw-name kind as the base implementation.

## PO-005: SQL table rendering remains wrapped and quoted

The `Statement` part used for the SQL `%(table)s` placeholder must still be renderable as a quoted table identifier.

Evidence: I-003 and E-005.

Discharge: V2 source passes `table=Table(table, self.quote_name)` to `Statement(...)`. This preserves the wrapper at the rendering boundary while keeping `TableColumns` parts raw.

## PO-006: Expression and include paths are not regressed

Expression unique statements and included columns must continue to use raw table names in reference-tracking parts.

Evidence: existing source for `Expressions(model._meta.db_table, ...)` and `_index_include_sql()` using `Columns(model._meta.db_table, ...)`.

Discharge: V2 changes `Expressions(model._meta.db_table, ...)` to `Expressions(table, ...)` after setting `table = model._meta.db_table`, which is equivalent. `_index_include_sql()` is untouched.
