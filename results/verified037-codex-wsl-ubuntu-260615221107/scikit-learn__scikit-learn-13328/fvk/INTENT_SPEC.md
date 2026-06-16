# Intent Spec

Status: constructed from public issue text and source inspection; not
machine-checked.

## Scope

The audited public behavior is `HuberRegressor.fit(X, y, sample_weight=None)`
for otherwise valid regression inputs that pass the estimator's existing shape,
finite-value, sparse-format, and parameter checks.

Dense arrays and accepted CSR sparse matrices are in scope because
`HuberRegressor.fit` already accepts dense input and passes
`accept_sparse=['csr']` to validation.

The private helper `_huber_loss_and_gradient` is modeled as a downstream
consumer of `fit`'s validated `X`. Direct calls to that helper with unvalidated
boolean `X` are outside the public issue's intent.

Full numerical convergence of L-BFGS-B and exact coefficient values are outside
this FVK slice. The proof targets the reported dtype/error behavior: a boolean
training matrix must not reach the unary-minus gradient operation as boolean
data.

## Required Behavior

I-001: `HuberRegressor.fit(X_bool, y)` must not raise the NumPy
`TypeError` caused by unary minus on a boolean array when `X_bool` is a valid
2D boolean predictor matrix and `y` is otherwise valid.

I-002: Boolean predictor data supplied through `HuberRegressor.fit` must be
converted to a floating dtype before optimization, matching the issue's stated
expectation that the estimator convert boolean predictors to floats.

I-003: Predictor data that is already floating point must continue through the
same `fit` path without an unnecessary dtype change.

I-004: Existing public validation behavior unrelated to this bug must be
preserved: `fit` keeps the same public signature, the same sparse format policy
(`csr` accepted), the same `y_numeric=True` target handling, and the same
sample-weight and `epsilon` checks.

I-005: The fix must be local to production source. Test files are fixed by the
task and must not be modified.
