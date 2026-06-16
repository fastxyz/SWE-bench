# Public Compatibility Audit

Status: constructed from source inspection; no execution performed.

## Changed Public Symbols

`Figure.__getstate__(self)`

- Signature unchanged.
- Return shape remains a dictionary state suitable for pickle.
- Existing removals of `canvas` and `_cachedRenderer` behavior remain intact.
- New behavior only adjusts the `_dpi` entry when the current canvas has
  `device_pixel_ratio != 1`.
- Compatibility status: pass.

`Figure.__setstate__(self, state)`

- Signature unchanged.
- Input remains a pickle state dictionary.
- Existing version warning, base canvas reinitialization, and optional pyplot
  manager restoration remain intact.
- New behavior resynchronizes `dpi_scale_trans` from restored `_dpi` before
  base canvas attachment.
- Compatibility status: pass.

## Public Callsites and Overrides

Source search found no override signature changes and no new arguments passed
through virtual dispatch. The patch does not change `FigureCanvasBase` APIs or
backend-specific canvas APIs.

## Storage Compatibility

The pickle state still contains `_dpi` and `_original_dpi`; the patch changes
the value of `_dpi` for high-DPI live canvases so that it represents logical
DPI. This is the intended compatibility break from buggy serialized runtime
state and is directly required by the public issue.

Existing normal-ratio pickle behavior is preserved because the normalization is
guarded by `self.canvas.device_pixel_ratio != 1`.
