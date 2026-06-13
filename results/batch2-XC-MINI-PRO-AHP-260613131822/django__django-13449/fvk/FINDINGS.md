# FINDINGS.md — django__django-13449

Plain-language findings from formalizing `Window.as_sqlite`. Each is
`input → observed vs expected`. The **Findings report does not depend on
machine-checking** (FVK MVP honesty gate) — the bugs below are real today.

The headline result: **writing a clean safety spec for V1 was impossible**, and
per the FVK rule *"if a clean spec is hard or impossible to write, that is itself
strong evidence of a bug"* — that difficulty pinpointed a residual defect (F1)
that V1 shared with the original code on a different input. V2 fixes it.

---

## F1 — [CODE BUG, fixed in V2] V1 still emits invalid SQL when a non-decimal `output_field` is set on a Window over a decimal source

- **input:** `Window(Lag('amount'), partition_by=..., order_by=...,
  output_field=FloatField())` where `amount` is a `DecimalField`, on SQLite.
- **observed (V1):** `self.output_field` is `FloatField` (explicit), so V1 takes
  its *non-decimal* branch `return self.as_sql(...)`. `as_sql` compiles the
  **unmodified** source `Lag('amount')`, which is `DecimalField`, so
  `SQLiteNumericMixin` wraps it: `CAST(LAG("amount", 7) AS NUMERIC)`. Then `as_sql`
  appends ` OVER (...)` →
  **`CAST(LAG("amount", 7) AS NUMERIC) OVER (...)`** → `OperationalError: near
  "OVER": syntax error`. This is the *same* bug class as the original ticket, just
  reached through a different input.
- **expected:** valid SQL with the `OVER` clause inside (or absent from) any cast,
  e.g. `LAG("amount", 7) OVER (...)`.
- **root cause:** V1 conditioned the suppression of the windowed function's own
  cast on the **wrong predicate** — the *Window's* output type — when the inner
  cast must be suppressed based on the *source's* type (and in fact must *always*
  be suppressed, since it always immediately precedes the appended `OVER`).
- **fix (V2):** *always* compile the windowed function as a `FloatField` to
  suppress its per-function cast, then add a single outer `CAST(... AS NUMERIC)`
  iff the Window's output is decimal. Proof obligation **PO-SAFE** now holds for
  *all* inputs (see [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md)).

## F2 — [NEEDED CODE GUARD / cross-backend consistency, fixed in V2] V1's unguarded `output_field` access can raise `FieldError` during SQL generation on SQLite

- **input:** a Window whose `output_field` cannot be resolved, e.g.
  `Window(Lag(F('date') + F('int')))` (mixed-type source, no explicit
  `output_field`).
- **observed (V1):** the top-level `if self.output_field.get_internal_type() ==
  'DecimalField':` is **unguarded**, so it raises `FieldError` *during SQL
  generation* on SQLite — whereas `SQLiteNumericMixin.as_sqlite` (the pattern V1
  builds on) deliberately wraps the identical check in `try/except FieldError`.
- **expected / nuance:** Such a Window is *doomed on every backend anyway* —
  `SQLCompiler.get_converters` accesses `window.output_field` during result
  processing and raises the same `FieldError` (a Window is always a SELECT
  annotation, never a WHERE-only expression). So this is **not** a working query
  that V1 breaks; it is a **consistency / surfacing-point** defect: V1 makes
  SQLite fail *earlier and differently* than other backends.
- **fix (V2):** wrap the decimal check in `try/except FieldError: pass`, matching
  `SQLiteNumericMixin`. SQLite now produces `over(bare, wc)` and the (inevitable)
  `FieldError` surfaces at the same point as on other backends.

## F3 — [SPEC-DIFFICULTY = BUG SIGNAL, resolved] V1 has no clean safety invariant

