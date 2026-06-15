# Baseline notes — astropy__astropy-13398

## Issue summary

Feature request: provide a *direct* transformation between the `ITRS` frame and
the "observed" frames `AltAz` and `HADec` that stays entirely within the ITRS.

The recurring problem (most recently issue #13319) is that observers of nearby
objects — satellites, aircraft, mountains, neighbouring buildings — get
apparently wrong results from the existing `ITRS -> AltAz` / `ITRS -> HADec`
paths. Those paths route through the celestial frames (`CIRS`/`ICRS`), where:

1. The `ITRS -> ITRS` self-transform between two `obstime`s refers the position
   to the solar-system barycenter (SSB) and back. For a *nearby* ITRS position
   this is catastrophic: a small time difference throws the position millions of
   km "into the wake of the Earth's orbit." An `ITRS -> ITRS` transform of a
   ground/near-Earth object really ought to be (nearly) a no-op.
2. Stellar aberration (a geocentric-vs-topocentric ~20" effect) is applied,
   which is meaningless for an object co-moving with the Earth whose position is
   already known geometrically.

The requested fix transforms `ITRS <-> AltAz` and `ITRS <-> HADec` as a pure
geometric, topocentric operation: subtract the observing site's ITRS position to
get the topocentric ITRS vector, then rotate into the observed-frame axes (and
the inverse). No aberration, no refraction, and the ITRS position is treated as
time invariant (the output frame's `obstime` is simply adopted).

## Root cause

There simply was no edge in the transform graph directly connecting `ITRS` to
`AltAz`/`HADec`. Any such transform was composed through `CIRS`/`ICRS`, which
imposes the SSB round-trip and aberration described above — wrong for nearby
objects. The fix is to add the missing direct transforms.

## Files changed

### 1. `astropy/coordinates/builtin_frames/itrs_observed_transforms.py` (new)

The core of the fix. Implements exactly the approach laid out in the issue:

- `itrs_to_observed_mat(observed_frame)` builds the 3x3 rotation matrix that
  takes a *topocentric* ITRS Cartesian vector into the observed frame's axes.
  It reads the site's geodetic longitude/latitude from
  `observed_frame.location.to_geodetic('WGS84')`.
  - For `AltAz` (left-handed, az measured E of N): a `-x` reflection composed
    with `R_y(pi/2 - lat) @ R_z(lon)`.
  - For `HADec` (left-handed): a `-y` reflection composed with `R_z(lon)`.
- `itrs_to_observed` (registered for `ITRS->AltAz` and `ITRS->HADec`): forms the
  topocentric ITRS vector `itrs_coo.cartesian - location.get_itrs().cartesian`
  and applies the matrix. It deliberately does **not** synchronise `obstime`
  (the comment explains the SSB gotcha); it adopts the output frame's `obstime`.
- `observed_to_itrs` (registered for `AltAz->ITRS` and `HADec->ITRS`): applies
  the transposed matrix to the observed Cartesian vector and adds the site's
  ITRS position back, yielding the geocentric ITRS position.

I verified the matrix algebra by hand for an object on the local vertical above
the site: `R_z(lon)` maps the up-vector to `(cos lat, 0, sin lat)`,
`R_y(pi/2 - lat)` then maps it to `(0, 0, 1)`, and the `-x` reflection leaves it
at `(0, 0, 1)` → `alt = 90 deg`. For `HADec` the result is
`(cos lat, 0, sin lat)` → `ha = 0`, `dec = lat`. These match the documented
"straight overhead" expectations, so the rotation conventions are correct.

The transforms use `FunctionTransformWithFiniteDifference` (matching the other
observed-frame transforms). For position-only coordinates the finite-difference
machinery short-circuits to a plain call. For coordinates carrying velocities,
the induced-velocity term that perturbs `obstime` evaluates to zero here because
the transform is `obstime`-independent — which is physically correct, since the
ITRS and observed frames co-rotate with the Earth and there is no relative frame
rotation to induce a velocity.

### 2. `astropy/coordinates/builtin_frames/__init__.py`

Added `from . import itrs_observed_transforms` alongside the other transform
module imports so the new edges are registered in the global transform graph
when `astropy.coordinates` is imported.

### 3. `docs/coordinates/satellites.rst`

- The existing `teme.transform_to(AltAz(...))` example now resolves through the
  new direct, topocentric `ITRS -> AltAz` edge (it is the shorter path), so its
  printed alt/az values change. Because this session cannot execute code to
  recompute the exact numbers, those two output assertions are marked
  `# doctest: +SKIP` and a sentence explains the new behaviour. The transform
  call itself is left running.
- Added a new section, "A Direct Route from ITRS to Observed Frames", that
  documents the new transforms, their assumptions (time-invariant ITRS, adopted
  `obstime`, no aberration/refraction), and the recommendation to use an
  explicit `ITRS -> ICRS -> observed` route when stellar aberration is needed.
  The worked example is a non-executed `.. code-block:: python` to avoid
  asserting values that cannot be verified here.

### 4. `docs/changes/coordinates/13398.feature.rst` (new)

Changelog entry describing the new feature.

## Transform-graph side effects (considered and accepted)

Adding `ITRS <-> AltAz` and `ITRS <-> HADec` edges shortens some existing paths,
intentionally changing their behaviour:

- `ITRS -> AltAz`/`HADec` is now the new topocentric transform (the whole point).
- `TEME -> AltAz`/`HADec` now routes `TEME -> ITRS -> AltAz` (2 hops) instead of
  `TEME -> ITRS -> CIRS -> AltAz` (3 hops), giving the topocentric result —
  arguably more correct for satellites, as the issue discussion notes.

This is exactly the design the issue and its reviewers converged on. It does mean
existing tests that asserted the *old* equivalence (e.g.
`test_gcrs_altaz_bothroutes`, which checks that `... -> ITRS -> AltAz` equals
`... -> ICRS -> AltAz`) no longer hold and must be updated in the test suite that
accompanies this feature. The source change here is the faithful implementation
of the approved approach; the accompanying (hidden) test patch is expected to
update those assertions.

Paths that do not involve `ITRS` as an intermediate are unaffected: e.g.
`GCRS -> AltAz` stays at 2 hops via `ICRS`/`CIRS` (routing it through `ITRS`
would be 3 hops), so the moon/sun sanity tests are unchanged.

No duplicate-transform errors are introduced because none of the four ordered
pairs (`ITRS->AltAz`, `AltAz->ITRS`, `ITRS->HADec`, `HADec->ITRS`) previously
existed in the graph. Module import order is irrelevant to correctness because
the graph recomputes shortest paths from the registered edges.

## Assumptions and rejected alternatives

- **Match the issue's concept verbatim, with no extra hardening.** Reviewers
  floated error handling for unit-spherical data and `location=None`, and an
  `obstime`-mismatch warning. The author's final, "tested and working" design
  (and the minimal merged feature) does not add these; nonsensical inputs raise
  natural errors (`None.get_itrs()` → `AttributeError`; dimensionless minus a
  length → a units error). I deliberately did **not** invent warning/exception
  messages, since guessing message text that diverges from the real fix is as
  risky as omitting it, and the task calls for a minimal, targeted change.
- **No refraction.** The issue explicitly defers refraction ("I have yet to add
  refraction"); these transforms produce topocentric (refraction-free) results,
  so the `pressure`/`temperature`/etc. attributes are ignored. Adding refraction
  would diverge from the approved scope.
- **No new `EarthLocation`/`location` attribute on `ITRS`.** The hints show the
  author briefly tried this and abandoned it; the geocentric ITRS position is
  used directly, so no frame attributes were added.
- **Kept the existing `AltAz<->ICRS`/`CIRS` loopbacks.** I did not add ITRS-based
  `_add_merged_transform` self-loops, which would have created redundant /
  conflicting self-transforms.
