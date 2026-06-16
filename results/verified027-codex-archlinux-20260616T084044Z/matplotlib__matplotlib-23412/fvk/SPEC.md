# SPEC

Status: constructed for FVK audit; not machine-checked.

## Human-readable contract

For any visible patch drawn through `Patch.draw()` with a valid dash tuple
linestyle `(offset, onoffseq)`, positive dash cycle `C`, and positive linewidth
`LW`, the renderer graphics context must receive the dash offset stored in the
patch dash pattern:

- `normalized_offset = offset mod C`
- if `lines.scale_dashes` is true, `effective_offset = normalized_offset * LW`
- otherwise, `effective_offset = normalized_offset`
- `Patch.draw()` must call the draw helper in a way that forwards
  `effective_offset` to `gc.set_dashes`

In particular, when `normalized_offset != 0` and `LW > 0`, the forwarded offset
must not be `0`.

## Public intent ledger summary

- E1-E4 require patch dash tuple offsets to affect rendering and to match the
  `Line2D` convention.
- E5 requires the shared patch drawing path to be fixed so rectangle and ellipse
  patches are covered.
- E6 and E10 localize the pre-fix defect to the temporary zero-offset override
  inside `Patch.draw()`.
- E7 rejects a doc-only or warning-only interpretation.
- E8-E9 show that tuple offsets are already accepted and stored before drawing.

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal model

The K fragment is split into:

- `fvk/mini-patch-dash.k`: a reduced semantics for the relevant patch dash
  state transition.
- `fvk/patch-dash-spec.k`: reachability claims for setter ordering, draw
  forwarding, non-zero offset preservation, and the invisible-patch frame case.

The model keeps only the state needed to distinguish the bug:

- patch visibility;
- current linewidth;
- normalized unscaled dash offset;
- dash cycle length;
- stored scaled dash-pattern offset;
- renderer-observed dash offset and call count.

The detailed path geometry, transforms, hatches, clipping, facecolor, renderer
grouping, and backend rasterization are framed out because they do not influence
whether `Patch.draw()` forwards the stored dash offset or replaces it with zero.

## Preconditions

For the visual offset obligation:

- the patch is visible;
- the dash tuple has positive cycle length `C > 0`;
- the linewidth satisfies `LW > 0`;
- the normalized offset satisfies `(offset mod C) != 0`;
- the edge is drawable, meaning the linestyle is not `'None'` and the edge color
  is not fully transparent.

For the general forwarding obligation, `LW >= 0` is sufficient; a zero linewidth
still forwards the stored value but has no visible edge.

## Postconditions

1. After constructor-order setup (`set_linestyle` followed by `set_linewidth`)
   and `draw`, the renderer-observed dash offset equals
   `scaleOffset(scale_dashes, offset mod C, LW)`.
2. After post-init `set_linestyle` on a patch whose linewidth is already `LW`
   and then `draw`, the renderer-observed dash offset equals
   `scaleOffset(scale_dashes, offset mod C, LW)`.
3. Under the non-zero visual preconditions, the renderer-observed dash offset is
   non-zero.
4. If a patch is not visible, `draw` makes no `set_dashes` call. This preserves
   the existing visibility frame behavior.

## Adequacy discriminator

Concrete public issue instance, abstracted to the model:

- `offset = 10`, `C = 20`, `LW = 4`, `scale_dashes = true`
- expected forwarded offset: `(10 mod 20) * 4 = 40`
- pre-fix `Patch.draw()` behavior: forwarded offset `0`
- V1 behavior: forwarded offset `40`

The model distinguishes the failing and passing behaviors on the exact property
under audit, so the abstraction is property-complete for this issue.

## Code decision

V1 removes the only draw-time operation that overwrote `_dash_pattern[0]` with
`0`. The setter and scaling path already preserves offsets, and
`_bind_draw_path_function()` already passes `self._dash_pattern` to
`gc.set_dashes`. Therefore V1 satisfies the formal obligations and stands
unchanged.
