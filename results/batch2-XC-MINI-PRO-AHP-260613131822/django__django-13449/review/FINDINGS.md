# Code review — V1 fix for django__django-13449

V1 changes, both in `django/db/models/expressions.py`:
1. `class Window(Expression)` → `class Window(SQLiteNumericMixin, Expression)`.
2. New `Window.as_sqlite` that, for a `DecimalField` output, compiles a copy of
   the window whose windowed function is re-typed to `FloatField` (suppressing
   the per-function `CAST`) and delegates to `SQLiteNumericMixin.as_sqlite`
   (via `super(Window, copy)`) so the cast wraps the whole `… OVER (…)` clause.

Each finding has a severity and a verdict (KEEP = no change needed / justified to
stand; FIX = change required).

---

## F1 — Correctness against the issue (the core bug). Severity: n/a. Verdict: KEEP

Traced the SQLite compile path for
`Window(Lag('amount', 7), partition_by=[F('modified')], order_by=F('modified').asc())`
with `amount = DecimalField`:

- `compiler.compile(window)` dispatches to `Window.as_sqlite` (vendor `sqlite`,
  `compiler.py:426`).
- `self.output_field` resolves to `DecimalField` (via `_resolve_output_field` →
  `source_expression.output_field` → `Lag.output_field` → the `amount` column),
  so the decimal branch runs.
- The windowed function copy is re-typed to `FloatField`, so its inherited
  `SQLiteNumericMixin.as_sqlite` does **not** wrap it → `LAG("amount", 7)`.
- `Window.as_sql` produces `LAG("amount", 7) OVER (PARTITION BY … ORDER BY … ASC)`.
- `SQLiteNumericMixin.as_sqlite` (called on the copy, whose cached
  `output_field` is still `DecimalField`) wraps the whole thing:
  `CAST(LAG("amount", 7) OVER (…) AS NUMERIC)`.

