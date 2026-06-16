# FVK Notes

## Decisions

V2 changes `repo/lib/matplotlib/backends/backend_cairo.py` beyond V1. The FVK
audit found that Cairo path-effect text could lose the copied antialiasing
state at the cairo-context level: `GraphicsContextBase.copy_properties` copied
the Python `_antialiased` flag, but V1 did not apply that value to
`ctx.set_antialias(...)`. This is Finding F1 and proof obligation PO-06. I
fixed it by adding `GraphicsContextCairo.copy_properties`, factoring
`_set_antialias`, and using that helper from `set_antialiased`. This keeps
copied GCs aligned with the cairo context for text path-effect drawing.

The rest of V1 stands. The `Text` API additions and draw-stage GC transfer are
kept because they discharge PO-01, PO-02, PO-03, and PO-07. The AGG and raster
mathtext changes are kept because they discharge PO-04, PO-05, and PO-08:
normal text and mathtext now consume `gc.get_antialiased()`, while existing
parser calls still default to `rcParams["text.antialiased"]`.

I did not extend per-artist antialiasing to TeX image generation. Finding F2
and PO-09 classify that as outside the public issue evidence: the inspected TeX
path uses a pre-rendered `TexManager` image and did not contain the direct
`rcParams["text.antialiased"]` backend lookup the issue asks to replace.

No tests, Python, or K tooling were run. The proof in `fvk/PROOF.md` is
constructed, not machine-checked, and Finding F4 records that constraint.
