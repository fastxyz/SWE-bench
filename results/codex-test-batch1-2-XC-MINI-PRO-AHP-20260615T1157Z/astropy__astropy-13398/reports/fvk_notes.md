# FVK Notes

## Decisions

The FVK audit confirmed V1's core direct-transform algebra: finite ITRS data are interpreted as local vectors relative to `ITRS.location`, transformed by preserving `P_geo = P_local + L_src`, and converted to observed frames from the topocentric vector `P_geo - L_obs`. This is justified by `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO1-PO2, so the V1 matrix/origin implementation stands.

The audit found one public-intent gap in V1. The issue discussion explicitly required a warning or exception when both source and target frames have differing `obstime` values, because the direct Earth-fixed path ignores the source time. V1 silently ignored that mismatch. This is `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO4.

## Code Changes

`repo/astropy/coordinates/builtin_frames/intermediate_rotation_transforms.py`

- Added `warn_if_obstime_mismatch(from_frame, to_frame)`.
- Called it from the direct `ITRS -> ITRS` transform before the origin shift.
- The warning uses `AstropyWarning` and tells users that ITRS coordinates are being treated as time-invariant Earth-fixed positions, with explicit ICRS routing recommended for inertial time evolution.

`repo/astropy/coordinates/builtin_frames/itrs_observed_transforms.py`

- Imported `warn_if_obstime_mismatch`.
- Called it from direct `ITRS -> AltAz/HADec`.
- Called it from direct `AltAz/HADec -> ITRS`.

No tests or Python commands were run. The task forbids execution, so verification is source inspection plus the constructed proof in `fvk/PROOF.md`.

## Kept From V1

The new `ITRS.location` attribute, `earth_location` addition of frame origin, direct observed transform matrices, refraction delegation through CIRS, and explicit geocentric conversion around CIRS/TETE transforms are unchanged. They are covered by `fvk/FINDINGS.md` F2-F3 and `fvk/PROOF_OBLIGATIONS.md` PO1-PO3.

Unit-spherical behavior is unchanged because public intent is unresolved. `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO5 record that no finite topocentric distance proof is claimed for those inputs.
