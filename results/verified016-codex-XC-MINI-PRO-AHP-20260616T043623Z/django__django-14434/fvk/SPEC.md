# FVK Spec

Status: constructed, not machine-checked.

## Target

The target behavior is the reference-tracking part of `_create_unique_sql()`: for every unique statement over a raw database table name `T` and non-empty unique column list `CS`, the returned `Statement` must answer true when asked whether it references any `C` in `CS`.

This spec models only the DDL-reference object graph needed for that property:

- `raw(T)` represents the string `model._meta.db_table`.
- `wrapped(T)` represents a `Table(T, quote_name)` object.
- `columnsPart(K, CS)` represents a `Columns` or `IndexColumns` object storing table key `K`.
- `indexNamePart(K, CS)` represents an `IndexName` object.
- `tablePart(K)` represents a renderable SQL table placeholder.
- `stmt(parts)` represents a `Statement`.

The formal model intentionally distinguishes `raw(T)` from `wrapped(T)` because that is the bug's observable axis. A model that collapsed them would be unable to distinguish the failing V1 shape from the passing V2 shape.

## Public Intent Ledger

The public evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are:

- E-001 and E-004 require `_create_unique_sql()` statements to return true from `references_column(T, C)` for unique columns.
- E-002 and E-003 require `TableColumns.table` to be a raw table name, not a `Table` object.
- E-005 requires `_create_unique_sql()` to follow the same raw-name-first construction pattern as `_create_index_sql()`.
- E-006 requires the same raw-name argument for backend `_index_columns()` overrides.

## Function Contract

For any table name `T`, any column `C`, and any remaining columns `CS`, the V2 constructor:

```text
createUniqueV2(T, col(C, CS), explicitName)
```

must produce a statement for which:

```text
stmtReferencesColumn(statement, raw(T), C) == true
```

The same obligation holds for:

```text
createUniqueV2(T, col(C, CS), generatedName)
```

The explicit-name claim is important because a quoted explicit name has no `references_column()` behavior; the unique columns part must carry the reference correctly by itself.

## Frame Conditions

The rendered SQL `table` placeholder must still use a `Table`-like wrapper. In the model this is represented by `tablePart(raw(T))`, and in code by `table=Table(table, self.quote_name)`.

No public signature changes are allowed. The internal refactor must preserve:

```text
_create_unique_sql(self, model, columns, name=None, condition=None,
                   deferrable=None, include=None, opclasses=None,
                   expressions=None)
```

and:

```text
_index_columns(self, table, columns, col_suffixes, opclasses)
```

## K Artifacts

- Semantics fragment: `fvk/mini-ddl-references.k`
- Claims: `fvk/schema-unique-spec.k`

