# Public Evidence Ledger

## E1 - Categorical equivalence

- Source: `benchmark/PROBLEM.md`
- Quote: "Nominal scale should be drawn the same way as categorical scales"
- Obligation: coordinate axes backed by `Nominal` scale objects receive the
  categorical-axis drawing policy.
- Status: encoded by obligations O1, O3, O4, and O6.

## E2 - Half-step bounds

- Source: `benchmark/PROBLEM.md`
- Quote: "The scale is drawn to +/- 0.5 from the first and last tick, rather
  than using the normal margin logic"
- Obligation: for `n > 0` categories with no explicit user limit, nominal x
  limits are `(-0.5, n - 0.5)` and nominal y limits are `(n - 0.5, -0.5)`.
- Status: encoded by obligations O2 and O4.

## E3 - Grid suppression

- Source: `benchmark/PROBLEM.md`
- Quote: "A grid is not shown, even when it otherwise would be with the active
  style"
- Obligation: a nominal coordinate axis has its grid disabled independent of
  theme defaults.
- Status: encoded by obligation O3.

## E4 - Y-axis inversion

- Source: `benchmark/PROBLEM.md`
- Quote: "If on the y axis, the axis is inverted"
- Obligation: nominal y axes end in inverted display order.
- Status: encoded by obligations O4 and O5.

## E5 - Explicit and inferred nominal scales

- Source: `benchmark/PROBLEM.md`
- Quote: "`so.Nominal` scales (including inferred ones)"
- Obligation: detection must use the compiled scale type, not only an explicit
  user scale argument.
- Status: encoded by obligation O1.

## E6 - Finalization placement

- Source: `benchmark/PROBLEM.md`
- Quote: "Probably straightforward to do in `Plotter._finalize_figure`"
- Obligation: it is acceptable and expected to apply the policy while finalizing
  the compiled figure.
- Status: encoded by obligation O7.

## E7 - Existing categorical behavior

- Source: `repo/seaborn/categorical.py`
- Quote: `_adjust_cat_axis` calls `ax.xaxis.grid(False)`,
  `ax.set_xlim(-.5, n - .5, auto=None)`, `ax.yaxis.grid(False)`, and
  `ax.set_ylim(n - .5, -.5, auto=None)`.
- Obligation: this implementation is supporting evidence for the exact behavior
  meant by "same way as categorical scales".
- Status: encoded by obligations O3 and O4.
