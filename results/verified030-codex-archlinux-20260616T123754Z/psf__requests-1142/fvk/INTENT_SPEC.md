# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Required behavior

1. A default/bodyless `GET` request must not receive an automatically added
   `Content-Length` header.
2. A `GET` request that actually carries body data may still receive a computed
   `Content-Length`; the public issue explicitly notes that data in a `GET`
   request is not forbidden.
3. Explicit user-supplied `Content-Length` on a bodyless `GET` is outside the
   automatic-addition bug and should not be removed by this fix.
4. The earlier behavior of adding `Content-Length: 0` to non-`GET` bodyless
   requests should remain unchanged absent public intent to alter those methods.
5. Public request-construction paths that denote "no body" with omitted data or
   `data=None` are in scope; both should be treated as bodyless for `GET`.

## Out of scope or underspecified

1. `HEAD` is not changed by this fix because the public issue and discussion are
   specifically about `requests.get` and `GET` requests.
2. Explicit empty iterable data such as `data=[]` is underspecified by the issue:
   it may mean an explicit zero-length stream rather than the default no-body
   case. It is recorded as a follow-up question, not used to justify a broader
   production change here.
