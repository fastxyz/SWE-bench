# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Lag() with DecimalField crashes on SQLite." | SQLite compilation of Decimal `Lag` inside `Window` is in scope. | Encoded in `DECIMAL-LAG-WINDOW` claim. |
| E2 | `benchmark/PROBLEM.md` | Generated SQL: `CAST(LAG(...) AS NUMERIC) OVER (...)`. | This nesting is the bad pre-fix behavior and must not be preserved. | Finding F1; excluded from spec as SUSPECT legacy output. |
| E3 | `benchmark/PROBLEM.md` | "CAST() statement ends after LAG whereas it should be around the whole statement up until 'w'." | Expected nesting is `CAST(LAG(...) OVER (...) AS NUMERIC)`. | Encoded in `DECIMAL-LAG-WINDOW`. |
| E4 | `benchmark/PROBLEM.md` | `Lag('data', 7)` with `FloatField` works correctly. | Non-Decimal path is a frame condition: keep existing uncast window SQL. | Encoded in `FLOAT-LAG-WINDOW`. |
| E5 | Public hint | "Likely an issue due to SQLiteNumericMixin." | Root cause must be checked at SQLite expression compilation, not model fields or DB execution. | Used in proof localization. |
| E6 | Public hint | Alternative `Window.as_sqlite` special-casing Decimal avoids teaching `SQLiteNumericMixin` about window functions and preserves outside-window wrapping. | Preserve ordinary `Func`/`Aggregate` Decimal casting outside `Window`. | Encoded in `STANDALONE-DECIMAL-FUNC`. |
| E7 | `repo/django/db/models/expressions.py` | `Func(SQLiteNumericMixin, Expression)` and `Window.as_sql()` compiles `source_expression` before appending `OVER`. | Implementation fact explaining pre-fix failure path. | Used in proof, not as expected behavior. |
| E8 | V1 source | `Window(SQLiteNumericMixin, Expression)` and `Window.as_sqlite()` clones source, forces cloned source output to `FloatField`, then delegates to `SQLiteNumericMixin`. | Candidate mechanism should produce outer cast while suppressing inner cast. | Encoded in mini-K semantics and proof obligations. |
