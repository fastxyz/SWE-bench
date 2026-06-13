# Code review: V1 fix for astropy__astropy-13579

Scope reviewed: the single change in
`astropy/wcs/wcsapi/wrappers/sliced_wcs.py`, method
`SlicedLowLevelWCS.world_to_pixel_values`, where the dropped-world placeholder
`1.` was replaced by `sliced_out_world_coords[iworld]`, with
`sliced_out_world_coords = self._pixel_to_world_values_all(*[0]*len(self._pixel_keep))`.

Each finding is numbered, given a severity, and a verdict (action taken in V2).

---

## F1 — Correctness against the reported issue — CONFIRMED CORRECT (high)

Re-traced the reported example. The 3D WCS couples spectral and spatial axes:
the second spatial intermediate coordinate is
`x2 = CDELT2 * ((p1 - CRPIX1) - (p3 - CRPIX3))`, i.e. it depends on the spectral
pixel `p3`. Inverting the full transform gives
`p1 = CRPIX1 + x2/CDELT2 + (w3 - CRVAL3)/CDELT3`, so the kept spatial pixel `p1`
genuinely depends on the spectral world value `w3`.

The low-level API works in SI units, so the old placeholder `1.` meant `1.0 m`,
while the slice wavelength is `1.05e-10 m`; the injected error is
`(1.0 - 1.05e-10) / 0.055e-10 ≈ 1.818e11`, matching the reported
`array(1.81818182e+11)`. V1 instead injects the slice's true world value
(`1.05e-10 m`), making the offset term vanish and returning `(49.5, 12.0)`, which
matches the first two components of the unsliced `world_to_pixel`. The hint's
shorter assertion `np.allclose(out_pix[0], 0)` also holds.
**Verdict: behaviour is correct; no change needed.**

## F2 — The injected value is EXACT, not a "first-order approximation" (medium)

`reports/baseline_notes.md` hedged that evaluating the dropped world coordinate
at kept-pixel `= 0` is only exact "when the dropped world dim doesn't depend on
kept pixels," and otherwise a first-order approximation. Re-reading
`__init__` (lines 148-150) shows this hedge understates the guarantee:

```python
self._world_keep = np.nonzero(
    self._wcs.axis_correlation_matrix[:, self._pixel_keep].any(axis=1))[0]
```

A world axis is *kept* iff it correlates with at least one kept pixel axis.
Therefore a *dropped* world axis correlates with **no** kept pixel axis, and by
the `axis_correlation_matrix` API contract it is mathematically independent of
every kept pixel value. Its value is a function only of the integer-sliced
(dropped) pixel axes, which are pinned to the slice indices inside
`_pixel_to_world_values_all`. Hence evaluating at kept-pixel `[0, ...]` returns
the *exact* constant slice value; the choice of `0` is irrelevant.

Note the coupling that *causes* the bug (kept-world depends on dropped-pixel) is
the opposite direction from the coupling that would invalidate the `[0]`
evaluation (dropped-world depends on kept-pixel); the latter is structurally
impossible given how `_world_keep` is built. So V1 is exactly correct, not
approximate. **Verdict: keep the code; correct the wording in the notes.**

## F3 — Index/return-shape safety (`tuple` vs single array) — SAFE (medium)

`_pixel_to_world_values_all` returns `self._wcs.pixel_to_world_values(...)`,
which is a single array (not a tuple) when the underlying `world_n_dim == 1`.
The new code indexes `sliced_out_world_coords[iworld]` only inside the `else`
(dropped-axis) branch. That branch is reachable only when some world axis is
dropped, which requires `len(self._world_keep) >= 1` kept axis *plus* the
dropped one, i.e. underlying `world_n_dim >= 2`; otherwise `__init__` raises
`ValueError` (`len(self._world_keep) == 0`). When `world_n_dim >= 2`,
`pixel_to_world_values` returns a tuple of that length, so `[iworld]` for
`iworld in range(world_n_dim)` is always valid. The unconditional top-line
assignment is still fine when `world_n_dim == 1` because the result is simply
never indexed. **Verdict: safe; no change.**

## F4 — Robust to non-contiguous / reordered dropped world axes — SAFE (medium)

