# FVK Findings

Status: constructed, not machine-checked. Findings are from static reasoning
over public intent and source code only.

## F1: Cairo Path-Effect Text Could Ignore Copied Text AA in V1

Classification: code bug in V1; fixed in V2.

Input scenario: a Cairo-rendered `Text` or `Annotation` with
`antialiased=False` and a text path effect that copies the graphics context,
for example a stroke-like path effect.

Observed in V1 by source reasoning:

- `Text.draw` set the original GC's `_antialiased` to `False`.
- `PathEffectRenderer`/path effects create a fresh Cairo GC via `new_gc()`.
- V1 `RendererCairo.new_gc()` reset the cairo context AA to default/true.
- `GraphicsContextBase.copy_properties(gc)` copied the Python `_antialiased`
  flag to false, but Cairo had no `copy_properties` override to apply that
  copied value to `ctx.set_antialias(...)`.
- The copied Cairo context could therefore draw the path-effect text with
  default antialiasing even though the copied GC field said false.

Expected from intent: every text drawing route that consumes a GC for AGG/Cairo
font/text rendering should observe the Text object's per-artist AA value.

Fix applied: `GraphicsContextCairo.copy_properties` now calls
`super().copy_properties(gc)` and then synchronizes the cairo context through
`self._set_antialias()`. `set_antialiased` and `new_gc` share the same helper.

Proof trace: PO-06, K claim `copyCairoGC`.

## F2: TeX Image Generation Is Not Proven Per-Artist AA

Classification: residual scope boundary, not a V2 code bug.

Input scenario: `Text(..., usetex=True, antialiased=False)` rendered through
AGG's TeX image path.

Observed by source reasoning: `RendererAgg.draw_tex` obtains a pre-rendered
grayscale image from `TexManager.get_grey(...)` and passes that image to
`draw_text_image`. The inspected TeX path does not read
`rcParams["text.antialiased"]`, so V1/V2 did not replace any rcParam lookup
there.

Expected from public intent: the issue specifically identifies replacement of
direct `rcParams["text.antialiased"]` reads and public hints name AGG/Cairo
font-antialiasing support. The TeX image path is not one of those direct
rcParam font-rendering paths.

Decision: no code change. The FVK spec explicitly does not claim TeX image
generation is controlled by per-artist AA. A broader TeX cache/API design would
need separate intent.

Proof trace: PO-09.

## F3: Public Compatibility of `MathTextParser.parse` Is Preserved

Classification: compatibility audit result; no code change.

Input scenario: existing callsites such as
`mathtext_parser.parse(s, dpi, prop)`.

Observed in V2 by source reasoning: the new `antialiased` parameter is
keyword-only and defaults to `None`; existing positional callsites keep the
same arity. For raster parsers, `None` resolves to
`rcParams["text.antialiased"]`, preserving pre-existing public behavior outside
Text drawing.

Expected from intent: adding per-Text AA must not break unrelated public
mathtext parser users.

Decision: keep the V1 parser API shape.

Proof trace: PO-08, K claim `parseRasterMath(NoneAA, RC)`.

## F4: No Hidden or Executed Evidence Was Used

Classification: methodology constraint.

Input scenario: any conclusion requiring hidden tests, benchmark result files,
Python execution, or K tool execution.

Observed: no such evidence is available or allowed.

Expected: conclusions must trace to public issue text, source, and constructed
FVK obligations only.

Decision: proof remains labeled constructed, not machine-checked; all test
removal recommendations are withheld.

Proof trace: all proof obligations.
