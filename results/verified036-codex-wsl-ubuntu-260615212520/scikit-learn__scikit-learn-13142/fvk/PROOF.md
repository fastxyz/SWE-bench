# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims

The formal claims are in `fvk/mixture-fit-predict-spec.k` over the mini
semantics in `fvk/mini-mixture.k`.

- FIT-PREDICT-CONSISTENCY: `fitPredict(RS, X)` returns
  `labels(X, bestParams(RS))` and leaves the estimator parameter cell at
  `bestParams(RS)`.
- SELECT-BEST-CIRCULARITY: the best-selection loop preserves the invariant that
  the accumulator is the best parameter among processed initialization runs.
- ARGMAX-RESP-PREDICT: `argmax(eStep(X, P)) == labels(X, P)` for any fixed
  parameter state `P`.

## Proof Sketch

1. Best-selection invariant. Initially `max_lower_bound` is below every
   completed run's lower bound, and each outer-loop iteration compares the
   current run's `lower_bound` with the accumulator. If the current run is
   greater, `_get_parameters()` becomes the accumulator; otherwise the previous
   accumulator remains. By induction over the finite `range(n_init)` loop, the
   stored `best_params` is the parameter set for the largest lower bound seen.

2. V1 ordering. After the loop and warning branch, V1 executes
   `_set_parameters(best_params)`, assigns `n_iter_` and `lower_bound_`, and
   only then executes the final `_e_step(X)`. Since `_e_step` reads estimator
   attributes through `_estimate_log_prob_resp`, this final responsibility
   matrix is computed from the restored best parameters.

3. Argmax equivalence. `predict(X)` returns
   `_estimate_weighted_log_prob(X).argmax(axis=1)`. `_e_step(X)` calls
   `_estimate_log_prob_resp(X)`, where
   `log_resp[row, k] = weighted_log_prob[row, k] - logsumexp(weighted_log_prob[row, :])`.
   The subtracted value is constant across components `k` for a fixed row, so
   every row's `argmax` is unchanged. Therefore the returned
   `log_resp.argmax(axis=1)` equals `predict(X)` under the same restored state.

4. Discriminator. In the pre-fix order, if the final initialization was not the
   best one and label argmax differs between `last_params` and `best_params`,
   final labels came from `last_params` while the estimator was restored to
   `best_params`. V1 removes exactly that path by restoring before the final
   E-step.

## Machine Check Commands

These commands are emitted for a future environment with K installed. They were
not run in this session.

```sh
kompile fvk/mini-mixture.k --backend haskell
kast --backend haskell fvk/mixture-fit-predict-spec.k
kprove fvk/mixture-fit-predict-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Test Guidance

No tests were modified. Existing fit/predict consistency tests should be kept
until the claims are machine-checked. The public suite should add a
`GaussianMixture(..., n_init > 1)` consistency case, but this benchmark forbids
test edits.

## Residual Risk

This is a partial-correctness proof over a mini semantics. It proves the
state-ordering and label-consistency slice; it does not prove termination,
floating-point numerical stability, KMeans initialization behavior, scipy
linear algebra behavior, or global EM optimality.
