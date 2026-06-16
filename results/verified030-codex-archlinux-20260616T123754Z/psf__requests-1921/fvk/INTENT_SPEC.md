# Intent Spec

Status: constructed from public intent, not machine-checked.

## Target Scope

This FVK pass audits the V1 production change for issue
`psf__requests-1921`: `requests.sessions.merge_setting()` as used by
`Session.prepare_request()` for headers. The full Requests project is not
formally modeled; the proof target is the merge behavior that determines
whether a prepared request contains a header whose final value is `None`.

## Required Behavior

1. A request-level header value of `None` means "omit this header" when session
   headers and request headers are merged.

2. A session-level default header value of `None` has the same deletion meaning
   during request preparation. In particular:
   `session.headers['Accept-Encoding'] = None` followed by a request with no
   explicit `Accept-Encoding` header must produce a prepared request without an
   `Accept-Encoding` header.

3. Request-level values override session-level values before deletion is
   applied. Therefore, if a session header is `None` and the request supplies a
   non-`None` value for the same header, the request value is retained.

4. Header-key matching in the session merge path is case-insensitive because
   `Session.prepare_request()` passes `dict_class=CaseInsensitiveDict`.

5. The session header object should not be mutated as a side effect of
   preparing one request. The `None` sentinel may remain in `Session.headers`
   so it continues to suppress that default on future requests.

6. Non-mapping settings and the existing "request setting wins" behavior for
   non-header settings should remain compatible with the pre-existing helper
   contract unless the public issue supplies contrary intent. The issue supplies
   contrary intent only for final merged mapping values that are `None`.

