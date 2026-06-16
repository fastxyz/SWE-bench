# Intent Spec

Status: constructed, not machine-checked.

1. On SQLite, `Window(expression=Lag(<DecimalField>, ...))` must not generate SQL where `OVER (...)` follows `CAST(LAG(...) AS NUMERIC)`. The public issue reports that shape as the crash.

2. For Decimal-valued window expressions on SQLite, the Numeric cast must wrap the completed window expression: `CAST(<window function> OVER (...) AS NUMERIC)`.

3. Non-Decimal window expressions, including the reported FloatField example, must keep the existing working `LAG(...) OVER (...)` shape without adding a Numeric cast.

4. Existing SQLite Decimal casting for expressions outside `Window` must be preserved. The public hint explicitly warns that window-compatible functions should remain wrapped appropriately outside window expressions.

5. The fix must not mutate user-visible expression metadata or public method signatures. It should be a compilation-time adjustment for SQLite SQL generation only.

6. Backend feature checks, including `supports_over_clause`, must continue to run before a backend emits window SQL.
