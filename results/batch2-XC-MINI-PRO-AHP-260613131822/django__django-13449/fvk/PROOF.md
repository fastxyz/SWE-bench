# PROOF.md — django__django-13449

**Constructed, not machine-checked** (FVK MVP). The `.k` files
[`window_sqlite.k`](window_sqlite.k) / [`window_sqlite-spec.k`](window_sqlite-spec.k)
and the run-commands are emitted below; `kprove` was not executed.

The unit (`Window.as_sqlite`, V2) compiles to finite, non-recursive term
rewrites, so there is **no loop and no circularity**: every claim is discharged by
symbolic execution (the `Axiom`/`Transitivity` rules) plus one `Case Analysis`
split on the output `Type`. No SMT nonlinearity and no `[simplification]` lemmas
are needed.

---

## Claim (V2-FUNC) — functional correctness

`asSqliteWindowV2(window(func(N, Ts), wc, Tw)) ⇒ spec(window(func(N, Ts), wc, Tw))`,
for **all** `N`, `Ts`, `Tw`.

Symbolic execution (each `⇒` is one Axiom step, chained by Transitivity):

```
asSqliteWindowV2(window(func(N,Ts), wc, Tw))
 ⇒ castIf(Tw, asSqlWindow(window(forceFloat(func(N,Ts)), wc, Tw)))   [asSqliteWindowV2]
 ⇒ castIf(Tw, asSqlWindow(window(func(N,other),         wc, Tw)))    [forceFloat]   (*)
 ⇒ castIf(Tw, over(compileFunc(func(N,other)), wc))                  [asSqlWindow]
 ⇒ castIf(Tw, over(bare(N), wc))                                     [compileFunc/other]
```

**(\*) is the crux.** `forceFloat` erases `Ts`, so from this point the derivation
is *independent of the source type*. Now `Case Analysis` on `Tw`:

- `Tw = decimal`: `⇒ cast(over(bare(N), wc))` `[castIf/decimal]` `=` `spec(…,decimal)`. ✓
- `Tw = other`: `⇒ over(bare(N), wc)` `[castIf/other]` `=` `spec(…,other)`. ✓
- `Tw = unresolved`: `⇒ over(bare(N), wc)` `[castIf/unresolved]` `=` `spec(…,unresolved)`. ✓

All branches reach `spec(W)`. ∎  (Discharges **PO-FUNC, PO-SUPPRESS, PO-CASTIFF,
PO-FIELDERR**.)

## Claim (V2-SAFE) — safety: no cast ever closes before `OVER`

`overValid(asSqliteWindowV2(W)) ⇒ true`, for all `W`.

By (V2-FUNC) the argument is `cast(over(bare(N),wc))` or `over(bare(N),wc)`. Evaluate:

```
overValid(over(bare(N), wc))
 ⇒ isBare(bare(N)) andBool overValid(bare(N))   [overValid/over]
 ⇒ true andBool true ⇒ true
overValid(cast(over(bare(N), wc)))
 ⇒ overValid(over(bare(N), wc)) ⇒ true          [overValid/cast]
```

∎  (Discharges **PO-SAFE** — the obligation whose failure *is* the
`OperationalError`.)

## Claim (V2-NOREG) — no change to working SQL

For `T ∈ {decimal, other}`:
`asSqliteWindowV2(window(func(N,T), wc, T)) ⇒ asSqliteWindowV1(window(func(N,T), wc, T))`.

- `T = decimal`: LHS `⇒ cast(over(bare(N),wc))` (by V2-FUNC). RHS `⇒
  cast(asSqlWindow(window(func(N,other),wc,decimal))) ⇒ cast(over(bare(N),wc))`. Equal. ✓
- `T = other`: LHS `⇒ over(bare(N),wc)`. RHS `⇒ asSqlWindow(window(func(N,other),wc,other))
  ⇒ over(bare(N),wc)`. Equal. ✓

∎ The fix is byte-identical to V1 on the working domain (`Tw = Ts`); it diverges
only on the broken inputs F1/F2. (Discharges **PO-NOREG**.)

## Counter-claim (BUG-V1) — the residual bug V2 fixes *(proof of a defect)*

`overValid(asSqliteWindowV1(window(func(N, decimal), wc, other))) ⇒ false`.

