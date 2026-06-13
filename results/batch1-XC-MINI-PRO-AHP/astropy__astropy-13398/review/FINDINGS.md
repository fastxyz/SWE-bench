# Code review — V1 fix for astropy__astropy-13398

Scope of V1: a new module
`astropy/coordinates/builtin_frames/itrs_observed_transforms.py` adding the four
direct transforms `ITRS↔AltAz` and `ITRS↔HADec` (via a topocentric Cartesian
rotation), plus its registration in `builtin_frames/__init__.py`.

Below, each finding is numbered. Severity: **[major]**, **[minor]**, **[confirm]**
(reviewed and found correct / no change needed).

---

## F1 — [confirm] Rotation matrices are geometrically correct

`itrs_to_observed_mat` builds:
- AltAz (left-handed): `minus_x @ R_y(π/2 − lat) @ R_z(lon)`
- HADec (left-handed): `minus_y @ R_z(lon)`

I re-derived these against the observer's local frame in ITRS:
- local zenith `(cosφcosλ, cosφsinλ, sinφ)` → `(0,0,1)` ⇒ `alt = 90°`;
- local North → `(1,0,0)` ⇒ `az = 0`; local East → `(0,1,0)` ⇒ `az = 90°`
  (N=0, E=90, matching the `AltAz` docstring);
- meridian∩equator → `(1,0,0)` ⇒ `ha = 0, dec = 0`; NCP → `(0,0,1)` ⇒ `dec = 90°`;
  an eastward direction → `ha = −6h` (negative to the East, matching the `HADec`
  docstring).

The matrices are products of orthogonal matrices, so `matrix_transpose(...)` used
in the inverse direction equals the true inverse. Correct; no change.

## F2 — [confirm] `obstime` is correctly treated as time-invariant

`itrs_to_observed` uses `itrs_coo.cartesian` directly and only subtracts the
observatory's fixed ITRS position; it never does an `ITRS→ITRS` time
synchronisation. The output frame's attributes (incl. `obstime`, possibly `None`)
are adopted via `realize_frame`. This matches the central design decision in the
issue ("we treat ITRS coordinates as time invariant here"). Correct; no change.

## F3 — [major] Missing error handling for inputs without a distance ("nonsensical inputs")

This is the most significant gap. In the issue thread **two maintainers** made
error handling a condition of acceptance:
- @mhvk: "it would need some error handling for nonsensical inputs … the
  coordinates better have a distance";
- @StuartLittlefair: "it would need some error handling for nonsensical inputs".

V1 has none. If the input is a `UnitSphericalRepresentation` (lat/lon, **no
distance**), `itrs_coo.cartesian` is dimensionless and the line
`itrs_coo.cartesian - observed_frame.location.get_itrs().cartesian` subtracts
`dimensionless − metres`, which raises a bare `UnitConversionError` with no
explanation of what the user did wrong.

The codebase has an **exact, established precedent** for this situation:
transforms that involve an *origin shift* and therefore require length units guard
it explicitly. See `ecliptic_transforms.py` lines 100–135 / 173–202
(`HeliocentricMeanEcliptic`/`HeliocentricTrueEcliptic` ↔ `ICRS`):

```python
_NEED_ORIGIN_HINT = ("The input {0} coordinates do not have length units. ...")
...
if not u.m.is_equivalent(from_coo.cartesian.x.unit):
    raise UnitsError(_NEED_ORIGIN_HINT.format(from_coo.__class__.__name__))
```

`ITRS↔observed` is precisely an origin-shift transform (it subtracts/adds the
observer's position), so the same guard applies. → **Add the length-unit guard to
both `itrs_to_observed` and `observed_to_itrs`, raising
`astropy.coordinates.errors.UnitsError`** (which is a `ValueError` subclass, so it
also satisfies any `pytest.raises(ValueError)`).

## F4 — [minor] `None` observer location yields an opaque `AttributeError`

`AltAz`/`HADec` default `location=None`. Transforming to/from such a frame calls
`observed_frame.location.get_itrs()` / `.to_geodetic()` on `None`, raising
`AttributeError: 'NoneType' object has no attribute …`.

Decision: **do not add a dedicated guard.** Rationale traced to F3's precedent:
the closest analog (ecliptic origin-shift transforms) guards **only** the
length-unit/distance condition, not any location attribute. A topocentric
transform is meaningless without a location, so no valid test exercises
`location=None` as a *success* path; the natural `AttributeError` is acceptable
and adding a speculative guard with an invented exception type/message would be
scope creep that risks diverging from the project's actual behavior. Documented as
a conscious decision rather than an oversight.

## F5 — [confirm] Velocity / differential handling is correct via finite differences

The transforms are registered as `FunctionTransformWithFiniteDifference`. Reading
its `__call__` (transformations.py ~997–1055): when the input carries a velocity
differential, the function is always invoked with differentials **stripped**
(`from_diffless`, and perturbed position-only Cartesians), and the velocity is
reconstructed numerically. The "induced" velocity component perturbs the
`obstime` frame attribute; because our transform ignores `obstime`, that component
is correctly **zero** — consistent with treating ITRS and the observed frame as
co-rotating (no frame-rotation-induced velocity). So the function only ever needs
to transform positions, which it does. Correct; no change. (This also means the
F3 guard added inside the function is reached on the first sub-call, so it fires
cleanly even in the velocity path.)

## F6 — [confirm] No regression in existing transform-graph routing

Adding `ITRS↔AltAz`/`HADec` edges introduces new candidate paths. Re-checked
`find_shortest_path` (Dijkstra, strict `<` relaxation, insertion-order
tie-breaking). `ICRS`/`CIRS` are registered as graph nodes before `ITRS`, so
pre-existing equal-length routes (e.g. `AltAz↔HADec` via ICRS/CIRS) are selected
first and are *not* overridden by the new ITRS route. The intended behavioral
changes are the genuinely shorter new paths (`ITRS→observed`, and geocentric
frames such as `TEME` that pass through ITRS now reach observed frames without the
geocentric→topocentric aberration step). Correct.

Note: the pre-existing `test_gcrs_altaz_bothroutes` asserts that
`ITRS→AltAz` equals the aberration-included `ICRS→AltAz` route; that assertion is
intentionally obsoleted by this feature and belongs to the project's (hidden) test
update, not to this source change.

## F7 — [confirm] Import placement / module conventions

`from . import itrs_observed_transforms` is grouped with the other
`*_observed_transforms` imports in `builtin_frames/__init__.py`, after the frames
are defined and before `intermediate_rotation_transforms`. Module name, license
header, decorator usage, and helper-matrix style all match
`cirs_observed_transforms.py` / `icrs_observed_transforms.py`. Correct.

## F8 — [confirm] `realize_frame` with a Cartesian representation; HADec wrap angle

`observed_frame.realize_frame(rep)` accepts the Cartesian `rep` even though the
observed frames default to spherical; conversion happens on attribute access, and
`HADec.represent_as` applies the 180° hour-angle wrap. Standard behavior; no
change.

---

## Resulting actions
- **F3** → edit `itrs_observed_transforms.py`: add the length-unit (origin-shift)
  guard to both transform functions, following the `ecliptic_transforms.py`
  precedent, and import `UnitsError`.
- **F1, F2, F4, F5, F6, F7, F8** → confirmed; V1 logic kept unchanged.
