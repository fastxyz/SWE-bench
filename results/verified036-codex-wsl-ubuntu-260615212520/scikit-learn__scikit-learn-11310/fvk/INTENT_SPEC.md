# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Required Behavior

1. For `BaseSearchCV` search objects that actually refit the selected best
   estimator on the full dataset, fitting should expose a public attribute
   named `refit_time_`.
2. `refit_time_` should be the elapsed wall-clock time, in seconds, for the
   final full-data refit of the best model after grid or randomized search.
3. The attribute should not be part of `cv_results_`, because the issue asks
   for an attribute and `cv_results_` describes per-candidate cross-validation
   measurements.
4. When `refit=False`, no final full-data refit is performed, so the new
   refit-time attribute is not required and should mirror the availability
   behavior of `best_estimator_`.
5. Existing search behavior must be preserved: candidate evaluation,
   `best_params_`, `best_score_`, `best_estimator_`, scoring delegation, and
   method signatures are not part of the requested change.

## Default-Domain Assumptions

1. Timing uses wall-clock seconds because existing in-repo search timing
   (`mean_fit_time` and `mean_score_time`) uses `time.time()`.
2. The proved normal-completion contract covers successful final refits. If the
   estimator's final `fit` raises, the existing refit error behavior is to raise
   and no completed-search attribute guarantee is made.
3. In multi-metric search, any validated truthy `refit` value, including a
   scorer key string, means the final refit branch runs.
