# FVK Notes

## Decision summary

The FVK audit did not confirm V1 unchanged. It found that V1 fixed the reported
shared-label symptom but over-preserved rcParam-derived tick visibility. I
revised the fix to V2.

## Source changes from the FVK audit

`repo/lib/matplotlib/axes/_base.py`

- Kept `_set_tick_params_from_rcparams()` and the call from `Axes.cla()`.
  This discharges `fvk/PROOF_OBLIGATIONS.md` P1: clear must apply current tick
  rcParams, as required by `fvk/FINDINGS.md` F1.
- Narrowed tick visibility preservation so it applies only when the axes is in
  a twinned-axes group. This addresses F1 by preventing ordinary axes from
  restoring stale old rcParam visibility, while still discharging P3 for the
  twin-axis compatibility case in F3.
- Reapplied `_label_outer_xaxis()` and `_label_outer_yaxis()` after the rcParam
  reset when those helpers had previously been used. This discharges P2 and
  fixes the shared-subplot label hiding issue described in F2.

`repo/lib/matplotlib/axes/_subplots.py`

- Added private marker attributes in `_label_outer_xaxis()` and
  `_label_outer_yaxis()`. These markers let `Axes.cla()` distinguish known
  outer-label suppression from arbitrary old tick-label visibility. This is the
  implementation mechanism for F2/P2 and avoids the overbroad V1 behavior from
  F1.

## Decisions to keep unchanged

- I did not change `Axis.clear()`. The public hint allowed applying rcParams in
  either `Axes.clear` or `Axis.clear`; P1 is satisfied in `Axes.cla()` without
  changing the lower-level `Axis.clear()` contract for all axis users.
- I did not preserve non-visibility tick styling. P5 states that size, color,
  padding, grid styling, locators, formatters, units, and callbacks should
  continue through the existing clear reset path.
- I did not modify tests. The task forbids test edits and code execution.

## Verification artifacts

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The constructed K core is:

- `fvk/mini-mpl-clear.k`
- `fvk/axes-clear-spec.k`

The proof is constructed, not machine-checked. The emitted K commands in
`fvk/PROOF.md` were not run.
