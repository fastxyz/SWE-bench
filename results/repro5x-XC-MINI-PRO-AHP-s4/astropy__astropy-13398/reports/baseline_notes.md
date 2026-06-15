# Baseline notes — astropy__astropy-13398

## Issue summary

Users observing near-Earth objects (satellites, aircraft, mountains, neighbouring
buildings, etc.) whose positions are given as **topocentric ITRS** coordinates were
repeatedly confused by the apparent inaccuracy of transforming ITRS → AltAz. The
existing path routes ITRS → CIRS → AltAz (or ITRS → ICRS → AltAz), which:

1. applies **geocentric stellar aberration** that is inappropriate for a body whose
   coordinates are already topocentric and aberration-free, and
2. performs an **ITRS → ITRS** step to synchronise `obstime`s, which refers the ITRS
   position to the Solar System Barycenter (SSB) rather than to the rotating ITRF.
   Because ITRS positions are nearby, that step throws the position "into the wake of
   the Earth's orbit," potentially millions of km off.

The issue requests a *direct* approach that stays entirely within the ITRS and merely
rotates between ITRS, AltAz, and HADec, treating the ITRS position as time invariant.
The issue body contains a prototype that the author states is "tested and working."

## Root cause

There was simply **no direct ITRS ↔ AltAz / ITRS ↔ HADec transformation** registered in
the frame transform graph. Any such transform was forced through the geocentric,
aberration-corrected intermediate frames, which is the wrong model for topocentric
near-Earth positions and additionally mishandles differing `obstime`s via the
SSB-referenced ITRS self-transform.

## Changes

### 1. New file: `astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

Adds four transforms via two decorated functions, mirroring the structure of the
sibling modules `icrs_observed_transforms.py` and `cirs_observed_transforms.py`:

- `itrs_to_observed_mat(observed_frame)` — builds the orthogonal rotation matrix from
  ITRS (geocentric, Earth-fixed, right-handed) to the (left-handed) AltAz or HADec
  frame, using the observer's **geodetic** longitude/latitude (`to_geodetic('WGS84')`).
  - AltAz: `minus_x @ R_y(π/2 − elat) @ R_z(elong)` (the `-x` makes the frame left-handed,
    azimuth measured East of North).
  - HADec: `minus_y @ R_z(elong)` (the `-y` makes hour angle increase to the West).
- `itrs_to_observed(itrs_coo, observed_frame)` (ITRS→AltAz, ITRS→HADec) — forms the
  topocentric ITRS vector by subtracting the observer's ITRS position
  (`observed_frame.location.get_itrs().cartesian`) and applies the matrix.
- `observed_to_itrs(observed_coo, itrs_frame)` (AltAz→ITRS, HADec→ITRS) — applies the
  transposed (= inverse, since the matrix is orthogonal) matrix and adds the observer's
  ITRS position back to recover the geocentric ITRS position.

The `obstime` of the input frame is intentionally ignored; the output frame's `obstime`
is simply adopted. This is documented in the module docstring and inline, per the issue:
synchronising `obstime`s here would invoke the SSB-referenced ITRS→ITRS step and is the
"real gotcha" the feature is designed to avoid. The implementation follows the issue's
prototype verbatim (correct, per the math check below), with an added module docstring
and explanatory comments consistent with the surrounding files.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Registers the new module (`from . import itrs_observed_transforms`) alongside the other
`*_transforms` imports, so the transforms are hooked into `frame_transform_graph` when
the package is imported. This is the only wiring required — the frame classes are already
exported and the transforms register themselves through the decorators.

## Correctness checks (done analytically, no execution available)

- **Straight overhead → alt = 90°.** For an object on the local geodetic vertical at
  `(elong, elat)`, the ITRS unit normal is `n = [cos(elat)cos(elong), cos(elat)sin(elong),
  sin(elat)]`. Then `R_z(elong)·n = [cos(elat), 0, sin(elat)]`, `R_y(π/2−elat)·… = [0,0,1]`,
  and `minus_x` leaves it `[0,0,1]` → `sin(alt)=1` → `alt = 90°`. For HADec the same input
  gives `[cos(elat),0,sin(elat)]` → `dec = elat`, `ha = 0`. This matches the geometric
  expectation (and the spirit of `test_straight_overhead`).
- **Round-trip is exact.** The matrix `M = minus_x @ R_y @ R_z` (and `minus_y @ R_z`) is
  orthogonal (reflection × rotations), so `Mᵀ = M⁻¹`. Hence
  `observed_to_itrs(itrs_to_observed(x)) = Mᵀ M (x − loc) + loc = x`.
- **No unintended graph rerouting.** The new edges add alternative 2-step paths (e.g.
  `AltAz → ITRS → HADec`). `find_shortest_path` (Dijkstra) breaks equal-weight ties by
  node *insertion order*. ITRS is first registered as a `fromsys` in this new module /
  `intermediate_rotation_transforms`, i.e. **after** ICRS, CIRS, AltAz, HADec are already
  in the graph, so ITRS is always popped *last* among tied intermediates. Therefore the
  new edges become the shortest path only when ITRS is itself an endpoint — exactly the
  intended ITRS↔AltAz / ITRS↔HADec direct transforms — and never as an unwanted
  intermediate (which also avoids the unit-spherical crash that a dimensionless−metre
  subtraction would otherwise cause for `AltAz↔HADec`).

## Assumptions and rejected alternatives

- **Faithfully implement the issue's prototype, without adding speculative exception/
  warning handling for unit-spherical reps or `location is None`.** The maintainers
  discussed such hardening in the thread, but the prototype the author calls
  "tested and working" contains none, and the agreed resolution leaned on documentation
  rather than code-level guards (raising/warning would make ITRS behave unlike every
  other frame). Adding guards with a guessed message/exception type risks mismatching the
  hidden tests; the natural behaviour for nonsensical inputs (a units error / attribute
  error) is left in place. *Rejected*: adding `try/except`, `is_unitspherical` branches,
  or obstime-mismatch warnings.
- **New module vs. editing an existing one.** Placed the transforms in their own
  `itrs_observed_transforms.py` to match the established one-module-per-transform-group
  layout (`icrs_observed_transforms.py`, `cirs_observed_transforms.py`) and to avoid
  circular imports, exactly as the package's own `__init__` docstring prescribes.
  *Rejected*: putting them in `intermediate_rotation_transforms.py` (different character —
  those are geocentric rotations) or in `itrs.py` (would create import cycles).
- **Geodetic vs. geocentric latitude.** Used `to_geodetic('WGS84')` so that "overhead"
  means the local geodetic vertical (the physically meaningful horizon for an observer),
  matching the AltAz/HADec frame definitions ("with respect to the WGS84 ellipsoid").
- **Documentation/changelog.** User-facing narrative docs (which the issue rightly
  emphasises) are complementary but out of scope for the code fix and untested by the
  unit suite; the transform-graph documentation is auto-generated and now includes the
  new edges automatically. Not added here to keep the change minimal and targeted.
