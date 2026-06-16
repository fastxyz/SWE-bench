# Formal Spec English

Status: English paraphrase of the K claims in
`fvk/mixture-fit-predict-spec.k`; constructed, not machine-checked.

## Claim FIT-PREDICT-CONSISTENCY

For every valid non-empty sequence of completed initialization runs `RS` and
valid input data `X`, executing the abstract `fitPredict(RS, X)` transition ends
with the estimator parameter cell set to `bestParams(RS)` and returns
`labels(X, bestParams(RS))`.

Plain meaning: the final labels returned by `fit_predict` are computed after
the best fitted parameters are restored.

## Claim SELECT-BEST-CIRCULARITY

For every valid suffix of initialization runs, if the current accumulator
contains the best parameter and lower bound from the already-processed prefix,
continuing selection over the suffix yields the best parameter over the whole
prefix plus suffix.

Plain meaning: the fitting loop's `best_params` invariant tracks the largest
lower bound seen so far.

## Claim ARGMAX-RESP-PREDICT

For every parameter state `P` and valid `X`, labels computed from the E-step
responsibilities are equal to labels computed by `predict`, because each row of
`log_resp` is the corresponding weighted-log-probability row minus a single
row-wise scalar.

Plain meaning: once the same parameter state is used, `fit_predict` and
`predict` choose the same component labels.

## Frame Claim PUBLIC-FRAME

The change preserves the public method signature and leaves validation,
convergence warning, `n_iter_`, and `lower_bound_` behavior outside the final
label E-step ordering unchanged.
