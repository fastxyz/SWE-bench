# Public Compatibility Audit

Status: no public API compatibility break found.

## Changed symbols

- `seaborn._core.plot.Plotter._finalize_figure`: internal method body changed,
  signature unchanged.
- `seaborn._core.plot.Plotter._nominal_axis_length`: new internal helper,
  private by naming convention.
- `seaborn._core.plot` import list: imports `Nominal` from an existing internal
  module; no public API change.

## Call sites and overrides

- Public call surface (`Plot.plot`, `Plot.save`, `Plot.show`) is unchanged.
- `_finalize_figure` is called internally from `Plot._plot`; no call signature
  changed.
- No subclass or override of `Plotter._finalize_figure` appears in source under
  `repo/`.
- The helper is not part of the public `seaborn.objects` namespace.

## Compatibility result

The V1 fix changes rendered axis state for nominal coordinate scales, which is
the intended behavioral fix. It does not require public caller changes and does
not alter test helper signatures or producer/consumer data shapes.
