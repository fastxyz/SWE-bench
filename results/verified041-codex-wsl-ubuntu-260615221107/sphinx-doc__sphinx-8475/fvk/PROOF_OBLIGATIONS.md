# Proof Obligations

Status labels: `DISCHARGED-CONSTRUCTED` means the proof is constructed from the
K claims and source reasoning but was not machine-checked.

## PO-01: Domain and Abstraction

- Obligation: model non-anchor HTTP/HTTPS linkcheck request decisions after
  ignore/cache/local-file filtering has selected a URI for network checking.
- Evidence: problem statement names HEAD/GET linkchecker fallback; code branch
  at `check_uri()` performs exactly that decision.
- Formal claim location: `fvk/mini-linkcheck.k` outcome abstraction.
- Status: DISCHARGED-CONSTRUCTED.

## PO-02: Successful HEAD Is Preserved

- Obligation: when HEAD succeeds, classify from HEAD and do not use GET.
- Evidence: public `test_follows_redirects_on_HEAD` expects HEAD redirect logs
  and a redirected result.
- Formal claim location: `linkcheck-spec.k` HEAD `ok(...)` claims.
- Status: DISCHARGED-CONSTRUCTED.

## PO-03: Existing HEAD HTTPError Fallback Is Preserved

- Obligation: when HEAD raises an HTTP status error, retry with GET.
- Evidence: public `test_follows_redirects_on_GET` expects HEAD 405 followed by
  GET redirect handling.
- Formal claim location: `linkcheck-spec.k` `httpError(...)` fallback claim.
- Status: DISCHARGED-CONSTRUCTED.

## PO-04: HEAD TooManyRedirects Uses GET

- Obligation: when HEAD raises `TooManyRedirects`, retry with GET instead of
  returning broken immediately.
- Evidence: problem statement E1-E3.
- Formal claim location: `linkcheck-spec.k` `tooManyRedirects` claims.
- Source discharge: V1 catches `(HTTPError, TooManyRedirects)` in the inner
  fallback handler before the outer generic exception handler can return broken.
- Status: DISCHARGED-CONSTRUCTED.

## PO-05: GET Outcome Determines Final Classification After Fallback

- Obligation: after HEAD fallback, use the same GET classification rules already
  present in `check_uri()`.
- Evidence: problem asks to retry with GET; existing code handles
  `raise_for_status`, redirects, 401, 503, and broken results.
- Formal claim location: `linkcheck-spec.k` GET result claims after
  `tooManyRedirects`.
- Status: DISCHARGED-CONSTRUCTED.

## PO-06: Other HEAD Exceptions Remain Broken

- Obligation: do not expand fallback to unrelated errors without public intent.
- Evidence: issue only names `TooManyRedirects`; public tests preserve SSL/error
  broken behavior.
- Formal claim location: `mini-linkcheck.k` `otherError` rule.
- Status: DISCHARGED-CONSTRUCTED.

## PO-07: Retry Loop Frame Condition

- Obligation: `check()` still retries only when `check_uri()` returns `broken`;
  if fallback GET returns a non-broken result, the retry loop stops and caches
  that status as before.
- Evidence: unchanged lines 235-245 in `repo/sphinx/builders/linkcheck.py`.
- Formal status: reasoned as a frame condition outside the abstract K branch.
- Status: DISCHARGED-CONSTRUCTED.

## PO-08: Public Compatibility

- Obligation: no public signature, config name, output schema, or virtual
  dispatch shape changes.
- Evidence: V1 changes an import and an internal exception tuple only.
- Formal status: compatibility audit in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: DISCHARGED-CONSTRUCTED.

## PO-09: Honesty Gate

- Obligation: do not claim machine verification or test redundancy without
  running K.
- Evidence: user forbids K tooling and tests; FVK docs require labeling.
- Status: DISCHARGED-CONSTRUCTED with residual machine-check task recorded.
