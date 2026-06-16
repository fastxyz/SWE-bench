# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`IsolationForest.fit`

- Public signature unchanged: `fit(self, X, y=None, sample_weight=None)`.
- Public return unchanged: returns `self`.
- Changed internal dispatch only: the non-auto contamination offset path now
  calls private `_score_samples(X)` instead of public `score_samples(X)`.
- Compatibility status: pass for public API. This intentionally stops treating
  an already validated internal array as a fresh public user input.

`IsolationForest.score_samples`

- Public signature unchanged: `score_samples(self, X)`.
- Public return shape unchanged: scores of shape `(n_samples,)`.
- Validation behavior preserved: still calls `check_is_fitted` and
  `_validate_data(..., reset=False)` before scoring.
- Compatibility status: pass.

`IsolationForest._score_samples`

- New private helper.
- Not a public API addition; used to share scoring computation after validation.
- It performs sparse CSR conversion, then calls the existing chunked score
  computation.
- Compatibility status: pass for in-repo usage.

## Public callsite and override search

The in-repo search found no existing `IsolationForest` subclass or existing
`_score_samples` override. Existing public callsites call `fit`, `predict`,
`decision_function`, or `score_samples` with unchanged signatures.

The change does mean that an external subclass overriding public
`score_samples` would no longer affect `IsolationForest.fit`'s internal offset
calculation. That is an accepted compatibility tradeoff for this bug because
the public issue and maintainer hint specifically require an internal
no-validation scoring path for `fit`; private internals are not stable public
extension points.

## Test-file policy

No test files were modified. The fixed test suite remains external to this
repair pass as required by the benchmark instructions.
