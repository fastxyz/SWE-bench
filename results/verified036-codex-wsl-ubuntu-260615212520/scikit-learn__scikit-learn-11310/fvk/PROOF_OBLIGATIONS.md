# Proof Obligations

Status: constructed for FVK audit, not machine-checked.

## PO1 - Refit-enabled success stores elapsed final-fit time

For every covered search object that reaches the final-refit branch and whose
final estimator `fit` returns normally:

- the best estimator is fitted on the full dataset using the existing `y`
  branch;
- `refit_time_` exists after `fit`;
- `refit_time_ = time_after_final_fit - time_before_final_fit`;
- `refit_time_ >= 0` under the clock side condition.

Traced findings: F1, F2.

## PO2 - Refit-disabled path does not invent timing state

For every covered search object with `refit=False`, the final-refit branch is
not executed and `refit_time_` remains unavailable.

Traced findings: F3.

## PO3 - Timing boundary matches existing fit-time convention

The timer starts after cloning and parameter assignment and immediately before
the final estimator `fit`. This aligns the new value with existing
cross-validation `fit_time`, which also starts after `set_params`.

Traced findings: F1, F2.

## PO4 - Both public search implementations are covered

The refactored `sklearn.model_selection` search classes and the deprecated
`sklearn.grid_search` duplicate both satisfy PO1 and PO2 while they remain
present in the source tree.

Traced findings: F2.

## PO5 - Public compatibility is preserved

The patch must not change constructor signatures, `fit` signatures, final
estimator `fit` arguments, return values, or `cv_results_`/`grid_scores_`
structure.

Traced findings: F1, F3.

## PO6 - Documentation reflects the new public attribute

Each public search class whose final-refit path records the attribute should
list `refit_time_` in its Attributes documentation.

Traced findings: F1, F2.
