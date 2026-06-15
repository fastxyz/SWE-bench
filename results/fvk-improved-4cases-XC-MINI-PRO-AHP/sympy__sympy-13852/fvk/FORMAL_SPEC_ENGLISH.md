# FORMAL_SPEC_ENGLISH — paraphrase of the K claims

Plain-English meaning of every claim in `polylog-expand-spec.k`, read as if it were
the only spec. Compared against `INTENT_SPEC.md` in `SPEC_AUDIT.md`.

- **(PL1)** `expandPolylog(1, z) => Neg(Log(Sub(1, z)))`
  → "Expanding `polylog(1, z)` yields `-log(1 - z)`." The right-hand side contains
  no `exp_polar`/winding factor. *(Paraphrase of intent I2, I4.)*

- **(PL2)** `expandPolylog(2, Half) => Add(Neg(Div(Pow(Log(2),2),2)), Div(Pow(Pi,2),12)))`
  → "Expanding `polylog(2, 1/2)` yields `-log(2)**2/2 + pi**2/12`." *(Paraphrase of
  intent I1.)*

- **(PL0)** `expandPolylog(0, z) => Div(z, Sub(1, z))`
  → "Expanding `polylog(0, z)` yields `z/(1 - z)`." *(Paraphrase of frame I5; the
  fix does not change this branch.)*

- **(PLF, s=3)** `expandPolylog(3, z) => PolyLog(3, z)`
  → "`polylog(3, z)` has no implemented closed form and is returned unchanged."
  *(Paraphrase of frame I5 fallback.)*

- **(PLF, s=2,z≠1/2)** `expandPolylog(2, z) => PolyLog(2, z)`
  → "`polylog(2, z)` for a generic `z` is returned unchanged; the new dilog branch
  fires only at `z = 1/2`." *(Guards the special case — paraphrase of I1's scope.)*

- **(PLDERIV-FIX, left)** `Diff(Neg(Log(Sub(1, z))), z) => Div(1, Sub(1, z))`
  → "The derivative of the expansion `-log(1 - z)` is `1/(1 - z)`." *(Paraphrase of
  intent I3.)*

- **(PLDERIV-FIX, right)** `Div(expandPolylog(0, z), z) => Div(1, Sub(1, z))`
  → "`d/dz polylog(1, z) = polylog(0, z)/z`, and `polylog(0, z)` expands to
  `z/(1 - z)`, so this equals `1/(1 - z)`." Same normal form as the left claim,
  hence expansion preserves the derivative. *(Paraphrase of intent I3 — the bug the
  old `exp_polar` form caused.)*

## Frame / side conditions paraphrased

- The dispatcher is **total** on the modelled domain: every `(s, z)` matches exactly
  one branch (`s=1`; `s=2,z=1/2`; integer `s<=0`; otherwise the `[owise]`
  fallback). No input is left without a result. *(Supports "no missing case".)*
- The s≤0 branch is modelled as the abstract `ratPolylog(s, z)` with the concrete
  instance `ratPolylog(0, z) = z/(1-z)`. The English claim is only that the fix
  **leaves this branch unchanged**; its internal loop is not re-proved here (it is
  pre-existing, correct, and outside the fix — see PROOF.md §Loop).
- Differentiation rules paraphrase to the standard identities: `d z/dz = 1`,
  `d(const)/dz = 0`, linearity over `Neg`/`Sub`, `d log(E)/dz = E'/E`, and the
  SymPy `fdiff` rule `d polylog(s,z)/dz = polylog(s-1,z)/z`.
