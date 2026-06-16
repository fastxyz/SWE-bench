# Formal Spec in English

Status: constructed for FVK audit, not machine-checked.

The K claims model the final-refit tail of `BaseSearchCV.fit` after candidate
search has selected `best_params_`. The model abstracts all validated truthy
`refit` values to `true` and `refit=False` to `false`.

## Claim REFIT-TRUE

For any successful final-refit path with `refit` true, a monotonic clock sample
`TStart` before the final estimator `fit`, and a later sample `TEnd`, executing
the refit tail:

- clones and parameterizes the selected estimator before timing starts;
- calls exactly one final best-estimator `fit`, using the branch determined by
  whether `y` is present;
- stores `best_estimator_` as fitted;
- stores `refit_time_` as `TEnd - TStart`;
- leaves cross-validation result state abstractly unchanged.

The side condition is `TEnd >= TStart`, matching an elapsed-time value in
seconds.

## Claim REFIT-FALSE

For any final-search state with `refit` false, executing the refit tail performs
no final best-estimator fit and leaves the `best_estimator_` and `refit_time_`
availability state unchanged.

## Frame Conditions

The claims intentionally do not alter candidate evaluation results,
`cv_results_`/`grid_scores_`, scorer selection, method signatures, or estimator
delegation methods. Those behaviors are outside the requested timing addition
and are preserved by the source patch.
