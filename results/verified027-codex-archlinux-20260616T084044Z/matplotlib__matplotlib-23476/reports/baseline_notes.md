# Baseline Notes

## Root cause

High-DPI-capable canvases store the user's logical figure DPI in
`Figure._original_dpi`, then multiply `Figure._dpi` by the device pixel ratio
for rendering. `Figure.__getstate__` serialized the mutated `_dpi` value
directly. On unpickle, canvas initialization treated that already-scaled DPI as
the new original DPI, so a backend that reapplied a device pixel ratio doubled
the DPI again on each load.

## Files changed

`repo/lib/matplotlib/figure.py`

Updated `Figure.__getstate__` to serialize `_dpi` as `_original_dpi` when the
current canvas has a non-default device pixel ratio. This keeps the pickle
representation at the logical figure DPI for high-DPI canvases while preserving
ordinary user-requested DPI changes.

Updated `Figure.__setstate__` to resynchronize the DPI transform from the
restored `_dpi`, so figures unpickled from the normalized state have consistent
DPI-dependent transforms before any backend-specific canvas is attached.

## Assumptions and alternatives considered

I assumed `_original_dpi` is the intended canonical logical DPI for persistent
high-DPI canvas state because `FigureCanvasBase` sets it before applying a
device pixel ratio, and `print_figure(..., dpi="figure")` already uses it to
avoid leaking high-DPI canvas scaling into saved output.

I considered using `_original_dpi` unconditionally, but rejected that because
`_original_dpi` also exists on ordinary canvases and may differ from `_dpi`
after a user changes the figure DPI without any high-DPI scaling involved.

I considered changing macOS-specific canvas initialization, but the hint notes
that other high-DPI-aware backends can be affected too. Fixing figure
serialization is backend-neutral and directly addresses the persisted state.

I considered changing `Figure.__setstate__` to divide by the device pixel
ratio, but the relevant ratio is not reliably known from the pickle state and
would only be reapplied later by the selected backend. Normalizing during
`__getstate__` avoids encoding backend-specific runtime DPI in the pickle.
