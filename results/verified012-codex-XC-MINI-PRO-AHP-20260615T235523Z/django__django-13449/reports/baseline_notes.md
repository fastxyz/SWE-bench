# Baseline Notes

## Root cause

On SQLite, `Func` inherits `SQLiteNumericMixin`, which wraps any expression with
`output_field=DecimalField()` in `CAST(... AS NUMERIC)`. `Lag` is a `Func`, so a
`Window(expression=Lag('decimal_field'))` compiled the inner function as
`CAST(LAG(...) AS NUMERIC)` before `Window.as_sql()` appended the `OVER (...)`
clause. That produced invalid SQL in the form:

```sql
CAST(LAG(...) AS NUMERIC) OVER (...)
```

The `OVER` clause must apply to the window function itself, and the Decimal cast
must wrap the completed window expression instead.

## Changed files

`repo/django/db/models/expressions.py`

Made `Window` inherit `SQLiteNumericMixin` so Decimal-valued window expressions
can be cast by SQLite after the full `... OVER (...)` SQL has been assembled.
Added `Window.as_sqlite()` to special-case Decimal output by compiling a clone
whose inner source expression is temporarily treated as `FloatField()`. This
prevents the inner `Lag`/`Lead`/aggregate function from being cast before
`OVER`, while preserving the outer Numeric cast and the Decimal converter on the
original `Window` expression.

`reports/baseline_notes.md`

Added this required implementation note.

## Assumptions and alternatives considered

Assumed the desired SQLite SQL shape is:

```sql
CAST(LAG(...) OVER (...) AS NUMERIC)
```

Rejected changing `SQLiteNumericMixin` to skip every expression with
`window_compatible=True`. Aggregates are also marked `window_compatible`, and
that broader change would alter existing SQLite Decimal casting for ordinary
aggregate annotations outside a `Window`.

Rejected changing `Lag` or `LagLeadFunction` output-field inference globally,
because the issue is specific to how SQLite compiles Decimal-valued expressions
inside `Window`, not to the logical result type of `Lag`.

No tests or code were run, per the task instructions.
