# FVK Spec: Direct ITRS Observed Transforms

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This audit covers the V1 patch for `astropy__astropy-13398`:

- `ITRS.location` and `ITRS.earth_location`
- direct `ITRS <-> ITRS` origin shifts
- direct `ITRS <-> AltAz/HADec` transforms, with and without refraction
- compatibility of public `EarthLocationAttribute` inputs that can transform to `ITRS`

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | problem statement | "A direct approach to ITRS to Observed transformations that stays within the ITRS." | Add direct ITRS to observed-frame behavior rather than forcing the CIRS/ICRS aberration route for nearby Earth-fixed positions. | Encoded by `itrs_observed_transforms.py`. |
| I2 | problem statement | "merely converts between ITRS, AltAz, and HADec coordinates" and "transforms between these frames (i.e. ITRS<->AltAz, ITRS<->HADec)" | Provide bidirectional direct transforms for both observed frame families. | Encoded by four graph decorators. |
| I3 | problem statement | "treats the ITRS position as time invariant" | Direct ITRS paths must preserve the Earth-fixed geocentric position and must not propagate through SSB/inertial time evolution. | Encoded by origin-shift formulas. |
| I4 | public comment | "ensure it gets used only when relevant ... coordinates better have a distance" | Unit-spherical/dimensionless data are suspicious because no finite topocentric displacement exists. | V1 preserves directions without origin shifts; documented as residual risk, not rejected. |
| I5 | public comment | "coords without distances ... assuming they are on the geoid with an appropriate warning" and later uncertainty about meaning | Missing distance semantics are not fully specified. | No new code change; record as residual ambiguity. |
| I6 | public comment | "if obstimes are present in both frames for now ... either raise an exception or a warning" | When source and target both carry an `obstime` and they differ, the direct Earth-fixed path must warn or raise rather than silently ignore the source time. | V1 violated this; V2 adds `AstropyWarning`. |
| I7 | public tests/comments | `test_straight_overhead` expects topocentric CIRS straight-overhead to map to `AltAz.alt == 90 deg`, `HADec.ha == 0`, `HADec.dec == observer latitude`. | Local observed-axis matrices must preserve the geometric topocentric vertical case. | Encoded by rotation/reflection matrices. |
| I8 | public API docs/names | `EarthLocationAttribute` accepts anything transformable to ITRS and returns an EarthLocation. | Adding `ITRS.location` must keep coordinate-valued location inputs convertible to geocentric EarthLocation. | Encoded by `earth_location = data + frame.location`. |

## Intent-Only Contract

1. A finite ITRS coordinate represents an Earth-fixed vector relative to an ITRS origin `L_src`, defaulting to Earth center.
2. The geocentric Earth-fixed vector represented by an ITRS coordinate is `P_geo = P_local + L_src`.
3. Transforming to another ITRS frame with origin `L_dst` must return `P_dst = P_geo - L_dst`; if the data are unit-spherical/dimensionless, no origin shift is defined and the direction is preserved.
4. Transforming finite ITRS to no-refraction AltAz/HADec at observer location `L_obs` must first form `P_topo = P_geo - L_obs`, then apply the location-specific observed-axis rotation matrix.
5. Transforming no-refraction AltAz/HADec to ITRS must apply the transpose of that same matrix, create an ITRS coordinate relative to `L_obs`, and then origin-shift to the requested ITRS frame.
6. Refraction-corrected ITRS/observed paths must require an `obstime`, form the same topocentric ITRS vector, and delegate the refraction correction to the existing CIRS/observed implementation.
7. If both source and target frames have non-`None` `obstime` values and they differ on a direct Earth-fixed ITRS path, the code must warn or raise before ignoring the source `obstime`.

## Formal Core Summary

The standalone formal snippets are in:

- `fvk/mini-itrs-transform.k`
- `fvk/itrs-transform-spec.k`

They model vectors, origins, a no-refraction observed rotation matrix, the transpose inverse, and the warning event for mismatched obstimes. They intentionally abstract away Astropy's full frame graph, units machinery, ERFA internals, and refraction numerics. Those are compatibility and escalation boundaries, not hidden evidence.

## Frame Conditions

- Existing geocentric ITRS remains the default because `location` defaults to `EARTH_CENTER`.
- `EarthLocation.get_itrs()` still creates geocentric ITRS data with no non-default `location`.
- Direct transforms must not modify test files.
- The warning does not change returned coordinate values; it only makes the ignored-obstime behavior explicit.

## Residual Ambiguities

- Unit-spherical or dimensionless Cartesian ITRS data do not have a finite origin shift. V2 preserves their direction and records that the public discussion did not settle whether to warn, error, or assume a geoid distance.
- The proof constructs partial correctness of the direct algebra. It does not prove numerical precision of ERFA matrices, termination, or the correctness of the existing CIRS refraction routines.
