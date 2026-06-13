# SPEC — `itrs_observed_transforms.py` (V1 fix for astropy#13398)

Human-readable specification (intent-spec mode) for the three functions added by the
V1 fix, plus the registration in `builtin_frames/__init__.py`. Variables: uppercase
for mathematical/logical values (`P`, `L`, `M`, `V`, `λ`, `φ`), lowercase for program
objects.

The code is **pure linear algebra over ℝ³** (vector subtraction/addition, a 3×3
matrix–vector product, a matrix transpose, and rotation/reflection matrices). It has
**no loops and no recursion**, so there are **no loop/recursion circularities** to
state (see `PROOF.md` §0). The contracts below are ordinary
pre/post-condition reachability rules `φ_pre ⇒ φ_post`.

---

## Intent (from `benchmark/PROBLEM.md` and the issue thread)

Provide a **direct** transform between `ITRS` and the observed frames `AltAz` /
`HADec` that **stays entirely within the ITRS**: form the topocentric ITRS vector
(target minus observer) and **rotate** it into the left-handed observed basis. The
transform is **time-invariant** — it must *not* perform an `ITRS→ITRS` re-referencing
across `obstime` (that throws nearby positions out toward the SSB); the output frame's
`obstime` is simply adopted. No aberration, no refraction.

---

## F1 — `itrs_to_observed_mat(observed_frame) → M : 3×3 real matrix`

Builds the rotation matrix from the topocentric ITRS basis to the observed basis,
from the observer's WGS84 geodetic longitude `λ` and latitude `φ`.

- **Precondition P1.1:** `observed_frame.location is not None`
  (`.to_geodetic(...)` is called on it).
- **Precondition P1.2:** `observed_frame` is an `AltAz` or a `HADec` instance
  (it is only ever called on those; the `isinstance(., AltAz)` branch selects the form).
- **Postcondition:**
  - AltAz: `M = minus_x · R_y(π/2 − φ) · R_z(λ)`
  - HADec: `M = minus_y · R_z(λ)`

  where `R_z`,`R_y` are `matrix_utilities.rotation_matrix` outputs (proper rotations,
  `Rᵀ = R⁻¹`) and `minus_x = diag(−1,1,1)`, `minus_y = diag(1,−1,1)` (reflections).
- **Guaranteed property (proved):** `M` is **orthogonal** — `M · Mᵀ = Mᵀ · M = I` —
  with `det M = −1` (left-handed/improper, as both observed frames are left-handed).
  Hence `Mᵀ = M⁻¹`. (Obligation **PO1/PO2**.)

## F2 — `itrs_to_observed(itrs_coo, observed_frame) → observed_frame coordinate`

Registered for `ITRS→AltAz` and `ITRS→HADec`.

- **Precondition P2.1 (distance):** `itrs_coo` carries a **dimensional 3-D Cartesian
  position** (length units) — i.e. *not* a `UnitSpherical`/dimensionless direction.
  (The body computes `itrs_coo.cartesian − location_itrs.cartesian`; the two operands
  must share length units.)
- **Precondition P2.2 (location):** `observed_frame.location is not None` (= P1.1).
- **Postcondition (position):** with `P = itrs_coo.cartesian`,
  `L = observed_frame.location.get_itrs().cartesian`, `M = itrs_to_observed_mat(observed_frame)`:

  `result.cartesian = M · (P − L)`     (topocentric, then rotated)

- **Postcondition (norm / topocentricity):** `|result.cartesian| = |P − L|` — the
  line-of-sight distance from the *observer* is preserved (PO7).
- **Postcondition (anchors, the geometry is the *right* one):** for an observer at
  `(λ, φ)`, with `up`,`north`,`east` the local ITRS unit vectors (PO5/PO6):
  - AltAz: `up → alt = +90°`; `north → az = 0°, alt = 0°`; `east → az = 90°, alt = 0°`.
  - HADec: meridian-on-equator `→ ha = 0, dec = 0`; pole `→ dec = 90°`; an eastward
    direction `→ negative ha` (matches the `HADec` docstring "negative to the East").
- **Postcondition (obstime):** `result` carries `observed_frame`'s attributes,
  including its `obstime` (possibly `None`); the **input `obstime` is ignored** and no
  `ITRS→ITRS` time transform is performed. The result is **independent of both frames'
  `obstime`** (PO8).
- **Velocity (when `itrs_coo` has a differential `V`):** handled by
  `FunctionTransformWithFiniteDifference`. Because the position map is the affine
  `X ↦ M·(X − L)` with `M, L` constant in time, the output differential is exactly
  `M·V` (re-orientation only); the frame-induced component is **identically zero**
  (PO8). V2 sets `finite_difference_frameattr_name=None` to declare this.

## F3 — `observed_to_itrs(observed_coo, itrs_frame) → ITRS coordinate`

Registered for `AltAz→ITRS` and `HADec→ITRS`. Exact inverse of F2.

- **Precondition P3.1 (distance):** `observed_coo` carries a dimensional 3-D Cartesian
  position (length units), not a `UnitSpherical`/dimensionless direction. (The body
  adds `location_itrs.cartesian`, which has length units.)
- **Precondition P3.2 (location):** `observed_coo.location is not None`.
- **Postcondition (position):** with `Q = observed_coo.cartesian`,
  `L = observed_coo.location.get_itrs().cartesian`, `M = itrs_to_observed_mat(observed_coo)`:

  `result.cartesian = Mᵀ · Q + L`

- **Round-trip (the headline correctness property):**
  - `observed_to_itrs(itrs_to_observed(P)) = Mᵀ·(M·(P − L)) + L = (Mᵀ M)(P − L) + L = P`
  - `itrs_to_observed(observed_to_itrs(Q)) = M·(Mᵀ·Q + L − L) = (M Mᵀ)·Q = Q`

  Both are **exact** (no truncation/approximation) because `M Mᵀ = Mᵀ M = I`
  (PO1/PO2 ⇒ PO3/PO4).

---

## Domain summary

The contract is **clean and total on its domain**
`D = { dimensional 3-D ITRS/observed position } × { observed frame with non-None location }`.
On `D`, F1–F3 are correct and the round-trips are exact. The fact that the spec is
clean (no awkward case splits, no missing closed form) is itself evidence the code is
not hiding a corner-case bug (Findings §"spec-difficulty"). Behavior **outside** `D`
is covered in `FINDINGS.md` (each out-of-domain input **fails safe** with an
exception — never a silent wrong answer).
