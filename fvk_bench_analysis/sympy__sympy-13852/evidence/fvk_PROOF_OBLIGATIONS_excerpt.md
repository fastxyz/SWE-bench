# Evidence excerpts — fvk/PROOF_OBLIGATIONS.md  (sympy__sympy-13852)
Source: results/batch5-XC-MINI-PRO-AHP-260614105258/sympy__sympy-13852/fvk/PROOF_OBLIGATIONS.md
Quoted verbatim with line numbers. (PROOF.md cross-refs included at end.)

## PO1 — s==1 -> -log(1-z), incl. branch cut  (escalation)
- PROOF_OBLIGATIONS.md:15 "## PO1 — `s == 1` branch value (VC-Li1)"
- PROOF_OBLIGATIONS.md:16-18 "**Statement.** `expand_func(polylog(1, z)) = -log(1 -
  z)`, and `-log(1 - z)` is analytically equal to `polylog(1, z)` **including branch
  cuts**: for real `z > 1`, both have imaginary part `-pi`."
- PROOF_OBLIGATIONS.md:20-21 "**Tier.** Code value: STRUCT (the branch literally
  returns `-log(1 - z)`). Analytic equality: ESCALATION."
- PROOF_OBLIGATIONS.md:22-28 discharge cites series, branch cut (Im=-pi), mpmath,
  hyperexpand (test_hyperexpand.py:582), eval consistency at z in {-1,0}.
- PROOF_OBLIGATIONS.md:29 "**Status.** ⛰ (value ✅, analytic identity ⛰)"

## PO2 — s==2,z==1/2 -> pi^2/12 - log(2)^2/2  (escalation) — ONLY value proven
- PROOF_OBLIGATIONS.md:31 "## PO2 — `s == 2, z == 1/2` branch value (VC-Li2½)"
- PROOF_OBLIGATIONS.md:32-33 "**Statement.** `expand_func(polylog(2, S.Half)) =
  pi**2/12 - log(2)**2/2`, and that equals `Li_2(1/2)`."
  >>> NOTE: stated as expand_func(...), matching the WRONG method. Gold asserts bare
  polylog(2, S.Half) == ... (no expand). PO2 never proves the construction-time form.
- PROOF_OBLIGATIONS.md:36-41 discharge: reflection/Landen identity at x=1/2 +
  numerical witness 0.5822405264. Only z==1/2; no z==2, no golden-ratio values.
- PROOF_OBLIGATIONS.md:42 "**Status.** ⛰ (value ✅, identity ⛰)"

## PO3 — disjoint/exhaustive, "no regression" (CERTIFIES the narrowness)
- PROOF_OBLIGATIONS.md:44-46 "## PO3 — branch disjointness / exhaustiveness (no
  regression) **Statement.** The inserted `s==2 ∧ z==½` rule does not shadow,
  reorder, or remove any input from the pre-existing branches; the dispatch is total."
- PROOF_OBLIGATIONS.md:50-55 "Guard sets: `{s=1}`, `{s=2 ∧ z=½}`, `{s∈ℤ, s≤0}`,
  default. ... union = all of `SVal × ZVal`. Therefore each of the four `<out>`
  rewrites fires on exactly its Python branch. ... ✅"
  >>> "Totality/exhaustiveness ✅" is asserted over a 2-point ZVal abstraction
  {half, zoth}. It declares the dispatch total while the real domain (z=2,
  golden-ratio args) is collapsed into the inert `zoth`/default bucket. The
  abstraction HIDES the missing cases the gold test exercises.

## PO4 — commutes with d/dz
- PROOF_OBLIGATIONS.md:57-68 "## PO4 ... `d/dz E(s,z) = E(s-1, z)/z` ... `polylog.fdiff`
  is unchanged by V1 (`polylog(s, z).diff(z) = polylog(s-1, z)/z`). ... ✅"

## PO5 — imports / no NameError
- PROOF_OBLIGATIONS.md:70-77 "## PO5 ... Removed `exp_polar`, `I` are not referenced
  anywhere in the method. ✅"

## PO6 — doctests print as written
- PROOF_OBLIGATIONS.md:79-89 "## PO6 ... `expand_func(polylog(1, z))` → `-log(-z +
  1)`; `expand_func(polylog(2, S.Half))` → `-log(2)**2/2 + pi**2/12`. ... ✅"

## PO7 — eval precedence keeps z in {0,1,-1} out of this method  (TELL: looked AT
## the gold fix site (eval) but only as a pre-filter, never as the fix location)
- PROOF_OBLIGATIONS.md:91-93 "## PO7 — `eval` precedence keeps `z ∈ {0, 1, -1}` out
  of this method **Statement.** `_eval_expand_func` never has to produce a value for
  the singular points `z ∈ {0, 1, -1}`; `polylog.eval` returns `0 / zeta(s) /
  -dirichlet_eta(s)` first."
- PROOF_OBLIGATIONS.md:96-100 "**Tier.** STRUCT (inspection of `polylog.eval`, lines
  278-285). **Discharge.** `eval` is a `@classmethod` run at construction; for
  `z∈{0,1,-1}` it returns a value, so the `polylog(...)` object ... is never built
  with those `z`. ... ✅"
  >>> The agent READ polylog.eval (lines 278-285) and correctly understood it is a
  @classmethod that returns special values at construction time — yet concluded only
  that it filters z∈{0,1,-1}. It never connected "eval returns construction-time
  closed forms" to "the new dilog values belong in eval," which is exactly the gold
  fix. The pointed-at-the-spot signal was present and was misread.

## Summary table + closing (TELL: undischarged escalation + "no invented precond")
- PROOF_OBLIGATIONS.md:104-114 summary table; PO1, PO2 marked ⛰ (escalation,
  identity not machine-checked).
- PROOF_OBLIGATIONS.md:116-120 "The two analytic identities (PO1, PO2) are discharged
  at the escalation tier with cited identities + numerical witnesses + SymPy-internal
  corroboration; they are **not** faked as `[trusted]`. No obligation fails, and
  **none forced an invented precondition** — the inverse of a bug signal."
  >>> TELL (b): PO1/PO2 are the undischarged (escalation-boundary) obligations.
  TELL (inverse): "no invented precondition" used as affirmative correctness signal.
  No obligation anywhere asks for the BARE-eval form or for z!=1/2 dilog values, so
  the proof can close while the code fails the real test.
