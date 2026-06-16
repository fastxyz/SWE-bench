# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Scope

This FVK pass audits the V1 fix for the public issue
`matplotlib__matplotlib-23412`: dash tuple offsets on patch edges were accepted
by the API but ignored during rendering. The formal target is the observable
path from a patch linestyle tuple through the stored dash pattern to the
graphics context call made by `Patch.draw()`.

The audited source units are:

- `matplotlib.lines._get_dash_pattern`
- `matplotlib.lines._scale_dashes`
- `matplotlib.patches.Patch.set_linestyle`
- `matplotlib.patches.Patch.set_linewidth`
- `matplotlib.patches.Patch._bind_draw_path_function`
- `matplotlib.patches.Patch.draw`

## Required behavior from public intent

1. A patch linestyle tuple `(offset, onoffseq)` is an in-domain patch linestyle
   value when `onoffseq` is a valid dash sequence with positive cycle length.
2. For visible patch edges, a non-zero tuple offset must affect the rendered
   edge dash phase. Two otherwise identical patches with the same dash sequence
   and different offsets should not be forced to overlap because the offset was
   discarded.
3. Patch dash tuple offsets should follow the same storage and renderer
   convention as `Line2D`: parse the tuple, normalize the offset modulo the dash
   cycle, scale by linewidth when `lines.scale_dashes` is enabled, and pass the
   resulting dash pattern to `gc.set_dashes`.
4. `Patch.draw()` must not replace a stored non-zero dash offset with `0`.
5. The fix must preserve unrelated patch behavior: visibility checks, path
   transformation, facecolor handling, hatching, clipping, linewidth decisions,
   renderer grouping, and public method signatures.
6. No warning or compatibility shim is required for code that explicitly passed
   a non-zero offset but relied on patches ignoring it; the public issue frames
   that behavior as the bug.

## Domain and assumptions

- The visual-effect obligation applies to visible patches with a drawable edge:
  `visible == True`, linestyle not `'None'`, non-transparent edge color, valid
  dash sequence, and positive linewidth.
- The lower-level graphics context and backends are assumed to implement
  `set_dashes(offset, dash_list)` according to their public contract. This FVK
  pass proves that the correct offset is forwarded to that contract, not the
  backend's pixel-level dash rasterization.
- The model treats the dash sequence by its positive cycle length. This is
  property-complete for the audited bug because the failing and passing cases
  differ in the offset value passed to `gc.set_dashes`, not in the detailed dash
  list geometry.
- Termination is trivial for the audited straight-line fragment and is not a
  separate proof target.
