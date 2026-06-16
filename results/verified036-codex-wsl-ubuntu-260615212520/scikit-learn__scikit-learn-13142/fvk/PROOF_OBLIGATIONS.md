# Proof Obligations

Status: constructed, not machine-checked.

## PO1: intent adequacy

The spec must prove the public issue's consistency property, not the legacy
pre-restore behavior.

- Evidence: E1, E2, E3.
- Status: discharged by S1, S3, claim FIT-PREDICT-CONSISTENCY, and finding F1.

## PO2: best-parameter selection invariant

After each outer initialization loop iteration, if a run's lower bound is
greater than the previous maximum, `best_params` and `best_n_iter` are updated
to that run; otherwise they retain the previous best. At loop exit,
`best_params` corresponds to the maximum lower bound seen.

- Evidence: E4 and source lines around the `if lower_bound > max_lower_bound`
  update.
- Status: discharged by inspection and represented by
  SELECT-BEST-CIRCULARITY.

## PO3: final E-step ordering

The final `_e_step(X)` whose `log_resp` feeds the return value must execute
after `_set_parameters(best_params)`.

- Evidence: E3.
- Status: discharged in V1 source. `repo/sklearn/mixture/base.py` now assigns
  best fitted state before the final E-step.

## PO4: E-step labels equal predict labels under a shared parameter state

For any fixed fitted parameter state `P`, `predict(X)` returns
`argmax(weighted_log_prob(X, P))`; `_e_step(X)` computes
`log_resp = weighted_log_prob(X, P) - row_logsumexp(...)`. Subtracting the same
scalar from every component in a row preserves that row's `argmax`.

- Evidence: E6.
- Status: discharged algebraically by ARGMAX-RESP-PREDICT.

## PO5: subclass compatibility

The BaseMixture ordering change must remain valid for both concrete subclasses.

- Evidence: E7 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: discharged by source inspection: both subclasses restore the
  parameters read by their log-probability and log-weight methods.

## PO6: public frame preservation

The fix must not change validation, method signatures, warning behavior,
`n_iter_`, or `lower_bound_`.

- Evidence: I5 and source diff.
- Status: discharged. V1 moved the final E-step only.

## PO7: discriminator against V0

The proof model must distinguish the fixed order from the buggy order. If
`bestParams(RS) != lastParams(RS)` and labels differ under those states, V0
returns `labels(X, lastParams(RS))` while V1 returns
`labels(X, bestParams(RS))`.

- Evidence: E1, E3.
- Status: discharged by the `mini-mixture.k` state-order model and finding F1.

## PO8: test guidance

Existing public tests may support intent but must not be edited here. Any
test-removal claim must be conditional on machine-checking.

- Evidence: F3 and task restrictions.
- Status: discharged by recommending an added `n_init > 1` test and no test
  deletion.

## PO9: proof boundary honesty

The FVK result must not claim full numerical EM correctness or machine-checked
K proof success.

- Evidence: F4 and FVK honesty gate.
- Status: discharged by labeling artifacts constructed, not machine-checked,
  and by scoping the spec to state ordering and label consistency.
