# Proof Obligations

Status: constructed obligations, not machine-checked.

## PO1: ITRS has a location frame attribute

- Statement: `ITRS.location` exists and defaults to `EARTH_CENTER`.
- Source evidence: E3, E7.
- Code evidence: `itrs.py` imports `EarthLocationAttribute` and sets
  `location = EarthLocationAttribute(default=EARTH_CENTER)`.
- Status: discharged by inspection and K claim C8.

## PO2: Matching-location ITRS->AltAz/HADec is direct in no-refraction mode

- Statement: if `itrs_coo.location == observed_frame.location` and
  `pressure == 0`, output data equal the local observed rotation of
  `itrs_coo.cartesian`.
- Source evidence: E1, E2, E3.
- Code evidence: `itrs_to_observed` skips ITRS self-transform when locations
  match and applies `itrs_to_observed_mat`.
- Status: discharged by K claims C1/C2.

## PO3: Matching-location direct path ignores obstime synchronization

- Statement: the matching-location no-refraction path does not call
  `transform_to(ITRS(obstime=...))`.
- Source evidence: E2.
- Code evidence: `itrs_to_observed` only constructs a new ITRS frame inside the
  location-changed branch.
- Status: discharged by branch inspection and K claims C1/C2.

## PO4: Differing-location ITRS->observed delegates origin changes

- Statement: if source and observed locations differ, the new transform uses
  the existing ITRS self-transform before local rotation.
- Source evidence: E4, E6.
- Code evidence: location-changed branch calls
  `itrs_coo.transform_to(ITRS(..., location=observed_frame.location))`.
- Status: discharged by K claim C3.

## PO5: Refraction is routed through CIRS and requires obstime

- Statement: non-zero pressure uses CIRS conversion; missing `obstime` raises a
  clear error.
- Source evidence: E5.
- Code evidence: `_observed_frame_has_refraction` branch calls
  `_check_refraction_obstime`, `cirs_to_itrs_mat`, and CIRS observed transforms.
- Status: discharged by K claims C6/C7 and branch inspection.

## PO6: Observed->ITRS creates topocentric ITRS before origin delegation

- Statement: no-refraction observed data are inverse-rotated into topocentric
  ITRS at the observed location and the target ITRS obstime; any differing
  target location is handled by ITRS self-transform.
- Source evidence: E1, E3, E4.
- Code evidence: `observed_to_itrs` creates
  `ITRS(topocentric_itrs_repr, obstime=itrs_frame.obstime,
  location=observed_coo.location)` and then transforms to `itrs_frame`.
- Status: discharged by K claims C4/C5.

## PO7: Intermediate ITRS/CIRS/TETE transforms preserve location

- Statement: ITRS->CIRS/TETE creates intermediate frames with
  `location=itrs_coo.location`; CIRS/TETE->ITRS targets `itrs_frame.location`.
- Source evidence: E3 and the topocentric ITRS design.
- Code evidence: `intermediate_rotation_transforms.py` updated in all four
  relevant transform functions.
- Status: discharged by K claims C8/C9.

## PO8: `earth_location` accounts for topocentric ITRS location

- Statement: converting ITRS data to `EarthLocation` uses `data + location`,
  not only raw frame data.
- Source evidence: E7 and public compatibility with `EarthLocationAttribute`.
- Code evidence: `itrs.py` computes cartesian data without differentials and
  adds `self.location.get_itrs().cartesian`.
- Status: discharged by K claim C10.

## PO9: Missing location fails clearly

- Statement: observed frames with `location is None` are rejected by direct
  ITRS observed transforms.
- Source evidence: public hints about hardening nonsensical inputs.
- Code evidence: `_check_observed_frame`.
- Status: discharged by inspection; model has `errNoLocation`.

## PO10: Transform graph registration occurs on built-in frame import

- Statement: importing built-in frames registers the new ITRS observed
  transforms.
- Source evidence: E1.
- Code evidence: `builtin_frames/__init__.py` imports
  `itrs_observed_transforms` after `intermediate_rotation_transforms`.
- Status: discharged by static import-order inspection.
