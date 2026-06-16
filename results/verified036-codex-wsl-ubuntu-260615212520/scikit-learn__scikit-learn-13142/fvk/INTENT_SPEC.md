# Intent Spec

Status: constructed from public issue text, public source/docstrings, and public
tests. No tests, Python, or K tooling were run.

## Intended behavior

I1. For valid mixture-model inputs, `fit_predict(X)` must return the same
component labels as `fit(X).predict(X)` on the same estimator configuration,
including when `n_init > 1`.

I2. When fitting uses multiple initializations, the fitted estimator parameters
after `fit_predict` must be the parameters from the initialization with the
largest likelihood or lower bound, as stated by the `fit_predict` docstring.

I3. The labels returned by `fit_predict(X)` must be the most probable component
labels for the fitted parameters, matching the public `predict(X)` contract.

I4. The consistency property is required across the existing `max_iter`, `tol`,
and `random_state` behavior when the method returns. Non-convergence may still
emit the existing `ConvergenceWarning`.

I5. The fix must not change public method signatures, input validation,
convergence-warning behavior, `n_iter_`, `lower_bound_`, or subclass dispatch
contracts.

I6. Domain assumptions: `X` passes `_check_X`; initial parameters pass
`_check_initial_parameters`; `n_init >= 1`; `max_iter >= 1`; subclass
`_get_parameters`, `_set_parameters`, `_e_step`, and `_estimate_weighted_log_prob`
honor their current contracts.

I7. Out of scope for this issue: proving that EM finds a global optimum or that
the Gaussian/Bayesian numerical formulas are mathematically complete. The public
bug concerns consistency between returned labels and restored fitted parameters.