Indexing by the underlying world index `iworld` (rather than by a separate
dropped-axis counter into `dropped_world_dimensions["value"]`) means the fix is
correct even when the dropped world axis is not the last one — e.g. underlying
`world_keep = [0, 2]`, dropped `= [1]`. The loop then builds
`[user0, sliced_out_world_coords[1], user1]`, which is the correct ordering for
the underlying `world_to_pixel_values`. Using `iworld` directly is strictly more
robust than the alternative considered in V1. **Verdict: keep this approach.**

## F5 — No regression for the previously-working (uncoupled) case — SAFE (high)

When there is no kept-world/dropped-pixel coupling, the kept pixels do not depend
on the dropped world value, so replacing `1.` with the true slice value leaves
the kept-pixel outputs unchanged (and additionally makes the discarded dropped
pixel correct). Thus cases that already worked continue to work. **Verdict: no
regression.**

## F6 — Broadcasting and dtype — SAFE (low)

Old code mixed a Python float `1.` with array entries; new code mixes a 0-d
numpy array (`sliced_out_world_coords[iworld]`, since the inputs are scalar `0`s)
with the user's kept-world arrays. `np.broadcast_arrays` handles 0-d arrays and
scalars identically, so scalar and array world inputs both broadcast as before.
The length-0-array short-circuit further down is untouched. **Verdict: no
behavioural change in shape handling.**

## F7 — Performance: unconditional extra forward transform (low)

`sliced_out_world_coords` is computed on every call, including the "crop but drop
nothing" case (e.g. slicing `[10:20, :]`), where it is then unused. The cost is a
single *scalar-point* forward transform per call, independent of how many points
the caller passes, so for vectorised calls it is negligible relative to the
inverse transform on the real data, and for scalar calls it merely adds one cheap
transform. It is also recomputed rather than cached (unlike the
`@lazyproperty dropped_world_dimensions`). Considered guarding it behind
`if self.world_n_dim != self._wcs.world_n_dim:` and/or caching, but both add
state/branching for a marginal gain and a "conditionally-defined variable"
smell. **Verdict: accept the minor cost in favour of simplicity; document it.**

## F8 — Potential NaN if the slice maps outside a projection's valid domain (low)

If the dropped pixel slice index mapped to an invalid world value on the dropped
axis, `sliced_out_world_coords[iworld]` could be NaN, whereas the old `1.` was
always finite. In practice the dropped axis is decoupled from the kept pixels
(F2), so its value depends only on the valid integer slice index; for the common
dropped axes (spectral/stokes, linear) it is never NaN, and for the reported case
it is the exact wavelength. Crucially this introduces **no new failure mode**
relative to existing code: the `@lazyproperty dropped_world_dimensions` already
exposes this very value via the identical expression, so any such NaN would
already surface there. **Verdict: pre-existing, out of scope; no change.**

## F9 — Consistency with `dropped_world_dimensions` — GOOD (low)

V1 reuses the exact expression already used at line 161
(`self._pixel_to_world_values_all(*[0]*len(self._pixel_keep))`). The dropped
world value injected into the inverse transform is therefore guaranteed
consistent with the value the wrapper advertises for its dropped dimensions.
**Verdict: a strength; keep.**

## F10 — Maintainability: the change is subtle and easily "un-fixed" (low)

Replacing a literal `1.` with a computed slice coordinate is non-obvious; a
future reader could mistake it for redundancy and revert it to a constant,
silently reintroducing the bug. A one-line comment stating *why* the slice world
value is required (axis coupling) materially lowers that risk and matches the
file's existing inline-comment style (e.g. the comments inside
`pixel_to_world_values`). **Verdict: add a brief explanatory comment.**

## F11 — No other affected sites (informational)

Grep confirms `world_to_pixel_values` in `wrappers/sliced_wcs.py` was the only
location using the `1.` placeholder. `sliced_low_level_wcs.py` is a deprecation
re-export shim, and `BaseWCSWrapper.world_to_pixel_values` (base.py) is abstract.
No parallel implementation needs the same fix. **Verdict: scope is complete.**

---

## Summary of actions for V2
- F1, F3, F4, F5, F6, F8, F9: confirm V1 logic unchanged.
- F2, F7: correct/​document the reasoning (notes only).
- F10: add a single explanatory comment (no behavioural change).
