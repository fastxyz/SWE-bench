# PROOF OBLIGATIONS — `polylog._eval_expand_func` (sympy__sympy-13852)

Each obligation below is what must hold for the **V1 fix** to be correct against
SPEC.md. Columns: statement, the claim/ledger entry it discharges, the tier that
discharges it, and status. "Tier" is one of **Z3** (linear/boolean, bundled),
**STRUCT** (symbolic-execution / code-inspection, bundled), or **ESCALATION**
(special-function identity beyond the bundled arithmetic tier — discharged by
established identity + numerical witness, never `[trusted]`).

Status legend: ✅ discharged (constructed, not machine-checked) · ⛰ discharged at
escalation tier (identity + numerical witness) · — n/a.

---

## PO1 — `s == 1` branch value (VC-Li1)
**Statement.** `expand_func(polylog(1, z)) = -log(1 - z)`, and `-log(1 - z)` is
analytically equal to `polylog(1, z)` **including branch cuts**: for real `z > 1`,
both have imaginary part `-pi`.
**Discharges.** (EXPAND-S1); ledger L3, L5; Finding F1.
**Tier.** Code value: STRUCT (the branch literally returns `-log(1 - z)`).
Analytic equality: ESCALATION.
**Discharge.** (i) `Li_1(z) = Σ_{n≥1} z^n/n = -log(1-z)` for `|z|<1` (power series),
the standard closed form. (ii) Branch cut: SymPy `log(neg real) = log| | + I*pi`
⇒ `Im(-log(1-z))|_{z>1} = -pi`; mpmath `polylog(1, z>1)` gives `-pi` too (issue's
thousands-of-points test). (iii) Corroboration: `eval` already gives
`polylog(1,-1) = -dirichlet_eta(1) = -log(2) = -log(1-(-1))` and
`polylog(1,0)=0=-log(1)` — both consistent with `-log(1-z)`. (iv) SymPy
`hyperexpand` independently returns `-log(1 + -z)` (test_hyperexpand.py:582).
**Status.** ⛰ (value ✅, analytic identity ⛰)

## PO2 — `s == 2, z == 1/2` branch value (VC-Li2½)
**Statement.** `expand_func(polylog(2, S.Half)) = pi**2/12 - log(2)**2/2`, and that
equals `Li_2(1/2)`.
**Discharges.** (EXPAND-HALF); ledger L1, L2; Finding F2.
**Tier.** Code value: STRUCT. Identity: ESCALATION.
**Discharge.** Standard dilogarithm identity `Li_2(1/2) = pi^2/12 - (ln 2)^2/2`
(derivable from the reflection/Landen relation `Li_2(x)+Li_2(1-x)=pi^2/6 -
ln x · ln(1-x)` at `x=1/2`). Numerical witness: `pi^2/12 - log(2)^2/2 =
0.8224670334 - 0.2402265070 = 0.5822405264`, matching `polylog(2, 0.5).n() ≈
0.5822405265`. Printed form `-log(2)**2/2 + pi**2/12` is the canonical str output
(issue line 14, an actual `nsimplify` print).
**Status.** ⛰ (value ✅, identity ⛰)

## PO3 — branch disjointness / exhaustiveness (no regression)
**Statement.** The inserted `s==2 ∧ z==½` rule does not shadow, reorder, or remove
any input from the pre-existing branches; the dispatch is total.
**Discharges.** (EXPAND-FRAME-SYM), (EXPAND-FRAME-2), (EXPAND-NEG); ledger L6, L7,
L8; Finding F3.
**Tier.** STRUCT + Z3 (guard algebra on `SVal × ZVal`).
**Discharge.** Guard sets: `{s=1}`, `{s=2 ∧ z=½}`, `{s∈ℤ, s≤0}`, default. Pairwise
intersection empty (`1≠2`, `2>0`, etc.); union = all of `SVal × ZVal`. Therefore
each of the four `<out>` rewrites fires on exactly its Python branch. The `for`
order in source (`if s==1` then `if s==2∧z=½` then `if s≤0` then `return`) is
preserved by the model; because guards are disjoint, order is irrelevant to the
result. ✅

