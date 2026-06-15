# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO1: ITRS Origin Shift Preserves Geocentric Earth-Fixed Position

For finite coordinate data:

- Let `P` be the local Cartesian vector in an ITRS frame with origin `L_src`.
- Let `L_dst` be the target ITRS origin.
- The implementation returns `P' = P + L_src - L_dst`.
- Required postcondition: `P' + L_dst = P + L_src`.

This discharges intent entries I1, I3, and I8 for direct ITRS origin changes.

## PO2: No-Refraction Observed Round Trip Uses Inverse Matrices

For finite coordinate data and observer origin `L_obs`:

- ITRS to observed forms `P_topo = P + L_src - L_obs`.
- AltAz/HADec transform applies a matrix `M_obs`.
- Observed to ITRS applies `transpose(M_obs)`.
- `M_obs` is a product of rotations and one axis reflection, so `transpose(M_obs) * M_obs = I`.
- Required postcondition: observed round trip returns the same topocentric vector before the final ITRS origin shift.

This discharges I1, I2, and I7 for no-refraction direct paths.

## PO3: Refraction Direct Path Keeps the Same Topocentric Vector Boundary

For refraction-corrected observed frames:

- The transform requires a non-`None` observed `obstime`.
- It computes the same `P_topo = P + L_src - L_obs`.
- It rotates `P_topo` through `cirs_to_itrs_mat(obstime).T` into a topocentric CIRS vector at the observed frame's location/time.
- Existing CIRS-observed transforms own the refraction correction.

The proof obligation is not to re-prove ERFA refraction. It is to prove the new direct path feeds the existing refraction code the correct topocentric CIRS input and does not use the inertial ICRS/SSB route.

## PO4: Mismatched Obstime Emits a Warning

For any direct Earth-fixed path between frames `A` and `B`:

- If `A.obstime is not None`, `B.obstime is not None`, and `A.obstime != B.obstime`, then `warn_if_obstime_mismatch(A, B)` emits `AstropyWarning`.
- If either `obstime` is `None` or the values are equal, no warning is required by this obligation.
- Returned coordinate values are unchanged by the warning.

This discharges I6 and fixes F1.

## PO5: Unit-Spherical Inputs Do Not Claim Finite Origin Shifts

For data whose cartesian `x` unit is dimensionless:

- The direct ITRS origin-shift path returns the same data in the target frame.
- Direct observed paths rotate the direction without subtracting finite origins.
- No finite topocentric distance postcondition is claimed.

This prevents the proof from encoding an invented distance policy not settled by public intent.
