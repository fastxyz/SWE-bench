# Control notes — audit outcome for django__django-13449

## Decision: V1 stands unchanged

The audit (see `review/FINDINGS.md`) found no correctness defect, no regression,
and no convention violation in V1 that warrants a change. No source files were
edited in this pass. Below, every aspect of V1 is traced to the finding that
justifies leaving it as-is, and the one alternative I seriously considered is
traced to the finding that justifies rejecting it.

## Why no change — decision by decision

- **Keep the core mechanism** (re-type the windowed function to `FloatField` on a
  copy, then let `SQLiteNumericMixin` cast the whole `… OVER (…)` clause). Traced
  to **F1**: this produces exactly `CAST(LAG(...) OVER (...) AS NUMERIC)`, the
  valid SQL the report asks for, and removes the invalid
  `CAST(LAG(...) AS NUMERIC) OVER (...)`. Verified by a full compile trace.

- **Keep copying the source expression before re-typing it**
  (`source_expressions[0].copy()`). Traced to **F2**: `Window.copy()` is shallow,
  so mutating `output_field` without this copy would corrupt the original
  expression. V1 already does the right thing here (and fixes the shared-mutation
  bug in the PROBLEM.md hint's pseudocode). Removing the copy would be a
  regression, so it stays.

- **Keep the `super(Window, copy).as_sqlite(...)` delegation** rather than
  inlining the cast. Traced to **F3** and **F11**. F3 verifies that the delegated
  mixin still casts because `copy.output_field` stays `DecimalField` (cached
  `@cached_property`, preserved by `copy.copy`/`__getstate__`, not cleared by
  `set_source_expressions`) — the mechanism is reliable and is the
  maintainer-suggested design. F11 records that the alternative "decide from
  `self`, wrap the copy's SQL inline" form was considered: it would avoid the
  cache reliance but duplicates the `CAST(... AS NUMERIC)` literal and makes the
  `SQLiteNumericMixin` inheritance vestigial, yields byte-identical SQL, and is
  therefore a lateral move, not an improvement. Hence the delegation stays.

- **Keep scoping the fix to `Window.as_sqlite`** (and not touching
  `SQLiteNumericMixin`). Traced to **F6**: `Aggregate` is `window_compatible` and
  shares the mixin, so the hint's first option (a blanket `window_compatible`
  no-op in `SQLiteNumericMixin`) would have dropped the cast from ordinary
  decimal aggregates like `Sum('price')`. The `Window`-scoped approach avoids
  that, and also correctly handles windowed aggregates.

- **Keep the unguarded `self.output_field` access** (no added `try/except
  FieldError`). Traced to **F10**: an unresolvable output field already crashes
  with `FieldError` via `select_format` on both pre-fix and post-fix code, so a
  guard would not change observable behavior; the unguarded pattern matches
  `FixDurationInputMixin.as_mysql`. Adding a guard would be inert churn.

- **Keep the omission of `**extra_context`** in the `as_sqlite` signature. Traced
  to **F12**: the only caller (`compiler.compile`) passes exactly
  `(compiler, connection)`, and `Window.as_sql` takes `template=None` rather than
  `**extra_context`, so adding it would be unused and could only forward keys
  `Window.as_sql` cannot accept. The signature matches how the method is invoked.

- **Keep the local name `copy`** (shadowing the `copy` module). Traced to **F12**:
  it matches the existing `Func.copy` idiom in the same file and is safe because
  the module is not referenced inside the method.

- **Keep `class Window(SQLiteNumericMixin, Expression)`**. Traced to **F1/F3/F11**:
  the inheritance is load-bearing (the `super(Window, copy).as_sqlite` call reuses
  the mixin's cast), so it is not vestigial and should remain.

## Regression review summary (no changes needed)

- Non-decimal windows and existing `expressions_window` tests: unaffected (**F4**).
- Other backends (PostgreSQL/MySQL/Oracle): unaffected — `as_sqlite` is SQLite-only
  (**F5**).
- Standalone and windowed aggregates: unaffected / correctly handled (**F6**).
- `PARTITION BY` / `ORDER BY` columns: compiled identically to pre-fix (**F7**).
- Query parameters: order/count preserved (**F8**).
- Result conversion: driven by the original `DecimalField` node; the copy is
  discarded (**F9**). Repeated compilation (e.g. `repr` then iterate) is safe
  because V1 never mutates `self` (**F2**).
- No alternate compile path bypasses `as_sqlite` (**F13**).

## Conclusion

The review confirms V1 is a correct, minimal, regression-free implementation of
the intended fix. The change is left exactly as in V1; `reports/baseline_notes.md`
remains an accurate description of it.