This is exactly what the report asks for ("it should be around the whole
statement up until w"). `CAST(<window-function> OVER (…) AS NUMERIC)` is valid
SQLite (`CAST(expr AS type)` accepts any expression, including a window
expression). The original invalid SQL (`CAST(LAG(...) AS NUMERIC) OVER (...)`) is
gone. **Correct.**

## F2 — Source expression is copied before mutation (avoids shared-state corruption). Severity: n/a. Verdict: KEEP (this is a real improvement over the hint)

`Window.copy()` is `copy.copy(self)` (shallow, `expressions.py:346`), so
`copy.source_expression` is the *same* object as `self.source_expression`. V1
calls `source_expressions[0].copy()` and mutates the **copy's** `output_field`,
leaving the original `Lag`/aggregate untouched. The PROBLEM.md hint's pseudocode
wrote `source_expressions[0].output_field = FloatField()` directly on the shared
shallow copy, which would permanently corrupt the original expression's output
field. V1 correctly avoids this. **Keep.**

## F3 — Correctness depends on `output_field` being cached and surviving the copy. Severity: Low. Verdict: KEEP (reliable, by-design)

V1 relies on this chain: line `if self.output_field.get_internal_type() == …`
resolves and caches `output_field` on `self` (`@cached_property`,
`expressions.py:263`); `copy.copy(self)` reproduces `self.__dict__` (via
`BaseExpression.__getstate__`, which only drops `convert_value`,
`expressions.py:166-169`), so the copy inherits the cached `DecimalField`;
`set_source_expressions` reassigns the source attribute but does not clear the
cached `output_field`. Therefore `copy.output_field` remains `DecimalField`
inside the delegated mixin even after the source is re-typed to `FloatField`.

Verified each link holds in the current code, so V1 is correct. The reliance is
non-local (changing the *source's* output field but expecting the *window's*
output field to be unaffected works only because of the cache). This is exactly
the mechanism the PROBLEM.md hint's "alternative" proposed (`super(Window, copy)
.as_sqlite(...)`), i.e. it is the intended, maintainer-blessed design. I weighed
restructuring to a "decide from `self`, wrap the copy's SQL manually" form (which
would not depend on the cache) but rejected it (see F11). **Keep.**

## F4 — No regression for non-`DecimalField` windows. Severity: n/a. Verdict: KEEP

For `FloatField`/`IntegerField` windows (e.g. `Lag('data')`, `Rank()`,
`RowNumber()`), `self.output_field.get_internal_type() != 'DecimalField'`, so
`as_sqlite` returns `self.as_sql(compiler, connection)` — identical SQL to
pre-fix. Existing `expressions_window` tests use `Lag('salary')`/`Lead('salary')`
over a `PositiveIntegerField` (`tests/expressions_window/models.py`), so they
take this branch and are unaffected. **No regression.**

## F5 — No regression for other database backends. Severity: n/a. Verdict: KEEP

`as_sqlite` is only dispatched for `connection.vendor == 'sqlite'`
(`compiler.py:426`). PostgreSQL/MySQL/Oracle continue to use `Window.as_sql`
(no `as_<vendor>` override for them), producing `LAG(...) OVER (...)` exactly as
before. Those backends have native numeric types and don't need the cast.
**No regression.**

## F6 — No regression for standalone aggregates / windowed aggregates. Severity: n/a. Verdict: KEEP

`Aggregate` is `window_compatible = True` and inherits
`SQLiteNumericMixin.as_sqlite` (`aggregates.py:16-21`). V1 deliberately scopes
its change to `Window.as_sqlite` only, so standalone decimal aggregates such as
`aggregate(Sum('price'))` still get `CAST(SUM("price") AS NUMERIC)` from the
unchanged mixin (important on SQLite, where `Decimal` is stored as text via
`register_adapter(decimal.Decimal, str)` and the result converter expects a
number). A windowed aggregate over decimals, e.g. `Window(Sum('amount'))`, is
handled identically to `Lag`: `CAST(SUM(...) OVER (...) AS NUMERIC)`. This is
why V1 chose the `Window`-scoped approach over the hint's first option (a blanket
`window_compatible` no-op in `SQLiteNumericMixin`), which would have dropped the
cast from ordinary aggregates. **No regression; the right design choice.**

## F7 — `PARTITION BY` / `ORDER BY` source expressions are untouched. Severity: n/a. Verdict: KEEP

V1 only re-types `source_expressions[0]` (the windowed function). Indexes 1–3
(`partition_by`, `order_by`, `frame`) are reassigned unchanged via
`set_source_expressions`, so their compilation (including any decimal partition
columns) is byte-for-byte identical to pre-fix. **No regression.**

## F8 — Parameter list integrity. Severity: n/a. Verdict: KEEP

The offset (`Lag('amount', 7)`) becomes `Value(7)` (`_parse_expressions`,
`expressions.py:184-189`). Params flow `Lag.as_sql → Window.as_sql →
SQLiteNumericMixin.as_sqlite`, and the cast only string-wraps the SQL
(`'CAST(%s AS NUMERIC)' % sql`) without touching `params`. Order and count are
preserved. **Correct.**

## F9 — Result conversion still uses the original (DecimalField) node. Severity: n/a. Verdict: KEEP

`get_select` keeps the original `Window` (`col`) in the select list and
`get_converters` builds converters from it (`compiler.py:260-268, 1090-1098`).
The throwaway copy made inside `as_sqlite` only generates SQL; it is never in the
select list, so its `FloatField`-typed source never affects conversion. The
original `Window.output_field` is `DecimalField`, so the SQLite decimal converter
(`operations.py:296-310`) runs and the `CAST(... AS NUMERIC)` guarantees the value
arrives numeric (not text), which is what `create_decimal_from_float` needs.
**Correct.**

## F10 — Error handling: unguarded `self.output_field` access. Severity: Low. Verdict: KEEP

`SQLiteNumericMixin.as_sqlite` guards its `output_field` access with
`try/except FieldError`; V1's top-level `if self.output_field.get_internal_type()`
is not guarded. If a window's output field were unresolvable, V1 would raise
`FieldError` here. This is **not** a regression: `select_format`
(`compiler.py:380-387`) accesses `self.output_field` immediately after compiling
the column, so an unresolvable-output window already crashes with `FieldError`
on both pre-fix and post-fix code — only the crash location differs slightly.
The pattern of accessing `output_field` unguarded inside an `as_<vendor>` method
already exists (`FixDurationInputMixin.as_mysql`, `mixins.py:27`). Adding a
`try/except` would not change observable behavior, so it is omitted. **Keep.**

## F11 — Alternative implementation (manual wrap) considered and rejected. Severity: n/a. Verdict: KEEP V1

Considered replacing the `super(Window, copy)` delegation with: decide from
`self.output_field`, compile the re-typed copy via `copy.as_sql(...)`, and wrap
the result inline with `'CAST(%s AS NUMERIC)'`. Pros: correctness no longer
depends on the cache invariant (F3); fully local reasoning. Cons: duplicates the
`CAST(... AS NUMERIC)` literal already owned by `SQLiteNumericMixin` (DRY), and
makes the `SQLiteNumericMixin` inheritance vestigial (no `super` call), inviting a
later "why inherit it?" churn. Because it produces byte-identical SQL and the
cache invariant in F3 is stable and intended, this is a lateral move, not an
improvement. **Rejected; V1 stands.**

## F12 — Consistency with conventions. Severity: Low. Verdict: KEEP

- Local variable name `copy` shadows the `copy` module but matches the existing
  idiom in this file (`Func.copy`, `expressions.py:700-703`, does
  `copy = super().copy()`); inside `as_sqlite` the module is not used, so it is
  safe. **Keep.**
- `Window.as_sqlite(self, compiler, connection)` omits the `**extra_context` that
  sibling `as_<vendor>` methods accept. This is appropriate here: the only caller
  is `compiler.compile`, which passes exactly `(compiler, connection)`, and
  `Window.as_sql` itself takes `template=None` (not `**extra_context`), so adding
  `**extra_context` would be unused cargo-culting that could only forward keys
  `Window.as_sql` cannot accept. **Keep.**
- The explanatory comment is accurate and matches the surrounding comment style.
  **Keep.**

## F13 — No alternate compile path can bypass `as_sqlite`. Severity: n/a. Verdict: KEEP

Windows are compiled only via `compiler.compile` (in `get_select` and
`get_order_by`). The only other references to windows in the compiler are guards
that *reject* them in UPDATE/INSERT (`compiler.py:1279, 1474`), and the SQLite
backend has no Window-specific operations or compiler override (no matches in
`backends/sqlite3/operations.py`). So every SQLite compilation of a `Window`
goes through V1's `as_sqlite`. **Correct.**

---

## Overall verdict

V1 is correct, regression-free, and faithfully implements the maintainer-suggested
design in PROBLEM.md while fixing the two latent bugs in that hint's pseudocode
(the `isinstance(x, 'DecimalField')` `TypeError` and the shared-source mutation,
see F1/F2). The only low-severity observations (F3, F10, F12) are either
by-design and reliable, or consistent with existing codebase patterns, and none
change behavior. **V1 stands unchanged.**
