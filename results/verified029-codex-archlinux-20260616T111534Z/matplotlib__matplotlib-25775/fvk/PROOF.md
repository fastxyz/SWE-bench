# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Machine-Check Commands Not Run

The commands to machine-check this proof later are:

```sh
kompile fvk/mini-matplotlib-text.k --backend haskell
kast --backend haskell fvk/matplotlib-text-antialias-spec.k
kprove fvk/matplotlib-text-antialias-spec.k --definition mini-matplotlib-text-kompiled
```

Expected machine-check result if the mini semantics and claims parse as written:
`#Top` for all claims in `matplotlib-text-antialias-spec.k`.

## Adequacy Gate

The intent-only obligations in `fvk/SPEC.md` are I1 through I7. The formal
English clauses FE-01 through FE-09 are claim paraphrases. The `SPEC.md` audit
marks each formal clause as matching public intent or a named source-code
dispatch fact. The only V1 mismatch was FE-08 / PO-06, recorded as Finding F1
and fixed in V2.

No claim depends on hidden tests, upstream patches, evaluator output, or
executed behavior.

## Proof Sketch

### PO-01: Text Initialization

For `initText(ARG, RC)`, the mini semantics rewrites
`<textAA> _ </textAA>` to `resolveAA(ARG, RC)`.

Cases:

- `ARG = NoneAA`: `resolveAA(NoneAA, RC) => RC`.
- `ARG = AA(B)`: `resolveAA(AA(B), RC) => B`.

This matches `Text._reset_visual_defaults(..., antialiased=...)` calling
`set_antialiased`, whose `None` branch reads `mpl.rcParams["text.antialiased"]`
and whose explicit branch stores the supplied value.

### PO-02: Setter/Getter

For `setTextAA(AA(B), RC)`, the same rewrite stores `B`. The getter has no
branching behavior: it returns the stored `_antialiased` field. Therefore, after
the setter claim reaches the post-state, `get_antialiased()` observes `B`.

### PO-03: Text Draw to GraphicsContext

For `drawText(BACKEND)`, the mini semantics reads `<textAA> B </textAA>` and
rewrites both `<gcAA>` and the backend observation for `BACKEND` to `B`.

The source has the corresponding sequence: `Text.draw` creates a GC, sets the
existing color/alpha/URL/clip properties, then calls
`gc.set_antialiased(self._antialiased)` before dispatching to
`draw_text`/`draw_tex`. Because `GraphicsContextBase.set_antialiased` stores a
boolean/int value in `_antialiased`, the backend receives the Text object's AA
state through the GC.

### PO-04: AGG Normal Text

Instantiate `drawText(BACKEND)` with `BACKEND = AggNormal`. The post-state
contains `backendAA[AggNormal] = B`.

The source-level consumption point is `RendererAgg.draw_text`, where
`font.draw_glyphs_to_bitmap(antialiased=gc.get_antialiased())` passes the GC AA
value to FT2 glyph rasterization. The direct rcParam read present before V1 is
removed from this path.

### PO-05: AGG Raster Mathtext

Instantiate `drawText(BACKEND)` with `BACKEND = AggMath`. The post-state
contains `backendAA[AggMath] = B`.

The source-level chain is:

1. `RendererAgg.draw_mathtext` calls
   `self.mathtext_parser.parse(..., antialiased=gc.get_antialiased())`.
2. `MathTextParser.parse` resolves the raster AA value and includes it in the
   `_parse_cached` key.
3. `_mathtext.Output.to_raster(antialiased=...)` passes that value to
   `draw_glyph_to_bitmap`.

Thus the glyph image and cache entry are functions of the per-Text GC AA state.

### PO-06: Cairo Text and Cairo GC Copy

For `drawText(CairoText)` and `drawText(CairoMath)`, the backend observation is
the GC AA value `B`.

The source-level consumption point is `_set_font_options(ctx, gc)`, which sets
cairo font antialiasing from `gc.get_antialiased()`. It is called from both
normal Cairo text and Cairo mathtext before `ctx.show_text`.

For `copyCairoGC`, the mini semantics rewrites `<copiedGcAA>` and
`backendAA[CairoPathEffectCopy]` to the source `<gcAA> B`. V2 implements this
by overriding `GraphicsContextCairo.copy_properties`: after the base Python
fields are copied, `_set_antialias()` applies the copied `_antialiased` value to
the cairo context. This discharges Finding F1.

### PO-07: Annotation

`drawAnnotation(BACKEND)` rewrites to `drawText(BACKEND)` in the mini
semantics. The source mirrors this: `Annotation.draw` updates annotation and
arrow positions, draws the arrow if present, and delegates final text rendering
to `Text.draw(self, renderer)`. Therefore the Text AA proof applies unchanged.

### PO-08: Public Compatibility

For `parseRasterMath(NoneAA, RC)`, the mini semantics records `AggMath <- RC`.
For `parseRasterMath(AA(B), RC)`, it records `AggMath <- B`.

The source matches this split: existing parser calls that omit `antialiased`
pass `None`, which resolves to `mpl.rcParams["text.antialiased"]`; Text drawing
passes an explicit GC-derived value.

### PO-09: Frame and Scope

The proof abstracts color, alpha, URL, clipping, layout, text content, and TeX
image generation because the issue does not require changing them. Source
inspection shows those pre-existing `Text.draw` assignments remain in place and
the backend edits are localized to antialiasing consumption.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini-K semantics is an abstraction of the relevant Matplotlib dispatch
  slice, not a full Python or full Matplotlib semantics.
- Termination is not at issue: the audited operations are straight-line
  setters and dispatch transitions.
- TeX image generation is out of scope for this issue and remains unproved for
  per-artist AA.

## Test Recommendation

No tests were run or modified. No test removal is recommended in this benchmark
setting. If a future maintainer machine-checks the K claims, focused tests that
only assert in-domain Text AA propagation through AGG/Cairo could be considered
subsumed by the proof, but integration/image-comparison tests should be kept.
