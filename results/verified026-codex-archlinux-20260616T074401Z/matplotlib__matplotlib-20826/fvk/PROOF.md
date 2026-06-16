# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims

The constructed claims are in `fvk/axes-clear-spec.k` over the transition
semantics in `fvk/mini-mpl-clear.k`.

Main claims:

- `CLAIM-RC-CLEAR`: proves P1 for ordinary axes.
- `CLAIM-LABEL-OUTER-X`: proves the x-axis part of P2.
- `CLAIM-LABEL-OUTER-Y`: proves the y-axis part of P2.
- `CLAIM-TWIN-PRESERVE`: proves P3.
- `CLAIM-NO-STYLE-FRAME`: proves P5 as a frame condition.

## Symbolic Proof Sketch

Initial state abbreviations:

- `Rc` is the current rcParam visibility defaults at clear time.
- `Saved` is the pre-clear tick visibility dictionary.
- `Twin` says the axes belongs to `_twinned_axes`.
- `LOX` / `LOY` say `_label_outer_xaxis()` / `_label_outer_yaxis()` had been
  applied before clear.

Execution of the relevant `cla()` fragment:

1. `cla()` saves axis and patch visibility. This is framed out of the tick
   visibility proof.
2. If `Twin` is true, `cla()` saves the four visibility keys from major and
   minor x and y tick keyword dictionaries. If `Twin` is false, no generic tick
   visibility restore data is used.
3. `Axis.clear()` resets the major and minor keyword dictionaries to grid state.
   This models the regression source: all tick side visibility keys are absent
   after this step.
4. `cla()` rebuilds axes artists, patch, titles, grids, and clip paths. These
   steps do not write tick side visibility in the model, except through the
   explicit grid state framed out of this proof.
5. `_set_tick_params_from_rcparams()` writes the current rcParam-derived major
   and minor tick side visibility dictionaries. This discharges P1 for ordinary
   axes.
6. If `Twin` is true, `cla()` restores the saved four visibility keys. This
   discharges P3 and is guarded by the twinned-axes condition, so it cannot
   reintroduce F1 for ordinary axes.
7. If `LOX` is true, `_label_outer_xaxis()` runs after the rcParam reset and
   hides the top and/or bottom x labels dictated by the subplot row position.
   This discharges the x part of P2.
8. If `LOY` is true, `_label_outer_yaxis()` runs after the rcParam reset and
   hides the left and/or right y labels dictated by the subplot column position.
   This discharges the y part of P2.
9. No transition restores non-visibility tick styling. Those fields remain at
   the values produced by the existing clear path. This discharges P5.

There are no loops or recursion in the changed fragment, so no loop circularity
is required.

## Adequacy Audit

The formal claims match the intent obligations:

- P1 corresponds to evidence E2, E4, and E5. It is not candidate-derived; it is
  directly required by the public hint.
- P2 corresponds to evidence E1, E3, E4, and E6. It captures the reported
  shared-axis label symptom and the helper that originally hid those labels.
- P3 corresponds to evidence E7. It is a compatibility frame condition over
  existing public twin-axis construction.
- P5 avoids over-preserving candidate behavior. It expressly rejects preserving
  ordinary user/style tick settings as part of this bug fix.

No required behavior in `fvk/SPEC.md` is marked ambiguous or failed after the V2
source change.

## Machine-Check Commands

These are emitted for a later environment with K installed. They were not run.

```sh
kompile fvk/mini-mpl-clear.k --backend haskell
kast --backend haskell fvk/axes-clear-spec.k
kprove fvk/axes-clear-spec.k
```

Expected result after compatible K setup: `#Top` for all claims.

## Test Recommendations

Do not remove tests unless the K proof is actually machine-checked.

Tests to add or keep, if test editing were allowed:

- shared `plt.subplots(2, 2, sharex=True, sharey=True)` followed by
  `ax.clear()` keeps inner labels hidden;
- a normal axes honors current tick-side rcParams after `ax.clear()`;
- `twinx()` / `twiny()` axes keep opposite-side tick placement after clear.

No test files were modified.
