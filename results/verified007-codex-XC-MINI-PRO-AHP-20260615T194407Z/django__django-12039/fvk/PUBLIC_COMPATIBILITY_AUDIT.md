# Public Compatibility Audit

Status: no compatibility break found.

## Changed Symbols

`django.db.backends.ddl_references.Columns.__str__()`

- Signature unchanged.
- Return type remains `str`.
- Public/in-repo call shape unchanged.
- Behavior change is limited to whitespace between quoted column tokens and suffix tokens.

`django.db.backends.ddl_references.IndexColumns.__str__()`

- Signature unchanged.
- Return type remains `str`.
- Constructor signature unchanged.
- Existing PostgreSQL dispatch through `DatabaseSchemaEditor._index_columns()` remains unchanged.
- Behavior change is limited to suppressing empty suffix tokens and joining non-empty tokens with one separator.

## Callsite Review

- `BaseDatabaseSchemaEditor._index_columns()` still constructs `Columns(table, columns, self.quote_name, col_suffixes=col_suffixes)`.
- PostgreSQL `_index_columns()` still constructs `IndexColumns(table, columns, self.quote_name, col_suffixes=col_suffixes, opclasses=opclasses)` only when `opclasses` is truthy.
- `Index.create_sql()` still supplies `col_suffixes` from `fields_orders`.
- No subclass override signature or virtual dispatch shape was changed.

## Compatibility Finding

Direct helper users who pass pre-spaced suffix fragments are outside the evidenced public producer contract. This is tracked as F-4; no source change is made for that case in this pass.
