# Baseline notes: django__django-14007

## Issue summary

Database converters — most notably the `from_db_value` hook — are not applied to
the values returned by an `INSERT ... RETURNING` (or `last_insert_id`) for the
fields listed in `returning_fields`. As a result, a custom field such as a
`BigAutoField` subclass that wraps its value via `from_db_value` (e.g.
`MyIntWrapper`) returns the wrapped type on a `SELECT` (`AutoModel.objects.first().id`)
but a bare `int` straight after `create()` / `bulk_create()`
(`AutoModel.objects.create().id`).

## Root cause

`SQLInsertCompiler.execute_sql()` in `django/db/models/sql/compiler.py` fetches the
returned columns directly from the cursor (via
`fetch_returned_insert_rows`, `fetch_returned_insert_columns`, or
`last_insert_id`) and returns them verbatim. Unlike the read path
(`SQLCompiler.results_iter` → `get_converters` / `apply_converters`), it never
runs the values through the field/backend converters, so `from_db_value` (and any
backend `get_db_converters`) is skipped.

The returned values flow into `Model._save_table` (`base.py:874`,
`setattr(self, field.attname, value)`) and `QuerySet.bulk_create`
(`query.py:506`/`520`), which set the attributes as-is — hence the unconverted
values observed on the instances.

## Change made

**File: `django/db/models/sql/compiler.py` — `SQLInsertCompiler.execute_sql`**

- Captured the fetched result into a local `rows` variable for each of the three
  retrieval branches (bulk-return, single column return, and `last_insert_id`)
  instead of returning each one immediately.
- After the cursor block, built a list of `Col` expressions from
  `self.returning_fields` (`field.get_col(opts.db_table)`), obtained converters via
  the inherited `self.get_converters(cols)`, and, when any exist, ran the rows
  through the inherited `self.apply_converters(rows, converters)` before returning.
- Hoisted `opts = self.query.get_meta()` to the top so it can be reused for both
  the `last_insert_id` call and the column construction.

This reuses the exact same converter machinery the SELECT path uses, so both
backend converters (`connection.ops.get_db_converters`) and field converters
(`Field.get_db_converters`, i.e. `from_db_value`) are now applied to inserted
returning fields. It covers `create()`, `save()`, and the
`bulk_create()` path on backends that can return rows.

No other files needed changes: the consumers (`base.py` and `query.py`) already
iterate the rows positionally, so they transparently pick up the converted
values, and they are agnostic to whether each row is a tuple or a list.

## Why `Col` rather than the raw `Field`

`get_converters`/`apply_converters` expect expression-like objects:
`connection.ops.get_db_converters(expression)` reads `expression.output_field`
(see the SQLite/MySQL/Oracle backends), and the field converters come from
`expression.get_db_converters()`. A bare `Field` has no `output_field`, so it
would break on those backends. `field.get_col(opts.db_table)` yields a `Col`
whose `output_field`/`target` is the field itself; `Col.get_db_converters`
delegates to `output_field.get_db_converters` (which returns `[from_db_value]`
when defined). The alias passed to `get_col` is irrelevant here because the `Col`
is only used for converter lookup, never compiled to SQL.

## Assumptions / alternatives considered

- **Applying converters only inside the cursor block / keeping the early
  returns.** Rejected: the fetch helpers eagerly materialize the data
  (`fetchall`/`fetchone`/`last_insert_id`), so converting after the `with` block
  closes the cursor is safe and keeps a single return point that is easy to read.
- **Doing the conversion in the callers (`base.py`, `query.py`).** Rejected:
  that would duplicate the converter-resolution logic in two places, would not
  have access to the compiler's `connection`/`get_converters` helpers as cleanly,
  and would leave any future caller of the insert compiler still receiving raw
  values. Converting at the source (the compiler that produced the values) is the
  minimal, single-point fix and mirrors how the read path works.
- **List vs tuple of the returned rows.** `apply_converters` yields lists,
  whereas the previous code returned tuples in the single-row/`last_insert_id`
  paths. Both consumers only iterate rows positionally, so this is not
  observable. When a field has no converters, `rows` is returned unchanged,
  preserving the prior tuple shape and behavior exactly.