- Trying to state V1's safety contract forces the **awkward** precondition
  *"`overValid(as_sqlite(W))` holds only when `Tw == decimal` **or** `Ts !=
  decimal`"* — i.e. it is false exactly on the `(Ts=decimal, Tw=other)` quadrant.
  A safety property that holds on three of four quadrants is the textbook
  bug-signal the FVK looks for; it *is* finding F1, restated. V2 admits the clean,
  unconditional invariant **`∀W. overValid(as_sqlite(W)) = true`**.

## F4 — [ROBUSTNESS / PROOF SIMPLIFICATION, addressed in V2] V1 relied on `output_field` caching

- **observed (V1):** V1 delegated the outer cast to `super(Window,
  copy).as_sqlite`, which decides to cast based on **`copy.output_field`**. That
  resolved to `DecimalField` *only because* `self.output_field` had been accessed
  (and cached) by the `if` before `copy = self.copy()`, and the shallow copy
  carried the cache. Sound, but it is a 4-step argument over `cached_property` /
  `copy.copy` / `set_source_expressions` internals — a latent trap for any future
  refactor of those internals (obligation **PO-CACHE**).
- **fix (V2):** the cast decision reads **`self.output_field`** directly and the
  wrap is the literal `'CAST(%s AS NUMERIC)' % sql`; `copy.output_field` is never
  read. **PO-CACHE is discharged by elimination** — it no longer exists.

## F5 — [CONFIRMATION, positive] No shared-state mutation

- **input:** any decimal Window compiled twice (e.g. `repr(qs)` then `list(qs)`).
- **observed (V1 & V2):** both `.copy()` the source expression *before*
  `source_expression.output_field = FloatField()`, so the original `Lag`/aggregate
  is never mutated. (The ticket's suggested pseudocode set
  `source_expressions[0].output_field = ...` on a **shallow** copy, which *would*
  corrupt the shared source — a bug both V1 and V2 correctly avoid.)

## F6 — [CONFIRMATION, non-regression] Standalone decimal aggregates untouched

- **input:** `Book.objects.aggregate(total=Sum('price'))`, `price` a
  `DecimalField`, on SQLite (exercised by `tests/aggregation/`).
- **observed (V2):** unchanged — `Sum` still gets `CAST(SUM("price") AS NUMERIC)`
  from `SQLiteNumericMixin`, because the fix lives entirely in `Window.as_sqlite`.
- **why it matters:** the rejected alternative (a blanket
  *"skip the cast when `getattr(self,'window_compatible',False)`"* in
  `SQLiteNumericMixin`) **would** drop this cast, because `Aggregate.window_compatible
  = True`; on SQLite `Decimal` is stored as text and an aggregate *expression*
  result must be cast to a number for the `create_decimal_from_float` converter.
  V2 avoids that regression by construction.

## F7 — [CONFIRMATION] Decimal sub-expressions inside the function arguments are fine

- **input:** `Window(Lag(F('a') * F('b')))` where the product is `DecimalField`.
- **observed (V2):** only the *outermost* windowed function is forced to
  `FloatField`. A decimal sub-expression in the arguments still receives its own,
  *valid* inner cast: `LAG(CAST(("a"*"b") AS NUMERIC), 1) OVER (...)` — the `OVER`
  still follows `LAG(...)`. `overValid` holds.

## F8 — [CONFIRMATION] Other backends unaffected

- `as_sqlite` is dispatched only when `connection.vendor == 'sqlite'`. PostgreSQL,
  Oracle and MySQL keep using `Window.as_sql` and handle `DecimalField` window
  functions natively. The fix changes no non-SQLite SQL.

## F9 — [NOTE] Termination is trivial

- `compileFunc` / `asSqlWindow` / `asSqliteWindowV2` are finite, non-recursive
  term rewrites (no loop, no back-edge). Partial and total correctness coincide;
  there is no termination obligation to defer.

---

## Proof-derived findings from `/verify`

Constructing the proof (see [PROOF.md](PROOF.md)) produced no new *open* obstacle:
all verification conditions for V2 are finite case-splits on `Type` discharged by
the equational rules — no SMT nonlinearity, no `[simplification]` lemmas, no
escalation boundary. The proof attempt for **V1** instead *succeeds at proving the
counter-claim* `overValid(asSqliteWindowV1(window(func(N,decimal),wc,other))) =
false` — i.e. the prover *confirms* F1 as a reachable bad state, the strongest
possible "this is a real bug" signal.

See [ITERATION_GUIDANCE.md](ITERATION_GUIDANCE.md) for the UltimatePowers
questions and the test-redundancy recommendation.
