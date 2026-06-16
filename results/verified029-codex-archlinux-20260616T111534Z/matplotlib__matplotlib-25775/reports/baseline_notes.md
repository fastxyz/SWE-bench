# Baseline Notes

## Root cause

`Text` did not have an artist-level antialiasing property. During drawing,
`Text.draw` created a graphics context with color, alpha, URL, and clipping
state, but never set antialiasing on that context. The AGG and Cairo text
renderers then read `rcParams["text.antialiased"]` directly when rasterizing
font glyphs, so every `Text` instance was tied to the global rcParam instead
of carrying the per-artist state that lines, patches, and collections expose.

AGG mathtext had the same issue one level deeper: raster math glyphs were
drawn in `_mathtext.Output.to_raster()` using the global rcParam, and the
mathtext parser cache did not include the antialiasing choice.

## Files changed

- `repo/lib/matplotlib/text.py`: Added `antialiased=None` to `Text`
  construction/reset, added `get_antialiased` and `set_antialiased`, added the
  `aa` alias, copied the property in `update_from`, and pushed the stored value
  into the graphics context before drawing text. `Annotation` inherits this
  behavior from `Text`, so no annotation-specific drawing change was needed.

- `repo/lib/matplotlib/text.pyi`: Exposed the new constructor keyword and
  getter/setter in the type stub.

- `repo/lib/matplotlib/backends/backend_agg.py`: Replaced normal text glyph
  rasterization's direct rcParam lookup with `gc.get_antialiased()`, and passed
  the same GC state through to AGG mathtext parsing.

- `repo/lib/matplotlib/mathtext.py`: Added an optional keyword-only
  `antialiased` argument for raster mathtext parsing. Existing callers that do
  not pass it still use `rcParams["text.antialiased"]`; raster cache keys now
  include the resolved antialiasing value.

- `repo/lib/matplotlib/mathtext.pyi`: Reflected the optional `antialiased`
  parser argument in the stub.

- `repo/lib/matplotlib/_mathtext.py`: Made raster math glyph rendering consume
  the antialiasing value supplied by `MathTextParser.parse`.

- `repo/lib/matplotlib/backends/backend_cairo.py`: Replaced Cairo text font
  option setup with GC-driven antialiasing, applied it to Cairo mathtext glyph
  drawing too, and made `GraphicsContextCairo.set_antialiased` update the base
  graphics context state so `gc.get_antialiased()` reports the current value.
  Cairo reuses one graphics context object, so `new_gc()` now also resets that
  antialiasing state to the base default.

## Assumptions and alternatives

- I treated `None` the same way other Matplotlib artist antialias setters do:
  it snapshots the corresponding rcParam at setter time rather than deferring
  lookup until draw time.

- I assumed per-artist antialiasing should affect normal text and Matplotlib
  mathtext in the AGG and Cairo paths because both are font-rendering paths
  mentioned by the issue hints.

- I did not try to make TeX image generation (`usetex=True`) per-artist
  antialiased. That path obtains a pre-rendered image from `TexManager`, so it
  is not the same backend font rasterization path as AGG/Cairo text glyph
  drawing and would require a broader TeX cache/API change.

- I did not modify tests or run tests/code, per the task constraints.
