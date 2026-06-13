# FINDINGS — `itrs_observed_transforms.py` (astropy#13398)

Plain-language findings from writing the spec (`/formalize`) and constructing the
proof (`/verify`). Each is `input → observed vs expected`. **Headline result: no
input produces a silent wrong answer.** The geometry is correct, the round-trips are
exact, and every out-of-domain input **fails safe with an exception**. The findings
below are therefore *robustness / UX recommendations* plus one applied fix (F4).

Legend for classification: `code bug` · `missing precondition` · `needed code guard`
· `underspecified intent` · `termination/perf` · `test gap` · `proof capability gap`
· `positive` (the code does the right thing).

---

## Finding 1 — missing precondition: input must have a distance (3-D position)
**Classification:** missing precondition (fail-safe). **Severity:** low.

- input: `ITRS(UnitSphericalRepresentation(10*u.deg, 20*u.deg)).transform_to(AltAz(location=loc, obstime=t))`
- observed: raises `UnitConversionError` deep inside representation arithmetic —
  the body computes `itrs_coo.cartesian - location.get_itrs().cartesian`, i.e.
  `dimensionless − metres`.
- expected (per intent): a *clear* error stating that a topocentric ITRS↔observed
  transform requires a 3-D position with a distance (parallax is the whole point);
  a direction-only coordinate is almost always a user mistake.

