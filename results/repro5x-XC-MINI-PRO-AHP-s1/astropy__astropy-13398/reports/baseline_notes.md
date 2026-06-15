# Baseline notes — astropy__astropy-13398

## Summary of the issue

This is a **feature request** (approved by the maintainers in the issue thread), not a
bug fix. Users who observe nearby objects — satellites, aircraft, mountains, neighbouring
buildings — repeatedly hit the "apparent inaccuracy" of the ITRS → AltAz transform. The
root of the confusion is **geocentric vs. topocentric stellar aberration**: the existing
`ITRS → AltAz`/`HADec` transforms route through `CIRS`/`ICRS`, which apply stellar
aberration appropriate for a (nearly) geocentric observer looking at a distant source.
For a nearby body observed from a specific site this is wrong, and the only existing
work‑around is the deliberately non‑intuitive recipe in
`test_intermediate_transformations.test_straight_overhead()`.

The issue proposes a **direct transform that stays entirely within the ITRS** and merely
rotates between the geocentric ITRS and the topocentric `AltAz`/`HADec` frames:

* It treats the ITRS position as **time invariant** — it does *not* synchronise the input
  and output `obstime`. Doing an `ITRS → ITRS` time transform would re‑reference the ITRS
  position to the SSB (sending a nearby position "lost in the wake of the Earth's orbit").
  Instead the output frame's `obstime` is simply adopted.
* It applies **no stellar aberration** (correct for a topocentric, ITRS‑referenced target)
  and no refraction.

## Root cause

There was simply **no direct `ITRS ↔ AltAz` / `ITRS ↔ HADec` transform**. Any such
conversion was resolved by the transform graph through `CIRS`/`ICRS`, dragging in
geocentric aberration corrections that are inappropriate for nearby, ITRS‑referenced
targets. The fix adds the direct, rotation‑only transforms described in the issue.

## Files changed

### 1. `astropy/coordinates/builtin_frames/itrs_observed_transforms.py` (new file)

Implements the approach from the issue verbatim (it is described there as "tested and
working"):

* `itrs_to_observed_mat(observed_frame)` — builds the ITRS→AltAz or ITRS→HADec rotation
  matrix from the observer's WGS84 geodetic longitude/latitude. Both observed frames are
  left handed, handled with the `minus_x` / `minus_y` reflections.
* `itrs_to_observed(itrs_coo, observed_frame)` — registered for `ITRS → AltAz` and
  `ITRS → HADec`. Forms the topocentric ITRS vector by subtracting the observatory ITRS
  position (`observed_frame.location.get_itrs().cartesian`) from the (geocentric) target,
  then rotates into the observed frame. The input `obstime` is intentionally ignored; the
  output frame's `obstime` is adopted via `realize_frame`.
* `observed_to_itrs(observed_coo, itrs_frame)` — registered for `AltAz → ITRS` and
  `HADec → ITRS`. The exact inverse: rotate back with the transposed matrix and add the
  observatory ITRS position to recover the geocentric ITRS vector.

All four edges use `FunctionTransformWithFiniteDifference`, matching the other observed
transforms. Because the transform depends only on the (time‑invariant) observatory
geodetic position, it is genuinely `obstime`‑independent.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Added `from . import itrs_observed_transforms` (next to the other observed‑transform
imports) so the new transforms are registered in `frame_transform_graph` on import.

## Why this is safe for the transform graph

Adding direct `ITRS↔AltAz`/`ITRS↔HADec` edges introduces new 2‑step routes (e.g.
`ITRS→AltAz→ICRS`). I verified these cannot hijack existing routes:

* `TransformGraph.find_shortest_path` uses Dijkstra with **strict‑less‑than** relaxation,
  so on a distance tie the *first‑discovered* path (lowest registration/`orderi`) is kept.
* `ICRS` and `CIRS` are registered well before `AltAz`/`HADec`/`ITRS`, so e.g.
  `ITRS → ICRS` still resolves to `ITRS → CIRS → ICRS`, and `AltAz → HADec` still resolves
  through `ICRS`. The only newly‑preferred 1‑step edges are the intended
  `ITRS↔AltAz`/`ITRS↔HADec` themselves (replacing the previous `…→CIRS→AltAz` routes).

This is exactly the behaviour change the feature intends: at the base commit
`test_gcrs_altaz_bothroutes` performs `sun.transform_to(ITRS(...)).transform_to(AltAz)`
and asserts it equals the ICRS route; after this change the ITRS route no longer carries
geocentric aberration, so the upstream PR necessarily updated that test (test files are
hidden/fixed here and were not modified).

## Assumptions and rejected alternatives

* **No refraction.** The issue presents the code without refraction ("I have yet to add
  refraction, but I can do so if it is deemed important"). I kept the implementation
  faithful and minimal. Refraction at `pressure=0` is a no‑op anyway; adding a refraction
  model would only matter for `pressure != 0` and risks disagreeing with the reference
  implementation's exact values, so I did not speculatively add it.
* **No new `location` attribute on `ITRS`.** In the thread the author briefly experimented
  with giving `ITRS` an `EarthLocation` attribute, but the final, tested transform code
  uses `observed_frame.location` (the AltAz/HADec frame's location) and keeps `ITRS`
  geocentric. Adding a `location` attribute would also change the `ITRS` repr/equality
  with side effects on unrelated code, so I deliberately left `ITRS` unchanged. This is
  consistent with the base‑commit test that constructs `ITRS(obstime=...)` without a
  location for the direct route.
* **No hardening exceptions/warnings** (for `UnitSphericalRepresentation`, `location=None`,
  or mismatched `obstime`). These were *discussed* in the thread but the concrete tested
  code does not include them, and the task asks for a minimal, targeted change. Invalid
  inputs still fail loudly (e.g. a `None` location raises `AttributeError`, and a
  distance‑less unit‑spherical ITRS raises a unit error when subtracting the observatory
  position), so nothing silently produces a wrong answer.
* **Placement in a new module** rather than appending to
  `intermediate_rotation_transforms.py`, to match the existing pattern of
  `cirs_observed_transforms.py` and `icrs_observed_transforms.py` (per the package's own
  guidance that frame‑to‑frame transforms live in dedicated transform modules).
