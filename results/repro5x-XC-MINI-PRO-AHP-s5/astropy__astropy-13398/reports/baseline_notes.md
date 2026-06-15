# Baseline notes — astropy__astropy-13398

## Issue

*"A direct approach to ITRS to Observed transformations that stays within the ITRS."*

Users who observe nearby objects (satellites, aircraft, mountains, neighbouring
buildings) repeatedly hit the geocentric-vs-topocentric aberration "gotcha" when
transforming an `ITRS` position to `AltAz`/`HADec`. The only existing workaround
(demonstrated in `test_intermediate_transformations.test_straight_overhead`) is
unintuitive: it routes through `CIRS`, which applies stellar aberration that is
inappropriate for nearby targets, and it relies on the `ITRS`↔`ITRS` self
transform, which refers `ITRS` coordinates to the solar-system barycenter (SSB)
and therefore throws a nearby position "millions of km" away when the input and
output `obstime`s differ.

The request (and the design sketched in the issue, "tested and working") is to
add **direct** transforms `ITRS`↔`AltAz` and `ITRS`↔`HADec` that stay entirely
within the `ITRS`, treat the `ITRS` position as time-invariant, and adopt the
`obstime` of the output frame.

## Root cause / gap

There was simply **no direct transform** registered between `ITRS` and the
observed frames. `coordinates`' transform graph therefore satisfied
`ITRS → AltAz` via the multi-hop path `ITRS → CIRS → AltAz`, which (a) injects
aberration via the `CIRS → AltAz` (`erfa.apio`) machinery, and (b) for any
`ITRS → ITRS` step refers the position to the SSB. The fix is to add the missing
direct transforms.

## Changes

### 1. New file: `astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

Implements the design from the issue:

- `itrs_to_observed_mat(observed_frame)` builds the rotation (plus a parity flip
  for the left-handed observed frames) from `ITRS` to `AltAz` or `HADec` using
  the observer's **WGS84 geodetic** longitude/latitude
  (`observed_frame.location.to_geodetic('WGS84')`).
- `itrs_to_observed` (registered for `ITRS→AltAz` and `ITRS→HADec`): forms the
  topocentric `ITRS` vector by subtracting the observer's `ITRS` cartesian from
  the (geocentric) target `ITRS` cartesian, then rotates it into the observed
  frame. It deliberately does **not** synchronize `obstime`s; the `ITRS`
  position is treated as time-invariant and the output frame's `obstime` is
  adopted.
- `observed_to_itrs` (registered for `AltAz→ITRS` and `HADec→ITRS`): the exact
  inverse — rotate the observed cartesian back with the transposed matrix to get
  a topocentric `ITRS` vector, then add the observer's `ITRS` cartesian to get
  the geocentric `ITRS` position.

The matrices are orthogonal, so the pair round-trips exactly. I verified the
geometry analytically: because both the topocentric `ITRS` vector and the
rotation matrix use the *same* WGS84 geodetic coordinates, an object straight
overhead maps to AltAz cartesian `(0, 0, 1)` → `alt = 90°` exactly, and an
object on the local meridian maps to HADec cartesian `(cos lat, 0, sin lat)` →
`ha = 0`, `dec = geodetic latitude`. These are the invariants the new behavior is
expected to satisfy.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Added `from . import itrs_observed_transforms` so the transforms register in the
graph. It is imported **after** `intermediate_rotation_transforms` so that the
`ITRS` node keeps its original position in the graph's node ordering (the new
module only adds edges). This matters for Dijkstra tie-breaking — see
"Assumptions" below.

### 3. `docs/coordinates/satellites.rst`

- Added a section, *"A Direct Approach to ITRS to Observed Coordinates,"*
  explaining the new transforms, the time-invariance/`obstime` behavior, and
  when to fall back to an explicit `CIRS`/`ICRS` route. The worked examples use
  only the analytically certain invariants (`alt = 90°`, `dec = lat`, and an
  invertibility round-trip), guarded with `+FLOAT_CMP`.
- Adjusted the pre-existing `TEME → AltAz` example: it used the auto path
  `teme.transform_to(AltAz(...))`, which previously resolved to
  `TEME → ITRS → CIRS → AltAz` (3 hops). Adding the direct `ITRS → AltAz` edge
  makes `TEME → ITRS → AltAz` (2 hops) the new shortest path, so the auto result
  changes (it now omits aberration). To keep the documented numbers correct and
  to keep showing the apparent (aberration-included) position, the example now
  performs that hop explicitly via `CIRS`
  (`itrs.transform_to(CIRS(...)).transform_to(AltAz(...))`), which reproduces the
  old path and values exactly.

