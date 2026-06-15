# FINDINGS.md — sympy__sympy-16597 (FVK audit of V1)

Plain-language `input → observed vs expected`, each traced to the intent ledger
in [`SPEC.md`](SPEC.md). "V1" = the patch `'rational -> real'` →
`'rational -> real & finite'` in `sympy/core/assumptions.py`.

## Primary finding (the bug V1 fixes) — RESOLVED

**B0 — integer tower did not imply finite.**
- input `Symbol('m', even=True).is_finite` → **observed (pre-fix):** `None`;
  **expected:** `True` (I1/E1).
- input `Symbol('i', integer=True).is_finite` → **observed (pre-fix):** `None`;
  **expected:** `True` (I2/E2).
- Root cause: in `_assume_rules` the chain `even/odd → integer → rational → real`
  never connected to `finite`; `finite` was reachable only via `zero → finite`
  and `infinite → !finite`. So a generic integer/rational symbol could not
  deduce finiteness.
- Fix: `rational -> real & finite`. Verified by claims (EVEN-FINITE),
  (INTEGER-FINITE), (RATIONAL-FINITE) in [`PROOF.md`](PROOF.md). **Resolved.**

---

## Investigated smells (the FVK "spec-difficulty / rationalization" gate)

The V1 notes contained the phrase *"debatable consequence … internally
consistent"* about `oo.is_irrational`. `formalize.md` §7 / `verify.md` Step 3
require that such a verbal rationalization be **investigated, not accepted**. Each
is promoted below to a falsifiable hypothesis and checked against the **full
intent**.

### F1 — `oo.is_irrational` / `(-oo).is_irrational` flip `None → True`

- input `oo.is_irrational` → **observed (post-fix):** `True`; **pre-fix:** `None`.
- Mechanism: V1 makes `oo.is_rational = False` (correct — ∞ is not rational, by
  `!finite → !rational`). The **unchanged** rule `irrational == real & !rational`
  then deduces `irrational = real(True) & !rational(True) = True`, because the
  **pre-existing** extended-real choice keeps `oo.is_real = True`.
- **Hypothesis to falsify (named alternative B):** "V1 is wrong; `irrational`
  should be redefined (e.g. `irrational == real & !rational & finite`) so that
  `oo.is_irrational` is *not* `True`." Side-by-side derivation in
  [`PROOF.md` §4](PROOF.md). Result:
  - Both V1 (A) and B satisfy I1–I3 (even/integer/rational ⟹ finite) and I5
    (consistency). The `oo.is_irrational` value is therefore **under-determined**
    by the public obligations — neither is "forced."
  - Against I6 (definitions stay faithful): the glossary defines `irrational`
    via Wikipedia "irrational number = real ∧ ¬rational"; with `oo.is_real=True`
    that **entails** `oo.is_irrational=True`. Alternative B *contradicts* the
    documented definition by smuggling `finite` into it — and would only be
    coherent if `real` also implied `finite`, which I4/E5 explicitly forbids
    ("adding finite to real would break a lot of code"). B "fixes" `irrational`
    while leaving the actual root cause (`real` = extended_real) in place.
  - There is **no public-intent evidence** (issue, hint, docstring) asking for
    any change to `irrational`; the issue is solely about `finite`.
- **Classification:** *correct consequence of a pre-existing, deliberately
  out-of-scope modeling choice* (`real` = extended_real), entailed by the
  documented definition of `irrational`. **Not a bug in V1.** Alternative B is
  **rejected on positive intent grounds** (contradicts I6, requires forbidden
  I4 change, no supporting evidence), not on bare "scope."
- E8 (`test_assumptions.py:108 assert oo.is_irrational is None`) is **SUSPECT
  legacy**: it pins the pre-fix `oo` row, which any correct finite-fix perturbs.
  It must not veto I1–I3.

### F2 — `oo`/`-oo` cascade: `is_integer, is_rational, is_even, is_odd → False`, `is_noninteger → True`

- input `oo.is_integer / .is_rational / .is_even / .is_odd` → **observed
  (post-fix):** `False` (pre-fix `None`); `oo.is_noninteger` → `True` (pre-fix
  `None`).
- Mechanism: `!finite → !rational → !integer → !even,!odd`; and `real & !integer
  → noninteger`. All are **mathematically correct for ∞**: infinity is not an
  integer, not rational, not even, not odd, and *is* a (extended) non-integer.
