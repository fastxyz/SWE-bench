# Iteration Guidance

Status: FVK audit result for V2.

## Decision

Keep the V1 source fix unchanged.

Reason: findings F1 and F2 plus proof obligations PO1-PO7 show the public bug
is the final E-step reading the last initialization's parameters, and V1 moves
that E-step after restoration of `best_params`. The proof obligations do not
surface an additional source change justified by public intent.

## Recommended next actions outside this benchmark

- Add a public regression test with `GaussianMixture(n_components=..., n_init > 1)`
  asserting `fit_predict(X)` equals `predict(X)` after fitting.
- Machine-check the emitted K artifacts in an environment with K installed
  before using the proof to remove or weaken any tests.
- Keep numerical, convergence, and integration tests because this FVK pass does
  not prove full EM numerical correctness.

## Non-actions

- Do not change `predict`; it already reads the fitted estimator state.
- Do not store `log_resp` during the initialization loop; a final E-step after
  restoration is simpler and preserves the existing consistency comment.
- Do not edit test files in this benchmark task.
