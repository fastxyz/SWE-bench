# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Text AA Initialization Defaults

Claim names: `initText(NoneAA, RC)`, `initText(AA(B), RC)`.

Obligation: constructing or resetting `Text` with `antialiased=None` stores the
current `rcParams["text.antialiased"]`; constructing or resetting with an
explicit boolean stores that boolean.

Evidence: E1, E2, E7.

Code witness: `Text.__init__` forwards `antialiased` to
`_reset_visual_defaults`; `_reset_visual_defaults` calls
`self.set_antialiased(antialiased)`; `set_antialiased(None)` reads
`mpl.rcParams["text.antialiased"]`.

Status: discharged by inspection and K claim construction.

## PO-02: Text Setter/Getter

Claim name: `setTextAA(AA(B), RC)`.

Obligation: `set_antialiased(B)` updates the stored value; `get_antialiased()`
returns that stored value.

Evidence: E1, E2.

Code witness: `Text.set_antialiased` assigns `self._antialiased`; 
`Text.get_antialiased` returns `self._antialiased`.

Status: discharged by inspection and K claim construction.

## PO-03: Text Draw Transfers AA to GC

Claim name: `drawText(BACKEND)`.

Obligation: before backend text rendering, `Text.draw` must set the graphics
context's AA state from the `Text` object's stored AA state.

Evidence: E3, E5.

Code witness: `Text.draw` calls `gc.set_antialiased(self._antialiased)` after
setting color/alpha/URL and before `draw_text`/`draw_tex` dispatch.

Status: discharged by inspection and K claim construction.

## PO-04: AGG Normal Text Consumes GC AA

Claim name: `drawText(AggNormal)`.

Obligation: AGG normal text glyph rasterization must call the FT2 glyph bitmap
renderer with `gc.get_antialiased()`.

Evidence: E5, E6.

Code witness: `RendererAgg.draw_text` calls
`font.draw_glyphs_to_bitmap(antialiased=gc.get_antialiased())`.

Status: discharged by inspection and K claim construction.

## PO-05: AGG Raster Mathtext Consumes GC AA

Claim names: `drawText(AggMath)`, `parseRasterMath(AA(B), RC)`.

Obligation: AGG mathtext raster glyphs must be generated with the same
GC-derived AA value as normal text, and the raster cache must distinguish AA
choices.

Evidence: E5, E6.

Code witness: `RendererAgg.draw_mathtext` passes
`antialiased=gc.get_antialiased()` to `MathTextParser.parse`;
`MathTextParser.parse` includes the resolved AA value in `_parse_cached`;
`_mathtext.Output.to_raster` passes the supplied AA value to
`draw_glyph_to_bitmap`.

Status: discharged by inspection and K claim construction.

## PO-06: Cairo Text and Cairo GC Copy Consume GC AA

Claim names: `drawText(CairoText)`, `drawText(CairoMath)`, `copyCairoGC`.

Obligation: Cairo normal text and Cairo mathtext must set cairo font options
from `gc.get_antialiased()`. When a Cairo graphics context is copied, the cairo
context must also receive the copied AA value so path-effect text rendering does
not fall back to default antialiasing.

Evidence: E5, E6, E9.

Code witness: `_set_font_options(ctx, gc)` uses `gc.get_antialiased()` and is
called from Cairo normal text and mathtext paths. `GraphicsContextCairo` now
calls `super().set_antialiased`, uses `_set_antialias()` for the cairo context,
resets default AA in `new_gc`, and synchronizes AA in `copy_properties`.

Status: discharged after V2 edit; V1 had Finding F1.

## PO-07: Annotation Inherits Text AA

Claim name: `drawAnnotation(BACKEND)`.

Obligation: annotation text must observe the same AA state as Text.

Evidence: E4, E8.

Code witness: `Annotation` inherits `Text`; its final draw step calls
`Text.draw(self, renderer)`.

Status: discharged by inspection and K claim construction.

## PO-08: Public Compatibility

Claim name: `parseRasterMath(NoneAA, RC)`.

Obligation: existing parser calls without an AA keyword preserve rcParam
behavior; changed APIs remain source-compatible.

Evidence: E10 and compatibility audit in `SPEC.md`.

Code witness: `MathTextParser.parse(..., *, antialiased=None)` preserves all
existing positional arguments; for raster output, `None` resolves to
`mpl.rcParams['text.antialiased']`. `Text.__init__` still accepts `**kwargs`.

Status: discharged by inspection and K claim construction.

## PO-09: Frame and Scope

Obligation: the fix should not change color, alpha, URL, clipping, layout, or
text content semantics; TeX image generation is not claimed to be controlled by
per-artist AA.

Evidence: issue scope and baseline source inspection.

Code witness: `Text.draw` still sets color, alpha, URL, and clipping as before,
with only the AA setter added. Backend edits are localized to font AA
consumption. No TeX-manager code was changed.

Status: frame condition accepted; TeX noted as residual out-of-scope risk in
Finding F2.
