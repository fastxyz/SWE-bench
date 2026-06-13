# FVK artifact excerpts — astropy__astropy-13398 (batch1-XC-MINI-PRO-AHP)

Curated, source-labeled excerpts from the `fvk/` markdown artifacts (no `.k` files
exist for this instance). Goal: surface every passage that touches the root-cause
REGION (the `itrs_to_observed_mat` matrix construction, the observer/geodetic basis,
the topocentric subtraction, the geometry/anchor claims), whether or not it carries
the true defect signal. The fvk arm FAILED (patched code still fails hidden tests).

All source files under:
`/home/xc/Projects/fastxyz-SWE-bench/results/batch1-XC-MINI-PRO-AHP/astropy__astropy-13398/`

================================================================================
## 1. WHAT FVK FORMALIZED — SPEC.md
================================================================================

### SPEC.md L27-44 — F1: itrs_to_observed_mat contract (THE matrix-build region)
> ## F1 — `itrs_to_observed_mat(observed_frame) → M : 3×3 real matrix`
> Builds the rotation matrix from the topocentric ITRS basis to the observed basis,
> from the observer's WGS84 geodetic longitude `λ` and latitude `φ`.
> - **Precondition P1.1:** `observed_frame.location is not None`
> - **Precondition P1.2:** `observed_frame` is an `AltAz` or a `HADec` instance
> - **Postcondition:**
>   - AltAz: `M = minus_x · R_y(π/2 − φ) · R_z(λ)`
>   - HADec: `M = minus_y · R_z(λ)`
>   ... `minus_x = diag(−1,1,1)`, `minus_y = diag(1,−1,1)` (reflections).
> - **Guaranteed property (proved):** `M` is **orthogonal** — `M · Mᵀ = Mᵀ · M = I` —
>   with `det M = −1` (left-handed/improper ...). Hence `Mᵀ = M⁻¹`. (Obligation **PO1/PO2**.)

NOTE (analyst): The spec accepts the WGS84 geodetic latitude `φ` directly as the
angle fed to `R_y(π/2 − φ)`. There is NO mention anywhere of geodetic-vs-geocentric
latitude. The only proved property of `M` is *orthogonality + det=−1*; orthogonality
is necessary but NOT sufficient for the matrix to be the geometrically correct one.
The "correctness" beyond orthogonality is asserted only via the hand-checked anchors
(PO5/PO6), which are themselves built from `up=(cosφcosλ,...)` using the SAME φ.

### SPEC.md L46-75 — F2: itrs_to_observed (topocentric subtraction region)
> - **Precondition P2.1 (distance):** `itrs_coo` carries a **dimensional 3-D Cartesian
>   position** ... *not* a `UnitSpherical`/dimensionless direction.
> - **Postcondition (position):** with `P = itrs_coo.cartesian`,
>   `L = observed_frame.location.get_itrs().cartesian`,
>   `M = itrs_to_observed_mat(observed_frame)`:
>   `result.cartesian = M · (P − L)`     (topocentric, then rotated)
> - **Postcondition (obstime):** ... the **input `obstime` is ignored** ... The result
>   is **independent of both frames' `obstime`** (PO8).

### SPEC.md L99-107 — "Domain summary" (the clean-spec claim)
> The contract is **clean and total on its domain** ... On `D`, F1–F3 are correct and
> the round-trips are exact. The fact that the spec is clean (no awkward case splits,
> no missing closed form) is itself evidence the code is not hiding a corner-case bug
> ... Behavior **outside** `D` ... each out-of-domain input **fails safe** with an
> exception — never a silent wrong answer.

================================================================================
## 2. FINDINGS.md — recorded findings + verdict markers
================================================================================

### FINDINGS.md L3-7 — HEADLINE VERDICT
> **Headline result: no input produces a silent wrong answer.** The geometry is
> correct, the round-trips are exact, and every out-of-domain input **fails safe with
> an exception**. The findings below are therefore *robustness / UX recommendations*
> plus one applied fix (F4).

