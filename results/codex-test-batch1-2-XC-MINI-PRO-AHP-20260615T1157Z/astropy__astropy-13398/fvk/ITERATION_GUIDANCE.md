# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Code Changes Made in This Iteration

1. Added `warn_if_obstime_mismatch()` to `intermediate_rotation_transforms.py`.
2. Called it from direct `ITRS -> ITRS`.
3. Called it from direct `ITRS -> AltAz/HADec` and `AltAz/HADec -> ITRS`.

These changes address F1 and PO4. The matrix/origin algebra from V1 stands.

## Tests to Add Later

Do not edit tests in this benchmark task. Recommended future public tests:

1. `ITRS(obstime=t1).transform_to(ITRS(obstime=t2))` warns when `t1 != t2` and preserves `P_geo`.
2. `ITRS(obstime=t1).transform_to(AltAz(obstime=t2, location=loc))` warns when `t1 != t2`.
3. `AltAz(obstime=t1, location=loc).transform_to(ITRS(obstime=t2))` warns when `t1 != t2`.
4. Direct no-refraction ITRS->AltAz for an object directly above an observer returns altitude `90 deg` and finite distance equal to the height difference.
5. Direct no-refraction ITRS->HADec for the same case returns hour angle `0` and declination equal to observer latitude.
6. A coordinate-valued `location` argument accepted by `EarthLocationAttribute` still converts through `ITRS().earth_location` to the expected geocentric EarthLocation after adding `ITRS.location`.
7. Unit-spherical ITRS inputs preserve direction and do not claim finite topocentric distance; whether they should warn remains a product decision.

## Questions for Future Intent Clarification

1. Should mismatched `obstime` be a warning or a hard exception for direct ITRS Earth-fixed transforms? The public discussion permits either; V2 chooses warning for compatibility.
2. Should unit-spherical ITRS inputs warn, error, or assume a geoid distance? Public discussion is unresolved.
3. Should the documentation explicitly show the recommended satellite workflow: subtract observer ITRS, create topocentric ITRS with `location`, then transform to observed?

## Machine-Check Follow-Up

Run the commands in `fvk/PROOF.md` after translating the mini semantics into a fully checked K fragment. Keep all tests until `kprove` returns `#Top` and the abstraction boundaries are reviewed.
