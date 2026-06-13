# PROOF OBLIGATIONS — `itrs_observed_transforms.py` (astropy#13398)

The verification conditions (VCs) that, together, establish the `SPEC.md` contracts.
Notation: `M_A = minus_x · R_y(π/2−φ) · R_z(λ)` (AltAz), `M_H = minus_y · R_z(λ)`
(HADec), where `R_z(λ)`, `R_y(α)` are `rotation_matrix` outputs and
`minus_x = diag(−1,1,1)`, `minus_y = diag(1,−1,1)`. `Iᵥ` = 3×3 identity. `·` is
matrix/matrix–vector product = exactly what `CartesianRepresentation.transform`
computes (`erfa rxp`, i.e. `M @ v`, column-vector convention — verified in source).

**Discharge tiers:** `Z3` = linear/equational, bundled; `[SIMP]` = needs a supplied
`[simplification]` lemma; `[ESC]` = `[ESCALATION BOUNDARY]` — real/trigonometric
arithmetic outside the bundled integer tier, discharged here *algebraically* and
routed to the real-closed-field / linear-algebra theory for machine-checking (never
faked as `[trusted]`).

---

## Building-block lemmas

- **L-ROT (rotation matrices are orthogonal).** `R_z(λ)ᵀ·R_z(λ) = Iᵥ` and
  `R_y(α)ᵀ·R_y(α) = Iᵥ`. Reduces to `cos²θ + sin²θ = 1`. Tier: `[SIMP]` lemma
  `sinθ² + cosθ² = 1` (the linear-algebra analogue of the sum example's "exact
  halving" lemma) → then `Z3`. `[ESC]` for the general real-trig closure.
- **L-REFL (reflections are orthogonal & involutive).** `minus_xᵀ = minus_x`,
  `minus_x·minus_x = Iᵥ`; likewise `minus_y`. Tier: `Z3` (diagonal ±1).
- **L-PROD (product of orthogonals is orthogonal).** If `AᵀA = I` and `BᵀB = I` then
  `(AB)ᵀ(AB) = Bᵀ(AᵀA)B = BᵀB = I`. Tier: `Z3` (equational, given L-ROT/L-REFL).

---

## PO1 — `M_A` is orthogonal  `M_A · M_Aᵀ = M_Aᵀ · M_A = Iᵥ`,  `det M_A = −1`
From L-REFL (`minus_x`) and L-ROT (`R_y`, `R_z`) via L-PROD applied twice.
`det = (−1)·(+1)·(+1) = −1` (improper ⇒ left-handed, as `AltAz` is). Tier: `[SIMP]`+`Z3` / `[ESC]` for trig closure.

## PO2 — `M_H` is orthogonal  `M_H · M_Hᵀ = M_Hᵀ · M_H = Iᵥ`,  `det M_H = −1`
From L-REFL (`minus_y`) and L-ROT (`R_z`) via L-PROD. `det = (−1)·(+1) = −1`. Tier: as PO1.

## PO3 — round-trip ITRS→observed→ITRS is the identity (position)
`observed_to_itrs(itrs_to_observed(P)) = M_Xᵀ·(M_X·(P − L)) + L`
`= (M_Xᵀ M_X)·(P − L) + L = Iᵥ·(P − L) + L = P`  for `X ∈ {A,H}`.
Depends on **PO1/PO2** (`M_Xᵀ M_X = Iᵥ`). Tier: `Z3` (equational) given PO1/PO2.
*Exact* — no truncation. (This is the strongest, cleanest correctness property.)

## PO4 — round-trip observed→ITRS→observed is the identity (position)
`itrs_to_observed(observed_to_itrs(Q)) = M_X·((M_Xᵀ·Q + L) − L) = (M_X M_Xᵀ)·Q = Q`.
Depends on **PO1/PO2** (`M_X M_Xᵀ = Iᵥ`). Tier: `Z3` given PO1/PO2. Exact.

## PO5 — AltAz geometric anchors (the matrix is the *correct* one, not just orthogonal)
With `up=(cosφcosλ, cosφsinλ, sinφ)`, `north=(−sinφcosλ, −sinφsinλ, cosφ)`,
`east=(−sinλ, cosλ, 0)`:
- `M_A · up   = (0, 0, 1)`  ⇒ alt = +90° (zenith).
- `M_A · north = (1, 0, 0)` ⇒ az = 0°, alt = 0° (North on horizon).
- `M_A · east  = (0, 1, 0)` ⇒ az = 90°, alt = 0° (East on horizon; Az East-of-North ✓).
Each reduces, after `R_z(λ)` then `R_y(π/2−φ)` then `minus_x`, to `cos²+sin²=1` and the
complementary-angle identities `cos(π/2−φ)=sinφ`, `sin(π/2−φ)=cosφ`. Tier: `[ESC]`
(real trig), discharged by hand in `PROOF.md` §3.1.

## PO6 — HADec geometric anchors
With `merid_eq=(cosλ, sinλ, 0)` (meridian ∩ equator), `pole=(0,0,1)`,
`east=(−sinλ, cosλ, 0)`:
- `M_H · merid_eq = (1, 0, 0)`  ⇒ ha = 0, dec = 0.
- `M_H · pole     = (0, 0, 1)`  ⇒ dec = 90°.
- `M_H · east     = (0, −1, 0)` ⇒ ha = −90° = −6ʰ (East ⇒ **negative** ha ✓ docstring).
Reduces to `cos²+sin²=1`. Tier: `[ESC]`, discharged by hand in `PROOF.md` §3.2.

## PO7 — norm / topocentricity  `|M_X·(P−L)| = |P−L|`
Orthogonal `M_X` preserves the Euclidean norm: `|M_X v|² = vᵀ M_Xᵀ M_X v = vᵀ v = |v|²`.
Depends on PO1/PO2. The output distance is the **observer→target** range. Tier: `Z3`.

## PO8 — `obstime`-independence and exact velocity (justifies the V2 change)
**PO8a (obstime-independence):** `itrs_to_observed` and `observed_to_itrs` are
functions of `(cartesian, location)` only; neither reads `itrs_coo.obstime` nor
`observed_frame.obstime` (the location's ITRS cartesian is obstime-free; `get_itrs()`
is called with the default). ⇒ output is invariant under any change of either
`obstime`. Tier: `Z3` / by inspection of the data-flow.

**PO8b (induced velocity = 0):** the `FunctionTransformWithFiniteDifference`
"frame-induced" term is `(supcall(state, frame@t+Δ) − supcall(state, frame@t−Δ))/2Δ`.
By PO8a both `supcall` evaluations are **bit-identical**, so the term is **exactly
`0.0`**. ⇒ the velocity equals the re-orientation term only.

**PO8c (re-orientation is exact `M·V`):** the position map `X ↦ M·(X − L)` is affine
with constant `M`,`L`, so `(M·(P+V·Δ−L) − M·(P−V·Δ−L))/2Δ = M·V` exactly. Tier: `Z3`
(linearity).

**Consequence:** setting `finite_difference_frameattr_name=None` (V2) removes only the
provably-`0.0` PO8b term ⇒ **bit-identical results** where V1 ran, and avoids the
`None + Δ` crash of Finding 4. This discharges the safety of the only V2 code change.

## PO9 — out-of-domain inputs fail safe (no silent wrong answer)
For `P` (or `Q`) `UnitSpherical`/dimensionless: the `cartesian ∓ location_itrs.cartesian`
operation raises `UnitConversionError` (dimensionless vs metres). For `location is None`:
`AttributeError`. In **no** out-of-domain case does a value get returned. Tier: `Z3` /
by inspection (this is a *liveness-of-failure* obligation, not a postcondition).

---

## Dependency / discharge summary

| PO | depends on | tier | status |
|----|-----------|------|--------|
| L-ROT | — | `[SIMP]`+`Z3` / `[ESC]` trig | constructed |
| L-REFL, L-PROD | — | `Z3` | constructed |
| PO1, PO2 | L-ROT,L-REFL,L-PROD | `[SIMP]`/`[ESC]` | constructed |
| PO3, PO4 | PO1/PO2 | `Z3` | constructed (exact round-trip) |
| PO5, PO6 | L-ROT | `[ESC]` trig | constructed by hand |
| PO7 | PO1/PO2 | `Z3` | constructed |
| PO8a/b/c | data-flow, linearity | `Z3` | constructed (justifies V2) |
| PO9 | unit algebra | `Z3`/inspection | constructed |

All obligations are **constructed, not machine-checked** (no execution environment).
The `[ESC]` trig obligations are the residual machine-check risk; they are standard
identities, hand-verified in `PROOF.md`, and routed (not faked) per the kit's honesty
gate.