Finding-by-finding classification (the artifact's own verdicts):
- **Finding 1** (L15-33): "missing precondition: input must have a distance" — class
  `missing precondition (fail-safe)`, severity low. NOT applied in V2.
- **Finding 2** (L35-44): "observed frame must have a non-None location" — class
  `missing precondition (fail-safe)`, low. NOT applied.
- **Finding 3** (L46-61): "`obstime` is intentionally ignored" — class
  `positive / underspecified intent`, informational.
- **Finding 4** (L63-91): "moving object + observed frame with `obstime=None` crashes"
  — class `needed code guard / robustness`, severity medium. **THE ONE APPLIED FIX.**
- **Finding 5** (L93-102): "geometry and round-trip are correct (positive)".
- **Finding 6** (L103-108): "velocity is correctly re-oriented (positive)".

### FINDINGS.md L93-101 — Finding 5 (the geometry "positive", asserts no defect)
> ## Finding 5 — geometry and round-trip are correct (positive)
> **Classification:** positive. **Severity:** informational.
> - AltAz anchors: zenith→alt 90°, North→az 0°, East→az 90° (PO5) — hand-derived and
>   re-checked; matches `AltAz` docstring (Az East-of-North).
> - HADec anchors: meridian-equator→(ha 0, dec 0), pole→dec 90°, East→negative ha (PO6)
>   — matches `HADec` docstring ("hour angle negative to the East").
> - Round-trips ITRS→obs→ITRS and obs→ITRS→obs are **exact** because `M` is orthogonal
>   (PO1–PO4). No off-by-sign, no axis swap.

NOTE (analyst): This is the single place the artifacts could have caught a geometry
defect. The arm AFFIRMS correctness here ("No off-by-sign, no axis swap") — it does
NOT flag the region as defective. The anchors are self-consistent with the chosen
matrix but were "hand-derived" with no execution.

### FINDINGS.md L112-120 — "Spec-difficulty signal" (clean spec = no bug, inverted)
> Writing the spec was **easy** ... There was **no** forced case split, **no** missing
> closed form ... Per the kit's "if a clean spec is hard, that's a bug signal" rule,
> the *converse* holds here: the spec is clean ⇒ this is weak positive evidence the
> code has no hidden corner-case bug **on its domain**. The only "rough edges" are the
> out-of-domain inputs (Findings 1, 2, 4), all of which fail safe.

================================================================================
## 3. PROOF_OBLIGATIONS.md — the VCs and their status
================================================================================

All POs are "constructed, not machine-checked". Status table (PROOF_OBLIGATIONS.md
L100-109): every PO marked "constructed". Trig VCs (PO1/PO2/PO5/PO6) tier `[ESC]`.

### PROOF_OBLIGATIONS.md L48-56 — PO5 AltAz anchors (defines the basis vectors)
> ## PO5 — AltAz geometric anchors (the matrix is the *correct* one, not just orthogonal)
> With `up=(cosφcosλ, cosφsinλ, sinφ)`, `north=(−sinφcosλ, −sinφsinλ, cosφ)`,
> `east=(−sinλ, cosλ, 0)`:
> - `M_A · up   = (0, 0, 1)`  ⇒ alt = +90° (zenith).
> - `M_A · north = (1, 0, 0)` ⇒ az = 0°, alt = 0° (North on horizon).
> - `M_A · east  = (0, 1, 0)` ⇒ az = 90°, alt = 0° (East on horizon; Az East-of-North ✓).

NOTE (analyst): `up`,`north`,`east` here are the local ENU basis expressed via the
SAME geodetic φ used to build `M`. So PO5 is internally circular w.r.t. any
geodetic/geocentric latitude question: it proves `M` maps "the φ-basis" to the
observed axes, not that the φ-basis is the physically correct local vertical at the
observer's geocentric ITRS position. The check is self-consistent and PASSES on its
own terms.

### PROOF_OBLIGATIONS.md L66-68 — PO7 norm/topocentricity
> ## PO7 — norm / topocentricity  `|M_X·(P−L)| = |P−L|`
> ... The output distance is the **observer→target** range.

### PROOF_OBLIGATIONS.md L70-88 — PO8 (justifies the only V2 change)
> **PO8a (obstime-independence):** `itrs_to_observed` and `observed_to_itrs` are
> functions of `(cartesian, location)` only ... ⇒ output is invariant under any change
> of either `obstime`.
> **PO8b (induced velocity = 0):** ... the term is **exactly `0.0`**.
> **Consequence:** setting `finite_difference_frameattr_name=None` (V2) removes only the
> provably-`0.0` PO8b term ⇒ **bit-identical results** where V1 ran, and avoids the
> `None + Δ` crash of Finding 4.

### PROOF_OBLIGATIONS.md L90-94 — PO9 out-of-domain fail-safe
> ## PO9 — out-of-domain inputs fail safe (no silent wrong answer)
> ... In **no** out-of-domain case does a value get returned.

================================================================================
## 4. PROOF.md — constructed proof (the algebraic core)
================================================================================

### PROOF.md L126-144 — §3.0 Orthogonality (PO1/PO2), the proof core
> By **L-ROT**, each `Rz(L)`, `Ry(A)` satisfies `Rᵀ·R = I` ... By **L-REFL**,
> `minusXᵀ·minusX = eye` ... By **L-PROD**, for `M = minusX·Ry·Rz`:
> ```
> Mᵀ·M = ... = Rzᵀ·Rz = I   [L-ROT ×2]
> ```
> ⇒ **(ORTHO-A)** `M_A Mᵀ_A = M_Aᵀ M_A = I`. ... `det M = ∓1` from the reflection
> factor ⇒ left-handed. ∎

### PROOF.md L146-156 — §3.1 AltAz anchors (symbolic exec, the geometry "proof")
> `up = v(cosφ cosλ, cosφ sinλ, sinφ)`. Apply `Rz(λ)` ... `Rz(λ)·up = v(cosφ, 0, sinφ)`
> ... Apply `Ry(π/2−φ)` with `cos(π/2−φ)=sinφ`, `sin(π/2−φ)=cosφ`:
> `Ry·v(cosφ,0,sinφ) = v(... ) = v(0,0,1)`. Apply `minusX`: `v(0,0,1)`. ⇒ alt = 90°. ∎

### PROOF.md L194-208 — §5 Residual risk / honesty gate
> - **Constructed, not machine-checked.** No `kompile`/`kprove` was run (no environment).
> - **Trusted base:** (i) adequacy of the mini-linalg fragment as a model of
>   numpy/erfa `rxp`/`rotation_matrix` (faithful for the ops used; floating-point is
>   idealized to ℝ ...); ...
> - **Escalation boundary:** PO1/PO2/PO5/PO6 rest on real-trigonometric identities ...
>   They are standard, hand-verified here, and routed ... — **not** admitted as
>   `[trusted]`.

NOTE (analyst): The proof's "trusted base" idealizes to ℝ and asserts the mini-linalg
fragment is a "faithful model of ... rotation_matrix" — it never re-derives WHAT
`rotation_matrix(angle,'y'/'z')` produces relative to the SIGN/handedness the geometry
needs, nor whether geodetic φ is the right angle. Any defect living in the matrix's
geometric *content* (as opposed to its orthogonality) is inside the trusted base and
would not be caught.

================================================================================
## 5. ITERATION_GUIDANCE.md — final disposition
================================================================================

### ITERATION_GUIDANCE.md L73-79 — BOTTOM LINE (final stated conclusion)
> ## Bottom line
> The core transform logic is **confirmed correct on its domain** (geometry + exact
> round-trips + exact velocity) and is left unchanged. The only applied edit is the
> zero-risk, audit-justified Finding-4 fix. All remaining findings are fail-safe
> robustness/UX items that hinge on **intent questions** the maintainers must answer,
> so they are surfaced as guidance rather than guessed into code.

================================================================================
## 6. reports/fvk_notes.md — decision log
================================================================================

### fvk_notes.md L24-43 — Decision 1: keep matrix-build + bodies UNCHANGED
> ## Decision 1 — keep the matrix-build and the two transform bodies unchanged
> **Traces to:** PO1, PO2 (orthogonality), PO3, PO4 (exact round-trip), PO5, PO6
> (geometry anchors), PO7 (norm); Findings 5, 6 (positive).
> ... Because the contract is clean and the obligations discharge, V1 is **correct on
> its domain**, so per the task ... I left F1/F2/F3 bodies untouched. Changing them
> would only risk diverging from the reference implementation that the hidden tests pin.

NOTE (analyst): This is the decisive call. The arm explicitly decided NOT to alter the
matrix-build (`itrs_to_observed_mat`) — the exact region most likely to host the true
defect — on the grounds that orthogonality+anchors prove it "correct on its domain"
and that changing it risks diverging from the reference. The fvk arm nonetheless FAILED
the hidden tests, so the defect is in code it deliberately left intact.