This is exactly the gap the issue reviewers flagged ("the coordinates better have a
distance" — @mhvk; "error handling for nonsensical inputs" — @StuartLittlefair). It
is **not a correctness bug**: the function never returns a wrong direction, it
*refuses* (raises). Precondition **P2.1/P3.1** in `SPEC.md` makes the assumption
explicit. **Recommendation:** raise an explicit, friendly error (e.g. `ValueError`)
when `data` is `UnitSpherical`/`x.unit == u.one`. **Not applied in V2** — see
`ITERATION_GUIDANCE.md` for why (error-type is an intent question, and the reference
implementation deliberately leaves this to fail-safe + documentation).

## Finding 2 — missing precondition: observed frame must have a non-None location
**Classification:** missing precondition (fail-safe). **Severity:** low.

- input: `itrs.transform_to(AltAz(obstime=t))`  (no `location`)
- observed: `AttributeError: 'NoneType' object has no attribute 'get_itrs'`
  (and `.to_geodetic` inside `itrs_to_observed_mat`).
- expected: a clear error that an observed frame needs an `EarthLocation`.

Same character as Finding 1 — fail-safe, not a wrong answer; **P1.1/P2.2/P3.2**.
**Recommendation:** explicit guard. **Not applied in V2** (same reasoning as F1).

## Finding 3 — `obstime` is intentionally ignored (time-invariant transform)
**Classification:** positive / underspecified intent. **Severity:** informational.

- input: `ITRS(pos, obstime=T1).transform_to(AltAz(location=loc, obstime=T2))`, `T1 ≠ T2`
- observed: the position is rotated using only `loc`; `T1` and `T2` are not used to
  re-reference the ITRS position. Result adopts `T2`.
- expected (per intent, PROBLEM.md ¶2 and the thread): **this is the desired
  behavior.** An `ITRS→ITRS` re-reference across time would send a nearby position
  millions of km toward the SSB. PO8 proves the output is independent of both
  `obstime`s.

This is a *positive* finding (code matches intent), but it carries an
**UltimatePowers question** the maintainers debated and did not settle in the draft:
*should a transform with `obstime` present and differing in both frames emit a warning
(or raise), suggesting `ITRS→ICRS→ITRS'` if a true time transform was intended?*
Left as a documentation/UX item; does not affect correctness on the domain.

## Finding 4 — moving object + observed frame with `obstime=None` crashes (APPLIED FIX)
**Classification:** needed code guard / robustness (fail-safe today). **Severity:** medium for the motivating use case.

- input: a **moving** satellite, `ITRS(pos_with_velocity, obstime=t).transform_to(AltAz(location=loc))`
  — note `AltAz` left at its default `obstime=None`, which is *legitimate* here since
  the transform is time-invariant.
- observed (V1, default `finite_difference_frameattr_name='obstime'`): the
  finite-difference machinery computes the "frame-induced" velocity by shifting the
  frame `obstime` by `±dt/2`, i.e. `getattr(toframe, 'obstime') + halfdt` =
  `None + halfdt` → **`TypeError`**.
- expected: the velocity is just the re-orientation `M·V` of the input differential;
  the frame-induced part is **identically zero** (PO8), so no `obstime` arithmetic is
  needed and the transform should succeed.

**Why it is exactly zero, and why the fix is safe (PO8 / PROOF.md §4):** `itrs_to_observed`
reads *only* `itrs_coo.cartesian`, `observed_frame.location` (geodetic `λ,φ`), and the
location's fixed ITRS cartesian — **none depend on `obstime`**. So `supcall` returns a
*bit-identical* result whether `obstime` is shifted or not, making the induced-velocity
finite difference `(fwd − back)/dt` **exactly `0.0`**. Declaring
`finite_difference_frameattr_name=None` (V2) drops that zero computation and keeps only
the re-orientation `M·V` — **observably identical wherever V1 did not crash**, and
correct (no crash) when `obstime=None`.

- input → observed/expected after fix: same moving satellite → `AltAz(location=loc)`
  now returns alt/az with the correctly re-oriented velocity, instead of `TypeError`.

This is the one finding **applied as a code change in V2** because it (a) fixes a real
crash on the motivating input, and (b) is *provably observationally neutral* on every
input where V1 worked (zero risk). Traced to PO8 and Finding 3.

## Finding 5 — geometry and round-trip are correct (positive)
**Classification:** positive. **Severity:** informational.

- AltAz anchors: zenith→alt 90°, North→az 0°, East→az 90° (PO5) — hand-derived and
  re-checked; matches `AltAz` docstring (Az East-of-North).
- HADec anchors: meridian-equator→(ha 0, dec 0), pole→dec 90°, East→negative ha (PO6)
  — matches `HADec` docstring ("hour angle negative to the East").
- Round-trips ITRS→obs→ITRS and obs→ITRS→obs are **exact** because `M` is orthogonal
  (PO1–PO4). No off-by-sign, no axis swap.

## Finding 6 — velocity is correctly re-oriented (positive)
**Classification:** positive. As above (PO8): output differential `= M·V`, exact,
because the position map is affine with constant `M`,`L`. Contrast the indirect path
`ITRS→CIRS→AltAz`, which routes a ground-stationary object's velocity through the
non-rotating CIRS frame (huge intermediate velocity, then cancellation). The direct
transform avoids that entirely.

---

## Spec-difficulty signal (benefit-2 meta-check)

Writing the spec was **easy**: a clean precondition (dimensional 3-D position +
non-None location), a clean closed-form postcondition (`M·(P−L)` / `Mᵀ·Q+L`), and an
exact round-trip. There was **no** forced case split, **no** missing closed form, and
**no** awkward side condition. Per the kit's "if a clean spec is hard, that's a bug
signal" rule, the *converse* holds here: the spec is clean ⇒ this is weak positive
evidence the code has no hidden corner-case bug **on its domain**. The only "rough
edges" are the out-of-domain inputs (Findings 1, 2, 4), all of which fail safe.

## Proof-derived findings (from `/verify`)

- **PD-1 (escalation boundary, not a code bug).** The orthogonality VCs (PO1/PO2) and
  the geometric-anchor VCs (PO5/PO6) are facts of **real (trigonometric) arithmetic**
  — `cos²θ + sin²θ = 1`, angle-subtraction identities, products of rotation matrices.
  The bundled K tier targets **integer/map/list** arithmetic, so these are **outside**
  what `kprove`'s Z3 path discharges automatically. They are marked
  `[ESCALATION BOUNDARY]` (route to a real-closed-field / linear-algebra theory), and
  discharged here **algebraically** (group-theoretic: a product of orthogonal matrices
  is orthogonal). This is a **proof-capability gap, NOT a code defect** — they are
  *not* faked as `[trusted]`. See `PROOF.md` §3.
- **PD-2 (no termination obligation).** No loops/recursion ⇒ the functions are
  straight-line and terminate trivially; partial = total correctness here. No variant
  needed.
