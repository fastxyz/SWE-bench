# FVK Findings

Status: constructed audit findings, not machine-checked.

## F1: Initial direct-geocentric proposal conflicts with later topocentric design

- Input: `EarthLocation(...).get_itrs(t).transform_to(AltAz(location=home, obstime=t))`
- V1 behavior: if source ITRS location is Earth center and target observed
  location is `home`, V1 delegates the origin change to the existing ITRS
  self-transform before local observed rotation.
- Direct-subtraction alternative: subtract `home.get_itrs().cartesian` directly
  from every geocentric ITRS coordinate and rotate locally.
- Expected by final public intent: V1 behavior. The later issue discussion says
  the solution is "an actual topocentric ITRS frame" and "won't create a direct
  path for satellite observations from geocentric ITRS to Observed without
  stellar aberration corrections."
- Classification: resolved ambiguity; no V2 code change.
- Proof link: PO4.

## F2: Topocentric ITRS requires an explicit location attribute

- Input: `ITRS(topocentric_vector, obstime=t, location=home)`
- V1 behavior: accepted because ITRS now has `location =
  EarthLocationAttribute(default=EARTH_CENTER)`.
- Expected: accepted; this was the concrete public blocker shown by the issue.
- Classification: fixed code gap.
- Proof link: PO1, PO8.

## F3: Missing observed-frame location is outside the transform domain

- Input: `ITRS(...).transform_to(AltAz(location=None))` or
  `AltAz(location=None).transform_to(ITRS(...))`
- V1 behavior: raises `ValueError("ITRS<->observed transforms require an EarthLocation")`.
- Expected: fail clearly. The public hints mention hardening against
  nonsensical missing Earth locations.
- Classification: positive precondition guard.
- Proof link: PO9.

## F4: Refraction with `obstime=None` is outside the transform domain

- Input: `ITRS(location=home).transform_to(AltAz(location=home, obstime=None, pressure!=0))`
- V1 behavior: raises `ValueError("Refraction requires an observed frame obstime")`.
- Expected: fail clearly rather than silently ignoring pressure, because the
  refraction path uses ERFA/CIRS time-dependent context.
- Classification: positive precondition guard.
- Proof link: PO5.

## F5: Full numeric astronomy semantics are an escalation boundary

- Input: any concrete high-precision AltAz/HADec value.
- V1/FVK model behavior: the proof models rotations and refraction as named
  abstract functions, not numeric ERFA/NumPy implementations.
- Expected: this FVK pass proves dispatch/origin/time/refraction routing, not
  floating-point astronomical accuracy.
- Classification: proof capability gap / escalation boundary.
- Proof link: PO2, PO5, PROOF section "Trusted base and limits".

## F6: Documentation can be improved but V1 code is not blocked

- Input: docs under `docs/coordinates/common_errors.rst`.
- Observed: the docs still show the older CIRS topocentric workaround. That
  workaround remains valid, but no longer shows the simpler topocentric ITRS
  path V1 enables.
- Expected: optional future documentation update. This is not a production-code
  correctness issue for the requested benchmark fix.
- Classification: documentation follow-up, not V2 code change.
- Proof link: PO10.

## Proof-Derived Findings from `/verify`

The constructed proof obligations close over the abstract branch semantics in
`itrs-observed-spec.k`. No proof-derived production-code bug was found in V1.
The only open item is F5: full numeric and existing graph semantics are outside
the mini-K fragment and require either real Python/Astropy semantics or concrete
tests/manual review after the benchmark constraints are lifted.
