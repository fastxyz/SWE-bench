# FVK Findings

Status: constructed, not machine-checked.

## F1: resolved code bug, final labels used the last initialization

- Classification: code bug, fixed by V1.
- Evidence: public issue E1/E2 and hint E3.
- Input shape: valid `X`, `n_init > 1`, with at least two initialization runs
  where the highest-lower-bound run is not the last run and the per-row label
  argmax differs between those parameter states.
- Observed before V1: the estimator restored `best_params`, but
  `fit_predict(X)` returned labels from the final `_e_step(X)` evaluated before
  that restoration, so labels could come from the last initialization.
- Expected: returned labels should come from the same best fitted parameters
  used by subsequent `predict(X)`.
- V1 status: discharged by moving the final `_e_step(X)` after
  `_set_parameters(best_params)`.
- Proof obligations: PO1, PO2, PO3, PO4.

## F2: no additional source bug found in the audited consistency slice

- Classification: confirmation finding.
- Evidence: PO3 verifies the ordering; PO4 verifies `log_resp.argmax(axis=1)`
  equals `predict(X)` under the same restored parameters; PO5 verifies the
  shared change is compatible with both concrete subclasses.
- Input shape: all valid inputs in the FVK domain from `SPEC.md`.
- Observed in V1: `best_params` is restored before the label-producing E-step.
- Expected: `fit_predict(X)` labels use `best_params`.
- V2 decision: keep V1 source unchanged.

## F3: public test coverage gap remains, but tests are fixed by the task

- Classification: test gap.
- Evidence: public Gaussian `fit_predict` test checks equivalence but does not
  set `n_init > 1`; the issue says this is why the bug was missed.
- Recommendation: add or extend a test that sets `n_init > 1` and asserts
  `fit_predict(X) == predict(X)` after fitting. Do not edit tests in this
  benchmark task.
- Proof obligations: PO8.

## F4: proof capability boundary, not a code bug for this issue

- Classification: proof capability gap / escalation boundary.
- Evidence: full Gaussian and Bayesian EM numerical correctness involves numpy,
  scipy linear algebra, floating-point behavior, KMeans initialization, and
  subclass-specific likelihood formulas outside the mini-mixture fragment.
- Impact: the constructed proof covers the state-ordering and label-consistency
  property, not global EM optimality or all numerical details.
- V2 decision: no source change justified; keep tests until any future
  machine-checked or fuller-semantics proof is available.
- Proof obligations: PO9.
