# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Code Change

Apply and keep the Cairo graphics-context copy fix from Finding F1 / PO-06:

- `GraphicsContextCairo.copy_properties` must synchronize the copied
  `_antialiased` value into the cairo context.
- `GraphicsContextCairo.set_antialiased` and `RendererCairo.new_gc` should use
  the same `_set_antialias` path so Python GC state and cairo context state do
  not diverge.

This has been applied in V2.

## V1 Changes Confirmed

Keep the V1 `Text` API and draw changes:

- `antialiased=None` in `Text.__init__` and `_reset_visual_defaults`.
- `get_antialiased` / `set_antialiased` and `aa` alias.
- `Text.draw` calls `gc.set_antialiased(self._antialiased)`.
- `Text.update_from` copies `_antialiased`.
- `text.pyi` exposes the new API.

These discharge PO-01 through PO-03 and PO-07.

Keep the V1 AGG/mathtext changes:

- AGG normal text uses `gc.get_antialiased()`.
- AGG raster mathtext accepts a GC-derived parser keyword.
- `_mathtext.Output.to_raster` consumes that keyword.
- Existing parser calls without the keyword preserve rcParam behavior.

These discharge PO-04, PO-05, and PO-08.

Keep the V1 Cairo font-option changes:

- Cairo normal text and mathtext call `_set_font_options(ctx, gc)`.

Together with the V2 copy fix, this discharges PO-06.

## Do Not Change in This Iteration

- Do not modify tests; the benchmark task forbids it.
- Do not run tests, Python, `kompile`, or `kprove`; no execution environment is
  available.
- Do not attempt to retrofit TeX image generation for per-artist AA without a
  separate public-intent requirement. It is documented as Finding F2 / PO-09.

## Future Verification Work

If a maintainer wants machine-checked confidence later, run the commands in
`fvk/PROOF.md` after installing K. If those commands do not return `#Top`, use
the failed claim names to refine `mini-matplotlib-text.k` or the source.

If future public requirements extend per-artist AA to additional backends or
TeX image generation, add new proof obligations rather than broadening the
current claims silently.
