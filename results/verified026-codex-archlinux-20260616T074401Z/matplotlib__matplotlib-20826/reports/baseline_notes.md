# Baseline Notes

## Root cause

`Axis.clear()` resets `_major_tick_kw` and `_minor_tick_kw`, which removes the
stored tick and tick-label visibility flags (`tick1On`, `tick2On`, `label1On`,
`label2On`). Those flags are where shared subplot label hiding and twin-axis
tick side placement are recorded. After the reset, newly created ticks fall back
to the `Tick` constructor defaults, where the second-side tick mark is visible.
Because the rcParam-derived tick side settings were only applied at the end of
`Axes.__init__`, a later `ax.clear()` did not restore the normal bottom/left
tick defaults and did not preserve the shared-axis hidden tick labels.

## Changed files

`repo/lib/matplotlib/axes/_base.py`

- Factored the existing rcParam tick-side setup into
  `_set_tick_params_from_rcparams()` so the same defaulting logic can be reused.
- Called that helper from `Axes.cla()` after the axes, patch, and grid state are
  rebuilt, ensuring a clear applies the rcParam tick side defaults to the reset
  tick state.
- Saved and restored only the tick/tick-label visibility flags across
  `Axis.clear()`. This keeps structural visibility state, such as shared-axis
  label suppression and twin-axis side placement, while still letting clear
  reset tick styling and grid state through the existing `Axis.clear()` path.

## Assumptions and alternatives

I assumed that tick side and tick-label side visibility is structural axes state
when it comes from shared subplots or twins, and should survive `Axes.clear()`.
I did not preserve broader tick styling such as size, color, padding, or grid
line properties because clearing should continue to reset those properties.

I considered re-running subplot `label_outer()` from `Axes.cla()`, but rejected
that because it would only address subplot sharing and could add new behavior to
manually shared subplots. Preserving the existing visibility flags is narrower
and also covers twins, which store their side placement in the same dictionaries.
