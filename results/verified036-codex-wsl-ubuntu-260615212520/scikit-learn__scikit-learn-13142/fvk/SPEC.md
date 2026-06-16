# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target under audit: `BaseMixture.fit_predict` in
`repo/sklearn/mixture/base.py`, with concrete use by `GaussianMixture` and
`BayesianGaussianMixture`.

The verified observable is the label vector returned by `fit_predict(X)` and
the fitted estimator state immediately afterward. The spec abstracts over the
numerical EM internals but keeps the key property visible: labels are the
`argmax` of the weighted log probabilities under the restored best parameters.

## Domain

The contract applies when:

- `X` passes `_check_X(X, self.n_components, ensure_min_samples=2)`;
- `_check_initial_parameters(X)` passes;
- `n_init >= 1` and `max_iter >= 1`, as enforced by existing validation;
- each subclass implementation of `_get_parameters`, `_set_parameters`,
  `_e_step`, and `_estimate_weighted_log_prob` satisfies its local contract;
- the method returns. The proof is partial-correctness only.

## Obligations

S1. `fit_predict(X)` returns the same labels as `fit(X).predict(X)` for the same
configuration, including `n_init > 1`.

S2. Across initialization attempts, the selected fitted parameters are the
parameters captured at the largest lower bound observed by the fitting loop.

S3. The label-producing final E-step is evaluated after
`_set_parameters(best_params)`, so it reads the restored best fitted parameters.

S4. For a fixed parameter state `P`, `_e_step(X)` returns
`log_resp = weighted_log_prob(X, P) - row_logsumexp(weighted_log_prob(X, P))`.
Subtracting one scalar per row preserves per-row `argmax`, so
`log_resp.argmax(axis=1) == predict(X)`.

S5. Existing public API and frame behavior are preserved: no signature changes;
input validation, warning timing, `n_iter_`, and `lower_bound_` remain as in the
candidate code.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical trace points:

- E1/E2 require consistency between `fit_predict(X)` and later `predict(X)`.
- E3 specifically identifies the order of `_set_parameters(best_params)` and
  final `_e_step(X)`.
- E4 supplies the best-lower-bound restoration obligation.
- E5 shows the public test intent and the `n_init > 1` coverage gap.
- E6 supports the `argmax` equivalence proof without turning implementation
  behavior into the desired behavior.
- E7 requires compatibility across both concrete subclasses.

## Formal Artifacts

- `fvk/mini-mixture.k`: a property-complete mini semantics for the relevant
  mixture state transitions.
- `fvk/mixture-fit-predict-spec.k`: reachability claims and circularity-style
  obligations for best-parameter selection and final label consistency.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-mixture.k --backend haskell
kast --backend haskell fvk/mixture-fit-predict-spec.k
kprove fvk/mixture-fit-predict-spec.k
```
