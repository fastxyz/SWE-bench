# PROOF

Status: constructed, not machine-checked.

## Machine-Check Commands

These commands are emitted for later validation. They were not run in this session.

```sh
cd fvk
kompile mini-django-sqlite-window.k --backend haskell
kast --backend haskell django-window-sqlite-spec.k
kprove django-window-sqlite-spec.k
```

Expected machine-check result after a functioning K setup: `kprove` discharges the claims to `#Top`.

## Constructed Proof Sketch

### Pre-Fix Failure Path

1. On SQLite, `compiler.compile(Lag('amount'))` dispatches to `Lag.as_sqlite()` because `Lag` inherits `Func`, and `Func` inherits `SQLiteNumericMixin`.
2. `SQLiteNumericMixin.as_sqlite()` calls `Lag.as_sql()` to produce `LAG(amount, 7)`.
3. Because `Lag.output_field` resolves to the source `DecimalField`, `SQLiteNumericMixin` wraps the inner SQL as `CAST(LAG(amount, 7) AS NUMERIC)`.
4. `Window.as_sql()` then inserts that compiled source into the window template, producing `CAST(LAG(amount, 7) AS NUMERIC) OVER (...)`.
5. This matches the issue's reported SQLite syntax error.

This discharges PO-1 and localizes the defect to Decimal casting before `Window` applies `OVER`.

### V1 Decimal Window Path

1. `Window.as_sqlite()` checks `self.output_field.get_internal_type()`.
2. If the `Window` output is `DecimalField`, it clones the `Window`.
3. It obtains the clone's source expressions, replaces the source expression with a clone, and sets the cloned source's `output_field` to `FloatField`.
4. It delegates to `super(Window, clone).as_sqlite()`, i.e. `SQLiteNumericMixin.as_sqlite()` on the cloned `Window`.
5. The mixin calls `clone.as_sql()`.
6. `clone.as_sql()` compiles the cloned source expression. Since that cloned source now has `FloatField` output, the source expression's SQLite mixin does not emit an inner Numeric cast. The source SQL is `LAG(amount, 7)`.
7. `clone.as_sql()` applies the window template, producing `LAG(amount, 7) OVER (...)`.
8. Control returns to `SQLiteNumericMixin.as_sqlite()` for the `Window` clone. The clone's cached `Window.output_field` remains Decimal, so the mixin wraps the completed window SQL as `CAST(LAG(amount, 7) OVER (...) AS NUMERIC)`.

This discharges PO-2 and proves the corrected nesting over the modeled property axis.

### Non-Decimal Window Frame

If `Window.output_field` is not `DecimalField`, `Window.as_sqlite()` returns `self.as_sql(compiler, connection)`. The source expression compiles as before and the window template is unchanged. For the reported FloatField case, the shape remains `LAG(data, 7) OVER (...)`.

This discharges PO-3.

### Standalone Decimal Func Frame

V1 does not change `SQLiteNumericMixin.as_sqlite()`, `Func`, `Aggregate`, `Lag`, or `LagLeadFunction`. A standalone Decimal `Func` still compiles through the original mixin path and keeps `CAST(<func sql> AS NUMERIC)`.

This discharges PO-4 and rejects the broader alternative of skipping all `window_compatible=True` expressions.

### Metadata and Backend Checks

The only `FloatField` assignment is on a cloned source expression, so the original `Window` and source expression metadata are preserved. The Decimal branch reaches `Window.as_sql()` through `SQLiteNumericMixin.as_sqlite()` on the clone, so the `supports_over_clause` check remains in force.

This discharges PO-5 and PO-6.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` matches `fvk/INTENT_SPEC.md` according to `fvk/SPEC_AUDIT.md`. The formal model preserves the only SQL property the issue makes observable: whether the Numeric cast wraps the window expression or the inner function.

## Test Recommendation

No test removal is recommended. The proof is constructed but not machine-checked, and the Django tests for this issue would exercise integration behavior outside the mini-K model. Add or keep tests for:

- Decimal `Lag` inside `Window` on SQLite;
- a Float `Lag` frame case;
- a Decimal aggregate or another Decimal window-compatible expression inside `Window`;
- a standalone Decimal `Func`/aggregate frame case if coverage exists nearby.
