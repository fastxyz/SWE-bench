# FVK Spec

Status: constructed, not machine-checked.

## Target

Primary target: `ColumnTransformer.set_output` in
`repo/sklearn/compose/_column_transformer.py`.

Supporting target: `_safe_set_output` in `repo/sklearn/utils/_set_output.py`,
because `ColumnTransformer.set_output` delegates child configuration to this
helper.

## Intended Contract

For a `ColumnTransformer` with explicit transformers `T`, optional fitted
transformers `T_`, and a `remainder` value `R`:

1. Calling `set_output(transform=t)` configures the `ColumnTransformer` itself
   with `t` when `t` is non-`None`; `None` leaves the configuration unchanged.
2. For every estimator in `T` and `T_`, `_safe_set_output(estimator,
   transform=t)` is invoked.
3. If `R` is an estimator rather than `"passthrough"` or `"drop"`,
   `_safe_set_output(R, transform=t)` is invoked.
4. If `t == "pandas"` and `R` is later cloned during `fit_transform`, the clone
   inherits the pandas output configuration.
5. If every active child output is pandas and the `ColumnTransformer` dense
   output config is pandas, `_hstack` takes the pandas concatenation branch.
6. If `t is None`, `_safe_set_output` returns without changing configuration
   and without requiring the estimator to define `set_output`.
7. If `t is not None` and the child can transform but has no `set_output`,
   `_safe_set_output` raises the existing `ValueError`.

## Domain

The proof models the issue-relevant domain:

- Dense, non-sparse output.
- A remainder estimator with at least one remaining column.
- Explicit transformers that are already correctly configured by the existing
  path.
- Remainder values are either estimator, `"drop"`, or `"passthrough"`.
- Child estimators follow scikit-learn clone semantics for
  `_sklearn_output_config`.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the issue states that `remainder` is ignored despite being a
  transformer-like participant.
- E3: the expected result makes the estimator-valued `remainder` path match the
  explicit-transformer path.
- E5/E6: fit-time cloning means the pre-fit fix must configure
  `self.remainder`, not only a fitted remainder.
- E7: pandas stacking depends on all child outputs being pandas-like.
- E8: the helper's documented `transform=None` no-op must remain true after
  adding a new caller path for `remainder`.

## Formal Model

The formal core abstracts the Python implementation into the following
observable state:

- `explicitOutput`: output kind for the explicit transformer group.
- `remainderKind`: `estimator` or `sentinel`.
- `remainderOutput`: output kind attached to `self.remainder`.
- `selfOutput`: output kind attached to the `ColumnTransformer`.

This abstraction is property-complete for the issue because it distinguishes
the failing state (`explicitOutput == pandas`, `remainderOutput == default`)
from the passing state (`explicitOutput == pandas`,
`remainderOutput == pandas`). That distinction is exactly what controls
whether `_hstack` can take the pandas branch for all dense chunks.

The K files are:

- `fvk/mini-column-transformer.k`
- `fvk/column-transformer-set-output-spec.k`

They are constructed but not run.
