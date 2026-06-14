# Control notes — sympy__sympy-16597 (V2, after review)

This document records every decision taken after the systematic review, tracing
each to the numbered entries in `review/FINDINGS.md`.

## Outcome in one line
V1's **functional** fix (`rational -> finite`) is **kept unchanged** because the
review found it correct, consistent, and well-scoped. The only edit applied is a
**cosmetic re-placement** of that one rule. No other source changes.

## State of the code after this pass
`sympy/core/assumptions.py`, `_assume_rules`:

```python
    'integer        ->  rational',
    'rational       ->  real',
    'rational       ->  finite',     # <- the fix
    'rational       ->  algebraic',
    ...
```

---

## Decision 1 — Keep `rational -> finite` as the fix (no functional change)
**Traces to: F1, F2, F3, F7, F12.**

- It resolves exactly what the issue asks: `even`/`integer` symbols now report
  `is_finite = True` via `even -> integer -> rational -> finite` (**F1**).
- It is the exact change the public hint endorses (`'rational -> real & finite'`,
  "safe to add finite to rational"), and V1's standalone line compiles
  identically (**F2**).
- It is logically consistent and import-safe: all `is_infinite` singletons and
  `NaN` still construct without `InconsistentAssumptions` (**F3**).
- It is correctly scoped to `rational`, **not** `real` — the latter would make
  `oo`/`-oo` (real ∧ infinite) inconsistent and is the out-of-scope
  extended-real refactor (**F7**, **F12c**).
- Rejected alternatives `integer -> finite` (less complete, off-hint) and
  retooling `irrational` (broader, regression-risky) are documented in **F12a/b**.

## Decision 2 — Move the rule next to the other `rational ->` implications
**Traces to: F11.**

V1 left `'rational -> finite'` in an isolated paragraph. The block's convention
is to group containment-style implications
(`integer -> rational -> real -> complex …`) together, so the rule was relocated
to sit immediately after `'rational -> real'`. This is **purely cosmetic**:
`FactRules` builds a transitive closure (`facts.py:transitive_closure`), so rule
placement/order has no effect on the deduced facts. Behavior is byte-for-byte
identical to V1 at runtime.

## Decision 3 — Accept the `oo.is_irrational = True` side effect (no extra code)
**Traces to: F5, F6.**

Making `oo`/`-oo` provably `!rational` causes the existing biconditional
`irrational == real & !rational` to deduce `is_irrational = True` for them
(**F5**). I chose not to add code to suppress this because:
- it is internally consistent with this version's extended-real model (where
  `oo.is_real = True`), i.e. a symptom of a known, out-of-scope design issue, and
- a full regression scan of every `is_irrational` consumer found **no practical
  impact**: `oo` auto-evaluates out of `Pow`/`Mul`/`Add`/`Min`/`Max`, and the
  remaining guards test "all *other* operands rational", which `oo` (now
  `is_rational = False`) never satisfies (**F6**).

Suppressing it would require widening `irrational`'s definition (F12b), changing
behavior for ordinary `real`-and-not-`rational` symbols — a worse trade than the
benign edge case.

## Decision 4 — No changes for the new contradiction detection
**Traces to: F9.**

`Symbol(even=True, infinite=True)` / `Symbol(rational=True, finite=False)` now
raise `InconsistentAssumptions` instead of being silently accepted. This is
*correct* (genuine contradictions), and a codebase scan confirmed no non-test
code constructs such symbols (the lone source `finite=False` is an unrelated
`fourier_series` kwarg). Nothing to fix.

## Decision 5 — No changes for surrounding number classes or new-style assumptions
**Traces to: F8, F10.**

`Rational`/`Integer` now derive `finite=True` at class level, agreeing with the
pre-existing `Number._eval_is_finite`; `Float` (incl. `Float('inf')`) is
unaffected because it pins `is_rational = None` (**F8**). Only
`test_infinity`/`test_neg_infinity` assertions change in the visible suite, and
those flips are forced by the fix itself (**F10**). The independent `ask()`
system is out of scope for this issue. Hence no further edits.

---

## Decision 6 — No changes for special-function behavior at infinities
**Traces to: F13.**

Since infinities now resolve `is_integer = False` / `is_noninteger = True`, I
scanned every special-function consumer that branches on these for infinite
arguments. The tested cases — `polygamma(0, -oo) == oo`, `loggamma(-oo) == zoo`,
and the `catalan(...)` cases (finite args) — are all **unaffected** because they
reach explicit infinity branches (`z in (S.Infinity, S.NegativeInfinity)`,
`abs(z) is S.Infinity`) via truthy-only checks. The only genuine shifts
(`gamma(-oo).is_real`/`.is_positive`, `catalan(-oo)`) are pathological, untested,
and intrinsic to *any* correct fix. Nothing to change.

## Net diff vs. V1
- `sympy/core/assumptions.py`: the single `'rational -> finite'` rule was moved
  up by seven lines (and the surrounding blank lines normalized). No semantic
  change. Everything else is identical to V1.
