# Control notes: review outcome for astropy__astropy-13579

This documents the V2 decisions after a systematic review of the V1 fix. Every
decision is traced to a numbered finding in `review/FINDINGS.md`.

## Verdict

**V1's behavioural logic is correct and stands unchanged.** The only V2 code edit
is a non-behavioural explanatory comment. The accompanying reasoning in the notes
is strengthened where V1 under-claimed its own correctness.

## The fix (unchanged core)

In `astropy/wcs/wcsapi/wrappers/sliced_wcs.py`,
`SlicedLowLevelWCS.world_to_pixel_values` reconstructs the full set of world
coordinates needed by the underlying WCS's inverse transform. For world axes that
were sliced out, V1 injects the world value *at the slice location*
(`sliced_out_world_coords[iworld]`, from
`_pixel_to_world_values_all(*[0]*len(self._pixel_keep))`) instead of the original
hardcoded `1.`.

## Decisions, each traced to findings

1. **Keep the substituted-value approach as the fix.** (F1) Re-tracing the
   reported example confirms the kept spatial pixel `p1` depends on the spectral
   world value through the `PCij` coupling, and that the SI-unit placeholder `1.`
   (= 1 m vs. the true 1.05e-10 m) produces exactly the reported ~`1.818e11`
   error. Injecting the slice's true world value yields `(49.5, 12.0)` and
   satisfies the hint assertion. No change.

2. **Keep `[0]*len(self._pixel_keep)` as the evaluation point; do not seek a
   "more accurate" point.** (F2) The dropped world axis is, by construction of
   `_world_keep` (`axis_correlation_matrix[:, self._pixel_keep]`), independent of
   every kept pixel axis. So its value is a constant determined solely by the
   integer-sliced pixel indices, and evaluating at kept-pixel `= 0` returns that
   exact constant. The value is exact, not approximate — so there is nothing to
   improve here. (I corrected the over-cautious "first-order approximation"
   wording from `baseline_notes.md`; see "Notes correction" below.)

3. **Index the dropped value by the underlying world index `iworld`, not by a
   dropped-axis counter into `dropped_world_dimensions["value"]`.** (F4) Keeping
   V1's `sliced_out_world_coords[iworld]` is correct even when the dropped world
   axis is not last (non-contiguous `world_keep`). The rejected alternative would
   need an extra counter and is more error-prone. No change.

4. **Do not add a guard for the `tuple` vs single-array return shape.** (F3) The
   `else` branch that indexes `sliced_out_world_coords[iworld]` is only reachable
   when the underlying `world_n_dim >= 2` (a dropped axis plus at least one kept
   axis, else `__init__` raises). In that regime
   `_pixel_to_world_values_all` returns a tuple, so the index is always valid.
   The unconditional top-line assignment is harmless when `world_n_dim == 1`
   because it is never indexed. No defensive code needed.

5. **Do not guard or cache the extra forward transform.** (F7) Computing
   `sliced_out_world_coords` unconditionally costs a single scalar-point forward
   transform per call, even in the crop-without-drop case where it is unused.
   This is negligible for vectorised calls and cheap for scalar calls. Guarding
   it behind `self.world_n_dim != self._wcs.world_n_dim` or memoising it would add
   branching/state and a "conditionally-defined variable" smell for marginal
   benefit. Chose simplicity and consistency with the existing
   `_pixel_to_world_values_all`-based pattern; documented the trade-off rather
   than coding around it.

6. **Do not add NaN handling for out-of-domain slice indices.** (F8) Because the
   dropped axis is decoupled from kept pixels, its value depends only on a valid
   integer slice index and is finite for the realistic cases (notably the
   reported spectral axis). More importantly, the identical expression already
   backs the `dropped_world_dimensions` property, so this introduces no new
   failure mode. Out of scope; no change.

7. **Add a one-line explanatory comment above the substitution.** (F10) This is
   the sole V2 code edit. The `1.` → computed-value change is subtle and could be
   "simplified" back by a future maintainer, silently reintroducing the bug. The
   comment states *why* the slice world value is required (axis coupling via the
   `PCij` matrix) and matches the file's existing inline-comment style. It is
   purely explanatory — zero behavioural change, zero regression risk (F5, F6).

8. **No changes elsewhere.** (F11) Grep confirmed `world_to_pixel_values` in
   `wrappers/sliced_wcs.py` was the only site with the placeholder bug;
   `sliced_low_level_wcs.py` is a deprecation shim and
   `BaseWCSWrapper.world_to_pixel_values` is abstract. Scope is complete.

## Notes correction

`reports/baseline_notes.md` described the kept-pixel `= 0` evaluation as exact
only "when the dropped world dim doesn't depend on kept pixels," otherwise a
"first-order approximation." Per F2 this is stronger than V1 claimed: the
independence is *guaranteed* by how `_world_keep` is derived from the axis
correlation matrix, so the injected value is exact in all cases the wrapper
admits (assuming the underlying WCS reports its correlation matrix correctly,
which the class already relies on to choose the kept axes in the first place).
The earlier wording is therefore conservative but not wrong; this note supersedes
it.

## Net change in V2 vs V1
- Code: +1 explanatory comment block in `world_to_pixel_values`; logic identical.
- Docs: this file plus `review/FINDINGS.md`.
