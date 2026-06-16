# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Converter Pipeline

For each returned row position `i`, if a field `f = fields[i]` has backend
converters `B` and field converters `F`, the output value at position `i` is the
result of applying every converter in `B + F` to the raw returned value in order.

Trace: E-001, E-002, E-005, F-001.

## PO-002: Converter Expression Shape

For each returned field `f`, the expression passed to `get_converters()` is
`f.get_col(query_meta.db_table)`, so backend converters can inspect
`output_field` and `field` and field converters are obtained through the same
`Col.get_db_converters()` path used by normal query conversion.

Trace: E-005, E-006, F-002.

## PO-003: `create()` Assignment

If `Model._save_table()` receives `results = [[v0, ...]]` from `_do_insert()`,
then for every returned field position assigned by
`zip(results[0], returning_fields)`, the assigned value is already converted by
PO-001.

Trace: E-003, F-001.

## PO-004: `bulk_create()` Assignment

If `_batched_insert()` receives rows from `_insert()` on a backend with
`can_return_rows_from_bulk_insert`, then every value assigned in
`bulk_create()` from `zip(results, opts.db_returning_fields)` is already
converted by PO-001.

Trace: E-004, F-001.

## PO-005: Last Insert ID Fallback Scope

When the backend does not return insert columns, `execute_sql()` obtains only
`last_insert_id(cursor, table, pk_column)`. The converter field list for that
one-column row is exactly `[query_meta.pk]`.

Trace: E-007, F-003.

## PO-006: Result Shape Compatibility

`execute_sql()` returns a materialized list in all paths:

- `[]` with no `returning_fields`;
- a list of row tuples after row fetching and conversion;
- a one-row list for single-column fallback.

This preserves `bulk_create()` length checks and positional zipping.

Trace: E-008, F-004.

## PO-007: No-Returning Frame Condition

When `returning_fields` is falsey, the compiler returns `[]` and does not call
the converter pipeline.

Trace: E-005 and compatibility audit.

## PO-008: Public Compatibility

No public signature, override protocol, or caller-visible row container protocol
changes. Only row values are converted according to public issue intent.

Trace: compatibility audit in `SPEC.md`, F-005.

