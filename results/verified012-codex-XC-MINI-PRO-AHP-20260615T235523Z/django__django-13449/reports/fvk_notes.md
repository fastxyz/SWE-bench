# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a public-intent or proof-obligation failure that justifies another production source edit.

## Trace to Findings and Proof Obligations

Kept the V1 `Window.as_sqlite()` Decimal branch because F1 and PO-2 show it corrects the operative defect: Decimal `Lag` in a SQLite `Window` now compiles as `CAST(LAG(...) OVER (...) AS NUMERIC)` rather than `CAST(LAG(...) AS NUMERIC) OVER (...)`.

Kept the non-Decimal fallback unchanged because F2 and PO-3 show the reported working FloatField path remains `LAG(...) OVER (...)` without an added Numeric cast.

Kept `SQLiteNumericMixin.as_sqlite()` unchanged because F3 and PO-4 show that ordinary Decimal `Func` and `Aggregate` expressions outside `Window` keep their existing SQLite cast behavior. This is why the broader alternative of skipping casts for every `window_compatible=True` expression remains rejected.

Kept the clone-based implementation because F4 and PO-5 show the original `Window` and source expression metadata are not mutated. The temporary `FloatField` assignment is applied only to a cloned source expression used for SQLite SQL rendering.

Confirmed backend and API compatibility based on PO-6 and PO-7: the Decimal branch still reaches `Window.as_sql()` and its `supports_over_clause` check, and the `Window` constructor/signature/call shape is unchanged.

Recorded but did not patch F6 / PO-9. A custom `window_compatible=True` expression whose SQL rendering depends on `output_field` is an underspecified extension-point risk, but the public issue and hint do not require a different mechanism. If that behavior becomes public intent, the next design should consider an internal one-compile cast-suppression flag instead of changing the cloned source output field.

## Validation Status

No tests, Python code, SQLite queries, `kompile`, `kast`, or `kprove` were run, per the task instructions. F5 and PO-8 capture this as an operational validation gap, not a code defect.
