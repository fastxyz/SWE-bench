# Formal Spec English

This file paraphrases the K claims in `itrs-observed-spec.k`.

## C1: Matching-Location ITRS to AltAz

For any vector `V`, location `L`, source time `T`, and observed time `TO`,
transforming `ITRS(location=L, obstime=T, data=V)` to
`AltAz(location=L, obstime=TO, pressure=0)` returns the observed frame with data
`rotate(AltAz, L, V)`. No ITRS self-transform or obstime synchronization occurs.

## C2: Matching-Location ITRS to HADec

Same as C1, but the local rotation is `rotate(HADec, L, V)`.

## C3: Differing-Location ITRS to Observed

If source ITRS location `L1` differs from target observed location `L2`, the
transform first applies the existing abstract ITRS self-transform
`selfITRS(L1, L2, T, chooseTime(TO, T), V)`, then rotates the resulting
topocentric ITRS vector at `L2` into the observed frame.

## C4: AltAz/HADec to Matching-Location ITRS

For no-refraction observed coordinates, the inverse transform rotates observed
data back with `inverseRotate(kind, L, V)` and returns
`ITRS(location=L, obstime=TOut)`.

## C5: AltAz/HADec to Differing-Location ITRS

If the requested output ITRS location differs from the observed location, the
transform first builds the topocentric ITRS vector at the observed location and
then delegates the origin change to `selfITRS`.

## C6: Refraction Requires Time and Uses CIRS

For refraction-enabled observed frames, `obstime=None` reaches a named error
state. Otherwise the transform routes through abstract CIRS refraction removal
or addition, rather than the pressure-zero local matrix.

## C7: ITRS Location Preservation Through CIRS/TETE

The abstract intermediate-rotation claims state that converting ITRS to an
intermediate topocentric-capable frame preserves the source location, and
converting CIRS/TETE to ITRS targets the requested ITRS location.

## C8: ITRS Earth Location Projection

The abstract projection claim states that `earth_location(ITRS(L, V))` denotes
`locationVector(L) + V`, so topocentric ITRS data are interpreted as geocentric
locations when converted to `EarthLocation`.
