# Baseline notes: `world_to_pixel` inconsistency in `SlicedLowLevelWCS`

## Issue summary

For a 3D WCS (space, space, wavelength) whose `PCij` matrix couples the spectral
and spatial axes, `world_to_pixel` on the *unsliced* WCS returns the expected
pixel coordinates, but the same operation on a single-wavelength slice produced
via `SlicedLowLevelWCS` returns an "essentially infinite" value (~`1.8e11`) for
one of the kept (spatial) dimensions. The corresponding `pixel_to_world`
operations were already correct.

## Root cause

In `astropy/wcs/wcsapi/wrappers/sliced_wcs.py`,
`SlicedLowLevelWCS.world_to_pixel_values` must reconstruct a full set of world
coordinates for the underlying (unsliced) WCS before calling its
`world_to_pixel_values`, because the underlying inverse transform needs values
for *every* world axis, including the ones that were sliced out.

For the world axes that were sliced out, the old code injected a hardcoded
placeholder:

```python
else:
    world_arrays_new.append(1.)
```

This is wrong for two compounding reasons:

1. **Coupling.** When the `PCij` matrix couples a dropped world axis (wavelength)
   to a kept pixel axis (a spatial axis), the value supplied for the dropped
   world axis directly influences the pixel coordinate returned for the kept
   axis. So a placeholder cannot be arbitrary — it must equal the world
   coordinate that the slice actually corresponds to, otherwise the inverse
   transform solves the wrong system.

2. **Units.** The low-level WCS API operates in SI units. For a `WAVE` axis the
   world value is in metres, so the placeholder `1.` was interpreted as
   `1.0 m`, whereas the true wavelength at the slice is `1.05e-10 m`. The error
   is therefore scaled by roughly `1 / CDELT3_SI = 1 / 0.055e-10 ≈ 1.8e11`,
   matching the reported `array(1.81818182e+11)`.

Concretely, for the reported header the spatial intermediate coordinate of the
second axis is `x2 = CDELT2 * ((p1 - CRPIX1) - (p3 - CRPIX3))`, i.e. it depends
on the wavelength pixel `p3`. Inverting the full transform gives
`p1 = CRPIX1 + x2/CDELT2 + (w3 - CRVAL3)/CDELT3`. Feeding `w3 = 1.0` (metres)
instead of the true slice value `w3 = 1.05e-10 m` injects the enormous
`(1.0 - 1.05e-10)/0.055e-10 ≈ 1.8e11` offset into `p1`.

## Fix

Compute the actual world coordinates that the slice corresponds to and use those
for the dropped world axes instead of `1.`. The world coordinate at the slice is
obtained from the already-existing helper `_pixel_to_world_values_all`, evaluated
with the kept pixel coordinates set to `0` (the dropped pixel axes are
automatically pinned to their integer slice index inside that helper). This is
the same expression already used by the `dropped_world_dimensions` property, so
the behaviour is consistent across the class.

### File changed: `astropy/wcs/wcsapi/wrappers/sliced_wcs.py`

`world_to_pixel_values` now begins by computing

```python
sliced_out_world_coords = self._pixel_to_world_values_all(*[0]*len(self._pixel_keep))
```

and, for each world axis that is *not* kept, appends
`sliced_out_world_coords[iworld]` (the true world value at the slice) rather than
`1.`. The index `iworld` runs over all underlying world dimensions, and
`_pixel_to_world_values_all` returns one value per underlying world dimension, so
the indexing lines up directly. The else branch is only reached when a world
dimension is dropped, which requires at least two underlying world dimensions
(otherwise `__init__` raises), so `sliced_out_world_coords` is always a tuple
that can be indexed.

With this change, for the reported example the dropped wavelength axis is fed its
true slice value (`1.05e-10 m`), the coupled offset becomes `0`, and the sliced
`world_to_pixel` returns `(49.5, 12.0)` — matching the first two components of
the unsliced result, and the hint's `np.allclose(out_pix[0], 0)` assertion holds.

## Assumptions and alternatives considered

- **Evaluating the dropped world value at kept-pixel = 0.** The dropped world
  coordinate is exact whenever it does not depend on the kept pixel axes (true
  for the reported case, where wavelength depends only on the spectral pixel via
  `PC3 = [0, 0, 1]`). If a dropped world axis *also* depended on a kept pixel
  axis, this would be a first-order approximation, but that mirrors the existing
  `dropped_world_dimensions` implementation and keeps the two consistent; there
  is no exact, dependency-free value available without already knowing the
  answer. I deliberately reused the existing helper rather than introducing a
  new evaluation strategy.

- **Reusing `self.dropped_world_dimensions["value"]`.** This holds the same
  numbers but is indexed by dropped-axis order, requiring an extra counter to map
  back to the underlying world index. Using `_pixel_to_world_values_all`
  directly indexes by the underlying world index `iworld`, which is exactly what
  the loop needs, so it is simpler and avoids the (lazy-cached) extra dict
  construction. Rejected as more error-prone.

- **Caching `sliced_out_world_coords`.** It is recomputed on each call (one extra
  forward transform). I kept it inline for minimality and correctness; a
  `lazyproperty` could be added later as a pure optimisation but is out of scope
  for this fix.

- **Scope.** Only `world_to_pixel_values` is changed. `pixel_to_world_values`
  was already correct (the issue confirms this), and no test files were touched.
