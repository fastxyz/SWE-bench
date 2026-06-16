# Findings

Status: constructed, not machine-checked.

## F-001: Original bug, resolved by V1

Input: `IsolationForest(random_state=0, contamination=0.05).fit(X)` where `X`
is a pandas DataFrame with a valid string column such as `"a"`.

Observed before V1: `fit` recorded `feature_names_in_`, converted local `X` to
an internal array, then called public `score_samples(X)` for the offset. Public
`score_samples` called `_validate_data(..., reset=False)` on the internal array,
which had no feature names, so `BaseEstimator._check_feature_names` emitted
`X does not have valid feature names, but IsolationForest was fitted with
feature names`.

Expected: no such warning during `fit`; the data originally supplied by the
user has valid feature names.

V1 status: resolved. PO-1 and PO-7 show that `fit` now calls the private scorer
on the already validated internal representation, so the warning-producing
public validation step is not on the internal offset path.

## F-002: Public feature-name warnings must not be globally suppressed

Input: an estimator fitted on DataFrame input with feature names, followed by a
public `score_samples` call on an ndarray with no feature names.

Expected: the standard public warning remains appropriate for this post-fit
user call.

V1 status: resolved/preserved. PO-3 shows that public `score_samples` still
validates with `reset=False` before delegating to `_score_samples`.

## F-003: Sparse scoring representation risk, resolved by V1

Input: sparse training data with fixed contamination.

Risk: `fit` validates sparse data as CSC for fitting, while the scoring path
used by tree `apply` is CSR-oriented. Bypassing public `score_samples` also
bypasses its `accept_sparse="csr"` validation conversion.

Expected: internal scoring receives CSR-compatible sparse data.

V1 status: resolved. `_score_samples` converts sparse input with `X.tocsr()`;
PO-5 captures the required CSC-to-CSR transition.

## F-004: Public compatibility, no further source change

Input: existing public calls to `fit`, `score_samples`, `decision_function`, and
`predict`.

Expected: public signatures and return shapes do not change.

V1 status: acceptable. PO-6 and `PUBLIC_COMPATIBILITY_AUDIT.md` show public
signatures are unchanged and no in-repo subclass/override conflict exists. An
external subclass that relied on overriding public `score_samples` to affect
`fit`'s internal offset computation is a residual private-internal behavior
change, but the public issue and maintainer hint explicitly justify the private
no-validation path.

## F-005: Proof capability boundary, not a code bug

The K proof abstracts raw IsolationForest scoring and percentile arithmetic.
This is a deliberate proof boundary rather than an implementation finding:
public intent requires preserving the offset scoring call shape, not proving
the IsolationForest algorithm. Existing numerical and integration tests should
be kept unless a future machine-checked proof covers those domains.

## Summary

No unresolved FVK finding justifies another production-code edit. V1 stands.
