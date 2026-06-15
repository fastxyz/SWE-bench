# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-V1 Dropped-World Placeholder Violates Intent

Input: a sliced WCS with a dropped world axis whose fixed-slice world coordinate
is not `1.0`, such as the issue's wavelength slice where the fixed spectral
world value is `1.05 Angstrom`.

Observed before the repair: `world_to_pixel_values` rebuilt the wrapped WCS
world tuple using `1.0` for the dropped world axis.

Expected: it must use the world coordinate corresponding to the fixed pixel
slice.

Classification: code bug.

Related proof obligations: O2, O3, O4.

Status: fixed. V2 uses `_world_values_at_sliced_pixel()` in the dropped-axis
branch.

## F2: V1 Added An Unnecessary Cached Transform Dependency

Input: a sliced wrapper whose fixed dropped world values are computed once, then
the wrapped WCS is mutated or otherwise changes before a later inverse call.

Observed in V1: `_world_values_at_sliced_pixel` was a `lazyproperty`, so
`world_to_pixel_values` could reuse stale fixed world values after the first
calculation.

Expected: the transform path should reconstruct the fixed dropped world values
from the current wrapped WCS state for that call. The public issue requires the
right value, not caching.

Classification: compatibility and implementation-risk finding.

Related proof obligations: O2, O7.

Status: fixed in V2. The helper is a regular method, and
`world_to_pixel_values` computes it once per call only when a dropped world axis
exists.

## F3: Full FITS/NumPy Semantics Are A Proof Capability Boundary

Input: arbitrary real `astropy.wcs.WCS` objects with wcslib distortions, unit
conversions, broadcasting edge cases, or non-local inverse behavior.

Observed in this FVK run: the K model abstracts the wrapped transforms as `p2w`
and `w2p` and uses explicit side conditions for local inverse behavior and
dropped-world independence.

Expected: a complete machine proof of all FITS WCS numerical behavior would need
a real Python/NumPy/wcslib semantics and WCS model.

Classification: proof capability gap / escalation boundary, not a code bug in
the wrapper fix.

Related proof obligations: O3, O4, O6.

Status: open capability boundary. Keep integration tests and run the emitted
K commands only as a check of the abstract wrapper proof.

## F4: Regression Tests Should Cover The Reported Coupled-Axis Case

Input: the issue's 3D WCS with a celestial axis coupled to the sliced-out
spectral pixel axis.

Observed in this task: tests are fixed and hidden; no test files may be edited.

Expected if tests were editable: add a regression asserting that
`SlicedLowLevelWCS(fits_wcs, 0).world_to_pixel_values(world[0], world[1])`
returns the kept pixels from the full inverse.

Classification: test gap.

Related proof obligations: O2, O3, O4.

Status: documented only; no test edits made.
