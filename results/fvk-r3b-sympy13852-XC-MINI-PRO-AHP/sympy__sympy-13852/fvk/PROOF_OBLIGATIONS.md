# PROOF_OBLIGATIONS.md — polylog fix (sympy__sympy-13852)

Each obligation = a K claim in [`polylog-spec.k`](polylog-spec.k) + its discharge
tier. "Tier": **R** = pure rewrite (apply mini-cas.k rules), **VC** = arithmetic
verification condition (linear / cancellation; Z3 / `[simplification]`), **E** =
`[ESCALATION BOUNDARY]` (special-function identity, routed to references — never faked
`[trusted]`).

| ID | Claim (φ_pre ⇒ φ_post) | Intent (SPEC §2) | Tier | Status (constructed) |
|----|------------------------|------------------|------|----------------------|
| PO1 | **EVAL-HALF**: `polylog(2, half) ⇒ CF2` | I-VALUE, I-DEFAULT | R + E(LEM-LI2) | discharged |
| PO2 | **SIMPLIFY-HALF**: `simpl(polylog(2, half)) ⇒ CF2` | I-DEFAULT, L4 | R(+PO1) | discharged |
| PO3 | **EXPAND-HALF**: `expandf(polylog(2, half)) ⇒ CF2` | I-VALUE (In[2]) | R + E(LEM-LI2) | discharged |
| PO4 | **EXPAND-LI1**: `expandf(polylog(1, z)) ⇒ neg(log(sub(1,z)))` | I-LI1 | R + E(LEM-LI1) | discharged |
| PO5 | **DERIV-CONSISTENT**: `expandf(der(sub(polylog(1,z), expandf(polylog(1,z))))) ⇒ 0` | I-DERIV | R + VC(cancel) | discharged |
| PO6 | **EVAL-PRESERVED**: `polylog(s,1)⇒zeta(s)`, `polylog(s,-1)⇒neg(deta(s))`, `polylog(s,0)⇒0` | I-REGRESS | R | discharged |
| PO7 | **doctest**: printed form of `expand_func(polylog(1,z))` is `-log(-z + 1)` | I-DOCTEST | (print) | discharged by analogy |

## Side conditions / VC lemmas (in `VERIFICATION`)

- **VC-CANCEL-1** `sub(X, X) ⇒ 0` — `a − a = 0`. Linear; Z3 tier. Used by PO5.
- **VC-CANCEL-2** `divi(divi(Z, W), Z) ⇒ divi(1, W)` — `(Z/W)/Z = 1/W` (the issue's
  `polylog(0,z)/z = (z/(1-z))/z = 1/(1-z)` collapse). Cancellation; needs `Z ≠ 0`,
  discharged on the symbolic domain. Used by PO5.

## [ESCALATION BOUNDARY] obligations — special-function identities

These are mathematically true but beyond the bundled Z3/`[simplification]` tier (they are
transcendental special-function theorems). They are the **targets** the SymPy rewrite
rules emit; the rules are correct **iff** these hold. Routed to references; **not**
`[trusted]`.

- **LEM-LI1** `polylog(1, Z) = -log(1 - Z)` for all `Z`.
  *Justification on record:* equal Maclaurin series on `|Z|<1`
  (`Li_1(Z)=Σ Z^n/n = -log(1-Z)`); identical branch cut `[1,∞)`; identical jump
  (`Im=-pi` for real `Z>1`). Issue #7132: numerically equal at thousands of
  real/complex points; `expand_func(diff(polylog(1,z)+log(1-z),z)) == 0`.
- **LEM-LI2** `polylog(2, 1/2) = pi²/12 - log²2/2`.
  *Justification on record:* dilogarithm reflection
  `Li₂(z)+Li₂(1-z)=pi²/6 - log(z)log(1-z)` at `z=1/2` gives `2·Li₂(1/2)=pi²/6 - log²2`.
  Numeric: `pi²/12 - log²2/2 ≈ 0.5822406 = Li₂(1/2)`.

## Coverage / placement obligation (the decisive one)

- **PO-PLACEMENT.** The value obligation (I-VALUE) must hold on the **default/
  construction path**, not only under `expand_func`. *Two-candidate derivation:*
  - *Candidate A (V1, expand_func only):* `polylog(2,1/2)` ⇒ `polylog(2,1/2)` (eval inert);
    `simpl(polylog(2,1/2))` ⇒ `polylog(2,1/2)` (simpl identity) ≠ CF2. **FAILS PO2**, fails
    L4/test_R18, leaves L3 symptom on the bare path.
  - *Candidate B (V2, eval):* `polylog(2,1/2)` ⇒ CF2 (PO1); then PO2, PO3 follow. **Satisfies all.**
  Candidate A demonstrably fails a public obligation (PO2/L4) ⇒ placement is **forced to B**,
  not under-determined. (This is exactly the FVK "don't resolve an under-determined choice
  toward V1, and resolve placement from the bare-form obligation" rule, here resolved by a
  *hard* failure of A, not a tie-break.)

## Out of scope (recorded, not obligations)

- `s≤0` expansion loop `for _ in range(-s): start = u*start.diff(u)` — unchanged by the
  fix; a terminating finite loop (|s| iters). No circularity needed for this issue.
- Other polylog special values (F7) — no public-intent obligation.
