# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 source change in
`repo/seaborn/_core/plot.py`, specifically the nominal-coordinate behavior added
to `Plotter._finalize_figure` and the helper `_nominal_axis_length`.

The formal unit is a single coordinate-axis finalization step. The actual
function loops over all subplots and both axes; the proof treats the loop as
repeated independent applications of the one-axis transition, with a frame
condition for unprocessed axes.

The K model uses doubled integer coordinates so half-step limits are exact:
`-.5` is `-1`, and `n - .5` is `2*n - 1`.

## Public intent ledger

The public ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1: the issue requires `so.Nominal` coordinate scales to draw like categorical
  axes.
- E2: default nominal axis bounds are half a category beyond the first and last
  tick/category.
- E3: nominal coordinate grids are hidden even under styles that normally draw a
  grid.
- E4: nominal y axes are inverted.
- E5: explicit and inferred `Nominal` coordinate scales are covered.
- E6: finalization is an intended implementation point.
- E7: existing categorical code confirms the exact grid and limit policy.

## Preconditions and domain

- The axis under analysis is a coordinate axis (`x`, `y`, or a paired variant
  represented by its subplot axis key).
- The compiled scale has already been resolved and stored in `self._scales`.
- `Nominal` in the formal model covers both explicit `so.Nominal` and inferred
  nominal coordinate scales.
- For default half-step bounds, the nominal axis has `n > 0` categories.
- Explicit user limits are represented as already converted axis-unit bounds.

## Required postconditions

- P1: nominal coordinate axes disable their own grid.
- P2: nominal x axes with no explicit user limit and `n > 0` end with limits
  `(-0.5, n - 0.5)`.
- P3: nominal y axes with no explicit user limit and `n > 0` end with limits
  `(n - 0.5, -0.5)`.
- P4: nominal y axes with explicit user limits end inverted; normal-order limits
  are reversed by `invert_yaxis`.
- P5: explicit user limits are applied instead of default categorical bounds.
- P6: non-nominal axes do not receive nominal grid, limit, or inversion changes.
- P7: semantic `Nominal` scales are outside this axis policy.

## Formal artifacts

- `mini-python-axis.k`: minimal K semantics for the relevant axis-state
  transition.
- `nominal-axis-spec.k`: K claims for nominal x/y default limits, explicit
  limits, and non-nominal frame behavior.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of each claim.
- `SPEC_AUDIT.md`: adequacy check against `INTENT_SPEC.md`.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: public API and callsite compatibility.
