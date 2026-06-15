# Intent Spec

Status: intent-first English obligations for the FVK audit of the V1 fix.

## Required Behavior

I1. Astropy must be able to represent an explicitly topocentric ITRS coordinate:
an ITRS vector may be relative to an `EarthLocation`, with the Earth center as
the default location.

I2. For an ITRS coordinate whose `location` equals the target observed frame's
`location`, ITRS->AltAz and ITRS->HADec must stay inside the ITRS/topocentric
rotation model. In the no-refraction case, the transform must not perform an
ITRS->ITRS obstime synchronization through the SSB-oriented self-transform.

I3. The inverse AltAz/HADec->ITRS transform must create a topocentric ITRS
coordinate at the observed location, with the caller's requested output ITRS
`obstime` and `location` honored.

I4. Existing geocentric ITRS behavior must not be silently reinterpreted as
Earth-fixed topocentric behavior for all callers. If a source ITRS location and
target observed location differ, the origin change must be delegated to the
existing ITRS self-transform semantics.

I5. If refraction is requested by non-zero observed-frame pressure, the
transform must use the existing CIRS observed machinery and require an
`obstime`, because that machinery needs time-dependent ERFA/CIRS context.

I6. ITRS<->CIRS and ITRS<->TETE intermediate transforms must preserve ITRS
`location`, otherwise topocentric ITRS data are reinterpreted as geocentric.

I7. The public transform graph must register ITRS<->AltAz and ITRS<->HADec
transforms when built-in frames are imported.

## Domain and Default Assumptions

D1. The formal model covers transform dispatch, origin handling, frame
attribute propagation, and local rotation shape. It abstracts the exact
floating-point trigonometry, ERFA refraction, and the existing Astropy
ITRS/CIRS/ICRS self-transform as uninterpreted but named operations.

D2. Partial correctness only: the constructed proof states what the transform
returns if the called existing Astropy transform routines return. It does not
prove termination or numerical accuracy of ERFA/NumPy matrix operations.

D3. Public in-repo docs/tests that preserve the geocentric ITRS aberration
behavior are treated as compatibility evidence, not as a veto of the new
topocentric path.
