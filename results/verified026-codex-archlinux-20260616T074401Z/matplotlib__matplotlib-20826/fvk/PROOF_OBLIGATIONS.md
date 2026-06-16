# Proof Obligations

Status: constructed, not machine-checked.

## P1 - Current rcParam tick defaults are applied during `Axes.cla`

Given a non-twinned axes with no prior outer-label marker, after `cla()` returns:

- major x tick side visibility equals
  `xtick.top && xtick.major.top` for `top`,
  `xtick.bottom && xtick.major.bottom` for `bottom`,
  `xtick.labeltop && xtick.major.top` for `labeltop`, and
  `xtick.labelbottom && xtick.major.bottom` for `labelbottom`;
- minor x tick visibility uses the corresponding `xtick.minor.*` rcParams;
- major and minor y tick visibility follow the analogous `ytick.*` rcParams.

This obligation rejects V1's stale preservation of old rc-derived visibility.

Findings: F1.

## P2 - Previously applied `label_outer` rules are re-applied after clear

If `_label_outer_xaxis()` had been applied before `cla()`, then after the
post-clear rcParam reset:

- if the subplot is not in the first row, top x tick labels are hidden;
- if the subplot is not in the last row, bottom x tick labels are hidden;
- matching x offset text is hidden when it belongs to the hidden side.

If `_label_outer_yaxis()` had been applied before `cla()`, then after the
post-clear rcParam reset:

- if the subplot is not in the first column, left y tick labels are hidden;
- if the subplot is not in the last column, right y tick labels are hidden;
- matching y offset text is hidden when it belongs to the hidden side.

Findings: F2.

## P3 - Twinned axes preserve structural tick placement

If an axes belongs to `_twinned_axes` before `cla()`, then after the post-clear
rcParam reset, its pre-clear values for `tick1On`, `tick2On`, `label1On`, and
`label2On` are restored for both major and minor x and y ticks.

This is intentionally narrower than V1: ordinary axes do not get this restore,
so ordinary axes can follow current rcParams.

Findings: F1, F3.

## P4 - Public compatibility is preserved

The patch must not change public method signatures, return values, or virtual
dispatch protocols. It may add private marker attributes on subplot instances
and a private helper on `_AxesBase`.

Checked public-facing symbols:

- `Axes.clear()` and `Axes.cla()` signatures unchanged.
- `Axes.tick_params()` and `Axis.set_tick_params()` signatures unchanged.
- `SubplotBase.label_outer()` signature unchanged.
- `_label_outer_xaxis()` and `_label_outer_yaxis()` are private helpers, still
  called with no arguments by existing in-repo callsites.

Findings: F3.

## P5 - Tick styling still resets

Only visibility keys are restored, and only for twinned axes. Non-visibility
styling such as size, width, color, padding, label color, grid line styling,
locators, formatters, units, and callbacks continues through the existing clear
path and is not preserved by this patch.

Findings: F1.
