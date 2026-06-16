# Proof Obligations

Status: constructed for FVK audit; not machine-checked.

## PO-1: Adequate intent provenance

Every formal claim about dash-offset forwarding must trace to public intent, not
to the current implementation alone.

Discharge: E1-E8 provide public-intent support. E10 is marked SUSPECT legacy
behavior and rejected.

## PO-2: Property-complete model

The mini model must represent the property that failed: whether the renderer
receives the user's dash offset or zero.

Discharge: `mini-patch-dash.k` records `rendererDashOffset`. The discriminator
case `O=10`, `C=20`, `LW=4`, `SCALE=true` maps pre-fix behavior to `0` and V1
behavior to `40`, so the model distinguishes fail from pass.

## PO-3: Setter and linewidth storage

After a tuple linestyle and linewidth are applied, the patch's stored dash
pattern offset must equal `scaleOffset(SCALE, O mod C, LW)`.

Discharge: `setLinestyleTuple` models `_get_dash_pattern` normalization and
immediate scaling; `setLinewidth` models rescaling `_unscaled_dash_pattern`.

## PO-4: Draw forwarding

`Patch.draw()` must enter `_bind_draw_path_function()` without replacing the
stored dash-pattern offset.

Discharge: V1 changes `Patch.draw()` from the pre-fix temporary override
`_dash_pattern=(0, self._dash_pattern[1])` to a direct
`with self._bind_draw_path_function(renderer) as draw_path:` call.

## PO-5: Non-zero offset preservation

For a visible, drawable patch edge with `LW > 0` and `(O mod C) != 0`, the
renderer-observed dash offset must be non-zero.

Discharge: Claim 3 in `patch-dash-spec.k`; arithmetic side conditions are
`C > 0`, `LW > 0`, and `(O mod C) != 0`.

## PO-6: Frame conditions

The fix must not alter unrelated draw behavior: invisible patches still do
nothing, public signatures remain unchanged, and path/face/hatch/clip handling
is outside the dash-offset transition.

Discharge: Claim 4 covers invisible draw behavior; compatibility audit records
no signature or dispatch-shape change.

## PO-7: Honesty gate

The proof must be labeled constructed, not machine-checked, and no tests may be
removed or treated as redundant without running the emitted K commands later.

Discharge: `PROOF.md` contains the commands and the caveat. This benchmark phase
does not run `kompile`, `kast`, `kprove`, tests, Python, or backend rendering.
