# Public Evidence Ledger

## E1: Need a direct ITRS/observed path

- Source: `benchmark/PROBLEM.md`
- Evidence: "a more direct approach. This approach stays entirely within the
  ITRS and merely converts between ITRS, AltAz, and HADec coordinates."
- Obligation: Add transform graph edges for ITRS<->AltAz and ITRS<->HADec.
- Status: Encoded by PO1 and PO7.

## E2: Avoid ITRS obstime synchronization for the topocentric shortcut

- Source: `benchmark/PROBLEM.md`
- Evidence: "Trying to synchronize the obstimes here makes no sense" and
  "we treat ITRS coordinates as time invariant here."
- Obligation: When the ITRS data are already in the observed location's
  topocentric ITRS frame, the no-refraction transform must be a local rotation
  rather than an ITRS self-transform through another obstime.
- Status: Encoded by PO2 and PO3.

## E3: Later public discussion pivots to explicit topocentric ITRS

- Source: `benchmark/PROBLEM.md`
- Evidence: "What I came up with is an actual topocentric ITRS frame" and
  "all they need to do is subtract the ITRS coordinates of the observing site
  from the coordinates of the target satellite, put the result into a
  topocentric ITRS frame and do the transform to Observed."
- Obligation: Add a `location` attribute to ITRS and make the direct shortcut
  apply to explicitly topocentric ITRS data.
- Status: Encoded by PO1, PO2, PO3, and PO8.

## E4: Do not create a blanket geocentric shortcut

- Source: `benchmark/PROBLEM.md`
- Evidence: "Doing this won't create a direct path for satellite observations
  from geocentric ITRS to Observed without stellar aberration corrections."
- Obligation: A geocentric ITRS coordinate should not be directly translated
  to the observer by subtracting the observing site in the new transform.
- Status: Encoded by PO4.

## E5: Refraction should be handled if included

- Source: `benchmark/PROBLEM.md`
- Evidence: "I have yet to add refraction, but I can do so if it is deemed
  important" and later "topocentric ITRS and Observed with the addition and
  removal of refraction tested and working."
- Obligation: The new path must not ignore non-zero `pressure`.
- Status: Encoded by PO5.

## E6: Existing docs/tests preserve geocentric aberration behavior

- Source: `repo/docs/coordinates/common_errors.rst` and
  `repo/astropy/coordinates/tests/test_regression.py`
- Evidence: common-errors docs explain that `obj.get_itrs(t).transform_to(AltAz(...))`
  is not zenith for a topocentric observer; regression tests repeat this
  geocentric/topocentric distinction.
- Obligation: Preserve geocentric ITRS behavior while adding the explicit
  topocentric path.
- Status: Encoded by PO4 and FINDING F1.

## E7: ITRS location support was an implementation blocker

- Source: `benchmark/PROBLEM.md`
- Evidence: "I added an EarthLocation as an argument for ITRS defaulting to
  .EARTH_CENTER" and the shown `TypeError` for unexpected keyword `location`.
- Obligation: ITRS must accept a `location` frame attribute with an Earth
  center default.
- Status: Encoded by PO1.
