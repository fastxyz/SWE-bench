# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Machine-Check Commands

```sh
kompile fvk/mini-itrs-transform.k --backend haskell
kast --backend haskell fvk/itrs-transform-spec.k
kprove fvk/itrs-transform-spec.k
```

Expected result after a full K implementation check: all claims discharge to `#Top`. This run did not execute those commands.

## PO1 Proof: Origin Shift

The implementation computes:

```text
newrepr = P + L_src - L_dst
```

The target frame interprets the returned data relative to `L_dst`, so the resulting geocentric vector is:

```text
newrepr + L_dst
= (P + L_src - L_dst) + L_dst
= P + L_src
```

Thus the Earth-fixed geocentric position is preserved. This proves the direct `ITRS -> ITRS` algebra for finite data and also proves the origin-shift component used before and after observed-frame transforms.

## PO2 Proof: No-Refraction ITRS Observed Round Trip

For no-refraction direct observed transforms, ITRS to observed first computes:

```text
P_topo = P + L_src - L_obs
O = M_obs * P_topo
```

`M_obs` is a product of rotation matrices and a single axis reflection. Each factor is orthogonal, so their product is orthogonal:

```text
transpose(M_obs) * M_obs = I
```

The reverse transform computes:

```text
P_topo' = transpose(M_obs) * O
        = transpose(M_obs) * M_obs * P_topo
        = P_topo
```

It then realizes ITRS data relative to `L_obs` and delegates to the ITRS origin-shift proof if the requested target frame has a different `location`. Therefore the direct no-refraction round trip preserves the intended Earth-fixed vector and discharges the straight-overhead geometry: if `P_topo` is the local vertical vector, `M_altaz * P_topo` has altitude `+90 deg`; if represented in HADec at latitude `lat`, the same local vertical maps to hour angle `0` and declination `lat`.

## PO3 Proof: Refraction Boundary

The refraction branch shares the same topocentric pre-state:

```text
P_topo = P + L_src - L_obs
```

It requires `observed_frame.obstime is not None`, then computes:

```text
C_topo = transpose(cirs_to_itrs_mat(obstime)) * P_topo
```

The result is realized as `CIRS(C_topo, obstime=observed_frame.obstime, location=L_obs)` and transformed to the observed frame through the existing CIRS-observed path. Thus the new code proves the part it owns: it supplies a topocentric CIRS vector at the observer and avoids the inertial aberration route. The existing CIRS-observed refraction semantics are outside this patch's proof boundary.

## PO4 Proof: Mismatched Obstime Warning

`warn_if_obstime_mismatch(from_frame, to_frame)` reads both frame attributes. If both exist and any element differs, it calls:

```text
warnings.warn(..., AstropyWarning)
```

The helper is called at the entry of direct `ITRS -> ITRS`, `ITRS -> AltAz/HADec`, and `AltAz/HADec -> ITRS` paths. Therefore every direct Earth-fixed path that ignores a differing source `obstime` now emits the public-intent-required warning before returning the same coordinate value as V1.

## PO5 Proof: Unit-Spherical Boundary

The implementation checks `coo.cartesian.x.unit == u.one`. In this case the ITRS self-transform returns the input data in the target frame without adding or subtracting origins. The direct observed path likewise avoids finite origin subtraction in `_topocentric_itrs_repr`. Since no finite distance exists, the formal spec makes no claim about parallax or topocentric distance for these inputs. This matches the public ambiguity and prevents a false proof of an invented geoid/distance policy.

## Test-Redundancy Recommendation

No test removal is recommended. The proof is constructed, not machine-checked, and it abstracts over full Astropy units, ERFA precision, frame graph path selection, and warnings. Existing public tests should be kept. New tests should be added for the V2 warning behavior after this FVK pass, but this task forbids editing tests.

## Residual Risk

- The proof is partial correctness only.
- It abstracts vector arithmetic and matrix orthogonality but does not machine-check NumPy/ERFA behavior.
- The warning behavior is source-inspected but not executed.
- Unit-spherical semantics remain an explicit unresolved policy point.
