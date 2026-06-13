# PROOF_OBLIGATIONS.md — django__django-13449

The verification conditions that must hold for the fix to be correct. Each lists
its statement, how it is discharged, its status for **V2** (current code) and for
**V1** (the previous fix), and the linked finding. `as_sqlite` lives at
`repo/django/db/models/expressions.py:1335`.

Notation: `W = window(func(N, Ts), wc, Tw)`; `Ts` = source function output type,
`Tw` = Window output type; types ∈ {`decimal`, `other`, `unresolved`}.

---

### PO-SUPPRESS — the windowed function never carries its own cast
**Statement:** `compileFunc(forceFloat(F)) = bare(name(F))` for every windowed
function `F`.
**Discharge:** `forceFloat(func(N,_)) = func(N, other)` (code: `source_expression =
source_expressions[0].copy(); source_expression.output_field =
fields.FloatField()`), then `compileFunc(func(N, other)) = bare(N)` (the
`other`/non-decimal rule of `SQLiteNumericMixin.as_sqlite`). Function SQL is
independent of `output_field`, so `bare(N)` is unchanged.
**V2:** ✅ holds for *all* `F` — the force is unconditional (code line 1348).
**V1:** ⚠️ holds only inside the decimal branch; the `other` branch skips the
force. → **F1**.

### PO-CASTIFF — exactly one outer cast iff the Window output is decimal
**Statement:** `as_sqlite(W)` wraps the whole expression in one `cast(...)` iff
`Tw == decimal`.
**Discharge:** `castIf(decimal,S)=cast(S)`, `castIf(other,S)=castIf(unresolved,S)=S`,
driven by `self.output_field.get_internal_type() == 'DecimalField'` (code 1353).
**V2:** ✅ decision reads `self.output_field` (the Window's own type) directly.
**V1:** ✅ (decimal branch casts; other branch doesn't) — but coupled to the buggy
PO-SUPPRESS, see PO-SAFE.

### PO-SAFE — **the safety property**: no `CAST(...)` ever closes before `OVER`
**Statement:** `∀W. overValid(as_sqlite(W)) = true`.
**Discharge:** by PO-SUPPRESS the inner operand of every `over(_, wc)` produced is
`bare(N)` (so `isBare = true`); the optional outer `cast` only ever wraps an
already-valid `over(bare(N), wc)`, and `overValid(cast(S)) = overValid(S)`. Finite
case-split on `Tw`. (Claim **(V2-SAFE)**.)
**V2:** ✅ holds for all four `(Ts,Tw)` quadrants (incl. `unresolved`).
**V1:** ❌ **false** on `(Ts=decimal, Tw=other)`: yields `over(cast(bare(N)), wc)`,
`isBare(cast(_)) = false`. The prover *discharges the counter-claim* **(BUG-V1)**.
→ **F1, F3**. This is the obligation V2 was written to satisfy.

### PO-FUNC — functional correctness (output equals the intended SQL)
**Statement:** `∀W. as_sqlite(W) = spec(W)` where
`spec(W) = cast(over(bare(N),wc))` if `Tw=decimal` else `over(bare(N),wc)`.
**Discharge:** compose PO-SUPPRESS (inner = `over(bare(N),wc)`) with PO-CASTIFF
(outer cast iff `Tw=decimal`). Claim **(V2-FUNC)**.
**V2:** ✅. **V1:** ❌ on `(decimal, other)` (returns `over(cast(bare(N)),wc) ≠
over(bare(N),wc)`).

### PO-FIELDERR — totality under an unresolvable `output_field`
**Statement:** `as_sqlite(W)` returns a SQL term (does not raise) when
`self.output_field` raises `FieldError`.
**Discharge:** `try: … except FieldError: pass` (code 1352–1356), modelled by
`castIf(unresolved, S) = S`.
**V2:** ✅ returns `over(bare(N),wc)`. **V1:** ❌ unguarded check raises at SQL-gen
time. → **F2**.

### PO-CACHE — *(V1 only; eliminated in V2)* outer cast depends on `output_field` caching
**Statement (V1):** inside `super(Window, copy).as_sqlite`, `copy.output_field`
resolves to `DecimalField`.
**Discharge (V1):** required a 4-step argument — (1) `self.output_field` is a
`cached_property` accessed by the `if`; (2) `self.copy()=copy.copy(self)` shallow-
copies `__dict__` incl. the cache; (3) `set_source_expressions` does not evict it;
(4) the cache shadows the descriptor. Sound, but fragile.
**V2:** ✅ **discharged by elimination** — V2 reads `self.output_field` directly and
never reads `copy.output_field`. → **F4**.

### PO-NOMUT — the original source expression is not mutated
**Statement:** compiling `W` does not change `W.source_expression.output_field`.
**Discharge:** `source_expressions[0].copy()` is taken *before*
`.output_field = FloatField()` (code 1347–1348); only the copy is mutated.
**V2:** ✅. **V1:** ✅ (same guard). → **F5**.

### PO-PARAMS — parameters are preserved and correctly ordered
**Statement:** `as_sqlite(W)` returns the same `params` as `copy.as_sql(W)`.
**Discharge:** the cast wrap is a pure string operation `'CAST(%s AS NUMERIC)' %
sql` (code 1354); `params` from `copy.as_sql` is returned unchanged. (Outside the
term model; argued at code level.)
**V2:** ✅. **V1:** ✅ (super delegated to the same `as_sql`).

### PO-CONV — Decimal result conversion still applies
**Statement:** the value fetched for a decimal Window is converted to `Decimal`.
**Discharge:** the throwaway `copy` is used only for SQL text; the original
`Window` stays in the SELECT, so its `output_field`/`convert_value` (Decimal) and
the SQLite `get_decimalfield_converter` drive conversion, and the emitted
`CAST(... AS NUMERIC)` makes SQLite return a numeric value for them. (Outside the
term model; argued at code level.)
**V2:** ✅. **V1:** ✅.

### PO-NOREG — non-regression vs V1 / pre-fix on normal windows
**Statement:** for `Tw = Ts ∈ {decimal, other}` (no explicit override),
`as_sqlite_V2(W) = as_sqlite_V1(W)`.
**Discharge:** both reduce to `cast(over(bare(N),wc))` (decimal) or
`over(bare(N),wc)` (other). Claim **(V2-NOREG)**.
**V2:** ✅ byte-identical to V1 and to the pre-fix output on the working domain;
V2 differs from V1 *only* on the broken inputs of F1/F2.

---

## Summary

| Obligation | V1 | V2 |
|---|---|---|
| PO-SUPPRESS | partial (decimal branch only) | ✅ all |
| PO-CASTIFF | ✅ | ✅ |
| **PO-SAFE** | ❌ fails on `(decimal,other)` | ✅ all inputs |
| PO-FUNC | ❌ on `(decimal,other)` | ✅ |
| PO-FIELDERR | ❌ raises | ✅ |
| PO-CACHE | sound-but-fragile | ✅ eliminated |
| PO-NOMUT | ✅ | ✅ |
| PO-PARAMS | ✅ | ✅ |
| PO-CONV | ✅ | ✅ |
| PO-NOREG | n/a | ✅ identical on working domain |

V1 discharges the original-ticket case but leaves **PO-SAFE / PO-FUNC / PO-FIELDERR**
open on the override and unresolvable inputs. **V2 discharges every obligation.**
