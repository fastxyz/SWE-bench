# FINDINGS

Status: constructed, not machine-checked.

## F1 - Fixed Code Bug: Bad CAST/OVER Nesting

Evidence: INT-1, INT-2; proof obligation PO-1 and PO-2.

Input: SQLite compilation of `Window(expression=Lag('amount', 7))` where `amount` is a `DecimalField`.

Pre-fix observed behavior: `CAST(LAG(amount, 7) AS NUMERIC) OVER (...)`.

Expected behavior: `CAST(LAG(amount, 7) OVER (...) AS NUMERIC)`.

Audit result: V1 removes the bad nesting. Decimal `Window` compilation now forces only the cloned inner source to non-Decimal for the inner compile, then applies `SQLiteNumericMixin` to the completed window SQL. No further source edit is required for this finding.

## F2 - Confirmed Frame: FloatField Window Behavior

Evidence: INT-3; proof obligation PO-3.

Input: SQLite compilation of `Window(expression=Lag('data', 7))` where `data` is a `FloatField`.

Expected behavior: keep `LAG(data, 7) OVER (...)` without Numeric cast.

Audit result: V1 preserves this. `Window.as_sqlite()` falls back to `as_sql()` when `Window.output_field` is not `DecimalField`.

## F3 - Confirmed Frame: Standalone Decimal Func/Aggregate Casting

Evidence: INT-4; proof obligation PO-4.

Input: SQLite compilation of a Decimal-valued `Func` or `Aggregate` outside `Window`.

Expected behavior: preserve existing `SQLiteNumericMixin` behavior, e.g. `CAST(<func sql> AS NUMERIC)`.

Audit result: V1 preserves this because it does not change `SQLiteNumericMixin.as_sqlite()`. This avoids the broader alternative of skipping all `window_compatible=True` expressions, which would affect ordinary aggregates.

## F4 - Confirmed Frame: Original Expression Metadata Is Not Mutated

Evidence: INT-5; proof obligation PO-5.

Input: A Decimal `Window` expression reused after SQLite compilation.

Expected behavior: original `Window` and source expression still expose their original Decimal output metadata and converters.

Audit result: V1 satisfies this by cloning the `Window` and the source expression before assigning `FloatField` to the cloned source. The original expression is not modified by the V1 code path.

## F5 - Residual Test/Machine-Check Gap

Evidence: task prohibition on execution; proof obligation PO-8.

Input: Any runtime SQLite query using the audited path.

Observed in this session: no tests, Python code, SQLite execution, `kompile`, or `kprove` were run.

Expected next validation: run the emitted FVK commands and Django tests in an environment that permits execution.

Audit result: This is not a code bug. It is the required honesty caveat: proof is constructed but not machine-checked.

## F6 - Residual Compatibility Risk: Custom Output-Field-Dependent Window Expressions

Evidence: proof obligation PO-9.

Input: A custom third-party `window_compatible=True` expression whose `as_sql()` intentionally changes SQL text based on `self.output_field`.

Expected behavior from public Django contract: not specified by the issue or public hint.

Audit result: V1 temporarily changes the cloned source's output field to `FloatField` during SQLite compilation. This matches the public hint and is limited to a clone, but a custom expression that renders SQL differently based on output field could observe a different inner SQL during Decimal `Window` compilation. No source change is justified by public evidence; record as residual risk only.
