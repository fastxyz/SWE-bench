# ITERATION_GUIDANCE.md — django__django-13449

Feedback package from `/formalize` + `/verify`, for the next code/intent pass.
The audit drove **one code change** (V1 → V2); the rest is confirmation and tests.

## 1. Code change applied this pass (V1 → V2)

`repo/django/db/models/expressions.py`, `Window` class:

- **Reverted** `class Window(SQLiteNumericMixin, Expression)` back to
  `class Window(Expression)` — V2's `as_sqlite` is self-contained and never calls
  the mixin's `as_sqlite`, so inheriting it was dead/misleading.
- **Rewrote `Window.as_sqlite`** to:
  1. **always** compile the windowed function as a `FloatField` (suppress its own
     cast) — was conditional on the decimal branch in V1 (**F1 / PO-SUPPRESS**);
  2. add the outer `CAST(... AS NUMERIC)` from `self.output_field` directly, with
     a `try/except FieldError` guard (**F2 / PO-FIELDERR**), eliminating V1's
     reliance on `copy.output_field` caching (**F4 / PO-CACHE**).

Net effect: discharges **PO-SAFE / PO-FUNC / PO-FIELDERR** for *all* inputs while
staying byte-identical to V1 on every window that already worked (**PO-NOREG**).

## 2. UltimatePowers questions (intent elicitation)

These are genuine API-policy ambiguities the spec surfaced. V2 picks the
defensible default for each; a maintainer may wish to confirm:

1. **`Window(Lag('amount'), output_field=FloatField())` over a `DecimalField`
   source — what is intended?** V2 emits `LAG("amount", 7) OVER (...)` (no cast,
   result converted as `Float`). Alternative readings: cast to the *declared*
   output (`Float` → no NUMERIC cast, as chosen), or honor the *source* decimal.
   V2 chooses "follow the Window's declared `output_field`," consistent with how
   `output_field` overrides work elsewhere. Confirm this is the desired semantics.
2. **A Window whose `output_field` cannot be resolved (mixed-type source).**
   V2 emits valid SQL and lets the inevitable `FieldError` surface later (in
   `get_converters`), matching other backends. Acceptable, or should an
   unresolved window `raise` eagerly with a clearer message? (Out of scope for
   this fix; a candidate for a separate validation improvement.)

## 3. Recommended next code/spec changes — none required

V2 discharges every obligation in [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md).
No further code change is recommended. Optional, non-blocking polish for a future
pass:

- If Django later wants `Window` to advertise SQLite-numeric behavior via the type
  system, a thin marker could be reintroduced — but only if `as_sqlite` actually
  *delegates* to it; do not re-inherit a fully-overridden mixin.

## 4. Tests — add / keep (recommendation only; never auto-deleted)

**Add** (these pin the audit's findings; none are in `tests/expressions_window/`
today, whose model has no `DecimalField`):

- **T1 — original ticket:** annotate a model having a `DecimalField` with
  `Window(Lag('amount', 7), partition_by=[F(...)], order_by=F(...).asc())`,
  compile on SQLite, assert the SQL is `CAST(... LAG(...) OVER (...) ... AS
  NUMERIC)` (OVER inside the cast) and that iterating returns `Decimal` values.
  (Covers **PO-SAFE/PO-FUNC**, original case.)
- **T2 — F1 regression guard:** `Window(Lag('amount'), output_field=FloatField())`
  over a `DecimalField` source on SQLite must **not** raise and must emit
  `LAG(...) OVER (...)` with no `CAST`. *This is the input V1 still crashed on.*
- **T3 — windowed decimal aggregate:** `Window(Sum('amount'))` →
  `CAST(SUM(...) OVER (...) AS NUMERIC)`.
- **T4 — non-decimal window unchanged:** `Window(Lag('data'))` (FloatField) and
  `Window(Rank())` emit no cast (non-regression, **F8/PO-NOREG**).

**Keep** (out of the verified domain or beyond the SQL-string model):

- All **standalone decimal-aggregate** tests in `tests/aggregation/` — they guard
  the **F6** non-regression (the rejected blanket-noop would have broken them).
- All **non-SQLite** window tests (**F8**).
- **DB-execution** assertions (actual returned values) — the proof covers SQL
  structure, not the SQLite converter pipeline (**PO-CONV** is argued, not modeled).

**Conditionally redundant after machine-checking:** per-input SQL-shape unit
points within the modeled domain are subsumed by **(V2-FUNC)** — but keep them
until `kprove` returns `#Top` (honesty gate).

## 5. Status

- Findings: **F1 (bug) fixed**, **F2/F4 hardened**, **F3 resolved**,
  **F5–F9 confirmed**.
- Proof: constructed (not machine-checked); all V2 claims reduce to `#Top` by
  finite case-split; the two `BUG-*` counter-claims certify the findings.
- Residual risk: the "constructed, not machine-checked" caveat and the
  fragment-adequacy / `PO-PARAMS` / `PO-CONV` code-level arguments in
  [PROOF.md](PROOF.md).
