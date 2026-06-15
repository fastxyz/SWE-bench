# Baseline Notes

## Root cause

ITRS did not carry an observer `location`, so Astropy could not represent an
explicitly topocentric ITRS vector. Transforming a nearby Earth-fixed object
from ITRS to observed frames therefore had to use indirect geocentric paths
through CIRS/ICRS-like machinery. That path is appropriate for ordinary
geocentric coordinates, but it is a poor fit for users who already have a
topocentric ITRS vector, because the transform graph has no way to know the
vector is relative to the observing site.

## Files changed

`astropy/coordinates/builtin_frames/itrs.py`

Added a `location` frame attribute to ITRS, defaulting to the Earth center,
matching the convention already used by topocentric-capable CIRS and TETE
frames. The `earth_location` property now includes the frame location offset so
topocentric ITRS data are interpreted as geocentric Earth locations when needed.
The frame docstring/footer were updated to describe the new attribute and the
topocentric use case.

`astropy/coordinates/builtin_frames/intermediate_rotation_transforms.py`

Updated ITRS<->CIRS and ITRS<->TETE transforms so they preserve the ITRS
`location` attribute. Without this, topocentric ITRS data would be rotated into
CIRS/TETE and then accidentally treated as geocentric.

`astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

Added direct transforms between ITRS and the observed frames AltAz/HADec. When
the ITRS coordinate is already relative to the observed location, the transform
uses a local ITRS rotation and avoids the geocentric aberration path. If the
locations differ, the code delegates the origin change to the existing ITRS
self-transform, preserving established geocentric behavior. Refraction requests
reuse the existing CIRS observed transform after the local ITRS vector is
rotated into CIRS.

`astropy/coordinates/builtin_frames/__init__.py`

Imported the new transform module so the transform graph registers the new
ITRS<->AltAz and ITRS<->HADec paths when built-in frames are imported.

## Assumptions and alternatives

I assumed the intended fix is the topocentric ITRS design discussed in the
issue, not a blanket reinterpretation of every geocentric ITRS coordinate as an
Earth-fixed object for observed-frame transforms. That keeps existing
geocentric ITRS semantics intact while giving satellite and nearby-object users
a direct, explicit topocentric workflow.

I considered directly subtracting the observed `EarthLocation` from every ITRS
coordinate when transforming to AltAz/HADec. I rejected that because it would
change existing behavior for geocentric ITRS coordinates and contradict the
later issue discussion that moved toward an explicit topocentric ITRS frame.

I also considered ignoring atmospheric refraction in the new direct path. I
rejected that because AltAz and HADec already expose pressure-dependent
refraction attributes; the implementation should either respect them or fail
clearly when the necessary `obstime` is absent.

No tests or code were run, per the benchmark instructions.
