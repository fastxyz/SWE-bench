# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent and source inspection only.

## F1 - V1 over-preserved tick visibility and could ignore current rcParams

Classification: code bug in V1, fixed in V2.

Evidence:

- Public hint E5 says tick rcParams should be applied at clear time.
- V1 saved `tick1On`, `tick2On`, `label1On`, and `label2On` for every axes
  before `Axis.clear()`, applied rcParams, then restored the saved values.

Concrete scenario:

- Input/state: create a normal axes while `xtick.top` is false; later enter an
  rc context where `xtick.top` is true and call `ax.clear()`.
- V1 observed-by-inspection: the saved old `tick2On=False` would be restored
  after applying current rcParams, so top ticks would remain hidden.
- Expected from public hint: clear should apply current tick rcParams, so top
  ticks should be visible in that rc context.

Resolution:

- V2 no longer preserves generic tick visibility for normal axes.
- `_set_tick_params_from_rcparams()` runs during `cla()`, and regular axes keep
  those current rcParam-derived values.

Related proof obligations: P1, P5.

## F2 - Shared-subplot label hiding must be re-established after `Axis.clear`

Classification: code bug in pre-fix behavior and incomplete V1 rationale;
fixed in V2.

Evidence:

- Public issue E1 requires shared-axis tick labels that were hidden before
  clear to remain hidden after clear.
- `Axis.clear()` resets the keyword dictionaries that store `label1On` and
  `label2On`.
- `GridSpec.subplots` and `Figure.subplot_mosaic` call the subplot
  `_label_outer_*` helpers to hide redundant labels after creation.

Concrete scenario:

- Input/state: `plt.subplots(2, 2, sharex=True, sharey=True)` creates a grid and
  calls `_label_outer_xaxis()` / `_label_outer_yaxis()` on appropriate axes.
- Pre-fix observed-by-inspection: `ax.clear()` invokes `Axis.clear()`, drops the
  `label*On=False` settings, and no later code reapplies `label_outer`.
- Expected: the same redundant shared labels remain hidden after clear.

Resolution:

- V2 records that a subplot had `_label_outer_xaxis()` or `_label_outer_yaxis()`
  applied, then `Axes.cla()` reapplies those helpers after rcParam tick defaults
  are restored.

Related proof obligations: P2.

## F3 - Twin-axis tick side placement is structural state

Classification: compatibility risk found during audit, fixed in V2.

Evidence:

- `Axes.twinx()` and `Axes.twiny()` explicitly move ticks to the opposite side
  for the twin axes.
- Those moves are also represented in `_major_tick_kw` and `_minor_tick_kw`,
  so `Axis.clear()` can drop them.

Concrete scenario:

- Input/state: `ax2 = ax.twinx()` creates a twin with the independent y-axis on
  the right.
- Pre-fix observed-by-inspection: a later `ax2.clear()` would reset y tick
  visibility to ordinary rc defaults unless the structural placement is saved.
- Expected from public twin-axis docs: the independent y-axis stays positioned
  opposite to the original axes.

Resolution:

- V2 preserves the four visibility keys only for axes that are members of a
  twinned-axes group.

Related proof obligations: P3, P4.

## Residual Findings

No unresolved code-change finding remains in the audited scope. Residual risk
is proof-process risk only: the K proof is constructed but not machine-checked,
and no tests were run by instruction.
