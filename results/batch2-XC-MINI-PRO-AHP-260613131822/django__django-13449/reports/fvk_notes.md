# reports/fvk_notes.md — FVK audit decisions for django__django-13449

This explains what the Formal Verification Kit pass changed in the V1 fix and
why, tracing each decision to a specific entry in
[`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Outcome in one line

The audit found that **V1 did not actually close the bug** — it still emitted the
`CAST(...) OVER (...)` syntax error on a reachable input. I revised the fix to
**V2**, which discharges every proof obligation. The single source file changed is
`repo/django/db/models/expressions.py` (`Window` class).

## What V1 was, and how the audit broke it

V1 = `class Window(SQLiteNumericMixin, Expression)` plus an `as_sqlite` that, *only
when the Window's output was decimal*, suppressed the windowed function's cast
(by forcing the source copy to `FloatField`) and delegated to
`super().as_sqlite` to wrap the whole expression.

Formalizing the safety property "the emitted SQL never closes a `CAST(...)` before
`OVER`" (predicate `overValid`) made V1's defect explicit:

- **Trace to [FINDINGS F1] / [PO-SUPPRESS] / [PO-SAFE].** The inner cast must be
  suppressed *unconditionally* — it always sits immediately before the appended
  ` OVER (...)`. V1 suppressed it *conditionally on the Window's output type*.
  When `output_field=FloatField()` is set on a `Window` over a `DecimalField`
  source (`Window(Lag('amount'), output_field=FloatField())`), V1 takes its
  non-decimal branch `return self.as_sql(...)`, which compiles the **unmodified**
  decimal source → `CAST(LAG(...) AS NUMERIC)` → `... OVER (...)` → the *same*
  `OperationalError` the ticket reports. The proof discharges the counter-claim
  `(BUG-V1)` (see [`fvk/PROOF.md`](../fvk/PROOF.md)).
- **Trace to [FINDINGS F3].** This is also a "spec-difficulty = bug signal" hit:
  V1 has no clean safety invariant — its `overValid` holds on only three of the
  four `(source-type, window-type)` quadrants. The inability to state a clean
  contract *is* the bug.

## The code change (V1 → V2) and the obligations it discharges

`Window.as_sqlite` now, for **every** window:

1. copies the source and **always** forces it to `FloatField` before compiling —
   so the windowed function is never individually cast.
   → discharges **[PO-SUPPRESS]** for all inputs, hence **[PO-SAFE]** and
   **[PO-FUNC]**; fixes **[FINDINGS F1]**.
2. adds the outer `CAST(... AS NUMERIC)` based on `self.output_field`, wrapped in
   `try/except FieldError`.
   → discharges **[PO-CASTIFF]** and **[PO-FIELDERR]**; fixes **[FINDINGS F2]**
   (V1's unguarded `self.output_field` access could raise `FieldError` during SQL
   generation on SQLite, inconsistent with `SQLiteNumericMixin`, which guards the
   identical check).

Because the decimal decision now reads `self.output_field` directly and the wrap
is the literal `'CAST(%s AS NUMERIC)' % sql`, V2 **never reads `copy.output_field`**.
→ **[PO-CACHE]** is *eliminated*, not merely satisfied (**[FINDINGS F4]**): V1's
correctness had rested on a 4-step `cached_property`/`copy.copy` argument; V2 does
not depend on caching at all.

### Why I reverted the base class to `class Window(Expression)`

V2's `as_sqlite` is self-contained and does not call `super().as_sqlite`, so
inheriting `SQLiteNumericMixin` (whose only member is that method) would be dead,
misleading inheritance. I confirmed `SQLiteNumericMixin` is **only** used as a base
class and never `isinstance`-checked anywhere in `repo/`, so dropping it from
`Window`'s bases is safe. This also makes the *total* diff versus the original
upstream code minimal: a single added `as_sqlite` method, no class-hierarchy
change. (Design rationale recorded under **[FINDINGS F4]** /
[`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) §1.)

## Decisions to KEEP V1 behavior (confirmed correct, left unchanged)

- **Copy the source expression before mutating `output_field`.** Kept exactly as
  V1 had it. → **[PO-NOMUT] / [FINDINGS F5]**: prevents corrupting the shared
  `Lag`/aggregate instance (the bug latent in the ticket's suggested pseudocode,
  which mutated a shallow copy).
- **Scope the fix to `Window.as_sqlite` only; do not touch `SQLiteNumericMixin`.**
  → **[FINDINGS F6]**: the tempting "blanket noop when
  `getattr(self,'window_compatible',False)`" alternative would have dropped the
  `CAST(... AS NUMERIC)` from *standalone* decimal aggregates (`Sum('price')`),
  because `Aggregate.window_compatible = True` and on SQLite a decimal aggregate
  *expression* must be cast to a number for the `create_decimal_from_float`
  converter. V2 leaves all standalone expressions untouched.
- **Only force the outermost windowed function to `FloatField`.** → **[FINDINGS
  F7]**: decimal sub-expressions inside the function's *arguments* still receive
  their own, valid inner cast (`LAG(CAST(x AS NUMERIC), 1) OVER (...)`), which is
  correct.
- **No non-SQLite change.** → **[FINDINGS F8]**: `as_sqlite` is SQLite-only.
- **No termination work.** → **[FINDINGS F9] / [PROOF residual risk]**: the unit is
  finite, non-recursive term construction; partial = total correctness.

## Things proved only at the code level (not in the `.k` model), and why that's OK

- **[PO-PARAMS]** — wrapping the SQL string in `CAST(...)` returns
  `copy.as_sql`'s `params` unchanged. The term model abstracts away parameters; I
  verified this by reading the one-line string substitution.
- **[PO-CONV]** — the throwaway `copy` is used only to build SQL text; the original
  `Window` stays in the SELECT, so its `output_field` (Decimal) and the SQLite
  `get_decimalfield_converter` still convert results, and the emitted
  `CAST(... AS NUMERIC)` ensures SQLite hands them a numeric value. Argued from the
  compiler/operations code, not the fragment.

## Confidence and honesty gate

The Findings (F1–F9) do **not** depend on machine-checking and stand today; F1 in
particular is a concrete reachable `input → invalid SQL`. The *proof* is
**constructed, not machine-checked**: [`fvk/window_sqlite.k`](../fvk/window_sqlite.k)
and [`fvk/window_sqlite-spec.k`](../fvk/window_sqlite-spec.k) plus the
`kompile`/`kprove` commands are emitted in [`fvk/PROOF.md`](../fvk/PROOF.md) but not
run (no execution environment). Test-removal suggestions are therefore
recommendation-only and conditioned on `kprove` returning `#Top`; I recommend
*adding* tests T1–T4 (including the F1 regression guard) and *keeping* all
DB-execution, non-SQLite, and standalone-aggregate tests.
