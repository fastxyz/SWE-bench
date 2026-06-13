# SPEC.md — formal specification of the fix for django__django-13449

*Constructed with the Formal Verification Kit (`/formalize`). Proof artifacts
are **constructed, not machine-checked** (FVK MVP — the `.k` files and
`kompile`/`kprove` commands are emitted but not run here).*

## What is being specified

The unit under audit is **`Window.as_sqlite(self, compiler, connection)`** in
`repo/django/db/models/expressions.py` (the V2 fix), together with the two
collaborators it depends on for SQLite SQL generation:

- `SQLiteNumericMixin.as_sqlite` — wraps a `DecimalField` expression in
  `CAST(<sql> AS NUMERIC)` (this is what `compiler.compile(source)` dispatches to
  for the windowed function on SQLite);
- `Window.as_sql` — renders `"<expression> OVER (<window>)"`.

Because the bug is structural (where a `CAST(...)` parenthesis closes relative to
the `OVER` clause), the fragment semantics in [`window_sqlite.k`](window_sqlite.k)
models the **SQL string as an algebraic term** built from three constructors:

| term | concrete SQL | meaning |
|---|---|---|
| `bare(N)` | `LAG(...)` | a bare window-function call |
| `over(S, wc)` | `S OVER (...)` | append an `OVER` clause to `S` |
| `cast(S)` | `CAST(S AS NUMERIC)` | the SQLite numeric cast |

Inputs are modelled by `window(func(N, Ts), wc, Tw)` where `Ts` is the *source
function's* output type and `Tw` is the *Window's own* output type (which can be
set explicitly via `output_field=` and therefore **differ** from `Ts`). Each type
is `decimal`, `other`, or `unresolved` (the last models `output_field` raising
`FieldError`).

## Precondition

`φ_pre`: the Window is well-formed — `source_expressions[0]` exists and is a
window-compatible function (guaranteed by `Window.__init__`, which raises
otherwise). No constraint on `Ts`/`Tw` is required; in particular the spec covers
the case `Tw == unresolved`.

## Postcondition — three contracts

Let `W = window(func(N, Ts), wc, Tw)`.

1. **(V2-FUNC) Functional correctness.** `as_sqlite(W)` equals the intended term

   ```
   spec(W) = cast(over(bare(N), wc))   if Tw == decimal
           = over(bare(N), wc)         otherwise   (other / unresolved)
   ```

   i.e. exactly one `CAST(... AS NUMERIC)` wraps the **whole** `<fn> OVER (...)`
   expression iff the *Window's* output is a `DecimalField`, and the windowed
   function is never cast on its own.

2. **(V2-SAFE) Safety — the bug can never recur.** For **all** inputs,
   `overValid(as_sqlite(W)) = true`, where `overValid` encodes the SQLite rule
   *the operand of `OVER` must be a bare function call, never a `CAST(...)`*. This
   is the property whose violation is `OperationalError: near "OVER": syntax
   error`.

3. **(V2-NOREG) Non-regression.** On "normal" windows — those with `Tw == Ts`,
   the only shape obtainable **without** an explicit `output_field=` override —
   `as_sqlite_V2(W)` is byte-identical to `as_sqlite_V1(W)`, and (for non-decimal
   `Ts`) to the pre-fix output. So the fix rewrites no SQL that previously worked.

## Side conditions / domain notes

- **`unresolved` is in-domain for V2.** The `try/except FieldError` guard makes
  `as_sqlite(W)` total: an unresolvable `output_field` yields `over(bare(N), wc)`
  (no cast), not a crash. (V1 had no guard here — see FINDINGS F2.)
- **Result conversion is unaffected.** `as_sqlite` builds a throwaway `copy` for
  SQL generation only; the original `Window` (and its `output_field`, hence its
  Python-side `Decimal` converter) is untouched.
- **Parameters are preserved.** Wrapping a SQL string in `CAST(... )` does not
  reorder or change `params`.

## Counter-specifications (used as findings)

The same model makes the defects of the earlier code machine-statable:

- **(BUG-OLD)** pre-V1 on the *original issue* `window(func(N, decimal), wc,
  decimal)` → `over(cast(bare(N)), wc)` → `overValid = false`.
- **(BUG-V1)** V1 on an *override* `window(func(N, decimal), wc, other)` →
  `over(cast(bare(N)), wc)` → `overValid = false`. (This is the residual bug V2
  fixes; see [`FINDINGS.md`](FINDINGS.md) F1.)

See [`window_sqlite-spec.k`](window_sqlite-spec.k) for the K `claim`s and
[`PROOF.md`](PROOF.md) for the constructed proof.
