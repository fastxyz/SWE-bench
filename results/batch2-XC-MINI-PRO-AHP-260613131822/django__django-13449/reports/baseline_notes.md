# Baseline notes — django__django-13449

## Summary of the issue

`Window(expression=Lag('amount', 7), ...)` where `amount` is a `DecimalField`
crashes on SQLite with `OperationalError: near "OVER": syntax error`.

The generated SQL is:

```sql
CAST(LAG("t"."amount", 7) AS NUMERIC) OVER (PARTITION BY ... ORDER BY ...)
```

The `CAST(... AS NUMERIC)` closes right after `LAG(...)`, so the `OVER (...)`
clause ends up *outside* the cast. That is not valid SQL — the `OVER` clause
must directly follow the window function. The correct form is to cast the whole
window expression:

```sql
CAST(LAG("t"."amount", 7) OVER (PARTITION BY ... ORDER BY ...) AS NUMERIC)
```

It only happens for `DecimalField`; `FloatField`/`IntegerField` work, and
passing `output_field=FloatField()` to `Lag` is the user's workaround.

## Root cause

SQLite has no native decimal type, so Django wraps `DecimalField` expressions in
`CAST(... AS NUMERIC)` via `SQLiteNumericMixin.as_sqlite`
(`django/db/models/expressions.py`). That cast forces SQLite to return a numeric
(REAL) value so the Python-side decimal converter
(`SQLiteOperations.get_decimalfield_converter`, which calls
`create_decimal_from_float`) receives a number rather than text.

Inheritance chain of the windowed function:

```
Lag -> LagLeadFunction -> Func(SQLiteNumericMixin, Expression)
```

So `Lag` inherits `SQLiteNumericMixin.as_sqlite`. `Lag('amount')` resolves its
output field to `DecimalField`.

When `Window.as_sql` compiles its source expression
(`expr_sql, params = compiler.compile(self.source_expression)`), the compiler
dispatches to the SQLite-specific `Lag.as_sqlite`, which wraps the function in
`CAST(LAG(...) AS NUMERIC)`. `Window.as_sql` then appends ` OVER (...)` from its
template `'%(expression)s OVER (%(window)s)'`, producing
`CAST(LAG(...) AS NUMERIC) OVER (...)` — the cast wraps only the function, not
the window clause.

The reason `Window` itself never moved the cast to the outside is that `Window`
did **not** inherit from `SQLiteNumericMixin`, so the cast was never applied
around the full `LAG(...) OVER (...)` expression — only the inner function got
(incorrectly) cast.

## Fix

File changed: `django/db/models/expressions.py` (only `Window`; nothing else).

1. `class Window(Expression)` → `class Window(SQLiteNumericMixin, Expression)`
   so a `Window` can cast itself on SQLite.

2. Added `Window.as_sqlite`:

   ```python
   def as_sqlite(self, compiler, connection):
       if self.output_field.get_internal_type() == 'DecimalField':
           copy = self.copy()
           source_expressions = copy.get_source_expressions()
           source_expression = source_expressions[0].copy()
           source_expression.output_field = fields.FloatField()
           source_expressions[0] = source_expression
           copy.set_source_expressions(source_expressions)
           return super(Window, copy).as_sqlite(compiler, connection)
       return self.as_sql(compiler, connection)
   ```

   For a `DecimalField` window expression, it compiles a copy of the window
   whose windowed function (the first source expression) is rewritten to report
   a `FloatField` output. That suppresses the *inner* `SQLiteNumericMixin` cast,
   so the function renders as plain `LAG(...) OVER (...)`. It then delegates to
   `SQLiteNumericMixin.as_sqlite` (via `super(Window, copy)`), which wraps the
   *entire* window expression in `CAST(... AS NUMERIC)`. Result:
   `CAST(LAG(...) OVER (...) AS NUMERIC)`.

   For non-decimal windows it returns `self.as_sql(...)` unchanged, so no cast is
   added (matching the previous, correct behavior).

### Why this works correctly and safely

- `output_field` is a `@cached_property`. Accessing `self.output_field` in the
  `if` guard caches the original `DecimalField` on `self`. The shallow
  `copy.copy(self)` (`BaseExpression.copy`) carries that cached value, so
  `copy.output_field` stays `DecimalField` even after the copy's source is
  swapped to a `FloatField`-typed expression. That is what makes the delegated
  `SQLiteNumericMixin.as_sqlite` apply the *outer* cast.
- The windowed function is copied before its `output_field` is overwritten, so
  the original `Lag`/aggregate instance is **not** mutated (the hint's
  pseudocode mutated shared state via a shallow copy — a bug I deliberately
  avoided).
- `get_source_expressions()` always returns `[source_expression, partition_by,
  order_by, frame]`, so index `0` is always the windowed function — never empty,
  even for arity-0 functions like `Rank()`.
- Only SQLite is affected (`as_sqlite`); other backends keep using `as_sql`.
- Standalone aggregates/functions are untouched: the change lives entirely in
  `Window.as_sqlite`, so e.g. `aggregate(Sum('price'))` still gets its
  `CAST(SUM(...) AS NUMERIC)` from `SQLiteNumericMixin` as before. A windowed
  aggregate over decimals, e.g. `Window(Sum('amount'))`, is also handled the
  same way and yields `CAST(SUM(...) OVER (...) AS NUMERIC)`.

## Alternatives considered and rejected

- **Blanket noop in `SQLiteNumericMixin`** (the hint's first option: make
  `Window` inherit the mixin and make `SQLiteNumericMixin.as_sqlite` skip the
  cast whenever `getattr(self, 'window_compatible', False)`).
  Rejected: `Aggregate` sets `window_compatible = True`
  (`django/db/models/aggregates.py:21`) and inherits `SQLiteNumericMixin`.
  Skipping the cast for every `window_compatible` expression would drop the
  `CAST(... AS NUMERIC)` from ordinary, non-windowed decimal aggregates such as
  `Sum('price')`/`Max('price')`, which the existing aggregation tests rely on.
  On SQLite, `Decimal` is adapted to a string
  (`register_adapter(decimal.Decimal, str)`), so decimal *expression* results
  need the cast to come back as a number for `create_decimal_from_float` to
  work. The hint author flagged this very risk ("make sure window compatible
  functions can be used outside of windows expressions while being wrapped
  appropriately"). The chosen, `Window`-scoped fix avoids the regression.

- **Hint's second option verbatim.** Same overall idea as the implemented fix
  but its pseudocode (`isinstance(self.output_field, 'DecimalField')` and
  mutating `source_expressions[0].output_field` on a shallow copy) is buggy:
  `isinstance` with a string raises `TypeError`, and the shallow copy shares the
  source object, so the mutation would corrupt the original expression. The
  implemented version fixes both (uses `get_internal_type()` and copies the
  source expression before changing its `output_field`).

## Assumptions

- A `Window`'s first source expression is always the windowed function and is
  always `window_compatible` (enforced by `Window.__init__`), so swapping its
  output field to `FloatField` for SQL generation only suppresses the redundant
  inner cast without changing the rendered function SQL (output_field does not
  affect `Func` SQL, only casting/conversion).
- Result conversion is driven by the original `Window` (output_field
  `DecimalField`), which remains in the query's select list; the throwaway copy
  is used only to build SQL, so values still convert to `Decimal`.
