# Public Evidence Ledger

## E1: issue title

- Source: prompt / issue
- Evidence: "GaussianMixture predict and fit_predict disagree when n_init>1"
- Obligation: `fit_predict(X)` and `predict(X)` must agree after fitting, even
  when several initializations are evaluated.
- Status: encoded by `SPEC.md` obligations S1 and S4, K claim
  `FIT-PREDICT-CONSISTENCY`, and proof obligations PO1, PO3, PO4.

## E2: issue expected result

- Source: prompt / issue
- Evidence: the reproduction expects no assertion failure after comparing
  `c1 = gm.fit_predict(X)` and `c2 = gm.predict(X)`.
- Obligation: returned labels from `fit_predict` must be computed from the
  same fitted model state used by subsequent `predict`.
- Status: encoded by S4 and PO4.

## E3: public hint

- Source: prompt / public hint
- Evidence: the final `self._e_step()` should occur after
  `self._set_parameters(best_params)` restores the best solution.
- Obligation: final label-producing E-step must occur after best-parameter
  restoration, not before it.
- Status: encoded by S3, finding F1, and proof obligation PO3.

## E4: `fit_predict` docstring

- Source: `repo/sklearn/mixture/base.py`
- Evidence: "fits the model n_init times and sets the parameters with which the
  model has the largest likelihood or lower bound" and then "predicts the most
  probable label".
- Obligation: after fitting, estimator state and returned labels are both tied
  to the best lower-bound initialization.
- Status: encoded by S2, S4, PO2, PO3, PO4.

## E5: public test comment

- Source: `repo/sklearn/mixture/tests/test_gaussian_mixture.py`
- Evidence: "check if fit_predict(X) is equivalent to fit(X).predict(X)".
- Obligation: equivalence is a public behavior, not merely an implementation
  detail. The existing test is incomplete for `n_init > 1`.
- Status: encoded by S1 and finding F3.

## E6: implementation fact, not standalone intent

- Source: `repo/sklearn/mixture/base.py`
- Evidence: `predict` returns `_estimate_weighted_log_prob(X).argmax(axis=1)`;
  `_estimate_log_prob_resp` computes `log_resp` by subtracting one row-wise
  `logsumexp` value from each weighted-log-probability row.
- Obligation: once best parameters are current, `log_resp.argmax(axis=1)` is
  equal to `predict(X)`.
- Status: proof support for PO4. This fact is not used to weaken the public
  intent.

## E7: subclass surface

- Source: `repo/sklearn/mixture/gaussian_mixture.py` and
  `repo/sklearn/mixture/bayesian_mixture.py`
- Evidence: both concrete mixture classes inherit `BaseMixture.fit_predict` and
  implement `_get_parameters` / `_set_parameters`.
- Obligation: a shared fix in `BaseMixture` must remain compatible with both
  subclasses.
- Status: encoded by PO5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
