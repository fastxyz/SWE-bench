# Baseline Notes

## Root cause

`SlicedLowLevelWCS.world_to_pixel_values` rebuilt the complete world-coordinate
tuple required by the wrapped WCS. For world axes removed by an integer pixel
slice, it used the placeholder value `1.0`. That is not generally the world
coordinate represented by the fixed pixel slice.

This breaks inverse transforms when a kept world axis is coupled to a sliced-out
pixel axis. The wrapped WCS needs the dropped world coordinate that corresponds
to the fixed pixel value in the slice; otherwise, `world_to_pixel_values` solves
for the wrong point and can return a wildly incorrect kept pixel coordinate.

## Changed files

`repo/astropy/wcs/wcsapi/wrappers/sliced_wcs.py`

- Added `_world_values_at_sliced_pixel`, a cached private helper that evaluates
  the wrapped WCS at the fixed slice pixels and zero in the remaining sliced-WCS
  pixel coordinates.
- Reused that helper in `dropped_world_dimensions`, preserving the existing
  source of dropped-world metadata while making it available to the inverse
  transform path.
- Replaced the hard-coded `1.0` dropped-world placeholder in
  `world_to_pixel_values` with the corresponding value from
  `_world_values_at_sliced_pixel`.

## Assumptions and alternatives

I assumed that world axes omitted from the sliced WCS are independent of the
kept pixel axes according to the existing `axis_correlation_matrix` logic. Under
that contract, evaluating the omitted world coordinate at zero in the sliced WCS
pixel coordinates is sufficient because the omitted coordinate is fixed by the
integer slice.

I considered using the public `dropped_world_dimensions["value"]` data directly,
but rejected it because callers can inspect and mutate that dictionary. A private
cached helper keeps `world_to_pixel_values` independent of public metadata
mutation while preserving the same underlying calculation.

I did not add or modify tests because the task explicitly forbids changing test
files, and I did not run the test suite or execute project code because the task
states that no execution environment is available.
