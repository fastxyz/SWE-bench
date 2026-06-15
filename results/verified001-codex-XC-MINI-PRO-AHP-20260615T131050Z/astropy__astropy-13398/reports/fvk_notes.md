# FVK Notes

## Decision

V1 stands as V2. I did not apply additional production-code edits after the FVK
audit.

## Trace to Findings and Proof Obligations

The main audit question was whether V1 should directly subtract the observer
from all geocentric ITRS coordinates, matching the issue's first sketch, or
preserve geocentric behavior and require users to construct explicit
topocentric ITRS coordinates. `fvk/FINDINGS.md` F1 records the conflict and
resolves it using later public issue text: the final design is an actual
topocentric ITRS frame and "won't create a direct path" from geocentric ITRS to
Observed without stellar aberration corrections. That supports keeping V1's
location-mismatch delegation. The corresponding proof obligation is PO4.

I kept the new `ITRS.location` attribute from V1 because F2 identifies it as
the concrete public blocker shown in the issue, and PO1 requires it with an
Earth-center default. I also kept the `earth_location` adjustment because PO8
requires topocentric ITRS data to project as `location + data` when converted
to an `EarthLocation`.

I kept the direct no-refraction ITRS<->AltAz/HADec path unchanged because PO2,
PO3, and PO6 state the intended topocentric behavior: matching-location ITRS
data rotate directly to observed frames, do not synchronize obstime through the
ITRS self-transform, and inverse transforms create topocentric ITRS at the
observed location before any requested origin change.

I kept the intermediate CIRS/TETE changes because PO7 shows they are necessary
to avoid dropping `ITRS.location` and reinterpreting topocentric data as
geocentric.

I kept the explicit `ValueError` guards for missing observed location and
refraction without `obstime` because F3 and F4 classify them as positive
precondition guards. They correspond to PO9 and PO5 respectively.

I did not attempt to edit docs during this pass. F6 notes that
`docs/coordinates/common_errors.rst` can be improved to show the new
topocentric ITRS workflow, but it is not a production-code correctness blocker
for this benchmark. `fvk/ITERATION_GUIDANCE.md` records it as future work.

I did not run tests, Python, or K tooling. F5 and `fvk/PROOF.md` explicitly
mark full numerical Astropy/ERFA semantics as an escalation boundary, and the
proof is labeled constructed, not machine-checked.
