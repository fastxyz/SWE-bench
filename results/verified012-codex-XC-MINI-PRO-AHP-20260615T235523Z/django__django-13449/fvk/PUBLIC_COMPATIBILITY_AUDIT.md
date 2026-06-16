# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `django.db.models.expressions.Window`.

Compatibility results:

1. Constructor signature unchanged: `Window(expression, partition_by=None, order_by=None, frame=None, output_field=None)`.

2. Public rendering behavior on non-SQLite backends unchanged: only `as_sqlite()` was added and the class inherited `SQLiteNumericMixin`.

3. Public rendering behavior on SQLite non-Decimal windows unchanged: `Window.as_sqlite()` falls back to `self.as_sql()` unless `Window.output_field` resolves to `DecimalField`.

4. Existing standalone `Func` and `Aggregate` SQLite Decimal casting unchanged: `SQLiteNumericMixin.as_sqlite()` was not modified.

5. Public in-repo subclass/override search found no subclasses of `Window` and no direct public calls to `Window.as_sqlite()` with custom arguments.

6. `Window.as_sql()` still performs `connection.ops.check_expression_support(self)` and `supports_over_clause` checks; the Decimal SQLite branch reaches the same check via `clone.as_sql()`.

Conclusion: no public API or override incompatibility was found.
