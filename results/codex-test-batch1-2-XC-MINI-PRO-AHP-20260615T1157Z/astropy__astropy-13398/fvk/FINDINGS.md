# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1: V1 Silently Ignored Mismatched Obstime

- Classification: code bug / missing user-visible guard
- Public evidence: issue discussion says that if `obstime` values are present in both frames, the transform should "either raise an exception or a warning".
- V1 observed behavior from source inspection: `itrs_to_itrs()`, `itrs_to_observed()`, and `observed_to_itrs()` treated ITRS positions as Earth-fixed and used the target frame time without warning when source and target `obstime` differed.
- Expected behavior: before ignoring the source `obstime`, warn or raise. A warning is sufficient under the public wording and preserves the direct transform path.
- V2 action: added `warn_if_obstime_mismatch()` and called it from direct `ITRS -> ITRS`, `ITRS -> AltAz/HADec`, and `AltAz/HADec -> ITRS` paths.
- Proof obligations: PO4.

## F2: V1 Correctly Preserved Finite Earth-Fixed Geocentric Positions

- Classification: confirmation
- Public evidence: issue asks for direct ITRS-observed behavior that treats ITRS positions as time-invariant nearby Earth-fixed positions.
- V1 observed behavior from source inspection: finite ITRS transforms compute `P_local + L_src - L_dst`, and direct observed transforms compute the topocentric vector before applying the observed-frame rotation.
- Expected behavior: geocentric Earth-fixed vector `P_geo = P_local + L_src` is invariant under origin changes, and observed-frame coordinates are based on `P_geo - L_obs`.
- V2 action: no algebraic change.
- Proof obligations: PO1, PO2.

## F3: Refraction Path Has a Bounded Dependency

- Classification: proof capability boundary / delegated existing behavior
- Public evidence: original proposed implementation had not yet added refraction, while existing AltAz/HADec frame docs define pressure-driven refraction behavior.
- V1 observed behavior from source inspection: refraction paths require an `obstime`, form the same topocentric ITRS vector, rotate it to CIRS, then delegate to existing CIRS-observed transforms.
- Expected behavior: direct ITRS transform should avoid the inertial aberration route while still using the existing CIRS refraction semantics.
- V2 action: no refraction algebra change; mismatch warnings also apply to refraction paths.
- Proof obligations: PO3.

## F4: Unit-Spherical ITRS Inputs Remain Underspecified

- Classification: underspecified intent
- Public evidence: public comments questioned coordinates without distances and suggested possible warning or geoid assumption, but did not settle a rule.
- V1 observed behavior from source inspection: `is_unitspherical()` skips origin shifts and preserves the direction.
- Expected behavior: no settled public requirement beyond avoiding nonsensical finite displacement when no distance exists.
- V2 action: no code change. This should be covered by future intent clarification and public tests.
- Proof obligations: PO5.
