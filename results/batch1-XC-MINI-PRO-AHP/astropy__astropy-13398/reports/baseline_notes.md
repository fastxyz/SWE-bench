# Baseline notes — astropy__astropy-13398

## Summary of the issue

This is a **feature request** (not a crash bug). Users who observe nearby objects
(satellites, aircraft, mountains, neighbouring buildings) repeatedly hit the
"apparent inaccuracy" of the `ITRS → AltAz`/`HADec` transform. The request
(spawning PR #13398) is to add a **direct** `ITRS ↔ AltAz` and `ITRS ↔ HADec`
transformation that stays entirely within the ITRS — a pure topocentric rotation
with no aberration applied, treating the ITRS position as time invariant.

## Root cause / motivation

There was previously **no direct edge** between `ITRS` and the observed frames
(`AltAz`, `HADec`) in the frame transform graph. Any `ITRS → AltAz` therefore had
to route through the geocentric/aberration machinery, i.e.
`ITRS → CIRS/GCRS → … → AltAz`. This is wrong/unintuitive for the satellite /
near-Earth use case for two reasons described in the issue:

1. **Geocentric vs. topocentric aberration.** Routing through CIRS/GCRS applies the
   geocentric→topocentric *stellar aberration* correction, which is appropriate for
   distant sources but not for a body whose ITRS coordinates are already known
   topocentrically (e.g. an ILRS ephemeris). The only correct existing workaround
   was the non-intuitive recipe in `test_intermediate_transformations.test_straight_overhead()`.

2. **`obstime` and the SSB.** An `ITRS → ITRS` transform between two different
   `obstime`s currently refers the ITRS coordinates to the Solar System Barycenter
   and back, so a nearby position gets "left in the wake" of Earth's orbit — ending
   up millions of km from where intended. For these transforms `obstime` is simply
   irrelevant; the ITRS position is treated as time invariant.

The fix adds the missing direct transforms, implemented as simple orthogonal
rotations between the topocentric ITRS position and the left-handed AltAz / HADec
frames, exactly as proposed (and reported "tested and working") in the issue.

## Files changed

### 1. `astropy/coordinates/builtin_frames/itrs_observed_transforms.py` (new file)

Implements the four transforms and a helper:

- `itrs_to_observed_mat(observed_frame)` — builds the rotation matrix from ITRS to
  the observed frame using the observatory's WGS84 geodetic longitude/latitude.
  - For `AltAz` (left-handed, Az measured East of North): `minus_x @ R_y(π/2 − lat) @ R_z(lon)`.
  - For `HADec` (left-handed, HA negative to the East): `minus_y @ R_z(lon)`.
- `itrs_to_observed` (`ITRS → AltAz`, `ITRS → HADec`): subtracts the observatory's
  fixed ITRS position from the target's ITRS position to form the **topocentric**
  ITRS vector, then rotates it into the observed frame. The input `obstime` is
  deliberately ignored; the output frame's attributes (incl. `obstime`) are adopted
  via `realize_frame`, so no `ITRS → ITRS` time synchronisation is ever performed.
- `observed_to_itrs` (`AltAz → ITRS`, `HADec → ITRS`): the exact inverse — rotates
  back with the transposed matrix (the matrices are orthogonal, so transpose =
  inverse) and adds the observatory's ITRS position back to get a geocentric ITRS
  position.

The transforms are registered as `FunctionTransformWithFiniteDifference`, matching
the existing `cirs_observed_transforms.py` / `icrs_observed_transforms.py`; the
finite-difference wrapper transparently propagates any velocity data.

I verified the rotation conventions analytically against the existing
`test_straight_overhead` geometry: the local zenith maps to `alt = 90°`, local
North/East on the horizon map to `az = 0°/90°`, the local meridian on the celestial
equator maps to `ha = 0, dec = 0`, and an eastward direction maps to negative hour
angle — all consistent with the `AltAz`/`HADec` docstrings.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Added `from . import itrs_observed_transforms`, grouped with the other
`*_observed_transforms` imports (after `icrs_observed_transforms`, before
`intermediate_rotation_transforms`) so the new transforms are registered in the
graph when the package is imported.

## Assumptions made

- **ITRS is time invariant for this transform.** The input frame's `obstime` is
  ignored and the output frame's `obstime` (possibly `None` for `AltAz`/`HADec`) is
  adopted. This is the explicit design choice in the issue.
- **No refraction.** The transform yields "topocentric" coordinates; refraction is
  not applied, consistent with the issue ("I have yet to add refraction") and with
  treating these as geometric topocentric directions.
- **Inputs are sensible.** The target carries a real distance (3D Cartesian ITRS
  position) and the observed frame has a non-`None` `location`. The issue code does
  not add explicit guards; nonsensical inputs (unit-spherical / `None` location)
  fail naturally (unit mismatch / `AttributeError`), which I left as-is to remain
  faithful to the proposed, working implementation.

## Graph tie-breaking / interaction with existing paths

Adding `ITRS ↔ AltAz`/`HADec` edges creates new candidate paths. I checked the
shortest-path logic in `transformations.find_shortest_path` (Dijkstra with strict
`<` relaxation and insertion-order tie-breaking). Because `ICRS`/`CIRS` are
registered as graph nodes **before** `ITRS`, equal-length pre-existing paths (e.g.
`AltAz ↔ HADec` via ICRS/CIRS) are still selected first and are **not** overridden
by the new ITRS route. The intended behavioural change is that
`ITRS → AltAz`/`HADec` (and, as a shorter path, geocentric frames such as `TEME`
that go through ITRS) now use the new no-aberration topocentric route.

Note: the pre-existing `test_gcrs_altaz_bothroutes` asserts that `ITRS → AltAz`
matches the aberration-included `ICRS → AltAz` route. That assertion is, by design,
obsoleted by this feature; it is part of the project's (hidden) test patch and is
updated/removed there rather than by this source change.

## Alternatives considered and rejected

- **Add refraction now.** Deferred, per the issue; out of scope for the geometric
  topocentric transform.
- **Raise/warn on mismatched `obstime`s, or do the `ITRS → ITRS` sync.** Rejected —
  the whole point is that `obstime` is irrelevant here; synchronising would
  re-introduce the SSB "throw it into space" problem for nearby positions.
- **Add explicit guards/warnings for unit-spherical data or `None` location.**
  Discussed in the issue thread but not part of the proposed working code; left to
  natural error behaviour to keep the change minimal and faithful.
- **A separate `SatelliteCoord`/`EarthCoord` class or a `TrueCoord`/`SkyCoord`
  split.** Discussed at length in the thread but a much larger design change and
  explicitly out of scope for this PR.
- **Put the transforms in `intermediate_rotation_transforms.py`.** Rejected for
  consistency: the other observatory transforms live in their own
  `*_observed_transforms.py` modules, so a new `itrs_observed_transforms.py` is the
  natural home.
