# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`matplotlib.legend.Legend.__init__`

V1 changed the parent type check from concrete `Figure` to `FigureBase`.

## Public Callsites

`Axes.legend()`:

- Source path: `repo/lib/matplotlib/axes/_axes.py`
- Parent passed to `Legend`: `self`, an `Axes`
- Compatibility result: pass.  The axes branch is unchanged and precedes the
  `FigureBase` branch.

`FigureBase.legend()`:

- Source path: `repo/lib/matplotlib/figure.py`
- Parent passed to `Legend`: `self`
- Compatibility result: pass.  Concrete `Figure` remains accepted, and
  `SubFigure` becomes accepted as required by public intent.

Direct `Legend(...)` calls:

- Source audit found no additional production direct constructor paths beyond
  axes and figure legend helpers.
- Compatibility result: invalid arbitrary parents still raise `TypeError`.

## Subclasses and Overrides

`FigureBase` subclasses in source:

- `Figure`
- `SubFigure`

No other `FigureBase` subclasses or public overrides of the audited legend
construction path were found in source.  There is no signature change.

## Result

No unhandled public callsite, subclass override, return-shape change, or
producer/consumer protocol change blocks V1.
