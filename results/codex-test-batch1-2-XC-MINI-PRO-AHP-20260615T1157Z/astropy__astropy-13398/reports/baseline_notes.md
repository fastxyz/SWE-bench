# Baseline Notes

## Root Cause

The existing ITRS to observed-frame path reached AltAz/HADec through CIRS and
then, for topocentric observer changes, through an inertial frame. That route is
appropriate for distant apparent sky positions, but it applies geocentric versus
topocentric aberration semantics to nearby Earth-fixed positions such as
satellites. As a result, an ITRS position that is physically straight above an
observer can fail to transform to an observed altitude of 90 degrees.

ITRS also had no frame attribute for a local origin. All ITRS data was treated
as geocentric, so users had to manually subtract the observer position and store
the result in another topocentric frame to avoid the inertial route.

## Files Changed

`repo/astropy/coordinates/builtin_frames/itrs.py`

Added an `EarthLocation` frame attribute named `location`, defaulting to
`EARTH_CENTER`, so existing geocentric ITRS behavior remains the default while
topocentric ITRS offsets can be represented directly. Updated
`earth_location` to add the frame origin before constructing an EarthLocation.

`repo/astropy/coordinates/builtin_frames/intermediate_rotation_transforms.py`

Replaced the synthesized ITRS self-transform through CIRS with a direct ITRS
self-transform that only shifts origins. Updated ITRS-CIRS and ITRS-TETE
transforms so topocentric ITRS coordinates are converted to or from geocentric
ITRS explicitly before the existing rotation steps.

`repo/astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

Added direct transforms between ITRS and AltAz/HADec. The default no-refraction
case subtracts the observed location in ITRS and applies the local observed
axis rotation directly. For refraction-corrected frames, the code still avoids
ICRS and uses the existing CIRS-observed refraction logic after rotating the
topocentric ITRS vector into CIRS.

`repo/astropy/coordinates/builtin_frames/__init__.py`

Imported the new transform module so the direct ITRS-observed graph edges are
registered with the built-in frame graph.

## Assumptions and Alternatives

I assumed the accepted behavior should support both direct geocentric
ITRS-to-observed transforms and explicit topocentric ITRS frames. This keeps the
issue's simple satellite use case working while also matching the later
discussion that topocentric ITRS should be expressible as an ITRS frame with a
non-geocentric origin.

I treated ITRS-to-ITRS transforms as Earth-fixed origin shifts and did not
propagate them through an inertial frame. This follows the issue's core
complaint that ITRS positions near Earth should not be displaced by Earth's
orbital motion when only the ITRS origin or output `obstime` changes.

I did not reject unit-spherical or dimensionless Cartesian ITRS data. Since no
distance is available, those values are treated as directions and origin shifts
are skipped, matching the behavior used by other observed-frame transforms for
unit-spherical coordinates.

I considered only adding ITRS to AltAz/HADec transforms without changing ITRS
self-transforms, but rejected that because topocentric ITRS origins would still
be mishandled when transforming ITRS to ITRS or through CIRS/TETE.
