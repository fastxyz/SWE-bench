# SPEC

Status: constructed, not machine-checked.

## Scope

The audited unit is `SQLInsertCompiler.execute_sql(returning_fields=None)` in
`repo/django/db/models/sql/compiler.py`, plus the observable consumers that
assign its result in `Model._save_table()` and `QuerySet.bulk_create()`.

The proof abstracts SQL execution and backend row fetching as inputs. It checks
the transformation Django applies after the backend returns insert values.

## Intent-Only Spec

1. Insert-returned values for `returning_fields` must be passed through the same
   database converter pipeline used by normal query results.
2. The converter pipeline includes backend converters from
   `connection.ops.get_db_converters(expression)` followed by field converters
   from `expression.get_db_converters(connection)`, including `from_db_value()`.
3. `Model.objects.create()` must assign converted returned values to model
   attributes.
4. `QuerySet.bulk_create()` must assign converted returned values to model
   attributes on backends that return inserted rows.
5. Existing behavior outside insert-returned values must be preserved:
   `execute_sql()` still returns `[]` when there are no `returning_fields`, and
   the no-`RETURNING` fallback still returns only the generated primary key.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "Database converters (from_db_value) not called for returning_fields on insert" | Insert-returned field values must call field converter hooks. | Encoded by PO-001. |
| E-002 | prompt | "unlike all other query pathways" | Insert conversion must use Django's normal query converter pipeline, not a special ad hoc hook. | Encoded by PO-001 and PO-002. |
| E-003 | prompt | `AutoModel.objects.create(); am2.id` displays raw `2` but queried `am.id` displays wrapper | `create()` must assign the converted wrapper value, not the raw integer. | Encoded by PO-003. |
| E-004 | prompt | "This also affects bulk_create on backends that support fetching the primary key value" | `bulk_create()` must assign converted returned primary keys when rows are returned. | Encoded by PO-004. |
| E-005 | implementation | `SQLCompiler.get_converters()` concatenates backend then field converters; `apply_converters()` applies them per row/position. | Formal model must preserve backend-before-field converter order. | Encoded by PO-001. |
| E-006 | implementation | Backend converters inspect `expression.output_field` and Oracle inspects `expression.field`. | Returned fields must be represented as converter-compatible expressions, not raw `Field` objects. | Encoded by PO-002. |
| E-007 | implementation | `last_insert_id()` returns only the generated primary key. | Fallback conversion scope is the primary key column only. | Encoded by PO-005. |
| E-008 | implementation | `bulk_create()` asserts `len(returned_columns)` when rows can be returned. | The compiler result must remain materialized and length-checkable. | Encoded by PO-006. |

The issue's raw integer examples are SUSPECT legacy behavior, not expected
behavior. They are evidence of the bug.

## Formal Model

Let:

- `Rows` be the sequence of rows returned by the backend insert helper.
- `Fields` be the fields corresponding positionally to the returned columns.
- `Expr(f)` be `f.get_col(query_meta.db_table)`.
- `Converters(Expr(f))` be
  `connection.ops.get_db_converters(Expr(f)) + Expr(f).get_db_converters(connection)`.
- `ConvertRow(row, Fields)` apply every converter in `Converters(Expr(Fields[i]))`
  to `row[i]`, left to right.
- `ConvertRows(Rows, Fields)` map `ConvertRow` over every returned row.

The intended postcondition of `execute_sql(returning_fields)` is:

1. If `returning_fields` is falsey, result is `[]`.
2. If bulk insert rows are returned, result is
   `ConvertRows(fetch_returned_insert_rows(cursor), returning_fields)`.
3. If single insert columns are returned, result is
   `ConvertRows([fetch_returned_insert_columns(cursor, returning_params)], returning_fields)`.
4. If no insert `RETURNING` support is available, result is
   `ConvertRows([(last_insert_id(cursor, table, pk_column),)], [pk])`.
5. When conversion occurs, returned rows are materialized as tuples so callers
   still receive a list whose length can be inspected.

## K Claim Paraphrases

The accompanying `fvk/mini-django-insert.k` and
`fvk/django-insert-returning-spec.k` sketch these reachability claims:

- `NO-RETURNING-FIELDS`: no returned fields reaches an empty row list.
- `BULK-RETURNING-CONVERTED`: bulk-returned rows reach `convertRows(rows, fields)`.
- `SINGLE-RETURNING-CONVERTED`: single returned row reaches
  `convertRows(row, fields)`.
- `LAST-ID-CONVERTED-AS-PK`: fallback last-insert-id row reaches conversion using
  the primary-key field only.
- `ASSIGNMENT-CONSUMERS`: model assignment consumes compiler rows positionally;
  therefore if compiler rows are converted, assigned attributes are converted.

## Compatibility Audit

No public method signature changed. `SQLInsertCompiler.execute_sql()` still
accepts the same `returning_fields=None` argument and returns a list. The change
is internal to the returned row values. Public callers discovered in source are
`Model._do_insert()` through `Model._save_table()` and `QuerySet._insert()`
through `_batched_insert()`/`bulk_create()`. Both consume the same row shape as
before.

