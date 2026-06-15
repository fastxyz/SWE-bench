# Intent Spec

Scope: `SlicedLowLevelWCS` inverse transforms for valid integer/slice views of
a low-level WCS. This is an intent-only spec from the public issue, API
docstrings, and source comments; candidate behavior is treated as something to
check, not as the source of expected output.

## Required Behavior

1. For a sliced WCS, `world_to_pixel_values` must behave as the inverse of the
   sliced `pixel_to_world_values` on points that lie on the slice. If a kept
   sliced pixel vector `p` is expanded into the wrapped WCS pixel vector by
   inserting the fixed integer slice pixels and applying slice starts, then
   converting that full pixel vector to world values and keeping the sliced
   world axes must invert back to `p`.

2. When the sliced WCS drops a world axis, the inverse transform must supply the
   wrapped WCS with the dropped world value corresponding to the fixed sliced
   pixel. A placeholder such as `1.0` is not in the contract.

3. The sliced wrapper must preserve the existing low-level WCS coordinate order:
   pixel coordinates are in pixel order, array slices are reversed into pixel
   order, sliced world inputs follow `_world_keep`, and returned pixels follow
   `_pixel_keep`.

4. Range slices with non-`None` starts must continue to offset kept pixels on
   the way into the wrapped WCS and subtract those starts on the way out.

5. `dropped_world_dimensions["value"]` must describe the same fixed-slice world
   values that the inverse transform uses for omitted world axes.

6. The public method signatures and return-shape conventions of
   `world_to_pixel_values`, `pixel_to_world_values`, and
   `dropped_world_dimensions` must not change.

## Domain And Assumptions

- Slices are valid after `sanitize_slices`: integers or unit-step range slices,
  with at least one kept pixel dimension and one kept world dimension.
- The wrapped WCS is defined and locally invertible for the full world vectors
  considered here.
- The existing `axis_correlation_matrix` contract is trusted to identify dropped
  world axes that do not depend on kept pixel axes. Under that contract, the
  dropped world value can be evaluated at zero in sliced-WCS pixel coordinates.
- This audit proves partial correctness of the wrapper data flow. It does not
  prove termination, NumPy broadcasting internals, FITS WCS numerical accuracy,
  or the correctness of the wrapped WCS implementation itself.
