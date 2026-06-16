# FVK Spec: `Axes.clear()` Tick Visibility

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This audit covers the `Axes.clear()` / `Axes.cla()` tick-visibility behavior
needed for matplotlib issue `matplotlib__matplotlib-20826`.

Primary code units:

- `repo/lib/matplotlib/axes/_base.py::_AxesBase.cla`
- `repo/lib/matplotlib/axes/_base.py::_AxesBase._set_tick_params_from_rcparams`
- `repo/lib/matplotlib/axes/_subplots.py::SubplotBase._label_outer_xaxis`
- `repo/lib/matplotlib/axes/_subplots.py::SubplotBase._label_outer_yaxis`

Supporting implementation facts:

- `repo/lib/matplotlib/axis.py::Axis.clear` clears `_major_tick_kw` and
  `_minor_tick_kw`.
- `repo/lib/matplotlib/axis.py::Axis.set_tick_params` stores translated
  tick visibility in those dictionaries for future ticks.
- `repo/lib/matplotlib/gridspec.py::GridSpec.subplots` and
  `repo/lib/matplotlib/figure.py::Figure.subplot_mosaic` call
  `_label_outer_xaxis()` / `_label_outer_yaxis()` to hide redundant labels for
  shared subplots.

## Intent Spec

I1. For a normal axes, `ax.clear()` must leave tick side visibility at the
current rcParam-derived defaults, not at `Tick` constructor defaults.

I2. For shared subplots created through helpers that call `label_outer`, a later
`ax.clear()` must keep redundant shared-axis tick labels hidden.

I3. `ax.clear()` must not break axis sharing itself.

I4. The public hint says the regression came from clearing tick keyword
dictionaries and from applying tick rcParams at the end of `Axes.__init__`
rather than at `Axes.clear` / `Axis.clear`; therefore the fix must apply current
tick rcParams during clear.

I5. Public twin-axis methods create axes with structural opposite-side tick
placement. Clearing a twinned axes should not silently move its ticks back to
the ordinary side.

## Public Evidence Ledger

E1. Source: prompt.
Quote: "`ax.clear()` causes ticks and tick labels to be shown that should be
hidden."
Obligation: after clear, hidden shared-axis tick labels remain hidden.
Status: encoded by P2.

E2. Source: prompt.
Quote: "there are also ticks that appear along the top and right side of each
subplot which are not present ... The top and right-side ticks also appear when
not using multiple subplots."
Obligation: clear must not expose top/right ticks unless current rcParams or
structural axes state require them.
Status: encoded by P1 and P3.

E3. Source: prompt.
Quote: "If the `ax.clear()` call is removed, the plot ... appears identical to
the 3.4.1 plot."
Obligation: for the reproduction, clearing and plotting should preserve the
same shared-label and tick-side visibility as the no-clear path.
Status: encoded by P1 and P2.

E4. Source: public hint.
Quote: "Clearing the tick keyword dictionaries drops the settings for which
sides the ticks should be visible."
Obligation: the post-clear tick keyword dictionaries must contain the side
visibility settings required by the intended axes state.
Status: encoded by P1, P2, and P3.

E5. Source: public hint.
Quote: "tick `rcParams` are applied at the end of `Axes.__init__` instead of at
the end of `Axes.clear` or even `Axis.clear`."
Obligation: current tick rcParams must be applied during clear, not only during
initialization.
Status: encoded by P1; V1 violated this when rcParams changed after axes
creation.

E6. Source: implementation docs in `SubplotBase.label_outer`.
Quote: "Only show `outer` labels and tick labels."
Obligation: a subplot that has had outer-label suppression applied must reapply
that rule after clear rebuilds the axes.
Status: encoded by P2.

E7. Source: implementation docs in `Axes.twinx` / `Axes.twiny`.
Quote: twinned axes place the independent axis "opposite to the original one."
Obligation: for twinned axes, tick placement is structural state and should
survive clear.
Status: encoded by P3.

## Formal Model Summary

The mini model abstracts a real `Axes` object to the state needed for the issue:

- current rcParam tick visibility defaults `Rc`
- pre-clear tick keyword visibility `Saved`
- whether the axes is twinned `Twin`
- whether `_label_outer_xaxis` / `_label_outer_yaxis` had been called
- subplot position facts used by `label_outer`

The observable is the final major/minor tick visibility dictionaries after
`cla()` returns. Styling values such as size, color, padding, grid color, and
locator/formatter identity are out of this model because the public issue is
about tick and tick-label visibility.

## K Core

The constructed K files are:

- `fvk/mini-mpl-clear.k`
- `fvk/axes-clear-spec.k`

They are intentionally small state-transition models of the relevant
Matplotlib behavior rather than a full Python or full Matplotlib semantics.
They keep the property under verification observable: final tick/tick-label
side visibility.

To machine-check later, use:

```sh
kompile fvk/mini-mpl-clear.k --backend haskell
kast --backend haskell fvk/axes-clear-spec.k
kprove fvk/axes-clear-spec.k
```

Expected result after installing a compatible K toolchain: `#Top` for the
claims. These commands were not run in this session.