- **Classification:** *correctness improvement*, not a regression. The pre-fix
  `None`s were under-informative. Traced to I5/E6. **Keep.** (Tests pinning the
  pre-fix `None` row are SUSPECT legacy, per E8.)

### F3 — `ask(Q.irrational(oo))` returns `True`

- input `ask(Q.irrational(oo))` (and `S.Infinity.is_irrational`) → **observed:**
  `True`. Same root as F1: `assumptions/handlers/sets.py:170` and
  `sathandlers.py:202` forward `Q.irrational` to `expr.is_irrational`.
- **Classification:** direct restatement of F1 in the new-assumptions (`ask`)
  layer; no additional decision. Out of scope for this issue.

### F4 — order-dependent value for `floor(Symbol('x', real=True, infinite=True))`

- input: `x = Symbol('x', real=True, infinite=True); y = floor(x)`. `floor`
  (`functions/elementary/integers.py:78`) defines `_eval_is_integer →
  args[0].is_real` and `_eval_is_finite → args[0].is_finite`. So `y.is_integer`
  wants `True` (x is real) while `y.is_finite` wants `False` (x is infinite).
- **observed under V1:** order-dependent — querying `is_integer` first yields
  `integer=True, finite=True`; querying `is_finite` first yields `finite=False,
  integer=False`. (No exception is raised; the two `deduce_all_facts` paths never
  run together.) **Pre-fix:** the two values simply coexist (`integer=True,
  finite=False`) because no rule linked them.
- **Hypothesis to falsify (named change):** "tighten `floor._eval_is_integer` to
  `args[0].is_real and args[0].is_finite`." Checked against full intent:
  - The triggering input `Symbol('x', real=True, infinite=True)` is a
    pathological *symbolic ∞*; `floor` of an actual ∞ evaluates to ∞ and never
    forms a `floor` node. There is **no public-intent or test evidence** about
    this construct.
  - The imprecision lives in `floor`'s handler (using `is_real` where it means
    "finite real"), is **pre-existing**, and is *surfaced* — not *created* — by
    V1. It is unrelated to the issue's intent (even/integer ⟹ finite).
  - Changing `floor` here risks altering `floor(real-symbol).is_integer` for the
    normal (finite) case if done carelessly, for zero issue-relevant benefit.
- **Classification:** *pre-existing modeling imprecision in `floor`, out of
  scope, no intent support.* **Change rejected** on positive grounds (no
  evidence + pathological-only trigger + regression risk), and recorded for a
  future dedicated issue rather than silently dropped.

### F5 — `irrational`/`real` symbols still not finite (asymmetry)

- input `Symbol('x', irrational=True).is_finite` → **observed:** `None`;
  `Symbol('x', real=True).is_finite` → `None`.
- These remain `None` after V1. Is that wrong vs intent?
  - `real`: I4/E5 **mandate** leaving `real` extended (not finite). Correct by
    intent. Keep.
  - `irrational`: a genuine irrational number is finite, so `irrational →
    finite` is mathematically true — **but it is unaddable on top of V1**: V1
    makes `oo.is_irrational = True` (F1), so `irrational → finite` would force
    `oo.is_finite = True`, contradicting `infinite → !finite` and breaking ∞
    construction (exactly the (CLASH-DETECTED) clash). The asymmetry is therefore
    a *consequence* of keeping `real` extended (I4), not an independent defect.
- **Classification:** *pre-existing, intent-consistent for `real`; blocked for
  `irrational` by the deliberately out-of-scope extended-real choice.* No change.

---

## Adequacy / compatibility findings

- **A1 — no candidate-derived claim.** Every claim traces to E1–E7; the
  `SPEC_AUDIT` is all-pass. The only non-issue deductions (F1) are entailed by
  the documented definition, not invented to match the patch.
- **A2 — no public-API break.** V1 only sharpens `is_*` values; no signature,
  return type, or override changes (see `SPEC.md` §6). No unhandled callsite.

## Verdict

V1 is **confirmed**. The fix is the minimal, definition-faithful realization of
I1–I3, keeps I4–I6, and is consistency-preserving (OO-CONSISTENT). Every smell
resolves to either a correct consequence (F1, F2) or a pre-existing, intent-less,
out-of-scope item (F3, F4, F5) whose "repair" is rejected on positive grounds.
No source change beyond V1 is justified by the artifacts.
