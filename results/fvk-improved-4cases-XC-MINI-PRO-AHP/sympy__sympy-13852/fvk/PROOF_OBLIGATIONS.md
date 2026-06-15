# PROOF_OBLIGATIONS — sympy__sympy-13852

The discharge targets behind each claim in `polylog-expand-spec.k`. Because the
function under audit is a **finite, non-recursive case dispatcher**, most obligations
are single-rule symbolic-execution steps; the only genuine reasoning is the
derivative-consistency normalization (PO-6) and the branch-coverage/totality argument
(PO-7).

## Per-claim obligations

- **PO-1 — (PL1) s == 1.**
  Goal: `expandPolylog(1, z) ⇒ Neg(Log(Sub(1, z)))`.
  Discharge: one Axiom step with the rule
  `expandPolylog(1, Z) => Neg(Log(Sub(1, Z)))`, substitution `Z ↦ z`. No side
  condition. **Closes by Reflexivity after one `=>` step.**

- **PO-2 — (PL2) s == 2, z == 1/2.**
  Goal: `expandPolylog(2, Half) ⇒ Add(Neg(Div(Pow(Log(2),2),2)), Div(Pow(Pi,2),12))`.
  Discharge: one Axiom step with the literal-match dilog rule. **No VC.** The numeric
  adequacy of the value (`= Li_2(1/2)`) is a *mathematical* side fact, checked in
  PROOF.md §Numeric against the dilogarithm reflection formula and mpmath.

- **PO-3 — (PL0) s == 0.**
  Goal: `expandPolylog(0, z) ⇒ Div(z, Sub(1, z))`.
  Discharge: Axiom `expandPolylog(S,Z) => ratPolylog(S,Z) requires S <=Int 0`
  (VC: `0 <=Int 0` — trivially true, Z3), then Axiom `ratPolylog(0,Z) => Div(Z,Sub(1,Z))`.
  Two steps, Transitivity.

- **PO-4 — (PLF s=3) fallback.**
  Goal: `expandPolylog(3, z) ⇒ PolyLog(3, z)`.
  Discharge: the `[owise]` rule fires because no literal/`requires` rule matches
  `s=3` (`3 ∉ {1,2}` and `¬(3 ≤ 0)`). **Obligation: confirm non-overlap** — that the
  earlier rules' match/`requires` are all false at `s=3` (PO-7).

- **PO-5 — (PLF s=2, z≠1/2) guard.**
  Goal: `expandPolylog(2, z) ⇒ PolyLog(2, z)` for `z ≠ Half`.
  Discharge: the dilog rule requires the literal second argument `Half`; for a
  symbolic `z` it does not match, so `[owise]` fires. **Obligation: the dilog branch
  is z=1/2-specific** (guards against over-firing) — confirmed by the literal pattern
  `Half`.

- **PO-6 — (PLDERIV-FIX) derivative consistency. THE load-bearing obligation.**
  Two goals that must reach the **same** normal form `Div(1, Sub(1, z))`:
  1. `Diff(Neg(Log(Sub(1, z))), z) ⇒ Div(1, Sub(1, z))`.
  2. `Div(expandPolylog(0, z), z) ⇒ Div(1, Sub(1, z))`.
  Discharge: structural differentiation + the algebra normalization lemmas
  (`Sub(0,1)→Neg(1)`, `Neg(Div(Neg(E),F))→Div(E,F)`, `Div(Div(Z,F),Z)→Div(1,F)`).
  Full reduction in PROOF.md §PO-6. This is the obligation the **old** `exp_polar`
  output **fails**: `Diff(Neg(Log(Add(1, Mul(expPolarMinusIPi, z)))), z)` reduces to
  `Neg(Div(expPolarMinusIPi, Add(1, Mul(expPolarMinusIPi, z))))`, which does **not**
  normalize to `Div(1, Sub(1, z))` because `expPolarMinusIPi` is held distinct from
  `-1` (the whole point of `exp_polar`). ⇒ the fix is exactly what discharges PO-6.

- **PO-7 — Totality / branch coverage (no missing case, no double-fire).**
  Obligation: every `(s, z)` matches exactly one branch.
  - `s = 1` → PL1; `(s,z) = (2,Half)` → PL2; integer `s ≤ 0` → PL0/ratPolylog;
    everything else → `[owise]`.
  - Non-overlap of the `s ≤ 0` rule with PL1/PL2: `1 ≤ 0` and `2 ≤ 0` are false.
  - `[owise]` totality: K's `owise` fires iff no other rule matches, so the union is
    exhaustive by construction. Discharge: Z3 on the integer guards.

## Side conditions summary (all linear ⇒ Z3)

- `0 <=Int 0` (PO-3): true.
- `¬(3 <=Int 0)`, `3 =/=Int 1`, `3 =/=Int 2` (PO-4/PO-7): true.
- In-domain `z ≠ 0` used implicitly by the lemma `Div(Div(Z,F),Z) → Div(1,F)`
  (PO-6): holds because the derivative identity `polylog(0,z)/z` is itself only used
  where `z ≠ 0` (the SymPy `fdiff` divides by `z`). Recorded as a named domain
  assumption, not a hidden precondition the code must guard.

## Loop obligation (out of scope for the fix, recorded)

- **PO-LOOP — `s < 0` rational-function loop.** The `for _ in range(-s)` loop
  (`start = u·start.diff(u)`) is **unchanged by this fix**. A full circularity claim
  would generalize over the iteration count `n = -s` with invariant "after `k` steps
  `start = (u d/du)^k (u/(1-u))`". We **do not** re-prove it (pre-existing, correct,
  untouched); `mini-sympy.k` abstracts it as `ratPolylog` and pins the `s=0` instance
  the public tests exercise. Flagged in FINDINGS as a deliberate scope boundary.
