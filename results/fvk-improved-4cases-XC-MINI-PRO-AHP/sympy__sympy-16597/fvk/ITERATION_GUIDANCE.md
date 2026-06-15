# ITERATION_GUIDANCE.md — sympy__sympy-16597

Next-iteration feedback distilled from the FVK audit. Ordered by relevance to
*this* issue; later items are explicitly out of scope and recorded so they are
not silently dropped.

## Decision for this iteration

**Keep V1 unchanged:** `'rational -> real & finite'` in
`sympy/core/assumptions.py`. It is the minimal, definition-faithful fix that
discharges PO1–PO8 (see [`PROOF.md`](PROOF.md)). No additional source edit is
justified by the artifacts. (No test files touched — task constraint.)

## Why no further code change

| Candidate change considered | Verdict | Trace |
|---|---|---|
| Attach `finite` to `real` instead of `rational` | **rejected — unsound** (breaks `oo`/`-oo`) | PO7, PROOF §4 (alt R), I4/E5 |
| Attach `finite` to `complex` | **rejected — unsound** (breaks `zoo`) | PO7, PROOF §4 (alt C) |
| Attach `finite` to `integer` only (not `rational`) | rejected — narrower than intent; misses `Symbol(rational=True)` | I3/E3/E4 |
| Redefine `irrational == real & !rational & finite` to keep `oo.is_irrational` False | **rejected — contradicts glossary def (I6), presupposes forbidden `real` change (I4), no evidence** | F1, PROOF §4 (alt B) |
| Tighten `floor._eval_is_integer` to require finiteness | **rejected — pre-existing, pathological-only trigger, no intent evidence, regression risk** | F4 / OB1 |
| Cosmetic: drop now-redundant `finite` from `zero -> even & finite` | not done — gratuitous refactor; keeping it is harmless and self-documenting | minimal-change principle |

## UltimatePowers-style clarifications (for the maintainers / next intent pass)

1. **Extended reals (the real root cause).** Should `S.Infinity.is_real` remain
   `True` (extended-real), or should SymPy introduce a separate `extended_real`
   so that `real ⟹ finite`? Resolving this *upstream* would (a) let `irrational`
   and `real` symbols imply `finite` cleanly and (b) make `oo.is_irrational`
   `False` honestly. This is the principled long-term fix the hint gestures at
   ("`real` should already imply `finite`") and is **outside this issue**.
2. **`oo.is_irrational` (F1).** Confirm the intended value of `is_irrational`
   for `±oo`. Under the current definition + `oo.is_real=True` it is `True`; if
   the team wants `False`, that requires clarification #1, not a local
   `irrational` hack.
3. **`floor` of a symbolic infinite real (F4).** Should
   `floor(Symbol('x', real=True, infinite=True))` be considered an integer?
   Decide alongside the extended-real model.

## Tests (recommendation only; never auto-deleted; no test files modified)

- **Add (when writing tests is in scope):** `Symbol('x', even=True).is_finite is
  True`; same for `integer`, `rational`, `prime`. These pin PO1–PO3.
- **Update, do not delete:** the `oo`/`-oo` rows in `test_infinity` /
  `test_neg_infinity` that currently assert pre-fix `None` for
  `is_integer/is_rational/is_even/is_odd/is_noninteger/is_irrational` — these are
  SUSPECT legacy (E8) and should move to the §2 fixpoint values
  (`False/False/False/False/True/True`).
- **Keep:** `test_zoo`, `test_nan`, and all consistency/termination tests — they
  guard the boundary the proof depends on (PO6).
- Proof-subsumed in-domain points become removable **only after** `kprove`
  returns `#Top` (Honesty gate, PROOF §6).

## Confidence

- **High (machine-check-independent):** the root-cause fix B0 and the consistency
  of all four singletons (constructive traces, PROOF §1–§2, §5).
- **Conditioned on `kprove #Top`:** the formal claims and any test-removal.
- **Open upstream questions:** items 1–3 above — none blocks this fix; all are
  larger than issue #16597.