## PO4 — `expand_func` commutes with `d/dz` (frame / consistency)
**Statement.** For every `(s, z)`, the returned `E(s,z)` satisfies
`d/dz E(s,z) = E(s-1, z)/z` wherever `polylog` does; in particular
`expand_func(diff(polylog(1, z) + log(1 - z), z)) = 0`.
**Discharges.** ledger L4; Finding F4; VC-Frame.
**Tier.** STRUCT, given PO1/PO2.
**Discharge.** Each branch result is analytically equal to `polylog(s, z)` (PO1,
PO2, Euler identity for `s≤0`, identity for the no-op). `polylog.fdiff` is unchanged
by V1 (`polylog(s, z).diff(z) = polylog(s-1, z)/z`). Hence differentiating the
*expanded* form equals differentiating `polylog` then expanding. Concretely:
`diff(polylog(1,z)+log(1-z), z) = polylog(0,z)/z - 1/(1-z)`; expand `polylog(0,z) =
z/(1-z)` ⇒ `1/(1-z) - 1/(1-z) = 0`. ✅

## PO5 — well-formedness of the edited method (no `NameError`, imports sound)
**Statement.** Every name used in the method body resolves; no removed import is
referenced.
**Discharges.** ledger L9; Finding F6.
**Tier.** STRUCT (inspection).
**Discharge.** Used in body: `log`, `expand_mul`, `Dummy` (local import), `pi`,
`S` (module-level, line 4), `polylog` (in scope). Removed `exp_polar`, `I` are not
referenced anywhere in the method. ✅

## PO6 — doctest outputs match SymPy's printer
**Statement.** The two updated/added doctests print exactly as written:
`expand_func(polylog(1, z))` → `-log(-z + 1)`; `expand_func(polylog(2, S.Half))` →
`-log(2)**2/2 + pi**2/12`.
**Discharges.** docstring edit; ledger L2; Finding F2/F1.
**Tier.** STRUCT (printer reasoning).
**Discharge.** (a) `1 - z` is the `Add(1, -z)`; the sibling doctest
`expand_func(polylog(0, z))` → `z/(-z + 1)` (same `Add`) fixes the printed form as
`-z + 1`, so `-log(1 - z)` prints `-log(-z + 1)`. (b) The `s==2` Add is identical to
the `nsimplify` result whose canonical print (issue line 14) is
`-log(2)**2/2 + pi**2/12`; `expand_func` does not reorder it. ✅

## PO7 — `eval` precedence keeps `z ∈ {0, 1, -1}` out of this method
**Statement.** `_eval_expand_func` never has to produce a value for the singular
points `z ∈ {0, 1, -1}`; `polylog.eval` returns `0 / zeta(s) / -dirichlet_eta(s)`
first.
**Discharges.** ledger L10.
**Tier.** STRUCT (inspection of `polylog.eval`, lines 278-285).
**Discharge.** `eval` is a `@classmethod` run at construction; for `z∈{0,1,-1}` it
returns a value, so the `polylog(...)` object (and thus `_eval_expand_func`) is
never built with those `z`. In particular the `s==1` branch is never asked for the
pole `z=1` (`-log(0)`), and the `z=½` branch is unaffected. ✅

---

## Summary table

| PO | What | Tier | Status |
|----|------|------|--------|
| PO1 | `s==1` → `-log(1-z)` (incl. branch cut) | STRUCT + ESCALATION | ⛰ |
| PO2 | `s==2,z==½` → `pi²/12 - log²2/2` | STRUCT + ESCALATION | ⛰ |
| PO3 | branch disjoint/exhaustive, no regression | STRUCT + Z3 | ✅ |
| PO4 | commutes with `d/dz` | STRUCT | ✅ |
| PO5 | imports/names well-formed | STRUCT | ✅ |
| PO6 | doctest prints match | STRUCT | ✅ |
| PO7 | `eval` removes `z∈{0,1,-1}` first | STRUCT | ✅ |

All STRUCT/Z3 obligations are discharged (constructed, not machine-checked). The two
analytic identities (PO1, PO2) are discharged at the escalation tier with cited
identities + numerical witnesses + SymPy-internal corroboration; they are **not**
faked as `[trusted]`. No obligation fails, and **none forced an invented
precondition** — the inverse of a bug signal.