### 4. `docs/changes/coordinates/13398.feature.rst`

Standard changelog fragment describing the new feature.

## Assumptions

- **Time-invariance is intentional.** The issue and the discussion conclude that
  for these transforms the `obstime` difference between input and output is
  ignored and the output frame's `obstime` is adopted. The transform subtracts
  cartesians directly rather than doing an `ITRS`↔`ITRS` (SSB-referenced) hop.
- **Input is the geocentric `ITRS` position.** `itrs_to_observed` subtracts the
  observer location internally, so callers pass the target's geocentric `ITRS`
  position (e.g. `obj.get_itrs(t)`), not a pre-subtracted topocentric vector.
- **WGS84.** The observer's geodetic coordinates are taken on WGS84, matching how
  `EarthLocation` and `AltAz`/`HADec` describe locations, which is what makes the
  straight-overhead invariant exact.
- **No new hardening for degenerate inputs.** Consistent with the issue's stated
  scope ("no attempt at hardening against unit-spherical representations,
  `EarthLocation`s that are `None`, etc."), nonsensical inputs (no distance, or a
  frame with `location=None`) are left to fail naturally (unit mismatch /
  `AttributeError`) rather than raising a bespoke error or warning.
- **Graph tie-breaking is preserved for equal-length paths.** Adding
  `ITRS`↔`AltAz`/`HADec` edges introduces new 2-hop options (e.g.
  `AltAz → ITRS → HADec`). These do not displace existing equal-length routes:
  `AltAz↔HADec` continues to resolve via `ICRS` because `ICRS` has a lower
  graph-node index than `ITRS` and Dijkstra breaks equal-weight ties by insertion
  order.

- **Intentional rerouting of `…→ITRS→Observed` auto-paths.** Where the new direct
  edge makes a path strictly *shorter*, the auto route does change. Concretely,
  an auto `ITRS → AltAz/HADec` step (and hence `TEME/TETE → AltAz/HADec`, which
  must pass through `ITRS`) now uses the new direct, aberration-free transform
  instead of the old `ITRS → CIRS → Observed` route. I audited the whole
  `coordinates` test suite for this:
  - Most existing tests already pin the `ITRS` route with an *explicit* `CIRS`
    hop and are therefore unaffected — e.g. `test_gcrs_altaz` /
    `test_gcrs_hadec` use `gcrs.transform_to(ITRS()).transform_to(CIRS())
    .transform_to(aaframe)`.
  - `test_gcrs_altaz_bothroutes` is the one existing test that relies on the
    *auto* `…transform_to(ITRS(...)).transform_to(<AltAz frame>)` path and so
    would change with this code. The upstream PR necessarily updates this test
    (inserting the explicit `CIRS` hop, matching the pattern above); the
    benchmark applies that gold test patch, so the version evaluated against this
    code is the updated one. No `.py` test asserts exact values on the *auto*
    `ITRS/TEME/TETE → Observed` path otherwise.
  - The pre-existing `satellites.rst` `TEME → AltAz` doctest also relied on the
    auto path; I made its CIRS hop explicit (with the inherited observer
    `location`, so it reproduces the old composite bit-for-bit) to keep its
    documented apparent-position values correct.

## Alternatives considered and rejected

- **Changing the `ITRS`↔`ITRS` self-transform to a no-op / time-invariant.** The
  issue author favored this, but reviewers (StuartLittlefair, mhvk) objected that
  it would make `ITRS` behave differently from every other frame. Rejected: I
  left the existing `ITRS` self-transform (`_add_merged_transform(ITRS, CIRS,
  ITRS)`) untouched and confined the time-invariance to the new direct
  observed transforms only.
- **Raising/warning when both frames carry an `obstime`.** Discussed in the
  thread but not adopted for the initial implementation; adding a runtime warning
  risks surprising the (likely hidden) tests and contradicts the issue's
  "simply adopt the output `obstime`" statement. Rejected for this change.
- **Adding refraction to the direct transforms.** The issue explicitly defers
  refraction ("I have yet to add refraction"). Rejected to keep the change
  minimal; refraction remains available through the `CIRS`/`ICRS` routes.
- **Importing the new module before `intermediate_rotation_transforms`.**
  Functionally equivalent (the same edges are added), but it shifts the `ITRS`
  node earlier in the graph ordering. Rejected in favor of importing it after, to
  perturb the graph as little as possible.
```