```
asSqliteWindowV1(window(func(N,decimal), wc, other))
 ⇒ asSqlWindow(window(func(N,decimal), wc, other))   [asSqliteWindowV1/other — NO forceFloat]
 ⇒ over(compileFunc(func(N,decimal)), wc)            [asSqlWindow]
 ⇒ over(cast(bare(N)), wc)                           [compileFunc/decimal]
overValid(over(cast(bare(N)), wc))
 ⇒ isBare(cast(bare(N))) andBool …                   [overValid/over]
 ⇒ false andBool … ⇒ false                           [isBare/cast]
```

∎ The prover *reaches the bad state* `over(cast(bare(N)), wc)` — the
`CAST(LAG(...) AS NUMERIC) OVER (...)` of the ticket — confirming **F1**.

## Counter-claim (BUG-OLD) — the original ticket

`overValid(asSqliteOld(window(func(N, decimal), wc, decimal))) ⇒ false`, by the
same two final steps after `asSqliteOld(W) ⇒ asSqlWindow(W)`. ∎ Confirms the
original `OperationalError`.

---

## What is proved, in plain language

> For **every** window expression on SQLite — any windowed function, any source
> field type, and whether or not an explicit `output_field` is set — the SQL that
> `Window.as_sqlite` (V2) emits places the `OVER (...)` clause directly after the
> window function, and wraps the whole `<function> OVER (...)` in exactly one
> `CAST(... AS NUMERIC)` iff the Window's output is a `DecimalField`. It therefore
> never produces the `near "OVER": syntax error`, and it is unchanged on every
> window that already worked.

## Residual risk / trusted base

- **Constructed, not machine-checked.** A `#Top` from `kprove` would upgrade this
  from *constructed* to *machine-verified*. Commands below.
- **Adequacy of the mini-SQL-builder fragment.** The proof is about the *term
  structure* (`bare`/`over`/`cast`) of the emitted SQL. It trusts that (a) the
  real `%`/string-join builds exactly these shapes — verified by reading
  `Window.as_sql` and `SQLiteNumericMixin.as_sqlite` — and (b) `overValid` faithfully
  encodes SQLite's "`OVER` operand must be a window function" rule. It does **not**
  model SQLite's parser itself.
- **Outside the term model (argued at code level, not in `.k`):** `PO-PARAMS`
  (parameter list preserved by string wrapping) and `PO-CONV` (the original
  `Window.output_field` still drives `Decimal` result conversion; the throwaway
  `copy` is SQL-text-only).
- **Partial vs total correctness:** moot — the unit has no loop/recursion, so it
  terminates trivially (**F9**).

## Test-redundancy recommendation (benefit 1) — *recommendation only, never auto-delete*

Conditioned on `kprove` returning `#Top`:

- **Subsumed (per-input SQL-shape points within the modeled domain).** Any unit
  test asserting the *emitted SQL shape* for a specific window+field combination —
  e.g. "`Lag('amount')` (DecimalField) yields `CAST(LAG(...) OVER (...) AS
  NUMERIC)`", "`Lag('data')` (FloatField) yields `LAG(...) OVER (...)` with no
  cast" — is entailed by **(V2-FUNC)** for all inputs and becomes a redundant
  single point. *Keep them until the `.k` claims are machine-checked.*
- **Keep — not covered by this proof:**
  - **DB-integration tests** that actually run the query on SQLite and assert the
    returned `Decimal` values — the proof covers the SQL *string structure*, not
    SQLite execution or the `create_decimal_from_float` converter pipeline
    (`PO-CONV` is argued, not modeled).
  - **Non-SQLite backend tests** (PostgreSQL/Oracle/MySQL) — out of the
    `as_sqlite` domain (**F8**).
  - **Standalone-aggregate decimal tests** (`tests/aggregation/`) — out of the
    `Window.as_sqlite` domain; they guard against the rejected blanket-noop
    regression (**F6**).
  - Any **out-of-domain / error-path** test (e.g. a Window whose `output_field` is
    unresolvable) — pins behavior outside the verified contract (**F2**).

## Reproduce the machine check

```sh
kompile window_sqlite.k --backend haskell        # compile the fragment semantics
kast    --backend haskell window_sqlite-spec.k   # (optional) confirm the claims parse
kprove  window_sqlite-spec.k                      # expected: #Top  (all proved)
```

Expected: the five claims `(V2-FUNC)`, `(V2-SAFE)`, `(V2-NOREG)`, `(BUG-V1)`,
`(BUG-OLD)` all reduce to `#Top`. (The two `BUG-*` claims prove a `… ⇒ false`
property *of the old code*, i.e. they certify the findings, not the fix.)
