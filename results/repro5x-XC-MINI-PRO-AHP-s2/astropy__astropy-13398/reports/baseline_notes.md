# Baseline notes — astropy__astropy-13398

## Issue summary

The issue (a feature request stemming from recurring user confusion, e.g. #13319)
asks for a *direct* set of transformations between `ITRS` and the "observed"
frames `AltAz` and `HADec` that **stay entirely within the ITRS**.

The existing way to get from an `ITRS` position of a nearby object (a satellite,
an airplane, a mountain, a neighbouring building, …) to `AltAz`/`HADec` routes
through the geocentric astrometric machinery (`ITRS -> CIRS -> AltAz`, or via
`ICRS`). That path applies stellar aberration and treats the coordinate as a
distant source observed from a moving Earth, which is the wrong model for an
object that is physically near the observer and whose position is already
expressed in the Earth-fixed ITRS. The result is an apparent inaccuracy of order
the aberration angle (~20 arcsec) for such targets, and the only existing
workaround is the unintuitive recipe in
`test_intermediate_transformations.test_straight_overhead()`.

The requested solution converts an ITRS position to a *topocentric* ITRS vector
(by subtracting the observing site's ITRS position) and then applies a pure
rotation into the local horizon (`AltAz`) or hour-angle/declination (`HADec`)
frame. No aberration, light deflection, or SSB referral is involved, which is
exactly what is wanted for nearby, Earth-fixed targets.

## Root cause

There simply was no direct `ITRS <-> AltAz` / `ITRS <-> HADec` transform. Any
such transform fell back to the multi-hop astrometric path, which:

1. Refers the ITRS coordinate to the Solar System Barycentre when changing
   `obstime` (an `ITRS -> ITRS` step), throwing a nearby object "into space"; and
2. Applies geocentric aberration corrections that are inappropriate for a target
   that is co-located with / near the observer.

## Changes made

### 1. New file: `astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

Implements the approach proposed in the issue:

- `itrs_to_observed_mat(observed_frame)` — builds the orthogonal rotation matrix
  from ITRS to the observed frame using the site's WGS84 geodetic longitude
  (and latitude for `AltAz`). For `AltAz` the matrix is
  `minus_x @ R_y(90° − lat) @ R_z(lon)` (left-handed, x→North, y→East, z→Up);
  for `HADec` it is `minus_y @ R_z(lon)` (left-handed, x→meridian/equator,
  y→West, z→pole). The `minus_x`/`minus_y` reflections encode the left-handed
  azimuth/hour-angle conventions.
- `itrs_to_observed(itrs_coo, observed_frame)` — registered for `ITRS -> AltAz`
  and `ITRS -> HADec`. It forms the topocentric ITRS vector
  `itrs_coo.cartesian - observed_frame.location.get_itrs().cartesian` and rotates
  it with the matrix above. The `obstime` is **not** synchronised between input
  and output: the ITRS coordinate is treated as time-invariant and the output
  frame's attributes are simply adopted, because an `ITRS -> ITRS` retiming would
  (wrongly) refer the position to the SSB.
- `observed_to_itrs(observed_coo, itrs_frame)` — registered for `AltAz -> ITRS`
  and `HADec -> ITRS`. Inverse of the above: rotate by the transposed matrix to
  get the topocentric ITRS vector, then add the site's ITRS position to get back
  the geocentric ITRS vector.

Because every matrix is orthogonal, the forward/inverse pair round-trips exactly.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Added `from . import itrs_observed_transforms` alongside the other transform
module imports so the new transforms are registered in the
`frame_transform_graph` when the package is imported. This is required — the
transform functions only take effect as a side effect of importing the module.

No other source files needed changing.

## Effect on the transform graph

The new direct edges are single-hop, so `ITRS.transform_to(AltAz/HADec)` (and the
reverse) now prefer them over the previous two-hop `ITRS -> CIRS -> AltAz` path.
This is the intended behaviour change: the default `ITRS <-> AltAz`/`HADec`
transform becomes the geometric, topocentric one without aberration.

I checked the rest of the source for direct `ITRS <-> AltAz/HADec` usage and
found none outside the test suite. Within the tests, the only direct
`ITRS().transform_to(<AltAz/HADec frame>)` calls are in
`test_gcrs_altaz_bothroutes` (it asserts the ITRS route equals the
aberration-bearing ICRS route). That assertion can no longer hold once the direct
transform deliberately drops aberration, so the upstream fix necessarily updated
that test; per the task constraints I did not modify any test file. All other
ITRS↔observed test paths route explicitly through `CIRS`
(`...transform_to(ITRS()).transform_to(CIRS()).transform_to(<frame>)`) and are
unaffected, as is `test_straight_overhead` (which uses the explicit CIRS recipe).

## Assumptions and rejected alternatives

- **Verbatim adoption of the issue's reference implementation.** The issue
  contains "the makings of a pull request" that is described as "tested and
  working," and the maintainers expressed support for the approach. I implemented
  it as given (minus the unused `erfa` import) rather than redesigning it.

- **Error handling for "nonsensical" inputs (unit-spherical data, `location` of
  `None`, mismatched `obstime`s).** Several maintainers raised this in the
  discussion, but the issue author explicitly deferred hardening ("so far I've
  made no attempt at hardening this") and the agreed resolution was to keep the
  transform itself simple and document the caveats (the `obstime` is intentionally
  ignored; targets are assumed to have a real distance). I therefore did **not**
  add warnings/exceptions inside the transforms, to keep the change minimal and to
  match the proposed/merged behaviour. A `UnitSphericalRepresentation` ITRS input
  will naturally raise a unit-conversion error when the dimensionless vector is
  differenced against the site's metre-valued ITRS position, which is acceptable
  given there is currently no meaningful topocentric interpretation of a
  distance-less ITRS coordinate.

- **Treating ITRS as time-invariant vs. synchronising obstimes.** I followed the
  issue's reasoning and adopt the output frame's `obstime` without performing an
  `ITRS -> ITRS` retiming, because that retiming refers the (near-Earth) position
  to the SSB and is the very source of the reported inaccuracy. Raising on
  mismatched obstimes was considered (and floated in the thread) but rejected to
  match the simpler accepted design; the behaviour is documented in the module.

- **Adding explicit loopback transforms.** Not needed: `ITRS <-> ITRS` already
  exists (merged via CIRS) and `AltAz <-> AltAz` / `HADec <-> HADec` already exist
  (merged via ICRS), so the graph can already round-trip without new loopback
  registrations.
