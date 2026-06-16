# Baseline Notes

## Root Cause

`Tick.__init__` resolves `xtick.labelcolor` and `ytick.labelcolor` from
`rcParams`, falling back to `xtick.color` or `ytick.color` when the label color
is set to `"inherit"`.  `XAxis._init` and `YAxis._init` initialized
`offsetText` directly from `xtick.color` and `ytick.color`, bypassing the
label-color rcParam.  As a result, the scientific-notation offset/exponent text
kept the tick mark color even when tick labels were configured with a distinct
`*.labelcolor`.

## Changed Files

- `repo/lib/matplotlib/axis.py`: added `_get_tick_label_color()` to resolve the
  rcParam label color consistently, reused it for default tick label color
  initialization, and applied it to `XAxis` and `YAxis` offset text
  initialization.  This makes offset text use explicit `xtick.labelcolor` /
  `ytick.labelcolor`, while preserving the existing `"inherit"` fallback to the
  tick color.

## Assumptions and Rejected Alternatives

- I assumed the offset text should visually behave like tick labels because
  existing `Axis.set_tick_params()` already applies `labelcolor` changes to
  `offsetText`, and the issue report describes the offset/exponent as part of
  tick label coloring.
- I preserved `"inherit"` semantics instead of always using
  `*.labelcolor`, because the rcParam validator and existing tick label code
  define `"inherit"` as falling back to the corresponding `*.color`.
- I rejected changing test files because the task explicitly requires the test
  suite to remain fixed and hidden.
- I rejected changing formatter or draw-time offset handling because the bug is
  present at `offsetText` artist initialization, before formatter output is
  drawn.
